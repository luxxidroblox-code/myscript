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

local GYRO_SPEED   = 150
local CRUISE_ALT   = 100
local VEHICLE_TAG  = "LikasturaMontors_"

local jobRunning   = false
local vehicleName  = nil
local currentToken = nil
local isOnline     = false
local spawnedOnce  = false
local tripActive   = false

local _charNoclipConn  = nil
local _anchorConn      = nil   -- keeps vehicle anchored every Stepped
local _antiRagdollConn = nil   -- keeps ragdoll states disabled every Stepped

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

-- ─── helpers ─────────────────────────────────────────────────────────────────
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

-- ─── anti-ragdoll — runs every Stepped while job is active ───────────────────
-- Blocks FallingDown, Ragdoll, and GettingUp so the humanoid never enters
-- the ragdoll pipeline regardless of what the server fires.
local RAGDOLL_STATES = {
    Enum.HumanoidStateType.FallingDown,
    Enum.HumanoidStateType.Ragdoll,
    Enum.HumanoidStateType.GettingUp,
}

local function startAntiRagdoll()
    if _antiRagdollConn then _antiRagdollConn:Disconnect() end
    _antiRagdollConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        for _, state in ipairs(RAGDOLL_STATES) do
            pcall(function()
                hum:SetStateEnabled(state, false)
            end)
        end
        -- if somehow already ragdolled, force back to Running
        pcall(function()
            local cur = hum:GetState()
            if cur == Enum.HumanoidStateType.FallingDown
            or cur == Enum.HumanoidStateType.Ragdoll then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
        -- unanchor character parts so HRP CFrame writes still work
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p ~= char:FindFirstChild("HumanoidRootPart") then
                pcall(function() p.Anchored = false end)
            end
        end
    end)
end

local function stopAntiRagdoll()
    if _antiRagdollConn then
        _antiRagdollConn:Disconnect()
        _antiRagdollConn = nil
    end
    -- re-enable states when job stops
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, state in ipairs(RAGDOLL_STATES) do
                pcall(function() hum:SetStateEnabled(state, true) end)
            end
        end
    end
end

-- ─── vehicle anchor + network ownership ──────────────────────────────────────
-- Anchor: every BasePart gets Anchored=true so physics can't move it.
-- Network ownership: setneworkowner(LocalPlayer) claims the physics simulation
-- for this client — prevents server from overriding our CFrame writes.
local function applyVehicleOwnership(vehicle)
    for _, p in ipairs(vehicle:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p:SetNetworkOwner(LocalPlayer) end)
        end
    end
end

local function startVehicleAnchor(vehicle)
    -- apply ownership once immediately
    applyVehicleOwnership(vehicle)

    if _anchorConn then _anchorConn:Disconnect() end
    _anchorConn = RunService.Stepped:Connect(function()
        if not vehicle or not vehicle.Parent then
            if _anchorConn then _anchorConn:Disconnect(); _anchorConn = nil end
            return
        end
        for _, p in ipairs(vehicle:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function()
                    p.Anchored      = true
                    p.CanCollide    = false
                    p.Velocity      = Vector3.new(0, 0, 0)
                    p.RotVelocity   = Vector3.new(0, 0, 0)
                end)
            end
        end
    end)
end

local function stopVehicleAnchor()
    if _anchorConn then
        _anchorConn:Disconnect()
        _anchorConn = nil
    end
end

-- ─── character noclip — during air phase only ─────────────────────────────────
local function startCharNoclip()
    if _charNoclipConn then _charNoclipConn:Disconnect() end
    _charNoclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

local function stopCharNoclip()
    if _charNoclipConn then
        _charNoclipConn:Disconnect()
        _charNoclipConn = nil
    end
    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            pcall(function() p.CanCollide = true end)
        end
    end
end

-- ─── raw HRP lerp segment ────────────────────────────────────────────────────
local function lerpHRP(fromPos, toPos, speed)
    local hrp = getCharParts()
    if not hrp then return end
    local distance = (toPos - fromPos).Magnitude
    if distance < 0.1 then return end
    local duration  = distance / speed
    local startTime = os.clock()
    local conn = RunService.Heartbeat:Connect(function()
        if not jobRunning then return end
        local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
        pcall(function()
            hrp.Velocity    = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
            hrp.CFrame      = CFrame.new(fromPos:Lerp(toPos, alpha))
        end)
    end)
    task.wait(duration + 0.05)
    conn:Disconnect()
    pcall(function()
        hrp.Velocity    = Vector3.new(0, 0, 0)
        hrp.RotVelocity = Vector3.new(0, 0, 0)
        hrp.CFrame      = CFrame.new(toPos)
    end)
end

-- ─── three-leg fly-over ───────────────────────────────────────────────────────
local function flyTo(targetPos)
    local hrp, hum = getCharParts()
    if not hrp then return end

    hum.Sit = true
    startCharNoclip()

    local origin    = hrp.Position
    local liftTop   = Vector3.new(origin.X,    origin.Y    + CRUISE_ALT, origin.Z)
    local cruiseDst = Vector3.new(targetPos.X, origin.Y    + CRUISE_ALT, targetPos.Z)
    local landDst   = Vector3.new(targetPos.X, targetPos.Y + 3,          targetPos.Z)

    lerpHRP(origin,    liftTop,    GYRO_SPEED)
    if not jobRunning then stopCharNoclip() return end

    lerpHRP(liftTop,   cruiseDst,  GYRO_SPEED * 2)
    if not jobRunning then stopCharNoclip() return end

    lerpHRP(cruiseDst, landDst,    GYRO_SPEED)

    stopCharNoclip()
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
                flyTo(pos)
            end
        else
            lastPos = nil
        end
        task.wait(1)
    end
    tripActive = false
end

-- ─── sit on vehicle ───────────────────────────────────────────────────────────
local function sitOnVehicle(vehicle)
    local seat = vehicle:FindFirstChild("DriveSeat")
    if not seat then return false end
    local hrp, hum = getCharParts()
    local prompt = seat:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        pcall(function() prompt.MaxActivationDistance = 50 end)
    end
    hrp.CFrame = seat.CFrame * CFrame.new(0, 0.5, 0)
    task.wait(0.2)
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.5)
    end
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    hum.Sit = true
    local deadline = os.clock() + 3
    while os.clock() < deadline do
        if hum.Sit then break end
        hrp.CFrame = seat.CFrame * CFrame.new(0, 0.5, 0)
        hum.Sit    = true
        task.wait(0.15)
    end
    return hum.Sit
end

-- ─── spawn guard ─────────────────────────────────────────────────────────────
local function ensureVehicle()
    local vehicle = findVehicle()
    if not vehicle then
        if not spawnedOnce then
            spawnedOnce = true
            SpawnCarEvents.SpawnCar:FireServer(vehicleName)
        end
        local t = 0
        while not vehicle and t < 8 do
            task.wait(0.5); t = t + 0.5
            vehicle = findVehicle()
        end
    end
    if vehicle then
        startVehicleAnchor(vehicle)
        sitOnVehicle(vehicle)
    end
    return vehicle
end

-- ─── job start ───────────────────────────────────────────────────────────────
local function startJob()
    TeamChange:FireServer("RideGO Driver", 11378976, 1, 0, "Detector")
    task.wait(2)

    startAntiRagdoll()

    local vehicle = ensureVehicle()
    if not vehicle then
        warn("[AutoTaxi] vehicle not found")
        return
    end

    local _, hum = getCharParts()
    local waited = 0
    while not hum.Sit and waited < 5 do
        task.wait(0.3); waited = waited + 0.3
    end

    if not isOnline then
        TaxiEvent:FireServer("GoOnline")
        isOnline = true
        Rayfield:Notify({
            Title    = "Auto Taxi",
            Content  = "Online! Menunggu orderan...",
            Duration = 3,
        })
        vehicle.AncestryChanged:Connect(function(_, parent)
            if not parent then
                isOnline = false
                stopVehicleAnchor()
            end
        end)
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
    Name         = "Kecepatan (studs/s)",
    Range        = {30, 500},
    Increment    = 10,
    Suffix       = " studs/s",
    CurrentValue = 150,
    Flag         = "GyroSpeed",
    Callback     = function(Value)
        GYRO_SPEED = Value
    end,
})

Tab:CreateSlider({
    Name         = "Ketinggian Cruise (studs)",
    Range        = {50, 300},
    Increment    = 10,
    Suffix       = " studs",
    CurrentValue = 100,
    Flag         = "CruiseAlt",
    Callback     = function(Value)
        CRUISE_ALT = Value
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
        if jobRunning then
            spawnedOnce = false
            isOnline    = false
            task.spawn(startJob)
        else
            stopCharNoclip()
            stopVehicleAnchor()
            stopAntiRagdoll()
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