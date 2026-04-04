
local s,id=GetID()
function s.initial_effect(c)
	aux.AddUnionProcedure(c,aux.FilterBoolFunction(Card.IsCode,88177324))
	--Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.matfilter,2)
	--Indes
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

    --NUEVO Efecto: No recibes daño de batalla que involucre al equipado
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	--Efecto 3: Negar Magia/Trampa (Sin límite, usando materiales del equipado)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCondition(s.negcon)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)

	--Efecto 4: Obligar a atacar (A los monstruos del oponente)
	--local e4=Effect.CreateEffect(c)
	--e4:SetType(EFFECT_TYPE_FIELD)
	--e4:SetCode(EFFECT_MUST_ATTACK)
	--e4:SetRange(LOCATION_SZONE)
	--e4:SetTargetRange(0,LOCATION_MZONE)
	--e4:SetValue(s.atktg)
	--c:RegisterEffect(e4)

	--NUEVO Efecto: Sellar activaciones del oponente en batalla
	--local e6=Effect.CreateEffect(c)
	--e6:SetType(EFFECT_TYPE_FIELD)
	--e6:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	--e6:SetCode(EFFECT_CANNOT_ACTIVATE)
	--e6:SetRange(LOCATION_SZONE)
	--e6:SetTargetRange(0,1)
	--e6:SetCondition(s.actcon)
	--e6:SetValue(1)
	--c:RegisterEffect(e6)
end
function s.matfilter(c,lc,sumtype,tp)
	return c:IsLevel(8) and c:IsRace(RACE_DRAGON,lc,sumtype,tp)
end

-- Condiciones para Negar Magia/Trampa
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- Solo niega la activación de Magias/Trampas del oponente
	return (re:IsActiveType(TYPE_SPELL) or re:IsActiveType(TYPE_TRAP)) 
		and rp~=tp and Duel.IsChainNegatable(ev)
end

-- Coste: Desacoplar 1 material del monstruo equipado
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local ec=e:GetHandler():GetEquipTarget()
	if chk==0 then return ec and ec:CheckRemoveOverlayCard(tp,1,REASON_COST) end
	ec:RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- Objetivo de la activación
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

-- Operación de negación y destrucción
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-- Solo permite seleccionar al monstruo equipado como objetivo de ataque
function s.atktg(e,c)
	return c~=e:GetHandler():GetEquipTarget()
end


-- Condición para sellar efectos (Cuando el equipado ataca o es atacado)
function s.actcon(e)
	local ec=e:GetHandler():GetEquipTarget()
	return ec and (Duel.GetAttacker()==ec or Duel.GetAttackTarget()==ec)
end