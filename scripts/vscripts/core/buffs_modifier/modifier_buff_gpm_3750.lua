LinkLuaModifier("modifier_buff_gpm_3750", "core/buffs_modifier/modifier_buff_gpm_3750", LUA_MODIFIER_MOTION_NONE)
modifier_buff_gpm_3750 = class({})

function modifier_buff_gpm_3750:IsHidden() return true end
function modifier_buff_gpm_3750:IsPurgable() return false end
function modifier_buff_gpm_3750:RemoveOnDeath() return false end

function modifier_buff_gpm_3750:OnCreated()
    if not IsServer() then return end

    self.gold_per_minute = 3750
    self.interval = 10
    self.gold_per_interval = self.gold_per_minute * (self.interval / 60)

    self:StartIntervalThink(self.interval)
end

function modifier_buff_gpm_3750:OnIntervalThink()
    local parent = self:GetParent()
    if parent and parent:IsRealHero() then
        PlayerResource:ModifyGold(parent:GetPlayerOwnerID(), self.gold_per_interval, true, DOTA_ModifyGold_Unspecified)
        SendOverheadEventMessage(parent, OVERHEAD_ALERT_GOLD, parent, self.gold_per_interval, nil)
    end
end
