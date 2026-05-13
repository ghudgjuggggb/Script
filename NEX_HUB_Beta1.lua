-- ╔══════════════════════════════════════════════════════╗
-- ║          NEX HUB  Beta 1.0  |  Clover Origins       ║
-- ║  Adaptive UI | PC + Mobile | All functions fixed     ║
-- ╚══════════════════════════════════════════════════════╝

-- ─── Services ─────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RS               = game:GetService("ReplicatedStorage")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer

-- ─── Device & Screen Adaptation ──────────────────────
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local VP        = Camera.ViewportSize

-- Scale: 1.0 = base (600px), scales up/down for any screen
local SCALE   = math.clamp(math.min(VP.X, VP.Y) / 600, 0.55, 1.5)
local UI_W    = IS_MOBILE and math.floor(VP.X * 0.94) or math.floor(math.min(460, VP.X * 0.42))
local UI_H    = IS_MOBILE and math.floor(VP.Y * 0.86) or math.floor(math.min(560, VP.Y * 0.82))
local FONT_SM = math.floor(11 * SCALE)
local FONT_MD = math.floor(13 * SCALE)
local FONT_LG = math.floor(15 * SCALE)
local PAD     = math.floor(10 * SCALE)
local ROW_H   = math.floor(36 * SCALE)
local HDR_H   = math.floor(44 * SCALE)
local TAB_H   = IS_MOBILE and math.floor(38 * SCALE) or math.floor(30 * SCALE)
local BTN_RAD = UDim.new(0, math.floor(7 * SCALE))

-- ─── Colours ──────────────────────────────────────────
local C = {
	BG       = Color3.fromRGB(12, 12, 20),
	Panel    = Color3.fromRGB(22, 22, 35),
	Card     = Color3.fromRGB(30, 30, 48),
	Accent   = Color3.fromRGB(220, 0, 110),
	Accent2  = Color3.fromRGB(140, 0, 200),
	Green    = Color3.fromRGB(60,  220, 100),
	Yellow   = Color3.fromRGB(255, 200, 60),
	Blue     = Color3.fromRGB(60,  160, 255),
	Red      = Color3.fromRGB(255, 70,  70),
	TextW    = Color3.fromRGB(240, 240, 240),
	TextG    = Color3.fromRGB(140, 140, 160),
	Border   = Color3.fromRGB(55,  55,  80),
}

-- ─── Remote Paths (from full game dump) ───────────────
local EV  = RS:WaitForChild("Events",  10)
local REM = RS:WaitForChild("Remotes", 10)

local function getRemote(parent, name, timeout)
	local ok, r = pcall(function()
		return parent:WaitForChild(name, timeout or 6)
	end)
	return ok and r or nil
end

local R = {
	Codes             = getRemote(EV,  "Codes"),
	Quests            = getRemote(EV,  "Quests"),
	RepeatQuest       = getRemote(EV,  "RepeatQuest"),
	Interact          = getRemote(EV,  "Interact"),
	Inventory         = getRemote(EV,  "Inventory"),
	Combat            = getRemote(EV,  "Combat"),
	MotionHandler     = getRemote(REM, "MotionHandler"),
	InvValidateTool   = getRemote(EV,  "InventoryValidateTool"),  -- RemoteFunction
	MagicKnightExam   = getRemote(EV,  "MagicKnightExam"),
	ManaSenseQuest    = getRemote(EV,  "ManaSenseQuest"),
	SecondaryQuests   = getRemote(EV,  "SecondaryQuestTools"),
	Missions          = getRemote(EV,  "Missions"),
}

-- ─── State ────────────────────────────────────────────
local S = {
	AutoFarm    = false,
	AutoCodes   = false,
	AutoChest   = false,
	FarmTime    = 0,
	KillCount   = 0,
	ChestCount  = 0,
	CodesRedeemed = 0,
	ActiveTab   = "Farm",
}

-- ─── All codes (from Code.txt reference) ──────────────
local ALL_CODES = {
	{code="SHUTDOWNSORRY7!", reward="2x EXP + 2x Luck 1hr"},
	{code="85KLIKES!",       reward="10k Yens + 3 Stat Reset + 10 Grimoire + 10 Broom + 10 Race + 25 Trait Spins"},
	{code="80KLIKES!",       reward="10k Yens + 3 Stat Reset + 10 Grimoire + 10 Broom + 10 Race + 25 Trait Spins"},
	{code="UPDATE4!",        reward="10k Yens + 3 Stat Reset + 10 Grimoire + 10 Broom + 10 Race + 25 Trait Spins"},
	{code="THANKS2!",        reward="50 Race Spins + 25 Grimoire Spins"},
	{code="70KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="75KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="65KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="60KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="UPDATEFIXES2!",   reward="2hr 2x EXP + 2x Luck"},
	{code="55KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="50KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="UPDATESFIXES!",   reward="2hr 2x EXP + 2x Luck"},
	{code="45KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="40KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="THANKS!",         reward="50 Race Spins + 25 Grimoire Spins"},
	{code="35KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="SHUTDOWNSORRY5!", reward="10k Yens + 3 Stat Reset + Spins"},
	{code="30KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="29KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="28KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="BUGFIXES11!",     reward="10k Yens + 3 Stat Reset + Spins"},
	{code="SORRYSHUTDOWN!",  reward="1hr 2x EXP + 2x Luck"},
	{code="27KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="26KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="25KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="24KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="23KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="22KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="21KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="20KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="19KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="BUGFIXES10!",     reward="10k Yens + 3 Stat Reset + Spins"},
	{code="18KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="17KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="16KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="15KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="14KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="13KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
	{code="12KLIKES!",       reward="10k Yens + 3 Stat Reset + Spins"},
}

-- ─── Level → Quest ranges ─────────────────────────────
local LEVEL_RANGES = {
	{min=1,   max=49,  enemy="Bandit",         quest="Bandit Boss Quest Lvl 50",         pos=Vector3.new(155.27,  5.18,  -330.74)},
	{min=50,  max=149, enemy="Boar",           quest="Boar Quest Lvl 150",               pos=Vector3.new(-121.18, 15.71, -844.86)},
	{min=150, max=249, enemy="Boar Boss",      quest="Boar Boss Quest Lvl 250",          pos=Vector3.new(-576.53, 10.98, -946.72)},
	{min=250, max=449, enemy="Corrupted Wiz",  quest="Corrupted Wizards Quest Lvl 450",  pos=Vector3.new(-310.15, 33.00, -2063.69)},
	{min=450, max=999, enemy="Earth Wizard",   quest="Quest Giver Earth Wizard 2000+",   pos=Vector3.new(536.77,  14.15, -416.55)},
}

-- ─── All Quest NPCs (from квесты.txt) ─────────────────
local QUEST_NPCS = {
	{name="Bandit Quest Lvl 1",                 pos=Vector3.new(289.63,  5.68,  -720.66)},
	{name="Bandit Boss Quest Lvl 50",           pos=Vector3.new(155.27,  5.18,  -330.74)},
	{name="Boar Quest Lvl 150",                 pos=Vector3.new(-121.18, 15.71, -844.86)},
	{name="Boar Boss Quest Lvl 250",            pos=Vector3.new(-576.53, 10.98, -946.72)},
	{name="Corrupted Wizards Quest Lvl 450",    pos=Vector3.new(-310.15, 33.00, -2063.69)},
	{name="Quest Giver Water Wizard",           pos=Vector3.new(-325.87, 11.14, -571.94)},
	{name="Quest Giver Earth Wizard 2000+",     pos=Vector3.new(536.77,  14.15, -416.55)},
	{name="Quest Giver Corrupted Nobleman 2550+", pos=Vector3.new(-449.13, 11.14, -724.49)},
	{name="Secondary Quest Giver Wheat",        pos=Vector3.new(-3.40,   5.18,  -623.19)},
	{name="BroomQuest",                         pos=Vector3.new(328.52,  17.29, -534.90)},
}

-- ─── Helpers ──────────────────────────────────────────
local function safeFireServer(remote, ...)
	if not remote then return false end
	local args = {...}
	local ok, err = pcall(function()
		remote:FireServer(table.unpack(args))
	end)
	if not ok then warn("[NexHub] Remote error: " .. tostring(err)) end
	return ok
end

local function safeInvokeServer(remote, ...)
	if not remote then return false end
	local args = {...}
	local ok, err = pcall(function()
		remote:InvokeServer(table.unpack(args))
	end)
	if not ok then warn("[NexHub] Invoke error: " .. tostring(err)) end
	return ok
end

local function getLevel()
	if LP.Character then
		local lv = LP.Character:FindFirstChild("Level")
		if lv then return lv.Value end
		local hum = LP.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			local lv2 = hum:FindFirstChild("Level") or hum.Parent:FindFirstChild("Level")
			if lv2 then return lv2.Value end
		end
	end
	return 1
end

local function getLevelRange()
	local lv = getLevel()
	for _, r in ipairs(LEVEL_RANGES) do
		if lv >= r.min and lv <= r.max then return r end
	end
	return LEVEL_RANGES[#LEVEL_RANGES]
end

local function getHum()
	return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function teleportTo(pos)
	local root = getRoot()
	if root then
		root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
	end
end

local function formatTime(s)
	return string.format("%02d:%02d:%02d", math.floor(s/3600), math.floor(s%3600/60), math.floor(s%60))
end

-- ─── Game Logic ───────────────────────────────────────
local function redeemCode(code)
	return safeFireServer(R.Codes, code)
end

local function giveQuest(questName)
	return safeFireServer(R.Quests, "giveQuest", questName)
end

local function enableRegen()
	if LP.Character and LP.Character:FindFirstChild("Regen") then
		safeFireServer(R.MotionHandler, LP.Character:FindFirstChild("Regen"), true)
	end
end

local function enableCombat()
	if LP.Character and LP.Character:FindFirstChild("Combat") then
		safeFireServer(R.MotionHandler, LP.Character:FindFirstChild("Combat"), true)
	end
end

local function equipCombat()
	safeInvokeServer(R.InvValidateTool, "Combat")
end

local function findNearestChest()
	local containers = {"Chests", "Items", "Chest", "WorldItems"}
	for _, cname in ipairs(containers) do
		local folder = workspace:FindFirstChild(cname)
		if folder then
			local root = getRoot()
			if not root then return nil end
			local best, bestDist = nil, 999999
			for _, obj in ipairs(folder:GetChildren()) do
				local pos = nil
				if obj:IsA("Model") then
					local hrp = obj:FindFirstChild("HumanoidRootPart")
						or obj:FindFirstChild("PrimaryPart")
						or obj:FindFirstChildWhichIsA("BasePart")
					if hrp then pos = hrp.Position end
				elseif obj:IsA("BasePart") then
					pos = obj.Position
				end
				if pos then
					local d = (pos - root.Position).Magnitude
					if d < bestDist then bestDist=d; best=obj end
				end
			end
			if best then return best end
		end
	end
	return nil
end

local function collectChest(chest)
	local root = getRoot()
	if not root or not chest then return end
	pcall(function()
		local target = chest:IsA("Model")
			and (chest:FindFirstChild("HumanoidRootPart") or chest:FindFirstChildWhichIsA("BasePart"))
			or chest
		if target then
			root.CFrame = CFrame.new(target.Position + Vector3.new(0, 4, 0))
			task.wait(0.25)
			safeFireServer(R.Interact, chest)
			S.ChestCount = S.ChestCount + 1
		end
	end)
end

-- ─── Auto loops ───────────────────────────────────────
-- Fixed: task.spawn / task.wait instead of spawn / wait

task.spawn(function()
	task.wait(2)
	if S.AutoCodes then
		for _, entry in ipairs(ALL_CODES) do
			if redeemCode(entry.code) then
				S.CodesRedeemed = S.CodesRedeemed + 1
			end
			task.wait(0.7)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)

		if S.AutoFarm then
			S.FarmTime = S.FarmTime + 1
			if LP.Character then
				enableRegen()
				task.wait(0.05)
				enableCombat()
				task.wait(0.05)
				equipCombat()
				task.wait(0.05)
				local range = getLevelRange()
				giveQuest(range.quest)
				task.wait(0.05)
				teleportTo(range.pos)
			end
		end

		if S.AutoChest then
			local chest = findNearestChest()
			if chest then
				collectChest(chest)
				task.wait(1.5)
			end
		end
	end
end)

-- ─── UI Construction ──────────────────────────────────
-- Existing GUI cleanup
pcall(function()
	local old = LP.PlayerGui:FindFirstChild("NexHubUI")
	if old then old:Destroy() end
end)

local GUI = Instance.new("ScreenGui")
GUI.Name           = "NexHubUI"
GUI.ResetOnSpawn   = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.IgnoreGuiInset = true
GUI.Parent         = LP.PlayerGui

-- ── Main frame ────────────────────────────────────────
local startX = IS_MOBILE and math.floor((VP.X - UI_W) / 2) or PAD * 2
local startY = IS_MOBILE and math.floor((VP.Y - UI_H) / 2) or math.floor(VP.Y * 0.1)

local Main = Instance.new("Frame")
Main.Name            = "Main"
Main.Size            = UDim2.new(0, UI_W, 0, UI_H)
Main.Position        = UDim2.new(0, startX, 0, startY)
Main.BackgroundColor3= C.BG
Main.BorderSizePixel = 0
Main.Parent          = GUI

local mainCorner = Instance.new("UICorner", Main); mainCorner.CornerRadius = UDim.new(0, math.floor(12*SCALE))
local mainStroke = Instance.new("UIStroke",  Main); mainStroke.Color = C.Accent; mainStroke.Thickness = math.max(1, math.floor(2*SCALE))

-- Gradient border effect
local grad = Instance.new("UIGradient", mainStroke)
grad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0,   C.Accent),
	ColorSequenceKeypoint.new(0.5, C.Accent2),
	ColorSequenceKeypoint.new(1,   C.Accent),
})
grad.Rotation = 45

-- ── Header ────────────────────────────────────────────
local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1, 0, 0, HDR_H)
Header.BackgroundColor3 = C.Panel
Header.BorderSizePixel  = 0
Header.ZIndex           = 2
Header.Parent           = Main

local hCorner = Instance.new("UICorner", Header); hCorner.CornerRadius = UDim.new(0, math.floor(12*SCALE))

local hGrad = Instance.new("UIGradient", Header)
hGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0,   C.Accent),
	ColorSequenceKeypoint.new(1,   C.Accent2),
})
hGrad.Rotation = 90

local Title = Instance.new("TextLabel")
Title.Size              = UDim2.new(1, -HDR_H-PAD, 1, 0)
Title.Position          = UDim2.new(0, PAD, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3        = C.TextW
Title.Font              = Enum.Font.GothamBold
Title.TextSize          = FONT_LG
Title.TextXAlignment    = Enum.TextXAlignment.Left
Title.Text              = "⚡ NEX HUB  Beta 1.0  |  Clover Origins"
Title.ZIndex            = 3
Title.Parent            = Header

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, HDR_H-8, 0, HDR_H-8)
CloseBtn.Position         = UDim2.new(1, -(HDR_H-4), 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseBtn.BorderSizePixel  = 0
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = C.TextW
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = FONT_MD
CloseBtn.ZIndex           = 4
CloseBtn.Parent           = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local isOpen = true
CloseBtn.MouseButton1Click:Connect(function()
	isOpen = not isOpen
	Main.Size = isOpen
		and UDim2.new(0, UI_W, 0, UI_H)
		or  UDim2.new(0, UI_W, 0, HDR_H)
end)

-- ── Dragging ──────────────────────────────────────────
local dragging, dragStart, frameStart = false, nil, nil
local function drag(input)
	if dragging then
		local delta = input.Position - dragStart
		Main.Position = UDim2.new(0,
			math.clamp(frameStart.X + delta.X, 0, VP.X - UI_W),
			0,
			math.clamp(frameStart.Y + delta.Y, 0, VP.Y - HDR_H))
	end
end

Header.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
		dragging   = true
		dragStart  = inp.Position
		frameStart = Main.AbsolutePosition
		inp.Changed:Connect(function()
			if inp.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseMovement
		or inp.UserInputType == Enum.UserInputType.Touch then
		drag(inp)
	end
end)

-- ── Separator under header ────────────────────────────
local Sep = Instance.new("Frame")
Sep.Size             = UDim2.new(1, 0, 0, 1)
Sep.Position         = UDim2.new(0, 0, 0, HDR_H)
Sep.BackgroundColor3 = C.Border
Sep.BorderSizePixel  = 0
Sep.Parent           = Main

-- ── Tab bar ───────────────────────────────────────────
local TAB_NAMES = {"Farm", "Codes", "Chest", "Quests", "Stats"}
local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, 0, 0, TAB_H + PAD)
TabBar.Position         = UDim2.new(0, 0, 0, HDR_H + 1)
TabBar.BackgroundColor3 = C.Panel
TabBar.BorderSizePixel  = 0
TabBar.ZIndex           = 2
TabBar.Parent           = Main

local TabList = Instance.new("UIListLayout", TabBar)
TabList.FillDirection  = Enum.FillDirection.Horizontal
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabList.VerticalAlignment   = Enum.VerticalAlignment.Center
TabList.Padding        = UDim.new(0, 4)
TabList.SortOrder      = Enum.SortOrder.LayoutOrder

local TabPad = Instance.new("UIPadding", TabBar)
TabPad.PaddingLeft  = UDim.new(0, PAD)
TabPad.PaddingRight = UDim.new(0, PAD)
TabPad.PaddingTop   = UDim.new(0, math.floor(PAD/2))
TabPad.PaddingBottom= UDim.new(0, math.floor(PAD/2))

local tabBtns = {}
local tabW    = math.floor((UI_W - PAD*2 - 4*(#TAB_NAMES-1)) / #TAB_NAMES)

for i, tname in ipairs(TAB_NAMES) do
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(0, tabW, 0, TAB_H)
	btn.BackgroundColor3 = C.Card
	btn.BorderSizePixel  = 0
	btn.Text             = tname
	btn.TextColor3       = C.TextG
	btn.Font             = Enum.Font.GothamBold
	btn.TextSize         = FONT_SM
	btn.LayoutOrder      = i
	btn.ZIndex           = 3
	btn.Parent           = TabBar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
	tabBtns[tname] = btn
end

-- ── Content frame (scrollable) ────────────────────────
local CONTENT_Y = HDR_H + 1 + TAB_H + PAD + 1
local CONTENT_H = UI_H - CONTENT_Y - PAD

local Content = Instance.new("ScrollingFrame")
Content.Size             = UDim2.new(1, -PAD*2, 0, CONTENT_H)
Content.Position         = UDim2.new(0, PAD, 0, CONTENT_Y)
Content.BackgroundTransparency = 1
Content.BorderSizePixel  = 0
Content.ScrollBarThickness= IS_MOBILE and 4 or 3
Content.ScrollBarImageColor3 = C.Accent
Content.CanvasSize       = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent           = Main

local ContentList = Instance.new("UIListLayout", Content)
ContentList.Padding   = UDim.new(0, math.floor(6*SCALE))
ContentList.SortOrder = Enum.SortOrder.LayoutOrder
ContentList.FillDirection = Enum.FillDirection.Vertical

-- ─── UI Component factories ───────────────────────────

local function makeCard(parent, order)
	local card = Instance.new("Frame")
	card.Size             = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize    = Enum.AutomaticSize.Y
	card.BackgroundColor3 = C.Card
	card.BorderSizePixel  = 0
	card.LayoutOrder      = order or 99
	card.Parent           = parent
	Instance.new("UICorner", card).CornerRadius = BTN_RAD
	local pad = Instance.new("UIPadding", card)
	pad.PaddingLeft   = UDim.new(0, PAD)
	pad.PaddingRight  = UDim.new(0, PAD)
	pad.PaddingTop    = UDim.new(0, math.floor(PAD*0.7))
	pad.PaddingBottom = UDim.new(0, math.floor(PAD*0.7))
	local list = Instance.new("UIListLayout", card)
	list.Padding   = UDim.new(0, math.floor(5*SCALE))
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.FillDirection = Enum.FillDirection.Vertical
	return card
end

local function makeLabel(parent, text, textColor, fontSize, order, xAlign)
	local lbl = Instance.new("TextLabel")
	lbl.Size             = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize    = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.TextColor3       = textColor or C.TextW
	lbl.Font             = Enum.Font.Gotham
	lbl.TextSize         = fontSize or FONT_MD
	lbl.TextXAlignment   = xAlign or Enum.TextXAlignment.Left
	lbl.TextWrapped      = true
	lbl.Text             = text
	lbl.LayoutOrder      = order or 99
	lbl.Parent           = parent
	return lbl
end

local function makeToggle(parent, label, stateKey, order, onToggle)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, 0, 0, ROW_H)
	row.BackgroundTransparency = 1
	row.LayoutOrder      = order or 99
	row.Parent           = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size             = UDim2.new(1, -(ROW_H+PAD), 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3       = C.TextW
	lbl.Font             = Enum.Font.Gotham
	lbl.TextSize         = FONT_MD
	lbl.TextXAlignment   = Enum.TextXAlignment.Left
	lbl.Text             = label
	lbl.TextWrapped      = true
	lbl.Parent           = row

	local pill = Instance.new("TextButton")
	pill.Size            = UDim2.new(0, ROW_H*1.7, 0, ROW_H*0.6)
	pill.Position        = UDim2.new(1, -(ROW_H*1.7), 0.5, -ROW_H*0.3)
	pill.BackgroundColor3= S[stateKey] and C.Green or C.Card
	pill.BorderSizePixel = 0
	pill.Text            = S[stateKey] and "ON" or "OFF"
	pill.TextColor3      = C.TextW
	pill.Font            = Enum.Font.GothamBold
	pill.TextSize        = FONT_SM
	pill.Parent          = row
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
	Instance.new("UIStroke",  pill).Color = C.Border

	local function refresh()
		local on = S[stateKey]
		pill.Text = on and "ON" or "OFF"
		TweenService:Create(pill, TweenInfo.new(0.15), {
			BackgroundColor3 = on and C.Green or C.Card
		}):Play()
	end

	pill.MouseButton1Click:Connect(function()
		S[stateKey] = not S[stateKey]
		refresh()
		if onToggle then onToggle(S[stateKey]) end
	end)

	return row, pill, refresh
end

local function makeButton(parent, label, col, order, onClick)
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(1, 0, 0, ROW_H)
	btn.BackgroundColor3 = col or C.Accent
	btn.BorderSizePixel  = 0
	btn.Text             = label
	btn.TextColor3       = C.TextW
	btn.Font             = Enum.Font.GothamBold
	btn.TextSize         = FONT_SM
	btn.LayoutOrder      = order or 99
	btn.Parent           = parent
	Instance.new("UICorner", btn).CornerRadius = BTN_RAD

	btn.MouseButton1Click:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = col and col:Lerp(Color3.new(1,1,1),0.2) or C.Accent2}):Play()
		task.delay(0.12, function()
			TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = col or C.Accent}):Play()
		end)
		if onClick then pcall(onClick) end
	end)

	return btn
end

local function makeDivider(parent, order)
	local d = Instance.new("Frame")
	d.Size             = UDim2.new(1, 0, 0, 1)
	d.BackgroundColor3 = C.Border
	d.BorderSizePixel  = 0
	d.LayoutOrder      = order or 99
	d.Parent           = parent
	return d
end

-- ─── Notification toast ───────────────────────────────
local ToastFrame = Instance.new("Frame")
ToastFrame.Size             = UDim2.new(0, math.floor(UI_W * 0.7), 0, math.floor(36*SCALE))
ToastFrame.AnchorPoint      = Vector2.new(0.5, 0)
ToastFrame.Position         = UDim2.new(0.5, 0, 0, -50)
ToastFrame.BackgroundColor3 = C.Green
ToastFrame.BorderSizePixel  = 0
ToastFrame.ZIndex           = 10
ToastFrame.Parent           = GUI
Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 8)

local ToastLbl = Instance.new("TextLabel")
ToastLbl.Size       = UDim2.new(1, -10, 1, 0)
ToastLbl.Position   = UDim2.new(0, 5, 0, 0)
ToastLbl.BackgroundTransparency = 1
ToastLbl.TextColor3 = C.BG
ToastLbl.Font       = Enum.Font.GothamBold
ToastLbl.TextSize   = FONT_SM
ToastLbl.Text       = ""
ToastLbl.ZIndex     = 11
ToastLbl.Parent     = ToastFrame

local toastActive = false
local function showToast(msg, col, duration)
	ToastFrame.BackgroundColor3 = col or C.Green
	ToastLbl.Text = msg
	TweenService:Create(ToastFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart),
		{Position = UDim2.new(0.5, 0, 0, 8)}):Play()
	toastActive = true
	task.delay(duration or 2.5, function()
		TweenService:Create(ToastFrame, TweenInfo.new(0.2),
			{Position = UDim2.new(0.5, 0, 0, -50)}):Play()
		toastActive = false
	end)
end

-- ─── Page builders ────────────────────────────────────

local function clearContent()
	for _, c in ipairs(Content:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
end

local statsLbls = {}  -- updated in render loop

local function buildFarm()
	clearContent()

	-- Status card
	local c1 = makeCard(Content, 1)
	makeLabel(c1, "AUTO FARM", C.Accent, FONT_LG, 1)
	makeLabel(c1, "Automatically assigns the correct quest and teleports\nbased on your current level.", C.TextG, FONT_SM, 2)
	makeDivider(c1, 3)

	makeToggle(c1, "Enable Auto Farm", "AutoFarm", 4, function(on)
		showToast(on and "Auto Farm ON" or "Auto Farm OFF", on and C.Green or C.Red)
	end)

	-- Level info card
	local c2 = makeCard(Content, 2)
	makeLabel(c2, "LEVEL RANGES", C.Yellow, FONT_MD, 1)
	local rangeStr = ""
	for _, r in ipairs(LEVEL_RANGES) do
		rangeStr = rangeStr .. string.format("Lv %d–%d  →  %s\n", r.min, r.max, r.enemy)
	end
	makeLabel(c2, rangeStr:sub(1,-2), C.TextG, FONT_SM, 2)

	-- Teleport to current zone
	makeButton(c2, "⚡ Teleport to My Zone", C.Accent, 3, function()
		local range = getLevelRange()
		teleportTo(range.pos)
		showToast("Teleported to " .. range.enemy .. " zone", C.Blue)
	end)

	-- Stats card (live)
	local c3 = makeCard(Content, 3)
	makeLabel(c3, "FARM STATS", C.Yellow, FONT_MD, 1)
	statsLbls.farm = makeLabel(c3, "Loading...", C.TextG, FONT_SM, 2)

	-- Stop all
	makeButton(c3, "◼ Stop All Auto Functions", C.Red, 3, function()
		S.AutoFarm  = false
		S.AutoCodes = false
		S.AutoChest = false
		showToast("All auto functions stopped", C.Red)
	end)
end

local function buildCodes()
	clearContent()

	local c1 = makeCard(Content, 1)
	makeLabel(c1, "AUTO CODES REDEEMER", C.Accent, FONT_LG, 1)
	makeLabel(c1, string.format("Redeems all %d codes on load. Toggle to auto-run on next join.", #ALL_CODES), C.TextG, FONT_SM, 2)
	makeDivider(c1, 3)
	makeToggle(c1, "Auto Redeem on Load", "AutoCodes", 4, function(on)
		showToast(on and "Auto Codes ON" or "Auto Codes OFF", on and C.Green or C.Red)
	end)

	-- Redeem all now
	makeButton(c1, "▶ Redeem ALL Codes Now", C.Green, 5, function()
		showToast("Redeeming " .. #ALL_CODES .. " codes...", C.Blue, 4)
		task.spawn(function()
			local ok = 0
			for _, entry in ipairs(ALL_CODES) do
				if redeemCode(entry.code) then ok = ok + 1 end
				task.wait(0.6)
			end
			S.CodesRedeemed = ok
			showToast(string.format("Done! %d/%d codes redeemed", ok, #ALL_CODES), C.Green, 3)
		end)
	end)

	-- Code list
	local c2 = makeCard(Content, 2)
	makeLabel(c2, "ALL CODES  (" .. #ALL_CODES .. " total)", C.Yellow, FONT_MD, 1)
	for i, entry in ipairs(ALL_CODES) do
		local row = Instance.new("Frame")
		row.Size            = UDim2.new(1, 0, 0, 0)
		row.AutomaticSize   = Enum.AutomaticSize.Y
		row.BackgroundTransparency = 1
		row.LayoutOrder     = i + 1
		row.Parent          = c2
		local rl = Instance.new("UIListLayout", row)
		rl.FillDirection = Enum.FillDirection.Vertical
		rl.Padding = UDim.new(0, 2)

		makeLabel(row, string.format("%d. %s", i, entry.code), C.TextW, FONT_SM, 1)
		makeLabel(row, "  → " .. entry.reward, C.TextG, FONT_SM-1, 2)
		if i < #ALL_CODES then
			local sep = Instance.new("Frame", row)
			sep.Size = UDim2.new(1, 0, 0, 1)
			sep.BackgroundColor3 = C.Border
			sep.BorderSizePixel = 0
			sep.LayoutOrder = 3
		end

		-- Tap code to redeem it individually
		local btn = Instance.new("TextButton", row)
		btn.Size = UDim2.new(1, 0, 0, 0)
		btn.AutomaticSize = Enum.AutomaticSize.Y
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 5
		btn.Parent = row
		-- invisible clickable overlay
		btn.MouseButton1Click:Connect(function()
			if redeemCode(entry.code) then
				showToast("Redeemed: " .. entry.code, C.Green)
			else
				showToast("Failed: " .. entry.code, C.Red)
			end
		end)
	end
end

local function buildChest()
	clearContent()

	local c1 = makeCard(Content, 1)
	makeLabel(c1, "AUTO CHEST COLLECTOR", C.Accent, FONT_LG, 1)
	makeLabel(c1, "Teleports to the nearest chest in the world and opens it automatically.", C.TextG, FONT_SM, 2)
	makeDivider(c1, 3)
	makeToggle(c1, "Enable Auto Chest Collect", "AutoChest", 4, function(on)
		showToast(on and "Auto Chest ON" or "Auto Chest OFF", on and C.Green or C.Red)
	end)

	local c2 = makeCard(Content, 2)
	makeLabel(c2, "MANUAL", C.Yellow, FONT_MD, 1)
	makeButton(c2, "📦 Collect Nearest Chest Now", C.Blue, 2, function()
		local chest = findNearestChest()
		if chest then
			collectChest(chest)
			showToast("Chest collected! Total: " .. S.ChestCount, C.Green)
		else
			showToast("No chest found nearby", C.Red)
		end
	end)

	local c3 = makeCard(Content, 3)
	makeLabel(c3, "STATS", C.Yellow, FONT_MD, 1)
	statsLbls.chest = makeLabel(c3, "Chests collected: " .. S.ChestCount, C.TextG, FONT_SM, 2)
end

local function buildQuests()
	clearContent()

	local c1 = makeCard(Content, 1)
	makeLabel(c1, "QUEST GIVERS & TELEPORT", C.Accent, FONT_LG, 1)
	makeLabel(c1, "Tap any quest to get the quest AND teleport to the NPC.", C.TextG, FONT_SM, 2)

	for i, npc in ipairs(QUEST_NPCS) do
		local qCard = makeCard(Content, i + 1)
		makeLabel(qCard, npc.name, C.TextW, FONT_SM, 1)
		makeLabel(qCard, string.format("Pos: %.0f, %.0f, %.0f", npc.pos.X, npc.pos.Y, npc.pos.Z), C.TextG, FONT_SM-1, 2)

		local btnRow = Instance.new("Frame")
		btnRow.Size            = UDim2.new(1, 0, 0, ROW_H)
		btnRow.BackgroundTransparency = 1
		btnRow.LayoutOrder     = 3
		btnRow.Parent          = qCard

		local tpBtn = Instance.new("TextButton")
		tpBtn.Size             = UDim2.new(0.48, 0, 1, 0)
		tpBtn.BackgroundColor3 = C.Blue
		tpBtn.BorderSizePixel  = 0
		tpBtn.Text             = "⚡ Teleport"
		tpBtn.TextColor3       = C.TextW
		tpBtn.Font             = Enum.Font.GothamBold
		tpBtn.TextSize         = FONT_SM
		tpBtn.Parent           = btnRow
		Instance.new("UICorner", tpBtn).CornerRadius = BTN_RAD
		tpBtn.MouseButton1Click:Connect(function()
			teleportTo(npc.pos)
			showToast("Teleported to " .. npc.name:sub(1, 24), C.Blue)
		end)

		local qBtn = Instance.new("TextButton")
		qBtn.Size             = UDim2.new(0.48, 0, 1, 0)
		qBtn.Position         = UDim2.new(0.52, 0, 0, 0)
		qBtn.BackgroundColor3 = C.Accent
		qBtn.BorderSizePixel  = 0
		qBtn.Text             = "✓ Get Quest"
		qBtn.TextColor3       = C.TextW
		qBtn.Font             = Enum.Font.GothamBold
		qBtn.TextSize         = FONT_SM
		qBtn.Parent           = btnRow
		Instance.new("UICorner", qBtn).CornerRadius = BTN_RAD
		local qname = npc.name
		qBtn.MouseButton1Click:Connect(function()
			giveQuest(qname)
			teleportTo(npc.pos)
			showToast("Quest: " .. qname:sub(1,24), C.Green)
		end)
	end
end

local function buildStats()
	clearContent()

	local c1 = makeCard(Content, 1)
	makeLabel(c1, "PLAYER STATS", C.Accent, FONT_LG, 1)
	statsLbls.statsMain = makeLabel(c1, "Loading...", C.TextG, FONT_SM, 2)

	local c2 = makeCard(Content, 2)
	makeLabel(c2, "SESSION STATS", C.Yellow, FONT_MD, 1)
	statsLbls.statsSession = makeLabel(c2, "Loading...", C.TextG, FONT_SM, 2)

	local c3 = makeCard(Content, 3)
	makeLabel(c3, "INFO", C.Blue, FONT_MD, 1)
	makeLabel(c3, string.format(
		"NEX HUB Beta 1.0\nClover Origins\nDevice: %s\nScreen: %dx%d\nScale: %.2f\nRemotes loaded: %d/12",
		IS_MOBILE and "Mobile" or "PC",
		math.floor(VP.X), math.floor(VP.Y),
		SCALE,
		(R.Codes and 1 or 0) + (R.Quests and 1 or 0) + (R.MotionHandler and 1 or 0)
			+ (R.Interact and 1 or 0) + (R.InvValidateTool and 1 or 0)
			+ (R.RepeatQuest and 1 or 0) + (R.Missions and 1 or 0)
			+ (R.MagicKnightExam and 1 or 0) + (R.ManaSenseQuest and 1 or 0)
			+ (R.SecondaryQuests and 1 or 0) + (R.Inventory and 1 or 0) + (R.Combat and 1 or 0)
	), C.TextG, FONT_SM, 2)
end

-- ─── Tab switching ────────────────────────────────────
local TAB_BUILDERS = {
	Farm   = buildFarm,
	Codes  = buildCodes,
	Chest  = buildChest,
	Quests = buildQuests,
	Stats  = buildStats,
}

local function switchTab(name)
	S.ActiveTab = name
	for tname, btn in pairs(tabBtns) do
		if tname == name then
			btn.BackgroundColor3 = C.Accent
			btn.TextColor3       = C.TextW
		else
			btn.BackgroundColor3 = C.Card
			btn.TextColor3       = C.TextG
		end
	end
	if TAB_BUILDERS[name] then TAB_BUILDERS[name]() end
end

for tname, btn in pairs(tabBtns) do
	local n = tname
	btn.MouseButton1Click:Connect(function() switchTab(n) end)
end

-- ─── Live stats update ────────────────────────────────
RunService.Heartbeat:Connect(function()
	local hum  = getHum()
	local lv   = getLevel()
	local range= getLevelRange()

	if statsLbls.farm and statsLbls.farm.Parent then
		statsLbls.farm.Text = string.format(
			"Level: %d  |  Zone: %s\nFarm Time: %s\nChests: %d  |  Codes: %d\nStatus: %s",
			lv, range.enemy,
			formatTime(S.FarmTime),
			S.ChestCount, S.CodesRedeemed,
			S.AutoFarm and "🟢 Farming" or "⛔ Idle"
		)
	end

	if statsLbls.chest and statsLbls.chest.Parent then
		statsLbls.chest.Text = "Chests collected: " .. S.ChestCount
	end

	if statsLbls.statsMain and statsLbls.statsMain.Parent then
		local hp    = hum and math.floor(hum.Health) or 0
		local maxhp = hum and math.floor(hum.MaxHealth) or 0
		statsLbls.statsMain.Text = string.format(
			"Level: %d\nHP: %d / %d\nZone: %s (Lv %d–%d)\nCurrent Quest: %s",
			lv, hp, maxhp,
			range.enemy, range.min, range.max,
			range.quest
		)
	end

	if statsLbls.statsSession and statsLbls.statsSession.Parent then
		statsLbls.statsSession.Text = string.format(
			"Farm Time: %s\nAuto Farm: %s\nAuto Codes: %s\nAuto Chest: %s\nChests: %d\nCodes Redeemed: %d",
			formatTime(S.FarmTime),
			S.AutoFarm  and "ON" or "OFF",
			S.AutoCodes and "ON" or "OFF",
			S.AutoChest and "ON" or "OFF",
			S.ChestCount,
			S.CodesRedeemed
		)
	end
end)

-- ─── Init ─────────────────────────────────────────────
switchTab("Farm")

-- ─── Mobile toggle button (show/hide hub) ─────────────
if IS_MOBILE then
	local ToggleBtn = Instance.new("TextButton")
	ToggleBtn.Size             = UDim2.new(0, math.floor(52*SCALE), 0, math.floor(52*SCALE))
	ToggleBtn.Position         = UDim2.new(0, 6, 0.5, -math.floor(26*SCALE))
	ToggleBtn.BackgroundColor3 = C.Accent
	ToggleBtn.BorderSizePixel  = 0
	ToggleBtn.Text             = "⚡"
	ToggleBtn.TextColor3       = C.TextW
	ToggleBtn.Font             = Enum.Font.GothamBold
	ToggleBtn.TextSize         = math.floor(22*SCALE)
	ToggleBtn.ZIndex           = 5
	ToggleBtn.Parent           = GUI
	Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

	ToggleBtn.MouseButton1Click:Connect(function()
		Main.Visible = not Main.Visible
	end)
end

print("✅ NEX HUB Beta 1.0 Loaded | Device: " .. (IS_MOBILE and "Mobile" or "PC") .. " | Scale: " .. string.format("%.2f", SCALE))
