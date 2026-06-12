local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- Efecto 2: Protección contra efectos de movimiento (Efecto Rápido)
    local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end
s.listed_series={0x10db}

-- --- LÓGICA DEL EFECTO 1 (INVOCACIÓN EN CAMPO) ---
function s.filter(c)
	return c:IsFaceup() and c:GetLevel()>0 and c:IsSetCard(SET_THE_PHANTOM_KNIGHTS)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsPlayerCanSpecialSummonMonster(tp,id,0,0x21,0,0,nil,RACE_WARRIOR,ATTRIBUTE_DARK) end
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not c:IsRelateToEffect(e) or not tc:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
		or not Duel.IsPlayerCanSpecialSummonMonster(tp,id,0,0x11,0,0,1,RACE_WARRIOR,ATTRIBUTE_DARK) then return end
	c:AddMonsterAttribute(TYPE_EFFECT+TYPE_SPELL+TYPE_TRAP)
	Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)
	c:AddMonsterAttributeComplete()
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CHANGE_LEVEL)
	e0:SetValue(s.value)
	e0:SetLabelObject(tc)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e0)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UNRELEASABLE_SUM)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetReset(RESET_EVENT+RESETS_STANDARD)
	e3:SetValue(1)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	c:RegisterEffect(e4)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_CANNOT_ATTACK)
	e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e5:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e5)
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e6:SetReset(RESET_EVENT+RESETS_STANDARD)
	e6:SetCode(EFFECT_REMOVE_TYPE)
	e6:SetValue(TYPE_TRAP)
	c:RegisterEffect(e6)
end
function s.value(e,c)
	local tc=e:GetLabelObject()
	if tc:IsLocation(LOCATION_MZONE) then
		return tc:GetLevel()
	else
		return 0
	end
end

-- --- LÓGICA DEL EFECTO 2 (REEMPLAZO DE DESTRUCCIÓN) ---
function s.movfilter(c,tp)
	return c:IsOnField() and c:IsControler(tp)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- Evita autonegaciones y valida que el efecto en la cadena se pueda negar
	if tp==ep or not Duel.IsChainNegatable(ev) then return false end
	
	-- Comprobamos si el efecto del rival intenta mover cartas de TU campo (Mano, Deck, Destierro)
	local is_moving = re:IsHasCategory(CATEGORY_DESTROY) 
		or re:IsHasCategory(CATEGORY_TOHAND) 
		or re:IsHasCategory(CATEGORY_TODECK) 
		or re:IsHasCategory(CATEGORY_REMOVE)
		
	if is_moving then
		-- Si el efecto del oponente selecciona objetivos (Target), verificamos que apunte a tus cartas en el campo
		local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
		if tg and tg:IsExists(s.movfilter,1,nil,tp) then
			return true
		end
		-- Si es un efecto global destructivo/removedor masivo sin selección previa, se activa por prevención
		return true
	end
	
	return false
end

-- Coste: Se destierra a sí misma del cementerio
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- Target: Confirma la negación y destrucción en el motor de EDOPro
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
	-- Informamos al motor que este efecto infligirá daño al oponente (1-tp)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,800)
end

-- Operación: Niega el efecto, destruye la carta y quema los puntos de vida
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	-- 1. Niega la activación del efecto enemigo
	if Duel.NegateActivation(ev) then
		local rc=re:GetHandler()
		-- 2. Si la carta sigue vinculada y es destruible, la destruye
		if rc and rc:IsRelateToEffect(re) and Duel.Destroy(rc,REASON_EFFECT)>0 then
			-- Parada de milisegundo oficial para separar efectos en Yu-Gi-Oh!
			Duel.BreakEffect() 
			-- 3. Inflige los 800 puntos de daño por efecto al rival
			Duel.Damage(1-tp,800,REASON_EFFECT)
		end
	end
end