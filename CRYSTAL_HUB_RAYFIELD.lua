local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local State = {
	ESPPlayers = false,
	ESPBall = false,
	BallTrajectory = false,
	SpeedBoost = false,
	SpeedValue = 35,
	DoubleJump = false,
	AntiRagdoll = false,
	SpinBot = false,
	HitboxMultiplier = 1,
}

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "_CrystalESP"
ESPFolder.Parent = Workspace

local TrajectoryFolder = Instance.new("Folder")
TrajectoryFolder.Name = "_CrystalTrajectory"
TrajectoryFolder.Parent = Workspace

local BallCache = nil
local BallCacheTime = 0

local function safeCall(fn, ...)
	local ok, result = pcall(fn, ...)
	return ok and result or nil
end

local function getChar()
	return LP and LP.Character or nil
end

local function getHRP()
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart") or nil
end

local function getHum()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid") or nil
end

local function findBall()
	if BallCache and BallCache.Parent and (tick() - BallCacheTime) < 1 then
		return BallCache
	end

	local attempts = {
		function()
			local names = {"Ball", "TennisBall", "DefaultTennisBall", "tennis_ball", "NetBall", "GameBall"}
			for _, n in ipairs(names) do
				local b = Workspace:FindFirstChild(n, true)
				if b and b:IsA("BasePart") then return b end
			end
		end,
		function()
			for _, v in ipairs(Workspace:GetDescendants()) do
				if (v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("SpecialMesh")) then
					local n = v.Name:lower()
					if n:find("ball") and not n:find("shadow") and not n:find("hitbox") and not n:find("region") then
						local s = v.Size
						if s.Magnitude < 3 then return v end
					end
				end
			end
		end,
		function()
			for _, v in ipairs(Workspace:GetDescendants()) do
				if v:IsA("BasePart") and not v.Anchored then
					local s = v.Size
					if s.X < 1.5 and s.Y < 1.5 and s.Z < 1.5 and s.X > 0.05 then
						if math.abs(s.X - s.Y) < 0.05 and math.abs(s.Y - s.Z) < 0.05 then
							return v
						end
					end
				end
			end
		end,
	}

	for _, fn in ipairs(attempts) do
		local result = safeCall(fn)
		if result then
			BallCache = result
			BallCacheTime = tick()
			return result
		end
	end

	BallCache = nil
	return nil
end

local PlayerESPData = {}

local function makeESPFor(player)
	if player == LP then return end
	if PlayerESPData[player] then return end

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(5, 0, 2.5, 0)
	bb.MaxDistance = 600
	bb.AlwaysOnTop = true
	bb.Enabled = false
	bb.Parent = ESPFolder

	local frame = Instance.new("Frame", bb)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(0, 255, 150)
	stroke.Thickness = 1.5

	local nameL = Instance.new("TextLabel", frame)
	nameL.Size = UDim2.new(1, 0, 0.55, 0)
	nameL.BackgroundTransparency = 1
	nameL.Font = Enum.Font.GothamBold
	nameL.TextColor3 = Color3.fromRGB(0, 255, 150)
	nameL.TextSize = 13
	nameL.Text = player.Name

	local distL = Instance.new("TextLabel", frame)
	distL.Size = UDim2.new(1, 0, 0.45, 0)
	distL.Position = UDim2.new(0, 0, 0.55, 0)
	distL.BackgroundTransparency = 1
	distL.Font = Enum.Font.Gotham
	distL.TextColor3 = Color3.fromRGB(200, 200, 200)
	distL.TextSize = 11
	distL.Text = ""

	local box = Instance.new("BoxHandleAdornment")
	box.Size = Vector3.new(3.5, 5.5, 3.5)
	box.Color3 = Color3.fromRGB(0, 255, 150)
	box.Transparency = 0.65
	box.AlwaysOnTop = true
	box.ZIndex = 5
	box.Visible = false
	box.Parent = ESPFolder

	PlayerESPData[player] = { BB = bb, Box = box, Name = nameL, Dist = distL, Stroke = stroke }

	local conn
	conn = RunService.RenderStepped:Connect(function()
		local data = PlayerESPData[player]
		if not data then conn:Disconnect() return end

		if not State.ESPPlayers then
			bb.Enabled = false
			box.Visible = false
			return
		end

		local char = player.Character
		if not char then bb.Enabled = false; box.Visible = false; return end

		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then
			bb.Enabled = false; box.Visible = false; return
		end

		local myHRP = getHRP()
		local dist = myHRP and (hrp.Position - myHRP.Position).Magnitude or 0

		bb.Adornee = hrp
		bb.Enabled = true
		box.Adornee = hrp
		box.Visible = true

		distL.Text = string.format("%.0fm", dist)

		local color = dist < 25 and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(0, 255, 150)
		nameL.TextColor3 = color
		box.Color3 = color
		stroke.Color = color
	end)

	player.CharacterRemoving:Connect(function()
		bb.Enabled = false
		box.Visible = false
	end)
end

local function removeESPFor(player)
	local data = PlayerESPData[player]
	if not data then return end
	safeCall(function() data.BB:Destroy() end)
	safeCall(function() data.Box:Destroy() end)
	PlayerESPData[player] = nil
end

local function initESP()
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(makeESPFor, p) end
	Players.PlayerAdded:Connect(function(p) task.delay(0.5, makeESPFor, p) end)
	Players.PlayerRemoving:Connect(removeESPFor)
end

local function initBallESP()
	local bb = Instance.new("BillboardGui")
	bb.Name = "_BallESP"
	bb.Size = UDim2.new(3.5, 0, 1.5, 0)
	bb.MaxDistance = 600
	bb.AlwaysOnTop = true
	bb.Enabled = false
	bb.Parent = ESPFolder

	local frame = Instance.new("Frame", bb)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(255, 80, 20)
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
	Instance.new("UIStroke", frame).Color = Color3.fromRGB(255, 180, 50)

	local lbl = Instance.new("TextLabel", frame)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextSize = 14
	lbl.Text = "🎾 BALL"

	local box = Instance.new("BoxHandleAdornment")
	box.Color3 = Color3.fromRGB(255, 160, 50)
	box.Transparency = 0.5
	box.AlwaysOnTop = true
	box.ZIndex = 5
	box.Visible = false
	box.Parent = ESPFolder

	RunService.RenderStepped:Connect(function()
		if not State.ESPBall then
			bb.Enabled = false
			box.Visible = false
			return
		end
		local ball = findBall()
		if ball and ball.Parent then
			bb.Adornee = ball
			bb.Enabled = true
			box.Adornee = ball
			box.Size = ball.Size * 1.3
			box.Visible = true
		else
			bb.Enabled = false
			box.Visible = false
		end
	end)
end

local function initTrajectory()
	local lines = {}

	local function makeDots()
		for _, old in ipairs(lines) do pcall(function() old:Destroy() end) end
		lines = {}
		for i = 1, 20 do
			local p = Instance.new("Part")
			p.Name = "TrajDot" .. i
			p.Shape = Enum.PartType.Ball
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromRGB(0, 200, 255)
			p.Size = Vector3.new(0.3, 0.3, 0.3)
			p.Anchored = true
			p.CanCollide = false
			p.CastShadow = false
			p.Transparency = 1
			p.Parent = TrajectoryFolder
			lines[i] = p
		end
	end

	makeDots()

	TrajectoryFolder.ChildRemoved:Connect(function()
		task.delay(0.1, makeDots)
	end)

	local lastPos = nil
	local lastTime = nil
	local smoothVel = Vector3.new(0, 0, 0)

	local function getBallVelocity(ball)
		local vel = nil

		vel = safeCall(function() return ball.AssemblyLinearVelocity end)
		if vel and vel.Magnitude > 0.1 then return vel end

		vel = safeCall(function() return ball.Velocity end)
		if vel and vel.Magnitude > 0.1 then return vel end

		if lastPos and lastTime then
			local dt = tick() - lastTime
			if dt > 0 and dt < 0.5 then
				return (ball.Position - lastPos) / dt
			end
		end

		return Vector3.new(0, 0, 0)
	end

	RunService.RenderStepped:Connect(function()
		if not State.BallTrajectory then
			for _, p in ipairs(lines) do
				if p and p.Parent then p.Transparency = 1 end
			end
			lastPos = nil
			lastTime = nil
			return
		end

		local ball = findBall()
		if not ball or not ball.Parent then
			for _, p in ipairs(lines) do
				if p and p.Parent then p.Transparency = 1 end
			end
			lastPos = nil
			lastTime = nil
			return
		end

		local rawVel = getBallVelocity(ball)
		smoothVel = smoothVel:Lerp(rawVel, 0.4)

		lastPos = ball.Position
		lastTime = tick()

		if smoothVel.Magnitude < 0.5 then
			for _, p in ipairs(lines) do
				if p and p.Parent then p.Transparency = 1 end
			end
			return
		end

		local pos = ball.Position
		local g = Vector3.new(0, -Workspace.Gravity, 0)
		local dt = 0.07

		for i, dot in ipairs(lines) do
			if dot and dot.Parent then
				local t = i * dt
				local predPos = pos + smoothVel * t + 0.5 * g * t * t
				dot.Position = predPos
				dot.Transparency = 0.15 + (i / #lines) * 0.75
			end
		end
	end)
end

local function initSpeedBoost()
	RunService.Heartbeat:Connect(function()
		if not State.SpeedBoost then
			local hum = getHum()
			if hum and hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
			return
		end
		local hum = getHum()
		if hum then hum.WalkSpeed = State.SpeedValue end
	end)
end

local function initDoubleJump()
	local jumped = false

	local function setup(char)
		local hum = char:WaitForChild("Humanoid", 5)
		if not hum then return end

		hum.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
				jumped = false
			end
		end)
	end

	if LP.Character then setup(LP.Character) end
	LP.CharacterAdded:Connect(setup)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if not State.DoubleJump then return end
		if input.KeyCode ~= Enum.KeyCode.Space then return end

		local hrp = getHRP()
		local hum = getHum()
		if not hrp or not hum then return end
		if hum.FloorMaterial ~= Enum.Material.Air then return end
		if jumped then return end

		jumped = true

		local attempts = {
			function()
				hrp.Velocity = Vector3.new(hrp.Velocity.X, 55, hrp.Velocity.Z)
			end,
			function()
				local bv = Instance.new("BodyVelocity")
				bv.Velocity = Vector3.new(hrp.Velocity.X, 55, hrp.Velocity.Z)
				bv.MaxForce = Vector3.new(0, math.huge, 0)
				bv.Parent = hrp
				task.delay(0.12, function() bv:Destroy() end)
			end,
			function()
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
				task.wait(0.05)
				hrp.Velocity = Vector3.new(hrp.Velocity.X, 55, hrp.Velocity.Z)
			end,
		}

		for _, fn in ipairs(attempts) do
			if safeCall(fn) then break end
		end
	end)
end

local function initAntiRagdoll()
	RunService.Heartbeat:Connect(function()
		if not State.AntiRagdoll then return end
		local char = getChar()
		if not char then return end

		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
			hum.Sit = false
		end

		for _, v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") and v.Anchored then
				v.Anchored = false
			end
		end
	end)
end

local function initSpinBot()
	RunService.Heartbeat:Connect(function()
		if not State.SpinBot then return end
		local hrp = getHRP()
		if hrp then
			hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(12), 0)
		end
	end)
end

local function initHitbox()
	local origSize = nil

	RunService.Heartbeat:Connect(function()
		local mult = State.HitboxMultiplier
		local ball = findBall()

		if ball then
			if mult > 1 then
				if not origSize then origSize = ball.Size end

				local attempts = {
					function()
						ball.Size = origSize * mult
					end,
					function()
						ball.LocalTransparencyModifier = 0
						ball.Size = origSize * mult
					end,
					function()
						local cf = ball.CFrame
						ball.Size = origSize * mult
						ball.CFrame = cf
					end,
				}

				for _, fn in ipairs(attempts) do
					if safeCall(fn) then break end
				end
			else
				if origSize and ball.Parent then
					safeCall(function() ball.Size = origSize end)
					origSize = nil
				end
			end
		else
			origSize = nil
		end
	end)
end

task.spawn(initESP)
task.spawn(initBallESP)
task.spawn(initTrajectory)
task.spawn(initSpeedBoost)
task.spawn(initDoubleJump)
task.spawn(initAntiRagdoll)
task.spawn(initSpinBot)
task.spawn(initHitbox)

local function initProtection()
	local defaultSpeed = 16

	RunService.Heartbeat:Connect(function()
		local hum = getHum()
		if hum then
			if State.SpeedBoost and hum.WalkSpeed < State.SpeedValue then
				hum.WalkSpeed = State.SpeedValue
			end
			if State.AntiRagdoll and hum.PlatformStand then
				hum.PlatformStand = false
			end
		end

		if not ESPFolder or not ESPFolder.Parent then
			ESPFolder = Instance.new("Folder")
			ESPFolder.Name = "_CrystalESP"
			ESPFolder.Parent = Workspace
		end

		if not TrajectoryFolder or not TrajectoryFolder.Parent then
			TrajectoryFolder = Instance.new("Folder")
			TrajectoryFolder.Name = "_CrystalTrajectory"
			TrajectoryFolder.Parent = Workspace
		end
	end)

	local function protectChar(char)
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end

		hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if State.SpeedBoost and hum.WalkSpeed ~= State.SpeedValue then
				task.defer(function() hum.WalkSpeed = State.SpeedValue end)
			end
		end)

		hum:GetPropertyChangedSignal("PlatformStand"):Connect(function()
			if State.AntiRagdoll and hum.PlatformStand then
				task.defer(function() hum.PlatformStand = false end)
			end
		end)

		hum:GetPropertyChangedSignal("Sit"):Connect(function()
			if State.AntiRagdoll and hum.Sit then
				task.defer(function() hum.Sit = false end)
			end
		end)
	end

	if LP.Character then protectChar(LP.Character) end
	LP.CharacterAdded:Connect(protectChar)
end

task.spawn(initProtection)

local Window = Rayfield:CreateWindow({
	Name = "Crystal Hub",
	LoadingTitle = "Crystal Hub",
	LoadingSubtitle = "Neo Tennis",
	Theme = "Default",
	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false,
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "CrystalHub",
		FileName = "NeoTennis"
	},
	Discord = {
		Enabled = false,
	},
	KeySystem = false,
})

local VisualTab = Window:CreateTab("Visual", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
local MovementTab = Window:CreateTab("Movement", 4483362458)

VisualTab:CreateSection("ESP Players")

VisualTab:CreateToggle({
	Name = "ESP Players",
	CurrentValue = false,
	Flag = "ESPPlayers",
	Callback = function(v)
		State.ESPPlayers = v
	end,
})

VisualTab:CreateSection("ESP Ball")

VisualTab:CreateToggle({
	Name = "ESP Ball",
	CurrentValue = false,
	Flag = "ESPBall",
	Callback = function(v)
		State.ESPBall = v
	end,
})

VisualTab:CreateSection("Trajectory")

VisualTab:CreateToggle({
	Name = "Ball Trajectory",
	CurrentValue = false,
	Flag = "BallTrajectory",
	Callback = function(v)
		State.BallTrajectory = v
	end,
})

CombatTab:CreateSection("Hitbox")

CombatTab:CreateSlider({
	Name = "Hitbox Multiplier",
	Range = {1, 5},
	Increment = 0.5,
	Suffix = "x",
	CurrentValue = 1,
	Flag = "HitboxMultiplier",
	Callback = function(v)
		State.HitboxMultiplier = v
	end,
})

MovementTab:CreateSection("Speed")

MovementTab:CreateToggle({
	Name = "Speed Boost",
	CurrentValue = false,
	Flag = "SpeedBoost",
	Callback = function(v)
		State.SpeedBoost = v
	end,
})

MovementTab:CreateSlider({
	Name = "Speed Value",
	Range = {16, 80},
	Increment = 1,
	Suffix = "",
	CurrentValue = 35,
	Flag = "SpeedValue",
	Callback = function(v)
		State.SpeedValue = v
	end,
})

MovementTab:CreateSection("Jump")

MovementTab:CreateToggle({
	Name = "Double Jump",
	CurrentValue = false,
	Flag = "DoubleJump",
	Callback = function(v)
		State.DoubleJump = v
	end,
})

MovementTab:CreateSection("Physics")

MovementTab:CreateToggle({
	Name = "Anti Ragdoll",
	CurrentValue = false,
	Flag = "AntiRagdoll",
	Callback = function(v)
		State.AntiRagdoll = v
	end,
})

MovementTab:CreateToggle({
	Name = "Spin Bot",
	CurrentValue = false,
	Flag = "SpinBot",
	Callback = function(v)
		State.SpinBot = v
	end,
})

Rayfield:Notify({
	Title = "Crystal Hub",
	Content = "Neo Tennis loaded!",
	Duration = 4,
	Image = 4483362458,
})
