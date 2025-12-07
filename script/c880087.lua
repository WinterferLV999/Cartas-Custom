
--scripted by Winterfer
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Synchro Summon Procedure: 1 Tuner + 1+ non-Tuner monsters
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)
	--synlimit
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetValue(s.synlimit)
	c:RegisterEffect(e1)
	--Negate the effects of all face-up cards your opponent currently controls
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
	--A "Black Rose Dragon" that was Synchro Summoned using this card as material cannot be destroyed by card effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e3:SetCode(EVENT_BE_MATERIAL)
	e3:SetCondition(s.con)
	e3:SetOperation(s.op)
	c:RegisterEffect(e3)
	--graveyard synchro
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(id)
	c:RegisterEffect(e4)
	aux.GlobalCheck(s,function()
		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_ADJUST)
		ge2:SetOperation(s.synchk)
		Duel.RegisterEffect(ge2,0)
	end)
end
s.listed_names={CARD_BLACK_ROSE_DRAGON}
s.listed_series={SET_ROSE}
--Local no.1
function s.synlimit(e,c)
	if not c then return false end
	return not (c:IsSetCard(SET_ROSE) or c:IsRace(RACE_DRAGON))
end
--Local no.2
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsLocation(LOCATION_GRAVE) and r==REASON_SYNCHRO
		and e:GetHandler():GetReasonCard():IsSetCard(SET_ROSE_DRAGON)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(Card.IsNegatable,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,tp,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsNegatable,tp,0,LOCATION_ONFIELD,nil)
	if #g==0 then return end
	local c=e:GetHandler()
	for tc in g:Iter() do
		--Negate their effects
		tc:NegateEffects(c,nil,true)
	end
end
--Local no.3
function s.con(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsLocation(LOCATION_GRAVE) and r==REASON_SYNCHRO
		and e:GetHandler():GetReasonCard():IsCode(73580471)
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local sync=c:GetReasonCard()
	--Cannot be destroyed by card effects
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(1)
	e1:SetReset(RESETS_STANDARD_PHASE_END)
	sync:RegisterEffect(e1)
end
--Local no.4
function s.regfilter(c)
	return c.synchro_type and c:IsType(TYPE_SYNCHRO) and c:GetFlagEffect(id+1)==0
end
function s.synchk(e,tp,eg,ep,ev,re,r,rp)
	local sg=Duel.GetMatchingGroup(s.regfilter,tp,0xff,0xff,nil)
	local tc=sg:GetFirst()
	while tc do
		tc:RegisterFlagEffect(id+1,0,0,0)
		local tpe=tc.synchro_type
		local t=tc.synchro_parameters
		if tc.synchro_type==1 then
			local f1,min1,max1,f2,min2,max2,sub1,sub2,req1,req2,reqm=table.unpack(t)
			local e1=Effect.CreateEffect(tc)
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_SPSUMMON_PROC)
			e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
			e1:SetRange(LOCATION_GRAVE)
			e1:SetCondition(Synchro.Condition(f1,min1,max1,f2,min2,max2,sub1,sub2,req1,req2,s.reqm(reqm)))
			e1:SetTarget(Synchro.Target(f1,min1,max1,f2,min2,max2,sub1,sub2,req1,req2,s.reqm(reqm)))
			e1:SetOperation(Synchro.Operation)
			e1:SetValue(SUMMON_TYPE_SYNCHRO)
			tc:RegisterEffect(e1)
		elseif tc.synchro_type==2 then
			local e1=Effect.CreateEffect(tc)
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_SPSUMMON_PROC)
			e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
			e1:SetRange(LOCATION_GRAVE)
			e1:SetCondition(Synchro.Condition(table.unpack(t),s.reqm()))
			e1:SetTarget(Synchro.Target(table.unpack(t),s.reqm()))
			e1:SetOperation(Synchro.Operation)
			e1:SetValue(SUMMON_TYPE_SYNCHRO)
			tc:RegisterEffect(e1)
		elseif tc.synchro_type==3 then
			local e1=Effect.CreateEffect(tc)
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_SPSUMMON_PROC)
			e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
			e1:SetRange(LOCATION_GRAVE)
			e1:SetCondition(Synchro.Condition(table.unpack(t),s.reqm()))
			e1:SetTarget(Synchro.Target(table.unpack(t),s.reqm()))
			e1:SetOperation(Synchro.Operation)
			e1:SetValue(SUMMON_TYPE_SYNCHRO)
			tc:RegisterEffect(e1)
		end
		tc=sg:GetNext()
	end
end
function s.reqm(reqm)
	return function(g,sc,tp)
				return g:IsExists(Card.IsHasEffect,1,nil,id) and (not reqm or reqm(g,sc,tp))
			end
end