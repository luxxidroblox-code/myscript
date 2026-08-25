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

-- ─── wait until PlayerGui and ScrollingFrame are actually ready ───────────────
local MainUI = LocalPlayer.PlayerGui:WaitForChild("MainUI", 15)
local ScrollingFrame = MainUI.Frame.MainFrame:WaitForChild("ScrollingFrame", 15)

local GYRO_SPEED  = 150
local VEHICLE_TAG = "LikasturaMontors_"

local jobRunning  = false
local vehicleName = nil
local currentToken= nil
local isOnline    = false
local spawnedOnce = false
local tripActive  = false

-- ─── vehicle list — waits for children to populate ───────────────────────────
local function getVehicleList()
    -- give the frame up to 5s to populate if it's still empty
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

-- ─── waypoint search — scans workspace descendants broadly ───────────────────
-- Matches: RideGO_GuideTarget, WaypointPart, GuideTarget, BeaconPart,
--          any BasePart/Model whose name contains guide/waypoint/beacon/target
local WAYPOINT_PATTERNS = {
    "guidetarget", "waypoint", "beacon", "ridego", "guide_target",
    "dropoff", "pickup", "destination", "navpoint",
}

local function findWaypoint()
    -- priority 1: known ActiveMissions path
    local missions = workspace:FindFirstChild("ActiveMissions")
    if missions then
        local direct = missions:FindFirstChild("RideGO_GuideTarget")
        if direct then return direct end
        -- search one level deeper
        for _, child in ipairs(missions:GetChildren()) do
            local lower = child.Name:lower()
            for _, pat in ipairs(WAYPOINT_PATTERNS) do
                if lower:find(pat) then return child end
            end
        end
    end

    -- priority 2: scan all workspace descendants for name match
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("BasePart") or desc:IsA("Model") then
            local lower = desc.Name:lower()
            for _, pat in ipairs(WAYPOINT_PATTERNS) do
                if lower:find(pat) then return desc end
            end
        end
    end

    -- priority 3: scan for a red BillboardGui (the map pin visible in screenshot)
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("BillboardGui") then
            for _, img in ipairs(desc:GetDescendants()) do
                if img:IsA("ImageLabel") or img:IsA("Frame") then
                    local c = img.BackgroundColor3 or Color3.new()
                    -- red: R > 0.7, G < 0.3, B < 0.3
                    if c.R > 0.7 and c.G < 0.3 and c.B < 0.3 then
                        return desc.Parent  -- the Part the billboard is on
                    end
                end
            end
        end
    end

    return nil
end

local function getWaypointPosition(wp)
    if wp:IsA("BasePart") then
        return wp.Position
    elseif wp:IsA("Model") then
        local hrp = wp:FindFirstChild("HumanoidRootPart")
                 or wp.PrimaryPart
                 or wp:FindFirstChildWhichIsA("BasePart")
        if hrp then return hrp.Position end
    end
    -- fallback: any BasePart descendant
    local part = wp:FindFirstChildWhichIsA("BasePart")
    return part and part.Position
end

-- ─── seat onto vehicle via proximity prompt ───────────────────────────────────
local function sitOnVehicle(vehicle)
    local seat = vehicle:FindFirstChild("DriveSeat")
    if not seat then return false end

    local hrp, hum = getCharParts()
    hrp.CFrame = seat.CFrame * CFrame.new(0, 3, 0)
    task.wait(0.3)

    local prompt = seat:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.5)
    end

    -- force sit state
    pcall(function() hum.Sit = true end)
    return true
end

-- ─── spawn guard ─────────────────────────────────────────────────────────────
local function ensureVehicle()
    local vehicle = findVehicle()
    if vehicle then
        sitOnVehicle(vehicle)
        return vehicle
    end

    if not spawnedOnce then
        spawnedOnce = true
        SpawnCarEvents.SpawnCar:FireServer(vehicleName)
    end

    -- wait up to 8s
    local t = 0
    while not vehicle and t < 8 do
        task.wait(0.5)
        t = t + 0.5
        vehicle = findVehicle()
    end

    if vehicle then sitOnVehicle(vehicle) end
    return vehicle
end

-- ─── movement: teleport HRP with BodyGyro stabilisation ──────────────────────
-- Moving the vehicle mesh from client doesn't replicate (server-owned).
-- Moving the character HRP while Humanoid.Sit=true keeps the ride illusion.
local function gyroMoveHRP(targetPos)
    local hrp, hum = getCharParts()
    if not hrp then return end

    hum.Sit = true   -- stay seated
    task.wait(0.1)

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
        local elapsed = os.clock() - startTime
        local alpha   = math.clamp(elapsed / duration, 0, 1)
        pcall(function()
            hrp.Velocity    = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
            hrp.CFrame      = CFrame.new(startPos:Lerp(targetPos, alpha),
                                          targetPos)
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
end

-- ─── trip loop — polls waypoint every 1s, re-moves when it shifts ─────────────
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
                gyroMoveHRP(pos + Vector3.new(0, 3, 0))  -- +3 so we land on ground
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
    TeamChange:FireServer("RideGO Driver", 11378976, 1, 0, "Detector")
    task.wait(2)

    local vehicle = ensureVehicle()
    if not vehicle then
        warn("[AutoTaxi] vehicle not found")
        return
    end

    if not isOnline then
        TaxiEvent:FireServer("GoOnline")
        isOnline = true

        vehicle.AncestryChanged:Connect(function(_, parent)
            if not parent then isOnline = false end
        end)
    end
end

-- ─── cleanup old listeners ───────────────────────────────────────────────────
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

-- dropdown is stored so refresh can destroy + recreate it
local dropdownHolder = Tab:CreateSection("Kendaraan")
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
        -- Rayfield dropdown: Set() updates the selected value;
        -- for options list, rebuild with the refreshed data
        if VehicleDropdown and VehicleDropdown.Refresh then
            VehicleDropdown:Refresh(vehicleList, true)
        elseif VehicleDropdown and VehicleDropdown.Set then
            -- fallback: at minimum update selection
            if vehicleList[1] then
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
        jobRunning  = Value
        tripActive  = false

        if jobRunning then
            spawnedOnce = false
            isOnline    = false
            task.spawn(startJob)
        end
    end,
})

-- ─── debug button: print what findWaypoint() sees right now ──────────────────
Tab:CreateButton({
    Name     = "Debug: Cari Waypoint",
    Callback = function()
        local wp  = findWaypoint()
        local pos = wp and getWaypointPosition(wp)
        Rayfield:Notify({
            Title    = "Waypoint Debug",
            Content  = wp and ("Ketemu: " .. wp.Name .. " @ " .. tostring(pos))
                           or "Tidak ditemukan",
            Duration = 5,
        })
    end,
})