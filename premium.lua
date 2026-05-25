-- [[ PROJECTSION HUB PREMIUM — EDISI BISNIS COMMERCIAL REUSE ]] --
-- // Dioptimasi khusus untuk kecepatan maksimal dan efisiensi satu server

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Projectsion Hub Premium - Fast Cargo CDID",
   LoadingTitle = "Loading Projectsion Hub...",
   LoadingSubtitle = "Made by.projectsion",
   Theme = "Dark"
})

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

-- // Variables
_G.FastAutofarm = false
local NextCooldown = 0

-- // Fungsi Ambil Truk Pemain
local function getMyTruck()
    local vehicles = Workspace:FindFirstChild("Vehicles")
    return vehicles and vehicles:FindFirstChild(lp.Name .. "sCar")
end

-- // Fungsi Trigger Prompt
local function safeFirePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then fireproximityprompt(prompt) end
end

-- // CORE LOGIC: REPEATED SKY-TWEEN METHOD (NON-STOP FARM)
local function startFastFarm()
    while _G.FastAutofarm do
        local char = lp.Character or lp.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid", 5)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)

        if not hrp or not humanoid then task.wait(1) continue end

        -- KONDISI 1: JIKA DI LUAR TRUK (PROSES AMBIL KERJAAN & SPAWN)
        if humanoid.SeatPart == nil then
            -- Ambil Job Trucker
            local network = ReplicatedStorage:WaitForChild("NetworkContainer", 5)
            local remote = network and network:WaitForChild("RemoteEvents", 5) and network.NetworkContainer.RemoteEvents:WaitForChild("Job", 5)
            if remote then remote:FireServer("Truck") end
            task.wait(0.3)

            local jobFolder = Workspace:WaitForChild("Etc", 5):WaitForChild("Job", 5):WaitForChild("Truck", 5)
            local starter = jobFolder:WaitForChild("Starter", 5)
            
            -- Ambil rute cargo
            if starter then
                hrp.CFrame = starter:GetPivot()
                task.wait(0.2)
                safeFirePrompt(starter:FindFirstChild("Prompt"))
            end
            task.wait(0.4)

            -- Spawn Truk
            local spawnerPart = jobFolder:WaitForChild("Spawner", 5):WaitForChild("Part", 5)
            if spawnerPart then
                hrp.CFrame = spawnerPart.CFrame
                task.wait(0.3)
                repeat
                    safeFirePrompt(spawnerPart:FindFirstChild("Prompt"))
                    task.wait(0.5)
                until getMyTruck() or not _G.FastAutofarm
            end

            -- Otomatis Duduk
            local myTruck = getMyTruck()
            if myTruck and myTruck:FindFirstChild("DriveSeat") then
                repeat
                    pcall(function() myTruck.DriveSeat:Sit(humanoid) end)
                    task.wait(0.4)
                until humanoid.SeatPart ~= nil or not _G.FastAutofarm
            end

        -- KONDISI 2: JIKA SUDAH DI DALAM TRUK (TERBANG & ANTAR)
        elseif humanoid.SeatPart ~= nil then
            local seat = humanoid.SeatPart
            local car = seat.Parent
            local primary = car.PrimaryPart or car:FindFirstChild("DriveSeat")
            
            local waypoint = Workspace:FindFirstChild("Etc"):FindFirstChild("Waypoint"):FindFirstChild("Waypoint")
            
            if primary and waypoint then
                local targetPos = waypoint.Position
                
                -- Anti-Stuck Waypoint Bug (>15KM)
                if (primary.Position - targetPos).Magnitude > 15000 then
                    pcall(function() car:Destroy() end)
                    task.wait(0.5)
                    continue
                end

                -- Langkah A: Lempar ke Langit (Ketinggian Aman 780m)
                local skyHeight = 780
                primary.AssemblyLinearVelocity = Vector3.zero
                primary.CFrame = CFrame.new(primary.Position.X, skyHeight, primary.Position.Z)
                task.wait(0.2)

                -- Langkah B: Sky-Tweening Kecepatan Tinggi (Speed: 210)
                local targetSkyPos = CFrame.new(targetPos.X, skyHeight, targetPos.Z)
                local duration = (primary.Position - targetSkyPos.Position).Magnitude / 210
                
                primary.Anchored = true
                local tween = TweenService:Create(primary, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetSkyPos})
                tween:Play()
                tween.Completed:Wait()
                primary.Anchored = false

                -- Langkah C: Landas & Potong Cooldown Gaji (Batas Kritis: 36 - 39 Detik)
                if _G.FastAutofarm and car.Parent then
                    primary.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                    task.wait(0.3)

                    local prepos = waypoint.Position
                    NextCooldown = math.random(36, 39)

                    while waypoint.Position == prepos and _G.FastAutofarm and NextCooldown > 0 do
                        task.wait(1)
                        NextCooldown = NextCooldown - 1
                    end
                    
                    -- Selesai dapat gaji, hancurkan truk lama untuk langsung ambil rute baru di server yang sama
                    pcall(function() car:Destroy() end)
                    task.wait(0.5)
                end
            end
        end
        task.wait(0.3)
    end
end

-- // INTERFACE RAYFIELD
local Tab = Window:CreateTab("Fast Farm", 4483362458)

Tab:CreateToggle({
   Name = "Enable Fast Cargo Farm (Method: Vortex High-Yield)",
   CurrentValue = false,
   Callback = function(Value)
      _G.FastAutofarm = Value
      if Value then
          task.spawn(startFastFarm)
      end
   end,
})

-- // Anti-AFK bawaan agar tidak ke-kick Roblox saat ditinggal tidur
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    lp.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)
