GameFilters = class({})

function CHoldoutGameMode:ItemAddedFilter(keys)
    -- Typical keys:
    -- inventory_parent_entindex_const: 852
    -- item_entindex_const: 1519
    -- item_parent_entindex_const: -1
    -- suggested_slot: -1
    local unit = EntIndexToHScript(keys.inventory_parent_entindex_const)
    if unit == nil then return end
    local item = EntIndexToHScript(keys.item_entindex_const)
    if item == nil then return end


    -- This is currently done by default and does not use the ENABLE_TPSCROLL_ON_FIRST_SPAWN variable
    -- if item:GetAbilityName() == "item_tpscroll" and item:GetPurchaser() == nil then
    -- item:EndCooldown()

    -- return ENABLE_TPSCROLL_ON_FIRST_SPAWN

    -- -- return false to remove it
    -- --       return false
    -- end

    local item_name = nil

    -- this event is broken in dota, so calling it from here instead (Credits: Pohka)
    if item.OnItemEquipped ~= nil then
        item:OnItemEquipped(item)
    end

    if item:GetName() then
        item_name = item:GetName()
    end

    if item.IsRapier then
        return true
    end

    if item and unit and unit:IsRealHero() then
		local itemName = item:GetName()
		local unitName = unit:GetUnitName()
        local blacklist_for_item = item_blacklist[itemName]
        if blacklist_for_item and blacklist_for_item[unitName] then
            print("[BLOCK] Blacklisted item", itemName, "picked up by", unitName)
            unit:DropItemAtPositionImmediate(item, unit:GetAbsOrigin())
            return false
        end

		-- 🔒 Cek donator whitelist
        for modifier_name, allowed_items in pairs(item_donator) do
            if allowed_items[itemName] then
                if not unit:HasModifier(modifier_name) then
                    print("[BLOCK] Donator-only item", itemName, "picked up by", unitName, "without", modifier_name)
                    unit:DropItemAtPositionImmediate(item, unit:GetAbsOrigin())
                    return false
                end
            end
        end
	end
    -------------------------------------------------------------------------------------------------
    -- Rapier pickup logic
    -------------------------------------------------------------------------------------------------
    if item.IsRapier then
        if item.rapier_pfx then
            ParticleManager:DestroyParticle(item.rapier_pfx, false)
            ParticleManager:ReleaseParticleIndex(item.rapier_pfx)
            item.rapier_pfx = nil
        end
        if item.x_pfx then
            ParticleManager:DestroyParticle(item.x_pfx, false)
            ParticleManager:ReleaseParticleIndex(item.x_pfx)
            item.x_pfx = nil
        end
        if unit:IsRealHero() or (unit:GetClassname() == "npc_dota_lone_druid_bear") then
            -- If the rapier has a purchaser (WARNING: if the courier buys it, item:GetPurchaser() is nil), and someone from the opposite team picks it up, then it becomes a free rapier
            -- Gonna make a pretty bold assumption here; there is the edge case where someone's inventory is full, they buy rapiers from courier which then drop the rapiers, and then someone from the enemy team picks it up; this code would then make THEM the original purchaser
            -- ...well I'm just trying to make rapiers not disappear first
            if not item:GetPurchaser() then
                item:SetPurchaser(unit)
            end

            if item:GetPurchaser() and item:GetPurchaser():GetTeamNumber() ~= unit:GetTeamNumber() then
                item.free = true
            end


        end

        if unit:IsIllusion() or unit:IsTempestDouble() or unit:IsHero() then
            return true
        else
            unit:DropItem(nil, item_name, true)
        end

        return false
end

    return true
end

function CHoldoutGameMode:FilterOrders( filterTable )
    if not filterTable.units then return true end
    local orderType = filterTable.order_type
    local unit = EntIndexToHScript(filterTable.units["0"] or 0)
    local ability = EntIndexToHScript(filterTable.entindex_ability)
    local target = EntIndexToHScript(filterTable.entindex_target)

    -- print(string.format("Order Filter: Unit=%s, OrderType=%d, Target=%s, Ability=%s", unit and unit:GetUnitName() or "nil", orderType, target and target:GetUnitName() or "nil", ability and ability:GetAbilityName() or "nil"))

    -- cancel tombstone channeling when hero issues a move/stop order
    if unit and unit:HasModifier("modifier_tombstone_channeling_root") then
        if orderType == DOTA_UNIT_ORDER_MOVE_TO_POSITION or
           orderType == DOTA_UNIT_ORDER_MOVE_TO_TARGET or
           orderType == DOTA_UNIT_ORDER_MOVE_TO_DIRECTION or
           orderType == DOTA_UNIT_ORDER_ATTACK_MOVE or
           orderType == DOTA_UNIT_ORDER_STOP then
            unit:RemoveModifierByName("modifier_tombstone_channeling_root")
            unit._tombstoneCancelledAt = Time()
        end
    end

    if unit and unit:GetUnitName() == "npc_dota_hero_void_spirit" then
        if orderType == DOTA_UNIT_ORDER_MOVE_TO_POSITION or
            orderType == DOTA_UNIT_ORDER_MOVE_TO_DIRECTION then
            local newPos = Vector(
                filterTable["position_x"] or 0,
                filterTable["position_y"] or 0,
                filterTable["position_z"] or 0
            )
            unit.newPos = newPos
        end

    end

    if orderType == DOTA_UNIT_ORDER_PURCHASE_ITEM then
        if unit ~= nil and unit:HasModifier("modifier_ban_movement") then
            DisplayError(unit:GetPlayerOwnerID(), "CANT BUY")
            return false
        end

        local item_name = filterTable.shop_item_name
        print("ITEM NAME: "..item_name)
        local player_id = filterTable.issuer_player_id_const

        -- Ambil hero utama dari player
        local hero = PlayerResource:GetSelectedHeroEntity(player_id)
        if hero and item_blacklist[item_name] and item_blacklist[item_name][hero:GetUnitName()] then
            DisplayError(unit:GetPlayerOwnerID(), "error_cannot_buy_item")
			return false
		end

        -- Cek whitelist donator
        for modifier_name, allowed_items in pairs(item_donator) do
            if allowed_items[item_name] then
                if not hero:HasModifier(modifier_name) then
                    DisplayError(unit:GetPlayerOwnerID(), "#error_donator_only")
                    return false
                end
            end
        end
    end
    if orderType == DOTA_UNIT_ORDER_MOVE_TO_TARGET then
        if (target and target:GetTeam() == unit:GetTeam() and PlayerResource:IsDisableHelpSetForPlayerID(target:GetPlayerOwnerID(), unit:GetPlayerOwnerID())) then
            DisplayError(unit:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
            return false
        end
    end

    if ability and ability:GetName() == "rubick_spell_steal" and target == unit then
        DisplayError(unit:GetPlayerOwnerID(), "dota_hud_error_cant_cast_on_self")
        return false
    end

    if ability and ability:GetName() == "item_ultimate_scepter"
      and unit and unit:GetUnitName() == "npc_dota_hero_alchemist"
      and target and target:GetUnitName() == "npc_dota_hero_invoker" then
       DisplayError(unit:GetPlayerOwnerID(), "dota_hud_error_invokerbug")
        return false
      end

    -- Allow moving any item into neutral slots (12,13,14) and out of them
    if orderType == DOTA_UNIT_ORDER_MOVE_ITEM then
        local targetSlot = filterTable.entindex_target
        if unit and unit:IsRealHero() and targetSlot and targetSlot >= 12 and targetSlot <= 14 then
            return true
        end
        if ability and ability:GetOwner() and ability:GetOwner():IsRealHero() then
            local curSlot = ability:GetItemSlot()
            if curSlot and curSlot >= 12 and curSlot <= 14 then
                return true
            end
        end
    end

    return VectorTarget:OrderFilter( filterTable )
end

function CHoldoutGameMode:FilterGold( filterTable )
    local hero = PlayerResource:GetSelectedHeroEntity( filterTable.player_id_const )
    local startGold = filterTable.gold
    if hero then
        local bonusGold = 0
        -- local midas = hero:FindModifierByName("modifier_hand_of_midas_passive")
        -- if midas then
            -- bonusGold = math.floor( startGold * (midas.bonus_gold or 0) )
        -- end
        if hero:HasAbility("alchemist_goblins_greed") then
            bonusGold = math.floor( startGold * hero:FindAbilityByName("alchemist_goblins_greed"):GetSpecialValueFor("bonus_gold")  / 100 )
        end
        bonusGold = bonusGold + math.floor( startGold * (GameRules:GetPlayerGoldMultiplier()-1) )
        if bonusGold > 0 then
            bonusGold = bonusGold + (hero.bonusGoldExcessValue or 0)
            hero.bonusGoldExcessValue = bonusGold % 1
            hero:AddGold( bonusGold, true )
        end
    end
    return true
end

function CHoldoutGameMode:FilterHealing( filterTable )
	local healer_index = filterTable["entindex_healer_const"]
	local target_index = filterTable["entindex_target_const"]

	if not target_index then return true end
	local target = EntIndexToHScript( target_index )
	local healer = target
	if healer_index then
		healer = EntIndexToHScript( healer_index )
	end
	filterTable["heal"] = math.min( filterTable["heal"], target:GetMaxHealth() )
	local posAmp = 1
	local negAmp = 1
	for _, modifier in ipairs( target:FindAllModifiers() ) do
		if modifier.GetModifierPropertyRestorationAmplification then
			local amp = modifier:GetModifierPropertyRestorationAmplification() / 100
			if amp then
				if amp > 0 then
					posAmp = posAmp + amp
				elseif amp < 0 then
					negAmp = negAmp + amp
				end
			end
		end
	end
	filterTable["heal"] = filterTable["heal"] * posAmp * negAmp

    if not healer_index then return true end
	healer.damage_healed_ingame = (healer.damage_healed_ingame or 0) + filterTable["heal"]

	return true
end

function CHoldoutGameMode:FilterAbilityValues( filterTable )
    if self.preventLoopGarbage then return end
    local caster_index = filterTable["entindex_caster_const"]
    local ability_index = filterTable["entindex_ability_const"]
    if not caster_index or not ability_index then
        return true
    end
    local ability = EntIndexToHScript( ability_index )
    local caster = EntIndexToHScript( caster_index )

    if ability and IGNORE_SPELL_AMP_KV[ability:GetName()] and IGNORE_SPELL_AMP_KV[ability:GetName()][filterTable.value_name_const] then
        local value = filterTable.value
        self.preventLoopGarbage = true
        -- get the real ability value because valve hates me
        local realValue = ability:GetSpecialValueFor(filterTable.value_name_const)
        self.preventLoopGarbage = false
        filterTable.value = realValue / ( 1+caster:GetSpellAmplification( false ) ) - (realValue-value)
    end
    -- aoe bonus until valve fixes their shit
    if not ability then return true end
    local abilityValues = ability:GetAbilityKeyValues().AbilityValues
    if abilityValues
    and type(abilityValues[filterTable.value_name_const]) == "table"
    and toboolean(abilityValues[filterTable.value_name_const].affected_by_aoe_increase) then
        local aoe_bonus_positive = 0
        local aoe_bonus_negative = 0
        for _, modifier in ipairs( caster:FindAllModifiers() ) do
            if modifier.GetModifierAoEBonusConstant and modifier:GetModifierAoEBonusConstant() then
                if modifier:GetModifierAoEBonusConstant() > 0 then
                    aoe_bonus_positive = math.max( aoe_bonus_positive, modifier:GetModifierAoEBonusConstant() )
                else
                    aoe_bonus_negative = math.min( aoe_bonus_negative, modifier:GetModifierAoEBonusConstant() )
                end
            end
        end
        filterTable.value = filterTable.value + aoe_bonus_positive + aoe_bonus_negative
    end
    return true
end

function CHoldoutGameMode:FilterDamage( filterTable )
    local total_damage_team = 0
    local dps = 0
    local victim_index = filterTable["entindex_victim_const"]
    local attacker_index = filterTable["entindex_attacker_const"]
    if not victim_index or not attacker_index then
        return true
    end
    local damage = filterTable["damage"] --Post reduction
    local inflictor = filterTable["entindex_inflictor_const"]
    local victim = EntIndexToHScript( victim_index )
    local attacker = EntIndexToHScript( attacker_index )
    local ability = (inflictor ~= nil) and EntIndexToHScript( inflictor )
    local original_attacker = attacker -- make a copy for threat
    local damagetype = filterTable["damagetype_const"]

    -- If the attacker is holding an Arcane/Archmage/Cursed Rapier and the distance is over the cap, remove the spellpower bonus from it
    if attacker:HasModifier("modifier_imba_arcane_rapier") or attacker:HasModifier("modifier_imba_arcane_rapier_2") or attacker:HasModifier("modifier_imba_rapier_cursed") then
        local distance = (attacker:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D()
        print("Distance: " .. distance)

        local rapier_spellpower = 0

        -- Get all modifiers, gather how much spellpower the target has from rapiers
        local modifiers = attacker:FindAllModifiers()

        for _, modifier in pairs(modifiers) do
            -- Increment Cursed Rapier's spellpower
            if modifier:GetName() == "modifier_imba_rapier_cursed" then
                rapier_spellpower = rapier_spellpower + modifier:GetAbility():GetSpecialValueFor("spell_power")

                -- Increment Archmage Rapier spellpower
            elseif modifier:GetName() == "modifier_imba_arcane_rapier_2" then
                rapier_spellpower = rapier_spellpower + modifier:GetAbility():GetSpecialValueFor("spell_power")

                -- Increment Arcane Rapier spellpower
            elseif modifier:GetName() == "modifier_imba_arcane_rapier" then
                rapier_spellpower = rapier_spellpower + modifier:GetAbility():GetSpecialValueFor("spell_power")
            end
        end

        if distance < 2500 then
            -- If spellpower was accumulated, reduce the damage
            if rapier_spellpower > 0 then


                if damagetype == DAMAGE_TYPE_PURE then
                    -- jika pure damage maka reduce 10%
                    filterTable.damage = filterTable.damage * 0.9
                end
            end
        else
            if rapier_spellpower > 0 then
                print("Menggunakan arcane rapier dan diluar 2500 meter")
                filterTable.damage = filterTable.damage / (1 + rapier_spellpower / 100)
            end

        end
    end

    if victim:HasModifier("modifier_necrolyte_heartstopper_aura_effect") and victim:HasModifier("modifier_item_aeon_disk_effect") then
        filterTable.damage = 0
    end


    if damage <= 0 then return true end
    --- DAMAGE MANIPULATION ---
    if ability and IGNORE_SPELL_AMP_FILTER[ability:GetName()] then
        -- print(ability:GetName())
        -- print("Ability: " .. ability:GetName())
        -- print(IGNORE_SPELL_AMP_FILTER[ability:GetName()])
        -- print(attacker:GetSpellAmplification( false ))
        -- print(IGNORE_SPELL_AMP_FILTER[ability:GetName()]/100)
        -- print("Damage: " .. damage)

        filterTable.damage = damage / ( 1+ ( attacker:GetSpellAmplification( false ) * (IGNORE_SPELL_AMP_FILTER[ability:GetName()]/100)) )
    end

    -- if GetMapName() == "epic_boss_fight_purgatory" then
    --     local player_count = 0
    --     for playerID = 0, DOTA_MAX_PLAYERS-1 do
    --         if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
    --             player_count = player_count + 1
    --         end
    --     end

    --     local multiplier = player_count / 10
    --     filterTable.damage = damage * multiplier
    -- end


    -- MUERTA SPECIFIC FIX: undo spell amp for PTV-converted attack damage only, skip item inflictors
    if ((ability and ability:GetName() == "muerta_gunslinger") or attacker:HasModifier("modifier_muerta_pierce_the_veil_buff"))
        and not (ability and ability:IsItem()) then
        filterTable.damage = damage / ( 1+ ( attacker:GetSpellAmplification( false ) * (IGNORE_SPELL_AMP_FILTER["muerta_pierce_the_veil"]/100)) )
    end

    if inflictor and attacker and not attacker:IsNull() and attacker.HasModifier and  attacker:HasModifier("spell_crit") then
        print("Spel Crit")
        local critDamage = 1
        for _, modifier in ipairs( attacker:FindAllModifiersByName("spell_crit") ) do
            local item = modifier:GetAbility()
            local critChance = item:GetSpecialValueFor("spell_crit_chance")
            local newCritDamage = item:GetSpecialValueFor("spell_crit_multiplier") / 100
            if critDamage < newCritDamage and RollPercentage( critChance ) then
                critDamage = newCritDamage
            end
        end
        if critDamage > 1 then
            filterTable["damage"] = damage * critDamage
            SendOverheadEventMessage( attacker:GetPlayerOwner(), OVERHEAD_ALERT_DEADLY_BLOW, victim, damage * critDamage, attacker:GetPlayerOwner() )
        end
    end

    if attacker.GetPlayerOwner and attacker:GetPlayerOwner() and attacker ~= victim then
        local heroToAssign = PlayerResource:GetSelectedHeroEntity( attacker:GetPlayerOwner():GetPlayerID() )
        heroToAssign.damage_dealt_ingame = (heroToAssign.damage_dealt_ingame or 0) + filterTable["damage"]
        heroToAssign.last_damage_dealt = filterTable["damage"]
    end
    if victim.GetPlayerOwner and victim:GetPlayerOwner() and attacker ~= victim  then
        local heroToAssign = PlayerResource:GetSelectedHeroEntity( victim:GetPlayerOwner():GetPlayerID() )
        heroToAssign.damage_taken_ingame = (heroToAssign.damage_taken_ingame or 0) + filterTable["damage"]
    end

    return true
end

function GameFilters:init(self)
    GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter(Dynamic_Wrap(CHoldoutGameMode, "ItemAddedFilter"), self)
    GameRules:GetGameModeEntity():SetDamageFilter( Dynamic_Wrap( CHoldoutGameMode, "FilterDamage" ), self )
    GameRules:GetGameModeEntity():SetAbilityTuningValueFilter( Dynamic_Wrap( CHoldoutGameMode, "FilterAbilityValues" ), self )
    GameRules:GetGameModeEntity():SetHealingFilter( Dynamic_Wrap( CHoldoutGameMode, "FilterHealing" ), self )
    GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( CHoldoutGameMode, "FilterOrders" ), self )
    GameRules:GetGameModeEntity():SetModifyGoldFilter( Dynamic_Wrap( CHoldoutGameMode, "FilterGold" ), self )
end