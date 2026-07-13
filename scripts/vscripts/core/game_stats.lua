function CHoldoutGameMode:RegisterStatsForRound( round )
    if not IsDedicatedServer() or IsInToolsMode() or GameRules:IsCheatMode() then return end
    round = round or self._nRoundNumber or GameRules._roundnumber
    if round == nil then
        print("[RegisterStatsForRound] Skipping stats: round is nil")
        return
    end

    local AUTH_KEY = GetAuthKey()
    local SERVER_LOCATION = GetServerLocation()

    local packageLocation = SERVER_LOCATION..AUTH_KEY.."/rounds/round_"..round..".json"
    local getRequest = CreateHTTPRequestScriptVM( "GET", packageLocation)

    local difficulty = string.gsub(GetMapName(), "epic_boss_fight_", "")
    
    if self.statsSentForRound then return end
    self.statsSentForRound = true
    
    getRequest:Send( function( result )
        local decoded = {}
        if tostring(result.Body) ~= 'null' then
            decoded = json.decode(result.Body)
        else return
        end
        
        local putData = deepcopy( decoded ) or {}

        putData[difficulty] = (putData[difficulty] or 0) + 1
        
        local encoded = json.encode(putData)
        
        local putRequest = CreateHTTPRequestScriptVM( "PUT", packageLocation)
        putRequest:SetHTTPRequestRawPostBody("application/json", encoded)
        putRequest:Send( function( result ) end )
    end )
end

function CHoldoutGameMode:RegisterStatsForPlayer( playerID, bWon, bAbandon )
    -- print("RegisterStatsForPlayer", playerID, bWon, bAbandon)
    if not IsDedicatedServer() or IsInToolsMode() or GameRules:IsCheatMode() then return end
    -- send stats only once
    self.statsSentForPlayer = self.statsSentForPlayer or {}
    if self.statsSentForPlayer[playerID] then return end
    self.statsSentForPlayer[playerID] = true

    -- player stats
    local map = GetMapName()
    local statSettings = GetStatSettings()
    local AUTH_KEY = GetAuthKey()
    local SERVER_LOCATION = GetServerLocation()

    local playerMatches = {}
    local purgatorySteamIdWon = {}

    local matchId = IsInToolsMode() and RandomInt(-10000000, -1) or tonumber(tostring(GameRules:Script_GetMatchID()))
    local packageLocation = SERVER_LOCATION..AUTH_KEY.."/players/"..tostring(PlayerResource:GetSteamID(playerID))..'.json'
    local API_BASE_URL = statSettings.apiBaseUrl or "http://localhost:8000"
    local matchesServer = API_BASE_URL.."/api/"..AUTH_KEY.."/matches/"..matchId..".json"

    local getRequestPlayer = CreateHTTPRequestScriptVM( "GET", packageLocation)

    local function IsAbilityDraftStatsMap()
        return map == "epic_boss_fight_ad" or string.find(map, "_ad") ~= nil
    end

    local function GetDraftAbilityType(abilitySlot)
        if not abilitySlot then
            return nil
        end

        if string.sub(abilitySlot, 1, 4) == "base" then
            return "base"
        end

        if abilitySlot == "ultimate" or abilitySlot == "innate" or abilitySlot == "facet" then
            return abilitySlot
        end

        return nil
    end

    local function AddDraftAbility(draftAbilities, abilityName, abilitySlot, abilityType, heroOwner, slotIndex)
        if not abilityName or abilityName == "" then
            return
        end

        table.insert(draftAbilities, {
            ability_name = abilityName,
            ability_slot = abilitySlot,
            ability_type = abilityType or GetDraftAbilityType(abilitySlot),
            hero_owner = heroOwner,
            slot_index = slotIndex
        })
    end

    local function GetDraftAbilitiesForStats(nPlayerID, hero)
        local draftAbilities = setmetatable({}, json.array)

        if not IsAbilityDraftStatsMap() then
            return draftAbilities
        end

        local abilityDraftMode = GameRules.holdOut and GameRules.holdOut.abilityDraftMode
        local pickedAbilities = abilityDraftMode
            and abilityDraftMode.playersPickedAbilities
            and abilityDraftMode.playersPickedAbilities[nPlayerID]

        if pickedAbilities then
            for slotIndex, abilityData in ipairs(pickedAbilities) do
                AddDraftAbility(
                    draftAbilities,
                    abilityData.ability_name,
                    abilityData.ability_slot,
                    abilityData.ability_type,
                    abilityData.hero_owner,
                    slotIndex
                )
            end

            return draftAbilities
        end

        if hero then
            for abilityIndex = 0, hero:GetAbilityCount() - 1 do
                local ability = hero:GetAbilityByIndex(abilityIndex)
                local abilityName = ability and ability:GetAbilityName()

                if abilityName
                    and abilityName ~= ""
                    and abilityName ~= "attribute_bonus"
                    and abilityName ~= "generic_hidden"
                    and string.sub(abilityName, 1, 14) ~= "special_bonus_"
                then
                    AddDraftAbility(draftAbilities, abilityName, tostring(abilityIndex), "current", nil, abilityIndex)
                end
            end
        end

        return draftAbilities
    end

    local eventConfig = CustomNetTables:GetTableValue('choosen_difficulty', 'saved')
    if not eventConfig then return end
    local bonusMMR = eventConfig.bonus_mmr or 0
    local loseMMR = eventConfig.lose_mmr or 0
    local classDiff = eventConfig.class
    
    if bAbandon then -- an abandon was registered
        local averageMMR = 0
        local players = 0
        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
            if PlayerResource:IsValidPlayerID( nPlayerID ) then
                local decoded = CustomNetTables:GetTableValue("mmr", tostring( nPlayerID ) )
                if decoded then
                    if PlayerResource:GetConnectionState( nPlayerID ) == DOTA_CONNECTION_STATE_ABANDONED
                    or ( PlayerResource:GetConnectionState( nPlayerID ) == DOTA_CONNECTION_STATE_DISCONNECTED 
                    and PlayerResource.disconnect[nPlayerID] and PlayerResource.disconnect[nPlayerID] + 5*60 <= GameRules:GetGameTime() ) then
                    else
                        averageMMR = averageMMR + decoded.mmr
                        players = players + 1
                    end
                end
            end
        end
        averageMMR = averageMMR / players
        local playerMultiplier = 1 + ( self._MaxPlayers - HeroList:GetActiveHeroCount() ) * ( 50 / (self._MaxPlayers-1) ) / 100
        
        
        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
            if PlayerResource:IsValidPlayerID( nPlayerID ) then
                local decoded = CustomNetTables:GetTableValue("mmr", tostring( nPlayerID ) )
                local decodedBancount = CustomNetTables:GetTableValue("ban", tostring( nPlayerID ) )
                

                if decoded then
                    if PlayerResource:GetConnectionState( nPlayerID ) == DOTA_CONNECTION_STATE_ABANDONED
                    or ( PlayerResource:GetConnectionState( nPlayerID ) == DOTA_CONNECTION_STATE_DISCONNECTED 
                    and PlayerResource.disconnect[nPlayerID] and PlayerResource.disconnect[nPlayerID] + 5*60 <= GameRules:GetGameTime() ) then
                        CustomNetTables:SetTableValue("mmr", tostring( nPlayerID ), {mmr = decoded.mmr, win = 0, loss = -500 })
                        local decoded = CustomNetTables:GetTableValue("mmr", tostring( nPlayerID ) )
                    else
                        
                        if GameRules:IsCheatMode() then
                            local winMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, true ) - averageMMR)*playerMultiplier + 0.5 ) + bonusMMR
                            local lossMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, false ) - averageMMR)/playerMultiplier + 0.5 ) + loseMMR
                            CustomNetTables:SetTableValue("mmr", tostring( nPlayerID ), {mmr = decoded.mmr, win = winMMR, loss = lossMMR})
                        else
                            local winMMR = 0
                            local lossMMR = 0

                            if GetMapName() == "epic_boss_fight_normal" then
                                winMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, true ) - averageMMR)*playerMultiplier + 0.5 ) + 10
                                lossMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, false ) - averageMMR)/playerMultiplier + 0.5 )
                            elseif GetMapName() == "epic_boss_fight_hard" then
                                winMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, true ) - averageMMR)*playerMultiplier + 0.5 ) + 30
                                lossMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, false ) - averageMMR)/playerMultiplier + 0.5 ) - 20
                            elseif GetMapName() == "epic_boss_fight_challenger" then
                                winMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, true ) - averageMMR)*playerMultiplier + 0.5 ) + 50
                                lossMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, false ) - averageMMR)/playerMultiplier + 0.5 ) - 50
                            elseif GetMapName() == "epic_boss_fight_nightmare" then
                                winMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, true ) - averageMMR)*playerMultiplier + 0.5 ) + 150
                                lossMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, false ) - averageMMR)/playerMultiplier + 0.5 ) - 120
                            elseif GetMapName() == "epic_boss_fight_god" then
                                winMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, true ) - averageMMR)*playerMultiplier + 0.5 ) + 500
                                lossMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, false ) - averageMMR)/playerMultiplier + 0.5 ) - 400
                            else
                                winMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, true ) - averageMMR)*playerMultiplier + 0.5 ) + 250
                                lossMMR = math.floor( (CalculateMMRChangeForPlayer( GetMapName(), averageMMR, false ) - averageMMR)/playerMultiplier + 0.5 ) - 220
                            end

                            CustomNetTables:SetTableValue("mmr", tostring( nPlayerID ), {mmr = decoded.mmr, win = winMMR, loss = lossMMR})
                        end
                        
                        
                    end
                end
            end
        end
    end

    -- Pre-kalkulasi coin bonus god map per player (harus sebelum playerMatches dibangun)
    local godMapCoinBonus = {}
    if GetMapName() == "epic_boss_fight_god" and bWon and not bAbandon then
        for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
            if PlayerResource:IsValidPlayerID(nPlayerID) then
                godMapCoinBonus[nPlayerID] = math.random(2, 5)
            end
        end
    end

    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
        if PlayerResource:IsValidPlayerID( nPlayerID ) then
            local steam_id = tostring(PlayerResource:GetSteamID(nPlayerID))
            -- gs bisa nil kalau net table "game_stats" belum di-set untuk player ini
            local gs = CustomNetTables:GetTableValue("game_stats", tostring( nPlayerID )) or {}
            local items = {}
            -- hero bisa nil kalau player disconnect / belum pick hero saat match end
            local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)

            if hero then
                for i = 0, 8 do
                    local item = hero:GetItemInSlot(i)
                    if item then
                        table.insert(items, item:GetAbilityName())
                    else
                        table.insert(items, "")
                    end
                end
            end
            local codexData = {}
            if _G.player_ability_pool[nPlayerID] ~= nil then
                codexData = _G.player_ability_pool[nPlayerID]
            end
            local draftAbilities = GetDraftAbilitiesForStats(nPlayerID, hero)
            local function IsNilOrEmpty(t)
                return t == nil or next(t) == nil
              end
            local upgrades = hero and hero.MinorAbilityUpgrades
            local json_ability_upgrades = ""
              if not IsNilOrEmpty(upgrades) then
                local clean_upgrades = SanitizeTable(upgrades)

                json_ability_upgrades = json.encode(clean_upgrades)
              end

            local buffUsageRaw = CustomNetTables:GetTableValue("buff_usage", tostring(nPlayerID)) or {}
            -- CustomNetTables mengubah numeric key jadi string ("1","2",...)
            -- rebuild ke proper sequential array agar json.encode kirim [] bukan {}
            -- setmetatable json.array: paksa encode sebagai array meski kosong
            local buffUsage = setmetatable({}, json.array)
            local coinsSpentOnBuffs = 0
            for _, b in pairs(buffUsageRaw) do
                coinsSpentOnBuffs = coinsSpentOnBuffs + (b.price or 0)
                table.insert(buffUsage, b)
            end

            playerMatches[steam_id] = {
                hero_name = PlayerResource:GetSelectedHeroName(nPlayerID),
                kills = PlayerResource:GetKills(nPlayerID),
                deaths = PlayerResource:GetDeaths(nPlayerID),
                assists = PlayerResource:GetAssists(nPlayerID),
                spell_amp = (hero and hero:GetSpellAmplification(false) * 100) or 0,
                party_id = tostring(PlayerResource:GetPartyID(nPlayerID)),
                damage_dealt = gs.damage_dealt or 0,
                damage_taken = gs.damage_taken or 0,
                healed = gs.damage_healed or 0,
                healing = math.floor(PlayerResource:GetHealing(nPlayerID)),
                stun_duration_total = math.floor(PlayerResource:GetStuns(nPlayerID)),
                items = items,
                codex = codexData,
                draft_abilities = draftAbilities,
                gold = PlayerResource:GetGold(nPlayerID),
                level = PlayerResource:GetLevel(nPlayerID),
                total_earned_gold = PlayerResource:GetTotalEarnedGold(nPlayerID),
                total_earned_xp = PlayerResource:GetTotalEarnedXP(nPlayerID),
                total_gold_spent = PlayerResource:GetTotalGoldSpent(nPlayerID),
                armor = (hero and hero:GetPhysicalArmorValue(false)) or 0,
                -- magic_resist = (hero and hero:GetBaseMagicalResistanceValue(false)) or 0,
                health = (hero and hero:GetHealth()) or 0,
                health_regen = (hero and hero:GetHealthRegen()) or 0,
                mana = (hero and hero:GetMana()) or 0,
                mana_regen = (hero and hero:GetManaRegen()) or 0,
                attack_speed = (hero and hero:GetAttackSpeed(true)) or 0,
                attack_range = (hero and hero:GetAttackRange()) or 0,
                attack_damage = (hero and hero:GetAverageTrueAttackDamage(nil)) or 0,
                attack_damage_min = (hero and hero:GetBaseDamageMin()) or 0,
                attack_damage_max = (hero and hero:GetBaseDamageMax()) or 0,
                move_speed = (hero and hero:GetBaseMoveSpeed()) or 0,
                ability_upgrades = json_ability_upgrades,
                buffs_used = buffUsage,
                coins_spent_on_buffs = coinsSpentOnBuffs,
                coin_earned = godMapCoinBonus[nPlayerID] or 0
            }

            if GetMapName() == "epic_boss_fight_purgatory" and bWon then
                table.insert(purgatorySteamIdWon, steam_id)
            end
            
        end
    end
    
    local isEventWeekend = CustomNetTables:GetTableValue("event_weekend", "is_event_weekend")
    local serverTime = CustomNetTables:GetTableValue("server_time", "server_time")
    -- net table server_time di-populate dari HTTP ke backend saat game start.
    -- Kalau belum sempat ter-set, fallback ke 0 -- backend yang isi created_at.
    local epoch = (serverTime and serverTime.epoch) or 0

    -- Format isEventWeekend langsung jadi 1 atau 0
    local eventWeekendValue = 0
    if isEventWeekend and isEventWeekend.is_event_weekend then
        eventWeekendValue = isEventWeekend.is_event_weekend
    elseif type(isEventWeekend) == "number" then
        eventWeekendValue = isEventWeekend
    elseif type(isEventWeekend) == "boolean" then
        eventWeekendValue = isEventWeekend and 1 or 0
    end

    local matchData = {
        path_name = PATCH_NAME,
        patch_date = PATCH_DATE,
        map_name = GetMapName(),
        win = bWon,
        isEventWeekend = eventWeekendValue,
        round = self._nRoundNumber,
        class_diff = classDiff,
        game_time = math.floor(GameRules:GetDOTATime(false, false)),
        new_game_plus = self._NewGamePlus,
        players = playerMatches,
        cheat_mode = IsInToolsMode() or GameRules:IsCheatMode(),
        chat_messages = playerChats,
        created_at = epoch
    }

    local matchRequest = CreateHTTPRequestScriptVM("PUT", matchesServer)
    json.__jsontype = "object"
    matchRequest:SetHTTPRequestRawPostBody("application/json", json.encode(matchData))

    matchRequest:Send(function(result)
        local status_code = result.StatusCode

        if status_code >= 200 and status_code <= 300 then
            print("[WebApi] finished request to")

            local body = result.Body
            local ok, response_data = pcall(function() return json.decode(body) end)

            if ok and response_data then
                DeepPrint(response_data)
                print("Match ID:", response_data.match_id or "unknown")
            else
                print("⚠️ Gagal decode response:", body)
            end
        else
            print("[WebApi] failed request:")
            local error_data = result.Body and json.decode(result.Body) or {}
            DeepPrint(error_data)
        end

        print("Match result", result.StatusCode, result.Body)
    end)
    
    local mmrTable = CustomNetTables:GetTableValue("mmr", tostring( playerID ) )
    local coinData = CustomNetTables:GetTableValue("coin", tostring(playerID)) or { coin = 0 }
    local coin = coinData.coin or 0
    local banData = CustomNetTables:GetTableValue("ban", tostring(playerID))
    -- local soul = CustomNetTables:GetTableValue("soul", tostring(playerID)).soul
    local donatorTierData = CustomNetTables:GetTableValue("donator_tier", tostring(playerID)) or {}
    local donator_tier = donatorTierData.donator_tier
    local tdonator_expired = CustomNetTables:GetTableValue("donator_expired", tostring(playerID)) or {}
    local donator_expired = tdonator_expired.donator_expired
    local donator_expired_value = tdonator_expired.donator_expired_value
    local donatorModifiersData = CustomNetTables:GetTableValue("donator_modifiers", tostring(playerID)) or {}
    local donator_modifiers = donatorModifiersData.modifiers or {}
    local purgaReward = CustomNetTables:GetTableValue("purgatory_reward", tostring(playerID)) or {}
    local purga_is_active = purgaReward.is_active
    -- local vDamage_taken = CustomNetTables:GetTableValue("damage_taken", tostring( playerID ))
    -- local vDamage_dealt = CustomNetTables:GetTableValue("damage_dealt", tostring( playerID ))

    getRequestPlayer:Send( function( result )
        local putData = {}
        local wins = 0
        local currentStreak = 0
        local maxStreak = 0
        putData.wins = wins
        putData.plays = 1
        putData.currentStreak = currentStreak
        putData.maxStreak = maxStreak
        putData.bancount = (banData.bancount or 0)
        
        -- putData.damage_dealt_v1 = vDamage_dealt.damage_dealt or 0
        -- putData.damage_taken_v1 = vDamage_taken.damage_taken or 0
        
        local decoded = {}
        if tostring(result.Body) ~= 'null' then
            decoded = json.decode(result.Body)
        end

        -- Sync top-ups by merging server value with in-game delta
        local serverCoin = decoded.coin or 0
        local startingCoin = nil
        if GameRules.PlayerStartCoins then
            startingCoin = GameRules.PlayerStartCoins[playerID]
        end
        local localCoin = coin or 0
        local baselineCoin = serverCoin
        if startingCoin ~= nil then
            baselineCoin = startingCoin
        else
            baselineCoin = localCoin
        end
        local adjustedCoin = serverCoin + (localCoin - baselineCoin)
        if adjustedCoin < 0 then
            adjustedCoin = 0
        end
        putData.coin = math.floor(adjustedCoin)

        local serverDonatorTier = decoded.donator_tier or ""
        local serverDonatorExpiredValue = tonumber(decoded.donator_expired) or 0
        local baselineDonator = GameRules.PlayerStartDonatorInfo and GameRules.PlayerStartDonatorInfo[playerID] or nil

        local finalDonatorTier = donator_tier
        if baselineDonator then
            if finalDonatorTier == nil or finalDonatorTier == baselineDonator.tier then
                finalDonatorTier = serverDonatorTier
            end
        elseif finalDonatorTier == nil or finalDonatorTier == "" then
            finalDonatorTier = serverDonatorTier
        end

        local finalDonatorExpiredValue = donator_expired_value
        if baselineDonator then
            if finalDonatorExpiredValue == nil or finalDonatorExpiredValue == baselineDonator.expired_value then
                finalDonatorExpiredValue = serverDonatorExpiredValue
            end
        elseif finalDonatorExpiredValue == nil or finalDonatorExpiredValue == 0 then
            finalDonatorExpiredValue = serverDonatorExpiredValue
        end

        putData.donator_tier = finalDonatorTier or ""
        putData.donator_expired = finalDonatorExpiredValue or 0
        -- Passthrough donator_modifiers dari server (tidak dimodifikasi oleh game)
        putData.donator_modifiers = decoded.donator_modifiers or {}

        wins = (decoded.wins or 0)
        currentStreak = (decoded.currentStreak or 0)
        maxStreak = (decoded.maxStreak or 0)
        if bWon then
            wins = wins + 1
        end
        
        putData.plays = (decoded.plays or 0) + 1
        putData.wins = wins
        putData.currentStreak = currentStreak
        putData.maxStreak = maxStreak
        
        -- MMR
        putData.mmr = decoded.mmr or 3000

        -- SOUL
        putData.soul = decoded.soul or 0
        if bAbandon then
            putData.mmr = math.max( putData.mmr - 500, -1)
            mmrTable.mmr = putData.mmr
            mmrTable.win = 0
            mmrTable.loss = -500
            putData.currentStreak = 0
            putData.donator_expired = donator_expired_value

            -- Tambah bancount untuk map yang relevan saat abandon (termasuk SOUL)
            -- epic_boss_fight_god: tidak menambah bancount (sengaja dikecualikan)
            if (GetMapName() == "epic_boss_fight_nightmare"
                or GetMapName() == "epic_boss_fight_purgatory"
                or GetMapName() == "epic_boss_fight_soul")
                and not self._NewGamePlus and putData.plays > 10 then
                putData.bancount = putData.bancount + 1
            end
            
        else
            if bWon then
                local gameTime = math.floor(GameRules:GetDOTATime(false, false))
                local mmrBonusDuration = 0
                -- cek jika gametime kurang dari 20 menit
                if gameTime < 1800 then
                    mmrBonusDuration=(mmrTable.win + bonusMMR) * 1
                elseif gameTime < 2100 then
                    mmrBonusDuration=(mmrTable.win + bonusMMR) * 0.5
                elseif gameTime < 2400 then
                    mmrBonusDuration=(mmrTable.win + bonusMMR) * 0.25
                else
                    mmrBonusDuration=(mmrTable.win + bonusMMR) * 0.10
                end

                putData.mmr = putData.mmr + mmrTable.win + bonusMMR + math.floor(mmrBonusDuration)
                if purga_is_active then
                    if purgaReward.reward_type == "mmr" then
                        putData.mmr = putData.mmr + purgaReward.reward_value
                    end
                end


                -- Hitung mmr jika dari donasi tier
                if donator_expired == 0 then
                    if donator_tier == "lust" then
                        putData.mmr = putData.mmr + 100
                    elseif donator_tier == "purgatory" then
                        putData.mmr = putData.mmr + 150
                    elseif donator_tier == "paradiso" then
                        putData.mmr = putData.mmr + 200
                    elseif donator_tier == "empyrean" then
                        putData.mmr = putData.mmr + 250
                    elseif donator_tier == "imba" then
                        putData.mmr = putData.mmr + 300
                    elseif donator_tier == "nord" then
                        putData.mmr = putData.mmr + 350
                    end
                end

                -- Hitung bonus MMR dari stacked donator modifiers
                for _, mod in pairs(donator_modifiers) do
                    if type(mod) == "table" then
                        local modTier = mod.tier or ""
                        if modTier == "lust" then
                            putData.mmr = putData.mmr + 100
                        elseif modTier == "purgatory" then
                            putData.mmr = putData.mmr + 150
                        elseif modTier == "paradiso" then
                            putData.mmr = putData.mmr + 200
                        elseif modTier == "empyrean" then
                            putData.mmr = putData.mmr + 250
                        elseif modTier == "imba" then
                            putData.mmr = putData.mmr + 300
                        elseif modTier == "nord" then
                            putData.mmr = putData.mmr + 350
                        elseif modTier == "lite" then
                            putData.mmr = putData.mmr + 350
                        end
                    end
                end

                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero:HasModifier("modifier_buff_mmr_300") then
                    putData.mmr = putData.mmr + 300
                elseif hero:HasModifier("modifier_buff_mmr_250") then
                    putData.mmr = putData.mmr + 250
                elseif hero:HasModifier("modifier_buff_mmr_200") then
                    putData.mmr = putData.mmr + 200
                elseif hero:HasModifier("modifier_buff_mmr_150") then
                    putData.mmr = putData.mmr + 150
                elseif hero:HasModifier("modifier_buff_mmr_100") then
                    putData.mmr = putData.mmr + 100
                end

                -- bonus mmr jika main di purgatory
                if GetMapName() == "epic_boss_fight_purgatory" and self:TeamCount() >= 4 then
                    if classDiff == "S1" then
                        putData.mmr = putData.mmr + 1000
                    elseif classDiff == "S2" then
                        putData.mmr = putData.mmr + 2000
                    elseif classDiff == "S3" then
                        putData.mmr = putData.mmr + 3000
                    elseif classDiff == "S4" then
                        putData.mmr = putData.mmr + 4000
                    elseif classDiff == "S5" then
                        putData.mmr = putData.mmr + 8000
                    end
                end

                -- bonus mmr dan coin jika menang di god map
                if GetMapName() == "epic_boss_fight_god" then
                    putData.mmr = putData.mmr + 500
                    local coinBonus = godMapCoinBonus[playerID] or 0
                    if coinBonus > 0 then
                        putData.coin = putData.coin + coinBonus
                        local coinData = CustomNetTables:GetTableValue("coin", tostring(playerID)) or { coin = 0 }
                        coinData.coin = (coinData.coin or 0) + coinBonus
                        CustomNetTables:SetTableValue("coin", tostring(playerID), coinData)
                    end
                    print(string.format("[GOD MAP] Player %d menang: +500 MMR, +%d coin", playerID, coinBonus))
                end

                mmrTable.mmr = putData.mmr
                mmrTable.loss = 0

                -- jika main di normal map, maka winrate tidak ditambah
                if GetMapName() == "epic_boss_fight_normal" then
                    putData.currentStreak = currentStreak
                else
                    putData.currentStreak = currentStreak + 1
                    -- jika current streak sama dengan max streak, update max streak = current streak
                    if putData.currentStreak >= maxStreak or putData.currentStreak == maxStreak then
                        putData.maxStreak = putData.currentStreak
                    end
                end

                if IsAbilityDraftStatsMap() then
                    local currentSoul = putData.soul or 0
                    putData.soul = currentSoul + 1
                    print("[AD SOUL SYSTEM] Soul naik:", currentSoul, "->", putData.soul)
                elseif map == "epic_boss_fight_soul" then
                    local activeKey = GameRules.SoulLevel or 0
                    local currentKey = putData.soul or 0

                    -- Tambah key hanya jika key pemain ≤ key obelisk
                    if currentKey <= activeKey then
                        putData.soul = currentKey + 1
                        print("[KEY SYSTEM] Key Naik:", currentKey, "->", putData.soul)
                    else
                        print("[KEY SYSTEM] Tidak naik key (di atas obelisk):", currentKey)
                    end
                end

            else
                putData.mmr = math.max( putData.mmr + mmrTable.loss + loseMMR, 0 )
                mmrTable.mmr = putData.mmr
                mmrTable.win = 0

                -- current streak -1
                putData.currentStreak = 0

                -- loss mmr purgatory berdasarkan class (~20% dari win)
                if GetMapName() == "epic_boss_fight_purgatory" and self:TeamCount() >= 4 then
                    local purgaLoss = 0
                    if classDiff == "S1" then
                        purgaLoss = -200
                    elseif classDiff == "S2" then
                        purgaLoss = -400
                    elseif classDiff == "S3" then
                        purgaLoss = -600
                    elseif classDiff == "S4" then
                        purgaLoss = -800
                    elseif classDiff == "S5" then
                        purgaLoss = -1600
                    end
                    putData.mmr = math.max( putData.mmr + purgaLoss, 0 )
                    mmrTable.mmr = putData.mmr
                    mmrTable.loss = mmrTable.loss + purgaLoss
                    print(string.format("[PURGATORY] Player %d kalah class %s: %d MMR", playerID, tostring(classDiff), purgaLoss))
                end

                -- SOUL SYSTEM (jika mode soul)
                if IsAbilityDraftStatsMap() then
                    local currentSoul = putData.soul or 0
                    putData.soul = math.max(currentSoul - 1, 0)
                    print("[AD SOUL SYSTEM] Soul turun:", currentSoul, "->", putData.soul)
                elseif map == "epic_boss_fight_soul" then
                    if putData.soul and putData.soul > 1 then
                        putData.soul = putData.soul - 1
                        print("[SOUL SYSTEM] Soul turun jadi", putData.soul)
                    else
                        print("[SOUL SYSTEM] Soul tidak bisa kurang dari 1 (sekarang:", putData.soul, ")")
                    end
                end

                
            end
            
            if IsInToolsMode() or GameRules:IsCheatMode() then
                putData.plays = (decoded.plays or 0)
                putData.wins = wins
                putData.currentStreak = currentStreak
                putData.maxStreak = maxStreak
                putData.bancount = banData.bancount or 0
                putData.mmr = decoded.mmr or 300
                putData.soul = decoded.soul or 0
                putData.damage_dealt_v1 = putData.damage_dealt_v1
                putData.damage_taken_v1 = putData.damage_taken_v1
            end
        end
        
        -- if PlayerResource.abandoned_player_hero_selection[playerID] then
        --     putData.plays = (decoded.plays or 0)
        --     putData.wins = (decoded.wins or 0)
        --     putData.currentStreak = (decoded.currentStreak or 0)
        --     putData.maxStreak = (decoded.maxStreak or 0)
        --     putData.bancount = banData.bancount or 0
        --     putData.mmr = decoded.mmr or 3000
        -- end

        local encoded = json.encode(putData)
        local putRequest = CreateHTTPRequestScriptVM( "PUT", packageLocation)
        putRequest:SetHTTPRequestRawPostBody("application/json", encoded)
        putRequest:Send( function( result )
            CustomNetTables:SetTableValue("mmr", tostring( playerID ), mmrTable)
        end )
    end )

    local eventConfig = CustomNetTables:GetTableValue('choosen_difficulty', 'saved')
    local diff = eventConfig.class
    if bWon and GetMapName() == "epic_boss_fight_purgatory" and self:TeamCount() >= 4 then
        local steamId = tostring(PlayerResource:GetSteamID(playerID))
        print(string.format("steamId: %s plyerID: %s", steamId, playerID))
        registerPurgatory(steamId, diff)
    end

end

function registerPurgatory(steamId, diff)
    print("registerPurgatory di diff " .. diff)
    local AUTH_KEY = GetAuthKey()
    local SERVER_LOCATION = GetServerLocation()

    -- FIX: Path harus tanpa diff, karena semua diff disimpan dalam satu file JSON
    local winnerJsonLocation = SERVER_LOCATION..AUTH_KEY.."/purgatory/winner/"..tostring(steamId)..'.json'

    local timeUrl = "https://ebfimba.lintangtimur915.workers.dev/"
    local httpRequest = CreateHTTPRequestScriptVM("GET", timeUrl)

    httpRequest:Send(function(result)
        if result.StatusCode ~= 200 then
            print("Gagal mendapatkan waktu dari server waktu.")
            return
        end

        local body = result.Body
        local data = json.decode(body)

        if not data or not data.year then
            print("Response waktu tidak valid")
            return
        end

        local grantedAt = tonumber(data.epochTimestamp) -- waktu sekarang dalam detik
        local expiresAt = grantedAt + (7 * 24 * 60 * 60) -- tambah 7 hari (detik)

        -- FIX: Load data player yang sudah ada
        local getRequest = CreateHTTPRequestScriptVM("GET", winnerJsonLocation)
        getRequest:Send(function(winnerResult)
            local winnerData = {}

            -- Load existing data jika ada
            if winnerResult.StatusCode == 200 and tostring(winnerResult.Body) ~= 'null' then
                winnerData = json.decode(winnerResult.Body) or {}
                if winnerData[diff] and winnerData[diff].winner == true then
                    print(string.format("Player %s sudah pernah menang di %s, akan refresh timestamp", steamId, diff))
                else
                    print(string.format("Data winner existing ditemukan, akan tambah key %s", diff))
                end
            else
                print(string.format("Data winner belum ada, akan create baru untuk diff %s", diff))
            end

            -- FIX: Selalu update/tambah key untuk diff yang baru menang (refresh timestamp jika sudah ada)
            winnerData[diff] = {
                winner = true,
                granted_at = grantedAt,
                expires_at = expiresAt
            }

            -- Upload balik winner.json dengan data yang sudah diupdate
            local saveRequest = CreateHTTPRequestScriptVM("PUT", winnerJsonLocation)
            saveRequest:SetHTTPRequestHeaderValue("Content-Type", "application/json")
            saveRequest:SetHTTPRequestRawPostBody("application/json", json.encode(winnerData))
            saveRequest:Send(function(saveResult)
                if saveResult.StatusCode == 200 then
                    print(string.format("Berhasil menyimpan winner %s untuk diff %s", steamId, diff))
                else
                    print(string.format("Gagal menyimpan winner %s untuk diff %s", steamId, diff))
                end
            end)
        end)
    end)
end


function isPurgatoryWinner(steamId, callback)
    local AUTH_KEY = GetAuthKey()
    local SERVER_LOCATION = GetServerLocation()

    local playerDataLocation = SERVER_LOCATION .. AUTH_KEY .. "/purgatory/winner/" .. tostring(steamId) .. ".json"

    local getRequest = CreateHTTPRequestScriptVM("GET", playerDataLocation)
    getRequest:Send(function(result)
        if result.StatusCode == 200 and tostring(result.Body) ~= 'null' then
            local data = json.decode(result.Body)
            if type(data) == "table" then
                -- Ambil waktu server untuk validasi expiry
                local timeUrl = "https://ebfimba.lintangtimur915.workers.dev/"
                local timeRequest = CreateHTTPRequestScriptVM("GET", timeUrl)

                timeRequest:Send(function(timeResult)
                    local currentTime = 0
                    if timeResult.StatusCode == 200 then
                        local timeData = json.decode(timeResult.Body)
                        currentTime = tonumber(timeData.epochTimestamp) or 0
                    end

                    -- Loop dari S5 ke S1 untuk cari diff tertinggi yang masih valid
                    for i = 5, 1, -1 do
                        local key = "S" .. i
                        -- FIX: Cek apakah data[key] adalah object dan memiliki winner = true
                        if data[key] and type(data[key]) == "table" and data[key].winner == true then
                            -- FIX: Validasi apakah winner status masih aktif (belum expired)
                            local expiresAt = tonumber(data[key].expires_at) or 0
                            if currentTime > 0 and expiresAt > 0 then
                                if currentTime <= expiresAt then
                                    print(string.format("Player %s adalah winner di %s (valid until %d)", steamId, key, expiresAt))
                                    callback(true, key)
                                    return
                                else
                                    print(string.format("Player %s pernah menang di %s tapi sudah expired", steamId, key))
                                end
                            else
                                -- Jika tidak ada waktu, return winner tanpa validasi expiry
                                print(string.format("Player %s adalah winner di %s (no time validation)", steamId, key))
                                callback(true, key)
                                return
                            end
                        end
                    end

                    -- Tidak ada winner status yang valid ditemukan
                    callback(false, nil)
                end)
                return
            end
        end
        callback(false, nil)
    end)
end
