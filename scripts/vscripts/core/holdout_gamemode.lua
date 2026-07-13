top5Leaderboard = {}

season1Leaderboard = {}

playerChats = {}



if CHoldoutGameMode == nil then

    CHoldoutGameMode = class({})

end





require("core.buffs_modifier.modifier_buff_cdr_all")

require("core.buffs_modifier.modifier_buff_outgoing_dmg_all")

require("core.buffs_modifier.modifier_buff_mmr_all")

require("core.buffs_modifier.modifier_buff_xpm_2200")

require("core.buffs_modifier.modifier_buff_xpm_4500")

require("core.buffs_modifier.modifier_buff_gpm_2500")

require("core.buffs_modifier.modifier_buff_gpm_3750")

require("core.buffs_modifier.modifier_buff_codex")

require("core.buffs_modifier.modifier_buff_stats")

require("core.buffs_modifier.modifier_buff_crit_all")

require("core.buffs_modifier.modifier_buff_mana_regen_all")

require("core.buffs_modifier.modifier_buff_bonus_dmg_all")

require("item_blacklist")

require("core.system")

require("core.buffs")

require("libraries.wearable")

require("libraries.activity_modifier")

require("core.event_listeners")

require("core.commands")

require("core.game_events")

require("core.game_stats")

require("core.game_filters")

require("core.bpass")

require("aghanim_ability_upgrade_constants")

require("minor_ability_wiki")



function CHoldoutGameMode:InitGameMode()

    -- MapWearables()

    -- GenerateBundleBlock( "Phantom Advent Bundle" )

    for i=0,16 do

        player_ability_pool[i]={}

    end



    init_player_ability_pool()

    print ("Epic Boss Fight - IMBA")

    print ("Extended From EBF Reborn")

    -- StartNaixCliffChecker()

    GameRules.ObeliskActivated = false

    GameRules.ObeliskActivator = nil

    GameRules.DropTable = LoadKeyValues("scripts/kv/loot.kv")

    GameRules._finish = false

    GameRules.vote_Yes = 0

    GameRules.vote_No = 0

    GameRules.voteRound_Yes = 0;

    GameRules.voteRound_No = 0;

    GameRules.difficultyConfig = {}
    GameRules.selected_facet_id = {}
    self.playersSelectedInnateAndFacetInfo = {}
    self.playersPickedHero = {}
    self.activatedGameMode = nil
    self.abilityDraftMode = nil
    CustomNetTables:SetTableValue("global_info", "map_info", {
        map_name = GetMapName(),
        is_ability_draft = (IsAbilityDraftMap and IsAbilityDraftMap()) or false,
    })
    if IsAbilityDraftMap and IsAbilityDraftMap() then
        self.activatedGameMode = CUSTOM_GAME_MODE_ABILITY_DRAFT
        CustomNetTables:SetTableValue("global_info", "game_mode", {
            id = self.activatedGameMode,
            name = CUSTOM_GAME_MODE_ABILITY_DRAFT_NAME,
        })
    end
    self._nRoundNumber = 1
    GameRules._roundnumber = 1

    self._NewGamePlus = false

    self.Last_Target_HB = nil

    self.Shield = false

    self.Last_HP_Display = -1

    self._currentRound = nil



    self._roundsRegened = {}

    self._regenNG = false

    self._check_check_dead = false

    self._flLastThinkGameTime = nil

    self._check_dead = false

    self._timetocheck = 0

    self._freshstart = true

    self.boss_master_id = -1

    self.user_ids = {}

    self.kicks_id = {}

    Life = class({})





    -- for hero_name, _ in pairs(_G.MINOR_ABILITY_UPGRADES) do

    --  table.insert(hero_keys, hero_name)

    -- end

    CustomNetTables:SetTableValue( "hero_special_upgrades", "hero", hero_keys)

    

    MinorAbilityWiki:Init()



    -- if GetMapName() == "epic_boss_fight_boss_master" then Life._life = 9

        -- GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 1 )

        -- GameRules:SetHeroSelectionTime( 45.0 )

        -- Life._MaxLife = 9

    -- else

        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )

    -- end

    

    GameRules:SetPreGameTime( 30 )

    GameRules:SetShowcaseTime( 0 )

    GameRules:SetPostGameTime( 15 )



    GameRules:SetCustomGameEndDelay( 15.0 )
    GameRules:GetGameModeEntity():SetDraftingHeroPickSelectTimeOverride(60)
    GameRules:SetHeroSelectPenaltyTime( 5.0 )
    if IsAbilityDraftMap and IsAbilityDraftMap() then
        GameRules:SetHeroSelectionTime(600)
        GameRules:GetGameModeEntity():SetDraftingHeroPickSelectTimeOverride(600)
        GameRules:SetHeroSelectPenaltyTime(600)
    end
    -- GameRules:SetCustomGameSetupAutoLaunchDelay( 0 )



    GameRules:LockCustomGameSetupTeamAssignment(false)

    GameRules:EnableCustomGameSetupAutoLaunch(true)

  	GameRules:SetCustomGameSetupAutoLaunchDelay(50)

    GameRules:SetCustomGameSetupRemainingTime(3)



    Convars:SetInt("tv_delay", 10)

    Convars:SetInt("dota_max_physical_items_purchase_limit", 500)

    Convars:SetInt("sv_allchat", 1)

    Convars:SetInt("sv_alltalk", 1)



    GameRules.herodemo = GameRules.herodemo or {}

    GameRules.herodemo.m_bRespawnWear = GameRules.herodemo.m_bRespawnWear or false

    GameRules.herodemo.m_tAlliesList = GameRules.herodemo.m_tAlliesList or {}

    self._wearablesInitialized = false



    

    local function ApplyDifficultySettings(mapName)

        local settings = DIFFICULTY_SETTINGS[mapName]

        if not settings then return end

        

        -- Apply life settings

        Life._life = settings.life

        Life._MaxLife = settings.maxLife

        

        -- Apply game rules

        GameRules._bonusLifeRoundDivider = settings.bonusLifeDivider

        GameRules.gameDifficulty = settings.difficulty

        GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, settings.teamSize)

        

        -- Apply bans if specified

        if settings.bans > 0 then

            GameRules:SetCustomGameBansPerTeam(settings.bans)

        end

        

        -- Apply vision and time settings

        local gameMode = GameRules:GetGameModeEntity()

        if mapName == "epic_boss_fight_nightmare" or mapName == "epic_boss_fight_purgatory" or mapName == "epic_boss_fight_soul" then

            -- gameMode:SetFogOfWarDisabled(settings.fogOfWar)

            -- gameMode:SetDaynightCycleDisabled(not settings.dayNightCycle)

        end



        if mapName == "epic_boss_fight_purgatory" then

            GameRules:GetGameModeEntity():SetBuybackEnabled( false )

        end

        

    end

    

    -- Apply settings based on current map

    ApplyDifficultySettings(GetMapName())

    

    GameRules:GetGameModeEntity():SetDraftingBanningTimeOverride(15)



    GameRules:SetStrategyTime( 12 )

    

    GameRules:SetStartingGold ( 8000 )



    if IsInToolsMode() or GameRules:IsCheatMode() then

        

        GameRules:SetPreGameTime( 99999 )

        GameRules:GetGameModeEntity():SetDraftingHeroPickSelectTimeOverride(99999)

        GameRules:GetGameModeEntity():SetDraftingBanningTimeOverride(0)

        GameRules:SetStrategyTime(0)

        GameRules:SetStartingGold(99999)

    end

    

    GameRules._live = Life._life

    GameRules._used_live = 0

    

    self:_ReadGameConfiguration()

    

    GameRules:SetHeroRespawnEnabled( false )

    GameRules:SetUseUniversalShopMode( true )

    GameRules:SetTreeRegrowTime( 15.0 )

    GameRules:SetCreepMinimapIconScale( 4 )

    GameRules:SetRuneMinimapIconScale( 1.5 )

    GameRules:SetGoldTickTime( 0.6 )

    GameRules:SetGoldPerTick( 5 )

    

    GameRules:SetEnableAlternateHeroGrids( false )

    GameRules:SetSameHeroSelectionEnabled( false )

    GameRules:GetGameModeEntity():SetPlayerHeroAvailabilityFiltered( true )

    GameRules:GetGameModeEntity():SetCameraDistanceOverride(1400)

    GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride( true )

    GameRules:GetGameModeEntity():SetTopBarTeamValuesVisible( false )

    

    

    GameRules:GetGameModeEntity():SetCustomBuybackCooldownEnabled( true )

    GameRules:GetGameModeEntity():SetCustomBuybackCostEnabled( true )

    GameRules:GetGameModeEntity():SetFreeCourierModeEnabled( true )

    GameRules:GetGameModeEntity():SetSelectionGoldPenaltyEnabled( false )

    GameRules:GetGameModeEntity():DisableClumpingBehaviorByDefault( true )

    GameRules:GetGameModeEntity():SetCanSellAnywhere( true )

    

    

    

    xpTable = {[1] = 0}

    local baseXPNeeded = 1000

    local sumXP = 0

    for level = 1, 55, 1 do

        local XPForLevel = baseXPNeeded * (level - 1)

        sumXP = sumXP + XPForLevel

        xpTable[level] = sumXP

    end



    GameRules:GetGameModeEntity():SetUseCustomHeroLevels( true )

    GameRules:GetGameModeEntity():SetCustomHeroMaxLevel( 55 )

    GameRules:GetGameModeEntity():SetCustomXPRequiredToReachNextLevel( xpTable )

    GameRules:GetGameModeEntity():SetLoseGoldOnDeath( false )

    GameRules:GetGameModeEntity():SetGiveFreeTPOnDeath( false )

    GameRules:GetGameModeEntity():SetStickyItemDisabled( true )

    GameRules:GetGameModeEntity():SetDefaultStickyItem( "item_bottle" )

    GameRules:GetGameModeEntity():SetTPScrollSlotItemOverride( "item_bottle" )

    

    GameRules:GetGameModeEntity():SetMaximumAttackSpeed(2500)

    GameRules:GetGameModeEntity():SetMinimumAttackSpeed( 80 )

    

    GameRules:GetGameModeEntity():SetInnateMeleeDamageBlockAmount( 0 )

    GameRules:GetGameModeEntity():SetInnateMeleeDamageBlockPerLevelAmount( 0 )

    GameRules:GetGameModeEntity():SetInnateMeleeDamageBlockPercent( 0 )



    GameRules:GetGameModeEntity():SetHudCombatEventsDisabled( true )

    

    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP, 22) 

    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP_REGEN, 0.15)

    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ARMOR, 0.00) 

    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ATTACK_SPEED, 0.0)

    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MANA, 2) 

    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MANA_REGEN, 0.01)

    GameRules:GetGameModeEntity():SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MAGIC_RESIST, 0.0)

    

    -- Custom console commands

    CustomCommands:init()



    -- Hook into game events allowing reload of functions at run time

    EventListeners:init(self)



    GameEventListener:init()



    CustomGameEventManager:RegisterListener('Boss_Master', Dynamic_Wrap( CHoldoutGameMode, 'Boss_Master'))

    CustomGameEventManager:RegisterListener('player_is_banned', Dynamic_Wrap( CHoldoutGameMode, 'player_is_banned'))



    CustomGameEventManager:RegisterListener('mute_sound', Dynamic_Wrap( CHoldoutGameMode, 'mute_sound'))

    CustomGameEventManager:RegisterListener('unmute_sound', Dynamic_Wrap( CHoldoutGameMode, 'unmute_sound'))

    CustomGameEventManager:RegisterListener('Health_Bar_Command', Dynamic_Wrap( CHoldoutGameMode, 'Health_Bar_Command'))

    CustomGameEventManager:RegisterListener("chat_time", CHoldoutGameMode.chat_time)

    

    PurgatoryReward:Init()

    CosmeticShop:Init()

    CouponCode:Init()

    SyncedChat:Init()

    

    CustomGameEventManager:RegisterListener('epic_boss_fight_ng_voted', function(id, event) return self:NewGamePlus_ProcessVotes( event ) end )

    CustomGameEventManager:RegisterListener('Vote_Round', Dynamic_Wrap( CHoldoutGameMode, 'vote_Round'))

    CustomGameEventManager:RegisterListener( "PingModifeirs:ping", Dynamic_Wrap(CHoldoutGameMode, "customPing"))

    CustomGameEventManager:RegisterListener( "choose_difficulty", Dynamic_Wrap(CHoldoutGameMode, "choose_difficulty"))

    CustomGameEventManager:RegisterListener( "vote_end", Dynamic_Wrap(CHoldoutGameMode, "vote_end"))

    CustomGameEventManager:RegisterListener( "admin_kick", function(playerID, event) self:admin_kick(event) end)

    CustomGameEventManager:RegisterListener( "admin_command", function(playerID, event) self:admin_command(event) end)

    

    GameFilters:init(self)

    

    -- Register OnThink with the game engine so it is called every 0.25 seconds

    GameRules:GetGameModeEntity():SetThink( "OnThink", self, 0.25 )

    --GameRules:GetGameModeEntity():SetThink( "RemovePassiveGPM", self, SEVER_TICK_RATE ) --tester

    panoramaBridge:Init()

    bossManager:Init(self)

    

    PlayerResource.disconnect = {}

    PlayerResource.abandoned_player_hero_selection = {}

    if HeroSoundManager and HeroSoundManager.Init then

        HeroSoundManager:Init()

    end

end

