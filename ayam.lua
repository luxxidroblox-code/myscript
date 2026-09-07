-- Lua | VoidlineHub | Roblox Client Script
-- Deps: firesignal (Synapse/KRNL), task, TweenService optional

local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local JoinRaceEvent = RS.Race.Remotes.JoinRace

-- Step 1: Fire join race
task.wait(10)
firesignal(JoinRaceEvent.OnClientEvent, workspace.Race.Race)

-- Step 2: Checkpoint/Finish teleport loop
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

local function findNextTarget()
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

    return candidates
end

local char = game.Players.LocalPlayer.Character
    or game.Players.LocalPlayer.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local finished = false

while not finished do
    task.wait(1)

    local targets = findNextTarget()

    if #targets == 0 then
        -- no billboard found, race likely ended
        break
    end

    -- pick closest white billboard
    local closest, closestDist = nil, math.huge
    for _, t in ipairs(targets) do
        local dist = (t.part.Position - hrp.Position).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = t
        end
    end

    if closest then
        -- teleport pivot
        hrp.CFrame = closest.part.CFrame + Vector3.new(0, 3, 0)

        if closest.label:find("FINISH") then
            finished = true
        end

        task.wait(5)
    end
end