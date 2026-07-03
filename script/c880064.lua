local s,id=GetID()
function s.initial_effect(c)
	--Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DAMAGE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--draw
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
	e2:SetCountLimit(1,id)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCost(aux.bfgcost)
	e2:SetCondition(s.quick_grave_condition)
	e2:SetOperation(s.spoperation)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetOperation(s.register_grave_op)
	c:RegisterEffect(e3)
end
s.listed_series={0x10f3,0x10f3}
function s.register_grave_op(e,tp,eg,ep,ev,re,r,rp)
	-- Clava un Flag en el jugador que expira estrictamente al terminar el turno actual (id+200)
	Duel.RegisterFlagEffect(tp,id+200,RESET_PHASE+PHASE_END,0,1)
end

function s.quick_grave_condition(e,tp,eg,ep,ev,re,r,rp)
	-- REGLA DE EXCLUSIÓN: Solo permite la activación si el Flag de caída (id+200) NO existe en la memoria
	-- Esto prohíbe activar el efecto en el mismo turno que fue enviada al cementerio
	return aux.exccon(e,tp,eg,ep,ev,re,r,rp) and Duel.GetFlagEffect(tp,id+200)==0
end
--local no.1
function s.counterfilter(c)
	return c:IsSetCard(0x10f3) or c:IsSetCard(0x10f3)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,800)
		and Duel.GetCustomActivityCount(id,tp,ACTIVITY_SUMMON)==0
		and Duel.GetCustomActivityCount(id,tp,ACTIVITY_SPSUMMON)==0 end
	--Cannot Special Summon monsters from the Extra Deck, except Plant monsters
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(_e,_c) return _c:IsLocation(LOCATION_EXTRA) and not _c:IsRace(RACE_PLANT) and not _c:IsRace(RACE_DRAGON) end)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
	aux.RegisterClientHint(e:GetHandler(),nil,tp,1,0,aux.Stringid(id,1),nil)
	Duel.PayLPCost(tp,800)
end
function s.sumlimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not (c:IsSetCard(0x10f3) or c:IsSetCard(0x10f3))
end
function s.filter1(c,e,tp)
	return not c:IsType(TYPE_FUSION) and c:IsSetCard(0x10f3) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
		and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_DECK,0,1,nil,e,tp,c:GetLevel())
end
function s.filter2(c,e,tp,lv)
	return c:IsSetCard(0x10f3) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.filter1(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>1 and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
		and Duel.IsExistingTarget(s.filter1,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.filter1,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,2,tp,LOCATION_GRAVE+LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 or Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local dg=Duel.SelectMatchingCard(tp,s.filter2,tp,LOCATION_DECK,0,1,1,nil,e,tp,tc:GetLevel())
		if #dg==0 then return end
		local g=Group.FromCards(tc,dg:GetFirst())
		for sc in aux.Next(g) do
			Duel.SpecialSummonStep(sc,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
		end
		Duel.SpecialSummonComplete()
	end
end


--local no.2


function s.spoperation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- EFECTO ①: Captura Invocaciones Especiales fuera de cadena (Sincronía, Péndulo, Contacto de AMBOS)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.drcon1)
	e1:SetOperation(s.drop1)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
	
	-- EFECTO ②: Registra Invocaciones Especiales que ocurren en cadena activa de AMBOS
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.regcon)
	e2:SetOperation(s.regop)
	e2:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e2,tp)
	
	-- EFECTO ③: Ejecuta el robo acumulado al resolverse la cadena
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e3:SetCode(EVENT_CHAIN_SOLVED)
	e3:SetCondition(s.drcon2)
	e3:SetOperation(s.drop2)
	e3:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e3,tp)
end

-- CORREGIDO: Se elimino el parametro de jugador "sp". Ahora acepta cualquier monstruo invocado especialmente de forma global.
function s.filter(c)
	return c:IsMonster()
end

-- --- 1. RESOLUCIÓN FUERA DE CADENA (PÉNDULO / SINCRONÍA / CONTACTO) ---
function s.drcon1(e,tp,eg,ep,ev,re,r,rp)
	if not eg:IsExists(s.filter,1,nil) then return false end
	if not re then return true end
	return not re:IsHasType(EFFECT_TYPE_ACTIONS) or re:IsHasType(EFFECT_TYPE_CONTINUOUS)
end

function s.drop1(e,tp,eg,ep,ev,re,r,rp)
	-- Cuenta absolutamente todos los monstruos que cayeron en este evento (tuyos y del rival)
	local count=eg:FilterCount(s.filter,nil)
	if count>0 then
		Duel.Draw(tp,count,REASON_EFFECT)
	end
end

-- --- 2. RESOLUCIÓN DENTRO DE CADENA (EFECTOS ACTIVOS) ---
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	if not eg:IsExists(s.filter,1,nil) then return false end
	if not re then return false end
	return re:IsHasType(EFFECT_TYPE_ACTIONS) and not re:IsHasType(EFFECT_TYPE_CONTINUOUS)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	-- Clava en la memoria 1 Flag por cada criatura que nacio en el eslabon sin importar el dueño
	local count=eg:FilterCount(s.filter,nil)
	for i=1,count do
		Duel.RegisterFlagEffect(tp,id,RESET_CHAIN,0,1)
	end
end

-- --- 3. CIERRE DE CADENA ---
function s.drcon2(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFlagEffect(tp,id)>0
end

function s.drop2(e,tp,eg,ep,ev,re,r,rp)
	-- Recoge el acumulado total de monstruos nacidos en la cadena, limpia y te otorga las cartas
	local n=Duel.GetFlagEffect(tp,id)
	Duel.ResetFlagEffect(tp,id)
	Duel.Draw(tp,n,REASON_EFFECT)
end