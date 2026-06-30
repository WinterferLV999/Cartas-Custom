local s,id=GetID()
function s.initial_effect(c)
	-- Registro oficial de Skill Flip
	aux.AddSkillProcedure(c,1,false,s.flipcon,s.flipop,1)
	
	-- REGLA ① (EVENT_STARTUP): Registro de la restricción del Deck al arrancar
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_STARTUP)
	e1:SetRange(0x5f)
	e1:SetOperation(s.startop)
	c:RegisterEffect(e1)
end

s.listed_names={41209827,24094653}
s.listed_series={0x10f3}

function s.flipcon(e,tp,eg,ep,ev,re,r,rp)
	return aux.CanActivateSkill(tp)
end

-- --- 1. LÓGICA DE LA RESTRICCIÓN INICIAL CORREGIDA ---
function s.startop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SKILL_FLIP,tp,id|(1<<32))
	Duel.Hint(HINT_CARD,tp,id)
	
	-- CORREGIDO: Filtro nativo de alta compatibilidad para cores antiguos que reemplaza a GetBycode
	local ex=Duel.GetMatchingGroup(function(c) return c:IsCode(41209827) end,tp,LOCATION_EXTRA,0,nil)
	if #ex==0 then return end -- Si no tienes al dragón en el Extra Deck, aborta la skill
	
	-- Restricción al jugador: Solo Predaplant (0x10f3) en el Main Deck
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_CANNOT_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.sumlimit)
	Duel.RegisterEffect(e1,tp)
	
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	Duel.RegisterEffect(e2,tp)
end

function s.sumlimit(e,c,sump,sumtyp,sumpos,targetp,se)
	if (c:GetLocation()&LOCATION_EXTRA)~=0 then return false end
	return not c:IsSetCard(0x10f3)
end

-- --- 2. FILTROS DE BÚSQUEDA Y CONFIRMACIÓN ---
function s.prefilter(c)
	return (c:IsSetCard(0x10f3) or c:IsCode(24094653) or c:IsType(TYPE_SPELL) and c:IsSetCard(0x46))
end
function s.addfilter(c)
	return c:IsSetCard(0x10f3) and (c:IsAbleToHand() or c:IsLocation(LOCATION_GRAVE))
end

-- --- 3. OPERACIÓN DE ACTIVACIÓN MANUAL (EFECTOS ② Y ③) ---
function s.flipop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SKILL_FLIP,tp,id|(1<<32))
	Duel.Hint(HINT_CARD,tp,id)

	local opt=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))

	-- --- EFECTO ②: CONSISTENCIA DE FUSIÓN PREDAP ---
	if opt==0 then
		if Duel.GetFlagEffect(tp,id)>0 then return end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local g=Duel.SelectMatchingCard(tp,s.prefilter,tp,LOCATION_HAND,0,2,2,nil)
		if #g==2 then
			Duel.ConfirmCards(1-tp,g)
			
			local token=Duel.CreateToken(tp,24094653)
			Duel.SendtoHand(token,nil,REASON_RULE)
			Duel.ConfirmCards(1-tp,token)
			
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=Duel.SelectMatchingCard(tp,s.addfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
			if #sg>0 then
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
			Duel.RegisterFlagEffect(tp,id,0,0,1)
		end

	-- --- EFECTO ③: LLUVIA DE CONTADORES PREDATOR ---
	else
		if Duel.GetFlagEffect(tp,id+100)>0 then return end
		
		local p1=Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)
		local p2=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
		
		if p1==0 and p2>0 then
			local hg=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
			for tc in aux.Next(hg) do
				if tc:AddCounter(0x1041,1) then
					if not tc:IsType(TYPE_XYZ+TYPE_LINK) and tc:GetLevel()>=2 then
						local e1=Effect.CreateEffect(e:GetHandler())
						e1:SetType(EFFECT_TYPE_SINGLE)
						e1:SetCode(EFFECT_CHANGE_LEVEL)
						e1:SetReset(RESET_EVENT+RESETS_STANDARD)
						e1:SetCondition(function(e) return e:GetHandler():GetCounter(0x1041)>0 end)
						e1:SetValue(1)
						tc:RegisterEffect(e1)
					end
				end
			end
			Duel.RegisterFlagEffect(tp,id+100,0,0,1)
		end
	end
end
