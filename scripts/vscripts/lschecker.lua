function StartNaixCliffChecker()
    Timers:CreateTimer(1.0, function()
        local players = HeroList:GetAllHeroes()

        for _, hero in pairs(players) do
            if hero and not hero:IsNull() and hero:IsAlive() and hero:GetUnitName() == "npc_dota_hero_life_stealer" then
                CheckAndResetNaixPosition(hero)
            end
        end

        return 0.5 -- cek setiap 0.5 detik
    end)
end


function CheckAndResetNaixPosition(unit)
    if not unit or unit:IsNull() then return end

    local pos = unit:GetAbsOrigin()
    local isValid = GridNav:IsTraversable(pos) and not GridNav:IsBlocked(pos)
    local isTooHigh = pos.z > 2000 or pos.z < -500

    if not isValid or isTooHigh then
        -- Reset posisi ke lokasi aman
        local safePos = GetSafeCenterPosition()
        FindClearSpaceForUnit(unit, safePos, true)
        unit:Stop()

        -- Efek suara + notifikasi error
        EmitSoundOn("General.CastFail_InvalidTarget_Hero", unit)
    end
end

function GetSafeCenterPosition()
    -- Misalnya koordinat fountain Radiant
    return Vector(0.073895, -0.111816, 397.000122)
end
