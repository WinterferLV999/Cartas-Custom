local s,id=GetID()
function s.initial_effect(c)
	-- Double Xyz Material: Puede actuar como 2 materiales si se usa para un "Battlin' Boxer"
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DOUBLE_XYZ_MATERIAL)
	e1:SetOperation(s.tgval)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	
	-- During your Main Phase: You can Special Summon this card from your hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION) 
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.xyzcheckop)
		Duel.RegisterEffect(ge1,0)
	end)
end

s.listed_series={SET_BATTLIN_BOXER}

function s.tgval(e,c)
	return c:IsSetCard(SET_BATTLIN_BOXER)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- =========================================================================
-- ---   NUEVO MOTOR DE INYECCIÓN INTEGRAL DESDE EL NÚCLEO (SANO)         ---
-- =========================================================================
function s.xyzcheckop(e,tp,eg,ep,ev,re,r,rp)
	-- Escanea los monstruos recién invocados de forma exitosa
	for rc in aux.Next(eg) do
		-- Valida que sea una Invocación Xyz legítima y que pertenezca al arquetipo "Battlin' Boxer"
		if rc:IsSummonType(SUMMON_TYPE_XYZ) and rc:IsSetCard(SET_BATTLIN_BOXER) then
			-- Revisa físicamente los materiales acoplados debajo del Xyz buscando esta ID de carta
			local mg=rc:GetOverlayGroup()
			if mg:IsExists(Card.IsCode,1,nil,id) then
				
				-- CLONACIÓN DE TU PLANTILLA: Le clava el efecto TRIGGER_F obligatorio al Xyz
				local e1=Effect.CreateEffect(rc)
				e1:SetDescription(aux.Stringid(id,1))
				e1:SetCategory(CATEGORY_ATKCHANGE)
				e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
				e1:SetCode(EVENT_CUSTOM+id) -- Código de llamada limpia para forzar la resolución visual
				e1:SetProperty(EFFECT_FLAG_DELAY)
				e1:SetOperation(s.atkop)
				e1:SetReset(RESET_EVENT|RESETS_STANDARD)
				rc:RegisterEffect(e1,true)
				
				-- Fuerza el disparo del efecto visual en pantalla de forma nativa e inmediata
				Duel.RaiseSingleEvent(rc,EVENT_CUSTOM+id,e,0,0,0,0)
			end
		end
	end
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() then
		-- Aplica la duplicación final del ATK actual multiplicando exactamente por 2
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(c:GetAttack()*2)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end
