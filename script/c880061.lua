local s,id=GetID()
function s.initial_effect(c)
	-- EFECTO ①: De-Fusión + Contadores + Convertir en Nivel 1
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON+CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- EFECTO ②: De-Sincronía + Contadores + Convertir en Nivel 1
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON+CATEGORY_COUNTER)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetTarget(s.sytarget)
	e2:SetOperation(s.syactivate)
	c:RegisterEffect(e2)
	
	-- EFECTO ③: De-Enlace + Contadores + Convertir en Nivel 1
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON+CATEGORY_COUNTER)
	e3:SetType(EFFECT_TYPE_ACTIVATE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetTarget(s.lktarget)
	e3:SetOperation(s.lkactivate)
	c:RegisterEffect(e3)

	-- EFECTO ④: De-Xyz + Contadores + Convertir en Nivel 1
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON+CATEGORY_COUNTER)
	e4:SetType(EFFECT_TYPE_ACTIVATE)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetTarget(s.xyztarget)
	e4:SetOperation(s.xyzactivate)
	c:RegisterEffect(e4)
	-- EFECTO ⑤: De-Ritual + Contadores + Convertir en Nivel 1
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,4)) -- Registra el botón de selección de-Ritual
	e5:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON+CATEGORY_COUNTER)
	e5:SetType(EFFECT_TYPE_ACTIVATE)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetTarget(s.rittarget)
	e5:SetOperation(s.ritactivate)
	c:RegisterEffect(e5)
end

s.counter_place_list={0x1041}

-- FUNCIÓN AUXILIAR MAESTRA: Coloca el contador y reduce el nivel a 1 usando tu formato condicional blindado
function s.apply_predation(c,mg)
	for mgc in aux.Next(mg) do
		-- Coloca el contador Predator (0x1041) de forma exitosa primero
		if mgc:AddCounter(0x1041,1) then
			-- CONDICIÓN INTEGRADA: Solo reduce si la carta acepta niveles (No Xyz/Link) y es mayor a 1
			if not mgc:IsType(TYPE_XYZ+TYPE_LINK) and mgc:GetLevel()>1 then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_CHANGE_LEVEL)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				e1:SetCondition(s.lvcon) -- Se apaga de inmediato si pierde sus contadores
				e1:SetValue(1)
				mgc:RegisterEffect(e1)
			end
		end
	end
end
function s.lvcon(e)
	return e:GetHandler():GetCounter(0x1041)>0
end

-- --- 1. SECCIÓN DE DE-FUSIÓN ---
function s.filter(c)
	return c:IsFaceup() and c:IsType(TYPE_FUSION) and c:IsAbleToExtra()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA)
end
function s.mgfilter(c,e,tp,fusc,mg)
	return c:IsControler(tp) and c:IsLocation(LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA)
		and (c:GetReason()&0x40008)==0x40008 and c:GetReasonCard()==fusc
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and fusc:CheckFusionMaterial(mg,c,PLAYER_NONE|FUSPROC_NOTFUSION)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	local mg=tc:GetMaterial()
	local ct=#mg
	local p=tc:GetControler()
	if Duel.SendtoDeck(tc,nil,0,REASON_EFFECT)~=0 then
		Duel.BreakEffect()
		if tc:IsSummonType(SUMMON_TYPE_FUSION) and ct>0 and ct<=Duel.GetLocationCount(p,LOCATION_MZONE)
			and mg:FilterCount(s.mgfilter,nil,e,p,tc,mg)==ct
			and (ct<=1 or not Duel.IsPlayerAffectedByEffect(p,CARD_BLUEEYES_SPIRIT)) then
			if Duel.SpecialSummon(mg,0,tp,p,false,false,POS_FACEUP)>0 then
				s.apply_predation(e:GetHandler(),mg)
			end
		end
	end
end

-- --- 2. SECCIÓN DE DE-SINCRONÍA ---
function s.syfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsAbleToExtra()
end
function s.sytarget(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and s.syfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.syfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.syfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA)
end
function s.symgfilter(c,e,tp,sync)
	return c:IsControler(tp) and c:IsLocation(LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA)
		and (c:GetReason()&(REASON_SYNCHRO|REASON_MATERIAL))==(REASON_SYNCHRO|REASON_MATERIAL) and c:GetReasonCard()==sync
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.syactivate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	local mg=tc:GetMaterial()
	local ct=#mg
	local p=tc:GetControler()
	if Duel.SendtoDeck(tc,nil,0,REASON_EFFECT)~=0 then
		Duel.BreakEffect()
		if tc:IsSummonType(SUMMON_TYPE_SYNCHRO) and ct>0 and ct<=Duel.GetLocationCount(p,LOCATION_MZONE)
			and mg:FilterCount(s.symgfilter,nil,e,p,tc)==ct
			and (ct<=1 or not Duel.IsPlayerAffectedByEffect(p,CARD_BLUEEYES_SPIRIT)) then
			if Duel.SpecialSummon(mg,0,tp,p,false,false,POS_FACEUP)>0 then
				s.apply_predation(e:GetHandler(),mg)
			end
		end
	end
end

-- --- 3. SECCIÓN DE DE-ENLACE ---
function s.lkfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_LINK) and c:IsAbleToExtra()
end
function s.lktarget(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.lkfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.lkfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.lkfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA)
end
function s.lkmgfilter(c,e,tp)
	return c:IsControler(tp) and c:IsLocation(LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.lkactivate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	local mg=tc:GetMaterial()
	local ct=#mg
	local p=tc:GetControler()
	local sum_chk = tc:IsSummonType(SUMMON_TYPE_LINK) and ct>0 
		and mg:FilterCount(aux.NecroValleyFilter(s.lkmgfilter),nil,e,p)==ct
		and ct<=Duel.GetLocationCount(p,LOCATION_MZONE)
		and (ct<=1 or not Duel.IsPlayerAffectedByEffect(p,CARD_BLUEEYES_SPIRIT))
	if Duel.SendtoDeck(tc,nil,0,REASON_EFFECT)~=0 then
		if sum_chk then
			Duel.BreakEffect()
			if Duel.SpecialSummon(mg,0,tp,p,false,false,POS_FACEUP)>0 then
				s.apply_predation(e:GetHandler(),mg)
			end
		end
	end
end

-- --- 4. SECCIÓN DE DE-XYZ (SANEADA Y COMPLETADA DE FORMA IMPECABLE) ---
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsAbleToExtra()
end
function s.xyztarget(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.xyzfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.xyzfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.xyzfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA)
end
function s.xyzmgfilter(c,e,tp)
	return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.xyzactivate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	local ov_g=tc:GetOverlayGroup()
	local ct=#ov_g
	local p=tc:GetControler()
	local summon_group=Group.CreateGroup()
	if ct>0 then summon_group:Merge(ov_g) summon_group:KeepAlive() end
	local is_xyz_summoned = tc:IsSummonType(SUMMON_TYPE_XYZ)
	if Duel.SendtoDeck(tc,nil,0,REASON_EFFECT)~=0 then
		if is_xyz_summoned and ct>0 and #summon_group>0 then
			local final_summon = summon_group:Filter(s.xyzmgfilter,nil,e,p)
			if #final_summon==ct and ct<=Duel.GetLocationCount(p,LOCATION_MZONE)
				and (ct<=1 or not Duel.IsPlayerAffectedByEffect(p,CARD_BLUEEYES_SPIRIT)) then
				Duel.BreakEffect()
				if Duel.SpecialSummon(final_summon,0,tp,p,false,false,POS_FACEUP)>0 then
					s.apply_predation(e:GetHandler(),final_summon)
				end
			end
		end
	end
	if summon_group then summon_group:DeleteGroup() end
end
-- --- 5. SECCIÓN DE DE-RITUAL ULTRA-COMPATIBLE Y BLINDADA ---
function s.ritfilter(c,e,tp)
	-- CORREGIDO: Ahora verifica que el Ritual pueda ser regresado legalmente al Mazo (IsAbleToDeck)
	return c:IsFaceup() and c:IsType(TYPE_RITUAL) and c:IsAbleToDeck() and c:GetLevel()>0
end
function s.rittarget(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.ritfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.ritfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK) -- Sincronizado el mensaje visual a "Regresar al Deck"
	local g=Duel.SelectTarget(tp,s.ritfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA)
end

-- Filtro para buscar los tributos caídos en el Cementerio
function s.ritmgfilter(c,e,tp)
	return c:IsControler(tp) and c:IsLocation(LOCATION_GRAVE) and c:GetLevel()>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.ritactivate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	
	-- Capturamos el nivel exacto del monstruo de Ritual antes de moverlo
	local rit_level=tc:GetLevel()
	local p=tc:GetControler()
	
	-- Verificación previa: ¿Tienes al menos 1 monstruo invocable en tu cementerio?
	local check = tc:IsSummonType(SUMMON_TYPE_RITUAL) and Duel.GetLocationCount(p,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.ritmgfilter,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA,0,1,nil,e,p)
	
	-- 1. Regresamos el monstruo de Ritual a la mano
	if Duel.SendtoHand(tc,nil,REASON_EFFECT)~=0 then
		
		-- 2. Si regresó con éxito, el script abre tu Cementerio para que elijas los tributos
		if check then
			Duel.BreakEffect()
			
			-- Buscamos todos tus monstruos válidos en la tumba
			local grave_monsters=Duel.GetMatchingGroup(s.ritmgfilter,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_DECK+LOCATION_EXTRA,0,nil,e,p)
			
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			-- LA MAGIA MATEMÁTICA: "SelectWithSumEqual" obliga a que las cartas que toques en la pantalla 
			-- sumen de forma exacta el nivel del Ritual (mínimo 1 monstruo, máximo 5)
			local sg=grave_monsters:SelectWithSumEqual(tp,Card.GetLevel,rit_level,1,5)
			
			if #sg>0 then
				-- Realiza la Invocación Especial de los monstruos que elegiste
				if Duel.SpecialSummon(sg,0,tp,p,false,false,POS_FACEUP)>0 then
					-- Aplica tus contadores y reduce sus niveles a 1
					s.apply_predation(e:GetHandler(),sg)
				end
			end
		end
	end
end