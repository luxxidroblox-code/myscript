local Players    = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart")
local humanoid  = character:WaitForChild("Humanoid")

local BENDERA = {
    { name = "Bendera 1",  cf = CFrame.new(22010.752,   291.610, -40318.680,  0.660, -0.000,  0.751, 0.000, 1.000,  0.000, -0.751, -0.000,  0.660) },
    { name = "Bendera 2",  cf = CFrame.new(-10680.044, -147.972,  36229.938,  0.197,  0.000,  0.980, 0.000, 1.000, -0.000, -0.980,  0.000,  0.197) },
    { name = "Bendera 3",  cf = CFrame.new(24321.625,   216.564, -23175.205, -0.987,  0.000, -0.161, 0.000, 1.000,  0.000,  0.161,  0.000, -0.987) },
    { name = "Bendera 4",  cf = CFrame.new(25919.605,   220.652, -18256.594, -0.953, -0.000, -0.304,-0.000, 1.000,  0.000,  0.304,  0.000, -0.953) },
    { name = "Bendera 5",  cf = CFrame.new(22864.131,   300.992, -39667.996,  0.629,  0.000, -0.777, 0.000, 1.000,  0.000,  0.777, -0.000,  0.629) },
    { name = "Bendera 6",  cf = CFrame.new(-11895.996, -194.369,  29305.900,  0.676,  0.000, -0.737,-0.000, 1.000,  0.000,  0.737, -0.000,  0.676) },
    { name = "Bendera 7",  cf = CFrame.new(12264.988,   -29.009,  12884.489,  0.527,  0.000,  0.850, 0.000, 1.000, -0.000, -0.850,  0.000,  0.527) },
    { name = "Bendera 8",  cf = CFrame.new(15358.921,   -64.393,  16893.139,  0.770, -0.000,  0.638, 0.000, 1.000,  0.000, -0.638, -0.000,  0.770) },
    { name = "Bendera 9",  cf = CFrame.new(-2173.090,  -148.266,  29692.879, -0.875,  0.000,  0.484, 0.000, 1.000,  0.000, -0.484,  0.000, -0.875) },
    { name = "Bendera 10", cf = CFrame.new(-22241.518, -186.630,  31077.883, -0.776, -0.000,  0.631,-0.000, 1.000,  0.000, -0.631,  0.000, -0.776) },
}

-- ── raycast ground resolver ──────────────────────────────────
-- shoots a ray from 500 studs above target XZ downward
-- returns Y of first terrain/part hit + character hip offset
local RAY_IGNORE  = RaycastParams.new()
RAY_IGNORE.FilterType = Enum.RaycastFilterType.Exclude
RAY_IGNORE.FilterDescendantsInstances = { character }

local HIP_OFFSET  = 3.0  -- studs above ground hit to place rootPart

local function resolveGroundY(targetCF)
    local origin    = Vector3.new(targetCF.X, targetCF.Y + 500, targetCF.Z)
    local direction = Vector3.new(0, -1000, 0)
    local result    = workspace:Raycast(origin, direction, RAY_IGNORE)

    if result then
        return result.Position.Y + HIP_OFFSET
    end
    -- no hit — flag is likely over void or underground, use raw Y
    return targetCF.Y
end

-- ── teleport ─────────────────────────────────────────────────
local function safeTeleport(targetCF, onDone)
    setsimulationradius(math.huge, math.huge)

    rootPart.Velocity    = Vector3.zero
    rootPart.RotVelocity = Vector3.zero

    task.wait()

    local groundY   = resolveGroundY(targetCF)
    -- reconstruct CFrame at resolved Y, keep original rotation
    local landingCF = CFrame.new(
        Vector3.new(targetCF.X, groundY, targetCF.Z)
    ) * CFrame.fromMatrix(
        Vector3.zero,
        targetCF.XVector,
        targetCF.YVector,
        targetCF.ZVector
    )

    rootPart.CFrame      = landingCF
    rootPart.Velocity    = Vector3.zero
    rootPart.RotVelocity = Vector3.zero

    task.wait(0.1)
    setsimulationradius(1000, 1000)

    if onDone then onDone() end
end

-- ── GUI ─────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "BenderaTeleportGUI"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = player.PlayerGui

local frame = Instance.new("Frame")
frame.Name             = "MainFrame"
frame.Size             = UDim2.new(0, 220, 0, 380)
frame.Position         = UDim2.new(0, 16, 0.5, -190)
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
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(50, 30, 110) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(24, 18, 52) }):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        statusLabel.Text       = "Teleporting → " .. entry.name .. "..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)

        task.spawn(function()
            safeTeleport(entry.cf, function()
                statusLabel.Text       = "Arrived: " .. entry.name
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 160)
                task.delay(2, function()
                    statusLabel.Text       = "Select a flag"
                    statusLabel.TextColor3 = Color3.fromRGB(120, 100, 200)
                end)
            end)
        end)
    end)
end

player.CharacterAdded:Connect(function(char)
    character = char
    rootPart  = char:WaitForChild("HumanoidRootPart")
    humanoid  = char:WaitForChild("Humanoid")
    RAY_IGNORE.FilterDescendantsInstances = { character }
    statusLabel.Text       = "Select a flag"
    statusLabel.TextColor3 = Color3.fromRGB(120, 100, 200)
end)