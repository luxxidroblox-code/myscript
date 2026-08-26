local genv = getgenv()
local fenv = getfenv()

local function _crash() end

local function verifyFunction(func)
    if typeof(func) ~= "function" then _crash() end
    if islclosure and not islclosure(func) then _crash() end
    if iscclosure and iscclosure(func) then _crash() end
    return true
end

local targetUrl1 = 'https://raw.githubusercontent.com/luxxidroblox-code/myscript.lua/refs/heads/main/adonis.lua'
local targetUrl2 = 'https://sirius.menu/rayfield'

if #targetUrl1 ~= 77 or #targetUrl2 ~= 28 then _crash() end

loadstring(game:HttpGet(targetUrl1))()

pcall(function()
    local networkPause = game:GetService('CoreGui').RobloxGui:FindFirstChild('CoreScripts/NetworkPause')
    if networkPause then networkPause:Destroy() end
end)

local Rayfield = loadstring(game:HttpGet(targetUrl2))()

local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local LP                = Players.LocalPlayer
local RunService        = game:GetService("RunService")
local PlayerData        = LP:WaitForChild("PlayerData")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local TeleportService   = game:GetService("TeleportService")
local VIM               = game:GetService("VirtualInputManager")

local CourierSettings = require(ReplicatedStorage:WaitForChild("Delivery System"):WaitForChild("Settings"))
local MachinePrompt   = workspace.BaristaJob.Interactions.MachinePart.MachinePart.MachinePrompt
local RegisterPrompt  = workspace.BaristaJob.Interactions.RegisterPart.RegisterPart.RegisterPrompt
local SupplyPrompt    = workspace.BaristaJob.Interactions.SupplyPart.SupplyPart.SupplyPrompt
local JobPrompt       = workspace.BaristaJob.Interactions.StartPart.StartPart.JobPrompt

local SupplyCF        = CFrame.new(-5116.78418, 5.78931046, -670.858887)
local MachineCF       = CFrame.new(-4997.1665, 1.58353043, -795.047607)
local RegisterCF      = CFrame.new(-4994.06934, 1.30402756, -760.247437)
local StartJobCF      = CFrame.new(-4989.80078, 5.30382967, -715.013062)
local TAKE_BOX_CFRAME = CFrame.new(-5105.61182, 4.48948574, -3758.98267)
local TAKE_PROMPT     = workspace:WaitForChild("Livrason"):WaitForChild("Take1"):WaitForChild("Take"):WaitForChild("ProximityPrompt")

_G.AutofarmCourier      = false
_G.CourierSpeed         = 230
_G.AutoFarmBarista      = false
_G.BaristaSpeed         = 300
_G.AutoPoliceEnabled    = false
_G.blackscreen          = false
_G.PermanentBlackscreen = false
_G.RejoinTriggered      = false

_G.AutoWebhook  = false
_G.WebhookURL   = ""
_G.TotalEarning = 0
_G.CycleCount   = 0
LastActivity    = tick()

local lastMoney     = PlayerData.RPValue.Value
local pendingIncome = 0
local isRunning     = false
local cooldownTime  = 60
local WaktuKosong   = nil

_G.CourierEarned    = 0
_G.BaristaEarned    = 0
_G.PoliceEarned     = 0
_G.AutoDriveEarned  = 0

-- ─── Active-session timer ─────────────────────────────────────────────────────
local _activeSeconds = 0
local _farmTickStart = nil

local function _syncFarmTimer()
    local anyActive = _G.AutofarmCourier or _G.AutoFarmBarista or _G.AutoPoliceEnabled or _G.AutoDriveActive
    if anyActive and not _farmTickStart then
        _farmTickStart = tick()
    elseif not anyActive and _farmTickStart then
        _activeSeconds = _activeSeconds + (tick() - _farmTickStart)
        _farmTickStart = nil
    end
end

local function getActiveSeconds()
    if _farmTickStart then
        return _activeSeconds + (tick() - _farmTickStart)
    end
    return _activeSeconds
end

local function getRunningTime()
    local diff = math.floor(getActiveSeconds())
    return string.format("%02d:%02d:%02d",
        math.floor(diff / 3600),
        math.floor((diff % 3600) / 60),
        diff % 60)
end

local function formatRP(v)
    local s         = string.format("%.0f", v)
    local formatted = s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    return "RP. " .. formatted
end

local function formatNumber(n)
    local s = tostring(math.floor(n))
    return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function formatTime(t)
    return string.format("%02d:%02d:%02d", math.floor(t / 3600), math.floor(t / 60) % 60, t % 60)
end

local function formatPerHour(earned)
    local hrs = getActiveSeconds() / 3600
    if hrs < 0.001 then return "RP. 0/hr" end
    local perHr = math.floor(earned / hrs)
    local s     = string.format("%d", perHr)
    local fmt   = s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    return "RP. " .. fmt .. "/hr"
end

-- ─── Auto Drive constants ─────────────────────────────────────────────────────
local AD_MIN_SPEED      = 0
local AD_MAX_SPEED      = 400
local AD_CHECK_DISTANCE = 15
local AD_HUGE_PLATFORM  = 2000
local AD_MIN_THRESHOLD  = 500000
local AD_MAX_THRESHOLD  = 2000000
local AD_UNSEAT_TIMEOUT = 10
local AD_DIR_COOLDOWN   = 0.3
local AD_DRAG_CP_DELAY  = 3
local AD_DRAG_START_HOLD= 3
local AD_DRAG_LOOP_DELAY= 8

local adSpeed           = 200
local adThreshold       = 500000
local adVehicleInput    = "Yamahax-MioSporty"
local adActive          = false
local adCurrentVehicle  = nil
local adForce           = nil
local adGyro            = nil
local adAttach          = nil
local adDirection       = 1
local adSavedFloor      = nil
local adStartTime       = nil
local adStartMoney      = nil
local adLastDirChange   = 0
local adIsRespawning    = false
local adUnseatedSince   = nil
local adSeatOffset      = 1.5
local adBlackGui        = nil
local adDragEnabled     = true
local adDragRunning     = false
local adDragPassActive  = false
local adDragCount       = 0

_G.AutoDriveActive      = false

local AutoPoliceConfig = {
    TeleportSpeed    = {min = 200, max = 300},
    PostTeleportWait = {min = 2,   max = 4},
    WalkTimeout      = 10,
    TargetOffset     = 15,
    LoopDelay        = 1
}
local ActiveConnections = {}
local NeedJobRefresh, RequestingJob = false, false
local TeleportActive    = false
local missionsCompleted = 0
local AnchoredPartsList = {}
local ActiveMissions    = Workspace:WaitForChild("ActiveMissions", 10)

local function generateRandomName()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local length = math.random(12, 24)
    local result = ""
    for i = 1, length do
        local rand = math.random(1, #chars)
        result = result .. string.sub(chars, rand, rand)
    end
    return result
end

local function RejoinServer()
    local queue_teleport = queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)

    _G.AutofarmCourier   = false
    _G.AutoFarmBarista   = false
    _G.AutoPoliceEnabled = false
    _G.AutoDriveActive   = false
    adActive             = false
    _syncFarmTimer()

    Rayfield:Notify({
        Title    = "Projectsion",
        Content  = "Rejoining server safely...",
        Duration = 3
    })
    task.wait(5)

    if queue_teleport then
        queue_teleport([[
            if not game:IsLoaded() then game.Loaded:Wait() end

            local function waitRS(name, timeout)
                local rs       = game:GetService("ReplicatedStorage")
                local deadline = os.clock() + (timeout or 20)
                local child
                repeat
                    child = rs:FindFirstChild(name)
                    if not child then task.wait(0.5) end
                until child or os.clock() > deadline
                return child
            end

            task.wait(4)
            local ok = pcall(function()
                loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/luxxidroblox-code/myscript.lua/refs/heads/main/adonis.lua"
                ))()
            end)
            if not ok then warn("[PROJECTSION] adonis load failed") return end

            waitRS("Delivery System")
            waitRS("JobEvents")
            task.wait(2)

            pcall(function()
                loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/luxxidroblox-code/myscript.lua/refs/heads/main/doc.lua"
                ))()
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

-- ─── Courier 79m cap ─────────────────────────────────────────────────────────
task.spawn(function()
    task.wait(10)
    while task.wait(2) do
        if not _G.RejoinTriggered and _G.CourierEarned >= 79000000 then
            _G.RejoinTriggered = true
            Rayfield:Notify({
                Title    = "Target Reached",
                Content  = "Courier earned mencakup batas. Memulai Rejoin...",
                Duration = 5,
                Image    = 4483362458,
            })
            task.wait(1)
            RejoinServer()
            break
        end
    end
end)

local BlackScreen = Instance.new("ScreenGui")
local Frame       = Instance.new("Frame")

if gethui then
    BlackScreen.Parent = gethui()
else
    BlackScreen.Parent = game:GetService("CoreGui") or LP.PlayerGui
end

BlackScreen.Name         = generateRandomName()
Frame.Name               = generateRandomName()
BlackScreen.DisplayOrder = -1
BlackScreen.Enabled      = false

Frame.Parent           = BlackScreen
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.Size             = UDim2.new(1.5, 0, 1.5, 0)
Frame.Position         = UDim2.new(-0.25, 0, -0.25, 0)
Frame.BorderSizePixel  = 0

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
    local isAnyFarmActive = (_G.AutofarmCourier or _G.AutoFarmBarista or _G.AutoPoliceEnabled or _G.AutoDriveActive)
    _syncFarmTimer()
    if isAnyFarmActive then
        _G.blackscreen          = true
        _G.PermanentBlackscreen = true
    else
        _G.blackscreen = false
        if _G.PermanentBlackscreen then
            BlackScreen.Enabled = true
        end
        return
    end
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

local function Tween(targetCFrame, keepSit)
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum  = Char and Char:FindFirstChild("Humanoid")
    if not Root or not Hum then return end

    Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    Hum.Sit = true
    task.wait(0.25)

    local gyro        = Instance.new("BodyGyro")
    gyro.MaxTorque    = Vector3.new(1e6, 1e6, 1e6)
    gyro.P            = 1e5
    gyro.D            = 500
    gyro.CFrame       = targetCFrame
    gyro.Parent       = Root

    local distance = (Root.Position - targetCFrame.Position).Magnitude
    local duration = distance / _G.CourierSpeed

    Root.Velocity    = Vector3.new(0, 0, 0)
    Root.RotVelocity = Vector3.new(0, 0, 0)

    local info  = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(Root, info, {CFrame = targetCFrame})
    tween:Play()

    local conn = RunService.Stepped:Connect(function()
        if tween.PlaybackState == Enum.PlaybackState.Playing then
            Root.Velocity = Vector3.new(0, 0, 0)
            gyro.CFrame   = targetCFrame
        else
            conn:Disconnect()
        end
    end)

    tween.Completed:Wait()
    conn:Disconnect()
    Root.Velocity = Vector3.new(0, 0, 0)
    gyro:Destroy()

    if not keepSit then
        Hum.Sit = false
        Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        task.wait(0.15)
        Hum.Jump = true
        task.wait(0.1)
    end
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
        local block  = folder:FindFirstChild("Block")
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

local function getRunningTimeWall()
    if not _G._wallStart then return "00:00:00" end
    local diff = os.time() - _G._wallStart
    return string.format("%02d:%02d:%02d",
        math.floor(diff / 3600),
        math.floor((diff % 3600) / 60),
        diff % 60)
end

local function sendWebhook(income, target)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    _G.CycleCount = _G.CycleCount + 1

    local currentMoney = PlayerData.RPValue.Value
    local http_request  = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)

    local embed = {
        ["author"] = {
            ["name"]     = "Projectsion Webhook",
            ["icon_url"] = getAvatar()
        },
        ["title"] = "Cycle Completed",
        ["color"] = 0xFFFFFF,
        ["fields"] = {
            {["name"] = "Username",      ["value"] = LP.Name,                               ["inline"] = false},
            {["name"] = "Cycle Income",  ["value"] = formatRP(income),                      ["inline"] = false},
            {["name"] = "Target",        ["value"] = formatRP(target),                      ["inline"] = false},
            {["name"] = "Current Money", ["value"] = formatRP(currentMoney) .. " (Est)",    ["inline"] = false},
            {["name"] = "Total Earning", ["value"] = formatRP(_G.TotalEarning) .. " (Est)", ["inline"] = false},
            {["name"] = "Cycle Count",   ["value"] = tostring(_G.CycleCount),               ["inline"] = false},
            {["name"] = "Running Time",  ["value"] = getRunningTimeWall(),                  ["inline"] = false}
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
        ["embeds"]   = {embed}
    })

    if http_request then
        pcall(function()
            http_request({
                Url     = _G.WebhookURL,
                Method  = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body    = payload
            })
        end)
    end
end

-- ─── Stat label handles ───────────────────────────────────────────────────────
local lblTotalEarned, lblCurrentMoney, lblSessionTime
local lblCourierEarned, lblBaristaEarned, lblPoliceEarned, lblAutoDriveEarned
local lblTotalPerHour, lblCourierPerHour, lblBaristaPerHour, lblPolicePerHour, lblAutoDrivePerHour
local adLblStatus, adLblCurrent, adLblEarned, adLblElapsed, adLblDragRaces

local function refreshPerHourLabels()
    if lblTotalPerHour     then lblTotalPerHour:Set("Total /hr: "              .. formatPerHour(_G.TotalEarning))    end
    if lblCourierPerHour   then lblCourierPerHour:Set("Courier /hr: "          .. formatPerHour(_G.CourierEarned))   end
    if lblBaristaPerHour   then lblBaristaPerHour:Set("Barista /hr: "          .. formatPerHour(_G.BaristaEarned))   end
    if lblPolicePerHour    then lblPolicePerHour:Set("Police Department /hr: " .. formatPerHour(_G.PoliceEarned))    end
    if lblAutoDrivePerHour then lblAutoDrivePerHour:Set("Auto Drive /hr: "     .. formatPerHour(_G.AutoDriveEarned)) end
end

PlayerData.RPValue.Changed:Connect(function(newMoney)
    if newMoney > lastMoney then
        local gained = newMoney - lastMoney
        pendingIncome   = pendingIncome + gained
        _G.TotalEarning = _G.TotalEarning + gained

        if _G.AutofarmCourier then
            _G.CourierEarned    = _G.CourierEarned + gained
        elseif _G.AutoFarmBarista then
            _G.BaristaEarned    = _G.BaristaEarned + gained
        elseif _G.AutoPoliceEnabled then
            _G.PoliceEarned     = _G.PoliceEarned + gained
        elseif _G.AutoDriveActive then
            _G.AutoDriveEarned  = _G.AutoDriveEarned + gained
        end

        if lblTotalEarned     then lblTotalEarned:Set("Total Earned: "         .. formatRP(_G.TotalEarning))    end
        if lblCurrentMoney    then lblCurrentMoney:Set("Current Money: "       .. formatRP(newMoney))           end
        if lblCourierEarned   then lblCourierEarned:Set("Courier: "            .. formatRP(_G.CourierEarned))   end
        if lblBaristaEarned   then lblBaristaEarned:Set("Barista: "            .. formatRP(_G.BaristaEarned))   end
        if lblPoliceEarned    then lblPoliceEarned:Set("Police Department: "   .. formatRP(_G.PoliceEarned))    end
        if lblAutoDriveEarned then lblAutoDriveEarned:Set("Auto Drive: "       .. formatRP(_G.AutoDriveEarned)) end
        refreshPerHourLabels()

        if not isRunning then
            isRunning = true
            task.spawn(function()
                while isRunning do
                    task.wait(60)
                    if pendingIncome > 0 and _G.WebhookURL ~= "" then
                        sendWebhook(pendingIncome, 0)
                        pendingIncome = 0
                    end
                    if not _G.AutofarmCourier and not _G.AutoFarmBarista
                    and not _G.AutoPoliceEnabled and not _G.AutoDriveActive then
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
        local Minigame  = Gui:FindFirstChild("MinigameFrame")
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
    local Hum  = Char:WaitForChild("Humanoid")
    local Root = Char:WaitForChild("HumanoidRootPart")
    if Hum and Root then
        local distance = (Root.Position - targetCF.Position).Magnitude
        local duration = distance / _G.BaristaSpeed
        Hum.Sit = true
        task.wait(0.5)
        local info  = TweenInfo.new(duration, Enum.EasingStyle.Linear)
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
                local txt      = OrderTextLabel.Text:lower()
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

-- ─── Courier main loop ────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1)

        if _G.AutofarmCourier then
            SwitchToCourier()

            local Char = LP.Character or LP.CharacterAdded:Wait()
            local Hum  = Char:WaitForChild("Humanoid")
            local Root = Char:WaitForChild("HumanoidRootPart")

            if not (Hum and Root and Hum.Health > 0) then continue end

            local BoxTempatAmbil = workspace:FindFirstChild("Livrason")
                                   and workspace.Livrason:FindFirstChild("Take1")
            local TargetBlock, TargetPrompt = GetActivePoint()

            if not BoxTempatAmbil or (AutoEquipBox() and not TargetBlock) then
                task.wait(2)
                continue
            end

            if not AutoEquipBox() then
                if not WaktuKosong then WaktuKosong = os.clock() end

                if (os.clock() - WaktuKosong) >= 240 then
                    game:GetService("ReplicatedStorage")
                        :WaitForChild("JobEvents")
                        :WaitForChild("TeamChangeRequest")
                        :FireServer("Civilian", 0, 0, 0, "Detector")
                    WaktuKosong = nil
                    repeat task.wait(1)
                    until (LP.Team and LP.Team.Name == "Civilian") or not _G.AutofarmCourier
                    task.wait(15)
                    continue
                end

                Tween(TAKE_BOX_CFRAME, false)
                task.wait(0.4)
                if _G.AutofarmCourier and TAKE_PROMPT.Enabled then
                    fireproximityprompt(TAKE_PROMPT)
                    task.wait(1.5)
                end
            else
                WaktuKosong = nil

                if TargetBlock and TargetPrompt then
                    task.wait(math.random(0, 1))
                    Tween(TargetBlock.CFrame * CFrame.new(0, 2, 0), false)
                    task.wait(0.3)
                    AutoEquipBox()

                    if _G.AutofarmCourier and TargetPrompt.Enabled then
                        fireproximityprompt(TargetPrompt)
                        task.wait(0.5)
                        if Hum and _G.AutofarmCourier then
                            Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                            Hum.Sit = true
                        end
                        task.wait(3)
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
                return true
            end)
            table.insert(h, x)
        end
        if rawget(v, "Variables") and rawget(v, "Process") and typeof(b) == "function" and not y then
            y = b
            local o; o = hookfunction(y, function(f) end)
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
    local ui    = getPoliceUI()
    local label = ui and ui:FindFirstChild("LocationLabel", true)
    return label and label.Text
end

local function WaitUntilAssigned()
    while _G.AutoPoliceEnabled and GetLocationLabelText() == "Awaiting assignment..." do task.wait(0.5) end
end

local function GetObjectiveProgress()
    local ui    = getPoliceUI()
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
    local ui    = getPoliceUI()
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
    local Humanoid  = Character and Character:FindFirstChildOfClass("Humanoid")
    local HRP       = Character and Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HRP then return end
    TeleportActive = true
    pcall(function()
        local isDriving  = (Humanoid.SeatPart ~= nil and Humanoid.SeatPart:IsA("VehicleSeat"))
        local destCFrame = targetCFrame + (isDriving and Vector3.new(0, 10, 0) or Vector3.new(0, 1.5, 0))
        local mainPart, vehicle = HRP, nil

        if isDriving then
            local seat = Humanoid.SeatPart
            vehicle    = seat:FindFirstAncestorOfClass("Model")
            mainPart   = (vehicle and vehicle.PrimaryPart) or seat
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
        local targetPos  = destCFrame.Position
        local distance   = (targetPos - currentPos).Magnitude
        local speedConf  = AutoPoliceConfig.TeleportSpeed
        local speed      = math.random(speedConf.min, speedConf.max)
        local duration   = distance / speed

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
                local gyro        = Instance.new("BodyGyro")
                gyro.MaxTorque    = Vector3.new(1e6, 1e6, 1e6)
                gyro.P            = 1e5
                gyro.D            = 500
                gyro.CFrame       = destCFrame
                gyro.Parent       = HRP

                HRP.Anchored = false
                local startTime = os.clock()
                while os.clock() - startTime < duration do
                    if not _G.AutoPoliceEnabled then break end
                    local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
                    pcall(function()
                        HRP.Velocity, HRP.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
                        HRP.CFrame  = CFrame.new(currentPos:Lerp(targetPos, alpha)) * destCFrame.Rotation
                        gyro.CFrame = destCFrame
                    end)
                    RunService.Heartbeat:Wait()
                end
                pcall(function() HRP.CFrame = destCFrame end)
                gyro:Destroy()
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
    local Humanoid  = Character and Character:FindFirstChildOfClass("Humanoid")
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
    local HRP    = Character and Character:FindFirstChild("HumanoidRootPart")
    local target = targetPart or prompt.Parent
    for attempt = 1, 3 do
        if not _G.AutoPoliceEnabled then break end
        if not prompt or not prompt.Parent or not prompt.Enabled then return true end
        if HRP and target and target:IsA("BasePart") then
            pcall(function()
                HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(target.Position.X, HRP.Position.Y, target.Position.Z))
                local cam  = Workspace.CurrentCamera
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
    local ui        = getPoliceUI()
    local container = ui and ui:FindFirstChild("Container")
    if container and container.Visible then return end
    RequestingJob = true
    pcall(function()
        local isAlreadyPolice = (LP.Team and LP.Team.Name == "Police")
        if not isAlreadyPolice then
            local JobEvents = ReplicatedStorage:WaitForChild("JobEvents", 10)
            local Event     = JobEvents and JobEvents:WaitForChild("TeamChangeRequest", 10)
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
                local Start     = PoliceJob and PoliceJob:WaitForChild("Start", 10)
                local TOMBOL    = Start and Start:WaitForChild("ProximityPrompt", 10)
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
    return part.Position + Vector3.new(
        (math.random() - 0.5) * (size.X * 0.8),
        size.Y / 2,
        (math.random() - 0.5) * (size.Z * 0.8)
    )
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
    local HRP       = Character and Character:FindFirstChild("HumanoidRootPart")
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
            local cam  = Workspace.CurrentCamera
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
    local HRP       = Character and Character:FindFirstChild("HumanoidRootPart")
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
            local cam  = Workspace.CurrentCamera
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
    local ui    = getPoliceUI()
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
    local HRP       = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    local suspectHRP = suspect:FindFirstChild("HumanoidRootPart") or suspect.PrimaryPart or suspect:FindFirstChild("Head") or suspect:FindFirstChildOfClass("Part")
    EquipToolByName("Baton")
    local lastHitTime   = 0
    local lastEquipTime = 0

    while _G.AutoPoliceEnabled and missionModel.Parent and suspect.Parent do
        local curHP, maxHP = GetSuspectHP()
        Character = LP.Character
        HRP       = Character and Character:FindFirstChild("HumanoidRootPart")
        if not HRP then task.wait(0.5) continue end

        local tool = Character:FindFirstChild("Baton")
        if not tool then
            if os.clock() - lastEquipTime > 2 then EquipToolByName("Baton") lastEquipTime = os.clock() end
            tool = Character:FindFirstChild("Baton") or LP.Backpack:FindFirstChild("Baton")
        end

        local suspectPos  = suspectHRP.Position
        local suspectLook = suspectHRP.CFrame.LookVector
        local targetPos   = suspectPos + suspectLook * 2.5

        pcall(function()
            HRP.Velocity = Vector3.new(0, 0, 0)
            HRP.CFrame   = CFrame.new(targetPos, suspectPos)
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
        local Humanoid  = Character and Character:FindFirstChildOfClass("Humanoid")
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
            local Humanoid  = Character and Character:FindFirstChildOfClass("Humanoid")
            local HRP       = Character and Character:FindFirstChild("HumanoidRootPart")
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
                    local prompt     = GetPrompt(missionModel, targetPart)
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
                                local Humanoid  = Character and Character:FindFirstChildOfClass("Humanoid")
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

-- ─── Auto Drive logic ─────────────────────────────────────────────────────────
local function adSendKey(key)
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(0.1)
    VIM:SendKeyEvent(false, key, false, game)
end

local function adIsWheelPart(part)
    local name = part.Name:lower()
    return name:find("wheel") or name:find("tire") or name:find("tyre") or name:find("rim")
end

local function adGetPartLowestY(part)
    local cf, half = part.CFrame, part.Size * 0.5
    local lowest = math.huge
    for _, sx in ipairs({-1, 1}) do
        for _, sy in ipairs({-1, 1}) do
            for _, sz in ipairs({-1, 1}) do
                local p = cf * Vector3.new(half.X * sx, half.Y * sy, half.Z * sz)
                if p.Y < lowest then lowest = p.Y end
            end
        end
    end
    return lowest
end

local function adFindClosestSeat()
    local best, bestDist = nil, math.huge
    local char = LP.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    for _, obj in ipairs(workspace:GetChildren()) do
        local seat = obj:FindFirstChildWhichIsA("VehicleSeat", true)
        if seat then
            local dist = (seat.Position - root.Position).Magnitude
            if dist < bestDist then best, bestDist = seat, dist end
        end
    end
    return best
end

local function adGetVehicleRoot(seat)
    return seat.Parent or seat
end

local function adCalcSeatOffset(vehicle, seat)
    local lowestWheelY   = math.huge
    local lowestVehicleY = math.huge
    for _, part in ipairs(vehicle:GetDescendants()) do
        if part:IsA("BasePart") and part ~= seat then
            local bottom = adGetPartLowestY(part)
            if bottom < lowestVehicleY then lowestVehicleY = bottom end
            if adIsWheelPart(part) and bottom < lowestWheelY then lowestWheelY = bottom end
        end
    end
    local lowestY = lowestWheelY ~= math.huge and lowestWheelY or lowestVehicleY
    if lowestY ~= math.huge then
        return math.clamp(seat.Position.Y - lowestY, 1, 12)
    end
    return 1.5
end

local function adSetSeatCF(seat, targetCF)
    if adCurrentVehicle and adCurrentVehicle.Parent and adCurrentVehicle:IsA("Model")
    and seat:IsDescendantOf(adCurrentVehicle) then
        local rel = seat.CFrame:ToObjectSpace(adCurrentVehicle:GetPivot())
        adCurrentVehicle:PivotTo(targetCF * rel)
    else
        seat.CFrame = targetCF
    end
end

local function adSetupPhysics(seat)
    adAttach = Instance.new("Attachment", seat)
    adForce  = Instance.new("LinearVelocity", seat)
    adForce.MaxForce    = 99999999
    adForce.Attachment0 = adAttach
    adForce.RelativeTo  = Enum.ActuatorRelativeTo.Attachment0
    adGyro              = Instance.new("BodyGyro", seat)
    adGyro.MaxTorque    = Vector3.new(math.huge, math.huge, math.huge)
    adGyro.P            = 100000
    adGyro.D            = 1000
    adGyro.CFrame       = seat.CFrame
end

local function adCleanupPhysics()
    if adForce  then adForce:Destroy();  adForce  = nil end
    if adGyro   then adGyro:Destroy();   adGyro   = nil end
    if adAttach then adAttach:Destroy(); adAttach = nil end
end

local function adZeroVelocity()
    if adForce then adForce.VectorVelocity = Vector3.zero end
    if adCurrentVehicle and adCurrentVehicle.Parent then
        for _, part in ipairs(adCurrentVehicle:GetDescendants()) do
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity  = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
        if adCurrentVehicle:IsA("BasePart") then
            adCurrentVehicle.AssemblyLinearVelocity  = Vector3.zero
            adCurrentVehicle.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

local function adStopVehicle()
    adZeroVelocity()
    local stoppedSince = nil
    local started = os.clock()
    while adCurrentVehicle and adCurrentVehicle.Parent and os.clock() - started < 6 do
        adZeroVelocity()
        local maxSpeed = 0
        if adCurrentVehicle and adCurrentVehicle.Parent then
            for _, part in ipairs(adCurrentVehicle:GetDescendants()) do
                if part:IsA("BasePart") then
                    maxSpeed = math.max(maxSpeed, part.AssemblyLinearVelocity.Magnitude)
                end
            end
        end
        if maxSpeed <= 0.25 then
            stoppedSince = stoppedSince or os.clock()
            if os.clock() - stoppedSince >= 0.35 then break end
        else
            stoppedSince = nil
        end
        task.wait(0.05)
    end
end

local function adGroundRay(origin, distance)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.IgnoreWater = true
    local filter = {}
    if adCurrentVehicle then table.insert(filter, adCurrentVehicle) end
    if LP.Character then table.insert(filter, LP.Character) end
    params.FilterDescendantsInstances = filter
    return workspace:Raycast(origin, Vector3.new(0, -distance, 0), params)
end

local function adGetLowestWheel()
    if not adCurrentVehicle then return nil end
    local lowest = math.huge
    for _, part in ipairs(adCurrentVehicle:GetDescendants()) do
        if part:IsA("BasePart") and adIsWheelPart(part) then
            lowest = math.min(lowest, adGetPartLowestY(part))
        end
    end
    return lowest ~= math.huge and lowest or nil
end

local function adCorrectGrounding(seat, groundY)
    local lowestWheel = adGetLowestWheel()
    if not lowestWheel or not groundY then return seat.CFrame end
    local delta = math.clamp((groundY + 0.06) - lowestWheel, -6, 6)
    if math.abs(delta) > 0.04 then
        adSetSeatCF(seat, seat.CFrame + Vector3.new(0, delta, 0))
    end
    return seat.CFrame
end

local function adFireCarEvent(name, ...)
    local sf = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
    if sf then
        local r = sf:FindFirstChild(name)
        if r then r:FireServer(...) return true end
    end
    return false
end

-- ─── FIXED: spawn with retry until a VehicleSeat appears near the player ─────
local function adSpawnVehicle()
    -- despawn first to clear any stuck ghost vehicle
    adFireCarEvent("DespawnCar")
    task.wait(1)

    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    for attempt = 1, 5 do
        adFireCarEvent("SpawnCar", adVehicleInput)
        local deadline = os.clock() + 6
        while os.clock() < deadline do
            task.wait(0.4)
            if root then
                for _, obj in ipairs(workspace:GetChildren()) do
                    local seat = obj:FindFirstChildWhichIsA("VehicleSeat", true)
                    if seat and (seat.Position - root.Position).Magnitude < 60 then
                        return true   -- vehicle landed
                    end
                end
            end
        end
        if adLblStatus then adLblStatus:Set("Status: Spawn attempt " .. attempt .. "/5...") end
        adFireCarEvent("DespawnCar")
        task.wait(1.5)
    end
    return false
end

local function adDespawnVehicle() adFireCarEvent("DespawnCar") end
-- ─────────────────────────────────────────────────────────────────────────────

local function adGetCurrentSeat()
    if not adCurrentVehicle then return nil end
    if adCurrentVehicle:IsA("VehicleSeat") then return adCurrentVehicle end
    return adCurrentVehicle:FindFirstChildWhichIsA("VehicleSeat", true)
end

local function adFindDragRace()
    local drag = workspace:FindFirstChild("DragRace")
    if drag then return drag end
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Folder") or obj:IsA("Model") then
            drag = obj:FindFirstChild("DragRace") or obj:FindFirstChild("DragRace", true)
            if drag then return drag end
        end
    end
    return nil
end

local function adFindDragDetectors(dragRace)
    if not dragRace then return nil, nil, nil, nil, nil end
    local root    = dragRace:FindFirstChild("Detector") or dragRace:FindFirstChild("Detectors") or dragRace
    local startDet  = root:FindFirstChild("DetectorStart") or root:FindFirstChild("Start") or dragRace:FindFirstChild("DetectorStart")
    local c1        = root:FindFirstChild("DetectorC1")    or root:FindFirstChild("C1")    or dragRace:FindFirstChild("DetectorC1")
    local c2        = root:FindFirstChild("DetectorC2")    or root:FindFirstChild("C2")    or dragRace:FindFirstChild("DetectorC2")
    local c3        = root:FindFirstChild("DetectorC3")    or root:FindFirstChild("C3")    or dragRace:FindFirstChild("DetectorC3")
    local finishDet = root:FindFirstChild("DetectorFinish") or root:FindFirstChild("Finish") or dragRace:FindFirstChild("DetectorFinish")
    return startDet, c1, c2, c3, finishDet
end

local function adTouchDetector(detector, seatCF)
    if not detector or not seatCF then return false end
    pcall(function() detector.CFrame = seatCF end)
    task.wait(0.1)
    pcall(function() detector.CFrame = seatCF * CFrame.new(0, -100, 0) end)
    return true
end

local function adHoldStill(duration)
    local started = os.clock()
    repeat
        adZeroVelocity()
        task.wait(0.05)
    until os.clock() - started >= duration or not adDragEnabled or not adActive
end

local function adRunDragPass()
    if adDragPassActive or not adDragEnabled or not adActive then return end
    local seat = adGetCurrentSeat()
    if not seat then return end
    local dragRace = adFindDragRace()
    if not dragRace then
        if adLblStatus then adLblStatus:Set("Status: DragRace not found") end
        return
    end
    local startDet, c1, c2, c3, finishDet = adFindDragDetectors(dragRace)
    if not startDet or not finishDet then
        if adLblStatus then adLblStatus:Set("Status: detectors not found") end
        return
    end

    adDragPassActive = true
    adDragRunning    = true

    adHoldStill(0.5)
    local seatCF = seat.CFrame
    if adLblStatus then adLblStatus:Set("Status: Drag start") end
    adTouchDetector(startDet, seatCF)
    adHoldStill(AD_DRAG_START_HOLD)
    adDragRunning = false

    for i, checkpoint in ipairs({c1, c2, c3}) do
        if checkpoint and adDragEnabled and adActive then
            seatCF = seat.CFrame
            if adLblStatus then adLblStatus:Set("Status: Drag checkpoint " .. i) end
            adTouchDetector(checkpoint, seatCF)
            task.wait(AD_DRAG_CP_DELAY)
        end
    end

    if adDragEnabled and adActive then
        seatCF = seat.CFrame
        if adLblStatus then adLblStatus:Set("Status: Drag finish") end
        adTouchDetector(finishDet, seatCF)
        adDragCount = adDragCount + 1
        if adLblDragRaces then adLblDragRaces:Set("Drag Races: " .. adDragCount) end
    end

    if adActive and adLblStatus then adLblStatus:Set("Status: Farming!") end
    adDragRunning    = false
    adDragPassActive = false
end

local function adEnsureFloor(root)
    if adSavedFloor and adSavedFloor.Parent then return adSavedFloor end
    local origin = root and root.Position or Vector3.new(0, 8, 0)
    local floor  = Instance.new("Part")
    floor.Name          = "AD_FARM_FLOOR"
    floor.Size          = Vector3.new(AD_HUGE_PLATFORM, 4, AD_HUGE_PLATFORM)
    floor.CFrame        = CFrame.new(origin.X, origin.Y - 8, origin.Z)
    floor.Anchored      = true
    floor.CanCollide    = true
    floor.CanTouch      = true
    floor.Transparency  = 0
    floor.Material      = Enum.Material.SmoothPlastic
    floor.Color         = Color3.fromRGB(35, 35, 35)
    floor.Parent        = workspace
    adSavedFloor = floor
    return adSavedFloor
end

local function adCleanWorkspace()
    local char = LP.Character
    if not char then
        char = LP.CharacterAdded:Wait()
        task.wait(2)
    end
    local protectedDrag = adFindDragRace()
    if protectedDrag then pcall(function() protectedDrag.Parent = workspace end) end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then root = char:WaitForChild("HumanoidRootPart"); task.wait(2) end

    local searching = true
    while searching do
        local result = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0))
        if result and result.Instance then
            local part = result.Instance
            if part.Size.X >= AD_HUGE_PLATFORM or part.Name == "AD_FARM_FLOOR" then
                adSavedFloor      = part
                adSavedFloor.Name = "AD_FARM_FLOOR"
                adSavedFloor.Parent = workspace
                searching = false
            else
                part:Destroy()
                task.wait(0.02)
            end
        else
            searching = false
        end
    end
    adEnsureFloor(root)

    for _, obj in pairs(workspace:GetChildren()) do
        if obj ~= workspace.CurrentCamera and obj ~= char
        and obj ~= adSavedFloor and obj ~= protectedDrag
        and not obj:IsA("Terrain") then
            obj:Destroy()
        end
    end

    if adSavedFloor then
        local oldWalls = adSavedFloor:FindFirstChild("AD_WALLS")
        if oldWalls then oldWalls:Destroy() end

        local walls    = Instance.new("Folder")
        walls.Name     = "AD_WALLS"
        walls.Parent   = adSavedFloor
        local cf       = adSavedFloor.CFrame
        local hX       = adSavedFloor.Size.X / 2
        local hZ       = adSavedFloor.Size.Z / 2
        local wH       = 140
        local wT       = 10
        local specs = {
            {cf * CFrame.new( hX, wH/2, 0),  Vector3.new(wT, wH, adSavedFloor.Size.Z)},
            {cf * CFrame.new(-hX, wH/2, 0),  Vector3.new(wT, wH, adSavedFloor.Size.Z)},
            {cf * CFrame.new(0, wH/2,  hZ),  Vector3.new(adSavedFloor.Size.X, wH, wT)},
            {cf * CFrame.new(0, wH/2, -hZ),  Vector3.new(adSavedFloor.Size.X, wH, wT)},
        }
        for _, spec in ipairs(specs) do
            local wall           = Instance.new("Part")
            wall.Name            = "SafetyWall"
            wall.Anchored        = true
            wall.CanCollide      = true
            wall.Transparency    = 1
            wall.Size            = spec[2]
            wall.CFrame          = spec[1]
            wall.Parent          = walls
        end
    end
end

local function adSetBlackScreen(enabled)
    local playerGui = LP:WaitForChild("PlayerGui")
    if enabled then
        if adBlackGui and adBlackGui.Parent then return end
        adBlackGui                  = Instance.new("ScreenGui")
        adBlackGui.Name             = "AD_BlackScreen"
        adBlackGui.IgnoreGuiInset   = true
        adBlackGui.ResetOnSpawn     = false
        adBlackGui.DisplayOrder     = 999998
        adBlackGui.Parent           = playerGui
        local frame                 = Instance.new("Frame")
        frame.Size                  = UDim2.fromScale(1, 1)
        frame.BackgroundColor3      = Color3.new(0, 0, 0)
        frame.BorderSizePixel       = 0
        frame.ZIndex                = 999999
        frame.Parent                = adBlackGui
    elseif adBlackGui then
        adBlackGui:Destroy()
        adBlackGui = nil
    end
end

local function adRespawnVehicle(hum, statusText)
    if adIsRespawning then return end
    adIsRespawning  = true
    adActive        = false
    adUnseatedSince = nil
    if adLblStatus then adLblStatus:Set("Status: " .. (statusText or "Threshold reached, respawning...")) end
    adStopVehicle()
    adSendKey(Enum.KeyCode.Space)
    task.wait(0.5)
    adCleanupPhysics()
    adDespawnVehicle()
    task.wait(1.5)

    local spawned = adSpawnVehicle()
    if not spawned then
        if adLblStatus then adLblStatus:Set("Status: Spawn failed, retrying next cycle") end
        adIsRespawning = false
        return
    end

    local seat = adFindClosestSeat()
    if not seat then
        if adLblStatus then adLblStatus:Set("Status: No seat found!") end
        adIsRespawning = false
        return
    end
    local char = LP.Character or LP.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    root.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
    task.wait(1)
    seat:Sit(hum)
    task.wait(1)
    adCurrentVehicle = seat.Parent
    adSeatOffset     = adCalcSeatOffset(adCurrentVehicle, seat)
    adStartMoney     = PlayerData.RPValue.Value
    adStartTime      = os.time()
    adUnseatedSince  = nil
    adSetupPhysics(seat)
    adActive       = true
    adIsRespawning = false
    _G.AutoDriveActive = true
    if adLblStatus then adLblStatus:Set("Status: Farming!") end
end

local function adGetVehicleList()
    local out = {}
    pcall(function()
        local d    = ReplicatedStorage:FindFirstChild("DealershipEvents")
        local init = d and d:FindFirstChild("InitializeCarData")
        if not init or not init:IsA("RemoteFunction") then return end
        local ok, cfg = pcall(function() return init:InvokeServer() end)
        if ok and type(cfg) == "table" then
            for _, v in pairs(cfg) do
                if type(v) == "table" and v.Name then
                    out[#out + 1] = {id = v.Name, name = v.DisplayName or v.Name}
                end
            end
        end
    end)
    if #out > 0 then
        table.sort(out, function(a, b) return a.name < b.name end)
        return out
    end
    return {{id = "Yamahax-MioSporty", name = "Yamahax - Mio Sporty (2006)"}}
end

local function adStartFarming()
    if adActive then return end
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hum  = char:WaitForChild("Humanoid")
    local root = char:WaitForChild("HumanoidRootPart")

    if adLblStatus then adLblStatus:Set("Status: Cleaning workspace...") end
    adCleanWorkspace()

    if adLblStatus then adLblStatus:Set("Status: Spawning vehicle...") end
    local spawned = adSpawnVehicle()
    if not spawned then
        if adLblStatus then adLblStatus:Set("Status: Vehicle spawn failed!") end
        return false
    end

    if adLblStatus then adLblStatus:Set("Status: Finding seat...") end
    local seat, attempts = nil, 0
    repeat task.wait(0.5); attempts = attempts + 1; seat = adFindClosestSeat()
    until seat or attempts > 10

    if not seat then
        if adLblStatus then adLblStatus:Set("Status: No seat found!") end
        return false
    end

    if adLblStatus then adLblStatus:Set("Status: Sitting...") end
    root.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
    task.wait(0.5)
    seat:Sit(hum)
    task.wait(1)

    if hum.SeatPart ~= seat then
        if adLblStatus then adLblStatus:Set("Status: Failed to sit!") end
        return false
    end

    adCurrentVehicle   = seat.Parent
    adSeatOffset       = adCalcSeatOffset(adCurrentVehicle, seat)
    adStartMoney       = PlayerData.RPValue.Value
    adStartTime        = os.time()
    adUnseatedSince    = nil
    adActive           = true
    _G.AutoDriveActive = true
    updateBlackScreen()
    adSetupPhysics(seat)

    if adLblStatus then adLblStatus:Set("Status: Farming!") end

    task.spawn(function()
        while adActive do
            task.wait(1)
            if adActive and not adIsRespawning and adStartMoney then
                local earned = math.max(0, PlayerData.RPValue.Value - adStartMoney)
                if earned >= adThreshold then
                    local hum2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                    if hum2 then adRespawnVehicle(hum2) end
                end
            end
        end
    end)

    return true
end

local function adStopFarming()
    if not adActive then return end
    adActive           = false
    _G.AutoDriveActive = false
    adDragRunning      = false
    adCleanupPhysics()
    adDespawnVehicle()
    adStartTime  = nil
    adStartMoney = nil
    updateBlackScreen()
    if adLblStatus then adLblStatus:Set("Status: Stopped") end
end

-- ─── Unseated watchdog ────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1)
        if not adActive or adIsRespawning then
            adUnseatedSince = nil
            continue
        end
        local char         = LP.Character
        local hum          = char and char:FindFirstChildOfClass("Humanoid")
        local expectedSeat = adCurrentVehicle and (adCurrentVehicle:IsA("VehicleSeat") and adCurrentVehicle or adCurrentVehicle:FindFirstChildWhichIsA("VehicleSeat", true))
        if hum and hum.SeatPart and (not expectedSeat or hum.SeatPart == expectedSeat) then
            adUnseatedSince = nil
            continue
        end
        adUnseatedSince = adUnseatedSince or os.clock()
        if os.clock() - adUnseatedSince >= AD_UNSEAT_TIMEOUT then
            adUnseatedSince = nil
            if adLblStatus then adLblStatus:Set("Status: Not seated 10s, respawning...") end
            if hum then
                adRespawnVehicle(hum, "Not seated 10s, respawning...")
            else
                adActive = false
                _G.AutoDriveActive = false
                adCleanupPhysics()
                adDespawnVehicle()
                task.wait(1)
                adStartFarming()
            end
        end
    end
end)

-- ─── Drag bridge loop ─────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(AD_DRAG_LOOP_DELAY)
        if adDragEnabled and adActive and not adIsRespawning and adCurrentVehicle then
            adRunDragPass()
        end
    end
end)

-- ─── Character respawn reconnect ──────────────────────────────────────────────
LP.CharacterAdded:Connect(function()
    if not adActive then return end
    adActive           = false
    _G.AutoDriveActive = false
    adIsRespawning     = false
    adCleanupPhysics()
    task.wait(2)
    if adLblStatus then adLblStatus:Set("Status: Respawned, restarting...") end
    adStartFarming()
end)

-- ─── UI ──────────────────────────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name            = "Projectsion",
    LoadingTitle    = "Projectsion",
    LoadingSubtitle = "by laksid",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "ProjectsionConfig",
        FileName   = "AutofarmSettings"
    },
    Discord   = {Enabled = false},
    KeySystem = false
})

local HomeTab = Window:CreateTab("Home", 4483362458)

HomeTab:CreateSection("Update Log")

HomeTab:CreateButton({
    Name = "Version 1.2",
    Callback = function()
        Rayfield:Notify({
            Title    = "Projectsion",
            Content  = "+ Auto Drive tab added\n+ /hr stats added\n+ session timer active-only",
            Duration = 5
        })
    end
})

HomeTab:CreateButton({
    Name     = "Rejoin Server",
    Callback = function() RejoinServer() end
})

-- ─── Autofarm tab ─────────────────────────────────────────────────────────────
local AutofarmTab = Window:CreateTab("Autofarm", 4483362458)

AutofarmTab:CreateSection("Courier")

AutofarmTab:CreateToggle({
    Name         = "Autofarm Courier",
    CurrentValue = false,
    Flag         = "CourierFarm",
    Callback     = function(state)
        _G.AutofarmCourier = state
        updateBlackScreen()
        if state then
            Rayfield:Notify({Title = "Projectsion", Content = "Courier Autofarm Enabled!", Duration = 3})
        end
    end
})

AutofarmTab:CreateSlider({
    Name         = "Courier Speed",
    Range        = {10, 550},
    Increment    = 1,
    Suffix       = "Speed",
    CurrentValue = 230,
    Flag         = "CourierSpeed",
    Callback     = function(value) _G.CourierSpeed = value end
})

AutofarmTab:CreateSection("Barista")

AutofarmTab:CreateToggle({
    Name         = "Autofarm Barista",
    CurrentValue = false,
    Flag         = "BaristaFarm",
    Callback     = function(state)
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
    Name         = "Barista Speed",
    Range        = {10, 1500},
    Increment    = 1,
    Suffix       = "Speed",
    CurrentValue = 300,
    Flag         = "BaristaSpeed",
    Callback     = function(value) _G.BaristaSpeed = value end
})

AutofarmTab:CreateSection("Police Department")

AutofarmTab:CreateToggle({
    Name         = "Autofarm Police",
    CurrentValue = false,
    Flag         = "PoliceFarmToggle",
    Callback     = function(state)
        _G.AutoPoliceEnabled = state
        updateBlackScreen()
        if state then
            Rayfield:Notify({Title = "Projectsion", Content = "Auto Police Department Enabled.",  Duration = 3})
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
    Name         = "Min PostTeleport Wait (s)",
    Range        = {0, 10},
    Increment    = 0.5,
    Suffix       = "s",
    CurrentValue = 2,
    Flag         = "PoliceMinWait",
    Callback     = function(value) AutoPoliceConfig.PostTeleportWait.min = value end
})

AutofarmTab:CreateSlider({
    Name         = "Max PostTeleport Wait (s)",
    Range        = {0, 10},
    Increment    = 0.5,
    Suffix       = "s",
    CurrentValue = 4,
    Flag         = "PoliceMaxWait",
    Callback     = function(value) AutoPoliceConfig.PostTeleportWait.max = value end
})

AutofarmTab:CreateSlider({
    Name         = "Police Teleport Speed Max",
    Range        = {100, 500},
    Increment    = 10,
    Suffix       = " km/h",
    CurrentValue = 300,
    Flag         = "PoliceMaxSpeed",
    Callback     = function(value) AutoPoliceConfig.TeleportSpeed.max = value end
})

-- ─── Stats tab ────────────────────────────────────────────────────────────────
local StatsTab = Window:CreateTab("Stats", "trending-up")

StatsTab:CreateSection("Session Stats")
lblTotalEarned  = StatsTab:CreateLabel("Total Earned: RP. 0")
lblCurrentMoney = StatsTab:CreateLabel("Current Money: " .. formatRP(PlayerData.RPValue.Value))
lblSessionTime  = StatsTab:CreateLabel("Session Time: 00:00:00  (active only)")
lblTotalPerHour = StatsTab:CreateLabel("Total /hr: RP. 0/hr")

StatsTab:CreateSection("Job Income")
lblCourierEarned   = StatsTab:CreateLabel("Courier: RP. 0")
lblCourierPerHour  = StatsTab:CreateLabel("Courier /hr: RP. 0/hr")

lblBaristaEarned   = StatsTab:CreateLabel("Barista: RP. 0")
lblBaristaPerHour  = StatsTab:CreateLabel("Barista /hr: RP. 0/hr")

lblPoliceEarned    = StatsTab:CreateLabel("Police Department: RP. 0")
lblPolicePerHour   = StatsTab:CreateLabel("Police Department /hr: RP. 0/hr")

lblAutoDriveEarned  = StatsTab:CreateLabel("Auto Drive: RP. 0")
lblAutoDrivePerHour = StatsTab:CreateLabel("Auto Drive /hr: RP. 0/hr")

-- ─── Auto Drive tab ───────────────────────────────────────────────────────────
local AutoDriveTab = Window:CreateTab("Auto Drive", 4483362458)

AutoDriveTab:CreateSection("Config")

local adVehicleList   = adGetVehicleList()
local adVehicleNames  = {}
local adVehicleById   = {}
local adDefaultName   = adVehicleInput

for _, v in ipairs(adVehicleList) do
    table.insert(adVehicleNames, v.name)
    adVehicleById[v.name] = v.id
    if v.id == adVehicleInput then adDefaultName = v.name end
end

AutoDriveTab:CreateDropdown({
    Name          = "Vehicle",
    Options       = adVehicleNames,
    CurrentOption = {adDefaultName},
    Flag          = "ADVehicle",
    Callback      = function(option)
        adVehicleInput = adVehicleById[option] or adVehicleInput
    end
})

AutoDriveTab:CreateSlider({
    Name         = "Drive Speed",
    Range        = {AD_MIN_SPEED, AD_MAX_SPEED},
    Increment    = 10,
    Suffix       = "",
    CurrentValue = adSpeed,
    Flag         = "ADSpeed",
    Callback     = function(value) adSpeed = value end
})

AutoDriveTab:CreateSlider({
    Name         = "Money Target (per cycle)",
    Range        = {AD_MIN_THRESHOLD, AD_MAX_THRESHOLD},
    Increment    = 50000,
    Suffix       = "",
    CurrentValue = adThreshold,
    Flag         = "ADThreshold",
    Callback     = function(value) adThreshold = value end
})

AutoDriveTab:CreateToggle({
    Name         = "Auto Drag Bridge",
    CurrentValue = true,
    Flag         = "ADDragBridge",
    Callback     = function(state) adDragEnabled = state end
})

AutoDriveTab:CreateToggle({
    Name         = "Black Screen",
    CurrentValue = false,
    Flag         = "ADBlackScreen",
    Callback     = function(state) adSetBlackScreen(state) end
})

AutoDriveTab:CreateToggle({
    Name         = "Enable Auto Drive",
    CurrentValue = false,
    Flag         = "ADEnabled",
    Callback     = function(state)
        if state then
            Rayfield:Notify({Title = "Projectsion", Content = "Auto Drive starting...", Duration = 3})
            task.spawn(function()
                if not adStartFarming() then
                    Rayfield:Notify({Title = "Projectsion", Content = "Auto Drive failed to start.", Duration = 4})
                end
            end)
        else
            adStopFarming()
            Rayfield:Notify({Title = "Projectsion", Content = "Auto Drive stopped.", Duration = 3})
        end
    end
})

AutoDriveTab:CreateSection("Stats")
adLblStatus    = AutoDriveTab:CreateLabel("Status: Idle")
adLblCurrent   = AutoDriveTab:CreateLabel("Current Money: RP. 0")
adLblEarned    = AutoDriveTab:CreateLabel("Earned This Cycle: RP. 0")
adLblElapsed   = AutoDriveTab:CreateLabel("Elapsed: 00:00:00")
adLblDragRaces = AutoDriveTab:CreateLabel("Drag Races: 0")

-- ─── Webhook tab ──────────────────────────────────────────────────────────────
local WebhookTab = Window:CreateTab("Webhook", 4483362458)

WebhookTab:CreateSection("Webhook Configuration")

WebhookTab:CreateInput({
    Name                     = "Discord Webhook URL",
    PlaceholderText          = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Flag                     = "WebhookURL",
    Callback                 = function(text) _G.WebhookURL = text end
})

WebhookTab:CreateToggle({
    Name         = "Enable Webhook Logs",
    CurrentValue = false,
    Flag         = "WebhookEnabled",
    Callback     = function(state) _G.AutoWebhook = state end
})

-- ─── Stats ticker ─────────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1)
        local anyActive = _G.AutofarmCourier or _G.AutoFarmBarista or _G.AutoPoliceEnabled or _G.AutoDriveActive
        if lblSessionTime then
            lblSessionTime:Set("Session Time: " .. getRunningTime() .. (anyActive and "  (active)" or "  (paused)"))
        end
        if anyActive then refreshPerHourLabels() end

        if adActive and adStartTime and adStartMoney then
            local money   = PlayerData.RPValue.Value
            local earned  = math.max(0, money - adStartMoney)
            local elapsed = os.time() - adStartTime
            if adLblCurrent   then adLblCurrent:Set("Current Money: "       .. formatRP(money))       end
            if adLblEarned    then adLblEarned:Set("Earned This Cycle: "    .. formatRP(earned))       end
            if adLblElapsed   then adLblElapsed:Set("Elapsed: "             .. formatTime(elapsed))    end
        end
    end
end)

-- ─── Auto Drive Heartbeat ─────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not adActive or not adForce or not adCurrentVehicle then return end

    local seat = adGetCurrentSeat()
    if not seat then return end

    if not adSavedFloor or not adSavedFloor.Parent then
        adEnsureFloor(seat)
    end

    if adDragRunning then
        adZeroVelocity()
        return
    end

    if adStartMoney and math.max(0, PlayerData.RPValue.Value - adStartMoney) >= adThreshold and not adIsRespawning then
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then adRespawnVehicle(hum) end
        return
    end

    local groundRay = adGroundRay(seat.Position, math.max(25, adSeatOffset + 8))
    if not groundRay then
        if adLblStatus then adLblStatus:Set("Status: In air, respawning...") end
        adActive           = false
        _G.AutoDriveActive = false
        adCleanupPhysics()
        adDespawnVehicle()
        for retry = 1, 5 do
            task.wait(1)
            local spawned = adSpawnVehicle()
            if spawned then
                local newSeat = adFindClosestSeat()
                if newSeat then
                    local char = LP.Character
                    if char then
                        local hum2 = char:FindFirstChildOfClass("Humanoid")
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if hum2 and root then
                            root.CFrame      = newSeat.CFrame * CFrame.new(0, 2, 0)
                            task.wait(0.5)
                            newSeat:Sit(hum2)
                            task.wait(1)
                            adCurrentVehicle   = newSeat.Parent
                            adSeatOffset       = adCalcSeatOffset(adCurrentVehicle, newSeat)
                            adStartMoney       = PlayerData.RPValue.Value
                            adStartTime        = os.time()
                            adSetupPhysics(newSeat)
                            adActive           = true
                            _G.AutoDriveActive = true
                            if adLblStatus then adLblStatus:Set("Status: Farming!") end
                            return
                        end
                    end
                end
            end
            if adLblStatus then adLblStatus:Set("Status: Retry " .. retry .. "/5...") end
        end
        if adLblStatus then adLblStatus:Set("Status: Failed, toggle to restart") end
        return
    end

    local p = seat.Position
    if adSavedFloor then
        local localPos = adSavedFloor.CFrame:PointToObjectSpace(p)
        local limX     = adSavedFloor.Size.X / 2 - 80
        local limZ     = adSavedFloor.Size.Z / 2 - 80
        local cX       = math.clamp(localPos.X, -limX, limX)
        local cZ       = math.clamp(localPos.Z, -limZ, limZ)
        if math.abs(cX - localPos.X) > 0.1 or math.abs(cZ - localPos.Z) > 0.1 then
            adDirection     = adDirection * -1
            adLastDirChange = tick()
            local cWorld = adSavedFloor.CFrame:PointToWorldSpace(Vector3.new(cX, localPos.Y, cZ))
            local _, yaw = seat.CFrame:ToEulerAnglesYXZ()
            adSetSeatCF(seat, CFrame.new(cWorld.X, p.Y, cWorld.Z) * CFrame.Angles(0, yaw, 0))
            p = seat.Position
            adZeroVelocity()
        end
    end

    local _, ry        = seat.CFrame:ToEulerAnglesYXZ()
    local targetCF     = CFrame.new(p.X, groundRay.Position.Y + adSeatOffset, p.Z) * CFrame.Angles(0, ry, 0)
    adSetSeatCF(seat, targetCF)
    targetCF = adCorrectGrounding(seat, groundRay.Position.Y)
    if adGyro then adGyro.CFrame = targetCF end

    local rayOrigin = (seat.CFrame * CFrame.new(0, 0, -AD_CHECK_DISTANCE * adDirection)).p
    local hit       = adGroundRay(rayOrigin, 30)
    if not hit then
        local now = tick()
        if now - adLastDirChange >= AD_DIR_COOLDOWN then
            adDirection     = adDirection * -1
            adLastDirChange = now
            for _, part in ipairs(adCurrentVehicle:GetDescendants()) do
                if part:IsA("BasePart") then part.AssemblyLinearVelocity = Vector3.zero end
            end
            if seat:IsA("BasePart") then seat.AssemblyLinearVelocity = Vector3.zero end
        end
    end

    local spd = math.clamp(adSpeed, AD_MIN_SPEED, AD_MAX_SPEED)
    adForce.VectorVelocity = Vector3.new(0, 0, -spd * adDirection)
    local desiredWorld = -seat.CFrame.LookVector * spd * adDirection
    local vertical     = math.clamp(seat.AssemblyLinearVelocity.Y, -2, 2)
    seat.AssemblyLinearVelocity = Vector3.new(desiredWorld.X, vertical, desiredWorld.Z)
end)

Rayfield:Notify({
    Title    = "Projectsion",
    Content  = "Loaded Successfully",
    Duration = 5
})

warn("[PROJECTSION] Engine Loaded & Waiting for Toggle...")

Rayfield:LoadConfiguration()