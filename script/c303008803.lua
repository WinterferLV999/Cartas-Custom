local s,id=GetID()
function s.initial_effect(c)
	-- EL CANAL OFICIAL REPARADO: Activa la Skill de forma nativa en tu emulador clásico sin congelarse
	aux.AddSkillProcedure(c,1,false,s.flipcon,s.flipop,1)
	
	-- REGLA ① (EVENT_STARTUP): Modificación del Extra Deck al arrancar el duelo
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_STARTUP)
	e1:SetRange(0x5f)
	e1:SetOperation(s.startop)
	c:RegisterEffect(e1)
end

-- Lista de IDs de los 6 Dragones del Extra Deck estables
s.listed_names={73580471,70902743,25862681,44508094,25165047,9012916} 

-- La Skill manual enciende el botón en azul brillante al iniciar si tienes la pieza en mano
function s.flipcon(e,tp,eg,ep,ev,re,r,rp)
	return aux.CanActivateSkill(tp) and Duel.GetFlagEffect(tp,id+2000)==0
		and Duel.IsExistingMatchingCard(s.stardust_filter,tp,0x2,0,1,nil) -- 0x2 = mano
end

-- --- 1. REGLA ①: INSERCIÓN AL Extra DECK CON TRUCO DE REDIRECCIÓN CLÁSICA ---
function s.startop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e_list={73580471,70902743,25862681,25165047,9012916}
	for _,code in ipairs(e_list) do
		local token=Duel.CreateToken(tp,code)
		if token then
			Duel.SendtoHand(token,nil,REASON_RULE)
		end
	end
	
	-- Restricción estricta de Invocación de Yusei Fudo intacta
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
	
	-- =========================================================================
	-- --- INYECCIÓN DE LA SKILL: ACTIVAR CONVERGING WISHES DESDE LA MANO ---
	-- =========================================================================
	-- ID de Converging Wishes Oficial de Konami: 14094653 (Ajusta si usas otra ID personalizada)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e3:SetTargetRange(LOCATION_HAND,0)
	e3:SetTarget(function(e,tc) return tc:IsCode(20007374) end)
	Duel.RegisterEffect(e3,tp)
end

function s.sumlimit(e,c,sump,sumtyp,sumpos,targetp,se)
	if c:IsType(0x1000) then return false end -- 0x1000 = TYPE_TUNER
	if c:IsType(0x2000) and (c:IsRace(RACE_DRAGON) or c:IsRace(RACE_WARRIOR)) then return false end -- 0x2000 = TYPE_SYNCHRO
	if c:IsSetCard(0x43) or c:IsSetCard(0xa3) then return false end
	return true 
end

-- =========================================================================
-- --- FILTROS DE FASE DE EMULACIÓN COMPLETAMENTE INTEGRADOS ---
-- =========================================================================
function s.stardust_filter(c)
	return c:IsMonster() and ((c:IsSetCard(0xa3) and c:GetLevel()<=4) or c:IsCode(75874514))
end
function s.deck_stardust_filter(c)
	return c:IsMonster() and c:IsSetCard(0xa3) and c:GetLevel()==4
end
function s.tuner_filter(c)
	return c:IsMonster() and c:IsType(0x1000)
end

-- =========================================================================
-- --- 2. OPERACIÓN MANUAL DEL EFECTO ② (BOTÓN DE CONSISTENCIA) ---
-- =========================================================================
function s.flipop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SKILL_FLIP,tp,id)
	Duel.Hint(HINT_CARD,tp,id)
	Duel.RegisterFlagEffect(tp,id+2000,RESET_PHASE+PHASE_END,0,1) -- Consume la consistencia manual
	
	-- PASO A: Intercambio de 2 cartas de la mano al mazo
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g1=Duel.SelectMatchingCard(tp,s.stardust_filter,tp,0x2,0,1,1,nil)
	if #g1==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g2=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,0x2,0,1,1,g1:GetFirst())
	g1:Merge(g2)
	
	if Duel.SendtoDeck(g1,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==0 then return end
	Duel.ShuffleDeck(tp)
	
	-- PASO B: Invoca 2 monstruos "Stardust" de Nivel 4 directamente del Deck al campo
	if Duel.GetLocationCount(tp,0x4)>=2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local sg=Duel.SelectMatchingCard(tp,s.deck_stardust_filter,tp,0x1,0,2,2,nil)
		if #sg==2 then
			local tc=sg:GetFirst()
			while tc do
				Duel.MoveToField(tc,tp,tp,0x4,POS_FACEUP,true)
				tc=sg:GetNext()
			end
		end
	end
	
	-- PASO C (Método Honey Trap): Teclado flotante por nombres para mandar 2 monstruos genéricos al GY
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CODE)
	local monster_announce_filter={0x1,OPCODE_ISTYPE,0x8000000,OPCODE_ISTYPE,OPCODE_NOT,OPCODE_AND,0x10000000,OPCODE_ISTYPE,OPCODE_NOT,OPCODE_AND}
	
	local ac1=Duel.AnnounceCard(tp,table.unpack(monster_announce_filter))
	local token_grave1=Duel.CreateToken(tp,ac1)
	if token_grave1 then Duel.SendtoGrave(token_grave1,REASON_EFFECT) end
	
	local ac2=Duel.AnnounceCard(tp,table.unpack(monster_announce_filter))
	local token_grave2=Duel.CreateToken(tp,ac2)
	if token_grave2 then Duel.SendtoGrave(token_grave2,REASON_EFFECT) end
	
	-- PASO D: Busca 1 Tuner de tu mazo para añadirlo a tu mano
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local th=Duel.SelectMatchingCard(tp,s.tuner_filter,tp,0x1,0,1,1,nil)
	if th and #th > 0 then
		Duel.SendtoHand(th,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,th)
	end
	
	-- PASO E: Añade a "Shooting Star" (ID: 47264717) desde fuera del mazo a tu mano
	local token_spell=Duel.CreateToken(tp,47264717) 
	if token_spell then
		Duel.SendtoHand(token_spell,nil,REASON_RULE)
		Duel.ConfirmCards(1-tp,token_spell)
	end
	
	-- =========================================================================
	-- --- EL RADAR LAST WILL: INYECCIÓN DE LA LEY FLOTANTE DE ASALTO ---
	-- =========================================================================
	-- Se pausa el efecto un milisegundo e inyectamos el radar directamente al jugador (tp).
	-- Al cerrarse la Skill, el core ejecutará esta ley de forma libre obligando a parpadear la pregunta.
	Duel.BreakEffect()
	
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,1)) -- Mensaje: "¿Desatar Convergencia de Signatarios?"
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1)
	e1:SetCondition(s.signercon)
	e1:SetOperation(s.signerop)
	e1:SetReset(RESET_PHASE+PHASE_END) -- El radar caduca al terminar el turno
	Duel.RegisterEffect(e1,tp)
end

-- =========================================================================
-- --- 3. RESOLUCIÓN DE LA LEY FLOTANTE (EL CUADRO DE DIÁLOGO DE TU IMAGEN) ---
-- =========================================================================
function s.signercon(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetTurnPlayer()~=tp or (Duel.GetCurrentPhase()~=PHASE_MAIN1 and Duel.GetCurrentPhase()~=PHASE_MAIN2) then return false end
	if Duel.GetFlagEffect(tp,id+3000)>0 then return false end
	
	-- Condición oficial de Crimson Dragon (63436931) boca arriba o monstruos del rival
	local c_dragon=Duel.IsExistingMatchingCard(function(c) return c:IsCode(63436931) and c:IsFaceup() end,tp,0x4,0,1,nil)
	local op_check=Duel.GetFieldGroupCount(tp,0,0x4)>0
	return c_dragon or op_check
end

function s.signerop(e,tp,eg,ep,ev,re,r,rp)
	-- GENERA LA ANIMACIÓN EXACTA DE TU FOTO: Lanza el cuadro flotante interactivo parpadeando en la pantalla
	if not Duel.SelectYesNo(tp,aux.Stringid(id,1)) then return end
	
	Duel.RegisterFlagEffect(tp,id+3000,RESET_PHASE+PHASE_END,0,1) -- Consume la habilidad por este turno
	Duel.Hint(HINT_CARD,tp,id)
	
	-- Carga los 6 monstruos Signatarios de tu base de datos real
	local signers={73580471,70902743,25862681,25165047,9012916}
	local g=Group.CreateGroup()
	for _,code in ipairs(signers) do
		local token_drag=Duel.CreateToken(tp,code)
		if token_drag then g:AddCard(token_drag) end
	end
	
	-- SELECCIÓN VISUAL NATIVA: Abre el recuadro interactivo mostrando las 6 ilustraciones juntas
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=g:Select(tp,3,3,nil)
	
	if #sg==3 then
		local play_count=0
		local tc=sg:GetFirst()
		while tc do
			if play_count < 3 and Duel.GetLocationCount(tp,0x4)>0 then
				Duel.MoveToField(tc,tp,tp,0x4,POS_FACEUP,true)
				
				-- CANDADO DE ENCOGIMIENTO DE ESTRELLAS (Nivel 2 continuo si no es Tuner)
				if not tc:IsType(0x1000) then
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_CHANGE_LEVEL)
					e1:SetValue(2)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					tc:RegisterEffect(e1)
				end
				play_count = play_count + 1
			else
				Duel.SendtoGrave(tc,REASON_EFFECT)
			end
			tc=sg:GetNext()
		end
		
		-- Tritura los 3 dragones sobrantes que no elegiste al cementerio
		g:Sub(sg)
		if #g>0 then
			g:ForEach(function(gc) Duel.SendtoGrave(gc,REASON_EFFECT) end)
		end
	end
end
