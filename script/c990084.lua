local s,id=GetID()
function s.initial_effect(c)
	-- Efecto principal: Activación de Magia Rápida (0x10000 = TYPE_QUICKPLAY)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Lista de arquetipos soportados en tu base de datos
s.listed_series={0x3a,0x43,0xa3}

-- =========================================================================
-- ---         APLICACIÓN DEL RADAR PERSISTENTE DEL PRIMER TURNO          ---
-- =========================================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- 1. REGISTRA EL RADAR CONTINUO DE RESCATE (DURACIÓN HASTA LA END PHASE DE ESTE TURNO)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_REMOVE)
	e1:SetCode(EVENT_REMOVE)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	e1:SetReset(RESET_PHASE+PHASE_END) -- El radar de rescate dura solo este turno
	Duel.RegisterEffect(e1,tp)
	
	-- 2. INTEGRACIÓN COMPATIBLE DE TU SUBRUTINA DE TIEMPO Y REGRESO (s.stage2)
	-- Se ejecuta en caliente pasando chk=1 para encender el reloj flotante dorado en el GY
	s.stage2(e,c,tp,nil,1)
end

-- =========================================================================
-- ---     FILTROS DE RECONOCIMIENTO EXCLUSIVOS PARA MONSTRUOS SINCRO     ---
-- =========================================================================
function s.filter(c,tp)
	return not c:IsType(TYPE_TOKEN) and c:IsType(TYPE_SYNCHRO) and c:IsMonster() 
		and c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.filter,nil,tp)
	return #g==1
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.filter,nil,tp)
	local tc=g:GetFirst()
	if not tc then return end
	
	Duel.Hint(HINT_CARD,0,id)
	
	if tc:IsLocation(LOCATION_REMOVED) then
		-- Revive al monstruo de Sincronía de forma Especial boca arriba en tu Zona de Monstruos
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- =========================================================================
-- ---       TU SUBRUTINA DE REINICIOS, TIEMPO Y ADUANAS DE GY (S_STAGE2) ---
-- =========================================================================
function s.stage2(e,tc,tp,sg,chk)
	if chk==1 and e:IsHasType(EFFECT_TYPE_ACTIVATE) then
		local res=0
		local c=e:GetHandler()
		local e1=Effect.CreateEffect(c)
		e1:SetCategory(CATEGORY_TOHAND)
		e1:SetType(EFFECT_TYPE_IGNITION)
		e1:SetRange(LOCATION_GRAVE)
		if Duel.IsTurnPlayer(tp) then
			res=3
			e1:SetLabel(Duel.GetTurnCount())
		else
			res=2
			e1:SetLabel(Duel.GetTurnCount()-1)
		end
		e1:SetValue(4)
		e1:SetCondition(s.thcon)
		e1:SetTarget(s.sstg) -- Se mapeó al sstg clásico de herencia
		e1:SetOperation(s.thop)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_EXC_GRAVE+RESET_PHASE+PHASE_END+RESET_SELF_TURN,res)
		c:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_SET_AVAILABLE)
		e2:SetCode(1082946)
		e2:SetLabelObject(e1)
		e2:SetOperation(s.reset)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD_EXC_GRAVE+RESET_PHASE+PHASE_END+RESET_SELF_TURN,res)
		c:RegisterEffect(e2)
	end
end

function s.reset(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetLabelObject()
	local val=te:GetValue()
	if Duel.GetTurnCount()==te:GetLabel()+val then
		e:GetHandler():SetTurnCounter(3)
		e:Reset() te:Reset()
	else
		val=val-2
		if Duel.GetTurnCount()==te:GetLabel()+val then
			e:GetHandler():SetTurnCounter(2)
		elseif Duel.GetTurnCount()==te:GetLabel()+val-2 then
			e:GetHandler():SetTurnCounter(1)
		end
		te:SetValue(val)
	end
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnCount()==e:GetLabel()+e:GetValue()
end

function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		-- Ejecuta el retorno físico a la mano desde tu cementerio de forma 100% nativa
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	end
end
