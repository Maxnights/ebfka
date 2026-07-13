modifier_round_scaling = class({})

function modifier_round_scaling:IsHidden() return true end
function modifier_round_scaling:IsPurgable() return false end
function modifier_round_scaling:RemoveOnDeath() return true end
function modifier_round_scaling:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_round_scaling:OnCreated(kv)
    if not IsServer() then return end

    local round = tonumber(kv.round) or 1

    -- Player-count factor: balance is tuned for 2 players.
    -- 1 player => harder (more enemy HP, same lethal damage)
    -- 3-4 players => easier (more HP but their combined DPS carries)
    -- NOTE: Currently disabled (set to fixed 1.0). Keep code for future use.
    -- local pc = 2
    -- if PlayerResource then
    --     local cnt = 0
    --     for i = 0, PlayerResource:GetPlayerCount() - 1 do
    --         if PlayerResource:IsValidPlayerID(i) and PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
    --             cnt = cnt + 1
    --         end
    --     end
    --     if cnt > 0 then pc = cnt end
    -- end
    -- local pf = pc / 2                  -- 2 players => 1.0
    -- local hp_factor = pf               -- scale enemy HP with player count
    -- local dmg_factor = 0.85 + 0.15 * pf -- scale enemy damage weakly
    local hp_factor = 1.0
    local dmg_factor = 1.0

    -- Round 1 = light scaling (still not trivial so mobility matters)
    if round <= 1 then
        self.hp_mult = 3.375 * hp_factor
        self.dmg_mult = 3.375 * dmg_factor
        self.bonus_armor = 6.0
        self.bonus_mr = 18.0
        self.bonus_as = 20.25
        self.bonus_ms = 16.2
        self.spell_amp = 33.75
        return
    end

    -- Progressive scaling from round 2+ (increased difficulty)
    if round == 2 then
        self.hp_mult = 10.8 * hp_factor
        self.dmg_mult = 8.775 * dmg_factor
        self.bonus_armor = 16.0
        self.bonus_mr = 45.0
        self.bonus_as = 47.25
        self.bonus_ms = 32.4
        self.spell_amp = 81
    elseif round == 3 then
        self.hp_mult = 14.85 * hp_factor
        self.dmg_mult = 12.15 * dmg_factor
        self.bonus_armor = 22.0
        self.bonus_mr = 60.0
        self.bonus_as = 67.5
        self.bonus_ms = 37.8
        self.spell_amp = 121.5
    elseif round == 4 then
        self.hp_mult = 16.875 * hp_factor
        self.dmg_mult = 13.5 * dmg_factor
        self.bonus_armor = 26.0
        self.bonus_mr = 70.0
        self.bonus_as = 78.3
        self.bonus_ms = 40.5
        self.spell_amp = 148.5
    elseif round == 5 then
        self.hp_mult = 7.0 * hp_factor
        self.dmg_mult = 5.6 * dmg_factor
        self.bonus_armor = 10.0
        self.bonus_mr = 28.0
        self.bonus_as = 25.9
        self.bonus_ms = 15.4
        self.spell_amp = 61.6
    else
        -- From round 6 onwards: multipliers DECREASE toward 1.5 by round 25.
        -- Round 5 is the peak; beyond that the natural enemy power growth
        -- (levels, abilities, base stats) is enough, so the multiplier tapers off.
        -- Each stat has its own step so they all reach exactly 1.5 at round 25.
        -- Values halved from original to reduce scaling intensity.
        local k = round - 5
        local step_hp     = (3.5   - 1.5) / 20
        local step_dmg    = (2.8   - 1.5) / 20
        local step_armor  = (10.0  - 1.5) / 20
        local step_mr     = (28.0  - 1.5) / 20
        local step_as     = (12.95 - 1.5) / 20
        local step_ms     = (7.7   - 1.5) / 20
        local step_spell  = (30.8  - 1.5) / 20
        self.hp_mult      = math.max(3.5   - k * step_hp,     1.5)
        self.dmg_mult     = math.max(2.8   - k * step_dmg,    1.5)
        self.bonus_armor  = math.max(10.0  - k * step_armor,  1.5)
        self.bonus_mr     = math.max(28.0  - k * step_mr,     1.5)
        self.bonus_as     = math.max(12.95 - k * step_as,     1.5)
        self.bonus_ms     = math.max(7.7   - k * step_ms,     1.5)
        self.spell_amp    = math.max(30.8  - k * step_spell,  1.5)
    end

    -- Apply stats
    local parent = self:GetParent()
    if parent and not parent:IsNull() then
        -- HP scaling
        local base_hp = parent:GetBaseMaxHealth()
        local new_hp = base_hp * self.hp_mult
        parent:SetBaseMaxHealth(new_hp)
        parent:SetMaxHealth(new_hp)
        parent:SetHealth(new_hp)
        
        -- Damage scaling
        local base_dmg_min = parent:GetBaseDamageMin()
        local base_dmg_max = parent:GetBaseDamageMax()
        parent:SetBaseDamageMin(base_dmg_min * self.dmg_mult)
        parent:SetBaseDamageMax(base_dmg_max * self.dmg_mult)
        
        -- Physical armor
        local base_armor = parent:GetPhysicalArmorBaseValue()
        parent:SetPhysicalArmorBaseValue(base_armor + self.bonus_armor)
        
        -- Attack speed
        local base_as = parent:GetBaseAttackSpeed()
        parent:SetBaseAttackSpeed(base_as + self.bonus_as)
        
        -- Move speed
        local base_ms = parent:GetIdealSpeed()
        parent:SetBaseMoveSpeed(base_ms + self.bonus_ms)
        
        -- Scale abilities: increase ability level based on round
        -- This makes all mob abilities (disarm, auras, etc.) stronger each round
        local ability_scale = 1.0
        if round >= 5 then ability_scale = 1.5 end
        if round >= 10 then ability_scale = 2.0 end
        if round >= 15 then ability_scale = 2.5 end
        if round >= 20 then ability_scale = 3.0 end
        if round >= 25 then ability_scale = 3.5 end
        if round >= 30 then ability_scale = 4.0 end
        
        -- Level up abilities to match round scaling
        for i = 0, parent:GetAbilityCount() - 1 do
            local ability = parent:GetAbilityByIndex(i)
            if ability and not ability:IsNull() then
                local max_level = ability:GetMaxLevel()
                if max_level > 0 then
                    -- Scale ability level based on round
                    local target_level = math.min(max_level, math.ceil(ability_scale))
                    if target_level > ability:GetLevel() then
                        ability:SetLevel(target_level)
                    end
                end
            end
        end
    end
end

function modifier_round_scaling:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    }
end

function modifier_round_scaling:GetModifierMagicalResistanceBonus()
    if not self.bonus_mr then return 0 end
    return self.bonus_mr
end

function modifier_round_scaling:GetModifierPhysicalArmorBonus()
    if not self.bonus_armor then return 0 end
    return self.bonus_armor
end

function modifier_round_scaling:GetModifierAttackSpeedBonus_Constant()
    if not self.bonus_as then return 0 end
    return self.bonus_as
end

function modifier_round_scaling:GetModifierMoveSpeedBonus_Constant()
    if not self.bonus_ms then return 0 end
    return self.bonus_ms
end

function modifier_round_scaling:GetModifierSpellAmplify_Percentage()
    if not self.spell_amp then return 0 end
    return self.spell_amp
end