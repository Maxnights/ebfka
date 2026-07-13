-- file: core/buffs_modifier/modifier_buff_codex.lua
LinkLuaModifier("modifier_buff_codex_6", "core/buffs_modifier/modifier_buff_codex", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_buff_codex_7", "core/buffs_modifier/modifier_buff_codex", LUA_MODIFIER_MOTION_NONE)

modifier_buff_codex_6 = class({})
function modifier_buff_codex_6:IsHidden() return true end
function modifier_buff_codex_6:IsPurgable() return false end
function modifier_buff_codex_6:GetTexture() return "tome/codex" end
function modifier_buff_codex_6:RemoveOnDeath() return false end

modifier_buff_codex_7 = class({})
function modifier_buff_codex_7:IsHidden() return true end
function modifier_buff_codex_7:IsPurgable() return false end
function modifier_buff_codex_7:GetTexture() return "tome/codex" end
function modifier_buff_codex_7:RemoveOnDeath() return false end
