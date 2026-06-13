
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon this card as an Effect Monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.selfsptg)
	e1:SetOperation(s.selfspop)
	c:RegisterEffect(e1)
end
s.listed_series={SET_THE_PHANTOM_KNIGHTS,SET_PHANTOM_KNIGHTS}
function s.selfsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,id,0,TYPE_MONSTER|TYPE_EFFECT,0,0,4,RACE_WARRIOR,ATTRIBUTE_DARK) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,0)
end
function s.selfspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and s.selfsptg(e,tp,eg,ep,ev,re,r,rp,0) then
		c:AddMonsterAttribute(TYPE_EFFECT|TYPE_TRAP)
		Duel.SpecialSummonStep(c,0,tp,tp,true,false,POS_FACEUP)
		--Special Summon 1 Trap, except "The Phantom Knights' Echo of Demise", from your GY or banishment as a Normal Monster and its name becomes "The Phantom Knights' Echo of Demise"
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,1))
		e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
		e1:SetType(EFFECT_TYPE_QUICK_O)
		e1:SetCode(EVENT_FREE_CHAIN)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCountLimit(1,id)
		e1:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
		e1:SetCost(Cost.PayLP(800))
		e1:SetTarget(s.sptg)
		e1:SetOperation(s.spop)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e1,true)
		c:AddMonsterAttributeComplete()
	    --Can be treated as Level 2 or 3 for a "THE_PHANTOM_KNIGHTS" Xyz Monster
	    local e2=Effect.CreateEffect(c)
	    e2:SetType(EFFECT_TYPE_SINGLE)
	    e2:SetCode(EFFECT_XYZ_LEVEL)
	    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	    e2:SetRange(LOCATION_MZONE)
	    e2:SetValue(s.xyzlvl)
		e2:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e2)
	end
	Duel.SpecialSummonComplete()
end
function s.spfilter(c,tp)
	return c:IsTrap() and c:IsFaceup() and c:IsSetCard({SET_THE_PHANTOM_KNIGHTS,SET_PHANTOM_KNIGHTS}) and not c:IsCode(id)
		and Duel.IsPlayerCanSpecialSummonMonster(tp,id,nil,TYPE_MONSTER|TYPE_NORMAL,0,0,4,RACE_WARRIOR,ATTRIBUTE_DARK)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE|LOCATION_REMOVED)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil,tp):GetFirst()
	if not sc then return end
	sc:AssumeProperty(ASSUME_CODE,id)
	if Duel.SpecialSummonStep(sc,0,tp,tp,true,false,POS_FACEUP) then
		--Special Summon it as Normal Monster (Warrior/DARK/Level 4/ATK 0/DEF 0) and its name becomes "The Phantom Knights' Echo of Demise" (even while face-down)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetValue(TYPE_NORMAL|TYPE_MONSTER)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD&~RESET_TURN_SET)
		sc:RegisterEffect(e1,true)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_CHANGE_RACE)
		e2:SetValue(RACE_WARRIOR)
		sc:RegisterEffect(e2,true)
		local e3=e1:Clone()
		e3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
		e3:SetValue(ATTRIBUTE_DARK)
		sc:RegisterEffect(e3,true)
		local e4=e1:Clone()
		e4:SetCode(EFFECT_CHANGE_LEVEL)
		e4:SetValue(4)
		sc:RegisterEffect(e4,true)
		local e5=e1:Clone()
		e5:SetCode(EFFECT_SET_BASE_ATTACK)
		e5:SetValue(0)
		sc:RegisterEffect(e5,true)
		local e6=e1:Clone()
		e6:SetCode(EFFECT_SET_BASE_DEFENSE)
		e6:SetValue(0)
		sc:RegisterEffect(e6,true)
		local e7=e1:Clone()
		e7:SetCode(EFFECT_CHANGE_CODE)
		e7:SetValue(id)
		sc:RegisterEffect(e7,true)
		--If it is used for the Xyz Summon of a "THE_PHANTOM_KNIGHTS" Xyz Monster this turn, it can be treated as a Level 2 or 3 monster
		local e8=e1:Clone()
		e8:SetDescription(aux.Stringid(id,2))
		e8:SetCode(EFFECT_XYZ_LEVEL)
		e8:SetValue(s.xyzlvl)
		sc:RegisterEffect(e8,true)
	end
	Duel.SpecialSummonComplete()
end
function s.xyzlvl(e,c,rc)
	local lv=e:GetHandler():GetLevel()
	if rc:IsSetCard(SET_THE_PHANTOM_KNIGHTS) then
		return 3,2,lv
	else
		return lv
	end
end