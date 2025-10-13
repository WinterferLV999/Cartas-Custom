
--Scripted by Winterfer
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK),10,4)
	--Cannot be destroyed by battle
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e0:SetValue(1)
	c:RegisterEffect(e0)
	--special summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e1:SetCode(EVENT_LEAVE_FIELD)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--Attach all banished monsters to this card as material
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.attachtg)
	e2:SetOperation(s.attachop)
	c:RegisterEffect(e2)
	--Negate any battle damage you would have taken from a battle involving this card, and if you do, inflict damage to your opponent equal to that amount, and if you do that, you gain LP equal to the amount of damage inflicted
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_CHANGE_DAMAGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(1,0)
	e3:SetValue(s.damval)
	c:RegisterEffect(e3)
	--Activate the effect of 1 Xyz Monster attached to this card that activates by detaching its own Xyz Material(s)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	--e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCost(s.copycost)
	e4:SetTarget(s.copytg)
	e4:SetOperation(s.copyop)
	c:RegisterEffect(e4)
end
s.listed_series={SET_NUMBER_C}
--local no.1
function s.cfilter(c,e,tp,xyz)
	return c:IsCode(98555327) and c:IsPreviousLocation(LOCATION_MZONE)
	--return c:IsCode(98555327) and c:IsPreviousControler(tp) and c:IsReason(REASON_DESTROY)
		and c:IsCanBeXyzMaterial(xyz,tp) and (not e or c:IsRelateToEffect(e))
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,nil,tp,e:GetHandler())
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=eg:Filter(s.cfilter,nil,nil,tp,e:GetHandler())
	if chk==0 then
		local c=e:GetHandler()
		local pg=aux.GetMustBeMaterialGroup(tp,g,tp,nil,nil,REASON_XYZ)
		return #pg<=0 and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
	end
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false) then return end
	local g=eg:Filter(s.cfilter,nil,e,tp,c)
	local pg=aux.GetMustBeMaterialGroup(tp,g,tp,nil,nil,REASON_XYZ)
	if #g>0 and #pg<=0 and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 then
		c:SetMaterial(g)
		Duel.Overlay(c,g)
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
		c:CompleteProcedure()
	end
end
--local no.2
function s.filter(c)
	return c:IsFaceup() and c:IsCode(990064)
end
function s.attachfilter(c,xc,tp)
	return not c:IsSpellTrap() and c:IsCanBeXyzMaterial(xc,tp,REASON_EFFECT)
end
function s.attachtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and c:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.attachfilter,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.attachop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsImmuneToEffect(e) then
		local g=Duel.GetMatchingGroup(s.attachfilter,tp,LOCATION_REMOVED,LOCATION_REMOVED,nil)
		if #g>0 then
			Duel.Overlay(tc,g)
		end
	end
end 
--local no.3
function s.damval(e,re,val,r,rp,rc)
	local c=e:GetHandler()
	if not (c:IsRelateToBattle() and r&REASON_BATTLE==REASON_BATTLE) then return val end
	local tp=e:GetHandlerPlayer()
	--Inflict damage to your opponent equal to the damage you would have taken, and if you do, you gain LP equal to the damage inflicted
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_BATTLED)
	e1:SetOperation(function()
						local dam=Duel.Damage(1-tp,val,REASON_EFFECT)
						if dam>0 then
							Duel.Recover(tp,dam,REASON_EFFECT)
						end
					end)
	e1:SetReset(RESET_PHASE|PHASE_DAMAGE)
	Duel.RegisterEffect(e1,tp)
	return 0
end
--local no.4
function s.copyfilter(c,e,tp)
	return c:IsMonster() and c:IsType(TYPE_XYZ)
end
function s.copycost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local b1=c:CheckRemoveOverlayCard(tp,1,REASON_COST)
	local b2=Duel.CheckLPCost(tp,400)
	if chk==0 then return (b1 or b2) and c:GetOverlayGroup():IsExists(s.copyfilter,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,1))
	local sc=c:GetOverlayGroup():FilterSelect(tp,s.copyfilter,1,1,nil,e,tp):GetFirst()
	Duel.Hint(HINT_CARD,0,sc:GetOriginalCodeRule())
	sc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
	local op=Duel.SelectEffect(tp,{b2,aux.Stringid(id,3)})
	if op==1 then
		Duel.PayLPCost(tp,400)
	end
	local available_effs={}
	local effs={sc:GetOwnEffects()}
	for _,eff in ipairs(effs) do
		if eff:HasDetachCost() then
			local con=eff:GetCondition()
			local tg=eff:GetTarget()
			if (con==nil or con(e,tp,Group.CreateGroup(),PLAYER_NONE,0,e,REASON_EFFECT,PLAYER_NONE,0))
				and (tg==nil or tg(e,tp,Group.CreateGroup(),PLAYER_NONE,0,e,REASON_EFFECT,PLAYER_NONE,0)) then
				table.insert(available_effs,eff)
			end
		end
	end
	e:SetLabelObject(available_effs)
end
function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		local eff=e:GetLabelObject()
		return eff and eff:GetTarget() and eff:GetTarget()(e,tp,eg,ep,ev,re,r,rp,0,chkc)
	end
	if chk==0 then return true end
	local eff=nil
	local available_effs=e:GetLabelObject()
	if #available_effs>1 then
		local available_effs_desc={}
		for _,eff in ipairs(available_effs) do
			table.insert(available_effs_desc,eff:GetDescription())
		end
		local op=Duel.SelectOption(tp,table.unpack(available_effs_desc))
		eff=available_effs[op+1]
	else
		eff=available_effs[1]
	end
	Duel.Hint(HINT_OPSELECTED,1-tp,eff:GetDescription())
	e:SetLabel(eff:GetLabel())
	e:SetLabelObject(eff:GetLabelObject())
	e:SetProperty(eff:IsHasProperty(EFFECT_FLAG_CARD_TARGET) and EFFECT_FLAG_CARD_TARGET or 0)
	local tg=eff:GetTarget()
	if tg then
		tg(e,tp,eg,ep,ev,re,r,rp,1)
	end
	eff:SetLabel(e:GetLabel())
	eff:SetLabelObject(e:GetLabelObject())
	e:SetLabelObject(eff)
	Duel.ClearOperationInfo(0)
end
function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	local eff=e:GetLabelObject()
	if not eff then return end
	e:SetLabel(eff:GetLabel())
	e:SetLabelObject(eff:GetLabelObject())
	local op=eff:GetOperation()
	if op then
		op(e,tp,Group.CreateGroup(),PLAYER_NONE,0,e,REASON_EFFECT,PLAYER_NONE)
	end
	e:SetLabel(0)
	e:SetLabelObject(nil)
end