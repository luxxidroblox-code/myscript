-- ============================================
-- STEALTH FARM PREMIUM - All Vehicles Support
-- Creator: _nznt
-- Discord: discord.gg/q6dUF4CsKH
-- ============================================
-- PREMIUM FEATURES:
-- - All Vehicles Support (Auto-detect & Respawn)
-- - Auto-Recovery System (Void/Death Protection)
-- - Baseplate Protection (No deletion bug)
-- - Anti-AFK System
-- - Advanced Statistics
-- - Smart Vehicle Detection
-- ============================================

-- Lightweight Adonis bypass
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
if c ~= "_" then end
return true
end)
table.insert(h, x)
end
if rawget(v, "Variables") and rawget(v, "Process") and typeof(b) == "function" and not y then
y = b
local o; o = hookfunction(y, function(f) end)
table.insert(h, y)
end
end
end
setthreadidentity(7)

if not game:IsLoaded() then game.Loaded:Wait() end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local RS               = game:GetService("ReplicatedStorage")
local VIM              = game:GetService("VirtualInputManager")
local Player           = Players.LocalPlayer

local SPEED             = 242
local MIN_SPEED         = 0
local MAX_SPEED         = 400
local GROUND_OFFSET     = 1.5
local MIN_OFFSET        = 0.5
local MAX_OFFSET        = 10.0
local CHECK_DISTANCE    = 15
local HUGE_PLATFORM_SIZE= 2000
local FARM_THRESHOLD    = 1000000
local DEFAULT_THRESHOLD = 1000000
local MIN_THRESHOLD     = 100000
local MAX_THRESHOLD     = 2500000

local active          = false
local currentVehicle  = nil
local currentVehicleId = "Yamahax-MioSporty" -- PREMIUM: Stores current vehicle type
local force           = nil
local gyro            = nil
local attachment      = nil
local direction       = 1
local savedFloor      = nil
local startTime       = os.time()
local startMoney      = nil
local lastDirChange   = 0
local DIR_COOLDOWN    = 0.3
local isRespawning    = false
local isRestarting    = false
local totalEarned     = 0
local totalTime       = 0

local function getExecutorName()
    if identifyexecutor then local ok, n = pcall(identifyexecutor) if ok and n then return n end end
    if getexecutorname  then local ok, n = pcall(getexecutorname)  if ok and n then return n end end
    return "Unknown"
end
local EXECUTOR_NAME = getExecutorName()

local lastFPS = 60
RunService.Heartbeat:Connect(function(dt)
    if dt > 0 then lastFPS = math.floor(1/dt) end
end)

local function getMoney()
    local pd = Player:FindFirstChild("PlayerData")
    if pd then local rp = pd:FindFirstChild("RPValue") if rp then return rp.Value end end
    return 0
end
local function formatNumber(n)
    local s = tostring(math.floor(n))
    return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end
local function formatTime(t)
    return string.format("%02d:%02d:%02d", math.floor(t/3600)%24, math.floor(t/60)%60, t%60)
end
local function getPing()
    local ok, ping = pcall(function() return Player:GetNetworkPing() end)
    return ok and math.floor(ping*1000) or 0
end

-- ============================================
-- PREMIUM: Universal Vehicle Spawn Function
-- Supports ALL vehicles in the game
-- ============================================
local function spawnVehicle(vehicleId)
    vehicleId = vehicleId or currentVehicleId or "Yamahax-MioSporty"
    local sf = RS:FindFirstChild("SpawnCarEvents")
    if sf then
        local r = sf:FindFirstChild("SpawnCar")
        if r then 
            r:FireServer(vehicleId) 
            currentVehicleId = vehicleId
            return true 
        end
    end
    return false
end

-- ============================================
-- PREMIUM: Auto-Detect Current Vehicle
-- Detects what vehicle player is currently using
-- ============================================
local function detectCurrentVehicle()
    local char = Player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local seat = hum.SeatPart
    if seat then
        local vehicle = seat.Parent
        if vehicle then
            currentVehicle = vehicle
            -- Try to identify vehicle type from model name
            local vehicleName = vehicle.Name
            -- Map common names to spawn IDs (extend as needed)
            local vehicleMap = {
                ["Mio"] = "Yamahax-MioSporty",
                ["MioSporty"] = "Yamahax-MioSporty",
                ["Yamaha"] = "Yamahax-MioSporty",
                ["Sporty"] = "Yamahax-MioSporty",
                -- Add more vehicles here
            }
            for name, id in pairs(vehicleMap) do
                if vehicleName:find(name) then
                    currentVehicleId = id
                    break
                end
            end
            return vehicle
        end
    end
    return nil
end

-- =====================
-- UI
-- =====================
local ScreenGui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
ScreenGui.Name = "nznt_StealthUI_Premium"
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.Visible = true
MainFrame.ZIndex = 1
MainFrame.BorderSizePixel = 0

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 2

local TopTitle = Instance.new("TextLabel", TopBar)
TopTitle.Size = UDim2.new(1, -120, 1, 0)
TopTitle.Position = UDim2.new(0, 14, 0, 0)
TopTitle.BackgroundTransparency = 1
TopTitle.Text = "STEALTH FARM PREMIUM  ·  nznt_"
TopTitle.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color for premium
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

hideBtn.MouseButton1Click:Connect(function()
    ScrollFrame.Visible = not ScrollFrame.Visible
    local t = ScrollFrame.Visible and 0 or 1
    MainFrame.BackgroundTransparency = t
    TopBar.BackgroundTransparency = t
    TopTitle.TextTransparency = t
    hideBtn.Text = ScrollFrame.Visible and "HIDE" or "SHOW"
end)

local ListLayout = Instance.new("UIListLayout", ScrollFrame)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 1)
Instance.new("UIPadding", ScrollFrame).PaddingBottom = UDim.new(0, 10)

local function makeSection(title, order)
    local sec = Instance.new("Frame", ScrollFrame)
    sec.Size = UDim2.new(1, 0, 0, 28) sec.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
    sec.BorderSizePixel = 0 sec.ZIndex = 3 sec.LayoutOrder = order
    local lbl = Instance.new("TextLabel", sec)
    lbl.Size = UDim2.new(1, -14, 1, 0) lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1 lbl.Text = title:upper()
    lbl.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold for premium
    lbl.Font = Enum.Font.GothamBold lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left lbl.ZIndex = 4
end

local function makeRow(icon, label, valueDefault, order)
    local row = Instance.new("Frame", ScrollFrame)
    row.Size = UDim2.new(1, 0, 0, 38) row.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    row.BorderSizePixel = 0 row.ZIndex = 3 row.LayoutOrder = order
    local iL = Instance.new("TextLabel", row)
    iL.Size = UDim2.new(0, 30, 1, 0) iL.Position = UDim2.new(0, 10, 0, 0)
    iL.BackgroundTransparency = 1 iL.Text = icon
    iL.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    iL.Font = Enum.Font.GothamBold iL.TextSize = 16 iL.ZIndex = 4
    local nL = Instance.new("TextLabel", row)
    nL.Size = UDim2.new(0.45, 0, 1, 0) nL.Position = UDim2.new(0, 44, 0, 0)
    nL.BackgroundTransparency = 1 nL.Text = label
    nL.TextColor3 = Color3.fromRGB(130, 130, 130)
    nL.Font = Enum.Font.Gotham nL.TextSize = 13
    nL.TextXAlignment = Enum.TextXAlignment.Left nL.ZIndex = 4
    local vL = Instance.new("TextLabel", row)
    vL.Size = UDim2.new(0.5, -14, 1, 0) vL.Position = UDim2.new(0.5, 0, 0, 0)
    vL.BackgroundTransparency = 1 vL.Text = valueDefault
    vL.TextColor3 = Color3.fromRGB(230, 230, 230)
    vL.Font = Enum.Font.GothamBold vL.TextSize = 13
    vL.TextXAlignment = Enum.TextXAlignment.Right vL.ZIndex = 4
    local sep = Instance.new("Frame", row)
    sep.Size = UDim2.new(1, -14, 0, 1) sep.Position = UDim2.new(0, 7, 1, -1)
    sep.BackgroundColor3 = Color3.fromRGB(28, 28, 28) sep.BorderSizePixel = 0 sep.ZIndex = 4
    return vL
end

local function makeSlider(icon, label, minV, maxV, curV, order, isFloat, onChange)
    local row = Instance.new("Frame", ScrollFrame)
    row.Size = UDim2.new(1, 0, 0, 70) row.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    row.BorderSizePixel = 0 row.ZIndex = 3 row.LayoutOrder = order
    local iL = Instance.new("TextLabel", row)
    iL.Size = UDim2.new(0,30,0,28) iL.Position=UDim2.new(0,10,0,5)
    iL.BackgroundTransparency=1 iL.Text=icon
    iL.TextColor3=Color3.fromRGB(255,215,0)
    iL.Font=Enum.Font.GothamBold iL.TextSize=16 iL.ZIndex=4
    local nL = Instance.new("TextLabel", row)
    nL.Size = UDim2.new(0.4,0,0,28) nL.Position=UDim2.new(0,44,0,5)
    nL.BackgroundTransparency=1 nL.Text=label
    nL.TextColor3=Color3.fromRGB(130,130,130)
    nL.Font=Enum.Font.Gotham nL.TextSize=13
    nL.TextXAlignment=Enum.TextXAlignment.Left nL.ZIndex=4
    local vL = Instance.new("TextLabel", row)
    vL.Size = UDim2.new(0.3,-14,0,28) vL.Position=UDim2.new(0.65,0,0,5)
    vL.BackgroundTransparency=1 vL.Text=tostring(curV)
    vL.TextColor3=Color3.fromRGB(230,230,230)
    vL.Font=Enum.Font.GothamBold vL.TextSize=13
    vL.TextXAlignment=Enum.TextXAlignment.Right vL.ZIndex=4
    local track = Instance.new("Frame", row)
    track.Size=UDim2.new(1,-60,0,6) track.Position=UDim2.new(0,44,0,45)
    track.BackgroundColor3=Color3.fromRGB(40,40,40) track.BorderSizePixel=0 track.ZIndex=4
    Instance.new("UICorner",track).CornerRadius=UDim.new(0,3)
    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3=Color3.fromRGB(255,215,0) fill.BorderSizePixel=0 fill.ZIndex=5
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,3)
    local knob = Instance.new("Frame", track)
    knob.Size=UDim2.new(0,18,0,18) knob.BackgroundColor3=Color3.fromRGB(255,255,255)
    knob.BorderSizePixel=0 knob.ZIndex=6
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local sep = Instance.new("Frame", row)
    sep.Size=UDim2.new(1,-14,0,1) sep.Position=UDim2.new(0,7,1,-1)
    sep.BackgroundColor3=Color3.fromRGB(28,28,28) sep.BorderSizePixel=0 sep.ZIndex=4
    local function refresh(v)
        local r=(v-minV)/(maxV-minV)
        fill.Size=UDim2.new(r,0,1,0)
        knob.Position=UDim2.new(r,-9,0.5,-9)
        vL.Text=tostring(v)
    end
    refresh(curV)
    local dragging=false
    knob.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local r=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local v = isFloat and (math.floor((minV+r*(maxV-minV))*10)/10) or math.floor(minV+r*(maxV-minV))
            refresh(v) onChange(v)
        end
    end)
end

makeSection("Money", 10)
local vCurrent   = makeRow("$",  "Current Money", "Rp. 0",          11)
local vEarned    = makeRow("↑",  "Earned",        "Rp. 0",          12)
local vMoneyHour = makeRow("⚡", "Money / Hour",  "Calculating...", 13)
makeSection("Total Stats", 15)
local vTotalEarned = makeRow("💰", "Total Earned", "Rp. " .. formatNumber(totalEarned), 16)
local vTotalTime   = makeRow("⏰", "Total Time",   formatTime(totalTime),               17)

local resetRow = Instance.new("Frame", ScrollFrame)
resetRow.Size = UDim2.new(1,0,0,50) resetRow.BackgroundColor3=Color3.fromRGB(16,16,16)
resetRow.BorderSizePixel=0 resetRow.ZIndex=3 resetRow.LayoutOrder=18
local resetBtn = Instance.new("TextButton", resetRow)
resetBtn.Size=UDim2.new(1,-20,0,32) resetBtn.Position=UDim2.new(0,10,0,9)
resetBtn.BackgroundColor3=Color3.fromRGB(200,50,50) resetBtn.TextColor3=Color3.fromRGB(255,255,255)
resetBtn.Font=Enum.Font.GothamBold resetBtn.TextSize=12
resetBtn.Text="🔄 Reset Total Stats" resetBtn.BorderSizePixel=0 resetBtn.ZIndex=4
Instance.new("UICorner",resetBtn).CornerRadius=UDim.new(0,5)
resetBtn.MouseButton1Click:Connect(function()
    totalEarned=0 totalTime=0
    vTotalEarned.Text="Rp. 0" vTotalTime.Text="00:00:00"
    resetBtn.Text="✓ Stats Reset!" resetBtn.BackgroundColor3=Color3.fromRGB(0,150,70)
    task.wait(2)
    resetBtn.Text="🔄 Reset Total Stats" resetBtn.BackgroundColor3=Color3.fromRGB(200,50,50)
end)

-- =====================
-- VEHICLE STATS SECTION
-- =====================
makeSection("Vehicle Stats", 18)

-- Vehicle display row
local vehicleRow = Instance.new("Frame", ScrollFrame)
vehicleRow.Size = UDim2.new(1,0,0,40) vehicleRow.BackgroundColor3 = Color3.fromRGB(20,20,20)
vehicleRow.BorderSizePixel = 0 vehicleRow.ZIndex = 3 vehicleRow.LayoutOrder = 18
Instance.new("UICorner", vehicleRow).CornerRadius = UDim.new(0,6)

local vehicleIcon = Instance.new("TextLabel", vehicleRow)
vehicleIcon.Size = UDim2.new(0,30,0,30) vehicleIcon.Position = UDim2.new(0,15,0.5,-15)
vehicleIcon.BackgroundTransparency = 1 vehicleIcon.Text = "🏍️"
vehicleIcon.Font = Enum.Font.GothamBold vehicleIcon.TextSize = 16 vehicleIcon.TextColor3 = Color3.fromRGB(255,215,0)
vehicleIcon.ZIndex = 4

local vehicleLabel = Instance.new("TextLabel", vehicleRow)
vehicleLabel.Size = UDim2.new(0,80,0,20) vehicleLabel.Position = UDim2.new(0,55,0,5)
vehicleLabel.BackgroundTransparency = 1 vehicleLabel.Text = "Vehicle:"
vehicleLabel.Font = Enum.Font.Gotham vehicleLabel.TextSize = 12 vehicleLabel.TextColor3 = Color3.fromRGB(180,180,180)
vehicleLabel.TextXAlignment = Enum.TextXAlignment.Left vehicleLabel.ZIndex = 4

local vehicleInput = Instance.new("TextBox", vehicleRow)
vehicleInput.Size = UDim2.new(0,200,0,28) vehicleInput.Position = UDim2.new(0,55,0,18)
vehicleInput.BackgroundColor3 = Color3.fromRGB(35,35,35) vehicleInput.BackgroundTransparency = 0
vehicleInput.TextColor3 = Color3.fromRGB(255,255,255) vehicleInput.PlaceholderText = "Enter vehicle name..."
vehicleInput.Font = Enum.Font.Gotham vehicleInput.TextSize = 13 vehicleInput.BorderSizePixel = 0
vehicleInput.ZIndex = 4
Instance.new("UICorner", vehicleInput).CornerRadius = UDim.new(0,4)
-- Add depth effect
local inputShadow = Instance.new("Frame", vehicleInput)
inputShadow.Size = UDim2.new(1,0,1,4) inputShadow.Position = UDim2.new(0,0,0,2)
inputShadow.BackgroundColor3 = Color3.fromRGB(0,0,0) inputShadow.BackgroundTransparency = 0.8
inputShadow.BorderSizePixel = 0 inputShadow.ZIndex = 3
Instance.new("UICorner", inputShadow).CornerRadius = UDim.new(0,4)

-- Start/Stop button
local toggleBtn = Instance.new("TextButton", vehicleRow)
toggleBtn.Size = UDim2.new(0,80,0,32) toggleBtn.Position = UDim2.new(1,-95,0.5,-16)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40) toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleBtn.Font = Enum.Font.GothamBold toggleBtn.TextSize = 12 toggleBtn.Text = "START"
toggleBtn.BorderSizePixel = 0 toggleBtn.ZIndex = 4
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,6)
-- Button depth effect
local btnShadow = Instance.new("Frame", toggleBtn)
btnShadow.Size = UDim2.new(1,0,1,4) btnShadow.Position = UDim2.new(0,0,0,2)
btnShadow.BackgroundColor3 = Color3.fromRGB(0,0,0) btnShadow.BackgroundTransparency = 0.6
btnShadow.BorderSizePixel = 0 btnShadow.ZIndex = 3
Instance.new("UICorner", btnShadow).CornerRadius = UDim.new(0,6)

-- Button functionality
local farmingStarted = false

toggleBtn.MouseButton1Click:Connect(function()
    if not farmingStarted then
        -- START FARMING
        local vehicleName = vehicleInput.Text
        if vehicleName == "" then
            toggleBtn.Text = "ENTER NAME"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)
            task.wait(1)
            toggleBtn.Text = "START"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
            return
        end
        
        toggleBtn.Text = "SPAWNING"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(150,100,0)
        
        -- Set vehicle and start farming
        currentVehicleId = vehicleName
        vVehicle.Text = vehicleName
        
        -- Start the farming process
        task.spawn(function()
            startFarming()
            if active then
                farmingStarted = true
                toggleBtn.Text = "STOP"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)
            else
                toggleBtn.Text = "START"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
            end
        end)
        
    else
        -- STOP FARMING
        toggleBtn.Text = "STOPPING"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
        
        active = false
        farmingStarted = false
        
        -- Clean up
        if force then force:Destroy() force = nil end
        if gyro then gyro:Destroy() gyro = nil end
        if attachment then attachment:Destroy() attachment = nil end
        
        vStatus.Text = "Stopped"
        toggleBtn.Text = "START"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    end
end)

makeSection("Vehicle Info", 19)
local vVehicle = makeRow("🏍️", "Vehicle", currentVehicleId or "Auto-Detect", 20)

makeSection("Stats", 21)
local vStatus  = makeRow("▶", "Status",  "Ready - Enter vehicle and press START", 22)
local vElapsed = makeRow("⏱", "Elapsed", "00:00:00",    23)
makeSection("Settings", 25)
makeSlider("⚡","Speed",MIN_SPEED,MAX_SPEED,SPEED,26,false,function(v) SPEED=v end)
makeSlider("↕","Ground Offset",MIN_OFFSET,MAX_OFFSET,GROUND_OFFSET,27,true,function(v) GROUND_OFFSET=v end)
makeSlider("💰","Farm Threshold",MIN_THRESHOLD,MAX_THRESHOLD,FARM_THRESHOLD,28,false,function(v) FARM_THRESHOLD=v end)
makeSection("Device", 30)
local vPing = makeRow("◉","Ping","0 ms",31)
local vFPS  = makeRow("◈","FPS","0",32)
local vExec = makeRow("⌘","Executor",EXECUTOR_NAME,33)
makeSection("About", 40)
local aboutRow = Instance.new("Frame", ScrollFrame)
aboutRow.Size=UDim2.new(1,0,0,100) aboutRow.BackgroundColor3=Color3.fromRGB(16,16,16)
aboutRow.BorderSizePixel=0 aboutRow.ZIndex=3 aboutRow.LayoutOrder=41
local snoopy = Instance.new("ImageLabel", aboutRow)
snoopy.Size=UDim2.new(0,80,0,80) snoopy.Position=UDim2.new(0,10,0.5,-40)
snoopy.BackgroundTransparency=1 snoopy.Image="rbxassetid://75353810328300" snoopy.ZIndex=4
local credit = Instance.new("TextLabel", aboutRow)
credit.Size=UDim2.new(1,-104,1,0) credit.Position=UDim2.new(0,100,0,0)
credit.BackgroundTransparency=1 credit.Text="PREMIUM SCRIPT\nMade by _nznt\nAll Vehicles Support"
credit.TextColor3=Color3.fromRGB(255,215,0) credit.Font=Enum.Font.Gotham
credit.TextSize=12 credit.TextXAlignment=Enum.TextXAlignment.Left
credit.TextYAlignment=Enum.TextYAlignment.Center credit.ZIndex=4 credit.TextWrapped=true
local discordRow = Instance.new("Frame", ScrollFrame)
discordRow.Size=UDim2.new(1,0,0,60) discordRow.BackgroundColor3=Color3.fromRGB(16,16,16)
discordRow.BorderSizePixel=0 discordRow.ZIndex=3 discordRow.LayoutOrder=42
local discordBtn = Instance.new("TextButton", discordRow)
discordBtn.Size=UDim2.new(1,-20,0,28) discordBtn.Position=UDim2.new(0,10,0,26)
discordBtn.BackgroundColor3=Color3.fromRGB(88,101,242) discordBtn.TextColor3=Color3.fromRGB(255,255,255)
discordBtn.Font=Enum.Font.GothamBold discordBtn.TextSize=12
discordBtn.Text="⎋  Join Discord — discord.gg/q6dUF4CsKH"
discordBtn.BorderSizePixel=0 discordBtn.ZIndex=4
Instance.new("UICorner",discordBtn).CornerRadius=UDim.new(0,5)
discordBtn.MouseButton1Click:Connect(function()
    setclipboard("https://discord.gg/q6dUF4CsKH")
    discordBtn.Text="✓  Copied!" discordBtn.BackgroundColor3=Color3.fromRGB(0,150,70)
    task.wait(2)
    discordBtn.Text="⎋  Join Discord — discord.gg/q6dUF4CsKH"
    discordBtn.BackgroundColor3=Color3.fromRGB(88,101,242)
end)

local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 24

-- =====================
-- PREMIUM: RESPAWN VEHICLE (All Vehicles Supported)
-- =====================
local function respawnVehicle(hum)
    if isRespawning then return end
    isRespawning = true
    active = false
    vStatus.Text = "Reached " .. formatNumber(FARM_THRESHOLD) .. "! Respawning vehicle..."

    -- Edge/void detection variables
    local lastVoidTime = 0
    local voidThreshold = 3 -- seconds

    -- Wait for safe position before jumping
    local safePos = false
    local maxWait = 10
    local waited = 0
    
    while not safePos and waited < maxWait do
        local seat = currentVehicle and currentVehicle:FindFirstChildWhichIsA("VehicleSeat")
        if seat then
            -- Check if we're close to edge
            local rayLeft = workspace:Raycast(seat.Position + Vector3.new(-CHECK_DISTANCE, 0, 0), Vector3.new(0, -30, 0))
            local rayRight = workspace:Raycast(seat.Position + Vector3.new(CHECK_DISTANCE, 0, 0), Vector3.new(0, -30, 0))
            local rayForward = workspace:Raycast(seat.Position + Vector3.new(0, 0, -CHECK_DISTANCE * direction), Vector3.new(0, -30, 0))
            local rayBack = workspace:Raycast(seat.Position + Vector3.new(0, 0, CHECK_DISTANCE * direction), Vector3.new(0, -30, 0))
            
            -- Safe if all directions have ground
            safePos = rayLeft and rayRight and rayForward and rayBack
        end
        
        if not safePos then
            task.wait(0.5)
            waited = waited + 0.5
        end
    end
    
    -- Jump out of vehicle using VIM
    local function sendKey(key)
        game:GetService("VirtualInputManager"):SendKeyEvent(true, key, false, game)
        task.wait(0.1)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, key, false, game)
    end
    
    sendKey(Enum.KeyCode.Space)
    task.wait(0.5)

    -- Destroy old force/gyro
    if force      then force:Destroy()      force      = nil end
    if gyro       then gyro:Destroy()       gyro       = nil end
    if attachment then attachment:Destroy() attachment = nil end

    -- Despawn old vehicle
    local despawnFolder = RS:FindFirstChild("SpawnCarEvents")
    if despawnFolder then
        local despawnRemote = despawnFolder:FindFirstChild("DespawnCar")
        if despawnRemote then despawnRemote:FireServer() end
    end
    task.wait(2)

    -- Spawn SAME vehicle type (Premium feature)
    spawnVehicle(currentVehicleId)
    task.wait(2)

    -- Find new seat and teleport to it
    local newSeat = nil
    local char = Player.Character or Player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    
    -- Wait a bit for our vehicle to spawn
    task.wait(1)
    
    -- Find the closest seat to our position (should be our vehicle)
    local closestSeat = nil
    local closestDistance = math.huge
    local _ws = workspace:GetChildren()
    for i = 1, #_ws do
        local obj = _ws[i]
        local found = obj:FindFirstChildWhichIsA("VehicleSeat", true)
        if found then 
            local distance = (root.Position - found.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestSeat = found
            end
        end
    end
    _ws = nil
    
    if closestSeat then
        newSeat = closestSeat
        root.CFrame = closestSeat.CFrame * CFrame.new(0, 2, 0)
    end

    if not newSeat then
        vStatus.Text = "No new seat found! Retrying..."
        task.wait(2)
        
        -- Retry spawn
        spawnVehicle(currentVehicleId)
        task.wait(2)
        
        -- Retry finding seat
        local retrySeat = nil
        local closestRetrySeat = nil
        local closestRetryDistance = math.huge
        local _ws2 = workspace:GetChildren()
        for i = 1, #_ws2 do
            local obj = _ws2[i]
            local found = obj:FindFirstChildWhichIsA("VehicleSeat", true)
            if found then 
                local distance = (root.Position - found.Position).Magnitude
                if distance < closestRetryDistance then
                    closestRetryDistance = distance
                    closestRetrySeat = found
                end
            end
        end
        _ws2 = nil
        
        if closestRetrySeat then
            retrySeat = closestRetrySeat
            root.CFrame = closestRetrySeat.CFrame * CFrame.new(0, 2, 0)
        end
        
        if not retrySeat then
            vStatus.Text = "Failed to respawn! Manual restart needed."
            isRespawning = false
            return
        end
        
        newSeat = retrySeat
        vStatus.Text = "Found seat on retry!"
    end

    task.wait(1)

    -- Try to sit with retry logic
    local maxRetries = 3
    local retryCount = 0
    local seated = false
    
    while retryCount < maxRetries and not seated do
        -- Check if player is dead/respawned
        local char = Player.Character or Player.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid")
        local root = char:WaitForChild("HumanoidRootPart")
        
        -- Teleport to seat if not close enough
        if (root.Position - newSeat.Position).Magnitude > 10 then
            root.CFrame = newSeat.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.5)
        end
        
        -- Try to sit
        newSeat:Sit(hum)
        task.wait(1)
        
        -- Check if successfully seated
        if hum.SeatPart == newSeat then
            seated = true
            vStatus.Text = "Successfully seated!"
        else
            retryCount = retryCount + 1
            vStatus.Text = "Seat attempt " .. retryCount .. "/" .. maxRetries
            
            if retryCount < maxRetries then
                task.wait(1)
            end
        end
    end
    
    if not seated then
        vStatus.Text = "Failed to sit! Manual restart needed."
        isRespawning = false
        return
    end

    currentVehicle = newSeat.Parent
    -- Add current session to totals before resetting
    if startMoney then
        local sessionEarned = getMoney() - startMoney
        local sessionTime = os.time() - startTime
        totalEarned = totalEarned + sessionEarned
        totalTime = totalTime + sessionTime
    end
    -- Reset session earnings for new vehicle, but preserve total earned
    startMoney = getMoney()
    startTime = os.time()

    -- Update vehicle info display
    if currentVehicle then
        vVehicle.Text = currentVehicle.Name .. " (" .. (currentVehicleId or "Unknown") .. ")"
    end

    attachment = Instance.new("Attachment", newSeat)
    force = Instance.new("LinearVelocity", newSeat)
    force.MaxForce = 99999999
    force.Attachment0 = attachment
    force.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    gyro = Instance.new("BodyGyro", newSeat)
    gyro.MaxTorque = Vector3.new(1e6, 0, 1e6)
    gyro.P = 5000
    gyro.CFrame = newSeat.CFrame

    active       = true
    isRespawning = false
    vStatus.Text = "Farming!"
end

-- =====================
-- PREMIUM: START FARMING
-- =====================
local function startFarming()
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hum  = char:WaitForChild("Humanoid")
    local root = char:WaitForChild("HumanoidRootPart")

    vStatus.Text = "Joining game..."
    local lce = RS:FindFirstChild("LoadCharacterEvent")
    if lce then
        lce:FireServer()
        char = Player.CharacterAdded:Wait()
        hum  = char:WaitForChild("Humanoid")
        root = char:WaitForChild("HumanoidRootPart")
        task.wait(1)
    end

    -- Drill down to the huge platform
    vStatus.Text = "Loading Script..."
    local searching = true
    while searching do
        local result = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0))
        if result and result.Instance then
            local part = result.Instance
            if part.Size.X >= HUGE_PLATFORM_SIZE or part.Name == "THE_SACRED_FLOOR" then
                -- PREMIUM: Protect baseplate from deletion
                savedFloor = part
                savedFloor.Name = "THE_SACRED_FLOOR"
                savedFloor.Parent = workspace
                -- Anchor it to prevent physics issues
                savedFloor.Anchored = true
                searching = false
            else
                part:Destroy()
                task.wait(0.02)
            end
        else
            searching = false
        end
    end

    -- PREMIUM: Better cleanup that protects the sacred floor
    for _, obj in pairs(workspace:GetChildren()) do
        if obj ~= workspace.CurrentCamera and obj ~= char then
            -- Check if it's the sacred floor by name (more reliable than reference)
            if obj.Name == "THE_SACRED_FLOOR" then
                -- Keep it
            elseif obj ~= savedFloor and not obj:IsA("Terrain") then
                obj:Destroy()
            end
        end
    end

    spawnVehicle(currentVehicleId)
    task.wait(5)

    vStatus.Text = "Finding vehicle..."
    local seat = nil
    repeat
        task.wait(0.5)
        local _ws = workspace:GetChildren()
        for i = 1, #_ws do
            local found = _ws[i]:FindFirstChildWhichIsA("VehicleSeat", true)
            if found then seat = found break end
        end
        _ws = nil
    until seat ~= nil

    vStatus.Text = "Sitting on vehicle..."
    task.wait(3)
    seat:Sit(hum)
    task.wait(0.5)

    -- Detect and store vehicle info
    currentVehicle = seat.Parent
    detectCurrentVehicle()
    if currentVehicle then
        vVehicle.Text = currentVehicle.Name .. " (" .. (currentVehicleId or "Auto") .. ")"
    end

    blur:Destroy()
    -- Reset session earnings for new vehicle
    startMoney = getMoney()
    startTime = os.time()
    active = true

    attachment = Instance.new("Attachment", seat)
    force = Instance.new("LinearVelocity", seat)
    force.MaxForce = 99999999
    force.Attachment0 = attachment
    force.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    gyro = Instance.new("BodyGyro", seat)
    gyro.MaxTorque = Vector3.new(1e6, 0, 1e6)

    -- Store hum ref for respawn
    coroutine.wrap(function()
        while true do
            task.wait(1)
            if active and not isRespawning and startMoney then
                local earned = getMoney() - startMoney
                if earned >= FARM_THRESHOLD then
                    respawnVehicle(hum)
                end
            end
        end
    end)()
end

-- Don't auto-start farming - wait for user to press START button
vStatus.Text = "Ready - Enter vehicle and press START"

-- =====================
-- PREMIUM: RESPAWN DETECTION
-- =====================
local isRestarting = false
Player.CharacterAdded:Connect(function()
    if isRestarting then return end
    isRestarting = true
    
    active = false
    isRespawning = false
    task.wait(2)
    startFarming()
    
    isRestarting = false
end)

-- =====================
-- STATS LOOP
-- =====================
coroutine.wrap(function()
    while task.wait(0.5) do
        if not active then continue end
        local elapsed = os.time() - startTime
        local money   = getMoney()
        local earned  = startMoney and (money - startMoney) or 0
        local mph     = elapsed > 0 and math.floor((earned/elapsed)*3600) or 0

        vCurrent.Text   = "Rp. " .. formatNumber(money)
        vEarned.Text    = "Rp. " .. formatNumber(math.max(0, earned))
        vMoneyHour.Text = elapsed > 10 and ("Rp. " .. formatNumber(mph) .. " /hr") or "Calculating..."
        vElapsed.Text   = formatTime(elapsed)
        vPing.Text      = getPing() .. " ms"
        vFPS.Text       = tostring(lastFPS)

        local ct  = totalEarned + earned
        local ctt = totalTime   + elapsed
        vTotalEarned.Text = "Rp. " .. formatNumber(ct)
        vTotalTime.Text   = formatTime(ctt)
    end
end)()

-- =====================
-- PREMIUM: ANTI-AFK SYSTEM
-- =====================
local VirtualInputManager = game:GetService("VirtualInputManager")
local lastActivity = tick()

coroutine.wrap(function()
    while task.wait(30) do
        if not active then continue end
        
        local now = tick()
        if now - lastActivity >= 120 then -- 2 minutes
            local keys = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D}
            local randomKey = keys[math.random(#keys)]
            
            VirtualInputManager:SendKeyEvent(true, randomKey, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, randomKey, false, game)
            
            lastActivity = now
        end
    end
end)()

-- =====================
-- PREMIUM: HEARTBEAT FARM
-- =====================
local lastVoidTime = 0
local voidThreshold = 2

RunService.Heartbeat:Connect(function()
    if not active or not force or not currentVehicle then return end
    local seat = currentVehicle:FindFirstChildWhichIsA("VehicleSeat")
    if not seat then return end

    -- Edge/void detection
    local groundRay = workspace:Raycast(seat.Position, Vector3.new(0, -100, 0))
    if not groundRay then
        -- We're in the void!
        local now = tick()
        if lastVoidTime == 0 then
            lastVoidTime = now
            vStatus.Text = "Void detected! " .. math.floor(voidThreshold - (now - lastVoidTime)) .. "s to reset..."
        elseif now - lastVoidTime >= voidThreshold then
            -- Force jump out after 2 seconds in void
            vStatus.Text = "Jumping out of void!"
            local function sendKey(key)
                game:GetService("VirtualInputManager"):SendKeyEvent(true, key, false, game)
                task.wait(0.1)
                game:GetService("VirtualInputManager"):SendKeyEvent(false, key, false, game)
            end
            sendKey(Enum.KeyCode.Space)
            lastVoidTime = 0
        end
    else
        -- Reset void timer when on ground
        if lastVoidTime > 0 then
            lastVoidTime = 0
            vStatus.Text = "Farming!"
        end
        
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

-- ============================================
-- PREMIUM SCRIPT END
-- ============================================