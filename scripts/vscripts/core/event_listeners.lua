EventListeners = class({})

function CHoldoutGameMode:StartSoulVotingIfNeeded()
    local mapName = GetMapName()
    local isSoulMap = mapName == "epic_boss_fight_soul"
    local isAbilityDraftMap = IsAbilityDraftMap and IsAbilityDraftMap()
    local shouldSetupSoulLevel = isSoulMap or isAbilityDraftMap

    if not shouldSetupSoulLevel or GameRules:State_Get() ~= DOTA_GAMERULES_STATE_PRE_GAME or GameRules._soulVotingStarted then
        return
    end

    print("[OnConnectFull] Soul setup pre-game: mulai P2W vote dulu")
    GameRules._soulVotingStarted = true

    local playerSouls = {}
    for playerId = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if PlayerResource:IsValidPlayerID(playerId)
            and PlayerResource:GetConnectionState(playerId) == DOTA_CONNECTION_STATE_CONNECTED
        then
            local soulData = CustomNetTables:GetTableValue("soul", tostring(playerId))
            if soulData and soulData.soul ~= nil then
                table.insert(playerSouls, {
                    playerId   = playerId,
                    soulNumber = soulData.soul
                })
            end
        end
    end

    local function CalculateAverageTeamSoul()
        local totalSoul = 0
        local playerCount = 0

        for _, soul in ipairs(playerSouls) do
            local soulNumber = tonumber(soul.soulNumber)
            if soulNumber then
                totalSoul = totalSoul + soulNumber
                playerCount = playerCount + 1
            end
        end

        if playerCount == 0 then
            return 0
        end

        return math.floor(totalSoul / playerCount)
    end

    local uniqueSouls, seen = {}, {}
    for _, soul in ipairs(playerSouls) do
        if not seen[soul.soulNumber] then
            seen[soul.soulNumber] = true
            table.insert(uniqueSouls, soul)
        end
    end

    local function ApplySelectedSoul(soulNumber)
        print("Menerapkan soul", soulNumber, "ke semua player")
        CustomGameEventManager:Send_ServerToAllClients("soul_selected", {soulSelected = soulNumber})
        GameRules.SoulLevel = soulNumber
        CustomNetTables:SetTableValue("game_stats","soul_selected", {soulSelected = soulNumber})
    end

    local P2WVote = require("p2w_vote_server")
    P2WVote.CheckAndStart(15, function(fairPlayEnabled)
        print("[OnConnectFull] P2W vote selesai. FairPlay=" .. tostring(fairPlayEnabled))

        Timers:CreateTimer(2.0, function()
            if isAbilityDraftMap then
                local averageSoul = CalculateAverageTeamSoul()
                print("[OnConnectFull] AD average soul selected:", averageSoul)
                ApplySelectedSoul(averageSoul)
            elseif #uniqueSouls > 0 then
                print("[OnConnectFull] Soul map: mulai soul voting")
                local SoulVoting = require("soul_voting_server")
                SoulVoting.SetOnComplete(function(selectedSoul, votes)
                    print("Voting selesai! Soul terpilih:", selectedSoul)
                    ApplySelectedSoul(selectedSoul)
                end)
                SoulVoting.StartVoting(uniqueSouls, 5)
            end
        end)
    end)
end

function CHoldoutGameMode:OnNPCSpawned( event )
    local spawnedUnit = EntIndexToHScript( event.entindex )

    -- Pastikan player valid sebelum mengirim event
    local playerID = spawnedUnit:GetPlayerOwnerID()
    
    if not spawnedUnit or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:IsPhantom() then
        return
    end
    if spawnedUnit:IsCreature() then
        bossManager:onBossSpawn(spawnedUnit)
    end
    if spawnedUnit:IsCourier() then
        spawnedUnit:AddNewModifier( spawnedUnit, nil, "modifier_invulnerable", {} )
    end
    if spawnedUnit:IsNeutralUnitType() then -- make AI ignore neutrals.
        spawnedUnit:RemoveAbility("neutral_upgrade")
    end
    if spawnedUnit:IsIllusion() then
        local heroName = spawnedUnit:GetUnitName()
    end

    if spawnedUnit:IsRealHero() then
        if not spawnedUnit.sHeroName then
            spawnedUnit.sHeroName = spawnedUnit:GetUnitName()
        end
        spawnedUnit.Slots = spawnedUnit.Slots or {}

        if not spawnedUnit:IsClone() and not spawnedUnit:IsTempestDouble() then
            -- if spawnedUnit:GetUnitName() == "npc_dota_hero_omniknight" then
            --     Wearable:Wear(spawnedUnit, "31450", "0")
            --     Wearable:Wear(spawnedUnit, "34270", "0")
            --     Wearable:Wear(spawnedUnit, "31449", "0")
            --     Wearable:Wear(spawnedUnit, "31448", "0")
            --     Wearable:Wear(spawnedUnit, "31446", "0")
            -- end
            
        end

        ShowPurgatoryPopupToAllPlayers()
        if GameRules._roundnumber <= 1 and GetMapName() == "epic_boss_fight_nightmare" and GetMapName() == "epic_boss_fight_purgatory" then
            -- CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(spawnedUnit:GetPlayerID()), "show_warning_message", nil)
            
        end

        self:StartSoulVotingIfNeeded()

        if spawnedUnit:GetUnitName() == "npc_dota_hero_undying" and spawnedUnit:HasModifier("modifier_fountain_invulnerability") then
            spawnedUnit:RemoveModifierByName("modifier_fountain_invulnerability")
        end

        -- if spawnedUnit:IsRealHero() and spawnedUnit:GetUnitName() == "npc_dota_hero_faceless_void" then
        --     AttachTendrilsCosmetic(spawnedUnit)
        -- end

        local playerID = spawnedUnit:GetPlayerID()

        -- Register bot/fake client ke user_ids saat hero spawn
        if PlayerResource:IsFakeClient(playerID) and not self.user_ids[playerID] then
            self.user_ids[playerID] = playerID
            print(string.format("[ADMIN] Registered bot player slot %d in user_ids on spawn", playerID))
        end

        local banData = CustomNetTables:GetTableValue("ban", tostring(playerID))

        local steamid = tostring(PlayerResource:GetSteamID(playerID))
        local playerName = PlayerResource:GetPlayerName(playerID)

        -- if isSteamIDInTop5Leaderboard(top5Leaderboard, steamid) then
        --     spawnedUnit:SetCustomHealthLabel(string.format("Rank %d", top5Leaderboard[steamid].index), 255, 215, 0)
        -- end
        
        print(string.format("Ban count: %d, Ban: %s", banData.bancount, tostring(banData.ban)))
        -- Cek apakah data ban ada dan pemain diban

        
        if banData.ban ~= nil and banData.bancount > 6 then
            -- Tambahkan modifier untuk menghentikan pemain
            print("Ban data: ", banData.ban)
            spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_ban_movement", {})
            spawnedUnit:SetCustomHealthLabel("#autobanned", 255, 0, 0)

            local user_id = self.user_ids[playerID]
            if not user_id then return end
            self.kicks_id[user_id] = true
            SendToServerConsole('kickid '.. user_id)
            print(string.format("[KICK] Player %s with SteamID %s has been kicked.", playerID, steamid))
            CustomNetTables:SetTableValue("kicked_data", steamid, { kicked = true })
        end

        if GameRules._roundnumber == 34 and spawnedUnit:HasModifier("modifier_item_map_reveal") then
            if spawnedUnit and spawnedUnit.viewerID then
                print("[ADDON GAME MODE SPAWNED] ViewerID: " .. spawnedUnit.viewerID)
                spawnedUnit:RemoveModifierByName("modifier_item_map_reveal")
                RemoveFOWViewer(spawnedUnit:GetTeamNumber(), spawnedUnit.viewerID)
                spawnedUnit.viewerID = nil -- Hapus viewerID setelah digunakan
            end
        end

        -- spawnedUnit.MinorAbilityUpgrades = {}
        if not spawnedUnit:HasModifier("modifier_minor_ability_upgrades") then
            spawnedUnit:AddNewModifier( spawnedUnit, nil, "modifier_minor_ability_upgrades", {} )
        end

        -- Add and level up the base stats upgrade ability
        local hAbility = spawnedUnit:FindAbilityByName( "aghsfort_minor_stats_upgrade" )
        if hAbility == nil then
            hAbility = spawnedUnit:AddAbility("aghsfort_minor_stats_upgrade")
            hAbility:UpgradeAbility( true )
         end

        -- if not spawnedUnit:HasModifier("modifier_player_order") then
        --  spawnedUnit:AddNewModifier( spawnedUnit, nil, "modifier_player_order", {} )
        -- end

        if spawnedUnit:GetName() == "npc_dota_hero_nevermore" and not spawnedUnit.auto_necromastery then
            spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_auto_necromastery", {})
            spawnedUnit.auto_necromastery = true
        end

        local isDonatorExpired = CustomNetTables:GetTableValue("donator_expired",tostring(playerID)).donator_expired
        local donatorTier = CustomNetTables:GetTableValue("donator_tier",tostring(playerID)).donator_tier
        

        -- if isDonatorExpired == 0 then
        --     if donatorTier == "empyrean" then
        --          local iobackpack = CreateUnitByName(
        --         "npc_dummy_io_backpack",
        --         spawnedUnit:GetAbsOrigin(), true,
        --         spawnedUnit, spawnedUnit, spawnedUnit:GetTeam()
        --     )
        --         print("TAMBAH IO SUPPORT")
        --         iobackpack:SetForwardVector(spawnedUnit:GetForwardVector())
        --         iobackpack:StartGesture(ACT_DOTA_SPAWN)
        --         local iobackpack_modifier = iobackpack:AddNewModifier(spawnedUnit, nil, "modifier_bpass_inferno", {duration = -1})
        --     end
        -- end
            

        if not spawnedUnit:HasModifier("modifier_thinker_hero_regeneration") then
            spawnedUnit:AddNewModifier( spawnedUnit, nil, "modifier_thinker_hero_regeneration", {} )
        end
        if spawnedUnit:IsTempestDouble() then
            spawnedUnit:AddNewModifier( spawnedUnit, nil, "modifier_special_bonus_attributes_stat_rescaling", {} )
        end
        if GetMapName() == "epic_boss_fight_purgatory" then
            spawnedUnit:AddNewModifier(spawnedUnit, nil, "purgatory_hp_buff", {})
        end

        local attr = spawnedUnit:GetPrimaryAttribute()
        if attr == DOTA_ATTRIBUTE_STRENGTH then
            -- if GameRules._roundnumber >= 1 and spawnedUnit:GetClassname() ~= "npc_dota_hero_alchemist" and spawnedUnit:GetClassname() ~= "npc_dota_hero_life_stealer" and GetMapName() == "epic_boss_fight_purgatory" then
            --     print("hero tambahkan str buff")
            --     spawnedUnit:AddNewModifier(spawnedUnit, nil, 'str_buff', {})
            -- end
        elseif attr == DOTA_ATTRIBUTE_AGILITY then
            if spawnedUnit:GetClassname() ~= "npc_dota_hero_phantom_assassin" and not spawnedUnit:HasModifier("agi_buff") then
                spawnedUnit:AddNewModifier(spawnedUnit, nil, 'agi_buff', {})
            end
        end
        local mapName = GetMapName()
        if (mapName == "epic_boss_fight_soul" or mapName == "epic_boss_fight_purgatory")
        and attr ~= DOTA_ATTRIBUTE_STRENGTH
        and spawnedUnit:GetClassname() ~= "npc_dota_hero_medusa"
        and not spawnedUnit:HasModifier("modifier_non_str_damage_reduction") then
            spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_non_str_damage_reduction", {})
        end
        -- if attr == DOTA_ATTRIBUTE_INTELLECT then
        --  if GameRules._roundnumber >= 1 then
        --      print("hero tambahkan intel buff")
        --      spawnedUnit:AddNewModifier(spawnedUnit, nil, 'intel_buff', {})
        --  end
        -- elseif attr == DOTA_ATTRIBUTE_STRENGTH then
        --  if GameRules._roundnumber >= 1 and spawnedUnit:GetClassname() ~= "npc_dota_hero_alchemist" then
        --      print("hero tambahkan str buff")
        --      spawnedUnit:AddNewModifier(spawnedUnit, nil, 'str_buff', {})
        --  end
        -- end
        if GameRules.lastManStanding then 
            GameRules.lastManStanding:RemoveModifierByName("modifier_last_man_standing")
            GameRules.lastManStanding:StopSound("Imba.WeAreElectric")
         end
        if not spawnedUnit.buyBackInitialized and PlayerResource:GetGoldSpentOnBuybacks( spawnedUnit:GetPlayerID() ) > 0 then -- only way to detect a buyback...
            spawnedUnit.buyBackInitialized = true
            if GetMapName() == "epic_boss_fight_nightmare" then
                PlayerResource:SetCustomBuybackCooldown( spawnedUnit:GetPlayerID(), 300 )
            else
                PlayerResource:SetCustomBuybackCooldown( spawnedUnit:GetPlayerID(), 180 )
            end
        end
    end
    
end

function CHoldoutGameMode:OnPlayerReconnected( event )
    local nReconnectedPlayerID = event.PlayerID
    
    local player = PlayerResource:GetPlayer( nReconnectedPlayerID )
    if not PlayerResource:HasSelectedHero(nReconnectedPlayerID) then
        player:MakeRandomHeroSelection()
    end
    
    --[[if self._NewGamePlus then
        local player = PlayerResource:GetPlayer(nReconnectedPlayerID)
        CustomGameEventManager:Send_ServerToPlayer(player,"Display_Asura_Core", {core = player.Asura_Core})
        CustomGameEventManager:Send_ServerToPlayer(player,"Display_Shop", {core = player.Asura_Core})
    end]]--
end


function CHoldoutGameMode:OnEntityKilled( event )
    local check_tombstone = true
    local killedUnit = EntIndexToHScript( event.entindex_killed )
    local attacker = EntIndexToHScript( event.entindex_attacker )

    -- Kill Effect cosmetic
    if attacker and not attacker:IsNull() and attacker.GetPlayerID then
        local attackerPlayerID = attacker:GetPlayerID()
        if attackerPlayerID >= 0 and killedUnit and not killedUnit:IsNull() then
            CosmeticShop:OnKill(attackerPlayerID, killedUnit)
        end
    end

    if killedUnit:IsCreature() and not killedUnit:HasModifier("modifier_dark_seer_wall_of_replica_illusion") then
        RollDrops(killedUnit)
    end

    if killedUnit:GetUnitName() == "npc_dota_boss36" and GameRules._roundnumber == 36 and (GetMapName() == "epic_boss_fight_soul" or GetMapName() == "epic_boss_fight_ad") then
        Timers:CreateTimer(1.5, function()
            local entities = Entities:FindAllByClassname("prop_dynamic")
            for _, entity in pairs(entities) do
                local entityName = entity:GetName()
                if string.find(entityName, "imba_mid_tormen") then
                    local ent = Entities:FindByName(nil, entityName)
                    DoEntFire(entityName, "SetAnimationNotLooping", "divine_sentinel_spawn_close", 0, ent, ent)
                    break
                end
            end
        end)
    end

    if killedUnit:GetUnitName() == "npc_dota_treasure" then
        local count = -1
        Timers:CreateTimer(0.5,function()
            --if count <= PlayerResource:GetTeamPlayerCount() then --tester
            if count <= self:TeamCount() then
                count = count + 1
                local Item_spawn = CreateItem( "item_present_treasure", nil, nil )
                local drop = CreateItemOnPositionForLaunch( killedUnit:GetAbsOrigin(), Item_spawn )
                Item_spawn:LaunchLoot( false, 300, 0.75, killedUnit:GetAbsOrigin() + RandomVector( RandomFloat( 50, 350 ) ) )
                return 0.25
            end
        end)
    end
    if killedUnit.Asura_To_Give ~= nil then
        for _,unit in pairs ( Entities:FindAllByName( "npc_dota_hero*")) do
            unit.Asura_Core = unit.Asura_Core + killedUnit.Asura_To_Give
        end
    end
    if killedUnit:IsNeutralUnitType() and attacker.GetPlayerID then
        local killingPlayer = attacker:GetPlayerID()
        for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
            if hero:GetPlayerID() ~= killingPlayer then
                hero:AddGold( killedUnit:GetGoldBounty() )
            end
        end
    end
    if killedUnit and killedUnit:IsRealHero() then
        local gameEvent = {}
        gameEvent["player_id"] = killedUnit:GetPlayerID()
        gameEvent["locstring_value"] = attacker:GetUnitName()
        gameEvent["teamnumber"] = -1
        gameEvent["message"] = "#EBFIMBA_KilledByCreature"
        FireGameEvent( "dota_combat_event_message", gameEvent )
        
        if GetMapName() == "epic_boss_fight_purgatory" then
            local has_aegis = killedUnit:HasItemInInventory("item_aegis")
            local has_reincarnation = killedUnit:IsReincarnating()
            local playerID = killedUnit:GetPlayerID()
        
            if not has_aegis and not has_reincarnation then
                local connState = PlayerResource:GetConnectionState(playerID)
                if PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
                    self:_OnLose()
                end
            end
        end
        

        local livingHeroes = {}
        if HeroList:GetActiveHeroCount() > 1 then
            for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
                if hero:IsAlive() then
                    table.insert( livingHeroes, hero )
                end
            end
            if #livingHeroes == 1 then
                GameRules.lastManStanding = livingHeroes[1]
                GameRules.lastManStanding:AddNewModifier( GameRules.lastManStanding, nil, "modifier_last_man_standing", {} )
            end
        end
        if GetMapName() == "epic_boss_fight_normal" and GetMapName() ~= "epic_boss_fight_challenger" and GetMapName() ~= "epic_boss_fight_nightmare" and GetMapName() ~= "epic_boss_fight_purgatory" and GetMapName() ~= "epic_boss_fight_soul" then
            if check_tombstone == true and killedUnit.NoTombStone ~= true then
                local tombstoneUnit = CreateUnitByName("npc_tombstone_player", killedUnit:GetAbsOrigin(), true, nil, nil, killedUnit:GetTeamNumber())
                tombstoneUnit:SetMaximumGoldBounty(0)
                tombstoneUnit:SetMinimumGoldBounty(0)
                tombstoneUnit:SetDeathXP(0)
                tombstoneUnit:SetAngles(0, RandomFloat(0, 360), 0)
                tombstoneUnit:AddNewModifier(tombstoneUnit, nil, "modifier_invulnerable", {})
                tombstoneUnit:AddNewModifier(killedUnit, nil, "modifier_tombstone2", {})
            end
        end
    end
end

-- When game state changes set state in script
function CHoldoutGameMode:OnGameRulesStateChange()
    local nNewState = GameRules:State_Get()
    -- local eventConfig = CustomNetTables:GetTableValue('choosen_difficulty', 'saved')
    -- local diff = eventConfig.class

    if nNewState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        if not self._wearablesInitialized then
            Wearable:Init()
            self._wearablesInitialized = true
        end

    elseif nNewState == DOTA_GAMERULES_STATE_HERO_SELECTION then
        if IsAbilityDraftMap and IsAbilityDraftMap() then
            print("[AbilityDraft] Starting AD hero selection for map: " .. tostring(GetMapName()))
            self.activatedGameMode = CUSTOM_GAME_MODE_ABILITY_DRAFT
            CustomNetTables:SetTableValue("global_info", "game_mode", { id = self.activatedGameMode, name = CUSTOM_GAME_MODE_ABILITY_DRAFT_NAME })

            if not self.abilityDraftMode then
                self.abilityDraftMode = CAbilityDraftMode()
                self.abilityDraftMode:Init(self)
                self.abilityDraftMode:StartAbilityDraft()
            end

            return
        end

        local eventConfig = CustomNetTables:GetTableValue('choosen_difficulty', 'saved')
        local diff = eventConfig.class
        GameRules.HeroKV = LoadKeyValues("scripts/npc/npc_heroes.txt")
        MergeTables( GameRules.HeroKV, LoadKeyValues("scripts/npc/npc_heroes_custom.txt") )
        local activeList = LoadKeyValues("scripts/npc/herolist.txt")
        if GetMapName() == "epic_boss_fight_purgatory" and diff == "S5" then
            activeList = LoadKeyValues("scripts/npc/herolist_s5_purgatory.txt")
        end
        local durableHeroes = {}
        local dpsHeroes = {}
        local supportHeroes = {}
        for heroName, available in pairs( activeList ) do
            if tonumber(available) > 0 then
                local heroData = GameRules.HeroKV[heroName]
        -- local heroKV = LoadKeyValues("scripts/npc/npc_heroes.txt")
        -- local activeList = LoadKeyValues("scripts/npc/herolist.txt")
        -- local durableHeroes = {}
        -- local dpsHeroes = {}
        -- local supportHeroes = {}
        -- for heroName, available in pairs( activeList ) do
        --  if tonumber(available) > 0 then
        --      local heroData = heroKV[heroName]
                local roles = splitString( heroData.Role, "," )
                local roleLevel = splitString( heroData.Rolelevels, "," )
                local roleData = {}
                for i = 1, #roles do
                    roleData[roles[i]] = roleLevel[i]
                end
                local highestRoleLevel = 0
                local highestRole
                for role, roleLevel in pairs(roleData) do
                    if tonumber(roleLevel) > highestRoleLevel then
                        highestRoleLevel = tonumber(roleLevel)
                        highestRole = role
                    end
                end
                if highestRole == "Nuker" or highestRole == "Carry" or highestRole == "Pusher" then
                    table.insert( dpsHeroes, heroName )
                elseif Durable == "Escape" or highestRole == "Durable" then
                    table.insert( durableHeroes, heroName )
                else
                    table.insert( supportHeroes, heroName )
                end
            end
        end
        local container = {durableHeroes, supportHeroes, dpsHeroes}
        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
            if PlayerResource:IsValidPlayerID( nPlayerID ) then
                    for hero, available in pairs( activeList ) do
                        if tonumber(available) > 0 then
                            GameRules:AddHeroToPlayerAvailability( nPlayerID, DOTAGameManager:GetHeroIDByName( hero ) )
                        end
                    end
            end
        end
        
    elseif nNewState == DOTA_GAMERULES_STATE_STRATEGY_TIME then
        GameRules:SetTimeOfDay(0.26)
        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
            
            local player = PlayerResource:GetPlayer(nPlayerID)
            if player and not PlayerResource:HasSelectedHero(nPlayerID) then
                player:MakeRandomHeroSelection()
            end
        end
    elseif nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
        if IsAbilityDraftMap and IsAbilityDraftMap() and self.abilityDraftMode then
            self.abilityDraftMode:VerifyAssetsPrecaching()
        end
        self:StartSoulVotingIfNeeded()

        local AUTH_KEY = GetAuthKey()


        if not self._preGameSetupDone then
            GameRules:SetTimeOfDay(0.26)
            if GameRules:IsCheatMode() then
                Say( nil, "type -startgame to start the game", false)
            end
            if GetMapName() ~= "epic_boss_fight_challenger" then
                ShowGenericPopup( "#holdout_instructions_title", "#holdout_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
            else
                ShowGenericPopup( "#holdout_instructions_title_challenger", "#holdout_instructions_body_challenger", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
            end
            GameRules.neutralCamps = {easy = {}, medium = {}, hard = {}, ancient = {}}
            
            for _, entity in ipairs( Entities:FindAllByClassname( "trigger_multiple" ) ) do
                if string.find( entity:GetName(), "easy_camp" )  then
                    table.insert( GameRules.neutralCamps.easy, entity )
                elseif string.find( entity:GetName(), "medium_camp" )  then
                    table.insert( GameRules.neutralCamps.medium, entity )
                elseif string.find( entity:GetName(), "hard_camp" )  then
                    table.insert( GameRules.neutralCamps.hard, entity )
                elseif string.find( entity:GetName(), "ancient_camp" ) then
                    table.insert( GameRules.neutralCamps.ancient, entity )
                end
            end
            self._preGameSetupDone = true
        end
    elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        GameRules:SpawnNeutralCreeps()
        
        -- ParticleManager:CreateParticle("particles/rain_fx/econ_snow.vpcf", PATTACH_EYES_FOLLOW, GameRules:GetGameModeEntity())
        -- GameRules:GetGameModeEntity():EmitSound("hero_demo_frostivus")
        
        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
            local player = PlayerResource:GetPlayer(nPlayerID)
            if player ~= nil then
                self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds               
                -- local nParticleID = ParticleManager:CreateParticle("particles/rain_fx/econ_snow.vpcf", PATTACH_EYES_FOLLOW, player)
                -- ParticleManager:ReleaseParticleIndex(nParticleID)
            end
        end
        GameRules:SetTimeOfDay(0.76)
    end
end

function CHoldoutGameMode:OnHeroPick (event)
    local hero = EntIndexToHScript(event.heroindex)
    if hero == nil then return end

    local playerID = hero:GetPlayerOwnerID()
    if IsAbilityDraftMap and IsAbilityDraftMap() and self.abilityDraftMode and not hero._abilityDraftApplied then
        self.abilityDraftMode:SetSelectedAbilities(hero, playerID)
        hero._abilityDraftApplied = true
    end

    if IsInToolsMode() or GameRules:IsCheatMode() then
       hero:AddItemByName("item_ultimate_scepter")
    end

    local donatorExpiredData = CustomNetTables:GetTableValue("donator_expired",tostring(playerID)) or {}
    local donatorTierData = CustomNetTables:GetTableValue("donator_tier",tostring(playerID)) or {}
    local isDonatorExpired = donatorExpiredData.donator_expired or 1
    local donatorTier = donatorTierData.donator_tier
    print("OnheroPick isDonatorExpired:",isDonatorExpired)

    GameRules.selected_facet_id[playerID] = hero:GetHeroFacetID()
	CustomNetTables:SetTableValue("game_stats", "selected_facet_id", GameRules.selected_facet_id)
    print("Hero Facet ID:",hero:GetHeroFacetID())

    -- Apply tier utama
    if isDonatorExpired == 0 and GetMapName() ~= "epic_boss_fight_purgatory" and not GameRules.FairPlayMode then
        local bpass_modifier = bpass.reward[donatorTier]
        if bpass_modifier then
            print("[bpass] Apply tier utama: " .. tostring(donatorTier) .. " -> " .. bpass_modifier)
            hero:AddNewModifier(hero, nil, bpass_modifier, {duration = -1})
        end
    end
    -- Apply stacked donator modifiers
    if GetMapName() ~= "epic_boss_fight_purgatory" and not GameRules.FairPlayMode then
        local modData = CustomNetTables:GetTableValue("donator_modifiers", tostring(playerID)) or {}
        local modifiers = modData.modifiers or {}
        for _, mod in pairs(modifiers) do
            if type(mod) == "table" then
                local stackMod = bpass.reward[mod.tier]
                if stackMod then
                    hero:AddNewModifier(hero, nil, stackMod, {duration = -1})
                    print("[bpass] Apply stacked modifier: " .. tostring(mod.tier) .. " -> " .. stackMod)
                end
            end
        end
    end

    for i = 0, 30 do
       local current_ability = hero:GetAbilityByIndex(i)
       if current_ability ~= nil and current_ability:GetAbilityName() == "dummy_ability_test" then
           hero:RemoveAbilityByHandle(current_ability)
           print(i .. current_ability:GetAbilityName())
       end 
   end

   local playerID = hero:GetPlayerOwnerID()
   
   -- set hero base stats to their intended values
   hero:SetBaseManaRegen( (hero:GetBaseIntellect() / 5) * 0.04 )
   
   hero.damageDone = 0
   hero.Ressurect = 0
   --stats:ModifyStatBonuses(hero)
   local ID = hero:GetPlayerID()

    if PlayerResource:IsValidPlayerID( playerID ) and not (IsAbilityDraftMap and IsAbilityDraftMap()) then
       local decoded = CustomNetTables:GetTableValue("mmr", tostring( playerID ) )
       local maxstreak  = CustomNetTables:GetTableValue("maxStreak", tostring( playerID ) )
       local mmr = CustomNetTables:GetTableValue("game_state", 'leaderboard_mmr' )
       local found, player = top10MMR(mmr, PlayerResource:GetSteamID(ID))
       local purgatory = CustomNetTables:GetTableValue("patrons", tostring(playerID)) or {}
       local purgatory_diff = purgatory.purgatory_diff

       if decoded and purgatory and purgatory.purgatory and purgatory.purgatory > 0 then
        EventListeners:OnPetEquipped(hero, decoded.mmr)
        EventListeners:EquipHeroAura(hero, purgatory_diff)
        -- EventListeners:ApplyCosmetic(hero)
       end

       local purgatory_reward = CustomNetTables:GetTableValue("purgatory_reward", tostring(playerID)) or {}
       local is_active = purgatory_reward.is_active
       print(string.format("[PurgatoryReward] is_active: %s", is_active))
       if is_active == 1 and GetMapName() ~= "epic_boss_fight_purgatory" and not GameRules.FairPlayMode then
           PurgatoryReward:GiveReward(purgatory_reward, hero)
       end

       if decoded then
           
        --    if found then
        --        local heroSpawnImmortalParticle = 'particles/prime/hero_spawn_hero_level_6.vpcf'
        --        local ImmortalFX = ParticleManager:CreateParticle(heroSpawnImmortalParticle, PATTACH_POINT_FOLLOW, hero )
        --        hero:AddEffects(ImmortalFX)
        --    end
        --    if decoded.mmr > 16000 then
        --        if PlayerResource:GetSteamAccountID( playerID ) == 108597233  then
                   
        --            local itemFX_agha = ParticleManager:CreateParticle("particles/agha/agh_lvl2.vpcf", PATTACH_POINT_FOLLOW, hero )
        --            local itemFX = ParticleManager:CreateParticle("particles/radiance/cool_effect.vpcf", PATTACH_POINT_FOLLOW, hero )
        --            hero:AddEffects(itemFX_agha)
        --            hero:AddEffects(itemFX)

                   
        --        else
        --            -- status hero particle biru saiyan
        --            local itemFX = ParticleManager:CreateParticle("particles/radiance/cool_effect_blue_.vpcf", PATTACH_POINT_FOLLOW, hero )
        --            hero:AddEffects(itemFX)
        --        end

               
        --    elseif decoded.mmr > 25000 then
        --        local itemFX = ParticleManager:CreateParticle("particles/radiance/cool_effect_orange.vpcf", PATTACH_POINT_FOLLOW, hero)
        --        hero:AddEffects(itemFX)
        --    elseif decoded.mmr > 15000 then
        --        local itemFX = ParticleManager:CreateParticle("particles/radiance/cool_effect_purple.vpcf", PATTACH_POINT_FOLLOW, hero)
        --        hero:AddEffects(itemFX)
        --    elseif decoded.mmr > 8000 then
        --        local itemFX = ParticleManager:CreateParticle("particles/radiance/radiance_green.vpcf", PATTACH_POINT_FOLLOW, hero )
        --        hero:AddEffects(itemFX)
        --    else
               
        --    end
               
               
       end

       if decoded then
           if decoded.mmr > 6000 then
               

               -- status hero particle biru saiyan
               PlayerResource._shiva = 'particles/shivas/shivas_blue_active.vpcf'
               PlayerResource._shiva_impact = "particles/items2_fx/shivas_guard_impact.vpcf"
           elseif decoded.mmr > 5000 then
               PlayerResource._shiva = "particles/items2_fx/shivas_guard_active.vpcf"
               PlayerResource._shiva_impact = "particles/items2_fx/shivas_guard_impact.vpcf"
           elseif decoded.mmr > 4000 then
               PlayerResource._shiva = "particles/shivas/shivas_red_active.vpcf"
               PlayerResource._shiva_impact = "particles/items2_fx/shivas_guard_impact.vpcf"
           elseif decoded.mmr > 3000 then
               -- shiva warna hijau
               PlayerResource._shiva = "particles/shivas/shivas_active.vpcf"
               PlayerResource._shiva_impact = "particles/items2_fx/shivas_green_guard_impact.vpcf"
           else
               PlayerResource._shiva = "particles/items2_fx/shivas_guard_active.vpcf"
               PlayerResource._shiva_impact = "particles/items2_fx/shivas_guard_impact.vpcf"
           end
               
               
       end
       
   end


   local player = PlayerResource:GetPlayer(ID)
   if not player then return end --tester
    player.HB = true
    player.Health_Bar_Open = false
   --[[Timers:CreateTimer(2.5,function()
            if self._NewGamePlus == true and PlayerResource:GetGold(ID)>= 80000 then
                self._Buy_Asura_Core(ID)
            end
            return 2.5
        end)]]

   --[[if PlayerResource:GetSteamAccountID( ID ) == 86736807 then
       print ("look like a chalenger is here :D")
       message_chalenger = true
       self.chalenger = hero
       GameRules:GetGameModeEntity():SetThink( "Chalenger", self, 0.25 )
   end]]
   
   local fountain = nil
   for _,unit in pairs ( Entities:FindAllByName( "*fountain*")) do
       if unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
           fountain = unit
       end
   end
   
   for i = 0, 10 do
       local ability = hero:GetAbilityByIndex( i )
       if ability and ability:IsInnateAbility() then
           ability:SetLevel( 1 )
       end
   end

   local courierPosition = hero:GetAbsOrigin()
   if fountain ~= nil then
       courierPosition = fountain:GetAbsOrigin()
   end

   -- local team = hero:GetTeamNumber()
   -- if team == DOTA_TEAM_GOODGUYS then
       -- local cr = CreateUnitByName("npc_dota_courier", courierPosition + RandomVector(RandomFloat(100, 100)), true, hero, hero, hero:GetTeamNumber())
       -- cr:SetOwner(hero)
       -- cr:SetControllableByPlayer(playerID, true)
   -- end
   
   if hero:GetTeamNumber() == DOTA_TEAM_BADGUYS then
       -- DeleteAbility(hero)
       -- TeachAbility (hero , "hide_hero")
       hero:AddNoDraw()
       self.boss_master_id = ID
   end

   CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {life = Life._life})
   
   hero.damage_dealt_ingame = 0
   hero.damage_taken_ingame = 0
   hero.damage_healed_ingame = 0

--    hero._heroManaType = GameRules.HeroKV[hero:GetUnitName()].ManaType or "Mana"
   
   if hero:GetManaType() == "Mana" then
       hero:SetBaseManaRegen( (hero:GetBaseIntellect() / 5) * 0.04 )
   else
       hero:SetBaseManaRegen( 0 )
   end

   CustomNetTables:SetTableValue("game_stats", tostring( playerID ), {damage_dealt = 0, damage_taken = 0, damage_healed = 0, last_damage_dealt = 0})
   CustomNetTables:SetTableValue("hero_attributes", tostring( hero:entindex() ), {mana_type = hero._heroManaType})

   PlayerResource:SetCustomBuybackCooldown( playerID, 10 )
   PlayerResource:SetCustomBuybackCost( playerID, 100 )
   
   local tp = hero:FindItemInInventory( "item_tpscroll" )
   if tp then
       hero:RemoveItem( tp )
   end
   hero:AddItemByName("item_bottle")
--    hero:AddItemByName("item_ability_book")
   if MINOR_ABILITY_UPGRADES[hero:GetUnitName()] ~= nil then
       hero:AddItemByName( "item_ability_upgrade" )
       hero:AddItemByName( "item_ability_book" )
       
       -- Give attribute book based on hero primary attribute
       local primaryAttr = hero:GetPrimaryAttribute()
       if primaryAttr == DOTA_ATTRIBUTE_STRENGTH then
           hero:AddItemByName("item_book_of_strength"):SetCurrentCharges(1)
       elseif primaryAttr == DOTA_ATTRIBUTE_AGILITY then
           hero:AddItemByName("item_book_of_agility"):SetCurrentCharges(1)
       elseif primaryAttr == DOTA_ATTRIBUTE_INTELLECT then
           hero:AddItemByName("item_book_of_intelligence"):SetCurrentCharges(1)
       end
   end

   hero:AddItemByName("item_revenant_ebf")
   hero:AddItemByName("item_octarine_core2")

    local eventConfig = CustomNetTables:GetTableValue('choosen_difficulty', 'saved') or {}
    local diff = eventConfig.class

   local allowed_diffs = {
        S1 = true,
        S2 = true,
        S3 = true,
        S4 = true,
        S5 = true,
    }

    if allowed_diffs[diff] and GetMapName() == "epic_boss_fight_nightmare" then
        hero:AddItemByName("item_aegis")
    elseif GetMapName() == "epic_boss_fight_soul" or GetMapName() == "epic_boss_fight_god" then
        print("No item granted on soul map")
    else
        local heroMidas = hero:AddItemByName("item_hand_of_midas_ebf")
        heroMidas:SetCombineLocked(true)
        heroMidas:SetSellable(false)
    end

    if GetMapName() == "epic_boss_fight_purgatory" then
        hero:AddItemByName("item_aeon_disk")
    end

--    hero:AddItemByName("item_tier1_token")
   if PlayerResource:GetPatronTier(playerID) >= 2 then
       hero:AddItemByName( "item_aegis" )
   end

   hero:SetDayTimeVisionRange(1200)
   hero:SetNightTimeVisionRange(900)

   local steamid = tostring(PlayerResource:GetSteamID(ID))
   local playerName = PlayerResource:GetPlayerName(ID)
   print("PlayerName: " .. playerName)
--    if isSteamIDInTop5Leaderboard(top5Leaderboard, steamid) then
--     hero:SetCustomHealthLabel(string.format("#rank_%d", top5Leaderboard[steamid].index), 255, 215, 0)
--    end

   -- Season 1 Leaderboard premium particles
   ApplySeason1Particles(hero, steamid)

   -- Guild label (jika data sudah ada; jika belum, guild HTTP callback yang handle)
   ApplyGuildLabel(hero, playerID)
end

-- Palette warna per guild (RGB), assign berurutan saat guild baru muncul
local GUILD_COLOR_PALETTE = {
    {0,   200, 255}, -- cyan
    {255, 180,   0}, -- gold
    {0,   255, 128}, -- green
    {255,  80, 200}, -- pink
    {180, 100, 255}, -- purple
    {255, 120,  50}, -- orange
    {80,  220, 255}, -- light blue
    {255, 255,  80}, -- yellow
}
local guildColorMap   = {}  -- guild_id (string) -> palette index
local guildColorCount = 0

local function GetGuildColor(guild_id)
    local key = tostring(guild_id)
    if not guildColorMap[key] then
        guildColorCount = guildColorCount + 1
        guildColorMap[key] = ((guildColorCount - 1) % #GUILD_COLOR_PALETTE) + 1
    end
    return GUILD_COLOR_PALETTE[guildColorMap[key]]
end

function ApplyGuildLabel(hero, playerID)
    local guildInfo = CustomNetTables:GetTableValue("guild", tostring(playerID))
    if not (guildInfo and guildInfo.has_guild and guildInfo.guild_tag) then return end

    local steamid = tostring(PlayerResource:GetSteamID(playerID))
    local s1rank  = season1Leaderboard[steamid]

    local label
    if s1rank and s1rank.index >= 4 then
        label = "[" .. guildInfo.guild_tag .. "] - Top " .. s1rank.index
    else
        label = "[" .. guildInfo.guild_tag .. "]"
    end

    local c = GetGuildColor(guildInfo.guild_id)
    hero:SetCustomHealthLabel(label, c[1], c[2], c[3])
end

function ApplySeason1Particles(hero, steamid)
   local s1rank = season1Leaderboard[steamid]
   if not s1rank then return end

   -- Destroy particles lama jika ada (untuk reconnect)
   if hero._s1_pid_overhead then
       ParticleManager:DestroyParticle(hero._s1_pid_overhead, false)
       ParticleManager:ReleaseParticleIndex(hero._s1_pid_overhead)
       hero._s1_pid_overhead = nil
   end
   if hero._s1_pid_wings then
       ParticleManager:DestroyParticle(hero._s1_pid_wings, false)
       ParticleManager:ReleaseParticleIndex(hero._s1_pid_wings)
       hero._s1_pid_wings = nil
   end

   local rank = s1rank.index
   local overhead_particle, wings_particle

   if rank == 1 then
       overhead_particle = "particles/econ/overhead_top/overhead_top1.vpcf"
       wings_particle    = "particles/econ/legion_wings/legion_wings_vip.vpcf"
   elseif rank == 2 then
       overhead_particle = "particles/econ/overhead_top/overhead_top2.vpcf"
       wings_particle    = "particles/econ/legion_wings/legion_wings.vpcf"
   elseif rank == 3 then
       overhead_particle = "particles/econ/overhead_top/overhead_top3.vpcf"
       wings_particle    = "particles/econ/legion_wings/legion_wings.vpcf"
   else
       overhead_particle = "particles/econ/overhead_energy_star.vpcf"
   end

   local pid_overhead = ParticleManager:CreateParticle(overhead_particle, PATTACH_OVERHEAD_FOLLOW, hero)
   ParticleManager:SetParticleControlEnt(pid_overhead, 0, hero, PATTACH_OVERHEAD_FOLLOW, "follow_overhead", hero:GetAbsOrigin(), true)
   hero._s1_pid_overhead = pid_overhead

   if wings_particle then
       local pid_wings = ParticleManager:CreateParticle(wings_particle, PATTACH_ABSORIGIN_FOLLOW, hero)
       ParticleManager:SetParticleControlEnt(pid_wings, 0, hero, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", hero:GetAbsOrigin(), true)
       ParticleManager:SetParticleControlEnt(pid_wings, 1, hero, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", hero:GetAbsOrigin(), true)
       ParticleManager:SetParticleControlEnt(pid_wings, 2, hero, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", hero:GetAbsOrigin(), true)
       ParticleManager:SetParticleControlEnt(pid_wings, 3, hero, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", hero:GetAbsOrigin(), true)
       ParticleManager:SetParticleControlEnt(pid_wings, 4, hero, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", hero:GetAbsOrigin(), true)
       hero._s1_pid_wings = pid_wings
   end
end

-- Verify spawners if random is set
function CHoldoutGameMode:OnConnectFull(data)
    CheckJakartaTime()
    FetchGuildLeaderboard()
    FetchSupporterStorePricing()
    print("MapName: " .. GetMapName())
    print("[OnConnectFull] PlayerID:" .. data.PlayerID)
    print("[OnConnectFull] userid:" .. data.userid)

    self.user_ids[data.PlayerID] = data.userid

    -- Re-apply season 1 particles and guild label on reconnect
    local reconHero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
    if reconHero and reconHero:IsRealHero() then
        local reconSteamid = tostring(PlayerResource:GetSteamID(data.PlayerID))
        ApplySeason1Particles(reconHero, reconSteamid)
        ApplyGuildLabel(reconHero, data.PlayerID)
    end

    if PlayerResource:GetSteamAccountID(data.PlayerID) == 108597233 then
        CustomNetTables:SetTableValue("admin_panel", "admin_playerid", { playerid = data.PlayerID })
        print(string.format("[ADMIN] Admin player connected, playerID: %s", data.PlayerID))

        -- Register semua valid player yang belum punya user_id (misal bot/fake client)
        for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
            if PlayerResource:IsValidPlayerID(i) and not self.user_ids[i] then
                self.user_ids[i] = i
                print(string.format("[ADMIN] Registered dummy user_id for player slot %d", i))
            end
        end
    end

    local steamID = tostring(PlayerResource:GetSteamID(data.PlayerID))
    local kickedData = CustomNetTables:GetTableValue("kicked_data", steamID)
    if kickedData and kickedData.kicked then
        print(string.format("[ADMIN] Player %s tried to rejoin but is admin-kicked. Kicking again.", data.PlayerID))
        SendToServerConsole('kickid ' .. data.userid)
        return
    end

    local banData = CustomNetTables:GetTableValue("ban", tostring(data.PlayerID))
    if banData and banData.ban ~= nil and banData.bancount > 6 then
        print(string.format("[KICK] Player %s has been kicked (banned).", data.PlayerID))
        SendToServerConsole('kickid ' .. data.userid)
    end

    local godMapRestricted = CustomNetTables:GetTableValue("god_map_restricted", tostring(data.PlayerID))
    if godMapRestricted and godMapRestricted.restricted then
        print(string.format("[GOD MAP] Player %s mencoba reconnect tapi tidak punya akses. Kick.", data.PlayerID))
        SendToServerConsole('kickid ' .. data.userid)
        return
    end
    
    local AUTH_KEY = GetAuthKey()
    local SERVER_LOCATION = GetServerLocation()

    local keyLoc = SERVER_LOCATION..'keycollection.json'
    local keyRequest = CreateHTTPRequestScriptVM( "PUT", keyLoc)
    local keyData = {[AUTH_KEY] = true}
    local encoded = json.encode(keyData)
    local eventConfig = CustomNetTables:GetTableValue('choosen_difficulty', 'saved')
    
    keyRequest:SetHTTPRequestRawPostBody("application/json", encoded)
    keyRequest:Send( function( result ) end )
 
    local players = 0
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
       if PlayerResource:IsValidPlayerID( nPlayerID ) then
          players = players + 1
       end
    end
    local averageMMR = 0
    local mmrTable = {}

    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
        if PlayerResource:IsValidPlayerID( nPlayerID ) then
            mmrTable[nPlayerID] = false
            local steamId = tostring(PlayerResource:GetSteamID(nPlayerID))

            PurgatoryReward:CheckRewardStatus(nPlayerID, mmrTable, averageMMR)

            CustomNetTables:SetTableValue("steamid", tostring(nPlayerID), {steamid = PlayerResource:GetSteamID(nPlayerID)})

            -- Check guild for the player
            local _guildSettings = GetStatSettings()
            local _guildBaseUrl = _guildSettings.apiBaseUrl or "https://ebfimba.stelincore.com"
            local guildCheckUrl = _guildBaseUrl .. "/api/gameserver/check-guild"
            local guildRequest = CreateHTTPRequestScriptVM("POST", guildCheckUrl)

            local guildAuthKey = GetAuthKey()

            guildRequest:SetHTTPRequestHeaderValue("X-EBFIMBA-KEY", guildAuthKey)
            guildRequest:SetHTTPRequestHeaderValue("Content-Type", "application/json")

            -- Send steam_id in the request body
            local guildRequestData = {
                steam_id = steamId
            }
            guildRequest:SetHTTPRequestRawPostBody("application/json", json.encode(guildRequestData))

            guildRequest:Send(function(guildResult)
                if guildResult.StatusCode == 200 then
                    local guildData = json.decode(guildResult.Body)
                    if guildData and guildData.success and guildData.has_guild then
                        -- Player has a guild, store the guild info
                        local guildInfo = {
                            has_guild = true,
                            guild_id = guildData.guild.id,
                            guild_name = guildData.guild.name,
                            guild_tag = guildData.guild.tag,
                            guild_level = guildData.guild.level,
                            guild_rank = guildData.guild.rank_name
                        }
                        CustomNetTables:SetTableValue("guild", tostring(nPlayerID), guildInfo)
                        print(string.format("[Guild] Player %d (%s) is in guild: %s [%s]", nPlayerID, steamId, guildData.guild.name, guildData.guild.tag))
                        local guildHero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
                        if guildHero and guildHero:IsRealHero() then
                            ApplyGuildLabel(guildHero, nPlayerID)
                        end
                    else
                        -- Player doesn't have a guild
                        CustomNetTables:SetTableValue("guild", tostring(nPlayerID), {has_guild = false})
                        print(string.format("[Guild] Player %d (%s) has no guild", nPlayerID, steamId))
                    end
                else
                    --  default to no guild
                    CustomNetTables:SetTableValue("guild", tostring(nPlayerID), {has_guild = false})
                    print(string.format("[Guild] Failed to check guild for player %d: HTTP %d", nPlayerID, guildResult.StatusCode))
                end
            end)
        end
    end
    local isAbilityDraftMap = IsAbilityDraftMap and IsAbilityDraftMap()

    if isAbilityDraftMap then
        Timers:CreateTimer( function()
            for playerID, mmr in pairs( mmrTable ) do
                if not mmr then
                    return 0.1
                end
            end

            for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
                if PlayerResource:IsValidPlayerID( nPlayerID ) then
                    local mmrPlayer = {mmr = math.floor(mmrTable[nPlayerID] or 3000), win = 0, loss = 0}
                    CustomNetTables:SetTableValue("mmr", tostring( nPlayerID ), mmrPlayer)

                    if GameRules.holdOut and GameRules.holdOut._vPlayerStats and GameRules.holdOut._vPlayerStats[nPlayerID] then
                        GameRules.holdOut._vPlayerStats[nPlayerID].mmr = mmrPlayer.mmr
                        CustomNetTables:SetTableValue("players_stats", tostring( nPlayerID ), GameRules.holdOut._vPlayerStats[nPlayerID])
                    end
                end
            end
        end)
    else
    Timers:CreateTimer( function()
        for playerID, mmr in pairs( mmrTable ) do
            if not mmr then -- mmr not gotten yet
                return 0.1
            end
        end
        -- all mmrs gotten
        averageMMR = averageMMR / players
        GameRules._averageMMRForMatch = averageMMR
        

        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
            if PlayerResource:IsValidPlayerID( nPlayerID ) then
                local mmrPlayer = {mmr = math.floor(mmrTable[nPlayerID])}
                local winMMR = CalculateMMRChangeForPlayer( GetMapName(), averageMMR, true ) - averageMMR
                local lossMMR = CalculateMMRChangeForPlayer( GetMapName(), averageMMR, false ) - averageMMR
                -- calc after player amount
                local playerMultiplier = 1 + ( self._MaxPlayers - players ) * ( 50 / (self._MaxPlayers-1) ) / 100
                if GameRules:IsCheatMode() then
                    mmrPlayer.win = math.floor(winMMR*playerMultiplier + 0.5 )
                    mmrPlayer.loss = math.floor(lossMMR/playerMultiplier + 0.5 )
                else
                    -- TODO: Normal map max MMR gain hanya +10
                    if GetMapName() == "epic_boss_fight_normal" then
                        mmrPlayer.win = math.floor(winMMR*playerMultiplier + 0.5 ) + 10
                        mmrPlayer.loss = math.floor(lossMMR/playerMultiplier + 0.5 )
                    elseif GetMapName() == "epic_boss_fight_hard" then
                        mmrPlayer.win = math.floor(winMMR*playerMultiplier + 0.5 ) + 30
                        mmrPlayer.loss = math.floor(lossMMR/playerMultiplier + 0.5 ) - 20
                    elseif GetMapName() == "epic_boss_fight_challenger" then
                        mmrPlayer.win = math.floor(winMMR*playerMultiplier + 0.5 ) + 50
                        mmrPlayer.loss = math.floor(lossMMR/playerMultiplier + 0.5 ) - 50
                    elseif GetMapName() == "epic_boss_fight_nightmare" then
                        mmrPlayer.win = math.floor(winMMR*playerMultiplier + 0.5 ) + 150
                        mmrPlayer.loss = math.floor(lossMMR/playerMultiplier + 0.5 ) - 120
                    elseif GetMapName() == "epic_boss_fight_god" then
                        mmrPlayer.win = math.floor(winMMR*playerMultiplier + 0.5 ) + 500
                        mmrPlayer.loss = math.floor(lossMMR/playerMultiplier + 0.5 ) - 400
                    else
                        mmrPlayer.win = math.floor(winMMR*playerMultiplier + 0.5 ) + 250
                        mmrPlayer.loss = math.floor(lossMMR/playerMultiplier + 0.5 ) - 220
                    end
                end
                
                if not IsDedicatedServer() or GameRules:IsCheatMode() then
                    winMMR = 0
                    lossMMR = 0
                end
                CustomNetTables:SetTableValue("mmr", tostring( nPlayerID ), mmrPlayer)
           end
        end
    end)
    end
    
-- Function to decode base64
local function base64decode(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = string.gsub(data, "[^" .. b .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

-- Fetching data from URL
local url_mmr = "https://raw.githubusercontent.com/lintangtimur/dota2-custom-game-lobby-list/master/ebf_imbafied_mmr.txt"
local req_mmr = CreateHTTPRequestScriptVM("GET", url_mmr)
req_mmr:Send(function(result)
    if result["StatusCode"] == 200 then
        -- Decoding base64 data
        local decodedData = base64decode(result["Body"])

        -- Parsing the decoded data into blocks
        local leaderboard_mmr = {}
        for line in decodedData:gmatch("[^\r\n]+") do
            local lb_mmr_steamID, lb_mmr_mmr, lb_mmr_plays, lb_mmr_wins = line:match("(%d+),%s*(%d+),%s*(%d+),%s*(%d+)")
            if lb_mmr_steamID and lb_mmr_mmr and lb_mmr_plays and lb_mmr_wins then
                table.insert(leaderboard_mmr, {steamID = lb_mmr_steamID, mmr = lb_mmr_mmr, plays = lb_mmr_plays, wins = lb_mmr_wins})
            end
        end

        table.sort(leaderboard_mmr, function(a, b)
            return tonumber(a.mmr) > tonumber(b.mmr)
        end)
        
        for i = 1, math.min(5, #leaderboard_mmr) do
            local player = leaderboard_mmr[i]
            top5Leaderboard[tostring(player.steamID)] = {
                mmr = player.mmr,
                index = i
            }
        end
        
        CustomNetTables:SetTableValue("game_state", "leaderboard_mmr", leaderboard_mmr)
    end
end)

-- Fetching data from URL
-- local url_wr = "https://raw.githubusercontent.com/john-mayhem/ebf_lb/main/leaderboard/lb_2.txt"
-- local req_wr = CreateHTTPRequestScriptVM("GET", url_wr)
-- req_wr:Send(function(result)
--     if result["StatusCode"] == 200 then
--         -- Decoding base64 data
--         local decodedData = base64decode(result["Body"])

--         -- Parsing the decoded data into blocks
--         local leaderboard_wr = {}
--         for line in decodedData:gmatch("[^\r\n]+") do
--             local lb_wr_steamID, lb_wr_mmr, lb_wr_plays, lb_wr_wins = line:match("(%d+),%s*(%d+),%s*(%d+),%s*(%d+)")
--             if lb_wr_steamID and lb_wr_mmr and lb_wr_plays and lb_wr_wins then
--                 table.insert(leaderboard_wr, {steamID = lb_wr_steamID, mmr = lb_wr_mmr, plays = lb_wr_plays, wins = lb_wr_wins})
--             end
--         end

--         -- Storing the leaderboard data in netTable
--         CustomNetTables:SetTableValue("game_state", "leaderboard_wr", leaderboard_wr)
--     end
-- end)


-- fetching soul leaderboard
local url_soul = "https://raw.githubusercontent.com/lintangtimur/dota2-custom-game-lobby-list/refs/heads/master/soulrank.txt"
local req_soul = CreateHTTPRequestScriptVM("GET", url_soul)
req_soul:Send(function(result)
    if result["StatusCode"] == 200 then
        -- Decoding base64 data
        local decodedData = base64decode(result["Body"])

        -- Parsing the decoded data into blocks
        local leaderboard_soul = {}
        for line in decodedData:gmatch("[^\r\n]+") do
            local lb_wr_steamID, lb_wr_soul, lb_wr_mmr = line:match("(%d+),%s*(%d+),%s*(%d+)")
            if lb_wr_steamID and lb_wr_mmr and lb_wr_soul then
                table.insert(leaderboard_soul, {steamID = lb_wr_steamID, mmr = lb_wr_mmr, soul = lb_wr_soul})
            end
        end

        -- Storing the leaderboard data in netTable
        CustomNetTables:SetTableValue("game_state", "leaderboard_soul", leaderboard_soul)
    end
end)

-- Fetching Season 1 MMR leaderboard for premium particles
local url_season1 = "https://raw.githubusercontent.com/lintangtimur/dota2-custom-game-lobby-list/refs/heads/master/mmr_season1.txt"
local req_season1 = CreateHTTPRequestScriptVM("GET", url_season1)
req_season1:Send(function(result)
    if result["StatusCode"] == 200 then
        local decodedData = base64decode(result["Body"])
        local leaderboard_s1 = {}
        for line in decodedData:gmatch("[^\r\n]+") do
            local steamID, mmr, plays, wins = line:match("(%d+),%s*(%d+),%s*(%d+),%s*(%d+)")
            if steamID and mmr then
                table.insert(leaderboard_s1, {steamID = steamID, mmr = tonumber(mmr)})
            end
        end
        table.sort(leaderboard_s1, function(a, b) return a.mmr > b.mmr end)
        for i = 1, math.min(10, #leaderboard_s1) do
            season1Leaderboard[leaderboard_s1[i].steamID] = { index = i }
        end
        print(string.format("[Season1] Loaded %d players into season1Leaderboard", math.min(10, #leaderboard_s1)))
    end
end)

-- Fetching data from URL
local urlMarkdown = "https://raw.githubusercontent.com/lintangtimur/ebf-imbafied-changenote/master/patch.md"
local reqMarkdown = CreateHTTPRequestScriptVM("GET", urlMarkdown)
reqMarkdown:Send(function(result)
    if result["StatusCode"] == 200 then
        -- Storing the Markdown content in netTable
        CustomNetTables:SetTableValue("game_state", "patchnotes_content", { content = result["Body"] })
    end
end)


end

function CHoldoutGameMode:OnPlayerReconnected(event)
    local playerID = event.PlayerID
    local banData = CustomNetTables:GetTableValue("ban", tostring(playerID))
    if banData and banData.ban ~= nil and banData.bancount > 6 then
        local user_id = self.user_ids[playerID]
        if user_id then
            print(string.format("[KICK] Player %s reconnected but is banned, kicking.", playerID))
            SendToServerConsole('kickid ' .. user_id)
        end
    end
end

function CHoldoutGameMode:OnPlayerDisconnected(event)
    local userid = event.userid
    local steamid = event.steamid
    local playerId = event.PlayerID
end

function CHoldoutGameMode:dota_player_reconnected(event)
    local playerID = event.PlayerID
    local banData = CustomNetTables:GetTableValue("ban", tostring(playerID))
    if banData and banData.ban ~= nil and banData.bancount > 6 then
        local user_id = self.user_ids[playerID]
        if user_id then
            print(string.format("[KICK] Player %s reconnected but is banned, kicking.", playerID))
            SendToServerConsole('kickid ' .. user_id)
        end
    end
end

function CHoldoutGameMode:admin_kick(event)
    print("[ADMIN] admin_kick event received: " .. tostring(event.PlayerID) .. " wants to kick " .. tostring(event.target_playerid) .. " for reason: " .. tostring(event.reason))
    local ADMIN_STEAMID_ACCOUNT = 108597233
    local requesterID = event.PlayerID
    local targetID = event.target_playerid
    local reason = event.reason or "No reason given"

    if PlayerResource:GetSteamAccountID(requesterID) ~= ADMIN_STEAMID_ACCOUNT then
        print(string.format("[ADMIN] Unauthorized admin_kick attempt from player %s", requesterID))
        return
    end

    if not PlayerResource:IsValidPlayerID(targetID) then
        print(string.format("[ADMIN] Invalid target player ID: %s", targetID))
        return
    end

    -- Register bot/fake client yang belum punya user_id (ditambah setelah admin join)
    if not GameRules.holdOut.user_ids[targetID] and PlayerResource:IsFakeClient(targetID) then
        GameRules.holdOut.user_ids[targetID] = targetID
        print(string.format("[ADMIN] Registered dummy user_id on-demand for bot slot %d", targetID))
    end

    local user_id = GameRules.holdOut.user_ids[targetID]
    if not user_id then
        print(string.format("[ADMIN] User ID not found for player: %s", targetID))
        return
    end

    local targetName = PlayerResource:GetPlayerName(targetID)

    -- Bot (fake client) pakai bot_kick, real player pakai kickid
    if PlayerResource:IsFakeClient(targetID) then
        print(string.format("[ADMIN] Kicking bot player %s using bot_kick", targetName))
        SendToServerConsole('kickid ' .. user_id)
    else
        print(string.format("[ADMIN] Kicking real player %s using kickid with user_id %s", targetName, user_id))
        SendToServerConsole('kickid ' .. user_id)
    end

    -- Block rejoin via CustomNetTables
    local targetSteamID = tostring(PlayerResource:GetSteamID(targetID))
    CustomNetTables:SetTableValue("kicked_data", targetSteamID, { kicked = true, reason = reason })

    Notifications:BottomToAll({ text = "[Admin] " .. targetName .. " was kicked. Reason: " .. reason, duration = 5 })

    print(string.format("[ADMIN] Player %s was kicked by admin. Reason: %s", targetName, reason))
end

function CHoldoutGameMode:admin_command(event)
    local ADMIN_STEAMID_ACCOUNT = 108597233
    local requesterID = event.PlayerID

    if PlayerResource:GetSteamAccountID(requesterID) ~= ADMIN_STEAMID_ACCOUNT then
        print(string.format("[ADMIN] Unauthorized admin_command attempt from player %s", requesterID))
        return
    end

    local cmd = event.cmd
    local arg1 = event.arg1

    print(string.format("[ADMIN] admin_command: %s arg1=%s", tostring(cmd), tostring(arg1)))

    if cmd == "holdout_test_round" then
        GameRules.holdOut:_TestRoundConsoleCommand(nil, arg1)
    elseif cmd == "ebf_set_health" then
        GameRules.holdOut:_TestSetHealth(nil, tonumber(arg1))
    elseif cmd == "ebf_gold" then
        GameRules.holdOut._Goldgive()
    elseif cmd == "ebf_max_level" then
        GameRules.holdOut._LevelGive()
    elseif cmd == "ebf_drop" then
        GameRules.holdOut:_ItemDrop(arg1)
    elseif cmd == "holdout_spawn_gold" then
        GameRules.holdOut:_GoldDropConsoleCommand(nil, tonumber(arg1))
    elseif cmd == "ebf_reward" then
        GameRules.holdOut:_TestEndReward()
    elseif cmd == "ebf_capture" then
        GameRules.holdOut:_TestOrb()
    end
end

function CHoldoutGameMode:OnAbilityUsed(keys)
    --will be used in future :p
    local player = PlayerResource:GetPlayer(keys.PlayerID)
    local hero = EntIndexToHScript( keys.caster_entindex )
    local abilityname = keys.abilityname
end

function CHoldoutGameMode:OnHeroLevelUp(event)
    local playerID = EntIndexToHScript(event.player):GetPlayerID()
    local unit = EntIndexToHScript(event.hero_entindex)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero == unit then
        if PlayerResource:GetSteamAccountID( playerID ) == 108597233 then
            ParticleManager:CreateParticle("particles/econ/events/ti9/hero_levelup_ti9.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
        end

        if hero:GetLevel() >= 27 and not (hero:GetLevel() == 30) then
            hero:SetAbilityPoints( hero:GetAbilityPoints() + 1)
        end
    end
end


function CHoldoutGameMode:OnPlayerChat(event)
    local playerID = event.playerid
    local text = event.text
    local steamid = tostring(PlayerResource:GetSteamID(playerID))
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local playerName = PlayerResource:GetPlayerName(playerID)

    table.insert(playerChats, {
        steamid = steamid,
        hero_name = PlayerResource:GetSelectedHeroName(playerID),
        player_id = playerID,
        player_name = playerName,
        gametime = math.floor(GameRules:GetDOTATime(false, false)),
        message = text
    })

    if IsInToolsMode() or GameRules:IsCheatMode() then
        if text == "-test_bug" then
            BugReporter:SendReport("simulasi error manual dari chat", "ThinkDefeat")
            Say(nil, "[BugReporter] Test report dikirim, cek console untuk hasilnya.", false)
        end

        -- ============================================================
        -- SIMULASI SEMUA PARTICLE PREMIUM (hanya yg sudah ada .vpcf_c)
        -- Row 0 (x+200): Wings/Body particles
        -- Row 1 (x+450): Overhead particles
        -- ============================================================
        if text == "-test_particles" then
            if not hero then return end
            local origin = hero:GetAbsOrigin()
            GameRules._testParticleUnits = GameRules._testParticleUnits or {}

            local HEROES = {
                "npc_dota_hero_lina",
                "npc_dota_hero_crystal_maiden",
                "npc_dota_hero_shadow_fiend",
                "npc_dota_hero_lion",
                "npc_dota_hero_drow_ranger",
                "npc_dota_hero_rubick",
                "npc_dota_hero_witch_doctor",
                "npc_dota_hero_storm_spirit",
                "npc_dota_hero_invoker",
            }

            -- ROW 0: Wings / Body particles (PATTACH_ABSORIGIN_FOLLOW)
            local bodyConfigs = {
                { label = "Legion Wings",        body = "particles/econ/legion_wings/legion_wings.vpcf" },
                { label = "Legion Wings VIP",    body = "particles/econ/legion_wings/legion_wings_vip.vpcf" },
                { label = "Legion Wings Pink",   body = "particles/econ/legion_wings/legion_wings_pink.vpcf" },
                { label = "SF GoldSky Wings",    body = "particles/wings/wing_sf_goldsky_gold.vpcf" },
                { label = "SF GoldGold Wings",   body = "particles/wings/wing_sf_goldgold.vpcf" },
                { label = "Radiance Cool Gold",  body = "particles/radiance/cool_effect.vpcf" },
                { label = "Ethereal Flame",      body = "particles/econ/ethereal_flame.vpcf" },
                { label = "Tournament Flame",    body = "particles/econ/tourament_flame.vpcf" },
            }

            -- ROW 1: Overhead particles (PATTACH_OVERHEAD_FOLLOW)
            local overheadConfigs = {
                { label = "Overhead Top 1",      overhead = "particles/econ/overhead_top/overhead_top1.vpcf" },
                { label = "Overhead Top 2",      overhead = "particles/econ/overhead_top/overhead_top2.vpcf" },
                { label = "Overhead Top 3",      overhead = "particles/econ/overhead_top/overhead_top3.vpcf" },
                { label = "Rank Top 1",          overhead = "particles/econ/rank_top1.vpcf" },
                { label = "Rank Top 2",          overhead = "particles/econ/rank_top2.vpcf" },
                { label = "Rank Top 3",          overhead = "particles/econ/rank_top3.vpcf" },
                { label = "Top Players Golden",  overhead = "particles/top_players_golden.vpcf" },
                { label = "Top Players Silver",  overhead = "particles/top_players_silver.vpcf" },
                { label = "Top Players Bronze",  overhead = "particles/top_players_bronze.vpcf" },
            }

            local SPACING = 220
            local function spawnRow(configs, rowX, ptype)
                local count = #configs
                local startY = -math.floor(count / 2) * SPACING
                for i, cfg in ipairs(configs) do
                    local heroName = HEROES[((i - 1) % #HEROES) + 1]
                    local pos = origin + Vector(rowX, startY + (i - 1) * SPACING, 0)
                    local ok, unit = pcall(CreateUnitByName, heroName, pos, true, nil, nil, hero:GetTeam())
                    if not ok or unit == nil or unit:IsNull() then
                        print(string.format("[SimParticles] GAGAL spawn %s untuk '%s'", heroName, cfg.label))
                    else
                        unit:SetControllableByPlayer(playerID, true)
                        unit:SetCustomHealthLabel(cfg.label, 255, 215, 0)

                        if ptype == "body" and cfg.body then
                            local pid = ParticleManager:CreateParticle(cfg.body, PATTACH_ABSORIGIN_FOLLOW, unit)
                            ParticleManager:SetParticleControlEnt(pid, 0, unit, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", unit:GetAbsOrigin(), true)
                            unit._simPid1 = pid
                        elseif ptype == "overhead" and cfg.overhead then
                            local pid = ParticleManager:CreateParticle(cfg.overhead, PATTACH_OVERHEAD_FOLLOW, unit)
                            ParticleManager:SetParticleControlEnt(pid, 0, unit, PATTACH_OVERHEAD_FOLLOW, "follow_overhead", unit:GetAbsOrigin(), true)
                            unit._simPid1 = pid
                        end

                        table.insert(GameRules._testParticleUnits, unit)
                        print(string.format("[SimParticles] OK %s -> %s", heroName, cfg.label))
                    end
                end
            end

            spawnRow(bodyConfigs,     200, "body")
            spawnRow(overheadConfigs, 450, "overhead")

            local total = #bodyConfigs + #overheadConfigs
            Say(nil, string.format("[SimParticles] %d hero spawned. Row depan=Body, Row belakang=Overhead. Ketik -clean_particles untuk hapus.", total), false)
        end

        if text == "-clean_particles" then
            if GameRules._testParticleUnits then
                for _, unit in ipairs(GameRules._testParticleUnits) do
                    if IsValidEntity(unit) and unit:IsAlive() then
                        if unit._simPid1 then
                            ParticleManager:DestroyParticle(unit._simPid1, true)
                            ParticleManager:ReleaseParticleIndex(unit._simPid1)
                        end
                        if unit._simPid2 then
                            ParticleManager:DestroyParticle(unit._simPid2, true)
                            ParticleManager:ReleaseParticleIndex(unit._simPid2)
                        end
                        unit:RemoveSelf()
                    end
                end
                GameRules._testParticleUnits = {}
            end
            Say(nil, "[SimParticles] Semua test hero dihapus.", false)
        end
        -- ============================================================

        local matched_number = string.match(text, "^%-round%s+(%d+)$")

        if matched_number then
            local nRoundToTest = tonumber(matched_number)
            print("Testing round %d", nRoundToTest)
            if nRoundToTest <= 0 or nRoundToTest > #self._vRounds then
                print( "Cannot test invalid round %d", nRoundToTest )
                return
            end
            GameRules._roundnumber = nRoundToTest
            if NG then
                self:_EnterNG()
            end
        
            local nExpectedGold = 0
            local nExpectedXP = 0
            for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do
                if PlayerResource:IsValidPlayer( nPlayerID ) then
                    PlayerResource:SetBuybackCooldownTime( nPlayerID, 0 )
                    PlayerResource:SetBuybackGoldLimitTime( nPlayerID, 0 )
                    PlayerResource:ResetBuybackCostTime( nPlayerID )
                end
            end
        
            if self._currentRound ~= nil then
                self._currentRound:End(false)
                self._currentRound = nil
            end
        
            self._flPrepTimeEnd = GameRules:GetGameTime() + 15
            self._nRoundNumber = nRoundToTest
            local delay = 1
            if delay ~= nil then
                self._flPrepTimeEnd = GameRules:GetGameTime() + tonumber( delay )
            end
        end
    end

    
    -- Debug output
    print("Pesan disimpan: Player " .. playerName .. " (" .. playerID .. ") said: " .. text)
end

function CHoldoutGameMode:OnGameStart (event)
    CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {life = Life._life})
end


function EventListeners: OnPetEquipped(hero, mmr)
	local petData = GetRewardByMMR(mmr)
    if petData == nil then return end

    local model_path = petData.model_path
	local pet = CreateUnitByName(
		"npc_cosmetic_pet",
		hero:GetAbsOrigin() + RandomVector(300), true,
		hero, hero, hero:GetTeam()
	)
	-- pet:SetOwner(hero)
	pet:SetForwardVector(hero:GetForwardVector())
	local pet_modifier = pet:AddNewModifier(hero, nil, "modifier_equipped_pet", {duration = -1})
	pet:RemoveModifierByName("modifier_pet")
	pet:SetModel(model_path)
	pet:SetOriginalModel(model_path)
	pet:SetModelScale(petData.scale)

	-- pet:StartGesture(ACT_DOTA_SPAWN)

	-- if item_definition.material_group then
	-- 	pet:SetMaterialGroup(item_definition.material_group)
	-- end

	if petData.is_flying then
		pet_modifier:SetStackCount(1)
	end

    local p_id = ParticleManager:CreateParticle(petData.particle_path, PATTACH_RENDERORIGIN_FOLLOW, pet)
end

function EventListeners: ApplyCosmetic(hero)
    if hero:GetName() == "npc_dota_hero_night_stalker" then
        -- Menambahkan wearable ke hero
        local wearable = SpawnEntityFromTableSynchronous("prop_dynamic", {
            model = "models/items/nightstalker/ns_ti10_immortal_arms/ns_ti10_immortal_arms.vmdl"
        })
        wearable:FollowEntity(hero, true)
        wearable:SetSkin(1)
        -- Menambahkan efek partikel
        local particle = ParticleManager:CreateParticle(
            "particles/econ/items/nightstalker/nightstalker_ti10_silence/nightstalker_ti10_ambient_crimson.vpcf",
            PATTACH_POINT_FOLLOW,
            wearable
        )

        -- ParticleManager:SetParticleControlEnt(
        --     particle,
        --     0,
        --     wearable,
        --     PATTACH_POINT_FOLLOW,
        --     "attach_thumb_1_fx", -- cek lagi nama attachment di model arms ya
        --     wearable:GetAbsOrigin(),
        --     true
        -- )


    end
end

function EventListeners:EquipHeroAura(hero, diff)
    local aura = heroAura[diff]
    local ImmortalFX = ParticleManager:CreateParticle(aura.particle, PATTACH_POINT_FOLLOW, hero )
    hero:AddEffects(ImmortalFX)
end

function EventListeners:init(self)
    ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CHoldoutGameMode, "OnNPCSpawned" ), self )
    ListenToGameEvent( "player_reconnected", Dynamic_Wrap( CHoldoutGameMode, 'OnPlayerReconnected' ), self )
    ListenToGameEvent( "entity_killed", Dynamic_Wrap( CHoldoutGameMode, 'OnEntityKilled' ), self )
    ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( CHoldoutGameMode, "OnGameRulesStateChange" ), self )
    ListenToGameEvent("dota_player_pick_hero", Dynamic_Wrap( CHoldoutGameMode, "OnHeroPick"), self )
    ListenToGameEvent('player_connect_full', Dynamic_Wrap( CHoldoutGameMode, 'OnConnectFull'), self)
    ListenToGameEvent('player_reconnected', Dynamic_Wrap( CHoldoutGameMode, 'OnPlayerReconnected'), self)
    ListenToGameEvent('player_disconnect', Dynamic_Wrap( CHoldoutGameMode, 'OnPlayerDisconnected'), self)
    
    ListenToGameEvent('dota_player_reconnected', Dynamic_Wrap( CHoldoutGameMode, 'dota_player_reconnected'), self)
    ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(CHoldoutGameMode, 'OnAbilityUsed'), self)
    ListenToGameEvent( "dota_player_gained_level", Dynamic_Wrap(CHoldoutGameMode, "OnHeroLevelUp"), self)
    ListenToGameEvent( "player_chat", Dynamic_Wrap(CHoldoutGameMode, "OnPlayerChat"), self)
    ListenToGameEvent('game_start', Dynamic_Wrap(CHoldoutGameMode, 'OnGameStart'), self)
    ListenToGameEvent("dota_item_physical_destroyed", function(event)
        local playerID = event.PlayerID   -- Player ID yang menghancurkan item
        local itemName = event.itemname   -- Nama item yang dihancurkan
    
        -- Dapatkan hero berdasarkan PlayerID
        local hero = PlayerResource:GetSelectedHeroEntity(playerID)
        if hero then
            print("Hero " .. hero:GetUnitName() .. " destroyed item: " .. itemName)
            
            hero:SetCustomHealthLabel("Destroyed " .. itemName, 255, 0, 0)  -- Teks merah
        end
    end, nil)
end
