-- File: modifiers/modifier_buff_stats.lua
LinkLuaModifier("modifier_buff_cast_range_300", "core/buffs_modifier/modifier_buff_stats.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_spell_amp_250", "core/buffs_modifier/modifier_buff_stats.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_status_resist_50", "core/buffs_modifier/modifier_buff_stats.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_move_speed_250", "core/buffs_modifier/modifier_buff_stats.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_attack_speed_700", "core/buffs_modifier/modifier_buff_stats.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_imba_rev_spell_amp_10", "core/buffs_modifier/modifier_buff_stats.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_limitless_movespeed", "core/buffs_modifier/modifier_buff_stats.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_s_reward_x3", "core/buffs_modifier/modifier_buff_stats.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_projectile_speed_400", "core/buffs_modifier/modifier_buff_stats.lua", LUA_MODIFIER_MOTION_NONE)


modifier_buff_cast_range_300 = class({})
function modifier_buff_cast_range_300:DeclareFunctions()
    return { MODIFIER_PROPERTY_CAST_RANGE_BONUS }
end
function modifier_buff_cast_range_300:GetModifierCastRangeBonus() return 300 end
function modifier_buff_cast_range_300:IsHidden() return true end
function modifier_buff_cast_range_300:IsPurgable() return false end
function modifier_buff_cast_range_300:RemoveOnDeath() return false end

modifier_buff_spell_amp_250 = class({})
function modifier_buff_spell_amp_250:DeclareFunctions()
    return { MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE }
end
function modifier_buff_spell_amp_250:GetModifierSpellAmplify_Percentage() return 250 end
function modifier_buff_spell_amp_250:IsHidden() return true end
function modifier_buff_spell_amp_250:IsPurgable() return false end
function modifier_buff_spell_amp_250:RemoveOnDeath() return false end

modifier_buff_status_resist_50 = class({})
function modifier_buff_status_resist_50:DeclareFunctions()
    return { MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING }
end
function modifier_buff_status_resist_50:GetModifierStatusResistanceStacking() return 50 end
function modifier_buff_status_resist_50:IsHidden() return true end
function modifier_buff_status_resist_50:IsPurgable() return false end
function modifier_buff_status_resist_50:RemoveOnDeath() return false end

modifier_buff_move_speed_250 = class({})
function modifier_buff_move_speed_250:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT }
end
function modifier_buff_move_speed_250:GetModifierMoveSpeedBonus_Constant() return 250 end
function modifier_buff_move_speed_250:IsHidden() return true end
function modifier_buff_move_speed_250:IsPurgable() return false end
function modifier_buff_move_speed_250:RemoveOnDeath() return false end

modifier_buff_attack_speed_700 = class({})
function modifier_buff_attack_speed_700:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_buff_attack_speed_700:GetModifierAttackSpeedBonus_Constant() return 700 end
function modifier_buff_attack_speed_700:IsHidden() return true end
function modifier_buff_attack_speed_700:IsPurgable() return false end
function modifier_buff_attack_speed_700:RemoveOnDeath() return false end

modifier_buff_imba_rev_spell_amp_10 = class({})
function modifier_buff_imba_rev_spell_amp_10:DeclareFunctions()
    return { MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE }
end
function modifier_buff_imba_rev_spell_amp_10:GetModifierSpellAmplify_Percentage() return 10 end
function modifier_buff_imba_rev_spell_amp_10:IsHidden() return true end
function modifier_buff_imba_rev_spell_amp_10:IsPurgable() return false end
function modifier_buff_imba_rev_spell_amp_10:RemoveOnDeath() return false end

modifier_buff_limitless_movespeed = class({})
function modifier_buff_limitless_movespeed:DeclareFunctions()
    return { MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT }
end
function modifier_buff_limitless_movespeed:GetModifierIgnoreMovespeedLimit() return 1 end
function modifier_buff_limitless_movespeed:IsHidden() return true end
function modifier_buff_limitless_movespeed:IsPurgable() return false end
function modifier_buff_limitless_movespeed:RemoveOnDeath() return false end

modifier_buff_s_reward_x3 = class({})
function modifier_buff_s_reward_x3:IsHidden() return true end
function modifier_buff_s_reward_x3:IsPurgable() return false end
function modifier_buff_s_reward_x3:RemoveOnDeath() return false end
-- Tambahkan efek khusus di tempat lain jika diperlukan

modifier_buff_projectile_speed_400 = class({})
function modifier_buff_projectile_speed_400:DeclareFunctions()
    return { MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS }
end
function modifier_buff_projectile_speed_400:GetModifierProjectileSpeedBonus() return 400 end
function modifier_buff_projectile_speed_400:IsHidden() return true end
function modifier_buff_projectile_speed_400:IsPurgable() return false end
function modifier_buff_projectile_speed_400:RemoveOnDeath() return false end
