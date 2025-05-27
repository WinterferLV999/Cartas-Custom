
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--fusattribute
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(s.attrtg)
	e2:SetValue(ATTRIBUTE_DARK)
	--e2:SetOperation(s.attrcon)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_ADD_SETCODE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e3:SetTarget(s.attrtg)
	e3:SetValue(0x10f3)
	--e3:SetOperation(s.attrcon)
	c:RegisterEffect(e3)
	--tribute
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(33900648,1))
	e7:SetCategory(CATEGORY_RELEASE+CATEGORY_DESTROY)
	e7:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e7:SetRange(LOCATION_SZONE)
	e7:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e7:SetCountLimit(1)
	e7:SetCondition(s.descon)
	--e7:SetTarget(s.destg)
	e7:SetOperation(s.desop)
	c:RegisterEffect(e7)
end
--local no.1
function s.costfilter(c)
	return c:IsSpell() and c:IsType(TYPE_CONTINUOUS) and c:IsFaceup()
end
function s.cost(e,tp,eg,ev,ep,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local tg=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,e:GetHandler())
	Duel.Destroy(tg,REASON_COST)
end
function s.tgfilter(c)
	return c:IsFaceup() and c:GetCounter(0x1041)==0
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--local g=Duel.GetMatchingGroup(s.tgfilter,tp,0,LOCATION_MZONE,nil)
	--Duel.Destroy(g,REASON_EFFECT)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetOperation(s.ctop1)
	e1:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,3)
	Duel.RegisterEffect(e1,tp)
	local e2=e1:Clone()
	e2:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	Duel.RegisterEffect(e2,tp)
	local e3=e1:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetOperation(s.ctop2)
	Duel.RegisterEffect(e3,tp)
end
function s.ctop1(e,tp,eg,ep,ev,re,r,rp)
	if ep~=tp then
		eg:GetFirst():AddCounter(0x1041,1)
	end
end
function s.ctop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	for tc in aux.Next(eg) do
		if tc:IsFaceup() and not tc:IsSummonPlayer(tp) then
			tc:AddCounter(0x1041,1)
		end
	end
end
--local no.2-3
function s.attrtg(e,c)
	return c:GetCounter(0x1041)>0
end
function s.attrval(e,c,rp)
	if rp==e:GetHandlerPlayer() then
		return ATTRIBUTE_DARK
	else return c:GetAttribute() end
end
function s.attrcon(scard,sumtype,tp)
	return (sumtype&MATERIAL_FUSION)~=0
end
--local no.7
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return tp==Duel.GetTurnPlayer()
end
function s.filter(c)
	return c:IsSetCard(0x10f3) and c:IsReleasableByEffect()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.filter(chkc) end
	if chk==0 then return true end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
	if #g==0 then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
	end
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.CheckReleaseGroup(tp,nil,1,nil) and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		local sg=Duel.SelectReleaseGroup(tp,nil,1,1,nil)
		Duel.Release(sg,REASON_COST)
	else
		Duel.Destroy(e:GetHandler(),REASON_RULE)
	end
end