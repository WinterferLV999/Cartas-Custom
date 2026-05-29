
local s,id=GetID()
function s.initial_effect(c)
	--code
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CHANGE_CODE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e2:SetValue(CARD_VIJAM)
	c:RegisterEffect(e2)
	--effect
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
	--special summon
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(TIMING_DAMAGE_STEP)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SUMMON_SUCCESS)
		ge1:SetLabel(id)
		ge1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		ge1:SetOperation(aux.sumreg)
		Duel.RegisterEffect(ge1,0)
		local ge2=ge1:Clone()
		ge2:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge2:SetLabel(id)
		Duel.RegisterEffect(ge2,0)
	end)
end
--local no.1
s.listed_names={15610297}
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id)>0
end
function s.spfilter(c,e,tp)
	return c:IsCode(15610297) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND|LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
--local no.3
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return re and re:IsActiveType(TYPE_MONSTER) and re:GetHandler():IsSetCard(0xe3)
end
function s.thfilter(c)
	return c:IsCode(802) or c:IsCode(15610297) and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
--otra eleccion del no.3
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_GRAVE)
end
function s.thfilter(c)
	return c:IsCode(802) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end