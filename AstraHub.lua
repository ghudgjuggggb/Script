local ok_rayfield, Rayfield = pcall(function()
	return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok_rayfield then warn("[AstraHub] Rayfield failed") return end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local S = {
	Aimbot           = false,
	AimbotFOV        = 120,
	AimbotSmooth     = 0.12,
	AimbotBone       = "Head",
	AimbotTeamCheck  = true,
	AimbotPrediction = true,
	ShowFOVCircle    = true,
	AimbotActive     = false,

	SilentAim        = false,
	SilentFOV        = 150,
	SilentTeamCheck  = true,

	MagicBullet      = false,
	MagicFOV         = 200,
	MagicBone        = "HumanoidRootPart",
	MagicTeamCheck   = true,

	ESP              = false,
	ESPEnemies       = true,
	ESPTeammates     = true,
	ESPBoxes         = true,
	ESPNames         = true,
	ESPHealth        = true,
	ESPDistance      = true,
	ESPTracers       = false,
	ESPSkeleton      = false,
	ESPHeadDot       = true,
	ESPMaxDist       = 1000,
	ESPEnemyColor    = Color3.fromRGB(255, 60, 60),
	ESPTeamColor     = Color3.fromRGB(60, 180, 255),

	HitBoxEnabled    = false,
	HitBoxSize       = 5,
	HitBoxTeamCheck  = true,

	ChamsEnabled     = false,
	ChamsEnemyColor  = Color3.fromRGB(255, 50, 50),
	ChamsTeamColor   = Color3.fromRGB(50, 120, 255),
	ChamsTransp      = 0.4,

	InfAmmo          = false,
	NoSpread         = false,
}

local velCache = {}
local posCache = {}

local function isTeammate(p)
	if p == LP then return true end
	local t = LP.Team
	if t and p.Team and p.Team == t then return true end
	return false
end

local function isAlive(p)
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

local function isValidTarget(p, teamCheck)
	if p == LP then return false end
	if not isAlive(p) then return false end
	if teamCheck and isTeammate(p) then return false end
	return true
end

local function getRoot(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
local function getHum(p)  return p.Character and p.Character:FindFirstChildOfClass("Humanoid") end

local function getBone(p, bone)
	local c = p.Character
	if not c then return nil end
	return c:FindFirstChild(bone) or c:FindFirstChild("HumanoidRootPart")
end

local function getScreenPos(worldPos)
	local pos, onScreen = Camera:WorldToViewportPoint(worldPos)
	return Vector2.new(pos.X, pos.Y), onScreen, pos.Z
end

local function getPredicted(p, bone)
	local part = getBone(p, bone)
	if not part then return nil end
	local vel = velCache[p]
	if vel then return part.Position + vel * 0.055 end
	return part.Position
end

local function getClosestTarget(fov, bone, teamCheck)
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	local closest, closestDist = nil, fov
	for _, p in ipairs(Players:GetPlayers()) do
		if isValidTarget(p, teamCheck) then
			local worldPos = S.AimbotPrediction and getPredicted(p, bone) or nil
			if not worldPos then
				local part = getBone(p, bone)
				if part then worldPos = part.Position end
			end
			if worldPos then
				local sp, onScreen = getScreenPos(worldPos)
				if onScreen then
					local d = (sp - center).Magnitude
					if d < closestDist then closestDist = d; closest = p end
				end
			end
		end
	end
	return closest
end

RunService.Heartbeat:Connect(function(dt)
	for _, p in ipairs(Players:GetPlayers()) do
		local root = getRoot(p)
		if root then
			local prev = posCache[p]
			local curr = root.Position
			if prev and dt > 0 then velCache[p] = (curr - prev) / dt end
			posCache[p] = curr
		end
	end
end)

local hookOk = pcall(function()
	local mt = getrawmetatable(game)
	setreadonly(mt, false)
	local old = mt.__namecall
	mt.__namecall = newcclosure(function(self, ...)
		local method = getnamecallmethod()
		local args = {...}
		if method == "FireServer" or method == "InvokeServer" then
			if S.SilentAim then
				local t = getClosestTarget(S.SilentFOV, S.AimbotBone, S.SilentTeamCheck)
				if t then
					local pos = S.AimbotPrediction and getPredicted(t, S.AimbotBone) or nil
					local bone = getBone(t, S.AimbotBone)
					if bone then
						pos = pos or bone.Position
						for i, v in ipairs(args) do
							if typeof(v) == "Instance" and v:IsA("BasePart") then args[i] = bone
							elseif typeof(v) == "CFrame" then args[i] = CFrame.new(pos)
							elseif typeof(v) == "Vector3" then args[i] = pos end
						end
					end
				end
			end
			if S.MagicBullet then
				local t = getClosestTarget(S.MagicFOV, S.MagicBone, S.MagicTeamCheck)
				if t then
					local bone = getBone(t, S.MagicBone)
					if bone then
						local pos = (S.AimbotPrediction and getPredicted(t, S.MagicBone)) or bone.Position
						local newArgs = table.clone(args)
						local changed = false
						for i, v in ipairs(newArgs) do
							if typeof(v) == "Vector3" then
								newArgs[i] = pos
								changed = true
							elseif typeof(v) == "CFrame" then
								newArgs[i] = CFrame.new(pos)
								changed = true
							end
						end
						if changed then
							return old(self, unpack(newArgs))
						end
					end
				end
			end
			return old(self, unpack(args))
		end
		return old(self, ...)
	end)
	setreadonly(mt, true)
end)

local function newDraw(t, props)
	local d = Drawing.new(t)
	for k, v in pairs(props) do d[k] = v end
	return d
end

local fovCircle    = newDraw("Circle", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1.5, Filled=false, NumSides=64})
local silentCircle = newDraw("Circle", {Visible=false, Color=Color3.fromRGB(0,200,255),   Thickness=1.5, Filled=false, NumSides=64})
local magicCircle  = newDraw("Circle", {Visible=false, Color=Color3.fromRGB(200,80,255),  Thickness=1.5, Filled=false, NumSides=64})

local SKEL = {
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
	o.boxFill  = newDraw("Square",{Color=Color3.fromRGB(255,60,60), Transparency=0.25, Filled=true, Visible=false, Thickness=0})
	o.box      = newDraw("Square",{Color=Color3.fromRGB(255,60,60), Thickness=1.5, Filled=false, Visible=false})
	local cnames = {"cTL","cTL2","cTR","cTR2","cBL","cBL2","cBR","cBR2"}
	for _, cn in ipairs(cnames) do
		o[cn] = newDraw("Line",{Color=Color3.fromRGB(255,255,255), Thickness=2.5, Visible=false})
	end
	o.hpOutline = newDraw("Square",{Color=Color3.fromRGB(0,0,0),   Filled=false, Visible=false, Thickness=1})
	o.hpBg      = newDraw("Square",{Color=Color3.fromRGB(15,15,15),Filled=true,  Visible=false, Thickness=0})
	o.hpBar     = newDraw("Square",{Color=Color3.fromRGB(50,220,50),Filled=true,  Visible=false, Thickness=0})
	o.hpText    = newDraw("Text",  {Color=Color3.fromRGB(255,255,255),Size=10,Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true,Font=2})
	o.nameLbl   = newDraw("Text",  {Color=Color3.fromRGB(255,255,255),Size=13,Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true,Font=2})
	o.tagLbl    = newDraw("Text",  {Color=Color3.fromRGB(100,200,255),Size=11,Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true,Font=2})
	o.distLbl   = newDraw("Text",  {Color=Color3.fromRGB(180,180,180),Size=11,Outline=true,OutlineColor=Color3.fromRGB(0,0,0),Visible=false,Center=true,Font=2})
	o.tracer    = newDraw("Line",  {Color=Color3.fromRGB(255,60,60), Thickness=1, Visible=false})
	o.headDot   = newDraw("Circle",{Color=Color3.fromRGB(255,255,255),Thickness=1.5,Filled=false,NumSides=32,Radius=4,Visible=false})
	o.headFill  = newDraw("Circle",{Color=Color3.fromRGB(255,60,60), Transparency=0.5,Filled=true,NumSides=32,Radius=4,Visible=false})
	o.skel = {}
	for _ = 1, #SKEL do table.insert(o.skel, newDraw("Line",{Color=Color3.fromRGB(255,255,255),Thickness=1,Visible=false})) end
	ESPObjects[p] = o
end

local function clearESP(p)
	local o = ESPObjects[p]
	if not o then return end
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
	local r, b = l + w, t + h
	local lines = {
		{o.cTL,  Vector2.new(l,t),   Vector2.new(l+cl,t)},
		{o.cTL2, Vector2.new(l,t),   Vector2.new(l,t+cl)},
		{o.cTR,  Vector2.new(r,t),   Vector2.new(r-cl,t)},
		{o.cTR2, Vector2.new(r,t),   Vector2.new(r,t+cl)},
		{o.cBL,  Vector2.new(l,b),   Vector2.new(l+cl,b)},
		{o.cBL2, Vector2.new(l,b),   Vector2.new(l,b-cl)},
		{o.cBR,  Vector2.new(r,b),   Vector2.new(r-cl,b)},
		{o.cBR2, Vector2.new(r,b),   Vector2.new(r,b-cl)},
	}
	for _, c in ipairs(lines) do
		c[1].From = c[2]; c[1].To = c[3]; c[1].Color = color; c[1].Visible = true
	end
end

local function applyChams(p)
	local char = p.Character
	if not char then return end
	ChamsObjects[p] = {}
	local color = isTeammate(p) and S.ChamsTeamColor or S.ChamsEnemyColor
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			local orig = {Material=v.Material, Color=v.Color, Transparency=v.Transparency}
			table.insert(ChamsObjects[p], {part=v, original=orig})
			v.Material = Enum.Material.Neon
			v.Color = color
			v.Transparency = S.ChamsTransp
		end
	end
end

local function clearChams(p)
	local list = ChamsObjects[p]
	if not list then return end
	for _, info in ipairs(list) do
		pcall(function()
			info.part.Material    = info.original.Material
			info.part.Color       = info.original.Color
			info.part.Transparency = info.original.Transparency
		end)
	end
	ChamsObjects[p] = nil
end

local function refreshChams()
	for _, p in ipairs(Players:GetPlayers()) do
		clearChams(p)
		if S.ChamsEnabled and p ~= LP and isAlive(p) then applyChams(p) end
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LP then
		makeESP(p)
		p.CharacterAdded:Connect(function()
			task.wait(0.5)
			if S.ChamsEnabled then clearChams(p); applyChams(p) end
		end)
	end
end
Players.PlayerAdded:Connect(function(p)
	task.wait(0.1); makeESP(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		if S.ChamsEnabled then clearChams(p); applyChams(p) end
	end)
end)
Players.PlayerRemoving:Connect(function(p) clearESP(p); clearChams(p) end)

local mobileGui = nil
local mobileAimBtn = nil
if IS_MOBILE then
	mobileGui = Instance.new("ScreenGui")
	mobileGui.Name = "AstraHubMobile"
	mobileGui.ResetOnSpawn = false
	mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mobileGui.Parent = LP.PlayerGui

	mobileAimBtn = Instance.new("ImageButton")
	mobileAimBtn.Size = UDim2.new(0, 90, 0, 90)
	mobileAimBtn.Position = UDim2.new(1, -110, 1, -200)
	mobileAimBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	mobileAimBtn.BackgroundTransparency = 0.2
	mobileAimBtn.Visible = false
	mobileAimBtn.Parent = mobileGui
	Instance.new("UICorner", mobileAimBtn).CornerRadius = UDim.new(1, 0)

	local aimLbl = Instance.new("TextLabel")
	aimLbl.Text = "🎯 AIM"
	aimLbl.Font = Enum.Font.GothamBold
	aimLbl.TextSize = 16
	aimLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	aimLbl.BackgroundTransparency = 1
	aimLbl.Size = UDim2.new(1, 0, 1, 0)
	aimLbl.Parent = mobileAimBtn

	mobileAimBtn.MouseButton1Down:Connect(function() S.AimbotActive = true end)
	mobileAimBtn.MouseButton1Up:Connect(function()   S.AimbotActive = false end)
	mobileAimBtn.TouchLongPress:Connect(function()   S.AimbotActive = false end)
end

local function isAimPressed()
	if IS_MOBILE then return S.AimbotActive end
	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

RunService.RenderStepped:Connect(function()
	local vp     = Camera.ViewportSize
	local center = Vector2.new(vp.X / 2, vp.Y / 2)

	fovCircle.Position    = center; fovCircle.Radius    = S.AimbotFOV
	silentCircle.Position = center; silentCircle.Radius = S.SilentFOV
	magicCircle.Position  = center; magicCircle.Radius  = S.MagicFOV

	fovCircle.Visible    = S.ShowFOVCircle and S.Aimbot
	silentCircle.Visible = S.SilentAim
	magicCircle.Visible  = S.MagicBullet

	if mobileAimBtn then mobileAimBtn.Visible = S.Aimbot end

	if S.Aimbot and isAimPressed() then
		local target = getClosestTarget(S.AimbotFOV, S.AimbotBone, S.AimbotTeamCheck)
		if target then
			local aimPos = S.AimbotPrediction and getPredicted(target, S.AimbotBone) or nil
			local bone   = getBone(target, S.AimbotBone)
			if bone then
				aimPos = aimPos or bone.Position
				local _, onScreen = getScreenPos(aimPos)
				if onScreen then
					Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimPos), S.AimbotSmooth)
				end
			end
		end
	end

	if S.HitBoxEnabled then
		for _, p in ipairs(Players:GetPlayers()) do
			if isValidTarget(p, S.HitBoxTeamCheck) and p.Character then
				for _, v in ipairs(p.Character:GetDescendants()) do
					if v:IsA("BasePart") then
						pcall(function() v.Size = Vector3.new(S.HitBoxSize, S.HitBoxSize, S.HitBoxSize) end)
					end
				end
			end
		end
	end

	if S.InfAmmo then
		local char = LP.Character
		if char then
			for _, v in ipairs(char:GetDescendants()) do
				if (v:IsA("IntValue") or v:IsA("NumberValue")) then
					local n = v.Name:lower()
					if (n:find("ammo") or n:find("bullet") or n:find("mag") or n:find("clip")) and v.Value < 200 then
						pcall(function() v.Value = 9999 end)
					end
				end
			end
		end
	end

	if S.NoSpread then
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

	for _, p in ipairs(Players:GetPlayers()) do
		if p == LP then continue end
		local o = ESPObjects[p]
		if not o then continue end

		local teammate = isTeammate(p)
		local showThis = S.ESP and ((teammate and S.ESPTeammates) or (not teammate and S.ESPEnemies))

		local root = getRoot(p)
		local hum  = getHum(p)
		local char = p.Character

		if not showThis or not root or not hum or not char or not isAlive(p) then
			hideESP(o); continue
		end

		local dist = (Camera.CFrame.Position - root.Position).Magnitude
		if dist > S.ESPMaxDist then hideESP(o); continue end

		local rootSP, onScreen = getScreenPos(root.Position)
		if not onScreen then hideESP(o); continue end

		local headPart = char:FindFirstChild("Head")
		if not headPart then hideESP(o); continue end

		local mainColor = teammate and S.ESPTeamColor or S.ESPEnemyColor
		local hp        = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		local hpColor   = Color3.fromHSV(hp * 0.33, 1, 1)

		local topSP    = getScreenPos(headPart.Position + Vector3.new(0, 0.7, 0))
		local bottomSP = getScreenPos(root.Position - Vector3.new(0, 2.8, 0))
		local height   = math.abs(topSP.Y - bottomSP.Y)
		if height < 2 then hideESP(o); continue end
		local width = height * 0.55
		local left  = rootSP.X - width / 2
		local top   = topSP.Y

		if S.ESPBoxes then
			o.boxFill.Position = Vector2.new(left, top); o.boxFill.Size = Vector2.new(width, height)
			o.boxFill.Color = mainColor; o.boxFill.Visible = true
			o.box.Position = Vector2.new(left, top); o.box.Size = Vector2.new(width, height)
			o.box.Color = mainColor; o.box.Visible = true
			drawCorners(o, left, top, width, height, Color3.fromRGB(255, 255, 255))
		else
			o.box.Visible=false; o.boxFill.Visible=false
			for _, cn in ipairs({"cTL","cTL2","cTR","cTR2","cBL","cBL2","cBR","cBR2"}) do o[cn].Visible=false end
		end

		if S.ESPHealth then
			local bw=4; local bh=height; local fill=bh*hp
			o.hpOutline.Position=Vector2.new(left-bw-4,top); o.hpOutline.Size=Vector2.new(bw,bh); o.hpOutline.Visible=true
			o.hpBg.Position=Vector2.new(left-bw-4,top); o.hpBg.Size=Vector2.new(bw,bh); o.hpBg.Visible=true
			o.hpBar.Position=Vector2.new(left-bw-4,top+bh-fill); o.hpBar.Size=Vector2.new(bw,fill); o.hpBar.Color=hpColor; o.hpBar.Visible=true
			o.hpText.Text=math.floor(hum.Health).."hp"; o.hpText.Position=Vector2.new(left-bw-4+bw/2,top+bh+2); o.hpText.Visible=true
		else
			o.hpOutline.Visible=false; o.hpBg.Visible=false; o.hpBar.Visible=false; o.hpText.Visible=false
		end

		if S.ESPNames then
			o.nameLbl.Text=p.DisplayName; o.nameLbl.Color=Color3.fromRGB(255,255,255); o.nameLbl.Position=Vector2.new(rootSP.X,top-28); o.nameLbl.Visible=true
			o.tagLbl.Text=teammate and "[TEAM]" or "[ENEMY]"; o.tagLbl.Color=mainColor; o.tagLbl.Position=Vector2.new(rootSP.X,top-16); o.tagLbl.Visible=true
		else
			o.nameLbl.Visible=false; o.tagLbl.Visible=false
		end

		if S.ESPDistance then
			o.distLbl.Text=math.floor(dist).."m"; o.distLbl.Position=Vector2.new(rootSP.X,top+height+3); o.distLbl.Visible=true
		else o.distLbl.Visible=false end

		if S.ESPTracers then
			o.tracer.From=Vector2.new(center.X,vp.Y); o.tracer.To=rootSP; o.tracer.Color=mainColor; o.tracer.Visible=true
		else o.tracer.Visible=false end

		if S.ESPHeadDot then
			local hsp = getScreenPos(headPart.Position)
			o.headDot.Position=hsp; o.headDot.Color=Color3.fromRGB(255,255,255); o.headDot.Visible=true
			o.headFill.Position=hsp; o.headFill.Color=mainColor; o.headFill.Visible=true
		else o.headDot.Visible=false; o.headFill.Visible=false end

		if S.ESPSkeleton then
			for idx, pair in ipairs(SKEL) do
				local b1=char:FindFirstChild(pair[1]); local b2=char:FindFirstChild(pair[2])
				local ln=o.skel[idx]
				if b1 and b2 then ln.From=getScreenPos(b1.Position); ln.To=getScreenPos(b2.Position); ln.Color=mainColor; ln.Visible=true
				else ln.Visible=false end
			end
		else for _,l in ipairs(o.skel) do l.Visible=false end end
	end
end)

local Window = Rayfield:CreateWindow({
	Name            = "Astra Hub",
	Icon            = 0,
	LoadingTitle    = "Astra Hub",
	LoadingSubtitle = IS_MOBILE and "📱 Mobile Mode" or "💻 PC Mode",
	Theme           = "Default",
	ConfigurationSaving = {Enabled=true, FileName="AstraHub"},
	KeySystem       = false,
})

local AimTab = Window:CreateTab("Aimbot", 4483362458)
AimTab:CreateSection("Aimbot")
AimTab:CreateToggle({Name="Enable Aimbot", CurrentValue=false, Flag="AimbotOn",
	Callback=function(v) S.Aimbot=v; if v then S.SilentAim=false; S.MagicBullet=false end end})
AimTab:CreateToggle({Name="Velocity Prediction", CurrentValue=true, Flag="AimbotPred",
	Callback=function(v) S.AimbotPrediction=v end})
AimTab:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="AimbotTeam",
	Callback=function(v) S.AimbotTeamCheck=v end})
AimTab:CreateToggle({Name="Show FOV Circle", CurrentValue=true, Flag="ShowFOV",
	Callback=function(v) S.ShowFOVCircle=v end})
AimTab:CreateSlider({Name="FOV Radius", Range={10,500}, Increment=1, CurrentValue=120, Flag="AimFOV",
	Callback=function(v) S.AimbotFOV=v end})
AimTab:CreateSlider({Name="Smoothness (lower = faster)", Range={1,100}, Increment=1, CurrentValue=12, Flag="AimSmooth",
	Callback=function(v) S.AimbotSmooth=v/100 end})
AimTab:CreateDropdown({Name="Target Bone", Options={"Head","HumanoidRootPart","UpperTorso","LowerTorso"}, CurrentOption={"Head"}, Flag="AimBone",
	Callback=function(v) S.AimbotBone=v[1] end})
AimTab:CreateParagraph({
	Title   = IS_MOBILE and "📱 Mobile Control" or "💻 PC Control",
	Content = IS_MOBILE and "Hold the AIM button (bottom right) to lock onto target." or "Hold Right Mouse Button to lock onto target.",
})
AimTab:CreateSection("Silent Aim")
AimTab:CreateToggle({Name="Enable Silent Aim", CurrentValue=false, Flag="SilentOn",
	Callback=function(v) S.SilentAim=v; if v then S.Aimbot=false; S.MagicBullet=false end end})
AimTab:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="SilentTeam",
	Callback=function(v) S.SilentTeamCheck=v end})
AimTab:CreateSlider({Name="Silent Aim FOV", Range={10,600}, Increment=1, CurrentValue=150, Flag="SilentFOV",
	Callback=function(v) S.SilentFOV=v end})
AimTab:CreateSection("Magic Bullet")
AimTab:CreateToggle({Name="Enable Magic Bullet", CurrentValue=false, Flag="MagicOn",
	Callback=function(v) S.MagicBullet=v; if v then S.Aimbot=false; S.SilentAim=false end end})
AimTab:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="MagicTeam",
	Callback=function(v) S.MagicTeamCheck=v end})
AimTab:CreateSlider({Name="Magic Bullet FOV", Range={10,800}, Increment=1, CurrentValue=200, Flag="MagicFOV",
	Callback=function(v) S.MagicFOV=v end})
AimTab:CreateDropdown({Name="Magic Bone", Options={"HumanoidRootPart","Head","UpperTorso"}, CurrentOption={"HumanoidRootPart"}, Flag="MagicBone",
	Callback=function(v) S.MagicBone=v[1] end})

local ESPTab = Window:CreateTab("ESP", 4483362458)
ESPTab:CreateSection("Targets")
ESPTab:CreateToggle({Name="Enable ESP", CurrentValue=false, Flag="ESPOn", Callback=function(v) S.ESP=v end})
ESPTab:CreateToggle({Name="Show Enemies", CurrentValue=true, Flag="ESPEnemy", Callback=function(v) S.ESPEnemies=v end})
ESPTab:CreateToggle({Name="Show Teammates", CurrentValue=true, Flag="ESPTeam", Callback=function(v) S.ESPTeammates=v end})
ESPTab:CreateSection("Elements")
ESPTab:CreateToggle({Name="Boxes + Corners", CurrentValue=true, Flag="ESPBox", Callback=function(v) S.ESPBoxes=v end})
ESPTab:CreateToggle({Name="Names + Tag", CurrentValue=true, Flag="ESPName", Callback=function(v) S.ESPNames=v end})
ESPTab:CreateToggle({Name="Health Bar", CurrentValue=true, Flag="ESPHp", Callback=function(v) S.ESPHealth=v end})
ESPTab:CreateToggle({Name="Distance", CurrentValue=true, Flag="ESPDist", Callback=function(v) S.ESPDistance=v end})
ESPTab:CreateToggle({Name="Tracers", CurrentValue=false, Flag="ESPTrace", Callback=function(v) S.ESPTracers=v end})
ESPTab:CreateToggle({Name="Skeleton", CurrentValue=false, Flag="ESPSkel", Callback=function(v) S.ESPSkeleton=v end})
ESPTab:CreateToggle({Name="Head Dot", CurrentValue=true, Flag="ESPHead", Callback=function(v) S.ESPHeadDot=v end})
ESPTab:CreateSlider({Name="Max Distance (studs)", Range={100,2000}, Increment=50, CurrentValue=1000, Flag="ESPMax",
	Callback=function(v) S.ESPMaxDist=v end})

local CombatTab = Window:CreateTab("Combat", 4483362458)
CombatTab:CreateSection("HitBox")
CombatTab:CreateToggle({Name="HitBox Expander", CurrentValue=false, Flag="HitOn", Callback=function(v) S.HitBoxEnabled=v end})
CombatTab:CreateToggle({Name="Enemies Only", CurrentValue=true, Flag="HitTeam", Callback=function(v) S.HitBoxTeamCheck=v end})
CombatTab:CreateSlider({Name="HitBox Size", Range={1,20}, Increment=0.5, CurrentValue=5, Flag="HitSz",
	Callback=function(v) S.HitBoxSize=v end})
CombatTab:CreateSection("Ammo & Accuracy")
CombatTab:CreateToggle({Name="Infinite Ammo", CurrentValue=false, Flag="InfAmmoOn", Callback=function(v) S.InfAmmo=v end})
CombatTab:CreateToggle({Name="No Spread / No Recoil", CurrentValue=false, Flag="NoSpreadOn", Callback=function(v) S.NoSpread=v end})

local ChamsTab = Window:CreateTab("Chams", 4483362458)
ChamsTab:CreateSection("Chams")
ChamsTab:CreateToggle({Name="Enable Chams", CurrentValue=false, Flag="ChamsOn",
	Callback=function(v) S.ChamsEnabled=v; refreshChams() end})
ChamsTab:CreateSlider({Name="Transparency", Range={0,90}, Increment=5, CurrentValue=40, Flag="ChamsT",
	Callback=function(v) S.ChamsTransp=v/100; if S.ChamsEnabled then refreshChams() end end})
ChamsTab:CreateSection("Enemy Color")
for name, rgb in pairs({Red={255,50,50},Orange={255,140,0},Yellow={255,220,0},Pink={255,80,200},White={240,240,240}}) do
	ChamsTab:CreateButton({Name="Enemy: "..name, Callback=function()
		S.ChamsEnemyColor=Color3.fromRGB(rgb[1],rgb[2],rgb[3]); if S.ChamsEnabled then refreshChams() end
	end})
end
ChamsTab:CreateSection("Teammate Color")
for name, rgb in pairs({Blue={50,100,255},Cyan={0,200,255},Green={50,220,100},Purple={160,50,255}}) do
	ChamsTab:CreateButton({Name="Team: "..name, Callback=function()
		S.ChamsTeamColor=Color3.fromRGB(rgb[1],rgb[2],rgb[3]); if S.ChamsEnabled then refreshChams() end
	end})
end
ChamsTab:CreateButton({Name="Refresh Chams", Callback=function()
	if S.ChamsEnabled then refreshChams() end
	Rayfield:Notify({Title="Astra Hub", Content="Chams refreshed", Duration=2})
end})

local SetTab = Window:CreateTab("Settings", 4483362458)
SetTab:CreateSection("Device Info")
SetTab:CreateParagraph({
	Title   = IS_MOBILE and "📱 Mobile Detected" or "💻 PC Detected",
	Content = IS_MOBILE and "All features work via toggles. Aimbot uses on-screen button." or "All features work via toggles. Aimbot uses RMB.",
})
SetTab:CreateParagraph({
	Title   = "Hook Status",
	Content = hookOk and "Silent Aim / Magic Bullet: ACTIVE ✓" or "Hook failed — executor may not support getrawmetatable",
})
SetTab:CreateSection("Actions")
SetTab:CreateButton({Name="Disable ALL", Callback=function()
	S.Aimbot=false; S.SilentAim=false; S.MagicBullet=false
	S.ESP=false; S.HitBoxEnabled=false; S.ChamsEnabled=false
	S.InfAmmo=false; S.NoSpread=false; S.AimbotActive=false
	refreshChams()
	Rayfield:Notify({Title="Astra Hub", Content="All disabled", Duration=3})
end})
SetTab:CreateButton({Name="Destroy Script", Callback=function()
	for _, d in pairs({fovCircle, silentCircle, magicCircle}) do pcall(function() d:Remove() end) end
	for _, p in ipairs(Players:GetPlayers()) do clearESP(p); clearChams(p) end
	if mobileGui then pcall(function() mobileGui:Destroy() end) end
	pcall(function() Rayfield:Destroy() end)
end})

Rayfield:Notify({
	Title   = "Astra Hub",
	Content = IS_MOBILE and "Loaded! Use the AIM button to lock on." or "Loaded! Hold RMB to aim.",
	Duration = 5,
})
