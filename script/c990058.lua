local s,id=GetID()
function s.initial_effect(c)
	-- Invocación por Fusión
	c:EnableReviveLimit()
	-- 1 monstruo "Edge Imp" + 1 o más monstruos "Fluffal"
	Fusion.AddProcMixRep(c,true,true,s.ffilter,1,99,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_EDGE_IMP))
	-- EFECTO ①: Inmunidad a destrucción por EFECTOS (Si usó a Fluffal Elephant - ID: 990046)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetCondition(s.matcon) -- Comprueba de forma directa si usó al elefante de peluche
	e1:SetValue(1)
	c:RegisterEffect(e1)
	
	-- NUEVO ADICIONAL ①.①: Inmunidad a destrucción por BATALLA (Si usó a Fluffal Elephant - ID: 990046)
	local e1b=e1:Clone()
	e1b:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	c:RegisterEffect(e1b)
	
	-- EFECTO ②: Enviar un Fluffal del Deck al GY para TOMAR EL CONTROL de un monstruo rival
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_CONTROL)
	e2:SetType(EFFECT_TYPE_IGNITION) -- Efecto de encendido estándar en tu Main Phase
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET) -- Selección quirúrgica de un objetivo en campo
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.tgcost)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
	
	-- EFECTO ③: Gana 300 ATK por cada Fluffal y Frightfur en tu CEMENTERIO
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)
end

s.listed_series={SET_EDGE_IMP,SET_FLUFFAL,SET_FRIGHTFUR}
s.listed_names={990046} 

-- Filtro para materiales Fluffal
function s.ffilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_FLUFFAL,fc,sumtype,tp)
end

-- Condición del Efecto ①: Verifica de forma nativa la presencia de Fluffal Elephant en los materiales
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_FUSION) and c:GetMaterial():IsExists(Card.IsCode,1,nil,990046)
end

-- Coste del Efecto ②: Enviar 1 monstruo Fluffal desde el Deck al Cementerio
function s.tgfilter(c)
	return c:IsSetCard(SET_FLUFFAL) and c:IsAbleToGraveAsCost()
end
function s.tgcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end

-- Target del Efecto ②: Selecciona 1 monstruo que se pueda tomar el control
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) and chkc:IsControlerCanBeChanged() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectTarget(tp,Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
end

-- Operación del Efecto ②: Toma el control del monstruo enemigo seleccionado hasta la End Phase
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.GetControl(tc,tp,PHASE_END,1)
	end
end

-- Lógica del Efecto ③: Cuenta cartas de ambos arquetipos en TU cementerio
function s.atkfilter(c)
	return c:IsSetCard(SET_FLUFFAL) or c:IsSetCard(SET_FRIGHTFUR)
end
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.atkfilter,c:GetControler(),LOCATION_GRAVE,0,nil)*300
end