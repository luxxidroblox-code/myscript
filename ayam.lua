-- Lua | VoidlineHub | Roblox Client Script

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()

local isRunning = true
local teleportTime = 7

local checkpoints = {
    CFrame.new(306.730, 150.496, 2481.263, 0.937, 0.005, -0.350, -0.002, 1.000, 0.009, 0.350, -0.008, 0.937),
    CFrame.new(326.823, 147.392, 2262.260, 0.966, -0.010, -0.257, -0.024, 0.992, -0.126, 0.256, 0.128, 0.958),
    CFrame.new(627.335, 102.014, 1744.822, 0.557, -0.225, -0.799, 0.055, 0.970, -0.235, 0.829, 0.087, 0.553),
    CFrame.new(563.848, 73.359, 1043.875, 0.624, 0.132, 0.771, -0.006, 0.986, -0.164, -0.782, 0.098, 0.616),
    CFrame.new(203.609, 61.644, 508.836, 0.058, 0.219, 0.974, -0.012, 0.976, -0.219, -0.998, 0.001, 0.060),
    CFrame.new(-53.878, 31.175, 115.163, 0.999, 0.019, 0.045, -0.009, 0.974, -0.227, -0.048, 0.226, 0.973),
    CFrame.new(-926.268, 25.998, 6.413, 0.043, 0.193, 0.980, 0.006, 0.981, -0.193, -0.999, 0.014, 0.041),
    CFrame.new(-1459.487, 2.760, 669.708, 0.991, 0.031, 0.129, -0.001, 0.974, -0.226, -0.133, 0.223, 0.966) * CFrame.new(0, 0, 5),
    CFrame.new(-1839.563, 12.334, 43.834, 0.735, 0.148, 0.662, -0.000, 0.976, -0.218, -0.678, 0.160, 0.717),
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

-- ============================================================
-- HELPERS
-- ============================================================
local function getVehicle()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        return hum.SeatPart.Parent
    end
    return nil
end

local function resetVelocity(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

local function tweenTo(model, targetCFrame, duration)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return end
    model.PrimaryPart = hum.SeatPart

    local cfValue = Instance.new("CFrameValue")
    cfValue.Value = model:GetPrimaryPartCFrame()

    cfValue.Changed:Connect(function()
        model:PivotTo(cfValue.Value)
        resetVelocity(model)
    end)

    workspace.Gravity = 0
    resetVelocity(model)

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(cfValue, tweenInfo, { Value = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
    cfValue:Destroy()

    workspace.Gravity = 196.2
    resetVelocity(model)
end

local function instantTo(model, targetCFrame)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return end
    model.PrimaryPart = hum.SeatPart
    workspace.Gravity = 0
    model:PivotTo(targetCFrame)
    resetVelocity(model)
    workspace.Gravity = 196.2
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local ShowRaceTrack = RS.Race.Remotes.ShowRaceTrack

while isRunning do
    char = lp.Character or lp.CharacterAdded:Wait()

    local vehicle = getVehicle()

    -- Step 1: instant ke start
    if vehicle then
        instantTo(vehicle, checkpoints[1])
    else
        char:PivotTo(checkpoints[1])
    end

    -- Step 2: listen ShowRaceTrack, tunggu 15 detik lalu langsung tween
    local raceStarted = false
    local conn
    conn = ShowRaceTrack.OnClientEvent:Connect(function(state)
        if state == true then
            raceStarted = true
            conn:Disconnect()
        end
    end)

    local elapsed = 0
    while not raceStarted and elapsed < 60 do
        task.wait(0.5)
        elapsed += 0.5
    end
    if conn then conn:Disconnect() end

    if not raceStarted then
        warn("ShowRaceTrack timeout, retry...")
        task.wait(3)
        continue
    end

    task.wait(15)

    -- Step 3: tween tiap checkpoint
    for i = 2, #checkpoints do
        if not isRunning then break end

        vehicle = getVehicle()
        if vehicle then
            tweenTo(vehicle, checkpoints[i], teleportTime)
        else
            char:PivotTo(checkpoints[i])
        end

        task.wait(1)
    end

    -- Step 4: finish, langsung loop balik
    task.wait(2)
end