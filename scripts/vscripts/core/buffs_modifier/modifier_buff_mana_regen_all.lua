-- core/buffs_modifier/modifier_buff_mana_regen_all.lua
-- Modifier untuk Mana Regeneration buff

LinkLuaModifier("modifier_buff_mana_regen_50",  "core/buffs_modifier/modifier_buff_mana_regen_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_mana_regen_100", "core/buffs_modifier/modifier_buff_mana_regen_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_mana_regen_150", "core/buffs_modifier/modifier_buff_mana_regen_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_mana_regen_200", "core/buffs_modifier/modifier_buff_mana_regen_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_mana_regen_250", "core/buffs_modifier/modifier_buff_mana_regen_all", LUA_MODIFIER_MOTION_NONE)

-- Helper function
function CreateManaRegenModifier(name, value)
    local cls = class({})

    function cls:IsHidden() return true end
    function cls:IsPurgable() return false end
    function cls:RemoveOnDeath() return false end

    function cls:DeclareFunctions()
        return {
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        }
    end

    function cls:GetModifierConstantManaRegen()
        return self.regen or 0
    end

    function cls:OnCreated()
        self.regen = value
    end

    function cls:OnRefresh()
        self.regen = value
    end

    _G[name] = cls
    return cls
end

-- Instansiasi semua modifier
modifier_buff_mana_regen_50  = CreateManaRegenModifier("modifier_buff_mana_regen_50",  50)
modifier_buff_mana_regen_100 = CreateManaRegenModifier("modifier_buff_mana_regen_100", 100)
modifier_buff_mana_regen_150 = CreateManaRegenModifier("modifier_buff_mana_regen_150", 150)
modifier_buff_mana_regen_200 = CreateManaRegenModifier("modifier_buff_mana_regen_200", 200)
modifier_buff_mana_regen_250 = CreateManaRegenModifier("modifier_buff_mana_regen_250", 250)
