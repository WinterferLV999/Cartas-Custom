local s,id=GetID()
function s.initial_effect(c)
	-- EFECTO ①: Acopla materiales antes de invocar para liberar la zona (Estilo Geira Guile)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.thcon2)
	e1:SetTarget(s.cubictg)
	e1:SetOperation(s.cubicop)
	c:RegisterEffect(e1)
	
	-- EFECTO ②: Esta carta copia el nombre de "Vijam la Semilla Cúbica" en el Cementerio
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CHANGE_CODE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetValue(CARD_VIJAM) -- Copia el ID oficial de Vijam de fábrica
	c:RegisterEffect(e2)
	
	-- EFECTO ③ ACTUALIZADO: Efecto otorgado que ABSORBE el ATK enemigo ÚNICAMENTE en la Battle Phase
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(1131)
	e4:SetCategory(CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_QUICK_O+EFFECT_TYPE_XMATERIAL) -- Se otorga al monstruo portador en el campo
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCondition(s.bpcon) -- NUEVO CANDADO: Condición de Battle Phase acoplada abajo
	e4:SetCost(s.dcost)      -- Costo genérico de desprendimiento de material
	e4:SetTarget(s.dtarget)
	e4:SetOperation(s.doperation)
	c:RegisterEffect(e4)
end

s.listed_series={0xe3}
s.listed_names={CARD_VIJAM}

function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_GRAVE)
end

function s.spfilter(c,e,tp)
	return c:IsMonster() and c:IsSetCard(0xe3) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.matfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xe3)
end

function s.cubictg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE,0,1,c) 
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local tg=Duel.SelectMatchingCard(tp,s.matfilter,tp,LOCATION_MZONE,0,1,99,c)
	tg:AddCard(c)
	tg:KeepAlive()
	e:SetLabelObject(tg)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_HAND+LOCATION_DECK)
end

function s.cubicop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local spg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
	local sc=spg:GetFirst()
	local tg=e:GetLabelObject()
	if sc and tg and #tg>0 then
		local mg=tg:Filter(Card.IsLocation,nil,LOCATION_MZONE)
		local tc=mg:GetFirst()
		while tc do
			if tc:GetOverlayCount()~=0 then 
				Duel.SendtoGrave(tc:GetOverlayGroup(),REASON_RULE) end
			tc=mg:GetNext()
		end
		sc:SetMaterial(mg)
		Duel.Overlay(sc,mg)
		Duel.SpecialSummon(sc,0,tp,tp,true,false,POS_FACEUP)
	end
end

-- =========================================================================
-- ---         GESTIÓN DEL EFECTO OTORGADO COMO MATERIAL (BATTLE PHASE)   ---
-- =========================================================================
function s.bpcon(e,tp,eg,ep,ev,re,r,rp)
	-- El efecto solo se iluminará de forma legal si el duelo se encuentra dentro de la Battle Phase
	return Duel.IsBattlePhase()
end

function s.dcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.ccfilter(c)
	return c:IsSummonType(SUMMON_TYPE_SPECIAL) and c:IsFaceup() and c:GetAttack()>0
end

function s.dtarget(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.ccfilter,tp,0,LOCATION_MZONE,1,nil) end
end

function s.doperation(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.ccfilter,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		-- Suma el ATK actual de todas las unidades especiales enemigas usando la función de mapeo directo
		e1:SetValue(g:GetSum(function(c) return c:GetAttack() end))
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
		-- Aplica la inyección de poder directamente sobre el portador de la mesa
		e:GetHandler():RegisterEffect(e1)
	end
end
