EHP_PER_ARMOR = 0.01
DOTA_LIFESTEAL_SOURCE_NONE = 0
DOTA_LIFESTEAL_SOURCE_ATTACK = 1
DOTA_LIFESTEAL_SOURCE_ABILITY = 2

DOTA_RUNES = {DOTA_RUNE_DOUBLEDAMAGE,DOTA_RUNE_HASTE,DOTA_RUNE_ILLUSION,DOTA_RUNE_INVISIBILITY,DOTA_RUNE_REGENERATION,DOTA_RUNE_BOUNTY,DOTA_RUNE_ARCANE}

-- ========================================
-- SERVER CONFIGURATION HELPERS
-- Centralized untuk maintenance yang mudah
-- ========================================
_STAT_SETTINGS_CACHE = nil

function GetStatSettings()
    if not _STAT_SETTINGS_CACHE then
        _STAT_SETTINGS_CACHE = LoadKeyValues("scripts/vscripts/statcollection/settings.kv")
    end
    return _STAT_SETTINGS_CACHE
end

function GetAuthKey()
    local settings = GetStatSettings()
    return GetDedicatedServerKeyV3(settings.modID)
end

function GetServerLocation()
    local settings = GetStatSettings()
    return settings.serverLocation
end

function Context_Wrap(o, funcname)
	return function(...) o[funcname](o, ...) end
end

if not KeyValues then
	KeyValues = {}
end

KeyValues.All = {}

function HasValInTable(checkTable, val)
	for key, value in pairs(checkTable) do
		if value == val then return true end
	end
	return false
end

function TernaryOperator(value, bCheck, default)
	if bCheck then 
		return value 
	else 
		return default
	end
end

function GetPerpendicularVector(vector)
	return Vector(vector.y, -vector.x)
end

function ActualRandomVector(maxLength, flMinLength)
	local minLength = flMinLength or 0
	return RandomVector(RandomInt(minLength, maxLength))
end

function ClampPositionToWorld(vec)
	local min_x, max_x = GetWorldMinX(), GetWorldMaxX()
	local min_y, max_y = GetWorldMinY(), GetWorldMaxY()
	local clamped_x = math.min(math.max(vec.x, min_x), max_x)
	local clamped_y = math.min(math.max(vec.y, min_y), max_y)
	return Vector(clamped_x, clamped_y, vec.z)
end

function randomPointInCircle(center, radius)
	local offset = RandomVector(RandomFloat(0, radius))
	return Vector(center.x + offset.x, center.y + offset.y, center.z)
end

function HasBit(checker, value)
	return bit.band(checker, value) == value
end

function math.sum( lowLimit, upLimit, summation )
	if upLimit == 0 then return 0 end
	local sum = 0
	for i = lowLimit or 0, upLimit do
		sum = sum + summation
	end
	return sum
end

function math.sumT( lowLimit, upLimit, summation )
	if upLimit == 0 then return 0 end
	local sum = 0
	for i = lowLimit or 0, upLimit do
		sum = sum + summation * i
	end
	return sum
end

function splitString( input, seperator)
	seperator = seperator or "%s"
	local output = {}
	for str in input:gmatch("([^"..seperator.."]+)") do
		table.insert( output, str )
	end
	return output
end

function toboolean(thing)
	if not thing then return false end
	if type(thing) == "number" then
		if thing == 1 then return true
		elseif thing == 0 then return false
		else error("number type not 1 or 0") end
	elseif type(thing) == "string" then
		if thing == "true" or thing == "1" then return true
		elseif thing == "false" or thing == "0" then return false
		else error("string type not true or false") end
	end
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
	
    return copy
end

function PrintTable( t, indent )
	--print( "PrintTable( t, indent ): " )

	if type(t) ~= "table" then return end
	
	if indent == nil then
		indent = "   "
	end

	for k,v in pairs( t ) do
		if type( v ) == "table" then
			if ( v ~= t ) then
				print( indent .. tostring( k ) .. ":\n" .. indent .. "{" )
				PrintTable( v, indent .. "  " )
				print( indent .. "}" )
			end
		else
		print( indent .. tostring( k ) .. ":" .. tostring(v) )
		end
	end
end

function CalculateDistance(ent1, ent2)
	local pos1 = ent1
	local pos2 = ent2
	if ent1.GetAbsOrigin then pos1 = ent1:GetAbsOrigin() end
	if ent2.GetAbsOrigin then pos2 = ent2:GetAbsOrigin() end
	local distance = (pos1 - pos2):Length2D()
	return distance
end

function CalculateDirection(ent1, ent2)
	local pos1 = ent1
	local pos2 = ent2
	if ent1.GetAbsOrigin then pos1 = ent1:GetAbsOrigin() end
	if ent2.GetAbsOrigin then pos2 = ent2:GetAbsOrigin() end
	local direction = (pos1 - pos2):Normalized()
	direction.z = 0
	return direction
end

function CDOTA_BaseNPC:CreateDummy(position, duration)
	local dummy = CreateUnitByName("npc_dummy_unit", position, false, nil, nil, self:GetTeam())
	dummy:AddNewModifier(self, nil, "modifier_hidden_generic", {})
	if duration and duration > 0 then
		local kill = dummy:AddNewModifier(self, nil, "modifier_kill", {duration = duration})
	end
	return dummy
end

function CDOTABaseAbility:CreateDummy(position, duration)
	local dummy = CreateUnitByName("npc_dummy_unit", position, false, nil, nil, self:GetCaster():GetTeam())
	dummy:AddNewModifier(self:GetCaster(), nil, "modifier_hidden_generic", {})
	if duration and duration > 0 then
		local kill = dummy:AddNewModifier(self, nil, "modifier_kill", {duration = duration})
	end
	return dummy
end

function CDOTA_BaseNPC_Hero:CreateSummon(unitName, position, duration)
	local summon = CreateUnitByName(unitName, position, true, self, nil, self:GetTeam())
	summon:SetControllableByPlayer(self:GetPlayerID(), true)
	self.summonTable = self.summonTable or {}
	table.insert(self.summonTable, summon)
	summon:SetOwner(self)
	if duration and duration > 0 then
		summon:AddNewModifier(self, nil, "modifier_kill", {duration = duration})
	end
	
	summon:StartGesture( ACT_DOTA_SPAWN )
	return summon
end

function CDOTA_BaseNPC:CreateSummon(unitName, position, duration)
	local summon = CreateUnitByName(unitName, position, true, self, nil, self:GetTeam())
	
	if duration and duration > 0 then
		summon:AddNewModifier(self, nil, "modifier_kill", {duration = duration})
	end
	
	summon:StartGesture( ACT_DOTA_SPAWN )
	return summon
end

function CDOTA_BaseNPC_Hero:RemoveSummon(entity)
	for id,ent in pairs(self.summonTable) do
		if ent == entity then
			table.remove(self.summonTable, id)
		end
	end
end

function CDOTA_BaseNPC:IsBeingAttacked()
	local enemies = FindUnitsInRadius(self:GetTeam(), self:GetAbsOrigin(), nil, 999999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0, false)
	for _, enemy in pairs(enemies) do
		if enemy:IsAttackingEntity(self) then return true end
	end
	return false
end

function CDOTA_BaseNPC:PerformAbilityAttack(target, bProcs, ability)
	self.autoAttackFromAbilityState = {} -- basically the same as setting it to true
	self.autoAttackFromAbilityState.ability = ability
	self:PerformAttack(target,bProcs,bProcs,true,false,false,false,true)
	Timers:CreateTimer(function() self.autoAttackFromAbilityState = nil end)
end

-- function CDOTA_BaseNPC:PerformGenericAttack(target, immediate, neverMiss)
-- 	self:PerformAttack(target, true, true, true, false, not immediate, false, neverMiss or false)
-- end

function CDOTA_BaseNPC:PerformGenericAttack(target, immediate, tAttackData )
	if not IsEntitySafe( self ) then return end
	if not IsEntitySafe( target ) then return end
	local neverMiss = false
	
	local attackData = tAttackData or {}
	local neverMiss = attackData.neverMiss
	local bonusDamage = attackData.bonusDamage
	local bonusDamagePct = attackData.bonusDamagePct
	local suppressCleave = attackData.suppressCleave or false
	local procAttackEffects = attackData.procAttackEffects
	if procAttackEffects == nil then procAttackEffects = true end
	if neverMiss == nil then neverMiss = true end
	local abilityIndex
	if attackData.ability then
		abilityIndex = attackData.ability:entindex()
	end
	
	self.autoAttackFromAbilityState = {} -- basically the same as setting it to true
	self.autoAttackFromAbilityState.abilityIndex = abilityIndex
	
	self:AddNewModifier(self, nil, "modifier_attack_tracker", {})
	self._suppressCleave = false
	if suppressCleave then
		self._suppressCleave = suppressCleave
		self:AddNewModifier(self, nil, "modifier_generic_suppress_cleave", {})
	end
	if bNeverMiss == true then neverMiss = true end
	if bonusDamagePct and bonusDamagePct ~= 0 then
		self:AddNewModifier(self, nil, "modifier_generic_attack_bonus_pct", {damage = bonusDamagePct})
		-- adjust flat bonus damage to account for reduced pct
		bonusDamage = math.floor( (bonusDamage or 0) / (1+(bonusDamagePct-100)/100) )
	end
	if bonusDamage and bonusDamage ~= 0 then
		self:AddNewModifier(self, nil, "modifier_generic_attack_bonus", {damage = bonusDamage})
	end 
	
	self:PerformAttack(target, procAttackEffects, procAttackEffects, true, false, not immediate, false, neverMiss)
	self:RemoveModifierByName("modifier_generic_attack_bonus")
	self:RemoveModifierByName("modifier_generic_attack_bonus_pct")
	self:RemoveModifierByName("modifier_generic_suppress_cleave")
	self._suppressCleave = false
	self.autoAttackFromAbilityState.abilityIndex = nil
end

function CDOTA_Modifier_Lua:AttachEffect(pID)
	self:AddParticle(pID, false, false, 0, false, false)
end

function CDOTA_Modifier_Lua:GetSpecialValueFor(specVal)
	return self:GetAbility():GetSpecialValueFor(specVal)
end

function CDOTABaseAbility:DealDamage(attacker, victim, damage, data, spellText)
	--OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, OVERHEAD_ALERT_DAMAGE, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, OVERHEAD_ALERT_MANA_LOSS
	local internalData = data or {}
	local damageType =  internalData.damage_type or self:GetAbilityDamageType()
	if damageType == 0 or damageType == nil then
		damageType = DAMAGE_TYPE_MAGICAL
	end
	local damageFlags = internalData.damage_flags or DOTA_DAMAGE_FLAG_NONE
	local localdamage = damage or self:GetAbilityDamage() or 0
	local ability = self or internalData.ability
	
	if not IsEntitySafe( victim ) or not victim:IsAlive() then return end
	if not IsEntitySafe( attacker ) or not attacker:IsAlive() then return end
	if not IsEntitySafe( ability ) then return end
	
	local returnDamage = ApplyDamage({victim = victim, attacker = attacker, ability = ability, damage_type = damageType, damage = localdamage, damage_flags = damageFlags})
	if victim and IsEntitySafe( victim ) then
		if spellText then
			SendOverheadEventMessage( nil,spellText,victim,returnDamage,nil)
		end
	end
	
	return returnDamage
end

function IsEntitySafe( entity )
	return entity and IsValidEntity( entity ) and not entity:IsNull() 
end

function IsModifierSafe( entity )
	return entity and not entity:IsNull() 
end

function FindUnitsInCone(teamNumber, vDirection, vPosition, flSideRadius, flLength, hCacheUnit, targetTeam, targetUnit, targetFlags, findOrder, bCache)
	local vDirectionCone = Vector( vDirection.y, -vDirection.x, 0.0 )
	local enemies = FindUnitsInRadius(teamNumber, vPosition, hCacheUnit, flSideRadius + flLength, targetTeam, targetUnit, targetFlags, findOrder, bCache )
	local unitTable = {}
	if #enemies > 0 then
		for _,enemy in pairs(enemies) do
			if enemy ~= nil then
				local vToPotentialTarget = enemy:GetOrigin() - vPosition
				local flSideAmount = math.abs( vToPotentialTarget.x * vDirectionCone.x + vToPotentialTarget.y * vDirectionCone.y + vToPotentialTarget.z * vDirectionCone.z )
				local flLengthAmount = ( vToPotentialTarget.x * vDirection.x + vToPotentialTarget.y * vDirection.y + vToPotentialTarget.z * vDirection.z )
				if ( flSideAmount < flSideRadius ) and ( flLengthAmount > 0.0 ) and ( flLengthAmount < flLength ) then
					table.insert(unitTable, enemy)
				end
			end
		end
	end
	return unitTable
end


function CDOTA_BaseNPC:FindEnemyUnitsInCone(vDirection, vPosition, flSideRadius, flLength, hData)
	if not self:IsNull() then
		local vDirectionCone = Vector( vDirection.y, -vDirection.x, 0.0 )
		local team = self:GetTeamNumber()
		local data = hData or {}
		local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = data.type or DOTA_UNIT_TARGET_ALL
		local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = data.order or FIND_ANY_ORDER
		local enemies = self:FindEnemyUnitsInRadius(vPosition, flSideRadius + flLength, hData)
		local unitTable = {}
		if #enemies > 0 then
			for _,enemy in pairs(enemies) do
				if enemy ~= nil then
					local vToPotentialTarget = enemy:GetOrigin() - vPosition
					local flSideAmount = math.abs( vToPotentialTarget.x * vDirectionCone.x + vToPotentialTarget.y * vDirectionCone.y + vToPotentialTarget.z * vDirectionCone.z )
					local flLengthAmount = ( vToPotentialTarget.x * vDirection.x + vToPotentialTarget.y * vDirection.y + vToPotentialTarget.z * vDirection.z )
					if ( flSideAmount < flSideRadius ) and ( flLengthAmount > 0.0 ) and ( flLengthAmount < flLength ) then
						table.insert(unitTable, enemy)
					end
				end
			end
		end
		return unitTable
	else return {} end
end

function CDOTA_BaseNPC:AddAbilityPrecache(abName)
	PrecacheItemByNameAsync( abName, function() end)
	return self:AddAbility(abName)
end

function AllPlayersAbandoned()
	local playerCounter = 0
	local dcCounter = 0
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			playerCounter = playerCounter + 1
			local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
			if hero then
				if hero:HasOwnerAbandoned() then
					dcCounter = dcCounter + 1
				end
				if PlayerResource:GetConnectionState(hero:GetPlayerID()) == 3 then
					if not hero.lastActiveTime then hero.lastActiveTime = GameRules:GetGameTime() end
					if hero.lastActiveTime + 60*3 < GameRules:GetGameTime() then
						dcCounter = dcCounter + 1
					end
				else
					hero.lastActiveTime = GameRules:GetGameTime()
				end
			else
				dcCounter = dcCounter + 1
			end
		end
	end
	if dcCounter >= playerCounter then
		return true
	else
		return false
	end
end

function CDOTA_PlayerResource:FindActivePlayerCount()
	local playerCounter = 0
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
			if hero then
				if PlayerResource:GetConnectionState(hero:GetPlayerID()) == 2 then
					if not hero.lastActiveTime then hero.lastActiveTime = GameRules:GetGameTime() end
					if hero.lastActiveTime + 60*3 > GameRules:GetGameTime() then
						playerCounter = playerCounter + 1
					end
				end
			end
		end
	end
	return playerCounter
end

function CDOTA_PlayerResource:GetPatronTier(playerID)
	self.patronData = self.patronData or LoadKeyValues( "scripts/kv/patrons.kv" )
	local steamID = self:GetSteamID(playerID)
	local tier = tonumber( self.patronData[tostring(steamID)] ) or -1

	return tier
end

function CDOTA_PlayerResource:GetPatronTier2(playerID)
	local AUTH_KEY = GetAuthKey()
	local SERVER_LOCATION = GetServerLocation()

	local packageLocation = SERVER_LOCATION..AUTH_KEY.."/badge/"..tostring(PlayerResource:GetSteamID(playerID))..'.json'
	local getRequest = CreateHTTPRequestScriptVM( "GET", packageLocation)
end

function MergeTables( t1, t2 )
    for name,info in pairs(t2) do
		if type(info) == "table" and type(t1[name]) == "table" then
			MergeTables(t1[name], info)
		else
			t1[name] = info
		end
	end
end

function PrintAll(t)
	print( "-------",t,"-------" )
	for k,v in pairs(t) do
		print(k,v)
	end
end

function table.removekey(t1, key)
    for k,v in pairs(t1) do
		if k == key then
			table.remove(t1,k)
		end
	end
end

function table.removeval(t1, val)
    for k,v in pairs(t1) do
		if t1[k] == val then
			table.remove(t1,k)
		end
	end
end

function table.shuffle( tbl )
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

function table.copy(t1)
	if t1 == nil then
		return t1
	end
	if type(t1) == 'table' then
		local copy = {}
		for k,v in pairs(t1) do
			local kCopy = table.copy(k)
			local vCopy = table.copy(v)
			copy[kCopy] = vCopy
		end
		return copy
	else
		local copy = t1
		return copy
	end
end

function CDOTA_BaseNPC:HasTalent(talentName)
	if self:HasAbility(talentName) then
		if self:FindAbilityByName(talentName):GetLevel() > 0 then return true end
	end
	return false
end

function CDOTA_BaseNPC:HasActiveAbility()
	return self:GetCurrentActiveAbility() ~= nil or self:IsChanneling()
end

function FindAllEntitiesByClassname(name)
	local entList = {}
	local sortList = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0,0,0), nil, 99999, 3, 63, DOTA_UNIT_TARGET_FLAG_DEAD + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, -1, false)
	for _, unit in pairs(sortList) do
		if unit:GetClassname() == name then
			table.insert(entList, unit)
		end
	end
	return entList
end

function GetTableLength(rndTable)
	local counter = 0
	for k,v in pairs(rndTable) do
		counter = counter + 1
	end
	return counter
end

function CDOTA_BaseNPC:FindTalentValue(talentName, value)
	if self:HasAbility(talentName) then
		return self:FindAbilityByName(talentName):GetSpecialValueFor(value or "value")
	end
	return 0
end

function CDOTA_BaseNPC:NotDead()
	if self:IsAlive() or 
	self:IsReincarnating() or 
	self.resurrectionStoned then
		return true
	else
		return false
	end
end

function CDOTA_BaseNPC:SetCoreHealth(newHP)
	self:SetBaseMaxHealth(newHP)
	self:SetMaxHealth(newHP)
	self:SetHealth(newHP)
end

function CDOTA_BaseNPC:GetAverageBaseDamage()
	return (self:GetBaseDamageMax() + self:GetBaseDamageMin())/2
end

function CDOTA_BaseNPC:SetAverageBaseDamage(average, variance) -- variance is in percent (50 not 0.5)
	local var = variance or 0
	self:SetBaseDamageMax(average*(1+(var/100)))
	self:SetBaseDamageMin(average*(1+(var/100)))
end

function CDOTA_BaseNPC:GetAverageBaseDamageVariance()
	return ( 1 - self:GetBaseDamageMin()/self:GetAverageBaseDamage() ) * 100
end

function CDOTABaseAbility:Refresh()
	-- if not self:IsActivated() then
		-- self:SetActivated(true)
	-- end
	if self.delayedCooldownTimer then self:EndDelayedCooldown() end
    self:EndCooldown()
	if self:GetMaxAbilityCharges( self:GetLevel() ) > 0 then
		self:SetCurrentAbilityCharges( self:GetMaxAbilityCharges( self:GetLevel() ) )
	end
end

function CDOTABaseAbility:GetTrueCastRange()
	local castrange = self:GetCastRange(self:GetCaster():GetAbsOrigin(), self:GetCaster())
	castrange = castrange + self:GetCaster():GetCastRangeBonus()
	if castrange > 0 then
		castrange = castrange + self:GetCaster():GetCastRangeBonus()
	end
	return castrange
end

function CDOTA_BaseNPC:KillTarget()
	if not ( self:IsInvulnerable() or self:IsOutOfGame() or self:IsUnselectable() ) then
		self:ForceKill(true)
	end
end

function CDOTA_BaseNPC:GetAngleDifference(attacker)
	local lineOfAttack = CalculateDirection( attacker, self )
	local angleUnits = ToDegrees( math.acos( DotProduct( self:GetForwardVector(), lineOfAttack ) ) )
	return angleUnits
end

function CDOTA_BaseNPC:IsAtAngleWithEntity(attacker, flDesiredAngle)
	local angleDiff = self:GetAngleDifference(attacker)
	return angleDiff <= flDesiredAngle / 2
end
	
function CDOTA_BaseNPC:RefreshAllCooldowns(bItems)
    local no_refresh_skill = {["arc_warden_tempest_double"] = true, ["dazzle_good_juju"] = true, ["item_refresher"] = true, ["item_ex_machina"] = true, }
    for i = 0, self:GetAbilityCount() - 1 do
        local ability = self:GetAbilityByIndex( i )
        if ability and not no_refresh_skill[ability:GetAbilityName()] and ( ability.IsRefreshable == nil or ability:IsRefreshable() ) then
			ability:Refresh()
        end
    end
	if bItems then
		for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
			local current_item = self:GetItemInSlot(i)
			if current_item ~= nil and not no_refresh_skill[current_item:GetAbilityName()] and ( current_item.IsRefreshable == nil or current_item:IsRefreshable() ) then
				current_item:Refresh()
			end
		end
		local neutralItem =	self:GetItemInSlot(DOTA_ITEM_NEUTRAL_ACTIVE_SLOT)
		if neutralItem and not no_refresh_skill[neutralItem:GetAbilityName()] and ( neutralItem.IsRefreshable == nil or neutralItem:IsRefreshable() ) then
			neutralItem:Refresh()
		end
	end
end

function CDOTA_BaseNPC:RefreshAllIntrinsicModifiers()
	for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
		local current_item = self:GetItemInSlot(i)
		if current_item then
			local passive = self:FindModifierByNameAndAbility( current_item:GetIntrinsicModifierName(), current_item )
			if passive then
				passive:Destroy()
			end
			current_item:RefreshIntrinsicModifier()
		end
	end
	local neutralItem =	self:GetItemInSlot(DOTA_ITEM_NEUTRAL_ACTIVE_SLOT)  
	if neutralItem then
		local passive = self:FindModifierByNameAndAbility( neutralItem:GetIntrinsicModifierName(), neutralItem )
		if passive then
			passive:Destroy()
		end
		neutralItem:RefreshIntrinsicModifier()
	end
	for i = 0, self:GetAbilityCount() - 1 do
		local ability = self:GetAbilityByIndex( i )
		if ability then
			local passive = self:FindModifierByNameAndAbility( ability:GetIntrinsicModifierName(), ability )
			if passive then
				local stacks = 0
				local stackData = table.copy(passive._stackFollowList)
				if passive then
					stacks = passive:GetStackCount()
					passive:Destroy()
				end
				Timers:CreateTimer(1, function()
					ability:RefreshIntrinsicModifier()
					passive = self:FindModifierByNameAndAbility( ability:GetIntrinsicModifierName(), ability )
					if IsModifierSafe( passive ) then
						passive._stackFollowList = stackData
						if passive._stackFollowList then
							passive:AddIndependentStack({stacks = 0, duration = 0})
						end
						passive:SetStackCount( stacks )
					else
						return 1
					end
				end)
			end
		end
	end
	self:CalculateGenericBonuses()
	if self:IsHero() then self:CalculateStatBonus(true) end
end

function CDOTABaseAbility:IsRearmable()
	return ( self.IsRefreshable == nil or self:IsRefreshable() )
end

function CDOTA_BaseNPC:ConjureImage( illusionInfo, duration, caster, amount )
	local illuInfo = illusionInfo or {}
	illuInfo.outgoing_damage = illuInfo.outgoing_damage or 0
	illuInfo.incoming_damage = illuInfo.incoming_damage or 0
	
	if self:IsHero() then
		local params = {caster = caster, target = self, duration = duration, ability = illuInfo.ability, modifier_name = "modifier_illusion"}
		local fDur = duration
		if fDur ~= -1 then
			fDur = duration * caster:GetStatusAmplification( params )
		end
		local illusionTable = CreateIllusions( caster or self , self, {outgoing_damage = illuInfo.outgoing_damage, incoming_damage = illuInfo.incoming_damage, duration = fDur}, amount or 1, self:GetHullRadius() + self:GetCollisionPadding(), illuInfo.scramble or false, true )
		if not illusionTable then return end
		for _, illusion in ipairs( illusionTable ) do
			local trueParent = self
			if self.unitOwnerEntity then
				trueParent = self.unitOwnerEntity
			end
			illusion:SetPhysicalArmorBaseValue( self:GetPhysicalArmorBaseValue() )
			for _, modifier in ipairs( self:FindAllModifiers() ) do
				if modifier.AllowIllusionDuplicate and modifier:AllowIllusionDuplicate() then
					illusion:AddNewModifier( modifier:GetCaster(), modifier:GetAbility(), modifier:GetName(), {duration = modifier:GetRemainingTime()} ):SetStackCount( modifier:GetStackCount() )
				end
			end
			for i = 0, 23 do
				local ability = illusion:GetAbilityByIndex( i )
				if ability then
					ability:SetActivated( false )
					local ownerAbility = self:GetAbilityByIndex( i )
					if ownerAbility then
						ability:SetCooldown (  ownerAbility:GetCooldownTimeRemaining() )
						if ownerAbility:GetAutoCastState() then
							ability:ToggleAutoCast()
						end
					end
				end
			end
			illusion:SetHealth( math.min( illusion:GetMaxHealth(), math.max( self:GetHealth(), 1 ) ) )
			illusion:SetOwner(caster or self)
			illusion:SetMaximumGoldBounty( 0 )
			illusion:SetMinimumGoldBounty( 0 )
			if illuInfo.controllable == false then
				illusion:SetControllableByPlayer(-1, true)
			end
			if illuInfo.position then
				FindClearSpaceForUnit( illusion, illuInfo.position, true )
			end
			if illuInfo.illusion_modifier then
				illusion:AddNewModifier( caster or self, illuInfo.ability, illuInfo.illusion_modifier, {} )
			end
			illusion.hasBeenInitialized = true
			Timers:CreateTimer(0.1, function() ResolveNPCPositions( illusion:GetAbsOrigin(), 128 ) end )
		end
		return illusionTable
	else
		local illusionTable = {}
		local owner = caster or self
		for i = 1, (amount or 1) do
			local illusion = CreateUnitByName( self:GetUnitName(), illuInfo.position or self:GetAbsOrigin(), true, owner, owner, owner:GetTeamNumber() )
			if illuInfo.illusion_modifier then
				illusion:AddNewModifier( caster or self, illuInfo.ability, illuInfo.illusion_modifier, {duration = duration} )
			else
				illusion:AddNewModifier( caster or self, illuInfo.ability, "modifier_illusion", {duration = duration} )
			end
			illusion:AddNewModifier( caster or self, illuInfo.ability, "modifier_kill", {duration = duration} )
			illusion:SetOwner(caster or self)
			for i = 0, 23 do
				local ability = illusion:GetAbilityByIndex( i )
				if ability then
					ability:SetActivated( false )
					local ownerAbility = self:GetAbilityByIndex( i )
					if ownerAbility then
						ability:SetCooldown (  ownerAbility:GetCooldownTimeRemaining() )
					end
				end
			end
			for itemSlot=0,5 do
				local item = self:GetItemInSlot(itemSlot)
				if item ~= nil then
					local itemName = item:GetName()
					local newItem = self:GetItemInSlot(itemSlot)
					if not newItem then
						newItem = self:AddItemByName( itemName )
					end
				end
			end	
			illusion:SetBaseDamageMax( self:GetBaseDamageMax() - 10 )
			illusion:SetBaseDamageMin( self:GetBaseDamageMin() - 10 )
			illusion:SetPhysicalArmorBaseValue( self:GetPhysicalArmorBaseValue() )
			illusion:SetBaseAttackTime( self:GetBaseAttackTime(true) )
			illusion:SetBaseMoveSpeed( self:GetBaseMoveSpeed() )
			illusion:SetMaximumGoldBounty( 0 )
			illusion:SetMinimumGoldBounty( 0 )
			if illuInfo.controllable == false then
				illusion:SetControllableByPlayer(-1, true)
			else
				illusion:SetControllableByPlayer(caster:GetPlayerID(), true)
			end
			Timers:CreateTimer(0.1, function() ResolveNPCPositions( illusion:GetAbsOrigin(), 128 ) end )
			table.insert( illusionTable, illusion )
		end
		return illusionTable
	end
end

function CDOTA_BaseNPC:GetTauntTarget()
	return self._currentlyBeingTauntedBy
end

function CDOTA_BaseNPC:SetTauntTarget( entity )
	self._currentlyBeingTauntedBy = entity
end

function CBaseEntity:RollPRNG( percentage )
	return RollPseudoRandomPercentage( percentage, self:entindex() * 1000, self )
end

function CDOTA_Ability_Lua:RollPRNG( percentage )
	return RollPseudoRandomPercentage( percentage, self:GetAbility():entindex() * 1000, self:GetCaster() )
end

function CDOTA_Modifier_Lua:RollPRNG( percentage )
	return RollPseudoRandomPercentage( percentage, self:GetAbility():entindex() * 1000 + self:GetSerialNumber(), self:GetParent() )
end

function CDOTABaseAbility:IsInnateAbility()
	local truefalse = tonumber( self:GetAbilityKeyValues().InnateAbility ) or 0
	if truefalse == 1 then
		return true
	else
		return false
	end
end

function CDOTA_BaseNPC:IsSlowed()
	return self:GetIdealSpeed() < self:GetIdealSpeedNoSlows()
end

function CDOTA_BaseNPC:IsLeashed()
	for _, modifier in ipairs( self:FindAllModifiers() ) do
		local tState = {}
		modifier:CheckStateToTable(tState)
		if tState[tostring(MODIFIER_STATE_TETHERED)] then
			return true
		end
	end
	return false
end

function CDOTA_BaseNPC:IsDisabled()
	if self:IsSlowed() or self:IsStunned() or self:IsRooted() or self:IsSilenced() or self:IsHexed() or self:IsDisarmed() then 
		return true
	else return false end
end

function CDOTA_BaseNPC:GetPhysicalArmorMultiplier()
	local armorNPC = self:GetPhysicalArmorValue(false)
	local armor_reduction = CalculatePhysicalArmorMultiplier( armorNPC )
	return armor_reduction
end

function CalculatePhysicalArmorMultiplier( armor )
	return 1 - (0.03 * armor) / (1 + 0.03 * math.abs(armor))
end


function CDOTA_BaseNPC:GetPhysicalArmorReduction()
	local armornpc = self:GetPhysicalArmorValue(false)
	local armor_reduction = self:GetPhysicalArmorMultiplier()
	armor_reduction = 100 - (armor_reduction * 100)
	return armor_reduction
end

function CDOTA_BaseNPC:GetRealPhysicalArmorReduction()
	local armornpc = self:GetPhysicalArmorValue()
	local armor_reduction = 1 - (EHP_PER_ARMOR * armornpc) / (1 + (EHP_PER_ARMOR * math.abs(armornpc)))
	armor_reduction = 100 - (armor_reduction * 100)
	return armor_reduction
end

function CDOTA_BaseNPC:FindModifierByAbility(abilityname)
	local modifiers = self:FindAllModifiers()
	local returnTable = {}
	for _,modifier in pairs(modifiers) do
		if modifier:GetAbility():GetName() == abilityname then
			table.insert(returnTable, modifier)
		end
	end
	return returnTable
end

function CDOTA_BaseNPC:FindModifierByNameAndAbility( modifierName, ability )
	local modifiers = self:FindAllModifiersByName( modifierName )
	local returnTable = {}
	for _,modifier in pairs(modifiers) do
		if modifier:GetAbility() == ability then
			return modifier
		end
	end
end

function CDOTA_BaseNPC:IsFakeHero()
	if self:IsIllusion() 
	or (self:HasModifier("modifier_monkey_king_fur_army_soldier") or self:HasModifier("modifier_monkey_king_fur_army_soldier_hidden")) 
	or self:IsTempestDouble() or self:IsClone()
	or self:GetUnitLabel() == "spirit_bear" then
		return true
	else return false end
end

function CDOTABaseAbility:GetTalentSpecialValueFor(value)
	local base = self:GetSpecialValueFor(value)
	local talentName
	local valname = "value"
	local multiply = false
	local kv = self:GetAbilityKeyValues()
	for k,v in pairs(kv) do -- trawl through keyvalues
		if k == "AbilitySpecial" then
			for l,m in pairs(v) do
				if m[value] then
					talentName = m["LinkedSpecialBonus"]
					if m["LinkedSpecialBonusField"] then valname = m["LinkedSpecialBonusField"] end
					if m["LinkedSpecialBonusOperation"] and m["LinkedSpecialBonusOperation"] == "SPECIAL_BONUS_MULTIPLY" then multiply = true end
				end
			end
		end
	end
	if talentName then 
		local talent = self:GetCaster():FindAbilityByName(talentName)
		if talent and talent:GetLevel() > 0 then 
			if multiply then
				base = base * talent:GetSpecialValueFor(valname) 
			else
				base = base + talent:GetSpecialValueFor(valname) 
			end
		end
	end
	return base
end

function CDOTA_Modifier_Lua:GetTalentSpecialValueFor(value)
	return self:GetAbility():GetTalentSpecialValueFor(value)
end

function CDOTA_Buff:HasBeenRefreshed()
	if self:GetCreationTime() + self:GetDuration() < self:GetDieTime() then -- if original destroy time is smaller than new destroy time
		return true
	else
		return false
	end
end

function CDOTABaseAbility:SetCooldown(fCD)
	if fCD then
		self:EndCooldown()
		self:StartCooldown(fCD)
	else
		self:UseResources(false, false, false, true)
	end
end

function CDOTABaseAbility:SpendAbilityCharge()
	local abilityChargeRestoreTime = self:GetAbilityChargeRestoreTime(-1) * (1-self:GetCaster():GetCooldownReduction())
	self:SetCurrentAbilityCharges( self:GetCurrentAbilityCharges() - 1 )
	if self:GetCurrentAbilityCharges() == 0 then
		self:SetCooldown(abilityChargeRestoreTime)
	end
end

function CDOTABaseAbility:ModifyCooldown(amt)
	local currCD = self:GetCooldownTimeRemaining()
	self:EndCooldown()
	self:StartCooldown(currCD + amt)
end

function CDOTABaseAbility:StartDelayedCooldown()
	local remaining = self:GetCooldownTimeRemaining()
	if remaining <= 0 then
		remaining = self:GetAbilityCooldown(self:GetLevel()) * (1 - self:GetCaster():GetCooldownReduction())
	end
	self.delayedCooldownValue = remaining
	self:EndCooldown()
	self:StartCooldown(99999)
	self.delayedCooldownTimer = true
end

function CDOTABaseAbility:EndDelayedCooldown()
	if not self.delayedCooldownTimer then return end
	self.delayedCooldownTimer = nil
	self:EndCooldown()
	local cd = self.delayedCooldownValue or 0
	self.delayedCooldownValue = nil
	if cd > 0 then
		self:StartCooldown(cd)
	end
end

function CScriptHeroList:GetRealHeroes()
	local heroes = self:GetAllHeroes()
	local realHeroes = {}
	for _,hero in pairs(heroes) do
		if not hero:IsFakeHero() then
			table.insert(realHeroes, hero)
		end
	end
	return realHeroes
end

function CScriptHeroList:GetRealHeroCount()
	return #self:GetRealHeroes()
end

function CScriptHeroList:GetActiveHeroes()
	local heroes = self:GetRealHeroes()
	local activeHeroes = {}
	for _, hero in pairs(heroes) do
		if hero:GetPlayerOwner() then
			table.insert(activeHeroes, hero)
		end
	end
	return activeHeroes
end

function CScriptHeroList:GetActiveHeroCount()
	return #self:GetActiveHeroes()
end

function RotateVector2D(vector, theta)
    local xp = vector.x*math.cos(theta)-vector.y*math.sin(theta)
    local yp = vector.x*math.sin(theta)+vector.y*math.cos(theta)
    return Vector(xp,yp,vector.z):Normalized()
end

function ToRadians(degrees)
	return degrees * math.pi / 180
end

function ToDegrees(radians)
	return radians * 180 / math.pi 
end

function CDOTA_BaseNPC:IsSameTeam(unit)
	return (self:GetTeamNumber() == unit:GetTeamNumber())
end

function CDOTA_BaseNPC:HealEvent(amount, sourceAb, healer)
	local healBonus = 1
	local flAmount = amount
	if healer then
		for _,modifier in ipairs( healer:FindAllModifiers() ) do
			if modifier.GetOnHealBonus then
				healBonus = healBonus + ((modifier:GetOnHealBonus() or 0)/100)
			end
		end
	end
	
	flAmount = flAmount * healBonus
	local params = {amount = flAmount, source = sourceAb, unit = healer, target = self}
	-- local units = self:FindAllUnitsInRadius(self:GetAbsOrigin(), -1)
	
	-- for _, unit in ipairs(units) do
		-- if unit.FindAllModifiers then
			-- for _, modifier in ipairs( unit:FindAllModifiers() ) do
				-- if modifier.OnHealed then
					-- modifier:OnHealed(params)
				-- end
				-- if modifier.OnHeal then
					-- modifier:OnHeal(params)
				-- end
				-- if modifier.OnHealRedirect then
					-- local reduction = modifier:OnHealRedirect(params) or 0
					-- flAmount = flAmount + reduction
				-- end
			-- end
		-- end
	-- end
	local preHP = self:GetHealth()
	self:HealWithParams(flAmount, sourceAb, false, true, healer, false)
	local postHP = self:GetHealth()
	SendOverheadEventMessage(self, OVERHEAD_ALERT_HEAL, self, postHP - preHP, healer)
	return postHP - preHP
end

function CDOTA_BaseNPC:SwapAbilityIndexes(index, swapname)
	local ability = self:GetAbilityByIndex(index)
	local swapability = self:FindAbilityByName(swapname)
	self:SwapAbilities(ability:GetName(), swapname, false, true)
	swapability:SetAbilityIndex(index)
end

CDOTA_BaseNPC.SwapAbilities_Engine = CDOTA_BaseNPC.SwapAbilities_Engine or CDOTA_BaseNPC.SwapAbilities
function CDOTA_BaseNPC:SwapAbilities(ability_name1, ability_name2, enable1, enable2)
	self:SwapAbilities_Engine(ability_name1, ability_name2, enable1, enable2)

	if enable1 then
		local ability1 = self:FindAbilityByName(ability_name1)
		if ability1 then ability1:SetHidden(false) end
	end

	if enable2 then
		local ability2 = self:FindAbilityByName(ability_name2)
		if ability2 then ability2:SetHidden(false) end
	end
end

function FindAllUnits()
	local team = DOTA_TEAM_GOODGUYS
	local data = hData or {}
	local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_BOTH
	local iType = data.type or DOTA_UNIT_TARGET_ALL
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_DEAD
	local iOrder = data.order or FIND_ANY_ORDER
	return FindUnitsInRadius(team, Vector(0,0), nil, -1, iTeam, iType, iFlag, iOrder, false)
end

function CDOTA_BaseNPC:FindEnemyUnitsInLine(startPos, endPos, width, hData)
	local team = self:GetTeamNumber()
	local data = hData or {}
	local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = data.type or DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
	return FindUnitsInLine(team, startPos, endPos, nil, width, iTeam, iType, iFlag)
end

function CDOTA_BaseNPC:FindFriendlyUnitsInLine(startPos, endPos, width, hData)
	local team = self:GetTeamNumber()
	local data = hData or {}
	local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = data.type or DOTA_UNIT_TARGET_ALL
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
	return FindUnitsInLine(team, startPos, endPos, nil, width, iTeam, iType, iFlag)
end

function CDOTA_BaseNPC:FindAllUnitsInLine(startPos, endPos, width, hData)
	local team = self:GetTeamNumber()
	local data = hData or {}
	local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_BOTH
	local iType = data.type or DOTA_UNIT_TARGET_ALL
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
	return FindUnitsInLine(team, startPos, endPos, nil, width, iTeam, iType, iFlag)
end

function CDOTA_BaseNPC:FindEnemyUnitsInRing(position, maxRadius, minRadius, hData)
	if not self:IsNull() then
		local team = self:GetTeamNumber()
		local data = hData or {}
		local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = data.type or DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
		local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = data.order or FIND_ANY_ORDER
	
		local innerRing = FindUnitsInRadius(team, position, nil, minRadius, iTeam, iType, iFlag, iOrder, false)
		local outerRing = FindUnitsInRadius(team, position, nil, maxRadius, iTeam, iType, iFlag, iOrder, false)
		local resultTable = {}
		for _, unit in ipairs(outerRing) do
			if not unit:IsNull() then
				local addToTable = true
				for _, exclude in ipairs(innerRing) do
					if unit == exclude then
						addToTable = false
						break
					end
				end
				if addToTable then
					table.insert(resultTable, unit)
				end
			end
		end
		return resultTable
		
	else return {} end
end

function CDOTA_BaseNPC:FindEnemyUnitsInRadius(position, radius, hData)
	if not self:IsNull() then
		local team = self:GetTeamNumber()
		local data = hData or {}
		local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = data.type or DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
		local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = data.order or FIND_ANY_ORDER
		return FindUnitsInRadius(team, position, nil, radius, iTeam, iType, iFlag, iOrder, false)
	else return {} end
end

function CDOTA_BaseNPC:FindFriendlyUnitsInRadius(position, radius, hData)
	local team = self:GetTeamNumber()
	local data = hData or {}
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = data.type or DOTA_UNIT_TARGET_ALL
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = data.order or FIND_ANY_ORDER
	return FindUnitsInRadius(team, position, nil, radius, iTeam, iType, iFlag, iOrder, false)
end

function CDOTA_BaseNPC:FindAllUnitsInRadius(position, radius, hData)
	local team = self:GetTeamNumber()
	local data = hData or {}
	local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_BOTH
	local iType = data.type or DOTA_UNIT_TARGET_ALL
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = data.order or FIND_ANY_ORDER
	return FindUnitsInRadius(team, position, nil, radius, iTeam, iType, iFlag, iOrder, false)
end

function ParticleManager:FireWarningParticle(position, radius)
	local thinker = ParticleManager:CreateParticle("particles/ui_mouseactions/range_finder_ward_aoe_ring.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(thinker, 2, position)
			ParticleManager:SetParticleControl(thinker, 3, Vector(radius,0,0))
	Timers:CreateTimer( 0.5, function() ParticleManager:ClearParticle( thinker ) end )
end

function ParticleManager:FireDangerParticle(position, radius)
	local thinker = ParticleManager:CreateParticle("particles/dark_moon/darkmoon_creep_warning_pulse.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl( thinker, 0, position)
	ParticleManager:SetParticleControl( thinker, 1,  Vector(radius, 0, 0) )
	ParticleManager:SetParticleControl( thinker, 15, Vector( 255, 0, 0 ) )
	Timers:CreateTimer( 0.5, function() ParticleManager:ClearParticle( thinker ) end )
end

function ParticleManager:FireGenericWarningParticle( position, endPos, radius )
	local thinker = ParticleManager:CreateParticle("particles/ui_mouseactions/range_finder_tower_aoe.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(thinker, 0, position)
			ParticleManager:SetParticleControl(thinker, 2, endPos)
			ParticleManager:SetParticleControl(thinker, 3, Vector(radius,0,0))
			ParticleManager:SetParticleControl(thinker, 4, Vector(255,0,0))
			ParticleManager:SetParticleControl(thinker, 6, Vector(radius,0,0))
			ParticleManager:SetParticleControl(thinker, 7, position )
	Timers:CreateTimer( 0.5, function()
		ParticleManager:ClearParticle( thinker ) 
	end )
end

function ParticleManager:FireLinearWarningParticle(vStartPos, vEndPos, vWidth)
	local width = Vector(vWidth, vWidth, vWidth)
	local fx = ParticleManager:FireParticle("particles/ui_mouseactions/range_ability_line.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = vStartPos,
																											[1] = vEndPos,
																											[2] = width} )																						
end

function ParticleManager:FireTargetWarningParticle(target)
	local fx = ParticleManager:CreateParticle("particles/ui_mouseactions/generic_marker.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
end

function ParticleManager:FireParticle(effect, attach, owner, cps)
	local FX = ParticleManager:CreateParticle(effect, attach, owner)
	if cps then
		for cp, value in pairs(cps) do
			if type(value) == "userdata" then
				ParticleManager:SetParticleControl(FX, tonumber(cp), value)
			else
				ParticleManager:SetParticleControlEnt(FX, cp, owner, attach, value, owner:GetAbsOrigin(), true)
			end
		end
	end
	ParticleManager:ReleaseParticleIndex(FX)
end

function ParticleManager:FireRopeParticle(effect, attach, owner, target, tCP)
	local FX = ParticleManager:CreateParticle(effect, attach, owner)

	ParticleManager:SetParticleControlEnt(FX, 0, owner, attach, "attach_hitloc", owner:GetAbsOrigin(), true)
	if target.GetAbsOrigin then -- npc (has getabsorigin function
		ParticleManager:SetParticleControlEnt(FX, 1, target, attach, "attach_hitloc", target:GetAbsOrigin(), true)
	else
		ParticleManager:SetParticleControl(FX, 1, target) -- vector
	end
	
	if tCP then
		for cp, value in pairs(tCP) do
			ParticleManager:SetParticleControl(FX, tonumber(cp), value)
		end
	end
	
	ParticleManager:ReleaseParticleIndex(FX)
end


function ParticleManager:CreateRopeParticle(effect, attach, owner, target, tCP)
	local FX = ParticleManager:CreateParticle(effect, attach, owner)

	ParticleManager:SetParticleControlEnt(FX, 0, owner, attach, "attach_hitloc", owner:GetAbsOrigin(), true)
	if target.GetAbsOrigin then -- npc (has getabsorigin function
		ParticleManager:SetParticleControlEnt(FX, 1, target, attach, "attach_hitloc", target:GetAbsOrigin(), true)
	else
		ParticleManager:SetParticleControl(FX, 1, target) -- vector
	end
	
	if tCP then
		for cp, value in pairs(tCP) do
			ParticleManager:SetParticleControl(FX, tonumber(cp), value)
		end
	end
	
	return FX
end

function ParticleManager:ClearParticle(cFX)
	if cFX then
		self:DestroyParticle(cFX, false)
		self:ReleaseParticleIndex(cFX)
	end
end

function CDOTA_Modifier_Lua:StartMotionController()
	if not self:GetParent():IsNull() and not self:IsNull() and self.DoControlledMotion and self:GetParent():HasMovementCapability() then
		self:GetParent():StopMotionControllers()
		self:GetParent():InterruptMotionControllers(true)
		self.controlledMotionTimer = Timers:CreateTimer(function()
			if pcall( function() self:DoControlledMotion() end ) then
				return 0.03
			elseif not self:IsNull() then
				self:Destroy()
			end
		end)
	else
	end
end

function CDOTA_Modifier_Lua:AddIndependentStack(duration, limit, bDontDestroy, tTimerTable)
	local timerTable = tTimerTable or {}
	self.stackTimers = self.stackTimers or {}
	if limit then
		if  self:GetStackCount() < limit then
			if timerTable.stacks then
				self:SetStackCount( math.min( limit, self:GetStackCount() + timerTable.stacks ) )
			else
				self:IncrementStackCount()
			end
		elseif self.stackTimers[1] and #self.stackTimers >= limit then
			self:SetStackCount( limit )
			Timers:RemoveTimer(self.stackTimers[1].ID)
			table.remove(self.stackTimers, 1)
		end
	else
		if timerTable.stacks then
			self:SetStackCount( self:GetStackCount() + timerTable.stacks )
		else
			self:IncrementStackCount()
		end
	end
	local dontDestroy = bDontDestroy
	if bDontDestroy == nil then dontDestroy = true end
	timerTable.ID = Timers:CreateTimer(duration or self:GetRemainingTime(), function(timer)
		if not self:IsNull() then
			if timerTable.stacks then	
				self:SetStackCount( math.max( 0, self:GetStackCount() - timerTable.stacks ) )
			else
				self:DecrementStackCount()
			end
			for i = #self.stackTimers, 1, -1 do
				if timer.name == self.stackTimers[i].ID then
					table.remove(self.stackTimers, pos)
					break
				end
			end
			if self:GetStackCount() == 0 and self:GetDuration() == -1 and not dontDestroy then self:Destroy() end
		end
	end)
	
	table.insert(self.stackTimers, timerTable or {})
	return timerTable
end

function CDOTA_Modifier_Lua:StopMotionController(bForceDestroy)
	FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), true)
	if self.controlledMotionTimer then Timers:RemoveTimer(self.controlledMotionTimer) end
	self:Destroy()
end

function CDOTA_BaseNPC:StopMotionControllers(bForceDestroy)
	if self.InterruptMotionControllers then self:InterruptMotionControllers(true) end
	for _, modifier in ipairs( self:FindAllModifiers() ) do
		if modifier.controlledMotionTimer then 
			modifier:StopMotionController(bForceDestroy)
		end
	end
end

function CDOTA_Modifier_Lua:AddEffect(id)
	self:AddParticle(id, false, false, 0, false, false)
end

function CDOTA_Buff:AddEffect(id)
	self:AddParticle(id, false, false, 0, false, false)
end

function CDOTA_Buff:AddStatusEffect(id, priority)
	self:AddParticle(id, false, true, priority, false, false)
end

function CDOTA_Buff:AddOverHeadEffect(id)
	self:AddParticle(id, false, false, 0, false, true)
end

function CDOTA_Buff:AddHeroEffect(id)
	self:AddParticle(id, false, false, 0, true, false)
end

function CDOTA_BaseNPC:FindRandomEnemyInRadius(position, radius, data)
	for _, unit in ipairs(self:FindEnemyUnitsInRadius(position, radius, data)) do
		return unit
	end
end

function CDOTA_BaseNPC:Blink(position, blinkData)
	if self:IsNull() then return end
	local vPos = position
	local tData = blinkData or {}
	EmitSoundOn("DOTA_Item.BlinkDagger.Activate", self)
	if tData.FX == true or tData.FX == nil then
		ParticleManager:FireParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, self, {[0] = self:GetAbsOrigin()})
	end
	local distance = CalculateDistance( self, position )
	
	if tData.distance and distance > tData.distance then
		if tData.clamp then
			vPos = self:GetAbsOrigin() + CalculateDirection( vPos, self ) * tData.clamp
		else
			vPos = self:GetAbsOrigin() + CalculateDirection( vPos, self ) * tData.distance
		end
	else
		EmitSoundOn("DOTA_Item.BlinkDagger.NailedIt", self)
	end
	
	FindClearSpaceForUnit(self, vPos, true)
	ProjectileManager:ProjectileDodge( self )
	if tData.FX == true or tData.FX == nil then
		ParticleManager:FireParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, self, {[0] = self:GetAbsOrigin()})
	end
end

function CDOTA_BaseNPC:GetStrength()
	return 0
end

function CDOTA_BaseNPC:GetAgility()
	return 0
end

function CDOTA_BaseNPC:GetIntellect()
	return 0
end

function CDOTA_BaseNPC:Dispel(hCaster, bHard)
	local sameTeam = (hCaster:GetTeam() == self:GetTeam())
	local hardDispel = bHard
	if hardDispel == nil then hardDispel = false end
	self:Purge(not sameTeam, sameTeam, false, hardDispel, hardDispel)
end

function CDOTA_BaseNPC:SmoothFindClearSpace(position)
	self:SetAbsOrigin(position)
	ResolveNPCPositions(position, self:GetHullRadius() + self:GetCollisionPadding())
end

function CDOTABaseAbility:Stun(target, duration, effectName, effectData)
	if not target or target:IsNull() then return end
	local stun = target:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = duration})
	if effectName then
		local FX = ParticleManager:CreateParticle(effectName, PATTACH_POINT_FOLLOW, target)
		if effectData then
			for cp, value in pairs(effectData) do
				if type(value) == "userdata" then
					ParticleManager:SetParticleControl(FX, tonumber(cp), value)
				else
					ParticleManager:SetParticleControlEnt(FX, cp, target, attach, value, target:GetAbsOrigin(), true)
				end
			end
		end
		stun:AddEffect( FX )
	end
	return stun
end

function CDOTABaseAbility:Silence(target, duration)
	return target:AddNewModifier(self:GetCaster(), self, "modifier_silence", {duration = duration})
end

function CDOTABaseAbility:FireLinearProjectile(FX, velocity, distance, width, data)
	local internalData = data or {}
	local info = {
		EffectName = FX,
		Ability = self,
		vSpawnOrigin = internalData.origin or self:GetCaster():GetAbsOrigin(), 
		fStartRadius = width,
		fEndRadius = internalData.width_end or width,
		vVelocity = velocity,
		fDistance = distance,
		Source = internalData.source or self:GetCaster(),
		iUnitTargetTeam = internalData.team or DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = internalData.type or DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		ExtraData = internalData.extraData
	}
	return ProjectileManager:CreateLinearProjectile( info )
end

function CDOTAGameRules:GetMaxRound()
	return GameRules.maxRounds
end

function CDOTAGameRules:GetCurrentRound()
	return GameRules._roundnumber
end

function CDOTA_BaseNPC:AddNewModifierStacking( caster, ability, modifierName, modifierData)
	local modifier = self:FindModifierByNameAndAbility( modifierName, ability )
	if modifier then
		modifierData.duration = (modifierData.duration or modifierData.Duration or 0) + modifier:GetRemainingTime()
		modifierData.Duration = nil
		return self:AddNewModifier( caster, ability, modifierName, modifierData )
	else
		return self:AddNewModifier( caster, ability, modifierName, modifierData )
	end
end

function CDOTA_BaseNPC:AttemptKill(sourceAb, attacker)
	ApplyDamage({victim = self, attacker = attacker, ability = sourceAb, damage_type = DAMAGE_TYPE_PURE, damage = self:GetMaxHealth() + 1, damage_flags = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS})
	return not self:IsAlive()
end

function CDOTA_BaseNPC:ApplyKnockBack(position, stunDuration, knockbackDuration, distance, height, caster, ability)
	local caster = caster or nil
	local ability = ability or nil

	local modifierKnockback = {
		center_x = position.x,
		center_y = position.y,
		center_z = position.z,
		should_stun = TernaryOperator( 1, stunDuration and stunDuration > 0, 0 ),
		duration = math.max( knockbackDuration, stunDuration ),
		knockback_duration = knockbackDuration,
		knockback_distance = distance,
		knockback_height = height,
	}
	return self:AddNewModifier(caster, ability, "modifier_knockback", modifierKnockback )
end

function CDOTA_BaseNPC:IsKnockedBack()
	if self:HasModifier("modifier_knockback") then
		return true
	else
		return false
	end
end

function CDOTABaseAbility:CastSpell(target)
	local caster = self:GetCaster()
	if target then
		if target.GetAbsOrigin then -- npc
			caster:SetCursorCastTarget(target)
			caster:SetCursorPosition(target:GetAbsOrigin())
		else
			caster:SetCursorPosition(target)
		end
	end
	self:OnSpellStart()
	self:UseResources(true, true, true, true)
end

function CDOTA_BaseNPC:InWater()
	if self:HasModifier("modifier_in_water") then
		return true
	else
		return false
	end
end

function CDOTA_BaseNPC:HasShard()
	return self:HasModifier("modifier_item_aghanims_shard")
end

function CDOTABaseAbility:FireTrackingProjectile(FX, target, speed, data, iAttach, bDodge, bVision, vision)
	local internalData = data or {}
	local dodgable = true
	if bDodge ~= nil then dodgable = bDodge end
	local provideVision = false
	if bVision ~= nil then provideVision = bVision end
	local origin = self:GetCaster():GetAbsOrigin()
	if internalData.origin then
		origin = internalData.origin
	elseif internalData.source then
		origin = internalData.source:GetAbsOrigin()
	end
	local projectile = {
		Target = target,
		Source = internalData.source or self:GetCaster(),
		Ability = self,	
		EffectName = FX,
	    iMoveSpeed = speed,
		vSourceLoc= origin or self:GetCaster():GetAbsOrigin(),
		bDrawsOnMinimap = false,
        bDodgeable = dodgable,
        bIsAttack = false,
        bVisibleToEnemies = true,
        bReplaceExisting = false,
        flExpireTime = internalData.duration,
		bProvidesVision = provideVision,
		iVisionRadius = vision or 100,
		iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
		iSourceAttachment = iAttach or DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
		ExtraData = internalData.extraData
	}
	return ProjectileManager:CreateTrackingProjectile(projectile)
end

function GameRules:GetPlayerGoldMultiplier()
	return math.max( 1, 1 + (6 - HeroList:GetActiveHeroCount())/20 )
end

function CDOTA_BaseNPC:AddGold( val, bIgnoreBonus )
	if self:GetPlayerID() >= 0 then
		local hero = PlayerResource:GetSelectedHeroEntity( self:GetPlayerID() )
		if hero then
			local baseGold = val or 0
			local bonusGold = 0
			local gold = baseGold
			
			-- gold handling
			if not bIgnoreBonus then
				-- local midas = hero:FindModifierByName("modifier_hand_of_midas_passive")
			
				-- if midas then
					-- bonusGold = baseGold * (midas.bonus_gold or 0)
				-- end
				if hero:HasAbility("alchemist_goblins_greed") then
					bonusGold = baseGold * hero:FindAbilityByName("alchemist_goblins_greed"):GetSpecialValueFor("bonus_gold")  / 100
				end
				bonusGold = bonusGold + baseGold * (GameRules:GetPlayerGoldMultiplier()-1)
			end
			local newGold = hero:GetGold() + gold + bonusGold
			hero:SetGold(0, false)
			newGold = newGold + (hero.bonusGoldExcessValue or 0)
			hero.bonusGoldExcessValue = newGold % 1
			
			hero:SetGold(math.floor(newGold), true)
			
			-- notification handling
			local showGold = math.floor( gold )
			SendOverheadEventMessage(self:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, self, showGold, self:GetPlayerOwner())
			
			if bonusGold > 0 then
				Timers:CreateTimer( 0.25, function()
					SendOverheadEventMessage(self:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, self, math.floor( bonusGold ), self:GetPlayerOwner())
				end)
			end
			
			return gold
		end
	end
end

function CDOTA_BaseNPC:GetMagicalArmorValue( bUseExperimentalFormula, ability )
	return self:Script_GetMagicalArmorValue( bUseExperimentalFormula, ability )
end

function CDOTA_BaseNPC:ReduceMana( mana, ability )
	return self:Script_ReduceMana( mana, ability )
end

function CDOTA_BaseNPC:IsDeniable()
	return self:Script_IsDeniable()
end

function CDOTA_BaseNPC:GetAttackRange()
	return self:Script_GetAttackRange()
end


MAP_MMR = {
["epic_boss_fight_normal"] = 1200,
["epic_boss_fight_hard"] = 3500,
["epic_boss_fight_challenger"] = 3700,
["epic_boss_fight_nightmare"] = 4000,
["epic_boss_fight_purgatory"] = 4300,
["epic_boss_fight_soul"] = 4300,
["epic_boss_fight_ad"] = 4300,
["epic_boss_fight_god"] = 4300,
}

MMR_WEIGHT = 3000
K_FACTOR = 60

function CalculateExpectedWinrate( map, playerMMR )
	local mapMMR = MAP_MMR[map]
	if not mapMMR and map and string.find(map, "_ad") ~= nil then
		mapMMR = MAP_MMR["epic_boss_fight_ad"]
	end
	if not mapMMR or not playerMMR then return end
	local mmrDiff = mapMMR - playerMMR
	local mmrWeightedDiff = mmrDiff / MMR_WEIGHT
	return 1 / ( 1 + 10^mmrWeightedDiff )
end

function CalculateMMRChangeForPlayer( map, playerMMR, win )
	local expectedWR = CalculateExpectedWinrate( map, playerMMR )
	if not expectedWR then return end
	
	local score = win and 1 or 0
	local newMMR = playerMMR + K_FACTOR * ( score - expectedWR )
	
	return newMMR
end

function CDOTABaseAbility:UnitFilter( target )
	local caster = self:GetCaster()
	
	if PlayerResource:IsDisableHelpSetForPlayerID( target:GetPlayerOwnerID(), caster:GetPlayerOwnerID() ) then
		DisplayError( caster:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
		return UF_FAIL_DISABLE_HELP
	else
		return UnitFilter( target, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), caster:GetTeam() )
	end
end

function DisplayError(playerID, message)
	local player = PlayerResource:GetPlayer(playerID)
	if player then
		CustomGameEventManager:Send_ServerToPlayer(player, "ebf_error_message", {message=message})
	end
end

function CDOTA_BaseNPC:GetManaType()
	return self._heroManaType or "Mana"
end

-- Serversided function only
function CDOTA_BaseNPC:DropItem(hItem, sNewItemName, bLaunchLoot)
	local vLocation = GetGroundPosition(self:GetAbsOrigin(), self)
	local sName
	local vRandomVector = RandomVector(100)

	if hItem then
		sName = hItem:GetName()
		self:DropItemAtPositionImmediate(hItem, vLocation)
	else
		sName = sNewItemName
		hItem = CreateItem(sNewItemName, nil, nil)
		CreateItemOnPositionSync(vLocation, hItem)
	end

	if sName == "item_imba_rapier" then
		hItem:GetContainer():SetRenderColor(230, 240, 35)
	elseif sName == "item_imba_rapier_2" then
		hItem:GetContainer():SetRenderColor(240, 150, 30)
		hItem.rapier_pfx = ParticleManager:CreateParticle("particles/item/rapier/item_rapier_trinity.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(hItem.rapier_pfx, 0, vLocation + vRandomVector)
	elseif sName == "item_imba_rapier_magic" then
		hItem:GetContainer():SetRenderColor(35, 35, 240)
	elseif sName == "item_imba_rapier_magic_2" then
		hItem:GetContainer():SetRenderColor(140, 70, 220)
		hItem.rapier_pfx = ParticleManager:CreateParticle("particles/item/rapier/item_rapier_archmage.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(hItem.rapier_pfx, 0, vLocation + vRandomVector)
	elseif sName == "item_imba_rapier_cursed" then
		hItem.rapier_pfx = ParticleManager:CreateParticle("particles/item/rapier/item_rapier_cursed.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(hItem.rapier_pfx, 0, vLocation + vRandomVector)
		hItem.x_pfx = ParticleManager:CreateParticle("particles/item/rapier/cursed_x.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(hItem.x_pfx, 0, vLocation + vRandomVector)
	end

	if bLaunchLoot then
		hItem:LaunchLoot(false, 250, 0.5, vLocation + vRandomVector, nil)
	end
end

function CDOTA_Modifier_Lua:CheckUnique(bCreated)
	local hParent = self:GetParent()
	if bCreated then
		local mod = hParent:FindAllModifiersByName(self:GetName())
		if #mod >= 2 then
			self:SetStackCount(1)
			return true
		else
			self:SetStackCount(0)
			return false
		end
	else
		if self:GetStackCount() == 0 then
			local mod = hParent:FindModifierByName(self:GetName())
			if mod then
				mod:SetStackCount(0)
			end
		end
		return nil
	end
end

function GetCastRangeIncrease(unit)
	local cast_range_increase = 0
	-- Only the greatefd st increase counts for items, they do not stack
	for _, parent_modifier in pairs(unit:FindAllModifiers()) do
		if parent_modifier.GetModifierCastRangeBonus then
			cast_range_increase = math.max(cast_range_increase, parent_modifier:GetModifierCastRangeBonus())
		end
	end

	for _, parent_modifier in pairs(unit:FindAllModifiers()) do
		if parent_modifier.GetModifierCastRangeBonusStacking and parent_modifier:GetModifierCastRangeBonusStacking() then
			cast_range_increase = cast_range_increase + parent_modifier:GetModifierCastRangeBonusStacking()
		end
	end

	return cast_range_increase
end

function CDOTABaseAbility:GetVanillaAbilitySpecial(key)
	return GetAbilityValue(self:GetVanillaAbilityName(), key, self:GetLevel()) or 0
end

function CDOTABaseAbility:GetVanillaAbilityName()
	return GetVanillaAbilityName(self:GetAbilityName())
end

function GetVanillaAbilityName(ability_name)
	return string.gsub(ability_name, "imba_", "")
end

function GetAbilityValue(name, key, level)
	local t = KeyValues.All[name]

	if key and t then
		local AbilitySpecials = t["AbilitySpecial"]

		if AbilitySpecials then
			for k, v in pairs(AbilitySpecials) do
				for i, j in pairs(v) do
					if i ~= "var_type" and i ~= "LinkedSpecialBonus" and i ~= "RequiresScepter" and i ~= "CalculateSpellDamageTooltip" then
						if i == key then
							if not level or type(j) == "number" then -- no level specified or there is only 1 ability value regardless of level
								-- print("Return table value:", j)
								return j
							else
								if type(j) == "table" and j["value"] then
									j = j["value"]
								end

								local s = split(j)
								if s[level] then
									return tonumber(s[level]) -- If we match the level, return that one
								else
									return tonumber(s[#s])
								end -- Otherwise, return the max
							end

							break
						end
					end
				end
			end
		else
			local tspecial = t["AbilityValues"]

			if tspecial then
				-- Find the key we are looking for
				for ability_key, value in pairs(tspecial) do
					if ability_key == key then
						if not level or type(value) == "number" then -- no level specified or there is only 1 ability value regardless of level
							-- print("Return table value:", value)
							return value
						else
							if type(value) == "table" and value["value"] then
								value = value["value"]
							end

							local s = split(value)
							if s[level] then
								return tonumber(s[level]) -- If we match the level, return that one
							else
								return tonumber(s[#s])
							end -- Otherwise, return the max
						end

						break
					end
				end
			end
		end
	else
		return t
	end
end


function CDOTA_Modifier_Lua:CheckMotionControllers()
	local parent = self:GetParent()
	local modifier_priority = self:GetMotionControllerPriority()
	local is_motion_controller = false
	local motion_controller_priority
	local found_modifier_handler

	local non_imba_motion_controllers =
	{"modifier_brewmaster_storm_cyclone",
	 "modifier_dark_seer_vacuum",
	 "modifier_eul_cyclone",
	 "modifier_earth_spirit_rolling_boulder_caster",
	 "modifier_huskar_life_break_charge",
	 "modifier_invoker_tornado",
	 "modifier_item_forcestaff_active",
	 "modifier_rattletrap_hookshot",
	 "modifier_phoenix_icarus_dive",
	 "modifier_shredder_timber_chain",
	 "modifier_slark_pounce",
	 "modifier_spirit_breaker_charge_of_darkness",
	 "modifier_tusk_walrus_punch_air_time",
	 "modifier_earthshaker_enchant_totem_leap"}
	

	-- Fetch all modifiers
	local modifiers = parent:FindAllModifiers()	

	for _,modifier in pairs(modifiers) do		
		-- Ignore the modifier that is using this function
		if self ~= modifier then			

			-- Check if this modifier is assigned as a motion controller
			if modifier.IsMotionController then
				if modifier:IsMotionController() then
					-- Get its handle
					found_modifier_handler = modifier

					is_motion_controller = true

					-- Get the motion controller priority
					motion_controller_priority = modifier:GetMotionControllerPriority()

					-- Stop iteration					
					break
				end
			end

			-- If not, check on the list
			for _,non_imba_motion_controller in pairs(non_imba_motion_controllers) do				
				if modifier:GetName() == non_imba_motion_controller then
					-- Get its handle
					found_modifier_handler = modifier

					is_motion_controller = true

					-- We assume that vanilla controllers are the highest priority
					motion_controller_priority = DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST

					-- Stop iteration					
					break
				end
			end
		end
	end

	-- If this is a motion controller, check its priority level
	if is_motion_controller and motion_controller_priority then

		-- If the priority of the modifier that was found is higher, override
		if motion_controller_priority > modifier_priority then			
			return false

		-- If they have the same priority levels, check which of them is older and remove it
		elseif motion_controller_priority == modifier_priority then			
			if found_modifier_handler:GetCreationTime() >= self:GetCreationTime() then				
				return false
			else				
				found_modifier_handler:Destroy()
				return true
			end

		-- If the modifier that was found is a lower priority, destroy it instead
		else			
			parent:InterruptMotionControllers(true)
			found_modifier_handler:Destroy()
			return true
		end
	else
		-- If no motion controllers were found, apply
		return true
	end
end


--Load ability KVs
-- local AbilityKV = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")

-- function C_DOTA_BaseNPC:FindTalentValue(talentName, key)
-- 	if self:HasModifier("modifier_"..talentName) then  
-- 		local value_name = key or "value"
-- 		local specialVal = AbilityKV[talentName]["AbilitySpecial"]
-- 		for l,m in pairs(specialVal) do
-- 			if m[value_name] then
-- 				return m[value_name]
-- 			end
-- 		end
-- 	end    
-- 	return 0
-- end

-- Rolls a Psuedo Random chance. If failed, chances increases, otherwise chances are reset
-- Numbers taken from https://gaming.stackexchange.com/a/290788
function RollPseudoRandom(base_chance, entity)
	local chances_table = {
		{1, 0.015604},
		{2, 0.062009},
		{3, 0.138618},
		{4, 0.244856},
		{5, 0.380166},
		{6, 0.544011},
		{7, 0.735871},
		{8, 0.955242},
		{9, 1.201637},
		{10, 1.474584},
		{11, 1.773627},
		{12, 2.098323},
		{13, 2.448241},
		{14, 2.822965},
		{15, 3.222091},
		{16, 3.645227},
		{17, 4.091991},
		{18, 4.562014},
		{19, 5.054934},
		{20, 5.570404},
		{21, 6.108083},
		{22, 6.667640},
		{23, 7.248754},
		{24, 7.851112},
		{25, 8.474409},
		{26, 9.118346},
		{27, 9.782638},
		{28, 10.467023},
		{29, 11.171176},
		{30, 11.894919},
		{31, 12.637932},
		{32, 13.400086},
		{33, 14.180520},
		{34, 14.981009},
		{35, 15.798310},
		{36, 16.632878},
		{37, 17.490924},
		{38, 18.362465},
		{39, 19.248596},
		{40, 20.154741},
		{41, 21.092003},
		{42, 22.036458},
		{43, 22.989868},
		{44, 23.954015},
		{45, 24.930700},
		{46, 25.987235},
		{47, 27.045294},
		{48, 28.100764},
		{49, 29.155227},
		{50, 30.210303},
		{51, 31.267664},
		{52, 32.329055},
		{53, 33.411996},
		{54, 34.736999},
		{55, 36.039785},
		{56, 37.321683},
		{57, 38.583961},
		{58, 39.827833},
		{59, 41.054464},
		{60, 42.264973},
		{61, 43.460445},
		{62, 44.641928},
		{63, 45.810444},
		{64, 46.966991},
		{65, 48.112548},
		{66, 49.248078},
		{67, 50.746269},
		{68, 52.941176},
		{69, 55.072464},
		{70, 57.142857},
		{71, 59.154930},
		{72, 61.111111},
		{73, 63.013699},
		{74, 64.864865},
		{75, 66.666667},
		{76, 68.421053},
		{77, 70.129870},
		{78, 71.794872},
		{79, 73.417722},
		{80, 75.000000},
		{81, 76.543210},
		{82, 78.048780},
		{83, 79.518072},
		{84, 80.952381},
		{85, 82.352941},
		{86, 83.720930},
		{87, 85.057471},
		{88, 86.363636},
		{89, 87.640449},
		{90, 88.888889},
		{91, 90.109890},
		{92, 91.304348},
		{93, 92.473118},
		{94, 93.617021},
		{95, 94.736842},
		{96, 95.833333},
		{97, 96.907216},
		{98, 97.959184},
		{99, 98.989899},	
		{100, 100}
	}

	entity.pseudoRandomModifier = entity.pseudoRandomModifier or 0
	local prngBase
	for i = 1, #chances_table do
		if base_chance == chances_table[i][1] then		  
			prngBase = chances_table[i][2]
		end	 
	end

	if not prngBase then
--		print("The chance was not found! Make sure to add it to the table or change the value.")
		return false
	end
	
	if RollPercentage( prngBase + entity.pseudoRandomModifier ) then
		entity.pseudoRandomModifier = 0
		return true
	else
		entity.pseudoRandomModifier = entity.pseudoRandomModifier + prngBase		
		return false
	end
end

function UsedBookMessage(caster, color, message)
	local playerID = caster:GetPlayerID()
	local pingerHero = PlayerResource:GetPlayer(playerID):GetAssignedHero():GetName()
	local hero_icon = "<img class=\"InlineImage HeroIcon\" src=\"file://{images}/heroes/" .. pingerHero .. ".png\" />"

	GameRules:SendCustomMessage(hero_icon .. " Just used <font color='" .. color .."'>" .. message .."</font>", 0, 0)
end

function ImbaCustomMessage(caster, color, message)
	
	local hero_icon = "<img class=\"InlineImage HeroIcon\" src=\"file://{images}/heroes/" .. caster .. ".png\" />"

	GameRules:SendCustomMessage(hero_icon .. " <font color='" .. color .."'>" .. message .."</font>", 0, 0)
end

function CDOTA_BaseNPC:SetUnitOnClearGround()
	Timers:CreateTimer(FrameTime(), function()
		self:SetAbsOrigin(Vector(self:GetAbsOrigin().x, self:GetAbsOrigin().y, GetGroundPosition(self:GetAbsOrigin(), self).z))		
		FindClearSpaceForUnit(self, self:GetAbsOrigin(), true)
		ResolveNPCPositions(self:GetAbsOrigin(), 64)
	end)
end

function printf(...)
    print(string.format(...))
end

function Custom_bIsStrongIllusion(unit)
	if not unit or unit:IsNull() then
		return
	end
	local strong_illu_modifiers = {
		"modifier_chaos_knight_phantasm_illusion",
		"modifier_imba_chaos_knight_phantasm_illusion",
		"modifier_vengefulspirit_hybrid_special",
		"modifier_chaos_knight_phantasm_illusion_shard",
	}
	for _, v in pairs(strong_illu_modifiers) do
		if unit:HasModifier(v) then
			return true
		end
	end
	return unit:IsStrongIllusion()
end

function GetRandomAbility()
    return LIST_ABILITIES[RandomInt(1, #LIST_ABILITIES)]
end

--[[
    RollDrops(unit: CDOTA_BaseNPC)
    unit: CDOTA_BaseNPC - unit to roll drops for
--]]
function RollDrops(unit)
	local eventConfig = CustomNetTables:GetTableValue('choosen_difficulty', 'saved')
	local diff = eventConfig.class

	local mapName = GetMapName()
	if mapName == "epic_boss_fight_soul" or mapName == "epic_boss_fight_god" then
		local unit_name = unit:GetUnitName()
		if unit_name ~= "npc_dota_alche_greed" and unit_name ~= "npc_dota_lightning_revenant" and unit_name ~= "npc_dota_zeus_god" then
			return
		end
		if mapName == "epic_boss_fight_soul" then
			local soulLevel = GameRules.SoulLevel or 0
			if soulLevel < 20 then return end
		end
	else
		-- Non-soul maps keep S-difficulty restriction (no drops in S1–S5)
		if diff == "S1" or diff == "S2" or diff == "S3" or diff == "S4" or diff == "S5" then return end
	end
    local DropInfo = GameRules.DropTable[unit:GetUnitName()]
    if DropInfo then
        for item_name,chance in pairs(DropInfo) do
            if RollPercentage(chance) then
                -- Create the item
                local item = CreateItem(item_name, nil, nil)
                local center = GetGroundPosition(unit:GetAbsOrigin(), unit)
				center = Vector(0.193817,-4.272217,397.000000)
                local minRadius, maxRadius = 2000, 2600
                local drop_target
                for attempt = 1, 15 do
                    local candidate = randomPointInCircle(center, maxRadius)
                    if (candidate - center):Length2D() < minRadius then
                        goto continue
                    end

                    candidate = ClampPositionToWorld(candidate)
                    candidate = GetGroundPosition(candidate, unit)

                    if GridNav:IsTraversable(candidate)
                        and not GridNav:IsBlocked(candidate)
                        and GridNav:CanFindPath(center, candidate) then
                        drop_target = candidate
                        break
                    end
                    ::continue::
                end

                if not drop_target then
                    local fallback = ClampPositionToWorld(center + ActualRandomVector(maxRadius, minRadius))
                    drop_target = GetGroundPosition(fallback, unit)
                end

                CreateItemOnPositionSync(center, item)
                item:LaunchLoot(false, 200, 0.75, drop_target, nil)
            end
        end
    end
end


--[[
	Check is player in S or A difficulty
]]
function CheckDifficulty()
	local eventConfig = CustomNetTables:GetTableValue('choosen_difficulty', 'saved')
	local diff = eventConfig.class
	
	if diff == "S1" or diff == "S2" or diff == "S3" or diff == "S4" or diff == "S5"
	 or diff == "A1" or diff == "A2" or diff == "A3" or diff == "A4" or diff == "A5" then
		return true
	end

	return false
end

function CDOTA_BaseNPC:IsSpiritBear()
    return self:GetUnitLabel() == "spirit_bear"
end

function GetBearOwnerHero(bear)
    if not IsValidEntity(bear) then return end
    local owner = bear:GetOwner()
    if not IsValidEntity(owner) then return end

    if owner:GetClassname() == "dota_player_controller" then
        return owner:GetAssignedHero()
    end

    return owner
end

function CDOTA_BaseNPC:IsMonkeyClone()
    return (self:HasModifier("modifier_monkey_king_fur_army_soldier") or self:HasModifier("modifier_wukongs_command_warrior"))
end

function SanitizeTable(tbl)
	local clean = {}
  
	for k, v in pairs(tbl) do
	  if type(v) == "table" then
		clean[k] = SanitizeTable(v)
	  elseif type(v) == "string" or type(v) == "number" or type(v) == "boolean" then
		clean[k] = v
	  end
	end
  
	return clean
  end
  

function ConvertUnixToDateTime(unixTimestamp)
    local daysInMonth = {
        31, 28, 31, 30, 31, 30,
        31, 31, 30, 31, 30, 31
    }
    local monthNames = {
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    }

    local function isLeapYear(year)
        return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
    end

    local seconds = unixTimestamp
    local minute = 60
    local hour = 60 * minute
    local day = 24 * hour

    -- Start from 1970
    local year = 1970
    while true do
        local daysInYear = isLeapYear(year) and 366 or 365
        if seconds >= daysInYear * day then
            seconds = seconds - daysInYear * day
            year = year + 1
        else
            break
        end
    end

    -- Adjust for leap year
    if isLeapYear(year) then
        daysInMonth[2] = 29
    end

    local month = 1
    while true do
        local secondsInMonth = daysInMonth[month] * day
        if seconds >= secondsInMonth then
            seconds = seconds - secondsInMonth
            month = month + 1
        else
            break
        end
    end

    local dayOfMonth = math.floor(seconds / day) + 1
    seconds = seconds % day
    local hourOfDay = math.floor(seconds / hour)
    seconds = seconds % hour
    local minuteOfHour = math.floor(seconds / minute)
    local secondOfMinute = seconds % minute

    local monthName = monthNames[month]

    return string.format("%s %d, %d at %02d:%02d:%02d", monthName, dayOfMonth, year, hourOfDay, minuteOfHour, secondOfMinute)
end

-- FOR 7.39
-- Apply a modifier only if it's not from the same source ability otherwise just refresh
function CDOTA_BaseNPC:ApplyNonStackableBuff(caster, ability, mod_name, duration)
    if not ability then
        return
    end
    local applied_by_this_ability = false
    local ability_name = ability:GetAbilityName()
    local mods = self:FindAllModifiersByName(mod_name)
    for _, mod in pairs(mods) do
        if mod and not mod:IsNull() then
            local mod_ability = mod:GetAbility()
            if mod_ability then
                local mod_ability_name = mod_ability:GetAbilityName()
                if mod_ability_name == ability_name then
                    --if string.find(mod_ability_name, string.sub(ability_name, 0, string.len(ability_name)-4)) then
                    -- if having items with multiple levels and similar name
                    applied_by_this_ability = true
                    mod:ForceRefresh()
                    break
                end
            end
        end
    end
    if not applied_by_this_ability then
        return self:AddNewModifier(caster, ability, mod_name, {duration = duration})
    end
end

function String2Vector(s)
    local array = string.split(s, " ")
    return Vector(array[1], array[2], array[3])
end

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == "") then
        return false
    end
    local pos, arr = 0, {}
    -- for each divider found
    for st, sp in function()
        return string.find(input, delimiter, pos, true)
    end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function CBaseEntity:SetAbsOrigin(point)
	-- printf("SetAbsOrigin: %s", point)
    self:SetOrigin(point)
end
