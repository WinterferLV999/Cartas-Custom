
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Fynchro Summon Procedure: "Red-Eyes Black Dragon" + "Red-Eyes Darkness Dragon" on the field
	--Fusion.AddProcMix(c,true,true,CARD_REDEYES_B_DRAGON,96561011)
	Fusion.AddProcMixRep(c,true,true,s.mfilter2,1,1,s.mfilter1)
	--atkup
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)
	--disable
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetRange(LOCATION_MZONE)
	--e2:SetCondition(s.discon)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)
	--Negate the activation of the effect
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAIN_ACTIVATING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.negcon)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end
s.listed_names={CARD_REDEYES_B_DRAGON}
s.material_setcode=SET_RED_EYES
function s.mfilter1(c,fc,sumtype,tp)
	return c:IsCode(74677422) and c:IsOnField()
end
function s.mfilter2(c,fc,sumtype,tp)
	return c:IsCode(96561011) and c:IsOnField()
end
--local no.1
function s.atkfilter(c)
	return c:IsMonster() and c:IsRace(RACE_DRAGON)
end
function s.atkval(e,c)
	return Duel.GetMatchingGroup(s.atkfilter,e:GetHandlerPlayer(),LOCATION_GRAVE,0,nil):GetClassCount(Card.GetCode)*500
end
function s.value(e,c)
	return Duel.GetMatchingGroupCount(s.atkfilter,c:GetControler(),LOCATION_GRAVE,0,nil)*500
end
--local no.2
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	if rp==1-tp and re:IsMonsterEffect() and (loc==LOCATION_MZONE)
		and re:GetHandler():IsAttackBelow(e:GetHandler():GetAttack()) then
		Duel.NegateEffect(ev)
	end
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	if e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) then return false end
	return rp==1-tp and re:IsMonsterEffect() and re:GetHandler():IsAttackBelow(e:GetHandler():GetAttack())
end
function s.disopp(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end
--local no.3
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return (re:IsHasType(EFFECT_TYPE_ACTIVATE) or re:IsActiveType(TYPE_SPELL)) and e:GetHandler():GetFlagEffect(id)==0
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsHasEffect(EFFECT_REVERSE_UPDATE) then
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
	end
	if c:GetFlagEffect(id)>0 or c:GetAttack()<1000 or Duel.GetCurrentChain()~=ev or c:IsStatus(STATUS_BATTLE_DESTROYED) then
		return
	end
	Duel.Hint(HINT_CARD,tp,id)
	Duel.Hint(HINT_CARD,1-tp,id)
	if Duel.NegateActivation(ev) then
		if re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:GetHandler():IsRelateToEffect(re) then
			Duel.SendtoGrave(re:GetHandler(),REASON_EFFECT)
		end
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_COPY_INHERIT)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD_DISABLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-1000)
		c:RegisterEffect(e1)
	end
end