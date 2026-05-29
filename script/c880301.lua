local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Material de fusión: 3+ Semillas Cúbicas (CARD_VIJAM)
	Fusion.AddProcMixRep(c,true,true,CARD_VIJAM,3,99)
	
	-- ① Al ser invocado: Acoplar tantos Vijam como desees de mano y/o Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON) -- (Usa Overlay internamente)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.ovcon)
	e1:SetTarget(s.ovtg)
	e1:SetOperation(s.ovop)
	c:RegisterEffect(e1)
	
	-- ➁ Gana 1000 de ATK original por cada carta acoplada abajo
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SET_BASE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	
	-- ➂ Puede atacar tantas veces como materiales de fusión usados
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_EXTRA_ATTACK)
	e3:SetValue(s.attval)
	c:RegisterEffect(e3)
	
	-- ➃ Al final del Damage Step: Regresar al Extra Deck, revivir 5 Vijams y buscar
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_DAMAGE_STEP_END)
	e4:SetCondition(s.spcon)
	e4:SetCost(s.spcost)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
	
	-- ➄ Si es enviado al GY por efecto de carta: Mandar 1 Cúbico del Deck al GY
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_TOGRAVE)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCode(EVENT_TO_GRAVE)
	e5:SetCountLimit(1,{id,2})
	e5:SetCondition(s.gycon)
	e5:SetTarget(s.gytg)
	e5:SetOperation(s.gyop)
	c:RegisterEffect(e5)
end

s.listed_names={CARD_VIJAM}
s.listed_series={0xe3} -- Arquetipo Cúbico

-- ① LÓGICA DE ACOPLAMIENTO (CORREGIDA)
function s.ovcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.ovfilter(c)
	return c:IsCode(CARD_VIJAM)
end
function s.ovtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.ovfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
end
function s.ovop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local g=Duel.GetMatchingGroup(s.ovfilter,tp,LOCATION_HAND+LOCATION_DECK,0,nil)
		if #g>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local og=g:Select(tp,1,#g,nil) -- Selecciona desde 1 hasta el máximo disponible
			Duel.Overlay(c,og)
		end
	end
end

-- ➁ VALOR DE ATK BASE
function s.atkval(e,c)
	return c:GetOverlayGroup():FilterCount(Card.IsMonster,nil)*1000
end

-- ➂ VALOR DE ATAQUES ADICIONALES (Fórmula nativa fija)
function s.attval(e,c)
	local g=c:GetMaterial()
	if #g>1 then return #g-1 end -- Si usó 3 materiales, añade 2 ataques extra (3 ataques en total)
	return 0
end

-- ➃ LÓGICA DE RETORNO AL EXTRA DECK (Tu diseño de coste reparado)
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsRelateToBattle()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtraAsCost() end
	Duel.SendtoDeck(c,nil,0,REASON_COST)
end
function s.spfilter(c,e,tp)
	return c:IsCode(CARD_VIJAM) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.thfilter(c)
	return c:IsSetCard(0xe3) and c:IsMonster() and c:IsAbleToHand()
end
-- ➃ REVISIÓN DEL TARGET (Permite de 1 a 5 Vijams)
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
-- ➃ REVISIÓN DE LA OPERACIÓN (Invoca la cantidad elegida y busca)
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 or Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	
	-- Elige el máximo espacio disponible o hasta 5
	local max_spawn=math.min(5,ft)
	
	-- Verifica nuevamente que existan objetivos válidos en el GY antes de pedir la selección
	local sg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
	if #sg==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	-- El usuario ahora puede elegir libremente entre 1 y el máximo calculado (hasta 5)
	local g_summon=sg:Select(tp,1,max_spawn,nil)
	
	if #g_summon>0 and Duel.SpecialSummon(g_summon,0,tp,tp,false,false,POS_FACEUP)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g_search=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g_search>0 then
			Duel.BreakEffect()
			Duel.SendtoHand(g_search,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g_search)
		end
	end
end

-- ➄ MANDAR AL GY POR EFECTO
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_EFFECT)
end
function s.tgfilter(c)
	return c:IsSetCard(0xe3) and c:IsAbleToGrave()
end
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end
