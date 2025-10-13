
--scripted by Winterfer
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon Procedure: 2 or more Level 8 monsters
	Xyz.AddProcedure(c,nil,8,2,nil,nil,Xyz.InfiniteMats)
	--Xyz.AddProcedure(c,nil,8,3)
	--Special Summon 1 Rank 8 Dragon Xyz Monster from your Extra Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Attach this card to a Number Xyz Monster as material
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET,EFFECT_FLAG2_CHECK_SIMULTANEOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(function(e,tp) return Duel.GetCustomActivityCount(id,tp,ACTIVITY_SPSUMMON)>0 end)
	e2:SetTarget(s.attachtg)
	e2:SetOperation(s.attachop)
	c:RegisterEffect(e2)
	Duel.AddCustomActivityCounter(id,ACTIVITY_SPSUMMON,s.counterfilter)
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.atcon)
    e3:SetTarget(s.dettg)
    e3:SetOperation(s.detop)
    c:RegisterEffect(e3)
end
--local no.1
--Prototipo del efecto no.1
function s.filter1(c,e,tp)
	local m=c:GetMetatable(true)
	if not m then return false end
	if c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,nil,c)<=0 then
		return false
	end
	local no=m.xyz_number
	local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
	return (#pg<=0 or (#pg==1 and pg:IsContains(c))) and c:IsCode(93717133) and not c:IsSetCard(SET_NUMBER_C)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and (aux.CheckSummonGate(tp,2) or c:IsLocation(LOCATION_MZONE|LOCATION_GRAVE|LOCATION_HAND))
		and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,c,no,pg)
end
function s.filter2(c,e,tp,mc,no,pg)
	--if c.rum_limit then return false end
	if c.rum_limit and not c.rum_limit(mc,e) then return false end
	--return c.xyz_number==no and mc:IsCanBeXyzMaterial(c,tp) and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
	return mc:IsCanBeXyzMaterial(c,tp) and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0 and c:IsRank(8) and c:IsSetCard(SET_GALAXY_EYES)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end
function s.targett(e,tp,eg,ep,ev,re,r,rp,chk)
	local loc=LOCATION_EXTRA
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then loc=loc|LOCATION_MZONE|LOCATION_GRAVE|LOCATION_HAND end
	if chk==0 then return Duel.IsPlayerCanSpecialSummonCount(tp,2)
		and Duel.GetFlagEffect(tp,id)==0 and Duel.IsExistingMatchingCard(s.filter1,tp,loc,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,loc)
end
function s.activatee(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFlagEffect(tp,id)~=0 then return end
	Duel.RegisterFlagEffect(tp,id,0,0,0)
	local loc=LOCATION_EXTRA
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then loc=loc|LOCATION_MZONE|LOCATION_GRAVE|LOCATION_HAND end
	if loc==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g1=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.filter1),tp,loc,0,1,1,nil,e,tp)
	local tc1=g1:GetFirst()
	if tc1 and Duel.SpecialSummon(tc1,0,tp,tp,false,false,POS_FACEUP)~=0 then
		local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(tc1),tp,nil,nil,REASON_XYZ)
		local m=tc1:GetMetatable(true)
		if not m then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g2=Duel.SelectMatchingCard(tp,s.filter2,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc1,m.xyz_number,pg)
		local tc2=g2:GetFirst()
		if tc2 then
			Duel.BreakEffect()
			tc2:SetMaterial(g1)
			Duel.Overlay(tc2,g1)
			Duel.SpecialSummon(tc2,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
			tc2:CompleteProcedure()
		end
	end
end
--Efecto finalizado
function s.tgfilter(c,e,tp,mmzone_chk)
	local no=c.xyz_number
	if not (c:IsCode(93717133)) then return false end
	if c:IsLocation(LOCATION_MZONE) then
		return c:IsFaceup() and c:IsCanBeEffectTarget(e)
	elseif c:IsLocation(LOCATION_GRAVE) then
		return mmzone_chk and c:IsCanBeEffectTarget(e) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
	elseif c:IsLocation(LOCATION_HAND) then
		return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
	elseif c:IsLocation(LOCATION_REMOVED) then
		return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
	end
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local mmzone_chk=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE|LOCATION_GRAVE|LOCATION_HAND|LOCATION_REMOVED) and s.tgfilter(chkc,e,tp,mmzone_chk) end
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_MZONE|LOCATION_GRAVE|LOCATION_HAND|LOCATION_REMOVED,0,1,nil,e,tp,mmzone_chk) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local tc=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_MZONE|LOCATION_GRAVE|LOCATION_HAND|LOCATION_REMOVED,0,1,1,nil,e,tp,mmzone_chk):GetFirst()
	Duel.SetTargetCard(tc)
	local target_not_in_mzone=not tc:IsLocation(LOCATION_MZONE)
	local g=target_not_in_mzone and tc or nil
	local ct=target_not_in_mzone and 2 or 1
	local loc=target_not_in_mzone and tc:GetLocation()|LOCATION_EXTRA or LOCATION_EXTRA
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,ct,tp,LOCATION_EXTRA)
end
function s.exspfilter(c,e,tp,mc,rk)
	return mc:IsCanBeXyzMaterial(c,tp) and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0 and c:IsRank(8) and c:IsSetCard(SET_GALAXY_EYES)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) then return end
	if tc:IsLocation(LOCATION_MZONE) and (tc:IsFacedown() or tc:IsControler(1-tp)) then return end
	if tc:IsLocation(LOCATION_GRAVE|LOCATION_HAND|LOCATION_REMOVED) and Duel.SpecialSummonStep(tc,0,tp,tp,true,false,POS_FACEUP) then
		if Duel.SpecialSummonComplete()==0 then return end
	end
	local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(tc),tp,nil,nil,REASON_XYZ)
	if #pg>1 or (#pg==1 and not pg:IsContains(tc)) then return end
	local g=Duel.GetMatchingGroup(s.exspfilter,tp,LOCATION_EXTRA,0,nil,e,tp,tc,tc:GetRank()+0)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=g:Select(tp,1,1,nil):GetFirst()
		if not sc then return end
		Duel.BreakEffect()
		sc:SetMaterial(tc)
		Duel.Overlay(sc,tc)
		if Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
			sc:CompleteProcedure()
		end
	end
end
--local no.2
function s.counterfilter(c)
	return not (c:IsType(TYPE_XYZ) and c:IsXyzSummoned())
end
function s.attachfilter(c,e,tp)
	return c:IsSummonPlayer(tp) and c:IsRace(RACE_DRAGON) and c:IsType(TYPE_XYZ) and c:IsSetCard(SET_NUMBER) and c:IsFaceup()
		and c:IsCanBeEffectTarget(e) and c:IsLocation(LOCATION_MZONE)
end
function s.attachtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return eg:IsContains(chkc) and s.attachfilter(chkc,e,tp) end
	if chk==0 then return eg:IsExists(s.attachfilter,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=eg:FilterSelect(tp,s.attachfilter,1,1,nil,e,tp)
	Duel.SetTargetCard(g)
	local c=e:GetHandler()
	if c:IsLocation(LOCATION_MZONE) then
		Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,tp,0)
	end
end
function s.attachop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		Duel.Overlay(tc,c)
	end
end
--local no.3
function s.atcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_COST) and re:IsActivated() and re:IsActiveType(TYPE_XYZ) and c:IsPreviousLocation(LOCATION_OVERLAY)
end
function s.dettg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsFaceup() and chkc:IsSetCard(SET_NUMBER) end
	if chk==0 then return Duel.IsExistingTarget(aux.FaceupFilter(Card.IsSetCard,SET_NUMBER),tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATKDEF)
	Duel.SelectTarget(tp,aux.FaceupFilter(Card.IsSetCard,SET_NUMBER),tp,LOCATION_MZONE,0,1,1,nil)
end
function s.detop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		e1:SetValue(tc:GetAttack()*ct)
		tc:RegisterEffect(e1)
	end
end