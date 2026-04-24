
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Prevent destruction by effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCondition(s.ptcon)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_CANNOT_REMOVE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(1,1)
	e3:SetCondition(s.ptcon)
	e3:SetTarget(function(e,c,tp,r) return c==e:GetHandler() and r==REASON_EFFECT end)
	c:RegisterEffect(e3)
	--Return to hand
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOHAND)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCondition(s.rtcon)
	e4:SetTarget(s.rttg)
	e4:SetOperation(s.rtop)
	c:RegisterEffect(e4)

	-- Protección: Los efectos de tus Bestias Divinas no pueden ser negados
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_CANNOT_DISABLE)
	e5:SetRange(LOCATION_FZONE)
	e5:SetTargetRange(LOCATION_MZONE,0)
	e5:SetTarget(s.distg)
	c:RegisterEffect(e5)

	-- Protección: La resolución de sus efectos activados no puede ser negada
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_CANNOT_DISEFFECT)
	e6:SetRange(LOCATION_FZONE)
	e6:SetValue(s.disval) 
	c:RegisterEffect(e6)
    
	-- Opcional: Impedir que el oponente responda a las activaciones de Bestias Divinas
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e7:SetCode(EFFECT_CANNOT_ACTIVATE)
	e7:SetRange(LOCATION_FZONE)
	e7:SetTargetRange(0,1)
	e7:SetCondition(s.actcon)
	e7:SetValue(1)
	c:RegisterEffect(e7)
end
s.listed_names={CARD_RA,CARD_OBELISK,CARD_SLIFER}
--Local No.2,3
function s.filter(c)
	return c:IsFaceup() and c:IsCode(CARD_RA,CARD_OBELISK,CARD_SLIFER,10000080,10000090,511000237)
end
function s.ptcon(e)
	return Duel.IsExistingMatchingCard(s.filter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
--Local No.4
function s.rdcfilter(c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_DIVINE)
end
function s.rtcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.rdcfilter,1,nil)
end

-- Target: Solo verifica que la carta pueda volver a la mano
function s.rttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

-- Operación: Mueve la carta del cementerio a la mano
function s.rtop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	end
end
--Local No.5
function s.distg(e,c)
	return c:IsAttribute(ATTRIBUTE_DIVINE) -- Si Atributo Divino, se aplica la protección
end
--Local No.6
function s.disval(e,ct)
	local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
	local tc=te:GetHandler()
	-- Verifica que sea un monstruo de tu lado, Bestia Divina y en el campo
	return tc:IsControler(e:GetHandlerPlayer()) and tc:IsAttribute(ATTRIBUTE_DIVINE) and tc:IsLocation(LOCATION_MZONE)
end
--Local No.7
-- Condición para que el oponente no pueda encadenar nada a sus efectos
function s.actcon(e)
	local tp=e:GetHandlerPlayer()
	local a=Duel.GetChainInfo(0,CHAININFO_TRIGGERING_EFFECT)
	return a and a:GetHandler():IsAttribute(ATTRIBUTE_DIVINE) and a:GetHandler():IsControler(tp)
end
