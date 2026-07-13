--[[
	CHoldoutGameSpawner - A single unit spawner for Holdout.
]]
if CHoldoutGameSpawner == nil then
	CHoldoutGameSpawner = class({})
end


function CHoldoutGameSpawner:ReadConfiguration( name, kv, gameRound )
	self._gameRound = gameRound
	self._dependentSpawners = {}

	self._szChampionNPCClassName = kv.ChampionNPCName or ""
	self._szGroupWithUnit = kv.GroupWithUnit or ""
	self._szName = name
	self._szNPCClassName = kv.NPCName or ""
	self._szSpawnerName = kv.SpawnerName or ""
	self._szWaitForUnit = kv.WaitForUnit or ""
	self._szWaypointName = kv.Waypoint or ""
	self._waypointEntity = nil

	self._nChampionLevel = tonumber( kv.ChampionLevel or 1 )
	self._nChampionMax = tonumber( kv.ChampionMax or 1 )
	self._nCreatureLevel = tonumber( kv.CreatureLevel or 1 )
	self._nTotalUnitsToSpawn = tonumber( kv.TotalUnitsToSpawn or 0 )
	self._nTotalCoreUnitsToSpawn = 0
	if GameRules.BossKV[self._szNPCClassName] and GameRules.BossKV[self._szNPCClassName].ConsideredHero and GameRules.BossKV[self._szNPCClassName].ConsideredHero == "1" then
		self._nTotalCoreUnitsToSpawn = self._nTotalUnitsToSpawn
	end	
	self._nTotalCoreUnitsToSpawn = tonumber( kv.TotalUnitsToSpawn or 0 )
	self._nUnitsPerSpawn = tonumber( kv.UnitsPerSpawn or 0 )
	self._nUnitsPerSpawn = tonumber( kv.UnitsPerSpawn or 1 )

	self._flChampionChance = tonumber( kv.ChampionChance or 0 )
	self._flInitialWait = tonumber( kv.WaitForTime or 0 )
	self._flSpawnInterval = tonumber( kv.SpawnInterval or 0 )

	self._bDontGiveGoal = ( tonumber( kv.DontGiveGoal or 0 ) ~= 0 )
	self._bDontOffsetSpawn = ( tonumber( kv.DontOffsetSpawn or 0 ) ~= 0 )
end


function CHoldoutGameSpawner:PostLoad( spawnerList )
	self._waitForUnit = spawnerList[ self._szWaitForUnit ]
	if self._szWaitForUnit ~= "" and not self._waitForUnit then
		print( "%s has a wait for unit %s that is missing from the round data.", self._szName, self._szWaitForUnit )
	elseif self._waitForUnit then
		table.insert( self._waitForUnit._dependentSpawners, self )
	end

	self._groupWithUnit = spawnerList[ self._szGroupWithUnit ]
	if self._szGroupWithUnit ~= "" and not self._groupWithUnit then
		print ("%s has a group with unit %s that is missing from the round data.", self._szName, self._szGroupWithUnit )
	elseif self._groupWithUnit then
		table.insert( self._groupWithUnit._dependentSpawners, self )
	end
end


function CHoldoutGameSpawner:Precache()
	PrecacheUnitByNameAsync( self._szNPCClassName, function( sg ) self._sg = sg end )
	if self._szChampionNPCClassName ~= "" then
		PrecacheUnitByNameAsync( self._szChampionNPCClassName, function( sg ) self._sgChampion = sg end )
	end
end


function CHoldoutGameSpawner:Begin()
	-- print("[PB] Begin() called for spawner: " .. tostring(self._szSpawnerName))
	self._nUnitsSpawnedThisRound = 0
	self._nChampionsSpawnedThisRound = 0
	self._nUnitsCurrentlyAlive = 0
	self._spawnedUnitsAlive = {}
	self._nKilledThisRound = 0
	self._pbActive = false

	self._vecSpawnLocation = nil
	self._entSpawnerUnit = nil
	self._pbKey = nil
	if self._szSpawnerName ~= "" then
		local entSpawner = Entities:FindByName( nil, self._szSpawnerName )
		if not entSpawner then
			print( string.format( "Failed to find spawner named %s for %s\n", self._szSpawnerName, self._szName ) )
		else
			self._vecSpawnLocation = entSpawner:GetAbsOrigin()
		end
	end

	if self._nTotalUnitsToSpawn > 0 then
		self._pbActive = true
		Timers:CreateTimer(0.5, function()
			if not self._pbActive then return nil end
			for idx, unit in pairs(self._spawnedUnitsAlive) do
				if unit:IsNull() or not unit:IsAlive() then
					self._spawnedUnitsAlive[idx] = nil
					self._nKilledThisRound = self._nKilledThisRound + 1
				end
			end
			return 0.5
		end)
	end
	self._entWaypoint = nil
	if self._szWaypointName ~= "" and not self._bDontGiveGoal then
		self._entWaypoint = Entities:FindByName( nil, self._szWaypointName )
		if not self._entWaypoint then
			print( string.format( "Failed to find waypoint named %s for %s", self._szWaypointName, self._szName ) )
		end
	end

	if self._waitForUnit ~= nil or self._groupWithUnit ~= nil then
		self._flNextSpawnTime = nil
	else
		self._flNextSpawnTime = GameRules:GetGameTime() + self._flInitialWait
	end
end


function CHoldoutGameSpawner:End()
	if self._sg ~= nil then
		UnloadSpawnGroupByHandle( self._sg )
		self._sg = nil
	end
	if self._sgChampion ~= nil then
		UnloadSpawnGroupByHandle( self._sgChampion )
		self._sgChampion = nil
	end
	self._pbActive = false
	self._spawnedUnitsAlive = {}
	self._nKilledThisRound = 0
	self._nLastKillCount = nil
end


function CHoldoutGameSpawner:ParentSpawned( parentSpawner )
	if parentSpawner == self._groupWithUnit then
		-- Make sure we use the same spawn location as parentSpawner.
		self:_DoSpawn()
	elseif parentSpawner == self._waitForUnit then
		if parentSpawner:IsFinishedSpawning() and self._flNextSpawnTime == nil then
			self._flNextSpawnTime = parentSpawner._flNextSpawnTime + self._flInitialWait
		end
	end
end


function CHoldoutGameSpawner:Think()
	if not self._flNextSpawnTime then
		return
	end
	
	if GameRules:GetGameTime() >= self._flNextSpawnTime then
		self:_DoSpawn()
		for _,s in pairs( self._dependentSpawners ) do
			s:ParentSpawned( self )
		end

		if self:IsFinishedSpawning() then
			self._flNextSpawnTime = nil
		else
			self._flNextSpawnTime = self._flNextSpawnTime + self._flSpawnInterval
		end
	end
end


function CHoldoutGameSpawner:GetTotalUnitsToSpawn( coreOnly )
	if not coreOnly then
		return self._nTotalUnitsToSpawn
	else
		return self._nTotalCoreUnitsToSpawn
	end
end


function CHoldoutGameSpawner:IsFinishedSpawning()
	return ( self._nTotalUnitsToSpawn <= self._nUnitsSpawnedThisRound ) or ( self._groupWithUnit ~= nil )
end


function CHoldoutGameSpawner:_GetSpawnLocation()
	if self._groupWithUnit then
		return self._groupWithUnit:_GetSpawnLocation()
	else
		return self._vecSpawnLocation
	end
end


function CHoldoutGameSpawner:_GetSpawnWaypoint()
	if self._groupWithUnit then
		return self._groupWithUnit:_GetSpawnWaypoint()
	else
		return self._entWaypoint
	end
end


function CHoldoutGameSpawner:_UpdateRandomSpawn()
	self._vecSpawnLocation = Vector( 0, 0, 0 )
	self._entWaypoint = nil

	local spawnInfo = self._gameRound:ChooseRandomSpawnInfo()
	if spawnInfo == nil then
		print( string.format( "Failed to get random spawn info for spawner %s.", self._szName ) )
		return
	end
	
	local entSpawner = Entities:FindByName( nil, spawnInfo.szSpawnerName )
	if not entSpawner then
		print( string.format( "Failed to find spawner named %s for %s.", spawnInfo.szSpawnerName, self._szName ) )
		return
	end
	self._vecSpawnLocation = entSpawner:GetAbsOrigin()

	if not self._bDontGiveGoal then
		self._entWaypoint = Entities:FindByName( nil, spawnInfo.szFirstWaypoint )
		if not self._entWaypoint then
			print( string.format( "Failed to find a waypoint named %s for %s.", spawnInfo.szFirstWaypoint, self._szName ) )
			return
		end
	end
end


function CHoldoutGameSpawner:_DoSpawn()
	local nUnitsToSpawn = math.min( self._nUnitsPerSpawn, self._nTotalUnitsToSpawn - self._nUnitsSpawnedThisRound )
	
	if self._currentlyAttemptingToSpawnUnit then return false end
	if nUnitsToSpawn <= 0 then
		return
	elseif self._nUnitsSpawnedThisRound == 0 then
		print( string.format( "Started spawning %s at %.2f", self._szName, GameRules:GetGameTime() ) )
	end

	if self._szSpawnerName == "" then
		self:_UpdateRandomSpawn()
	end

	local vBaseSpawnLocation = self:_GetSpawnLocation()
	if not vBaseSpawnLocation then return end
	for iUnit = 1,nUnitsToSpawn do
		local bIsChampion = RollPercentage( self._flChampionChance )
		if self._nChampionsSpawnedThisRound >= self._nChampionMax then
			bIsChampion = false
		end

		local szNPCClassToSpawn = self._szNPCClassName
		if bIsChampion and self._szChampionNPCClassName ~= "" then
			szNPCClassToSpawn = self._szChampionNPCClassName
		end

		local vSpawnLocation = vBaseSpawnLocation
		if not self._bDontOffsetSpawn then
			vSpawnLocation = vSpawnLocation + RandomVector( RandomFloat( 0, 200 ) )
		end
		self._currentlyAttemptingToSpawnUnit = true
		CreateUnitByNameAsync( szNPCClassToSpawn, vSpawnLocation, true, nil, nil, DOTA_TEAM_NEUTRALS,
		function(entUnit)
			if entUnit:IsCreature() then
				if bIsChampion then
					self._nChampionsSpawnedThisRound = self._nChampionsSpawnedThisRound + 1
					entUnit:CreatureLevelUp( ( self._nChampionLevel - 1 ) )
					entUnit:SetChampion( true )
					local nParticle = ParticleManager:CreateParticle( "heavens_halberd", PATTACH_ABSORIGIN_FOLLOW, entUnit )
					ParticleManager:ReleaseParticleIndex( nParticle )
					entUnit:SetModelScale( 1.1, 0 )
				else
					entUnit:CreatureLevelUp( self._nCreatureLevel - 1 )
				end
			end
			-- Apply round scaling modifier with delay to ensure unit is fully initialized
			local roundNumber = self._gameRound._nRoundNumber or 1
			Timers:CreateTimer(0.5, function()
				if entUnit and not entUnit:IsNull() and entUnit:IsAlive() then
					entUnit:AddNewModifier(entUnit, nil, "modifier_round_scaling", { round = roundNumber })
					print("[EBF] DEBUG: round=" .. roundNumber .. ", aura=" .. (GameRules._currentRoundAuraType or 0) .. ", cursed=" .. (GameRules._currentRoundCursedAuraType or 0))
					-- Also add visible aura modifier if round >= 3 (all mobs in this round share the same type)
					if roundNumber >= 3 then
						local aura_type = GameRules._currentRoundAuraType or 0
						
						if aura_type > 0 then
							-- Always add normal aura
							entUnit:AddNewModifier(entUnit, nil, "modifier_round_scaling_aura", { aura_type = aura_type })
							print("[EBF] Applied aura modifier type " .. aura_type .. " to " .. entUnit:GetUnitName())
						end
						
						-- Cursed aura on top (cached on round object to avoid reset race)
						local cursed_aura = self._gameRound._cursedAuraType or GameRules._currentRoundCursedAuraType or 0
						if cursed_aura > 0 then
							entUnit:AddNewModifier(entUnit, nil, "modifier_round_scaling_cursed_aura", { aura_type = cursed_aura })
							print("[EBF] Applied cursed aura modifier type " .. cursed_aura .. " to " .. entUnit:GetUnitName())
						end
					end
					print("[EBF] Applied round scaling modifier to " .. entUnit:GetUnitName() .. " for round " .. roundNumber)
				end
			end)
			self._nUnitsSpawnedThisRound = self._nUnitsSpawnedThisRound + 1
			if entUnit:IsNull() or not entUnit:IsAlive() then
				-- already dead before callback ran — count it immediately
				self._nKilledThisRound = self._nKilledThisRound + 1
			else
				self._spawnedUnitsAlive[entUnit:entindex()] = entUnit
			end
			self._currentlyAttemptingToSpawnUnit = false
			
			target = entUnit:FindEnemyUnitsInRadius( vSpawnLocation, -1 )[1]
			if target then
				ExecuteOrderFromTable({
					UnitIndex = entUnit:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
					TargetIndex = target:entindex()
				})
			end
			-- local entWp = self:_GetSpawnWaypoint()
			-- if entWp ~= nil then
				-- entUnit:SetInitialGoalEntity( entWp )
			-- end
			self._nUnitsCurrentlyAlive = self._nUnitsCurrentlyAlive + 1
			entUnit.Holdout_IsCore = true
			entUnit:SetDeathXP( 0 )
		end)
	end
end


function CHoldoutGameSpawner:StatusReport()
	print( string.format( "** Spawner %s", self._szNPCClassName ) )
	print( string.format( "%d of %d spawned", self._nUnitsSpawnedThisRound, self._nTotalUnitsToSpawn ) )
end
