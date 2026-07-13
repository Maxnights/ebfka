-- core/buffs_modifier/modifier_buff_bonus_dmg_all.lua
-- Bonus Damage menggunakan MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
-- Meningkatkan base damage hero sebesar persen yang ditentukan

LinkLuaModifier("modifier_buff_bonus_dmg_50",  "core/buffs_modifier/modifier_buff_bonus_dmg_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_bonus_dmg_100", "core/buffs_modifier/modifier_buff_bonus_dmg_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_bonus_dmg_200", "core/buffs_modifier/modifier_buff_bonus_dmg_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_bonus_dmg_300", "core/buffs_modifier/modifier_buff_bonus_dmg_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_bonus_dmg_500", "core/buffs_modifier/modifier_buff_bonus_dmg_all", LUA_MODIFIER_MOTION_NONE)

-- Helper function
function CreateBonusDmgModifier(name, value)
    local cls = class({})

    function cls:IsHidden() return true end
    function cls:IsPurgable() return false end
    function cls:RemoveOnDeath() return false end

    -- MODIFIER_ATTRIBUTE_MULTIPLE agar bisa stack dengan sumber bonus damage lain
    function cls:GetAttributes()
        return MODIFIER_ATTRIBUTE_MULTIPLE
    end

    function cls:DeclareFunctions()
        return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE }
    end

    -- Persentase bonus base damage outgoing
    function cls:GetModifierBaseDamageOutgoing_Percentage()
        return self.bonus_dmg or 0
    end

    function cls:OnCreated()
        self.bonus_dmg = value
    end

    function cls:OnRefresh()
        self.bonus_dmg = value
    end

    _G[name] = cls
    return cls
end

-- Instansiasi semua modifier
modifier_buff_bonus_dmg_50  = CreateBonusDmgModifier("modifier_buff_bonus_dmg_50",  50)
modifier_buff_bonus_dmg_100 = CreateBonusDmgModifier("modifier_buff_bonus_dmg_100", 100)
modifier_buff_bonus_dmg_200 = CreateBonusDmgModifier("modifier_buff_bonus_dmg_200", 200)
modifier_buff_bonus_dmg_300 = CreateBonusDmgModifier("modifier_buff_bonus_dmg_300", 300)
modifier_buff_bonus_dmg_500 = CreateBonusDmgModifier("modifier_buff_bonus_dmg_500", 500)
