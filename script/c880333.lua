local s,id=GetID()
function s.initial_effect(c)
	-- 1. EFECTO PRINCIPAL: Negar y destruir (Se activa en cadena)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetCost(s.negcost)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
	
	-- 2. REGLA ESPECIAL: Permitir activar el turno en que se coloca (Set)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetCondition(s.actcon)
	c:RegisterEffect(e2)

	-- 3. RECICLAJE: Colocarse desde el GY cuando invocas un Xyz de OSCURIDAD
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.setcon)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_THE_PHANTOM_KNIGHTS,SET_XYZ_DRAGON}

function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard({SET_THE_PHANTOM_KNIGHTS,SET_XYZ_DRAGON}) and c:IsType(TYPE_XYZ)
end
function s.costfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsAttribute(ATTRIBUTE_DARK) and c:GetOverlayCount()>0
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		if c:IsStatus(STATUS_SET_TURN) then
			return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_MZONE,0,1,nil)
		end
		return true
	end
	if c:IsStatus(STATUS_SET_TURN) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DEATTACHFROM)
		local sc=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
		if sc then
			sc:RemoveOverlayCard(tp,1,1,REASON_COST)
		end
	end
end

function s.actcon(e)
	return e:GetHandler():IsStatus(STATUS_SET_TURN)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	local rc=re:GetHandler()
	if rc:IsDestructable() and rc:IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

-- Operación unificada con la lógica global de Called by the Grave
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	
	-- 1. Negamos la activación actual de la cadena
	if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) then
		-- Guardamos el nombre original de la carta antes de destruirla
		local code=rc:GetOriginalCodeRule()
		
		-- 2. Destruimos la carta de forma inmediata
		if Duel.Destroy(eg,REASON_EFFECT)>0 then
			
			-- 3. ESCUDO GLOBAL (Estilo Called by the Grave):
			-- e1: Apaga de forma continua monstruos con ese nombre en el campo
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
			e1:SetTarget(s.distg)
			e1:SetLabel(code)
			e1:SetReset(RESET_PHASE|PHASE_END) -- Cambiado a un solo turno (Fin de este turno)
			Duel.RegisterEffect(e1,tp)
			
			-- e2: Intercepta y niega cualquier efecto con ese nombre que intente resolver en GY, Mano o Destierro
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e2:SetCode(EVENT_CHAIN_SOLVING)
			e2:SetCondition(s.discon)
			e2:SetOperation(s.disop)
			e2:SetLabel(code)
			e2:SetReset(RESET_PHASE|PHASE_END) -- Fin de este turno
			Duel.RegisterEffect(e2,tp)
		end
	end
end

-- Funciones auxiliares globales del escudo
function s.distg(e,c)
	local code=e:GetLabel()
	local code1,code2=c:GetOriginalCodeRule()
	return code1==code or code2==code
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()
	local code1,code2=re:GetHandler():GetOriginalCodeRule()
	-- Se aplica a efectos de monstruo, magia o trampa que tengan el mismo ID original
	return code1==code or code2==code
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.NegateEffect(ev) -- Apaga la resolución de forma nativa e instantánea
end

-- --- LÓGICA DE RECICLAJE (e3) ---
function s.thcfilter(c,tp)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_DARK) and c:IsType(TYPE_XYZ)
		and c:IsControler(tp) and c:IsXyzSummoned()
end
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.thcfilter,1,nil,tp)
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,tp,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsSSetable() and Duel.SSet(tp,c)>0 then
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(3300)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetValue(LOCATION_REMOVED)
		e1:SetReset(RESET_EVENT|RESETS_REDIRECT)
		c:RegisterEffect(e1)
	end
end
