--Ｎｏ．１０７ 銀河眼の時空竜 (Anime)
--Number 107: Galaxy-Eyes Tachyon Dragon (Anime)
--scripted by MLD, Larry126, and pyrQ
Duel.LoadCardScript("c88177324.lua")
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon procedure: 2 Level 8 monsters
	Xyz.AddProcedure(c,nil,8,2)
	--Cannot be destroyed by battle, except with a "Number" monster
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(aux.NOT(aux.TargetBoolFunction(Card.IsSetCard,SET_NUMBER)))
	c:RegisterEffect(e1)
	--Negate the effects of all other face-up monsters currently on the field, also their ATK and DEF become their original ATK and DEF
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(function(e,tp) return Duel.IsTurnPlayer(1-tp) end)
	--e2:SetCost(Cost.Detach(1)
	e2:SetTarget(s.distg)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2,false,REGISTER_FLAG_DETACH_XMAT)
	--Workaround to make the extra attack part work on your turn
	local e3=e2:Clone()
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetCountLimit(1)
	e3:SetCondition(s.discon)
	e3:SetCost(s.discost)
	c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)
	--Global effects to keep track of total effect resolutions and the last attacker
	aux.GlobalCheck(s,function()
		--Keep track of how many effects have resolved during each Battle Phase
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAIN_SOLVED)
		ge1:SetCondition(function() return Duel.IsBattlePhase() end)
		ge1:SetOperation(function() Duel.RegisterFlagEffect(0,id,RESET_PHASE|PHASE_BATTLE,0,1) end)
		Duel.RegisterEffect(ge1,0)
		--Keep track of which card was the last one that declared an attack
		local ge2=Effect.CreateEffect(c)
		ge2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge2:SetCode(EVENT_ATTACK_ANNOUNCE)
		ge2:SetOperation(s.atkregop)
		Duel.RegisterEffect(ge2,0)
		s.last_attacker=nil
	end)
end
s.xyz_number=107
s.listed_series={SET_NUMBER}
function s.atkregop(e,tp,eg,ep,ev,re,r,rp)
	local ac=eg:GetFirst()
	s.last_attacker=ac
	ac:RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_BATTLE,0,1)
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase() and Duel.IsTurnPlayer(tp) and not Duel.GetAttacker() and Duel.GetCurrentChain()==0
		and not Duel.HasFlagEffect(tp,id+1) and not Duel.IsPhase(PHASE_BATTLE_START)
end
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST) end
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
	if Duel.IsTurnPlayer(tp) then
		Duel.RegisterFlagEffect(tp,id+1,RESET_PHASE|PHASE_BATTLE,0,1)
		c:RegisterFlagEffect(id+1,RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_DAMAGE|PHASE_BATTLE,0,1)
		--Cannot attack with any other card after activating this effect
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
		e1:SetCode(EFFECT_CANNOT_ATTACK)
		e1:SetTargetRange(LOCATION_MZONE,0)
		e1:SetTarget(function(e,c) return c~=s.last_attacker or not c:HasFlagEffect(id+1) end)
		e1:SetReset(RESET_PHASE|PHASE_BATTLE)
		Duel.RegisterEffect(e1,tp)
	end
end
function s.disfilter(c)
	return c:IsNegatableMonster() or not (c:IsAttack(c:GetBaseAttack()) and c:IsDefense(c:GetBaseDefense()))
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return true end
	
	local g=Duel.GetMatchingGroup(s.disfilter,tp,LOCATION_MZONE,LOCATION_MZONE,c)
	if #g>0 then
		Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,PLAYER_ALL,0)
	end
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local exc=c:IsRelateToEffect(e) and c or nil
	local res=false
	
	-- Escanea y recopila los objetivos aptos en mesa
	local g=Duel.GetMatchingGroup(s.disfilter,tp,LOCATION_MZONE,LOCATION_MZONE,exc)
	if #g>0 then
		for tc in g:Iter() do
			tc:NegateEffects(c)
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetCode(EFFECT_SET_ATTACK_FINAL)
			e1:SetValue(tc:GetBaseAttack())
			e1:SetReset(RESET_EVENT|RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_SET_DEFENSE_FINAL)
			e2:SetValue(tc:GetBaseDefense())
			tc:RegisterEffect(e2)
			res=true
		end
	end
	
	if c:IsFacedown() or not c:IsRelateToEffect(e) then return end
	
	-- LECTURA DEL ÁBACO DIGITAL: Calcula cuántos efectos se resolvieron en esta Battle Phase
	local resolved_eff_ct=Duel.GetFlagEffect(0,id)
	if resolved_eff_ct>0 then
		Duel.BreakEffect()
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_UPDATE_ATTACK)
		e3:SetValue(resolved_eff_ct*1000)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD_DISABLE|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e3)
		res=true
	end
	
	-- Frena el proceso si es el turno del oponente
	if Duel.IsTurnPlayer(1-tp) then return end
	
	local atk_ct=c:GetAttackAnnouncedCount()
	-- SANEADO TOTAL: Se extirpó el texto 'Glen' que rompía la sintaxis de Lua.
	if res and atk_ct==1 and c:CanAttack() and s.last_attacker==c and c:HasFlagEffect(id) then
		-- Otorga el segundo golpe reglamentario del anime
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e4:SetCode(EFFECT_EXTRA_ATTACK)
		e4:SetValue(atk_ct)
		e4:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_BATTLE)
		c:RegisterEffect(e4)
		
		-- Registro de sub-relojes para terminar la Battle Phase manualmente tras el segundo golpe
		local e5=Effect.CreateEffect(c)
		e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
		e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e5:SetCode(EVENT_ATTACK_ANNOUNCE)
		e5:SetOperation(s.endbpop)
		e5:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_BATTLE)
		c:RegisterEffect(e5)
		
		local e6=Effect.CreateEffect(c)
		e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e6:SetCode(EVENT_ADJUST)
		e6:SetCondition(function(e) return not c:HasFlagEffect(id) end)
		e6:SetOperation(function(e) e:Reset() Duel.SkipPhase(tp,PHASE_BATTLE,RESET_PHASE|PHASE_BATTLE_STEP,1) end)
		e6:SetReset(RESET_PHASE|PHASE_END|PHASE_BATTLE)
		Duel.RegisterEffect(e6,tp)
	elseif atk_ct==0 and c:CanAttack() then
		-- REPARADO REGLA SINCRO: Si activas el efecto antes de golpear (atk_ct == 0),
		-- el script ya NO ejecutará Duel.SkipPhase. Deja la Battle Phase abierta en la RAM 
		-- para que puedas declarar tus batallas normalmente tras resolver la transmutación.
	else
		-- Cierre de seguridad si el monstruo ya no puede combatir en este turno
		Duel.SkipPhase(tp,PHASE_BATTLE,RESET_PHASE|PHASE_BATTLE_STEP,1)
	end
end
function s.endbpop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_ADJUST)
	e1:SetCondition(function(e) return not c:IsRelateToBattle() end)
	e1:SetOperation(function(e) e:Reset() Duel.SkipPhase(tp,PHASE_BATTLE,RESET_PHASE|PHASE_BATTLE_STEP,1) end)
	e1:SetReset(RESET_PHASE|PHASE_END|PHASE_BATTLE)
	Duel.RegisterEffect(e1,tp)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_DAMAGE_STEP_END)
	e2:SetOperation(function(e) e:Reset() Duel.SkipPhase(tp,PHASE_BATTLE,RESET_PHASE|PHASE_BATTLE_STEP,1) end)
	e2:SetReset(RESET_PHASE|PHASE_END|PHASE_BATTLE)
	Duel.RegisterEffect(e2,tp)
end