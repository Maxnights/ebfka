print("PrecacheUnit.lua loaded")
function Precache( context )
	local entity = thisEntity
	local name = entity:GetName()
	print("Precaching unit: ", name, entity:GetUnitName(), entity:GetModelName(), entity:GetClassname(), entity:GetDebugName(), entity:GetEntityIndex())
	-- PrecacheUnitByNameSync(name, context)
	Wearable:Precache(name, context)
end