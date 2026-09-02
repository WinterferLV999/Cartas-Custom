local s,id=GetID()
function s.initial_effect(c)
	-- Habilita de forma nativa la Invocación y las mecánicas de Péndulo en el Core clásico
	Pendulum.AddProcedure(c)
	
	-- EFFECT ①: BOTÓN DE DESPLAZAMIENTO EN CADENA CONDICIONAL (PÉNDULO)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.pctg)
	e1:SetOperation(s.pcop)
	c:RegisterEffect(e1)
	
	-- EFFECT ②: INVOCACIÓN DE EMERGENCIA DE RELEVOS (MONSTRUO)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

s.listed_names={96227613} 
s.listed_series={SET_SUPREME_KING_GATE, SET_SUPREME_KING_DRAGON}

-- =========================================================================
-- --- RESOLUCIÓN LOGICA DEL EFECTO DE PÉNDULO (COMPLETAMENTE ESTABLE)    ---
-- =========================================================================
function s.pcfilter(c)
	-- Filtra monstruos Péndulo de la familia Supreme King Gate que no estén prohibidos
	if c:IsLocation(LOCATION_EXTRA) and c:IsFacedown() then return false end
	
	-- REPARADO DEFINITIVO: La directiva 'and not c:IsCode(id)' EXPULSA a este monstruo
	-- de las opciones jugables, impidiendo que el sistema te deje seleccionarlo o desplazarlo.
	return c:IsSetCard(SET_SUPREME_KING_GATE) and c:IsType(TYPE_PENDULUM) 
		and not c:IsForbidden() and not c:IsCode(id)
end

function s.pctg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Habilita el botón interactivo en azul brillante si hay zonas libres y blancos válidos en las 4 zonas
	if chk==0 then return Duel.CheckPendulumZones(tp)
		and Duel.IsExistingMatchingCard(s.pcfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA,0,1,nil) end
end

function s.pcop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Si la carta dejó la Zona de Péndulo antes de la resolución, detiene la operación por seguridad
	if not c:IsRelateToEffect(e) or not Duel.CheckPendulumZones(tp) then return end
	local my_seq=c:GetSequence()
	
	-- 🚀 DESPLAZAMIENTO 1: Seleccionamos el primer Gate desde tu Mano, Deck, GY o Extra Deck boca arriba (Excluyendo esta carta)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.pcfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA,0,1,1,nil)
	local tc=g:GetFirst()
	
	if tc then
		-- Capturamos la ID exacta en la caché inmune antes de alterar su estado físico
		local card_code=tc:GetCode()
		
		-- Mueve la carta seleccionada directamente a tu Zona de Péndulo vacía
		if Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true) then
			
			-- --- EL INYECTOR DE NEGACIÓN EN LA RANURA MÁGICA ---
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
			
			-- =========================================================================
			-- --- RELEVOS DE HARDWARE: BUCLE CONDICIONAL POR COORDENADA DE CASILLA   ---
			-- =========================================================================
			-- Si el código de caché coincide con Gate Zero (96227613), abre el menú interactivo
			if card_code==96227613 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
				
				-- Localiza físicamente la ranura por su secuencia original (my_seq)
				local dc=Duel.GetFieldCard(tp,LOCATION_PZONE,my_seq)
				
				-- Revienta la carta de la Habilidad liberando la casilla al instante en la RAM
				if dc and Duel.Destroy(dc,REASON_EFFECT)>0 then
					
					-- 🚀 DESPLAZAMIENTO 2: Trae el segundo Gate desde cualquiera de las 4 zonas expandidas (Excluyendo esta carta)
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
					local g2=Duel.SelectMatchingCard(tp,s.pcfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA,0,1,1,nil)
					local tc2=g2:GetFirst()
					
					if tc2 then
						if Duel.MoveToField(tc2,tp,tp,LOCATION_PZONE,POS_FACEUP,true) then
							-- También le clavamos la supresión de efectos al segundo monstruo hasta la End Phase
							local e3=Effect.CreateEffect(c)
							e3:SetType(EFFECT_TYPE_SINGLE)
							e3:SetCode(EFFECT_DISABLE)
							e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
							tc2:RegisterEffect(e3)
							
							local e4=Effect.CreateEffect(c)
							e4:SetType(EFFECT_TYPE_SINGLE)
							e4:SetCode(EFFECT_DISABLE_EFFECT)
							e4:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
							tc2:RegisterEffect(e4)
						end
					end
				end
			end
			
		end
	end
end

-- =========================================================================
-- --- RESOLUCIÓN LOGICA DEL EFECTO DE MONSTRUO (BLINDAJE DE PARÁMETROS)  ---
-- =========================================================================
function s.spfilter(c,e,tp)
	if c:IsLocation(LOCATION_EXTRA) and c:IsFacedown() then return false end
	return c:IsSetCard(SET_SUPREME_KING_DRAGON) and c:IsLevel(4) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- REPARADO DEFINITIVO BEYOND PARAMETERS: Limpiamos por completo las funciones IsXyzSummonable
-- e IsSynchroSummonable que causaban el crash de tipo de datos en tu línea 104.
-- El filtro ahora valida pasivamente la identidad de los jefes en tu Extra Deck.
function s.exfilter(c,e,tp)
	if not (c:IsSetCard(SET_SUPREME_KING_DRAGON) and c:IsLocation(LOCATION_EXTRA)) then return false end
	-- Da luz verde de forma pasiva a cualquier Fusión, Sincronía o Xyz del arquetipo
	return c:IsType(TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsReleasable()
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_RELEASE,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsReleasable() then return end
	
	if Duel.Release(c,REASON_EFFECT)==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA+LOCATION_GRAVE,0,1,1,nil,e,tp)
	
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		local sg=Duel.GetMatchingGroup(s.exfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
		if #sg==0 or not Duel.SelectYesNo(tp,aux.Stringid(id,2)) then return end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=sg:Select(tp,1,1,nil):GetFirst()
		if not sc then return end
		
		Duel.BreakEffect()
		
		if sc:IsType(TYPE_FUSION) then
			-- Ejecución limpia de fusión procedural para servidores de la vieja escuela
			local fgroup=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_MZONE,0,nil,sc)
			if #fgroup>0 then
				local sg2=Duel.SelectMatchingCard(tp,Card.IsCanBeFusionMaterial,tp,LOCATION_MZONE,0,1,99,nil,sc)
				if #sg2>0 then
					Duel.SetFusionMaterial(sg2)
					Duel.SendtoGrave(sg2,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
					Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
					sc:CompleteProcedure()
				end
			end
		elseif sc:IsType(TYPE_SYNCHRO) then
			-- Invoca de forma Sincronía interactiva abriendo el menú nativo del Extra Deck
			Duel.SynchroSummon(tp,sc)
		elseif sc:IsType(TYPE_XYZ) then
			-- Invoca de forma Xyz acoplando tus materiales de campo abajo del monstruo elegido
			Duel.XyzSummon(tp,sc)
		end
	end
end
