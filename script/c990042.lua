
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Summon
	local e1=Fusion.CreateSummonEff({handler=c,extrafil=s.fextra,stage2=s.stage2,extraop=s.extraop,extratg=s.extratg})
	--e1:SetCountLimit(1,id)
	c:RegisterEffect(e1)
end
s.listed_names={CARD_REDEYES_B_DRAGON}
function s.fcheck(tp,sg,fc)
	if not sg:IsExists(Card.IsRace,1,nil,RACE_DRAGON) then
		return false
	end
	if sg:IsExists(Card.IsLocation,1,nil,LOCATION_GRAVE) then
		return sg:IsExists(Card.IsCode,1,nil,CARD_REDEYES_B_DRAGON)
	end
	return true
end
function s.fextra(e,tp,mg)
	local eg=Duel.GetMatchingGroup(Fusion.IsMonsterFilter(Card.IsAbleToToDeck),tp,LOCATION_GRAVE,0,nil)
	if #eg>0 and (mg+eg):IsExists(Card.IsCode,1,nil,CARD_REDEYES_B_DRAGON) then
		if #eg>0 then
			return eg,s.fcheck
		end
	end
	return nil,s.fcheck
end
function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)
end
function s.extraop(e,tc,tp,sg)
	local rg=sg:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
	if #rg>0 then
		Duel.HintSelection(rg,true)
		Duel.SendtoDeck(rg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT|REASON_MATERIAL|REASON_FUSION)
		sg:RemoveCard(rg)
	end
end
function s.stage2(e,tc,tp,mg,chk)
	if chk==1 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(CARD_REDEYES_B_DRAGON)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end