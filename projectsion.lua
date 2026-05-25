local VelarisUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/nhfudzfsrzggt/brigida/refs/heads/main/dist/main.lua", true))()
-- // Destroy Specific Prop
local targetProp = workspace.Map.Prop:GetChildren()[1627]
if targetProp then
    targetProp:Destroy()
end

-- // Black Screen Setup
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

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

-- // Config & Stats Variables
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

local lastMoney = 0 
local pendingIncome = 0
local isRunning = false

task.spawn(function()
    task.wait(3)
    lastMoney = getCleanMoney()
end)

local SelectedBox = "Limited Box"
local SelectedNPC = ""
local SelectedDealer = ""
local SelectedPlayer = ""
local SelectedNpcTp = ""
local SelectedDealerTp = ""
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

-- // Fungsi Format Angka
local function formatNominal(n)
    local left, num, right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
    if not left then return tostring(n) end
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

-- // Fungsi Konversi Text ke Angka
local function getCleanMoney()
    local rawText = MoneyPath.Text
    local cleanText = rawText:gsub("RP.", ""):gsub(",", ""):gsub("%s+", "")
    return tonumber(cleanText) or 0
end

-- // Fungsi Cari Truck
local function getMyTruck()
    for _, v in pairs(Workspace:WaitForChild("Vehicles"):GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("DriveSeat") then
            return v
        end
    end
    return nil
end

-- [[ ANTI-AFK SYSTEM ]]
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- // FUNGSI AUTO-AVATAR
local function getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. lp.UserId .. "&width=420&height=420&format=png"
end

-- // FORMAT RUPIAH
local function formatRP(v)
    local s = string.format("%.0f", v)
    local formatted = s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    return "RP. " .. formatted
end

-- // RUNNING TIME
local function getRunningTime()
    local diff = os.time() - _G.StartTime
    local hours = math.floor(diff / 3600)
    local mins = math.floor((diff % 3600) / 60)
    local secs = diff % 60
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

-- // FUNGSI WEBHOOK
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
            {["name"] = "Username", ["value"] = lp.Name, ["inline"] = false},
            {["name"] = "Cycle Income", ["value"] = formatRP(income), ["inline"] = false},
            {["name"] = "Target", ["value"] = formatRP(target), ["inline"] = false},
            {["name"] = "Current Money", ["value"] = formatRP(currentMoney) .. " (Est)", ["inline"] = false},
            {["name"] = "Total Earning", ["value"] = formatRP(_G.TotalEarning) .. " (Est)", ["inline"] = false},
            {["name"] = "Cycle Count", ["value"] = tostring(_G.CycleCount), ["inline"] = false},
            {["name"] = "Running Time", ["value"] = getRunningTime(), ["inline"] = false}
        },
        ["image"] = { ["url"] = "https://cdn.discordapp.com/attachments/1492837859370074192/1508063383944036433/IMG_20260524_180509.jpg?ex=6a142cf9&is=6a12db79&hm=124ec4dccb5d72326d9b0776d912bb18631948f41162cd9fa6d08eafcff19fb4&" },
        ["footer"] = { ["text"] = "Made by .projectsion | " .. os.date("%m/%d/%Y %I:%M %p") }
    }
    local payload = HttpService:JSONEncode({ ["username"] = "Projectsion Reports", ["embeds"] = {embed} })
    if http_request then
        pcall(function()
            http_request({ Url = _G.WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload })
        end)
    end
end

-- // MONEY MONITOR
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

-- // STEP TELEPORT PLAYER
local function StepTeleportChar(hrp, targetCF, steps, interval)
    steps    = steps    or 10
    interval = interval or 0.1
    local startCF = hrp.CFrame
    for i = 1, steps do
        hrp.CFrame = startCF:Lerp(targetCF, i / steps)
        task.wait(interval)
    end
    hrp.CFrame = targetCF
end

-- // MOVE TRUCK PHYSICS (anti-detect)
local function MoveTruckPhysics(truck, targetCF)
    local root = truck.PrimaryPart
    if not root then return end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Parent = root

    local speed = 80
    local target = targetCF.Position
    local elapsed = 0
    local maxTime = (root.Position - target).Magnitude / speed + 5

    while elapsed < maxTime do
        local dt = task.wait(0.1)
        elapsed = elapsed + dt
        local dir = (target - root.Position).Unit
        bv.Velocity = dir * speed
        if (root.Position - target).Magnitude < 5 then break end
    end

    bv:Destroy()
    truck:PivotTo(targetCF)
    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end

-- // FUNGSI UTAMA FARM
local function runAutofarm()
    StartMoney = getCleanMoney()

    while _G.Autofarm do
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        -- 1. Ambil Job
        task.wait(math.random(1, 2))
        ReplicatedStorage:WaitForChild("NetworkContainer"):WaitForChild("RemoteEvents"):WaitForChild("Job"):FireServer("Truck")
        task.wait(math.random(3, 4))

        -- 2. Starter
        local starter = Workspace:WaitForChild("Etc"):WaitForChild("Job"):WaitForChild("Truck"):WaitForChild("Starter")
        StepTeleportChar(hrp, starter:GetPivot(), 10, 0.1)
        task.wait(math.random(2, 3))
        fireproximityprompt(starter:WaitForChild("Prompt"))
        task.wait(math.random(2, 3))

        -- 3. Spawner
        local spawnerPart = Workspace:WaitForChild("Etc"):WaitForChild("Job"):WaitForChild("Truck"):WaitForChild("Spawner"):WaitForChild("Part")
        StepTeleportChar(hrp, spawnerPart.CFrame, 10, 0.1)
        task.wait(math.random(2, 3))
        fireproximityprompt(spawnerPart:WaitForChild("Prompt"))

        -- 4. Masuk Truck & Loop Teleport
        task.wait(math.random(4, 6))
        local myTruck = getMyTruck()

        if myTruck then
            StepTeleportChar(hrp, myTruck.DriveSeat.CFrame, 8, 0.1)
            task.wait(math.random(1, 2))
            fireproximityprompt(myTruck.DriveSeat:WaitForChild("PromptDriveSeat"))
            task.wait(math.random(1, 2))

            while _G.Autofarm do
                if not myTruck or not myTruck.Parent then break end

                local waypoint = Workspace:WaitForChild("Etc"):WaitForChild("Waypoint"):WaitForChild("Waypoint")
                local targetCF = (waypoint:IsA("Model") and waypoint:GetPivot()) or waypoint.CFrame

                -- Gerak truck pakai physics
                MoveTruckPhysics(myTruck, targetCF)
                task.wait(math.random(1, 2))

                -- Coba fire waypoint prompt
                local prompt = waypoint:FindFirstChildWhichIsA("ProximityPrompt")
                    or waypoint:FindFirstChild("Prompt")
                if prompt then
                    local hrp2 = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if hrp2 then
                        StepTeleportChar(hrp2, targetCF, 10, 0.1)
                        task.wait(math.random(1, 2))
                        fireproximityprompt(prompt)
                        task.wait(math.random(1, 2))
                    end
                end

                CurrentMoney = getCleanMoney()
                EarnedMoney = CurrentMoney - StartMoney

                -- Countdown Delay
                NextTeleportIn = math.random(45, 55)
                repeat
                    task.wait(1)
                    NextTeleportIn = NextTeleportIn - 1
                until NextTeleportIn <= 0 or not _G.Autofarm
            end
        end
        if not _G.Autofarm then break end
        task.wait(1)
    end
end

-- [[ GUI VELARIS ]] --
local Window = VelarisUI:Window({
    Title     = "Car Driving Indonesia",
    Footer    = "By .projectsion",
    Color     = "Dark",
    Version   = "1.6",
    Image     = "75533822533623",
    Size      = UDim2.fromOffset(640, 400),
    ShowUser  = true,
    Search    = true,
    Animation = true,
})

local FarmTab = Window:AddTab({ Name = "Autofarm", Icon = "projectsion:truck" })
local FarmSection = FarmTab:AddSection({ Title = "Autofarm Truck", Open = true })

FarmSection:AddToggle({
    Title    = "On Autofarm Truck",
    Content  = "Autofarm truck tanpa stuck",
    Default  = false,
    Callback = function(value)
        _G.Autofarm = value
        BlackScreen.Enabled = value
        if _G.Autofarm then
            task.spawn(runAutofarm)
        end
    end
})

local StatsTab = Window:AddTab({ Name = "Stats", Icon = "projectsion:trending-up" })
local StatsSection = StatsTab:AddSection({ Title = "Statistics", Open = true })
local DelayLabel = StatsSection:AddParagraph({ Title = "Next Teleport In:", Content = "0 Seconds" })
local EarnedLabel = StatsSection:AddParagraph({ Title = "Total Earned:", Content = "RP. 0" })
local CurrentLabel = StatsSection:AddParagraph({ Title = "Current Money:", Content = "RP. 0" })

local ProxTab = Window:AddTab({ Name = "automation", Icon = "projectsion:bot" })
local NpcSection = ProxTab:AddSection({ Title = "Open npc", Open = true })
NpcSection:AddDropdown({
    Title    = "Select npc",
    Options  = { "Npc upgrade slot Npc", "Npc Box Shop", "Daily quest npc" },
    Default  = "Npc job select",
    Callback = function(value) SelectedNPC = value end
})
NpcSection:AddButton({
    Title    = "Open npc",
    Callback = function()
        local target = NPC_Paths[SelectedNPC]
        if target then fireproximityprompt(target) end
    end
})

local DealerSection = ProxTab:AddSection({ Title = "Open dealership", Open = true })
DealerSection:AddDropdown({
    Title    = "Select Dealer",
    Options  = { "Toyota", "Suzuki", "Premium", "Nissan", "Mercedes", "Komersial", "KIA", "Hyundai", "Honda", "Daihatsu", "Chery", "Bandung", "Dealer 77" },
    Default  = "",
    Callback = function(value) SelectedDealer = value end
})
DealerSection:AddButton({
    Title    = "Open Dealer UI",
    Callback = function()
        local target = Dealer_Paths[SelectedDealer]
        if target then fireproximityprompt(target) end
    end
})

local GachaSection = ProxTab:AddSection({ Title = "Gacha Box", Open = true })
GachaSection:AddDropdown({
    Title    = "Select Action / Box",
    Options  = { "Limited Box", "Gamepass Box", "Minigame Box", "Claim" },
    Default  = "Limited Box",
    Callback = function(value) SelectedBox = value end
})
GachaSection:AddToggle({
    Title    = "auto gacha box",
    Content  = "Automatic Buy Box",
    Default  = false,
    Callback = function(value)
        _G.AutoGacha = value
        if _G.AutoGacha then
            task.spawn(function()
                while _G.AutoGacha do
                    if SelectedBox ~= "Claim" then
                        game:GetService("ReplicatedStorage").NetworkContainer.RemoteEvents.Box:FireServer("Buy", SelectedBox)
                        task.wait(0.5)
                        game:GetService("ReplicatedStorage").NetworkContainer.RemoteEvents.Box:FireServer("Claim")
                    end
                    task.wait(1.5)
                end
            end)
        end
    end
})
GachaSection:AddButton({
    Title    = "Execute Selection",
    Callback = function()
        local Remote = game:GetService("ReplicatedStorage").NetworkContainer.RemoteEvents.Box
        if SelectedBox == "Claim" then
            Remote:FireServer("Claim")
        else
            Remote:FireServer("Buy", SelectedBox)
        end
    end
})

local WebhookTab = Window:AddTab({ Name = "Webhook ", Icon = "projectsion:webhook" })
local WebhookSection = WebhookTab:AddSection({ Title = "Webhook farm ", Open = true })
WebhookSection:AddInput({
    Title    = "webhook",
    Content  = "Enter link webhook",
    Default  = "",
    Callback = function(value) _G.WebhookURL = value end
})
WebhookSection:AddToggle({
    Title    = "enable webhook",
    Content  = "webhook ngirim setiap 1 menit",
    Default  = false,
    Callback = function(value) _G.AutoWebhook = value end
})

-- TAB TELEPORT
local TpTab = Window:AddTab({ Name = "Teleport", Icon = "projectsion:map-pin" })

local PlayerSection = TpTab:AddSection({ Title = "Teleport Player", Open = true })
local PlayerDropdown = PlayerSection:AddDropdown({
    Title    = "Select Player",
    Options  = {},
    Default  = "",
    Callback = function(value) SelectedPlayer = value end
})

local function refreshPlayers()
    local pList = {}
    for _, v in pairs(workspace.Lives:GetChildren()) do
        if v:IsA("Model") and v.Name ~= lp.Name then
            table.insert(pList, v.Name)
        end
    end
    PlayerDropdown:SetValues(pList)
end

PlayerSection:AddButton({ Title = "Refresh Player List", Callback = refreshPlayers })
PlayerSection:AddButton({
    Title    = "Teleport to Player",
    Callback = function()
        local target = workspace.Lives:FindFirstChild(SelectedPlayer)
        if target then lp.Character:PivotTo(target:GetPivot()) end
    end
})

local SaveSection = TpTab:AddSection({ Title = "Saved Location", Open = false })
local LocationStatus = SaveSection:AddParagraph({ Title = "Status:", Content = "No Location Saved" })
SaveSection:AddButton({
    Title    = "Get Location Now",
    Callback = function()
        SavedPos = lp.Character:GetPivot()
        LocationStatus:SetContent("Location Saved Successfully!")
    end
})
SaveSection:AddButton({
    Title    = "Teleport to Saved Location",
    Callback = function()
        if SavedPos then
            lp.Character:PivotTo(SavedPos)
        else
            LocationStatus:SetContent("Error: Save a location first!")
        end
    end
})
SaveSection:AddButton({
    Title    = "Reset Saved Location",
    Callback = function()
        SavedPos = nil
        LocationStatus:SetContent("No Location Saved")
    end
})

local NpcOnlyTp = TpTab:AddSection({ Title = "Teleport NPC", Open = false })
NpcOnlyTp:AddDropdown({
    Title    = "Select NPC",
    Options  = { "Npc job select", "Npc upgrade slot Npc", "Npc Box Shop", "Daily quest npc" },
    Default  = "Npc job select",
    Callback = function(value) SelectedNpcTp = value end
})
NpcOnlyTp:AddButton({
    Title    = "Teleport to NPC",
    Callback = function()
        local target = NPC_Paths[SelectedNpcTp]
        if target then lp.Character:PivotTo(target.Parent:GetPivot()) end
    end
})

local DealerOnlyTp = TpTab:AddSection({ Title = "Teleport Dealership", Open = false })
DealerOnlyTp:AddDropdown({
    Title    = "Select Dealer",
    Options  = { "Toyota", "Suzuki", "Premium", "Nissan", "Mercedes", "Komersial", "KIA", "Hyundai", "Honda", "Daihatsu", "Chery", "Bandung", "Dealer 77", "Modification" },
    Default  = "Toyota",
    Callback = function(value) SelectedDealerTp = value end
})
DealerOnlyTp:AddButton({
    Title    = "Teleport to Dealer",
    Callback = function()
        local target = Dealer_Paths[SelectedDealerTp]
        if target then
            local pos = (target:IsA("ProximityPrompt") and target.Parent:GetPivot()) or target:GetPivot()
            lp.Character:PivotTo(pos)
        end
    end
})

task.spawn(refreshPlayers)

-- // UPDATE UI STATS
task.spawn(function()
    while true do
        if _G.Autofarm then
            local current = getCleanMoney()
            EarnedMoney = current - StartMoney
            EarnedLabel:SetContent("RP. " .. formatNominal(EarnedMoney))
            CurrentLabel:SetContent("RP. " .. formatNominal(current))
        end
        task.wait(2)
    end
end)

-- // UPDATE UI TIMER
task.spawn(function()
    while true do
        if _G.Autofarm then
            DelayLabel:SetContent(tostring(NextTeleportIn) .. " Seconds")
        end
        task.wait(1)
    end
end)