modifier_round_scaling_cursed_aura = class({})

function modifier_round_scaling_cursed_aura:IsHidden() return false end
function modifier_round_scaling_cursed_aura:IsPurgable() return false end
function modifier_round_scaling_cursed_aura:RemoveOnDeath() return true end
function modifier_round_scaling_cursed_aura:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_round_scaling_cursed_aura:OnCreated(kv)
    if not IsServer() then return end
    self.aura_type = tonumber(kv.aura_type) or 0
    self.attack_tick = 0
    print("[EBF CURSED AURA] Created on " .. self:GetParent():GetUnitName() .. " type=" .. self.aura_type)
end

function modifier_round_scaling_cursed_aura:GetTexture()
    local textures = {
        [8] = "item_orchid",         -- Silence
        [9] = "item_lesser_crit",    -- Stun
        [10] = "item_diffusal_blade", -- Mana Void
        [11] = "item_sange",         -- Slow
        [12] = "item_desolator",     -- Armor Break
        [13] = "item_urn_of_shadows", -- Poison
        [14] = "item_ultimate_scepter", -- Cursed Combo
    }
    return textures[self.aura_type] or "item_blade_mail"
end

function modifier_round_scaling_cursed_aura:GetEffectName()
    local effects = {
        [8] = "particles/items_fx/orchid.vpcf",
        [9] = "particles/items_fx/lesser_crit.vpcf",
        [10] = "particles/items_fx/urn_of_shadows.vpcf",
        [11] = "particles/items_fx/sange.vpcf",
        [12] = "particles/items_fx/desolator.vpcf",
        [13] = "particles/items_fx/urn_of_shadows.vpcf",
        [14] = "particles/items_fx/orchid.vpcf",
    }
    return effects[self.aura_type] or ""
end

function modifier_round_scaling_cursed_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_round_scaling_cursed_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function modifier_round_scaling_cursed_aura:OnTooltip()
    if not self.aura_type then return 0 end
    local values = {
        [8] = 38,
        [9] = 18,
        [10] = 64,
        [11] = 60,
        [12] = 25,
        [13] = 50,
        [14] = 3,
    }
    return values[self.aura_type] or 0
end

function modifier_round_scaling_cursed_aura:GetModifierName()
    if not self.aura_type then return "Cursed Aura" end
    local names = {
        [8] = "Silence",
        [9] = "Stun",
        [10] = "Mana Void",
        [11] = "Slow",
        [12] = "Armor Break",
        [13] = "Poison",
        [14] = "Cursed Combo",
    }
    return names[self.aura_type] or "Cursed Aura"
end

function modifier_round_scaling_cursed_aura:GetModifierDescription()
    if not self.aura_type then return "" end
    local descriptions = {
        [8] = "38% Silence 2s on Hit",
        [9] = "18% Stun 0.5s on Hit",
        [10] = "64% Burns 10% Mana + Damage",
        [11] = "60% Slow 40% 3s on Hit",
        [12] = "90% -25 Armor 4s on Hit",
        [13] = "50% 5% HP Poison 3s on Hit",
        [14] = "3 Random Cursed Auras",
    }
    return descriptions[self.aura_type] or ""
end

function modifier_round_scaling_cursed_aura:OnAttack(kv)
    if not IsServer() then return end
    if not self.aura_type then return end
    
    local parent = self:GetParent()
    if not parent or parent:IsNull() then return end
    if kv.attacker ~= parent then return end
    
    local target = kv.target
    if not target or target:IsNull() then return end
    if target:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS then return end
    
    -- NOTE: Don't check IsMagicImmune here - OnAttack fires when attack STARTS,
    -- not when it lands. Magic immunity check goes in OnAttackLanded only.
    self:ApplyCursedEffects(target)
end

function modifier_round_scaling_cursed_aura:OnAttackLanded(kv)
    if not IsServer() then return end
    if not self.aura_type then return end
    
    local parent = self:GetParent()
    if not parent or parent:IsNull() then return end
    if kv.attacker ~= parent then return end
    
    local target = kv.target
    if not target or target:IsNull() then return end
    if target:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS then return end
    
    -- OnAttackLanded: the attack has actually connected, so check magic immunity now
    if target:IsMagicImmune() then return end
    
    self:ApplyCursedEffects(target)
end

function modifier_round_scaling_cursed_aura:ApplyCursedEffects(target)
    if not IsServer() then return end
    if not target or target:IsNull() then return end
    if target:IsMagicImmune() then return end
    
    -- Check if this is a cursed combo and use stored combo auras
    local cursed_types = {}
    if self.aura_type == 14 then
        -- Use combo data stored in GameRules
        if not GameRules._cursedComboAuras then 
            print("[EBF CURSED AURA] ERROR: type 14 but no combo auras generated!")
            return 
        end
        cursed_types = GameRules._cursedComboAuras
        print("[EBF CURSED AURA] Applying cursed combo: " .. table.concat(cursed_types, ","))
    else
        cursed_types = { self.aura_type }
    end
    
    for _, at in ipairs(cursed_types) do
        -- Aura type 8: Silence for 2s (38% chance)
        if at == 8 then
            if RandomInt(1, 100) <= 38 then
                target:AddNewModifier(self:GetParent(), nil, "modifier_silence", { duration = 2.0 })
            end
        end
        
        -- Aura type 9: 18% stun for 0.5s
        if at == 9 then
            if RandomInt(1, 100) <= 10 then
                target:AddNewModifier(self:GetParent(), nil, "modifier_stunned", { duration = 0.5 })
            end
        end
        
        -- Aura type 10: Mana Void - burn 10% current mana + deal damage (64% chance)
        if at == 10 then
            if RandomInt(1, 100) <= 64 then
                local current_mana = target:GetMana()
                if current_mana > 0 then
                    local mana_burn = current_mana * 0.10
                    target:ReduceMana(mana_burn)
                    ApplyDamage({
                        victim = target,
                        attacker = self:GetParent(),
                        damage = mana_burn,
                        damage_type = DAMAGE_TYPE_MAGICAL,
                    })
                end
            end
        end
        
        -- Aura type 11: Slow 40% for 3s (60% chance)
        if at == 11 then
            if RandomInt(1, 100) <= 60 then
                target:AddNewModifier(self:GetParent(), nil, "modifier_slow_custom", { duration = 3.0, move_slow = 40, attack_slow = 40 })
            end
        end
        
        -- Aura type 12: Armor Break - reduces armor by 25 for 4s (90% chance)
        if at == 12 then
            if RandomInt(1, 100) <= 90 then
                target:AddNewModifier(self:GetParent(), nil, "modifier_armor_reduction", { duration = 4.0, armor_reduction = 25 })
            end
        end
        
        -- Aura type 13: Poison - 5% max HP over 3s (50% chance)
        if at == 13 then
            if RandomInt(1, 100) <= 50 then
                target:AddNewModifier(self:GetParent(), nil, "modifier_cursed_poison", { duration = 3.0 })
            end
        end
    end
end
