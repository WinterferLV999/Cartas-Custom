--Number 38: Hope Harbinger Dragon Titanic Galaxy
Duel.LoadCardScript("c63767246.lua")
local s,id=GetID()
function s.initial_effect(c)
	--xyz summon
	Xyz.AddProcedure(c,nil,8,2)
	c:EnableReviveLimit()
    -- EFECTO 1: Negar y Desterrar
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetCondition(s.negcon)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)
	--attach
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetLabelObject(e1)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.atcon)
	e2:SetOperation(s.atop)
	c:RegisterEffect(e2)
	--change battle target
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.con)
	e3:SetCost(s.cost)
	e3:SetOperation(s.op)
	c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)
	--gain atk
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetCondition(s.atkcon1)
	e4:SetOperation(s.atkop1)
	c:RegisterEffect(e4)
	--xyz gains atk
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,4))
	e5:SetCategory(CATEGORY_ATKCHANGE)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e5:SetCode(EVENT_DESTROYED)
	e5:SetTarget(s.atktg2)
	e5:SetOperation(s.atkop2)
	c:RegisterEffect(e5)
	--battle indestructable
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e6:SetValue(s.indes)
	c:RegisterEffect(e6)
end
s.xyz_number=38
-- Lógica del Negado
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and re:IsActiveType(TYPE_SPELL) and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemove() end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,Group.FromCards(e:GetHandler(),re:GetHandler()),2,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=re:GetHandler()
    if Duel.NegateActivation(ev) and c:IsRelateToEffect(e) then
        local g=Group.FromCards(c)
        if tc:IsRelateToEffect(re) then g:AddCard(tc) end
        
        if Duel.Remove(g,POS_FACEUP,REASON_EFFECT)>0 then
            -- Creamos un grupo persistente para guardar las referencias
            local sg=Group.FromCards(c,tc)
            sg:KeepAlive()
            
            -- Registro del efecto de retorno en el duelo
            local e2=Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
            e2:SetCode(EVENT_SPSUMMON_SUCCESS)
            e2:SetLabelObject(sg)
            e2:SetCondition(s.xyzcon)
            e2:SetOperation(s.xyzop)
            -- Reset por seguridad: si no regresan en 2 turnos, el efecto se borra
            e2:SetReset(RESET_PHASE+PHASE_END,2) 
            Duel.RegisterEffect(e2,tp)
        end
    end
end

-- Lógica de reconexión (Usa referencias directas, no nombres)
function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
    local sg=e:GetLabelObject()
    local c=sg:GetFirst()  -- El monstruo
    local tc=sg:GetNext() -- La magia
    
    -- Verifica si "esta carta específica" (c) está en el grupo de invocados
    return eg:IsContains(c) and tc and tc:IsLocation(LOCATION_REMOVED)
end

function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
    local sg=e:GetLabelObject()
    local c=sg:GetFirst()
    local tc=sg:GetNext()
    
    if c and tc and tc:IsLocation(LOCATION_REMOVED) then
        Duel.Overlay(c,tc)
    end
    
    -- Limpieza de memoria (IMPORTANTE)
    sg:DeleteGroup()
    e:Reset()
end
function s.atcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=e:GetLabelObject():GetLabelObject()
	return c:GetPreviousLocation()==LOCATION_REMOVED and c:GetFlagEffect(id)>0 and tc and tc:GetFlagEffect(id)>0
end
function s.atop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Overlay(e:GetHandler(),e:GetLabelObject():GetLabelObject())
	e:GetLabelObject():SetLabelObject(nil)
end
function s.con(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp and Duel.GetAttackTarget()~=e:GetHandler()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.ChangeAttackTarget(c)
	end
end
function s.atkfilter(c,tp)
	return c:IsReason(REASON_DESTROY) and c:IsPreviousControler(tp) and c:IsType(TYPE_XYZ)
end
function s.atkcon1(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.atkfilter,nil,tp)
	return #g==1 and g:GetFirst()~=e:GetHandler()
end
function s.atkop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=eg:Filter(s.atkfilter,nil,tp)
	local tc=g:GetFirst()
	if tc and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		e1:SetValue(tc:GetBaseAttack())
		c:RegisterEffect(e1)
	end
end
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_XYZ)
end
function s.atktg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then return true end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.atkop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(e:GetHandler():GetPreviousAttackOnField())
		tc:RegisterEffect(e1)
	end
end
function s.indes(e,c)
	return not c:IsSetCard(SET_NUMBER)
end