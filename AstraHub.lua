-- Astra Hub
local ok, Rayfield = pcall(function()
	return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok then warn("[AstraHub] Rayfield load failed") return end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser      = game:GetService("VirtualUser")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer
local Mouse            = LP:GetMouse()

-- ═══════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════
local C = {
	-- Aimbot
	Aimbot        = false,
	AimMode       = "Camera",  -- "Camera" | "Silent"
	AimPart       = "Head",
	FoVRadius     = 150,
	FoVCheck      = true,
	ShowFoV       = true,
	TeamCheck     = true,
	AliveCheck    = true,
	WallCheck     = false,
	Smoothness    = 0.15,
	UseOffset     = false,
	OffsetY       = 0,
	UseNoise      = false,
	NoiseStr      = 0.05,
	OnePressAim   = false,

	-- Silent methods
	SilHit      = true,
	SilTarget   = true,
	SilMouseLoc = true,
	SilRaycast  = true,

	-- ESP
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
	ESPEnemyCol   = Color3.fromRGB(255, 60, 60),
	ESPTeamCol    = Color3.fromRGB(60, 180, 255),

	-- HitBox
	HitBox          = false,
	HitBoxSize      = 5,
	HitBoxEnemyOnly = true,

	-- Chams
	Chams          = false,
	ChamsEnemyCol  = Color3.fromRGB(255, 50, 50),
	ChamsTeamCol   = Color3.fromRGB(50, 120, 255),
	ChamsTransp    = 0.4,

	-- Combat
	InfAmmo   = false,
	NoSpread  = false,

	-- SpinBot
	SpinBot       = false,
	SpinSpeed     = 50,
	OnePressSpinB = false,

	-- TriggerBot
	TriggerBot    = false,
	TrigDelay     = 0.06,
	TrigChance    = 100,
	TrigTeamCheck = true,
	OnePressTrigg = false,

	-- Camera FOV
	CustomFOV  = false,
	FOVValue   = 70,
	OrigFOV    = Camera.FieldOfView,

	-- Anti-AFK
	AntiAFK = false,
}

-- ═══════════════════════════════════
-- STATE
-- ═══════════════════════════════════
local Aiming     = false
local Spinning   = false
local Triggering = false
local AimTarget  = nil

-- ═══════════════════════════════════
-- UTILS
-- ═══════════════════════════════════
local function isTeammate(p)
	if p == LP then return true end
	if not LP.Team then return false end
	return p.Team == LP.Team
end

local function getChar(p)
	return p.Character
end

local function getHum(p)
	local c = getChar(p)
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot(p)
	local c = getChar(p)
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getPart(p, name)
	local c = getChar(p)
	if not c then return nil end
	return c:FindFirstChild(name) or c:FindFirstChild("HumanoidRootPart")
end

local function toScreen(v3)
	local v, on = Camera:WorldToViewportPoint(v3)
	return Vector2.new(v.X, v.Y), on
end

local function isValidTarget(p)
	if p == LP then return false end
	if C.TeamCheck and isTeammate(p) then return false end
	local hum = getHum(p)
	if C.AliveCheck and (not hum or hum.Health <= 0) then return false end
	if not hum then return false end
	if C.WallCheck then
		local myRoot = getRoot(LP)
		local tRoot  = getRoot(p)
		if myRoot and tRoot then
			local rp = RaycastParams.new()
			rp.FilterType = Enum.RaycastFilterType.Exclude
			rp.FilterDescendantsInstances = { LP.Character }
			rp.IgnoreWater = true
			local dir = tRoot.Position - myRoot.Position
			local result = workspace:Raycast(myRoot.Position, dir, rp)
			if not result then return false end
			if not result.Instance:IsDescendantOf(getChar(p)) then return false end
		end
	end
	return true
end

local function getAimPos(p)
	local part = getPart(p, C.AimPart)
	if not part then return nil end
	local pos = part.Position
	if C.UseOffset then pos = pos + Vector3.new(0, C.OffsetY, 0) end
	if C.UseNoise  then
		local n = C.NoiseStr
		pos = pos + Vector3.new(
			math.random() * n * 2 - n,
			math.random() * n * 2 - n,
			math.random() * n * 2 - n
		)
	end
	return pos
end

local function findClosest()
	local center = Vector2.new(Mouse.X, Mouse.Y)
	local maxD   = C.FoVCheck and C.FoVRadius or math.huge
	local best, bestD = nil, maxD
	for _, p in ipairs(Players:GetPlayers()) do
		if isValidTarget(p) then
			local pos = getAimPos(p)
			if pos then
				local sp, on = toScreen(pos)
				if on then
					local d = (center - sp).Magnitude
					if d < bestD then bestD = d; best = p end
				end
			end
		end
	end
	return best
end

-- ═══════════════════════════════════
-- SILENT AIM — getrawmetatable hook
-- ═══════════════════════════════════
local hookActive = false
local function getSilentPos()
	if not AimTarget or not isValidTarget(AimTarget) then return nil, nil end
	local pos  = getAimPos(AimTarget)
	if not pos then return nil, nil end
	local sp, on = toScreen(pos)
	return pos, on and sp or nil
end

local hookOk = pcall(function()
	local mt = getrawmetatable(game)
	setreadonly(mt, false)
	local oldNamecall = mt.__namecall
	mt.__namecall = newcclosure(function(self, ...)
		local method = getnamecallmethod()
		-- only intercept when silent aim is active
		if C.Aimbot and C.AimMode == "Silent" and Aiming then
			local worldPos, sp = getSilentPos()
			if worldPos then
				local myRoot = getRoot(LP)
				if myRoot then
					-- UserInputService:GetMouseLocation()
					if C.SilMouseLoc and self == UserInputService
						and method == "GetMouseLocation" then
						return Vector2.new(sp.X, sp.Y)
					end
					-- workspace:Raycast(origin, dir, params)
					if C.SilRaycast and self == workspace and method == "Raycast" then
						local args = {...}
						if typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
							local newDir = (worldPos - args[1])
							return oldNamecall(workspace, args[1], newDir, args[3])
						end
					end
					-- FindPartOnRay variants
					if C.SilRaycast and self == workspace and method:find("FindPartOnRay") then
						local args = {...}
						if typeof(args[1]) == "userdata" then
							local newRay = Ray.new(args[1].Origin, (worldPos - args[1].Origin))
							return oldNamecall(workspace, newRay, table.unpack(args, 2))
						end
					end
				end
			end
		end
		return oldNamecall(self, ...)
	end)
	-- Mouse.Hit / Mouse.Target via __index hook
	local oldIndex = mt.__index
	mt.__index = newcclosure(function(self, key)
		if C.Aimbot and C.AimMode == "Silent" and Aiming and self == Mouse then
			local worldPos, sp = getSilentPos()
			if worldPos and sp then
				if C.SilHit and (key == "Hit" or key == "hit") then
					return CFrame.new(worldPos)
				end
				if C.SilTarget and (key == "Target" or key == "target") then
					local part = AimTarget and getPart(AimTarget, C.AimPart)
					return part
				end
				if C.SilHit and key == "X" then return sp.X end
				if C.SilHit and key == "Y" then return sp.Y end
			end
		end
		return oldIndex(self, key)
	end)
	setreadonly(mt, true)
	hookActive = true
end)

-- ═══════════════════════════════════
-- DRAWING HELPERS
-- ═══════════════════════════════════
local function nd(t, p)
	local d = Drawing.new(t)
	for k, v in pairs(p) do d[k] = v end
	return d
end

local fovDraw = nd("Circle", {
	Visible=false, Color=Color3.fromRGB(255,255,255),
	Thickness=1.5, Filled=false, NumSides=64,
})

local SKEL = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
}
local CKEYS = {"cTL","cTL2","cTR","cTR2","cBL","cBL2","cBR","cBR2"}

local ESPPool   = {}
local ChamsPool = {}

local function makeESP(p)
	local o = {}
	o.fill  = nd("Square",{Transparency=0.25,Filled=true,Visible=false,Thickness=0,Color=Color3.fromRGB(255,60,60)})
	o.box   = nd("Square",{Thickness=1.5,Filled=false,Visible=false,Color=Color3.fromRGB(255,60,60)})
	for _, n in ipairs(CKEYS) do
		o[n] = nd("Line",{Thickness=2.5,Visible=false,Color=Color3.fromRGB(255,255,255)})
	end
	o.hpOut = nd("Square",{Color=Color3.fromRGB(0,0,0),Filled=false,Visible=false,Thickness=1})
	o.hpBg  = nd("Square",{Color=Color3.fromRGB(15,15,15),Filled=true,Visible=false,Thickness=0})
	o.hpBar = nd("Square",{Color=Color3.fromRGB(50,220,50),Filled=true,Visible=false,Thickness=0})
	o.hpTxt = nd("Text",{Color=Color3.fromRGB(255,255,255),Size=10,Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true,Font=2})
	o.name  = nd("Text",{Color=Color3.fromRGB(255,255,255),Size=13,Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true,Font=2})
	o.tag   = nd("Text",{Color=Color3.fromRGB(100,200,255),Size=11,Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true,Font=2})
	o.dist  = nd("Text",{Color=Color3.fromRGB(180,180,180),Size=11,Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true,Font=2})
	o.trace = nd("Line",{Color=Color3.fromRGB(255,60,60),Thickness=1,Visible=false})
	o.hdot  = nd("Circle",{Color=Color3.fromRGB(255,255,255),Thickness=1.5,Filled=false,NumSides=32,Radius=4,Visible=false})
	o.hfill = nd("Circle",{Transparency=0.5,Filled=true,NumSides=32,Radius=4,Visible=false,Color=Color3.fromRGB(255,60,60)})
	o.skel  = {}
	for _ = 1, #SKEL do
		table.insert(o.skel, nd("Line",{Color=Color3.fromRGB(255,255,255),Thickness=1,Visible=false}))
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

local function corners(o, l, t, w, h, col)
	local cl = math.min(w,h)*0.22; local r,b = l+w, t+h
	local s = {
		{o.cTL, Vector2.new(l,t),Vector2.new(l+cl,t)}, {o.cTL2,Vector2.new(l,t),Vector2.new(l,t+cl)},
		{o.cTR, Vector2.new(r,t),Vector2.new(r-cl,t)}, {o.cTR2,Vector2.new(r,t),Vector2.new(r,t+cl)},
		{o.cBL, Vector2.new(l,b),Vector2.new(l+cl,b)}, {o.cBL2,Vector2.new(l,b),Vector2.new(l,b-cl)},
		{o.cBR, Vector2.new(r,b),Vector2.new(r-cl,b)}, {o.cBR2,Vector2.new(r,b),Vector2.new(r,b-cl)},
	}
	for _, c in ipairs(s) do c[1].From=c[2];c[1].To=c[3];c[1].Color=col;c[1].Visible=true end
end

local function applyChams(p)
	local char = getChar(p); if not char then return end
	ChamsPool[p] = {}
	local col = isTeammate(p) and C.ChamsTeamCol or C.ChamsEnemyCol
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			local orig = {M=v.Material,C=v.Color,T=v.Transparency}
			table.insert(ChamsPool[p], {part=v,orig=orig})
			v.Material=Enum.Material.Neon; v.Color=col; v.Transparency=C.ChamsTransp
		end
	end
end

local function clearChams(p)
	local list = ChamsPool[p]; if not list then return end
	for _, i in ipairs(list) do
		pcall(function() i.part.Material=i.orig.M; i.part.Color=i.orig.C; i.part.Transparency=i.orig.T end)
	end
	ChamsPool[p] = nil
end

local function refreshChams()
	for _, p in ipairs(Players:GetPlayers()) do
		clearChams(p)
		local hum = getHum(p)
		if C.Chams and p~=LP and hum and hum.Health>0 then applyChams(p) end
	end
end

-- player hooks
for _, p in ipairs(Players:GetPlayers()) do
	if p~=LP then
		makeESP(p)
		p.CharacterAdded:Connect(function() task.wait(0.5); if C.Chams then clearChams(p);applyChams(p) end end)
	end
end
Players.PlayerAdded:Connect(function(p)
	task.wait(0.1); makeESP(p)
	p.CharacterAdded:Connect(function() task.wait(0.5); if C.Chams then clearChams(p);applyChams(p) end end)
end)
Players.PlayerRemoving:Connect(function(p) clearESP(p); clearChams(p) end)

-- ═══════════════════════════════════
-- INPUT
-- ═══════════════════════════════════
UserInputService.InputBegan:Connect(function(inp, gp)
	if gp then return end
	local k = inp.KeyCode
	local t = inp.UserInputType

	if C.Aimbot and (t == Enum.UserInputType.MouseButton2 or k == Enum.KeyCode.Q) then
		if t == Enum.UserInputType.MouseButton2 then
			if C.OnePressAim then Aiming = not Aiming
			else Aiming = true end
		end
	end

	if C.SpinBot and k == Enum.KeyCode.Q then
		if C.OnePressSpinB then Spinning = not Spinning
		else Spinning = true end
	end

	if C.TriggerBot and k == Enum.KeyCode.E then
		if C.OnePressTrigg then Triggering = not Triggering
		else Triggering = true end
	end
end)

UserInputService.InputEnded:Connect(function(inp)
	local k = inp.KeyCode
	local t = inp.UserInputType

	if not C.OnePressAim and t == Enum.UserInputType.MouseButton2 then
		Aiming = false; AimTarget = nil
	end
	if not C.OnePressSpinB and k == Enum.KeyCode.Q then Spinning = false end
	if not C.OnePressTrigg and k == Enum.KeyCode.E then Triggering = false end
end)

UserInputService.WindowFocusReleased:Connect(function()
	Aiming = false; Spinning = false; Triggering = false; AimTarget = nil
end)

-- Anti-AFK
LP.Idled:Connect(function()
	if not C.AntiAFK then return end
	VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
	task.wait(0.1)
	VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
end)

-- ═══════════════════════════════════
-- BACKGROUND LOOPS (не в RenderStepped!)
-- ═══════════════════════════════════

-- HitBox loop
task.spawn(function()
	while task.wait(0.1) do
		if not C.HitBox then continue end
		for _, p in ipairs(Players:GetPlayers()) do
			if p~=LP and (not C.HitBoxEnemyOnly or not isTeammate(p)) then
				local char = getChar(p)
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
end)

-- Infinite Ammo loop
task.spawn(function()
	while task.wait(0.5) do
		if not C.InfAmmo then continue end
		local char = LP.Character
		if not char then continue end
		for _, v in ipairs(char:GetDescendants()) do
			if v:IsA("IntValue") or v:IsA("NumberValue") then
				local n = v.Name:lower()
				if (n:find("ammo") or n:find("bullet") or n:find("mag") or n:find("clip")) and v.Value < 200 then
					pcall(function() v.Value = 9999 end)
				end
			end
		end
	end
end)

-- No Spread loop
task.spawn(function()
	while task.wait(0.1) do
		if not C.NoSpread then continue end
		local char = LP.Character
		if not char then continue end
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") then
				for _, v in ipairs(tool:GetDescendants()) do
					if v:IsA("NumberValue") or v:IsA("IntValue") then
						local n = v.Name:lower()
						if n:find("spread") or n:find("recoil") or n:find("bloom") or n:find("scatter") then
							pcall(function() v.Value = 0 end)
						end
					end
				end
			end
		end
	end
end)

-- TriggerBot loop
task.spawn(function()
	while true do
		task.wait(C.TrigDelay)
		if not C.TriggerBot or not Triggering then continue end
		local hitTarget = Mouse.Target
		if not hitTarget then continue end
		local p = Players:GetPlayerFromCharacter(hitTarget.Parent)
		if not p or p == LP then continue end
		if C.TrigTeamCheck and isTeammate(p) then continue end
		local hum = getHum(p)
		if not hum or hum.Health <= 0 then continue end
		if math.random(1,100) > C.TrigChance then continue end
		pcall(mouse1click)
	end
end)

-- SpinBot in Heartbeat
RunService.Heartbeat:Connect(function()
	if not C.SpinBot or not Spinning then return end
	local char = LP.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(C.SpinSpeed), 0)
	end
end)

-- ═══════════════════════════════════
-- RENDER LOOP (visual only)
-- ═══════════════════════════════════
RunService.RenderStepped:Connect(function()
	local vp = Camera.ViewportSize
	local cx  = vp.X/2
	local cy  = vp.Y/2

	-- FOV circle
	fovDraw.Position = Vector2.new(cx, cy)
	fovDraw.Radius   = C.FoVRadius
	fovDraw.Visible  = C.ShowFoV and C.Aimbot

	-- Camera FOV
	Camera.FieldOfView = C.CustomFOV and C.FOVValue or C.OrigFOV

	-- Camera aimbot
	if C.Aimbot and C.AimMode == "Camera" then
		local pressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
		if not C.OnePressAim then Aiming = pressed end
		if Aiming then
			if not AimTarget or not isValidTarget(AimTarget) then
				AimTarget = findClosest()
			end
			if AimTarget then
				local pos = getAimPos(AimTarget)
				if pos then
					local _, on = toScreen(pos)
					if on then
						local goal = CFrame.new(Camera.CFrame.Position, pos)
						Camera.CFrame = Camera.CFrame:Lerp(goal, C.Smoothness)
					else
						AimTarget = nil
					end
				end
			end
		else
			AimTarget = nil
		end
	end

	-- Silent aimbot target tracking
	if C.Aimbot and C.AimMode == "Silent" then
		local pressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
		if not C.OnePressAim then Aiming = pressed end
		if Aiming then
			if not AimTarget or not isValidTarget(AimTarget) then
				AimTarget = findClosest()
			end
		else
			AimTarget = nil
		end
	end

	-- ESP
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LP then continue end
		local o = ESPPool[p]; if not o then continue end

		local tm    = isTeammate(p)
		local show  = C.ESP and ((tm and C.ESPTeammates) or (not tm and C.ESPEnemies))
		local char  = getChar(p)
		local hum   = char and char:FindFirstChildOfClass("Humanoid")
		local root  = char and char:FindFirstChild("HumanoidRootPart")

		if not show or not root or not hum or hum.Health<=0 then
			hideESP(o); continue
		end

		local dist = (Camera.CFrame.Position - root.Position).Magnitude
		if dist > C.ESPMaxDist then hideESP(o); continue end

		local rootSP, onSc = toScreen(root.Position)
		if not onSc then hideESP(o); continue end

		local head = char:FindFirstChild("Head")
		if not head then hideESP(o); continue end

		local mainC = tm and C.ESPTeamCol or C.ESPEnemyCol
		local hp    = math.clamp(hum.Health/math.max(hum.MaxHealth,1), 0, 1)
		local hpC   = Color3.fromHSV(hp*0.33, 1, 1)

		local topSP = toScreen(head.Position + Vector3.new(0,0.7,0))
		local botSP = toScreen(root.Position  - Vector3.new(0,2.8,0))
		local h     = math.abs(topSP.Y - botSP.Y)
		if h < 2 then hideESP(o); continue end
		local w = h*0.55; local l = rootSP.X - w/2; local t = topSP.Y

		if C.ESPBoxes then
			o.fill.Position=Vector2.new(l,t); o.fill.Size=Vector2.new(w,h); o.fill.Color=mainC; o.fill.Visible=true
			o.box.Position=Vector2.new(l,t);  o.box.Size=Vector2.new(w,h);  o.box.Color=mainC;  o.box.Visible=true
			corners(o, l, t, w, h, Color3.fromRGB(255,255,255))
		else
			o.fill.Visible=false; o.box.Visible=false
			for _, k in ipairs(CKEYS) do o[k].Visible=false end
		end

		if C.ESPHealth then
			local bw=4; local bh=h; local fill=bh*hp
			o.hpOut.Position=Vector2.new(l-bw-4,t); o.hpOut.Size=Vector2.new(bw,bh); o.hpOut.Visible=true
			o.hpBg.Position=Vector2.new(l-bw-4,t);  o.hpBg.Size=Vector2.new(bw,bh);  o.hpBg.Visible=true
			o.hpBar.Position=Vector2.new(l-bw-4,t+bh-fill); o.hpBar.Size=Vector2.new(bw,fill); o.hpBar.Color=hpC; o.hpBar.Visible=true
			o.hpTxt.Text=math.floor(hum.Health).."hp"; o.hpTxt.Position=Vector2.new(l-bw-4+bw/2,t+bh+2); o.hpTxt.Visible=true
		else
			o.hpOut.Visible=false; o.hpBg.Visible=false; o.hpBar.Visible=false; o.hpTxt.Visible=false
		end

		if C.ESPNames then
			o.name.Text=p.DisplayName; o.name.Color=Color3.fromRGB(255,255,255); o.name.Position=Vector2.new(rootSP.X,t-28); o.name.Visible=true
			o.tag.Text=tm and "[TEAM]" or "[ENEMY]"; o.tag.Color=mainC; o.tag.Position=Vector2.new(rootSP.X,t-16); o.tag.Visible=true
		else o.name.Visible=false; o.tag.Visible=false end

		if C.ESPDistance then
			o.dist.Text=math.floor(dist).."m"; o.dist.Position=Vector2.new(rootSP.X,t+h+3); o.dist.Visible=true
		else o.dist.Visible=false end

		if C.ESPTracers then
			o.trace.From=Vector2.new(cx,vp.Y); o.trace.To=rootSP; o.trace.Color=mainC; o.trace.Visible=true
		else o.trace.Visible=false end

		if C.ESPHeadDot then
			local hsp = toScreen(head.Position)
			o.hdot.Position=hsp; o.hdot.Color=Color3.fromRGB(255,255,255); o.hdot.Visible=true
			o.hfill.Position=hsp; o.hfill.Color=mainC; o.hfill.Visible=true
		else o.hdot.Visible=false; o.hfill.Visible=false end

		if C.ESPSkeleton then
			for idx, pair in ipairs(SKEL) do
				local b1=char:FindFirstChild(pair[1]); local b2=char:FindFirstChild(pair[2])
				local ln=o.skel[idx]
				if b1 and b2 then
					ln.From=toScreen(b1.Position); ln.To=toScreen(b2.Position); ln.Color=mainC; ln.Visible=true
				else ln.Visible=false end
			end
		else for _,l in ipairs(o.skel) do l.Visible=false end end
	end
end)

-- ═══════════════════════════════════
-- UI
-- ═══════════════════════════════════
local Win = Rayfield:CreateWindow({
	Name="Astra Hub", Icon=0,
	LoadingTitle="Astra Hub", LoadingSubtitle="v1.0",
	Theme="Default",
	ConfigurationSaving={Enabled=true, FileName="AstraHub"},
	KeySystem=false,
})

-- ── AIMBOT ───────────────────────────────────────────
local AT = Win:CreateTab("Aimbot", 4483362458)
AT:CreateSection("Aimbot")
AT:CreateToggle({Name="Enable Aimbot", CurrentValue=false, Flag="AimOn",
	Callback=function(v) C.Aimbot=v; if not v then Aiming=false; AimTarget=nil end end})
AT:CreateDropdown({Name="Mode", Options={"Camera","Silent"}, CurrentOption={"Camera"}, Flag="AimMd",
	Callback=function(v) C.AimMode=v[1]; Aiming=false; AimTarget=nil end})
AT:CreateToggle({Name="One-Press Mode", CurrentValue=false, Flag="AimOneP",
	Callback=function(v) C.OnePressAim=v end})
AT:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="AimTeam",
	Callback=function(v) C.TeamCheck=v end})
AT:CreateToggle({Name="Alive Check", CurrentValue=true, Flag="AimAlive",
	Callback=function(v) C.AliveCheck=v end})
AT:CreateToggle({Name="Wall Check", CurrentValue=false, Flag="AimWall",
	Callback=function(v) C.WallCheck=v end})
AT:CreateToggle({Name="FOV Check", CurrentValue=true, Flag="AimFovChk",
	Callback=function(v) C.FoVCheck=v end})
AT:CreateToggle({Name="Show FOV Circle", CurrentValue=true, Flag="AimShowF",
	Callback=function(v) C.ShowFoV=v end})
AT:CreateSlider({Name="FOV Radius", Range={10,500}, Increment=1, CurrentValue=150, Flag="AimFovR",
	Callback=function(v) C.FoVRadius=v end})
AT:CreateDropdown({Name="Target Bone", Options={"Head","HumanoidRootPart","UpperTorso","LowerTorso"}, CurrentOption={"Head"}, Flag="AimBone",
	Callback=function(v) C.AimPart=v[1] end})
AT:CreateSlider({Name="Smoothness (lower = snap)", Range={1,30}, Increment=1, CurrentValue=15, Flag="AimSm",
	Callback=function(v) C.Smoothness=v/100 end})

AT:CreateSection("Aim Offset & Noise")
AT:CreateToggle({Name="Use Y Offset", CurrentValue=false, Flag="AimUseOff",
	Callback=function(v) C.UseOffset=v end})
AT:CreateSlider({Name="Offset Y", Range={-30,30}, Increment=1, CurrentValue=0, Flag="AimOffY",
	Callback=function(v) C.OffsetY=v/10 end})
AT:CreateToggle({Name="Noise (humanize)", CurrentValue=false, Flag="AimNoise",
	Callback=function(v) C.UseNoise=v end})
AT:CreateSlider({Name="Noise Strength", Range={1,50}, Increment=1, CurrentValue=5, Flag="AimNoiseS",
	Callback=function(v) C.NoiseStr=v/100 end})

AT:CreateSection("Silent Aim Methods")
AT:CreateParagraph({Title="Info", Content="Silent mode: bullets redirect without camera moving. Hook: "..(hookOk and "ACTIVE ✓" or "NOT SUPPORTED")})
AT:CreateToggle({Name="Mouse.Hit / Mouse.Target", CurrentValue=true, Flag="SilHit",
	Callback=function(v) C.SilHit=v; C.SilTarget=v end})
AT:CreateToggle({Name="GetMouseLocation", CurrentValue=true, Flag="SilML",
	Callback=function(v) C.SilMouseLoc=v end})
AT:CreateToggle({Name="Raycast / FindPartOnRay", CurrentValue=true, Flag="SilRay",
	Callback=function(v) C.SilRaycast=v end})
AT:CreateParagraph({Title="Key", Content="Hold RMB to aim. One-Press: RMB toggles on/off."})

-- ── ESP ──────────────────────────────────────────────
local ET = Win:CreateTab("ESP", 4483362458)
ET:CreateSection("Targets")
ET:CreateToggle({Name="Enable ESP", CurrentValue=false, Flag="ESPOn", Callback=function(v) C.ESP=v end})
ET:CreateToggle({Name="Show Enemies", CurrentValue=true, Flag="ESPEn", Callback=function(v) C.ESPEnemies=v end})
ET:CreateToggle({Name="Show Teammates", CurrentValue=true, Flag="ESPTm", Callback=function(v) C.ESPTeammates=v end})
ET:CreateSection("Elements")
ET:CreateToggle({Name="Boxes + Corners", CurrentValue=true, Flag="ESPBox", Callback=function(v) C.ESPBoxes=v end})
ET:CreateToggle({Name="Names + Tag", CurrentValue=true, Flag="ESPNm", Callback=function(v) C.ESPNames=v end})
ET:CreateToggle({Name="Health Bar", CurrentValue=true, Flag="ESPHp", Callback=function(v) C.ESPHealth=v end})
ET:CreateToggle({Name="Distance", CurrentValue=true, Flag="ESPDst", Callback=function(v) C.ESPDistance=v end})
ET:CreateToggle({Name="Tracers", CurrentValue=false, Flag="ESPTr", Callback=function(v) C.ESPTracers=v end})
ET:CreateToggle({Name="Skeleton", CurrentValue=false, Flag="ESPSk", Callback=function(v) C.ESPSkeleton=v end})
ET:CreateToggle({Name="Head Dot", CurrentValue=true, Flag="ESPHd", Callback=function(v) C.ESPHeadDot=v end})
ET:CreateSlider({Name="Max Distance", Range={100,2000}, Increment=50, CurrentValue=1000, Flag="ESPMax",
	Callback=function(v) C.ESPMaxDist=v end})

-- ── COMBAT ───────────────────────────────────────────
local CT = Win:CreateTab("Combat", 4483362458)
CT:CreateSection("HitBox")
CT:CreateToggle({Name="HitBox Expander", CurrentValue=false, Flag="HBOn", Callback=function(v) C.HitBox=v end})
CT:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="HBTeam", Callback=function(v) C.HitBoxEnemyOnly=v end})
CT:CreateSlider({Name="HitBox Size", Range={1,20}, Increment=1, CurrentValue=5, Flag="HBSz",
	Callback=function(v) C.HitBoxSize=v end})

CT:CreateSection("TriggerBot")
CT:CreateToggle({Name="Enable TriggerBot", CurrentValue=false, Flag="TBOn",
	Callback=function(v) C.TriggerBot=v; if not v then Triggering=false end end})
CT:CreateToggle({Name="One-Press (E toggle)", CurrentValue=false, Flag="TBOneP",
	Callback=function(v) C.OnePressTrigg=v end})
CT:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="TBTeam",
	Callback=function(v) C.TrigTeamCheck=v end})
CT:CreateSlider({Name="Delay (ms)", Range={10,500}, Increment=10, CurrentValue=60, Flag="TBDelay",
	Callback=function(v) C.TrigDelay=v/1000 end})
CT:CreateSlider({Name="Chance (%)", Range={1,100}, Increment=1, CurrentValue=100, Flag="TBChance",
	Callback=function(v) C.TrigChance=v end})
CT:CreateParagraph({Title="Key", Content="Hold E to fire on target. One-Press = E toggles."})

CT:CreateSection("SpinBot")
CT:CreateToggle({Name="Enable SpinBot", CurrentValue=false, Flag="SBOn",
	Callback=function(v) C.SpinBot=v; if not v then Spinning=false end end})
CT:CreateToggle({Name="One-Press (Q toggle)", CurrentValue=false, Flag="SBOneP",
	Callback=function(v) C.OnePressSpinB=v end})
CT:CreateSlider({Name="Spin Speed", Range={1,200}, Increment=1, CurrentValue=50, Flag="SBSpd",
	Callback=function(v) C.SpinSpeed=v end})
CT:CreateParagraph({Title="Key", Content="Hold Q to spin. One-Press = Q toggles."})

CT:CreateSection("Ammo & Accuracy")
CT:CreateToggle({Name="Infinite Ammo", CurrentValue=false, Flag="InfAmm", Callback=function(v) C.InfAmmo=v end})
CT:CreateToggle({Name="No Spread / Recoil", CurrentValue=false, Flag="NoSpr", Callback=function(v) C.NoSpread=v end})

-- ── CHAMS ────────────────────────────────────────────
local ChT = Win:CreateTab("Chams", 4483362458)
ChT:CreateSection("Chams")
ChT:CreateToggle({Name="Enable Chams", CurrentValue=false, Flag="ChOn",
	Callback=function(v) C.Chams=v; refreshChams() end})
ChT:CreateSlider({Name="Transparency", Range={0,90}, Increment=5, CurrentValue=40, Flag="ChTr",
	Callback=function(v) C.ChamsTransp=v/100; if C.Chams then refreshChams() end end})
ChT:CreateSection("Enemy Color")
for n, rgb in pairs({Red={255,50,50},Orange={255,140,0},Yellow={255,220,0},Pink={255,80,200},White={240,240,240}}) do
	ChT:CreateButton({Name="Enemy: "..n, Callback=function()
		C.ChamsEnemyCol=Color3.fromRGB(rgb[1],rgb[2],rgb[3]); if C.Chams then refreshChams() end
	end})
end
ChT:CreateSection("Team Color")
for n, rgb in pairs({Blue={50,100,255},Cyan={0,200,255},Green={50,220,100},Purple={160,50,255}}) do
	ChT:CreateButton({Name="Team: "..n, Callback=function()
		C.ChamsTeamCol=Color3.fromRGB(rgb[1],rgb[2],rgb[3]); if C.Chams then refreshChams() end
	end})
end
ChT:CreateButton({Name="Refresh Chams", Callback=function()
	if C.Chams then refreshChams() end
	Rayfield:Notify({Title="Astra Hub", Content="Chams refreshed", Duration=2})
end})

-- ── MISC ─────────────────────────────────────────────
local MT = Win:CreateTab("Misc", 4483362458)
MT:CreateSection("Camera FOV")
MT:CreateToggle({Name="Custom FOV", CurrentValue=false, Flag="CFOVOn",
	Callback=function(v) C.CustomFOV=v; if not v then Camera.FieldOfView=C.OrigFOV end end})
MT:CreateSlider({Name="FOV Value", Range={30,120}, Increment=1, CurrentValue=70, Flag="CFOVVal",
	Callback=function(v) C.FOVValue=v end})
MT:CreateSection("Anti-AFK")
MT:CreateToggle({Name="Anti-AFK", CurrentValue=false, Flag="AAfk", Callback=function(v) C.AntiAFK=v end})
MT:CreateSection("Actions")
MT:CreateButton({Name="Disable ALL", Callback=function()
	C.Aimbot=false; C.ESP=false; C.HitBox=false; C.Chams=false
	C.InfAmmo=false; C.NoSpread=false; C.SpinBot=false
	C.TriggerBot=false; C.CustomFOV=false; C.AntiAFK=false
	Aiming=false; Spinning=false; Triggering=false; AimTarget=nil
	Camera.FieldOfView=C.OrigFOV; refreshChams()
	Rayfield:Notify({Title="Astra Hub", Content="All off", Duration=2})
end})
MT:CreateButton({Name="Destroy Script", Callback=function()
	pcall(function() fovDraw:Remove() end)
	for _, p in ipairs(Players:GetPlayers()) do clearESP(p); clearChams(p) end
	Aiming=false; Spinning=false; Triggering=false; AimTarget=nil
	Camera.FieldOfView=C.OrigFOV
	pcall(function() Rayfield:Destroy() end)
end})

Rayfield:Notify({
	Title="Astra Hub",
	Content="RMB = Aim  |  Q = Spin  |  E = Trigger",
	Duration=5,
})
