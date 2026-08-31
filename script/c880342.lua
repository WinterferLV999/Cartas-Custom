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

-- =========================================================================
-- --- ADUANA DE MONITOREO DE CATEGORÍAS (TU CÓDIGO ORIGINAL SEGURO)     ---
-- =========================================================================
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

-- =========================================================================
-- --- TARGETS CON FORMATO DE REGISTRO TACHYON TRANSMIGRATION          ---
-- =========================================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local ng=Group.CreateGroup()
	local dg=Group.CreateGroup()
	
	-- Recorre la cadena entera buscando eslabones del rival para armar las pilas en la RAM
	for i=1,ev do
		local te,tgp=Duel.GetChainInfo(i,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
		if tgp~=tp and Duel.IsChainNegatable(i) then
			local tc=te:GetHandler()
			ng:AddCard(tc)
			-- Si la carta cumple las leyes de hardware para ir al mazo, la mete al grupo de barajado
			if tc:IsOnField() and tc:IsRelateToEffect(te) and not tc:IsHasEffect(EFFECT_CANNOT_TO_DECK) and Duel.IsPlayerCanSendtoDeck(tp,tc) then
				dg:AddCard(tc)
			end
		end
	end
	Duel.SetTargetCard(dg)
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,ng,#ng,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,dg,#dg,0,0)
end

-- =========================================================================
-- --- OPERACIÓN DEFINITIVA CON CANCELTOGRAVE (MÉTODO MIZAR INDESTRUCTIBLE)---
-- =========================================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local dg=Group.CreateGroup()
	
	-- Ejecuta el bucle de resolución eslabón por eslabón de la cadena
	for i=1,ev do
		local te,tgp=Duel.GetChainInfo(i,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
		if tgp~=tp and Duel.NegateActivation(i) then
			local tc=te:GetHandler()
			if tc:IsRelateToEffect(e) and tc:IsRelateToEffect(te) and not tc:IsHasEffect(EFFECT_CANNOT_TO_DECK) and Duel.IsPlayerCanSendtoDeck(tp,tc) then
				-- EL SECRETO DE HARDWARE: Borra el flag de ir al cementerio del rival en la caché
				tc:CancelToGrave()
				dg:AddCard(tc)
			end
		end
	end
	-- Envía todo el grupo masivo al mazo y baraja de forma 100% exitosa y real en tu pantalla
	Duel.SendtoDeck(dg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
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
