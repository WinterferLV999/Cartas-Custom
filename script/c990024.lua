
local s,id=GetID()
function s.initial_effect(c)
	--synchro summon
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_MACHINE),1,1,Synchro.NonTunerEx(Card.IsSetCard,0x9a),1,99)
	c:EnableReviveLimit()
	--defense attack
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DEFENSE_ATTACK)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BATTLE_CONFIRM)
	e2:SetCondition(s.con)
	e2:SetOperation(s.op)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	c:RegisterEffect(e2)
	--actlimit
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,1)
	e3:SetValue(1)
	e3:SetCondition(s.actcon)
	c:RegisterEffect(e3)
end
--local no.2
function s.con(e,tp,eg,ep,ev,re,r,rp)
	local at=Duel.GetAttackTarget()
	return Duel.GetAttacker():IsControler(tp) and at and at:IsControler(1-tp) and at:IsDefensePos()
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetAttacker()
	if tc and tc:IsRelateToBattle() then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_PIERCE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE)
		tc:RegisterEffect(e1)
	end
end
--local no.3
function s.actfilter(c,tp)
	return c and c:IsFaceup() and c:IsSetCard(0x9a) and c:IsMonster() and c:IsControler(tp)
end
function s.actcon(e)
	local tp=e:GetHandlerPlayer()
	return s.actfilter(Duel.GetAttacker(),tp) or s.actfilter(Duel.GetAttackTarget(),tp)
end
