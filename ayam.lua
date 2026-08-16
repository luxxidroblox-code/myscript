local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = ".projectsion",
   LoadingTitle = "Bus Explorer Indonesia",
   LoadingSubtitle = "by .projectsion",
   Theme = "Bloom",
   ConfigurationSaving = {
      Enabled = true,
      FileName = "VoidlineConfig"
   },
   KeySystem = false,
})

local VirtualUser    = game:GetService("VirtualUser")
local TweenService   = game:GetService("TweenService")
local Players        = game:GetService("Players")
local LP             = Players.LocalPlayer
local Remotes        = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsFolder    = LP:WaitForChild("PlayerData")
local StartUang      = StatsFolder.Uang.Value
local StartTime      = os.time()
local CarData        = Remotes.GetClientCustomizationData:InvokeServer()
local OwnedCarsFolder = LP:WaitForChild("PlayerData"):WaitForChild("OwnedCars")
local HttpService    = game:GetService("HttpService")

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
local TargetUang        = 0
local lastMoney         = StatsFolder.Uang.Value
local SelectedBusToBuy  = ""
local CarListData       = {}
local pendingIncome     = 0
local SelectedAction    = "Dealership"
local SelectedTP        = "Dealership"
local isRunning         = false
local busOptions        = {}

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
    while task.wait(0.5) do
        BlackScreen.Enabled = _G.blackscreen
    end
end)

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

Players.PlayerAdded:Connect(function(player)
    if player == LP then return end
    task.wait(0.5)
    checkAndKick()
end)

task.spawn(function()
    while true do
        task.wait(3)
        checkAndKick()
    end
end)

local StatusLabel, UangLabel, EarningLabel, TimeLabel, FPSLabel, PingLabel

local function formatRS(amount)
    local formatted = tostring(amount)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if (k == 0) then break end
    end
    return formatted
end

task.spawn(function()
    while task.wait(1) do
        if UangLabel then
            pcall(function()
                local currentUang = StatsFolder.Uang.Value
                UangLabel:Set("Uang: Rp " .. formatRS(currentUang))
                EarningLabel:Set("Earning: Rp " .. formatRS(currentUang - StartUang))
                local diff = os.time() - StartTime
                local h = math.floor(diff / 3600)
                local m = math.floor((diff % 3600) / 60)
                local s = diff % 60
                TimeLabel:Set(string.format("Time: %02d:%02d:%02d", h, m, s))
                local ping = tonumber(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString():split(" ")[1]) or 0
                PingLabel:Set("Ping: " .. math.floor(ping) .. " ms")
                local fps = math.floor(1 / task.wait())
                FPSLabel:Set("FPS: " .. fps)
            end)
        end
    end
end)

for _, car in pairs(OwnedCarsFolder:GetChildren()) do
    local carID   = car.Name
    local carInfo = CarData.CarData_Cars[carID]
    if carInfo then table.insert(busOptions, carID) end
end

if #busOptions == 0 then table.insert(busOptions, "Jetbus_3_RM _SHD") end
_G.SelectedBus = busOptions[1]

local lastTarget      = nil
local noBillboardTime = 0
local jobStarted      = false

local BaranangsangEndCF = CFrame.new(22732.02, 293.21, -39525.31) * CFrame.Angles(2.8307, -0.7276, 2.9293)

local TP_Locations = {
    ["Dealership"]    = CFrame.new(19830.625,  266.913116, -27910.4844, 0.999847949, 0, 0.017436387, 0, 1, 0, -0.017436387, 0, 0.999847949),
    ["Modifikasi"]    = CFrame.new(12035.499,  -21.3362789, 12740.0605, -0.573599219, 0, 0.81913656, 0, 1, 0, -0.81913656, 0, -0.573599219),
    ["Teleport City"] = CFrame.new(21795.2461, 292.439026, -40055.918,  0.707134247, -0, -0.707079291, 0, 1, -0, 0.707079291, 0, 0.707134247)
}

game.Players.LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        warn("anti afk nyala tenang be")
    end
end)

local function SetStatus(text)
    if StatusLabel then StatusLabel:Set("Status: " .. text) end
end

local function GetMyBus()
    return workspace.SpawnedVehicles:FindFirstChild(_G.SelectedBus)
end

-- ============================================================
-- AERIAL_HEIGHT : studs above map during aerial transit.
--   Server never sees a ground-level position jump.
--   Instant moves happen at sky height where nothing is tracked.
-- DESCENT_TIME  : seconds for the final tween down to the stop.
--   Heartbeat-driven via CFrameValue.Changed â€” same pattern as CDI script.
-- ============================================================
local AERIAL_HEIGHT  = 1000
local DESCENT_TIME   = 5    -- tune: faster = snappier, slower = safer

-- ============================================================
-- AerialTP
--   1. Instant lift to current + AERIAL_HEIGHT  (above map, out of range)
--   2. Instant translate to target + AERIAL_HEIGHT  (still above map)
--   3. TweenService descent to target over DESCENT_TIME seconds
--      CFrameValue.Changed fires every heartbeat â†’ position updated
--      every frame, velocity zeroed every frame â€” no anchor needed.
-- workspace.Gravity must be 0 before calling (set at farm start).
-- ============================================================
local function AerialTP(targetCF)
    local bus = GetMyBus()
    if not bus then return end

    if not bus.PrimaryPart then
        bus.PrimaryPart = bus:FindFirstChildWhichIsA("BasePart")
    end
    if not bus.PrimaryPart then return end

    local primaryPart = bus.PrimaryPart

    -- clear anchors and any residual velocity
    for _, part in pairs(bus:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored                = false
            part.AssemblyLinearVelocity  = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end

    -- instant lift â€” gravity is 0, bus floats at whatever height we set
    local currentCF = bus:GetPivot()
    bus:PivotTo(currentCF + Vector3.new(0, AERIAL_HEIGHT, 0))
    task.wait()

    -- instant lateral translate â€” still 1000 studs above the target
    bus:PivotTo(targetCF + Vector3.new(0, AERIAL_HEIGHT, 0))
    task.wait()

    -- heartbeat-driven descent via CFrameValue tween (from CDI script)
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

    -- interruptible wait â€” exits early if farm is toggled off
    while tween.PlaybackState ~= Enum.PlaybackState.Completed and _G.AutoFull do
        task.wait(0.1)
    end
    if tween.PlaybackState ~= Enum.PlaybackState.Completed then
        tween:Cancel()
    end

    conn:Disconnect()
    cfVal:Destroy()
    bus:PivotTo(targetCF)
end

-- ============================================================
-- HoldAtStop
--   Zeros velocity every HOLD_INTERVAL while stopped at a checkpoint.
--   Gravity is 0 during farming so there's no gravitational drift â€”
--   this handles any residual physics forces only.
-- ============================================================
local HOLD_INTERVAL = 0.05

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
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png"
end

local function formatRP(v)
    local formatted = tostring(v)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if (k == 0) then break end
    end
    return "Rp " .. formatted
end

local function getRunningTime()
    local diff = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d", math.floor(diff/3600), math.floor((diff%3600)/60), diff%60)
end

local function sendWebhook(income, target)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end

    _G.CycleCount   = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income

    local currentMoney = StatsFolder.Uang.Value
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)

    local embed = {
        ["author"] = { ["name"] = "Projectsion Webhook", ["icon_url"] = getAvatar() },
        ["title"]  = "Bus Route Completed",
        ["color"]  = 0xFFFFFF,
        ["fields"] = {
            {["name"] = "protected",     ["value"] = LP.Name,                          ["inline"] = false},
            {["name"] = "Cycle Income",  ["value"] = formatRP(income),                 ["inline"] = false},
            {["name"] = "Target",        ["value"] = "Cirebon â†’ Baranangsiang Route",  ["inline"] = false},
            {["name"] = "Current Money", ["value"] = formatRP(currentMoney),           ["inline"] = false},
            {["name"] = "Total Earning", ["value"] = formatRP(_G.TotalEarning),        ["inline"] = false},
            {["name"] = "Cycle Count",   ["value"] = tostring(_G.CycleCount),          ["inline"] = false},
            {["name"] = "Running Time",  ["value"] = getRunningTime(),                 ["inline"] = false}
        },
        ["image"]  = { ["url"] = "https://cdn.discordapp.com/attachments/1492837859370074192/1508063383944036433/IMG_20260524_180509.jpg?ex=6a142cf9&is=6a12db79&hm=124ec4dccb5d72326d9b0776d912bb18631948f41162cd9fa6d08eafcff19fb4&" },
        ["footer"] = { ["text"] = "Made By Projectsion | " .. os.date("%m/%d/%Y %I:%M %p") }
    }

    local payload = HttpService:JSONEncode({
        ["username"] = "Projectsion Reports",
        ["embeds"]   = { embed }
    })

    if http_request then
        pcall(function()
            http_request({
                Url     = _G.WebhookURL,
                Method  = "POST",
                Headers = {["Content-Type"] = "application/json"},
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
                    if pendingIncome > 0 and _G.WebhookURL ~= "" and _G.WebhookEnabled then
                        sendWebhook(pendingIncome, 0)
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
    for carID, data in pairs(ClientData.CarData_Cars) do
        table.insert(CarListData, carID)
    end
    table.sort(CarListData)
end

local MainTab = Window:CreateTab("Main Farm", "play")
MainTab:CreateSection("Autofarm bus")
MainTab:CreateParagraph({
    Title   = "WARNING",
    Content = "USE JB5 ONLY, IF U USE OTHER BUS IT WILL DETECTED, TURN ON AUTO KICK WHEN STAFF JOINED"
})
MainTab:CreateToggle({
    Name         = "On Autofarm",
    CurrentValue = false,
    Callback     = function(Value)
        _G.AutoFull = Value

        if not Value then
            lastTarget    = nil
            jobStarted    = false
            workspace.Gravity = 196.2   -- restore gravity on manual stop
            SetStatus("Idle")
            return
        end

        -- zero gravity for the entire farming session â€”
        -- AerialTP lifts the bus above map, moves laterally, tweens down.
        -- gravity 0 means the bus floats at whatever height we set instantly.
        workspace.Gravity = 0

        while _G.AutoFull do
            pcall(function()
                local cikamurang = workspace:FindFirstChild("Cikamurang")
                if cikamurang then
                    local folderModel = cikamurang:FindFirstChild("model") or cikamurang:FindFirstChild("Model")
                    if folderModel then
                        local targetHapus = folderModel:WaitForChild("SInar", 0.1)
                        if targetHapus then targetHapus:Destroy() end
                    end
                end
            end)

            local hum      = LP.Character and LP.Character:FindFirstChild("Humanoid")
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

                    SetStatus("Invoke job...")
                    Remotes:WaitForChild("StartBusJob"):InvokeServer("Cirebon_Baranangsiang4", nil)
                    task.wait(1)

                    hum.Jump = true
                    task.wait(1.5)

                    SetStatus("Spawning vehicle..")
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

                    -- lift above map â†’ translate above stop â†’ tween down
                    SetStatus("Aerial approach...")
                    AerialTP(target.CFrame)

                    -- 30s presence hold at stop, velocity zeroed each tick
                    for i = 1, 20 do
                        if not _G.AutoFull then break end
                        if infoLabel and string.find(string.upper(infoLabel.Text), "RETURN TO THE CHECKPOINT") then
                            SetStatus("Correction: re-approaching...")
                            AerialTP(target.CFrame)
                        else
                            SetStatus("Position confirmed...")
                        end
                        HoldAtStop(1)
                    end

                    -- 15s window before next stop
                    for i = 10, 1, -1 do
                        if not _G.AutoFull then break end
                        SetStatus("Next stop in: " .. i .. "s")
                        HoldAtStop(1)
                    end

                    -- 90s inter-stop delay
                    for i = 58, 1, -1 do
                        if not _G.AutoFull then break end
                        SetStatus("Delay TP: " .. i .. "s")
                        HoldAtStop(1)
                    end
                end
            else
                if jobStarted then
                    noBillboardTime = noBillboardTime + 1
                    SetStatus("Searching Stop: " .. (20 - noBillboardTime) .. "s")

                    if noBillboardTime >= 20 then
                        SetStatus("Finishing Job...")
                        AerialTP(BaranangsangEndCF)

                        task.wait(2)
                        jobStarted      = false
                        lastTarget      = nil
                        noBillboardTime = 0

                        local bus = GetMyBus()
                        if bus then bus:Destroy() end

                        SetStatus("Job Finished! Restarting...")
                        task.wait(3)
                    end
                end
            end
            task.wait(1)
        end

        workspace.Gravity = 196.2   -- restore when loop exits naturally
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
   Name                    = "Set Target Money",
   PlaceholderText         = "input your target",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      local cleanNumber = Text:gsub("%.", "")
      TargetUang = tonumber(cleanNumber) or 0
      Rayfield:Notify({
         Title   = "Target Set",
         Content = "money target is set to: Rp " .. formatRS(TargetUang),
         Duration = 3
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
                      LP:Kick("\n[VoidlineHub]\nTarget money reached!\nTotal: Rp " .. formatRS(currentMoney))
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
   Name            = "Select Owned Bus",
   Options         = busOptions,
   CurrentOption   = {busOptions[1]},
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
   Name                    = "Discord Webhook URL",
   PlaceholderText         = "Paste URL Here",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      _G.WebhookURL = Text
      Rayfield:Notify({
         Title   = "Webhook Updated",
         Content = "URL has been saved.",
         Duration = 3,
         Image   = "link",
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

-- Guard: GetActiveStop() relies on BillboardGui.Enabled â€”
-- destroying them during autofarm silences the stop detector.
MoreTab:CreateButton({
   Name     = "Hide All Names",
   Callback = function()
      if _G.AutoFull then
          Rayfield:Notify({
              Title    = "Blocked",
              Content  = "Turn off autofarm first â€” BillboardGui destruction breaks stop detection.",
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
   CurrentOption   = {CarListData[1] or "None"},
   MultipleOptions = false,
   Callback        = function(Option)
      SelectedBusToBuy = Option[1]
   end,
})

MoreTab:CreateButton({
   Name     = "Purchase Selected Bus",
   Callback = function()
      if SelectedBusToBuy == "" or SelectedBusToBuy == "None" then
          Rayfield:Notify({Title = "Error", Content = "Please select a bus first!", Duration = 3})
          return
      end
      Rayfield:Notify({
         Title   = "Confirm Purchase",
         Content = "Buying: " .. SelectedBusToBuy .. ". Please wait...",
         Duration = 5,
         Image   = "shopping-cart",
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
   Options         = {"Dealership", "Modifikasi", "Teleport City"},
   CurrentOption   = {"Dealership"},
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
   Options         = {"Dealership", "Modifikasi", "Teleport City"},
   CurrentOption   = {"Dealership"},
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