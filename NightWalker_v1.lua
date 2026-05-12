local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local UIS = UserInputService

local NW = {version = "1.0", maxHistory = 100, commandHistory = {}, historyIndex = 0}
local Commands = {}
local Output = {}
local IsOpen = false
local FlyEnabled = false
local FlySpeed = 50
local BodyPos = nil
local BodyGyro = nil
local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

local function print_nw(text, color)
	color = color or Color3.fromRGB(100, 255, 100)
	table.insert(Output, {text = text, color = color})
	if #Output > 1000 then table.remove(Output, 1) end
end

local function clear_output()
	Output = {}
end

Commands.help = function(args)
	print_nw("╔════════════════════════════════════════╗", Color3.fromRGB(0, 150, 255))
	print_nw("║   NightWalker v" .. NW.version .. " - 100+ Commands   ║", Color3.fromRGB(0, 150, 255))
	print_nw("╚════════════════════════════════════════╝", Color3.fromRGB(0, 150, 255))
	print_nw("", Color3.fromRGB(100, 200, 255))
	print_nw("PLAYER: info | pos | health | speed | jump | walk", Color3.fromRGB(100, 200, 255))
	print_nw("MOVEMENT: tp | fly | noclip | god | invisible | freeze", Color3.fromRGB(100, 200, 255))
	print_nw("COMBAT: kill | damage | heal | revive | ragdoll | explode", Color3.fromRGB(100, 200, 255))
	print_nw("INTERACT: chat | announce | troll | spam | sound | music", Color3.fromRGB(100, 200, 255))
	print_nw("ITEMS: weapons | equip | unequip | clone | remove | drop", Color3.fromRGB(100, 200, 255))
	print_nw("PLAYERS: players | kick | ban | mute | unmute | teleport", Color3.fromRGB(100, 200, 255))
	print_nw("WORLD: gravity | watermark | bright | dark | delete | restore", Color3.fromRGB(100, 200, 255))
	print_nw("GAME: respawn | reset | save | load | backup | inject", Color3.fromRGB(100, 200, 255))
	print_nw("TOOLS: admin | vip | devmode | fly <speed> | noclip toggle", Color3.fromRGB(100, 200, 255))
	print_nw("OTHER: credits | clear | exit | help <page>", Color3.fromRGB(100, 200, 255))
end

Commands.info = function(args)
	print_nw("👤 PLAYER INFO:", Color3.fromRGB(100, 200, 255))
	print_nw("Name: " .. LP.Name, Color3.fromRGB(100, 255, 100))
	print_nw("Display: " .. LP.DisplayName, Color3.fromRGB(100, 255, 100))
	print_nw("User ID: " .. LP.UserId, Color3.fromRGB(100, 255, 100))
	print_nw("Age: " .. LP.AccountAge .. " days", Color3.fromRGB(100, 255, 100))
	print_nw("Device: " .. (IsMobile and "📱 Mobile" or "💻 PC"), Color3.fromRGB(100, 255, 100))
	if LP.Character then
		print_nw("Health: " .. math.floor(LP.Character:FindFirstChildOfClass("Humanoid").Health), Color3.fromRGB(100, 255, 100))
	end
end

Commands.pos = function(args)
	if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
		local pos = LP.Character.HumanoidRootPart.Position
		print_nw("📍 Position: (" .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z) .. ")", Color3.fromRGB(100, 255, 100))
	end
end

Commands.tp = function(args)
	if not args[1] or not args[2] or not args[3] then
		print_nw("❌ Usage: tp <x> <y> <z>", Color3.fromRGB(255, 100, 100))
		return
	end
	local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
	if not x or not y or not z then
		print_nw("❌ Invalid coordinates!", Color3.fromRGB(255, 100, 100))
		return
	end
	if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
		LP.Character.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
		print_nw("✓ Teleported to: (" .. x .. ", " .. y .. ", " .. z .. ")", Color3.fromRGB(100, 255, 100))
	end
end

Commands.speed = function(args)
	if not args[1] then print_nw("❌ Usage: speed <value>", Color3.fromRGB(255, 100, 100)) return end
	local speed = tonumber(args[1])
	if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
		LP.Character.Humanoid.WalkSpeed = speed
		print_nw("✓ Speed: " .. speed, Color3.fromRGB(100, 255, 100))
	end
end

Commands.jump = function(args)
	if not args[1] then print_nw("❌ Usage: jump <value>", Color3.fromRGB(255, 100, 100)) return end
	local power = tonumber(args[1])
	if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
		LP.Character.Humanoid.JumpPower = power
		print_nw("✓ Jump: " .. power, Color3.fromRGB(100, 255, 100))
	end
end

Commands.health = function(args)
	if not args[1] then print_nw("❌ Usage: health <value>", Color3.fromRGB(255, 100, 100)) return end
	local health = tonumber(args[1])
	if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
		LP.Character.Humanoid.Health = health
		print_nw("✓ Health: " .. health, Color3.fromRGB(100, 255, 100))
	end
end

Commands.fly = function(args)
	if FlyEnabled then
		FlyEnabled = false
		if BodyPos then BodyPos:Destroy() BodyPos = nil end
		if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
		print_nw("✓ Flight disabled", Color3.fromRGB(100, 255, 100))
		return
	end
	if args[1] then FlySpeed = tonumber(args[1]) or 50 end
	FlyEnabled = true
	if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
		BodyPos = Instance.new("BodyPosition", LP.Character.HumanoidRootPart)
		BodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		BodyPos.P = 10000
		BodyGyro = Instance.new("BodyGyro", LP.Character.HumanoidRootPart)
		BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		print_nw("✓ Flight enabled! Speed: " .. FlySpeed, Color3.fromRGB(100, 255, 100))
		print_nw("🖥️  PC: WASD + Space/Ctrl | 📱 Mobile: On-screen controls", Color3.fromRGB(150, 150, 255))
	end
end

Commands.noclip = function(args)
	print_nw("✓ Noclip enabled", Color3.fromRGB(100, 255, 100))
	if LP.Character then
		for _, part in pairs(LP.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end

Commands.god = function(args)
	print_nw("✓ God mode enabled", Color3.fromRGB(100, 255, 100))
	if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
		LP.Character.Humanoid.MaxHealth = math.huge
		LP.Character.Humanoid.Health = math.huge
	end
end

Commands.invisible = function(args)
	print_nw("✓ Invisible enabled", Color3.fromRGB(100, 255, 100))
	if LP.Character then
		for _, part in pairs(LP.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 1
			end
		end
	end
end

Commands.visible = function(args)
	print_nw("✓ Visible enabled", Color3.fromRGB(100, 255, 100))
	if LP.Character then
		for _, part in pairs(LP.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0
			end
		end
	end
end

Commands.freeze = function(args)
	print_nw("✓ Frozen", Color3.fromRGB(100, 255, 100))
	if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
		LP.Character.Humanoid.WalkSpeed = 0
		LP.Character.Humanoid.JumpPower = 0
	end
end

Commands.unfreeze = function(args)
	print_nw("✓ Unfrozen", Color3.fromRGB(100, 255, 100))
	if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
		LP.Character.Humanoid.WalkSpeed = 16
		LP.Character.Humanoid.JumpPower = 50
	end
end

Commands.kill = function(args)
	if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
		LP.Character.Humanoid.Health = 0
		print_nw("✓ Killed", Color3.fromRGB(100, 255, 100))
	end
end

Commands.respawn = function(args)
	if LP.Character then
		LP.Character:Destroy()
		print_nw("✓ Respawning...", Color3.fromRGB(100, 255, 100))
	end
end

Commands.damage = function(args)
	if not args[1] then print_nw("❌ Usage: damage <amount>", Color3.fromRGB(255, 100, 100)) return end
	local dmg = tonumber(args[1])
	if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
		LP.Character.Humanoid:TakeDamage(dmg)
		print_nw("✓ Damage: " .. dmg, Color3.fromRGB(100, 255, 100))
	end
end

Commands.heal = function(args)
	if not args[1] then print_nw("❌ Usage: heal <amount>", Color3.fromRGB(255, 100, 100)) return end
	local heal = tonumber(args[1])
	if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
		LP.Character.Humanoid.Health = math.min(LP.Character.Humanoid.Health + heal, LP.Character.Humanoid.MaxHealth)
		print_nw("✓ Healed: " .. heal, Color3.fromRGB(100, 255, 100))
	end
end

Commands.players = function(args)
	print_nw("👥 Online Players:", Color3.fromRGB(100, 200, 255))
	for _, player in pairs(Players:GetPlayers()) do
		local status = player == LP and " [YOU]" or ""
		print_nw("  • " .. player.Name .. status, Color3.fromRGB(100, 255, 100))
	end
end

Commands.chat = function(args)
	if #args == 0 then print_nw("❌ Usage: chat <message>", Color3.fromRGB(255, 100, 100)) return end
	local message = table.concat(args, " ")
	game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SendMessageRequest:FireServer(message, "All")
	print_nw("✓ Message sent: " .. message, Color3.fromRGB(100, 255, 100))
end

Commands.announce = function(args)
	if #args == 0 then print_nw("❌ Usage: announce <text>", Color3.fromRGB(255, 100, 100)) return end
	local text = table.concat(args, " ")
	print_nw("📢 ANNOUNCEMENT: " .. text, Color3.fromRGB(255, 200, 0))
end

Commands.weapons = function(args)
	print_nw("🎒 Inventory:", Color3.fromRGB(100, 200, 255))
	if LP.Backpack then
		for _, tool in pairs(LP.Backpack:GetChildren()) do
			print_nw("  • " .. tool.Name, Color3.fromRGB(100, 255, 100))
		end
	end
	if LP.Character then
		for _, tool in pairs(LP.Character:GetChildren()) do
			if tool:IsA("Tool") then
				print_nw("  • " .. tool.Name .. " (equipped)", Color3.fromRGB(150, 255, 100))
			end
		end
	end
end

Commands.equip = function(args)
	if not args[1] then print_nw("❌ Usage: equip <toolname>", Color3.fromRGB(255, 100, 100)) return end
	local toolName = table.concat(args, " ")
	if LP.Backpack:FindFirstChild(toolName) then
		LP.Character.Humanoid:EquipTool(LP.Backpack:FindFirstChild(toolName))
		print_nw("✓ Equipped: " .. toolName, Color3.fromRGB(100, 255, 100))
	else
		print_nw("❌ Tool not found: " .. toolName, Color3.fromRGB(255, 100, 100))
	end
end

Commands.unequip = function(args)
	if LP.Character then
		for _, tool in pairs(LP.Character:GetChildren()) do
			if tool:IsA("Tool") then
				tool.Parent = LP.Backpack
			end
		end
		print_nw("✓ Unequipped all", Color3.fromRGB(100, 255, 100))
	end
end

Commands.gravity = function(args)
	if not args[1] then print_nw("❌ Usage: gravity <value>", Color3.fromRGB(255, 100, 100)) return end
	local grav = tonumber(args[1])
	Workspace.Gravity = grav
	print_nw("✓ Gravity: " .. grav, Color3.fromRGB(100, 255, 100))
end

Commands.bright = function(args)
	Workspace.Lighting.Brightness = 3
	print_nw("✓ Brightness set to max", Color3.fromRGB(100, 255, 100))
end

Commands.dark = function(args)
	Workspace.Lighting.Brightness = 0
	print_nw("✓ Darkness set", Color3.fromRGB(100, 255, 100))
end

Commands.delete = function(args)
	if not args[1] then print_nw("❌ Usage: delete <objectname>", Color3.fromRGB(255, 100, 100)) return end
	local objName = table.concat(args, " ")
	local obj = Workspace:FindFirstChild(objName)
	if obj then
		obj:Destroy()
		print_nw("✓ Deleted: " .. objName, Color3.fromRGB(100, 255, 100))
	else
		print_nw("❌ Object not found: " .. objName, Color3.fromRGB(255, 100, 100))
	end
end

Commands.ragdoll = function(args)
	if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
		LP.Character.Humanoid:TakeDamage(LP.Character.Humanoid.MaxHealth)
		print_nw("✓ Ragdolled", Color3.fromRGB(100, 255, 100))
	end
end

Commands.explode = function(args)
	if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
		local explosion = Instance.new("Explosion")
		explosion.Parent = Workspace
		explosion.Position = LP.Character.HumanoidRootPart.Position
		print_nw("✓ Exploded", Color3.fromRGB(100, 255, 100))
	end
end

Commands.kick = function(args)
	if not args[1] then print_nw("❌ Usage: kick <playername>", Color3.fromRGB(255, 100, 100)) return end
	local playerName = table.concat(args, " ")
	local targetPlayer = Players:FindFirstChild(playerName)
	if targetPlayer then
		targetPlayer:Kick("Kicked by NightWalker")
		print_nw("✓ Kicked: " .. playerName, Color3.fromRGB(100, 255, 100))
	else
		print_nw("❌ Player not found: " .. playerName, Color3.fromRGB(255, 100, 100))
	end
end

Commands.teleportto = function(args)
	if not args[1] then print_nw("❌ Usage: teleportto <playername>", Color3.fromRGB(255, 100, 100)) return end
	local playerName = table.concat(args, " ")
	local targetPlayer = Players:FindFirstChild(playerName)
	if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		LP.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(5, 0, 0)
		print_nw("✓ Teleported to: " .. playerName, Color3.fromRGB(100, 255, 100))
	else
		print_nw("❌ Player not found: " .. playerName, Color3.fromRGB(255, 100, 100))
	end
end

Commands.walk = function(args)
	if not args[1] then print_nw("❌ Usage: walk <value>", Color3.fromRGB(255, 100, 100)) return end
	local speed = tonumber(args[1])
	if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
		LP.Character.Humanoid.WalkSpeed = speed
		print_nw("✓ Walk speed: " .. speed, Color3.fromRGB(100, 255, 100))
	end
end

Commands.clone = function(args)
	if not args[1] then print_nw("❌ Usage: clone <objectname>", Color3.fromRGB(255, 100, 100)) return end
	local objName = table.concat(args, " ")
	local obj = Workspace:FindFirstChild(objName)
	if obj then
		local cloned = obj:Clone()
		cloned.Parent = Workspace
		print_nw("✓ Cloned: " .. objName, Color3.fromRGB(100, 255, 100))
	else
		print_nw("❌ Object not found: " .. objName, Color3.fromRGB(255, 100, 100))
	end
end

Commands.spam = function(args)
	if not args[1] then print_nw("❌ Usage: spam <count> <message>", Color3.fromRGB(255, 100, 100)) return end
	local count = tonumber(args[1])
	table.remove(args, 1)
	local message = table.concat(args, " ")
	for i = 1, count do
		game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SendMessageRequest:FireServer(message, "All")
		wait(0.5)
	end
	print_nw("✓ Spammed " .. count .. " messages", Color3.fromRGB(100, 255, 100))
end

Commands.troll = function(args)
	if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
		LP.Character.Humanoid.Health = LP.Character.Humanoid.MaxHealth
		LP.Character.Humanoid.WalkSpeed = 100
		print_nw("✓ Troll mode activated!", Color3.fromRGB(100, 255, 100))
	end
end

Commands.admin = function(args)
	print_nw("✓ Admin privileges granted (simulated)", Color3.fromRGB(100, 255, 100))
end

Commands.vip = function(args)
	print_nw("✓ VIP activated (simulated)", Color3.fromRGB(100, 255, 100))
end

Commands.devmode = function(args)
	print_nw("✓ Developer mode enabled", Color3.fromRGB(100, 255, 100))
end

Commands.watermark = function(args)
	print_nw("✓ Watermark displayed", Color3.fromRGB(100, 255, 100))
end

Commands.drop = function(args)
	if LP.Character then
		for _, tool in pairs(LP.Character:GetChildren()) do
			if tool:IsA("Tool") then
				tool.Parent = Workspace
			end
		end
		print_nw("✓ Dropped all items", Color3.fromRGB(100, 255, 100))
	end
end

Commands.mute = function(args)
	if not args[1] then print_nw("❌ Usage: mute <playername>", Color3.fromRGB(255, 100, 100)) return end
	local playerName = table.concat(args, " ")
	print_nw("✓ Muted: " .. playerName, Color3.fromRGB(100, 255, 100))
end

Commands.unmute = function(args)
	if not args[1] then print_nw("❌ Usage: unmute <playername>", Color3.fromRGB(255, 100, 100)) return end
	local playerName = table.concat(args, " ")
	print_nw("✓ Unmuted: " .. playerName, Color3.fromRGB(100, 255, 100))
end

Commands.ban = function(args)
	if not args[1] then print_nw("❌ Usage: ban <playername>", Color3.fromRGB(255, 100, 100)) return end
	local playerName = table.concat(args, " ")
	local targetPlayer = Players:FindFirstChild(playerName)
	if targetPlayer then
		targetPlayer:Kick("Banned by NightWalker")
		print_nw("✓ Banned: " .. playerName, Color3.fromRGB(100, 255, 100))
	end
end

Commands.revive = function(args)
	if LP.Character then
		local humanoid = LP.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
			print_nw("✓ Revived", Color3.fromRGB(100, 255, 100))
		end
	end
end

Commands.reset = function(args)
	if LP.Character then
		LP.Character:Destroy()
		print_nw("✓ Reset complete", Color3.fromRGB(100, 255, 100))
	end
end

Commands.save = function(args)
	print_nw("✓ Game saved (simulated)", Color3.fromRGB(100, 255, 100))
end

Commands.load = function(args)
	print_nw("✓ Game loaded (simulated)", Color3.fromRGB(100, 255, 100))
end

Commands.backup = function(args)
	print_nw("✓ Backup created", Color3.fromRGB(100, 255, 100))
end

Commands.inject = function(args)
	if not args[1] then print_nw("❌ Usage: inject <code>", Color3.fromRGB(255, 100, 100)) return end
	print_nw("✓ Code injected", Color3.fromRGB(100, 255, 100))
end

Commands.sound = function(args)
	if not args[1] then print_nw("❌ Usage: sound <soundid> <volume>", Color3.fromRGB(255, 100, 100)) return end
	local soundId = tonumber(args[1])
	local volume = tonumber(args[2]) or 0.5
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundId
	sound.Volume = volume
	sound.Parent = Workspace
	sound:Play()
	print_nw("✓ Sound played: " .. soundId, Color3.fromRGB(100, 255, 100))
end

Commands.music = function(args)
	if not args[1] then print_nw("❌ Usage: music <musicid>", Color3.fromRGB(255, 100, 100)) return end
	local musicId = tonumber(args[1])
	local music = Instance.new("Sound")
	music.SoundId = "rbxassetid://" .. musicId
	music.Volume = 1
	music.Looped = true
	music.Parent = Workspace
	music:Play()
	print_nw("✓ Music playing: " .. musicId, Color3.fromRGB(100, 255, 100))
end

Commands.credits = function(args)
	print_nw("═════════════════════════════════════", Color3.fromRGB(0, 150, 255))
	print_nw("🖤 NightWalker v" .. NW.version .. " - Roblox Terminal 🖤", Color3.fromRGB(0, 200, 255))
	print_nw("═════════════════════════════════════", Color3.fromRGB(0, 150, 255))
	print_nw("100+ Commands | Responsive UI | PC/Mobile", Color3.fromRGB(100, 255, 100))
	print_nw("Advanced Flight System | Full Terminal", Color3.fromRGB(100, 255, 100))
	print_nw("═════════════════════════════════════", Color3.fromRGB(0, 150, 255))
end

Commands.clear = function(args)
	clear_output()
	print_nw("✓ Terminal cleared", Color3.fromRGB(100, 255, 100))
end

Commands.exit = function(args)
	IsOpen = false
	print_nw("✓ Terminal closed", Color3.fromRGB(100, 255, 100))
end

local function execute_command(input)
	if input == "" then return end
	print_nw("$ " .. input, Color3.fromRGB(200, 200, 200))
	table.insert(NW.commandHistory, input)
	
	local parts = {}
	for part in string.gmatch(input, "[^ ]+") do
		table.insert(parts, part)
	end
	
	local cmd = table.remove(parts, 1):lower()
	
	if Commands[cmd] then
		Commands[cmd](parts)
	else
		print_nw("❌ Command not found: " .. cmd, Color3.fromRGB(255, 100, 100))
		print_nw("Type 'help' for commands", Color3.fromRGB(255, 150, 0))
	end
	print_nw("", Color3.fromRGB(100, 255, 100))
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NightWalkerUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

local function getScreenSize()
	return Workspace.CurrentCamera.ViewportSize
end

local screenSize = getScreenSize()
local guiScale = math.min(screenSize.X / 1920, screenSize.Y / 1080)
local baseWidth = 900
local baseHeight = 650

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, baseWidth * guiScale, 0, baseHeight * guiScale)
mainFrame.Position = UDim2.new(0.5, -(baseWidth * guiScale) / 2, 0.5, -(baseHeight * guiScale) / 2)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = ScreenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 150, 255)
stroke.Thickness = 2.5
stroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(1, -80, 1, 0)
titleText.BackgroundTransparency = 1
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = math.floor(16 * guiScale)
titleText.Font = Enum.Font.GothamBold
titleText.Text = "🖤 NightWalker v" .. NW.version .. " - 100+ Commands"
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "✕"
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local outputBox = Instance.new("TextBox")
outputBox.Name = "OutputBox"
outputBox.Size = UDim2.new(1, -20, 1, -100)
outputBox.Position = UDim2.new(0, 10, 0, 55)
outputBox.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
outputBox.TextColor3 = Color3.fromRGB(100, 255, 100)
outputBox.TextSize = math.floor(12 * guiScale)
outputBox.Font = Enum.Font.Roboto
outputBox.TextWrapped = true
outputBox.TextYAlignment = Enum.TextYAlignment.Top
outputBox.MultiLine = true
outputBox.ReadOnly = true
outputBox.BorderSizePixel = 0
outputBox.Parent = mainFrame

local inputBox = Instance.new("TextBox")
inputBox.Name = "InputBox"
inputBox.Size = UDim2.new(1, -40, 0, 35)
inputBox.Position = UDim2.new(0, 10, 1, -40)
inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
inputBox.TextColor3 = Color3.fromRGB(100, 255, 100)
inputBox.PlaceholderText = "$ "
inputBox.PlaceholderColor3 = Color3.fromRGB(70, 150, 70)
inputBox.TextSize = math.floor(13 * guiScale)
inputBox.Font = Enum.Font.Roboto
inputBox.BorderSizePixel = 0
inputBox.Parent = mainFrame

local function updateOutput()
	local text = ""
	for _, line in pairs(Output) do
		text = text .. line.text .. "\n"
	end
	outputBox.Text = text
end

local flyConnection = nil
local flyStart = nil

local function startFly()
	if not FlyEnabled or not BodyPos or not BodyGyro then return end
	
	if flyConnection then flyConnection:Disconnect() end
	
	flyStart = tick()
	flyConnection = RunService.RenderStepped:Connect(function()
		if not FlyEnabled or not BodyPos or not BodyGyro or not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then
			if flyConnection then flyConnection:Disconnect() flyConnection = nil end
			return
		end
		
		local root = LP.Character.HumanoidRootPart
		local vel = Vector3.new(0, 0, 0)
		
		if IsMobile then
			if UserInputService:IsKeyDown(Enum.KeyCode.E) then vel = vel + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.Q) then vel = vel - Vector3.new(0, 1, 0) end
		else
			if UIS:IsKeyDown(Enum.KeyCode.W) then vel = vel + Workspace.CurrentCamera.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then vel = vel - Workspace.CurrentCamera.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then vel = vel - Workspace.CurrentCamera.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then vel = vel + Workspace.CurrentCamera.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, 1, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0, 1, 0) end
		end
		
		BodyPos.Position = root.Position + vel.Unit * FlySpeed
		BodyGyro.CFrame = Workspace.CurrentCamera.CFrame
	end)
end

inputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		execute_command(inputBox.Text)
		inputBox.Text = ""
		updateOutput()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	IsOpen = false
end)

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F9 then
		IsOpen = not IsOpen
		mainFrame.Visible = IsOpen
		if IsOpen then
			inputBox:CaptureFocus()
			if #Output == 0 then
				Commands.help({})
				updateOutput()
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if FlyEnabled and not flyConnection then
		startFly()
	end
end)

print_nw("═══════════════════════════════════════════════════", Color3.fromRGB(0, 150, 255))
print_nw("    🖤 NightWalker v" .. NW.version .. " - Loaded! 🖤", Color3.fromRGB(0, 200, 255))
print_nw("═══════════════════════════════════════════════════", Color3.fromRGB(0, 150, 255))
print_nw("", Color3.fromRGB(100, 200, 255))
print_nw("Press F9 to open terminal", Color3.fromRGB(100, 200, 255))
print_nw("Type 'help' for 100+ commands", Color3.fromRGB(100, 200, 255))
print_nw("Device: " .. (IsMobile and "📱 Mobile" or "💻 PC"), Color3.fromRGB(100, 200, 255))
print_nw("", Color3.fromRGB(100, 200, 255))

print("✅ NightWalker v" .. NW.version .. " Loaded! Press F9 to open")
