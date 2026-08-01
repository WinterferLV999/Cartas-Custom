local s,id=GetID()
function s.initial_effect(c)
	-- EFECTO ①: Esta carta es tratada como un monstruo de Tipo Planta en el Cementerio
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_ADD_RACE)
	e1:SetRange(LOCATION_GRAVE) -- Se aplica estrictamente en el Cementerio
	e1:SetValue(RACE_PLANT)     -- Añade el Tipo Planta a su ADN de juego
	c:RegisterEffect(e1)
	
	-- EFECTO ②: Si esta carta es añadida a tu mano (excepto por robo normal): Puedes Invocarla de Modo Especial
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetCountLimit(1,{id,0})
	e2:SetCondition(s.selfspcon) -- Condición de exclusión de robo oficial
	e2:SetTarget(s.selfsptg)
	e2:SetOperation(s.selfspop)
	c:RegisterEffect(e2)

	-- EFECTO ③ REESCRITO: Intercepta de forma obligatoria cualquier destierro desde tu Cementerio y lo regresa
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD) -- Disparo forzado (Funciona desde la zona de desterrados)
	e3:SetCode(EVENT_REMOVE)
	e3:SetRange(LOCATION_REMOVED) -- Ubicación física donde vigila el efecto
	e3:SetCondition(s.retcon)
	e3:SetTarget(s.rettg)
	e3:SetOperation(s.retop)
	c:RegisterEffect(e3)
end

-- Lista de arquetipos indexados para compatibilidad
s.listed_series={SET_ROSE}

-- =========================================================================
-- ---         RESOLUCIÓN DEL EFECTO ② (INVOCACIÓN POR BÚSQUEDA)         ---
-- =========================================================================
function s.selfspcon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsReason(REASON_DRAW)
end

function s.selfsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
end

function s.selfspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- =========================================================================
-- ---        RESOLUCIÓN DEL EFECTO ③ (RETORNO DEFENSIVO DESDE REMOVED)   ---
-- =========================================================================
function s.retfilter(c,tp,hc)
	-- Filtra cartas que provengan de tu propio Cementerio y excluye estrictamente a esta copia física (hc)
	return c:IsPreviousLocation(LOCATION_GRAVE) and c:GetPreviousControler()==tp and c~=hc
end

function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- El efecto salta si en el grupo de cartas desterradas hay al menos una de tu cementerio (sin contar esta copia)
	return eg:IsExists(s.retfilter,1,nil,tp,c)
end

function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local c=e:GetHandler()
	local g=eg:Filter(s.retfilter,nil,tp,c)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,#g,0,0)
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Captura las cartas desterradas de tu cementerio que siguen actualmente en la zona de desterrados
	local g=eg:Filter(s.retfilter,nil,tp,c):Filter(Card.IsLocation,nil,LOCATION_REMOVED)
	if #g>0 then
		Duel.BreakEffect() -- Breve pausa visual estética de Konami
		-- Envía las cartas de vuelta a tu Cementerio original de forma inmediata
		Duel.SendtoGrave(g,REASON_EFFECT+REASON_RETURN)
	end
end
