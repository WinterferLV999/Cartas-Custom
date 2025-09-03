
local s,id=GetID()
function s.initial_effect(c)
	--Ritual Reencarnation
	local e1=Ritual.CreateProc({handler=c,lvtype=RITPROC_GREATER,filter=s.ritualfil,extrafil=s.extrafil,extraop=s.extraop,matfilter=s.forcedgroup,location=LOCATION_HAND|LOCATION_GRAVE})
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)
	--Link Reencarnation
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e2:SetTarget(s.target)
	e2:SetOperation(s.activate)
	c:RegisterEffect(e2)
	--Xyz Reencarnation
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_ACTIVATE)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.target2)
	e3:SetOperation(s.activate2)
	c:RegisterEffect(e3)
	--Fusion Reencarnation
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e4:SetType(EFFECT_TYPE_ACTIVATE)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.target3)
	e4:SetOperation(s.activate3)
	c:RegisterEffect(e4)
	--Synchro Reencarnation
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,4))
	e5:SetCategory(CATEGORY_LVCHANGE)
	e5:SetType(EFFECT_TYPE_ACTIVATE)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetCondition(s.lvcon)
	--e5:SetCondition(function(e,tp) return Duel.IsPlayerCanAdditionalSummon(tp) and not Duel.HasFlagEffect(tp,id) end)
	e5:SetTarget(s.lvtg)
	e5:SetOperation(s.lvop)
	c:RegisterEffect(e5)
end
s.listed_series={SET_SALAMANGREAT}
--local no.1
function s.ritualfil(c)
	return c:IsSetCard(SET_SALAMANGREAT)
end
function s.exfilter0(c)
	return c:IsSetCard(SET_SALAMANGREAT) and c:IsLevelAbove(1) and c:IsAbleToGrave()
end
function s.extrafil(e,tp,eg,ep,ev,re,r,rp,chk)
	if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 and Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>1 then
		return Duel.GetMatchingGroup(s.exfilter0,tp,LOCATION_DECK,0,nil)
	end
end
function s.extraop(mg,e,tp,eg,ep,ev,re,r,rp)
	local mat2=mg:Filter(Card.IsLocation,nil,LOCATION_DECK)
	mg:Sub(mat2)
	Duel.ReleaseRitualMaterial(mg)
	Duel.SendtoGrave(mat2,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
end
function s.forcedgroup(c,e,tp)
	return (c:IsType(TYPE_RITUAL) and c:IsLocation(LOCATION_ONFIELD)) or (c:IsSetCard(SET_SALAMANGREAT) and c:IsOriginalCode(code) and c:IsLocation(LOCATION_DECK))
end
--local no.2
function s.filter1(c,e,tp)
	return c:IsFaceup() and c:IsLinkMonster() and c:IsSetCard(SET_SALAMANGREAT)
		and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
end
function s.filter2(c,e,tp,mc)
	return c:IsSetCard(SET_SALAMANGREAT) and mc:IsCanBeLinkMaterial(c,tp) and c:IsLinkMonster() and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0 
		and c:IsCode(mc:GetCode()) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_LINK,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.filter1(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.filter1,tp,LOCATION_MZONE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.filter1,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or tc:IsFacedown() or not tc:IsRelateToEffect(e) or tc:IsControler(1-tp) or tc:IsImmuneToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.filter2,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc):GetFirst()
	if sc then
		sc:SetMaterial(Group.FromCards(tc))
		Duel.SendtoGrave(tc,REASON_EFFECT+REASON_MATERIAL+REASON_LINK)
		Duel.BreakEffect()
		Duel.SpecialSummon(sc,SUMMON_TYPE_LINK,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end
--local no.3
	--Check for a SALAMANGREAT Xyz monster
function s.filter3(c,e,tp)
	local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
	return (#pg<=0 or (#pg==1 and pg:IsContains(c))) and c:IsFaceup() and c:IsSetCard(SET_SALAMANGREAT) and Duel.IsExistingMatchingCard(s.filter4,tp,LOCATION_EXTRA,0,1,nil,e,tp,c,c:GetOriginalCode(),pg)
end
	--Check for "SALAMANGREAT" Xyz monster
function s.filter4(c,e,tp,mc,code,pg)
	return mc:IsType(TYPE_XYZ,c,SUMMON_TYPE_XYZ,tp) and c:IsType(TYPE_XYZ) and c:IsSetCard(SET_SALAMANGREAT) and c:IsOriginalCode(code) and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
		and mc:IsCanBeXyzMaterial(c,tp) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end
	--Activation legality
function s.target2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.filter3(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.filter3,tp,LOCATION_MZONE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.filter3,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
	--Special summon 1 "SALAMANGREAT" Xyz monster from extra deck, using targeted SALAMANGREAT Xyz monster as material
function s.activate2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(tc),tp,nil,nil,REASON_XYZ)
	if not tc or tc:IsFacedown() or not tc:IsRelateToEffect(e) or tc:IsControler(1-tp) or tc:IsImmuneToEffect(e) or #pg>1 or (#pg==1 and not pg:IsContains(tc)) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter4,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc,tc:GetCode(),pg)
	local sc=g:GetFirst()
	if sc then
		sc:SetMaterial(tc)
		Duel.Overlay(sc,tc)
		Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end
--local no.4
function s.cfilter(c)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(SET_SALAMANGREAT)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.filter5(c,e,tp,m,f)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(SET_SALAMANGREAT) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial(m,nil,tp)
end
function s.fcheck(tp,sg,fc,mg)
	if sg:IsExists(Card.IsHasEffect,1,nil,id) then
		return sg:IsExists(s.filterchk,1,nil) end
	return true
end
function s.filterchk(c)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(SET_SALAMANGREAT) and not c:IsHasEffect(id)
end
function s.target3(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		local mg1=Duel.GetFusionMaterial(tp)
		local e1,e2
		if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
			mg1:AddCard(c)
			e1=Effect.CreateEffect(c)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_IGNORE_IMMUNE)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(511002961)
			e1:SetReset(RESET_CHAIN)
			c:RegisterEffect(e1)
			e2=Effect.CreateEffect(c)
			e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_IGNORE_IMMUNE)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(id)
			e2:SetReset(RESET_CHAIN)
			c:RegisterEffect(e2)
			Fusion.CheckAdditional=s.fcheck
		end
		local res=Duel.IsExistingMatchingCard(s.filter5,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1,nil)
		Fusion.CheckAdditional=nil
		if not res then
			local ce=Duel.GetChainMaterial(tp)
			if ce~=nil then
				local fgroup=ce:GetTarget()
				local mg2=fgroup(ce,e,tp)
				local mf=ce:GetValue()
				res=Duel.IsExistingMatchingCard(s.filter5,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg2,mf)
			end
		end
		if e1 then e1:Reset() e2:Reset() end
		return res
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.activate3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg1=Duel.GetFusionMaterial(tp):Filter(aux.NOT(Card.IsImmuneToEffect),nil,e)
	local exmat=false
	if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
		local e1=Effect.CreateEffect(c)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(511002961)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(id)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
		mg1:AddCard(c)
		exmat=true
	end
	if exmat then Fusion.CheckAdditional=s.fcheck end
	local sg1=Duel.GetMatchingGroup(s.filter5,tp,LOCATION_EXTRA,0,nil,e,tp,mg1,nil)
	Fusion.CheckAdditional=nil
	local mg2=nil
	local sg2=nil
	local ce=Duel.GetChainMaterial(tp)
	if ce~=nil then
		local fgroup=ce:GetTarget()
		mg2=fgroup(ce,e,tp)
		local mf=ce:GetValue()
		sg2=Duel.GetMatchingGroup(s.filter5,tp,LOCATION_EXTRA,0,nil,e,tp,mg2,mf)
	end
	if #sg1>0 or (sg2~=nil and #sg2>0) then
		local sg=sg1:Clone()
		if sg2 then sg:Merge(sg2) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tg=sg:Select(tp,1,1,nil)
		local tc=tg:GetFirst()
		if sg1:IsContains(tc) and (sg2==nil or not sg2:IsContains(tc) or not Duel.SelectYesNo(tp,ce:GetDescription())) then
			if exmat then Fusion.CheckAdditional=s.fcheck end
			local mat1=Duel.SelectFusionMaterial(tp,tc,mg1,nil,tp)
			Fusion.CheckAdditional=nil
			tc:SetMaterial(mat1)
			Duel.SendtoGrave(mat1,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		else
			local mat2=Duel.SelectFusionMaterial(tp,tc,mg2,nil,tp)
			local fop=ce:GetOperation()
			fop(ce,e,tp,tc,mat2)
		end
		tc:CompleteProcedure()
	end
end
--local no.5
function s.lvlfilter(c)
	return c:IsType(TYPE_TUNER) and c:IsSetCard(SET_SALAMANGREAT) and c:IsLevel(3)
end
function s.lvcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.lvlfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.lvfilter(c)
	return c:IsSynchroMonster() and c:IsLevelAbove(2) and c:IsFaceup()
end
function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.lvfilter(chkc) end
	if chk==0 then return Duel.IsPlayerCanSummon(tp)
		and Duel.IsExistingTarget(s.lvfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.lvfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_LVCHANGE,g,1,tp,1)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() and tc:IsLevelAbove(2) and not tc:IsImmuneToEffect(e) then
		--Decrease its Level by 1
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_UPDATE_LEVEL)
		e1:SetValue(-3)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
		Duel.BreakEffect()
		aux.RegisterClientHint(c,nil,tp,1,0,aux.Stringid(id,2))
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
		local g=Duel.GetMatchingGroup(Card.IsSynchroSummonable,tp,LOCATION_EXTRA,0,nil,nil)
		if #g>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=g:Select(tp,1,1,nil)
			Duel.SynchroSummon(tp,sg:GetFirst(),nil)
		end
	end
end