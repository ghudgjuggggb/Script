-- Astra Hub | Complete Edition

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local VirtualUser      = game:GetService("VirtualUser")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer
local Mouse            = LP:GetMouse()

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ══════════════════════════════════════════════════════
-- CONFIG
-- ══════════════════════════════════════════════════════
local C = {
	Aimbot          = false,
	AimMode         = "Camera",
	AimPart         = "Head",
	AimKey          = Enum.UserInputType.MouseButton2,
	OnePressAim     = false,
	TeamCheck       = true,
	AliveCheck      = true,
	WallCheck       = false,
	FoVCheck        = true,
	FoVRadius       = 150,
	ShowFoV         = true,
	UseSmoothness   = true,
	Smoothness      = 15,
	UseOffset       = false,
	StaticOffset    = 0,
	DynamicOffset   = 0,
	UseNoise        = false,
	NoiseStrength   = 20,

	SilentMouseHit    = true,
	SilentMouseTarget = true,
	SilentGetMouseLoc = true,
	SilentRaycast     = true,
	SilentFindPart    = true,

	ESP           = false,
	ESPEnemies    = true,
	ESPTeammates  = true,
	ESPBoxes      = true,
	ESPNames      = true,
	ESPHealth     = true,
	ESPDistance   = true,
	ESPTracers    = false,
	ESPSkeleton   = false,
	ESPHeadDot    = true,
	ESPMaxDist    = 1000,
	ESPEnemyColor = Color3.fromRGB(255, 60, 60),
	ESPTeamColor  = Color3.fromRGB(60, 180, 255),

	HitBox          = false,
	HitBoxSize      = 5,
	HitBoxEnemyOnly = true,

	Chams           = false,
	ChamsEnemyColor = Color3.fromRGB(255, 50, 50),
	ChamsTeamColor  = Color3.fromRGB(50, 120, 255),
	ChamsTransp     = 0.4,

	InfAmmo  = false,
	NoSpread = false,

	SpinBot         = false,
	SpinVelocity    = 50,
	OnePressSpinBot = false,

	TriggerBot      = false,
	TriggerDelay    = 0.05,
	TriggerChance   = 100,
	SmartTrigger    = true,
	OnePressTrigger = false,

	CustomFOV  = false,
	FOVValue   = 70,
	DefaultFOV = Camera.FieldOfView,

	AntiAFK = false,
}

-- ══════════════════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════════════════
local Aiming        = false
local Spinning      = false
local Triggering    = false
local Target        = nil
local CurrentTween  = nil
local MouseSens     = UserInputService.MouseDeltaSensitivity
local WindowActive  = true

-- ══════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════
local function isTeammate(p)
	if p == LP then return true end
	return LP.Team and p.Team and p.Team == LP.Team
end

local function getScreenPos(world)
	local v, on = Camera:WorldToViewportPoint(world)
	return Vector2.new(v.X, v.Y), on
end

local function applyNoise(str)
	local f = str / 100
	return Vector3.new(
		math.random() * f * 2 - f,
		math.random() * f * 2 - f,
		math.random() * f * 2 - f
	)
end

local function newDraw(t, props)
	local d = Drawing.new(t)
	for k, v in pairs(props) do d[k] = v end
	return d
end

-- ══════════════════════════════════════════════════════
-- IsReady — core target validator
-- ══════════════════════════════════════════════════════
local function IsReady(char)
	if not char then return false end
	local hum     = char:FindFirstChildWhichIsA("Humanoid")
	local aimPart = char:FindFirstChild(C.AimPart)
	local myChar  = LP.Character
	local myPart  = myChar and myChar:FindFirstChild(C.AimPart)
	local p       = Players:GetPlayerFromCharacter(char)

	if not hum or not aimPart or not aimPart:IsA("BasePart") then return false end
	if not myPart or not p or p == LP then return false end
	if C.AliveCheck and hum.Health <= 0 then return false end
	if C.TeamCheck and isTeammate(p) then return false end

	if C.WallCheck then
		local dir = aimPart.Position - myPart.Position
		local rp  = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = { myChar }
		rp.IgnoreWater = true
		local hit = workspace:Raycast(myPart.Position, dir, rp)
		if not hit or not hit.Instance or not hit.Instance:IsDescendantOf(char) then
			return false
		end
	end

	local offset = Vector3.zero
	if C.UseOffset then
		offset = Vector3.new(0, C.StaticOffset / 10, 0)
			+ hum.MoveDirection * (C.DynamicOffset / 10)
	end

	local noiseV  = C.UseNoise and applyNoise(C.NoiseStrength) or Vector3.zero
	local finalPos = aimPart.Position + offset + noiseV
	local sp, on  = getScreenPos(finalPos)
	local dist    = (finalPos - myPart.Position).Magnitude
	local hitCF   = CFrame.new(finalPos)

	return true, char, sp, on, finalPos, dist, hitCF, aimPart
end

-- ══════════════════════════════════════════════════════
-- TARGET SELECTION
-- ══════════════════════════════════════════════════════
local function findTarget()
	local mPos = Vector2.new(Mouse.X, Mouse.Y)
	local best, bestDist = nil, C.FoVCheck and C.FoVRadius or math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then
			local ok, _, sp, on = IsReady(p.Character)
			if ok and on then
				local d = (mPos - sp).Magnitude
				if d < bestDist then bestDist = d; best = p.Character end
			end
		end
	end
	return best
end

-- ══════════════════════════════════════════════════════
-- RESET AIM
-- ══════════════════════════════════════════════════════
local function resetAim()
	Aiming = false; Target = nil
	if CurrentTween then CurrentTween:Cancel(); CurrentTween = nil end
	UserInputService.MouseDeltaSensitivity = MouseSens
end

-- ══════════════════════════════════════════════════════
-- SILENT AIM HOOKS
-- ══════════════════════════════════════════════════════
local silentIndexOk = pcall(function()
	assert(hookmetamethod)
	local old = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if C.Aimbot and C.AimMode == "Silent" and Aiming and self == Mouse then
			local ok, _, sp, on, worldPos, _, hitCF, aimPart = IsReady(Target)
			if ok and on then
				if C.SilentMouseHit    and (key == "Hit"    or key == "hit")    then return hitCF    end
				if C.SilentMouseTarget and (key == "Target" or key == "target") then return aimPart  end
				if C.SilentMouseHit    and key == "X"       then return sp.X end
				if C.SilentMouseHit    and key == "Y"       then return sp.Y end
				if key == "UnitRay" then
					return Ray.new(Camera.CFrame.Position, (worldPos - Camera.CFrame.Position).Unit)
				end
			end
		end
		return old(self, key)
	end))
end)

local silentCallOk = pcall(function()
	assert(hookmetamethod)
	local old = hookmetamethod(game, "__namecall", newcclosure(function(...)
		local args   = { ... }
		local self   = args[1]
		local method = getnamecallmethod()

		if C.Aimbot and C.AimMode == "Silent" and Aiming then
			local ok, _, _, on, worldPos, dist = IsReady(Target)
			if ok and on then
				if C.SilentGetMouseLoc and self == UserInputService
					and (method == "GetMouseLocation" or method == "getMouseLocation") then
					local sp = getScreenPos(worldPos)
					return Vector2.new(sp.X, sp.Y)
				end

				local myPart = LP.Character and LP.Character:FindFirstChild(C.AimPart)
				if myPart then
					local dir = (worldPos - myPart.Position).Unit * dist

					if C.SilentRaycast and self == workspace
						and (method == "Raycast" or method == "raycast")
						and typeof(args[2]) == "Vector3" and typeof(args[3]) == "Vector3" then
						local newArgs = table.clone(args)
						newArgs[3] = dir
						return old(table.unpack(newArgs))
					end

					if C.SilentFindPart and self == workspace
						and method:find("FindPartOnRay")
						and typeof(args[2]) == "userdata" then
						local newArgs = table.clone(args)
						newArgs[2] = Ray.new(args[2].Origin, dir)
						return old(table.unpack(newArgs))
					end
				end
			end
		end
		return old(...)
	end))
end)

-- ══════════════════════════════════════════════════════
-- INPUT
-- ══════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	local t = input.UserInputType
	local k = input.KeyCode

	if C.Aimbot and (t == C.AimKey or k == C.AimKey) then
		if C.OnePressAim then
			if Aiming then resetAim() else Aiming = true end
		else
			Aiming = true
		end
	end

	if C.SpinBot and k == Enum.KeyCode.Q then
		if C.OnePressSpinBot then Spinning = not Spinning else Spinning = true end
	end

	if C.TriggerBot and k == Enum.KeyCode.E then
		if C.OnePressTrigger then Triggering = not Triggering else Triggering = true end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	local t = input.UserInputType
	local k = input.KeyCode
	if not C.OnePressAim     and (t == C.AimKey or k == C.AimKey) then resetAim() end
	if not C.OnePressSpinBot and k == Enum.KeyCode.Q then Spinning   = false end
	if not C.OnePressTrigger and k == Enum.KeyCode.E then Triggering = false end
end)

UserInputService.WindowFocused:Connect(function() WindowActive = true end)
UserInputService.WindowFocusReleased:Connect(function()
	WindowActive = false; resetAim(); Spinning = false; Triggering = false
end)

UserInputService:GetPropertyChangedSignal("MouseDeltaSensitivity"):Connect(function()
	if not Aiming then MouseSens = UserInputService.MouseDeltaSensitivity end
end)

-- ══════════════════════════════════════════════════════
-- ANTI-AFK
-- ══════════════════════════════════════════════════════
LP.Idled:Connect(function()
	if not C.AntiAFK then return end
	VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
	task.wait(0.1)
	VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
end)

-- ══════════════════════════════════════════════════════
-- TRIGGERBOT LOOP
-- ══════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(C.TriggerDelay)
		if C.TriggerBot and Triggering then
			local hit = Mouse.Target
			if hit then
				local p = Players:GetPlayerFromCharacter(hit.Parent)
				if p and p ~= LP then
					local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
					local valid = hum and hum.Health > 0
					if valid and C.TeamCheck and isTeammate(p) then valid = false end
					if valid and C.SmartTrigger then
						local ok = IsReady(p.Character)
						if not ok then valid = false end
					end
					if valid and math.random(1, 100) <= C.TriggerChance then
						pcall(mouse1click)
					end
				end
			end
		end
	end
end)

-- ══════════════════════════════════════════════════════
-- ESP SYSTEM
-- ══════════════════════════════════════════════════════
local SKEL_PAIRS = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
}
local CORNER_KEYS = {"cTL","cTL2","cTR","cTR2","cBL","cBL2","cBR","cBR2"}

local ESPPool   = {}
local ChamsPool = {}

local function makeESP(p)
	local o = {}
	o.fill     = newDraw("Square",{Transparency=0.25, Filled=true,  Visible=false, Thickness=0,   Color=Color3.fromRGB(255,60,60)})
	o.box      = newDraw("Square",{Thickness=1.5,     Filled=false, Visible=false,               Color=Color3.fromRGB(255,60,60)})
	for _, n in ipairs(CORNER_KEYS) do
		o[n] = newDraw("Line",{Thickness=2.5, Visible=false, Color=Color3.fromRGB(255,255,255)})
	end
	o.hpOutline = newDraw("Square",{Color=Color3.fromRGB(0,0,0),      Filled=false, Visible=false, Thickness=1})
	o.hpBg      = newDraw("Square",{Color=Color3.fromRGB(15,15,15),   Filled=true,  Visible=false, Thickness=0})
	o.hpBar     = newDraw("Square",{Color=Color3.fromRGB(50,220,50),  Filled=true,  Visible=false, Thickness=0})
	o.hpText    = newDraw("Text",  {Color=Color3.fromRGB(255,255,255),Size=10, Outline=true, OutlineColor=Color3.fromRGB(0,0,0), Visible=false, Center=true, Font=2})
	o.nameLbl   = newDraw("Text",  {Color=Color3.fromRGB(255,255,255),Size=13, Outline=true, OutlineColor=Color3.fromRGB(0,0,0), Visible=false, Center=true, Font=2})
	o.tagLbl    = newDraw("Text",  {Color=Color3.fromRGB(100,200,255),Size=11, Outline=true, OutlineColor=Color3.fromRGB(0,0,0), Visible=false, Center=true, Font=2})
	o.distLbl   = newDraw("Text",  {Color=Color3.fromRGB(180,180,180),Size=11, Outline=true, OutlineColor=Color3.fromRGB(0,0,0), Visible=false, Center=true, Font=2})
	o.tracer    = newDraw("Line",  {Color=Color3.fromRGB(255,60,60),  Thickness=1, Visible=false})
	o.headDot   = newDraw("Circle",{Color=Color3.fromRGB(255,255,255),Thickness=1.5, Filled=false, NumSides=32, Radius=4, Visible=false})
	o.headFill  = newDraw("Circle",{Transparency=0.5, Filled=true, NumSides=32, Radius=4, Visible=false, Color=Color3.fromRGB(255,60,60)})
	o.skel      = {}
	for _ = 1, #SKEL_PAIRS do
		table.insert(o.skel, newDraw("Line",{Color=Color3.fromRGB(255,255,255), Thickness=1, Visible=false}))
	end
	ESPPool[p] = o
end

local function clearESP(p)
	local o = ESPPool[p]; if not o then return end
	for k, v in pairs(o) do
		if k == "skel" then for _, l in ipairs(v) do pcall(function() l:Remove() end) end
		else pcall(function() v:Remove() end) end
	end
	ESPPool[p] = nil
end

local function hideESP(o)
	for k, v in pairs(o) do
		if k == "skel" then for _, l in ipairs(v) do l.Visible = false end
		else pcall(function() v.Visible = false end) end
	end
end

local function drawCorners(o, l, t, w, h, color)
	local cl = math.min(w, h) * 0.22
	local r, b = l+w, t+h
	local lines = {
		{o.cTL,  Vector2.new(l,t), Vector2.new(l+cl,t)},
		{o.cTL2, Vector2.new(l,t), Vector2.new(l,t+cl)},
		{o.cTR,  Vector2.new(r,t), Vector2.new(r-cl,t)},
		{o.cTR2, Vector2.new(r,t), Vector2.new(r,t+cl)},
		{o.cBL,  Vector2.new(l,b), Vector2.new(l+cl,b)},
		{o.cBL2, Vector2.new(l,b), Vector2.new(l,b-cl)},
		{o.cBR,  Vector2.new(r,b), Vector2.new(r-cl,b)},
		{o.cBR2, Vector2.new(r,b), Vector2.new(r,b-cl)},
	}
	for _, c in ipairs(lines) do
		c[1].From=c[2]; c[1].To=c[3]; c[1].Color=color; c[1].Visible=true
	end
end

-- ══════════════════════════════════════════════════════
-- CHAMS
-- ══════════════════════════════════════════════════════
local function applyChams(p)
	local char = p.Character; if not char then return end
	ChamsPool[p] = {}
	local col = isTeammate(p) and C.ChamsTeamColor or C.ChamsEnemyColor
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			local orig = {Material=v.Material, Color=v.Color, Transparency=v.Transparency}
			table.insert(ChamsPool[p], {part=v, orig=orig})
			v.Material=Enum.Material.Neon; v.Color=col; v.Transparency=C.ChamsTransp
		end
	end
end

local function clearChams(p)
	local list = ChamsPool[p]; if not list then return end
	for _, info in ipairs(list) do
		pcall(function()
			info.part.Material    = info.orig.Material
			info.part.Color       = info.orig.Color
			info.part.Transparency = info.orig.Transparency
		end)
	end
	ChamsPool[p] = nil
end

local function refreshChams()
	for _, p in ipairs(Players:GetPlayers()) do
		clearChams(p)
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if C.Chams and p ~= LP and hum and hum.Health > 0 then applyChams(p) end
	end
end

-- Player hooks
for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LP then
		makeESP(p)
		p.CharacterAdded:Connect(function()
			task.wait(0.5)
			if C.Chams then clearChams(p); applyChams(p) end
		end)
	end
end
Players.PlayerAdded:Connect(function(p)
	task.wait(0.1); makeESP(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		if C.Chams then clearChams(p); applyChams(p) end
	end)
end)
Players.PlayerRemoving:Connect(function(p) clearESP(p); clearChams(p) end)

-- ══════════════════════════════════════════════════════
-- FOV CIRCLE
-- ══════════════════════════════════════════════════════
local fovCircle = newDraw("Circle",{
	Visible=false, Color=Color3.fromRGB(255,255,255),
	Thickness=1.5, Filled=false, NumSides=64
})

-- ══════════════════════════════════════════════════════
-- MAIN LOOP
-- ══════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
	local vp     = Camera.ViewportSize
	local center = Vector2.new(vp.X/2, vp.Y/2)

	fovCircle.Position = center
	fovCircle.Radius   = C.FoVRadius
	fovCircle.Visible  = C.ShowFoV and C.Aimbot

	Camera.FieldOfView = C.CustomFOV and C.FOVValue or C.DefaultFOV

	if WindowActive then
		-- AIMBOT CAMERA
		if C.Aimbot and C.AimMode == "Camera" then
			local pressed = UserInputService:IsMouseButtonPressed(C.AimKey)
			if Aiming or pressed then
				Aiming = true
				if not IsReady(Target) then Target = findTarget() end
				local ok, _, _, on, worldPos = IsReady(Target)
				if ok and on then
					if CurrentTween then CurrentTween:Cancel() end
					UserInputService.MouseDeltaSensitivity = 0
					if C.UseSmoothness then
						CurrentTween = TweenService:Create(Camera,
							TweenInfo.new(math.clamp(C.Smoothness,1,99)/100, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
							{CFrame = CFrame.new(Camera.CFrame.Position, worldPos)}
						)
						CurrentTween:Play()
					else
						Camera.CFrame = CFrame.new(Camera.CFrame.Position, worldPos)
					end
				else
					if CurrentTween then CurrentTween:Cancel(); CurrentTween = nil end
					UserInputService.MouseDeltaSensitivity = MouseSens
					Target = nil
				end
			else
				if CurrentTween then CurrentTween:Cancel(); CurrentTween = nil end
				UserInputService.MouseDeltaSensitivity = MouseSens
				Aiming = false; Target = nil
			end
		end

		-- AIMBOT SILENT (target tracking only, hooks do the work)
		if C.Aimbot and C.AimMode == "Silent" then
			local pressed = UserInputService:IsMouseButtonPressed(C.AimKey)
			if Aiming or pressed then
				Aiming = true
				if not IsReady(Target) then Target = findTarget() end
			else
				Aiming = false; Target = nil
			end
		end

		-- SPINBOT
		if C.SpinBot and Spinning then
			local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(C.SpinVelocity), 0)
			end
		end
	end

	-- HITBOX
	if C.HitBox then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and (not C.HitBoxEnemyOnly or not isTeammate(p)) then
				local char = p.Character
				if char then
					for _, v in ipairs(char:GetDescendants()) do
						if v:IsA("BasePart") then
							pcall(function()
								v.Size = Vector3.new(C.HitBoxSize, C.HitBoxSize, C.HitBoxSize)
							end)
						end
					end
				end
			end
		end
	end

	-- INFINITE AMMO
	if C.InfAmmo then
		local char = LP.Character
		if char then
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("IntValue") or v:IsA("NumberValue") then
					local n = v.Name:lower()
					if (n:find("ammo") or n:find("bullet") or n:find("mag") or n:find("clip"))
						and v.Value < 200 then
						pcall(function() v.Value = 9999 end)
					end
				end
			end
		end
	end

	-- NO SPREAD
	if C.NoSpread then
		local char = LP.Character
		if char then
			for _, tool in ipairs(char:GetChildren()) do
				if tool:IsA("Tool") then
					for _, v in ipairs(tool:GetDescendants()) do
						if v:IsA("NumberValue") or v:IsA("IntValue") then
							local n = v.Name:lower()
							if n:find("spread") or n:find("recoil") or n:find("scatter") or n:find("bloom") then
								pcall(function() v.Value = 0 end)
							end
						end
					end
				end
			end
		end
	end

	-- ESP RENDER
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LP then continue end
		local o = ESPPool[p]; if not o then continue end

		local teammate = isTeammate(p)
		local show     = C.ESP and ((teammate and C.ESPTeammates) or (not teammate and C.ESPEnemies))
		local char     = p.Character
		local hum      = char and char:FindFirstChildOfClass("Humanoid")
		local root     = char and char:FindFirstChild("HumanoidRootPart")

		if not show or not root or not hum or hum.Health <= 0 then
			hideESP(o); continue
		end

		local dist = (Camera.CFrame.Position - root.Position).Magnitude
		if dist > C.ESPMaxDist then hideESP(o); continue end

		local rootSP, onScreen = getScreenPos(root.Position)
		if not onScreen then hideESP(o); continue end

		local head = char:FindFirstChild("Head")
		if not head then hideESP(o); continue end

		local mainColor = teammate and C.ESPTeamColor or C.ESPEnemyColor
		local hp        = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
		local hpColor   = Color3.fromHSV(hp * 0.33, 1, 1)

		local topSP  = getScreenPos(head.Position + Vector3.new(0,0.7,0))
		local botSP  = getScreenPos(root.Position  - Vector3.new(0,2.8,0))
		local height = math.abs(topSP.Y - botSP.Y)
		if height < 2 then hideESP(o); continue end
		local width = height * 0.55
		local left  = rootSP.X - width/2
		local top   = topSP.Y

		if C.ESPBoxes then
			o.fill.Position=Vector2.new(left,top); o.fill.Size=Vector2.new(width,height)
			o.fill.Color=mainColor; o.fill.Visible=true
			o.box.Position=Vector2.new(left,top);  o.box.Size=Vector2.new(width,height)
			o.box.Color=mainColor;  o.box.Visible=true
			drawCorners(o, left, top, width, height, Color3.fromRGB(255,255,255))
		else
			o.fill.Visible=false; o.box.Visible=false
			for _, k in ipairs(CORNER_KEYS) do o[k].Visible=false end
		end

		if C.ESPHealth then
			local bw=4; local bh=height; local fill=bh*hp
			o.hpOutline.Position=Vector2.new(left-bw-4,top); o.hpOutline.Size=Vector2.new(bw,bh); o.hpOutline.Visible=true
			o.hpBg.Position=Vector2.new(left-bw-4,top);      o.hpBg.Size=Vector2.new(bw,bh);      o.hpBg.Visible=true
			o.hpBar.Position=Vector2.new(left-bw-4,top+bh-fill); o.hpBar.Size=Vector2.new(bw,fill)
			o.hpBar.Color=hpColor; o.hpBar.Visible=true
			o.hpText.Text=math.floor(hum.Health).."hp"
			o.hpText.Position=Vector2.new(left-bw-4+bw/2, top+bh+2); o.hpText.Visible=true
		else
			o.hpOutline.Visible=false; o.hpBg.Visible=false; o.hpBar.Visible=false; o.hpText.Visible=false
		end

		if C.ESPNames then
			o.nameLbl.Text=p.DisplayName; o.nameLbl.Color=Color3.fromRGB(255,255,255)
			o.nameLbl.Position=Vector2.new(rootSP.X, top-28); o.nameLbl.Visible=true
			o.tagLbl.Text=teammate and "[TEAM]" or "[ENEMY]"; o.tagLbl.Color=mainColor
			o.tagLbl.Position=Vector2.new(rootSP.X, top-16);  o.tagLbl.Visible=true
		else o.nameLbl.Visible=false; o.tagLbl.Visible=false end

		if C.ESPDistance then
			o.distLbl.Text=math.floor(dist).."m"
			o.distLbl.Position=Vector2.new(rootSP.X, top+height+3); o.distLbl.Visible=true
		else o.distLbl.Visible=false end

		if C.ESPTracers then
			o.tracer.From=Vector2.new(center.X,vp.Y); o.tracer.To=rootSP
			o.tracer.Color=mainColor; o.tracer.Visible=true
		else o.tracer.Visible=false end

		if C.ESPHeadDot then
			local hsp = getScreenPos(head.Position)
			o.headDot.Position=hsp;  o.headDot.Color=Color3.fromRGB(255,255,255); o.headDot.Visible=true
			o.headFill.Position=hsp; o.headFill.Color=mainColor;                   o.headFill.Visible=true
		else o.headDot.Visible=false; o.headFill.Visible=false end

		if C.ESPSkeleton then
			for idx, pair in ipairs(SKEL_PAIRS) do
				local b1=char:FindFirstChild(pair[1]); local b2=char:FindFirstChild(pair[2])
				local ln=o.skel[idx]
				if b1 and b2 then
					ln.From=getScreenPos(b1.Position); ln.To=getScreenPos(b2.Position)
					ln.Color=mainColor; ln.Visible=true
				else ln.Visible=false end
			end
		else for _, l in ipairs(o.skel) do l.Visible=false end end
	end
end)

-- ══════════════════════════════════════════════════════
-- UI
-- ══════════════════════════════════════════════════════
local Win = Rayfield:CreateWindow({
	Name="Astra Hub", Icon=0,
	LoadingTitle="Astra Hub", LoadingSubtitle="Loading...",
	Theme="Default",
	ConfigurationSaving={Enabled=true, FileName="AstraHub"},
	KeySystem=false,
})

-- ── AIMBOT TAB ────────────────────────────────────────
local AimTab = Win:CreateTab("Aimbot", 4483362458)

AimTab:CreateSection("Aimbot")
AimTab:CreateToggle({Name="Enable Aimbot", CurrentValue=false, Flag="AimOn",
	Callback=function(v) C.Aimbot=v; if not v then resetAim() end end})
AimTab:CreateDropdown({Name="Aim Mode", Options={"Camera","Silent"}, CurrentOption={"Camera"}, Flag="AimMode",
	Callback=function(v) C.AimMode=v[1]; resetAim() end})
AimTab:CreateToggle({Name="One-Press Mode (toggle instead of hold)", CurrentValue=false, Flag="OnePressAim",
	Callback=function(v) C.OnePressAim=v end})
AimTab:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="AimTeam",
	Callback=function(v) C.TeamCheck=v end})
AimTab:CreateToggle({Name="Alive Check", CurrentValue=true, Flag="AliveChk",
	Callback=function(v) C.AliveCheck=v end})
AimTab:CreateToggle({Name="Wall Check", CurrentValue=false, Flag="WallChk",
	Callback=function(v) C.WallCheck=v end})
AimTab:CreateToggle({Name="FOV Check", CurrentValue=true, Flag="FovChk",
	Callback=function(v) C.FoVCheck=v end})
AimTab:CreateToggle({Name="Show FOV Circle", CurrentValue=true, Flag="ShowFov",
	Callback=function(v) C.ShowFoV=v end})
AimTab:CreateSlider({Name="FOV Radius", Range={10,500}, Increment=1, CurrentValue=150, Flag="FovR",
	Callback=function(v) C.FoVRadius=v end})
AimTab:CreateDropdown({Name="Target Bone", Options={"Head","HumanoidRootPart","UpperTorso","LowerTorso"}, CurrentOption={"Head"}, Flag="AimBone",
	Callback=function(v) C.AimPart=v[1] end})

AimTab:CreateSection("Camera Smoothness")
AimTab:CreateToggle({Name="Use Smoothness", CurrentValue=true, Flag="UseSm",
	Callback=function(v) C.UseSmoothness=v end})
AimTab:CreateSlider({Name="Smoothness (lower = snappier)", Range={1,99}, Increment=1, CurrentValue=15, Flag="SmVal",
	Callback=function(v) C.Smoothness=v end})

AimTab:CreateSection("Aim Offset")
AimTab:CreateToggle({Name="Use Offset", CurrentValue=false, Flag="UseOff",
	Callback=function(v) C.UseOffset=v end})
AimTab:CreateSlider({Name="Static Offset (Y)", Range={0,50}, Increment=1, CurrentValue=0, Flag="StatOff",
	Callback=function(v) C.StaticOffset=v end})
AimTab:CreateSlider({Name="Dynamic Offset (movement pred)", Range={0,50}, Increment=1, CurrentValue=0, Flag="DynOff",
	Callback=function(v) C.DynamicOffset=v end})

AimTab:CreateSection("Humanization")
AimTab:CreateToggle({Name="Noise / Human Shake", CurrentValue=false, Flag="UseNoise",
	Callback=function(v) C.UseNoise=v end})
AimTab:CreateSlider({Name="Noise Strength", Range={1,100}, Increment=1, CurrentValue=20, Flag="NoiseStr",
	Callback=function(v) C.NoiseStrength=v end})

AimTab:CreateSection("Silent Aim Methods")
AimTab:CreateParagraph({Title="Info", Content="Silent mode hooks Mouse.Hit, Raycast and more so bullets bend to target without moving your camera."})
AimTab:CreateToggle({Name="Mouse.Hit / Mouse.Target", CurrentValue=true, Flag="SilHit",
	Callback=function(v) C.SilentMouseHit=v; C.SilentMouseTarget=v end})
AimTab:CreateToggle({Name="GetMouseLocation", CurrentValue=true, Flag="SilGML",
	Callback=function(v) C.SilentGetMouseLoc=v end})
AimTab:CreateToggle({Name="Raycast", CurrentValue=true, Flag="SilRay",
	Callback=function(v) C.SilentRaycast=v end})
AimTab:CreateToggle({Name="FindPartOnRay", CurrentValue=true, Flag="SilFPOR",
	Callback=function(v) C.SilentFindPart=v end})

-- ── ESP TAB ───────────────────────────────────────────
local ESPTab = Win:CreateTab("ESP", 4483362458)

ESPTab:CreateSection("Targets")
ESPTab:CreateToggle({Name="Enable ESP", CurrentValue=false, Flag="ESPOn",
	Callback=function(v) C.ESP=v end})
ESPTab:CreateToggle({Name="Show Enemies", CurrentValue=true, Flag="ESPEnemy",
	Callback=function(v) C.ESPEnemies=v end})
ESPTab:CreateToggle({Name="Show Teammates", CurrentValue=true, Flag="ESPTeam",
	Callback=function(v) C.ESPTeammates=v end})

ESPTab:CreateSection("Elements")
ESPTab:CreateToggle({Name="Boxes + Corners", CurrentValue=true, Flag="ESPBox",
	Callback=function(v) C.ESPBoxes=v end})
ESPTab:CreateToggle({Name="Names + Tag", CurrentValue=true, Flag="ESPName",
	Callback=function(v) C.ESPNames=v end})
ESPTab:CreateToggle({Name="Health Bar", CurrentValue=true, Flag="ESPHp",
	Callback=function(v) C.ESPHealth=v end})
ESPTab:CreateToggle({Name="Distance", CurrentValue=true, Flag="ESPDist",
	Callback=function(v) C.ESPDistance=v end})
ESPTab:CreateToggle({Name="Tracers", CurrentValue=false, Flag="ESPTrace",
	Callback=function(v) C.ESPTracers=v end})
ESPTab:CreateToggle({Name="Skeleton", CurrentValue=false, Flag="ESPSkel",
	Callback=function(v) C.ESPSkeleton=v end})
ESPTab:CreateToggle({Name="Head Dot", CurrentValue=true, Flag="ESPHead",
	Callback=function(v) C.ESPHeadDot=v end})
ESPTab:CreateSlider({Name="Max Distance (studs)", Range={100,2000}, Increment=50, CurrentValue=1000, Flag="ESPMax",
	Callback=function(v) C.ESPMaxDist=v end})

-- ── COMBAT TAB ────────────────────────────────────────
local CombatTab = Win:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("HitBox Expander")
CombatTab:CreateToggle({Name="Enable HitBox", CurrentValue=false, Flag="HitOn",
	Callback=function(v) C.HitBox=v end})
CombatTab:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="HitTeam",
	Callback=function(v) C.HitBoxEnemyOnly=v end})
CombatTab:CreateSlider({Name="HitBox Size", Range={1,20}, Increment=0.5, CurrentValue=5, Flag="HitSz",
	Callback=function(v) C.HitBoxSize=v end})

CombatTab:CreateSection("TriggerBot")
CombatTab:CreateToggle({Name="Enable TriggerBot", CurrentValue=false, Flag="TrigOn",
	Callback=function(v) C.TriggerBot=v; if not v then Triggering=false end end})
CombatTab:CreateToggle({Name="One-Press Mode (E toggle)", CurrentValue=false, Flag="OnePTrig",
	Callback=function(v) C.OnePressTrigger=v end})
CombatTab:CreateToggle({Name="Smart Trigger (IsReady check)", CurrentValue=true, Flag="SmartTrig",
	Callback=function(v) C.SmartTrigger=v end})
CombatTab:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="TrigTeam",
	Callback=function(v) C.TeamCheck=v end})
CombatTab:CreateSlider({Name="Trigger Delay (ms)", Range={1,200}, Increment=1, CurrentValue=50, Flag="TrigDelay",
	Callback=function(v) C.TriggerDelay=v/1000 end})
CombatTab:CreateSlider({Name="Trigger Chance (%)", Range={1,100}, Increment=1, CurrentValue=100, Flag="TrigChance",
	Callback=function(v) C.TriggerChance=v end})
CombatTab:CreateParagraph({Title="Key", Content="Hold E to activate. Enable One-Press to toggle instead."})

CombatTab:CreateSection("SpinBot")
CombatTab:CreateToggle({Name="Enable SpinBot", CurrentValue=false, Flag="SpinOn",
	Callback=function(v) C.SpinBot=v; if not v then Spinning=false end end})
CombatTab:CreateToggle({Name="One-Press Mode (Q toggle)", CurrentValue=false, Flag="OnePSpin",
	Callback=function(v) C.OnePressSpinBot=v end})
CombatTab:CreateSlider({Name="Spin Speed", Range={1,200}, Increment=1, CurrentValue=50, Flag="SpinSpd",
	Callback=function(v) C.SpinVelocity=v end})
CombatTab:CreateParagraph({Title="Key", Content="Hold Q to spin. Enable One-Press to toggle instead."})

CombatTab:CreateSection("Ammo & Accuracy")
CombatTab:CreateToggle({Name="Infinite Ammo", CurrentValue=false, Flag="InfAmmoOn",
	Callback=function(v) C.InfAmmo=v end})
CombatTab:CreateToggle({Name="No Spread / No Recoil", CurrentValue=false, Flag="NoSpreadOn",
	Callback=function(v) C.NoSpread=v end})

-- ── CHAMS TAB ─────────────────────────────────────────
local ChamsTab = Win:CreateTab("Chams", 4483362458)

ChamsTab:CreateSection("Chams")
ChamsTab:CreateToggle({Name="Enable Chams", CurrentValue=false, Flag="ChamsOn",
	Callback=function(v) C.Chams=v; refreshChams() end})
ChamsTab:CreateSlider({Name="Transparency", Range={0,90}, Increment=5, CurrentValue=40, Flag="ChamsT",
	Callback=function(v) C.ChamsTransp=v/100; if C.Chams then refreshChams() end end})

ChamsTab:CreateSection("Enemy Color")
for name, rgb in pairs({Red={255,50,50}, Orange={255,140,0}, Yellow={255,220,0}, Pink={255,80,200}, White={240,240,240}}) do
	ChamsTab:CreateButton({Name="Enemy: "..name, Callback=function()
		C.ChamsEnemyColor=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
		if C.Chams then refreshChams() end
	end})
end

ChamsTab:CreateSection("Teammate Color")
for name, rgb in pairs({Blue={50,100,255}, Cyan={0,200,255}, Green={50,220,100}, Purple={160,50,255}}) do
	ChamsTab:CreateButton({Name="Team: "..name, Callback=function()
		C.ChamsTeamColor=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
		if C.Chams then refreshChams() end
	end})
end
ChamsTab:CreateButton({Name="Refresh Chams", Callback=function()
	if C.Chams then refreshChams() end
	Rayfield:Notify({Title="Astra Hub", Content="Chams refreshed", Duration=2})
end})

-- ── MISC TAB ──────────────────────────────────────────
local MiscTab = Win:CreateTab("Misc", 4483362458)

MiscTab:CreateSection("Camera FOV")
MiscTab:CreateToggle({Name="Custom FOV", CurrentValue=false, Flag="CamFOVOn",
	Callback=function(v)
		C.CustomFOV=v
		if not v then Camera.FieldOfView=C.DefaultFOV end
	end})
MiscTab:CreateSlider({Name="FOV Value", Range={30,120}, Increment=1, CurrentValue=70, Flag="CamFOVVal",
	Callback=function(v) C.FOVValue=v end})

MiscTab:CreateSection("Anti-AFK")
MiscTab:CreateToggle({Name="Anti-AFK", CurrentValue=false, Flag="AntiAFKOn",
	Callback=function(v) C.AntiAFK=v end})

MiscTab:CreateSection("Actions")
MiscTab:CreateButton({Name="Disable ALL", Callback=function()
	C.Aimbot=false; C.ESP=false; C.HitBox=false; C.Chams=false
	C.InfAmmo=false; C.NoSpread=false; C.SpinBot=false
	C.TriggerBot=false; C.CustomFOV=false; C.AntiAFK=false
	Aiming=false; Spinning=false; Triggering=false
	resetAim(); refreshChams()
	Camera.FieldOfView=C.DefaultFOV
	Rayfield:Notify({Title="Astra Hub", Content="All disabled", Duration=3})
end})
MiscTab:CreateButton({Name="Destroy Script", Callback=function()
	pcall(function() fovCircle:Remove() end)
	for _, p in ipairs(Players:GetPlayers()) do clearESP(p); clearChams(p) end
	resetAim()
	Camera.FieldOfView=C.DefaultFOV
	pcall(function() Rayfield:Destroy() end)
end})

-- ── SETTINGS TAB ──────────────────────────────────────
local SetTab = Win:CreateTab("Settings", 4483362458)

SetTab:CreateSection("Hook Status")
SetTab:CreateParagraph({
	Title="Silent __index",
	Content=silentIndexOk and "Mouse.Hit / Target: ACTIVE ✓" or "Not supported on this executor",
})
SetTab:CreateParagraph({
	Title="Silent __namecall",
	Content=silentCallOk and "Raycast / GetMouseLocation: ACTIVE ✓" or "Not supported on this executor",
})
SetTab:CreateSection("Controls")
SetTab:CreateParagraph({
	Title="Key Binds",
	Content="Aimbot: hold RMB\nSpinBot: hold Q (or toggle)\nTriggerBot: hold E (or toggle)",
})

Rayfield:Notify({
	Title="Astra Hub",
	Content="Loaded!  RMB=Aim  Q=Spin  E=Trigger",
	Duration=5,
})
