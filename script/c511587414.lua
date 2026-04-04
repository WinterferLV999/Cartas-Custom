--真なる太陽神
--The True Sun God
--Scripted by The Razgriz
local s,id=GetID()
function s.initial_effect(c)
	--Search "The Winged Dragon of Ra" or 1 card that mentions it
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	--Monsters, except "The Winged Dragon of Ra", cannot attack the turn they are Special Summoned
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ATTACK)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(function(_,c) return not c:IsCode(CARD_RA) and c:IsStatus(STATUS_SPSUMMON_TURN) end)
	c:RegisterEffect(e2)
	--Send this card or 1 "The Winged Dragon of Ra - Immortal Phoenix" from the Deck to the GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1)
	e3:SetCost(s.tgcost) -- Todo ocurre aquí
	e3:SetTarget(s.tgtg)
	e3:SetOperation(s.tgop)
	c:RegisterEffect(e3)
end

s.listed_names={CARD_RA,id,10000090}

function s.thfilter(c)
	return (c:IsCode(CARD_RA) or c:ListsCode(CARD_RA)) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

function s.tgfilter(c)
	return c:IsCode(CARD_RA) and c:IsFaceup() and c:IsLocation(LOCATION_MZONE)
end

-- Filtro para Fénix en el Deck (10000090)
function s.cfilter(c)
	return c:IsCode(10000090) and c:IsAbleToGrave()
end

function s.tgcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- Verificamos si podemos pagar AMBOS costes
	if chk==0 then 
		return (c:IsAbleToGrave() or Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_DECK,0,1,nil))
			and Duel.CheckReleaseGroupCost(tp,s.tgfilter,1,false,nil,nil) 
	end
	
	-- 1. Primer envío: Esta carta o Fénix
	local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_DECK,0,nil)
	if c:IsAbleToGrave() then g:AddCard(c) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local tc=g:Select(tp,1,1,nil):GetFirst()
	if tc and Duel.SendtoGrave(tc,REASON_COST)>0 then
		-- 2. Segundo envío: Mandar a Ra (como coste de tributo)
		local sg=Duel.SelectReleaseGroupCost(tp,s.tgfilter,1,1,false,nil,nil)
		Duel.Release(sg,REASON_COST)
	end
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	-- Informamos al sistema que 2 cartas fueron al GY (opcional para animaciones)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_DECK|LOCATION_ONFIELD)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	-- La operación queda vacía o con un mensaje, ya que el coste hizo todo el trabajo.
end