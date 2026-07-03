local s,id=GetID()
function s.initial_effect(c)
	-- El monstruo debe cumplir sus condiciones de Extra Deck para poder revivir
	c:EnableReviveLimit()
	c:EnableCounterPermit(0x1041)
	
	-- INVOCACIÓN DE FUSIÓN NATIVA INTÁCTA (Tu base de 24 líneas exitosa de fábrica)
	Fusion.AddProcMixN(c,true,true,s.mfilter2,1,s.dark_filter,2)
	
	-- EFECTO ①: Traspaso del Total de Contadores de Materiales (Tu Plantilla de Éxito)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.ctcon)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)
	
	-- EL RADAR DE INTERCEPTACIÓN OFICIAL: Graba el veneno en vivo durante los clics del pago
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_MATERIAL_CHECK)
	e2:SetValue(s.valcheck)
	e2:SetLabelObject(e1)
	c:RegisterEffect(e2)
	
	-- EFECTO ②: Bombardeo Temático por Selección de Zona estilo Exblowrer (Ignición)
	local e2_bomb=Effect.CreateEffect(c)
	e2_bomb:SetDescription(aux.Stringid(id,1))
	e2_bomb:SetCategory(CATEGORY_DESTROY)
	e2_bomb:SetType(EFFECT_TYPE_IGNITION)
	e2_bomb:SetRange(LOCATION_MZONE)
	e2_bomb:SetCountLimit(1,id+100)
	e2_bomb:SetTarget(s.destg)
	e2_bomb:SetOperation(s.desop)
	c:RegisterEffect(e2_bomb)
	
	-- EFECTO ③: Lluvia Masiva de Veneno en la Fase Final con tope máximo de 3 por monstruo (Obligatorio)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_COUNTER)
	e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+200)
	e3:SetTarget(s.p_end_tg)
	e3:SetOperation(s.p_end_op)
	c:RegisterEffect(e3)
end

-- Habilita el Contador Predator (0x1041) nativamente en tu servidor antiguo
s.counter_list={0x1041}

-- --- 1. FILTROS DE TU BASE DE FUSIÓN EXITOSA ---
function s.mfilter2(c,fc,sumtype,tp)
	return c:GetCounter(0x1041)>0 and c:IsOnField()
end

function s.dark_filter(c,fc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_DARK,fc,sumtype,tp)
end

-- --- 2. EL MOTOR DE AUDITORÍA SIN CRASHEOS DE TU PLANTILLA DE ÉXITO ---
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.valcheck(e,c)
	-- Captura las piezas exactas que estás clickeando en el campo
	local mg=c:GetMaterial()
	-- ARITMÉTICA INTEGRADA: Suma de forma milimétrica cuántos contadores portaban en sus mapas de bits
	local sum=mg:GetSum(function(mc) return mc:GetCounter(0x1041) end)
	-- Le estampa la cifra grabada directamente al eslabón e1
	e:GetLabelObject():SetLabel(sum)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Jala de forma segura el número exacto del coste sin tocar variables globales
	local ct=e:GetLabel()
	if not (c:IsRelateToEffect(e) and c:IsFaceup() and ct>0) then return end
	-- Inyecta el veneno absorbido real
	c:AddCounter(0x1041,ct)
end

-- --- 3. MOTOR GEOMÉTRICO ADYACENTE ESTILO EXBLOWRER ---
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

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
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
	local zone=Duel.SelectFieldZone(tp,1,1-tp,LOCATION_ONFIELD,~filter<<16)
	Duel.Hint(HINT_ZONE,tp,zone)
	e:SetLabel(zone) 
	local sg=groupfrombit(zone>>16,1-tp)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,sg,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local zone=e:GetLabel() 
	if not c:IsRelateToEffect(e) or c:GetCounter(0x1041)==0 then return end
	local g=groupfrombit(zone>>16,1-tp)
	if #g==0 then return end
	local max_ct=math.min(c:GetCounter(0x1041),#g)
	local count=Duel.AnnounceNumberRange(tp,1,max_ct)
	c:RemoveCounter(tp,0x1041,count,REASON_EFFECT)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local sg=g:Select(tp,count,count,false)
	if #sg>0 then
		Duel.Destroy(sg,REASON_EFFECT)
	end
end

-- --- 4. LÓGICA DE FIN DE TURNO (TOPE MÁXIMO DE 3 REAL) ---
function s.p_end_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(function(tc) return tc:IsFaceup() and tc:GetCounter(0x1041)<3 end,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,g,1,0,0x1041)
end

function s.p_end_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	for tc in aux.Next(g) do
		if tc:GetCounter(0x1041)<3 then
			if tc:AddCounter(0x1041,1) then
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

function s.lv_check_con(e)
	return e:GetHandler():GetCounter(0x1041)>0
end
