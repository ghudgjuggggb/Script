--[[
╔══════════════════════════════════════════════════════════════════════╗
║               AuraX Hub  v1.0  —  Universal Roblox Script           ║
║            Works on any game  ·  Rayfield UI  ·  No Key             ║
║   ESP · Fly · SilentAim · WorldEdit · CamMods · ChatLog · More      ║
╚══════════════════════════════════════════════════════════════════════╝
]]

-- ════════════════════════════════════════════════════════════════════
-- §0  GUARD & BOOT
-- ════════════════════════════════════════════════════════════════════
if getgenv().AuraXLoaded then
    warn("[AuraX] Already loaded. Skipping.")
    return
end
getgenv().AuraXLoaded = true

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(0.3)

-- ════════════════════════════════════════════════════════════════════
-- §1  SERVICES
-- ════════════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local CoreGui          = game:GetService("CoreGui")
local Lighting         = game:GetService("Lighting")
local SoundService     = game:GetService("SoundService")
local VirtualUser      = game:GetService("VirtualUser")
local Stats            = game:GetService("Stats")

local LP   = Players.LocalPlayer
local Cam  = workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════════════
-- §2  CONNECTION POOL  (safe cleanup)
-- ════════════════════════════════════════════════════════════════════
local Pool = {}
Pool._c = {}  -- connections
Pool._i = {}  -- instances

function Pool:Add(key, conn)
    if self._c[key] then pcall(function() self._c[key]:Disconnect() end) end
    self._c[key] = conn
end

function Pool:Kill(key)
    if self._c[key] then
        pcall(function() self._c[key]:Disconnect() end)
        self._c[key] = nil
    end
end

function Pool:AddInst(key, inst)
    if self._i[key] then pcall(function() self._i[key]:Destroy() end) end
    self._i[key] = inst
end

function Pool:KillInst(key)
    if self._i[key] then
        pcall(function() self._i[key]:Destroy() end)
        self._i[key] = nil
    end
end

function Pool:Nuke()
    for _, c in pairs(self._c) do pcall(function() c:Disconnect() end) end
    for _, i in pairs(self._i) do pcall(function() i:Destroy() end) end
    self._c = {}; self._i = {}
end

getgenv().AuraXPool = Pool

-- ════════════════════════════════════════════════════════════════════
-- §3  HELPERS
-- ════════════════════════════════════════════════════════════════════
local H = {}

function H.Char()   return LP.Character end
function H.Root()   local c = H.Char(); return c and c:FindFirstChild("HumanoidRootPart") end
function H.Hum()    local c = H.Char(); return c and c:FindFirstChildOfClass("Humanoid") end
function H.Alive()  local h = H.Hum(); return h and h.Health > 0 end

function H.Dist(a, b)
    if typeof(a) == "Instance" then a = a.Position end
    if typeof(b) == "Instance" then b = b.Position end
    if typeof(a) == "CFrame"   then a = a.Position end
    if typeof(b) == "CFrame"   then b = b.Position end
    return (Vector3.new(a.X,a.Y,a.Z) - Vector3.new(b.X,b.Y,b.Z)).Magnitude
end

function H.ScreenPoint(worldPos)
    local sp, onScreen = Cam:WorldToScreenPoint(worldPos)
    return Vector2.new(sp.X, sp.Y), onScreen, sp.Z
end

function H.Notify(title, body, dur, img)
    pcall(function()
        if getgenv()._AuraRayfield then
            getgenv()._AuraRayfield:Notify({
                Title    = title   or "AuraX",
                Content  = body    or "",
                Duration = dur     or 3,
                Image    = img     or 4483362458,
            })
        else
            StarterGui:SetCore("SendNotification", {
                Title = title, Text = body, Duration = dur or 3
            })
        end
    end)
end

function H.Tween(obj, props, t, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

-- FPS counter
local _fps, _fpsLast, _fpsFrames = 0, tick(), 0
Pool:Add("FPSCounter", RunService.RenderStepped:Connect(function()
    _fpsFrames = _fpsFrames + 1
    local now = tick()
    if now - _fpsLast >= 1 then
        _fps = _fpsFrames
        _fpsFrames = 0
        _fpsLast = now
    end
end))

function H.FPS()  return _fps end
function H.Ping() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end

-- ════════════════════════════════════════════════════════════════════
-- §4  STATE  (all toggleable features live here)
-- ════════════════════════════════════════════════════════════════════
local S = {
    -- ESP
    ESPEnabled      = false,
    ESPShowHealth   = true,
    ESPShowDist     = true,
    ESPShowName     = true,
    ESPTeamCheck    = false,
    ESPBoxes        = false,
    ESPMaxDist      = 1000,

    -- Movement
    WalkSpeed       = 16,
    JumpPower       = 50,
    FlyEnabled      = false,
    FlySpeed        = 100,
    InfJump         = false,
    NoClip          = false,
    NoFallDmg       = false,

    -- Combat
    SilentAim       = false,
    SilentAimPart   = "Head",
    HitboxExpand    = false,
    HitboxSize      = 8,
    KillAura        = false,
    KillAuraRange   = 15,

    -- World
    TimeOfDay       = 14,
    FogEnabled      = false,
    FogEnd          = 500,
    AmbientR        = 128, AmbientG = 128, AmbientB = 128,
    Fullbright      = false,
    NoSky           = false,

    -- Camera
    FOV             = 70,
    CamShake        = false,
    ThirdPersonDist = 12.5,

    -- Misc
    AntiAFK         = true,
    AutoRejoin      = false,
    InvisEnabled    = false,
    ChatLogEnabled  = false,
    FPSCapEnabled   = false,
    FPSCap          = 60,
    SpinBot         = false,
    SpinSpeed       = 10,
}

-- ════════════════════════════════════════════════════════════════════
-- §5  ESP SYSTEM
-- ════════════════════════════════════════════════════════════════════
local ESP = {}
ESP._objects = {}   -- [player] = { billboard, bars, labels, conn }

local function makeESPObject(player)
    if ESP._objects[player] then return end
    if player == LP then return end

    local ok = pcall(function()
        -- Container BillboardGui
        local bb = Instance.new("BillboardGui")
        bb.Name            = "AuraESP_" .. player.Name
        bb.AlwaysOnTop     = true
        bb.ResetOnSpawn    = false
        bb.Size            = UDim2.new(0, 120, 0, 50)
        bb.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
        bb.Parent          = CoreGui

        -- Name label
        local nameL = Instance.new("TextLabel", bb)
        nameL.Name                = "NameLabel"
        nameL.Size                = UDim2.new(1, 0, 0, 18)
        nameL.Position            = UDim2.new(0, 0, 0, 0)
        nameL.BackgroundTransparency = 1
        nameL.Font                = Enum.Font.GothamBold
        nameL.TextSize            = 13
        nameL.TextColor3          = Color3.fromRGB(255, 255, 255)
        nameL.TextStrokeTransparency = 0
        nameL.TextStrokeColor3    = Color3.fromRGB(0, 0, 0)
        nameL.Text                = player.Name

        -- Distance label
        local distL = Instance.new("TextLabel", bb)
        distL.Name                = "DistLabel"
        distL.Size                = UDim2.new(1, 0, 0, 14)
        distL.Position            = UDim2.new(0, 0, 0, 18)
        distL.BackgroundTransparency = 1
        distL.Font                = Enum.Font.Gotham
        distL.TextSize            = 11
        distL.TextColor3          = Color3.fromRGB(200, 200, 255)
        distL.TextStrokeTransparency = 0
        distL.TextStrokeColor3    = Color3.fromRGB(0, 0, 0)
        distL.Text                = ""

        -- HP bar background
        local hpBG = Instance.new("Frame", bb)
        hpBG.Name                 = "HPBG"
        hpBG.Size                 = UDim2.new(1, 0, 0, 5)
        hpBG.Position             = UDim2.new(0, 0, 0, 34)
        hpBG.BackgroundColor3     = Color3.fromRGB(40, 40, 40)
        hpBG.BorderSizePixel      = 0

        -- HP bar fill
        local hpFill = Instance.new("Frame", hpBG)
        hpFill.Name               = "HPFill"
        hpFill.Size               = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3   = Color3.fromRGB(80, 220, 100)
        hpFill.BorderSizePixel    = 0

        -- Team color dot
        local dot = Instance.new("Frame", bb)
        dot.Name                  = "TeamDot"
        dot.Size                  = UDim2.new(0, 8, 0, 8)
        dot.Position              = UDim2.new(0, -10, 0, 3)
        dot.BackgroundColor3      = player.TeamColor and player.TeamColor.Color or Color3.fromRGB(255, 80, 80)
        dot.BorderSizePixel       = 0
        local dotCorner = Instance.new("UICorner", dot)
        dotCorner.CornerRadius    = UDim.new(1, 0)

        -- Update connection
        local updateConn = RunService.RenderStepped:Connect(function()
            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local myHRP = H.Root()

            if not char or not hrp or not myHRP then
                bb.Enabled = false
                return
            end

            local dist = H.Dist(myHRP.Position, hrp.Position)

            -- Distance check
            if dist > S.ESPMaxDist then
                bb.Enabled = false
                return
            end

            bb.Enabled  = S.ESPEnabled
            bb.Adornee  = hrp

            -- Team check
            if S.ESPTeamCheck and player.Team == LP.Team then
                bb.Enabled = false
                return
            end

            -- Name
            nameL.Visible = S.ESPShowName
            nameL.Text    = player.Name

            -- Distance
            distL.Visible = S.ESPShowDist
            distL.Text    = math.floor(dist) .. "m"

            -- HP bar
            hpBG.Visible  = S.ESPShowHealth
            if hum then
                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                hpFill.Size = UDim2.new(pct, 0, 1, 0)
                hpFill.BackgroundColor3 = pct > 0.5
                    and Color3.fromRGB(80, 220, 100)
                    or  pct > 0.25
                    and Color3.fromRGB(230, 180, 0)
                    or  Color3.fromRGB(220, 60, 60)
            end

            -- Team dot
            dot.BackgroundColor3 = player.TeamColor and player.TeamColor.Color or Color3.fromRGB(255, 80, 80)
        end)

        ESP._objects[player] = {
            Billboard = bb,
            Conn      = updateConn,
        }
    end)
end

local function removeESPObject(player)
    local obj = ESP._objects[player]
    if obj then
        pcall(function() obj.Conn:Disconnect() end)
        pcall(function() obj.Billboard:Destroy() end)
        ESP._objects[player] = nil
    end
end

function ESP.Enable()
    S.ESPEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do
        makeESPObject(p)
    end
    Pool:Add("ESPJoin", Players.PlayerAdded:Connect(function(p)
        task.wait(1)
        makeESPObject(p)
    end))
    Pool:Add("ESPLeave", Players.PlayerRemoving:Connect(function(p)
        removeESPObject(p)
    end))
end

function ESP.Disable()
    S.ESPEnabled = false
    for p in pairs(ESP._objects) do
        removeESPObject(p)
    end
    Pool:Kill("ESPJoin")
    Pool:Kill("ESPLeave")
end

-- ════════════════════════════════════════════════════════════════════
-- §6  FLY SYSTEM
-- ════════════════════════════════════════════════════════════════════
local Fly = {}
local _flyBG, _flyBV

function Fly.On()
    S.FlyEnabled = true
    local root = H.Root()
    if not root then return end

    -- Remove old
    if _flyBG then pcall(function() _flyBG:Destroy() end) end
    if _flyBV then pcall(function() _flyBV:Destroy() end) end

    _flyBG = Instance.new("BodyGyro")
    _flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    _flyBG.D         = 1500
    _flyBG.P         = 20000
    _flyBG.CFrame    = root.CFrame
    _flyBG.Parent    = root

    _flyBV = Instance.new("BodyVelocity")
    _flyBV.Velocity  = Vector3.zero
    _flyBV.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
    _flyBV.P         = 20000
    _flyBV.Parent    = root

    Pool:Add("FlyStep", RunService.RenderStepped:Connect(function()
        if not S.FlyEnabled then return end
        local r = H.Root(); if not r then return end

        local spd  = S.FlySpeed
        local camCF = Cam.CFrame
        local dir  = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            dir = dir + camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            dir = dir - camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            dir = dir - camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            dir = dir + camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir = dir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            dir = dir - Vector3.new(0, 1, 0)
        end

        _flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
        _flyBG.CFrame   = CFrame.new(r.Position, r.Position + camCF.LookVector)
    end))
end

function Fly.Off()
    S.FlyEnabled = false
    Pool:Kill("FlyStep")
    if _flyBG then pcall(function() _flyBG:Destroy() end); _flyBG = nil end
    if _flyBV then pcall(function() _flyBV:Destroy() end); _flyBV = nil end
    local hum = H.Hum()
    if hum then hum.PlatformStand = false end
end

-- ════════════════════════════════════════════════════════════════════
-- §7  INFINITE JUMP
-- ════════════════════════════════════════════════════════════════════
Pool:Add("InfJump", UserInputService.JumpRequest:Connect(function()
    if not S.InfJump then return end
    local hum = H.Hum()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

-- ════════════════════════════════════════════════════════════════════
-- §8  NOCLIP
-- ════════════════════════════════════════════════════════════════════
Pool:Add("NoClip", RunService.Stepped:Connect(function()
    if not S.NoClip then return end
    local char = H.Char()
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end))

-- ════════════════════════════════════════════════════════════════════
-- §9  NO FALL DAMAGE
-- ════════════════════════════════════════════════════════════════════
Pool:Add("NoFall", RunService.Heartbeat:Connect(function()
    if not S.NoFallDmg then return end
    local hum = H.Hum()
    if hum then hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end
end))

-- ════════════════════════════════════════════════════════════════════
-- §10  SPEED / JUMP LOOP
-- ════════════════════════════════════════════════════════════════════
Pool:Add("SpeedLoop", RunService.Heartbeat:Connect(function()
    local hum = H.Hum()
    if not hum then return end
    if S.WalkSpeed ~= 16 then
        hum.WalkSpeed = S.WalkSpeed
    end
    if S.JumpPower ~= 50 then
        hum.JumpPower = S.JumpPower
    end
end))

-- ════════════════════════════════════════════════════════════════════
-- §11  SILENT AIM
-- ════════════════════════════════════════════════════════════════════
local SilentAim = {}
local _origIndex

local function getClosestPlayerToMouse()
    local mousePos = UserInputService:GetMouseLocation()
    local closest, closestDist = nil, math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character
        if not char then continue end

        local partName = S.SilentAimPart or "Head"
        local part = char:FindFirstChild(partName) or char:FindFirstChildOfClass("BasePart")
        if not part then continue end

        local sp, onScreen = H.ScreenPoint(part.Position)
        if not onScreen then continue end

        local dist = (sp - mousePos).Magnitude
        if dist < closestDist then
            closest = part
            closestDist = dist
        end
    end
    return closest
end

function SilentAim.Enable()
    S.SilentAim = true
    _origIndex = _origIndex or workspace.FindPartOnRay

    local mt = getrawmetatable and getrawmetatable(workspace)
    if mt then
        local oldIndex = rawget(mt, "__index")
        if setreadonly then setreadonly(mt, false) end
        rawset(mt, "__namecall", function(self, ...)
            local method = getnamecallmethod and getnamecallmethod() or ""
            if S.SilentAim and (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay") then
                local target = getClosestPlayerToMouse()
                if target then
                    local args = {...}
                    local ray = args[1]
                    if ray then
                        args[1] = Ray.new(ray.Origin, (target.Position - ray.Origin).Unit * ray.Direction.Magnitude)
                        return oldIndex(self, table.unpack(args))
                    end
                end
            end
            return oldIndex(self, ...)
        end)
        if setreadonly then setreadonly(mt, true) end
    end
end

function SilentAim.Disable()
    S.SilentAim = false
end

-- ════════════════════════════════════════════════════════════════════
-- §12  HITBOX EXPANDER
-- ════════════════════════════════════════════════════════════════════
Pool:Add("HitboxLoop", RunService.Heartbeat:Connect(function()
    if not S.HitboxExpand then return end
    local sz = Vector3.new(S.HitboxSize, S.HitboxSize, S.HitboxSize)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Size = sz end
    end
end))

-- Restore hitboxes when disabled
local _lastHitbox = false
Pool:Add("HitboxRestore", RunService.Heartbeat:Connect(function()
    if _lastHitbox and not S.HitboxExpand then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local char = p.Character
            if not char then continue end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Size = Vector3.new(2, 2, 1) end
        end
    end
    _lastHitbox = S.HitboxExpand
end))

-- ════════════════════════════════════════════════════════════════════
-- §13  KILL AURA
-- ════════════════════════════════════════════════════════════════════
Pool:Add("KillAura", RunService.Heartbeat:Connect(function()
    if not S.KillAura then return end
    local root = H.Root()
    if not root then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end

        if H.Dist(root.Position, hrp.Position) <= S.KillAuraRange then
            -- Use equipped tool
            pcall(function()
                local tool = H.Char():FindFirstChildOfClass("Tool")
                if tool then
                    local re = tool:FindFirstChildOfClass("RemoteEvent")
                    if re then re:FireServer(hrp.CFrame) end
                    local rf = tool:FindFirstChildOfClass("RemoteFunction")
                    if rf then rf:InvokeServer(hrp.CFrame) end
                end
            end)
        end
    end
end))

-- ════════════════════════════════════════════════════════════════════
-- §14  SPIN BOT
-- ════════════════════════════════════════════════════════════════════
local _spinAngle = 0
Pool:Add("SpinBot", RunService.RenderStepped:Connect(function()
    if not S.SpinBot then return end
    local root = H.Root()
    if not root then return end
    _spinAngle = (_spinAngle + S.SpinSpeed) % 360
    root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(_spinAngle), 0)
end))

-- ════════════════════════════════════════════════════════════════════
-- §15  INVISIBILITY
-- ════════════════════════════════════════════════════════════════════
local function setInvis(on)
    S.InvisEnabled = on
    local char = H.Char()
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.LocalTransparencyModifier = on and 1 or 0
        end
        if p:IsA("Decal") then
            p.Transparency = on and 1 or 0
        end
    end
end

-- ════════════════════════════════════════════════════════════════════
-- §16  WORLD EDITOR
-- ════════════════════════════════════════════════════════════════════
local World = {}

function World.SetTime(hour)
    S.TimeOfDay = hour
    Lighting.TimeOfDay = string.format("%02d:00:00", math.clamp(math.floor(hour), 0, 23))
end

function World.SetFullbright(on)
    S.Fullbright = on
    if on then
        Lighting.Ambient          = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient   = Color3.new(1, 1, 1)
        Lighting.Brightness       = 2
        Lighting.GlobalShadows    = false
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("Sky") then
                v.Enabled = false
            end
        end
    else
        Lighting.Ambient          = Color3.fromRGB(127, 127, 127)
        Lighting.OutdoorAmbient   = Color3.fromRGB(127, 127, 127)
        Lighting.Brightness       = 1
        Lighting.GlobalShadows    = true
    end
end

function World.SetFog(on, fogEnd)
    S.FogEnabled = on
    if on then
        Lighting.FogStart = 0
        Lighting.FogEnd   = fogEnd or S.FogEnd
        Lighting.FogColor  = Color3.fromRGB(200, 200, 200)
    else
        Lighting.FogEnd   = 100000
        Lighting.FogStart = 0
    end
end

function World.RemovePostFX()
    for _, v in ipairs(Lighting:GetDescendants()) do
        if v:IsA("PostEffect") then v.Enabled = false end
    end
    H.Notify("World", "Post FX removed", 2)
end

function World.RemoveParticles()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail")
        or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        end
    end
    H.Notify("World", "Particles removed", 2)
end

-- ════════════════════════════════════════════════════════════════════
-- §17  CAMERA MODS
-- ════════════════════════════════════════════════════════════════════
Pool:Add("FOVLoop", RunService.RenderStepped:Connect(function()
    Cam.FieldOfView = S.FOV
end))

local function setCamDist(dist)
    S.ThirdPersonDist = dist
    pcall(function()
        LP.CameraMaxZoomDistance = dist
        LP.CameraMinZoomDistance = dist
    end)
end

-- ════════════════════════════════════════════════════════════════════
-- §18  CHAT LOGGER
-- ════════════════════════════════════════════════════════════════════
local ChatLog = {}
ChatLog._logs = {}

Pool:Add("ChatLog", Players.PlayerAdded:Connect(function(p)
    p.Chatted:Connect(function(msg)
        if not S.ChatLogEnabled then return end
        local entry = {
            Player = p.Name,
            Msg    = msg,
            Time   = os.date("%H:%M:%S"),
        }
        table.insert(ChatLog._logs, 1, entry)
        if #ChatLog._logs > 50 then table.remove(ChatLog._logs) end
    end)
end))

-- Connect existing players
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        Pool:Add("ChatLog_"..p.Name, p.Chatted:Connect(function(msg)
            if not S.ChatLogEnabled then return end
            local entry = {
                Player = p.Name,
                Msg    = msg,
                Time   = os.date("%H:%M:%S"),
            }
            table.insert(ChatLog._logs, 1, entry)
            if #ChatLog._logs > 50 then table.remove(ChatLog._logs) end
            -- Popup notification
            H.Notify("💬 "..p.Name, msg, 4)
        end))
    end
end

-- ════════════════════════════════════════════════════════════════════
-- §19  ANTI-AFK & AUTO-REJOIN
-- ════════════════════════════════════════════════════════════════════
Pool:Add("AntiAFK", LP.Idled:Connect(function()
    if not S.AntiAFK then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end))

Pool:Add("AutoRejoin", LP.OnTeleport:Connect(function(state)
    if not S.AutoRejoin then return end
    if state == Enum.TeleportState.Failed then
        task.wait(5)
        TeleportService:Teleport(game.PlaceId, LP)
    end
end))

-- ════════════════════════════════════════════════════════════════════
-- §20  FPS CAP
-- ════════════════════════════════════════════════════════════════════
Pool:Add("FPSCap", RunService.RenderStepped:Connect(function(dt)
    if not S.FPSCapEnabled then return end
    local target = 1 / S.FPSCap
    if dt < target then
        task.wait(target - dt)
    end
end))

-- ════════════════════════════════════════════════════════════════════
-- §21  SERVER INFO (live HUD)
-- ════════════════════════════════════════════════════════════════════
local InfoHUD = {}
InfoHUD._gui  = nil

function InfoHUD.Create()
    if InfoHUD._gui then pcall(function() InfoHUD._gui:Destroy() end) end

    local sg = Instance.new("ScreenGui")
    sg.Name           = "AuraXHUD"
    sg.ResetOnSpawn   = false
    sg.DisplayOrder   = 10
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent         = (typeof(gethui) == "function" and gethui()) or LP:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", sg)
    frame.Size              = UDim2.new(0, 180, 0, 72)
    frame.Position          = UDim2.new(1, -190, 0, 10)
    frame.BackgroundColor3  = Color3.fromRGB(10, 10, 18)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel   = 0
    local fc = Instance.new("UICorner", frame); fc.CornerRadius = UDim.new(0, 8)
    local fs = Instance.new("UIStroke", frame)
    fs.Color = Color3.fromRGB(120, 80, 255); fs.Thickness = 1.5

    local function addRow(y, label)
        local lbl = Instance.new("TextLabel", frame)
        lbl.Size                 = UDim2.new(1, -8, 0, 14)
        lbl.Position             = UDim2.new(0, 4, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Font                 = Enum.Font.Gotham
        lbl.TextSize             = 11
        lbl.TextColor3           = Color3.fromRGB(200, 200, 255)
        lbl.TextXAlignment       = Enum.TextXAlignment.Left
        lbl.Text                 = label
        return lbl
    end

    local lblTitle   = addRow(4,  "⚡ AuraX Hub v1.0")
    lblTitle.Font    = Enum.Font.GothamBold
    lblTitle.TextColor3 = Color3.fromRGB(160, 120, 255)

    local lblFPS     = addRow(20, "FPS: --")
    local lblPing    = addRow(34, "Ping: --")
    local lblPlayers = addRow(48, "Players: --")
    local lblLevel   = addRow(62, "")

    Pool:Add("HUDUpdate", RunService.RenderStepped:Connect(function()
        pcall(function()
            lblFPS.Text     = "FPS: "    .. H.FPS()
            lblPing.Text    = "Ping: "   .. H.Ping() .. "ms"
            lblPlayers.Text = "Players: " .. #Players:GetPlayers() .. "/" .. LP:GetAttribute("MaxPlayers") or "?"
        end)
    end))

    InfoHUD._gui = sg
    Pool:AddInst("InfoHUD", sg)
end

InfoHUD.Create()

-- ════════════════════════════════════════════════════════════════════
-- §22  TELEPORT TO PLAYER
-- ════════════════════════════════════════════════════════════════════
local function tpToPlayer(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(name:lower()) then
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local myRoot = H.Root()
                if myRoot then
                    myRoot.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
                    H.Notify("Teleport", "→ " .. p.Name, 2)
                    return true
                end
            end
        end
    end
    H.Notify("Teleport", "Player not found", 2)
    return false
end

-- ════════════════════════════════════════════════════════════════════
-- §23  RAYFIELD UI
-- ════════════════════════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
getgenv()._AuraRayfield = Rayfield

local Window = Rayfield:CreateWindow({
    Name            = "⚡ AuraX Hub",
    LoadingTitle    = "AuraX Hub",
    LoadingSubtitle = "Universal Script  ·  v1.0",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "AuraXHub",
        FileName   = "Settings",
    },
    KeySystem = false,
})

-- ────────────────────────────────────────────
-- TAB: PLAYERS / ESP
-- ────────────────────────────────────────────
local TabESP = Window:CreateTab("👁️ ESP", 4483362458)

TabESP:CreateSection("ESP Controls")

TabESP:CreateToggle({
    Name = "Enable ESP", CurrentValue = false, Flag = "ESPEnabled",
    Callback = function(v)
        if v then ESP.Enable() else ESP.Disable() end
    end,
})

TabESP:CreateToggle({
    Name = "Show Name", CurrentValue = true, Flag = "ESPName",
    Callback = function(v) S.ESPShowName = v end,
})

TabESP:CreateToggle({
    Name = "Show Health Bar", CurrentValue = true, Flag = "ESPHealth",
    Callback = function(v) S.ESPShowHealth = v end,
})

TabESP:CreateToggle({
    Name = "Show Distance", CurrentValue = true, Flag = "ESPDist",
    Callback = function(v) S.ESPShowDist = v end,
})

TabESP:CreateToggle({
    Name = "Team Check (hide teammates)", CurrentValue = false, Flag = "ESPTeam",
    Callback = function(v) S.ESPTeamCheck = v end,
})

TabESP:CreateSlider({
    Name = "Max Distance", Range = {50, 2000}, Increment = 50,
    CurrentValue = 1000, Suffix = "m", Flag = "ESPMax",
    Callback = function(v) S.ESPMaxDist = v end,
})

TabESP:CreateSection("Teleport to Player")

local playerNames = {}
local function refreshPlayerList()
    playerNames = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(playerNames, p.Name) end
    end
end
refreshPlayerList()

TabESP:CreateDropdown({
    Name = "Select Player", Options = playerNames,
    CurrentOption = playerNames[1] and {playerNames[1]} or {"—"},
    Flag = "SelPlayer",
    Callback = function(v) end,
})

TabESP:CreateButton({
    Name = "📍 Teleport to Selected Player",
    Callback = function()
        local sel = Rayfield:GetFlag("SelPlayer")
        if sel then tpToPlayer(type(sel)=="table" and sel[1] or sel) end
    end,
})

TabESP:CreateButton({
    Name = "🔄 Refresh Player List",
    Callback = function()
        refreshPlayerList()
        H.Notify("ESP", "Player list refreshed ("..#playerNames..")", 2)
    end,
})

-- ────────────────────────────────────────────
-- TAB: MOVEMENT
-- ────────────────────────────────────────────
local TabMove = Window:CreateTab("⚡ Movement", 4483362458)

TabMove:CreateSection("Speed & Jump")

TabMove:CreateSlider({
    Name = "Walk Speed", Range = {16, 500}, Increment = 4,
    CurrentValue = 16, Flag = "WalkSpeed",
    Callback = function(v)
        S.WalkSpeed = v
        local hum = H.Hum(); if hum then hum.WalkSpeed = v end
    end,
})

TabMove:CreateSlider({
    Name = "Jump Power", Range = {50, 500}, Increment = 10,
    CurrentValue = 50, Flag = "JumpPower",
    Callback = function(v)
        S.JumpPower = v
        local hum = H.Hum(); if hum then hum.JumpPower = v end
    end,
})

TabMove:CreateButton({
    Name = "↩️ Reset Speed & Jump",
    Callback = function()
        S.WalkSpeed = 16; S.JumpPower = 50
        local hum = H.Hum()
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
        H.Notify("Movement", "Speed & Jump reset", 2)
    end,
})

TabMove:CreateSection("Fly")

TabMove:CreateToggle({
    Name = "Fly  [WASD + Space / Ctrl]", CurrentValue = false, Flag = "Fly",
    Callback = function(v)
        if v then Fly.On() else Fly.Off() end
    end,
})

TabMove:CreateSlider({
    Name = "Fly Speed", Range = {20, 500}, Increment = 10,
    CurrentValue = 100, Suffix = " st/s", Flag = "FlySpeed",
    Callback = function(v) S.FlySpeed = v end,
})

TabMove:CreateSection("Extra")

TabMove:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump",
    Callback = function(v) S.InfJump = v end,
})

TabMove:CreateToggle({
    Name = "NoClip (walk through walls)", CurrentValue = false, Flag = "NoClip",
    Callback = function(v) S.NoClip = v end,
})

TabMove:CreateToggle({
    Name = "No Fall Damage", CurrentValue = false, Flag = "NoFall",
    Callback = function(v) S.NoFallDmg = v end,
})

-- ────────────────────────────────────────────
-- TAB: COMBAT
-- ────────────────────────────────────────────
local TabCombat = Window:CreateTab("🎯 Combat", 4483362458)

TabCombat:CreateSection("Silent Aim")

TabCombat:CreateToggle({
    Name = "Silent Aim", CurrentValue = false, Flag = "SilentAim",
    Callback = function(v)
        S.SilentAim = v
        if v then SilentAim.Enable() else SilentAim.Disable() end
    end,
})

TabCombat:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"},
    CurrentOption = {"Head"}, Flag = "AimPart",
    Callback = function(v) S.SilentAimPart = type(v)=="table" and v[1] or v end,
})

TabCombat:CreateSection("Hitbox")

TabCombat:CreateToggle({
    Name = "Hitbox Expander", CurrentValue = false, Flag = "HitboxExpand",
    Callback = function(v) S.HitboxExpand = v end,
})

TabCombat:CreateSlider({
    Name = "Hitbox Size", Range = {2, 30}, Increment = 1,
    CurrentValue = 8, Flag = "HitboxSize",
    Callback = function(v) S.HitboxSize = v end,
})

TabCombat:CreateSection("Kill Aura")

TabCombat:CreateToggle({
    Name = "Kill Aura", CurrentValue = false, Flag = "KillAura",
    Callback = function(v) S.KillAura = v end,
})

TabCombat:CreateSlider({
    Name = "Kill Aura Range", Range = {5, 60}, Increment = 1,
    CurrentValue = 15, Suffix = " st", Flag = "KillRange",
    Callback = function(v) S.KillAuraRange = v end,
})

TabCombat:CreateSection("Spin Bot")

TabCombat:CreateToggle({
    Name = "Spin Bot", CurrentValue = false, Flag = "SpinBot",
    Callback = function(v) S.SpinBot = v end,
})

TabCombat:CreateSlider({
    Name = "Spin Speed", Range = {1, 60}, Increment = 1,
    CurrentValue = 10, Flag = "SpinSpeed",
    Callback = function(v) S.SpinSpeed = v end,
})

-- ────────────────────────────────────────────
-- TAB: WORLD
-- ────────────────────────────────────────────
local TabWorld = Window:CreateTab("🌍 World", 4483362458)

TabWorld:CreateSection("Lighting")

TabWorld:CreateToggle({
    Name = "Fullbright", CurrentValue = false, Flag = "Fullbright",
    Callback = function(v) World.SetFullbright(v) end,
})

TabWorld:CreateSlider({
    Name = "Time of Day", Range = {0, 23}, Increment = 1,
    CurrentValue = 14, Suffix = ":00", Flag = "TimeOfDay",
    Callback = function(v) World.SetTime(v) end,
})

TabWorld:CreateSection("Fog")

TabWorld:CreateToggle({
    Name = "Enable Custom Fog", CurrentValue = false, Flag = "FogOn",
    Callback = function(v) World.SetFog(v, S.FogEnd) end,
})

TabWorld:CreateSlider({
    Name = "Fog Distance", Range = {50, 2000}, Increment = 50,
    CurrentValue = 500, Suffix = " st", Flag = "FogEnd",
    Callback = function(v)
        S.FogEnd = v
        if S.FogEnabled then World.SetFog(true, v) end
    end,
})

TabWorld:CreateSection("Cleanup")

TabWorld:CreateButton({
    Name = "✨ Remove Post FX",
    Callback = function() World.RemovePostFX() end,
})

TabWorld:CreateButton({
    Name = "💥 Remove All Particles",
    Callback = function() World.RemoveParticles() end,
})

-- ────────────────────────────────────────────
-- TAB: CAMERA
-- ────────────────────────────────────────────
local TabCam = Window:CreateTab("📷 Camera", 4483362458)

TabCam:CreateSection("Camera Settings")

TabCam:CreateSlider({
    Name = "Field of View (FOV)", Range = {40, 120}, Increment = 1,
    CurrentValue = 70, Suffix = "°", Flag = "FOV",
    Callback = function(v) S.FOV = v end,
})

TabCam:CreateSlider({
    Name = "Zoom Distance", Range = {5, 100}, Increment = 1,
    CurrentValue = 12, Flag = "ZoomDist",
    Callback = function(v) setCamDist(v) end,
})

TabCam:CreateButton({
    Name = "↩️ Reset Camera",
    Callback = function()
        S.FOV = 70
        setCamDist(12.5)
        Cam.FieldOfView = 70
        H.Notify("Camera", "Reset to defaults", 2)
    end,
})

-- ────────────────────────────────────────────
-- TAB: PLAYER / CHARACTER
-- ────────────────────────────────────────────
local TabChar = Window:CreateTab("🧍 Character", 4483362458)

TabChar:CreateSection("Appearance")

TabChar:CreateToggle({
    Name = "Invisibility", CurrentValue = false, Flag = "Invis",
    Callback = function(v) setInvis(v) end,
})

TabChar:CreateButton({
    Name = "🗑️ Remove Accessories",
    Callback = function()
        local char = H.Char(); if not char then return end
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Accessory") then v:Destroy() end
        end
        H.Notify("Character", "Accessories removed", 2)
    end,
})

TabChar:CreateButton({
    Name = "🔄 Respawn Character",
    Callback = function()
        LP:LoadCharacter()
        H.Notify("Character", "Respawning...", 2)
    end,
})

TabChar:CreateSection("Name Tag")

TabChar:CreateButton({
    Name = "🏷️ Change Display Name (overhead)",
    Callback = function()
        -- Simple overhead tag above head
        local char = H.Char(); if not char then return end
        local head = char:FindFirstChild("Head"); if not head then return end
        local old = head:FindFirstChild("AuraTag")
        if old then old:Destroy() return end
        local bg = Instance.new("BillboardGui", head)
        bg.Name = "AuraTag"
        bg.Size = UDim2.new(0, 100, 0, 20)
        bg.StudsOffset = Vector3.new(0, 2.5, 0)
        bg.AlwaysOnTop = false
        local lbl = Instance.new("TextLabel", bg)
        lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextColor3 = Color3.fromRGB(160, 120, 255)
        lbl.TextStrokeTransparency = 0
        lbl.Text = "⚡ " .. LP.Name
        H.Notify("Character", "Tag toggled", 2)
    end,
})

-- ────────────────────────────────────────────
-- TAB: CHAT LOG
-- ────────────────────────────────────────────
local TabChat = Window:CreateTab("💬 Chat Log", 4483362458)

TabChat:CreateSection("Chat Logger")

TabChat:CreateToggle({
    Name = "Enable Chat Logger", CurrentValue = false, Flag = "ChatLog",
    Callback = function(v) S.ChatLogEnabled = v end,
})

TabChat:CreateLabel("Enable it then check console (F9) for logs.")

TabChat:CreateButton({
    Name = "📋 Print Recent Messages",
    Callback = function()
        if #ChatLog._logs == 0 then
            H.Notify("Chat Log", "No messages captured yet", 2)
            return
        end
        print("─── AuraX Chat Log ───")
        for i, entry in ipairs(ChatLog._logs) do
            print(string.format("[%s] %s: %s", entry.Time, entry.Player, entry.Msg))
            if i >= 20 then break end
        end
        print("─────────────────────")
        H.Notify("Chat Log", "Printed "..math.min(#ChatLog._logs,20).." messages to console", 3)
    end,
})

TabChat:CreateButton({
    Name = "🗑️ Clear Chat Log",
    Callback = function()
        ChatLog._logs = {}
        H.Notify("Chat Log", "Cleared", 2)
    end,
})

-- ────────────────────────────────────────────
-- TAB: MISC
-- ────────────────────────────────────────────
local TabMisc = Window:CreateTab("⚙️ Misc", 4483362458)

TabMisc:CreateSection("Anti & Safety")

TabMisc:CreateToggle({
    Name = "Anti-AFK", CurrentValue = true, Flag = "AntiAFK",
    Callback = function(v) S.AntiAFK = v end,
})

TabMisc:CreateToggle({
    Name = "Auto Rejoin on Kick", CurrentValue = false, Flag = "AutoRejoin",
    Callback = function(v) S.AutoRejoin = v end,
})

TabMisc:CreateSection("Performance")

TabMisc:CreateToggle({
    Name = "FPS Cap", CurrentValue = false, Flag = "FPSCap",
    Callback = function(v) S.FPSCapEnabled = v end,
})

TabMisc:CreateSlider({
    Name = "FPS Limit", Range = {15, 240}, Increment = 5,
    CurrentValue = 60, Suffix = " fps", Flag = "FPSLimit",
    Callback = function(v) S.FPSCap = v end,
})

TabMisc:CreateButton({
    Name = "🗑️ FPS Boost (remove effects)",
    Callback = function()
        World.RemoveParticles()
        World.RemovePostFX()
        pcall(function() settings().Rendering.QualityLevel = 1 end)
        H.Notify("FPS Boost", "Applied! Removed effects.", 3)
    end,
})

TabMisc:CreateSection("Server")

TabMisc:CreateButton({
    Name = "🔄 Rejoin Same Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end,
})

TabMisc:CreateButton({
    Name = "🌐 Hop to New Server",
    Callback = function()
        H.Notify("Server Hop", "Finding new server...", 3)
        task.spawn(function()
            local ok, data = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(
                    "https://games.roblox.com/v1/games/"..game.PlaceId..
                    "/servers/Public?sortOrder=Asc&limit=100"))
            end)
            if ok and data and data.data then
                for _, srv in ipairs(data.data) do
                    if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP)
                        return
                    end
                end
            end
            TeleportService:Teleport(game.PlaceId, LP)
        end)
    end,
})

TabMisc:CreateButton({
    Name = "📋 Copy Place ID",
    Callback = function()
        H.Notify("Info", "Place ID: "..game.PlaceId, 4)
        pcall(function() setclipboard(tostring(game.PlaceId)) end)
    end,
})

TabMisc:CreateSection("Emergency")

TabMisc:CreateButton({
    Name = "🛑 Kill Script (disable all)",
    Callback = function()
        S.ESPEnabled    = false
        S.FlyEnabled    = false
        S.InfJump       = false
        S.NoClip        = false
        S.KillAura      = false
        S.SpinBot       = false
        S.HitboxExpand  = false
        S.SilentAim     = false
        S.InvisEnabled  = false
        ESP.Disable()
        Fly.Off()
        SilentAim.Disable()
        setInvis(false)
        Pool:Nuke()
        getgenv().AuraXLoaded = nil
        H.Notify("AuraX", "Script killed. Re-execute to restart.", 5)
    end,
})

-- ════════════════════════════════════════════════════════════════════
-- §24  FINAL NOTIFY
-- ════════════════════════════════════════════════════════════════════
Rayfield:Notify({
    Title    = "⚡ AuraX Hub v1.0",
    Content  = "Loaded successfully!\nGame: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
    Duration = 5,
    Image    = 4483362458,
})

print("[AuraX Hub] ✅ Loaded | Place: "..game.PlaceId.." | Players: "..#Players:GetPlayers())
