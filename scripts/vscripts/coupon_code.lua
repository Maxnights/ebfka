--[[
    Coupon / Redeem Code System (backend-authoritative)

    Player memasukkan kode dari HUD. Kode ditembak ke Laravel backend untuk
    divalidasi & diterapkan ke Firebase (coin/buff/donator/mmr). Backend membalas
    payload terstruktur, lalu kita cerminkan reward-nya secara live di match ini.

    Event dari client:
        coupon_redeem   { code = "..." }

    Event ke client:
        coupon_result   { status, message, reward_type, reward_value, label }

    Status: success | invalid | expired | not_started | limit_reached
            | already_used | error
]]

CouponCode = CouponCode or {}

require("libraries/json")

function CouponCode:Init()
    -- Base URL diambil dari settings.kv (apiBaseUrl), pola sama dgn synced_chat.lua
    local settings = GetStatSettings()
    local apiBase = (settings.apiBaseUrl or "http://localhost:8000") .. "/api/redeem-codes"
    self.redeemEndpoint = apiBase .. "/redeem"
    self.announcementEndpoint = apiBase .. "/active-announcement"

    CustomGameEventManager:RegisterListener("coupon_redeem", function(_, data)
        self:OnRedeem(data)
    end)
    print("[CouponCode] Init OK (backend-authoritative) endpoint=" .. self.redeemEndpoint)
end

local function normalize(code)
    return string.upper(string.gsub(tostring(code or ""), "%s+", ""))
end

function CouponCode:OnRedeem(data)
    local playerID = data.PlayerID
    if not playerID or playerID < 0 then return end
    local player = PlayerResource:GetPlayer(playerID)
    if not player then return end

    local code = normalize(data.code)
    if code == "" then
        self:_SendResult(player, { status = "invalid", message = "Invalid code" })
        return
    end

    local body = {
        steam_id    = tostring(PlayerResource:GetSteamID(playerID)),
        code        = code,
        player_name = PlayerResource:GetPlayerName(playerID),
        match_id    = tostring(GameRules:Script_GetMatchID()),
    }

    local request = CreateHTTPRequestScriptVM("POST", self.redeemEndpoint)
    request:SetHTTPRequestHeaderValue("Content-Type", "application/json")
    request:SetHTTPRequestHeaderValue("X-EBFIMBA-KEY", GetAuthKey())
    request:SetHTTPRequestHeaderValue("User-Agent", "Dota2CustomGame/EBF")
    request:SetHTTPRequestRawPostBody("application/json", json.encode(body))

    request:Send(function(result)
        local ok, decoded = pcall(json.decode, result.Body or "")
        if not ok or type(decoded) ~= "table" then
            print("[CouponCode] Bad response: " .. tostring(result.StatusCode) .. " " .. tostring(result.Body))
            self:_SendResult(player, { status = "error", message = "Network error, please try again" })
            return
        end

        if decoded.success then
            self:_ApplyReward(playerID, decoded)
            print(string.format("[CouponCode] %s redeem '%s' -> %s (%s)",
                body.player_name, code, tostring(decoded.reward_type), tostring(decoded.label)))
        end

        self:_SendResult(player, decoded)
    end)
end

-- Cerminkan reward live di match ini (Firebase sudah diupdate backend).
function CouponCode:_ApplyReward(playerID, r)
    local rtype = r.reward_type
    if rtype == "coin" then
        self:_AddCoinsLive(playerID, tonumber(r.reward_value) or 0)
    elseif rtype == "buff" then
        self:_AddBuffLive(playerID, r.buff_key, tonumber(r.expires_at) or 0)
    elseif rtype == "donator" then
        self:_SetDonatorLive(playerID, r.tier_key, tonumber(r.expires_at) or 0)
    -- mmr: berlaku match berikutnya (di-handle saat load), tidak ada aksi live.
    end

    -- Coin shop (shopcoin.js) hanya refresh coin & indikator donator/buff saat
    -- menerima shop_data, bukan dari net-table. Kirim ulang agar UI ikut sinkron.
    if rtype == "coin" or rtype == "buff" or rtype == "donator" then
        if shop_request_data then
            shop_request_data(nil, { PlayerID = playerID })
        end
    end
end

function CouponCode:_AddCoinsLive(playerID, amount)
    if amount == 0 then return end
    local coinData = CustomNetTables:GetTableValue("coin", tostring(playerID)) or { coin = 0 }
    coinData.coin = (coinData.coin or 0) + amount
    CustomNetTables:SetTableValue("coin", tostring(playerID), coinData)

    -- Naikkan baseline juga agar sync coin saat match berakhir tidak double-credit
    -- (backend sudah menambahkan coin ini ke Firebase; lihat game_stats.lua).
    GameRules.PlayerStartCoins = GameRules.PlayerStartCoins or {}
    GameRules.PlayerStartCoins[playerID] = (GameRules.PlayerStartCoins[playerID] or 0) + amount
end

function CouponCode:_AddBuffLive(playerID, buffKey, expiresAt)
    if not buffKey or buffKey == "" then return end

    -- Update net-table donator_modifiers: ganti entri buff yang sama, pertahankan lainnya.
    local modData = CustomNetTables:GetTableValue("donator_modifiers", tostring(playerID)) or {}
    local modifiers = {}
    for _, m in pairs(modData.modifiers or {}) do
        if type(m) == "table" and m.tier ~= buffKey then
            table.insert(modifiers, m)
        end
    end
    table.insert(modifiers, { tier = buffKey, expired = expiresAt })
    CustomNetTables:SetTableValue("donator_modifiers", tostring(playerID), { modifiers = modifiers })

    self:_ApplyModifierToHero(playerID, buffKey)
end

function CouponCode:_SetDonatorLive(playerID, tierKey, expiresAt)
    if not tierKey or tierKey == "" then return end

    CustomNetTables:SetTableValue("donator_tier", tostring(playerID), { donator_tier = tierKey })
    CustomNetTables:SetTableValue("donator_expired", tostring(playerID), {
        donator_expired       = 0,
        donator_expired_value = expiresAt,
    })

    self:_ApplyModifierToHero(playerID, tierKey)
end

-- Terapkan modifier bpass ke hero yang sedang hidup (pola sama dgn event_listeners).
function CouponCode:_ApplyModifierToHero(playerID, key)
    if GetMapName() == "epic_boss_fight_purgatory" or GameRules.FairPlayMode then return end
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if not hero or hero:IsNull() then return end
    local mod = bpass and bpass.reward and bpass.reward[key]
    if mod and not hero:HasModifier(mod) then
        hero:AddNewModifier(hero, nil, mod, { duration = -1 })
        print("[CouponCode] Applied modifier " .. tostring(key) .. " -> " .. tostring(mod))
    end
end

function CouponCode:_SendResult(player, r)
    CustomGameEventManager:Send_ServerToPlayer(player, "coupon_result", {
        status       = r.status or (r.success and "success" or "error"),
        message      = r.message or "",
        reward_type  = r.reward_type or "",
        reward_value = r.reward_value or 0,
        label        = r.label or "",
    })
end

function CouponCode:AnnounceForRoundOne(roundNumber)
    if tonumber(roundNumber) ~= 1 then return end
    if GameRules.RedeemAnnouncementShown then return end
    GameRules.RedeemAnnouncementShown = true

    local request = CreateHTTPRequestScriptVM("GET", self.announcementEndpoint)
    request:SetHTTPRequestHeaderValue("X-EBFIMBA-KEY", GetAuthKey())
    request:SetHTTPRequestHeaderValue("User-Agent", "Dota2CustomGame/EBF")

    request:Send(function(result)
        if result.StatusCode ~= 200 then
            print("[CouponCode] Announcement request failed: HTTP " .. tostring(result.StatusCode))
            return
        end

        local ok, decoded = pcall(json.decode, result.Body or "")
        if not ok or type(decoded) ~= "table" or not decoded.active or not decoded.code then
            return
        end

        CustomGameEventManager:Send_ServerToAllClients("coupon_announcement", {
            code = tostring(decoded.code or ""),
            title = tostring(decoded.title or "Redeem Code Available"),
            message = tostring(decoded.message or "Redeem this code in the Coupon Code menu."),
            reward_label = tostring(decoded.reward_label or ""),
            expires_at = tonumber(decoded.expires_at) or 0,
        })
    end)
end
