local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	c:EnableUnsummonable()
	local e_lock=Effect.CreateEffect(c)
	e_lock:SetType(EFFECT_TYPE_SINGLE)
	e_lock:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e_lock:SetCode(EFFECT_SPSUMMON_CONDITION)
	--e_lock:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e_lock:SetValue(s.splimit) 
	c:RegisterEffect(e_lock)
	-- level/rank
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_RANK_LEVEL_S)
	c:RegisterEffect(e0)
	-- PROCEDIMIENTO ÚNICO DE INVOCACIÓN (EFFECT_SPSUMMON_PROC)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.hspcon)
	e1:SetTarget(s.hsptg)
	e1:SetOperation(s.hspop)
	c:RegisterEffect(e1)
	-- prevent effect activation (Inmunidad y Congelación de campo del rival)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.cpcon)
	e2:SetCost(s.cost)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
	-- copy (Absorción de ATK, negación y clonación de efectos de tu código)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCost(s.costt)
	e3:SetTarget(s.atktg)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
	-- destroy and damage (Venganza masiva al dejar el campo por efecto rival)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,3))
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetProperty(EFFECT_FLAG_DELAY)
	e6:SetCode(EVENT_LEAVE_FIELD)
	e6:SetCountLimit(1,id)
	e6:SetCondition(s.pencon)
	e6:SetTarget(s.pentg)
	e6:SetOperation(s.penop)
	c:RegisterEffect(e6)
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e7:SetCode(EFFECT_ADD_SETCODE)
	e7:SetValue(0x13b)
	c:RegisterEffect(e7)
end
function s.splimit(e,se,sp,st)
	--return se and se:GetHandler()==e:GetHandler()
	return se and se:GetCode()~=EFFECT_SPSUMMON_PROC
	--return se and se:GetHandler()==e:GetHandler() and (st&SUMMON_TYPE_SPECIAL)==0
end
-- --- LOCAL No.1: REQUISITOS FÍSICOS DE SUPERPOSICIÓN DE MATERIALES ---
function s.hspfilter(c,tp,sc)
	return c:IsMonster() and c:IsFaceup() and c:IsCode(16195942,41209827)
		and Duel.GetLocationCountFromEx(tp,tp,c,sc)>0
end

function s.hspcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.hspfilter,tp,LOCATION_MZONE,0,2,nil,tp,c)
end

function s.hsptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	if chk==0 then return true end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,s.hspfilter,tp,LOCATION_MZONE,0,2,99,nil,tp,c)
	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end

function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	local ov_group=Group.CreateGroup()
	local tc=g:GetFirst()
	while tc do
		if tc:GetOverlayCount()~=0 then 
			ov_group:Merge(tc:GetOverlayGroup())
		end
		tc=g:GetNext()
	end
	c:SetMaterial(g)
	Duel.Overlay(c,g)
	if #ov_group>0 then
		Duel.Overlay(c,ov_group)
	end
	g:DeleteGroup()
	ov_group:DeleteGroup()
end

-- --- LOCAL No.2: DETONADOR DEL AURA DE INMUNIDAD ---
function s.cpcon(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsTurnPlayer(1-tp) then return false end
	return Duel.IsMainPhase() and e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,16195942)
end
function s.effilter(e,te)
	return te:GetOwner()~=e:GetOwner() and te:IsMonsterEffect() and te:GetHandler():IsLevelAbove(5)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetFlagEffect(id)==0 end
	e:GetHandler():RegisterFlagEffect(id,RESETS_STANDARD_PHASE_END,0,1)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,4))
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_OATH+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetValue(s.effilter)
	e1:SetReset(RESETS_STANDARD_PHASE_END)
	e:GetHandler():RegisterEffect(e1,true)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetTargetRange(0,1)
	e2:SetValue(1)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

-- --- LOCAL No.3: ABSORCIÓN DE COMBATE Y COPIA DE IDENTIDAD ---
function s.costt(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		tc:NegateEffects(c,RESETS_STANDARD_PHASE_END)
		local atk=tc:GetAttack()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetReset(RESETS_STANDARD_PHASE_END)
		e1:SetValue(math.ceil(atk/2))
		tc:RegisterEffect(e1)
		if c:IsRelateToEffect(e) and c:IsFaceup() then
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_SET_ATTACK)
			e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e2:SetReset(RESETS_STANDARD_PHASE_END)
			e2:SetValue(c:GetAttack()*2)
			c:RegisterEffect(e2)
			local code=tc:GetOriginalCodeRule()
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e3:SetCode(EFFECT_ADD_CODE)
			e3:SetValue(code)
			e3:SetReset(RESETS_STANDARD_PHASE_END)
			c:RegisterEffect(e3)
			if not tc:IsType(TYPE_TRAPMONSTER) then
				c:CopyEffect(code,RESETS_STANDARD_PHASE_END,1)
			end
		end
	end
end

-- --- LOCAL No.6: VENGANZA AL DEJAR EL CAMPO ---
function s.pencon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and e:GetHandler():IsPreviousControler(tp)
end
function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToDestroy,tp,0,LOCATION_ONFIELD,1,nil) end
	local g2=Duel.GetMatchingGroup(Card.IsAbleToDestroy,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g2,#g2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
end
function s.penop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToDestroy,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		local ct=Duel.GetOperatedGroup():GetCount()
		Duel.Damage(1-tp,ct*1000,REASON_EFFECT)
	end
end
