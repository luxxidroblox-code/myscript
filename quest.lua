-- [[ 17Agustus Combined Farm — Full Build ]]
-- Executor: Arceus X / Delta
-- Runtime:  Roblox Luau

local Rayfield   = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local RepStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart")
local humanoid  = character:WaitForChild("Humanoid")

-- ── Config ────────────────────────────────────────────────────────
local cfg = {
    miniRunning = false,
    miniSpeed   = 30,
    miniReset   = 1.5,
    flagRunning = false,
    flagDelay   = 20,
    holdTime    = 3,
}

-- ── Ladder tuning ─────────────────────────────────────────────────
local LADDER_RADIUS   = 8
local LADDER_APPROACH = 6
local LADDER_STEER_Y  = 1

-- ── Raycast params ────────────────────────────────────────────────
local RAY_PARAMS = RaycastParams.new()
RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
RAY_PARAMS.FilterDescendantsInstances = { character }

-- ── Minigame CFrame ───────────────────────────────────────────────
local CF_START = CFrame.new(-10583.440, -148.798, 36687.500,
    -0.901, 0.000, -0.434,
     0.000, 1.000,  0.000,
     0.434, 0.000, -0.901)

-- ── Bendera CFrames ───────────────────────────────────────────────
local BENDERA = {
    { name = "Bendera 1",  cf = CFrame.new(22012.752,   291.610, -40320.789, -0.109, 0.000,  0.994, -0.000, 1.000, -0.000, -0.994, -0.000, -0.109) },
    { name = "Bendera 2",  cf = CFrame.new(-10680.044, -147.972,  36229.938,  0.197, 0.000,  0.980,  0.000, 1.000, -0.000, -0.980,  0.000,  0.197) },
    { name = "Bendera 3",  cf = CFrame.new(24321.625,   216.564, -23175.205, -0.987, 0.000, -0.161,  0.000, 1.000,  0.000,  0.161,  0.000, -0.987) },
    { name = "Bendera 4",  cf = CFrame.new(25919.605,   220.652, -18256.594, -0.953,-0.000, -0.304, -0.000, 1.000,  0.000,  0.304,  0.000, -0.953) },
    { name = "Bendera 5",  cf = CFrame.new(22864.131,   300.992, -39667.996,  0.629, 0.000, -0.777,  0.000, 1.000,  0.000,  0.777, -0.000,  0.629) },
    { name = "Bendera 6",  cf = CFrame.new(-11895.996, -194.369,  29305.900,  0.676, 0.000, -0.737, -0.000, 1.000,  0.000,  0.737, -0.000,  0.676) },
    { name = "Bendera 7",  cf = CFrame.new(12264.988,   -29.009,  12884.489,  0.527, 0.000,  0.850,  0.000, 1.000, -0.000, -0.850,  0.000,  0.527) },
    { name = "Bendera 8",  cf = CFrame.new(15358.921,   -64.393,  16893.139,  0.770,-0.000,  0.638,  0.000, 1.000,  0.000, -0.638, -0.000,  0.770) },
    { name = "Bendera 9",  cf = CFrame.new(-2173.090,  -148.266,  29692.879, -0.875, 0.000,  0.484,  0.000, 1.000,  0.000, -0.484,  0.000, -0.875) },
    { name = "Bendera 10", cf = CFrame.new(-22241.518, -186.630,  31077.883, -0.776,-0.000,  0.631, -0.000, 1.000,  0.000, -0.631,  0.000, -0.776) },
    { name = "Bendera 11", cf = CFrame.new(21908.070,   291.163, -39988.266,  0.742,-0.000,  0.670,  0.000, 1.000,  0.000, -0.670, -0.000,  0.742) },
    { name = "Bendera 12", cf = CFrame.new(19992.523,   265.478, -27978.184,  0.997, 0.000, -0.077, -0.000, 1.000,  0.000,  0.077, -0.000,  0.997) },
    { name = "Bendera 13", cf = CFrame.new(23871.199,   222.195, -16860.410,  0.152, 0.000, -0.988,  0.000, 1.000,  0.000,  0.988, -0.000,  0.152) },
    { name = "Bendera 14", cf = CFrame.new(-21253.691, -219.169,  35107.188,  0.898, 0.000, -0.440, -0.000, 1.000, -0.000,  0.440,  0.000,  0.898) },
    { name = "Bendera 15", cf = CFrame.new(27850.434,   129.072,  -3485.787,  0.978,-0.000,  0.210,  0.000, 1.000,  0.000, -0.210, -0.000,  0.978) },
}

local NPC_QUEST_CF = CFrame.new(25987.922, 220.577, -18501.188,
    -0.999, 0.000, 0.046, -0.000, 1.000, -0.000, -0.046, -0.000, -0.999)

-- ── Refs ──────────────────────────────────────────────────────────
local function refreshRefs()
    character = player.Character or player.CharacterAdded:Wait()
    rootPart  = character:WaitForChild("HumanoidRootPart")
    humanoid  = character:WaitForChild("Humanoid")
    while humanoid.Health <= 0 do task.wait(0.1) end
    RAY_PARAMS.FilterDescendantsInstances = { character }
end

-- ── Ground resolve ────────────────────────────────────────────────
local function resolveGroundY(targetCF)
    RAY_PARAMS.FilterDescendantsInstances = { character }
    local offsets = {
        Vector3.new(0,0,0), Vector3.new(2,0,0), Vector3.new(-2,0,0),
        Vector3.new(0,0,2), Vector3.new(0,0,-2),
    }
    local hits = {}
    for _, off in ipairs(offsets) do
        local origin = Vector3.new(targetCF.X + off.X, targetCF.Y + 600, targetCF.Z + off.Z)
        local result = workspace:Raycast(origin, Vector3.new(0, -1200, 0), RAY_PARAMS)
        if result then table.insert(hits, result.Position.Y) end
    end
    if #hits == 0 then return targetCF.Y end
    local minY = hits[1]
    for _, y in ipairs(hits) do if y < minY then minY = y end end
    return minY + 3.2
end

-- ── Snap teleport ─────────────────────────────────────────────────
local function snapTP(targetCF)
    local groundY     = resolveGroundY(targetCF)
    local destination = CFrame.new(targetCF.X, groundY, targetCF.Z) * targetCF.Rotation
    if setsimulationradius then setsimulationradius(math.huge, math.huge) end
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    rootPart.CFrame                  = destination
    rootPart.AssemblyLinearVelocity  = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    RunService.Stepped:Wait()
    rootPart.CFrame                  = destination
    rootPart.AssemblyLinearVelocity  = Vector3.zero
    RunService.Stepped:Wait()
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

-- ── Reset ─────────────────────────────────────────────────────────
local function resetToSpawn(delay)
    local oldChar = character
    humanoid.Health = 0
    repeat task.wait(0.1) until player.Character ~= oldChar and player.Character ~= nil
    task.wait(delay or 1.5)
    refreshRefs()
end

-- ── Prompt fire ───────────────────────────────────────────────────
local function firePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        if fireproximityprompt then fireproximityprompt(prompt) end
        prompt:InputHoldBegin()
        task.wait(cfg.holdTime)
        prompt:InputHoldEnd()
    end)
end

local function scanAndFirePrompts(radius)
    local origin = rootPart.Position
    local fired  = false
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local part = obj.Parent
            local pos  = part:IsA("BasePart") and part.Position
                      or (part:IsA("Model") and part:GetPivot().Position)
            if pos and (pos - origin).Magnitude <= (radius or 20) then
                firePrompt(obj)
                fired = true
            end
        end
    end
    return fired
end

-- ════════════════════════════════════════════════════════════════
-- LADDER DETECTION — sphere scan
-- ════════════════════════════════════════════════════════════════
local function findNearbyLadder()
    if not rootPart then return nil, math.huge end
    local origin = rootPart.Position
    local nearest, nearestDist = nil, LADDER_RADIUS

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("TrussPart")
            or (obj:IsA("BasePart") and (
                obj.Name:lower():find("ladder")
                or obj.Name:lower():find("tangga")
                or obj.Name:lower():find("truss")
            ))
        then
            local dist = (obj.Position - origin).Magnitude
            if dist < nearestDist then
                nearest     = obj
                nearestDist = dist
            end
        end
    end
    return nearest, nearestDist
end

local function steerToward(part)
    local delta = part.Position - rootPart.Position
    local xz    = Vector3.new(delta.X, 0, delta.Z)
    if xz.Magnitude < 0.01 then return nil end
    return xz.Unit
end

-- ════════════════════════════════════════════════════════════════
-- HRP HEARTBEAT WALKER
-- ════════════════════════════════════════════════════════════════
local miniPhase = "idle"
local walkConn  = nil
local lockedDir = nil
local MiniStatus

local function stopWalk()
    if walkConn then
        walkConn:Disconnect()
        walkConn = nil
    end
    if humanoid then
        pcall(function() humanoid:Move(Vector3.zero, false) end)
    end
end

local function faceDirection(dir)
    if not rootPart or dir.Magnitude < 0.01 then return end
    local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
    local newCF   = CFrame.lookAt(rootPart.Position, rootPart.Position + flatDir)
    rootPart.CFrame                  = newCF
    rootPart.AssemblyLinearVelocity  = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
end

local function startWalk(dir)
    stopWalk()
    lockedDir = dir

    walkConn = RunService.Heartbeat:Connect(function(dt)
        if not rootPart or not humanoid then stopWalk(); return end

        local state                  = humanoid:GetState()
        local ladderPart, ladderDist = findNearbyLadder()
        local onLadder               = state == Enum.HumanoidStateType.Climbing

        if onLadder then
            humanoid:Move(Vector3.new(lockedDir.X, LADDER_STEER_Y, lockedDir.Z), false)
            return
        end

        if ladderPart and ladderDist <= LADDER_APPROACH then
            local steerDir = steerToward(ladderPart)
            if steerDir then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                local step = steerDir * cfg.miniSpeed * dt
                local cur  = rootPart.CFrame
                rootPart.CFrame = CFrame.new(
                    cur.X + step.X,
                    cur.Y,
                    cur.Z + step.Z
                ) * CFrame.fromMatrix(Vector3.zero, cur.XVector, cur.YVector, cur.ZVector)
                rootPart.AssemblyLinearVelocity = Vector3.zero
                humanoid:Move(steerDir, false)
                return
            end
        end

        if state == Enum.HumanoidStateType.Freefall
        or state == Enum.HumanoidStateType.Jumping then
            humanoid:Move(lockedDir, false)
            return
        end

        local cur  = rootPart.CFrame
        local step = lockedDir * cfg.miniSpeed * dt
        rootPart.CFrame = CFrame.new(
            cur.X + step.X,
            cur.Y,
            cur.Z + step.Z
        ) * CFrame.fromMatrix(Vector3.zero, cur.XVector, cur.YVector, cur.ZVector)
        rootPart.AssemblyLinearVelocity = Vector3.zero
    end)
end

local function performFinishReset()
    stopWalk()
    miniPhase = "waiting_reset"
    if MiniStatus then MiniStatus:Set("Status: Resetting to minigame CFrame...") end
    task.spawn(function()
        if not cfg.miniRunning then return end
        resetToSpawn(cfg.miniReset)
        if not cfg.miniRunning then return end
        snapTP(CF_START)
        miniPhase = "idle"
        if MiniStatus then MiniStatus:Set("Status: Waiting for MULAI...") end
    end)
end

-- ── Persistent listener ───────────────────────────────────────────
local MiniEvent = RepStorage["17Agustus"].ShowInfoMessage
MiniEvent.OnClientEvent:Connect(function(msg)
    if not cfg.miniRunning then return end
    local text = tostring(msg):upper()

    -- Player personally finished — stop walking, wait for posisi ke-8
    if text:find(player.Name:upper()) and (text:find("FINIS") or text:find("FINISH")) then
        stopWalk()
        miniPhase = "finished_self"
        if MiniStatus then MiniStatus:Set("Status: Finished — waiting for Posisi 8...") end
        return
    end

    -- Posisi ke-8 announced — only reset if we already finished or are still running
    if text:find("POSISI KE-8") or text:find("POSISI 8") then
        if miniPhase == "finished_self"
        or miniPhase == "forward"
        or miniPhase == "returning" then
            performFinishReset()
        end
        return
    end

    if text:find("MULAI") and (miniPhase == "idle" or miniPhase == "waiting_reset") then
        miniPhase = "forward"
        if MiniStatus then MiniStatus:Set("Status: MULAI — walking forward") end
        local fwd = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z).Unit
        faceDirection(fwd)
        startWalk(fwd)

    elseif (text:find("PUTER") or text:find("BALIK") or text:find("KEMBALI")) and miniPhase == "forward" then
        miniPhase = "returning"
        if MiniStatus then MiniStatus:Set("Status: Balik — walking back") end
        local returnDir = -lockedDir
        faceDirection(returnDir)
        task.wait(0.05)
        startWalk(returnDir)

    elseif (text:find("SELESAI") or text:find("FINISH")) and miniPhase ~= "idle" and miniPhase ~= "waiting_reset" and miniPhase ~= "finished_self" then
        performFinishReset()
    end
end)

-- ════════════════════════════════════════════════════════════════
-- RAYFIELD UI
-- ════════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name            = "Bxi Event",
    LoadingTitle    = "Projectsion",
    LoadingSubtitle = "by .projectsion",
    Theme           = "Bloom",
    ConfigurationSaving = { Enabled = false },
    KeySystem       = false,
})

-- ── Tab 1: Minigame ───────────────────────────────────────────────
local MiniTab = Window:CreateTab("Minigame", "zap")
MiniTab:CreateSection("Auto Minigame")
MiniStatus = MiniTab:CreateLabel("Status: Idle")

MiniTab:CreateToggle({
    Name         = "Auto Minigame",
    CurrentValue = false,
    Callback     = function(state)
        cfg.miniRunning = state
        if not state then
            stopWalk()
            miniPhase = "idle"
            MiniStatus:Set("Status: Stopped")
        else
            miniPhase = "idle"
            snapTP(CF_START)
            MiniStatus:Set("Status: Waiting for MULAI...")
        end
    end,
})

MiniTab:CreateSlider({
    Name         = "Reset Delay (s)",
    Range        = { 0.5, 5.0 },
    Increment    = 0.5,
    Suffix       = "s",
    CurrentValue = cfg.miniReset,
    Callback     = function(val) cfg.miniReset = val end,
})

-- ── Tab 2: Auto Flag ──────────────────────────────────────────────
local FlagTab  = Window:CreateTab("Auto Flag", "flag")
FlagTab:CreateSection("Auto Flag Farm")
local FlagStatus   = FlagTab:CreateLabel("Status: Idle")
local flagToggleRef

flagToggleRef = FlagTab:CreateToggle({
    Name         = "Auto Find Flag (1–15)",
    CurrentValue = false,
    Callback     = function(state)
        cfg.flagRunning = state
        if not state then FlagStatus:Set("Status: Stopped"); return end

        task.spawn(function()
            for i, entry in ipairs(BENDERA) do
                if not cfg.flagRunning then break end

                FlagStatus:Set("Status: Snap → " .. entry.name)
                snapTP(entry.cf)
                task.wait(0.4)

                if not cfg.flagRunning then break end

                FlagStatus:Set("Status: Firing @ " .. entry.name)
                local fired = scanAndFirePrompts(20)
                if not fired then
                    task.wait(0.3); snapTP(entry.cf); task.wait(0.3)
                    scanAndFirePrompts(20)
                end

                task.wait(0.2)
                if not cfg.flagRunning then break end

                for t = cfg.flagDelay, 1, -1 do
                    if not cfg.flagRunning then break end
                    FlagStatus:Set(string.format("Status: [%s] next in %ds", entry.name, t))
                    task.wait(1)
                end

                if not cfg.flagRunning then break end

                if i < #BENDERA then
                    FlagStatus:Set("Status: Resetting after " .. entry.name .. "...")
                    resetToSpawn(1.5)
                    FlagStatus:Set("Status: Ready for " .. BENDERA[i + 1].name)
                    task.wait(0.3)
                end
            end

            cfg.flagRunning = false
            FlagStatus:Set("Status: Cycle complete ✓")
            if flagToggleRef then flagToggleRef:Set(false) end
        end)
    end,
})

FlagTab:CreateSection("NPC Quest")
FlagTab:CreateButton({
    Name     = "Teleport to NPC Quest",
    Callback = function()
        FlagStatus:Set("Status: Snap → NPC Quest...")
        task.spawn(function()
            snapTP(NPC_QUEST_CF)
            task.wait(0.3)
            scanAndFirePrompts(20)
            FlagStatus:Set("Status: NPC Quest done")
        end)
    end,
})

FlagTab:CreateSection("Settings")
FlagTab:CreateSlider({
    Name         = "Flag Delay (seconds)",
    Range        = { 5, 60 },
    Increment    = 1,
    CurrentValue = cfg.flagDelay,
    Callback     = function(val) cfg.flagDelay = val end,
})
FlagTab:CreateSlider({
    Name         = "Hold Duration (seconds)",
    Range        = { 1, 6 },
    Increment    = 0.5,
    CurrentValue = cfg.holdTime,
    Callback     = function(val) cfg.holdTime = val end,
})

-- ── CharacterAdded rebind ─────────────────────────────────────────
player.CharacterAdded:Connect(function(char)
    character = char
    rootPart  = char:WaitForChild("HumanoidRootPart")
    humanoid  = char:WaitForChild("Humanoid")
    RAY_PARAMS.FilterDescendantsInstances = { character }
    stopWalk()
    miniPhase = "idle"
    MiniStatus:Set("Status: Respawned — " .. (cfg.miniRunning and "Waiting for MULAI..." or "Idle"))
    FlagStatus:Set("Status: Respawned — " .. (cfg.flagRunning and "resuming..." or "Idle"))
end)