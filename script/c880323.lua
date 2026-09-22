local s,id=GetID()
local COUNTER_CUBIC=0x1038
function s.initial_effect(c)
	-- EFECTO ①: Magia Rápida - Envía Vijams del Deck al GY para colocar Contadores Cúbicos (No-Selección)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- EFECTO ②: Sustitución mixta desde el GY basada en tu referencia (Protege por Batalla y por Efecto)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	--e2:SetCountLimit(1,{id,1}) 
	e2:SetTarget(s.reptg)
	e2:SetLabelObject(c)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end

s.listed_names={CARD_VIJAM}
s.counter_place_list={COUNTER_CUBIC}
s.listed_series={0xe3} -- Código del arquetipo Cúbico

-- =========================================================================
-- ---   MÓDULO TARGET: CÁLCULO PROPORCIONAL DE OBJETIVOS Y COSTES       ---
-- =========================================================================
function s.vijamfilter(c)
	return c:IsCode(CARD_VIJAM) and c:IsAbleToGrave()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local opp_monsters=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	local deck_vijams=Duel.GetMatchingGroupCount(s.vijamfilter,tp,LOCATION_DECK,0,nil)
	
	if chk==0 then 
		return #opp_monsters>0 and deck_vijams>0 
	end
	
	-- NUEVO CANDADO DE CADENA TURNO EXCLUSIVO:
	-- Si el jugador que activa la carta (tp) es el dueño del turno actual, se congela el motor de monstruos rivales.
	-- Si es el turno del oponente (tp ~= Duel.GetTurnPlayer()), esta subrutina pasa de largo y sí pueden responder.
	if tp==Duel.GetTurnPlayer() then
		Duel.SetChainLimit(function(te) return not te:IsMonsterEffect() end)
	end
	
	local max_count=math.min(#opp_monsters,deck_vijams)
	local t={}
	for i=1,max_count do t[i]=i end
	local ct=Duel.AnnounceNumber(tp,table.unpack(t))
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.vijamfilter,tp,LOCATION_DECK,0,ct,ct,nil)
	Duel.SendtoGrave(g,REASON_COST)
	
	e:SetLabel(ct)
	Duel.SetOperationInfo(0,CATEGORY_COUNTER,nil,ct,0,COUNTER_CUBIC)
end

-- =========================================================================
-- ---   MÓDULO OPERATION: ACOPLAMIENTO DE CONTADORES SIN SELECCIONAR    ---
-- =========================================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=e:GetLabel()
	
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	if #g==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_COUNTER)
	local sg=g:Select(tp,ct,ct,nil)
	if #sg==0 then return end
	
	for tc in aux.Next(sg) do
		Duel.HintSelection(tc)
		if tc:AddCounter(COUNTER_CUBIC,1) then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CANNOT_ATTACK)
			e1:SetCondition(s.countercon)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			
			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE)
			tc:RegisterEffect(e2)
		end
	end
end

function s.countercon(e)
	return e:GetHandler():GetCounter(COUNTER_CUBIC)>0
end

-- =========================================================================
-- ---   MÓDULO EFECTO ②: SUSTITUCIÓN MIXTA POR BATALLA Y EFECTO        ---
-- =========================================================================
function s.repfilter(c,tp)
	return c:IsControler(tp) and c:IsLocation(LOCATION_ONFIELD) and c:IsFaceup() and c:IsSetCard(0xe3)
		and not c:IsReason(REASON_REPLACE) and (c:IsReason(REASON_EFFECT|REASON_BATTLE))
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemove() and eg:IsExists(s.repfilter,1,nil,tp) end
	return Duel.SelectEffectYesNo(tp,c,96)
end

function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT|REASON_REPLACE)
end
