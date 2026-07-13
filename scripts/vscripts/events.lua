function top10MMR(leaderboard, targetSteamID)
	local targetSteamIDStr = tostring(targetSteamID)
	
    for i, player in pairs(leaderboard) do
        if player.steamID == targetSteamIDStr and tonumber(i) <= 10 then
            return true, player -- Mengembalikan true dan data player jika ditemukan
        end
    end
    return false, nil -- Mengembalikan false jika tidak ditemukan
end

function CHoldoutGameMode:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:IsPhantom() then
		return
	end
	if spawnedUnit:IsCreature() then
		bossManager:onBossSpawn(spawnedUnit)
	end
	if spawnedUnit:IsCourier() then
		spawnedUnit:AddNewModifier( spawnedUnit, nil, "modifier_invulnerable", {} )
	end
	if spawnedUnit:IsNeutralUnitType() then -- make AI ignore neutrals.
		spawnedUnit:RemoveAbility("neutral_upgrade")
	end
	if spawnedUnit:IsIllusion() then
		local heroName = spawnedUnit:GetUnitName()
	end
	if spawnedUnit:IsRealHero() then

        hero.MinorAbilityUpgrades = {}
		hero:AddNewModifier( hero, nil, "modifier_minor_ability_upgrades", {} )
		--self:AddMinorAbilityUpgrade( hPlayerHero, MINOR_ABILITY_UPGRADES[ hPlayerHero:GetUnitName() ][ 2 ] )

		-- Add and level up the base stats upgrade ability
		local hAbility = hero:FindAbilityByName( "aghsfort_minor_stats_upgrade" )
		if hAbility == nil then
			hAbility = hero:AddAbility("aghsfort_minor_stats_upgrade")
		 	hAbility:UpgradeAbility( true )
		 end

		if not spawnedUnit:HasModifier("modifier_thinker_hero_regeneration") then
			spawnedUnit:AddNewModifier( spawnedUnit, nil, "modifier_thinker_hero_regeneration", {} )
		end
		if spawnedUnit:IsTempestDouble() then
			spawnedUnit:AddNewModifier( spawnedUnit, nil, "modifier_special_bonus_attributes_stat_rescaling", {} )
		end
		local attr = spawnedUnit:GetPrimaryAttribute()
		
		if GameRules.lastManStanding then 
			GameRules.lastManStanding:RemoveModifierByName("modifier_last_man_standing")
			GameRules.lastManStanding:StopSound("Imba.WeAreElectric")
		 end
		if not spawnedUnit.buyBackInitialized and PlayerResource:GetGoldSpentOnBuybacks( spawnedUnit:GetPlayerID() ) > 0 then -- only way to detect a buyback...
			spawnedUnit.buyBackInitialized = true
			if GetMapName() == "epic_boss_fight_nightmare" then
				PlayerResource:SetCustomBuybackCooldown( spawnedUnit:GetPlayerID(), 600 )
			else
				PlayerResource:SetCustomBuybackCooldown( spawnedUnit:GetPlayerID(), 180 )
			end
		end
	end
	-- if spawnedUnit:IsConsideredHero() and spawnedUnit:GetUnitName() ~= "npc_dota_healthbar_dummy" then
		-- local dummy = CreateUnitByName("npc_dota_healthbar_dummy", spawnedUnit:GetAbsOrigin(), false, nil, nil, spawnedUnit:GetTeam())
		-- dummy:SetHealthBarOffsetOverride( spawnedUnit:GetBaseHealthBarOffset() )
		-- dummy:AddNewModifier(spawnedUnit, nil, "modifier_healthbar_dummy", {})
		-- spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_hide_healthbar", {})
	-- end
end

function CHoldoutGameMode:OnHeroPick (event)
    local hero = EntIndexToHScript(event.heroindex)

    if IsInToolsMode() or GameRules:IsCheatMode() then
       -- hero:AddItemByName("item_book_of_intelligence"):SetCurrentCharges(100)
       -- hero:AddItemByName("item_book_of_agility"):SetCurrentCharges(100)
       -- hero:AddItemByName("item_book_of_strength"):SetCurrentCharges(100)
       -- hero:AddItemByName("item_butterfly5")
       -- -- hero:AddItemByName("item_imba_rapier_magic_2")
       -- hero:AddItemByName("item_uber_dagon_5")
    end
   --  hero:AddAbility("sven_gods_strength")
   --  hero:AddAbility("necrolyte_sadist")
   --  hero:AddAbility("ogre_magi_multicast")
   --  hero:AddAbility("imba_enigma_black_hole")

--     for i = 0, 30 do
--        local current_ability = hero:GetAbilityByIndex(i)
--        if current_ability ~= nil then
--            print(i .. current_ability:GetAbilityName())
--        else
--            print(i)
--        end
       
--    end

    local playerID = hero:GetPlayerOwnerID()
    
    -- set hero base stats to their intended values
    hero:SetBaseManaRegen( (hero:GetBaseIntellect() / 5) * 0.04 )
    
    hero.damageDone = 0
    hero.Ressurect = 0
    --stats:ModifyStatBonuses(hero)
    local ID = hero:GetPlayerID()
    
    -- Set starting gold to 8k
    hero:SetGold(0, false)
    hero:SetGold(8000, true)
    
   if PlayerResource:IsValidPlayerID( playerID ) then
       local decoded = CustomNetTables:GetTableValue("mmr", tostring( playerID ) )
       local maxstreak  = CustomNetTables:GetTableValue("maxStreak", tostring( playerID ) )
       local mmr = CustomNetTables:GetTableValue("game_state", 'leaderboard_mmr' )
       local found, player = top10MMR(mmr, PlayerResource:GetSteamID(ID))

       if decoded then
           
           if found then
               local heroSpawnImmortalParticle = 'particles/prime/hero_spawn_hero_level_6.vpcf'
               local ImmortalFX = ParticleManager:CreateParticle(heroSpawnImmortalParticle, PATTACH_POINT_FOLLOW, hero )
               hero:AddEffects(ImmortalFX)
           end
           if decoded.mmr > 16000 then
               if PlayerResource:GetSteamAccountID( playerID ) == 108597233  then
                   
                   local itemFX_agha = ParticleManager:CreateParticle("particles/agha/agh_lvl2.vpcf", PATTACH_POINT_FOLLOW, hero )
                   local itemFX = ParticleManager:CreateParticle("particles/radiance/cool_effect.vpcf", PATTACH_POINT_FOLLOW, hero )
                   hero:AddEffects(itemFX_agha)
                   hero:AddEffects(itemFX)

                   
               else
                   -- status hero particle biru saiyan
                   local itemFX = ParticleManager:CreateParticle("particles/radiance/cool_effect_blue_.vpcf", PATTACH_POINT_FOLLOW, hero )
                   hero:AddEffects(itemFX)
               end

               
           elseif decoded.mmr > 25000 then
               local itemFX = ParticleManager:CreateParticle("particles/radiance/cool_effect_orange.vpcf", PATTACH_POINT_FOLLOW, hero)
               hero:AddEffects(itemFX)
           elseif decoded.mmr > 15000 then
               local itemFX = ParticleManager:CreateParticle("particles/radiance/cool_effect_purple.vpcf", PATTACH_POINT_FOLLOW, hero)
               hero:AddEffects(itemFX)
           elseif decoded.mmr > 8000 then
               local itemFX = ParticleManager:CreateParticle("particles/radiance/radiance_green.vpcf", PATTACH_POINT_FOLLOW, hero )
               hero:AddEffects(itemFX)
           else
               
           end
               
               
       end

       if decoded then
           
           if decoded.mmr > 6000 then
               

               -- status hero particle biru saiyan
               PlayerResource._shiva = 'particles/shivas/shivas_blue_active.vpcf'
               PlayerResource._shiva_impact = "particles/items2_fx/shivas_guard_impact.vpcf"
           elseif decoded.mmr > 5000 then
               PlayerResource._shiva = "particles/items2_fx/shivas_guard_active.vpcf"
               PlayerResource._shiva_impact = "particles/items2_fx/shivas_guard_impact.vpcf"
           elseif decoded.mmr > 4000 then
               PlayerResource._shiva = "particles/shivas/shivas_red_active.vpcf"
               PlayerResource._shiva_impact = "particles/items2_fx/shivas_guard_impact.vpcf"
           elseif decoded.mmr > 3000 then
               -- shiva warna hijau
               PlayerResource._shiva = "particles/shivas/shivas_active.vpcf"
               PlayerResource._shiva_impact = "particles/items2_fx/shivas_green_guard_impact.vpcf"
           else
               PlayerResource._shiva = "particles/items2_fx/shivas_guard_active.vpcf"
               PlayerResource._shiva_impact = "particles/items2_fx/shivas_guard_impact.vpcf"
           end
               
               
       end
       
   end

   

   

   local player = PlayerResource:GetPlayer(ID)
   if not player then return end --tester
    player.HB = true
    player.Health_Bar_Open = false
   --[[Timers:CreateTimer(2.5,function()
            if self._NewGamePlus == true and PlayerResource:GetGold(ID)>= 80000 then
                self._Buy_Asura_Core(ID)
            end
            return 2.5
        end)]]

   --[[if PlayerResource:GetSteamAccountID( ID ) == 86736807 then
       print ("look like a chalenger is here :D")
       message_chalenger = true
       self.chalenger = hero
       GameRules:GetGameModeEntity():SetThink( "Chalenger", self, 0.25 )
   end]]
   
   local fountain = nil
   for _,unit in pairs ( Entities:FindAllByName( "*fountain*")) do
       if unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
           fountain = unit
       end
   end
   
   for i = 0, 10 do
       local ability = hero:GetAbilityByIndex( i )
       if ability and ability:IsInnateAbility() then
           ability:SetLevel( 1 )
       end
   end

   local courierPosition = hero:GetAbsOrigin()
   if fountain ~= nil then
       courierPosition = fountain:GetAbsOrigin()
   end

   -- local team = hero:GetTeamNumber()
   -- if team == DOTA_TEAM_GOODGUYS then
       -- local cr = CreateUnitByName("npc_dota_courier", courierPosition + RandomVector(RandomFloat(100, 100)), true, hero, hero, hero:GetTeamNumber())
       -- cr:SetOwner(hero)
       -- cr:SetControllableByPlayer(playerID, true)
   -- end
   
   if hero:GetTeamNumber() == DOTA_TEAM_BADGUYS then
       -- DeleteAbility(hero)
       -- TeachAbility (hero , "hide_hero")
       hero:AddNoDraw()
       self.boss_master_id = ID
   end

   CustomGameEventManager:Send_ServerToAllClients("UpdateLife", {life = Life._life})
   
   hero.damage_dealt_ingame = 0
   hero.damage_taken_ingame = 0
   hero.damage_healed_ingame = 0

   hero._heroManaType = GameRules.HeroKV[hero:GetUnitName()].ManaType or "Mana"
   
   if hero:GetManaType() == "Mana" then
       hero:SetBaseManaRegen( (hero:GetBaseIntellect() / 5) * 0.04 )
   else
       hero:SetBaseManaRegen( 0 )
   end

   CustomNetTables:SetTableValue("game_stats", tostring( playerID ), {damage_dealt = 0, damage_taken = 0, damage_healed = 0, last_damage_dealt = 0})
   CustomNetTables:SetTableValue("hero_attributes", tostring( hero:entindex() ), {mana_type = hero._heroManaType})

   PlayerResource:SetCustomBuybackCooldown( playerID, 10 )
   PlayerResource:SetCustomBuybackCost( playerID, 100 )
   
     -- Final gold enforcement with delay to override any other gold-giving systems
     Timers:CreateTimer(5.0, function()
         if hero and not hero:IsNull() and hero:IsRealHero() then
             hero:SetGold(0, false)
             hero:SetGold(8000, true)
             
             -- Final inventory cleanup - remove ALL items, then give only bottle
             for itemSlot = 0, 11 do
                 local item = hero:GetItemInSlot(itemSlot)
                 if item then
                     hero:RemoveItem(item)
                 end
             end
             
             -- Give bottle
             hero:AddItemByName("item_bottle")
             
             print("[EBF] Player " .. hero:GetPlayerID() .. " starting gold set to 8000, items cleaned")
         end
     end)

   hero:SetDayTimeVisionRange(1200)
   hero:SetNightTimeVisionRange(750)	
end