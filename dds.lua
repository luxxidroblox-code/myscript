            -- ============================================
            -- STEALTH FARM - Universal Vehicle Edition
            -- Creator: _nznt
            -- Features: Premium UI, Anti-AFK, Any Vehicle, Webhook
            -- ============================================

            -- Adonis bypass
        local d = false
        local h = {}
        local x, y
        setthreadidentity(2)
        for i, v in getgc(true) do
            if typeof(v) == "table" then
                local a = rawget(v, "Detected")
                local b = rawget(v, "Kill")
                if typeof(a) == "function" and not x then
                    x = a
                    local o; o = hookfunction(x, function(c, f, n)
                        if c ~= "_" then
                            if d then warn(`Adonis flagged\nMethod: {c}\nInfo: {f}`) end
                        end
                        return true
                    end)
                    table.insert(h, x)
                end
                if rawget(v, "Variables") and rawget(v, "Process") and typeof(b) == "function" and not y then
                    y = b
                    local o; o = hookfunction(y, function(f)
                        if d then warn(`Adonis tried to kill: {f}`) end
                    end)
                    table.insert(h, y)
                end
            end
        end
        local o; o = hookfunction(getrenv().debug.info, newcclosure(function(...)
            local a, f = ...
            if x and a == x then return coroutine.yield(coroutine.running()) end
            return o(...)
        end))
        setthreadidentity(7)

        local function nzntStartupRoots()
            local roots = {}
            local player = game:GetService("Players").LocalPlayer
            local playerGui = player and player:FindFirstChild("PlayerGui")
            if playerGui then
                table.insert(roots, playerGui)
            end

            local ok, coreGui = pcall(function()
                return game:GetService("CoreGui")
            end)
            if ok and coreGui then
                table.insert(roots, coreGui)
            end

            return roots
        end

        local function nzntVisibleGuiObject(obj)
            if not obj:IsA("GuiObject") or obj.AbsoluteSize.X <= 0 or obj.AbsoluteSize.Y <= 0 then
                return false
            end

            local current = obj
            while current do
                if current:IsA("GuiObject") and not current.Visible then
                    return false
                end
                if current:IsA("ScreenGui") and not current.Enabled then
                    return false
                end
                current = current.Parent
            end

            return true
        end

        local function nzntGuiText(obj)
            if obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
                return tostring(obj.Text or "")
            end
            return ""
        end

        local function nzntNamePath(obj)
            local names = {}
            local current = obj
            local depth = 0
            while current and depth < 8 do
                table.insert(names, tostring(current.Name or ""))
                current = current.Parent
                depth = depth + 1
            end
            return table.concat(names, " "):lower()
        end

        local function nzntClickableStartupTarget(obj)
            local current = obj
            while current do
                if current:IsA("GuiButton") then
                    return current
                end
                current = current.Parent
            end

            current = obj
            while current do
                local name = tostring(current.Name or ""):lower()
                if current:IsA("GuiObject")
                    and (name:find("deployselect", 1, true)
                        or name:find("applyselect", 1, true)
                        or name:find("playframe", 1, true))
                then
                    return current
                end
                current = current.Parent
            end

            return obj:IsA("GuiObject") and obj or nil
        end

        local function nzntFindNamedPlayTarget()
            for _, root in ipairs(nzntStartupRoots()) do
                local mainMenu = root:FindFirstChild("mainMenuSystem")
                local baseFrame = mainMenu and mainMenu:FindFirstChild("baseFrame")
                local homeFrame = baseFrame and baseFrame:FindFirstChild("homeFrame")
                local playFrame = homeFrame and homeFrame:FindFirstChild("playFrame")
                local applySelect = playFrame and playFrame:FindFirstChild("applySelect")
                if applySelect and applySelect:IsA("GuiObject") and nzntVisibleGuiObject(applySelect) then
                    return applySelect
                end

                local directPlayFrame = baseFrame and baseFrame:FindFirstChild("playFrame")
                local deploySelect = directPlayFrame and directPlayFrame:FindFirstChild("deploySelect")
                if deploySelect and deploySelect:IsA("GuiObject") and nzntVisibleGuiObject(deploySelect) then
                    return deploySelect
                end

                local ok, descendants = pcall(function()
                    return root:GetDescendants()
                end)
                if ok then
                    for _, obj in ipairs(descendants) do
                        if obj:IsA("GuiObject") and nzntVisibleGuiObject(obj) then
                            local name = tostring(obj.Name or ""):lower()
                            if name == "applyselect" or name == "deployselect" then
                                local path = nzntNamePath(obj)
                                if path:find("mainmenusystem", 1, true) and path:find("playframe", 1, true) then
                                    return obj
                                end
                            end
                        end
                    end
                end
            end
        end

        local function nzntFindDeploySelectTarget()
            for _, root in ipairs(nzntStartupRoots()) do
                local mainMenu = root:FindFirstChild("mainMenuSystem")
                local baseFrame = mainMenu and mainMenu:FindFirstChild("baseFrame")
                local playFrame = baseFrame and baseFrame:FindFirstChild("playFrame")
                local deploySelect = playFrame and playFrame:FindFirstChild("deploySelect")
                if deploySelect and deploySelect:IsA("GuiObject") and nzntVisibleGuiObject(deploySelect) then
                    return deploySelect
                end

                local ok, descendants = pcall(function()
                    return root:GetDescendants()
                end)
                if ok then
                    for _, obj in ipairs(descendants) do
                        if obj:IsA("GuiObject") and nzntVisibleGuiObject(obj) then
                            local name = tostring(obj.Name or ""):lower()
                            if name == "deployselect" then
                                local path = nzntNamePath(obj)
                                if path:find("mainmenusystem", 1, true) and path:find("playframe", 1, true) then
                                    return obj
                                end
                            end
                        end
                    end
                end
            end
        end

        local function nzntFindPlayButton()
            local namedTarget = nzntFindNamedPlayTarget()
            if namedTarget then
                return namedTarget
            end

            local bestButton, bestScore = nil, -math.huge
            for _, root in ipairs(nzntStartupRoots()) do
                local ok, descendants = pcall(function()
                    return root:GetDescendants()
                end)
                if ok then
                    for _, obj in ipairs(descendants) do
                        if (obj:IsA("TextButton") or obj:IsA("ImageButton") or obj:IsA("TextLabel")) and nzntVisibleGuiObject(obj) then
                            local text = nzntGuiText(obj):upper():gsub("%s+", "")
                            local path = nzntNamePath(obj)
                            local color = obj.BackgroundColor3
                            local isGreen = obj.BackgroundTransparency < 0.8
                                and color.G > 0.45
                                and color.G > color.R * 1.25
                                and color.G > color.B * 1.25
                            local score = 0

                            if text == "PLAY" then
                                score = score + 100
                            elseif text:find("PLAY", 1, true) then
                                score = score + 55
                            end
                            if path:find("play", 1, true) then
                                score = score + 25
                            end
                            if path:find("deployselect", 1, true) or path:find("applyselect", 1, true) then
                                score = score + 45
                            end
                            if path:find("mainmenusystem", 1, true) then
                                score = score + 15
                            end
                            if isGreen then
                                score = score + 25
                            end

                            if score >= 60 and score > bestScore then
                                local target = nzntClickableStartupTarget(obj)
                                if target and nzntVisibleGuiObject(target) then
                                    bestButton = target
                                    bestScore = score
                                end
                            end
                        end
                    end
                end
            end
            return bestButton
        end

        local function nzntStartupScreenPresent()
            for _, root in ipairs(nzntStartupRoots()) do
                local ok, descendants = pcall(function()
                    return root:GetDescendants()
                end)
                if ok then
                    for _, obj in ipairs(descendants) do
                        if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) and nzntVisibleGuiObject(obj) then
                            local text = nzntGuiText(obj):upper()
                            if text:find("LOADING GAME", 1, true) or text:find("TIP:", 1, true) then
                                return true
                            end
                        end
                    end
                end
            end

            return false
        end

        local function nzntStartupExecutorIsDelta()
            local ok, name = pcall(function()
                if identifyexecutor then
                    return identifyexecutor()
                end
                if getexecutorname then
                    return getexecutorname()
                end
                return ""
            end)

            return ok and tostring(name or ""):lower():find("delta", 1, true) ~= nil
        end

        local function nzntClickButton(button)
            if not button or not button.Parent then
                return false
            end

            local clicked = false
            local isDelta = nzntStartupExecutorIsDelta()
            local function mark(ok)
                clicked = ok or clicked
            end

            if button:IsA("GuiButton") then
                mark(pcall(function()
                    button:Activate()
                end))

                local signals = {
                    button.MouseButton1Click,
                    button.Activated
                }

                for _, signal in ipairs(signals) do
                    if firesignal then
                        mark(pcall(function()
                            firesignal(signal)
                        end))
                    end

                    if not isDelta and getconnections then
                        local ok, signalConnections = pcall(function()
                            return getconnections(signal)
                        end)

                        if ok and type(signalConnections) == "table" then
                            for _, connection in ipairs(signalConnections) do
                                local didCall = false
                                local okConnection = pcall(function()
                                    if connection.Fire then
                                        didCall = true
                                        connection:Fire()
                                    elseif connection.Function then
                                        didCall = true
                                        connection.Function()
                                    end
                                end)
                                clicked = (okConnection and didCall) or clicked
                            end
                        end
                    end
                end

                if isDelta and nzntVisibleGuiObject(button) then
                    mark(pcall(function()
                        local guiService = game:GetService("GuiService")
                        local vim = game:GetService("VirtualInputManager")
                        button.Selectable = true
                        guiService.SelectedObject = button

                        vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.04)
                        vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                        vim:SendKeyEvent(true, Enum.KeyCode.KeypadEnter, false, game)
                        task.wait(0.04)
                        vim:SendKeyEvent(false, Enum.KeyCode.KeypadEnter, false, game)

                        if guiService.SelectedObject == button then
                            guiService.SelectedObject = nil
                        end
                    end))
                end
            end

            if not isDelta then
                pcall(function()
                    local vim = game:GetService("VirtualInputManager")
                    local center = button.AbsolutePosition + (button.AbsoluteSize / 2)
                    vim:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
                    task.wait(0.03)
                    vim:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
                    clicked = true
                end)
            end

            return clicked
        end

        local function nzntPassStartupMenu()
            if not game:IsLoaded() then game.Loaded:Wait() end
            local player = game:GetService("Players").LocalPlayer
            if player then
                player:WaitForChild("PlayerGui")
            end

            local playButton = nzntFindPlayButton()
            if not playButton and not nzntStartupScreenPresent() then
                return
            end

            while nzntStartupScreenPresent() do
                task.wait(0.25)
            end

            playButton = nzntFindPlayButton()
            while not playButton do
                task.wait(0.25)
                playButton = nzntFindPlayButton()
            end

            nzntClickButton(playButton)

            task.wait(3)
            local deployButton = nzntFindDeploySelectTarget()
            local deployDeadline = os.clock() + 15
            while not deployButton and os.clock() < deployDeadline do
                task.wait(0.25)
                deployButton = nzntFindDeploySelectTarget()
            end
            if deployButton then
                nzntClickButton(deployButton)
            end
        end

        pcall(nzntPassStartupMenu)
        task.wait(2)

            local Players          = game:GetService("Players")
            local RunService       = game:GetService("RunService")
            local UserInputService = game:GetService("UserInputService")
            local Lighting         = game:GetService("Lighting")
            local RS               = game:GetService("ReplicatedStorage")
            local VIM              = game:GetService("VirtualInputManager")
            local Player           = Players.LocalPlayer
            local TeleportService  = game:GetService("TeleportService")
            local GuiService       = game:GetService("GuiService")

            local SPEED             = 180
            local MIN_SPEED         = 0
            local MAX_SPEED         = 200
            local CHECK_DISTANCE    = 15
            local HUGE_PLATFORM_SIZE= 2000
            local FARM_THRESHOLD    = 500000
            local DEFAULT_THRESHOLD = 500000
            local MIN_THRESHOLD     = 500000
            local MAX_THRESHOLD     = 2000000
            local NOT_SEATED_TIMEOUT = 10

            local active          = false
            local farmingActive   = false
            local currentVehicle  = nil
            local spawnedSeatSnapshot = {}
            local force           = nil
            local gyro            = nil
            local attachment      = nil
            local direction       = 1
            local savedFloor      = nil
            local startTime       = nil  -- Set when farming starts
            local startMoney      = nil
            local sessionStartTime = nil  -- Set when farming starts
            local sessionStartMoney = nil
            local lastDirChange   = 0
            local DIR_COOLDOWN    = 0.3
            local isRespawning    = false
            local farmTransitionActive = false
            local unseatedSince   = nil
            local vehicleInput    = "Yamahax-MioSporty"
            local webhookUrl      = ""
            local webhookInterval = 60
            local lastVoidTime    = 0
            local voidThreshold   = 2
            local seatOffset      = 1.5  -- Dynamic seat-to-wheel offset
            local rejoinInterval  = 0    -- 0 = disabled, minutes until auto-rejoin
            local sessionStart    = os.time()  -- Track session time for rejoin
            local autoRejoinEnabled = false  -- Toggle for auto-rejoin feature
            local autoPSJoinEnabled = false  -- Toggle for auto private server join
            local SURAKARTA_ID    = 131378148336503  -- Surakarta map ID
            local SURAKARTA_ARG   = "131378148336503"  -- Arg for CreatePrivateServer
            local vStatus = nil
            local dragBridgeEnabled = false
            local dragBridgeRunning = false
            local dragBridgePassActive = false
            local dragBridgeRaceCount = 0
            local DRAG_BRIDGE_LIMIT = 100
            local DRAG_BRIDGE_CHECKPOINT_DELAY = 3
            local DRAG_BRIDGE_START_HOLD = 3
            local DRAG_BRIDGE_LOOP_DELAY = 8
            local blackGui = nil

            local function safeNumber(value, fallback, minValue, maxValue)
                local number = tonumber(value)
                if not number or number ~= number or number == math.huge or number == -math.huge then
                    number = fallback
                end
                if minValue and number < minValue then number = minValue end
                if maxValue and number > maxValue then number = maxValue end
                return number
            end

            local totalEarned = 0
            local totalTime   = 0
            if isfile and readfile and isfile("nznt_stealth_stats.txt") then
                local content = readfile("nznt_stealth_stats.txt")
                local commaPos = content:find(",")
                if commaPos then
                    totalEarned = tonumber(content:sub(1, commaPos-1)) or 0
                    totalTime   = tonumber(content:sub(commaPos+1)) or 0
                end
            end

            local CFG_FILE = "nznt_stealth_config.txt"
            local CFG_MIGRATION_FILE = "nznt_stealth_config_speed180_v2.txt"

            local function saveConfig()
                if not writefile then return end
                SPEED = safeNumber(SPEED, 180, MIN_SPEED, MAX_SPEED)
                FARM_THRESHOLD = safeNumber(FARM_THRESHOLD, DEFAULT_THRESHOLD, MIN_THRESHOLD, MAX_THRESHOLD)
                webhookInterval = safeNumber(webhookInterval, 60, 30, 300)
                rejoinInterval = safeNumber(rejoinInterval, 0, 0, 120)
                writefile(CFG_FILE, '{"speed":'..SPEED
                    ..',"farmThreshold":'..FARM_THRESHOLD..',"webhookUrl":"'..webhookUrl:gsub('"','\\"')
                    ..'","webhookInterval":'..webhookInterval..',"vehicleInput":"'..vehicleInput:gsub('"','\\"')
                    ..'","rejoinInterval":'..rejoinInterval..',"autoRejoinEnabled":'..(autoRejoinEnabled and "true" or "false")
                    ..',"autoPSJoinEnabled":'..(autoPSJoinEnabled and "true" or "false")
                    ..',"dragBridgeEnabled":'..(dragBridgeEnabled and "true" or "false")..'}')
            end

            local function loadConfig()
                if not isfile or not readfile or not isfile(CFG_FILE) then return end
                local s = readfile(CFG_FILE)
                if not s or s == "" then return end
                local function g(k, d)
                    local v = s:match('"'..k..'":"([^"]*)"') or s:match('"'..k..'":([%d%.]+)')
                    return v and (tonumber(v) or v) or d
                end
                SPEED = g("speed", SPEED)
                FARM_THRESHOLD = g("farmThreshold", FARM_THRESHOLD); webhookUrl = g("webhookUrl", webhookUrl)
                webhookInterval = g("webhookInterval", webhookInterval); vehicleInput = g("vehicleInput", vehicleInput)
                rejoinInterval = g("rejoinInterval", rejoinInterval)
                autoRejoinEnabled = s:find('"autoRejoinEnabled":true') ~= nil
                autoPSJoinEnabled = s:find('"autoPSJoinEnabled":true') ~= nil
                dragBridgeEnabled = s:find('"dragBridgeEnabled":true') ~= nil
                SPEED = safeNumber(SPEED, 180, MIN_SPEED, MAX_SPEED)
                FARM_THRESHOLD = safeNumber(FARM_THRESHOLD, DEFAULT_THRESHOLD, MIN_THRESHOLD, MAX_THRESHOLD)
            end

            local function runOneTimeConfigMigration()
                if not writefile then return end
                if isfile and isfile(CFG_MIGRATION_FILE) then return end

                SPEED = 180
                FARM_THRESHOLD = 500000
                saveConfig()
                writefile(CFG_MIGRATION_FILE, "done")
            end

            loadConfig()
            runOneTimeConfigMigration()
            
            -- Load shared webhook config from loader
            local WEBHOOK_FILE = "nznt_webhook_config.json"
            local function loadSharedWebhookConfig()
                if not isfile or not readfile or not isfile(WEBHOOK_FILE) then return end
                local ok, content = pcall(function() return readfile(WEBHOOK_FILE) end)
                if ok and content then
                    local ok2, data = pcall(function() return game:GetService("HttpService"):JSONDecode(content) end)
                    if ok2 and data then
                        -- Only override if shared config has values
                        if data.url and data.url ~= "" then
                            webhookUrl = data.url
                            webhookInterval = data.interval or 60
                            warn("[Auto Drive Farm] Webhook loaded from loader: " .. (data.enabled and "enabled" or "disabled"))
                        end
                    end
                end
            end
            loadSharedWebhookConfig()
            
            -- Debug: show loaded values
            warn("=== CONFIG LOADED ===")
            warn("autoRejoinEnabled:", autoRejoinEnabled)
            warn("autoPSJoinEnabled:", autoPSJoinEnabled)
            warn("=====================")

            -- Auto-rejoin system (after config loaded)
            local SCRIPT_URL = "https://scripts.nznt.store/raw.php?file=autofarm_yellow.lua"
            local scriptSource = ""
            pcall(function() scriptSource = game:HttpGet(SCRIPT_URL, true) end)


            local function queueSelfOnTeleport()
                local source = scriptSource
                if source == "" and readfile and isfile and isfile("autofarm_yellow.lua") then
                    local ok, localSource = pcall(readfile, "autofarm_yellow.lua")
                    if ok and localSource and localSource ~= "" then
                        source = localSource
                    end
                end
                if source == "" then return false end

                local queueFunc = queue_on_teleport
                    or queueonteleport
                    or (syn and syn.queue_on_teleport)
                    or (fluxus and fluxus.queue_on_teleport)
                if not queueFunc then return false end

                -- Queue the source untouched so the bypass remains the first executable code.
                local ok = pcall(queueFunc, source)
                return ok
            end
            
            -- Queue script for re-execution on teleport (only if auto-rejoin enabled)
            if autoRejoinEnabled then
                queueSelfOnTeleport(true)
            end
            
            -- Rejoin on error/crash (only if auto-rejoin enabled)
            GuiService.ErrorMessageChanged:Connect(function()
                if not autoRejoinEnabled then return end
                if scriptSource ~= "" then
                    task.wait(3)
                    queueSelfOnTeleport(true)
                end
                task.wait(5)
                TeleportService:Teleport(game.PlaceId, Player)
            end)
            
            -- Auto private server join function
            local currentServerCode = ""
            
            local function grabServerCode()
                local pse = RS:FindFirstChild("PrivateServerEvents")
                if not pse then return "" end
                local getCode = pse:FindFirstChild("GetCurrentCode")
                if not getCode then return "" end
                
                local code = ""
                local conn = getCode.OnClientEvent:Connect(function(c)
                    code = tostring(c)
                end)
                getCode:FireServer()
                
                local waited = 0
                while code == "" and waited < 5 do
                    task.wait(1)
                    waited = waited + 1
                end
                pcall(function() conn:Disconnect() end)
                return code
            end
            
            local function tryAutoPSJoin()
                if not autoPSJoinEnabled then return end
                
                local currentID = game.PlaceId ~= 0 and game.PlaceId or game.GameId
                
                -- Wrong map - teleport to Surakarta
                if currentID ~= SURAKARTA_ID then
                    warn("Wrong map, teleporting to Surakarta...")
                    local createRemote = RS:FindFirstChild("CreatePrivateServer", true)
                    if createRemote then
                        for i = 1, 3 do
                            createRemote:FireServer(SURAKARTA_ARG)
                            task.wait(5)
                        end
                    end
                    task.wait(2)
                    TeleportService:Teleport(SURAKARTA_ID, Player)
                    return
                end
                
                -- On correct map - check if in private server
                currentServerCode = grabServerCode()
                
                if currentServerCode == "" or currentServerCode == "nil" then
                    -- In public server - create/join private server
                    warn("In public server, creating private server...")
                    local pse = RS:FindFirstChild("PrivateServerEvents")
                    if pse then
                        local createRemote = pse:FindFirstChild("CreatePrivateServer")
                        local joinRemote = pse:FindFirstChild("JoinPrivateServer")
                        
                        -- Try to get existing code first
                        if joinRemote then
                            local existingCode = grabServerCode()
                            if existingCode ~= "" and existingCode ~= "nil" then
                                warn("Joining existing private server:", existingCode)
                                joinRemote:FireServer(existingCode)
                                task.wait(5)
                                return
                            end
                        end
                        
                        -- Create new private server
                        if createRemote then
                            for i = 1, 3 do
                                createRemote:FireServer(SURAKARTA_ARG)
                                task.wait(5)
                            end
                        end
                    end
                else
                    warn("Already in private server:", currentServerCode)
                end
            end
            
            -- Run auto PS join at startup if enabled
            tryAutoPSJoin()

            local function getExecutorName()
                if identifyexecutor then local ok, n = pcall(identifyexecutor) if ok and n then return n end end
                if getexecutorname  then local ok, n = pcall(getexecutorname)  if ok and n then return n end end
                return "Unknown"
            end
            local EXECUTOR_NAME = getExecutorName()

            local lastFPS = 60
            RunService.Heartbeat:Connect(function(dt)
                if dt > 0 then lastFPS = math.floor(1/dt) end
            end)

            local function getMoney()
                local pd = Player:FindFirstChild("PlayerData")
                if pd then local rp = pd:FindFirstChild("RPValue") if rp then return rp.Value end end
                return 0
            end
            local function formatNumber(n)
                local s = tostring(math.floor(n))
                return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
            end
            local function formatTime(t)
                return string.format("%02d:%02d:%02d", math.floor(t/3600)%24, math.floor(t/60)%60, t%60)
            end
            local function getPing()
                local ok, ping = pcall(function() return Player:GetNetworkPing() end)
                return ok and math.floor(ping*1000) or 0
            end
            local function sendKey(key)
                VIM:SendKeyEvent(true, key, false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, key, false, game)
            end
            local function snapshotVehicleSeats()
                local snapshot = {}
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("VehicleSeat") then
                        snapshot[obj] = true
                    end
                end
                return snapshot
            end

            local function spawnedSeatScore(seat, root)
                local distance = (seat.Position - root.Position).Magnitude
                local score = -distance
                local names = {}
                local current = seat

                while current and current ~= workspace do
                    names[#names + 1] = tostring(current.Name or ""):lower()
                    current = current.Parent
                end

                local path = table.concat(names, " ")
                local playerName = Player.Name:lower()
                local vehicleName = tostring(vehicleInput or ""):lower()

                if path:find(playerName, 1, true) then score = score + 100000 end
                if vehicleName ~= "" and path:find(vehicleName, 1, true) then score = score + 20000 end
                if path:find("drive", 1, true) then score = score + 5000 end
                if path:find("passenger", 1, true) or path:find("passanger", 1, true) then
                    score = score - 50000
                end

                return score
            end

            local function findSpawnedSeat(timeout)
                local best, bestScore = nil, -math.huge
                local char = Player.Character
                if not char then return nil end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return nil end

                local started = os.clock()
                repeat
                    best, bestScore = nil, -math.huge
                    for _, seat in ipairs(workspace:GetDescendants()) do
                        if seat:IsA("VehicleSeat") and seat.Parent and not spawnedSeatSnapshot[seat] then
                            local distance = (seat.Position - root.Position).Magnitude
                            if distance <= 600 then
                                local score = spawnedSeatScore(seat, root)
                                if score > bestScore then
                                    best = seat
                                    bestScore = score
                                end
                            end
                        end
                    end

                    if best and (bestScore >= 5000 or os.clock() - started >= 1.5) then
                        return best
                    end
                    task.wait(0.2)
                until os.clock() - started >= (timeout or 12)

                return best
            end
            local function getVehicleRootFromSeat(seat)
                local node = seat
                while node and node.Parent and node.Parent ~= workspace do
                    node = node.Parent
                end
                if node and node ~= seat then
                    return node
                end
                return seat
            end
            local function getPartLowestY(part)
                local cf, half = part.CFrame, part.Size * 0.5
                local lowest = math.huge
                for _, x in ipairs({-1, 1}) do
                    for _, y in ipairs({-1, 1}) do
                        for _, z in ipairs({-1, 1}) do
                            local p = cf * Vector3.new(half.X * x, half.Y * y, half.Z * z)
                            if p.Y < lowest then
                                lowest = p.Y
                            end
                        end
                    end
                end
                return lowest
            end

            local function isWheelPart(part)
                local name = part.Name:lower()
                return name:find("wheel") or name:find("tire") or name:find("tyre") or name:find("rim")
            end

            local function calculateSeatOffset(vehicle, seat)
                local lowestWheelY = math.huge
                local lowestVehicleY = math.huge
                for _, part in ipairs(vehicle:GetDescendants()) do
                    if part:IsA("BasePart") and part ~= seat then
                        local wheelBottom = getPartLowestY(part)
                        if wheelBottom < lowestVehicleY then
                            lowestVehicleY = wheelBottom
                        end
                        if isWheelPart(part) then
                            if wheelBottom < lowestWheelY then
                                lowestWheelY = wheelBottom
                            end
                        end
                    end
                end
                local lowestY = lowestWheelY ~= math.huge and lowestWheelY or lowestVehicleY
                if lowestY ~= math.huge then
                    return math.clamp(seat.Position.Y - lowestY, 1, 12)
                end
                return 1.5  -- Default fallback
            end
            local function setupPhysics(seat)
                attachment = Instance.new("Attachment", seat)
                force = Instance.new("LinearVelocity", seat)
                force.MaxForce = 99999999
                force.Attachment0 = attachment
                force.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
                gyro = Instance.new("BodyGyro", seat)
                gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)  -- Lock all rotation
                gyro.P = 100000  -- Stronger P for faster correction
                gyro.D = 1000    -- Add damping to prevent oscillation
                gyro.CFrame = seat.CFrame
            end
            local function cleanupPhysics()
                if force then force:Destroy() force = nil end
                if gyro then gyro:Destroy() gyro = nil end
                if attachment then attachment:Destroy() attachment = nil end
            end

            local function getVehicleMaxSpeed()
                if not currentVehicle or not currentVehicle.Parent then return 0 end

                local maxSpeed = 0
                for _, part in ipairs(currentVehicle:GetDescendants()) do
                    if part:IsA("BasePart") then
                        maxSpeed = math.max(maxSpeed, part.AssemblyLinearVelocity.Magnitude)
                    end
                end
                if currentVehicle:IsA("BasePart") then
                    maxSpeed = math.max(maxSpeed, currentVehicle.AssemblyLinearVelocity.Magnitude)
                end
                return maxSpeed
            end

            local function stopVehicleCompletely()
                if force then
                    force.VectorVelocity = Vector3.zero
                end

                local stoppedSince = nil
                local started = os.clock()
                while currentVehicle and currentVehicle.Parent and os.clock() - started < 6 do
                    for _, part in ipairs(currentVehicle:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.AssemblyLinearVelocity = Vector3.zero
                            part.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                    if currentVehicle:IsA("BasePart") then
                        currentVehicle.AssemblyLinearVelocity = Vector3.zero
                        currentVehicle.AssemblyAngularVelocity = Vector3.zero
                    end

                    if getVehicleMaxSpeed() <= 0.25 then
                        stoppedSince = stoppedSince or os.clock()
                        if os.clock() - stoppedSince >= 0.35 then
                            break
                        end
                    else
                        stoppedSince = nil
                    end

                    task.wait(0.05)
                end
            end

            local function groundRaycast(origin, distance)
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Blacklist
                params.IgnoreWater = true
                local filter = {}
                if currentVehicle then table.insert(filter, currentVehicle) end
                if Player.Character then table.insert(filter, Player.Character) end
                params.FilterDescendantsInstances = filter
                return workspace:Raycast(origin, Vector3.new(0, -distance, 0), params)
            end

            -- Anti-AFK removed - now handled by UI loader

            local function fireCarEvent(name, ...)
                local sf = RS:FindFirstChild("SpawnCarEvents")
                if sf then local r = sf:FindFirstChild(name) if r then r:FireServer(...) return true end end
                return false
            end
            local function spawnVehicle(id)
                spawnedSeatSnapshot = snapshotVehicleSeats()
                return fireCarEvent("SpawnCar", id or vehicleInput)
            end
            local function despawnVehicle() fireCarEvent("DespawnCar") end

            local function sitOnSpawnedSeat(seat, hum, root)
                if not seat or not seat.Parent or spawnedSeatSnapshot[seat] then
                    return false
                end

                for _ = 1, 5 do
                    if not seat.Parent or spawnedSeatSnapshot[seat] then
                        return false
                    end

                    if hum.SeatPart and hum.SeatPart ~= seat then
                        sendKey(Enum.KeyCode.Space)
                        hum.Sit = false
                        task.wait(0.2)
                    end

                    root.CFrame = seat.CFrame * CFrame.new(0, 2.5, 0)
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    task.wait(0.2)
                    seat:Sit(hum)
                    task.wait(0.45)

                    if hum.SeatPart == seat then
                        return true
                    end
                end

                return false
            end

            local function findDragRace()
                local dragRace = workspace:FindFirstChild("DragRace")
                if dragRace then return dragRace end

                for _, obj in pairs(workspace:GetChildren()) do
                    if obj:IsA("Folder") or obj:IsA("Model") then
                        dragRace = obj:FindFirstChild("DragRace") or obj:FindFirstChild("DragRace", true)
                        if dragRace then return dragRace end
                    end
                end

                for _, name in ipairs({"Race", "Drag", "SpeedRace", "SpeedTrap"}) do
                    dragRace = workspace:FindFirstChild(name)
                    if dragRace then return dragRace end
                end

                return nil
            end

            local function findDragDetectors(dragRace)
                if not dragRace then return nil, nil, nil, nil, nil end

                local detectorRoot = dragRace:FindFirstChild("Detector") or dragRace:FindFirstChild("Detectors") or dragRace
                local startDet = (
                    detectorRoot:FindFirstChild("DetectorStart") or detectorRoot:FindFirstChild("Start")
                    or dragRace:FindFirstChild("DetectorStart") or dragRace:FindFirstChild("Start")
                )
                local c1 = (
                    detectorRoot:FindFirstChild("DetectorC1") or detectorRoot:FindFirstChild("C1")
                    or dragRace:FindFirstChild("DetectorC1") or dragRace:FindFirstChild("C1")
                )
                local c2 = (
                    detectorRoot:FindFirstChild("DetectorC2") or detectorRoot:FindFirstChild("C2")
                    or dragRace:FindFirstChild("DetectorC2") or dragRace:FindFirstChild("C2")
                )
                local c3 = (
                    detectorRoot:FindFirstChild("DetectorC3") or detectorRoot:FindFirstChild("C3")
                    or dragRace:FindFirstChild("DetectorC3") or dragRace:FindFirstChild("C3")
                )
                local finishDet = (
                    detectorRoot:FindFirstChild("DetectorFinish") or detectorRoot:FindFirstChild("Finish")
                    or dragRace:FindFirstChild("DetectorFinish") or dragRace:FindFirstChild("Finish")
                )
                return startDet, c1, c2, c3, finishDet
            end

            local function touchDragDetector(detector, seatCFrame)
                if not detector or not seatCFrame then return false end

                local ok = pcall(function()
                    detector.CFrame = seatCFrame
                end)
                task.wait(0.1)
                pcall(function()
                    detector.CFrame = seatCFrame * CFrame.new(0, -100, 0)
                end)

                return ok
            end

        local function getCurrentSeat()
            if not currentVehicle then return nil end
            if currentVehicle:IsA("VehicleSeat") then return currentVehicle end
            return currentVehicle:FindFirstChildWhichIsA("VehicleSeat", true)
        end

        local function zeroVehicleVelocity()
            if force then
                force.VectorVelocity = Vector3.zero
            end

            if currentVehicle and currentVehicle.Parent then
                for _, part in ipairs(currentVehicle:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                    end
                end

                if currentVehicle:IsA("BasePart") then
                    currentVehicle.AssemblyLinearVelocity = Vector3.zero
                    currentVehicle.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end

        local function holdVehicleStill(duration)
            local started = os.clock()
            repeat
                zeroVehicleVelocity()
                task.wait(0.05)
            until os.clock() - started >= duration or not dragBridgeEnabled or not farmingActive or isRespawning
        end

        local function runDragBridgePass()
            if dragBridgePassActive or not dragBridgeEnabled or not farmingActive or isRespawning then return end

                local seat = getCurrentSeat()
                if not seat then return end

                local dragRace = findDragRace()
                if not dragRace then
                    vStatus.Text = "Drag bridge: DragRace not found"
                    return
                end

                local startDet, c1, c2, c3, finishDet = findDragDetectors(dragRace)
                if not startDet or not finishDet then
                    vStatus.Text = "Drag bridge: detectors not found"
                    return
                end

                dragBridgePassActive = true
                dragBridgeRunning = true
                local oldStatus = vStatus.Text
                local seatCFrame = seat.CFrame

                vStatus.Text = "Drag bridge: halting..."
                holdVehicleStill(0.5)
                seatCFrame = seat.CFrame

                vStatus.Text = "Drag bridge: start"
                touchDragDetector(startDet, seatCFrame)
                vStatus.Text = "Drag bridge: waiting for timer..."
                holdVehicleStill(DRAG_BRIDGE_START_HOLD)

                dragBridgeRunning = false

                for index, checkpoint in ipairs({c1, c2, c3}) do
                    if checkpoint and dragBridgeEnabled and farmingActive and not isRespawning then
                        seatCFrame = seat.CFrame
                        vStatus.Text = "Drag bridge: checkpoint " .. tostring(index)
                        touchDragDetector(checkpoint, seatCFrame)
                        task.wait(DRAG_BRIDGE_CHECKPOINT_DELAY)
                    end
                end

                if dragBridgeEnabled and farmingActive and not isRespawning then
                    seatCFrame = seat.CFrame
                    vStatus.Text = "Drag bridge: finish"
                    touchDragDetector(finishDet, seatCFrame)
                    dragBridgeRaceCount = dragBridgeRaceCount + 1
                    if dragBridgeRaceCount >= DRAG_BRIDGE_LIMIT then
                        vStatus.Text = "Drag bridge: 100 races - rejoining..."
                        if writefile then
                            writefile("nznt_stealth_stats.txt", tostring(totalEarned) .. "," .. tostring(totalTime))
                        end
                        if not queueSelfOnTeleport(true) then
                            vStatus.Text = "Drag bridge: re-exec queue failed"
                            dragBridgeRunning = false
                            dragBridgePassActive = false
                            return
                        end
                        task.wait(1)
                        TeleportService:Teleport(game.PlaceId, Player)
                        return
                    end
                end

                if dragBridgeEnabled and farmingActive and oldStatus ~= "" then
                    vStatus.Text = oldStatus
                end
                dragBridgeRunning = false
                dragBridgePassActive = false
            end

            -- UI
            local Gui = Instance.new("ScreenGui")
            Gui.Name = "nznt_StealthUI_Premium"; Gui.IgnoreGuiInset = true; Gui.DisplayOrder = 999; Gui.ResetOnSpawn = false

            local MainFrame = Instance.new("Frame", Gui)
            MainFrame.Size = UDim2.new(1,0,1,0); MainFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
            MainFrame.ZIndex = 1; MainFrame.BorderSizePixel = 0; MainFrame.Active = false

            local TopBar = Instance.new("Frame", MainFrame)
            TopBar.Size = UDim2.new(1,0,0,44); TopBar.BackgroundColor3 = Color3.fromRGB(18,18,18)
            TopBar.BorderSizePixel = 0; TopBar.ZIndex = 2

            local TopTitle = Instance.new("TextLabel", TopBar)
            TopTitle.Size = UDim2.new(1,-120,1,0); TopTitle.Position = UDim2.new(0,14,0,0)
            TopTitle.BackgroundTransparency = 1; TopTitle.Text = "STEALTH FARM  ·  nznt_"
            TopTitle.TextColor3 = Color3.fromRGB(255,215,0); TopTitle.Font = Enum.Font.GothamBold
            TopTitle.TextSize = 13; TopTitle.TextXAlignment = Enum.TextXAlignment.Left; TopTitle.ZIndex = 3

            local hideBtn = Instance.new("TextButton", TopBar)
            hideBtn.Size = UDim2.new(0,70,0,28); hideBtn.Position = UDim2.new(1,-80,0.5,-14)
            hideBtn.BackgroundColor3 = Color3.fromRGB(40,40,40); hideBtn.TextColor3 = Color3.fromRGB(200,200,200)
            hideBtn.Font = Enum.Font.GothamBold; hideBtn.TextSize = 12; hideBtn.Text = "HIDE"
            hideBtn.ZIndex = 3; hideBtn.BorderSizePixel = 0
            Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0,6)

            local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
            ScrollFrame.Size = UDim2.new(1,0,1,-44); ScrollFrame.Position = UDim2.new(0,0,0,44)
            ScrollFrame.BackgroundTransparency = 1; ScrollFrame.BorderSizePixel = 0
            ScrollFrame.ScrollBarThickness = 4; ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
            ScrollFrame.CanvasSize = UDim2.new(0,0,0,0); ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y; ScrollFrame.ZIndex = 2

            hideBtn.MouseButton1Click:Connect(function()
                ScrollFrame.Visible = not ScrollFrame.Visible
                local t = ScrollFrame.Visible and 0 or 1
                MainFrame.BackgroundTransparency = t; TopBar.BackgroundTransparency = t
                TopTitle.TextTransparency = t; hideBtn.Text = ScrollFrame.Visible and "HIDE" or "SHOW"
            end)

            local ll = Instance.new("UIListLayout", ScrollFrame)
            ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0,1)
            Instance.new("UIPadding", ScrollFrame).PaddingBottom = UDim.new(0,10)

            local function makeContainer(h, order)
                local f = Instance.new("Frame", ScrollFrame)
                f.Size = UDim2.new(1,0,0,h); f.BackgroundColor3 = Color3.fromRGB(16,16,16)
                f.BorderSizePixel = 0; f.ZIndex = 3; f.LayoutOrder = order
                return f
            end

            local function makeSection(title, order)
                local sec = makeContainer(28, order)
                sec.BackgroundColor3 = Color3.fromRGB(13,13,13)
                local lbl = Instance.new("TextLabel", sec)
                lbl.Size = UDim2.new(1,-14,1,0); lbl.Position = UDim2.new(0,14,0,0)
                lbl.BackgroundTransparency = 1; lbl.Text = title:upper()
                lbl.TextColor3 = Color3.fromRGB(255,215,0); lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 4
            end

            local function makeRow(icon, label, valueDefault, order)
                local row = makeContainer(38, order)
                local iL = Instance.new("TextLabel", row)
                iL.Size = UDim2.new(0,30,1,0); iL.Position = UDim2.new(0,10,0,0)
                iL.BackgroundTransparency = 1; iL.Text = icon; iL.TextColor3 = Color3.fromRGB(255,215,0)
                iL.Font = Enum.Font.GothamBold; iL.TextSize = 16; iL.ZIndex = 4
                local nL = Instance.new("TextLabel", row)
                nL.Size = UDim2.new(0.45,0,1,0); nL.Position = UDim2.new(0,44,0,0)
                nL.BackgroundTransparency = 1; nL.Text = label; nL.TextColor3 = Color3.fromRGB(130,130,130)
                nL.Font = Enum.Font.Gotham; nL.TextSize = 13; nL.TextXAlignment = Enum.TextXAlignment.Left; nL.ZIndex = 4
                local vL = Instance.new("TextLabel", row)
                vL.Size = UDim2.new(0.5,-14,1,0); vL.Position = UDim2.new(0.5,0,0,0)
                vL.BackgroundTransparency = 1; vL.Text = valueDefault; vL.TextColor3 = Color3.fromRGB(230,230,230)
                vL.Font = Enum.Font.GothamBold; vL.TextSize = 13; vL.TextXAlignment = Enum.TextXAlignment.Right; vL.ZIndex = 4
                local sep = Instance.new("Frame", row)
                sep.Size = UDim2.new(1,-14,0,1); sep.Position = UDim2.new(0,7,1,-1)
                sep.BackgroundColor3 = Color3.fromRGB(28,28,28); sep.BorderSizePixel = 0; sep.ZIndex = 4
                return vL
            end

            local function makeSlider(icon, label, minV, maxV, curV, order, isFloat, onChange)
                local row = makeContainer(70, order)
                local iL = Instance.new("TextLabel", row)
                iL.Size = UDim2.new(0,30,0,28); iL.Position = UDim2.new(0,10,0,5)
                iL.BackgroundTransparency = 1; iL.Text = icon; iL.TextColor3 = Color3.fromRGB(255,215,0)
                iL.Font = Enum.Font.GothamBold; iL.TextSize = 16; iL.ZIndex = 4
                local nL = Instance.new("TextLabel", row)
                nL.Size = UDim2.new(0.4,0,0,28); nL.Position = UDim2.new(0,44,0,5)
                nL.BackgroundTransparency = 1; nL.Text = label; nL.TextColor3 = Color3.fromRGB(130,130,130)
                nL.Font = Enum.Font.Gotham; nL.TextSize = 13; nL.TextXAlignment = Enum.TextXAlignment.Left; nL.ZIndex = 4
                
                local vBox = Instance.new("TextBox", row)
                vBox.Size = UDim2.new(0,50,0,28); vBox.Position = UDim2.new(1,-60,0,5)
                vBox.BackgroundColor3 = Color3.fromRGB(28,28,28); vBox.Text = tostring(curV)
                vBox.TextColor3 = Color3.fromRGB(230,230,230); vBox.Font = Enum.Font.GothamBold; vBox.TextSize = 13
                vBox.TextXAlignment = Enum.TextXAlignment.Center; vBox.ZIndex = 10
                vBox.BorderSizePixel = 0; vBox.ClearTextOnFocus = false; vBox.Active = true
                Instance.new("UICorner",vBox).CornerRadius = UDim.new(0,4)
                
                local track = Instance.new("Frame", row)
                track.Size = UDim2.new(1,-60,0,6); track.Position = UDim2.new(0,44,0,45)
                track.BackgroundColor3 = Color3.fromRGB(40,40,40); track.BorderSizePixel = 0; track.ZIndex = 4
                Instance.new("UICorner",track).CornerRadius = UDim.new(0,3)
                local fill = Instance.new("Frame", track)
                fill.BackgroundColor3 = Color3.fromRGB(255,215,0); fill.BorderSizePixel = 0; fill.ZIndex = 5
                Instance.new("UICorner",fill).CornerRadius = UDim.new(0,3)
                local knob = Instance.new("Frame", track)
                knob.Size = UDim2.new(0,18,0,18); knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
                knob.BorderSizePixel = 0; knob.ZIndex = 6
                Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)
                local sep = Instance.new("Frame", row)
                sep.Size = UDim2.new(1,-14,0,1); sep.Position = UDim2.new(0,7,1,-1)
                sep.BackgroundColor3 = Color3.fromRGB(28,28,28); sep.BorderSizePixel = 0; sep.ZIndex = 4
                
                local function refresh(v)
                    local r = (v-minV)/(maxV-minV)
                    fill.Size = UDim2.new(r,0,1,0); knob.Position = UDim2.new(r,-9,0.5,-9); vBox.Text = tostring(v)
                end
                refresh(curV)
                vBox.FocusLost:Connect(function()
                    local val = isFloat and tonumber(vBox.Text:gsub("[^%d%.%-]","")) or tonumber(vBox.Text:gsub("[^%d%-]",""))
                    if val then val = math.clamp(val,minV,maxV); refresh(val); onChange(val)
                    else vBox.Text = tostring(isFloat and math.floor(curV*10)/10 or curV) end
                end)
                local dragging = false
                knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                        local r = math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                        local v = isFloat and (math.floor((minV+r*(maxV-minV))*10)/10) or math.floor(minV+r*(maxV-minV))
                        refresh(v); onChange(v)
                    end
                end)
            end

            local function getVehicleList()
                local vehicles = {}
                pcall(function()
                    local d = RS:FindFirstChild("DealershipEvents")
                    if not d then return end
                    local init = d:FindFirstChild("InitializeCarData")
                    if not init or not init:IsA("RemoteFunction") then return end
                    local ok, cfg = pcall(function() return init:InvokeServer() end)
                    if ok and type(cfg) == "table" then
                        for _, v in pairs(cfg) do
                            if type(v) == "table" and v.Name then
                                table.insert(vehicles, {id = v.Name, name = v.DisplayName or v.Name})
                            end
                        end
                    end
                end)
                if #vehicles > 0 then table.sort(vehicles, function(a,b) return a.name < b.name end) return vehicles end
                return {{id = "Yamahax-MioSporty", name = "Yamahax - Mio Sporty (2006)"}}
            end

            local function createDropdown(parent, position, size, options, onSelect)
                local dd = Instance.new("Frame", parent)
                dd.Size = size; dd.Position = position; dd.BackgroundColor3 = Color3.fromRGB(28,28,28)
                dd.BorderSizePixel = 0; dd.ZIndex = 10
                Instance.new("UICorner", dd).CornerRadius = UDim.new(0,4)
                
                local display = Instance.new("TextButton", dd)
                display.Size = UDim2.new(1,0,1,0); display.BackgroundTransparency = 1
                display.Text = options[1] and options[1].name or "Select Vehicle"
                display.TextColor3 = Color3.fromRGB(255,255,255); display.Font = Enum.Font.Gotham
                display.TextSize = 12; display.TextXAlignment = Enum.TextXAlignment.Left; display.ZIndex = 11
                
                local arrow = Instance.new("TextLabel", dd)
                arrow.Size = UDim2.new(0,20,1,0); arrow.Position = UDim2.new(1,-20,0,0)
                arrow.BackgroundTransparency = 1; arrow.Text = "▼"; arrow.TextColor3 = Color3.fromRGB(255,215,0)
                arrow.Font = Enum.Font.GothamBold; arrow.TextSize = 10; arrow.ZIndex = 11
                
                local list = Instance.new("ScrollingFrame", parent)
                list.Size = UDim2.new(0,size.X.Offset,0,math.min(200,#options*28))
                list.Position = UDim2.new(0,position.X.Offset,0,position.Y.Offset+size.Y.Offset+2)
                list.BackgroundColor3 = Color3.fromRGB(35,35,35); list.BorderSizePixel = 0
                list.ScrollBarThickness = 4; list.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
                list.CanvasSize = UDim2.new(0,0,0,#options*28); list.Visible = false; list.ZIndex = 20
                Instance.new("UICorner", list).CornerRadius = UDim.new(0,4)
                
                for i, opt in ipairs(options) do
                    local btn = Instance.new("TextButton", list)
                    btn.Size = UDim2.new(1,-8,0,26); btn.Position = UDim2.new(0,4,0,(i-1)*28+2)
                    btn.BackgroundColor3 = Color3.fromRGB(28,28,28); btn.Text = opt.name
                    btn.TextColor3 = Color3.fromRGB(230,230,230); btn.Font = Enum.Font.Gotham
                    btn.TextSize = 11; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.ZIndex = 21
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,3)
                    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(255,215,0); btn.TextColor3 = Color3.fromRGB(0,0,0) end)
                    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(28,28,28); btn.TextColor3 = Color3.fromRGB(230,230,230) end)
                    btn.MouseButton1Click:Connect(function()
                        display.Text = opt.name; list.Visible = false; arrow.Text = "▼"; onSelect(opt.id, opt.name)
                    end)
                end
                
                display.MouseButton1Click:Connect(function() list.Visible = not list.Visible; arrow.Text = list.Visible and "▲" or "▼" end)
                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local p = input.Position
                        local function inside(f) local fp,fs = f.AbsolutePosition,f.AbsoluteSize return p.X>=fp.X and p.X<=fp.X+fs.X and p.Y>=fp.Y and p.Y<=fp.Y+fs.Y end
                        if not inside(list) and not inside(dd) then list.Visible = false; arrow.Text = "▼" end
                    end
                end)
                return dd
            end

            makeSection("Vehicle Control", 0)
            local vehicleRow = makeContainer(50, 1)

            local vLbl = Instance.new("TextLabel", vehicleRow)
            vLbl.Size = UDim2.new(0,70,0,20); vLbl.Position = UDim2.new(0,14,0,15)
            vLbl.BackgroundTransparency = 1; vLbl.Text = "Vehicle:"; vLbl.TextColor3 = Color3.fromRGB(255,215,0)
            vLbl.Font = Enum.Font.Gotham; vLbl.TextSize = 12; vLbl.TextXAlignment = Enum.TextXAlignment.Left; vLbl.ZIndex = 4

            local vehicles = getVehicleList()
            -- Validate vehicleInput: check if it exists in the list
            local validVehicle = false
            for _, v in ipairs(vehicles) do
                if v.id == vehicleInput then validVehicle = true break end
            end
            if not validVehicle and #vehicles > 0 then
                vehicleInput = vehicles[1].id
            end

            local dropdownFrame = createDropdown(
                vehicleRow,
                UDim2.new(0, 80, 0, 11),
                UDim2.new(0, 180, 0, 28),
                vehicles,
                function(id, name)
                    vehicleInput = id
                    saveConfig()
                    print("Selected vehicle: " .. name .. " (" .. id .. ")")
                end
            )

            local toggleBtn = Instance.new("TextButton", vehicleRow)
            toggleBtn.Size = UDim2.new(0,100,0,28); toggleBtn.Position = UDim2.new(1,-115,0,11)
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0,150,0); toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
            toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.TextSize = 12; toggleBtn.Text = "▶ START"
            toggleBtn.BorderSizePixel = 0; toggleBtn.ZIndex = 4
            Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,4)

            makeSection("Money", 10)
            local vCurrent   = makeRow("💰", "Current Money", "Rp. 0", 11)
            local vEarned    = makeRow("📈", "Earned", "Rp. 0", 12)
            local vMoneyHour = makeRow("⚡", "Money / Hour", "Calculating...", 13)

            makeSection("Total Stats", 15)
            local vTotalEarned = makeRow("🏆", "Total Earned", "Rp. " .. formatNumber(totalEarned), 16)
            local vTotalTime   = makeRow("⏰", "Total Time", formatTime(totalTime), 17)

            local resetRow = makeContainer(50, 18)
            local resetBtn = Instance.new("TextButton", resetRow)
            resetBtn.Size = UDim2.new(1,-20,0,32); resetBtn.Position = UDim2.new(0,10,0,9)
            resetBtn.BackgroundColor3 = Color3.fromRGB(200,50,50); resetBtn.TextColor3 = Color3.fromRGB(255,255,255)
            resetBtn.Font = Enum.Font.GothamBold; resetBtn.TextSize = 12; resetBtn.Text = "🔄 Reset Total Stats"
            resetBtn.BorderSizePixel = 0; resetBtn.ZIndex = 4
            Instance.new("UICorner",resetBtn).CornerRadius = UDim.new(0,5)
            resetBtn.MouseButton1Click:Connect(function()
                totalEarned=0 totalTime=0
                if writefile then writefile("nznt_stealth_stats.txt","0,0") end
                vTotalEarned.Text="Rp. 0" vTotalTime.Text="00:00:00"
                resetBtn.Text="✓ Stats Reset!"
                resetBtn.BackgroundColor3 = Color3.fromRGB(0,150,70)
                task.wait(2)
                resetBtn.Text="🔄 Reset Total Stats"
                resetBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
            end)

            makeSection("Stats", 20)
            vStatus  = makeRow("▶", "Status", "Auto starting...", 21)
            local vElapsed = makeRow("⏱", "Elapsed", "00:00:00", 22)

            makeSection("Settings", 25)
            makeSlider("⚡","Speed",MIN_SPEED,MAX_SPEED,SPEED,26,false,function(v) SPEED=v saveConfig() end)
            makeSlider("💰","Farm Threshold",MIN_THRESHOLD,MAX_THRESHOLD,FARM_THRESHOLD,27,false,function(v) FARM_THRESHOLD=v saveConfig() end)
            makeSlider("🔄","Auto Rejoin (min)",0,120,rejoinInterval,28,false,function(v) rejoinInterval=v saveConfig() end)
            
            -- Auto-rejoin toggle
            local rejoinToggleRow = makeContainer(50, 18)
            local rejoinToggleBtn = Instance.new("TextButton", rejoinToggleRow)
            rejoinToggleBtn.Size = UDim2.new(1,-20,0,32); rejoinToggleBtn.Position = UDim2.new(0,10,0,9)
            rejoinToggleBtn.BackgroundColor3 = autoRejoinEnabled and Color3.fromRGB(0,150,70) or Color3.fromRGB(60,60,60)
            rejoinToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
            rejoinToggleBtn.Font = Enum.Font.GothamBold; rejoinToggleBtn.TextSize = 12
            rejoinToggleBtn.Text = autoRejoinEnabled and "✓ Auto Rejoin ON" or "○ Auto Rejoin OFF"
            rejoinToggleBtn.BorderSizePixel = 0; rejoinToggleBtn.ZIndex = 4
            Instance.new("UICorner", rejoinToggleBtn).CornerRadius = UDim.new(0,5)
            rejoinToggleBtn.MouseButton1Click:Connect(function()
                autoRejoinEnabled = not autoRejoinEnabled
                rejoinToggleBtn.Text = autoRejoinEnabled and "✓ Auto Rejoin ON" or "○ Auto Rejoin OFF"
                rejoinToggleBtn.BackgroundColor3 = autoRejoinEnabled and Color3.fromRGB(0,150,70) or Color3.fromRGB(60,60,60)
                saveConfig()
            end)
            
            -- Auto PS join toggle
            local psToggleRow = makeContainer(50, 19)
            local psToggleBtn = Instance.new("TextButton", psToggleRow)
            psToggleBtn.Size = UDim2.new(1,-20,0,32); psToggleBtn.Position = UDim2.new(0,10,0,9)
            psToggleBtn.BackgroundColor3 = autoPSJoinEnabled and Color3.fromRGB(0,150,70) or Color3.fromRGB(60,60,60)
            psToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
            psToggleBtn.Font = Enum.Font.GothamBold; psToggleBtn.TextSize = 12
            psToggleBtn.Text = autoPSJoinEnabled and "✓ Auto PS Join ON" or "○ Auto PS Join OFF"
            psToggleBtn.BorderSizePixel = 0; psToggleBtn.ZIndex = 4
            Instance.new("UICorner", psToggleBtn).CornerRadius = UDim.new(0,5)
            psToggleBtn.MouseButton1Click:Connect(function()
                autoPSJoinEnabled = not autoPSJoinEnabled
                psToggleBtn.Text = autoPSJoinEnabled and "✓ Auto PS Join ON" or "○ Auto PS Join OFF"
                psToggleBtn.BackgroundColor3 = autoPSJoinEnabled and Color3.fromRGB(0,150,70) or Color3.fromRGB(60,60,60)
                saveConfig()
                -- Try to join PS immediately when enabled
                if autoPSJoinEnabled then
                    task.spawn(tryAutoPSJoin)
                end
            end)

            makeSection("Discord Webhook", 35)

            local webhookRow = makeContainer(50, 36)
            local webhookBox = Instance.new("TextBox", webhookRow)
            webhookBox.Size = UDim2.new(1,-20,0,30); webhookBox.Position = UDim2.new(0,10,0,10)
            webhookBox.BackgroundColor3 = Color3.fromRGB(28,28,28); webhookBox.TextColor3 = Color3.fromRGB(200,200,200)
            webhookBox.PlaceholderText = "Paste Discord webhook URL..."; webhookBox.PlaceholderColor3 = Color3.fromRGB(80,80,80)
            webhookBox.Text = webhookUrl; webhookBox.TextSize = 11; webhookBox.Font = Enum.Font.Gotham
            webhookBox.TextXAlignment = Enum.TextXAlignment.Left; webhookBox.ClearTextOnFocus = false
            webhookBox.BorderSizePixel = 0; webhookBox.ZIndex = 10; webhookBox.TextTruncate = Enum.TextTruncate.AtEnd
            webhookBox.Active = true
            Instance.new("UICorner", webhookBox).CornerRadius = UDim.new(0,4)
            webhookBox.FocusLost:Connect(function() webhookUrl = webhookBox.Text saveConfig() end)

            makeSlider("⏱","Webhook Interval (s)",30,300,webhookInterval,37,false,function(v) webhookInterval=v saveConfig() end)

            local sendRow = makeContainer(50, 39)
            local sendBtn = Instance.new("TextButton", sendRow)
            sendBtn.Size = UDim2.new(1,-20,0,32); sendBtn.Position = UDim2.new(0,10,0,9)
            sendBtn.BackgroundColor3 = Color3.fromRGB(88,101,242); sendBtn.TextColor3 = Color3.fromRGB(255,255,255)
            sendBtn.Font = Enum.Font.GothamBold; sendBtn.TextSize = 12; sendBtn.Text = "📨 Send Now"
            sendBtn.BorderSizePixel = 0; sendBtn.ZIndex = 4
            Instance.new("UICorner",sendBtn).CornerRadius = UDim.new(0,5)

            makeSection("Device", 40)
            local vPing = makeRow("◉","Ping","0 ms",41)
            local vFPS  = makeRow("◈","FPS","0",42)
            local vExec = makeRow("⌘","Executor",EXECUTOR_NAME,43)

            makeSection("About", 45)
            local aboutRow = makeContainer(100, 46)
            local snoopy = Instance.new("ImageLabel", aboutRow)
            snoopy.Size = UDim2.new(0,80,0,80); snoopy.Position = UDim2.new(0,10,0.5,-40)
            snoopy.BackgroundTransparency = 1; snoopy.Image = "rbxassetid://75353810328300"; snoopy.ZIndex = 4
            local credit = Instance.new("TextLabel", aboutRow)
            credit.Size = UDim2.new(1,-104,1,0); credit.Position = UDim2.new(0,100,0,0)
            credit.BackgroundTransparency = 1; credit.Text = "Script made by _nznt\nPremium UI + Anti-AFK + Any Vehicle\n100% by myself"
            credit.TextColor3 = Color3.fromRGB(255,215,0); credit.Font = Enum.Font.Gotham; credit.TextSize = 12
            credit.TextXAlignment = Enum.TextXAlignment.Left; credit.TextYAlignment = Enum.TextYAlignment.Center
            credit.ZIndex = 4; credit.TextWrapped = true
            local discordRow = makeContainer(60, 47)
            local discordBtn = Instance.new("TextButton", discordRow)
            discordBtn.Size = UDim2.new(1,-20,0,28); discordBtn.Position = UDim2.new(0,10,0,26)
            discordBtn.BackgroundColor3 = Color3.fromRGB(88,101,242); discordBtn.TextColor3 = Color3.fromRGB(255,255,255)
            discordBtn.Font = Enum.Font.GothamBold; discordBtn.TextSize = 12; discordBtn.Text = "⎋ Join Discord — discord.gg/q6dUF4CsKH"
            discordBtn.BorderSizePixel = 0; discordBtn.ZIndex = 4
            Instance.new("UICorner",discordBtn).CornerRadius = UDim.new(0,5)
            discordBtn.MouseButton1Click:Connect(function()
                setclipboard("https://discord.gg/q6dUF4CsKH")
                discordBtn.Text="✓ Copied!"
                discordBtn.BackgroundColor3 = Color3.fromRGB(0,150,70)
                task.wait(2)
                discordBtn.Text="⎋ Join Discord — discord.gg/q6dUF4CsKH"
                discordBtn.BackgroundColor3 = Color3.fromRGB(88,101,242)
            end)

            local function loadNzntAutofarmArcane()
                local source
                if readfile and isfile and isfile("nznt_autofarm_arcane.lua") then
                    local ok, content = pcall(function()
                        return readfile("nznt_autofarm_arcane.lua")
                    end)
                    if ok and content and content ~= "" then
                        source = content
                    end
                end

                if not source then
                    source = game:HttpGet("https://scripts.nznt.store/raw.php?file=nznt_autofarm_arcane.lua", true)
                end

                return loadstring(source)()
            end

            local ArcaneHelper = loadNzntAutofarmArcane()
            local ArcaneUI = ArcaneHelper.CreateFarmWindow({
                Name = "nznt's hub",
                SubTitle = "AutoDrive Farm (Premium)",
                PageName = "Auto Drive",
                Webhook = true
            })

            Gui:Destroy()
            Gui = ArcaneUI.Library.Holder.Instance

            local controlSection = ArcaneUI.ConfigPage:Section({Name = "AutoFarm Config", Icon = "136879043989014"})
            local toggleCallbacks = {}
            local toggleProxy = {
                MouseButton1Click = {
                    Connect = function(_, callback)
                        table.insert(toggleCallbacks, callback)
                    end
                }
            }
            setmetatable(toggleProxy, {
                __newindex = function(self, key, value)
                    rawset(self, key, value)
                end
            })

            controlSection:Button({
                Name = "Start / Stop Auto Drive",
                Callback = function()
                    for _, callback in ipairs(toggleCallbacks) do
                        task.spawn(callback)
                    end
                end
            })
            toggleBtn = toggleProxy

            local configUnlocked = false
            local suppressConfigCallback = true
            local speedSlider
            local thresholdSlider
            local rejoinSlider

            local function warnConfig()
                ArcaneUI:Notify("Warning! If you change the normal config, any form of kicks/ban are not my responsibility, use caotiously!", 7, "75353810328300")
            end

            local function restoreStableConfig()
                SPEED = 180
                FARM_THRESHOLD = 500000
                rejoinInterval = 0
                saveConfig()
                suppressConfigCallback = true
                if speedSlider and speedSlider.Set then speedSlider:Set(SPEED) end
                if thresholdSlider and thresholdSlider.Set then thresholdSlider:Set(FARM_THRESHOLD) end
                if rejoinSlider and rejoinSlider.Set then rejoinSlider:Set(rejoinInterval) end
                suppressConfigCallback = false
            end

            controlSection:Button({
                Name = "Unlock Normal Config",
                Callback = function()
                    configUnlocked = true
                    if speedSlider and speedSlider.SetLocked then speedSlider:SetLocked(false) end
                    if thresholdSlider and thresholdSlider.SetLocked then thresholdSlider:SetLocked(false) end
                    if rejoinSlider and rejoinSlider.SetLocked then rejoinSlider:SetLocked(false) end
                    warnConfig()
                end
            })

            local vehicleNames = {}
            local vehicleIdsByName = {}
            for _, vehicle in ipairs(vehicles) do
                table.insert(vehicleNames, vehicle.name)
                vehicleIdsByName[vehicle.name] = vehicle.id
            end

            local selectedVehicleName = vehicleInput
            for _, vehicle in ipairs(vehicles) do
                if vehicle.id == vehicleInput then
                    selectedVehicleName = vehicle.name
                    break
                end
            end

            controlSection:Dropdown({
                Name = "Vehicle",
                Flag = "AutoDriveVehicle",
                Items = vehicleNames,
                Default = selectedVehicleName,
                Multi = false,
                Callback = function(name)
                    vehicleInput = vehicleIdsByName[name] or vehicleInput
                    saveConfig()
                end
            })

            speedSlider = controlSection:Slider({
                Name = "Speed",
                Flag = "AutoDriveSpeed",
                Min = MIN_SPEED,
                Max = MAX_SPEED,
                Default = SPEED,
                Suffix = "",
                Decimals = 0,
                Callback = function(value)
                    if suppressConfigCallback then return end
                    if not configUnlocked then
                        warnConfig()
                        restoreStableConfig()
                        return
                    end
                    SPEED = value
                    saveConfig()
                end
            })

            thresholdSlider = controlSection:Slider({
                Name = "Farm Threshold",
                Flag = "AutoDriveThreshold",
                Min = MIN_THRESHOLD,
                Max = MAX_THRESHOLD,
                Default = FARM_THRESHOLD,
                Suffix = "",
                Decimals = 0,
                Callback = function(value)
                    if suppressConfigCallback then return end
                    if not configUnlocked then
                        warnConfig()
                        restoreStableConfig()
                        return
                    end
                    FARM_THRESHOLD = value
                    saveConfig()
                end
            })

            rejoinSlider = controlSection:Slider({
                Name = "Auto Rejoin",
                Flag = "AutoDriveRejoin",
                Min = 0,
                Max = 120,
                Default = rejoinInterval,
                Suffix = "m",
                Decimals = 0,
                Callback = function(value)
                    if suppressConfigCallback then return end
                    if not configUnlocked then
                        warnConfig()
                        restoreStableConfig()
                        return
                    end
                    rejoinInterval = safeNumber(value, 0, 0, 120)
                    saveConfig()
                end
            })

            suppressConfigCallback = false
            if speedSlider and speedSlider.SetLocked then speedSlider:SetLocked(true, "Config Locked, Press Unlock to modify!") end
            if thresholdSlider and thresholdSlider.SetLocked then thresholdSlider:SetLocked(true, "Config Locked, Press Unlock to modify!") end
            if rejoinSlider and rejoinSlider.SetLocked then rejoinSlider:SetLocked(true, "Config Locked, Press Unlock to modify!") end

            controlSection:Toggle({
                Name = "Auto Rejoin",
                Flag = "AutoDriveAutoRejoin",
                Default = autoRejoinEnabled,
                Callback = function(value)
                    autoRejoinEnabled = value
                    saveConfig()
                end
            })

            controlSection:Toggle({
                Name = "Auto Private Server",
                Flag = "AutoDrivePrivateServer",
                Default = autoPSJoinEnabled,
                Callback = function(value)
                    autoPSJoinEnabled = value
                    saveConfig()
                    if autoPSJoinEnabled then
                        task.spawn(tryAutoPSJoin)
                    end
                end
            })

            controlSection:Toggle({
                Name = "Drag Bridge",
                Flag = "AutoDriveDragBridge",
                Default = dragBridgeEnabled,
                Callback = function(value)
                    dragBridgeEnabled = value
                    saveConfig()

                    if value then
                        ArcaneUI:Notify("Drag bridge enabled!", 4, "75353810328300")
                    end
                end
            })

            local function setBlackScreen(enabled)
                local playerGui = Player:WaitForChild("PlayerGui")
                if enabled then
                    if blackGui and blackGui.Parent then return end
                    blackGui = Instance.new("ScreenGui")
                    blackGui.Name = "NZNT_BlackScreen_AutoDrive"
                    blackGui.IgnoreGuiInset = true
                    blackGui.ResetOnSpawn = false
                    blackGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                    if Gui and Gui:IsA("ScreenGui") then
                        Gui.DisplayOrder = math.max(Gui.DisplayOrder, 999999)
                        blackGui.DisplayOrder = Gui.DisplayOrder - 1
                    else
                        blackGui.DisplayOrder = 999998
                    end
                    blackGui.Parent = playerGui

                    local frame = Instance.new("Frame")
                    frame.Size = UDim2.fromScale(1, 1)
                    frame.BackgroundColor3 = Color3.new(0, 0, 0)
                    frame.BorderSizePixel = 0
                    frame.ZIndex = 999999
                    frame.Parent = blackGui
                elseif blackGui then
                    blackGui:Destroy()
                    blackGui = nil
                end
            end

            controlSection:Toggle({
                Name = "Black Screen",
                Flag = "AutoDriveBlackScreen",
                Default = false,
                Callback = setBlackScreen
            })

            local moneySection = ArcaneUI.StatsPage:Section({Name = "Money", Icon = "97491613646216"})
            vCurrent = ArcaneHelper.MakeStat(moneySection, "Current Money", "Rp. 0")
            vEarned = ArcaneHelper.MakeStat(moneySection, "Earned", "Rp. 0")
            vMoneyHour = ArcaneHelper.MakeStat(moneySection, "Money / Hour", "Calculating...")

            local totalSection = ArcaneUI.StatsPage:Section({Name = "Total Stats", Icon = "97491613646216"})
            vTotalEarned = ArcaneHelper.MakeStat(totalSection, "Total Earned", "Rp. " .. formatNumber(totalEarned))
            vTotalTime = ArcaneHelper.MakeStat(totalSection, "Total Time", formatTime(totalTime))
            totalSection:Button({
                Name = "Reset Total Stats",
                Callback = function()
                    totalEarned = 0
                    totalTime = 0
                    if writefile then writefile("nznt_stealth_stats.txt", "0,0") end
                    vTotalEarned.Text = "Rp. 0"
                    vTotalTime.Text = "00:00:00"
                    ArcaneUI:Notify("Stats reset", 3, "75353810328300")
                end
            })

            local statusSection = ArcaneUI.StatsPage:Section({Name = "Farm Stats", Icon = "136879043989014"})
            vStatus = ArcaneHelper.MakeStat(statusSection, "Status", "Auto starting...")
            vElapsed = ArcaneHelper.MakeStat(statusSection, "Elapsed", "00:00:00")
            local vDragBridgeRaces = ArcaneHelper.MakeStat(statusSection, "Drag Bridge Races", "0")

            local deviceSection = ArcaneUI.StatsPage:Section({Name = "Device", Icon = "136879043989014"})
            vPing = ArcaneHelper.MakeStat(deviceSection, "Ping", "0 ms")
            vFPS = ArcaneHelper.MakeStat(deviceSection, "FPS", "0")
            vExec = ArcaneHelper.MakeStat(deviceSection, "Executor", EXECUTOR_NAME)

            local webhookSection = ArcaneUI.WebhookPage:Section({Name = "Discord Webhook", Icon = "136879043989014"})
            webhookSection:Textbox({
                Flag = "AutoDriveWebhookUrl",
                Placeholder = "Discord webhook URL",
                Default = webhookUrl,
                Finished = true,
                Numeric = false,
                Callback = function(value)
                    webhookUrl = tostring(value or "")
                    saveConfig()
                end
            })

            webhookSection:Slider({
                Name = "Webhook Interval",
                Flag = "AutoDriveWebhookInterval",
                Min = 30,
                Max = 300,
                Default = webhookInterval,
                Suffix = "s",
                Decimals = 0,
                Callback = function(value)
                    webhookInterval = safeNumber(value, 60, 30, 300)
                    saveConfig()
                end
            })

            local blur = Instance.new("BlurEffect", Lighting)
            blur.Size = 24

        local function cleanWorkspace()
            local char = Player.Character
            if not char then
                char = Player.CharacterAdded:Wait()
                task.wait(2)
            end
            local protectedDragRoot = findDragRace()
            if protectedDragRoot then
                pcall(function()
                    protectedDragRoot.Parent = workspace
                end)
            end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then
                root = char:WaitForChild("HumanoidRootPart")
                    task.wait(2)
                end
                
                -- Drill down to the huge platform (exactly like autofarm.lua)
                local searching = true
                while searching do
                    local result = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0))
                    if result and result.Instance then
                        local part = result.Instance
                        if part.Size.X >= HUGE_PLATFORM_SIZE or part.Name == "THE_SACRED_FLOOR" then
                            savedFloor = part
                            savedFloor.Name = "THE_SACRED_FLOOR"
                            savedFloor.Parent = workspace
                            searching = false
                        else
                            part:Destroy()
                            task.wait(0.02)
                        end
                    else
                        searching = false
                    end
                end

            -- Cleanup except platform (exactly like autofarm.lua)
            for _, obj in pairs(workspace:GetChildren()) do
                if obj ~= workspace.CurrentCamera and obj ~= char and obj ~= savedFloor and obj ~= protectedDragRoot and not obj:IsA("Terrain") then
                    obj:Destroy()
                end
            end

                local oldWalls = savedFloor and savedFloor:FindFirstChild("NZNT_SAFETY_WALLS")
                if oldWalls then
                    oldWalls:Destroy()
                end

                if savedFloor then
                    local walls = Instance.new("Folder")
                    walls.Name = "NZNT_SAFETY_WALLS"
                    walls.Parent = savedFloor

                    local cf = savedFloor.CFrame
                    local halfX = savedFloor.Size.X / 2
                    local halfZ = savedFloor.Size.Z / 2
                    local wallHeight = 140
                    local wallThickness = 10
                    local specs = {
                        {cf * CFrame.new(halfX, wallHeight / 2, 0), Vector3.new(wallThickness, wallHeight, savedFloor.Size.Z)},
                        {cf * CFrame.new(-halfX, wallHeight / 2, 0), Vector3.new(wallThickness, wallHeight, savedFloor.Size.Z)},
                        {cf * CFrame.new(0, wallHeight / 2, halfZ), Vector3.new(savedFloor.Size.X, wallHeight, wallThickness)},
                        {cf * CFrame.new(0, wallHeight / 2, -halfZ), Vector3.new(savedFloor.Size.X, wallHeight, wallThickness)},
                    }

                    for _, spec in ipairs(specs) do
                        local wall = Instance.new("Part")
                        wall.Name = "SafetyWall"
                        wall.Anchored = true
                        wall.CanCollide = true
                        wall.Transparency = 1
                        wall.Size = spec[2]
                        wall.CFrame = spec[1]
                        wall.Parent = walls
                    end
                end
            end

            local function respawnVehicle(hum, statusText)
                if isRespawning or farmTransitionActive then return end
                isRespawning = true; farmTransitionActive = true; farmingActive = false
                unseatedSince = nil
                vStatus.Text = statusText or ("Reached " .. formatNumber(FARM_THRESHOLD) .. "! Respawning...")
                
                -- Don't update totalEarned/totalTime here - UI handles it with session values
                -- This prevents double counting
                
                vStatus.Text = statusText or ("Reached " .. formatNumber(FARM_THRESHOLD) .. "! Stopping...")
                stopVehicleCompletely()
                sendKey(Enum.KeyCode.Space); task.wait(0.5)
                cleanupPhysics()
                despawnVehicle(); task.wait(2)
                spawnVehicle(vehicleInput); task.wait(3)
                
                local seat = findSpawnedSeat(12)
                if not seat then
                    vStatus.Text = "Spawned motor seat not found!"
                    isRespawning = false
                    farmTransitionActive = false
                    lastVoidTime = 0
                    return
                end
                
                local char = Player.Character or Player.CharacterAdded:Wait()
                hum = char:FindFirstChildOfClass("Humanoid") or hum
                local root = char:WaitForChild("HumanoidRootPart")
                if not hum or not sitOnSpawnedSeat(seat, hum, root) then
                    vStatus.Text = "Failed to sit on spawned motor!"
                    despawnVehicle()
                    isRespawning = false
                    farmTransitionActive = false
                    lastVoidTime = 0
                    return
                end
                
                currentVehicle = getVehicleRootFromSeat(seat)
                seatOffset = calculateSeatOffset(currentVehicle, seat)
                startMoney = getMoney(); startTime = os.time()
                unseatedSince = nil
                setupPhysics(seat)
                lastVoidTime = 0
                farmingActive = true; active = true; isRespawning = false; farmTransitionActive = false; vStatus.Text = "Farming!"
            end

            local suppressCharacterRestart = false

            local function startFarming()
                if farmingActive then return true end
                if farmTransitionActive then return false end
                farmTransitionActive = true
                local char = Player.Character or Player.CharacterAdded:Wait()
                local hum, root = char:WaitForChild("Humanoid"), char:WaitForChild("HumanoidRootPart")
                
                vStatus.Text = "Joining..."
                local lce = RS:FindFirstChild("LoadCharacterEvent")
                if lce then
                    suppressCharacterRestart = true
                    lce:FireServer()
                    char = Player.CharacterAdded:Wait()
                    hum = char:WaitForChild("Humanoid"); root = char:WaitForChild("HumanoidRootPart")
                    task.wait(1)
                    suppressCharacterRestart = false
                end
                
                vStatus.Text = "Spawning vehicle..."
                spawnVehicle(vehicleInput); task.wait(4)
                
                vStatus.Text = "Finding seat..."
                local seat = findSpawnedSeat(12)
                if not seat then vStatus.Text = "Spawned motor seat not found!"; farmTransitionActive = false; return false end
                
                vStatus.Text = "Sitting..."
                if not sitOnSpawnedSeat(seat, hum, root) then
                    vStatus.Text = "Failed to sit on spawned motor!"
                    despawnVehicle()
                    farmTransitionActive = false
                    return false
                end
                
                pcall(function() blur:Destroy() end)
                currentVehicle = getVehicleRootFromSeat(seat)
                seatOffset = calculateSeatOffset(currentVehicle, seat)
                startMoney = getMoney(); startTime = os.time()
                sessionStartMoney = startMoney; sessionStartTime = os.time()
                sessionStart = os.time()
                unseatedSince = nil
                farmingActive = true; active = true
                setupPhysics(seat)
                farmTransitionActive = false
                
                vStatus.Text = "Farming!"
                toggleBtn.Text = "⏹ STOP"; toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
                
                task.spawn(function()
                    while farmingActive do
                        task.wait(1)
                        if farmingActive and not isRespawning and startMoney and getMoney() - startMoney >= FARM_THRESHOLD then
                            respawnVehicle(hum)
                        end
                    end
                end)
                return true
            end

            local function stopFarming()
                if not farmingActive then return end
                -- Save session data to totals before stopping
                if sessionStartTime and sessionStartMoney then
                    local sessionElapsed = os.time() - sessionStartTime
                    local sessionEarned = getMoney() - sessionStartMoney
                    totalEarned = totalEarned + math.max(0, sessionEarned)
                    totalTime = totalTime + sessionElapsed
                    if writefile then writefile("nznt_stealth_stats.txt", tostring(totalEarned) .. "," .. tostring(totalTime)) end
                end
                farmingActive = false; active = false; vStatus.Text = "Stopping..."
                dragBridgeRunning = false
                cleanupPhysics(); despawnVehicle()
                -- Reset session vars
                sessionStartTime = nil; sessionStartMoney = nil
                startTime = nil; startMoney = nil
                vStatus.Text = "Stopped - Ready"
                toggleBtn.Text = "▶ START"; toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                -- Show saved totals
                vTotalEarned.Text = "Rp. " .. formatNumber(totalEarned)
                vTotalTime.Text = formatTime(totalTime)
                vEarned.Text = "Rp. 0"
                vElapsed.Text = "00:00:00"
            end

            toggleBtn.MouseButton1Click:Connect(function()
                if not farmingActive then
                    toggleBtn.Text = "LOADING..."; toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
                    if not startFarming() then toggleBtn.Text = "▶ START"; toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0) end
                else stopFarming() end
            end)

            task.spawn(function()
                while true do
                    task.wait(1)

                if not farmingActive or isRespawning or farmTransitionActive then
                        unseatedSince = nil
                        continue
                    end

                    local char = Player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local expectedSeat = currentVehicle and (currentVehicle:IsA("VehicleSeat") and currentVehicle or currentVehicle:FindFirstChildWhichIsA("VehicleSeat", true))

                    if hum and hum.SeatPart and (not expectedSeat or hum.SeatPart == expectedSeat) then
                        unseatedSince = nil
                        continue
                    end

                    unseatedSince = unseatedSince or os.clock()
                    if os.clock() - unseatedSince >= NOT_SEATED_TIMEOUT then
                        unseatedSince = nil
                        vStatus.Text = "Not seated for 10s! Restarting..."

                        if hum then
                            respawnVehicle(hum, "Not seated for 10s! Respawning...")
                        else
                            farmingActive = false
                            active = false
                            cleanupPhysics()
                            despawnVehicle()
                            task.wait(1)
                            startFarming()
                        end
                    end
                end
            end)

            local function sendWebhook()
                if webhookUrl == "" or not webhookUrl:find("discord") then return end
                local sessionElapsed = os.time() - sessionStartTime
                local money = getMoney()
                local sessionEarned = sessionStartMoney and (money - sessionStartMoney) or 0
                local mph = sessionElapsed > 60 and math.floor((sessionEarned/sessionElapsed)*3600) or 0
                local ct = totalEarned + sessionEarned
                local ctt = totalTime + sessionElapsed
                local body = '{"embeds":[{"title":"Stealth Farm — Stats","color":16776960,"fields":['
                    ..'{"name":"💰 Current Money","value":"Rp. ' .. formatNumber(money) .. '","inline":true},'
                    ..'{"name":"📈 Session Earned","value":"Rp. ' .. formatNumber(math.max(0,sessionEarned)) .. '","inline":true},'
                    ..'{"name":"⚡ Money/Hour","value":"Rp. ' .. formatNumber(mph) .. '","inline":true},'
                    ..'{"name":"⏱ Session Time","value":"' .. formatTime(sessionElapsed) .. '","inline":true},'
                    ..'{"name":"🏆 Total Earned","value":"Rp. ' .. formatNumber(ct) .. '","inline":true},'
                    ..'{"name":"⏰ Total Time","value":"' .. formatTime(ctt) .. '","inline":true}'
                    ..'],"footer":{"text":"by _nznt — Premium"}}]}'
                pcall(function()
                    request({Url=webhookUrl, Method="POST", Headers={["Content-Type"]="application/json"}, Body=body})
                end)
            end

            sendBtn.MouseButton1Click:Connect(function()
                sendBtn.Text = "⏳ Sending..."
                task.spawn(function() sendWebhook(); sendBtn.Text = "✓ Sent!"; task.wait(2); sendBtn.Text = "📨 Send Now" end)
            end)

            task.spawn(function()
                while true do
                    task.wait(safeNumber(webhookInterval, 60, 5, 300))
                    if farmingActive and webhookUrl ~= "" then sendWebhook() end
                end
            end)

            task.spawn(function()
                while task.wait(0.5) do
                    if not farmingActive then continue end
                    if not startTime then continue end
                    
                    local money = getMoney()
                    -- Earned THIS bike (resets on each spawn)
                    local earnedThisBike = startMoney and (money - startMoney) or 0
                    -- For money/hour, use session time
                    local sessionElapsed = sessionStartTime and (os.time() - sessionStartTime) or 0
                    local sessionEarned = sessionStartMoney and (money - sessionStartMoney) or 0
                    local mph = sessionElapsed > 60 and math.floor((sessionEarned/sessionElapsed)*3600) or 0
                    
                    vCurrent.Text = "Rp. " .. formatNumber(money)
                    vEarned.Text = "Rp. " .. formatNumber(math.max(0, earnedThisBike))
                    vMoneyHour.Text = sessionElapsed > 60 and ("Rp. " .. formatNumber(mph) .. " /hr") or "Calculating..."
                    vElapsed.Text = formatTime(os.time() - startTime)
                    vDragBridgeRaces.Text = tostring(dragBridgeRaceCount)
                    vPing.Text = getPing() .. " ms"
                    vFPS.Text = tostring(lastFPS)
                    
                    -- Total stats = saved totals + current session
                    local ct = totalEarned + sessionEarned
                    local ctt = totalTime + sessionElapsed
                    vTotalEarned.Text = "Rp. " .. formatNumber(ct)
                    vTotalTime.Text = formatTime(ctt)
                    
                    -- Save combined totals to file periodically for crash recovery (don't update in-memory totals)
                    if sessionElapsed > 0 and sessionElapsed % 30 < 1 and writefile then
                        writefile("nznt_stealth_stats.txt", tostring(ct) .. "," .. tostring(ctt))
                    end
                end
            end)

            task.spawn(function()
                while true do
                    task.wait(DRAG_BRIDGE_LOOP_DELAY)
                    if dragBridgeEnabled and farmingActive and not isRespawning and currentVehicle then
                        runDragBridgePass()
                    end
                end
            end)

            RunService.Heartbeat:Connect(function()
                if not farmingActive or farmTransitionActive or not force or not currentVehicle then return end
                local seat = currentVehicle:IsA("VehicleSeat") and currentVehicle or currentVehicle:FindFirstChildWhichIsA("VehicleSeat", true)
                if not seat then return end

                if dragBridgeRunning then
                    zeroVehicleVelocity()
                    return
                end
                
                -- Check auto-rejoin timer
                if autoRejoinEnabled and rejoinInterval > 0 and os.time() - sessionStart >= rejoinInterval * 60 then
                    vStatus.Text = "Auto rejoining..."
                    if not queueSelfOnTeleport(true) then
                        vStatus.Text = "Auto rejoin queue failed"
                        return
                    end
                    farmingActive = false; active = false
                    cleanupPhysics()
                    despawnVehicle()
                    task.wait(1)
                    TeleportService:Teleport(game.PlaceId, Player)
                    return
                end
                
                -- Check farm threshold first
                if startMoney and getMoney() - startMoney >= FARM_THRESHOLD and not isRespawning then
                    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        respawnVehicle(hum)
                        return
                    end
                end
                
                local groundRay = groundRaycast(seat.Position, math.max(25, seatOffset + 8))
                if not groundRay then
                    lastVoidTime = lastVoidTime > 0 and lastVoidTime or os.clock()
                    if os.clock() - lastVoidTime < voidThreshold then
                        return
                    end

                    if isRespawning then return end
                    isRespawning = true
                    farmTransitionActive = true
                    -- In air/void - respawn immediately with retry
                    vStatus.Text = "In air! Respawning..."
                    farmingActive = false; active = false
                    cleanupPhysics()
                    despawnVehicle()
                    
                    -- Retry loop until successful
                    for retry = 1, 5 do
                        task.wait(1)
                        spawnVehicle(vehicleInput); task.wait(3)
                        local newSeat = findSpawnedSeat(10)
                        if newSeat then
                            local char = Player.Character
                            if char then
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                local root = char:FindFirstChild("HumanoidRootPart")
                                if hum and root and sitOnSpawnedSeat(newSeat, hum, root) then
                                    currentVehicle = getVehicleRootFromSeat(newSeat)
                                    seatOffset = calculateSeatOffset(currentVehicle, newSeat)
                                    startMoney = getMoney()
                                    startTime = os.time()
                                    if not sessionStartMoney then sessionStartMoney = startMoney end
                                    setupPhysics(newSeat)
                                    farmingActive = true; active = true
                                    lastVoidTime = 0
                                    isRespawning = false
                                    farmTransitionActive = false
                                    vStatus.Text = "Farming!"
                                    return  -- Success, exit heartbeat
                                end
                            end
                        end
                        vStatus.Text = "Retry " .. retry .. "/5..."
                    end
                    isRespawning = false
                    farmTransitionActive = false
                    lastVoidTime = 0
                    vStatus.Text = "Failed after 5 retries! Click START"
                    return
                end
                lastVoidTime = 0
                
                -- Keep vehicle flat on ground using dynamic seat offset
                local p = seat.Position
                local _, ry = seat.CFrame:ToEulerAnglesYXZ()
                local targetCFrame = CFrame.new(p.X, groundRay.Position.Y + seatOffset, p.Z) * CFrame.Angles(0, ry, 0)
                seat.CFrame = targetCFrame
                -- Update gyro to maintain upright orientation
                if gyro then
                    gyro.CFrame = CFrame.new(p.X, groundRay.Position.Y + seatOffset, p.Z) * CFrame.Angles(0, ry, 0)
                end
                
                -- Direction change detection
                local rayOrigin = (seat.CFrame * CFrame.new(0, 0, -CHECK_DISTANCE * direction)).p
                local hit = groundRaycast(rayOrigin, 30)
                if not hit then
                    local now = tick()
                    if now - lastDirChange >= DIR_COOLDOWN then
                        direction = direction * -1
                        lastDirChange = now
                        -- Reset velocity to instantly stop momentum when changing direction
                        for _, part in ipairs(currentVehicle:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            end
                        end
                        if seat:IsA("BasePart") then
                            seat.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        end
                    end
                end
                
                SPEED = safeNumber(SPEED, 180, MIN_SPEED, MAX_SPEED)
                force.VectorVelocity = Vector3.new(0, 0, -SPEED * direction)
            end)

            task.spawn(function()
                task.wait(2)
                cleanWorkspace()
                pcall(function() blur:Destroy() end)
                if getgenv and getgenv().NZNT_AUTODRIVE_AUTO_START then
                    getgenv().NZNT_AUTODRIVE_AUTO_START = false
                end
                task.wait(1)

                for attempt = 1, 3 do
                    if farmingActive then
                        return
                    end

                    vStatus.Text = attempt == 1 and "Auto starting..." or ("Auto start retry " .. attempt .. "/3...")
                    local ok = startFarming()
                    if ok or farmingActive then
                        return
                    end

                    cleanupPhysics()
                    despawnVehicle()
                    task.wait(2)
                end

                vStatus.Text = "Auto start failed - Click START"
                toggleBtn.Text = "▶ START"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            end)

            print("✅ Stealth Farm Loaded - Premium")

            local isRestarting = false
            Player.CharacterAdded:Connect(function()
                if suppressCharacterRestart or farmTransitionActive then return end
                if isRestarting or not farmingActive then return end
                isRestarting = true
                unseatedSince = os.clock()
                task.wait(1)
                isRestarting = false
            end)