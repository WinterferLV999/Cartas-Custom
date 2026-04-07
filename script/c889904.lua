local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY,EFFECT_FLAG2_CHECK_SIMULTANEOUS)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1)
	e2:SetRange(LOCATION_GRAVE|LOCATION_REMOVED)
	e2:SetCondition(s.dcondition)
	e2:SetTarget(s.dtarget)
	e2:SetOperation(s.doperation)
	c:RegisterEffect(e2)
end
s.listed_names={CARD_RA,CARD_OBELISK,CARD_SLIFER}
--Local No.1
-- Función auxiliar para permitir Bestias Divinas
function s.divinefilter(e,c)
	return not c:IsRace(RACE_DIVINE)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Verificación: No haber invocado nada que NO sea Bestia Divina antes
	if chk==0 then return Duel.GetActivityCount(tp,ACTIVITY_SUMMON)==0
		and Duel.GetActivityCount(tp,ACTIVITY_FLIPSUMMON)==0 
		and Duel.GetActivityCount(tp,ACTIVITY_SPSUMMON)==0 end
	
	local c=e:GetHandler()
	
	-- 1. Restricción de Invocación Especial: Solo permite Bestias Divinas
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetReset(RESET_PHASE|PHASE_END)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.sumlimit)
	Duel.RegisterEffect(e1,tp)
	
	-- 2. Restricción de Invocación Normal: Solo permite Bestias Divinas
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e2:SetCode(EFFECT_CANNOT_SUMMON)
	e2:SetReset(RESET_PHASE|PHASE_END)
	e2:SetTargetRange(1,0)
	e2:SetTarget(s.divinefilter) -- Aquí aplicamos la excepción
	Duel.RegisterEffect(e2,tp)
	
	-- 3. Restricción de Volteo: Solo permite Bestias Divinas
	local e3=e2:Clone()
	e3:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
	Duel.RegisterEffect(e3,tp)
	
	-- Indicador visual del estado
	local e4=Effect.CreateEffect(c)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetReset(RESET_PHASE|PHASE_END)
	e4:SetTargetRange(1,0)
	Duel.RegisterEffect(e4,tp)
end

-- Lógica para la excepción de Invocación Especial
function s.sumlimit(e,c,sump,sumtype,sumpos,targetp,se)
	-- Permite si el monstruo es Bestia Divina O si es invocado por este efecto
	return not c:IsRace(RACE_DIVINE) and e:GetHandler()~=se:GetHandler()
end
function s.ssumlimit(e,c,sump,sumtype,sumpos,targetp,se)
	return e:GetHandler()~=se:GetHandler()
end
function s.spfilter(c,e,tp)
	return c:IsCode(CARD_RA,CARD_OBELISK,CARD_SLIFER,10000080,10000090)
	--return c:IsCode(CARD_RA,10000080,10000090) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.filter(c,e,tp)
	return c:IsCode(CARD_RA,CARD_OBELISK,CARD_SLIFER,10000080,10000090) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE|LOCATION_REMOVED)
	
	-- Protección de cadena (opcional, para que no puedan responder)
	if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
		Duel.SetChainLimit(aux.FALSE)
	end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil)
	local tc=g:GetFirst()
	
	if tc then
		-- El quinto parámetro 'true' ignora las condiciones de invocación (Nomi/Semi-Nomi)
		if Duel.SpecialSummonStep(tc,0,tp,tp,true,true,POS_FACEUP) then
			-- Si quieres añadir efectos adicionales al monstruo al ser invocado, hazlo aquí
			Duel.SpecialSummonComplete()
			
			Duel.SkipPhase(Duel.GetTurnPlayer(),PHASE_END,RESET_PHASE+PHASE_END,1)
		end
	end
end
--Local No.2
function s.dfilter(c,tp)
	return c:IsAttribute(ATTRIBUTE_DIVINE) and c:IsControler(tp) and c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.dcondition(e,tp,eg,ep,ev,re,r,rp)
	return not eg:IsContains(e:GetHandler()) and eg:IsExists(s.dfilter,1,nil,tp)
end
function s.dtarget(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.doperation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	end
end