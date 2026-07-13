modifier_bleed_debuff = class({})

function modifier_bleed_debuff:IsHidden() return false end
function modifier_bleed_debuff:IsPurgable() return true end
function modifier_bleed_debuff:RemoveOnDeath() return true end
function modifier_bleed_debuff:GetTexture() return "item_blade_mail" end

function modifier_bleed_debuff:OnCreated(kv)
    if not IsServer() then return end
    self.damage_per_second = 0.02
    self.tick_interval = 1.0
    self:StartIntervalThink(self.tick_interval)
end

function modifier_bleed_debuff:OnIntervalThink()
    if not IsServer() then return end
    local parent = self:GetParent()
    if not parent or parent:IsNull() or not parent:IsAlive() then return end

    local current_hp = parent:GetHealth()
    local bleed_damage = current_hp * self.damage_per_second

    ApplyDamage({
        victim = parent,
        attacker = self:GetCaster(),
        damage = bleed_damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
    })
end

function modifier_bleed_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATUS_BAR_NAME,
    }
end

function modifier_bleed_debuff:GetModifierStatusBarName()
    -- Returns a localization token - will be localized client-side
    return "DOTA_Tooltip_ability_bloodseeker_rupture"
end
