warn("sebelum loadstring")
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
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
local Window  -- declared early so status toasts work inside farm functions

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

warn("berhasil lewatin services")

_G.Autofarm = false
_G.AutoWebhook = false
_G.DeleteMap = false
_G.WebhookURL = _G.WebhookURL or ""
_G.StartTime = _G.StartTime or os.time()
_G.CycleCount = _G.CycleCount or 0
_G.TotalEarning = _G.TotalEarning or 0
_G.TotalTeleportCount = _G.TotalTeleportCount or 0

warn("berhasil lewatin global")

local MoneyPath = lp.PlayerGui
    :WaitForChild("Main"):WaitForChild("Container"):WaitForChild("Hub")
    :WaitForChild("CashFrame"):WaitForChild("Frame"):WaitForChild("TextLabel")

warn("berhasil lewatin moneypath")

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
local lastDestName = "â€”"
local cycleMoneySnapshot = 0

warn("berhasil lewatin global 2")

local KILL_NAMES = {
    "tree", "pohon", "bush", "semak", "building", "gedung", "house", "rumah",
    "shop", "toko", "wall", "pagar", "fence", "prop", "detail", "lamp", "lampu",
    "sign", "signage", "billboard", "papan", "trash", "sampah", "rock", "batu",
    "grass", "rumput", "flower", "bunga", "car", "kendaraan", "vehicle",
    "decoration", "dekorasi", "obstacle", "barrier",
}

local KEEP_NAMES = {
    "road", "jalan", "asphalt", "aspal", "floor", "lantai", "ground", "tanah",
    "platform", "spawner", "starter", "spawn", "base", "baseplate",
    "waypoint", "checkpoint", "trigger", "invisible", "collision",
    "truck", "depot", "terminal", "garage",
}

local function shouldKill(obj)
    if not obj:IsA("BasePart") and not obj:IsA("Model") then return false end
    local nameLow = obj.Name:lower()
    for _, k in ipairs(KEEP_NAMES) do
        if nameLow:find(k) then return false end
    end
    local ancestor = obj.Parent
    while ancestor and ancestor ~= Workspace do
        local aLow = ancestor.Name:lower()
        for _, k in ipairs(KEEP_NAMES) do
            if aLow:find(k) then return false end
        end
        ancestor = ancestor.Parent
    end
    for _, k in ipairs(KILL_NAMES) do
        if nameLow:find(k) then return true end
    end
    return false
end

local function cleanMap()
    if mapDeleted then return end
    mapDeleted = true
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local prop = map:FindFirstChild("Prop")
    if prop then pcall(function() prop:Destroy() end) end
    for _, child in ipairs(map:GetChildren()) do
        if child.Name ~= "Prop" then
            if shouldKill(child) then
                pcall(function() child:Destroy() end)
            else
                if child:IsA("Model") or child:IsA("Folder") then
                    for _, grandchild in ipairs(child:GetChildren()) do
                        if shouldKill(grandchild) then
                            pcall(function() grandchild:Destroy() end)
                        end
                    end
                end
            end
        end
    end
end

local function uprightCF(cf, yOffset)
    yOffset = yOffset or 0
    local pos = cf.Position + Vector3.new(0, yOffset, 0)
    local look = cf.LookVector
    local yaw = math.atan2(look.X, look.Z)
    return CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
end

local function clearPlatforms()
    for _, p in ipairs(activePlatforms) do
        if p and p.Parent then p:Destroy() end
    end
    activePlatforms = {}
end

local function deleteMap()
    mapDeleted = false
    cleanMap()
end

local STAFF_GROUP_ID = 10884667

local function isStaff(player)
    local ok, result = pcall(function() return player:IsInGroup(STAFF_GROUP_ID) end)
    return ok and result
end

local function selfKick(player)
    local tag = isStaff(player) and "STAFF" or "PLAYER"
    lp:Kick(tag .. " DETECTED (" .. player.Name .. ") â€” player/staff join kacung semua tu staff co")
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

local function steppedTruckTeleport(truck, targetCF)
    if not truck or not truck.Parent then return end
    local origin = truck:GetPivot()
    local duration = 5
    local elapsed = 0
    local done = false

    -- Gen2: use Toast for transient status, stat for countdown
    if Window then
        Window:Toast({ title = "Teleporting", content = string.format("%.0f fps", getFPS()) })
    end

    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not truck or not truck.Parent or not _G.Autofarm then
            conn:Disconnect()
            done = true
            return
        end
        pcall(function() setsimulationradius(math.huge, math.huge) end)
        pcall(function()
            if truck.PrimaryPart then
                truck.PrimaryPart:SetNetworkOwner(lp)
            end
        end)
        local fpsScale = _currentFPS >= 50 and 1 or _currentFPS >= 30 and 0.75 or 0.5
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
            { name = "Session Time",  value = SessionStart and formatDuration(os.time() - SessionStart) or "â€”", inline = false },
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
    local wpName = waypoint.Name:lower()
    local wpLabel = ""
    local gui = waypoint:FindFirstChildOfClass("BillboardGui") or waypoint:FindFirstChildOfClass("SurfaceGui")
    if gui then
        local tl = gui:FindFirstChildOfClass("TextLabel")
        if tl then wpLabel = tl.Text:lower() end
    end
    for _, t in pairs({ "sidoarjo", "malang" }) do
        if wpName:find(t) or wpLabel:find(t) then return true end
    end
    return false
end

local function updateCycleLabels(earned, destName)
    lastDestEarned = earned
    lastDestName = destName
    -- Gen2: CreateStat:Set() takes a raw number; prefix "RP. " handles the label
    if CycleEarnedLabel then CycleEarnedLabel:Set(earned) end
    -- LastDestLabel shows the earned amount; destName shown via Toast since stat is numeric-only
    if LastDestLabel then LastDestLabel:Set(earned) end
    if Window then
        Window:Toast({ title = "Delivery: " .. destName, content = formatRP(earned) })
    end
end

local function rollUntilTarget(remote, etc, hrp)
    local waypointFolder = etc and etc:FindFirstChild("Waypoint")
    if not waypointFolder then return false end
    local attempt = 0
    while _G.Autofarm do
        attempt = attempt + 1
        -- Gen2: transient status via Toast
        if Window then
            Window:Toast({ title = "Rolling Job", content = "Attempt " .. attempt })
        end
        if remote then remote:FireServer("Unemployed") end
        task.wait(0.3)
        if remote then remote:FireServer("Truck") end
        local starter = etc:FindFirstChild("Job")
            and etc.Job:FindFirstChild("Truck")
            and etc.Job.Truck:FindFirstChild("Starter")
        if starter and hrp then
            hrp.CFrame = uprightCF(starter:GetPivot(), 3)
            task.wait(0.1)
            local prompt = starter:FindFirstChild("Prompt")
            if prompt then
                fireproximityprompt(prompt)
                task.wait(0.1)
                fireproximityprompt(prompt)
            end
        end
        task.wait(0.3)
        local wp = waypointFolder:FindFirstChild("Waypoint")
        if wp and isTargetDestination(wp) then
            lastDestName = getWaypointName(wp)
            return true
        end
    end
    return false
end

local function runAutofarm()
    StartMoney = getCleanMoney()
    SessionStart = os.time()
    SessionMoneyStart = StartMoney

    _G.DeleteMap = true
    mapDeleted = false
    deleteMap()

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
        pcall(function()
            local ownable = spawnerPart:FindFirstAncestorOfClass("Model")
            if ownable and ownable.PrimaryPart then
                ownable.PrimaryPart:SetNetworkOwner(lp)
            end
        end)

        fireproximityprompt(spawnerPart:WaitForChild("Prompt"))
        task.wait(3)

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
            pcall(function() setsimulationradius(math.huge, math.huge) end)
            pcall(function()
                if myTruck.PrimaryPart then myTruck.PrimaryPart:SetNetworkOwner(lp) end
            end)

            while _G.Autofarm do
                if not myTruck or not myTruck.Parent then break end

                local waypointFolder = Workspace:WaitForChild("Etc"):WaitForChild("Waypoint")
                local waypoint = waypointFolder:FindFirstChild("Waypoint")
                if not waypoint then task.wait(1) continue end

                if isTargetDestination(waypoint) then
                    local targetCFrame = waypoint:IsA("Model") and waypoint:GetPivot() or waypoint.CFrame
                    local primary = myTruck.PrimaryPart
                    local currentDestName = getWaypointName(waypoint)

                    if primary then
                        local dir = targetCFrame.Position - primary.Position
                        if dir.Magnitude > 5 then
                            primary.AssemblyLinearVelocity = dir.Unit * 70
                        end
                        primary.AssemblyAngularVelocity = Vector3.zero
                    end

                    cycleMoneySnapshot = getCleanMoney()
                    EarnedMoney = cycleMoneySnapshot - StartMoney
                    NextTeleportIn = 43

                    repeat
                        task.wait(1)
                        NextTeleportIn = NextTeleportIn - 1
                        if NextTeleportIn <= 2 and myTruck and primary then
                            primary.AssemblyLinearVelocity = Vector3.new(0, 0.05, 0)
                        end
                    until NextTeleportIn <= 0 or not _G.Autofarm

                    if _G.Autofarm and myTruck and myTruck.Parent then
                        local oldWaypointPos = targetCFrame.Position

                        if primary then
                            primary.AssemblyLinearVelocity = Vector3.zero
                            primary.AssemblyAngularVelocity = Vector3.zero
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

                        task.wait(0.35)

                        if remote then remote:FireServer("Unemployed") end

                        if Window then
                            Window:Toast({ title = "Status", content = "Waiting payment..." })
                        end
                        task.wait(0.3)

                        local earned = math.max(0, getCleanMoney() - cycleMoneySnapshot)
                        updateCycleLabels(earned, currentDestName)

                        break
                    end
                else
                    break
                end
            end

            if Window then
                Window:Toast({ title = "Status", content = "Clearing truck & job..." })
            end

            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.SeatPart then humanoid.Jump = true end
            if myTruck and myTruck.Parent then myTruck:Destroy() end

            task.wait(0.8)
        end

        task.wait(0.3)

        continue
    until not _G.Autofarm

    _G.DeleteMap = false
    mapDeleted = false
end

-- â”€â”€â”€ WINDOW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Gen2: name/subtitle replace Name/LoadingTitle/LoadingSubtitle
-- Gen2: no KeySystem, Discord, or ConfigurationSaving at window level
Window = Rayfield:CreateWindow({
    name     = "Car Driving Indonesia | By .projectsion",
    subtitle = "CDID Script",
})

-- â”€â”€â”€ AUTOFARM TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Gen2: CreateTab takes a props table, not positional args
-- Gen2: icons are asset-id numbers, not icon-name strings â€” omitted here
local FarmTab = Window:CreateTab({ name = "Autofarm" })

-- Gen2: CreateSection takes { name = "..." }
FarmTab:CreateSection({ name = "Autofarm Truck" })

-- Gen2: Nameâ†’name, Infoâ†’description, CurrentValueâ†’value, Callbackâ†’callback
FarmTab:CreateToggle({
    name        = "On Autofarm Truck (yes)",
    description = "Filter HANYA Surabaya / Sidoarjo",
    value       = false,
    callback    = function(v)
        _G.Autofarm = v
        if v then
            SessionStart = os.time()
            SessionMoneyStart = getCleanMoney()
            task.spawn(runAutofarm)
        end
    end,
})

FarmTab:CreateToggle({
    name        = "Enable Black Screen Layout",
    description = "Hitamkan layar, UI tetap kelihatan",
    value       = false,
    callback    = function(v) BlackScreen.Enabled = v end,
})

-- â”€â”€â”€ STATS TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Gen2: no CreateParagraph â€” replaced with CreateStat
-- CreateStat:Set(number) â€” prefix/suffix handle the label context
-- Status messages (non-numeric) go through Window:Toast() in the farm logic above
local StatsTab = Window:CreateTab({ name = "Stats" })

StatsTab:CreateSection({ name = "Cycle" })
CycleEarnedLabel = StatsTab:CreateStat({ name = "Cycle Earned",       prefix = "RP. ", value = 0 })
LastDestLabel    = StatsTab:CreateStat({ name = "Last Cycle Earned",  prefix = "RP. ", value = 0 })

StatsTab:CreateSection({ name = "Session" })
SessionTimeLabel   = StatsTab:CreateStat({ name = "Session Time",    suffix = " min", value = 0 })
SessionEarnedLabel = StatsTab:CreateStat({ name = "Session Earned",  prefix = "RP. ", value = 0 })
SessionIPHLabel    = StatsTab:CreateStat({ name = "Session / Hour",  prefix = "RP. ", suffix = "/h", value = 0 })

StatsTab:CreateSection({ name = "Overall" })
-- DelayLabel: countdown stat â€” stat:Set(NextTeleportIn) in the loop below
DelayLabel      = StatsTab:CreateStat({ name = "Next TP In",               suffix = "s",            value = 0 })
TeleportLabel   = StatsTab:CreateStat({ name = "Total Teleports",          suffix = " times",       value = 0 })
DestMinLabel    = StatsTab:CreateStat({ name = "Dests (Last 1 Min)",                                value = 0 })
Dest5MinLabel   = StatsTab:CreateStat({ name = "Dests (Last 5 Min)",                                value = 0 })
IncomeHourLabel = StatsTab:CreateStat({ name = "Est. Income / Hour",       prefix = "RP. ", suffix = "/h", value = 0 })
EarnedLabel     = StatsTab:CreateStat({ name = "Total Earned",             prefix = "RP. ",         value = 0 })
CurrentLabel    = StatsTab:CreateStat({ name = "Current Money",            prefix = "RP. ",         value = 0 })
FpsLabel        = StatsTab:CreateStat({ name = "FPS",                      suffix = " fps",         value = 0 })

-- â”€â”€â”€ MISC TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local ProxTab = Window:CreateTab({ name = "Misc" })

ProxTab:CreateSection({ name = "Open NPC" })

-- Gen2: Optionsâ†’options, CurrentOptionâ†’value (bare string), MultipleOptionsâ†’multiSelect
-- Gen2: dropdown callback in single mode receives a plain string, not a table
ProxTab:CreateDropdown({
    name     = "Select NPC",
    options  = { "Npc job select", "Npc upgrade slot Npc", "Npc Box Shop", "Daily quest npc" },
    value    = "Npc job select",
    callback = function(v) SelectedNPC = v end,
})

ProxTab:CreateButton({
    name     = "Open NPC UI",
    callback = function()
        local t = NPC_Paths[SelectedNPC]
        if t then fireproximityprompt(t) end
    end,
})

ProxTab:CreateSection({ name = "Open Dealership" })

ProxTab:CreateDropdown({
    name     = "Select Dealer",
    options  = { "Toyota","Suzuki","Premium","Nissan","Mercedes","Komersial","KIA","Hyundai","Honda","Daihatsu","Chery","Bandung","Dealer 77" },
    callback = function(v) SelectedDealer = v end,
})

ProxTab:CreateSection({ name = "Map / Performance" })

ProxTab:CreateButton({
    name     = "Re-run Map Clean",
    callback = function()
        mapDeleted = false
        cleanMap()
    end,
})

-- â”€â”€â”€ WEBHOOK TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local WebhookTab = Window:CreateTab({ name = "Webhook" })

WebhookTab:CreateSection({ name = "Webhook Farm" })

-- Gen2: PlaceholderTextâ†’placeholder, RemoveTextAfterFocusLost dropped (Gen2 default)
WebhookTab:CreateInput({
    name        = "Webhook Link",
    placeholder = "Enter link webhook",
    callback    = function(t) _G.WebhookURL = t end,
})

WebhookTab:CreateToggle({
    name        = "Enable Webhook",
    description = "Ngirim tiap 1 menit",
    value       = false,
    callback    = function(v) _G.AutoWebhook = v end,
})

-- â”€â”€â”€ TELEPORT TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local TpTab = Window:CreateTab({ name = "Teleport" })

TpTab:CreateSection({ name = "Teleport Player" })

local PlayerDropdown = TpTab:CreateDropdown({
    name     = "Select Player",
    options  = {},
    callback = function(v) SelectedPlayer = v end,
})

local function refreshPlayers()
    local list = {}
    for _, v in pairs(workspace.Lives:GetChildren()) do
        if v:IsA("Model") and v.Name ~= lp.Name then
            table.insert(list, v.Name)
        end
    end
    -- Gen2: Refresh(options) â€” second arg (current selection reset) removed
    PlayerDropdown:Refresh(list)
end

TpTab:CreateButton({ name = "Refresh Player List", callback = refreshPlayers })

TpTab:CreateButton({
    name     = "Teleport to Player",
    callback = function()
        local t = workspace.Lives:FindFirstChild(SelectedPlayer)
        if t then lp.Character:PivotTo(t:GetPivot()) end
    end,
})

task.spawn(refreshPlayers)

-- â”€â”€â”€ STATS UPDATE LOOP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Gen2: all stat:Set() calls take raw numbers â€” prefix/suffix handle display context
task.spawn(function()
    while true do
        task.wait(1.5)
        local current = getCleanMoney()
        local fps = getFPS()

        if SessionStart then
            local sessionEarned = math.max(0, current - SessionMoneyStart)
            local sessionMinutes = math.floor((os.time() - SessionStart) / 60)
            SessionTimeLabel:Set(sessionMinutes)
            SessionEarnedLabel:Set(sessionEarned)
            SessionIPHLabel:Set(getSessionIPH())
        end

        if not _G.Autofarm then continue end

        EarnedMoney = current - StartMoney
        TeleportLabel:Set(_G.TotalTeleportCount)
        DestMinLabel:Set(getDestinationsInWindow(60))
        Dest5MinLabel:Set(getDestinationsInWindow(300))
        IncomeHourLabel:Set(getIncomePerHour())
        EarnedLabel:Set(EarnedMoney)
        CurrentLabel:Set(current)
        FpsLabel:Set(math.floor(fps))
    end
end)

-- â”€â”€â”€ COUNTDOWN LOOP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
task.spawn(function()
    while true do
        task.wait(1)
        -- Gen2: stat:Set(number) â€” DelayLabel shows raw countdown seconds
        if _G.Autofarm and NextTeleportIn > 0 then
            DelayLabel:Set(NextTeleportIn)
        end
    end
end)