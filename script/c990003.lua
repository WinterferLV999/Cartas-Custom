
local s,id=GetID()
function s.initial_effect(c)
	--fusion material
	c:EnableReviveLimit()
	Fusion.AddProcCodeFun(c,CARD_REDEYES_B_DRAGON,aux.FilterBoolFunction(Card.IsCode,30079770),1,true)
	c:EnableCounterPermit(0x27)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_BATTLE_DESTROYING)
	e1:SetCondition(aux.bdogcon)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)
	--Destroy
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetRange(LOCATION_MZONE)
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetCountLimit(1)
	e2:SetCondition(s.condition0)
	e2:SetTarget(s.target0)
	e2:SetOperation(s.operation0)
	c:RegisterEffect(e2)
	--Special Summon "Vijam" and change attack target
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.condition1)
	e3:SetTarget(s.target1)
	e3:SetOperation(s.activate1)
	c:RegisterEffect(e3)
	--special summon red b. dragon
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.descon)
	e4:SetCost(s.descost)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)
	--attackup
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCode(EFFECT_UPDATE_ATTACK)
	e5:SetValue(s.attackup)
	c:RegisterEffect(e5)
end
s.listed_series={0x3b}
s.listed_names={CARD_NECROVALLEY}
s.material_setcode=0x3b
--local no.1
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		c:AddCounter(0x27,1)
	end
end
--LOCAL NO.2
function s.condition0(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and bc:IsControler(1-tp)
end
function s.target0(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if chkc then return chkc==bc end
	if chk==0 then
		if c:IsHasEffect(id+1) then return true
		else return bc and bc:IsOnField() and bc:IsCanBeEffectTarget(e) end
	end
	if c:IsHasEffect(id+1) then
		e:SetProperty(0)
		local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_MZONE,nil)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	else
		e:SetProperty(EFFECT_FLAG_CARD_TARGET)
		Duel.SetTargetCard(bc)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,bc,1,0,0)
	end
end
function s.operation0(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end
--local no.3
function s.condition1(e,tp,eg,ep,ev,re,r,rp)
	local d=Duel.GetAttackTarget()
	return d and d:IsPosition(POS_FACEUP_ATTACK) and d:IsSetCard(0x3b) and d:IsControler(tp)
end
function s.spfilter(c,e,tp)
	return c:IsCode(990003) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.activate1(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
	local at=Duel.GetAttacker()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 and at and at:CanAttack() and not at:IsImmuneToEffect(e) then
		Duel.CalculateDamage(at,tc)
	end
end
--local no.4
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetAttack()~=c:GetBaseAttack()
end
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:GetCounter(0x27)>=3 and c:IsReleasable() end
	Duel.Destroy(c,REASON_COST)
end
function s.filter(c,e,tp)
	return c:IsCode(CARD_REDEYES_B_DRAGON) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if e:GetHandler():GetSequence()<5 then ft=ft+1 end
	if chk==0 then return ft>0 and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

function s.attackup(e,c)
	return c:GetCounter(0x27)*1000
end
