
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--reduce battle damage
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCondition(s.damcon)
	e1:SetOperation(s.damop)
	c:RegisterEffect(e1)
	--fusattribute
	--local e2=Effect.CreateEffect(c)
	--e2:SetType(EFFECT_TYPE_FIELD)
	--e2:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	--e2:SetRange(LOCATION_SZONE)
	--e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	--e2:SetTarget(s.attrtg)
	--e2:SetValue(s.attrval)
	--e2:SetOperation(s.attrcon)
	--c:RegisterEffect(e2)
	--local e3=Effect.CreateEffect(c)
	--e3:SetType(EFFECT_TYPE_FIELD)
	--e3:SetCode(EFFECT_ADD_SETCODE)
	--e3:SetRange(LOCATION_SZONE)
	--e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	--e3:SetTarget(s.attrtg)
	--e3:SetValue(0x10f3)
	--e3:SetOperation(s.attrcon)
	--c:RegisterEffect(e3)
	--copy effecr no.1
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_TOGRAVE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.target1)
	e4:SetOperation(s.activate)
	c:RegisterEffect(e4)
	--copy effecr no.2
	local e5=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetRange(LOCATION_SZONE)
	e5:SetCondition(s.sspcon)
	e5:SetTarget(s.target)
	e5:SetOperation(s.operation)
	c:RegisterEffect(e5)
	--only attack PP
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_MUST_ATTACK_MONSTER)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetTarget(s.atktg)
	e2:SetValue(0x10f3)
	c:RegisterEffect(e2)
	--Place Counters on this card
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e7:SetCode(EVENT_SPSUMMON_SUCCESS)
	e7:SetRange(LOCATION_FZONE)
	e7:SetOperation(s.ctop)
	c:RegisterEffect(e7)
	--Special summon 1 level 5 or lower fusion monster from extra deck
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,2))
	e8:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e8:SetType(EFFECT_TYPE_IGNITION)
	e8:SetRange(LOCATION_FZONE)
	e8:SetCondition(s.ssspcon)
	e8:SetTarget(s.target2)
	e8:SetOperation(s.activate2)
	c:RegisterEffect(e8)
end
s.counter_place_list={COUNTER_PREDATOR}
s.counter_place_list={0x1041}
s.listed_series={0x10f3}
--local no.8
function s.ssspcon(e)
	return e:GetHandler():GetCounter(0x1009)>=6
end
function s.kkfilter(c,e,tp)
	return c:IsType(TYPE_FUSION) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial()
end
function s.target2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.kkfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.activate2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.kkfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if not tc then return end
	tc:SetMaterial(nil)
	if Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)~=0 then
		e:GetHandler():RemoveCounter(tp,0x1009,6,REASON_EFFECT)
	end
end
--local no.6
function s.atktg(e,c)
	return c:GetCounter(0x1041)>0
end
--local no.7
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(Card.IsSummonType,1,nil,SUMMON_TYPE_FUSION) then
		e:GetHandler():AddCounter(0x1009,1)
	end
end
--local no.1
function s.confilter(c)
	return c:GetCounter(0x1041)>0
end
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetMatchingGroupCount(s.confilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0,nil)>0
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local dam=Duel.GetBattleDamage(tp)
	local ct=Duel.GetMatchingGroupCount(s.confilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,0,nil)
	if ct<1 or dam<=0 then return end
	dam=dam-(ct*500)
	if dam<0 then dam=0 end
	Duel.ChangeBattleDamage(tp,dam)
end
--local no.2-3
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
function s.spcon(e)
	return e:GetHandler():GetCounter(0x1009)>=2
end
function s.filter(c)
	return c:GetType()==TYPE_SPELL or c:GetType()==TYPE_TRAP and c:IsAbleToGrave() and c:CheckActivateEffect(false,true,false)~=nil
end
function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		e:GetHandler():RemoveCounter(tp,0x1009,2,REASON_EFFECT)
		Duel.SendtoGrave(g,REASON_EFFECT)
		local te,eg,ep,ev,re,r,rp=g:GetFirst():CheckActivateEffect(false,true,false)
		e:SetLabelObject(te)
		Duel.ClearTargetCard()
		local tg=te:GetTarget()
		e:SetCategory(te:GetCategory())
		e:SetProperty(te:GetProperty())
		if tg then tg(e,tp,eg,ep,ev,re,r,rp,1) end
		local op=te:GetOperation()
		if op then op(e,tp,eg,ep,ev,re,r,rp) end
	end
end
--local no.5
function s.sspcon(e)
	return e:GetHandler():GetCounter(0x1009)>=4
end
function s.filter1(c,e,tp,eg,ep,ev,re,r,rp)
	local te=c:CheckActivateEffect(false,false,false)
	if c:IsTrap() or c:IsSpell() and c:IsFaceup() and te then
		if c:IsSetCard(0x95) then
			local tg=te:GetTarget()
			return not tg or tg(e,tp,eg,ep,ev,re,r,rp,0)
		else
			return true
		end
	end
	return false
end
function s.filter2(c,e,tp,eg,ep,ev,re,r,rp)
	local te=c:CheckActivateEffect(false,false,false)
	if c:IsSpell() and c:IsFaceup() and not c:IsType(TYPE_EQUIP+TYPE_CONTINUOUS) and te then
		if c:IsSetCard(0x95) then
			local tg=te:GetTarget()
			return not tg or tg(e,tp,eg,ep,ev,re,r,rp,0)
		else
			return true
		end
	end
	return false
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then
		local b=e:GetHandler():IsLocation(LOCATION_HAND)
		local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
		if (b and ft>1) or (not b and ft>0) then
			return Duel.IsExistingTarget(s.filter1,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,e:GetHandler(),e,tp,eg,ep,ev,re,r,rp)
		else
			return Duel.IsExistingTarget(s.filter2,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,e:GetHandler(),e,tp,eg,ep,ev,re,r,rp)
		end
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
		Duel.SelectTarget(tp,s.filter1,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,1,nil,e,tp,eg,ep,ev,re,r,rp)
	else
		Duel.SelectTarget(tp,s.filter2,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,1,nil,e,tp,eg,ep,ev,re,r,rp)
	end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	local tpe=tc:GetType()
	local te=tc:GetActivateEffect()
	local tg=te:GetTarget()
	local co=te:GetCost()
	local op=te:GetOperation()
	e:SetCategory(te:GetCategory())
	e:SetProperty(te:GetProperty())
	Duel.ClearTargetCard()
	if (tpe&TYPE_EQUIP+TYPE_CONTINUOUS)~=0 or tc:IsHasEffect(EFFECT_REMAIN_FIELD) then
		if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	elseif (tpe&TYPE_FIELD)~=0 then
		Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
	end
	tc:CreateEffectRelation(te)
	if co then co(te,tp,eg,ep,ev,re,r,rp,1) end
	if tg then
		e:GetHandler():RemoveCounter(tp,0x1009,4,REASON_EFFECT)
		if tc:IsSetCard(0x95) then
			tg(e,tp,eg,ep,ev,re,r,rp,1)
		else
			tg(te,tp,eg,ep,ev,re,r,rp,1)
		end
	end
	Duel.BreakEffect()
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	local etc=g:GetFirst()
	while etc do
		etc:CreateEffectRelation(te)
		etc=g:GetNext()
	end
	if op then 
		e:GetHandler():RemoveCounter(tp,0x1009,4,REASON_EFFECT)
		if tc:IsSetCard(0x95) then
			op(e,tp,eg,ep,ev,re,r,rp)
		else
			op(te,tp,eg,ep,ev,re,r,rp)
		end
	end
	tc:ReleaseEffectRelation(te)
	etc=g:GetFirst()
	while etc do
		etc:ReleaseEffectRelation(te)
		etc=g:GetNext()
	end
end