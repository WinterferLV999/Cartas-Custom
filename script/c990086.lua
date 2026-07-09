local s,id=GetID()
function s.initial_effect(c)
	-- EFECTO ①: Activación de Trampa Contraefecto (Negación + Destrucción + Robo Masivo de 2)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING) -- Se dispara encadenándose a efectos en vivo
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL) -- Funciona en pleno Damage Step
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- CORREGIDO: Lista de arquetipos soportados utilizando tu macro oficial de sistema
s.listed_series={SET_RED_DRAGON_ARCHFIEND}

-- Filtro del líder: Busca monstruos "Red Dragon Archfiend" boca arriba en tu campo
function s.cfilter(c)
	-- CORREGIDO: Se inyectó tu constante exacta SET_RED_DRAGON_ARCHFIEND
	return c:IsFaceup() and c:IsSetCard(SET_RED_DRAGON_ARCHFIEND)
end

-- =========================================================================
-- ---         CONDICION DE ACTIVACIÓN PREMIUM (CALCADA DE TU PLANTILLA) ---
-- =========================================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- El oponente (1-tp) activa un efecto que se pueda negar, y tú controlas al líder en mesa
	return rp==1-tp and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- =========================================================================
-- ---         ADUANA DE TARGET: DECLARACIÓN DE OPERACIONES EN RAM      ---
-- =========================================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Sincronizado con tu referencia: chk==0 valida si el motor te permite robar las 2 cartas
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	
	-- Prepara los reportes del sistema para la animación visual interactiva en la pantalla
	if e:IsHasCategory(CATEGORY_NEGATE) then
		Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2) -- Exige estrictamente preparar el robo de 2
end

-- =========================================================================
-- ---     OPERACIÓN DEFINITIVA: EL APAGÓN TOTAL DEL CAMPO ENEMIGO        ---
-- =========================================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	
	-- PASO A: Niega la activación del efecto de la carta enemiga en la cadena actual
	if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) then
		
		-- PASO B: Hace estallar y destruye físicamente el cartón del oponente
		if Duel.Destroy(eg,REASON_EFFECT)>0 then
			Duel.BreakEffect() -- La pausa visual estética oficial de Konami que asienta los datos
			
			-- PASO C: Robas de forma obligatoria 2 cartas de tu baraja de forma limpia y consecutiva
			Duel.Draw(tp,2,REASON_EFFECT)
		end
	end
end
