-- core/buffs_modifier/modifier_buff_crit_all.lua
--
-- CATATAN PENTING:
--   hero:AddNewModifier(hero, nil, modifier_name, {}) → ability = nil
--   self:RollPRNG() MEMBUTUHKAN ability yang valid, jika nil akan selalu gagal!
--   Solusi: gunakan RollPercentage() (random biasa) atau simpan nilai di OnCreated.
--
--   MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE:
--     Return nilai multiplier dalam persen (200 = 200% = 2x damage = bonus 100%)
--     Jika return nil/0 → tidak ada crit untuk tick itu.

-- === CRIT CHANCE LINK ===
LinkLuaModifier("modifier_buff_crit_chance_5",  "core/buffs_modifier/modifier_buff_crit_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_crit_chance_10", "core/buffs_modifier/modifier_buff_crit_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_crit_chance_15", "core/buffs_modifier/modifier_buff_crit_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_crit_chance_20", "core/buffs_modifier/modifier_buff_crit_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_crit_chance_25", "core/buffs_modifier/modifier_buff_crit_all", LUA_MODIFIER_MOTION_NONE)

-- === CRIT DAMAGE LINK ===
LinkLuaModifier("modifier_buff_crit_dmg_30",  "core/buffs_modifier/modifier_buff_crit_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_crit_dmg_60",  "core/buffs_modifier/modifier_buff_crit_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_crit_dmg_90",  "core/buffs_modifier/modifier_buff_crit_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_crit_dmg_120", "core/buffs_modifier/modifier_buff_crit_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_crit_dmg_150", "core/buffs_modifier/modifier_buff_crit_all", LUA_MODIFIER_MOTION_NONE)

-- ===================================================================
-- Helper: Crit Chance modifier
-- chance  = % peluang (5, 10, 15, 20, 25)
-- mult    = damage multiplier saat proc (200 = 2x damage = +100% bonus)
--
-- Menggunakan RollPercentage() karena ability parent bisa nil saat
-- di-apply via hero:AddNewModifier(hero, nil, ...)
-- ===================================================================
function CreateCritChanceModifier(name, chance, mult)
    local cls = class({})

    function cls:IsHidden() return true end
    function cls:IsPurgable() return false end
    function cls:RemoveOnDeath() return false end

    function cls:GetAttributes()
        return MODIFIER_ATTRIBUTE_MULTIPLE
    end

    function cls:DeclareFunctions()
        return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
    end

    -- RollPercentage tidak memerlukan ability → aman saat ability = nil
    function cls:GetModifierPreAttack_CriticalStrike(params)
        if RollPercentage(self.crit_chance) then
            return self.crit_mult
        end
        return 0
    end

    function cls:OnCreated()
        self.crit_chance = chance
        self.crit_mult   = mult
    end

    function cls:OnRefresh()
        self.crit_chance = chance
        self.crit_mult   = mult
    end

    _G[name] = cls
    return cls
end

-- ===================================================================
-- Helper: Crit Damage modifier
-- Guaranteed 100% crit setiap serangan, tanpa roll.
-- mult = multiplier total (130 = 130% damage = bonus +30%)
-- ===================================================================
function CreateCritDmgModifier(name, mult)
    local cls = class({})

    function cls:IsHidden() return true end
    function cls:IsPurgable() return false end
    function cls:RemoveOnDeath() return false end

    function cls:GetAttributes()
        return MODIFIER_ATTRIBUTE_MULTIPLE
    end

    function cls:DeclareFunctions()
        return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
    end

    -- Langsung return multiplier tanpa roll → guaranteed crit setiap hit
    function cls:GetModifierPreAttack_CriticalStrike(params)
        return self.crit_mult
    end

    function cls:OnCreated()
        self.crit_mult = mult
    end

    function cls:OnRefresh()
        self.crit_mult = mult
    end

    _G[name] = cls
    return cls
end

-- ===================================================================
-- Crit Chance (multiplier 200% saat proc = bonus 100% damage)
-- ===================================================================
modifier_buff_crit_chance_5  = CreateCritChanceModifier("modifier_buff_crit_chance_5",  5,  200)
modifier_buff_crit_chance_10 = CreateCritChanceModifier("modifier_buff_crit_chance_10", 10, 200)
modifier_buff_crit_chance_15 = CreateCritChanceModifier("modifier_buff_crit_chance_15", 15, 200)
modifier_buff_crit_chance_20 = CreateCritChanceModifier("modifier_buff_crit_chance_20", 20, 200)
modifier_buff_crit_chance_25 = CreateCritChanceModifier("modifier_buff_crit_chance_25", 25, 200)

-- ===================================================================
-- Crit Damage  (100% proc, multiplier bertingkat)
--   crit_dmg_30  → 130% total damage (base 100 + bonus 30)
--   crit_dmg_60  → 160%
--   crit_dmg_90  → 190%
--   crit_dmg_120 → 220%
--   crit_dmg_150 → 250%
-- ===================================================================
modifier_buff_crit_dmg_30  = CreateCritDmgModifier("modifier_buff_crit_dmg_30",  130)
modifier_buff_crit_dmg_60  = CreateCritDmgModifier("modifier_buff_crit_dmg_60",  160)
modifier_buff_crit_dmg_90  = CreateCritDmgModifier("modifier_buff_crit_dmg_90",  190)
modifier_buff_crit_dmg_120 = CreateCritDmgModifier("modifier_buff_crit_dmg_120", 220)
modifier_buff_crit_dmg_150 = CreateCritDmgModifier("modifier_buff_crit_dmg_150", 250)
