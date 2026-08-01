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
	
	-- EFECTO ②: ACTIVACIÓN EN EL TURNO SET (REPARADO: COMPATIBILIDAD DE HARDWARE DE ID ANIME)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE) -- Propiedad reina que activa el brillo boca abajo
	e2:SetCondition(s.actcon) -- Llama a tu aduana de verificación de mención
	c:RegisterEffect(e2)
end

-- Lista de arquetipos soportados oficialmente en tu base de datos (Red Dragon Archfiend)
s.listed_series={SET_RED_DRAGON_ARCHFIEND}
-- ID Oficial del Red Dragon Archfiend clásico para habilitar el radar del Core
s.listed_names={70902743}

-- =========================================================================
-- ---   CONDICIÓN DE ACTIVACIÓN ①: OMNI-NEGACIÓN UNIVERSAL LIBRE         ---
-- =========================================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- El oponente (1-tp) activa un efecto que se pueda negar de forma reglamentaria
	-- Se mantiene libre e independiente si la carta ya lleva un turno colocada.
	return rp==1-tp and Duel.IsChainNegatable(ev)
end

-- =========================================================================
-- ---   CONDICIÓN DEL EFECTO ②: TU ADUANA DE CORRECCIÓN POR ID FISICA   ---
-- =========================================================================
function s.actfilter(c)
	if not c:IsFaceup() then return false end
	-- CORREGIDO DEFINITIVO: Cambiamos el macro por la ID real del Red Demon original (70902743).
	-- Tu servidor ahora leerá en limpio si la carta en campo menciona formalmente al líder del mazo.
	return c:IsSetCard(SET_RED_DRAGON_ARCHFIEND) or c:ListsCode(70902743)
end

function s.actcon(e)
	-- Evalúa si existe al menos 1 carta válida que mencione al líder boca arriba en tu tablero (LOCATION_ONFIELD)
	return Duel.IsExistingMatchingCard(s.actfilter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,nil)
end

-- =========================================================================
-- ---         ADUANA DE TARGET: DECLARACIÓN DE OPERACIONES EN RAM      ---
-- =========================================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	
	if e:IsHasCategory(CATEGORY_NEGATE) then
		Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2) -- Prepara el robo obligatorio de 2
end

-- =========================================================================
-- ---     OPERACIÓN DEFINITIVA: EL APAGÓN TOTAL DEL CAMPO ENEMIGO        ---
-- =========================================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	
	-- PASO A: Niega la activación del efecto de la carta enemiga en la cadena actual
	if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) then
		
		-- PASO B: Hace estallar y destruye físicamente el cartón del oponente en la mesa
		if Duel.Destroy(eg,REASON_EFFECT)>0 then
			Duel.BreakEffect() -- La pausa visual estética oficial de Konami que asienta los datos
			
			-- PASO C: Robas de forma obligatoria 2 cartas de tu baraja de forma limpia
			Duel.Draw(tp,2,REASON_EFFECT)
		end
	end
end
