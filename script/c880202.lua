
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion Materials: "Dark Rebellion Xyz Dragon" + 1 "Starving Venom" monster
	Fusion.AddProcMixN(c,false,false,16195942,1,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_STARVING_VENOM),1)
	c:AddMustBeFusionSummoned()
	--pendulum summon
	Pendulum.AddProcedure(c,false)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(54936498,0))
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTarget(s.tg)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
	--prevent effect activation
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.cpcon)
	e2:SetCost(s.cost)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
	--copy
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.atktg)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
	--Place itself into pendulum zone
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,3))
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetProperty(EFFECT_FLAG_DELAY)
	e6:SetCode(EVENT_LEAVE_FIELD)
	e6:SetCountLimit(1,id)
	e6:SetCondition(s.pencon)
	e6:SetTarget(s.pentg)
	e6:SetOperation(s.penop)
	c:RegisterEffect(e6)
end
--Local No.1
function s.atkfilter(c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_DARK)
end
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then return Duel.IsExistingTarget(s.atkfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELF)
	Duel.SelectTarget(tp,s.atkfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_OPPO)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
	e:SetLabelObject(g:GetFirst())
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	local hc=e:GetLabelObject()
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	local tc=g:GetFirst()
	if tc==hc then tc=g:GetNext() end
	if tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(tc:GetAttack()*2)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
		if hc:IsFaceup() and hc:IsRelateToEffect(e) then
			Duel.BreakEffect()
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_SET_ATTACK_FINAL)
			e2:SetValue(hc:GetAttack()/2)
			e2:SetReset(RESET_EVENT|RESETS_STANDARD)
			hc:RegisterEffect(e2)
		end
	end
end
--Local No.2
function s.cpcon(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsTurnPlayer(1-tp) then return false end
	return Duel.IsMainPhase()
end
function s.effilter(e,te)
	--return te:IsMonsterEffect() and te:GetHandler():IsLevelAbove(5) and te:GetOwner()~=e:GetOwner()-- and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
	return te:GetOwner()~=e:GetOwner() and te:IsMonsterEffect() and te:GetHandler():IsLevelAbove(5)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetFlagEffect(id)==0 end
	e:GetHandler():RegisterFlagEffect(id,RESETS_STANDARD_PHASE_END,0,1)
	--Cannot attack
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,4))
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_OATH+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetValue(s.effilter)
	e1:SetReset(RESETS_STANDARD_PHASE_END)
	e:GetHandler():RegisterEffect(e1,true)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--Your opponent's cards and effects cannot be activated
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetTargetRange(0,1)
	e2:SetValue(1)
	e2:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e2,tp)
end
--Local No.3
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
	    --Negate effect
		tc:NegateEffects(c,RESETS_STANDARD_PHASE_END)
		-- Half ATK
		local atk=tc:GetAttack()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetReset(RESETS_STANDARD_PHASE_END)
		e1:SetValue(math.ceil(atk/2))
		tc:RegisterEffect(e1)
		if c:IsRelateToEffect(e) and c:IsFaceup() then
		    -- Double ATK
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_SET_ATTACK)
			e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e2:SetReset(RESETS_STANDARD_PHASE_END)
			e2:SetValue(c:GetAttack()*2)
			c:RegisterEffect(e2)
		    --Copy name
		    local code=tc:GetOriginalCodeRule()
		    local e3=Effect.CreateEffect(c)
		    e3:SetType(EFFECT_TYPE_SINGLE)
		    e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		    e3:SetCode(EFFECT_CHANGE_CODE)
		    e3:SetValue(code)
		    e3:SetReset(RESETS_STANDARD_PHASE_END)
		    c:RegisterEffect(e3)
		    if not tc:IsType(TYPE_TRAPMONSTER) then
		    --Copy effects
			    c:CopyEffect(code,RESETS_STANDARD_PHASE_END,1)
			end
		end
	end
end
--Local No.6
function s.pencon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and e:GetHandler():IsPreviousControler(tp)
end
function s.penconn(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsFaceup()
end
function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp) end
	local g2=Duel.GetMatchingGroup(Card.IsAbleToDestroy,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g2,#g2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
end
function s.penop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.CheckPendulumZones(tp) then return false end
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	    local g=Duel.GetMatchingGroup(Card.IsAbleToDestroy,tp,0,LOCATION_ONFIELD,nil)
	    if c:IsRelateToEffect(e) and c:IsAbleToDestroy() then g:AddCard(c) end
	    if #g>0 and Duel.Destroy(g,POS_FACEUP,REASON_EFFECT)>0 then
		    local ct=Duel.GetOperatedGroup():GetCount()
		    Duel.Damage(1-tp,ct*1000,REASON_EFFECT)
	    end
    end
end