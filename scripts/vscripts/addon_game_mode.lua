--[[
Holdout Example

    Underscore prefix such as "_function()" denotes a local function and is used to improve readability

    Variable Prefix Examples
        "fl"    Float
        "n"     Int
        "v"     Table
        "b"     Boolean
]]

local function _init()
pcall(require, "encrypt")
PATCH_NAME = "EBFIMBAV11"
PATCH_DATE = "2025-11-11"



if ChatCollector == nil then
    ChatCollector = class({})
end

Kicks = Kicks or {}
Kicks.blacklist = {}
if PlayerResource then
    PlayerResource.disconnect = PlayerResource.disconnect or {}
    PlayerResource.abandoned_player_hero_selection = PlayerResource.abandoned_player_hero_selection or {}
end

-- Tabel untuk menyimpan semua pesan chat
ChatCollector.chatMessages = {}

DAMAGE_TYPES = {
        [0] = "DAMAGE_TYPE_NONE",
        [1] = "DAMAGE_TYPE_PHYSICAL",
        [2] = "DAMAGE_TYPE_MAGICAL",
        [4] = "DAMAGE_TYPE_PURE",
        [7] = "DAMAGE_TYPE_ALL",
        [8] = "DAMAGE_TYPE_HP_REMOVAL",
}
require("list_rewards")
require("heroAura")
require("cosmetics")
require("cosmetic_shop")
require("coupon_code")
require("pet")
require("lib/enc")
require("lua_item/simple_item")
require("lua_boss/boss_32_meteor")
require( "epic_boss_fight_game_round" )
require( "epic_boss_fight_game_spawner" )
require('lib.optionsmodule')
require( "libraries/Timers")
require("libraries/progressbars")
require("libraries/CustomBarriers")
require( "libraries/notifications")
require("libraries/json")
-- require("libraries/event_stream")
-- require( "libraries/protected_events")
require( "libraries/custom_chat")
require("libraries/synced_chat")
require("libraries/animations")
require( "libraries/vector_targeting" )
require("libraries/disable_help")

require("libraries/hero_sound_manager")

require("list_abilities")
require( "panoramaBridge")
require( "bossManager")

require("libraries/utility")
require("libraries/bug_report")
require( "ai/ai_core" )
require("ability_sound_pool")
require("meta/constant")
require("settings")
require("precache")
require("client.modifier")
require("generic_upgrades/generic_system")
if GenericUpgrades and GenericUpgrades.LinkModifiers then
    GenericUpgrades:LinkModifiers()
end
require("special_upgrades/special_upgrade_system")
require("lschecker")

require("core.holdout_gamemode")
require("ability_draft_compat")
require("ability_draft_config")
require("ability_draft_database")
GOLD_TALENT_EQUIVALENT = {}
UNIVERSAL_HERO_TALENTS = {}
require("ability_draft_mode")

-- require("events")

_G.player_hero_pool = {}
_G.player_ability_pool = {}
_G.all_ability_pool = {}
_G.betrayerList = {}
_G.user_id_kicked = {}
-- Actually make the game mode when we activate
function Activate()
    GameRules.holdOut = CHoldoutGameMode()
    GameRules.holdOut:InitGameMode()
end

function Precache(context)
    print("[Precache] Precaching...")
    if not Wearable then
        require("libraries.wearable")
    end

    if not Wearable.heroes then
        Wearable:Init()
    end

    Wearable:Precache("9449", context)
    Wearable:Precache("13811", context)
    
    -- Precache spirit bear model for summon abilities
    PrecacheModel("models/heroes/lone_druid/spirit_bear.vmdl", context)
    if SpecialUpgrades and SpecialUpgrades.Precache then
        SpecialUpgrades:Precache(context)
    end

    PrecacheInitiator:Init(context)
    print("[Precache] Precached.")
end


-- Item added to inventory filter

function CHoldoutGameMode:chat_time(event)
    local playerID = event.player_id
    local player = PlayerResource:GetPlayer(playerID)
    if not player then return end

    local currentTime = GameRules:GetDOTATime(false, true)
    local minutes = math.floor(currentTime / 60)
    local seconds = math.floor(currentTime % 60)
    local message = "> " .. minutes .. ":" .. (seconds < 10 and "0" or "") .. seconds

    Say(player, message, true)
end



function CHoldoutGameMode:Health_Bar_Command (event)
    local ID = event.pID
    local player = PlayerResource:GetPlayer(ID)
    if event.Enabled == 0 then
        player.HB = false
        player.Health_Bar_Open = false
    else
        player.HB = true
    end
end

function CHoldoutGameMode:NewGamePlus_StartVote()
    GameRules._NGPlusVotes = {}
    GameRules.forceEndTime = GameRules:GetGameTime() + 60
    for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
        GameRules._NGPlusVotes[hero:GetName()] = -1
    end
    CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", { active = true, endTime = GameRules.forceEndTime, votes = GameRules._NGPlusVotes })
end

function CHoldoutGameMode:NewGamePlus_ProcessVotes( event )
    local ID = event.pID
    local vote = event.vote
    local hero = PlayerResource:GetSelectedHeroName(ID)
    
    GameRules._NGPlusVotes[hero] = tonumber(vote);

    local yes = 0
    local no = 0
    local idk = 0
    for hero, vote in pairs( GameRules._NGPlusVotes ) do
        if vote == -1 then
            idk = idk + 1
        elseif vote == 0 then
            no = no + 1
        elseif vote == 1 then
            yes = yes + 1
        end
    end
    
    if yes >= no + idk then
        self:_EnterNG()
        self._nRoundNumber = 1
        self._flPrepTimeEnd = GameRules:GetGameTime() + 30
            GameRules.forceEndTime = nil
        CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", { active = false })
    elseif idk > 0 then
        CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", { votes = GameRules._NGPlusVotes })
    else -- everyone has voted
        if yes > 0 then -- at least one person wants NG+
            self:_EnterNG()
            self._nRoundNumber = 1
            self._flPrepTimeEnd = GameRules:GetGameTime() + 30
            GameRules.forceEndTime = nil
            CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", { active = false })
        else
            GameRules.forceEndTime = GameRules:GetGameTime() + 3
            CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", { endTime = GameRules.forceEndTime, votes = GameRules._NGPlusVotes })
        end
    end
end



function GetHeroDamageDone(hero)
    return hero.damageDone
end



function CHoldoutGameMode:_EnterNG()
    print ("Enter NG+ :D")
    self._NewGamePlus = true
    GameRules._NewGamePlus = true
    --new test?
    --[[Timers:CreateTimer(0.12,function()
            for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
                if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
                    if PlayerResource:HasSelectedHero( nPlayerID ) then
                        local player = PlayerResource:GetPlayer(nPlayerID)
                        --CustomGameEventManager:Send_ServerToPlayer(player,"Update_Asura_Core", {core = player.Asura_Core})
                    end
                end
            end
            return 0.12
        end)]]
    --CustomGameEventManager:Send_ServerToAllClients("Display_Asura_Core", {})
    --CustomGameEventManager:Send_ServerToAllClients("Display_Shop", {})
end


addedAbilities = {}

local NORMAL_DEFAULT_DIFFICULTY_CONFIG = {
    class = "S1",
    dmg_reduction_pct = 10,
    cdr = 20,
    bonus_mr = 5,
    bonus_ms = 30,
    spell_amp = 155,
    bonus_armor = 5,
    bonus_mmr = 220,
    lose_mmr = -50,
}

local ABILITY_DRAFT_DEFAULT_DIFFICULTY_CONFIG = {
    class = "S1",
    dmg_reduction_pct = 10,
    cdr = 10,
    bonus_mr = 1,
    bonus_ms = 30,
    spell_amp = 30,
    bonus_armor = 5,
    bonus_mmr = 220,
    lose_mmr = -50,
}

local NORMAL_ALLOWED_DIFFICULTIES = {
    S1 = true,
    S2 = true,
    S3 = true,
    S4 = true,
    S5 = true,
}

local GAME_STATS_NETTABLE_INTERVAL = 1.0


function randomAbility(hero, index)
    local randomedAbility = GetRandomAbility()
        
        
    if not hero:HasAbility(randomedAbility) then

        -- juggernaut blade dance ga boleh sama multicast
        local addedAbility = hero:AddAbility(randomedAbility)
        -- print(addedAbility:GetAbilityIndex())
        -- hero:SetAbilityByIndex(addedAbility, index)
        
    end
end


function CHoldoutGameMode:choose_difficulty(event)
    local mapName = GetMapName() or ""
    local isAbilityDraftMap = mapName == "epic_boss_fight_ad" or string.find(mapName, "_ad") ~= nil

    if isAbilityDraftMap then
        event.difficulty = 16
        event.config = ABILITY_DRAFT_DEFAULT_DIFFICULTY_CONFIG
    elseif mapName == "epic_boss_fight_normal" then
        local config = event.config or {}
        if not NORMAL_ALLOWED_DIFFICULTIES[config.class] then
            event.difficulty = 16
            event.config = NORMAL_DEFAULT_DIFFICULTY_CONFIG
        end
    end

    DeepPrint(event)
    CustomNetTables:SetTableValue('game_difficulty', 'all', { difficulty = event })
    CustomNetTables:SetTableValue('choosen_difficulty', "saved", event.config)
end

function CHoldoutGameMode:vote_end(event)
    CustomNetTables:SetTableValue('game_difficulty', 'all', event)
end

function CHoldoutGameMode:customPing(event)
    local sourcePlayerID = event.player_id
    local sourceHeroName = PlayerResource:GetSelectedHeroEntity(sourcePlayerID):GetUnitName()
    local target = EntIndexToHScript(event.target_entity)
    local modifier_name = event.modifier_name
    local localized = event.loc_result

    -- Get remaining time if any
    local modifier = target:FindModifierByName(modifier_name)
    local remaining_time = 0
    if modifier then
        remaining_time = modifier:GetRemainingTime()
        print("Remaining time: " .. remaining_time)
    end


    -- Construct the ping message

    -- Determine if the modifier is a debuff or buff
    local is_debuff = modifier:IsDebuff()
    local color = is_debuff and "#ff0000" or "#42f551"

    local ping_message = "Affected by: " .. "<font color='" .. color .."'>" .. localized .. "</font>"
    local stack_count = modifier:GetStackCount()
    if stack_count > 0 then
        ping_message = ping_message .. " (Stacks: " .. stack_count .. ")"
    end
    if remaining_time >= 1 then
        ping_message = ping_message .. " (" .. math.floor(remaining_time) .. " seconds remaining)"
    end

    print(modifier_name)
    print(ping_message)
    -- Create the hero icon image
    local hero_icon = "<img class=\"InlineImage HeroIcon\" src=\"file://{images}/heroes/" .. sourceHeroName .. ".png\" /><img src='s2r://panorama/images/control_icons/chat_wheel_icon_png.vtex' class='ChatWheelIcon'/> <img class=\"InlineImage HeroIcon\" src=\"file://{images}/heroes/" .. target:GetUnitName() .. ".png\" />"

    local playerName = PlayerResource:GetPlayerName(sourcePlayerID)
    local steamid = tostring(PlayerResource:GetSteamID(sourcePlayerID))
    
    -- Send the custom message
    GameRules:SendCustomMessage(hero_icon .. " " .. ping_message, 0, 0)

    table.insert(playerChats, {
        steamid = steamid,
        hero_name = PlayerResource:GetSelectedHeroName(sourcePlayerID),
        player_id = sourcePlayerID,
        player_name = playerName,
        gametime = math.floor(GameRules:GetDOTATime(false, false)),
        message = hero_icon .. " " .. ping_message
    })
end

function CHoldoutGameMode:Boss_Master (event)
    local ID = event.pID
    local commandname = event.Command
    local player = PlayerResource:GetPlayer(ID)
    if commandname == "magic_immunity_1" then

    elseif commandname == "magic_immunity_2" then

    elseif commandname == "damage_immunity" then

    elseif commandname == "double_damage" then

    elseif commandname == "quad_damage" then

    end

end


-- Read and assign configurable keyvalues if applicable
function CHoldoutGameMode:_ReadGameConfiguration()
    local kv = LoadKeyValues( "scripts/maps/" .. GetMapName() .. ".txt" )
    kv = kv or {} -- Handle the case where there is not keyvalues file
    
    GameRules.BossKV = LoadKeyValues( "scripts/npc/units/npc_boss_units.txt" )
    print( GameRules.BossKV, "loaded bossKV" )

    print( GameRules.BossKV, "loaded bossKV" )

    -- Initialize aura type cache for 3-round cycles
    GameRules._auraTypeByRound = {}

    self._bAlwaysShowPlayerGold = kv.AlwaysShowPlayerGold or false
    self._bRestoreHPAfterRound = kv.RestoreHPAfterRound or false
    self._bRestoreMPAfterRound = kv.RestoreMPAfterRound or false
    self._bRewardForTowersStanding = kv.RewardForTowersStanding or false
    self._bUseReactiveDifficulty = kv.UseReactiveDifficulty or false

    self._flPrepTimeBetweenRounds = tonumber( kv.PrepTimeBetweenRounds or 0 )
    self._flItemExpireTime = tonumber( kv.ItemExpireTime or 10.0 )

    self:_ReadRandomSpawnsConfiguration( kv["RandomSpawns"] )
    self:_ReadLootItemDropsConfiguration( kv["ItemDrops"] )
    self:_ReadRoundConfigurations( kv )
    
    -- local genericKV = LoadKeyValues( "addoninfo.txt" )
    -- self._MaxPlayers = genericKV[GetMapName()].MaxPlayers
    
    if GetMapName() == "epic_boss_fight_normal" then
        self._MaxPlayers = 5
    elseif GetMapName() == "epic_boss_fight_nightmare" then
        self._MaxPlayers = 10
    else
        self._MaxPlayers = 7
    end
end


function CHoldoutGameMode:player_is_banned(data)
    local playerID = data.player_id
    if not PlayerResource:IsValidPlayerID(playerID) then return end

    -- Delay 5 detik sebelum game selesai
    GameRules:GetGameModeEntity():SetThink(function()
        GameRules:SetGameWinner(DOTA_TEAM_BADGUYS) -- atau GOODGUYS sesuai preferensi
    end, 5.0)
end


function CHoldoutGameMode:ChooseRandomSpawnInfo()
    if #self._vRandomSpawnsList == 0 then
        error( "Attempt to choose a random spawn, but no random spawns are specified in the data." )
        return nil
    end
    return self._vRandomSpawnsList[ RandomInt( 1, #self._vRandomSpawnsList ) ]
end

-- Verify valid spawns are defined and build a table with them from the keyvalues file
function CHoldoutGameMode:_ReadRandomSpawnsConfiguration( kvSpawns )
    self._vRandomSpawnsList = {}
    if type( kvSpawns ) ~= "table" then
        return
    end
    for _,sp in pairs( kvSpawns ) do            -- Note "_" used as a shortcut to create a temporary throwaway variable
        table.insert( self._vRandomSpawnsList, {
            szSpawnerName = sp.SpawnerName or "",
            szFirstWaypoint = sp.Waypoint or ""
        } )
    end
end


-- If random drops are defined read in that data
function CHoldoutGameMode:_ReadLootItemDropsConfiguration( kvLootDrops )
    self._vLootItemDropsList = {}
    if type( kvLootDrops ) ~= "table" then
        return
    end
    for _,lootItem in pairs( kvLootDrops ) do
        table.insert( self._vLootItemDropsList, {
            szItemName = lootItem.Item or "",
            nChance = tonumber( lootItem.Chance or 0 )
        })
    end
end


-- Set number of rounds without requiring index in text file
function CHoldoutGameMode:_ReadRoundConfigurations( kv )
    self._vRounds = {}
    while true do
        local szRoundName = string.format("Round%d", #self._vRounds + 1 )
        local kvRoundData = kv[ szRoundName ]
        if kvRoundData == nil then
            return
        end
        local roundObj = CHoldoutGameRound()
        roundObj:ReadConfiguration( kvRoundData, self, #self._vRounds + 1 )
        table.insert( self._vRounds, roundObj )
    end
end



function CHoldoutGameMode:AddLife(life)
    local messageinfo = {
        message = life.." life has been gained",
        duration = 5
        }
    FireGameEvent("show_center_message",messageinfo)
    Life._life = Life._life + life
    GameRules._live = Life._life
    CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {life = Life._life})
end


function CHoldoutGameMode:_regenlifecheck()
    if not self._roundsRegened[self._nRoundNumber] and self._nRoundNumber % GameRules._bonusLifeRoundDivider == 0 then
        self._roundsRegened[self._nRoundNumber] = true
        self:AddLife(1)
    end
    if self._regenNG == false and self._NewGamePlus == true then
        self._regenNG = true

        local messageinfo = {
        message = "Five life has been gained , Welcome to NewGame + .Mouahahaha !",
        duration = 10
        }
        FireGameEvent("show_center_message",messageinfo)   
        self._checkpoint = 1
        
        if GetMapName() == "epic_boss_fight_normal" then
            Life._life = 4
            Life._MaxLife = 4
        elseif GetMapName() == "epic_boss_fight_hard" then 
            Life._life = 2
            Life._MaxLife = 2
        elseif GetMapName() == "epic_boss_fight_impossible" then
            Life._life = 2
            Life._MaxLife = 2
        elseif GetMapName() == "epic_boss_fight_challenger" then
             Life._life = 1
            Life._MaxLife = 1
        elseif GetMapName() == "epic_boss_fight_nightmare" then
            Life._life = 1
           Life._MaxLife = 1
        elseif GetMapName() == "epic_boss_fight_purgatory" then
            Life._life = 1
           Life._MaxLife = 1   
        end
        
        GameRules._live = Life._life
        --Life:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Life._life )
        --Life:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, Life._MaxLife )
        -- value on the bar
        --LifeBar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Life._life )
        --LifeBar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, Life._MaxLife )
    end
end

function CHoldoutGameMode:vote_Round (event)
    local ID = event.pID
    local vote = event.vote
    local player = PlayerResource:GetPlayer(ID)
    
    if player~= nil then
        if vote == 1 then
            GameRules.voteRound_Yes = GameRules.voteRound_Yes + 1
            GameRules.voteRound_No = GameRules.voteRound_No - 1

            local event_data =
            {
                No = GameRules.voteRound_No,
                Yes = GameRules.voteRound_Yes,
            }
            CustomGameEventManager:Send_ServerToAllClients("RoundVoteResults", event_data)
        end
    end
end

function CHoldoutGameMode:spawn_unit( place , unitname , radius , unit_number)
    if radius == nil then radius = 400 end
    if core == nil then core = false end
    if unit_number == nil then unit_number = 1 end
    for i = 0, unit_number-1 do
        print   ("spawn unit : "..unitname)
        PrecacheUnitByNameAsync( unitname, function()
        local unit = CreateUnitByName( unitname ,place + RandomVector(RandomInt(radius,radius)), true, nil, nil, DOTA_TEAM_NEUTRALS )
            Timers:CreateTimer(0.03,function()
            end)
        end,
        nil)
    end
end

function CHoldoutGameMode:OnThink()
    if GameRules:State_Get() <= DOTA_GAMERULES_STATE_HERO_SELECTION then
        for player_id = 0, PlayerResource:GetPlayerCount() - 1 do
            if PlayerResource:GetConnectionState(player_id) == DOTA_CONNECTION_STATE_ABANDONED and GameRules:GetGameTime() <= 60 then
                PlayerResource.abandoned_player_hero_selection[player_id] = true
            
                local hero = PlayerResource:GetSelectedHeroEntity(player_id)
                if hero and not hero:HasModifier("modifier_player_abandon") then
                    hero:AddNewModifier(hero, nil, "modifier_player_abandon", {})
                end
            end
            
        end
    end
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_PRE_GAME and GameRules:State_Get() < DOTA_GAMERULES_STATE_POST_GAME then
        self._lastGameStatsNetTableUpdate = self._lastGameStatsNetTableUpdate or -GAME_STATS_NETTABLE_INTERVAL
        self._lastGameStatsNetTablePayloads = self._lastGameStatsNetTablePayloads or {}

        local now = GameRules:GetGameTime()
        local shouldUpdateGameStats = now - self._lastGameStatsNetTableUpdate >= GAME_STATS_NETTABLE_INTERVAL

        if shouldUpdateGameStats then
            self._lastGameStatsNetTableUpdate = now

        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
            if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
                if PlayerResource:HasSelectedHero( nPlayerID ) then
                    local heroToAssign = PlayerResource:GetSelectedHeroEntity( nPlayerID )
                    if heroToAssign then
                        -- Get guild info for the player
                        local guildData = CustomNetTables:GetTableValue("guild", tostring(nPlayerID)) or {has_guild = false}
                        local guildTag = ""
                        if guildData.has_guild and guildData.guild_tag then
                            guildTag = guildData.guild_tag
                        end

                        local payload = {
                            damage_dealt = heroToAssign.damage_dealt_ingame,
                            damage_taken = heroToAssign.damage_taken_ingame,
                            damage_healed = heroToAssign.damage_healed_ingame,
                            last_damage_dealt = heroToAssign.last_damage_dealt,
                            guild = guildTag
                        }
                        local payloadKey = tostring(payload.damage_dealt) .. "|" ..
                            tostring(payload.damage_taken) .. "|" ..
                            tostring(payload.damage_healed) .. "|" ..
                            tostring(payload.last_damage_dealt) .. "|" ..
                            tostring(payload.guild)

                        if self._lastGameStatsNetTablePayloads[nPlayerID] ~= payloadKey then
                            self._lastGameStatsNetTablePayloads[nPlayerID] = payloadKey
                            CustomNetTables:SetTableValue("game_stats", tostring( nPlayerID ), payload)
                        end
                    end
                end
            end
        end
        end
    end
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then      
        local ThinkDefeat = function()
            self:_CheckForDefeat()
        end
        status, err, ret = xpcall(ThinkDefeat, function(msg) return msg end, self )
        if not status  and not self.gameHasBeenBroken then
            self.gameHasBeenBroken = true
            Say(nil, string.format("Error occurred while checking for defeat: %s", tostring(err)), false)
            BugReporter:SendReport(err, "ThinkDefeat")
        end
        
        local ThinkNeutrals = function()
            self:_ManageNeutralScaling()
        end
        status, err, ret = xpcall(ThinkNeutrals, function(msg) return msg end, self )
        if not status  and not self.gameHasBeenBroken then
            self.gameHasBeenBroken = true
            Say(nil, string.format("Error occurred while managing neutral scaling: %s", tostring(err)), false)
            BugReporter:SendReport(err, "ThinkNeutrals")
        end
        
        local ThinkLives = function()
            self:_regenlifecheck()
        end
        status, err, ret = xpcall(ThinkLives, function(msg) return msg end, self )
        if not status  and not self.gameHasBeenBroken then
            self.gameHasBeenBroken = true
            Say(nil, string.format("Error occurred while checking life regeneration: %s", tostring(err)), false)
            BugReporter:SendReport(err, "ThinkLives")
        end
        
        local ThinkGeneric = function()
            ResolveNPCPositions( Vector( 0,0 ), 9999 )
            for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
                if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
                    if PlayerResource:HasSelectedHero( nPlayerID ) and PlayerResource:GetConnectionState(nPlayerID) == DOTA_CONNECTION_STATE_DISCONNECTED  then -- people that didn't manage to connect in time etc
                        PlayerResource.disconnect[nPlayerID] = PlayerResource.disconnect[nPlayerID] or GameRules:GetGameTime()
                    else
                        PlayerResource.disconnect[nPlayerID] = nil
                    end
                end
            end
            
            if self._flPrepTimeEnd ~= nil then
                self:_ThinkPrepTime()
            elseif self._currentRound ~= nil then
                self._currentRound:Think()
                if self._currentRound:IsFinished() then
                    self._currentRound:End(true)
                    self._currentRound = nil
                    -- Heal all players
                    self:_RefreshPlayers(true)
                    
                    self._nRoundNumber = self._nRoundNumber + 1
                    simple_item:SetRoundNumer(self._nRoundNumber)
                    boss_meteor:SetRoundNumer(self._nRoundNumber)
                    GameRules._roundnumber = self._nRoundNumber
                    
                    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
                        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
                            if PlayerResource:HasSelectedHero( nPlayerID ) then
                                PlayerResource:SetCustomBuybackCost(nPlayerID, GameRules._roundnumber * 100)
                            end
                        end
                    end
                    
                    -- if math.random(1,25) == 25 then
                        -- self:spawn_unit( Vector(0,0,0) , "npc_dota_treasure" , 2000)
                        -- for _,unit in pairs ( Entities:FindAllByModel( "models/courier/flopjaw/flopjaw.vmdl")) do
                            -- Waypoint = Entities:FindByName( nil, "path_invader1_1" )
                            -- unit:SetInitialGoalEntity(Waypoint)
                            -- Timers:CreateTimer(15,function()
                                -- unit:ForceKill(true)
                            -- end)
                        -- end
                        -- self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds + 15

                    -- end

                    local tc = function ()
                        local mapName = GetMapName()
                        local presetCounts = {
                            epic_boss_fight_purgatory = 10,
                            epic_boss_fight_soul = 10,
                            epic_boss_fight_god = 10,
                        }

                        if presetCounts[mapName] then
                            return presetCounts[mapName]
                        end

                        local counter = 0
                        for i = 0, PlayerResource:GetPlayerCount() - 1 do
                            if PlayerResource:IsValidPlayerID(i) and PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
                                counter = counter + 1
                            end
                        end

                        return counter
                    end
                    
                    if self._nRoundNumber > #self._vRounds then
                        if not self._NewGamePlus and not GameRules.forceEndTime then
                            self:NewGamePlus_StartVote()
                            local eventConfig = CustomNetTables:GetTableValue('choosen_difficulty', 'saved')
                            local classDiff = eventConfig.class

                            for _, hero in ipairs( HeroList:GetRealHeroes() ) do
                                if hero:GetPlayerOwner() then
                                    self:RegisterStatsForHero( hero, true )
                                end
                                local playerID = hero:GetPlayerID()
                                local won = true
                                if GetMapName() == "epic_boss_fight_purgatory" and classDiff == "S5" and tc() >= 4 then
                                    local player = PlayerResource:GetPlayer(playerID)
                                    if player then
                                        -- Gunakan empty table sebagai payload jika tidak ada data
                                        CustomGameEventManager:Send_ServerToPlayer(player, "show_reward_popup", purgatory_reward)
                                        print("[Reward] Event dikirim ke player "..playerID)
                                    
                                    end
                                end
                                self:RegisterStatsForPlayer( playerID, won )

                                -- Send guild XP if player has a guild
                                if won then
                                    self:SendGuildXP( playerID, hero )
                                end
                            end

                            self:RegisterStatsForRound( "won" )
                        elseif self._NewGamePlus then
                            GameRules:SetCustomVictoryMessage ("Congratulations!")
                            GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
                            GameRules._finish = true
                        end
                    else
                        self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds
                        
                        --GameRules.voteRound_No = PlayerResource:GetTeamPlayerCount()  --tester
                        GameRules.voteRound_No = self:TeamCount()
                        GameRules.voteRound_Yes = 0                       

                        CustomGameEventManager:Send_ServerToAllClients("Display_RoundVote", {})
                        local event_data =
                        {
                            No = GameRules.voteRound_No,
                            Yes = GameRules.voteRound_Yes,
                        }
                        CustomGameEventManager:Send_ServerToAllClients("RoundVoteResults", event_data)
                    
                        Timers:CreateTimer(1,function()
                            --if GameRules.voteRound_Yes == PlayerResource:GetTeamPlayerCount() then --tester
                            if GameRules.voteRound_Yes == self:TeamCount() then 
                                CustomGameEventManager:Send_ServerToAllClients("Close_RoundVote", {})
                                if self._flPrepTimeEnd~= nil then
                                    self._flPrepTimeEnd = 0
                                end
                            else
                                return 1
                            end
                        end)
                    end
                end
            elseif ( GameRules.forceEndTime and GameRules.forceEndTime < GameRules:GetGameTime() ) then
                local yes = 0
                local no = 0
                local idk = 0
                for hero, vote in pairs( GameRules._NGPlusVotes ) do
                    if vote == -1 then
                        idk = idk + 1
                    elseif vote == 0 then
                        no = no + 1
                    elseif vote == 1 then
                        yes = yes + 1
                    end
                end
                
                if yes > 0 then
                    self:_EnterNG()
                    self._nRoundNumber = 1
                    self._flPrepTimeEnd = GameRules:GetGameTime() + 30
                    GameRules.forceEndTime = nil
                    CustomGameEventManager:Send_ServerToAllClients("epic_boss_fight_ng_vote_update", { active = false })
                else
                    GameRules:SetCustomVictoryMessage ("Congratulations!")
                    GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
                    GameRules._finish = true
                end
            end
        end
        status, err, ret = xpcall(ThinkGeneric, function(msg) return msg end, self )
        if not status  and not self.gameHasBeenBroken then
            self.gameHasBeenBroken = true
            Say(nil, string.format("game think: %s", tostring(err)), false)
            BugReporter:SendReport(err, "ThinkGeneric")
        end
    elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then     -- Safe guard catching any state that may exist beyond DOTA_GAMERULES_STATE_POST_GAME
        return nil
    end
    return 0.5
end

function CHoldoutGameMode:RegisterStatsForHero( hero, bWon )
    if not IsDedicatedServer() or IsInToolsMode() or GameRules:IsCheatMode() then return end
    if not (
        GetMapName() == "epic_boss_fight_nightmare" or GetMapName() == "epic_boss_fight_challenger" or GetMapName() == "epic_boss_fight_purgatory"
    ) then return end
    
    local AUTH_KEY = GetAuthKey()
    local SERVER_LOCATION = GetServerLocation()
    local heroName = hero:GetUnitName()
    
    self.statsSentForHero = self.statsSentForHero or {}
    if self.statsSentForHero[hero] then return end
    self.statsSentForHero[hero] = true

    
    local packageLocation = SERVER_LOCATION..AUTH_KEY.."/heroes/"..heroName..'.json'
    local getRequest = CreateHTTPRequestScriptVM( "GET", packageLocation)
    -- hero stats
    getRequest:Send( function( result )
        local putData = {}
        local wins = 0
        putData.wins = wins
        putData.plays = 1
        
        local decoded = {}
        if tostring(result.Body) ~= 'null' then
            decoded = json.decode(result.Body)
        end
        wins = (decoded.wins or 0)
        if bWon then
            wins = wins + 1
        end
        
        -- SCEPTER
        putData.scepter = {}
        decoded.scepter = decoded.scepter or {}
        putData.scepter.plays = (decoded.scepter.plays or 0)
        putData.scepter.wins = (decoded.scepter.wins or 0)
        if hero:HasScepter() then
            putData.scepter.plays = putData.scepter.plays + 1
            if bWon then
                putData.scepter.wins = putData.scepter.wins + 1
            end
        end
        
        -- SHARD
        putData.shard = {}
        decoded.shard = decoded.shard or {}
        putData.shard.plays = (decoded.shard.plays or 0)
        putData.shard.wins = (decoded.shard.wins or 0)
        if hero:HasShard() then
            putData.shard.plays = putData.shard.plays + 1
            if bWon then
                putData.shard.wins = putData.shard.wins + 1
            end
        end
        
        putData.plays = (decoded.plays or 0) + 1
        putData.wins = wins
        
        -- MMR
        putData.mmr = decoded.mmr or 3000
        putData.mmr = math.floor( CalculateMMRChangeForPlayer( GetMapName(), putData.mmr, bWon ) + 0.5 )
        
        local encoded = json.encode(putData)
        local putRequest = CreateHTTPRequestScriptVM( "PUT", packageLocation)
        putRequest:SetHTTPRequestRawPostBody("application/json", encoded)
        putRequest:Send( function( result ) end )
    end )
end

function CHoldoutGameMode:SendGuildXP( playerID, hero )
    if not IsDedicatedServer() or IsInToolsMode() or GameRules:IsCheatMode() then return end

    -- Check if player has a guild
    local guildData = CustomNetTables:GetTableValue("guild", tostring(playerID))
    if not guildData or not guildData.has_guild then
        print(string.format("[Guild XP] Player %d has no guild, skipping XP send", playerID))
        return
    end

    -- Get player stats
    local statsData = CustomNetTables:GetTableValue("game_stats", tostring(playerID))
    if not statsData then
        print(string.format("[Guild XP] No stats data for player %d", playerID))
        return
    end

    -- Calculate guild XP
    local basexp = 2000
    local damageDealt = hero.damage_dealt_ingame or 0
    local damageHealed = hero.damage_healed_ingame or 0

    local factorDivider = 1000000
    local expFromDamage = damageDealt * 0.65 / factorDivider
    local expFromHealing = damageHealed * 0.35
    local totalXP = math.floor(basexp + expFromDamage + expFromHealing)

    print(string.format("[Guild XP] Player %d - Damage: %d, Healing: %d, Total XP: %d", playerID, damageDealt, damageHealed, totalXP))

    -- Send XP to guild API
    local statSettings = LoadKeyValues("scripts/vscripts/statcollection/settings.kv")
    local guildXPUrl = "https://ebfimba.stelincore.com/api/guilds/exp/update"
    local guildXPRequest = CreateHTTPRequestScriptVM("POST", guildXPUrl)

    -- Set Bearer token for authentication
    local bearerToken = "LsJyrrcEPMzG1pGtVTfmT8WO8iQ7CfcjqJZYVez6VVhi0tlu6XMhboxO4T81cKNU"
    guildXPRequest:SetHTTPRequestHeaderValue("Authorization", "Bearer " .. bearerToken)
    guildXPRequest:SetHTTPRequestHeaderValue("Content-Type", "application/json")

    -- Prepare request body
    local steamID = tostring(PlayerResource:GetSteamID(playerID))
    local requestData = {
        steam_id = steamID,
        exp_amount = totalXP
    }

    guildXPRequest:SetHTTPRequestRawPostBody("application/json", json.encode(requestData))
    guildXPRequest:Send(function(result)
        if result.StatusCode == 200 then
            local guildDisplay = guildData.guild_name or guildData.guild_tag or "Unknown"
            local guildTag = guildData.guild_tag or ""
            print(string.format("[Guild XP] Successfully sent %d XP to guild for player %s (Guild: %s [%s])", totalXP, steamID, guildDisplay, guildTag))
        else
            print(string.format("[Guild XP] Failed to send XP for player %s: HTTP %d - %s", steamID, result.StatusCode, result.Body))
        end
    end)
end

function CHoldoutGameMode:_Connection_states()
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
        local player_connection_state = PlayerResource:GetConnectionState(nPlayerID)
        local hero = GetAssignedHero(nPlayerID)
        if hero~=nil and player_connection_state == 4 and hero.Abandonned ~= true then
            hero.Abandonned = true
            for _,unit in pairs ( Entities:FindAllByName( "npc_dota_hero*")) do
                if self._NewGamePlus == false then
                    local totalgold = unit:GetGold() + (self._nRoundNumber^1.3)*100
                else
                    local totalgold = unit:GetGold() + ((36+self._nRoundNumber)^1.3)*100
                end
                unit:SetGold(0 , false)
                unit:SetGold(totalgold, true)
            end
            for itemSlot = 0, 5, 1 do
                local Item = hero:GetItemInSlot( itemSlot )
                hero:RemoveItem(Item)
            end
            Timers:CreateTimer(0.1,function()
                hero:SetGold(0, true)
                return 0.5
            end)
        end
    end
end

local REVENANT_EBF_TOGGLE_ITEMS = {
    item_revenant_ebf = true,
    item_revenant_ebf_2 = true,
    item_revenant_ebf_3 = true,
    item_revenant_ebf_4 = true,
    item_revenant_ebf_5 = true,
    item_revenant_ebf_6 = true,
}

local function SnapshotRevenantEBFToggles(hero)
    local toggledItems = {}

    if hero == nil then
        return toggledItems
    end

    for itemSlot = 0, 5 do
        local item = hero:GetItemInSlot(itemSlot)
        if item ~= nil and REVENANT_EBF_TOGGLE_ITEMS[item:GetAbilityName()] and item:GetToggleState() then
            table.insert(toggledItems, item)
        end
    end

    return toggledItems
end

local function RestoreRevenantEBFToggles(hero, toggledItems)
    if hero == nil or toggledItems == nil or #toggledItems == 0 then
        return
    end

    Timers:CreateTimer(FrameTime(), function()
        if not IsEntitySafe(hero) then
            return
        end

        for _, item in pairs(toggledItems) do
            if IsEntitySafe(item) and item:GetCaster() == hero and item:GetItemSlot() >= 0 and item:GetItemSlot() <= 5 then
                if not item:GetToggleState() then
                    item:ToggleAbility()
                elseif not hero:HasModifier("modifier_item_revenant_ebf_active") then
                    hero:AddNewModifier(hero, item, "modifier_item_revenant_ebf_active", {})
                end
            end
        end
    end)
end


function CHoldoutGameMode:_RefreshPlayers(bWon)
    local eventConfig = CustomNetTables:GetTableValue('choosen_difficulty', 'saved')
    local diff = eventConfig.class
    
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
            if PlayerResource:HasSelectedHero( nPlayerID ) then
                local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
                local mapName = GetMapName()

                if bWon and (mapName == "epic_boss_fight_normal" or mapName == "epic_boss_fight_nightmare" or mapName == "epic_boss_fight_purgatory" or mapName == "epic_boss_fight_soul" or mapName == "epic_boss_fight_god" or mapName == "epic_boss_fight_ad") then
                    if diff == "S1" or diff == "S2" or diff == "S3" or diff == "S4" or diff == "S5" then
                        local heroName = hero:GetUnitName()
                        if mapName == "epic_boss_fight_ad" or MINOR_ABILITY_UPGRADES[heroName] ~= nil then
                            showRewards(hero)
                        end
                    end
                end
                
                if hero ~=nil then
                    local revenantEBFToggles = SnapshotRevenantEBFToggles(hero)
                    hero:Dispel( hero, true )
                    if hero:HasModifier("modifier_reapers_scythe_kill") then hero:RemoveModifierByName("modifier_reapers_scythe_kill") end
                    if hero:IsMoving() or hero:IsChanneling() or hero:IsInvulnerable() or hero:IsOutOfGame() then
                        hero:Heal( hero:GetMaxHealth(), nil )
                        hero:GiveMana( hero:GetMaxMana() )
                        hero:Dispel( hero, true )
                        if hero:HasModifier("modifier_reapers_scythe_kill") then hero:RemoveModifierByName("modifier_reapers_scythe_kill") end
                    else
                        local ogPos = hero:GetAbsOrigin()
                        hero:RespawnHero(false, false)
                        hero:SetAbsOrigin(ogPos)
                        hero:RemoveModifierByName( "modifier_fountain_invulnerability" )
                    end
                    
                    
                    if bWon ~= nil then
                        local hBottle = hero:FindItemInInventory("item_bottle" )
                        if hBottle then
                            local maxCharges = hBottle:GetSpecialValueFor( "max_charges" )
                            if bWon then
                                hBottle:SetCurrentCharges( math.min( hBottle:GetCurrentCharges() + 1, maxCharges ) )
                            else
                                hBottle:SetCurrentCharges( maxCharges )
                            end
                        end
                    end

                    RestoreRevenantEBFToggles(hero, revenantEBFToggles)
                end
            end
        end
    end
end

function CHoldoutGameMode:_ManageNeutralScaling()
    for campType, camps in pairs( GameRules.neutralCamps ) do
        for _, camp in ipairs( camps ) do
            local newNeutralsSpawned = false
            for _, unit in ipairs( FindUnitsInRadius(DOTA_TEAM_NEUTRALS, camp:GetAbsOrigin(), nil, 128, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false) ) do
                if unit:IsNeutralUnitType() and not unit:HasAbility( "neutral_upgrade" ) then
                    if not newNeutralsSpawned then
                        camp.neutralsCreepsSpawnedThisRound = camp.neutralsCreepsSpawnedThisRound or {}
                        table.insert( camp.neutralsCreepsSpawnedThisRound, {} ) 
                        newNeutralsSpawned = true
                    end
                    local upgrader = unit:AddAbility( "neutral_upgrade" )
                    if camp:IsTouching( unit ) then
                        table.insert( camp.neutralsCreepsSpawnedThisRound[#camp.neutralsCreepsSpawnedThisRound], unit )
                        if #camp.neutralsCreepsSpawnedThisRound > 1 then
                            unit:AddNewModifier( unit, nil, "modifier_neutrals_ancestors_rage", {} ):SetStackCount(#camp.neutralsCreepsSpawnedThisRound-1)
                        end
                        if campType == "easy"  then
                            unit:SetCoreHealth( unit:GetMaxHealth() + 50 )
                            unit:SetAverageBaseDamage( unit:GetAverageBaseDamage() + 1, unit:GetAverageBaseDamageVariance() )
                            upgrader:SetLevel(1)
                        elseif campType == "medium" then
                            unit:SetCoreHealth( unit:GetMaxHealth() + 200 )
                            unit:SetAverageBaseDamage( unit:GetAverageBaseDamage() + 3, unit:GetAverageBaseDamageVariance() )
                            upgrader:SetLevel(2)
                        elseif campType == "hard" then
                            unit:SetCoreHealth( unit:GetMaxHealth() + 350 )
                            unit:SetAverageBaseDamage( unit:GetAverageBaseDamage() + 6, unit:GetAverageBaseDamageVariance() )
                            upgrader:SetLevel(3)
                        elseif campType == "ancient" then 
                            unit:SetCoreHealth( unit:GetMaxHealth() + 500 )
                            unit:SetAverageBaseDamage( unit:GetAverageBaseDamage() + 10, unit:GetAverageBaseDamageVariance() )
                            upgrader:SetLevel(4)
                        end
                    end
                end
            end
        end
    end
end

function CHoldoutGameMode:_CheckForDefeat()
    if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS or self._GameHasFinished then
        return
    end
    local AllRPlayersDead = true
    local PlayerNumberRadiant = 0
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
            local isActivePlayer = self:IsPlayerActiveForRound(nPlayerID)
            if isActivePlayer then
                PlayerNumberRadiant = PlayerNumberRadiant + 1
            end
            if not PlayerResource:HasSelectedHero( nPlayerID ) and self._nRoundNumber == 1 and self._currentRound == nil then
                if isActivePlayer then
                    AllRPlayersDead = false
                end
            elseif PlayerResource:HasSelectedHero( nPlayerID ) then
                local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
                if PlayerResource:GetConnectionState( nPlayerID ) == DOTA_CONNECTION_STATE_ABANDONED
                or ( PlayerResource:GetConnectionState( nPlayerID ) == DOTA_CONNECTION_STATE_DISCONNECTED 
                and PlayerResource.disconnect[nPlayerID] and PlayerResource.disconnect[nPlayerID] + 5*60 <= GameRules:GetGameTime() ) then
                    self:RegisterStatsForPlayer( nPlayerID, false, true )
                end
                if isActivePlayer and hero and hero:NotDead() then
                    AllRPlayersDead = false
                end
            end
        end
    end

    if AllRPlayersDead then -- 3s timer before proceeding
        if not self.waitingToEnd then
            self.waitingToEnd = GameRules:GetGameTime() + 3
            return
        elseif GameRules:GetGameTime() < self.waitingToEnd then
            return
        end
    else
        self.waitingToEnd = nil
    end
    
    if PlayerNumberRadiant == 0 or Life._life == 0 then
        self:_OnLose()
    end

    if AllRPlayersDead and PlayerNumberRadiant>0 then
        if self._check_dead == false then
            self._check_check_dead = false
            Timers:CreateTimer(2.0,function()
                if self._check_check_dead == false then
                    self._check_dead = true
                else
                    self._check_check_dead = false
                end
            end)
        end
        if self._check_dead == true and Life._life > 0 then
            if Life._life <= 1 then
                self:_OnLose()
                return
            end

            if self._currentRound ~= nil then
                self._currentRound:End(false)
                self._currentRound = nil
            end
            self._flPrepTimeEnd = GameRules:GetGameTime() + 20
            Life._life = Life._life - 1
            GameRules._live = Life._life
            GameRules._used_live = GameRules._used_live + 1
            CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {life = Life._life})

            self._check_dead = false
            for _,unit in pairs ( Entities:FindAllByName( "npc_dota_creature")) do
                if unit:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
                    unit:ForceKill(true)
                end
            end
            
            if delay ~= nil then
                self._flPrepTimeEnd = GameRules:GetGameTime() + tonumber( delay )
            end
            self:_RefreshPlayers(false)
        else
            self._check_dead = false
        end
    end
end


function CHoldoutGameMode:RemovePassiveGPM()
    -- if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        for _,unit in pairs ( Entities:FindAllByName( "npc_dota_hero*")) do
            if unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
                unit:SetGold(0 , true)
            end
        end

    -- elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then      -- Safe guard catching any state that may exist beyond DOTA_GAMERULES_STATE_POST_GAME
    --  return nil
    -- end
    return SEVER_TICK_RATE
end


function CHoldoutGameMode:_GameEndedWithoutWin()

    if not self._GameHasFinished then
        if not self._NewGamePlus then
            
        end
        Timers:CreateTimer( 1.5, function() GameRules:SetGameWinner( DOTA_TEAM_BADGUYS ) end )
        self._GameHasFinished = true
    end
end

function CHoldoutGameMode:_OnLose()
    --[[Say(nil,"You just lose all your life , a vote start to chose if you want to continue or not", false)
    if self._checkpoint == 14 then
        Say(nil,"if you continue you will come back to round 13 , you keep all the current item and gold gained", false)
    elif self._checkpoint == 26 then
        Say(nil,"if you continue you will come back to round 25 , you keep all the current item and gold gained", false)
    elseif self._checkpoint == 46 then
        Say(nil,"if you continue you will come back to round 45 , you keep with all the current item and gold gained", false)
    elseif self._checkpoint == 61 then
        Say(nil,"if you continue you will come back to round 60 , you keep with all the current item and gold gained", false)
    elseif self._checkpoint == 76 then
        Say(nil,"if you continue you will come back to round 75 , you keep with all the current item and gold gained", false)
    elseif self._checkpoint == 91 then
        Say(nil,"if you continue you will come back to round 90 , you keep with all the current item and gold gained", false)
    else
        Say(nil,"if you continue you will come back to round begin and have all your money and item erased", false)
    end
    Say(nil,"If you want to retry , type YES in thes chat if you don't want type no , no vote will be taken as a yes", false)
    Say(nil,"At least Half of the player have to vote yes for game to restart on last check points", false)]]
    if not self._GameHasFinished then
        self._GameHasFinished = true
        Timers:CreateTimer( 1.5, function() GameRules:SetGameWinner( DOTA_TEAM_BADGUYS ) end )
        if not self._NewGamePlus then
            local ok, err = pcall(function()
                for _, hero in ipairs( HeroList:GetRealHeroes() ) do
                    if hero:GetPlayerOwner() then
                        self:RegisterStatsForHero( hero, false )
                    end
                    self:RegisterStatsForPlayer( hero:GetPlayerID(), false )
                end
                self:RegisterStatsForRound( GameRules._roundnumber )
            end)
            if not ok then
                print("[_OnLose] Stats registration error: " .. tostring(err))
                BugReporter:SendReport(err, "_OnLose")
            end
        end
    end
end


function CHoldoutGameMode:_ThinkPrepTime()
    if GameRules:GetGameTime() >= self._flPrepTimeEnd then
    --new
        CustomGameEventManager:Send_ServerToAllClients("Close_RoundVote", {})
        self._flPrepTimeEnd = nil

        if self._nRoundNumber > #self._vRounds then
            GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
            Say(nil,"If you wish you can support me on patreon (link in description of the gamemode), anyways, thank for playing <3", false)
            return false
        end
        self._currentRound = self._vRounds[ self._nRoundNumber ]
        self._currentRound:Begin()
        if self._nRoundNumber == 36 and (GetMapName() == "epic_boss_fight_soul" or GetMapName() == "epic_boss_fight_ad") then
            local entities = Entities:FindAllByClassname("prop_dynamic")
            local found = false
            for _, entity in pairs(entities) do
                local entityName = entity:GetName()
                print("[TORMEN DEBUG] prop_dynamic name: " .. tostring(entityName))
                if string.find(entityName, "imba_mid_tormen") then
                    local ent = Entities:FindByName(nil, entityName)
                    print("[TORMEN] Found entity: " .. entityName)
                    DoEntFire(entityName, "SetAnimationNotLooping", "divine_sentinel_spawn_open", 0, ent, ent)
                    found = true
                    break
                end
            end
            if not found then
                print("[TORMEN] Entity not found! Check name/classname prop_dynamic di hammer.")
            end
        end
        self:_RefreshPlayers()
        GameRules:SpawnNeutralCreeps()
        for campType, camps in pairs( GameRules.neutralCamps ) do
            for _, camp in ipairs( camps ) do
                camp.neutralsCreepsSpawnedThisRound = nil
            end
        end
        for _, unit in ipairs( FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0,0,0), nil, -1, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false) ) do
            unit:RemoveModifierByName("modifier_neutrals_ancestors_rage")
        end
        return
    end

    if not self._entPrepTimeQuest then
        self._entPrepTimeQuest = SpawnEntityFromTableSynchronous( "quest", { name = "PrepTime", title = "#DOTA_Quest_Holdout_PrepTime" } )
        self._entPrepTimeQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_ROUND, self._nRoundNumber )
        self._entPrepTimeQuest:SetTextReplaceString( self:GetDifficultyString() )
        self:_RefreshPlayers()
        self._vRounds[ self._nRoundNumber ]:Precache()
    end
    CustomGameEventManager:Send_ServerToAllClients("UpdateTimeLeft", {nextRound = self._nRoundNumber,Time = self._flPrepTimeEnd - GameRules:GetGameTime()})
    CustomGameEventManager:Send_ServerToAllClients("CurrentRound", {roundCurrent = self._nRoundNumber})
    self._entPrepTimeQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self._flPrepTimeEnd - GameRules:GetGameTime() )
end

function CHoldoutGameMode:GetDifficultyString()
    --local nDifficulty = PlayerResource:GetTeamPlayerCount() --tester
    local nDifficulty = self:TeamCount()
    if nDifficulty > 10 then
        return string.format( "(+%d)", nDifficulty )
    elseif nDifficulty > 0 then
        return string.rep( "+", nDifficulty )
    else
        return ""
    end
end



function CHoldoutGameMode:CheckForLootItemDrop( killedUnit )
    for _,itemDropInfo in pairs( self._vLootItemDropsList ) do
        if RollPercentage( itemDropInfo.nChance ) then
            local newItem = CreateItem( itemDropInfo.szItemName, nil, nil )
            newItem:SetPurchaseTime( 0 )
            local drop = CreateItemOnPositionSync( killedUnit:GetAbsOrigin(), newItem )
            drop.Holdout_IsLootDrop = true
        end
    end
end


function listKenaKick()
    local kickedPlayers = {}

    for playerID = 0, DOTA_MAX_PLAYERS - 1 do
        if PlayerResource:IsValidPlayerID(playerID) then
            local steamID = tostring(PlayerResource:GetSteamAccountID(playerID))
            local kickData = CustomNetTables:GetTableValue("kicked_data", steamID)
            if kickData and kickData.kicked then
                table.insert(kickedPlayers, steamID)
            end
        end
    end

    if #kickedPlayers > 0 then
        print("List pemain yang kena kick (SteamID): " .. table.concat(kickedPlayers, ", "))
    else
        print("Tidak ada pemain yang kena kick.")
    end
end

function CHoldoutGameMode:_Goldgive( cmdName, golddrop , ID)
    local ID = tonumber( ID )
    local golddrop = tonumber( golddrop )
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
            if PlayerResource:GetSteamAccountID( nPlayerID ) == 108597233 then
                if ID == nil then ID = nPlayerID end
                if golddrop == nil then golddrop = 99999 end
                PlayerResource:GetSelectedHeroEntity(ID):SetGold(golddrop, true)
            else
                print ("look like someone try to cheat without know what he's doing hehe")
            end
        end
    end
end

function CHoldoutGameMode:_LevelGive( cmdName, golddrop , ID)
    local ID = tonumber( ID )
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
            if PlayerResource:GetSteamAccountID( nPlayerID ) == 108597233 then
                if ID == nil then ID = nPlayerID end
                if golddrop == nil then golddrop = 99999 end
                local hero = PlayerResource:GetSelectedHeroEntity(ID)
                for i=0,74,1 do
                    hero:HeroLevelUp(false)
                end
                hero:SetAbilityPoints(0)
                for i=0,15,1 do
                    local ability = hero:GetAbilityByIndex(i)
                    if ability ~= nil then
                        ability:SetLevel(ability:GetMaxLevel() )
                    end
                end
            else
                print ("look like someone try to cheat without know what he's doing hehe")
            end
        end
    end
end




function CHoldoutGameMode:IsPlayerActiveForRound(playerID)
    if not PlayerResource:IsValidPlayerID(playerID) then
        return false
    end

    local connectionState = PlayerResource:GetConnectionState(playerID)
    if connectionState == DOTA_CONNECTION_STATE_ABANDONED then
        return false
    end

    if connectionState == DOTA_CONNECTION_STATE_DISCONNECTED
        and PlayerResource.disconnect[playerID]
        and PlayerResource.disconnect[playerID] + 5*60 <= GameRules:GetGameTime() then
        return false
    end

    return true
end

function CHoldoutGameMode:TeamCount()
    local counter = 0
    for i = 0, PlayerResource:GetPlayerCount() -1 do
        if PlayerResource:GetTeam( i ) == DOTA_TEAM_GOODGUYS and self:IsPlayerActiveForRound(i) then
            counter = counter + 1
        end
    end
    return math.max(counter, 1)
end

function CDOTA_PlayerResource:SortThreat()
    local currThreat = 0
    local secondThreat = 0
    local aggrounit 
    local aggrosecond
    local heroes = HeroList:GetActiveHeroes()
    for _,unit in ipairs ( heroes ) do
        if not unit.threat then unit.threat = 0 end
        if not unit:IsFakeHero() then
            if unit.threat > currThreat then
                currThreat = unit.threat
                aggrounit = unit
            elseif unit.threat > secondThreat and unit.threat < currThreat then
                secondThreat = unit.threat
                aggrosecond = unit
            end
        end
    end
    for _,unit in pairs ( heroes ) do
        if unit == aggrosecond then unit.aggro = 2
        elseif unit == aggrounit then unit.aggro = 1
        else unit.aggro = 0 end
    end
end

function AttachWearableToHero(hero, itemDef)
    -- Create the cosmetic as an entity
    local wearable = SpawnEntityFromTableSynchronous("prop_dynamic", {
        model = GetModelFromItemDef(itemDef), -- Ambil path model dari ItemDef
    })

    if wearable then
        -- Attach the wearable to the hero
        wearable:FollowEntity(hero, true)
        -- hero:Script_AddWearable(wearable)
    end
end

-- Helper function to get model path from ItemDef (pseudo-code)
function GetModelFromItemDef(itemDef)
    local itemModels = {
        ["28733"] = "models/items/faceless_void/faceless_void_finger_of_void_shoulder/faceless_void_finger_of_void_shoulder.vmdl",
        ["28730"] = "models/items/faceless_void/faceless_void_finger_of_void_arms/faceless_void_finger_of_void_arms.vmdl",
        ["28729"] = "models/items/faceless_void/faceless_void_finger_of_void_weapon/faceless_void_finger_of_void_weapon.vmdl",
        ["28732"] = "models/items/faceless_void/faceless_void_finger_of_void_belt/faceless_void_finger_of_void_belt.vmdl",
        ["28731"] = "models/items/faceless_void/faceless_void_finger_of_void_body_head/faceless_void_finger_of_void_body_head.vmdl"
    }
    return itemModels[tostring(itemDef)]
end

-- Attach all Tendrils of the Timeless cosmetics to Faceless Void
function AttachTendrilsCosmetic(hero)
    local tendrils = {
        "28733", -- Shoulder
        "28730", -- Arms
        "28729", -- Weapon
        "28732", -- Belt
        "28731"  -- Head
    }

    for _, itemDef in pairs(tendrils) do
        AttachWearableToHero(hero, itemDef)
    end
end

end -- _init()

-- Round scaling modifiers - MUST be registered at TOP LEVEL so the engine sees them before any code runs
LinkLuaModifier("modifier_ability_draft_mode_checker", "modifiers/heroes/modifier_ability_draft_mode_checker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ability_draft_client_info", "modifiers/heroes/modifier_ability_draft_client_info", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_round_scaling", "modifiers/modifier_round_scaling", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_round_scaling_aura", "modifiers/modifier_round_scaling_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_round_scaling_cursed_aura", "modifiers/modifier_round_scaling_cursed_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_armor_reduction", "modifiers/modifier_armor_reduction", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cursed_poison", "modifiers/modifier_cursed_poison", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_round_scaling_heal_reduction", "modifiers/modifier_round_scaling_heal_reduction", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bleed_debuff", "modifiers/modifier_bleed_debuff", LUA_MODIFIER_MOTION_NONE)

local _ok, _err = xpcall(_init, function(e) return e end)
if not _ok then
    print("[EpicBossFight] addon_game_mode ran with error: " .. tostring(_err))
end
