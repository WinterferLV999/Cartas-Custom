--Scripted by Winterfer
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Invocación Xyz de Fábrica: Exige 3 monstruos de OSCURIDAD de Nivel 3
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK),3,3)
	
	-- EFECTO ①: Capacidad nativa de declarar ataques directos al oponente
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DIRECT_ATTACK)
	c:RegisterEffect(e1)
	
	-- EFECTO ②: Desacopla 1 material, destruye Magias/Trampas del rival y gana 500 ATK por cada una
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id) 
	e2:SetCost(s.descost)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2,false,REGISTER_FLAG_DETACH_XMAT)
	
	-- EFECTO ③ ACTUALIZADO: Destruye TODOS los monstruos del rival (Sin importar su tipo de invocación)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id) 
	e3:SetCost(s.descost)
	e3:SetTarget(s.destg2)
	e3:SetOperation(s.desop2)
	c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)
end

-- Lista de arquetipos indexados por nombre oficial para buscadores del mazo
s.listed_series={SET_THE_PHANTOM_KNIGHTS}

-- COSTE GENERAL: Retira de forma obligatoria 1 material Xyz de la carta
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- =========================================================================
-- ---        RESOLUCIÓN DEL EFECTO ②: LIMPIEZA Y ABSORCIÓN DE ATK      ---
-- =========================================================================
function s.desfilter(c)
	return c:IsSpellTrap()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_ONFIELD,nil)
	local ct=Duel.Destroy(g,REASON_EFFECT)
	
	if ct>0 and c:IsFaceup() and c:IsRelateToEffect(e) then
		Duel.BreakEffect() 
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(ct*500)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE) 
		c:RegisterEffect(e1)
	end
end

-- =========================================================================
-- ---        RESOLUCIÓN DEL EFECTO ③: PURGA ABSOLUTA DE MONSTRUOS        ---
-- =========================================================================
function s.filter(c)
	-- CORREGIDO: Escanea cualquier monstruo boca arriba del oponente en el campo
	return c:IsFaceup()
end

function s.destg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,0,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(s.filter,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,#g*500)
end

function s.desop2(e,tp,eg,ep,ev,re,r,rp)
	local sg=Duel.GetMatchingGroup(s.filter,tp,0,LOCATION_MZONE,nil)
	if #sg>0 then
		-- Barre con todas las unidades monstruo enemigas en la mesa
		local ct=Duel.Destroy(sg,REASON_EFFECT)
		if ct>0 then
			Duel.BreakEffect() -- Breve pausa visual estética de Konami
			Duel.Damage(1-tp,ct*500,REASON_EFFECT)
		end
	end
end
