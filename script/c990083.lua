local s,id=GetID()
function s.initial_effect(c)
	-- EFECTO ①: Activar e invocar materiales para realizar Sincronía (Ventanas Secuenciales)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_END_PHASE)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- EFECTO ② REPARADO: Añadir del GY a la mano si se invoca un Sincro Dragón (Cualquier Atributo)
	-- [CANDADO EXCLUSIVO]: NO funciona el mismo turno en que esta carta fue enviada al Cementerio
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_GRAVE) -- 0x10 = LOCATION_GRAVE
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	
	-- EFECTO ③: Activación desde la mano si hay 5+ Dragones de Sincronía con nombres diferentes en GY
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e3:SetCondition(s.handcon)
	c:RegisterEffect(e3)
end

-- Lista de arquetipos soportados en tu base de datos
s.listed_series={SET_SYNCHRON,SET_JUNK,SET_STARDUST}

-- --- FILTROS PLANOS UNIVERSALES PARA EVITAR ERRORES DE PARÁMETROS EN CADENA ---
function s.tuner_filter(c,e,tp)
	return (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:HasLevel()
		and c:IsType(TYPE_TUNER) and (c:IsSetCard(SET_SYNCHRON) or c:IsSetCard(SET_JUNK))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.nontuner_filter(c,e,tp)
	return (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:HasLevel()
		and not c:IsType(TYPE_TUNER) and c:IsSetCard(SET_STARDUST)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.spfilter(c,e,tp,mg,lv)
	return c:IsType(TYPE_SYNCHRO) and (c:IsRace(RACE_DRAGON) or c:IsRace(RACE_WARRIOR))
		and c:IsLevel(lv) and c:IsSynchroSummonable(nil,mg)
end

-- =========================================================================
-- ---   ADUANA DE TARGET NATIVA: ENCIENDE LA CARTA DE FORMA INTERACTIVA  ---
-- =========================================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
			and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
			and Duel.IsExistingMatchingCard(s.tuner_filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)
			and Duel.IsExistingMatchingCard(s.nontuner_filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)
	end
	
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_GRAVE+LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- =========================================================================
-- ---    OPERACIÓN CORREGIDA: INTERFAZ DE VENTANAS CONSECUTIVAS         ---
-- =========================================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 or Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end
	
	-- [VENTANA 1]: SELECCIÓN EXCLUSIVA DEL CANTANTE (SYNCHRON / JUNK)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g1=Duel.SelectMatchingCard(tp,s.tuner_filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
	if #g1==0 then return end
	local tc1=g1:GetFirst()
	
	-- [VENTANA 2]: SELECCIÓN EXCLUSIVA DEL NO-CANTANTE (STARDUST)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g2=Duel.SelectMatchingCard(tp,s.nontuner_filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,tc1,e,tp)
	if #g2==0 then return end
	local tc2=g2:GetFirst()
	
	local dg=Group.FromCards(tc1,tc2)
	
	-- 1. Invoca Especialmente ambos materiales seleccionados al campo boca arriba al unísono
	if Duel.SpecialSummon(dg,0,tp,tp,false,false,POS_FACEUP)==2 then
		Duel.BreakEffect() 
		
		local lv=dg:GetSum(Card.GetLevel)
		
		-- [VENTANA 3]: APARICIÓN DEL EXTRA DECK EN AZUL BRILLANTE
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,dg,lv)
		
		if #g>0 then
			local sc=g:GetFirst()
			-- 3. Realiza la Invocación por Sincronía oficial mandando los materiales al Cementerio
			Duel.SynchroSummon(tp,sc,nil,dg)
		end
	end
end

-- =========================================================================
-- ---  RESOLUCIÓN DEL EFECTO ②: RECICLAJE EXCLUSIVO CON CANDADO DE TURNO ---
-- =========================================================================
function s.thcfilter(c,tp)
	-- SANEADO: Se removio por completo IsAttribute(ATTRIBUTE_DARK). Acepta cualquier Sincro Dragon legal.
	return c:IsRace(RACE_DRAGON) and c:IsType(TYPE_SYNCHRO) and c:IsControler(tp) and c:IsSynchroSummoned()
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- CANDADO REPARADO: Evalua que el turno en que se envio al GY NO coincida con el Turno de ejecucion del duelo
	return eg:IsExists(s.thcfilter,1,nil,tp) and c:GetTurnID()~=Duel.GetTurnCount()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end

-- =========================================================================
-- ---  CONDICIONAL DE ENTRADA EXCLUSIVA: 5 SINCROS DRAGÓN DE ID DIFERENTE ---
-- =========================================================================
function s.handcon_filter(c)
	return c:IsType(TYPE_SYNCHRO) and c:IsRace(RACE_DRAGON)
end

function s.handcon(e)
	local g=Duel.GetMatchingGroup(s.handcon_filter,e:GetHandlerPlayer(),LOCATION_GRAVE,0,nil)
	local ct=g:GetClassCount(Card.GetCode)
	return ct>=5
end
