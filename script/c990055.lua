
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,s.ffilter,3)
	--special summon condition
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetValue(aux.fuslimit)
	c:RegisterEffect(e1)
	-- Inafectable por efectos de monstruos del oponente invocados de modo especial
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)

	-- Equipar al destruir en batalla y atacar de nuevo
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_EQUIP)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DESTROYING)
	e3:SetCondition(s.bccon)
	e3:SetTarget(s.eqtg)
	e3:SetOperation(s.eqop)
	c:RegisterEffect(e3)
	-- EFECTO DE ATK CORREGIDO: Gana el ATK de todos los monstruos equipados
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetValue(s.atkval)
	c:RegisterEffect(e4)

	-- Debilitar monstruos del oponente (-300 por cada Frightfur en GY/Banished)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_UPDATE_ATTACK)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTargetRange(0,LOCATION_MZONE)
	e5:SetValue(s.atkval2)
	c:RegisterEffect(e5)
end
s.listed_series={SET_FRIGHTFUR}
s.material_setcode=SET_FRIGHTFUR

-- Filtro de materiales (Set Frightfur)
function s.ffilter(c,fc,sumtype,tp,sub,mg,sg)
	return c:IsSetCard(SET_FRIGHTFUR,fc,sumtype,tp) and (not sg or not sg:IsExists(s.fusfilter,1,c,c:GetCode(fc,sumtype,tp),fc,sumtype,tp))
end
function s.fusfilter(c,code,fc,sumtype,tp)
	return c:IsSummonCode(fc,sumtype,tp,code) and not c:IsHasEffect(511002961)
end

-- Filtro de inmunidad
function s.efilter(e,te)
	local tp=e:GetHandlerPlayer()
	local owner=te:GetOwner()
	return te:IsActiveType(TYPE_MONSTER) -- Que sea monstruo
		and te:GetOwnerPlayer()~=tp -- Que sea del oponente
		and (owner:IsSummonType(SUMMON_TYPE_SPECIAL) or owner:GetSummonType()==SUMMON_TYPE_SPECIAL) -- Que sea Special Summon
end
--local No.3
-- Lógica para equipar y atacar de nuevo
function s.bccon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	-- Verifica destrucción y que haya espacio libre en la zona de magia/trampa
	return c:IsRelateToBattle() and bc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and bc:IsType(TYPE_MONSTER)
		and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local bc=e:GetHandler():GetBattleTarget()
	Duel.SetTargetCard(bc)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,bc,1,0,0)
end

function s.eqlimit(e,c)
	return e:GetLabelObject()==c
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
		if Duel.Equip(tp,tc,c,false) then
			-- MARCAMOS LA CARTA EQUIPADA con una ID propia (id)
			tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
			
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetValue(s.eqlimit)
			e1:SetLabelObject(c)
			tc:RegisterEffect(e1)
			
			if Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_MZONE,1,nil) then
				Duel.ChainAttack()
			end
		end
	end
end
--local No.4
-- Cálculo de ATK filtrado por FLAG
function s.atkval(e,c)
	local g=c:GetEquipGroup()
	local atk=0
	local tc=g:GetFirst()
	while tc do
		-- SOLO suma el ATK si la carta tiene el FLAG registrado en eqop
		if tc:HasFlagEffect(id) then
			local tatk=tc:GetTextAttack()
			if tatk<0 then tatk=0 end
			atk=atk+tatk
		end
		tc=g:GetNext()
	end
	return atk
end
--local No.5
-- Reducir ATK oponente (-300 por Frightfur en GY/Banished)
function s.atkval2(e,c)
	local tp=e:GetHandlerPlayer()
	local g=Duel.GetMatchingGroup(Card.IsSetCard,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil,SET_FRIGHTFUR)
	return #g*-300
end