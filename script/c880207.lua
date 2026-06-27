function s.initial_effect(c)
	c:EnableReviveLimit()
	c:EnableUnsummonable()
	Fusion.AddProcMixN(c,true,true,s.ffilter,2)
	local e_lock=Effect.CreateEffect(c)
	e_lock:SetType(EFFECT_TYPE_SINGLE)
	e_lock:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e_lock:SetCode(EFFECT_SPSUMMON_CONDITION)
	e_lock:SetValue(s.splimit) 
	c:RegisterEffect(e_lock)
		-- EFECTO ① (Efecto Rápido): Destierro de Campo/GY (Estilo Called by the Grave Omnipresente)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1) -- Una vez por turno
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--copy
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_ADJUST)
	e2:SetRange(LOCATION_MZONE)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end
function s.ffilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_STARVING_VENOM,fc,sumtype,tp) and c:IsOnField()
end
function s.splimit(e,se,sp,st)
	return se and (se:IsHasCategory(CATEGORY_SPECIAL_SUMMON) or st==SUMMON_TYPE_FUSION)
end
-- --- 1. LÓGICA DE DESTIERRO E INTERCEPCIÓN EN CADENA ---
function s.tgfilter(c,e)
	return c:IsMonster() and c:IsAbleToRemove() and c~=e:GetHandler()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,nil,e) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_MZONE+LOCATION_GRAVE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,1,nil,e)
	
	if #g>0 then
		local tc=g:GetFirst()
		if tc:IsFaceup() or tc:IsLocation(LOCATION_GRAVE) then
			tc:NegateEffects(c,RESET_PHASE+PHASE_END)
		end
		if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)~=0 then
			
			-- AURA 1: Negación de copias en el campo hasta la End Phase de este turno
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
			e1:SetTarget(s.distg)
			e1:SetLabel(tc:GetOriginalCodeRule())
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
			
			-- AURA 2: Intercepción y negación de activaciones en cadena hasta la End Phase de este turno
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e2:SetCode(EVENT_CHAIN_SOLVING)
			e2:SetCondition(s.discon)
			e2:SetOperation(s.disop)
			e2:SetLabel(tc:GetOriginalCodeRule())
			e2:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e2,tp)
		end
	end
end
function s.distg(e,c)
	local code=e:GetLabel()
	local code1,code2=c:GetOriginalCodeRule()
	return code1==code or code2==code
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()
	local code1,code2=re:GetHandler():GetOriginalCodeRule()
	return re:IsMonsterEffect() and (code1==code or code2==code)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.NegateEffect(ev)
end
--Local No.2
function s.filter(c)
	return c:IsLevelAbove(5) and c:IsMonster()
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	g:Remove(s.codefilterchk,nil,e:GetHandler())
	if c:IsFacedown() or #g<=0 then return end
	repeat
		local tc=g:GetFirst()
		local code=tc:GetOriginalCode()
		
		-- Clona las habilidades originales de la carta desterrada
		local cid=c:CopyEffect(code,RESET_EVENT+RESETS_STANDARD,1)
		c:RegisterFlagEffect(code,RESET_EVENT+RESETS_STANDARD,0,0)
		
		-- NUEVO ADICIONAL: Clona nativamente el NOMBRE original de la carta desterrada
		local e_name=Effect.CreateEffect(c)
		e_name:SetType(EFFECT_TYPE_SINGLE)
		e_name:SetCode(EFFECT_ADD_CODE)
		e_name:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
		e_name:SetValue(code)
		e_name:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e_name,true)
		
		local e0=Effect.CreateEffect(c)
		e0:SetCode(id)
		e0:SetLabel(code)
		e0:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e0,true)
		
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_ADJUST)
		e1:SetRange(LOCATION_MZONE)
		e1:SetLabel(cid)
		e1:SetLabelObject(e0)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetOperation(s.resetop)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1,true)
		g:Remove(s.codefilter,nil,code)
	until #g<=0
end
function s.codefilter(c,code)
	return c:IsOriginalCode(code) and c:IsLevelAbove(5)
end
function s.codefilterchk(c,sc)
	return sc:GetFlagEffect(c:GetOriginalCode())>0
end
function s.resetop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_REMOVED,LOCATION_REMOVED,nil)
	if not g:IsExists(s.codefilter,1,nil,e:GetLabelObject():GetLabel()) or c:IsDisabled() then
		c:ResetEffect(e:GetLabel(),RESET_COPY)
		c:ResetFlagEffect(e:GetLabelObject():GetLabel())
	end
end