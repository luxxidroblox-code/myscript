local genv = getgenv()
local fenv = getfenv()

loadstring(game:HttpGet('https://raw.githubusercontent.com/LynX99-9/komtolmmek2/refs/heads/main/Adonis'))()
game:GetService('CoreGui').RobloxGui['CoreScripts/NetworkPause']:Destroy()

genv.WindUI = nil
genv.maxRetries = 3

local _ = genv.maxRetries

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- [[ DATA BINDING ]]
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer -- Kita pakai LP untuk LocalPlayer
local RunService = game:GetService("RunService")
local PlayerData = LP:WaitForChild("PlayerData") -- DIPERBAIKI: Dari Player jadi LP
local UserInputService = game:GetService("UserInputService")

-- // SETTINGS & PROMPTS
local CourierSettings = require(ReplicatedStorage:WaitForChild("Delivery System"):WaitForChild("Settings"))
local MachinePrompt = workspace.BaristaJob.Interactions.MachinePart.MachinePart.MachinePrompt
local RegisterPrompt = workspace.BaristaJob.Interactions.RegisterPart.RegisterPart.RegisterPrompt
local SupplyPrompt = workspace.BaristaJob.Interactions.SupplyPart.SupplyPart.SupplyPrompt
local JobPrompt = workspace.BaristaJob.Interactions.StartPart.StartPart.JobPrompt

-- // CFRAMES
local SupplyCF = CFrame.new(-5116.78418, 5.78931046, -670.858887)
local MachineCF = CFrame.new(-4997.1665, 1.58353043, -795.047607)
local RegisterCF = CFrame.new(-4994.06934, 1.30402756, -760.247437)
local StartJobCF = CFrame.new(-4989.80078, 5.30382967, -715.013062)
local TAKE_BOX_CFRAME = CFrame.new(-5105.61182, 4.48948574, -3758.98267)
local TAKE_PROMPT = workspace:WaitForChild("Livrason"):WaitForChild("Take1"):WaitForChild("Take"):WaitForChild("ProximityPrompt")

-- [[ GLOBAL VARIABLES ]]
_G.AutofarmCourier = false 
_G.CourierSpeed = 230  
_G.AutoFarmBarista = false
_G.AutoWebhook = false
_G.WebhookURL = "" 
_G.TotalEarning = 0
_G.CycleCount = 0
_G.StartTime = os.time()
LastActivity = tick()
local lastMoney = PlayerData.RPValue.Value
local pendingIncome = 0
local isRunning = false
local cooldownTime = 60
local WaktuKosong = nil

-- [[  UTILITY FUNCTIONS ]]
local function SwitchToCourier()
    local TeamRemote = ReplicatedStorage:FindFirstChild("TeamChangeRequest", true)
    if TeamRemote then
        if not LP.Team or LP.Team.Name ~= "Courier" then
            TeamRemote:FireServer("Courier", 11378976, 0, 0, "Detector")
            task.wait(1.5)
        end
    end
end

local function Tween(targetCFrame)
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    if not Root then return end

    local distance = (Root.Position - targetCFrame.Position).Magnitude
    local duration = distance / _G.CourierSpeed

    Root.Velocity = Vector3.new(0,0,0)
    Root.RotVelocity = Vector3.new(0,0,0)

    local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(Root, info, {CFrame = targetCFrame})

    tween:Play()

    local connection
    connection = game:GetService("RunService").Stepped:Connect(function()
        if tween.PlaybackState == Enum.PlaybackState.Playing then
            Root.Velocity = Vector3.new(0,0,0)
        else
            connection:Disconnect()
        end
    end)

    tween.Completed:Wait()
    Root.Velocity = Vector3.new(0,0,0)
end

local function AutoEquipBox()
    local Char = LP.Character
    if not Char or not Char:FindFirstChild("Humanoid") then return false end
    local held = Char:FindFirstChildOfClass("Tool")
    if held and held.Name:lower() == "box" then return true end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, item in pairs(bp:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower() == "box" then
                Char.Humanoid:EquipTool(item)
                return true
            end
        end
    end
    return false
end

local function GetActivePoint()
    for _, folder in ipairs(CourierSettings.Folder.Location:GetChildren()) do
        local block = folder:FindFirstChild("Block")
        local prompt = block and block:FindFirstChildOfClass("ProximityPrompt")
        if prompt and (prompt.Enabled or folder:FindFirstChild("POINT").billboardgui.Enabled) then
            return block, prompt
        end
    end
    return nil, nil
end



-- [[ ANTI-AFK SYSTEM ]]
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- // 2. FUNGSI AUTO-AVATAR (Narik foto profil user otomatis)
local function getAvatar()
    -- Pastikan pakai LP.UserId agar sinkron dengan Data Binding lu
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png"
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
    return string.format("%02d:%02d:%02d", math.floor(diff/3600), math.floor((diff%3600)/60), diff%60)
end

-- // 5. FUNGSI WEBHOOK (PROJECTSION EMBED AUTHOR VERSION)
local function sendWebhook(income, target)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    
    _G.CycleCount = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income
    
    local currentMoney = PlayerData.RPValue.Value
    local http_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)

    local embed = {
        ["author"] = {
            ["name"] = "Projectsion Webhook",
            ["icon_url"] = getAvatar() -- Foto profil lu (LP)
        },

        ["title"] = "Cycle Completed",
        ["color"] = 0xFFFFFF,

        ["fields"] = {
            {["name"] = "Username", ["value"] = LP.Name, ["inline"] = false}, -- DIUBAH: Dari Player ke LP
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
            ["text"] = "Made By Projectsion | " .. os.date("%m/%d/%Y %I:%M %p")
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

-- // 6. MONEY MONITOR (DAFTAR PERUBAHAN DUIT)
PlayerData.RPValue:GetPropertyChangedSignal("Value"):Connect(function()
    local newMoney = PlayerData.RPValue.Value
    if newMoney > lastMoney then
        pendingIncome = pendingIncome + (newMoney - lastMoney)
        
        if not isRunning then
            isRunning = true
            task.spawn(function()
                while isRunning do
                    task.wait(60)
                    if pendingIncome > 0 and _G.WebhookURL ~= "" then
                        sendWebhook(pendingIncome, 0)
                        pendingIncome = 0
                    end
                    -- Auto stop jika semua farm off
                    if not _G.AutofarmCourier and not _G.AutoFarmBarista then
                        isRunning = false
                    end
                end
            end)
        end
    end
    lastMoney = newMoney
end)


-- // PATHS
local function GetBaristaElements()
    -- Ganti Player jadi LP biar nyambung sama variabel di atas
    local Gui = LP.PlayerGui:FindFirstChild("BaristaGUI")
    if Gui then
        local OrderText = Gui:FindFirstChild("StatusFrame") and Gui.StatusFrame:FindFirstChild("OrderText")
        local Minigame = Gui:FindFirstChild("MinigameFrame")
        return Gui, OrderText, Minigame
    end
    return nil, nil, nil
end

local function GetRemote(name)
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == name then return v end
    end
    return nil
end


-- // BYPASS TP (SIT -> WAIT -> TP)
local function BypassTP(targetCF)
    -- Ganti Player jadi LP biar gak nil
    local Char = LP.Character or LP.CharacterAdded:Wait()
    local Hum = Char:WaitForChild("Humanoid")
    local Root = Char:WaitForChild("HumanoidRootPart")
    
    if Hum and Root then
        Hum.Sit = true
        task.wait(0.5) -- SIT WAIT
        Root.CFrame = targetCF
        task.wait(0.3)
        Hum.Sit = false
    end
end

-- // CORE SEQUENCE: REMOTE -> BYPASS TP -> WAIT -> START
local function ExecuteStartSequence()
    local tr = GetRemote("TeamChangeRequest")
    
    -- Ganti Player jadi LP di baris ini
    if LP.Team and LP.Team.Name ~= "Barista" and tr then
        tr:FireServer("Barista", 11378976, 0, 0, "Detector")
        task.wait(2.5)
    end
    
    BypassTP(StartJobCF)
    task.wait(0.8) -- WAIT BEFORE FIRE
    
    if JobPrompt and JobPrompt.Enabled then
        fireproximityprompt(JobPrompt)
    end
    
    LastActivity = tick() -- Reset timer setelah ambil job
end

-- // MAIN FARMING LOOP
task.spawn(function()
    while task.wait(0.6) do
        if _G.AutoFarmBarista then
            local _, OrderTextLabel, MinigameFrame = GetBaristaElements()
            
            -- Cek 4 Menit Tanpa Aktivitas
            if tick() - LastActivity >= 240 then
                ExecuteStartSequence()
            end

            if OrderTextLabel then
                local txt = OrderTextLabel.Text:lower()
                local isBroken = (OrderTextLabel.TextColor3.R > 0.8 and (txt:find("break") or txt:find("down")))
                
                if isBroken then
                    BypassTP(SupplyCF)
                    task.wait(0.5)
                    fireproximityprompt(SupplyPrompt)
                    LastActivity = tick() -- RESET TIMER
                    task.wait(0.5)
                    BypassTP(MachineCF)
                    fireproximityprompt(MachinePrompt)
                elseif MachinePrompt.Enabled and not (MinigameFrame and MinigameFrame.Visible) then
                    BypassTP(MachineCF)
                    fireproximityprompt(MachinePrompt)
                    LastActivity = tick() -- RESET TIMER
                    repeat task.wait(0.5)
                        LastActivity = tick() -- Jaga agar tidak mati pas nunggu minigame
                    until not (MinigameFrame and MinigameFrame.Visible) or not _G.AutoFarmBarista
                elseif RegisterPrompt.Enabled and not (MinigameFrame and MinigameFrame.Visible) then
                    task.wait(0.5)
                    BypassTP(RegisterCF)
                    task.wait(0.5)
                    fireproximityprompt(RegisterPrompt)
                    LastActivity = tick() -- RESET TIMER
                end
            end
        end
    end
end)

-- Persistent Fixes & Anti-AFK
RunService.Heartbeat:Connect(function()
    local _, _, MinigameFrame = GetBaristaElements()
    if _G.AutoFarmBarista and MinigameFrame and MinigameFrame.Visible then
        local tz = MinigameFrame:FindFirstChild("TargetZone", true)
        if tz then tz.Size = UDim2.new(1, 0, 1, 0); tz.Position = UDim2.new(0, 0, 0, 0) end
    end
end)


-- [[ MAIN ENGINE ]]
task.spawn(function()
    warn("[PROJECTSION] Engine Loaded & Waiting for Toggle...")
    
    while true do
        task.wait(1)
        
        -- Hanya jalan jika Toggle ON
        if _G.AutofarmCourier then
            -- 1. Masuk Job (Jika respawn/baru mulai)
            SwitchToCourier()

            -- Ambil data karakter terbaru setiap kali loop (penting karena sering respawn)
            local Char = LP.Character or LP.CharacterAdded:Wait()
            local Hum = Char:WaitForChild("Humanoid")
            local Root = Char:WaitForChild("HumanoidRootPart")

            if Hum and Root then
                
                -- [[ LOGIC DETEKSI LIMIT / STUCK 4 MENIT ]]
                if not AutoEquipBox() then
                    -- Mulai hitung waktu kalau tangan kosong
                    if not WaktuKosong then 
                        WaktuKosong = os.clock() 
                    end
                    
                    -- Jika sudah 240 detik (4 menit) masih kosong
                    if (os.clock() - WaktuKosong) >= 240 then
                        warn("[PROJECTSION] Limit Detect / Stuck! Switching Role...")
                        
                        -- Remote Civilian buat reset status (Ini bakal bikin lu RESPAWN)
                        local args = {"Civilian", 0, 0, 0, "Detector"}
                        game:GetService("ReplicatedStorage"):WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest"):FireServer(unpack(args))
                        
                        WaktuKosong = nil -- Reset timer
                        
                        -- LOCK SCRIPT: Tunggu sampai bener-bener jadi Civilian
                        repeat 
                            task.wait(1)
                            warn("[PROJECTSION] Waiting for team change to Civilian...")
                        until (LP.Team and LP.Team.Name == "Civilian") or not _G.AutofarmCourier
                        
                        -- Jeda istirahat 15 detik (Biar gak disangka spam ganti team) 
                       warn("[PROJECTSION] Resting for 15s...")
                        task.wait(15) 
                        
                        continue -- Balik ke paling atas buat masuk Courier lagi (Bakal RESPAWN lagi)
                    end
                else
                    -- Kalau pegang box, timer reset jadi nil lagi
                    WaktuKosong = nil
                end

                -- [[ BYPASS UTAMA: WAJIB SIT SEBELUM TWEEN ]]
                -- Karena setiap ganti job itu RESPAWN, lu bakal berdiri. 
                -- Maka di sini wajib dipaksa duduk dulu sebelum gerak (Tween).
                if not Hum.Sit then
                    warn("[PROJECTSION] Activating SIT Bypass...")
                    repeat 
                        Hum.Sit = true
                        task.wait(0.5)
                    until Hum.Sit or not _G.AutofarmCourier
                    task.wait(1) -- Jeda biar server sinkron posisi duduk lu
                end

                -- PHASE 1: AMBIL PAKET
                if not AutoEquipBox() then
                    -- Tween ke tempat ambil box
                    Tween(TAKE_BOX_CFRAME)
                    task.wait(0.5)
                    
                    if _G.AutofarmCourier and TAKE_PROMPT.Enabled then
                        fireproximityprompt(TAKE_PROMPT)
                        task.wait(1.5)
                    end
                
                -- PHASE 2: ANTER PAKET
                else
                    local TargetBlock, TargetPrompt = GetActivePoint()
                    
                    if TargetBlock and TargetPrompt then
                        task.wait(math.random(0, 1))
                        
                        -- Tween ke tempat antar
                        Tween(TargetBlock.CFrame * CFrame.new(0, 2, 0))
                        task.wait(0.8)
                        
                        AutoEquipBox() -- Pastikan tool masih dipegang sebelum diprompt
                        
                        if _G.AutofarmCourier and TargetPrompt.Enabled then
                            fireproximityprompt(TargetPrompt)
                            task.wait(3.5)
                        end
                    end
                end
            end
        else
            -- Reset timer kalau toggle dimatikan manual
            WaktuKosong = nil
        end
    end
end)








-- window
local Window = WindUI:CreateWindow({
    Title = "Projectsion",
    Icon = "dds", 
    Author = "laksid",
    Folder = "apa aja",
    Transparent = true,
    Size = UDim2.fromOffset(300, 350),
   
    OpenButton = {
        Enabled = true,
        Title = "Drag Drive Simulator",
        Draggable = true,
    }
})

Window:Tag({
Title = "DDS",
Icon = "dds",
Color = Color3.fromRGB(255,255,255),
Border = true,
})


-- Home Tab
local HomeTab = Window:Tab({ Title = "Home Tab", Icon = "house" })

HomeTab:Section({ Title = "Update Log" })
HomeTab:Button({
Title = "Version 1.0",
Desc = "[+]added autofarm courier\n[+]added barista\n[+]webhook sistem\n[+]new ui",
Icon = "file-text"
})


local AutofarmTab = Window:Tab({ Title = "Autofarm", Icon = "motorcycle"})

AutofarmTab:Section({ Title = "AutoFarming" })

AutofarmTab:Toggle({
    Title = "Autofarm Courier",
    Desc = "It's safe if you're in doubt, use a small account",
    Callback = function(state)
        _G.AutofarmCourier = state -- Ini yang bakal dibaca sama loop engine
        if state then
            WindUI:Notify({ 
                Title = ".projectsion", 
                Content = "Courier Autofarm Enabled!", 
                Duration = 3 
            })
        end
    end
})

AutofarmTab:Slider({
    Title = "speed Autofarm Courier",
    Desc = "changes tween autofarm",
    Value = {Min = 10, Max = 300, Default = 230},
    Callback = function(value)
        _G.CourierSpeed = value -- Real-time ganti speed tween
    end
})

AutofarmTab:Section({ Title = "Autofarm barista" })
AutofarmTab:Toggle({
    Title = "Autofarm barista",
    Desc = "This is quite a big salary and it's all automatic!",
    Callback = function(state)
        _G.AutoFarmBarista = state 
        if state then
            LastActivity = tick()
            -- [[ PANCINGAN BIAR LANGSUNG JALAN ]]
            task.spawn(function()
                ExecuteStartSequence() 
            end)
            
            WindUI:Notify({ 
                Title = ".projectsion", 
                Content = "Barista Engine Active!", 
                Duration = 3 
            })
        end
    end
})

local WebhookTab = Window:Tab({ Title = "Webhook", Icon = "webhook" })

WebhookTab:Section({ Title = "Webhook Configuration" })

WebhookTab:Input({
    Title = "Discord Webhook URL",
    Desc = "Enter your Discord channel webhook link",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(text)
        _G.WebhookURL = text
        print("Webhook set to: " .. text)
    end
})

-- Tambahin Toggle biar user bisa ON/OFF log-nya
WebhookTab:Toggle({
    Title = "Enable Webhook Logs",
    Desc = "Send cycle reports to Discord every 1 minute",
    Default = false,
    Callback = function(state)
        _G.AutoWebhook = state
    end
})
