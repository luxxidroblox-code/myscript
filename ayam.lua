-- [[ Protected by DX-SR | ID: 61c8bfcc-a51f-4b76-8ac5-471bb10b3d77 ]] --
local player, VU = game:GetService("Players").LocalPlayer, game:GetService("VirtualUser")

-- Hapus instance yang mengganggu
pcall(function() workspace.Etc:Destroy() end)
pcall(function() game:GetService("ReplicatedStorage").NetworkContainer.RemoteEvents.NewModification:Destroy() end)
pcall(function() player.PlayerGui.NewModification:Destroy() end)
pcall(function() workspace.Map.Building.Modification:Destroy() end)

pcall(function()
    local bldg = workspace.Map.Building
    if bldg:FindFirstChild("Pertamana Small") then
        bldg["Pertamana Small"]:Destroy()
    end
end)

pcall(function()
    local stuff = workspace.Map.Stuff:GetChildren()
    if stuff[260] then stuff[260]:Destroy() end
    if stuff[1045] then stuff[1045]:Destroy() end
    if stuff[103] then
        local child86 = stuff[103]:GetChildren()[86]
        if child86 then child86:Destroy() end
    end
end)

pcall(function()
    local prop = workspace.Map.Prop
    if prop:FindFirstChild("Mitra Terrace") then
        prop["Mitra Terrace"]:Destroy()
    end
    
    local propGroups = prop:GetChildren()
    if propGroups[4] then
        local props = propGroups[4]:GetChildren()
        if props[46] then props[46]:Destroy() end
    end
end)

pcall(function()
    local melawai = workspace:FindFirstChild("MELAWAI")
    if melawai then
        local mChildren = melawai:GetChildren()
        if mChildren[359] then mChildren[359]:Destroy() end
        
        local model = melawai:FindFirstChild("Model")
        if model then
            local areaPlaza = model:FindFirstChild("AREA PLAZA BLOK M")
            if areaPlaza then
                if areaPlaza:FindFirstChild("Union") then areaPlaza.Union:Destroy() end
                
                local apChildren = areaPlaza:GetChildren()
                local toDelete = {350, 464, 549, 592, 623, 627, 631, 638, 643, 644, 679}
                for _, idx in ipairs(toDelete) do
                    if apChildren[idx] then apChildren[idx]:Destroy() end
                end
            end
        end
    end
end)

for _, c in getconnections(player.Idled) do
	pcall(c.Disable, c)
	pcall(c.Disconnect, c)
end

local con = player.Idled:Connect(function()
	VU:CaptureController()
	VU:ClickButton2(Vector2.zero)
end)

local unantiidle = function()
	if con then
		con:Disconnect()
		con = nil
	end
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

local isEventRunning = false
local targetEarningLimit = 0
local tweenSpeed = 190
local tweenHeight = 4
local tweenArriveDistance = 34
local minigameStart = 2
local minigameEnd = 18

local PromptButtonHoldBegan

local function uninstantpp()
	if PromptButtonHoldBegan then
		PromptButtonHoldBegan:Disconnect()
		PromptButtonHoldBegan = nil
	end
end

local function instantpp()
	if not fireproximityprompt then
		warn("Your exploit does not support this command (missing fireproximityprompt)")
		return
	end
	uninstantpp()
	task.wait(0.1)
	PromptButtonHoldBegan = game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(prompt)
		if prompt.Name ~= "AmbilPrompt" then
			pcall(function() fireproximityprompt(prompt) end)
		end
	end)
end

instantpp()

local function formatCurrency(amount)
    local formatted = tostring(math.floor(amount))
    local k
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return "Rp " .. formatted
end

local function getActiveCar()
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if vehiclesFolder then
        local expectedName = LocalPlayer.Name .. "sCar"
        local car = vehiclesFolder:FindFirstChild(expectedName)
        if car then
            -- Hapus roda biar suspensi gak ganggu gravitasi saat vfly/mendarat
            local wheels = car:FindFirstChild("Wheels") or car:FindFirstChild("wheels")
            if wheels then
                wheels:Destroy()
                
                -- Otomatis hapus part yang mengganggu di body (berdasarkan request)
                local body = car:FindFirstChild("Body")
                if body then
                    -- MainPart CanCollide false
                    local mainPart = body:FindFirstChild("MainPart")
                    if mainPart and mainPart:IsA("BasePart") then
                        mainPart.CanCollide = false
                    end
                    
                    local toDelete = {
                        "Body", "Lightbar", "Lights", "Plate", "Plate Text", "Prop",
                        "Hitbox", "FrontSensor", "BackSensor", "Cam", "DownforceF", "DownforceR", "Drag", "#Weight", "Dashcam",
                        "RM", "LM"
                    }
                    for _, name in ipairs(toDelete) do
                        -- Blacklist part penting dari auto delete
                        if name ~= "MainPart" and name ~= "BagasiPoint" and name ~= "WeldConstraint" then
                            local part = body:FindFirstChild(name)
                            if part then
                                pcall(function() part:Destroy() end)
                            end
                        end
                    end
                end
            end
            return car
        end
    end
    return nil
end

local function getKoperCount()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        local jobGui = pGui:FindFirstChild("Job")
        if jobGui then
            local bcGui = jobGui:FindFirstChild("BankCourier")
            if bcGui then
                local status = bcGui:FindFirstChild("Status")
                if status and status:FindFirstChild("Koper") then
                    local txt = status.Koper.Text
                    local currentStr, maxStr = string.match(txt, "(%d+)/(%d+)")
                    if currentStr and maxStr then
                        return tonumber(currentStr) or 0, tonumber(maxStr) or 4
                    end
                end
            end
        end
    end
    return 0, 4
end

local function getAtmCount()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        local jobGui = pGui:FindFirstChild("Job")
        if jobGui then
            local bcGui = jobGui:FindFirstChild("BankCourier")
            if bcGui then
                local status = bcGui:FindFirstChild("Status")
                if status and status:FindFirstChild("Atm") then
                    local txt = status.Atm.Text
                    local currentStr, maxStr = string.match(txt, "(%d+)/(%d+)")
                    if currentStr and maxStr then
                        return tonumber(currentStr) or 0, tonumber(maxStr) or 4
                    end
                end
            end
        end
    end
    return 0, 4
end

local function vehicleFlyTo(car, targetCFrame, speed)
    local root = car.PrimaryPart or car:FindFirstChild("DriveSeat")
    if not root then return end
    
    local targetPos = targetCFrame.Position
    local flySpeed = (speed or 150)
    
    -- Noclip loop: force CanCollide=false setiap frame untuk vehicle + player character
    local RunService = game:GetService("RunService")
    local noclipConn = RunService.Stepped:Connect(function()
        -- Vehicle noclip
        for _, v in ipairs(car:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
        -- Player character noclip (biar body player gak jadi anchor nabrak)
        local char = LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end)
    
    -- BodyGyro untuk menjaga orientasi mobil stabil
    local BG = Instance.new("BodyGyro")
    BG.P = 9e4
    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.D = 50
    BG.Parent = root
    
    -- BodyVelocity untuk menggerakkan mobil secara fisik (server register jarak)
    local BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BV.Velocity = Vector3.zero
    BV.Parent = root
    
    local arriveDistance = tweenArriveDistance or 40
    local timeout = os.clock()
    
    while isEventRunning do
        local currentPos = root.Position
        local direction = targetPos - currentPos
        local distance = direction.Magnitude
        
        if distance < arriveDistance then break end
        if os.clock() - timeout > 300 then break end -- hard timeout 5 menit
        
        -- Arahkan velocity ke target
        BV.Velocity = direction.Unit * flySpeed
        -- Arahkan orientasi ke target
        BG.CFrame = CFrame.lookAt(currentPos, targetPos)
        
        task.wait()
    end
    
    -- Perlambat dan berhenti
    BV.Velocity = Vector3.zero
    task.wait(0.2)
    
    -- Cleanup physics
    BG:Destroy()
    BV:Destroy()
    
    -- Matikan sisa momentum dari BodyVelocity biar mobil berhenti total (gak nyelonong/mental)
    for _, v in ipairs(car:GetDescendants()) do
        if v:IsA("BasePart") then
            v.AssemblyLinearVelocity = Vector3.zero
            v.AssemblyAngularVelocity = Vector3.zero
        end
    end
    
    -- Stop noclip dan restore collision
    noclipConn:Disconnect()
    for _, v in ipairs(car:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = true
        end
    end
    
    -- Pulihkan juga collision character player biar nggak jatuh ke void saat keluar mobil
    local char = LocalPlayer.Character
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
            end
        end
    end
end

local function handleMinigames()
    task.spawn(function()
        local VirtualInputManager = game:GetService("VirtualInputManager")
        while true do
            task.wait(0.05)
            if not isEventRunning then continue end
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not pGui then continue end
            
            local jobGui = pGui:FindFirstChild("Job")
            if not jobGui then continue end
            
            local bcGui = jobGui:FindFirstChild("BankCourier")
            if not bcGui then continue end
            
            local timing = bcGui:FindFirstChild("Timing")
            if timing and timing.Visible then
                local koper = timing:FindFirstChild("Track") and timing.Track:FindFirstChild("Koper")
                local slot = timing:FindFirstChild("Trunk") and timing.Trunk:FindFirstChild("Slot")
                
                -- 1. Minigame Load Koper (Timing)
                if koper and slot and koper.Visible and slot.Visible then
                    local kX = koper.Position.X.Scale
                    local sX = slot.Position.X.Scale
                    local sW = slot.Size.X.Scale
                    
                    if kX >= (sX + 0.02) and kX <= (sX + sW - 0.02) then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                        task.wait(0.5) 
                    end
                end
            end
            
            -- 2. Minigame Isi ATM (Skill - Jarum Berputar)
            local skill = bcGui:FindFirstChild("Skill")
            if skill and skill.Visible then
                local needleArm = skill:FindFirstChild("NeedleArm")
                local zoneArc = skill:FindFirstChild("ZoneArc")
                local greatArc = skill:FindFirstChild("GreatArc")
                
                if needleArm and needleArm.Visible then
                    local nRot = needleArm.Rotation % 360
                    
                    if greatArc and greatArc.Visible then
                        local gRot = greatArc.Rotation % 360
                        local gDiff = (nRot - gRot) % 360
                        if gDiff > minigameStart and gDiff < minigameEnd then
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                            task.wait(0.05)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                            task.wait(0.5)
                        end
                    elseif zoneArc and zoneArc.Visible then
                        local zRot = zoneArc.Rotation % 360
                        local diff = (nRot - zRot) % 360
                        if diff > 8 and diff < 25 then
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                            task.wait(0.05)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end)
end

local function teleportPlayer(targetCFrame)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        hrp.CFrame = targetCFrame
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function teleportWithSlowmoDrop(targetCFrame, dropHeight, dropTime)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        
        -- Pindah ke posisi tinggi dulu
        local startCFrame = targetCFrame * CFrame.new(0, dropHeight, 0)
        hrp.CFrame = startCFrame
        hrp.Anchored = true
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        
        -- Lerp lambat ke bawah
        local startTime = os.clock()
        while (os.clock() - startTime) < dropTime and isEventRunning do
            local elapsed = os.clock() - startTime
            local alpha = elapsed / dropTime
            hrp.CFrame = startCFrame:Lerp(targetCFrame, alpha)
            task.wait()
        end
        
        if isEventRunning then
            hrp.CFrame = targetCFrame
        end
        
        hrp.Anchored = false
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function firePrompt(prompt)
    if prompt then
        local oldLoS = prompt.RequiresLineOfSight
        local oldDist = prompt.MaxActivationDistance
        
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 50
        
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.1)
            prompt:InputHoldEnd()
        end
        
        task.delay(0.5, function()
            if prompt and prompt.Parent then
                prompt.RequiresLineOfSight = oldLoS
                prompt.MaxActivationDistance = oldDist
            end
        end)
    end
end

local function holdPromptKey(prompt, keyCode, customDuration)
    if prompt then
        local oldLoS = prompt.RequiresLineOfSight
        local oldDist = prompt.MaxActivationDistance
        
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 50
        
        local VirtualInputManager = game:GetService("VirtualInputManager")
        local duration = customDuration or (prompt.HoldDuration > 0 and (prompt.HoldDuration + 0.2) or 2.2)
        
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(duration)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        
        task.delay(0.5, function()
            if prompt and prompt.Parent then
                prompt.RequiresLineOfSight = oldLoS
                prompt.MaxActivationDistance = oldDist
            end
        end)
    end
end

local function forceLookAt(targetPosition, lockDuration)
    local cam = Workspace.CurrentCamera
    if cam then
        cam.CameraType = Enum.CameraType.Scriptable
        local targetCFrame = CFrame.lookAt(cam.CFrame.Position, targetPosition)
        
        local TweenService = game:GetService("TweenService")
        local tween = TweenService:Create(cam, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait()
        
        -- Kunci lookat selama waktu tertentu (default 0.8 detik) biar prompt valid
        task.spawn(function()
            task.wait(lockDuration or 0.8)
            cam.CameraType = Enum.CameraType.Custom
        end)
    end
end

local function startBCAEventLogic()
    handleMinigames()

    local bcaFolder = Workspace:WaitForChild("MY_BCA_COLLAB", 10)
    if not bcaFolder then
        warn("BCA Event folder not found!")
        return
    end

    local hasFinishedDelivery = false

    while isEventRunning do
        -- Tahap 1: Ke Andhini
        local andhiniCFrame = CFrame.new(1804, 23, -4632)
        teleportWithSlowmoDrop(andhiniCFrame, 60, 2.5) -- Mulai 60 stud di atas, turun perlahan selama 2.5 detik
        task.wait(0.5)

        local andhini = bcaFolder:FindFirstChild("NPC_START_JOB")
        if andhini and andhini:FindFirstChild("HumanoidRootPart") then
            local prompt = andhini.HumanoidRootPart:FindFirstChild("DialogPrompt")
            if prompt then
                if hasFinishedDelivery then
                    -- Trigger dialog claim reward
                    forceLookAt(andhini.HumanoidRootPart.Position)
                    firePrompt(prompt)
                    task.wait(1.5) -- Tunggu dialog beneran kebuka dulu
                    
                    -- Spam enter beberapa kali untuk menyelesaikan dialog reward
                    local VirtualInputManager = game:GetService("VirtualInputManager")
                    for i = 1, 6 do
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                        task.wait(0.2)
                    end
                    task.wait(0.5)
                end
                
                local dialogFinished = false
                
                -- Hook remote event to detect when dialog is finished by server
                local jobRemote = ReplicatedStorage:WaitForChild("NetworkContainer"):WaitForChild("RemoteEvents"):WaitForChild("Job")
                local msgRemote = ReplicatedStorage:WaitForChild("NetworkContainer"):WaitForChild("RemoteEvents"):WaitForChild("MessageNotification")
                
                local jobConn = jobRemote.OnClientEvent:Connect(function(action, jobName)
                    if action == "SetJob" and jobName == "BankCourier" then
                        dialogFinished = true
                    end
                end)
                
                local msgConn = msgRemote.OnClientEvent:Connect(function(title, desc)
                    if title == "KURIR BANK" then
                        dialogFinished = true
                    end
                end)

                -- Mulai Dialog Job (Firing 1 KALI SAJA)
                forceLookAt(andhini.HumanoidRootPart.Position)
                firePrompt(prompt)
                
                task.wait(1.5) -- Tunggu UI dialog masuk
                
                -- Spam enter sampai remote trigger (dialog selesai)
                local VirtualInputManager = game:GetService("VirtualInputManager")
                local dialogStart = os.clock()
                
                while not dialogFinished and isEventRunning do
                    if os.clock() - dialogStart > 10 then break end -- timeout 10 detik
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    task.wait(0.2)
                end
                
                -- Cleanup connections
                if jobConn then jobConn:Disconnect() end
                if msgConn then msgConn:Disconnect() end
            end
        end

        -- Tahap 2: Ke Putra (Spawn Mobil)
        local car = getActiveCar()
        if not car then
            local putraCFrame = CFrame.new(1869, 22, -4879)
            teleportPlayer(putraCFrame)
            task.wait(0.5)

            local putra = bcaFolder:FindFirstChild("CAR_SPAWNER_NPC")
            if putra and putra:FindFirstChild("HumanoidRootPart") then
                local prompt = putra.HumanoidRootPart:FindFirstChild("DialogPrompt")
                if prompt then
                    -- Mulai Dialog Spawn Mobil (Firing 1 KALI SAJA)
                    forceLookAt(putra.HumanoidRootPart.Position)
                    firePrompt(prompt)
                    
                    task.wait(1.5) -- Tunggu UI dialog masuk

                    -- Click layar (pake Enter) sampe mobil spawn (detect car ready)
                    local VirtualInputManager = game:GetService("VirtualInputManager")
                    local dialogStart = os.clock()
                    
                    while not getActiveCar() and isEventRunning do
                        if os.clock() - dialogStart > 10 then break end -- timeout 10 detik
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                        task.wait(0.2)
                    end
                end
            end
        end
        
        -- Anchor mobil pas player keliling ngambil koper (biar nggak terbang kesenggol noclip)
        car = getActiveCar()
        if car then
            task.wait(1) -- Tunggu bentar biar mobil mendarat sempurna pas baru spawn
            for _, v in ipairs(car:GetDescendants()) do
                if v:IsA("BasePart") then v.Anchored = true end
            end
        end

        -- Tahap 3: Ambil Koper & Minigame
        local currentKoper, maxKoper = getKoperCount()
        local koperSpawn = bcaFolder:FindFirstChild("Job") and bcaFolder.Job:FindFirstChild("BankCourier") and bcaFolder.Job.BankCourier:FindFirstChild("KoperSpawn")
        
        while currentKoper < maxKoper and isEventRunning do
            car = getActiveCar()
            if not car then break end

            -- 1. Ambil koper dari spawn
            if koperSpawn and koperSpawn:FindFirstChild("Part") then
                local prompt = koperSpawn.Part:FindFirstChild("Prompt")
                if prompt then
                    teleportPlayer(koperSpawn.Part.CFrame + Vector3.new(0, 2, 0))
                    task.wait(0.5)
                    forceLookAt(koperSpawn.Part.Position)
                    firePrompt(prompt)
                    task.wait(0.5)
                end
            end
            
            -- 2. Bawa ke Bagasi mobil dan mulai minigame
            local bagasiPoint = car:FindFirstChild("BagasiPoint")
            if bagasiPoint then
                local muatPrompt = bagasiPoint:FindFirstChild("MuatPrompt")
                if muatPrompt then
                    local awayVector = (bagasiPoint.Position - car:GetPivot().Position).Unit
                    teleportPlayer(CFrame.new(bagasiPoint.Position + awayVector * 4 + Vector3.new(0, 4, 0)))
                    task.wait(0.5)
                    forceLookAt(bagasiPoint.Position)
                    firePrompt(muatPrompt)
                    
                    -- Tunggu sampai jumlah koper bertambah
                    local kC, mK = getKoperCount()
                    local waitStart = os.clock()
                    while kC == currentKoper and isEventRunning do
                        task.wait(0.5)
                        kC, mK = getKoperCount()
                        if os.clock() - waitStart > 10 then break end -- timeout
                    end
                    currentKoper = kC
                    maxKoper = mK
                end
            end
        end

        -- Tahap 4: Antar ke ATM
        local currentAtm, maxAtm = getAtmCount()
        while currentAtm < maxAtm and isEventRunning do
            car = getActiveCar()
            if not car then break end

            -- 1. Duduk di DriveSeat
            local driveSeat = car:FindFirstChild("DriveSeat")
            if driveSeat then
                local prompt = driveSeat:FindFirstChild("PromptDriveSeat")
                if prompt then
                    teleportPlayer(driveSeat.CFrame + Vector3.new(0, 2, 0))
                    task.wait(0.5)
                    firePrompt(prompt)
                    task.wait(1)
                end
            end
            
            -- UNANCHOR KARENA PLAYER UDAH DI DALAM MOBIL (Aman buat terbang)
            for _, v in ipairs(car:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Anchored = false
                end
            end
            
            -- 2. Tween Mobil ke Destination (BankCourierRoute.To)
            local routeFolder = Workspace:FindFirstChild("BankCourierRoute")
            local targetNode = routeFolder and routeFolder:FindFirstChild("To")
            if targetNode then
                -- Gunakan CFrame langsung dari node rute
                local targetCFrame = targetNode:IsA("CFrameValue") and targetNode.Value or targetNode.CFrame
                local finalCFrame = targetCFrame + Vector3.new(0, tweenHeight, 0)
                vehicleFlyTo(car, finalCFrame, tweenSpeed)
                
                -- Biarkan gravitasi menarik mobil ke tanah (mendarat)
                task.wait(1.5)
            else
                -- Fallback jika rute tidak ditemukan
                local target = Workspace:FindFirstChild("__BankCourierTarget")
                if target then
                    local carPos = car:GetPivot().Position
                    local targetPos = target.Position
                    
                    local dir = (carPos - targetPos)
                    local flatDir = Vector3.new(dir.X, 0, dir.Z)
                    if flatDir.Magnitude < 0.1 then
                        flatDir = Vector3.new(1, 0, 0)
                    end
                    
                    local stopPos = targetPos + flatDir.Unit * 20
                    stopPos = stopPos + Vector3.new(0, tweenHeight, 0)
                    
                    local finalCFrame = CFrame.lookAt(stopPos, targetPos)
                    vehicleFlyTo(car, finalCFrame, tweenSpeed)
                    
                    -- Biarkan gravitasi menarik mobil ke tanah (mendarat)
                    task.wait(1.5)
                end
            end
            
            -- Anchor mobil SECARA PERMANEN selama player di luar mobil
            for _, v in ipairs(car:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Anchored = true
                end
            end

            -- 3. Lompat dari kursi
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Sit = false
                task.wait(0.2)
                humanoid.Jump = true
                task.wait(0.5)
            end

            local bagasiPoint = car:FindFirstChild("BagasiPoint")
            if bagasiPoint then
                local ambilPrompt = bagasiPoint:FindFirstChild("AmbilPrompt")
                if ambilPrompt then
                    local holdKoperStart = os.clock()
                    while isEventRunning do
                        -- Cek apakah Koper sudah dipegang (ada di dalam model karakter player)
                        local charFolder = Workspace:FindFirstChild("Lives")
                        local myChar = charFolder and charFolder:FindFirstChild(LocalPlayer.Name) or LocalPlayer.Character
                        if myChar and myChar:FindFirstChild("KoperUang") then
                            break
                        end
                        if os.clock() - holdKoperStart > 15 then break end -- timeout 15 detik
                        
                        local awayVector = (bagasiPoint.Position - car:GetPivot().Position).Unit
                        teleportPlayer(CFrame.new(bagasiPoint.Position + awayVector * 4 + Vector3.new(0, 4, 0)))
                        task.wait(0.2)
                        forceLookAt(bagasiPoint.Position)
                        holdPromptKey(ambilPrompt, Enum.KeyCode.F)
                        task.wait(0.5)
                    end
                end
            end

            -- 5. Ke ATM dan isi
            local routeFolder = Workspace:FindFirstChild("BankCourierRoute")
            local targetNode = routeFolder and routeFolder:FindFirstChild("To")
            if targetNode then
                local targetCFrame = targetNode:IsA("CFrameValue") and targetNode.Value or targetNode.CFrame
                local targetPos = targetCFrame.Position
                
                -- Posisi berdiri langsung di titik To (sejauh 3 stud di atas atm)
                teleportPlayer(targetCFrame + Vector3.new(0, 3, 0))
                task.wait(0.2)
                
                -- Anchor karakter player supaya ragdoll physics / collision saat jatuh gak bikin mencelat
                local char = LocalPlayer.Character
                if char then
                    for _, v in ipairs(char:GetDescendants()) do
                        if v:IsA("BasePart") then v.Anchored = true end
                    end
                end
                
                -- LookAt instan (tanpa tween)
                local cam = Workspace.CurrentCamera
                if cam then
                    cam.CameraType = Enum.CameraType.Scriptable
                    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetPos)
                    task.spawn(function()
                        task.wait(0.8)
                        cam.CameraType = Enum.CameraType.Custom
                    end)
                end
                
                local isiStart = os.clock()
                while isEventRunning do
                    -- Cek sukses 1: Minigame UI muncul
                    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                    local skillUi = pGui and pGui:FindFirstChild("Job") and pGui.Job:FindFirstChild("BankCourier") and pGui.Job.BankCourier:FindFirstChild("Skill")
                    if skillUi and skillUi.Visible then break end
                    
                    -- Cek sukses 2: KoperUang hilang dari tangan
                    local charFolder = Workspace:FindFirstChild("Lives")
                    local myChar = charFolder and charFolder:FindFirstChild(LocalPlayer.Name) or LocalPlayer.Character
                    if myChar and not myChar:FindFirstChild("KoperUang") then
                        break
                    end
                    
                    -- Cek sukses 3: Jumlah ATM bertambah
                    local cAtm, mAtm = getAtmCount()
                    if cAtm > currentAtm then break end
                    
                    if os.clock() - isiStart > 15 then break end
                    
                    -- Cari prompt di dalam To atau gunakan VIM
                    local isiPrompt = targetNode:FindFirstChild("IsiAtmPrompt", true)
                    if isiPrompt then
                        holdPromptKey(isiPrompt, Enum.KeyCode.F, 0.3)
                        -- Jaga-jaga kalau VIM gagal: panggil method instant executor
                        if fireproximityprompt then
                            pcall(function() fireproximityprompt(isiPrompt) end)
                        end
                        -- Jaga-jaga kalau instant executor gagal: panggil method internal Roblox
                        pcall(function()
                            isiPrompt:InputHoldBegin()
                            task.wait(0.1)
                            isiPrompt:InputHoldEnd()
                        end)
                    else
                        local VirtualInputManager = game:GetService("VirtualInputManager")
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                    end
                    task.wait(0.5)
                end
                
                -- Tunggu minigame skill selesai & ATM terisi
                local cAtm, mAtm = getAtmCount()
                local waitStart = os.clock()
                while cAtm == currentAtm and isEventRunning do
                    task.wait(0.5)
                    cAtm, mAtm = getAtmCount()
                    if os.clock() - waitStart > 15 then break end -- timeout
                end
                
                -- Pastikan marker destination sudah pindah tempat ke ATM berikutnya sebelum lanjut
                if cAtm > currentAtm and cAtm < mAtm then
                    local moveWaitStart = os.clock()
                    local oldPos = targetPos
                    while isEventRunning do
                        local newNode = routeFolder and routeFolder:FindFirstChild("To")
                        local newPos = newNode and (newNode:IsA("CFrameValue") and newNode.Value.Position or newNode.Position)
                        if newPos and newPos ~= oldPos then
                            break
                        end
                        task.wait(0.1)
                        if os.clock() - moveWaitStart > 5 then break end
                    end
                end
                
                -- Unanchor karakter supaya bisa bergerak / terbang sama mobil lagi
                local char = LocalPlayer.Character
                if char then
                    for _, v in ipairs(char:GetDescendants()) do
                        if v:IsA("BasePart") then v.Anchored = false end
                    end
                end
                
                currentAtm = cAtm
                maxAtm = mAtm
            end
        end

        -- Kembali ke Andhini untuk diulangi (sesuai while loop utama)
        hasFinishedDelivery = true
        task.wait(2)
        
        local currentEarned = _G.TotalEarned or 0
        local cycleEarned = currentEarned - (_G.LastCycleEarned or 0)
        if cycleEarned > 0 then
            WindUI:Notify({
                Title = "Job Completed",
                Content = "Kamu mendapatkan " .. formatCurrency(cycleEarned) .. " dari shift ini!",
                Duration = 5,
                Icon = "wallet",
            })
        end
        _G.LastCycleEarned = currentEarned
    end
end

local webhookUrl = ""
local webhookEnabled = false

-- =====================================
-- WindUI Load & Interface
-- =====================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "CDID x BCA",
    Icon = "van", 
    Author = "DX-SR Hub",
    Folder = "DX-SR",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey = Enum.KeyCode.V,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = false,
    ScrollBarEnabled = false
})

Window:Tag({
    Title = "v1.9B",
    Icon = "github",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 13,
})

Window:Tag({
    Title = "DX-SR Hub",
    Icon = "text-cursor",
    Color = Color3.fromHex("#1E3A8A"),
    Radius = 13,
})

WindUI:Popup({
    Title = "Update log",
    Icon = "info",
    Content = "Fixed Weld constrant are not avaible.",
    Buttons = {
        {
            Title = "Continue",
            Icon = "arrow-right",
            Callback = function() end,
            Variant = "Primary",
        }
    }
})

local Tab = Window:Tab({
    Title = "Farming",
    Icon = "car"
})

local Section = Tab:Section({
    Title = "Auto BCA"
})

Tab:Space()



Tab:Slider({
    Title = "Car tween height",
    Step = 1,
    Value = {
        Min = 0,
        Max = 200,
        Default = 4,
    },
    Flag = "TweenHeight",
    Callback = function(value)
        tweenHeight = value
    end
})

Tab:Slider({
    Title = "Arrive distance",
    Step = 1,
    Value = {
        Min = 0,
        Max = 100,
        Default = tweenArriveDistance,
    },
    Flag = "ArriveDistance",
    Callback = function(value)
        tweenArriveDistance = value
    end
})

Tab:Input({
    Title = "Target Earning",
    Desc = "Auto stop when reached (e.g. 1500000000). 0 for infinite.",
    Default = "0",
    PlaceholderText = "3500000000",
    Flag = "TargetEarning",
    Callback = function(text)
        local num = tonumber((string.gsub(text, "[^%d]", ""))) or 0
        targetEarningLimit = num
    end
})

Tab:Toggle({
    Title = "Auto farm BCA",
    Callback = function(state)
        isEventRunning = state
        if isEventRunning then
            task.spawn(startBCAEventLogic)
        end
    end,
    Default = false
})

local SettingsSection = Tab:Section({
    Title = "Settings"
})

Tab:Space()

Tab:Slider({
    Title = "Start",
    Step = 1,
    Value = {
        Min = 0,
        Max = 10,
        Default = minigameStart,
    },
    Flag = "MinigameStart",
    Callback = function(value)
        minigameStart = value
    end
})

Tab:Slider({
    Title = "End",
    Step = 1,
    Value = {
        Min = 5,
        Max = 25,
        Default = minigameEnd,
    },
    Flag = "MinigameEnd",
    Callback = function(value)
        minigameEnd = value
    end
})

Tab:Space()

local InfoSection = Tab:Section({
    Title = "Information"
})

Tab:Space()

local timePara = Tab:Paragraph({
    Title = "Time Elapsed",
    Desc = "00:00:00"
})

local liveCurPara = Tab:Paragraph({
    Title = "Live Currency",
    Desc = "Loading..."
})

local mEarningPara = Tab:Paragraph({
    Title = "Money earning per/Hour",
    Desc = "Loading..."
})

local totalEarnedPara = Tab:Paragraph({
    Title = "Total Earning",
    Desc = "Loading..."
})

local scriptStartTick = tick()

local function parseCurrency(text)
    if not text then return 0 end
    local numStr = string.gsub(text, "[^%d]", "")
    return tonumber(numStr) or 0
end

local function formatCurrency(amount)
    local formatted = tostring(math.floor(amount))
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then
            break
        end
    end
    return "Rp. " .. formatted
end

local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local currentLiveCurText = "0"
local currentMPerHourText = "0"
local currentTotalEarnedText = "0"
local currentTimeElapsedText = "0"

local globalTotalEarned = 0
local lastObservedSalary = -1

task.spawn(function()
    while true do
        task.wait(1)
        
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            -- Time Elapsed Update
            local totalElapsed = tick() - scriptStartTick
            if totalElapsed > 0 then
                currentTimeElapsedText = formatTime(totalElapsed)
                timePara:SetDesc(currentTimeElapsedText)
            end
            
            -- Live Currency (Cuma buat ditampilin di Webhook & UI)
            local liveCurText = "0"
            local mGui = pGui:FindFirstChild("Main")
            if mGui and mGui:FindFirstChild("Container") and mGui.Container:FindFirstChild("Hub") then
                local cashFrame = mGui.Container.Hub:FindFirstChild("CashFrame")
                if cashFrame and cashFrame:FindFirstChild("Frame") and cashFrame.Frame:FindFirstChild("TextLabel") then
                    liveCurText = cashFrame.Frame.TextLabel.Text
                end
            end
            currentLiveCurText = liveCurText
            liveCurPara:SetDesc(liveCurText)
            
            -- Logika Total Earning (Diambil akurat dari Salary UI)
            local jobGui = pGui:FindFirstChild("Job")
            if jobGui and jobGui:FindFirstChild("BankCourier") then
                local salaryLabel = jobGui.BankCourier:FindFirstChild("Status") and jobGui.BankCourier.Status:FindFirstChild("Salary")
                if salaryLabel then
                    local currentSalary = parseCurrency(salaryLabel.Text)
                    
                    if lastObservedSalary == -1 then
                        -- Set base pertama kali baca (misal start dari 4,000,000)
                        lastObservedSalary = currentSalary
                    elseif currentSalary > lastObservedSalary then
                        -- Uang bertambah (Berhasil drop koper ke ATM)
                        local earnedThisTick = currentSalary - lastObservedSalary
                        globalTotalEarned = globalTotalEarned + earnedThisTick
                        lastObservedSalary = currentSalary
                        
                        -- Cek target earning
                        if targetEarningLimit > 0 and globalTotalEarned >= targetEarningLimit then
                            isEventRunning = false
                            
                            -- Notif In-Game
                            local StarterGui = game:GetService("StarterGui")
                            pcall(function()
                                StarterGui:SetCore("SendNotification", {
                                    Title = "Target Reached!",
                                    Text = "You have reached " .. formatCurrency(globalTotalEarned) .. ". Auto farm stopped.",
                                    Duration = 10,
                                })
                            end)
                        end
                        
                        -- Trigger webhook karena cuan nambah
                        if _G.SendWebhook then
                            _G.SendWebhook(false)
                        end
                    elseif currentSalary < lastObservedSalary then
                        -- Quest kereset (Misal dari 4.015.000 balik ke modal awal 4.000.000)
                        lastObservedSalary = currentSalary
                    end
                end
            end
            
            -- Update UI Total Earned & Per Hour
            currentTotalEarnedText = formatCurrency(globalTotalEarned)
            totalEarnedPara:SetDesc(currentTotalEarnedText)
            
            if totalElapsed > 0 then
                local mPerHour = (globalTotalEarned / totalElapsed) * 3600
                currentMPerHourText = formatCurrency(mPerHour)
                mEarningPara:SetDesc(currentMPerHourText)
            end
        end
    end
end)

-- ==================== WEBHOOK SYSTEM ====================
local WebhookTab = Window:Tab({
    Title = "Webhook",
    Icon = "globe"
})

WebhookTab:Input({
    Title = "Webhook URL",
    Desc = "Discord Webhook URL",
    Default = webhookUrl,
    PlaceholderText = "https://discord.com/api/webhooks/...",
    Flag = "WebhookUrl",
    Callback = function(text)
        webhookUrl = text
    end
})

WebhookTab:Toggle({
    Title = "Enable Webhook",
    Flag = "WebhookEnabled",
    Callback = function(state)
        webhookEnabled = state
    end,
    Default = webhookEnabled
})

_G.SendWebhook = function(isDisconnect, customMsg)
    if not webhookEnabled or webhookUrl == "" then return end
    
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
    if not httprequest then return end
    
    local pingMsg = isDisconnect and "@everyone " or ""
    local titleText = isDisconnect and "ðŸš¨ DISCONNECTED" or "ðŸ’° DELIVERY SUCCESS"
    local colorHex = isDisconnect and 16711680 or 65280
    
    local payload = {
        content = pingMsg,
        embeds = {{
            title = titleText,
            description = isDisconnect and ("Reason: " .. (customMsg or "Unknown")) or "Berhasil setor koper ke ATM!",
            color = colorHex,
            fields = {
                {name = "Live Currency", value = currentLiveCurText, inline = true},
                {name = "Money Per Hour", value = currentMPerHourText, inline = true},
                {name = "Total Earning", value = currentTotalEarnedText, inline = true},
                {name = "Time Elapsed", value = currentTimeElapsedText, inline = true}
            },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }
    
    local HttpService = game:GetService("HttpService")
    task.spawn(function()
        pcall(function()
            httprequest({
                Url = webhookUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

-- Detect Disconnect (NetworkClient / GuiError / Game Closed)
local GuiService = game:GetService("GuiService")
GuiService.ErrorMessageChanged:Connect(function(errMsg)
    if errMsg and errMsg ~= "" then
        _G.SendWebhook(true, errMsg)
    end
end)

-- ==================== CONFIGURATION TAB ====================
local ConfigTab = Window:Tab({
    Title = "Configuration",
    Icon = "settings"
})

-- Theme Section
local ThemeSection = ConfigTab:Section({
    Title = "Theme"
})

local themeList = {}
pcall(function()
    local themes = WindUI:GetThemes()
    if themes then
        for k, v in pairs(themes) do
            if type(v) == "string" then
                table.insert(themeList, v)
            elseif type(k) == "string" then
                table.insert(themeList, k)
            end
        end
    end
end)

if #themeList == 0 then
    themeList = {
        "Dark", "Light", "Rose", "Plant", "Red", "Indigo", 
        "Sky", "Violet", "Amber", "Emerald", "Midnight", 
        "Crimson", "Monokai Pro", "Cotton Candy", "Mellowsi", "Rainbow"
    }
end

ConfigTab:Dropdown({
    Title = "Select Theme",
    Desc = "Choose UI Theme",
    Multi = false,
    Flag = "SelectedTheme",
    Value = WindUI:GetCurrentTheme() or "Dark",
    Values = themeList,
    Callback = function(option)
        pcall(function()
            WindUI:SetTheme(option)
        end)
    end
})

-- Config Manager Section
local ConfigManagerSection = ConfigTab:Section({
    Title = "Config Manager"
})

local selectedConfig = ""
local configNameInput = ""

local function getConfigList()
    local list = {}
    pcall(function()
        local configs = Window.ConfigManager:AllConfigs()
        if configs then
            for _, name in ipairs(configs) do
                table.insert(list, name)
            end
        end
    end)
    return list
end

local configDropdown = ConfigTab:Dropdown({
    Title = "Select Config",
    Desc = "Choose saved config",
    Multi = false,
    Value = "",
    Values = getConfigList(),
    Callback = function(option)
        selectedConfig = option
    end
})

ConfigTab:Input({
    Title = "Config Name",
    Desc = "New config name",
    PlaceholderText = "Enter config name...",
    Callback = function(text)
        configNameInput = text
    end
})

ConfigTab:Button({
    Title = "Save Config",
    Desc = "Save current settings to new config",
    Callback = function()
        if configNameInput == "" then
            WindUI:Notify({Title = "Config", Content = "Enter config name first!", Duration = 3})
            return
        end
        pcall(function()
            local cfg = Window.ConfigManager:CreateConfig(configNameInput)
            cfg:Save()
        end)
        WindUI:Notify({Title = "Config", Content = "Config '" .. configNameInput .. "' saved successfully!", Duration = 3})
        pcall(function() configDropdown:Refresh(getConfigList()) end)
    end
})

ConfigTab:Button({
    Title = "Load Config",
    Desc = "Load selected config",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "--" then
            WindUI:Notify({Title = "Config", Content = "Select config first!", Duration = 3})
            return
        end
        pcall(function()
            local cfg = Window.ConfigManager:CreateConfig(selectedConfig)
            cfg:Load()
        end)
        WindUI:Notify({Title = "Config", Content = "Config '" .. selectedConfig .. "' loaded successfully!", Duration = 3})
    end
})

ConfigTab:Button({
    Title = "Rewrite Config",
    Desc = "Overwrite selected config with current settings",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "--" then
            WindUI:Notify({Title = "Config", Content = "Select config first!", Duration = 3})
            return
        end
        pcall(function()
            local cfg = Window.ConfigManager:CreateConfig(selectedConfig)
            cfg:Save()
        end)
        WindUI:Notify({Title = "Config", Content = "Config '" .. selectedConfig .. "' overwritten successfully!", Duration = 3})
    end
})

ConfigTab:Button({
    Title = "Delete Config",
    Desc = "Delete selected config",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "--" then
            WindUI:Notify({Title = "Config", Content = "Select config first!", Duration = 3})
            return
        end
        pcall(function()
            local cfg = Window.ConfigManager:CreateConfig(selectedConfig)
            cfg:Delete()
        end)
        WindUI:Notify({Title = "Config", Content = "Config '" .. selectedConfig .. "' deleted successfully!", Duration = 3})
        selectedConfig = ""
        pcall(function() configDropdown:Refresh(getConfigList()) end)
    end
})

ConfigTab:Button({
    Title = "Set Auto Load",
    Desc = "Automatically load selected config on start",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "--" then
            WindUI:Notify({Title = "Config", Content = "Select config first!", Duration = 3})
            return
        end
        pcall(function()
            local cfg = Window.ConfigManager:CreateConfig(selectedConfig)
            cfg:SetAutoLoad(true)
            cfg:Save()
        end)
        WindUI:Notify({Title = "Config", Content = "Auto load set to '" .. selectedConfig .. "'!", Duration = 3})
    end
})

-- Manual bulletproof AutoLoad parsing
pcall(function()
    local HttpService = game:GetService("HttpService")
    local configs = Window.ConfigManager:AllConfigs()
    if configs and readfile and isfile then
        for _, name in pairs(configs) do
            local path = "WindUI/DX-SR/config/" .. name .. ".json"
            if isfile(path) then
                local success, data = pcall(function()
                    return HttpService:JSONDecode(readfile(path))
                end)
                if success and type(data) == "table" and data.__autoload then
                    local cfg = Window.ConfigManager:CreateConfig(name)
                    cfg:Load()
                end
            end
        end
    end
end)

Window:EditOpenButton({
    Title = "Open UI",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})