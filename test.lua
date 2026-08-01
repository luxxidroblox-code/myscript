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
local jobRunning     = false
local vehicleName    = nil
local currentToken   = nil
local isOnline       = false
local tripActive     = false
local tweenDuration  = 20
local currentVehicle = nil
local spawnFired     = false
local seatWatcher    = nil

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
warn("[AutoTaxi] vehicleList built —", #vehicleList, "entries. Default:", tostring(vehicleName))

-- ============ HELPERS ============
local function findVehicle()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:match("^LikasturaMontors_") then
            warn("[findVehicle] Found:", obj.Name)
            return obj
        end
    end
    warn("[findVehicle] No vehicle found in workspace")
    return nil
end

local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    warn("[getHRP] HRP:", hrp and "OK" or "NIL")
    return hrp, char
end

local function getDriveSeat(vehicle)
    if not vehicle then
        warn("[getDriveSeat] vehicle is nil")
        return nil
    end
    local ds = vehicle:FindFirstChild("DriveSeat")
    if ds and (ds:IsA("VehicleSeat") or ds:IsA("Seat")) then
        warn("[getDriveSeat] Found by name 'DriveSeat' — class:", ds.ClassName)
        return ds
    end
    for _, d in ipairs(vehicle:GetDescendants()) do
        if d:IsA("VehicleSeat") then
            warn("[getDriveSeat] Found VehicleSeat descendant:", d.Name)
            return d
        end
    end
    for _, d in ipairs(vehicle:GetDescendants()) do
        if d:IsA("BasePart") and d.Name:lower():match("seat") then
            warn("[getDriveSeat] Fallback seat by name match:", d.Name)
            return d
        end
    end
    warn("[getDriveSeat] No seat found in vehicle:", vehicle.Name)
    return nil
end

-- ============ FORCE SEAT ============
local function forceSeat(vehicle)
    warn("[forceSeat] Attempting seat on:", vehicle and vehicle.Name or "NIL")
    if not vehicle or not vehicle.Parent then
        warn("[forceSeat] Vehicle invalid or not in workspace")
        return false
    end

    local seat = getDriveSeat(vehicle)
    if not seat then
        warn("[forceSeat] No seat found — aborting")
        return false
    end
    warn("[forceSeat] Targeting seat:", seat.Name, "at", tostring(seat.Position))

    local hrp, char = getHRP()
    if not hrp then
        warn("[forceSeat] HRP is nil — cannot seat")
        return false
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        warn("[forceSeat] Humanoid not found")
        return false
    end

    if hum.Sit then
        warn("[forceSeat] Already seated — skipping")
        return true
    end

    warn("[forceSeat] Anchoring vehicle parts")
    local anchored = {}
    for _, p in ipairs(vehicle:GetDescendants()) do
        if p:IsA("BasePart") then
            anchored[p] = p.Anchored
            p.Anchored = true
        end
    end

    warn("[forceSeat] Teleporting HRP to seat CFrame")
    hrp.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
    task.wait(0.05)
    warn("[forceSeat] Setting hum.Sit = true")
    hum.Sit = true
    task.wait(0.15)

    warn("[forceSeat] Restoring anchor states")
    for p, was in pairs(anchored) do
        pcall(function() p.Anchored = was end)
    end

    warn("[forceSeat] Sit result:", tostring(hum.Sit))
    return hum.Sit
end

-- ============ SEAT WATCHER ============
local function stopSeatWatcher()
    if seatWatcher then
        warn("[SeatWatcher] Disconnecting watcher")
        seatWatcher:Disconnect()
        seatWatcher = nil
    end
end

local function startSeatWatcher(vehicle)
    stopSeatWatcher()
    if not vehicle then
        warn("[SeatWatcher] No vehicle — watcher not started")
        return
    end
    warn("[SeatWatcher] Starting watcher on:", vehicle.Name)

    local cooldown = false
    seatWatcher = RunService.Heartbeat:Connect(function()
        if not jobRunning or not vehicle or not vehicle.Parent then
            warn("[SeatWatcher] Job stopped or vehicle gone — disconnecting")
            stopSeatWatcher()
            return
        end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Sit then return end
        if cooldown then return end

        warn("[SeatWatcher] Player not seated — triggering forceSeat")
        cooldown = true
        task.spawn(function()
            forceSeat(vehicle)
            task.wait(1.5)
            cooldown = false
        end)
    end)
end

-- ============ SPAWN ============
local function ensureVehicle()
    warn("[ensureVehicle] Checking for existing vehicle in workspace")
    local existing = findVehicle()
    if existing then
        warn("[ensureVehicle] Using existing vehicle:", existing.Name)
        currentVehicle = existing
        return existing
    end

    if spawnFired then
        warn("[ensureVehicle] SpawnCar already fired — waiting for vehicle to appear")
        return nil
    end

    if not vehicleName then
        warn("[ensureVehicle] vehicleName is nil — cannot spawn")
        return nil
    end

    warn("[ensureVehicle] Firing SpawnCar for:", vehicleName)
    SpawnCarEvents.SpawnCar:FireServer(vehicleName)
    spawnFired = true

    local deadline = tick() + 9
    warn("[ensureVehicle] Waiting up to 9s for vehicle to materialize")
    while tick() < deadline do
        task.wait(0.3)
        local v = findVehicle()
        if v and v:IsDescendantOf(workspace) then
            for _, p in ipairs(v:GetDescendants()) do
                if p:IsA("BasePart") and p.Size.Magnitude > 0 then
                    warn("[ensureVehicle] Vehicle confirmed:", v.Name)
                    currentVehicle = v
                    v.AncestryChanged:Connect(function(_, parent)
                        if not parent and currentVehicle == v then
                            warn("[ensureVehicle] Vehicle removed from workspace externally")
                            currentVehicle = nil
                        end
                    end)
                    startSeatWatcher(v)
                    return v
                end
            end
        end
    end

    warn("[ensureVehicle] Timeout — vehicle never appeared. Resetting spawnFired")
    spawnFired = false
    return nil
end

-- ============ GO ONLINE ============
local function goOnline()
    if isOnline then
        warn("[goOnline] Already online — skipping")
        return
    end
    warn("[goOnline] Firing GoOnline remote")
    TaxiEvent:FireServer("GoOnline")
    isOnline = true
    warn("[goOnline] isOnline = true")
end

local function acceptOrder(token)
    warn("[acceptOrder] Firing AcceptOrder with token:", tostring(token))
    if token then TaxiEvent:FireServer("AcceptOrder", token) end
end

-- ============ MOVEMENT ENGINE ============
local function moveToTarget(targetPos, vehicle)
    warn("[moveToTarget] Moving to:", tostring(targetPos))
    local base = vehicle and (getDriveSeat(vehicle) or vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart"))
    if not base then
        warn("[moveToTarget] No base part found — aborting move")
        return false
    end
    warn("[moveToTarget] Using base part:", base.Name)

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
        if hum and not hum.Sit then
            warn("[moveToTarget] Player fell off mid-tween — forcing sit")
            pcall(function() hum.Sit = true end)
        end

        if alpha >= 1 then
            warn("[moveToTarget] Tween complete")
            conn:Disconnect()
            for p, was in pairs(noCollide) do pcall(function() p.CanCollide = was end) end
        end
    end)

    while conn.Connected do task.wait(0.1) end
    return true
end

local function tweenToTarget()
    warn("[tweenToTarget] Looking for ActiveMissions > RideGO_GuideTarget")
    local missions = workspace:FindFirstChild("ActiveMissions")
    if not missions then
        warn("[tweenToTarget] ActiveMissions not found")
        return
    end
    local guide = missions:FindFirstChild("RideGO_GuideTarget")
    if not guide then
        warn("[tweenToTarget] RideGO_GuideTarget not found")
        return
    end
    warn("[tweenToTarget] GuideTarget at:", tostring(guide.Position))
    local v = currentVehicle or findVehicle()
    if not v then
        warn("[tweenToTarget] No vehicle for movement")
        return
    end
    moveToTarget(guide.Position, v)
end

-- ============ TRIP LOOP ============
local function tripLoop()
    if tripActive then
        warn("[tripLoop] Already active — skipping duplicate spawn")
        return
    end
    tripActive = true
    warn("[tripLoop] Trip started")
    local lastPos = nil

    while tripActive and jobRunning do
        local missions = workspace:FindFirstChild("ActiveMissions")
        local guide = missions and missions:FindFirstChild("RideGO_GuideTarget")

        if guide then
            local pos = guide.Position
            if not lastPos or (pos - lastPos).Magnitude > 5 then
                warn("[tripLoop] New guide position detected — tweening:", tostring(pos))
                lastPos = pos
                tweenToTarget()
            end
        else
            if lastPos then
                warn("[tripLoop] GuideTarget gone — trip complete. Going online again")
                lastPos = nil
                currentToken = nil
                isOnline = false
                task.wait(0.5)
                if jobRunning then goOnline() end
            end
        end

        task.wait(0.5)
    end

    warn("[tripLoop] Trip loop exited. tripActive:", tostring(tripActive), "jobRunning:", tostring(jobRunning))
    tripActive = false
end

-- ============ AUTO JOB LOOP ============
local function autoJobLoop()
    warn("[autoJobLoop] Starting — firing TeamChangeRequest + GoOnline")
    TeamChangeRequest:FireServer("RideGO Driver", 11378976, 1, 0, "Detector")
    task.wait(0.3)
    TaxiEvent:FireServer("GoOnline")
    isOnline = true
    warn("[autoJobLoop] Team set. isOnline = true")

    while jobRunning do
        local vehicle = currentVehicle
        warn("[autoJobLoop] Tick — currentVehicle:", vehicle and vehicle.Name or "NIL")

        if not vehicle or not vehicle.Parent then
            warn("[autoJobLoop] Vehicle missing — resetting spawnFired and respawning")
            currentVehicle = nil
            spawnFired = false
            vehicle = ensureVehicle()
            if not vehicle then
                warn("[autoJobLoop] ensureVehicle returned nil — waiting 2s")
                task.wait(2)
                continue
            end
        end

        warn("[autoJobLoop] Attempting seat — up to 10 tries")
        local seated = false
        for i = 1, 10 do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Sit then
                warn("[autoJobLoop] Seated on attempt", i)
                seated = true
                break
            end
            warn("[autoJobLoop] Seat attempt", i, "— not seated yet")
            forceSeat(vehicle)
            task.wait(0.4)
        end

        if not seated then
            warn("[autoJobLoop] All seat attempts failed — destroying vehicle and respawning")
            if currentVehicle and currentVehicle.Parent then
                currentVehicle:Destroy()
            end
            currentVehicle = nil
            spawnFired = false
            task.wait(1)
            continue
        end

        if not isOnline then
            warn("[autoJobLoop] Not online — calling goOnline()")
            goOnline()
            task.wait(0.5)
        end

        task.wait(1)
    end

    warn("[autoJobLoop] jobRunning = false — loop exited")
end

-- ============ EVENT HANDLERS ============
for _, key in ipairs({"__AutoTaxiConn","__AutoTaxiNotifConn","__AutoTaxiSeatWatcher"}) do
    if _G[key] then
        warn("[Cleanup] Disconnecting old handler:", key)
        _G[key]:Disconnect()
        _G[key] = nil
    end
end

_G.__AutoTaxiNotifConn = NotifSound.OnClientEvent:Connect(function()
    warn("[NotifSound] Notification fired")
end)

_G.__AutoTaxiConn = TaxiEvent.OnClientEvent:Connect(function(...)
    local args = {...}
    local action, data = args[1], args[2]
    warn("[TaxiEvent] Received action:", tostring(action), "| data type:", typeof(data))

    if action == "OrderOffer" and jobRunning and typeof(data) == "table" then
        warn("[TaxiEvent] OrderOffer — token:", tostring(data.Token))
        currentToken = data.Token
        task.wait(0.3)
        acceptOrder(currentToken)

    elseif action == "OrderAccepted" and jobRunning then
        warn("[TaxiEvent] OrderAccepted — spawning tripLoop")
        if not tripActive then task.spawn(tripLoop) end

    elseif action == "OrderCompleted" then
        warn("[TaxiEvent] OrderCompleted — resetting trip state")
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
        warn("[UI] Vehicle changed to:", Option[1])
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
        warn("[UI] Vehicle list refreshed —", #vehicleList, "entries")
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
    Callback = function(Value)
        warn("[UI] tweenDuration set to:", Value)
        tweenDuration = Value
    end,
})

Tab:CreateToggle({
    Name = "Start Job Auto Repeat",
    CurrentValue = false,
    Flag = "AutoJob",
    Callback = function(Value)
        warn("[UI] AutoJob toggle:", tostring(Value))
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
            warn("[UI] Job stopped — watchers cleared")
        end
    end,
})