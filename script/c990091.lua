local s,id=GetID()
function s.initial_effect(c)
	--xyz summon
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_BATTLIN_BOXER),4,3)
	c:EnableReviveLimit()
	
	--damage reduce
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e1:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e1:SetCondition(s.rdcon)
	e1:SetOperation(s.rdop)
	c:RegisterEffect(e1)
	
	--battle indestructable
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetCondition(s.con)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	--los monstruos del oponente no pueden activar efectos durante mi phase de batalla
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,1) 
	e3:SetCondition(s.actcon)
	e3:SetValue(s.actval)
	c:RegisterEffect(e3)

	--Desacopla 1 material para colocar 1 Contraefecto "Counter" del Deck/GY (Se puede activar ese turno)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetType(EFFECT_TYPE_IGNITION) 
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1) 
	e4:SetCost(s.setcost) 
	e4:SetTarget(s.settg)
	e4:SetOperation(s.setop)
	c:RegisterEffect(e4,false,REGISTER_FLAG_DETACH_XMAT)
end

s.listed_series={SET_BATTLIN_BOXER,SET_COUNTER}

function s.rdcon(e,tp,eg,ep,ev,re,r,rp)
	return ep==tp
end

function s.rdop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ChangeBattleDamage(ep,ev/2)
end

function s.con(e,c)
	return e:GetHandler():IsAttackPos() 
end

function s.actcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsBattlePhase() and Duel.IsTurnPlayer(tp)
end

function s.actval(e,re,tp)
	return re:IsMonsterEffect()
end

-- =========================================================================
-- ---   MÓDULO DE RASTREO CORREGIDO: TU FILTRO EXACTO DE CONTRAEFECTO    ---
-- =========================================================================
function s.setfilter(c)
	-- CORRECCIÓN: Aplicada tu sintaxis estricta de validación de arquetipo y subtipo de trampa
	return c:IsSetCard(SET_COUNTER) and c:IsCounterTrap() and c:IsSSetable()
end

function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local tc=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil):GetFirst()
	if tc then
		if Duel.SSet(tp,tc)~=0 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetDescription(aux.Stringid(id,1))
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
			e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
	end
end
