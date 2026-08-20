-- [[ 17Agustus Combined Farm ]]
-- Executor: Arceus X / Delta
-- Runtime: Roblox Luau

local Rayfield     = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RepStorage   = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart")
local humanoid  = character:WaitForChild("Humanoid")

-- ── CFrames: Minigame ─────────────────────────────────────────────
local CF_START = CFrame.new(-10583.440, -148.798, 36687.500,
    -0.901, 0.000, -0.434,
     0.000, 1.000,  0.000,
     0.434, 0.000, -0.901)

local CF_END = CFrame.new(-10375.147, -148.798, 36590.812,
     0.351,-0.000, -0.937,
     0.000, 1.000, -0.000,
     0.937, 0.000,  0.351)

local CF_RETURN = CFrame.new(-10583.391, -148.798, 36654.738,
    -0.270, 0.000,  0.963,
     0.000, 1.000, -0.000,
    -0.963,-0.000, -0.270)

-- ── CFrames: Bendera ──────────────────────────────────────────────
local BENDERA = {
    { name = "Bendera 1",  cf = CFrame.new(22012.752, 291.610, -40320.789, -0.109, 0.000, 0.994, -0.000, 1.000, -0.000, -0.994, -0.000, -0.109) },
    { name = "Bendera 2",  cf = CFrame.new(-10680.044, -147.972, 36229.938,  0.197,  0.000,  0.980,  0.000, 1.000, -0.000, -0.980,  0.000,  0.197) },
    { name = "Bendera 3",  cf = CFrame.new(24321.625,   216.564, -23175.205, -0.987,  0.000, -0.161,  0.000, 1.000,  0.000,  0.161,  0.000, -0.987) },
    { name = "Bendera 4",  cf = CFrame.new(25919.605,   220.652, -18256.594, -0.953, -0.000, -0.304, -0.000, 1.000,  0.000,  0.304,  0.000, -0.953) },
    { name = "Bendera 5",  cf = CFrame.new(22864.131,   300.992, -39667.996,  0.629,  0.000, -0.777,  0.000, 1.000,  0.000,  0.777, -0.000,  0.629) },
    { name = "Bendera 6",  cf = CFrame.new(-11895.996, -194.369, 29305.900,  0.676,  0.000, -0.737, -0.000, 1.000,  0.000,  0.737, -0.000,  0.676) },
    { name = "Bendera 7",  cf = CFrame.new(12264.988,   -29.009,  12884.489,  0.527,  0.000,  0.850,  0.000, 1.000, -0.000, -0.850,  0.000,  0.527) },
    { name = "Bendera 8",  cf = CFrame.new(15358.921,   -64.393,  16893.139,  0.770, -0.000,  0.638,  0.000, 1.000,  0.000, -0.638, -0.000,  0.770) },
    { name = "Bendera 9",  cf = CFrame.new(-2173.090,  -148.266,  29692.879, -0.875,  0.000,  0.484,  0.000, 1.000,  0.000, -0.484,  0.000, -0.875) },
    { name = "Bendera 10", cf = CFrame.new(-22241.518, -186.630,  31077.883, -0.776, -0.000,  0.631, -0.000, 1.000,  0.000, -0.631,  0.000, -0.776) },
    { name = "Bendera 11", cf = CFrame.new(21908.070,   291.163, -39988.266,  0.742, -0.000,  0.670,  0.000, 1.000,  0.000, -0.670, -0.000,  0.742) },
    { name = "Bendera 12", cf = CFrame.new(19992.523,   265.478, -27978.184,  0.997,  0.000, -0.077, -0.000, 1.000,  0.000,  0.077, -0.000,  0.997) },
    { name = "Bendera 13", cf = CFrame.new(23871.199,   222.195, -16860.410,  0.152,  0.000, -0.988,  0.000, 1.000,  0.000,  0.988, -0.000,  0.152) },
    { name = "Bendera 14", cf = CFrame.new(-21253.691, -219.169,  35107.188,  0.898,  0.000, -0.440, -0.000, 1.000, -0.000,  0.440,  0.000,  0.898) },
    { name = "Bendera 15", cf = CFrame.new(27850.434,   129.072,  -3485.787,  0.978, -0.000,  0.210,  0.000, 1.000,  0.000, -0.210, -0.000,  0.978) },
}

local NPC_QUEST_CF = CFrame.new(25987.922, 220.577, -18501.188,
    -0.999, 0.000, 0.046, -0.000, 1.000, -0.000, -0.046, -0.000, -0.999)

-- ── Config ────────────────────────────────────────────────────────
local cfg = {
    miniRunning = false,
    miniSpeed   = 30,
    miniReset   = 1.5,
    flagRunning = false,
    flagDelay   = 20,
    holdTime    = 3,
}

-- ── Raycast params ────────────────────────────────────────────────
local RAY_PARAMS = RaycastParams.new()
RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
RAY_PARAMS.FilterDescendantsInstances = { character }

-- ── Shared ref refresh ────────────────────────────────────────────
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

-- ── Snap teleport (GettingUp passive state) ───────────────────────
local function snapTP(targetCF)
    local groundY     = resolveGroundY(targetCF)
    local destination = CFrame.new(targetCF.X, groundY, targetCF.Z) * targetCF.Rotation
    if setsimulationradius then setsimulationradius(math.huge, math.huge) end
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    rootPart.CFrame                  = destination
    rootPart.AssemblyLinearVelocity  = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    RunService.Stepped:Wait()
    rootPart.CFrame                 = destination
    rootPart.AssemblyLinearVelocity = Vector3.zero
    RunService.Stepped:Wait()
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

-- ── Smooth tween move (minigame legs) ────────────────────────────
local function smoothMove(targetCF, speed)
    local hrp = rootPart
    if not hrp then return end
    local dist = (targetCF.Position - hrp.CFrame.Position).Magnitude
    local dur  = math.max(dist / (speed * 10), 0.5)
    local val  = Instance.new("CFrameValue")
    val.Value  = hrp.CFrame
    local tween = TweenService:Create(val,
        TweenInfo.new(dur, Enum.EasingStyle.Linear),
        { Value = targetCF })
    local conn = val:GetPropertyChangedSignal("Value"):Connect(function()
        if rootPart then rootPart.CFrame = val.Value end
    end)
    tween:Play()
    tween.Completed:Wait()
    conn:Disconnect()
    val:Destroy()
end

-- ── Reset: kill → respawn → refresh ──────────────────────────────
local function resetToSpawn()
    local oldChar = character
    humanoid.Health = 0
    repeat task.wait(0.1) until player.Character ~= oldChar and player.Character ~= nil
    task.wait(cfg.miniReset)
    refreshRefs()
end

-- ── Reset (flag variant uses same reset delay) ────────────────────
local function resetToSpawnFlag()
    local oldChar = character
    humanoid.Health = 0
    repeat task.wait(0.1) until player.Character ~= oldChar and player.Character ~= nil
    task.wait(1.5)
    refreshRefs()
end

-- ── Proximity prompt fire ─────────────────────────────────────────
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

-- ── Rayfield Window ───────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name            = "17Agustus Farm",
    LoadingTitle    = "Projectsion",
    LoadingSubtitle = "by .projectsion",
    Theme           = "Bloom",
    ConfigurationSaving = { Enabled = false },
    KeySystem       = false,
})

-- ════════════════════════════════════════════════════════════════
-- TAB 1 — MINIGAME
-- ════════════════════════════════════════════════════════════════
local MiniTab = Window:CreateTab("Minigame", "zap")

MiniTab:CreateSection("Auto Minigame")
local MiniStatus = MiniTab:CreateLabel("Status: Idle")

-- Persistent listener — bound on load, gate is cfg.miniRunning
local MiniEvent = RepStorage["17Agustus"].ShowInfoMessage
MiniEvent.OnClientEvent:Connect(function(msg)
    if not cfg.miniRunning then return end
    if not tostring(msg):upper():find("MULAI") then return end

    task.spawn(function()
        humanoid.WalkSpeed = cfg.miniSpeed
        MiniStatus:Set("Status: Running → End")

        smoothMove(CF_END, cfg.miniSpeed)
        if not cfg.miniRunning then return end

        MiniStatus:Set("Status: Running → Return")
        smoothMove(CF_RETURN, cfg.miniSpeed)
        if not cfg.miniRunning then return end

        MiniStatus:Set("Status: Resetting...")
        resetToSpawn()
        if not cfg.miniRunning then return end

        snapTP(CF_START)
        humanoid.WalkSpeed = cfg.miniSpeed
        MiniStatus:Set("Status: Waiting for MULAI...")
    end)
end)

MiniTab:CreateToggle({
    Name         = "Auto Minigame",
    CurrentValue = false,
    Flag         = "AutoMini",
    Callback     = function(state)
        cfg.miniRunning = state
        if state then
            snapTP(CF_START)
            humanoid.WalkSpeed = cfg.miniSpeed
            MiniStatus:Set("Status: Waiting for MULAI...")
        else
            MiniStatus:Set("Status: Stopped")
        end
    end,
})

MiniTab:CreateSlider({
    Name         = "Move Speed",
    Range        = { 16, 100 },
    Increment    = 1,
    Suffix       = "stud/s",
    CurrentValue = cfg.miniSpeed,
    Flag         = "MiniSpeed",
    Callback     = function(val)
        cfg.miniSpeed = val
        if cfg.miniRunning then humanoid.WalkSpeed = val end
    end,
})

MiniTab:CreateSlider({
    Name         = "Reset Delay (s)",
    Range        = { 0.5, 5.0 },
    Increment    = 0.5,
    Suffix       = "s",
    CurrentValue = cfg.miniReset,
    Flag         = "MiniReset",
    Callback     = function(val) cfg.miniReset = val end,
})

-- ════════════════════════════════════════════════════════════════
-- TAB 2 — AUTO FLAG
-- ════════════════════════════════════════════════════════════════
local FlagTab = Window:CreateTab("Auto Flag", "flag")

FlagTab:CreateSection("Auto Flag Farm")
local FlagStatus   = FlagTab:CreateLabel("Status: Idle")
local flagToggleRef

flagToggleRef = FlagTab:CreateToggle({
    Name         = "Auto Find Flag (1–15)",
    CurrentValue = false,
    Callback     = function(state)
        cfg.flagRunning = state
        if not state then
            FlagStatus:Set("Status: Stopped")
            return
        end

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
                    task.wait(0.3)
                    snapTP(entry.cf)
                    task.wait(0.3)
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
                    resetToSpawnFlag()
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

-- ── Shared CharacterAdded rebind ──────────────────────────────────
player.CharacterAdded:Connect(function(char)
    character = char
    rootPart  = char:WaitForChild("HumanoidRootPart")
    humanoid  = char:WaitForChild("Humanoid")
    RAY_PARAMS.FilterDescendantsInstances = { character }
    MiniStatus:Set("Status: Respawned — " .. (cfg.miniRunning and "resuming..." or "Idle"))
    FlagStatus:Set("Status: Respawned — " .. (cfg.flagRunning and "resuming..." or "Idle"))
end)