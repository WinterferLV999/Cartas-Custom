
local s,id=GetID()
function s.initial_effect(c)
	--special summon
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	--e1:SetCountLimit(1,id)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetTarget(s.tgtg)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)
	--Place this card and 1 "Centurion" monster in the Spell Zone as Continuous Traps
	local e2=e1:Clone()
	e2:SetDescription(aux.Stringid(id,1))
	--e3:SetCountLimit(1,id)
	e2:SetTarget(s.pltg)
	e2:SetOperation(s.plop)
	c:RegisterEffect(e2)
	--Place this card and 1 "Centurion" monster in the Trap Zone as Continuous Traps
	local e3=e2:Clone()
	e3:SetDescription(aux.Stringid(id,2))
	--e3:SetCountLimit(1,id)
	e3:SetTarget(s.pltg)
	e3:SetOperation(s.plopp)
	c:RegisterEffect(e3)
	--Shuffle
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_COUNTER)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e4:SetCountLimit(1,id)
	e4:SetTarget(s.target)
	e4:SetOperation(s.operation)
	c:RegisterEffect(e4)
end
s.listed_names={69890967}
--local no.1
function s.filter(c,e,tp)
	return c:IsCode(id) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK+LOCATION_HAND,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_HAND)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if ft>2 then ft=2 end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK+LOCATION_HAND,0,1,ft,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
	local e0=Effect.CreateEffect(e:GetHandler())
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e0:SetDescription(aux.Stringid(id,3))
	e0:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	if Duel.GetTurnPlayer()==tp then
		e0:SetReset(RESET_PHASE+PHASE_END)
	else
		e0:SetReset(RESET_PHASE+PHASE_END)
	end
	e0:SetTargetRange(1,0)
	e0:SetTarget(s.splimit)
	Duel.RegisterEffect(e0,tp)
end
	--Cannot special summon from extra deck
function s.splimit(e,c,sump,sumtype,sumpos,targetp)
	return c:IsLocation(LOCATION_EXTRA)
end
--local no.3,4
function s.plfilter(c)
	return c:IsCode(id) and c:IsMonster() and not c:IsForbidden()
end
function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if Duel.GetLocationCount(tp,LOCATION_SZONE)<2 then return false end
		local g=Duel.GetMatchingGroup(s.plfilter,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_MZONE,0,nil)
		return aux.SelectUnselectGroup(g,e,tp,3,3,s.rescon,0)
	end
	Duel.SetPossibleOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,LOCATION_GRAVE)
end
function s.plop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<2 then return end
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.plfilter),tp,LOCATION_HAND|LOCATION_DECK|LOCATION_MZONE,0,nil)
	local tg=aux.SelectUnselectGroup(g,e,tp,3,3,s.rescon,1,tp,HINTMSG_TOFIELD)
	if #tg~=3 then return end
	local c=e:GetHandler()
	for tc in tg:Iter() do
		if Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true) then
			--Treat as Continuous Spell
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetCode(EFFECT_CHANGE_TYPE)
			e1:SetValue(TYPE_SPELL|TYPE_CONTINUOUS)
			e1:SetReset((RESET_EVENT|RESETS_STANDARD)&~RESET_TURN_SET)
			tc:RegisterEffect(e1)
		end
	end
end
function s.plopp(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<2 then return end
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.plfilter),tp,LOCATION_HAND|LOCATION_DECK|LOCATION_MZONE,0,nil)
	local tg=aux.SelectUnselectGroup(g,e,tp,3,3,s.rescon,1,tp,HINTMSG_TOFIELD)
	if #tg~=3 then return end
	local c=e:GetHandler()
	for tc in tg:Iter() do
		if Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true) then
			--Treat as Continuous Trap
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetCode(EFFECT_CHANGE_TYPE)
			e1:SetValue(TYPE_TRAP|TYPE_CONTINUOUS)
			e1:SetReset((RESET_EVENT|RESETS_STANDARD)&~RESET_TURN_SET)
			tc:RegisterEffect(e1)
		end
	end
end
--local no.4
function s.shfilter(c)
	return c:IsCode(id) and c:IsAbleToDeck()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return true end
	local g=Duel.GetMatchingGroup(s.shfilter,tp,LOCATION_GRAVE,0,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,#g,0,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.shfilter,tp,LOCATION_GRAVE,0,nil)
	if #g>0 then
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end