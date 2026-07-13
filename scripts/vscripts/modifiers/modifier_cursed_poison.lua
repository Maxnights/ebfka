modifier_cursed_poison = class({})

function modifier_cursed_poison:IsHidden() return false end
function modifier_cursed_poison:IsPurgable() return true end
function modifier_cursed_poison:RemoveOnDeath() return true end
function modifier_cursed_poison:GetTexture() return "item_urn_of_shadows" end

function modifier_cursed_poison:OnCreated(kv)
    if not IsServer() then return end
    self.tick_interval = 1.0
    self.tick_count = 0
    self.max_ticks = 3
    self:StartIntervalThink(self.tick_interval)
end

function modifier_cursed_poison:OnIntervalThink()
    if not IsServer() then return end
    self.tick_count = self.tick_count + 1
    if self.tick_count > self.max_ticks then
        self:Destroy()
        return
    end
    
    local parent = self:GetParent()
    if not parent or parent:IsNull() or not parent:IsAlive() then
        self:Destroy()
        return
    end
    
    local max_hp = parent:GetMaxHealth()
    local poison_damage = max_hp * 0.05 / self.max_ticks
    
    ApplyDamage({
        victim = parent,
        attacker = self:GetCaster(),
        damage = poison_damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
    })
end

function modifier_cursed_poison:GetModifierName()
    return "Cursed Poison"
end

function modifier_cursed_poison:GetModifierDescription()
    return "Taking " .. 5 .. "% max HP as magic damage over 3s."
end