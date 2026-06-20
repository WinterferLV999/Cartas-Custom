local s,id=GetID()
function s.initial_effect(c)
	-- Invocación Xyz estándar (3 monstruos de OSCURIDAD de Nivel 4) o por Superposición Especial
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK),4,3,s.ovfilter,aux.Stringid(id,0),3,s.xyzop)
	c:EnableReviveLimit()
	
	-- EFECTO ①: Negación masiva, reducción de ATK a 0, aumento de poder e INMUNIDAD CONTINUA ABSOLUTA (Tu efecto rápido inmune)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	--e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE) -- Mantiene la inmunidad nativa de cadena que te funcionó
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e1:SetCost(s.discost)
	e1:SetOperation(s.disop)
	c:RegisterEffect(e1)
	
	-- REGLA DE INMUNIDAD: Protege al propio monstruo de Skill Drain u otras negaciones si tiene el material
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_DISABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.immcon)
	c:RegisterEffect(e2)

	-- EFECTO ③: Tu nueva flotación de venganza con acople inmediato al Dark Rebellion original
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2)) 
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DAMAGE_STEP)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

s.listed_names={16195942}

-- --- LÓGICA DE INVOCACIÓN Y ABSORCIÓN (e1 y e2) ---
function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsSummonCode(lc,SUMMON_TYPE_XYZ,tp,16195942)
end
function s.xyzop(e,tp,chk,mc)
	return Duel.GetLP(1-tp)-Duel.GetLP(tp)>=2000
end
function s.immcon(e)
	return e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,16195942)
end
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- LA SOLUCIÓN TÉCNICA: Si el oponente encadenó Chalice y NO tenemos el material, 
	-- el motor aplicará el estado IsDisabled(). Si está desactivado, el efecto se detiene de inmediato.
	if c:IsDisabled() and not s.immcon(e) then return end
	
	-- Buscamos todas las cartas boca arriba que controla el oponente en el campo
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_ONFIELD,nil)
	if #g==0 then return end
	
	local negated_count=0
	
	for tc in aux.Next(g) do
		-- Negamos los efectos de la carta continuamente boca arriba
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
		
		negated_count = negated_count + 1
		
		-- Si la carta del rival es un monstruo, reducimos su ATK a 0 de forma definitiva
		if tc:IsType(TYPE_MONSTER) then
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_SET_ATTACK_FINAL)
			e3:SetValue(0)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e3)
		end
	end
	
	-- El dragón gana 1000 de ATK por cada carta silenciada con éxito
	if negated_count>0 and c:IsFaceup() and c:IsRelateToEffect(e) then
		local bonus_atk = negated_count * 1000
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetCode(EFFECT_UPDATE_ATTACK)
		e4:SetValue(bonus_atk)
		e4:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e4)
	end
end

-- --- LÓGICA DE FLOTACIÓN CON ACOPLE INMEDIATO (e3) ---
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return rp~=tp and c:IsReason(REASON_EFFECT) and c:GetPreviousControler()==tp and c:IsPreviousPosition(POS_FACEUP)
end
function s.filter(c,e,tp)
	return c:IsCode(16195942) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and s.filter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	local c=e:GetHandler()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP_DEFENSE)~=0 then
		-- Absorbe y acopla la armadura inmediatamente como material
		if c:IsRelateToEffect(e) and (c:IsLocation(LOCATION_GRAVE) or c:IsLocation(LOCATION_REMOVED)) then
			Duel.Overlay(tc, Group.FromCards(c))
		end
		-- Concede las protecciones de combate
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(3008)
		e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		tc:RegisterEffect(e2)
	end
	Duel.SpecialSummonComplete()
end
