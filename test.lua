local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
loadstring(game:HttpGet('https://raw.githubusercontent.com/luxxidroblox-code/myscript.lua/refs/heads/main/adonis.lua'))()

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local LocalPlayer       = Players.LocalPlayer

local JobEvents      = ReplicatedStorage:WaitForChild("JobEvents")
local TeamChange     = JobEvents:WaitForChild("TeamChangeRequest")
local TaxiAssets     = ReplicatedStorage:WaitForChild("TaxiAssets")
local TaxiEvent      = TaxiAssets.Events:WaitForChild("TaxiEvent")
local SpawnCarEvents = ReplicatedStorage:WaitForChild("SpawnCarEvents")
local NotifSound     = ReplicatedStorage:WaitForChild("Notification"):WaitForChild("Notif2Sound")

local MainUI         = LocalPlayer.PlayerGui:WaitForChild("MainUI", 15)
local ScrollingFrame = MainUI.Frame.MainFrame:WaitForChild("ScrollingFrame", 15)

local GYRO_SPEED  = 150
local VEHICLE_TAG = "LikasturaMontors_"

local jobRunning   = false
local vehicleName  = nil
local currentToken = nil
local isOnline     = false
local spawnedOnce  = false
local tripActive   = false
local _seatWeld    = nil   -- active Motor6D keeping HRP on seat
local _noclipConn  = nil   -- RunService conn for noclip during move

-- ─── vehicle list ─────────────────────────────────────────────────────────────
local function getVehicleList()
    local deadline = os.clock() + 5
    while #ScrollingFrame:GetChildren() == 0 and os.clock() < deadline do
        task.wait(0.3)
    end
    local list = {}
    for _, child in ipairs(ScrollingFrame:GetChildren()) do
        if (child:IsA("TextButton") or child:IsA("ImageButton"))
            and not child.Name:lower():match("ui")
        then
            table.insert(list, child.Name)
        end
    end
    return list
end

local vehicleList = getVehicleList()
vehicleName       = vehicleList[1]

-- ─── helpers ──────────────────────────────────────────────────────────────────
local function findVehicle()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name:match("^" .. VEHICLE_TAG) then return obj end
    end
    return nil
end

local function getCharParts()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart"),
           char:WaitForChild("Humanoid"),
           char
end

-- ─── noclip: disable CanCollide on every character part ──────────────────────
local function startNoclip()
    if _noclipConn then _noclipConn:Disconnect() end
    _noclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function stopNoclip()
    if _noclipConn then
        _noclipConn:Disconnect()
        _noclipConn = nil
    end
    -- restore collision on character parts
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
    end
end

-- ─── hard seat weld: Motor6D from DriveSeat → HRP ────────────────────────────
local function destroySeatWeld()
    if _seatWeld and _seatWeld.Parent then
        pcall(function() _seatWeld:Destroy() end)
    end
    _seatWeld = nil
end

local function weldToSeat(seat, hrp)
    destroySeatWeld()
    local weld      = Instance.new("Motor6D")
    weld.Name       = "AutoTaxiWeld"
    weld.Part0      = seat
    weld.Part1      = hrp
    -- offset: keep HRP centered above seat
    weld.C0         = CFrame.new(0, 1.5, 0)
    weld.C1         = CFrame.new()
    weld.Parent     = seat
    _seatWeld       = weld
    return weld
end

-- ─── sit + weld sequence ─────────────────────────────────────────────────────
-- Returns true once the humanoid confirms Sit == true.
local function sitAndWeld(vehicle)
    local seat = vehicle:FindFirstChild("DriveSeat")
    if not seat then return false end

    local hrp, hum, char = getCharParts()

    -- 1. teleport HRP directly onto the seat
    hrp.CFrame = seat.CFrame * CFrame.new(0, 1.5, 0)
    task.wait(0.15)

    -- 2. fire proximity prompt if present
    local prompt = seat:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.4)
    end

    -- 3. force sit state
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    hum.Sit = true

    -- 4. poll until seated, max 3s
    local deadline = os.clock() + 3
    while not hum.Sit and os.clock() < deadline do
        hrp.CFrame = seat.CFrame * CFrame.new(0, 1.5, 0)
        hum.Sit    = true
        task.wait(0.2)
    end

    -- 5. hard weld so physics can't eject the character
    weldToSeat(seat, hrp)

    -- 6. destroy weld when vehicle is removed from workspace
    vehicle.AncestryChanged:Connect(function(_, parent)
        if not parent then
            destroySeatWeld()
            isOnline = false
        end
    end)

    return hum.Sit
end

-- ─── waypoint search ─────────────────────────────────────────────────────────
local WAYPOINT_PATTERNS = {
    "guidetarget", "waypoint", "beacon", "ridego",
    "guide_target", "dropoff", "pickup", "destination", "navpoint",
}

local function findWaypoint()
    local missions = workspace:FindFirstChild("ActiveMissions")
    if missions then
        local direct = missions:FindFirstChild("RideGO_GuideTarget")
        if direct then return direct end
        for _, child in ipairs(missions:GetChildren()) do
            local lower = child.Name:lower()
            for _, pat in ipairs(WAYPOINT_PATTERNS) do
                if lower:find(pat) then return child end
            end
        end
    end
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("BasePart") or desc:IsA("Model") then
            local lower = desc.Name:lower()
            for _, pat in ipairs(WAYPOINT_PATTERNS) do
                if lower:find(pat) then return desc end
            end
        end
    end
    return nil
end

local function getWaypointPosition(wp)
    if wp:IsA("BasePart") then return wp.Position end
    local part = wp:FindFirstChild("HumanoidRootPart")
             or (wp:IsA("Model") and wp.PrimaryPart)
             or wp:FindFirstChildWhichIsA("BasePart")
    return part and part.Position
end

-- ─── gyro move — moves HRP with noclip active ────────────────────────────────
local function gyroMoveHRP(targetPos)
    local hrp, hum = getCharParts()
    if not hrp then return end

    hum.Sit = true
    startNoclip()

    local gyro        = Instance.new("BodyGyro")
    gyro.MaxTorque    = Vector3.new(1e6, 1e6, 1e6)
    gyro.P            = 1e5
    gyro.D            = 500
    gyro.CFrame       = CFrame.new(hrp.Position, targetPos)
    gyro.Parent       = hrp

    local startPos  = hrp.Position
    local distance  = (targetPos - startPos).Magnitude
    local duration  = math.max(distance / GYRO_SPEED, 0.1)
    local startTime = os.clock()

    local conn = RunService.Heartbeat:Connect(function()
        if not jobRunning then return end
        local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
        pcall(function()
            hrp.Velocity    = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
            hrp.CFrame      = CFrame.new(startPos:Lerp(targetPos, alpha), targetPos)
            gyro.CFrame     = hrp.CFrame
        end)
    end)

    task.wait(duration + 0.1)
    conn:Disconnect()
    gyro:Destroy()

    pcall(function()
        hrp.Velocity    = Vector3.new(0, 0, 0)
        hrp.RotVelocity = Vector3.new(0, 0, 0)
    end)

    stopNoclip()
end

-- ─── trip loop ───────────────────────────────────────────────────────────────
local function tripLoop()
    if tripActive then return end
    tripActive = true
    local lastPos = nil
    while tripActive and jobRunning do
        local wp  = findWaypoint()
        local pos = wp and getWaypointPosition(wp)
        if pos then
            if not lastPos or (pos - lastPos).Magnitude > 5 then
                lastPos = pos
                gyroMoveHRP(pos + Vector3.new(0, 3, 0))
            end
        else
            if lastPos then lastPos = nil end
        end
        task.wait(1)
    end
    tripActive = false
end

-- ─── spawn guard ─────────────────────────────────────────────────────────────
local function ensureVehicle()
    local vehicle = findVehicle()
    if vehicle then
        sitAndWeld(vehicle)
        return vehicle
    end
    if not spawnedOnce then
        spawnedOnce = true
        SpawnCarEvents.SpawnCar:FireServer(vehicleName)
    end
    local t = 0
    while not vehicle and t < 8 do
        task.wait(0.5)
        t       = t + 0.5
        vehicle = findVehicle()
    end
    if vehicle then sitAndWeld(vehicle) end
    return vehicle
end

-- ─── job start ───────────────────────────────────────────────────────────────
-- GoOnline only fires after sitAndWeld confirms hum.Sit == true.
local function startJob()
    TeamChange:FireServer("RideGO Driver", 11378976, 1, 0, "Detector")
    task.wait(2)

    local vehicle = ensureVehicle()
    if not vehicle then
        warn("[AutoTaxi] vehicle not found")
        return
    end

    -- confirm seated before going online
    local hrp, hum = getCharParts()
    local waited   = 0
    while not hum.Sit and waited < 5 do
        task.wait(0.3)
        waited = waited + 0.3
    end

    if not isOnline then
        TaxiEvent:FireServer("GoOnline")
        isOnline = true
        Rayfield:Notify({
            Title    = "Auto Taxi",
            Content  = "Online! Menunggu orderan...",
            Duration = 3,
        })
    end
end

-- ─── cleanup ─────────────────────────────────────────────────────────────────
if _G.__AutoTaxiConn      then _G.__AutoTaxiConn:Disconnect()      end
if _G.__AutoTaxiNotifConn then _G.__AutoTaxiNotifConn:Disconnect() end

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

-- ─── UI ──────────────────────────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name            = "Auto Taxi",
    LoadingTitle    = "Loading...",
    LoadingSubtitle = "by you",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "AutoTaxi",
        FileName   = "Config"
    },
    KeySystem = false,
})

local Tab = Window:CreateTab("Main", nil)

Tab:CreateSection("Kendaraan")

local VehicleDropdown = Tab:CreateDropdown({
    Name          = "Pilih Motor",
    Options       = #vehicleList > 0 and vehicleList or {"(belum ada)"},
    CurrentOption = {vehicleName or "(belum ada)"},
    Flag          = "VehicleDropdown",
    Callback      = function(Option)
        vehicleName = Option[1]
    end,
})

Tab:CreateButton({
    Name     = "Refresh Daftar Motor",
    Callback = function()
        vehicleList = getVehicleList()
        if VehicleDropdown then
            if VehicleDropdown.Refresh then
                VehicleDropdown:Refresh(vehicleList, true)
            elseif VehicleDropdown.Set and vehicleList[1] then
                vehicleName = vehicleList[1]
                VehicleDropdown:Set(vehicleName)
            end
        end
        Rayfield:Notify({
            Title    = "Refreshed",
            Content  = #vehicleList .. " motor ditemukan",
            Duration = 3,
        })
    end,
})

Tab:CreateSection("Pengaturan")

Tab:CreateSlider({
    Name         = "Kecepatan Gyro (studs/s)",
    Range        = {30, 500},
    Increment    = 10,
    Suffix       = " studs/s",
    CurrentValue = 150,
    Flag         = "GyroSpeed",
    Callback     = function(Value)
        GYRO_SPEED = Value
    end,
})

Tab:CreateSection("Kontrol")

Tab:CreateToggle({
    Name         = "Start Auto Taxi",
    CurrentValue = false,
    Flag         = "AutoJob",
    Callback     = function(Value)
        jobRunning = Value
        tripActive = false
        stopNoclip()
        if jobRunning then
            spawnedOnce = false
            isOnline    = false
            task.spawn(startJob)
        else
            destroySeatWeld()
        end
    end,
})

Tab:CreateButton({
    Name     = "Debug: Cari Waypoint",
    Callback = function()
        local wp  = findWaypoint()
        local pos = wp and getWaypointPosition(wp)
        Rayfield:Notify({
            Title    = "Waypoint Debug",
            Content  = wp and ("Ketemu: " .. wp.Name .. "\n" .. tostring(pos))
                           or "Tidak ditemukan",
            Duration = 5,
        })
    end,
})