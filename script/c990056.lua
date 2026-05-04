local s,id=GetID()
function s.initial_effect(c)
	-- Invocación por Fusión
	c:EnableReviveLimit()
	-- 1 monstruo "Edge Imp" + 1 o más monstruos "Fluffal"
	Fusion.AddProcMixRep(c,true,true,s.ffilter,1,99,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_EDGE_IMP))

	-- EFECTO 1: Desterrar cartas según materiales al ser invocado
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.remcon)
	e1:SetTarget(s.remtg)
	e1:SetOperation(s.remop)
	c:RegisterEffect(e1)

	-- EFECTO 2: Efecto rápido heredado (Si usó a Fluffal Bat - 990045)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCondition(s.quickcon)
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
s.listed_names={990045} 

-- Filtro para materiales Fluffal
function s.ffilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_FLUFFAL,fc,sumtype,tp)
end

-- Lógica Efecto 1: Destierro masivo
function s.remcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.remtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	local ct=c:GetMaterialCount()
	if chkc then return chkc:IsControler(1-tp) and chkc:IsAbleToRemove() and chkc:IsLocation(LOCATION_ONFIELD+LOCATION_GRAVE) end
	if chk==0 then return ct>0 and Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end
function s.remop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end

-- Lógica Efecto 2: Quick Effect (Heredado de Fluffal Bat)
function s.quickcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_FUSION) and c:GetMaterial():IsExists(Card.IsCode,1,nil,990045)
end
function s.quicktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsAbleToRemove() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end
function s.quickop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end

-- Lógica Efecto 3: Aumento de ATK dinámico
function s.atkfilter(c)
	return c:IsFaceup() and (c:IsSetCard(SET_FLUFFAL) or c:IsSetCard(SET_FRIGHTFUR))
end
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.atkfilter,c:GetControler(),LOCATION_MZONE,LOCATION_MZONE,nil)*300
end
