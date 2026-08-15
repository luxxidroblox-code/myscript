-- CFrame & Vector3 Copier — paste ke executor, jalanin di game

local LP = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")

local function copyToClipboard(text)
    if setclipboard then setclipboard(text)
    elseif toclipboard then toclipboard(text)
    elseif syn and syn.write_clipboard then syn.write_clipboard(text)
    else warn("Clipboard not supported on this executor") end
end

local function getRootCF()
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return hrp.CFrame
end

local function formatCF(cf)
    local p = cf.Position
    local ax, ay, az = cf:ToEulerAnglesXYZ()
    return string.format(
        "CFrame.new(%.2f, %.2f, %.2f) * CFrame.Angles(%.4f, %.4f, %.4f)",
        p.X, p.Y, p.Z, ax, ay, az
    )
end

local function formatVec(cf)
    local p = cf.Position
    return string.format("Vector3.new(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
end

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CFrameCopier"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 340, 0, 160)
Frame.Position = UDim2.new(0.5, -170, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.TextColor3 = Color3.fromRGB(220, 220, 220)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Text = "CFrame Copier — .projectsion"
Title.Parent = Frame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

local Output = Instance.new("TextLabel")
Output.Size = UDim2.new(1, -20, 0, 40)
Output.Position = UDim2.new(0, 10, 0, 38)
Output.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
Output.TextColor3 = Color3.fromRGB(180, 255, 160)
Output.Font = Enum.Font.Code
Output.TextSize = 11
Output.TextWrapped = true
Output.TextXAlignment = Enum.TextXAlignment.Left
Output.Text = "Move character to position, then copy."
Output.Parent = Frame

local OutCorner = Instance.new("UICorner")
OutCorner.CornerRadius = UDim.new(0, 6)
OutCorner.Parent = Output

local function makeButton(text, posY, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 150, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = text
    btn.BorderSizePixel = 0
    btn.Parent = Frame
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = btn
    return btn
end

local BtnCF  = makeButton("Copy CFrame",  90, Color3.fromRGB(50, 120, 200))
local BtnVec = makeButton("Copy Vector3", 90, Color3.fromRGB(60, 160, 80))
BtnVec.Position = UDim2.new(0, 175, 0, 90)

local BtnClose = Instance.new("TextButton")
BtnClose.Size = UDim2.new(0, 24, 0, 24)
BtnClose.Position = UDim2.new(1, -28, 0, 3)
BtnClose.BackgroundTransparency = 1
BtnClose.TextColor3 = Color3.fromRGB(180, 80, 80)
BtnClose.Font = Enum.Font.GothamBold
BtnClose.TextSize = 16
BtnClose.Text = "✕"
BtnClose.Parent = Frame
BtnClose.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

BtnCF.MouseButton1Click:Connect(function()
    local cf = getRootCF()
    if not cf then Output.Text = "No character found." return end
    local str = formatCF(cf)
    copyToClipboard(str)
    Output.Text = "✓ " .. str
end)

BtnVec.MouseButton1Click:Connect(function()
    local cf = getRootCF()
    if not cf then Output.Text = "No character found." return end
    local str = formatVec(cf)
    copyToClipboard(str)
    Output.Text = "✓ " .. str
end)

-- ProximityPrompt — triggers Copy CFrame on [E], attached to HRP
-- *ProximityPrompt fires Triggered only for the LocalPlayer who owns the part;
--  no server replication needed here since HRP is client-side read*
local function injectPrompt()
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    if not hrp then return end

    -- clean up any leftover from a prior run
    local old = hrp:FindFirstChild("CFrameCopierPrompt")
    if old then old:Destroy() end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CFrameCopierPrompt"
    prompt.ActionText = "Copy CFrame"
    prompt.ObjectText = ".projectsion"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0          -- instant, no hold bar
    prompt.MaxActivationDistance = 0 -- only self can trigger; 0 = no range limit shown
    prompt.RequiresLineOfSight = false
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
    prompt.Parent = hrp

    prompt.Triggered:Connect(function(_player)
        local cf = getRootCF()
        if not cf then Output.Text = "No character found." return end
        local str = formatCF(cf)
        copyToClipboard(str)
        Output.Text = "✓ [Prompt] " .. str
    end)
end

injectPrompt()

-- re-inject on respawn so the prompt survives character reloads
LP.CharacterAdded:Connect(function()
    task.wait(1) -- wait for HRP to exist
    injectPrompt()
end)