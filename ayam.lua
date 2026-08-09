warn("sebelum loadstring")
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/X5Dermaster/RayField-Loader/refs/heads/main/rayfieldloader.lua'))()
warn("sesudah loadstring")
if Rayfield then
    warn("kalau ini muncul 1 berarti berhasil rayfieldnya")
else
    warn("kalau ini muncul 2 berarti ga berhasil rayfieldnya")
end
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
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

_G.Autofarm = false
_G.AutoWebhook = false
_G.DeleteMap = false
_G.WebhookURL = _G.WebhookURL or ""
_G.StartTime = _G.StartTime or os.time()
_G.CycleCount = _G.CycleCount or 0
_G.TotalEarning = _G.TotalEarning or 0
_G.TotalTeleportCount = _G.TotalTeleportCount or 0

local MoneyPath = lp.PlayerGui
    :WaitForChild("Main"):WaitForChild("Container"):WaitForChild("Hub")
    :WaitForChild("CashFrame"):WaitForChild("Frame"):WaitForChild("TextLabel")

local StartMoney = 0
local EarnedMoney = 0
local NextTeleportIn = 0
local SessionStart = nil
local SessionMoneyStart = 0
local incomeLog = {}
local lastMoney = 0
local pendingIncome = 0
local isRunning = false
local destinationTimestamps = {}
local activePlatforms = {}
local mapDeleted = false
local lastDestEarned = 0
local lastDestName = "—"
local cycleMoneySnapshot = 0

local function uprightCF(cf, yOffset)
    yOffset = yOffset or 0
    local pos = cf.Position + Vector3.new(0, yOffset, 0)
    local look = cf.LookVector
    local yaw = math.atan2(look.X, look.Z)
    return CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
end

local function buildPlatform(position, sizeX, sizeZ, yOffset)
    sizeX = sizeX or 350
    sizeZ = sizeZ or 350
    yOffset = yOffset or 4
    local p = Instance.new("Part")
    p.Name = "FarmPlatform"
    p.Size = Vector3.new(sizeX, 8, sizeZ)
    p.CFrame = CFrame.new(position.X, position.Y - yOffset, position.Z)
    p.Anchored = true
    p.CanCollide = true
    p.CastShadow = false
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
    lp:Kick(tag .. " DETECTED (" .. player.Name .. ") — player/staff join kacung semua tu staff co")
end
Players.PlayerAdded:Connect(function(player)
    if player == lp then return end
    task.wait(0.5)
    selfKick(player)
end)
task.spawn(function()
    while true do
        task.wait(3)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp then selfKick(player) return end
        end
    end
end)

local function getCleanMoney()
    local raw = MoneyPath.Text:gsub("RP.", ""):gsub(",", ""):gsub("%s+", "")
    return tonumber(raw) or 0
end

local function formatShort(n)
    if n >= 1000000 then return string.format("%.1fM/h", n / 1000000):gsub("%.0M", "M")
    elseif n >= 1000 then return string.format("%.1fK/h", n / 1000):gsub("%.0K", "K")
    else return tostring(n) .. "/h" end
end

local function formatNominal(n)
    local left, num, right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
    if not left then return tostring(n) end
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

local function formatRP(v)
    local s = string.format("%.0f", v)
    return "RP. " .. s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
end

local function formatDuration(sec)
    sec = math.max(0, math.floor(sec))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%dh %02dm %02ds", h, m, s)
    else return string.format("%dm %02ds", m, s) end
end

local function getRunningTime()
    local diff = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d",
        math.floor(diff / 3600), math.floor((diff % 3600) / 60), diff % 60)
end

local function logIncome(amount)
    table.insert(incomeLog, { t = os.time(), amount = amount })
end
local function getIncomePerHour()
    local now = os.time()
    local total = 0
    for i = #incomeLog, 1, -1 do
        if now - incomeLog[i].t <= 600 then
            total = total + incomeLog[i].amount
        else
            table.remove(incomeLog, i)
        end
    end
    if total == 0 then return 0 end
    local elapsed = math.min(now - _G.StartTime, 600)
    if elapsed < 20 then return 0 end
    return math.floor((total / elapsed) * 3600)
end
local function getSessionIPH()
    if not SessionStart then return 0 end
    local elapsed = os.time() - SessionStart
    if elapsed < 20 then return 0 end
    local earned = math.max(0, getCleanMoney() - SessionMoneyStart)
    return math.floor((earned / elapsed) * 3600)
end

local _currentFPS = 60
task.spawn(function()
    while true do
        local t = tick()
        RunService.Heartbeat:Wait()
        _currentFPS = math.clamp(1 / math.max(tick() - t, 0.001), 1, 144)
        task.wait(0.5)
    end
end)
local function getFPS() return _currentFPS end

-- FUNGSI TURUN FULL & TUNGGU PAYMENT LEBIH CEPAT
local function descendAndWait(vehicle, targetCFrame, duration, moneySnapshot)
    local primary = vehicle.PrimaryPart
    if not primary then return end
    
    local startCFrame = targetCFrame + Vector3.new(0, 1000, 0)
    
    vehicle:PivotTo(startCFrame)
    pcall(function() primary.Velocity = Vector3.new(0, 0, 0) end)
    
    local elapsed = 0
    workspace.Gravity = 0
    local reached = false
    
    local conn = RunService.Heartbeat:Connect(function(dt)
        if not _G.Autofarm or not vehicle.Parent then
            reached = true
            return
        end
        
        elapsed = elapsed + dt
        local alpha = math.clamp(elapsed / duration, 0, 1)
        
        vehicle:PivotTo(startCFrame:Lerp(targetCFrame, alpha))
        pcall(function() primary.Velocity = Vector3.new(0, 0, 0) end)
        
        NextTeleportIn = math.max(0, duration - elapsed)
        
        if alpha >= 1 then reached = true end
    end)
    
    repeat task.wait() until reached
    if conn then conn:Disconnect() end
    
    if DelayLabel then DelayLabel:Set({ Title = "Status:", Content = "Waiting payment..." }) end
    
    local waitStart = tick()
    -- Tahan gravity 0 nunggu payment (cekan super cepat 0.01 detik)
    while _G.Autofarm and vehicle.Parent and (getCleanMoney() <= moneySnapshot) and (tick() - waitStart < 15) do
        task.wait(0.01)
        pcall(function() primary.Velocity = Vector3.new(0, 0, 0) end)
    end
    
    workspace.Gravity = 196.2
    pcall(function() primary.Velocity = Vector3.new(0, 0, 0) end)
end

local function logDestinationComplete()
    table.insert(destinationTimestamps, os.time())
end
local function getDestinationsInWindow(seconds)
    local now = os.time()
    local count = 0
    for i = #destinationTimestamps, 1, -1 do
        if now - destinationTimestamps[i] <= seconds then
            count = count + 1
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

local function getWaypointName(waypoint)
    if not waypoint then return "Unknown" end
    local gui = waypoint:FindFirstChildOfClass("BillboardGui") or waypoint:FindFirstChildOfClass("SurfaceGui")
    if gui then
        local tl = gui:FindFirstChildOfClass("TextLabel")
        if tl and tl.Text ~= "" then return tl.Text end
    end
    return waypoint.Name
end

-- FILTER HANYA SIDOARJO DAN SURABAYA (MALANG/CARGO DIHAPUS)
local function isTargetDestination(waypoint)
    if not waypoint then return false end
    local wpName = waypoint.Name:lower()
    local wpLabel = ""
    local gui = waypoint:FindFirstChildOfClass("BillboardGui") or waypoint:FindFirstChildOfClass("SurfaceGui")
    if gui then
        local tl = gui:FindFirstChildOfClass("TextLabel")
        if tl then wpLabel = tl.Text:lower() end
    end
    for _, t in pairs({ "sidoarjo", "surabaya" }) do
        if wpName:find(t) or wpLabel:find(t) then return true end
    end
    return false
end

local function updateCycleLabels(earned, destName)
    lastDestEarned = earned
    lastDestName = destName
    if CycleEarnedLabel then
        CycleEarnedLabel:Set({ Title = "Cycle Earned:", Content = "RP. " .. formatNominal(earned) })
    end
    if LastDestLabel then
        LastDestLabel:Set({ Title = "Last Destination:", Content = destName .. "  →  RP. " .. formatNominal(earned) })
    end
end

-- SISTEM SPAM STARTER & LOOPING FIRE UNEMPLOYED JIKA BUKAN TARGET
local function rollUntilTarget(remote, etc, hrp)
    local waypointFolder = etc and etc:FindFirstChild("Waypoint")
    if not waypointFolder then return false end

    local attempt = 0

    while _G.Autofarm do
        attempt = attempt + 1
        if DelayLabel then
            DelayLabel:Set({ Title = "Status:", Content = "Rolling Job (Attempt " .. attempt .. ")..." })
        end

        -- 1. Resign job lama 
        if remote then remote:FireServer("Unemployed") end
        task.wait(0.1)
        
        -- Hapus waypoint nyangkut kalau ada
        for _, v in ipairs(waypointFolder:GetChildren()) do
            v:Destroy()
        end
        
        -- 2. Ambil Job Truck
        if remote then remote:FireServer("Truck") end
        task.wait(0.1)

        -- 3. Teleport ke Starter & Spam Pencet
        local starter = etc:FindFirstChild("Job")
            and etc.Job:FindFirstChild("Truck")
            and etc.Job.Truck:FindFirstChild("Starter")
            
        if starter and hrp then
            hrp.CFrame = uprightCF(starter:GetPivot(), 3)
            task.wait(0.1)
            
            local prompt = starter:FindFirstChild("Prompt")
            if prompt then 
                -- SPAM PROMPT STARTER sampai waypoint muncul
                for i = 1, 15 do
                    if waypointFolder:FindFirstChild("Waypoint") then break end
                    fireproximityprompt(prompt)
                    task.wait(0.1)
                end
            end
        end

        -- Tunggu Waypoint muncul sebentar
        local wpTimeout = 0
        while not waypointFolder:FindFirstChild("Waypoint") and wpTimeout < 1.5 do
            task.wait(0.1)
            wpTimeout = wpTimeout + 0.1
        end

        local wp = waypointFolder:FindFirstChild("Waypoint")
        if wp then
            task.wait(0.1) -- Loading label text sebentar
            if isTargetDestination(wp) then
                lastDestName = getWaypointName(wp)
                if _G.DeleteMap then
                    local wpos = wp:IsA("Model") and wp:GetPivot().Position or wp.Position
                    buildPlatform(wpos, 400, 400, 25)
                end
                return true
            else
                -- BUKAN TARGET (Misal malang), langsung hancurin dan loop lagi ke atas (Fire Unemployed)
                wp:Destroy()
            end
        end
    end

    return false
end

local function runAutofarm()
    StartMoney = getCleanMoney()
    SessionStart = os.time()
    SessionMoneyStart = StartMoney

    repeat
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        local etc = Workspace:FindFirstChild("Etc")
        local network = ReplicatedStorage:FindFirstChild("NetworkContainer")
        local remote = network
            and network:FindFirstChild("RemoteEvents")
            and network.RemoteEvents:FindFirstChild("Job")

        local dapetRuteBagus = rollUntilTarget(remote, etc, hrp)
        if not dapetRuteBagus or not _G.Autofarm then continue end

        local spawnerPart = Workspace
            :WaitForChild("Etc"):WaitForChild("Job")
            :WaitForChild("Truck"):WaitForChild("Spawner"):WaitForChild("Part")

        hrp.CFrame = uprightCF(spawnerPart.CFrame, 3)
        task.wait(0.4)
        pcall(function() setsimulationradius(math.huge, math.huge) end)
        fireproximityprompt(spawnerPart:WaitForChild("Prompt"))
        task.wait(2.5)

        local myTruck = getMyTruck()

        if myTruck then
            hrp.CFrame = uprightCF(myTruck.DriveSeat.CFrame, 1)
            task.wait(0.2)
            pcall(function() setsimulationradius(math.huge, math.huge) end)
            pcall(function()
                if myTruck.PrimaryPart then myTruck.PrimaryPart:SetNetworkOwner(lp) end
            end)
            fireproximityprompt(myTruck.DriveSeat:WaitForChild("PromptDriveSeat"))
            task.wait(0.3)

            while _G.Autofarm do
                if not myTruck or not myTruck.Parent then break end

                local waypointFolder = Workspace:WaitForChild("Etc"):WaitForChild("Waypoint")
                local waypoint = waypointFolder:FindFirstChild("Waypoint")
                if not waypoint then task.wait(1) continue end

                if isTargetDestination(waypoint) then
                    local currentDestName = getWaypointName(waypoint)
                    cycleMoneySnapshot = getCleanMoney()
                    EarnedMoney = cycleMoneySnapshot - StartMoney
                    
                    local descentTime = 43
                    NextTeleportIn = descentTime

                    if DelayLabel then
                        DelayLabel:Set({
                            Title = "Status:",
                            Content = string.format("Descending... (%.0f fps)", getFPS())
                        })
                    end

                    local targetCFrame = waypoint:IsA("Model") and waypoint:GetPivot() or waypoint.CFrame
                    descendAndWait(myTruck, targetCFrame, descentTime, cycleMoneySnapshot)

                    if _G.Autofarm and myTruck and myTruck.Parent then
                        _G.TotalTeleportCount = _G.TotalTeleportCount + 1
                        logDestinationComplete()

                        local earned = math.max(0, getCleanMoney() - cycleMoneySnapshot)
                        updateCycleLabels(earned, currentDestName)

                        if remote then remote:FireServer("Unemployed") end
                        break 
                    end
                else
                    break
                end
            end

            if DelayLabel then
                DelayLabel:Set({ Title = "Status:", Content = "Clearing old truck & job..." })
            end

            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.SeatPart then humanoid.Jump = true end
            if myTruck and myTruck.Parent then myTruck:Destroy() end
            task.wait(0.8)
        end
        task.wait(0.3)
    until not _G.Autofarm
end

local Window = Rayfield:CreateWindow({
    Name = "Car Driving Indonesia | By .projectsion",
    LoadingTitle = "Projectsion Loading...",
    LoadingSubtitle = "Version 3.8 (Fast Spam & SBY/SDA Only)",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
})

local FarmTab = Window:CreateTab("Autofarm", "truck")
FarmTab:CreateSection("Autofarm Truck")
FarmTab:CreateToggle({
    Name = "On Autofarm Truck (yes)",
    Info = "Filter HANYA Surabaya & Sidoarjo",
    CurrentValue = false,
    Callback = function(v)
        _G.Autofarm = v
        if v then
            SessionStart = os.time()
            SessionMoneyStart = getCleanMoney()
            task.spawn(runAutofarm)
        end
    end,
})
FarmTab:CreateToggle({
    Name = "Enable Black Screen Layout",
    CurrentValue = false,
    Callback = function(v) BlackScreen.Enabled = v end,
})

local StatsTab = Window:CreateTab("Stats", "trending-up")
StatsTab:CreateSection("Cycle")
CycleEarnedLabel = StatsTab:CreateParagraph({ Title = "Cycle Earned:",    Content = "RP. 0" })
LastDestLabel    = StatsTab:CreateParagraph({ Title = "Last Destination:", Content = "—" })
StatsTab:CreateSection("Session")
SessionTimeLabel   = StatsTab:CreateParagraph({ Title = "Session Time:",   Content = "—" })
SessionEarnedLabel = StatsTab:CreateParagraph({ Title = "Session Earned:", Content = "RP. 0" })
SessionIPHLabel    = StatsTab:CreateParagraph({ Title = "Session / Hour:", Content = "RP. 0/h" })
StatsTab:CreateSection("Overall")
DelayLabel      = StatsTab:CreateParagraph({ Title = "Status / Next TP:",          Content = "Waiting Job..." })
TeleportLabel   = StatsTab:CreateParagraph({ Title = "Total Teleport Done:",        Content = "0 Times" })
DestMinLabel    = StatsTab:CreateParagraph({ Title = "Destinations (Last 1 Min):",  Content = "0" })
Dest5MinLabel   = StatsTab:CreateParagraph({ Title = "Destinations (Last 5 Mins):", Content = "0" })
IncomeHourLabel = StatsTab:CreateParagraph({ Title = "Est. Income / Hour:",         Content = "RP. 0/h" })
EarnedLabel     = StatsTab:CreateParagraph({ Title = "Total Earned:",               Content = "RP. 0" })
CurrentLabel    = StatsTab:CreateParagraph({ Title = "Current Money:",              Content = "RP. 0" })
FpsLabel        = StatsTab:CreateParagraph({ Title = "Current FPS:",                Content = "-- fps" })

local TpTab = Window:CreateTab("Teleport", "map-pin")
TpTab:CreateSection("Teleport Player")
local PlayerDropdown = TpTab:CreateDropdown({
    Name = "Select Player", Options = {}, CurrentOption = { "" }, MultipleOptions = false,
    Callback = function(v) SelectedPlayer = v[1] end,
})
local function refreshPlayers()
    local list = {}
    for _, v in pairs(workspace.Lives:GetChildren()) do
        if v:IsA("Model") and v.Name ~= lp.Name then table.insert(list, v.Name) end
    end
    PlayerDropdown:Refresh(list, { "" })
end
TpTab:CreateButton({ Name = "Refresh Player List", Callback = refreshPlayers })
TpTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        local t = workspace.Lives:FindFirstChild(SelectedPlayer)
        if t then lp.Character:PivotTo(t:GetPivot()) end
    end,
})
task.spawn(refreshPlayers)

task.spawn(function()
    while true do
        task.wait(1.5)
        local current = getCleanMoney()
        local fps = getFPS()
        if SessionStart then
            local sessionEarned = math.max(0, current - SessionMoneyStart)
            SessionTimeLabel:Set({
                Title = "Session Time:",
                Content = formatDuration(os.time() - SessionStart) .. (_G.Autofarm and "" or "  (paused)"),
            })
            SessionEarnedLabel:Set({ Title = "Session Earned:", Content = "RP. " .. formatNominal(sessionEarned) })
            SessionIPHLabel:Set({ Title = "Session / Hour:", Content = "RP. " .. formatShort(getSessionIPH()) })
        end
        if not _G.Autofarm then continue end
        EarnedMoney = current - StartMoney
        TeleportLabel:Set({ Title = "Total Teleport Done:",        Content = _G.TotalTeleportCount .. " Times" })
        DestMinLabel:Set({ Title = "Destinations (Last 1 Min):",   Content = getDestinationsInWindow(60) .. " (Chance of Double!)" })
        Dest5MinLabel:Set({ Title = "Destinations (Last 5 Mins):", Content = tostring(getDestinationsInWindow(300)) })
        IncomeHourLabel:Set({ Title = "Est. Income / Hour:",       Content = "RP. " .. formatShort(getIncomePerHour()) })
        EarnedLabel:Set({ Title = "Total Earned:",                 Content = "RP. " .. formatNominal(EarnedMoney) })
        CurrentLabel:Set({ Title = "Current Money:",               Content = "RP. " .. formatNominal(current) })
        FpsLabel:Set({
            Title = "Current FPS:",
            Content = string.format("%.0f fps  %s", fps, fps < 30 and "⚠ lag" or "✓ smooth"),
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
