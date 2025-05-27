--No.107 銀河眼の時空竜 (Anime)
--Number 107: Galaxy-Eyes Tachyon Dragon (Anime)
--fixed and cleaned up by MLD
--fixed by Larry126
Duel.LoadCardScript("c88177324.lua")
local s,id=GetID()
function s.initial_effect(c)
	--xyz summon
	Xyz.AddProcedure(c,nil,9,3)
	c:EnableReviveLimit()
	--battle indestructable
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(aux.NOT(aux.TargetBoolFunction(Card.IsSetCard,0x48)))
	c:RegisterEffect(e1)
	--code
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CHANGE_CODE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e2:SetValue(88177324)
	c:RegisterEffect(e2)
	--el efecto arrecho
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(81927732,0))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCost(s.cost)
	e3:SetOperation(s.operation)
	c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)
	--damage
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_DAMAGE)
	e4:SetCode(EVENT_BATTLE_DESTROYING)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetCondition(s.condition)
	e4:SetTarget(s.target)
	e4:SetOperation(s.op)
	c:RegisterEffect(e4)
	--cannot target
	--local e5=Effect.CreateEffect(c)
	--e5:SetType(EFFECT_TYPE_SINGLE)
	--e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	--e5:SetRange(LOCATION_MZONE)
	--e5:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	--e5:SetCondition(s.indcon)
	--e5:SetValue(aux.tgoval)
	--c:RegisterEffect(e5)
	--indes
	--local e6=Effect.CreateEffect(c)
	--e6:SetType(EFFECT_TYPE_SINGLE)
	--e6:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	--e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	--e6:SetRange(LOCATION_MZONE)
	--e6:SetCondition(s.indcon)
	--e6:SetValue(s.indval)
	--c:RegisterEffect(e6)
end
s.xyz_number=107
s.listed_series={SET_GALAXY_EYES,SET_GALAXY_EYES_TACHYON_DRAGON,SET_NUMBER_C}
--Local no.3
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.filter3(c)
	return c:IsFaceup() and c:IsType(TYPE_EFFECT)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tg=Duel.GetMatchingGroup(s.filter3,tp,LOCATION_MZONE,LOCATION_MZONE,c)
	if #tg>0 then
	--if #tg>0 and Duel.SelectEffectYesNo(tp,c) then
		--Duel.Hint(HINT_CARD,0,id)
		local atk=#tg*1000
		for tc in aux.Next(tg) do
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_SET_ATTACK_FINAL)
			e1:SetValue(0)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		    local e2=Effect.CreateEffect(c)
		    e2:SetType(EFFECT_TYPE_SINGLE)
		    e2:SetCode(EFFECT_DISABLE)
		    e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		    tc:RegisterEffect(e2)
		    local e3=Effect.CreateEffect(c)
		    e3:SetType(EFFECT_TYPE_SINGLE)
		    e3:SetCode(EFFECT_DISABLE_EFFECT)
		    e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		    tc:RegisterEffect(e3)
		end
		local e1=Effect.CreateEffect(c)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(atk)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD)
		c:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_ATTACK_ALL)
		e2:SetValue(1)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e2)
	end
	Duel.Readjust()
end
--Local no.4
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	e:SetLabel(bc:GetAttack())
	return c:IsRelateToBattle() and bc:IsMonster()
		and e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,88177324)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(e:GetLabel())
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,e:GetLabel())
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Damage(p,d,REASON_EFFECT)
end
--Local no.5,6
function s.indcon(e)
	return e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,88177324)
end
function s.indval(e,re,tp)
	return tp~=e:GetHandlerPlayer()
end
