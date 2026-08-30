-- Lua 5.1 / Luau · Bus Explorer Indonesia · Roblox executor
-- Rayfield UI library loaded via HttpGet
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ============================================================
-- SERVICES
-- ============================================================
local VirtualUser       = game:GetService("VirtualUser")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP            = Players.LocalPlayer
local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local StatsFolder   = LP:WaitForChild("PlayerData")
local OwnedCarsFolder = StatsFolder:WaitForChild("OwnedCars")

-- ============================================================
-- WINDOW
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name              = ".projectsion",
    LoadingTitle      = "Bus Explorer Indonesia",
    LoadingSubtitle   = "by .projectsion",
    Theme             = "Bloom",
    ConfigurationSaving = { Enabled = true, FileName = "VoidlineConfig" },
    KeySystem         = false,
})

-- ============================================================
-- GLOBALS
-- ============================================================
_G.AutoFull        = false
_G.AntiAFK         = true
_G.AutoRejoin      = false
_G.blackscreen     = false
_G.HideChar        = false
_G.SelectedBus     = ""
_G.WebhookURL      = ""
_G.WebhookEnabled  = false
_G.TotalEarning    = 0
_G.CycleCount      = 0
_G.StartTime       = os.time()
_G.AutoKickEnabled = false

local CarData       = Remotes.GetClientCustomizationData:InvokeServer()
local StartUang     = StatsFolder.Uang.Value
local StartTime     = os.time()
local TargetUang    = 0
local lastMoney     = StatsFolder.Uang.Value
local SelectedBusToBuy = ""
local CarListData   = {}
local pendingIncome = 0
local SelectedAction = "Dealership"
local SelectedTP    = "Dealership"
local isRunning     = false
local busOptions    = {}
local lastTarget    = nil
local noBillboardTime = 0
local jobStarted    = false

-- ============================================================
-- LABELS (forward-declared; set when tabs build)
-- ============================================================
local StatusLabel, UangLabel, EarningLabel, TimeLabel, FPSLabel, PingLabel

-- ============================================================
-- BLACK SCREEN OVERLAY
-- ============================================================
local BlackScreen = Instance.new("ScreenGui")
BlackScreen.Name         = "ProjectsionBlackout"
BlackScreen.Parent       = game:GetService("CoreGui")
BlackScreen.DisplayOrder = -1
BlackScreen.Enabled      = false

local Frame = Instance.new("Frame")
Frame.Parent           = BlackScreen
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.Size             = UDim2.new(1.5, 0, 1.5, 0)
Frame.Position         = UDim2.new(-0.25, 0, -0.25, 0)
Frame.BorderSizePixel  = 0

task.spawn(function()
    while task.wait(0.5) do
        BlackScreen.Enabled = _G.blackscreen
    end
end)

-- ============================================================
-- UTILITY
-- ============================================================
local function formatRS(amount)
    local formatted = tostring(amount)
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return formatted
end

local function formatRP(v)
    return "Rp " .. formatRS(v)
end

local function getRunningTime()
    local diff = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d",
        math.floor(diff / 3600),
        math.floor((diff % 3600) / 60),
        diff % 60)
end

local function getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId="
        .. LP.UserId .. "&width=420&height=420&format=png"
end

local function SetStatus(text)
    if StatusLabel then StatusLabel:Set("Status: " .. text) end
end

local function GetMyBus()
    return workspace.SpawnedVehicles:FindFirstChild(_G.SelectedBus)
end

-- ============================================================
-- NETWORK OWNERSHIP BYPASS
-- ============================================================
-- Forces the local client as network owner of every BasePart in
-- the spawned bus each heartbeat tick.  `sethiddenproperty` writes
-- the internal NetworkOwnershipRule to Enum value 0 (Manual),
-- which must precede SetNetworkOwner or the call is silently dropped.
-- *sethiddenproperty is a Synapse / Delta / Arceus X internal — not
--  available in vanilla Luau; the pcall guards safe execution on
--  executors that lack it.*
-- ============================================================
local networkBypassConn = nil

local function StartNetworkBypass()
    if networkBypassConn then
        networkBypassConn:Disconnect()
        networkBypassConn = nil
    end
    networkBypassConn = RunService.Heartbeat:Connect(function()
        local bus = GetMyBus()
        if not bus then return end
        for _, part in ipairs(bus:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(sethiddenproperty, part, "NetworkOwnershipRule", 0)
                pcall(function() part:SetNetworkOwner(LP) end)
            end
        end
    end)
end

local function StopNetworkBypass()
    if networkBypassConn then
        networkBypassConn:Disconnect()
        networkBypassConn = nil
    end
end

-- ============================================================
-- HARDENED KICK SYSTEM
-- Layers:
--   1. Players.PlayerAdded signal — fires immediately on join
--   2. Polling loop every 1.5s  — catches any that slipped through
--   3. OnClientEvent listener   — server-push kick trigger
--      Any RemoteEvent firing to the client with payload matching
--      known staff-alert strings also triggers the kick sequence.
-- All three paths call the same KickSelf() which fires LP:Kick()
-- through three escalating paths to maximise execution.
-- ============================================================
local KNOWN_STAFF = {
    -- lowercase exact or partial matches against player name
    "admin", "mod", "moderator", "staff", "dev", "owner",
    "projectsion_staff", "beiadmin", "bistaff"
}

local function isStaff(player)
    local nameLower = string.lower(player.Name)
    for _, tag in ipairs(KNOWN_STAFF) do
        if string.find(nameLower, tag) then return true end
    end
    -- heuristic: players with very low UserId tend to be devs / alts on private runs
    if player.UserId > 0 and player.UserId < 1000 then return true end
    return false
end

local function KickSelf(reason)
    reason = reason or "Intruder detected — auto-kicked by Projectsion"
    -- path 1: standard kick
    pcall(function() LP:Kick(reason) end)
    -- path 2: character removal forces disconnect on most server configs
    pcall(function()
        if LP.Character then
            LP.Character:BreakJoints()
        end
    end)
    -- path 3: fire a bad remote to force server-side disconnect
    pcall(function()
        Remotes:FindFirstChild("LeaveGame") and
        Remotes.LeaveGame:FireServer()
    end)
end

local function CheckAndKick()
    local playerList = Players:GetPlayers()
    if #playerList <= 1 then return end
    local names = {}
    for _, p in ipairs(playerList) do
        if p ~= LP then
            table.insert(names, p.Name)
        end
    end
    if #names > 0 then
        SetStatus("INTRUDER DETECTED — KICKING")
        KickSelf("Intruder(s) in private server: " .. table.concat(names, ", "))
    end
end

-- layer 1: signal
Players.PlayerAdded:Connect(function(player)
    if player == LP then return end
    -- immediate check, then again after 0.5s to catch late-load admins
    CheckAndKick()
    task.wait(0.5)
    CheckAndKick()
end)

-- layer 2: polling
task.spawn(function()
    while true do
        task.wait(1.5)
        if #Players:GetPlayers() > 1 then
            CheckAndKick()
        end
    end
end)

-- ============================================================
-- OnClientEvent LISTENER
-- Hooks every RemoteEvent under the Remotes folder.
-- Staff alert payloads (ban, kick, spectate, teleport-to-player)
-- trigger KickSelf() before the server action can resolve.
-- ============================================================
local STAFF_ALERT_KEYS = {
    "kick", "ban", "mute", "spectate", "teleportplayer",
    "moderationaction", "adminaction", "staffaction", "punish"
}

local function hookRemote(remote)
    if not remote:IsA("RemoteEvent") then return end
    remote.OnClientEvent:Connect(function(...)
        local args = { ... }
        -- stringify all args and scan for staff-action keywords
        local payload = string.lower(HttpService:JSONEncode(args))
        for _, key in ipairs(STAFF_ALERT_KEYS) do
            if string.find(payload, key) then
                SetStatus("SERVER PUSH ALERT — " .. key)
                KickSelf("Server-side staff action intercepted: " .. key)
                return
            end
        end
    end)
end

-- hook existing remotes
for _, remote in ipairs(Remotes:GetChildren()) do
    hookRemote(remote)
end
-- hook future remotes added during session
Remotes.ChildAdded:Connect(function(child)
    task.wait()   -- let it initialise
    hookRemote(child)
end)

-- ============================================================
-- AERIAL TP
-- ============================================================
local AERIAL_HEIGHT = 1000
local DESCENT_TIME  = 5

local function AerialTP(targetCF)
    local bus = GetMyBus()
    if not bus then return end
    if not bus.PrimaryPart then
        bus.PrimaryPart = bus:FindFirstChildWhichIsA("BasePart")
    end
    if not bus.PrimaryPart then return end
    local primaryPart = bus.PrimaryPart

    for _, part in ipairs(bus:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored                = false
            part.AssemblyLinearVelocity  = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end

    local currentCF = bus:GetPivot()
    bus:PivotTo(currentCF + Vector3.new(0, AERIAL_HEIGHT, 0))
    task.wait()
    bus:PivotTo(targetCF + Vector3.new(0, AERIAL_HEIGHT, 0))
    task.wait()

    local info  = TweenInfo.new(DESCENT_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local cfVal = Instance.new("CFrameValue")
    cfVal.Value = bus:GetPivot()

    local conn = cfVal.Changed:Connect(function()
        bus:PivotTo(cfVal.Value)
        primaryPart.AssemblyLinearVelocity  = Vector3.zero
        primaryPart.AssemblyAngularVelocity = Vector3.zero
    end)

    local tween = TweenService:Create(cfVal, info, { Value = targetCF })
    tween:Play()

    while tween.PlaybackState ~= Enum.PlaybackState.Completed and _G.AutoFull do
        task.wait(0.1)
    end
    if tween.PlaybackState ~= Enum.PlaybackState.Completed then tween:Cancel() end
    conn:Disconnect()
    cfVal:Destroy()
    bus:PivotTo(targetCF)
end

-- ============================================================
-- HOLD AT STOP
-- ============================================================
local HOLD_INTERVAL = 0.05

local function HoldAtStop(duration)
    local bus     = GetMyBus()
    local elapsed = 0
    while elapsed < duration and _G.AutoFull do
        task.wait(HOLD_INTERVAL)
        elapsed = elapsed + HOLD_INTERVAL
        if bus then
            for _, part in ipairs(bus:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then
                    part.AssemblyLinearVelocity  = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end
end

-- ============================================================
-- STOP DETECTOR
-- ============================================================
local function GetActiveStop()
    for _, part in ipairs(workspace.Checkpoints:GetChildren()) do
        local bs = part:FindFirstChild("BusStop")
        if bs and bs:IsA("BillboardGui") and bs.Enabled then
            return part
        end
    end
    return nil
end

-- ============================================================
-- WEBHOOK
-- ============================================================
local function sendWebhook(income)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    _G.CycleCount   = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income

    local currentMoney = StatsFolder.Uang.Value
    local http_request = (request ~= nil and request)
        or (syn and syn.request)
        or (fluxus and fluxus.request)
        or nil

    local embed = {
        author  = { name = "Projectsion Webhook", icon_url = getAvatar() },
        title   = "Bus Route Completed",
        color   = 0xFFFFFF,
        fields  = {
            { name = "Player",        value = LP.Name,                         inline = false },
            { name = "Cycle Income",  value = formatRP(income),                inline = false },
            { name = "Target",        value = "Cirebon → Baranangsiang",       inline = false },
            { name = "Current Money", value = formatRP(currentMoney),          inline = false },
            { name = "Total Earning", value = formatRP(_G.TotalEarning),       inline = false },
            { name = "Cycle Count",   value = tostring(_G.CycleCount),         inline = false },
            { name = "Running Time",  value = getRunningTime(),                inline = false },
        },
        image  = { url = "https://cdn.discordapp.com/attachments/1492837859370074192/1508063383944036433/IMG_20260524_180509.jpg" },
        footer = { text = "Made By Projectsion | " .. os.date("%m/%d/%Y %I:%M %p") }
    }

    local payload = HttpService:JSONEncode({
        username = "Projectsion Reports",
        embeds   = { embed }
    })

    if http_request then
        pcall(function()
            http_request({
                Url     = _G.WebhookURL,
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = payload
            })
        end)
    end
end

StatsFolder.Uang:GetPropertyChangedSignal("Value"):Connect(function()
    local newMoney = StatsFolder.Uang.Value
    if newMoney > lastMoney then
        pendingIncome = pendingIncome + (newMoney - lastMoney)
        if not isRunning then
            isRunning = true
            task.spawn(function()
                while isRunning do
                    task.wait(65)
                    if pendingIncome > 0 and _G.WebhookEnabled then
                        sendWebhook(pendingIncome)
                        pendingIncome = 0
                    end
                    if not _G.AutoFull then isRunning = false end
                end
            end)
        end
    end
    lastMoney = newMoney
end)

-- ============================================================
-- STATS TICKER
-- ============================================================
task.spawn(function()
    while task.wait(1) do
        if not UangLabel then continue end
        pcall(function()
            local currentUang = StatsFolder.Uang.Value
            UangLabel:Set("Uang: Rp " .. formatRS(currentUang))
            EarningLabel:Set("Earning: Rp " .. formatRS(currentUang - StartUang))
            local diff = os.time() - StartTime
            TimeLabel:Set(string.format("Time: %02d:%02d:%02d",
                math.floor(diff / 3600),
                math.floor((diff % 3600) / 60),
                diff % 60))
            local ping = tonumber(
                game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
                    :GetValueString():split(" ")[1]) or 0
            PingLabel:Set("Ping: " .. math.floor(ping) .. " ms")
            FPSLabel:Set("FPS: " .. math.floor(1 / task.wait()))
        end)
    end
end)

-- ============================================================
-- OWNED BUS LIST
-- ============================================================
for _, car in ipairs(OwnedCarsFolder:GetChildren()) do
    local carID   = car.Name
    local carInfo = CarData.CarData_Cars and CarData.CarData_Cars[carID]
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

-- ============================================================
-- LOCATIONS
-- ============================================================
local BaranangsangEndCF = CFrame.new(22732.02, 293.21, -39525.31)
    * CFrame.Angles(2.8307, -0.7276, 2.9293)

local TP_Locations = {
    ["Dealership"]    = CFrame.new(19830.625,  266.913116,  -27910.4844,  0.999847949, 0,  0.017436387, 0, 1, 0, -0.017436387, 0,  0.999847949),
    ["Modifikasi"]    = CFrame.new(12035.499,  -21.3362789,  12740.0605, -0.573599219, 0,  0.81913656,  0, 1, 0, -0.81913656,  0, -0.573599219),
    ["Teleport City"] = CFrame.new(21795.2461,  292.439026, -40055.918,   0.707134247, 0, -0.707079291, 0, 1, 0,  0.707079291, 0,  0.707134247),
}

-- ============================================================
-- ANTI-AFK
-- ============================================================
LP.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ============================================================
-- UI — MAIN TAB
-- ============================================================
local MainTab = Window:CreateTab("Main Farm", "play")
MainTab:CreateSection("Autofarm Bus")
MainTab:CreateParagraph({
    Title   = "WARNING",
    Content = "USE JB5 ONLY. Other buses risk detection. Enable Auto-Kick so staff joins trigger immediate self-kick."
})

MainTab:CreateToggle({
    Name         = "On Autofarm",
    CurrentValue = false,
    Callback     = function(Value)
        _G.AutoFull = Value

        if not Value then
            lastTarget        = nil
            jobStarted        = false
            workspace.Gravity = 196.2
            StopNetworkBypass()
            SetStatus("Idle")
            return
        end

        workspace.Gravity = 0
        StartNetworkBypass()

        while _G.AutoFull do
            pcall(function()
                local cikamurang  = workspace:FindFirstChild("Cikamurang")
                if cikamurang then
                    local folderModel = cikamurang:FindFirstChild("model")
                        or cikamurang:FindFirstChild("Model")
                    if folderModel then
                        local sinar = folderModel:WaitForChild("SInar", 0.1)
                        if sinar then sinar:Destroy() end
                    end
                end
            end)

            local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
            local infoLabel = LP.PlayerGui:FindFirstChild("BusJobGUI")
                and LP.PlayerGui.BusJobGUI.JobStatusFrame.InfoLabel

            if not jobStarted then
                SetStatus("Spawning: " .. _G.SelectedBus)
                Remotes:WaitForChild("SpawnCar"):FireServer(_G.SelectedBus)
                task.wait(4)
                local bus = GetMyBus()

                if bus and bus:FindFirstChild("DriveSeat") then
                    bus.DriveSeat:Sit(hum)
                    task.wait(2)

                    SetStatus("Invoking job...")
                    Remotes:WaitForChild("StartBusJob"):InvokeServer("Cirebon_Baranangsiang4", nil)
                    task.wait(1)

                    hum.Jump = true
                    task.wait(1.5)

                    SetStatus("Respawning vehicle...")
                    Remotes:WaitForChild("SpawnCar"):FireServer(_G.SelectedBus)
                    task.wait(4)
                    bus = GetMyBus()

                    if bus and bus:FindFirstChild("DriveSeat") then
                        bus.DriveSeat:Sit(hum)
                        jobStarted = true
                    end
                end
            end

            local target = GetActiveStop()
            if target then
                noBillboardTime = 0
                if target ~= lastTarget then
                    lastTarget = target
                    SetStatus("Aerial approach...")
                    AerialTP(target.CFrame)

                    for i = 1, 20 do
                        if not _G.AutoFull then break end
                        if infoLabel and string.find(
                            string.upper(infoLabel.Text), "RETURN TO THE CHECKPOINT") then
                            SetStatus("Correction: re-approaching...")
                            AerialTP(target.CFrame)
                        else
                            SetStatus("Position confirmed...")
                        end
                        HoldAtStop(1)
                    end

                    for i = 10, 1, -1 do
                        if not _G.AutoFull then break end
                        SetStatus("Next stop in: " .. i .. "s")
                        HoldAtStop(1)
                    end

                    for i = 64, 1, -1 do
                        if not _G.AutoFull then break end
                        SetStatus("Delay TP: " .. i .. "s")
                        HoldAtStop(1)
                    end
                end
            else
                if jobStarted then
                    noBillboardTime = noBillboardTime + 1
                    SetStatus("Searching stop: " .. (20 - noBillboardTime) .. "s")

                    if noBillboardTime >= 20 then
                        SetStatus("Finishing job...")
                        AerialTP(BaranangsangEndCF)
                        task.wait(2)

                        jobStarted        = false
                        lastTarget        = nil
                        noBillboardTime   = 0

                        local bus = GetMyBus()
                        if bus then bus:Destroy() end

                        SetStatus("Job finished. Restarting...")
                        task.wait(3)
                    end
                end
            end
            task.wait(1)
        end

        workspace.Gravity = 196.2
        StopNetworkBypass()
    end
})

MainTab:CreateToggle({
    Name         = "Black Screen",
    CurrentValue = false,
    Flag         = "BlackScreen",
    Callback     = function(Value)
        _G.blackscreen = Value
    end,
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
    Name         = "Enable Auto-Kick",
    CurrentValue = false,
    Flag         = "AutoKick",
    Callback     = function(Value)
        _G.AutoKickEnabled = Value
        if Value then
            task.spawn(function()
                while _G.AutoKickEnabled do
                    local currentMoney = StatsFolder.Uang.Value
                    if TargetUang > 0 and currentMoney >= TargetUang then
                        LP:Kick("\n[VoidlineHub]\nTarget reached!\nTotal: Rp "
                            .. formatRS(currentMoney))
                        break
                    end
                    task.wait(2)
                end
            end)
        end
    end,
})

-- ============================================================
-- UI — CONFIGURATION TAB
-- ============================================================
local ConfigTab = Window:CreateTab("Configuration", "settings")
ConfigTab:CreateSection("Select Spawner Vehicle")

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
        for _, car in ipairs(OwnedCarsFolder:GetChildren()) do
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
        Rayfield:Notify({
            Title    = "Webhook Updated",
            Content  = "URL saved.",
            Duration = 3,
            Image    = "link",
        })
    end,
})

ConfigTab:CreateToggle({
    Name         = "Enable Webhook Report",
    CurrentValue = false,
    Callback     = function(Value)
        _G.WebhookEnabled = Value
        if Value then
            if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then
                Rayfield:Notify({
                    Title    = "Webhook Error",
                    Content  = "Enter a valid Discord Webhook URL first.",
                    Duration = 5,
                    Image    = "alert-triangle",
                })
            else
                SetStatus("Webhook Active")
            end
        end
    end,
})

-- ============================================================
-- UI — STATS TAB
-- ============================================================
local StatsTab = Window:CreateTab("Stats", "trending-up")
StatsTab:CreateSection("Info Farm")
StatusLabel  = StatsTab:CreateLabel("Status: Waiting",    "clock")
UangLabel    = StatsTab:CreateLabel("Uang: Rp " .. formatRS(StartUang), "banknote")
EarningLabel = StatsTab:CreateLabel("Earning: Rp 0",      "coins")
TimeLabel    = StatsTab:CreateLabel("Time: 00:00:00",     "timer")
StatsTab:CreateSection("System Info")
FPSLabel  = StatsTab:CreateLabel("FPS: Scanning...",  "monitor")
PingLabel = StatsTab:CreateLabel("Ping: Scanning...", "wifi")

-- ============================================================
-- UI — MORE FEATURES TAB
-- ============================================================
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
    Callback     = function(Value)
        _G.AutoRejoin = Value
    end,
})

MoreTab:CreateSection("Visual & Performance")

-- Guard: destroying BillboardGui during autofarm silences GetActiveStop().
MoreTab:CreateButton({
    Name     = "Hide All Names",
    Callback = function()
        if _G.AutoFull then
            Rayfield:Notify({
                Title    = "Blocked",
                Content  = "Turn off autofarm first — BillboardGui destruction breaks stop detection.",
                Duration = 4,
                Image    = "alert-triangle",
            })
            return
        end
        for _, v in ipairs(workspace:GetDescendants()) do
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
            for _, part in ipairs(char:GetDescendants()) do
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
        for _, v in ipairs(workspace:GetDescendants()) do
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
    Callback        = function(Option)
        SelectedBusToBuy = Option[1]
    end,
})

MoreTab:CreateButton({
    Name     = "Purchase Selected Bus",
    Callback = function()
        if SelectedBusToBuy == "" or SelectedBusToBuy == "None" then
            Rayfield:Notify({ Title = "Error", Content = "Select a bus first.", Duration = 3 })
            return
        end
        Rayfield:Notify({
            Title    = "Buying...",
            Content  = SelectedBusToBuy .. " — please wait.",
            Duration = 5,
            Image    = "shopping-cart",
        })
        local success, err = pcall(function()
            Remotes:WaitForChild("BuyCar"):FireServer(SelectedBusToBuy)
        end)
        if success then
            SetStatus("Bought " .. SelectedBusToBuy)
        else
            SetStatus("Purchase failed.")
            warn("BuyCar error: " .. tostring(err))
        end
    end,
})

MoreTab:CreateSection("World Teleport")

MoreTab:CreateDropdown({
    Name            = "Select TP Destination",
    Options         = { "Dealership", "Modifikasi", "Teleport City" },
    CurrentOption   = { "Dealership" },
    MultipleOptions = false,
    Callback        = function(Option)
        SelectedTP = Option[1]
    end,
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
    Callback        = function(Option)
        SelectedAction = Option[1]
    end,
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