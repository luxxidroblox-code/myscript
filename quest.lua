local Rayfield     = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart")
local humanoid  = character:WaitForChild("Humanoid")

local BENDERA = {
    { name = "Bendera 1",  cf = CFrame.new(22010.752,   291.610, -40318.680,  0.660, -0.000,  0.751,  0.000, 1.000,  0.000, -0.751, -0.000,  0.660) },
    { name = "Bendera 2",  cf = CFrame.new(-10680.044, -147.972,  36229.938,  0.197,  0.000,  0.980,  0.000, 1.000, -0.000, -0.980,  0.000,  0.197) },
    { name = "Bendera 3",  cf = CFrame.new(24321.625,   216.564, -23175.205, -0.987,  0.000, -0.161,  0.000, 1.000,  0.000,  0.161,  0.000, -0.987) },
    { name = "Bendera 4",  cf = CFrame.new(25919.605,   220.652, -18256.594, -0.953, -0.000, -0.304, -0.000, 1.000,  0.000,  0.304,  0.000, -0.953) },
    { name = "Bendera 5",  cf = CFrame.new(22864.131,   300.992, -39667.996,  0.629,  0.000, -0.777,  0.000, 1.000,  0.000,  0.777, -0.000,  0.629) },
    { name = "Bendera 6",  cf = CFrame.new(-11895.996, -194.369,  29305.900,  0.676,  0.000, -0.737, -0.000, 1.000,  0.000,  0.737, -0.000,  0.676) },
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

local NPC_QUEST_CF  = CFrame.new(25987.922, 220.577, -18501.188, -0.999, 0.000, 0.046, -0.000, 1.000, -0.000, -0.046, -0.000, -0.999)
local UNDERGROUND_Y = -4000
local FLAG_DELAY    = 20
local HOLD_DURATION = 3

_G.CycleRunning = false

local function freeze()
    humanoid.WalkSpeed   = 0
    humanoid.JumpPower   = 0
    rootPart.Velocity    = Vector3.zero
    rootPart.RotVelocity = Vector3.zero
end

local function restore()
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
end

local function stealthTP(targetCF)
    character = player.Character
    if not character then return end
    rootPart  = character:WaitForChild("HumanoidRootPart")
    humanoid  = character:WaitForChild("Humanoid")

    freeze()
    RunService.Stepped:Wait()

    local cur = character:GetPivot()
    character:PivotTo(CFrame.new(cur.X, UNDERGROUND_Y, cur.Z))
    freeze()
    RunService.Stepped:Wait()

    local tPos = targetCF.Position
    character:PivotTo(CFrame.new(tPos.X, UNDERGROUND_Y, tPos.Z))
    freeze()
    RunService.Stepped:Wait()

    character:PivotTo(targetCF)
    freeze()

    for _ = 1, 3 do
        RunService.Stepped:Wait()
        character:PivotTo(targetCF)
        rootPart.Velocity    = Vector3.zero
        rootPart.RotVelocity = Vector3.zero
    end

    task.delay(0.25, restore)
end

local function holdNearbyPrompts(radius)
    local origin = rootPart.Position
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                if (part.Position - origin).Magnitude <= radius then
                    pcall(function()
                        if holdproximityprompt then
                            holdproximityprompt(obj, HOLD_DURATION)
                        else
                            fireproximityprompt(obj)
                        end
                    end)
                end
            end
        end
    end
end

-- ── Rayfield ──────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name            = "Auto find flag by .projectsion",
    LoadingTitle    = "Auto Find Flag",
    LoadingSubtitle = "by .projectsion",
    Theme           = "Bloom",
    ConfigurationSaving = { Enabled = false },
    KeySystem       = false,
})

local MainTab = Window:CreateTab("Main", "flag")
local StatusLabel

MainTab:CreateSection("Auto Flag Farm")
StatusLabel = MainTab:CreateLabel("Status: Idle", "activity")

MainTab:CreateButton({
    Name     = "▶  Start Auto Find Flag (1 Cycle)",
    Callback = function()
        if _G.CycleRunning then
            Rayfield:Notify({
                Title    = "Already Running",
                Content  = "Cycle in progress — wait for it to finish.",
                Duration = 3,
                Image    = "alert-triangle",
            })
            return
        end

        task.spawn(function()
            _G.CycleRunning = true
            StatusLabel:Set("Status: Cycle started...")

            for i, entry in ipairs(BENDERA) do
                StatusLabel:Set("Status: Moving → " .. entry.name .. " (" .. i .. "/15)")
                stealthTP(entry.cf)

                task.wait(0.5)
                StatusLabel:Set("Status: Holding prompt — " .. entry.name)
                holdNearbyPrompts(12)

                -- interruptible delay between flags
                for t = FLAG_DELAY, 1, -1 do
                    StatusLabel:Set("Status: [" .. entry.name .. "] " .. i .. "/15 — next in " .. t .. "s")
                    task.wait(1)
                end
            end

            _G.CycleRunning = false
            StatusLabel:Set("Status: ✓ Cycle complete (15/15)")
            Rayfield:Notify({
                Title    = "Done",
                Content  = "All 15 flags visited.",
                Duration = 5,
                Image    = "check-circle",
            })
        end)
    end,
})

MainTab:CreateSection("NPC Quest")

MainTab:CreateButton({
    Name     = "Teleport to NPC Quest",
    Callback = function()
        if _G.CycleRunning then
            Rayfield:Notify({
                Title    = "Cycle Running",
                Content  = "Wait for the flag cycle to finish first.",
                Duration = 3,
                Image    = "alert-triangle",
            })
            return
        end
        StatusLabel:Set("Status: Moving → NPC Quest...")
        task.spawn(function()
            stealthTP(NPC_QUEST_CF)
            task.wait(0.5)
            StatusLabel:Set("Status: Holding NPC prompt...")
            holdNearbyPrompts(12)
            StatusLabel:Set("Status: NPC Quest done")
        end)
    end,
})

MainTab:CreateSection("Settings")

MainTab:CreateSlider({
    Name         = "Flag Delay (seconds)",
    Range        = {5, 60},
    Increment    = 1,
    CurrentValue = FLAG_DELAY,
    Callback     = function(Value)
        FLAG_DELAY = Value
    end,
})

MainTab:CreateSlider({
    Name         = "Prompt Hold Duration (seconds)",
    Range        = {1, 10},
    Increment    = 0.5,
    CurrentValue = HOLD_DURATION,
    Callback     = function(Value)
        HOLD_DURATION = Value
    end,
})

player.CharacterAdded:Connect(function(char)
    character       = char
    rootPart        = char:WaitForChild("HumanoidRootPart")
    humanoid        = char:WaitForChild("Humanoid")
    _G.CycleRunning = false
    if StatusLabel then StatusLabel:Set("Status: Respawned") end
end)