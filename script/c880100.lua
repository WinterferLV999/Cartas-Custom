
--Scripted by Winterfer
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_LIGHT),9,4)
	--ATK/DEF
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetValue(function(e,c) return Duel.GetOverlayCount(0,1,1)*800 end)
	--e4:SetCondition(function(e) return e:GetHandler():HasFlagEffect(id+1) end)
	--e4:SetValue(function(e,c) return c:GetFlagEffectLabel(id+1)*300 end)
	--e4:SetValue(s.value)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e5)
	--Cannot be destroyed by battle except with "Number" monsters
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e6:SetValue(aux.NOT(aux.TargetBoolFunction(Card.IsSetCard,SET_NUMBER)))
	c:RegisterEffect(e6)
	aux.GlobalCheck(s,function()
		local oldf=Duel.Overlay
		Duel.Overlay=function(c,g,grave)
			if type(g)=="Card" then
				g=Group.FromCards(g)
			end
			local mg=g:Clone()
			if not grave then g:ForEach(function(gc) mg:Merge(gc:GetOverlayGroup()) end) end
			local rank=mg:GetSum(Card.GetLevel)+g:GetSum(Card.GetRank)
			local label=c:GetFlagEffectLabel(id+1)
			if not label then
				c:RegisterFlagEffect(id+1,RESET_EVENT|RESETS_STANDARD&~RESET_TOFIELD,0,1,rank)
			else
				c:SetFlagEffectLabel(id+1,label+rank)
			end
			return oldf(c,g,grave)
		end
		local oldcf=Card.RegisterEffect
		Card.RegisterEffect=function(c,e,...)
			if e:GetCode()==EFFECT_CANNOT_SPECIAL_SUMMON then
				local oldTg=e:GetTarget()
				e:SetTarget(s.splimit(oldTg))
			end
			return oldcf(c,e,...)
		end
		local oldpf=Duel.RegisterEffect
		Duel.RegisterEffect=function(e,p)
			if e:GetCode()==EFFECT_CANNOT_SPECIAL_SUMMON then
				local oldTg=e:GetTarget()
				e:SetTarget(s.splimit(oldTg))
			end
			return oldpf(e,p)
		end
	end)
	--attack all
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(81927732,0))
	e7:SetType(EFFECT_TYPE_IGNITION)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCondition(s.indcon)
	e7:SetCountLimit(1)
	e7:SetOperation(s.operation)
	c:RegisterEffect(e7,false,REGISTER_FLAG_DETACH_XMAT)
	--negate
	local e8=Effect.CreateEffect(c)
	e8:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e8:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	--e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_F)
	e8:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e8:SetCode(EVENT_CHAINING)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCondition(s.negcon)
	e8:SetTarget(s.negtg)
	e8:SetOperation(s.negop)
	c:RegisterEffect(e8)
end
s.listed_series={SET_NUMBER_C}
function s.splimit(target)
	return function (e,c,...)
		return not c:IsHasEffect(id) and (not target or target(e,c,...))
	end
end
--local no.4
function s.value(e,c)
	return Duel.GetOverlayCount(0,1,1)*800
end
--local no.7
function s.indcon(e)
	return e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,31801517)
end
function s.filter3(c)
	return c:IsFaceup() and c:IsType(TYPE_EFFECT)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end

	-- 1. NEGAR: Todas las cartas boca arriba del oponente
	local g=Duel.GetMatchingGroup(Card.IsNegatable,tp,0,LOCATION_ONFIELD,nil)
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

	-- 2. ABSORBER: Todas las unidades overlay de otros Xyz en el campo
	local xyz_g=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_MZONE,LOCATION_MZONE,c,TYPE_XYZ)
	local og=Group.CreateGroup()
	for xyz_c in aux.Next(xyz_g) do
		og:Merge(xyz_c:GetOverlayGroup())
	end
	if #og>0 then
		Duel.Overlay(c,og)
	end

	-- 3. MULTI-ATAQUE: Puede atacar a todos los monstruos este turno
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_ATTACK_ALL)
	e3:SetValue(1)
	e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e3)
end
--local no.8
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsChainDisablable(ev) then return false end
	local eb,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_FUSION_SUMMON)
	if eb and tg and tg:IsContains(e:GetHandler()) then return true end
	local eb,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_RELEASE)
	if eb and tg and tg:IsContains(e:GetHandler()) then return true end
	local eb,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_CONTROL)
	if eb and tg and tg:IsContains(e:GetHandler()) then return true end
	local eb,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_REMOVE)
	if eb and tg and tg:IsContains(e:GetHandler()) then return true end
	local eb,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
	if eb and tg and tg:IsContains(e:GetHandler()) then return true end
	local eb,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_TODECK)
	if eb and tg and tg:IsContains(e:GetHandler()) then return true end
	local eb,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_TOGRAVE)
	if eb and tg and tg:IsContains(e:GetHandler()) then return true end
	local eb,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_TOHAND)
	if eb and tg and tg:IsContains(e:GetHandler()) then return true end
	return eb and tg and tg:IsContains(e:GetHandler())
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local sg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE,LOCATION_MZONE,e:GetHandler())
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end