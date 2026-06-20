local s,id=GetID()
function s.initial_effect(c)
	-- EFECTO ①: Activación estándar desde la mano o campo (Magia Rápida)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- EFECTO ②: Activación especial desde el CEMENTERIO (Solo en TU turno)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_ACTIVATE) 
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_GRAVE) 
	e2:SetCountLimit(1,id) -- Comparte el límite de nombre por turno (uno u otro)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e2:SetCondition(s.gycon) -- CORREGIDO: Bloquea el efecto si es turno del rival
	e2:SetCost(s.gycost) 
	e2:SetTarget(s.target) 
	e2:SetOperation(s.activate) 
	c:RegisterEffect(e2)
end

s.listed_series={SET_THE_PHANTOM_KNIGHTS,SET_XYZ_DRAGON}

-- --- FILTROS DE SELECCIÓN ---
function s.tgfilter(c,e,tp)
	local is_valid_archetype = c:IsType(TYPE_XYZ) and (c:IsSetCard(SET_THE_PHANTOM_KNIGHTS) or c:IsSetCard(SET_XYZ_DRAGON))
	if not is_valid_archetype then return false end
	
	if c:IsLocation(LOCATION_MZONE) then
		return c:IsFaceup() and c:IsCanBeEffectTarget(e)
			and Duel.IsExistingMatchingCard(s.exspfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c,c:GetRank())
	elseif c:IsLocation(LOCATION_GRAVE|LOCATION_REMOVED) then
		return c:IsCanBeEffectTarget(e) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.exspfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c,c:GetRank())
	end
	return false
end

function s.exspfilter(c,e,tp,mc,rk)
	local is_dark_xyz = c:IsType(TYPE_XYZ) and c:IsAttribute(ATTRIBUTE_DARK)
	local rank_check = c:IsRank(rk+1) or c:IsRank(rk+2)
	return is_dark_xyz and rank_check and mc:IsCanBeXyzMaterial(c,tp)
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED) and s.tgfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,aux.NecroValleyFilter(s.tgfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED|LOCATION_MZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- --- CONDICIÓN Y COSTE DESDE EL CEMENTERIO (e2) ---
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	-- 1. LA CLAVE: Comprueba de forma estricta que sea TU turno actual
	local is_my_turn = Duel.GetTurnPlayer()==tp
	-- 2. Exige NO controlar monstruos en tu campo
	local no_monsters = Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
	-- 3. Exige que NO sea el turno en que la carta cayó al Cementerio
	local not_this_turn = e:GetHandler():GetTurnID() ~= Duel.GetTurnCount()
	
	return is_my_turn and no_monsters and not_this_turn
end
function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end

-- --- OPERACIÓN DE RESOLUCIÓN PRINCIPAL ---
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	
	if tc:IsLocation(LOCATION_GRAVE|LOCATION_REMOVED) then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		if not Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP) then return end
		Duel.SpecialSummonComplete()
	end
	
	if tc:IsFacedown() or tc:IsControler(1-tp) then return end
	
	local g=Duel.GetMatchingGroup(s.exspfilter,tp,LOCATION_EXTRA,0,nil,e,tp,tc,tc:GetRank())
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=g:Select(tp,1,1,nil):GetFirst()
		if not sc then return end
		
		Duel.BreakEffect()
		sc:SetMaterial(tc)
		Duel.Overlay(sc,tc)
		
		if Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
			sc:CompleteProcedure()
			local c=e:GetHandler()
			if c:IsRelateToEffect(e) then
				c:CancelToGrave()
				Duel.Overlay(sc,c)
			end
		end
	end
end
