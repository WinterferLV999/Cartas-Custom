
--Starving Venemy Predator Dragon
Duel.LoadScript("c420.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Summon procedure
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,s.mfilter2,1,1,s.mfilter1)
	--place counter predator
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.remcon)
	e1:SetTarget(s.cttg)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)
	--place counter venemy
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetOperation(s.acop)
	c:RegisterEffect(e3)
	--disable
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_DISABLE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e4:SetCode(EFFECT_DISABLE)
	e4:SetCountLimit(1)
	e4:SetTarget(function(e,c) return c~=e:GetHandler() end)
	e4:SetOperation(s.disop)
	c:RegisterEffect(e4)
	--copy
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_ADJUST)
	e5:SetRange(LOCATION_MZONE)
	e5:SetOperation(s.operation)
	c:RegisterEffect(e5)
	--atkdown
	--local e6=Effect.CreateEffect(c)
	--e6:SetType(EFFECT_TYPE_FIELD)
	--e6:SetCode(EFFECT_UPDATE_ATTACK)
	--e6:SetRange(LOCATION_PZONE+LOCATION_MZONE)
	--e6:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	--e6:SetTarget(s.atktg)
	--e6:SetValue(s.atkval)
	--c:RegisterEffect(e6)
	--atk up
	--local e7=Effect.CreateEffect(c)
	--e7:SetDescription(aux.Stringid(id,0))
	--e7:SetCategory(CATEGORY_ATKCHANGE)
	--e7:SetType(EFFECT_TYPE_TRIGGER_F+EFFECT_TYPE_SINGLE)
	--e7:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	--e7:SetRange(LOCATION_MZONE)
	--e7:SetCondition(s.atkcon)
	--e7:SetOperation(s.atkop)
	--c:RegisterEffect(e7)
	--gain atk
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(900787,0))
	e8:SetCategory(CATEGORY_ATKCHANGE)
	e8:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e8:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCost(s.cost)
	e8:SetTarget(s.target)
	e8:SetOperation(s.operaxion)
	c:RegisterEffect(e8)
	--Change name
	--local e9=Effect.CreateEffect(c)
	--e9:SetCategory(CATEGORY_DISABLE)
	--e9:SetType(EFFECT_TYPE_IGNITION)
	--e9:SetProperty(EFFECT_FLAG_CARD_TARGET)
	--e9:SetRange(LOCATION_MZONE)
	--e9:SetCountLimit(1)
	--e9:SetTarget(s.distgg2)
	--e9:SetOperation(s.disopp2)
	--c:RegisterEffect(e9)
end
s.counter_list={0x1149}
s.counter_list={COUNTER_PREDATOR}
s.listed_series={0x10f3}
function s.mfilter1(c,fc,sumtype,tp)
	return c:IsSetCard(0x10f3,fc,sumtype,tp) and c:IsType(TYPE_FUSION,sc,st,tp)
end
function s.mfilter2(c,fc,sumtype,tp)
	return c:IsRace(RACE_DRAGON,fc,sumtype,tp) and c:IsType(TYPE_FUSION,sc,st,tp)
end
--local no.1-2
function s.remcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,g,1,0,COUNTER_PREDATOR)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	local tc=g:GetFirst()
	for tc in aux.Next(g) do
		tc:AddCounter(COUNTER_PREDATOR,1)
		if tc:GetLevel()>1 then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CHANGE_LEVEL)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetCondition(s.lvcon)
			e1:SetValue(1)
			tc:RegisterEffect(e1)
		end
	end
end
function s.lvcon(e)
	return e:GetHandler():GetCounter(COUNTER_PREDATOR)>0
end
--local no.3
function s.acop(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(Card.IsPreviousLocation,nil,LOCATION_ONFIELD)
	if ct>0 then
		e:GetHandler():AddCounter(0x1149,ct)
	end
end
--local no.4
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,0,LOCATION_MZONE,LOCATION_MZONE,e:GetHandler())
	local tc=g:GetFirst()
	local c=e:GetHandler()
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
	end
end
--local no.5
function s.copfilter(c)
	return c:IsFaceup() and c:IsStatus(STATUS_DISABLED) and c:GetFlagEffect(id)==0 and c:GetCounter(COUNTER_PREDATOR)>0
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local wg=Duel.GetMatchingGroup(s.copfilter,tp,LOCATION_MZONE,LOCATION_MZONE,c)
	for wbc in aux.Next(wg) do
		if c:IsFaceup() then
			local cid=c:CopyEffect(wbc:GetOriginalCode(),RESET_EVENT+RESETS_STANDARD_DISABLE,1)
			wbc:RegisterFlagEffect(id,0,0,0,cid)
		end
	end
end
--local no.6
function s.atktg(e,c)
	return not (c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_DRAGON) or c:IsRace(RACE_PLANT))
end
function s.atkval(e,c)
	return Duel.GetCounter(0,1,1,0x1149)*-200
end
--local no.7
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler()==Duel.GetAttacker() and Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0x1149)>0
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0x1149)
	if c:IsRelateToBattle() and c:IsFaceup() and ct>0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetReset(RESET_PHASE+PHASE_DAMAGE_CAL+RESET_EVENT+RESETS_STANDARD_DISABLE)
		e1:SetValue(ct*200)
		c:RegisterEffect(e1)
	end
end
--local no.8
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,0x1149,3,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,0x1149,3,REASON_EFFECT)
	return true
end
function s.filter(c)
	return c:IsSummonType(SUMMON_TYPE_SPECIAL) and c:IsFaceup() and c:GetAttack()>0
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,0,LOCATION_MZONE,1,nil) end
end
function s.operaxion(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.filter,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(g:GetSum(Card.GetAttack))
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
		e:GetHandler():RegisterEffect(e1)
	end
end
--local no.9
function s.distgg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) and chkc:IsNegatableMonster() end
	local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
	if chk==0 then return ct>0 and Duel.GetTargetCount(Card.IsNegatableMonster,tp,0,LOCATION_MZONE,nil)==ct end
	local g=Duel.GetMatchingGroup(Card.IsNegatableMonster,tp,0,LOCATION_MZONE,nil)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,0,0)
end
function s.disopp2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetCards(e)
	for tc in aux.Next(g) do
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
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and c:IsRelateToEffect(e) and c:IsFaceup() and tc:IsFaceup() and tc:IsRelateToEffect(e) then
		local code=tc:GetOriginalCode()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetValue(code)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
		c:CopyEffect(code,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,1)
	end
end