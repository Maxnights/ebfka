LinkLuaModifier("modifier_buff_xpm_4500", "core/buffs_modifier/modifier_buff_xpm_4500", LUA_MODIFIER_MOTION_NONE)
modifier_buff_xpm_4500 = class({})

function modifier_buff_xpm_4500:IsHidden() return true end
function modifier_buff_xpm_4500:IsPurgable() return false end
function modifier_buff_xpm_4500:RemoveOnDeath() return false end

function modifier_buff_xpm_4500:OnCreated()
    if not IsServer() then return end

    self.xp_per_minute = 4500
    self.interval = 10
    self.xp_per_interval = self.xp_per_minute * (self.interval / 60)

    self:StartIntervalThink(self.interval)
end

function modifier_buff_xpm_4500:OnIntervalThink()
    local parent = self:GetParent()
    if parent and parent:IsRealHero() then
        parent:AddExperience(self.xp_per_interval, DOTA_ModifyXP_Unspecified, false, true)
    end
end
