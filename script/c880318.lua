
Duel.LoadScript("c420.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.thcon2)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	--code
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CHANGE_CODE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetValue(CARD_VIJAM)
	c:RegisterEffect(e2)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(1131)
	e4:SetCategory(CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_QUICK_O+EFFECT_TYPE_XMATERIAL)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCost(s.dcost)
	e4:SetTarget(s.dtarget)
	e4:SetOperation(s.doperation)
	c:RegisterEffect(e4)
end
function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_GRAVE)
end
function s.filter(c,e,tp)
	return c:IsMonster() and c:IsSetCard(0xe3) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_GRAVE+LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_HAND+LOCATION_DECK)
end
function s.cfilter(c,tc)
	return c:IsFaceup() and c:IsSetCard(0xe3)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_GRAVE+LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if #g>0 and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
		local xg=Group.FromCards(c,tc)
		local xge=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_MZONE,0,0,99,xg):Merge(c)
		Duel.Overlay(tc,xge,true)
	end
end
--local no.4
function s.dcfilter(c)
	return c:IsCode(id)
end
function s.ddcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local ov=c:GetOverlayGroup()
	if chk==0 then return ov:IsExists(s.dcfilter,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVEXYZ)
	local tov=ov:FilterSelect(tp,s.dcfilter,1,1,nil)
	Duel.SendtoGrave(tov,REASON_COST)
end
function s.dcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.ccfilter(c)
	return c:IsSummonType(SUMMON_TYPE_SPECIAL) and c:IsFaceup() and c:GetAttack()>0
end
function s.dtarget(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.ccfilter,tp,0,LOCATION_MZONE,1,nil) end
end
function s.doperation(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.ccfilter,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(g:GetSum(Card.GetAttack))
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
		e:GetHandler():RegisterEffect(e1)
	end
end
