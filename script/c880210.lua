local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	c:EnableCounterPermit(0x1041)
	Fusion.AddProcMixN(c,true,true,s.mfilter2,1,s.dark_filter,2)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.ctcon)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)   
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_COUNTER)
	 e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+200) -- Una vez por turno (HPTW) unificado
	e3:SetTarget(s.p_end_tg)
	e3:SetOperation(s.p_end_op)
	c:RegisterEffect(e3)
end

-- Habilita el Contador Predator (0x1041) nativamente en tu servidor antiguo
s.counter_list={0x1041}
s.counter_storage=0 -- Variable estática de almacenamiento seguro acumulativa
s.counted_cards={}  -- Tabla de memoria temporal para bloquear el bucle fantasma de C++

-- --- 1. CAPTURA Y SUMA DEL MATERIAL OBLIGATORIO CON CONTADOR ---
function s.mfilter2(c,fc,sumtype,tp)
	if c:GetCounter(0x1041)>0 and c:IsOnField() then
		local cid=c:GetCardID()
		-- LA CLAVE DEL EXITO: Solo suma si este monstruo fisico NO ha sido contado en este chequeo
		if not s.counted_cards[cid] then
			s.counted_cards[cid]=true
			s.counter_storage = s.counter_storage + c:GetCounter(0x1041)
		end
		return true
	end
	return false
end

-- --- 2. CAPTURA Y SUMA DE LOS MATERIALES DE OSCURIDAD SOBRANTES ---
function s.dark_filter(c,fc,sumtype,tp)
	if c:IsAttribute(ATTRIBUTE_DARK,fc,sumtype,tp) then
		if c:GetCounter(0x1041)>0 and c:IsOnField() then
			local cid=c:GetCardID()
			-- Aplica exactamente el mismo candado de ID para evitar duplicaciones por re-escaneo
			if not s.counted_cards[cid] then
				s.counted_cards[cid]=true
				s.counter_storage = s.counter_storage + c:GetCounter(0x1041)
			end
		end
		return true
	end
	return false
end

-- --- 3. LÓGICA DE INYECCIÓN REAL EN EL NACIMIENTO ---
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsFusionSummoned()
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local sum=s.counter_storage
		
		-- LIMPIEZA TOTAL DE MEMORIA RAM: Resetea la tabla y el acumulador para la siguiente jugada
		s.counter_storage=0 
		s.counted_cards={}  
		
		if sum>0 then
			c:AddCounter(0x1041,sum)
		end
	end
end
--Local No.2
-- --- 1. COSTO DINÁMICO SANEADO ---
local function adjzone(loc,seq)
	if loc==LOCATION_MZONE then
		if seq<5 then
			return ((7<<(seq-1))&0x1f)|(1<<(seq+8))
		else
			return (1<<seq)|(2+(6*(seq-5)))
		end
	else
		return ((7<<(seq+7))&0x1F00)|(1<<seq)
	end
end

-- --- 2. EXTRACCIÓN DE CARTAS EN LA INTERFAZ GRÁFICA DE LA COLUMNA ---
local function groupfrombit(bit,p)
	local loc=(bit&0x7F>0) and LOCATION_MZONE or LOCATION_SZONE
	local seq=(loc==LOCATION_MZONE) and bit or bit>>8
	
	local s_count=0
	while seq>1 do seq=seq>>1 s_count=s_count+1 end
	seq = s_count
	
	local g=Group.CreateGroup()
	local function optadd(l,s)
		local c=Duel.GetFieldCard(p,l,s)
		if c then g:AddCard(c) end
	end
	optadd(loc,seq)
	if seq<=4 then
		if seq+1<=4 then optadd(loc,seq+1) end
		if seq-1>=0 then optadd(loc,seq-1) end
	end
	if loc==LOCATION_MZONE then
		if seq<5 then
			optadd(LOCATION_SZONE,seq)
			if seq==1 then optadd(LOCATION_MZONE,5) end
			if seq==3 then optadd(LOCATION_MZONE,6) end
		elseif seq==5 then optadd(LOCATION_MZONE,1)
		elseif seq==6 then optadd(LOCATION_MZONE,3) end
	else
		optadd(LOCATION_MZONE,seq)
	end
	return g
end

function s.filter(c)
	return not c:IsLocation(LOCATION_FZONE) and not (Duel.IsDuelType(DUEL_SEPARATE_PZONE) and c:IsLocation(LOCATION_PZONE))
end

-- --- 3. PASO 1 (ACTIVACIÓN): SELECCIONA LA CASILLA ANTES DE REMOVER CONTADORES ---
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- El target ahora solo exige que tu dragón tenga al menos 1 contador para poder iniciar la puntería
	if chk==0 then return e:GetHandler():GetCounter(0x1041)>0 
		and Duel.IsExistingMatchingCard(s.filter,tp,0,LOCATION_ONFIELD,1,nil) end
		
	local g=Duel.GetMatchingGroup(s.filter,tp,0,LOCATION_ONFIELD,nil)
	local filter=0
	local tc=g:GetFirst()
	while tc do
		filter=filter|adjzone(tc:GetLocation(),tc:GetSequence())
		tc=g:GetNext()
	end
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,0))
	
	-- Tu plantilla intacta abre la cuadricula virtual azul al activar la carta en la cadena
	local zone=Duel.SelectFieldZone(tp,1,1-tp,LOCATION_ONFIELD,~filter<<16)
	Duel.Hint(HINT_ZONE,tp,zone)
	
	e:SetLabel(zone) -- Guarda la zona seleccionada de forma limpia
	local sg=groupfrombit(zone>>16,1-tp)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,sg,1,0,0)
end

-- --- 4. PASO 2 (RESOLUCIÓN): PREGUNTA CUÁNTOS REMOVER Y BOMBARDEA ---
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local zone=e:GetLabel() -- Jala la zona que elegiste en el paso anterior
	
	-- Si el dragón dejó el campo o perdió sus fichas antes de resolverse, aborta la jugada
	if not c:IsRelateToEffect(e) or c:GetCounter(0x1041)==0 then return end
	
	-- El radar busca qué cartas están paradas físicamente en esa cruz elegida del rival
	local g=groupfrombit(zone>>16,1-tp)
	if #g==0 then return end
	
	-- INTERFÁZ EXBLOWRER OFICIAL: Al resolverse el efecto, te pregunta cuántos contadores deseas pagar
	local max_ct=math.min(c:GetCounter(0x1041),#g)
	local count=Duel.AnnounceNumberRange(tp,1,max_ct)
	
	-- Remueve físicamente las fichas en plena resolución de la cadena
	c:RemoveCounter(tp,0x1041,count,REASON_EFFECT)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	-- Te obliga de forma estricta a marcar en la cruz el número de objetivos equivalente a lo que pagaste
	local sg=g:Select(tp,count,count,false)
	if #sg>0 then
		Duel.Destroy(sg,REASON_EFFECT)
	end
end
--Local No.3
-- --- 1. TARGET DE FIN DE FASE GLOBAL MÁSIVO ---
function s.p_end_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- El efecto se activa si hay al menos 1 monstruo boca arriba en el campo que tenga menos de 3 contadores
	if chk==0 then return Duel.IsExistingMatchingCard(function(tc) return tc:IsFaceup() and tc:GetCounter(0x1041)<4 end,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,g,1,0,0x1041)
end

-- --- 2. OPERACIÓN: LLUVIA DE VENENO CON CANDADO DE TOPE MATEMÁTICO ---
function s.p_end_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	
	for tc in aux.Next(g) do
		-- LA CLAVE DEL TOPE (< 3): Sincronizado con tu referencia de cadenas.
		-- El script solo inyectará veneno si el monstruo tiene menos de 3 Contadores Predator (0x1041).
		if tc:GetCounter(0x1041)<4 then
			if tc:AddCounter(0x1041,1) then
				-- Si la víctima es Nivel 2 o mayor (y no es Xyz/Link), le encoge las estrellas a Nivel 1 de forma continua
				if not tc:IsType(TYPE_XYZ+TYPE_LINK) and tc:GetLevel()>1 then
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_CHANGE_LEVEL)
					e1:SetValue(1)
					e1:SetCondition(s.lv_check_con)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					tc:RegisterEffect(e1)
				end
			end
		end
	end
end

-- --- 3. CONDICIÓN CONTINUA DEL NIVEL 1 ---
function s.lv_check_con(e)
	-- El encogimiento a Nivel 1 dura única y estrictamente mientras el monstruo conserve el Contador Predator (0x1041)
	return e:GetHandler():GetCounter(0x1041)>0
end