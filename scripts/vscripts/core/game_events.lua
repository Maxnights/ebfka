GameEventListener = class({})

-- from dota survivor, ty
function swap_ability(eventSourceIndex, data)
    local hero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
    hero:SwapAbilities(data.ability1,data.ability2,true,true)

    -- Fix: Set abilities to not hidden after swap (Valve auto-hides abilities with index > 5)
    local ability1 = hero:FindAbilityByName(data.ability1)
    local ability2 = hero:FindAbilityByName(data.ability2)

    if ability1 then
        ability1:SetHidden(false)
    end

    if ability2 then
        ability2:SetHidden(false)
    end
end

--from dota survivor
function get_hotkey_ability(eventSourceIndex, data)
    local hero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
    local showed_abilities ={}
    for i=0,34 do
        local ability = hero:GetAbilityByIndex(i)
        if ability and not ability:IsHidden() and not ability:IsAttributeBonus() then
            showed_abilities[i] = ability:GetName()
        end
    end
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID),"get_hotkey_ability",showed_abilities)
end

-- from dota survivor, ty
function ability_book(eventSourceIndex, data)
    local hero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
    
    local ability = hero:AddAbility(data.name)
    ability:SetLevel(1)

    if data.name == "nevermore_necromastery" then
        hero:AddNewModifier(hero, nil, "modifier_auto_necromastery", {})
        hero.auto_necromastery = true
    end

    hero:SwapAbilities(ability:GetName(),"spawn_creep",true,true)

    table.insert(_G.player_ability_pool[data.PlayerID],data.name)
    CustomNetTables:SetTableValue( "selected_abilitys_table", tostring(data.PlayerID), _G.player_ability_pool[data.PlayerID] )
end

function upgrade_minor(eventSourceIndex, data)
    print("[upgrade_minor] upgrade_minor")
    local playerID = data.PlayerID
    local choiceIndex = tonumber(data.choice_index)

    if not choiceIndex then
        print("[upgrade_minor] ERROR: missing choice_index from player " .. tostring(playerID))
        return
    end

    if not (_G.pending_rewards and _G.pending_rewards[playerID]) then
        print("[upgrade_minor] WARNING: no pending rewards for player " .. tostring(playerID))
        return
    end

    local storedUpgrade = _G.pending_rewards[playerID][choiceIndex]
    if not storedUpgrade then
        print("[upgrade_minor] ERROR: invalid choice_index " .. tostring(choiceIndex) .. " for player " .. tostring(playerID))
        return
    end

    local from_item = storedUpgrade.from_item == 1

    if not from_item then
        require("generic_upgrades/generic_system")
        require("special_upgrades/special_upgrade_system")
        local isSupporter = IsGenericUpgradeSupporter(playerID)

        if storedUpgrade.supporter_locked == 1 and not isSupporter then
            print("[upgrade_minor] Blocked supporter locked reward for non-supporter player " .. tostring(playerID))
            return
        end

        if choiceIndex == 3 and storedUpgrade.supporter_locked == 1 and not isSupporter then
            print("[upgrade_minor] Blocked slot 3 selection for non-supporter player " .. tostring(playerID))
            return
        end
    end

    _G.pending_rewards[playerID] = nil
    if _G.player_rerolls then _G.player_rerolls[playerID] = nil end

    if not from_item then
        ClearRoundRewardsNetTable(playerID)
    end

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if AddSpecialUpgradeFromReward and AddSpecialUpgradeFromReward(hero, storedUpgrade) then
        return
    end

    if AddGenericUpgradeFromReward and AddGenericUpgradeFromReward(hero, storedUpgrade) then
        return
    end

    CHoldoutGameMode:AddMinorAbilityUpgrade(hero, storedUpgrade)
end

function reward_reroll(eventSourceIndex, data)
    local playerID = data.PlayerID
    _G.player_rerolls = _G.player_rerolls or {}

    local charges = _G.player_rerolls[playerID] or 0
    if charges <= 0 then
        print("[reward_reroll] Player " .. tostring(playerID) .. " tidak punya reroll charges")
        return
    end

    if not (_G.pending_rewards and _G.pending_rewards[playerID]) then
        print("[reward_reroll] Tidak ada pending rewards untuk player " .. tostring(playerID))
        return
    end

    _G.player_rerolls[playerID] = charges - 1
    _G.pending_rewards[playerID] = nil

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero then
        showRewards(hero)
    end
end

function skip_round_reward(eventSourceIndex, data)
    local playerID = data.PlayerID

    -- Cek supporter tier aktif.
    if not IsRoundRewardSupporter(playerID) then
        print("[skip_round_reward] Player " .. tostring(playerID) .. " tidak punya hak skip (bukan donator aktif)")
        return
    end

    if not (_G.pending_rewards and _G.pending_rewards[playerID]) then
        print("[skip_round_reward] Tidak ada pending rewards untuk player " .. tostring(playerID))
        return
    end

    -- Simpan seluruh pilihan round saat ini sebagai satu grup
    _G.skipped_rewards = _G.skipped_rewards or {}
    _G.skipped_rewards[playerID] = _G.skipped_rewards[playerID] or {}

    local newGroup = {}
    for i, item in ipairs(_G.pending_rewards[playerID]) do
        newGroup[i] = item
    end
    table.insert(_G.skipped_rewards[playerID], newGroup)

    -- Sync ke NetTable (nested: group index → choice index → item)
    local skippedNetData = {}
    for i, grp in ipairs(_G.skipped_rewards[playerID]) do
        local netGrp = {}
        for j, item in ipairs(grp) do
            netGrp[tostring(j)] = item
        end
        skippedNetData[tostring(i)] = netGrp
    end
    CustomNetTables:SetTableValue("skipped_rewards", tostring(playerID), skippedNetData)

    -- Bersihkan round saat ini
    _G.pending_rewards[playerID] = nil
    _G.player_rerolls[playerID] = nil
    ClearRoundRewardsNetTable(playerID)

    print("[skip_round_reward] Player " .. tostring(playerID) .. " skip, total skipped: " .. #_G.skipped_rewards[playerID])
end

function choose_skipped_reward(eventSourceIndex, data)
    local playerID    = data.PlayerID
    local groupIndex  = tonumber(data.group_index)
    local choiceIndex = tonumber(data.choice_index)

    if not groupIndex or not choiceIndex then
        print("[choose_skipped_reward] ERROR: missing group_index or choice_index")
        return
    end

    if not (_G.skipped_rewards and _G.skipped_rewards[playerID]) then
        print("[choose_skipped_reward] Tidak ada skipped rewards untuk player " .. tostring(playerID))
        return
    end

    local group = _G.skipped_rewards[playerID][groupIndex]
    if not group then
        print("[choose_skipped_reward] ERROR: group_index " .. tostring(groupIndex) .. " tidak valid")
        return
    end

    local storedUpgrade = group[choiceIndex]
    if not storedUpgrade then
        print("[choose_skipped_reward] ERROR: choice_index " .. tostring(choiceIndex) .. " tidak valid dalam group")
        return
    end

    require("generic_upgrades/generic_system")
    require("special_upgrades/special_upgrade_system")
    if storedUpgrade.supporter_locked == 1 and not IsGenericUpgradeSupporter(playerID) then
        print("[choose_skipped_reward] Blocked supporter locked reward for non-supporter player " .. tostring(playerID))
        return
    end

    -- Hapus seluruh grup (player sudah pilih satu dari grup ini)
    table.remove(_G.skipped_rewards[playerID], groupIndex)

    -- Sync skipped NetTable
    local skippedNetData = {}
    for i, grp in ipairs(_G.skipped_rewards[playerID]) do
        local netGrp = {}
        for j, item in ipairs(grp) do
            netGrp[tostring(j)] = item
        end
        skippedNetData[tostring(i)] = netGrp
    end
    CustomNetTables:SetTableValue("skipped_rewards", tostring(playerID), skippedNetData)

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if AddSpecialUpgradeFromReward and AddSpecialUpgradeFromReward(hero, storedUpgrade) then
        return
    end

    if AddGenericUpgradeFromReward and AddGenericUpgradeFromReward(hero, storedUpgrade) then
        return
    end

    CHoldoutGameMode:AddMinorAbilityUpgrade(hero, storedUpgrade)
end

function CHoldoutGameMode:AddMinorAbilityUpgrade( hHero, upgradeTable )
    print("=== Adding Minor Ability Upgrade ===")
    print("Hero:", hHero:GetUnitName())
    print("PlayerID:", hHero:GetPlayerOwnerID())
    print("Ability:", upgradeTable["ability_name"])
    print("Special Value:", upgradeTable["special_value_name"])
    print("Operator:", upgradeTable["operator"])
    print("Value:", upgradeTable["value"])


    if hHero.MinorAbilityUpgrades == nil then
        hHero.MinorAbilityUpgrades = {}
    end

    local szAbilityName = upgradeTable[ "ability_name" ]
    
    if hHero.MinorAbilityUpgrades[ szAbilityName ] == nil then
        hHero.MinorAbilityUpgrades[ szAbilityName ] = {}
    end

    local szSpecialValueName = upgradeTable[ "special_value_name" ]
    if szSpecialValueName ~= nil then
        print("Insert Single Special Value")
        if hHero.MinorAbilityUpgrades[ szAbilityName ][ szSpecialValueName ] == nil then
            hHero.MinorAbilityUpgrades[ szAbilityName ][ szSpecialValueName ] = {}
        end
        local newUpgradeTable = {}
        newUpgradeTable[ "operator" ] = upgradeTable[ "operator" ]
        newUpgradeTable[ "value" ] = upgradeTable[ "value" ]
        newUpgradeTable[ "elite" ] = upgradeTable[ "elite" ]
        newUpgradeTable[ "RequiresFacetID" ] = upgradeTable[ "RequiresFacetID" ]
        newUpgradeTable[ "DisabledWithFacetID" ] = upgradeTable[ "DisabledWithFacetID" ]
        
        table.insert( hHero.MinorAbilityUpgrades[ szAbilityName ][ szSpecialValueName ], newUpgradeTable )
    else
        local SpecialValues = upgradeTable[ "special_values" ]
        if SpecialValues == nil then 
            print( "ERROR! Malformed multiple special values minor ability upgrade" )
            return
        end

        for _,SpecialValue in pairs( SpecialValues ) do 
            szSpecialValueName = SpecialValue[ "special_value_name" ]

            if hHero.MinorAbilityUpgrades[ szAbilityName ][ szSpecialValueName ] == nil then
                hHero.MinorAbilityUpgrades[ szAbilityName ][ szSpecialValueName ] = {}
            end

            local newUpgradeTable = {}
            newUpgradeTable[ "operator" ] = SpecialValue[ "operator" ]
            newUpgradeTable[ "value" ] = SpecialValue[ "value" ]
            newUpgradeTable[ "elite" ] = upgradeTable[ "elite" ]
            newUpgradeTable[ "RequiresFacetID" ] = SpecialValue[ "RequiresFacetID" ] or upgradeTable[ "RequiresFacetID" ]
            newUpgradeTable[ "DisabledWithFacetID" ] = SpecialValue[ "DisabledWithFacetID" ] or upgradeTable[ "DisabledWithFacetID" ]
            table.insert( hHero.MinorAbilityUpgrades[ szAbilityName ][ szSpecialValueName ], newUpgradeTable )
        end
    end

    CustomNetTables:SetTableValue( "minor_ability_upgrades", tostring( hHero:GetPlayerOwnerID() ), hHero.MinorAbilityUpgrades )

    PrintTable( hHero.MinorAbilityUpgrades)

    local Buff = hHero:FindModifierByName( "modifier_minor_ability_upgrades" )
    if Buff == nil then
        print( "Error - No minor ability upgrade buff!" )
        return
    end
    Buff:ForceRefresh()


    local hAbility = hHero:FindAbilityByName( upgradeTable[ "ability_name"] )
    if hAbility ~= nil then
        if hAbility:GetIntrinsicModifierName() ~= nil then
            local hIntrinsicModifier = hHero:FindModifierByName( hAbility:GetIntrinsicModifierName() )
            if hIntrinsicModifier then
                hIntrinsicModifier:ForceRefresh()
                hHero:CalculateStatBonus(true)
            end
        end
    end
end

function activate_obelisk(eventSourceIndex, args)
    local playerID = args.PlayerID
    local player = PlayerResource:GetPlayer(playerID)
    if not player or GameRules.ObeliskActivated then return end

    -- Misalnya soul = jumlah kill (ganti sesuai sistem kamu)
    local soulCount = CustomNetTables:GetTableValue("soul", tostring( playerID ) ).soul
    local playerName = PlayerResource:GetPlayerName(playerID)

    print(string.format("Obelisk activated by %s with %d souls", playerName, soulCount))

    GameRules.ObeliskActivated = true
    GameRules.ObeliskActivator = playerID
    GameRules.SoulLevel = soulCount

    CustomGameEventManager:Send_ServerToAllClients("obelisk_status_update", {
        activated = true,
        activator_id = playerID,
        activator_name = playerName,
        activator_soul = soulCount
    })
end

function cancel_obelisk(eventSourceIndex, args)
    local playerID = args.PlayerID
    if GameRules.ObeliskActivator ~= playerID then return end

    GameRules.ObeliskActivated = false
    GameRules.ObeliskActivator = nil
    GameRules.SoulLevel = nil

    local playerName = PlayerResource:GetPlayerName(playerID)

    print(string.format("Soul canceled by %s with", playerName))
    CustomGameEventManager:Send_ServerToAllClients("obelisk_status_update", {
        activated = false,
        cancelled_by = playerName
    })
end

-- Util untuk set/get custom data player
function SetCustomProperty(playerID, key, value)
    local tableName = "player_custom_properties"
    local current = CustomNetTables:GetTableValue(tableName, tostring(playerID)) or {}
    current[key] = value
    CustomNetTables:SetTableValue(tableName, tostring(playerID), current)
end

function GetCustomProperty(playerID, key)
    local tableName = "player_custom_properties"
    local current = CustomNetTables:GetTableValue(tableName, tostring(playerID)) or {}
    return current[key]
end

-- Tanda bahwa player sudah pakai buff
function MarkBuffUsed(playerID, key)
    local used = GetCustomProperty(playerID, "used_buffs") or {}
    used[key] = true
    SetCustomProperty(playerID, "used_buffs", used)
end

function IsBuffUsed(playerID, key)
    local used = GetCustomProperty(playerID, "used_buffs") or {}
    return used[key] == true
end

-- Fungsi ketika UI request data shop
function shop_request_data(eventSourceIndex, args)
    local playerID = args.PlayerID
    local coinData = CustomNetTables:GetTableValue("coin", tostring(playerID)) or { coin = 0 }
    local coins = coinData.coin

    local used_buffs = GetCustomProperty(playerID, "used_buffs") or {}

    local tdonator_expired = CustomNetTables:GetTableValue("donator_expired", tostring(playerID)) or {}
    local donator_expired_value = tdonator_expired.donator_expired_value
    local donatorTierData = CustomNetTables:GetTableValue("donator_tier", tostring(playerID)) or {}
    local donator_tier = donatorTierData.donator_tier or ""
    local donatorModData = CustomNetTables:GetTableValue("donator_modifiers", tostring(playerID)) or {}
    local donator_modifiers = donatorModData.modifiers or {}

    local serverTimeData = CustomNetTables:GetTableValue("server_time", "server_time") or {}
    local server_time = serverTimeData.epoch or 0

    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "shop_data", {
        buffs = Buffs,
        coins = coins,
        used = used_buffs,
        donator_expired = donator_expired_value,
        donator_tier = donator_tier,
        donator_modifiers = donator_modifiers,
        server_time = server_time,
        map_name = GetMapName()
    })
end

-- Fungsi ketika player klik USE buff
function shop_use_buff(eventSourceIndex, args)
    print("shop_use_buff")
    local playerID = args.PlayerID

    if GameRules.FairPlayMode then return end

    local key = args.key
    local buff = Buffs[key]
    if not buff then return end
    if not IsBuffAllowedOnMap(buff, GetMapName()) then
        print(string.format("[shop_use_buff] Buff %s tidak tersedia di map %s", tostring(key), GetMapName()))
        return
    end

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local coinData = CustomNetTables:GetTableValue("coin", tostring(playerID)) or { coin = 0 }
    local coins = coinData.coin

    if coins >= buff.price and not IsBuffUsed(playerID, key) then
        -- Tambahkan modifier buff ke hero
        print(string.format("Player %s menggunakan buff %s dengan modifier %s", PlayerResource:GetPlayerName(playerID), buff.name, buff.modifier))
        hero:AddNewModifier(hero, nil, buff.modifier, {})

        -- Kurangi koin player
        SpendPlayerCoins(playerID, buff.price)

        -- Tandai buff sudah dipakai
        MarkBuffUsed(playerID, key)

        -- Track buff usage untuk stats
        -- CustomNetTables mengembalikan string keys ("1","2",...) bukan numeric,
        -- sehingga #table = 0 dan table.insert selalu overwrite di index 1.
        -- Rebuild ke proper sequential array dulu sebelum insert.
        local buffUsageRaw = CustomNetTables:GetTableValue("buff_usage", tostring(playerID)) or {}
        local buffUsage = {}
        for _, b in pairs(buffUsageRaw) do
            table.insert(buffUsage, b)
        end
        table.insert(buffUsage, {
            key = key,
            name = buff.name,
            group = buff.group,
            level = buff.level,
            price = buff.price,
            used_at = GameRules:GetGameTime()
        })
        CustomNetTables:SetTableValue("buff_usage", tostring(playerID), buffUsage)

        -- Ambil data coin & buff terbaru
        local updatedCoins = CustomNetTables:GetTableValue("coin", tostring(playerID)).coin
        local usedBuffs = GetCustomProperty(playerID, "used_buffs") or {}

        local tdonator_expired = CustomNetTables:GetTableValue("donator_expired", tostring(playerID)) or {}
        local donator_expired_value = tdonator_expired.donator_expired_value
        local donatorTierData = CustomNetTables:GetTableValue("donator_tier", tostring(playerID)) or {}
        local donator_tier = donatorTierData.donator_tier or ""
        local donatorModData = CustomNetTables:GetTableValue("donator_modifiers", tostring(playerID)) or {}
        local donator_modifiers = donatorModData.modifiers or {}

        local serverTimeData = CustomNetTables:GetTableValue("server_time", "server_time") or {}
        local server_time = serverTimeData.epoch or 0

        -- Kirim update ke client
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "shop_data", {
            buffs = Buffs,
            coins = updatedCoins,
            used = usedBuffs,
            donator_expired = donator_expired_value,
            donator_tier = donator_tier,
            donator_modifiers = donator_modifiers,
            server_time = server_time,
            map_name = GetMapName()
        })
    end
end

function SpendPlayerCoins(playerID, coins)
    local coinData = CustomNetTables:GetTableValue("coin", tostring(playerID)) or { coin = 0 }
    print(string.format("Player %s punya %s, mengeluarkan %s koin", PlayerResource:GetPlayerName(playerID), coinData.coin, coins))
    coinData.coin = coinData.coin - coins
    print(string.format("Player %s punya %s", PlayerResource:GetPlayerName(playerID), coinData.coin))
    CustomNetTables:SetTableValue("coin", tostring(playerID), coinData)
end

function GameEventListener:init()
    print("GameEventListener:init")
    CustomGameEventManager:RegisterListener("get_hotkey_ability",get_hotkey_ability)
    CustomGameEventManager:RegisterListener("ability_book",ability_book)
    CustomGameEventManager:RegisterListener("upgrade_minor",upgrade_minor)
    CustomGameEventManager:RegisterListener("swap_ability",swap_ability)
    CustomGameEventManager:RegisterListener("activate_obelisk",activate_obelisk)
    CustomGameEventManager:RegisterListener("cancel_obelisk",cancel_obelisk)
    CustomGameEventManager:RegisterListener("shop_request_data",shop_request_data)
    CustomGameEventManager:RegisterListener("shop_use_buff",shop_use_buff)
    CustomGameEventManager:RegisterListener("reward_reroll",reward_reroll)
    CustomGameEventManager:RegisterListener("skip_round_reward",skip_round_reward)
    CustomGameEventManager:RegisterListener("choose_skipped_reward",choose_skipped_reward)
end
