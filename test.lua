-- Auto Taxi — Full Fixed Script
-- Fixes:
-- 1. getHRP() returns char correctly
-- 2. Movement preserves rotation (no snap)
-- 3. Heartbeat lerp replaces TweenService + Velocity conflict
-- 4. CanCollide disabled during movement, restored after
-- 5. Force seat retry with verification
-- 6. Spawn once + watch until seated

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

-- ============ RAYFIELD BOOTSTRAP ============
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
loadstring(game:HttpGet('https://raw.githubusercontent.com/LynX99-9/komtolmmek2/refs/heads/main/Adonis'))()

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

-- ============ STATE ============
local jobRunning = false
local vehicleName = nil
local currentToken = nil
local isOnline = false
local tripActive = false
local tweenDuration = 20

-- ============ VEHICLE LIST ============
local function getVehicleList()
    local list = {}
    for _, child in ipairs(ScrollingFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("ImageButton") then
            if not child.Name:lower():match("ui") then
                table.insert(list, child.Name)
            end
        end
    end
    return list
end

local vehicleList = getVehicleList()
if #vehicleList > 0 then
    vehicleName = vehicleList[1]
end

-- ============ HELPERS ============
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

local function sitOnVehicle(vehicle)
    local driveSeat = vehicle:FindFirstChild("DriveSeat")
    if not driveSeat then
        warn("[DEBUG] DriveSeat missing in", vehicle.Name)
        return false
    end

    local hrp, char = getHRP()
    hrp.CFrame = driveSeat.CFrame * CFrame.new(0, 3, 0)
    task.wait(0.3)

    local prompt = driveSeat:FindFirstChild("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
    else
        warn("[DEBUG] ProximityPrompt missing")
    end
    return true
end

-- ============ FORCE SEAT WATCHER ============
local function forceSeat(vehicle, maxRetries)
    maxRetries = maxRetries or 12
    local retries = 0

    while retries < maxRetries do
        local hrp, char = getHRP()
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if hum and hum.Sit then
            return true
        end

        local driveSeat = vehicle:FindFirstChild("DriveSeat")
        if driveSeat then
            hrp.CFrame = driveSeat.CFrame * CFrame.new(0, 3, 0)
            task.wait(0.2)

            local prompt = driveSeat:FindFirstChild("ProximityPrompt")
            if prompt then
                fireproximityprompt(prompt)
            end

            task.wait(0.3)
            hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Sit then
                return true
            end
        end

        retries += 1
        task.wait(0.5)
    end

    return false
end

-- ============ SPAWN + WATCH ============
local function spawnAndSitWithWatch(name)
    if not name then return false end

    SpawnCarEvents.SpawnCar:FireServer(name)

    local vehicle = nil
    local attempts = 0
    while not vehicle and attempts < 15 do
        task.wait(0.5)
        vehicle = findVehicle()
        attempts += 1
    end

    if not vehicle then
        return false
    end

    local seated = forceSeat(vehicle, 12)
    if seated then
        return true
    else
        vehicle:Destroy()
        task.wait(1)
        return spawnAndSitWithWatch(name)
    end
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

-- ============ MOVEMENT ENGINE ============
local function moveToTarget(targetPos, vehicle)
    local basePart = vehicle:FindFirstChild("DriveSeat") or vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
    if not basePart then
        return false
    end

    local originalCollide = {}
    for _, part in ipairs(vehicle:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollide[part] = part.CanCollide
            part.CanCollide = false
        end
    end

    local startCFrame = basePart.CFrame
    local targetCFrame = CFrame.new(targetPos) * (startCFrame - startCFrame.Position)

    local elapsed = 0
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        local alpha = math.min(elapsed / tweenDuration, 1)
        local t = alpha * alpha * (3 - 2 * alpha)

        pcall(function()
            basePart.CFrame = startCFrame:Lerp(targetCFrame, t)
        end)

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and not hum.Sit then
            pcall(function() hum.Sit = true end)
        end

        if alpha >= 1 then
            connection:Disconnect()
            for part, wasCollide in pairs(originalCollide) do
                pcall(function() part.CanCollide = wasCollide end)
            end
        end
    end)

    while connection.Connected do
        task.wait(0.1)
    end
    return true
end

local function tweenToTarget()
    local target = workspace:FindFirstChild("ActiveMissions")
    if not target then return end

    local guideTarget = target:FindFirstChild("RideGO_GuideTarget")
    if not guideTarget then return end

    local vehicle = findVehicle()
    if not vehicle then return end

    moveToTarget(guideTarget.Position, vehicle)
end

-- ============ TRIP LOOP ============
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
                lastPos = nil
            end
        end

        task.wait(1)
    end

    tripActive = false
end

-- ============ AUTO JOB LOOP ============
local function autoJobLoop()
    while jobRunning do
        local vehicle = findVehicle()

        if not vehicle then
            local success = spawnAndSitWithWatch(vehicleName)
            if not success then
                task.wait(3)
                continue
            end
            vehicle = findVehicle()
        else
            local hrp, char = getHRP()
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not (hum and hum.Sit) then
                forceSeat(vehicle, 8)
            end
        end

        if vehicle then
            task.wait(0.5)
            goOnline()

            vehicle.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    isOnline = false
                end
            end)
        else
            task.wait(2)
        end

        task.wait(1)
    end
end

-- ============ EVENT HANDLERS ============
if _G.__AutoTaxiConn then
    _G.__AutoTaxiConn:Disconnect()
    _G.__AutoTaxiConn = nil
end
if _G.__AutoTaxiNotifConn then
    _G.__AutoTaxiNotifConn:Disconnect()
    _G.__AutoTaxiNotifConn = nil
end

_G.__AutoTaxiNotifConn = NotifSound.OnClientEvent:Connect(function()
    -- Notification received
end)

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

    for i, v in ipairs(args) do
        if typeof(v) == "table" then
            printTable(v)
        end
    end

    local action = args[1]
    local data = args[2]

    if action == "OrderOffer" and jobRunning and typeof(data) == "table" then
        currentToken = data.Token
        task.wait(0.5)
        acceptOrder(currentToken)

    elseif action == "OrderAccepted" and jobRunning and typeof(data) == "table" then
        task.spawn(tripLoop)
    end
end)

-- ============ UI ============
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
        else
            tripActive = false
        end
    end,
})