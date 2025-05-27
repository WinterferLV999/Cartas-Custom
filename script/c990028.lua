
local s,id=GetID()
function s.initial_effect(c)
	--synchro summon
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()
	--multi attack
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.mtcon)
	e1:SetOperation(s.mtop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_MATERIAL_CHECK)
	e2:SetValue(s.valcheckk)
	e2:SetLabelObject(e1)
	c:RegisterEffect(e2)
	--opponent's turn synchro
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(575512,0))
	e3:SetHintTiming(0,TIMING_END_PHASE+TIMING_MAIN_END)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetRange(LOCATION_EXTRA)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetCondition(s.syncon)
	e3:SetTarget(s.syntg)
	e3:SetOperation(s.synop)
	c:RegisterEffect(e3)
	--atkup
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetRange(LOCATION_MZONE)
	e4:SetValue(s.value)
	c:RegisterEffect(e4)
	--Destroy replace
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_DESTROY_REPLACE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTarget(s.desreptg)
	e5:SetOperation(s.desrepop)
	c:RegisterEffect(e5)
end
--local no.1,2
function s.mfilter(c)
	return c:IsSetCard(0x27)
end
function s.valcheckk(e,c)
	local g=c:GetMaterial()
	local ct=g:FilterCount(s.mfilter,nil)
	e:GetLabelObject():SetLabel(ct)
end
function s.mtcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO) and e:GetLabel()>0
end
function s.mtop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=e:GetLabel()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EXTRA_ATTACK)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
	e1:SetValue(ct-1)
	c:RegisterEffect(e1)
end
--local no.3
function s.syncon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp and not e:GetHandler():IsStatus(STATUS_CHAINING) and Duel.GetCurrentChain()==0
end
function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsSynchroSummonable(nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,LOCATION_EXTRA)
end
function s.synop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SynchroSummon(tp,c,nil)
	end
end
--local no.4
function s.atkfilter(c)
	return c:IsMonster() and c:IsSetCard(0x27) and c:IsType(TYPE_TUNER)
end
function s.value(e,c)
	return Duel.GetMatchingGroupCount(s.atkfilter,c:GetControler(),LOCATION_GRAVE,0,nil)*300
end
--local no.5
function s.desreptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsReason(REASON_REPLACE) and c:IsOnField() and c:IsFaceup() 
		and c:IsAbleToExtra() end
	return true
end
function s.mgfilter(c,e,tp,sync)
	return c:IsControler(tp) and c:IsLocation(LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED)
		and c:GetReason()&0x80008==0x80008 and c:GetReasonCard()==sync
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.desrepop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local sumtype=c:GetSummonType()
	local mg=c:GetMaterial():Filter(aux.NecroValleyFilter(s.mgfilter),nil,e,tp,c)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft>1 and Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	if Duel.SendtoDeck(c,nil,0,REASON_EFFECT+REASON_REPLACE)>0 
		and sumtype==SUMMON_TYPE_SYNCHRO and #mg>0 
		and #mg<=ft then
		Duel.SpecialSummon(mg,0,tp,tp,false,false,POS_FACEUP)
	end
end
