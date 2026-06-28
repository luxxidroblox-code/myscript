local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")

warn("[DEBUG] Menginisialisasi modul Courier System...")
local CourierSettings = require(ReplicatedStorage:WaitForChild("Delivery System"):WaitForChild("Settings"))
local SupplyCF = CFrame.new(-5116.78418, 5.78931046, -670.858887)
local TAKE_BOX_CFRAME = CFrame.new(-5105.61182, 4.48948574, -3758.98267)

warn("[DEBUG] Mencari objek TAKE_PROMPT di workspace...")
local Livrason = workspace:WaitForChild("Livrason")
local Take1 = Livrason:WaitForChild("Take1")
local Take = Take1:WaitForChild("Take")
local TAKE_PROMPT = Take:WaitForChild("ProximityPrompt")
warn("[DEBUG] TAKE_PROMPT ditemukan berjenis: " .. TAKE_PROMPT.ClassName)

_G.AutofarmCourier = true
_G.CourierSpeed = 230
local WaktuKosong = nil

local function SwitchToCourier()
    local TeamRemote = ReplicatedStorage:FindFirstChild("TeamChangeRequest", true)
    if TeamRemote then
        if not LP.Team or LP.Team.Name ~= "Courier" then
            warn("[DEBUG] Mengirim request pindah tim ke Courier...")
            TeamRemote:FireServer("Courier", 11378976, 0, 0, "Detector")
            task.wait(1.5)
        end
    end
end

local function Tween(targetCFrame)
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    if not Root then 
        warn("[DEBUG] [WARNING] HumanoidRootPart tidak ditemukan saat mencoba Tween!")
        return 
    end

    local distance = (Root.Position - targetCFrame.Position).Magnitude
    local duration = distance / _G.CourierSpeed
    warn(string.format("[DEBUG] Memulai pergerakan Tween ke koordinat %s (Jarak: %.2f studs, Durasi: %.2f detik)", tostring(targetCFrame.Position), distance, duration))

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
    warn("[DEBUG] Tween selesai. Karakter sampai di tujuan.")
end

local function AutoEquipBox()
    local Char = LP.Character
    if not Char or not Char:FindFirstChild("Humanoid") then return false end
    
    local held = Char:FindFirstChildOfClass("Tool")
    if held and held.Name:lower() == "box" then 
        return true 
    end
    
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, item in pairs(bp:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower() == "box" then
                warn("[DEBUG] Menemukan kotak di Backpack. Memasang ke karakter...")
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
            warn("[DEBUG] Menemukan titik pengantaran aktif: " .. folder.Name)
            return block, prompt
        end
    end
    warn("[DEBUG] Tidak ada titik pengantaran aktif yang terdeteksi.")
    return nil, nil
end

warn("[DEBUG] Skrip pembaca antarmuka selesai di-load. Menjalankan Loop Utama...")

task.spawn(function()
    while true do
        task.wait(1)

        if _G.AutofarmCourier then
            warn("[DEBUG] Loop tick - AutofarmCourier berstatus aktif.")
            SwitchToCourier()

            local Char = LP.Character or LP.CharacterAdded:Wait()
            local Hum = Char:WaitForChild("Humanoid")
            local Root = Char:WaitForChild("HumanoidRootPart")

            if Hum and Root then
                local punyaKotak = AutoEquipBox()
                warn("[DEBUG] Cek status paket - Membawa kotak: " .. tostring(punyaKotak))

                if not punyaKotak then
                    if not WaktuKosong then
                        WaktuKosong = os.clock()
                        warn("[DEBUG] Memulai hitung mundur waktu macet (Anti-Stuck)...")
                    end

                    -- Batas deteksi macet dipercepat jadi 30 detik untuk keperluan testing/ngebug
                    if (os.clock() - WaktuKosong) >= 30 then 
                        warn("[DEBUG] [STUCK DETECTED] Karakter macet tanpa kotak selama 30 detik! Pindah tim ke Civilian...")
                        local args = {"Civilian", 0, 0, 0, "Detector"}
                        game:GetService("ReplicatedStorage"):WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest"):FireServer(unpack(args))

                        WaktuKosong = nil

                        repeat
                            task.wait(1)
                        until (LP.Team and LP.Team.Name == "Civilian") or not _G.AutofarmCourier

                        warn("[DEBUG] Istirahat 5 detik sebelum mencoba kembali jadi Courier...")
                        task.wait(5)
                        continue
                    end
                else
                    WaktuKosong = nil
                end

                if not Hum.Sit then
                    warn("[DEBUG] Mengubah status humanoid menjadi Duduk (Sit) untuk stabilitas...")
                    repeat
                        Hum.Sit = true
                        task.wait(0.5)
                    until Hum.Sit or not _G.AutofarmCourier
                    task.wait(1)
                end

                if not punyaKotak then
                    warn("[DEBUG] Menuju lokasi pengambilan box paket...")
                    Tween(TAKE_BOX_CFRAME)
                    task.wait(0.5)

                    if _G.AutofarmCourier and TAKE_PROMPT.Enabled then
                        warn("[DEBUG] Menekan tombol interaksi TAKE_PROMPT...")
                        fireproximityprompt(TAKE_PROMPT)
                        task.wait(1.5)
                    else
                        warn("[DEBUG] [WARNING] Gagal interaksi, TAKE_PROMPT sedang tidak aktif!")
                    end
                else
                    local TargetBlock, TargetPrompt = GetActivePoint()

                    if TargetBlock and TargetPrompt then
                        warn("[DEBUG] Menuju ke titik lokasi pengantaran...")
                        Tween(TargetBlock.CFrame * CFrame.new(0, 2, 0))
                        task.wait(0.8)

                        AutoEquipBox()

                        if _G.AutofarmCourier and TargetPrompt.Enabled then
                            warn("[DEBUG] Menekan tombol interaksi pengantaran paket...")
                            fireproximityprompt(TargetPrompt)
                            task.wait(3.5)
                        else
                            warn("[DEBUG] [WARNING] Gagal mengantar, tombol target pengantaran tidak aktif!")
                        end
                    end
                end
            end
        else
            WaktuKosong = nil
        end
    end
end)
