local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local DelayLabel, TeleportLabel, DestMinLabel, Dest5MinLabel
local IncomeHourLabel, EarnedLabel, CurrentLabel, FpsLabel
local SessionTimeLabel, SessionEarnedLabel, SessionIPHLabel

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

-- ── upright CFrame ────────────────────────────────────────
local function uprightCF(cf, yOffset)
    yOffset = yOffset or 0
    local pos = cf.Position + Vector3.new(0, yOffset, 0)
    local look = cf.LookVector
    local yaw = math.atan2(look.X, look.Z)
    return CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
end

-- ── platform builder ──────────────────────────────────────
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
    if spawnerPart then buildPlatform(spawnerPart.Position - Vector3.new(0, 6, 0), 200, 200) end
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

-- ── anti-staff ────────────────────────────────────────────
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

-- ── helpers ───────────────────────────────────────────────
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

-- ── FPS ──────────────────────────────────────────────────
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

-- ── smooth truck teleport ─────────────────────────────────
local function steppedTruckTeleport(truck, targetCF)
    if not truck or not truck.Parent then return end
    local origin = truck:GetPivot()
    local distance = (targetCF.Position - origin.Position).Magnitude
    local duration = math.clamp(distance * 0.009, 0.8, 3.5)
    local elapsed = 0
    local done = false
    local conn

    conn = RunService.Heartbeat:Connect(function(dt)
        if not truck or not truck.Parent or not _G.Autofarm then
            conn:Disconnect()
            done = true
            return
        end
        local fps = getFPS()
        local fpsScale = fps >= 50 and 1 or fps >= 30 and 0.75 or 0.5
        elapsed = elapsed + math.min(dt, 0.1) * fpsScale
        local alpha = math.min(elapsed / duration, 1)
        local eased
        if alpha < 0.5 then
            eased = 16 * alpha ^ 5
        else
            eased = 1 - (-2 * alpha + 2) ^ 5 / 2
        end
        truck:PivotTo(origin:Lerp(targetCF, eased))
        if alpha >= 1 then
            conn:Disconnect()
            truck:PivotTo(targetCF)
            done = true
        end
    end)

    while not done do task.wait() end
end

-- ── destination log ───────────────────────────────────────
local function logDestinationComplete()
    table.insert(destinationTimestamps, os.time())
end

local function getDestinationsInWindow(seconds)
    local now = os.time()
    local count = 0
    for i = #destinationTimestamps, 1, -1 do
        if now - destinationTimestamps[i] <= seconds then
            count = count + 1
        else
            table.remove(destinationTimestamps, i)
        end
    end
    return count
end

-- ── money tracker ─────────────────────────────────────────
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
                            if not _G.AutoWebhook or not _G.Autofarm then
                                isRunning = false
                            end
                        end
                    end)
                end
            end
        end
        lastMoney = newMoney
    end
end)

-- ── paths ─────────────────────────────────────────────────
local SelectedNPC, SelectedDealer, SelectedPlayer = "", "", ""

local Dealer_Paths = {
    ["Toyota"]    = workspace.Etc.Dealership.Toyota.Prompt,
    ["Suzuki"]    = workspace.Etc.Dealership.Suzuki.Prompt,
    ["Premium"]   = workspace.Etc.Dealership.Premium.Prompt,
    ["Nissan"]    = workspace.Etc.Dealership.Nissan.Prompt,
    ["Mercedes"]  = workspace.Etc.Dealership.MercedesBenz.Prompt,
    ["Komersial"] = workspace.Etc.Dealership.Komersial.Prompt,
    ["KIA"]       = workspace.Etc.Dealership.KIA.Prompt,
    ["Hyundai"]   = workspace.Etc.Dealership.Hyundai.Prompt,
    ["Honda"]     = workspace.Etc.Dealership.Honda.Prompt,
    ["Daihatsu"]  = workspace.Etc.Dealership.Daihatsu.Prompt,
    ["Chery"]     = workspace.Etc.Dealership.Chery.Prompt,
    ["Bandung"]   = workspace.Etc.Dealership.Bandung.Prompt,
    ["Dealer 77"] = workspace.Etc.Dealership["77"].Prompt,
}

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
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. lp.UserId .. "&width=420&height=420&format=png"
end

local function sendWebhook(income)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    _G.CycleCount = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    local HttpService = game:GetService("HttpService")
    local embed = {
        author = { name = "Projectsion Webhook", icon_url = getAvatar() },
        title = "Cycle Completed",
        color = 0xFFFFFF,
        fields = {
            { name = "Username",      value = lp.Name,                                                          inline = false },
            { name = "Cycle Income",  value = formatRP(income),                                                 inline = false },
            { name = "Current Money", value = formatRP(getCleanMoney()) .. " (Est)",                            inline = false },
            { name = "Total Earning", value = formatRP(_G.TotalEarning) .. " (Est)",                           inline = false },
            { name = "Cycle Count",   value = tostring(_G.CycleCount),                                         inline = false },
            { name = "Running Time",  value = getRunningTime(),                                                 inline = false },
            { name = "Session Time",  value = SessionStart and formatDuration(os.time() - SessionStart) or "—", inline = false },
            { name = "Session /Hour", value = "RP. " .. formatShort(getSessionIPH()),                          inline = false },
            { name = "Est /Hour",     value = "RP. " .. formatShort(getIncomePerHour()),                       inline = false },
            { name = "FPS",           value = string.format("%.0f fps", getFPS()),                             inline = false },
        },
        image = { url = "https://cdn.discordapp.com/attachments/1492837859370074192/1508063383944036433/IMG_20260524_180509.jpg?ex=6a142cf9&is=6a12db79&hm=124ec4dccb5d72326d9b0776d912bb18631948f41162cd9fa6d08eafcff19fb4&" },
        footer = { text = "Made by .projectsion | " .. os.date("%m/%d/%Y %I:%M %p") },
    }
    if http_request then
        pcall(function()
            http_request({
                Url = _G.WebhookURL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({ username = "Projectsion Reports", embeds = { embed } })
            })
        end)
    end
end

local function isTargetDestination(waypoint)
    if not waypoint then return false end
    local wpName = waypoint.Name:lower()
    local wpLabel = ""
    local gui = waypoint:FindFirstChildOfClass("BillboardGui") or waypoint:FindFirstChildOfClass("SurfaceGui")
    if gui then
        local tl = gui:FindFirstChildOfClass("TextLabel")
        if tl then wpLabel = tl.Text:lower() end
    end
    for _, t in pairs({ "malang", "sidoarjo", "cargo", "surabaya" }) do
        if wpName:find(t) or wpLabel:find(t) then return true end
    end
    return false
end

-- ── roll until target ─────────────────────────────────────
local function rollUntilTarget(remote, etc, hrp)
    local waypointFolder = etc and etc:FindFirstChild("Waypoint")
    if not waypointFolder then return false end

    local starter = etc:FindFirstChild("Job")
        and etc.Job:FindFirstChild("Truck")
        and etc.Job.Truck:FindFirstChild("Starter")

    local attempt = 0

    while _G.Autofarm do
        attempt = attempt + 1
        if DelayLabel then
            DelayLabel:Set({ Title = "Status:", Content = "Rolling Job (Attempt " .. attempt .. ")..." })
        end

        -- fire unemployed, wait for server
        if remote then remote:FireServer("Unemployed") end
        task.wait(0.5)

        local clearTimeout = 0
        while waypointFolder:FindFirstChild("Waypoint") and clearTimeout < 3 do
            task.wait(0.1)
            clearTimeout = clearTimeout + 0.1
        end

        -- hook ChildAdded BEFORE firing
        local gotWaypoint = nil
        local wpDone = false
        local conn
        conn = waypointFolder.ChildAdded:Connect(function(child)
            gotWaypoint = child
            wpDone = true
            conn:Disconnect()
        end)

        -- fire truck job
        if remote then remote:FireServer("Truck") end

        -- teleport to starter + fire prompt
        if starter and hrp then
            hrp.CFrame = uprightCF(starter:GetPivot(), 3)
            task.wait(0.15)
            local prompt = starter:FindFirstChild("Prompt")
            if prompt then fireproximityprompt(prompt) end
        end

        -- wait for waypoint (max 3s)
        local wpTimeout = 0
        while not wpDone and wpTimeout < 3 do
            task.wait(0.05)
            wpTimeout = wpTimeout + 0.05
        end
        pcall(function() conn:Disconnect() end)

        -- fallback scan
        if not gotWaypoint then
            gotWaypoint = waypointFolder:FindFirstChild("Waypoint")
        end

        -- small settle so BillboardGui text can populate
        if gotWaypoint then task.wait(0.2) end

        if gotWaypoint and isTargetDestination(gotWaypoint) then
            if DelayLabel then
                DelayLabel:Set({ Title = "Status:", Content = "Target found! Going to spawner..." })
            end
            if _G.DeleteMap then
                local wpos = gotWaypoint:IsA("Model")
                    and gotWaypoint:GetPivot().Position
                    or gotWaypoint.Position
                buildPlatform(wpos, 400, 400, 25)
            end
            return true
        end

        if DelayLabel then
            DelayLabel:Set({ Title = "Status:", Content = "Not target — re-rolling..." })
        end
        task.wait(0.3)
    end

    return false
end

-- ── try spawn truck (retries spawner WITHOUT losing the job) ──
local function trySpawnTruck(hrp, spawnerPart, maxAttempts)
    maxAttempts = maxAttempts or 4
    local myTruck = nil

    for attempt = 1, maxAttempts do
        if not _G.Autofarm then break end
        if DelayLabel then
            DelayLabel:Set({ Title = "Status:", Content = "Spawning truck (try " .. attempt .. "/" .. maxAttempts .. ")..." })
        end

        hrp.CFrame = uprightCF(spawnerPart.CFrame, 3)
        task.wait(0.3)
        fireproximityprompt(spawnerPart:WaitForChild("Prompt"))

        -- wait up to 5s per attempt
        local t = 0
        repeat
            task.wait(0.4)
            t = t + 0.4
            myTruck = getMyTruck()
        until myTruck or t >= 5

        if myTruck then break end
        task.wait(0.5)
    end

    return myTruck
end

-- ── autofarm ─────────────────────────────────────────────
local function runAutofarm()
    StartMoney = getCleanMoney()
    SessionStart = os.time()
    SessionMoneyStart = StartMoney

    while _G.Autofarm do
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        local etc = Workspace:FindFirstChild("Etc")
        local network = ReplicatedStorage:FindFirstChild("NetworkContainer")
        local remote = network
            and network:FindFirstChild("RemoteEvents")
            and network.RemoteEvents:FindFirstChild("Job")

        -- roll for target destination
        local dapetRuteBagus = rollUntilTarget(remote, etc, hrp)
        if not dapetRuteBagus or not _G.Autofarm then continue end

        local spawnerPart = Workspace
            :WaitForChild("Etc"):WaitForChild("Job")
            :WaitForChild("Truck"):WaitForChild("Spawner"):WaitForChild("Part")

        -- retry spawner WITHOUT firing Unemployed — keeps the job + destination alive
        local myTruck = trySpawnTruck(hrp, spawnerPart, 4)

        if myTruck then
            hrp.CFrame = uprightCF(myTruck.DriveSeat.CFrame, 1)
            task.wait(0.2)
            fireproximityprompt(myTruck.DriveSeat:WaitForChild("PromptDriveSeat"))

            while _G.Autofarm do
                if not myTruck or not myTruck.Parent then break end

                local waypointFolder = Workspace:WaitForChild("Etc"):WaitForChild("Waypoint")
                local waypoint = waypointFolder:FindFirstChild("Waypoint")
                if not waypoint then task.wait(1) continue end

                if isTargetDestination(waypoint) then
                    local targetCFrame = waypoint:IsA("Model") and waypoint:GetPivot() or waypoint.CFrame
                    local primary = myTruck.PrimaryPart

                    if primary then
                        local dir = targetCFrame.Position - primary.Position
                        if dir.Magnitude > 5 then
                            primary.AssemblyLinearVelocity = dir.Unit * 70
                        end
                        primary.AssemblyAngularVelocity = Vector3.zero
                    end

                    EarnedMoney = getCleanMoney() - StartMoney
                    NextTeleportIn = 42

                    repeat
                        task.wait(1)
                        NextTeleportIn = NextTeleportIn - 1
                        if NextTeleportIn <= 25 and myTruck and primary then
                            primary.AssemblyLinearVelocity = Vector3.new(0, 0.05, 0)
                        end
                    until NextTeleportIn <= 0 or not _G.Autofarm

                    if _G.Autofarm and myTruck and myTruck.Parent then
                        local oldWaypointPos = targetCFrame.Position

                        if primary then
                            primary.AssemblyLinearVelocity = Vector3.zero
                            primary.AssemblyAngularVelocity = Vector3.zero
                        end

                        if DelayLabel then
                            DelayLabel:Set({
                                Title = "Status:",
                                Content = string.format("Teleporting... (%.0f fps)", getFPS())
                            })
                        end

                        steppedTruckTeleport(myTruck, targetCFrame)
                        _G.TotalTeleportCount = _G.TotalTeleportCount + 1
                        logDestinationComplete()

                        local timeout = 0
                        repeat
                            task.wait(0.5)
                            timeout = timeout + 0.5
                            local wCheck = waypointFolder:FindFirstChild("Waypoint")
                            if not wCheck or (wCheck:GetPivot().Position - oldWaypointPos).Magnitude > 10 then
                                break
                            end
                        until timeout >= 2

                        if DelayLabel then
                            DelayLabel:Set({ Title = "Status:", Content = "Waiting payment..." })
                        end
                        task.wait(3.5)

                        local nextWaypoint = waypointFolder:FindFirstChild("Waypoint")
                        if nextWaypoint and isTargetDestination(nextWaypoint) then
                            if _G.DeleteMap then
                                local npos = nextWaypoint:IsA("Model")
                                    and nextWaypoint:GetPivot().Position
                                    or nextWaypoint.Position
                                buildPlatform(npos, 400, 400, 25)
                            end
                            if DelayLabel then
                                DelayLabel:Set({ Title = "Status:", Content = "Next dest ready — skipping reset!" })
                            end
                            EarnedMoney = getCleanMoney() - StartMoney
                            NextTeleportIn = 42
                        else
                            break
                        end
                    end
                else
                    break
                end
            end

            if DelayLabel then
                DelayLabel:Set({ Title = "Status:", Content = "Clearing truck..." })
            end

            -- jump out of seat, destroy truck, then rollUntilTarget handles Unemployed
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.SeatPart then humanoid.Jump = true end
            task.wait(0.3)
            if myTruck and myTruck.Parent then myTruck:Destroy() end
            task.wait(0.8)
        else
            -- spawner genuinely failed after all retries — NOW safe to unemployed
            if DelayLabel then
                DelayLabel:Set({ Title = "Status:", Content = "Spawner failed — full reset..." })
            end
            if remote then remote:FireServer("Unemployed") end
            task.wait(1.5)
        end

        task.wait(0.3)
    end
end

-- ── UI ───────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name = "Car Driving Indonesia | By .projectsion",
    LoadingTitle = "Projectsion Loading...",
    LoadingSubtitle = "Version 3.6 (spawner retry — no job loss)",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
})

local FarmTab = Window:CreateTab("Autofarm", "truck")
FarmTab:CreateSection("Autofarm Truck")

FarmTab:CreateToggle({
    Name = "On Autofarm Truck (yes)",
    Info = "Filter Malang / Sidoarjo / Surabaya / Cargo",
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
    Info = "Hitamkan layar, UI tetap kelihatan",
    CurrentValue = false,
    Callback = function(v) BlackScreen.Enabled = v end,
})

local StatsTab = Window:CreateTab("Stats", "trending-up")
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

local ProxTab = Window:CreateTab("Misc", "bot")
ProxTab:CreateSection("Open NPC")
ProxTab:CreateDropdown({
    Name = "Select NPC",
    Options = { "Npc upgrade slot Npc", "Npc Box Shop", "Daily quest npc" },
    CurrentOption = { "Npc job select" },
    MultipleOptions = false,
    Callback = function(v) SelectedNPC = v[1] end,
})
ProxTab:CreateButton({
    Name = "Open NPC UI",
    Callback = function()
        local t = NPC_Paths[SelectedNPC]
        if t then fireproximityprompt(t) end
    end,
})

ProxTab:CreateSection("Open Dealership")
ProxTab:CreateDropdown({
    Name = "Select Dealer",
    Options = { "Toyota","Suzuki","Premium","Nissan","Mercedes","Komersial","KIA","Hyundai","Honda","Daihatsu","Chery","Bandung","Dealer 77" },
    CurrentOption = { "" },
    MultipleOptions = false,
    Callback = function(v) SelectedDealer = v[1] end,
})
ProxTab:CreateButton({
    Name = "Open Dealer UI",
    Callback = function()
        local t = Dealer_Paths[SelectedDealer]
        if t then fireproximityprompt(t) end
    end,
})

ProxTab:CreateSection("Map / Performance")
ProxTab:CreateToggle({
    Name = "Delete Map (Low Lag Mode)",
    Info = "Hapus map + terrain, otomatis buat platform di semua destinasi",
    CurrentValue = false,
    Callback = function(v)
        _G.DeleteMap = v
        if v then deleteMap() else clearPlatforms() end
    end,
})
ProxTab:CreateButton({
    Name = "Rebuild Destination Platforms",
    Callback = function()
        if _G.DeleteMap then rebuildPlatforms() end
    end,
})

local WebhookTab = Window:CreateTab("Webhook", "webhook")
WebhookTab:CreateSection("Webhook Farm")
WebhookTab:CreateInput({
    Name = "Webhook Link",
    PlaceholderText = "Enter link webhook",
    RemoveTextAfterFocusLost = false,
    Callback = function(t) _G.WebhookURL = t end,
})
WebhookTab:CreateToggle({
    Name = "Enable Webhook",
    Info = "Ngirim tiap 1 menit",
    CurrentValue = false,
    Callback = function(v) _G.AutoWebhook = v end,
})

local TpTab = Window:CreateTab("Teleport", "map-pin")
TpTab:CreateSection("Teleport Player")
local PlayerDropdown = TpTab:CreateDropdown({
    Name = "Select Player",
    Options = {},
    CurrentOption = { "" },
    MultipleOptions = false,
    Callback = function(v) SelectedPlayer = v[1] end,
})

local function refreshPlayers()
    local list = {}
    for _, v in pairs(workspace.Lives:GetChildren()) do
        if v:IsA("Model") and v.Name ~= lp.Name then
            table.insert(list, v.Name)
        end
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

-- ── stats loop ────────────────────────────────────────────
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
            Content = string.format("%.0f fps  %s", fps,
                fps < 30 and "⚠ lag — tp slowed" or
                fps < 50 and "~ mild lag" or "✓ smooth"),
        })
    end
end)

-- ── countdown loop ────────────────────────────────────────
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