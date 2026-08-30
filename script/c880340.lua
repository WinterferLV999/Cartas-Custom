local s,id=GetID()
function s.initial_effect(c)
	-- 1. ACTIVACIÓN DE CARTA MÁGICA
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH) -- Candado de uso único por turno
	e1:SetCost(s.activcost)
	e1:SetTarget(s.activtg)
	e1:SetOperation(s.activop)
	c:RegisterEffect(e1)
end

-- Mapeada tu ID real de tu base de datos para Supreme King Z-ARC
s.listed_names={13331639} 
s.listed_series={0x2017} -- Arquetipo "Starving Venom"

-- =========================================================================
-- --- ADUANA DE ACTIVACIÓN E INMUNIDAD (TU HOJA MANUSCRITA)             ---
-- =========================================================================
function s.activcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	-- CONDICIÓN DEL MANUSCRITO: "Si tú no controlas monstruos..."
	if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 then
		-- Bloqueo físico de hardware: Ningún jugador puede encadenar nada en respuesta
		Duel.SetChainLimit(s.chainlimit)
	end
end

function s.chainlimit(e,ep,tp)
	return tp==ep -- Detiene por completo los clics del oponente en su pantalla
end

function s.zarcfilter(c,e,tp)
	-- Busca a tu Supreme King Z-ARC legítimo (13331639) o a la serie Starving Venom
	return c:IsCode(13331639)
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.poolfilter(c,type_flag)
	-- Filtra cartas de la Mano, Deck o Extra Deck del tipo faltante, bloqueando a Z-ARC de las opciones
	return c:IsType(type_flag) and c:IsAbleToGrave() and not c:IsCode(13331639)
end

function s.activtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.zarcfilter,tp,LOCATION_EXTRA+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA+LOCATION_GRAVE+LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA)
end

-- =========================================================================
-- --- OPERACIÓN DE ESCANEO DE CEMENTERIO Y EJECUCIÓN DEL RITUAL          ---
-- =========================================================================
function s.activop(e,tp,eg,ep,ev,re,r,rp)
	-- CONDICIÓN DEL MANUSCRITO: "Ningún jugador puede activar efecto en respuesta a la invocación"
	if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_SPSUMMON_SUCCESS)
		e1:SetCountLimit(1)
		e1:SetOperation(s.sucop)
		e1:SetReset(RESET_CHAIN)
		Duel.RegisterEffect(e1,tp)
	end

	-- 1. Escaneamos la matriz global (Cementerio y Desterrados de AMBOS JUGADORES)
	local types={TYPE_FUSION, TYPE_SYNCHRO, TYPE_XYZ, TYPE_PENDULUM}
	local pool=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_GRAVE+LOCATION_REMOVED,LOCATION_GRAVE+LOCATION_REMOVED,nil,TYPE_MONSTER)
	
	-- 2. El bucle audita cada una de las 4 mecánicas
	for _,ty in ipairs(types) do
		if not pool:IsExists(Card.IsType,1,nil,ty) then
			-- Si falta este tipo de monstruo en la pila, lo buscas en MANO, DECK o EXTRA DECK
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
			local sg=Duel.SelectMatchingCard(tp,s.poolfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil,ty)
			if #sg>0 then
				Duel.SendtoGrave(sg,REASON_EFFECT)
			end
		end
	end
	
	-- 3. Con los requisitos completados en la RAM, materializa a tu Z-ARC (13331639) ignorando condiciones
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.zarcfilter,tp,LOCATION_EXTRA+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc then
		if Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)>0 then
			-- =========================================================================
			-- --- NUEVA LÓGICA DE INMUNIDAD COMPLETA ADAPTADA AL MANUSCRITO           ---
			-- =========================================================================
			-- SANEADO MAESTRO: En cuanto Z-ARC pisa el campo con éxito mediante esta Magia, 
			-- le inyectamos un escudo de hardware absoluto. Se vuelve 100% inafectable por 
			-- efectos de otras cartas en el duelo hasta la End Phase exacta de este mismo turno.
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetDescription(3110) -- Texto flotante del cliente: "Inafectable por efectos de cartas"
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_IMMUNE_EFFECT)
			e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
			e2:SetRange(LOCATION_MZONE)
			e2:SetValue(s.efilter)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e2)
		end
	end
end

function s.efilter(e,re)
	-- Retorna verdadero para cualquier efecto que no sea este mismo script, 
	-- blindándolo contra Magias, Trampas y Monstruos del oponente (y tuyos).
	return re:GetHandler()~=e:GetHandler()
end

function s.sucop(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetChainLimitTillChainEnd(s.chainlimit)
end
