local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
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

-- ── aerial constants (mirrored from bus script) ───────────────
-- AERIAL_HEIGHT: how far above the map the character floats
--   during transit. At this altitude the speed check never
--   samples a meaningful ground-level delta.
-- DESCENT_TIME: seconds for the CFrameValue tween to land.
--   Heartbeat-driven via Changed → position updated every frame,
--   velocity zeroed every frame. Same pattern as bus AerialTP.
local AERIAL_HEIGHT = 1200   -- studs above current position
local DESCENT_TIME  = 3.5    -- tune down for snappier landing

-- ── aerial teleport ───────────────────────────────────────────
local function aerialTP(targetCF, onDone)
    -- 1. zero gravity so the character floats at whatever Y we set
    workspace.Gravity = 0

    -- 2. kill all velocity and freeze state
    humanoid.WalkSpeed   = 0
    humanoid.JumpPower   = 0
    rootPart.Velocity    = Vector3.zero
    rootPart.RotVelocity = Vector3.zero

    -- one tick for gravity change to take effect
    RunService.Stepped:Wait()

    -- 3. instant vertical lift — still above current XZ, nothing lateral yet
    rootPart.CFrame = rootPart.CFrame + Vector3.new(0, AERIAL_HEIGHT, 0)
    RunService.Stepped:Wait()

    -- 4. instant lateral translate — now above the TARGET at sky height
    --    the server sees the character appear 1200 studs in the air;
    --    it does not register a ground-level speed delta
    local skyTargetCF = targetCF + Vector3.new(0, AERIAL_HEIGHT, 0)
    rootPart.CFrame = skyTargetCF
    RunService.Stepped:Wait()

    -- 5. heartbeat-driven descent via CFrameValue tween
    --    CFrameValue.Changed fires every Heartbeat → rootPart.CFrame
    --    is updated every frame, velocity zeroed every frame.
    --    No anchor needed; gravity is 0.
    local cfVal = Instance.new("CFrameValue")
    cfVal.Value = rootPart.CFrame

    local conn = cfVal.Changed:Connect(function()
        rootPart.CFrame      = cfVal.Value
        rootPart.Velocity    = Vector3.zero
        rootPart.RotVelocity = Vector3.zero
    end)

    local info  = TweenInfo.new(DESCENT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(cfVal, info, { Value = targetCF })
    tween:Play()
    tween.Completed:Wait()

    conn:Disconnect()
    cfVal:Destroy()

    -- 6. precision snap to exact target
    rootPart.CFrame      = targetCF
    rootPart.Velocity    = Vector3.zero
    rootPart.RotVelocity = Vector3.zero

    -- two physics frames of settle — server integrator sees clean stop
    RunService.Stepped:Wait()
    rootPart.CFrame   = targetCF
    rootPart.Velocity = Vector3.zero
    RunService.Stepped:Wait()
    rootPart.CFrame   = targetCF
    rootPart.Velocity = Vector3.zero

    -- 7. restore physics and humanoid
    workspace.Gravity = 196.2
    task.delay(0.3, function()
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end)

    if onDone then onDone() end
end

-- ── GUI ──────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "BenderaTeleportGUI"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = player.PlayerGui

local frame = Instance.new("Frame")
frame.Name             = "MainFrame"
frame.Size             = UDim2.new(0, 220, 0, 420)
frame.Position         = UDim2.new(0, 16, 0.5, -210)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
frame.BorderSizePixel  = 0
frame.Active           = true
frame.Draggable        = true
frame.Parent           = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Color     = Color3.fromRGB(80, 60, 180)
stroke.Thickness = 1.5

local header = Instance.new("Frame")
header.Size             = UDim2.new(1, 0, 0, 38)
header.BackgroundColor3 = Color3.fromRGB(22, 14, 48)
header.BorderSizePixel  = 0
header.Parent           = frame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size                   = UDim2.new(1, -10, 1, 0)
titleLabel.Position               = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                   = "⚑  BENDERA TELEPORT"
titleLabel.TextColor3             = Color3.fromRGB(160, 120, 255)
titleLabel.Font                   = Enum.Font.GothamBold
titleLabel.TextSize               = 13
titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
titleLabel.Parent                 = header

local statusLabel = Instance.new("TextLabel")
statusLabel.Size                   = UDim2.new(1, -20, 0, 16)
statusLabel.Position               = UDim2.new(0, 10, 0, 42)
statusLabel.BackgroundTransparency = 1
statusLabel.Text                   = "Select a flag"
statusLabel.TextColor3             = Color3.fromRGB(120, 100, 200)
statusLabel.Font                   = Enum.Font.Gotham
statusLabel.TextSize               = 11
statusLabel.TextXAlignment         = Enum.TextXAlignment.Left
statusLabel.Parent                 = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Size                   = UDim2.new(1, -16, 1, -66)
scroll.Position               = UDim2.new(0, 8, 0, 62)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness     = 3
scroll.ScrollBarImageColor3   = Color3.fromRGB(80, 60, 180)
scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
scroll.BorderSizePixel        = 0
scroll.Parent                 = frame

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding   = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local teleporting = false

for i, entry in ipairs(BENDERA) do
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(24, 18, 52)
    btn.BorderSizePixel  = 0
    btn.Text             = string.format("  ⚑  %s", entry.name)
    btn.TextColor3       = Color3.fromRGB(200, 180, 255)
    btn.Font             = Enum.Font.Gotham
    btn.TextSize         = 12
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.LayoutOrder      = i
    btn.AutoButtonColor  = false
    btn.Parent           = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(60, 40, 130)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(50, 30, 110)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(24, 18, 52)
        }):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        if teleporting then return end
        teleporting = true

        statusLabel.Text       = "Lifting → " .. entry.name .. "..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)

        task.spawn(function()
            aerialTP(entry.cf, function()
                teleporting            = false
                statusLabel.Text       = "Arrived: " .. entry.name
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 160)
                task.delay(2, function()
                    if not teleporting then
                        statusLabel.Text       = "Select a flag"
                        statusLabel.TextColor3 = Color3.fromRGB(120, 100, 200)
                    end
                end)
            end)
        end)
    end)
end

player.CharacterAdded:Connect(function(char)
    character   = char
    rootPart    = char:WaitForChild("HumanoidRootPart")
    humanoid    = char:WaitForChild("Humanoid")
    teleporting = false
    -- safety restore if teleport was mid-flight on respawn
    workspace.Gravity = 196.2
    statusLabel.Text       = "Select a flag"
    statusLabel.TextColor3 = Color3.fromRGB(120, 100, 200)
end)