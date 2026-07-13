function CalculatePlayerLevel(total_xp)
    local level = 1
    local xp_accumulated = 0

    while true do
        local xp_needed = math.floor(50 + math.pow(level, 1.8)) -- XP yang dibutuhkan untuk naik level berikutnya
        if xp_accumulated + xp_needed > total_xp then
            break
        end
        xp_accumulated = xp_accumulated + xp_needed
        level = level + 1
    end

    local xp_needed_next = math.floor(50 + math.pow(level, 1.8)) -- XP untuk level berikutnya
    local remaining_xp = total_xp - xp_accumulated -- XP yang sudah dikumpulkan di level saat ini
    local xp_in_current_level = xp_needed_next -- XP yang dibutuhkan untuk naik level saat ini

    return level - 1, xp_accumulated, xp_in_current_level, xp_needed_next - remaining_xp
end

-- print("Level Sekarang:", level)
-- print("Total XP pada Level:", xp_at_level)
-- print("XP yang digunakan pada Level itu:", xp_used)
-- print("Sisa XP yang dibutuhkan untuk Level berikutnya:", xp_remaining)

function GetLevelCategory(level)
    if level >= 1 and level <= 5 then
        return "Rookie", {255, 255, 255} -- Putih
    elseif level >= 6 and level <= 10 then
        return "Apprentice", {0, 191, 255} -- Biru Muda (Sky Blue)
    elseif level >= 11 and level <= 20 then
        return "Warrior", {34, 139, 34} -- Hijau Gelap (Forest Green)
    elseif level >= 21 and level <= 35 then
        return "Elite Fighter", {255, 165, 0} -- Oranye (Orange)
    elseif level >= 36 and level <= 50 then
        return "Veteran", {255, 69, 0} -- Merah Oranye (Red-Orange)
    elseif level >= 51 and level <= 75 then
        return "Champion", {138, 43, 226} -- Ungu Muda (Blue Violet)
    elseif level >= 76 and level <= 100 then
        return "Heroic", {255, 215, 0} -- Emas (Gold)
    elseif level >= 101 and level <= 150 then
        return "Legend", {205, 133, 63} -- Perunggu (Peru)
    elseif level >= 151 and level <= 200 then
        return "Demi-God", {186, 85, 211} -- Ungu Mewah (Medium Orchid)
    elseif level >= 201 and level <= 300 then
        return "Godslayer", {255, 0, 0} -- Merah Darah (Red)
    elseif level >= 301 and level <= 400 then
        return "Immortal", {0, 206, 209} -- Cyan Mewah (Dark Turquoise)
    elseif level >= 401 and level <= 500 then
        return "Apex Being", {75, 0, 130} -- Indigo
    else
        return "Beyond Limits", {128, 0, 128} -- Ungu Gelap (Dark Purple)
    end
end


-- print("Level:", level)
-- print("Rank:", category)
-- print("RGB:", "R=" .. rgb[1] .. ", G=" .. rgb[2] .. ", B=" .. rgb[3])
