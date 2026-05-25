-- [[ VORTEX HUB PREMIUM — HIGH-TIER ENTERPRISE EDITION ]] --
-- // Base: Projectsion Remastered (Jawa Timur Route Upgrade)
-- // Target Komersial: Velocity Bypass, Fast-Cycle, & Full Webhook Logs

local VelarisUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/nhfudzfsrzggt/brigida/refs/heads/main/dist/main.lua", true))()

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

-- // Mengurangi Beban Memori Map
pcall(function()
    local targetProp = workspace.Map.Prop:GetChildren()[1627]
    if targetProp then targetProp:Destroy() end
end)

-- // Pembuatan Platform Pendukung di Bawah Map (Bypass Stabilitas)
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

-- // Black Screen Setup (Optimasi FPS Pembeli)
local BlackScreen = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local StatusLabel = Instance.new("TextLabel")

BlackScreen.Name = "VortexBlackout"
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
StatusLabel.TextColor3 = Color3.fromRGB(255, 83, 112)
StatusLabel.TextSize = 28
StatusLabel.Text = "VORTEX HUB - Waiting for Farm..."
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center

-- // Global Configuration Variables
_G.Autofarm = false
_G.AutoWebhook = false
_G.WebhookURL = _G.WebhookURL or ""
_G.StartTime = _G.StartTime or os.time()
_G.CycleCount = _G.CycleCount or 0
_G.TotalEarning = _G.TotalEarning or 0

local MoneyPath = lp.PlayerGui:WaitForChild("Main"):WaitForChild("Container"):WaitForChild("Hub"):WaitForChild("CashFrame"):WaitForChild("Frame"):WaitForChild("TextLabel")
local lastMoney = 0 
local pendingIncome = 0
local isRunning = false
local TargetVelocitySpeed = 235 -- Mengikuti standarisasi kecepatan Aroel/Sansunner
local SafeSkyHeight = 820

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

-- // Fungsi Ambil Kendaraan Atas Nama Pemain
local function getMyTruck()
    local vehicles = Workspace:FindFirstChild("Vehicles")
    return vehicles and vehicles:FindFirstChild(lp.Name .. "sCar")
end

-- // Fungsi Trigger Proximity Prompt Aman
local function safeFirePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        fireproximityprompt(prompt)
    end
end

-- // UTILS WEBHOOK DISCORD
local function getAvatar() return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. lp.UserId .. "&width=420&height=420&format=png" end
local function formatRP(v) return "RP. " .. tostring(v):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "") end
local function getRunningTime()
    local diff = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d", math.floor(diff / 3600), math.floor((diff % 3600) / 60), diff % 60)
end

local function sendWebhook(income)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    _G.CycleCount = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income
    
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    if not http_request then return end

    local payload = game:GetService("HttpService"):JSONEncode({
        ["username"] = "Vortex Hub Reports",
        ["embeds"] = {{
            ["author"] = {["name"] = "Vortex Hub Premium", ["icon_url"] = getAvatar()},
            ["title"] = "🚀 Fast Cargo Cycle Completed",
            ["color"] = 0xFF5370,
            ["fields"] = {
                {["name"] = "Driver Username", ["value"] = "||" .. lp.Name .. "||", ["inline"] = true},
                {["name"] = "Income Received", ["value"] = formatRP(income), ["inline"] = true},
                {["name"] = "Current Balance", ["value"] = formatRP(getCleanMoney()), ["inline"] = false},
                {["name"] = "Session Total Earning", ["value"] = formatRP(_G.TotalEarning), ["inline"] = true},
                {["name"] = "Total Completed Cycles", ["value"] = tostring(_G.CycleCount), ["inline"] = true},
                {["name"] = "Continuous Runtime", ["value"] = getRunningTime(), ["inline"] = false}
            },
            ["footer"] = {["text"] = "Vortex Hub Premium v2.6 • " .. os.date("%X")}
        }}
    })

    pcall(function()
        http_request({Url = _G.WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload})
    end)
end

-- // CORE LOGIC: ADVANCED HIGH-YIELD VELOCITY FARM
local function startVortexFarm()
    while _G.Autofarm do
        local char = lp.Character or lp.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid", 5)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)

        if not hrp or not humanoid then task.wait(0.5) continue end

        -- STAGE 1: AMBIL JOB DAN SPAWN TRUK CARGO
        if humanoid.SeatPart == nil then
            pcall(function()
                local network = ReplicatedStorage:WaitForChild("NetworkContainer", 3)
                if network then network.RemoteEvents.Job:FireServer("Truck") end
            end)
            task.wait(0.3)

            local etc = Workspace:FindFirstChild("Etc")
            local jobFolder = etc and etc:FindFirstChild("Job") and etc.Job:FindFirstChild("Truck")
            
            if jobFolder then
                local starter = jobFolder:FindFirstChild("Starter")
                if starter then
                    hrp.CFrame = starter:GetPivot()
                    task.wait(0.2)
                    safeFirePrompt(starter:FindFirstChild("Prompt"))
                end
                task.wait(0.4)

                local spawnerPart = jobFolder:FindFirstChild("Spawner") and jobFolder.Spawner:FindFirstChild("Part")
                if spawnerPart then
                    hrp.CFrame = spawnerPart.CFrame
                    task.wait(0.2)
                    local spawnTimeout = 0
                    repeat
                        safeFirePrompt(spawnerPart:FindFirstChild("Prompt"))
                        task.wait(0.6)
                        spawnTimeout = spawnTimeout + 1
                    until getMyTruck() or not _G.Autofarm or spawnTimeout > 8
                end
            end

            local myTruck = getMyTruck()
            if myTruck and myTruck:FindFirstChild("DriveSeat") then
                local sitTimeout = 0
                repeat
                    pcall(function() myTruck.DriveSeat:Sit(humanoid) end)
                    task.wait(0.4)
                    sitTimeout = sitTimeout + 1
                until humanoid.SeatPart ~= nil or not _G.Autofarm or sitTimeout > 8
            end

        -- STAGE 2: CARGO UDARA (VELOCITY METHOD)
        elseif humanoid.SeatPart ~= nil then
            local seat = humanoid.SeatPart
            local car = seat.Parent
            local primary = car.PrimaryPart or car:FindFirstChild("DriveSeat")
            
            local waypoint = Workspace:FindFirstChild("Etc") and Workspace.Etc:FindFirstChild("Waypoint") and Workspace.Etc.Waypoint:FindFirstChild("Waypoint")
            
            if primary and waypoint then
                local targetPos = waypoint.Position
                
                if (primary.Position - targetPos).Magnitude > 15000 then
                    pcall(function() car:Destroy() end)
                    task.wait(0.3)
                    continue
                end

                -- Elevasi Truk ke Angkasa
                primary.AssemblyLinearVelocity = Vector3.zero
                primary.CFrame = CFrame.new(primary.Position.X, SafeSkyHeight, primary.Position.Z)
                task.wait(0.2)

                -- Pembuatan Instan LinearVelocity (Sistem Dorong Halus)
                local attachment = Instance.new("Attachment", primary)
                local velocity = Instance.new("LinearVelocity", primary)
                velocity.Attachment0 = attachment
                velocity.MaxForce = math.huge
                
                -- Sistem Kunci Posisi & Arah di Langit
                while _G.Autofarm and car.Parent and (Vector3.new(primary.Position.X, SafeSkyHeight, primary.Position.Z) - Vector3.new(targetPos.X, SafeSkyHeight, targetPos.Z)).Magnitude > 50 do
                    local direction = (Vector3.new(targetPos.X, SafeSkyHeight, targetPos.Z) - primary.Position).Unit
                    velocity.VectorVelocity = direction * TargetVelocitySpeed
                    primary.CFrame = CFrame.lookAt(primary.Position, Vector3.new(targetPos.X, primary.Position.Y, targetPos.Z))
                    task.wait()
                end
                
                velocity:Destroy()
                attachment:Destroy()

                -- Landing & Validasi Keuntungan Per Siklus
                if _G.Autofarm and car.Parent then
                    primary.AssemblyLinearVelocity = Vector3.zero
                    primary.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                    task.wait(0.4)

                    local currentWaypointPos = waypoint.Position
                    local serverCooldown = math.random(35, 38) -- Interval klaim optimal agar aman dan cepat

                    while waypoint.Position == currentWaypointPos and _G.Autofarm and serverCooldown > 0 do
                        task.wait(1)
                        serverCooldown = serverCooldown - 1
                    end
                    
                    pcall(function() car:Destroy() end)
                    task.wait(0.4)
                end
            end
        end
        task.wait(0.2)
    end
end

-- // DATA MONITOR UNTUK WEBHOOK TRANSAKSI
task.spawn(function()
    while true do
        local newMoney = getCleanMoney()
        if _G.AutoWebhook and newMoney > lastMoney then
            pendingIncome = pendingIncome + (newMoney - lastMoney)
            
            if not isRunning then
                isRunning = true
                task.spawn(function()
                    while isRunning and _G.AutoWebhook do
                        task.wait(5) -- Deteksi kilat per 5 detik untuk laporan langsung masuk
                        if pendingIncome > 0 and _G.WebhookURL ~= "" then
                            sendWebhook(pendingIncome)
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
        task.wait(1)
    end
end)

-- [[ INTEGRASI UI INTERFACE VELARIS ]]
-- // Struktur pembuatan Menu/Tab dan fiturnya menggunakan Framework VelarisUI bawaanmu
local MainInst = VelarisUI:CreateMenu({
    Name = "Vortex Hub Premium",
    Description = "Fast Cargo Edition v2.6 (Java Regional Framework)",
    Logo = "rbxassetid://4483362458"
})

local FarmTab = MainInst:CreateTab({Name = "Autofarm Suite", Icon = "rbxassetid://4483362458"})

FarmTab:CreateToggle({
    Name = "Enable Vortex Velocity Farm",
    Description = "Mulai autofarm cargo udara berkecepatan tinggi tanpa putus (1 Server).",
    Default = false,
    Callback = function(state)
        _G.Autofarm = state
        BlackScreen.Enabled = state
        if state then
            StatusLabel.Text = "VORTEX HUB - Auto Farming Active..."
            task.spawn(startVortexFarm)
        end
    end
})

local WebhookTab = MainInst:CreateTab({Name = "Discord Log", Icon = "rbxassetid://4483362458"})

WebhookTab:CreateTextBox({
    Name = "Discord Webhook URL",
    Placeholder = "Masukkan URL Webhook Kamu Disini...",
    Callback = function(text)
        _G.WebhookURL = text
    end
})

WebhookTab:CreateToggle({
    Name = "Enable Webhook Report",
    Description = "Kirim laporan pendapatan otomatis langsung ke server Discord milikmu.",
    Default = false,
    Callback = function(state)
        _G.AutoWebhook = state
    end
})
