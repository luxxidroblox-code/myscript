local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
loadstring(game:HttpGet('https://raw.githubusercontent.com/luxxidroblox-code/myscript.lua/refs/heads/main/adonis.lua'))()

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local LocalPlayer       = Players.LocalPlayer

local JobEvents   = ReplicatedStorage:WaitForChild("JobEvents")
local TeamChange  = JobEvents:WaitForChild("TeamChangeRequest")
local TaxiAssets  = ReplicatedStorage:WaitForChild("TaxiAssets")
local TaxiEvent   = TaxiAssets.Events:WaitForChild("TaxiEvent")
local SpawnCarEvents = ReplicatedStorage:WaitForChild("SpawnCarEvents")
local NotifSound  = ReplicatedStorage:WaitForChild("Notification"):WaitForChild("Notif2Sound")

local ScrollingFrame = LocalPlayer.PlayerGui
    :WaitForChild("MainUI").Frame.MainFrame.ScrollingFrame

-- ─── config ──────────────────────────────────────────────────────────────────
local GYRO_SPEED    = 150   -- studs/s, replaces tweenDuration
local VEHICLE_TAG   = "LikasturaMontors_"

-- ─── state ───────────────────────────────────────────────────────────────────
local jobRunning    = false
local vehicleName   = nil
local currentToken  = nil
local isOnline      = false
local spawnedOnce   = false   -- guard: only spawn once per job session
local tripActive    = false

-- ─── vehicle list ─────────────────────────────────────────────────────────────
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
vehicleName       = vehicleList[1]

-- ─── helpers ─────────────────────────────────────────────────────────────────
local function findVehicle()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name:match("^" .. VEHICLE_TAG) then return obj end
    end
    return nil
end

local function getCharParts()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local hum  = char:WaitForChild("Humanoid")
    return hrp, hum, char
end

-- ─── seat lock: weld HRP to DriveSeat so character doesn't fall off ──────────
local _seatConn = nil
local function lockToSeat(vehicle)
    local seat = vehicle:FindFirstChild("DriveSeat")
    if not seat then return end

    local hrp, hum = getCharParts()

    -- fire proximity prompt if present
    local prompt = seat:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        hrp.CFrame = seat.CFrame * CFrame.new(0, 2.5, 0)
        task.wait(0.2)
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.3)
    end

    -- inject a Motor6D/weld so the character stays seated during gyro movement
    pcall(function()
        local weld      = Instance.new("Motor6D")
        weld.Name       = "AutoTaxiSeatWeld"
        weld.Part0      = seat
        weld.Part1      = hrp
        weld.C0         = CFrame.new(0, 0, 0)
        weld.C1         = hrp.CFrame:ToObjectSpace(seat.CFrame)
        weld.Parent     = seat

        hum.Sit = true

        -- clean up weld when job stops or character resets
        if _seatConn then _seatConn:Disconnect() end
        _seatConn = vehicle.AncestryChanged:Connect(function(_, parent)
            if not parent then
                pcall(function() weld:Destroy() end)
                if _seatConn then _seatConn:Disconnect() end
            end
        end)
    end)
end

-- ─── spawn guard: only fires SpawnCar once per job session ───────────────────
local function ensureVehicle()
    local vehicle = findVehicle()
    if vehicle then
        lockToSeat(vehicle)
        return vehicle
    end

    if spawnedOnce then
        -- already spawned this session, wait up to 8s for it to appear
        local t = 0
        while not vehicle and t < 8 do
            task.wait(0.5)
            t       = t + 0.5
            vehicle = findVehicle()
        end
        if vehicle then lockToSeat(vehicle) end
        return vehicle
    end

    spawnedOnce = true
    SpawnCarEvents.SpawnCar:FireServer(vehicleName)
    task.wait(2)

    vehicle = findVehicle()
    local tries = 0
    while not vehicle and tries < 10 do
        task.wait(0.5)
        vehicle = findVehicle()
        tries   = tries + 1
    end

    if vehicle then lockToSeat(vehicle) end
    return vehicle
end

-- ─── BodyGyro lerp — moves the vehicle's DriveSeat/PrimaryPart ───────────────
local function gyroMoveTo(targetPos)
    local vehicle = findVehicle()
    if not vehicle then return end

    local basePart = vehicle:FindFirstChild("DriveSeat")
                  or vehicle.PrimaryPart
                  or vehicle:FindFirstChildWhichIsA("BasePart")
    if not basePart then return end

    -- temporarily disable collisions so the vehicle doesn't snag on geometry
    local savedCollide = {}
    for _, p in ipairs(vehicle:GetDescendants()) do
        if p:IsA("BasePart") then
            savedCollide[p] = p.CanCollide
            p.CanCollide    = false
        end
    end

    local gyro        = Instance.new("BodyGyro")
    gyro.MaxTorque    = Vector3.new(1e6, 1e6, 1e6)
    gyro.P            = 1e5
    gyro.D            = 500
    gyro.CFrame       = CFrame.new(basePart.Position, targetPos)
    gyro.Parent       = basePart

    local startPos  = basePart.Position
    local distance  = (targetPos - startPos).Magnitude
    local duration  = distance / GYRO_SPEED
    local startTime = os.clock()

    local conn = RunService.Heartbeat:Connect(function()
        if not jobRunning or not basePart.Parent then return end
        local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
        pcall(function()
            basePart.Velocity    = Vector3.new(0, 0, 0)
            basePart.RotVelocity = Vector3.new(0, 0, 0)
            basePart.CFrame      = CFrame.new(startPos:Lerp(targetPos, alpha),
                                              targetPos)
            gyro.CFrame          = basePart.CFrame
        end)
    end)

    task.wait(duration)
    conn:Disconnect()
    gyro:Destroy()

    -- restore collisions
    for part, was in pairs(savedCollide) do
        pcall(function() part.CanCollide = was end)
    end

    pcall(function()
        basePart.Velocity    = Vector3.new(0, 0, 0)
        basePart.RotVelocity = Vector3.new(0, 0, 0)
    end)
end

-- ─── trip loop — tracks guideTarget and re-gyros when it moves ───────────────
local function tripLoop()
    if tripActive then return end
    tripActive = true

    local lastPos = nil
    while tripActive and jobRunning do
        local missions     = workspace:FindFirstChild("ActiveMissions")
        local guideTarget  = missions and missions:FindFirstChild("RideGO_GuideTarget")
        if guideTarget then
            local pos = guideTarget.Position
            if not lastPos or (pos - lastPos).Magnitude > 5 then
                lastPos = pos
                gyroMoveTo(pos)
            end
        else
            if lastPos then lastPos = nil end
        end
        task.wait(1)
    end

    tripActive = false
end

-- ─── job start ───────────────────────────────────────────────────────────────
local function startJob()
    -- 1. switch team to RideGO Driver
    TeamChange:FireServer("RideGO Driver", 11378976, 1, 0, "Detector")
    task.wait(2)

    -- 2. ensure vehicle exists (spawn once) and sit
    local vehicle = ensureVehicle()
    if not vehicle then
        warn("[AutoTaxi] vehicle not found after spawn attempt")
        return
    end

    -- 3. go online
    if not isOnline then
        TaxiEvent:FireServer("GoOnline")
        isOnline = true

        vehicle.AncestryChanged:Connect(function(_, parent)
            if not parent then isOnline = false end
        end)
    end
end

-- ─── cleanup old listeners ───────────────────────────────────────────────────
if _G.__AutoTaxiConn       then _G.__AutoTaxiConn:Disconnect()       end
if _G.__AutoTaxiNotifConn  then _G.__AutoTaxiNotifConn:Disconnect()  end

-- ─── TaxiEvent listener ──────────────────────────────────────────────────────
_G.__AutoTaxiConn = TaxiEvent.OnClientEvent:Connect(function(...)
    local args   = {...}
    local action = args[1]
    local data   = args[2]

    if action == "OrderOffer" and jobRunning and typeof(data) == "table" then
        currentToken = data.Token
        task.wait(0.3)
        TaxiEvent:FireServer("AcceptOrder", currentToken)

    elseif action == "OrderAccepted" and jobRunning then
        task.spawn(tripLoop)
    end
end)

_G.__AutoTaxiNotifConn = NotifSound.OnClientEvent:Connect(function() end)

-- ─── Rayfield UI ─────────────────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name             = "Auto Taxi",
    LoadingTitle     = "Loading...",
    LoadingSubtitle  = "by you",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "AutoTaxi",
        FileName   = "Config"
    },
    KeySystem = false,
})

local Tab = Window:CreateTab("Main", nil)

Tab:CreateDropdown({
    Name          = "Pilih Motor",
    Options       = vehicleList,
    CurrentOption = {vehicleName or ""},
    Flag          = "VehicleDropdown",
    Callback      = function(Option)
        vehicleName = Option[1]
    end,
})

Tab:CreateButton({
    Name     = "Refresh Daftar Motor",
    Callback = function()
        vehicleList = getVehicleList()
        Rayfield:Notify({
            Title   = "Refreshed",
            Content = #vehicleList .. " motor ditemukan",
            Duration = 3,
        })
    end,
})

Tab:CreateSlider({
    Name         = "Kecepatan Gyro (studs/s)",
    Range        = {50, 400},
    Increment    = 10,
    Suffix       = " studs/s",
    CurrentValue = 150,
    Flag         = "GyroSpeed",
    Callback     = function(Value)
        GYRO_SPEED = Value
    end,
})

Tab:CreateToggle({
    Name         = "Start Auto Taxi",
    CurrentValue = false,
    Flag         = "AutoJob",
    Callback     = function(Value)
        jobRunning  = Value
        tripActive  = false

        if jobRunning then
            spawnedOnce = false   -- reset spawn guard for new session
            isOnline    = false
            task.spawn(startJob)
        end
    end,
})