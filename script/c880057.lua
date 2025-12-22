
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x10f3),2,2)
	--fusion summon
	local params = {aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_DARK),nil,s.fextra,nil,Fusion.ForcedHandler}
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(Fusion.SummonEffTG(table.unpack(params)))
	e1:SetOperation(Fusion.SummonEffOP(table.unpack(params)))
	c:RegisterEffect(e1)
	--fusion substitute
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_FUSION_SUBSTITUTE)
	e2:SetValue(s.subcon)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(511002961)
	e3:SetRange(LOCATION_ONFIELD+LOCATION_GRAVE)
	c:RegisterEffect(e3)
	--fusattribute
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e0:SetTarget(s.attrtg)
	e0:SetValue(s.attrval)
	e0:SetOperation(s.attrcon)
	c:RegisterEffect(e0)
end
s.counter_place_list={COUNTER_PREDATOR}
function s.filter(c)
	return c:IsFaceup() and c:GetCounter(COUNTER_PREDATOR)>0
end
function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(s.filter),tp,0,LOCATION_MZONE,nil)
end
--local no.0
function s.attrtg(e,c)
	return c:GetCounter(COUNTER_PREDATOR)>0
end
function s.attrval(e,c,rp)
	if rp==e:GetHandlerPlayer() then
		return ATTRIBUTE_DARK
	else return c:GetAttribute() end
end
function s.attrcon(scard,sumtype,tp)
	return (sumtype&MATERIAL_FUSION)~=0
end
--local no.2
function s.subcon(e)
	return e:GetHandler():IsLocation(LOCATION_ONFIELD+LOCATION_GRAVE)
end