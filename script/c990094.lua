local s,id=GetID()
function s.initial_effect(c)
	-- Add 1 "Battlin Boxer" monster or 1 "Counter" Counter Trap from your Deck to your hand
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE|EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)

	-- HERENCIA: Si es usado como material para un "Battlin' Boxer" Xyz, le otorga el efecto activo de desacoplar
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e5:SetProperty(EFFECT_FLAG_EVENT_PLAYER)
	e5:SetCode(EVENT_BE_MATERIAL)
	e5:SetCountLimit(1,id)
	e5:SetCondition(s.matcon)
	e5:SetOperation(s.effop)
	c:RegisterEffect(e5)
end

s.listed_series={SET_BATTLIN_BOXER}

function s.thfilter(c)
	return c:IsSetCard(SET_BATTLIN_BOXING) and c:IsSpellTrap() and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,e:GetHandler():GetOwner(),LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local p=e:GetHandler():GetOwner()
	Duel.Hint(HINT_SELECTMSG,p,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(p,s.thfilter,p,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,p,REASON_EFFECT)
		Duel.ConfirmCards(1-p,g)
	end
end

-- =========================================================================
-- ---   LÓGICA DE INYECCIÓN: OTORGA EFECTO ACTIVO CON CONDICIÓN          ---
-- =========================================================================
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetHandler():GetReasonCard()
	return r==REASON_XYZ and rc and rc:IsSetCard(SET_BATTLIN_BOXER)
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	if not rc then return end
	
	-- Inyecta un Efecto Rápido activo al monstruo Xyz resultante
	local e1=Effect.CreateEffect(rc)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O) -- Efecto Rápido Activo
	e1:SetCode(EVENT_FREE_CHAIN)   -- Se puede encadenar libremente
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)            -- Una vez por turno
	e1:SetCondition(s.skipcon)     -- NUEVA CONDICIÓN EXTRA DE OPERACIÓN
	e1:SetCost(s.skipcost)         -- COSTE: Desacoplar 1 material Xyz
	e1:SetOperation(s.skipop)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	rc:RegisterEffect(e1,true)
	
	-- Seguro contra crasheos para Xyz sin efectos nativos
	if not rc:IsType(TYPE_EFFECT) then
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_ADD_TYPE)
		e2:SetValue(TYPE_EFFECT)
		e2:SetReset(RESET_EVENT|RESETS_STANDARD)
		rc:RegisterEffect(e2,true)
	end
end

function s.skipcon(e,tp,eg,ep,ev,re,r,rp)
	-- CORRECCIÓN PASO A PASO: El efecto solo se ilumina si el oponente (0,1) controla monstruos en mesa
	return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_MZONE,1,nil)
end

function s.skipcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.skipop(e,tp,eg,ep,ev,re,r,rp)
	-- COPIA EXACTA DE TU PLANTILLA: Clava el candado en el reloj del duelo central
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0,1) -- Bloquea al rival (0 para ti, 1 para el oponente)
	e1:SetCode(EFFECT_SKIP_M1) -- Salta obligatoriamente la Main Phase 1
	e1:SetReset(RESET_PHASE+PHASE_MAIN1+RESET_OPPO_TURN)
	Duel.RegisterEffect(e1,tp)
end
