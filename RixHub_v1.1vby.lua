local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua", true))()
if not Luna then return end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
if not LP then return end

-- Config System (from OpenSource)
local configFile = "RixHub_Unified_Config.json"
local config = {
	speed = 1.2, jump = 1.3, gravity = 0.5, spinSpeed = 15, flySpeed = 40, platHeight = 8,
	reachDist = 10, espRange = 5000, ballEspRange = 5000, lineDist = 50, fogEnd = 1000,
	bloomIntensity = 0,
	spikePower = 1, diveSpeed = 1, blockPower = 1, bumpPower = 1, servePower = 1,
	jumpPower = 1, setPower = 1, tiltPower = 1,
	spikeHitbox = 10, jumpsetHitbox = 10, setHitbox = 10, serveHitbox = 10,
	diveHitbox = 10, bumpHitbox = 10, blockHitbox = 10,
	autoRotate = false, powerfulServe = false, airMovement = false, autoShiftLock = true
}

local function loadConfig()
	if isfile(configFile) then
		local success, data = pcall(function() return HttpService:JSONDecode(readfile(configFile)) end)
		if success then for k, v in pairs(data) do if config[k] ~= nil then config[k] = v end end end
	end
end
local function saveConfig()
	writefile(configFile, HttpService:JSONEncode(config))
end
loadConfig()

-- Global State
local Connections = {}
local ESPObjects, BallESPObjects, TrajectoryLines, LineData, JumpHighlights = {}, {}, {}, {}, {}
local OriginalBallSizes, OriginalParts = {}, {}
local PlatformPart, ReachCircle, ReachGui, bodyVelocity, LastPos
local CurrentBall, LastBallCheck = nil, 0
local FrameCounter, LastESPUpdate, LastDescUpdate = 0, 0, 0
local AntiCheatEnabled, AutoFarmEnabled, AutoJoinEnabled, PowerfulServeActive, AutoSpinActive = false, false, false, false, false
local ProtectedPlayers, BlockedRemotes = {}, {}
local isRunning = false, escPressed = false

-- Helpers
local function getChar() return LP.Character end
local function getHRP() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") or nil end
local function getHum() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") or nil end
local function disconnect(key)
	if Connections[key] then pcall(function() Connections[key]:Disconnect() end); Connections[key] = nil end
end
local function Notify(title, content)
	pcall(function() Luna:Notification({Title = title, Icon = "info", ImageSource = "Material", Content = content or ""}) end)
end
local function SafeDestroy(obj) pcall(function() if obj and obj.Parent then obj:Destroy() end end) end

-- UI Init
local Window = Luna:CreateWindow({
	Name = "Rix Hub", Subtitle = "Volleyball Legends - Unified", LogoID = "130188918639066",
	LoadingEnabled = true, LoadingTitle = "Rix Hub", LoadingSubtitle = "Loading...",
	ConfigSettings = { RootFolder = nil, ConfigFolder = "RixHub" }, KeySystem = false
})

local TMove = Window:CreateTab({ Name = "Movement", Icon = "directions_run", ImageSource = "Material", ShowTitle = true })
local TCombat = Window:CreateTab({ Name = "Combat & Auto", Icon = "sports_volleyball", ImageSource = "Material", ShowTitle = true })
local TVisual = Window:CreateTab({ Name = "Visuals", Icon = "visibility", ImageSource = "Material", ShowTitle = true })
local TProtect = Window:CreateTab({ Name = "Protection", Icon = "security", ImageSource = "Material", ShowTitle = true })
local TAbout = Window:CreateTab({ Name = "About", Icon = "info", ImageSource = "Material", ShowTitle = true })

-- ================= MOVEMENT =================
TMove:CreateToggle({ Name = "Speed Boost", CurrentValue = false, Callback = function(v)
	disconnect("Speed")
	if v then
		local hum = getHum(); if hum then hum.WalkSpeed = 16 * config.speed end
		Connections.Speed = RunService.Heartbeat:Connect(function()
			local hum = getHum(); if hum and hum.WalkSpeed ~= 16 * config.speed then hum.WalkSpeed = 16 * config.speed end
		end); Notify("Speed Boost", "x" .. string.format("%.1f", config.speed))
	else local hum = getHum(); if hum then hum.WalkSpeed = 16 end; Notify("Speed", "Off") end
end })
TMove:CreateSlider({ Name = "Speed Multiplier", Range = {1, 2.5}, Increment = 0.1, CurrentValue = config.speed, Callback = function(v) config.speed = v; saveConfig() end })

TMove:CreateToggle({ Name = "Jump Boost", CurrentValue = false, Callback = function(v)
	disconnect("Jump")
	if v then
		local hum = getHum(); if hum then hum.JumpHeight = 7.2 * config.jump end
		Connections.Jump = RunService.Heartbeat:Connect(function()
			local hum = getHum(); if hum and hum.JumpHeight ~= 7.2 * config.jump then hum.JumpHeight = 7.2 * config.jump end
		end); Notify("Jump Boost", "x" .. string.format("%.1f", config.jump))
	else local hum = getHum(); if hum then hum.JumpHeight = 7.2 end; Notify("Jump", "Off") end
end })
TMove:CreateSlider({ Name = "Jump Multiplier", Range = {1, 2.5}, Increment = 0.1, CurrentValue = config.jump, Callback = function(v) config.jump = v; saveConfig() end })

TMove:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Callback = function(v)
	disconnect("InfiniteJump"); disconnect("InfiniteJumpEnded")
	if v then
		local jumping = false
		Connections.InfiniteJump = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe or input.KeyCode ~= Enum.KeyCode.Space or jumping then return end
			jumping = true
			local hrp, hum = getHRP(), getHum()
			if hrp and hum then
				if hum.FloorMaterial == Enum.Material.Air then
					local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(0, math.huge, 0); bv.Velocity = Vector3.new(0, 30, 0); bv.Parent = hrp
					game:GetService("Debris"):AddItem(bv, 0.1)
				end
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
		Connections.InfiniteJumpEnded = UserInputService.InputEnded:Connect(function(input) if input.KeyCode == Enum.KeyCode.Space then jumping = false end end)
		Notify("Infinite Jump", "On")
	else Notify("Infinite Jump", "Off") end
end })

TMove:CreateToggle({ Name = "Gravity Mod", CurrentValue = false, Callback = function(v)
	disconnect("Gravity")
	if v then
		Connections.Gravity = RunService.Heartbeat:Connect(function()
			local hrp = getHRP(); if hrp and hrp.Velocity.Y < -5 then
				hrp.Velocity = Vector3.new(hrp.Velocity.X, hrp.Velocity.Y * config.gravity, hrp.Velocity.Z)
			end
		end); Notify("Gravity Mod", "x" .. string.format("%.1f", config.gravity))
	else Notify("Gravity Mod", "Off") end
end })
TMove:CreateSlider({ Name = "Gravity Multiplier", Range = {0.1, 1}, Increment = 0.1, CurrentValue = config.gravity, Callback = function(v) config.gravity = v; saveConfig() end })

TMove:CreateToggle({ Name = "Anti Stun", CurrentValue = false, Callback = function(v)
	disconnect("AntiStun")
	if v then
		Connections.AntiStun = RunService.Heartbeat:Connect(function()
			local hum = getHum(); if hum then
				if hum.PlatformStand then hum.PlatformStand = false end
				local state = hum:GetState()
				if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll then
					hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end
		end); Notify("Anti Stun", "On")
	else Notify("Anti Stun", "Off") end
end })

TMove:CreateToggle({ Name = "Anti Ragdoll", CurrentValue = false, Callback = function(v)
	disconnect("AntiRagdoll")
	if v then
		Connections.AntiRagdoll = RunService.Heartbeat:Connect(function()
			local char = getChar(); if not char then return end
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BallSocketConstraint") or part:IsA("HingeConstraint") then SafeDestroy(part) end
			end
			local hum = getHum(); if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
		end); Notify("Anti Ragdoll", "On")
	else Notify("Anti Ragdoll", "Off") end
end })

TMove:CreateToggle({ Name = "Spin Mod", CurrentValue = false, Callback = function(v)
	disconnect("Spin")
	if v then
		Connections.Spin = RunService.Heartbeat:Connect(function()
			local hrp = getHRP(); if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(config.spinSpeed), 0) end
		end); Notify("Spin Mod", "Speed " .. config.spinSpeed)
	else Notify("Spin Mod", "Off") end
end })
TMove:CreateSlider({ Name = "Spin Speed", Range = {1, 150}, Increment = 1, CurrentValue = config.spinSpeed, Callback = function(v) config.spinSpeed = v; saveConfig() end })

TMove:CreateToggle({ Name = "Fly Mode", CurrentValue = false, Callback = function(v)
	disconnect("Fly"); SafeDestroy(bodyVelocity); bodyVelocity = nil
	if v then
		local hrp = getHRP(); if hrp then
			bodyVelocity = Instance.new("BodyVelocity"); bodyVelocity.MaxForce = Vector3.new(9e5, 9e5, 9e5); bodyVelocity.Parent = hrp
		end
		Connections.Fly = RunService.Heartbeat:Connect(function()
			local hrp = getHRP(); if not hrp or not bodyVelocity then return end
			local moveDir = Vector3.new(0, 0, 0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + hrp.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - hrp.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - hrp.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + hrp.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
			bodyVelocity.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * config.flySpeed or Vector3.new(0, 0, 0)
		end); Notify("Fly Mode", "WASD+Space/Ctrl")
	else Notify("Fly Mode", "Off") end
end })
TMove:CreateSlider({ Name = "Fly Speed", Range = {10, 80}, Increment = 1, CurrentValue = config.flySpeed, Callback = function(v) config.flySpeed = v; saveConfig() end })

TMove:CreateToggle({ Name = "Air Movement (Freeflight)", CurrentValue = config.airMovement, Callback = function(v)
	config.airMovement = v; saveConfig()
	if v then
		local hrp = getHRP(); if hrp then
			bodyVelocity = Instance.new("BodyVelocity"); bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5); bodyVelocity.Velocity = Vector3.zero; bodyVelocity.Parent = hrp
		end
		Connections.AirMove = RunService.RenderStepped:Connect(function()
			if config.airMovement and bodyVelocity and getHum() then
				bodyVelocity.Velocity = getHum().MoveDirection * 16
			end
		end); Notify("Air Movement", "On")
	else disconnect("AirMove"); SafeDestroy(bodyVelocity); Notify("Air Movement", "Off") end
end })

TMove:CreateToggle({ Name = "Auto Shift Lock", CurrentValue = config.autoShiftLock, Callback = function(v)
	config.autoShiftLock = v; saveConfig()
	if v then Notify("Auto Shift Lock", "On") else Notify("Auto Shift Lock", "Off") end
end })

-- ================= COMBAT & AUTO =================
TCombat:CreateToggle({ Name = "Ball Hitbox (Client)", CurrentValue = false, Callback = function(v)
	disconnect("BallHitbox")
	if v then
		local function findBall()
			local now = tick(); if now - LastBallCheck < 0.5 and CurrentBall and CurrentBall.Parent then return CurrentBall end
			LastBallCheck = now; CurrentBall = nil
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("BasePart") and (obj.Name:lower():find("ball") or obj.Name:lower():find("volleyball")) then CurrentBall = obj; break end
			end
			return CurrentBall
		end
		Connections.BallHitbox = RunService.Heartbeat:Connect(function()
			local ball = findBall(); if not ball then return end
			if not OriginalBallSizes[ball] then OriginalBallSizes[ball] = ball.Size end
			ball.Size = OriginalBallSizes[ball] * 3; ball.Transparency = 0.3; ball.Material = Enum.Material.Neon; ball.Color = Color3.fromRGB(255, 0, 100)
		end); Notify("Ball Hitbox", "On")
	else
		for b, s in pairs(OriginalBallSizes) do if b and b.Parent then b.Size = s; b.Transparency = 0; b.Material = Enum.Material.Plastic; b.Color = Color3.new(1,1,1) end end
		OriginalBallSizes = {}; Notify("Ball Hitbox", "Off")
	end
end })

TCombat:CreateToggle({ Name = "CLIENT_BALL Hitbox", CurrentValue = false, Callback = function(v)
	disconnect("ClientBallHitbox")
	if v then
		local function updateHitboxes(scale)
			for _, m in ipairs(Workspace:GetChildren()) do
				if m:IsA("Model") and m.Name:match("^CLIENT_BALL_%d+$") then
					local ball = m:FindFirstChild("Ball.001") or m:FindFirstChild("Sphere.001")
					if not ball then
						local part = m:FindFirstChildWhichIsA("BasePart")
						if part then ball = Instance.new("Part"); ball.Name = "Ball.001"; ball.Shape = Enum.PartType.Ball; ball.Size = Vector3.new(2,2,2)*scale; ball.CFrame = part.CFrame; ball.Anchored = true; ball.CanCollide = false; ball.Transparency = 0.7; ball.Parent = m end
					end
					if ball then ball.Size = Vector3.new(2,2,2) * scale end
				end
			end
		end
		Connections.ClientBallHitbox = RunService.Heartbeat:Connect(function() updateHitboxes(5) end)
		Notify("CLIENT_BALL Hitbox", "On")
	else
		for _, m in ipairs(Workspace:GetChildren()) do
			if m:IsA("Model") and m.Name:match("^CLIENT_BALL_%d+$") then
				local b = m:FindFirstChild("Ball.001") or m:FindFirstChild("Sphere.001"); if b then b:Destroy() end
			end
		end
		Notify("CLIENT_BALL Hitbox", "Off")
	end
end })

TCombat:CreateToggle({ Name = "Auto Farm", CurrentValue = false, Callback = function(v)
	AutoFarmEnabled = v; Notify("Auto Farm", v and "Enabled" or "Disabled")
end })
TCombat:CreateToggle({ Name = "Auto Join Match", CurrentValue = false, Callback = function(v)
	AutoJoinEnabled = v; Notify("Auto Join", v and "Enabled" or "Disabled")
end })
TCombat:CreateToggle({ Name = "Enable Powerful Serve (Z)", CurrentValue = config.powerfulServe, Callback = function(v)
	config.powerfulServe = v; PowerfulServeActive = v; saveConfig(); Notify("Powerful Serve", v and "Enabled (Press Z)" or "Disabled")
end })
TCombat:CreateToggle({ Name = "Enable Rotate In Air", CurrentValue = config.autoRotate, Callback = function(v)
	config.autoRotate = v; saveConfig()
	if v then
		Connections.AutoRotate = RunService.Heartbeat:Connect(function()
			local hum = getHum(); if hum and not hum.AutoRotate then hum.AutoRotate = true end
		end); Notify("Auto Rotate", "On")
	else disconnect("AutoRotate"); Notify("Auto Rotate", "Off") end
end })

TCombat:CreateSection("Stat Multipliers")
local function statSlider(name, attr, default)
	TCombat:CreateSlider({ Name = name, Range = {0, 500}, Increment = 0.1, CurrentValue = config[name] or default, Callback = function(v)
		config[name] = v; saveConfig(); LP:SetAttribute("Game" .. attr .. "Multiplier", v)
	end })
end
statSlider("Dive Speed", "DiveSpeed", 1)
statSlider("Spike Power", "SpikePower", 1)
statSlider("Tilt Power", "TiltPower", 1)
statSlider("Speed", "Speed", 1)
statSlider("Set Power", "SetPower", 1)
statSlider("Serve Power", "ServePower", 1)
statSlider("Jump Power", "JumpPower", 1)
statSlider("Bump Power", "BumpPower", 1)
statSlider("Block Power", "BlockPower", 1)

TCombat:CreateSection("Action Hitboxes")
local function hitboxSlider(name, path)
	TCombat:CreateSlider({ Name = name .. " Hitbox", Range = {1, 100}, Increment = 0.1, CurrentValue = config[name:lower():gsub(" ","").."Hitbox"] or 10, Callback = function(v)
		local folder = ReplicatedStorage:FindFirstChild(path); if not folder then return end
		local part = folder:FindFirstChild("Part"); if part and part:IsA("BasePart") then part.Size = Vector3.new(v,v,v) end
		config[name:lower():gsub(" ","").."Hitbox"] = v; saveConfig()
	end })
end
hitboxSlider("Spike", "Assets/Hitboxes/Spike")
hitboxSlider("JumpSet", "Assets/Hitboxes/JumpSet")
hitboxSlider("Set", "Assets/Hitboxes/Set")
hitboxSlider("Serve", "Assets/Hitboxes/Serve")
hitboxSlider("Dive", "Assets/Hitboxes/Dive")
hitboxSlider("Bump", "Assets/Hitboxes/Bump")
hitboxSlider("Block", "Assets/Hitboxes/Block")

TCombat:CreateButton({ Name = "Break The Match", Callback = function()
	pcall(function() ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.GameService.RF.Serve:InvokeServer(nil, 0.95) end)
	Notify("Break Match", "Executed")
end })

TCombat:CreateDropdown({ Name = "Auto Spin Style", Options = {"Oikawa", "Bokuto", "Kageyama", "Sawamura", "Ushijima", "Kozume", "Kuroo", "Yamamoto", "Azumane", "Yaku", "Hinata"}, CurrentOption = {"Hinata"}, MultipleOptions = true, Callback = function(opts)
	local desiredStyles = opts
	Connections.AutoSpin = Connections.AutoSpin or nil
	TCombat:CreateToggle({ Name = "Auto Spin", CurrentValue = false, Callback = function(v)
		AutoSpinActive = v; if v then
			coroutine.wrap(function()
				while AutoSpinActive do
					local gui = LP.PlayerGui:FindFirstChild("Interface") and LP.PlayerGui.Interface:FindFirstChild("Lobby")
					local styleTxt = gui and gui:FindFirstChild("Styles") and gui.Styles:FindFirstChild("TopPanel") and gui.Styles.TopPanel:FindFirstChild("DisplayName")
					if styleTxt then
						local cur = styleTxt.Text
						if table.find(desiredStyles, cur) then
							AutoSpinActive = false; Notify("Style Obtained!", cur); break
						end
					end
					pcall(function() ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.StylesService.RF.Roll:InvokeServer(false) end)
					task.wait(0.5)
				end
			end)()
		end
	end })
end })

-- ================= VISUALS =================
TVisual:CreateToggle({ Name = "Player ESP", CurrentValue = false, Callback = function(v)
	for _, bb in pairs(ESPObjects) do SafeDestroy(bb) end; ESPObjects = {}; disconnect("ESPUpdate")
	if v then
		local function createESP(p)
			if p == LP or not p.Character then return end
			local hrp = p.Character:FindFirstChild("HumanoidRootPart"); local myHRP = getHRP()
			if hrp and myHRP and (hrp.Position - myHRP.Position).Magnitude <= config.espRange then
				local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(8,0,4,0); bb.MaxDistance = config.espRange; bb.Adornee = hrp; bb.AlwaysOnTop = true; bb.Name = "RixESP_"..p.Name
				local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,0,1,0); frame.BackgroundTransparency = 0.1; frame.BorderSizePixel = 0; frame.Parent = bb
				local g = Instance.new("UIGradient"); g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0,1,0.8)), ColorSequenceKeypoint.new(1,Color3.new(0,0.4,1))}); g.Rotation = 45; g.Parent = frame
				local lbl = Instance.new("TextLabel"); lbl.Parent = frame; lbl.Size = UDim2.new(1,0,0.5,0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 16; lbl.Text = p.Name
				local dLbl = Instance.new("TextLabel"); dLbl.Parent = frame; dLbl.Size = UDim2.new(1,0,0.5,0); dLbl.Position = UDim2.new(0,0,0.5,0); dLbl.BackgroundTransparency = 1; dLbl.TextColor3 = Color3.new(0.8,1,1); dLbl.Font = Enum.Font.GothamBold; dLbl.TextSize = 14; dLbl.Text = math.floor((hrp.Position-myHRP.Position).Magnitude).."m"
				Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8); bb.Parent = Workspace; ESPObjects[p] = bb
			end
		end
		for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
		Connections.ESPUpdate = RunService.Heartbeat:Connect(function()
			FrameCounter = FrameCounter + 1; if FrameCounter % 3 ~= 0 then return end
			local now = tick(); if now - LastESPUpdate < 0.5 then return end; LastESPUpdate = now
			local myHRP = getHRP(); if not myHRP then return end
			for p, bb in pairs(ESPObjects) do
				if p.Character and bb then
					local hrp = p.Character:FindFirstChild("HumanoidRootPart"); if hrp then
						local dLbl = bb:FindFirstChild("Frame", true) and bb:FindFirstChild("Frame", true):FindFirstChild("TextLabel", true)
						if dLbl then dLbl.Text = math.floor((hrp.Position-myHRP.Position).Magnitude).."m" end
					end
				end
			end
		end); Notify("Player ESP", "On")
	else Notify("Player ESP", "Off") end
end })
TVisual:CreateSlider({ Name = "ESP Range", Range = {100, 10000}, Increment = 100, CurrentValue = config.espRange, Callback = function(v) config.espRange = v; saveConfig() end })

TVisual:CreateToggle({ Name = "Ball ESP", CurrentValue = false, Callback = function(v)
	for _, bb in pairs(BallESPObjects) do SafeDestroy(bb) end; BallESPObjects = {}; disconnect("BallESPUpdate")
	if v then
		local function createBallESP(ball)
			if not ball or not ball:IsA("BasePart") then return end
			local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(10,0,5,0); bb.MaxDistance = config.ballEspRange; bb.Adornee = ball; bb.AlwaysOnTop = true; bb.Name = "RixBallESP"
			local frame = Instance.new("Frame"); frame.Size = UDim2.new(1,0,1,0); frame.BackgroundTransparency = 0.05; frame.BackgroundColor3 = Color3.fromRGB(255,50,50); frame.Parent = bb
			local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(Color3.fromRGB(255,50,50), Color3.fromRGB(255,150,0)); g.Rotation = 45; g.Parent = frame
			local lbl = Instance.new("TextLabel"); lbl.Parent = frame; lbl.Size = UDim2.new(1,0,0.5,0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 18; lbl.Text = "BALL"
			local vLbl = Instance.new("TextLabel"); vLbl.Parent = frame; vLbl.Size = UDim2.new(1,0,0.5,0); vLbl.Position = UDim2.new(0,0,0.5,0); vLbl.BackgroundTransparency = 1; vLbl.TextColor3 = Color3.new(1,1,0.8); vLbl.Font = Enum.Font.GothamBold; vLbl.TextSize = 14; vLbl.Text = "Speed: " .. math.floor(ball.Velocity.Magnitude)
			Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10); Instance.new("UIStroke", frame).Color = Color3.fromRGB(255,100,100); bb.Parent = Workspace; BallESPObjects[ball] = bb
		end
		local ball = Workspace:FindFirstChild("Ball") or Workspace:FindFirstChild("Volleyball"); if ball then createBallESP(ball) end
		Connections.BallESPUpdate = RunService.Heartbeat:Connect(function()
			local b = Workspace:FindFirstChild("Ball") or Workspace:FindFirstChild("Volleyball")
			if b and not BallESPObjects[b] then createBallESP(b) end
			for ball, bb in pairs(BallESPObjects) do
				if ball and ball.Parent and bb then
					local vLbl = bb:FindFirstChild("Frame", true) and bb:FindFirstChild("Frame", true):FindFirstChild("TextLabel", true)
					if vLbl then vLbl.Text = "Speed: " .. math.floor(ball.Velocity.Magnitude) end
				else SafeDestroy(bb); BallESPObjects[ball] = nil end
			end
		end); Notify("Ball ESP", "On")
	else Notify("Ball ESP", "Off") end
end })

TVisual:CreateToggle({ Name = "Ball Trajectory", CurrentValue = false, Callback = function(v)
	disconnect("Trajectory"); for _, l in ipairs(TrajectoryLines) do SafeDestroy(l) end; TrajectoryLines = {}
	if v then
		Connections.Trajectory = RunService.Heartbeat:Connect(function()
			FrameCounter = FrameCounter + 1; if FrameCounter % 2 ~= 0 then return end
			local ball = Workspace:FindFirstChild("Ball") or Workspace:FindFirstChild("Volleyball"); if not ball then return end
			local start = ball.Position; local vel = ball.Velocity; local grav = Workspace.Gravity; local pts = {}
			for t = 0, 3, 0.15 do table.insert(pts, start + vel*t + Vector3.new(0, -0.5*grav*t*t, 0)) end
			for i = 1, #pts-1 do
				local line = Instance.new("Part"); line.Name = "RixTrajectory"; line.Anchored = true; line.CanCollide = false
				line.Size = Vector3.new(0.3,0.3,(pts[i]-pts[i+1]).Magnitude); line.CFrame = CFrame.lookAt(pts[i], pts[i+1])*CFrame.new(0,0,-line.Size.Z/2)
				line.Color = Color3.fromRGB(255,100,100); line.Material = Enum.Material.Neon; line.Transparency = 0.3; line.Parent = Workspace
				table.insert(TrajectoryLines, line)
			end
		end); Notify("Ball Trajectory", "On")
	else Notify("Ball Trajectory", "Off") end
end })

TVisual:CreateToggle({ Name = "Reach Circle", CurrentValue = false, Callback = function(v)
	if v then
		ReachGui = Instance.new("ScreenGui"); ReachGui.Name = "RixReachGui"; ReachGui.ResetOnSpawn = false; ReachGui.IgnoreGuiInset = true; ReachGui.Parent = LP.PlayerGui
		ReachCircle = Instance.new("Frame"); ReachCircle.Name = "ReachCircle"; ReachCircle.AnchorPoint = Vector2.new(0.5,0.5); ReachCircle.Position = UDim2.new(0.5,0,0.5,0); ReachCircle.Size = UDim2.new(0, config.reachDist*8, 0, config.reachDist*8)
		ReachCircle.BackgroundTransparency = 0.85; ReachCircle.BackgroundColor3 = Color3.fromRGB(0,255,200); ReachCircle.BorderSizePixel = 0; ReachCircle.Parent = ReachGui
		Instance.new("UICorner", ReachCircle).CornerRadius = UDim.new(1,0)
		Instance.new("UIStroke", ReachCircle).Color = Color3.fromRGB(0,255,200)
		local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,0,0,20); lbl.Position = UDim2.new(0,0,1,5); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(0,255,200); lbl.Font = Enum.Font.GothamBold; lbl.Text = config.reachDist.." studs"; lbl.Parent = ReachCircle
		Notify("Reach Circle", "On")
	else SafeDestroy(ReachGui); ReachCircle = nil; ReachGui = nil; Notify("Reach Circle", "Off") end
end })
TVisual:CreateSlider({ Name = "Reach Distance", Range = {5, 50}, Increment = 1, CurrentValue = config.reachDist, Callback = function(v)
	config.reachDist = v; saveConfig()
	if ReachCircle then ReachCircle.Size = UDim2.new(0, v*8, 0, v*8); local l = ReachCircle:FindFirstChild("TextLabel"); if l then l.Text = v.." studs" end end
end })

TVisual:CreateToggle({ Name = "Xray Vision", CurrentValue = false, Callback = function(v)
	if v then
		for _, part in ipairs(Workspace:GetDescendants()) do
			if part:IsA("BasePart") and not part:IsDescendantOf(LP.Character) and part.Name ~= "RixPlatform" and part.Name ~= "RixTrajectory" then
				if OriginalParts[part] == nil then OriginalParts[part] = part.Transparency end
				part.Transparency = 0.4
			end
		end; Notify("Xray", "On")
	else for p, t in pairs(OriginalParts) do if p and p.Parent then p.Transparency = t end end; OriginalParts = {}; Notify("Xray", "Off") end
end })

TVisual:CreateToggle({ Name = "Fullbright", CurrentValue = false, Callback = function(v)
	if v then Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.GlobalShadows = false; Notify("Fullbright", "On")
	else Lighting.Ambient = Color3.fromRGB(128,128,128); Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128); Lighting.GlobalShadows = true; Notify("Fullbright", "Off") end
end })

TVisual:CreateToggle({ Name = "Night Mode", CurrentValue = false, Callback = function(v)
	if v then Lighting.Ambient = Color3.fromRGB(20,20,20); Notify("Night Mode", "On")
	else Lighting.Ambient = Color3.fromRGB(128,128,128); Notify("Night Mode", "Off") end
end })

TVisual:CreateSlider({ Name = "Fog End", Range = {0, 1000}, Increment = 50, CurrentValue = config.fogEnd, Callback = function(v) config.fogEnd = v; Lighting.FogEnd = v; saveConfig() end })
TVisual:CreateSlider({ Name = "Bloom Intensity", Range = {0, 5}, Increment = 0.1, CurrentValue = config.bloomIntensity, Callback = function(v)
	config.bloomIntensity = v; local b = Lighting:FindFirstChild("BloomEffect") or Instance.new("BloomEffect", Lighting); b.Intensity = v; saveConfig()
end })

TVisual:CreateToggle({ Name = "Enemy Lines", CurrentValue = false, Callback = function(v)
	if v then
		for idx, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Team and LP.Team and p.Team ~= LP.Team and p.Character and p.Character:FindFirstChild("Head") then
				local attach = Instance.new("Attachment", p.Character.Head)
				local target = Instance.new("Part"); target.Anchored = true; target.CanCollide = false; target.Transparency = 1; target.Size = Vector3.new(0.1,0.1,0.1); target.Parent = Workspace
				local tAttach = Instance.new("Attachment", target)
				local beam = Instance.new("Beam"); beam.Attachment0 = attach; beam.Attachment1 = tAttach; beam.Width0 = 0.25; beam.Width1 = 0.25; beam.FaceCamera = true; beam.LightEmission = 1; beam.Transparency = NumberSequence.new(0.3)
				local colors = {Color3.new(1,0,0), Color3.new(0,1,0), Color3.new(0,0,1), Color3.new(1,0.65,0)}; beam.Color = ColorSequence.new(colors[idx % 4 + 1]); beam.Parent = p.Character.Head
				LineData[p] = {beam=beam, target=target}
			end
		end
		Connections.Lines = RunService.RenderStepped:Connect(function()
			for p, data in pairs(LineData) do
				if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					data.target.Position = p.Character.Head.Position + p.Character.HumanoidRootPart.CFrame.LookVector * config.lineDist
				end
			end
		end); Notify("Enemy Lines", "On")
	else
		for p, d in pairs(LineData) do if d.beam then SafeDestroy(d.beam.Parent) end; if d.target then SafeDestroy(d.target) end end
		LineData = {}; Notify("Enemy Lines", "Off")
	end
end })
TVisual:CreateSlider({ Name = "Line Distance", Range = {0, 100}, Increment = 10, CurrentValue = config.lineDist, Callback = function(v) config.lineDist = v; saveConfig() end })

TVisual:CreateToggle({ Name = "Jump ESP (Highlight)", CurrentValue = false, Callback = function(v)
	if v then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then
				local hum = p.Character:WaitForChild("Humanoid", 2)
				if hum then
					local con = hum.StateChanged:Connect(function(_, newState)
						if v and (newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall) and p ~= LP then
							if not JumpHighlights[p] then
								local hl = Instance.new("Highlight"); hl.Adornee = p.Character; hl.FillTransparency = 1; hl.OutlineColor = Color3.new(1,1,0); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = p.Character
								JumpHighlights[p] = hl
							end
						elseif JumpHighlights[p] then
							SafeDestroy(JumpHighlights[p]); JumpHighlights[p] = nil
						end
					end)
					JumpHighlights[p] = JumpHighlights[p] or {con = con}
				end
			end
		end
		Notify("Jump ESP", "On")
	else for p, hl in pairs(JumpHighlights) do if type(hl) == "Instance" then SafeDestroy(hl) end; JumpHighlights[p] = nil end; Notify("Jump ESP", "Off") end
end })

-- ================= PROTECTION =================
TProtect:CreateToggle({ Name = "Anti Cheat Bypass", CurrentValue = false, Callback = function(v)
	AntiCheatEnabled = v
	if v then
		pcall(function()
			local mt = getrawmetatable(game); if not mt then return end
			local old = mt.__namecall; setreadonly(mt, false)
			mt.__namecall = newcclosure(function(self, ...)
				local method = getnamecallmethod(); if method == "FireServer" or method == "InvokeServer" then
					local name = tostring(self):lower()
					if name:find("kick") or name:find("ban") or name:find("report") or name:find("ac") or name:find("anti") or name:find("cheat") or name:find("detect") or name:find("bac") or name:find("hack") or name:find("exploit") or name:find("flag") or name:find("log") or name:find("punish") or name:find("moderate") or name:find("security") or name:find("stun") or name:find("ragdoll") or name:find("verify") or name:find("validate") or name:find("check") then
						if not BlockedRemotes[tostring(self)] then BlockedRemotes[tostring(self)] = true; Notify("AC Bypass", "Blocked: "..tostring(self)) end
						return nil
					end
				end
				return old(self, ...)
			end); setreadonly(mt, true)
		end)
		Notify("Anti Cheat", "Multi-Stage Bypass Active")
	else Notify("Anti Cheat", "Off") end
end })

TProtect:CreateToggle({ Name = "Anti Kick", CurrentValue = false, Callback = function(v)
	if v then
		pcall(function()
			if hookfunction then
				local old = hookfunction(LP.Kick, function(self, ...)
					if self == LP then Notify("Anti Kick", "Blocked"); return nil end
					return old(self, ...)
				end)
			end
		end)
		Notify("Anti Kick", "On")
	else Notify("Anti Kick", "Off") end
end })

TProtect:CreateToggle({ Name = "Anti Teleport", CurrentValue = false, Callback = function(v)
	disconnect("AntiTP"); LastPos = getHRP() and getHRP().Position or Vector3.new(0,0,0)
	if v then
		Connections.AntiTP = RunService.Heartbeat:Connect(function()
			local hrp = getHRP(); if not hrp then return end
			local dist = (hrp.Position - LastPos).Magnitude
			if dist > 150 then hrp.CFrame = CFrame.new(LastPos) else LastPos = hrp.Position end
		end); Notify("Anti TP", "On")
	else Notify("Anti TP", "Off") end
end })

TProtect:CreateToggle({ Name = "Anti AFK", CurrentValue = false, Callback = function(v)
	disconnect("AntiAFK")
	if v then
		Connections.AntiAFK = RunService.Heartbeat:Connect(function() game:GetService("VirtualUser"):CaptureController(); game:GetService("VirtualUser"):ClickButton2(Vector2.new()) end)
		Notify("Anti AFK", "On")
	else Notify("Anti AFK", "Off") end
end })

TProtect:CreateButton({ Name = "Protect All Players", Callback = function()
	for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then ProtectedPlayers[p.Name] = true end end
	Notify("Player Protect", "All players protected")
end })

TProtect:CreateButton({ Name = "PANIC (Turn Off All)", Callback = function()
	for k in pairs(Connections) do disconnect(k) end
	for _, v in pairs(ESPObjects) do SafeDestroy(v) end; ESPObjects = {}
	for _, v in pairs(BallESPObjects) do SafeDestroy(v) end; BallESPObjects = {}
	for _, v in ipairs(TrajectoryLines) do SafeDestroy(v) end; TrajectoryLines = {}
	for _, v in pairs(LineData) do if v.beam then SafeDestroy(v.beam.Parent) end; if v.target then SafeDestroy(v.target) end end; LineData = {}
	for _, v in pairs(JumpHighlights) do if type(v) == "Instance" then SafeDestroy(v) end end; JumpHighlights = {}
	SafeDestroy(ReachGui); ReachCircle = nil; ReachGui = nil
	SafeDestroy(PlatformPart); PlatformPart = nil; SafeDestroy(bodyVelocity); bodyVelocity = nil
	Lighting.Ambient = Color3.fromRGB(128,128,128); Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128); Lighting.GlobalShadows = true; Lighting.FogEnd = 1000
	for p, t in pairs(OriginalParts) do if p and p.Parent then p.Transparency = t end end; OriginalParts = {}
	for b, s in pairs(OriginalBallSizes) do if b and b.Parent then b.Size = s; b.Transparency = 0; b.Material = Enum.Material.Plastic; b.Color = Color3.new(1,1,1) end end; OriginalBallSizes = {}
	local hum = getHum(); if hum then hum.WalkSpeed = 16; hum.JumpHeight = 7.2 end
	Notify("Panic", "All features disabled")
end })

-- ================= ABOUT =================
TAbout:CreateLabel({ Text = "Rix Hub v2.0 (Unified)", Style = 1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "Volleyball Legends Edition", Style = 2 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "Player: " .. LP.Name, Style = 1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "Merged Features: RixHub + ZeckHub + OpenSource", Style = 1 })
TAbout:CreateLabel({ Text = "All stats, hitboxes, visuals, auto-farm & protection included.", Style = 1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "PC & Mobile Optimized", Style = 1 })

-- ================= EVENTS & LOOPS =================
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Z and PowerfulServeActive then
		pcall(function() ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.GameService.RF.Serve:InvokeServer(Vector3.new(0,0,0), math.huge) end)
	end
end)

LP.CharacterAdded:Connect(function()
	task.wait(1)
	local hum = getHum(); if hum then hum.WalkSpeed = 16; hum.JumpHeight = 7.2 end
	if LastPos then LastPos = getHRP() and getHRP().Position or Vector3.new(0,0,0) end
	if AntiCheatEnabled then task.delay(2, function() AntiCheatEnabled = true end) end
end)

Players.PlayerAdded:Connect(function(p)
	if AntiCheatEnabled and p ~= LP then ProtectedPlayers[p.Name] = true end
end)

CoreGui.ChildAdded:Connect(function(child)
	if child:IsA("ScreenGui") and child.Name == "ErrorPrompt" then task.wait(2); TeleportService:Teleport(game.PlaceId, LP) end
end)

-- Auto Farm Loop
task.spawn(function()
	while task.wait(0.3) do
		if not AutoFarmEnabled then continue end
		local ball = Workspace:FindFirstChild("Ball") or Workspace:FindFirstChild("Volleyball")
		if ball then
			local hum = getHum(); local hrp = getHRP()
			if hum and hrp then
				hum:MoveTo(ball.Position)
				local dist = (ball.Position - hrp.Position).Magnitude
				if dist <= 15 and ball.Position.Y > hrp.Position.Y + 5 then
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
					task.wait(0.1); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
					VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
					VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
				end
			end
		end
	end
end)

-- Auto Join Loop
task.spawn(function()
	while task.wait(1) do
		if not AutoJoinEnabled then continue end
		local gui = LP.PlayerGui:FindFirstChild("Interface")
		if gui and gui:FindFirstChild("TeamSelection") and not gui:FindFirstChild("Game"):IsA("ScreenGui") then
			gui.TeamSelection.Visible = true
			local btn = gui.TeamSelection:FindFirstChild("2") and gui.TeamSelection["2"]:FindFirstChild(tostring(math.random(1,6)))
			if btn and btn:IsA("ImageButton") then
				local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
				VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
				task.wait(0.1)
				VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
			end
		end
	end
end)