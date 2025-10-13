
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--The activation and effect of e1 cannot be negated if your LP are lower than your opponent's
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD)
		ge1:SetCode(EFFECT_CANNOT_INACTIVATE)
		ge1:SetValue(s.effectfilter)
		Duel.RegisterEffect(ge1,0)
		local ge2=ge1:Clone()
		ge2:SetCode(EFFECT_CANNOT_DISEFFECT)
		Duel.RegisterEffect(ge2,0)
	end)
end
function s.effectfilter(e,ct)
	local te,tp=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
	return te:GetLabel()==id and c:IsFaceup() and c:IsCode(31801517)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local bc=Duel.GetAttackTarget()
	if not bc then return false end
	local tc=Duel.GetAttacker()
	if not tc:IsControler(tp) then tc,bc=bc,tc end
	e:SetLabelObject(tc)
	return tc:IsControler(tp) and not bc:IsControler(tp)
	and Duel.GetLP(1-tp)-Duel.GetLP(tp)>=3000
end
function s.selfilter(c)
	return c:IsFaceup() and c:IsCode(98555327)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	--if chk==0 then return Duel.IsExistingMatchingCard(s.selfilter,tp,LOCATION_MZONE,0,1,nil) end
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_MZONE,0,1,nil) end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	--local g=Duel.SelectMatchingCard(tp,s.selfilter,tp,LOCATION_MZONE,0,1,1,nil)
	local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,LOCATION_MZONE,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.HintSelection(g)
		--if Duel.GetLP(tp)>8000 or Duel.GetLP(1-tp)>8000 or Duel.GetLP(tp)==Duel.GetLP(1-tp) then return end
		--local val=0
		if Duel.GetLP(tp)>Duel.GetLP(1-tp) then
			val=Duel.GetLP(tp)-Duel.GetLP(1-tp)
		else
			val=Duel.GetLP(1-tp)-Duel.GetLP(tp)
		end
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		e1:SetValue(val*2)
		tc:RegisterEffect(e1)
	end
end