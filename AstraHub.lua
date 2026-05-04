-- // Astra Hub v4 | PC + Mobile | No Anti-Ban/Kick
-- // Improved: Aimbot, ESP, Silent Aim, Magic Bullet, Chams, HitBox

local ok_rf, Rayfield = pcall(function()
	return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok_rf then warn("[AstraHub] Rayfield failed") return end

-- ─── Services ────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer

-- ─── Device detection ────────────────────────────────────────────
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ─── State ───────────────────────────────────────────────────────
local S = {
	-- Aimbot
	Aimbot          = false,
	AimbotFOV       = 120,
	AimbotSmooth    = 0.12,
	AimbotBone      = "Head",
	AimbotTeamCheck = true,
	ShowFOVCircle   = true,
	AimbotPrediction= false,
	AimbotPredMult  = 0.08,

	-- Silent Aim
	SilentAim       = false,
	SilentFOV       = 150,
	SilentTeamCheck = true,
	SilentBone      = "Head",

	-- Magic Bullet
	MagicBullet     = false,
	MagicFOV        = 250,
	MagicBone       = "HumanoidRootPart",
	MagicTeamCheck  = true,

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
	HitBoxBone      = "Head",

	-- Chams
	ChamsEnabled    = false,
	ChamsEnemyColor = Color3.fromRGB(255, 50, 50),
	ChamsTeamColor  = Color3.fromRGB(50, 120, 255),
	ChamsTransp     = 0.4,
	ChamsWallCheck  = false,

	-- Combat
	FireRate        = false,
	FireRateVal     = 0.05,
	InfAmmo         = false,
	NoSpread        = false,

	-- Mobile touch aim active
	_touchAiming    = false,
}

-- ─── Helpers ─────────────────────────────────────────────────────
local function isTeammate(p)
	if p == LP then return true end
	local myTeam = LP.Team
	return myTeam and p.Team and p.Team == myTeam
end

local function isEnemy(p)
	if p == LP then return false end
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	return not isTeammate(p)
end

local function isAlive(p)
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

local function getRoot(p)  return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
local function getHum(p)   return p.Character and p.Character:FindFirstChildOfClass("Humanoid") end

local function getBone(p, bone)
	local c = p.Character
	if not c then return nil end
	return c:FindFirstChild(bone) or c:FindFirstChild("HumanoidRootPart")
end

local function toScreen(worldPos)
	local pos, onScreen = Camera:WorldToViewportPoint(worldPos)
	return Vector2.new(pos.X, pos.Y), onScreen, pos.Z
end

local function screenCenter()
	return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function getVelocity(p)
	local root = getRoot(p)
	if root then return root.AssemblyLinearVelocity end
	return Vector3.zero
end

local function getClosestTarget(fov, bone, teamCheck)
	local center  = screenCenter()
	local closest, bestDist = nil, fov
	for _, p in ipairs(Players:GetPlayers()) do
		local valid = teamCheck and isEnemy(p) or (not teamCheck and p ~= LP and isAlive(p))
		if valid then
			local part = getBone(p, bone)
			if part then
				local sp, onScreen = toScreen(part.Position)
				if onScreen then
					local d = (sp - center).Magnitude
					if d < bestDist then
						bestDist = d
						closest  = p
					end
				end
			end
		end
	end
	return closest
end

-- ─── BAC Alpha-3B / Anti-Kick protection ─────────────────────────
local BAC_KEYWORDS = {
	"bac","alpha","anticheat","anti_cheat","banned",
	"ban","punish","flag","suspend","blacklist",
}
local function isBacRemote(name)
	local low = name:lower()
	for _, kw in ipairs(BAC_KEYWORDS) do
		if low:find(kw, 1, true) then return true end
	end
	return false
end
pcall(function()
	for _, d in pairs(game:GetDescendants()) do
		pcall(function()
			if d:IsA("RemoteEvent") and isBacRemote(d.Name) then
				d.OnClientEvent:Connect(function()
					warn("[AstraHub] BAC OnClientEvent blocked: " .. d.Name)
				end)
			end
		end)
	end
end)
game.DescendantAdded:Connect(function(d)
	task.wait(0.05)
	pcall(function()
		if d:IsA("RemoteEvent") and isBacRemote(d.Name) then
			d.OnClientEvent:Connect(function()
				warn("[AstraHub] BAC OnClientEvent blocked (new): " .. d.Name)
			end)
		end
	end)
end)
pcall(function()
	LP.Kick = function() warn("[AstraHub] LP.Kick fallback blocked") end
end)

-- ─── Namecall hook: Anti-Kick + BAC + Silent Aim + Magic Bullet ──
local _hookOk = pcall(function()
	local mt    = getrawmetatable(game)
	local oldNC = mt.__namecall
	setreadonly(mt, false)
	mt.__namecall = newcclosure(function(self, ...)
		local method = getnamecallmethod()

		-- Block :Kick()
		if method == "Kick" and typeof(self) == "Instance" and self:IsA("Player") then
			warn("[AstraHub] :Kick() blocked")
			return
		end

		-- Block BAC FireServer/InvokeServer
		if (method == "FireServer" or method == "InvokeServer")
			and typeof(self) == "Instance"
			and isBacRemote(self.Name) then
			warn("[AstraHub] BAC FireServer blocked: " .. self.Name)
			return
		end

		-- Silent Aim + Magic Bullet
		if (method == "FireServer" or method == "InvokeServer")
			and (S.SilentAim or S.MagicBullet) then

			local args = {...}

			if S.SilentAim then
				local target = getClosestTarget(S.SilentFOV, S.SilentBone, S.SilentTeamCheck)
				if target then
					local bone = getBone(target, S.SilentBone)
					if bone then
						local predicted = bone.Position
						if S.AimbotPrediction then
							predicted = predicted + getVelocity(target) * S.AimbotPredMult
						end
						for i, v in ipairs(args) do
							if typeof(v) == "Instance" and v:IsA("BasePart") then
								args[i] = bone
							elseif typeof(v) == "CFrame" then
								args[i] = CFrame.new(predicted)
							elseif typeof(v) == "Vector3" then
								args[i] = predicted
							end
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

			return oldNC(self, table.unpack(args))
		end

		return oldNC(self, ...)
	end)
	setreadonly(mt, true)
end)
if not _hookOk then
	warn("[AstraHub] Namecall hook failed — executor may not support it")
end


-- ─── Mobile touch aim trigger ────────────────────────────────────
if IS_MOBILE then
	UserInputService.TouchStarted:Connect(function(touch, gp)
		if gp then return end
		-- два пальца одновременно = прицеливание
		local touches = UserInputService:GetTouchState()
		if #touches >= 2 then S._touchAiming = true end
	end)
	UserInputService.TouchEnded:Connect(function()
		local touches = UserInputService:GetTouchState()
		if #touches < 2 then S._touchAiming = false end
	end)
end

-- ─── Drawing helper ──────────────────────────────────────────────
local function D(t, props)
	local d = Drawing.new(t)
	for k, v in pairs(props) do d[k] = v end
	return d
end

-- ─── ESP ─────────────────────────────────────────────────────────
local BONES_PAIRS = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
}

local ESPPool   = {}
local ChamsPool = {}

local function makeESP(p)
	if ESPPool[p] then return end
	local o = {}

	o.boxFill     = D("Square",{ Filled=true,  Color=Color3.fromRGB(255,60,60), Transparency=0.75, Visible=false, Thickness=0 })
	o.box         = D("Square",{ Filled=false, Color=Color3.fromRGB(255,60,60), Thickness=1.2,    Visible=false })

	o.corner = {}
	for i = 1, 8 do
		o.corner[i] = D("Line", { Color=Color3.fromRGB(255,255,255), Thickness=2, Visible=false })
	end

	o.healthBg      = D("Square",{ Filled=true,  Color=Color3.fromRGB(20,20,20),  Visible=false, Thickness=0 })
	o.healthFill    = D("Square",{ Filled=true,  Color=Color3.fromRGB(60,220,60), Visible=false, Thickness=0 })
	o.healthOutline = D("Square",{ Filled=false, Color=Color3.fromRGB(0,0,0),     Visible=false, Thickness=1 })
	o.healthText    = D("Text",  { Color=Color3.fromRGB(255,255,255), Size=10, Outline=true,
	                               OutlineColor=Color3.fromRGB(0,0,0), Visible=false, Center=true, Font=Drawing.Fonts.UI })

	o.nameLabel  = D("Text",{ Color=Color3.fromRGB(255,255,255), Size=13, Outline=true,
	                          OutlineColor=Color3.fromRGB(0,0,0), Visible=false, Center=true, Font=Drawing.Fonts.UI })
	o.distLabel  = D("Text",{ Color=Color3.fromRGB(180,180,180), Size=11, Outline=true,
	                          OutlineColor=Color3.fromRGB(0,0,0), Visible=false, Center=true, Font=Drawing.Fonts.UI })
	o.tracer     = D("Line",{ Color=Color3.fromRGB(255,60,60), Thickness=1, Visible=false })
	o.headDot    = D("Circle",{ Color=Color3.fromRGB(255,255,255), Thickness=1.5, Filled=false, NumSides=32, Radius=4, Visible=false })
	o.headDotFill= D("Circle",{ Color=Color3.fromRGB(255,60,60),  Transparency=0.4, Filled=true,  NumSides=32, Radius=4, Visible=false })

	o.skeleton = {}
	for _ = 1, #BONES_PAIRS do
		table.insert(o.skeleton, D("Line",{ Color=Color3.fromRGB(255,255,255), Thickness=1, Visible=false }))
	end

	ESPPool[p] = o
end

local function hideESP(o)
	for k, v in pairs(o) do
		if k == "skeleton" or k == "corner" then
			for _, line in ipairs(v) do pcall(function() line.Visible = false end) end
		else
			pcall(function() v.Visible = false end)
		end
	end
end

local function clearESP(p)
	local o = ESPPool[p]
	if not o then return end
	for k, v in pairs(o) do
		if k == "skeleton" or k == "corner" then
			for _, d in ipairs(v) do pcall(function() d:Remove() end) end
		else
			pcall(function() v:Remove() end)
		end
	end
	ESPPool[p] = nil
end

local function applyChams(p)
	local char = p.Character
	if not char then return end
	clearChams(p)
	ChamsPool[p] = {}
	local color = isTeammate(p) and S.ChamsTeamColor or S.ChamsEnemyColor
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			local orig = { Material=v.Material, Color=v.Color, Transparency=v.Transparency }
			table.insert(ChamsPool[p], { part=v, orig=orig })
			pcall(function()
				v.Material     = Enum.Material.Neon
				v.Color        = color
				v.Transparency = S.ChamsTransp
				if S.ChamsWallCheck then
					v.CastShadow = false
				end
			end)
		end
	end
end

function clearChams(p)
	local list = ChamsPool[p]
	if not list then return end
	for _, info in ipairs(list) do
		pcall(function()
			info.part.Material     = info.orig.Material
			info.part.Color        = info.orig.Color
			info.part.Transparency = info.orig.Transparency
		end)
	end
	ChamsPool[p] = nil
end

local function refreshChams()
	for _, p in ipairs(Players:GetPlayers()) do
		clearChams(p)
		if S.ChamsEnabled and p ~= LP and isAlive(p) then
			applyChams(p)
		end
	end
end

-- init ESP for existing players
for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LP then
		makeESP(p)
		p.CharacterAdded:Connect(function()
			task.wait(0.5)
			if S.ChamsEnabled then applyChams(p) end
		end)
	end
end

Players.PlayerAdded:Connect(function(p)
	task.wait(0.2)
	makeESP(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		if S.ChamsEnabled then applyChams(p) end
	end)
end)

Players.PlayerRemoving:Connect(function(p)
	clearESP(p)
	clearChams(p)
end)

-- ─── FOV circles ─────────────────────────────────────────────────
local fovCircle    = D("Circle",{ Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1.5, Filled=false, NumSides=64 })
local silentCircle = D("Circle",{ Visible=false, Color=Color3.fromRGB(0,200,255),   Thickness=1.5, Filled=false, NumSides=64 })
local magicCircle  = D("Circle",{ Visible=false, Color=Color3.fromRGB(200,80,255),  Thickness=1.5, Filled=false, NumSides=64 })

-- ─── Corner box helper ───────────────────────────────────────────
local function drawCornerBox(o, left, top, w, h, color)
	local cLen = math.min(w, h) * 0.22
	local thick = 2
	local corners = {
		-- TL horizontal, TL vertical
		{ Vector2.new(left, top),          Vector2.new(left+cLen, top)       },
		{ Vector2.new(left, top),          Vector2.new(left, top+cLen)       },
		-- TR horizontal, TR vertical
		{ Vector2.new(left+w, top),        Vector2.new(left+w-cLen, top)     },
		{ Vector2.new(left+w, top),        Vector2.new(left+w, top+cLen)     },
		-- BL horizontal, BL vertical
		{ Vector2.new(left, top+h),        Vector2.new(left+cLen, top+h)     },
		{ Vector2.new(left, top+h),        Vector2.new(left, top+h-cLen)     },
		-- BR horizontal, BR vertical
		{ Vector2.new(left+w, top+h),      Vector2.new(left+w-cLen, top+h)   },
		{ Vector2.new(left+w, top+h),      Vector2.new(left+w, top+h-cLen)   },
	}
	for i, pts in ipairs(corners) do
		local line = o.corner[i]
		line.From      = pts[1]
		line.To        = pts[2]
		line.Color     = Color3.fromRGB(255,255,255)
		line.Thickness = thick
		line.Visible   = true
	end
end

-- ─── RenderStepped ───────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
	local center = screenCenter()
	local VP     = Camera.ViewportSize

	-- FOV circles
	fovCircle.Position    = center; fovCircle.Radius    = S.AimbotFOV
	silentCircle.Position = center; silentCircle.Radius = S.SilentFOV
	magicCircle.Position  = center; magicCircle.Radius  = S.MagicFOV

	fovCircle.Visible    = S.ShowFOVCircle and S.Aimbot
	silentCircle.Visible = S.SilentAim
	magicCircle.Visible  = S.MagicBullet

	-- ── Aimbot ──────────────────────────────────────────
	local aimActive = IS_MOBILE
		and S._touchAiming
		or  UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

	if S.Aimbot and aimActive then
		local target = getClosestTarget(S.AimbotFOV, S.AimbotBone, S.AimbotTeamCheck)
		if target then
			local bone = getBone(target, S.AimbotBone)
			if bone then
				local aimPos = bone.Position
				if S.AimbotPrediction then
					aimPos = aimPos + getVelocity(target) * S.AimbotPredMult
				end
				local _, onScreen = toScreen(aimPos)
				if onScreen then
					local targetCF = CFrame.new(Camera.CFrame.Position, aimPos)
					Camera.CFrame  = Camera.CFrame:Lerp(targetCF, S.AimbotSmooth)
				end
			end
		end
	end

	-- ── HitBox ──────────────────────────────────────────
	if S.HitBoxEnabled then
		for _, p in ipairs(Players:GetPlayers()) do
			local valid = S.HitBoxTeamCheck and isEnemy(p)
				or (not S.HitBoxTeamCheck and p ~= LP and isAlive(p))
			if valid and p.Character then
				local bone = p.Character:FindFirstChild(S.HitBoxBone)
					or p.Character:FindFirstChild("HumanoidRootPart")
				if bone and bone:IsA("BasePart") then
					pcall(function()
						bone.Size = Vector3.new(S.HitBoxSize, S.HitBoxSize, S.HitBoxSize)
					end)
				end
			end
		end
	end

	-- ── Infinite Ammo ───────────────────────────────────
	if S.InfAmmo then
		local char = LP.Character
		if char then
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("IntValue") and (v.Name:lower():find("ammo") or v.Name:lower():find("bullets")) then
					pcall(function() if v.Value < 200 then v.Value = 9999 end end)
				end
			end
		end
	end

	-- ── No Spread ───────────────────────────────────────
	if S.NoSpread then
		local char = LP.Character
		if char then
			for _, tool in ipairs(char:GetChildren()) do
				if tool:IsA("Tool") then
					for _, v in ipairs(tool:GetDescendants()) do
						pcall(function()
							if (v.Name:lower():find("spread") or v.Name:lower():find("recoil"))
								and (v:IsA("NumberValue") or v:IsA("FloatValue")) then
								v.Value = 0
							end
						end)
					end
				end
			end
		end
	end

	-- ── ESP render ──────────────────────────────────────
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LP then continue end
		local o = ESPPool[p]
		if not o then continue end

		local teammate = isTeammate(p)
		local showThis = S.ESP and (
			(teammate and S.ESPTeammates) or
			(not teammate and S.ESPEnemies)
		)

		local root = getRoot(p)
		local hum  = getHum(p)
		local char = p.Character

		if not showThis or not root or not hum or not char or not isAlive(p) then
			hideESP(o); continue
		end

		local dist = (Camera.CFrame.Position - root.Position).Magnitude
		if dist > S.ESPMaxDist then hideESP(o); continue end

		local rootSP, onScreen = toScreen(root.Position)
		if not onScreen then hideESP(o); continue end

		local headPart = char:FindFirstChild("Head")
		if not headPart then hideESP(o); continue end

		local mainColor = teammate and S.ESPTeamColor or S.ESPEnemyColor

		local topSP    = toScreen(headPart.Position + Vector3.new(0, 0.75, 0))
		local bottomSP = toScreen(root.Position - Vector3.new(0, 3.0, 0))

		local height = math.abs(topSP.Y - bottomSP.Y)
		local width  = height * 0.55
		local left   = rootSP.X - width / 2
		local top    = topSP.Y

		local hp      = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		local hpColor = Color3.fromHSV(hp * 0.33, 1, 1)

		-- Box + corners
		if S.ESPBoxes then
			o.boxFill.Position = Vector2.new(left, top)
			o.boxFill.Size     = Vector2.new(width, height)
			o.boxFill.Color    = mainColor
			o.boxFill.Visible  = true

			o.box.Position = Vector2.new(left, top)
			o.box.Size     = Vector2.new(width, height)
			o.box.Color    = mainColor
			o.box.Visible  = true

			drawCornerBox(o, left, top, width, height, mainColor)
		else
			o.box.Visible = false; o.boxFill.Visible = false
			for _, line in ipairs(o.corner) do line.Visible = false end
		end

		-- Health bar (left side, vertical)
		if S.ESPHealth then
			local bW     = 4
			local bH     = height
			local fillH  = bH * hp
			local bx     = left - bW - 3

			o.healthOutline.Position = Vector2.new(bx, top)
			o.healthOutline.Size     = Vector2.new(bW, bH)
			o.healthOutline.Visible  = true

			o.healthBg.Position = Vector2.new(bx, top)
			o.healthBg.Size     = Vector2.new(bW, bH)
			o.healthBg.Visible  = true

			o.healthFill.Position = Vector2.new(bx, top + bH - fillH)
			o.healthFill.Size     = Vector2.new(bW, fillH)
			o.healthFill.Color    = hpColor
			o.healthFill.Visible  = true

			o.healthText.Text     = math.floor(hum.Health)
			o.healthText.Position = Vector2.new(bx + bW/2, top + bH + 2)
			o.healthText.Visible  = true
		else
			o.healthBg.Visible=false; o.healthFill.Visible=false
			o.healthOutline.Visible=false; o.healthText.Visible=false
		end

		-- Name
		if S.ESPNames then
			local tag = teammate and "[TEAM] " or "[ENEMY] "
			o.nameLabel.Text     = tag .. p.DisplayName
			o.nameLabel.Color    = mainColor
			o.nameLabel.Position = Vector2.new(rootSP.X, top - 17)
			o.nameLabel.Visible  = true
		else
			o.nameLabel.Visible = false
		end

		-- Distance
		if S.ESPDistance then
			o.distLabel.Text     = string.format("%.0fm", dist)
			o.distLabel.Color    = Color3.fromRGB(170,170,170)
			o.distLabel.Position = Vector2.new(rootSP.X, top + height + 3)
			o.distLabel.Visible  = true
		else
			o.distLabel.Visible = false
		end

		-- Tracer
		if S.ESPTracers then
			o.tracer.From    = Vector2.new(center.X, VP.Y)
			o.tracer.To      = rootSP
			o.tracer.Color   = mainColor
			o.tracer.Visible = true
		else
			o.tracer.Visible = false
		end

		-- Head dot
		if S.ESPHeadDot then
			local headSP = toScreen(headPart.Position)
			o.headDot.Position     = headSP
			o.headDot.Color        = mainColor
			o.headDot.Visible      = true
			o.headDotFill.Position = headSP
			o.headDotFill.Color    = mainColor
			o.headDotFill.Visible  = true
		else
			o.headDot.Visible=false; o.headDotFill.Visible=false
		end

		-- Skeleton
		if S.ESPSkeleton then
			for idx, pair in ipairs(BONES_PAIRS) do
				local b1 = char:FindFirstChild(pair[1])
				local b2 = char:FindFirstChild(pair[2])
				local line = o.skeleton[idx]
				if b1 and b2 then
					line.From    = toScreen(b1.Position)
					line.To      = toScreen(b2.Position)
					line.Color   = mainColor
					line.Visible = true
				else
					line.Visible = false
				end
			end
		else
			for _, line in ipairs(o.skeleton) do line.Visible = false end
		end
	end
end)

-- ─── Rayfield UI ─────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
	Name            = "Astra Hub",
	Icon            = 0,
	LoadingTitle    = "Astra Hub",
	LoadingSubtitle = "v4 | " .. (IS_MOBILE and "Mobile" or "PC"),
	Theme           = "Default",
	ConfigurationSaving = { Enabled=true, FileName="AstraHub_v4" },
	KeySystem       = false,
})

-- ═══ TAB: AIMBOT ════════════════════════════════════════════════
local AimTab = Window:CreateTab("Aimbot", 4483362458)

AimTab:CreateSection("Aimbot")
AimTab:CreateToggle({ Name="Enable Aimbot", CurrentValue=false, Flag="Aimbot",
	Callback=function(v) S.Aimbot=v; if v then S.SilentAim=false; S.MagicBullet=false end end })
AimTab:CreateToggle({ Name="Enemy Only (Team Check)", CurrentValue=true, Flag="AimbotTeamCheck",
	Callback=function(v) S.AimbotTeamCheck=v end })
AimTab:CreateToggle({ Name="Show FOV Circle", CurrentValue=true, Flag="ShowFOVCircle",
	Callback=function(v) S.ShowFOVCircle=v end })
AimTab:CreateToggle({ Name="Prediction (moving targets)", CurrentValue=false, Flag="AimbotPred",
	Callback=function(v) S.AimbotPrediction=v end })
AimTab:CreateSlider({ Name="FOV Radius", Range={10,500}, Increment=5, CurrentValue=120, Flag="AimbotFOV",
	Callback=function(v) S.AimbotFOV=v end })
AimTab:CreateSlider({ Name="Smoothness (lower = snappier)", Range={1,100}, Increment=1, CurrentValue=12, Flag="AimbotSmooth",
	Callback=function(v) S.AimbotSmooth=v/100 end })
AimTab:CreateSlider({ Name="Prediction Multiplier", Range={1,30}, Increment=1, CurrentValue=8, Flag="AimbotPredMult",
	Callback=function(v) S.AimbotPredMult=v/100 end })
AimTab:CreateDropdown({ Name="Target Bone", Options={"Head","HumanoidRootPart","UpperTorso","LowerTorso"},
	CurrentOption={"Head"}, Flag="AimbotBone",
	Callback=function(v) S.AimbotBone=v[1] end })

if IS_MOBILE then
	AimTab:CreateParagraph({ Title="Mobile Aim", Content="Hold 2 fingers to activate aimbot on mobile." })
end

AimTab:CreateSection("Silent Aim")
AimTab:CreateToggle({ Name="Enable Silent Aim", CurrentValue=false, Flag="SilentAim",
	Callback=function(v) S.SilentAim=v; if v then S.Aimbot=false; S.MagicBullet=false end end })
AimTab:CreateToggle({ Name="Enemy Only (Team Check)", CurrentValue=true, Flag="SilentTeamCheck",
	Callback=function(v) S.SilentTeamCheck=v end })
AimTab:CreateSlider({ Name="Silent FOV", Range={10,600}, Increment=5, CurrentValue=150, Flag="SilentFOV",
	Callback=function(v) S.SilentFOV=v end })
AimTab:CreateDropdown({ Name="Silent Target Bone", Options={"Head","HumanoidRootPart","UpperTorso"},
	CurrentOption={"Head"}, Flag="SilentBone",
	Callback=function(v) S.SilentBone=v[1] end })

AimTab:CreateSection("Magic Bullet")
AimTab:CreateToggle({ Name="Enable Magic Bullet", CurrentValue=false, Flag="MagicBullet",
	Callback=function(v) S.MagicBullet=v; if v then S.Aimbot=false; S.SilentAim=false end end })
AimTab:CreateToggle({ Name="Enemy Only (Team Check)", CurrentValue=true, Flag="MagicTeamCheck",
	Callback=function(v) S.MagicTeamCheck=v end })
AimTab:CreateSlider({ Name="Magic Bullet FOV", Range={10,800}, Increment=10, CurrentValue=250, Flag="MagicFOV",
	Callback=function(v) S.MagicFOV=v end })
AimTab:CreateDropdown({ Name="Magic Bone", Options={"HumanoidRootPart","Head","UpperTorso"},
	CurrentOption={"HumanoidRootPart"}, Flag="MagicBone",
	Callback=function(v) S.MagicBone=v[1] end })

-- ═══ TAB: ESP ════════════════════════════════════════════════════
local ESPTab = Window:CreateTab("ESP", 4483362458)

ESPTab:CreateSection("Targets")
ESPTab:CreateToggle({ Name="Enable ESP", CurrentValue=false, Flag="ESP",
	Callback=function(v) S.ESP=v end })
ESPTab:CreateToggle({ Name="Show Enemies", CurrentValue=true, Flag="ESPEnemies",
	Callback=function(v) S.ESPEnemies=v end })
ESPTab:CreateToggle({ Name="Show Teammates", CurrentValue=true, Flag="ESPTeammates",
	Callback=function(v) S.ESPTeammates=v end })

ESPTab:CreateSection("Elements")
ESPTab:CreateToggle({ Name="Box + Corners", CurrentValue=true, Flag="ESPBoxes",
	Callback=function(v) S.ESPBoxes=v end })
ESPTab:CreateToggle({ Name="Name + Team Tag", CurrentValue=true, Flag="ESPNames",
	Callback=function(v) S.ESPNames=v end })
ESPTab:CreateToggle({ Name="Health Bar", CurrentValue=true, Flag="ESPHealth",
	Callback=function(v) S.ESPHealth=v end })
ESPTab:CreateToggle({ Name="Distance", CurrentValue=true, Flag="ESPDistance",
	Callback=function(v) S.ESPDistance=v end })
ESPTab:CreateToggle({ Name="Tracers", CurrentValue=false, Flag="ESPTracers",
	Callback=function(v) S.ESPTracers=v end })
ESPTab:CreateToggle({ Name="Skeleton", CurrentValue=false, Flag="ESPSkeleton",
	Callback=function(v) S.ESPSkeleton=v end })
ESPTab:CreateToggle({ Name="Head Dot", CurrentValue=true, Flag="ESPHeadDot",
	Callback=function(v) S.ESPHeadDot=v end })
ESPTab:CreateSlider({ Name="Max Distance (studs)", Range={100,2000}, Increment=50, CurrentValue=1000, Flag="ESPMaxDist",
	Callback=function(v) S.ESPMaxDist=v end })

-- ═══ TAB: COMBAT ═════════════════════════════════════════════════
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("HitBox Expander")
CombatTab:CreateToggle({ Name="HitBox Expander", CurrentValue=false, Flag="HitBox",
	Callback=function(v) S.HitBoxEnabled=v end })
CombatTab:CreateToggle({ Name="Enemies Only", CurrentValue=true, Flag="HitBoxTeamCheck",
	Callback=function(v) S.HitBoxTeamCheck=v end })
CombatTab:CreateSlider({ Name="HitBox Size", Range={1,30}, Increment=0.5, CurrentValue=5, Flag="HitBoxSize",
	Callback=function(v) S.HitBoxSize=v end })
CombatTab:CreateDropdown({ Name="HitBox Target Bone", Options={"Head","HumanoidRootPart","UpperTorso"},
	CurrentOption={"Head"}, Flag="HitBoxBone",
	Callback=function(v) S.HitBoxBone=v[1] end })

CombatTab:CreateSection("Weapon")
CombatTab:CreateToggle({ Name="Fast Fire Rate", CurrentValue=false, Flag="FireRate",
	Callback=function(v)
		S.FireRate=v
		if v then
			local char=LP.Character
			if char then
				for _, d in ipairs(char:GetDescendants()) do
					pcall(function()
						if d:IsA("NumberValue") and
							(d.Name:lower():find("fire") or d.Name:lower():find("rate") or d.Name:lower():find("delay")) then
							d.Value = S.FireRateVal
						end
					end)
				end
			end
		end
	end })
CombatTab:CreateSlider({ Name="Fire Delay (lower = faster)", Range={1,100}, Increment=1, CurrentValue=5, Flag="FireRateSlider",
	Callback=function(v) S.FireRateVal=v/100 end })
CombatTab:CreateToggle({ Name="Infinite Ammo", CurrentValue=false, Flag="InfAmmo",
	Callback=function(v) S.InfAmmo=v end })
CombatTab:CreateToggle({ Name="No Spread / No Recoil", CurrentValue=false, Flag="NoSpread",
	Callback=function(v) S.NoSpread=v end })

-- ═══ TAB: CHAMS ══════════════════════════════════════════════════
local ChamsTab = Window:CreateTab("Chams", 4483362458)

ChamsTab:CreateSection("Chams")
ChamsTab:CreateToggle({ Name="Enable Chams", CurrentValue=false, Flag="Chams",
	Callback=function(v) S.ChamsEnabled=v; refreshChams() end })
ChamsTab:CreateToggle({ Name="Wall-through Effect", CurrentValue=false, Flag="ChamsWall",
	Callback=function(v) S.ChamsWallCheck=v; if S.ChamsEnabled then refreshChams() end end })
ChamsTab:CreateSlider({ Name="Transparency", Range={0,90}, Increment=5, CurrentValue=40, Flag="ChamsTransp",
	Callback=function(v) S.ChamsTransp=v/100; if S.ChamsEnabled then refreshChams() end end })

ChamsTab:CreateSection("Enemy Color")
local enemyColors = {
	{"Red",    255, 50,  50},  {"Orange", 255, 140, 0},
	{"Yellow", 255, 220, 0},   {"Pink",   255, 80,  200},
	{"White",  255, 255, 255},
}
for _, c in ipairs(enemyColors) do
	ChamsTab:CreateButton({ Name="Enemy: "..c[1], Callback=function()
		S.ChamsEnemyColor=Color3.fromRGB(c[2],c[3],c[4])
		if S.ChamsEnabled then refreshChams() end
	end })
end

ChamsTab:CreateSection("Teammate Color")
local teamColors = {
	{"Blue",   50,  100, 255}, {"Cyan",   0,   200, 255},
	{"Green",  50,  220, 100}, {"Purple", 160, 50,  255},
}
for _, c in ipairs(teamColors) do
	ChamsTab:CreateButton({ Name="Team: "..c[1], Callback=function()
		S.ChamsTeamColor=Color3.fromRGB(c[2],c[3],c[4])
		if S.ChamsEnabled then refreshChams() end
	end })
end

ChamsTab:CreateButton({ Name="Refresh Chams", Callback=function()
	refreshChams()
	Rayfield:Notify({ Title="Astra Hub", Content="Chams refreshed", Duration=2 })
end })

-- ═══ TAB: SETTINGS ═══════════════════════════════════════════════
local SetTab = Window:CreateTab("Settings", 4483362458)

SetTab:CreateSection("Device")
SetTab:CreateParagraph({
	Title   = IS_MOBILE and "📱 Mobile" or "🖥 PC",
	Content = IS_MOBILE
		and "Aimbot: hold 2 fingers. Rayfield: tap top icon."
		or  "Aimbot: hold RMB. Rayfield: press Insert."
})

SetTab:CreateSection("Protection")
SetTab:CreateParagraph({
	Title   = "Anti-Kick / BAC Alpha-3B",
	Content = _hookOk
		and "Active — :Kick() blocked, BAC remotes hooked, LP.Kick overridden"
		or  "Partial — LP.Kick overridden, BAC remote scan active (executor lacks full hook)",
})
SetTab:CreateSection("Actions")
SetTab:CreateButton({ Name="Disable ALL", Callback=function()
	S.Aimbot=false; S.SilentAim=false; S.MagicBullet=false
	S.ESP=false; S.HitBoxEnabled=false; S.ChamsEnabled=false
	S.FireRate=false; S.InfAmmo=false; S.NoSpread=false
	refreshChams()
	Rayfield:Notify({ Title="Astra Hub", Content="All disabled", Duration=3 })
end })

SetTab:CreateButton({ Name="Destroy Script", Callback=function()
	pcall(function() fovCircle:Remove() end)
	pcall(function() silentCircle:Remove() end)
	pcall(function() magicCircle:Remove() end)
	for _, p in ipairs(Players:GetPlayers()) do
		clearESP(p); clearChams(p)
	end
	pcall(function() Rayfield:Destroy() end)
end })

-- ─── Loaded ──────────────────────────────────────────────────────
Rayfield:Notify({
	Title   = "Astra Hub",
	Content = IS_MOBILE
		and "Loaded! Hold 2 fingers to aim."
		or  "Loaded! Hold RMB to aim.",
	Duration = 5,
})
