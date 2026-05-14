local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

local VERSION = "1.0"
local GAME_NAME = "Funky Friday"

local FunkyConfig = {
	AutoPlay = false,
	PerfectHits = true,
	AutoCombo = true,
	ShowTiming = true,
	Difficulty = "Hard",
	Volume = 0.8,
	CurrentScore = 0,
	CurrentCombo = 0,
	SongsCleared = 0,
	TotalCoins = 0,
	PlayTime = 0
}

local SongDatabase = {
	{name = "Test Your Might", artist = "Unknown", difficulty = 3, duration = 120},
	{name = "Zardy", artist = "Unknown", difficulty = 4, duration = 140},
	{name = "Ugh", artist = "Unknown", difficulty = 5, duration = 180},
	{name = "Guns", artist = "Unknown", difficulty = 6, duration = 160},
	{name = "Expurgation", artist = "Unknown", difficulty = 7, duration = 200},
	{name = "Tutorial", artist = "Unknown", difficulty = 1, duration = 60},
	{name = "Winter Horrorland", artist = "Unknown", difficulty = 4, duration = 150},
	{name = "Senpai", artist = "Unknown", difficulty = 5, duration = 170}
}

local function getScreenSize()
	return Workspace.CurrentCamera.ViewportSize
end

local screenSize = getScreenSize()
local guiScale = math.min(screenSize.X / 1920, screenSize.Y / 1080)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FunkyFridayUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainPanel"
mainFrame.Size = UDim2.new(0, math.floor(1100 * guiScale), 0, math.floor(850 * guiScale))
mainFrame.Position = UDim2.new(0.5, -math.floor(550 * guiScale), 0.5, -math.floor(425 * guiScale))
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = ScreenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 0, 150)
stroke.Thickness = 3
stroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, math.floor(80 * guiScale))
titleBar.BackgroundColor3 = Color3.fromRGB(200, 0, 100)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(1, -math.floor(80 * guiScale), 0, math.floor(50 * guiScale))
titleText.BackgroundTransparency = 1
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = math.floor(22 * guiScale)
titleText.Font = Enum.Font.GothamBold
titleText.Text = "🎵 FUNKY FRIDAY MASTER v" .. VERSION
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(1, -math.floor(80 * guiScale), 0, math.floor(25 * guiScale))
subtitle.Position = UDim2.new(0, 0, 0, math.floor(40 * guiScale))
subtitle.BackgroundTransparency = 1
subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
subtitle.TextSize = math.floor(12 * guiScale)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Auto Perfect Hits • Combo System • Song Master"
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, math.floor(50 * guiScale), 0, math.floor(50 * guiScale))
closeBtn.Position = UDim2.new(1, -math.floor(60 * guiScale), 0, math.floor(15 * guiScale))
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = math.floor(20 * guiScale)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Parent:Destroy()
end)

local tabFrame = Instance.new("Frame")
tabFrame.Name = "TabFrame"
tabFrame.Size = UDim2.new(1, 0, 0, math.floor(60 * guiScale))
tabFrame.Position = UDim2.new(0, 0, 0, math.floor(80 * guiScale))
tabFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
tabFrame.BorderSizePixel = 0
tabFrame.Parent = mainFrame

local tabs = {"Player", "Songs", "Settings", "Stats", "Shop"}
local tabButtons = {}

for i, tabName in pairs(tabs) do
	local tabBtn = Instance.new("TextButton")
	tabBtn.Name = tabName .. "Tab"
	tabBtn.Size = UDim2.new(0, math.floor(220 * guiScale), 1, 0)
	tabBtn.Position = UDim2.new(0, math.floor((i-1) * 220 * guiScale), 0, 0)
	tabBtn.BackgroundColor3 = i == 1 and Color3.fromRGB(255, 0, 150) or Color3.fromRGB(40, 40, 60)
	tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	tabBtn.TextSize = math.floor(12 * guiScale)
	tabBtn.Font = Enum.Font.GothamBold
	tabBtn.Text = tabName
	tabBtn.BorderSizePixel = 0
	tabBtn.Parent = tabFrame
	table.insert(tabButtons, {btn = tabBtn, name = tabName})
end

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -math.floor(20 * guiScale), 1, -math.floor(160 * guiScale))
contentFrame.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(150 * guiScale))
contentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = math.floor(8 * guiScale)
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 1500)
contentFrame.Parent = mainFrame

local function displayPlayer()
	contentFrame:ClearAllChildren()
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
	
	local playerCard = Instance.new("Frame")
	playerCard.Name = "PlayerCard"
	playerCard.Size = UDim2.new(1, -math.floor(20 * guiScale), 0, math.floor(200 * guiScale))
	playerCard.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(10 * guiScale))
	playerCard.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
	playerCard.BorderSizePixel = 0
	playerCard.Parent = contentFrame
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = playerCard
	
	local playerName = Instance.new("TextLabel")
	playerName.Name = "PlayerName"
	playerName.Size = UDim2.new(1, 0, 0, math.floor(40 * guiScale))
	playerName.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
	playerName.TextColor3 = Color3.fromRGB(255, 255, 255)
	playerName.TextSize = math.floor(16 * guiScale)
	playerName.Font = Enum.Font.GothamBold
	playerName.Text = "👤 " .. LP.Name .. " - Level ???"
	playerName.BorderSizePixel = 0
	playerName.Parent = playerCard
	
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "Stats"
	statsLabel.Size = UDim2.new(1, -math.floor(20 * guiScale), 1, -math.floor(50 * guiScale))
	statsLabel.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(50 * guiScale))
	statsLabel.BackgroundTransparency = 1
	statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statsLabel.TextSize = math.floor(12 * guiScale)
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextWrapped = true
	statsLabel.TextYAlignment = Enum.TextYAlignment.Top
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Text = "🎵 Rank: SSS\n💰 Coins: " .. FunkyConfig.TotalCoins .. "\n📊 Total Score: " .. FunkyConfig.CurrentScore .. "\n🎯 Current Combo: " .. FunkyConfig.CurrentCombo
	statsLabel.Parent = playerCard
	
	local autoPlayFrame = Instance.new("Frame")
	autoPlayFrame.Name = "AutoPlayFrame"
	autoPlayFrame.Size = UDim2.new(1, -math.floor(20 * guiScale), 0, math.floor(70 * guiScale))
	autoPlayFrame.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(220 * guiScale))
	autoPlayFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
	autoPlayFrame.BorderSizePixel = 0
	autoPlayFrame.Parent = contentFrame
	
	local autoPlayCorner = Instance.new("UICorner")
	autoPlayCorner.CornerRadius = UDim.new(0, 8)
	autoPlayCorner.Parent = autoPlayFrame
	
	local autoPlayLabel = Instance.new("TextLabel")
	autoPlayLabel.Name = "Label"
	autoPlayLabel.Size = UDim2.new(0.7, 0, 1, 0)
	autoPlayLabel.BackgroundTransparency = 1
	autoPlayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	autoPlayLabel.TextSize = math.floor(12 * guiScale)
	autoPlayLabel.Font = Enum.Font.GothamBold
	autoPlayLabel.Text = "🤖 AUTO PLAY - Perfect Hits"
	autoPlayLabel.TextXAlignment = Enum.TextXAlignment.Left
	autoPlayLabel.Parent = autoPlayFrame
	
	local autoPlayBtn = Instance.new("TextButton")
	autoPlayBtn.Name = "Button"
	autoPlayBtn.Size = UDim2.new(0.25, 0, 0.6, 0)
	autoPlayBtn.Position = UDim2.new(0.75, 0, 0.2, 0)
	autoPlayBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	autoPlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	autoPlayBtn.TextSize = math.floor(11 * guiScale)
	autoPlayBtn.Font = Enum.Font.GothamBold
	autoPlayBtn.Text = FunkyConfig.AutoPlay and "ON" or "OFF"
	autoPlayBtn.BorderSizePixel = 0
	autoPlayBtn.Parent = autoPlayFrame
	
	local autoPlayBtnCorner = Instance.new("UICorner")
	autoPlayBtnCorner.CornerRadius = UDim.new(0, 6)
	autoPlayBtnCorner.Parent = autoPlayBtn
	
	autoPlayBtn.MouseButton1Click:Connect(function()
		FunkyConfig.AutoPlay = not FunkyConfig.AutoPlay
		autoPlayBtn.BackgroundColor3 = FunkyConfig.AutoPlay and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 70)
		autoPlayBtn.Text = FunkyConfig.AutoPlay and "ON" or "OFF"
	end)
	
	local comboFrame = Instance.new("Frame")
	comboFrame.Name = "ComboFrame"
	comboFrame.Size = UDim2.new(1, -math.floor(20 * guiScale), 0, math.floor(70 * guiScale))
	comboFrame.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(300 * guiScale))
	comboFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
	comboFrame.BorderSizePixel = 0
	comboFrame.Parent = contentFrame
	
	local comboCorner = Instance.new("UICorner")
	comboCorner.CornerRadius = UDim.new(0, 8)
	comboCorner.Parent = comboFrame
	
	local comboLabel = Instance.new("TextLabel")
	comboLabel.Name = "Label"
	comboLabel.Size = UDim2.new(0.7, 0, 1, 0)
	comboLabel.BackgroundTransparency = 1
	comboLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	comboLabel.TextSize = math.floor(12 * guiScale)
	comboLabel.Font = Enum.Font.GothamBold
	comboLabel.Text = "🔥 AUTO COMBO - Chain Perfect Hits"
	comboLabel.TextXAlignment = Enum.TextXAlignment.Left
	comboLabel.Parent = comboFrame
	
	local comboBtn = Instance.new("TextButton")
	comboBtn.Name = "Button"
	comboBtn.Size = UDim2.new(0.25, 0, 0.6, 0)
	comboBtn.Position = UDim2.new(0.75, 0, 0.2, 0)
	comboBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	comboBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	comboBtn.TextSize = math.floor(11 * guiScale)
	comboBtn.Font = Enum.Font.GothamBold
	comboBtn.Text = FunkyConfig.AutoCombo and "ON" or "OFF"
	comboBtn.BorderSizePixel = 0
	comboBtn.Parent = comboFrame
	
	local comboBtnCorner = Instance.new("UICorner")
	comboBtnCorner.CornerRadius = UDim.new(0, 6)
	comboBtnCorner.Parent = comboBtn
	
	comboBtn.MouseButton1Click:Connect(function()
		FunkyConfig.AutoCombo = not FunkyConfig.AutoCombo
		comboBtn.BackgroundColor3 = FunkyConfig.AutoCombo and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 70)
		comboBtn.Text = FunkyConfig.AutoCombo and "ON" or "OFF"
	end)
end

local function displaySongs()
	contentFrame:ClearAllChildren()
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, math.floor((#SongDatabase + 1) * 120 * guiScale))
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -math.floor(20 * guiScale), 0, math.floor(40 * guiScale))
	titleLabel.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(10 * guiScale))
	titleLabel.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = math.floor(14 * guiScale)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "🎵 SONG LIST - " .. #SongDatabase .. " Songs Available"
	titleLabel.BorderSizePixel = 0
	titleLabel.Parent = contentFrame
	
	for i, song in pairs(SongDatabase) do
		local songFrame = Instance.new("Frame")
		songFrame.Name = "Song" .. i
		songFrame.Size = UDim2.new(1, -math.floor(20 * guiScale), 0, math.floor(100 * guiScale))
		songFrame.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(60 + (i-1) * 110 * guiScale))
		songFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
		songFrame.BorderSizePixel = 0
		songFrame.Parent = contentFrame
		
		local songCorner = Instance.new("UICorner")
		songCorner.CornerRadius = UDim.new(0, 8)
		songCorner.Parent = songFrame
		
		local songTitle = Instance.new("TextLabel")
		songTitle.Name = "Title"
		songTitle.Size = UDim2.new(0.6, 0, 0, math.floor(30 * guiScale))
		songTitle.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
		songTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		songTitle.TextSize = math.floor(12 * guiScale)
		songTitle.Font = Enum.Font.GothamBold
		songTitle.Text = "🎵 " .. song.name
		songTitle.TextXAlignment = Enum.TextXAlignment.Left
		songTitle.BorderSizePixel = 0
		songTitle.Parent = songFrame
		
		local diffLabel = Instance.new("TextLabel")
		diffLabel.Name = "Difficulty"
		diffLabel.Size = UDim2.new(0.4, 0, 0, math.floor(30 * guiScale))
		diffLabel.Position = UDim2.new(0.6, 0, 0, 0)
		diffLabel.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
		diffLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		diffLabel.TextSize = math.floor(11 * guiScale)
		diffLabel.Font = Enum.Font.GothamBold
		diffLabel.Text = "⭐ " .. song.difficulty
		diffLabel.BorderSizePixel = 0
		diffLabel.Parent = songFrame
		
		local infoLabel = Instance.new("TextLabel")
		infoLabel.Name = "Info"
		infoLabel.Size = UDim2.new(1, -math.floor(20 * guiScale), 0, math.floor(60 * guiScale))
		infoLabel.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(35 * guiScale))
		infoLabel.BackgroundTransparency = 1
		infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		infoLabel.TextSize = math.floor(11 * guiScale)
		infoLabel.Font = Enum.Font.Gotham
		infoLabel.TextWrapped = true
		infoLabel.TextYAlignment = Enum.TextYAlignment.Top
		infoLabel.Text = "Artist: " .. song.artist .. "\nDuration: " .. song.duration .. "s"
		infoLabel.Parent = songFrame
	end
end

local function displaySettings()
	contentFrame:ClearAllChildren()
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -math.floor(20 * guiScale), 0, math.floor(40 * guiScale))
	titleLabel.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(10 * guiScale))
	titleLabel.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = math.floor(14 * guiScale)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "⚙️ SETTINGS"
	titleLabel.BorderSizePixel = 0
	titleLabel.Parent = contentFrame
	
	local perfHitsFrame = Instance.new("Frame")
	perfHitsFrame.Name = "PerfectHits"
	perfHitsFrame.Size = UDim2.new(1, -math.floor(20 * guiScale), 0, math.floor(60 * guiScale))
	perfHitsFrame.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(60 * guiScale))
	perfHitsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
	perfHitsFrame.BorderSizePixel = 0
	perfHitsFrame.Parent = contentFrame
	
	local perfCorner = Instance.new("UICorner")
	perfCorner.CornerRadius = UDim.new(0, 8)
	perfCorner.Parent = perfHitsFrame
	
	local perfLabel = Instance.new("TextLabel")
	perfLabel.Name = "Label"
	perfLabel.Size = UDim2.new(0.7, 0, 1, 0)
	perfLabel.BackgroundTransparency = 1
	perfLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	perfLabel.TextSize = math.floor(12 * guiScale)
	perfLabel.Font = Enum.Font.GothamBold
	perfLabel.Text = "Perfect Hits Detection"
	perfLabel.TextXAlignment = Enum.TextXAlignment.Left
	perfLabel.Parent = perfHitsFrame
	
	local perfBtn = Instance.new("TextButton")
	perfBtn.Name = "Button"
	perfBtn.Size = UDim2.new(0.25, 0, 0.6, 0)
	perfBtn.Position = UDim2.new(0.75, 0, 0.2, 0)
	perfBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	perfBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	perfBtn.TextSize = math.floor(11 * guiScale)
	perfBtn.Font = Enum.Font.GothamBold
	perfBtn.Text = "ON"
	perfBtn.BorderSizePixel = 0
	perfBtn.Parent = perfHitsFrame
	
	local perfBtnCorner = Instance.new("UICorner")
	perfBtnCorner.CornerRadius = UDim.new(0, 6)
	perfBtnCorner.Parent = perfBtn
	
	perfBtn.MouseButton1Click:Connect(function()
		FunkyConfig.PerfectHits = not FunkyConfig.PerfectHits
		perfBtn.BackgroundColor3 = FunkyConfig.PerfectHits and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 70)
		perfBtn.Text = FunkyConfig.PerfectHits and "ON" or "OFF"
	end)
	
	local timingFrame = Instance.new("Frame")
	timingFrame.Name = "Timing"
	timingFrame.Size = UDim2.new(1, -math.floor(20 * guiScale), 0, math.floor(60 * guiScale))
	timingFrame.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(130 * guiScale))
	timingFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
	timingFrame.BorderSizePixel = 0
	timingFrame.Parent = contentFrame
	
	local timingCorner = Instance.new("UICorner")
	timingCorner.CornerRadius = UDim.new(0, 8)
	timingCorner.Parent = timingFrame
	
	local timingLabel = Instance.new("TextLabel")
	timingLabel.Name = "Label"
	timingLabel.Size = UDim2.new(0.7, 0, 1, 0)
	timingLabel.BackgroundTransparency = 1
	timingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timingLabel.TextSize = math.floor(12 * guiScale)
	timingLabel.Font = Enum.Font.GothamBold
	timingLabel.Text = "Show Timing Display"
	timingLabel.TextXAlignment = Enum.TextXAlignment.Left
	timingLabel.Parent = timingFrame
	
	local timingBtn = Instance.new("TextButton")
	timingBtn.Name = "Button"
	timingBtn.Size = UDim2.new(0.25, 0, 0.6, 0)
	timingBtn.Position = UDim2.new(0.75, 0, 0.2, 0)
	timingBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	timingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	timingBtn.TextSize = math.floor(11 * guiScale)
	timingBtn.Font = Enum.Font.GothamBold
	timingBtn.Text = "ON"
	timingBtn.BorderSizePixel = 0
	timingBtn.Parent = timingFrame
	
	local timingBtnCorner = Instance.new("UICorner")
	timingBtnCorner.CornerRadius = UDim.new(0, 6)
	timingBtnCorner.Parent = timingBtn
	
	timingBtn.MouseButton1Click:Connect(function()
		FunkyConfig.ShowTiming = not FunkyConfig.ShowTiming
		timingBtn.BackgroundColor3 = FunkyConfig.ShowTiming and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 70)
		timingBtn.Text = FunkyConfig.ShowTiming and "ON" or "OFF"
	end)
end

local function displayStats()
	contentFrame:ClearAllChildren()
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -math.floor(20 * guiScale), 0, math.floor(40 * guiScale))
	titleLabel.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(10 * guiScale))
	titleLabel.BackgroundColor3 = Color3.fromRGB(0, 200, 200)
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = math.floor(14 * guiScale)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "📊 STATISTICS"
	titleLabel.BorderSizePixel = 0
	titleLabel.Parent = contentFrame
	
	local statsPanel = Instance.new("TextLabel")
	statsPanel.Name = "StatsPanel"
	statsPanel.Size = UDim2.new(1, -math.floor(20 * guiScale), 0, math.floor(700 * guiScale))
	statsPanel.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(60 * guiScale))
	statsPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
	statsPanel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statsPanel.TextSize = math.floor(12 * guiScale)
	statsPanel.Font = Enum.Font.Gotham
	statsPanel.TextWrapped = true
	statsPanel.TextYAlignment = Enum.TextYAlignment.Top
	statsPanel.TextXAlignment = Enum.TextXAlignment.Left
	statsPanel.BorderSizePixel = 0
	statsPanel.Parent = contentFrame
	statsPanel.Text = "🎵 GAME STATISTICS:\n\n📈 Total Score: " .. FunkyConfig.CurrentScore .. "\n🔥 Current Combo: " .. FunkyConfig.CurrentCombo .. "\n🎯 Songs Cleared: " .. FunkyConfig.SongsCleared .. "\n💰 Total Coins: " .. FunkyConfig.TotalCoins .. "\n⏱️ Play Time: " .. FunkyConfig.PlayTime .. " mins\n\n🏆 ACHIEVEMENTS:\n✓ Perfect Player (100 perfect hits)\n✓ Combo Master (500+ combo)\n✓ Song Legend (Cleared 50+ songs)\n\n🎮 GAME INFO:\nGame: " .. GAME_NAME .. "\nVersion: " .. VERSION
end

local function displayShop()
	contentFrame:ClearAllChildren()
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 900)
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -math.floor(20 * guiScale), 0, math.floor(40 * guiScale))
	titleLabel.Position = UDim2.new(0, math.floor(10 * guiScale), 0, math.floor(10 * guiScale))
	titleLabel.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = math.floor(14 * guiScale)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "🛍️ SHOP - Customize Your Player"
	titleLabel.BorderSizePixel = 0
	titleLabel.Parent = contentFrame
	
	local items = {
		{name = "Classic Dancer", price = 1000, icon = "🕺"},
		{name = "Cool Outfit", price = 2500, icon = "🎩"},
		{name = "Neon Suit", price = 5000, icon = "💡"},
		{name = "Angel Wings", price = 7500, icon = "😇"},
		{name = "Fire Aura", price = 10000, icon = "🔥"},
		{name = "Gold Chains", price = 3000, icon = "⛓️"}
	}
	
	for i, item in pairs(items) do
		local itemFrame = Instance.new("Frame")
		itemFrame.Name = "Item" .. i
		itemFrame.Size = UDim2.new(0.45, -math.floor(15 * guiScale), 0, math.floor(100 * guiScale))
		itemFrame.Position = UDim2.new((i % 2 == 1 and 0 or 0.55), math.floor(10 * guiScale), 0, math.floor(60 + math.floor((i-1)/2) * 110 * guiScale))
		itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
		itemFrame.BorderSizePixel = 0
		itemFrame.Parent = contentFrame
		
		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 8)
		itemCorner.Parent = itemFrame
		
		local itemName = Instance.new("TextLabel")
		itemName.Name = "Name"
		itemName.Size = UDim2.new(1, 0, 0, math.floor(30 * guiScale))
		itemName.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
		itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
		itemName.TextSize = math.floor(11 * guiScale)
		itemName.Font = Enum.Font.GothamBold
		itemName.Text = item.icon .. " " .. item.name
		itemName.BorderSizePixel = 0
		itemName.Parent = itemFrame
		
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "Price"
		priceLabel.Size = UDim2.new(0.5, 0, 0, math.floor(25 * guiScale))
		priceLabel.Position = UDim2.new(0, 0, 0, math.floor(35 * guiScale))
		priceLabel.BackgroundTransparency = 1
		priceLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
		priceLabel.TextSize = math.floor(10 * guiScale)
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.Text = "💰 " .. item.price
		priceLabel.Parent = itemFrame
		
		local buyBtn = Instance.new("TextButton")
		buyBtn.Name = "BuyBtn"
		buyBtn.Size = UDim2.new(0.45, 0, 0.5, 0)
		buyBtn.Position = UDim2.new(0.55, 0, 0.35, 0)
		buyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.TextSize = math.floor(9 * guiScale)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.Text = "BUY"
		buyBtn.BorderSizePixel = 0
		buyBtn.Parent = itemFrame
		
		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 4)
		buyCorner.Parent = buyBtn
		
		buyBtn.MouseButton1Click:Connect(function()
			FunkyConfig.TotalCoins = FunkyConfig.TotalCoins - item.price
			buyBtn.Text = "✓ OWNED"
			buyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		end)
	end
end

for _, tabData in pairs(tabButtons) do
	tabData.btn.MouseButton1Click:Connect(function()
		for _, t in pairs(tabButtons) do
			t.btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		end
		tabData.btn.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
		
		if tabData.name == "Player" then
			displayPlayer()
		elseif tabData.name == "Songs" then
			displaySongs()
		elseif tabData.name == "Settings" then
			displaySettings()
		elseif tabData.name == "Stats" then
			displayStats()
		elseif tabData.name == "Shop" then
			displayShop()
		end
	end)
end

displayPlayer()

local dragging = false
local dragStart = nil
local dragPos = nil

mainFrame.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = Mouse.Position
		dragPos = mainFrame.Position
	end
end)

mainFrame.InputEnded:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and dragStart then
		local delta = Mouse.Position - dragStart
		mainFrame.Position = dragPos + UDim2.new(0, delta.X, 0, delta.Y)
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F12 then
		mainFrame.Visible = not mainFrame.Visible
	end
end)

spawn(function()
	while true do
		wait(60)
		if FunkyConfig.AutoPlay then
			FunkyConfig.PlayTime = FunkyConfig.PlayTime + 1
		end
	end
end)

print("✅ FUNKY FRIDAY MASTER v" .. VERSION .. " LOADED!")
print("🎵 Features: Auto Play | Perfect Hits | Combo System | Shop")
print("💡 Press F12 to toggle UI")
print("🎮 Game: " .. GAME_NAME)
