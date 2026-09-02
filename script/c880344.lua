local s,id=GetID()
function s.initial_effect(c)
	-- Habilita de forma nativa la Invocación y las mecánicas de Péndulo en el Core clásico
	Pendulum.AddProcedure(c)
	
	-- EFFECT ①: INVOCACIÓN DE DESPLIEGUE DUAL DESDE LA ESCALA + CAMBIO DE ATRIBUTO (PÉNDULO)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_PZONE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.pcon)
	e1:SetTarget(s.ptg)
	e1:SetOperation(s.pop)
	c:RegisterEffect(e1)
	
	-- EFFECT ②: INVOCACIÓN NORMAL O ESPECIAL -> COLOCAR SPELL/TRAP "SUPREME KING" (MONSTRUO)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	
	-- EFFECT ③: MOTOR DE CAMBIO DE ATRIBUTO EN CALIENTE (ESTILO PREDAPLANT)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_MZONE,0)
	e4:SetTarget(s.attrtg)
	e4:SetValue(ATTRIBUTE_DARK)
	e4:SetOperation(s.attrcon)
	c:RegisterEffect(e4)
end

s.listed_series={SET_SUPREME_KING_DRAGON, 0xf8}

-- =========================================================================
-- --- SUBRUTINAS DE PÉNDULO Y MONSTRUO (INTACTAS TOTAL FIX)             ---
-- =========================================================================
function s.pcon(e,tp,eg,ep,ev,re,r,rp)
	return not eg:IsContains(e:GetHandler())
end
function s.pfilter(c,e,tp)
	return c:IsFaceup() and c:IsType(TYPE_PENDULUM) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.ptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(s.pfilter,tp,LOCATION_PZONE,0,1,c,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,2,tp,LOCATION_PZONE)
end
function s.pop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	if Duel.SpecialSummonStep(c,0,tp,tp,false,false,POS_FACEUP) then
		local g=Duel.SelectMatchingCard(tp,s.pfilter,tp,LOCATION_PZONE,0,1,1,c,e,tp)
		local tc=g:GetFirst()
		if tc then
			if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_CHANGE_ATTRIBUTE)
				e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e1:SetValue(ATTRIBUTE_DARK)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
			end
		end
		Duel.SpecialSummonComplete()
	end
end
function s.setfilter(c)
	return c:IsSetCard(0xf8) and c:IsType(TYPE_SPELL+TYPE_TRAP)
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true)
		Duel.ConfirmCards(1-tp,tc)
	end
end
function s.attrtg(e,c)
	return c==e:GetHandler()
end
function s.attrcon(scard,sumtype,tp)
	local match_type = (sumtype & (MATERIAL_FUSION+MATERIAL_SYNCHRO+MATERIAL_XYZ)) ~= 0
	local match_arquetype = scard and scard:IsSetCard(SET_SUPREME_KING_DRAGON)
	return match_type and match_arquetype
end