--覇王暴竜スターヴ・ヴェノム・ウィング・ドラゴン
--Starving Venom Wing Dragon
--Scripted By The Razgriz
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Pendulum.AddProcedure(c,false)
	--Fusion Materials: 1 "Starving Venom" monster + 1 "Clear Wing" monster
	--Fusion.AddProcMix(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_STARVING_VENOM),aux.FilterBoolFunctionEx(Card.IsSetCard,SET_CLEAR_WING))
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_STARVING_VENOM),s.matefilter)
	--Place Predator Counters on monsters Summoned to your opponent's field
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetRange(LOCATION_PZONE)
	e1:SetOperation(s.counterplaceop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	c:RegisterEffect(e2)
	local e3=e1:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetOperation(s.ctop2)
	c:RegisterEffect(e3)
	--If your opponent Special Summons a monster(s): You can target 1 of them; this card gains ATK equal to its ATK, and its effects are negated.
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DISABLE)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.atknegeffcon)
	e4:SetTarget(s.atknegefftg)
	e4:SetOperation(s.atknegeffop)
	c:RegisterEffect(e4)
	--When another card or effect is activated on the field: You can destroy 1 card on the field
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_DESTROY)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,0,EFFECT_COUNT_CODE_CHAIN)
	e5:SetCondition(s.condition)
	--e5:SetCondition(function(e,tp,eg,ep,ev,re,r,rp) return re:GetHandler()~=e:GetHandler() and Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)&LOCATION_ONFIELD>0 end)
	e5:SetTarget(s.destg)
	e5:SetOperation(s.desop)
	c:RegisterEffect(e5)
	--Place itself into Pendulum Zone if it is destroyed
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,2))
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetProperty(EFFECT_FLAG_DELAY)
	e6:SetCode(EVENT_DESTROYED)
	e6:SetCondition(function(e) return e:GetHandler():IsPreviousLocation(LOCATION_MZONE) end)
	e6:SetTarget(function(e,tp,eg,ep,ev,re,r,rp,chk) if chk==0 then return Duel.CheckPendulumZones(tp) end local c=e:GetHandler() if c:IsLocation(LOCATION_GRAVE) then Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,tp,0) end end)
	e6:SetOperation(s.penop)
	c:RegisterEffect(e6)
end
s.listed_series={SET_CLEAR_WING}
s.material_setcode={SET_CLEAR_WING}
s.counter_place_list={COUNTER_PREDATOR}
function s.matefilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_CLEAR_WING) and c:IsOnField()
end
--Local No.1,3
function s.counterplaceop(e,tp,eg,ep,ev,re,r,rp)
	if ep~=tp then
		eg:GetFirst():AddCounter(0x1041,1)
	end
end
function s.ctop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	for tc in aux.Next(eg) do
		if tc:IsFaceup() and not tc:IsSummonPlayer(tp) then
			tc:AddCounter(0x1041,1)
		end
	end
end
--Local No.4
function s.atknegefffilter(c,e,tp)
	return c:IsSummonPlayer(1-tp) and c:IsCanBeEffectTarget(e)	and c:IsLocation(LOCATION_MZONE) and c:HasNonZeroAttack()
end
function s.atknegeffcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.atknegefffilter,1,nil,e,tp)
end
function s.atknegefftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return eg:IsContains(chkc) and s.atknegefffilter(chkc,e,tp) end
	if chk==0 then return eg:IsExists(s.atknegefffilter,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local tc=nil
	if #eg==1 then
		tc=eg:GetFirst()
		Duel.SetTargetCard(tc)
	else
		tc=eg:FilterSelect(tp,s.atknegefffilter,1,1,nil,e,tp)
		Duel.SetTargetCard(tc)
	end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,tc,1,0,0)
end
function s.atknegeffop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc:IsRelateToEffect(e) and tc:IsFaceup()
		and c:UpdateAttack(tc:GetAttack(),RESETS_STANDARD_DISABLE_PHASE_END) and tc:IsNegatableMonster() then
		tc:NegateEffects(c,RESETS_STANDARD_PHASE_END)
		local code=tc:GetOriginalCodeRule()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetValue(code)
		e1:SetReset(RESETS_STANDARD_PHASE_END)
		c:RegisterEffect(e1)
		if not tc:IsType(TYPE_TRAPMONSTER) then
			c:CopyEffect(code,RESETS_STANDARD_PHASE_END,1)
		end
	end
end
--Local No.5
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	return re:IsMonsterEffect() and rc~=c and rc:IsLevelAbove(5) and loc==LOCATION_MZONE
		and not c:IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,Duel.GetFieldGroup(tp,LOCATION_ONFIELD,LOCATION_ONFIELD),1,tp,LOCATION_ONFIELD)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT)
	end
end
--Local No.6
function s.penop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end