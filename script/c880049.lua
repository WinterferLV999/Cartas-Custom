
local s,id=GetID()
function s.initial_effect(c)
	--Synchro Summon Procedure
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(s.predafilter),1,1,Synchro.NonTunerEx(s.matfilter),1,1)
	c:EnableReviveLimit()
	--c:EnableCounterPermit(0x1041)
	--c:SetCounterLimit(0x1041)
	--indes
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCondition(function(e) return e:GetHandler():GetCounter(0x1041)>0 end)
	--e0:SetCondition(function(e) return e:GetHandler():GetCounter(0x1041)==1 end)
	e0:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e0:SetValue(1)
	c:RegisterEffect(e0)
	local e1=e0:Clone()
	e1:SetCondition(function(e) return e:GetHandler():GetCounter(0x1041)>0 end)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	c:RegisterEffect(e1)
	--Negate Spell effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.discon)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)
	--Negate Trap effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAIN_SOLVING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.doscon)
	e3:SetOperation(s.disop)
	c:RegisterEffect(e3)
end
s.listed_names={id}
s.counter_place_list={0x1041}
function s.predafilter(c,sc,st,tp)
	return c:GetCounter(0x1041)>0
end
function s.matfilter(c,val,scard,sumtype,tp)
	return c:IsSetCard(SET_PREDAPLANT)
end
--Local no.2,3
function s.cfilter(c,seq,p)
	return c:IsFaceup() and c:GetCounter(0x1041)>0 and c:IsColumn(seq,p,LOCATION_SZONE)
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not re:IsSpellEffect() then return false end
	local rc=re:GetHandler()
	local p,loc,seq=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_CONTROLER,CHAININFO_TRIGGERING_LOCATION,CHAININFO_TRIGGERING_SEQUENCE)
	if re:IsHasType(EFFECT_TYPE_ACTIVATE) and (loc&LOCATION_SZONE==0 or rc:IsControler(1-p)) then
		if rc:IsLocation(LOCATION_SZONE) and rc:IsControler(p) then
			seq=rc:GetSequence()
			loc=LOCATION_SZONE
		else
			seq=rc:GetPreviousSequence()
			loc=rc:GetPreviousLocation()
		end
	end
	return loc&LOCATION_SZONE==LOCATION_SZONE and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil,seq,p)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end
function s.doscon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not re:IsTrapEffect() then return false end
	local rc=re:GetHandler()
	local p,loc,seq=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_CONTROLER,CHAININFO_TRIGGERING_LOCATION,CHAININFO_TRIGGERING_SEQUENCE)
	if re:IsHasType(EFFECT_TYPE_ACTIVATE) and (loc&LOCATION_SZONE==0 or rc:IsControler(1-p)) then
		if rc:IsLocation(LOCATION_SZONE) and rc:IsControler(p) then
			seq=rc:GetSequence()
			loc=LOCATION_SZONE
		else
			seq=rc:GetPreviousSequence()
			loc=rc:GetPreviousLocation()
		end
	end
	return loc&LOCATION_SZONE==LOCATION_SZONE and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil,seq,p)
end
