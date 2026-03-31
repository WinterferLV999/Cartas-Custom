
local s,id=GetID()
function s.initial_effect(c)
	aux.AddEquipProcedure(c,nil,aux.FilterBoolFunction(Card.IsSetCard,SET_GALAXY_EYES))
    
    -- 1. Inafectable por efectos de monstruos del oponente con menor ATK (Incluye continuos)
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_EQUIP)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetValue(s.efilter)
    c:RegisterEffect(e1)

    -- 2. Duplicar ATK durante el cálculo de daño (SOLO SI ES XYZ)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_EQUIP)
    e2:SetCode(EFFECT_SET_ATTACK_FINAL)
    e2:SetCondition(s.atkcon)
    e2:SetValue(s.atkval)
    c:RegisterEffect(e2)

    -- 3. Solo el equipado ataca (SOLO SI ES XYZ)
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_CANNOT_ATTACK)
    e3:SetRange(LOCATION_SZONE)
    e3:SetTargetRange(LOCATION_MZONE, 0)
    e3:SetCondition(s.xyzcon) -- Solo aplica si el equipado es Xyz
    e3:SetTarget(s.atktg)
    c:RegisterEffect(e3)

    -- 4. Auto-equipar desde el CEMENTERIO (Restricción de turno)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 0))
    e4:SetCategory(CATEGORY_EQUIP)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCondition(s.selfeqcon)
    e4:SetTarget(s.selfeqtg)
    e4:SetOperation(s.selfeqop)
    c:RegisterEffect(e4)
end

-- 1. Lógica Filtro Inmunidad (General)
function s.efilter(e, re)
    local ec = e:GetHandler():GetEquipTarget()
    if not ec then return false end
    local rc = re:GetHandler()
    local tp = e:GetHandlerPlayer()
    if not (re:IsActiveType(TYPE_MONSTER) and rc:GetControler() ~= tp) then return false end
    local atk = rc:IsLocation(LOCATION_MZONE) and rc:GetAttack() or rc:GetTextAttack()
    return atk < ec:GetAttack()
end

-- 2. Lógica Duplicar ATK (Restringido a Xyz)
function s.atkcon(e)
    local ec = e:GetHandler():GetEquipTarget()
    -- Verifica: Fase de daño + Hay objetivo de ataque + El equipado es tipo XYZ
    return Duel.GetCurrentPhase() == PHASE_DAMAGE_CAL 
        and ec and ec:IsType(TYPE_XYZ) and ec:IsTachyon()
        and Duel.GetAttackTarget()
end

function s.atkval(e, c)
    return c:GetAttack() * 2
end

-- 3. Lógica Restricción de Ataque (Restringido a Xyz)
function s.xyzcon(e)
    local ec = e:GetHandler():GetEquipTarget()
    return ec and ec:IsType(TYPE_XYZ) and ec:IsTachyon()
end

function s.atktg(e, c)
    -- Los demás no atacan si el equipado es Xyz
    return c ~= e:GetHandler():GetEquipTarget()
end

-- 4. Lógica Auto-equipar desde GY (Excepto el turno que fue enviada)
function s.selfeqcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local g = Duel.GetFieldGroup(tp, LOCATION_MZONE, 0)
    -- Verifica: Solo 1 monstruo, es Tachyon, y NO es el turno en que cayó al GY
    return #g == 1 and g:GetFirst():IsFaceup() and g:GetFirst():IsCode(88177324)
        and c:GetTurnID() ~= Duel.GetTurnCount()
end

function s.selfeqtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0 end
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, e:GetHandler(), 1, 0, 0)
end

function s.selfeqop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local g = Duel.GetFieldGroup(tp, LOCATION_MZONE, 0)
    local tc = g:GetFirst()
    if #g == 1 and tc and tc:IsFaceup() and tc:IsCode(88177324) then
        Duel.Equip(tp, c, tc)
    end
end

