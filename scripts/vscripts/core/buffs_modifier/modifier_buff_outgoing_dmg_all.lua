-- Base template untuk semua modifier Outgoing Damage
LinkLuaModifier("modifier_buff_outgoing_dmg_20", "core/buffs_modifier/modifier_buff_outgoing_dmg_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_outgoing_dmg_30", "core/buffs_modifier/modifier_buff_outgoing_dmg_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_outgoing_dmg_40", "core/buffs_modifier/modifier_buff_outgoing_dmg_all", LUA_MODIFIER_MOTION_NONE)

-- Helper function
function CreateOutgoingDmgModifier(name, value)
    local class = class({})

    function class:IsHidden() return true end
    function class:IsPurgable() return false end
    function class:RemoveOnDeath() return false end

    function class:GetTexture()
        return "item_greater_crit" -- Ganti dengan icon lain kalau perlu
    end

    function class:DeclareFunctions()
        return {
            MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        }
    end

    function class:GetModifierDamageOutgoing_Percentage()
        return self.outgoing_dmg or 0
    end

    function class:OnCreated()
        self.outgoing_dmg = value
    end

    function class:OnRefresh()
        self.outgoing_dmg = value
    end

    _G[name] = class
    return class
end

-- Buat semua modifier
modifier_buff_outgoing_dmg_20 = CreateOutgoingDmgModifier("modifier_buff_outgoing_dmg_20", 20)
modifier_buff_outgoing_dmg_30 = CreateOutgoingDmgModifier("modifier_buff_outgoing_dmg_30", 30)
modifier_buff_outgoing_dmg_40 = CreateOutgoingDmgModifier("modifier_buff_outgoing_dmg_40", 40)
