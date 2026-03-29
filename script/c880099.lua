
--Scripted by Winterfer
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK),10,4)
	--Cannot be destroyed by battle
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e0:SetValue(1)
	c:RegisterEffect(e0)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	e3:SetValue(1)
	c:RegisterEffect(e3)
	--special summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e1:SetCode(EVENT_LEAVE_FIELD)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--Attach all banished monsters to this card as material
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.attachtg)
	e2:SetOperation(s.attachop)
	c:RegisterEffect(e2)
    
    -- Efecto Continuo: Aprender efectos de los materiales
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_ADJUST) 
    e4:SetRange(LOCATION_MZONE)
    e4:SetOperation(s.gainop)
    c:RegisterEffect(e4)
end
s.listed_series={SET_NUMBER_C}
--local no.1
function s.cfilter(c,e,tp,xyz)
	 return c:IsCode(58820923) and c:IsPreviousLocation(LOCATION_MZONE)
	--return c:IsCode(98555327) and c:IsPreviousControler(tp) and c:IsReason(REASON_DESTROY)
		and c:IsCanBeXyzMaterial(xyz,tp) and (not e or c:IsRelateToEffect(e))
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,nil,tp,e:GetHandler())
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=eg:Filter(s.cfilter,nil,nil,tp,e:GetHandler())
	if chk==0 then
		local c=e:GetHandler()
		local pg=aux.GetMustBeMaterialGroup(tp,g,tp,nil,nil,REASON_XYZ)
		return #pg<=0 and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
	end
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false) then return end
	local g=eg:Filter(s.cfilter,nil,e,tp,c)
	local pg=aux.GetMustBeMaterialGroup(tp,g,tp,nil,nil,REASON_XYZ)
	if #g>0 and #pg<=0 and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 then
		c:SetMaterial(g)
		Duel.Overlay(c,g)
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
		c:CompleteProcedure()
	end
end
--local no.2
function s.filter(c)
	return c:IsFaceup() and c:IsCode(990064)
end
function s.attachfilter(c,xc,tp)
	return not c:IsSpellTrap() and c:IsCanBeXyzMaterial(xc,tp,REASON_EFFECT)
end
function s.attachtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and c:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.attachfilter,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.attachop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsImmuneToEffect(e) then
		local g=Duel.GetMatchingGroup(s.attachfilter,tp,LOCATION_REMOVED,LOCATION_REMOVED,nil)
		if #g>0 then
			Duel.Overlay(tc,g)
		end
	end
end 
--local no.4
function s.gainop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    -- Solo busca materiales que sean monstruos
    local g=c:GetOverlayGroup():Filter(Card.IsType,nil,TYPE_MONSTER)
    if #g==0 then return end
    
    for tc in aux.Next(g) do
        local code=tc:GetOriginalCode()
        -- Si el Xyz NO tiene el "flag" de este c¨®digo, lo aprende
        if not c:IsHasEffect(id+code) then
            -- COPIA PERMANENTE:
            -- RESET_EVENT+RESETS_STANDARD asegura que pierda el efecto SOLO si el Xyz deja el campo
            -- Pero NO se pierde al desacoplar el material.
            c:CopyEffect(code, RESET_EVENT+RESETS_STANDARD, 1)
            
            -- Registramos el Flag para que no lo intente copiar de nuevo
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(id+code)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            c:RegisterEffect(e1)
        end
    end
end