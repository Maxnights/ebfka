LinkLuaModifier("modifier_buff_xpm_2200", "core/buffs_modifier/modifier_buff_xpm_2200", LUA_MODIFIER_MOTION_NONE)
modifier_buff_xpm_2200 = class({})

function modifier_buff_xpm_2200:IsHidden() return true end
function modifier_buff_xpm_2200:IsPurgable() return false end
function modifier_buff_xpm_2200:RemoveOnDeath() return false end

function modifier_buff_xpm_2200:OnCreated()
    if not IsServer() then return end

    self.xp_per_minute = 2200
    self.interval = 10
    self.xp_per_interval = self.xp_per_minute * (self.interval / 60)

    self:StartIntervalThink(self.interval)
end

function modifier_buff_xpm_2200:OnIntervalThink()
    local parent = self:GetParent()
    if parent and parent:IsRealHero() then
        parent:AddExperience(self.xp_per_interval, DOTA_ModifyXP_Unspecified, false, true)
    end
end
