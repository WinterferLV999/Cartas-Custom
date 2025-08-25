
--scripted by Winterfer
local s,id=GetID()
function s.initial_effect(c)
	--token
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tktg)
	e1:SetOperation(s.tkop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
	--draw
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_DRAW)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_BE_MATERIAL)
	e6:SetCountLimit(1)
	e6:SetCondition(s.drcon)
	e6:SetTarget(s.drtg)
	e6:SetOperation(s.drop)
	c:RegisterEffect(e6)
end
--local no.1
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_ROSE,0,TYPES_TOKEN,800,800,2,RACE_PLANT,ATTRIBUTE_DARK,POS_FACEUP_ATTACK,p) end
	local c=e:GetHandler()
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) or Duel.GetLocationCount(tp,LOCATION_MZONE)<2 
		or not Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_ROSE,0,TYPES_TOKEN,800,800,2,RACE_PLANT,ATTRIBUTE_DARK,POS_FACEUP_ATTACK,p) then return end
	for i=1,2 do
		local token=Duel.CreateToken(tp,TOKEN_ROSE)
		Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK,p)
		--Cannot Special Summon non-rose_dragon monsters from Extra Deck
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e1:SetTargetRange(1,0)
        e1:SetTarget(s.exlimit)
        e1:SetCondition(function() return token:IsLocation(LOCATION_MZONE) end)
        Duel.RegisterEffect(e1,tp)
	end
end
function s.exlimit(e,c,sump,sumtype,sumpos,targetp,se)
    return c:IsLocation(LOCATION_EXTRA) and c:IsType(TYPE_SYNCHRO) and not c:IsSetCard(SET_ROSE_DRAGON) and not c:IsRace(RACE_PLANT)
end
--local no.6
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsLocation(LOCATION_GRAVE) and r==REASON_SYNCHRO
		and e:GetHandler():GetReasonCard():IsSetCard(SET_ROSE)
end
function s.cfilter(c)
	return c:IsSetCard(SET_ROSE) and not c:IsPublic()
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local dt=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)
	if dt==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local cg=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND,0,1,dt,nil)
	Duel.ConfirmCards(1-tp,cg)
	Duel.ShuffleHand(tp)
	local ct=#cg
	Duel.Draw(tp,ct,REASON_EFFECT)
end