local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name             = ".projectsion",
    LoadingTitle     = "Bus Explorer Indonesia",
    LoadingSubtitle  = "by .projectsion",
    Theme            = "Bloom",
    ConfigurationSaving = {
        Enabled  = true,
        FileName = "VoidlineConfig"
    },
    KeySystem = false,
})

-- ── services ──────────────────────────────────────────────────────────────
local VirtualUser       = game:GetService("VirtualUser")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")

local LP                = Players.LocalPlayer
local Remotes           = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local StatsFolder       = LP:WaitForChild("PlayerData")
local OwnedCarsFolder   = StatsFolder:WaitForChild("OwnedCars")
local CarData           = Remotes.GetClientCustomizationData:InvokeServer()
local StartUang         = StatsFolder.Uang.Value
local StartTime         = os.time()

-- ── globals ───────────────────────────────────────────────────────────────
_G.AutoFull        = false
_G.AntiAFK         = true
_G.AutoRejoin      = false
_G.blackscreen     = false
_G.HideChar        = false
_G.SelectedBus     = ""
_G.WebhookURL      = ""
_G.TotalEarning    = 0
_G.CycleCount      = 0
_G.StartTime       = os.time()
_G.AutoKickEnabled = false
_G.WebhookEnabled  = false

-- ── tunables ──────────────────────────────────────────────────────────────
local TWEEN_SPEED      = 100
local ARRIVE_DELAY     = 60
local INCOME_THRESHOLD = 30_000_000

-- ── state ─────────────────────────────────────────────────────────────────
local isWaitingInZone      = false
local jobStarted           = false
local TargetUang           = 0
local lastMoney            = StatsFolder.Uang.Value
local SelectedBusToBuy     = ""
local CarListData          = {}
local pendingIncome        = 0
local SelectedAction       = "Dealership"
local SelectedTP           = "Dealership"
local isWebhookRunning     = false
local busOptions           = {}
local isCycleResetting     = false
local lockedRootPart       = nil

-- ── recovery state ────────────────────────────────────────────────────────
local lastCheckpointName   = ""
local lastCheckpointFolder = "Checkpoints"
local isRecovering         = false

-- ── route state ───────────────────────────────────────────────────────────
local RouteData        = {}
local RouteSortedKeys  = {}
local SelectedRouteKey = ""
local LabelToKey       = {}

local StatusLabel, UangLabel, EarningLabel, TimeLabel, FPSLabel, PingLabel
local RouteRewardLabel

-- ── terminal registry ─────────────────────────────────────────────────────
local TERMINALS = {
    {
        id    = "Baranangsiang",
        spawn = CFrame.new(0, 0, 0),
        useTP = false,
    },
    {
        id    = "Cirebon",
        spawn = CFrame.new(-26455.625, -216.685, 33480.039,
                           -0.744, -0.147, -0.651,
                            0.000,  0.975, -0.221,
                            0.668, -0.165, -0.726),
        useTP = true,
    },
}

local function getTerminalForKey(key)
    local info = RouteData[key]
    if not info then return TERMINALS[1] end
    for _, t in ipairs(TERMINALS) do
        if t.id == info.Terminal then return t end
    end
    return TERMINALS[1]
end

-- ── blackscreen ───────────────────────────────────────────────────────────
local BlackScreen        = Instance.new("ScreenGui")
BlackScreen.Name         = "ProjectsionBlackout"
BlackScreen.Parent       = game:GetService("CoreGui")
BlackScreen.DisplayOrder = -1
BlackScreen.Enabled      = false

local BSFrame            = Instance.new("Frame")
BSFrame.Parent           = BlackScreen
BSFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BSFrame.Size             = UDim2.new(1.5, 0, 1.5, 0)
BSFrame.Position         = UDim2.new(-0.25, 0, -0.25, 0)
BSFrame.BorderSizePixel  = 0

task.spawn(function()
    while task.wait(0.5) do
        BlackScreen.Enabled = _G.blackscreen
    end
end)

-- ── anti-afk ─────────────────────────────────────────────────────────────
for _, c in getconnections(LP.Idled) do
    pcall(c.Disable, c)
    pcall(c.Disconnect, c)
end

LP.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end
end)

-- ── auto kick intruders ───────────────────────────────────────────────────
local function checkAndKick()
    local playerList = Players:GetPlayers()
    if #playerList > 1 then
        local names = {}
        for _, p in ipairs(playerList) do
            if p ~= LP then table.insert(names, p.Name) end
        end
        LP:Kick("admim mesum joim private server lu woi aowkaowk: " .. table.concat(names, ", "))
    end
end

Players.PlayerAdded:Connect(function(p)
    if p == LP then return end
    task.wait(0.5)
    checkAndKick()
end)

task.spawn(function()
    while true do task.wait(3) checkAndKick() end
end)

-- ── format helpers ────────────────────────────────────────────────────────
local function formatRS(amount)
    local f = tostring(math.floor(amount))
    local k
    while true do
        f, k = string.gsub(f, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return f
end

local function formatRP(v) return "Rp " .. formatRS(v) end

local function getRunningTime()
    local diff = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d",
        math.floor(diff/3600), math.floor((diff%3600)/60), diff%60)
end

local function SetStatus(text)
    if StatusLabel then StatusLabel:Set("Status: " .. text) end
end

-- ── unlock helper ─────────────────────────────────────────────────────────
local function unlockVehicle()
    if lockedRootPart and lockedRootPart.Parent then
        lockedRootPart.Anchored                = false
        lockedRootPart.AssemblyLinearVelocity  = Vector3.zero
        lockedRootPart.AssemblyAngularVelocity = Vector3.zero
    end
    lockedRootPart = nil
end

-- ── bus list ──────────────────────────────────────────────────────────────
for _, car in pairs(OwnedCarsFolder:GetChildren()) do
    local carID   = car.Name
    local carInfo = CarData and CarData.CarData_Cars and CarData.CarData_Cars[carID]
    if carInfo then table.insert(busOptions, carID) end
end
if #busOptions == 0 then table.insert(busOptions, "Jetbus_3_RM _SHD") end
_G.SelectedBus = busOptions[1]

local ClientData = Remotes.GetClientCustomizationData:InvokeServer()
if ClientData and ClientData.CarData_Cars then
    for carID in pairs(ClientData.CarData_Cars) do
        table.insert(CarListData, carID)
    end
    table.sort(CarListData)
end

-- ── TP locations ──────────────────────────────────────────────────────────
local TP_Locations = {
    ["Dealership"]    = CFrame.new(19830.625,  266.913116,  -27910.4844,  0.999847949, 0,  0.017436387, 0, 1, 0, -0.017436387, 0,  0.999847949),
    ["Modifikasi"]    = CFrame.new(12035.499,  -21.3362789,  12740.0605, -0.573599219, 0,  0.81913656,  0, 1, 0, -0.81913656,  0, -0.573599219),
    ["Teleport City"] = CFrame.new(21795.2461, 292.439026,  -40055.918,   0.707134247, 0, -0.707079291, 0, 1, 0,  0.707079291, 0,  0.707134247),
}

-- ══════════════════════════════════════════════════════════════════════════
-- ROUTE FETCH + SORT
-- ══════════════════════════════════════════════════════════════════════════
local function buildLabelForKey(key)
    local info = RouteData[key]
    if not info then return key end
    return (info.DisplayName or key)
        .. "  |  " .. formatRP(info.Reward or 0)
        .. "  (" .. tostring(info.TotalCheckpoints or "?") .. " CP)"
        .. "  [" .. (info.Terminal or "?") .. "]"
end

local function fetchRoutes()
    RouteData       = {}
    RouteSortedKeys = {}
    LabelToKey      = {}

    local anyLoaded = false

    for _, terminal in ipairs(TERMINALS) do
        local ok, result = pcall(function()
            return Remotes:WaitForChild("GetAvailableBusRoutes"):InvokeServer(terminal.id)
        end)
        if ok and type(result) == "table" then
            anyLoaded = true
            for key, info in pairs(result) do
                info.Terminal  = terminal.id
                RouteData[key] = info
                table.insert(RouteSortedKeys, key)
            end
        end
    end

    if not anyLoaded then return false end

    table.sort(RouteSortedKeys, function(a, b)
        return (RouteData[a].Reward or 0) > (RouteData[b].Reward or 0)
    end)

    if SelectedRouteKey == "" and #RouteSortedKeys > 0 then
        SelectedRouteKey = RouteSortedKeys[1]
    end

    for _, key in ipairs(RouteSortedKeys) do
        LabelToKey[buildLabelForKey(key)] = key
    end

    return true
end

local function buildRouteOptions()
    local opts = {}
    for _, key in ipairs(RouteSortedKeys) do
        table.insert(opts, buildLabelForKey(key))
    end
    return opts
end

fetchRoutes()

-- ══════════════════════════════════════════════════════════════════════════
-- PREPARE VEHICLE
-- ══════════════════════════════════════════════════════════════════════════
local function prepareVehicle()
    Remotes.SpawnCar:FireServer(_G.SelectedBus)
    task.wait(2)

    local spawnedFolder = workspace:FindFirstChild("SpawnedVehicles")
    if not spawnedFolder then return end

    local bus = nil
    for _, veh in ipairs(spawnedFolder:GetChildren()) do
        local ownerAttr = veh:GetAttribute("Owner")
        local ownerVal  = veh:FindFirstChild("Owner")
        if (ownerAttr and tostring(ownerAttr) == LP.Name)
        or (ownerVal  and tostring(ownerVal.Value) == LP.Name)
        or veh.Name:find(LP.Name) then
            bus = veh
            break
        end
    end

    if not bus then
        local vehicles = spawnedFolder:GetChildren()
        bus = vehicles[#vehicles]
    end

    if not bus then return end

    local seat = bus:FindFirstChild("DriveSeat", true)
    if seat then
        local char = LP.Character or LP.CharacterAdded:Wait()
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
        end
        task.wait(0.3)
        local prompt = seat:FindFirstChildWhichIsA("ProximityPrompt", true)
                    or bus:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- moveTo
-- ══════════════════════════════════════════════════════════════════════════
local function getPart(name, folderName)
    local folder = workspace:WaitForChild(folderName, 5)
    if not folder then return nil end
    local part = folder:FindFirstChild(name, true)
    if not part then
        task.wait(0.3)
        part = folder:FindFirstChild(name, true)
    end
    return part
end

local function moveTo(targetPart)
    if not targetPart then return end

    unlockVehicle()

    local char = LP.Character or LP.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local targetModel = char

    if hum and hum.SeatPart then
        local veh = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if veh then targetModel = veh end
    end

    local rootPart = targetModel.PrimaryPart or targetModel:FindFirstChildWhichIsA("BasePart")
    if not rootPart then return end

    local startCFrame  = targetModel:GetPivot()
    local targetCFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
    local distance     = (targetCFrame.Position - startCFrame.Position).Magnitude
    local duration     = math.max(distance / TWEEN_SPEED, 0.1)

    local originalCollisions = {}
    for _, p in ipairs(targetModel:GetDescendants()) do
        if p:IsA("BasePart") then
            originalCollisions[p] = p.CanCollide
        end
    end

    rootPart.Anchored = true

    local noclipConn = RunService.Stepped:Connect(function()
        for p in pairs(originalCollisions) do
            if p and p.Parent then
                p.CanCollide              = false
                p.AssemblyLinearVelocity  = Vector3.zero
                p.AssemblyAngularVelocity = Vector3.zero
            end
        end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end)

    local elapsed = 0
    while elapsed < duration do
        if not _G.AutoFull then break end
        local dt = RunService.Heartbeat:Wait()
        elapsed  = elapsed + dt
        local alpha = math.min(elapsed / duration, 1)
        targetModel:PivotTo(startCFrame:Lerp(targetCFrame, alpha))
    end

    targetModel:PivotTo(targetCFrame)
    noclipConn:Disconnect()

    for p, cc in pairs(originalCollisions) do
        if p and p.Parent then
            p.CanCollide              = cc
            p.AssemblyLinearVelocity  = Vector3.zero
            p.AssemblyAngularVelocity = Vector3.zero
        end
    end

    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            p.CanCollide = true
        end
    end

    task.wait(0.8)
    if not isWaitingInZone then
        targetModel:PivotTo(targetPart.CFrame + Vector3.new(0, 3, 0))
        task.wait(0.2)
    end

    rootPart.Anchored                = false
    rootPart.AssemblyLinearVelocity  = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.25)

    rootPart.Anchored                = true
    rootPart.AssemblyLinearVelocity  = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    lockedRootPart = rootPart
end

-- ══════════════════════════════════════════════════════════════════════════
-- START JOB
-- ══════════════════════════════════════════════════════════════════════════
local function startJob()
    if jobStarted then return end
    if SelectedRouteKey == "" then
        SetStatus("No route selected.")
        return
    end

    local terminal = getTerminalForKey(SelectedRouteKey)

    if terminal.useTP then
        SetStatus("Teleporting to terminal " .. terminal.id .. "...")
        local char = LP.Character or LP.CharacterAdded:Wait()
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = terminal.spawn
        end
        task.wait(1.5)
        if not _G.AutoFull then return end
    end

    SetStatus("Preparing vehicle...")
    prepareVehicle()
    task.wait(2)

    if not _G.AutoFull then return end

    SetStatus("Invoke job: " .. SelectedRouteKey)
    local res = Remotes:WaitForChild("StartBusJob"):InvokeServer(SelectedRouteKey, nil)

    if type(res) == "table" and res.success and res.nextCheckpointPartName then
        jobStarted           = true
        lastCheckpointName   = res.nextCheckpointPartName
        lastCheckpointFolder = "Checkpoints"
        SetStatus("Job started — moving to first checkpoint...")
        local part = getPart(res.nextCheckpointPartName, "Checkpoints")
        if part then moveTo(part) end
    else
        SetStatus("Job invoke failed, retrying...")
        task.wait(2)
        if _G.AutoFull then startJob() end
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- CYCLE RESET  ← PATCHED
-- ══════════════════════════════════════════════════════════════════════════
local function doCycleReset()
    if isCycleResetting then return end
    isCycleResetting   = true
    isWaitingInZone    = false
    jobStarted         = false
    lastCheckpointName = ""

    unlockVehicle()

    SetStatus("Income detected — resetting character...")

    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = 0
    end

    LP.CharacterAdded:Wait()
    task.wait(5)

    if not _G.AutoFull then
        isCycleResetting = false
        return
    end

    -- ── TP balik ke terminal kalau rute dari Cirebon (useTP == true) ──────
    local terminal = getTerminalForKey(SelectedRouteKey)
    if terminal and terminal.useTP then
        SetStatus("Waiting before teleport to " .. terminal.id .. "...")
        task.wait(7)

        if not _G.AutoFull then
            isCycleResetting = false
            return
        end

        SetStatus("Teleporting to " .. terminal.id .. "...")
        local char = LP.Character or LP.CharacterAdded:Wait()
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = terminal.spawn
        end
        task.wait(1.5)

        if not _G.AutoFull then
            isCycleResetting = false
            return
        end
    end

    SetStatus("Character ready — starting next cycle...")
    isCycleResetting = false
    startJob()
end

-- ── detect uang masuk → trigger cycle reset ───────────────────────────────
StatsFolder.Uang:GetPropertyChangedSignal("Value"):Connect(function()
    local newMoney = StatsFolder.Uang.Value
    if newMoney > lastMoney then
        local income = newMoney - lastMoney
        pendingIncome = pendingIncome + income

        if not isWebhookRunning and _G.WebhookURL ~= "" and _G.WebhookEnabled then
            isWebhookRunning = true
            task.spawn(function()
                while isWebhookRunning do
                    task.wait(65)
                    if pendingIncome > 0 and _G.WebhookURL ~= "" and _G.WebhookEnabled then
                        pendingIncome = 0
                    end
                    if not _G.AutoFull then isWebhookRunning = false end
                end
            end)
        end

        if _G.AutoFull and not isCycleResetting and income >= INCOME_THRESHOLD then
            task.spawn(doCycleReset)
        end
    end
    lastMoney = newMoney
end)

-- ══════════════════════════════════════════════════════════════════════════
-- CHECKPOINT RECOVERY MONITOR
-- ══════════════════════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(0.5) do
        if not _G.AutoFull or isRecovering or isCycleResetting then continue end
        if lastCheckpointName == "" then continue end

        local detected = false
        pcall(function()
            for _, sg in ipairs(LP.PlayerGui:GetChildren()) do
                for _, label in ipairs(sg:GetDescendants()) do
                    if label:IsA("TextLabel") or label:IsA("TextButton") then
                        if string.find(string.upper(label.Text), "RETURN TO THE CHECKPOINT") then
                            detected = true
                            break
                        end
                    end
                end
                if detected then break end
            end
        end)

        if detected then
            isRecovering = true
            SetStatus("Off-track — recovering to checkpoint...")
            local part = getPart(lastCheckpointName, lastCheckpointFolder)
            if part then moveTo(part) end
            task.wait(1)
            isRecovering = false
            SetStatus("Recovered — continuing...")
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════════
-- BusJobUpdate handler
-- ══════════════════════════════════════════════════════════════════════════
Remotes:WaitForChild("BusJobUpdate").OnClientEvent:Connect(function(action, data)
    if not _G.AutoFull then return end

    if action == "StartCheckpointWait" then
        isWaitingInZone = true
        SetStatus("Waiting in zone...")
        return
    end

    if action == "JobSuccess" or action == "JobCancelled" then
        isWaitingInZone    = false
        jobStarted         = false
        lastCheckpointName = ""
        SetStatus(action == "JobSuccess" and "Job success! Restarting..." or "Cancelled. Restarting...")
        task.wait(1)
        if _G.AutoFull then startJob() end
        return
    end

    if type(data) ~= "table" then return end

    local isFinal    = (action == "FinalDestination" or data.isFinalDestination)
    local targetName = isFinal and data.endTriggerPartName
                    or (data.nextCheckpointPartName or data.checkpointPartName)
    local folder     = isFinal and "BusJobEndTriggers" or "Checkpoints"

    if targetName then
        lastCheckpointName   = targetName
        lastCheckpointFolder = folder

        task.spawn(function()
            isWaitingInZone = false

            if isFinal then
                local waitStart = os.clock()
                while _G.AutoFull do
                    local remaining = ARRIVE_DELAY - (os.clock() - waitStart)
                    if remaining <= 0 then break end
                    local secs = math.floor(remaining)
                    local ms   = math.floor((remaining - secs) * 1000)
                    SetStatus(string.format("Arrive in: %02d:%03d", secs, ms))
                    task.wait(0.05)
                end
                if not _G.AutoFull then return end

                SetStatus("Moving to final stop...")
                local part = getPart(targetName, folder)
                if part then moveTo(part) end

                task.wait(1.5)
                if _G.AutoFull and not isCycleResetting and not jobStarted then
                    isWaitingInZone    = false
                    jobStarted         = false
                    lastCheckpointName = ""
                    SetStatus("Cycle done — restarting...")
                    startJob()
                end
            else
                SetStatus("Moving to: " .. targetName)
                local part = getPart(targetName, folder)
                if part then moveTo(part) end
            end
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════════════════
-- WEBHOOK
-- ══════════════════════════════════════════════════════════════════════════
local function getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png"
end

local function sendWebhook(income)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    _G.CycleCount   = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income

    local http_request = request or http_request
        or (syn and syn.request) or (fluxus and fluxus.request)

    local routeDisplay = (RouteData[SelectedRouteKey] and RouteData[SelectedRouteKey].DisplayName)
                      or SelectedRouteKey

    local embed = {
        ["author"] = { ["name"] = "Projectsion Webhook", ["icon_url"] = getAvatar() },
        ["title"]  = "Bus Route Completed",
        ["color"]  = 0xFFFFFF,
        ["fields"] = {
            { ["name"] = "Player",        ["value"] = LP.Name,                          ["inline"] = false },
            { ["name"] = "Cycle Income",  ["value"] = formatRP(income),                 ["inline"] = false },
            { ["name"] = "Route",         ["value"] = routeDisplay,                     ["inline"] = false },
            { ["name"] = "Current Money", ["value"] = formatRP(StatsFolder.Uang.Value), ["inline"] = false },
            { ["name"] = "Total Earning", ["value"] = formatRP(_G.TotalEarning),        ["inline"] = false },
            { ["name"] = "Cycle Count",   ["value"] = tostring(_G.CycleCount),          ["inline"] = false },
            { ["name"] = "Running Time",  ["value"] = getRunningTime(),                 ["inline"] = false },
        },
        ["footer"] = { ["text"] = "Made By Projectsion | " .. os.date("%m/%d/%Y %I:%M %p") }
    }

    local payload = HttpService:JSONEncode({
        ["username"] = "Projectsion Reports",
        ["embeds"]   = { embed }
    })

    if http_request then
        pcall(function()
            http_request({ Url = _G.WebhookURL, Method = "POST",
                Headers = { ["Content-Type"] = "application/json" }, Body = payload })
        end)
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- STATS LOOP
-- ══════════════════════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(1) do
        if UangLabel then
            pcall(function()
                local cur = StatsFolder.Uang.Value
                UangLabel:Set("Uang: Rp " .. formatRS(cur))
                EarningLabel:Set("Earning: Rp " .. formatRS(cur - StartUang))
                local diff = os.time() - StartTime
                TimeLabel:Set(string.format("Time: %02d:%02d:%02d",
                    math.floor(diff/3600), math.floor((diff%3600)/60), diff%60))
                local ping = tonumber(
                    game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
                        :GetValueString():split(" ")[1]) or 0
                PingLabel:Set("Ping: " .. math.floor(ping) .. " ms")
                FPSLabel:Set("FPS: " .. math.floor(1 / task.wait()))
            end)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════════
-- UI — MAIN TAB
-- ══════════════════════════════════════════════════════════════════════════
local MainTab = Window:CreateTab("Main Farm", "play")
MainTab:CreateSection("Autofarm Bus")

MainTab:CreateParagraph({
    Title   = "WARNING",
    Content = "USE JB5 ONLY. Turn on Auto-Kick when staff joins.",
})

MainTab:CreateToggle({
    Name         = "On Autofarm",
    CurrentValue = false,
    Callback     = function(Value)
        _G.AutoFull = Value
        if Value then
            isWaitingInZone  = false
            jobStarted       = false
            isCycleResetting = false
            task.spawn(startJob)
        else
            unlockVehicle()
            isWaitingInZone    = false
            jobStarted         = false
            isCycleResetting   = false
            lastCheckpointName = ""
            SetStatus("Idle")
        end
    end,
})

MainTab:CreateSlider({
    Name         = "Move Speed (studs/s)",
    Range        = { 50, 500 },
    Increment    = 10,
    CurrentValue = TWEEN_SPEED,
    Flag         = "TweenSpeed",
    Callback     = function(Value) TWEEN_SPEED = Value end,
})

MainTab:CreateSlider({
    Name         = "Arrive Delay (seconds)",
    Range        = { 5, 120 },
    Increment    = 5,
    CurrentValue = ARRIVE_DELAY,
    Flag         = "ArriveDelay",
    Callback     = function(Value) ARRIVE_DELAY = Value end,
})

MainTab:CreateToggle({
    Name         = "Black Screen",
    CurrentValue = false,
    Flag         = "BlackScreen",
    Callback     = function(Value) _G.blackscreen = Value end,
})

MainTab:CreateSection("Auto Stop Settings")

MainTab:CreateInput({
    Name                     = "Set Target Money",
    PlaceholderText          = "input your target",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local cleanNumber = Text:gsub("%.", "")
        TargetUang = tonumber(cleanNumber) or 0
        Rayfield:Notify({
            Title    = "Target Set",
            Content  = "Target: Rp " .. formatRS(TargetUang),
            Duration = 3,
        })
    end,
})

MainTab:CreateToggle({
    Name         = "Enable Auto-Kick on Target",
    CurrentValue = false,
    Flag         = "AutoKick",
    Callback     = function(Value)
        _G.AutoKickEnabled = Value
        if Value then
            task.spawn(function()
                while _G.AutoKickEnabled do
                    if TargetUang > 0 and StatsFolder.Uang.Value >= TargetUang then
                        LP:Kick("\n[Projectsion]\nTarget reached!\nTotal: Rp " .. formatRS(StatsFolder.Uang.Value))
                        break
                    end
                    task.wait(2)
                end
            end)
        end
    end,
})

-- ══════════════════════════════════════════════════════════════════════════
-- UI — ROUTE TAB
-- ══════════════════════════════════════════════════════════════════════════
local RouteTab = Window:CreateTab("Routes", "map-pin")
RouteTab:CreateSection("Select Bus Route")

RouteTab:CreateParagraph({
    Title   = "Route Info",
    Content = "Routes sorted by reward (highest first). Terminal shown in brackets. Refresh to reload all terminals.",
})

local routeOpts    = buildRouteOptions()
local defaultLabel = routeOpts[1] or "No routes loaded"

local RouteDropdown = RouteTab:CreateDropdown({
    Name            = "Available Routes",
    Options         = routeOpts,
    CurrentOption   = { defaultLabel },
    MultipleOptions = false,
    Callback        = function(Option)
        local label = Option[1]
        local key   = LabelToKey[label]
        if key then
            SelectedRouteKey = key
            local info = RouteData[key]
            if RouteRewardLabel then
                RouteRewardLabel:Set(
                    "Selected: " .. (info.DisplayName or key)
                    .. "  |  Reward: " .. formatRP(info.Reward or 0)
                    .. "  |  " .. tostring(info.TotalCheckpoints or "?") .. " checkpoints"
                    .. "  [" .. (info.Terminal or "?") .. "]"
                )
            end
            SetStatus("Route: " .. (info.DisplayName or key))
            Rayfield:Notify({
                Title    = "Route Selected",
                Content  = (info.DisplayName or key)
                        .. "\nReward: " .. formatRP(info.Reward or 0)
                        .. "\nCheckpoints: " .. tostring(info.TotalCheckpoints or "?")
                        .. "\nTerminal: " .. (info.Terminal or "?"),
                Duration = 4,
                Image    = "map-pin",
            })
        end
    end,
})

RouteRewardLabel = RouteTab:CreateLabel(
    #RouteSortedKeys > 0
        and ("Selected: "
            .. (RouteData[SelectedRouteKey] and RouteData[SelectedRouteKey].DisplayName or SelectedRouteKey)
            .. "  |  Reward: " .. formatRP(RouteData[SelectedRouteKey] and RouteData[SelectedRouteKey].Reward or 0)
            .. "  |  " .. tostring(RouteData[SelectedRouteKey] and RouteData[SelectedRouteKey].TotalCheckpoints or "?") .. " checkpoints"
            .. "  [" .. (RouteData[SelectedRouteKey] and RouteData[SelectedRouteKey].Terminal or "?") .. "]")
        or "No route loaded.",
    "coins"
)

RouteTab:CreateButton({
    Name     = "Refresh Route List",
    Callback = function()
        if fetchRoutes() then
            local newOpts = buildRouteOptions()
            RouteDropdown:Set(newOpts)
            if RouteRewardLabel and SelectedRouteKey ~= "" and RouteData[SelectedRouteKey] then
                local info = RouteData[SelectedRouteKey]
                RouteRewardLabel:Set(
                    "Selected: " .. (info.DisplayName or SelectedRouteKey)
                    .. "  |  Reward: " .. formatRP(info.Reward or 0)
                    .. "  |  " .. tostring(info.TotalCheckpoints or "?") .. " checkpoints"
                    .. "  [" .. (info.Terminal or "?") .. "]"
                )
            end
            Rayfield:Notify({
                Title    = "Routes Refreshed",
                Content  = tostring(#RouteSortedKeys) .. " routes loaded from all terminals.",
                Duration = 3,
                Image    = "refresh-cw",
            })
        else
            Rayfield:Notify({
                Title    = "Fetch Failed",
                Content  = "Could not reach GetAvailableBusRoutes.",
                Duration = 4,
                Image    = "alert-triangle",
            })
        end
    end,
})

-- ══════════════════════════════════════════════════════════════════════════
-- UI — CONFIGURATION TAB
-- ══════════════════════════════════════════════════════════════════════════
local ConfigTab = Window:CreateTab("Configuration", "settings")
ConfigTab:CreateSection("Select Vehicle")

local BusDropdown = ConfigTab:CreateDropdown({
    Name            = "Select Owned Bus",
    Options         = busOptions,
    CurrentOption   = { busOptions[1] },
    MultipleOptions = false,
    Callback        = function(Option)
        _G.SelectedBus = Option[1]
        SetStatus("Selected: " .. _G.SelectedBus)
    end,
})

ConfigTab:CreateButton({
    Name     = "Refresh Garage List",
    Callback = function()
        local newOptions = {}
        for _, car in pairs(OwnedCarsFolder:GetChildren()) do
            table.insert(newOptions, car.Name)
        end
        BusDropdown:Set(newOptions)
    end,
})

ConfigTab:CreateSection("Webhook")

ConfigTab:CreateInput({
    Name                     = "Discord Webhook URL",
    PlaceholderText          = "Paste URL Here",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        _G.WebhookURL = Text
        Rayfield:Notify({ Title = "Webhook Updated", Content = "URL saved.", Duration = 3, Image = "link" })
    end,
})

ConfigTab:CreateToggle({
    Name         = "Enable Webhook Report",
    CurrentValue = false,
    Callback     = function(Value)
        _G.WebhookEnabled = Value
        if Value and (_G.WebhookURL == "" or not _G.WebhookURL:find("discord.com")) then
            Rayfield:Notify({
                Title    = "Webhook Error",
                Content  = "Enter a valid Discord Webhook URL first!",
                Duration = 5,
                Image    = "alert-triangle",
            })
        end
    end,
})

-- ══════════════════════════════════════════════════════════════════════════
-- UI — STATS TAB
-- ══════════════════════════════════════════════════════════════════════════
local StatsTab = Window:CreateTab("Stats", "trending-up")
StatsTab:CreateSection("Info Farm")
StatusLabel  = StatsTab:CreateLabel("Status: Waiting",                    "clock")
UangLabel    = StatsTab:CreateLabel("Uang: Rp " .. formatRS(StartUang),   "banknote")
EarningLabel = StatsTab:CreateLabel("Earning: Rp 0",                      "coins")
TimeLabel    = StatsTab:CreateLabel("Time: 00:00:00",                      "timer")

StatsTab:CreateSection("System Info")
FPSLabel  = StatsTab:CreateLabel("FPS: Scanning...",  "monitor")
PingLabel = StatsTab:CreateLabel("Ping: Scanning...", "wifi")

-- ══════════════════════════════════════════════════════════════════════════
-- UI — MORE FEATURES TAB
-- ══════════════════════════════════════════════════════════════════════════
local MoreTab = Window:CreateTab("More Features", "plus-circle")
MoreTab:CreateSection("Important Features")

MoreTab:CreateToggle({
    Name         = "Anti-AFK System",
    CurrentValue = true,
    Flag         = "AntiAFK",
    Callback     = function(Value)
        _G.AntiAFK = Value
        SetStatus(_G.AntiAFK and "Anti-AFK Enabled" or "Anti-AFK Disabled")
    end,
})

MoreTab:CreateToggle({
    Name         = "Auto Rejoin",
    CurrentValue = false,
    Flag         = "AutoRejoin",
    Callback     = function(Value) _G.AutoRejoin = Value end,
})

MoreTab:CreateSection("Visual & Performance")

MoreTab:CreateButton({
    Name     = "Hide All Names",
    Callback = function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BillboardGui") then v:Destroy() end
        end
        SetStatus("Names Hidden")
    end,
})

MoreTab:CreateToggle({
    Name         = "Hide Character",
    CurrentValue = false,
    Flag         = "HideChar",
    Callback     = function(Value)
        local char = LP.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    part.Transparency = Value and 1 or 0
                end
            end
        end
    end,
})

MoreTab:CreateButton({
    Name     = "FPS Boost",
    Callback = function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            end
        end
        SetStatus("FPS Boosted")
    end,
})

MoreTab:CreateSection("Auto Buy Bus")

MoreTab:CreateDropdown({
    Name            = "Select Bus to Purchase",
    Options         = CarListData,
    CurrentOption   = { CarListData[1] or "None" },
    MultipleOptions = false,
    Callback        = function(Option) SelectedBusToBuy = Option[1] end,
})

MoreTab:CreateButton({
    Name     = "Purchase Selected Bus",
    Callback = function()
        if SelectedBusToBuy == "" or SelectedBusToBuy == "None" then
            Rayfield:Notify({ Title = "Error", Content = "Select a bus first!", Duration = 3 })
            return
        end
        local success, err = pcall(function()
            Remotes:WaitForChild("BuyCar"):FireServer(SelectedBusToBuy)
        end)
        SetStatus(success and ("Bought: " .. SelectedBusToBuy) or "Purchase Failed!")
        if not success then warn("Purchase error: " .. tostring(err)) end
    end,
})

MoreTab:CreateSection("World Teleport")

MoreTab:CreateDropdown({
    Name            = "Select TP Destination",
    Options         = { "Dealership", "Modifikasi", "Teleport City" },
    CurrentOption   = { "Dealership" },
    MultipleOptions = false,
    Callback        = function(Option) SelectedTP = Option[1] end,
})

MoreTab:CreateButton({
    Name     = "Teleport Now",
    Callback = function()
        local targetCF = TP_Locations[SelectedTP]
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character:PivotTo(targetCF)
            SetStatus("Teleported to " .. SelectedTP)
        end
    end,
})

MoreTab:CreateSection("Open UI / Actions")

MoreTab:CreateDropdown({
    Name            = "Select Menu to Open",
    Options         = { "Dealership", "Modifikasi", "Teleport City" },
    CurrentOption   = { "Dealership" },
    MultipleOptions = false,
    Callback        = function(Option) SelectedAction = Option[1] end,
})

MoreTab:CreateButton({
    Name     = "Open Selected Menu",
    Callback = function()
        if SelectedAction == "Dealership" then
            local p = workspace:FindFirstChild("BigBus_DealershipPart")
                   and workspace.BigBus_DealershipPart:FindFirstChild("ProximityPrompt")
            if p then fireproximityprompt(p) end
        elseif SelectedAction == "Modifikasi" then
            local p = workspace.Modif.ModificationTriggerPart:FindFirstChild("ProximityPrompt")
            if p then fireproximityprompt(p) end
        elseif SelectedAction == "Teleport City" then
            local p = workspace:FindFirstChild("Telportpart")
                   and workspace.Telportpart:FindFirstChild("ProximityPrompt")
            if p then fireproximityprompt(p) end
        end
        SetStatus("Opening " .. SelectedAction)
    end,
})