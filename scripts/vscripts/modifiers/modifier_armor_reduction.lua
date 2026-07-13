modifier_armor_reduction = class({})

function modifier_armor_reduction:IsHidden() return false end
function modifier_armor_reduction:IsPurgable() return true end
function modifier_armor_reduction:RemoveOnDeath() return true end
function modifier_armor_reduction:GetTexture() return "item_desolator" end

function modifier_armor_reduction:OnCreated(kv)
    if not IsServer() then return end
    self.armor_reduction = tonumber(kv.armor_reduction) or 15
end

function modifier_armor_reduction:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function modifier_armor_reduction:GetModifierPhysicalArmorBonus()
    return -self.armor_reduction
end

function modifier_armor_reduction:GetModifierName()
    return "Armor Break"
end

function modifier_armor_reduction:GetModifierDescription()
    return "Reduces armor by " .. self.armor_reduction .. "."
end