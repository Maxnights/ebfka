-- buffs.lua

BuffMapSets = {
    All = { "*" },
    Standard = {
        "epic_boss_fight_normal",
        "epic_boss_fight_hard",
        "epic_boss_fight_impossible",
        "epic_boss_fight_challenger",
        "epic_boss_fight_nightmare",
        "epic_boss_fight_soul",
        "epic_boss_fight_god",
        "epic_boss_fight_ad",
    },
}

function IsBuffAllowedOnMap(buff, mapName)
    if not buff then return false end

    local maps = buff.maps or buff.map
    if not maps then return true end

    if type(maps) == "string" then
        return maps == "*" or maps == "all" or maps == mapName
    end

    if type(maps) == "table" then
        for key, value in pairs(maps) do
            if value == "*" or value == "all" or value == mapName or key == mapName and value == true then
                return true
            end
        end
    end

    return false
end

Buffs = {
    -- Cooldown Reduction
    cdr_20 = { name = "CDR 20%", modifier = "modifier_buff_cdr_20", price = 14, group = "Cooldown Reduction", level = 3 },

    -- MMR Boost
    mmr_100 = { name = "MMR +100", modifier = "modifier_buff_mmr_100", price = 10, group = "MMR Boost", level = 1 },
    mmr_150 = { name = "MMR +150", modifier = "modifier_buff_mmr_150", price = 12, group = "MMR Boost", level = 2 },
    mmr_200 = { name = "MMR +200", modifier = "modifier_buff_mmr_200", price = 16, group = "MMR Boost", level = 3 },
    mmr_250 = { name = "MMR +250", modifier = "modifier_buff_mmr_250", price = 18, group = "MMR Boost", level = 4 },
    mmr_300 = { name = "MMR +300", modifier = "modifier_buff_mmr_300", price = 20, group = "MMR Boost", level = 5 },

    -- XPM
    xpm_2200 = { name = "XPM +2200", modifier = "modifier_buff_xpm_2200", price = 15, group = "XPM Boost", level = 1 },
    
    -- GPM
    gpm_2500 = { name = "GPM +2500", modifier = "modifier_buff_gpm_2500", price = 15, group = "GPM Boost", level = 1 },
    
    -- Outgoing Damage %
    outgoing_dmg_20 = { name = "Outgoing DMG +20%", modifier = "modifier_buff_outgoing_dmg_20", price = 10, group = "Outgoing Damage", level = 1 },

    -- Codex Slots
    codex_7 = { name = "Codex Lv 7", modifier = "modifier_buff_codex_7", price = 20, group = "Codex Level", level = 2 },

    -- Other Buffs
    projectile_speed_400 = { name = "Proj Speed +400", modifier = "modifier_buff_projectile_speed_400", price = 5, group = "Misc Buffs", level = 1 },
    cast_range_300 = { name = "Cast Range +300", modifier = "modifier_buff_cast_range_300", price = 10, group = "Misc Buffs", level = 2 },
    -- spell_amp_250 = { name = "Spell Amp +250", modifier = "modifier_buff_spell_amp_250", price = 10, group = "Misc Buffs", level = 3 },
    status_resist_50 = { name = "Status Resist +50%", modifier = "modifier_buff_status_resist_50", price = 10, group = "Misc Buffs", level = 4 },
    s_reward_x3 = { name = "S Reward x3", modifier = "modifier_buff_s_reward_x3", price = 50, group = "Misc Buffs", level = 7 },

    -- Crit Chance
    crit_chance_25 = { name = "Crit Chance +25%", modifier = "modifier_buff_crit_chance_25", price = 50, group = "Crit Chance", level = 5 },

    -- Crit Damage
    crit_dmg_150 = { name = "Crit Damage +150%", modifier = "modifier_buff_crit_dmg_150", price = 50, group = "Crit Damage", level = 5 },

    -- Mana Regen
    mana_regen_5 = { name = "Mana Regen +50", modifier = "modifier_buff_mana_regen_50", price = 9, group = "Mana Regen", level = 1 },
    mana_regen_10 = { name = "Mana Regen +100", modifier = "modifier_buff_mana_regen_100", price = 10, group = "Mana Regen", level = 2 },

    -- Bonus Damage (God Strength)
    -- bonus_dmg_50 = { name = "Bonus DMG +50", modifier = "modifier_buff_bonus_dmg_50", price = 10, group = "Bonus Damage", level = 1 },
    bonus_dmg_100 = { name = "Bonus DMG +100", modifier = "modifier_buff_bonus_dmg_100", price = 50, group = "Bonus Damage", level = 2 },
}

for _, buff in pairs(Buffs) do
    if buff.maps == nil and buff.map == nil then
        buff.maps = BuffMapSets.Standard
    end
end

-- Urutan group di UI shop (digunakan oleh shopcoin.js)
BuffGroupOrder = {
    "Cooldown Reduction",
    "MMR Boost",
    "XPM Boost",
    "GPM Boost",
    "Outgoing Damage",
    "Bonus Damage Percentage",
    "Crit Chance",
    "Crit Damage",
    "Mana Regen",
    "Codex Level",
    "Misc Buffs",
}
