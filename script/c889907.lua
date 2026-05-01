
local s,id=GetID()
function s.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_MZONE+LOCATION_GRAVE) -- Lo trata como Aqua en campo y cementerio
	e0:SetCode(EFFECT_ADD_RACE)
	e0:SetValue(RACE_AQUA)
	c:RegisterEffect(e0)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(Cost.SelfDiscard)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)
	--special summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(95100021,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCost(s.cost)
	e2:SetCountLimit(3,id)
	e2:SetCondition(s.actcon)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end
s.listed_names={CARD_RA}
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,3) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(3)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,3)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp,chk)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	local g=Duel.GetDecktopGroup(p,d)
	Duel.Draw(p,d,REASON_EFFECT)
	Duel.ConfirmCards(1-p,g)
	g:Match(Card.IsMonster,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
	Duel.ShuffleHand(p)
end
--local no.2
function s.cfilter(c,ft)
	-- No puede ser Ra (ID: 10000010)
	local is_not_ra = not c:IsCode(10000010)
	return is_not_ra and c:IsAbleToHandAsCost() 
		and (ft>0 or (c:IsLocation(LOCATION_MZONE) and c:GetSequence()<5))
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	-- Se añade el chequeo de 800 LP en el chk==0
	if chk==0 then return Duel.CheckLPCost(tp,800) and ft>-1 
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_ONFIELD,0,1,nil,ft) end
	
	-- Pago de LP
	Duel.PayLPCost(tp,800)
	
	-- Devolver carta a la mano
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_ONFIELD,0,1,1,nil,ft)
	Duel.SendtoHand(g,nil,REASON_COST)
end
function s.actcon(e)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsOriginalCodeRule,CARD_RA),e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_IGNORE_IMMUNE)
		e1:SetCode(EVENT_MSET)
		e1:SetRange(LOCATION_MZONE)
		e1:SetOperation(s.desop)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EVENT_SSET)
		c:RegisterEffect(e2)
		local e3=e1:Clone()
		e3:SetCode(EVENT_CHANGE_POS)
		e3:SetCondition(s.descon2)
		c:RegisterEffect(e3)
		local e4=e1:Clone()
		e4:SetCode(EVENT_SPSUMMON_SUCCESS)
		e4:SetCondition(s.descon3)
		c:RegisterEffect(e4)
	end
end
function s.filter2(c)
	return c:GetPreviousPosition()&POS_FACEUP~=0 and c:GetPosition()&POS_FACEDOWN~=0
end
function s.descon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.filter2,1,nil)
end
function s.descon3(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsFacedown,1,nil)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Destroy(e:GetHandler(),REASON_EFFECT)
end