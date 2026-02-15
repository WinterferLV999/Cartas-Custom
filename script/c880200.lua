--覇王眷竜スターヴ・ヴェノム
--Supreme King Dragon Starving Venom
local s,id=GetID()
function s.initial_effect(c)
	--fusion summon
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_STARVING_VENOM),aux.FilterBoolFunctionEx(Card.IsSetCard,SET_SUPREME_KING_DRAGON))
	--special summon
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e0:SetCode(EVENT_SPSUMMON_SUCCESS)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.spcon)
	e0:SetOperation(s.spop)
	c:RegisterEffect(e0)
	--cannot be target
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.atlimit)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)
	--atk limit
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e2:SetValue(s.atlimit)
	c:RegisterEffect(e2)
	--Copy the name and effect of another monster
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	--e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.copytg)
	e3:SetOperation(s.copyop)
	c:RegisterEffect(e3)
	--Make the ATK of an opponent's monster become equal to its original ATK
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(0,LOCATION_MZONE)
	e4:SetCode(EFFECT_SET_ATTACK_FINAL)
	e4:SetCondition(s.basecon)
	e4:SetTarget(s.basetg)
	e4:SetValue(s.baseval)
	c:RegisterEffect(e4)
	--spsummon
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetHintTiming(0,TIMING_END_PHASE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCost(s.spcost)
	e5:SetTarget(s.sptg)
	e5:SetOperation(s.spop2)
	c:RegisterEffect(e5)
	--atk up
	--local e4=Effect.CreateEffect(c)
	--e4:SetDescription(aux.Stringid(id,2))
	--e4:SetCategory(CATEGORY_ATKCHANGE)
	--e4:SetType(EFFECT_TYPE_TRIGGER_F+EFFECT_TYPE_SINGLE)
	--e4:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	--e4:SetRange(LOCATION_MZONE)
	--e4:SetCondition(s.atkcon)
	--e4:SetOperation(s.atkop)
	--c:RegisterEffect(e4)
end
s.listed_series={SET_SUPREME_KING_DRAGON}
s.listed_names={13331639}
--Local No.0
function s.spfilter(c,tp)
	return c:IsControler(1-tp) and c:IsPreviousLocation(LOCATION_EXTRA)
end
function s.costfilter(c,tp,sg,tc)
	if not (c:IsSetCard({SET_SUPREME_KING_DRAGON,SET_STARVING_VENOM})) and c:IsType(TYPE_FUSION) then return false end
	sg:AddCard(c)
	local res
	if #sg<2 then
		res=Duel.CheckReleaseGroup(tp,s.costfilter,1,sg,tp,sg,tc)
	else
		res=Duel.GetLocationCountFromEx(tp,tp,sg,tc)>0
	end
	sg:RemoveCard(c)
	return res
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:CheckFusionMaterial() and eg:IsExists(s.spfilter,1,nil,tp)
		and Duel.GetLP(tp)~=Duel.GetLP(1-tp)
		and Duel.CheckReleaseGroup(tp,s.costfilter,1,nil,tp,Group.CreateGroup(),c) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SPECIAL,tp,false,true)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local sg=Group.CreateGroup()
	if Duel.CheckReleaseGroup(tp,s.costfilter,1,nil,tp,sg,c) and e:GetHandler():IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,true)
		and c:CheckFusionMaterial() and Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,0)) then
		while #sg<2 do
			local g=Duel.SelectReleaseGroup(tp,s.costfilter,1,1,sg,tp,sg,c)
			sg:Merge(g)
		end
		Duel.Destroy(sg,REASON_COST)
		Duel.SpecialSummon(c,SUMMON_TYPE_FUSION,tp,tp,false,true,POS_FACEUP)
		c:CompleteProcedure()
	end
end
--Local No.1
function s.atlimit(e,c)
	return c~=e:GetHandler()
end
--Local No.1
function s.copyfilter(c)
	return c:IsMonster() and not c:IsType(TYPE_TOKEN) and (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE|LOCATION_REMOVED))
end
function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_MZONE|LOCATION_GRAVE) and s.copyfilter(chkc) and chkc~=c end
	if chk==0 then return Duel.IsExistingTarget(s.copyfilter,tp,LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED,LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED,1,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.copyfilter,tp,LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED,LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED,1,1,c)
end
function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		tc:NegateEffects(c,RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1)
		local code=tc:GetOriginalCode()
		--This card's name becomes the target's name
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetValue(code)
		e1:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1)
		c:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE)
		e2:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1)
		tc:RegisterEffect(e2)
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_DISABLE_EFFECT)
		e3:SetValue(RESET_TURN_SET)
		e3:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1)
		tc:RegisterEffect(e3)
		if not tc:IsType(TYPE_TRAPMONSTER) then
			c:CopyEffect(code,RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1)
		end
	end
end
--Local No.3
--Increase ATK
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetLP(tp)~=Duel.GetLP(1-tp)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local atk=math.abs(Duel.GetLP(tp)-Duel.GetLP(1-tp))
		--Increase ATK
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD_DISABLE)
		e1:SetValue(atk)
		c:RegisterEffect(e1)
	end
end
function s.adcon(e)
	return Duel.GetCurrentPhase()==PHASE_DAMAGE_CAL
end
function s.basecon(e)
	local ph=Duel.GetCurrentPhase()
	return (ph==PHASE_DAMAGE or ph==PHASE_DAMAGE_CAL) and Duel.GetAttackTarget()~=nil
		and (Duel.GetAttacker()==e:GetHandler() or Duel.GetAttackTarget()==e:GetHandler())
end
function s.basetg(e,c)
	return c==e:GetHandler():GetBattleTarget()
end
function s.baseval(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler():GetBattleTarget()
	return c:GetBaseAttack()
end
--Local No.4
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToExtraAsCost() end
	Duel.SendtoDeck(e:GetHandler(),nil,0,REASON_COST)
end
function s.spfilter2(c,e,tp)
	return c:IsFaceup() and c:IsSetCard(SET_STARVING_VENOM) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spfilter22(c,e,tp)
	if c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,nil,c)==0 then return false end
	return c:IsSetCard(SET_STARVING_VENOM) or c:IsCode(13331639) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local loc=LOCATION_EXTRA
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then loc=loc|LOCATION_GRAVE|LOCATION_REMOVED end
	if chk==0 then return loc~=0 and Duel.IsExistingMatchingCard(s.spfilter22,tp,loc,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,loc)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local loc=LOCATION_EXTRA
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then loc=loc|LOCATION_GRAVE|LOCATION_REMOVED end
	if loc==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter22,tp,loc,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)
	end
end