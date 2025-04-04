ember_spirit_sleight_of_fist = class({})

function ember_spirit_sleight_of_fist:IsStealable()
	return true
end

function ember_spirit_sleight_of_fist:IsHiddenWhenStolen()
	return false
end

function ember_spirit_sleight_of_fist:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function ember_spirit_sleight_of_fist:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	caster:StartGesture(ACT_DOTA_CAST_ABILITY_2)
	
	ProjectileManager:ProjectileDodge( caster )

	EmitSoundOn("Hero_EmberSpirit.SleightOfFist.Cast", caster)

	local startPos = caster:GetAbsOrigin()

	local radius = self:GetSpecialValueFor("radius")
	local jumpRate = self:GetSpecialValueFor("attack_interval") / caster:GetAttackSpeed(false)
	local minAttacks = self:GetSpecialValueFor("min_attacks")
	local min_enemies_for_double_sleight = self:GetSpecialValueFor("min_enemies_for_double_sleight")

	self.hitUnits = {}

	local current = 0

	local castFx = 	ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleight_of_fist_cast.vpcf", PATTACH_POINT, caster)
					ParticleManager:SetParticleControl(castFx, 0, point)
					ParticleManager:SetParticleControl(castFx, 1, Vector(radius, radius, radius))
					ParticleManager:ReleaseParticleIndex(castFx)
					
	---Remnant Only lasts 10 seconds.-----
	local enemies = caster:FindEnemyUnitsInRadius(point, radius, {flag = self:GetAbilityTargetFlags(), order = FIND_CLOSEST})
	if #enemies > 0 then
		local duration = self:GetSpecialValueFor("duration")
		
		local modifier = caster:AddNewModifier(caster, self, "modifier_ember_spirit_sleight_of_fist_caster", {Duration = 10})
		caster:AddNewModifier(caster, self, "modifier_ember_spirit_sleight_of_fist_caster_invulnerability", {Duration = 10})
		
		local remenantFx = 	ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleight_of_fist_caster.vpcf", PATTACH_WORLDORIGIN, nil )
				 			ParticleManager:SetParticleControl(remenantFx, 0, startPos)
				 			ParticleManager:SetParticleControlForward(remenantFx, 1, caster:GetForwardVector())

	
		modifier:AddEffect( remenantFx )
		
		Timers:CreateTimer(function()
			if current >= #enemies then -- less enemies than attacks
				local hitCount = 0
				for _,enemy in pairs(self.hitUnits) do
					hitCount = hitCount + 1
				end
				if current < minAttacks and hitCount >= #enemies then -- not hit attack limit yet, wipe board state
					self.hitUnits = {}
				end				
			end
			if (current < #enemies or current < minAttacks) and not caster:HasModifier("modifier_ember_spirit_fire_remnant") then
				for _,enemy in pairs(enemies) do
					if not self.hitUnits[enemy:entindex()] then
						EmitSoundOn("Hero_EmberSpirit.SleightOfFist.Damage", enemy)

						local firstPoint = caster:GetAbsOrigin()
						local secondPoint = enemy:GetAbsOrigin() + caster:GetForwardVector() * 50

						ParticleManager:FireRopeParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_trail.vpcf", PATTACH_WORLDORIGIN, caster, secondPoint, {[0]=firstPoint, [1]=secondPoint})

						FindClearSpaceForUnit(caster, secondPoint, true)
						caster:FaceTowards(enemy:GetAbsOrigin())
						
						if enemy:IsConsideredHero() then
							caster:AddNewModifier( caster, self, "modifier_ember_spirit_sleight_of_fist_bonus_damage", {} )
						end
						caster:PerformGenericAttack( enemy, true )
						caster:RemoveModifierByName("modifier_ember_spirit_sleight_of_fist_bonus_damage")
						
			            self.hitUnits[enemy:entindex()] = true
			            current = current + 1
						return jumpRate
			        end
				end
			else
				if min_enemies_for_double_sleight > 0 and #enemies >= min_enemies_for_double_sleight then
					local enemy = enemies[1]
					local firstPoint = caster:GetAbsOrigin()
					local secondPoint = enemy:GetAbsOrigin() + caster:GetForwardVector() * 50
					
					ParticleManager:FireRopeParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_trail.vpcf", PATTACH_WORLDORIGIN, caster, secondPoint, {[0]=firstPoint, [1]=secondPoint})

					FindClearSpaceForUnit(caster, secondPoint, true)
					caster:FaceTowards(enemy:GetAbsOrigin())
					
					if enemy:IsConsideredHero() then
						caster:AddNewModifier( caster, self, "modifier_ember_spirit_sleight_of_fist_bonus_damage", {} )
					end
					caster:PerformGenericAttack( enemy, true )
					caster:RemoveModifierByName("modifier_ember_spirit_sleight_of_fist_bonus_damage")
					
					min_enemies_for_double_sleight = 0
					return jumpRate
				end
				local firstPoint = caster:GetAbsOrigin()

				ParticleManager:ClearParticle(remenantFx)

				caster:RemoveModifierByName("modifier_ember_spirit_sleight_of_fist_caster")
				caster:RemoveModifierByName("modifier_ember_spirit_sleight_of_fist_caster_invulnerability")
				if not caster:HasModifier("modifier_ember_spirit_fire_remnant") then FindClearSpaceForUnit(caster, startPos, true) end

				local secondPoint = caster:GetAbsOrigin()

				ParticleManager:FireRopeParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_trail.vpcf", PATTACH_WORLDORIGIN, caster, secondPoint, {[0]=firstPoint, [1]=secondPoint})
				
				
				return nil
			end
		end)
	else
		self:GetCaster():RemoveGesture(ACT_DOTA_CAST_ABILITY_2)
	end
end

LinkLuaModifier("modifier_ember_spirit_sleight_of_fist_active", "heroes/hero_ember_spirit/ember_spirit_sleight_of_fist", LUA_MODIFIER_MOTION_NONE)
modifier_ember_spirit_sleight_of_fist_active = class({})

function modifier_ember_spirit_sleight_of_fist_active:OnRemoved()
	if IsServer() then
		self:GetCaster():RemoveGesture(ACT_DOTA_CAST_ABILITY_2)
	end
end

function modifier_ember_spirit_sleight_of_fist_active:CheckState()
	local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
					[MODIFIER_STATE_DISARMED] = true,
					[MODIFIER_STATE_INVULNERABLE] = true,
					[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS ] = true}
	return state
end

function modifier_ember_spirit_sleight_of_fist_active:GetStatusEffectName()
	return "particles/status_fx/status_effect_snapfire_magma.vpcf"
end

function modifier_ember_spirit_sleight_of_fist_active:StatusEffectPriority()
	return 20
end

function modifier_ember_spirit_sleight_of_fist_active:IsHidden()
	return true
end

LinkLuaModifier("modifier_ember_spirit_sleight_of_fist_bonus_damage", "heroes/hero_ember_spirit/ember_spirit_sleight_of_fist", LUA_MODIFIER_MOTION_NONE)
modifier_ember_spirit_sleight_of_fist_bonus_damage = class({})

function modifier_ember_spirit_sleight_of_fist_bonus_damage:OnCreated()
	self:OnRefresh()
end

function modifier_ember_spirit_sleight_of_fist_bonus_damage:OnRefresh(table)
	self.damage = self:GetSpecialValueFor("bonus_hero_damage")
end

function modifier_ember_spirit_sleight_of_fist_bonus_damage:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
    }
    return funcs
end

function modifier_ember_spirit_sleight_of_fist_bonus_damage:GetModifierPreAttack_BonusDamage()
	return self.damage
end

function modifier_ember_spirit_sleight_of_fist_bonus_damage:IsDebuff()
	return false
end

function modifier_ember_spirit_sleight_of_fist_bonus_damage:IsHidden()
	return true
end