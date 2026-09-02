-- [[ Protected by DX-SR | ID: d9b5e40f-637b-4beb-9531-63cb666e680e ]] --
pcall(function()
    local player, VU = game:GetService("Players").LocalPlayer, game:GetService("VirtualUser")

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
        if con then
            con:Disconnect()
            con = nil
        end
    end
end)

task.spawn(function()
    local success, AFKTeleportController = pcall(function()
        return require(game:GetService("ReplicatedStorage").Modules.Client.AFK.AFKTeleportController)
    end)
    if success and type(AFKTeleportController) == "table" then
        AFKTeleportController.JoinAFKServer = function() end
        AFKTeleportController.PromptJoinAFKServer = function() end
    end
end)

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Driving Empire",
    Icon = "car",
    Author = "DX-SR",
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
    ScrollBarEnabled = false,
})

Window:Tag({
    Title = "v2.1",
    Icon = "github",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 13,
})

Window:Tag({
    Title = "DX-Sr",
    Icon = "terminal",
    Color = Color3.fromHex("#1E3A8A"),
    Radius = 13,
})

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

-- Hover dulu di +45Y, tunggu zona stream, lalu turun ke target
local function safeTP(targetPos)
    local hrp = getHRP()
    if not hrp then return end

    local hoverPos = targetPos + Vector3.new(0, 45, 0)
    hrp.CFrame = CFrame.new(hoverPos)
    resetVelocity(hrp)

    task.wait(getgenv().DeliveryDelay or 6)

    hrp = getHRP()
    if not hrp then return end
    hrp.CFrame = CFrame.new(targetPos)
    resetVelocity(hrp)
    task.wait(0.15)
end

-- Tween ke hover point, tunggu stream, lalu drop — tanpa Anchored
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

-- =================== TABS ===================
local MainTabSection = Window:Section({
    Title = "Main",
    Opened = true
})

local DeliveryTab = MainTabSection:Tab({
    Title = "Delivery",
    Icon = "package"
})

local DeliveryJobSection = DeliveryTab:Section({
    Title = "Delivery Job",
    Opened = true
})

local InfoSection = DeliveryTab:Section({
    Title = "Information",
    Opened = true
})

local EarningPara = InfoSection:Paragraph({
    Title = "Total Earning",
    Desc = "$0",
})

local LevelPara = InfoSection:Paragraph({
    Title = "Total Level",
    Desc = "Lv. 0",
})

local DeliveriesPara = InfoSection:Paragraph({
    Title = "Total Delivery",
    Desc = "-",
})

local DeliveryTimePara = InfoSection:Paragraph({
    Title = "Timestamp",
    Desc = "00:00:00:000",
})

local OutlawEarningPara
local OutlawATMsPara
local OutlawTimePara

DeliveryTab:Space()

-- =================== MONEY TRACKING ===================
task.spawn(function()
    local player    = game.Players.LocalPlayer
    local leaderstats = player:WaitForChild("leaderstats", 5)
    if not leaderstats then return end

    local moneyObj = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
    if not moneyObj then return end

    local lastMoney = moneyObj.Value
    moneyObj.Changed:Connect(function(newVal)
        if getgenv().AutoDelivery and newVal > lastMoney then
            getgenv().TotalEarning = getgenv().TotalEarning + (newVal - lastMoney)
            EarningPara:SetDesc("$" .. tostring(getgenv().TotalEarning))
        end
        if getgenv().AutoOutlaw and newVal > lastMoney then
            getgenv().TotalOutlawEarning = getgenv().TotalOutlawEarning + (newVal - lastMoney)
            if OutlawEarningPara then
                OutlawEarningPara:SetDesc("$" .. tostring(getgenv().TotalOutlawEarning))
            end
        end
        lastMoney = newVal
    end)

    local DeliveryConstants = require(game:GetService("ReplicatedStorage").Modules.Shared.Jobs.Delivery.DeliveryConstants)
    local Remotes           = require(game:GetService("ReplicatedStorage").Modules.Shared.Remotes)
    Remotes.connect(DeliveryConstants.RemoteEvents.DeliveryCompleted, function(data)
        if getgenv().AutoDelivery and data and not data.FailureReason then
            getgenv().TotalDeliveries = getgenv().TotalDeliveries + (data.ItemsDelivered or 1)
            DeliveriesPara:SetDesc(tostring(getgenv().TotalDeliveries))
        end
    end)

    task.spawn(function()
        while task.wait(2) do
            local char   = player.Character
            local streak = char and char:GetAttribute("DeliveryStreak")
            if streak and type(streak) == "number" then
                getgenv().TotalDeliveryLevel = streak
            end
            LevelPara:SetDesc("Lv. " .. tostring(getgenv().TotalDeliveryLevel))
        end
    end)
end)

-- =================== DELIVERY TOGGLE ===================
local TweenSpeedSlider
local DeliveryJobToggle

DeliveryJobToggle = DeliveryJobSection:Toggle({
    Title = "Auto Delivery",
    Desc = "Turn on/off Auto Delivery",
    Value = false,
    Flag = "DeliveryJobToggle",
    Callback = function(state)
        getgenv().AutoDelivery = state
        getgenv().DeliveryStartTime = state and tick() or 0

        if state then
            game:GetService("ReplicatedStorage").Remotes.RequestStartJobSession:FireServer("Delivery", "jobPad")

            task.spawn(function()
                local DeliveryJobTask = require(game:GetService("ReplicatedStorage").Modules.Client.Jobs.Tasks.DeliveryJobTask)
                local lastPickup  = nil
                local lastDropoff = nil

                while getgenv().AutoDelivery do
                    task.wait(0.5)

                    local delState = DeliveryJobTask.GetCurrentDeliveryState()
                    if not delState then continue end

                    if not getHRP() then continue end

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
    end
})

-- =================== DELIVERY SETTINGS ===================
local DeliveryMethodDropdown = DeliveryJobSection:Dropdown({
    Title = "Delivery Method",
    Desc = "Choose how to travel",
    Value = "Teleport",
    Values = {"Teleport", "Tween"},
    Flag = "DeliveryMethodDropdown",
    Callback = function(val)
        getgenv().DeliveryMethod = val
        if TweenSpeedSlider then
            if val == "Tween" then
                TweenSpeedSlider:Unlock()
            else
                TweenSpeedSlider:Lock("Avaible for tween")
            end
        end
    end
})

TweenSpeedSlider = DeliveryJobSection:Slider({
    Title = "Tween Speed",
    Desc = "Speed for Tween method",
    Step = 10,
    Value = { Min = 0, Max = 500, Default = 300 },
    Flag = "TweenSpeedSlider",
    Callback = function(val)
        getgenv().DeliveryTweenSpeed = val
    end
})
TweenSpeedSlider:Lock("Avaible for tween")

local DeliveryDelaySlider = DeliveryJobSection:Slider({
    Title = "Delivery Delay",
    Desc = "Hover timeout before teleporting down (seconds)",
    Step = 1,
    Value = { Min = 1, Max = 15, Default = 6 },
    Flag = "DeliveryDelaySlider",
    Callback = function(val)
        getgenv().DeliveryDelay = val
    end
})

-- =================== OUTLAW TAB ===================
local OutlawTab = MainTabSection:Tab({
    Title = "Outlaw",
    Icon = "skull"
})

local OutlawJobSection = OutlawTab:Section({
    Title = "Autofarm Outlaw",
    Opened = true
})

local BagLimitSlider = OutlawJobSection:Slider({
    Title = "Bag Limit",
    Desc = "Stop and collect money after carrying X bags",
    Step = 1,
    Value = { Min = 1, Max = 50, Default = 15 },
    Flag = "BagLimitSlider",
    Callback = function(val)
        getgenv().BagLimit = val
    end
})

local OutlawJobToggle

OutlawJobToggle = OutlawJobSection:Toggle({
    Title = "Autofarm Outlaw",
    Desc = "Turn on/off Autofarm Outlaw",
    Value = false,
    Flag = "OutlawJobToggle",
    Callback = function(state)
        getgenv().AutoOutlaw = state
        getgenv().OutlawStartTime = state and tick() or 0

        if state then
            game:GetService("ReplicatedStorage").Remotes.RequestStartJobSession:FireServer("Criminal", "jobPad")

            task.spawn(function()
                local hrp = getHRP()
                if hrp then
                    hrp.CFrame = CFrame.new(-2529, 15, 4022)
                end

                local cities = {
                    CFrame.new(96, 35, -164),
                    CFrame.new(-1247, 26, -1039),
                    CFrame.new(-335, 269, 1827),
                    CFrame.new(-925, 14, 3823),
                    CFrame.new(-2369, 14, 2731),
                }
                local currentCity    = 1
                local lastRobTime    = tick()
                local timeoutDuration = 5

                local function countMoneyBags()
                    local count = 0
                    pcall(function()
                        local LP      = game.Players.LocalPlayer
                        local backpack = LP:FindFirstChild("Backpack")
                        if backpack then
                            for _, item in ipairs(backpack:GetChildren()) do
                                if item.Name == "CriminalMoneyBag" then count = count + 1 end
                            end
                        end
                        local c = LP.Character
                        if c then
                            for _, item in ipairs(c:GetChildren()) do
                                if item.Name == "CriminalMoneyBag" then count = count + 1 end
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

                while getgenv().AutoOutlaw do
                    task.wait(0.5)

                    if not getHRP() then continue end

                    if countMoneyBags() >= (getgenv().BagLimit or 15) then
                        doDropoff()
                        local CriminalUtil = require(game:GetService("ReplicatedStorage").Modules.Shared.Jobs.Criminal.CriminalUtil)
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

                                local Remotes          = require(game:GetService("ReplicatedStorage").Modules.Shared.Remotes)
                                local CriminalConstants = require(game:GetService("ReplicatedStorage").Modules.Shared.Jobs.Criminal.CriminalConstants)

                                local ok = Remotes.invokeServer(CriminalConstants.RemoteFunctions.AttemptATMBustStart, atm)
                                if ok then
                                    local startT = os.clock()
                                    while getgenv().AutoOutlaw and os.clock() - startT < 2.9 do
                                        task.wait(0.1)
                                    end
                                    Remotes.invokeServer(CriminalConstants.RemoteFunctions.AttemptATMBustComplete, atm)
                                    getgenv().TotalATMsRobbed = getgenv().TotalATMsRobbed + 1
                                    if OutlawATMsPara then
                                        OutlawATMsPara:SetDesc(tostring(getgenv().TotalATMsRobbed))
                                    end
                                end
                                lastRobTime   = tick()
                                timeoutDuration = 5
                            end
                        else
                            if tick() - lastRobTime > timeoutDuration then
                                local hrp_c = getHRP()
                                if hrp_c then
                                    hrp_c.CFrame = cities[currentCity] + Vector3.new(0, 30, 0)
                                    resetVelocity(hrp_c)
                                end
                                currentCity = currentCity % #cities + 1
                                timeoutDuration = 5
                                lastRobTime = tick()
                            end
                        end
                    end
                end
            end)
        else
            -- Dropoff sisa bag sebelum stop
            local hrp = getHRP()
            if hrp then
                local dropoff = workspace.Game.Jobs:FindFirstChild("CriminalDropOffSpawners")
                if dropoff and dropoff:FindFirstChild("CriminalDropOffSpawnerPermanent") then
                    local wall = dropoff.CriminalDropOffSpawnerPermanent:FindFirstChild("CriminalDropOffPoint")
                    if wall and wall:FindFirstChild("Zone") and wall.Zone:FindFirstChild("Wall") then
                        hrp.CFrame = wall.Zone.Wall.CFrame * CFrame.new(0, 15, 0)
                        task.wait(0.6)
                        pcall(function()
                            game:GetService("ReplicatedStorage").Remotes.AttemptCriminalJobComplete:InvokeServer(wall)
                        end)
                    else
                        hrp.CFrame = CFrame.new(-2529, 15, 4022)
                    end
                else
                    hrp.CFrame = CFrame.new(-2529, 15, 4022)
                end
                local CriminalUtil = require(game:GetService("ReplicatedStorage").Modules.Shared.Jobs.Criminal.CriminalUtil)
                while CriminalUtil.GetWantedTimeRemaining(game.Players.LocalPlayer) > 0 do
                    task.wait(1)
                end
            end
            game:GetService("ReplicatedStorage").Remotes.RequestEndJobSession:FireServer("jobPad")
        end
    end
})

local OutlawInfoSection = OutlawTab:Section({
    Title = "Information",
    Opened = true
})

OutlawEarningPara = OutlawInfoSection:Paragraph({
    Title = "Total Earning",
    Desc = "$0",
})

OutlawATMsPara = OutlawInfoSection:Paragraph({
    Title = "Total ATMs Robbed",
    Desc = "0",
})

OutlawTimePara = OutlawInfoSection:Paragraph({
    Title = "Timestamp",
    Desc = "00:00:00:000",
})

OutlawTab:Space()

-- =================== CONFIGURATION TAB ===================
local ConfigTab = Window:Tab({
    Title = "Configuration",
    Icon = "settings"
})

local ThemesSection = ConfigTab:Section({
    Title = "Themes",
    Opened = true
})

local ThemesList = {}
for themeName, _ in pairs(WindUI:GetThemes()) do
    table.insert(ThemesList, themeName)
end
table.sort(ThemesList)

local ThemeDropdown = ThemesSection:Dropdown({
    Title = "Select Theme",
    Desc = "Change the UI Theme",
    Value = "Dark",
    Values = ThemesList,
    Flag = "ThemeDropdown",
    Callback = function(theme)
        getgenv().SelectedTheme = theme
        WindUI:SetTheme(theme)
    end
})

local ConfigSection = ConfigTab:Section({
    Title = "Config",
    Opened = true
})

local HttpService   = game:GetService("HttpService")
local ConfigFolder  = "DXSR_Configs"
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

local function GetConfigs()
    local list = {}
    if listfiles then
        local ok, files = pcall(function() return listfiles(ConfigFolder) end)
        if ok and files then
            for _, file in pairs(files) do
                local name = file:match("([^/\\]+)%.json$")
                if name then table.insert(list, name) end
            end
        end
    end
    return list
end

local ConfigDropdown
ConfigDropdown = ConfigSection:Dropdown({
    Title = "Select Config",
    Desc = "Choose a configuration to load",
    Value = "",
    Values = GetConfigs(),
    Callback = function(val)
        getgenv().SelectedConfig = val
    end
})

local ConfigInput = ConfigSection:Input({
    Title = "Config Name",
    Desc = "Name for new config",
    Value = "",
    Type = "Input",
    Placeholder = "my_config",
    Callback = function(val)
        getgenv().ConfigInputName = val
    end
})

local function currentConfigData()
    return {
        AutoDelivery   = getgenv().AutoDelivery   or false,
        DeliveryMethod = getgenv().DeliveryMethod  or "Teleport",
        TweenSpeed     = getgenv().DeliveryTweenSpeed or 500,
        DeliveryDelay  = getgenv().DeliveryDelay   or 6,
        AutoOutlaw     = getgenv().AutoOutlaw      or false,
        BagLimit       = getgenv().BagLimit        or 15,
        SelectedTheme  = getgenv().SelectedTheme   or "Dark",
    }
end

ConfigSection:Button({
    Title = "Save Config",
    Desc = "Save current settings to new config",
    Callback = function()
        local name = getgenv().ConfigInputName
        if name and name ~= "" then
            writefile(ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(currentConfigData()))
            if ConfigDropdown then ConfigDropdown:Refresh(GetConfigs()) end
            WindUI:Notify({ Title = "Config System", Content = "Saved: " .. name, Duration = 3 })
        else
            WindUI:Notify({ Title = "Config System", Content = "Enter a name in Config Name first!", Duration = 3 })
        end
    end
})

ConfigSection:Button({
    Title = "Rewrite Config",
    Desc = "Overwrite selected config",
    Callback = function()
        local name = getgenv().SelectedConfig
        if name and name ~= "" then
            writefile(ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(currentConfigData()))
            WindUI:Notify({ Title = "Config System", Content = "Rewrote: " .. name, Duration = 3 })
        else
            WindUI:Notify({ Title = "Config System", Content = "Select a config first!", Duration = 3 })
        end
    end
})

ConfigSection:Button({
    Title = "Delete Config",
    Desc = "Delete selected config",
    Callback = function()
        local name = getgenv().SelectedConfig
        if name and name ~= "" then
            local path = ConfigFolder .. "/" .. name .. ".json"
            if isfile(path) then
                delfile(path)
                if ConfigDropdown then ConfigDropdown:Refresh(GetConfigs()) end
                WindUI:Notify({ Title = "Config System", Content = "Deleted: " .. name, Duration = 3 })
            end
        else
            WindUI:Notify({ Title = "Config System", Content = "Select a config first!", Duration = 3 })
        end
    end
})

local function LoadConfigInternal(name)
    local path = ConfigFolder .. "/" .. name .. ".json"
    if not isfile(path) then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok or not data then return end
    task.spawn(function()
        if DeliveryJobToggle     and data.AutoDelivery   ~= nil    then DeliveryJobToggle:Set(data.AutoDelivery)           end
        if OutlawJobToggle       and data.AutoOutlaw     ~= nil    then OutlawJobToggle:Set(data.AutoOutlaw)               end
        if DeliveryMethodDropdown and data.DeliveryMethod           then DeliveryMethodDropdown:Select(data.DeliveryMethod) end
        if TweenSpeedSlider      and data.TweenSpeed               then TweenSpeedSlider:Set(data.TweenSpeed)              end
        if DeliveryDelaySlider   and data.DeliveryDelay            then DeliveryDelaySlider:Set(data.DeliveryDelay)        end
        if BagLimitSlider        and data.BagLimit                 then BagLimitSlider:Set(data.BagLimit)                  end
        if ThemeDropdown         and data.SelectedTheme            then ThemeDropdown:Select(data.SelectedTheme)           end
        WindUI:Notify({ Title = "Config System", Content = "Loaded: " .. name, Duration = 3 })
    end)
end

ConfigSection:Button({
    Title = "Load Config",
    Desc = "Load selected config",
    Callback = function()
        local name = getgenv().SelectedConfig
        if name and name ~= "" then
            LoadConfigInternal(name)
        else
            WindUI:Notify({ Title = "Config System", Content = "Select a config first!", Duration = 3 })
        end
    end
})

ConfigSection:Button({
    Title = "Set as Autoload",
    Desc = "Set selected config to load on startup",
    Callback = function()
        local name = getgenv().SelectedConfig
        if name and name ~= "" then
            writefile(ConfigFolder .. "/autoload.txt", name)
            WindUI:Notify({ Title = "Config System", Content = "Autoload set to: " .. name, Duration = 3 })
        else
            WindUI:Notify({ Title = "Config System", Content = "Select a config first!", Duration = 3 })
        end
    end
})

-- Autoload on startup
if isfile and isfile(ConfigFolder .. "/autoload.txt") then
    local name = readfile(ConfigFolder .. "/autoload.txt")
    if name and name ~= "" then
        task.spawn(function()
            task.wait(1.5)
            LoadConfigInternal(name)
        end)
    end
end

-- =================== CLOCK LOOP ===================
task.spawn(function()
    while task.wait(0.01) do
        local function fmtTime(elapsed)
            local ms = math.floor((elapsed % 1) * 1000)
            local s  = math.floor(elapsed)   % 60
            local m  = math.floor(elapsed / 60)  % 60
            local h  = math.floor(elapsed / 3600)
            return string.format("%02d:%02d:%02d:%03d", h, m, s, ms)
        end

        if getgenv().AutoDelivery and getgenv().DeliveryStartTime > 0 then
            DeliveryTimePara:SetDesc(fmtTime(tick() - getgenv().DeliveryStartTime))
        else
            DeliveryTimePara:SetDesc("00:00:00:000")
        end

        if getgenv().AutoOutlaw and getgenv().OutlawStartTime > 0 then
            if OutlawTimePara then OutlawTimePara:SetDesc(fmtTime(tick() - getgenv().OutlawStartTime)) end
        else
            if OutlawTimePara then OutlawTimePara:SetDesc("00:00:00:000") end
        end
    end
end)