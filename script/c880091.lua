
local s,id=GetID()
function s.initial_effect(c)
	--Negate the effects of cards your opponent controls, up to the number of "Rose" monster you control
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	--e1:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.distg)
	e1:SetOperation(s.disop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	--e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCost(Cost.SelfToDeck)
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end
s.listed_names={CARD_BLACK_ROSE_DRAGON}
--Local no.1
function s.disctfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_ROSE)
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsNegatable() end
	local ct=Duel.GetMatchingGroupCount(s.disctfilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then return ct>0 and Duel.IsExistingTarget(Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,tp,0)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e):Match(Card.IsFaceup,nil)
	if #tg==0 then return end
	local c=e:GetHandler()
	for tc in tg:Iter() do
		--Negate their effects until the end of this turn
		tc:NegateEffects(c,RESET_PHASE|PHASE_END,true)
	end
end
--Local no.2
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local ch=Duel.GetCurrentChain(true)-1
	if ch<=0 then return false end
	local cplayer=Duel.GetChainInfo(ch,CHAININFO_TRIGGERING_CONTROLER)
	local ceff=Duel.GetChainInfo(ch,CHAININFO_TRIGGERING_EFFECT)
	if re:GetHandler():IsDisabled() or not Duel.IsChainDisablable(ev) then return false end
	return ep==1-tp and cplayer==tp and ceff:GetHandler():IsSetCard(SET_ROSE) and ceff:GetHandler():IsMonster()
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not re:GetHandler():IsStatus(STATUS_DISABLED) end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end