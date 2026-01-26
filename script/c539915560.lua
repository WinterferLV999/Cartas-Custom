--スターヴ・ヴェノム・プレデター・フュージョン・ドラゴン
--Starving Venom Predapower Fusion Dragon
--Scripted by Eerie Code
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Summon procedure
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,s.mfilter2,1,1,s.mfilter1)
	--copy
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,2))
	e0:SetCategory(CATEGORY_DISABLE+CATEGORY_ATKCHANGE)
	e0:SetType(EFFECT_TYPE_QUICK_O)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCountLimit(1)
	e0:SetCondition(s.copycon)
	e0:SetTarget(s.copytg)
	e0:SetOperation(s.copyop)
	c:RegisterEffect(e0)
	--Negate activation
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RELEASE+CATEGORY_NEGATE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
	--Special Summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end
s.counter_list={COUNTER_PREDATOR}
s.listed_series={SET_PREDAPLANT}
function s.mfilter1(c,sc,st,tp)
	return c:IsAttribute(ATTRIBUTE_DARK,sc,st,tp) and c:IsType(TYPE_FUSION,sc,st,tp)
end
function s.mfilter2(c,fc,sumtype,tp)
	return c:IsSetCard(SET_STARVING_VENOM,fc,sumtype,tp) and c:IsOnField()
end
function s.copycon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsTurnPlayer(tp) and (Duel.IsMainPhase() or Duel.IsBattlePhase())
end
function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.atkdisfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.atkdisfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.atkdisfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,tp,0)
end
function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and c:IsRelateToEffect(e) and c:IsFaceup() and tc:IsRelateToEffect(e) and tc:IsFaceup() and c:UpdateAttack(tc:GetAttack(),RESET_EVENT+RESETS_STANDARD) and not tc:IsType(TYPE_TOKEN) then
		--Copy name
		local code=tc:GetOriginalCodeRule()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetValue(code)
		e1:SetReset(RESETS_STANDARD)
		c:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_DISABLE_EFFECT)
		e3:SetValue(RESET_TURN_SET)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e3)
		if not tc:IsType(TYPE_TRAPMONSTER) then
		--Copy effects
			c:CopyEffect(tc:GetOriginalCode(),RESET_EVENT+RESETS_STANDARD,1)
		end
	    if tc:IsRelateToEffect(e) and tc:AddCounter(COUNTER_PREDATOR,1) and tc:GetLevel()>1 then
		    local e1=Effect.CreateEffect(e:GetHandler())
		    e1:SetType(EFFECT_TYPE_SINGLE)
		    e1:SetCode(EFFECT_CHANGE_LEVEL)
		    e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		    e1:SetCondition(s.lvcon)
		    e1:SetValue(1)
		    tc:RegisterEffect(e1)
		end
	end
end
function s.lvcon(e)
	return e:GetHandler():GetCounter(COUNTER_PREDATOR)>0
end
--Local no.1
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev)
end
function s.negcfilter(c)
	return c:IsFaceup() and c:GetCounter(COUNTER_PREDATOR)>0 and c:IsReleasableByEffect()
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.negcfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,s.negcfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	if #g>0 and Duel.Release(g,REASON_EFFECT)>0 then
		Duel.NegateActivation(ev)
	end
end
--Local no.2
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsFusionSummoned() and rp==1-tp
end
function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end