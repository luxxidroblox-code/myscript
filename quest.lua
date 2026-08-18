-- Lua 5.1 / Roblox executor  |  bendera_tp.lua  |  Arceus X / Delta

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

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

local NPC_QUEST = {
    name = "NPC Quest",
    cf   = CFrame.new(25987.922, 220.577, -18501.188, -0.999, 0.000, 0.046, -0.000, 1.000, -0.000, -0.046, -0.000, -0.999)
}

-- ============================================================
-- AERIAL_HEIGHT : studs above current position before translate.
--   Moves happen at sky height — server never sees a ground jump.
-- DESCENT_TIME  : seconds for the heartbeat-driven tween down.
--   CFrameValue.Changed fires every frame → velocity cleared every frame.
-- ============================================================
local AERIAL_HEIGHT = 800
local DESCENT_TIME  = 7   -- tune: shorter = snappier, longer = safer

-- ============================================================
-- AerialTP  (character variant — rootPart instead of bus:PivotTo)
--   1. Zero gravity, clear velocity
--   2. Instant lift to current + AERIAL_HEIGHT
--   3. Instant lateral translate to target + AERIAL_HEIGHT
--   4. Heartbeat-driven CFrameValue tween descent to target
--   5. Restore gravity, call onDone
-- ============================================================
local function AerialTP(targetCF, onDone)
    local prevGravity           = workspace.Gravity
    workspace.Gravity           = 0

    rootPart.AssemblyLinearVelocity  = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero

    -- lift
    rootPart.CFrame = rootPart.CFrame + Vector3.new(0, AERIAL_HEIGHT, 0)
    task.wait()

    -- lateral snap above target
    rootPart.CFrame = targetCF + Vector3.new(0, AERIAL_HEIGHT, 0)
    task.wait()

    -- heartbeat descent via CFrameValue tween
    local cfVal  = Instance.new("CFrameValue")
    cfVal.Value  = rootPart.CFrame

    local tweenInfo = TweenInfo.new(DESCENT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local conn = cfVal.Changed:Connect(function(newCF)
        rootPart.CFrame                  = newCF
        rootPart.AssemblyLinearVelocity  = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end)

    local tween = TweenService:Create(cfVal, tweenInfo, { Value = targetCF })
    tween:Play()
    tween.Completed:Wait()

    conn:Disconnect()
    cfVal:Destroy()

    -- hard-snap landing
    rootPart.CFrame = targetCF
    workspace.Gravity = prevGravity

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
frame.Size             = UDim2.new(0, 220, 0, 480)
frame.Position         = UDim2.new(0, 16, 0.5, -240)
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
statusLabel.Text                   = "Select a destination"
statusLabel.TextColor3             = Color3.fromRGB(120, 100, 200)
statusLabel.Font                   = Enum.Font.Gotham
statusLabel.TextSize               = 11
statusLabel.TextXAlignment         = Enum.TextXAlignment.Left
statusLabel.Parent                 = frame

local npcBtn = Instance.new("TextButton")
npcBtn.Size             = UDim2.new(1, -16, 0, 30)
npcBtn.Position         = UDim2.new(0, 8, 0, 62)
npcBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 80)
npcBtn.BorderSizePixel  = 0
npcBtn.Text             = "  🧭  NPC Quest"
npcBtn.TextColor3       = Color3.fromRGB(255, 210, 100)
npcBtn.Font             = Enum.Font.GothamBold
npcBtn.TextSize         = 12
npcBtn.TextXAlignment   = Enum.TextXAlignment.Left
npcBtn.AutoButtonColor  = false
npcBtn.Parent           = frame
Instance.new("UICorner", npcBtn).CornerRadius = UDim.new(0, 6)
local npcStroke = Instance.new("UIStroke", npcBtn)
npcStroke.Color     = Color3.fromRGB(180, 120, 50)
npcStroke.Thickness = 1.2

local scroll = Instance.new("ScrollingFrame")
scroll.Size                   = UDim2.new(1, -16, 1, -104)
scroll.Position               = UDim2.new(0, 8, 0, 100)
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

local function fireTP(entry)
    if teleporting then return end
    teleporting            = true
    statusLabel.Text       = "Aerial → " .. entry.name .. "..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
    task.spawn(function()
        AerialTP(entry.cf, function()
            teleporting            = false
            statusLabel.Text       = "Arrived: " .. entry.name
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 160)
            task.delay(2, function()
                if not teleporting then
                    statusLabel.Text       = "Select a destination"
                    statusLabel.TextColor3 = Color3.fromRGB(120, 100, 200)
                end
            end)
        end)
    end)
end

local function makeBtn(entry, index)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(24, 18, 52)
    btn.BorderSizePixel  = 0
    btn.Text             = string.format("  ⚑  %s", entry.name)
    btn.TextColor3       = Color3.fromRGB(200, 180, 255)
    btn.Font             = Enum.Font.Gotham
    btn.TextSize         = 12
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.AutoButtonColor  = false
    btn.LayoutOrder      = index
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
    btn.MouseButton1Click:Connect(function() fireTP(entry) end)
end

for i, entry in ipairs(BENDERA) do
    makeBtn(entry, i)
end

npcBtn.MouseEnter:Connect(function()
    TweenService:Create(npcBtn, TweenInfo.new(0.12), {
        BackgroundColor3 = Color3.fromRGB(70, 40, 120)
    }):Play()
end)
npcBtn.MouseLeave:Connect(function()
    TweenService:Create(npcBtn, TweenInfo.new(0.12), {
        BackgroundColor3 = Color3.fromRGB(40, 20, 80)
    }):Play()
end)
npcBtn.MouseButton1Click:Connect(function() fireTP(NPC_QUEST) end)

player.CharacterAdded:Connect(function(char)
    character   = char
    rootPart    = char:WaitForChild("HumanoidRootPart")
    humanoid    = char:WaitForChild("Humanoid")
    teleporting = false
    workspace.Gravity      = 196.2   -- safety: reset if respawn mid-tween
    statusLabel.Text       = "Select a destination"
    statusLabel.TextColor3 = Color3.fromRGB(120, 100, 200)
end)