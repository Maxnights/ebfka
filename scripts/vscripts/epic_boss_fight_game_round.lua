--[[
	CHoldoutGameRound - A single round of Holdout
]]

if CHoldoutGameRound == nil then
	CHoldoutGameRound = class({})
end

require("libraries/Timers")

local FFA_TEAM_SEQUENCE = {
	DOTA_TEAM_CUSTOM_1,
	DOTA_TEAM_CUSTOM_2,
	DOTA_TEAM_CUSTOM_3,
	DOTA_TEAM_CUSTOM_4,
	DOTA_TEAM_CUSTOM_5,
	DOTA_TEAM_CUSTOM_6,
	DOTA_TEAM_CUSTOM_7,
	DOTA_TEAM_CUSTOM_8,
	DOTA_TEAM_BADGUYS,
}

local FREE_FOR_ALL_ROUND = 13
local FIND_ALL_UNITS_FINISH_CHECK_INTERVAL = 2.0


function CHoldoutGameRound:ReadConfiguration( kv, gameMode, roundNumber )
	self._gameMode = gameMode
	self._nRoundNumber = roundNumber


	self._szRoundQuestTitle = kv.round_quest_title or "#DOTA_Quest_Holdout_Round"
	self._szRoundTitle = kv.round_title or string.format( "Round%d", roundNumber )

	self._nMaxGold = tonumber( kv.MaxGold or 0 )
	self._nBagCount = tonumber( kv.BagCount or 0 )
	self._nBagVariance = tonumber( kv.BagVariance or 0 )
	self._nFixedXP = tonumber( kv.FixedXP or 0 )

	self._vSpawners = {}
	for k, v in pairs( kv ) do
		if type( v ) == "table" and v.NPCName then
			local spawner = CHoldoutGameSpawner()
			spawner:ReadConfiguration( k, v, self )
			self._vSpawners[ k ] = spawner
		end
	end

	for _, spawner in pairs( self._vSpawners ) do
		spawner:PostLoad( self._vSpawners )
	end
end


function CHoldoutGameRound:Precache()
	for _, spawner in pairs( self._vSpawners ) do
		spawner:Precache()
	end
end

function CHoldoutGameRound:spawn_treasure()
	random = math.random(0,100)
	if (random > 80) then
		local Item_spawn = CreateItem( "item_present_treasure", nil, nil )
		Timers:CreateTimer(0.03,function()
			local max_player = DOTA_MAX_TEAM_PLAYERS
			WID = math.random(0,max_player)
			if PlayerResource:GetConnectionState(WID) == 2 then
				local player = PlayerResource:GetPlayer(WID)
				local hero = player:GetAssignedHero() 
				hero:AddItem(Item_spawn)
			else
				return 0.03
			end
		end)
	end
end

function CHoldoutGameRound:SpawnFreeForAllOrb(count)
	count = count or 1
	print("[EBF FFA] SpawnFreeForAllOrb() called! count=" .. count)
	if not IsServer() then
		print("[EBF FFA] Not server, aborting")
		return
	end

	print("[EBF FFA] Spawning " .. count .. " FFA orb(s) and setting up Free For All mode...")
	EmitGlobalSound("Item.PickUpGemWorld")
	self:SetFreeForAllFogState(true)

	self._ffaCapturePoints = {}

	local center = Vector(2.387512, 2.394592, 397.000000)
	local radius = count > 1 and 500 or 0
	local particle_name = "particles/orb_epic.vpcf"

	for i = 1, count do
		local spawn_point
		if count == 1 then
			spawn_point = center
		else
			local angle = (i - 1) * (2 * math.pi / count)
			spawn_point = center + Vector(radius * math.cos(angle), radius * math.sin(angle), 0)
		end

		local capture_point = CreateUnitByName("npc_dummy_capture", spawn_point, false, nil, nil, DOTA_TEAM_NEUTRALS)
		capture_point:SetAbsOrigin(spawn_point)
		capture_point:AddNewModifier(capture_point, nil, "capture_point_area", { orb_type = 3, should_launch = true })
		table.insert(self._ffaCapturePoints, capture_point)

		capture_point.orb_fx = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, capture_point)
		ParticleManager:SetParticleControl(capture_point.orb_fx, 0, capture_point:GetAbsOrigin())
	end

	print("[EBF FFA] Orb(s) spawned, now assigning players to FFA teams...")
	-- self:AssignPlayersToFreeForAllTeams()
end

function CHoldoutGameRound:AssignPlayersToFreeForAllTeams()
	print("[EBF FFA] AssignPlayersToFreeForAllTeams() called")
	local heroes = {}
	for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
		if hero:IsRealHero() and hero:GetPlayerID() ~= -1 then
			table.insert(heroes, hero)
		end
	end

	print("[EBF FFA] Found " .. #heroes .. " active heroes")

	if #heroes <= 2 then
		print("[EBF FFA] Not enough players (need more than 2), aborting FFA team assignment")
		return
	end

	if #heroes > #FFA_TEAM_SEQUENCE then
		print("[CaptureOrbFFA] Not enough unique team slots for all players, some will share a team.")
	end

	for index, hero in ipairs(heroes) do
		local playerID = hero:GetPlayerID()
		local team = FFA_TEAM_SEQUENCE[((index - 1) % #FFA_TEAM_SEQUENCE) + 1]

		if not team then
			break
		end

		local oldTeam = hero:GetTeamNumber()
		print("[EBF FFA] Assigning player " .. playerID .. " (" .. hero:GetUnitName() .. ") from team " .. oldTeam .. " to team " .. team)

		if playerID ~= nil and playerID ~= -1 then
			PlayerResource:SetCustomTeamAssignment(playerID, team)
		end

		if oldTeam ~= team then
			hero:SetTeam(team)
			print("[EBF FFA] Player " .. playerID .. " successfully moved to team " .. team)
		end
	end

	print("[EBF FFA] FFA team assignment completed!")
end

function CHoldoutGameRound:SetFreeForAllFogState(enabled)
	if not IsServer() then return end

	local gameMode = GameRules:GetGameModeEntity()
	if not gameMode then return end

	gameMode:SetFogOfWarDisabled(true)
end

function CHoldoutGameRound:EnsurePlayersAreRadiant()
	self:SetFreeForAllFogState(false)

	for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
		if hero:IsRealHero() then
			local playerID = hero:GetPlayerID()
			if playerID == nil or playerID == -1 then
				-- skip invalid player IDs (e.g. -1 from world units)
				goto continue_ensure
			end
			if hero:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS then
				hero:SetTeam(DOTA_TEAM_GOODGUYS)
			end
			PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_GOODGUYS)
		end
		::continue_ensure::
	end
end

function SpawnDoomAuraParticle()
    -- Posisi world tempat partikel muncul
    local pos = Vector(0.073895, -0.111816, 397.000122)
    local aura_radius = 800
    local aura_duration = 15
    local lightning_interval = 0.2
    local lightning_damage_radius = 300
    local lightning_damage = 200000
    local strike_count = math.floor(aura_duration / lightning_interval)

    -- Buat partikel doom aura boss
    local particle = ParticleManager:CreateParticle(
        "particles/imba/units/heroes/hero_doom_bringer/doom_bringer_doom_aura_imba_boss.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(particle, 0, pos)
    ParticleManager:SetParticleControl(particle, 1, Vector(aura_radius, 0, 0))

    -- Sound dan efek dramatis
    EmitSoundOnLocationWithCaster(pos, "Imba.DoomRound", thisEntity)
    ScreenShake(pos, 150, 1.0, 1.5, 1200, 0, true)

    -- Find enemy units dan apply root
    local enemies = FindUnitsInRadius(
        DOTA_TEAM_BADGUYS,
        pos,
        nil,
        aura_radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(nil, nil, "modifier_rooted_undispellable", { duration = aura_duration })
    end

    -- Petir menyambar selama durasi aura
    for i = 0, strike_count - 1 do
        Timers:CreateTimer(i * lightning_interval, function()
            local offset = Vector(RandomFloat(-aura_radius, aura_radius), RandomFloat(-aura_radius, aura_radius), 0)
            local strike_pos = pos + offset

            -- Particle lightning bolt
            local bolt = ParticleManager:CreateParticle("particles/events/crownfall/survivors/abilities/zeus/zuus_thundergods_wrath.vpcf", PATTACH_WORLDORIGIN, nil)
            ParticleManager:SetParticleControl(bolt, 0, strike_pos + Vector(0, 0, 1000)) -- from sky
            ParticleManager:SetParticleControl(bolt, 1, strike_pos)
            ParticleManager:SetParticleControl(bolt, 2, strike_pos)

            -- Damage musuh di sekitar titik sambaran
            local targets = FindUnitsInRadius(
                DOTA_TEAM_BADGUYS,
                strike_pos,
                nil,
                lightning_damage_radius,
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_ANY_ORDER,
                false
            )

			local function CreateFakeNeutralAttacker(origin)
				local dummy = CreateUnitByName("npc_dummy_unit", origin, false, nil, nil, DOTA_TEAM_NEUTRALS)
				dummy:AddNewModifier(dummy, nil, "modifier_invulnerable", {})
				dummy:AddNewModifier(dummy, nil, "modifier_hidden", {})
				dummy:SetControllableByPlayer(-1, false)
				dummy:SetDayTimeVisionRange(0)
				dummy:SetNightTimeVisionRange(0)
				return dummy
			end

			attacker = attacker or CreateFakeNeutralAttacker(pos)

            for _, target in pairs(targets) do
                ApplyDamage({
                    victim = target,
                    attacker = attacker,
                    damage = lightning_damage,
                    damage_type = DAMAGE_TYPE_MAGICAL,
                    damage_flags = DOTA_DAMAGE_FLAG_NONE,
                    ability = nil
                })
            end
        end)
    end

    -- Setelah 15 detik, hapus aura dan spawn unit
    Timers:CreateTimer(aura_duration, function()
        ParticleManager:DestroyParticle(particle, false)
        ParticleManager:ReleaseParticleIndex(particle)

        for i = 1, 4 do
            Timers:CreateTimer(i * 3, function()
                local offset = Vector(RandomInt(-150, 600), RandomInt(-150, 900), 0)
                local spawn_pos = pos + offset
                local unit = CreateUnitByName("npc_dota_boss31_vh", spawn_pos, true, nil, nil, DOTA_TEAM_NEUTRALS)

                local hp = 100000000
                if unit then
                    unit:SetBaseMaxHealth(hp)
                    unit:SetMaxHealth(hp)
                    unit:SetHealth(hp)
                end
            end)
        end
    end)
end


-- ==========================================
-- TREE CUT EVENT CONFIGURATION
-- ==========================================
local TREE_CUT_SPAWN_CHANCE = 75
local TREE_CUT_MAX_TREANTS = 20
local TREE_CUT_SPAWN_COOLDOWN = 0.5     -- cooldown per spawn to prevent lag battlefury tebangan sekagus
local TREE_CUT_UNIT_NAME = "npc_dota_boss_forest_guardian" -- Replace with your preferred tree unit name
-- ==========================================

function CHoldoutGameRound:_AnnounceRoundAura()
	local round = self._nRoundNumber
	print("[EBF] _AnnounceRoundAura called for round " .. round)
	if round < 4 then return end

	-- Read the pre-set types from Begin()
	local aura_type = GameRules._currentRoundAuraType or 0

	if aura_type == 0 then return end

	-- Generate random combo for combo auras on first call
	if aura_type >= 7 then
		if aura_type == 14 and not GameRules._cursedComboAuras then
			GameRules._cursedComboAuras = {}
			local available = {8, 9, 10, 11, 12, 13}
			for i = 1, 3 do
				local idx = RandomInt(1, #available)
				table.insert(GameRules._cursedComboAuras, available[idx])
				table.remove(available, idx)
			end
			print("[EBF] Generated random cursed combo auras: " .. table.concat(GameRules._cursedComboAuras, ", "))
		elseif aura_type == 7 and not GameRules._comboAuras then
			GameRules._comboAuras = {}
			local available = {1, 2, 3, 4, 5, 6}
			for i = 1, 3 do
				local idx = RandomInt(1, #available)
				table.insert(GameRules._comboAuras, available[idx])
				table.remove(available, idx)
			end
			print("[EBF] Generated random combo auras: " .. table.concat(GameRules._comboAuras, ", "))
		end
	end

	-- Build message with actual aura names and descriptions
	local aura_names = {
		[1] = { name = "Magic Shield", desc = "+70% Magic Resist" },
		[2] = { name = "Iron Skin", desc = "+80 Armor" },
		[3] = { name = "Spikes", desc = "25% Damage Reflect" },
		[4] = { name = "Suppression", desc = "-50% Healing" },
		[5] = { name = "Dispel", desc = "Dispels Buffs" },
		[6] = { name = "Mana Drain", desc = "Burns 5% Mana" },
		[7] = { name = "Combo", desc = "3 Random Auras" },
		[8] = { name = "Silence", desc = "38% Silence 2s on Hit" },
		[9] = { name = "Stun", desc = "18% Stun 0.5s on Hit" },
		[10] = { name = "Mana Void", desc = "64% Burns 10% Mana + Damage" },
		[11] = { name = "Slow", desc = "60% Slow 40% 3s on Hit" },
		[12] = { name = "Armor Break", desc = "90% -25 Armor 4s on Hit" },
		[13] = { name = "Poison", desc = "50% 5% HP Poison 3s on Hit" },
		[14] = { name = "Cursed Combo", desc = "3 Random Cursed Auras" },
	}
	
	-- Announce normal aura
	local message
	if aura_type == 7 then
		local combo_parts = {}
		for _, at in ipairs(GameRules._comboAuras) do
			table.insert(combo_parts, aura_names[at].name .. " (" .. aura_names[at].desc .. ")")
		end
		message = "⚠️ Round " .. round .. ": COMBO — " .. table.concat(combo_parts, " + ")
	elseif aura_type >= 1 and aura_type <= 6 then
		message = "⚠️ Round " .. round .. ": " .. aura_names[aura_type].name .. " (" .. aura_names[aura_type].desc .. ")"
	end
	if message then
		Say(nil, message, false)
		print("[EBF] Aura announcement sent for round " .. round .. ", normal_aura=" .. aura_type)
	end

	-- Now announce cursed aura separately (if any)
	if round >= 4 then
		local cursed_type = GameRules._currentRoundCursedAuraType or 0
		if cursed_type >= 8 and cursed_type <= 13 then
			-- Single cursed aura
			Say(nil, "☠️ Round " .. round .. ": " .. aura_names[cursed_type].name .. " (" .. aura_names[cursed_type].desc .. ")", false)
			print("[EBF] Cursed aura announcement sent for round " .. round .. ", cursed_type=" .. cursed_type)
		elseif cursed_type == 14 then
			-- Cursed combo
			local combo_parts = {}
			if GameRules._cursedComboAuras then
				for _, at in ipairs(GameRules._cursedComboAuras) do
					table.insert(combo_parts, aura_names[at].name .. " (" .. aura_names[at].desc .. ")")
				end
			end
			local combo_str = #combo_parts > 0 and table.concat(combo_parts, " + ") or "3 Random Cursed Auras"
			Say(nil, "☠️ Round " .. round .. ": CURSED COMBO — " .. combo_str, false)
			print("[EBF] Cursed combo aura announcement sent for round " .. round)
		end
	end
end

function CHoldoutGameRound:Begin()

	self._vEnemiesRemaining = {}
	self._heroLastDamageTime = {}
	self._vEventHandles = {
		ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CHoldoutGameRound, "OnNPCSpawned" ), self ),
		ListenToGameEvent( "entity_killed", Dynamic_Wrap( CHoldoutGameRound, "OnEntityKilled" ), self ),
		ListenToGameEvent( "dota_holdout_revive_complete", Dynamic_Wrap( CHoldoutGameRound, 'OnHoldoutReviveComplete' ), self ),
		-- ListenToGameEvent( "tree_cut", Dynamic_Wrap( CHoldoutGameRound, 'OnTreeCut' ), self ),
		ListenToGameEvent( "dota_player_used_ability", Dynamic_Wrap( CHoldoutGameRound, 'OnAbilityUsed' ), self ),
		ListenToGameEvent( "entity_hurt", Dynamic_Wrap( CHoldoutGameRound, 'OnEntityHurt' ), self ),
	}
	self._DisconnectedPlayer = 0
	self._nAsuraCoreRemaining = 0
	
	-- Variabel limitasi & state spawn tree
	self._spawnedTreants = {}
	self._bTreantSpawnCooldown = false

	--local PlayerNumber = PlayerResource:GetTeamPlayerCount() --tester
    local PlayerNumber = self:TeamCount()	
	
	ListenToGameEvent( "player_reconnected", Dynamic_Wrap( CHoldoutGameRound, 'OnPlayerReconnected' ), self )
	ListenToGameEvent( "player_disconnect", Dynamic_Wrap( CHoldoutGameRound, 'OnPlayerDisconnected' ), self )


	local roundNumber = self._nRoundNumber
	local mapName = GetMapName()
	if CouponCode and CouponCode.AnnounceForRoundOne then
		CouponCode:AnnounceForRoundOne(roundNumber)
	end

	if roundNumber == FREE_FOR_ALL_ROUND and (mapName == "epic_boss_fight_soul" or mapName == "epic_boss_fight_god") then
		print("[EBF] SPAWNING FREE FOR ALL ORB - Players will be split into teams!")
		local orbCount = mapName == "epic_boss_fight_god" and 5 or 1
		self:SpawnFreeForAllOrb(orbCount)
	else
		print("[EBF] Ensuring players are Radiant (Not FFA round or not soul map)")
		self:EnsurePlayersAreRadiant()
	end

	-- play sound disini
	if roundNumber == 27 and (GetMapName() == "epic_boss_fight_nightmare" or GetMapName() == "epic_boss_fight_purgatory" or GetMapName() == "epic_boss_fight_soul") then
		SpawnDoomAuraParticle()
	end

	if roundNumber == 10 and (GetMapName() == "epic_boss_fight_nightmare" or GetMapName() == "epic_boss_fight_soul") then
		EmitGlobalSound("jboberg_01.music.roshan")
	end
	if roundNumber == FREE_FOR_ALL_ROUND and (GetMapName() == "epic_boss_fight_nightmare" or GetMapName() == "epic_boss_fight_soul") then
		StopGlobalSound("jboberg_01.music.roshan")
	end
	if roundNumber == 26 then
		Timers:CreateTimer(2,function()
			Notifications:RemoveTop(0, 2)
			Notifications:RemoveBottomFromTeam(DOTA_TEAM_GOODGUYS, 1)
			-- Notifications:BottomToAll({text="SF is magic immune, SD will not take ANY damage until SF is dead", duration=10, style={color="red"}})
		  end)
	end
	self._nMaxGoldForUnits = self._nMaxGold / 2
	self._nMaxGoldForVictory = self._nMaxGold / 2
	self._nGoldRemainingInRound = self._nMaxGoldForUnits
	--new--
	if GameRules._NewGamePlus == true then
		self._nGoldRemainingInRound = self._nGoldRemainingInRound * 5 + 10000
	end

	CustomGameEventManager:Send_ServerToAllClients("UpdateRound", {roundNumber = self._nRoundNumber,roundTitle = self._szRoundQuestTitle})
	
	for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
		if PlayerResource:GetPatronTier( hero:GetPlayerID() ) >= 3 then
			local rune = RandomInt(1,#DOTA_RUNES)
			local rune_2 = RandomInt(1,#DOTA_RUNES)
			local rune_3 = RandomInt(1,#DOTA_RUNES)
			-- CreateRune( hero:GetAbsOrigin() + RandomVector( 250 ), rune )
			-- CreateRune( hero:GetAbsOrigin() + RandomVector( 250 ), DOTA_RUNE_BOUNTY )
			-- CreateRune( hero:GetAbsOrigin() + RandomVector( 250 ), DOTA_RUNE_BOUNTY )
		end
	end
	
	for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
		if hero:GetUnitName() == "npc_dota_hero_dazzle" then
			local mod = hero:FindModifierByName("modifier_dazzle_nothl_projection_physical_body_debuff")
			if mod then
				mod:Destroy()
			end
		end
	end

    self._nGoldBagsRemaining = self._nBagCount
    self._nGoldBagsExpired = 0
    self._nCoreUnitsTotal = 0

    -- Reduce gold reward for rounds 1-5 by 50%
    if roundNumber <= 5 then
        local gold_mult = 0.5
        self._nMaxGold = math.floor(self._nMaxGold * gold_mult)
    end

	-- Set aura types BEFORE spawners begin, so mobs get the correct modifiers.
	-- Cache on the round object so spawners read a stable value (no reset race).
	if roundNumber >= 4 and roundNumber <= 5 then
		GameRules._currentRoundAuraType = RandomInt(1, 6)
		GameRules._currentRoundCursedAuraType = RandomInt(8, 13)
		self._cursedAuraType = GameRules._currentRoundCursedAuraType
	elseif roundNumber >= 6 then
		GameRules._currentRoundAuraType = RandomInt(1, 6)
		GameRules._currentRoundCursedAuraType = RandomInt(8, 14)
		self._cursedAuraType = GameRules._currentRoundCursedAuraType
	elseif roundNumber == 3 then
		GameRules._currentRoundAuraType = RandomInt(1, 6)
		GameRules._currentRoundCursedAuraType = 0
		self._cursedAuraType = 0
	else
		GameRules._currentRoundAuraType = 0
		GameRules._currentRoundCursedAuraType = 0
		self._cursedAuraType = 0
	end

	-- Generate combo aura lists SYCHRONOUSLY here (not in a delayed timer),
	-- so cursed combo (type 14) has effects ready before any mob spawns/attacks.
	GameRules._cursedComboAuras = nil
	GameRules._comboAuras = nil
	if self._cursedAuraType == 14 then
		GameRules._cursedComboAuras = {}
		local available = {8, 9, 10, 11, 12, 13}
		for i = 1, 3 do
			local idx = RandomInt(1, #available)
			table.insert(GameRules._cursedComboAuras, available[idx])
			table.remove(available, idx)
		end
		print("[EBF] Generated random cursed combo auras: " .. table.concat(GameRules._cursedComboAuras, ", "))
	elseif GameRules._currentRoundAuraType == 7 then
		GameRules._comboAuras = {}
		local available = {1, 2, 3, 4, 5, 6}
		for i = 1, 3 do
			local idx = RandomInt(1, #available)
			table.insert(GameRules._comboAuras, available[idx])
			table.remove(available, idx)
		end
		print("[EBF] Generated random combo auras: " .. table.concat(GameRules._comboAuras, ", "))
	end

	-- Round scaling aura announcement (with delay to ensure client is ready)
	if roundNumber >= 4 then
		Timers:CreateTimer(1.0, function()
			self:_AnnounceRoundAura()
		end)
	end
	if GameRules._NewGamePlus == true then
		self._nFixedXP = (50000 + self._nFixedXP) * (roundNumber^0.1)
	end
	self._nExpRemainingInRound = self._nFixedXP
	for _, spawner in pairs( self._vSpawners ) do
		spawner:Begin()
		self._nCoreUnitsTotal = self._nCoreUnitsTotal + spawner:GetTotalUnitsToSpawn( true )
		if self._nRoundNumber == 36 then
			self._nCoreUnitsTotal = self._nCoreUnitsTotal + 1
		end
		--if self._nRoundNumber == 37 then --tester
		--[[if self._nRoundNumber == 39 then
				self._NewGamePlus = true
				self._nRoundNumber = 1
				self._flPrepTimeEnd = GameRules:GetGameTime() + 70-time
		end]]
	end
	self._nCoreUnitsKilled = 0

	-- Single combined progress bar for all spawners this round
	local pbTotal = 0
	for _, spawner in pairs(self._vSpawners) do
		pbTotal = pbTotal + spawner:GetTotalUnitsToSpawn(false)
	end
	if pbTotal > 0 then
		self._pbRoundTotal = pbTotal
		self._pbRoundKilledLast = nil
		CustomNetTables:SetTableValue("progress_bars", "round_progress", {
			text = "0/" .. pbTotal .. " killed",
			currentStacks = 0,
			maxStacks = pbTotal,
			progressBarType = "stacks",
			style = "SpawnerProgress",
		})
		Timers:CreateTimer(0.5, function()
			if not self.currentlyActive then return nil end
			local killed = 0
			for _, spawner in pairs(self._vSpawners) do
				killed = killed + (spawner._nKilledThisRound or 0)
			end
			if killed ~= self._pbRoundKilledLast then
				self._pbRoundKilledLast = killed
				CustomNetTables:SetTableValue("progress_bars", "round_progress", {
					text = killed .. "/" .. pbTotal .. " killed",
					currentStacks = killed,
					maxStacks = pbTotal,
					progressBarType = "stacks",
					style = "SpawnerProgress",
				})
			end
			return 0.5
		end)
	end

	self._entQuest = SpawnEntityFromTableSynchronous( "quest", {
		name = self._szRoundTitle,
		title =  self._szRoundQuestTitle
	})
	self._entQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_ROUND, self._nRoundNumber )
	self._entQuest:SetTextReplaceString( self._gameMode:GetDifficultyString() )

	self._entKillCountSubquest = SpawnEntityFromTableSynchronous( "subquest_base", {
		show_progress_bar = true,
		progress_bar_hue_shift = -119
	} )
	self._entQuest:AddSubquest( self._entKillCountSubquest )
	self._entKillCountSubquest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, self._nCoreUnitsTotal )
	
	GameRules._currentRound = self
	self.currentlyActive = true
end

function CHoldoutGameRound:OnHoldoutReviveComplete( event )
	local castingHero = EntIndexToHScript( event.caster )
	
	if castingHero then
		castingHero.Ressurect = castingHero.Ressurect + 1
		local totalgold = castingHero:GetGold() + self._nRoundNumber*5
		castingHero:SetGold(0 , false)
		castingHero:SetGold(totalgold, true)
	end
end

function CHoldoutGameRound:End(bWon)
	for _, eID in pairs( self._vEventHandles ) do
		StopListeningToGameEvent( eID )
	end
	self._vEventHandles = {}
	
	self.currentlyActive = false
	local roundNumber = self._nRoundNumber
	if self._ffaCapturePoints then
		for _, cp in ipairs(self._ffaCapturePoints) do
			if IsValidEntity(cp) and cp:IsAlive() then
				cp:ForceKill(false)
			end
		end
		self._ffaCapturePoints = nil
	end
	self:EnsurePlayersAreRadiant()
	Timers:CreateTimer( function()
		for _,unit in pairs( Entities:FindAllByClassname("npc_dota_creature") ) do
			if unit:IsAlive() and unit:GetUnitName() ~= "npc_tombstone_player" then
				unit:ForceKill( true )
			end
		end

		for _,unit in pairs( Entities:FindAllByClassname("npc_dota_hero") ) do
			if unit:IsAlive() then
				unit:ForceKill( true )
			end
		end
	end)
	
	if bWon and self._nGoldRemainingInRound > 0 then
		self._heroesDiedThisRound = self._heroesDiedThisRound or {}
		local goldMuliplierTeam = 0.8
		local deathReduction = goldMuliplierTeam / HeroList:GetActiveHeroCount()
		
		for hero, deaths in pairs( self._heroesDiedThisRound ) do
			if deaths > 0 then
				goldMuliplierTeam = goldMuliplierTeam - deathReduction
			end
		end
		
		local expToProvide = self._nExpRemainingInRound
		for _, hero in ipairs( HeroList:GetRealHeroes() ) do
			local goldMuliplierSolo = TernaryOperator( 0.5, (self._heroesDiedThisRound[hero] or 0 > 0), 0)
			local goldForLiving = self._nMaxGoldForVictory * (goldMuliplierTeam + goldMuliplierSolo)
			local goldToProvide = self._nMaxGoldForVictory + self._nGoldRemainingInRound
			
			local player = hero:GetPlayerOwner()
			if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then 
				if PlayerResource:GetConnectionState( hero:GetPlayerID() ) ~= DOTA_CONNECTION_STATE_ABANDONED then
					local midas
					for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6, 1 do
						local item = hero:GetItemInSlot(i)
						if item and item:GetName() == "item_hand_of_midas_ebf" then
							midas = item
							break
						end
					end
					if midas and (midas._currentGoldStorage or 0) < 99999 then
						midas._currentGoldStorage = (midas._currentGoldStorage or 0) * (1 + midas:GetSpecialValueFor("interest_rate") / 100)
					end
					Timers:CreateTimer( 0.5, function()
						if midas and midas._currentGoldStorage < 99999 then
							local goldToBank = goldToProvide * midas:GetSpecialValueFor("bonus_gold") / 100
							midas._currentGoldStorage = midas._currentGoldStorage + goldToBank
							midas._roundRewardsBanked = (midas._roundRewardsBanked or 0) + goldToBank
							goldToProvide = goldToProvide - goldToBank
							
							local tooltip = hero:FindModifierByNameAndAbility( "modifier_hand_of_midas_passive", midas )
							if tooltip then
								tooltip:ForceRefresh()
							end
						end
						hero:AddGold( goldToProvide )
						hero:AddExperience(expToProvide, DOTA_ModifyXP_HeroKill, false, true)
					end)
					if goldMuliplierTeam + goldMuliplierSolo > 0 then
						Timers:CreateTimer( 1.5, function()
							if midas and midas._currentGoldStorage < 99999 then
								local goldToBank = goldForLiving * midas:GetSpecialValueFor("bonus_gold") / 100
								midas._currentGoldStorage = midas._currentGoldStorage + goldToBank
								midas._roundRewardsBanked = (midas._roundRewardsBanked or 0) + goldToBank
								goldForLiving = goldForLiving - goldToBank
								
								local tooltip = hero:FindModifierByNameAndAbility( "modifier_hand_of_midas_passive", midas )
								if tooltip then
									tooltip:ForceRefresh()
								end
							end
							hero:AddGold( goldForLiving )
						end)
					end
					-- if roundNumber == 6 then
					-- 	hero:AddItemByName("item_tier2_token")
					-- elseif roundNumber == 12 then
					-- 	hero:AddItemByName("item_tier3_token")
					-- elseif roundNumber == 17 then
					-- 	hero:AddItemByName("item_tier4_token")
					-- elseif roundNumber == 25 then
					-- 	hero:AddItemByName("item_tier5_token")
					-- end
					if GameRules._NewGamePlus and player then
						if roundNumber == 2
						or roundNumber == 10 
						or roundNumber == 15 
						or roundNumber == 20 then
							local asuraShard = CreateItem( "item_orb_5", player, player )
							hero:AddItem( asuraShard )
						end
					end
				end
			end
		end
		self._nGoldRemainingInRound = 0
		self._nExpRemainingInRound = 0
	end
	-- for _,unit in pairs( Entities:FindAllByClassname("npc_dota_thinker") ) do
		-- if not ( unit:IsTower() or unit:IsHero() or unit:IsNeutralUnitType() ) then
			-- UTIL_Remove( unit )
		-- end
	-- end
	-- for _,unit in pairs( Entities:FindAllInSphere( Vector(0,0,0), 999999 ) ) do
		-- if unit.GetUnitName then print( unit:GetClassname(), unit:GetUnitName() )
		-- else print( unit:GetClassname() ) end
	-- end
	CustomNetTables:SetTableValue("progress_bars", "round_progress", {})
	for _,spawner in pairs( self._vSpawners ) do
		spawner:End()
	end
	-- clear cached units
	if GameRules._getDeadCoreUnitsForGarbageCollection[roundNumber-2] then
		local delay = 0
		for _, unit in ipairs( GameRules._getDeadCoreUnitsForGarbageCollection[roundNumber-2] ) do
			for _, checkTarget in ipairs( unit:FindAllUnitsInRadius(unit:GetAbsOrigin(), -1) ) do
				if checkTarget.FindAllModifiers then
					for _, modifier in ipairs( checkTarget:FindAllModifiers() ) do
						if modifier:GetCaster() == unit then
							modifier:Destroy()
						end
					end
				end
			end
			Timers:CreateTimer( delay, function() UTIL_Remove( unit ) end)
			delay = delay + 0.1
		end
		GameRules._getDeadCoreUnitsForGarbageCollection[roundNumber-2] = nil
	end
end


function CHoldoutGameRound:Think()
	for _, spawner in pairs( self._vSpawners ) do
		spawner:Think()
	end

	-- Bleed tracker: if hero takes no damage for 10 seconds, apply bleed
	self:_CheckBleedTracker()
end

function CHoldoutGameRound:_CheckBleedTracker()
	if not IsServer() then return end
	local now = GameRules:GetGameTime()
	for _, hero in ipairs( HeroList:GetRealHeroes() ) do
		if hero:IsRealHero() and hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS and hero:IsAlive() then
			local entIndex = hero:entindex()
			local lastDmgTime = self._heroLastDamageTime[entIndex]
			if lastDmgTime and now - lastDmgTime >= 10 then
				-- 10 seconds without damage, apply bleed
				if not hero:HasModifier("modifier_bleed_debuff") then
			hero:AddNewModifier(hero, nil, "modifier_bleed_debuff", { duration = 5.0 })
					print("[EBF] Applied bleed to " .. hero:GetUnitName() .. " (no damage for 10s)")
				end
			end
		end
	end
end

function CHoldoutGameRound:OnEntityHurt(event)
	local hurt = EntIndexToHScript(event.entindex_killed)
	if not hurt then return end
	if hurt:IsRealHero() and hurt:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
		self._heroLastDamageTime[hurt:entindex()] = GameRules:GetGameTime()
	end
end

function CHoldoutGameRound:OnAbilityUsed(event)
	local hero = EntIndexToHScript(event.activator)
	if hero and hero:IsRealHero() and hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
		self._heroLastDamageTime[hero:entindex()] = GameRules:GetGameTime()
	end
end


function CHoldoutGameRound:ChooseRandomSpawnInfo()
	return self._gameMode:ChooseRandomSpawnInfo()
end


function CHoldoutGameRound:IsFinished()
	for _, spawner in pairs( self._vSpawners ) do
		if not spawner:IsFinishedSpawning() then
			return false
		end
	end
	local nEnemiesRemaining = #self._vEnemiesRemaining
	if nEnemiesRemaining == 0 then
		return true
	end

	local now = GameRules:GetGameTime()
	if not self._lastFindAllUnitsFinishCheckTime or
		now - self._lastFindAllUnitsFinishCheckTime >= FIND_ALL_UNITS_FINISH_CHECK_INTERVAL
	then
		self._lastFindAllUnitsFinishCheckTime = now
		self._lastFindAllUnitsFinishCheckResult = true

		for _, unit in ipairs( FindAllUnits() ) do
			local isFfaOrb = false
			if self._ffaCapturePoints then
				for _, ffaOrb in ipairs(self._ffaCapturePoints) do
					if unit == ffaOrb then isFfaOrb = true break end
				end
			end
			if not isFfaOrb and unit:GetTeam() == DOTA_TEAM_NEUTRALS and unit:IsAlive() and unit:IsCreature() then
				self._lastFindAllUnitsFinishCheckResult = false
				break
			end
		end
	end

	if self._lastFindAllUnitsFinishCheckResult == false then
		return false
	end

	if not self._lastEnemiesRemaining == nEnemiesRemaining then
		self._lastEnemiesRemaining = nEnemiesRemaining
		print ( string.format( "%d enemies remaining in the round...", #self._vEnemiesRemaining ) )
	end
	return true
end


-- Rather than use the xp granting from the units keyvalues file,
-- we let the round determine the xp per unit to grant as a flat value.
-- This is done to make tuning of rounds easier.


function CHoldoutGameRound:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit or spawnedUnit:IsPhantom() or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:GetUnitName() == "" or spawnedUnit:IsNeutralUnitType() then
		return
	end
	local nCoreUnitsRemaining = self._nCoreUnitsTotal - self._nCoreUnitsKilled

	if spawnedUnit:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
		table.insert( self._vEnemiesRemaining, spawnedUnit )
		spawnedUnit:SetDeathXP( 0 )
		spawnedUnit.unitName = spawnedUnit:GetUnitName()
	end
end


function CHoldoutGameRound:OnEntityKilled( event )
	local killedUnit = EntIndexToHScript( event.entindex_killed )
	
	if not killedUnit then return end
	if killedUnit:IsRealHero() and not killedUnit:IsReincarnating() then
		self._heroesDiedThisRound = self._heroesDiedThisRound or {}
		self._heroesDiedThisRound[killedUnit] = (self._heroesDiedThisRound[killedUnit] or 0) + 1
	end
	if not killedUnit:IsCreature() then
		return
	end
	
	for i, unit in pairs( self._vEnemiesRemaining ) do
		if killedUnit == unit then
			table.remove( self._vEnemiesRemaining, i )
			break
		end
	end

	if killedUnit.Holdout_IsCore then
		self._nCoreUnitsKilled = self._nCoreUnitsKilled + 1
		-- self:_CheckForGoldBagDrop( killedUnit )
		local nCoreUnitsRemaining = self._nCoreUnitsTotal - self._nCoreUnitsKilled
		if nCoreUnitsRemaining == 0 then
			self:spawn_treasure()
		end
	end
	
	Timers:CreateTimer( 1.5, function()
		for _, modifier in ipairs( killedUnit:FindAllModifiers() ) do
			modifier:Destroy()
		end
		killedUnit:AddNoDraw()
	end)
	
	
	for _,unit in pairs( FindUnitsInRadius( DOTA_TEAM_NEUTRALS, Vector( 0, 0, 0 ), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false )) do
		if unit:IsCreature() and unit:IsAlive() then
			return
		end
	end
	-- find earliest spawn
	local nextSpawn
	for _, spawner in pairs( self._vSpawners ) do
		if spawner._flNextSpawnTime and (not nextSpawn or spawner._flNextSpawnTime <= nextSpawn._flNextSpawnTime) then
			nextSpawn = spawner
		end
	end
	if nextSpawn then
		nextSpawn._flNextSpawnTime = GameRules:GetGameTime()
	end
end



function CHoldoutGameRound:_CheckForGoldBagDrop( killedUnit )
	if self._nGoldRemainingInRound <= 0 then return end
	if not killedUnit:IsConsideredHero() then return end
	local nCoreUnitsRemaining = self._nCoreUnitsTotal - self._nCoreUnitsKilled
	local tBagDrops = {}
	--local PlayerNumber = PlayerResource:GetTeamPlayerCount() --tester
	local PlayerNumber = self:TeamCount()
	
	-- EXPERIENCE
	local exptogain = 0
	if nCoreUnitsRemaining > 0 then
		exptogain = math.min( self._nExpRemainingInRound, math.ceil( self._nFixedXP / self._nCoreUnitsTotal ) )
	elseif nCoreUnitsRemaining <= 0 then
		exptogain =  math.ceil(self._nExpRemainingInRound)
	end
	-- GOLD
	local goldToGain = 0
	if nCoreUnitsRemaining <= 0 then
		goldToGain = self._nGoldRemainingInRound
	else
		goldToGain = math.min( self._nGoldRemainingInRound, self._nMaxGoldForUnits / self._nCoreUnitsTotal )
	end
	for _,unit in ipairs ( HeroList:GetRealHeroes() ) do
		if unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			unit:AddExperience(exptogain, DOTA_ModifyXP_HeroKill, false, true)
			if PlayerResource:GetConnectionState( unit:GetPlayerID() ) ~= DOTA_CONNECTION_STATE_ABANDONED then unit:AddGold( goldToGain ) end
		end
	end

	self._nExpRemainingInRound = math.max( 0,self._nExpRemainingInRound - exptogain)
	self._nGoldRemainingInRound = math.max( 0,self._nGoldRemainingInRound - goldToGain)
end


function CHoldoutGameRound:StatusReport( )
	print( string.format( "Enemies remaining: %d", #self._vEnemiesRemaining ) )
	for _,e in pairs( self._vEnemiesRemaining ) do
		if e:IsNull() then
			print( string.format( "<Unit %s Deleted from C++>", e.unitName ) )
		else
			print( e:GetUnitName() )
		end
	end
	print( string.format( "Spawners: %d", #self._vSpawners ) )
	for _,s in pairs( self._vSpawners ) do
		s:StatusReport()
	end
end

--tester
function CHoldoutGameRound:TeamCount()
    local counter = 0
    for i = 0, PlayerResource:GetPlayerCount() -1 do
        if PlayerResource:IsValidPlayerID(i) and PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
	        counter = counter + 1
		end
	end
	return counter
end

function CHoldoutGameRound:OnPlayerReconnected(event)
	local playerID = event.PlayerID
	if not playerID then return end

	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if not hero then return end

	-- Jika round saat ini bukan round 13 (FFA), kembalikan player ke team Radiant
	if self._nRoundNumber ~= FREE_FOR_ALL_ROUND then
		if hero:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS then
			hero:SetTeam(DOTA_TEAM_GOODGUYS)
		end
		PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_GOODGUYS)
	else
		-- Jika round 13 masih aktif dan player reconnect, assign ke team FFA
		-- Cari slot team yang tersedia atau assign berdasarkan playerID
		local teamIndex = ((playerID) % #FFA_TEAM_SEQUENCE) + 1
		local team = FFA_TEAM_SEQUENCE[teamIndex]

		if team then
			if hero:GetTeamNumber() ~= team then
				hero:SetTeam(team)
			end
			PlayerResource:SetCustomTeamAssignment(playerID, team)
		end
	end
end

function CHoldoutGameRound:OnPlayerDisconnected(event)
	local playerID = event.PlayerID
	if not playerID then return end

	-- Track disconnected player jika diperlukan
	self._DisconnectedPlayer = self._DisconnectedPlayer + 1
end

-- ================================================
-- TREE CUT EVENT HANDLER
-- ================================================
function CHoldoutGameRound:OnTreeCut( event )
	-- 1. Chance spawn (dalam skala 100%)
	if RandomInt( 1, 100 ) > TREE_CUT_SPAWN_CHANCE then return end

	-- 2. Anti server-crash (Cooldown anti Battlefury / Timber Cut ganda)
	if self._bTreantSpawnCooldown then return end

	-- Opsional: Bersihkan data minion yang telah mati dari tabel
	if self._spawnedTreants then
		for i = #self._spawnedTreants, 1, -1 do
			local minion = self._spawnedTreants[i]
			if not minion or minion:IsNull() or not minion:IsAlive() then
				table.remove( self._spawnedTreants, i )
			end
		end
	else
		self._spawnedTreants = {}
	end

	-- 3. Batasi limit maksimal spawn yang gentayangan
	if #self._spawnedTreants >= TREE_CUT_MAX_TREANTS then return end

	local vLocation = Vector( event.tree_x, event.tree_y, 0 )
	local hTreant = CreateUnitByName( TREE_CUT_UNIT_NAME, vLocation, true, nil, nil, DOTA_TEAM_NEUTRALS )

	if hTreant then
		table.insert( self._spawnedTreants, hTreant )
		
		-- Masukkan array agar di reset otomatis bila ronde habis / ke wipe
		table.insert( self._vEnemiesRemaining, hTreant ) 

		hTreant.unitName = hTreant:GetUnitName()
		-- Mencegah abuse kill exp / gold farm
		hTreant:SetDeathXP( 0 )
		hTreant:SetMinimumGoldBounty( 0 )
		hTreant:SetMaximumGoldBounty( 0 )

		-- SCALING SETTINGS (HP/DMG dikalikan seiring dengan bertambahnya Ronde boss)
		local scale_multiplier = self._nRoundNumber
		if scale_multiplier == nil or scale_multiplier < 1 then scale_multiplier = 1 end
		
		local hp = 10000 * scale_multiplier
		hTreant:SetBaseMaxHealth( hp )
		hTreant:SetMaxHealth( hp )
		hTreant:SetHealth( hp )
		
		hTreant:SetBaseDamageMin( 50 * scale_multiplier )
		hTreant:SetBaseDamageMax( 100 * scale_multiplier )

		-- Cari musuh / player hero untuk memfokuskan serangan
		local enemies = FindUnitsInRadius(
			DOTA_TEAM_NEUTRALS,
			vLocation,
			nil,
			FIND_UNITS_EVERYWHERE,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_CLOSEST,
			false
		)
		
		if #enemies > 0 then
			hTreant:SetInitialGoalEntity( enemies[1] )
			-- Memaksa minion agar mengejar musuh terdekat
			ExecuteOrderFromTable({
				UnitIndex = hTreant:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
				Position = enemies[1]:GetAbsOrigin()
			})
		end

		-- Tambahkan modifier haste selama 3 detik seperti permintaan
		hTreant:AddNewModifier( hTreant, nil, "modifier_rune_haste", { duration = 3.0 } )

		-- Set cooldown singkat biar 1 kapak Beastmaster/skill tidak spam >15 treant instan
		self._bTreantSpawnCooldown = true
		Timers:CreateTimer( TREE_CUT_SPAWN_COOLDOWN, function()
			self._bTreantSpawnCooldown = false
		end)
	end
end