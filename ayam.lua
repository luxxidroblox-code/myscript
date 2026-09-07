-- [[ Protected by DX-SR | ID: 61c8bfcc-a51f-4b76-8ac5-471bb10b3d77 ]] --
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

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

local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer      = Players.LocalPlayer

local isEventRunning   = false
local targetEarningLimit = 0
local tweenSpeed       = 150
local tweenHeight      = 4
local tweenArriveDistance = 33
local minigameStart    = 2
local minigameEnd      = 8

local webhookUrl       = ""
local webhookEnabled   = false

local currentLiveCurText  = "0"
local currentMPerHourText = "0"
local currentTotalEarnedText = "0"
local currentTimeElapsedText = "0"

local globalTotalEarned  = 0
local lastObservedSalary = -1
local scriptStartTick    = tick()

-- ============================================================
-- UTILS
-- ============================================================
local function formatCurrency(amount)
    local formatted = tostring(math.floor(amount))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return "Rp. " .. formatted
end

local function parseCurrency(text)
    if not text then return 0 end
    return tonumber(string.gsub(text, "[^%d]", "")) or 0
end

local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- ============================================================
-- CORE FUNCTIONS (logic tidak diubah)
-- ============================================================
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

local function getActiveCar()
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles")
    if vehiclesFolder then
        local car = vehiclesFolder:FindFirstChild(LocalPlayer.Name .. "sCar")
        if car then
            local wheels = car:FindFirstChild("Wheels") or car:FindFirstChild("wheels")
            if wheels then
                wheels:Destroy()
                local body = car:FindFirstChild("Body")
                if body then
                    local mainPart = body:FindFirstChild("MainPart")
                    if mainPart and mainPart:IsA("BasePart") then
                        mainPart.CanCollide = false
                    end
                    local toDelete = {
                        "Body", "Lightbar", "Lights", "Plate", "Plate Text", "Prop",
                        "Hitbox", "FrontSensor", "BackSensor", "Cam",
                        "DownforceF", "DownforceR", "Drag", "#Weight", "Dashcam",
                        "RM", "LM"
                    }
                    for _, name in ipairs(toDelete) do
                        if name ~= "MainPart" and name ~= "BagasiPoint" and name ~= "WeldConstraint" then
                            local part = body:FindFirstChild(name)
                            if part then pcall(function() part:Destroy() end) end
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
                    local cur, max = string.match(txt, "(%d+)/(%d+)")
                    if cur and max then
                        return tonumber(cur) or 0, tonumber(max) or 4
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
                    local cur, max = string.match(txt, "(%d+)/(%d+)")
                    if cur and max then
                        return tonumber(cur) or 0, tonumber(max) or 4
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
    local flySpeed  = speed or 150
    local RunService = game:GetService("RunService")

    local noclipConn = RunService.Stepped:Connect(function()
        for _, v in ipairs(car:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
        local char = LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end)

    local BG = Instance.new("BodyGyro")
    BG.P = 9e4
    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.D = 50
    BG.Parent = root

    local BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BV.Velocity  = Vector3.zero
    BV.Parent    = root

    local arriveDistance = tweenArriveDistance or 40
    local timeout = os.clock()

    while isEventRunning do
        local currentPos = root.Position
        local direction  = targetPos - currentPos
        local distance   = direction.Magnitude

        if distance < arriveDistance then break end
        if os.clock() - timeout > 300 then break end

        BV.Velocity = direction.Unit * flySpeed
        BG.CFrame   = CFrame.lookAt(currentPos, targetPos)
        task.wait()
    end

    BV.Velocity = Vector3.zero
    task.wait(0.2)
    BG:Destroy()
    BV:Destroy()

    for _, v in ipairs(car:GetDescendants()) do
        if v:IsA("BasePart") then
            v.AssemblyLinearVelocity  = Vector3.zero
            v.AssemblyAngularVelocity = Vector3.zero
        end
    end

    noclipConn:Disconnect()
    for _, v in ipairs(car:GetDescendants()) do
        if v:IsA("BasePart") then v.CanCollide = true end
    end

    local char = LocalPlayer.Character
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end

local function handleMinigames()
    task.spawn(function()
        local VIM = game:GetService("VirtualInputManager")
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
                local slot  = timing:FindFirstChild("Trunk") and timing.Trunk:FindFirstChild("Slot")
                if koper and slot and koper.Visible and slot.Visible then
                    local kX = koper.Position.X.Scale
                    local sX = slot.Position.X.Scale
                    local sW = slot.Size.X.Scale
                    if kX >= (sX + 0.02) and kX <= (sX + sW - 0.02) then
                        VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        task.wait(0.05)
                        VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                        task.wait(0.5)
                    end
                end
            end

            local skill = bcGui:FindFirstChild("Skill")
            if skill and skill.Visible then
                local needleArm = skill:FindFirstChild("NeedleArm")
                local zoneArc   = skill:FindFirstChild("ZoneArc")
                local greatArc  = skill:FindFirstChild("GreatArc")

                if needleArm and needleArm.Visible then
                    local nRot = needleArm.Rotation % 360

                    if greatArc and greatArc.Visible then
                        local gRot  = greatArc.Rotation % 360
                        local gDiff = (nRot - gRot) % 360
                        if gDiff > minigameStart and gDiff < minigameEnd then
                            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                            task.wait(0.05)
                            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                            task.wait(0.5)
                        end
                    elseif zoneArc and zoneArc.Visible then
                        local zRot = zoneArc.Rotation % 360
                        local diff = (nRot - zRot) % 360
                        if diff > 8 and diff < 25 then
                            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                            task.wait(0.05)
                            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
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
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function teleportWithSlowmoDrop(targetCFrame, dropHeight, dropTime)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp        = char.HumanoidRootPart
        local startCFrame = targetCFrame * CFrame.new(0, dropHeight, 0)
        hrp.CFrame = startCFrame
        hrp.Anchored = true
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

        local startTime = os.clock()
        while (os.clock() - startTime) < dropTime and isEventRunning do
            local alpha = (os.clock() - startTime) / dropTime
            hrp.CFrame = startCFrame:Lerp(targetCFrame, alpha)
            task.wait()
        end

        if isEventRunning then hrp.CFrame = targetCFrame end
        hrp.Anchored = false
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function firePrompt(prompt)
    if not prompt then return end
    local oldLoS  = prompt.RequiresLineOfSight
    local oldDist = prompt.MaxActivationDistance
    prompt.RequiresLineOfSight    = false
    prompt.MaxActivationDistance  = 50
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + 0.1)
        prompt:InputHoldEnd()
    end
    task.delay(0.5, function()
        if prompt and prompt.Parent then
            prompt.RequiresLineOfSight   = oldLoS
            prompt.MaxActivationDistance = oldDist
        end
    end)
end

local function holdPromptKey(prompt, keyCode, customDuration)
    if not prompt then return end
    local oldLoS  = prompt.RequiresLineOfSight
    local oldDist = prompt.MaxActivationDistance
    prompt.RequiresLineOfSight   = false
    prompt.MaxActivationDistance = 50
    local VIM      = game:GetService("VirtualInputManager")
    local duration = customDuration or (prompt.HoldDuration > 0 and (prompt.HoldDuration + 0.2) or 2.2)
    VIM:SendKeyEvent(true, keyCode, false, game)
    task.wait(duration)
    VIM:SendKeyEvent(false, keyCode, false, game)
    task.delay(0.5, function()
        if prompt and prompt.Parent then
            prompt.RequiresLineOfSight   = oldLoS
            prompt.MaxActivationDistance = oldDist
        end
    end)
end

local function forceLookAt(targetPosition, lockDuration)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    cam.CameraType = Enum.CameraType.Scriptable
    local targetCFrame = CFrame.lookAt(cam.CFrame.Position, targetPosition)
    local TweenService = game:GetService("TweenService")
    local tween = TweenService:Create(cam, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
    task.spawn(function()
        task.wait(lockDuration or 0.8)
        cam.CameraType = Enum.CameraType.Custom
    end)
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
        teleportWithSlowmoDrop(andhiniCFrame, 60, 2.5)
        task.wait(0.5)

        local andhini = bcaFolder:FindFirstChild("NPC_START_JOB")
        if andhini and andhini:FindFirstChild("HumanoidRootPart") then
            local prompt = andhini.HumanoidRootPart:FindFirstChild("DialogPrompt")
            if prompt then
                if hasFinishedDelivery then
                    forceLookAt(andhini.HumanoidRootPart.Position)
                    firePrompt(prompt)
                    task.wait(1.5)
                    local VIM = game:GetService("VirtualInputManager")
                    for i = 1, 6 do
                        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.05)
                        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                        task.wait(0.2)
                    end
                    task.wait(0.5)
                end

                local dialogFinished = false
                local jobRemote = ReplicatedStorage:WaitForChild("NetworkContainer"):WaitForChild("RemoteEvents"):WaitForChild("Job")
                local msgRemote = ReplicatedStorage:WaitForChild("NetworkContainer"):WaitForChild("RemoteEvents"):WaitForChild("MessageNotification")

                local jobConn = jobRemote.OnClientEvent:Connect(function(action, jobName)
                    if action == "SetJob" and jobName == "BankCourier" then dialogFinished = true end
                end)
                local msgConn = msgRemote.OnClientEvent:Connect(function(title, desc)
                    if title == "KURIR BANK" then dialogFinished = true end
                end)

                forceLookAt(andhini.HumanoidRootPart.Position)
                firePrompt(prompt)
                task.wait(1.5)

                local VIM = game:GetService("VirtualInputManager")
                local dialogStart = os.clock()
                while not dialogFinished and isEventRunning do
                    if os.clock() - dialogStart > 10 then break end
                    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.wait(0.05)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    task.wait(0.2)
                end

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
                    forceLookAt(putra.HumanoidRootPart.Position)
                    firePrompt(prompt)
                    task.wait(1.5)

                    local VIM = game:GetService("VirtualInputManager")
                    local dialogStart = os.clock()
                    while not getActiveCar() and isEventRunning do
                        if os.clock() - dialogStart > 10 then break end
                        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.05)
                        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                        task.wait(0.2)
                    end
                end
            end
        end

        car = getActiveCar()
        if car then
            task.wait(1)
            for _, v in ipairs(car:GetDescendants()) do
                if v:IsA("BasePart") then v.Anchored = true end
            end
        end

        -- Tahap 3: Ambil Koper & Minigame
        local currentKoper, maxKoper = getKoperCount()
        local koperSpawn = bcaFolder:FindFirstChild("Job")
            and bcaFolder.Job:FindFirstChild("BankCourier")
            and bcaFolder.Job.BankCourier:FindFirstChild("KoperSpawn")

        while currentKoper < maxKoper and isEventRunning do
            car = getActiveCar()
            if not car then break end

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

            local bagasiPoint = car:FindFirstChild("BagasiPoint")
            if bagasiPoint then
                local muatPrompt = bagasiPoint:FindFirstChild("MuatPrompt")
                if muatPrompt then
                    local awayVector = (bagasiPoint.Position - car:GetPivot().Position).Unit
                    teleportPlayer(CFrame.new(bagasiPoint.Position + awayVector * 4 + Vector3.new(0, 4, 0)))
                    task.wait(0.5)
                    forceLookAt(bagasiPoint.Position)
                    firePrompt(muatPrompt)

                    local kC, mK = getKoperCount()
                    local waitStart = os.clock()
                    while kC == currentKoper and isEventRunning do
                        task.wait(0.5)
                        kC, mK = getKoperCount()
                        if os.clock() - waitStart > 10 then break end
                    end
                    currentKoper = kC
                    maxKoper     = mK
                end
            end
        end

        -- Tahap 4: Antar ke ATM
        local currentAtm, maxAtm = getAtmCount()
        while currentAtm < maxAtm and isEventRunning do
            car = getActiveCar()
            if not car then break end

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

            for _, v in ipairs(car:GetDescendants()) do
                if v:IsA("BasePart") then v.Anchored = false end
            end

            local routeFolder = Workspace:FindFirstChild("BankCourierRoute")
            local targetNode  = routeFolder and routeFolder:FindFirstChild("To")
            if targetNode then
                local targetCFrame = targetNode:IsA("CFrameValue") and targetNode.Value or targetNode.CFrame
                vehicleFlyTo(car, targetCFrame + Vector3.new(0, tweenHeight, 0), tweenSpeed)
                task.wait(1.5)
            else
                local target = Workspace:FindFirstChild("__BankCourierTarget")
                if target then
                    local carPos    = car:GetPivot().Position
                    local targetPos = target.Position
                    local dir       = (carPos - targetPos)
                    local flatDir   = Vector3.new(dir.X, 0, dir.Z)
                    if flatDir.Magnitude < 0.1 then flatDir = Vector3.new(1, 0, 0) end
                    local stopPos   = targetPos + flatDir.Unit * 20 + Vector3.new(0, tweenHeight, 0)
                    vehicleFlyTo(car, CFrame.lookAt(stopPos, targetPos), tweenSpeed)
                    task.wait(1.5)
                end
            end

            for _, v in ipairs(car:GetDescendants()) do
                if v:IsA("BasePart") then v.Anchored = true end
            end

            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Sit  = false
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
                        local charFolder = Workspace:FindFirstChild("Lives")
                        local myChar = charFolder and charFolder:FindFirstChild(LocalPlayer.Name) or LocalPlayer.Character
                        if myChar and myChar:FindFirstChild("KoperUang") then break end
                        if os.clock() - holdKoperStart > 15 then break end
                        local awayVector = (bagasiPoint.Position - car:GetPivot().Position).Unit
                        teleportPlayer(CFrame.new(bagasiPoint.Position + awayVector * 4 + Vector3.new(0, 4, 0)))
                        task.wait(0.2)
                        forceLookAt(bagasiPoint.Position)
                        holdPromptKey(ambilPrompt, Enum.KeyCode.F)
                        task.wait(0.5)
                    end
                end
            end

            local routeFolder = Workspace:FindFirstChild("BankCourierRoute")
            local targetNode  = routeFolder and routeFolder:FindFirstChild("To")
            if targetNode then
                local targetCFrame = targetNode:IsA("CFrameValue") and targetNode.Value or targetNode.CFrame
                local targetPos    = targetCFrame.Position

                teleportPlayer(targetCFrame + Vector3.new(0, 3, 0))
                task.wait(0.2)

                local char = LocalPlayer.Character
                if char then
                    for _, v in ipairs(char:GetDescendants()) do
                        if v:IsA("BasePart") then v.Anchored = true end
                    end
                end

                local cam = Workspace.CurrentCamera
                if cam then
                    cam.CameraType = Enum.CameraType.Scriptable
                    cam.CFrame     = CFrame.lookAt(cam.CFrame.Position, targetPos)
                    task.spawn(function()
                        task.wait(0.8)
                        cam.CameraType = Enum.CameraType.Custom
                    end)
                end

                local isiStart = os.clock()
                while isEventRunning do
                    local pGui   = LocalPlayer:FindFirstChild("PlayerGui")
                    local skillUi = pGui and pGui:FindFirstChild("Job")
                        and pGui.Job:FindFirstChild("BankCourier")
                        and pGui.Job.BankCourier:FindFirstChild("Skill")
                    if skillUi and skillUi.Visible then break end

                    local charFolder = Workspace:FindFirstChild("Lives")
                    local myChar = charFolder and charFolder:FindFirstChild(LocalPlayer.Name) or LocalPlayer.Character
                    if myChar and not myChar:FindFirstChild("KoperUang") then break end

                    local cAtm, mAtm = getAtmCount()
                    if cAtm > currentAtm then break end
                    if os.clock() - isiStart > 15 then break end

                    local isiPrompt = targetNode:FindFirstChild("IsiAtmPrompt", true)
                    if isiPrompt then
                        holdPromptKey(isiPrompt, Enum.KeyCode.F, 0.3)
                        if fireproximityprompt then
                            pcall(function() fireproximityprompt(isiPrompt) end)
                        end
                        pcall(function()
                            isiPrompt:InputHoldBegin()
                            task.wait(0.1)
                            isiPrompt:InputHoldEnd()
                        end)
                    else
                        local VIM = game:GetService("VirtualInputManager")
                        VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                        task.wait(0.05)
                        VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                    end
                    task.wait(0.5)
                end

                local cAtm, mAtm = getAtmCount()
                local waitStart  = os.clock()
                while cAtm == currentAtm and isEventRunning do
                    task.wait(0.5)
                    cAtm, mAtm = getAtmCount()
                    if os.clock() - waitStart > 15 then break end
                end

                if cAtm > currentAtm and cAtm < mAtm then
                    local moveWaitStart = os.clock()
                    local oldPos        = targetPos
                    while isEventRunning do
                        local newNode = routeFolder and routeFolder:FindFirstChild("To")
                        local newPos  = newNode and (newNode:IsA("CFrameValue") and newNode.Value.Position or newNode.Position)
                        if newPos and newPos ~= oldPos then break end
                        task.wait(0.1)
                        if os.clock() - moveWaitStart > 5 then break end
                    end
                end

                local char = LocalPlayer.Character
                if char then
                    for _, v in ipairs(char:GetDescendants()) do
                        if v:IsA("BasePart") then v.Anchored = false end
                    end
                end

                currentAtm = cAtm
                maxAtm     = mAtm
            end
        end

        hasFinishedDelivery = true
        task.wait(2)

        local currentEarned = _G.TotalEarned or 0
        local cycleEarned   = currentEarned - (_G.LastCycleEarned or 0)
        if cycleEarned > 0 then
            Rayfield:Notify({
                title   = "Job Completed",
                content = "Kamu mendapatkan " .. formatCurrency(cycleEarned) .. " dari shift ini!",
                duration = 5
            })
        end
        _G.LastCycleEarned = currentEarned
    end
end

-- ============================================================
-- RAYFIELD GEN2 UI SETUP (THEME COBALT)
-- ============================================================
local window = Rayfield:CreateWindow({
    name     = "CDID x BCA",
    subtitle = "DX-SR Hub v1.9B",
    theme    = "cobalt"
})

-- TAB 1: FARMING
local farmTab = window:CreateTab({ name = "Farming" })

farmTab:CreateSection({ name = "Auto BCA" })

farmTab:CreateSlider({
    name      = "Car Tween Height",
    range     = {0, 200},
    increment = 1,
    value     = 4,
    suffix    = " studs",
    callback  = function(value)
        tweenHeight = value
    end,
})

farmTab:CreateSlider({
    name      = "Arrive Distance",
    range     = {0, 100},
    increment = 1,
    value     = tweenArriveDistance,
    suffix    = " studs",
    callback  = function(value)
        tweenArriveDistance = value
    end,
})

farmTab:CreateInput({
    name        = "Target Earning",
    placeholder = "3500000000",
    callback    = function(text)
        local num = tonumber((string.gsub(text, "[^%d]", ""))) or 0
        targetEarningLimit = num
    end,
})

farmTab:CreateToggle({
    name     = "Auto Farm BCA",
    callback = function(state)
        isEventRunning = state
        if isEventRunning then
            task.spawn(startBCAEventLogic)
        end
    end,
})

farmTab:CreateSection({ name = "Settings" })

farmTab:CreateSlider({
    name      = "Minigame Start",
    range     = {0, 10},
    increment = 1,
    value     = minigameStart,
    callback  = function(value)
        minigameStart = value
    end,
})

farmTab:CreateSlider({
    name      = "Minigame End",
    range     = {5, 25},
    increment = 1,
    value     = minigameEnd,
    callback  = function(value)
        minigameEnd = value
    end,
})

farmTab:CreateSection({ name = "Information" })

local timeStat       = farmTab:CreateStat({ name = "Time Elapsed",  value = "00:00:00"  })
local liveCurStat    = farmTab:CreateStat({ name = "Live Currency", value = "Loading..." })
local mEarningStat   = farmTab:CreateStat({ name = "Money / Hour",  value = "Loading..." })
local totalEarnedStat = farmTab:CreateStat({ name = "Total Earned", value = "Rp. 0"     })

-- TAB 2: WEBHOOK
local webhookTab = window:CreateTab({ name = "Webhook" })

webhookTab:CreateInput({
    name        = "Webhook URL",
    placeholder = "https://discord.com/api/webhooks/...",
    callback    = function(text)
        webhookUrl = text
    end,
})

webhookTab:CreateToggle({
    name     = "Enable Webhook",
    callback = function(state)
        webhookEnabled = state
    end,
})

-- TAB 3: CONFIG
local configTab = window:CreateTab({ name = "Config" })

configTab:CreateSection({ name = "Theme" })

configTab:CreateDropdown({
    name            = "UI Theme",
    options         = {"cobalt", "aqua", "green", "red", "pink", "yellow", "purple", "white", "black"},
    currentOption   = {"cobalt"},
    multipleOptions = false,
    callback        = function(option)
        local theme = type(option) == "table" and option[1] or option
        Rayfield:Notify({
            title    = "Theme",
            content  = "Reload script to apply theme: " .. theme,
            duration = 4
        })
    end,
})

-- ============================================================
-- LIVE STATS UPDATE LOOP
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1)
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then continue end

        -- Time elapsed
        local totalElapsed = tick() - scriptStartTick
        if totalElapsed > 0 then
            currentTimeElapsedText = formatTime(totalElapsed)
            timeStat:Set(currentTimeElapsedText)
        end

        -- Live currency
        local liveCurText = "0"
        local mGui = pGui:FindFirstChild("Main")
        if mGui and mGui:FindFirstChild("Container") and mGui.Container:FindFirstChild("Hub") then
            local cashFrame = mGui.Container.Hub:FindFirstChild("CashFrame")
            if cashFrame and cashFrame:FindFirstChild("Frame") and cashFrame.Frame:FindFirstChild("TextLabel") then
                liveCurText = cashFrame.Frame.TextLabel.Text
            end
        end
        currentLiveCurText = liveCurText
        liveCurStat:Set(liveCurText)

        -- Total earned via salary delta
        local jobGui = pGui:FindFirstChild("Job")
        if jobGui and jobGui:FindFirstChild("BankCourier") then
            local salaryLabel = jobGui.BankCourier:FindFirstChild("Status")
                and jobGui.BankCourier.Status:FindFirstChild("Salary")
            if salaryLabel then
                local currentSalary = parseCurrency(salaryLabel.Text)
                if lastObservedSalary == -1 then
                    lastObservedSalary = currentSalary
                elseif currentSalary > lastObservedSalary then
                    globalTotalEarned  = globalTotalEarned + (currentSalary - lastObservedSalary)
                    lastObservedSalary = currentSalary

                    if targetEarningLimit > 0 and globalTotalEarned >= targetEarningLimit then
                        isEventRunning = false
                        Rayfield:Notify({
                            title    = "Target Reached!",
                            content  = "You have reached " .. formatCurrency(globalTotalEarned) .. ". Auto farm stopped.",
                            duration = 10
                        })
                    end

                    if _G.SendWebhook then _G.SendWebhook(false) end
                elseif currentSalary < lastObservedSalary then
                    lastObservedSalary = currentSalary
                end
            end
        end

        -- Update stat displays
        currentTotalEarnedText = formatCurrency(globalTotalEarned)
        totalEarnedStat:Set(currentTotalEarnedText)

        if totalElapsed > 0 then
            local mPerHour = (globalTotalEarned / totalElapsed) * 3600
            currentMPerHourText = formatCurrency(mPerHour)
            mEarningStat:Set(currentMPerHourText)
        end
    end
end)

-- ============================================================
-- WEBHOOK SYSTEM
-- ============================================================
_G.SendWebhook = function(isDisconnect, customMsg)
    if not webhookEnabled or webhookUrl == "" then return end
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or request
    if not httprequest then return end

    local payload = {
        content = isDisconnect and "@everyone " or "",
        embeds  = {{
            title       = isDisconnect and "🚨 DISCONNECTED" or "💰 DELIVERY SUCCESS",
            description = isDisconnect and ("Reason: " .. (customMsg or "Unknown")) or "Berhasil setor koper ke ATM!",
            color       = isDisconnect and 16711680 or 65280,
            fields      = {
                {name = "Live Currency",   value = currentLiveCurText,     inline = true},
                {name = "Money Per Hour",  value = currentMPerHourText,    inline = true},
                {name = "Total Earning",   value = currentTotalEarnedText, inline = true},
                {name = "Time Elapsed",    value = currentTimeElapsedText, inline = true}
            },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    task.spawn(function()
        pcall(function()
            httprequest({
                Url     = webhookUrl,
                Method  = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body    = game:GetService("HttpService"):JSONEncode(payload)
            })
        end)
    end)
end

game:GetService("GuiService").ErrorMessageChanged:Connect(function(errMsg)
    if errMsg and errMsg ~= "" then
        _G.SendWebhook(true, errMsg)
    end
end)