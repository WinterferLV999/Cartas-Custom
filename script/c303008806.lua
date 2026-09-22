local s,id=GetID()
function s.initial_effect(c)
	-- SKILL REPARADA DEFINTIVA: Cambiada a EVENT_STARTUP (Arranque Absoluto de la Partida).
	-- SANEADO MAESTRO: Corre en el segundo cero, antes de que el juego calcule la mano inicial.
	-- Escanea tus restricciones Cubic, inyecta los 3 Vijam y se evapora al Limbo (-2) al instante.
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_SET_AVAILABLE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_STARTUP)
	e1:SetRange(LOCATION_DECK+LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.autoskillop)
	c:RegisterEffect(e1)
end

s.listed_names={15610297}

function s.illegal_mon_filter(c,id)
	return c:IsMonster() and not c:IsSetCard(0xe3) and not c:IsCode(id)
end

function s.illegal_st_filter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and not c:IsSetCard(0xe3)
end

-- =========================================================================
-- --- OPERACIÓN DEFINTIVA: INYECCIÓN PREVENTIVA Y EVAPORACIÓN AL LIMBO     ---
-- =========================================================================
function s.autoskillop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- 1. Capturamos los inventarios físicos de tu Main Deck y tu Extra Deck en el segundo cero
	local main_deck = Duel.GetFieldGroup(tp,LOCATION_DECK,0)
	local extra_deck = Duel.GetFieldGroup(tp,LOCATION_EXTRA,0)
	
	-- 2. ESCÁNER DE VALIDACIÓN DE LA IMAGEN DE DUEL LINKS:
	-- Monstruos exclusivos Cubic (0xe3) y Magias/Trampas genéricas <= 6
	local has_illegal_monster = main_deck:IsExists(s.illegal_mon_filter,1,nil,id) 
		or extra_deck:IsExists(s.illegal_mon_filter,1,nil,id)
		
	local illegal_st_count = main_deck:FilterCount(s.illegal_st_filter,nil) or 0
	
	-- 3. VALIDACIÓN E INYECCIÓN EN CALIENTE TRASPASANDO EL BLOQUEO
	if not has_illegal_monster and illegal_st_count <= 6 then
		
		-- Despliega el cartel interactivo de tu Skill de forma automática en tu monitor
		Duel.Hint(HINT_CARD,0,id)
		
		-- Bucle recursivo para fabricar e inyectar tus 3 Vijam reales de base de datos
		for i=1,3 do
			local token=Duel.CreateToken(tp,15610297)
			if token then
				-- Los envía al fondo usando el método de tu manuscrito original
				Duel.SendtoDeck(token,tp,SEQ_DECKBOTTOM,REASON_RULE)
			end
		end
		
		-- Baraja tu mazo completo para mezclar los 3 Vijam nuevos de forma aleatoria
		Duel.ShuffleDeck(tp)
	end
	
	-- =========================================================================
	-- --- EL DESVANECIMIENTO PREVENTIVO DE HARDWARE (MÉTODO -2 EN STARTUP)  ---
	-- =========================================================================
	-- REPARADO: Al ejecutarse en EVENT_STARTUP, la RAM borra los hilos de la Skill 
	-- y la saca del juego ANTES de repartir las cartas. Jamás aparecerá en tu mano.
	if c then
		c:ResetEffect(id,RESET_COPY)
		Duel.SendtoDeck(c,tp,-2,REASON_RULE) -- Eject al Limbo Absoluto Fuera del Juego
	end
	
	e:Reset()
end
