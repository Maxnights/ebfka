if HeroSoundManager == nil then
	HeroSoundManager = class({})
end

function HeroSoundManager:Init()
	if self.initialized then
		return
	end

	self.initialized = true
	self.mutedByListener = {}
	self.customActiveSounds = {}

	CustomGameEventManager:RegisterListener("toggle_hero_sound_mute", function(_, event)
		self:OnToggleHeroSoundMute(event)
	end)
end

function HeroSoundManager:OnToggleHeroSoundMute(event)
	if not event then return end

	local listenerID = event.PlayerID
	local targetID = event.target_player_id
	local muted = event.muted

	if type(listenerID) ~= "number" or type(targetID) ~= "number" then
		return
	end

	if not PlayerResource:IsValidPlayerID(listenerID) then
		return
	end

	if not PlayerResource:IsValidPlayerID(targetID) then
		return
	end

	local shouldMute = (muted == 1) or (muted == true) or (tostring(muted) == "1")

	self.mutedByListener[listenerID] = self.mutedByListener[listenerID] or {}
	local targetKey = tostring(targetID)

	if shouldMute then
		self.mutedByListener[listenerID][targetKey] = 1
	else
		self.mutedByListener[listenerID][targetKey] = nil
		if self:TableIsEmpty(self.mutedByListener[listenerID]) then
			self.mutedByListener[listenerID] = nil
		end
	end

	self:SyncNetTable(listenerID)
end

function HeroSoundManager:SyncNetTable(listenerID)
	if not PlayerResource:IsValidPlayerID(listenerID) then
		return
	end

	local data = self.mutedByListener[listenerID]
	if not data then
		CustomNetTables:SetTableValue("hero_sound_mutes", tostring(listenerID), {})
	else
		CustomNetTables:SetTableValue("hero_sound_mutes", tostring(listenerID), data)
	end
end

function HeroSoundManager:TableIsEmpty(tbl)
	if not tbl then return true end
	return next(tbl) == nil
end

function HeroSoundManager:GetUnitOwnerPlayerID(unit)
	if not unit or unit:IsNull() then
		return -1
	end

	local ownerID = -1
	if unit.GetPlayerOwnerID then
		ownerID = unit:GetPlayerOwnerID()
	end

	if ownerID and ownerID >= 0 then
		return ownerID
	end

	if unit.GetOwner then
		local owner = unit:GetOwner()
		if owner and owner.GetPlayerOwnerID then
			ownerID = owner:GetPlayerOwnerID()
		end
	end

	if ownerID ~= nil and ownerID >= 0 then
		return ownerID
	end

	return -1
end

function HeroSoundManager:IsMutedForPlayer(listenerID, ownerID)
	if not ownerID or ownerID < 0 then
		return false
	end

	local mapping = self.mutedByListener[listenerID]
	if not mapping then
		return false
	end

	return mapping[tostring(ownerID)] ~= nil
end

function HeroSoundManager:AnyMuteForOwner(ownerID)
	if not ownerID or ownerID < 0 then
		return false
	end

	for listenerID, mapping in pairs(self.mutedByListener) do
		if mapping and mapping[tostring(ownerID)] ~= nil then
			return true
		end
	end

	return false
end

function HeroSoundManager:GetListeners(ownerID)
	local listeners = {}
	for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:IsValidPlayerID(playerID) then
			local player = PlayerResource:GetPlayer(playerID)
			if player and not self:IsMutedForPlayer(playerID, ownerID) then
				table.insert(listeners, player)
			end
		end
	end

	return listeners
end

function HeroSoundManager:SendSoundEvent(players, payload, stop)
	if not players or #players == 0 then
		return
	end

	local eventName = stop and "hero_sound_stop" or "hero_sound_play"
	for _, player in pairs(players) do
		if player then
			CustomGameEventManager:Send_ServerToPlayer(player, eventName, payload)
		end
	end
end

function HeroSoundManager:MarkCustomSound(entityIndex, soundName)
	if not entityIndex or not soundName then return end

	self.customActiveSounds[entityIndex] = self.customActiveSounds[entityIndex] or {}
	self.customActiveSounds[entityIndex][soundName] = true
end

function HeroSoundManager:ClearCustomSound(entityIndex, soundName)
	if not entityIndex or not soundName then return end

	local mapping = self.customActiveSounds[entityIndex]
	if not mapping then return end

	mapping[soundName] = nil

	if next(mapping) == nil then
		self.customActiveSounds[entityIndex] = nil
	end
end

function HeroSoundManager:ShouldUseCustomBroadcast(ownerID)
	return self:AnyMuteForOwner(ownerID)
end

function HeroSoundManager:PlaySoundFromUnit(unit, soundName, options)
	if not unit or unit:IsNull() or not soundName then
		return
	end

	options = options or {}

	local ownerID = self:GetUnitOwnerPlayerID(unit)
	if not self:ShouldUseCustomBroadcast(ownerID) then
		self:ClearCustomSound(unit:GetEntityIndex(), soundName)
		unit:EmitSound(soundName)
		return
	end

	local listeners = self:GetListeners(ownerID)
	if #listeners == 0 then
		self:MarkCustomSound(unit:GetEntityIndex(), soundName)
		return
	end

	self:MarkCustomSound(unit:GetEntityIndex(), soundName)

	local payload = {
		sound = soundName,
		entity_index = unit:GetEntityIndex()
	}

	if options.location then
		payload.location = { x = options.location.x, y = options.location.y, z = options.location.z }
	end

	self:SendSoundEvent(listeners, payload, false)
end

function HeroSoundManager:PlaySoundAtLocation(sourceUnit, location, soundName)
	if not location or not soundName then
		return
	end

	local ownerID = -1
	if sourceUnit and not sourceUnit:IsNull() then
		ownerID = self:GetUnitOwnerPlayerID(sourceUnit)
	end

	if ownerID == -1 or not self:ShouldUseCustomBroadcast(ownerID) then
		EmitSoundOnLocationWithCaster(location, soundName, sourceUnit)
		return
	end

	local listeners = self:GetListeners(ownerID)
	if #listeners == 0 then
		return
	end

	local payload = {
		sound = soundName,
		location = { x = location.x, y = location.y, z = location.z }
	}

	self:SendSoundEvent(listeners, payload, false)
end

function HeroSoundManager:StopSoundFromUnit(unit, soundName)
	if not unit or unit:IsNull() or not soundName then
		return
	end

	local entityIndex = unit:GetEntityIndex()
	local mapping = self.customActiveSounds[entityIndex]

	if not mapping or not mapping[soundName] then
		StopSoundOn(soundName, unit)
		return
	end

	self:ClearCustomSound(entityIndex, soundName)

	local ownerID = self:GetUnitOwnerPlayerID(unit)
	local listeners = self:GetListeners(ownerID)
	if #listeners == 0 then
		return
	end

	local payload = {
		sound = soundName,
		entity_index = entityIndex
	}

	self:SendSoundEvent(listeners, payload, true)
end
