local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local SoundService     = game:GetService("SoundService")
local Workspace        = game:GetService("Workspace")
local LP               = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

if not LP then return end
local PlayerGui = LP:WaitForChild("PlayerGui", 10)
if not PlayerGui then return end

local isMobile   = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local SW, SH
do
	local ok, res = pcall(function() return UserInputService:GetScreenSize() end)
	if ok and res then SW, SH = res.X, res.Y
	else SW, SH = 1280, 720 end
end

local CONFIG = {
	Prompt          = "[crystal@roblox ~]$ ",
	BG              = Color3.fromRGB(8,  8,  12),
	TitleBG         = Color3.fromRGB(14, 14, 20),
	InputBG         = Color3.fromRGB(14, 14, 20),
	Border          = Color3.fromRGB(40, 40, 60),
	Text            = Color3.fromRGB(220, 220, 235),
	Muted           = Color3.fromRGB(80,  80, 110),
	Silver          = Color3.fromRGB(180, 180, 210),
	Crystal         = Color3.fromRGB(120, 180, 255),
	Success         = Color3.fromRGB(80,  220, 140),
	Error           = Color3.fromRGB(220, 80,  80),
	Warn            = Color3.fromRGB(220, 180, 60),
	Prompt_Col      = Color3.fromRGB(100, 160, 255),
	Font            = Enum.Font.Code,
	TextSize        = isMobile and 15 or 13,
	Width           = isMobile and math.floor(SW * 0.96) or 720,
	Height          = isMobile and math.floor(SH * 0.68) or 480,
	TitleH          = isMobile and 54 or 44,
	InputH          = isMobile and 50 or 40,
	BtnH            = isMobile and 38 or 26,
	isMobile        = isMobile,
	SW              = SW,
	SH              = SH,
}

local State = {
	visible   = true,
	history   = {},
	histIdx   = 0,
	dir       = "workspace",
	aliases   = {},
	env       = {},
	flyActive = false,
	flyBP     = nil,
	flyBG     = nil,
	flyConn   = nil,
}

local function safeCall(fn, ...)
	local ok, r = pcall(fn, ...)
	return ok and r or nil
end
local function getChar()   return LP and LP.Character or nil end
local function getHRP()    local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") or nil end
local function getHum()    local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") or nil end

-- =============================================
-- UI
-- =============================================
local existing = PlayerGui:FindFirstChild("CrystalTermux")
if existing then existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "CrystalTermux"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent          = PlayerGui

local Main = Instance.new("Frame", ScreenGui)
Main.Name                 = "Main"
Main.Size                 = UDim2.new(0, CONFIG.Width, 0, CONFIG.Height)
Main.AnchorPoint          = Vector2.new(0.5, 0.5)
Main.Position             = isMobile and UDim2.new(0.5,0, 0.02,0) or UDim2.new(0.5,-CONFIG.Width/2, 0.5,-CONFIG.Height/2)
Main.BackgroundColor3     = CONFIG.BG
Main.BorderSizePixel      = 0
Main.Active               = true
Main.ClipsDescendants     = true
do
	local c = Instance.new("UICorner", Main); c.CornerRadius = UDim.new(0,12)
	local s = Instance.new("UIStroke",  Main); s.Color = CONFIG.Border; s.Thickness = 1
end

-- Title Bar
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size             = UDim2.new(1, 0, 0, CONFIG.TitleH)
TitleBar.BackgroundColor3 = CONFIG.TitleBG
TitleBar.BorderSizePixel  = 0
do
	local c  = Instance.new("UICorner", TitleBar); c.CornerRadius = UDim.new(0,12)
	local fix= Instance.new("Frame", TitleBar)
	fix.Size = UDim2.new(1,0,0.5,0); fix.Position = UDim2.new(0,0,0.5,0)
	fix.BackgroundColor3 = CONFIG.TitleBG; fix.BorderSizePixel = 0
	local sep = Instance.new("Frame", TitleBar)
	sep.Size = UDim2.new(1,0,0,1); sep.Position = UDim2.new(0,0,1,-1)
	sep.BackgroundColor3 = CONFIG.Border; sep.BorderSizePixel = 0
end

-- Crystal icon + title
local TitleIcon = Instance.new("TextLabel", TitleBar)
TitleIcon.Size               = UDim2.new(0,30,1,0)
TitleIcon.Position           = UDim2.new(0,12,0,0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text               = "💎"
TitleIcon.Font               = CONFIG.Font
TitleIcon.TextSize           = 16

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size               = UDim2.new(1,-130,1,0)
TitleText.Position           = UDim2.new(0,40,0,0)
TitleText.BackgroundTransparency = 1
TitleText.Text               = LP.Name .. "@crystal — bash"
TitleText.TextColor3         = CONFIG.Muted
TitleText.Font               = CONFIG.Font
TitleText.TextSize           = 12
TitleText.TextXAlignment     = Enum.TextXAlignment.Center

-- Window buttons
local function makeBtn(x, icon, col)
	local btn = Instance.new("TextButton", TitleBar)
	btn.Size                = UDim2.new(0,CONFIG.BtnH,0,CONFIG.BtnH)
	btn.Position            = UDim2.new(0,x,0.5,-CONFIG.BtnH/2)
	btn.BackgroundColor3    = col or Color3.fromRGB(38,38,50)
	btn.Text                = icon
	btn.TextColor3          = CONFIG.Muted
	btn.Font                = CONFIG.Font
	btn.TextSize            = 14
	btn.AutoButtonColor     = false
	btn.BorderSizePixel     = 0
	local c = Instance.new("UICorner",btn); c.CornerRadius = UDim.new(0,6)
	btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(60,60,80) btn.TextColor3 = CONFIG.Text end)
	btn.MouseLeave:Connect(function() btn.BackgroundColor3 = col or Color3.fromRGB(38,38,50) btn.TextColor3 = CONFIG.Muted end)
	return btn
end

local BtnMin   = makeBtn(CONFIG.Width - CONFIG.BtnH*3 - 6, "─")
local BtnMax   = makeBtn(CONFIG.Width - CONFIG.BtnH*2 - 4, "□")
local BtnClose = makeBtn(CONFIG.Width - CONFIG.BtnH - 2, "✕", Color3.fromRGB(50,20,20))

-- Output
local Output = Instance.new("ScrollingFrame", Main)
Output.Name                  = "Output"
Output.Size                  = UDim2.new(1,-24, 1, isMobile and -148 or -92)
Output.Position              = UDim2.new(0,12, 0, CONFIG.TitleH+8)
Output.BackgroundTransparency = 1
Output.BorderSizePixel       = 0
Output.ScrollBarThickness    = 3
Output.ScrollBarImageColor3  = CONFIG.Border
Output.AutomaticCanvasSize   = Enum.AutomaticSize.Y
Output.CanvasSize            = UDim2.new(0,0,0,0)
local OLayout = Instance.new("UIListLayout", Output)
OLayout.SortOrder  = Enum.SortOrder.LayoutOrder
OLayout.Padding    = UDim.new(0,2)

-- Separator
local Sep = Instance.new("Frame", Main)
Sep.Size              = UDim2.new(1,0,0,1)
Sep.Position          = UDim2.new(0,0,1,-CONFIG.InputH)
Sep.BackgroundColor3  = CONFIG.Border
Sep.BorderSizePixel   = 0

-- Input bar
local InputBar = Instance.new("Frame", Main)
InputBar.Size             = UDim2.new(1,0,0,CONFIG.InputH)
InputBar.Position         = UDim2.new(0,0,1,-CONFIG.InputH)
InputBar.BackgroundColor3 = CONFIG.InputBG
InputBar.BorderSizePixel  = 0
do
	local c  = Instance.new("UICorner",InputBar); c.CornerRadius = UDim.new(0,12)
	local fix= Instance.new("Frame",InputBar)
	fix.Size = UDim2.new(1,0,0.5,0); fix.BackgroundColor3 = CONFIG.InputBG; fix.BorderSizePixel = 0
end

local PromptLabel = Instance.new("TextLabel", InputBar)
PromptLabel.Size              = UDim2.new(0,0,1,0)
PromptLabel.Position          = UDim2.new(0,12,0,0)
PromptLabel.AutomaticSize     = Enum.AutomaticSize.X
PromptLabel.BackgroundTransparency = 1
PromptLabel.Text              = CONFIG.Prompt
PromptLabel.TextColor3        = CONFIG.Prompt_Col
PromptLabel.Font              = CONFIG.Font
PromptLabel.TextSize          = CONFIG.TextSize
PromptLabel.TextXAlignment    = Enum.TextXAlignment.Left

local InputBox = Instance.new("TextBox", InputBar)
InputBox.Size                 = UDim2.new(1,-160,1,0)
InputBox.Position             = UDim2.new(0,150,0,0)
InputBox.BackgroundTransparency = 1
InputBox.Text                 = ""
InputBox.PlaceholderText      = "type a command... (help)"
InputBox.PlaceholderColor3    = CONFIG.Muted
InputBox.TextColor3           = CONFIG.Text
InputBox.Font                 = CONFIG.Font
InputBox.TextSize             = CONFIG.TextSize
InputBox.TextXAlignment       = Enum.TextXAlignment.Left
InputBox.ClearTextOnFocus     = false

PromptLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
	local w = PromptLabel.TextBounds.X + 18
	InputBox.Position = UDim2.new(0, w, 0, 0)
	InputBox.Size     = UDim2.new(1, -w-12, 1, 0)
end)
PromptLabel.Text = PromptLabel.Text

-- Autocomplete
local AcFrame = Instance.new("Frame", Main)
AcFrame.Name            = "Autocomplete"
AcFrame.Size            = UDim2.new(0,220,0,0)
AcFrame.Position        = UDim2.new(0,12,1,-42)
AcFrame.BackgroundColor3= Color3.fromRGB(18,18,28)
AcFrame.BorderSizePixel = 0
AcFrame.Visible         = false
AcFrame.ZIndex          = 10
do
	local c = Instance.new("UICorner",AcFrame); c.CornerRadius = UDim.new(0,8)
	local s = Instance.new("UIStroke",AcFrame);  s.Color = CONFIG.Border; s.Thickness = 1
end
local AcLayout = Instance.new("UIListLayout", AcFrame)
AcLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- =============================================
-- OUTPUT FUNCTIONS
-- =============================================
local lineCount = 0

local function writeLine(text, color, bold)
	lineCount += 1
	local row = Instance.new("TextLabel", Output)
	row.Name               = "Line" .. lineCount
	row.LayoutOrder        = lineCount
	row.Size               = UDim2.new(1,-4,0,0)
	row.AutomaticSize      = Enum.AutomaticSize.Y
	row.BackgroundTransparency = 1
	row.TextColor3         = color or CONFIG.Text
	row.Font               = bold and Enum.Font.GothamBold or CONFIG.Font
	row.TextSize           = CONFIG.TextSize
	row.Text               = text
	row.TextXAlignment     = Enum.TextXAlignment.Left
	row.TextWrapped        = true
	row.RichText           = true

	task.defer(function()
		Output.CanvasPosition = Vector2.new(0, 999999)
	end)
	return row
end

local function writeLines(lines, color)
	for _, l in ipairs(lines) do writeLine(l, color) end
end

local function ok(msg)    writeLine("✓ " .. msg, CONFIG.Success) end
local function err(msg)   writeLine("✗ " .. msg, CONFIG.Error) end
local function warn(msg)  writeLine("⚠ " .. msg, CONFIG.Warn) end
local function info(msg)  writeLine("  " .. msg, CONFIG.Silver) end
local function blank()    writeLine("") end

local function clearOutput()
	for _, v in ipairs(Output:GetChildren()) do
		if v:IsA("TextLabel") then v:Destroy() end
	end
	lineCount = 0
end

-- =============================================
-- COMMAND REGISTRY
-- =============================================
local Commands = {}

local function reg(name, desc, usage, fn, aliases)
	local cmd = { name=name, desc=desc, usage=usage, fn=fn, aliases=aliases or {} }
	Commands[name] = cmd
	for _, a in ipairs(cmd.aliases) do Commands[a] = cmd end
end

-- =============================================
-- COMMANDS: SYSTEM
-- =============================================
reg("help", "Show all commands", "help [command]", function(args)
	if args[1] then
		local c = Commands[args[1]]
		if not c then err("Unknown command: " .. args[1]); return end
		writeLine("💎 " .. c.name, CONFIG.Crystal, true)
		info(c.desc)
		info("Usage: " .. c.usage)
		if #c.aliases > 0 then info("Aliases: " .. table.concat(c.aliases, ", ")) end
		return
	end

	local cats = {
		{ name = "System",    cmds = {"help","clear","echo","history","alias","version","exit","reload"} },
		{ name = "Roblox",    cmds = {"players","me","ping","server","remotes","scripts","workspace","teams"} },
		{ name = "Character", cmds = {"speed","jump","god","heal","kill","tp","tpto","fly","noclip","spin","size","invis","vis"} },
		{ name = "World",     cmds = {"gravity","time","fog","bright","anchor","unanchor","explode","npc","part"} },
		{ name = "Players",   cmds = {"killall","tpall","freezep","unfreezep","bringp","kickp","healp","espall"} },
		{ name = "Lighting",  cmds = {"fullbright","day","night","sunset","reset_light"} },
		{ name = "Camera",    cmds = {"fov","freecam","cam_reset"} },
		{ name = "Executor",  cmds = {"exec","load","dump","find"} },
		{ name = "Sound",     cmds = {"mute","unmute","playsound","stopsounds"} },
	}

	blank()
	writeLine("  💎 CRYSTAL TERMUX — Command Reference", CONFIG.Crystal, true)
	writeLine("  ─────────────────────────────────────", CONFIG.Border)
	blank()
	for _, cat in ipairs(cats) do
		writeLine("  ▸ " .. cat.name, CONFIG.Prompt_Col, true)
		local line = "    "
		for _, cname in ipairs(cat.cmds) do
			if Commands[cname] then line = line .. cname .. "  " end
		end
		writeLine(line, CONFIG.Silver)
	end
	blank()
	info("Type 'help <command>' for details")
	blank()
end)

reg("clear","Clear terminal","clear",function()
	clearOutput()
	writeLine("  💎 Crystal Termux — cleared", CONFIG.Muted)
end, {"cls","c"})

reg("echo","Print text","echo <text>",function(args)
	writeLine(table.concat(args," "), CONFIG.Text)
end)

reg("version","Show version","version",function()
	blank()
	writeLine("  💎 Crystal Termux v2.0", CONFIG.Crystal, true)
	info("Built for Roblox Universal")
	info("Player: " .. LP.Name .. " (" .. LP.UserId .. ")")
	info("Place:  " .. game.PlaceId)
	info("Job:    " .. (game.JobId ~= "" and game.JobId:sub(1,20) or "N/A"))
	blank()
end, {"ver"})

reg("history","Show command history","history",function()
	if #State.history == 0 then info("No history"); return end
	for i, cmd in ipairs(State.history) do
		writeLine(string.format("  %3d  %s", i, cmd), CONFIG.Silver)
	end
end, {"h"})

reg("alias","Create alias","alias <name> <command>",function(args)
	if not args[1] or not args[2] then err("Usage: alias <name> <command>"); return end
	State.aliases[args[1]] = table.concat(args, " ", 2)
	ok("Alias created: " .. args[1] .. " → " .. State.aliases[args[1]])
end)

reg("exit","Close terminal","exit",function()
	ScreenGui:Destroy()
end, {"quit","q"})

reg("reload","Reload terminal","reload",function()
	ok("Reloading...")
	task.delay(0.5, function()
		ScreenGui:Destroy()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/your/crystal_termux/main/loader.lua"))()
	end)
end)

-- =============================================
-- COMMANDS: ROBLOX INFO
-- =============================================
reg("players","List all players","players",function()
	blank()
	writeLine("  Players on server:", CONFIG.Crystal, true)
	for _, p in ipairs(Players:GetPlayers()) do
		local char  = p.Character
		local hrp   = char and char:FindFirstChild("HumanoidRootPart")
		local hum   = char and char:FindFirstChildOfClass("Humanoid")
		local hp    = hum and math.floor(hum.Health) or 0
		local pos   = hrp and string.format("(%.0f,%.0f,%.0f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "N/A"
		local mark  = p == LP and " ◀" or ""
		writeLine(string.format("  %-20s HP:%-5d %s%s", p.Name, hp, pos, mark), CONFIG.Text)
	end
	blank()
end, {"ls","who","ps"})

reg("me","Show your info","me",function()
	local hrp = getHRP()
	local hum = getHum()
	blank()
	writeLine("  You: " .. LP.Name, CONFIG.Crystal, true)
	info("UserID:   " .. LP.UserId)
	info("Account:  " .. LP.AccountAge .. " days old")
	info("Team:     " .. (LP.Team and LP.Team.Name or "None"))
	info("Health:   " .. (hum and math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) or "N/A"))
	info("Speed:    " .. (hum and hum.WalkSpeed or "N/A"))
	info("Position: " .. (hrp and string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "N/A"))
	blank()
end, {"whoami"})

reg("ping","Show ping & FPS","ping",function()
	local ping = math.floor(LP:GetNetworkPing() * 1000)
	local fps  = math.floor(1 / RunService.RenderStepped:Wait())
	local col  = ping < 80 and CONFIG.Success or ping < 150 and CONFIG.Warn or CONFIG.Error
	writeLine(string.format("  Ping: %dms  FPS: %d  Players: %d/%d",
		ping, fps, #Players:GetPlayers(), Players.MaxPlayers), col)
end)

reg("server","Show server info","server",function()
	blank()
	writeLine("  Server Info", CONFIG.Crystal, true)
	info("PlaceId:  " .. game.PlaceId)
	info("JobId:    " .. (game.JobId ~= "" and game.JobId or "N/A"))
	info("Players:  " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
	info("Gravity:  " .. Workspace.Gravity)
	info("StreamingEnabled: " .. tostring(Workspace.StreamingEnabled))
	blank()
end)

reg("remotes","List all remotes","remotes [filter]",function(args)
	local filter = args[1] and args[1]:lower() or nil
	local list = {}
	for _, v in ipairs(game:GetDescendants()) do
		if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("BindableEvent") then
			local path = v:GetFullName()
			if not filter or path:lower():find(filter) then
				table.insert(list, { type=v.ClassName, path=path })
			end
		end
	end
	writeLine("  Found " .. #list .. " remotes:", CONFIG.Crystal, true)
	for i, r in ipairs(list) do
		local col = r.type:find("Remote") and CONFIG.Warn or CONFIG.Silver
		writeLine(string.format("  [%s] %s", r.type:sub(1,2), r.path), col)
		if i >= 50 then writeLine("  ... and " .. (#list-50) .. " more", CONFIG.Muted); break end
	end
end)

reg("scripts","List all scripts","scripts [filter]",function(args)
	local filter = args[1] and args[1]:lower() or nil
	local count  = 0
	for _, v in ipairs(game:GetDescendants()) do
		if v:IsA("LocalScript") or v:IsA("Script") or v:IsA("ModuleScript") then
			local path = v:GetFullName()
			if not filter or path:lower():find(filter) then
				count += 1
				local col = v:IsA("LocalScript") and CONFIG.Crystal or CONFIG.Silver
				writeLine("  [" .. v.ClassName:sub(1,1) .. "] " .. path, col)
			end
		end
	end
	info("Total: " .. count)
end)

reg("workspace","List workspace children","workspace [filter]",function(args)
	local filter = args[1] and args[1]:lower() or nil
	for _, v in ipairs(Workspace:GetChildren()) do
		if not filter or v.Name:lower():find(filter) then
			local col = v:IsA("Model") and CONFIG.Crystal or CONFIG.Silver
			writeLine(string.format("  %-12s %s", v.ClassName, v.Name), col)
		end
	end
end, {"ws","dir"})

reg("teams","List all teams","teams",function()
	local ok2 = false
	for _, t in ipairs(game:GetService("Teams"):GetTeams()) do
		writeLine("  ■ " .. t.Name, t.TeamColor.Color)
		ok2 = true
	end
	if not ok2 then info("No teams") end
end)

-- =============================================
-- COMMANDS: CHARACTER
-- =============================================
reg("speed","Set walk speed","speed <value>",function(args)
	local v = tonumber(args[1])
	if not v then err("Usage: speed <number>"); return end
	local hum = getHum()
	if not hum then err("No character"); return end
	hum.WalkSpeed = v
	ok("Speed set to " .. v)
end, {"ws","walkspeed"})

reg("jump","Set jump power","jump <value>",function(args)
	local v = tonumber(args[1]) or 50
	local hum = getHum()
	if not hum then err("No character"); return end
	hum.JumpPower = v
	ok("Jump power: " .. v)
end, {"jp"})

reg("god","Toggle godmode","god [on|off]",function(args)
	local hum = getHum()
	if not hum then err("No character"); return end
	local on = args[1] ~= "off"
	if on then
		hum.MaxHealth = math.huge
		hum.Health    = math.huge
		ok("Godmode ON")
	else
		hum.MaxHealth = 100
		hum.Health    = 100
		ok("Godmode OFF")
	end
end)

reg("heal","Heal yourself","heal [amount]",function(args)
	local hum = getHum()
	if not hum then err("No character"); return end
	local amt = tonumber(args[1])
	hum.Health = amt and math.min(hum.Health + amt, hum.MaxHealth) or hum.MaxHealth
	ok("Healed to " .. math.floor(hum.Health))
end)

reg("kill","Kill yourself","kill",function()
	local hum = getHum()
	if hum then hum.Health = 0; ok("💀 Killed") else err("No character") end
end, {"suicide"})

reg("tp","Teleport to coords","tp <x> <y> <z>",function(args)
	local x,y,z = tonumber(args[1]),tonumber(args[2]),tonumber(args[3])
	if not x or not y or not z then err("Usage: tp <x> <y> <z>"); return end
	local hrp = getHRP()
	if not hrp then err("No character"); return end
	hrp.CFrame = CFrame.new(x,y,z)
	ok(string.format("Teleported → %.0f, %.0f, %.0f", x, y, z))
end, {"teleport"})

reg("tpto","Teleport to player","tpto <name>",function(args)
	if not args[1] then err("Usage: tpto <name>"); return end
	local target
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():find(args[1]:lower()) then target = p; break end
	end
	if not target then err("Player not found: " .. args[1]); return end
	local char = target.Character
	local tHRP = char and char:FindFirstChild("HumanoidRootPart")
	local hrp  = getHRP()
	if not tHRP or not hrp then err("Character not available"); return end
	hrp.CFrame = tHRP.CFrame + Vector3.new(3,0,0)
	ok("Teleported → " .. target.Name)
end, {"goto","go"})

reg("fly","Toggle fly mode","fly [speed]",function(args)
	local speed = tonumber(args[1]) or 60
	if State.flyActive then
		State.flyActive = false
		if State.flyBP   then State.flyBP:Destroy()   end
		if State.flyBG   then State.flyBG:Destroy()   end
		if State.flyConn then State.flyConn:Disconnect() end
		local hum = getHum()
		if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
		ok("Fly OFF")
		return
	end

	local hrp = getHRP()
	if not hrp then err("No character"); return end

	State.flyActive = true
	State.flyBP = Instance.new("BodyPosition")
	State.flyBP.MaxForce = Vector3.new(1e9,1e9,1e9)
	State.flyBP.Position = hrp.Position
	State.flyBP.D = 100; State.flyBP.P = 5000
	State.flyBP.Parent = hrp

	State.flyBG = Instance.new("BodyGyro")
	State.flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
	State.flyBG.CFrame = hrp.CFrame
	State.flyBG.D = 400; State.flyBG.P = 10000
	State.flyBG.Parent = hrp

	State.flyConn = RunService.RenderStepped:Connect(function()
		if not State.flyActive then return end
		local hrp2 = getHRP()
		if not hrp2 then return end
		local cf = Camera.CFrame
		local mv = Vector3.new(0,0,0)
		if UserInputService:IsKeyDown(Enum.KeyCode.W)          then mv = mv + cf.LookVector  end
		if UserInputService:IsKeyDown(Enum.KeyCode.S)          then mv = mv - cf.LookVector  end
		if UserInputService:IsKeyDown(Enum.KeyCode.A)          then mv = mv - cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D)          then mv = mv + cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space)      then mv = mv + Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)  then mv = mv - Vector3.new(0,1,0) end
		State.flyBP.Position = mv.Magnitude > 0 and hrp2.Position + mv.Unit*speed*0.1 or hrp2.Position
		State.flyBG.CFrame   = cf
	end)
	ok("Fly ON  [WASD+Space/Shift] — 'fly' to stop | Speed: " .. speed)
end)

reg("noclip","Toggle noclip","noclip",function()
	if State.noclip then
		State.noclip = false
		if State.noclipConn then State.noclipConn:Disconnect() end
		ok("Noclip OFF")
	else
		State.noclip = true
		State.noclipConn = RunService.Stepped:Connect(function()
			if not State.noclip then return end
			local c = getChar()
			if not c then return end
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end)
		ok("Noclip ON")
	end
end, {"nc","ghost"})

reg("spin","Toggle spin","spin [speed]",function(args)
	local speed = tonumber(args[1]) or 10
	if State.spinConn then
		State.spinConn:Disconnect(); State.spinConn = nil
		ok("Spin OFF")
	else
		State.spinConn = RunService.Heartbeat:Connect(function()
			local hrp = getHRP()
			if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0,math.rad(speed),0) end
		end)
		ok("Spin ON — speed: " .. speed)
	end
end)

reg("size","Set character scale","size <scale>",function(args)
	local v = tonumber(args[1])
	if not v then err("Usage: size <0.1-5>"); return end
	local char = getChar()
	if not char then err("No character"); return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local desc = safeCall(function() return hum:GetAppliedDescription() end)
	if not desc then err("Cannot get description"); return end
	desc.BodyWidthScale  = v
	desc.BodyHeightScale = v
	desc.HeadScale       = v
	safeCall(function() hum:ApplyDescription(desc) end)
	ok("Size set to " .. v)
end, {"scale"})

reg("invis","Make yourself invisible","invis",function()
	local c = getChar()
	if not c then err("No character"); return end
	for _, v in ipairs(c:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			v.LocalTransparencyModifier = 1
		end
	end
	ok("Invisible")
end)

reg("vis","Make yourself visible","vis",function()
	local c = getChar()
	if not c then err("No character"); return end
	for _, v in ipairs(c:GetDescendants()) do
		if v:IsA("BasePart") then
			v.LocalTransparencyModifier = 0
		end
	end
	ok("Visible")
end)

-- =============================================
-- COMMANDS: WORLD
-- =============================================
reg("gravity","Set gravity","gravity <value>",function(args)
	local v = tonumber(args[1])
	if not v then err("Usage: gravity <0-500>"); return end
	Workspace.Gravity = v
	ok("Gravity: " .. v)
end, {"grav","g"})

reg("time","Set time of day","time <0-24>",function(args)
	local v = tonumber(args[1])
	if not v then err("Usage: time <0-24>"); return end
	Lighting.TimeOfDay = string.format("%02d:00:00", v % 24)
	ok("Time: " .. string.format("%02d:00", v % 24))
end, {"tod"})

reg("fog","Set fog end distance","fog <distance>",function(args)
	local v = tonumber(args[1]) or 100000
	Lighting.FogEnd = v
	ok("Fog end: " .. v)
end)

reg("bright","Set brightness","bright <value>",function(args)
	local v = tonumber(args[1]) or 2
	Lighting.Brightness = v
	ok("Brightness: " .. v)
end)

reg("anchor","Anchor all parts","anchor",function()
	local count = 0
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("BasePart") and not (LP.Character and v:IsDescendantOf(LP.Character)) then
			v.Anchored = true; count += 1
		end
	end
	ok("Anchored " .. count .. " parts")
end)

reg("unanchor","Unanchor all parts","unanchor",function()
	local count = 0
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("BasePart") and not (LP.Character and v:IsDescendantOf(LP.Character)) then
			v.Anchored = false; count += 1
		end
	end
	ok("Unanchored " .. count .. " parts")
end)

reg("explode","Explode at position","explode [x y z]",function(args)
	local pos
	if args[1] then
		pos = Vector3.new(tonumber(args[1]) or 0, tonumber(args[2]) or 0, tonumber(args[3]) or 0)
	else
		local hrp = getHRP()
		pos = hrp and hrp.Position or Vector3.new(0,5,0)
	end
	local e = Instance.new("Explosion")
	e.Position     = pos
	e.BlastRadius  = 20
	e.BlastPressure= 5e5
	e.Parent       = Workspace
	ok(string.format("💥 Explosion at %.0f,%.0f,%.0f", pos.X, pos.Y, pos.Z))
end, {"boom"})

reg("npc","Delete all NPCs","npc [delete]",function(args)
	if args[1] == "delete" or args[1] == "del" then
		local count = 0
		for _, v in ipairs(Workspace:GetChildren()) do
			if v:IsA("Model") and v ~= LP.Character then
				if v:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(v) then
					v:Destroy(); count += 1
				end
			end
		end
		ok("Deleted " .. count .. " NPCs")
	else
		local count = 0
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("Humanoid") and not Players:GetPlayerFromCharacter(v.Parent) then count += 1 end
		end
		info("Found " .. count .. " NPCs (use 'npc delete' to remove)")
	end
end)

reg("part","Spawn a part","part [size] [color]",function(args)
	local hrp = getHRP()
	if not hrp then err("No character"); return end
	local size  = tonumber(args[1]) or 4
	local color = args[2] and BrickColor.new(args[2]) or BrickColor.new("Medium stone grey")
	local p = Instance.new("Part")
	p.Size        = Vector3.new(size,1,size)
	p.CFrame      = hrp.CFrame + Vector3.new(0,-3,0)
	p.BrickColor  = color
	p.Material    = Enum.Material.SmoothPlastic
	p.Parent      = Workspace
	ok("Spawned " .. size .. "x1x" .. size .. " part")
end)

-- =============================================
-- COMMANDS: LIGHTING PRESETS
-- =============================================
reg("fullbright","Maximum visibility","fullbright",function()
	Lighting.Brightness       = 10
	Lighting.Ambient          = Color3.fromRGB(178,178,178)
	Lighting.OutdoorAmbient   = Color3.fromRGB(178,178,178)
	Lighting.GlobalShadows    = false
	ok("Fullbright ON")
end, {"fb"})

reg("day","Set to daytime","day",function()
	Lighting.TimeOfDay = "12:00:00"
	Lighting.Brightness = 2
	Lighting.GlobalShadows = true
	ok("Time: Day")
end)

reg("night","Set to nighttime","night",function()
	Lighting.TimeOfDay = "00:00:00"
	Lighting.Brightness = 0
	ok("Time: Night")
end)

reg("sunset","Set to sunset","sunset",function()
	Lighting.TimeOfDay = "18:30:00"
	Lighting.Brightness = 1
	ok("Time: Sunset")
end)

reg("reset_light","Reset lighting","reset_light",function()
	Lighting.Brightness     = 2
	Lighting.Ambient        = Color3.fromRGB(70,70,70)
	Lighting.TimeOfDay      = "14:00:00"
	Lighting.FogEnd         = 100000
	Lighting.GlobalShadows  = true
	ok("Lighting reset")
end, {"rl"})

-- =============================================
-- COMMANDS: CAMERA
-- =============================================
reg("fov","Set field of view","fov <value>",function(args)
	local v = tonumber(args[1]) or 70
	Camera.FieldOfView = math.clamp(v,1,120)
	ok("FOV: " .. Camera.FieldOfView)
end)

reg("freecam","Toggle freecam","freecam",function()
	if State.freecamActive then
		State.freecamActive = false
		if State.freecamPart then State.freecamPart:Destroy() end
		if State.freecamConn then State.freecamConn:Disconnect() end
		Camera.CameraSubject = getHum()
		Camera.CameraType    = Enum.CameraType.Custom
		ok("Freecam OFF")
		return
	end

	State.freecamActive = true
	local part = Instance.new("Part")
	part.Anchored = true; part.CanCollide = false; part.Transparency = 1
	part.CFrame = Camera.CFrame; part.Parent = Workspace
	State.freecamPart = part

	Camera.CameraSubject = part
	Camera.CameraType    = Enum.CameraType.Custom

	State.freecamConn = RunService.RenderStepped:Connect(function(dt)
		if not State.freecamActive then return end
		local mv  = Vector3.new(0,0,0)
		local cf  = Camera.CFrame
		local spd = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 120 or 60
		if UserInputService:IsKeyDown(Enum.KeyCode.W)          then mv = mv + cf.LookVector  end
		if UserInputService:IsKeyDown(Enum.KeyCode.S)          then mv = mv - cf.LookVector  end
		if UserInputService:IsKeyDown(Enum.KeyCode.A)          then mv = mv - cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D)          then mv = mv + cf.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space)      then mv = mv + Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
		if mv.Magnitude > 0 then part.CFrame = CFrame.new(part.Position + mv.Unit*spd*dt) end
	end)
	ok("Freecam ON  [WASD+Space/Ctrl, Shift=fast] — 'freecam' to stop")
end, {"fc"})

reg("cam_reset","Reset camera","cam_reset",function()
	Camera.CameraType    = Enum.CameraType.Custom
	Camera.CameraSubject = getHum()
	Camera.FieldOfView   = 70
	ok("Camera reset")
end)

-- =============================================
-- COMMANDS: PLAYER ACTIONS
-- =============================================
reg("killall","Kill all players","killall",function()
	local count = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then
			local char = p.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.Health = 0; count += 1 end
		end
	end
	ok("Killed " .. count .. " players")
end)

reg("tpall","Teleport all to you","tpall",function()
	local hrp = getHRP()
	if not hrp then err("No character"); return end
	local count = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then
			local char = p.Character
			local tHRP = char and char:FindFirstChild("HumanoidRootPart")
			if tHRP then
				tHRP.CFrame = hrp.CFrame + Vector3.new(count*4,0,0)
				count += 1
			end
		end
	end
	ok("Brought " .. count .. " players")
end, {"bringall"})

reg("freezep","Freeze a player","freezep <name>",function(args)
	if not args[1] then err("Usage: freezep <name>"); return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():find(args[1]:lower()) then
			local char = p.Character
			if char then
				for _, v in ipairs(char:GetDescendants()) do
					if v:IsA("BasePart") then v.Anchored = true end
				end
				ok("Frozen: " .. p.Name); return
			end
		end
	end
	err("Player not found")
end)

reg("unfreezep","Unfreeze a player","unfreezep <name>",function(args)
	if not args[1] then err("Usage: unfreezep <name>"); return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():find(args[1]:lower()) then
			local char = p.Character
			if char then
				for _, v in ipairs(char:GetDescendants()) do
					if v:IsA("BasePart") then v.Anchored = false end
				end
				ok("Unfrozen: " .. p.Name); return
			end
		end
	end
	err("Player not found")
end)

reg("bringp","Bring a player to you","bringp <name>",function(args)
	if not args[1] then err("Usage: bringp <name>"); return end
	local hrp = getHRP()
	if not hrp then return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():find(args[1]:lower()) and p ~= LP then
			local char = p.Character
			local tHRP = char and char:FindFirstChild("HumanoidRootPart")
			if tHRP then tHRP.CFrame = hrp.CFrame + Vector3.new(3,0,0); ok("Brought: "..p.Name); return end
		end
	end
	err("Player not found")
end, {"bring"})

reg("kickp","Kick a player","kickp <name>",function(args)
	if not args[1] then err("Usage: kickp <name>"); return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():find(args[1]:lower()) then
			safeCall(function() p:Kick("[Crystal] Removed by admin") end)
			ok("Kicked: " .. p.Name); return
		end
	end
	err("Player not found")
end, {"kick"})

reg("healp","Heal a player","healp <name>",function(args)
	if not args[1] then err("Usage: healp <name>"); return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():find(args[1]:lower()) then
			local char = p.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.Health = hum.MaxHealth; ok("Healed: "..p.Name); return end
		end
	end
	err("Player not found")
end)

reg("espall","Toggle ESP for all","espall",function()
	if State.espConn then
		State.espConn:Disconnect(); State.espConn = nil
		for _, v in ipairs(Workspace:GetChildren()) do
			if v.Name:find("_CESP_") then v:Destroy() end
		end
		ok("ESP OFF"); return
	end

	local folder = Instance.new("Folder")
	folder.Name = "_CESP_folder"; folder.Parent = Workspace

	local esps = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then
			local bb = Instance.new("BillboardGui")
			bb.Name = "_CESP_"..p.Name; bb.Size = UDim2.new(5,0,2.5,0)
			bb.AlwaysOnTop = true; bb.MaxDistance = 2000; bb.Parent = folder
			local lbl = Instance.new("TextLabel", bb)
			lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
			lbl.Font = CONFIG.Font; lbl.TextSize = 13
			lbl.TextColor3 = CONFIG.Crystal
			esps[p] = { bb=bb, lbl=lbl }
		end
	end

	State.espConn = RunService.RenderStepped:Connect(function()
		local myHRP = getHRP()
		for p, data in pairs(esps) do
			local char = p.Character
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				data.bb.Adornee = hrp; data.bb.Enabled = true
				local dist = myHRP and math.floor((hrp.Position - myHRP.Position).Magnitude) or 0
				data.lbl.Text = p.Name .. "\n" .. dist .. "m | " .. math.floor(hum.Health) .. "hp"
			else
				data.bb.Enabled = false
			end
		end
	end)
	ok("ESP ON for " .. #Players:GetPlayers()-1 .. " players")
end, {"esp"})

-- =============================================
-- COMMANDS: SOUND
-- =============================================
reg("mute","Mute all sounds","mute",function()
	for _, v in ipairs(game:GetDescendants()) do
		if v:IsA("Sound") then v.Volume = 0 end
	end
	ok("All sounds muted")
end)

reg("unmute","Unmute all sounds","unmute",function()
	for _, v in ipairs(game:GetDescendants()) do
		if v:IsA("Sound") then v.Volume = 0.5 end
	end
	ok("All sounds unmuted")
end)

reg("playsound","Play a sound by ID","playsound <id>",function(args)
	if not args[1] then err("Usage: playsound <rbxassetid>"); return end
	local s = Instance.new("Sound")
	s.SoundId = args[1]:find("rbxassetid") and args[1] or "rbxassetid://"..args[1]
	s.Volume = 0.5; s.Parent = SoundService
	s:Play()
	ok("Playing: " .. s.SoundId)
end, {"play"})

reg("stopsounds","Stop all sounds","stopsounds",function()
	for _, v in ipairs(game:GetDescendants()) do
		if v:IsA("Sound") and v.Playing then v:Stop() end
	end
	ok("All sounds stopped")
end, {"stopall"})

-- =============================================
-- COMMANDS: EXECUTOR
-- =============================================
reg("exec","Execute Lua code","exec <code>",function(args)
	if #args == 0 then err("Usage: exec <lua code>"); return end
	local code = table.concat(args," ")
	local fn, e = loadstring(code)
	if not fn then err("Syntax error: " .. tostring(e)); return end
	local success, result = pcall(fn)
	if success then
		ok("Executed" .. (result ~= nil and (": " .. tostring(result)) or ""))
	else
		err("Runtime error: " .. tostring(result))
	end
end, {"run","lua","e"})

reg("load","Load script from URL","load <url>",function(args)
	if not args[1] then err("Usage: load <url>"); return end
	local ok2, src = pcall(function() return game:HttpGet(args[1]) end)
	if not ok2 then err("HttpGet failed"); return end
	local fn, e = loadstring(src)
	if not fn then err("Parse error: " .. tostring(e)); return end
	local success, result = pcall(fn)
	if success then ok("Loaded and executed") else err(tostring(result)) end
end, {"loadurl"})

reg("dump","Dump instance tree","dump <path>",function(args)
	if not args[1] then err("Usage: dump game.ReplicatedStorage"); return end
	local obj = game
	for part in args[1]:gmatch("[^%.]+") do
		obj = safeCall(function() return obj:WaitForChild(part, 2) end)
		if not obj then err("Not found: " .. part); return end
	end
	writeLine("  " .. obj:GetFullName() .. " [" .. obj.ClassName .. "]", CONFIG.Crystal, true)
	for _, v in ipairs(obj:GetChildren()) do
		writeLine(string.format("  ├─ %-15s %s", v.ClassName, v.Name), CONFIG.Silver)
	end
end)

reg("find","Find instances by name","find <name> [class]",function(args)
	if not args[1] then err("Usage: find <name> [ClassName]"); return end
	local filter = args[1]:lower()
	local class  = args[2]
	local count  = 0
	for _, v in ipairs(game:GetDescendants()) do
		local nameMatch  = v.Name:lower():find(filter)
		local classMatch = not class or v.ClassName:lower():find(class:lower())
		if nameMatch and classMatch then
			writeLine("  " .. v:GetFullName() .. " [" .. v.ClassName .. "]", CONFIG.Silver)
			count += 1
			if count >= 30 then
				warn("Showing first 30 results")
				break
			end
		end
	end
	info("Found " .. count .. " results")
end, {"search","grep"})

-- =============================================
-- AUTOCOMPLETE
-- =============================================
local function getMatches(prefix)
	local matches = {}
	for name, _ in pairs(Commands) do
		if name:sub(1, #prefix) == prefix then
			table.insert(matches, name)
		end
	end
	table.sort(matches)
	return matches
end

local acMatches   = {}
local acSelected  = 0

local function hideAC()
	AcFrame.Visible = false
	for _, v in ipairs(AcFrame:GetChildren()) do
		if v:IsA("TextButton") then v:Destroy() end
	end
end

local function showAC(matches, prefix)
	hideAC()
	if #matches == 0 then return end
	acMatches  = matches
	acSelected = 0

	local rows = math.min(#matches, 7)
	AcFrame.Size = UDim2.new(0, 220, 0, rows * 26 + 6)
	AcFrame.Position = UDim2.new(0, 12, 1, -(40 + rows*26 + 10))
	AcFrame.Visible = true

	for i, name in ipairs(matches) do
		if i > 7 then break end
		local btn = Instance.new("TextButton", AcFrame)
		btn.LayoutOrder = i
		btn.Size = UDim2.new(1,0,0,26)
		btn.BackgroundTransparency = 1
		btn.Text = "  " .. name
		btn.TextColor3 = i == 1 and CONFIG.Crystal or CONFIG.Silver
		btn.Font = CONFIG.Font
		btn.TextSize = 12
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.BorderSizePixel = 0
		btn.ZIndex = 11

		btn.MouseEnter:Connect(function() btn.TextColor3 = CONFIG.Crystal end)
		btn.MouseLeave:Connect(function() btn.TextColor3 = i == acSelected and CONFIG.Crystal or CONFIG.Silver end)
		btn.MouseButton1Click:Connect(function()
			InputBox.Text = name .. " "
			InputBox.CursorPosition = #InputBox.Text + 1
			hideAC()
			InputBox:CaptureFocus()
		end)
	end
end

InputBox:GetPropertyChangedSignal("Text"):Connect(function()
	local text = InputBox.Text
	if text == "" then hideAC(); return end
	local parts = text:split(" ")
	if #parts == 1 and text:sub(-1) ~= " " then
		showAC(getMatches(parts[1]), parts[1])
	else
		hideAC()
	end
end)

-- =============================================
-- INPUT HANDLER
-- =============================================
local function parseArgs(input)
	local args = {}
	for token in input:gmatch("%S+") do
		table.insert(args, token)
	end
	return args
end

local function runCommand(input)
	input = input:match("^%s*(.-)%s*$")
	if input == "" then return end

	-- Alias substitution
	local words = input:split(" ")
	if State.aliases[words[1]] then
		input = State.aliases[words[1]] .. (words[2] and " " .. table.concat(words," ",2) or "")
	end

	-- Echo command to output
	writeLine(CONFIG.Prompt .. input, CONFIG.Prompt_Col)

	-- History
	if State.history[#State.history] ~= input then
		table.insert(State.history, input)
	end
	State.histIdx = #State.history + 1

	-- Parse
	local args  = parseArgs(input)
	local name  = table.remove(args, 1):lower()
	local cmd   = Commands[name]

	if cmd then
		local ok2, e = pcall(cmd.fn, args)
		if not ok2 then err("Error: " .. tostring(e)) end
	else
		err("Command not found: " .. name .. "  (type 'help')")
	end
end

InputBox.FocusLost:Connect(function(enter)
	if enter then
		local text = InputBox.Text
		InputBox.Text = ""
		hideAC()
		runCommand(text)
		InputBox:CaptureFocus()
	end
end)

-- Arrow keys for history + Tab autocomplete
UserInputService.InputBegan:Connect(function(input, gpe)
	if not InputBox:IsFocused() then return end

	if input.KeyCode == Enum.KeyCode.Up then
		State.histIdx = math.max(1, State.histIdx - 1)
		InputBox.Text = State.history[State.histIdx] or ""
		InputBox.CursorPosition = #InputBox.Text + 1

	elseif input.KeyCode == Enum.KeyCode.Down then
		State.histIdx = math.min(#State.history + 1, State.histIdx + 1)
		InputBox.Text = State.history[State.histIdx] or ""
		InputBox.CursorPosition = #InputBox.Text + 1

	elseif input.KeyCode == Enum.KeyCode.Tab then
		if #acMatches > 0 then
			InputBox.Text = acMatches[1] .. " "
			InputBox.CursorPosition = #InputBox.Text + 1
			hideAC()
		end
	end
end)

-- =============================================
-- WINDOW CONTROLS + DRAG
-- =============================================
BtnClose.MouseButton1Click:Connect(function()
	TweenService:Create(Main, TweenInfo.new(0.25), {Size=UDim2.new(0,0,0,0)}):Play()
	task.delay(0.25, function() ScreenGui:Destroy() end)
end)

local minimized = false
BtnMin.MouseButton1Click:Connect(function()
	minimized = not minimized
	TweenService:Create(Main, TweenInfo.new(0.2),
		{Size = minimized and UDim2.new(0,CONFIG.Width,0,44) or UDim2.new(0,CONFIG.Width,0,CONFIG.Height)}
	):Play()
end)

local maximized = false
BtnMax.MouseButton1Click:Connect(function()
	maximized = not maximized
	TweenService:Create(Main, TweenInfo.new(0.2),
		{Size = maximized and UDim2.new(1,0,1,0) or UDim2.new(0,CONFIG.Width,0,CONFIG.Height),
		 Position = maximized and UDim2.new(0,0,0,0) or UDim2.new(0.5,-CONFIG.Width/2,0.5,-CONFIG.Height/2)}
	):Play()
end)

-- Drag (Mouse + Touch)
local dragging, dragStart, startPos

local function onDragStart(pos)
	dragging  = true
	dragStart = pos
	startPos  = Main.Position
end
local function onDragMove(pos)
	if not dragging then return end
	local delta = pos - dragStart
	Main.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end
local function onDragEnd()
	dragging = false
end

TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
	   input.UserInputType == Enum.UserInputType.Touch then
		onDragStart(Vector2.new(input.Position.X, input.Position.Y))
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or
	   input.UserInputType == Enum.UserInputType.Touch then
		onDragMove(Vector2.new(input.Position.X, input.Position.Y))
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
	   input.UserInputType == Enum.UserInputType.Touch then
		onDragEnd()
	end
end)

-- Toggle (handled below)

-- =============================================
-- SPLASH SCREEN
-- =============================================
local SplashLines = {
	"  💎 Crystal Termux v2.0",
	"  ─────────────────────",
	"  Universal Roblox Terminal",
	"  Loading commands...",
}

local function showSplash()
	Main.Visible = false

	local splash = Instance.new("Frame", ScreenGui)
	splash.Size              = UDim2.new(0, 420, 0, 160)
	splash.Position          = UDim2.new(0.5,-210,0.5,-80)
	splash.BackgroundColor3  = Color3.fromRGB(8,8,12)
	splash.BorderSizePixel   = 0
	Instance.new("UICorner", splash).CornerRadius = UDim.new(0,12)
	local ss = Instance.new("UIStroke", splash)
	ss.Color = CONFIG.Border; ss.Thickness = 1

	local icon = Instance.new("TextLabel", splash)
	icon.Size = UDim2.new(0,50,0,50); icon.Position = UDim2.new(0,20,0,20)
	icon.BackgroundTransparency = 1; icon.Text = "💎"; icon.TextSize = 32
	icon.Font = CONFIG.Font; icon.TextTransparency = 1

	local title = Instance.new("TextLabel", splash)
	title.Size = UDim2.new(1,-90,0,30); title.Position = UDim2.new(0,80,0,22)
	title.BackgroundTransparency = 1; title.Text = "Crystal Termux"
	title.TextColor3 = CONFIG.Crystal; title.Font = CONFIG.Font
	title.TextSize = 20; title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTransparency = 1

	local sub = Instance.new("TextLabel", splash)
	sub.Size = UDim2.new(1,-90,0,18); sub.Position = UDim2.new(0,80,0,52)
	sub.BackgroundTransparency = 1; sub.Text = LP.Name .. "@roblox"
	sub.TextColor3 = CONFIG.Muted; sub.Font = CONFIG.Font
	sub.TextSize = 12; sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.TextTransparency = 1

	local status = Instance.new("TextLabel", splash)
	status.Size = UDim2.new(1,-40,0,16); status.Position = UDim2.new(0,20,0,95)
	status.BackgroundTransparency = 1; status.Text = "initializing..."
	status.TextColor3 = CONFIG.Muted; status.Font = CONFIG.Font
	status.TextSize = 11; status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextTransparency = 1

	local barBg = Instance.new("Frame", splash)
	barBg.Size = UDim2.new(1,-40,0,4); barBg.Position = UDim2.new(0,20,0,118)
	barBg.BackgroundColor3 = Color3.fromRGB(25,25,35); barBg.BorderSizePixel = 0
	barBg.BackgroundTransparency = 1
	Instance.new("UICorner",barBg).CornerRadius = UDim.new(1,0)

	local barFill = Instance.new("Frame", barBg)
	barFill.Size = UDim2.new(0,0,1,0); barFill.BackgroundColor3 = CONFIG.Crystal
	barFill.BorderSizePixel = 0; barFill.BackgroundTransparency = 1
	Instance.new("UICorner",barFill).CornerRadius = UDim.new(1,0)

	-- Appear
	local ai = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(icon,   ai, {TextTransparency=0}):Play()
	TweenService:Create(title,  ai, {TextTransparency=0}):Play()
	TweenService:Create(sub,    ai, {TextTransparency=0}):Play()
	TweenService:Create(status, ai, {TextTransparency=0}):Play()
	TweenService:Create(barBg,  ai, {BackgroundTransparency=0}):Play()
	TweenService:Create(barFill,ai, {BackgroundTransparency=0}):Play()
	task.wait(0.35)

	local cmdCount = 0
	for _, _ in pairs(Commands) do cmdCount += 1 end

	local steps = {
		{0.15, "loading core modules..."},
		{0.35, "loading character commands..."},
		{0.55, "loading world commands..."},
		{0.75, "loading player commands..."},
		{0.90, "loading executor..."},
		{1.00, "ready! " .. cmdCount .. " commands loaded"},
	}

	for _, step in ipairs(steps) do
		status.Text = step[2]
		TweenService:Create(barFill, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size=UDim2.new(step[1],0,1,0)}):Play()
		task.wait(0.18)
	end

	task.wait(0.4)
	local fi = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	TweenService:Create(splash, fi, {BackgroundTransparency=1}):Play()
	TweenService:Create(icon,   fi, {TextTransparency=1}):Play()
	TweenService:Create(title,  fi, {TextTransparency=1}):Play()
	TweenService:Create(sub,    fi, {TextTransparency=1}):Play()
	TweenService:Create(status, fi, {TextTransparency=1}):Play()
	TweenService:Create(barBg,  fi, {BackgroundTransparency=1}):Play()
	TweenService:Create(barFill,fi, {BackgroundTransparency=1}):Play()
	task.wait(0.3)
	splash:Destroy()

	-- Show terminal
	Main.Visible              = true
	Main.BackgroundTransparency = 1
	TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {BackgroundTransparency=0}):Play()
	task.wait(0.1)

	blank()
	writeLine("  💎 Crystal Termux v2.0 — " .. LP.Name .. "@roblox", CONFIG.Crystal, true)
	writeLine("  ─────────────────────────────────────────────", CONFIG.Border)
	info("  " .. cmdCount .. " commands available  |  type 'help' to start")
	info("  F9 = toggle  |  Tab = autocomplete  |  ↑↓ = history")
	blank()

	InputBox:CaptureFocus()
end

-- =============================================
-- COMMANDS: NETWORK / ANTI
-- =============================================
reg("antikick","Toggle anti-kick","antikick",function()
	if State.antiKick then
		State.antiKick = false
		if State.antiKickHook then
			safeCall(function()
				local mt = getrawmetatable(game)
				setreadonly(mt,false)
				mt.__namecall = State.antiKickOrig
				setreadonly(mt,true)
			end)
		end
		ok("Anti-Kick OFF")
		return
	end
	local hooked = safeCall(function()
		local mt = getrawmetatable(game)
		setreadonly(mt,false)
		State.antiKickOrig = mt.__namecall
		mt.__namecall = newcclosure(function(self,...)
			if getnamecallmethod() == "Kick" then
				warn("[AK] Kick blocked!")
				return
			end
			return State.antiKickOrig(self,...)
		end)
		setreadonly(mt,true)
		return true
	end)
	State.antiKick = true
	if hooked then ok("Anti-Kick ON") else warn("Anti-Kick ON (limited — executor may not support hooks)") end
end, {"ak"})

reg("antitp","Toggle anti-teleport","antitp",function()
	if State.antiTP then
		State.antiTP = false
		if State.antiTPConn then State.antiTPConn:Disconnect() end
		ok("Anti-TP OFF"); return
	end
	State.antiTP = true
	local lastPos = getHRP() and getHRP().Position or Vector3.new(0,0,0)
	State.antiTPConn = RunService.Heartbeat:Connect(function()
		if not State.antiTP then return end
		local hrp = getHRP()
		if not hrp then return end
		local dist = (hrp.Position - lastPos).Magnitude
		if dist > 200 then
			hrp.CFrame = CFrame.new(lastPos)
			warn("[AT] Teleport blocked!")
		else
			lastPos = hrp.Position
		end
	end)
	ok("Anti-TP ON  (blocks >200 stud jumps)")
end, {"at"})

reg("antideath","Toggle anti-death","antideath",function()
	if State.antiDeath then
		State.antiDeath = false
		if State.antiDeathConn then State.antiDeathConn:Disconnect() end
		ok("Anti-Death OFF"); return
	end
	State.antiDeath = true
	local function hook(char)
		local hum = char:WaitForChild("Humanoid",5)
		if not hum then return end
		State.antiDeathConn = hum.HealthChanged:Connect(function(hp)
			if State.antiDeath and hp <= 0 then
				task.defer(function()
					if hum and hum.Parent then hum.Health = hum.MaxHealth end
				end)
			end
		end)
	end
	if LP.Character then task.spawn(hook,LP.Character) end
	LP.CharacterAdded:Connect(hook)
	ok("Anti-Death ON")
end, {"ad","nodeath"})

reg("antirag","Toggle anti-ragdoll","antirag",function()
	if State.antiRagConn then
		State.antiRagConn:Disconnect(); State.antiRagConn = nil
		ok("Anti-Ragdoll OFF"); return
	end
	State.antiRagConn = RunService.Heartbeat:Connect(function()
		local char = getChar()
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
			hum.Sit           = false
		end
		for _,v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") and v.Anchored then v.Anchored = false end
		end
	end)
	ok("Anti-Ragdoll ON")
end, {"ar","norag"})

-- =============================================
-- COMMANDS: REMOTE TOOLS
-- =============================================
reg("fire","Fire a remote event","fire <path> [args]",function(args)
	if not args[1] then err("Usage: fire game.RS.EventName [arg1 arg2]"); return end
	local obj = game
	for part in args[1]:gmatch("[^%.]+") do
		obj = safeCall(function() return obj:WaitForChild(part,2) end)
		if not obj then err("Not found: "..part); return end
	end
	if not obj:IsA("RemoteEvent") then err("Not a RemoteEvent: "..obj.ClassName); return end
	local callArgs = {}
	for i=2,#args do table.insert(callArgs, args[i]) end
	safeCall(function() obj:FireServer(table.unpack(callArgs)) end)
	ok("Fired: " .. obj:GetFullName())
end)

reg("invoke","Invoke a remote function","invoke <path>",function(args)
	if not args[1] then err("Usage: invoke game.RS.FunctionName"); return end
	local obj = game
	for part in args[1]:gmatch("[^%.]+") do
		obj = safeCall(function() return obj:WaitForChild(part,2) end)
		if not obj then err("Not found: "..part); return end
	end
	if not obj:IsA("RemoteFunction") then err("Not a RemoteFunction: "..obj.ClassName); return end
	local result = safeCall(function() return obj:InvokeServer() end)
	ok("Result: " .. tostring(result))
end)

reg("spy","Toggle remote spy","spy",function()
	if State.spyActive then
		State.spyActive = false
		ok("Spy OFF"); return
	end
	local hooked = safeCall(function()
		local mt = getrawmetatable(game)
		setreadonly(mt,false)
		local orig = mt.__namecall
		mt.__namecall = newcclosure(function(self,...)
			local m = getnamecallmethod()
			if (m=="FireServer" or m=="InvokeServer") and State.spyActive then
				local path = safeCall(function() return self:GetFullName() end) or "?"
				writeLine("  [SPY] " .. m .. " → " .. path, CONFIG.Warn)
				task.defer(function()
					Output.CanvasPosition = Vector2.new(0,999999)
				end)
			end
			return orig(self,...)
		end)
		setreadonly(mt,true)
		return true
	end)
	State.spyActive = true
	if hooked then ok("Spy ON — all remotes shown here")
	else warn("Spy ON (executor may not support hooks — limited)") end
end)

-- =============================================
-- COMMANDS: TELEPORT SAVED
-- =============================================
reg("savepos","Save current position","savepos [name]",function(args)
	local hrp = getHRP()
	if not hrp then err("No character"); return end
	State.savedPos = State.savedPos or {}
	local name = args[1] or ("pos"..#State.savedPos+1)
	State.savedPos[name] = hrp.Position
	ok("Saved '"..name.."' → "..string.format("%.0f,%.0f,%.0f",hrp.Position.X,hrp.Position.Y,hrp.Position.Z))
end, {"save"})

reg("loadpos","Teleport to saved position","loadpos [name]",function(args)
	State.savedPos = State.savedPos or {}
	if not args[1] then
		if not next(State.savedPos) then info("No saved positions"); return end
		for n,p in pairs(State.savedPos) do
			writeLine(string.format("  %-12s → %.0f,%.0f,%.0f",n,p.X,p.Y,p.Z), CONFIG.Silver)
		end
		return
	end
	local pos = State.savedPos[args[1]]
	if not pos then err("Not found: "..args[1]); return end
	local hrp = getHRP()
	if not hrp then return end
	hrp.CFrame = CFrame.new(pos)
	ok("→ "..args[1])
end, {"goto2","pos"})

reg("tpspawn","Teleport to game spawn","tpspawn",function()
	local hrp = getHRP()
	if not hrp then return end
	local sp = Workspace:FindFirstChildWhichIsA("SpawnLocation",true)
	if sp then hrp.CFrame = CFrame.new(sp.Position + Vector3.new(0,5,0)); ok("→ Spawn: "..sp:GetFullName())
	else hrp.CFrame = CFrame.new(0,10,0); ok("→ Origin (0,10,0)") end
end, {"spawn","respawn"})

-- =============================================
-- COMMANDS: CHARACTER APPEARANCE
-- =============================================
reg("color","Set character color","color <r> <g> <b>",function(args)
	local r,g,b = tonumber(args[1]),tonumber(args[2]),tonumber(args[3])
	if not r or not g or not b then err("Usage: color <0-255> <0-255> <0-255>"); return end
	local char = getChar()
	if not char then return end
	local col = Color3.fromRGB(r,g,b)
	for _,v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			v.Color = col
		end
	end
	ok(string.format("Color set to rgb(%d,%d,%d)",r,g,b))
end)

reg("glow","Add neon glow to character","glow [on|off]",function(args)
	local char = getChar()
	if not char then return end
	local on = args[1] ~= "off"
	for _,v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			v.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
		end
	end
	ok("Glow: " .. (on and "ON" or "OFF"))
end)

reg("hat","List/remove hats","hat [remove]",function(args)
	local char = getChar()
	if not char then return end
	if args[1] == "remove" then
		local count = 0
		for _,v in ipairs(char:GetChildren()) do
			if v:IsA("Accessory") then v:Destroy(); count+=1 end
		end
		ok("Removed "..count.." accessories")
	else
		local count = 0
		for _,v in ipairs(char:GetChildren()) do
			if v:IsA("Accessory") then
				writeLine("  🎩 "..v.Name, CONFIG.Silver); count+=1
			end
		end
		if count == 0 then info("No accessories") end
	end
end, {"acc","accessory"})

reg("forcefield","Spawn forcefield","forcefield [duration]",function(args)
	local char = getChar()
	if not char then return end
	local dur = tonumber(args[1]) or 10
	local ff = char:FindFirstChildOfClass("ForceField")
	if ff then ff:Destroy(); ok("ForceField removed"); return end
	ff = Instance.new("ForceField")
	ff.Parent = char
	ok("ForceField ON for "..dur.."s")
	task.delay(dur,function() if ff and ff.Parent then ff:Destroy() end end)
end, {"ff","shield"})

-- =============================================
-- COMMANDS: INFO / DEBUG
-- =============================================
reg("fps","Show FPS monitor","fps",function()
	if State.fpsConn then
		State.fpsConn:Disconnect(); State.fpsConn = nil
		if State.fpsLabel then State.fpsLabel:Destroy() end
		ok("FPS monitor OFF"); return
	end

	local label = Instance.new("TextLabel", ScreenGui)
	label.Size = UDim2.new(0,120,0,24)
	label.Position = UDim2.new(1,-130,0,10)
	label.BackgroundColor3 = Color3.fromRGB(8,8,12)
	label.BackgroundTransparency = 0.3
	label.TextColor3 = CONFIG.Crystal
	label.Font = CONFIG.Font
	label.TextSize = 12
	label.BorderSizePixel = 0
	Instance.new("UICorner",label).CornerRadius = UDim.new(0,6)
	local stroke = Instance.new("UIStroke",label)
	stroke.Color = CONFIG.Border; stroke.Thickness = 1
	State.fpsLabel = label

	local frames = 0
	local last   = tick()
	State.fpsConn = RunService.RenderStepped:Connect(function()
		frames += 1
		local now = tick()
		if now - last >= 0.5 then
			local fps  = math.floor(frames / (now-last))
			local ping = math.floor(LP:GetNetworkPing()*1000)
			local col  = fps >= 55 and CONFIG.Success or fps >= 30 and CONFIG.Warn or CONFIG.Error
			label.TextColor3 = col
			label.Text = string.format(" 💎 %dfps %dms", fps, ping)
			frames = 0; last = now
		end
	end)
	ok("FPS monitor ON  (type 'fps' again to hide)")
end)

reg("vars","Show all state variables","vars",function()
	blank()
	writeLine("  State Variables", CONFIG.Crystal, true)
	local checks = {
		{"Fly",       State.flyActive},
		{"Noclip",    State.noclip},
		{"Spin",      State.spinConn ~= nil},
		{"Freecam",   State.freecamActive},
		{"ESP",       State.espConn ~= nil},
		{"Anti-Kick", State.antiKick},
		{"Anti-TP",   State.antiTP},
		{"Anti-Death",State.antiDeath},
		{"Anti-Rag",  State.antiRagConn ~= nil},
		{"Spy",       State.spyActive},
		{"FPS HUD",   State.fpsConn ~= nil},
	}
	for _,c in ipairs(checks) do
		local col = c[2] and CONFIG.Success or CONFIG.Muted
		local sym = c[2] and "●" or "○"
		writeLine(string.format("  %s  %-14s %s", sym, c[1], c[2] and "ON" or "off"), col)
	end
	blank()
end, {"status","stat"})

reg("prop","Get/set property of an instance","prop <path> <property> [value]",function(args)
	if not args[1] or not args[2] then
		err("Usage: prop game.Workspace.Part Transparency 0.5"); return
	end
	local obj = game
	for part in args[1]:gmatch("[^%.]+") do
		obj = safeCall(function() return obj:WaitForChild(part,2) end)
		if not obj then err("Not found: "..part); return end
	end
	local prop = args[2]
	if args[3] then
		local val = tonumber(args[3]) or (args[3]=="true") or (args[3]~="false" and args[3])
		local ok2,e = pcall(function() obj[prop] = val end)
		if ok2 then ok(obj:GetFullName().."."..prop.." = "..tostring(val))
		else err(tostring(e)) end
	else
		local ok2,val = pcall(function() return obj[prop] end)
		if ok2 then info(obj:GetFullName().."."..prop.." = "..tostring(val))
		else err(tostring(val)) end
	end
end)

reg("count","Count instances by class","count <ClassName>",function(args)
	if not args[1] then err("Usage: count BasePart"); return end
	local count = 0
	for _,v in ipairs(game:GetDescendants()) do
		if v.ClassName == args[1] then count += 1 end
	end
	info(args[1] .. ": " .. count .. " instances found")
end)

reg("uptime","Show session uptime","uptime",function()
	local t   = math.floor(tick() - (State.startTime or tick()))
	local h   = math.floor(t/3600)
	local m   = math.floor((t%3600)/60)
	local s   = t%60
	info(string.format("Session uptime: %02d:%02d:%02d", h, m, s))
end)

reg("neofetch","Show system info art","neofetch",function()
	blank()
	local lines = {
		{"  ██████╗██████╗ ██╗   ██╗███████╗████████╗ █████╗ ██╗     ", CONFIG.Crystal},
		{" ██╔════╝██╔══██╗╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔══██╗██║     ", CONFIG.Crystal},
		{" ██║     ██████╔╝ ╚████╔╝ ███████╗   ██║   ███████║██║     ", CONFIG.Prompt_Col},
		{" ██║     ██╔══██╗  ╚██╔╝  ╚════██║   ██║   ██╔══██║██║     ", CONFIG.Prompt_Col},
		{" ╚██████╗██║  ██║   ██║   ███████║   ██║   ██║  ██║███████╗", CONFIG.Silver},
		{"  ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝", CONFIG.Silver},
	}
	for _,l in ipairs(lines) do writeLine(l[1], l[2]) end
	blank()
	local hrp = getHRP(); local hum = getHum()
	local pairs2 = {
		{"User",      LP.Name .. " (" .. LP.UserId .. ")"},
		{"OS",        "Roblox " .. game.PlaceId},
		{"Shell",     "Crystal Termux v2.0"},
		{"Place",     tostring(game.PlaceId)},
		{"Players",   #Players:GetPlayers() .. "/" .. Players.MaxPlayers},
		{"Ping",      math.floor(LP:GetNetworkPing()*1000) .. "ms"},
		{"Position",  hrp and string.format("%.0f,%.0f,%.0f",hrp.Position.X,hrp.Position.Y,hrp.Position.Z) or "N/A"},
		{"Health",    hum and math.floor(hum.Health).."/"..math.floor(hum.MaxHealth) or "N/A"},
		{"Gravity",   tostring(Workspace.Gravity)},
		{"Commands",  (function() local n=0; for _ in pairs(Commands) do n+=1 end; return n end)() .. " loaded"},
	}
	for _,p in ipairs(pairs2) do
		writeLine(string.format("  %-12s %s %s", p[1], "│", p[2]), CONFIG.Silver)
	end
	blank()
end, {"nf","info","sysinfo"})

-- =============================================
-- COMMANDS: UTILITIES
-- =============================================
reg("copy","Copy text to clipboard","copy <text>",function(args)
	if not args[1] then err("Usage: copy <text>"); return end
	local text = table.concat(args," ")
	local ok2 = safeCall(function()
		setclipboard(text)
		return true
	end)
	if ok2 then ok("Copied: " .. text)
	else err("Clipboard not supported by executor") end
end, {"clip","cb"})

reg("notify","Show notification","notify <title> <message>",function(args)
	if not args[1] then err("Usage: notify <title> <text>"); return end
	local title = args[1]
	local msg   = table.concat(args," ",2)
	safeCall(function()
		game:GetService("StarterGui"):SetCore("SendNotification",{
			Title    = title,
			Text     = msg,
			Duration = 4,
		})
	end)
	ok("Notification sent")
end, {"notif","alert"})

reg("screenshot","Save screenshot","screenshot",function()
	local ok2 = safeCall(function()
		local ss = game:GetService("Screenshot")
		if ss then ss:RequestScreenshot() end
		return true
	end)
	ok2 = ok2 or safeCall(function() writescreenshot(); return true end)
	if ok2 then ok("Screenshot taken") else err("Screenshots not supported") end
end, {"ss","snap"})

reg("rejoin","Rejoin the server","rejoin",function()
	safeCall(function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
	end)
	ok("Rejoining...")
end, {"rj"})

reg("serverhop","Hop to a new server","serverhop",function()
	ok("Finding new server...")
	safeCall(function()
		local TS       = game:GetService("TeleportService")
		local HttpSvc  = game:GetService("HttpService")
		local servers  = HttpSvc:JSONDecode(game:HttpGet(
			"https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
		)).data
		local current  = game.JobId
		for _, s in ipairs(servers) do
			if s.id ~= current and s.playing < s.maxPlayers then
				TS:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
				return
			end
		end
		warn("No other servers found")
	end)
end, {"hop","sh"})

reg("chat","Send a chat message","chat <message>",function(args)
	if not args[1] then err("Usage: chat <message>"); return end
	local msg = table.concat(args," ")
	local sent = false

	local attempts = {
		function()
			game:GetService("ReplicatedStorage")
				:FindFirstChild("DefaultChatSystemChatEvents",true)
				:FindFirstChild("SayMessageRequest"):FireServer(msg,"All")
			sent = true
		end,
		function()
			game:GetService("Chat"):Chat(getChar(),msg)
			sent = true
		end,
	}

	for _,fn in ipairs(attempts) do
		safeCall(fn)
		if sent then ok("Sent: "..msg); return end
	end
	err("Chat not available in this game")
end, {"say","msg"})

reg("stopall","Stop all active features","stopall",function()
	if State.flyActive then
		State.flyActive = false
		if State.flyBP then State.flyBP:Destroy() end
		if State.flyBG then State.flyBG:Destroy() end
		if State.flyConn then State.flyConn:Disconnect() end
	end
	if State.noclip then
		State.noclip = false
		if State.noclipConn then State.noclipConn:Disconnect() end
	end
	if State.spinConn then State.spinConn:Disconnect(); State.spinConn = nil end
	if State.freecamActive then
		State.freecamActive = false
		if State.freecamPart then State.freecamPart:Destroy() end
		if State.freecamConn then State.freecamConn:Disconnect() end
		Camera.CameraSubject = getHum()
		Camera.CameraType = Enum.CameraType.Custom
	end
	if State.espConn then State.espConn:Disconnect(); State.espConn = nil end
	if State.antiRagConn then State.antiRagConn:Disconnect(); State.antiRagConn = nil end
	if State.antiTPConn then State.antiTPConn:Disconnect() end
	if State.antiDeath then State.antiDeath = false end
	if State.fpsConn then State.fpsConn:Disconnect(); State.fpsConn = nil end
	if State.fpsLabel then State.fpsLabel:Destroy(); State.fpsLabel = nil end
	if State.spyActive then State.spyActive = false end
	local hum = getHum()
	if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
	Workspace.Gravity = 196.2
	Camera.FieldOfView = 70
	ok("All features stopped & reset")
end, {"reset","killall2","panic"})

-- =============================================
-- INIT RECORD
-- =============================================
State.startTime = tick()

-- =============================================
-- MOBILE: QUICK BUTTONS + TOUCH INPUT
-- =============================================
if CONFIG.isMobile then

	-- Quick command bar (горизонтальная прокрутка снизу)
	local quickBar = Instance.new("ScrollingFrame", Main)
	quickBar.Name                  = "QuickBar"
	quickBar.Size                  = UDim2.new(1,0, 0, 52)
	quickBar.Position              = UDim2.new(0,0, 1, -(CONFIG.InputH + 56))
	quickBar.BackgroundColor3      = Color3.fromRGB(10,10,16)
	quickBar.BorderSizePixel       = 0
	quickBar.ScrollBarThickness    = 0
	quickBar.ScrollingDirection    = Enum.ScrollingDirection.X
	quickBar.AutomaticCanvasSize   = Enum.AutomaticSize.X
	quickBar.CanvasSize            = UDim2.new(0,0,0,0)
	quickBar.ClipsDescendants      = true

	local qLayout = Instance.new("UIListLayout", quickBar)
	qLayout.FillDirection  = Enum.FillDirection.Horizontal
	qLayout.SortOrder      = Enum.SortOrder.LayoutOrder
	qLayout.Padding        = UDim.new(0,6)
	qLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	local qPad = Instance.new("UIPadding", quickBar)
	qPad.PaddingLeft = UDim.new(0,8); qPad.PaddingRight = UDim.new(0,8)

	local quickCmds = {
		{"🚀 Fly",       "fly"},
		{"👻 Noclip",    "noclip"},
		{"🛡 God",       "god"},
		{"⚡ Speed 60",  "speed 60"},
		{"👥 ESP",       "espall"},
		{"✨ Bright",    "fullbright"},
		{"🌙 Night",     "night"},
		{"☀ Day",       "day"},
		{"💊 Heal",      "heal"},
		{"🌀 Spin",      "spin"},
		{"📷 Freecam",   "freecam"},
		{"💥 Explode",   "explode"},
		{"🔄 Rejoin",    "rejoin"},
		{"🏁 Spawn",     "tpspawn"},
		{"🔊 Mute",      "mute"},
		{"🔴 Stop All",  "stopall"},
		{"📊 Info",      "neofetch"},
		{"🔮 Vars",      "vars"},
		{"📡 Remotes",   "remotes"},
		{"🧹 Clear",     "clear"},
	}

	for i, qc in ipairs(quickCmds) do
		local btn = Instance.new("TextButton", quickBar)
		btn.LayoutOrder        = i
		btn.Size               = UDim2.new(0, 0, 1, -10)
		btn.AutomaticSize      = Enum.AutomaticSize.X
		btn.BackgroundColor3   = Color3.fromRGB(18,18,28)
		btn.TextColor3         = CONFIG.Crystal
		btn.Font               = CONFIG.Font
		btn.TextSize           = 12
		btn.Text               = " " .. qc[1] .. " "
		btn.BorderSizePixel    = 0
		btn.AutoButtonColor    = false
		Instance.new("UICorner",btn).CornerRadius = UDim.new(0,8)
		Instance.new("UIStroke",btn).Color = CONFIG.Border

		btn.MouseButton1Click:Connect(function()
			runCommand(qc[2])
			btn.BackgroundColor3 = CONFIG.Prompt_Col
			task.delay(0.2, function() btn.BackgroundColor3 = Color3.fromRGB(18,18,28) end)
		end)

		btn.TouchTap:Connect(function()
			runCommand(qc[2])
			btn.BackgroundColor3 = CONFIG.Prompt_Col
			task.delay(0.2, function() btn.BackgroundColor3 = Color3.fromRGB(18,18,28) end)
		end)
	end

	-- Сепаратор над quick bar
	local qSep = Instance.new("Frame", Main)
	qSep.Size             = UDim2.new(1,0,0,1)
	qSep.Position         = UDim2.new(0,0,1,-(CONFIG.InputH+58))
	qSep.BackgroundColor3 = CONFIG.Border
	qSep.BorderSizePixel  = 0

	-- Адаптируем Output под мобиль
	Output.Size     = UDim2.new(1,-16, 1, -(CONFIG.TitleH + CONFIG.InputH + 66))
	Output.Position = UDim2.new(0,8, 0, CONFIG.TitleH+6)

	-- Большой InputBox для мобиля
	InputBox.TextSize    = 15
	InputBox.ClearTextOnFocus = false

	-- Кнопка Send рядом с инпутом
	local sendBtn = Instance.new("TextButton", InputBar)
	sendBtn.Size             = UDim2.new(0, 60, 1, -8)
	sendBtn.Position         = UDim2.new(1, -66, 0, 4)
	sendBtn.BackgroundColor3 = CONFIG.Prompt_Col
	sendBtn.TextColor3       = Color3.fromRGB(255,255,255)
	sendBtn.Font             = CONFIG.Font
	sendBtn.TextSize         = 13
	sendBtn.Text             = "▶ GO"
	sendBtn.BorderSizePixel  = 0
	sendBtn.AutoButtonColor  = false
	Instance.new("UICorner",sendBtn).CornerRadius = UDim.new(0,8)

	sendBtn.MouseButton1Click:Connect(function()
		local text = InputBox.Text
		InputBox.Text = ""
		hideAC()
		runCommand(text)
	end)
	sendBtn.TouchTap:Connect(function()
		local text = InputBox.Text
		InputBox.Text = ""
		hideAC()
		runCommand(text)
	end)

	-- Адаптируем InputBox ширину под мобиль
	InputBox.Size     = UDim2.new(1,-140,1,-6)
	InputBox.Position = UDim2.new(0,8,0,3)
	PromptLabel.Visible = false

	-- F9 toggle через кнопку на экране (мобиль)
	local toggleBtn = Instance.new("TextButton", ScreenGui)
	toggleBtn.Size             = UDim2.new(0,44,0,44)
	toggleBtn.Position         = UDim2.new(0,10,0,10)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(14,14,22)
	toggleBtn.TextColor3       = CONFIG.Crystal
	toggleBtn.Font             = CONFIG.Font
	toggleBtn.TextSize         = 20
	toggleBtn.Text             = "💎"
	toggleBtn.BorderSizePixel  = 0
	toggleBtn.AutoButtonColor  = false
	toggleBtn.ZIndex           = 20
	Instance.new("UICorner",toggleBtn).CornerRadius = UDim.new(0,10)
	Instance.new("UIStroke",toggleBtn).Color = CONFIG.Border

	local function toggleTerminal()
		State.visible = not State.visible
		Main.Visible  = State.visible
		if State.visible then InputBox:CaptureFocus() end
	end

	toggleBtn.MouseButton1Click:Connect(toggleTerminal)
	toggleBtn.TouchTap:Connect(toggleTerminal)

	-- Touch drag для toggle button
	local tDrag, tDragStart, tBtnStart = false
	toggleBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.Touch then
			tDrag = true
			tDragStart = Vector2.new(inp.Position.X, inp.Position.Y)
			tBtnStart  = toggleBtn.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if tDrag and inp.UserInputType == Enum.UserInputType.Touch then
			local d = Vector2.new(inp.Position.X,inp.Position.Y) - tDragStart
			if d.Magnitude > 6 then
				toggleBtn.Position = UDim2.new(
					tBtnStart.X.Scale, tBtnStart.X.Offset+d.X,
					tBtnStart.Y.Scale, tBtnStart.Y.Offset+d.Y
				)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.Touch then tDrag = false end
	end)

	-- Автофокус после команды на мобиле
	RunService.Heartbeat:Connect(function()
		if State.visible and not InputBox:IsFocused() then
		end
	end)
end

-- =============================================
-- PC: F9 toggle
-- =============================================
if not CONFIG.isMobile then
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.F9 then
			State.visible = not State.visible
			Main.Visible  = State.visible
			if State.visible then InputBox:CaptureFocus() end
		end
	end)
end

task.spawn(showSplash)
