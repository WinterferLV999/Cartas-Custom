local s,id=GetID()
function s.initial_effect(c)
	-- MUST BE PROPERLY SUMMONED BEFORE REVIVING
	c:EnableReviveLimit()
	
	-- PROCEDIMIENTO BASE NATIVO: 1 Cantante OSCURIDAD + 1 Monstruo Sincronía No Cantante
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK),1,1,aux.FilterBoolFunction(Card.IsCode,70771599),1,1)
	
	-- =========================================================================
	-- --- EFECTO ① (MANUSCRITO): INTERCEPCIÓN EN EL EXTRA DECK (COSTO HÍBRIDO) ---
	-- =========================================================================
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--cannot be target
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.atlimit)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)
	--atk limit
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,LOCATION_MZONE)
	e3:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e3:SetValue(s.atlimit)
	c:RegisterEffect(e3)
	--spsummon success
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetCondition(s.discon)
	e4:SetTarget(s.distg)
	e4:SetOperation(s.disop)
	c:RegisterEffect(e4)
	--attack all
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_ATTACK_ALL)
	e5:SetValue(1)
	c:RegisterEffect(e5)
	--ATK up
	local e6=Effect.CreateEffect(c)
	e6:SetCategory(CATEGORY_ATKCHANGE)
	e6:SetType(EFFECT_TYPE_TRIGGER_F+EFFECT_TYPE_SINGLE)
	e6:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e6:SetCondition(s.atkcon)
	e6:SetOperation(s.atkop)
	c:RegisterEffect(e6)
	--spsummon
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,2))
	e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e7:SetProperty(EFFECT_FLAG_CANNOT_DISABLE) -- CORREGIDO: Se removió PLAYER_TARGET ya que este efecto apunta a cartas, no a jugadores
	e7:SetType(EFFECT_TYPE_QUICK_O)
	e7:SetCode(EVENT_FREE_CHAIN)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCost(s.spcost)
	e7:SetTarget(s.sptg)
	e7:SetOperation(s.spop2)
	c:RegisterEffect(e7)
end

s.listed_series={SET_SUPREME_KING_DRAGON}
s.listed_names={13331639}
--Local No.1
function s.spfilter(c,tp)
	return c:IsControler(1-tp) and c:IsPreviousLocation(LOCATION_EXTRA)
end

-- =========================================================================
-- --- ADUANA DE SELECCIÓN MULTI-FILTRO: REGLA HÍBRIDA + SUMA DE NIVEL 10  ---
-- =========================================================================
function s.rescon(sg,e,tp,mg)
	local c=e:GetHandler()
	-- Paso A: Validación obligatoria de espacio libre en las zonas del Extra Deck
	local loc_chk = false
	if c:IsLocation(LOCATION_EXTRA) then
		loc_chk = Duel.GetLocationCountFromEx(tp,tp,sg,c)>0
	else
		loc_chk = aux.ChkfMMZ(1)(sg,e,tp,mg)
	end
	if not loc_chk then return false end
	
	-- Paso B: Si el grupo aún no tiene las 2 cartas completas, da paso libre para seguir eligiendo
	if #sg<2 then return true end
	
	-- Paso C: VERIFICACIÓN CRUZADA HÍBRIDA DE TU MANUSCRITO
	local c1=sg:GetFirst()
	local c2=sg:GetNext()
	
	-- Condición 1: Carta 1 es Supreme King Y Carta 2 es el Clear Wing real (70771599)
	local opt1 = c1:IsSetCard(SET_SUPREME_KING_DRAGON) and c2:IsCode(70771599)
	-- Condición 2: Carta 1 es el Clear Wing real (70771599) Y Carta 2 es Supreme King
	local opt2 = c1:IsCode(70771599) and c2:IsSetCard(SET_SUPREME_KING_DRAGON)
	
	-- Paso D: AUDITORÍA MATEMÁTICA DE NIVEL 10 (SANEADO)
	-- Extrae el Nivel de fábrica de ambas cartas de la mesa (soporta cálculo alterno si fuesen Xyz de fondo)
	local lv1 = c1:IsType(TYPE_XYZ) and c1:GetRank() or c1:GetLevel()
	local lv2 = c2:IsType(TYPE_XYZ) and c2:GetRank() or c2:GetLevel()
	local lvl_chk = (lv1 + lv2 == 10)
	
	-- Retorna verdadero únicamente si se cumple la identidad de Kaiba Y la suma da exactamente 10
	return (opt1 or opt2) and lvl_chk
end

-- Filtro base general de cartas elegibles para el sacrificio en tu campo
function s.costfilter(c)
	return c:IsFaceup() and (c:IsSetCard(SET_SUPREME_KING_DRAGON) or c:IsCode(70771599))
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetReleaseGroup(tp):Filter(s.costfilter,nil)
	local pg=aux.GetMustBeMaterialGroup(tp,Group.CreateGroup(),tp,nil,nil,REASON_SYNCHRO)
	
	return #pg<=0 
		and eg:IsExists(s.spfilter,1,nil,tp) 
		and Duel.GetLP(tp)<=Duel.GetLP(1-tp)
		and #g>1 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,true)
		and aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetReleaseGroup(tp):Filter(s.costfilter,nil)
	local pg=aux.GetMustBeMaterialGroup(tp,Group.CreateGroup(),tp,nil,nil,REASON_SYNCHRO)
	
	if #pg<=0 and #g>1 and aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,0)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,true)
		and Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,0)) then
		
		-- Abre tu campo de forma interactiva aplicando el filtro híbrido estricto de nivel 10
		local sg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,1,tp,HINTMSG_RELEASE)
		
		-- Libera y tributa el par exacto que suma 10
		Duel.Release(sg,REASON_COST)
		
		-- Ejecuta la Invocación Especial legítima del Crystal Wing del Extra Deck
		if Duel.SpecialSummon(c,SUMMON_TYPE_SYNCHRO,tp,tp,false,true,POS_FACEUP)>0 then
			c:CompleteProcedure()
		end
	end
end

--Local No.2,3
function s.atlimit(e,c)
	return c~=e:GetHandler()
end
--Local No.4
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSynchroSummoned()
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsNegatableMonster,tp,0,LOCATION_ONFIELD,1,nil) end
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsNegatableMonster,tp,0,LOCATION_ONFIELD,nil)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e2)
	end
	Duel.AdjustInstantly(c)
	Duel.Destroy(g,REASON_EFFECT)
end
--Local No.6
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and bc:IsControler(1-tp)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if c:IsRelateToBattle() and c:IsFaceup() and bc and bc:IsRelateToBattle() and bc:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetReset(RESET_PHASE+PHASE_DAMAGE_CAL)
		e1:SetValue(bc:GetAttack())
		c:RegisterEffect(e1)
	end
end
--Local No.7
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToExtraAsCost() end
	Duel.SendtoDeck(e:GetHandler(),nil,0,REASON_COST)
end
function s.spfilter2(c,e,tp)
	return c:IsFaceup() and c:IsSetCard(SET_CLEAR_WING) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spfilter22(c,e,tp)
	if c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,nil,c)==0 then return false end
	return c:IsSetCard(SET_CLEAR_WING) or c:IsCode(13331639) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local loc=LOCATION_EXTRA
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then loc=loc|LOCATION_GRAVE|LOCATION_REMOVED end
	if chk==0 then return loc~=0 and Duel.IsExistingMatchingCard(s.spfilter22,tp,loc,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,loc)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local loc=LOCATION_EXTRA
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then loc=loc|LOCATION_GRAVE|LOCATION_REMOVED end
	if loc==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter22,tp,loc,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,true,true,POS_FACEUP)
	end
end