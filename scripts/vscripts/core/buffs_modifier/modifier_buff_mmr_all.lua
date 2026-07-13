-- core/buffs_modifier/modifier_buff_mmr_all.lua

LinkLuaModifier("modifier_buff_mmr_100", "core/buffs_modifier/modifier_buff_mmr_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_mmr_150", "core/buffs_modifier/modifier_buff_mmr_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_mmr_200", "core/buffs_modifier/modifier_buff_mmr_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_mmr_250", "core/buffs_modifier/modifier_buff_mmr_all", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_mmr_300", "core/buffs_modifier/modifier_buff_mmr_all", LUA_MODIFIER_MOTION_NONE)

modifier_buff_mmr_100 = class({})
modifier_buff_mmr_150 = class({})
modifier_buff_mmr_200 = class({})
modifier_buff_mmr_250 = class({})
modifier_buff_mmr_300 = class({})

function modifier_buff_mmr_100:IsHidden() return true end
function modifier_buff_mmr_100:IsPurgable() return false end
function modifier_buff_mmr_100:RemoveOnDeath() return false end

function modifier_buff_mmr_150:IsHidden() return true end
function modifier_buff_mmr_150:IsPurgable() return false end
function modifier_buff_mmr_150:RemoveOnDeath() return false end

function modifier_buff_mmr_200:IsHidden() return true end
function modifier_buff_mmr_200:IsPurgable() return false end
function modifier_buff_mmr_200:RemoveOnDeath() return false end

function modifier_buff_mmr_250:IsHidden() return true end
function modifier_buff_mmr_250:IsPurgable() return false end
function modifier_buff_mmr_250:RemoveOnDeath() return false end

function modifier_buff_mmr_300:IsHidden() return true end
function modifier_buff_mmr_300:IsPurgable() return false end
function modifier_buff_mmr_300:RemoveOnDeath() return false end
