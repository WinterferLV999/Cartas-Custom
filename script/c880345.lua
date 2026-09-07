-- =========================================================================
-- --- SCRIPT COMPLETA: MAGIA CONTINUA SUPREME KING GATE (CONVERGENCE)   ---
-- =========================================================================
local s,id=GetID()
function s.initial_effect(c)
	-- ACTUACIÓN E INICIALIZACIÓN: Activación base de la Magia Continua
	-- Requiere estrictamente controlar a Supreme King Z-ARC (13331639) boca arriba.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.actcon)
	c:RegisterEffect(e1)
	
	-- EFFECT ②: INVOCACIÓN MASIVA Y MODIFICACIÓN DE NIVEL DESDE LAS 4 ZONAS
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1) 
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- EFFECT ③: INVOCACIÓN HÍBRIDA SIN CADENA (CONTINUA / ACCIÓN DIRECTa)
	local e3=Effect.CreateEffect(c)
	--e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_ADJUST) -- Evento de Ajuste Permanente: Escanea el campo de forma pasiva en mundo abierto
	e3:SetRange(LOCATION_SZONE)
	e3:SetCondition(s.excon)
	e3:SetOperation(s.exop)
	c:RegisterEffect(e3)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCondition(s.excon)
	e4:SetOperation(s.exop)
	c:RegisterEffect(e4)
	--If "Z-arc" is not on the field, destroy this card
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetCode(EFFECT_SELF_DESTROY)
	e5:SetRange(LOCATION_SZONE)
	e5:SetCondition(s.descon2)
	c:RegisterEffect(e5)
end

function s.scfilter(c)
	return c:IsCode(13331639)
end
function s.descon2(e)
	return not Duel.IsExistingMatchingCard(s.scfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,e:GetHandler())
end
-- Mapeamos las series e IDs de fábrica requeridas
s.listed_names={13331639}
s.listed_series={SET_SUPREME_KING, SET_SUPREME_KING_DRAGON}

-- Aduana de Activación Física de la Magia Continua en Mesa
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,13331639),tp,LOCATION_MZONE,0,1,nil)
end

-- =========================================================================
-- --- FILTROS PARA EFECTO ② (INVOCACIÓN MASIVA)                         ---
-- =========================================================================
function s.chkfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_SUPREME_KING_DRAGON)
end

function s.spfilter(c,e,tp)
	--if c:IsLocation(LOCATION_EXTRA) and c:IsFacedown() then return false end
	return c:IsSetCard(SET_SUPREME_KING_DRAGON) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(s.chkfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if ft>2 then ft=2 end
	
	if Duel.IsExistingMatchingCard(s.chkfilter,tp,LOCATION_MZONE,0,1,nil) then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA,0,1,ft,nil,e,tp)
	
	if #g>0 then
		local tc=g:GetFirst()
		local spg=Group.CreateGroup()
		
		while tc do
			if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
				spg:AddCard(tc)
				
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DISABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
				
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_DISABLE_EFFECT)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e2)
				
				local e3=Effect.CreateEffect(c)
				e3:SetType(EFFECT_TYPE_SINGLE)
				e3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
				e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e3:SetValue(ATTRIBUTE_DARK)
				e3:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e3)
			end
			tc=g:GetNext()
		end
		
		Duel.SpecialSummonComplete()
		
		spg:KeepAlive()
		if #spg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
			local sc=spg:Select(tp,1,1,nil):GetFirst()
			
			if sc then
				local lv=Duel.AnnounceNumber(tp,1,2,3,4,5,6,7,8,9,10,11,12)
				local e4=Effect.CreateEffect(c)
				e4:SetType(EFFECT_TYPE_SINGLE)
				e4:SetCode(EFFECT_CHANGE_LEVEL)
				e4:SetValue(lv)
				e4:SetReset(RESET_EVENT+RESETS_STANDARD)
				sc:RegisterEffect(e4)
			end
		end
	end
end

-- =========================================================================
-- --- FILTROS Y LÓGICA DE EXTRA DECK CONTINUA SIN CADENA (EFECTO ③)      ---
-- =========================================================================
function s.fusfilter(c,e,tp,mg)
	return (c:IsSetCard(SET_SUPREME_KING) or c:IsSetCard(SET_SUPREME_KING_DRAGON)) 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial(mg,nil,tp)
end

function s.syncfilter(c,mg)
	-- Valida de forma estricta en el motor C++ si el monstruo se puede invocar por Sincronía usando el grupo 'mg'
	return (c:IsSetCard(SET_SUPREME_KING) or c:IsSetCard(SET_SUPREME_KING_DRAGON)) and c:IsSynchroSummonable(nil,mg)
end

function s.xyzfilter(c,mg)
	-- Valida de forma estricta en el motor C++ si el monstruo se puede invocar por Xyz usando el grupo 'mg'
	return (c:IsSetCard(SET_SUPREME_KING) or c:IsSetCard(SET_SUPREME_KING_DRAGON)) and c:IsXyzSummonable(nil,mg)
end

function s.excon(e,tp,eg,ep,ev,re,r,rp)
	-- Condición de mundo abierto: Funciona en las Main Phases de cualquier jugador con la cadena vacía (Chain 0)
	local c=e:GetHandler()
	local ph=Duel.GetCurrentPhase()
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	return (ph==PHASE_MAIN1 or ph==PHASE_MAIN2) and Duel.GetCurrentChain()==0
		and c:GetFlagEffect(id)==0
		and (Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
			or Duel.IsExistingMatchingCard(s.syncfilter,tp,LOCATION_EXTRA,0,1,nil,mg)
			or Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,mg))
end

-- =========================================================================
-- ---   EJECUCIÓN POR REGLA CONTINUA (VERIFICACIÓN DE MATERIALES LEGALES) ---
-- =========================================================================
function s.exop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local b1=Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
	local b2=Duel.IsExistingMatchingCard(s.syncfilter,tp,LOCATION_EXTRA,0,1,nil,mg)
	local b3=Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,mg)
	
	local ops={}
	local opval={}
	if b1 then table.insert(ops,aux.Stringid(id,3)); table.insert(opval,1) end
	if b2 then table.insert(ops,aux.Stringid(id,4)); table.insert(opval,2) end
	if b3 then table.insert(ops,aux.Stringid(id,5)); table.insert(opval,3) end
	
	if #ops==0 then return end
	
	-- Ventana interactiva de decisión directa (Sin eslabón de cadena)
	if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		-- Candado de una vez por turno inmediato en este turno activo
		c:RegisterFlagEffect(id,RESET_PHASE+PHASE_END,0,1)
		
		local op=Duel.SelectOption(tp,table.unpack(ops))+1
		local sel=opval[op]
		
		-- Deshabilita de golpe las respuestas rápidas del rival (Invocación por regla sin cadena)
		Duel.SetChainLimit(aux.FALSE)
		
		if sel==1 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local tc=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg):GetFirst()
			if tc then
				local fud=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
				tc:SetMaterial(fud)
				Duel.SendtoGrave(fud,REASON_MATERIAL+REASON_FUSION)	
				Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
				tc:CompleteProcedure()
			end
		elseif sel==2 then
			-- REPARADO: Llama al procedimiento oficial que obliga a cumplir la receta de Sincronía (Tuner + No-Tuner y Niveles exactos)
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local g=Duel.GetMatchingGroup(s.syncfilter,tp,LOCATION_EXTRA,0,nil,mg)
			if #g>0 then
				local tc=g:Select(tp,1,1,nil):GetFirst()
				Duel.SynchroSummon(tp,tc,nil,mg)
			end
		elseif sel==3 then
			-- REPARADO: Llama al procedimiento oficial que obliga a cumplir la receta Xyz (Rangos y Materiales acoplados debajo)
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local g=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,mg)
			if #g>0 then
				local tc=g:Select(tp,1,1,nil):GetFirst()
				Duel.XyzSummon(tp,tc,nil,mg)
			end
		end
	else
		-- Bandera de pausa corta para evitar que la ventana emergente trabe la pantalla en el mismo frame de juego libre
		c:RegisterFlagEffect(id,RESET_CHAIN,0,1)
	end
end