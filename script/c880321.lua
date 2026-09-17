
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Activate
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCost(aux.bfgcost) 
	e2:SetCondition(s.condition)
	e2:SetTarget(s.targett)
	e2:SetOperation(s.activatee)
	c:RegisterEffect(e2)
	aux.GlobalCheck(s,function()
		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_DESTROYED)
		ge2:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
		ge2:SetOperation(s.checkop)
		Duel.RegisterEffect(ge2,0)
	end)
end
--local no.1
function s.filter(c,e,tp)
	return c:IsFaceup() and c:IsCode(15610297)
		and Duel.IsPlayerCanSpecialSummonMonster(tp,c:GetOriginalCode(),0,c:GetType(),c:GetAttack(),c:GetDefense(),c:GetLevel(),c:GetRace(),c:GetAttribute()) 
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<1 or not Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil,e,tp) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil,e,tp):GetFirst()
	local ct=0
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) or ft==1 then ct=1
	else
		local nums = {}
		for i=1,ft do
			table.insert(nums, i)
		end
		ct=Duel.AnnounceNumber(tp,table.unpack(nums))
	end
	local g=Group.CreateGroup()
	for i=1,ct do
		g:AddCard(Duel.CreateToken(tp,tc:GetOriginalCode()))
	end
	Duel.SpecialSummon(g,0,tp,tp,false,false,tc:GetPosition())
end
--local no.2
function s.cfilter(c,p)
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsPreviousPosition(POS_DEFENSE) and c:IsPreviousControler(p)
end
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	for p=0,1 do
		local tg=eg:Filter(s.cfilter,nil,p)
		for tc in aux.Next(tg) do
			Duel.RegisterFlagEffect(1-p,id,RESET_PHASE+PHASE_END,0,1)
		end
	end
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFlagEffect(tp,id)>0 and Duel.GetTurnPlayer()==tp and (Duel.IsAbleToEnterBP()
		or (Duel.GetCurrentPhase()>=PHASE_BATTLE_START and Duel.GetCurrentPhase()<=PHASE_BATTLE))
end
function s.ffilter(c)
	return c:IsFaceup() and (c:GetEffectCount(EFFECT_EXTRA_ATTACK)==0
		or c:GetEffectCount(EFFECT_EXTRA_ATTACK)<Duel.GetFlagEffect(tp,id))
end
function s.targett(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.ffilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.ffilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.ffilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.activatee(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EXTRA_ATTACK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		e1:SetValue(Duel.GetFlagEffect(tp,id))
		tc:RegisterEffect(e1)
	end
end