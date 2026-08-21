--太陽神の亡霊－リバイバル・ジャム
--The Sun God Revival Jam Revenant
local s,id,alias=GetID()
function s.initial_effect(c)
	alias=c:GetOriginalCodeRule()
	--①: Revival when sent to the GY by an effect or destroyed by battle
	local e00=Effect.CreateEffect(c)
	e00:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e00:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e00:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e00:SetCode(EVENT_TO_GRAVE)
	e00:SetCondition(s.condition)
	e00:SetTarget(s.sptg)
	e00:SetOperation(s.spop)
	c:RegisterEffect(e00)
	local e0=Effect.CreateEffect(c)
	e0:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e0:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e0:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e0:SetCode(EVENT_BATTLE_DESTROYED)
	e0:SetTarget(s.sptg)
	e0:SetOperation(s.spop)
	c:RegisterEffect(e0)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(alias,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetCondition(function(e) return e:GetHandler():IsReason(REASON_EFFECT) end)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	--②: Add 1 "Sun God" or "The Winged Dragon of Ra"-mentioning Spell/Trap from GY or banishment when Special Summoned
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(alias,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg2)
	e2:SetOperation(s.thop2)
	c:RegisterEffect(e2)
	--During the End Phase, if "The Immortal Sun God" was sent to your GY this turn: You can add this card from your GY to your hand
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
		return Duel.HasFlagEffect(tp,id)
	end)
	e3:SetTarget(s.retthtg)
	e3:SetOperation(s.retthop)
	c:RegisterEffect(e3)
	--Check if "The Immortal Sun God" is sent to the GY
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_TO_GRAVE)
		ge1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
			for tc in eg:Iter() do
				if tc:IsCode(CARD_THE_IMMORTAL_SUN_GOD) then 
					Duel.RegisterFlagEffect(tc:GetControler(),id,RESET_PHASE|PHASE_END,0,1)
				end
			end
		end)
		Duel.RegisterEffect(ge1,0)
	end)
end
s.listed_names={id,CARD_RA,CARD_THE_IMMORTAL_SUN_GOD}
s.listed_series={SET_SUN_GOD}
-- ① Lógica de resurrección: si estaba en el campo y fue enviado por efecto, o destruido en batalla

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_HAND)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
	end
end

-- ② Lógica al ser Invocado de Modo Especial (Añade Mágica/Trampa "Sun God" o que mencione a Ra desde GY/Banish)
function s.thfilter2(c)
	return (c:IsSetCard(SET_SUN_GOD) or c:ListsCode(CARD_RA)) and c:IsSpellTrap() and c:IsAbleToHand()
end

function s.thtg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE|LOCATION_REMOVED) and chkc:IsControler(tp) and s.thfilter2(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter2,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter2,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,tp,LOCATION_GRAVE|LOCATION_REMOVED)
end

function s.thop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end

-- ③ Lógica de reciclaje en la End Phase si la Mágica fue enviada al Cementerio este turno
function s.cfilter(c)
	return c:IsCode(IMMORTAL_SUN_GOD_ID) and c:IsReason(REASON_ANY)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_GRAVE,0,1,nil)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end
--local no.3
function s.retthtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,0)
end
function s.retthop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end