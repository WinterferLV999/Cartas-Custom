
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Activate
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetTarget(s.sytarget)
	e2:SetOperation(s.syactivate)
	c:RegisterEffect(e2)
	--Activate
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,3))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_ACTIVATE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetTarget(s.lktarget)
	e3:SetOperation(s.lkactivate)
	c:RegisterEffect(e3)
end
function s.filter(c)
	return c:IsFaceup() and c:IsType(TYPE_FUSION) and c:IsAbleToExtra()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA)
end
function s.mgfilter(c,e,tp,fusc,mg)
	return c:IsControler(tp) and c:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA)
		and (c:GetReason()&0x40008)==0x40008 and c:GetReasonCard()==fusc
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and fusc:CheckFusionMaterial(mg,c,PLAYER_NONE|FUSPROC_NOTFUSION)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	local mg=tc:GetMaterial()
	local ct=#mg
	local p=tc:GetControler()
	if Duel.SendtoDeck(tc,nil,0,REASON_EFFECT)~=0 then
		Duel.BreakEffect()
		--Duel.SkipPhase(Duel.GetTurnPlayer(),PHASE_END,RESET_PHASE+PHASE_END,1)
		if tc:IsSummonType(SUMMON_TYPE_FUSION) and ct>0 and ct<=Duel.GetLocationCount(p,LOCATION_MZONE)
			and mg:FilterCount(aux.NecroValleyFilter(s.mgfilter),nil,e,p,tc,mg)==ct
			and (ct<=1 or not Duel.IsPlayerAffectedByEffect(p,CARD_BLUEEYES_SPIRIT)) then
			Duel.SpecialSummon(mg,0,tp,p,false,false,POS_FACEUP)
		    local mgc=mg:GetFirst()
		    while mgc do
			    mgc:AddCounter(0x1041,1)
			    mgc=mg:GetNext()
			end
		end
	end
end
function s.cttg(e,c)
	return c:GetCounter(0x1041)>0
end
--Local No.2
function s.syfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsAbleToExtra()
end
function s.sytarget(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.syfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.syfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.syfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA)
end
function s.symgfilter(c,e,tp,sync)
	return c:IsControler(tp) and c:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA)
		and (c:GetReason()&(REASON_SYNCHRO|REASON_MATERIAL))==(REASON_SYNCHRO|REASON_MATERIAL) and c:GetReasonCard()==sync
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.syactivate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	local mg=tc:GetMaterial()
	local ct=#mg
	local p=tc:GetControler()
	if Duel.SendtoDeck(tc,nil,0,REASON_EFFECT)~=0 then
		Duel.BreakEffect()
		--Duel.SkipPhase(Duel.GetTurnPlayer(),PHASE_END,RESET_PHASE+PHASE_END,1)
		if tc:IsSummonType(SUMMON_TYPE_SYNCHRO) and ct>0 and ct<=Duel.GetLocationCount(p,LOCATION_MZONE)
		    and Duel.SelectYesNo(tp,aux.Stringid(id,2))
			and mg:FilterCount(aux.NecroValleyFilter(s.symgfilter),nil,e,p,tc,mg)==ct
			and (ct<=1 or not Duel.IsPlayerAffectedByEffect(p,CARD_BLUEEYES_SPIRIT)) then
			Duel.SpecialSummon(mg,0,tp,p,false,false,POS_FACEUP)
		    local mgc=mg:GetFirst()
		    while mgc do
			    mgc:AddCounter(0x1041,1)
			    mgc=mg:GetNext()
			end
		end
	end
end
--Local No.3
function s.lkfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_LINK) and c:IsAbleToExtra()
end
function s.lktarget(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.lkfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.lkfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.lkfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA)
end
function s.lkmgfilter(c,e,tp,sync)
	return c:IsControler(tp) and c:IsLocation(LOCATION_GRAVE)
		and c:GetReason()&0x80008==0x80008 and c:GetReasonCard()==linc
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.lkactivate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	local mg=tc:GetMaterial()
	local ct=#mg
	local p=tc:GetControler()
	if Duel.SendtoDeck(tc,nil,0,REASON_EFFECT)~=0 then
		Duel.BreakEffect()
		--Duel.SkipPhase(Duel.GetTurnPlayer(),PHASE_END,RESET_PHASE+PHASE_END,1)
		if tc:IsSummonType(SUMMON_TYPE_LINK) and ct>0 and ct<=Duel.GetLocationCount(p,LOCATION_MZONE)
		    and Duel.SelectYesNo(tp,aux.Stringid(id,4))
			and mg:FilterCount(aux.NecroValleyFilter(s.lkmgfilter),nil,e,p,tc,mg)==ct
			and (ct<=1 or not Duel.IsPlayerAffectedByEffect(p,CARD_BLUEEYES_SPIRIT)) then
			Duel.SpecialSummon(mg,0,tp,p,false,false,POS_FACEUP)
		    local mgc=mg:GetFirst()
		    while mgc do
			    mgc:AddCounter(0x1041,1)
			    mgc=mg:GetNext()
			end
		end
	end
end