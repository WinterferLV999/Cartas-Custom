local s,id=GetID()
function s.initial_effect(c)
	-- Invocación Xyz estándar (2 monstruos de OSCURIDAD de Nivel 4)
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK),4,2)
	c:EnableReviveLimit()
	
	-- Chequeo de Materiales: Detecta si usaste a Dark Rebellion tratado como Nivel 4
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_MATERIAL_CHECK)
	e1:SetValue(s.valcheck)
	c:RegisterEffect(e1)
	
	-- EFECTO ①: Efecto Rápido Condicionado (Gana ATK = LP y Niega todo hasta el fin del turno rival)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e2:SetCondition(s.atkcon) -- Exige de forma estricta tener el Flag encendido
	e2:SetCost(s.atkcost)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
	--cannot target
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetCondition(s.atkcon) -- Exige de forma estricta tener el Flag encendido
	e3:SetValue(aux.tgoval)
	c:RegisterEffect(e3)
	--indes
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.atkcon) -- Exige de forma estricta tener el Flag encendido
	e4:SetValue(s.indval)
	c:RegisterEffect(e4)
	--search
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCost(Cost.SelfBanish)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end

s.listed_names={16195942}

-- --- LÓGICA DE DETECCIÓN DE MATERIAL ---
function s.matfilter(c,sc)
	return c:IsCode(16195942) and c:IsXyzLevel(sc,4)
end
function s.valcheck(e,c)
	local g=c:GetMaterial()
	if g:IsExists(s.matfilter,1,nil,c) then
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD_DISABLE-RESET_TOFIELD,0,1)
	end
end

-- --- LÓGICA DEL EFECTO CONDICIONADO DE COMBATE ---
-- Condición: El monstruo debe tener activo el Flag de haber usado al Dark Rebellion flexibilizado
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id)>0
end

-- Coste: Desacoplar 1 material Xyz
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- Operación: Gana ATK = LP y Apaga el tablero del rival hasta el fin de su propio turno
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- 1. Inyección de ATK igual a tus puntos de vida actuales
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local my_lp = Duel.GetLP(tp)
		if my_lp > 0 then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(my_lp)
			-- Dura hasta el final del turno del oponente
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END,Duel.GetTurnPlayer()==tp and 2 or 1)
			c:RegisterEffect(e1)
		end
	end
	
	-- 2. Buscamos todas las cartas boca arriba en el campo del oponente
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_ONFIELD,nil)
	for tc in aux.Next(g) do
		-- Niega los efectos continuamente boca arriba
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,Duel.GetTurnPlayer()==tp and 2 or 1)
		tc:RegisterEffect(e2)
		
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_DISABLE_EFFECT)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,Duel.GetTurnPlayer()==tp and 2 or 1)
		tc:RegisterEffect(e3)
	end
end

function s.indval(e,re,tp)
	return tp~=e:GetHandlerPlayer()
end
function s.thfilter(c)
	return c:IsSetCard(SET_RANK_UP_MAGIC) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end