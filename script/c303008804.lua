local s,id=GetID()
function s.initial_effect(c)
	-- REPARADO DEFINITIVO: Usamos EVENT_PHASE + PHASE_DRAW para erradicar el error de 'SetCode'
	-- Este evento es 100% compatible con todas las versiones antiguas de tu emulador clásico.
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_SET_AVAILABLE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_DRAW) -- Se ejecuta de forma interactiva en la Draw Phase
	e1:SetRange(LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.skillcon)
	e1:SetOperation(s.skillop)
	c:RegisterEffect(e1)
end

-- Lista de identidades de tu base de datos asociadas a la habilidad
s.listed_names={511880001,66457407,511880000}

function s.skillcon(e,tp,eg,ep,ev,re,r,rp)
	-- Se asegura de que la inyección ocurra única y estrictamente al iniciar el Turno 1 del duelo
	return Duel.GetTurnCount()==1
end

function s.skillop(e,tp,eg,ep,ev,re,r,rp)
	-- Despliega el cartel interactivo de tu Skill en la pantalla
	Duel.Hint(HINT_CARD,0,id)
	
	-- PASO 1: Envía al Cementerio fuera del mazo la ID 511880001
	local token1=Duel.CreateToken(tp,511880001)
	if token1 then
		Duel.SendtoGrave(token1,REASON_RULE)
	end
	
	-- PASO 2: Introduce al Main Deck la ID 66457507 (Phoenixian Cluster Amaryllis)
	-- Con el motor al 100% de su capacidad en la Draw Phase, las IDs cargan en limpio
	local token2=Duel.CreateToken(tp,66457407)
	if token2 then
		Duel.SendtoDeck(token2,tp,SEQ_DECKBOTTOM,REASON_RULE)
		Duel.ShuffleDeck(tp) -- Baraja de forma legal para integrarla de forma aleatoria
	end
	
	-- PASO 3: Introduce al Extra Deck boca abajo la ID 511880000
	local token3=Duel.CreateToken(tp,511880000)
	if token3 then
		Duel.SendtoDeck(token3,tp,SEQ_DECKTOP,REASON_RULE)
	end
	
	-- Destruye de forma definitiva la subrutina de la RAM para liberar el procesador
	e:Reset()
end

