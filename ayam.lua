-- Lua | VoidlineHub | Roblox Client Script

local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()

local isRunning = true
local flySpeed = 300
local flyHeight = 8 -- terbang di ketinggian ini di atas checkpoint

-- ============================================================
-- DESTROY WHEELS
-- ============================================================
local function stripWheels(model)
    local wheels = model:FindFirstChild("Wheels") or model:FindFirstChild("wheels")
    if wheels then wheels:Destroy() end
    local body = model:FindFirstChild("Body")
    if body then
        local mainPart = body:FindFirstChild("MainPart")
        if mainPart and mainPart:IsA("BasePart") then
            mainPart.CanCollide = false
        end
    end
end

-- ============================================================
-- FLY TO — berhenti saat tepat di atas target (XZ match, Y = target + flyHeight)
-- ============================================================
local function flyModelTo(model, targetPos)
    local root = model.PrimaryPart
        or model:FindFirstChild("DriveSeat")
        or model:FindFirstChild("VehicleSeat")
        or model:FindFirstChildWhichIsA("BasePart")
    if not root then return end

    -- final destination: langsung di atas checkpoint
    local destination = Vector3.new(targetPos.X, targetPos.Y + flyHeight, targetPos.Z)

    local noclipConn = RunService.Stepped:Connect(function()
        for _, v in ipairs(model:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end)

    local BG = Instance.new("BodyGyro")
    BG.P = 9e4
    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.D = 50
    BG.Parent = root

    local BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BV.Velocity = Vector3.zero
    BV.Parent = root

    local timeout = os.clock()
    while isRunning do
        local cur = root.Position
        local dir = destination - cur

        -- stop: XZ dalam 3 studs DAN Y dalam 2 studs dari destination
        local xzDist = Vector3.new(dir.X, 0, dir.Z).Magnitude
        local yDiff  = math.abs(dir.Y)
        if xzDist < 3 and yDiff < 2 then break end

        if os.clock() - timeout > 60 then break end

        BV.Velocity = dir.Unit * flySpeed
        BG.CFrame = CFrame.lookAt(cur, destination)
        task.wait()
    end

    BV.Velocity = Vector3.zero
    task.wait(0.2)
    BG:Destroy()
    BV:Destroy()

    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            v.AssemblyLinearVelocity = Vector3.zero
            v.AssemblyAngularVelocity = Vector3.zero
            v.CanCollide = true
        end
    end

    noclipConn:Disconnect()
end

-- ============================================================
-- GET VEHICLE
-- ============================================================
local function getVehicle()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        return hum.SeatPart:FindFirstAncestorOfClass("Model")
    end
    return nil
end

-- ============================================================
-- STEP 1: Strip wheels → fly ke start
-- ============================================================
local startPos = Vector3.new(306.730, 150.496, 2481.263)

local vehicle = getVehicle()
if vehicle then
    stripWheels(vehicle)
    task.wait(0.3)
    flyModelTo(vehicle, startPos)
else
    char:PivotTo(CFrame.new(startPos))
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

    local v = getVehicle()
    if v then
        stripWheels(v)
        flyModelTo(v, target.part.Position)
    else
        char:PivotTo(CFrame.new(target.part.Position + Vector3.new(0, flyHeight, 0)))
    end

    if target.label:find("FINISH") then
        finished = true
    end

    task.wait(5)
end