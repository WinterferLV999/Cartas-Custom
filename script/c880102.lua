local s,id=GetID()
function s.initial_effect(c)
	-- MUST BE PROPERLY SUMMONED BEFORE REVIVING
	c:EnableReviveLimit()
	
	-- XYZ SUMMON PROCEDURE: Requiere 2 monstruos de Nivel 8 ordinarios
	Xyz.AddProcedure(c,nil,8,2)
	
	-- =========================================================================
	-- --- REGLA DE IDENTIDAD ABSOLUTA: SIEMPRE SE TRATA COMO NUMBER 107        ---
	-- =========================================================================
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_ADD_CODE)
	e1:SetRange(LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE+LOCATION_MZONE+LOCATION_EXTRA)
	e1:SetValue(88177324) -- ID real de Number 107: Galaxy-Eyes Tachyon Dragon
	c:RegisterEffect(e1)
	
	-- =========================================================================
	-- --- EFECTO OTORGADO 1: ESCUDO ANTISELECCIÓN POR MATERIAL XYZ             ---
	-- =========================================================================
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_XMATERIAL)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetValue(aux.tgoval) -- Protege solo contra efectos del oponente
	c:RegisterEffect(e2)
	
	-- =========================================================================
	-- --- NUEVO EFECTO: COPIAR RANK-UP DESDE EL DECK (FORMATO ANACONDA VERTE) ---
	-- =========================================================================
	-- SANEADO TOTAL: Desprende 1 material por costo, envía 1 Magia Normal o de Juego 
	-- Rápido "Rank-Up-Magic" del Deck al Cementerio, y clona sus efectos e interacciones 
	-- de forma nativa e interactiva imitando milimétricamente tu plantilla de referencia.
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0)) -- "Copiar Rank-Up desde el Deck"
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id) -- Un solo uso por turno para evitar bucles corruptos
	e3:SetCost(s.cost)
	e3:SetTarget(s.target)
	e3:SetOperation(s.operation)
	c:RegisterEffect(e3)
end

s.xyz_number=107
-- Lista de identidades asociadas utilizando tus macros y códigos reales de tu base de datos
s.listed_series={SET_TACHYON,0x95} -- 0x95 es la máscara de bits universal de las "Rank-Up-Magic"
s.listed_names={88177324,57734012} -- Number 107, The Seventh One

-- =========================================================================
-- --- SUBRUTINAS DE CLONACIÓN DE HARDWARE (MÉTODO ANACONDA PARCHADO)      ---
-- =========================================================================
function s.copfilter(c)
	-- Filtra Magias Normales o Rápidas del arquetipo Rank-Up-Magic (0x95)
	-- Y verifica que sus condiciones de activación de fase sean válidas en la RAM (CheckActivateEffect)
	return c:IsAbleToGraveAsCost() and c:IsSetCard(0x95) 
		and (c:IsNormalSpell() or c:IsQuickPlaySpell()) 
		and c:CheckActivateEffect(true,true,false)~=nil 
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Reemplazado LP por el costo Xyz: Desprende de forma obligatoria 1 materialOverlay
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) 
		and Duel.IsExistingMatchingCard(s.copfilter,tp,LOCATION_DECK,0,1,nil) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		local te=e:GetLabelObject()
		local tg=te:GetTarget()
		return tg and tg(e,tp,eg,ep,ev,re,r,rp,0,chkc)
	end
	if chk==0 then return Duel.IsExistingMatchingCard(s.copfilter,tp,LOCATION_DECK,0,1,nil) end
	
	-- Selecciona y envía la Rank-Up-Magic de tu mazo al cementerio como costo de guardado
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.copfilter,tp,LOCATION_DECK,0,1,1,nil)
	if not Duel.SendtoGrave(g,REASON_COST) then return end
	
	-- Clona los punteros y etiquetas de la magia enviada para que C++ no pierda la pista del efecto
	local te=g:GetFirst():CheckActivateEffect(true,true,false)
	e:SetLabel(te:GetLabel())
	e:SetLabelObject(te:GetLabelObject())
	local tg=te:GetTarget()
	if tg then
		tg(e,tp,eg,ep,ev,re,r,rp,1)
	end
	te:SetLabel(e:GetLabel())
	te:SetLabelObject(e:GetLabelObject())
	e:SetLabelObject(te)
	Duel.ClearOperationInfo(0)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	-- Captura el puntero clonado en el target y ejecuta la operación original de la Rank-Up-Magic.
	-- Esto forzará la Invocación Especial del Xyz del Caos evolucionado desde tu Extra Deck en limpio total.
	local te=e:GetLabelObject()
	if te then
		e:SetLabel(te:GetLabel())
		e:SetLabelObject(te:GetLabelObject())
		local op=te:GetOperation()
		if op then op(e,tp,eg,ep,ev,re,r,rp) end
		te:SetLabel(e:GetLabel())
		te:SetLabelObject(e:GetLabelObject())
	end
end
