local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Material de fusión estándar (Arquetipo Cúbico 0xe3)
	Fusion.AddProcMixRep(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,0xe3),2,99)
	
	-- Invocación alternativa por contacto (Acoplando las Semillas Cúbicas)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.hspcon)
	e1:SetTarget(s.hsptg)
	e1:SetOperation(s.hspop)
	c:RegisterEffect(e1)
	
	-- ① Destruir Magias/Trampas al entrar
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	
	-- ➁ Reducción de ATK (-600 por cada monstruo acoplado)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,LOCATION_MZONE)
	e3:SetCondition(s.ctcon)
	e3:SetValue(s.ctval)
	c:RegisterEffect(e3)
	
	-- ➂ Regresar al Extra Deck, Buscar e Invocar (Tu lógica de coste)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_BATTLE_DAMAGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.spcon)
	e4:SetCost(s.spcost)
	e4:SetTarget(s.target0)
	e4:SetOperation(s.operation0)
	c:RegisterEffect(e4)
end

-- LÓGICA DE INVOCACIÓN POR CONTACTO (ACUPLAR MATERIALES)
function s.hspfilter(c,tp,sc)
	-- Filtra monstruos "Cubic Seed" boca arriba que sean de Nivel 1 exactamente
	return c:IsMonster() and c:IsCubicSeed() and c:IsFaceup() and c:IsLevel(1)
		and Duel.GetLocationCountFromEx(tp,tp,c,sc)>0
end

function s.hspfilter(c,tp,sc)
	-- Filtra monstruos "Cubic Seed" boca arriba que sean de Nivel 1 exactamente
	return c:IsMonster() and c:IsCubicSeed() and c:IsFaceup() and c:IsLevel(1)
		and Duel.GetLocationCountFromEx(tp,tp,c,sc)>0
end

function s.hspcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	-- Ahora verifica si tienes AL MENOS 2 o más monstruos que cumplan el filtro
	return Duel.IsExistingMatchingCard(s.hspfilter,tp,LOCATION_MZONE,0,2,nil,tp,c)
end

function s.hsptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	if chk==0 then return true end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	-- Cambiado: El motor ahora te permite seleccionar desde un mínimo de 2 hasta el máximo disponible en tu campo
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
	
	-- Limpia materiales previos de los monstruos seleccionados si los hubiera
	local tc=g:GetFirst()
	while tc do
		if tc:GetOverlayCount()~=0 then Duel.SendtoGrave(tc:GetOverlayGroup(),REASON_RULE) end
		tc=g:GetNext()
	end
	
	c:SetMaterial(g)
	-- Apila todas las Semillas seleccionadas debajo de Veda (Stack)
	Duel.Overlay(c,g)
	g:DeleteGroup()
end

-- Funciones del Efecto ① (Destrucción)
function s.desfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- Funciones del Efecto ➁ (Reducción de ATK)
function s.ctcon(e)
	return e:GetHandler():GetOverlayGroup():IsExists(Card.IsMonster,1,nil)
end
function s.ctval(e,c)
	return e:GetHandler():GetOverlayGroup():FilterCount(Card.IsMonster,nil)*-600
end

-- Funciones del Efecto ➂ (Tu lógica de coste para el Extra Deck)
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return ep~=tp and eg:GetFirst()==e:GetHandler()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtraAsCost() end
	-- Guardamos las cartas de abajo en una variable temporal antes de que la carta se vaya
	local mg=c:GetOverlayGroup()
	mg:KeepAlive()
	e:SetLabelObject(mg)
	Duel.SendtoDeck(c,nil,0,REASON_COST)
end
function s.spfilter(c,e,tp)
	-- Filtra específicamente a Vijam la Semilla Cúbica (CARD_VIJAM = 4998619)
	return c:IsCode(CARD_VIJAM) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.thfilter(c)
	return c:IsSetCard(0xe3) and c:IsAbleToHand()
end

function s.target0(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.operation0(e,tp,eg,ep,ev,re,r,rp)
	-- 1. Intenta buscar el monstruo Cúbico en el Deck primero
	local search_group=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if #search_group==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g_search=search_group:Select(tp,1,1,nil)
	if #g_search>0 and Duel.SendtoHand(g_search,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g_search)
		
		-- 2. Calcula el espacio disponible en tu campo para las Semillas
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		if ft<=0 then return end
		if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
		
		-- Elige el máximo espacio disponible, pero limitado a un tope de 3
		local max_spawn=math.min(3,ft)
		
		-- Obtiene los Vijam válidos del cementerio
		local grave_group=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
		if #grave_group>0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			-- Permite al usuario elegir libremente de 1 a 3 copias de Vijam
			local g_summon=grave_group:Select(tp,1,max_spawn,nil)
			if #g_summon>0 then
				Duel.SpecialSummon(g_summon,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end


function s.sspfilter(c,e,tp)
	return c:IsMonster() and c:IsCubicSeed() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sthfilter(c)
	return c:IsSetCard(0xe3) and c:IsAbleToHand()
end
function s.starget0(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.soperation0(e,tp,eg,ep,ev,re,r,rp)
	-- Recuperamos el grupo que guardamos en el coste (los monstruos de abajo)
	local sg=e:GetLabelObject()
	if not sg then return end
	
	-- Filtrar solo los que se puedan invocar legalmente
	sg=sg:Filter(s.spfilter,nil,e,tp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 or #sg==0 then return end
	
	if #sg>1 and Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	if #sg > ft then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		sg=sg:Select(tp,ft,ft,nil)
	end
	
	-- 1. Invoca las semillas que estaban abajo de la fusión
	if Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)~=0 then
		-- 2. Busca un monstruo Cúbico del mazo a la mano
		local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
		if #g>0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			g=g:Select(tp,1,1,nil)
			Duel.SendtoHand(g,tp,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
	sg:DeleteGroup()
end
