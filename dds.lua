Local genv = getgenv()
local fenv = getfenv()

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
_G.AutoFarmOffice = false
_G.AutoPoliceEnabled = false
_G.blackscreen = false 

_G.AutoWebhook = false
_G.WebhookURL = ""
_G.TotalEarning = 0
_G.CycleCount = 0
_G.StartTime = os.time()
LastActivity = tick()
local lastMoney = PlayerData.RPValue.Value
local pendingIncome = 0
local isRunning = false
local cooldownTime = 60
local WaktuKosong = nil

_G.CourierEarned = 0
_G.BaristaEarned = 0
_G.OfficeEarned = 0
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

local function RejoinServer()
    local queue_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    
    Rayfield:Notify({
        Title = "Projectsion",
        Content = "Rejoining server safely...",
        Duration = 3
    })
    task.wait(1.5)
    
    if queue_teleport then
        queue_teleport([[
            if not game:IsLoaded() then
                game.Loaded:Wait()
            end
            task.wait(1.5)
            pcall(function() 
                loadstring(game:HttpGet("https://raw.githubusercontent.com/LynX99-9/komtolmmek2/refs/heads/main/Adonis"))() 
            end)
            task.wait(1.5)
            pcall(function() 
                loadstring(game:HttpGet("https://raw.githubusercontent.com/luxxidroblox-code/myscript.lua/refs/heads/main/dds.lua"))() 
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
    if Frame.Visible == false and _G.blackscreen then
        Frame.Visible = true
    end
end)

local function updateBlackScreen()
    verifyFunction(updateBlackScreen)
    _G.blackscreen = (_G.AutofarmCourier or _G.AutoFarmBarista or _G.AutoFarmOffice or _G.AutoPoliceEnabled)
    BlackScreen.Enabled = _G.blackscreen
end

local function SwitchToCourier()
    local TeamRemote = ReplicatedStorage:FindFirstChild("TeamChangeRequest", true)
    if TeamRemote then
        if not LP.Team or LP.Team.Name ~= "Courier" then
            TeamRemote:FireServer("Courier", 11378976, 0, 0, "Detector")
            task.wait(1.5)
        end
    end
end

local function Tween(targetCFrame)
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    if not Root then return end

    local distance = (Root.Position - targetCFrame.Position).Magnitude
    local duration = distance / _G.CourierSpeed

    Root.Velocity = Vector3.new(0,0,0)
    Root.RotVelocity = Vector3.new(0,0,0)

    local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(Root, info, {CFrame = targetCFrame})

    tween:Play()

    local connection
    connection = game:GetService("RunService").Stepped:Connect(function()
        if tween.PlaybackState == Enum.PlaybackState.Playing then
            Root.Velocity = Vector3.new(0,0,0)
        else
            connection:Disconnect()
        end
    end)

    tween.Completed:Wait()
    Root.Velocity = Vector3.new(0,0,0)
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
        ["author"] = {
            ["name"] = "Projectsion Webhook",
            ["icon_url"] = getAvatar()
        },
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
        ["image"] = {
            ["url"] = "https://cdn.discordapp.com/attachments/1492837859370074192/1508063383944036433/IMG_20260524_180509.jpg?ex=6a142cf9&is=6a12db79&hm=124ec4dccb5d72326d9b0776d912bb18631948f41162cd9fa6d08eafcff19fb4&"
        },
        ["footer"] = {
            ["text"] = "Made By Projectsion | " .. os.date("%m/%d/%Y %I:%M %p")
        }
    }

    local payload = HttpService:JSONEncode({
        ["username"] = "Projectsion Reports",
        ["embeds"] = {embed}
    })

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
local lblCourierEarned, lblBaristaEarned, lblOfficeEarned, lblPoliceEarned

PlayerData.RPValue.Changed:Connect(function(newMoney)
    if newMoney > lastMoney then
        local gained = newMoney - lastMoney
        pendingIncome = pendingIncome + gained
        _G.TotalEarning = _G.TotalEarning + gained
        
        if _G.AutofarmCourier then
            _G.CourierEarned = _G.CourierEarned + gained
        elseif _G.AutoFarmBarista then
            _G.BaristaEarned = _G.BaristaEarned + gained
        elseif _G.AutoFarmOffice then
            _G.OfficeEarned = _G.OfficeEarned + gained
        elseif _G.AutoPoliceEnabled then
            _G.PoliceEarned = _G.PoliceEarned + gained
        end

        if lblTotalEarned then lblTotalEarned:Set("Total Earned: " .. formatRP(_G.TotalEarning)) end
        if lblCurrentMoney then lblCurrentMoney:Set("Current Money: " .. formatRP(newMoney)) end
        if lblCourierEarned then lblCourierEarned:Set("Courier: " .. formatRP(_G.CourierEarned)) end
        if lblBaristaEarned then lblBaristaEarned:Set("Barista: " .. formatRP(_G.BaristaEarned)) end
        if lblOfficeEarned then lblOfficeEarned:Set("Office Worker: " .. formatRP(_G.OfficeEarned)) end
        if lblPoliceEarned then lblPoliceEarned:Set("Police Department: " .. formatRP(_G.PoliceEarned)) end

        if not isRunning then
            isRunning = true
            task.spawn(function()
                while isRunning do
                    task.wait(60)
                    if pendingIncome > 0 and _G.WebhookURL ~= "" then
                        sendWebhook(pendingIncome, 0)
                        pendingIncome = 0
                    end
                    if not _G.AutofarmCourier and not _G.AutoFarmBarista and not _G.AutoFarmOffice and not _G.AutoPoliceEnabled then
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

    if Hum and Root then
        local distance = (Root.Position - targetCF.Position).Magnitude
        local duration = distance / _G.BaristaSpeed

        Hum.Sit = true
        task.wait(0.5)

        local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(Root, info, {CFrame = targetCF})
        tween:Play()
        tween.Completed:Wait()

        task.wait(0.3)
        Hum.Sit = false
    end
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
        fireproximityprompt(JobPrompt)
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
                    fireproximityprompt(SupplyPrompt)
                    LastActivity = tick()
                    task.wait(0.5)
                    BypassTP(MachineCF)
                    fireproximityprompt(MachinePrompt)
                elseif MachinePrompt.Enabled and not (MinigameFrame and MinigameFrame.Visible) then
                    BypassTP(MachineCF)
                    fireproximityprompt(MachinePrompt)
                    LastActivity = tick()
                    repeat task.wait(0.5)
                        LastActivity = tick()
                    until not (MinigameFrame and MinigameFrame.Visible) or not _G.AutoFarmBarista
                elseif RegisterPrompt.Enabled and not (MinigameFrame and MinigameFrame.Visible) then
                    task.wait(0.5)
                    BypassTP(RegisterCF)
                    task.wait(0.5)
                    fireproximityprompt(RegisterPrompt)
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

            if Hum and Root then
                local BoxTempatAmbil = workspace:FindFirstChild("Livrason") and workspace.Livrason:FindFirstChild("Take1")
                local TargetBlock, TargetPrompt = GetActivePoint()
                
                if not BoxTempatAmbil or (AutoEquipBox() and not TargetBlock) then
                    RejoinServer()
                    break
                end

                if not AutoEquipBox() then
                    if not WaktuKosong then
                        WaktuKosong = os.clock()
                    end

                    if (os.clock() - WaktuKosong) >= 240 then
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
                    repeat
                        Hum.Sit = true
                        task.wait(0.5)
                    until Hum.Sit or not _G.AutofarmCourier
                    task.wait(1)
                end

                if not AutoEquipBox() then
                    Tween(TAKE_BOX_CFRAME)
                    task.wait(0.5)

                    if _G.AutofarmCourier and TAKE_PROMPT.Enabled then
                        fireproximityprompt(TAKE_PROMPT)
                        task.wait(1.5)
                    end
                else
                    if TargetBlock and TargetPrompt then
                        task.wait(math.random(0, 1))

                        Tween(TargetBlock.CFrame * CFrame.new(0, 2, 0))
                        task.wait(0.8)

                        AutoEquipBox()

                        if _G.AutofarmCourier and TargetPrompt.Enabled then
                            fireproximityprompt(TargetPrompt)
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

local d = false
local h = {}
local x, y
setthreadidentity(2)
for i, v in getgc(true) do
    if typeof(v) == "table" then
        local a = rawget(v, "Detected")
        local b = rawget(v, "Kill")
        if typeof(a) == "function" and not x then
            x = a
            local o; o = hookfunction(x, function(c, f, n)
                if c ~= "_" then
                    if d then warn(`Adonis flagged\nMethod: {c}\nInfo: {f}`) end
                end
                return true
            end)
            table.insert(h, x)
        end
        if rawget(v, "Variables") and rawget(v, "Process") and typeof(b) == "function" and not y then
            y = b
            local o; o = hookfunction(y, function(f)
                if d then warn(`Adonis tried to kill: {f}`) end
            end)
            table.insert(h, y)
        end
    end
end
local o; o = hookfunction(getrenv().debug.info, newcclosure(function(...)
    local a, f = ...
    if x and a == x then return coroutine.yield(coroutine.running()) end
    return o(...)
end))
setthreadidentity(7)

pcall(function()
    if getgenv and getgenv().NZNT_OFFICE_STOP then
        getgenv().NZNT_OFFICE_STOP()
    end
end)

local PathfindingService = game:GetService("PathfindingService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local STATS_FILE = "nznt_office_stats.txt"
local CONFIG_FILE = "nznt_office_config.txt"
local CONFIG_LOCK_FILE = "nznt_office_config_locked_3_7_v2.txt"
local WEBHOOK_FILE = "nznt_webhook_config.json"
local SCRIPT_URL = "https://scripts.nznt.store/raw.php?file=office_autofarm_testing_delta_checkpoint.lua"

local MIN_DELAY = 0.0
local MAX_DELAY = 10.0
local answerDelayMin = 3.0
local answerDelayMax = 7.0

local CHAIR_SEARCH_AREA = Vector3.new(-5927.33, 4.57, -228.61)
local CHAIR_SEARCH_RADIUS = 50

local PRINTER_POS = {
    Print_1 = Vector3.new(-6008.84, 4.58, -210.84),
    Print_2 = Vector3.new(-6008.84, 4.58, -224.52),
    Print_3 = Vector3.new(-6008.84, 4.58, -238.36),
    Print_4 = Vector3.new(-5868.43, 4.58, -213.19),
    Print_5 = Vector3.new(-5868.43, 4.58, -249.96)
}

local active = false
local joiningTeam = false
local currentSeat = nil
local unseatedSince = 0
local lastReseatAttemptAt = 0
local pendingPrint = nil
local isDoingPrinterJob = false
local printerVerifyName = nil
local printerVerifyStartedAt = 0
local printerVerifyQuestionCount = 0

local questionsAnswered = 0
local printersCompleted = 0
local totalEarned = 0
local totalTime = 0

local remCorrectAnswer = nil
local remGenQuestion = nil
local remAssignPrint = nil
local questionConnection = nil
local printConnection = nil
local seatBlockActive = false
local seatBlockToken = 0
local answeringQuestion = false
local lastQuestionKey = nil
local lastQuestionAt = 0
local lastAnswerAt = 0
local activeQuestionToken = 0
local MAX_ANSWER_RETRIES = 8
local ANSWER_RETRY_DELAY = 0.65

local function getChar() return Player.Character or Player.CharacterAdded:Wait() end

local function sendKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function setSeatBlocking(enabled)
    seatBlockActive = enabled
    seatBlockToken = seatBlockToken + 1
    local token = seatBlockToken
    local function updateHumanoid()
        local char = Player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not hum then return end
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, not enabled) end)
        if enabled and hum.SeatPart then
            sendKey(Enum.KeyCode.Space)
            task.wait(0.05)
            hum.Sit = false
        end
    end
    updateHumanoid()
    if enabled then
        task.spawn(function()
            while seatBlockActive and seatBlockToken == token do
                updateHumanoid()
                task.wait(0.1)
            end
        end)
    end
end

local function jumpAndReseatCurrentSeat()
    if not currentSeat or not currentSeat.Parent then return false end
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end

    activeQuestionToken = activeQuestionToken + 1
    answeringQuestion = false
    setSeatBlocking(false)
    sendKey(Enum.KeyCode.Space)
    task.wait(0.45)

    for _ = 1, 4 do
        if not currentSeat or not currentSeat.Parent then return false end
        pcall(function()
            hum.Sit = false
            root.CFrame = currentSeat.CFrame * CFrame.new(0, 2.5, 0)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
        task.wait(0.12)
        pcall(function() currentSeat:Sit(hum) end)
        task.wait(0.45)
        if hum.SeatPart == currentSeat then
            unseatedSince = 0
            lastQuestionAt = os.clock()
            lastAnswerAt = os.clock()
            return true
        end
    end
    lastQuestionAt = os.clock()
    lastAnswerAt = os.clock()
    return false
end

local function interactWithPrinter()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:SetKeyDown("0x65")
    end)
    task.wait(1.8)
    pcall(function() VirtualUser:SetKeyUp("0x65") end)
    return true
end

local function normalizeMathText(text)
    local normalized = tostring(text or "")
    normalized = normalized:gsub("\226\136\146", "-"):gsub("\226\128\147", "-"):gsub("\226\128\148", "-"):gsub("\195\151", "*"):gsub("\195\183", "/")
    return normalized
end

local function solveQuestion(question)
    local text = normalizeMathText(question)
    local a, op, b = text:match("([%-]?%d+%.?%d*)%s*([+%*/xX%-])%s*([%-]?%d+%.?%d*)")
    if not a then return nil end
    a, b = tonumber(a), tonumber(b)
    if not a or not b then return nil end
    if op == "x" or op == "X" then op = "*" end
    if op == "+" then return a + b
    elseif op == "-" then return a - b
    elseif op == "*" then return a * b
    elseif op == "/" and b ~= 0 then
        local result = a / b
        return result == math.floor(result) and math.floor(result) or result
    end
    return nil
end

local function findAvailableChair()
    local bestChair, closestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
            local dist = (obj.Position - CHAIR_SEARCH_AREA).Magnitude
            if dist < CHAIR_SEARCH_RADIUS and not obj.Occupant and dist < closestDist then
                closestDist = dist
                bestChair = obj
            end
        end
    end
    return bestChair
end

local function seatTP(targetSeat)
    if not targetSeat then return false end
    local char = getChar()
    local hum = char:WaitForChild("Humanoid")
    local root = char:WaitForChild("HumanoidRootPart")
    local originalCFrame = targetSeat.CFrame

    targetSeat.CFrame = root.CFrame * CFrame.new(0, -2, -3)
    task.wait(0.2)
    targetSeat:Sit(hum)
    task.wait(0.3)
    if hum.SeatPart ~= targetSeat then
        targetSeat:Sit(hum)
        task.wait(0.4)
    end
    targetSeat.CFrame = originalCFrame
    task.wait(0.5)
    return hum.SeatPart == targetSeat
end

local function walkTo(targetPos)
    local char = getChar()
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end

    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentJumpHeight = 7.5, AgentMaxSlope = 45})
    local success = pcall(function() path:ComputeAsync(root.Position, targetPos) end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        hum:MoveTo(targetPos)
        local started = os.clock()
        while active and (root.Position - targetPos).Magnitude > 4 and os.clock() - started < 10 do task.wait(0.1) end
        return (root.Position - targetPos).Magnitude <= 6
    end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        if not active then break end
        if waypoint.Action == Enum.PathWaypointAction.Jump then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        hum:MoveTo(waypoint.Position)
        local timeout = 0
        while active and (root.Position - waypoint.Position).Magnitude > 4 and timeout < 50 do
            task.wait(0.1)
            timeout = timeout + 1
        end
    end
    return true
end

local function ensureRemotes()
    local jobEvents = ReplicatedStorage:WaitForChild("JobEvents", 10)
    if not jobEvents then return false end
    remCorrectAnswer = jobEvents:WaitForChild("CorrectAnswer", 10)
    remGenQuestion = jobEvents:WaitForChild("GenerateQuestion", 10)
    remAssignPrint = jobEvents:WaitForChild("AssignPrintJob", 10)
    return (remCorrectAnswer and remGenQuestion and remAssignPrint) and true or false
end

local function safeFireServer(remote, ...)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
    end
end

local function normalizeAnswerText(text) return normalizeMathText(text):lower():gsub("%s+", ""):gsub(",", "") end

local function isVisibleGuiObject(obj)
    if not obj:IsA("GuiObject") or obj.AbsoluteSize.X <= 0 or obj.AbsoluteSize.Y <= 0 then return false end
    local current = obj
    while current do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if (current:IsA("ScreenGui") or current:IsA("SurfaceGui") or current:IsA("BillboardGui")) and not current.Enabled then return false end
        current = current.Parent
    end
    return true
end

local function answerTextMatches(buttonText, answerText, solvedValue)
    local normalizedButton = normalizeAnswerText(buttonText)
    if normalizedButton == "" then return false end
    if normalizeAnswerText(answerText) ~= "" and normalizedButton == normalizeAnswerText(answerText) then return true end
    if normalizeAnswerText(solvedValue) ~= "" and normalizedButton == normalizeAnswerText(solvedValue) then return true end
    local numericButton = tonumber(normalizeMathText(buttonText):match("[%-]?%d+%.?%d*"))
    return numericButton ~= nil and tonumber(solvedValue) ~= nil and numericButton == tonumber(solvedValue)
end

local function findMatchingAnswerTarget(button, answerText, solvedValue)
    if button:IsA("TextButton") and answerTextMatches(button.Text or "", answerText, solvedValue) then return button end
    for _, child in ipairs(button:GetDescendants()) do
        if (child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("TextBox")) and answerTextMatches(child.Text or "", answerText, solvedValue) then
            return child
        end
    end
    return nil
end

local function guiContainsQuestion(root, questionText)
    local needles = {normalizeAnswerText(questionText)}
    for _, obj in ipairs(root:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("TextBox")) and normalizeAnswerText(obj.Text) ~= "" then
            for _, needle in ipairs(needles) do if normalizeAnswerText(obj.Text):find(needle, 1, true) then return true end end
        end
    end
    return false
end

local function scoreAnswerButton(button, questionText)
    local score = (button.ZIndex or 0)
    local current = button.Parent
    local depth = 1
    while current and depth <= 8 do
        if questionText and guiContainsQuestion(current, questionText) then score = score + (220 - depth * 10) break end
        current = current.Parent
        depth = depth + 1
    end
    return score
end

local function findAnswerButton(answerText, solvedValue, questionText)
    local bestButton, bestScore, candidates = nil, -math.huge, {}
    local workGui = PlayerGui:FindFirstChild("WorkGui")
    if not workGui then return nil, 0, {} end

    for _, obj in ipairs(workGui:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and isVisibleGuiObject(obj) then
            local target = findMatchingAnswerTarget(obj, answerText, solvedValue)
            if target then
                local score = scoreAnswerButton(obj, questionText)
                table.insert(candidates, {Button = obj, Target = target, Score = score})
                if score >= bestScore then bestButton = obj; bestScore = score end
            end
        end
    end
    return bestButton, #candidates, candidates
end

local function fireGuiButtonDirectly(button)
    if not button or not button.Parent or not button:IsA("GuiButton") then return false end
    pcall(function() button:Activate() end)
    if firesignal then pcall(function() firesignal(button.MouseButton1Click) end) end
    return true
end

local function clickAnswerButtonAndWait(button, timeout, target)
    local response, done = nil, false
    local conn; conn = remCorrectAnswer.OnClientEvent:Connect(function(result) response = result; done = true end)
    local started = os.clock()
    fireGuiButtonDirectly(button)
    if target and target ~= button then fireGuiButtonDirectly(target) end
    while active and not done and os.clock() - started < timeout do task.wait(0.05) end
    if conn then conn:Disconnect() end
    return response, true
end

local function answerQuestion(question, answers, sessionId, attempt, questionToken)
    attempt = tonumber(attempt) or 1
    questionToken = tonumber(questionToken) or activeQuestionToken
    if not active or answeringQuestion or questionToken ~= activeQuestionToken then return end
    answeringQuestion = true

    task.spawn(function()
        pcall(function()
            if not active or questionToken ~= activeQuestionToken then return end
            local solvedValue = solveQuestion(question)
            if not solvedValue then return end

            local delayTime = answerDelayMin + math.random() * (answerDelayMax - answerDelayMin)
            task.wait(delayTime)
            if not active or questionToken ~= activeQuestionToken then return end

            local answerButton, _, candidates = findAnswerButton(tostring(solvedValue), solvedValue, question)
            if not answerButton then
                if attempt < MAX_ANSWER_RETRIES and questionToken == activeQuestionToken then
                    task.delay(ANSWER_RETRY_DELAY, function() answerQuestion(question, answers, sessionId, attempt + 1, questionToken) end)
                else
                    jumpAndReseatCurrentSeat()
                end
                return
            end

            local finalResponse, clickedAny = nil, false
            for index, candidate in ipairs(candidates) do
                if not active or questionToken ~= activeQuestionToken then return end
                local response, clicked = clickAnswerButtonAndWait(candidate.Button, 1.3, candidate.Target)
                clickedAny = clickedAny or clicked
                if response == true or tostring(response):lower() == "success" then finalResponse = response; break end
                task.wait(0.12)
            end

            if finalResponse == true or tostring(finalResponse):lower() == "success" then
                questionsAnswered = questionsAnswered + 1
                lastAnswerAt = os.clock()
                if printerVerifyName then printersCompleted = printersCompleted + 1; printerVerifyName = nil end
            elseif attempt < MAX_ANSWER_RETRIES and questionToken == activeQuestionToken then
                task.delay(ANSWER_RETRY_DELAY, function() answerQuestion(question, answers, sessionId, attempt + 1, questionToken) end)
            else
                jumpAndReseatCurrentSeat()
            end
        end)
        answeringQuestion = false
    end)
end

local function onQuestionReceived(question, answers, sessionId)
    if not active then return end
    local questionKey = tostring(sessionId or "") .. "|" .. normalizeAnswerText(question)
    if questionKey == lastQuestionKey and os.clock() - lastQuestionAt < 4 then return end
    lastQuestionKey = questionKey
    lastQuestionAt = os.clock()
    activeQuestionToken = activeQuestionToken + 1
    answerQuestion(question, answers, sessionId, 1, activeQuestionToken)
end

local function joinOfficeTeam()
    if joiningTeam then return true end
    joiningTeam = true
    local menuToggleRemote = ReplicatedStorage:WaitForChild("menuToggleRequest", 10)
    if menuToggleRemote then safeFireServer(menuToggleRemote) task.wait(1) end
    local teamChangeRemote = ReplicatedStorage:WaitForChild("JobEvents", 10):WaitForChild("TeamChangeRequest", 10)
    safeFireServer(teamChangeRemote, "Office Worker", 0, 0, 0, "MainMenu")
    task.wait(3)
    joiningTeam = false
    return true
end

local function mainFarmLoop()
    local usedInitialSeatTeleport = false
    while active do
        local char = getChar()
        local hum = char:WaitForChild("Humanoid")
        local seat = findAvailableChair()
        if not seat then task.wait(3) continue end

        currentSeat = seat
        local seated = false
        if not usedInitialSeatTeleport then
            seated = seatTP(seat)
            usedInitialSeatTeleport = seated
        else
            walkTo(seat.Position)
            task.wait(0.3)
            seat:Sit(hum)
            task.wait(0.5)
            seated = hum.SeatPart == seat
        end
        if not seated then task.wait(2) continue end
        unseatedSince = 0
        lastReseatAttemptAt = 0

        while active do
            if pendingPrint then
                local pos = PRINTER_POS[pendingPrint]
                if pos then
                    isDoingPrinterJob = true
                    local officeSeat = currentSeat
                    local currentPrint = pendingPrint
                    printerVerifyName = nil
                    setSeatBlocking(true)
                    sendKey(Enum.KeyCode.Space)
                    task.wait(0.5)
                    walkTo(pos)
                    task.wait(0.5)
                    interactWithPrinter()
                    task.wait(1)
                    pendingPrint = nil

                    if officeSeat and officeSeat.Parent then
                        walkTo(officeSeat.Position)
                        task.wait(0.5)
                        setSeatBlocking(false)
                        officeSeat:Sit(hum)
                        task.wait(0.5)
                        currentSeat = officeSeat
                        unseatedSince = 0
                        lastReseatAttemptAt = 0
                        printerVerifyName = currentPrint
                        printerVerifyStartedAt = hum.SeatPart == officeSeat and os.clock() or 0
                        printerVerifyQuestionCount = questionsAnswered
                    else
                        setSeatBlocking(false)
                    end
                    isDoingPrinterJob = false
                    setSeatBlocking(false)
                else
                    pendingPrint = nil
                end
            elseif not isDoingPrinterJob and hum.SeatPart ~= currentSeat then
                if currentSeat and currentSeat.Parent then
                    if unseatedSince <= 0 then unseatedSince = os.clock() end
                    if os.clock() - lastReseatAttemptAt >= 1.5 then
                        lastReseatAttemptAt = os.clock()
                        jumpAndReseatCurrentSeat()
                    end
                else
                    break
                end
            end
            task.wait(0.2)
        end
        task.wait(1)
    end
end

local function stopOfficeFarm()
    active = false
    _G.AutoFarmOffice = false
    setSeatBlocking(false)
    if questionConnection then questionConnection:Disconnect(); questionConnection = nil end
    if printConnection then printConnection:Disconnect(); printConnection = nil end
    pendingPrint = nil
    isDoingPrinterJob = false
end

local function startOfficeFarm()
    if _G.AutoFarmOffice then return end
    joinOfficeTeam()
    if not ensureRemotes() then return end
    active = true
    _G.AutoFarmOffice = true
    questionsAnswered = 0
    printersCompleted = 0
    pendingPrint = nil
    currentSeat = nil
    questionConnection = remGenQuestion.OnClientEvent:Connect(onQuestionReceived)
    printConnection = remAssignPrint.OnClientEvent:Connect(function(printerName) if active then pendingPrint = printerName end end)
    task.spawn(mainFarmLoop)
end

pcall(function()
    setthreadidentity(2)
    local DetectFunc, KillFunc
    for _, v in getgc(true) do
        if typeof(v) == "table" then
            local a, b = rawget(v, "Detected"), rawget(v, "Kill")
            if typeof(a) == "function" and not DetectFunc then
                DetectFunc = a
                hookfunction(DetectFunc, function() return true end)
            end
            if typeof(b) == "function" and not KillFunc then
                KillFunc = b
                hookfunction(KillFunc, function() end)
            end
        end
    end
    local targetFunc = getrenv().debug.info or debug.info
    if targetFunc then
        local oldDebugInfo; oldDebugInfo = hookfunction(targetFunc, newcclosure(function(...)
            if DetectFunc and (...) == DetectFunc then return coroutine.yield(coroutine.running()) end
            return oldDebugInfo(...)
        end))
    end
    setthreadidentity(7)
end)

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
        
        local currentPos = mainPart.Position
        local targetPos = destCFrame.Position
        local distance = (targetPos - currentPos).Magnitude
        local speedConf = AutoPoliceConfig.TeleportSpeed
        local speed = math.random(speedConf.min, speedConf.max)
        local duration = distance / speed

        if duration > 0 then
            if isDriving then
                if vehicle then
                    for _, p in ipairs(vehicle:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = false end end
                end
                mainPart.Velocity, mainPart.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
                local tween = TweenService:Create(mainPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = destCFrame})
                local connection; connection = RunService.Stepped:Connect(function()
                    if tween.PlaybackState == Enum.PlaybackState.Playing then
                        pcall(function()
                            mainPart.Velocity, mainPart.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
                            if vehicle and vehicle.PrimaryPart then
                                vehicle.PrimaryPart.Velocity, vehicle.PrimaryPart.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
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
                HRP.Anchored = false
                local startTime = os.clock()
                while os.clock() - startTime < duration do
                    if not _G.AutoPoliceEnabled then break end
                    local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
                    pcall(function()
                        HRP.Velocity, HRP.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
                        HRP.CFrame = CFrame.new(currentPos:Lerp(targetPos, alpha)) * destCFrame.Rotation
                    end)
                    RunService.Heartbeat:Wait()
                end
                pcall(function() HRP.CFrame = destCFrame end)
            end
            mainPart.Velocity, mainPart.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
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
        if fireproximityprompt then
            local success = pcall(function() fireproximityprompt(prompt) end)
            if success then
                task.wait(0.5)
                if not prompt or not prompt.Parent or not prompt.Enabled then triggered = true; break end
            end
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
        local isAlreadyPolice = (LP.Team and LP.Team.Name == "Police")
        if not isAlreadyPolice then
            local JobEvents = ReplicatedStorage:WaitForChild("JobEvents", 10)
            local Event = JobEvents and JobEvents:WaitForChild("TeamChangeRequest", 10)
            if Event then Event:FireServer("Police", 0, 0, 1428858969, "Detector") task.wait(2) end
        end
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
                    if fireproximityprompt then
                        pcall(function() fireproximityprompt(TOMBOL) end)
                    else
                        pcall(function()
                            TOMBOL:InputHoldBegin()
                            task.wait(TOMBOL.HoldDuration + 0.1)
                            TOMBOL:InputHoldEnd()
                        end)
                    end
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
            HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(zonePart.Position.X, HRP.Position.Y, zonePart.Position.Z))
            local cam = Workspace.CurrentCamera
            if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, zonePart.Position) end
        end)
        task.wait(0.2)
        local remote = tool:FindFirstChild("PlaceConeEvent") or tool:FindFirstChildOfClass("RemoteEvent")
        if remote then pcall(function() remote:FireServer(targetPos, HRP.CFrame) end) end
        task.wait(0.3)
        pcall(function()
            local Event = ReplicatedStorage:WaitForChild("PoliceAssets", 10) and ReplicatedStorage.PoliceAssets:WaitForChild("PoliceEvent", 10)
            if Event and firesignal then firesignal(Event.OnClientEvent, "UpdateToolTip", "TrafficCone") end
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
            HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(zonePart.Position.X, HRP.Position.Y, zonePart.Position.Z))
            local cam = Workspace.CurrentCamera
            if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, zonePart.Position) end
        end)
        task.wait(0.2)
        local remote = tool:FindFirstChildOfClass("RemoteEvent")
        if remote then pcall(function() remote:FireServer(targetPos, HRP.CFrame) end) end
        task.wait(0.3)
        pcall(function()
            local Event = ReplicatedStorage:WaitForChild("PoliceAssets", 10) and ReplicatedStorage.PoliceAssets:WaitForChild("PoliceEvent", 10)
            if Event and firesignal then firesignal(Event.OnClientEvent, "UpdateToolTip", "PoliceLine") end
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
        
        local currentSuspectPos = suspectHRP.Position
        local suspectLook = suspectHRP.CFrame.LookVector
        local targetPos = currentSuspectPos + suspectLook * 2.5
        
        pcall(function()
            HRP.Velocity = Vector3.new(0, 0, 0)
            HRP.CFrame = CFrame.new(targetPos, currentSuspectPos)
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
        FileName = "AutofarmSettings"
    },
    Discord = {Enabled = false},
    KeySystem = false
})

local HomeTab = Window:CreateTab("Home", 4483362458)

HomeTab:CreateSection("Update Log")

HomeTab:CreateButton({
    Name = "Version 1.0",
    Callback = function()
        Rayfield:Notify({
            Title = "Projectsion",
            Content = "+ office autofarm yes yes",
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
            Rayfield:Notify({
                Title = "Projectsion",
                Content = "Courier Autofarm Enabled!",
                Duration = 3
            })
        end
    end
})

AutofarmTab:CreateSlider({
    Name = "Courier Speed",
    Range = {10, 550},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 300,
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
            task.spawn(function()
                ExecuteStartSequence()
            end)

            Rayfield:Notify({
                Title = "Projectsion",
                Content = "Barista Active!",
                Duration = 3
            })
        end
    end
})

AutofarmTab:CreateSlider({
    Name = "Barista Speed",
    Range = {10, 1500},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 1000,
    Flag = "BaristaSpeed",
    Callback = function(value)
        _G.BaristaSpeed = value
    end
})

AutofarmTab:CreateSection("Office Worker")

AutofarmTab:CreateToggle({
    Name = "Autofarm Office",
    CurrentValue = false,
    Flag = "OfficeFarmToggle",
    Callback = function(state)
        if state then
            startOfficeFarm()
            updateBlackScreen() 
            Rayfield:Notify({
                Title = "Projectsion",
                Content = "Office Autofarm Enabled!",
                Duration = 3
            })
        else
            stopOfficeFarm()
            updateBlackScreen() 
            Rayfield:Notify({
                Title = "Projectsion",
                Content = "Office Autofarm Disabled.",
                Duration = 3
            })
        end
    end
})

AutofarmTab:CreateSlider({
    Name = "Answer Delay Min",
    Range = {0, 10},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = 2.5,
    Flag = "OfficeDelayMin",
    Callback = function(value)
        answerDelayMin = value
    end
})

AutofarmTab:CreateSlider({
    Name = "Answer Delay Max",
    Range = {0, 10},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = 4.5,
    Flag = "OfficeDelayMax",
    Callback = function(value)
        answerDelayMax = value
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
lblOfficeEarned = StatsTab:CreateLabel("Office Worker: RP. 0")
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
    Content = "Loaded Successfully",
    Duration = 5
})

warn("[PROJECTSION] Engine Loaded & Waiting for Toggle...")

Rayfield:LoadConfiguration()
