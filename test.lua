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

-- ─── Services & References ───────────────────────────────────────────────────
local VirtualUser  = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")
local HttpService  = game:GetService("HttpService")
local LP           = Players.LocalPlayer
local Remotes      = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local StatsFolder  = LP:WaitForChild("PlayerData")
local OwnedCarsFolder = StatsFolder:WaitForChild("OwnedCars")
local CarData      = Remotes.GetClientCustomizationData:InvokeServer()
local StartUang    = StatsFolder.Uang.Value
local StartTime    = os.time()
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Globals ─────────────────────────────────────────────────────────────────
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
_G.TweenSpeed      = 150
_G.ArrivalDelay    = 45
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── State ───────────────────────────────────────────────────────────────────
local TargetUang       = 0
local lastMoney        = StatsFolder.Uang.Value
local SelectedBusToBuy = ""
local CarListData      = {}
local pendingIncome    = 0
local SelectedAction   = "Dealership"
local SelectedTP       = "Dealership"
local isRunning        = false
local busOptions       = {}

local lastTarget        = nil
local noBillboardTime   = 0
local jobStarted        = false
local checkpointCount   = 0
local lastStopSpoofed   = false

local BaranangsangEndCF = CFrame.new(22732.02, 293.21, -39525.31)
    * CFrame.Angles(2.8307, -0.7276, 2.9293)
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── OnClientEvent — BusJobUpdate (clean state machine) ──────────────────────
-- State pakai table biar pipeline bisa baca tanpa race condition
local JobEvent = {
    checkpointData = nil,   -- data dari StartCheckpointWait
    resumed        = false, -- true sesaat setelah JobResumed
    resumedAt      = 0,     -- os.clock() saat resumed, untuk auto-clear 3s
}

local busJobUpdate = Remotes:FindFirstChild("BusJobUpdate")
if busJobUpdate and busJobUpdate:IsA("RemoteEvent") then
    busJobUpdate.OnClientEvent:Connect(function(eventType, data)
        if eventType == "StartCheckpointWait" then
            -- server bilang "tunggu di checkpoint ini"
            JobEvent.checkpointData = data
            JobEvent.resumed        = false
            warn("[projectsion] BusJobUpdate → StartCheckpointWait:", data)

        elseif eventType == "JobResumed" then
            -- server bilang "job lanjut, boleh jalan ke CP berikutnya"
            JobEvent.resumed        = true
            JobEvent.resumedAt      = os.clock()
            JobEvent.checkpointData = nil
            warn("[projectsion] BusJobUpdate → JobResumed")

        elseif eventType == "JobCompleted" then
            -- server konfirmasi route selesai
            JobEvent.resumed        = false
            JobEvent.checkpointData = nil
            warn("[projectsion] BusJobUpdate → JobCompleted")
        end
    end)
end

-- Helper: tunggu JobResumed dengan timeout (detik).
-- Returns true jika resumed dalam waktu timeout, false jika timeout habis.
local function waitForJobResumed(timeoutSec)
    local deadline = os.clock() + (timeoutSec or 90)
    while os.clock() < deadline do
        if not _G.AutoFull then return false end
        if JobEvent.resumed then
            -- consume flag setelah dibaca
            JobEvent.resumed = false
            return true
        end
        -- auto-clear resumed flag setelah 3 detik supaya nggak stale
        if JobEvent.resumed and (os.clock() - JobEvent.resumedAt) > 3 then
            JobEvent.resumed = false
        end
        task.wait(0.25)
    end
    warn("[projectsion] waitForJobResumed — timeout " .. (timeoutSec or 90) .. "s")
    return false
end
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Window ───────────────────────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name            = ".projectsion",
    LoadingTitle    = "Bus Explorer Indonesia",
    LoadingSubtitle = "by .projectsion",
    Theme           = "Bloom",
    ConfigurationSaving = { Enabled = true, FileName = "VoidlineConfig" },
    KeySystem       = false,
})
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Self-Kick ────────────────────────────────────────────────────────────────
local function selfKickIfIntruder()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            LP:Kick(" SOMEONE JOINED — AUTO ESCAPED\nPlayer: " .. p.Name)
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

-- ─── Black Screen ─────────────────────────────────────────────────────────────
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
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Labels (late-bound) ──────────────────────────────────────────────────────
local StatusLabel, UangLabel, EarningLabel, TimeLabel, FPSLabel, PingLabel
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Helpers ──────────────────────────────────────────────────────────────────
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
        math.floor(diff / 3600), math.floor((diff % 3600) / 60), diff % 60)
end

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
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Stats updater ───────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(1) do
        if UangLabel then
            pcall(function()
                local currentUang = StatsFolder.Uang.Value
                UangLabel:Set("Uang: Rp "      .. formatRS(currentUang))
                EarningLabel:Set("Earning: Rp " .. formatRS(currentUang - StartUang))
                local diff = os.time() - StartTime
                TimeLabel:Set(string.format("Time: %02d:%02d:%02d",
                    math.floor(diff / 3600), math.floor((diff % 3600) / 60), diff % 60))
                local ping = tonumber(
                    game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
                        :GetValueString():split(" ")[1]) or 0
                PingLabel:Set("Ping: " .. math.floor(ping) .. " ms")
                FPSLabel:Set("FPS: " .. math.floor(1 / task.wait()))
            end)
        end
    end
end)
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Bus list ─────────────────────────────────────────────────────────────────
for _, car in pairs(OwnedCarsFolder:GetChildren()) do
    local carID = car.Name
    if CarData.CarData_Cars[carID] then table.insert(busOptions, carID) end
end
if #busOptions == 0 then table.insert(busOptions, "Jetbus_3_RM _SHD") end
_G.SelectedBus = busOptions[1]

local ClientData = Remotes.GetClientCustomizationData:InvokeServer()
if ClientData and ClientData.CarData_Cars then
    for carID, _ in pairs(ClientData.CarData_Cars) do
        table.insert(CarListData, carID)
    end
    table.sort(CarListData)
end
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── TP Locations ─────────────────────────────────────────────────────────────
local TP_Locations = {
    ["Dealership"]    = CFrame.new(19830.625, 266.913116, -27910.4844,
        0.999847949, 0, 0.017436387, 0, 1, 0, -0.017436387, 0, 0.999847949),
    ["Modifikasi"]    = CFrame.new(12035.499, -21.3362789, 12740.0605,
        -0.573599219, 0, 0.81913656, 0, 1, 0, -0.81913656, 0, -0.573599219),
    ["Teleport City"] = CFrame.new(21795.2461, 292.439026, -40055.918,
        0.707134247, 0, -0.707079291, 0, 1, 0, 0.707079291, 0, 0.707134247),
}
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Anti-AFK ─────────────────────────────────────────────────────────────────
LP.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Webhook ──────────────────────────────────────────────────────────────────
local function sendWebhook(income)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    _G.CycleCount   = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income
    local currentMoney  = StatsFolder.Uang.Value
    local http_request  = request or http_request
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
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Locomotion ───────────────────────────────────────────────────────────────
local function SpoofTP(targetCF)
    local bus = GetMyBus()
    if not bus then return end
    local primaryPart = GetPrimaryPart(bus)
    if not primaryPart then return end
    bus.PrimaryPart = primaryPart

    pcall(function() primaryPart:SetNetworkOwner(nil) end)

    local gyro = Instance.new("BodyGyro")
    gyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    gyro.D = 500
    gyro.P = 1e5
    gyro.CFrame = targetCF
    gyro.Parent = primaryPart

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

-- TweenDrive: gerak ke targetCF dengan kecepatan studs/s pakai BodyGyro buat orientasi
-- Returns true = selesai, false = _G.AutoFull dimatiin di tengah
local function TweenDrive(targetCF)
    local speed = math.max(_G.TweenSpeed, 1)
    local bus   = GetMyBus()
    if not bus then return false end
    local primaryPart = GetPrimaryPart(bus)
    if not primaryPart then return false end
    bus.PrimaryPart = primaryPart

    local dist     = (primaryPart.Position - targetCF.Position).Magnitude
    local duration = math.max(dist / speed, 0.5)

    pcall(function() primaryPart:SetNetworkOwner(nil) end)
    workspace.Gravity = 0
    primaryPart.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
    primaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

    local gyro = Instance.new("BodyGyro")
    gyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    gyro.D         = 300
    gyro.P         = 8e4
    gyro.CFrame    = targetCF
    gyro.Parent    = primaryPart

    local cfVal = Instance.new("CFrameValue")
    cfVal.Value = bus:GetPrimaryPartCFrame()

    local conn = cfVal.Changed:Connect(function(newCF)
        bus:PivotTo(newCF)
        primaryPart.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
        primaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)

    local tween = TweenService:Create(cfVal,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
        { Value = targetCF })
    tween:Play()

    local done = false
    tween.Completed:Connect(function() done = true end)
    while not done do
        if not _G.AutoFull then
            tween:Cancel()
            conn:Disconnect()
            cfVal:Destroy()
            gyro:Destroy()
            workspace.Gravity = 196.2
            return false
        end
        task.wait(0.2)
    end

    conn:Disconnect()
    cfVal:Destroy()
    gyro:Destroy()
    workspace.Gravity = 196.2
    return true
end

-- ArrivalDescent: teleport 100 studs atas CP, turun ke CP, lalu tahan arrivalDelay detik
local function ArrivalDescent(targetCF)
    local delay = _G.ArrivalDelay
    local bus   = GetMyBus()
    if not bus then return end
    local primaryPart = GetPrimaryPart(bus)
    if not primaryPart then return end
    bus.PrimaryPart = primaryPart

    local aboveCF = CFrame.new(targetCF.Position + Vector3.new(0, 100, 0))
        * (targetCF - targetCF.Position)
    bus:PivotTo(aboveCF)
    primaryPart.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
    primaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

    workspace.Gravity = 0
    local cfVal = Instance.new("CFrameValue")
    cfVal.Value = bus:GetPrimaryPartCFrame()

    local conn = cfVal.Changed:Connect(function(newCF)
        bus:PivotTo(newCF)
        primaryPart.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
        primaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)

    local tDescent = TweenService:Create(cfVal,
        TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Value = targetCF })
    tDescent:Play()
    tDescent.Completed:Wait()

    conn:Disconnect()
    cfVal:Destroy()
    workspace.Gravity = 196.2

    for i = delay, 1, -1 do
        if not _G.AutoFull then return end
        SetStatus("Arrival Delay: " .. i .. "s")
        task.wait(1)
    end
end

-- GotoCP: pipeline penuh untuk satu CP
-- 1) SpoofTP ke target
-- 2) Tunggu JobResumed dari server (timeout 90s), fallback tunggu 20s flat
-- 3) TweenDrive ke target
-- 4) ArrivalDescent (100 studs drop + arrivalDelay)
-- 5) Post-arrival wait 20 detik sebelum deteksi CP berikutnya
-- Returns false jika AutoFull dimatiin di tengah
local function GotoCP(targetCF, label)
    -- 1. Spoof
    SetStatus("Spoof → " .. label)
    SpoofTP(targetCF)

    -- 2. Tunggu JobResumed — kalau server kirim event, lanjut langsung.
    --    Kalau 20s timeout (server lambat / event miss), lanjut juga biar nggak stuck.
    SetStatus("Waiting Server Resume → " .. label)
    local resumed = waitForJobResumed(20)
    if not _G.AutoFull then return false end
    if not resumed then
        -- fallback: tunggu 20 detik flat
        for i = 20, 1, -1 do
            if not _G.AutoFull then return false end
            SetStatus("Post-Spoof Wait (fallback): " .. i .. "s")
            task.wait(1)
        end
    else
        SetStatus("Server Resumed — Driving → " .. label)
    end

    -- 3. TweenDrive
    SetStatus("Tween Drive → " .. label .. " @ " .. _G.TweenSpeed .. " studs/s")
    local ok = TweenDrive(targetCF)
    if not ok then return false end

    -- 4. ArrivalDescent + arrivalDelay
    SetStatus("Arrival Descent → " .. label)
    ArrivalDescent(targetCF)
    if not _G.AutoFull then return false end

    -- 5. Post-arrival standby 20 detik
    for i = 20, 1, -1 do
        if not _G.AutoFull then return false end
        SetStatus("Standby Next CP: " .. i .. "s")
        task.wait(1)
    end

    return true
end
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── UI ───────────────────────────────────────────────────────────────────────
local MainTab = Window:CreateTab("Main Farm", "play")
MainTab:CreateSection("Autofarm bus")
MainTab:CreateParagraph({
    Title   = "WARNING",
    Content = "USE JB5 ONLY, IF U USE OTHER BUS IT WILL DETECTED, TURN ON AUTO KICK WHEN STAFF JOINED",
})

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

        -- reset state setiap kali toggle on
        checkpointCount = 0
        lastStopSpoofed = false
        JobEvent.resumed        = false
        JobEvent.checkpointData = nil

        while _G.AutoFull do
            -- bersihkan objek Cikamurang/SInar yang bikin lag
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

            local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")

            -- ── Job Start ────────────────────────────────────────────────────
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
                        checkpointCount = 0
                        lastTarget      = nil
                        JobEvent.resumed        = false
                        JobEvent.checkpointData = nil
                    end
                end
            end

            -- ── Checkpoint Loop ──────────────────────────────────────────────
            local target = GetActiveStop()

            if target then
                noBillboardTime = 0
                lastStopSpoofed = false

                if target ~= lastTarget then
                    checkpointCount = checkpointCount + 1
                    local label = "CP#" .. checkpointCount .. " (" .. target.Name .. ")"

                    local ok = GotoCP(target.CFrame, label)
                    if not ok then break end

                    lastTarget = target
                end

            else
                -- ── Last Stop: Baranangsiang End ─────────────────────────────
                if jobStarted then
                    if not lastStopSpoofed then
                        SetStatus("Last Stop — driving to Baranangsiang End")
                        local ok = GotoCP(BaranangsangEndCF, "Baranangsiang End")
                        if not ok then break end
                        lastStopSpoofed = true
                    end

                    noBillboardTime = noBillboardTime + 1
                    SetStatus("Waiting Finish: " .. (30 - noBillboardTime) .. "s")

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
                        LP:Kick("money target reached: Rp " .. formatRS(currentMoney))
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

ConfigTab:CreateSection("Locomotion Settings")

ConfigTab:CreateSlider({
    Name         = "Tween Speed (studs/s)",
    Range        = { 0, 235 },
    Increment    = 1,
    Suffix       = " studs/s",
    CurrentValue = 150,
    Flag         = "TweenSpeedSlider",
    Callback     = function(Value)
        _G.TweenSpeed = Value
        SetStatus("Tween Speed: " .. Value .. " studs/s")
    end,
})

ConfigTab:CreateSlider({
    Name         = "Arrival Delay (s)",
    Range        = { 0, 120 },
    Increment    = 1,
    Suffix       = " s",
    CurrentValue = 45,
    Flag         = "ArrivalDelaySlider",
    Callback     = function(Value)
        _G.ArrivalDelay = Value
        SetStatus("Arrival Delay: " .. Value .. "s")
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
StatusLabel  = StatsTab:CreateLabel("Status: Waiting",                  "clock")
UangLabel    = StatsTab:CreateLabel("Uang: Rp " .. formatRS(StartUang), "banknote")
EarningLabel = StatsTab:CreateLabel("Earning: Rp 0",                    "coins")
TimeLabel    = StatsTab:CreateLabel("Time: 00:00:00",                   "timer")
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