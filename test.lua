local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ─── Adonis Bypass ────────────────────────────────────────────────────────────
local function unfreezeTable(t)
    if type(t) == "table" then
        pcall(function()
            if setreadonly    then setreadonly(t, false)  end
            if table.unfreeze then table.unfreeze(t)      end
            if make_writeable then make_writeable(t)      end
        end)
        for _, v in pairs(t) do
            if type(v) == "table" then unfreezeTable(v) end
        end
    end
end

local function hiadonis()
    local Detected = filtergc("function", {
        Constants      = { " - On Xbox", " - On mobile", "_" },
        IgnoreExecutor = true,
    }, true)
    if not Detected then
        warn("[projectsion] filtergc miss — Adonis not loaded or constants changed")
        return false
    end

    local s, l, a, n, f = debug.info(Detected, "slanf")
    warn("[projectsion] Detected located.")

    local targetDebug = (typeof(REnv) == "table" and REnv.debug) or debug
    local origDebugInfo
    if targetDebug and targetDebug.info then
        origDebugInfo = hookfunction(targetDebug.info, newcclosure(function(fn, fmt, ...)
            if fn == Detected and fmt == "slanf" then return s, l, a, n, f end
            return origDebugInfo(fn, fmt, ...)
        end))
    end

    hookfunction(Detected, newcclosure(function(...)
        return coroutine.yield(coroutine.running())
    end))

    local Kill = filtergc("function", {
        Constants = { "Kill", "Variables", "Process" }, IgnoreExecutor = true,
    }, true)
    if Kill then
        warn("[projectsion] Kill located.")
        hookfunction(Kill, newcclosure(function(...) end))
    end

    local Log = filtergc("function", {
        Constants = { "Log", "Logs", "LogMessage" }, IgnoreExecutor = true,
    }, true)
    if Log then
        warn("[projectsion] Log located.")
        hookfunction(Log, newcclosure(function(...) end))
    end

    setthreadidentity(2)
    for _, v in getgc(true) do
        if typeof(v) == "table" then
            unfreezeTable(v)
            local dk = rawget(v, "Detected")
            local kk = rawget(v, "Kill")
            local lk = rawget(v, "Log")
            if dk ~= nil then
                pcall(rawset, v, "Detected", function() return false end)
            end
            if typeof(dk) == "function" and dk ~= Detected then
                pcall(hookfunction, dk, function(...) return true end)
            end
            if typeof(kk) == "function" and kk ~= Kill then
                pcall(hookfunction, kk, function(...) end)
            end
            if typeof(lk) == "function" and lk ~= Log then
                pcall(hookfunction, lk, function(...) end)
            end
        end
    end
    setthreadidentity(7)
    return true
end

task.delay(1.5, function()
    local ok = hiadonis()
    if not ok then
        task.delay(3, function()
            local retry = hiadonis()
            warn("[projectsion] Adonis bypass " .. (retry and "active (retry)." or "failed — check constants."))
        end)
    else
        warn("[projectsion] Adonis bypass active.")
    end
end)
-- ─────────────────────────────────────────────────────────────────────────────

local Window = Rayfield:CreateWindow({
    Name            = ".projectsion",
    LoadingTitle    = "Bus Explorer Indonesia",
    LoadingSubtitle = "by .projectsion",
    Theme           = "Bloom",
    ConfigurationSaving = { Enabled = true, FileName = "VoidlineConfig" },
    KeySystem       = false,
})

local VirtualUser     = game:GetService("VirtualUser")
local TweenService    = game:GetService("TweenService")
local LP              = game.Players.LocalPlayer
local Players         = game:GetService("Players")
local Remotes         = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local StatsFolder     = LP:WaitForChild("PlayerData")
local StartUang       = StatsFolder.Uang.Value
local StartTime       = os.time()
local CarData         = Remotes.GetClientCustomizationData:InvokeServer()
local OwnedCarsFolder = LP:WaitForChild("PlayerData"):WaitForChild("OwnedCars")
local HttpService     = game:GetService("HttpService")

_G.AutoFull        = false
_G.AntiAFK         = true
_G.blackscreen     = false
_G.SelectedBus     = ""
_G.WebhookURL      = ""
_G.WebhookEnabled  = false
_G.TotalEarning    = 0
_G.CycleCount      = 0
_G.StartTime       = os.time()
_G.AutoKickEnabled = false

local TargetUang       = 0
local lastMoney        = StatsFolder.Uang.Value
local SelectedBusToBuy = ""
local CarListData      = {}
local pendingIncome    = 0
local SelectedAction   = "Dealership"
local SelectedTP       = "Dealership"
local isRunning        = false
local busOptions       = {}

-- last stop Baranangsiang — dipakai setelah CP#7 billboard hilang
local BaranangsangEndCF = CFrame.new(22732.02, 293.21, -39525.31)
    * CFrame.Angles(2.8307, -0.7276, 2.9293)

-- ─── OnClientEvent — BusJobUpdate fallback ───────────────────────────────────
local _jobEventArg = nil
local _jobResumed  = false

local busJobUpdate = Remotes:FindFirstChild("BusJobUpdate")
if busJobUpdate and busJobUpdate:IsA("RemoteEvent") then
    busJobUpdate.OnClientEvent:Connect(function(eventType, data)
        if eventType == "StartCheckpointWait" then
            _jobEventArg = data
        elseif eventType == "JobResumed" then
            _jobResumed = true
            task.delay(2, function() _jobResumed = false end)
        end
    end)
end
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Self-Kick ────────────────────────────────────────────────────────────────
local function selfKickIfIntruder()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            LP:Kick("⚠️ SOMEONE JOINED — AUTO ESCAPED\nPlayer: " .. p.Name)
            return
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    if player == LP then return end
    selfKickIfIntruder()
    task.delay(0.3, selfKickIfIntruder)
    task.delay(1,   selfKickIfIntruder)
end)

task.spawn(function()
    while true do
        task.wait(2)
        selfKickIfIntruder()
    end
end)
-- ─────────────────────────────────────────────────────────────────────────────

local BlackScreen = Instance.new("ScreenGui")
local BSFrame     = Instance.new("Frame")
BlackScreen.Name           = "ProjectsionBlackout"
BlackScreen.Parent         = game:GetService("CoreGui")
BlackScreen.DisplayOrder   = -1
BlackScreen.Enabled        = false
BSFrame.Parent             = BlackScreen
BSFrame.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
BSFrame.Size               = UDim2.new(1.5, 0, 1.5, 0)
BSFrame.Position           = UDim2.new(-0.25, 0, -0.25, 0)
BSFrame.BorderSizePixel    = 0

task.spawn(function()
    while task.wait(0.5) do BlackScreen.Enabled = _G.blackscreen end
end)

local StatusLabel, UangLabel, EarningLabel, TimeLabel, FPSLabel, PingLabel

local function formatRS(amount)
    local formatted = tostring(amount)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return formatted
end

task.spawn(function()
    while task.wait(1) do
        if UangLabel then
            pcall(function()
                local currentUang = StatsFolder.Uang.Value
                UangLabel:Set("Uang: Rp "       .. formatRS(currentUang))
                EarningLabel:Set("Earning: Rp "  .. formatRS(currentUang - StartUang))
                local diff = os.time() - StartTime
                TimeLabel:Set(string.format("Time: %02d:%02d:%02d",
                    math.floor(diff / 3600), math.floor((diff % 3600) / 60), diff % 60))
                local ping = tonumber(game:GetService("Stats")
                    .Network.ServerStatsItem["Data Ping"]:GetValueString():split(" ")[1]) or 0
                PingLabel:Set("Ping: " .. math.floor(ping) .. " ms")
                FPSLabel:Set("FPS: " .. math.floor(1 / task.wait()))
            end)
        end
    end
end)

for _, car in pairs(OwnedCarsFolder:GetChildren()) do
    local carID = car.Name
    if CarData.CarData_Cars[carID] then table.insert(busOptions, carID) end
end
if #busOptions == 0 then table.insert(busOptions, "Jetbus_3_RM _SHD") end
_G.SelectedBus = busOptions[1]

local TP_Locations = {
    ["Dealership"]    = CFrame.new(19830.625, 266.913116, -27910.4844,
        0.999847949, 0, 0.017436387, 0, 1, 0, -0.017436387, 0, 0.999847949),
    ["Modifikasi"]    = CFrame.new(12035.499, -21.3362789, 12740.0605,
        -0.573599219, 0, 0.81913656, 0, 1, 0, -0.81913656, 0, -0.573599219),
    ["Teleport City"] = CFrame.new(21795.2461, 292.439026, -40055.918,
        0.707134247, 0, -0.707079291, 0, 1, 0, 0.707079291, 0, 0.707134247),
}

LP.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

local function SetStatus(text)
    if StatusLabel then StatusLabel:Set("Status: " .. text) end
end

local function GetMyBus()
    return workspace.SpawnedVehicles:FindFirstChild(_G.SelectedBus)
end

local function GetPrimaryPart(bus)
    local body = bus:FindFirstChild("Body")
    if body then
        local w = body:FindFirstChild("#Weight")
        if w then return w end
    end
    return bus.PrimaryPart or bus:FindFirstChildWhichIsA("BasePart")
end

-- ─── SpoofTP ─────────────────────────────────────────────────────────────────
local function SpoofTP(targetCF)
    local bus = GetMyBus()
    if not bus then return end
    local primaryPart = GetPrimaryPart(bus)
    if not primaryPart then return end
    bus.PrimaryPart = primaryPart

    pcall(function() primaryPart:SetNetworkOwner(nil) end)

    local gyro = Instance.new("BodyGyro")
    gyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    gyro.D         = 500
    gyro.P         = 1e5
    gyro.CFrame    = targetCF
    gyro.Parent    = primaryPart

    workspace.Gravity = 0
    primaryPart.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
    primaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

    local cfVal = Instance.new("CFrameValue")
    cfVal.Value = bus:GetPrimaryPartCFrame()

    local conn = cfVal.Changed:Connect(function(newCF)
        bus:PivotTo(newCF)
        primaryPart.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
        primaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)

    local currentPos = primaryPart.CFrame.Position
    local liftTarget = CFrame.new(currentPos + Vector3.new(0, 500, 0))
        * (targetCF - targetCF.Position)
    local highTarget = CFrame.new(
        targetCF.Position + Vector3.new(0, 500, 0),
        targetCF.Position + Vector3.new(0, 500, 0) + targetCF.LookVector
    )

    local t1 = TweenService:Create(cfVal,
        TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Value = liftTarget })
    t1:Play(); t1.Completed:Wait()

    local t2 = TweenService:Create(cfVal,
        TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        { Value = highTarget })
    t2:Play(); t2.Completed:Wait()

    local t3 = TweenService:Create(cfVal,
        TweenInfo.new(7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        { Value = targetCF })
    t3:Play(); t3.Completed:Wait()

    conn:Disconnect()
    cfVal:Destroy()
    gyro:Destroy()
    workspace.Gravity = 196.2
end
-- ─────────────────────────────────────────────────────────────────────────────

local function GetActiveStop()
    for _, part in pairs(workspace.Checkpoints:GetChildren()) do
        local bs = part:FindFirstChild("BusStop")
        if bs and bs:IsA("BillboardGui") and bs.Enabled == true then
            return part
        end
    end
    return nil
end

local function getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId="
        .. LP.UserId .. "&width=420&height=420&format=png"
end

local function formatRP(v)
    local formatted = tostring(v)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return "Rp " .. formatted
end

local function getRunningTime()
    local diff = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d",
        math.floor(diff / 3600), math.floor((diff % 3600) / 60), diff % 60)
end

local function sendWebhook(income)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    _G.CycleCount   = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income
    local currentMoney = StatsFolder.Uang.Value
    local http_request = request or http_request
        or (syn and syn.request) or (fluxus and fluxus.request)
    local embed = {
        ["author"] = { ["name"] = "Projectsion Webhook", ["icon_url"] = getAvatar() },
        ["title"]  = "Bus Route Completed",
        ["color"]  = 0xFFFFFF,
        ["fields"] = {
            { ["name"] = "protected",     ["value"] = LP.Name,                         ["inline"] = false },
            { ["name"] = "Cycle Income",  ["value"] = formatRP(income),                ["inline"] = false },
            { ["name"] = "Target",        ["value"] = "Cirebon → Baranangsiang Route", ["inline"] = false },
            { ["name"] = "Current Money", ["value"] = formatRP(currentMoney),          ["inline"] = false },
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
                    if pendingIncome > 0 and _G.WebhookURL ~= "" and _G.WebhookEnabled then
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

local ClientData = Remotes.GetClientCustomizationData:InvokeServer()
if ClientData and ClientData.CarData_Cars then
    for carID, _ in pairs(ClientData.CarData_Cars) do
        table.insert(CarListData, carID)
    end
    table.sort(CarListData)
end

-- ─── UI ───────────────────────────────────────────────────────────────────────
local MainTab = Window:CreateTab("Main Farm", "play")
MainTab:CreateSection("Autofarm bus")
MainTab:CreateParagraph({
    Title   = "WARNING",
    Content = "USE JB5 ONLY, IF U USE OTHER BUS IT WILL DETECTED, TURN ON AUTO KICK WHEN STAFF JOINED",
})

local lastTarget        = nil
local noBillboardTime   = 0
local jobStarted        = false
local checkpointCount   = 0
local lastStopSpoofed   = false  -- guard biar SpoofTP end cuma sekali per cycle

MainTab:CreateToggle({
    Name         = "On Autofarm",
    CurrentValue = false,
    Callback     = function(Value)
        _G.AutoFull = Value

        if not Value then
            lastTarget      = nil
            jobStarted      = false
            checkpointCount = 0
            lastStopSpoofed = false
            workspace.Gravity = 196.2
            SetStatus("Idle")
            return
        end

        checkpointCount = 0
        lastStopSpoofed = false

        while _G.AutoFull do
            pcall(function()
                local cikamurang = workspace:FindFirstChild("Cikamurang")
                if cikamurang then
                    local folderModel = cikamurang:FindFirstChild("model")
                        or cikamurang:FindFirstChild("Model")
                    if folderModel then
                        local targetHapus = folderModel:WaitForChild("SInar", 0.1)
                        if targetHapus then targetHapus:Destroy() end
                    end
                end
            end)

            local hum       = LP.Character and LP.Character:FindFirstChild("Humanoid")
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

                    SetStatus("Get job...")
                    Remotes:WaitForChild("StartBusJob"):InvokeServer("Cirebon_Baranangsiang4", nil)
                    task.wait(1)

                    hum.Jump = true
                    task.wait(1.5)

                    SetStatus("Spawn vehicle..")
                    Remotes:WaitForChild("SpawnCar"):FireServer(_G.SelectedBus)
                    task.wait(4)
                    bus = GetMyBus()

                    if bus and bus:FindFirstChild("DriveSeat") then
                        bus.DriveSeat:Sit(hum)
                        jobStarted      = true
                        lastStopSpoofed = false
                    end
                end
            end

            local target = GetActiveStop()

            if target then
                -- ada billboard aktif = masih di tengah route (CP#1–CP#7)
                noBillboardTime = 0
                lastStopSpoofed = false

                if target ~= lastTarget then
                    checkpointCount = checkpointCount + 1
                    SetStatus("Spoofing to CP#" .. checkpointCount .. ": " .. target.Name)
                    SpoofTP(target.CFrame)
                    lastTarget = target

                    for i = 1, 30 do
                        if not _G.AutoFull then break end
                        if infoLabel and string.find(
                            string.upper(infoLabel.Text), "RETURN TO THE CHECKPOINT"
                        ) then
                            SetStatus("Correction: Spoof Again!")
                            SpoofTP(target.CFrame)
                        else
                            SetStatus("Position Secure... " .. i .. "/30")
                        end
                        task.wait(1)
                    end

                    for i = 15, 1, -1 do
                        if not _G.AutoFull then break end
                        SetStatus("To Stations: " .. i .. "s")
                        task.wait(1)
                    end

                    for i = 63, 1, -1 do
                        if not _G.AutoFull then break end
                        SetStatus("Delay TP: " .. i .. "s")
                        task.wait(1)
                    end
                end

            else
                if jobStarted then
                    -- billboard hilang setelah CP#7 = last stop
                    if not lastStopSpoofed then
                        SetStatus("Last Stop — Spoofing to Baranangsiang End...")
                        SpoofTP(BaranangsangEndCF)
                        lastStopSpoofed = true
                    end

                    noBillboardTime = noBillboardTime + 1
                    SetStatus("Waiting finish: " .. (30 - noBillboardTime) .. "s")

                    if noBillboardTime >= 30 then
                        SetStatus("Job Done! Restarting...")
                        jobStarted      = false
                        lastTarget      = nil
                        noBillboardTime = 0
                        checkpointCount = 0
                        lastStopSpoofed = false
                        workspace.Gravity = 196.2

                        local bus = GetMyBus()
                        if bus then bus:Destroy() end
                        task.wait(3)
                    end
                end
            end

            task.wait(1)
        end
    end,
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
                    local currentMoney = StatsFolder.Uang.Value
                    if TargetUang > 0 and currentMoney >= TargetUang then
                        LP:Kick("money target reached: Rp "
                            .. formatRS(currentMoney))
                        break
                    end
                    task.wait(2)
                end
            end)
        end
    end,
})

-- ─── Config Tab ───────────────────────────────────────────────────────────────
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

-- ─── Stats Tab ────────────────────────────────────────────────────────────────
local StatsTab = Window:CreateTab("Stats", "trending-up")
StatsTab:CreateSection("Info Farm")
StatusLabel  = StatsTab:CreateLabel("Status: Waiting",              "clock")
UangLabel    = StatsTab:CreateLabel("Uang: Rp " .. formatRS(StartUang), "banknote")
EarningLabel = StatsTab:CreateLabel("Earning: Rp 0",                "coins")
TimeLabel    = StatsTab:CreateLabel("Time: 00:00:00",               "timer")
StatsTab:CreateSection("System Info")
FPSLabel  = StatsTab:CreateLabel("FPS: Scanning...",  "monitor")
PingLabel = StatsTab:CreateLabel("Ping: Scanning...", "wifi")

-- ─── More Tab ─────────────────────────────────────────────────────────────────
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
        local success, err = pcall(function()
            Remotes:WaitForChild("BuyCar"):FireServer(SelectedBusToBuy)
        end)
        if success then
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