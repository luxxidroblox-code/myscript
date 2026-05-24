
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Projectsion",
   LoadingTitle = "Bus Explorer Indonesia",
   LoadingSubtitle = "by Projectsion",
   Theme = "Ocean",
   ConfigurationSaving = {
      Enabled = true,
      FileName = "ProjectsionConfig"
   },
   KeySystem = false 
   
   local VirtualUser = game:GetService("VirtualUser")
local LP = game.Players.LocalPlayer
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsFolder = LP:WaitForChild("PlayerData")
local StartUang = StatsFolder.Uang.Value
local StartTime = os.time()
local CarData = Remotes.GetClientCustomizationData:InvokeServer()
local OwnedCarsFolder = LP:WaitForChild("PlayerData"):WaitForChild("OwnedCars")
local HttpService = game:GetService("HttpService")

-- VARIABEL
_G.AutoFull = false
_G.AntiAFK = true
_G.AutoRejoin = false
_G.blackscreen = false
_G.HideChar = false
_G.SelectedBus = "" 
_G.WebhookURL = ""
_G.TotalEarning = 0
_G.CycleCount = 0
_G.StartTime = os.time()
_G.AutoKickEnabled = false
local TargetUang = 0
local lastMoney = StatsFolder.Uang.Value
local SelectedBusToBuy = ""
local CarListData = {}
local pendingIncome = 0
local SelectedAction = "Dealership"
local SelectedTP = "Dealership"
local isRunning = false
local busOptions = {}
local BlackScreen = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")

BlackScreen.Name = "Projectsion"
BlackScreen.Parent = game:GetService("CoreGui")
BlackScreen.DisplayOrder = -1 -- Menunya aman di depan, in-game ketutup hitam
BlackScreen.Enabled = false 

Frame.Parent = BlackScreen
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.Size = UDim2.new(1.5, 0, 1.5, 0)
Frame.Position = UDim2.new(-0.25, 0, -0.25, 0)
Frame.BorderSizePixel = 0

-- Fungsi buat ngetoggle GUI hitamnya berdasarkan variabel _G.blackscreen
task.spawn(function()
    while task.wait(0.5) do
        if _G.blackscreen then
            BlackScreen.Enabled = true
        else
            BlackScreen.Enabled = false
        end
    end
end)

-- Forward Declaration
local StatusLabel, UangLabel, EarningLabel, TimeLabel, FPSLabel, PingLabel

-- --- FORMAT RUPIAH FUNCTION ---
local function formatRS(amount)
    local formatted = tostring(amount)
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if (k==0) then break end
    end
    return formatted
end

-- --- LOOP MONITORING STATS ---
task.spawn(function()
    while task.wait(1) do
        -- Cek salah satu label saja buat mastiin UI udah ke-load
        if UangLabel then
            pcall(function()
                -- Update Financials
                local currentUang = StatsFolder.Uang.Value
                UangLabel:Set("Uang: Rp " .. formatRS(currentUang))
                EarningLabel:Set("Earning: Rp " .. formatRS(currentUang - StartUang))
                
                -- Update Time
                local diff = os.time() - StartTime
                local h = math.floor(diff / 3600)
                local m = math.floor((diff % 3600) / 60)
                local s = diff % 60
                TimeLabel:Set(string.format("Time: %02d:%02d:%02d", h, m, s))
                
                -- Update Performance
                local ping = tonumber(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString():split(" ")[1]) or 0
                PingLabel:Set("Ping: " .. math.floor(ping) .. " ms")
                
                -- Update FPS
                local fps = math.floor(1 / task.wait())
                FPSLabel:Set("FPS: " .. fps)
            end)
        end
    end
end)

-- SCANNING BUS 
for _, car in pairs(OwnedCarsFolder:GetChildren()) do
    local carID = car.Name
    local carInfo = CarData.CarData_Cars[carID]
    if carInfo then
        table.insert(busOptions, carID)
    end
end

-- Fallback 
if #busOptions == 0 then table.insert(busOptions, "Jetbus_3_RM _SHD") end
_G.SelectedBus = busOptions[1]

local lastTarget = nil
local noBillboardTime = 0
local jobStarted = false
local CirebonEndCF = CFrame.new(-26471.1445, -212.441071, 33276.8203, -0.0246282816, 0, 0.999696672, 0, 1, 0, -0.999696672, 0, -0.0246282816)
local TP_Locations = {
    ["Dealership"] = CFrame.new(19830.625, 266.913116, -27910.4844, 0.999847949, 0, 0.017436387, 0, 1, 0, -0.017436387, 0, 0.999847949),
    ["Modifikasi"] = CFrame.new(12035.499, -21.3362789, 12740.0605, -0.573599219, 0, 0.81913656, 0, 1, 0, -0.81913656, 0, -0.573599219),
    ["Teleport City"] = CFrame.new(21795.2461, 292.439026, -40055.918, 0.707134247, -0, -0.707079291, 0, 1, -0, 0.707079291, 0, 0.707134247)
}
game.Players.LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        warn("VoidlineHub: Anti-AFK Aktif!")
    end
end) -- Pastikan ada 'end)' di sini!

-- --- UTILITY FUNCTIONS ---
local function SetStatus(text)
    if StatusLabel then
        StatusLabel:Set("Status: " .. text)
    end
end

local function GetMyBus()
    return workspace.SpawnedVehicles:FindFirstChild(_G.SelectedBus)
end

local function SetFreeze(state)
    local bus = GetMyBus()
    if bus then
        for _, part in pairs(bus:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = state
                if not state then
                    part.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    part.AssemblyAngularVelocity = Vector3.new(0,0,0)
                end
            end
        end
    end
end

local function InstantTP(targetCF)
    local bus = GetMyBus()
    if not bus then return end
    SetFreeze(false) 
    task.wait(0.1)
    for i = 1, 3 do
        bus:PivotTo(targetCF)
        task.wait(0.05)
    end
end

local function GetActiveStop()
    for _, part in pairs(workspace.Checkpoints:GetChildren()) do
        local bs = part:FindFirstChild("BusStop")
        if bs and bs:IsA("BillboardGui") and bs.Enabled == true then
            return part
        end
    end
    return nil
end

-- // 2. FUNGSI AUTO-AVATAR
local function getAvatar()
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=420&height=420&format=png"
end

-- // 3. FORMAT RUPIAH (Disamakan dengan format titik lu tadi)
local function formatRP(v)
    local formatted = tostring(v)
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if (k==0) then break end
    end
    return "Rp " .. formatted
end

-- // 4. RUNNING TIME
local function getRunningTime()
    local diff = os.time() - _G.StartTime
    return string.format("%02d:%02d:%02d", math.floor(diff/3600), math.floor((diff%3600)/60), diff%60)
end

-- // 5. MONEY MONITOR (Setiap 2.15 Menit / 135 Detik)
StatsFolder.Uang:GetPropertyChangedSignal("Value"):Connect(function()
    local newMoney = StatsFolder.Uang.Value
    if newMoney > lastMoney then
        -- Simpan pendapatan yang masuk
        pendingIncome = pendingIncome + (newMoney - lastMoney)
        
        if not isRunning then
            isRunning = true
            task.spawn(function()
                while isRunning do
                    -- Tunggu selama 135 detik (2 Menit 15 Detik) agar pas dengan timer payout
                    task.wait(65) 
                    
                    if pendingIncome > 0 and _G.WebhookURL ~= "" and _G.WebhookEnabled then
                        sendWebhook(pendingIncome, 0)
                        pendingIncome = 0 -- Reset setelah kirim
                    end
                    
                    -- Auto stop jika autofarm mati
                    if not _G.AutoFull then
                        isRunning = false
                    end
                end
            end)
        end
    end
    lastMoney = newMoney
end)

local ClientData = Remotes.GetClientCustomizationData:InvokeServer()
if ClientData and ClientData.CarData_Cars then
    for carID, data in pairs(ClientData.CarData_Cars) do
        -- Masukin nama asli bus ke daftar dropdown
        table.insert(CarListData, carID) 
    end
    table.sort(CarListData)
end

-- --- UI ---
local MainTab = Window:CreateTab("Main Farm", "play")
MainTab:CreateSection("Autofarm bus")
MainTab:CreateParagraph({
    Title = "How to Use Auto-Kick", 
    Content = "1. Masukkan target uang (Contoh: 1.500.000)\n2. Nyalakan toggle 'Enable Auto-Kick'\n3. Script akan otomatis kick saat uang tercapai."
})
MainTab:CreateToggle({
    Name = "On Autofarm",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoFull = Value
        _G.blackscreen = Value
        
        if not Value then 
           _G.blackscreen = false
            lastTarget = nil 
            jobStarted = false
            SetFreeze(false)
            SetStatus("Idle")
        end
        
        while _G.AutoFull do
            -- LOGIC HAPUS PENGHALANG
            pcall(function()
                local cikamurang = workspace:FindFirstChild("Cikamurang")
                if cikamurang then
                    local folderModel = cikamurang:FindFirstChild("model") or cikamurang:FindFirstChild("Model")
                    if folderModel then
                        local targetHapus = folderModel:WaitForChild("SInar", 0.1)
                        if targetHapus then targetHapus:Destroy() end
                    end
                end
            end)

            local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
            local infoLabel = LP.PlayerGui:FindFirstChild("BusJobGUI") and LP.PlayerGui.BusJobGUI.JobStatusFrame.InfoLabel
            
            if not jobStarted then
                SetStatus("Spawning: " .. _G.SelectedBus)
                Remotes:WaitForChild("SpawnCar"):FireServer(_G.SelectedBus)
                task.wait(4)
                local bus = GetMyBus()
                
                if bus and bus:FindFirstChild("DriveSeat") then
                    bus.DriveSeat:Sit(hum)
                    task.wait(2)
                    
                    SetStatus("get job...")
                    Remotes:WaitForChild("StartBusJob"):InvokeServer
                 (Baranangsiang_ke_Cirebon2)
                    task.wait(1)
                    
                    hum.Jump = true
                    task.wait(1.5)
                    
                    SetStatus("Spawn vehicle..")
                    Remotes:WaitForChild("SpawnCar"):FireServer(_G.SelectedBus)
                    task.wait(4)
                    bus = GetMyBus() 
                    
                    if bus and bus:FindFirstChild("DriveSeat") then
                        bus.DriveSeat:Sit(hum)
                        jobStarted = true
                    end
                end
            end
            
            local target = GetActiveStop()
            if target then
                noBillboardTime = 0 
                if target ~= lastTarget then
                    -- PROSES TP AWAL
                    SetFreeze(true) 
                    task.wait(0.2)
                    InstantTP(target.CFrame)
                    lastTarget = target
                    
                    -- PENGECEKAN 30 DETIK (Anti-Stuck / Return Zone)
                    for i = 1, 30 do
                        if not _G.AutoFull then break end
                        if infoLabel and string.find(string.upper(infoLabel.Text), "RETURN TO THE CHECKPOINT") then
                            SetStatus("Correction: TP Again!")
                            SetFreeze(false)
                            task.wait(0.5)
                            InstantTP(target.CFrame)
                            task.wait(0.5)
                            SetFreeze(true)
                        else
                            SetStatus("Position Secure...")
                        end
                        task.wait(1)
                    end
                    
                    -- SISA WAKTU FREEZE (45 - 30 = 15s)
                    for i = 15, 1, -1 do
                        if not _G.AutoFull then break end
                        SetStatus("To Stations: " .. i .. "s")
                        task.wait(1)
                    end
                    
                    SetFreeze(false)
                    
                    -- Timer 2: Total 2 Menit (120s - 45s = 75s)
                    for i = 77, 1, -1 do
                        if not _G.AutoFull then break end
                        SetStatus("Delay TP: " .. i .. "s")
                        task.wait(1)
                    end
                end
            else
                if jobStarted then
                    noBillboardTime = noBillboardTime + 1
                    SetStatus("Searching Stop: " .. (40 - noBillboardTime) .. "s")
                    
                    if noBillboardTime >= 40 then
                        SetStatus("Finishing Job...")
                        SetFreeze(true)
                        task.wait(0.2)
                        InstantTP(CirebonEndCF)
                        
                        task.wait(2)
                        SetFreeze(false)
                        jobStarted = false
                        lastTarget = nil
                        noBillboardTime = 0
                        
                        local bus = GetMyBus()
                        if bus then bus:Destroy() end 
                        
                        SetStatus("Job Finished! Restarting...")
                        task.wait(3) 
                    end
                end
            end
            task.wait(1)
        end
    end
})



MainTab:CreateSection("Auto Stop Settings")

-- INPUT NOMINAL
MainTab:CreateInput({
   Name = "Set Target Money",
   PlaceholderText = "input your target",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      -- Logic: Hilangkan titik agar menjadi angka murni
      local cleanNumber = Text:gsub("%.", "")
      TargetUang = tonumber(cleanNumber) or 0
      
      Rayfield:Notify({
         Title = "Target Set",
         Content = "money target is set to: Rp " .. formatRS(TargetUang),
         Duration = 3
      })
   end,
})


MainTab:CreateToggle({
   Name = "Enable Auto-Kick",
   CurrentValue = false,
   Flag = "AutoKick",
   Callback = function(Value)
      _G.AutoKickEnabled = Value
      
      if Value then
          -- Jalankan Loop Pengecekan
          task.spawn(function()
              while _G.AutoKickEnabled do
                  local currentMoney = StatsFolder.Uang.Value
                  if TargetUang > 0 and currentMoney >= TargetUang then
                      LP:Kick("\n[VoidlineHub]\nTarget money reached!\nTotal: Rp " .. formatRS(currentMoney))
                      break
                  end
                  task.wait(2) -- Cek tiap 2 detik biar gak berat
              end
          end)
      else
      end
   end,
})



local ConfigTab = Window:CreateTab("Configuration", "settings")
ConfigTab:CreateSection("Select Spawner Vehicle")

local BusDropdown = ConfigTab:CreateDropdown({
   Name = "Select Owned Bus",
   Options = busOptions,
   CurrentOption = {busOptions[1]},
   MultipleOptions = false,
   Callback = function(Option)
      _G.SelectedBus = Option[1]
      SetStatus("Selected: " .. _G.SelectedBus)
   end,
})

ConfigTab:CreateButton({
   Name = "Refresh Garage List",
   Callback = function()
       local newOptions = {}
       for _, car in pairs(OwnedCarsFolder:GetChildren()) do
           table.insert(newOptions, car.Name)
       end
       BusDropdown:Set(newOptions)
   end,
})

ConfigTab:CreateSection("Webhook")

ConfigTab:CreateInput({
   Name = "Discord Webhook URL",
   PlaceholderText = "Paste URL Here",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      _G.WebhookURL = Text
      Rayfield:Notify({
         Title = "Webhook Updated",
         Content = "URL has been saved.",
         Duration = 3,
         Image = "link",
      })
   end,
})

ConfigTab:CreateToggle({
   Name = "Enable Webhook Report",
   CurrentValue = false,
   Callback = function(Value)
      _G.WebhookEnabled = Value -- Variabel tambahan buat kontrol kirim/enggak
      
      if Value then
         if _G.WebhookURL == "" or not _G.WebhookURL:find("discord.com") then
            Rayfield:Notify({
               Title = "Webhook Error",
               Content = "Please enter a valid Discord Webhook URL first!",
               Duration = 5,
               Image = "alert-triangle",
            })
         else
            SetStatus("Webhook Active")
         end
      end
   end,
})


local StatsTab = Window:CreateTab("Stats", "trending-up")

StatsTab:CreateSection("Info Farm")
StatusLabel = StatsTab:CreateLabel("Status: Waiting", "clock")
UangLabel = StatsTab:CreateLabel("Uang: Rp " .. StartUang, "banknote")
EarningLabel = StatsTab:CreateLabel("Earning: Rp 0", "coins")
TimeLabel = StatsTab:CreateLabel("Time: 00:00:00", "timer")

StatsTab:CreateSection("System Info")
FPSLabel = StatsTab:CreateLabel("FPS: Scanning...", "monitor")
PingLabel = StatsTab:CreateLabel("Ping: Scanning...", "wifi")


-- // CREATE MORE FEATURES TAB
local MoreTab = Window:CreateTab("More Features", "plus-circle") -- Kamu bisa ganti icon-nya sesuai selera

-- SECTION: MISC & SECURITY
MoreTab:CreateSection("important features")
-- ANTI AFK TOGGLE
MoreTab:CreateToggle({
   Name = "Anti-AFK System",
   CurrentValue = false, -- Sesuai request, start-nya False
   Flag = "AntiAFK",
   Callback = function(Value)
      _G.AntiAFK = Value
      if _G.AntiAFK then
          SetStatus("Anti-AFK Enabled")
      else
          SetStatus("Anti-AFK Disabled")
      end
   end,
})


-- AUTO REJOIN
MoreTab:CreateToggle({
   Name = "Auto Rejoin",
   CurrentValue = false, -- Default False
   Flag = "AutoRejoin",
   Callback = function(Value)
      _G.AutoRejoin = Value
   end,
})


MoreTab:CreateSection("Visual & Performance")

-- HIDE NAME
MoreTab:CreateButton({
   Name = "Hide All Names",
   Callback = function()
      for _, v in pairs(workspace:GetDescendants()) do
          if v:IsA("BillboardGui") then
              v:Destroy()
          end
      end
      SetStatus("Names Hidden")
   end,
})

-- HIDE CHARACTER
MoreTab:CreateToggle({
   Name = "Hide Character",
   CurrentValue = false, -- Default False
   Flag = "HideChar",
   Callback = function(Value)
      local char = LP.Character
      if char then
          for _, part in pairs(char:GetDescendants()) do
              if part:IsA("BasePart") or part:IsA("Decal") then
                  part.Transparency = Value and 1 or 0
              end
          end
      end
   end,
})

-- FPS BOOST
MoreTab:CreateButton({
   Name = "FPS Boost",
   Callback = function()
      for _, v in pairs(workspace:GetDescendants()) do
          if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
              v.Material = Enum.Material.SmoothPlastic
          elseif v:IsA("Decal") or v:IsA("Texture") then
              v:Destroy()
          end
      end
      SetStatus("FPS Boosted")
   end,
})

-- SECTION: BUS DEALERSHIP
MoreTab:CreateSection("auto buy bus")

MoreTab:CreateDropdown({
   Name = "Select Bus to Purchase",
   Options = CarListData,
   CurrentOption = {CarListData[1] or "None"},
   MultipleOptions = false,
   Callback = function(Option)
      SelectedBusToBuy = Option[1]
   end,
})

MoreTab:CreateButton({
   Name = "Purchase Selected Bus",
   Callback = function()
      if SelectedBusToBuy == "" or SelectedBusToBuy == "None" then
          Rayfield:Notify({Title = "Error", Content = "Please select a bus first!", Duration = 3})
          return
      end

      Rayfield:Notify({
         Title = "Confirm Purchase",
         Content = "Buying: " .. SelectedBusToBuy .. ". Please wait...",
         Duration = 5,
         Image = "shopping-cart",
      })

      local success, err = pcall(function()
          Remotes:WaitForChild("BuyCar"):FireServer(SelectedBusToBuy)
      end)

      if success then
          SetStatus("Success Buying " .. SelectedBusToBuy)
      else
          SetStatus("Purchase Failed!")
          warn("Error: " .. tostring(err))
      end
   end,
})

-- SECTION: WORLD TELEPORT
MoreTab:CreateSection("World Teleport")

MoreTab:CreateDropdown({
   Name = "Select TP Destination",
   Options = {"Dealership", "Modifikasi", "Teleport City"},
   CurrentOption = {"Dealership"},
   MultipleOptions = false,
   Callback = function(Option)
      SelectedTP = Option[1]
   end,
})

MoreTab:CreateButton({
   Name = "Teleport Now",
   Callback = function()
      local targetCF = TP_Locations[SelectedTP]
      if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
          LP.Character:PivotTo(targetCF)
          SetStatus("Teleported to " .. SelectedTP)
      end
   end,
})

-- SECTION: OPEN UI / PROXIMITY
MoreTab:CreateSection("Open UI / Actions")

MoreTab:CreateDropdown({
   Name = "Select Menu to Open",
   Options = {"Dealership", "Modifikasi", "Teleport City"},
   CurrentOption = {"Dealership"},
   MultipleOptions = false,
   Callback = function(Option)
      SelectedAction = Option[1]
   end,
})

MoreTab:CreateButton({
   Name = "Open Selected Menu",
   Callback = function()
      if SelectedAction == "Dealership" then
          local p = workspace:FindFirstChild("BigBus_DealershipPart") and workspace.BigBus_DealershipPart:FindFirstChild("ProximityPrompt")
          if p then fireproximityprompt(p) end
      elseif SelectedAction == "Modifikasi" then
          local p = workspace.Modif.ModificationTriggerPart:FindFirstChild("ProximityPrompt")
          if p then fireproximityprompt(p) end
      elseif SelectedAction == "Teleport City" then
          local p = workspace:FindFirstChild("Telportpart") and workspace.Telportpart:FindFirstChild("ProximityPrompt")
          if p then fireproximityprompt(p) end
      end
      SetStatus("Opening " .. SelectedAction)
   end,
})        
