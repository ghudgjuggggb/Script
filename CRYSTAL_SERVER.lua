local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local CS = {
	Version = "1.0.0",
	ESPEnabled = false,
	NoclipEnabled = false,
	FlyEnabled = false,
	SpeedEnabled = false,
	SpeedValue = 32,
	InfJumpEnabled = false,
	GodmodeEnabled = false,
	FreecamEnabled = false,
	BrightnessValue = 2,
	AmbientColor = Color3.fromRGB(128, 128, 128),
	TimeValue = 14,
	FogEnabled = false,
	FogEnd = 100000,
	SpinEnabled = false,
	AntiRagdoll = false,
	AntiFall = false,
	JumpPower = 50,
	GravityValue = 196.2,
}

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "_CrystalServer_ESP"
ESPFolder.Parent = Workspace

local function safeCall(fn, ...)
	local ok, r = pcall(fn, ...)
	return ok and r or nil
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

local function notify(title, text, dur)
	Rayfield:Notify({ Title = title, Content = text, Duration = dur or 3, Image = 4483362458 })
end

local function getPlayerFromName(name)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():find(name:lower()) or p.DisplayName:lower():find(name:lower()) then
			return p
		end
	end
	return nil
end

local function getAllPlayers(includeSelf)
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if includeSelf or p ~= LP then
			table.insert(list, p)
		end
	end
	return list
end

local function getPlayerList(includeSelf)
	local names = {}
	for _, p in ipairs(getAllPlayers(includeSelf)) do
		table.insert(names, p.Name)
	end
	return names
end

-- =============================================
-- ESP SYSTEM
-- =============================================
local ESPData = {}

local function buildESPFor(player)
	if player == LP then return end
	if ESPData[player] then return end

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(6, 0, 3, 0)
	bb.MaxDistance = 2000
	bb.AlwaysOnTop = true
	bb.Enabled = false
	bb.Parent = ESPFolder

	local frame = Instance.new("Frame", bb)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(200, 220, 255)

	local nameL = Instance.new("TextLabel", frame)
	nameL.Size = UDim2.new(1, 0, 0.45, 0)
	nameL.BackgroundTransparency = 1
	nameL.Font = Enum.Font.GothamBold
	nameL.TextColor3 = Color3.fromRGB(200, 220, 255)
	nameL.TextSize = 13
	nameL.Text = player.Name

	local infoL = Instance.new("TextLabel", frame)
	infoL.Size = UDim2.new(1, 0, 0.3, 0)
	infoL.Position = UDim2.new(0, 0, 0.45, 0)
	infoL.BackgroundTransparency = 1
	infoL.Font = Enum.Font.Gotham
	infoL.TextColor3 = Color3.fromRGB(160, 180, 220)
	infoL.TextSize = 11
	infoL.Text = ""

	local hpL = Instance.new("TextLabel", frame)
	hpL.Size = UDim2.new(1, 0, 0.25, 0)
	hpL.Position = UDim2.new(0, 0, 0.75, 0)
	hpL.BackgroundTransparency = 1
	hpL.Font = Enum.Font.Gotham
	hpL.TextColor3 = Color3.fromRGB(0, 255, 100)
	hpL.TextSize = 10
	hpL.Text = ""

	local box = Instance.new("BoxHandleAdornment")
	box.Size = Vector3.new(4, 6, 4)
	box.Color3 = Color3.fromRGB(200, 220, 255)
	box.Transparency = 0.6
	box.AlwaysOnTop = true
	box.ZIndex = 5
	box.Visible = false
	box.Parent = ESPFolder

	ESPData[player] = { BB = bb, Box = box, Stroke = stroke, Name = nameL, Info = infoL, HP = hpL }

	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not ESPData[player] then conn:Disconnect() return end
		if not CS.ESPEnabled then
			bb.Enabled = false
			box.Visible = false
			return
		end
		local char = player.Character
		if not char then bb.Enabled = false; box.Visible = false; return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp then bb.Enabled = false; box.Visible = false; return end

		bb.Adornee = hrp
		bb.Enabled = true
		box.Adornee = hrp
		box.Visible = true

		local myHRP = getHRP()
		local dist = myHRP and math.floor((hrp.Position - myHRP.Position).Magnitude) or 0
		infoL.Text = dist .. "m"

		if hum then
			local hp = math.floor(hum.Health)
			local maxhp = math.floor(hum.MaxHealth)
			hpL.Text = "HP " .. hp .. "/" .. maxhp
			local ratio = hp / math.max(maxhp, 1)
			hpL.TextColor3 = Color3.fromRGB(math.floor((1 - ratio) * 255), math.floor(ratio * 255), 50)
		end

		local teamColor = Color3.fromRGB(200, 220, 255)
		if player.Team and LP.Team then
			teamColor = player.Team == LP.Team
				and Color3.fromRGB(0, 255, 150)
				or Color3.fromRGB(255, 80, 80)
		end
		nameL.TextColor3 = teamColor
		box.Color3 = teamColor
		stroke.Color = teamColor
	end)

	player.CharacterRemoving:Connect(function()
		bb.Enabled = false
		box.Visible = false
	end)
end

local function removeESPFor(player)
	local d = ESPData[player]
	if not d then return end
	safeCall(function() d.BB:Destroy() end)
	safeCall(function() d.Box:Destroy() end)
	ESPData[player] = nil
end

local function initESP()
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(buildESPFor, p) end
	Players.PlayerAdded:Connect(function(p) task.delay(0.5, buildESPFor, p) end)
	Players.PlayerRemoving:Connect(removeESPFor)
end

-- =============================================
-- NOCLIP
-- =============================================
local function initNoclip()
	RunService.Stepped:Connect(function()
		if not CS.NoclipEnabled then return end
		local char = getChar()
		if not char then return end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CanCollide = false
			end
		end
	end)
end

-- =============================================
-- FLY
-- =============================================
local FlyBodyPos, FlyBodyGyr
local FlyConnection

local function startFly()
	local hrp = getHRP()
	if not hrp then return end

	FlyBodyPos = Instance.new("BodyPosition")
	FlyBodyPos.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	FlyBodyPos.Position = hrp.Position
	FlyBodyPos.D = 100
	FlyBodyPos.P = 5000
	FlyBodyPos.Parent = hrp

	FlyBodyGyr = Instance.new("BodyGyro")
	FlyBodyGyr.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	FlyBodyGyr.CFrame = hrp.CFrame
	FlyBodyGyr.D = 400
	FlyBodyGyr.P = 10000
	FlyBodyGyr.Parent = hrp

	FlyConnection = RunService.RenderStepped:Connect(function()
		if not CS.FlyEnabled then
			if FlyBodyPos then FlyBodyPos:Destroy() end
			if FlyBodyGyr then FlyBodyGyr:Destroy() end
			if FlyConnection then FlyConnection:Disconnect() end
			return
		end

		local hrp2 = getHRP()
		if not hrp2 then return end

		local moveDir = Vector3.new(0, 0, 0)
		local speed = CS.SpeedEnabled and CS.SpeedValue or 50
		local camCF = Camera.CFrame

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

		if moveDir.Magnitude > 0 then
			FlyBodyPos.Position = hrp2.Position + moveDir.Unit * speed * 0.1
		else
			FlyBodyPos.Position = hrp2.Position
		end

		FlyBodyGyr.CFrame = camCF
	end)
end

local function stopFly()
	if FlyBodyPos then FlyBodyPos:Destroy() end
	if FlyBodyGyr then FlyBodyGyr:Destroy() end
	if FlyConnection then FlyConnection:Disconnect() end
	local hum = getHum()
	if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

-- =============================================
-- SPEED
-- =============================================
local function initSpeed()
	RunService.Heartbeat:Connect(function()
		local hum = getHum()
		if not hum then return end
		if CS.SpeedEnabled then
			hum.WalkSpeed = CS.SpeedValue
		end
	end)
end

-- =============================================
-- INFINITE JUMP
-- =============================================
local function initInfJump()
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode ~= Enum.KeyCode.Space then return end
		if not CS.InfJumpEnabled then return end
		local hum = getHum()
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

-- =============================================
-- GODMODE
-- =============================================
local function initGodmode()
	local conn
	local function setup(char)
		local hum = char:WaitForChild("Humanoid", 5)
		if not hum then return end
		if conn then conn:Disconnect() end
		conn = hum.HealthChanged:Connect(function(hp)
			if CS.GodmodeEnabled and hp < hum.MaxHealth then
				task.defer(function()
					if hum and hum.Parent then
						hum.Health = hum.MaxHealth
					end
				end)
			end
		end)
	end
	if LP.Character then task.spawn(setup, LP.Character) end
	LP.CharacterAdded:Connect(setup)
end

-- =============================================
-- ANTI RAGDOLL / ANTI FALL
-- =============================================
local function initAntiPhysics()
	RunService.Heartbeat:Connect(function()
		local char = getChar()
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			if CS.AntiRagdoll then
				hum.PlatformStand = false
				hum.Sit = false
			end
			if CS.AntiFall and hum.JumpPower ~= CS.JumpPower then
				hum.JumpPower = CS.JumpPower
			end
		end
		if CS.AntiRagdoll then
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("BasePart") and v.Anchored then
					v.Anchored = false
				end
			end
		end
	end)
end

-- =============================================
-- SPIN
-- =============================================
local function initSpin()
	RunService.Heartbeat:Connect(function()
		if not CS.SpinEnabled then return end
		local hrp = getHRP()
		if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(10), 0) end
	end)
end

-- =============================================
-- GRAVITY CONTROL
-- =============================================
local function applyGravity(val)
	CS.GravityValue = val
	Workspace.Gravity = val
end

-- =============================================
-- LIGHTING CONTROL
-- =============================================
local DefaultLighting = {
	Brightness = Lighting.Brightness,
	Ambient = Lighting.Ambient,
	TimeOfDay = Lighting.TimeOfDay,
	FogEnd = Lighting.FogEnd,
	FogColor = Lighting.FogColor,
}

local function setFullBright(on)
	Lighting.Brightness = on and 10 or DefaultLighting.Brightness
	Lighting.Ambient = on and Color3.fromRGB(178, 178, 178) or DefaultLighting.Ambient
	Lighting.OutdoorAmbient = on and Color3.fromRGB(178, 178, 178) or Color3.fromRGB(70, 70, 70)
	Lighting.GlobalShadows = not on
end

-- =============================================
-- TELEPORT
-- =============================================
local function teleportToPlayer(target)
	local hrp = getHRP()
	local char = target.Character
	if not hrp or not char then return end
	local tHRP = char:FindFirstChild("HumanoidRootPart")
	if not tHRP then return end
	hrp.CFrame = tHRP.CFrame + Vector3.new(3, 0, 0)
end

local function bringPlayer(target)
	local hrp = getHRP()
	local char = target.Character
	if not hrp or not char then return end
	local tHRP = char:FindFirstChild("HumanoidRootPart")
	if not tHRP then return end
	tHRP.CFrame = hrp.CFrame + Vector3.new(3, 0, 0)
end

local function teleportToCoords(x, y, z)
	local hrp = getHRP()
	if not hrp then return end
	hrp.CFrame = CFrame.new(x, y, z)
end

-- =============================================
-- PLAYER ACTIONS (on other players)
-- =============================================
local function killPlayer(target)
	local char = target.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		local attempts = {
			function() hum.Health = 0 end,
			function() hum:TakeDamage(hum.MaxHealth * 10) end,
			function()
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.CFrame = CFrame.new(0, -999, 0) end
			end,
		}
		for _, fn in ipairs(attempts) do
			if safeCall(fn) then break end
		end
	end
end

local function kickPlayer(target)
	local attempts = {
		function() target:Kick("[Crystal Server] You have been removed.") end,
		function()
			local char = target.Character
			if char then char:BreakJoints() end
		end,
	}
	for _, fn in ipairs(attempts) do
		if safeCall(fn) then break end
	end
end

local function freezePlayer(target, state)
	local char = target.Character
	if not char then return end
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Anchored = state
		end
	end
end

local function invisPlayer(target, state)
	local char = target.Character
	if not char then return end
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("Decal") then
			v.Transparency = state and 1 or 0
		end
	end
end

local function clonePlayer(target)
	local char = target.Character
	if not char then return end
	local clone = char:Clone()
	clone.Parent = Workspace
	task.delay(10, function()
		if clone and clone.Parent then clone:Destroy() end
	end)
end

local function giveSpeedTo(target, speed)
	local char = target.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = speed end
end

local function healPlayer(target)
	local char = target.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.Health = hum.MaxHealth end
end

-- =============================================
-- WORKSPACE CONTROL
-- =============================================
local function deleteAllNPCs()
	for _, v in ipairs(Workspace:GetChildren()) do
		if v:IsA("Model") and v ~= LP.Character then
			local hum = v:FindFirstChildOfClass("Humanoid")
			if hum and not Players:GetPlayerFromCharacter(v) then
				v:Destroy()
			end
		end
	end
end

local function explodeAt(pos)
	local e = Instance.new("Explosion")
	e.Position = pos
	e.BlastRadius = 20
	e.BlastPressure = 5e5
	e.Parent = Workspace
end

local function explodePlayer(target)
	local char = target.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then explodeAt(hrp.Position) end
end

local function clearDecals()
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("Decal") or v:IsA("Texture") then
			v.Transparency = 1
		end
	end
end

local function clearParticles()
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
			v.Enabled = false
		end
	end
end

local function anchorAll(state)
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("BasePart") and not LP.Character or (LP.Character and not v:IsDescendantOf(LP.Character)) then
			v.Anchored = state
		end
	end
end

-- =============================================
-- REMOTES SPY
-- =============================================
local RemoteLog = {}
local SpyEnabled = false
local spyConns = {}

local function startRemoteSpy()
	if SpyEnabled then return end
	SpyEnabled = true
	local mt = getrawmetatable and getrawmetatable(game)
	if not mt then
		notify("Remote Spy", "Metatable not accessible on this executor", 4)
		return
	end
	local oldIndex = mt.__index
	setreadonly(mt, false)
	table.insert(spyConns, mt)
	local oldNC = mt.__namecall
	mt.__namecall = newcclosure(function(self, ...)
		local method = getnamecallmethod()
		if (method == "FireServer" or method == "InvokeServer") and self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
			local entry = {
				Name = self.Name,
				Path = self:GetFullName(),
				Method = method,
				Args = { ... },
				Time = tick(),
			}
			table.insert(RemoteLog, 1, entry)
			if #RemoteLog > 50 then table.remove(RemoteLog) end
		end
		return oldNC(self, ...)
	end)
	setreadonly(mt, true)
end

-- =============================================
-- FREECAM
-- =============================================
local FreecamPart
local FreecamConn

local function startFreecam()
	FreecamPart = Instance.new("Part")
	FreecamPart.Anchored = true
	FreecamPart.CanCollide = false
	FreecamPart.Transparency = 1
	FreecamPart.Size = Vector3.new(1, 1, 1)
	FreecamPart.CFrame = Camera.CFrame
	FreecamPart.Parent = Workspace

	Camera.CameraSubject = FreecamPart
	Camera.CameraType = Enum.CameraType.Custom

	local speed = 50
	FreecamConn = RunService.RenderStepped:Connect(function(dt)
		if not CS.FreecamEnabled then
			if FreecamPart then FreecamPart:Destroy() end
			if FreecamConn then FreecamConn:Disconnect() end
			local hrp = getHRP()
			if hrp then Camera.CameraSubject = getHum() end
			Camera.CameraType = Enum.CameraType.Custom
			return
		end

		local move = Vector3.new(0, 0, 0)
		local cf = Camera.CFrame
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end

		if move.Magnitude > 0 then
			FreecamPart.CFrame = CFrame.new(FreecamPart.Position + move.Unit * speed * dt)
		end
	end)
end

local function stopFreecam()
	CS.FreecamEnabled = false
	if FreecamPart then FreecamPart:Destroy() end
	if FreecamConn then FreecamConn:Disconnect() end
	Camera.CameraSubject = getHum()
	Camera.CameraType = Enum.CameraType.Custom
end

-- =============================================
-- SERVER INFO
-- =============================================
local function getServerInfo()
	local ping = math.floor(LP:GetNetworkPing() * 1000)
	local fps = math.floor(1 / RunService.RenderStepped:Wait())
	local playerCount = #Players:GetPlayers()
	local maxPlayers = Players.MaxPlayers
	local jobId = game.JobId
	local placeId = game.PlaceId
	return {
		Ping = ping,
		FPS = fps,
		Players = playerCount .. "/" .. maxPlayers,
		JobId = jobId ~= "" and jobId:sub(1, 18) .. "..." or "N/A",
		PlaceId = tostring(placeId),
	}
end

-- =============================================
-- INIT ALL
-- =============================================
task.spawn(initESP)
task.spawn(initNoclip)
task.spawn(initSpeed)
task.spawn(initInfJump)
task.spawn(initGodmode)
task.spawn(initAntiPhysics)
task.spawn(initSpin)

-- =============================================
-- RAYFIELD WINDOW
-- =============================================
local Window = Rayfield:CreateWindow({
	Name = "Crystal Server",
	LoadingTitle = "Crystal Server",
	LoadingSubtitle = "Full Server Control",
	Theme = "Default",
	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false,
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "CrystalServer",
		FileName = "Config"
	},
	Discord = { Enabled = false },
	KeySystem = false,
})

-- TABS
local TabSelf     = Window:CreateTab("Self",      4483362458)
local TabVisual   = Window:CreateTab("Visual",    4483362458)
local TabPlayers  = Window:CreateTab("Players",   4483362458)
local TabWorld    = Window:CreateTab("World",     4483362458)
local TabLighting = Window:CreateTab("Lighting",  4483362458)
local TabTeleport = Window:CreateTab("Teleport",  4483362458)
local TabServer   = Window:CreateTab("Server",    4483362458)

-- =============================================
-- TAB: SELF
-- =============================================
TabSelf:CreateSection("Movement")

TabSelf:CreateToggle({
	Name = "Speed Boost",
	CurrentValue = false,
	Flag = "Speed",
	Callback = function(v)
		CS.SpeedEnabled = v
		if not v then
			local hum = getHum()
			if hum then hum.WalkSpeed = 16 end
		end
	end,
})

TabSelf:CreateSlider({
	Name = "Walk Speed",
	Range = {16, 250},
	Increment = 1,
	Suffix = "",
	CurrentValue = 32,
	Flag = "SpeedVal",
	Callback = function(v) CS.SpeedValue = v end,
})

TabSelf:CreateToggle({
	Name = "Fly",
	CurrentValue = false,
	Flag = "Fly",
	Callback = function(v)
		CS.FlyEnabled = v
		if v then startFly() else stopFly() end
	end,
})

TabSelf:CreateToggle({
	Name = "Noclip",
	CurrentValue = false,
	Flag = "Noclip",
	Callback = function(v) CS.NoclipEnabled = v end,
})

TabSelf:CreateToggle({
	Name = "Infinite Jump",
	CurrentValue = false,
	Flag = "InfJump",
	Callback = function(v) CS.InfJumpEnabled = v end,
})

TabSelf:CreateSlider({
	Name = "Jump Power",
	Range = {50, 500},
	Increment = 10,
	Suffix = "",
	CurrentValue = 50,
	Flag = "JumpPower",
	Callback = function(v)
		CS.JumpPower = v
		local hum = getHum()
		if hum then hum.JumpPower = v end
	end,
})

TabSelf:CreateSection("Combat")

TabSelf:CreateToggle({
	Name = "Godmode",
	CurrentValue = false,
	Flag = "Godmode",
	Callback = function(v) CS.GodmodeEnabled = v end,
})

TabSelf:CreateToggle({
	Name = "Anti Ragdoll",
	CurrentValue = false,
	Flag = "AntiRag",
	Callback = function(v) CS.AntiRagdoll = v end,
})

TabSelf:CreateToggle({
	Name = "Spin Bot",
	CurrentValue = false,
	Flag = "Spin",
	Callback = function(v) CS.SpinEnabled = v end,
})

TabSelf:CreateSection("Character")

TabSelf:CreateButton({
	Name = "Reset Character",
	Callback = function()
		local hum = getHum()
		if hum then hum.Health = 0 end
	end,
})

TabSelf:CreateButton({
	Name = "Rejoin Server",
	Callback = function()
		local TS = game:GetService("TeleportService")
		safeCall(function()
			TS:Teleport(game.PlaceId, LP)
		end)
	end,
})

TabSelf:CreateButton({
	Name = "Leave Server",
	Callback = function()
		safeCall(function()
			game:GetService("TeleportService"):Teleport(game.PlaceId)
		end)
	end,
})

-- =============================================
-- TAB: VISUAL
-- =============================================
TabVisual:CreateSection("ESP")

TabVisual:CreateToggle({
	Name = "ESP Players",
	CurrentValue = false,
	Flag = "ESP",
	Callback = function(v) CS.ESPEnabled = v end,
})

TabVisual:CreateSection("Camera")

TabVisual:CreateToggle({
	Name = "Freecam",
	CurrentValue = false,
	Flag = "Freecam",
	Callback = function(v)
		CS.FreecamEnabled = v
		if v then startFreecam() else stopFreecam() end
	end,
})

TabVisual:CreateSlider({
	Name = "Camera FOV",
	Range = {30, 120},
	Increment = 1,
	Suffix = "",
	CurrentValue = 70,
	Flag = "FOV",
	Callback = function(v) Camera.FieldOfView = v end,
})

TabVisual:CreateSection("View")

TabVisual:CreateToggle({
	Name = "Fullbright",
	CurrentValue = false,
	Flag = "Fullbright",
	Callback = function(v) setFullBright(v) end,
})

TabVisual:CreateButton({
	Name = "Clear Particles",
	Callback = function()
		clearParticles()
		notify("Crystal", "All particles disabled", 2)
	end,
})

TabVisual:CreateButton({
	Name = "Clear Decals",
	Callback = function()
		clearDecals()
		notify("Crystal", "All decals hidden", 2)
	end,
})

-- =============================================
-- TAB: PLAYERS
-- =============================================
TabPlayers:CreateSection("Target Player")

local targetName = ""
TabPlayers:CreateInput({
	Name = "Player Name",
	PlaceholderText = "Enter name...",
	RemoveTextAfterFocusLost = false,
	Flag = "TargetInput",
	Callback = function(v) targetName = v end,
})

TabPlayers:CreateButton({
	Name = "Teleport To Player",
	Callback = function()
		local t = getPlayerFromName(targetName)
		if t then teleportToPlayer(t); notify("Teleport", "→ " .. t.Name, 2)
		else notify("Error", "Player not found", 2) end
	end,
})

TabPlayers:CreateButton({
	Name = "Bring Player",
	Callback = function()
		local t = getPlayerFromName(targetName)
		if t then bringPlayer(t); notify("Bring", t.Name .. " brought", 2)
		else notify("Error", "Player not found", 2) end
	end,
})

TabPlayers:CreateButton({
	Name = "Heal Player",
	Callback = function()
		local t = getPlayerFromName(targetName)
		if t then healPlayer(t); notify("Heal", t.Name .. " healed", 2)
		else notify("Error", "Player not found", 2) end
	end,
})

TabPlayers:CreateButton({
	Name = "Kill Player",
	Callback = function()
		local t = getPlayerFromName(targetName)
		if t then killPlayer(t); notify("Kill", t.Name .. " killed", 2)
		else notify("Error", "Player not found", 2) end
	end,
})

TabPlayers:CreateButton({
	Name = "Kick Player",
	Callback = function()
		local t = getPlayerFromName(targetName)
		if t then kickPlayer(t); notify("Kick", "Attempted kick on " .. t.Name, 2)
		else notify("Error", "Player not found", 2) end
	end,
})

TabPlayers:CreateButton({
	Name = "Freeze Player",
	Callback = function()
		local t = getPlayerFromName(targetName)
		if t then freezePlayer(t, true); notify("Freeze", t.Name .. " frozen", 2)
		else notify("Error", "Player not found", 2) end
	end,
})

TabPlayers:CreateButton({
	Name = "Unfreeze Player",
	Callback = function()
		local t = getPlayerFromName(targetName)
		if t then freezePlayer(t, false); notify("Unfreeze", t.Name .. " unfrozen", 2)
		else notify("Error", "Player not found", 2) end
	end,
})

TabPlayers:CreateButton({
	Name = "Make Invisible",
	Callback = function()
		local t = getPlayerFromName(targetName)
		if t then invisPlayer(t, true); notify("Invisible", t.Name .. " hidden", 2)
		else notify("Error", "Player not found", 2) end
	end,
})

TabPlayers:CreateButton({
	Name = "Make Visible",
	Callback = function()
		local t = getPlayerFromName(targetName)
		if t then invisPlayer(t, false); notify("Visible", t.Name .. " visible", 2)
		else notify("Error", "Player not found", 2) end
	end,
})

TabPlayers:CreateButton({
	Name = "Explode Player",
	Callback = function()
		local t = getPlayerFromName(targetName)
		if t then explodePlayer(t); notify("Explode", t.Name .. " exploded", 2)
		else notify("Error", "Player not found", 2) end
	end,
})

TabPlayers:CreateButton({
	Name = "Clone Player",
	Callback = function()
		local t = getPlayerFromName(targetName)
		if t then clonePlayer(t); notify("Clone", t.Name .. " cloned (10s)", 2)
		else notify("Error", "Player not found", 2) end
	end,
})

TabPlayers:CreateSection("All Players")

TabPlayers:CreateButton({
	Name = "Kill All Players",
	Callback = function()
		for _, p in ipairs(getAllPlayers(false)) do killPlayer(p) end
		notify("Kill All", "Attempted kill on all players", 2)
	end,
})

TabPlayers:CreateButton({
	Name = "Freeze All Players",
	Callback = function()
		for _, p in ipairs(getAllPlayers(false)) do freezePlayer(p, true) end
		notify("Freeze All", "All players frozen", 2)
	end,
})

TabPlayers:CreateButton({
	Name = "Unfreeze All Players",
	Callback = function()
		for _, p in ipairs(getAllPlayers(false)) do freezePlayer(p, false) end
		notify("Unfreeze All", "All players unfrozen", 2)
	end,
})

TabPlayers:CreateButton({
	Name = "Explode All Players",
	Callback = function()
		for _, p in ipairs(getAllPlayers(false)) do explodePlayer(p) end
		notify("Explode All", "Boom", 2)
	end,
})

TabPlayers:CreateButton({
	Name = "Bring All Players",
	Callback = function()
		for _, p in ipairs(getAllPlayers(false)) do bringPlayer(p) end
		notify("Bring All", "All players brought", 2)
	end,
})

-- =============================================
-- TAB: WORLD
-- =============================================
TabWorld:CreateSection("Physics")

TabWorld:CreateSlider({
	Name = "Gravity",
	Range = {0, 500},
	Increment = 5,
	Suffix = "",
	CurrentValue = 196,
	Flag = "Gravity",
	Callback = function(v) applyGravity(v) end,
})

TabWorld:CreateButton({
	Name = "Reset Gravity",
	Callback = function()
		applyGravity(196.2)
		notify("Gravity", "Reset to 196.2", 2)
	end,
})

TabWorld:CreateSection("Objects")

TabWorld:CreateButton({
	Name = "Delete All NPCs",
	Callback = function()
		deleteAllNPCs()
		notify("World", "All NPCs removed", 2)
	end,
})

TabWorld:CreateButton({
	Name = "Anchor All Parts",
	Callback = function()
		anchorAll(true)
		notify("World", "All parts anchored", 2)
	end,
})

TabWorld:CreateButton({
	Name = "Unanchor All Parts",
	Callback = function()
		anchorAll(false)
		notify("World", "All parts unanchored", 2)
	end,
})

TabWorld:CreateButton({
	Name = "Explode at Spawn",
	Callback = function()
		local hrp = getHRP()
		if hrp then explodeAt(hrp.Position)
		else explodeAt(Vector3.new(0, 5, 0)) end
	end,
})

-- =============================================
-- TAB: LIGHTING
-- =============================================
TabLighting:CreateSection("Time")

TabLighting:CreateSlider({
	Name = "Time of Day",
	Range = {0, 24},
	Increment = 1,
	Suffix = ":00",
	CurrentValue = 14,
	Flag = "TimeOfDay",
	Callback = function(v)
		CS.TimeValue = v
		Lighting.TimeOfDay = string.format("%02d:00:00", v)
	end,
})

TabLighting:CreateSection("Atmosphere")

TabLighting:CreateSlider({
	Name = "Brightness",
	Range = {0, 10},
	Increment = 1,
	Suffix = "",
	CurrentValue = 2,
	Flag = "Brightness",
	Callback = function(v) Lighting.Brightness = v end,
})

TabLighting:CreateSlider({
	Name = "Fog End",
	Range = {10, 100000},
	Increment = 100,
	Suffix = "",
	CurrentValue = 100000,
	Flag = "FogEnd",
	Callback = function(v) Lighting.FogEnd = v end,
})

TabLighting:CreateButton({
	Name = "Reset Lighting",
	Callback = function()
		Lighting.Brightness = DefaultLighting.Brightness
		Lighting.Ambient = DefaultLighting.Ambient
		Lighting.TimeOfDay = DefaultLighting.TimeOfDay
		Lighting.FogEnd = DefaultLighting.FogEnd
		Lighting.GlobalShadows = true
		notify("Lighting", "Reset to default", 2)
	end,
})

-- =============================================
-- TAB: TELEPORT
-- =============================================
TabTeleport:CreateSection("Coordinates")

local tpX, tpY, tpZ = 0, 10, 0

TabTeleport:CreateInput({
	Name = "X",
	PlaceholderText = "0",
	RemoveTextAfterFocusLost = false,
	Flag = "TpX",
	Callback = function(v) tpX = tonumber(v) or 0 end,
})

TabTeleport:CreateInput({
	Name = "Y",
	PlaceholderText = "10",
	RemoveTextAfterFocusLost = false,
	Flag = "TpY",
	Callback = function(v) tpY = tonumber(v) or 10 end,
})

TabTeleport:CreateInput({
	Name = "Z",
	PlaceholderText = "0",
	RemoveTextAfterFocusLost = false,
	Flag = "TpZ",
	Callback = function(v) tpZ = tonumber(v) or 0 end,
})

TabTeleport:CreateButton({
	Name = "Teleport to Coords",
	Callback = function()
		teleportToCoords(tpX, tpY, tpZ)
		notify("Teleport", string.format("→ %.0f, %.0f, %.0f", tpX, tpY, tpZ), 2)
	end,
})

TabTeleport:CreateSection("Saved Locations")

local Saves = {}

TabTeleport:CreateButton({
	Name = "Save Current Position",
	Callback = function()
		local hrp = getHRP()
		if not hrp then return end
		local p = hrp.Position
		table.insert(Saves, p)
		notify("Saved", string.format("#%d → %.0f %.0f %.0f", #Saves, p.X, p.Y, p.Z), 3)
	end,
})

TabTeleport:CreateButton({
	Name = "Go to Last Save",
	Callback = function()
		if #Saves == 0 then notify("Error", "No saves", 2); return end
		local p = Saves[#Saves]
		teleportToCoords(p.X, p.Y, p.Z)
		notify("Teleport", "→ Last save", 2)
	end,
})

TabTeleport:CreateButton({
	Name = "Teleport to Spawn",
	Callback = function()
		local spawn = Workspace:FindFirstChild("SpawnLocation")
		if spawn then
			teleportToCoords(spawn.Position.X, spawn.Position.Y + 5, spawn.Position.Z)
		else
			teleportToCoords(0, 10, 0)
		end
		notify("Teleport", "→ Spawn", 2)
	end,
})

-- =============================================
-- TAB: SERVER INFO
-- =============================================
TabServer:CreateSection("Server Info")

TabServer:CreateButton({
	Name = "Show Server Info",
	Callback = function()
		local info = getServerInfo()
		notify("Server Info",
			string.format("Ping: %dms | FPS: %d | Players: %s", info.Ping, info.FPS, info.Players), 6)
	end,
})

TabServer:CreateButton({
	Name = "Show Place/Job ID",
	Callback = function()
		local info = getServerInfo()
		notify("IDs", "PlaceId: " .. info.PlaceId .. "\nJob: " .. info.JobId, 5)
	end,
})

TabServer:CreateSection("Remote Events")

TabServer:CreateButton({
	Name = "List All Remotes",
	Callback = function()
		local remotes = {}
		for _, v in ipairs(game:GetDescendants()) do
			if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
				table.insert(remotes, v:GetFullName())
			end
		end
		notify("Remotes", "Found " .. #remotes .. " remotes (check console)", 3)
		for i, r in ipairs(remotes) do
			print("[Crystal Server] Remote #" .. i .. ": " .. r)
		end
	end,
})

TabServer:CreateSection("Chat")

TabServer:CreateInput({
	Name = "Message",
	PlaceholderText = "Type message...",
	RemoveTextAfterFocusLost = false,
	Flag = "ChatMsg",
	Callback = function(v)
		safeCall(function()
			game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
				:FindFirstChild("SayMessageRequest"):FireServer(v, "All")
		end)
	end,
})

-- НОВЫЕ ТАБЫ
local TabTools    = Window:CreateTab("Tools",      4483362458)
local TabSound    = Window:CreateTab("Sound",      4483362458)
local TabSpy      = Window:CreateTab("Spy",        4483362458)
local TabProtect  = Window:CreateTab("Protect",    4483362458)
local TabExecutor = Window:CreateTab("Executor",   4483362458)
local TabAuto     = Window:CreateTab("Auto",       4483362458)
local TabChar     = Window:CreateTab("Character",  4483362458)

-- =============================================
-- TOOL GIVER (даёт инструменты персонажу)
-- =============================================
local function giveToolByName(name)
	local found = {}
	for _, v in ipairs(game:GetDescendants()) do
		if (v:IsA("Tool") or v:IsA("HopperBin")) and v.Name:lower():find(name:lower()) then
			table.insert(found, v)
		end
	end
	if #found == 0 then
		notify("Tools", "Tool not found: " .. name, 2)
		return
	end
	local tool = found[1]:Clone()
	tool.Parent = LP.Backpack
	notify("Tools", "Got: " .. tool.Name, 2)
end

local function giveAllTools()
	local count = 0
	for _, v in ipairs(game:GetDescendants()) do
		if v:IsA("Tool") or v:IsA("HopperBin") then
			local clone = v:Clone()
			clone.Parent = LP.Backpack
			count += 1
		end
	end
	notify("Tools", "Got " .. count .. " tools", 3)
end

local function clearBackpack()
	for _, v in ipairs(LP.Backpack:GetChildren()) do
		v:Destroy()
	end
	local char = getChar()
	if char then
		for _, v in ipairs(char:GetChildren()) do
			if v:IsA("Tool") then v:Destroy() end
		end
	end
	notify("Tools", "Backpack cleared", 2)
end

local function dropAllTools()
	local char = getChar()
	if not char then return end
	local hrp = getHRP()
	for _, v in ipairs(LP.Backpack:GetChildren()) do
		if v:IsA("Tool") then
			v.Parent = Workspace
			if hrp then
				safeCall(function()
					v.Handle.CFrame = hrp.CFrame + Vector3.new(math.random(-5,5), 1, math.random(-5,5))
				end)
			end
		end
	end
	notify("Tools", "Dropped all tools", 2)
end

TabTools:CreateSection("Tool Finder")

local toolSearchName = ""
TabTools:CreateInput({
	Name = "Tool Name",
	PlaceholderText = "Sword, Gun, ...",
	RemoveTextAfterFocusLost = false,
	Flag = "ToolSearch",
	Callback = function(v) toolSearchName = v end,
})

TabTools:CreateButton({
	Name = "Give Tool",
	Callback = function()
		if toolSearchName == "" then notify("Error", "Enter tool name", 2); return end
		giveToolByName(toolSearchName)
	end,
})

TabTools:CreateButton({
	Name = "Give All Tools",
	Callback = function() giveAllTools() end,
})

TabTools:CreateButton({
	Name = "Clear Backpack",
	Callback = function() clearBackpack() end,
})

TabTools:CreateButton({
	Name = "Drop All Tools",
	Callback = function() dropAllTools() end,
})

TabTools:CreateSection("Quick Spawn")

TabTools:CreateButton({
	Name = "Spawn Explosion Here",
	Callback = function()
		local hrp = getHRP()
		if hrp then
			explodeAt(hrp.Position)
			notify("Explosion", "💥 Boom", 2)
		end
	end,
})

TabTools:CreateButton({
	Name = "Spawn Part Here",
	Callback = function()
		local hrp = getHRP()
		if not hrp then return end
		local part = Instance.new("Part")
		part.Size = Vector3.new(4, 1, 4)
		part.CFrame = hrp.CFrame + Vector3.new(0, -3, 0)
		part.BrickColor = BrickColor.new("Bright blue")
		part.Material = Enum.Material.SmoothPlastic
		part.Parent = Workspace
		notify("Part", "Spawned platform below you", 2)
	end,
})

TabTools:CreateButton({
	Name = "Spawn Forcefield",
	Callback = function()
		local char = getChar()
		if not char then return end
		local ff = Instance.new("ForceField")
		ff.Parent = char
		task.delay(10, function() if ff and ff.Parent then ff:Destroy() end end)
		notify("Forcefield", "Active for 10s", 2)
	end,
})

-- =============================================
-- SOUND CONTROL
-- =============================================
local MutedSounds = {}
local OriginalVolumes = {}

local function muteAllSounds(state)
	for _, v in ipairs(game:GetDescendants()) do
		if v:IsA("Sound") then
			if state then
				OriginalVolumes[v] = v.Volume
				v.Volume = 0
			else
				if OriginalVolumes[v] then
					v.Volume = OriginalVolumes[v]
				end
			end
		end
	end
end

local function stopAllSounds()
	for _, v in ipairs(game:GetDescendants()) do
		if v:IsA("Sound") and v.Playing then
			v:Stop()
		end
	end
end

TabSound:CreateSection("Volume")

TabSound:CreateSlider({
	Name = "Master Volume",
	Range = {0, 100},
	Increment = 1,
	Suffix = "%",
	CurrentValue = 100,
	Flag = "MasterVol",
	Callback = function(v)
		SoundService.RespectFilteringEnabled = true
		for _, s in ipairs(game:GetDescendants()) do
			if s:IsA("Sound") then
				s.Volume = (v / 100) * (OriginalVolumes[s] or s.Volume)
			end
		end
	end,
})

TabSound:CreateSection("Controls")

TabSound:CreateToggle({
	Name = "Mute All Sounds",
	CurrentValue = false,
	Flag = "MuteAll",
	Callback = function(v) muteAllSounds(v) end,
})

TabSound:CreateButton({
	Name = "Stop All Sounds",
	Callback = function()
		stopAllSounds()
		notify("Sound", "All sounds stopped", 2)
	end,
})

TabSound:CreateButton({
	Name = "List All Sounds",
	Callback = function()
		local count = 0
		for _, v in ipairs(game:GetDescendants()) do
			if v:IsA("Sound") then
				count += 1
				print("[Crystal Server] Sound: " .. v:GetFullName() .. " | Vol: " .. v.Volume .. " | Playing: " .. tostring(v.Playing))
			end
		end
		notify("Sound", count .. " sounds found (console)", 3)
	end,
})

TabSound:CreateSection("Background Music")

local bgMusic = nil
local musicInput = ""
TabSound:CreateInput({
	Name = "Sound ID",
	PlaceholderText = "rbxassetid://...",
	RemoveTextAfterFocusLost = false,
	Flag = "MusicID",
	Callback = function(v) musicInput = v end,
})

TabSound:CreateButton({
	Name = "Play Sound",
	Callback = function()
		if bgMusic then bgMusic:Stop(); bgMusic:Destroy() end
		bgMusic = Instance.new("Sound")
		bgMusic.SoundId = musicInput:find("rbxassetid") and musicInput or "rbxassetid://" .. musicInput
		bgMusic.Volume = 0.5
		bgMusic.Looped = true
		bgMusic.Parent = game:GetService("SoundService")
		bgMusic:Play()
		notify("Sound", "Playing custom music", 2)
	end,
})

TabSound:CreateButton({
	Name = "Stop Custom Music",
	Callback = function()
		if bgMusic then bgMusic:Stop(); bgMusic:Destroy(); bgMusic = nil end
		notify("Sound", "Stopped", 2)
	end,
})

-- =============================================
-- REMOTE SPY
-- =============================================
local RemoteLog = {}
local RemoteBlacklist = {}
local SpyActive = false

local function hookRemoteSpy()
	local ok = pcall(function()
		local mt = getrawmetatable(game)
		setreadonly(mt, false)
		local oldNC = mt.__namecall
		mt.__namecall = newcclosure(function(self, ...)
			local method = getnamecallmethod()
			if (method == "FireServer" or method == "InvokeServer") then
				if SpyActive and not RemoteBlacklist[self.Name] then
					local args = { ... }
					local entry = {
						Name    = self.Name,
						Path    = self:GetFullName(),
						Method  = method,
						Time    = string.format("%.2f", tick()),
					}
					table.insert(RemoteLog, 1, entry)
					if #RemoteLog > 100 then table.remove(RemoteLog) end
					print(string.format("[Crystal Spy] %s | %s | %s", method, self:GetFullName(), entry.Time))
				end
			end
			return oldNC(self, ...)
		end)
		setreadonly(mt, true)
	end)
	if not ok then
		notify("Spy", "Executor doesn't support metatable hooks", 4)
	end
end

TabSpy:CreateSection("Remote Spy")

TabSpy:CreateToggle({
	Name = "Enable Remote Spy",
	CurrentValue = false,
	Flag = "SpyToggle",
	Callback = function(v)
		SpyActive = v
		if v then
			hookRemoteSpy()
			notify("Spy", "Remote spy active (check console)", 3)
		else
			notify("Spy", "Remote spy disabled", 2)
		end
	end,
})

TabSpy:CreateButton({
	Name = "Print Last 10 Remotes",
	Callback = function()
		if #RemoteLog == 0 then notify("Spy", "No remotes logged yet", 2); return end
		for i = 1, math.min(10, #RemoteLog) do
			local e = RemoteLog[i]
			print(string.format("[%s] %s → %s", e.Time, e.Method, e.Path))
		end
		notify("Spy", "Printed to console", 2)
	end,
})

TabSpy:CreateButton({
	Name = "Clear Remote Log",
	Callback = function()
		RemoteLog = {}
		notify("Spy", "Log cleared", 2)
	end,
})

TabSpy:CreateSection("Remote Caller")

local remoteCallPath = ""
TabSpy:CreateInput({
	Name = "Remote Path",
	PlaceholderText = "game.ReplicatedStorage.Event",
	RemoveTextAfterFocusLost = false,
	Flag = "RemotePath",
	Callback = function(v) remoteCallPath = v end,
})

TabSpy:CreateButton({
	Name = "Fire Remote (no args)",
	Callback = function()
		local ok, result = pcall(function()
			local remote = game
			for part in remoteCallPath:gmatch("[^%.]+") do
				remote = remote:WaitForChild(part, 2)
				if not remote then error("Not found: " .. part) end
			end
			if remote:IsA("RemoteEvent") then
				remote:FireServer()
			elseif remote:IsA("RemoteFunction") then
				remote:InvokeServer()
			end
		end)
		notify("Spy", ok and "Fired!" or "Error: path not found", 2)
	end,
})

-- =============================================
-- PROTECTION
-- =============================================
local Protection = {
	AntiKick = false,
	AntiTP = false,
	AntiDeath = false,
	AntiChat = false,
}

local OriginalKick

local function initProtection()
	local function protectChar(char)
		local hum = char:WaitForChild("Humanoid", 5)
		if not hum then return end

		hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if CS.SpeedEnabled and hum.WalkSpeed ~= CS.SpeedValue then
				task.defer(function() if hum.Parent then hum.WalkSpeed = CS.SpeedValue end end)
			end
		end)

		hum:GetPropertyChangedSignal("PlatformStand"):Connect(function()
			if CS.AntiRagdoll and hum.PlatformStand then
				task.defer(function() if hum.Parent then hum.PlatformStand = false end end)
			end
		end)

		hum:GetPropertyChangedSignal("Sit"):Connect(function()
			if CS.AntiRagdoll and hum.Sit then
				task.defer(function() if hum.Parent then hum.Sit = false end end)
			end
		end)

		hum.HealthChanged:Connect(function(hp)
			if Protection.AntiDeath and hp <= 0 then
				task.defer(function()
					if hum.Parent then hum.Health = hum.MaxHealth end
				end)
			end
		end)
	end

	if LP.Character then protectChar(LP.Character) end
	LP.CharacterAdded:Connect(protectChar)

	LP.CharacterAdded:Connect(function(char)
		if Protection.AntiTP then
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				local lastPos = hrp.Position
				RunService.Heartbeat:Connect(function()
					if not Protection.AntiTP then lastPos = hrp.Position; return end
					local dist = (hrp.Position - lastPos).Magnitude
					if dist > 100 then
						hrp.CFrame = CFrame.new(lastPos)
					else
						lastPos = hrp.Position
					end
				end)
			end
		end
	end)

	pcall(function()
		OriginalKick = LP.Kick
		LP.Kick = function(self, msg)
			if Protection.AntiKick then
				notify("Anti-Kick", "Kick blocked: " .. tostring(msg), 4)
				return
			end
			return OriginalKick(self, msg)
		end
	end)
end

TabProtect:CreateSection("Anti Exploits")

TabProtect:CreateToggle({
	Name = "Anti Kick",
	CurrentValue = false,
	Flag = "AntiKick",
	Callback = function(v)
		Protection.AntiKick = v
		notify("Protect", "Anti Kick: " .. (v and "ON" or "OFF"), 2)
	end,
})

TabProtect:CreateToggle({
	Name = "Anti Teleport",
	CurrentValue = false,
	Flag = "AntiTP",
	Callback = function(v)
		Protection.AntiTP = v
		notify("Protect", "Anti Teleport: " .. (v and "ON" or "OFF"), 2)
	end,
})

TabProtect:CreateToggle({
	Name = "Anti Death",
	CurrentValue = false,
	Flag = "AntiDeath",
	Callback = function(v)
		Protection.AntiDeath = v
		notify("Protect", "Anti Death: " .. (v and "ON" or "OFF"), 2)
	end,
})

TabProtect:CreateSection("Settings Lock")

TabProtect:CreateToggle({
	Name = "Lock Walk Speed",
	CurrentValue = false,
	Flag = "LockSpeed",
	Callback = function(v)
		CS.SpeedEnabled = v
		notify("Protect", "Speed lock: " .. (v and "ON" or "OFF"), 2)
	end,
})

TabProtect:CreateToggle({
	Name = "Lock Anti Ragdoll",
	CurrentValue = false,
	Flag = "LockRag",
	Callback = function(v)
		CS.AntiRagdoll = v
		notify("Protect", "Ragdoll lock: " .. (v and "ON" or "OFF"), 2)
	end,
})

TabProtect:CreateSection("Folder Guard")

TabProtect:CreateToggle({
	Name = "Guard ESP Folder",
	CurrentValue = false,
	Flag = "FolderGuard",
	Callback = function(v)
		if v then
			RunService.Heartbeat:Connect(function()
				if not ESPFolder or not ESPFolder.Parent then
					ESPFolder = Instance.new("Folder")
					ESPFolder.Name = "_CrystalServer_ESP"
					ESPFolder.Parent = Workspace
					for _, p in ipairs(Players:GetPlayers()) do
						ESPData[p] = nil
						task.spawn(buildESPFor, p)
					end
				end
			end)
		end
		notify("Protect", "Folder guard: " .. (v and "ON" or "OFF"), 2)
	end,
})

-- =============================================
-- EXECUTOR
-- =============================================
local execCode = ""

TabExecutor:CreateSection("Script Executor")

TabExecutor:CreateInput({
	Name = "Lua Code",
	PlaceholderText = "print('Hello!')",
	RemoveTextAfterFocusLost = false,
	Flag = "ExecCode",
	Callback = function(v) execCode = v end,
})

TabExecutor:CreateButton({
	Name = "Execute",
	Callback = function()
		if execCode == "" then notify("Executor", "No code entered", 2); return end
		local fn, err = loadstring(execCode)
		if not fn then
			notify("Executor", "Syntax error: " .. tostring(err), 4)
			return
		end
		local ok, result = pcall(fn)
		if ok then
			notify("Executor", "✅ Executed", 2)
		else
			notify("Executor", "❌ Error: " .. tostring(result), 4)
			warn("[Crystal Executor] " .. tostring(result))
		end
	end,
})

TabExecutor:CreateSection("Quick Scripts")

TabExecutor:CreateButton({
	Name = "Print All Scripts",
	Callback = function()
		local count = 0
		for _, v in ipairs(game:GetDescendants()) do
			if v:IsA("LocalScript") or v:IsA("Script") or v:IsA("ModuleScript") then
				count += 1
				print("[Crystal] " .. v:GetFullName() .. " | " .. v.ClassName)
			end
		end
		notify("Executor", count .. " scripts found (console)", 3)
	end,
})

TabExecutor:CreateButton({
	Name = "Dump LocalPlayer",
	Callback = function()
		print("=== LocalPlayer Dump ===")
		print("Name:", LP.Name)
		print("UserId:", LP.UserId)
		print("Team:", tostring(LP.Team))
		print("AccountAge:", LP.AccountAge)
		print("MembershipType:", tostring(LP.MembershipType))
		local char = getChar()
		if char then
			print("CharPosition:", tostring(getHRP() and getHRP().Position))
			print("Health:", tostring(getHum() and getHum().Health))
			print("WalkSpeed:", tostring(getHum() and getHum().WalkSpeed))
		end
		notify("Executor", "Dumped to console", 2)
	end,
})

TabExecutor:CreateButton({
	Name = "Dump Workspace",
	Callback = function()
		print("=== Workspace Dump ===")
		for _, v in ipairs(Workspace:GetChildren()) do
			print("[" .. v.ClassName .. "] " .. v.Name)
		end
		notify("Executor", "Dumped Workspace to console", 2)
	end,
})

TabExecutor:CreateButton({
	Name = "Dump ReplicatedStorage",
	Callback = function()
		print("=== ReplicatedStorage Dump ===")
		for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
			print("[" .. v.ClassName .. "] " .. v:GetFullName())
		end
		notify("Executor", "Dumped ReplicatedStorage", 2)
	end,
})

-- =============================================
-- AUTO FEATURES
-- =============================================
local Auto = {
	AutoRespawn = false,
	AutoCollect = false,
	AutoHeal = false,
	AutoHealThreshold = 50,
	AutoSpin = false,
}

local function initAutoFeatures()
	LP.CharacterAdded:Connect(function(char)
		if Auto.AutoRespawn then
			notify("Auto", "Respawned!", 2)
		end
	end)

	RunService.Heartbeat:Connect(function()
		local hum = getHum()
		local hrp = getHRP()

		if Auto.AutoHeal and hum then
			local pct = (hum.Health / hum.MaxHealth) * 100
			if pct < Auto.AutoHealThreshold then
				hum.Health = hum.MaxHealth
			end
		end

		if Auto.AutoCollect and hrp then
			for _, v in ipairs(Workspace:GetDescendants()) do
				if v:IsA("Tool") or v:IsA("BasePart") then
					local dist = (v.Position - hrp.Position).Magnitude
					if dist < 15 then
						safeCall(function()
							if v:IsA("Tool") then
								v.Parent = LP.Backpack
							end
						end)
					end
				end
			end
		end
	end)
end

TabAuto:CreateSection("Auto Actions")

TabAuto:CreateToggle({
	Name = "Auto Respawn Notify",
	CurrentValue = false,
	Flag = "AutoRespawn",
	Callback = function(v) Auto.AutoRespawn = v end,
})

TabAuto:CreateToggle({
	Name = "Auto Heal",
	CurrentValue = false,
	Flag = "AutoHeal",
	Callback = function(v) Auto.AutoHeal = v end,
})

TabAuto:CreateSlider({
	Name = "Heal Threshold",
	Range = {10, 90},
	Increment = 5,
	Suffix = "%",
	CurrentValue = 50,
	Flag = "HealThresh",
	Callback = function(v) Auto.AutoHealThreshold = v end,
})

TabAuto:CreateToggle({
	Name = "Auto Collect Tools",
	CurrentValue = false,
	Flag = "AutoCollect",
	Callback = function(v) Auto.AutoCollect = v end,
})

TabAuto:CreateSection("Auto Kill")

local AutoKillConn
TabAuto:CreateToggle({
	Name = "Auto Kill All",
	CurrentValue = false,
	Flag = "AutoKillAll",
	Callback = function(v)
		if v then
			AutoKillConn = RunService.Heartbeat:Connect(function()
				for _, p in ipairs(getAllPlayers(false)) do
					killPlayer(p)
				end
			end)
		else
			if AutoKillConn then AutoKillConn:Disconnect(); AutoKillConn = nil end
		end
	end,
})

local AutoKillName = ""
TabAuto:CreateInput({
	Name = "Target Name (Auto Kill)",
	PlaceholderText = "Player name...",
	RemoveTextAfterFocusLost = false,
	Flag = "AutoKillName",
	Callback = function(v) AutoKillName = v end,
})

local AutoKillTargetConn
TabAuto:CreateToggle({
	Name = "Auto Kill Target",
	CurrentValue = false,
	Flag = "AutoKillTarget",
	Callback = function(v)
		if v then
			AutoKillTargetConn = RunService.Heartbeat:Connect(function()
				local t = getPlayerFromName(AutoKillName)
				if t then killPlayer(t) end
			end)
		else
			if AutoKillTargetConn then AutoKillTargetConn:Disconnect(); AutoKillTargetConn = nil end
		end
	end,
})

TabAuto:CreateSection("Auto TP")

local AutoTPConn
local AutoTPName = ""
TabAuto:CreateInput({
	Name = "Target (Auto TP)",
	PlaceholderText = "Player name...",
	RemoveTextAfterFocusLost = false,
	Flag = "AutoTPName",
	Callback = function(v) AutoTPName = v end,
})

TabAuto:CreateToggle({
	Name = "Auto Follow Player",
	CurrentValue = false,
	Flag = "AutoFollow",
	Callback = function(v)
		if v then
			AutoTPConn = RunService.Heartbeat:Connect(function()
				local t = getPlayerFromName(AutoTPName)
				if t then
					local char = t.Character
					if char then
						local tHRP = char:FindFirstChild("HumanoidRootPart")
						local myHRP = getHRP()
						if tHRP and myHRP then
							local dist = (tHRP.Position - myHRP.Position).Magnitude
							if dist > 8 then
								myHRP.CFrame = tHRP.CFrame + Vector3.new(3, 0, 0)
							end
						end
					end
				end
			end)
		else
			if AutoTPConn then AutoTPConn:Disconnect(); AutoTPConn = nil end
		end
	end,
})

-- =============================================
-- CHARACTER EDITOR
-- =============================================
local function setCharacterScale(scaleType, value)
	local char = getChar()
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local desc = safeCall(function() return hum:GetAppliedDescription() end)
	if not desc then return end
	desc[scaleType] = value
	safeCall(function() hum:ApplyDescription(desc) end)
end

local function setWalkAnimSpeed(speed)
	local char = getChar()
	if not char then return end
	local animate = char:FindFirstChild("Animate")
	if animate then
		for _, v in ipairs(animate:GetDescendants()) do
			if v:IsA("Animation") then
				local track = safeCall(function()
					return char:FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks()
				end)
				if track then
					for _, t in ipairs(track) do
						t:AdjustSpeed(speed)
					end
				end
			end
		end
	end
end

local function setTransparency(value)
	local char = getChar()
	if not char then return end
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			v.LocalTransparencyModifier = value
		end
	end
end

TabChar:CreateSection("Scale")

TabChar:CreateSlider({
	Name = "Body Width",
	Range = {25, 200},
	Increment = 5,
	Suffix = "%",
	CurrentValue = 100,
	Flag = "BodyWidth",
	Callback = function(v) setCharacterScale("BodyWidthScale", v / 100) end,
})

TabChar:CreateSlider({
	Name = "Body Height",
	Range = {25, 200},
	Increment = 5,
	Suffix = "%",
	CurrentValue = 100,
	Flag = "BodyHeight",
	Callback = function(v) setCharacterScale("BodyHeightScale", v / 100) end,
})

TabChar:CreateSlider({
	Name = "Head Size",
	Range = {25, 200},
	Increment = 5,
	Suffix = "%",
	CurrentValue = 100,
	Flag = "HeadSize",
	Callback = function(v) setCharacterScale("HeadScale", v / 100) end,
})

TabChar:CreateButton({
	Name = "Reset Scale",
	Callback = function()
		setCharacterScale("BodyWidthScale", 1)
		setCharacterScale("BodyHeightScale", 1)
		setCharacterScale("HeadScale", 1)
		notify("Char", "Scale reset", 2)
	end,
})

TabChar:CreateSection("Visibility")

TabChar:CreateSlider({
	Name = "Transparency",
	Range = {0, 100},
	Increment = 5,
	Suffix = "%",
	CurrentValue = 0,
	Flag = "CharTransp",
	Callback = function(v) setTransparency(v / 100) end,
})

TabChar:CreateButton({
	Name = "Full Invisible",
	Callback = function()
		setTransparency(1)
		notify("Char", "Invisible", 2)
	end,
})

TabChar:CreateButton({
	Name = "Full Visible",
	Callback = function()
		setTransparency(0)
		notify("Char", "Visible", 2)
	end,
})

TabChar:CreateSection("Animation")

TabChar:CreateSlider({
	Name = "Animation Speed",
	Range = {0, 5},
	Increment = 1,
	Suffix = "x",
	CurrentValue = 1,
	Flag = "AnimSpeed",
	Callback = function(v) setWalkAnimSpeed(v) end,
})

-- =============================================
-- START ALL NEW SYSTEMS
-- =============================================
task.spawn(initProtection)
task.spawn(initAutoFeatures)

-- =============================================
-- READY
-- =============================================
notify("Crystal Server", "✅ Fully Loaded | " .. #Players:GetPlayers() .. " players online", 5)
print([[
  ██████╗██████╗ ██╗   ██╗███████╗████████╗ █████╗ ██╗     
 ██╔════╝██╔══██╗╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔══██╗██║     
 ██║     ██████╔╝ ╚████╔╝ ███████╗   ██║   ███████║██║     
 ██║     ██╔══██╗  ╚██╔╝  ╚════██║   ██║   ██╔══██║██║     
 ╚██████╗██║  ██║   ██║   ███████║   ██║   ██║  ██║███████╗
  ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝
  SERVER v1.0.0 — Full Control
]])
