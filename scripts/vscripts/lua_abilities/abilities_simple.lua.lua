LinkLuaModifier( "modifier_abilities_simple", "lua_abilities/abilities_simple.lua.lua", LUA_MODIFIER_MOTION_NONE )
--Abilities
if abilities_simple == nil then
	abilities_simple = class({})
end
function abilities_simple:GetIntrinsicModifierName()
	return "modifier_abilities_simple"
end
---------------------------------------------------------------------
--Modifiers
if modifier_abilities_simple == nil then
	modifier_abilities_simple = class({})
end
function modifier_abilities_simple:OnCreated(params)
	if IsServer() then
	end
end
function modifier_abilities_simple:OnRefresh(params)
	if IsServer() then
	end
end
function modifier_abilities_simple:OnDestroy()
	if IsServer() then
	end
end
function modifier_abilities_simple:DeclareFunctions()
	return {
	}
end