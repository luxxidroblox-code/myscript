warn("sebelum loadstring")
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/X5Dermaster/RayField-Loader/refs/heads/main/rayfieldloader.lua'))()

local DelayLabel, TeleportLabel, DestMinLabel, Dest5MinLabel
local IncomeHourLabel, EarnedLabel, CurrentLabel, FpsLabel
local SessionTimeLabel, SessionEarnedLabel, SessionIPHLabel
local CycleEarnedLabel, LastDestLabel

pcall(function()
    local p = workspace.Map.Prop:GetChildren()[1627]
    if p then p:Destroy() end
end)

local BlackScreen = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
BlackScreen.Name = "ProjectsionBlackout"
BlackScreen.Parent = game:GetService("CoreGui")
BlackScreen.DisplayOrder = -1
BlackScreen.Enabled = false
Frame.Parent = BlackScreen
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.Size = UDim2.new(1.5, 0, 1.5, 0)
Frame.Position = UDim2.new(-0.25, 0, -0.25, 0)
Frame.BorderSizePixel = 0

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local lp                = Players.LocalPlayer

_G.Autofarm           = false
_G.AutoWebhook        = false
_G.DeleteMap          = false
_G.WebhookURL         = _G.WebhookURL or ""
_G.StartTime          = _G.StartTime or os.time()
_G.CycleCount         = _G.CycleCount or 0
_G.TotalEarning       = _G.TotalEarning or 0
_G.TotalTeleportCount = _G.TotalTeleportCount or 0

-- durasi tween = durasi countdown, nyampe bareng
local TP_TWEEN_DURATION = 39

local MoneyPath = lp.PlayerGui
    :WaitForChild("Main"):WaitForChild("Container"):WaitForChild("Hub")
    :WaitForChild("CashFrame"):WaitForChild("Frame"):WaitForChild("TextLabel")

local StartMoney            = 0
local EarnedMoney           = 0
local NextTeleportIn        = 0
local SessionStart          = nil
local SessionMoneyStart     = 0
local incomeLog             = {}
local lastMoney             = 0
local pendingIncome         = 0
local isRunning             = false
local destinationTimestamps = {}
local activePlatforms       = {}
local mapDeleted            = false
local lastDestEarned        = 0
local lastDestName          = "—"
local cycleMoneySnapshot    = 0

-- ─── UTILS ───────────────────────────────────────────────────────────────────

local function uprightCF(cf, yOffset)
    yOffset = yOffset or 0
    local pos = cf.Position + Vector3.new(0, yOffset, 0)
    local yaw = math.atan2(cf.LookVector.X, cf.LookVector.Z)
    return CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
end

local function buildPlatform(position, sizeX, sizeZ, yOffset)
    sizeX = sizeX or 350; sizeZ = sizeZ or 350; yOffset = yOffset or 4
    local p = Instance.new("Part")
    p.Name = "FarmPlatform"
    p.Size = Vector3.new(sizeX, 8, sizeZ)
    p.CFrame = CFrame.new(position.X, position.Y - yOffset, position.Z)
    p.Anchored = true; p.CanCollide = true; p.CastShadow = false
    p.Material = Enum.Material.SmoothPlastic
    p.BrickColor = BrickColor.new("Dark grey")
    p.Parent = Workspace
    table.insert(activePlatforms, p)
    return p
end

local function clearPlatforms()
    for _, p in ipairs(activePlatforms) do
        if p and p.Parent then p:Destroy() end
    end
    activePlatforms = {}
end

local function rebuildPlatforms()
    clearPlatforms()
    local etc = Workspace:FindFirstChild("Etc")
    if not etc then return end
    local waypointFolder = etc:FindFirstChild("Waypoint")
    if waypointFolder then
        for _, wp in ipairs(waypointFolder:GetChildren()) do
            local pos = (wp:IsA("Model") and wp:GetPivot().Position)
                     or (wp:IsA("BasePart") and wp.Position)
            if pos then buildPlatform(pos, 400, 400, 25) end
        end
    end
    local starter = etc:FindFirstChild("Job")
        and etc.Job:FindFirstChild("Truck")
        and etc.Job.Truck:FindFirstChild("Starter")
    if starter then buildPlatform(starter:GetPivot().Position, 200, 200) end
    local spawnerPart = etc:FindFirstChild("Job")
        and etc.Job:FindFirstChild("Truck")
        and etc.Job.Truck:FindFirstChild("Spawner")
        and etc.Job.Truck.Spawner:FindFirstChild("Part")
    if spawnerPart then buildPlatform(spawnerPart.Position - Vector3.new(0, 6, 0), 1000, 1000) end
end

local function deleteMap()
    if mapDeleted then return end
    mapDeleted = true
    rebuildPlatforms()
    local map = Workspace:FindFirstChild("Map")
    if map then
        for _, child in ipairs(map:GetChildren()) do
            pcall(function() child:Destroy() end)
        end
    end
    pcall(function() Workspace.Terrain:Clear() end)
end

local STAFF_GROUP_ID = 10884667
local function isStaff(player)
    local ok, result = pcall(function() return player:IsInGroup(STAFF_GROUP_ID) end)
    return ok and result
end
local function selfKick(player)
    local tag = isStaff(player) and "STAFF" or "PLAYER"
    lp:Kick(tag .. " DETECTED (" .. player.Name .. ")")
end
Players.PlayerAdded:Connect(function(player)
    if player == lp then return end
    task.wait(0.5); selfKick(player)
end)
task.spawn(function()
    while true do
        task.wait(3)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp then selfKick(player); return end
        end
    end
end)

local function getCleanMoney()
    local raw = MoneyPath.Text:gsub("RP.", ""):gsub(",", ""):gsub("%s+", "")
    return tonumber(raw) or 0
end

local function formatShort(n)
    if n >= 1000000 then return string.format("%.1fM/h", n/1000000):gsub("%.0M","M")
    elseif n >= 1000 then return string.format("%.1fK/h", n/1000):gsub("%.0K","K")
    else return tostring(n).."/h" end
end

local function formatNominal(n)
    local left, num, right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
    if not left then return tostring(n) end
    return left..(num:reverse():gsub('(%d%d%d)', '%1,'):reverse())..right
end

local function formatRP(v)
    local s = string.format("%.0f", v)
    return "RP. "..s:reverse():gsub("(%d%d%d)","%1."):reverse():gsub("^%.","")
end

local function formatDuration(sec)
    sec = math.max(0, math.floor(sec))
    local h = math.floor(sec/3600)
    local m = math.floor((sec%3600)/60)
    local s = sec%60
    if h > 0 then return string.format("%dh %02dm %02ds", h, m, s)
    else return string.format("%dm %02ds", m, s) end
end

local function getRunningTime()
    local diff = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d",
        math.floor(diff/3600), math.floor((diff%3600)/60), diff%60)
end

local function logIncome(amount)
    table.insert(incomeLog, {t = os.time(), amount = amount})
end

local function getIncomePerHour()
    local now = os.time(); local total = 0
    for i = #incomeLog, 1, -1 do
        if now - incomeLog[i].t <= 600 then total = total + incomeLog[i].amount
        else table.remove(incomeLog, i) end
    end
    if total == 0 then return 0 end
    local elapsed = math.min(now - _G.StartTime, 600)
    if elapsed < 20 then return 0 end
    return math.floor((total/elapsed)*3600)
end

local function getSessionIPH()
    if not SessionStart then return 0 end
    local elapsed = os.time() - SessionStart
    if elapsed < 20 then return 0 end
    return math.floor((math.max(0, getCleanMoney() - SessionMoneyStart)/elapsed)*3600)
end

local _currentFPS = 60
task.spawn(function()
    while true do
        local t = tick()
        RunService.Heartbeat:Wait()
        _currentFPS = math.clamp(1/math.max(tick()-t, 0.001), 1, 144)
        task.wait(0.5)
    end
end)
local function getFPS() return _currentFPS end

-- ─── TWEEN TELEPORT (DEJP STYLE) ─────────────────────────────────────────────
-- Mulai dari detik 0, truck lerp heartbeat selama TP_TWEEN_DURATION detik
-- pas timer countdown habis = truck udah tepat di destinasi
local function tweenTruckToDestination(truck, targetCF, duration, onTick)
    if not truck or not truck.Parent then return end

    local origin  = truck:GetPivot()
    local elapsed = 0
    local done    = false
    local conn

    -- pakai CFrameValue + tween biar smooth & engine-driven
    local cfVal = Instance.new("CFrameValue")
    cfVal.Value = origin

    cfVal.Changed:Connect(function(v)
        if truck and truck.Parent then
            truck:PivotTo(v)
            -- nol-in velocity biar ga kelempar fisika
            local pp = truck.PrimaryPart
            if pp then
                pp.AssemblyLinearVelocity  = Vector3.zero
                pp.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)

    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        0, false, 0
    )
    local tween = TweenService:Create(cfVal, tweenInfo, {Value = targetCF})
    tween:Play()

    -- countdown parallel di heartbeat
    conn = RunService.Heartbeat:Connect(function(dt)
        if not _G.Autofarm or not truck or not truck.Parent then
            tween:Cancel()
            conn:Disconnect()
            cfVal:Destroy()
            done = true
            return
        end
        elapsed = elapsed + dt
        local remaining = math.max(0, duration - elapsed)
        NextTeleportIn = math.ceil(remaining)
        if onTick then onTick(remaining) end
        if elapsed >= duration then
            conn:Disconnect()
            cfVal:Destroy()
            truck:PivotTo(targetCF) -- snap final
            done = true
        end
    end)

    -- block sampai tween selesai
    tween.Completed:Wait()
    pcall(function() conn:Disconnect() end)
    pcall(function() cfVal:Destroy() end)
    truck:PivotTo(targetCF)
end

local function logDestinationComplete()
    table.insert(destinationTimestamps, os.time())
end

local function getDestinationsInWindow(seconds)
    local now = os.time(); local count = 0
    for i = #destinationTimestamps, 1, -1 do
        if now - destinationTimestamps[i] <= seconds then count = count + 1
        else table.remove(destinationTimestamps, i) end
    end
    return count
end

task.spawn(function()
    task.wait(3)
    lastMoney = getCleanMoney()
    while true do
        task.wait(2)
        local newMoney = getCleanMoney()
        if newMoney > lastMoney then
            local delta = newMoney - lastMoney
            logIncome(delta)
            if _G.AutoWebhook then
                pendingIncome = pendingIncome + delta
                if not isRunning then
                    isRunning = true
                    task.spawn(function()
                        while isRunning and _G.AutoWebhook do
                            task.wait(60)
                            if pendingIncome > 0 and _G.WebhookURL ~= "" then
                                pendingIncome = 0
                            end
                            if not _G.AutoWebhook or not _G.Autofarm then isRunning = false end
                        end
                    end)
                end
            end
        end
        lastMoney = newMoney
    end
end)

local SelectedNPC, SelectedDealer, SelectedPlayer = "", "", ""

local NPC_Paths = {
    ["Npc job select"]       = workspace.Etc.Job.Selection.Model.Prompt,
    ["Npc upgrade slot Npc"] = workspace.Etc.Upgrade.Upgrade.Prompt,
    ["Npc Box Shop"]         = workspace.Etc.NPC.BOXSHOP.ProximityPrompt,
    ["Daily quest npc"]      = workspace.Asset.DailyQuest.NPC.ProximityPrompt,
}

local function getMyTruck()
    for _, v in pairs(Workspace:WaitForChild("Vehicles"):GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("DriveSeat") then return v end
    end
end

task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    lp.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

local function getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId="..lp.UserId.."&width=420&height=420&format=png"
end

local function sendWebhook(income)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    _G.CycleCount   = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    local HttpService  = game:GetService("HttpService")
    local embed = {
        author  = {name = "Projectsion Webhook", icon_url = getAvatar()},
        title   = "Cycle Completed",
        color   = 0xFFFFFF,
        fields  = {
            {name="Username",      value=lp.Name,                                                           inline=false},
            {name="Cycle Income",  value=formatRP(income),                                                  inline=false},
            {name="Current Money", value=formatRP(getCleanMoney()).." (Est)",                               inline=false},
            {name="Total Earning", value=formatRP(_G.TotalEarning).." (Est)",                              inline=false},
            {name="Cycle Count",   value=tostring(_G.CycleCount),                                          inline=false},
            {name="Running Time",  value=getRunningTime(),                                                  inline=false},
            {name="Session Time",  value=SessionStart and formatDuration(os.time()-SessionStart) or "—",   inline=false},
            {name="Session /Hour", value="RP. "..formatShort(getSessionIPH()),                             inline=false},
            {name="Est /Hour",     value="RP. "..formatShort(getIncomePerHour()),                          inline=false},
            {name="FPS",           value=string.format("%.0f fps", getFPS()),                              inline=false},
        },
        image  = {url="https://cdn.discordapp.com/attachments/1492837859370074192/1508063383944036433/IMG_20260524_180509.jpg"},
        footer = {text="Made by .projectsion | "..os.date("%m/%d/%Y %I:%M %p")},
    }
    if http_request then
        pcall(function()
            http_request({
                Url     = _G.WebhookURL,
                Method  = "POST",
                Headers = {["Content-Type"]="application/json"},
                Body    = HttpService:JSONEncode({username="Projectsion Reports", embeds={embed}})
            })
        end)
    end
end

local function getWaypointName(waypoint)
    if not waypoint then return "Unknown" end
    local gui = waypoint:FindFirstChildOfClass("BillboardGui") or waypoint:FindFirstChildOfClass("SurfaceGui")
    if gui then
        local tl = gui:FindFirstChildOfClass("TextLabel")
        if tl and tl.Text ~= "" then return tl.Text end
    end
    return waypoint.Name
end

local function isTargetDestination(waypoint)
    if not waypoint then return false end
    local wpName  = waypoint.Name:lower()
    local wpLabel = ""
    local gui = waypoint:FindFirstChildOfClass("BillboardGui") or waypoint:FindFirstChildOfClass("SurfaceGui")
    if gui then
        local tl = gui:FindFirstChildOfClass("TextLabel")
        if tl then wpLabel = tl.Text:lower() end
    end
    for _, t in pairs({"malang","sidoarjo","cargo","surabaya"}) do
        if wpName:find(t) or wpLabel:find(t) then return true end
    end
    return false
end

local function updateCycleLabels(earned, destName)
    lastDestEarned = earned
    lastDestName   = destName
    if CycleEarnedLabel then
        CycleEarnedLabel:Set({Title="Cycle Earned:", Content="RP. "..formatNominal(earned)})
    end
    if LastDestLabel then
        LastDestLabel:Set({Title="Last Destination:", Content=destName.."  →  RP. "..formatNominal(earned)})
    end
end

-- ─── ROLL UNTIL TARGET ───────────────────────────────────────────────────────
-- spam starter langsung tanpa task.wait blocking
local function rollUntilTarget(remote, etc, hrp)
    local waypointFolder = etc and etc:FindFirstChild("Waypoint")
    if not waypointFolder then return false end

    local attempt = 0

    while _G.Autofarm do
        attempt = attempt + 1
        if DelayLabel then
            DelayLabel:Set({Title="Status:", Content="Rolling Job (Attempt "..attempt..")..."})
        end

        -- reset job dulu
        if remote then remote:FireServer("Unemployed") end

        -- tunggu waypoint lama ilang (max 2s, non-blocking)
        local clearStart = os.clock()
        while waypointFolder:FindFirstChild("Waypoint") and (os.clock()-clearStart) < 2 do
            RunService.Heartbeat:Wait()
        end

        -- fire job baru
        if remote then remote:FireServer("Truck") end

        -- spam starter tanpa task.wait — fire langsung berkali-kali sampai waypoint muncul
        local starter = etc:FindFirstChild("Job")
            and etc.Job:FindFirstChild("Truck")
            and etc.Job.Truck:FindFirstChild("Starter")

        local gotWaypoint = nil
        local wpConn
        wpConn = waypointFolder.ChildAdded:Connect(function(child)
            gotWaypoint = child
            if wpConn then wpConn:Disconnect() end
        end)

        -- spam fire proximityprompt setiap heartbeat sampai dapat waypoint (max 3s)
        local spamStart = os.clock()
        while not gotWaypoint and (os.clock()-spamStart) < 3 do
            if starter and hrp then
                hrp.CFrame = uprightCF(starter:GetPivot(), 3)
                local prompt = starter:FindFirstChild("Prompt")
                if prompt then
                    fireproximityprompt(prompt)
                end
            end
            RunService.Heartbeat:Wait()
        end
        pcall(function() if wpConn then wpConn:Disconnect() end end)

        if not gotWaypoint then
            gotWaypoint = waypointFolder:FindFirstChild("Waypoint")
        end

        if gotWaypoint then
            -- kasih 1 frame buat stabilize
            RunService.Heartbeat:Wait()
            local wp = waypointFolder:FindFirstChild("Waypoint") or gotWaypoint
            if isTargetDestination(wp) then
                lastDestName = getWaypointName(wp)
                if _G.DeleteMap then
                    local wpos = wp:IsA("Model") and wp:GetPivot().Position or wp.Position
                    buildPlatform(wpos, 400, 400, 25)
                end
                return true
            end
        end

        RunService.Heartbeat:Wait()
    end

    return false
end

-- ─── AUTOFARM ────────────────────────────────────────────────────────────────
local function runAutofarm()
    StartMoney      = getCleanMoney()
    SessionStart    = os.time()
    SessionMoneyStart = StartMoney

    repeat
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp  = char:WaitForChild("HumanoidRootPart")

        local etc     = Workspace:FindFirstChild("Etc")
        local network = ReplicatedStorage:FindFirstChild("NetworkContainer")
        local remote  = network
            and network:FindFirstChild("RemoteEvents")
            and network.RemoteEvents:FindFirstChild("Job")

        local dapetRute = rollUntilTarget(remote, etc, hrp)
        if not dapetRute or not _G.Autofarm then continue end

        local spawnerPart = Workspace
            :WaitForChild("Etc"):WaitForChild("Job")
            :WaitForChild("Truck"):WaitForChild("Spawner"):WaitForChild("Part")

        hrp.CFrame = uprightCF(spawnerPart.CFrame, 3)
        RunService.Heartbeat:Wait()
        task.wait(0.4)

fireproximityprompt(spawnerPart:WaitForChild("Prompt"))
task.wait(0.4)
fireproximityprompt(spawnerPart:WaitForChild("Prompt"))
task.wait(0.4)
fireproximityprompt(spawnerPart:WaitForChild("Prompt"))

        local myTruck = getMyTruck()

        if myTruck then
            hrp.CFrame = uprightCF(myTruck.DriveSeat.CFrame, 1)
            RunService.Heartbeat:Wait()
            fireproximityprompt(myTruck.DriveSeat:WaitForChild("PromptDriveSeat"))

            while _G.Autofarm do
                if not myTruck or not myTruck.Parent then break end

                local waypointFolder = Workspace:WaitForChild("Etc"):WaitForChild("Waypoint")
                local waypoint       = waypointFolder:FindFirstChild("Waypoint")
                if not waypoint then task.wait(0.5); continue end

                if isTargetDestination(waypoint) then
                    local targetCFrame      = waypoint:IsA("Model") and waypoint:GetPivot() or waypoint.CFrame
                    local currentDestName   = getWaypointName(waypoint)
                    cycleMoneySnapshot      = getCleanMoney()
                    EarnedMoney             = cycleMoneySnapshot - StartMoney
                    NextTeleportIn          = TP_TWEEN_DURATION

                    if DelayLabel then
                        DelayLabel:Set({Title="Teleporting to "..currentDestName..":", Content="Starting tween..."})
                    end

                    -- tween jalan dari sekarang, countdown realtime, nyampe bareng
                    tweenTruckToDestination(myTruck, targetCFrame, TP_TWEEN_DURATION, function(remaining)
                        if DelayLabel then
                            DelayLabel:Set({
                                Title   = "Teleporting → "..currentDestName,
                                Content = string.format("%d sec remaining  |  %.0f fps", math.ceil(remaining), getFPS()),
                            })
                        end
                    end)

                    if not _G.Autofarm then break end

                    _G.TotalTeleportCount = _G.TotalTeleportCount + 1
                    logDestinationComplete()

                    -- tunggu waypoint berganti (max 2s)
                    local oldWaypointPos = targetCFrame.Position
                    local timeout = 0
                    repeat
                        task.wait(0.3)
                        timeout = timeout + 0.3
                        local wCheck = waypointFolder:FindFirstChild("Waypoint")
                        if not wCheck or (wCheck:GetPivot().Position - oldWaypointPos).Magnitude > 10 then
                            break
                        end
                    until timeout >= 2

                    task.wait(0.35)

                    local nextWaypoint = waypointFolder:FindFirstChild("Waypoint")

                    if nextWaypoint and isTargetDestination(nextWaypoint) then
                        if DelayLabel then
                            DelayLabel:Set({Title="Status:", Content="Payment + next dest ready..."})
                        end
                        task.wait(1.5)

                        local earned = math.max(0, getCleanMoney() - cycleMoneySnapshot)
                        updateCycleLabels(earned, currentDestName)

                        if _G.DeleteMap then
                            local npos = nextWaypoint:IsA("Model")
                                and nextWaypoint:GetPivot().Position
                                or nextWaypoint.Position
                            buildPlatform(npos, 400, 400, 25)
                        end

                        cycleMoneySnapshot = getCleanMoney()
                        lastDestName       = getWaypointName(nextWaypoint)
                        EarnedMoney        = cycleMoneySnapshot - StartMoney
                        NextTeleportIn     = TP_TWEEN_DURATION

                    else
                        if remote then remote:FireServer("Unemployed") end
                        if DelayLabel then
                            DelayLabel:Set({Title="Status:", Content="Waiting payment..."})
                        end
                        task.wait(1.5)

                        local earned = math.max(0, getCleanMoney() - cycleMoneySnapshot)
                        updateCycleLabels(earned, currentDestName)
                        sendWebhook(earned)
                        break
                    end
                else
                    break
                end
            end

            if DelayLabel then
                DelayLabel:Set({Title="Status:", Content="Clearing old truck & job..."})
            end

            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.SeatPart then humanoid.Jump = true end
            if myTruck and myTruck.Parent then myTruck:Destroy() end
            task.wait(0.8)
        end

        task.wait(0.3)
        continue
    until not _G.Autofarm
end
-- ─── END AUTOFARM ────────────────────────────────────────────────────────────

local Window = Rayfield:CreateWindow({
    Name             = "Car Driving Indonesia | By .projectsion",
    LoadingTitle     = "Projectsion Loading...",
    LoadingSubtitle  = "Version 3.6 (realtime tween teleport)",
    ConfigurationSaving = {Enabled=false},
    Discord          = {Enabled=false},
    KeySystem        = false,
})

local FarmTab = Window:CreateTab("Autofarm", "truck")
FarmTab:CreateSection("Autofarm Truck")
FarmTab:CreateToggle({
    Name         = "On Autofarm Truck (yes)",
    Info         = "Filter Malang / Sidoarjo / Surabaya / Cargo",
    CurrentValue = false,
    Callback     = function(v)
        _G.Autofarm = v
        if v then
            SessionStart      = os.time()
            SessionMoneyStart = getCleanMoney()
            task.spawn(runAutofarm)
        end
    end,
})
FarmTab:CreateToggle({
    Name         = "Enable Black Screen Layout",
    Info         = "Hitamkan layar, UI tetap kelihatan",
    CurrentValue = false,
    Callback     = function(v) BlackScreen.Enabled = v end,
})

local StatsTab = Window:CreateTab("Stats", "trending-up")
StatsTab:CreateSection("Cycle")
CycleEarnedLabel = StatsTab:CreateParagraph({Title="Cycle Earned:",     Content="RP. 0"})
LastDestLabel    = StatsTab:CreateParagraph({Title="Last Destination:", Content="—"})

StatsTab:CreateSection("Session")
SessionTimeLabel   = StatsTab:CreateParagraph({Title="Session Time:",   Content="—"})
SessionEarnedLabel = StatsTab:CreateParagraph({Title="Session Earned:", Content="RP. 0"})
SessionIPHLabel    = StatsTab:CreateParagraph({Title="Session / Hour:", Content="RP. 0/h"})

StatsTab:CreateSection("Overall")
DelayLabel      = StatsTab:CreateParagraph({Title="Status / Next TP:",          Content="Waiting Job..."})
TeleportLabel   = StatsTab:CreateParagraph({Title="Total Teleport Done:",        Content="0 Times"})
DestMinLabel    = StatsTab:CreateParagraph({Title="Destinations (Last 1 Min):",  Content="0"})
Dest5MinLabel   = StatsTab:CreateParagraph({Title="Destinations (Last 5 Mins):", Content="0"})
IncomeHourLabel = StatsTab:CreateParagraph({Title="Est. Income / Hour:",         Content="RP. 0/h"})
EarnedLabel     = StatsTab:CreateParagraph({Title="Total Earned:",               Content="RP. 0"})
CurrentLabel    = StatsTab:CreateParagraph({Title="Current Money:",              Content="RP. 0"})
FpsLabel        = StatsTab:CreateParagraph({Title="Current FPS:",                Content="-- fps"})

local ProxTab = Window:CreateTab("Misc", "bot")
ProxTab:CreateSection("Open NPC")
ProxTab:CreateDropdown({
    Name            = "Select NPC",
    Options         = {"Npc upgrade slot Npc","Npc Box Shop","Daily quest npc"},
    CurrentOption   = {"Npc job select"},
    MultipleOptions = false,
    Callback        = function(v) SelectedNPC = v[1] end,
})
ProxTab:CreateButton({
    Name     = "Open NPC UI",
    Callback = function()
        local t = NPC_Paths[SelectedNPC]
        if t then fireproximityprompt(t) end
    end,
})
ProxTab:CreateSection("Map / Performance")
ProxTab:CreateToggle({
    Name         = "Delete Map (Low Lag Mode)",
    Info         = "Hapus map + terrain, otomatis buat platform di semua destinasi",
    CurrentValue = false,
    Callback     = function(v)
        _G.DeleteMap = v
        if v then deleteMap() else clearPlatforms() end
    end,
})
ProxTab:CreateButton({
    Name     = "Rebuild Destination Platforms",
    Callback = function()
        if _G.DeleteMap then rebuildPlatforms() end
    end,
})

local WebhookTab = Window:CreateTab("Webhook", "webhook")
WebhookTab:CreateSection("Webhook Farm")
WebhookTab:CreateInput({
    Name                    = "Webhook Link",
    PlaceholderText         = "Enter link webhook",
    RemoveTextAfterFocusLost = false,
    Callback                = function(t) _G.WebhookURL = t end,
})
WebhookTab:CreateToggle({
    Name         = "Enable Webhook",
    Info         = "Ngirim tiap cycle selesai",
    CurrentValue = false,
    Callback     = function(v) _G.AutoWebhook = v end,
})

local TpTab = Window:CreateTab("Teleport", "map-pin")
TpTab:CreateSection("Teleport Player")
local PlayerDropdown = TpTab:CreateDropdown({
    Name            = "Select Player",
    Options         = {},
    CurrentOption   = {""},
    MultipleOptions = false,
    Callback        = function(v) SelectedPlayer = v[1] end,
})
local function refreshPlayers()
    local list = {}
    for _, v in pairs(workspace.Lives:GetChildren()) do
        if v:IsA("Model") and v.Name ~= lp.Name then
            table.insert(list, v.Name)
        end
    end
    PlayerDropdown:Refresh(list, {""})
end
TpTab:CreateButton({Name="Refresh Player List", Callback=refreshPlayers})
TpTab:CreateButton({
    Name     = "Teleport to Player",
    Callback = function()
        local t = workspace.Lives:FindFirstChild(SelectedPlayer)
        if t then lp.Character:PivotTo(t:GetPivot()) end
    end,
})
task.spawn(refreshPlayers)

-- ─── STATS LOOP ──────────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1.5)
        local current = getCleanMoney()
        local fps     = getFPS()
        if SessionStart then
            local sessionEarned = math.max(0, current - SessionMoneyStart)
            SessionTimeLabel:Set({
                Title   = "Session Time:",
                Content = formatDuration(os.time()-SessionStart)..(_G.Autofarm and "" or "  (paused)"),
            })
            SessionEarnedLabel:Set({Title="Session Earned:", Content="RP. "..formatNominal(sessionEarned)})
            SessionIPHLabel:Set({Title="Session / Hour:",    Content="RP. "..formatShort(getSessionIPH())})
        end
        if not _G.Autofarm then continue end
        EarnedMoney = current - StartMoney
        TeleportLabel:Set({Title="Total Teleport Done:",        Content=_G.TotalTeleportCount.." Times"})
        DestMinLabel:Set({Title="Destinations (Last 1 Min):",   Content=getDestinationsInWindow(60).." (Chance of Double!)"})
        Dest5MinLabel:Set({Title="Destinations (Last 5 Mins):", Content=tostring(getDestinationsInWindow(300))})
        IncomeHourLabel:Set({Title="Est. Income / Hour:",       Content="RP. "..formatShort(getIncomePerHour())})
        EarnedLabel:Set({Title="Total Earned:",                 Content="RP. "..formatNominal(EarnedMoney)})
        CurrentLabel:Set({Title="Current Money:",               Content="RP. "..formatNominal(current)})
        FpsLabel:Set({
            Title   = "Current FPS:",
            Content = string.format("%.0f fps  %s", fps,
                fps < 30 and "⚠  lag — tp slowed" or
                fps < 50 and "~ mild lag" or "✔ smooth"),
        })
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if _G.Autofarm and DelayLabel and NextTeleportIn > 0 then
            DelayLabel:Set({
                Title = "Next Teleport In:",
                Content = string.format("%d sec  |  %.0f fps", NextTeleportIn, getFPS()),
            })
        end
    end
end)