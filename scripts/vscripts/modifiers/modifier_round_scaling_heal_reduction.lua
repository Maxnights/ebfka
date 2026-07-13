modifier_round_scaling_heal_reduction = class({})

function modifier_round_scaling_heal_reduction:IsHidden() return false end
function modifier_round_scaling_heal_reduction:IsPurgable() return true end
function modifier_round_scaling_heal_reduction:RemoveOnDeath() return true end
function modifier_round_scaling_heal_reduction:GetTexture() return "item_sphere" end

function modifier_round_scaling_heal_reduction:OnCreated(kv)
    if not IsServer() then return end
    self.reduction_pct = -50
end

function modifier_round_scaling_heal_reduction:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    }
end

function modifier_round_scaling_heal_reduction:GetModifierHealAmplify_PercentageSource()
    return self.reduction_pct or -50
end

function modifier_round_scaling_heal_reduction:GetModifierHPRegenAmplify_Percentage()
    return self.reduction_pct or -50
end