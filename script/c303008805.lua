local s, id = GetID()

function s.initial_effect(c)
	-- 1. Cabecera interactiva clásica para el botón de la Main Phase (Buscador)
	aux.AddSkillProcedure(c, 1, false, s.flipcon, s.flipop, 1)
	
	-- 2. REGLA ① AUTOMÁTICA (EVENT_STARTUP): Inyección total en el segundo cero fuera del mazo
	local e1 = Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE + EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_STARTUP)
	e1:SetRange(0x5f)
	e1:SetOperation(s.startop)
	c:RegisterEffect(e1)
end

-- Lista de identidades asociadas unificadas con la versión oficial (57734012)
s.listed_series = {SET_TACHYON}
s.listed_names = {88177324, 551010107, 8038143, 57734012}

-- =========================================================================
-- --- 1. REGLA ① AUTOMÁTICA: LA INYECCIÓN INDESTRUCTIBLE DESDE FUERA DECK ---
-- =========================================================================
function s.startop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local p = e:GetOwnerPlayer()
	Duel.Hint(HINT_CARD, 0, id)
	
	-- PASO A: Añade fuera del deck un 8038143 (Tachyon Transmigration) directo al Main Deck (Tope)
	local token1 = Duel.CreateToken(p, 8038143)
	if token1 then
		Duel.SendtoDeck(token1, p, SEQ_DECKTOP, REASON_RULE)
	end
	
	-- PASO B: Barajamos obligatoriamente el mazo para fijar la mezcla inicial
	Duel.ShuffleDeck(p)
	
	-- PASO C: Inyectamos a 57734012 (The Seventh One) de forma limpia DIRECTO AL FONDO (SEQ_DECKBOTTOM)
	local token2 = Duel.CreateToken(p, 57734012)
	if token2 then
		Duel.SendtoDeck(token2, p, SEQ_DECKBOTTOM, REASON_RULE)
	end
	
	-- PASO D: Registramos el listener independiente de la Draw Phase (Funciona 1° o 2° turno sin fallo)
	local e_draw = Effect.CreateEffect(c)
	e_draw:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e_draw:SetCode(EVENT_PREDRAW)
	e_draw:SetCountLimit(1)
	e_draw:SetCondition(s.drawcon)
	e_draw:SetOperation(s.drawop)
	Duel.RegisterEffect(e_draw, p)
	
	-- PASO E: RESTRICCIÓN DE MIZAR EN TIEMPO REAL (LIBERTAD EN EXTRA DECK DRAGÓN)
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET + EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e2:SetCode(EFFECT_CANNOT_SUMMON)
	e2:SetTargetRange(1, 0)
	e2:SetTarget(s.sumlimit)
	e2:SetReset(RESET_PHASE + PHASE_END, 100) 
	Duel.RegisterEffect(e2, p)
	
	local e3 = e2:Clone()
	e3:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	Duel.RegisterEffect(e3, p)
	
	e:Reset()
end

function s.sumlimit(e, c, sump, sumtyp, sumpos, targetp, se)
	if c:IsLocation(LOCATION_EXTRA) and c:IsRace(RACE_DRAGON) then return false end
	if c:IsRace(RACE_DRAGON) and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK))
		and (c:IsLevel(4) or c:IsLevel(8)) then
		return false
	end
	return true 
end

-- =========================================================================
-- --- SUBRUTINAS DE LA DRAW PHASE (ROBO SEGURO DE LA SEVENTH ONE)       ---
-- =========================================================================
function s.drawcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.GetCurrentChain() == 0 
		and Duel.IsTurnPlayer(tp) 
		and Duel.GetFieldGroupCount(tp, LOCATION_DECK, 0) > 0
		and Duel.GetDrawCount(tp) > 0 
		and Duel.GetFlagEffect(tp, id + 3000) == 0 
		and Duel.IsExistingMatchingCard(Card.IsCode, tp, LOCATION_DECK, 0, 1, nil, 57734012)
end

function s.drawop(e, tp, eg, ep, ev, re, r, rp)
	if not Duel.SelectYesNo(tp, aux.Stringid(id, 0)) then return end
	
	local dt = Duel.GetDrawCount(tp)
	if dt ~= 0 then
		local e1 = Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_DRAW_COUNT)
		e1:SetTargetRange(1, 0)
		e1:SetReset(RESET_PHASE + PHASE_DRAW)
		e1:SetValue(0)
		Duel.RegisterEffect(e1, tp)
	end
	
	Duel.Hint(HINT_SKILL_FLIP, tp, id | (1 << 32))
	Duel.Hint(HINT_CARD, tp, id)
	
	local g = Duel.SelectMatchingCard(tp, Card.IsCode, tp, LOCATION_DECK, 0, 1, 1, nil, 57734012)
	if #g > 0 and Duel.SendtoHand(g, nil, REASON_EFFECT) > 0 then
		Duel.ConfirmCards(1 - tp, g)
		Duel.Hint(HINT_SKILL_FLIP, tp, id | (2 << 32))
		Duel.RegisterFlagEffect(tp, id + 3000, 0, 0, 0)
	end
end

-- =========================================================================
-- --- BUSCADOR MANUAL DE LA MAIN PHASE (BOTÓN DE INTERFAZ)             ---
-- =========================================================================
function s.revealfilter(c)
	return c:IsLocation(LOCATION_HAND) and ((c:IsRace(RACE_DRAGON) and c:IsLevel(8)) or c:IsSetCard(SET_TACHYON))
end

function s.searchfilter(c)
	return c:IsRace(RACE_DRAGON) and (c:IsAttribute(ATTRIBUTE_LIGHT) or c:IsAttribute(ATTRIBUTE_DARK))
		and (c:IsLevel(4) or c:IsLevel(8)) and c:IsAbleToHand()
end

function s.flipcon(e, tp, eg, ep, ev, re, r, rp)
	if not aux.CanActivateSkill(tp) then return false end
	local phase = Duel.GetCurrentPhase()
	return (phase == PHASE_MAIN1 or phase == PHASE_MAIN2) 
		and Duel.GetFlagEffect(tp, id + 2000) == 0 
		and Duel.IsExistingMatchingCard(s.revealfilter, tp, LOCATION_HAND, 0, 1, nil)
		and Duel.IsExistingMatchingCard(s.searchfilter, tp, LOCATION_DECK, 0, 1, nil)
end

function s.flipop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SKILL_FLIP, tp, id | 1)
	Duel.Hint(HINT_CARD, 0, id)
	Duel.RegisterFlagEffect(tp, id + 2000, RESET_PHASE + PHASE_END, 0, 1)
	
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONFIRM)
	local rc = Duel.SelectMatchingCard(tp, s.revealfilter, tp, LOCATION_HAND, 0, 1, 1, nil)
	if #rc > 0 then
		Duel.ConfirmCards(1 - tp, rc)
		
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
		local g = Duel.SelectMatchingCard(tp, s.searchfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
		if #g > 0 then
			Duel.SendtoHand(g, nil, REASON_EFFECT)
			Duel.ConfirmCards(1 - tp, g)
		end
	end
end