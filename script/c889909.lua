local s,id=GetID()
function s.initial_effect(c)
	-- Activación de la Magia Rápida (0x10000 = TYPE_QUICKPLAY)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) -- Solo puedes activar 1 "Forbidden Water" por turno
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- VELOCIDAD DE RESPUESTA SANEADA: El oponente NO puede activar cartas o efectos en respuesta
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_SZONE)
	e2:SetOperation(s.chainop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_FORBIDDEN}

function s.copy_filter(c)
	return c:IsType(0x10000) and c:IsSetCard(SET_FORBIDDEN) and not c:IsCode(id) and c:IsAbleToRemoveAsCost()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.copy_filter,tp,LOCATION_HAND+LOCATION_GRAVE,LOCATION_GRAVE,1,nil) end
	
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_GRAVE)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	-- Despliega el menú de selección leyendo tu Mano/GY (Argumento 3) y el GY del rival (Argumento 4)
	local g=Duel.SelectMatchingCard(tp,s.copy_filter,tp,LOCATION_HAND+LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil)
	
	if #g>0 and Duel.Remove(g,POS_FACEUP,REASON_EFFECT)>0 then
		local tc=g:GetFirst()
		
		-- Extraemos directamente la función de operación en crudo del bloque de memoria de la carta desterrada
		local te=tc:GetActivateEffect()
		if not te then return end
		
		local op=te:GetOperation()
		if op then
			op(e,tp,eg,ep,ev,re,r,rp)
		end
	end
end
function s.chainop(e,tp,eg,ep,ev,re,r,rp)
	if re:GetHandler()==e:GetHandler() then
		Duel.SetChainLimit(function(e,ep,tp) return ep==tp end)
	end
end