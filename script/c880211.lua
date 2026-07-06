local s,id=GetID()
function s.initial_effect(c)
	-- EFECTO ①: Búsqueda/Reciclaje Predaplant + Negación y Destrucción Masiva (Juego Rápido en Campo)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DISABLE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) -- Juramento por nombre
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	e1:SetHintTiming(0,TIMING_STANDBY_PHASE+TIMING_MAIN_END+TIMINGS_CHECK_MONSTER)
	c:RegisterEffect(e1)
	
	-- EFECTO ② NUEVO: Desterrar esta carta + 1 Magia de Fusión del GY para copiar su efecto (Ignición en Cementerio)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1000) -- Una vez por turno para la habilidad de la tumba
	e2:SetCost(s.copycost)
	e2:SetTarget(s.copytg)
	e2:SetOperation(s.copyop)
	c:RegisterEffect(e2)
end

s.listed_names={id}
s.counter_place_list={0x1041} 
s.listed_series={0x10f3,0x46} -- Registra Predaplant (0x10f3) y Fusión/Polimerización (0x46)

-- =========================================================================
-- --- MOTOR DEL EFECTO ① (TU BASE GANADORA INTERACTIVA QUE YA FUNCIONA) ---
-- =========================================================================
function s.remfilter(c)
	return c:GetCounter(0x1041)>0
end

function s.thfilter(c)
	return c:ListsCounter(0x1041) and c:IsAbleToHand() and not c:IsCode(id)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DISABLE,nil,1,1-tp,LOCATION_ONFIELD)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_ONFIELD)
end

function s.endymionfilter(c)
	return c:GetCounter(0x1041)>0 and c:IsType(TYPE_FUSION) and c:IsSetCard(0x10f3) and c:IsType(TYPE_MONSTER) and c:IsFaceup()
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local sc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil):GetFirst()
	if not sc then return end
	if sc:IsLocation(LOCATION_GRAVE) then Duel.HintSelection(sc) end
	if Duel.SendtoHand(sc,nil,REASON_EFFECT)==0 or not sc:IsLocation(LOCATION_HAND) then return end
	if sc:IsPreviousLocation(LOCATION_DECK) then Duel.ConfirmCards(1-tp,sc) end
	Duel.ShuffleHand(tp)
	
	if not Duel.IsExistingMatchingCard(s.endymionfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) then return end
	local g=Duel.GetMatchingGroup(s.remfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	
	local total_field_counters=0
	local mc=g:GetFirst()
	while mc do
		total_field_counters = total_field_counters + mc:GetCounter(0x1041)
		mc=g:GetNext()
	end
	
	if total_field_counters==0 then return end
	
	local ng=Duel.GetMatchingGroup(Card.IsNegatable,tp,0,LOCATION_ONFIELD,nil)
	if #ng==0 or not Duel.SelectYesNo(tp,aux.Stringid(id,1)) then return end
	
	local max_ct=math.min(#ng, total_field_counters)
	local ct=max_ct==1 and 1 or Duel.AnnounceNumberRange(tp,1,max_ct)
	Duel.BreakEffect()
	
	local rem_count=0
	local rem_tc=g:GetFirst()
	while rem_tc and rem_count<ct do
		local current_counters=rem_tc:GetCounter(0x1041)
		if current_counters>0 then
			local to_remove=math.min(current_counters, ct-rem_count)
			rem_tc:RemoveCounter(tp,0x1041,to_remove,REASON_EFFECT)
			rem_count = rem_count + to_remove
		end
		rem_tc=g:GetNext()
	end
	
	if rem_count~=ct then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local sng=ng:Select(tp,ct,ct,nil)
	if #sng==ct then
		Duel.HintSelection(sng)
		sng:Match(Card.IsCanBeDisabledByEffect,nil,e)
		
		local tc=sng:GetFirst()
		while tc do
			if tc:IsCanBeDisabledByEffect(e) then
				tc:NegateEffects(e:GetHandler())
				Duel.AdjustInstantly()
				Duel.Destroy(tc,REASON_EFFECT)
			end
			tc=sng:GetNext()
		end
	end
end

-- =========================================================================
-- ---   MOTOR DEL EFECTO ② NUEVO: IMITACIÓN DE FUSIÓN EN CEMENTERIO   ---
-- =========================================================================
function s.copyfilter(c)
	-- Filtra Magias Normales/Juego Rápido del arquetipo Fusión/Polimerización (0x46) que estén en tu GY y sean desterrables
	return c:IsAbleToRemoveAsCost() and c:IsSetCard(0x46) and (c:IsNormalSpell() or c:IsQuickPlaySpell()) 
		and c:CheckActivateEffect(true,true,false)~=nil 
end

function s.copycost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- Exige que esta propia carta esté en la tumba y que exista otra Magia de Fusión legal para desterrar
	if chk==0 then return c:IsAbleToRemoveAsCost() 
		and Duel.IsExistingMatchingCard(s.copyfilter,tp,LOCATION_GRAVE,0,1,c) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.copyfilter,tp,LOCATION_GRAVE,0,1,1,c)
	g:AddCard(c) -- Junta tu Magia y la Fusión elegida en un solo saco de destierro
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	
	-- Captura y guarda de forma segura los punteros del efecto clonado (te)
	local te=g:GetFirst():IsCode(id) and g:GetNext():CheckActivateEffect(true,true,false) or g:GetFirst():CheckActivateEffect(true,true,false)
	e:SetLabelObject(te)
end

function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		local te=e:GetLabelObject()
		if not te then return false end
		local tg=te:GetTarget()
		return tg and tg(e,tp,eg,ep,ev,re,r,rp,0,chkc)
	end
	-- Sincroniza las condiciones de activación de los materiales con la interfaz del tablero antiguo
	if chk==0 then return true end
	local te=e:GetLabelObject()
	if te then
		e:SetLabel(te:GetLabel())
		local tg=te:GetTarget()
		if tg then tg(e,tp,eg,ep,ev,re,r,rp,1) end
		te:SetLabel(e:GetLabel())
		e:SetLabelObject(te)
	end
	Duel.ClearOperationInfo(0)
end

function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	-- Extrae el puntero del buffer estático de memoria RAM
	local te=e:GetLabelObject()
	if not te then return end
	
	-- Ejecuta la fusión física en el campo usando la Magia copiada
	local op=te:GetOperation()
	if op then 
		e:SetLabel(te:GetLabel())
		op(e,tp,eg,ep,ev,re,r,rp) 
		te:SetLabel(e:GetLabel())
	end
end
