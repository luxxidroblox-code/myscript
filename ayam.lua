local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local DelayLabel, TeleportLabel, DestMinLabel, Dest5MinLabel
local IncomeHourLabel, EarnedLabel, CurrentLabel, FpsLabel
local SessionTimeLabel, SessionEarnedLabel, SessionIPHLabel

local targetProp = workspace.Map.Prop:GetChildren()[1627]
if targetProp then targetProp:Destroy() end

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
local lp                = Players.LocalPlayer

_G.Autofarm           = false
_G.AutoWebhook        = false
_G.WebhookURL         = _G.WebhookURL         or ""
_G.StartTime          = _G.StartTime          or os.time()
_G.CycleCount         = _G.CycleCount         or 0
_G.TotalEarning       = _G.TotalEarning       or 0
_G.TotalTeleportCount = _G.TotalTeleportCount or 0

local MoneyPath = lp.PlayerGui
    :WaitForChild("Main"):WaitForChild("Container"):WaitForChild("Hub")
    :WaitForChild("CashFrame"):WaitForChild("Frame"):WaitForChild("TextLabel")

local StartMoney        = 0
local EarnedMoney       = 0
local NextTeleportIn    = 0
local SessionStart      = nil
local SessionMoneyStart = 0
local incomeLog         = {}
local lastMoney         = 0
local pendingIncome     = 0
local isRunning         = false
local destinationTimestamps = {}

-- ── anti-staff / anti-join ────────────────────────────────
local STAFF_GROUP_ID = 10884667

local function isStaff(player)
    local ok, result = pcall(function() return player:IsInGroup(STAFF_GROUP_ID) end)
    return ok and result
end

local function selfKick(player)
    local tag = isStaff(player) and "STAFF" or "PLAYER"
    lp:Kick(tag.." DETECTED ("..player.Name..") — player/staff join kacung semua tu staff co")
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
            if player ~= lp then selfKick(player); return end
        end
    end
end)

-- ── helpers ───────────────────────────────────────────────
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
    return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
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
    return h > 0
        and string.format("%dh %02dm %02ds", h, m, s)
        or  string.format("%dm %02ds", m, s)
end

local function getRunningTime()
    local diff = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d",
        math.floor(diff/3600), math.floor((diff%3600)/60), diff%60)
end

-- ── rolling income ────────────────────────────────────────
local function logIncome(amount)
    table.insert(incomeLog, { t=os.time(), amount=amount })
end

local function getIncomePerHour()
    local now, total = os.time(), 0
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
        _currentFPS = math.clamp(1/math.max(tick()-t, 0.001), 1, 144)
        task.wait(0.5)
    end
end)
local function getFPS() return _currentFPS end

-- ── smooth truck teleport ─────────────────────────────────
local function steppedTruckTeleport(truck, targetCF)
    if not truck or not truck.Parent then return end
    local origin = truck:GetPivot()
    local dist   = (targetCF.Position - origin.Position).Magnitude
    local dur    = math.clamp(dist * 0.008, 0.6, 3.0)
    local elapsed, done = 0, false
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not truck or not truck.Parent or not _G.Autofarm then
            conn:Disconnect(); done = true; return
        end
        local fps   = getFPS()
        local scale = fps >= 50 and 1 or fps >= 30 and 0.75 or 0.5
        elapsed     = elapsed + math.min(dt, 0.1) * scale
        local alpha = math.min(elapsed / dur, 1)
        local eased = alpha < 0.5 and 4*alpha^3 or 1-(-2*alpha+2)^3/2
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

local function getDestinationsInWindow(sec)
    local now, count = os.time(), 0
    for i = #destinationTimestamps, 1, -1 do
        if now - destinationTimestamps[i] <= sec then
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
    ["Toyota"]       = workspace.Etc.Dealership.Toyota.Prompt,
    ["Suzuki"]       = workspace.Etc.Dealership.Suzuki.Prompt,
    ["Premium"]      = workspace.Etc.Dealership.Premium.Prompt,
    ["Nissan"]       = workspace.Etc.Dealership.Nissan.Prompt,
    ["Mercedes"]     = workspace.Etc.Dealership.MercedesBenz.Prompt,
    ["Komersial"]    = workspace.Etc.Dealership.Komersial.Prompt,
    ["KIA"]          = workspace.Etc.Dealership.KIA.Prompt,
    ["Hyundai"]      = workspace.Etc.Dealership.Hyundai.Prompt,
    ["Honda"]        = workspace.Etc.Dealership.Honda.Prompt,
    ["Daihatsu"]     = workspace.Etc.Dealership.Daihatsu.Prompt,
    ["Chery"]        = workspace.Etc.Dealership.Chery.Prompt,
    ["Bandung"]      = workspace.Etc.Dealership.Bandung.Prompt,
    ["Dealer 77"]    = workspace.Etc.Dealership["77"].Prompt,
    ["Modification"] = workspace.Map.Building.Modification,
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
    local VU = game:GetService("VirtualUser")
    lp.Idled:Connect(function()
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end)
end)

local function getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId="..lp.UserId.."&width=420&height=420&format=png"
end

local function sendWebhook(income)
    if _G.WebhookURL=="" or not _G.WebhookURL:find("discord.com") then return end
    _G.CycleCount  += 1
    _G.TotalEarning += income
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    local HS = game:GetService("HttpService")
    local embed = {
        author = { name="Projectsion Webhook", icon_url=getAvatar() },
        title  = "Cycle Completed",
        color  = 0xFFFFFF,
        fields = {
            { name="Username",      value=lp.Name,                                              inline=false },
            { name="Cycle Income",  value=formatRP(income),                                     inline=false },
            { name="Current Money", value=formatRP(getCleanMoney()).." (Est)",                   inline=false },
            { name="Total Earning", value=formatRP(_G.TotalEarning).." (Est)",                  inline=false },
            { name="Cycle Count",   value=tostring(_G.CycleCount),                              inline=false },
            { name="Running Time",  value=getRunningTime(),                                     inline=false },
            { name="Session Time",  value=SessionStart and formatDuration(os.time()-SessionStart) or "—", inline=false },
            { name="Session /Hour", value="RP. "..formatShort(getSessionIPH()),                 inline=false },
            { name="Est /Hour",     value="RP. "..formatShort(getIncomePerHour()),              inline=false },
            { name="FPS",           value=string.format("%.0f fps", getFPS()),                  inline=false },
        },
        image  = { url="https://cdn.discordapp.com/attachments/1492837859370074192/1508063383944036433/IMG_20260524_180509.jpg?ex=6a142cf9&is=6a12db79&hm=124ec4dccb5d72326d9b0776d912bb18631948f41162cd9fa6d08eafcff19fb4&" },
        footer = { text="Made by .projectsion | "..os.date("%m/%d/%Y %I:%M %p") },
    }
    if http_request then
        pcall(function()
            http_request({
                Url=_G.WebhookURL, Method="POST",
                Headers={ ["Content-Type"]="application/json" },
                Body=HS:JSONEncode({ username="Projectsion Reports", embeds={embed} })
            })
        end)
    end
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
    for _, t in pairs({"malang","sidoarjo","cargo"}) do
        if wpName:find(t) or wpLabel:find(t) then return true end
    end
    return false
end

-- ── autofarm ─────────────────────────────────────────────
local function runAutofarm()
    StartMoney        = getCleanMoney()
    SessionStart      = os.time()
    SessionMoneyStart = StartMoney

    while _G.Autofarm do
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp  = char:WaitForChild("HumanoidRootPart")
        local dapetRuteBagus = false
        local attemptCount   = 0

        repeat
            if not _G.Autofarm then break end
            attemptCount += 1
            if DelayLabel then
                DelayLabel:Set({ Title="Status:", Content="Rolling Job (Attempt "..attemptCount..")..." })
            end

            local network = ReplicatedStorage:FindFirstChild("NetworkContainer")
            local remote  = network
                and network:FindFirstChild("RemoteEvents")
                and network.RemoteEvents:FindFirstChild("Job")

            if remote then remote:FireServer("Truck") end
            task.wait(0.3 + math.random(15, 25) / 100)

            local etc     = Workspace:FindFirstChild("Etc")
            local starter = etc
                and etc:FindFirstChild("Job")
                and etc.Job:FindFirstChild("Truck")
                and etc.Job.Truck:FindFirstChild("Starter")

            if starter and hrp then
                hrp.CFrame = starter:GetPivot()
                task.wait(0.3)
                local prompt = starter:FindFirstChild("Prompt")
                if prompt then fireproximityprompt(prompt) end
                task.wait(1.2)
            end

            local waypointFolder = etc and etc:FindFirstChild("Waypoint")
            local waypoint       = waypointFolder and waypointFolder:FindFirstChild("Waypoint")

            if waypoint and isTargetDestination(waypoint) then
                dapetRuteBagus = true
            else
                if remote then remote:FireServer("Unemployed") end
                local checkTimeout = 0
                while waypointFolder and waypointFolder:FindFirstChild("Waypoint") and checkTimeout < 2 do
                    task.wait(0.2); checkTimeout += 0.2
                end
                task.wait(0.15 + math.random(0, 15) / 100)
            end
        until dapetRuteBagus or not _G.Autofarm

        if not _G.Autofarm then break end

        local spawnerPart = Workspace
            :WaitForChild("Etc"):WaitForChild("Job")
            :WaitForChild("Truck"):WaitForChild("Spawner"):WaitForChild("Part")

        hrp.CFrame = spawnerPart.CFrame
        task.wait(0.4)
        fireproximityprompt(spawnerPart:WaitForChild("Prompt"))
        task.wait(2.5)

        local myTruck = getMyTruck()

        if myTruck then
            hrp.CFrame = myTruck.DriveSeat.CFrame
            task.wait(0.2)
            fireproximityprompt(myTruck.DriveSeat:WaitForChild("PromptDriveSeat"))

            while _G.Autofarm do
                if not myTruck or not myTruck.Parent then break end

                local waypointFolder = Workspace:WaitForChild("Etc"):WaitForChild("Waypoint")
                local waypoint       = waypointFolder:FindFirstChild("Waypoint")
                if not waypoint then task.wait(1) continue end

                if isTargetDestination(waypoint) then
                    local targetCFrame = waypoint:IsA("Model") and waypoint:GetPivot() or waypoint.CFrame
                    local primary      = myTruck.PrimaryPart

                    if primary then
                        local dir = targetCFrame.Position - primary.Position
                        if dir.Magnitude > 5 then
                            primary.AssemblyLinearVelocity = dir.Unit * 70
                        end
                        primary.AssemblyAngularVelocity = Vector3.zero
                    end

                    EarnedMoney    = getCleanMoney() - StartMoney
                    NextTeleportIn = 41.5

                    repeat
                        task.wait(1)
                        NextTeleportIn -= 1
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
                            DelayLabel:Set({ Title="Status:", Content=string.format("Teleporting... (%.0f fps)", getFPS()) })
                        end

                        steppedTruckTeleport(myTruck, targetCFrame)
                        _G.TotalTeleportCount += 1
                        logDestinationComplete()

                        -- tunggu waypoint confirm
                        local timeout = 0
                        repeat
                            task.wait(0.5); timeout += 0.5
                            local wCheck = waypointFolder:FindFirstChild("Waypoint")
                            if not wCheck or (wCheck:GetPivot().Position - oldWaypointPos).Magnitude > 10 then
                                break
                            end
                        until timeout >= 2

                        -- tunggu server transfer duit sebelum destroy
                        if DelayLabel then
                            DelayLabel:Set({ Title="Status:", Content="Waiting payment..." })
                        end
                        task.wait(3.5)

                        break
                    end
                else
                    break
                end
            end

            if DelayLabel then
                DelayLabel:Set({ Title="Status:", Content="Clearing old truck & job..." })
            end

            local network = ReplicatedStorage:FindFirstChild("NetworkContainer")
            local remote  = network
                and network:FindFirstChild("RemoteEvents")
                and network.RemoteEvents:FindFirstChild("Job")
            if remote then remote:FireServer("Unemployed") end

            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.SeatPart then humanoid.Jump = true end
            if myTruck and myTruck.Parent then myTruck:Destroy() end

            task.wait(0.8)
        end
        task.wait(0.5)
    end
end

-- ── UI ───────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name            = "Car Driving Indonesia | By .projectsion",
    LoadingTitle    = "Projectsion Loading...",
    LoadingSubtitle = "Version 3.1 (payment wait fix)",
    ConfigurationSaving = { Enabled=false },
    Discord         = { Enabled=false },
    KeySystem       = false,
})

local FarmTab = Window:CreateTab("Autofarm", "truck")
FarmTab:CreateSection("Autofarm Truck")

FarmTab:CreateToggle({
    Name="On Autofarm Truck (yes)",
    Info="Filter job Malang / Sidoarjo only",
    CurrentValue=false,
    Callback=function(v)
        _G.Autofarm = v
        if v then
            SessionStart      = os.time()
            SessionMoneyStart = getCleanMoney()
            task.spawn(runAutofarm)
        end
    end,
})

FarmTab:CreateToggle({
    Name="Enable Black Screen Layout",
    Info="Hitamkan layar, UI tetap kelihatan",
    CurrentValue=false,
    Callback=function(v) BlackScreen.Enabled = v end,
})

local StatsTab = Window:CreateTab("Stats", "trending-up")
StatsTab:CreateSection("Session")

SessionTimeLabel   = StatsTab:CreateParagraph({ Title="Session Time:",   Content="—" })
SessionEarnedLabel = StatsTab:CreateParagraph({ Title="Session Earned:", Content="RP. 0" })
SessionIPHLabel    = StatsTab:CreateParagraph({ Title="Session / Hour:", Content="RP. 0/h" })

StatsTab:CreateSection("Overall")

DelayLabel      = StatsTab:CreateParagraph({ Title="Status / Next TP:",          Content="Waiting Job..." })
TeleportLabel   = StatsTab:CreateParagraph({ Title="Total Teleport Done:",        Content="0 Times" })
DestMinLabel    = StatsTab:CreateParagraph({ Title="Destinations (Last 1 Min):",  Content="0" })
Dest5MinLabel   = StatsTab:CreateParagraph({ Title="Destinations (Last 5 Mins):", Content="0" })
IncomeHourLabel = StatsTab:CreateParagraph({ Title="Est. Income / Hour:",         Content="RP. 0/h" })
EarnedLabel     = StatsTab:CreateParagraph({ Title="Total Earned:",               Content="RP. 0" })
CurrentLabel    = StatsTab:CreateParagraph({ Title="Current Money:",              Content="RP. 0" })
FpsLabel        = StatsTab:CreateParagraph({ Title="Current FPS:",                Content="-- fps" })

local ProxTab = Window:CreateTab("Misc", "bot")
ProxTab:CreateSection("Open NPC")
ProxTab:CreateDropdown({
    Name="Select NPC",
    Options={ "Npc upgrade slot Npc","Npc Box Shop","Daily quest npc" },
    CurrentOption={"Npc job select"}, MultipleOptions=false,
    Callback=function(v) SelectedNPC=v[1] end,
})
ProxTab:CreateButton({ Name="Open NPC UI", Callback=function()
    local t=NPC_Paths[SelectedNPC]; if t then fireproximityprompt(t) end
end })

ProxTab:CreateSection("Open Dealership")
ProxTab:CreateDropdown({
    Name="Select Dealer",
    Options={"Toyota","Suzuki","Premium","Nissan","Mercedes","Komersial","KIA","Hyundai","Honda","Daihatsu","Chery","Bandung","Dealer 77"},
    CurrentOption={""}, MultipleOptions=false,
    Callback=function(v) SelectedDealer=v[1] end,
})
ProxTab:CreateButton({ Name="Open Dealer UI", Callback=function()
    local t=Dealer_Paths[SelectedDealer]; if t then fireproximityprompt(t) end
end })

local WebhookTab = Window:CreateTab("Webhook","webhook")
WebhookTab:CreateSection("Webhook Farm")
WebhookTab:CreateInput({
    Name="Webhook Link", PlaceholderText="Enter link webhook",
    RemoveTextAfterFocusLost=false,
    Callback=function(t) _G.WebhookURL=t end,
})
WebhookTab:CreateToggle({
    Name="Enable Webhook", Info="Ngirim tiap 1 menit",
    CurrentValue=false,
    Callback=function(v) _G.AutoWebhook=v end,
})

local TpTab = Window:CreateTab("Teleport","map-pin")
TpTab:CreateSection("Teleport Player")
local PlayerDropdown = TpTab:CreateDropdown({
    Name="Select Player", Options={}, CurrentOption={""}, MultipleOptions=false,
    Callback=function(v) SelectedPlayer=v[1] end,
})
local function refreshPlayers()
    local list={}
    for _,v in pairs(workspace.Lives:GetChildren()) do
        if v:IsA("Model") and v.Name~=lp.Name then table.insert(list,v.Name) end
    end
    PlayerDropdown:Refresh(list,{""})
end
TpTab:CreateButton({ Name="Refresh Player List", Callback=refreshPlayers })
TpTab:CreateButton({ Name="Teleport to Player", Callback=function()
    local t=workspace.Lives:FindFirstChild(SelectedPlayer)
    if t then lp.Character:PivotTo(t:GetPivot()) end
end })
task.spawn(refreshPlayers)

-- ── stats loop ────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1.5)
        local current = getCleanMoney()
        local fps     = getFPS()

        if SessionStart then
            local sessionEarned = math.max(0, current - SessionMoneyStart)
            SessionTimeLabel:Set({
                Title="Session Time:",
                Content=formatDuration(os.time()-SessionStart)
                    ..(_G.Autofarm and "" or "  (paused)"),
            })
            SessionEarnedLabel:Set({ Title="Session Earned:", Content="RP. "..formatNominal(sessionEarned) })
            SessionIPHLabel:Set({ Title="Session / Hour:", Content="RP. "..formatShort(getSessionIPH()) })
        end

        if not _G.Autofarm then continue end

        EarnedMoney = current - StartMoney
        TeleportLabel:Set({ Title="Total Teleport Done:", Content=_G.TotalTeleportCount.." Times" })
        DestMinLabel:Set({ Title="Destinations (Last 1 Min):", Content=getDestinationsInWindow(60).." (Chance of Double!)" })
        Dest5MinLabel:Set({ Title="Destinations (Last 5 Mins):", Content=tostring(getDestinationsInWindow(300)) })
        IncomeHourLabel:Set({ Title="Est. Income / Hour:", Content="RP. "..formatShort(getIncomePerHour()) })
        EarnedLabel:Set({ Title="Total Earned:", Content="RP. "..formatNominal(EarnedMoney) })
        CurrentLabel:Set({ Title="Current Money:", Content="RP. "..formatNominal(current) })
        FpsLabel:Set({
            Title="Current FPS:",
            Content=string.format("%.0f fps  %s", fps,
                fps<30 and "⚠ lag — tp slowed" or fps<50 and "~ mild lag" or "✓ smooth"),
        })
    end
end)

-- countdown loop
task.spawn(function()
    while true do
        task.wait(1)
        if _G.Autofarm and DelayLabel and NextTeleportIn > 0 then
            DelayLabel:Set({
                Title="Next Teleport In:",
                Content=string.format("%d sec  |  %.0f fps", NextTeleportIn, getFPS()),
            })
        end
    end
end)