-- Copy CFrame GUI (Roblox Executor)
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Hapus GUI lama jika sudah ada
if CoreGui:FindFirstChild("CFrameCopyGui") then
    CoreGui.CFrameCopyGui:Destroy()
end

-- ScreenGui Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CFrameCopyGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

-- Main Frame (Tombol Melayang)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 160, 0, 50)
frame.Position = UDim2.new(0.05, 0, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Button
local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -10, 1, -10)
button.Position = UDim2.new(0, 5, 0, 5)
button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
button.Text = "📋 Copy CFrame"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 14
button.Font = Enum.Font.SourceSansBold
button.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = button

-- Logic Copy CFrame
button.MouseButton1Click:Connect(function()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local cf = character.HumanoidRootPart.CFrame
        local cfString = string.format("CFrame.new(%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f)", cf:GetComponents())
        
        if setclipboard then
            setclipboard(cfString)
            button.Text = "✅ Copied!"
        else
            print(cfString)
            button.Text = "Printed in F9"
        end
        
        task.wait(1.5)
        button.Text = "📋 Copy CFrame"
    end
end)
