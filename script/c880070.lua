--No.107 銀河眼の時空竜 (Anime)
--Number 107: Galaxy-Eyes Tachyon Dragon (Anime)
Duel.LoadCardScript("c88177324.lua")
local s,id=GetID()
function s.initial_effect(c)
	--xyz summon
	Xyz.AddProcedure(c,nil,8,3)
	c:EnableReviveLimit()
	--battle indestructable
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e0:SetValue(aux.NOT(aux.TargetBoolFunction(Card.IsSetCard,0x48)))
	c:RegisterEffect(e0)
	--Special summon
	local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCountLimit(1)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
	--cannot destroyed
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.indcon)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetCondition(s.indcon)
	e3:SetValue(1)
	c:RegisterEffect(e3)
	--attach and negate
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(53347303,0))
	e4:SetCategory(CATEGORY_DISABLE)
	--e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.discon)
	e4:SetTarget(s.distg)
	e4:SetOperation(s.disop)
	c:RegisterEffect(e4)
	--cannot target monster for attack except this one
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTargetRange(0,LOCATION_MZONE)
	e5:SetValue(s.csbtv)
	c:RegisterEffect(e5)
	--cannot attack
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_CANNOT_ATTACK)
	e6:SetRange(LOCATION_MZONE)
	e6:SetTargetRange(LOCATION_MZONE,0)
	e6:SetTarget(s.atktg)
	c:RegisterEffect(e6)
	--chain attack
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,0))
	e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	--e7:SetCode(EVENT_DAMAGE_STEP_END)
	e7:SetCode(EVENT_BATTLED)
	--e7:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e7:SetCondition(s.con)
	e7:SetCost(s.cost)
	e7:SetOperation(s.op)
	c:RegisterEffect(e7,false,REGISTER_FLAG_DETACH_XMAT)
	--negate
	local e8=Effect.CreateEffect(c)
	e8:SetCategory(CATEGORY_DISABLE+CATEGORY_ATKCHANGE)
	e8:SetDescription(aux.Stringid(799183,0))
	e8:SetType(EFFECT_TYPE_QUICK_F)
	e8:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e8:SetRange(LOCATION_MZONE)
	e8:SetTarget(s.negtg)
	e8:SetOperation(s.negop)
	c:RegisterEffect(e8,false,REGISTER_FLAG_DETACH_XMAT)
	aux.GlobalCheck(s,function()
		--Cards that resolved effects check
		BPResolvedEffects={}
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_CHAIN_SOLVED)
		e1:SetCondition(s.regcon)
		e1:SetOperation(s.regop)
		Duel.RegisterEffect(e1,0)
		aux.AddValuesReset(function()
			BPResolvedEffects={}
		end)
	end)
end
s.xyz_number=107
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()>=PHASE_BATTLE_START and Duel.GetCurrentPhase()<=PHASE_BATTLE
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local cid=e:GetOwner():GetFieldID()
	if not BPResolvedEffects[cid] then BPResolvedEffects[cid]={} end
	for _,fid in ipairs(BPResolvedEffects[cid]) do
		if fid==re:GetHandler():GetFieldID() then return end
	end
	table.insert(BPResolvedEffects[cid],re:GetHandler():GetFieldID())
end
--Local no.1

-- Filtro para el Galaxy-Eyes que será el material
function s.cfilter(c,tp,e)
    return c:IsFaceup() and c:IsControler(tp) and c:IsType(TYPE_XYZ) and c:IsSetCard(SET_GALAXY_EYES) 
        and c:GetEquipCount()>=1 and c:IsCanBeXyzMaterial(e:GetHandler())
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
    local ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
    if not ex then return false end
    -- Pasamos "e" al final para que el filtro lo reconozca
    return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil,tp,e)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then 
        -- También pasamos "e" aquí
        return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 
            and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil,tp,e)
            and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false) 
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end

	-- 1. Seleccionamos al Galaxy-Eyes que servirá de base
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_MZONE,0,1,1,nil,tp,e)
	local tc=g:GetFirst()
	
	if tc and not tc:IsImmuneToEffect(e) then
		-- 2. Capturamos materiales previos y EQUIPOS
		local mg=tc:GetOverlayGroup()
		local eqg=tc:GetEquipGroup():Filter(Card.IsType,nil,TYPE_EQUIP)
		mg:KeepAlive()
		eqg:KeepAlive()

		-- 3. UNIMOS al Monstruo + Equipos en un solo grupo de materiales
		local materials=Group.FromCards(tc)
		materials:Merge(eqg)
		
		-- Registrar el grupo completo como materiales de esta carta
		c:SetMaterial(materials)

		-- 4. Ejecutar la INVOCACIÓN XYZ
		-- Primero movemos el monstruo y los equipos debajo de la carta (Overlay)
		Duel.Overlay(c,materials)
		
		if Duel.SpecialSummon(c,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)~=0 then
			-- 5. Acoplar los materiales antiguos que ya tenía el Galaxy-Eyes
			if #mg>0 then 
				Duel.Overlay(c,mg) 
			end
			
			c:CompleteProcedure()
		end
	end
end
--Local no.2,3,7
function s.indcon(e)
	return e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,88177324)
end
--Local no.4
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsStatus(STATUS_BATTLE_DESTROYED) or not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local loc,tg=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION,CHAININFO_TARGET_CARDS)
	if not tg or not tg:IsContains(c) then return false end
	return Duel.IsChainDisablable(ev) and loc~=LOCATION_DECK
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsType(TYPE_XYZ) end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp,chk)
	Duel.Hint(HINT_CARD,0,id)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	if c:IsType(TYPE_XYZ) then
		rc:CancelToGrave()
		Duel.Overlay(c,rc)
	end
	if Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.NegateEffect(ev)
	end
end
--Local no.5
function s.csbtv(e,c)
	return e:GetHandler()~=c
end
--Local no.6
function s.atktg(e,c)
	return not c:IsCode(88177324)
end
--Local no.7
function s.con(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return Duel.GetAttacker()==c and c:CanChainAttack(0,true)
		and e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,88177324)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,3,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,3,3,REASON_COST)
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToBattle() then return end
	Duel.ChainAttack()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_DIRECT_ATTACK)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_BATTLE+PHASE_DAMAGE_CAL)
	c:RegisterEffect(e1)
end
--Local no.8
function s.disfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_EFFECT)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.disfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,e:GetHandler()) 
	--if chk==0 then return Duel.IsExistingMatchingCard(s.disfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,e:GetHandler()) 
		or BPResolvedEffects[e:GetHandler():GetFieldID()] end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local res=false
	local g=Duel.GetMatchingGroup(s.disfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,c)
	--local g=Duel.GetMatchingGroup(s.disfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,c)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
		if not tc:IsImmuneToEffect(e1) and not tc:IsImmuneToEffect(e2) then
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_SET_ATTACK_FINAL)
			e3:SetValue(tc:GetBaseAttack())
			e3:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e3)
			local e4=Effect.CreateEffect(c)
			e4:SetType(EFFECT_TYPE_SINGLE)
			e4:SetCode(EFFECT_SET_DEFENSE_FINAL)
			e4:SetValue(tc:GetBaseDefense())
			e4:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e4)
		end
		res=true
	end
	if c:IsFacedown() or not c:IsRelateToEffect(e) then return end
	local fid=e:GetHandler():GetFieldID()
	local bpre=BPResolvedEffects[fid]
	if bpre then
		Duel.BreakEffect()
		local e5=Effect.CreateEffect(c)
		e5:SetType(EFFECT_TYPE_SINGLE)
		e5:SetCode(EFFECT_UPDATE_ATTACK)
		e5:SetValue(#bpre*1000)
		e5:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e5)
		res=true
	end
end

