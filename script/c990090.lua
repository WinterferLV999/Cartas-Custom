local s,id=GetID()
function s.initial_effect(c)
	-- 1. EFECTO PRINCIPAL: Negar y destruir (Se activa en cadena)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
	
	-- 2. REGLA ESPECIAL REPARADA: Permite activar la trampa el mismo turno que es colocada (Set Turn)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetCondition(s.actcon)
	e2:SetDescription(aux.Stringid(id,1))
	c:RegisterEffect(e2)
	--Banish from the GY to Special Summon "Blue-Eyes White Dragon"
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCost(Cost.SelfBanish)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- Lista de series indexadas oficialmente en la base de datos
s.listed_series={SET_BLUE_EYES}
s.listed_names={CARD_BLUEEYES_W_DRAGON}

-- Filtro ①: Para la activación general de la carta (Exige un Monstruo de Fusión Blue-Eyes)
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_BLUE_EYES) and c:IsType(TYPE_FUSION)
end

-- Filtro ②: Para el bypass de velocidad (Exige un Monstruo Normal Blue-Eyes)
function s.actfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_BLUE_EYES) and c:IsType(TYPE_NORMAL)
end

-- =========================================================================
-- --- ADUANAS DE VERIFICACIÓN DE HARDWARE EN LA MESA                      ---
-- =========================================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- Solo se puede activar la trampa si el efecto es del rival, es negable y controlas la Fusión Blue-Eyes
	return rp~=tp and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.actcon(e)
	-- Abre el candado del Set Turn si controlas al menos un Monstruo Normal "Blue-Eyes" boca arriba
	return Duel.IsExistingMatchingCard(s.acfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

-- =========================================================================
-- --- PROCESO INTERACTIVO DE NEGACIÓN Y ESCUDO GLOBAL                    ---
-- =========================================================================
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	local rc=re:GetHandler()
	if rc:IsDestructable() and rc:IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	
	if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) then
		local code=rc:GetOriginalCodeRule()
		
		if Duel.Destroy(eg,REASON_EFFECT)>0 then
			-- e1: Apaga de forma continua monstruos con ese nombre en la mesa
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
			e1:SetTarget(s.distg)
			e1:SetLabel(code)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
			
			-- e2: Intercepta y niega cualquier efecto con ese nombre en GY, Mano o Destierro
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e2:SetCode(EVENT_CHAIN_SOLVING)
			e2:SetCondition(s.discon)
			e2:SetOperation(s.disop)
			e2:SetLabel(code)
			e2:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e2,tp)
		end
	end
end

function s.distg(e,c)
	local code=e:GetLabel()
	local code1,code2=c:GetOriginalCodeRule()
	return code1==code or code2==code
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()
	local code1,code2=re:GetHandler():GetOriginalCodeRule()
	return code1==code or code2==code
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.NegateEffect(ev)
end

function s.spfilter(c,e,tp)
	return c:IsCode(CARD_BLUEEYES_W_DRAGON) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK|LOCATION_HAND|LOCATION_GRAVE,0,1,nil,e,tp) end
	local count=(Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 and Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0) and 2 or 0
	e:SetLabel(count)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_HAND|LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft==0 then return end
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK|LOCATION_HAND|LOCATION_GRAVE,0,nil,e,tp)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=g:Select(tp,1,1,nil):GetFirst()
	if Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	ft=ft-1
	g:RemoveCard(sc)
	if ft>0 and #g>0 and e:GetLabel()>0 and Duel.IsPlayerCanSpecialSummonCount(tp,1) and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		ft=Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) and 1 or ft
		ft=math.min(ft,2)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=g:Select(tp,1,ft,nil)
		if #sg>0 then
			Duel.BreakEffect()
			Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end