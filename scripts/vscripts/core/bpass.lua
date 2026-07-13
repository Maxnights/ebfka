bpass = class({})

bpass.reward = {
    donator = "modifier_bpass_donator",
    limbo = "modifier_bpass_limbo",
    lust = "modifier_bpass_lust",
    purgatory = "modifier_bpass_purgatory",
    paradiso = "modifier_bpass_paradiso",
    empyrean = "modifier_bpass_empyrean",
    imba = "modifier_bpass_imba", --aka "belatrix" supporter
    nord = "modifier_bpass_nord", -- Monthly supporter buff
    lite = "modifier_bpass_lite", -- Monthly supporter buff
    greed = "modifier_bpass_goblins_greed", -- Premium reward for alchemist_goblins_greed skill
}

function bpass:giveBpass(steamid)

end

function bpass:checkBpass(steamid)
end

-- Dipanggil saat game start untuk setiap player.
-- Apply modifier dari tier utama + semua stacked modifier yang masih aktif.
function bpass:ApplyDonatorBuffs(playerID, hero)
    local tierData     = CustomNetTables:GetTableValue("donator_tier", tostring(playerID)) or {}
    local expiredData  = CustomNetTables:GetTableValue("donator_expired", tostring(playerID)) or {}
    local modData      = CustomNetTables:GetTableValue("donator_modifiers", tostring(playerID)) or {}

    -- Apply tier utama jika belum expired
    if expiredData.donator_expired == 0 then
        local mainMod = bpass.reward[tierData.donator_tier]
        if mainMod then
            hero:AddNewModifier(hero, nil, mainMod, {})
            print("[bpass] Apply tier utama: " .. tostring(tierData.donator_tier) .. " -> " .. mainMod)
        end
    end

    -- Apply semua stacked modifiers yang masih aktif
    local modifiers = modData.modifiers or {}
    for _, mod in pairs(modifiers) do
        if type(mod) == "table" then
            local stackMod = bpass.reward[mod.tier]
            if stackMod then
                hero:AddNewModifier(hero, nil, stackMod, {})
                print("[bpass] Apply stacked modifier: " .. tostring(mod.tier) .. " -> " .. stackMod)
            end
        end
    end
end
