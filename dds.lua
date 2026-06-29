-- ============================================
-- STEALTH DRIVE - DYNAMIC INVENTORY EDITION
-- Auto-detects owned vehicles from player data
-- ============================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- Services
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local RS               = game:GetService("ReplicatedStorage")
local Player           = Players.LocalPlayer

-- Variables & Configurations
local SPEED             = 242
local GROUND_OFFSET     = 1.5
local CHECK_DISTANCE    = 15
local DIR_COOLDOWN      = 0.3

local active           = false
local currentVehicle   = nil
local selectedVehicle  = "" 
local direction        = 1
local lastDirChange    = 0

local force            = nil
local gyro             = nil
local attachment       = nil
local heartbeatConn    = nil

-- ============================================
-- DYNAMIC INVENTORY SCANNER (Mencari Motor di Dex/Data)
-- ============================================
local OwnedVehicles = {}

local function scanInventory()
    table.clear(OwnedVehicles)
    
    -- Mencari folder inventaris yang umum di data player
    local playerData = Player:FindFirstChild("PlayerData") or Player:FindFirstChild("Data")
    local inventory = Player:FindFirstChild("Inventory") or (playerData and (playerData:FindFirstChild("Inventory") or playerData:FindFirstChild("Vehicles") or playerData:FindFirstChild("OwnedCars")))
    
    if inventory then
        for _, item in pairs(inventory:GetChildren()) do
            -- Memasukkan nama objek/value ke dalam daftar motor
            if item:IsA("ValueBase") then
                -- Jika datanya berupa BoolValue/StringValue (contoh: item.Name = "MioSporty", Value = true)
                if item.Value == true or typeof(item.Value) == "string" then
                    table.insert(OwnedVehicles, item.Name)
                end
            else
                -- Jika datanya berupa Folder/Part/Configuration di dalam inventaris
                table.insert(OwnedVehicles, item.Name)
            end
        end
    end
    
    -- Cadangan: Jika inventaris kosong/tidak ketemu, beri opsi default agar tidak eror
    if #OwnedVehicles == 0 then
        table.insert(OwnedVehicles, "Yamahax-MioSporty")
        table.insert(OwnedVehicles, "Honda-Beat")
    end
    
    -- Set default selection ke motor pertama yang ditemukan
    selectedVehicle = OwnedVehicles[1]
end

-- Jalankan scan pertama kali sebelum UI dibuat
scanInventory()

-- ============================================
-- RAYFIELD UI SETUP
-- ============================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Stealth Drive Premium",
   LoadingTitle = "Scanning Vehicles...",
   LoadingSubtitle = "by _nznt (Inventory Scan)",
   ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Auto Drive", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- ============================================
-- FUNCTIONS
-- ============================================

local function spawnVehicle(vehicleId)
    local sf = RS:FindFirstChild("SpawnCarEvents") or RS:FindFirstChild("CarEvents") or RS:FindFirstChild("VehicleEvents")
    if sf then
        -- Mencari remote untuk spawn (menyesuaikan nama remote umum)
        local r = sf:FindFirstChild("SpawnCar") or sf:FindFirstChild("SpawnVehicle") or sf:FindFirstChild("Spawn")
        if r and r:IsA("RemoteEvent") then 
            r:FireServer(vehicleId) 
            return true 
        end
    end
    return false
end

local function cleanPhysics()
    if force then pcall(function() force:Destroy() end) force = nil end
    if gyro then pcall(function() gyro:Destroy() end) gyro = nil end
    if attachment then pcall(function() attachment:Destroy() end) attachment = nil end
end

local function startAutoDrive()
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hum  = char:WaitForChild("Humanoid")
    local root = char:WaitForChild("HumanoidRootPart")

    Rayfield:Notify({Title = "Status", Content = "Memunculkan: " .. selectedVehicle, Duration = 3})
    spawnVehicle(selectedVehicle)
    task.wait(3)

    -- Cari VehicleSeat terdekat
    local seat = nil
    local closestDistance = math.huge
    for _, obj in pairs(workspace:GetChildren()) do
        local found = obj:FindFirstChildWhichIsA("VehicleSeat", true)
        if found then
            local dist = (root.Position - found.Position).Magnitude
            if dist < closestDistance then
                closestDistance = dist
                seat = found
            end
        end
    end

    if not seat then
        Rayfield:Notify({Title = "Error", Content = "Motor tidak ditemukan! Pastikan kamu berada dekat tempat spawn.", Duration = 5})
        return false
    end

    seat:Sit(hum)
    task.wait(0.5)
    currentVehicle = seat.Parent

    cleanPhysics()
    attachment = Instance.new("Attachment", seat)
    force = Instance.new("LinearVelocity", seat)
    force.MaxForce = 99999999
    force.Attachment0 = attachment
    force.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    
    gyro = Instance.new("BodyGyro", seat)
    gyro.MaxTorque = Vector3.new(1e6, 0, 1e6)
    gyro.CFrame = seat.CFrame

    return true
end

-- ============================================
-- UI ELEMENTS (MAIN TAB)
-- ============================================

-- Dropdown otomatis terisi berdasarkan isi Data/Inventory kamu
local VehicleDropdown = MainTab:CreateDropdown({
   Name = "Pilih Motor (Dari Inventory)",
   Options = OwnedVehicles,
   CurrentOption = {selectedVehicle},
   MultipleOptions = false,
   Callback = function(Option)
      selectedVehicle = Option[1]
      Rayfield:Notify({Title = "Target Terpilih", Content = "Siap menggunakan: " .. selectedVehicle, Duration = 2})
   end,
})

-- Tombol untuk scan ulang jika kamu baru beli motor baru di game
MainTab:CreateButton({
   Name = "🔄 Refresh Daftar Motor",
   Callback = function()
       scanInventory()
       VehicleDropdown:Refresh(OwnedVehicles, {selectedVehicle})
       Rayfield:Notify({Title = "Daftar Diperbarui", Content = "Berhasil memindai ulang isi inventory!", Duration = 2})
   end,
})

MainTab:CreateToggle({
   Name = "Aktifkan Auto Drive",
   CurrentValue = false,
   Callback = function(Value)
      active = Value
      if active then
          if selectedVehicle == "" then
              Rayfield:Notify({Title = "Error", Content = "Pilih motor terlebih dahulu!", Duration = 3})
              return
          end

          local success = startAutoDrive()
          if not success then active = false return end
          
          heartbeatConn = RunService.Heartbeat:Connect(function()
              if not active or not force or not currentVehicle then return end
              local seat = currentVehicle:FindFirstChildWhichIsA("VehicleSeat")
              if not seat then return end

              local groundRay = workspace:Raycast(seat.Position, Vector3.new(0, -100, 0))
              if groundRay then
                  local p = seat.Position
                  local _, ry, rz = seat.CFrame:ToEulerAnglesYXZ()
                  seat.CFrame = CFrame.new(p.X, groundRay.Position.Y + GROUND_OFFSET, p.Z) * CFrame.Angles(0, ry, 0)
              end

              local rayOrigin = (seat.CFrame * CFrame.new(0, 0, -CHECK_DISTANCE * direction)).p
              local hit = workspace:Raycast(rayOrigin, Vector3.new(0, -30, 0))
              if not hit then
                  local now = tick()
                  if now - lastDirChange >= DIR_COOLDOWN then
                      direction     = direction * -1
                      lastDirChange = now
                  end
              end

              force.VectorVelocity = Vector3.new(0, 0, -SPEED * direction)
              if gyro then gyro.CFrame = seat.CFrame end
          end)
      else
          if heartbeatConn then heartbeatConn:Disconnect() end
          cleanPhysics()
          Rayfield:Notify({Title = "Status", Content = "Auto Drive Dimatikan.", Duration = 2})
      end
   end,
})

-- ============================================
-- UI ELEMENTS (SETTINGS TAB)
-- ============================================

SettingsTab:CreateSlider({
   Name = "Kecepatan Motor",
   Min = 0,
   Max = 400,
   CurrentValue = SPEED,
   Increment = 10,
   ValueName = "Speed",
   Callback = function(Value) SPEED = Value end,
})

SettingsTab:CreateSlider({
   Name = "Tinggi dari Tanah (Offset)",
   Min = 1,
   Max = 10,
   CurrentValue = GROUND_OFFSET,
   Increment = 0.5,
   ValueName = "Studs",
   Callback = function(Value) GROUND_OFFSET = Value end,
})
