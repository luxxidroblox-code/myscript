local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")

-- ============================================================
-- ANTI PAUSE & ANTI AFK
-- ============================================================
local pauseGui = CoreGui:FindFirstChild("RobloxNetworkPauseNotification")
if pauseGui then pauseGui.Enabled = false end

game:GetService("Players").LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp       = character:WaitForChild("HumanoidRootPart")

-- ============================================================
-- COURIER JOB STATE
-- ============================================================
local autofarmstart  = false
local selectedVehicle = "2019HijetTruckBoxCourier"
local teleportTime   = 21

local initialMoney      = 0
local farmStartTime     = 0
local countdownTime     = 0
local lastEarned        = 0
local currentHourlyRate = 0

local vehiclelist = {
    "2024ElfEV",
    "2024ElfDiesel",
    "2014AD150Courier",
    "2014HiaceDX4WDCourier",
    "2008HiaceDXCourier",
    "2016ProboxCourier",
    "2017HijetCargoCourier",
    "2020EveryPACourier",
    "2019HijetTruckBoxCourier",
}

local lokasijomok = {
    ["TriggerJob"] = {
        Position = Vector3.new(-482.514832, 8.28940201, -220.797409),
        CFrame   = CFrame.new(-482.514832, 8.28940201, -220.797409, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    },
    ["Spawner"] = {
        Position = Vector3.new(-522.376709, 6.39453697, -158.395432),
        CFrame   = CFrame.new(-522.376709, 6.39453697, -158.395432, 0.484826028, 0, 0.874610603, 0, 1, 0, -0.874610603, 0, 0.484826028),
    },
    ["Sakura Hills Apartment"] = {
        Position = Vector3.new(-328.697723, 5.89059401, -698.436829),
        CFrame   = CFrame.new(-328.697723, 5.89059401, -698.436829, -0.499959469, 0, -0.866048813, 0, 1, 0, 0.866048813, 0, -0.499959469),
    },
    ["Rafuuna's Warehouse"] = {
        Position = Vector3.new(-1572.11963, 5.12375069, -87.1921387),
        CFrame   = CFrame.new(-1572.11963, 5.12375069, -87.1921387, 0.996191859, -0, -0.0871884301, 0, 1, -0, 0.0871884301, 0, 0.996191859),
    },
    ["Kogane's Storage"] = {
        Position = Vector3.new(363.579895, 5.12027216, 120.865082),
        CFrame   = CFrame.new(363.579895, 5.12027216, 120.865082, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    },
    ["Akebono Market"] = {
        Position = Vector3.new(233.844345, 5.07027197, 453.023499),
        CFrame   = CFrame.new(233.844345, 5.07027197, 453.023499, 0.939700544, -0, -0.341998369, 0, 1, -0, 0.341998369, 0, 0.939700544),
    },
    ["Densu Dealership"] = {
        Position = Vector3.new(-8013.87109, 6.4607296, 598.06543),
        CFrame   = CFrame.new(-8013.87109, 6.4607296, 598.06543, -0.996191859, 0, -0.0871884301, 0, 1, 0, 0.871884301, 0, -0.996191859),
    },
    ["Shizuka Terrace"] = {
        Position = Vector3.new(-2897.11548, -40.1908607, 9563.4043),
        CFrame   = CFrame.new(-2897.11548, -40.1908607, 9563.4043, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268),
    },
    ["Eizōya Select"] = {
        Position = Vector3.new(990.303528, 5.11927795, -1307.03931),
        CFrame   = CFrame.new(990.303528, 5.11927795, -1307.03931, -0.0523990393, 0, 0.998626292, 0, 1, 0, -0.998626292, 0, -0.0523990393),
    },
    ["Be Backwards Dealership"] = {
        Position = Vector3.new(2022.57397, 5.05900002, -5128.46582),
        CFrame   = CFrame.new(2025.32, 3.07, -5132.90) * CFrame.Angles(0.0000, -0.2547, -0.0000),
    },
    ["Courier Storage 2"] = {
        Position = Vector3.new(4021.11841, 5.03000927, -7485.104),
        CFrame   = CFrame.new(4021.11841, 5.03000927, -7485.104, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    },
    ["Himawari Wellness Clinic"] = {
        Position = Vector3.new(5029.77441, 5.17267847, -9796.75391),
        CFrame   = CFrame.new(5029.77441, 5.17267847, -9796.75391, -0.939700961, 0, 0.341998369, 0, 1, 0, -0.341998369, 0, -0.939700961),
    },
    ["Fire Department"] = {
        Position = Vector3.new(6091.86328, 5.17267847, -12092.9844),
        CFrame   = CFrame.new(6091.86328, 5.17267847, -12092.9844, -0.342042685, 0, -0.939684391, 0, 1, 0, 0.939684391, 0, -0.342042685),
    },
    ["Tsukiichi Market"] = {
        Position = Vector3.new(6038.05859, 5.17267847, -10316.4775),
        CFrame   = CFrame.new(6038.05859, 5.17267847, -10316.4775, 0.548200727, 0, 0.836346805, 0, 1, 0, -0.836346805, 0, 0.548200727),
    },
}

-- ============================================================
-- COURIER HELPERS
-- ============================================================
local function getPlayerMoney()
    local success, val = pcall(function()
        local pd = player:FindFirstChild("PlayerData")
        if pd then
            local yen = pd:FindFirstChild("Yen")
            if yen then return tonumber(yen.Value) or 0 end
        end
        return 0
    end)
    return (success and val) and val or 0
end

local currentState          = nil
local lastestdetectedCframe = nil
local lastestdetectedName   = nil

local function findLocationByPosition(pos, tolerance)
    tolerance = tolerance or 5
    local closestName, closestData, closestDist = nil, nil, math.huge
    for name, data in pairs(lokasijomok) do
        local dist = (data.Position - pos).Magnitude
        if dist < closestDist then
            closestName, closestData, closestDist = name, data, dist
        end
    end
    if closestData and closestDist <= tolerance then
        return closestName, closestData, closestDist
    end
    return nil, nil, closestDist
end

local MoveArrow = ReplicatedStorage.General.MoveArrow
MoveArrow.OnClientEvent:Connect(function(pos)
    if currentState == nil then
        if typeof(pos) == "Vector3" and hrp then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        end
    elseif currentState == "Spawn" then
        if typeof(pos) == "Vector3" then
            local name, data = findLocationByPosition(pos)
            if data then
                lastestdetectedName   = name
                lastestdetectedCframe = data.CFrame
            else
                lastestdetectedName   = nil
                lastestdetectedCframe = CFrame.new(pos)
            end
        end
    end
end)

local function teleportToJob()
    local Event = ReplicatedStorage.Job.General.Remotes.Client.SetJob
    Event:InvokeServer("CourierDriver")
    local job    = workspace:FindFirstChild("Job")
    local driver = job and job:FindFirstChild("CourierDriver")
    local start  = driver and driver:FindFirstChild("Start")
    if not start and hrp then
        hrp.CFrame = CFrame.new(-482.514832, 8.28940201, -220.797409, 0, 0, 1, 0, 1, -0, -1, 0, 0)
    end
    task.wait(1)
    currentState = "Spawn"
    if workspace.Job.CourierDriver.Start.Start:FindFirstChild("ProximityPrompt") then
        fireproximityprompt(workspace.Job.CourierDriver.Start.Start.ProximityPrompt)
    end
    task.wait(2)
    if hrp then
        hrp.CFrame = CFrame.new(workspace.Job.CourierDriver.CarSpawns.Prompt1.Position)
    end
    task.wait(1)
    if workspace.Job.CourierDriver.CarSpawns.Prompt1:FindFirstChild("ProximityPrompt") then
        fireproximityprompt(workspace.Job.CourierDriver.CarSpawns.Prompt1.ProximityPrompt)
    end
end

local function getVehicle(name)
    local vehicles = Workspace:FindFirstChild("PlayerCars")
    if not vehicles then return nil end
    for _, v in ipairs(vehicles:GetChildren()) do
        if v:IsA("Model") and v.Name == name .. "sCar" then
            local seat = v:FindFirstChild("DriveSeat", true)
            if seat then
                v.PrimaryPart = seat
                return v
            end
        end
    end
    return nil
end

local function main()
    local v173

    local function spawnSelectedVehicle()
        local vehicleName  = selectedVehicle
        local vehicleFrame = player.PlayerGui.JobGui.Canvas.JobInterfaces.CarSpawner.AvailableCars:FindFirstChild(vehicleName)

        if vehicleFrame then
            local lockedFrame = vehicleFrame:FindFirstChild("Locked")
            if lockedFrame and lockedFrame:IsA("GuiObject") and not lockedFrame.Visible then
                ReplicatedStorage.Job.General.Remotes.Client.SpawnCar:FireServer(vehicleName)
                local s = tick()
                while tick() - s < 5 do
                    local pc = Workspace.PlayerCars:FindFirstChild(player.Name .. "sCar")
                    if pc then return pc end
                    task.wait(0.1)
                end
                return nil
            end
        end

        for _, name in ipairs(vehiclelist) do
            local frame = player.PlayerGui.JobGui.Canvas.JobInterfaces.CarSpawner.AvailableCars:FindFirstChild(name)
            if frame then
                local locked = frame:FindFirstChild("Locked")
                if locked and locked:IsA("GuiObject") and not locked.Visible then
                    ReplicatedStorage.Job.General.Remotes.Client.SpawnCar:FireServer(name)
                    local s = tick()
                    while tick() - s < 5 do
                        local pc = Workspace.PlayerCars:FindFirstChild(player.Name .. "sCar")
                        if pc then return pc end
                        task.wait(0.1)
                    end
                    return nil
                end
            end
        end
        return nil
    end

    local function spawnVehiclerer()
        local start = tick()
        v173 = nil
        repeat
            v173 = workspace:WaitForChild("PlayerCars"):FindFirstChild(player.Name .. "sCar")
            task.wait()
        until v173 or tick() - start > 10 or not autofarmstart
        if not v173 or not autofarmstart then return false end

        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        task.wait(1)

        local promptdriveseat = v173:WaitForChild("DriveSeat"):FindFirstChild("DrivePrompt")
        if not promptdriveseat then return false end
        promptdriveseat.Enabled = true
        fireproximityprompt(promptdriveseat)
        task.wait(3)

        local timeout = 0
        repeat
            task.wait(0.1)
            timeout  = timeout + 0.1
            humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        until (humanoid and humanoid.SeatPart) or timeout >= 10 or not autofarmstart

        if not humanoid or not humanoid.SeatPart then return false end
        return true
    end

    local function newFarming()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or not humanoid.SeatPart then return end

        getVehicle(player.Name)

        local _Parent2 = humanoid.SeatPart.Parent
        if not _Parent2 then return end

        _Parent2.PrimaryPart = humanoid.SeatPart
        local _PrimaryPart   = _Parent2.PrimaryPart
        if not _PrimaryPart then return end

        local function resetVelocity()
            for _, part in ipairs(_Parent2:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.AssemblyLinearVelocity  = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end

        local function v191(p186, p187)
            local v188      = TweenInfo.new(p187, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
            local cfValue   = Instance.new("CFrameValue")
            cfValue.Value   = _Parent2:GetPrimaryPartCFrame()

            cfValue.Changed:Connect(function()
                _Parent2:PivotTo(cfValue.Value)
                resetVelocity()
            end)

            local v190 = TweenService:Create(cfValue, v188, { Value = p186 })
            v190:Play()

            if p187 > 0 then
                countdownTime = p187
                task.spawn(function()
                    while countdownTime > 0 and autofarmstart do
                        task.wait(1)
                        countdownTime = math.max(0, countdownTime - 1)
                    end
                end)
            end

            v190.Completed:Wait()
            cfValue:Destroy()
            resetVelocity()
        end

        local lastWaypointCFrame = nil

        while autofarmstart do
            humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid or not humanoid.SeatPart then
                warn("Seat hilang, mematikan autofarm")
                break
            end

            _Parent2             = humanoid.SeatPart.Parent
            if not _Parent2 then break end
            _Parent2.PrimaryPart = humanoid.SeatPart
            _PrimaryPart         = _Parent2.PrimaryPart

            local waypoint = workspace:FindFirstChild("General") and workspace.General:FindFirstChild("Waypoint")
            if not waypoint then
                task.wait(0.5)
            else
                local rawCFrame      = waypoint.CFrame
                local beBackwardsPos = Vector3.new(2022.57397, 5.05900002, -5128.46582)
                local isBeBackwards  = (rawCFrame.Position - beBackwardsPos).Magnitude < 100

                local baseCFrame
                if isBeBackwards then
                    baseCFrame = CFrame.new(2025.32, 3.07, -5132.90) * CFrame.Angles(0.0000, -0.2547, -0.0000)
                else
                    local _, ry, _ = rawCFrame:ToOrientation()
                    baseCFrame     = CFrame.new(rawCFrame.Position) * CFrame.Angles(0, ry, 0)
                end

                local isElfOrTruck  = string.find(selectedVehicle:lower(), "elf")
                                   or string.find(selectedVehicle:lower(), "truck")
                                   or string.find(_Parent2.Name:lower(), "elf")
                                   or string.find(_Parent2.Name:lower(), "truck")

                local forwardOffset = isElfOrTruck and 5.5 or 2.0

                local waypointCFrame
                if isBeBackwards then
                    waypointCFrame = baseCFrame
                else
                    waypointCFrame = baseCFrame + (baseCFrame.LookVector * forwardOffset) - Vector3.new(0, 1.2, 0)
                end

                if lastWaypointCFrame ~= nil and waypointCFrame == lastWaypointCFrame then
                    task.wait(0.5)
                else
                    workspace.Gravity = 0
                    resetVelocity()
                    v191(_PrimaryPart.CFrame + Vector3.new(0, 1000, 0), 0)
                    v191(waypointCFrame + Vector3.new(0, 1000, 0), 0)
                    v191(waypointCFrame, teleportTime)
                    workspace.Gravity = 196.2
                    resetVelocity()
                    task.wait(1.2)
                    lastWaypointCFrame = waypointCFrame
                end
            end
        end

        workspace.Gravity = 196.2
        resetVelocity()
        task.wait(0.5)
    end

    teleportToJob()
    task.wait(1)
    if not autofarmstart then return end

    local vehicle = spawnSelectedVehicle()
    if not vehicle then return end

    local vehicleSpawn = spawnVehiclerer()
    if vehicleSpawn and autofarmstart then
        newFarming()
    end
end

-- ============================================================
-- AUTO RACE STATE
-- ============================================================
local raceRunning  = false
local raceTpTime   = 5

local raceCheckpoints = {
    CFrame.new(306.730, 150.496, 2481.263, 0.937, 0.005, -0.350, -0.002, 1.000, 0.009, 0.350, -0.008, 0.937),
    CFrame.new(326.823, 147.392, 2262.260, 0.966, -0.010, -0.257, -0.024, 0.992, -0.126, 0.256, 0.128, 0.958),
    CFrame.new(627.335, 102.014, 1744.822, 0.557, -0.225, -0.799, 0.055, 0.970, -0.235, 0.829, 0.087, 0.553),
    CFrame.new(563.848, 73.359, 1043.875, 0.624, 0.132, 0.771, -0.006, 0.986, -0.164, -0.782, 0.098, 0.616),
    CFrame.new(203.609, 61.644, 508.836, 0.058, 0.219, 0.974, -0.012, 0.976, -0.219, -0.998, 0.001, 0.060),
    CFrame.new(-53.878, 31.175, 115.163, 0.999, 0.019, 0.045, -0.009, 0.974, -0.227, -0.048, 0.226, 0.973),
    CFrame.new(-926.268, 25.998, 6.413, 0.043, 0.193, 0.980, 0.006, 0.981, -0.193, -0.999, 0.014, 0.041),
    CFrame.new(-1459.487, 2.760, 669.708, 0.991, 0.031, 0.129, -0.001, 0.974, -0.226, -0.133, 0.223, 0.966) * CFrame.new(0, 0, 5),
    CFrame.new(-1839.563, 12.334, 43.834, 0.735, 0.148, 0.662, -0.000, 0.976, -0.218, -0.678, 0.160, 0.717) * CFrame.new(0, 0, 5),
    CFrame.new(-2625.543, 12.284, -759.915, -0.041, 0.228, 0.973, 0.000, 0.974, -0.228, -0.999, -0.009, -0.040),
    CFrame.new(-3326.966, -9.079, -941.116, 0.329, 0.212, 0.920, -0.000, 0.974, -0.225, -0.944, 0.074, 0.321),
    CFrame.new(-3614.975, -29.626, -1396.650, 0.904, 0.099, 0.416, -0.000, 0.973, -0.232, -0.427, 0.210, 0.879),
    CFrame.new(-4154.276, -26.309, -1671.829, 0.302, 0.219, 0.928, 0.005, 0.973, -0.231, -0.953, 0.074, 0.293),
    CFrame.new(-4722.355, -65.885, -1519.478, -0.735, 0.028, 0.677, 0.008, 0.999, -0.033, -0.678, -0.018, -0.735),
    CFrame.new(-5130.196, -74.003, -891.922, -0.761, 0.152, 0.630, 0.007, 0.974, -0.227, -0.648, -0.169, -0.743),
    CFrame.new(-5263.064, -73.693, -443.458, -1.000, 0.004, -0.016, 0.008, 0.974, -0.224, 0.015, -0.225, -0.974),
    CFrame.new(-5835.653, -115.926, 132.166, -0.344, 0.164, 0.924, 0.066, 0.986, -0.151, -0.937, 0.009, -0.350),
    CFrame.new(-6094.300, -165.720, 383.025, -0.841, 0.032, 0.540, -0.010, 0.997, -0.074, -0.541, -0.068, -0.839),
    CFrame.new(-6328.751, -211.052, 673.646, -0.902, 0.061, 0.427, 0.000, 0.990, -0.141, -0.432, -0.127, -0.893),
    CFrame.new(-6587.236, -227.868, 941.343, -0.661, 0.166, 0.732, -0.000, 0.975, -0.221, -0.751, -0.146, -0.644),
    CFrame.new(-6854.230, -227.864, 1107.610, -0.607, 0.177, 0.775, 0.000, 0.975, -0.222, -0.795, -0.135, -0.592),
    CFrame.new(-7109.637, -227.903, 1282.685, -0.634, 0.173, 0.754, -0.000, 0.975, -0.224, -0.774, -0.142, -0.618),
    CFrame.new(-7262.330, -227.894, 1405.334, -0.611, 0.179, 0.771, 0.000, 0.974, -0.227, -0.791, -0.138, -0.595),
    CFrame.new(-7624.308, -227.886, 1632.237, -0.471, 0.199, 0.859, 0.001, 0.974, -0.225, -0.882, -0.106, -0.459),
    CFrame.new(-8153.211, -227.887, 1846.007, -0.335, 0.213, 0.918, 0.001, 0.974, -0.225, -0.942, -0.075, -0.327),
    CFrame.new(-9049.890, -227.825, 2334.867, -0.511, 0.170, 0.843, -0.000, 0.980, -0.198, -0.860, -0.101, -0.501),
}

local function getRaceVehicle()
    local char2 = player.Character
    if not char2 then return nil end
    local hum = char2:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        return hum.SeatPart.Parent
    end
    return nil
end

local function raceResetVelocity(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity  = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

local function raceTweenTo(model, targetCFrame, duration)
    local char2 = player.Character
    if not char2 then return end
    local hum = char2:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return end
    model.PrimaryPart = hum.SeatPart

    local snapshot = {}
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            snapshot[part]  = part.CanCollide
            part.CanCollide = false
        end
    end

    local noclipConn = RunService.Stepped:Connect(function()
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)

    local cfValue = Instance.new("CFrameValue")
    cfValue.Value = model:GetPrimaryPartCFrame()

    cfValue.Changed:Connect(function()
        model:PivotTo(cfValue.Value)
        raceResetVelocity(model)
    end)

    workspace.Gravity = 0
    raceResetVelocity(model)

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local tween     = TweenService:Create(cfValue, tweenInfo, { Value = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
    cfValue:Destroy()

    workspace.Gravity = 196.2
    raceResetVelocity(model)

    noclipConn:Disconnect()
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and snapshot[part] ~= nil then
            part.CanCollide = snapshot[part]
        end
    end
end

local function raceInstantTo(model, targetCFrame)
    local char2 = player.Character
    if not char2 then return end
    local hum = char2:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return end
    model.PrimaryPart = hum.SeatPart
    workspace.Gravity = 0
    model:PivotTo(targetCFrame)
    raceResetVelocity(model)
    workspace.Gravity = 196.2
end

local function runRaceLoop()
    local ShowRaceTrack = ReplicatedStorage.Race.Remotes.ShowRaceTrack

    while raceRunning do
        local char2 = player.Character or player.CharacterAdded:Wait()

        local vehicle = getRaceVehicle()
        if vehicle then
            raceInstantTo(vehicle, raceCheckpoints[1])
        else
            char2:PivotTo(raceCheckpoints[1])
        end

        local raceStarted = false
        local conn
        conn = ShowRaceTrack.OnClientEvent:Connect(function(state)
            if state == true then
                raceStarted = true
                conn:Disconnect()
            end
        end)

        local elapsed = 0
        while not raceStarted and elapsed < 60 and raceRunning do
            task.wait(0.5)
            elapsed += 0.5
        end
        if conn then conn:Disconnect() end

        if not raceStarted then
            warn("[AutoRace] ShowRaceTrack timeout — retrying...")
            task.wait(3)
            continue
        end

        task.wait(12)

        for i = 2, #raceCheckpoints do
            if not raceRunning then break end
            vehicle = getRaceVehicle()
            if vehicle then
                raceTweenTo(vehicle, raceCheckpoints[i], raceTpTime)
            else
                char2:PivotTo(raceCheckpoints[i])
            end
            task.wait(1)
        end

        task.wait(2)
    end
end

-- ============================================================
-- RAYFIELD GEN2 UI
-- ============================================================
local window = Rayfield:CreateWindow({
    name     = "Projectsion",
    subtitle = "Driving Experience: Japan",
    theme    = "cobalt",
})

-- ── TAB 1: AUTO FARM ────────────────────────────────────────
local autoJobTab = window:CreateTab({ name = "AutoFarm" })

autoJobTab:CreateDropdown({
    name            = "Select Vehicle",
    options         = vehiclelist,
    currentOption   = { selectedVehicle },
    multipleOptions = false,
    callback        = function(option)
        selectedVehicle = type(option) == "table" and option[1] or option
    end,
})

autoJobTab:CreateSlider({
    name      = "Teleport Delay",
    range     = { 1, 60 },
    increment = 1,
    value     = teleportTime,
    suffix    = " Seconds",
    callback  = function(value)
        teleportTime = value
    end,
})

autoJobTab:CreateToggle({
    name     = "Start AutoFarm",
    callback = function(value)
        autofarmstart = value
        if autofarmstart then
            initialMoney    = getPlayerMoney()
            farmStartTime   = tick()
            lastEarned      = 0
            currentHourlyRate = 0
            task.spawn(main)
        else
            countdownTime     = 0
            workspace.Gravity = 196.2
            lastEarned        = 0
            currentHourlyRate = 0
        end
    end,
})

-- ── TAB 2: AUTO RACE ────────────────────────────────────────
local autoRaceTab = window:CreateTab({ name = "Auto Race" })

autoRaceTab:CreateSlider({
    name      = "Teleport Time",
    range     = { 1, 20 },
    increment = 1,
    value     = raceTpTime,
    suffix    = " Seconds",
    callback  = function(value)
        raceTpTime = value
    end,
})

autoRaceTab:CreateToggle({
    name     = "Start Auto Race",
    callback = function(state)
        if state then
            local char2   = player.Character or player.CharacterAdded:Wait()
            local vehicle = getRaceVehicle()

            if not vehicle then
                Rayfield:Notify({
                    title    = "Auto Race",
                    content  = "Spawn your car first before starting the auto race.",
                    duration = 5,
                })
                -- Gen2 toggle off: set via flag table
                Rayfield.Flags["Start Auto Race"] = false
                return
            end

            raceRunning = true
            task.spawn(runRaceLoop)
        else
            raceRunning = false
        end
    end,
})

-- ── TAB 3: STATS ────────────────────────────────────────────
local statsTab = window:CreateTab({ name = "Stats" })

local nextTeleportStat = statsTab:CreateStat({
    name   = "Next Teleport In",
    suffix = "s",
    value  = 0,
})

local earnedMoneyStat = statsTab:CreateStat({
    name   = "Total Earned Money",
    prefix = "¥",
    value  = 0,
})

local hourlyRateStat = statsTab:CreateStat({
    name   = "Income per Hour",
    prefix = "¥",
    suffix = " / Hour",
    value  = 0,
})

task.spawn(function()
    while task.wait(0.5) do
        if autofarmstart then
            nextTeleportStat:Set(math.ceil(countdownTime))
            local currentMoney = getPlayerMoney()
            if initialMoney == 0 and currentMoney > 0 then
                initialMoney = currentMoney
            end
            local earned = math.max(0, currentMoney - initialMoney)
            earnedMoneyStat:Set(earned)
            if earned > lastEarned then
                local elapsedTime = math.max(1, tick() - farmStartTime)
                local newRate     = math.floor((earned / elapsedTime) * 3600)
                if newRate > currentHourlyRate then
                    currentHourlyRate = newRate
                    hourlyRateStat:Set(currentHourlyRate)
                end
                lastEarned = earned
            end
        else
            nextTeleportStat:Set(0)
            lastEarned        = 0
            currentHourlyRate = 0
        end
    end
end)

-- ── TAB 4: MISC ─────────────────────────────────────────────
local miscTab = window:CreateTab({ name = "Misc" })

miscTab:CreateButton({
    name     = "Reset Character",
    callback = function()
        if player.Character then
            player.Character:BreakJoints()
        end
    end,
})

miscTab:CreateButton({
    name     = "Open Basic Box (instant)",
    callback = function()
        task.spawn(function()
            for i = 1, 50 do
                task.wait(0.05)
                ReplicatedStorage.Box.Remotes.Client.RollBox:FireServer("BasicBox")
            end
        end)
    end,
})

-- ── GASHAPON AUTO SPIN ──────────────────────────────────────
local spinEvent     = ReplicatedStorage:WaitForChild("Gashapon"):WaitForChild("Events"):WaitForChild("Spin")
local notifEvent    = ReplicatedStorage:WaitForChild("General"):WaitForChild("NotificatePlayer")
local showInterface = ReplicatedStorage:WaitForChild("Gashapon"):WaitForChild("Events"):WaitForChild("ShowInterface")

local gashaponConfig = {
    IsRunning = false,
    ItemType  = "Basic A",
    TotalSpin = 150,
    DelayAnim = 5,
    SpinCount = 0,
}

local killConn = nil

miscTab:CreateSection({ name = "Gashapon Auto Spin" })

miscTab:CreateDropdown({
    name            = "Item Type",
    options         = { "Basic A", "Basic B", "Basic C", "Basic D", "Basic E", "Basic F" },
    currentOption   = { "Basic A" },
    multipleOptions = false,
    callback        = function(option)
        gashaponConfig.ItemType = type(option) == "table" and option[1] or option
    end,
})

miscTab:CreateSlider({
    name      = "Total Spins",
    range     = { 1, 1000 },
    increment = 1,
    value     = 150,
    suffix    = "x",
    callback  = function(value)
        gashaponConfig.TotalSpin = value
    end,
})

miscTab:CreateSlider({
    name      = "Spin Delay",
    range     = { 1, 15 },
    increment = 0.5,
    value     = 5,
    suffix    = "s",
    callback  = function(value)
        gashaponConfig.DelayAnim = value
    end,
})

showInterface.OnClientEvent:Connect(function(itemType, priceStr, colors)
    if not gashaponConfig.IsRunning then return end
    local colorInfo = ""
    if colors and type(colors) == "table" and typeof(colors[1]) == "Color3" then
        local c = colors[1]
        colorInfo = string.format(" | Color: R=%.2f G=%.2f B=%.2f", c.R, c.G, c.B)
    end
    print(string.format("[Gashapon] #%d → %s | %s%s",
        gashaponConfig.SpinCount,
        tostring(itemType),
        tostring(priceStr),
        colorInfo
    ))
end)

miscTab:CreateToggle({
    name     = "Auto Spin Gashapon",
    callback = function(state)
        gashaponConfig.IsRunning = state

        if state then
            gashaponConfig.SpinCount = 0
            if killConn then killConn:Disconnect() end
            killConn = notifEvent.OnClientEvent:Connect(function(...)
                for _, msg in ipairs({ ... }) do
                    if type(msg) == "string" and msg:find("Not enough currency") then
                        gashaponConfig.IsRunning = false
                        warn("[Gashapon] Stopped: not enough currency.")
                        if killConn then killConn:Disconnect(); killConn = nil end
                    end
                end
            end)

            task.spawn(function()
                print("[Gashapon] Starting " .. gashaponConfig.TotalSpin .. "x on [" .. gashaponConfig.ItemType .. "]")
                for i = 1, gashaponConfig.TotalSpin do
                    if not gashaponConfig.IsRunning then break end
                    gashaponConfig.SpinCount = i
                    print("[Gashapon] Spin " .. i .. "/" .. gashaponConfig.TotalSpin)
                    spinEvent:FireServer(gashaponConfig.ItemType)
                    task.wait(0.5)
                    firesignal(showInterface.OnClientEvent,
                        gashaponConfig.ItemType,
                        "\xC2\xA53.000.000",
                        { Color3.new(0.86666697263718, 0.86666697263718, 0.86666697263718) }
                    )
                    task.wait(gashaponConfig.DelayAnim + math.random() * 0.5)
                end

                if gashaponConfig.IsRunning then
                    print("[Gashapon] Done. " .. gashaponConfig.TotalSpin .. "x completed.")
                else
                    print("[Gashapon] Stopped at spin " .. gashaponConfig.SpinCount .. "/" .. gashaponConfig.TotalSpin)
                end

                gashaponConfig.IsRunning = false
                if killConn then killConn:Disconnect(); killConn = nil end
            end)
        else
            if killConn then killConn:Disconnect(); killConn = nil end
            print("[Gashapon] Stopped manually at spin " .. gashaponConfig.SpinCount)
        end
    end,
})

-- ── DISCONNECT HANDLER ──────────────────────────────────────
game:GetService("GuiService").ErrorMessageChanged:Connect(function(errMsg)
    if errMsg and errMsg ~= "" then
        warn("[Projectsion] Disconnected: " .. errMsg)
    end
end)