local s,id=GetID()
local COUNTER_CUBIC=0x1038
function s.initial_effect(c)
	-- EFECTO ①: Al activar esta carta: Puedes enviar 1 carta "Cúbico" desde tu Deck al GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)
	
	-- EFECTO ②: Una vez por turno: Puedes descartar 1 carta; coloca 1 Contador Cúbico en un monstruo del rival
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_COUNTER)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetCost(s.countercost)
	e2:SetTarget(s.countertg)
	e2:SetOperation(s.counterop)
	c:RegisterEffect(e2)
	
	-- EFECTO ③ REPARADO FÍSICAMENTE (SIN CRASH EN LÍNEA 31): Bloqueo de turno absoluto por ID guardado en la Magia Continua
	local fusion_params={
		fusfilter=function(tc)
			-- SOLUCIÓN: Usamos 'c' (la Magia Continua) directamente desde la cabecera, removiendo 'e' de los parámetros
			return tc:IsSetCard(SET_CUBIC) and c:GetFlagEffect(id+tc:GetCode())==0
		end
	}
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,0,EFFECT_COUNT_CODE_CHAIN)
	e3:SetCondition(s.fuscon)
	e3:SetTarget(Fusion.SummonEffTG(fusion_params))
	e3:SetOperation(s.fusop(fusion_params)) 
	c:RegisterEffect(e3)
end

s.listed_series={SET_CUBIC}
s.counter_place_list={COUNTER_CUBIC}

-- =========================================================================
-- ---         RESOLUCIÓN DEL EFECTO ① (ENTIERRO TEMÁTICO)               ---
-- =========================================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.tgfilter(c)
	return c:IsSetCard(SET_CUBIC) and c:IsAbleToGrave()
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	end
end

-- =========================================================================
-- ---         RESOLUCIÓN DEL EFECTO ② (SEMANÁTICA DE CONTADORES)        ---
-- =========================================================================
function s.countercost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

function s.countertg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,nil,1,tp,COUNTER_CUBIC)
end

function s.counterop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_COUNTER)
	local sc=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil):GetFirst()
	if not sc then return end
	Duel.HintSelection(sc)
	if sc:AddCounter(COUNTER_CUBIC,1) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_CANNOT_ATTACK)
		e1:SetCondition(function(e)
			return e:GetHandler():HasCounter(COUNTER_CUBIC)
		end)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		sc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE)
		sc:RegisterEffect(e2)
	end
end

-- =========================================================================
-- ---     RESOLUCIÓN DEL EFECTO ③ (FUSIÓN CON CANDADO DE TURNO SEGURO)  ---
-- =========================================================================
function s.fusconfilter(c,tp)
	return c:IsSetCard(SET_CUBIC) and c:IsFaceup() and c:IsControler(tp)
end

function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.fusconfilter,1,nil,tp)
end

function s.fusop(params)
	return function(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		if not c:IsRelateToEffect(e) then return end
		
		-- 1. Ejecuta la invocación por fusión de la librería
		Fusion.SummonEffOP(params)(e,tp,eg,ep,ev,re,r,rp)
		
		-- 2. Rastrea cuál monstruo fue el que tocó el campo de forma exitosa
		local g=Duel.GetOperatedGroup():Filter(Card.IsType,nil,TYPE_FUSION)
		local tc=g:GetFirst()
		
		if tc and tc:IsType(TYPE_FUSION) then
			-- Registra la marca directamente sobre el cuerpo físico de ESTA Magia Continua (c)
			-- Con la propiedad RESET_PHASE+PHASE_END el candado expira obligatoriamente en la End Phase
			c:RegisterFlagEffect(id+tc:GetCode(),RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
		end
	end
end
