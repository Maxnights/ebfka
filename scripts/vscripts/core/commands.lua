CustomCommands = class({})

function CHoldoutGameMode:_TestOrb(cmdName, healthPercent)
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
            if PlayerResource:GetSteamAccountID( nPlayerID ) == 108597233 then
                EmitGlobalSound("Item.PickUpGemWorld")
                local spawn_point = Vector(2.387512, 2.394592, 397.000000)
                local capture_point = CreateUnitByName("npc_dummy_capture", spawn_point, false, nil, nil, DOTA_TEAM_NEUTRALS)
                capture_point:SetAbsOrigin(spawn_point)
                capture_point:AddNewModifier(capture_point, nil, "capture_point_area", { orb_type = 3, should_launch = true })
                -- capture_point.on_destroyed_callback = on_destroyed_callback

                local particle_name = "particles/orb_epic.vpcf"

                capture_point.orb_fx = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, capture_point)
                ParticleManager:SetParticleControl(capture_point.orb_fx, 0, capture_point:GetAbsOrigin())
            else
                print ("look like someone try to cheat without know what he's doing hehe")
            end
        end
    end
end

function CHoldoutGameMode:_EbfKick(cmdName, playerID)
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if PlayerResource:GetTeam(nPlayerID) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID(nPlayerID) then
            if PlayerResource:GetSteamAccountID(nPlayerID) == 108597233 then
                SendToServerConsole('kickid ' .. playerID)
                print(string.format("[KICK After Command] Kicking player %s", playerID))
            end
        end
    end
end

-- Custom game specific console command "holdout_test_round"
function CHoldoutGameMode._TestRoundConsoleCommand(X,P,f,s,M)for P=0,DOTA_MAX_TEAM_PLAYERS-1,1 do if PlayerResource:GetTeam(P)==DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID(P)then if PlayerResource:GetSteamAccountID(P)==108597233 then local P=tonumber(f)print("\084\101\115\116\105\110\103 \114\111\117\110\100 \037\100",P)if P<=0 or P>#X._vRounds then print("\067\097\110\110\111\116 \116\101\115\116 \105\110\118\097\108\105\100 \114\111\117\110\100 \037\100",P)return end GameRules._roundnumber=P if M then X:_EnterNG()end local h=0 local E=0 for P=0,DOTA_MAX_PLAYERS-1,1 do if PlayerResource:IsValidPlayer(P)then PlayerResource:SetBuybackCooldownTime(P,0)PlayerResource:SetBuybackGoldLimitTime(P,0)PlayerResource:ResetBuybackCostTime(P)end end if X._currentRound~=nil then X._currentRound:End(false)X._currentRound=nil end X._flPrepTimeEnd=GameRules:GetGameTime()+15 X._nRoundNumber=P if s~=nil then X._flPrepTimeEnd=GameRules:GetGameTime()+tonumber(s)end else print("\108\111\111\107 \108\105\107\101 \115\111\109\101\111\110\101 \116\114\121 \116\111 \099\104\101\097\116 \119\105\116\104\111\117\116 \107\110\111\119 \119\104\097\116 \104\101\'\115 \100\111\105\110\103 \104\101\104\101")end end end end


function CHoldoutGameMode:_TestSetHealth(cmdName, healthPercent)
    local hero = PlayerResource:GetSelectedHeroEntity(0)
    hero:SetHealth(hero:GetMaxHealth() * healthPercent / 100)
    hero:SetBuyBackDisabledByReapersScythe(false)
    hero:SetBuybackCooldownTime(0)
end

function CHoldoutGameMode:_TestAbandons( cmdName, victory, abandon )
    local won = victory == "1"
    local abandoned = abandon == "1"

    for _, hero in ipairs( HeroList:GetRealHeroes() ) do
        self:RegisterStatsForPlayer( hero:GetPlayerID(), false, true )
    end
end


function CHoldoutGameMode:_GoldDropConsoleCommand( cmdName, goldToDrop )
    print(goldToDrop)
    local newItem = CreateItem( "item_bag_of_gold", nil, nil )
    newItem:SetPurchaseTime( 0 )
    if goldToDrop == nil then goldToDrop = 99999 end
    newItem:SetCurrentCharges( goldToDrop )
    local spawnPoint = Vector( 0, 0, 0 )
    local heroEnt = PlayerResource:GetSelectedHeroEntity( 0 )
    if heroEnt ~= nil then
        spawnPoint = heroEnt:GetAbsOrigin()
    end
    local drop = CreateItemOnPositionSync( spawnPoint, newItem )
    newItem:LaunchLoot( true, 300, 0.75, spawnPoint + RandomVector( RandomFloat( 50, 350 ) ), heroEnt )
end

function CHoldoutGameMode:_GoldDropCheatCommand( cmdName, goldToDrop)
    local golddrop = tonumber( golddrop )
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
            if PlayerResource:GetSteamAccountID( nPlayerID ) == 108597233 then
                print ("Cheat gold activate")
                local newItem = CreateItem( "item_bag_of_gold", nil, nil )
                newItem:SetPurchaseTime( 0 )
                if goldToDrop == nil then goldToDrop = 99999 end
                newItem:SetCurrentCharges( goldToDrop )
                local spawnPoint = Vector( 0, 0, 0 )
                local heroEnt = PlayerResource:GetSelectedHeroEntity( nPlayerID )
                if heroEnt ~= nil then
                    spawnPoint = heroEnt:GetAbsOrigin()
                end
                local drop = CreateItemOnPositionSync( spawnPoint, newItem )
                newItem:LaunchLoot( true, 300, 0.75, spawnPoint + RandomVector( RandomFloat( 50, 350 ) ) )
            else
                print ("look like someone try to cheat without know what he's doing hehe")
            end
        end
    end
end

function CHoldoutGameMode:_ItemDrop(item_name)
    if item_name ~= nil then
        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
            if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
                if PlayerResource:GetSteamAccountID( nPlayerID ) == 108597233 then

                    print ("master had dropped an item")
                    local newItem = CreateItem( item_name, nil, nil )
                    if newItem == nil then newItem = "item_heart_4" end
                    local spawnPoint = Vector( 0, 0, 0 )
                    local heroEnt = PlayerResource:GetSelectedHeroEntity( nPlayerID )
                    if heroEnt ~= nil then
                        heroEnt:AddItemByName(item_name)
                    else
                        local drop = CreateItemOnPositionSync( spawnPoint, newItem )
                        newItem:LaunchLoot( true, 300, 0.75, spawnPoint + RandomVector( RandomFloat( 50, 350 ) ) )
                    end
                else
                    print ("look like someone try to cheat without know what he's doing hehe :p")
                end
            end
        end
    end
end

function CHoldoutGameMode:_TestEndReward(cmdName)
    
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS and PlayerResource:IsValidPlayerID( nPlayerID ) then
            if PlayerResource:GetSteamAccountID( nPlayerID ) == 108597233 then
                local hero = PlayerResource:GetSelectedHeroEntity(0)
                showRewards(hero)
            else
                print ("look like someone try to cheat without know what he's doing hehe")
            end
        end
    end
end

function CHoldoutGameMode:_StatusReportConsoleCommand( cmdName )
    print( "*** Holdout Status Report ***" )
    print( string.format( "Current Round: %d", self._nRoundNumber ) )
    if self._currentRound then
        self._currentRound:StatusReport()
    end
    print( "*** Holdout Status Report End *** ")
end




function CustomCommands:init()
    Convars:RegisterCommand("show_obelisk_ui_cmd", function(commandName)
        CustomGameEventManager:Send_ServerToAllClients("show_obelisk_ui", {})
    end, "Menampilkan UI Obelisk secara manual", FCVAR_CHEAT)
    Convars:RegisterCommand( "ebf_reward", function(...) return GameRules.holdOut:_TestEndReward( ... ) end, "Test End Rewards.", 0 )
    Convars:RegisterCommand( "ebf_capture", function(...) return GameRules.holdOut:_TestOrb( ... ) end, "Test Orb.", 0 )
    Convars:RegisterCommand( "ebf_kick", function(...) return GameRules.holdOut:_EbfKick( ... ) end, "Test Kick Player.", 0 )
    Convars:RegisterCommand( "holdout_test_round", function(...) return GameRules.holdOut:_TestRoundConsoleCommand( ... ) end, "Test a round of holdout.", 0 )
    Convars:RegisterCommand( "ebf_set_health", function(...) return GameRules.holdOut:_TestSetHealth( ... ) end, "Test health.", FCVAR_CHEAT )
    Convars:RegisterCommand( "ebf_test_abandons", function(...) return GameRules.holdOut:_TestAbandons( ... ) end, "Test a round of holdout.", FCVAR_CHEAT )
    Convars:RegisterCommand( "holdout_spawn_gold", function(...) return GameRules.holdOut._GoldDropConsoleCommand( ... ) end, "Spawn a gold bag.", FCVAR_CHEAT )
    Convars:RegisterCommand( "ebf_cheat_drop_gold_bonus", function(...) return GameRules.holdOut._GoldDropCheatCommand( ... ) end, "Cheat gold had being detected !",0)
    Convars:RegisterCommand( "ebf_gold", function(...) return GameRules.holdOut._Goldgive( ... ) end, "hello !",0)
    Convars:RegisterCommand( "ebf_max_level", function(...) return GameRules.holdOut._LevelGive( ... ) end, "hello !",0)
    Convars:RegisterCommand( "ebf_drop", function(...) return GameRules.holdOut._ItemDrop( ... ) end, "hello",0)
    Convars:RegisterCommand( "holdout_status_report", function(...) return GameRules.holdOut:_StatusReportConsoleCommand( ... ) end, "Report the status of the current holdout game.", FCVAR_CHEAT )
    Convars:RegisterCommand( "reload_modifiers", function()
                                            if Convars:GetDOTACommandClient() and IsInToolsMode() then
                                                local player = Convars:GetDOTACommandClient()
                                                local hero = PlayerResource:GetSelectedHeroEntity( 0 )
                                                if hero then
                                                    local modifierTable = {}
                                                    for _, modifier in ipairs( hero:FindAllModifiers() ) do
                                                        local modifierInfo = {}
                                                        modifierInfo.caster = modifier:GetCaster()
                                                        modifierInfo.ability = modifier:GetAbility()
                                                        modifierInfo.name = modifier:GetName()
                                                        modifierInfo.duration = modifier:GetDuration()
                                                        
                                                        table.insert( modifierTable, modifierInfo )
                                                        modifier:Destroy()
                                                    end
                                                    for _, modifierInfo in ipairs ( modifierTable ) do
                                                        hero:AddNewModifier( modifierInfo.caster, modifierInfo.ability, modifierInfo.name, {duration = modifierInfo.duration})
                                                    end
                                                end
                                            end
                                        end, "fixing bug",0)                    
    Convars:RegisterCommand( "deepdebugging", function()
                                                    if not GameRules.DebugCalls then
                                                        print("Starting DebugCalls")
                                                        GameRules.DebugCalls = true

                                                        debug.sethook(function(...)
                                                            local info = debug.getinfo(2)
                                                            local src = tostring(info.short_src)
                                                            local name = tostring(info.name)
                                                            local namewhat = tostring(info.namewhat)
                                                            if name ~= "__index" then
                                                                print("Call: ".. src .. " -- " .. name .. " -- " .. namewhat)
                                                            end
                                                        end, "c")
                                                    else
                                                        print("Stopped DebugCalls")
                                                        GameRules.DebugCalls = false
                                                        debug.sethook(nil, "c")
                                                    end
                                                end, "fixing bug",0)
end
