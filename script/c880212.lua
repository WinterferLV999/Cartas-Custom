local s,id=GetID()
function s.initial_effect(c)
	-- Invocación Xyz de Fábrica (Consistencia de Base)
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK),5,3)
	--c:AddMustBeXyzSummoned()
	c:EnableReviveLimit()
	
	-- INVOCACIÓN CONTINUA INMEDIATA (NO INICIA CADENA)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e0:SetCode(EVENT_SPSUMMON_SUCCESS)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.spcon)
	e0:SetOperation(s.spop)
	c:RegisterEffect(e0)
	
	-- EFECTO ①: Tus otros monstruos no pueden ser elegidos como objetivos de efectos de cartas
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetTargetRange(LOCATION_MZONE,0) 
	e1:SetTarget(s.tglimit)              
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)
	
	-- EFECTO ②: El adversario no puede seleccionar otros monstruos para ataques (Señuelo de Batalla)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE) 
	e2:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e2:SetValue(s.atlimit)              
	c:RegisterEffect(e2)

	-- EFECTO ③ CORREGIDO: Desacoplar material, reducir ATK a 0, ganar LP e infligir daño por LP rivales
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1)) -- Mensaje emergente visual en pantalla
	e3:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_RECOVER+CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_QUICK_O) -- Efecto Rápido
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1) -- Una vez por turno
	e3:SetCost(s.atkcost)
	e3:SetTarget(s.atktg)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)
	--atk up
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_TRIGGER_F+EFFECT_TYPE_SINGLE)
	e4:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.atkon)
	e4:SetOperation(s.atkpop)
	c:RegisterEffect(e4)
	--spsummon
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE) -- CORREGIDO: Se removió PLAYER_TARGET ya que este efecto apunta a cartas, no a jugadores
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id)
	e5:SetCost(s.spcost)
	e5:SetTarget(s.sptg)
	e5:SetOperation(s.spop2)
	c:RegisterEffect(e5)
end

-- Lista de arquetipos indexados e IDs reales sincronizados
s.listed_series={SET_SUPREME_KING_DRAGON}
s.listed_names={13331639}

-- [LÓGICA DE INVOCACIÓN CONTINUA DEFENSIVA]
function s.ex_spfilter(c,tp)
	return c:IsControler(1-tp) and c:IsPreviousLocation(LOCATION_EXTRA)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetLP(tp)<=Duel.GetLP(1-tp)
		and eg:IsExists(s.ex_spfilter,1,nil,tp)
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,42160203),tp,LOCATION_MZONE,0,1,nil)
		and e:GetHandler():IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local g_mat=Duel.SelectMatchingCard(tp,aux.FaceupFilter(Card.IsCode,42160203),tp,LOCATION_MZONE,0,1,1,nil)
		local mat=g_mat:GetFirst()
		if not mat or mat:IsImmuneToEffect(e) then return end
		local overlay_group=mat:GetOverlayGroup()
		local total_materials=Group.FromCards(mat)
		if #overlay_group>0 then
			total_materials:Merge(overlay_group)
		end
		total_materials:KeepAlive()
		local pos=mat:GetPosition()
		c:SetMaterial(total_materials)
		if #overlay_group>0 then
			Duel.Overlay(c,overlay_group)
		end
		Duel.Overlay(c,mat)
		if Duel.SpecialSummonStep(c,SUMMON_TYPE_XYZ,tp,tp,false,false,pos,0xff) then
			Duel.SpecialSummonComplete()
			c:CompleteProcedure()
			Duel.RaiseEvent(c,EVENT_SPSUMMON_SUCCESS,e,REASON_EFFECT,tp,tp,0)
		end
	end
end

-- [LÓGICA DE PROTECCIÓN CONTINUA IMPRESA]
function s.tglimit(e,c)
	return c~=e:GetHandler()
end
function s.atlimit(e,c)
	return c~=e:GetHandler()
end

-- =========================================================================
-- ---   RESOLUCIÓN DEL EFECTO ③ SANEADO SIN FILTROS OBSOLETOS          ---
-- =========================================================================
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- Filtro nativo para escanear monstruos boca arriba en resolución con ATK mayor a 0
function s.tgfilter(c)
	return c:IsFaceup() and c:GetAttack()>0
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Al no seleccionar, chk==0 solo valida que EXISTA al menos un objetivo legal en el campo
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,0,LOCATION_MZONE,1,nil) end
	
	-- Declaramos las categorías vacías en el target ya que el valor exacto se sabrá en la resolución
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- ELECCIÓN EN RESOLUCIÓN: El jugador escoge al monstruo rival en este momento exacto.
	-- Tu oponente ya no puede encadenar nada en respuesta a esta elección.
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTACK)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,0,LOCATION_MZONE,1,1,nil)
	local tc=g:GetFirst()
	
	-- Verifica el objetivo en mesa respetando las inmunidades nativas
	if tc and tc:IsFaceup() and not tc:IsImmuneToEffect(e) then
		-- Guarda el ATK exacto antes de reducirlo a cero
		local atk=tc:GetAttack()
		
		-- Clava su ATK final en cero usando la constante reglamentaria
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(0)
		e1:SetReset(RESETS_STANDARD)
		tc:RegisterEffect(e1)
		
		-- Mecánica encadenada: Si el ATK cambió exitosamente a 0
		if tc:GetAttack()==0 and atk>0 then
			Duel.BreakEffect() -- Breve pausa visual estética de Konami
			
			-- 1. Recuperas LP igual al ATK que el monstruo oponente perdió
			if Duel.Recover(tp,atk,REASON_EFFECT)>0 then
				-- 2. El oponente toma daño directo igual al ATK perdido
				Duel.Damage(1-tp,atk,REASON_EFFECT)
			end
		end
	end
end
--Local No.4
--Increase ATK
function s.atkon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetLP(tp)~=Duel.GetLP(1-tp)
end
function s.atkpop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local atk=math.abs(Duel.GetLP(tp)-Duel.GetLP(1-tp))
		--Increase ATK
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD_DISABLE)
		e1:SetValue(atk)
		c:RegisterEffect(e1)
	end
end
function s.adcon(e)
	return Duel.GetCurrentPhase()==PHASE_DAMAGE_CAL
end
--Local No.5
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToExtraAsCost() end
	Duel.SendtoDeck(e:GetHandler(),nil,0,REASON_COST)
end

function s.spfilter2(c,e,tp)
	return c:IsFaceup() and c:IsSetCard(SET_REBELLION) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.spfilter22(c,e,tp)
	if c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,nil,c)==0 then return false end
	-- Permite listar monstruos "Rebellion", el ID base del dragón, o a Z-ARC (13331639)
	return (c:IsSetCard(SET_REBELLION) or c:IsCode(42160203) or c:IsCode(13331639))
		and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end

-- Filtro auxiliar para buscar el material de acoplamiento (Monstruo de OSCURIDAD válido)
function s.xyzmatfilter(c)
	return (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsAttribute(ATTRIBUTE_DARK) and c:IsMonster()
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
	local sc=g:GetFirst()
	
	-- 1. Realiza la Invocación Especial (Aplica tanto para Rebellion como para Z-ARC)
	if sc and Duel.SpecialSummon(g,0,tp,tp,true,true,POS_FACEUP)>0 then
		
		-- 2. Define las zonas legales de búsqueda para el material de acoplamiento
		local mat_loc=LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA
		
		-- 3. CORREGIDO: El acoplamiento es EXCLUSIVO si es Xyz Y además pertenece al arquetipo "Rebellion"
		-- Si invocaste a Z-ARC, esta condición dará 'false' y el efecto terminará limpiamente sin pedir materiales.
		if sc:IsType(TYPE_XYZ) and sc:IsSetCard(SET_REBELLION) and Duel.IsExistingMatchingCard(s.xyzmatfilter,tp,mat_loc,0,1,nil) then
			Duel.BreakEffect() -- Breve pausa visual estética regulada de Konami
			
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local mat_g=Duel.SelectMatchingCard(tp,s.xyzmatfilter,tp,mat_loc,0,1,1,nil)
			
			if #mat_g>0 then
				-- 4. Acopla la unidad seleccionada debajo del monstruo Rebellion
				Duel.Overlay(sc,mat_g)
			end
		end
	end
end