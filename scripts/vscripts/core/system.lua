function CheckJakartaTime()
    local url = "https://ebfimba.lintangtimur915.workers.dev/"
    local request = CreateHTTPRequestScriptVM("GET", url)

    request:Send(function(result)
        if result.StatusCode == 200 then
            -- Parsing JSON response
            local data = json.decode(result.Body)
            local currentEpoch = tonumber(data.epochTimestamp)

            if data and data.dayOfWeek then
                print("📆 Hari ini: " .. data.dayOfWeek)
                CustomNetTables:SetTableValue("server_time", "server_time", {epoch= currentEpoch})
                -- Cek apakah hari Jumat, Sabtu, atau Minggu
                if data.dayOfWeek == "Friday" or data.dayOfWeek == "Saturday" or data.dayOfWeek == "Sunday" then
                    print("✅ Hari event! (" .. data.dayOfWeek .. ")")
                    FetchEventData()
                else
                    print("❌ Bukan hari event. (" .. data.dayOfWeek .. ")")
                    CustomNetTables:SetTableValue("event_weekend", "is_event_weekend", { is_event_weekend = false })
                end
            else
                print("❌ Gagal parsing JSON atau field tidak ditemukan")
                CustomNetTables:SetTableValue("event_weekend", "is_event_weekend", {
                    is_event_weekend = false,
                    event_type = nil,
                    multiplier = 1
                })
            end
        else
            print("❌ Request Gagal! Status Code: " .. tostring(result.StatusCode))
            CustomNetTables:SetTableValue("event_weekend", "is_event_weekend", { is_event_weekend = false, event_type = nil, multiplier = 1 })
        end
    end)
end

function FetchEventData()

    local AUTH_KEY = GetAuthKey()
    local SERVER_LOCATION = GetServerLocation()

    local packageLocation = SERVER_LOCATION..AUTH_KEY.."/event.json"
    local request = CreateHTTPRequestScriptVM( "GET", packageLocation)


    request:Send(function(result)
        if result.StatusCode == 200 then
            local event_data = json.decode(result.Body)

            if event_data and event_data.kv_event and event_data.kv_multiplier then
                print("🎉 Event Weekend: " .. event_data.kv_event .. " (x" .. event_data.kv_multiplier .. ")")

                -- Simpan event ke NetTable
                CustomNetTables:SetTableValue("event_weekend", "is_event_weekend", {
                    is_event_weekend = true,
                    event_type = event_data.kv_event,
                    multiplier = event_data.kv_multiplier
                })

                -- Kirim pesan ke semua pemain
                GameRules:SendCustomMessage("🔥 Weekend Event! <font color='#42f551'>" .. event_data.kv_event_message .. "</font>", 0, 0)
            else
                CustomNetTables:SetTableValue("event_weekend", "is_event_weekend", {
                    is_event_weekend = true,
                    event_type = nil,
                    multiplier = 1
                })
                print("❌ Gagal parsing data event atau field tidak ditemukan")
            end
        else
            CustomNetTables:SetTableValue("event_weekend", "is_event_weekend", {
                is_event_weekend = true,
                event_type = nil,
                multiplier = 1
            })
            print("❌ Request ke Firebase Gagal! Status Code: " .. tostring(result.StatusCode))
        end
    end)
end

local _guild_leaderboard_fetched = false
function FetchGuildLeaderboard()
    if _guild_leaderboard_fetched then return end
    _guild_leaderboard_fetched = true

    local settings = GetStatSettings()
    local baseUrl = settings.apiBaseUrl or "https://ebfimba.stelincore.com"
    local url = baseUrl .. "/api/guilds/leaderboard"
    local request = CreateHTTPRequestScriptVM("GET", url)
    request:Send(function(result)
        if result.StatusCode == 200 then
            local data = json.decode(result.Body)
            if data and data.guilds then
                local tableData = {}
                for i, guild in ipairs(data.guilds) do
                    tableData[tostring(i)] = {
                        rank         = guild.rank,
                        name         = guild.name,
                        tag          = guild.tag,
                        experience   = guild.experience,
                        level        = guild.level,
                        rank_name    = guild.rank_name,
                        member_count = guild.member_count,
                        logo         = guild.logo or "",
                    }
                end
                CustomNetTables:SetTableValue("game_state", "leaderboard_guild", tableData)
                print(string.format("[GuildLeaderboard] Fetched %d guilds", #data.guilds))
            end
        else
            print(string.format("[GuildLeaderboard] Fetch failed: HTTP %d", result.StatusCode))
        end
    end)
end

local _supporter_pricing_fetched = false
function FetchSupporterStorePricing()
	if _supporter_pricing_fetched then return end
	_supporter_pricing_fetched = true

	local settings = GetStatSettings()
	local baseUrl = settings.apiBaseUrl or "https://ebfimba.stelincore.com"
	local url = baseUrl .. "/api/store/supporter-pricing"
	local request = CreateHTTPRequestScriptVM("GET", url)
	request:SetHTTPRequestHeaderValue("Accept", "application/json")
	request:SetHTTPRequestHeaderValue("User-Agent", "Dota2CustomGame/EBF")

	request:Send(function(result)
		if result.StatusCode ~= 200 then
			print(string.format("[SupporterPricing] Fetch failed: HTTP %s", tostring(result.StatusCode)))
			CustomNetTables:SetTableValue("supporter_store", "pricing", { available = 0 })
			return
		end

		local ok, decoded = pcall(json.decode, result.Body or "")
		if not ok or type(decoded) ~= "table" or not decoded.featured then
			print("[SupporterPricing] Bad response")
			CustomNetTables:SetTableValue("supporter_store", "pricing", { available = 0 })
			return
		end

		local featured = decoded.featured
		CustomNetTables:SetTableValue("supporter_store", "pricing", {
			available = 1,
			name = tostring(featured.name or "Supporter"),
			firebase_key = tostring(featured.firebase_key or ""),
			duration_days = tonumber(featured.duration_days) or 30,
			original_price_usd = tonumber(featured.original_price) or 0,
			final_price_usd = tonumber(featured.final_price) or 0,
			discount_applied = featured.discount_applied and 1 or 0,
			discount_percentage = tonumber(featured.discount_percentage) or 0,
			store_url = tostring(decoded.store_url or "https://ebfimba.stelincore.com/store"),
		})

		print(string.format("[SupporterPricing] %s $%.2f/%dd",
			tostring(featured.name or "Supporter"),
			tonumber(featured.final_price) or 0,
			tonumber(featured.duration_days) or 30))
	end)
end

function init_player_ability_pool()
    for i,j in pairs(LIST_ABILITIES)do
        table.insert(_G.all_ability_pool,j)
    end
end

function IsPlayerBanned(playerID, decoded)
    
    local playerSteamID = PlayerResource:GetSteamID(playerID)
    
    local bancount = decoded.bancount or 0
    
    -- Memeriksa apakah ban masih berlaku
    if bancount > 0 then
        print(string.format("Player %s is banned, bancount  %d", playerSteamID, bancount))
        return true, bancount
    end
    return nil, bancount
    
end

function ShowPurgatoryPopupToAllPlayers()
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if PlayerResource:IsValidPlayerID(playerID) then
            CustomGameEventManager:Send_ServerToPlayer(
                PlayerResource:GetPlayer(playerID),
                "show_purgatory_popup",
                {}
            )
        end
    end
end

function top10MMR(leaderboard, targetSteamID)
    if type(leaderboard) ~= "table" then
        return false, nil
    end

    local targetSteamIDStr = tostring(targetSteamID)
    
    for i, player in pairs(leaderboard) do
        if player.steamID == targetSteamIDStr and tonumber(i) <= 10 then
            return true, player -- Mengembalikan true dan data player jika ditemukan
        end
    end
    return false, nil -- Mengembalikan false jika tidak ditemukan
end

function isSteamIDInTop5Leaderboard(top5Leaderboard, targetSteamID)
    return top5Leaderboard[targetSteamID] ~= nil  -- Cek apakah steamID ada di dalam tabel
end


function MapWearables()
    GameRules.items = LoadKeyValues("scripts/items/items_game.txt")['items']
    GameRules.modelmap = {}
    for k,v in pairs(GameRules.items) do
        if v.name and v.prefab ~= "loading_screen" then
            GameRules.modelmap[v.name] = k
        end
    end
end

function GenerateDefaultBlock( heroName )
    print("    \"Creature\"")
    print("    {")
    print("        \"AttachWearables\" ".."// Default "..heroName)
    print("        {")
    local defCount = 1
    for code,values in pairs(GameRules.items) do
        if values.name and values.prefab == "default_item" and values.used_by_heroes then
            for k,v in pairs(values.used_by_heroes) do
                if k == heroName then
                    local itemID = GameRules.modelmap[values.name]
                    GenerateItemDefLine( defCount, itemID, values.name )
                    defCount = defCount + 1
                end
            end
        end
    end
    print("        }")
    print("    }")
end
 
function GenerateBundleBlock( setname )
    local bundle = {}
    for code,values in pairs(GameRules.items) do
        if values.name and values.name == setname and values.prefab and values.prefab == "bundle" then
            bundle = values.bundle
        end
    end

    print("    \"Creature\"")
    print("    {")
    print("        \"AttachWearables\" ".."// "..setname)
    print("        {")
    local wearableCount = 1
    for k,v in pairs(bundle) do
        local itemID = GameRules.modelmap[k]
        if itemID then
            GenerateItemDefLine(wearableCount, itemID, k)
            wearableCount = wearableCount+1
        end
    end
    print("        }")
    print("    }")
end
 
function GenerateItemDefLine( i, itemID, comment )
    print("            \""..tostring(i).."\" { ".."\"ItemDef\" \""..itemID.."\" } // "..comment)
end

function GetRewardByMMR(player_mmr)
    local best_mmr = nil

    for required_mmr, _ in pairs(RewardList) do
        if player_mmr >= required_mmr then
            if not best_mmr or required_mmr > best_mmr then
                best_mmr = required_mmr
            end
        end
    end

    if best_mmr then
        return RewardList[best_mmr]
    else
        return nil
    end
end

-- Resolve effective config (weight + guaranteed_window) untuk satu item,
-- dengan mempertimbangkan map_overrides jika ada.
local function GetBaseStatEffectiveConfig(item, mapName)
	local weight = item.weight or 1
	local guaranteed_window = item.guaranteed_window

	local ov = item.map_overrides and item.map_overrides[mapName]
	if ov then
		if ov.weight ~= nil then
			weight = ov.weight
		end
		if ov.guaranteed_window == false then
			guaranteed_window = nil
		elseif ov.guaranteed_window ~= nil then
			guaranteed_window = ov.guaranteed_window
		end
	end

	return { weight = weight, guaranteed_window = guaranteed_window }
end

-- Pilih 1 base stat dari pool dengan sistem guarantee + weighted random.
-- hero.BaseStatsGuaranteedOffered dipakai untuk tracking per-game per-hero.
local function PickBaseStat(pool, hero, currentRound, mapName)
	if not hero.BaseStatsGuaranteedOffered then
		hero.BaseStatsGuaranteedOffered = {}
	end

	-- Kumpulkan kandidat guaranteed: punya window yang mencakup round ini dan belum pernah ditawarkan
	local guaranteedCandidates = {}
	for _, item in ipairs(pool) do
		local cfg = GetBaseStatEffectiveConfig(item, mapName)
		local gw = cfg.guaranteed_window
		if gw and currentRound >= gw[1] and currentRound <= gw[2] then
			local key = item.tracking_key or item.special_value_name
			if not hero.BaseStatsGuaranteedOffered[key] then
				table.insert(guaranteedCandidates, item)
			end
		end
	end

	if #guaranteedCandidates > 0 then
		local picked = guaranteedCandidates[RandomInt(1, #guaranteedCandidates)]
		local key = picked.tracking_key or picked.special_value_name
		hero.BaseStatsGuaranteedOffered[key] = true
		print(string.format("[BaseStat] Guaranteed pick: %s (round %d, map %s)", picked.special_value_name, currentRound, mapName))
		return picked
	end

	-- Weighted random: duplikasi item sesuai weight lalu pilih acak
	local weightedPool = {}
	for _, item in ipairs(pool) do
		-- Skip item once_per_match yang sudah pernah ditawarkan
		local key = item.tracking_key or item.special_value_name
		if item.once_per_match and hero.BaseStatsGuaranteedOffered[key] then
			-- skip
		else
			local cfg = GetBaseStatEffectiveConfig(item, mapName)
			for _ = 1, cfg.weight do
				table.insert(weightedPool, item)
			end
		end
	end
	local picked = weightedPool[RandomInt(1, #weightedPool)]
	if picked.once_per_match then
		local key = picked.tracking_key or picked.special_value_name
		hero.BaseStatsGuaranteedOffered[key] = true
	end
	print(string.format("[BaseStat] Weighted random pick: %s (round %d, map %s)", picked.special_value_name, currentRound, mapName))
	return picked
end

local REWARD_TIER_MULTIPLIERS = {imba = 3, nord = 3}
local ROUND_REWARD_SUPPORTER_TIERS = {imba = true, nord = true, lite = true}
local ROUND_REWARD_REROLL_CHARGES = {imba = 2, nord = 2, lite = 5}

function IsRoundRewardSupporter(playerID)
	local tierData    = CustomNetTables:GetTableValue("donator_tier", tostring(playerID)) or {}
	local expiredData = CustomNetTables:GetTableValue("donator_expired", tostring(playerID)) or {}
	local tier        = tierData.donator_tier
	local expired     = expiredData.donator_expired
	if expired == 0 and ROUND_REWARD_SUPPORTER_TIERS[tier] then
		return true
	end

	local modData = CustomNetTables:GetTableValue("donator_modifiers", tostring(playerID))
	if modData and modData.modifiers then
		for _, mod in pairs(modData.modifiers) do
			if mod and ROUND_REWARD_SUPPORTER_TIERS[mod.tier] then
				return true
			end
		end
	end

	return false
end

function GetRerollCharges(playerID)
	local tierData    = CustomNetTables:GetTableValue("donator_tier", tostring(playerID)) or {}
	local expiredData = CustomNetTables:GetTableValue("donator_expired", tostring(playerID)) or {}
	local bestCharges = 0

	if expiredData.donator_expired == 0 and ROUND_REWARD_REROLL_CHARGES[tierData.donator_tier] then
		bestCharges = ROUND_REWARD_REROLL_CHARGES[tierData.donator_tier]
	end

	local modData = CustomNetTables:GetTableValue("donator_modifiers", tostring(playerID))
	if modData and modData.modifiers then
		for _, mod in pairs(modData.modifiers) do
			local charges = mod and ROUND_REWARD_REROLL_CHARGES[mod.tier]
			if charges and charges > bestCharges then
				bestCharges = charges
			end
		end
	end

	return bestCharges
end

function WriteRoundRewardsNetTable(playerID, upgrade_ability)
	local netData = {}
	for i, item in pairs(upgrade_ability) do
		netData[tostring(i)] = item
	end
	_G.player_rerolls = _G.player_rerolls or {}
	netData["info"] = {
		rerolls  = _G.player_rerolls[playerID] or 0,
		chest_id = DoUniqueString("chest_" .. tostring(playerID))
	}
	CustomNetTables:SetTableValue("round_rewards", tostring(playerID), netData)
end

function ClearRoundRewardsNetTable(playerID)
	CustomNetTables:SetTableValue("round_rewards", tostring(playerID), {})
end

function GetRewardMultiplier(playerID, specialValueName)
	local S_DIFF = 2
	local mapName = GetMapName()

	local fairPlayData = CustomNetTables:GetTableValue("game_stats", "fair_play_mode")
	local isFairPlay = fairPlayData and fairPlayData.enabled == 1

	local donatorMult = 1
	if not isFairPlay and mapName ~= "epic_boss_fight_purgatory" then
		local donatorData = CustomNetTables:GetTableValue("donator_tier", tostring(playerID))
		local donatorTier = donatorData and donatorData.donator_tier
		local expiredData = CustomNetTables:GetTableValue("donator_expired", tostring(playerID))
		local donatorExpired = expiredData and expiredData.donator_expired
		-- donator_expired == 0 berarti masih aktif (bukan nil/1); Lua: not 0 = false, jadi harus cek eksplisit
		if donatorExpired == 0 and donatorTier and REWARD_TIER_MULTIPLIERS[donatorTier] then
			donatorMult = REWARD_TIER_MULTIPLIERS[donatorTier]
		end
		local modData = CustomNetTables:GetTableValue("donator_modifiers", tostring(playerID))
		if modData and modData.modifiers then
			for _, mod in pairs(modData.modifiers) do
				if mod and mod.tier and REWARD_TIER_MULTIPLIERS[mod.tier] and REWARD_TIER_MULTIPLIERS[mod.tier] > donatorMult then
					donatorMult = REWARD_TIER_MULTIPLIERS[mod.tier]
				end
			end
		end
	end

	local x5Mult = 1
	if not isFairPlay and mapName == "epic_boss_fight_god" then
		local modData = CustomNetTables:GetTableValue("donator_modifiers", tostring(playerID))
		if modData and modData.modifiers then
			for _, mod in pairs(modData.modifiers) do
				if mod and mod.tier == "reward_x5" then x5Mult = 5; break end
			end
		end
	end

	local coinMult = 1
	local propData = CustomNetTables:GetTableValue("player_custom_properties", tostring(playerID))
	if propData and propData.used_buffs and propData.used_buffs.s_reward_x3 then
		coinMult = 3
	end

	local eventMult = 1
	if specialValueName and mapName ~= "epic_boss_fight_purgatory" then
		local eventData = CustomNetTables:GetTableValue("event_weekend", "is_event_weekend")
		if eventData and eventData.is_event_weekend then
			local isDamage = string.find(specialValueName, "damage")
			local isPercent = string.find(specialValueName, "percent") or string.find(specialValueName, "pct")
			if isDamage and not isPercent then
				eventMult = tonumber(eventData.multiplier) or 1
			end
		end
	end

	return S_DIFF * eventMult * donatorMult * coinMult * x5Mult
end


function PickGenericUpgrade(genericUpgradesPool, hero)
	require("generic_upgrades/generic_system")
	return GenericUpgrades:PickReward(hero)
end

local function PickGenericRewardWithFallback(baseStatsPool, hero, currentRound, mapName)
	require("generic_upgrades/generic_system")

	local genericUpgrade = PickGenericUpgrade(nil, hero)
	if genericUpgrade then
		return genericUpgrade
	end

	return PickBaseStat(baseStatsPool, hero, currentRound, mapName)
end

local function IsAbilityDraftMap()
	local mapName = GetMapName() or ""
	return mapName == "epic_boss_fight_ad" or string.find(mapName, "_ad") ~= nil
end

local function AddAbilityUpgradesToRewardPool(abilityNames, rewardPool, inserted)
	if type(abilityNames) ~= "table" then return end

	for _, heroUpgrades in pairs(_G.MINOR_ABILITY_UPGRADES or {}) do
		if type(heroUpgrades) == "table" then
			for _, upgrade in pairs(heroUpgrades) do
				local abilityName = upgrade and upgrade.ability_name
				if abilityName and abilityNames[abilityName] then
					local uniqueKey = abilityName .. "|" .. tostring(upgrade.special_value_name) .. "|" .. tostring(upgrade.description) .. "|" .. tostring(upgrade.value)
					if not inserted[uniqueKey] then
						inserted[uniqueKey] = true
						table.insert(rewardPool, upgrade)
					end
				end
			end
		end
	end
end

local function GetDraftPickedAbilityNames(hero)
	local playerID = hero:GetPlayerOwnerID()
	local abilityDraftMode = GameRules.holdOut and GameRules.holdOut.abilityDraftMode
	local pickedAbilities = abilityDraftMode and abilityDraftMode.playersPickedAbilities and abilityDraftMode.playersPickedAbilities[playerID]
	local abilityNames = {}

	if type(pickedAbilities) ~= "table" then
		return abilityNames
	end

	for _, abilityData in pairs(pickedAbilities) do
		local abilityName = abilityData and abilityData.ability_name
		if abilityName and abilityName ~= "" then
			abilityNames[abilityName] = true
		end
	end

	return abilityNames
end

local function GetCurrentHeroAbilityRewardPool(hero, isAbilityDraftMap)
	local currentAbilities = {}

	if isAbilityDraftMap then
		currentAbilities = GetDraftPickedAbilityNames(hero)
	end

	if not next(currentAbilities) then
		local abilityCount = hero:GetAbilityCount()

		for i = 0, abilityCount - 1, 1 do
			local ability = hero:GetAbilityByIndex(i)
			if ability and not ability:IsAttributeBonus() then
				local abilityName = ability:GetAbilityName()
				if abilityName and abilityName ~= "" and abilityName ~= "generic_hidden" and not string.find(abilityName, "special_bonus") then
					currentAbilities[abilityName] = true
				end
			end
		end
	end

	local rewardPool = {}
	local inserted = {}
	AddAbilityUpgradesToRewardPool(currentAbilities, rewardPool, inserted)

	return rewardPool
end

function showRewards(hero)
	local heroName = hero:GetUnitName()

	EmitSoundOn("NeutralLootDrop.TierComplete", hero)

	local upgrade_ability = {}
	local heroUpgradePool = {}
	local isAbilityDraftMap = IsAbilityDraftMap()

	if isAbilityDraftMap then
		heroUpgradePool = GetCurrentHeroAbilityRewardPool(hero, true)
	end

	if not isAbilityDraftMap and #heroUpgradePool == 0 and _G.MINOR_ABILITY_UPGRADES[heroName] then
		for k, v in pairs(_G.MINOR_ABILITY_UPGRADES[heroName]) do
			table.insert(heroUpgradePool, v)
		end
	end

	local base_stats_upgrades_pool = require("minor_ability_upgrades/base_minor_stats_upgrades")
	require("generic_upgrades/generic_system")
	require("special_upgrades/special_upgrade_system")

	local MAX_UPGRADE_LIMITS = {
		["disruptor_static_storm"] = {
			radius = 5,
		},
        ["imba_enigma_midnight_pulse"] = {
            radius = 5,
            pull_strength = 5,
        },
        ["doom_bringer_scorched_earth"] = {
            damage_per_second = 10,
        },
        ["imba_bloodseeker_blood_bath"] = {
            damage = 5,
            dmg_to_overheal = 5
        },
        ["doom_bringer_infernal_blade"] = {
            burn_damage = 5,
        },
        ["undying_decay"] = {
            decay_damage = 10
        },
        ["sniper_concussive_grenade"] = {
            damage = 5
        },
        ["tinker_rearm"] = {
            AbilityChannelTime = 5
        },
        ["ursa_enrage"] = {
            duration = 2,
        }
		-- tambahkan skill lain di sini jika perlu
	}

	local function CountMinorUpgrades(hero, ability_name, special_value)
		local upgrades = hero.MinorAbilityUpgrades or {}
		if upgrades[ability_name] and upgrades[ability_name][special_value] then
			local count = 0
			for _, _ in pairs(upgrades[ability_name][special_value]) do
				count = count + 1
			end
			return count
		end
		return 0
	end

	local safetyCounter = 50

	while #upgrade_ability < 3 and #heroUpgradePool > 0 and safetyCounter > 0 do
		safetyCounter = safetyCounter - 1

		local popIndex = RandomInt(1, #heroUpgradePool)
		local pop = table.remove(heroUpgradePool, popIndex)

		if not pop then break end

		local shouldSkip = false

		-- Morphling conflict check
		if hero:HasAbility("morphling_primordial_form") then
			if pop.ability_name == "morphling_equalize" and (
				pop.special_value_name == "bonus_strength" or
				pop.special_value_name == "bonus_agility" or
				pop.special_value_name == "bonus_evasion"
			) then
				shouldSkip = true
				print(string.format("[Upgrade Reward] Skip for Morphling with primordial_form: %s %s", pop.ability_name, pop.special_value_name))
			end
		end

		if hero:HasAbility("morphling_equalize") then
			if pop.ability_name == "morphling_primordial_form" and (
				pop.special_value_name == "damage_bonus_pct_per_attribute" or
				pop.special_value_name == "attack_speed_bonus_per_agility" or
				pop.special_value_name == "mana_regen_per_intelligence" or
				pop.special_value_name == "damage_reduction_pct"
			) then
				shouldSkip = true
				print(string.format("[Upgrade Reward] Skip for Morphling with equalize: %s %s", pop.ability_name, pop.special_value_name))
			end
		end

		-- Upgrade limit check
		local maxLimit = MAX_UPGRADE_LIMITS[pop.ability_name] and MAX_UPGRADE_LIMITS[pop.ability_name][pop.special_value_name]
		if maxLimit then
			local currentCount = CountMinorUpgrades(hero, pop.ability_name, pop.special_value_name)
			if currentCount >= maxLimit then
				shouldSkip = true
				print(string.format("[Upgrade Reward] Skip %s %s: %d/%d", pop.ability_name, pop.special_value_name, currentCount, maxLimit))
			end
		end

		-- Round restriction
		if not shouldSkip and (GetMapName() == "epic_boss_fight_nightmare" or GetMapName() == "epic_boss_fight_purgatory" or GetMapName() == "epic_boss_fight_soul") and GameRules._roundnumber < 22 then
			if pop.ability_name == "phantom_assassin_coup_de_grace" and (pop.special_value_name == "crit_bonus")
			or pop.ability_name == "lycan_shapeshift" and (pop.special_value_name == "crit_multiplier")
			or pop.ability_name == "imba_juggernaut_blade_dance" and (pop.special_value_name == "blade_dance_crit_mult")
			or pop.ability_name == "juggernaut_omni_slash" and (pop.special_value_name == "duration")
			or pop.ability_name == "skeleton_king_mortal_strike" and (pop.special_value_name == "crit_mult")
			or pop.ability_name == "dawnbreaker_luminosity" and (pop.special_value_name == "bonus_damage")
			or pop.ability_name == "brewmaster_drunken_brawler" and (pop.special_value_name == "crit_multiplier")
			or pop.ability_name == "imba_magnataur_empower" and (pop.special_value_name == "bonus_damage_pct")
			or pop.ability_name == "juggernaut_swift_slash" and (pop.special_value_name == "duration")
			or pop.ability_name == "riki_tricks_of_the_trade" and (pop.special_value_name == "duration")
			or pop.ability_name == "magnataur_reverse_polarity" and (pop.special_value_name == "hero_stun_duration")
			or pop.ability_name == "magnataur_reverse_polarity" and (pop.special_value_name == "pull_radius") then
				shouldSkip = true
				print(string.format("[Upgrade Reward] Skip early-round OP: %s %s", pop.ability_name, pop.special_value_name))
			end
		end

		if not shouldSkip then
			table.insert(upgrade_ability, pop)
		end
	end

	-- Slot ke-4: generic upgrade. Base stat hanya fallback kalau generic pool kosong.
	local currentRound = GameRules._roundnumber or 0
	local currentMap = GetMapName()
	local pooledReward = PickGenericRewardWithFallback(base_stats_upgrades_pool, hero, currentRound, currentMap)
	upgrade_ability[4] = pooledReward

	if isAbilityDraftMap and PickSpecialUpgradeReward then
		local specialReward = PickSpecialUpgradeReward(hero)
		if specialReward then
			upgrade_ability[5] = specialReward
		end
	end

	-- Hitung multiplier server-side dan terapkan ke setiap nilai.
	-- Buat shallow copy tiap item agar nilai asli di _G.MINOR_ABILITY_UPGRADES tidak termutasi.
	local playerID = hero:GetPlayerOwnerID()
	for i, item in pairs(upgrade_ability) do
		local copy = {}
		for k, v in pairs(item) do copy[k] = v end
		if i == 3 and copy.is_generic_upgrade ~= 1 then
			copy.supporter_locked = 1
		end
		if copy.is_special_upgrade == 1 then
			copy.supporter_locked = nil
		elseif type(copy.value) == "number" then
			if copy.is_generic_upgrade == 1 then
				if copy.generic_name == "generic_all_attributes" then
					local mult = GetRewardMultiplier(playerID, item.special_value_name)
					copy.value = item.value * mult
					copy.generic_count = math.floor(mult)
				end
			else
				copy.value = item.value * GetRewardMultiplier(playerID, item.special_value_name)
			end
		end
		upgrade_ability[i] = copy
	end

	-- Simpan untuk validasi saat player memilih (server tidak percaya nilai dari client)
	_G.pending_rewards = _G.pending_rewards or {}
	_G.pending_rewards[playerID] = upgrade_ability

	-- Inisialisasi reroll charges hanya jika belum di-set (reroll tidak reset charges)
	_G.player_rerolls = _G.player_rerolls or {}
	if _G.player_rerolls[playerID] == nil then
		_G.player_rerolls[playerID] = GetRerollCharges(playerID)
	end

	-- Tulis ke NetTable — client subscribe ini, panel muncul otomatis saat reconnect
	WriteRoundRewardsNetTable(playerID, upgrade_ability)
end
