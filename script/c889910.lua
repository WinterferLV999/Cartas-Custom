local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Invocación por Sincronía: Exige 1 Cantante "Rosa" + 1 o más monstruos no Cantantes
	Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,SET_ROSE),1,1,Synchro.NonTuner(nil),1,99)
	
	-- EFECTO ① DEFINITIVO: Efecto Rápido Libre que niega cartas y anula sus resoluciones en cadena antes de barajar
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_QUICK_O) -- Efecto Rápido
	e1:SetCode(EVENT_FREE_CHAIN)    -- Cadena Libre (Lo activas en cualquier momento que desees)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
	
	-- EFECTO ②: Efecto Rápido Libre para regresar al Extra Deck y revivir un Sincro "Rosa"
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOEXTRA+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O) 
	e3:SetCode(EVENT_FREE_CHAIN)    
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_ROSE}

-- =========================================================================
-- ---        RESOLUCIÓN DEL EFECTO ① (DRENAJE ABSOLUTO EN CADENAS)     ---
-- =========================================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetSummonType()==SUMMON_TYPE_SYNCHRO
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsAbleToDeck() end
	local mg=c:GetMaterial()
	local count=mg and #mg or 0
	if chk==0 then return count>0 and Duel.IsExistingTarget(Card.IsAbleToDeck,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,Card.IsAbleToDeck,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,count,nil)
	
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,#g,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		local dg=Group.CreateGroup()
		local chain_count=Duel.GetCurrentChain()
		
		for tc in aux.Next(g) do
			-- Recorre la cadena activa buscando si este objetivo inició un eslabón
			for i=1,chain_count do
				local te,tgp=Duel.GetChainInfo(i,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
				if tgp~=tp and te and te:GetHandler()==tc then
					-- Niega estrictamente la activación/resolución de ese eslabón en la cadena actual
					Duel.NegateActivation(i)
				end
			end
			
			-- Desvincula de forma segura cualquier otra cadena remota del objetivo
			Duel.NegateRelatedChain(tc,RESET_TURN_SET) 
			dg:AddCard(tc)
		end
		
		-- Pausa estética reglamentaria de Konami
		Duel.BreakEffect() 
		
		-- Envía las cartas seleccionadas de regreso al Deck completamente limpias
		Duel.SendtoDeck(dg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end

-- =========================================================================
-- ---          RESOLUCIÓN DEL EFECTO ② (ESCAPE RÁPIDO LIBRE)            ---
-- =========================================================================
function s.spfilter(c,e,tp)
	return c:IsType(TYPE_SYNCHRO) and c:IsSetCard(SET_ROSE) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) and chkc~=c end
	if chk==0 then return (Duel.GetLocationCount(tp,LOCATION_MZONE)>0 or c:GetSequence()<5) 
		and c:IsAbleToExtra()
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	
	Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 and c:IsLocation(LOCATION_EXTRA)) then return end
	
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

