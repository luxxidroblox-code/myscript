local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local DelayLabel, TeleportLabel, DestMinLabel, Dest5MinLabel, IncomeHourLabel, EarnedLabel, CurrentLabel

local targetProp = workspace.Map.Prop:GetChildren()[1627]
if targetProp then
    targetProp:Destroy()
end

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
_G.AutoGacha = false
_G.AutoWebhook = false
_G.WebhookURL = ""
local MoneyPath = lp.PlayerGui:WaitForChild("Main"):WaitForChild("Container"):WaitForChild("Hub"):WaitForChild("CashFrame"):WaitForChild("Frame"):WaitForChild("TextLabel")
local StartMoney = 0
local CurrentMoney = 0
local EarnedMoney = 0
local NextTeleportIn = 0
local SavedPos = nil
_G.StartTime = _G.StartTime or os.time()
_G.CycleCount = _G.CycleCount or 0
_G.TotalEarning = _G.TotalEarning or 0
_G.WebhookURL = _G.WebhookURL or ""
_G.TotalTeleportCount = _G.TotalTeleportCount or 0

local lastMoney = 0
local pendingIncome = 0
local isRunning = false
local destinationTimestamps = {}

-- FPS tracker
local _currentFPS = 60
task.spawn(function()
    while true do
        local t = tick()
        RunService.Heartbeat:Wait()
        local dt = tick() - t
        _currentFPS = math.clamp(1 / math.max(dt, 0.001), 1, 144)
        task.wait(0.5)
    end
end)

local function getFPS() return _currentFPS end

-- Smooth stepped truck teleport (Heartbeat lerp, FPS-adaptive)
local function steppedTruckTeleport(truck, targetCF)
    if not truck or not truck.Parent then return end

    local origin = truck:GetPivot()
    local distance = (targetCF.Position - origin.Position).Magnitude

    -- base duration scales with distance: ~1 stud per 0.008s, min 0.6s max 3s
    local baseDuration = math.clamp(distance * 0.008, 0.6, 3.0)

    local elapsed = 0
    local done = false

    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if not truck or not truck.Parent or not _G.Autofarm then
            connection:Disconnect()
            done = true
            return
        end

        local fps = getFPS()

        -- cap raw dt to prevent spike jumps on lag frames
        local cappedDt = math.min(dt, 0.1)

        -- when lagging (fps < 30), slow down alpha advancement so server sees smaller deltas
        local fpsScale = fps >= 50 and 1
            or fps >= 30 and 0.75
            or 0.5

        elapsed = elapsed + (cappedDt * fpsScale)

        local alpha = math.min(elapsed / baseDuration, 1)

        -- ease in-out cubic: smooth start AND end
        local eased = alpha < 0.5
            and 4 * alpha ^ 3
            or 1 - (-2 * alpha + 2) ^ 3 / 2

        truck:PivotTo(origin:Lerp(targetCF, eased))

        if alpha >= 1 then
            connection:Disconnect()
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

local function formatShort(n)
    if n >= 1000000 then
        return string.format("%.1fM/h", n / 1000000):gsub("%.0M", "M")
    elseif n >= 1000 then
        return string.format("%.1fK/h", n / 1000):gsub("%.0K", "K")
    else
        return tostring(n) .. "/h"
    end
end

local function formatNominal(n)
    local left, num, right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
    if not left then return tostring(n) end
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

local function getCleanMoney()
    local rawText = MoneyPath.Text
    local cleanText = rawText:gsub("RP.", ""):gsub(",", ""):gsub("%s+", "")
    return tonumber(cleanText) or 0
end

task.spawn(function()
    task.wait(3)
    lastMoney = getCleanMoney()
end)

local SelectedBox = "Limited Box"
local SelectedNPC = ""
local SelectedDealer = ""
local SelectedPlayer = ""

local Dealer_Paths = {
    ["Toyota"] = workspace.Etc.Dealership.Toyota.Prompt,
    ["Suzuki"] = workspace.Etc.Dealership.Suzuki.Prompt,
    ["Premium"] = workspace.Etc.Dealership.Premium.Prompt,
    ["Nissan"] = workspace.Etc.Dealership.Nissan.Prompt,
    ["Mercedes"] = workspace.Etc.Dealership.MercedesBenz.Prompt,
    ["Komersial"] = workspace.Etc.Dealership.Komersial.Prompt,
    ["KIA"] = workspace.Etc.Dealership.KIA.Prompt,
    ["Hyundai"] = workspace.Etc.Dealership.Hyundai.Prompt,
    ["Honda"] = workspace.Etc.Dealership.Honda.Prompt,
    ["Daihatsu"] = workspace.Etc.Dealership.Daihatsu.Prompt,
    ["Chery"] = workspace.Etc.Dealership.Chery.Prompt,
    ["Bandung"] = workspace.Etc.Dealership.Bandung.Prompt,
    ["Dealer 77"] = workspace.Etc.Dealership["77"].Prompt,
    ["Modification"] = workspace.Map.Building.Modification
}
local NPC_Paths = {
    ["Npc job select"] = workspace.Etc.Job.Selection.Model.Prompt,
    ["Npc upgrade slot Npc"] = workspace.Etc.Upgrade.Upgrade.Prompt,
    ["Npc Box Shop"] = workspace.Etc.NPC.BOXSHOP.ProximityPrompt,
    ["Daily quest npc"] = workspace.Asset.DailyQuest.NPC.ProximityPrompt
}

local function getMyTruck()
    for _, v in pairs(Workspace:WaitForChild("Vehicles"):GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("DriveSeat") then
            return v
        end
    end
    return nil
end

task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

local function getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. lp.UserId .. "&width=420&height=420&format=png"
end

local function formatRP(v)
    local s = string.format("%.0f", v)
    local formatted = s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    return "RP. " .. formatted
end

local function getRunningTime()
    local diff = os.time() - _G.StartTime
    local hours = math.floor(diff / 3600)
    local mins = math.floor((diff % 3600) / 60)
    local secs = diff % 60
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

local function sendWebhook(income, target)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end

    _G.CycleCount = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income

    local currentMoney = getCleanMoney()
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    local HttpService = game:GetService("HttpService")

    local embed = {
        ["author"] = { ["name"] = "Projectsion Webhook", ["icon_url"] = getAvatar() },
        ["title"] = "Cycle Completed",
        ["color"] = 0xFFFFFF,
        ["fields"] = {
            {["name"] = "Username",       ["value"] = lp.Name,                             ["inline"] = false},
            {["name"] = "Cycle Income",   ["value"] = formatRP(income),                    ["inline"] = false},
            {["name"] = "Target",         ["value"] = formatRP(target),                    ["inline"] = false},
            {["name"] = "Current Money",  ["value"] = formatRP(currentMoney) .. " (Est)", ["inline"] = false},
            {["name"] = "Total Earning",  ["value"] = formatRP(_G.TotalEarning) .. " (Est)", ["inline"] = false},
            {["name"] = "Cycle Count",    ["value"] = tostring(_G.CycleCount),             ["inline"] = false},
            {["name"] = "Running Time",   ["value"] = getRunningTime(),                    ["inline"] = false},
            {["name"] = "FPS at Cycle",   ["value"] = string.format("%.0f fps", getFPS()), ["inline"] = false},
        },
        ["image"] = { ["url"] = "https://cdn.discordapp.com/attachments/1492837859370074192/1508063383944036433/IMG_20260524_180509.jpg?ex=6a142cf9&is=6a12db79&hm=124ec4dccb5d72326d9b0776d912bb18631948f41162cd9fa6d08eafcff19fb4&" },
        ["footer"] = { ["text"] = "Made by .projectsion | " .. os.date("%m/%d/%Y %I:%M %p") }
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

task.spawn(function()
    while true do
        local newMoney = getCleanMoney()
        if _G.AutoWebhook and newMoney > lastMoney then
            pendingIncome = pendingIncome + (newMoney - lastMoney)
            if not isRunning then
                isRunning = true
                task.spawn(function()
                    while isRunning and _G.AutoWebhook do
                        task.wait(60)
                        if pendingIncome > 0 and _G.WebhookURL ~= "" then
                            sendWebhook(pendingIncome, 0)
                            pendingIncome = 0
                        end
                        if not _G.AutoWebhook or not _G.Autofarm then
                            isRunning = false
                        end
                    end
                end)
            end
        end
        lastMoney = newMoney
        task.wait(2)
    end
end)

local function isTargetDestination(waypoint)
    if not waypoint then return false end
    local wpName = waypoint.Name:lower()
    local wpLabel = ""
    local guiText = waypoint:FindFirstChildOfClass("BillboardGui") or waypoint:FindFirstChildOfClass("SurfaceGui")
    if guiText then
        local textLabel = guiText:FindFirstChildOfClass("TextLabel")
        if textLabel then wpLabel = textLabel.Text:lower() end
    end
    local targets = {"malang", "sidoarjo", "cargo"}
    for _, t in pairs(targets) do
        if string.find(wpName, t) or string.find(wpLabel, t) then return true end
    end
    return false
end

local function runAutofarm()
    StartMoney = getCleanMoney()

    while _G.Autofarm do
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local dapetRuteBagus = false
        local attemptCount = 0

        repeat
            if not _G.Autofarm then break end
            attemptCount = attemptCount + 1

            if DelayLabel then
                DelayLabel:Set({Title = "Status:", Content = "Rolling Job (Attempt " .. tostring(attemptCount) .. ")..."})
            end

            local network = ReplicatedStorage:FindFirstChild("NetworkContainer")
            local remote = network and network:FindFirstChild("RemoteEvents") and network.RemoteEvents:FindFirstChild("Job")
            if remote then remote:FireServer("Truck") end
            task.wait(0.5)

            local etc = Workspace:FindFirstChild("Etc")
            local jobTruck = etc and etc:FindFirstChild("Job") and etc.Job:FindFirstChild("Truck")
            local starter = jobTruck and jobTruck:FindFirstChild("Starter")

            if starter and hrp then
                hrp.CFrame = starter:GetPivot()
                task.wait(0.3)
                local prompt = starter:FindFirstChild("Prompt")
                if prompt then fireproximityprompt(prompt) end
                task.wait(1.2)
            end

            local waypointFolder = etc and etc:FindFirstChild("Waypoint")
            local waypoint = waypointFolder and waypointFolder:FindFirstChild("Waypoint")

            if waypoint and isTargetDestination(waypoint) then
                dapetRuteBagus = true
            else
                if remote then remote:FireServer("Unemployed") end
                local checkTimeout = 0
                while waypointFolder and waypointFolder:FindFirstChild("Waypoint") and checkTimeout < 2 do
                    task.wait(0.2)
                    checkTimeout = checkTimeout + 0.2
                end
                task.wait(0.3)
            end
        until dapetRuteBagus or not _G.Autofarm

        if not _G.Autofarm then break end

        local spawnerPart = Workspace:WaitForChild("Etc"):WaitForChild("Job"):WaitForChild("Truck"):WaitForChild("Spawner"):WaitForChild("Part")
        hrp.CFrame = spawnerPart.CFrame
        task.wait(0.4)
        fireproximityprompt(spawnerPart:WaitForChild("Prompt"))

        task.wait(4)
        local myTruck = getMyTruck()

        if myTruck then
            hrp.CFrame = myTruck.DriveSeat.CFrame
            task.wait(0.2)
            fireproximityprompt(myTruck.DriveSeat:WaitForChild("PromptDriveSeat"))

            while _G.Autofarm do
                if not myTruck or not myTruck.Parent then break end

                local waypointFolder = Workspace:WaitForChild("Etc"):WaitForChild("Waypoint")
                local waypoint = waypointFolder:FindFirstChild("Waypoint")

                if not waypoint then task.wait(1) continue end

                if isTargetDestination(waypoint) then
                    local targetCFrame = (waypoint:IsA("Model") and waypoint:GetPivot()) or waypoint.CFrame
                    local primary = myTruck.PrimaryPart

                    if primary then
                        local dir = (targetCFrame.Position - primary.Position)
                        if dir.Magnitude > 5 then
                            primary.AssemblyLinearVelocity = dir.Unit * 70
                        end
                        primary.AssemblyAngularVelocity = Vector3.zero
                    end

                    CurrentMoney = getCleanMoney()
                    EarnedMoney = CurrentMoney - StartMoney

                    NextTeleportIn = 45
                    repeat
                        task.wait(1)
                        NextTeleportIn -= 1

                        if NextTeleportIn <= 28 and myTruck and primary then
                            primary.AssemblyLinearVelocity = Vector3.new(0, 0.05, 0)
                            for _, part in pairs(myTruck:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.AssemblyLinearVelocity = part.AssemblyLinearVelocity
                                end
                            end
                        end
                    until NextTeleportIn <= 0 or not _G.Autofarm

                    if _G.Autofarm and myTruck and myTruck.Parent then
                        local oldWaypointPos = targetCFrame.Position

                        if primary then
                            primary.AssemblyLinearVelocity = Vector3.zero
                            primary.AssemblyAngularVelocity = Vector3.zero
                        end

                        -- smooth adaptive teleport
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
                            local checkWaypoint = waypointFolder:FindFirstChild("Waypoint")
                            if not checkWaypoint or (checkWaypoint:GetPivot().Position - oldWaypointPos).Magnitude > 10 then
                                break
                            end
                        until timeout >= 4

                        break
                    end
                else
                    break
                end
            end

            if DelayLabel then
                DelayLabel:Set({Title = "Status:", Content = "Clearing old truck & job..."})
            end

            local network = ReplicatedStorage:FindFirstChild("NetworkContainer")
            local remote = network and network:FindFirstChild("RemoteEvents") and network.RemoteEvents:FindFirstChild("Job")
            if remote then remote:FireServer("Unemployed") end

            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.SeatPart then humanoid.Jump = true end

            if myTruck and myTruck.Parent then myTruck:Destroy() end

            task.wait(1.5)
        end
        task.wait(0.5)
    end
end

local Window = Rayfield:CreateWindow({
    Name = "Car Driving Indonesia | By .projectsion",
    LoadingTitle = "Projectsion Loading...",
    LoadingSubtitle = "Version 2.8 (smooth tp + fps adaptive)",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})

local FarmTab = Window:CreateTab("Autofarm", "truck")
local FarmSection = FarmTab:CreateSection("Autofarm Truck")

FarmTab:CreateToggle({
    Name = "On Autofarm Truck (yes)",
    Info = "Otomatis memfilter job hanya ke arah Malang atau Sidoarjo",
    CurrentValue = false,
    Callback = function(value)
        _G.Autofarm = value
        if _G.Autofarm then task.spawn(runAutofarm) end
    end
})

FarmTab:CreateToggle({
    Name = "Enable Black Screen Layout",
    Info = "Menghitamkan layar game (Menu UI tetap kelihatan)",
    CurrentValue = false,
    Callback = function(value) BlackScreen.Enabled = value end
})

local StatsTab = Window:CreateTab("Stats", "trending-up")
local StatsSection = StatsTab:CreateSection("Statistics")

DelayLabel     = StatsTab:CreateParagraph({Title = "Status / Next TP:",            Content = "Waiting Job..."})
TeleportLabel  = StatsTab:CreateParagraph({Title = "Total Teleport Done:",          Content = "0 Times"})
DestMinLabel   = StatsTab:CreateParagraph({Title = "Destinations (Last 1 Min):",    Content = "0"})
Dest5MinLabel  = StatsTab:CreateParagraph({Title = "Destinations (Last 5 Mins):",  Content = "0"})
IncomeHourLabel= StatsTab:CreateParagraph({Title = "Est. Income / Hour:",           Content = "RP. 0/h"})
EarnedLabel    = StatsTab:CreateParagraph({Title = "Total Earned:",                 Content = "RP. 0"})
CurrentLabel   = StatsTab:CreateParagraph({Title = "Current Money:",                Content = "RP. 0"})
local FpsLabel = StatsTab:CreateParagraph({Title = "Current FPS:",                  Content = "-- fps"})

local ProxTab = Window:CreateTab("Misc", "bot")
local NpcSection = ProxTab:CreateSection("Open NPC")

ProxTab:CreateDropdown({
    Name = "Select NPC",
    Options = { "Npc upgrade slot Npc", "Npc Box Shop", "Daily quest npc" },
    CurrentOption = {"Npc job select"},
    MultipleOptions = false,
    Callback = function(Value) SelectedNPC = Value[1] end
})

ProxTab:CreateButton({
    Name = "Open NPC UI",
    Callback = function()
        local target = NPC_Paths[SelectedNPC]
        if target then fireproximityprompt(target) end
    end
})

local DealerSection = ProxTab:CreateSection("Open Dealership")
ProxTab:CreateDropdown({
    Name = "Select Dealer",
    Options = { "Toyota", "Suzuki", "Premium", "Nissan", "Mercedes", "Komersial", "KIA", "Hyundai", "Honda", "Daihatsu", "Chery", "Bandung", "Dealer 77" },
    CurrentOption = {""},
    MultipleOptions = false,
    Callback = function(Value) SelectedDealer = Value[1] end
})

ProxTab:CreateButton({
    Name = "Open Dealer UI",
    Callback = function()
        local target = Dealer_Paths[SelectedDealer]
        if target then fireproximityprompt(target) end
    end
})

local WebhookTab = Window:CreateTab("Webhook", "webhook")
local WebhookSection = WebhookTab:CreateSection("Webhook Farm")

WebhookTab:CreateInput({
    Name = "Webhook Link",
    PlaceholderText = "Enter link webhook",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) _G.WebhookURL = Text end
})

WebhookTab:CreateToggle({
    Name = "Enable Webhook",
    Info = "Webhook ngirim setiap 1 menit",
    CurrentValue = false,
    Callback = function(value) _G.AutoWebhook = value end
})

local TpTab = Window:CreateTab("Teleport", "map-pin")
local PlayerSection = TpTab:CreateSection("Teleport Player")

local PlayerDropdown = TpTab:CreateDropdown({
    Name = "Select Player",
    Options = {},
    CurrentOption = {""},
    MultipleOptions = false,
    Callback = function(Value) SelectedPlayer = Value[1] end
})

local function refreshPlayers()
    local pList = {}
    for _, v in pairs(workspace.Lives:GetChildren()) do
        if v:IsA("Model") and v.Name ~= lp.Name then table.insert(pList, v.Name) end
    end
    PlayerDropdown:Refresh(pList, {""})
end

TpTab:CreateButton({ Name = "Refresh Player List", Callback = refreshPlayers })
TpTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        local target = workspace.Lives:FindFirstChild(SelectedPlayer)
        if target then lp.Character:PivotTo(target:GetPivot()) end
    end
})

task.spawn(refreshPlayers)

-- stats loop
task.spawn(function()
    while true do
        if _G.Autofarm and TeleportLabel then
            local current = getCleanMoney()
            EarnedMoney = current - StartMoney

            local timePassed = os.time() - _G.StartTime
            local incomePerHour = 0
            if timePassed > 5 then
                incomePerHour = math.floor((EarnedMoney / timePassed) * 3600)
            end

            local cMin  = getDestinationsInWindow(60)
            local c5Min = getDestinationsInWindow(300)
            local fps   = getFPS()

            TeleportLabel:Set({Title = "Total Teleport Done:", Content = tostring(_G.TotalTeleportCount) .. " Times"})
            DestMinLabel:Set({Title = "Destinations (Last 1 Min):", Content = tostring(cMin) .. " (Chance of Double!)"})
            Dest5MinLabel:Set({Title = "Destinations (Last 5 Mins):", Content = tostring(c5Min)})
            IncomeHourLabel:Set({Title = "Est. Income / Hour:", Content = "RP. " .. formatShort(incomePerHour)})
            EarnedLabel:Set({Title = "Total Earned:", Content = "RP. " .. formatNominal(EarnedMoney)})
            CurrentLabel:Set({Title = "Current Money:", Content = "RP. " .. formatNominal(current)})
            FpsLabel:Set({
                Title = "Current FPS:",
                Content = string.format("%.0f fps %s", fps,
                    fps < 30 and "⚠ lag — tp slowed" or
                    fps < 50 and "~ mild lag" or
                    "✓ smooth")
            })
        end
        task.wait(1.5)
    end
end)

-- countdown loop
task.spawn(function()
    while true do
        if _G.Autofarm and DelayLabel and NextTeleportIn > 0 then
            DelayLabel:Set({
                Title = "Next Teleport In:",
                Content = string.format("%d sec | %.0f fps", NextTeleportIn, getFPS())
            })
        end
        task.wait(1)
    end
end)