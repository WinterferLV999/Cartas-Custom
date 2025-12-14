--ＴＨＥ ＳＵＮ ＯＦ ＧＯＤ ＤＲＡＧＯＮ
--マイケル・ローレンス・ディーによってスクリプト
Duel.EnableUnofficialProc(PROC_DIVINE_HIERARCHY,PROC_RA_DEFUSION)
Duel.EnableUnofficialProc(PROC_RA_DEFUSION)
local s,id=GetID()
function s.initial_effect(c)
	--Summon With 3 Tributes
	local e1=aux.AddNormalSummonProcedure(c,true,false,3,3)
	local e2=aux.AddNormalSetProcedure(c,true,false,3,3)
	--Destroy Equip
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_EQUIP)
	e3:SetOperation(s.eqop)
	c:RegisterEffect(e3)
	--Control of this card cannot switch
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_CANNOT_CHANGE_CONTROL)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	c:RegisterEffect(e4)
	--Effect immunity
	local e5=e4:Clone()
	e5:SetCode(EFFECT_IMMUNE_EFFECT)
	e5:SetValue(s.efilter)
	c:RegisterEffect(e3)
	local e6=e5:Clone()
	e6:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e6:SetValue(aux.cannotmatfilter(SUMMON_TYPE_FUSION,SUMMON_TYPE_RITUAL))
	c:RegisterEffect(e6)
	--Last for 1 turn & block
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e7:SetCode(EVENT_TURN_END)
	e7:SetRange(LOCATION_MZONE)
	e7:SetOperation(s.stgop)
	c:RegisterEffect(e7)
	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e8:SetCode(EVENT_SPSUMMON_SUCCESS)
	e8:SetOperation(s.spchk)
	c:RegisterEffect(e8)
	--Unstoppable Attack
	local e9=Effect.CreateEffect(c)
	e9:SetType(EFFECT_TYPE_SINGLE)
	e9:SetCode(EFFECT_UNSTOPPABLE_ATTACK)
	e9:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e9:SetRange(LOCATION_MZONE)
	e9:SetCondition(function(e) return e:GetHandler():IsSpecialSummoned() end)
	c:RegisterEffect(e9)
	--Stats when Normal Summoned
	local e10=Effect.CreateEffect(c)
	e10:SetType(EFFECT_TYPE_SINGLE)
	e10:SetCode(EFFECT_MATERIAL_CHECK)
	e10:SetValue(s.valcheck)
	c:RegisterEffect(e10)
	local e11=Effect.CreateEffect(c)
	e11:SetType(EFFECT_TYPE_SINGLE)
	e11:SetCode(EFFECT_SUMMON_COST)
	e11:SetOperation(function() e10:SetLabel(1) end)
	c:RegisterEffect(e11)
	--Point-to-Point Transfer
	local e12=Effect.CreateEffect(c)
	e12:SetDescription(aux.Stringid(id,0))
	e12:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e12:SetType(EFFECT_TYPE_IGNITION)
	e12:SetProperty(EFFECT_FLAG_NO_TURN_RESET)
	e12:SetCountLimit(1,0,EFFECT_COUNT_CODE_SINGLE)
	e12:SetRange(LOCATION_MZONE)
	e12:SetCondition(s.spconnn)
	e12:SetCost(s.payatkcost)
	e12:SetOperation(s.payatkop)
	c:RegisterEffect(e12)
	--Resurrection
	local e13=Effect.CreateEffect(c)
	e13:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e13:SetCode(EVENT_SPSUMMON_SUCCESS)
	e13:SetCondition(function(e) return e:GetHandler():IsPreviousLocation(LOCATION_GRAVE) end)
	e13:SetTarget(s.immortal)
	c:RegisterEffect(e13)
	--reg
	local e14=Effect.CreateEffect(c)
	e14:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e14:SetCode(EVENT_SPSUMMON_SUCCESS)
	e14:SetOperation(s.regoppp)
	c:RegisterEffect(e14)
end
function s.spconnn(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id)==0
end
function s.regoppp(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(id+1,RESET_EVENT|RESET_TOGRAVE|PHASE_END,0,1)
end
--Local No.3
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Destroy(eg:Filter(function(ec) return ec:GetEquipTarget()==c end,nil),REASON_EFFECT)
end
function s.leaveChk(c,category)
	local ex,tg=Duel.GetOperationInfo(0,category)
	return ex and tg~=nil and tg:IsContains(c)
end
--Local No.5,6
function s.efilter(e,te,c)
	local c=e:GetOwner()
	local tc=te:GetOwner()
	return (te:IsTrapEffect() and te:IsActivated())
		or (((te:IsSpellEffect() and te:IsHasProperty(EFFECT_FLAG_CARD_TARGET) and Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):IsContains(c))
		or (te:IsMonsterEffect() and tc~=c and not tc:IsOriginalAttribute(ATTRIBUTE_DIVINE)))
		and ((c:GetDestination()>0 and c:GetReasonEffect()==te)
		or (s.leaveChk(c,CATEGORY_TOHAND) or s.leaveChk(c,CATEGORY_DESTROY) or s.leaveChk(c,CATEGORY_REMOVE)
		or s.leaveChk(c,CATEGORY_TODECK) or s.leaveChk(c,CATEGORY_RELEASE) or s.leaveChk(c,CATEGORY_TOGRAVE))))
end
--Local No.7
function s.stgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local effs={c:GetCardEffect()}
	for _,eff in ipairs(effs) do
		if eff:GetOwner()~=c and not eff:GetOwner():IsCode(0)
			and not eff:IsHasProperty(EFFECT_FLAG_IGNORE_IMMUNE) and eff:GetCode()~=EFFECT_SPSUMMON_PROC
			and (eff:GetTarget()==aux.PersistentTargetFilter or not eff:IsHasType(EFFECT_TYPE_GRANT+EFFECT_TYPE_FIELD)) then
			eff:Reset()
		end
	end
end
--Local No.8
function s.spchk(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if re and (re:IsSpellEffect() or re:IsMonsterEffect()) then
		local prevCtrl=c:GetPreviousControler()
		aux.DelayedOperation(c,PHASE_END,id,e,tp,function()
			if c:IsPreviousLocation(LOCATION_GRAVE) then
				Duel.SendtoGrave(c,REASON_EFFECT,prevCtrl)
			elseif c:IsPreviousLocation(LOCATION_DECK) then
				Duel.SendtoDeck(c,prevCtrl,SEQ_DECKSHUFFLE,REASON_EFFECT)
			elseif c:IsPreviousLocation(LOCATION_HAND) then
				Duel.SendtoHand(c,prevCtrl,REASON_EFFECT)
			elseif c:IsPreviousLocation(LOCATION_REMOVED) then
				Duel.Remove(c,c:GetPreviousPosition(),REASON_EFFECT,prevCtrl)
			elseif c:GetPreviousLocation()==0 then
				Duel.RemoveCards(c)
			end
		end,nil,0)
	end
	if c:IsAttackPos() then return end
	local ac=Duel.GetAttacker()
	if Duel.CheckEvent(EVENT_ATTACK_ANNOUNCE) and ac:CanAttack()
		and ac:GetAttackableTarget():IsContains(c)
		and Duel.SelectEffectYesNo(tp,c,aux.Stringid(68823957,0)) then
		Duel.HintSelection(c,true)
		Duel.ChangeAttackTarget(c)
	end
	local te,tg=Duel.GetChainInfo(ev+1,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TARGET_CARDS)
	if te and te~=re and te:IsHasProperty(EFFECT_FLAG_CARD_TARGET) and #tg==1
		and c:IsCanBeEffectTarget(te) and Duel.SelectEffectYesNo(tp,c,aux.Stringid(68823957,1)) then
		Duel.ChangeTargetCard(ev+1,Group.FromCards(c))
	end
end
-------------------------------------------
--Local No.10
--Stats When Normal Summoned
function s.valcheck(e,c)
	local mg=c:GetMaterial()
	local atk=0
	local def=0
	for tc in mg:Iter() do
		local catk=tc:GetAttack()
		local cdef=tc:GetDefense()
		atk=atk+(catk>=0 and catk or 0)
		def=def+(cdef>=0 and cdef or 0)
	end
	if e:GetLabel()==1 then
		e:SetLabel(0)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_BASE_ATTACK)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetValue(atk)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD&~RESET_TOFIELD)
		c:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_SET_BASE_DEFENSE)
		e2:SetValue(def)
		c:RegisterEffect(e2)
	end
end
-------------------------------------------
--Local No.13
--Resurrection
function s.immortal(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local op=Duel.SelectEffect(tp,
		{s.payatkcost(e,tp,eg,ep,ev,re,r,rp,0),aux.Stringid(id,0)},
		{true,aux.Stringid(id,1)},
		{true,aux.Stringid(id,2)})
	if op==1 then
		s.payatkcost(e,tp,eg,ep,ev,re,r,rp,1)
		e:SetOperation(s.payatkop)
	elseif op==2 then
		e:SetOperation(s.egpop)
	else
		e:SetOperation(nil)
	end
end
-------------------------------------------
--One Turn Kill
function s.payatkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local lpCost=Duel.GetLP(tp)-1
	if chk==0 then return lpCost>0 and Duel.CheckLPCost(tp,lpCost) end
	e:SetLabel(lpCost)
	Duel.PayLPCost(tp,lpCost)
end
function s.payatkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local lp=e:GetLabel()
	if c:IsFaceup() then
		--Fuse ATK/DEF
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_BASE_ATTACK)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCondition(s.dfcon)
		e1:SetValue(c:GetBaseAttack()+lp)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_SET_BASE_DEFENSE)
		e2:SetValue(c:GetBaseDefense()+lp)
		c:RegisterEffect(e2)
		--Treated as Fusion
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_ADD_TYPE)
		e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e3:SetCondition(s.dfcon)
		e3:SetValue(TYPE_FUSION)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e3)
		--Tribute for stats
		local e4=Effect.CreateEffect(c)
		e4:SetDescription(aux.Stringid(id,3))
		e4:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
		e4:SetType(EFFECT_TYPE_QUICK_O)
		e4:SetCode(EVENT_FREE_CHAIN)
		e4:SetRange(LOCATION_MZONE)
		e4:SetCondition(s.dfcon)
		e4:SetCost(s.tatkcost)
		e4:SetOperation(s.tatkop)
		e4:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e4)
		--LP is stats
		local e5=Effect.CreateEffect(c)
		e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e5:SetCode(EVENT_RECOVER)
		e5:SetRange(LOCATION_MZONE)
		e5:SetCondition(s.dfcon)
		e5:SetOperation(s.atkop1)
		e5:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e5)
		local e6=Effect.CreateEffect(c)
		e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e6:SetCode(EVENT_CHAIN_END)
		e6:SetRange(LOCATION_MZONE)
		e6:SetCondition(s.dfcon)
		e6:SetOperation(s.atkop2)
		e6:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e6)
		--Attack all
		local e7=Effect.CreateEffect(c)
		e7:SetType(EFFECT_TYPE_FIELD)
		e7:SetRange(LOCATION_MZONE)
		e7:SetTargetRange(0,LOCATION_MZONE)
		e7:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_CANNOT_DISABLE)
		e7:SetCode(EFFECT_CANNOT_BE_BATTLE_TARGET)
		e7:SetCondition(s.dfcon)
		e7:SetTarget(function(_e,_c) return _c:GetFlagEffect(id+100)>0 end)
		e7:SetValue(function(_e,_c) return _c==_e:GetHandler() end)
		e7:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e7)
		local e8=Effect.CreateEffect(c)
		e8:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
		e8:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e8:SetCode(EVENT_DAMAGE_STEP_END)
		e8:SetCondition(s.dfcon)
		e8:SetOperation(s.dirop)
		e8:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e8)
		local e9=Effect.CreateEffect(c)
		e9:SetType(EFFECT_TYPE_SINGLE)
		e9:SetCode(EFFECT_EXTRA_ATTACK)
		e9:SetValue(9999)
		e9:SetCondition(s.dfcon)
		e9:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e9)
		local e10=Effect.CreateEffect(c)
		e10:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
		e10:SetCode(EVENT_DAMAGE_STEP_END)
		e10:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e10:SetCondition(s.dfcon)
		e10:SetOperation(s.unop)
		e10:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e10)
	end
end
function s.dfcon(e)
	if e:GetHandler():HasFlagEffect(FLAG_RA_DEFUSION) then
		e:Reset()
		return false
	end
	return true
end
function s.atkop1(e,tp,eg,ep,ev,re,r,rp)
	if ep==1-tp then return end
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_COPY_INHERIT)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetCondition(s.dfcon)
	e1:SetValue(ev)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)
	Duel.SetLP(tp,1,REASON_EFFECT)
end
function s.atkop2(e,tp,eg,ep,ev,re,r,rp)
	local lp=Duel.GetLP(tp)
	if lp<=1 then return end
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_COPY_INHERIT)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetCondition(s.dfcon)
	e1:SetValue(lp-1)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)
	Duel.SetLP(tp,1,REASON_EFFECT)
end
function s.tatkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,nil,1,false,nil,e:GetHandler()) end
	local g=Duel.SelectReleaseGroupCost(tp,nil,1,99,false,nil,e:GetHandler())
	local suma=0
	local sumd=0
	for tc in g:Iter() do
		suma=suma+tc:GetAttack()
		sumd=sumd+tc:GetDefense()
	end
	e:SetLabel(suma,sumd)
	Duel.Release(g,REASON_COST)
end
function s.tatkop(e,tp,eg,ep,ev,re,r,rp)
	if not s.dfcon(e) then return end
	local c=e:GetHandler()
	local atk,def=e:GetLabel()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetCondition(s.dfcon)
	e1:SetValue(atk)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	e2:SetCondition(s.dfcon)
	e2:SetValue(def)
	e2:SetReset(RESET_EVENT|RESETS_STANDARD)
	c:RegisterEffect(e2)
end
function s.unop(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetHandler():GetBattleTarget()
	if bc and bc:IsRelateToBattle() then
		bc:RegisterFlagEffect(id+100,RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_BATTLE,0,1)
	end
end
function s.dirop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.GetAttackTarget() then
		local c=e:GetHandler()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_CANNOT_DIRECT_ATTACK)
		e1:SetCondition(s.dfcon)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_BATTLE)
		c:RegisterEffect(e1)
	end
end
-------------------------------------------
--God Phoenix
function s.egpop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() then
		--Treated as God Phoenix
		local e0=Effect.CreateEffect(c)
		e0:SetType(EFFECT_TYPE_SINGLE)
		e0:SetCode(EFFECT_CHANGE_CODE)
		e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e0:SetValue(511000237)
		e0:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e0)
		--Immunities
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_INDESTRUCTABLE)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_IMMUNE_EFFECT)
		e2:SetValue(s.imfilter)
		c:RegisterEffect(e2)
		local e3=e1:Clone()
		e3:SetCode(EFFECT_CANNOT_BE_MATERIAL)
		e3:SetValue(aux.cannotmatfilter(SUMMON_TYPE_FUSION,SUMMON_TYPE_RITUAL))
		c:RegisterEffect(e3)
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
		e4:SetValue(1)
		e4:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e4)
		--Send to Graveyard
		local e5=Effect.CreateEffect(c)
		e5:SetDescription(aux.Stringid(id,4))
		e5:SetCategory(CATEGORY_TOGRAVE)
		e5:SetType(EFFECT_TYPE_QUICK_O)
		e5:SetCode(EVENT_FREE_CHAIN)
		e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
		e5:SetRange(LOCATION_MZONE)
		e5:SetCondition(s.tgcon)
		e5:SetCost(s.tgcost)
		--e5:SetTarget(s.tgtg)
		--e5:SetOperation(s.tgop)
	    e5:SetOperation(s.chop1)
		e5:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e5)
	end
end
function s.leaveChk(c,category)
	local ex,tg=Duel.GetOperationInfo(0,category)
	return ex and tg~=nil and tg:IsContains(c)
end
function s.imfilter(e,te)
	local c=e:GetOwner()
	return (c:GetDestination()>0 and c:GetReasonEffect()==te)
		or (s.leaveChk(c,CATEGORY_TOHAND) or s.leaveChk(c,CATEGORY_DESTROY) or s.leaveChk(c,CATEGORY_REMOVE)
		or s.leaveChk(c,CATEGORY_TODECK) or s.leaveChk(c,CATEGORY_RELEASE) or s.leaveChk(c,CATEGORY_TOGRAVE))
end
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsHasEffect(EFFECT_UNSTOPPABLE_ATTACK) or (not c:IsHasEffect(EFFECT_CANNOT_ATTACK_ANNOUNCE)
		and not c:IsHasEffect(EFFECT_FORBIDDEN) and not c:IsHasEffect(EFFECT_CANNOT_ATTACK)
		and not Duel.IsPlayerAffectedByEffect(tp,EFFECT_CANNOT_ATTACK_ANNOUNCE)
		and not Duel.IsPlayerAffectedByEffect(tp,EFFECT_CANNOT_ATTACK))
end
function s.tgcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc~=e:GetHandler() end
	if chk==0 then return Duel.IsExistingTarget(nil,tp,LOCATION_MZONE,LOCATION_MZONE,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectTarget(tp,nil,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,e:GetHandler())
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
end
function s.chop1(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(nil,tp,LOCATION_MZONE,LOCATION_MZONE,e:GetHandler())
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=g:Select(tp,1,1,nil)
		Duel.HintSelection(sg)
		Duel.SendtoGrave(sg,REASON_RULE,PLAYER_NONE,tp)
	end
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) then return end
	if not tc:GetFlagEffectLabel(513000065)
		or (c:GetFlagEffectLabel(513000065) and c:GetFlagEffectLabel(513000065)>=tc:GetFlagEffectLabel(513000065)) then
		e:SetProperty(e:GetProperty()|EFFECT_FLAG_IGNORE_IMMUNE)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_CHAIN)
		tc:RegisterEffect(e1,true)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_CHAIN)
		tc:RegisterEffect(e2,true)
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetRange(LOCATION_MZONE)
		e3:SetCode(EFFECT_IMMUNE_EFFECT)
		e3:SetValue(function(e,te) return te:GetOwner()~=e:GetOwner() end)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_CHAIN)
		tc:RegisterEffect(e3,true)
		Duel.AdjustInstantly(c)
	end
	Duel.SendtoGrave(tc,REASON_EFFECT)
	e:SetProperty(e:GetProperty()&~EFFECT_FLAG_IGNORE_IMMUNE)
end