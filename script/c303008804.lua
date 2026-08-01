local s,id=GetID()
function s.initial_effect(c)
	-- CABECERA NATIVA DE TU REFERENCIA DE YUSEI: Saca la carta del mazo antes del duelo
	aux.AddSkillProcedure(c,1,false,s.flipcon,s.flipop,1)
	
	-- REGLA ① (EVENT_STARTUP): Modificación e inyección total en el segundo cero fuera del mazo
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_STARTUP)
	e1:SetRange(0x5f) -- Rango maestro neutral de tu servidor
	e1:SetOperation(s.startop)
	c:RegisterEffect(e1)
end

-- Lista de identidades asociadas fuera del mazo
s.listed_names={511880001,66457407,511880000}

function s.flipcon(e,tp,eg,ep,ev,re,r,rp)
	return aux.CanActivateSkill(tp) and Duel.GetFlagEffect(tp,id+2000)==0
end

function s.flipop(e,tp,eg,ep,ev,re,r,rp)
end

-- =========================================================================
-- --- 1. REGLA ①: INYECCIÓN MAESTRA + ELIMINACIÓN POR REUBICACIÓN TOTAL ---
-- =========================================================================
function s.startop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- Muestra el cartel interactivo de tu Skill en la pantalla de forma automática al iniciar
	Duel.Hint(HINT_CARD,0,id)
	
	-- PASO A: Añade fuera del mazo un 66457407 (Dark Verger) directo al Main Deck
	local token1=Duel.CreateToken(tp,66457407)
	if token1 then
		Duel.SendtoDeck(token1,tp,SEQ_DECKBOTTOM,REASON_RULE)
	end
	
	-- PASO B: Envía fuera del mazo un 511880001 (Copy Plant) directo al Cementerio
	local token2=Duel.CreateToken(tp,511880001)
	if token2 then
		Duel.SendtoGrave(token2,REASON_RULE)
	end
	
	-- PASO C: Añade fuera del mazo un 511880000 (Black Rose Dragon) al Extra Deck boca abajo
	local token3=Duel.CreateToken(tp,511880000)
	if token3 then
		Duel.SendtoDeck(token3,tp,SEQ_DECKTOP,REASON_RULE)
	end
	
	-- Baraja de forma reglamentaria tu mazo principal para integrar tu soporte
	Duel.ShuffleDeck(tp)
	
	-- =========================================================================
	-- ---    LA SOLUCIÓN DE TU REFERENCIA DE YUSEI PARA QUE SÍ DESAPAREZCA   ---
	-- =========================================================================
	-- SANEADO: Usamos el borrado atómico de herencia. Buscamos el cartón físico 
	-- original de la Skill en absolutamente todas las locaciones posibles al arrancar.
	local g=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_EXTRA,0,nil,id)
	local tc=g:GetFirst()
	while tc do
		-- Apaga sus subrutinas en la memoria RAM
		tc:ResetEffect(id,RESET_COPY)
		-- Destierra el cartón de la Skill boca abajo FUERA del duelo por regla de juego.
		-- Esto es lo que limpia tu Extra Deck/Main Deck en tu servidor clásico antiguo,
		-- haciendo desaparecer la carta físicamente al 100% de tu vista.
		Duel.Remove(tc,POS_FACEDOWN,REASON_RULE)
		tc=g:GetNext()
	end
	
	-- Destruye de forma definitiva el efecto continuo de la RAM para liberar el procesador
	e:Reset()
end
