local s,id=GetID()
function s.initial_effect(c)
	-- EFECTO MAESTRO: Se ejecuta de forma automática e invisible antes de la primera Draw Phase
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_SET_AVAILABLE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PREDRAW) -- Disparador automático global en el segundo cero del duelo
	e1:SetRange(LOCATION_DECK+LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.autoskillcon)
	e1:SetOperation(s.autoskillop)
	c:RegisterEffect(e1)
end

-- Lista de identidades de tu base de datos asociadas a la habilidad
s.listed_names={511880001,66457407,511880000}

function s.autoskillcon(e,tp,eg,ep,ev,re,r,rp)
	-- Se asegura mecánicamente de actuar estrictamente en el arranque del Turno 1
	return Duel.GetTurnCount()==1
end

function s.autoskillop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- Despliega el cartel interactivo de tu Skill en la pantalla de forma automática
	Duel.Hint(HINT_CARD,0,id)
	
	-- PASO 1: Envía al Cementerio fuera del mazo la ID 511880001 (Copy Plant)
	local token1=Duel.CreateToken(tp,511880001)
	if token1 then
		Duel.SendtoGrave(token1,REASON_RULE)
	end
	
	-- PASO 2: Introduce al Main Deck la ID 66457407 (Dark Verger)
	local token2=Duel.CreateToken(tp,66457407)
	if token2 then
		Duel.SendtoDeck(token2,tp,SEQ_DECKBOTTOM,REASON_RULE)
		Duel.ShuffleDeck(tp) -- Baraja de forma legal para integrarla de forma aleatoria
	end
	
	-- PASO 3: Introduce al Extra Deck boca abajo la ID 511880000 (Black Rose Dragon)
	local token3=Duel.CreateToken(tp,511880000)
	if token3 then
		Duel.SendtoDeck(token3,tp,SEQ_DECKTOP,REASON_RULE)
	end
	
	-- COMPRESIÓN TÉCNICA: Si la carta sigue en el mazo, la borra mandándola al limbo fuera del juego de inmediato
	if c then
		c:ResetEffect(id,RESET_COPY) -- Apaga por completo las subrutinas de la carta en la RAM
		Duel.SendtoDeck(c,tp,-2,REASON_RULE) -- Forzado técnico al Limbo (-2). Se esfuma del Deck antes de iniciar
	end
	
	-- Destruye de forma definitiva la subrutina del efecto para liberar el procesador
	e:Reset()
end
