local s,id=GetID()
function s.initial_effect(c)
	c:AddSetcodesRule(id,false,0x601)
	--dark synchro summon Procedure: 1 non-Tuner monsters - 1 dark tuner monster
	c:EnableReviveLimit()
	Synchro.AddDarkSynchroProcedure(c,Synchro.NonTuner(nil),nil,8) -- Parámetro nativo de resta de nivel fijo = 8 (12 - 4 = 8)
	
	-- =========================================================================
	-- ---   EFECTO NUEVO ①: CLONADO DE IDENTIDAD DE REGLA (STARDUST DRAGON)   ---
	-- =========================================================================
	-- Esta carta es tratada como Stardust Dragon (ID: 44508094) en todas las locaciones (Campo, GY, Extra Deck, Destierro)
	-- EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE aseguran que ninguna carta del meta pueda apagar esta ley.
	local e_name=Effect.CreateEffect(c)
	e_name:SetType(EFFECT_TYPE_SINGLE)
	e_name:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e_name:SetCode(EFFECT_CHANGE_CODE)
	e_name:SetRange(LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA)
	e_name:SetValue(44508094) -- ID Oficial de Konami para Stardust Dragon
	c:RegisterEffect(e_name)
	
	--Must first be Synchro Summoned with the above materials
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
	
	--Must be Special Summoned (from your Extra Deck) by sending 2 monsters you control with a Level difference of 8 to the GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.sprcon)
	e1:SetTarget(s.sprtg)
	e1:SetOperation(s.sprop)
	e1:SetValue(SUMMON_TYPE_SYNCHRO)
	c:RegisterEffect(e1)
	
	--treat 1 Tuner you control as a Dark Tuner
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_ADD_SETCODE)
	e2:SetRange(LOCATION_EXTRA) 
	e2:SetTargetRange(LOCATION_MZONE,0) 
	e2:SetTarget(s.synchron_to_darktuner_radar)
	e2:SetValue(1536) -- El entero plano 1536 (0x600) de Dark Tuner
	c:RegisterEffect(e2)
	
	-- RADAR A: Se dispara ante la declaración de ataque del oponente (EVENT_ATTACK_ANNOUNCE)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetRange(LOCATION_MZONE) -- 0x4 = LOCATION_MZONE
	e3:SetCountLimit(1,0,EFFECT_COUNT_CODE_SINGLE)
	e3:SetCondition(s.atkcon)
	e3:SetTarget(s.rmtg)
	e3:SetOperation(s.rmop)
	c:RegisterEffect(e3)
	
	-- RADAR B: Clonado idéntico que reacciona en cadena a efectos de cartas del oponente (EVENT_CHAINING)
	local e4=e3:Clone()
	e4:SetCode(EVENT_CHAINING)
	e4:SetCondition(s.rmcon2)
	c:RegisterEffect(e4)
	
	-- TU SEGUNDO EFECTO DE INTEGRACIÓN: Revive al final de cada turno (TRIGGER_O)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_FIELD)
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetCode(EVENT_PHASE+PHASE_END)
	e5:SetRange(LOCATION_REMOVED)
	e5:SetCountLimit(1)
	e5:SetCondition(s.sscon)
	e5:SetTarget(s.sstg)
	e5:SetOperation(s.ssop)
	c:RegisterEffect(e5)
end

function s.splimit(e,se,sp,st)
	return not e:GetHandler():IsLocation(LOCATION_EXTRA) or ((st&SUMMON_TYPE_SYNCHRO)==SUMMON_TYPE_SYNCHRO and not se)
end

-- =========================================================================
-- ---         MATEMÁTICA DE INVOCACIÓN POR RESTA DARK SYNCHRO             ---
-- =========================================================================
function s.sprfilter(c)
	return c:IsFaceup() and c:IsAbleToGraveAsCost() and c:HasLevel()
end

function s.sprfilter1(c,tp,g,sc)
	return not c:IsType(TYPE_TUNER) and g:IsExists(s.sprfilter2,1,c,tp,c,sc)
end

function s.sprfilter2(c,tp,mc,sc)
	local sg=Group.FromCards(c,mc)
	return (math.abs(mc:GetLevel()-c:GetLevel())==8) and c:IsType(TYPE_TUNER) 
		and s.synchron_to_darktuner_radar(nil,c) and Duel.GetLocationCountFromEx(tp,tp,sg,sc)>0
end

function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.sprfilter,tp,LOCATION_MZONE,0,nil)
	return g:IsExists(s.sprfilter1,1,nil,tp,g,c)
end

function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.sprfilter,tp,LOCATION_MZONE,0,nil)
	local g1=g:Filter(s.sprfilter1,nil,tp,g,c)
	local mg1=aux.SelectUnselectGroup(g1,e,tp,1,1,nil,1,tp,HINT_SELECTMSG,nil,nil,true)
	if #mg1>0 then
		local mc=mg1:GetFirst()
		local g2=g:Filter(s.sprfilter2,mc,tp,mc,c)
		local mg2=aux.SelectUnselectGroup(g2,e,tp,1,1,nil,1,tp,HINT_SELECTMSG,nil,nil,true)
		mg1:Merge(mg2)
	end
	if #mg1==2 then
		mg1:KeepAlive()
		e:SetLabelObject(mg1)
		return true
	end
	return false
end

function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.SendtoGrave(g,REASON_COST)
end

-- Lista de IDs de los monstruos Cantantes "Synchron" e "Junk" estables de tu mazo
s.synchron_tuners={
	63977036, -- Junk Synchron
	9742784,  -- Jet Synchron
	25165047, -- Majestic Dragon / Synchron de la Nueva Alianza
	35952884, -- Formula Synchron
	70238111, -- Bri Synchron
	50265626, -- Quickdraw Synchron
	37799519  -- Tu ID de biblioteca agregada
}

function s.synchron_to_darktuner_radar(e,c)
	if not (c:IsFaceup() and c:IsType(TYPE_TUNER)) then return false end
	local code=c:GetCode()
	for _,sync_id in ipairs(s.synchron_tuners) do
		if code==sync_id then
			return true 
		end
	end
	return false
end

-- =========================================================================
-- ---        CONDICIONALES DE DISPARO DEL REMATE MASIVO                 ---
-- =========================================================================
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return Duel.GetAttacker():IsControler(1-tp) and Duel.GetAttackTarget()==c
end

function s.rmcon2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsStatus(STATUS_BATTLE_DESTROYED) or rp~=1-tp then return false end
	
	local ex1,tg1,tc1=Duel.GetOperationInfo(ev,CATEGORY_TOHAND)
	local ex2,tg2,tc2=Duel.GetOperationInfo(ev,CATEGORY_TODECK)
	local ex3,tg3,tc3=Duel.GetOperationInfo(ev,CATEGORY_TOGRAVE)
	local ex4,tg4,tc4=Duel.GetOperationInfo(ev,CATEGORY_REMOVE)
	local ex5,tg5,tc5=Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
	
	local is_target = (tg1 and tg1:IsContains(c)) or (tg2 and tg2:IsContains(c)) 
		or (tg3 and tg3:IsContains(c)) or (tg4 and tg4:IsContains(c)) or (tg5 and tg5:IsContains(c))
		or (Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS) and Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS):IsContains(c))
		
	return is_target or ex1 or ex2 or ex3 or ex4 or ex5
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemove() end
	
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil)
	g:AddCard(c)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil)
	
	if c:IsRelateToEffect(e) and c:IsAbleToRemove() then 
		g:AddCard(c) 
	end
	
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end

-- =========================================================================
-- ---         TU BLOQUE DE RETORNO EXACTO INTEGRADO DE FORMA SEGURA      ---
-- =========================================================================
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
	return tp==Duel.GetTurnPlayer()
end

function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetFlagEffect(id+1)==0 end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	e:GetHandler():RegisterFlagEffect(id+1,RESET_EVENT+0x4760000+RESET_PHASE+PHASE_END,0,1)
end

function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
			Duel.SendtoGrave(c,REASON_EFFECT)
			return
		end
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end
