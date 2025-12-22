
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.counter_place_list={COUNTER_PREDATOR}
s.counter_place_list={0x1041}
s.listed_series={0x10f3}
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--fusattribute
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetTarget(s.attrtg)
	e1:SetValue(s.attrval)
	e1:SetOperation(s.attrcon)
	Duel.RegisterEffect(e1,tp)
	local e3=Effect.CreateEffect(e:GetHandler())
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_ADD_SETCODE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e3:SetReset(RESET_PHASE+PHASE_END)
	e3:SetTarget(s.attrtg)
	e3:SetValue(0x10f3)
	e3:SetOperation(s.attrcon)
	Duel.RegisterEffect(e3,tp)
	--chain material
	local e4=Effect.CreateEffect(e:GetHandler())
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CHAIN_MATERIAL)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetReset(RESET_PHASE+PHASE_END)
	e4:SetTargetRange(1,0)
	e4:SetTarget(s.chtg)
	e4:SetOperation(s.chop)
	e4:SetValue(aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_DARK))
	Duel.RegisterEffect(e4,tp)
	local e5=Effect.CreateEffect(e:GetHandler())
	e5:SetOperation(s.chk)
	Duel.RegisterEffect(e5,tp)
end
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
--local no.4
function s.chfilter(c,e,tp)
	return c:IsMonster() and (c:IsFaceup() or c:IsControler(tp)) and c:IsCanBeFusionMaterial() and not c:IsImmuneToEffect(e)
end
function s.chtg(e,te,tp,value)
	if value&SUMMON_TYPE_FUSION==0 then return Group.CreateGroup() end
	return Duel.GetMatchingGroup(s.chfilter,tp,LOCATION_MZONE+LOCATION_HAND,LOCATION_MZONE,nil,te,tp)
end
function s.chop(e,te,tp,tc,mat,sumtype,sg,sumpos)
	if not sumtype then sumtype=SUMMON_TYPE_FUSION end
	tc:SetMaterial(mat)
	Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	if mat:IsExists(Card.IsControler,6,nil,1-tp) then
		Duel.SetChainLimit(aux.FALSE)
	end
	Duel.BreakEffect()
	if sg then
		sg:AddCard(tc)
	else
		Duel.SpecialSummon(tc,sumtype,tp,tp,false,false,sumpos)
	end
end
--local no.5
function s.chk(tp,sg,fc)
	return sg:FilterCount(Card.IsControler,nil,1-tp)<=6
end