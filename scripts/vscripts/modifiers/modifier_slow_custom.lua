modifier_slow_custom = class({})

function modifier_slow_custom:IsHidden() return false end
function modifier_slow_custom:IsPurgable() return true end
function modifier_slow_custom:RemoveOnDeath() return true end

function modifier_slow_custom:OnCreated(kv)
    if not IsServer() then return end
    self.move_slow = tonumber(kv.move_slow) or 40
    self.attack_slow = tonumber(kv.attack_slow) or 40
end

function modifier_slow_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end

function modifier_slow_custom:GetModifierMoveSpeedBonus_Percentage()
    return -self.move_slow
end

function modifier_slow_custom:GetModifierAttackSpeedBonus_Constant()
    return -self.attack_slow
end