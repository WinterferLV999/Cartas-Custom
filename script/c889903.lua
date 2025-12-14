
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--act in set turn
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetCondition(s.actcon)
	c:RegisterEffect(e2)
	--Draw 6 cards
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetCountLimit(1)
	e3:SetHintTiming(0,TIMING_END_PHASE)
	e3:SetCondition(s.drcon)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetRange(LOCATION_SZONE)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCode(EVENT_PHASE|PHASE_STANDBY)
	e4:SetCountLimit(1)
	e4:SetCondition(s.tkcon)
	e4:SetTarget(s.target)
	e4:SetOperation(s.operation)
	c:RegisterEffect(e4)
	--Your LP becomes equal to the total ATK of all monsters you control
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e5:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	--e5:SetType(EFFECT_TYPE_QUICK_O)
	--e5:SetCode(EVENT_FREE_CHAIN)
	--e5:SetCode(EVENT_CHAINING)
	e5:SetCode(EVENT_ADJUST)
	e5:SetHintTiming(TIMING_DAMAGE_STEP)
	--e5:SetCountLimit(1,0,EFFECT_COUNT_CODE_CHAIN)
	e5:SetRange(LOCATION_SZONE)
	e5:SetCondition(s.racon)
	e5:SetOperation(s.rapop)
	c:RegisterEffect(e5)
end
s.listed_names={CARD_RA}
s.listed_names={CARD_OBELISK}
s.listed_names={CARD_SLIFER}
--Local No.2
function s.filter(c,e,tp)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_DIVINE)
end
function s.actcon(e)
	return Duel.IsExistingMatchingCard(s.filter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
--Local No.3
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsOriginalCodeRule,CARD_SLIFER),e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,6) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(6)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,6)
end
function s.dropp(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_ATTACK)
		e1:SetTargetRange(LOCATION_MZONE,0)
		e1:SetTarget(s.attg)
		e1:SetReset(RESET_PHASE|PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end
function s.attg(e,c)
	return not c:IsCode(CARD_SLIFER)
end
--Local No.4
function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsOriginalCodeRule,CARD_OBELISK),e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.sfilter(c,e,tp)
	return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.sfilter(chkc,e,tp) end
	if chk==0 then return not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		and Duel.IsExistingTarget(s.sfilter,tp,LOCATION_GRAVE,0,2,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.sfilter,tp,LOCATION_GRAVE,0,2,2,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,2,0,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	local ct=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if #g<=ct then
		if #g>1 and Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end
		local tc=g:GetFirst()
		for tc in aux.Next(g) do
			Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT|RESETS_STANDARD)
			tc:RegisterEffect(e1,true)
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESET_EVENT|RESETS_STANDARD)
			tc:RegisterEffect(e2,true)
	        --Must attack this card, if able
		    local e3=Effect.CreateEffect(e:GetHandler())
		    e3:SetType(EFFECT_TYPE_FIELD)
		    e3:SetCode(EFFECT_MUST_ATTACK)
		    e3:SetRange(LOCATION_MZONE)
		    e3:SetTargetRange(0,LOCATION_MZONE)
	        e3:SetCondition(function(e) return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,CARD_OBELISK),e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil) end)
		    --e3:SetCondition(s.effcon)
		    e3:SetOwnerPlayer(tp)
		    e3:SetReset(RESETS_STANDARD_PHASE_END)
		    tc:RegisterEffect(e3)
		    local e4=e3:Clone()
		    e4:SetCode(EFFECT_MUST_ATTACK_MONSTER)
	        e4:SetValue(aux.TargetBoolFunction(Card.IsCode,CARD_OBELISK))
		    --e4:SetValue(s.atklimit)
		    tc:RegisterEffect(e4)
		end
		Duel.SpecialSummonComplete()
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_ACTIVATE)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT+EFFECT_FLAG_OATH)
		e1:SetDescription(aux.Stringid(id,5))
		e1:SetTargetRange(1,0)
	    e1:SetValue(s.actlimit)
		e1:SetReset(RESET_PHASE|PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end
function s.actlimit(e,re,rp)
	local rc=re:GetHandler()
	return re:IsMonsterEffect() and not rc:IsCode(CARD_OBELISK)
end
function s.atktg(e,c)
	return c:IsAttackPos()
end
function s.musttg(e,c)
	return c:GetFlagEffectLabel(id) and c:GetFlagEffectLabel(id)==e:GetHandler():GetFieldID()
end
function s.effcon(e)
	return e:GetHandler():IsControler(e:GetOwnerPlayer())
end
function s.atklimit(e,c)
	return c==e:GetHandler()
end
--Local No.5
function s.racon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsOriginalCodeRule,CARD_RA),e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.rafilter(c,tid)
	return c:IsHasEffect(90162951) and c:GetFieldID()>tid
end
function s.rapop(e,tp,eg,ep,ev,re,r,rp)
	Duel.AdjustInstantly()
	local c=e:GetHandler()
	local sg=Duel.GetMatchingGroup(s.rafilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil,c:GetFieldID())
	Duel.SendtoGrave(sg,REASON_RULE)
	if Duel.IsExistingMatchingCard(Card.IsHasEffect,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,90162951) then Duel.SendtoGrave(c,REASON_RULE) end
	if not c:IsDisabled() then
		local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
		local sum=g:GetSum(Card.GetAttack)
		Duel.SetLP(tp,sum,REASON_EFFECT)
	end
end