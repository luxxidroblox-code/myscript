local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
warn("[DEBUG] Services loaded")
LP.Idled:Connect(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
warn("[DEBUG] Anti-AFK triggered")
end)
local DeliverySystem = ReplicatedStorage:WaitForChild("Delivery System", 10)
if not DeliverySystem then
warn("[DEBUG] Delivery System not found!")
return
end
warn("[DEBUG] Delivery System found")
local SettingsModule = DeliverySystem:WaitForChild("Settings", 10)
if not SettingsModule then
warn("[DEBUG] Settings module not found!")
return
end
warn("[DEBUG] Settings module found")
local CourierSettings = require(SettingsModule)
if not CourierSettings then
warn("[DEBUG] CourierSettings require failed!")
return
end
warn("[DEBUG] CourierSettings loaded:", CourierSettings)
local SupplyCF = CFrame.new(-5116.78418, 5.78931046, -670.858887)
local TAKE_BOX_CFRAME = CFrame.new(-5105.61182, 4.48948574, -3758.98267)
warn("[DEBUG] Finding TAKE_PROMPT...")
local Livrason = workspace:WaitForChild("Livrason", 10)
if not Livrason then warn("[DEBUG] Livrason not found!") return end
warn("[DEBUG] Livrason found")
local Take1 = Livrason:WaitForChild("Take1", 10)
if not Take1 then warn("[DEBUG] Take1 not found!") return end
warn("[DEBUG] Take1 found")
local Take = Take1:WaitForChild("Take", 10)
if not Take then warn("[DEBUG] Take not found!") return end
warn("[DEBUG] Take found")
local TAKE_PROMPT = Take:WaitForChild("ProximityPrompt", 10)
if not TAKE_PROMPT then warn("[DEBUG] ProximityPrompt not found!") return end
warn("[DEBUG] TAKE_PROMPT found:", TAKE_PROMPT)
_G.AutofarmCourier = true
_G.CourierSpeed = 300
local WaktuKosong = nil
local function _crash()
task.spawn(function()
while true do
task.wait(0.1)
pcall(function() local a = {}; table.insert(a, a) end)
end
end)
end
local function verifyFunction(func)
if typeof(func) ~= "function" then _crash() end
if islclosure and not islclosure(func) then _crash() end
if iscclosure and iscclosure(func) then _crash() end
return true
end
local function SwitchToCourier()
warn("[DEBUG] SwitchToCourier called")
local TeamRemote = ReplicatedStorage:FindFirstChild("TeamChangeRequest", true)
warn("[DEBUG] TeamRemote:", TeamRemote)
if TeamRemote then
warn("[DEBUG] LP.Team:", LP.Team and LP.Team.Name or "nil")
if not LP.Team or LP.Team.Name ~= "Courier" then
TeamRemote:FireServer("Courier", 11378976, 0, 0, "Detector")
task.wait(1.5)
end
end
warn("[DEBUG] SwitchToCourier done")
end
local function Tween(targetCFrame)
warn("[DEBUG] Tween called to:", targetCFrame)
local Char = LP.Character
local Root = Char and Char:FindFirstChild("HumanoidRootPart")
if not Root then warn("[DEBUG] Root not found in Tween!") return end
local distance = (Root.Position - targetCFrame.Position).Magnitude
local duration = distance / _G.CourierSpeed
warn("[DEBUG] Tween distance:", distance, "| duration:", duration)
Root.Velocity = Vector3.new(0,0,0)
Root.RotVelocity = Vector3.new(0,0,0)
local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
local tween = TweenService:Create(Root, info, {CFrame = targetCFrame})
tween:Play()
local connection
connection = RunService.Stepped:Connect(function()
if tween.PlaybackState == Enum.PlaybackState.Playing then
Root.Velocity = Vector3.new(0,0,0)
else
connection:Disconnect()
end
end)
tween.Completed:Wait()
Root.Velocity = Vector3.new(0,0,0)
warn("[DEBUG] Tween completed")
end
local function AutoEquipBox()
warn("[DEBUG] AutoEquipBox called")
local Char = LP.Character
if not Char or not Char:FindFirstChild("Humanoid") then
warn("[DEBUG] AutoEquipBox: no Char or Humanoid")
return false
end
local held = Char:FindFirstChildOfClass("Tool")
if held and held.Name:lower() == "box" then
warn("[DEBUG] AutoEquipBox: already holding box")
return true
end
local bp = LP:FindFirstChild("Backpack")
if bp then
for _, item in pairs(bp:GetChildren()) do
if item:IsA("Tool") and item.Name:lower() == "box" then
warn("[DEBUG] AutoEquipBox: equipping box from backpack")
Char.Humanoid:EquipTool(item)
return true
end
end
end
warn("[DEBUG] AutoEquipBox: no box found")
return false
end
local function GetActivePoint()
warn("[DEBUG] GetActivePoint called")
if not CourierSettings.Folder or not CourierSettings.Folder.Location then
warn("[DEBUG] CourierSettings.Folder.Location not found!")
return nil, nil
end
for _, folder in ipairs(CourierSettings.Folder.Location:GetChildren()) do
local block = folder:FindFirstChild("Block")
local prompt = block and block:FindFirstChildOfClass("ProximityPrompt")
local point = folder:FindFirstChild("POINT")
warn("[DEBUG] Checking folder:", folder.Name, "| block:", block and block.Name or "nil", "| prompt:", prompt and tostring(prompt.Enabled) or "nil", "| POINT:", point and point.Name or "nil")
if prompt and (prompt.Enabled or (point and point:FindFirstChild("billboardgui") and point.billboardgui.Enabled)) then
warn("[DEBUG] Active point found:", folder.Name)
return block, prompt
end
end
warn("[DEBUG] No active point found")
return nil, nil
end
warn("[DEBUG] Starting main loop")
task.spawn(function()
while true do
task.wait(1)
if _G.AutofarmCourier then
warn("[DEBUG] Loop tick - AutofarmCourier active")
SwitchToCourier()
local Char = LP.Character or LP.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid")
local Root = Char:WaitForChild("HumanoidRootPart")
warn("[DEBUG] Char:", Char.Name, "| Hum:", Hum and "found" or "nil", "| Root:", Root and "found" or "nil")
if Hum and Root then
if not AutoEquipBox() then
if not WaktuKosong then
WaktuKosong = os.clock()
warn("[DEBUG] WaktuKosong started:", WaktuKosong)
end
local elapsed = os.clock() - WaktuKosong
warn("[DEBUG] WaktuKosong elapsed:", elapsed)
if elapsed >= 240 then
warn("[DEBUG] 240s timeout, switching to Civilian")
local args = {"Civilian", 0, 0, 0, "Detector"}
game:GetService("ReplicatedStorage"):WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest"):FireServer(unpack(args))
WaktuKosong = nil
repeat
task.wait(1)
until (LP.Team and LP.Team.Name == "Civilian") or not _G.AutofarmCourier
task.wait(15)
continue
end
else
WaktuKosong = nil
end
if not Hum.Sit then
warn("[DEBUG] Sitting humanoid")
repeat
Hum.Sit = true
task.wait(0.5)
until Hum.Sit or not _G.AutofarmCourier
task.wait(1)
end
if not AutoEquipBox() then
warn("[DEBUG] No box, tweening to TAKE_BOX_CFRAME")
Tween(TAKE_BOX_CFRAME)
task.wait(0.5)
if _G.AutofarmCourier and TAKE_PROMPT.Enabled then
warn("[DEBUG] Firing TAKE_PROMPT")
fireproximityprompt(TAKE_PROMPT)
task.wait(1.5)
else
warn("[DEBUG] TAKE_PROMPT disabled or AutofarmCourier off")
end
else
local TargetBlock, TargetPrompt = GetActivePoint()
warn("[DEBUG] TargetBlock:", TargetBlock and TargetBlock.Name or "nil", "| TargetPrompt:", TargetPrompt and tostring(TargetPrompt.Enabled) or "nil")
if TargetBlock and TargetPrompt then
task.wait(math.random(0, 1))
Tween(TargetBlock.CFrame * CFrame.new(0, 2, 0))
task.wait(0.8)
AutoEquipBox()
if _G.AutofarmCourier and TargetPrompt.Enabled then
warn("[DEBUG] Firing TargetPrompt")
fireproximityprompt(TargetPrompt)
task.wait(3.5)
else
warn("[DEBUG] TargetPrompt disabled or AutofarmCourier off")
end
end
end
end
else
WaktuKosong = nil
end
end
end)
warn("[DEBUG] Script fully loaded")
