-- Lua | VoidlineHub | Roblox Client Script

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()

local isRunning = true
local teleportTime = 3 -- detik turun ke checkpoint

-- ============================================================
-- GET VEHICLE
-- ============================================================
local function getVehicle()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        return hum.SeatPart.Parent
    end
    return nil
end

-- ============================================================
-- v191 TWEEN METHOD (ported dari DEJ script)
-- ============================================================
local function resetVelocity(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

local function tweenModelTo(model, targetCFrame, duration)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return end

    model.PrimaryPart = hum.SeatPart
    local primaryPart = model.PrimaryPart
    if not primaryPart then return end

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local cfValue = Instance.new("CFrameValue")
    cfValue.Value = model:GetPrimaryPartCFrame()

    cfValue.Changed:Connect(function()
        model:PivotTo(cfValue.Value)
        resetVelocity(model)
    end)

    local tween = TweenService:Create(cfValue, tweenInfo, { Value = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
    cfValue:Destroy()
    resetVelocity(model)
end

local function flyTo(model, targetCFrame)
    local primaryPart = model.PrimaryPart
    if not primaryPart then return end

    workspace.Gravity = 0
    resetVelocity(model)

    -- naik dulu tinggi
    tweenModelTo(model, primaryPart.CFrame + Vector3.new(0, 1000, 0), 0)
    -- geser ke atas target
    tweenModelTo(model, targetCFrame + Vector3.new(0, 1000, 0), 0)
    -- turun ke target
    tweenModelTo(model, targetCFrame, teleportTime)

    workspace.Gravity = 196.2
    resetVelocity(model)
    task.wait(1.2)
end

-- ============================================================
-- STEP 1: Fly ke start race
-- ============================================================
local startCFrame = CFrame.new(306.730, 150.496, 2481.263, 0.937, 0.005, -0.350, -0.002, 1.000, 0.009, 0.350, -0.008, 0.937)

local vehicle = getVehicle()
if vehicle then
    vehicle.PrimaryPart = char:FindFirstChildOfClass("Humanoid").SeatPart
    flyTo(vehicle, startCFrame)
else
    char:PivotTo(startCFrame)
end

-- ============================================================
-- STEP 2: Tunggu ShowRaceTrack OnClientEvent
-- ============================================================
local ShowRaceTrack = RS.Race.Remotes.ShowRaceTrack
local raceStarted = false

local conn
conn = ShowRaceTrack.OnClientEvent:Connect(function(state)
    if state == true then
        raceStarted = true
        conn:Disconnect()
    end
end)

local elapsed = 0
while not raceStarted and elapsed < 30 do
    task.wait(0.5)
    elapsed += 0.5
end

if not raceStarted then
    warn("ShowRaceTrack timeout")
    return
end

-- ============================================================
-- STEP 3: Checkpoint/Finish loop
-- ============================================================
local function findWhiteBillboards()
    local results = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") then
            for _, label in ipairs(obj:GetDescendants()) do
                if label:IsA("TextLabel") then
                    local text = label.Text:upper()
                    local c = label.TextColor3
                    local isWhite = c.R > 0.85 and c.G > 0.85 and c.B > 0.85
                    local isTarget = text:find("CHECKPOINT") or text:find("FINISH")
                    if isWhite and isTarget then
                        local part = obj.Adornee
                            or (obj.Parent:IsA("BasePart") and obj.Parent)
                            or (obj.Parent:IsA("Model") and obj.Parent.PrimaryPart)
                        if part then
                            table.insert(results, { part = part, label = text })
                        end
                    end
                end
            end
        end
    end
    return results
end

local function getClosest(list)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local closest, minDist = nil, math.huge
    for _, t in ipairs(list) do
        local d = (t.part.Position - hrp.Position).Magnitude
        if d < minDist then
            minDist = d
            closest = t
        end
    end
    return closest
end

local finished = false
while not finished do
    task.wait(1)

    local targets = findWhiteBillboards()
    if #targets == 0 then break end

    local target = getClosest(targets)
    if not target then break end

    local destCFrame = CFrame.new(target.part.Position + Vector3.new(0, 4, 0))

    local v = getVehicle()
    if v then
        v.PrimaryPart = char:FindFirstChildOfClass("Humanoid").SeatPart
        flyTo(v, destCFrame)
    else
        char:PivotTo(destCFrame)
    end

    if target.label:find("FINISH") then
        finished = true
    end

    task.wait(5)
end