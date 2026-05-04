local ok_rayfield, Rayfield = pcall(function()
	return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok_rayfield then warn("[AstraHub] Rayfield failed") return end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Camera            = workspace.CurrentCamera
local LP                = Players.LocalPlayer

local S = {
	Aimbot         = false,
	AimbotFOV      = 120,
	AimbotSmooth   = 0.15,
	AimbotBone     = "Head",
	AimbotKey      = Enum.UserInputType.MouseButton2,
	AimbotTeamCheck = true,
	ShowFOVCircle  = true,
	SilentAim      = false,
	SilentFOV      = 150,
	SilentTeamCheck = true,
	MagicBullet    = false,
	MagicFOV       = 200,
	MagicBone      = "HumanoidRootPart",
	MagicTeamCheck = true,
	ESP            = false,
	ESPEnemies     = true,
	ESPTeammates   = true,
	ESPBoxes       = true,
	ESPNames       = true,
	ESPHealth      = true,
	ESPDistance    = true,
	ESPTracers     = false,
	ESPSkeleton    = false,
	ESPHeadDot     = true,
	ESPMaxDist     = 1000,
	ESPEnemyColor  = Color3.fromRGB(255, 60, 60),
	ESPTeamColor   = Color3.fromRGB(60, 180, 255),
	HitBoxEnabled  = false,
	HitBoxSize     = 5,
	HitBoxTeamCheck = true,
	ChamsEnabled   = false,
	ChamsEnemyColor = Color3.fromRGB(255, 50, 50),
	ChamsTeamColor  = Color3.fromRGB(50, 120, 255),
	ChamsTransp    = 0.4,
	FireRate       = false,
	FireRateVal    = 0.05,
	InfAmmo        = false,
	NoSpread       = false,
}

local function isTeammate(p)
	if p == LP then return true end
	local myTeam = LP.Team
	if myTeam and p.Team and p.Team == myTeam then return true end
	return false
end

local function isEnemy(p)
	if p == LP then return false end
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	return not isTeammate(p)
end

local function isAlivePlayer(p)
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
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

local function getClosestTarget(fovRadius, boneKey, teamCheck)
	local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
	local closest, closestDist = nil, fovRadius
	for _, p in ipairs(Players:GetPlayers()) do
		local valid = teamCheck and isEnemy(p) or (not teamCheck and p ~= LP and isAlivePlayer(p))
		if valid then
			local part = getBone(p, boneKey)
			if part then
				local sp, onScreen = getScreenPos(part.Position)
				if onScreen then
					local dist = (sp - center).Magnitude
					if dist < closestDist then
						closestDist = dist
						closest = p
					end
				end
			end
		end
	end
	return closest
end

-- Anti-ban / Anti-kick
local antiBanOk = pcall(function()
	local mt = getrawmetatable(game)
	setreadonly(mt, false)
	local oldNamecall = mt.__namecall
	mt.__namecall = newcclosure(function(self, ...)
		local method = getnamecallmethod()
		if method == "Kick" then return end
		if method == "FireServer" or method == "InvokeServer" then
			local args = {...}
			if S.SilentAim then
				local target = getClosestTarget(S.SilentFOV, S.AimbotBone, S.SilentTeamCheck)
				if target then
					local bone = getBone(target, S.AimbotBone)
					if bone then
						for i, v in ipairs(args) do
							if typeof(v) == "Instance" and v:IsA("BasePart") then args[i] = bone
							elseif typeof(v) == "CFrame" then args[i] = bone.CFrame
							elseif typeof(v) == "Vector3" then args[i] = bone.Position end
						end
					end
				end
			end
			if S.MagicBullet then
				local target = getClosestTarget(S.MagicFOV, S.MagicBone, S.MagicTeamCheck)
				if target then
					local bone = getBone(target, S.MagicBone)
					if bone then
						for i, v in ipairs(args) do
							if typeof(v) == "Vector3" then args[i] = bone.Position
							elseif typeof(v) == "CFrame" then args[i] = bone.CFrame end
						end
					end
				end
			end
			return oldNamecall(self, unpack(args))
		end
		return oldNamecall(self, ...)
	end)
	setreadonly(mt, true)
end)

-- Block unauthorized teleport/data wipes
pcall(function()
	LP.OnTeleport:Connect(function(state)
		if state == Enum.TeleportState.Started then
			warn("[AstraHub] Teleport blocked")
		end
	end)
end)

-- Re-spawn protection character state
local function protectChar()
	local char = LP.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:GetPropertyChangedSignal("Health"):Connect(function()
		end)
	end
end
LP.CharacterAdded:Connect(function() task.wait(0.2) protectChar() end)
protectChar()

-- Drawing ESP system
local ESPObjects = {}
local ChamsObjects = {}

local BONES_PAIRS = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
}

local function newDrawing(type, props)
	local d = Drawing.new(type)
	for k,v in pairs(props) do d[k]=v end
	return d
end

local function makeESP(p)
	local objs = {}

	objs.box = newDrawing("Square", { Color=Color3.fromRGB(255,60,60), Thickness=1.5, Filled=false, Visible=false })
	objs.boxCorner1 = newDrawing("Square", { Color=Color3.fromRGB(255,255,255), Thickness=2, Filled=true, Visible=false })
	objs.boxCorner2 = newDrawing("Square", { Color=Color3.fromRGB(255,255,255), Thickness=2, Filled=true, Visible=false })
	objs.boxCorner3 = newDrawing("Square", { Color=Color3.fromRGB(255,255,255), Thickness=2, Filled=true, Visible=false })
	objs.boxCorner4 = newDrawing("Square", { Color=Color3.fromRGB(255,255,255), Thickness=2, Filled=true, Visible=false })

	objs.boxFill = newDrawing("Square", { Color=Color3.fromRGB(0,0,0), Transparency=0.35, Filled=true, Visible=false, Thickness=0 })

	objs.healthBg  = newDrawing("Square", { Color=Color3.fromRGB(15,15,15), Filled=true,  Visible=false, Thickness=0 })
	objs.healthBar = newDrawing("Square", { Color=Color3.fromRGB(50,220,50), Filled=true, Visible=false, Thickness=0 })
	objs.healthOutline = newDrawing("Square", { Color=Color3.fromRGB(0,0,0), Filled=false, Visible=false, Thickness=1 })

	objs.nameLabel = newDrawing("Text", {
		Color=Color3.fromRGB(255,255,255), Size=13, Outline=true,
		OutlineColor=Color3.fromRGB(0,0,0), Visible=false, Center=true, Font=Drawing.Fonts.UI
	})
	objs.teamLabel = newDrawing("Text", {
		Color=Color3.fromRGB(100,200,255), Size=11, Outline=true,
		OutlineColor=Color3.fromRGB(0,0,0), Visible=false, Center=true, Font=Drawing.Fonts.UI
	})
	objs.distLabel = newDrawing("Text", {
		Color=Color3.fromRGB(200,200,200), Size=11, Outline=true,
		OutlineColor=Color3.fromRGB(0,0,0), Visible=false, Center=true, Font=Drawing.Fonts.UI
	})
	objs.healthLabel = newDrawing("Text", {
		Color=Color3.fromRGB(255,255,255), Size=10, Outline=true,
		OutlineColor=Color3.fromRGB(0,0,0), Visible=false, Center=true, Font=Drawing.Fonts.UI
	})

	objs.tracer = newDrawing("Line", { Color=Color3.fromRGB(255,60,60), Thickness=1, Visible=false })

	objs.headDot = newDrawing("Circle", { Color=Color3.fromRGB(255,255,255), Thickness=1.5, Filled=false, NumSides=32, Radius=4, Visible=false })
	objs.headDotFill = newDrawing("Circle", { Color=Color3.fromRGB(255,60,60), Transparency=0.5, Filled=true, NumSides=32, Radius=4, Visible=false })

	objs.skeleton = {}
	for _ = 1, #BONES_PAIRS do
		table.insert(objs.skeleton, newDrawing("Line", { Color=Color3.fromRGB(255,255,255), Thickness=1, Visible=false }))
	end

	ESPObjects[p] = objs
end

local function clearESP(p)
	local obj = ESPObjects[p]
	if not obj then return end
	for k, v in pairs(obj) do
		if k == "skeleton" then
			for _, line in ipairs(v) do pcall(function() line:Remove() end) end
		else
			pcall(function() v:Remove() end)
		end
	end
	ESPObjects[p] = nil
end

local function hideESP(obj)
	for k, v in pairs(obj) do
		if k == "skeleton" then
			for _, line in ipairs(v) do line.Visible = false end
		else
			pcall(function() v.Visible = false end)
		end
	end
end

local function applyChams(p)
	local char = p.Character
	if not char then return end
	ChamsObjects[p] = {}
	local color = isTeammate(p) and S.ChamsTeamColor or S.ChamsEnemyColor
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			local orig = { Material=v.Material, Color=v.Color, Transparency=v.Transparency }
			table.insert(ChamsObjects[p], { part=v, original=orig })
			v.Material     = Enum.Material.Neon
			v.Color        = color
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
		if S.ChamsEnabled and p ~= LP and isAlivePlayer(p) then
			applyChams(p)
		end
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
	task.wait(0.1)
	makeESP(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		if S.ChamsEnabled then clearChams(p); applyChams(p) end
	end)
end)

Players.PlayerRemoving:Connect(function(p)
	clearESP(p)
	clearChams(p)
end)

local fovCircle = newDrawing("Circle", { Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1.5, Filled=false, NumSides=64 })
local silentCircle = newDrawing("Circle", { Visible=false, Color=Color3.fromRGB(0,200,255), Thickness=1.5, Filled=false, NumSides=64 })
local magicCircle  = newDrawing("Circle", { Visible=false, Color=Color3.fromRGB(200,80,255), Thickness=1.5, Filled=false, NumSides=64 })

local function cornerLine(box, w, h, cLen)
	local tl = Vector2.new(box.X, box.Y)
	local tr = Vector2.new(box.X+w, box.Y)
	local bl = Vector2.new(box.X, box.Y+h)
	local br = Vector2.new(box.X+w, box.Y+h)
	return tl, tr, bl, br, cLen
end

RunService.RenderStepped:Connect(function()
	local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

	fovCircle.Position = center; fovCircle.Radius = S.AimbotFOV
	silentCircle.Position = center; silentCircle.Radius = S.SilentFOV
	magicCircle.Position  = center; magicCircle.Radius  = S.MagicFOV

	fovCircle.Visible    = S.ShowFOVCircle and S.Aimbot
	silentCircle.Visible = S.SilentAim
	magicCircle.Visible  = S.MagicBullet

	if S.Aimbot and UserInputService:IsMouseButtonPressed(S.AimbotKey) then
		local target = getClosestTarget(S.AimbotFOV, S.AimbotBone, S.AimbotTeamCheck)
		if target then
			local bone = getBone(target, S.AimbotBone)
			if bone then
				local _, onScreen = getScreenPos(bone.Position)
				if onScreen then
					Camera.CFrame = Camera.CFrame:Lerp(
						CFrame.new(Camera.CFrame.Position, bone.Position), S.AimbotSmooth
					)
				end
			end
		end
	end

	if S.HitBoxEnabled then
		for _, p in ipairs(Players:GetPlayers()) do
			local valid = S.HitBoxTeamCheck and isEnemy(p) or (not S.HitBoxTeamCheck and p ~= LP and isAlivePlayer(p))
			if valid and p.Character then
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
				if v:IsA("IntValue") and (v.Name:lower():find("ammo") or v.Name:lower():find("bullets")) then
					pcall(function() if v.Value < 100 then v.Value = 9999 end end)
				end
			end
		end
	end

	if S.NoSpread then
		local char = LP.Character
		if char then
			for _, tool in ipairs(char:GetChildren()) do
				if tool:IsA("Tool") then
					pcall(function()
						local spread = tool:FindFirstChild("Spread") or tool:FindFirstChild("spread")
						if spread then spread.Value = 0 end
					end)
				end
			end
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p == LP then continue end
		local obj = ESPObjects[p]
		if not obj then continue end

		local teammate = isTeammate(p)
		local showThis = S.ESP and (
			(teammate and S.ESPTeammates) or
			(not teammate and S.ESPEnemies)
		)

		local root = getRoot(p)
		local hum  = getHum(p)
		local char = p.Character

		if not showThis or not root or not hum or not char or not isAlivePlayer(p) then
			hideESP(obj)
			continue
		end

		local dist = (Camera.CFrame.Position - root.Position).Magnitude
		if dist > S.ESPMaxDist then hideESP(obj); continue end

		local rootSP, onScreen = getScreenPos(root.Position)
		if not onScreen then hideESP(obj); continue end

		local headPart = char:FindFirstChild("Head")
		if not headPart then hideESP(obj); continue end

		local teamColor  = S.ESPTeamColor
		local enemyColor = S.ESPEnemyColor
		local mainColor  = teammate and teamColor or enemyColor

		local topSP    = getScreenPos(headPart.Position + Vector3.new(0,0.7,0))
		local bottomSP = getScreenPos(root.Position    - Vector3.new(0,2.8,0))

		local height = math.abs(topSP.Y - bottomSP.Y)
		local width  = height * 0.55
		local left   = rootSP.X - width/2
		local top    = topSP.Y

		local hp = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
		local hpColor = Color3.fromHSV(hp * 0.33, 1, 1)

		if S.ESPBoxes then
			obj.boxFill.Position = Vector2.new(left, top)
			obj.boxFill.Size     = Vector2.new(width, height)
			obj.boxFill.Color    = mainColor
			obj.boxFill.Visible  = true

			obj.box.Position = Vector2.new(left, top)
			obj.box.Size     = Vector2.new(width, height)
			obj.box.Color    = mainColor
			obj.box.Visible  = true

			local cLen = math.min(width, height) * 0.25
			local thick = 2.5

			local corners = {
				{Vector2.new(left, top),           Vector2.new(left+cLen, top),       Vector2.new(left, top+cLen)},
				{Vector2.new(left+width, top),     Vector2.new(left+width-cLen, top), Vector2.new(left+width, top+cLen)},
				{Vector2.new(left, top+height),    Vector2.new(left+cLen, top+height),Vector2.new(left, top+height-cLen)},
				{Vector2.new(left+width,top+height),Vector2.new(left+width-cLen,top+height),Vector2.new(left+width,top+height-cLen)},
			}

			local cObjs = {obj.boxCorner1, obj.boxCorner2, obj.boxCorner3, obj.boxCorner4}
			for idx, c in ipairs(corners) do
				cObjs[idx].Color    = Color3.fromRGB(255,255,255)
				cObjs[idx].Visible  = true
				cObjs[idx].Size     = Vector2.new(cLen, thick)
				cObjs[idx].Position = c[2] - Vector2.new(0, thick/2)
			end
		else
			obj.box.Visible=false; obj.boxFill.Visible=false
			obj.boxCorner1.Visible=false; obj.boxCorner2.Visible=false
			obj.boxCorner3.Visible=false; obj.boxCorner4.Visible=false
		end

		if S.ESPHealth then
			local barW   = 4
			local barH   = height
			local filledH = barH * hp
			obj.healthOutline.Position = Vector2.new(left - barW - 3, top)
			obj.healthOutline.Size     = Vector2.new(barW, barH)
			obj.healthOutline.Visible  = true
			obj.healthBg.Position  = Vector2.new(left - barW - 3, top)
			obj.healthBg.Size      = Vector2.new(barW, barH)
			obj.healthBg.Visible   = true
			obj.healthBar.Position = Vector2.new(left - barW - 3, top + barH - filledH)
			obj.healthBar.Size     = Vector2.new(barW, filledH)
			obj.healthBar.Color    = hpColor
			obj.healthBar.Visible  = true
			obj.healthLabel.Text     = math.floor(hum.Health)
			obj.healthLabel.Position = Vector2.new(left - barW - 3 + barW/2, top + barH + 2)
			obj.healthLabel.Visible  = true
		else
			obj.healthBg.Visible=false; obj.healthBar.Visible=false
			obj.healthOutline.Visible=false; obj.healthLabel.Visible=false
		end

		if S.ESPNames then
			local tag = teammate and "[TEAM] " or "[ENEMY] "
			obj.nameLabel.Text     = tag .. p.DisplayName
			obj.nameLabel.Color    = mainColor
			obj.nameLabel.Position = Vector2.new(rootSP.X, top - 17)
			obj.nameLabel.Visible  = true
		else
			obj.nameLabel.Visible = false
		end

		if S.ESPDistance then
			obj.distLabel.Text     = math.floor(dist) .. "m"
			obj.distLabel.Color    = Color3.fromRGB(180,180,180)
			obj.distLabel.Position = Vector2.new(rootSP.X, top + height + 3)
			obj.distLabel.Visible  = true
		else
			obj.distLabel.Visible = false
		end

		if S.ESPTracers then
			obj.tracer.From    = Vector2.new(center.X, Camera.ViewportSize.Y)
			obj.tracer.To      = rootSP
			obj.tracer.Color   = mainColor
			obj.tracer.Visible = true
		else
			obj.tracer.Visible = false
		end

		if S.ESPHeadDot then
			local headSP = getScreenPos(headPart.Position)
			obj.headDot.Position     = headSP
			obj.headDot.Color        = mainColor
			obj.headDot.Visible      = true
			obj.headDotFill.Position = headSP
			obj.headDotFill.Color    = mainColor
			obj.headDotFill.Visible  = true
		else
			obj.headDot.Visible=false; obj.headDotFill.Visible=false
		end

		if S.ESPSkeleton then
			for idx, pair in ipairs(BONES_PAIRS) do
				local b1 = char:FindFirstChild(pair[1])
				local b2 = char:FindFirstChild(pair[2])
				local line = obj.skeleton[idx]
				if b1 and b2 then
					local s1 = getScreenPos(b1.Position)
					local s2 = getScreenPos(b2.Position)
					line.From    = s1
					line.To      = s2
					line.Color   = mainColor
					line.Visible = true
				else
					line.Visible = false
				end
			end
		else
			for _, line in ipairs(obj.skeleton) do line.Visible = false end
		end
	end
end)

local Window = Rayfield:CreateWindow({
	Name            = "Astra Hub",
	Icon            = 0,
	LoadingTitle    = "Astra Hub",
	LoadingSubtitle = "Loading modules...",
	Theme           = "Default",
	ConfigurationSaving = { Enabled=true, FileName="AstraHub" },
	KeySystem       = false,
})

local AimTab = Window:CreateTab("Aimbot", 4483362458)
AimTab:CreateSection("Aimbot")
AimTab:CreateToggle({ Name="Enable Aimbot", CurrentValue=false, Flag="Aimbot",
	Callback=function(v) S.Aimbot=v; if v then S.SilentAim=false; S.MagicBullet=false end end,
})
AimTab:CreateToggle({ Name="Enemy Only (Team Check)", CurrentValue=true, Flag="AimbotTeamCheck",
	Callback=function(v) S.AimbotTeamCheck=v end,
})
AimTab:CreateToggle({ Name="Show FOV Circle", CurrentValue=true, Flag="ShowFOVCircle",
	Callback=function(v) S.ShowFOVCircle=v end,
})
AimTab:CreateSlider({ Name="FOV Radius", Range={10,500}, Increment=1, CurrentValue=120, Flag="AimbotFOV",
	Callback=function(v) S.AimbotFOV=v end,
})
AimTab:CreateSlider({ Name="Smoothness (lower = snappier)", Range={1,100}, Increment=1, CurrentValue=15, Flag="AimbotSmooth",
	Callback=function(v) S.AimbotSmooth=v/100 end,
})
AimTab:CreateDropdown({ Name="Target Bone", Options={"Head","HumanoidRootPart","UpperTorso","LowerTorso"},
	CurrentOption={"Head"}, Flag="AimbotBone",
	Callback=function(v) S.AimbotBone=v[1] end,
})
AimTab:CreateSection("Silent Aim")
AimTab:CreateToggle({ Name="Enable Silent Aim", CurrentValue=false, Flag="SilentAim",
	Callback=function(v) S.SilentAim=v; if v then S.Aimbot=false; S.MagicBullet=false end end,
})
AimTab:CreateToggle({ Name="Enemy Only (Team Check)", CurrentValue=true, Flag="SilentTeamCheck",
	Callback=function(v) S.SilentTeamCheck=v end,
})
AimTab:CreateSlider({ Name="Silent Aim FOV", Range={10,600}, Increment=1, CurrentValue=150, Flag="SilentFOV",
	Callback=function(v) S.SilentFOV=v end,
})
AimTab:CreateSection("Magic Bullet")
AimTab:CreateToggle({ Name="Enable Magic Bullet", CurrentValue=false, Flag="MagicBullet",
	Callback=function(v) S.MagicBullet=v; if v then S.Aimbot=false; S.SilentAim=false end end,
})
AimTab:CreateToggle({ Name="Enemy Only (Team Check)", CurrentValue=true, Flag="MagicTeamCheck",
	Callback=function(v) S.MagicTeamCheck=v end,
})
AimTab:CreateSlider({ Name="Magic Bullet FOV", Range={10,800}, Increment=1, CurrentValue=200, Flag="MagicFOV",
	Callback=function(v) S.MagicFOV=v end,
})
AimTab:CreateDropdown({ Name="Magic Bone", Options={"HumanoidRootPart","Head","UpperTorso"},
	CurrentOption={"HumanoidRootPart"}, Flag="MagicBone",
	Callback=function(v) S.MagicBone=v[1] end,
})

local ESPTab = Window:CreateTab("ESP", 4483362458)
ESPTab:CreateSection("ESP Targets")
ESPTab:CreateToggle({ Name="Enable ESP", CurrentValue=false, Flag="ESP",
	Callback=function(v) S.ESP=v end,
})
ESPTab:CreateToggle({ Name="Show Enemies", CurrentValue=true, Flag="ESPEnemies",
	Callback=function(v) S.ESPEnemies=v end,
})
ESPTab:CreateToggle({ Name="Show Teammates", CurrentValue=true, Flag="ESPTeammates",
	Callback=function(v) S.ESPTeammates=v end,
})
ESPTab:CreateSection("ESP Elements")
ESPTab:CreateToggle({ Name="Boxes", CurrentValue=true, Flag="ESPBoxes",
	Callback=function(v) S.ESPBoxes=v end,
})
ESPTab:CreateToggle({ Name="Names + Team Tag", CurrentValue=true, Flag="ESPNames",
	Callback=function(v) S.ESPNames=v end,
})
ESPTab:CreateToggle({ Name="Health Bar", CurrentValue=true, Flag="ESPHealth",
	Callback=function(v) S.ESPHealth=v end,
})
ESPTab:CreateToggle({ Name="Distance", CurrentValue=true, Flag="ESPDistance",
	Callback=function(v) S.ESPDistance=v end,
})
ESPTab:CreateToggle({ Name="Tracers", CurrentValue=false, Flag="ESPTracers",
	Callback=function(v) S.ESPTracers=v end,
})
ESPTab:CreateToggle({ Name="Skeleton", CurrentValue=false, Flag="ESPSkeleton",
	Callback=function(v) S.ESPSkeleton=v end,
})
ESPTab:CreateToggle({ Name="Head Dot", CurrentValue=true, Flag="ESPHeadDot",
	Callback=function(v) S.ESPHeadDot=v end,
})
ESPTab:CreateSlider({ Name="Max Distance (studs)", Range={100,2000}, Increment=50, CurrentValue=1000, Flag="ESPMaxDist",
	Callback=function(v) S.ESPMaxDist=v end,
})

local CombatTab = Window:CreateTab("Combat", 4483362458)
CombatTab:CreateSection("HitBox Expander")
CombatTab:CreateToggle({ Name="HitBox Expander", CurrentValue=false, Flag="HitBox",
	Callback=function(v) S.HitBoxEnabled=v end,
})
CombatTab:CreateToggle({ Name="Enemies Only", CurrentValue=true, Flag="HitBoxTeamCheck",
	Callback=function(v) S.HitBoxTeamCheck=v end,
})
CombatTab:CreateSlider({ Name="HitBox Size", Range={1,20}, Increment=0.5, CurrentValue=5, Flag="HitBoxSize",
	Callback=function(v) S.HitBoxSize=v end,
})
CombatTab:CreateSection("Fire Rate")
CombatTab:CreateToggle({ Name="Fast Fire Rate", CurrentValue=false, Flag="FireRate",
	Callback=function(v)
		S.FireRate=v
		if v then
			local char = LP.Character
			if char then
				for _, v2 in ipairs(char:GetDescendants()) do
					pcall(function()
						if v2:IsA("NumberValue") and (v2.Name:lower():find("fire") or v2.Name:lower():find("rate") or v2.Name:lower():find("delay")) then
							v2.Value = S.FireRateVal
						end
					end)
				end
			end
		end
	end,
})
CombatTab:CreateSlider({ Name="Fire Delay (lower = faster)", Range={1,100}, Increment=1, CurrentValue=5, Flag="FireRateVal",
	Callback=function(v) S.FireRateVal=v/100 end,
})
CombatTab:CreateSection("Misc")
CombatTab:CreateToggle({ Name="Infinite Ammo", CurrentValue=false, Flag="InfAmmo",
	Callback=function(v) S.InfAmmo=v end,
})
CombatTab:CreateToggle({ Name="No Spread", CurrentValue=false, Flag="NoSpread",
	Callback=function(v) S.NoSpread=v end,
})

local ChamsTab = Window:CreateTab("Chams", 4483362458)
ChamsTab:CreateSection("Chams")
ChamsTab:CreateToggle({ Name="Enable Chams", CurrentValue=false, Flag="Chams",
	Callback=function(v) S.ChamsEnabled=v; refreshChams() end,
})
ChamsTab:CreateSlider({ Name="Transparency", Range={0,90}, Increment=5, CurrentValue=40, Flag="ChamsTransp",
	Callback=function(v) S.ChamsTransp=v/100; if S.ChamsEnabled then refreshChams() end end,
})
ChamsTab:CreateSection("Enemy Color")
local enemyColors = { Red={255,50,50}, Orange={255,140,0}, Yellow={255,220,0}, Pink={255,80,200}, White={255,255,255} }
for name, rgb in pairs(enemyColors) do
	ChamsTab:CreateButton({ Name="Enemy: "..name, Callback=function()
		S.ChamsEnemyColor=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
		if S.ChamsEnabled then refreshChams() end
	end })
end
ChamsTab:CreateSection("Teammate Color")
local teamColors = { Blue={50,100,255}, Cyan={0,200,255}, Green={50,220,100}, Purple={160,50,255} }
for name, rgb in pairs(teamColors) do
	ChamsTab:CreateButton({ Name="Team: "..name, Callback=function()
		S.ChamsTeamColor=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
		if S.ChamsEnabled then refreshChams() end
	end })
end
ChamsTab:CreateButton({ Name="Refresh Chams", Callback=function()
	if S.ChamsEnabled then refreshChams() end
	Rayfield:Notify({ Title="Astra Hub", Content="Chams refreshed", Duration=2 })
end })

local SettingsTab = Window:CreateTab("Settings", 4483362458)
SettingsTab:CreateSection("Anti-Cheat Status")
SettingsTab:CreateParagraph({
	Title   = "Anti-Ban / Anti-Kick",
	Content = antiBanOk and "Active — :Kick() is blocked" or "Not supported on this executor",
})
SettingsTab:CreateSection("Actions")
SettingsTab:CreateButton({ Name="Disable ALL", Callback=function()
	S.Aimbot=false; S.SilentAim=false; S.MagicBullet=false
	S.ESP=false; S.HitBoxEnabled=false; S.ChamsEnabled=false
	S.FireRate=false; S.InfAmmo=false; S.NoSpread=false
	refreshChams()
	Rayfield:Notify({ Title="Astra Hub", Content="All disabled", Duration=3 })
end })
SettingsTab:CreateButton({ Name="Destroy Script", Callback=function()
	for _, d in pairs({fovCircle, silentCircle, magicCircle}) do pcall(function() d:Remove() end) end
	for _, p in ipairs(Players:GetPlayers()) do clearESP(p); clearChams(p) end
	pcall(function() Rayfield:Destroy() end)
end })

Rayfield:Notify({
	Title   = "Astra Hub",
	Content = "Loaded! Hold RMB to aim",
	Duration = 5,
})
