-- Lua 5.1 | Roblox Executor | No dependencies

local Players   = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")
local camera      = workspace.CurrentCamera

local function formatCFrame(cf)
    local c = {cf:GetComponents()}
    return string.format("CFrame.new(%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f)",
        c[1],c[2],c[3],c[4],c[5],c[6],c[7],c[8],c[9],c[10],c[11],c[12])
end

local function copyToClipboard(text)
    if setclipboard then setclipboard(text)
    elseif toclipboard then toclipboard(text)
    elseif syn and syn.clipboard then syn.clipboard.set(text)
    else return false end
    return true
end

local function getHRP()
    local char = localPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "CFrameCopier"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = playerGui

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 160)
frame.Position = UDim2.new(0.5, -140, 0.5, -80)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- Titlebar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "CFrame Copier"
title.TextColor3 = Color3.fromRGB(220, 220, 220)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, 32)
statusLabel.Position = UDim2.new(0, 8, 0, 38)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready."
statusLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextWrapped = true
statusLabel.Parent = frame

local function flash(label, text)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(100, 220, 100)
    task.delay(2, function()
        label.TextColor3 = Color3.fromRGB(140, 140, 140)
        label.Text = "Ready."
    end)
end

-- Button factory
local function makeButton(labelText, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 34)
    btn.Position = UDim2.new(0, 8, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    btn.BorderSizePixel = 0
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(210, 210, 210)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.AutoButtonColor = false
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(55, 55, 55)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(38, 38, 38)}):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- HRP button
makeButton("Copy HRP CFrame", 78, function()
    local hrp = getHRP()
    if not hrp then
        statusLabel.Text = "HRP not found."
        statusLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
        task.delay(2, function()
            statusLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
            statusLabel.Text = "Ready."
        end)
        return
    end
    local result = formatCFrame(hrp.CFrame)
    copyToClipboard(result)
    flash(statusLabel, "HRP copied.")
end)

-- Camera button
makeButton("Copy Camera CFrame", 120, function()
    local result = formatCFrame(camera.CFrame)
    copyToClipboard(result)
    flash(statusLabel, "Camera copied.")
end)