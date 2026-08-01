-- Fixed: Auto Taxi with stable movement and collision handling
-- Changes:
-- 1. getHRP() now returns char correctly so sit check works
-- 2. Tween preserves rotation instead of snapping flat
-- 3. RunService.Heartbeat lerp replaces TweenService + Velocity conflict
-- 4. CanCollide disabled during movement, restored after

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

-- FIX 1: Returns both HRP and character
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
    warn("[DEBUG] Vehicle not found after", tries, "attempts")
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

-- ============ MOVEMENT ENGINE (FIX 2 + 3) ============
-- No TweenService. No Velocity fighting. Pure lerp on Heartbeat.
local function moveToTarget(targetPos, vehicle)
    local basePart = vehicle:FindFirstChild("DriveSeat") or vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
    if not basePart then
        warn("[DEBUG] No BasePart on vehicle")
        return false
    end

    -- Disable collision during movement
    local originalCollide = {}
    for _, part in ipairs(vehicle:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollide[part] = part.CanCollide
            part.CanCollide = false
        end
    end

    local startCFrame = basePart.CFrame
    -- Preserve rotation — only move position
    local targetCFrame = CFrame.new(targetPos) * (startCFrame - startCFrame.Position)

    local elapsed = 0
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        local alpha = math.min(elapsed / tweenDuration, 1)
        -- Smoothstep
        local t = alpha * alpha * (3 - 2 * alpha)

        pcall(function()
            basePart.CFrame = startCFrame:Lerp(targetCFrame, t)
        end)

        -- Keep seated
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
            warn("[DEBUG] Arrived. Collision restored.")
        end
    end)

    while connection.Connected do
        task.wait(0.1)
    end
    return true
end

local function tweenToTarget()
    local target = workspace:FindFirstChild("ActiveMissions")
    if not target then
        warn("[DEBUG] ActiveMissions missing")
        return
    end

    local guideTarget = target:FindFirstChild("RideGO_GuideTarget")
    if not guideTarget then
        warn("[DEBUG] RideGO_GuideTarget missing")
        return
    end

    local vehicle = findVehicle()
    if not vehicle then
        warn("[DEBUG] Vehicle missing, abort tween")
        return
    end

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
                warn("[DEBUG] GuideTarget lost, trip ended")
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
                    isOnline = false
                end
            end)
        else
            warn("[DEBUG] No vehicle, retrying...")
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
    warn("[DEBUG] Incoming order notification")
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
    warn("[DEBUG] TaxiEvent fired, args:", #args)

    for i, v in ipairs(args) do
        warn("[DEBUG] arg[" .. i .. "]:", typeof(v), tostring(v))
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

    else
        warn("[DEBUG] Skipped. action:", tostring(action), "jobRunning:", tostring(jobRunning))
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
        end
    end,
})