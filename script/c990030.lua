
local s,id=GetID()
function s.initial_effect(c)
	--synchro summon
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()
	--code
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CHANGE_CODE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE+LOCATION_GRAVE+LOCATION_EXTRA+LOCATION_REMOVED)
	e0:SetValue(44508094)
	c:RegisterEffect(e0)
	--Negate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.condition)
	--e1:SetCost(aux.StardustCost)
	e1:SetCost(aux.bfgcost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	--Revive
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(5592689,0))
	e2:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_FIELD)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_REMOVED)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.sscon)
	e2:SetTarget(s.sstg)
	e2:SetOperation(s.ssop)
	c:RegisterEffect(e2)
end
--local no.1
function s.cfilter(c,tp)
	return c:IsOnField() and c:IsMonster() and c:IsControler(tp) and c:IsFaceup()
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    if tp==ep or not Duel.IsChainNegatable(ev) then return false end
    local ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
    if ex and tg~=nil and tc+tg:FilterCount(s.cfilter,nil,tp)-#tg>0 then
        return true
    end
    ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_TOHAND)
    if ex and tg~=nil and tc+tg:FilterCount(s.cfilter,nil,tp)-#tg>0 then
        return true
    end
    ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_REMOVE)
    if ex and tg~=nil and tc+tg:FilterCount(s.cfilter,nil,tp)-#tg>0 then
        return true
    end
    ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_TODECK)
    if ex and tg~=nil and tc+tg:FilterCount(s.cfilter,nil,tp)-#tg>0 then
        return true
    end
    ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_RELEASE)
    if ex and tg~=nil and tc+tg:FilterCount(s.cfilter,nil,tp)-#tg>0 then
        return true
    end
    ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_TOGRAVE)
    if ex and tg~=nil and tc+tg:FilterCount(s.cfilter,nil,tp)-#tg>0 then
        return true
    end
    return false
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local rc=re:GetHandler()
	local relation=rc:IsRelateToEffect(re)
	if chk==0 then return rc:IsAbleToRemove(tp)
		or (not relation and Duel.IsPlayerCanRemove(tp)) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if relation then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,rc,1,rc:GetControler(),rc:GetLocation())
	else
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,0,0,rc:GetPreviousLocation())
	end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)
	end
	--e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,0)
end
--local no.2
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
	return tp==Duel.GetTurnPlayer()
end
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetFlagEffect(id+1)==0 end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	e:GetHandler():RegisterFlagEffect(id+1,RESET_EVENT+0x4760000+RESET_PHASE+PHASE_END,0,1)
end
function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
			Duel.SendtoGrave(e:GetHandler(),REASON_EFFECT)
			return
		end
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end
