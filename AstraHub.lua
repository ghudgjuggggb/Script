-- ╔══════════════════════════════════════════════╗
-- ║          ASTRA HUB  v1.0  CLEAN BUILD        ║
-- ║  Based on Open-Aimbot reference patterns     ║
-- ║  All bugs fixed | PC + Mobile full support   ║
-- ╚══════════════════════════════════════════════╝

-- ─── Rayfield ─────────────────────────────────────────────────────
local ok_rf, Rayfield = pcall(function()
	return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok_rf then
	warn("[AstraHub] Rayfield failed to load")
	return
end

-- ─── Services ─────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer
local Mouse            = LP:GetMouse()

-- ─── Device ───────────────────────────────────────────────────────
-- Reference pattern: IsComputer = KeyboardEnabled and MouseEnabled
local IsComputer = UserInputService.KeyboardEnabled and UserInputService.MouseEnabled
local IS_MOBILE  = not IsComputer

-- ─── Configuration (matches reference pattern) ────────────────────
local C = {
	-- Aimbot
	Aimbot          = false,
	AimMode         = "Camera",      -- "Camera" | "Silent"
	AimKey          = Enum.UserInputType.MouseButton2,
	OnePressMode    = false,
	AimPart         = "Head",
	TeamCheck       = true,
	AliveCheck      = true,
	WallCheck       = false,
	FoVCheck        = true,
	FoVRadius       = 120,
	UseSensitivity  = true,
	Sensitivity     = 12,            -- maps to lerp alpha (1-100)
	UseNoise        = false,
	NoiseFrequency  = 30,
	Prediction      = true,
	PredStrength    = 0.06,
	ShowFoV         = true,

	-- Silent Aim (separate mode)
	SilentAim       = false,
	SilentPart      = "Head",
	SilentFoV       = 150,
	SilentTeamCheck = true,

	-- Magic Bullet
	MagicBullet     = false,
	MagicPart       = "HumanoidRootPart",
	MagicFoV        = 200,
	MagicTeamCheck  = true,

	-- ESP
	ESPEnabled      = false,
	ESPBox          = true,
	ESPBoxFilled    = false,
	ESPName         = true,
	ESPHealth       = true,
	ESPDistance     = true,
	ESPTracer       = false,
	ESPSkeleton     = false,
	ESPHeadDot      = true,
	ESPEnemies      = true,
	ESPTeammates    = false,
	ESPMaxDist      = 1000,
	ESPThickness    = 1.5,
	ESPColour       = Color3.fromRGB(255, 60, 60),
	ESPTeamColour   = Color3.fromRGB(60, 180, 255),

	-- HitBox (only expands the specific bone, not all parts)
	HitBox          = false,
	HitBoxPart      = "Head",
	HitBoxSize      = 5,
	HitBoxTeam      = true,

	-- Chams
	Chams           = false,
	ChamsEnemyCol   = Color3.fromRGB(255, 50, 50),
	ChamsTeamCol    = Color3.fromRGB(50, 120, 255),
	ChamsTransp     = 0.4,

	-- Combat
	InfAmmo         = false,
	NoSpread        = false,

	-- Internal
	_aiming         = false,   -- one-press toggle state
	_mobileAim      = false,   -- mobile button held
}

-- ─── Velocity Cache (reference pattern: Heartbeat delta) ──────────
-- Cleaned on PlayerRemoving to prevent memory leak
local VelCache = {}
local PosCache = {}

RunService.Heartbeat:Connect(function(dt)
	if dt <= 0 then return end
	for _, p in next, Players:GetPlayers() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local prev = PosCache[p]
			local curr = root.Position
			if prev then VelCache[p] = (curr - prev) / dt end
			PosCache[p] = curr
		end
	end
end)

Players.PlayerRemoving:Connect(function(p)
	VelCache[p] = nil
	PosCache[p] = nil
end)

-- ─── Helpers ──────────────────────────────────────────────────────
local function isTeammate(p)
	if p == LP then return true end
	local t = LP.Team
	return t ~= nil and p.Team ~= nil and p.Team == t
end

local function isAlive(p)
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

-- Reference: IsReady pattern — validates all checks before targeting
local function isReady(p, teamCheck, wallCheck, fovCheck, fovRadius)
	if p == LP then return false end
	if not p.Character then return false end
	if C.AliveCheck and not isAlive(p) then return false end
	if teamCheck and isTeammate(p) then return false end
	return true
end

local function getPart(p, partName)
	local c = p.Character
	if not c then return nil end
	return c:FindFirstChild(partName) or c:FindFirstChild("HumanoidRootPart")
end

local function getHum(p)
	return p.Character and p.Character:FindFirstChildOfClass("Humanoid")
end

local function toScreen(worldPos)
	local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
	return Vector2.new(sp.X, sp.Y), onScreen, sp.Z
end

local function screenCenter()
	local vp = Camera.ViewportSize
	return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end

-- Reference: predicted position using velocity delta
local function getPredicted(p, partName)
	local part = getPart(p, partName)
	if not part then return nil end
	local vel = VelCache[p]
	return vel and (part.Position + vel * C.PredStrength) or part.Position
end

-- Reference: closest target by FOV distance
local function getClosest(fov, partName, teamCheck)
	local center     = screenCenter()
	local best, dist = nil, fov
	for _, p in next, Players:GetPlayers() do
		if isReady(p, teamCheck) then
			local pos = C.Prediction and getPredicted(p, partName) or nil
			if not pos then
				local part = getPart(p, partName)
				if part then pos = part.Position end
			end
			if pos then
				local sp, onScreen = toScreen(pos)
				if onScreen then
					local d = (sp - center).Magnitude
					if d < dist then dist = d; best = p end
				end
			end
		end
	end
	return best
end

-- ─── Silent Aim / Magic Bullet hook ──────────────────────────────
-- Reference pattern: hookmetamethod / getrawmetatable + newcclosure
-- Fixed: uses table.unpack (not unpack), manual arg copy (no table.clone)
local HookOk = pcall(function()
	local mt    = getrawmetatable(game)
	local oldNC = mt.__namecall
	setreadonly(mt, false)

	mt.__namecall = newcclosure(function(self, ...)
		local method = getnamecallmethod()

		if method == "FireServer" or method == "InvokeServer" then
			-- Manual arg copy — table.clone doesn't exist on all executors
			local raw  = {...}
			local args = {}
			for i = 1, #raw do args[i] = raw[i] end

			local changed = false

			-- Silent Aim
			if C.SilentAim then
				local t = getClosest(C.SilentFoV, C.SilentPart, C.SilentTeamCheck)
				if t then
					local part = getPart(t, C.SilentPart)
					if part then
						local pos = C.Prediction and getPredicted(t, C.SilentPart) or part.Position
						for i = 1, #args do
							local v = args[i]
							if typeof(v) == "Instance" and v:IsA("BasePart") then
								args[i] = part; changed = true
							elseif typeof(v) == "CFrame" then
								args[i] = CFrame.new(pos); changed = true
							elseif typeof(v) == "Vector3" then
								args[i] = pos; changed = true
							end
						end
					end
				end
			end

			-- Magic Bullet (only if Silent Aim didn't already modify)
			if C.MagicBullet and not C.SilentAim then
				local t = getClosest(C.MagicFoV, C.MagicPart, C.MagicTeamCheck)
				if t then
					local part = getPart(t, C.MagicPart)
					if part then
						local pos = C.Prediction and getPredicted(t, C.MagicPart) or part.Position
						for i = 1, #args do
							local v = args[i]
							if typeof(v) == "Vector3" then
								args[i] = pos; changed = true
							elseif typeof(v) == "CFrame" then
								args[i] = CFrame.new(pos); changed = true
							end
						end
					end
				end
			end

			if changed then
				-- Fixed: table.unpack, NOT global unpack
				return oldNC(self, table.unpack(args))
			end
		end

		return oldNC(self, ...)
	end)

	setreadonly(mt, true)
end)

-- ─── Drawing helper ───────────────────────────────────────────────
local function D(t, props)
	local ok, d = pcall(Drawing.new, t)
	if not ok then
		-- return stub so code never errors on d.Visible = etc
		return setmetatable({}, {
			__index    = function() return 0 end,
			__newindex = function() end,
		})
	end
	for k, v in pairs(props) do pcall(function() d[k] = v end) end
	return d
end

-- ─── FOV circles ──────────────────────────────────────────────────
local fovCircle    = D("Circle",{Visible=false,Color=Color3.fromRGB(255,255,255),Thickness=1.5,Filled=false,NumSides=64})
local silentCircle = D("Circle",{Visible=false,Color=Color3.fromRGB(0,200,255),  Thickness=1.5,Filled=false,NumSides=64})
local magicCircle  = D("Circle",{Visible=false,Color=Color3.fromRGB(200,80,255), Thickness=1.5,Filled=false,NumSides=64})

-- ─── Skeleton definition ──────────────────────────────────────────
local SKEL = {
	{"Head","UpperTorso"},
	{"UpperTorso","LowerTorso"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
}

-- ─── ESP pool ─────────────────────────────────────────────────────
local ESPPool   = {}
local ChamsPool = {}

local CORNER_KEYS = {"cTLh","cTLv","cTRh","cTRv","cBLh","cBLv","cBRh","cBRv"}

local function makeESP(p)
	if ESPPool[p] then return end
	local o = {}
	-- Fixed: Drawing.Fonts.UI instead of hardcoded Font=2
	local font = Drawing.Fonts.UI

	o.boxFill = D("Square",{Filled=true, Transparency=0.75,Visible=false,Thickness=0,Color=Color3.fromRGB(255,60,60)})
	o.box     = D("Square",{Filled=false,Thickness=1.5,    Visible=false,            Color=Color3.fromRGB(255,60,60)})

	for _, k in ipairs(CORNER_KEYS) do
		o[k] = D("Line",{Color=Color3.fromRGB(255,255,255),Thickness=2,Visible=false})
	end

	o.hpBg      = D("Square",{Filled=true, Color=Color3.fromRGB(10,10,10), Visible=false,Thickness=0})
	o.hpBar     = D("Square",{Filled=true, Color=Color3.fromRGB(50,220,50),Visible=false,Thickness=0})
	o.hpOutline = D("Square",{Filled=false,Color=Color3.fromRGB(0,0,0),    Visible=false,Thickness=1})
	o.hpText    = D("Text",  {Font=font,Size=10,Color=Color3.fromRGB(255,255,255),Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true})

	o.nameLbl = D("Text",{Font=font,Size=13,Color=Color3.fromRGB(255,255,255),Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true})
	o.tagLbl  = D("Text",{Font=font,Size=11,Color=Color3.fromRGB(60,180,255), Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true})
	o.distLbl = D("Text",{Font=font,Size=11,Color=Color3.fromRGB(180,180,180),Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true})

	o.tracer   = D("Line",  {Color=Color3.fromRGB(255,60,60),Thickness=1,  Visible=false})
	o.headDot  = D("Circle",{Color=Color3.fromRGB(255,255,255),Thickness=1.5,Filled=false,NumSides=32,Radius=4,Visible=false})
	o.headFill = D("Circle",{Color=Color3.fromRGB(255,60,60), Transparency=0.5,Filled=true,NumSides=32,Radius=4,Visible=false})

	o.skel = {}
	for _ = 1, #SKEL do
		table.insert(o.skel, D("Line",{Color=Color3.fromRGB(255,255,255),Thickness=1,Visible=false}))
	end

	ESPPool[p] = o
end

local function hideESP(o)
	if not o then return end
	local flat = {"boxFill","box","hpBg","hpBar","hpOutline","hpText","nameLbl","tagLbl","distLbl","tracer","headDot","headFill"}
	for _, k in ipairs(flat) do pcall(function() o[k].Visible = false end) end
	for _, k in ipairs(CORNER_KEYS) do pcall(function() o[k].Visible = false end) end
	if o.skel then for _, l in ipairs(o.skel) do pcall(function() l.Visible = false end) end end
end

local function clearESP(p)
	local o = ESPPool[p]
	if not o then return end
	local flat = {"boxFill","box","hpBg","hpBar","hpOutline","hpText","nameLbl","tagLbl","distLbl","tracer","headDot","headFill"}
	for _, k in ipairs(flat) do pcall(function() o[k]:Remove() end) end
	for _, k in ipairs(CORNER_KEYS) do pcall(function() o[k]:Remove() end) end
	if o.skel then for _, l in ipairs(o.skel) do pcall(function() l:Remove() end) end end
	ESPPool[p] = nil
end

local function drawCorners(o, l, t, w, h, col)
	local cl  = math.min(w, h) * 0.22
	local r, b = l + w, t + h
	local pts = {
		{o.cTLh, Vector2.new(l,t), Vector2.new(l+cl,t)},
		{o.cTLv, Vector2.new(l,t), Vector2.new(l,t+cl)},
		{o.cTRh, Vector2.new(r,t), Vector2.new(r-cl,t)},
		{o.cTRv, Vector2.new(r,t), Vector2.new(r,t+cl)},
		{o.cBLh, Vector2.new(l,b), Vector2.new(l+cl,b)},
		{o.cBLv, Vector2.new(l,b), Vector2.new(l,b-cl)},
		{o.cBRh, Vector2.new(r,b), Vector2.new(r-cl,b)},
		{o.cBRv, Vector2.new(r,b), Vector2.new(r,b-cl)},
	}
	for _, c in ipairs(pts) do
		c[1].From=c[2]; c[1].To=c[3]; c[1].Color=col; c[1].Visible=true
	end
end

-- ─── Chams ────────────────────────────────────────────────────────
local function clearChams(p)
	local list = ChamsPool[p]
	if not list then return end
	for _, info in ipairs(list) do
		pcall(function()
			info.part.Material    = info.orig.Material
			info.part.Color       = info.orig.Color
			info.part.Transparency= info.orig.Transparency
		end)
	end
	ChamsPool[p] = nil
end

local function applyChams(p)
	local char = p.Character
	if not char then return end
	clearChams(p)
	ChamsPool[p] = {}
	local col = isTeammate(p) and C.ChamsTeamCol or C.ChamsEnemyCol
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			local orig = {Material=v.Material, Color=v.Color, Transparency=v.Transparency}
			table.insert(ChamsPool[p], {part=v, orig=orig})
			pcall(function()
				v.Material    = Enum.Material.Neon
				v.Color       = col
				v.Transparency= C.ChamsTransp
			end)
		end
	end
end

local function refreshChams()
	for _, p in ipairs(Players:GetPlayers()) do
		clearChams(p)
		if C.Chams and p ~= LP and isAlive(p) then pcall(applyChams, p) end
	end
end

-- ─── Player tracking init ─────────────────────────────────────────
for _, p in next, Players:GetPlayers() do
	if p ~= LP then
		makeESP(p)
		p.CharacterAdded:Connect(function()
			task.wait(0.4)
			if C.Chams then pcall(applyChams, p) end
		end)
	end
end

Players.PlayerAdded:Connect(function(p)
	task.wait(0.15)
	makeESP(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.4)
		if C.Chams then pcall(applyChams, p) end
	end)
end)

Players.PlayerRemoving:Connect(function(p)
	clearESP(p)
	clearChams(p)
end)

-- ─── HitBox state (only one bone, restores on disable) ────────────
-- Fixed: no longer resizes ALL parts every frame
local HitBoxStore = {}

local function applyHitBox(p)
	if not isReady(p, C.HitBoxTeam) or not p.Character then return end
	local bone = p.Character:FindFirstChild(C.HitBoxPart)
	         or p.Character:FindFirstChild("HumanoidRootPart")
	if not bone or not bone:IsA("BasePart") then return end
	if not HitBoxStore[p] then
		HitBoxStore[p] = {part=bone, orig=bone.Size}
	elseif HitBoxStore[p].part ~= bone then
		-- bone changed, restore old
		pcall(function() HitBoxStore[p].part.Size = HitBoxStore[p].orig end)
		HitBoxStore[p] = {part=bone, orig=bone.Size}
	end
	pcall(function() bone.Size = Vector3.new(C.HitBoxSize, C.HitBoxSize, C.HitBoxSize) end)
end

local function restoreHitBox()
	for _, info in pairs(HitBoxStore) do
		pcall(function() info.part.Size = info.orig end)
	end
	HitBoxStore = {}
end

-- ─── Mobile AIM button ────────────────────────────────────────────
-- Fixed: no TouchLongPress (doesn't exist on TextButton/ImageButton)
-- Uses MouseButton1Down/Up which works for both touch and mouse
local mobileGui    = nil
local mobileAimBtn = nil

if IS_MOBILE then
	mobileGui = Instance.new("ScreenGui")
	mobileGui.Name           = "AstraHubMobile"
	mobileGui.ResetOnSpawn   = false
	mobileGui.IgnoreGuiInset = true
	mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mobileGui.Parent         = LP.PlayerGui

	mobileAimBtn = Instance.new("TextButton")
	mobileAimBtn.Size             = UDim2.new(0, 76, 0, 76)
	mobileAimBtn.Position         = UDim2.new(1, -90, 1, -170)
	mobileAimBtn.BackgroundColor3 = Color3.fromRGB(190, 30, 30)
	mobileAimBtn.BackgroundTransparency = 0.2
	mobileAimBtn.Text             = "🎯"
	mobileAimBtn.TextSize         = 30
	mobileAimBtn.Font             = Enum.Font.GothamBold
	mobileAimBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	mobileAimBtn.Visible          = false
	mobileAimBtn.Parent           = mobileGui

	local corner  = Instance.new("UICorner",  mobileAimBtn); corner.CornerRadius = UDim.new(1,0)
	local stroke  = Instance.new("UIStroke",  mobileAimBtn)
	stroke.Color  = Color3.fromRGB(255,255,255); stroke.Thickness = 2

	-- Fixed: MouseButton1Down/Up (works on both touch + mouse)
	mobileAimBtn.MouseButton1Down:Connect(function()
		C._mobileAim = true
		mobileAimBtn.BackgroundColor3 = Color3.fromRGB(255,50,50)
	end)
	mobileAimBtn.MouseButton1Up:Connect(function()
		C._mobileAim = false
		mobileAimBtn.BackgroundColor3 = Color3.fromRGB(190,30,30)
	end)
end

-- Reference: OnePressMode support + RMB for PC
local function isAimKeyDown()
	if IS_MOBILE then return C._mobileAim end
	if C.OnePressMode then return C._aiming end
	-- PC: check actual key/button state
	if C.AimKey == Enum.UserInputType.MouseButton2 then
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	end
	return UserInputService:IsKeyDown(C.AimKey)
end

-- One-press toggle
if IsComputer then
	UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if C.Aimbot and C.OnePressMode then
			if (C.AimKey == Enum.UserInputType.MouseButton2 and inp.UserInputType == Enum.UserInputType.MouseButton2)
			or (C.AimKey ~= Enum.UserInputType.MouseButton2 and inp.KeyCode == C.AimKey) then
				C._aiming = not C._aiming
			end
		end
	end)
end

-- ─── Noise helper (reference pattern) ────────────────────────────
local noiseT = 0
local function getNoise()
	noiseT = noiseT + 0.016
	local freq = C.NoiseFrequency / 1000
	return Vector3.new(
		math.noise(noiseT * freq, 0) * 0.4,
		math.noise(0, noiseT * freq) * 0.4,
		0
	)
end

-- ─── Render Loop ──────────────────────────────────────────────────
local CurrentTween = nil  -- reference pattern: cancel old tween before new one

RunService.RenderStepped:Connect(function()
	local vp     = Camera.ViewportSize
	local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)

	-- FOV circles
	fovCircle.Position    = center; fovCircle.Radius    = C.FoVRadius
	silentCircle.Position = center; silentCircle.Radius = C.SilentFoV
	magicCircle.Position  = center; magicCircle.Radius  = C.MagicFoV
	fovCircle.Visible    = C.ShowFoV and C.Aimbot
	silentCircle.Visible = C.SilentAim
	magicCircle.Visible  = C.MagicBullet

	if mobileAimBtn then mobileAimBtn.Visible = C.Aimbot end

	-- ── Aimbot (Camera mode) ──────────────────────────────────────
	-- Reference: CFrame.new(pos, target) — correct approach
	-- Sensitivity uses TweenService (same as reference)
	if C.Aimbot and C.AimMode == "Camera" and isAimKeyDown() then
		local target = getClosest(C.FoVRadius, C.AimPart, C.TeamCheck)
		if target then
			local aimPos = C.Prediction and getPredicted(target, C.AimPart)
			           or (getPart(target, C.AimPart) and getPart(target, C.AimPart).Position)
			if aimPos then
				if C.UseNoise then aimPos = aimPos + getNoise() end
				local _, onScreen = toScreen(aimPos)
				if onScreen then
					if C.UseSensitivity then
						-- Reference pattern: TweenService for smooth Camera aim
						if CurrentTween then CurrentTween:Cancel() end
						CurrentTween = TweenService:Create(
							Camera,
							TweenInfo.new(
								math.clamp(C.Sensitivity, 1, 99) / 100,
								Enum.EasingStyle.Sine,
								Enum.EasingDirection.Out
							),
							{CFrame = CFrame.new(Camera.CFrame.Position, aimPos)}
						)
						CurrentTween:Play()
					else
						-- Instant
						Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)
					end
				end
			end
		else
			if CurrentTween then CurrentTween:Cancel(); CurrentTween = nil end
		end
	elseif not isAimKeyDown() then
		if CurrentTween then CurrentTween:Cancel(); CurrentTween = nil end
	end

	-- ── HitBox ────────────────────────────────────────────────────
	-- Fixed: only targets the specific bone, not all parts
	if C.HitBox then
		for _, p in next, Players:GetPlayers() do
			pcall(applyHitBox, p)
		end
	elseif next(HitBoxStore) then
		restoreHitBox()
	end

	-- ── Infinite Ammo ─────────────────────────────────────────────
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

	-- ── No Spread / Recoil ────────────────────────────────────────
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

	-- ── ESP ───────────────────────────────────────────────────────
	for _, p in next, Players:GetPlayers() do
		if p == LP then continue end
		local o = ESPPool[p]
		if not o then continue end

		local teammate = isTeammate(p)
		local showThis = C.ESPEnabled
			and ((teammate and C.ESPTeammates) or (not teammate and C.ESPEnemies))

		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		local hum  = getHum(p)
		local char = p.Character

		if not showThis or not root or not hum or not char or not isAlive(p) then
			hideESP(o) continue
		end

		local dist = (Camera.CFrame.Position - root.Position).Magnitude
		if dist > C.ESPMaxDist then hideESP(o) continue end

		local rootSP, onScreen = toScreen(root.Position)
		if not onScreen then hideESP(o) continue end

		local headPart = char:FindFirstChild("Head")
		if not headPart then hideESP(o) continue end

		local mainCol = teammate and C.ESPTeamColour or C.ESPColour
		local hp      = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		local hpCol   = Color3.fromHSV(hp * 0.33, 1, 1)

		local topSP,    _ = toScreen(headPart.Position + Vector3.new(0, 0.7, 0))
		local bottomSP, _ = toScreen(root.Position    - Vector3.new(0, 2.8, 0))
		local height      = math.abs(topSP.Y - bottomSP.Y)
		if height < 2 then hideESP(o) continue end

		local width = height * 0.55
		local left  = rootSP.X - width * 0.5
		local top   = topSP.Y

		-- Box + corners
		if C.ESPBox then
			o.boxFill.Position = Vector2.new(left,top); o.boxFill.Size = Vector2.new(width,height)
			o.boxFill.Color    = mainCol; o.boxFill.Visible = not not C.ESPBoxFilled
			o.box.Position     = Vector2.new(left,top); o.box.Size = Vector2.new(width,height)
			o.box.Color        = mainCol; o.box.Thickness = C.ESPThickness; o.box.Visible = true
			drawCorners(o, left, top, width, height, Color3.fromRGB(255,255,255))
		else
			o.box.Visible=false; o.boxFill.Visible=false
			for _, k in ipairs(CORNER_KEYS) do pcall(function() o[k].Visible=false end) end
		end

		-- Health bar (vertical, left side)
		if C.ESPHealth then
			local bw=4; local bh=height; local fill=bh*hp; local bx=left-bw-4
			o.hpBg.Position=Vector2.new(bx,top);          o.hpBg.Size=Vector2.new(bw,bh);   o.hpBg.Visible=true
			o.hpOutline.Position=Vector2.new(bx,top);     o.hpOutline.Size=Vector2.new(bw,bh); o.hpOutline.Visible=true
			o.hpBar.Position=Vector2.new(bx,top+bh-fill); o.hpBar.Size=Vector2.new(bw,fill); o.hpBar.Color=hpCol; o.hpBar.Visible=true
			o.hpText.Text=math.floor(hum.Health).."hp";  o.hpText.Position=Vector2.new(bx+bw*0.5,top+bh+2); o.hpText.Visible=true
		else
			o.hpBg.Visible=false; o.hpOutline.Visible=false; o.hpBar.Visible=false; o.hpText.Visible=false
		end

		-- Names
		if C.ESPName then
			o.nameLbl.Text=p.DisplayName; o.nameLbl.Color=Color3.fromRGB(255,255,255)
			o.nameLbl.Position=Vector2.new(rootSP.X,top-28); o.nameLbl.Visible=true
			o.tagLbl.Text=teammate and "[TEAM]" or "[ENEMY]"; o.tagLbl.Color=mainCol
			o.tagLbl.Position=Vector2.new(rootSP.X,top-16); o.tagLbl.Visible=true
		else
			o.nameLbl.Visible=false; o.tagLbl.Visible=false
		end

		-- Distance
		if C.ESPDistance then
			o.distLbl.Text=math.floor(dist).."m"
			o.distLbl.Position=Vector2.new(rootSP.X,top+height+3)
			o.distLbl.Visible=true
		else
			o.distLbl.Visible=false
		end

		-- Tracer
		if C.ESPTracer then
			o.tracer.From=Vector2.new(center.X,vp.Y); o.tracer.To=rootSP
			o.tracer.Color=mainCol; o.tracer.Visible=true
		else
			o.tracer.Visible=false
		end

		-- Head dot
		if C.ESPHeadDot then
			local hsp,_ = toScreen(headPart.Position)
			o.headDot.Position=hsp;  o.headDot.Color=Color3.fromRGB(255,255,255); o.headDot.Visible=true
			o.headFill.Position=hsp; o.headFill.Color=mainCol;                    o.headFill.Visible=true
		else
			o.headDot.Visible=false; o.headFill.Visible=false
		end

		-- Skeleton
		if C.ESPSkeleton then
			for idx, pair in ipairs(SKEL) do
				local b1=char:FindFirstChild(pair[1]); local b2=char:FindFirstChild(pair[2])
				local ln=o.skel[idx]
				if b1 and b2 then
					ln.From=toScreen(b1.Position); ln.To=toScreen(b2.Position)
					ln.Color=mainCol; ln.Visible=true
				else
					ln.Visible=false
				end
			end
		else
			for _, l in ipairs(o.skel) do l.Visible=false end
		end
	end
end)

-- ══════════════════════════════════════════
-- RAYFIELD UI
-- ══════════════════════════════════════════
local Window = Rayfield:CreateWindow({
	Name            = "Astra Hub",
	Icon            = 0,
	LoadingTitle    = "Astra Hub",
	LoadingSubtitle = IS_MOBILE and "v1.0 | Mobile" or "v1.0 | PC",
	Theme           = "Default",
	ConfigurationSaving = {Enabled=true, FileName="AstraHub_v1"},
	KeySystem       = false,
})

-- ═══ AIMBOT TAB ══════════════════════════
local AimTab = Window:CreateTab("Aimbot", 4483362458)

AimTab:CreateSection("Aimbot")
AimTab:CreateToggle({Name="Enable Aimbot", CurrentValue=false, Flag="AimbotOn",
	Callback=function(v)
		C.Aimbot=v
		if not v then
			C._aiming=false
			if CurrentTween then CurrentTween:Cancel(); CurrentTween=nil end
		end
		if v then C.SilentAim=false; C.MagicBullet=false end
	end})

if IsComputer then
	AimTab:CreateToggle({Name="One-Press Mode (toggle instead of hold)", CurrentValue=false, Flag="OnePressMode",
		Callback=function(v) C.OnePressMode=v; C._aiming=false end})
end

AimTab:CreateToggle({Name="Velocity Prediction", CurrentValue=true, Flag="AimPred",
	Callback=function(v) C.Prediction=v end})
AimTab:CreateToggle({Name="Enemies Only (Team Check)", CurrentValue=true, Flag="AimTeam",
	Callback=function(v) C.TeamCheck=v end})
AimTab:CreateToggle({Name="Show FOV Circle", CurrentValue=true, Flag="ShowFoV",
	Callback=function(v) C.ShowFoV=v end})
AimTab:CreateToggle({Name="Use Sensitivity (smooth)", CurrentValue=true, Flag="UseSens",
	Callback=function(v) C.UseSensitivity=v end})
AimTab:CreateToggle({Name="Camera Noise (humanise)", CurrentValue=false, Flag="UseNoise",
	Callback=function(v) C.UseNoise=v end})

AimTab:CreateSlider({Name="FOV Radius", Range={10,500}, Increment=1, CurrentValue=120, Flag="FoVRadius",
	Callback=function(v) C.FoVRadius=v end})
AimTab:CreateSlider({Name="Smoothness (lower = faster)", Range={1,99}, Increment=1, CurrentValue=12, Flag="AimSmooth",
	Callback=function(v) C.Sensitivity=v end})
AimTab:CreateSlider({Name="Prediction Strength", Range={1,20}, Increment=1, CurrentValue=6, Flag="AimPredStr",
	Callback=function(v) C.PredStrength=v/100 end})
AimTab:CreateSlider({Name="Noise Frequency", Range={1,100}, Increment=1, CurrentValue=30, Flag="NoiseFreq",
	Callback=function(v) C.NoiseFrequency=v end})

AimTab:CreateDropdown({Name="Aim Part", Options={"Head","HumanoidRootPart","UpperTorso","LowerTorso"},
	CurrentOption={"Head"}, Flag="AimPart",
	Callback=function(v) C.AimPart=v[1] end})

AimTab:CreateParagraph({
	Title   = IS_MOBILE and "📱 Mobile" or "💻 PC",
	Content = IS_MOBILE
		and "Press the 🎯 button that appears on screen."
		or  "Hold RMB (or set One-Press Mode to toggle).",
})

AimTab:CreateSection("Silent Aim")
AimTab:CreateToggle({Name="Enable Silent Aim", CurrentValue=false, Flag="SilentOn",
	Callback=function(v)
		C.SilentAim=v
		if v then C.Aimbot=false; C.MagicBullet=false end
	end})
AimTab:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="SilentTeam",
	Callback=function(v) C.SilentTeamCheck=v end})
AimTab:CreateSlider({Name="Silent Aim FOV", Range={10,600}, Increment=1, CurrentValue=150, Flag="SilentFoV",
	Callback=function(v) C.SilentFoV=v end})
AimTab:CreateDropdown({Name="Silent Bone", Options={"Head","HumanoidRootPart","UpperTorso"},
	CurrentOption={"Head"}, Flag="SilentBone",
	Callback=function(v) C.SilentPart=v[1] end})

AimTab:CreateSection("Magic Bullet")
AimTab:CreateToggle({Name="Enable Magic Bullet", CurrentValue=false, Flag="MagicOn",
	Callback=function(v)
		C.MagicBullet=v
		if v then C.Aimbot=false; C.SilentAim=false end
	end})
AimTab:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="MagicTeam",
	Callback=function(v) C.MagicTeamCheck=v end})
AimTab:CreateSlider({Name="Magic Bullet FOV", Range={10,800}, Increment=1, CurrentValue=200, Flag="MagicFoV",
	Callback=function(v) C.MagicFoV=v end})
AimTab:CreateDropdown({Name="Magic Bone", Options={"HumanoidRootPart","Head","UpperTorso"},
	CurrentOption={"HumanoidRootPart"}, Flag="MagicBone",
	Callback=function(v) C.MagicPart=v[1] end})

-- ═══ ESP TAB ═════════════════════════════
local ESPTab = Window:CreateTab("ESP", 4483362458)

ESPTab:CreateSection("Targets")
ESPTab:CreateToggle({Name="Enable ESP", CurrentValue=false, Flag="ESPOn",
	Callback=function(v) C.ESPEnabled=v end})
ESPTab:CreateToggle({Name="Show Enemies", CurrentValue=true, Flag="ESPEnemies",
	Callback=function(v) C.ESPEnemies=v end})
ESPTab:CreateToggle({Name="Show Teammates", CurrentValue=false, Flag="ESPTeammates",
	Callback=function(v) C.ESPTeammates=v end})
ESPTab:CreateSlider({Name="Max Distance (studs)", Range={100,2000}, Increment=50, CurrentValue=1000, Flag="ESPMaxDist",
	Callback=function(v) C.ESPMaxDist=v end})
ESPTab:CreateSlider({Name="Box Thickness", Range={1,5}, Increment=0.5, CurrentValue=1.5, Flag="ESPThick",
	Callback=function(v) C.ESPThickness=v end})

ESPTab:CreateSection("Elements")
ESPTab:CreateToggle({Name="Box + Corners", CurrentValue=true, Flag="ESPBox",
	Callback=function(v) C.ESPBox=v end})
ESPTab:CreateToggle({Name="Filled Box", CurrentValue=false, Flag="ESPBoxFill",
	Callback=function(v) C.ESPBoxFilled=v end})
ESPTab:CreateToggle({Name="Name + Tag", CurrentValue=true, Flag="ESPName",
	Callback=function(v) C.ESPName=v end})
ESPTab:CreateToggle({Name="Health Bar", CurrentValue=true, Flag="ESPHealth",
	Callback=function(v) C.ESPHealth=v end})
ESPTab:CreateToggle({Name="Distance", CurrentValue=true, Flag="ESPDist",
	Callback=function(v) C.ESPDistance=v end})
ESPTab:CreateToggle({Name="Tracers", CurrentValue=false, Flag="ESPTracer",
	Callback=function(v) C.ESPTracer=v end})
ESPTab:CreateToggle({Name="Skeleton", CurrentValue=false, Flag="ESPSkel",
	Callback=function(v) C.ESPSkeleton=v end})
ESPTab:CreateToggle({Name="Head Dot", CurrentValue=true, Flag="ESPHeadDot",
	Callback=function(v) C.ESPHeadDot=v end})

-- ═══ COMBAT TAB ══════════════════════════
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("HitBox Expander")
CombatTab:CreateParagraph({Title="How it works", Content="Expands only the selected bone. Restores original size when disabled."})
CombatTab:CreateToggle({Name="HitBox Expander", CurrentValue=false, Flag="HitBoxOn",
	Callback=function(v)
		C.HitBox=v
		if not v then restoreHitBox() end
	end})
CombatTab:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="HitBoxTeam",
	Callback=function(v) C.HitBoxTeam=v end})
CombatTab:CreateSlider({Name="HitBox Size", Range={1,30}, Increment=0.5, CurrentValue=5, Flag="HitBoxSize",
	Callback=function(v) C.HitBoxSize=v end})
CombatTab:CreateDropdown({Name="HitBox Bone", Options={"Head","HumanoidRootPart","UpperTorso"},
	CurrentOption={"Head"}, Flag="HitBoxBone",
	Callback=function(v) C.HitBoxPart=v[1]; restoreHitBox() end})

CombatTab:CreateSection("Ammo & Accuracy")
CombatTab:CreateToggle({Name="Infinite Ammo", CurrentValue=false, Flag="InfAmmo",
	Callback=function(v) C.InfAmmo=v end})
CombatTab:CreateToggle({Name="No Spread / No Recoil", CurrentValue=false, Flag="NoSpread",
	Callback=function(v) C.NoSpread=v end})

-- ═══ CHAMS TAB ═══════════════════════════
local ChamsTab = Window:CreateTab("Chams", 4483362458)

ChamsTab:CreateSection("Chams")
ChamsTab:CreateToggle({Name="Enable Chams", CurrentValue=false, Flag="ChamsOn",
	Callback=function(v) C.Chams=v; refreshChams() end})
ChamsTab:CreateSlider({Name="Transparency", Range={0,90}, Increment=5, CurrentValue=40, Flag="ChamsTransp",
	Callback=function(v) C.ChamsTransp=v/100; if C.Chams then refreshChams() end end})

local enemyCols = {Red={255,50,50},Orange={255,140,0},Yellow={255,220,0},Pink={255,80,200},White={240,240,240}}
ChamsTab:CreateSection("Enemy Color")
for name, rgb in pairs(enemyCols) do
	ChamsTab:CreateButton({Name="Enemy: "..name, Callback=function()
		C.ChamsEnemyCol=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
		if C.Chams then refreshChams() end
	end})
end

local teamCols = {Blue={50,100,255},Cyan={0,200,255},Green={50,220,100},Purple={160,50,255}}
ChamsTab:CreateSection("Team Color")
for name, rgb in pairs(teamCols) do
	ChamsTab:CreateButton({Name="Team: "..name, Callback=function()
		C.ChamsTeamCol=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
		if C.Chams then refreshChams() end
	end})
end
ChamsTab:CreateButton({Name="Refresh Chams", Callback=function()
	refreshChams()
	Rayfield:Notify({Title="Astra Hub",Content="Chams refreshed",Duration=2})
end})

-- ═══ SETTINGS TAB ════════════════════════
local SetTab = Window:CreateTab("Settings", 4483362458)

SetTab:CreateSection("Status")
SetTab:CreateParagraph({
	Title   = IS_MOBILE and "📱 Mobile Mode" or "💻 PC Mode",
	Content = IS_MOBILE
		and "Aimbot: press on-screen 🎯 button."
		or  "Aimbot: hold RMB (or One-Press to toggle).",
})
SetTab:CreateParagraph({
	Title   = "Hook Status",
	Content = HookOk
		and "✅ Silent Aim / Magic Bullet hook: ACTIVE"
		or  "❌ Hook failed — try a different executor",
})

SetTab:CreateSection("Actions")
SetTab:CreateButton({Name="Disable ALL Features", Callback=function()
	C.Aimbot=false; C.SilentAim=false; C.MagicBullet=false
	C.ESPEnabled=false; C.HitBox=false; C.Chams=false
	C.InfAmmo=false; C.NoSpread=false; C._aiming=false; C._mobileAim=false
	restoreHitBox(); refreshChams()
	if CurrentTween then CurrentTween:Cancel(); CurrentTween=nil end
	Rayfield:Notify({Title="Astra Hub",Content="All features disabled",Duration=3})
end})

SetTab:CreateButton({Name="Destroy Script", Callback=function()
	pcall(function() fovCircle:Remove() end)
	pcall(function() silentCircle:Remove() end)
	pcall(function() magicCircle:Remove() end)
	for _, p in ipairs(Players:GetPlayers()) do clearESP(p); clearChams(p) end
	restoreHitBox()
	if mobileGui then pcall(function() mobileGui:Destroy() end) end
	if CurrentTween then CurrentTween:Cancel() end
	pcall(function() Rayfield:Destroy() end)
end})

-- ─── Loaded notification ──────────────────────────────────────────
Rayfield:Notify({
	Title   = "Astra Hub v1.0",
	Content = IS_MOBILE
		and "Loaded! Tap 🎯 button to aim."
		or  "Loaded! Hold RMB to aim.",
	Duration = 5,
})
