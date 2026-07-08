local s,id=GetID()
function s.initial_effect(c)
	--synchro summon
	--Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsType,TYPE_SYNCHRO),1,99)
	c:EnableReviveLimit()
	
    -- EFECTO ①: CLONADO PREMIUM (Negación Rápida + Ventana de Destrucción Condicionada a Sincronía)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE) -- 0x4 = LOCATION_MZONE
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
	e1:SetCountLimit(1)
	e1:SetTarget(s.target1)
	e1:SetOperation(s.operation1)
	c:RegisterEffect(e1)
	
	-- EFECTO ② NUEVO: Invocación por Reacción de Activación (Efecto Rápido en Cadena)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON) -- Categoría de Invocación Especial
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING) -- Se dispara en el microsegundo en que OTRA carta es activada
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1000) -- Candado único por turno independiente para el Efecto 2 (id+1000)
	e2:SetCost(s.tempbanishcost)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- =========================================================================
-- ---          MOTOR DE RESOLUCIÓN DEL EFECTO ① (TU BASE GANADORA)      ---
-- =========================================================================
function s.target1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and chkc:IsNegatable() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
	if e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	end
end
function s.operation1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and ((tc:IsFaceup() and not tc:IsDisabled()) or tc:IsType(TYPE_TRAPMONSTER)) and tc:IsRelateToEffect(e) then
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESETS_STANDARD_PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESETS_STANDARD_PHASE_END)
		tc:RegisterEffect(e2)
		if tc:IsType(TYPE_TRAPMONSTER) then
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
			e3:SetReset(RESETS_STANDARD_PHASE_END)
			tc:RegisterEffect(e3)
		end
		Duel.AdjustInstantly(tc)
		Duel.BreakEffect()
		if c:IsRelateToEffect(e) and c:IsFaceup() and c:IsSummonType(SUMMON_TYPE_SYNCHRO) 
			and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.Destroy(tc,REASON_EFFECT)
		end
	end
end

-- =========================================================================
-- ---       MOTOR DE RESOLUCIÓN DEL EFECTO ②: REACCIÓN EN CADENA        ---
-- =========================================================================

-- Filtra monstruos del arquetipo Stardust (0xa3) en tu GY o Destierro que puedan ser Invocados Especialmente
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xa3) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.tempbanishcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() end
	--Banish this card until the End Phase
	aux.RemoveUntil(c,nil,REASON_COST,PHASE_END,id,e,tp,aux.DefaultFieldReturnOp)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- REGLA DE FILTRO: Se activa cuando CUALQUIER OTRA carta o efecto es activado en el duelo.
	-- re:GetHandler()~=e:GetHandler() asegura que el dragón no intente reaccionar a sus propias habilidades.
	return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and re:GetHandler()~=e:GetHandler()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- El radar valida si tienes espacio en tu zona de monstruos (0x4) y si posees al menos 1 Stardust legal en GY/Destierro
	if chk==0 then return Duel.GetLocationCount(tp,0x4)>0 
		and Duel.IsExistingMatchingCard(s.spfilter,tp,0x10+0x20,0,1,nil,e,tp) end -- 0x10 = GY / 0x20 = Destierro
	
	-- Sincroniza la operación de Invocación Especial en la base de datos de tu servidor clásico
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0x10+0x20)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,0x4)>0 
		and Duel.IsExistingMatchingCard(s.spfilter,tp,0x10+0x20,0,1,nil,e,tp)  then
		
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		-- Te ilumina tu lista completa de Cementerio y Removidas en azul brillante para que elijas a tu criatura
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,0x10+0x20,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end