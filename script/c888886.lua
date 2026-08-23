-- The Sun Go's Metallic Nightmare - Plasma Eel
local s, id = GetID()
function s.initial_effect(c)
    -- Send from hand to GY (cost or effect): Equip to opponent's monster
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_EQUIP)
    e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_TO_GRAVE)
	e1:SetCountLimit(1,{id,1})
    e1:SetCondition(s.eqcon)
    e1:SetTarget(s.eqtg)
    e1:SetOperation(s.eqop)
    c:RegisterEffect(e1)
	--During the End Phase, if "The Immortal Sun God" was sent to your GY this turn: You can add this card from your GY to your hand
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
		return Duel.HasFlagEffect(tp,id)
	end)
	e3:SetTarget(s.retthtg)
	e3:SetOperation(s.retthop)
	c:RegisterEffect(e3)
	--Check if "The Immortal Sun God" is sent to the GY
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_TO_GRAVE)
		ge1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
			for tc in eg:Iter() do
				if tc:IsCode(CARD_THE_IMMORTAL_SUN_GOD) then 
					Duel.RegisterFlagEffect(tc:GetControler(),id,RESET_PHASE|PHASE_END,0,1)
				end
			end
		end)
		Duel.RegisterEffect(ge1,0)
	end)
end
s.listed_names={id,CARD_THE_IMMORTAL_SUN_GOD}
s.listed_series={SET_SUN_GOD}

function s.eqcon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return c:IsPreviousLocation(LOCATION_HAND)
end

function s.eqtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and aux.CheckStealEquip(chkc, e, tp) end
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_SZONE) > 0
        and Duel.IsExistingTarget(aux.CheckStealEquip, tp, 0, LOCATION_MZONE, 1, nil, e, tp) end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_EQUIP)
    local g = Duel.SelectTarget(tp, aux.CheckStealEquip, tp, 0, LOCATION_MZONE, 1, 1, nil, e, tp)
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, e:GetHandler(), 1, 0, 0)
    Duel.SetOperationInfo(0, CATEGORY_LEAVE_GRAVE, e:GetHandler(), 1, 0, 0)
end

function s.eqlimit(e, c)
    return e:GetOwner() == c
end

function s.eqop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = Duel.GetFirstTarget()
    if tc and c:IsRelateToEffect(e) and aux.CheckStealEquip(tc, e, tp) and tc:IsRelateToEffect(e) and Duel.Equip(tp, c, tc) then
        -- Add Equip limit
        local e1 = Effect.CreateEffect(tc)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_EQUIP_LIMIT)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetReset(RESET_EVENT | RESETS_STANDARD)
        e1:SetValue(s.eqlimit)
        c:RegisterEffect(e1)

        -- It cannot be Tributed (For Tribute Summons)
        local e2 = Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_EQUIP)
        e2:SetCode(EFFECT_UNRELEASABLE_SUM)
        e2:SetValue(1)
        e2:SetReset(RESET_EVENT | RESETS_STANDARD)
        c:RegisterEffect(e2)

        -- It cannot be Tributed (For Costs / Card Effects)
        local e3 = e2:Clone()
        e3:SetCode(EFFECT_UNRELEASABLE_NONSUM)
        c:RegisterEffect(e3)

        -- It cannot be used as material for a Fusion, Synchro, Xyz, or Link Summon
        local e4 = Effect.CreateEffect(c)
        e4:SetType(EFFECT_TYPE_EQUIP)
        e4:SetCode(EFFECT_CANNOT_BE_MATERIAL)
        e4:SetValue(aux.cannotmatfilter(SUMMON_TYPE_FUSION, SUMMON_TYPE_SYNCHRO, SUMMON_TYPE_XYZ, SUMMON_TYPE_LINK))
        e4:SetReset(RESET_EVENT | RESETS_STANDARD)
        c:RegisterEffect(e4)

        -- Reduce ATK to half each End Phase and inflict damage equal to the difference
        local e5 = Effect.CreateEffect(c)
        e5:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
        e5:SetCode(EVENT_PHASE + PHASE_END)
        e5:SetRange(LOCATION_SZONE)
        e5:SetCountLimit(1)
        e5:SetOperation(s.atkop)
        c:RegisterEffect(e5)
    end
end

function s.atkop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    local tc = c:GetEquipTarget()
    if tc and tc:IsFaceup() then
        local current_atk = tc:GetAttack()
        local base_atk = tc:GetBaseAttack()
        
        -- Calcular la diferencia antes de reducirlo (entre el original y el actual antes de este turno, o el acumulado)
        -- Reducir el ATK actual a la mitad
        local half_atk = math.floor(current_atk / 2)
        
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(-half_atk)
        e1:SetReset(RESET_EVENT | RESETS_STANDARD)
        tc:RegisterEffect(e1)
        
        -- Daño igual a la diferencia exacta entre el ATK original y el nuevo ATK resultante
        local new_atk = current_atk - half_atk
        local diff = base_atk - new_atk
        
        if diff > 0 then
            Duel.Damage(1 - tp, diff, REASON_EFFECT)
        end
    end
end
function s.retthtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,0)
end
function s.retthop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end