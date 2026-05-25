local VelarisUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/nhfudzfsrzggt/brigida/refs/heads/main/dist/main.lua", true))()

-- // Destroy Specific Prop
pcall(function()
    local targetProp = workspace.Map.Prop:GetChildren()[1627]
    if targetProp then
        targetProp:Destroy()
    end
end)

-- // Black Screen Setup
local BlackScreen = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local StatusLabel = Instance.new("TextLabel")

BlackScreen.Name = "ProjectsionBlackout"
BlackScreen.Parent = game:GetService("CoreGui")
BlackScreen.DisplayOrder = -1 
BlackScreen.Enabled = false 

Frame.Parent = BlackScreen
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.Size = UDim2.new(1.5, 0, 1.5, 0) 
Frame.Position = UDim2.new(-0.25, 0, -0.25, 0)
Frame.BorderSizePixel = 0

StatusLabel.Parent = Frame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0.25, 0, 0.4, 0)
StatusLabel.Size = UDim2.new(0.5, 0, 0.1, 0)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 28
StatusLabel.Text = "Waiting for Farm..."
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center

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

local getCleanMoney

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

-- Jalur proxy menggunakan pcall aman
local function safeGetPath(parent, name)
    return parent and parent:FindFirstChild(name)
end

-- // Fungsi Format Angka
local function formatNominal(n)
    local left, num, right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
    if not left then return tostring(n) end
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

-- // Fungsi Konversi Text ke Angka
function getCleanMoney()
    if not MoneyPath then return 0 end
    local rawText = MoneyPath.Text
    local cleanText = rawText:gsub("RP.", ""):gsub(",", ""):gsub("%s+", "")
    return tonumber(cleanText) or 0
end

-- // Fungsi Cari Truck
local function getMyTruck()
    local vehicles = Workspace:FindFirstChild("Vehicles")
    if vehicles then
        for _, v in pairs(vehicles:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("DriveSeat") then
                return v
            end
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

-- // 2. FUNGSI AUTO-AVATAR
local function getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. lp.UserId .. "&width=420&height=420&format=png"
end

-- // 3. FORMAT RUPIAH
local function formatRP(v)
    local s = string.format("%.0f", v)
    local formatted = s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    return "RP. " .. formatted
end

-- // 4. RUNNING TIME
local function getRunningTime()
    local diff = os.time() - _G.StartTime
    local hours = math.floor(diff / 3600)
    local mins = math.floor((diff % 3600) / 60)
    local secs = diff % 60
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

-- // 5. FUNGSI WEBHOOK
local function sendWebhook(income, target)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    
    _G.CycleCount = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income
    
    local currentMoney = getCleanMoney()
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    local HttpService = game:GetService("HttpService")

    local embed = {
        ["author"] = {
            ["name"] = "Projectsion Webhook",
            ["icon_url"] = getAvatar()
        },
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
        ["image"] = {
            ["url"] = "https://cdn.discordapp.com/attachments/1492837859370074192/1508063383944036433/IMG_20260524_180509.jpg?ex=6a142cf9&is=6a12db79&hm=124ec4dccb5d72326d9b0776d912bb18631948f41162cd9fa6d08eafcff19fb4&"
        },
        ["footer"] = {
            ["text"] = "Made by .projectsion | " .. os.date("%m/%d/%Y %I:%M %p")
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

-- // 6. MONEY MONITOR
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

-- // --- FUNGSI UTAMA FARM ---
local function runAutofarm()
    StartMoney = getCleanMoney()
    
    while _G.Autofarm do
        StatusLabel.Text = "Initializing Truck Job..."
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)

        if not hrp then
            StatusLabel.Text = "Error: Character Loading Slow"
            task.wait(1)
            continue
        end

        -- 1. Ambil Job (Safe Check)
        local network = ReplicatedStorage:WaitForChild("NetworkContainer", 5)
        local remote = network and network:WaitForChild("RemoteEvents", 5) and network.RemoteEvents:WaitForChild("Job", 5)
        
        if remote then
            remote:FireServer("Truck")
        else
            StatusLabel.Text = "Error: Job Remote Missing!"
            task.wait(2)
        end
        task.wait(1.5)

        -- 2. Check Jalur Folder Map untuk mencegah Stuck Infinitas
        local etcFolder = Workspace:WaitForChild("Etc", 5)
        local jobFolder = etcFolder and etcFolder:WaitForChild("Job", 5) and etcFolder.Job:WaitForChild("Truck", 5)
        
        if not jobFolder then
            StatusLabel.Text = "Error: Map Folder Changed!"
            task.wait(3)
            continue
        end

        -- 3. Starter Job
        local starter = jobFolder:WaitForChild("Starter", 5)
        local starterPrompt = starter and starter:WaitForChild("Prompt", 5)
        if starterPrompt then
            hrp.CFrame = starter:GetPivot()
            task.wait(1)
            fireproximityprompt(starterPrompt)
        else
            StatusLabel.Text = "Error: Starter Prompt Missing!"
            task.wait(2)
            continue
        end
        task.wait(2)

        -- 4. Spawner Job
        local spawner = jobFolder:WaitForChild("Spawner", 5)
        local spawnerPart = spawner and spawner:WaitForChild("Part", 5)
        local spawnerPrompt = spawnerPart and spawnerPart:WaitForChild("Prompt", 5)
        if spawnerPrompt then
            hrp.CFrame = spawnerPart.CFrame
            task.wait(1)
            fireproximityprompt(spawnerPrompt)
        else
            StatusLabel.Text = "Error: Spawner Prompt Missing!"
            task.wait(2)
            continue
        end

        -- 5. Masuk Truck & Loop Teleport
        task.wait(4)
        local myTruck = getMyTruck()
        
        if myTruck then
            local seat = myTruck:WaitForChild("DriveSeat", 5)
            local seatPrompt = seat and seat:WaitForChild("PromptDriveSeat", 5)
            
            if seatPrompt then
                hrp.CFrame = seat.CFrame
                task.wait(0.5)
                fireproximityprompt(seatPrompt)
            end
            
            while _G.Autofarm do
                if not myTruck or not myTruck.Parent then break end

                local waypointFolder = etcFolder:WaitForChild("Waypoint", 3)
                local waypoint = waypointFolder and waypointFolder:FindFirstChild("Waypoint")
                
                if not waypoint then
                    StatusLabel.Text = "Waiting for Waypoint..."
                    task.wait(1)
                    continue
                end

                local targetCF = (waypoint:IsA("Model") and waypoint:GetPivot()) or waypoint.CFrame
                StatusLabel.Text = "Bypassing Server Detection..."
                
                local currentCF = myTruck:GetPivot()
                local distance = (targetCF.Position - currentCF.Position).Magnitude
                local direction = (targetCF.Position - currentCF.Position).Unit
                
                local maxSpeed = 42   
                local chunkDist = 4.5 
                local steps = math.floor(distance / chunkDist)
                local stepDelay = chunkDist / maxSpeed
                
                for i = 1, steps do
                    if not _G.Autofarm or not myTruck or not myTruck.Parent then break end
                    
                    local nextCF
                    if i == steps then
                        nextCF = targetCF
                    else
                        nextCF = currentCF + (direction * chunkDist * i)
                        nextCF = CFrame.new(nextCF.Position, nextCF.Position + direction)
                    end
                    
                    myTruck:PivotTo(nextCF)
                    if myTruck.PrimaryPart then
                        myTruck.PrimaryPart.AssemblyLinearVelocity = direction * maxSpeed
                    end
                    task.wait(stepDelay)
                end
                
                if _G.Autofarm and myTruck and myTruck.Parent and myTruck.PrimaryPart then
                    myTruck.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
                    myTruck.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
                end
                
                CurrentMoney = getCleanMoney()
                EarnedMoney = CurrentMoney - StartMoney

                NextTeleportIn = math.random(50, 55)
                repeat
                    StatusLabel.Text = "Next Teleport In: " .. tostring(NextTeleportIn) .. " Seconds"
                    task.wait(1)
                    NextTeleportIn = NextTeleportIn - 1
                until NextTeleportIn <= 0 or not _G.Autofarm
            end
        end
        if not _G.Autofarm then break end
        task.wait(1)
    end
    StatusLabel.Text = "Autofarm Stopped"
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

-- Pemetaan Dinamis agar tidak error saat di-klik jika aset game berubah
local Dealer_Paths = {
    ["Toyota"] = "workspace.Etc.Dealership.Toyota.Prompt",
    ["Suzuki"] = "workspace.Etc.Dealership.Suzuki.Prompt",
    ["Premium"] = "workspace.Etc.Dealership.Premium.Prompt",
    ["Nissan"] = "workspace.Etc.Dealership.Nissan.Prompt",
    ["Mercedes"] = "workspace.Etc.Dealership.MercedesBenz.Prompt",
    ["Komersial"] = "workspace.Etc.Dealership.Komersial.Prompt",
    ["KIA"] = "workspace.Etc.Dealership.KIA.Prompt",
    ["Hyundai"] = "workspace.Etc.Dealership.Hyundai.Prompt",
    ["Honda"] = "workspace.Etc.Dealership.Honda.Prompt",
    ["Daihatsu"] = "workspace.Etc.Dealership.Daihatsu.Prompt",
    ["Chery"] = "workspace.Etc.Dealership.Chery.Prompt",
    ["Bandung"] = "workspace.Etc.Dealership.Bandung.Prompt",
    ["Dealer 77"] = "workspace.Etc.Dealership['77'].Prompt",
    ["Modification"] = "workspace.Map.Building.Modification"
}

local ProxTab = Window:AddTab({ Name = "automation", Icon = "projectsion:bot" })
local NpcSection = ProxTab:AddSection({ Title = "Open npc", Open = true })
NpcSection:AddDropdown({
    Title    = "Select npc",
    Options  = { "Npc upgrade slot Npc", "Npc Box Shop","Daily quest npc" },
    Default  = "Npc job select",
    Callback = function(value) SelectedNPC = value end
})

NpcSection:AddButton({
    Title    = "Open npc",
    Callback = function()
        pcall(function()
            local target
            if SelectedNPC == "Npc upgrade slot Npc" then target = workspace.Etc.Upgrade.Upgrade.Prompt
            elseif SelectedNPC == "Npc Box Shop" then target = workspace.Etc.NPC.BOXSHOP.ProximityPrompt
            elseif SelectedNPC == "Daily quest npc" then target = workspace.Asset.DailyQuest.NPC.ProximityPrompt
            end
            if target then fireproximityprompt(target) end
        end)
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
        pcall(function()
            local dFolder = workspace.Etc.Dealership
            local target
            if SelectedDealer == "Dealer 77" then target = dFolder["77"].Prompt
            elseif dFolder:FindFirstChild(SelectedDealer) then target = dFolder[SelectedDealer].Prompt
            end
            if target then fireproximityprompt(target) end
        end)
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
                    pcall(function()
                        if SelectedBox ~= "Claim" then
                            ReplicatedStorage.NetworkContainer.RemoteEvents.Box:FireServer("Buy", SelectedBox)
                            task.wait(0.5)
                            ReplicatedStorage.NetworkContainer.RemoteEvents.Box:FireServer("Claim")
                        end
                    end)
                    task.wait(1.5)
                end
            end)
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
    local lives = workspace:FindFirstChild("Lives")
    if lives then
        for _, v in pairs(lives:GetChildren()) do
            if v:IsA("Model") and v.Name ~= lp.Name then table.insert(pList, v.Name) end
        end
    end
    PlayerDropdown:SetValues(pList)
end

PlayerSection:AddButton({ Title = "Refresh Player List", Callback = refreshPlayers })
PlayerSection:AddButton({
    Title    = "Teleport to Player",
    Callback = function()
        local lives = workspace:FindFirstChild("Lives")
        local target = lives and lives:FindFirstChild(SelectedPlayer)
        if target then lp.Character:PivotTo(target:GetPivot()) end
    end
})

task.spawn(refreshPlayers)

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

task.spawn(function()
    while true do
        if _G.Autofarm then DelayLabel:SetContent(tostring(NextTeleportIn) .. " Seconds") end
        task.wait(1)
    end
end)
