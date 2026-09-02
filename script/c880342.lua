local s,id=GetID()
function s.initial_effect(c)
	-- 1. EFECTO PRINCIPAL (MATRIZ TACHYON): Negar activaciones de la cadena y barajarlas al Deck
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- 2. REGLA ESPECIAL: Activar el mismo turno que es colocada si controlas a Z-ARC
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetCondition(s.actcon)
	e2:SetDescription(aux.Stringid(id,0))
	c:RegisterEffect(e2)
	
	-- 3. RECICLAJE DESDE EL GY: Añadir esta carta a la mano al invocar un Supreme King del Extra Deck
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.setcon)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)
end

-- Lista de identidades asociadas indexadas de fábrica
s.listed_names={13331639}

function s.cfilter(c,tp)
	return c:IsOnField() and c:IsSetCard(0xf8) and c:IsControler(tp)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	if tp==ep or not Duel.IsChainNegatable(ev) then return false end
	
	-- Escaneo estructural de tus categorías para validar que atenten contra tus cartas 0xf8
	local match=false
	local categories={CATEGORY_DESTROY, CATEGORY_TOHAND, CATEGORY_REMOVE, CATEGORY_TODECK, CATEGORY_RELEASE, CATEGORY_TOGRAVE}
	for _,cat in ipairs(categories) do
		local ex,tg,tc=Duel.GetOperationInfo(ev,cat)
		if ex and tg~=nil and tc+tg:FilterCount(s.cfilter,nil,tp)-#tg>0 then
			match=true
			break
		end
	end
	if not match then return false end

	-- Si hay match, el bucle Tachyon audita que los eslabones sean negables por el sistema
	for i=1,ev do
		local te,tgp=Duel.GetChainInfo(i,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
		if tgp~=tp and Duel.IsChainNegatable(i) then
			return true
		end
	end
	return false
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	
	-- Captura la carta exacta que originó la activación de este eslabón enemigo
	local rc=re:GetHandler()
	
	-- Informamos al Core clásico en C++ de las dos categorías que se ejecutarán
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
	
	-- SANEADO: Si la carta enemiga es legalmente barajable en el mazo, la registra en el búfer
	if rc:IsAbleToDeck() and rc:IsRelateToEffect(re) and not rc:IsHasEffect(EFFECT_CANNOT_TO_DECK) and Duel.IsPlayerCanSendtoDeck(tp,rc) then
		Duel.SetOperationInfo(0,CATEGORY_TODECK,eg,1,0,0)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- Captura el puntero dinámico de la carta del rival en la RAM
	local rc=re:GetHandler()
	
	-- Negamos de forma legítima ÚNICAMENTE la activación de este eslabón actual
	if Duel.NegateActivation(ev) then
		
		-- Inyectamos los apagadores de estados continuos en la RAM sobre la carta enemiga
		local e8=Effect.CreateEffect(e:GetHandler())
		e8:SetType(EFFECT_TYPE_SINGLE)
		e8:SetCode(EFFECT_DISABLE)
		e8:SetReset(RESET_EVENT+RESETS_STANDARD)
		rc:RegisterEffect(e8,true)
		
		local e9=Effect.CreateEffect(e:GetHandler())
		e9:SetType(EFFECT_TYPE_SINGLE)
		e9:SetCode(EFFECT_DISABLE_EFFECT)
		e9:SetReset(RESET_EVENT+RESETS_STANDARD)
		rc:RegisterEffect(e9,true)
		
		-- COMPATIBILIDAD CON CARD DE REFERENCIA DE HARDWARE: 
		-- Validamos que la carta siga físicamente relacionada a su efecto antes del traslado
		if rc:IsRelateToEffect(re) and not rc:IsHasEffect(EFFECT_CANNOT_TO_DECK) and Duel.IsPlayerCanSendtoDeck(tp,rc) then
			
			-- EL SECRETO REVELADO DE HARDWARE: Borra el flag de ir al cementerio del rival en la caché.
			-- Esto evita que Magias Normales o Trampas Normales saboteen la redirección de bits.
			rc:CancelToGrave()
			
			-- Envía la carta individual al mazo del oponente y ejecuta un barajado nativo inmediato (SEQ_DECKSHUFFLE)
			Duel.SendtoDeck(rc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
end

-- =========================================================================
-- --- SUBRUTINAS DE BOTÓN DE MANO Y RECICLAJE DESDE EL GY               ---
-- =========================================================================
function s.actcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_MZONE,0,1,nil,13331639)
end

function s.sfilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0xf8) and c:IsSummonLocation(LOCATION_EXTRA) and c:IsPreviousControler(tp)
end

function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.sfilter,1,nil,tp)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end
