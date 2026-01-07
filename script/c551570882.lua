
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Pendulum.AddProcedure(c,false)
	--Fusion Materials: 1 "Predaplant" monster + 1 "Starving Venom" monster
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_PREDAPLANT),aux.FilterBoolFunctionEx(Card.IsSetCard,SET_STARVING_VENOM))
	--If this card is Fusion Summoned, the Fusion Materials used for its Fusion Summon gain an effect
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(function(e) return e:GetHandler():IsFusionSummoned() end)
	e1:SetOperation(s.effop)
	c:RegisterEffect(e1)
	--Change the ATK of 1 face-up monster on the field to 0 and negate its effects
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.atkdistg)
	e2:SetOperation(s.atkdisop)
	c:RegisterEffect(e2)
	--Destroy as many monsters on the field as possible, then inflict damage to the controllers equal to the combined original ATK on the field of their destroyed monsters
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end
s.listed_names={51570882} --"Greedy Venom Fusion Dragon"
s.material_setcode={SET_PREDAP,SET_PREDAPLANT}
--Local No.1
function s.effopfilter(c,fusc)
	return c:IsLocation(LOCATION_GRAVE) and fusc:IsReasonCard(c) and c:IsReason(REASON_FUSION) and c:IsReason(REASON_MATERIAL)
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=c:GetMaterial()
	if not mg or #mg==0 then return end
	mg=mg:Filter(aux.NecroValleyFilter(s.effopfilter),nil,c)
	if #mg==0 then return end
	for mc in mg:Iter() do
		--Special Summon 1 "Greedy Venom Fusion Dragon" from your GY
		local e1=Effect.CreateEffect(mc)
		e1:SetDescription(aux.Stringid(id,2))
		e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
		e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
		e1:SetCode(EVENT_DESTROYED)
		e1:SetRange(LOCATION_GRAVE)
		e1:SetCost(Cost.SelfBanish)
		e1:SetTarget(s.sptg)
		e1:SetOperation(s.spop)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		mc:RegisterEffect(e1)
	end
end
function s.spfilter(c,e,tp)
	return c:IsCode(51570882) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end
--Local No.2
function s.atkdisfilter(c)
	return (not c:IsAttack(0) or c:IsNegatableMonster()) and c:IsFaceup()
end
function s.atkdistg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.atkdisfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.atkdisfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.atkdisfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,tp,0)
end
function s.atkdisop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		tc:NegateEffects(c,RESETS_STANDARD_PHASE_END)
		--Copy name
		local code=tc:GetOriginalCodeRule()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetValue(code)
		e1:SetReset(RESETS_STANDARD_PHASE_END)
		c:RegisterEffect(e1)
		if not tc:IsType(TYPE_TRAPMONSTER) then
		--Copy effects
			c:CopyEffect(code,RESETS_STANDARD_PHASE_END,1)
		end
		--Change its ATK to 0 until the end of this turn
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e3:SetCode(EFFECT_SET_ATTACK_FINAL)
		e3:SetValue(0)
		e3:SetReset(RESETS_STANDARD_PHASE_END)
		tc:RegisterEffect(e3)
		--Negate its effects until the end of this turn
		tc:NegateEffects(c,RESET_PHASE|PHASE_END)
	end
end
--Local No.3
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(nil,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,PLAYER_ALL,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(nil,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		local og=Duel.GetOperatedGroup()
		local g1=og:Filter(Card.IsPreviousControler,nil,tp)
		local g2=og:Filter(Card.IsPreviousControler,nil,1-tp)
		local sum1=g1:GetSum(Card.GetPreviousAttackOnField)
		local sum2=g2:GetSum(Card.GetPreviousAttackOnField)
		if sum1==0 and sum2==0 then return end
		Duel.BreakEffect()
		Duel.Damage(tp,sum1,REASON_EFFECT,true)
		Duel.Damage(1-tp,sum2,REASON_EFFECT,true)
		Duel.RDComplete()
	end
end