local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DELAY_WARN_SECONDS = 3

local function isWeirdName(name)
	if #name <= 2 then return true end
	if name:match("%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x") then return true end
	local vowels, letters = 0, 0
	for c in name:gmatch("[%a]") do
		letters += 1
		if c:match("[aeiouAEIOU]") then vowels += 1 end
	end
	if letters >= 5 and vowels == 0 then return true end
	local digits = 0
	for _ in name:gmatch("%d") do digits += 1 end
	if digits >= 4 and #name >= 6 then return true end
	if #name > 12 and name:lower() == name and not name:match("[aeiou]") then return true end
	return false
end

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RemoteAnomalyV2"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 340)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -170)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ Remote Anomaly Scanner v2 — Live"
titleLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.Parent = titleBar

local pulseDot = Instance.new("Frame")
pulseDot.Size = UDim2.new(0, 8, 0, 8)
pulseDot.Position = UDim2.new(1, -18, 0.5, -4)
pulseDot.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
pulseDot.BorderSizePixel = 0
pulseDot.Parent = titleBar
Instance.new("UICorner", pulseDot).CornerRadius = UDim.new(1, 0)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 38)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "listening for new remotes..."
statusLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.Parent = mainFrame

local counterLabel = Instance.new("TextLabel")
counterLabel.Size = UDim2.new(0, 120, 0, 20)
counterLabel.Position = UDim2.new(1, -130, 0, 38)
counterLabel.BackgroundTransparency = 1
counterLabel.Text = "caught: 0"
counterLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
counterLabel.TextXAlignment = Enum.TextXAlignment.Right
counterLabel.Font = Enum.Font.GothamBold
counterLabel.TextSize = 11
counterLabel.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -12, 1, -68)
scrollFrame.Position = UDim2.new(0, 6, 0, 62)
scrollFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(220, 80, 80)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame
Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 6)

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 3)
listLayout.Parent = scrollFrame

local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 4)
listPad.PaddingLeft = UDim.new(0, 4)
listPad.PaddingRight = UDim.new(0, 4)
listPad.Parent = scrollFrame

-- Drag
local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- Pulse
task.spawn(function()
	while true do
		for i = 1, 6 do pulseDot.BackgroundTransparency = i / 6 task.wait(0.12) end
		for i = 6, 1, -1 do pulseDot.BackgroundTransparency = i / 6 task.wait(0.12) end
	end
end)

-- Copy feedback: briefly changes button text to "✓"
local function flashCopied(btn)
	local prev = btn.Text
	btn.Text = "✓"
	btn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
	task.delay(1, function()
		if btn and btn.Parent then
			btn.Text = prev
			btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
		end
	end)
end

-- Build clipboard string for a remote
-- format: game:GetService("ReplicatedStorage"):WaitForChild("RemoteName")
local function buildClipboard(remote, source)
	local service = source == "RS" and "ReplicatedStorage" or "Workspace"
	-- walk up the path from remote to the container
	local path = {}
	local current = remote
	local root = source == "RS" and ReplicatedStorage or workspace
	while current and current ~= root do
		table.insert(path, 1, current.Name)
		current = current.Parent
	end
	-- build chain
	local chain = string.format('game:GetService("%s")', service)
	for _, part in ipairs(path) do
		chain = chain .. string.format(':WaitForChild("%s")', part)
	end
	return chain
end

-- Entry
local caughtCount = 0

local function makeEntry(remote, source, tag, tagColor, timestamp)
	caughtCount += 1
	counterLabel.Text = "caught: " .. caughtCount

	local name = remote.Name
	local clipText = buildClipboard(remote, source)

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
	row.BorderSizePixel = 0
	row.LayoutOrder = caughtCount
	row.Parent = scrollFrame
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

	task.delay(0.35, function()
		if row and row.Parent then
			row.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
		end
	end)

	-- remote name
	local nameText = Instance.new("TextLabel")
	nameText.Size = UDim2.new(0.5, 0, 0.5, 0)
	nameText.Position = UDim2.new(0, 8, 0, 2)
	nameText.BackgroundTransparency = 1
	nameText.Text = name
	nameText.TextColor3 = Color3.fromRGB(210, 210, 220)
	nameText.TextXAlignment = Enum.TextXAlignment.Left
	nameText.Font = Enum.Font.GothamMedium
	nameText.TextSize = 11
	nameText.TextTruncate = Enum.TextTruncate.AtEnd
	nameText.Parent = row

	-- timestamp + source
	local timeText = Instance.new("TextLabel")
	timeText.Size = UDim2.new(0.6, 0, 0.45, 0)
	timeText.Position = UDim2.new(0, 8, 0.52, 0)
	timeText.BackgroundTransparency = 1
	timeText.Text = timestamp .. " | " .. source
	timeText.TextColor3 = Color3.fromRGB(65, 65, 85)
	timeText.TextXAlignment = Enum.TextXAlignment.Left
	timeText.Font = Enum.Font.Gotham
	timeText.TextSize = 10
	timeText.Parent = row

	-- tag badge
	local tagLabel = Instance.new("TextLabel")
	tagLabel.Size = UDim2.new(0, 60, 0, 18)
	tagLabel.Position = UDim2.new(1, -136, 0.5, -9)
	tagLabel.BackgroundColor3 = tagColor
	tagLabel.BackgroundTransparency = 0.25
	tagLabel.Text = tag
	tagLabel.TextColor3 = Color3.new(1, 1, 1)
	tagLabel.Font = Enum.Font.GothamBold
	tagLabel.TextSize = 10
	tagLabel.Parent = row
	Instance.new("UICorner", tagLabel).CornerRadius = UDim.new(0, 4)

	-- copy button
	local copyBtn = Instance.new("TextButton")
	copyBtn.Size = UDim2.new(0, 58, 0, 24)
	copyBtn.Position = UDim2.new(1, -70, 0.5, -12)
	copyBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	copyBtn.Text = "📋 copy"
	copyBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
	copyBtn.Font = Enum.Font.GothamMedium
	copyBtn.TextSize = 10
	copyBtn.BorderSizePixel = 0
	copyBtn.Parent = row
	Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 5)

	copyBtn.MouseButton1Click:Connect(function()
		setclipboard(clipText)
		flashCopied(copyBtn)
		statusLabel.Text = "copied: " .. name
	end)

	-- touch support for mobile
	copyBtn.TouchTap:Connect(function()
		setclipboard(clipText)
		flashCopied(copyBtn)
		statusLabel.Text = "copied: " .. name
	end)

	task.defer(function()
		scrollFrame.CanvasPosition = Vector2.new(0, math.huge)
	end)
end

-- Hook logic
local hookedRemotes = {}
local watchedRemotes = {}

local function processRemote(remote, source)
	if hookedRemotes[remote] or watchedRemotes[remote] then return end
	local name = remote.Name
	local timestamp = os.date("%H:%M:%S")

	if isWeirdName(name) then
		hookedRemotes[remote] = true
		makeEntry(remote, source, "HOOKED", Color3.fromRGB(200, 50, 50), timestamp)
		statusLabel.Text = "hooked suspicious: " .. name

		remote.OnClientEvent:Connect(function(...)
			warn(string.format("[RAS] Blocked '%s' from %s | %d args", name, source, select("#", ...)))
			error("[RAS] Callback blocked — suspicious remote: " .. name, 2)
		end)
	else
		watchedRemotes[remote] = true
		makeEntry(remote, source, "WATCH", Color3.fromRGB(50, 110, 200), timestamp)

		local lastFire = nil
		remote.OnClientEvent:Connect(function()
			local now = tick()
			if lastFire then
				local delta = now - lastFire
				if delta >= DELAY_WARN_SECONDS then
					warn(string.format("[RAS] Delayed fire '%s' from %s — %.2fs", name, source, delta))
					statusLabel.Text = string.format("⚠ delay: %s (%.1fs)", name, delta)
				end
			end
			lastFire = now
		end)
	end
end

local function initialScan(container, label)
	for _, obj in ipairs(container:GetDescendants()) do
		if obj:IsA("RemoteEvent") then processRemote(obj, label) end
	end
end

local function attachWatcher(container, label)
	container.DescendantAdded:Connect(function(obj)
		if obj:IsA("RemoteEvent") then
			task.wait()
			processRemote(obj, label)
		end
	end)
end

task.defer(function()
	if not game:IsLoaded() then game.Loaded:Wait() end
	task.wait(0.5)
	initialScan(ReplicatedStorage, "RS")
	initialScan(workspace, "WS")
	attachWatcher(ReplicatedStorage, "RS")
	attachWatcher(workspace, "WS")
	statusLabel.Text = "live — waiting for remotes..."
end)