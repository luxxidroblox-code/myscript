-- [[ STEALTH FARM PREMIUM — INTEGRATED INTO RAYFIELD UI ]] --

-- [[ INITIALIZATION & ANTI-CHEAT BYPASS ]] --
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
    if x and a == x then 
        return coroutine.yield(coroutine.running()) 
    end
    return o(...) 
end))

setthreadidentity(7) 

pcall(function() 
    game:GetService("CoreGui").RobloxGui["CoreScripts/NetworkPause"]:Destroy() 
end)

if getgenv and getgenv().NZNT_AUTODRIVE_AUTO_START then 
    task.wait(1)
    pcall(function() 
        local args = {}
        game:GetService("ReplicatedStorage"):WaitForChild("menuToggleRequest", 10):FireServer(table.unpack(args)) 
    end)
end 

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

task.wait(0.2)

-- [[ SERVICES ]] --
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService") 
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting") 
local RS               = game:GetService("ReplicatedStorage")
local VIM              = game:GetService("VirtualInputManager") 
local Player           = Players.LocalPlayer
local TeleportService  = game:GetService("TeleportService") 
local GuiService       = game:GetService("GuiService") 
local VirtualUser      = game:GetService("VirtualUser")

-- [[ CONFIGURATIONS & VARIABLES ]] --
local SPEED              = 200 
local MIN_SPEED          = 0
local MAX_SPEED          = 400 
local CHECK_DISTANCE     = 15
local HUGE_PLATFORM_SIZE = 2000 
local FARM_THRESHOLD     = 500000
local DEFAULT_THRESHOLD  = 500000 
local MIN_THRESHOLD      = 500000
local MAX_THRESHOLD      = 2000000 
local NOT_SEATED_TIMEOUT = 10

local active             = false 
local farmingActive      = false
local currentVehicle     = nil 
local force              = nil
local gyro               = nil 
local attachment         = nil
local direction          = 1 
local savedFloor         = nil
local startTime          = nil 
local startMoney         = nil
local sessionStartTime   = nil 
local sessionStartMoney  = nil
local lastDirChange      = 0 
local DIR_COOLDOWN       = 0.3
local isRespawning       = false 
local unseatedSince      = nil
local vehicleInput       = "Yamahax-MioSporty" 
local webhookUrl         = ""
local webhookInterval    = 60 
local lastVoidTime       = 0
local voidThreshold      = 2 
local seatOffset         = 1.5
local rejoinInterval     = 0 
local sessionStart       = os.time()

local autoRejoinEnabled  = false 
local autoPSJoinEnabled  = false 
local AntiAFKEnabled     = true 
local AntiAdminEnabled   = true

local SURAKARTA_ID       = 131378148336503 
local SURAKARTA_ARG      = "131378148336503" 
local GAME_GROUP_ID      = 11378976 
local MIN_STAFF_RANK     = 200

-- Referensi Status String (Rayfield Label / Element pengganti Arcane)
local currentStatusText  = "Ready - Click START"

-- [[ ANTI-ADMIN & ANTI-AFK ]] --
local function checkForAdmin(targetPlayer) 
    if not AntiAdminEnabled or targetPlayer == Player then return end 
    pcall(function() 
        if targetPlayer:GetRankInGroup(GAME_GROUP_ID) >= MIN_STAFF_RANK then 
            currentStatusText = "Admin detected - leaving"
            task.wait(0.5) 
            Player:Kick("Admin detected, leaving for safety.") 
        end 
    end) 
end

for _, targetPlayer in ipairs(Players:GetPlayers()) do 
    task.spawn(checkForAdmin, targetPlayer) 
end 

Players.PlayerAdded:Connect(checkForAdmin)

Player.Idled:Connect(function() 
    if AntiAFKEnabled then 
        pcall(function() 
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new()) 
        end) 
    end 
end)

-- [[ DRAG BRIDGE SETTINGS ]] --
local dragBridgeEnabled           = true
local dragBridgeRunning           = false 
local dragBridgePassActive        = false
local dragBridgeRaceCount         = 0 
local DRAG_BRIDGE_LIMIT           = 100
local DRAG_BRIDGE_CHECKPOINT_DELAY = 3 
local DRAG_BRIDGE_START_HOLD       = 3
local DRAG_BRIDGE_LOOP_DELAY       = 8 
local blackGui                    = nil

-- [[ UTILITY FUNCTIONS ]] --
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
local CFG_MIGRATION_FILE = "nznt_stealth_config_speed200_v1.txt" 

local function saveConfig()
    if not writefile then return end 
    SPEED = safeNumber(SPEED, 200, MIN_SPEED, MAX_SPEED)
    FARM_THRESHOLD = safeNumber(FARM_THRESHOLD, DEFAULT_THRESHOLD, MIN_THRESHOLD, MAX_THRESHOLD) 
    webhookInterval = safeNumber(webhookInterval, 60, 30, 300)
    rejoinInterval = safeNumber(rejoinInterval, 0, 0, 120) 
    
    writefile(CFG_FILE, '{"speed":'..SPEED
    ..',"farmThreshold":'..FARM_THRESHOLD..',"webhookUrl":"'..webhookUrl:gsub('"','\\"') ..'","webhookInterval":'..webhookInterval..',"vehicleInput":"'..vehicleInput:gsub('"','\\"')
    ..'","rejoinInterval":'..rejoinInterval..',"autoRejoinEnabled":'..(autoRejoinEnabled and "true" or "false") ..',"autoPSJoinEnabled":'..(autoPSJoinEnabled and "true" or "false")..',"dragBridgeEnabled":'..(dragBridgeEnabled and "true" or "false")..'}')
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
    FARM_THRESHOLD = g("farmThreshold", FARM_THRESHOLD)
    webhookUrl = g("webhookUrl", webhookUrl) 
    webhookInterval = g("webhookInterval", webhookInterval)
    vehicleInput = g("vehicleInput", vehicleInput)
    rejoinInterval = g("rejoinInterval", rejoinInterval) 
    
    autoRejoinEnabled = s:find('"autoRejoinEnabled":true') ~= nil
    autoPSJoinEnabled = s:find('"autoPSJoinEnabled":true') ~= nil 
    dragBridgeEnabled = s:find('"dragBridgeEnabled":false') == nil 
    
    SPEED = safeNumber(SPEED, 200, MIN_SPEED, MAX_SPEED)
    FARM_THRESHOLD = safeNumber(FARM_THRESHOLD, DEFAULT_THRESHOLD, MIN_THRESHOLD, MAX_THRESHOLD) 
end

local function runOneTimeConfigMigration() 
    if not writefile then return end
    if isfile and isfile(CFG_MIGRATION_FILE) then return end 
    SPEED = 200
    FARM_THRESHOLD = 500000 
    saveConfig()
    writefile(CFG_MIGRATION_FILE, "done") 
end

loadConfig() 
runOneTimeConfigMigration()

local WEBHOOK_FILE = "nznt_webhook_config.json" 

local function loadSharedWebhookConfig()
    if not isfile or not readfile or not isfile(WEBHOOK_FILE) then return end 
    local ok, content = pcall(function() return readfile(WEBHOOK_FILE) end)
    if ok and content then 
        local ok2, data = pcall(function() return game:GetService("HttpService"):JSONDecode(content) end)
        if ok2 and data then 
            if data.url and data.url ~= "" then
                webhookUrl = data.url 
                webhookInterval = data.interval or 60
                warn("[Auto Drive Farm] Webhook loaded from loader: " .. (data.enabled and "enabled" or "disabled")) 
            end
        end 
    end
end 

loadSharedWebhookConfig()

local SCRIPT_URL = "https://scripts.nznt.store/raw.php?file=autofarm_yellow.lua" 
local scriptSource = ""
pcall(function() scriptSource = game:HttpGet(SCRIPT_URL, true) end) 

local function queueSelfOnTeleport(autoStart)
    local source = scriptSource 
    if source == "" and readfile and isfile and isfile("autofarm_yellow.lua") then
        local ok, localSource = pcall(readfile, "autofarm_yellow.lua") 
        if ok and localSource and localSource ~= "" then
            source = localSource 
        end
    end 
    if source == "" then return false end
    
    local queueFunc = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if not queueFunc then return false end 
    
    local ok = pcall(queueFunc, "getgenv().NZNT_AUTODRIVE_AUTO_START = " .. (autoStart and "true" or "false") .. "\n" .. source)
    return ok 
end

if autoRejoinEnabled then 
    queueSelfOnTeleport(true)
end 

GuiService.ErrorMessageChanged:Connect(function()
    if not autoRejoinEnabled then return end 
    if scriptSource ~= "" then
        task.wait(3) 
        queueSelfOnTeleport(true)
    end 
    task.wait(5)
    TeleportService:Teleport(game.PlaceId, Player) 
end)

-- [[ SERVER & TELEPORT MANAGEMENT ]] --
local currentServerCode = "" 

local function grabServerCode()
    local pse = RS:FindFirstChild("PrivateServerEvents") if not pse then return "" end
    local getCode = pse:FindFirstChild("GetCurrentCode") if not getCode then return "" end
    local code = "" 
    local conn = getCode.OnClientEvent:Connect(function(c) code = tostring(c) end)
    
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
    
    if currentID ~= SURAKARTA_ID then 
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
    
    currentServerCode = grabServerCode()
    if currentServerCode == "" or currentServerCode == "nil" then 
        local pse = RS:FindFirstChild("PrivateServerEvents") 
        if pse then
            local createRemote = pse:FindFirstChild("CreatePrivateServer") 
            local joinRemote = pse:FindFirstChild("JoinPrivateServer")
            if joinRemote then 
                local existingCode = grabServerCode()
                if existingCode ~= "" and existingCode ~= "nil" then 
                    joinRemote:FireServer(existingCode) 
                    task.wait(5)
                    return 
                end
            end 
            if createRemote then
                for i = 1, 3 do 
                    createRemote:FireServer(SURAKARTA_ARG)
                    task.wait(5) 
                end
            end 
        end
    end 
end

tryAutoPSJoin() 

local function getExecutorName()
    if identifyexecutor then 
        local ok, n = pcall(identifyexecutor) 
        if ok and n then return n end 
    end 
    if getexecutorname  then 
        local ok, n = pcall(getexecutorname)  
        if ok and n then return n end 
    end
    return "Unknown" 
end

local EXECUTOR_NAME = getExecutorName() 
local lastFPS = 60

RunService.Heartbeat:Connect(function(dt) 
    if dt > 0 then lastFPS = math.floor(1/dt) end
end) 

local function getMoney()
    local pd = Player:FindFirstChild("PlayerData") 
    if pd then 
        local rp = pd:FindFirstChild("RPValue") 
        if rp then return rp.Value end 
    end
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

-- [[ VEHICLE UTILITIES ]] --
local function findClosestSeat() 
    local best, bestDist = nil, math.huge
    local char = Player.Character if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart") if not root then return nil end
    
    for _, obj in ipairs(workspace:GetChildren()) do 
        local seat = obj:FindFirstChildWhichIsA("VehicleSeat", true)
        if seat then 
            local dist = (seat.Position - root.Position).Magnitude
            if dist < bestDist then best, bestDist = seat, dist end 
        end
    end 
    return best
end 

local function getVehicleRootFromSeat(seat)
    local node = seat 
    while node and node.Parent and node.Parent ~= workspace do
        node = node.Parent 
    end
    if node and node ~= seat then return node end 
    return seat
end 

local function getPartLowestY(part)
    local cf, half = part.CFrame, part.Size * 0.5 
    local lowest = math.huge
    for _, x in ipairs({-1, 1}) do 
        for _, y in ipairs({-1, 1}) do
            for _, z in ipairs({-1, 1}) do 
                local p = cf * Vector3.new(half.X * x, half.Y * y, half.Z * z)
                if p.Y < lowest then lowest = p.Y end 
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
            if wheelBottom < lowestVehicleY then lowestVehicleY = wheelBottom end 
            if isWheelPart(part) then
                if wheelBottom < lowestWheelY then lowestWheelY = wheelBottom end 
            end
        end 
    end
    
    local lowestY = lowestWheelY ~= math.huge and lowestWheelY or lowestVehicleY 
    if lowestY ~= math.huge then
        return math.clamp(seat.Position.Y - lowestY, 1, 12) 
    end
    return 1.5 
end

-- [[ PHYSICS MANAGEMENT ]] --
local function setupPhysics(seat) 
    attachment = Instance.new("Attachment", seat)
    force = Instance.new("LinearVelocity", seat) 
    force.MaxForce = 99999999
    force.Attachment0 = attachment 
    force.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    
    gyro = Instance.new("BodyGyro", seat) 
    gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    gyro.P = 100000 
    gyro.D = 1000
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
    if force then force.VectorVelocity = Vector3.zero end
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
            if os.clock() - stoppedSince >= 0.35 then break end
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

local function fireCarEvent(name, ...) 
    local sf = RS:FindFirstChild("SpawnCarEvents")
    if sf then 
        local r = sf:FindFirstChild(name) 
        if r then r:FireServer(...) return true end 
    end 
    return false
end 

local function spawnVehicle(id) return fireCarEvent("SpawnCar", id or vehicleInput) end
local function despawnVehicle() fireCarEvent("DespawnCar") end 

-- [[ DRAG RACE LOGIC ]] --
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
    local startDet = (detectorRoot:FindFirstChild("DetectorStart") or detectorRoot:FindFirstChild("Start") or dragRace:FindFirstChild("DetectorStart") or dragRace:FindFirstChild("Start")) 
    local c1 = (detectorRoot:FindFirstChild("DetectorC1") or detectorRoot:FindFirstChild("C1") or dragRace:FindFirstChild("DetectorC1") or dragRace:FindFirstChild("C1")) 
    local c2 = (detectorRoot:FindFirstChild("DetectorC2") or detectorRoot:FindFirstChild("C2") or dragRace:FindFirstChild("DetectorC2") or dragRace:FindFirstChild("C2")) 
    local c3 = (detectorRoot:FindFirstChild("DetectorC3") or detectorRoot:FindFirstChild("C3") or dragRace:FindFirstChild("DetectorC3") or dragRace:FindFirstChild("C3")) 
    local finishDet = (detectorRoot:FindFirstChild("DetectorFinish") or detectorRoot:FindFirstChild("Finish") or dragRace:FindFirstChild("DetectorFinish") or dragRace:FindFirstChild("Finish")) 
    return startDet, c1, c2, c3, finishDet
end 

local function touchDragDetector(detector, seatCFrame)
    if not detector or not seatCFrame then return false end 
    local ok = pcall(function() detector.CFrame = seatCFrame end)
    task.wait(0.1) 
    pcall(function() detector.CFrame = seatCFrame * CFrame.new(0, -100, 0) end)
    return ok 
end

local function getCurrentSeat() 
    if not currentVehicle then return nil end
    if currentVehicle:IsA("VehicleSeat") then return currentVehicle end 
    return currentVehicle:FindFirstChildWhichIsA("VehicleSeat", true)
end 

local function zeroVehicleVelocity()
    if force then force.VectorVelocity = Vector3.zero end 
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

-- Forward declaration update UI status
local updateUIStatus;

local function runDragBridgePass()
    if dragBridgePassActive or not dragBridgeEnabled or not farmingActive or isRespawning then return end 
    local seat = getCurrentSeat()
    if not seat then return end 
    local dragRace = findDragRace()
    if not dragRace then 
        updateUIStatus("Drag bridge: DragRace not found")
        return 
    end
    
    local startDet, c1, c2, c3, finishDet = findDragDetectors(dragRace) 
    if not startDet or not finishDet then
        updateUIStatus("Drag bridge: detectors not found") 
        return
    end 
    
    dragBridgePassActive = true
    dragBridgeRunning = true 
    local oldStatus = currentStatusText
    local seatCFrame = seat.CFrame 
    
    updateUIStatus("Drag bridge: halting...")
    holdVehicleStill(0.5) 
    seatCFrame = seat.CFrame
    
    updateUIStatus("Drag bridge: start") 
    touchDragDetector(startDet, seatCFrame)
    updateUIStatus("Drag bridge: waiting for timer...") 
    holdVehicleStill(DRAG_BRIDGE_START_HOLD)
    dragBridgeRunning = false 
    
    for index, checkpoint in ipairs({c1, c2, c3}) do
        if checkpoint and dragBridgeEnabled and farmingActive and not isRespawning then 
            seatCFrame = seat.CFrame
            updateUIStatus("Drag bridge: checkpoint " .. tostring(index)) 
            touchDragDetector(checkpoint, seatCFrame)
            task.wait(DRAG_BRIDGE_CHECKPOINT_DELAY) 
        end
    end 
    
    if dragBridgeEnabled and farmingActive and not isRespawning then
        seatCFrame = seat.CFrame 
        updateUIStatus("Drag bridge: finish")
        touchDragDetector(finishDet, seatCFrame) 
        dragBridgeRaceCount = dragBridgeRaceCount + 1
        
        if dragBridgeRaceCount >= DRAG_BRIDGE_LIMIT then 
            updateUIStatus("Drag bridge: 100 races - rejoining...")
            if writefile then 
                writefile("nznt_stealth_stats.txt", tostring(totalEarned) .. "," .. tostring(totalTime))
            end 
            if not queueSelfOnTeleport(true) then
                updateUIStatus("Drag bridge: re-exec queue failed") 
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
        updateUIStatus(oldStatus)
    end 
    dragBridgeRunning = false
    dragBridgePassActive = false 
end

-- [[ INTEGRASI INTEGRATED INTERFACE RAYFIELD UI ]] --
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "NZNT Stealth Farm (Premium)",
   LoadingTitle = "Loading interface...",
   LoadingSubtitle = "by NZNT",
   ConfigurationSaving = {
      Enabled = false
   }
})

local MainTab = Window:CreateTab("Auto Farm", 4483362458)
local StatsTab = Window:CreateTab("Stats & Logs", 4483362458)

-- [[ DYNAMIC LIST VEHICLE DARI GAME ]] --
local function getVehicleList() 
    local out = {}; 
    pcall(function() 
        local d = RS:FindFirstChild("DealershipEvents"); 
        local init = d and d:FindFirstChild("InitializeCarData"); 
        if not init or not init:IsA("RemoteFunction") then return end; 
        local ok, cfg = pcall(function() return init:InvokeServer() end); 
        if ok and type(cfg) == "table" then 
            for _, v in pairs(cfg) do 
                if type(v) == "table" and v.Name then out[#out + 1] = {id = v.Name, name = v.DisplayName or v.Name} end 
            end 
        end 
    end); 
    if #out > 0 then 
        table.sort(out, function(a, b) return a.name < b.name end); 
        return out 
    end; 
    -- Fallback list komplit dari database gambar spawner agar ngga cuma Mio Sporty
    return {
        {id = "Yamahax-MioSporty", name = "Yamahax - Mio Sporty (2006)"},
        {id = "Kawzaki-NinjaRR", name = "Kawzaki - Ninja RR FFA Thailand"},
        {id = "Hando-VarioTechno", name = "Hando - Vario Techno KZR SR"},
        {id = "Hando-Scoopy", name = "Hando - Scoopy (2020)"},
        {id = "Hando-NewVario250", name = "Hando - New Vario 250cc"}
    } 
end

local vehicles = getVehicleList()
local validVehicle = false 
for _, vehicle in ipairs(vehicles) do 
    if vehicle.id == vehicleInput then validVehicle = true break end 
end 
if not validVehicle and vehicles[1] then vehicleInput = vehicles[1].id end

local vehicleNames = {}
local vehicleIdsByName = {} 
for _, vehicle in ipairs(vehicles) do
    table.insert(vehicleNames, vehicle.name) 
    vehicleIdsByName[vehicle.name] = vehicle.id
end 

local selectedVehicleName = vehicleInput
for _, vehicle in ipairs(vehicles) do 
    if vehicle.id == vehicleInput then selectedVehicleName = vehicle.name break end 
end

-- Forward declaration fungsi start/stop core
local startFarming, stopFarming;

-- [[ MAIN UI CONTROLS IN RAYFIELD ]] --

local ToggleFarm = MainTab:CreateToggle({
   Name = "Start / Stop Auto Drive",
   CurrentValue = false,
   Flag = "ToggleAutoDrive",
   Callback = function(Value)
       if Value then
           if not farmingActive then startFarming() end
       else
           if farmingActive then stopFarming() end
       end
   end,
})

local VehicleDropdown = MainTab:CreateDropdown({
   Name = "Vehicle Spawner Target",
   Options = vehicleNames,
   CurrentOption = {selectedVehicleName},
   MultipleOptions = false,
   Callback = function(Option)
       vehicleInput = vehicleIdsByName[Option[1]] or vehicleInput
       saveConfig()
   end,
})

local SpeedSlider = MainTab:CreateSlider({
   Name = "Speed Configuration",
   Min = MIN_SPEED,
   Max = MAX_SPEED,
   CurrentValue = SPEED,
   Flag = "SpeedSliderFlag",
   Callback = function(Value)
       SPEED = Value
       saveConfig()
   end,
})

local ThresholdSlider = MainTab:CreateSlider({
   Name = "Farm Threshold Reset",
   Min = MIN_THRESHOLD,
   Max = MAX_THRESHOLD,
   CurrentValue = FARM_THRESHOLD,
   Flag = "ThresholdSliderFlag",
   Callback = function(Value)
       FARM_THRESHOLD = Value
       saveConfig()
   end,
})

local DragBridgeToggle = MainTab:CreateToggle({
   Name = "Enable Drag Bridge Race",
   CurrentValue = dragBridgeEnabled,
   Flag = "DragBridgeFlag",
   Callback = function(Value)
       dragBridgeEnabled = Value
       saveConfig()
   end,
})

local AntiAFKToggle = MainTab:CreateToggle({
   Name = "Anti-AFK System",
   CurrentValue = AntiAFKEnabled,
   Flag = "AntiAFKFlag",
   Callback = function(Value)
       AntiAFKEnabled = Value
   end,
})

local BlackScreenToggle = MainTab:CreateToggle({
   Name = "Black Screen Mode (Battery Saver)",
   CurrentValue = false,
   Flag = "BlackScreenFlag",
   Callback = function(Value)
       local playerGui = Player:WaitForChild("PlayerGui")
       if Value then
           if blackGui and blackGui.Parent then return end
           blackGui = Instance.new("ScreenGui")
           blackGui.Name = "NZNT_BlackScreen_AutoDrive"
           blackGui.IgnoreGuiInset = true
           blackGui.ResetOnSpawn = false
           blackGui.Parent = playerGui
           local frame = Instance.new("Frame")
           frame.Size = UDim2.fromScale(1, 1)
           frame.BackgroundColor3 = Color3.new(0, 0, 0)
           frame.BorderSizePixel = 0
           frame.Parent = blackGui
       else
           if blackGui then blackGui:Destroy() blackGui = nil end
       end
   end,
})

-- [[ LABELS STATS DI RAYFIELD ]] --
local LabelStatus = StatsTab:CreateLabel("Status: Ready - Click START")
local LabelCurrentMoney = StatsTab:CreateLabel("Current Money: Rp. 0")
local LabelEarned = StatsTab:CreateLabel("Earned This Bike: Rp. 0")
local LabelMoneyHour = StatsTab:CreateLabel("Money / Hour: Calculating...")
local LabelElapsed = StatsTab:CreateLabel("Elapsed Time: 00:00:00")
local LabelRaces = StatsTab:CreateLabel("Drag Bridge Races: 0")
local LabelFPS = StatsTab:CreateLabel("FPS: 60 | Ping: 0 ms")

updateUIStatus = function(text)
    currentStatusText = text
    LabelStatus:Set("Status: " .. text)
end

local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 24

-- [[ WORKSPACE CLEANER ]] --
local function cleanWorkspace()
    local char = Player.Character or Player.CharacterAdded:Wait()
    local protectedDragRoot = findDragRace()
    if protectedDragRoot then pcall(function() protectedDragRoot.Parent = workspace end) end
    
    local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
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
    
    for _, obj in pairs(workspace:GetChildren()) do
        if obj ~= workspace.CurrentCamera and obj ~= char and obj ~= savedFloor and obj ~= protectedDragRoot and not obj:IsA("Terrain") then
            obj:Destroy()
        end
    end
    
    local oldWalls = savedFloor and savedFloor:FindFirstChild("NZNT_SAFETY_WALLS")
    if oldWalls then oldWalls:Destroy() end
    
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

-- [[ MAIN FARM CORE LOGIC ]] --
local function respawnVehicle(hum, statusText)
    if isRespawning then return end
    isRespawning = true; farmingActive = false
    unseatedSince = nil
    updateUIStatus(statusText or ("Reached " .. formatNumber(FARM_THRESHOLD) .. "! Respawning..."))
    
    stopVehicleCompletely()
    sendKey(Enum.KeyCode.Space); task.wait(0.5)
    cleanupPhysics()
    despawnVehicle(); task.wait(2)
    spawnVehicle(vehicleInput); task.wait(3)
    
    local seat = findClosestSeat()
    if not seat then updateUIStatus("No seat found!"); isRespawning = false; return end
    
    local char = Player.Character or Player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    root.CFrame = seat.CFrame * CFrame.new(0, 2, 0); task.wait(1)
    seat:Sit(hum); task.wait(1)
    
    currentVehicle = getVehicleRootFromSeat(seat)
    seatOffset = calculateSeatOffset(currentVehicle, seat)
    startMoney = getMoney(); startTime = os.time()
    unseatedSince = nil
    setupPhysics(seat)
    
    farmingActive = true; isRespawning = false; updateUIStatus("Farming!")
end

startFarming = function()
    if farmingActive then return end
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hum, root = char:WaitForChild("Humanoid"), char:WaitForChild("HumanoidRootPart")
    updateUIStatus("Joining...")
    
    local lce = RS:FindFirstChild("LoadCharacterEvent")
    if lce then
        lce:FireServer()
        char = Player.CharacterAdded:Wait()
        hum = char:WaitForChild("Humanoid"); root = char:WaitForChild("HumanoidRootPart")
        task.wait(1)
    end
    
    updateUIStatus("Spawning vehicle...")
    spawnVehicle(vehicleInput); task.wait(4)
    updateUIStatus("Finding seat...")
    
    local seat, attempts = nil, 0
    repeat 
        task.wait(0.5); attempts = attempts + 1; seat = findClosestSeat()
    until seat or attempts > 20
    
    if not seat then updateUIStatus("No seat found!"); return false end
    updateUIStatus("Sitting...")
    
    root.CFrame = seat.CFrame * CFrame.new(0, 2, 0); task.wait(0.5)
    seat:Sit(hum); task.wait(1)
    if hum.SeatPart ~= seat then updateUIStatus("Failed to sit!"); return false end
    
    pcall(function() blur:Destroy() end)
    currentVehicle = getVehicleRootFromSeat(seat)
    seatOffset = calculateSeatOffset(currentVehicle, seat)
    startMoney = getMoney(); startTime = os.time()
    sessionStartMoney = startMoney; sessionStartTime = os.time()
    sessionStart = os.time()
    unseatedSince = nil
    farmingActive = true; active = true
    setupPhysics(seat)
    
    updateUIStatus("Farming!")
    
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

stopFarming = function()
    if not farmingActive then return end
    if sessionStartTime and sessionStartMoney then
        local sessionElapsed = os.time() - sessionStartTime
        local sessionEarned = getMoney() - sessionStartMoney
        totalEarned = totalEarned + math.max(0, sessionEarned)
        totalTime = totalTime + sessionElapsed
        if writefile then writefile("nznt_stealth_stats.txt", tostring(totalEarned) .. "," .. tostring(totalTime)) end
    end
    
    farmingActive = false; active = false; updateUIStatus("Stopping...")
    dragBridgeRunning = false
    cleanupPhysics(); despawnVehicle()
    sessionStartTime = nil; sessionStartMoney = nil
    startTime = nil; startMoney = nil
    
    updateUIStatus("Stopped - Ready")
end

-- [[ LOOPS & THREADS MANAGEMENT ]] --
task.spawn(function()
    while true do
        task.wait(1)
        if not farmingActive or isRespawning then
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
            updateUIStatus("Not seated for 10s! Restarting...")
            if hum then
                respawnVehicle(hum, "Not seated for 10s! Respawning...")
            else
                farmingActive = false; active = false
                cleanupPhysics(); despawnVehicle()
                task.wait(1)
                startFarming()
            end
        end
    end
end)

-- [[ HEARTBEAT & RENDER UPDATES ]] --
task.spawn(function()
    while task.wait(0.5) do
        if not farmingActive or not startTime then continue end
        local money = getMoney()
        local earnedThisBike = startMoney and (money - startMoney) or 0
        local sessionElapsed = sessionStartTime and (os.time() - sessionStartTime) or 0
        local sessionEarned = sessionStartMoney and (money - sessionStartMoney) or 0
        local mph = sessionElapsed > 60 and math.floor((sessionEarned/sessionElapsed)*3600) or 0
        
        LabelCurrentMoney:Set("Current Money: Rp. " .. formatNumber(money))
        LabelEarned:Set("Earned This Bike: Rp. " .. formatNumber(math.max(0, earnedThisBike)))
        LabelMoneyHour:Set(sessionElapsed > 60 and ("Money / Hour: Rp. " .. formatNumber(mph) .. " /hr") or "Money / Hour: Calculating...")
        LabelElapsed:Set("Elapsed Time: " .. formatTime(os.time() - startTime))
        LabelRaces:Set("Drag Bridge Races: " .. tostring(dragBridgeRaceCount))
        LabelFPS:Set("FPS: " .. tostring(lastFPS) .. " | Ping: " .. getPing() .. " ms")
        
        local ct = totalEarned + sessionEarned
        local ctt = totalTime + sessionElapsed
        
        if sessionElapsed > 0 and sessionElapsed % 30 < 1 and writefile then
            writefile("nznt_stealth_stats.txt", tostring(ct) .. "," .. tostring(cttt))
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
    if not farmingActive or not force or not currentVehicle then return end
    local seat = currentVehicle:IsA("VehicleSeat") and currentVehicle or currentVehicle:FindFirstChildWhichIsA("VehicleSeat", true)
    if not seat then return end
    
    if dragBridgeRunning then
        zeroVehicleVelocity()
        return
    end
    
    if autoRejoinEnabled and rejoinInterval > 0 and os.time() - sessionStart >= rejoinInterval * 60 then
        updateUIStatus("Auto rejoining...")
        if not queueSelfOnTeleport(true) then
            updateUIStatus("Auto rejoin queue failed")
            return
        end
        farmingActive = false; active = false
        cleanupPhysics(); despawnVehicle()
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, Player)
        return
    end
    
    if startMoney and getMoney() - startMoney >= FARM_THRESHOLD and not isRespawning then
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then respawnVehicle(hum) return end
    end
    
    local groundRay = groundRaycast(seat.Position, math.max(25, seatOffset + 8))
    if not groundRay then
        updateUIStatus("In air! Respawning...")
        farmingActive = false; active = false
        cleanupPhysics(); despawnVehicle()
        
        for retry = 1, 5 do
            task.wait(1)
            spawnVehicle(vehicleInput); task.wait(3)
            local newSeat = findClosestSeat()
            if newSeat then
                local char = Player.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if hum and root then
                        root.CFrame = newSeat.CFrame * CFrame.new(0, 2, 0)
                        task.wait(0.5)
                        newSeat:Sit(hum); task.wait(1)
                        currentVehicle = getVehicleRootFromSeat(newSeat)
                        seatOffset = calculateSeatOffset(currentVehicle, newSeat)
                        startMoney = getMoney()
                        startTime = os.time()
                        if not sessionStartMoney then sessionStartMoney = startMoney end
                        setupPhysics(newSeat)
                        farmingActive = true; active = true
                        updateUIStatus("Farming!")
                        return
                    end
                end
            end
            updateUIStatus("Retry " .. retry .. "/5...")
        end
        updateUIStatus("Failed after 5 retries! Click START")
        return
    end
    
    local p = seat.Position
    if savedFloor then
        local localPos = savedFloor.CFrame:PointToObjectSpace(p)
        local limitX = savedFloor.Size.X / 2 - 80
        local limitZ = savedFloor.Size.Z / 2 - 80
        local clampedX = math.clamp(localPos.X, -limitX, limitX)
        local clampedZ = math.clamp(localPos.Z, -limitZ, limitZ)
        
        if math.abs(clampedX - localPos.X) > 0.1 or math.abs(clampedZ - localPos.Z) > 0.1 then
            direction = direction * -1
            lastDirChange = tick()
            local clampedWorld = savedFloor.CFrame:PointToWorldSpace(Vector3.new(clampedX, localPos.Y, clampedZ))
            local _, clampYaw = seat.CFrame:ToEulerAnglesYXZ()
            seat.CFrame = CFrame.new(clampedWorld.X, p.Y, clampedWorld.Z) * CFrame.Angles(0, clampYaw, 0)
            p = seat.Position
            zeroVehicleVelocity()
        end
    end
    
    local _, ry = seat.CFrame:ToEulerAnglesYXZ()
    local targetCFrame = CFrame.new(p.X, groundRay.Position.Y + seatOffset, p.Z) * CFrame.Angles(0, ry, 0)
    seat.CFrame = targetCFrame
    if gyro then
        gyro.CFrame = CFrame.new(p.X, groundRay.Position.Y + seatOffset, p.Z) * CFrame.Angles(0, ry, 0)
    end
    
    local rayOrigin = (seat.CFrame * CFrame.new(0, 0, -CHECK_DISTANCE * direction)).p
    local hit = groundRaycast(rayOrigin, 30)
    if not hit then
        local now = tick()
        if now - lastDirChange >= DIR_COOLDOWN then
            direction = direction * -1
            lastDirChange = now
            for _, part in ipairs(currentVehicle:GetDescendants()) do
                if part:IsA("BasePart") then part.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
            end
            if seat:IsA("BasePart") then seat.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
        end
    end
    
    local chosenSpeed = safeNumber(SPEED, 200, MIN_SPEED, MAX_SPEED)
    SPEED = chosenSpeed
    force.VectorVelocity = Vector3.new(0, 0, -chosenSpeed * direction)
    local desiredWorld = -seat.CFrame.LookVector * chosenSpeed * direction
    local vertical = math.clamp(seat.AssemblyLinearVelocity.Y, -2, 2)
    seat.AssemblyLinearVelocity = Vector3.new(desiredWorld.X, vertical, desiredWorld.Z)
end)

-- [[ INITIAL EXECUTIVE STARTUP ]] --
task.spawn(function()
    task.wait(2)
    cleanWorkspace()
    pcall(function() blur:Destroy() end)
    updateUIStatus("Auto starting...")
    if getgenv and getgenv().NZNT_AUTODRIVE_AUTO_START then
        getgenv().NZNT_AUTODRIVE_AUTO_START = false
    end
    task.wait(1)
    -- Mengaktifkan toggle secara visual di Rayfield
    ToggleFarm:Set(true)
end)

print("✅ Stealth Farm Loaded - Successfully Integrated to Rayfield UI")

local isRestarting = false
Player.CharacterAdded:Connect(function()
    if isRestarting then return end
    isRestarting = true
    farmingActive = false; active = false; isRespawning = false
    cleanupPhysics(); task.wait(2)
    if not isRestarting then return end
    
    updateUIStatus("Respawned - Restarting...")
    ToggleFarm:Set(true)
    isRestarting = false
end)
