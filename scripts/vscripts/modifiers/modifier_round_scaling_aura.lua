modifier_round_scaling_aura = class({})

function modifier_round_scaling_aura:IsHidden() return false end
function modifier_round_scaling_aura:IsPurgable() return false end
function modifier_round_scaling_aura:RemoveOnDeath() return true end
function modifier_round_scaling_aura:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_round_scaling_aura:OnCreated(kv)
    if not IsServer() then return end
    self.aura_type = tonumber(kv.aura_type) or 0
end

function modifier_round_scaling_aura:GetTexture()
    local textures = {
        [1] = "item_pipe",           -- Magic Shield
        [2] = "item_assault",        -- Iron Skin
        [3] = "item_blade_mail",     -- Spikes
        [4] = "item_heavens_halberd", -- Suppression
        [5] = "item_diffusal_blade",  -- Dispel
        [6] = "item_soul_ring",      -- Mana Drain
        [7] = "item_ultimate_scepter", -- Combo
    }
    return textures[self.aura_type] or "item_blade_mail"
end

function modifier_round_scaling_aura:GetEffectName()
    local effects = {
        [1] = "particles/items_fx/pipe_aura.vpcf",
        [2] = "particles/items_fx/assault_armor.vpcf",
        [3] = "particles/items_fx/blade_mail.vpcf",
    }
    return effects[self.aura_type] or ""
end

function modifier_round_scaling_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_round_scaling_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_EVENT_ON_ATTACK,
    }
end

function modifier_round_scaling_aura:OnTooltip()
    if not self.aura_type then return 0 end
    local values = {
        [1] = 70,
        [2] = 80,
        [3] = 10,
        [4] = 50,
        [5] = 1,
        [6] = 5,
        [7] = 3,
    }
    return values[self.aura_type] or 0
end

function modifier_round_scaling_aura:GetModifierName()
    if not self.aura_type then return "Round Aura" end
    local names = {
        [1] = "Magic Shield",
        [2] = "Iron Skin",
        [3] = "Spikes",
        [4] = "Suppression",
        [5] = "Dispel",
        [6] = "Mana Drain",
        [7] = "Combo",
    }
    return names[self.aura_type] or "Round Aura"
end

function modifier_round_scaling_aura:GetModifierDescription()
    if not self.aura_type then return "" end
    local descriptions = {
        [1] = "+70% Magic Resist",
        [2] = "+80 Armor",
        [3] = "10% Damage Reflect",
        [4] = "-50% Healing on Attacker",
        [5] = "Dispels Buffs on Hit",
        [6] = "Burns 5% Mana on Hit",
        [7] = "3 Random Auras Combo",
    }
    return descriptions[self.aura_type] or ""
end

-- Aura type 1: Magic Shield - bonus magic resistance
function modifier_round_scaling_aura:GetModifierMagicalResistanceBonus()
    if self.aura_type == 1 then
        return 70
    end
    return 0
end

-- Aura type 2: Iron Skin - bonus armor
function modifier_round_scaling_aura:GetModifierPhysicalArmorBonus()
    if self.aura_type == 2 then
        return 80
    end
    return 0
end

function modifier_round_scaling_aura:OnTakeDamage(kv)
    if not IsServer() then return end
    if not self.aura_type then return end
    
    local parent = self:GetParent()
    if not parent or parent:IsNull() then return end
    if kv.unit ~= parent then return end
    
    local attacker = kv.attacker
    if not attacker or attacker:IsNull() then return end
    if attacker:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS then return end
    
    local damage = kv.damage
    if damage <= 0 then return end
    
    -- Aura type 3: Damage reflection 10%
    if self.aura_type == 3 then
        local reflect_dmg = damage * 0.10
        ApplyDamage({
            victim = attacker,
            attacker = parent,
            damage = reflect_dmg,
            damage_type = DAMAGE_TYPE_PHYSICAL,
            damage_flags = DOTA_DAMAGE_FLAG_REFLECTION,
        })
    end
    
    -- Aura type 4: Healing reduction 50% (applied as a debuff on attacker)
    if self.aura_type == 4 then
        attacker:AddNewModifier(parent, nil, "modifier_round_scaling_heal_reduction", { duration = 3.0 })
    end
end

function modifier_round_scaling_aura:OnAttack(kv)
    if not IsServer() then return end
    if not self.aura_type then return end
    
    local parent = self:GetParent()
    if not parent or parent:IsNull() then return end
    if kv.attacker ~= parent then return end
    
    local target = kv.target
    if not target or target:IsNull() then return end
    if target:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS then return end
    
    -- Aura type 5: Dispel on attack - removes positive buffs from the target
    if self.aura_type == 5 then
        target:Purge(true, false, false, false, false)
    end
    
    -- Aura type 6: Mana Drain on attack
    if self.aura_type == 6 then
        local mana_drain = target:GetMaxMana() * 0.05
        local actual_drain = target:ReduceMana(mana_drain)
        if actual_drain > 0 then
            ApplyDamage({
                victim = target,
                attacker = parent,
                damage = actual_drain,
                damage_type = DAMAGE_TYPE_MAGICAL,
            })
        end
    end
end