local VelarisUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/nhfudzfsrzggt/brigida/refs/heads/main/dist/main.lua", true))()

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

-- // Destroy Specific Prop untuk Mengurangi Beban Memori / Lag
pcall(function()
    local targetProp = workspace.Map.Prop:GetChildren()[1627]
    if targetProp then
        targetProp:Destroy()
    end
end)

-- // [GABUNGAN ASSET] Pembuatan Platform Pendukung di Bawah Map (Agar Kendaraan Stabil)
local function createPlatform(name, cframe, size)
    if Workspace:FindFirstChild(name) then Workspace[name]:Destroy() end
    local part = Instance.new("Part", Workspace)
    part.Name = name
    part.CFrame = cframe
    part.Size = size
    part.Anchored = true
    part.Transparency = 1
end

createPlatform("Tele1[STORAGE]", CFrame.new(-7932.738, 382.885, 46876.062), Vector3.new(280, 1, 280))
createPlatform("Tp Asset", CFrame.new(-7845.343, 383.014, 46865.543), Vector3.new(280, 1, 280))
createPlatform("spawn[Ngawi]", CFrame.new(34938.425, 131.505, -54576.171), Vector3.new(550, 1, 320))

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
_G.StartTime = _G.StartTime or os.time()
_G.CycleCount = _G.CycleCount or 0
_G.TotalEarning = _G.TotalEarning or 0
_G.WebhookURL = _G.WebhookURL or ""

local lastMoney = 0 
local pendingIncome = 0
local isRunning = false

local SelectedBox = "Limited Box"
local SelectedNPC = ""
local SelectedDealer = ""
local SelectedPlayer = ""

-- // Fungsi Format Angka ke Ribuan Komma
local function formatNominal(n)
    local left, num, right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
    if not left then return tostring(n) end
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

-- // Fungsi Konversi Text ke Angka Bersih
local function getCleanMoney()
    if not MoneyPath then return 0 end
    local rawText = MoneyPath.Text
    local cleanText = rawText:gsub("RP.", ""):gsub(",", ""):gsub("%s+", "")
    return tonumber(cleanText) or 0
end

task.spawn(function()
    task.wait(3) 
    lastMoney = getCleanMoney()
end)

-- // Fungsi Ambil Kendaraan Atas Nama Pemain (Lebih Universal)
local function getMyTruck()
    local vehicles = Workspace:FindFirstChild("Vehicles")
    if vehicles then
        return vehicles:FindFirstChild(lp.Name .. "sCar")
    end
    return nil
end

-- // Fungsi Trigger Proximity Prompt Aman
local function safeFirePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        fireproximityprompt(prompt)
    end
end

-- [[ ANTI-AFK SYSTEM ]]
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    lp.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- // FUNGSI WEBHOOK DATA UTILS
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

-- // FUNGSI LOG WEBHOOK DISCORD
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
        ["title"] = "Cycle Completed (Sky Velocity Mode)",
        ["color"] = 0xFFFFFF,
        ["fields"] = {
            {["name"] = "Username", ["value"] = lp.Name, ["inline"] = false},
            {["name"] = "Cycle Income", ["value"] = formatRP(income), ["inline"] = false},
            {["name"] = "Current Money", ["value"] = formatRP(currentMoney), ["inline"] = false},
            {["name"] = "Total Earning This Session", ["value"] = formatRP(_G.TotalEarning), ["inline"] = false},
            {["name"] = "Cycle Count", ["value"] = tostring(_G.CycleCount), ["inline"] = false},
            {["name"] = "Running Time", ["value"] = getRunningTime(), ["inline"] = false}
        },
        ["image"] = {
            ["url"] = "https://cdn.discordapp.com/attachments/1492837859370074192/1508063383944036433/IMG_20260524_180509.jpg"
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

-- // MONEY MONITOR UNTUK WEBHOOK
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

-- // --- FUNGSI UTAMA SKY VELOCITY FARM ---
local function runAutofarm()
    StartMoney = getCleanMoney()
    
    while _G.Autofarm do
        local char = lp.Character or lp.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid", 5)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)

        if not hrp or not humanoid then
            StatusLabel.Text = "Error: Character Loading Slow"
            task.wait(1)
            continue
        end

        -- JIKA PEMAIN DI LUAR KENDARAAN (Proses Ambil & Spawn Truk)
        if humanoid.SeatPart == nil then
            StatusLabel.Text = "Initializing Truck Job..."
            
            -- 1. Ambil Job ke Server
            local network = ReplicatedStorage:WaitForChild("NetworkContainer", 5)
            local remote = network and network:WaitForChild("RemoteEvents", 5) and network.RemoteEvents:WaitForChild("Job", 5)
            if remote then
                remote:FireServer("Truck")
            end
            task.wait(0.5)

            -- 2. Ambil Jalur Folder Kerja
            local etcFolder = Workspace:WaitForChild("Etc", 5)
            local jobFolder = etcFolder and etcFolder:WaitForChild("Job", 5) and etcFolder.Job:WaitForChild("Truck", 5)
            if not jobFolder then
                StatusLabel.Text = "Error: Map Folder Changed!"
                task.wait(3)
                continue
            end

            -- 3. Trigger Starter Job
            local starter = jobFolder:WaitForChild("Starter", 5)
            if starter then
                hrp.CFrame = starter:GetPivot()
                hrp.Anchored = true
                task.wait(1)
                hrp.Anchored = false
                
                local waypointFolder = etcFolder:WaitForChild("Waypoint", 5)
                if waypointFolder and waypointFolder:FindFirstChild("Waypoint") then
                    local prepos = waypointFolder.Waypoint.Position
                    local timeout = 0
                    repeat 
                        safeFirePrompt(starter:FindFirstChild("Prompt"))
                        task.wait(0.5)
                        timeout = timeout + 1
                    until (waypointFolder.Waypoint.Position ~= prepos) or not _G.Autofarm or timeout > 10
                end
            end
            task.wait(1)

            -- 4. Trigger Spawner Kendaraan
            local spawner = jobFolder:WaitForChild("Spawner", 5)
            local spawnerPart = spawner and spawner:WaitForChild("Part", 5)
            if spawnerPart then
                hrp.CFrame = spawnerPart.CFrame
                task.wait(1)
                
                local timeout = 0
                repeat
                    safeFirePrompt(spawnerPart:FindFirstChild("Prompt"))
                    task.wait(0.5)
                    timeout = timeout + 1
                until getMyTruck() or not _G.Autofarm or timeout > 15
            end
            task.wait(1)

            -- 5. Masuk Otomatis ke Kursi Pengemudi
            local myTruck = getMyTruck()
            if myTruck then
                local driveSeat = myTruck:WaitForChild("DriveSeat", 5)
                if driveSeat then
                    local timeout = 0
                    repeat
                        pcall(function() driveSeat:Sit(humanoid) end)
                        task.wait(0.5)
                        timeout = timeout + 1
                    until humanoid.SeatPart ~= nil or not _G.Autofarm or timeout > 10
                end
            end

        -- JIKA PEMAIN SUDAH BERADA DI DALAM TRUK (Proses Pengantaran Jalur Langit)
        elseif humanoid.SeatPart ~= nil then
            local seat = humanoid.SeatPart
            local car = seat.Parent
            local primary = car.PrimaryPart or car:FindFirstChild("DriveSeat")
            
            local etcFolder = Workspace:FindFirstChild("Etc")
            local waypointFolder = etcFolder and etcFolder:FindFirstChild("Waypoint")
            local waypoint = waypointFolder and waypointFolder:FindFirstChild("Waypoint")
            
            if primary and waypoint then
                -- Langkah A: Terbangkan Truk ke Atas Langit (Gunakan CFrame Properti, BUKAN PivotTo)
                local skyHeight = 650
                local startPos = primary.Position
                
                primary.CFrame = CFrame.new(startPos.X, skyHeight, startPos.Z)
                task.wait(0.2)
                
                -- Langkah B: Laju Menuju Koordinat Waypoint Menggunakan Gabungan Velocity Fisika & CFrame Orien
                local targetPos = waypoint.Position
                local targetSkyPos = Vector3.new(targetPos.X, skyHeight, targetPos.Z)
                
                local speed = 145 -- Batas kecepatan aman penyamaran server
                local distance = (primary.Position - targetSkyPos).Magnitude
                
                while distance > 15 and _G.Autofarm and humanoid.SeatPart ~= nil do
                    if not car.Parent then break end
                    
                    local currentPos = primary.Position
                    local direction = (targetSkyPos - currentPos).Unit
                    distance = (targetSkyPos - currentPos).Magnitude
                    StatusLabel.Text = "Sky-Bypassing: " .. math.floor(distance) .. "m Left"
                    
                    -- Update rotasi menghadap target dan suntik kecepatan linear
                    primary.CFrame = CFrame.lookAt(currentPos, targetSkyPos)
                    primary.AssemblyLinearVelocity = direction * speed
                    primary.AssemblyAngularVelocity = Vector3.zero
                    task.wait()
                end
                
                -- Langkah C: Landaskan Truk Kembali Menggunakan Properti .CFrame Langsung di Atas Checkpoint Bumi
                if _G.Autofarm and car.Parent then
                    primary.AssemblyLinearVelocity = Vector3.zero
                    primary.AssemblyAngularVelocity = Vector3.zero
                    
                    primary.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                    task.wait(0.5)
                    
                    -- Sistem Cooldown Deteksi Keamanan Gaji Server (Dihubungkan Langsung ke Loop UI Detik)
                    local prepos = waypoint.Position
                    NextTeleportIn = math.random(50, 55)
                    
                    while waypoint.Position == prepos and _G.Autofarm and NextTeleportIn > 0 do
                        StatusLabel.Text = "Waiting Payout: " .. tostring(NextTeleportIn) .. "s"
                        task.wait(1)
                        NextTeleportIn = NextTeleportIn - 1
                    end
                    NextTeleportIn = 0
                end
            end
        end
        task.wait(0.5)
    end
    StatusLabel.Text = "Autofarm Stopped"
end

-- [[ INTERFACE MENCIPTAKAN WINDOW VELARISUI ]] --
local Window = VelarisUI:Window({
    Title     = "Car Driving Indonesia",
    Footer    = "By .projectsion",
    Color     = "Dark",            
    Version   = "2.0 (Sky Velocity)",
    Image     = "75533822533623",    
    Size      = UDim2.fromOffset(640, 400),
    ShowUser  = true,                  
    Search    = true,                  
    Animation = true,
})

local FarmTab = Window:AddTab({ Name = "Autofarm", Icon = "projectsion:truck" })
local FarmSection = FarmTab:AddSection({ Title = "Autofarm Truck Sky", Open = true })

FarmSection:AddToggle({
    Title    = "On Autofarm Truck",
    Content  = "Metode terbang tinggi bypass anti-cheat fisis",
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

-- // Loop Sinkronisasi Teks Parameter Statistik UI
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
        if _G.Autofarm then 
            DelayLabel:SetContent(tostring(NextTeleportIn) .. " Seconds") 
        else
            DelayLabel:SetContent("0 Seconds")
        end
        task.wait(1)
    end
end)
