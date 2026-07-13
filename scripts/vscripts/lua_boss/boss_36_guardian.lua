-- Legacy function kept for compatibility (no longer used with new Lua ability)
function create_shield_particle(keys)
	local origin = keys.caster:GetAbsOrigin()
	local size = Vector(300,300,0)
	keys.caster.shield_particle = ParticleManager:CreateParticle("particles/demon_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW  , keys.caster)
    ParticleManager:SetParticleControl(keys.caster.shield_particle, 0, origin)
    ParticleManager:SetParticleControl(keys.caster.shield_particle, 1, size)
    ParticleManager:SetParticleControl(keys.caster.shield_particle, 6, origin)
    ParticleManager:SetParticleControl(keys.caster.shield_particle, 10, origin)
end

-- Legacy function (replaced by guardian_hell_passive.lua)
function creation(keys)
	print("BOSS PASIV - LEGACY FUNCTION")
	-- This function is no longer used with the new Lua ability system
	-- The functionality has been moved to guardian_hell_passive.lua
end


function flaming_fist(keys)

    -- Inheritted variables
    local caster = keys.caster
    
    -- Use new charge system
    local passive_modifier = caster:FindModifierByName("modifier_guardian_hell_passive")
    if passive_modifier then
        passive_modifier:ConsumeCharge(200)
    else
        -- Fallback to old system if passive not found
        caster.Charge = (caster.Charge or 0) - 200
        if caster.Charge < 0 then caster.Charge = 0 end
    end
    local targetPoint = keys.target_points[1]
    local ability = keys.ability
    local radius = 1000
    local attack_interval = 0.05
    local casterModifierName = "modifier_sleight_of_fist_caster_datadriven"
    local particleSlashName = "particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_tgt.vpcf"
    local particleTrailName = "particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_trail.vpcf"
    local slashSound = "Hero_EmberSpirit.SleightOfFist.Damage"
    
    -- Targeting variables
    local targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
    local targetType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
    local targetFlag = DOTA_UNIT_TARGET_FLAG_NO_INVIS
    local unitOrder = FIND_ANY_ORDER
    
    -- Necessary varaibles
    local counter = 0
    caster.sleight_of_fist_active = true
    local origin = caster:GetAbsOrigin()
    
    local units = FindUnitsInRadius(
        caster:GetTeamNumber(), targetPoint, caster, radius, targetTeam,
        targetType, targetFlag, unitOrder, false
    )
    
    for _, target in pairs( units ) do
        counter = counter + 1
        Timers:CreateTimer( counter * attack_interval, function()
                -- Only jump to it if it's alive
                if target:IsAlive() then
                    -- Create trail particles
                    local trailFxIndex = ParticleManager:CreateParticle( particleTrailName, PATTACH_CUSTOMORIGIN, target )
                    ParticleManager:SetParticleControl( trailFxIndex, 0, target:GetAbsOrigin() )
                    ParticleManager:SetParticleControl( trailFxIndex, 1, caster:GetAbsOrigin() )
                    
                    Timers:CreateTimer( 0.1, function()
                            ParticleManager:DestroyParticle( trailFxIndex, false )
                            ParticleManager:ReleaseParticleIndex( trailFxIndex )
                            return nil
                        end
                    )
                    
                    -- Move hero there
                    FindClearSpaceForUnit( caster, target:GetAbsOrigin(), false )
                    
                    caster:PerformGenericAttack( target, true )
                    
                    -- Slash particles
                    local slashFxIndex = ParticleManager:CreateParticle( particleSlashName, PATTACH_ABSORIGIN_FOLLOW, target )
                    StartSoundEvent( slashSound, caster )
                    
                    Timers:CreateTimer( 0.1, function()
                            ParticleManager:DestroyParticle( slashFxIndex, false )
                            ParticleManager:ReleaseParticleIndex( slashFxIndex )
                            StopSoundEvent( slashSound, caster )
                            return nil
                        end
                    )
                    
                end
                return nil
            end
        )
    end
    
    -- Return caster to origin position
    Timers:CreateTimer( ( counter + 1 ) * attack_interval, function()
            FindClearSpaceForUnit( caster, origin, false )
            caster:RemoveModifierByName( casterModifierName )
            caster.sleight_of_fist_active = false
            return nil
        end
    )
end

function asura_darkness(keys)
	-- Inheritted variables
	local caster = keys.caster
	
	-- Use new charge system
	local passive_modifier = caster:FindModifierByName("modifier_guardian_hell_passive")
	if passive_modifier then
		passive_modifier:ConsumeCharge(200)
	else
		-- Fallback to old system if passive not found
		caster.Charge = (caster.Charge or 0) - 200
		if caster.Charge < 0 then caster.Charge = 0 end
	end
	local targetPoint = keys.target_points[1]
	local ability = keys.ability
	local radius = 1000
	local attack_interval = 0.05
	local casterModifierName = "modifier_sleight_of_fist_caster_datadriven"
	local particleSlashName = "particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_tgt.vpcf"
	local particleTrailName = "particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_trail.vpcf"
	local slashSound = "Hero_EmberSpirit.SleightOfFist.Damage"

	-- Targeting variables
	local targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local targetType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local targetFlag = DOTA_UNIT_TARGET_FLAG_NO_INVIS
	local unitOrder = FIND_ANY_ORDER

	-- Necessary varaibles
	local counter = 0
	caster.sleight_of_fist_active = true
	local origin = caster:GetAbsOrigin()

	local units = FindUnitsInRadius(
		caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, FIND_UNITS_EVERYWHERE, targetTeam,
		targetType, targetFlag, unitOrder, false
	)
	

	for _, target in pairs( units ) do
		target:AddNewModifier(caster, nil, "modifier_mini_chrono", {duration= 3})
	end
end

function hell_on_earth(keys)
	local caster = keys.caster
    keys.ability:StartCooldown(5)
    
    -- Use new charge system
    local passive_modifier = caster:FindModifierByName("modifier_guardian_hell_passive")
    if passive_modifier then
        passive_modifier:ConsumeCharge(50)
    else
        -- Fallback to old system if passive not found
        caster.Charge = (caster.Charge or 0) - 50
        if caster.Charge < 0 then caster.Charge = 0 end
    end
    
	local damage = 250000
	local created_projectile = 0
	local fv = caster:GetForwardVector()
	local rv = caster:GetRightVector()
	local origin = caster:GetAbsOrigin()
	local total_projectile = 40
	local distance = 1500
	local shift = -24
	
	local hellType = RandomInt( 1, 7 )
	if caster.hell_grow == nil then caster.hell_grow = false end

	if caster.hell_grow then
		caster.hell_grow = false
		distance = 0
		position = origin
		shift = 24
	else
		caster.hell_grow = true
	end
	StartRazeSequence( damage, total_projectile, distance, shift, hellType, keys )
end

function warlock_vh_on_death(keys)
	local caster = keys.caster
	local spawnPos = caster:GetAbsOrigin()
	keys.casterTeam = caster:GetTeam()
	-- StartRazeSequence(300000, 20, 1200, -24, 2, keys)
	CreateUnitByName("npc_dota_boss32_trueform_vh", GetGroundPosition(spawnPos + RandomVector(400), nil), true, nil, nil, DOTA_TEAM_NEUTRALS)
	CreateUnitByName("npc_dota_boss32_trueform_vh", GetGroundPosition(spawnPos + RandomVector(400), nil), true, nil, nil, DOTA_TEAM_NEUTRALS)
	StartRazeSequence(300000, 300, 1200, 24, 3, keys)
end

function StartRazeSequence( damage, total_projectile, distance, shift, razeType, keys )
	local caster = keys.caster
	local fv = caster:GetForwardVector()
	local rv = caster:GetRightVector()
	local origin = caster:GetAbsOrigin()
	local created_projectile = 0
	local position = origin + fv*distance
	if razeType == 1 then
		print("RAZE 1")
		total_projectile = total_projectile * 3
		Timers:CreateTimer(0.05, function()
			created_projectile = created_projectile + 1
			createAOEDamage(keys,"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf",position,175,damage,DAMAGE_TYPE_MAGICAL,2.1,"Hero_Invoker.ChaosMeteor.Cast",1.5)
			angle = (created_projectile*1200)/total_projectile
			position = GetGroundPosition(RotatePosition(Vector(0,0,0), QAngle(0,angle,0), fv) * distance + origin,nil)
			
			distance = distance +shift
			if created_projectile <=total_projectile then
				return 0.05
			end
		end)
	elseif razeType == 2 then
		print("RAZE 2")
		-- pentagram
		Timers:CreateTimer(0.05, function()
			created_projectile = created_projectile + 1
			
			for i = 1, 15 do
				angle = 0 + 360*(i-1)/14				
				local linePos = GetGroundPosition(RotatePosition(Vector(0,0,0), QAngle(0,angle,0), fv) * distance + origin,nil)
				createAOEDamage(keys,"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf",linePos,175,damage,DAMAGE_TYPE_MAGICAL,2.1,"Hero_Invoker.ChaosMeteor.Cast",1.5)
			end
			
			distance = distance + shift * 10
			if created_projectile <=total_projectile then
				return 0.05
			end
		end)
	elseif razeType == 3 then
		print("RAZE 3")
		total_projectile = total_projectile / 4
		local casterOrigin = caster:GetAbsOrigin()
		local casterTeamNumber = caster:GetTeamNumber()
		Timers:CreateTimer(0.20, function()
			created_projectile = created_projectile + 1

			local heroes = FindUnitsInRadius(casterTeamNumber, casterOrigin, nil, -1, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, hero in ipairs( heroes ) do
				if not hero:IsNull() and hero:IsAlive() then
					createAOEDamage(keys,"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf",hero:GetAbsOrigin(),175,damage,DAMAGE_TYPE_MAGICAL,2.1,"Hero_Invoker.ChaosMeteor.Cast",1.5)
				end
			end
			-- print( created_projectile, total_projectile )
			if created_projectile <=total_projectile then
				return 0.20
			end
		end)
	elseif razeType == 4 then
		print("RAZE 4 - SWEEPING WALL")
		local row_half_count = 5
		local lateral_spacing = 250
		local step = 150
		local dir = shift < 0 and -1 or 1
		Timers:CreateTimer(0.12, function()
			created_projectile = created_projectile + 1
			for i = -row_half_count, row_half_count do
				local p = GetGroundPosition(position + rv * (i * lateral_spacing), nil)
				createAOEDamage(keys, "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf", p, 175, damage, DAMAGE_TYPE_MAGICAL, 2.1, "Hero_Invoker.ChaosMeteor.Cast", 1.5)
			end
			distance = distance + dir * step
			position = origin + fv * distance
			if created_projectile <= total_projectile then
				return 0.12
			end
		end)
	elseif razeType == 5 then
		print("RAZE 5 - CROSS SWEEP")
		-- Wall 1 sweeps along fv axis, Wall 2 sweeps along rv axis simultaneously
		total_projectile = math.floor(total_projectile / 2)
		local half_count = 3
		local spacing = 420
		local step = 150
		local fv_dist = distance
		local rv_dist = distance
		Timers:CreateTimer(0.10, function()
			created_projectile = created_projectile + 1
			-- Wall 1: bar along rv, sweeping forward/backward along fv
			local wpos1 = origin + fv * fv_dist
			for i = -half_count, half_count do
				local p = GetGroundPosition(wpos1 + rv * (i * spacing), nil)
				createAOEDamage(keys, "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf", p, 175, damage, DAMAGE_TYPE_MAGICAL, 2.1, "Hero_Invoker.ChaosMeteor.Cast", 1.5)
			end
			-- Wall 2: bar along fv, sweeping sideways along rv
			local wpos2 = origin + rv * rv_dist
			for i = -half_count, half_count do
				local p = GetGroundPosition(wpos2 + fv * (i * spacing), nil)
				createAOEDamage(keys, "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf", p, 175, damage, DAMAGE_TYPE_MAGICAL, 2.1, "Hero_Invoker.ChaosMeteor.Cast", 1.5)
			end
			fv_dist = fv_dist - step
			rv_dist = rv_dist - step
			if created_projectile <= total_projectile then
				return 0.10
			end
		end)
	elseif razeType == 6 then
		print("RAZE 6 - ZIGZAG SWEEP")
		-- Sweeping wall with lateral zig-zag offset
		local row_half_count = 3
		local spacing = 420
		local zigzag_amplitude = 600
		local zigzag_period = 6
		local step = 150
		local dir = shift < 0 and -1 or 1
		Timers:CreateTimer(0.12, function()
			created_projectile = created_projectile + 1
			local side = ((created_projectile % (zigzag_period * 2)) < zigzag_period) and 1 or -1
			local center = position + (rv * (side * zigzag_amplitude))
			for i = -row_half_count, row_half_count do
				local p = GetGroundPosition(center + (rv * (i * spacing)), nil)
				createAOEDamage(keys, "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf", p, 175, damage, DAMAGE_TYPE_MAGICAL, 2.1, "Hero_Invoker.ChaosMeteor.Cast", 1.5)
			end
			distance = distance + dir * step
			position = origin + fv * distance
			if created_projectile <= total_projectile then
				return 0.12
			end
		end)
	elseif razeType == 7 then
		print("RAZE 7 - TWIN SPIRAL LIGHT")
		-- Light twin-arm spiral, smoother and symmetric with gentle radius oscillation
		local angle = 0
		local radius = distance
		total_projectile = math.floor(total_projectile * 0.5) -- keep short to avoid heavy coverage
		local angle_step = 18 -- smoother rotation per tick
		local radial_step = shift * 2 -- gentle in/out movement
		local wobble_amp = 120 -- breathing effect on radius
		local wobble_freq = 0.35 -- radians per tick proxy
		Timers:CreateTimer(0.07, function()
			created_projectile = created_projectile + 1
			local effective_r = radius + math.sin(created_projectile * wobble_freq) * wobble_amp
			-- primary arm
			local pos1 = GetGroundPosition(RotatePosition(Vector(0,0,0), QAngle(0,angle,0), fv) * effective_r + origin, nil)
			createAOEDamage(keys, "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf", pos1, 140, damage, DAMAGE_TYPE_MAGICAL, 2.1, "Hero_Invoker.ChaosMeteor.Cast", 1.5)
			-- secondary arm (symmetric)
			local pos2 = GetGroundPosition(RotatePosition(Vector(0,0,0), QAngle(0,angle+180,0), fv) * effective_r + origin, nil)
			createAOEDamage(keys, "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf", pos2, 140, damage, DAMAGE_TYPE_MAGICAL, 2.1, "Hero_Invoker.ChaosMeteor.Cast", 1.5)
			angle = angle + angle_step
			radius = radius + radial_step
			if created_projectile <= total_projectile then
				return 0.07
			end
		end)
	end
end

function createAOEDamage(keys,particlesname,location,size,damage,damage_type,duration,sound,delay)
	if delay == nil then delay = 0 end

    if duration == nil then
        duration = 3
    end
    if damage == nil then
        damage = 5000
    end
    if size == nil then
        size = 250
    end
    if damage_type == nil then
        damage_type = DAMAGE_TYPE_MAGICAL
    end
    if sound ~= nil then
        -- StartSoundEventFromPosition(sound,location)
    end

    local casterTeam = keys.casterTeam or keys.caster:GetTeam()

    local warning_effect = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_fortune_purge_root_ring_glow_rev.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(warning_effect, 0, location)
    ParticleManager:SetParticleControl(warning_effect, 1, Vector(size, size, size))
    ParticleManager:SetParticleControl(warning_effect, 15, Vector(255, 0, 0))

    Timers:CreateTimer(delay, function()
        ParticleManager:ClearParticle(warning_effect)

        local impact_effect = ParticleManager:CreateParticle(particlesname, PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(impact_effect, 0, location)
        ParticleManager:SetParticleControl(impact_effect, 1, location)
        Timers:CreateTimer(duration, function()
            ParticleManager:DestroyParticle(impact_effect, true)
            ParticleManager:ReleaseParticleIndex(impact_effect)
        end)

	    local nearbyUnits = FindUnitsInRadius(casterTeam,
	                                  location,
	                                  nil,
	                                  size,
	                                  DOTA_UNIT_TARGET_TEAM_ENEMY,
	                                  DOTA_UNIT_TARGET_HERO,
	                                  DOTA_UNIT_TARGET_FLAG_NONE,
	                                  FIND_ANY_ORDER,
	                                  false)
        if GetMapName() == "epic_boss_fight_challenger" or GetMapName() == "epic_boss_fight_impossible" or GetMapName() == "epic_boss_fight_nightmare" then
            nearbyUnits = FindUnitsInRadius(keys.caster:GetTeam(),
                                      location,
                                      nil,
                                      size,
                                      DOTA_UNIT_TARGET_TEAM_ENEMY,
                                      DOTA_UNIT_TARGET_ALL,
                                      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                      FIND_ANY_ORDER,
                                      false)
        end
	    for _,unit in pairs(nearbyUnits) do
	        if unit ~= keys.caster then
	                if unit:GetUnitName()~="npc_dota_courier" and unit:GetUnitName()~="npc_dota_flying_courier" then
	                    local damageTableAoe = {victim = unit,
	                                attacker = keys.caster,
	                                damage = damage,
	                                damage_type = damage_type,
	                                }
	                    ApplyDamage(damageTableAoe)
	                end
	        end
	    end
	end)
end
