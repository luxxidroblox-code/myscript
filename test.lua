local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
loadstring(game:HttpGet('https://raw.githubusercontent.com/LynX99-9/komtolmmek2/refs/heads/main/Adonis'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local SpawnCarEvents = ReplicatedStorage:WaitForChild("SpawnCarEvents")
local TaxiAssets = ReplicatedStorage:WaitForChild("TaxiAssets")
local TaxiEvent = TaxiAssets.Events:WaitForChild("TaxiEvent")
local NotifSound = ReplicatedStorage:WaitForChild("Notification"):WaitForChild("Notif2Sound")

local ScrollingFrame = LocalPlayer.PlayerGui:WaitForChild("MainUI").Frame.MainFrame.ScrollingFrame

local Window = Rayfield:CreateWindow({
    Name = "Auto Taxi",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by you",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AutoTaxi",
        FileName = "Config"
    },
    KeySystem = false,
})

local Tab = Window:CreateTab("Main", nil)

local jobRunning = false
local vehicleName = nil
local currentToken = nil
local isOnline = false

-- ============ SCAN VEHICLE LIST ============

local function getVehicleList()
    local list = {}
    for _, child in ipairs(ScrollingFrame:GetChildren()) do
        local isButton = child:IsA("TextButton") or child:IsA("ImageButton")
        if isButton and not child.Name:lower():match("ui") then
            table.insert(list, child.Name)
        end
    end
    return list
end

local vehicleList = getVehicleList()
if #vehicleList > 0 then
    vehicleName = vehicleList[1]
end

-- ============ HELPER FUNCTIONS ============

local function findVehicle()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name:match("^LikasturaMontors_") then
            return obj
        end
    end
    return nil
end

local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart"), char
end

-- FIX 1: getHRP() returns (hrp, char) — original code discarded char, causing
-- the sit check later to reference a stale or nil humanoid.
local function sitOnVehicle(vehicle)
    local driveSeat = vehicle:FindFirstChild("DriveSeat")
    if not driveSeat then
        warn("[DEBUG] DriveSeat TIDAK ditemukan di", vehicle.Name)
        return false
    end

    local hrp, char = getHRP()
    hrp.CFrame = driveSeat.CFrame * CFrame.new(0, 3, 0)
    task.wait(0.3)

    local prompt = driveSeat:FindFirstChild("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
    else
        warn("[DEBUG] ProximityPrompt TIDAK ditemukan di DriveSeat")
    end
    return true
end

local function spawnAndSit(name)
    if not name then return false end

    SpawnCarEvents.SpawnCar:FireServer(name)
    task.wait(2)

    local vehicle = findVehicle()
    local tries = 0
    while not vehicle and tries < 10 do
        task.wait(0.5)
        vehicle = findVehicle()
        tries += 1
    end

    if vehicle then
        sitOnVehicle(vehicle)
        return true
    end
    warn("[DEBUG] vehicle GAGAL ditemukan setelah", tries, "percobaan")
    return false
end

local function goOnline()
    if isOnline then return end
    TaxiEvent:FireServer("GoOnline")
    isOnline = true
end

local function acceptOrder(token)
    if not token then return end
    TaxiEvent:FireServer("AcceptOrder", token)
end

local tweenDuration = 20

-- FIX 2: Original tween used CFrame.new(targetPos) which zeros rotation — vehicle
-- would snap to a flat orientation on arrival. Now preserves current rotation.
-- FIX 3: RunService.Stepped zeroing Velocity every frame conflicts with TweenService
-- interpolation under Roblox physics, causing stutter/snap. Replaced with manual
-- Heartbeat lerp so there's no physics engine fighting the position update.
local function tweenToTarget()
    local target = workspace:WaitForChild("ActiveMissions", 10)
    if not target then
        warn("[DEBUG] ActiveMissions TIDAK ditemukan")
        return
    end

    local guideTarget = target:WaitForChild("RideGO_GuideTarget", 10)
    if not guideTarget then
        warn("[DEBUG] RideGO_GuideTarget TIDAK ditemukan")
        return
    end

    local vehicle = findVehicle()
    if not vehicle then
        warn("[DEBUG] vehicle tidak ditemukan, batalkan tween")
        return
    end

    local basePart = vehicle:FindFirstChild("DriveSeat") or vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
    if not basePart then
        warn("[DEBUG] tidak ada BasePart di vehicle")
        return
    end

    -- Disable collision while moving
    local originalCollide = {}
    for _, part in ipairs(vehicle:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollide[part] = part.CanCollide
            part.CanCollide = false
        end
    end

    local targetPos = guideTarget.Position
    local startCFrame = basePart.CFrame
    -- Preserve rotation, only move position
    local targetCFrame = CFrame.new(targetPos) * (startCFrame - startCFrame.Position)

    local elapsed = 0
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        local alpha = math.min(elapsed / tweenDuration, 1)
        -- Smooth step for less robotic feel than linear
        local t = alpha * alpha * (3 - 2 * alpha)

        pcall(function()
            basePart.CFrame = startCFrame:Lerp(targetCFrame, t)
        end)

        -- Keep humanoid seated during move
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and not hum.Sit then
            pcall(function() hum.Sit = true end)
        end

        if alpha >= 1 then
            connection:Disconnect()

            -- Restore collision
            for part, wasCollide in pairs(originalCollide) do
                pcall(function() part.CanCollide = wasCollide end)
            end

            warn("[DEBUG] tween selesai, collision dikembalikan")
        end
    end)

    -- Block until done
    while connection.Connected do
        task.wait(0.1)
    end
end

local tripActive = false

local function tripLoop()
    if tripActive then return end
    tripActive = true

    local lastPos = nil

    while tripActive and jobRunning do
        local target = workspace:FindFirstChild("ActiveMissions")
        local guideTarget = target and target:FindFirstChild("RideGO_GuideTarget")

        if guideTarget then
            local pos = guideTarget.Position
            if not lastPos or (pos - lastPos).Magnitude > 5 then
                lastPos = pos
                tweenToTarget()
            end
        else
            if lastPos then
                warn("[DEBUG] guideTarget hilang, trip selesai")
                lastPos = nil
            end
        end

        task.wait(1)
    end

    tripActive = false
end

-- ============ AUTO JOB LOOP ============

local function autoJobLoop()
    local vehicle = findVehicle()
    if not vehicle then
        spawnAndSit(vehicleName)
        vehicle = findVehicle()
    else
        sitOnVehicle(vehicle)
    end

    if vehicle then
        task.wait(0.5)
        goOnline()

        vehicle.AncestryChanged:Connect(function(_, parent)
            if not parent then
                warn("[DEBUG] vehicle terhapus, reset isOnline")
                isOnline = false
            end
        end)
    else
        warn("[DEBUG] vehicle tidak ditemukan, batalkan go online")
    end
end

if _G.__AutoTaxiConn then
    _G.__AutoTaxiConn:Disconnect()
    _G.__AutoTaxiConn = nil
end
if _G.__AutoTaxiNotifConn then
    _G.__AutoTaxiNotifConn:Disconnect()
    _G.__AutoTaxiNotifConn = nil
end

-- ============ LISTEN NOTIF SOUND ============

_G.__AutoTaxiNotifConn = NotifSound.OnClientEvent:Connect(function()
    warn("[DEBUG] Notif2Sound triggered -> orderan masuk")
end)

-- ============ LISTEN INCOMING ORDER ============

local function printTable(t, indent)
    indent = indent or "   "
    for k, v in pairs(t) do
        if typeof(v) == "table" then
            warn("[DEBUG]" .. indent .. tostring(k) .. " = {")
            printTable(v, indent .. "   ")
            warn("[DEBUG]" .. indent .. "}")
        else
            warn("[DEBUG]" .. indent .. tostring(k) .. " =", tostring(v))
        end
    end
end

_G.__AutoTaxiConn = TaxiEvent.OnClientEvent:Connect(function(...)
    local args = {...}
    warn("[DEBUG] TaxiEvent triggered, args:", #args)
    for i, v in ipairs(args) do
        warn("[DEBUG] arg[" .. i .. "]:", typeof(v), tostring(v))
        if typeof(v) == "table" then printTable(v) end
    end

    local action = args[1]
    local data = args[2]

    if action == "OrderOffer" and jobRunning and typeof(data) == "table" then
        currentToken = data.Token
        task.wait(0.5)
        acceptOrder(currentToken)

    elseif action == "OrderAccepted" and jobRunning and typeof(data) == "table" then
        task.spawn(tripLoop)

    else
        warn("[DEBUG] skip. action:", tostring(action), "jobRunning:", tostring(jobRunning))
    end
end)

-- ============ RAYFIELD UI ============

Tab:CreateDropdown({
    Name = "Pilih Motor",
    Options = vehicleList,
    CurrentOption = {vehicleName or ""},
    Flag = "VehicleDropdown",
    Callback = function(Option)
        vehicleName = Option[1]
    end,
})

Tab:CreateButton({
    Name = "Refresh Daftar Motor",
    Callback = function()
        vehicleList = getVehicleList()
        Rayfield:Notify({
            Title = "Refreshed",
            Content = #vehicleList .. " motor ditemukan",
            Duration = 3,
        })
    end,
})

Tab:CreateSlider({
    Name = "Durasi Tween (detik)",
    Range = {10, 30},
    Increment = 1,
    Suffix = " detik",
    CurrentValue = 20,
    Flag = "TweenDuration",
    Callback = function(Value)
        tweenDuration = Value
    end,
})

Tab:CreateToggle({
    Name = "Start Job Auto Repeat",
    CurrentValue = false,
    Flag = "AutoJob",
    Callback = function(Value)
        jobRunning = Value
        if jobRunning then
            task.spawn(autoJobLoop)
        end
    end,
})