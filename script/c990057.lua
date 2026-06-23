local s,id=GetID()
function s.initial_effect(c)
	-- Invocación por Fusión
	c:EnableReviveLimit()
	-- 1 monstruo "Edge Imp" + 1 o más monstruos "Fluffal"
	Fusion.AddProcMixRep(c,true,true,s.ffilter,1,99,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_EDGE_IMP))
	
	-- EFECTO ①: Al ser invocado por Fusión, niega cartas del rival de forma permanente (Sin SelectTarget)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.discon)
	e1:SetTarget(s.distg)     
	e1:SetOperation(s.disop)   
	c:RegisterEffect(e1)
	
	-- EFECTO ②: Efecto rápido heredado (Copiado exactamente de la estructura de tu referencia)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id) -- Mantiene el límite de nombre compartido que querías
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
	e2:SetCondition(s.quickcon) -- Verifica de forma directa la herencia del material 990047
	e2:SetTarget(s.quicktg)
	e2:SetOperation(s.quickop)
	c:RegisterEffect(e2)

	-- EFECTO 3: Gana 300 ATK por cada "Fluffal" y "Frightfur" en el campo
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)
end

s.listed_series={SET_EDGE_IMP,SET_FLUFFAL,SET_FRIGHTFUR}
s.listed_names={990045,990047} 

-- Filtro para materiales Fluffal
function s.ffilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_FLUFFAL,fc,sumtype,tp)
end

-- Condición del Efecto ①: Exige que el monstruo sea Invocado por Fusión
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

-- Target del Efecto ① (Ultra-Simple antierrores de tu core)
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,1-tp,LOCATION_ONFIELD)
end

-- Operación del Efecto ①: Negación masiva permanente en base a materiales
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mc=c:GetMaterialCount()
	if mc<=0 then return end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_ONFIELD,nil)
	if #g==0 then return end
	if #g<mc then mc=#g end
	local tg=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,mc,nil)
	if #tg>0 then
		Duel.HintSelection(tg)
		for tc in aux.Next(tg) do
			if tc:IsFaceup() and not tc:IsDisabled() then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DISABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD) 
				tc:RegisterEffect(e1)
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_DISABLE_EFFECT)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD) 
				tc:RegisterEffect(e2)
			end
		end
	end
end

-- --- LÓGICA EFECTO ②: QUICK EFFECT (Basado milimétricamente en tu referencia) ---
-- Condición: Exige que haya sido invocado por Fusión y que se encuentre el ID 990047 en los materiales
function s.quickcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_FUSION) and c:GetMaterial():IsExists(Card.IsCode,1,nil,990047)
end

function s.quicktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and chkc:IsNegatable() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.quickop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and ((tc:IsFaceup() and not tc:IsDisabled()) or tc:IsType(TYPE_TRAPMONSTER)) and tc:IsRelateToEffect(e) then
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESETS_STANDARD_PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESETS_STANDARD_PHASE_END)
		tc:RegisterEffect(e2)
		if tc:IsType(TYPE_TRAPMONSTER) then
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
			e3:SetReset(RESETS_STANDARD_PHASE_END)
			tc:RegisterEffect(e3)
		end
	end
end
-- Lógica Efecto 3: Aumento de ATK dinámico
function s.atkfilter(c)
	return c:IsFaceup() and (c:IsSetCard(SET_FLUFFAL) or c:IsSetCard(SET_FRIGHTFUR))
end
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.atkfilter,c:GetControler(),LOCATION_MZONE,LOCATION_MZONE,nil)*300
end
