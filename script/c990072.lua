local s,id=GetID()
function s.initial_effect(c)
	-- EFECTO ①: Auto-Resurrección desde el Cementerio (Ignición)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_GRAVE) -- Se activa estrictamente en el Cementerio
	e1:SetCountLimit(1,id) -- HPTW: Una vez por turno
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	-- EFECTO ②: Robo de carta al ser material de Sincronía (Disparo / Trigger)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F) -- Disparo Obligatorio (Trigger F)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCountLimit(1,id+100) -- HPTW: Una vez por turno
	e2:SetCondition(s.drcon)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
end

-- Registra que pertenece al arquetipo T.G. (0x27)
s.listed_series={0x27}

-- --- 1. LÓGICA DEL EFECTO ① (AUTO-RESURRECCIÓN) ---
function s.cfilter(c)
	-- Busca un monstruo T.G. (0x27) boca arriba en tu lado del tablero
	return c:IsFaceup() and c:IsSetCard(0x27) and c:IsMonster()
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- La condición exige que controles al menos 1 monstruo que cumpla el filtro de arriba
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		-- Revive al monstruo en Posición de Ataque o Defensa boca arriba de forma libre
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- --- 2. LÓGICA DEL EFECTO ② (ROBO POR SINCRONÍA) ---
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	-- Verifica de forma estricta que la razón de envío sea haber sido usado como material de Sincronía
	return e:GetHandler():IsReason(REASON_SYNCHRO)
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- Al ser obligatorio, chk==0 devuelve verdadero directo
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1) -- Indica la cantidad exacta a robar: 1 carta
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	-- Ejecuta el comando oficial de robo de carta en el motor del juego
	Duel.Draw(p,d,REASON_EFFECT)
end
