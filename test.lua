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

local MOVE_SPEED   = 150   -- studs/s for lift and descend legs
local CRUISE_SPEED = 300   -- studs/s for horizontal cruise
local CRUISE_ALT   = 100   -- studs above ground during cruise
local VEHICLE_TAG  = "LikasturaMontors_"

local jobRunning   = false
local vehicleName  = nil
local currentToken = nil
local isOnline     = false
local spawnedOnce  = false
local tripActive   = false

local _antiRagdollConn = nil
local _charNoclipConn  = nil

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

-- ─── network ownership — claim all vehicle BaseParts ─────────────────────────
-- Must be called after every respawn of the vehicle since new parts reset owner.
local function claimOwnership(vehicle)
    for _, p in ipairs(vehicle:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function()
                p:SetNetworkOwner(LocalPlayer)
                p.Anchored    = false   -- unanchor so CFrame writes replicate
                p.CanCollide  = false
                p.Velocity    = Vector3.new(0, 0, 0)
                p.RotVelocity = Vector3.new(0, 0, 0)
            end)
        end
    end
end

-- ─── get the part we'll be moving (PrimaryPart > DriveSeat > any BasePart) ───
local function getVehicleRoot(vehicle)
    return vehicle.PrimaryPart
        or vehicle:FindFirstChild("DriveSeat")
        or vehicle:FindFirstChildWhichIsA("BasePart")
end

-- ─── anti-ragdoll ─────────────────────────────────────────────────────────────
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
            pcall(function() hum:SetStateEnabled(state, false) end)
        end
        pcall(function()
            local cur = hum:GetState()
            if cur == Enum.HumanoidStateType.FallingDown
            or cur == Enum.HumanoidStateType.Ragdoll then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end)
end

local function stopAntiRagdoll()
    if _antiRagdollConn then _antiRagdollConn:Disconnect(); _antiRagdollConn = nil end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, state in ipairs(RAGDOLL_STATES) do
            pcall(function() hum:SetStateEnabled(state, true) end)
        end
    end
end

-- ─── character noclip during air phase ───────────────────────────────────────
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
    if _charNoclipConn then _charNoclipConn:Disconnect(); _charNoclipConn = nil end
    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            pcall(function() p.CanCollide = true end)
        end
    end
end

-- ─── vehicle CFrame lerp segment ─────────────────────────────────────────────
-- Moves the vehicle root part directly. Because we own the network, the server
-- accepts these CFrame values and the anti-cheat sees vehicle movement, not
-- character teleportation.
local function lerpVehicle(vehicle, fromCF, toCF, speed)
    local root = getVehicleRoot(vehicle)
    if not root then return end

    local distance = (toCF.Position - fromCF.Position).Magnitude
    if distance < 0.1 then return end

    local duration  = distance / speed
    local startTime = os.clock()

    local conn = RunService.Heartbeat:Connect(function()
        if not jobRunning or not vehicle.Parent then return end
        local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
        pcall(function()
            local cf = fromCF:Lerp(toCF, alpha)
            root.CFrame      = cf
            root.Velocity    = Vector3.new(0, 0, 0)
            root.RotVelocity = Vector3.new(0, 0, 0)

            -- keep all other parts relative (PivotTo handles the whole model)
            if vehicle.PrimaryPart then
                vehicle:PivotTo(cf)
            end
        end)
    end)

    task.wait(duration + 0.05)
    conn:Disconnect()

    pcall(function()
        if vehicle.PrimaryPart then
            vehicle:PivotTo(toCF)
        else
            root.CFrame = toCF
        end
        root.Velocity    = Vector3.new(0, 0, 0)
        root.RotVelocity = Vector3.new(0, 0, 0)
    end)
end

-- ─── three-leg fly-over using vehicle spoof ───────────────────────────────────
local function flyTo(vehicle, targetPos)
    local root = getVehicleRoot(vehicle)
    if not root then return end

    -- re-claim ownership before every move in case server reclaimed it
    claimOwnership(vehicle)

    local _, hum = getCharParts()
    hum.Sit = true
    startCharNoclip()

    local origin = root.Position
    local liftCF   = CFrame.new(origin.X,    origin.Y    + CRUISE_ALT, origin.Z)
    local cruiseCF = CFrame.new(targetPos.X, origin.Y    + CRUISE_ALT, targetPos.Z)
    local landCF   = CFrame.new(targetPos.X, targetPos.Y + 3,          targetPos.Z)

    local originCF = root.CFrame

    -- leg 1: lift straight up
    lerpVehicle(vehicle, originCF,                                     liftCF,   MOVE_SPEED)
    if not jobRunning then stopCharNoclip() return end

    -- leg 2: cruise horizontally above geometry
    lerpVehicle(vehicle, liftCF,                                       cruiseCF, CRUISE_SPEED)
    if not jobRunning then stopCharNoclip() return end

    -- leg 3: descend to waypoint
    lerpVehicle(vehicle, cruiseCF,                                     landCF,   MOVE_SPEED)

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
        local vehicle = findVehicle()
        local wp      = vehicle and findWaypoint()
        local pos     = wp and getWaypointPosition(wp)
        if vehicle and pos then
            if not lastPos or (pos - lastPos).Magnitude > 5 then
                lastPos = pos
                flyTo(vehicle, pos)
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
        claimOwnership(vehicle)
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
            if not parent then isOnline = false end
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
    Name         = "Kecepatan Move (studs/s)",
    Range        = {30, 500},
    Increment    = 10,
    Suffix       = " studs/s",
    CurrentValue = 150,
    Flag         = "MoveSpeed",
    Callback     = function(Value)
        MOVE_SPEED   = Value
        CRUISE_SPEED = Value * 2
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