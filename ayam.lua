local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = ".projectsion",
   LoadingTitle = "Bus Explorer Indonesia",
   LoadingSubtitle = "by .projectsion",
   Theme = "Bloom",
   ConfigurationSaving = { Enabled = true, FileName = "VoidlineConfig" },
   KeySystem = false,
})

local VirtualUser       = game:GetService("VirtualUser")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local LP                = Players.LocalPlayer
local Remotes           = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsFolder       = LP:WaitForChild("PlayerData")
local StartUang         = StatsFolder.Uang.Value
local StartTime         = os.time()
local CarData           = Remotes.GetClientCustomizationData:InvokeServer()
local OwnedCarsFolder   = LP:WaitForChild("PlayerData"):WaitForChild("OwnedCars")
local HttpService       = game:GetService("HttpService")

_G.AutoFull        = false
_G.AntiAFK         = true
_G.AutoRejoin      = false
_G.blackscreen     = false
_G.SelectedBus     = ""
_G.WebhookURL      = ""
_G.TotalEarning    = 0
_G.CycleCount      = 0
_G.StartTime       = os.time()
_G.WebhookEnabled  = false
local TargetUang        = 0
local lastMoney         = StatsFolder.Uang.Value
local SelectedBusToBuy  = ""
local CarListData       = {}
local pendingIncome     = 0
local SelectedAction    = "Dealership"
local SelectedTP        = "Dealership"
local isRunning         = false
local busOptions        = {}

-- ============================================================
-- 9-MINUTE TIMING CONSTANTS
-- 30s hold + 15s approach + 90s delay = 135s per stop
-- 4 stops × 135s = 540s = exactly 9 minutes
-- Tune DELAY_SECS if your route has more or fewer stops.
-- ============================================================
local HOLD_SECS     = 30   -- seconds the bus dwells at each stop (game registration)
local APPROACH_SECS = 15   -- approach window countdown
local DELAY_SECS    = 90   -- inter-stop delay — adjust for stop count vs target time
local AERIAL_HEIGHT = 1000 -- studs above map during transit
local DESCENT_TIME  = 8    -- seconds for final tween-down to stop
local HOLD_INTERVAL = 0.05 -- velocity-zero tick while stationary

local BlackScreen = Instance.new("ScreenGui")
local Frame       = Instance.new("Frame")
BlackScreen.Name         = "ProjectsionBlackout"
BlackScreen.Parent       = game:GetService("CoreGui")
BlackScreen.DisplayOrder = -1
BlackScreen.Enabled      = false
Frame.Parent           = BlackScreen
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.Size             = UDim2.new(1.5, 0, 1.5, 0)
Frame.Position         = UDim2.new(-0.25, 0, -0.25, 0)
Frame.BorderSizePixel  = 0

task.spawn(function()
    while task.wait(0.5) do BlackScreen.Enabled = _G.blackscreen end
end)

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
Players.PlayerAdded:Connect(function(p)
    if p == LP then return end
    task.wait(0.5); checkAndKick()
end)
task.spawn(function()
    while true do task.wait(3); checkAndKick() end
end)

local StatusLabel, UangLabel, EarningLabel, TimeLabel, FPSLabel, PingLabel

local function formatRS(n)
    local s = tostring(n)
    while true do
        s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return s
end

task.spawn(function()
    while task.wait(1) do
        if UangLabel then
            pcall(function()
                local u = StatsFolder.Uang.Value
                UangLabel:Set("Uang: Rp " .. formatRS(u))
                EarningLabel:Set("Earning: Rp " .. formatRS(u - StartUang))
                local d = os.time() - StartTime
                TimeLabel:Set(string.format("Time: %02d:%02d:%02d",
                    math.floor(d/3600), math.floor((d%3600)/60), d%60))
                local ping = tonumber(game:GetService("Stats").Network.ServerStatsItem
                    ["Data Ping"]:GetValueString():split(" ")[1]) or 0
                PingLabel:Set("Ping: " .. math.floor(ping) .. " ms")
                FPSLabel:Set("FPS: " .. math.floor(1 / task.wait()))
            end)
        end
    end
end)

for _, car in pairs(OwnedCarsFolder:GetChildren()) do
    if CarData.CarData_Cars[car.Name] then
        table.insert(busOptions, car.Name)
    end
end
if #busOptions == 0 then table.insert(busOptions, "Jetbus_3_RM _SHD") end
_G.SelectedBus = busOptions[1]

local jobStarted       = false
local noBillboardTime  = 0
local lastVisitedCF    = nil  -- tracks last stop CFrame we sent the bus to

local BaranangsangEndCF = CFrame.new(22732.02, 293.21, -39525.31)
    * CFrame.Angles(2.8307, -0.7276, 2.9293)

local TP_Locations = {
    ["Dealership"]    = CFrame.new(19830.625, 266.913116, -27910.4844,
        0.999847949, 0, 0.017436387, 0, 1, 0, -0.017436387, 0, 0.999847949),
    ["Modifikasi"]    = CFrame.new(12035.499, -21.3362789, 12740.0605,
        -0.573599219, 0, 0.81913656, 0, 1, 0, -0.81913656, 0, -0.573599219),
    ["Teleport City"] = CFrame.new(21795.2461, 292.439026, -40055.918,
        0.707134247, -0, -0.707079291, 0, 1, -0, 0.707079291, 0, 0.707134247)
}

LP.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

local function SetStatus(t)
    if StatusLabel then StatusLabel:Set("Status: " .. t) end
end

local function GetMyBus()
    return workspace.SpawnedVehicles:FindFirstChild(_G.SelectedBus)
end

-- ============================================================
-- STOP DETECTION — THREE TIERS, NO BILLBOARD USED ANYWHERE
--
-- TIER 1: ReplicatedStorage.General.MoveArrow OnClientEvent
--   The game's own next-destination signal — server-authoritative.
--   Same pattern used by CDI (Car Driving Indonesia).
--   If BEI fires this event, it's the cleanest source.
--
-- TIER 2: workspace.General.Waypoint CFrame polling
--   A BasePart the game moves to indicate next stop.
--   Same pattern used by CDI. BEI may share this architecture.
--
-- TIER 3: Pre-enumerated workspace.Checkpoints list
--   Reads all checkpoint parts' CFrames at job start.
--   Sorted by embedded number in part name (Checkpoint1, Stop3, etc).
--   No BusStop billboard state checked at any point.
--   Visited sequentially — advances on each stop completion.
-- ============================================================

local nextStopFromEvent = nil  -- populated by Tier 1 listener

local function trySetupMoveArrow()
    -- Silent — if MoveArrow doesn't exist in BEI, this just does nothing.
    pcall(function()
        local general = ReplicatedStorage:WaitForChild("General", 3)
        local arrow   = general:WaitForChild("MoveArrow", 3)
        arrow.OnClientEvent:Connect(function(pos)
            if typeof(pos) == "Vector3" and _G.AutoFull then
                nextStopFromEvent = CFrame.new(pos.X, pos.Y, pos.Z)
            end
        end)
    end)
end
task.spawn(trySetupMoveArrow)

local function getWorkspaceWaypoint()
    -- Tier 2: workspace.General.Waypoint (CDI pattern, may exist in BEI)
    local ok, cf = pcall(function()
        local wp = workspace.General.Waypoint
        if wp and wp:IsA("BasePart") then return wp.CFrame end
        return nil
    end)
    return ok and cf or nil
end

local orderedStops       = {}  -- built at job start (Tier 3 fallback)
local currentStopIndex   = 1

local function buildStopList()
    -- Read all checkpoint parts, sort by numeric suffix in name.
    -- No billboard state consulted — purely spatial data.
    local stops = {}
    for _, part in pairs(workspace.Checkpoints:GetChildren()) do
        local cf = nil
        if part:IsA("Model") then
            cf = part:GetPivot()
        elseif part:IsA("BasePart") then
            cf = part.CFrame
        end
        if cf then
            local num = tonumber(part.Name:match("%d+")) or 0
            table.insert(stops, { name = part.Name, num = num, cf = cf })
        end
    end
    table.sort(stops, function(a, b) return a.num < b.num end)
    return stops
end

local function getNextStopCFrame()
    -- Priority: Tier 1 → Tier 2 → Tier 3
    if nextStopFromEvent then
        local cf = nextStopFromEvent
        nextStopFromEvent = nil  -- consume — wait for next event
        return cf, "event"
    end

    local wpCF = getWorkspaceWaypoint()
    if wpCF then return wpCF, "waypoint" end

    if #orderedStops > 0 then
        local stop = orderedStops[currentStopIndex]
        if stop then
            return stop.cf, "list[" .. currentStopIndex .. "/" .. #orderedStops .. "]"
        end
    end

    return nil, "none"
end

local function advanceStopIndex()
    if currentStopIndex < #orderedStops then
        currentStopIndex = currentStopIndex + 1
    else
        currentStopIndex = 1  -- route looped, job finished externally
    end
end

-- ============================================================
-- MOVEMENT
-- ============================================================

local function AerialTP(targetCF)
    local bus = GetMyBus()
    if not bus then return end
    if not bus.PrimaryPart then
        bus.PrimaryPart = bus:FindFirstChildWhichIsA("BasePart")
    end
    if not bus.PrimaryPart then return end
    local primaryPart = bus.PrimaryPart

    for _, part in pairs(bus:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored                = false
            part.AssemblyLinearVelocity  = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end

    -- instant lift, instant lateral translate (1000 studs above, out of tracking range)
    local currentCF = bus:GetPivot()
    bus:PivotTo(currentCF + Vector3.new(0, AERIAL_HEIGHT, 0))
    task.wait()
    bus:PivotTo(targetCF + Vector3.new(0, AERIAL_HEIGHT, 0))
    task.wait()

    -- heartbeat-driven descent via CFrameValue tween (CDI pattern)
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
    lastVisitedCF = targetCF
end

local function HoldAtStop(duration)
    local bus     = GetMyBus()
    local elapsed = 0
    while elapsed < duration and _G.AutoFull do
        task.wait(HOLD_INTERVAL)
        elapsed = elapsed + HOLD_INTERVAL
        if bus then
            for _, part in pairs(bus:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then
                    part.AssemblyLinearVelocity  = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end
end

-- ============================================================
-- WEBHOOK
-- ============================================================

local function formatRP(v)
    local s = tostring(v)
    while true do
        s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return "Rp " .. s
end

local function getRunningTime()
    local d = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d", math.floor(d/3600), math.floor((d%3600)/60), d%60)
end

local function sendWebhook(income)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    _G.CycleCount   = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    local embed = {
        ["author"]  = { ["name"] = "Projectsion Webhook", ["icon_url"] =
            "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png" },
        ["title"]   = "Bus Route Completed",
        ["color"]   = 0xFFFFFF,
        ["fields"]  = {
            {["name"] = "Player",        ["value"] = LP.Name,                         ["inline"] = false},
            {["name"] = "Cycle Income",  ["value"] = formatRP(income),                ["inline"] = false},
            {["name"] = "Route",         ["value"] = "Cirebon → Baranangsiang",       ["inline"] = false},
            {["name"] = "Current Money", ["value"] = formatRP(StatsFolder.Uang.Value),["inline"] = false},
            {["name"] = "Total Earning", ["value"] = formatRP(_G.TotalEarning),       ["inline"] = false},
            {["name"] = "Cycle Count",   ["value"] = tostring(_G.CycleCount),         ["inline"] = false},
            {["name"] = "Running Time",  ["value"] = getRunningTime(),                ["inline"] = false},
        },
        ["footer"]  = { ["text"] = "Made By Projectsion | " .. os.date("%m/%d/%Y %I:%M %p") }
    }
    if http_request then
        pcall(function()
            http_request({
                Url     = _G.WebhookURL,
                Method  = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body    = HttpService:JSONEncode({ ["username"] = "Projectsion Reports", ["embeds"] = { embed } })
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
                        sendWebhook(pendingIncome); pendingIncome = 0
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
    for carID in pairs(ClientData.CarData_Cars) do table.insert(CarListData, carID) end
    table.sort(CarListData)
end

-- ============================================================
-- UI
-- ============================================================

local MainTab = Window:CreateTab("Main Farm", "play")
MainTab:CreateSection("Autofarm bus")
MainTab:CreateParagraph({
    Title   = "WARNING",
    Content = "USE JB5 ONLY. Billboard detection bypassed — uses MoveArrow/Waypoint/ordered-list. 9 min route at 4 stops × 135s."
})

MainTab:CreateToggle({
    Name         = "On Autofarm",
    CurrentValue = false,
    Callback     = function(Value)
        _G.AutoFull = Value

        if not Value then
            jobStarted      = false
            noBillboardTime = 0
            currentStopIndex = 1
            lastVisitedCF   = nil
            workspace.Gravity = 196.2
            SetStatus("Idle")
            return
        end

        -- zero gravity for the session — AerialTP lifts out of range before lateral move
        workspace.Gravity = 0

        while _G.AutoFull do
            pcall(function()
                local cikamurang = workspace:FindFirstChild("Cikamurang")
                if cikamurang then
                    local m = cikamurang:FindFirstChild("model") or cikamurang:FindFirstChild("Model")
                    if m then
                        local t = m:WaitForChild("SInar", 0.1)
                        if t then t:Destroy() end
                    end
                end
            end)

            local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
            local infoLabel = LP.PlayerGui:FindFirstChild("BusJobGUI")
                and LP.PlayerGui.BusJobGUI.JobStatusFrame.InfoLabel

            -- ── JOB SETUP ──────────────────────────────────────────────
            if not jobStarted then
                SetStatus("Spawning: " .. _G.SelectedBus)
                Remotes:WaitForChild("SpawnCar"):FireServer(_G.SelectedBus)
                task.wait(4)

                local bus = GetMyBus()
                if bus and bus:FindFirstChild("DriveSeat") then
                    bus.DriveSeat:Sit(hum)
                    task.wait(2)

                    SetStatus("Getting job...")
                    Remotes:WaitForChild("StartBusJob"):InvokeServer("Cirebon_Baranangsiang4", nil)
                    task.wait(1)

                    hum.Jump = true
                    task.wait(1.5)

                    SetStatus("Re-spawning vehicle...")
                    Remotes:WaitForChild("SpawnCar"):FireServer(_G.SelectedBus)
                    task.wait(4)
                    bus = GetMyBus()

                    if bus and bus:FindFirstChild("DriveSeat") then
                        bus.DriveSeat:Sit(hum)

                        -- Build stop list from workspace.Checkpoints (no billboard)
                        orderedStops     = buildStopList()
                        currentStopIndex = 1

                        -- Log tier being used so user can diagnose
                        if nextStopFromEvent then
                            SetStatus("Stop source: MoveArrow event (Tier 1)")
                        elseif getWorkspaceWaypoint() then
                            SetStatus("Stop source: Workspace Waypoint (Tier 2)")
                        else
                            SetStatus("Stop source: Checkpoint list (" .. #orderedStops .. " stops, Tier 3)")
                        end

                        task.wait(1)
                        jobStarted = true
                    end
                end
            end

            -- ── STOP DETECTION (no billboard) ───────────────────────────
            local targetCF, tier = getNextStopCFrame()

            if targetCF then
                noBillboardTime = 0

                -- skip if we're already at this exact stop (same CFrame object)
                if lastVisitedCF ~= targetCF then

                    SetStatus("Approaching stop [" .. tier .. "]...")
                    AerialTP(targetCF)

                    -- HOLD: bus at stop, game registers presence
                    for i = 1, HOLD_SECS do
                        if not _G.AutoFull then break end
                        if infoLabel and string.find(string.upper(infoLabel.Text), "RETURN TO THE CHECKPOINT") then
                            SetStatus("Correction: re-approaching [" .. tier .. "]...")
                            AerialTP(targetCF)
                        else
                            SetStatus("At stop [" .. tier .. "] — " .. (HOLD_SECS - i + 1) .. "s")
                        end
                        HoldAtStop(1)
                    end

                    -- APPROACH WINDOW countdown
                    for i = APPROACH_SECS, 1, -1 do
                        if not _G.AutoFull then break end
                        SetStatus("Next stop in: " .. i .. "s")
                        HoldAtStop(1)
                    end

                    -- advance Tier 3 index for next iteration
                    advanceStopIndex()

                    -- INTER-STOP DELAY (tune for 9-min total)
                    for i = DELAY_SECS, 1, -1 do
                        if not _G.AutoFull then break end
                        SetStatus("Delay: " .. i .. "s | stop " ..
                            currentStopIndex .. "/" .. #orderedStops)
                        HoldAtStop(1)
                    end
                end

            else
                -- No stop signal from any tier — route likely complete
                if jobStarted then
                    noBillboardTime = noBillboardTime + 1
                    SetStatus("No stop signal: " .. (20 - noBillboardTime) .. "s until finish")

                    if noBillboardTime >= 20 then
                        SetStatus("Finishing route...")
                        AerialTP(BaranangsangEndCF)
                        task.wait(2)

                        jobStarted       = false
                        currentStopIndex = 1
                        noBillboardTime  = 0
                        lastVisitedCF    = nil

                        local bus = GetMyBus()
                        if bus then bus:Destroy() end

                        SetStatus("Job done! Restarting...")
                        task.wait(3)
                    end
                end
            end

            task.wait(1)
        end

        workspace.Gravity = 196.2  -- restore when loop exits
    end
})

MainTab:CreateToggle({
    Name = "Black Screen", CurrentValue = false, Flag = "BlackScreen",
    Callback = function(v) _G.blackscreen = v end,
})

MainTab:CreateSection("Timing Tuning — Target 9 Minutes")
MainTab:CreateParagraph({
    Title   = "Timing Guide",
    Content = "4 stops: DELAY=90s → 9 min\n5 stops: DELAY=63s → 9 min\n6 stops: DELAY=45s → 9 min\nAdjust DELAY_SECS in script header."
})

MainTab:CreateSection("Auto Stop Settings")

MainTab:CreateInput({
   Name = "Set Target Money", PlaceholderText = "input your target",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      TargetUang = tonumber(Text:gsub("%.", "")) or 0
      Rayfield:Notify({ Title = "Target Set", Content = "Rp " .. formatRS(TargetUang), Duration = 3 })
   end,
})

MainTab:CreateToggle({
   Name = "Enable Auto-Kick", CurrentValue = false, Flag = "AutoKick",
   Callback = function(v)
      if v then
          task.spawn(function()
              while v do
                  if TargetUang > 0 and StatsFolder.Uang.Value >= TargetUang then
                      LP:Kick("\n[VoidlineHub]\nTarget reached! Rp " .. formatRS(StatsFolder.Uang.Value))
                      break
                  end
                  task.wait(2)
              end
          end)
      end
   end,
})

local ConfigTab = Window:CreateTab("Configuration", "settings")
ConfigTab:CreateSection("Select Spawner Vehicle")

local BusDropdown = ConfigTab:CreateDropdown({
   Name = "Select Owned Bus", Options = busOptions, CurrentOption = {busOptions[1]},
   MultipleOptions = false,
   Callback = function(Option) _G.SelectedBus = Option[1]; SetStatus("Selected: " .. _G.SelectedBus) end,
})

ConfigTab:CreateButton({
   Name = "Refresh Garage List",
   Callback = function()
       local opts = {}
       for _, c in pairs(OwnedCarsFolder:GetChildren()) do table.insert(opts, c.Name) end
       BusDropdown:Set(opts)
   end,
})

ConfigTab:CreateSection("Webhook")

ConfigTab:CreateInput({
   Name = "Discord Webhook URL", PlaceholderText = "Paste URL Here",
   RemoveTextAfterFocusLost = false,
   Callback = function(t)
      _G.WebhookURL = t
      Rayfield:Notify({ Title = "Webhook Updated", Content = "URL saved.", Duration = 3, Image = "link" })
   end,
})

ConfigTab:CreateToggle({
   Name = "Enable Webhook Report", CurrentValue = false,
   Callback = function(v)
      _G.WebhookEnabled = v
      if v and (_G.WebhookURL == "" or not _G.WebhookURL:find("discord.com")) then
          Rayfield:Notify({ Title = "Webhook Error", Content = "Enter a valid Discord URL first!", Duration = 5, Image = "alert-triangle" })
      end
   end,
})

local StatsTab = Window:CreateTab("Stats", "trending-up")
StatsTab:CreateSection("Info Farm")
StatusLabel  = StatsTab:CreateLabel("Status: Waiting", "clock")
UangLabel    = StatsTab:CreateLabel("Uang: Rp " .. StartUang, "banknote")
EarningLabel = StatsTab:CreateLabel("Earning: Rp 0", "coins")
TimeLabel    = StatsTab:CreateLabel("Time: 00:00:00", "timer")
StatsTab:CreateSection("System Info")
FPSLabel  = StatsTab:CreateLabel("FPS: Scanning...", "monitor")
PingLabel = StatsTab:CreateLabel("Ping: Scanning...", "wifi")

local MoreTab = Window:CreateTab("More Features", "plus-circle")
MoreTab:CreateSection("important features")

MoreTab:CreateToggle({
   Name = "Anti-AFK System", CurrentValue = true, Flag = "AntiAFK",
   Callback = function(v) _G.AntiAFK = v; SetStatus(v and "Anti-AFK ON" or "Anti-AFK OFF") end,
})

MoreTab:CreateToggle({
   Name = "Auto Rejoin", CurrentValue = false, Flag = "AutoRejoin",
   Callback = function(v) _G.AutoRejoin = v end,
})

MoreTab:CreateSection("Visual & Performance")

-- Guard: "Hide All Names" destroys BillboardGuis in workspace.
-- With no-billboard mode, this is now SAFE to run even during farm
-- because detection never reads BillboardGui state.
-- Guard still shown for awareness — user chooses.
MoreTab:CreateButton({
   Name = "Hide All Names",
   Callback = function()
      for _, v in pairs(workspace:GetDescendants()) do
          if v:IsA("BillboardGui") then v:Destroy() end
      end
      SetStatus("Names Hidden (safe — billboard detection not used)")
   end,
})

MoreTab:CreateToggle({
   Name = "Hide Character", CurrentValue = false, Flag = "HideChar",
   Callback = function(v)
      local c = LP.Character
      if c then
          for _, p in pairs(c:GetDescendants()) do
              if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency = v and 1 or 0 end
          end
      end
   end,
})

MoreTab:CreateButton({
   Name = "FPS Boost",
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
   Name = "Select Bus to Purchase", Options = CarListData,
   CurrentOption = {CarListData[1] or "None"}, MultipleOptions = false,
   Callback = function(o) SelectedBusToBuy = o[1] end,
})

MoreTab:CreateButton({
   Name = "Purchase Selected Bus",
   Callback = function()
      if SelectedBusToBuy == "" or SelectedBusToBuy == "None" then
          Rayfield:Notify({ Title = "Error", Content = "Select a bus first!", Duration = 3 }); return
      end
      local ok, err = pcall(function() Remotes:WaitForChild("BuyCar"):FireServer(SelectedBusToBuy) end)
      SetStatus(ok and ("Bought " .. SelectedBusToBuy) or "Purchase Failed!")
      if not ok then warn(tostring(err)) end
   end,
})

MoreTab:CreateSection("World Teleport")

MoreTab:CreateDropdown({
   Name = "Select TP Destination", Options = {"Dealership","Modifikasi","Teleport City"},
   CurrentOption = {"Dealership"}, MultipleOptions = false,
   Callback = function(o) SelectedTP = o[1] end,
})

MoreTab:CreateButton({
   Name = "Teleport Now",
   Callback = function()
      if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
          LP.Character:PivotTo(TP_Locations[SelectedTP])
          SetStatus("Teleported to " .. SelectedTP)
      end
   end,
})

MoreTab:CreateSection("Open UI / Actions")

MoreTab:CreateDropdown({
   Name = "Select Menu to Open", Options = {"Dealership","Modifikasi","Teleport City"},
   CurrentOption = {"Dealership"}, MultipleOptions = false,
   Callback = function(o) SelectedAction = o[1] end,
})

MoreTab:CreateButton({
   Name = "Open Selected Menu",
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