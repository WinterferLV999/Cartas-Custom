local s,id=GetID()
function s.initial_effect(c)
	-- Activación única para ambos efectos de la Battle Phase
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_series={0xe3} -- Arquetipo Cúbico

-- La condición valida que obligatoriamente se esté en la Battle Phase
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase()
end

-- Filtro para el monstruo Cúbico que controlas en el campo
function s.tgfilter(c,e,tp)
	if not (c:IsFaceup() and c:IsSetCard(0xe3) and c:HasLevel()) then return false end
	local next_lvl = c:GetLevel() + 1
	
	-- Elige el origen de la búsqueda dependiendo del turno actual
	local loc = (Duel.GetTurnPlayer()==tp) and LOCATION_DECK or LOCATION_EXTRA
	local sum_type = (Duel.GetTurnPlayer()==tp) and SUMMON_TYPE_SPECIAL or SUMMON_TYPE_FUSION
	
	return Duel.IsExistingMatchingCard(s.spfilter,tp,loc,0,1,nil,e,tp,next_lvl,sum_type,c)
end

-- Filtro para el monstruo Cúbico que va a entrar del Deck o Extra Deck
function s.spfilter(c,e,tp,rk,sum_type,mc)
	return c:IsSetCard(0xe3) and c:IsLevel(rk) 
		and c:IsCanBeSpecialSummoned(e,sum_type,tp,false,false)
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
end

-- Target del efecto
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.tgfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_MZONE,0,1,nil,e,tp) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	
	local loc = (Duel.GetTurnPlayer()==tp) and LOCATION_DECK or LOCATION_EXTRA
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,loc)
end

-- Resolución del efecto (Operación unificada)
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or tc:IsFacedown() or not tc:IsRelateToEffect(e) or tc:IsImmuneToEffect(e) then return end
	
	local next_lvl = tc:GetLevel() + 1
	local is_my_turn = (Duel.GetTurnPlayer()==tp)
	
	local loc = is_my_turn and LOCATION_DECK or LOCATION_EXTRA
	local sum_type = is_my_turn and SUMMON_TYPE_SPECIAL or SUMMON_TYPE_FUSION
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,loc,0,1,1,nil,e,tp,next_lvl,sum_type,tc)
	local sc=g:GetFirst()
	
	if sc then
		-- Si existían materiales debajo del monstruo anterior, pásalos al nuevo
		local og=tc:GetOverlayGroup()
		if #og>0 then
			Duel.Overlay(sc,og)
		end
		
		-- Coloca al monstruo objetivo inicial debajo de la nueva invocación (Stack)
		sc:SetMaterial(Group.FromCards(tc))
		Duel.Overlay(sc,Group.FromCards(tc))
		
		-- Realiza la Invocación Especial / Invocación por Fusión
		if Duel.SpecialSummon(sc,sum_type,tp,tp,false,false,POS_FACEUP)~=0 then
			sc:CompleteProcedure()
		end
	end
end
