local s,id=GetID()
function s.initial_effect(c)
	-- Activación de Skill (Voltear carta)
	aux.AddSkillProcedure(c,1,false,s.flipcon,s.flipop,1)
end

-- Filtro para el monstruo que vas a tributar (Código 10000080)
function s.costfilter(c)
	return c:IsCode(10000080)
end

-- Filtro para Ra en Cementerio o Destierro
function s.spfilter(c,e,tp)
	return c:IsCode(CARD_RA) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.flipcon(e,tp,eg,ep,ev,re,r,rp)
	-- Restricción: Una vez por turno
	if Duel.GetFlagEffect(tp,id)>0 then return end
	
	return aux.CanActivateSkill(tp) 
		and Duel.CheckReleaseGroupCost(tp,s.costfilter,1,false,nil,nil)
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)
end

function s.flipop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SKILL_FLIP,tp,id|(1<<32))
	Duel.Hint(HINT_CARD,tp,id)
	
	-- Registrar uso por turno
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	
	-- 1. Sacrificar el monstruo 10000080 (Modo Esfera)
	local sg=Duel.SelectReleaseGroupCost(tp,s.costfilter,1,1,false,nil,nil)
	if Duel.Release(sg,REASON_COST)>0 then
		-- 2. Invocar a Ra
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp):GetFirst()
		
		-- El truco del SpecialSummonStep para evitar errores con el Fénix
		if tc and Duel.SpecialSummonStep(tc,0,tp,tp,true,true,POS_FACEUP) then
			Duel.SpecialSummonComplete()
			
			-- 3. EFECTO DE PERSISTENCIA: Se enviará al cementerio al final de CUALQUIER turno
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e1:SetCode(EVENT_PHASE+PHASE_END)
			e1:SetCountLimit(1)
			e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE) -- Ignora la inmunidad de Ra
			e1:SetLabelObject(tc)
			e1:SetCondition(s.selfdescon)
			e1:SetOperation(s.selfdesop)
			Duel.RegisterEffect(e1,tp)
		end
	end
end

-- Condición: Solo si Ra sigue en el campo
function s.selfdescon(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	return tc:IsLocation(LOCATION_MZONE)
end

-- Operación: Mandarlo al cementerio y resetear el efecto
function s.selfdesop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	Duel.SendtoGrave(tc,REASON_RULE)
	e:Reset() -- El efecto se borra una vez que Ra es enviado al cementerio
end