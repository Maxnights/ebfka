--[[
    Bug Reporter Library
    Sends error reports to Laravel API instead of using Say()
    
    Usage:
        BugReporter:SendReport(err, "ThinkDefeat")
]]

if BugReporter == nil then
    BugReporter = class({})
end

require("libraries/json")

-- Configuration
BugReporter.apiEndpoint = "https://ebfimba.stelincore.com/api/bug-reports"
-- BugReporter.apiEndpoint = "http://127.0.0.1:8000/api/bug-reports" -- Local testing endpoint
BugReporter.apiKey = GetAuthKey() or "test-key" -- Replace with your actual API key or use GetAuthKey() if defined  
BugReporter.enabled = true
BugReporter.debug = true

-- Initialize (called automatically)
function BugReporter:Init()
    -- Already initialized with class variables
end

--[[
    Send error report to Laravel API
    
    @param err string - The error message
    @param functionName string - Name of the function where error occurred (ThinkDefeat, ThinkNeutrals, ThinkLives, ThinkGeneric)
    @param additionalData table|nil - Optional additional data to include
]]
function BugReporter:SendReport(err, functionName, additionalData)
    -- if not self.enabled then 
    --     print("[BugReporter] Disabled, skipping report")
    --     return 
    -- end
    
    -- -- Skip if not dedicated server (development/local testing)
    -- if not IsDedicatedServer() then
    --     if self.debug then
    --         print("[BugReporter] Not a dedicated server, skipping report")
    --     end
    --     return 
    -- end
    
    -- -- Skip if in tools mode (development)
    -- if IsInToolsMode() then
    --     if self.debug then
    --         print("[BugReporter] Tools mode detected, skipping report")
    --     end
    --     return
    -- end
    
    -- -- Skip if cheat mode is enabled
    -- if GameRules and GameRules:IsCheatMode() then
    --     if self.debug then
    --         print("[BugReporter] Cheat mode enabled, skipping report")
    --     end
    --     return
    -- end
    
    -- -- Build the report
    -- local report = self:BuildReport(err, functionName, additionalData)
    
    -- if self.debug then
    --     print("[BugReporter] Sending report:")
    --     DeepPrintTable(report)
    -- end
    
    -- Send the request
    local report = self:BuildReport(err, functionName, additionalData)
    local request = CreateHTTPRequestScriptVM("POST", self.apiEndpoint)
    -- request:SetHTTPRequestHeaderValue("Authorization", "Bearer " .. self.apiToken)
    request:SetHTTPRequestHeaderValue("Content-Type", "application/json")
    request:SetHTTPRequestHeaderValue("X-Game-Version", PATCH_NAME or "unknown")
    request:SetHTTPRequestHeaderValue("X-EBFIMBA-KEY", self.apiKey)
    request:SetHTTPRequestHeaderValue("User-Agent", "Dota2CustomGame/EBF")

    local encodedBody = json.encode(report)
    print("[BugReporter] Sending to: " .. self.apiEndpoint)
    print("[BugReporter] Body: " .. tostring(encodedBody))

    request:SetHTTPRequestRawPostBody("application/json", encodedBody)

    request:Send(function(result)
        print("[BugReporter] HTTP Status: " .. tostring(result.StatusCode))
        print("[BugReporter] Response: " .. tostring(result.Body))
        if result.StatusCode == 200 or result.StatusCode == 201 then
            print("[BugReporter] Error report sent successfully")
        else
            print("[BugReporter] Failed to send report: HTTP " .. tostring(result.StatusCode))
        end
    end)
end

--[[
    Build the report object
]]
function BugReporter:BuildReport(err, functionName, additionalData)
    local report = {
        error_message = tostring(err),
        stack_trace = self:GetStackTrace(),
        context = {
            function_name = functionName or "unknown",
            game_state = self:GetGameStateString()
        },
        game_info = {
            patch_name = (PATCH_NAME and PATCH_NAME ~= "") and PATCH_NAME or "unknown",
            patch_date = (PATCH_DATE and PATCH_DATE ~= "" and PATCH_DATE ~= "unknown") and PATCH_DATE or nil,
            map_name = GetMapName(),
            round_number = GameRules and GameRules._roundnumber or 0,
            game_time = GameRules and GameRules:GetDOTATime(false, false) or 0,
            is_new_game_plus = GameRules and GameRules._NewGamePlus or false,
            is_dedicated_server = IsDedicatedServer(),
            is_tools_mode = IsInToolsMode(),
            is_cheat_mode = GameRules and GameRules:IsCheatMode() or false
        },
        players = self:GetPlayersData(),
        metadata = self:GetMetadata()
    }
    
    -- Merge additional data if provided
    if additionalData then
        for k, v in pairs(additionalData) do
            report[k] = v
        end
    end
    
    return report
end

--[[
    Get current timestamp in ISO 8601 format
    Note: Dota 2 Lua doesn't have os.date(), so we use GameRules time
    This returns game time based timestamp (not real world time)
]]
function BugReporter:GetISOTimestamp()
    -- Dota 2 doesn't have os.date(), use game time instead
    local gameTime = GameRules and GameRules:GetDOTATime(false, false) or 0
    local hours = math.floor(gameTime / 3600)
    local minutes = math.floor((gameTime % 3600) / 60)
    local seconds = math.floor(gameTime % 60)
    
    -- Return in format that shows this is game-relative time
    -- Format: "GAME-TIME: HH:MM:SS" since we don't have real time
    return string.format("GAME-TIME: %02d:%02d:%02d", hours, minutes, seconds)
end

--[[
    Get stack trace
]]
function BugReporter:GetStackTrace()
    local trace = debug.traceback()
    -- Limit stack trace length to avoid huge payloads
    if #trace > 5000 then
        trace = string.sub(trace, 1, 5000) .. "\n... (truncated)"
    end
    return trace
end

--[[
    Get game state as string
]]
function BugReporter:GetGameStateString()
    if not GameRules then
        return "UNKNOWN"
    end
    
    local state = GameRules:State_Get()
    local states = {
        [DOTA_GAMERULES_STATE_INIT] = "INIT",
        [DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD] = "WAIT_FOR_PLAYERS_TO_LOAD",
        [DOTA_GAMERULES_STATE_HERO_SELECTION] = "HERO_SELECTION",
        [DOTA_GAMERULES_STATE_STRATEGY_TIME] = "STRATEGY_TIME",
        [DOTA_GAMERULES_STATE_PRE_GAME] = "PRE_GAME",
        [DOTA_GAMERULES_STATE_GAME_IN_PROGRESS] = "GAME_IN_PROGRESS",
        [DOTA_GAMERULES_STATE_POST_GAME] = "POST_GAME",
        [DOTA_GAMERULES_STATE_DISCONNECT] = "DISCONNECT",
    }
    
    return states[state] or "UNKNOWN"
end

--[[
    Get players data
]]
function BugReporter:GetPlayersData()
    local players = {}
    
    if not PlayerResource then
        return players
    end
    
    for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if PlayerResource:IsValidPlayerID(i) then
            local playerData = {
                player_id = i,
                steam_id = tostring(PlayerResource:GetSteamID(i)),
                steam_account_id = PlayerResource:GetSteamAccountID(i),
                team = PlayerResource:GetTeam(i),
                connection_state = PlayerResource:GetConnectionState(i)
            }
            
            -- Try to get hero name
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero then
                playerData.hero_name = hero:GetUnitName()
                playerData.hero_damage = hero.damage_dealt_ingame or 0
                playerData.hero_level = hero:GetLevel() or 1
            else
                playerData.hero_name = PlayerResource:GetSelectedHeroName(i) or "unknown"
            end
            
            table.insert(players, playerData)
        end
    end
    
    return players
end

--[[
    Get metadata about the game
]]
function BugReporter:GetMetadata()
    local metadata = {
        difficulty = self:GetDifficulty(),
        lives_remaining = Life and Life._life or 0,
        max_lives = Life and Life._MaxLife or 0,
        total_players = self:CountActivePlayers(),
        server_time = GameRules and GameRules:GetDOTATime(false, false) or 0
    }
    
    -- Add round information
    if GameRules then
        metadata.current_round = GameRules._roundnumber or 0
        metadata.total_rounds = GameRules._vRounds and #GameRules._vRounds or 0
    end
    
    -- Add total damage dealt by all players
    local totalDamage = 0
    local totalHealing = 0
    if PlayerResource then
        for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
            if PlayerResource:IsValidPlayerID(i) then
                local hero = PlayerResource:GetSelectedHeroEntity(i)
                if hero then
                    totalDamage = totalDamage + (hero.damage_dealt_ingame or 0)
                    totalHealing = totalHealing + (hero.damage_healed_ingame or 0)
                end
            end
        end
    end
    metadata.total_damage_dealt = totalDamage
    metadata.total_healing = totalHealing
    
    return metadata
end

--[[
    Get difficulty from custom net tables
]]
function BugReporter:GetDifficulty()
    local eventConfig = CustomNetTables:GetTableValue('choosen_difficulty', 'saved')
    if eventConfig and eventConfig.class then
        return eventConfig.class
    end
    return "unknown"
end

--[[
    Count active players
]]
function BugReporter:CountActivePlayers()
    local count = 0
    if not PlayerResource then
        return count
    end
    
    for i = 0, PlayerResource:GetPlayerCount() - 1 do
        if PlayerResource:IsValidPlayerID(i) and 
           PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
            count = count + 1
        end
    end
    return count
end

-- Legacy function for backwards compatibility
function SendBugReport(err, functionName)
    BugReporter:SendReport(err, functionName)
end

--[[
    Test function to send a test bug report
    This bypasses all checks (dedicated server, tools mode, cheat mode)
    Use this for testing the API connection
    
    Usage:
        BugReporter:TestReport()
        Or from console: script_execute BugReporter:TestReport()
]]
function BugReporter:TestReport()
    print("[BugReporter] Sending TEST report...")
    
    local testReport = {
        timestamp = self:GetISOTimestamp(),
        error_message = "[TEST] This is a test error report from BugReporter",
        stack_trace = debug.traceback(),
        context = {
            function_name = "TestReport",
            game_state = self:GetGameStateString()
        },
        game_info = {
            patch_name = PATCH_NAME or "test-unknown",
            patch_date = (PATCH_DATE and PATCH_DATE ~= "" and PATCH_DATE ~= "unknown") and PATCH_DATE or nil,
            map_name = GetMapName(),
            round_number = GameRules and GameRules._roundnumber or 0,
            game_time = GameRules and GameRules:GetDOTATime(false, false) or 0,
            is_new_game_plus = GameRules and GameRules._NewGamePlus or false,
            is_dedicated_server = IsDedicatedServer(),
            is_tools_mode = IsInToolsMode(),
            is_cheat_mode = GameRules and GameRules:IsCheatMode() or false
        },
        players = self:GetPlayersData(),
        metadata = self:GetMetadata()
    }
    
    print("[BugReporter] Test report data:")
    DeepPrintTable(testReport)
    
    local request = CreateHTTPRequestScriptVM("POST", self.apiEndpoint)
    request:SetHTTPRequestHeaderValue("Content-Type", "application/json")
    request:SetHTTPRequestHeaderValue("X-Game-Version", PATCH_NAME or "unknown")
    request:SetHTTPRequestHeaderValue("X-EBFIMBA-KEY", self.apiKey)
    request:SetHTTPRequestHeaderValue("User-Agent", "Dota2CustomGame/EBF-TEST")
    request:SetHTTPRequestHeaderValue("X-Test-Mode", "true")
    
    local encodedBody = json.encode(testReport)
    print("[BugReporter] Encoded JSON: " .. encodedBody)
    
    request:SetHTTPRequestRawPostBody("application/json", encodedBody)
    
    request:Send(function(result)
        print("[BugReporter] === TEST REPORT RESPONSE ===")
        print("[BugReporter] Status Code: " .. tostring(result.StatusCode))
        print("[BugReporter] Response Body: " .. tostring(result.Body))
        
        if result.StatusCode == 200 or result.StatusCode == 201 then
            print("[BugReporter] ✓ TEST SUCCESS! Report sent to " .. self.apiEndpoint)
        else
            print("[BugReporter] ✗ TEST FAILED! Check your Laravel server")
            print("[BugReporter] Make sure:")
            print("  1. Laravel server is running on " .. self.apiEndpoint)
            print("  2. API endpoint /api/bug-reports exists")
            print("  3. CORS is configured properly")
        end
    end)
end

print("[BugReporter] Library loaded successfully")
