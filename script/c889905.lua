local s,id=GetID()

function s.initial_effect(c)
    -- Activar la carta
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCondition(s.condition)
    --e1:SetHintTiming(TIMING_BATTLE_PHASE+TIMING_BATTLE_END)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    --add this card
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
s.listed_names={CARD_RA}
-- Condición: Debe ser tu Battle Phase
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsBattlePhase() and Duel.IsTurnPlayer(tp)
	--return Duel.GetCurrentPhase()==PHASE_MAIN2 and Duel.IsTurnPlayer(tp)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    -- Evitar activaciones múltiples que rompan el motor
    if Duel.HasFlagEffect(tp,id) then return end
    Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)

    -- Efecto para permitir una segunda Battle Phase
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetDescription(aux.Stringid(id,0)) -- "Segunda Battle Phase"
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetTargetRange(1,0)
    e1:SetCode(EFFECT_BP_TWICE)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
    -- El reset debe ser al final del turno para que el motor procese ambas fases
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
    
    -- Mensaje de confirmación en el log del duelo
    Duel.Hint(HINT_CARD,0,id)
end
--Local No.2
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,10000010,10000080,10000090),tp,LOCATION_MZONE,0,1,nil) and Duel.GetCurrentPhase()==PHASE_MAIN1
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end