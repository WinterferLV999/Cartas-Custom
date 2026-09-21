local s,id=GetID()
local SET_ARQUETIPO=0xe3 -- 0xe3 es el código hexadecimal oficial para Cúbicos (Cubic)
function s.initial_effect(c)
	-- EFECTO ①: Activación de la Magia de Campo
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	
	-- EFECTO ②: El oponente NO puede desterrar cartas de TU Cementerio (Tú sí puedes)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_REMOVE)
	e4:SetRange(LOCATION_FZONE)
	e4:SetTargetRange(LOCATION_GRAVE,0) -- Protege únicamente a TU Cementerio
	e4:SetTarget(s.remtg)
	c:RegisterEffect(e4)
	
	-- EFECTO ③: No puedes Invocar de Modo Especial, excepto monstruos "Cúbico" (Unilateral para ti)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e5:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e5:SetRange(LOCATION_FZONE)
	e5:SetTargetRange(1,0) -- Te bloquea únicamente a ti
	e5:SetTarget(s.splimit)
	c:RegisterEffect(e5)
	
	-- EFECTO ④ REFORMADO (ESCUDO DE INMUNIDAD EXCLUSIVO): Inafectable por efectos de otras cartas si un Cubic tiene materiales abajo
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetCode(EFFECT_IMMUNE_EFFECT)
	e6:SetRange(LOCATION_FZONE)
	e6:SetCondition(s.immcon) -- Enlazado a tu nueva lógica de condición abajo
	e6:SetValue(s.immval)     -- Filtro de valor absoluto (Inmunidad total)
	c:RegisterEffect(e6)
	
	-- EFECTO ⑤ (INGENIERÍA NECROVALLEY): Niega efectos del oponente que apunten a TU Cementerio en resolución
	local e10=Effect.CreateEffect(c)
	e10:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e10:SetCode(EVENT_CHAIN_SOLVING)
	e10:SetRange(LOCATION_FZONE)
	e10:SetOperation(s.disop)
	c:RegisterEffect(e10)
end

s.listed_series={SET_ARQUETIPO}

-- =========================================================================
-- ---     NUEVA LÓGICA DE FILTRADO Y CONDICIÓN DE INMUNIDAD MÁXIMA       ---
-- =========================================================================
function s.immfilter(c)
	-- CORRECCIÓN: Filtra estrictamente si es un monstruo Cúbico boca arriba con 1 o más cartas apiladas abajo
	return c:IsFaceup() and c:IsSetCard(SET_ARQUETIPO) and c:GetOverlayCount()>=1
end

function s.immcon(e)
	-- La inmunidad se enciende si controlas al menos 1 Cúbico con materiales
	return Duel.IsExistingMatchingCard(s.immfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

function s.immval(e,te)
	-- Ignora absolutamente cualquier efecto de carta del resto del duelo
	return te:GetOwner()~=e:GetHandler()
end

-- =========================================================================
-- ---        RESTO DEL SCRIPT ORIGINAL SANEADO                           ---
-- =========================================================================
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsSetCard(SET_ARQUETIPO)
end

function s.remtg(e,c,rp,r,re)
	return rp~=e:GetHandlerPlayer()
end

function s.discheck(ev,category,tp)
	local ex,tg,ct,p,v=Duel.GetOperationInfo(ev,category)
	if not ex then return false end
	if v==LOCATION_GRAVE and p==tp then return true end
	if tg and #tg>0 then
		return tg:IsExists(function(c) return c:IsLocation(LOCATION_GRAVE) and c:GetControler()==tp end,1,nil)
	end
	return false
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not Duel.IsChainDisablable(ev) then return end
	
	local res=false
	if not res and s.discheck(ev,CATEGORY_SPECIAL_SUMMON,tp) then res=true end
	if not res and s.discheck(ev,CATEGORY_REMOVE,tp) then res=true end
	if not res and s.discheck(ev,CATEGORY_TOHAND,tp) then res=true end
	if not res and s.discheck(ev,CATEGORY_TODECK,tp) then res=true end
	if not res and s.discheck(ev,CATEGORY_TOEXTRA,tp) then res=true end
	if not res and s.discheck(ev,CATEGORY_LEAVE_GRAVE,tp) then res=true end
	
	if res then 
		Duel.NegateEffect(ev) 
	end
end
