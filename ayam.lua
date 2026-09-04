-- [[ Protected by DX-SR | ID: d9b5e40f-637b-4beb-9531-63cb666e680e ]] --
-- Lua 5.1 / Luau · Roblox executor · Rayfield Gen2 stable

pcall(function()
    local player = game:GetService("Players").LocalPlayer
    local VU     = game:GetService("VirtualUser")

    if getconnections then
        for _, c in pairs(getconnections(player.Idled)) do
            pcall(function() c:Disable() end)
            pcall(function() c:Disconnect() end)
        end
    end

    local con = player.Idled:Connect(function()
        pcall(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.zero)
        end)
    end)

    getgenv().unantiidle = function()
        if con then con:Disconnect() con = nil end
    end
end)

task.spawn(function()
    local ok, AFKTeleportController = pcall(function()
        return require(game:GetService("ReplicatedStorage").Modules.Client.AFK.AFKTeleportController)
    end)
    if ok and type(AFKTeleportController) == "table" then
        AFKTeleportController.JoinAFKServer    = function() end
        AFKTeleportController.PromptJoinAFKServer = function() end
    end
end)

-- =================== LOAD GEN2 ===================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- =================== WINDOW ===================
local Window = Rayfield:CreateWindow({
    name     = "Driving Empire",
    subtitle = "DX-SR",
    icon     = "car",
    theme    = "cobalt",
    showName = "DX-SR",
    configuration = {
        autoSave   = true,
        autoLoad   = true,
        fileName   = "DXSR_DrivingEmpire",
        customFolder = "DX-SR",
    },
})

Window:CreateTag({ title = "v2.1",  color = Color3.fromHex("#30ff6a") })
Window:CreateTag({ title = "DX-SR", color = Color3.fromHex("#1E3A8A") })

-- =================== GLOBALS ===================
getgenv().AutoDelivery       = false
getgenv().AutoOutlaw         = false
getgenv().DeliveryMethod     = "Teleport"
getgenv().DeliveryTweenSpeed = 500
getgenv().DeliveryDelay      = 6
getgenv().BagLimit           = 15
getgenv().TotalEarning       = 0
getgenv().TotalDeliveries    = 0
getgenv().TotalDeliveryLevel = 0
getgenv().TotalOutlawEarning = 0
getgenv().TotalATMsRobbed    = 0
getgenv().DeliveryStartTime  = 0
getgenv().OutlawStartTime    = 0

-- =================== SHARED TELEPORT UTILS ===================
local function getHRP()
    local char = game.Players.LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function resetVelocity(hrp)
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local function safeTP(targetPos)
    local hrp = getHRP()
    if not hrp then return end
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 45, 0))
    resetVelocity(hrp)
    task.wait(getgenv().DeliveryDelay or 6)
    hrp = getHRP()
    if not hrp then return end
    hrp.CFrame = CFrame.new(targetPos)
    resetVelocity(hrp)
    task.wait(0.15)
end

local function safeTween(targetPos)
    local hrp = getHRP()
    if not hrp then return end
    local speed    = math.max(1, getgenv().DeliveryTweenSpeed or 500)
    local hoverPos = targetPos + Vector3.new(0, 45, 0)
    hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 45, 0))
    resetVelocity(hrp)
    task.wait(0.1)
    local dist  = (hrp.Position - hoverPos).Magnitude
    local tinfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    local tween = game:GetService("TweenService"):Create(hrp, tinfo, {CFrame = CFrame.new(hoverPos)})
    tween:Play()
    tween.Completed:Wait()
    resetVelocity(hrp)
    task.wait(getgenv().DeliveryDelay or 6)
    hrp = getHRP()
    if not hrp then return end
    hrp.CFrame = CFrame.new(targetPos)
    resetVelocity(hrp)
    task.wait(0.15)
end

-- =================== DELIVERY TAB ===================
local DeliveryTab = Window:CreateTab({ name = "Delivery", icon = "package" })

DeliveryTab:CreateSection({ name = "Delivery Job" })

-- Stat handles for live display (Stat replaces Paragraph in Gen2)
local StatEarning   = DeliveryTab:CreateStat({ name = "Total Earning",  prefix = "$", value = 0 })
local StatLevel     = DeliveryTab:CreateStat({ name = "Delivery Level", prefix = "Lv. ", value = 0 })
local StatDelivery  = DeliveryTab:CreateStat({ name = "Total Delivery", value = 0 })
-- Timestamp shown as a plain text Stat with suffix
local StatDelTime   = DeliveryTab:CreateStat({ name = "Timestamp", value = 0, suffix = "s", forgetState = true })

DeliveryTab:CreateSection({ name = "Settings" })

local TweenSpeedSlider  -- forward declare; locked until Tween selected
local DeliveryToggle

local DeliveryMethodDropdown = DeliveryTab:CreateDropdown({
    name     = "Delivery Method",
    options  = { "Teleport", "Tween" },
    value    = "Teleport",
    flag     = "DeliveryMethod",
    callback = function(val)
        getgenv().DeliveryMethod = val
        if TweenSpeedSlider then
            -- Gen2 has no :Lock() -- show/hide by rebuilding is not available;
            -- we gate the value in safeTween instead, slider stays visible.
        end
    end,
})

TweenSpeedSlider = DeliveryTab:CreateSlider({
    name        = "Tween Speed",
    description = "Speed for Tween method (studs/s)",
    range       = { 10, 1000 },
    increment   = 10,
    value       = 300,
    flag        = "TweenSpeed",
    callback    = function(val)
        getgenv().DeliveryTweenSpeed = val
    end,
})

local DeliveryDelaySlider = DeliveryTab:CreateSlider({
    name        = "Delivery Delay",
    description = "Hover timeout before teleporting down (seconds)",
    range       = { 1, 15 },
    increment   = 1,
    value       = 6,
    flag        = "DeliveryDelay",
    callback    = function(val)
        getgenv().DeliveryDelay = val
    end,
})

DeliveryToggle = DeliveryTab:CreateToggle({
    name        = "Auto Delivery",
    description = "Turn on/off Auto Delivery",
    value       = false,
    flag        = "AutoDelivery",
    forgetState = true,
    callback    = function(state)
        getgenv().AutoDelivery      = state
        getgenv().DeliveryStartTime = state and tick() or 0

        if state then
            game:GetService("ReplicatedStorage").Remotes.RequestStartJobSession:FireServer("Delivery", "jobPad")

            task.spawn(function()
                local DeliveryJobTask = require(
                    game:GetService("ReplicatedStorage").Modules.Client.Jobs.Tasks.DeliveryJobTask
                )
                local lastPickup, lastDropoff = nil, nil

                while getgenv().AutoDelivery do
                    task.wait(0.5)
                    local delState = DeliveryJobTask.GetCurrentDeliveryState()
                    if not delState or not getHRP() then continue end

                    local carried = delState.ItemsCarried or 0
                    local maxCap  = delState.MaxCapacity  or 1
                    local useTP   = getgenv().DeliveryMethod ~= "Tween"

                    if carried < maxCap and delState.PickupPosition then
                        if lastPickup ~= delState.PickupPosition then
                            lastPickup = delState.PickupPosition
                            if useTP then safeTP(delState.PickupPosition)
                            else          safeTween(delState.PickupPosition) end
                        end
                    elseif carried >= maxCap and delState.DestinationPosition then
                        if lastDropoff ~= delState.DestinationPosition then
                            lastDropoff = delState.DestinationPosition
                            if useTP then safeTP(delState.DestinationPosition)
                            else          safeTween(delState.DestinationPosition) end
                        end
                    end
                end
            end)
        else
            game:GetService("ReplicatedStorage").Remotes.RequestEndJobSession:FireServer("jobPad")
        end
    end,
})

-- =================== MONEY / DELIVERY TRACKING ===================
task.spawn(function()
    local player      = game.Players.LocalPlayer
    local leaderstats = player:WaitForChild("leaderstats", 5)
    if not leaderstats then return end

    local moneyObj = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
    if not moneyObj then return end

    local lastMoney = moneyObj.Value
    moneyObj.Changed:Connect(function(newVal)
        if getgenv().AutoDelivery and newVal > lastMoney then
            getgenv().TotalEarning = getgenv().TotalEarning + (newVal - lastMoney)
            StatEarning:Set(getgenv().TotalEarning)
        end
        if getgenv().AutoOutlaw and newVal > lastMoney then
            getgenv().TotalOutlawEarning = getgenv().TotalOutlawEarning + (newVal - lastMoney)
            if StatOutlawEarning then StatOutlawEarning:Set(getgenv().TotalOutlawEarning) end
        end
        lastMoney = newVal
    end)

    local DeliveryConstants = require(
        game:GetService("ReplicatedStorage").Modules.Shared.Jobs.Delivery.DeliveryConstants
    )
    local Remotes = require(game:GetService("ReplicatedStorage").Modules.Shared.Remotes)
    Remotes.connect(DeliveryConstants.RemoteEvents.DeliveryCompleted, function(data)
        if getgenv().AutoDelivery and data and not data.FailureReason then
            getgenv().TotalDeliveries = getgenv().TotalDeliveries + (data.ItemsDelivered or 1)
            StatDelivery:Set(getgenv().TotalDeliveries)
        end
    end)

    task.spawn(function()
        while task.wait(2) do
            local char   = player.Character
            local streak = char and char:GetAttribute("DeliveryStreak")
            if streak and type(streak) == "number" then
                getgenv().TotalDeliveryLevel = streak
            end
            StatLevel:Set(getgenv().TotalDeliveryLevel)
        end
    end)
end)

-- =================== OUTLAW TAB ===================
local OutlawTab = Window:CreateTab({ name = "Outlaw", icon = "skull" })

OutlawTab:CreateSection({ name = "Autofarm Outlaw" })

local BagLimitSlider = OutlawTab:CreateSlider({
    name        = "Bag Limit",
    description = "Stop and collect money after carrying X bags",
    range       = { 1, 50 },
    increment   = 1,
    value       = 15,
    flag        = "BagLimit",
    callback    = function(val)
        getgenv().BagLimit = val
    end,
})

OutlawTab:CreateSection({ name = "Information" })

local StatOutlawEarning = OutlawTab:CreateStat({ name = "Total Earning",    prefix = "$", value = 0 })
local StatOutlawATMs    = OutlawTab:CreateStat({ name = "Total ATMs Robbed", value = 0 })
local StatOutlawTime    = OutlawTab:CreateStat({ name = "Timestamp",         value = 0, suffix = "s", forgetState = true })

OutlawTab:CreateSection({ name = "Controls" })

local OutlawToggle
OutlawToggle = OutlawTab:CreateToggle({
    name        = "Autofarm Outlaw",
    description = "Turn on/off Autofarm Outlaw",
    value       = false,
    flag        = "AutoOutlaw",
    forgetState = true,
    callback    = function(state)
        getgenv().AutoOutlaw      = state
        getgenv().OutlawStartTime = state and tick() or 0

        local function doDropoff()
            local hrp_d   = getHRP()
            if not hrp_d then return end
            local dropoff = workspace.Game.Jobs:FindFirstChild("CriminalDropOffSpawners")
            if dropoff and dropoff:FindFirstChild("CriminalDropOffSpawnerPermanent") then
                local wall = dropoff.CriminalDropOffSpawnerPermanent:FindFirstChild("CriminalDropOffPoint")
                if wall and wall:FindFirstChild("Zone") and wall.Zone:FindFirstChild("Wall") then
                    hrp_d.CFrame = wall.Zone.Wall.CFrame * CFrame.new(0, 15, 0)
                    task.wait(0.6)
                    pcall(function()
                        game:GetService("ReplicatedStorage").Remotes.AttemptCriminalJobComplete:InvokeServer(wall)
                    end)
                    return
                end
            end
            hrp_d.CFrame = CFrame.new(-2529, 15, 4022)
        end

        if state then
            game:GetService("ReplicatedStorage").Remotes.RequestStartJobSession:FireServer("Criminal", "jobPad")

            task.spawn(function()
                local hrp = getHRP()
                if hrp then hrp.CFrame = CFrame.new(-2529, 15, 4022) end

                local cities = {
                    CFrame.new(96, 35, -164),
                    CFrame.new(-1247, 26, -1039),
                    CFrame.new(-335, 269, 1827),
                    CFrame.new(-925, 14, 3823),
                    CFrame.new(-2369, 14, 2731),
                }
                local currentCity     = 1
                local lastRobTime     = tick()
                local timeoutDuration = 5

                local function countMoneyBags()
                    local count = 0
                    pcall(function()
                        local LP      = game.Players.LocalPlayer
                        local backpack = LP:FindFirstChild("Backpack")
                        if backpack then
                            for _, item in ipairs(backpack:GetChildren()) do
                                if item.Name == "CriminalMoneyBag" then count += 1 end
                            end
                        end
                        local c = LP.Character
                        if c then
                            for _, item in ipairs(c:GetChildren()) do
                                if item.Name == "CriminalMoneyBag" then count += 1 end
                            end
                        end
                    end)
                    return count
                end

                local function findATM()
                    local atmFolder = workspace.Game.Jobs:FindFirstChild("CriminalATMSpawners")
                    if not atmFolder then return nil end
                    local hrp_inner = getHRP()
                    if not hrp_inner then return nil end
                    local nearest, nearestDist = nil, math.huge
                    for _, spawner in ipairs(atmFolder:GetChildren()) do
                        if spawner.Name == "CriminalATMSpawner" then
                            for _, atmModel in ipairs(spawner:GetChildren()) do
                                if atmModel.Name == "CriminalATM" and atmModel:IsA("Model") then
                                    if atmModel:GetAttribute("State") ~= "Busted" then
                                        local pivot = atmModel:GetPivot()
                                        if pivot then
                                            local dist = (hrp_inner.Position - pivot.Position).Magnitude
                                            if dist < nearestDist then
                                                nearestDist = dist
                                                nearest     = atmModel
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    return nearest
                end

                while getgenv().AutoOutlaw do
                    task.wait(0.5)
                    if not getHRP() then continue end

                    if countMoneyBags() >= (getgenv().BagLimit or 15) then
                        doDropoff()
                        local CriminalUtil = require(
                            game:GetService("ReplicatedStorage").Modules.Shared.Jobs.Criminal.CriminalUtil
                        )
                        while CriminalUtil.GetWantedTimeRemaining(game.Players.LocalPlayer) > 0 do
                            if not getgenv().AutoOutlaw then break end
                            task.wait(1)
                        end
                        lastRobTime   = tick()
                        timeoutDuration = 5
                    else
                        local atm = findATM()
                        if atm then
                            local hrp_a = getHRP()
                            if hrp_a then
                                hrp_a.CFrame = atm:GetPivot() + Vector3.new(0, 3, 0)
                                task.wait(0.3)
                                local Remotes           = require(game:GetService("ReplicatedStorage").Modules.Shared.Remotes)
                                local CriminalConstants = require(
                                    game:GetService("ReplicatedStorage").Modules.Shared.Jobs.Criminal.CriminalConstants
                                )
                                local ok = Remotes.invokeServer(CriminalConstants.RemoteFunctions.AttemptATMBustStart, atm)
                                if ok then
                                    local startT = os.clock()
                                    while getgenv().AutoOutlaw and os.clock() - startT < 2.9 do
                                        task.wait(0.1)
                                    end
                                    Remotes.invokeServer(CriminalConstants.RemoteFunctions.AttemptATMBustComplete, atm)
                                    getgenv().TotalATMsRobbed += 1
                                    StatOutlawATMs:Set(getgenv().TotalATMsRobbed)
                                end
                                lastRobTime     = tick()
                                timeoutDuration = 5
                            end
                        else
                            if tick() - lastRobTime > timeoutDuration then
                                local hrp_c = getHRP()
                                if hrp_c then
                                    hrp_c.CFrame = cities[currentCity] + Vector3.new(0, 30, 0)
                                    resetVelocity(hrp_c)
                                end
                                currentCity     = currentCity % #cities + 1
                                timeoutDuration = 5
                                lastRobTime     = tick()
                            end
                        end
                    end
                end
            end)
        else
            local hrp = getHRP()
            if hrp then
                doDropoff()
                local CriminalUtil = require(
                    game:GetService("ReplicatedStorage").Modules.Shared.Jobs.Criminal.CriminalUtil
                )
                while CriminalUtil.GetWantedTimeRemaining(game.Players.LocalPlayer) > 0 do
                    task.wait(1)
                end
            end
            game:GetService("ReplicatedStorage").Remotes.RequestEndJobSession:FireServer("jobPad")
        end
    end,
})

-- =================== CONFIGURATION TAB ===================
-- Gen2 built-in saving handles config file I/O automatically via the
-- configuration = { autoSave, autoLoad } block on the window.
-- window:ListConfigs(), window:Save(name), window:Load(name),
-- window:DeleteConfig(name) give full multi-config control.
-- The settings tab exposed by Gen2 also shows a Configurations panel for free.

local ConfigTab = Window:CreateTab({ name = "Configuration", icon = "settings" })

ConfigTab:CreateSection({ name = "Themes" })

ConfigTab:CreateDropdown({
    name     = "Select Theme",
    options  = { "default", "cobalt", "ember", "amethyst", "frost", "rose" },
    value    = "cobalt",
    flag     = "SelectedTheme",
    callback = function(theme)
        Window:ChangeTheme(theme)
    end,
})

ConfigTab:CreateSection({ name = "Named Configs" })

local configNameInput = ConfigTab:CreateInput({
    name        = "Config Name",
    placeholder = "my_config",
    forgetState = true,
    callback    = function(val)
        getgenv().ConfigInputName = val
    end,
})

ConfigTab:CreateButton({
    name        = "Save Config",
    description = "Save current settings under the typed name",
    callback    = function()
        local name = getgenv().ConfigInputName
        if name and name ~= "" then
            local ok = Window:Save(name)
            Window:Notify({
                title   = "Config System",
                content = ok and ("Saved: " .. name) or "Save failed.",
                duration = 3,
            })
        else
            Window:Notify({ title = "Config System", content = "Enter a name first.", duration = 3 })
        end
    end,
})

ConfigTab:CreateButton({
    name        = "Load Config",
    description = "Load the named config",
    callback    = function()
        local name = getgenv().ConfigInputName
        if name and name ~= "" then
            local ok = Window:Load(name)
            Window:Notify({
                title   = "Config System",
                content = ok and ("Loaded: " .. name) or "Config not found.",
                duration = 3,
            })
        else
            Window:Notify({ title = "Config System", content = "Enter a name first.", duration = 3 })
        end
    end,
})

ConfigTab:CreateButton({
    name        = "Delete Config",
    description = "Delete the named config",
    callback    = function()
        local name = getgenv().ConfigInputName
        if name and name ~= "" then
            local ok = Window:DeleteConfig(name)
            Window:Notify({
                title   = "Config System",
                content = ok and ("Deleted: " .. name) or "Config not found.",
                duration = 3,
            })
        else
            Window:Notify({ title = "Config System", content = "Enter a name first.", duration = 3 })
        end
    end,
})

-- =================== CLOCK LOOP ===================
-- Stat:Set() expects a number; we store raw elapsed seconds and suffix "s".
-- For HH:MM:SS display, use a Text element instead — but Stat with a rounded
-- integer keeps parity with the original timestamp paragraph.
task.spawn(function()
    while task.wait(0.25) do
        if getgenv().AutoDelivery and getgenv().DeliveryStartTime > 0 then
            StatDelTime:Set(math.floor(tick() - getgenv().DeliveryStartTime))
        else
            StatDelTime:Set(0)
        end
        if getgenv().AutoOutlaw and getgenv().OutlawStartTime > 0 then
            StatOutlawTime:Set(math.floor(tick() - getgenv().OutlawStartTime))
        else
            StatOutlawTime:Set(0)
        end
    end
end)