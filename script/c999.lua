--prueba no.3
local s,id=GetID()
function s.initial_effect(c)
	--fusion material
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,s.mfilter2,2,99,s.mfilter1)
	--add counter
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.no_chain_ct_con)
	e1:SetOperation(s.no_chain_ct_op)
	c:RegisterEffect(e1)
	--local e1=Effect.CreateEffect(c)
	--e1:SetDescription(aux.Stringid(id,0))
	--e1:SetCategory(CATEGORY_COUNTER)
	--e1:SetCountLimit(1,id)
	--e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	--e1:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	--e1:SetCode(EVENT_PHASE+PHASE_END)
	--e1:SetRange(LOCATION_MZONE)
	--e1:SetTarget(s.target)
	--e1:SetOperation(s.activate)
	--c:RegisterEffect(e1)
	--immune
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetCondition(s.spcon)
	e2:SetTarget(function(_,c) return c:GetCounter(0x1041)>0 end)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)
	--destroy replace
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTarget(s.reptg)
	c:RegisterEffect(e3)
end
s.counter_place_list={COUNTER_PREDATOR}
s.listed_series={0x10f3}
function s.mfilter1(c,fc,sumtype,tp)
	return c:IsSetCard(0x10f3,fc,sumtype,tp) and c:IsType(TYPE_FUSION,fc,sumtype,tp)
end
function s.mfilter2(c,fc,sumtype,tp)
	return c:GetCounter(0x1041)>0 and c:IsOnField()
end
--local no.1
function s.no_chain_ct_con(e,tp,eg,ep,ev,re,r,rp)
	-- El radar continuo verifica si este monstruo (e:GetHandler()) está en el grupo que acaba de pisar el campo
	return eg:IsContains(e:GetHandler())
end
function s.no_chain_ct_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Clava los 2 contadores directamente en el mapa de bits del monstruo boca arriba en el acto
	if c:IsFaceup() then
		c:AddCounter(0x1041,2)
	end
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,g,1,0,COUNTER_PREDATOR)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
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
--local no.2
function s.filter(c)
	return c:IsFaceup() and c:GetCounter(0x1041)>0 and c:GetCode()~=id
end
function s.spcon(e,c)
	if c==nil then return true end
	return Duel.GetLocationCount(c:GetControler(),tp,LOCATION_MZONE,LOCATION_MZONE)>0 and
		Duel.IsExistingMatchingCard(s.filter,c:GetControler(),tp,LOCATION_MZONE,LOCATION_MZONE,0,1,nil)
end
function s.econ(e)
	return e:GetHandler():GetCounter(0x1041)>0
end
function s.efilter(e,re)
	return re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end
--local no.3
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsReason(REASON_BATTLE)
		and e:GetHandler():IsCanRemoveCounter(tp,0x1041,1,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,0x1041,1,REASON_EFFECT)
	return true
end


