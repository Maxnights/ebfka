-- Base template untuk semua modifier CDR
LinkLuaModifier("modifier_buff_cdr_10", "core/buffs_modifier/modifier_buff_cdr_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_cdr_15", "core/buffs_modifier/modifier_buff_cdr_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_cdr_20", "core/buffs_modifier/modifier_buff_cdr_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_cdr_25", "core/buffs_modifier/modifier_buff_cdr_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_cdr_30", "core/buffs_modifier/modifier_buff_cdr_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_cdr_40", "core/buffs_modifier/modifier_buff_cdr_all", LUA_MODIFIER_MOTION_NONE)

-- Helper function
function CreateCDRModifier(name, value)
    local class = class({})

    function class:IsHidden() return true end
    function class:IsPurgable() return false end
    function class:RemoveOnDeath() return false end

    function class:GetTexture()
        return "alchemist_goblins_greed" -- Ganti dengan icon yang cocok
    end

    function class:DeclareFunctions()
        return {
            MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
        }
    end

    function class:GetModifierPercentageCooldown()
        return self.cdr or 0
    end

    function class:OnCreated()
        self.cdr = value
    end

    function class:OnRefresh()
        self.cdr = value
    end

    _G[name] = class
    return class
end

-- Buat semua modifier
modifier_buff_cdr_10 = CreateCDRModifier("modifier_buff_cdr_10", 10)
modifier_buff_cdr_15 = CreateCDRModifier("modifier_buff_cdr_15", 15)
modifier_buff_cdr_20 = CreateCDRModifier("modifier_buff_cdr_20", 20)
modifier_buff_cdr_25 = CreateCDRModifier("modifier_buff_cdr_25", 25)
modifier_buff_cdr_30 = CreateCDRModifier("modifier_buff_cdr_30", 30)
modifier_buff_cdr_40 = CreateCDRModifier("modifier_buff_cdr_40", 40)
