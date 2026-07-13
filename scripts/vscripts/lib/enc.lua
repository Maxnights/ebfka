
-- AUTH_KEY tersedia via GetAuthKey() dari utility.lua

local function stringToHex(str)
    return (str:gsub('.', function(c)
        return string.format('%02X', string.byte(c))
    end))
end

-- Fungsi untuk konversi hex ke string
local function hexToString(hex)
    return (hex:gsub('..', function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

local function encryptFunction(data, key)
    local encrypted = {}
    for i = 1, #data do
        local char = string.byte(data, i)
        local keyChar = string.byte(key, (i - 1) % #key + 1)
        table.insert(encrypted, string.char(bit.bxor(char, keyChar)))
    end
	return stringToHex(table.concat(encrypted)) -- Konversi hasil enkripsi ke hex
end

-- Fungsi untuk dekripsi (menggunakan kunci yang sama)
function ebfImbaDecrypt(hexData)
    local key = GetAuthKey()
	local encryptedString = hexToString(hexData) -- Konversi dari hex ke string
	local decrypted = {}
	for i = 1, #encryptedString do
		local char = string.byte(encryptedString, i)
		local keyChar = string.byte(key, (i - 1) % #key + 1)
		table.insert(decrypted, string.char(bit.bxor(char, keyChar)))
	end
	return table.concat(decrypted) -- Mengembalikan string asli setelah dekripsi
end