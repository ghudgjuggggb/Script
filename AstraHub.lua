local ok_rayfield, Rayfield = pcall(function()
	return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok_rayfield then warn("[AstraHub] Rayfield failed") return end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer
local Mouse            = LP:GetMouse()

local IS_MOBILE  = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local IS_DESKTOP = UserInputService.KeyboardEnabled and UserInputService.MouseEnabled

-- ──────────────────────────────────────────────
-- Configuration
-- ──────────────────────────────────────────────
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
	FoVRadius       = 150,
	UseSensitivity  = true,
	Sensitivity     = 15,
	UseOffset       = false,
	StaticOffset    = 0,
	DynamicOffset   = 0,
	UseNoise        = false,
	NoiseFreq       = 20,
	ShowFoV         = true,
	AimbotActive    = false,

	-- Silent Aim specific
	SilentMethods   = {
		MouseHit     = true,
		MouseTarget  = true,
		GetMouseLocation = true,
		Raycast      = true,
		FindPartOnRay = true,
	},

	-- ESP
	ESP             = false,
	ESPEnemies      = true,
	ESPTeammates    = true,
	ESPBoxes        = true,
	ESPNames        = true,
	ESPHealth       = true,
	ESPDistance     = true,
	ESPTracers      = false,
	ESPSkeleton     = false,
	ESPHeadDot      = true,
	ESPMaxDist      = 1000,
	ESPEnemyColor   = Color3.fromRGB(255, 60, 60),
	ESPTeamColor    = Color3.fromRGB(60, 180, 255),

	-- HitBox
	HitBoxEnabled   = false,
	HitBoxSize      = 5,
	HitBoxTeamCheck = true,

	-- Chams
	ChamsEnabled    = false,
	ChamsEnemyColor = Color3.fromRGB(255, 50, 50),
	ChamsTeamColor  = Color3.fromRGB(50, 120, 255),
	ChamsTransp     = 0.4,

	-- Combat
	InfAmmo         = false,
	NoSpread        = false,

	-- SpinBot
	SpinBot          = false,
	SpinVelocity     = 50,
	SpinPart         = "HumanoidRootPart",
	OnePressSpinMode = false,
	Spinning         = false,

	-- TriggerBot
	TriggerBot        = false,
	TriggerChance     = 100,
	TriggerDelay      = 0.05,
	SmartTrigger      = true,
	OnePressTriggMode = false,
	Triggering        = false,

	-- Camera FOV
	CustomFOV   = false,
	FOVValue    = 70,

	-- Anti-AFK
	AntiAFK = false,
}

-- ──────────────────────────────────────────────
-- State
-- ──────────────────────────────────────────────
local Aiming         = false
local Target         = nil
local CurrentTween   = nil
local MouseSens      = UserInputService.MouseDeltaSensitivity
local RobloxActive   = true
local Clock          = os.clock()

-- Anti-AFK
local VirtualUser = game:GetService("VirtualUser")
LP.Idled:Connect(function()
	if C.AntiAFK then
		VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
		task.wait(0.1)
		VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
	end
end)

-- ──────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────
local function isTeammate(p)
	if p == LP then return true end
	local t = LP.Team
	return t and p.Team and p.Team == t
end

local function getPart(char, name)
	if not char then return nil end
	return char:FindFirstChild(name) or char:FindFirstChild("HumanoidRootPart")
end

local function getScreenPos(world)
	local v, on = Camera:WorldToViewportPoint(world)
	return Vector2.new(v.X, v.Y), on
end

local function calcDir(origin, target, mag)
	return (target - origin).Unit * mag
end

local function calcNoise(freq)
	local f = freq / 100
	return Vector3.new(
		math.random() * f * 2 - f,
		math.random() * f * 2 - f,
		math.random() * f * 2 - f
	)
end

-- ──────────────────────────────────────────────
-- IsReady — core target validator (from reference)
-- ──────────────────────────────────────────────
local function IsReady(char)
	if not char then return false end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	local aimPart = char:FindFirstChild(C.AimPart)
	local myChar = LP.Character
	local myPart = myChar and myChar:FindFirstChild(C.AimPart)

	if not hum or not aimPart or not aimPart:IsA("BasePart") or not myPart then
		return false
	end

	local p = Players:GetPlayerFromCharacter(char)
	if not p or p == LP then return false end

	if C.AliveCheck and hum.Health <= 0 then return false end
	if C.TeamCheck and isTeammate(p) then return false end

	if C.WallCheck then
		local dir = calcDir(myPart.Position, aimPart.Position, (aimPart.Position - myPart.Position).Magnitude)
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = { myChar }
		rp.IgnoreWater = true
		local result = workspace:Raycast(myPart.Position, dir, rp)
		if not result or not result.Instance or not result.Instance:FindFirstAncestor(p.Name) then
			return false
		end
	end

	-- Offset calculation
	local offset = Vector3.zero
	if C.UseOffset then
		local staticOff  = Vector3.new(0, C.StaticOffset / 10, 0)
		local dynamicOff = hum.MoveDirection * (C.DynamicOffset / 10)
		offset = staticOff + dynamicOff
	end

	-- Noise
	local noise = C.UseNoise and calcNoise(C.NoiseFreq) or Vector3.zero

	local finalPos = aimPart.Position + offset + noise
	local sp, onScreen = getScreenPos(finalPos)
	local dist = (finalPos - myPart.Position).Magnitude
	local hitCF = CFrame.new(finalPos) * CFrame.fromEulerAnglesYXZ(
		math.rad(aimPart.Orientation.X),
		math.rad(aimPart.Orientation.Y),
		math.rad(aimPart.Orientation.Z)
	)

	return true, char, {sp, onScreen}, finalPos, dist, hitCF, aimPart
end

-- ──────────────────────────────────────────────
-- Target selection
-- ──────────────────────────────────────────────
local function findClosest()
	local mousePos = Vector2.new(Mouse.X, Mouse.Y)
	local closest, closestDist = nil, C.FoVCheck and C.FoVRadius or math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then
			local char = p.Character
			local ok, _, spData = IsReady(char)
			if ok and spData and spData[2] then
				local d = (mousePos - spData[1]).Magnitude
				if d < closestDist then
					closestDist = d
					closest = char
				end
			end
		end
	end
	return closest
end

-- ──────────────────────────────────────────────
-- Reset aimbot state
-- ──────────────────────────────────────────────
local function resetAim(keepAiming, keepTarget)
	Aiming = keepAiming and Aiming or false
	Target = keepTarget and Target or nil
	if CurrentTween then CurrentTween:Cancel(); CurrentTween = nil end
	UserInputService.MouseDeltaSensitivity = MouseSens
end

-- ──────────────────────────────────────────────
-- Silent Aim — __index hook (Mouse.Hit / Mouse.Target / X / Y)
-- ──────────────────────────────────────────────
local silentHookOk = pcall(function()
	if not getfenv().hookmetamethod then return end
	local oldIndex = getfenv().hookmetamethod(game, "__index", getfenv().newcclosure(function(self, key)
		if C.Aimbot and C.AimMode == "Silent" and Aiming and self == Mouse then
			local ok, _, spData, worldPos, _, hitCF, aimPart = IsReady(Target)
			if ok and spData and spData[2] then
				if (key == "Hit" or key == "hit") and C.SilentMethods.MouseHit then
					return hitCF
				elseif (key == "Target" or key == "target") and C.SilentMethods.MouseTarget then
					return aimPart
				elseif (key == "X" or key == "x") and C.SilentMethods.MouseHit then
					return spData[1].X
				elseif (key == "Y" or key == "y") and C.SilentMethods.MouseHit then
					return spData[1].Y
				elseif key == "UnitRay" or key == "unitRay" then
					return Ray.new(Camera.CFrame.Position, (worldPos - Camera.CFrame.Position).Unit)
				end
			end
		end
		return oldIndex(self, key)
	end))
end)

-- ──────────────────────────────────────────────
-- Silent Aim — __namecall hook (Raycast / FindPartOnRay / GetMouseLocation)
-- ──────────────────────────────────────────────
local namecallHookOk = pcall(function()
	if not getfenv().hookmetamethod then return end
	local oldCall = getfenv().hookmetamethod(game, "__namecall", getfenv().newcclosure(function(...)
		local method = getfenv().getnamecallmethod()
		local args   = { ... }
		local self   = args[1]

		if C.Aimbot and C.AimMode == "Silent" and Aiming then
			local ok, _, spData, worldPos, dist = IsReady(Target)
			if ok and spData and spData[2] then

				if C.SilentMethods.GetMouseLocation and self == UserInputService
					and (method == "GetMouseLocation" or method == "getMouseLocation") then
					return Vector2.new(spData[1].X, spData[1].Y)
				end

				local myChar = LP.Character
				local myPart = myChar and myChar:FindFirstChild(C.AimPart)

				if C.SilentMethods.Raycast and self == workspace
					and (method == "Raycast" or method == "raycast")
					and typeof(args[2]) == "Vector3" and typeof(args[3]) == "Vector3" then
					args[3] = calcDir(args[2], worldPos, dist)
					return oldCall(table.unpack(args))
				end

				if C.SilentMethods.FindPartOnRay and self == workspace
					and (method == "FindPartOnRay" or method == "findPartOnRay")
					and typeof(args[2]) == "userdata" then
					args[2] = Ray.new(args[2].Origin, calcDir(args[2].Origin, worldPos, dist))
					return oldCall(table.unpack(args))
				end

				if C.SilentMethods.FindPartOnRay and self == workspace
					and (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist")
					and typeof(args[2]) == "userdata" then
					args[2] = Ray.new(args[2].Origin, calcDir(args[2].Origin, worldPos, dist))
					return oldCall(table.unpack(args))
				end
			end
		end
		return oldCall(...)
	end))
end)

-- ──────────────────────────────────────────────
-- Drawing helpers
-- ──────────────────────────────────────────────
local function newDraw(t, props)
	local d = Drawing.new(t)
	for k, v in pairs(props) do d[k] = v end
	return d
end

local fovCircle = newDraw("Circle", {
	Visible=false, Color=Color3.fromRGB(255,255,255),
	Thickness=1.5, Filled=false, NumSides=64
})

local SKEL_PAIRS = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
}

local ESPObjects   = {}
local ChamsObjects = {}

local function makeESP(p)
	local o = {}
	o.boxFill  = newDraw("Square",{Transparency=0.25,Filled=true,Visible=false,Thickness=0,Color=Color3.fromRGB(255,60,60)})
	o.box      = newDraw("Square",{Thickness=1.5,Filled=false,Visible=false,Color=Color3.fromRGB(255,60,60)})
	for _, cn in ipairs({"cTL","cTL2","cTR","cTR2","cBL","cBL2","cBR","cBR2"}) do
		o[cn] = newDraw("Line",{Thickness=2.5,Visible=false,Color=Color3.fromRGB(255,255,255)})
	end
	o.hpOutline = newDraw("Square",{Color=Color3.fromRGB(0,0,0),Filled=false,Visible=false,Thickness=1})
	o.hpBg      = newDraw("Square",{Color=Color3.fromRGB(15,15,15),Filled=true,Visible=false,Thickness=0})
	o.hpBar     = newDraw("Square",{Color=Color3.fromRGB(50,220,50),Filled=true,Visible=false,Thickness=0})
	o.hpText    = newDraw("Text",{Color=Color3.fromRGB(255,255,255),Size=10,Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true,Font=2})
	o.nameLbl   = newDraw("Text",{Color=Color3.fromRGB(255,255,255),Size=13,Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true,Font=2})
	o.tagLbl    = newDraw("Text",{Size=11,Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true,Font=2,Color=Color3.fromRGB(100,200,255)})
	o.distLbl   = newDraw("Text",{Color=Color3.fromRGB(180,180,180),Size=11,Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true,Font=2})
	o.tracer    = newDraw("Line",{Color=Color3.fromRGB(255,60,60),Thickness=1,Visible=false})
	o.headDot   = newDraw("Circle",{Color=Color3.fromRGB(255,255,255),Thickness=1.5,Filled=false,NumSides=32,Radius=4,Visible=false})
	o.headFill  = newDraw("Circle",{Transparency=0.5,Filled=true,NumSides=32,Radius=4,Visible=false,Color=Color3.fromRGB(255,60,60)})
	o.skel      = {}
	for _ = 1, #SKEL_PAIRS do
		table.insert(o.skel, newDraw("Line",{Color=Color3.fromRGB(255,255,255),Thickness=1,Visible=false}))
	end
	ESPObjects[p] = o
end

local function clearESP(p)
	local o = ESPObjects[p]; if not o then return end
	for k, v in pairs(o) do
		if k == "skel" then for _, l in ipairs(v) do pcall(function() l:Remove() end) end
		else pcall(function() v:Remove() end) end
	end
	ESPObjects[p] = nil
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

local function applyChams(p)
	local char = p.Character; if not char then return end
	ChamsObjects[p] = {}
	local color = isTeammate(p) and C.ChamsTeamColor or C.ChamsEnemyColor
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			local orig = {Material=v.Material,Color=v.Color,Transparency=v.Transparency}
			table.insert(ChamsObjects[p], {part=v,original=orig})
			v.Material=Enum.Material.Neon; v.Color=color; v.Transparency=C.ChamsTransp
		end
	end
end

local function clearChams(p)
	local list = ChamsObjects[p]; if not list then return end
	for _, info in ipairs(list) do
		pcall(function()
			info.part.Material=info.original.Material
			info.part.Color=info.original.Color
			info.part.Transparency=info.original.Transparency
		end)
	end
	ChamsObjects[p] = nil
end

local function refreshChams()
	for _, p in ipairs(Players:GetPlayers()) do
		clearChams(p)
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if C.ChamsEnabled and p ~= LP and hum and hum.Health > 0 then applyChams(p) end
	end
end

-- Init ESP for existing players
for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LP then
		makeESP(p)
		p.CharacterAdded:Connect(function()
			task.wait(0.5)
			if C.ChamsEnabled then clearChams(p); applyChams(p) end
		end)
	end
end
Players.PlayerAdded:Connect(function(p)
	task.wait(0.1); makeESP(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		if C.ChamsEnabled then clearChams(p); applyChams(p) end
	end)
end)
Players.PlayerRemoving:Connect(function(p) clearESP(p); clearChams(p) end)

-- ──────────────────────────────────────────────
-- Mobile button
-- ──────────────────────────────────────────────
local mobileGui, mobileAimBtn

if IS_MOBILE then
	mobileGui = Instance.new("ScreenGui")
	mobileGui.Name="AstraHubMobile"; mobileGui.ResetOnSpawn=false
	mobileGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	mobileGui.Parent=LP.PlayerGui

	mobileAimBtn = Instance.new("ImageButton")
	mobileAimBtn.Size=UDim2.new(0,90,0,90)
	mobileAimBtn.Position=UDim2.new(1,-110,1,-200)
	mobileAimBtn.BackgroundColor3=Color3.fromRGB(200,40,40)
	mobileAimBtn.BackgroundTransparency=0.2
	mobileAimBtn.Visible=false; mobileAimBtn.Parent=mobileGui
	Instance.new("UICorner",mobileAimBtn).CornerRadius=UDim.new(1,0)
	local lbl=Instance.new("TextLabel")
	lbl.Text="🎯 AIM"; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=16
	lbl.TextColor3=Color3.fromRGB(255,255,255); lbl.BackgroundTransparency=1
	lbl.Size=UDim2.new(1,0,1,0); lbl.Parent=mobileAimBtn

	mobileAimBtn.MouseButton1Down:Connect(function() C.AimbotActive=true end)
	mobileAimBtn.MouseButton1Up:Connect(function()   C.AimbotActive=false end)
end

local function isAimPressed()
	if IS_MOBILE then return C.AimbotActive end
	return UserInputService:IsMouseButtonPressed(C.AimKey)
end

-- ──────────────────────────────────────────────
-- PC Input — hold/one-press, window focus
-- ──────────────────────────────────────────────
if IS_DESKTOP then
	UserInputService.InputBegan:Connect(function(input)
		if UserInputService:GetFocusedTextBox() then return end
		if C.Aimbot and (input.KeyCode == C.AimKey or input.UserInputType == C.AimKey) then
			if C.OnePressMode then
				if Aiming then resetAim() else Aiming = true end
			else
				Aiming = true
			end
		end
		if C.SpinBot and input.KeyCode == Enum.KeyCode.Q then
			if C.OnePressSpinMode then
				C.Spinning = not C.Spinning
			else
				C.Spinning = true
			end
		end
		if C.TriggerBot and input.KeyCode == Enum.KeyCode.E then
			if C.OnePressTriggMode then
				C.Triggering = not C.Triggering
			else
				C.Triggering = true
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if not C.OnePressMode and Aiming and (input.KeyCode == C.AimKey or input.UserInputType == C.AimKey) then
			resetAim()
		end
		if not C.OnePressSpinMode and input.KeyCode == Enum.KeyCode.Q then
			C.Spinning = false
		end
		if not C.OnePressTriggMode and input.KeyCode == Enum.KeyCode.E then
			C.Triggering = false
		end
	end)
	UserInputService.WindowFocused:Connect(function()  RobloxActive = true end)
	UserInputService.WindowFocusReleased:Connect(function()
		RobloxActive = false; resetAim()
		C.Spinning = false; C.Triggering = false
	end)

	UserInputService:GetPropertyChangedSignal("MouseDeltaSensitivity"):Connect(function()
		if not Aiming then MouseSens = UserInputService.MouseDeltaSensitivity end
	end)
end

-- ──────────────────────────────────────────────
-- Main loop
-- ──────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
	local vp = Camera.ViewportSize
	local center = Vector2.new(vp.X/2, vp.Y/2)

	fovCircle.Position = center
	fovCircle.Radius   = C.FoVRadius
	fovCircle.Visible  = C.ShowFoV and C.Aimbot

	if mobileAimBtn then mobileAimBtn.Visible = C.Aimbot end

	if not RobloxActive then goto afterAim end

	if C.Aimbot and C.AimMode == "Camera" then
		local activated = IS_MOBILE and C.AimbotActive or (IS_DESKTOP and Aiming)
		if activated then
			-- Refresh target if needed
			if not IsReady(Target) then
				Target = findClosest()
			end
			local ok, _, _, worldPos = IsReady(Target)
			if ok then
				if CurrentTween then CurrentTween:Cancel() end
				UserInputService.MouseDeltaSensitivity = 0
				if C.UseSensitivity then
					local tweenInfo = TweenInfo.new(
						math.clamp(C.Sensitivity, 1, 99) / 100,
						Enum.EasingStyle.Sine,
						Enum.EasingDirection.Out
					)
					CurrentTween = TweenService:Create(Camera, tweenInfo, {
						CFrame = CFrame.new(Camera.CFrame.Position, worldPos)
					})
					CurrentTween:Play()
				else
					Camera.CFrame = CFrame.new(Camera.CFrame.Position, worldPos)
				end
			else
				resetAim(true, false)
			end
		else
			if CurrentTween then CurrentTween:Cancel(); CurrentTween = nil end
			UserInputService.MouseDeltaSensitivity = MouseSens
		end
	end

	-- Silent mode: Aiming state is managed by hooks
	if C.Aimbot and C.AimMode == "Silent" then
		local activated = IS_MOBILE and C.AimbotActive or (IS_DESKTOP and Aiming)
		if activated then
			if not IsReady(Target) then Target = findClosest() end
		end
	end

	::afterAim::

	-- HitBox
	if C.HitBoxEnabled then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and (not C.HitBoxTeamCheck or not isTeammate(p)) then
				local char = p.Character
				if char then
					for _, v in ipairs(char:GetDescendants()) do
						if v:IsA("BasePart") then
							pcall(function() v.Size=Vector3.new(C.HitBoxSize,C.HitBoxSize,C.HitBoxSize) end)
						end
					end
				end
			end
		end
	end

	-- Infinite Ammo
	if C.InfAmmo then
		local char = LP.Character
		if char then
			for _, v in ipairs(char:GetDescendants()) do
				if (v:IsA("IntValue") or v:IsA("NumberValue")) then
					local n = v.Name:lower()
					if (n:find("ammo") or n:find("bullet") or n:find("mag") or n:find("clip")) and v.Value < 200 then
						pcall(function() v.Value=9999 end)
					end
				end
			end
		end
	end

	-- No Spread
	if C.NoSpread then
		local char = LP.Character
		if char then
			for _, tool in ipairs(char:GetChildren()) do
				if tool:IsA("Tool") then
					for _, v in ipairs(tool:GetDescendants()) do
						if v:IsA("NumberValue") or v:IsA("IntValue") then
							local n = v.Name:lower()
							if n:find("spread") or n:find("recoil") or n:find("scatter") or n:find("bloom") then
								pcall(function() v.Value=0 end)
							end
						end
					end
				end
			end
		end
	end

	-- ESP render
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LP then continue end
		local o = ESPObjects[p]; if not o then continue end

		local teammate = isTeammate(p)
		local showThis = C.ESP and ((teammate and C.ESPTeammates) or (not teammate and C.ESPEnemies))

		local char = p.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")

		if not showThis or not root or not hum or not char or hum.Health <= 0 then
			hideESP(o); continue
		end

		local dist = (Camera.CFrame.Position - root.Position).Magnitude
		if dist > C.ESPMaxDist then hideESP(o); continue end

		local rootSP, onScreen = getScreenPos(root.Position)
		if not onScreen then hideESP(o); continue end

		local headPart = char:FindFirstChild("Head")
		if not headPart then hideESP(o); continue end

		local mainColor = teammate and C.ESPTeamColor or C.ESPEnemyColor
		local hp        = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		local hpColor   = Color3.fromHSV(hp * 0.33, 1, 1)

		local topSP    = getScreenPos(headPart.Position + Vector3.new(0,0.7,0))
		local bottomSP = getScreenPos(root.Position - Vector3.new(0,2.8,0))
		local height   = math.abs(topSP.Y - bottomSP.Y)
		if height < 2 then hideESP(o); continue end
		local width = height * 0.55
		local left  = rootSP.X - width/2
		local top   = topSP.Y

		if C.ESPBoxes then
			o.boxFill.Position=Vector2.new(left,top); o.boxFill.Size=Vector2.new(width,height)
			o.boxFill.Color=mainColor; o.boxFill.Visible=true
			o.box.Position=Vector2.new(left,top); o.box.Size=Vector2.new(width,height)
			o.box.Color=mainColor; o.box.Visible=true
			drawCorners(o, left, top, width, height, Color3.fromRGB(255,255,255))
		else
			o.box.Visible=false; o.boxFill.Visible=false
			for _, cn in ipairs({"cTL","cTL2","cTR","cTR2","cBL","cBL2","cBR","cBR2"}) do o[cn].Visible=false end
		end

		if C.ESPHealth then
			local bw=4; local bh=height; local fill=bh*hp
			o.hpOutline.Position=Vector2.new(left-bw-4,top); o.hpOutline.Size=Vector2.new(bw,bh); o.hpOutline.Visible=true
			o.hpBg.Position=Vector2.new(left-bw-4,top); o.hpBg.Size=Vector2.new(bw,bh); o.hpBg.Visible=true
			o.hpBar.Position=Vector2.new(left-bw-4,top+bh-fill); o.hpBar.Size=Vector2.new(bw,fill); o.hpBar.Color=hpColor; o.hpBar.Visible=true
			o.hpText.Text=math.floor(hum.Health).."hp"; o.hpText.Position=Vector2.new(left-bw-4+bw/2,top+bh+2); o.hpText.Visible=true
		else
			o.hpOutline.Visible=false; o.hpBg.Visible=false; o.hpBar.Visible=false; o.hpText.Visible=false
		end

		if C.ESPNames then
			o.nameLbl.Text=p.DisplayName; o.nameLbl.Color=Color3.fromRGB(255,255,255); o.nameLbl.Position=Vector2.new(rootSP.X,top-28); o.nameLbl.Visible=true
			o.tagLbl.Text=teammate and "[TEAM]" or "[ENEMY]"; o.tagLbl.Color=mainColor; o.tagLbl.Position=Vector2.new(rootSP.X,top-16); o.tagLbl.Visible=true
		else o.nameLbl.Visible=false; o.tagLbl.Visible=false end

		if C.ESPDistance then
			o.distLbl.Text=math.floor(dist).."m"; o.distLbl.Position=Vector2.new(rootSP.X,top+height+3); o.distLbl.Visible=true
		else o.distLbl.Visible=false end

		if C.ESPTracers then
			o.tracer.From=Vector2.new(center.X,vp.Y); o.tracer.To=rootSP; o.tracer.Color=mainColor; o.tracer.Visible=true
		else o.tracer.Visible=false end

		if C.ESPHeadDot then
			local hsp=getScreenPos(headPart.Position)
			o.headDot.Position=hsp; o.headDot.Color=Color3.fromRGB(255,255,255); o.headDot.Visible=true
			o.headFill.Position=hsp; o.headFill.Color=mainColor; o.headFill.Visible=true
		else o.headDot.Visible=false; o.headFill.Visible=false end

		if C.ESPSkeleton then
			for idx, pair in ipairs(SKEL_PAIRS) do
				local b1=char:FindFirstChild(pair[1]); local b2=char:FindFirstChild(pair[2])
				local ln=o.skel[idx]
				if b1 and b2 then
					ln.From=getScreenPos(b1.Position); ln.To=getScreenPos(b2.Position); ln.Color=mainColor; ln.Visible=true
				else ln.Visible=false end
			end
		else for _,l in ipairs(o.skel) do l.Visible=false end end
	end
end)

-- ──────────────────────────────────────────────
-- UI
-- ──────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
	Name="Astra Hub", Icon=0,
	LoadingTitle="Astra Hub",
	LoadingSubtitle=IS_MOBILE and "📱 Mobile Mode" or "💻 PC Mode",
	Theme="Default",
	ConfigurationSaving={Enabled=true,FileName="AstraHub"},
	KeySystem=false,
})

local AimTab = Window:CreateTab("Aimbot", 4483362458)
AimTab:CreateSection("Aimbot")
AimTab:CreateToggle({Name="Enable Aimbot", CurrentValue=false, Flag="Aon",
	Callback=function(v) C.Aimbot=v; if not v then resetAim() end end})
AimTab:CreateDropdown({Name="Aim Mode", Options={"Camera","Silent"}, CurrentOption={"Camera"}, Flag="AimMode",
	Callback=function(v)
		C.AimMode=v[1]
		resetAim()
	end})
if IS_DESKTOP then
	AimTab:CreateToggle({Name="One-Press Mode (toggle instead of hold)", CurrentValue=false, Flag="OnePress",
		Callback=function(v) C.OnePressMode=v end})
end
AimTab:CreateToggle({Name="Enemies Only (Team Check)", CurrentValue=true, Flag="AimTeam",
	Callback=function(v) C.TeamCheck=v end})
AimTab:CreateToggle({Name="Alive Check", CurrentValue=true, Flag="AliveCheck",
	Callback=function(v) C.AliveCheck=v end})
AimTab:CreateToggle({Name="Wall Check", CurrentValue=false, Flag="WallCheck",
	Callback=function(v) C.WallCheck=v end})
AimTab:CreateToggle({Name="FOV Check", CurrentValue=true, Flag="FovCheck",
	Callback=function(v) C.FoVCheck=v end})
AimTab:CreateToggle({Name="Show FOV Circle", CurrentValue=true, Flag="ShowFov",
	Callback=function(v) C.ShowFoV=v end})
AimTab:CreateSlider({Name="FOV Radius", Range={10,500}, Increment=1, CurrentValue=150, Flag="FovR",
	Callback=function(v) C.FoVRadius=v end})
AimTab:CreateDropdown({Name="Target Bone", Options={"Head","HumanoidRootPart","UpperTorso","LowerTorso"}, CurrentOption={"Head"}, Flag="AimBone",
	Callback=function(v) C.AimPart=v[1] end})
AimTab:CreateSection("Camera Smoothness")
AimTab:CreateToggle({Name="Use Sensitivity (smooth)", CurrentValue=true, Flag="UseSens",
	Callback=function(v) C.UseSensitivity=v end})
AimTab:CreateSlider({Name="Sensitivity (lower = snappier)", Range={1,99}, Increment=1, CurrentValue=15, Flag="SensVal",
	Callback=function(v) C.Sensitivity=v end})
AimTab:CreateSection("Aim Offset")
AimTab:CreateToggle({Name="Use Offset", CurrentValue=false, Flag="UseOff",
	Callback=function(v) C.UseOffset=v end})
AimTab:CreateSlider({Name="Static Offset (Y)", Range={0,50}, Increment=1, CurrentValue=0, Flag="StatOff",
	Callback=function(v) C.StaticOffset=v end})
AimTab:CreateSlider({Name="Dynamic Offset (movement)", Range={0,50}, Increment=1, CurrentValue=0, Flag="DynOff",
	Callback=function(v) C.DynamicOffset=v end})
AimTab:CreateSection("Humanization")
AimTab:CreateToggle({Name="Noise (human-like shake)", CurrentValue=false, Flag="UseNoise",
	Callback=function(v) C.UseNoise=v end})
AimTab:CreateSlider({Name="Noise Frequency", Range={1,100}, Increment=1, CurrentValue=20, Flag="NoiseFq",
	Callback=function(v) C.NoiseFreq=v end})
AimTab:CreateSection("Silent Aim Methods")
AimTab:CreateParagraph({Title="Silent Mode", Content="Silent Aim works in 'Silent' Aim Mode. Hooks Mouse.Hit, Raycast, GetMouseLocation, etc."})
AimTab:CreateToggle({Name="Mouse.Hit / Mouse.Target", CurrentValue=true, Flag="SilentMouseHit",
	Callback=function(v) C.SilentMethods.MouseHit=v; C.SilentMethods.MouseTarget=v end})
AimTab:CreateToggle({Name="GetMouseLocation", CurrentValue=true, Flag="SilentGML",
	Callback=function(v) C.SilentMethods.GetMouseLocation=v end})
AimTab:CreateToggle({Name="Raycast", CurrentValue=true, Flag="SilentRay",
	Callback=function(v) C.SilentMethods.Raycast=v end})
AimTab:CreateToggle({Name="FindPartOnRay", CurrentValue=true, Flag="SilentFPOR",
	Callback=function(v) C.SilentMethods.FindPartOnRay=v end})
if IS_MOBILE then
	AimTab:CreateParagraph({Title="📱 Mobile", Content="Hold the AIM button (bottom right) to lock on in Camera mode."})
else
	AimTab:CreateParagraph({Title="💻 PC", Content="Hold RMB (or configured key) to activate in Camera/Silent mode."})
end

local ESPTab = Window:CreateTab("ESP", 4483362458)
ESPTab:CreateSection("Targets")
ESPTab:CreateToggle({Name="Enable ESP",CurrentValue=false,Flag="ESPOn",Callback=function(v)C.ESP=v end})
ESPTab:CreateToggle({Name="Show Enemies",CurrentValue=true,Flag="ESPEnemy",Callback=function(v)C.ESPEnemies=v end})
ESPTab:CreateToggle({Name="Show Teammates",CurrentValue=true,Flag="ESPTeam",Callback=function(v)C.ESPTeammates=v end})
ESPTab:CreateSection("Elements")
ESPTab:CreateToggle({Name="Boxes + Corners",CurrentValue=true,Flag="ESPBox",Callback=function(v)C.ESPBoxes=v end})
ESPTab:CreateToggle({Name="Names + Tag",CurrentValue=true,Flag="ESPName",Callback=function(v)C.ESPNames=v end})
ESPTab:CreateToggle({Name="Health Bar",CurrentValue=true,Flag="ESPHp",Callback=function(v)C.ESPHealth=v end})
ESPTab:CreateToggle({Name="Distance",CurrentValue=true,Flag="ESPDist",Callback=function(v)C.ESPDistance=v end})
ESPTab:CreateToggle({Name="Tracers",CurrentValue=false,Flag="ESPTrace",Callback=function(v)C.ESPTracers=v end})
ESPTab:CreateToggle({Name="Skeleton",CurrentValue=false,Flag="ESPSkel",Callback=function(v)C.ESPSkeleton=v end})
ESPTab:CreateToggle({Name="Head Dot",CurrentValue=true,Flag="ESPHead",Callback=function(v)C.ESPHeadDot=v end})
ESPTab:CreateSlider({Name="Max Distance",Range={100,2000},Increment=50,CurrentValue=1000,Flag="ESPMax",
	Callback=function(v)C.ESPMaxDist=v end})

local CombatTab = Window:CreateTab("Combat", 4483362458)
CombatTab:CreateSection("HitBox")
CombatTab:CreateToggle({Name="HitBox Expander",CurrentValue=false,Flag="HitOn",Callback=function(v)C.HitBoxEnabled=v end})
CombatTab:CreateToggle({Name="Enemies Only",CurrentValue=true,Flag="HitTeam",Callback=function(v)C.HitBoxTeamCheck=v end})
CombatTab:CreateSlider({Name="HitBox Size",Range={1,20},Increment=0.5,CurrentValue=5,Flag="HitSz",
	Callback=function(v)C.HitBoxSize=v end})
CombatTab:CreateSection("Ammo & Accuracy")
CombatTab:CreateToggle({Name="Infinite Ammo",CurrentValue=false,Flag="InfAmmoOn",Callback=function(v)C.InfAmmo=v end})
CombatTab:CreateToggle({Name="No Spread / No Recoil",CurrentValue=false,Flag="NoSpreadOn",Callback=function(v)C.NoSpread=v end})

local ChamsTab = Window:CreateTab("Chams", 4483362458)
ChamsTab:CreateSection("Chams")
ChamsTab:CreateToggle({Name="Enable Chams",CurrentValue=false,Flag="ChamsOn",
	Callback=function(v)C.ChamsEnabled=v;refreshChams()end})
ChamsTab:CreateSlider({Name="Transparency",Range={0,90},Increment=5,CurrentValue=40,Flag="ChamsT",
	Callback=function(v)C.ChamsTransp=v/100;if C.ChamsEnabled then refreshChams()end end})
ChamsTab:CreateSection("Enemy Color")
for name, rgb in pairs({Red={255,50,50},Orange={255,140,0},Yellow={255,220,0},Pink={255,80,200},White={240,240,240}}) do
	ChamsTab:CreateButton({Name="Enemy: "..name,Callback=function()
		C.ChamsEnemyColor=Color3.fromRGB(rgb[1],rgb[2],rgb[3]);if C.ChamsEnabled then refreshChams()end
	end})
end
ChamsTab:CreateSection("Teammate Color")
for name, rgb in pairs({Blue={50,100,255},Cyan={0,200,255},Green={50,220,100},Purple={160,50,255}}) do
	ChamsTab:CreateButton({Name="Team: "..name,Callback=function()
		C.ChamsTeamColor=Color3.fromRGB(rgb[1],rgb[2],rgb[3]);if C.ChamsEnabled then refreshChams()end
	end})
end
ChamsTab:CreateButton({Name="Refresh Chams",Callback=function()
	if C.ChamsEnabled then refreshChams()end
	Rayfield:Notify({Title="Astra Hub",Content="Chams refreshed",Duration=2})
end})

local SetTab = Window:CreateTab("Settings", 4483362458)
SetTab:CreateSection("Hook Status")
SetTab:CreateParagraph({
	Title="Silent Aim __index",
	Content=silentHookOk and "Mouse.Hit / Target hook: ACTIVE ✓" or "Not supported on this executor",
})
SetTab:CreateParagraph({
	Title="Silent Aim __namecall",
	Content=namecallHookOk and "Raycast / GetMouseLocation hook: ACTIVE ✓" or "Not supported on this executor",
})
SetTab:CreateSection("Actions")
SetTab:CreateButton({Name="Disable ALL",Callback=function()
	C.Aimbot=false; C.ESP=false; C.HitBoxEnabled=false
	C.ChamsEnabled=false; C.InfAmmo=false; C.NoSpread=false
	C.AimbotActive=false; resetAim(); refreshChams()
	Rayfield:Notify({Title="Astra Hub",Content="All disabled",Duration=3})
end})
SetTab:CreateButton({Name="Destroy Script",Callback=function()
	pcall(function()fovCircle:Remove()end)
	for _,p in ipairs(Players:GetPlayers())do clearESP(p);clearChams(p)end
	if mobileGui then pcall(function()mobileGui:Destroy()end)end
	resetAim()
	pcall(function()Rayfield:Destroy()end)
end})

Rayfield:Notify({
	Title="Astra Hub",
	Content=IS_MOBILE and "Loaded! Hold AIM button to lock on." or "Loaded! Hold RMB to aim.",
	Duration=5,
})
