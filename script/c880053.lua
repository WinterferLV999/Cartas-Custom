
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x10f3),2,2)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
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