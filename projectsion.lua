local VelarisUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/nhfudzfsrzggt/brigida/refs/heads/main/dist/main.lua", true))()
-- // Destroy Specific Prop
local targetProp = workspace.Map.Prop:GetChildren()[1627]
if targetProp then
    targetProp:Destroy()
end

-- // Black Screen Setup
local BlackScreen = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local StatusLabel = Instance.new("TextLabel") -- Tambahan Label Status Detik

BlackScreen.Name = "ProjectsionBlackout"
BlackScreen.Parent = game:GetService("CoreGui")
BlackScreen.DisplayOrder = -1 -- Biar menu script lu tetep keliatan di depan
BlackScreen.Enabled = false 

Frame.Parent = BlackScreen
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.Size = UDim2.new(1.5, 0, 1.5, 0) -- Lebih besar biar gak bocor layarnya
Frame.Position = UDim2.new(-0.25, 0, -0.25, 0)
Frame.BorderSizePixel = 0

-- Konfigurasi Tampilan Teks Hitungan Mundur di Layar Hitam
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
-- // Tetep di baris yang sama kayak kemauan lu
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

-- JANGAN LANGSUNG PANGGIL FUNGSINYA DI SINI
local lastMoney = 0 
local pendingIncome = 0
local isRunning = false

-- // NAH, TAPI DI BAWAH (Setelah fungsi getCleanMoney dibuat), LU ISI NILAINYA
task.spawn(function()
    task.wait(3) -- Tunggu bentar biar game load
    lastMoney = getCleanMoney()
end)


-- Tambahkan baris ini biar gak error:
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

-- // 2. FUNGSI AUTO-AVATAR
local function getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. lp.UserId .. "..&width=420&height=420&format=png"
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

-- // 5. FUNGSI WEBHOOK (PROJECTSION EMBED AUTHOR VERSION)
local function sendWebhook(income, target)
    if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then return end
    
    _G.CycleCount = _G.CycleCount + 1
    _G.TotalEarning = _G.TotalEarning + income
    
    local currentMoney = getCleanMoney() -- Sinkron ke fungsi Truck Farm lu
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

-- // 6. MONEY MONITOR (SINKRON KE TOGGLE)
task.spawn(function()
    while true do
        local newMoney = getCleanMoney()
        -- Cek apakah duit nambah DAN fitur Webhook dinyalain
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
                        -- Stop jika fitur dimatikan atau farm berhenti
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
        local hrp = char:WaitForChild("HumanoidRootPart")
