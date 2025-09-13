
--scripted by Winterfer
local s,id=GetID()
function s.initial_effect(c)
	c:SetUniqueOnField(1,0,id)
	c:EnableReviveLimit()
	--Special Summon condition
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.FALSE)
	c:RegisterEffect(e0)
	--Special Summon itself from the GY if you control "King's Sarcophagus"
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_GRAVE)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
	--Change a effect to "Destroy 1 Set Spell/Trap your control"
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.chcon1)
	e2:SetOperation(s.chop1)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET,EFFECT_FLAG2_CHECK_SIMULTANEOUS)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.thtdcon)
	--e3:SetTarget(s.thtdtg)
	e3:SetOperation(s.thtdop)
	c:RegisterEffect(e3)
end
s.listed_names={CARD_KING_SARCOPHAGUS}
--Local No.1
function s.spcon(e,c)
	if c==nil then return true end
	local eff={c:GetCardEffect(EFFECT_NECRO_VALLEY)}
	for _,te in ipairs(eff) do
		local op=te:GetOperation()
		if not op or op(e,c) then return false end
	end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,CARD_KING_SARCOPHAGUS),tp,LOCATION_ONFIELD,0,1,nil)
end
--Local No.2
function s.chcon1(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp and (re:IsHasType(EFFECT_TYPE_ACTIVATE) or re:IsActiveType(TYPE_MONSTER))
		and Duel.IsExistingMatchingCard(s.confilter,tp,LOCATION_SZONE,0,1,nil)
		and e:GetHandler():GetFlagEffect(id)==0
end
function s.chop1(e,tp,eg,ep,ev,re,r,rp)
	if Duel.SelectEffectYesNo(tp,e:GetHandler()) then
	Duel.Hint(HINT_CARD,0,id)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Group.CreateGroup()
		e:GetHandler():RegisterFlagEffect(id,RESETS_STANDARD_PHASE_END,0,1)
		local sg=g:Select(1-tp,1,1,nil)
	    Duel.ChangeChainOperation(ev,s.repop)
	end
end
function s.confilter(c)
	return c:IsFaceup() and c:IsCode(16528181)
end
function s.desfilter(c)
	return c:IsSpellTrap()
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		Duel.HintSelection(g,true)
		Duel.Destroy(g,REASON_EFFECT)
		Duel.Damage(1-tp,1000,REASON_EFFECT)
	end
end
--Local No.3
function s.cfilter(c,tp)
	return c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsPreviousControler(tp)
		and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp
end
function s.thtdcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.thtdop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(54719828,1))
	local op=Duel.SelectOption(tp,70,71,72)
	local c=e:GetHandler()
	--disable
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetTargetRange(0,0xff)
	e1:SetTarget(s.distarget)
	e1:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1)
	e1:SetLabel(op)
	Duel.RegisterEffect(e1,tp)
	--disable effect
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetOperation(s.disoperation)
	e2:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1)
	e2:SetLabel(op)
	Duel.RegisterEffect(e2,tp)
	--disable trap monster
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
	e3:SetTargetRange(0,0xff)
	e3:SetTarget(s.distarget)
	e3:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1)
	e3:SetLabel(op)
	Duel.RegisterEffect(e3,tp)
end
function s.distarget(e,c)
	local type=0
	if e:GetLabel()==0 then
		type=TYPE_MONSTER
	elseif e:GetLabel()==1 then
		type=TYPE_SPELL
	else
		type=TYPE_TRAP
	end
	return c:IsType(type)
end
function s.disoperation(e,tp,eg,ep,ev,re,r,rp)
	local type=0
	if e:GetLabel()==0 then
		type=TYPE_MONSTER
	elseif e:GetLabel()==1 then
		type=TYPE_SPELL
	else
		type=TYPE_TRAP
	end
	if re:IsActiveType(type) and re:GetHandler():IsControler(1-tp) then
		Duel.NegateEffect(ev)
	end
end