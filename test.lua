local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local SpawnCarEvents = ReplicatedStorage:WaitForChild("SpawnCarEvents")
local TaxiAssets = ReplicatedStorage:WaitForChild("TaxiAssets")
local TaxiEvent = TaxiAssets.Events:WaitForChild("TaxiEvent")
local TeamChangeRequest = ReplicatedStorage:WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
local NotifSound = ReplicatedStorage:WaitForChild("Notification"):WaitForChild("Notif2Sound")

local ScrollingFrame = LocalPlayer.PlayerGui:WaitForChild("MainUI").Frame.MainFrame.ScrollingFrame

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
loadstring(game:HttpGet('https://raw.githubusercontent.com/LynX99-9/komtolmmek2/refs/heads/main/Adonis'))()

local Window = Rayfield:CreateWindow({
    Name = "Auto Taxi",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by you",
    ConfigurationSaving = { Enabled = true, FolderName = "AutoTaxi", FileName = "Config" },
    KeySystem = false,
})
local Tab = Window:CreateTab("Main", nil)

-- ============ STATE ============
local jobRunning    = false
local vehicleName   = nil
local currentToken  = nil
local isOnline      = false
local tripActive    = false
local tweenDuration = 20
local currentVehicle = nil
local spawnFired    = false   -- true once FireServer("SpawnCar") is sent; never resets while job is on
local seatWatcher   = nil

-- ============ VEHICLE LIST ============
local function getVehicleList()
    local list = {}
    for _, child in ipairs(ScrollingFrame:GetChildren()) do
        if (child:IsA("TextButton") or child:IsA("ImageButton"))
            and not child.Name:lower():match("ui") then
            table.insert(list, child.Name)
        end
    end
    return list
end

local vehicleList = getVehicleList()
vehicleName = vehicleList[1] or nil

-- ============ HELPERS ============
local function findVehicle()
    -- Returns the first model in workspace matching the spawn pattern that still exists
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:match("^LikasturaMontors_") then
            return obj
        end
    end
    return nil
end

local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 5), char
end

local function getDriveSeat(vehicle)
    if not vehicle then return nil end
    -- Check exact name first
    local ds = vehicle:FindFirstChild("DriveSeat")
    if ds and (ds:IsA("VehicleSeat") or ds:IsA("Seat")) then return ds end
    -- Walk descendants for any VehicleSeat
    for _, d in ipairs(vehicle:GetDescendants()) do
        if d:IsA("VehicleSeat") then return d end
    end
    -- Fallback: any part with "seat" in name
    for _, d in ipairs(vehicle:GetDescendants()) do
        if d:IsA("BasePart") and d.Name:lower():match("seat") then return d end
    end
    return nil
end

-- ============ FORCE SEAT ============
local function forceSeat(vehicle)
    if not vehicle or not vehicle.Parent then return false end

    local seat = getDriveSeat(vehicle)
    if not seat then return false end

    local hrp, char = getHRP()
    if not hrp then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    -- Already seated
    if hum.Sit then return true end

    -- Anchor all parts so vehicle doesn't fly away during teleport
    local anchored = {}
    for _, p in ipairs(vehicle:GetDescendants()) do
        if p:IsA("BasePart") then
            anchored[p] = p.Anchored
            p.Anchored = true
        end
    end

    -- Teleport HRP onto seat
    hrp.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
    task.wait(0.05)
    hum.Sit = true
    task.wait(0.15)

    -- Restore anchors
    for p, was in pairs(anchored) do
        pcall(function() p.Anchored = was end)
    end

    return hum.Sit
end

-- ============ SEAT WATCHER ============
-- Continuous Heartbeat guard — if player falls off seat while job is running, force back in.
local function stopSeatWatcher()
    if seatWatcher then
        seatWatcher:Disconnect()
        seatWatcher = nil
    end
end

local function startSeatWatcher(vehicle)
    stopSeatWatcher()
    if not vehicle then return end

    local cooldown = false
    seatWatcher = RunService.Heartbeat:Connect(function()
        if not jobRunning or not vehicle or not vehicle.Parent then
            stopSeatWatcher()
            return
        end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Sit then return end
        if cooldown then return end

        cooldown = true
        task.spawn(function()
            forceSeat(vehicle)
            task.wait(1.5)
            cooldown = false
        end)
    end)
end

-- ============ SPAWN — FIRES EXACTLY ONCE PER JOB SESSION ============
local function ensureVehicle()
    -- If we already have a valid vehicle in workspace, use it
    local existing = findVehicle()
    if existing then
        currentVehicle = existing
        return existing
    end

    -- Only fire SpawnCar once per job session
    if spawnFired then
        -- Still waiting for it to appear
        return nil
    end

    if not vehicleName then return nil end
    SpawnCarEvents.SpawnCar:FireServer(vehicleName)
    spawnFired = true

    -- Wait up to 9 seconds for it to appear
    local deadline = tick() + 9
    while tick() < deadline do
        task.wait(0.3)
        local v = findVehicle()
        if v and v:IsDescendantOf(workspace) then
            -- Confirm it has geometry
            for _, p in ipairs(v:GetDescendants()) do
                if p:IsA("BasePart") and p.Size.Magnitude > 0 then
                    currentVehicle = v
                    -- Watch for external destruction (game despawns it)
                    v.AncestryChanged:Connect(function(_, parent)
                        if not parent and currentVehicle == v then
                            currentVehicle = nil
                            -- Do NOT reset spawnFired here — let autoJobLoop decide
                        end
                    end)
                    startSeatWatcher(v)
                    return v
                end
            end
        end
    end

    -- Spawn fired but vehicle never appeared — allow one retry
    spawnFired = false
    return nil
end

-- ============ GO ONLINE ============
local function goOnline()
    if isOnline then return end
    TaxiEvent:FireServer("GoOnline")
    isOnline = true
end

local function acceptOrder(token)
    if token then TaxiEvent:FireServer("AcceptOrder", token) end
end

-- ============ MOVEMENT ENGINE ============
local function moveToTarget(targetPos, vehicle)
    local base = vehicle and (getDriveSeat(vehicle) or vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart"))
    if not base then return false end

    local noCollide = {}
    for _, p in ipairs(vehicle:GetDescendants()) do
        if p:IsA("BasePart") then
            noCollide[p] = p.CanCollide
            p.CanCollide = false
        end
    end

    local startCF = base.CFrame
    local targetCF = CFrame.new(targetPos) * (startCF - startCF.Position)
    local elapsed = 0
    local conn

    conn = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        local alpha = math.min(elapsed / tweenDuration, 1)
        local t = alpha * alpha * (3 - 2 * alpha)
        pcall(function() base.CFrame = startCF:Lerp(targetCF, t) end)

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and not hum.Sit then pcall(function() hum.Sit = true end) end

        if alpha >= 1 then
            conn:Disconnect()
            for p, was in pairs(noCollide) do pcall(function() p.CanCollide = was end) end
        end
    end)

    while conn.Connected do task.wait(0.1) end
    return true
end

local function tweenToTarget()
    local missions = workspace:FindFirstChild("ActiveMissions")
    if not missions then return end
    local guide = missions:FindFirstChild("RideGO_GuideTarget")
    if not guide then return end
    local v = currentVehicle or findVehicle()
    if not v then return end
    moveToTarget(guide.Position, v)
end

-- ============ TRIP LOOP ============
local function tripLoop()
    if tripActive then return end
    tripActive = true
    local lastPos = nil

    while tripActive and jobRunning do
        local missions = workspace:FindFirstChild("ActiveMissions")
        local guide = missions and missions:FindFirstChild("RideGO_GuideTarget")

        if guide then
            local pos = guide.Position
            if not lastPos or (pos - lastPos).Magnitude > 5 then
                lastPos = pos
                tweenToTarget()
            end
        else
            if lastPos then
                lastPos = nil
                currentToken = nil
                isOnline = false
                task.wait(0.5)
                if jobRunning then goOnline() end
            end
        end

        task.wait(0.5)
    end

    tripActive = false
end

-- ============ AUTO JOB LOOP ============
local function autoJobLoop()
    -- Fire team + online remotes immediately on start
    TeamChangeRequest:FireServer("RideGO Driver", 11378976, 1, 0, "Detector")
    task.wait(0.3)
    TaxiEvent:FireServer("GoOnline")
    isOnline = true

    while jobRunning do
        local vehicle = currentVehicle

        -- Vehicle gone externally — allow one respawn
        if not vehicle or not vehicle.Parent then
            currentVehicle = nil
            spawnFired = false   -- reset ONLY when vehicle is confirmed gone
            vehicle = ensureVehicle()
            if not vehicle then
                task.wait(2)
                continue
            end
        end

        -- Ensure seated before anything else
        local seated = false
        for _ = 1, 10 do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Sit then seated = true break end
            forceSeat(vehicle)
            task.wait(0.4)
        end

        if not seated then
            -- Seat completely failed — vehicle might be broken, respawn it
            if currentVehicle and currentVehicle.Parent then
                currentVehicle:Destroy()
            end
            currentVehicle = nil
            spawnFired = false
            task.wait(1)
            continue
        end

        if not isOnline then
            goOnline()
            task.wait(0.5)
        end

        task.wait(1)
    end
end

-- ============ EVENT HANDLERS ============
for _, key in ipairs({"__AutoTaxiConn","__AutoTaxiNotifConn","__AutoTaxiSeatWatcher"}) do
    if _G[key] then _G[key]:Disconnect() _G[key] = nil end
end

_G.__AutoTaxiNotifConn = NotifSound.OnClientEvent:Connect(function() end)

_G.__AutoTaxiConn = TaxiEvent.OnClientEvent:Connect(function(...)
    local args = {...}
    local action, data = args[1], args[2]

    if action == "OrderOffer" and jobRunning and typeof(data) == "table" then
        currentToken = data.Token
        task.wait(0.3)
        acceptOrder(currentToken)

    elseif action == "OrderAccepted" and jobRunning then
        if not tripActive then task.spawn(tripLoop) end

    elseif action == "OrderCompleted" then
        tripActive = false
        isOnline = false
        task.wait(0.5)
        if jobRunning then goOnline() end
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
        currentVehicle = nil
        spawnFired = false
        stopSeatWatcher()
    end,
})

Tab:CreateButton({
    Name = "Refresh Daftar Motor",
    Callback = function()
        vehicleList = getVehicleList()
        Rayfield:Notify({ Title = "Refreshed", Content = #vehicleList .. " motor ditemukan", Duration = 3 })
    end,
})

Tab:CreateSlider({
    Name = "Durasi Tween (detik)",
    Range = {5, 30},
    Increment = 1,
    Suffix = " detik",
    CurrentValue = 20,
    Flag = "TweenDuration",
    Callback = function(Value) tweenDuration = Value end,
})

Tab:CreateToggle({
    Name = "Start Job Auto Repeat",
    CurrentValue = false,
    Flag = "AutoJob",
    Callback = function(Value)
        jobRunning = Value
        if jobRunning then
            currentVehicle = nil
            spawnFired = false
            isOnline = false
            tripActive = false
            task.spawn(autoJobLoop)
        else
            tripActive = false
            isOnline = false
            stopSeatWatcher()
        end
    end,
})