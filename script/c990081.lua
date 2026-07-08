local s,id=GetID()
function s.initial_effect(c)
	-- Invocación por Sincronía (Mantiene intacta la sintaxis híbrida ganadora de tu servidor)
	Synchro.AddProcedure(c,s.tfilter,1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()
	
	-- EFECTO ①: Tratarse como Nivel 6 o 7 para una Invocación por Sincronía de un Dragón
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_SYNCHRO_LEVEL)
	e1:SetRange(LOCATION_MZONE) -- 0x4 = LOCATION_MZONE
	e1:SetValue(s.slevel)
	c:RegisterEffect(e1)
	
	-- EFECTO ②: Cambiar el Nivel de un Cantante bajo tu control (Del 1 al 5)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1) 
	e2:SetTarget(s.lvtg)
	e2:SetOperation(s.lvop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_SYNCHRON}
s.material_setcode=SET_SYNCHRON

function s.tfilter(c,lc,stype,tp)
	return c:IsSetCard(SET_SYNCHRON,lc,stype,tp) or c:IsSetCard(SET_JUNK,lc,stype,tp)
end

-- =========================================================================
-- --- RESOLUCIÓN DEL EFECTO ①: COMODÍN DE NIVEL 6 O 7 PARA SINCRO DRAGÓN ---
-- =========================================================================
function s.slevel(e,c)
	local lv=e:GetHandler():GetLevel()
	-- 0x1 = RACE_DRAGON en tu archivo de constantes oficial
	-- Si el monstruo que vas a invocar (c) es de Raza Dragón, la Skill le inyecta los dos valores en binario
	if c:IsRace(RACE_DRAGON) then
		-- Devuelve una máscara de bits en bajo nivel que le avisa a C++ que la carta vale como 6 y como 7
		return (6<<16)+7
	else
		-- Si no es un dragón, devuelve su nivel físico normal de fábrica
		return lv
	end
end

-- =========================================================================
-- ---   RESOLUCIÓN DEL EFECTO ②: MENÚ INTERACTIVO DE NIVEL (1 AL 5)     ---
-- =========================================================================
function s.filter(c)
	-- Escanea monstruos sintonizadores (0x1000 = TYPE_TUNER) boca arriba que posean niveles
	return c:IsFaceup() and c:IsType(0x1000) and c:HasLevel()
end

function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
	
	-- INTERFAZ DE ANUNCIO EN PANTALLA: Te abrirá el teclado flotante oficial de tu emulador
	-- restringiendo las opciones estrictamente desde el número 1 hasta el número 5
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_LVRANK)
	local lv=Duel.AnnounceLevel(tp,1,5,g:GetFirst():GetLevel())
	Duel.SetTargetParam(lv)
end

function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	local lv=Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)
	
	-- Si el Cantante seleccionado sigue acoplado a la mesa, le inyecta el nuevo nivel
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_LEVEL)
		e1:SetValue(lv)
		e1:SetReset(RESETS_STANDARD_PHASE_END) -- El cambio caduca al finalizar el turno actual
		tc:RegisterEffect(e1)
	end
end
