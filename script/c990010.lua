
local s,id=GetID()
function s.initial_effect(c)
	--synchro limit no.1
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetValue(s.synlimit)
	c:RegisterEffect(e1)
	--synchro limit no.2
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetValue(s.ssynlimit)
	c:RegisterEffect(e2)
	-- Opponent cannot activate cards or effects on Special Summon
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCondition(s.tncon)
	e3:SetOperation(s.chlimop)
	c:RegisterEffect(e3)
	--spsummon
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(57421866,0))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetCountLimit(1,id)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetTarget(s.target)
	e4:SetOperation(s.operation)
	c:RegisterEffect(e4)
end
--local no.1
function s.synlimit(e,c)
	if not c then return false end
	return not c:IsAttribute(ATTRIBUTE_DARK) and c:IsLevelAbove(6)
end
--local no.2
function s.ssynlimit(e,c)
	if not c then return false end
	return not c:IsLevelAbove(6)
end
--local no.3
function s.tncon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_GRAVE)
end
function s.chlimop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.HasFlagEffect(tp,id) then return end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
	local c=e:GetHandler()
	--Your opponent cannot activate cards or effects when your "Red" monster(s) is Normal/Special Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetOperation(s.limop)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	Duel.RegisterEffect(e2,tp)
	local e3=e1:Clone()
	e3:SetCode(EVENT_CHAIN_END)
	e3:SetOperation(s.limop2)
	Duel.RegisterEffect(e3,tp)
	aux.RegisterClientHint(c,nil,tp,1,0,aux.Stringid(id,3))
end
function s.limfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp)
end
function s.limop(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(s.limfilter,1,nil,tp) then
		Duel.SetChainLimitTillChainEnd(function(re,rp,tp) return rp==tp end)
	end
end
function s.limop2(e,tp,eg,ep,ev,re,r,rp)
	local ex,sg=Duel.CheckEvent(EVENT_SPSUMMON_SUCCESS,true)
	if ex and sg:IsExists(s.limfilter,1,nil,tp) then
		Duel.SetChainLimitTillChainEnd(function(re,rp,tp) return rp==tp end)
	end
end
--local no.4
function s.filter(c)
	return c:IsFaceup() and c:GetLevel()>=6
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter(chkc) end
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(57421866,1))
	Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsFacedown() or not tc:IsRelateToEffect(e) or tc:IsImmuneToEffect(e) or tc:GetLevel()<2 then return end
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_LEVEL)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetValue(-1)
	tc:RegisterEffect(e1)
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end
