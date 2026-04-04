local s,id=GetID()

function s.initial_effect(c)
	-- Registro de Skill Flip (Manual)
	aux.AddSkillProcedure(c,1,false,s.flipcon,s.flipop,1)
	
	-- 1: Animación de volteo inicial y registro de restricciones
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_STARTUP)
	e1:SetRange(0x5f)
	e1:SetOperation(s.startop)
	c:RegisterEffect(e1)
end

-- Función que se activa al empezar: Voltea la carta y ACTIVA EL BLOQUEO
function s.startop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SKILL_FLIP,tp,id|(1<<32))
	Duel.Hint(HINT_CARD,tp,id)
	
	-- RESTRICCIÓN GLOBAL (Se registra al jugador directamente)
	-- Solo Divine-Beast (0x4000000), Aqua (0x40) y Extra Deck
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_CANNOT_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	Duel.RegisterEffect(e1,tp)
	
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	Duel.RegisterEffect(e2,tp)
end

-- Lógica de la restricción: Bloquea si NO es Divine-Beast, Aqua o del Extra Deck
function s.splimit(e,c,sump,sumtyp,sumpos,targetp,se)
	return not (c:IsRace(RACE_DIVINE|RACE_AQUA) or c:IsLocation(LOCATION_EXTRA))
end

function s.flipcon(e,tp,eg,ep,ev,re,r,rp)
	return aux.CanActivateSkill(tp) 
end

function s.flipop(e,tp,eg,ep,ev,re,r,rp)
	-- Animación visual al activar
	Duel.Hint(HINT_SKILL_FLIP,tp,id|(1<<32))
	Duel.Hint(HINT_CARD,tp,id)

	local opt=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))

	-- --- EFECTO 2: GUARDIAN SLIME ---
	if opt==0 then
		if Duel.GetFlagEffect(tp,id)>0 then 
			Debug.Message("Efecto usado este turno.")
			return 
		end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local g=Duel.SelectMatchingCard(tp,function(c) return c:IsCode(10000010,10000080,10000090) end,tp,LOCATION_HAND,0,1,1,nil)
		
		if #g>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.ConfirmCards(1-tp,g)
			local sg=Duel.SelectMatchingCard(tp,Card.IsCode,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,15771991)
			local sc=sg:GetFirst()
			if sc then
				if Duel.SpecialSummonStep(sc,0,tp,tp,true,false,POS_FACEUP) then
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_DISABLE)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					sc:RegisterEffect(e1)
				end
				Duel.SpecialSummonComplete()
				Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
			end
		end

	-- --- EFECTO 3: LP Y MONSTER REBORN ---
	else
		if Duel.GetFlagEffect(tp,id+100)>0 then return end
		Duel.RegisterFlagEffect(tp,id+100,0,0,1)
		Duel.SetLP(tp,4100)
		local reborn=Duel.CreateToken(tp,83764718)
		Duel.SendtoHand(reborn,nil,REASON_RULE)
		Duel.ConfirmCards(1-tp,reborn)
		
		if Duel.GetFieldGroupCount(tp,LOCATION_ONFIELD,0)==0 then
			local g2=Duel.SelectMatchingCard(tp,function(c) return c:IsCode(10000010) or c:ListsCode(10000010) end,tp,LOCATION_DECK,0,1,1,nil)
			if #g2>0 then Duel.SendtoHand(g2,nil,REASON_EFFECT) Duel.ConfirmCards(1-tp,g2) end
		end
	end
end