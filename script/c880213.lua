local s,id=GetID()
function s.initial_effect(c)
	-- Invocación Xyz de Fábrica: Exige 3 monstruos de Nivel 5
	Xyz.AddProcedure(c,nil,5,3)
	c:EnableReviveLimit()
	
	-- Habilita el registro en caliente del motor para el Rank-Up usando a Dark Rebellion (16195942)
	aux.EnableCheckRankUp(c,nil,nil,16195942)
	local e_reb=Effect.CreateEffect(c)
	e_reb:SetType(EFFECT_TYPE_SINGLE)
	e_reb:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e_reb:SetCode(EFFECT_ADD_SETCODE)
	e_reb:SetValue(0x13b)
	c:RegisterEffect(e_reb)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0)) 
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION) 
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1) 
	e1:SetCost(s.discost)
	e1:SetTarget(s.distg)
	e1:SetOperation(s.disop)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_RANKUP_EFFECT)
	e2:SetLabelObject(e1)
	c:RegisterEffect(e2,false,REGISTER_FLAG_DETACH_XMAT) -- Registro de coste de desacople seguro
	--Can attack all monsters
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_ATTACK_ALL)
	e3:SetValue(1)
	c:RegisterEffect(e3)
	--Banish monsters destroyed by battle
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_BATTLE_DESTROY_REDIRECT)
	e4:SetValue(LOCATION_REMOVED)
	c:RegisterEffect(e4)
end

-- Lista de nombres indexados oficiales
s.listed_names={16195942}

-- =========================================================================
-- ---        RESOLUCIÓN DEL EFECTO ①: DRENAJE Y MULTIPLICACIÓN        ---
-- =========================================================================
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Costo: Desacopla obligatoriamente 2 materiales Xyz de esta carta
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Target: Valida que el oponente controle al menos 1 monstruo boca arriba para poder activar
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,0,1-tp,LOCATION_MZONE)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- 1. Captura a todos los monstruos boca arriba que controle tu adversario en este instante
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	if #g==0 then return end
	
	local count=0
	for tc in aux.Next(g) do
		if not tc:IsImmuneToEffect(e) then
			-- A. Niega los efectos del monstruo de forma permanente en el campo
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESETS_STANDARD)
			tc:RegisterEffect(e1)
			
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESETS_STANDARD)
			tc:RegisterEffect(e2)
			
			-- B. Clava su ATK final en cero de forma permanente
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_SET_ATTACK_FINAL)
			e3:SetValue(0)
			e3:SetReset(RESETS_STANDARD)
			tc:RegisterEffect(e3)
			
			count = count + 1
		end
	end
	
	-- 2. Si al menos un monstruo fue afectado con éxito, este dragón multiplica su ATK
	if count>0 and c:IsFaceup() and c:IsRelateToEffect(e) then
		Duel.BreakEffect() -- Breve pausa visual estética de Konami
		
		-- Guarda su valor actual en la mesa y lo multiplica por 2 (Doble ATK = 6000)
		local current_atk=c:GetAttack()
		local new_atk=current_atk * 2
		
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetCode(EFFECT_SET_ATTACK_FINAL)
		e4:SetValue(new_atk)
		-- El bufo de multiplicación expira automáticamente al finalizar el turno actual
		e4:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END) 
		c:RegisterEffect(e4)
	end
end
