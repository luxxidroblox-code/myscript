-- ============================================
-- Office Farm Stealth UI
-- Creator: _nznt
-- Features: Office Worker farm, stats UI, configurable answer delays
-- ============================================

local d = false
local h = {}
local x, y
setthreadidentity(2)
for i, v in getgc(true) do
    if typeof(v) == "table" then
        local a = rawget(v, "Detected")
        local b = rawget(v, "Kill")
        if typeof(a) == "function" and not x then
            x = a
            local o; o = hookfunction(x, function(c, f, n)
                if c ~= "_" then
                    if d then warn(`Adonis flagged\nMethod: {c}\nInfo: {f}`) end
                end
                return true
            end)
            table.insert(h, x)
        end
        if rawget(v, "Variables") and rawget(v, "Process") and typeof(b) == "function" and not y then
            y = b
            local o; o = hookfunction(y, function(f)
                if d then warn(`Adonis tried to kill: {f}`) end
            end)
            table.insert(h, y)
        end
    end
end
local o; o = hookfunction(getrenv().debug.info, newcclosure(function(...)
    local a, f = ...
    if x and a == x then return coroutine.yield(coroutine.running()) end
    return o(...)
end))
setthreadidentity(7)

pcall(function()
    if getgenv and getgenv().NZNT_OFFICE_STOP then
        getgenv().NZNT_OFFICE_STOP()
    end
end)

local function nzntStartupRoots()
    local roots = {}
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player and player:FindFirstChild("PlayerGui")
    if playerGui then
        table.insert(roots, playerGui)
    end

    local ok, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and coreGui then
        table.insert(roots, coreGui)
    end

    return roots
end

local function nzntVisibleGuiObject(obj)
    if not obj:IsA("GuiObject") or obj.AbsoluteSize.X <= 0 or obj.AbsoluteSize.Y <= 0 then
        return false
    end

    local current = obj
    while current do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end
        if current:IsA("ScreenGui") and not current.Enabled then
            return false
        end
        current = current.Parent
    end

    return true
end

local function nzntGuiText(obj)
    if obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
        return tostring(obj.Text or "")
    end
    return ""
end

local function nzntNamePath(obj)
    local names = {}
    local current = obj
    local depth = 0
    while current and depth < 8 do
        table.insert(names, tostring(current.Name or ""))
        current = current.Parent
        depth = depth + 1
    end
    return table.concat(names, " "):lower()
end

local function nzntClickableStartupTarget(obj)
    local current = obj
    while current do
        if current:IsA("GuiButton") then
            return current
        end
        current = current.Parent
    end

    current = obj
    while current do
        local name = tostring(current.Name or ""):lower()
        if current:IsA("GuiObject")
            and (name:find("deployselect", 1, true)
                or name:find("applyselect", 1, true)
                or name:find("playframe", 1, true))
        then
            return current
        end
        current = current.Parent
    end

    return obj:IsA("GuiObject") and obj or nil
end

local function nzntFindNamedPlayTarget()
    for _, root in ipairs(nzntStartupRoots()) do
        local mainMenu = root:FindFirstChild("mainMenuSystem")
        local baseFrame = mainMenu and mainMenu:FindFirstChild("baseFrame")
        local homeFrame = baseFrame and baseFrame:FindFirstChild("homeFrame")
        local playFrame = homeFrame and homeFrame:FindFirstChild("playFrame")
        local applySelect = playFrame and playFrame:FindFirstChild("applySelect")
        if applySelect and applySelect:IsA("GuiObject") and nzntVisibleGuiObject(applySelect) then
            return applySelect
        end

        local directPlayFrame = baseFrame and baseFrame:FindFirstChild("playFrame")
        local deploySelect = directPlayFrame and directPlayFrame:FindFirstChild("deploySelect")
        if deploySelect and deploySelect:IsA("GuiObject") and nzntVisibleGuiObject(deploySelect) then
            return deploySelect
        end

        local ok, descendants = pcall(function()
            return root:GetDescendants()
        end)
        if ok then
            for _, obj in ipairs(descendants) do
                if obj:IsA("GuiObject") and nzntVisibleGuiObject(obj) then
                    local name = tostring(obj.Name or ""):lower()
                    if name == "applyselect" or name == "deployselect" then
                        local path = nzntNamePath(obj)
                        if path:find("mainmenusystem", 1, true) and path:find("playframe", 1, true) then
                            return obj
                        end
                    end
                end
            end
        end
    end
end

local function nzntFindDeploySelectTarget()
    for _, root in ipairs(nzntStartupRoots()) do
        local mainMenu = root:FindFirstChild("mainMenuSystem")
        local baseFrame = mainMenu and mainMenu:FindFirstChild("baseFrame")
        local playFrame = baseFrame and baseFrame:FindFirstChild("playFrame")
        local deploySelect = playFrame and playFrame:FindFirstChild("deploySelect")
        if deploySelect and deploySelect:IsA("GuiObject") and nzntVisibleGuiObject(deploySelect) then
            return deploySelect
        end

        local ok, descendants = pcall(function()
            return root:GetDescendants()
        end)
        if ok then
            for _, obj in ipairs(descendants) do
                if obj:IsA("GuiObject") and nzntVisibleGuiObject(obj) then
                    local name = tostring(obj.Name or ""):lower()
                    if name == "deployselect" then
                        local path = nzntNamePath(obj)
                        if path:find("mainmenusystem", 1, true) and path:find("playframe", 1, true) then
                            return obj
                        end
                    end
                end
            end
        end
    end
end

local function nzntFindPlayButton()
    local namedTarget = nzntFindNamedPlayTarget()
    if namedTarget then
        return namedTarget
    end

    local bestButton, bestScore = nil, -math.huge
    for _, root in ipairs(nzntStartupRoots()) do
        local ok, descendants = pcall(function()
            return root:GetDescendants()
        end)
        if ok then
            for _, obj in ipairs(descendants) do
                if (obj:IsA("TextButton") or obj:IsA("ImageButton") or obj:IsA("TextLabel")) and nzntVisibleGuiObject(obj) then
                    local text = nzntGuiText(obj):upper():gsub("%s+", "")
                    local path = nzntNamePath(obj)
                    local color = obj.BackgroundColor3
                    local isGreen = obj.BackgroundTransparency < 0.8
                        and color.G > 0.45
                        and color.G > color.R * 1.25
                        and color.G > color.B * 1.25
                    local score = 0

                    if text == "PLAY" then
                        score = score + 100
                    elseif text:find("PLAY", 1, true) then
                        score = score + 55
                    end
                    if path:find("play", 1, true) then
                        score = score + 25
                    end
                    if path:find("deployselect", 1, true) or path:find("applyselect", 1, true) then
                        score = score + 45
                    end
                    if path:find("mainmenusystem", 1, true) then
                        score = score + 15
                    end
                    if isGreen then
                        score = score + 25
                    end

                    if score >= 60 and score > bestScore then
                        local target = nzntClickableStartupTarget(obj)
                        if target and nzntVisibleGuiObject(target) then
                            bestButton = target
                            bestScore = score
                        end
                    end
                end
            end
        end
    end
    return bestButton
end

local function nzntStartupScreenPresent()
    for _, root in ipairs(nzntStartupRoots()) do
        local ok, descendants = pcall(function()
            return root:GetDescendants()
        end)
        if ok then
            for _, obj in ipairs(descendants) do
                if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) and nzntVisibleGuiObject(obj) then
                    local text = nzntGuiText(obj):upper()
                    if text:find("LOADING GAME", 1, true) or text:find("TIP:", 1, true) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function nzntStartupExecutorIsDelta()
    local ok, name = pcall(function()
        if identifyexecutor then
            return identifyexecutor()
        end
        if getexecutorname then
            return getexecutorname()
        end
        return ""
    end)

    return ok and tostring(name or ""):lower():find("delta", 1, true) ~= nil
end

local function nzntClickButton(button)
    if not button or not button.Parent then
        return false
    end

    local clicked = false
    local isDelta = nzntStartupExecutorIsDelta()
    local function mark(ok)
        clicked = ok or clicked
    end

    if button:IsA("GuiButton") then
        mark(pcall(function()
            button:Activate()
        end))

        local signals = {
            button.MouseButton1Click,
            button.Activated
        }

        for _, signal in ipairs(signals) do
            if firesignal then
                mark(pcall(function()
                    firesignal(signal)
                end))
            end

            if not isDelta and getconnections then
                local ok, signalConnections = pcall(function()
                    return getconnections(signal)
                end)

                if ok and type(signalConnections) == "table" then
                    for _, connection in ipairs(signalConnections) do
                        local didCall = false
                        local okConnection = pcall(function()
                            if connection.Fire then
                                didCall = true
                                connection:Fire()
                            elseif connection.Function then
                                didCall = true
                                connection.Function()
                            end
                        end)
                        clicked = (okConnection and didCall) or clicked
                    end
                end
            end
        end

        if isDelta and nzntVisibleGuiObject(button) then
            mark(pcall(function()
                local guiService = game:GetService("GuiService")
                local vim = game:GetService("VirtualInputManager")
                button.Selectable = true
                guiService.SelectedObject = button

                vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait(0.04)
                vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                vim:SendKeyEvent(true, Enum.KeyCode.KeypadEnter, false, game)
                task.wait(0.04)
                vim:SendKeyEvent(false, Enum.KeyCode.KeypadEnter, false, game)

                if guiService.SelectedObject == button then
                    guiService.SelectedObject = nil
                end
            end))
        end
    end

    if not isDelta then
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local center = button.AbsolutePosition + (button.AbsoluteSize / 2)
            vim:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
            task.wait(0.03)
            vim:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
            clicked = true
        end)
    end

    return clicked
end

local function nzntPassStartupMenu()
    if not game:IsLoaded() then game.Loaded:Wait() end
    local player = game:GetService("Players").LocalPlayer
    if player then
        player:WaitForChild("PlayerGui")
    end

    local playButton = nzntFindPlayButton()
    if not playButton and not nzntStartupScreenPresent() then
        return
    end

    while nzntStartupScreenPresent() do
        task.wait(0.25)
    end

    playButton = nzntFindPlayButton()
    while not playButton do
        task.wait(0.25)
        playButton = nzntFindPlayButton()
    end

    nzntClickButton(playButton)

    task.wait(3)
    local deployButton = nzntFindDeploySelectTarget()
    local deployDeadline = os.clock() + 15
    while not deployButton and os.clock() < deployDeadline do
        task.wait(0.25)
        deployButton = nzntFindDeploySelectTarget()
    end
    if deployButton then
        nzntClickButton(deployButton)
    end
end

pcall(nzntPassStartupMenu)
task.wait(2)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local function getExecutorName()
    local ok, name = pcall(function()
        if identifyexecutor then
            return identifyexecutor()
        end
        return ""
    end)

    return ok and tostring(name or "") or ""
end

local executorName = getExecutorName()
local isDeltaExecutor = executorName:lower():find("delta", 1, true) ~= nil

local STATS_FILE = "nznt_office_stats.txt"
local CONFIG_FILE = "nznt_office_config.txt"
local CONFIG_LOCK_FILE = "nznt_office_config_locked_3_7_v2.txt"
local WEBHOOK_FILE = "nznt_webhook_config.json"
local SCRIPT_URL = "https://scripts.nznt.store/raw.php?file=office_autofarm_testing_delta_checkpoint.lua"
local AUTO_REJOIN_MINUTES = 180
local AUTO_REJOIN_SECONDS = AUTO_REJOIN_MINUTES * 60
local OLD_OFFICE_CONFIG_FILES = {
    "nznt_office_config_locked_3_5_v1.txt",
    "nznt_office_config_locked_3_7_v1.txt",
    "nznt_office_config_locked_0_4_v1.txt"
}

local MIN_DELAY = 0.0
local MAX_DELAY = 10.0

local answerDelayMin = 3.0
local answerDelayMax = 7.0

local CHAIR_SEARCH_AREA = Vector3.new(-5927.33, 4.57, -228.61)
local CHAIR_SEARCH_RADIUS = 50

local PRINTER_POS = {
    Print_1 = Vector3.new(-6008.84, 4.58, -210.84),
    Print_2 = Vector3.new(-6008.84, 4.58, -224.52),
    Print_3 = Vector3.new(-6008.84, 4.58, -238.36),
    Print_4 = Vector3.new(-5868.43, 4.58, -213.19),
    Print_5 = Vector3.new(-5868.43, 4.58, -249.96)
}

local active = false
local farmRunning = false
local joiningTeam = false
local officeAutoRejoinStarted = false
local currentSeat = nil
local unseatedSince = 0
local lastReseatAttemptAt = 0
local pendingPrint = nil
local isDoingPrinterJob = false
local printerVerifyName = nil
local printerVerifyStartedAt = 0
local printerVerifyQuestionCount = 0

local questionsAnswered = 0
local printersCompleted = 0
local totalEarned = 0
local totalTime = 0
local sessionStartTime = nil
local sessionStartMoney = nil
local startTime = nil
local startMoney = nil
local startFarm
local stopFarm

local remCorrectAnswer = nil
local remGenQuestion = nil
local remAssignPrint = nil
local questionConnection = nil
local printConnection = nil
local connections = {}
local seatBlockActive = false
local seatBlockToken = 0
local answeringQuestion = false
local lastQuestionKey = nil
local lastQuestionAt = 0
local lastAnswerAt = 0
local activeQuestionToken = 0
local setStatus
local saveCurrentTotals
local MAX_ANSWER_RETRIES = 8
local ANSWER_RETRY_DELAY = 0.65
local webhookUrl = ""
local webhookInterval = 60
local webhookEnabled = false
local lastWebhookTime = 0

local function safeNumber(value, fallback, minValue, maxValue)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge then
        number = fallback
    end
    if minValue and number < minValue then number = minValue end
    if maxValue and number > maxValue then number = maxValue end
    return number
end

local function formatNumber(n)
    n = tonumber(n) or 0
    local sign = n < 0 and "-" or ""
    local s = tostring(math.floor(math.abs(n)))
    return sign .. s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function formatTime(t)
    t = math.max(0, math.floor(tonumber(t) or 0))
    return string.format("%02d:%02d:%02d", math.floor(t / 3600) % 24, math.floor(t / 60) % 60, t % 60)
end

local function formatDelay(v)
    return string.format("%.1f", tonumber(v) or 0)
end

local function getMoney()
    local playerData = Player:FindFirstChild("PlayerData")
    if playerData then
        local value = playerData:FindFirstChild("RPValue")
            or playerData:FindFirstChild("Money")
            or playerData:FindFirstChild("Cash")
        if value and value.Value ~= nil then
            return tonumber(value.Value) or 0
        end
    end

    local leaderstats = Player:FindFirstChild("leaderstats")
    if leaderstats then
        local value = leaderstats:FindFirstChild("RP")
            or leaderstats:FindFirstChild("Money")
            or leaderstats:FindFirstChild("Cash")
        if value and value.Value ~= nil then
            return tonumber(value.Value) or 0
        end
    end

    return 0
end

local function loadStats()
    if not isfile or not readfile or not isfile(STATS_FILE) then return end

    local content = readfile(STATS_FILE)
    local earned, time = tostring(content):match("^%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*$")
    totalEarned = tonumber(earned) or totalEarned
    totalTime = tonumber(time) or totalTime
end

local function saveStats(earned, time)
    if not writefile then return end
    writefile(STATS_FILE, tostring(math.max(0, earned or totalEarned)) .. "," .. tostring(math.max(0, time or totalTime)))
end

local function loadConfig()
    if not isfile or not readfile or not isfile(CONFIG_FILE) then return end

    local content = tostring(readfile(CONFIG_FILE) or "")
    local values = {}
    for value in content:gmatch("[%d%.]+") do
        table.insert(values, tonumber(value))
    end

    if #values >= 4 then
        answerDelayMin = math.clamp(values[3] or answerDelayMin, MIN_DELAY, MAX_DELAY)
        answerDelayMax = math.clamp(values[4] or answerDelayMax, answerDelayMin, MAX_DELAY)
    elseif #values >= 2 then
        answerDelayMin = math.clamp(values[1] or answerDelayMin, MIN_DELAY, MAX_DELAY)
        answerDelayMax = math.clamp(values[2] or answerDelayMax, answerDelayMin, MAX_DELAY)
    end
end

local function saveConfig()
    if not writefile then return end
    writefile(CONFIG_FILE, table.concat({
        formatDelay(answerDelayMin),
        formatDelay(answerDelayMax)
    }, ","))
end

local function forceOfficeAnswerConfig()
    answerDelayMin = 3.0
    answerDelayMax = 7.0
end

local function migrateOfficeConfigOnce()
    if delfile and isfile then
        for _, fileName in ipairs(OLD_OFFICE_CONFIG_FILES) do
            if isfile(fileName) then
                pcall(function()
                    delfile(fileName)
                end)
            end
        end
    end

    if isfile and isfile(CONFIG_LOCK_FILE) then
        return
    end

    forceOfficeAnswerConfig()
    saveConfig()
    if writefile and isfile and not isfile(CONFIG_LOCK_FILE) then
        pcall(function()
            writefile(CONFIG_LOCK_FILE, "done")
        end)
    end
end

local function loadSharedWebhookConfig()
    if not isfile or not readfile or not isfile(WEBHOOK_FILE) then return end

    local ok, content = pcall(function()
        return readfile(WEBHOOK_FILE)
    end)

    if ok and content then
        local ok2, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(content)
        end)

        if ok2 and data then
            if data.url and data.url ~= "" then
                webhookUrl = data.url
                webhookInterval = data.interval or webhookInterval
                webhookEnabled = data.enabled == true
            end
        end
    end
end

local function saveSharedWebhookConfig()
    if not writefile then return end
    webhookInterval = safeNumber(webhookInterval, 60, 15, 300)
    pcall(function()
        writefile(WEBHOOK_FILE, game:GetService("HttpService"):JSONEncode({
            url = webhookUrl,
            interval = webhookInterval,
            enabled = webhookEnabled
        }))
    end)
end

local function sendWebhook()
    if not webhookEnabled or webhookUrl == "" or not webhookUrl:find("discord") then return end
    local interval = safeNumber(webhookInterval, 60, 15, 300)
    if (os.time() - lastWebhookTime) < interval then return end

    local money = 0
    local pd = Player:FindFirstChild("PlayerData")
    if pd then
        local rp = pd:FindFirstChild("RPValue")
            or pd:FindFirstChild("Money")
            or pd:FindFirstChild("Cash")
        if rp and rp.Value ~= nil then
            money = tonumber(rp.Value) or 0
        end
    end
    if money == 0 then
        local leaderstats = Player:FindFirstChild("leaderstats")
        if leaderstats then
            local rp = leaderstats:FindFirstChild("RP")
                or leaderstats:FindFirstChild("Money")
                or leaderstats:FindFirstChild("Cash")
            if rp and rp.Value ~= nil then
                money = tonumber(rp.Value) or 0
            end
        end
    end

    local sessionElapsed = sessionStartTime and (os.time() - sessionStartTime) or 0
    local sessionEarned = sessionStartMoney and math.max(0, money - sessionStartMoney) or 0
    local moneyPerHour = sessionElapsed > 60 and math.floor((sessionEarned / sessionElapsed) * 3600) or 0

    local body = '{"embeds":[{"title":"Office Autofarm","color":16776960,"fields":['
        ..'{"name":"💰 Current Money","value":"Rp. ' .. formatNumber(money) .. '","inline":true},'
        ..'{"name":"📈 Session Earned","value":"Rp. ' .. formatNumber(sessionEarned) .. '","inline":true},'
        ..'{"name":"⚡ Money/Hour","value":"Rp. ' .. formatNumber(moneyPerHour) .. '","inline":true},'
        ..'{"name":"⏱ Session Time","value":"' .. formatTime(sessionElapsed) .. '","inline":true},'
        ..'{"name":"🧠 Questions","value":"' .. tostring(questionsAnswered) .. '","inline":true},'
        ..'{"name":"🖨 Printers","value":"' .. tostring(printersCompleted) .. '","inline":true}'
        ..'],"footer":{"text":"by _nznt — Office Autofarm"}}]}'

    local requestFunc = http_request or request or syn and syn.request
    if requestFunc then
        local ok = pcall(function()
            requestFunc({
                Url = webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = body
            })
        end)
        if ok then
            lastWebhookTime = os.time()
        end
    end
end

loadStats()
loadConfig()
migrateOfficeConfigOnce()
loadSharedWebhookConfig()

local officeScriptSource = ""
pcall(function()
    officeScriptSource = game:HttpGet(SCRIPT_URL, true)
end)

local function injectOfficeStartFlag(source)
    local flagLine = "if getgenv then getgenv().NZNT_OFFICE_AUTO_START = true end\n"
    local injected, count = tostring(source):gsub("(setthreadidentity%(%s*7%s*%)[\r\n]+)", "%1" .. flagLine, 1)
    return count > 0 and injected or source
end

local function queueOfficeOnTeleport()
    local source = officeScriptSource
    if source == "" and readfile and isfile and isfile("office_autofarm_testing_delta_checkpoint.lua") then
        local ok, localSource = pcall(readfile, "office_autofarm_testing_delta_checkpoint.lua")
        if ok and localSource then
            source = localSource
        end
    end

    if source == "" then
        return false
    end

    local queueFunc = queue_on_teleport
        or queueonteleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
    if not queueFunc then
        return false
    end

    local ok = pcall(queueFunc, injectOfficeStartFlag(source))
    return ok
end

local function autoRejoinOffice()
    if not farmRunning then return end
    if setStatus then
        setStatus(tostring(AUTO_REJOIN_MINUTES) .. " minutes reached - rejoining...")
    end
    if saveCurrentTotals then
        saveCurrentTotals()
    end
    if not queueOfficeOnTeleport() then
        if setStatus then
            setStatus("Auto rejoin queue failed")
        end
        officeAutoRejoinStarted = false
        return
    end
    if stopFarm then
        pcall(stopFarm)
    else
        active = false
        farmRunning = false
    end
    task.wait(1)
    TeleportService:Teleport(game.PlaceId, Player)
end

local function randomDelay(minValue, maxValue)
    minValue = tonumber(minValue) or 3
    maxValue = tonumber(maxValue) or 5
    if minValue ~= minValue then minValue = 3 end
    if maxValue ~= maxValue then maxValue = 5 end
    minValue = math.clamp(minValue, MIN_DELAY, MAX_DELAY)
    maxValue = math.clamp(maxValue, minValue, MAX_DELAY)
    return minValue + math.random() * (maxValue - minValue)
end

local function safeFireServer(remote, ...)
    if not remote then return end

    local args = {...}
    task.spawn(function()
        if setthreadidentity then pcall(setthreadidentity, 2) end
        pcall(function()
            remote:FireServer(unpack(args))
        end)
        if setthreadidentity then pcall(setthreadidentity, 7) end
    end)
end

local function getChar()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function sendKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function releaseSprint()
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
    end)
end

local function setSeatBlocking(enabled)
    seatBlockActive = enabled
    seatBlockToken = seatBlockToken + 1
    local token = seatBlockToken

    local function updateHumanoid()
        local char = Player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not hum then return end

        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, not enabled)
        end)

        if enabled and hum.SeatPart then
            sendKey(Enum.KeyCode.Space)
            task.wait(0.05)
            hum.Sit = false
        end
    end

    updateHumanoid()

    if enabled then
        task.spawn(function()
            while seatBlockActive and seatBlockToken == token do
                updateHumanoid()
                task.wait(0.1)
            end
        end)
    end
end

local function jumpAndReseatCurrentSeat(reason)
    if not currentSeat or not currentSeat.Parent then
        return false
    end

    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then
        return false
    end

    setStatus(reason or "Question stuck, reseating...")
    activeQuestionToken = activeQuestionToken + 1
    answeringQuestion = false
    setSeatBlocking(false)

    sendKey(Enum.KeyCode.Space)
    task.wait(0.45)

    for _ = 1, 4 do
        if not currentSeat or not currentSeat.Parent then
            return false
        end

        pcall(function()
            hum.Sit = false
            root.CFrame = currentSeat.CFrame * CFrame.new(0, 2.5, 0)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
        task.wait(0.12)

        pcall(function()
            currentSeat:Sit(hum)
        end)
        task.wait(0.45)

        if hum.SeatPart == currentSeat then
            unseatedSince = 0
            lastQuestionAt = os.clock()
            lastAnswerAt = os.clock()
            return true
        end
    end

    lastQuestionAt = os.clock()
    lastAnswerAt = os.clock()
    return false
end

local function interactWithPrinter()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:SetKeyDown("0x65")
    end)

    task.wait(1.8)

    pcall(function()
        VirtualUser:SetKeyUp("0x65")
    end)

    return true
end

local function normalizeMathText(text)
    local normalized = tostring(text or "")
    normalized = normalized:gsub("\226\136\146", "-")
    normalized = normalized:gsub("\226\128\147", "-")
    normalized = normalized:gsub("\226\128\148", "-")
    normalized = normalized:gsub("\195\151", "*")
    normalized = normalized:gsub("\195\183", "/")
    return normalized
end

local function solveQuestion(question)
    local text = normalizeMathText(question)
    local a, op, b = text:match("([%-]?%d+%.?%d*)%s*([+%*/xX%-])%s*([%-]?%d+%.?%d*)")
    if not a then return nil end

    a = tonumber(a)
    b = tonumber(b)
    if not a or not b then return nil end
    if op == "x" or op == "X" then
        op = "*"
    end

    if op == "+" then
        return a + b
    elseif op == "-" then
        return a - b
    elseif op == "*" then
        return a * b
    elseif op == "/" and b ~= 0 then
        local result = a / b
        if result == math.floor(result) then
            return math.floor(result)
        end
        return result
    end

    return nil
end

local function findAvailableChair()
    local bestChair = nil
    local closestDist = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
            local dist = (obj.Position - CHAIR_SEARCH_AREA).Magnitude
            if dist < CHAIR_SEARCH_RADIUS and not obj.Occupant and dist < closestDist then
                closestDist = dist
                bestChair = obj
            end
        end
    end

    return bestChair
end

local function seatTP(targetSeat)
    if not targetSeat then return false end

    local char = getChar()
    local hum = char:WaitForChild("Humanoid")
    local root = char:WaitForChild("HumanoidRootPart")
    local originalCFrame = targetSeat.CFrame

    targetSeat.CFrame = root.CFrame * CFrame.new(0, -2, -3)
    task.wait(0.2)
    targetSeat:Sit(hum)
    task.wait(0.3)

    if hum.SeatPart ~= targetSeat then
        targetSeat:Sit(hum)
        task.wait(0.4)
    end

    if hum.SeatPart ~= targetSeat then
        targetSeat.CFrame = originalCFrame
        return false
    end

    targetSeat.CFrame = originalCFrame
    task.wait(0.5)

    return hum.SeatPart == targetSeat
end

local function walkTo(targetPos)
    local char = getChar()
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end

    releaseSprint()

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 7.5,
        AgentMaxSlope = 45
    })

    local success = pcall(function()
        path:ComputeAsync(root.Position, targetPos)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        hum:MoveTo(targetPos)
        local started = os.clock()
        while active and (root.Position - targetPos).Magnitude > 4 and os.clock() - started < 10 do
            task.wait(0.1)
        end
        return (root.Position - targetPos).Magnitude <= 6
    end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        if not active then break end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end

        hum:MoveTo(waypoint.Position)

        local timeout = 0
        while active and (root.Position - waypoint.Position).Magnitude > 4 and timeout < 50 do
            task.wait(0.1)
            timeout = timeout + 1
        end
    end

    releaseSprint()
    return true
end

local function ensureRemotes()
    local jobEvents = ReplicatedStorage:WaitForChild("JobEvents", 10)
    if not jobEvents then
        return false, "JobEvents not found"
    end

    remCorrectAnswer = jobEvents:WaitForChild("CorrectAnswer", 10)
    remGenQuestion = jobEvents:WaitForChild("GenerateQuestion", 10)
    remAssignPrint = jobEvents:WaitForChild("AssignPrintJob", 10)

    if not remCorrectAnswer or not remGenQuestion or not remAssignPrint then
        return false, "Office remotes not found"
    end

    return true
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "nznt_OfficeFarmTestingUI"
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- Legacy UI is never parented; Arcane owns the visible interface.

local MainFrame = Instance.new("Frame", Gui)
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 1

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 2

local TopTitle = Instance.new("TextLabel", TopBar)
TopTitle.Size = UDim2.new(1, -120, 1, 0)
TopTitle.Position = UDim2.new(0, 14, 0, 0)
TopTitle.BackgroundTransparency = 1
TopTitle.Text = "OFFICE FARM TESTING - nznt_"
TopTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
TopTitle.Font = Enum.Font.GothamBold
TopTitle.TextSize = 13
TopTitle.TextXAlignment = Enum.TextXAlignment.Left
TopTitle.ZIndex = 3

local hideBtn = Instance.new("TextButton", TopBar)
hideBtn.Size = UDim2.new(0, 70, 0, 28)
hideBtn.Position = UDim2.new(1, -80, 0.5, -14)
hideBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
hideBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 12
hideBtn.Text = "HIDE"
hideBtn.ZIndex = 3
hideBtn.BorderSizePixel = 0
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 6)

local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(1, 0, 1, -44)
ScrollFrame.Position = UDim2.new(0, 0, 0, 44)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.ZIndex = 2

local listLayout = Instance.new("UIListLayout", ScrollFrame)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 1)

local padding = Instance.new("UIPadding", ScrollFrame)
padding.PaddingBottom = UDim.new(0, 10)

hideBtn.MouseButton1Click:Connect(function()
    ScrollFrame.Visible = not ScrollFrame.Visible
    local transparency = ScrollFrame.Visible and 0 or 1
    MainFrame.BackgroundTransparency = transparency
    TopBar.BackgroundTransparency = transparency
    TopTitle.TextTransparency = transparency
    hideBtn.Text = ScrollFrame.Visible and "HIDE" or "SHOW"
end)

local function makeContainer(height, order)
    local frame = Instance.new("Frame", ScrollFrame)
    frame.Size = UDim2.new(1, 0, 0, height)
    frame.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    frame.BorderSizePixel = 0
    frame.ZIndex = 3
    frame.LayoutOrder = order
    return frame
end

local function makeSection(title, order)
    local section = makeContainer(28, order)
    section.BackgroundColor3 = Color3.fromRGB(13, 13, 13)

    local label = Instance.new("TextLabel", section)
    label.Size = UDim2.new(1, -14, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = string.upper(title)
    label.TextColor3 = Color3.fromRGB(255, 215, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
end

local function makeRow(icon, label, valueDefault, order)
    local row = makeContainer(38, order)

    local iconLabel = Instance.new("TextLabel", row)
    iconLabel.Size = UDim2.new(0, 30, 1, 0)
    iconLabel.Position = UDim2.new(0, 10, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 16
    iconLabel.ZIndex = 4

    local nameLabel = Instance.new("TextLabel", row)
    nameLabel.Size = UDim2.new(0.45, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 44, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = label
    nameLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 4

    local valueLabel = Instance.new("TextLabel", row)
    valueLabel.Size = UDim2.new(0.5, -14, 1, 0)
    valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = valueDefault
    valueLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 4

    local sep = Instance.new("Frame", row)
    sep.Size = UDim2.new(1, -14, 0, 1)
    sep.Position = UDim2.new(0, 7, 1, -1)
    sep.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    sep.BorderSizePixel = 0
    sep.ZIndex = 4

    return valueLabel
end

local function makeSlider(icon, label, minValue, maxValue, currentValue, order, onChange)
    local row = makeContainer(70, order)
    local current = currentValue

    local iconLabel = Instance.new("TextLabel", row)
    iconLabel.Size = UDim2.new(0, 30, 0, 28)
    iconLabel.Position = UDim2.new(0, 10, 0, 5)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 16
    iconLabel.ZIndex = 4

    local nameLabel = Instance.new("TextLabel", row)
    nameLabel.Size = UDim2.new(0.45, 0, 0, 28)
    nameLabel.Position = UDim2.new(0, 44, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = label
    nameLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 4

    local valueBox = Instance.new("TextBox", row)
    valueBox.Size = UDim2.new(0, 56, 0, 28)
    valueBox.Position = UDim2.new(1, -70, 0, 5)
    valueBox.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    valueBox.Text = formatDelay(current)
    valueBox.TextColor3 = Color3.fromRGB(230, 230, 230)
    valueBox.Font = Enum.Font.GothamBold
    valueBox.TextSize = 13
    valueBox.TextXAlignment = Enum.TextXAlignment.Center
    valueBox.ClearTextOnFocus = false
    valueBox.BorderSizePixel = 0
    valueBox.ZIndex = 10
    Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 4)

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1, -114, 0, 6)
    track.Position = UDim2.new(0, 44, 0, 45)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    track.BorderSizePixel = 0
    track.ZIndex = 4
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)

    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 6
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local sep = Instance.new("Frame", row)
    sep.Size = UDim2.new(1, -14, 0, 1)
    sep.Position = UDim2.new(0, 7, 1, -1)
    sep.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    sep.BorderSizePixel = 0
    sep.ZIndex = 4

    local function refresh(value, callCallback)
        value = safeNumber(value, current, minValue, maxValue)
        value = math.floor(value * 10) / 10
        current = value

        local ratio = (value - minValue) / (maxValue - minValue)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, -9, 0.5, -9)
        valueBox.Text = formatDelay(value)

        if callCallback then
            onChange(value)
        end
    end

    local function setFromInput(input)
        local width = track.AbsoluteSize.X
        if width <= 0 then return end

        local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X) / width, 0, 1)
        refresh(minValue + ratio * (maxValue - minValue), true)
    end

    refresh(current, false)

    valueBox.FocusLost:Connect(function()
        local parsed = tonumber(valueBox.Text:gsub("[^%d%.%-]", ""))
        if parsed then
            refresh(parsed, true)
        else
            valueBox.Text = formatDelay(current)
        end
    end)

    local dragging = false
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromInput(input)
        end
    end)
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromInput(input)
        end
    end)

    return function(value)
        refresh(value, false)
    end
end

makeSection("About", 0)
local aboutRow = makeContainer(100, 1)

local avatar = Instance.new("ImageLabel", aboutRow)
avatar.Size = UDim2.new(0, 80, 0, 80)
avatar.Position = UDim2.new(0, 10, 0.5, -40)
avatar.BackgroundTransparency = 1
avatar.Image = "rbxassetid://75353810328300"
avatar.ScaleType = Enum.ScaleType.Crop
avatar.ZIndex = 4
Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 10)

local credit = Instance.new("TextLabel", aboutRow)
credit.Size = UDim2.new(1, -104, 1, 0)
credit.Position = UDim2.new(0, 100, 0, 0)
credit.BackgroundTransparency = 1
credit.Text = "Script made by _nznt\nOffice Farm + Anti-AFK + Manual Start\n100% by myself"
credit.TextColor3 = Color3.fromRGB(255, 215, 0)
credit.Font = Enum.Font.Gotham
credit.TextSize = 12
credit.TextXAlignment = Enum.TextXAlignment.Left
credit.TextYAlignment = Enum.TextYAlignment.Center
credit.TextWrapped = true
credit.ZIndex = 4

makeSection("Money", 10)
local vCurrent = makeRow("💰", "Current Money", "Rp. 0", 11)
local vEarned = makeRow("📈", "Earned", "Rp. 0", 12)
local vMoneyHour = makeRow("⚡", "Money / Hour", "Calculating...", 13)

makeSection("Total Stats", 15)
local vTotalEarned = makeRow("🏆", "Total Earned", "Rp. " .. formatNumber(totalEarned), 16)
local vTotalTime = makeRow("⏰", "Total Time", formatTime(totalTime), 17)

local resetRow = makeContainer(50, 18)
local resetBtn = Instance.new("TextButton", resetRow)
resetBtn.Size = UDim2.new(1, -20, 0, 32)
resetBtn.Position = UDim2.new(0, 10, 0, 9)
resetBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 12
resetBtn.Text = "🔄 Reset Total Stats"
resetBtn.BorderSizePixel = 0
resetBtn.ZIndex = 4
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 5)

makeSection("Delays", 20)

local setAnswerMinSlider
local setAnswerMaxSlider

setAnswerMinSlider = makeSlider("⏱", "Answer Delay Min", MIN_DELAY, MAX_DELAY, answerDelayMin, 21, function(value)
    answerDelayMin = value
    if answerDelayMax < answerDelayMin then
        answerDelayMax = answerDelayMin
        if setAnswerMaxSlider then setAnswerMaxSlider(answerDelayMax) end
    end
    saveConfig()
end)

setAnswerMaxSlider = makeSlider("⏳", "Answer Delay Max", MIN_DELAY, MAX_DELAY, answerDelayMax, 22, function(value)
    answerDelayMax = math.max(value, answerDelayMin)
    if value < answerDelayMin and setAnswerMaxSlider then
        setAnswerMaxSlider(answerDelayMax)
    end
    saveConfig()
end)

makeSection("Office Stats", 30)
local vStatus = makeRow("▶", "Status", "Ready", 31)
local vQuestions = makeRow("🧠", "Questions Answered", "0", 32)
local vPrinters = makeRow("🖨", "Printers Completed", "0", 33)

makeSection("Discord Webhook", 40)
local webhookUrlRow = makeContainer(50, 41)
local webhookUrlLabel = Instance.new("TextLabel", webhookUrlRow)
webhookUrlLabel.Size = UDim2.new(0, 70, 0, 20)
webhookUrlLabel.Position = UDim2.new(0, 14, 0, 8)
webhookUrlLabel.BackgroundTransparency = 1
webhookUrlLabel.Text = "Webhook URL"
webhookUrlLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
webhookUrlLabel.Font = Enum.Font.GothamBold
webhookUrlLabel.TextSize = 11
webhookUrlLabel.TextXAlignment = Enum.TextXAlignment.Left
webhookUrlLabel.ZIndex = 4

local webhookBox = Instance.new("TextBox", webhookUrlRow)
webhookBox.Size = UDim2.new(1, -28, 0, 26)
webhookBox.Position = UDim2.new(0, 14, 0, 22)
webhookBox.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
webhookBox.Text = webhookUrl
webhookBox.PlaceholderText = "Paste Discord webhook URL..."
webhookBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
webhookBox.TextColor3 = Color3.fromRGB(230, 230, 230)
webhookBox.Font = Enum.Font.Gotham
webhookBox.TextSize = 11
webhookBox.TextXAlignment = Enum.TextXAlignment.Left
webhookBox.ClearTextOnFocus = false
webhookBox.BorderSizePixel = 0
webhookBox.ZIndex = 10
Instance.new("UICorner", webhookBox).CornerRadius = UDim.new(0, 4)

local webhookEnabledRow = makeContainer(38, 42)
local webhookToggle = Instance.new("TextButton", webhookEnabledRow)
webhookToggle.Size = UDim2.new(1, -20, 0, 26)
webhookToggle.Position = UDim2.new(0, 10, 0.5, -13)
webhookToggle.BorderSizePixel = 0
webhookToggle.Font = Enum.Font.GothamBold
webhookToggle.TextSize = 12
webhookToggle.ZIndex = 4
Instance.new("UICorner", webhookToggle).CornerRadius = UDim.new(0, 5)

local function refreshWebhookToggle()
    webhookToggle.Text = webhookEnabled and "Webhook: ON" or "Webhook: OFF"
    webhookToggle.BackgroundColor3 = webhookEnabled and Color3.fromRGB(0, 150, 70) or Color3.fromRGB(150, 35, 35)
    webhookToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
end

webhookBox.FocusLost:Connect(function()
    webhookUrl = tostring(webhookBox.Text or "")
    saveSharedWebhookConfig()
end)

webhookToggle.MouseButton1Click:Connect(function()
    webhookEnabled = not webhookEnabled
    refreshWebhookToggle()
    saveSharedWebhookConfig()
end)

local setWebhookIntervalSlider
setWebhookIntervalSlider = makeSlider("⏱", "Webhook Interval", 15, 300, webhookInterval, 43, function(value)
    webhookInterval = safeNumber(value, 60, 15, 300)
    saveSharedWebhookConfig()
end)

refreshWebhookToggle()

local function loadNzntAutofarmArcane()
    local source
    if readfile and isfile and isfile("nznt_autofarm_arcane.lua") then
        local ok, content = pcall(function()
            return readfile("nznt_autofarm_arcane.lua")
        end)
        if ok and content and content ~= "" then
            source = content
        end
    end

    if not source then
        source = game:HttpGet("https://scripts.nznt.store/raw.php?file=nznt_autofarm_arcane.lua", true)
    end

    return loadstring(source)()
end

local ArcaneHelper = loadNzntAutofarmArcane()
local ArcaneUI = ArcaneHelper.CreateFarmWindow({
    Name = "Office Autofarm",
    SubTitle = "Delta checkpoint build",
    PageName = "Office",
    Webhook = true
})

Gui:Destroy()
Gui = ArcaneUI.Library.Holder.Instance

local moneySection = ArcaneUI.StatsPage:Section({Name = "Money", Icon = "97491613646216"})
vCurrent = ArcaneHelper.MakeStat(moneySection, "Current Money", "Rp. 0")
vEarned = ArcaneHelper.MakeStat(moneySection, "Earned", "Rp. 0")
vMoneyHour = ArcaneHelper.MakeStat(moneySection, "Money / Hour", "Calculating...")

local totalsSection = ArcaneUI.StatsPage:Section({Name = "Total Stats", Icon = "97491613646216"})
vTotalEarned = ArcaneHelper.MakeStat(totalsSection, "Total Earned", "Rp. " .. formatNumber(totalEarned))
vTotalTime = ArcaneHelper.MakeStat(totalsSection, "Total Time", formatTime(totalTime))

local resetCallbacks = {}
local resetProxy = {
    MouseButton1Click = {
        Connect = function(_, callback)
            table.insert(resetCallbacks, callback)
        end
    }
}
setmetatable(resetProxy, {
    __newindex = function(self, key, value)
        rawset(self, key, value)
    end
})

totalsSection:Button({
    Name = "Reset Total Stats",
    Callback = function()
        for _, callback in ipairs(resetCallbacks) do
            task.spawn(callback)
        end
    end
})
resetBtn = resetProxy

local officeSection = ArcaneUI.StatsPage:Section({Name = "Office Stats", Icon = "136879043989014"})
vStatus = ArcaneHelper.MakeStat(officeSection, "Status", "Ready")
vQuestions = ArcaneHelper.MakeStat(officeSection, "Questions Answered", "0")
vPrinters = ArcaneHelper.MakeStat(officeSection, "Printers Completed", "0")

local delaySection = ArcaneUI.ConfigPage:Section({Name = "Delays", Icon = "136879043989014"})
local lockState = ArcaneHelper.MakeLockedConfig(ArcaneUI, {
    Section = delaySection,
    ButtonName = "Unlock Delay Config"
})
ArcaneHelper.MakeBlackScreenToggle(ArcaneUI, delaySection, "OfficeBlackScreen")

delaySection:Button({
    Name = "Start / Stop Office Farm",
    Callback = function()
        if farmRunning then
            if stopFarm then stopFarm() end
            return
        end

        if startFarm then
            task.spawn(function()
                if not startFarm() then
                    vStatus.Text = "Start failed - Ready"
                end
            end)
        end
    end
})

local suppressDelayCallback = true
local minDelaySlider
local maxDelaySlider

local function restoreLockedOfficeDelay()
    answerDelayMin = 3.0
    answerDelayMax = 7.0
    saveConfig()
    suppressDelayCallback = true
    if minDelaySlider and minDelaySlider.Set then minDelaySlider:Set(answerDelayMin) end
    if maxDelaySlider and maxDelaySlider.Set then maxDelaySlider:Set(answerDelayMax) end
    suppressDelayCallback = false
end

minDelaySlider = delaySection:Slider({
    Name = "Answer Delay Min",
    Flag = "OfficeAnswerDelayMin",
    Min = MIN_DELAY,
    Max = MAX_DELAY,
    Default = answerDelayMin,
    Suffix = "s",
    Decimals = 1,
    Callback = function(value)
        if suppressDelayCallback then return end
        if not lockState:Guard(restoreLockedOfficeDelay) then return end
        answerDelayMin = value
        if answerDelayMax < answerDelayMin then
            answerDelayMax = answerDelayMin
            if maxDelaySlider and maxDelaySlider.Set then maxDelaySlider:Set(answerDelayMax) end
        end
        saveConfig()
    end
})

maxDelaySlider = delaySection:Slider({
    Name = "Answer Delay Max",
    Flag = "OfficeAnswerDelayMax",
    Min = MIN_DELAY,
    Max = MAX_DELAY,
    Default = answerDelayMax,
    Suffix = "s",
    Decimals = 1,
    Callback = function(value)
        if suppressDelayCallback then return end
        if not lockState:Guard(restoreLockedOfficeDelay) then return end
        answerDelayMax = math.max(value, answerDelayMin)
        if value < answerDelayMin and maxDelaySlider and maxDelaySlider.Set then
            maxDelaySlider:Set(answerDelayMax)
        end
        saveConfig()
    end
})

suppressDelayCallback = false
if minDelaySlider and minDelaySlider.SetLocked then minDelaySlider:SetLocked(true, "Config Locked, Press Unlock to modify!") end
if maxDelaySlider and maxDelaySlider.SetLocked then maxDelaySlider:SetLocked(true, "Config Locked, Press Unlock to modify!") end
lockState.OnUnlock = function()
    if minDelaySlider and minDelaySlider.SetLocked then minDelaySlider:SetLocked(false) end
    if maxDelaySlider and maxDelaySlider.SetLocked then maxDelaySlider:SetLocked(false) end
end
local oldGuard = lockState.Guard
function lockState:Guard(onLocked)
    local ok = oldGuard(self, onLocked)
    if ok then
        if minDelaySlider and minDelaySlider.SetLocked then minDelaySlider:SetLocked(false) end
        if maxDelaySlider and maxDelaySlider.SetLocked then maxDelaySlider:SetLocked(false) end
    end
    return ok
end
setAnswerMinSlider = function(value)
    suppressDelayCallback = true
    if minDelaySlider and minDelaySlider.Set then minDelaySlider:Set(value) end
    suppressDelayCallback = false
end
setAnswerMaxSlider = function(value)
    suppressDelayCallback = true
    if maxDelaySlider and maxDelaySlider.Set then maxDelaySlider:Set(value) end
    suppressDelayCallback = false
end

local webhookSection = ArcaneUI.WebhookPage:Section({Name = "Discord Webhook", Icon = "136879043989014"})
webhookSection:Textbox({
    Flag = "OfficeWebhookUrl",
    Placeholder = "Discord webhook URL",
    Default = webhookUrl,
    Finished = true,
    Numeric = false,
    Callback = function(value)
        webhookUrl = tostring(value or "")
        saveSharedWebhookConfig()
    end
})

webhookSection:Toggle({
    Name = "Enable Webhook",
    Flag = "OfficeWebhookEnabled",
    Default = webhookEnabled,
    Callback = function(value)
        webhookEnabled = value
        saveSharedWebhookConfig()
    end
})

local suppressWebhookInterval = true
local webhookIntervalSlider = webhookSection:Slider({
    Name = "Webhook Interval",
    Flag = "OfficeWebhookInterval",
    Min = 15,
    Max = 300,
    Default = webhookInterval,
    Suffix = "s",
    Decimals = 0,
    Callback = function(value)
        if suppressWebhookInterval then return end
        webhookInterval = safeNumber(value, 60, 15, 300)
        saveSharedWebhookConfig()
    end
})
suppressWebhookInterval = false
setWebhookIntervalSlider = function(value)
    suppressWebhookInterval = true
    if webhookIntervalSlider and webhookIntervalSlider.Set then webhookIntervalSlider:Set(value) end
    suppressWebhookInterval = false
end

function setStatus(text)
    vStatus.Text = text
    print("[Office Farm] " .. text)
end

resetBtn.MouseButton1Click:Connect(function()
    totalEarned = 0
    totalTime = 0
    saveStats(0, 0)
    vTotalEarned.Text = "Rp. 0"
    vTotalTime.Text = "00:00:00"
    resetBtn.Text = "Stats Reset"
    resetBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
    task.wait(2)
    resetBtn.Text = "🔄 Reset Total Stats"
    resetBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)

local function normalizeAnswerText(text)
    local normalized = normalizeMathText(text):lower():gsub("%s+", ""):gsub(",", "")
    return normalized
end

local function getGuiText(obj)
    if obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
        return obj.Text or ""
    end

    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("TextBox") then
            local text = child.Text
            if text and text ~= "" then
                return text
            end
        end
    end

    return ""
end

local function normalizeAnswerEntries(entries)
    local cleaned = {}
    local seen = {}

    if type(entries) ~= "table" then
        return cleaned
    end

    for _, entry in ipairs(entries) do
        if type(entry) == "table" then
            local text = tostring(entry.Text or "")
            local normalized = normalizeAnswerText(text)
            if normalized ~= "" and not seen[normalized] then
                seen[normalized] = true
                table.insert(cleaned, entry)
            end
        end
    end

    return cleaned
end

local function isVisibleGuiObject(obj)
    if obj:IsDescendantOf(Gui) then return false end
    if not obj:IsA("GuiObject") then return false end
    if obj.AbsoluteSize.X <= 0 or obj.AbsoluteSize.Y <= 0 then return false end

    local current = obj
    while current do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end
        if (current:IsA("ScreenGui") or current:IsA("SurfaceGui") or current:IsA("BillboardGui")) and not current.Enabled then
            return false
        end
        current = current.Parent
    end

    return true
end

local function answerTextMatches(buttonText, answerText, solvedValue)
    local normalizedButton = normalizeAnswerText(buttonText)
    local normalizedAnswer = normalizeAnswerText(answerText)
    local normalizedSolved = normalizeAnswerText(solvedValue)

    if normalizedButton == "" then return false end
    if normalizedAnswer ~= "" and normalizedButton == normalizedAnswer then return true end
    if normalizedSolved ~= "" and normalizedButton == normalizedSolved then return true end

    local numericButton = tonumber(normalizeMathText(buttonText):match("[%-]?%d+%.?%d*"))
    local numericSolved = tonumber(solvedValue)
    return numericButton ~= nil and numericSolved ~= nil and numericButton == numericSolved
end

local function findMatchingAnswerTarget(button, answerText, solvedValue)
    local bestTarget = nil
    local bestArea = math.huge

    local function consider(obj, text)
        if not obj:IsA("GuiObject") or not isVisibleGuiObject(obj) then return end
        if not answerTextMatches(text, answerText, solvedValue) then return end

        local area = obj.AbsoluteSize.X * obj.AbsoluteSize.Y
        if area > 0 and area < bestArea then
            bestTarget = obj
            bestArea = area
        end
    end

    if button:IsA("TextButton") then
        consider(button, button.Text or "")
    end

    for _, child in ipairs(button:GetDescendants()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("TextBox") then
            consider(child, child.Text or "")
        end
    end

    return bestTarget
end

local function guiContainsQuestion(root, questionText)
    local needles = {}
    local normalizedQuestion = normalizeAnswerText(questionText)
    if normalizedQuestion ~= "" then
        needles[#needles + 1] = normalizedQuestion
    end

    local a, op, b = normalizeMathText(questionText):match("([%-]?%d+%.?%d*)%s*([+%*/xX%-])%s*([%-]?%d+%.?%d*)")
    if a and op and b then
        if op == "x" or op == "X" then
            op = "*"
        end
        local normalizedEquation = normalizeAnswerText(a .. op .. b)
        if normalizedEquation ~= "" then
            needles[#needles + 1] = normalizedEquation
        end
    end

    if #needles == 0 then return false end

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
            local haystack = normalizeAnswerText(obj.Text)
            if haystack ~= "" then
                for _, needle in ipairs(needles) do
                    if haystack:find(needle, 1, true) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function getRootDisplayOrder(obj)
    local current = obj
    while current do
        if current:IsA("ScreenGui") then
            return current.DisplayOrder or 0
        end
        current = current.Parent
    end
    return 0
end

local function getTopmostScore(button)
    local center = button.AbsolutePosition + (button.AbsoluteSize / 2)
    local ok, objects = pcall(function()
        return GuiService:GetGuiObjectsAtPosition(center.X, center.Y)
    end)

    if not ok or type(objects) ~= "table" then return 0 end

    for index, obj in ipairs(objects) do
        if obj == button or obj:IsDescendantOf(button) or button:IsDescendantOf(obj) then
            return math.max(0, 80 - index)
        end
    end

    return 0
end

local function scoreAnswerButton(button, questionText)
    local score = 0
    local area = button.AbsoluteSize.X * button.AbsoluteSize.Y

    score = score + getRootDisplayOrder(button) * 4
    score = score + getTopmostScore(button)
    score = score + math.min(30, area / 1000)
    score = score + (button.ZIndex or 0)

    local current = button.Parent
    local depth = 1
    while current and depth <= 8 do
        local name = current.Name:lower()
        if name:find("work", 1, true) or name:find("question", 1, true) or name:find("answer", 1, true) then
            score = score + 6
        end

        if questionText and guiContainsQuestion(current, questionText) then
            score = score + (220 - depth * 10)
            break
        end

        current = current.Parent
        depth = depth + 1
    end

    return score
end

local function getAnswerButtonRoots()
    local roots = {}
    local workGui = PlayerGui:FindFirstChild("WorkGui")

    if workGui then
        roots[#roots + 1] = workGui
    end

    return roots
end

local function isOfficeAnswerCandidate(obj)
    local current = obj

    while current do
        local name = current.Name:lower()
        if name == "workgui" then
            return true
        end

        if current:IsA("SurfaceGui") or current:IsA("BillboardGui") then
            return name:find("work", 1, true)
                or name:find("office", 1, true)
                or name:find("computer", 1, true)
        end

        if current == PlayerGui or current == workspace then
            break
        end

        current = current.Parent
    end

    return false
end

local function findAnswerButton(answerText, solvedValue, questionText)
    local bestButton = nil
    local bestScore = -math.huge
    local candidateCount = 0
    local candidates = {}
    local seenKeys = {}

    for _, root in ipairs(getAnswerButtonRoots()) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                local target = findMatchingAnswerTarget(obj, answerText, solvedValue)
                if target and isVisibleGuiObject(obj) and isOfficeAnswerCandidate(obj) then
                    local dedupeKey = normalizeAnswerText(getGuiText(target))
                    if dedupeKey == "" then
                        dedupeKey = normalizeAnswerText(getGuiText(obj))
                    end
                    if dedupeKey ~= "" and seenKeys[dedupeKey] then
                        continue
                    end
                    if dedupeKey ~= "" then
                        seenKeys[dedupeKey] = true
                    end

                    local score = scoreAnswerButton(obj, questionText) + getTopmostScore(target)
                    candidateCount = candidateCount + 1
                    table.insert(candidates, {
                        Button = obj,
                        Target = target,
                        Score = score
                    })
                    if score >= bestScore then
                        bestButton = obj
                        bestScore = score
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.Score > b.Score
    end)

    return bestButton, candidateCount, candidates
end

local function fireGuiButtonDirectly(button)
    if not button or not button.Parent or not button:IsA("GuiButton") then return false end

    local fired = false
    local function mark(ok)
        fired = ok or fired
    end

    mark(pcall(function()
        button:Activate()
    end))

    local signals = {
        button.MouseButton1Click,
        button.Activated
    }

    for _, signal in ipairs(signals) do
        if firesignal then
            mark(pcall(function()
                firesignal(signal)
            end))
        end

        if not isDeltaExecutor and getconnections then
            local ok, signalConnections = pcall(function()
                return getconnections(signal)
            end)

            if ok and type(signalConnections) == "table" then
                for _, connection in ipairs(signalConnections) do
                    local didCall = false
                    local okConnection = pcall(function()
                        if connection.Fire then
                            didCall = true
                            connection:Fire()
                        elseif connection.Function then
                            didCall = true
                            connection.Function()
                        end
                    end)
                    fired = (okConnection and didCall) or fired
                end
            end
        end
    end

    if isDeltaExecutor and isVisibleGuiObject(button) then
        mark(pcall(function()
            button.Selectable = true
            GuiService.SelectedObject = button

            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.04)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.KeypadEnter, false, game)
            task.wait(0.04)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.KeypadEnter, false, game)

            if GuiService.SelectedObject == button then
                GuiService.SelectedObject = nil
            end
        end))
    end

    if not isDeltaExecutor then
        pcall(function()
            local center = button.AbsolutePosition + (button.AbsoluteSize / 2)
            VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
            fired = true
        end)
    end

    return fired
end

local function clickAnswerButtonAndWait(button, timeout, target)
    local response = nil
    local done = false
    local conn

    conn = remCorrectAnswer.OnClientEvent:Connect(function(result)
        response = result
        done = true
    end)

    local started = os.clock()
    local clicked = false

    clicked = fireGuiButtonDirectly(button)

    if target and target ~= button and target:IsA("GuiButton") then
        clicked = fireGuiButtonDirectly(target) or clicked
    end

    while active and not done and os.clock() - started < timeout do
        task.wait(0.05)
    end

    if conn then conn:Disconnect() end
    return response, clicked
end

local function answerQuestion(question, answers, sessionId, attempt, questionToken)
    attempt = tonumber(attempt) or 1
    questionToken = tonumber(questionToken) or activeQuestionToken
    if not active or answeringQuestion or questionToken ~= activeQuestionToken then return end
    answeringQuestion = true

    task.spawn(function()
        local ok, err = pcall(function()
            if not active or questionToken ~= activeQuestionToken then return end
            local solvedValue = solveQuestion(question)
            if not solvedValue then return end

            local correctAnswerText = tostring(solvedValue)
            local correctAnswerIndex = nil
            local answerCount = 0
            local filteredAnswers = normalizeAnswerEntries(answers)

            if #filteredAnswers > 0 then
                answerCount = #filteredAnswers

                for index, answer in ipairs(filteredAnswers) do
                    if type(answer) == "table" and tonumber(answer.Text) == solvedValue then
                        correctAnswerText = tostring(answer.Text)
                        correctAnswerIndex = index
                        break
                    end
                end
            end

            task.wait(randomDelay(answerDelayMin, answerDelayMax))
            if not active or questionToken ~= activeQuestionToken then return end

            local answerButton, candidateCount, candidates = findAnswerButton(correctAnswerText, solvedValue, question)
            if not answerButton then
                if attempt < MAX_ANSWER_RETRIES and questionToken == activeQuestionToken then
                    setStatus("Retrying answer...")
                    task.delay(ANSWER_RETRY_DELAY, function()
                        answerQuestion(question, answers, sessionId, attempt + 1, questionToken)
                    end)
                else
                    jumpAndReseatCurrentSeat("Answer failed after 8 retries, reseating...")
                end
                return
            end

            local finalResponse = nil
            local clickedAny = false
            local clickedButton = nil
            local clickedTarget = nil

            for index, candidate in ipairs(candidates) do
                if not active or questionToken ~= activeQuestionToken then return end

                local timeout = index == #candidates and 4 or 1.3
                local response, clicked = clickAnswerButtonAndWait(candidate.Button, timeout, candidate.Target, correctAnswerIndex, answerCount)
                clickedAny = clickedAny or clicked

                if clicked then
                    clickedButton = candidate.Button
                    clickedTarget = candidate.Target
                end

                if response == true or tostring(response):lower() == "success" then
                    finalResponse = response
                    clickedButton = candidate.Button
                    clickedTarget = candidate.Target
                    break
                end

                task.wait(0.12)
            end

            if finalResponse == true or tostring(finalResponse):lower() == "success" then
                questionsAnswered = questionsAnswered + 1
                lastAnswerAt = os.clock()
                if printerVerifyName then
                    printersCompleted = printersCompleted + 1
                    vPrinters.Text = tostring(printersCompleted)
                    printerVerifyName = nil
                    printerVerifyStartedAt = 0
                    printerVerifyQuestionCount = 0
                end
                vQuestions.Text = tostring(questionsAnswered)
                setStatus("Answered question")
            elseif clickedAny and clickedButton then
                setStatus("Answer clicked")
                if attempt < MAX_ANSWER_RETRIES and questionToken == activeQuestionToken then
                    task.delay(ANSWER_RETRY_DELAY, function()
                        answerQuestion(question, answers, sessionId, attempt + 1, questionToken)
                    end)
                else
                    jumpAndReseatCurrentSeat("Answer clicked but not accepted, reseating...")
                end
            elseif attempt < MAX_ANSWER_RETRIES then
                setStatus("Retrying answer...")
                if questionToken == activeQuestionToken then
                    task.delay(ANSWER_RETRY_DELAY, function()
                        answerQuestion(question, answers, sessionId, attempt + 1, questionToken)
                    end)
                end
            else
                jumpAndReseatCurrentSeat("Answer failed after 8 retries, reseating...")
            end
        end)

        answeringQuestion = false

        if not ok then
            warn("[Office Farm] Question handler error: " .. tostring(err))
        end
    end)
end

local function onQuestionReceived(question, answers, sessionId)
    if not active then return end

    local questionKey = tostring(sessionId or "") .. "|" .. normalizeAnswerText(question)
    local now = os.clock()
    if questionKey == lastQuestionKey and now - lastQuestionAt < 4 then
        return
    end

    lastQuestionKey = questionKey
    lastQuestionAt = now
    activeQuestionToken = activeQuestionToken + 1
    answerQuestion(question, answers, sessionId, 1, activeQuestionToken)
end

local function hookOfficeRemotes()
    if questionConnection or printConnection then return end

    questionConnection = remGenQuestion.OnClientEvent:Connect(onQuestionReceived)
    printConnection = remAssignPrint.OnClientEvent:Connect(function(printerName)
        if not active then return end
        pendingPrint = printerName
        setStatus("Print job assigned: " .. tostring(printerName))
    end)

    table.insert(connections, questionConnection)
    table.insert(connections, printConnection)
end

local function joinOfficeTeam()
    if joiningTeam then return true end
    joiningTeam = true

    setStatus("Joining office team...")

    local menuToggleRemote = ReplicatedStorage:WaitForChild("menuToggleRequest", 10)
    if menuToggleRemote then
        safeFireServer(menuToggleRemote)
        task.wait(1)
    end

    local jobEvents = ReplicatedStorage:WaitForChild("JobEvents", 10)
    if not jobEvents then
        joiningTeam = false
        return false, "JobEvents not found"
    end

    local teamChangeRemote = jobEvents:WaitForChild("TeamChangeRequest", 10)
    if not teamChangeRemote then
        joiningTeam = false
        return false, "TeamChangeRequest not found"
    end

    safeFireServer(teamChangeRemote, "Office Worker", 0, 0, 0, "MainMenu")
    task.wait(3)

    joiningTeam = false
    return true
end

saveCurrentTotals = function()
    if sessionStartTime and sessionStartMoney then
        local sessionElapsed = os.time() - sessionStartTime
        local sessionEarned = math.max(0, getMoney() - sessionStartMoney)
        saveStats(totalEarned + sessionEarned, totalTime + sessionElapsed)
    else
        saveStats(totalEarned, totalTime)
    end
end

function stopFarm()
    if not farmRunning then return end

    active = false
    farmRunning = false
    releaseSprint()
    setSeatBlocking(false)

    if sessionStartTime and sessionStartMoney then
        local sessionElapsed = os.time() - sessionStartTime
        local sessionEarned = math.max(0, getMoney() - sessionStartMoney)
        totalEarned = totalEarned + sessionEarned
        totalTime = totalTime + sessionElapsed
        saveStats(totalEarned, totalTime)
    end

    sessionStartTime = nil
    sessionStartMoney = nil
    startTime = nil
    startMoney = nil
    pendingPrint = nil
    isDoingPrinterJob = false
    printerVerifyName = nil
    printerVerifyStartedAt = 0
    printerVerifyQuestionCount = 0
    unseatedSince = 0
    lastReseatAttemptAt = 0

    setStatus("Stopped - Ready")
    vEarned.Text = "Rp. 0"
    vMoneyHour.Text = "Calculating..."
    vTotalEarned.Text = "Rp. " .. formatNumber(totalEarned)
    vTotalTime.Text = formatTime(totalTime)
end

local function mainFarmLoop()
    local usedInitialSeatTeleport = false

    while active do
        local char = getChar()
        local hum = char:WaitForChild("Humanoid")

        setStatus("Finding empty chair...")
        local seat = findAvailableChair()

        if not seat then
            setStatus("No chair found, retrying...")
            task.wait(3)
            continue
        end

        currentSeat = seat
        local seated = false

        if not usedInitialSeatTeleport then
            setStatus("Moving to chair...")
            seated = seatTP(seat)
            usedInitialSeatTeleport = seated
        else
            setStatus("Walking to chair...")
            walkTo(seat.Position)
            task.wait(0.3)
            seat:Sit(hum)
            task.wait(0.5)
            seated = hum.SeatPart == seat
        end

        if not seated then
            setStatus("Seat failed, retrying...")
            task.wait(2)
            continue
        end

        setStatus("Seated - answering questions")
        unseatedSince = 0
        lastReseatAttemptAt = 0

        while active do
            if pendingPrint then
                local pos = PRINTER_POS[pendingPrint]
                if pos then
                    isDoingPrinterJob = true
                    local officeSeat = currentSeat
                    local currentPrint = pendingPrint
                    printerVerifyName = nil
                    printerVerifyStartedAt = 0
                    printerVerifyQuestionCount = 0
                    setStatus("Walking to printer...")
                    setSeatBlocking(true)

                    sendKey(Enum.KeyCode.Space)
                    task.wait(0.5)

                    walkTo(pos)
                    task.wait(0.5)

                    setStatus("Collecting printer job...")
                    interactWithPrinter()
                    task.wait(1)

                    setStatus("Printer submitted")
                    pendingPrint = nil

                    setStatus("Returning to chair...")
                    if officeSeat and officeSeat.Parent then
                        walkTo(officeSeat.Position)
                        task.wait(0.5)
                        setSeatBlocking(false)
                        officeSeat:Sit(hum)
                        task.wait(0.5)
                        currentSeat = officeSeat
                        unseatedSince = 0
                        lastReseatAttemptAt = 0
                        printerVerifyName = currentPrint
                        printerVerifyStartedAt = hum.SeatPart == officeSeat and os.clock() or 0
                        printerVerifyQuestionCount = questionsAnswered
                        setStatus("Back in chair")
                    else
                        setSeatBlocking(false)
                        setStatus("No return chair found")
                    end

                    isDoingPrinterJob = false
                    setSeatBlocking(false)
                else
                    pendingPrint = nil
                end
            elseif printerVerifyName and currentSeat and hum.SeatPart == currentSeat then
                if questionsAnswered > printerVerifyQuestionCount then
                    printerVerifyName = nil
                    printerVerifyStartedAt = 0
                    printerVerifyQuestionCount = 0
                elseif printerVerifyStartedAt <= 0 then
                    printerVerifyStartedAt = os.clock()
                elseif os.clock() - printerVerifyStartedAt >= 15 then
                    pendingPrint = printerVerifyName
                    printerVerifyName = nil
                    printerVerifyStartedAt = 0
                    printerVerifyQuestionCount = 0
                    setStatus("Printer not confirmed, retrying...")
                end
            elseif not pendingPrint and not printerVerifyName and not isDoingPrinterJob
                and (answeringQuestion or (lastQuestionAt or 0) > (lastAnswerAt or 0))
                and currentSeat and hum.SeatPart == currentSeat
            then
                local lastProgressAt = math.max(lastQuestionAt or 0, lastAnswerAt or 0)
                if lastProgressAt > 0 and os.clock() - lastProgressAt >= 8 then
                    jumpAndReseatCurrentSeat("Question stuck for 8s, reseating...")
                end
            elseif not isDoingPrinterJob and hum.SeatPart ~= currentSeat then
                if currentSeat and currentSeat.Parent then
                    if unseatedSince <= 0 then
                        unseatedSince = os.clock()
                    end

                    if os.clock() - lastReseatAttemptAt >= 1.5 then
                        lastReseatAttemptAt = os.clock()
                        jumpAndReseatCurrentSeat("Unseated, reseating...")
                    elseif os.clock() - unseatedSince >= 4 then
                        setStatus("Walking back to chair...")
                        walkTo(currentSeat.Position)
                        task.wait(0.2)
                        jumpAndReseatCurrentSeat("Retrying chair seat...")
                    else
                        setStatus("Reseating...")
                    end
                else
                    break
                end
            elseif currentSeat and hum.SeatPart == currentSeat then
                unseatedSince = 0
            end

            task.wait(0.2)
        end

        task.wait(1)
    end
end

function startFarm()
    if farmRunning then return true end

    setStatus("Loading...")

    local joined, joinErr = joinOfficeTeam()
    if not joined then
        setStatus(joinErr or "Could not join office team")
        return false
    end

    local waitStarted = os.clock()
    repeat
        task.wait(0.5)
    until (
        Player.Character
        and Player.Character:FindFirstChild("HumanoidRootPart")
        and Player.Character:FindFirstChild("Humanoid")
    ) or os.clock() - waitStarted > 15

    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") or not Player.Character:FindFirstChild("Humanoid") then
        setStatus("Character not ready")
        return false
    end

    local ok, err = ensureRemotes()
    if not ok then
        setStatus(err or "Remote setup failed")
        return false
    end

    active = true
    farmRunning = true
    officeAutoRejoinStarted = false
    questionsAnswered = 0
    printersCompleted = 0
    pendingPrint = nil
    currentSeat = nil
    unseatedSince = 0
    lastReseatAttemptAt = 0
    printerVerifyName = nil
    printerVerifyStartedAt = 0
    printerVerifyQuestionCount = 0
    lastAnswerAt = 0
    sessionStartTime = os.time()
    sessionStartMoney = getMoney()
    startTime = os.time()
    startMoney = sessionStartMoney

    vQuestions.Text = "0"
    vPrinters.Text = "0"
    setStatus("Running")

    hookOfficeRemotes()
    task.spawn(mainFarmLoop)
    return true
end

table.insert(connections, Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end))

vStatus.Text = "Auto starting..."

task.spawn(function()
    while Gui.Parent do
        task.wait(0.5)

        local money = getMoney()
        local sessionElapsed = sessionStartTime and (os.time() - sessionStartTime) or 0
        local sessionEarned = sessionStartMoney and math.max(0, money - sessionStartMoney) or 0
        local currentEarned = startMoney and math.max(0, money - startMoney) or 0
        local moneyPerHour = sessionElapsed > 60 and math.floor((sessionEarned / sessionElapsed) * 3600) or 0

        vCurrent.Text = "Rp. " .. formatNumber(money)
        vEarned.Text = "Rp. " .. formatNumber(currentEarned)
        vMoneyHour.Text = sessionElapsed > 60 and ("Rp. " .. formatNumber(moneyPerHour) .. " /hr") or "Calculating..."

        vTotalEarned.Text = "Rp. " .. formatNumber(totalEarned + sessionEarned)
        vTotalTime.Text = formatTime(totalTime + sessionElapsed)

        if farmRunning and sessionElapsed > 0 and sessionElapsed % 30 < 1 then
            saveCurrentTotals()
        end

        if farmRunning then
            sendWebhook()
        end

        if farmRunning and not officeAutoRejoinStarted and sessionElapsed >= AUTO_REJOIN_SECONDS then
            officeAutoRejoinStarted = true
            task.spawn(autoRejoinOffice)
        end
    end
end)

local function cleanup()
    if farmRunning then
        pcall(stopFarm)
    else
        saveCurrentTotals()
    end

    active = false
    farmRunning = false
    releaseSprint()
    setSeatBlocking(false)

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if Gui and Gui.Parent then
        Gui:Destroy()
    end
end

if getgenv then
    getgenv().NZNT_OFFICE_STOP = cleanup
end

if getgenv and getgenv().NZNT_OFFICE_AUTO_START then
    getgenv().NZNT_OFFICE_AUTO_START = false
end

task.delay(2, function()
    if startFarm and not farmRunning then
        local ok = startFarm()
        if not ok then
            setStatus("Auto start failed")
        end
    end
end)

print("[Office Farm] UI loaded. Auto start ready.")
