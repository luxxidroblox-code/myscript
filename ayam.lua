-- Lua 5.1 | Bus Explorer Indonesia | Roblox Executor
-- Rayfield UI library: sirius.menu/rayfield
-- Remote hook: ReplicatedStorage.Remotes — OnClientEvent fires destination CF after StartBusJob
-- BodyGyro + AlignPosition spoof: server sees smooth velocity approach, not instant pivot
-- TweenService drives CFrameValue for descent — same CDI pattern as AerialTP v1
-- *BodyGyro deprecated in newer baseplate templates; falls back to AlignOrientation if missing*

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name             = ".projectsion",
    LoadingTitle     = "Bus Explorer Indonesia",
    LoadingSubtitle  = "by .projectsion",
    Theme            = "Bloom",
    ConfigurationSaving = { Enabled = true, FileName = "VoidlineConfig" },
    KeySystem        = false,
})

-- ── Services ──────────────────────────────────────────────────────────────────
local VirtualUser       = game:GetService("VirtualUser")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP              = Players.LocalPlayer
local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local StatsFolder     = LP:WaitForChild("PlayerData")
local OwnedCarsFolder = StatsFolder:WaitForChild("OwnedCars")
local CarData         = Remotes.GetClientCustomizationData:InvokeServer()

-- ── Globals ───────────────────────────────────────────────────────────────────
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

local StartUang        = StatsFolder.Uang.Value
local StartTime        = os.time()
local TargetUang       = 0
local lastMoney        = StatsFolder.Uang.Value
local SelectedBusToBuy = ""
local CarListData      = {}
local pendingIncome    = 0
local SelectedAction   = "Dealership"
local SelectedTP       = "Dealership"
local isRunning        = false
local busOptions       = {}

-- ── Remote-event destination state ───────────────────────────────────────────
-- The server fires a destination CFrame after StartBusJob resolves.
-- We hook OnClientEvent on the route remote and cache the last destination.
local pendingDestinationCF = nil   -- set by remote hook, consumed by farm loop
local destinationArrived   = false -- flag for the farm loop to wake on

-- ── Black screen overlay ──────────────────────────────────────────────────────
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
    while task.wait(0.5) do BlackScreen.Enabled = _G.blackscreen end
end)

-- ── Auto-kick non-LP players ──────────────────────────────────────────────────
local function checkAndKick()
    local list = Players:GetPlayers()
    if #list > 1 then
        local names = {}
        for _, p in ipairs(list) do
            if p ~= LP then table.insert(names, p.Name) end
        end
        LP:Kick("admim mesum joim private server lu woi aowkaowk: " .. table.concat(names, ", "))
    end
end

Players.PlayerAdded:Connect(function(player)
    if player == LP then return end
    task.wait(0.5)
    checkAndKick()
end)

task.spawn(function()
    while true do task.wait(3); checkAndKick() end
end)

-- ── UI labels (forward-declared, populated in StatsTab) ──────────────────────
local StatusLabel, UangLabel, EarningLabel, TimeLabel, FPSLabel, PingLabel

local function formatRS(amount)
    local s = tostring(amount)
    while true do
        local k; s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return s
end

local function formatRP(v)  return "Rp " .. formatRS(v) end

local function getRunningTime()
    local d = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d", math.floor(d/3600), math.floor((d%3600)/60), d%60)
end

task.spawn(function()
    while task.wait(1) do
        if UangLabel then
            pcall(function()
                local cur = StatsFolder.Uang.Value
                UangLabel:Set("Uang: Rp "    .. formatRS(cur))
                EarningLabel:Set("Earning: Rp " .. formatRS(cur - StartUang))
                local d = os.time() - StartTime
                TimeLabel:Set(string.format("Time: %02d:%02d:%02d",
                    math.floor(d/3600), math.floor((d%3600)/60), d%60))
                local ping = tonumber(game:GetService("Stats")
                    .Network.ServerStatsItem["Data Ping"]
                    :GetValueString():split(" ")[1]) or 0
                PingLabel:Set("Ping: " .. math.floor(ping) .. " ms")
                FPSLabel:Set("FPS: "  .. math.floor(1 / task.wait()))
            end)
        end
    end
end)

-- ── Owned bus list ────────────────────────────────────────────────────────────
for _, car in pairs(OwnedCarsFolder:GetChildren()) do
    local id   = car.Name
    local info = CarData.CarData_Cars[id]
    if info then table.insert(busOptions, id) end
end
if #busOptions == 0 then table.insert(busOptions, "Jetbus_3_RM _SHD") end
_G.SelectedBus = busOptions[1]

-- ── Fixed CFrames ─────────────────────────────────────────────────────────────
local BaranangsangEndCF = CFrame.new(22732.02, 293.21, -39525.31)
    * CFrame.Angles(2.8307, -0.7276, 2.9293)

local TP_Locations = {
    ["Dealership"]    = CFrame.new(19830.625,  266.913116, -27910.4844,  0.999847949, 0,  0.017436387, 0, 1, 0, -0.017436387, 0, 0.999847949),
    ["Modifikasi"]    = CFrame.new(12035.499,  -21.3362789, 12740.0605, -0.573599219, 0,  0.81913656,  0, 1, 0, -0.81913656,  0, -0.573599219),
    ["Teleport City"] = CFrame.new(21795.2461, 292.439026, -40055.918,   0.707134247, -0, -0.707079291, 0, 1, -0, 0.707079291, 0, 0.707134247),
}

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function SetStatus(text)
    if StatusLabel then StatusLabel:Set("Status: " .. text) end
end

local function GetMyBus()
    return workspace.SpawnedVehicles:FindFirstChild(_G.SelectedBus)
end

local function getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId="
        .. LP.UserId .. "&width=420&height=420&format=png"
end

-- ── BodyGyro spoof ────────────────────────────────────────────────────────────
-- Attaches a BodyGyro (+ BodyVelocity) to the bus PrimaryPart.
-- Server observes smooth angular correction at 240 deg/s cap — no snap.
-- *BodyGyro.MaxTorque must be large enough to overcome bus mass*
-- Returns the two constraint instances for caller to manage lifetime.
local GYRO_SPEED    = 240   -- degrees-per-second equivalent, mapped to MaxTorque
local GYRO_DAMPING  = 500
local ALIGN_SPEED   = 60    -- studs/s for BodyVelocity during approach

local function AttachSpoof(bus, targetCF)
    local primaryPart = bus.PrimaryPart
        or bus:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then return nil, nil end

    -- clear residual velocity
    for _, p in pairs(bus:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored = false
            p.AssemblyLinearVelocity  = Vector3.zero
            p.AssemblyAngularVelocity = Vector3.zero
        end
    end

    -- BodyGyro: server sees angular approach, not teleport
    local gyro          = Instance.new("BodyGyro")
    gyro.MaxTorque      = Vector3.new(1e6, 1e6, 1e6)
    gyro.D              = GYRO_DAMPING
    gyro.P              = GYRO_SPEED * 1000   -- proportional gain
    gyro.CFrame         = targetCF            -- desired orientation
    gyro.Parent         = primaryPart

    -- BodyVelocity: pushes bus toward target at ALIGN_SPEED, server sees velocity
    local toTarget      = targetCF.Position - primaryPart.Position
    local dist          = toTarget.Magnitude
    local bv            = Instance.new("BodyVelocity")
    bv.MaxForce         = Vector3.new(1e6, 1e6, 1e6)
    bv.P                = 1e4
    bv.Velocity         = dist > 0.1
        and (toTarget.Unit * ALIGN_SPEED)
        or  Vector3.zero
    bv.Parent           = primaryPart

    return gyro, bv
end

local function DetachSpoof(gyro, bv)
    if gyro then gyro:Destroy() end
    if bv   then bv:Destroy()   end
end

-- ── SpoofTP ───────────────────────────────────────────────────────────────────
-- 1. Instantly moves bus to sky (gravity 0, server can't pathfind up there).
-- 2. Attaches BodyGyro + BodyVelocity spoof toward targetCF at sky height.
-- 3. TweenService descent over DESCENT_TIME — CFrameValue.Changed pattern.
-- 4. Removes spoof constraints at landing, pivots exact.
local AERIAL_HEIGHT = 1000
local DESCENT_TIME  = 4   -- seconds; faster = snappier, slower = safer

local function SpoofTP(targetCF)
    local bus = GetMyBus()
    if not bus then return end

    bus.PrimaryPart = bus.PrimaryPart or bus:FindFirstChildWhichIsA("BasePart")
    if not bus.PrimaryPart then return end

    local pp = bus.PrimaryPart

    -- clear all physics before lift
    for _, p in pairs(bus:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored = false
            p.AssemblyLinearVelocity  = Vector3.zero
            p.AssemblyAngularVelocity = Vector3.zero
        end
    end

    -- lift instant (gravity 0)
    local currentCF = bus:GetPivot()
    bus:PivotTo(currentCF + Vector3.new(0, AERIAL_HEIGHT, 0))
    task.wait()

    -- translate above target
    bus:PivotTo(targetCF + Vector3.new(0, AERIAL_HEIGHT, 0))
    task.wait()

    -- attach spoof — server sees orientation + velocity, not snap
    local gyro, bv = AttachSpoof(bus, targetCF + Vector3.new(0, AERIAL_HEIGHT, 0))

    -- CFrameValue tween descent
    local info  = TweenInfo.new(DESCENT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local cfVal = Instance.new("CFrameValue")
    cfVal.Value = bus:GetPivot()

    local conn = cfVal.Changed:Connect(function()
        bus:PivotTo(cfVal.Value)
        pp.AssemblyLinearVelocity  = Vector3.zero
        pp.AssemblyAngularVelocity = Vector3.zero
        -- steer gyro toward current descent CF orientation
        if gyro and gyro.Parent then gyro.CFrame = cfVal.Value end
    end)

    local tween = TweenService:Create(cfVal, info, { Value = targetCF })
    tween:Play()

    while tween.PlaybackState ~= Enum.PlaybackState.Completed and _G.AutoFull do
        task.wait(0.1)
    end
    if tween.PlaybackState ~= Enum.PlaybackState.Completed then tween:Cancel() end

    conn:Disconnect()
    cfVal:Destroy()
    DetachSpoof(gyro, bv)

    -- exact landing
    bus:PivotTo(targetCF)
    pp.AssemblyLinearVelocity  = Vector3.zero
    pp.AssemblyAngularVelocity = Vector3.zero
end

-- ── HoldAtStop ────────────────────────────────────────────────────────────────
-- Zeros velocity every HOLD_INTERVAL; gravity is 0 during farm.
local HOLD_INTERVAL = 0.05

local function HoldAtStop(duration)
    local elapsed = 0
    while elapsed < duration and _G.AutoFull do
        task.wait(HOLD_INTERVAL)
        elapsed = elapsed + HOLD_INTERVAL
        local bus = GetMyBus()
        if bus then
            for _, p in pairs(bus:GetDescendants()) do
                if p:IsA("BasePart") and not p.Anchored then
                    p.AssemblyLinearVelocity  = Vector3.zero
                    p.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end
end

-- ── OnClientEvent hook ────────────────────────────────────────────────────────
-- Bus Explorer Indonesia fires a route-update remote after StartBusJob.
-- We intercept every client-bound event on the Remotes folder and cache
-- any that carry a CFrame payload — that CFrame is the next checkpoint.
-- *RemoteEvent name may vary; hook all and filter by CFrame argument.*

local hookedRemotes = {}

local function hookRemote(remote)
    if hookedRemotes[remote] then return end
    hookedRemotes[remote] = true
    remote.OnClientEvent:Connect(function(...)
        local args = {...}
        for _, v in ipairs(args) do
            if typeof(v) == "CFrame" then
                -- server pushed a destination CFrame
                pendingDestinationCF = v
                destinationArrived   = true
                break
            end
            -- some games wrap destination in a table
            if type(v) == "table" then
                for _, tv in pairs(v) do
                    if typeof(tv) == "CFrame" then
                        pendingDestinationCF = tv
                        destinationArrived   = true
                        break
                    end
                end
            end
        end
    end)
end

-- hook existing remotes
for _, remote in pairs(Remotes:GetChildren()) do
    if remote:IsA("RemoteEvent") then hookRemote(remote) end
end

-- hook future remotes
Remotes.ChildAdded:Connect(function(child)
    if child:IsA("RemoteEvent") then hookRemote(child) end
end)

-- ── Webhook ───────────────────────────────────────────────────────────────────
local function sendWebhook(income)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end

    _G.CycleCount   = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income

    local http_request = request or http_request
        or (syn and syn.request)
        or (fluxus and fluxus.request)

    local embed = {
        ["author"] = { ["name"] = "Projectsion Webhook", ["icon_url"] = getAvatar() },
        ["title"]  = "Bus Route Completed",
        ["color"]  = 0xFFFFFF,
        ["fields"] = {
            { ["name"] = "Protected",     ["value"] = LP.Name,                         ["inline"] = false },
            { ["name"] = "Cycle Income",  ["value"] = formatRP(income),                ["inline"] = false },
            { ["name"] = "Target",        ["value"] = "Cirebon → Baranangsiang Route", ["inline"] = false },
            { ["name"] = "Current Money", ["value"] = formatRP(StatsFolder.Uang.Value),["inline"] = false },
            { ["name"] = "Total Earning", ["value"] = formatRP(_G.TotalEarning),       ["inline"] = false },
            { ["name"] = "Cycle Count",   ["value"] = tostring(_G.CycleCount),         ["inline"] = false },
            { ["name"] = "Running Time",  ["value"] = getRunningTime(),                ["inline"] = false },
        },
        ["image"]  = { ["url"] = "https://cdn.discordapp.com/attachments/1492837859370074192/1508063383944036433/IMG_20260524_180509.jpg?ex=6a142cf9&is=6a12db79&hm=124ec4dccb5d72326d9b0776d912bb18631948f41162cd9fa6d08eafcff19fb4&" },
        ["footer"] = { ["text"] = "Made By Projectsion | " .. os.date("%m/%d/%Y %I:%M %p") },
    }

    local payload = HttpService:JSONEncode({
        ["username"] = "Projectsion Reports",
        ["embeds"]   = { embed },
    })

    if http_request then
        pcall(function()
            http_request({
                Url     = _G.WebhookURL,
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = payload,
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

-- ── Client car list ───────────────────────────────────────────────────────────
local ClientData = Remotes.GetClientCustomizationData:InvokeServer()
if ClientData and ClientData.CarData_Cars then
    for carID in pairs(ClientData.CarData_Cars) do
        table.insert(CarListData, carID)
    end
    table.sort(CarListData)
end

-- ════════════════════════════════════════════════════════════════════════════
-- MAIN TAB
-- ════════════════════════════════════════════════════════════════════════════
local MainTab = Window:CreateTab("Main Farm", "play")
MainTab:CreateSection("Autofarm bus")
MainTab:CreateParagraph({
    Title   = "WARNING",
    Content = "USE JB5 ONLY — other buses risk detection. Enable Auto-Kick when staff is online.",
})

MainTab:CreateToggle({
    Name         = "On Autofarm",
    CurrentValue = false,
    Callback     = function(Value)
        _G.AutoFull = Value

        if not Value then
            workspace.Gravity    = 196.2
            pendingDestinationCF = nil
            destinationArrived   = false
            SetStatus("Idle")
            return
        end

        workspace.Gravity = 0   -- AerialTP relies on gravity-zero float

        local jobStarted    = false
        local lastDestCF    = nil
        local noBillboard   = 0

        while _G.AutoFull do
            -- ── Cikamurang artifact cleanup ────────────────────────────────
            pcall(function()
                local cik = workspace:FindFirstChild("Cikamurang")
                if cik then
                    local mdl = cik:FindFirstChild("model") or cik:FindFirstChild("Model")
                    if mdl then
                        local sinar = mdl:WaitForChild("SInar", 0.1)
                        if sinar then sinar:Destroy() end
                    end
                end
            end)

            local hum      = LP.Character and LP.Character:FindFirstChild("Humanoid")
            local infoLabel = LP.PlayerGui:FindFirstChild("BusJobGUI")
                and LP.PlayerGui.BusJobGUI.JobStatusFrame.InfoLabel

            -- ── Job start sequence ─────────────────────────────────────────
            if not jobStarted then
                SetStatus("Spawning: " .. _G.SelectedBus)
                Remotes:WaitForChild("SpawnCar"):FireServer(_G.SelectedBus)
                task.wait(4)

                local bus = GetMyBus()
                if bus and bus:FindFirstChild("DriveSeat") then
                    bus.DriveSeat:Sit(hum)
                    task.wait(2)

                    SetStatus("Invoking job...")
                    pendingDestinationCF = nil
                    destinationArrived   = false

                    -- fire StartBusJob — server will push route update via OnClientEvent
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
                        SetStatus("Job active — waiting for remote destination...")
                    end
                end
            end

            -- ── Remote-driven destination logic ────────────────────────────
            -- destinationArrived is set true by OnClientEvent hook.
            -- If the server sent a CFrame destination, SpoofTP there.
            -- If no remote yet, fall back to BillboardGui stop detection.
            if destinationArrived and pendingDestinationCF then
                local destCF = pendingDestinationCF
                pendingDestinationCF = nil
                destinationArrived   = false
                noBillboard          = 0

                if destCF ~= lastDestCF then
                    lastDestCF = destCF

                    SetStatus("Remote destination received — spoofing approach...")
                    SpoofTP(destCF)

                    -- 20s presence hold, correction check every second
                    for i = 1, 20 do
                        if not _G.AutoFull then break end
                        if infoLabel and string.find(string.upper(infoLabel.Text), "RETURN TO THE CHECKPOINT") then
                            SetStatus("Correction: re-spoofing...")
                            SpoofTP(destCF)
                        else
                            SetStatus("Stop confirmed — holding " .. (20 - i) .. "s")
                        end
                        HoldAtStop(1)
                    end

                    -- 15s next-stop window
                    for i = 15, 1, -1 do
                        if not _G.AutoFull then break end
                        SetStatus("Next stop in: " .. i .. "s")
                        HoldAtStop(1)
                    end

                    -- 90s inter-stop delay
                    for i = 90, 1, -1 do
                        if not _G.AutoFull then break end
                        SetStatus("Delay: " .. i .. "s")
                        HoldAtStop(1)
                    end
                end

            else
                -- ── Billboard fallback ─────────────────────────────────────
                local activeStop = nil
                for _, part in pairs(workspace.Checkpoints:GetChildren()) do
                    local bs = part:FindFirstChild("BusStop")
                    if bs and bs:IsA("BillboardGui") and bs.Enabled then
                        activeStop = part
                        break
                    end
                end

                if activeStop then
                    noBillboard = 0
                    if activeStop ~= lastDestCF then
                        lastDestCF = activeStop

                        SetStatus("Billboard fallback — spoofing to stop...")
                        SpoofTP(activeStop.CFrame)

                        for i = 1, 20 do
                            if not _G.AutoFull then break end
                            if infoLabel and string.find(string.upper(infoLabel.Text), "RETURN TO THE CHECKPOINT") then
                                SetStatus("Correction: re-spoofing...")
                                SpoofTP(activeStop.CFrame)
                            else
                                SetStatus("Stop confirmed — holding " .. (20 - i) .. "s")
                            end
                            HoldAtStop(1)
                        end

                        for i = 15, 1, -1 do
                            if not _G.AutoFull then break end
                            SetStatus("Next stop in: " .. i .. "s")
                            HoldAtStop(1)
                        end

                        for i = 50, 1, -1 do
                            if not _G.AutoFull then break end
                            SetStatus("Delay: " .. i .. "s")
                            HoldAtStop(1)
                        end
                    end

                elseif jobStarted then
                    noBillboard = noBillboard + 1
                    SetStatus("No stop found: " .. (20 - noBillboard) .. "s")

                    if noBillboard >= 20 then
                        SetStatus("Finishing route...")
                        SpoofTP(BaranangsangEndCF)
                        task.wait(2)

                        jobStarted   = false
                        lastDestCF   = nil
                        noBillboard  = 0

                        local bus = GetMyBus()
                        if bus then bus:Destroy() end

                        SetStatus("Route complete — restarting...")
                        task.wait(3)
                    end
                end
            end

            task.wait(1)
        end

        workspace.Gravity = 196.2
    end
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
        local clean = Text:gsub("%.", "")
        TargetUang  = tonumber(clean) or 0
        Rayfield:Notify({
            Title    = "Target Set",
            Content  = "money target is set to: Rp " .. formatRS(TargetUang),
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
                    local cur = StatsFolder.Uang.Value
                    if TargetUang > 0 and cur >= TargetUang then
                        LP:Kick("\n[VoidlineHub]\nTarget money reached!\nTotal: Rp " .. formatRS(cur))
                        break
                    end
                    task.wait(2)
                end
            end)
        end
    end,
})

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION TAB
-- ════════════════════════════════════════════════════════════════════════════
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
        local newOpts = {}
        for _, car in pairs(OwnedCarsFolder:GetChildren()) do
            table.insert(newOpts, car.Name)
        end
        BusDropdown:Set(newOpts)
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
            Content  = "URL has been saved.",
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
                    Content  = "Please enter a valid Discord Webhook URL first!",
                    Duration = 5,
                    Image    = "alert-triangle",
                })
            else
                SetStatus("Webhook Active")
            end
        end
    end,
})

-- ════════════════════════════════════════════════════════════════════════════
-- STATS TAB
-- ════════════════════════════════════════════════════════════════════════════
local StatsTab = Window:CreateTab("Stats", "trending-up")

StatsTab:CreateSection("Info Farm")
StatusLabel  = StatsTab:CreateLabel("Status: Waiting",    "clock")
UangLabel    = StatsTab:CreateLabel("Uang: Rp " .. StartUang, "banknote")
EarningLabel = StatsTab:CreateLabel("Earning: Rp 0",      "coins")
TimeLabel    = StatsTab:CreateLabel("Time: 00:00:00",      "timer")

StatsTab:CreateSection("System Info")
FPSLabel  = StatsTab:CreateLabel("FPS: Scanning...", "monitor")
PingLabel = StatsTab:CreateLabel("Ping: Scanning...", "wifi")

-- ════════════════════════════════════════════════════════════════════════════
-- MORE FEATURES TAB
-- ════════════════════════════════════════════════════════════════════════════
local MoreTab = Window:CreateTab("More Features", "plus-circle")
MoreTab:CreateSection("important features")

MoreTab:CreateToggle({
    Name         = "Anti-AFK System",
    CurrentValue = true,
    Flag         = "AntiAFK",
    Callback     = function(Value)
        _G.AntiAFK = Value
        SetStatus(_G.AntiAFK and "Anti-AFK Enabled" or "Anti-AFK Disabled")
    end,
})

game.Players.LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

MoreTab:CreateToggle({
    Name         = "Auto Rejoin",
    CurrentValue = false,
    Flag         = "AutoRejoin",
    Callback     = function(Value) _G.AutoRejoin = Value end,
})

MoreTab:CreateSection("Visual & Performance")

-- Guard: destroys BillboardGui only when farm is off — active farm needs them for fallback.
MoreTab:CreateButton({
    Name     = "Hide All Names",
    Callback = function()
        if _G.AutoFull then
            Rayfield:Notify({
                Title    = "Blocked",
                Content  = "Turn off autofarm first — BillboardGui destruction breaks stop fallback.",
                Duration = 4,
                Image    = "alert-triangle",
            })
            return
        end
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

MoreTab:CreateSection("auto buy bus")

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
            Rayfield:Notify({ Title = "Error", Content = "Please select a bus first!", Duration = 3 })
            return
        end
        Rayfield:Notify({
            Title    = "Confirm Purchase",
            Content  = "Buying: " .. SelectedBusToBuy .. ". Please wait...",
            Duration = 5,
            Image    = "shopping-cart",
        })
        local ok, err = pcall(function()
            Remotes:WaitForChild("BuyCar"):FireServer(SelectedBusToBuy)
        end)
        if ok then
            SetStatus("Success Buying " .. SelectedBusToBuy)
        else
            SetStatus("Purchase Failed!")
            warn("Error: " .. tostring(err))
        end
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
        local cf = TP_Locations[SelectedTP]
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character:PivotTo(cf)
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