-- Lua | VoidlineHub | Roblox Client Script

local RS = game:GetService("ReplicatedStorage")

local char = game.Players.LocalPlayer.Character
    or game.Players.LocalPlayer.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- Step 1: Teleport ke start race
hrp.CFrame = CFrame.new(306.730, 150.496, 2481.263, 0.937, 0.005, -0.350, -0.002, 1.000, 0.009, 0.350, -0.008, 0.937)

-- Step 2: Tunggu ShowRaceTrack OnClientEvent
local ShowRaceTrack = RS.Race.Remotes.ShowRaceTrack
local raceStarted = false

local conn
conn = ShowRaceTrack.OnClientEvent:Connect(function(state)
    if state == true then
        raceStarted = true
        conn:Disconnect()
    end
end)

-- timeout fallback 30 detik
local elapsed = 0
while not raceStarted and elapsed < 30 do
    task.wait(0.5)
    elapsed = elapsed + 0.5
end

if not raceStarted then
    warn("ShowRaceTrack timeout — race tidak dimulai")
    return
end

-- Step 3: Checkpoint/Finish teleport loop
local function isWhiteBillboard(obj)
    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("BillboardGui") then
            for _, label in ipairs(desc:GetDescendants()) do
                if label:IsA("TextLabel") then
                    local text = label.Text:upper()
                    local color = label.TextColor3
                    local isWhite = color.R > 0.85 and color.G > 0.85 and color.B > 0.85
                    local isTarget = text:find("CHECKPOINT") or text:find("FINISH")
                    if isWhite and isTarget then
                        return true, text
                    end
                end
            end
        end
    end
    return false, nil
end

local finished = false

while not finished do
    task.wait(1)

    local candidates = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local found, label = isWhiteBillboard(obj)
            if found then
                local part = obj:IsA("BasePart") and obj or obj.PrimaryPart
                if part then
                    table.insert(candidates, { part = part, label = label })
                end
            end
        end
    end

    if #candidates == 0 then break end

    local closest, closestDist = nil, math.huge
    for _, t in ipairs(candidates) do
        local dist = (t.part.Position - hrp.Position).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = t
        end
    end

    if closest then
        hrp.CFrame = closest.part.CFrame + Vector3.new(0, 3, 0)
        if closest.label:find("FINISH") then
            finished = true
        end
        task.wait(5)
    end
end