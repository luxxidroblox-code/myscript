--[[ LimeHub â€¢ RADEN BUILD â€¢ Grow a Garden 2 (Delta Android/iOS)
     STAGE 3 â€” Buy path-based PASTI (SeedShop/GearShop dari Scan) + Auto Buy Gears + tab Player (Custom Walk Speed)
     STAGE 2 â€” + Shop page: Auto Buy Seeds (Talk Sam -> Seed Shop) & Auto Sell (Talk Steven -> Sell Inventory!)
     STAGE 1 â€” Pondasi: Config + UI shell + Dashboard + Settings(FPSCap) + AutoHarvest (terbukti)
     Strategi (lihat LimeHub_DOCS.md Â§2): JANGAN lawan Packet/buffer. Micu mekanisme client:
       fireproximityprompt (harvest/steal), fire GUI button (buy/sell), teleport, require controller.
     Paste: host ke pastebin -> loadstring(game:HttpGet(".../raw/XXXX"))()  (anti-potong di HP). ]]

local OKK, EE = pcall(function()

--==================================================================================--
-- SERVICES & EXECUTOR CAPS
--==================================================================================--
local Players   = game:GetService("Players")
local SG        = game:GetService("StarterGui")
local UIS       = game:GetService("UserInputService")
local RunSvc    = game:GetService("RunService")
local WS        = workspace

local LP        = Players.LocalPlayer
local fpp       = fireproximityprompt
local setclip   = setclipboard or toclipboard or writeclipboard

local function toast(t, x)
	pcall(function() SG:SetCore("SendNotification", { Title = tostring(t), Text = tostring(x), Duration = 6 }) end)
end

--==================================================================================--
-- CONFIG  (mirror dari Raden.json â€” sumber kebenaran untuk semua modul/stage berikutnya)
-- Catatan: WEBHOOK SENGAJA DIKOSONGKAN. Token lama kamu sudah bocor -> bikin baru, tempel di sini.
--==================================================================================--
local CFG = {
	Dashboard = { Enabled = true, SyncConfig = true, GroupName = "Raden" },

	AutoHarvest = { Enabled = false, Mode = "All", Mutations = {}, MinWeight = 0 },

	AutoEquipPets = {
		Enabled = false, FillRemaining = false, EquipPets = {},
		Whitelist = { "Bee", "Black Dragon", "Golden Dragonfly", "Ice Serpent", "Raccoon", "Robin", "Unicorn", "Monkey" },
	},

	AutoGarden = {
		Enabled = false, PlotLimit = 100, PlantMode = "All", Whitelist = {},
		NeverPlant = { "Rainbow", "Gold" }, Sprinklers = false, Upgrade = false,
		KeepMutated = true, Purge = {}, PlantLimits = {},
	},

	AutoBuySeeds = {
		Enabled = false, Mode = "Selected",
		Seeds = { "Carrot", "Tulip", "Bamboo", "Corn", "Banana", "Coconut", "Glow Mushroom", "Grape", "Green Bean", "Mango", "Mushroom" },
	},

	AutoBuyGears = { Enabled = false, Mode = "All", Gears = {} },
	AutoBuySlot  = { Enabled = false },
	AutoBuyPets  = { Enabled = false, Pets = { "Monkey", "Unicorn", "Robin", "Raccoon", "Ice Serpent", "Golden Dragonfly", "Black Dragon", "Bee" } },

	AutoSell = {
		Enabled = false, Mode = "Inventory", Fruits = {}, BlacklistChecks = {},
		BlacklistMutations = { "Gold", "Rainbow" }, BlacklistMinWeight = 100, BlacklistMinSellPrice = 1000,
	},

	AutoEventSeeds = { Enabled = false, Types = { "Gold", "Rainbow" } },
	AutoMail       = { Enabled = false, ClaimMail = false, Recipients = {} },
	PetWebhook     = { Enabled = false, URL = "", Pets = {}, PingEveryone = false },

	Settings = { ShowOverlay = true, AutoCenter = false, FPSCap = 30 },
}

--==================================================================================--
-- THEME & UI HELPERS (konvensi LimeHub: nw/cor/st/grd)
--==================================================================================--
local C = {
	Bg = Color3.fromRGB(16,18,22), Bg2 = Color3.fromRGB(13,14,18), Card = Color3.fromRGB(28,32,39),
	Txt = Color3.fromRGB(235,240,246), Sub = Color3.fromRGB(140,148,160), Strk = Color3.fromRGB(48,53,64),
	A = Color3.fromRGB(95,225,160), B = Color3.fromRGB(58,190,210), Off = Color3.fromRGB(58,63,74),
	Bad = Color3.fromRGB(235,110,110),
}
local SEQ = ColorSequence.new(C.A, C.B)

local function fn(n, f) local a,b = pcall(function() return Enum.Font[n] end); return (a and b) or Enum.Font[f] end
local FB = fn("BuilderSansExtraBold","GothamBold")
local FM = fn("BuilderSansBold","GothamSemibold")
local FR = fn("BuilderSans","Gotham")

local function nw(c, p, k)
	local o = Instance.new(c)
	for a, b in pairs(p or {}) do o[a] = b end
	for _, x in ipairs(k or {}) do x.Parent = o end
	return o
end
local function cor(p, r) nw("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = p }) end
local function st(p, c, t) nw("UIStroke", { Color = c or C.Strk, Thickness = t or 1, Transparency = .4, Parent = p }) end
local function grd(p, r) nw("UIGradient", { Color = SEQ, Rotation = r or 0, Parent = p }) end

--==================================================================================--
-- ROOT GUI
--==================================================================================--
local par = (gethui and gethui()) or game:GetService("CoreGui")
if par:FindFirstChild("LimeRaden") then par.LimeRaden:Destroy() end
local G = nw("ScreenGui", { Name = "LimeRaden", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = par })

local W = nw("Frame", { AnchorPoint = Vector2.new(.5,.5), Position = UDim2.new(.5,0,.5,0), Size = UDim2.new(0,560,0,420), BackgroundColor3 = C.Bg, Parent = G })
cor(W, 14); st(W, C.Strk, 1.4)
nw("Frame", { Size = UDim2.new(1,-32,0,2), Position = UDim2.new(0,16,0,0), BackgroundColor3 = C.A, BorderSizePixel = 0, Parent = W })

-- HEADER
local HD = nw("Frame", { Size = UDim2.new(1,0,0,46), BackgroundTransparency = 1, Parent = W })
local lg = nw("Frame", { Size = UDim2.new(0,34,0,34), Position = UDim2.new(0,12,.5,-17), BackgroundColor3 = C.A, Parent = HD }); cor(lg,9); grd(lg,45)
nw("TextLabel", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "ðŸŒ±", TextSize = 18, Parent = lg })
nw("TextLabel", { Position = UDim2.new(0,56,0,6), Size = UDim2.new(.6,0,0,18), BackgroundTransparency = 1, Font = FB, Text = "LimeHub â€¢ Raden", TextColor3 = C.Txt, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = HD })
local subL = nw("TextLabel", { Position = UDim2.new(0,56,0,25), Size = UDim2.new(.6,0,0,14), BackgroundTransparency = 1, Font = FR, Text = (fpp and "ready âœ“" or "âš  no fireproximityprompt"), TextColor3 = (fpp and C.Sub or C.Bad), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = HD })

local function tbn(x, t) local b = nw("TextButton", { AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,x,.5,0), Size = UDim2.new(0,28,0,28), BackgroundColor3 = C.Card, Text = t, Font = FB, TextColor3 = C.Sub, TextSize = 14, Parent = HD }); cor(b,8); return b end
local clB, minB = tbn(-12,"âœ•"), tbn(-46,"â€”")

-- BODY: SIDEBAR + CONTENT
local SIDE = nw("Frame", { Position = UDim2.new(0,12,0,52), Size = UDim2.new(0,150,1,-64), BackgroundColor3 = C.Bg2, Parent = W }); cor(SIDE,12); st(SIDE,C.Strk,1)
nw("UIListLayout", { Padding = UDim.new(0,4), Parent = SIDE, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center })
nw("UIPadding", { PaddingTop = UDim.new(0,6), Parent = SIDE })

local CONT = nw("Frame", { Position = UDim2.new(0,172,0,52), Size = UDim2.new(1,-184,1,-64), BackgroundTransparency = 1, Parent = W })

local Pages, tabBtns = {}, {}
local function newPage(name)
	local p = nw("ScrollingFrame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.A, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = CONT })
	nw("UIListLayout", { Padding = UDim.new(0,8), Parent = p })
	Pages[name] = p
	return p
end
local function showPage(name)
	for n, p in pairs(Pages) do p.Visible = (n == name) end
	for n, b in pairs(tabBtns) do
		b.BackgroundColor3 = (n == name) and C.Card or C.Bg2
		b.TextColor3 = (n == name) and C.Txt or C.Sub
	end
end
local function tab(name, icon)
	local b = nw("TextButton", { Size = UDim2.new(1,-12,0,30), BackgroundColor3 = C.Bg2, Text = "  "..icon.." "..name, Font = FM, TextColor3 = C.Sub, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = SIDE }); cor(b,8)
	tabBtns[name] = b
	newPage(name)
	b.MouseButton1Click:Connect(function() showPage(name) end)
	return b
end

--==================================================================================--
-- CARD / CONTROL HELPERS (per-page)
--==================================================================================--
local function card(page, h) local r = nw("Frame", { Size = UDim2.new(1,0,0,h or 56), BackgroundColor3 = C.Card, Parent = page }); cor(r,12); st(r,C.Strk,1); return r end
local function lbl(r, t, d)
	nw("TextLabel", { Position = UDim2.new(0,14,0,d and 9 or 0), Size = UDim2.new(.62,0,0,d and 17 or 56), BackgroundTransparency = 1, Font = FM, Text = t, TextColor3 = C.Txt, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = d and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center, Parent = r })
	if d then nw("TextLabel", { Position = UDim2.new(0,14,0,29), Size = UDim2.new(.66,0,0,15), BackgroundTransparency = 1, Font = FR, Text = d, TextColor3 = C.Sub, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = r }) end
end
-- toggle: cb(state) dipanggil saat klik. initial = nilai awal dari CFG.
local function toggle(page, t, d, initial, cb)
	local r = card(page); lbl(r, t, d)
	local tr = nw("TextButton", { AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-14,.5,0), Size = UDim2.new(0,46,0,24), BackgroundColor3 = initial and C.A or C.Off, Text = "", AutoButtonColor = false, Parent = r }); cor(tr,12)
	local kn = nw("Frame", { AnchorPoint = Vector2.new(0,.5), Position = initial and UDim2.new(1,-21,.5,0) or UDim2.new(0,3,.5,0), Size = UDim2.new(0,18,0,18), BackgroundColor3 = Color3.new(1,1,1), Parent = tr }); cor(kn,9)
	local s = initial and true or false
	tr.MouseButton1Click:Connect(function()
		s = not s
		tr.BackgroundColor3 = s and C.A or C.Off
		kn.Position = s and UDim2.new(1,-21,.5,0) or UDim2.new(0,3,.5,0)
		pcall(cb, s)
	end)
	return r
end
local function button(page, t, d, bt, cb)
	local r = card(page); lbl(r, t, d)
	local b = nw("TextButton", { AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-14,.5,0), Size = UDim2.new(0,100,0,30), BackgroundColor3 = C.A, Text = bt, Font = FB, TextColor3 = Color3.fromRGB(16,22,18), TextSize = 13, Parent = r }); cor(b,8); grd(b,20)
	b.MouseButton1Click:Connect(function() pcall(cb) end)
	return r, b
end

--==================================================================================--
-- ENGINE: PROMPTS (terbukti â€” LimeHub_DOCS.md Â§2/Â§3)
--==================================================================================--
local function firePrompts(words)
	if not fpp then return 0 end
	local n = 0
	for _, v in ipairs(WS:GetDescendants()) do
		if v:IsA("ProximityPrompt") and v.Enabled then
			local a = ((v.ActionText or "").." "..(v.ObjectText or "")):lower()
			for _, w in ipairs(words) do
				if a:find(w, 1, true) then pcall(fpp, v); n = n + 1; break end
			end
		end
	end
	return n
end

--==================================================================================--
-- ENGINE: GUI BUTTONS (best-effort â€” LimeHub_DOCS.md Â§2/Â§9: fire GUI button)
--==================================================================================--
local PlayerGui = LP:WaitForChild("PlayerGui")

-- klik 1 GuiButton se-robust mungkin (getconnections + firesignal)
local function clickBtn(b)
	if not b then return false end
	local fired = false
	local sigs = {}
	pcall(function() sigs[#sigs+1] = b.MouseButton1Click end)
	pcall(function() sigs[#sigs+1] = b.MouseButton1Down end)
	pcall(function() sigs[#sigs+1] = b.Activated end)
	if getconnections then
		for _, sig in ipairs(sigs) do
			pcall(function()
				for _, c in ipairs(getconnections(sig)) do
					if c.Fire then c:Fire(); fired = true
					elseif c.Function then c.Function(); fired = true end
				end
			end)
		end
	end
	if firesignal then pcall(function() firesignal(b.MouseButton1Click); fired = true end) end
	return fired
end

-- cari GuiButton yg teks/namanya cocok salah satu keyword
local function findButtons(words, root)
	root = root or PlayerGui
	local out = {}
	for _, v in ipairs(root:GetDescendants()) do
		if v:IsA("TextButton") or v:IsA("ImageButton") then
			local t = ((v:IsA("TextButton") and v.Text or "").." "..v.Name):lower()
			for _, w in ipairs(words) do if t:find(w:lower(), 1, true) then out[#out+1] = v; break end end
		end
	end
	return out
end

-- fire ProximityPrompt yg ActionText/ObjectText cocok (mis. Talk ke Sam/Steven)
local function firePromptMatch(actionWord, objectWord)
	if not fpp then return false end
	local hit = false
	for _, v in ipairs(WS:GetDescendants()) do
		if v:IsA("ProximityPrompt") and v.Enabled then
			local okA = (not actionWord) or (v.ActionText or ""):lower():find(actionWord:lower(), 1, true)
			local okO = (not objectWord) or (v.ObjectText or ""):lower():find(objectWord:lower(), 1, true)
			if okA and okO then pcall(fpp, v); hit = true end
		end
	end
	return hit
end

-- PATH PASTI (hasil Scan Buttons):
--   SeedShop.Frame.NormalShop.<Seed>.Main_Frame.TextButton
--   GearShop.Frame.ScrollingFrame.<Gear>.Main_Frame.TextButton
local SHOP_SKIP = { ItemTemplate = true, Robux_Shelf = true, Sheckles_Shelf = true }

local function clickShopItem(shopName, containerName, itemName, times)
	local shop = PlayerGui:FindFirstChild(shopName); if not shop then return false end
	local frame = shop:FindFirstChild("Frame"); if not frame then return false end
	local cont = frame:FindFirstChild(containerName); if not cont then return false end
	local item = cont:FindFirstChild(itemName); if not item then return false end
	local mf = item:FindFirstChild("Main_Frame"); if not mf then return false end
	local btn = mf:FindFirstChild("TextButton"); if not btn then return false end
	for _ = 1, (times or 1) do clickBtn(btn); task.wait(.1) end
	return true
end

local function buyAllIn(shopName, containerName, times)
	local shop = PlayerGui:FindFirstChild(shopName); if not shop then return 0 end
	local frame = shop:FindFirstChild("Frame"); if not frame then return 0 end
	local cont = frame:FindFirstChild(containerName); if not cont then return 0 end
	local n = 0
	for _, item in ipairs(cont:GetChildren()) do
		if item:IsA("GuiObject") and not SHOP_SKIP[item.Name] then
			local mf = item:FindFirstChild("Main_Frame")
			local btn = mf and mf:FindFirstChild("TextButton")
			if btn then for _ = 1, (times or 1) do clickBtn(btn); task.wait(.08) end n = n + 1 end
		end
	end
	return n
end

local function buySeed(name, times) return clickShopItem("SeedShop", "NormalShop", name, times) end
local function buyGear(name, times) return clickShopItem("GearShop", "ScrollingFrame", name, times) end

--==================================================================================--
-- PAGE: DASHBOARD
--==================================================================================--
tab("Dashboard", "â–£")
do
	local p = Pages.Dashboard
	local info = card(p, 96)
	nw("TextLabel", { Position = UDim2.new(0,14,0,10), Size = UDim2.new(1,-28,0,18), BackgroundTransparency = 1, Font = FB, Text = "Group: "..CFG.Dashboard.GroupName, TextColor3 = C.Txt, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = info })
	local statL = nw("TextLabel", { Position = UDim2.new(0,14,0,32), Size = UDim2.new(1,-28,0,54), BackgroundTransparency = 1, Font = FR, Text = "...", TextColor3 = C.Sub, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = info })

	local function refresh()
		local on = {}
		for _, k in ipairs({ "AutoHarvest","AutoSell","AutoBuySeeds","AutoBuyGears","AutoBuySlot","AutoBuyPets","AutoGarden","AutoEquipPets","AutoEventSeeds","AutoMail","PetWebhook" }) do
			if CFG[k] and CFG[k].Enabled then on[#on+1] = k end
		end
		statL.Text = "Player: "..LP.Name.."\nAktif: "..(#on > 0 and table.concat(on, ", ") or "(belum ada)").."\nFPS Cap: "..tostring(CFG.Settings.FPSCap)
	end
	refresh()
	task.spawn(function() while G.Parent do refresh(); task.wait(2) end end)

	-- Scan prompt (alat riset â€” lihat prompt di sekitar)
	local rs = card(p, 88); lbl(rs, "Scan Prompt", "lihat ProximityPrompt di sekitar (buat tuning keyword)")
	local resL = nw("TextLabel", { Position = UDim2.new(0,14,0,38), Size = UDim2.new(1,-28,0,44), BackgroundTransparency = 1, Font = FR, Text = "(tekan Scan)", TextColor3 = C.Sub, TextSize = 10, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = rs })
	local sb = nw("TextButton", { AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-14,0,10), Size = UDim2.new(0,80,0,28), BackgroundColor3 = C.Bg2, Text = "Scan", Font = FB, TextColor3 = C.Txt, TextSize = 12, Parent = rs }); cor(sb,8); st(sb,C.Strk,1)
	sb.MouseButton1Click:Connect(function()
		local seen, lines = {}, {}
		for _, v in ipairs(WS:GetDescendants()) do
			if v:IsA("ProximityPrompt") then local k = (v.ActionText or "").."|"..(v.ObjectText or ""); seen[k] = (seen[k] or 0) + 1 end
		end
		for k, c in pairs(seen) do lines[#lines+1] = "â€¢ "..k.." x"..c end
		if #lines == 0 then lines[1] = "(0 prompt â€” deketin tanaman matang dulu)" end
		resL.Text = table.concat(lines, "\n")
		if setclip then pcall(setclip, resL.Text) end
		toast("Raden", #lines.." jenis prompt (disalin)")
	end)
end

--==================================================================================--
-- PAGE: FARM  (Stage 1 = AutoHarvest; Stage 2 akan tambah Sell/Buy di sini)
--==================================================================================--
tab("Farm", "ðŸŒ¾")
do
	local p = Pages.Farm
	local aH = false
	toggle(p, "Auto Harvest", "Panen otomatis (berdiri di kebun)", CFG.AutoHarvest.Enabled, function(o)
		CFG.AutoHarvest.Enabled = o; aH = o
		toast("Raden", "Auto Harvest "..(o and "ON" or "OFF"))
		if o then
			task.spawn(function()
				while aH do firePrompts({ "harvest","collect","pick","gather" }); task.wait(.5) end
			end)
		end
	end)

	local aS = false
	toggle(p, "Auto Steal", "Nyolong kebun orang (deket) â€” prompt 'steal'", false, function(o)
		aS = o
		if o then task.spawn(function() while aS do firePrompts({ "steal" }); task.wait(.5) end end) end
	end)

	button(p, "Harvest Sekali", "Panen 1x sekarang", "Run", function()
		local n = firePrompts({ "harvest","collect","pick","gather" }); toast("Raden", n.." prompt dipicu")
	end)

	-- Fire ALL (fallback kalau harvest gagal kena keyword)
	local aA = false
	toggle(p, "Fire ALL Prompts", "Micu SEMUA prompt (fallback, hati-hati)", false, function(o)
		aA = o
		if o then task.spawn(function() while aA do if fpp then for _, v in ipairs(WS:GetDescendants()) do if v:IsA("ProximityPrompt") and v.Enabled then pcall(fpp, v) end end end task.wait(.6) end end) end
	end)
end

--==================================================================================--
-- PAGE: SHOP  (Stage 2 â€” Auto Buy Seeds + Auto Sell, best-effort fire GUI button)
--==================================================================================--
tab("Shop", "ðŸ›’")
do
	local p = Pages.Shop

	-- SCAN BUTTONS (alat tuning â€” BUKA Seed Shop / dialog Sell dulu, baru tekan)
	local rs = card(p, 96); lbl(rs, "Scan Buttons", "BUKA Seed Shop / Sell dulu, lalu tekan (hasil disalin)")
	local resL = nw("TextLabel", { Position = UDim2.new(0,14,0,40), Size = UDim2.new(1,-28,0,50), BackgroundTransparency = 1, Font = FR, Text = "(tekan Scan)", TextColor3 = C.Sub, TextSize = 10, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = rs })
	local sb = nw("TextButton", { AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-14,0,10), Size = UDim2.new(0,80,0,28), BackgroundColor3 = C.Bg2, Text = "Scan", Font = FB, TextColor3 = C.Txt, TextSize = 12, Parent = rs }); cor(sb,8); st(sb,C.Strk,1)
	sb.MouseButton1Click:Connect(function()
		local lines, n = {}, 0
		for _, v in ipairs(PlayerGui:GetDescendants()) do
			if (v:IsA("TextButton") or v:IsA("ImageButton")) and v.Visible then
				n = n + 1
				lines[#lines+1] = "â€¢ ["..(v:IsA("TextButton") and v.Text or v.ClassName).."] "..v:GetFullName()
			end
		end
		if #lines == 0 then lines[1] = "(0 tombol â€” buka Seed Shop / dialog Sell dulu)" end
		resL.Text = "total "..n.." btn:\n"..table.concat(lines, "\n")
		if setclip then pcall(setclip, resL.Text) end
		toast("Raden", n.." tombol (disalin) â€” kirim ke dev buat tuning")
	end)

	-- AUTO BUY SEEDS (path pasti: SeedShop.Frame.NormalShop.<Seed>.Main_Frame.TextButton)
	local BUY_TIMES = 8 -- klik per seed/gear per putaran (borong stock)
	local function doBuySeeds()
		firePromptMatch("talk", "sam"); task.wait(.3)
		local n = 0
		if CFG.AutoBuySeeds.Mode == "All" then
			n = buyAllIn("SeedShop", "NormalShop", BUY_TIMES)
		else
			for _, s in ipairs(CFG.AutoBuySeeds.Seeds) do if buySeed(s, BUY_TIMES) then n = n + 1 end task.wait(.1) end
		end
		return n
	end
	toggle(p, "Auto Buy Seeds", "beli seed whitelist (Mode: "..CFG.AutoBuySeeds.Mode..")", CFG.AutoBuySeeds.Enabled, function(o)
		CFG.AutoBuySeeds.Enabled = o
		toast("Raden", "Auto Buy Seeds "..(o and "ON" or "OFF"))
		if o then task.spawn(function()
			while CFG.AutoBuySeeds.Enabled do doBuySeeds(); task.wait(5) end
		end) end
	end)
	button(p, "Buy Seeds Sekali", "beli whitelist 1 putaran", "Buy", function()
		toast("Raden", "Buy seeds: "..doBuySeeds().." item")
	end)

	-- AUTO BUY GEARS (path pasti: GearShop.Frame.ScrollingFrame.<Gear>.Main_Frame.TextButton)
	local function doBuyGears()
		firePromptMatch("talk", "gear"); task.wait(.3)
		local n = 0
		if CFG.AutoBuyGears.Mode == "All" or #CFG.AutoBuyGears.Gears == 0 then
			n = buyAllIn("GearShop", "ScrollingFrame", BUY_TIMES)
		else
			for _, g in ipairs(CFG.AutoBuyGears.Gears) do if buyGear(g, BUY_TIMES) then n = n + 1 end task.wait(.1) end
		end
		return n
	end
	toggle(p, "Auto Buy Gears", "beli gear (Mode: "..CFG.AutoBuyGears.Mode..")", CFG.AutoBuyGears.Enabled, function(o)
		CFG.AutoBuyGears.Enabled = o
		toast("Raden", "Auto Buy Gears "..(o and "ON" or "OFF"))
		if o then task.spawn(function()
			while CFG.AutoBuyGears.Enabled do doBuyGears(); task.wait(5) end
		end) end
	end)
	button(p, "Buy Gears Sekali", "beli gear 1 putaran", "Buy", function()
		toast("Raden", "Buy gears: "..doBuyGears().." item")
	end)

	-- AUTO SELL
	toggle(p, "Auto Sell", "Talk ke Steven -> klik Sell Inventory!", CFG.AutoSell.Enabled, function(o)
		CFG.AutoSell.Enabled = o
		toast("Raden", "Auto Sell "..(o and "ON" or "OFF"))
		if o then task.spawn(function()
			while CFG.AutoSell.Enabled do
				firePromptMatch("talk", "steven"); task.wait(.8)
				local btns = findButtons({ "sell inventory" })
				for _, b in ipairs(btns) do clickBtn(b) end
				task.wait(8)
			end
		end) end
	end)

	button(p, "Sell Sekali", "buka Steven & jual inventory", "Sell", function()
		firePromptMatch("talk", "steven"); task.wait(.8)
		local btns = findButtons({ "sell inventory" })
		for _, b in ipairs(btns) do clickBtn(b) end
		toast("Raden", #btns.." tombol 'Sell Inventory' dipicu")
	end)
end

--==================================================================================--
-- PAGE: PLAYER  (Custom Walk Speed â€” docs Â§3 solid; re-apply di CharacterAdded)
--==================================================================================--
tab("Player", "ðŸƒ")
do
	local p = Pages.Player
	local spd = { on = false, val = 16 } -- 16 = default Roblox

	local function hum()
		local ch = LP.Character or LP.CharacterAdded:Wait()
		return ch:FindFirstChildOfClass("Humanoid")
	end
	local function applySpeed()
		local h = hum()
		if h then h.WalkSpeed = spd.on and spd.val or 16 end
	end
	-- re-apply tiap respawn + loop jaga2 (game suka reset speed)
	LP.CharacterAdded:Connect(function(ch) ch:WaitForChild("Humanoid", 5); task.wait(.6); applySpeed() end)
	task.spawn(function() while G.Parent do if spd.on then applySpeed() end task.wait(1) end end)

	-- Toggle ON/OFF
	toggle(p, "Custom Walk Speed", "ON = pakai nilai di bawah, OFF = balik 16", false, function(o)
		spd.on = o; applySpeed(); toast("Raden", "Walk Speed "..(o and ("ON ("..spd.val..")") or "OFF"))
	end)

	-- Kartu pengatur nilai: âˆ’  [value]  +   dan TextBox set manual
	local r = card(p, 118); lbl(r, "Speed Value", "atur kecepatan (1â€“500)")
	local valL = nw("TextLabel", { Position = UDim2.new(0,14,0,40), Size = UDim2.new(0,90,0,34), BackgroundColor3 = C.Bg2, Font = FB, Text = tostring(spd.val), TextColor3 = C.A, TextSize = 18, Parent = r }); cor(valL,8)
	local function setVal(v) spd.val = math.clamp(math.floor(v), 1, 500); valL.Text = tostring(spd.val); if spd.on then applySpeed() end end
	local function step(x, delta) local b = nw("TextButton", { Position = UDim2.new(0,x,0,40), Size = UDim2.new(0,40,0,34), BackgroundColor3 = C.A, Text = delta > 0 and "+" or "âˆ’", Font = FB, TextColor3 = Color3.fromRGB(16,22,18), TextSize = 18, Parent = r }); cor(b,8)
		b.MouseButton1Click:Connect(function() setVal(spd.val + delta) end)
	end
	step(112, -2); step(158, 2)
	-- TextBox custom
	local box = nw("TextBox", { AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-90,0,40), Size = UDim2.new(0,72,0,34), BackgroundColor3 = C.Bg2, Font = FM, PlaceholderText = "set...", Text = "", TextColor3 = C.Txt, PlaceholderColor3 = C.Sub, TextSize = 13, ClearTextOnFocus = true, Parent = r }); cor(box,8); st(box,C.Strk,1)
	local ap = nw("TextButton", { AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-14,0,40), Size = UDim2.new(0,68,0,34), BackgroundColor3 = C.A, Text = "Set", Font = FB, TextColor3 = Color3.fromRGB(16,22,18), TextSize = 14, Parent = r }); cor(ap,8); grd(ap,20)
	local function commit() local v = tonumber(box.Text); if v then setVal(v); toast("Raden", "Speed = "..spd.val) end box.Text = "" end
	ap.MouseButton1Click:Connect(commit)
	box.FocusLost:Connect(function(enter) if enter then commit() end end)

	-- preset cepat
	local function preset(x, v) local b = nw("TextButton", { Position = UDim2.new(0,x,0,84), Size = UDim2.new(0,52,0,26), BackgroundColor3 = C.Card, Text = tostring(v), Font = FM, TextColor3 = C.Txt, TextSize = 12, Parent = r }); cor(b,7); st(b,C.Strk,1)
		b.MouseButton1Click:Connect(function() setVal(v); toast("Raden", "Speed = "..v) end)
	end
	preset(14, 16); preset(72, 32); preset(130, 50); preset(188, 100)
end

--==================================================================================--
-- PAGE: SETTINGS  (FPSCap proven; Overlay/AutoCenter siap dipakai stage berikut)
--==================================================================================--
tab("Settings", "âš™")
do
	local p = Pages.Settings

	-- FPS Cap
	local fpsCard = card(p); lbl(fpsCard, "FPS Cap", "batasi FPS biar HP gak panas (0 = lepas)")
	local fpsVal = nw("TextLabel", { AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-110,.5,0), Size = UDim2.new(0,40,0,20), BackgroundTransparency = 1, Font = FB, Text = tostring(CFG.Settings.FPSCap), TextColor3 = C.A, TextSize = 14, Parent = fpsCard })
	local function applyFps()
		local cap = CFG.Settings.FPSCap
		if setfpscap then pcall(setfpscap, cap > 0 and cap or 10000)
		elseif set_fps_cap then pcall(set_fps_cap, cap > 0 and cap or 10000) end
	end
	local function fpsBtn(x, delta) local b = nw("TextButton", { AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,x,.5,0), Size = UDim2.new(0,30,0,30), BackgroundColor3 = C.A, Text = delta > 0 and "+" or "âˆ’", Font = FB, TextColor3 = Color3.fromRGB(16,22,18), TextSize = 16, Parent = fpsCard }); cor(b,8)
		b.MouseButton1Click:Connect(function()
			CFG.Settings.FPSCap = math.clamp(CFG.Settings.FPSCap + delta, 0, 240)
			fpsVal.Text = tostring(CFG.Settings.FPSCap); applyFps(); toast("Raden", "FPS Cap "..CFG.Settings.FPSCap)
		end)
	end
	fpsBtn(-14, 5); fpsBtn(-50, -5)
	applyFps()

	-- Show Overlay (placeholder toggle -> nyimpen state, dipakai stage berikut buat HUD mini)
	toggle(p, "Show Overlay", "tampilkan HUD status kecil (stage berikut)", CFG.Settings.ShowOverlay, function(o) CFG.Settings.ShowOverlay = o end)
	toggle(p, "Auto Center", "auto rapihin posisi window", CFG.Settings.AutoCenter, function(o)
		CFG.Settings.AutoCenter = o
		if o then W.Position = UDim2.new(.5,0,.5,0) end
	end)
end

--==================================================================================--
-- WINDOW CONTROLS: close / minimize / drag (mouse + touch)
--==================================================================================--
clB.MouseButton1Click:Connect(function() G:Destroy() end)

local MI = nw("TextButton", { AnchorPoint = Vector2.new(.5,.5), Position = UDim2.new(0,80,0,150), Size = UDim2.new(0,0,0,0), BackgroundColor3 = C.A, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 60, Parent = G }); cor(MI,16); grd(MI,45); st(MI,Color3.new(1,1,1),1.5)
nw("TextLabel", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "ðŸŒ±", TextSize = 26, ZIndex = 61, Parent = MI })
minB.MouseButton1Click:Connect(function() W.Visible = false; MI.Visible = true; MI.Size = UDim2.new(0,0,0,0); MI:TweenSize(UDim2.new(0,56,0,56), Enum.EasingDirection.Out, Enum.EasingStyle.Back, .28, true) end)
do
	local drag, sp, so, mv
	MI.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; mv = false; sp = i.Position; so = Vector2.new(MI.Position.X.Offset, MI.Position.Y.Offset) end end)
	UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - sp; if d.Magnitude > 6 then mv = true end; MI.Position = UDim2.new(0, so.X + d.X, 0, so.Y + d.Y) end end)
	UIS.InputEnded:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then drag = false; if not mv then MI:TweenSize(UDim2.new(0,0,0,0), Enum.EasingDirection.In, Enum.EasingStyle.Back, .18, true, function() MI.Visible = false end); W.Visible = true end end end)
end
do
	local drag, ds, spos
	HD.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; ds = i.Position; spos = W.Position end end)
	UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - ds; W.Position = UDim2.new(spos.X.Scale, spos.X.Offset + d.X, spos.Y.Scale, spos.Y.Offset + d.Y) end end)
	UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
end

-- default page
showPage("Dashboard")
toast("LimeHub â€¢ Raden", "Stage 1 kebuka âœ“")

end) -- pcall body

if not OKK then warn("[Raden] "..tostring(EE)); pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Raden ERROR", Text = tostring(EE), Duration = 10 }) end) end