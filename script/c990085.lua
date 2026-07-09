local s,id=GetID()
function s.initial_effect(c)
	-- EFECTO ①: Mutación Colectiva a Nivel 12 (Basado milimétricamente en tu plantilla de referencia)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_LVCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE) -- Se ejecuta como el efecto de tu Magia Rápida al activarse
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.condition) -- Exige controlar un Sincro Dragón Nivel 12
	e1:SetTarget(s.lvtg)
	e1:SetOperation(s.lvop)
	c:RegisterEffect(e1)
	
	-- EFECTO ②: Añadir del GY a la mano si se invoca un Sincro Dragón OSCURIDAD
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_GRAVE) -- 0x10 = LOCATION_GRAVE
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- Lista de arquetipos soportados en tu base de datos
s.listed_series={0x3a,0x43,0xa3}

-- =========================================================================
-- ---  ADUANA DE REQUISITO DE CAMPO: SINCRO DRAGÓN NIVEL 12 REQUERIDO     ---
-- =========================================================================
function s.cfilter(c)
	-- El monstruo líder debe ser de Sincronía (0x2000), Raza Dragón (0x1) y Nivel 12 exacto
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsRace(RACE_DRAGON) and c:GetLevel()==12
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- La carta solo te dará la opción de activarse si el radar encuentra al coloso de Nivel 12 en tu mesa
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- =========================================================================
-- ---    ADUANAS DE VALIDACIÓN DE TU PLANTILLA PREMUM (AJUSTADA A NIVEL 12) ---
-- =========================================================================
function s.lvfilter(c)
	-- Busca monstruos boca arriba que posean Nivel y que NO sean actualmente Nivel 12 (Tu lógica)
	return c:IsFaceup() and c:HasLevel() and not c:IsLevel(12)
end

function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Legitimidad de activación: Verifica si hay al menos 1 monstruo apto para mutar en tus casillas
	if chk==0 then return Duel.IsExistingMatchingCard(s.lvfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_LVCHANGE,nil,1,tp,LOCATION_MZONE)
end

function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- 1. ADUANA DEL CANDADO EXCLUSIVO (LOCK DEL EXTRA DECK ASOCIADO AL TURNO)
	local e_lock=Effect.CreateEffect(c)
	e_lock:SetType(EFFECT_TYPE_FIELD)
	e_lock:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e_lock:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e_lock:SetDescription(aux.Stringid(id,1)) -- "Solo puedes invocar monstruos Sincro del Extra Deck"
	e_lock:SetTargetRange(1,0)
	e_lock:SetTarget(s.splimit)
	e_lock:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e_lock,tp)

	-- 2. OPERACIÓN DE MUTACIÓN COLCETIVA CALCADA DE TU PLANTILLA REPARADA
	local g=Duel.GetMatchingGroup(s.lvfilter,tp,LOCATION_MZONE,0,nil)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE) -- Tu propiedad protectora contra negaciones enemigas
		e1:SetCode(EFFECT_CHANGE_LEVEL)
		e1:SetValue(12) -- Convierte de forma obligatoria todas las estrellas a Nivel 12 exacto
		e1:SetReset(RESETS_STANDARD_PHASE_END) -- Tu constante de reseteo estable de Fase Final
		tc:RegisterEffect(e1)
	end
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsType(TYPE_SYNCHRO)
end

-- =========================================================================
-- ---  RESOLUCIÓN DEL EFECTO ②: MOTORES DE RASTREO Y AUTORECICLAJE GY     ---
-- =========================================================================
function s.thcfilter(c,tp)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_DRAGON) and c:IsType(TYPE_SYNCHRO)
		and c:IsControler(tp) and c:IsSynchroSummoned()
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.thcfilter,1,nil,tp)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,0)
end

-- Operación del segundo efecto: Recupera la carta del Cementerio de forma automática
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end
