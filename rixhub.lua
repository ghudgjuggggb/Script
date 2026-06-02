repeat task.wait() until game:IsLoaded()

pcall(function() setclipboard("discord.gg/sPCKm8juf") end)

local Luna
local _lunaUrls = {
    "https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua",
    "https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/main/source.lua",
}
local _lunaLoaded = false
for _, url in ipairs(_lunaUrls) do
    if _lunaLoaded then break end
    for attempt = 1, 3 do
        local ok, result = pcall(function()
            local src = game:HttpGet(url, true)
            if not src or src == "" then error("empty") end
            local fn = loadstring(src)
            if type(fn) ~= "function" then error("loadstring nil") end
            return fn()
        end)
        if ok and type(result) == "table" then
            Luna = result
            _lunaLoaded = true
            break
        end
        task.wait(1.5)
    end
end
if not _lunaLoaded or not Luna then
    error("[RixHub] Failed to load UI library after all attempts.")
end

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")
local Lighting           = game:GetService("Lighting")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualUser        = game:GetService("VirtualUser")
local VirtualInputManager= game:GetService("VirtualInputManager")
local TeleportService    = game:GetService("TeleportService")
local Debris             = game:GetService("Debris")
local CoreGui            = game:GetService("CoreGui")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()
if not LP then return end

local UserInputService2  = game:GetService("UserInputService")
local IS_MOBILE          = UserInputService2.TouchEnabled and not UserInputService2.KeyboardEnabled
local IS_FULL_EXECUTOR   = (getrawmetatable ~= nil and setreadonly ~= nil and newcclosure ~= nil)
local IS_PC              = not IS_MOBILE
local PLATFORM           = IS_MOBILE and "Mobile" or "PC"
local EXECUTOR_TYPE      = IS_FULL_EXECUTOR and "Full" or "Limited"

-- ─── ADAPTIVE PERFORMANCE MANAGER ───────────────────────────────
local PERF = {
    fps          = 60,
    quality      = "high",
    hbInterval   = 1,
    espInterval  = 5,
    trajInterval = 2,
}

local _fpsFrames  = 0
local _fpsTimer   = 0
local _fpsMaster  = RunService.Heartbeat:Connect(function(dt)
    _fpsFrames += 1
    _fpsTimer  += dt
    if _fpsTimer >= 1 then
        PERF.fps    = math.floor(_fpsFrames / _fpsTimer)
        _fpsFrames  = 0
        _fpsTimer   = 0
        if PERF.fps >= 50 then
            PERF.quality      = "high"
            PERF.hbInterval   = 1
            PERF.espInterval  = 4
            PERF.trajInterval = 2
        elseif PERF.fps >= 30 then
            PERF.quality      = "medium"
            PERF.hbInterval   = 2
            PERF.espInterval  = 8
            PERF.trajInterval = 3
        else
            PERF.quality      = "low"
            PERF.hbInterval   = 3
            PERF.espInterval  = 12
            PERF.trajInterval = 5
        end
    end
end)

if IS_MOBILE then
    PERF.hbInterval   = 2
    PERF.espInterval  = 8
    PERF.trajInterval = 3
end


local function safeExec(fn)
    if not IS_FULL_EXECUTOR then return end
    pcall(fn)
end

local function requireFull(featureName, fn)
    if not IS_FULL_EXECUTOR then
        Notify(featureName, "Requires full executor (PC). Not supported on Delta iOS.")
        return false
    end
    pcall(fn)
    return true
end

local function mobileGuard()
    return IS_MOBILE
end


local Window = Luna:CreateWindow({
    Name             = "Rix Hub",
    Subtitle         = "v1.0.0 beta",
    LogoID           = "130188918639066",
    LoadingEnabled   = true,
    LoadingTitle     = "Rix Hub",
    LoadingSubtitle  = "v1.0.0 beta",
    ConfigSettings   = { RootFolder = nil, ConfigFolder = "RixHub" },
    KeySystem        = false,
})

local Connections = {}

local SpeedMult       = 1.2
local JumpMult        = 1.3
local SpinSpd         = 15
local FlySpd          = 40
local PlatHeight      = 8
local GravityMult     = 0.5
local airMovementSpeed= 16

local ESPRange        = 5000
local BallESPRange    = 5000
local ReachDistance   = 10
local lineDistance    = 50
local BallHitboxMult  = 5

local IsJumping       = false
local autoShiftLock   = false
local airMovement     = false
local linesEnabled    = false
local powerfulServe   = false
local autoFarm        = false
local autoJoin        = false
local autoSpin        = false
local espJumpEnabled  = false
local AntiCheatEnabled= false
local escPressed      = false

local vbSetting    = false
local vbServing    = false
local vbSpiking    = false
local vbPower      = false
local vbSprint     = false
local vbBlockMode  = false
local vbSpikeMode  = "random"
local vbSetForward = Enum.KeyCode.F
local vbSetBack    = Enum.KeyCode.R
local vbMaxPower   = Enum.KeyCode.C
local vbSprintKey  = Enum.KeyCode.T
local vbChangeMode = Enum.KeyCode.One
local vbLeft, vbRight
local vbRedRCorner, vbRedLCorner, vbBluRCorner, vbBluLCorner
local vbRedSpike, vbBluSpike

local PlatformPart     = nil
local bodyVelocity     = nil
local airBodyVelocity  = nil
local ReachCircle      = nil
local ReachGui         = nil

local ESPObjects       = {}
local BallESPObjects   = {}
local TrajectoryLines  = {}
local OriginalParts    = {}
local lines            = {}
local espHighlights    = {}
local espConnections   = {}
local desiredStyles    = {}

local BlockedRemotes   = {}
local ProtectedPlayers = {}
local LastPos          = nil

local FrameCounter      = 0
local UpdateInterval    = 3
local LastESPUpdate     = 0
local ESPUpdateInterval = 5

local CurrentBall     = nil
local LastBallCheck   = 0

local defaultAmbient       = Lighting.Ambient
local defaultBrightness    = Lighting.Brightness
local defaultOutdoorAmbient= Lighting.OutdoorAmbient
local defaultFogEnd        = Lighting.FogEnd

local bloomEffect           = Instance.new("BloomEffect", Lighting)
bloomEffect.Intensity = 0; bloomEffect.Size = 56; bloomEffect.Threshold = 1

local OriginalWalkSpeed  = 16
local OriginalJumpHeight = 7.2

local function getChar() return LP.Character end
local function getHRP()  local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") or nil end
local function getHum()  local c=getChar() return c and c:FindFirstChildOfClass("Humanoid")  or nil end

local function disconnect(key)
    if Connections[key] then
        pcall(function() Connections[key]:Disconnect() end)
        Connections[key] = nil
    end
end

local function Notify(title, content)
    pcall(function()
        Luna:Notification({ Title=title, Icon="info", ImageSource="Material", Content=content or "" })
    end)
end

local function SafeDestroy(obj)
    pcall(function() if obj and obj.Parent then obj:Destroy() end end)
end

local function CreateGradientFrame(parent, c1, c2)
    pcall(function()
        local g = Instance.new("UIGradient")
        g.Color    = ColorSequence.new({ ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(1,c2) })
        g.Rotation = 45
        g.Parent   = parent
    end)
end

local function FindBall()
    local now = tick()
    if now - LastBallCheck < 0.5 and CurrentBall and CurrentBall.Parent then return CurrentBall end
    LastBallCheck = now; CurrentBall = nil
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:match("^CLIENT_BALL_%d+$") then
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("BasePart") then CurrentBall = child; return CurrentBall end
            end
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if (n:find("ball") or n:find("volleyball") or n:find("sphere"))
               and not n:find("rack") and not n:find("nocollide") and not n:find("collideonly") then
                CurrentBall = obj; break
            end
        end
    end
    return CurrentBall
end

local function getBallModel()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:match("^CLIENT_BALL_%d+$") then
            local part = obj:FindFirstChild("02_Mango_Volleyball")
                      or obj:FindFirstChild("Sphere.001")
                      or obj:FindFirstChild("Cube.001")
            if not part then
                for _, d in ipairs(obj:GetDescendants()) do
                    if d:IsA("BasePart") then part = d; break end
                end
            end
            return part
        end
    end
    return nil
end

local function findFirstPart(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
end

local ballHitboxEnabled   = false
local ballHitboxLoopAlive = false
local originalBallSizes   = {}
local managedModelBalls   = {}
local ballChildAddedConn  = nil

local function applyBallHitboxToModel(model)
    if not (model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$")) then return end
    if model:FindFirstChild("RixBall") then return end
    local base = nil
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then base = d; break end
    end
    if not base then return end
    local hb        = Instance.new("Part")
    hb.Name         = "RixBall"
    hb.Shape        = Enum.PartType.Ball
    hb.Size         = Vector3.new(1,1,1) * BallHitboxMult
    hb.CFrame       = base.CFrame
    hb.Anchored     = false
    hb.CanCollide   = false
    hb.Transparency = 0.5
    hb.Material     = Enum.Material.ForceField
    hb.Color        = Color3.fromRGB(0, 255, 100)
    hb.Massless     = true
    local weld      = Instance.new("WeldConstraint")
    weld.Part0      = base
    weld.Part1      = hb
    weld.Parent     = hb
    hb.Parent       = model
    table.insert(managedModelBalls, hb)
end

local function applyBallHitboxToPart(ball)
    if not ball or not ball:IsA("BasePart") then return end
    if originalBallSizes[ball] then return end
    originalBallSizes[ball] = {
        size         = ball.Size,
        transparency = ball.Transparency,
        material     = ball.Material,
        color        = ball.Color,
    }
    ball.Size         = ball.Size * BallHitboxMult
    ball.Transparency = 0.45
    ball.Material     = Enum.Material.Neon
    ball.Color        = Color3.fromRGB(255, 50, 50)
end

local function restoreAllBalls()
    for _, hb in ipairs(managedModelBalls) do
        if hb and hb.Parent then hb:Destroy() end
    end
    managedModelBalls = {}
    for ball, props in pairs(originalBallSizes) do
        if ball and ball.Parent then
            ball.Size         = props.size
            ball.Transparency = props.transparency
            ball.Material     = props.material
            ball.Color        = props.color
        end
    end
    originalBallSizes = {}
end

local function enableBallHitbox()
    if ballHitboxLoopAlive then return end
    ballHitboxLoopAlive = true
    for _, child in ipairs(Workspace:GetChildren()) do
        task.defer(function() applyBallHitboxToModel(child) end)
    end
    local part = FindBall()
    if part then applyBallHitboxToPart(part) end
    if ballChildAddedConn then ballChildAddedConn:Disconnect() end
    ballChildAddedConn = Workspace.ChildAdded:Connect(function(child)
        if not ballHitboxEnabled then return end
        task.delay(0.2, function()
            if ballHitboxEnabled then applyBallHitboxToModel(child) end
        end)
    end)
    task.spawn(function()
        local lastBall = nil
        while ballHitboxLoopAlive do
            task.wait(3)
            if not ballHitboxEnabled then break end
            pcall(function()
                local ball = FindBall()
                if ball and ball ~= lastBall and not originalBallSizes[ball] then
                    lastBall = ball
                    applyBallHitboxToPart(ball)
                end
            end)
        end
    end)
end

local function disableBallHitbox()
    ballHitboxLoopAlive = false
    if ballChildAddedConn then ballChildAddedConn:Disconnect(); ballChildAddedConn = nil end
    restoreAllBalls()
end

local function setHitboxSize(name, value)
    pcall(function()
        local hitbox = ReplicatedStorage.Assets.Hitboxes:FindFirstChild(name)
        if hitbox then
            local part = hitbox:FindFirstChild("Part")
            if part and part:IsA("BasePart") then
                part.Size = Vector3.new(value, value, value)
            end
        end
    end)
end

local function lookAt(chr, target)
    if chr and chr.PrimaryPart and target then
        chr:SetPrimaryPartCFrame(CFrame.new(chr.PrimaryPart.Position, target.Position))
    end
end

local function lookAway(chr, target)
    if chr and chr.PrimaryPart and target then
        chr:SetPrimaryPartCFrame(CFrame.new(chr.PrimaryPart.Position, target.Position))
        chr.HumanoidRootPart.CFrame = chr.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(180), 0)
    end
end

local function placeAntennas()
    pcall(function()
        vbLeft  = Instance.new("Part"); vbRight = Instance.new("Part")
        vbLeft.Name  = "RixLeft";  vbRight.Name  = "RixRight"
        vbLeft.Transparency  = 1;  vbRight.Transparency  = 1
        vbLeft.Position  = Vector3.new(-23.789, 8, 0.007)
        vbRight.Position = Vector3.new(23.783,  8, -0.006)
        vbLeft.Size  = Vector3.new(1.607, 1, 2)
        vbRight.Size = Vector3.new(1.607, 1, 2)
        vbLeft.CanCollide  = false; vbRight.CanCollide  = false
        vbLeft.Anchored    = true;  vbRight.Anchored    = true
        vbLeft.Parent  = Workspace; vbRight.Parent = Workspace
    end)
end

local function removeAntennas()
    for _, v in ipairs(Workspace:GetChildren()) do
        if v.Name == "RixLeft" or v.Name == "RixRight" then v:Destroy() end
    end
    vbLeft = nil; vbRight = nil
end

local function placeServeCorners()
    pcall(function()
        vbRedRCorner = Instance.new("Part"); vbRedLCorner = Instance.new("Part")
        vbBluRCorner = Instance.new("Part"); vbBluLCorner = Instance.new("Part")
        vbRedRCorner.Name="RixRedRight"; vbRedLCorner.Name="RixRedLeft"
        vbBluRCorner.Name="RixBluRight"; vbBluLCorner.Name="RixBluLeft"
        vbRedRCorner.Position = Vector3.new(23.479,  0.638, -47.059)
        vbRedLCorner.Position = Vector3.new(-23.577, 0.633, -47.059)
        vbBluRCorner.Position = Vector3.new(-23.577, 0.633,  46.936)
        vbBluLCorner.Position = Vector3.new(23.483,  0.628,  46.936)
        for _, p in ipairs({vbRedRCorner, vbRedLCorner, vbBluRCorner, vbBluLCorner}) do
            p.Size = Vector3.new(1.048, 0.076, 1.07)
            p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Parent = Workspace
        end
    end)
end

local function removeServeCorners()
    for _, v in ipairs(Workspace:GetChildren()) do
        if v.Name:find("RixRed") or v.Name:find("RixBlu") then v:Destroy() end
    end
    vbRedRCorner=nil; vbRedLCorner=nil; vbBluRCorner=nil; vbBluLCorner=nil
end

local function placeSpikeZones()
    pcall(function()
        vbRedSpike = Instance.new("Part"); vbRedSpike.Name = "RixRedSpike"
        vbRedSpike.Anchored = true; vbRedSpike.CanCollide = false
        vbRedSpike.Position = Vector3.new(-0.009, 0.501, -23.927)
        vbRedSpike.Size     = Vector3.new(47.936, 0.001, 46.988)
        vbRedSpike.Transparency = 1; vbRedSpike.Parent = Workspace
        vbBluSpike = Instance.new("Part"); vbBluSpike.Name = "RixBluSpike"
        vbBluSpike.Anchored = true; vbBluSpike.CanCollide = false
        vbBluSpike.Position = Vector3.new(-0.009, 0.501, 23.984)
        vbBluSpike.Size     = Vector3.new(47.936, 0.001, 46.988)
        vbBluSpike.Transparency = 1; vbBluSpike.Parent = Workspace
    end)
end

local function removeSpikeZones()
    for _, v in ipairs(Workspace:GetChildren()) do
        if v.Name == "RixRedSpike" or v.Name == "RixBluSpike" then v:Destroy() end
    end
    vbRedSpike=nil; vbBluSpike=nil
end

local function startRoundOverChecker()
    task.spawn(function()
        while true do
            task.wait(0.5)
            pcall(function()
                local roundOverStats = LP.PlayerGui.Interface.RoundOverStats
                if roundOverStats and roundOverStats.Visible then
                    if not escPressed then
                        escPressed = true
                        task.wait(5)
                        sendKey(true, Enum.KeyCode.Escape)
                        sendKey(false, Enum.KeyCode.Escape)
                        task.wait(0.3)
                        sendKey(true, Enum.KeyCode.Escape)
                        sendKey(false, Enum.KeyCode.Escape)
                    end
                else
                    escPressed = false
                end
            end)
        end
    end)
end

local lineColors = {
    Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255),
    Color3.fromRGB(255,165,0), Color3.fromRGB(128,0,128), Color3.fromRGB(255,255,0),
}

local function removeLine(player)
    local data = lines[player]
    if data then
        if data.beam then pcall(function() data.beam:Destroy() end) end
        if data.target and data.target.Parent then pcall(function() data.target:Destroy() end) end
        if data.attachment and data.attachment.Parent then pcall(function() data.attachment:Destroy() end) end
        lines[player] = nil
    end
end

local function updateLine(player, index)
    if not linesEnabled then removeLine(player); return end
    local char = player.Character
    if not char or not char:FindFirstChild("Head") then removeLine(player); return end
    local head     = char.Head
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then removeLine(player); return end
    if not lines[player] then
        local attachment       = Instance.new("Attachment", head)
        local target           = Instance.new("Part")
        target.Anchored        = true; target.CanCollide = false; target.Transparency = 1
        target.Size            = Vector3.new(0.1,0.1,0.1); target.Parent = Workspace
        local targetAttachment = Instance.new("Attachment", target)
        local beam             = Instance.new("Beam")
        beam.Attachment0       = attachment; beam.Attachment1 = targetAttachment
        beam.Width0            = 0.25; beam.Width1 = 0.25; beam.FaceCamera = true
        beam.LightEmission     = 1; beam.Transparency = NumberSequence.new(0.3)
        beam.Color             = ColorSequence.new(lineColors[((index-1)%#lineColors)+1])
        beam.Parent            = head
        lines[player] = { beam=beam, target=target, attachment=attachment }
    end
    lines[player].target.Position = head.Position + rootPart.CFrame.LookVector * lineDistance
end

local function applyJumpESP(player)
    if not player.Character or espHighlights[player] then return end
    local hl = Instance.new("Highlight")
    hl.Name               = "JumpESP"; hl.Adornee = player.Character
    hl.FillTransparency   = 1; hl.OutlineTransparency = 0
    hl.OutlineColor       = Color3.fromRGB(255,255,0)
    hl.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent             = player.Character
    espHighlights[player] = hl
end

local function removeJumpESP(player)
    if espHighlights[player] then espHighlights[player]:Destroy(); espHighlights[player] = nil end
end

local function setupJumpESP(player)
    if player == LP then return end
    local function onChar(char)
        if espConnections[player] then
            for _, c in pairs(espConnections[player]) do pcall(function() c:Disconnect() end) end
        end
        espConnections[player] = nil
        removeJumpESP(player)
        local hum = char:WaitForChild("Humanoid", 3)
        if not hum then return end
        local c1 = hum.StateChanged:Connect(function(_, newState)
            if not espJumpEnabled then return end
            local isEnemy = player.Team ~= nil and LP.Team ~= nil and player.Team ~= LP.Team
            if isEnemy then
                if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
                    applyJumpESP(player)
                elseif newState == Enum.HumanoidStateType.Landed then
                    removeJumpESP(player)
                end
            else
                removeJumpESP(player)
            end
        end)
        espConnections[player] = {c1}
    end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

local _acActive    = false
local _acOldNC     = nil
local _acOldFire   = nil
local _acOldInvoke = nil

local function sendKey(down, key)
    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(down, key, false, game)
        end
    end)
end

local function sendClick(down)
    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, down, game, 1)
        end
    end)
end


local _acBlockList = {
    "kick","ban","anticheat","anti_cheat","anti cheat",
    "detect","hack","exploit","flag","punish","security",
    "stun","ragdoll","verify","validate","report","sanity",
    "integrity","watchdog","monitor","alert","violation","suspect",
    "speedcheck","positioncheck","velocitycheck","flyhack",
    "nocliphack","godmode","teleport_block","unauthorized",
}

local function _isBlocked(name)
    local n = name:lower():gsub("[%s%-_]","")
    for _, kw in ipairs(_acBlockList) do
        if n:find(kw, 1, true) then return true end
    end
    return false
end

local function SetupAntiCheatBypass()
    if _acActive then return end
    _acActive = true
    pcall(function() LP.Kick = function() end end)
    if not IS_FULL_EXECUTOR then
        Notify("AC Bypass","Limited mode - full executor not detected")
        return
    end
    pcall(function()
        if not getrawmetatable then return end
        local mt = getrawmetatable(game)
        if not mt then return end
        _acOldNC = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args   = {...}
            if method == "Kick" then
                if self == LP or (LP.Character and self == LP.Character) then return nil end
            end
            if method == "FireServer" or method == "InvokeServer" then
                local name = tostring(self)
                if _isBlocked(name) then
                    if not BlockedRemotes[name] then BlockedRemotes[name] = true end
                    return nil
                end
                if method == "FireServer" and args[1] ~= nil then
                    local a1 = tostring(args[1]):lower()
                    if a1:find("kick") or a1:find("ban") or a1:find("flag") then return nil end
                end
            end
            if method == "Destroy" then
                if self == LP or (LP.Character and self:IsDescendantOf(LP.Character)) then return nil end
            end
            return _acOldNC(self, ...)
        end)
        setreadonly(mt, true)
    end)
    pcall(function()
        if not hookfunction then return end
        local mt   = getrawmetatable(game)
        if not mt  then return end
        local orig = mt.__index
        setreadonly(mt, false)
        mt.__index = newcclosure(function(self, key)
            if (self == LP or (LP.Character and self == LP.Character)) then
                if key == "Kick" or key == "Remove" or key == "Destroy" then
                    return function() end
                end
            end
            return orig(self, key)
        end)
        setreadonly(mt, true)
    end)
    pcall(function()
        if not hookmetamethod then return end
        hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" and self == LP then return nil end
            if (method == "FireServer" or method == "InvokeServer") then
                if _isBlocked(tostring(self)) then return nil end
            end
            return self[method](self, ...)
        end))
    end)
end

local function CreateReachCircle()
    pcall(function()
        if ReachGui then SafeDestroy(ReachGui) end
        ReachGui = Instance.new("ScreenGui")
        ReachGui.Name = "RixReachGui"; ReachGui.ResetOnSpawn = false
        ReachGui.IgnoreGuiInset = true; ReachGui.Parent = LP.PlayerGui
        ReachCircle = Instance.new("Frame")
        ReachCircle.AnchorPoint          = Vector2.new(0.5, 0.5)
        ReachCircle.Position             = UDim2.new(0.5, 0, 0.5, 0)
        ReachCircle.Size                 = UDim2.new(0, ReachDistance*8, 0, ReachDistance*8)
        ReachCircle.BackgroundTransparency = 0.85
        ReachCircle.BackgroundColor3     = Color3.fromRGB(0, 255, 200)
        ReachCircle.BorderSizePixel      = 0; ReachCircle.Parent = ReachGui
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = ReachCircle
        local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(0,255,200); stroke.Thickness = 2; stroke.Parent = ReachCircle
        local label  = Instance.new("TextLabel")
        label.Size                 = UDim2.new(1,0,0,20); label.Position = UDim2.new(0,0,1,5)
        label.BackgroundTransparency = 1; label.TextColor3 = Color3.fromRGB(0,255,200)
        label.TextSize = 14; label.Font = Enum.Font.GothamBold
        label.Text     = tostring(ReachDistance).." studs"; label.Parent = ReachCircle
    end)
end

local function UpdateReachCircle()
    pcall(function()
        if ReachCircle then
            ReachCircle.Size = UDim2.new(0, ReachDistance*8, 0, ReachDistance*8)
            local label = ReachCircle:FindFirstChildOfClass("TextLabel")
            if label then label.Text = tostring(ReachDistance).." studs" end
        end
    end)
end

local function DestroyReachCircle()
    SafeDestroy(ReachGui); ReachCircle=nil; ReachGui=nil
end

local function setupCharacterAir(character)
    local hum = character:WaitForChild("Humanoid", 5)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hum or not hrp then return end
    airMovementSpeed = hum.WalkSpeed
    hum:GetPropertyChangedSignal("Jump"):Connect(function()
        if hum.Jump and autoShiftLock then
            task.defer(function()
                task.wait(0.03)
                local cam = Workspace:FindFirstChildOfClass("Camera")
                if cam then
                    local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
                    if look.Magnitude > 0 then
                        hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + look.Unit)
                        hum.AutoRotate = false
                    end
                end
            end)
        else
            hum.AutoRotate = true
        end
    end)
    hum.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Freefall and airMovement then
            if not airBodyVelocity then
                airBodyVelocity          = Instance.new("BodyVelocity")
                airBodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5)
                airBodyVelocity.Velocity = Vector3.zero
                airBodyVelocity.P        = 2500
                airBodyVelocity.Name     = "AirControlVelocity"
                airBodyVelocity.Parent   = hrp
            end
        elseif newState == Enum.HumanoidStateType.Landed then
            if airBodyVelocity then airBodyVelocity:Destroy(); airBodyVelocity = nil end
            hum.AutoRotate = true
        end
    end)
end

if LP.Character then setupCharacterAir(LP.Character) end
LP.CharacterAdded:Connect(setupCharacterAir)

local _rsTick = 0
RunService.RenderStepped:Connect(function()
    _rsTick += 1
    if airMovement and airBodyVelocity and LP.Character then
        local hum = LP.Character:FindFirstChild("Humanoid")
        if hum then airBodyVelocity.Velocity = hum.MoveDirection * airMovementSpeed end
    end
    if linesEnabled and _rsTick % PERF.hbInterval == 0 then
        local idx = 0
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then
                local sameTeam = LP.Team ~= nil and player.Team ~= nil and player.Team == LP.Team
                if not sameTeam then idx = idx + 1; updateLine(player, idx)
                else removeLine(player) end
            end
        end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do setupJumpESP(p) end
Players.PlayerAdded:Connect(function(p)
    setupJumpESP(p)
    if AntiCheatEnabled then ProtectedPlayers[p.Name] = true end
end)
Players.PlayerRemoving:Connect(removeLine)

CoreGui.ChildAdded:Connect(function(child)
    if child:IsA("ScreenGui") and child.Name == "ErrorPrompt" then
        task.wait(2)
        pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
    end
end)

if LP.Character then Mouse.TargetFilter = LP.Character end
LP.CharacterAdded:Connect(function(char) Mouse.TargetFilter = char end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Z and powerfulServe then
        pcall(function()
            ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.GameService.RF.Serve:InvokeServer(Vector3.new(0,0,0), math.huge)
        end)
    end
    if input.KeyCode == Enum.KeyCode.Space and vbPower then
        pcall(function() sendKey(true, vbMaxPower) end)
    end
    if input.KeyCode == vbSetForward and vbSetting then
        local char = LP.Character
        if char then
            if LP.TeamColor == BrickColor.new("Really blue") then lookAt(char, vbLeft)
            else lookAt(char, vbRight) end
        end
    end
    if input.KeyCode == vbSetBack and vbSetting then
        local char = LP.Character
        if char then
            if LP.TeamColor == BrickColor.new("Really red") then lookAway(char, vbLeft)
            else lookAway(char, vbRight) end
        end
    end
    if input.KeyCode == Enum.KeyCode.Space and vbServing then
        local char  = LP.Character
        local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
        if torso then
            if torso.Position.Z > 40 and LP.TeamColor == BrickColor.new("Really blue") then
                local r = math.random(1,2)
                lookAt(char, r==1 and vbRedRCorner or vbRedLCorner)
            elseif torso.Position.Z < -40 and LP.TeamColor == BrickColor.new("Really red") then
                local r = math.random(1,2)
                lookAt(char, r==1 and vbBluRCorner or vbBluLCorner)
            end
        end
    end
    if input.KeyCode == Enum.KeyCode.Space and vbSpiking then
        if vbBlockMode then return end
        local char  = LP.Character
        local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
        if torso then
            if vbSpikeMode == "random" then
                if LP.TeamColor == BrickColor.new("Really blue") and torso.Position.Z < 40 and vbRedSpike then
                    local rP = Instance.new("Part")
                    rP.Anchored=true; rP.Transparency=1; rP.CanCollide=false
                    local range=20
                    rP.Position = vbRedSpike.Position + Vector3.new(math.random(-range,range),10,math.random(-range,range))
                    rP.Parent = Workspace; lookAt(char, rP); rP:Destroy()
                elseif LP.TeamColor == BrickColor.new("Really red") and torso.Position.Z > -40 and vbBluSpike then
                    local rP = Instance.new("Part")
                    rP.Anchored=true; rP.Transparency=1; rP.CanCollide=false
                    local range=20
                    rP.Position = vbBluSpike.Position + Vector3.new(math.random(-range,range),10,math.random(-range,range))
                    rP.Parent = Workspace; lookAt(char, rP); rP:Destroy()
                end
            elseif vbSpikeMode == "point" then
                if (LP.TeamColor==BrickColor.new("Really blue") and torso.Position.Z < 40) or
                   (LP.TeamColor==BrickColor.new("Really red")  and torso.Position.Z > -40) then
                    local p = Instance.new("Part")
                    p.Anchored=true; p.CanCollide=false
                    p.CFrame=CFrame.new(Mouse.Hit.X, 10, Mouse.Hit.Z)
                    p.Transparency=1; p.Parent=Workspace; lookAt(char, p); p:Destroy()
                end
            end
        end
    end
    if input.KeyCode == vbChangeMode then
        vbBlockMode = not vbBlockMode
        Notify("Mode", vbBlockMode and "Block Mode" or "Spike Mode")
    end
    if (input.KeyCode==Enum.KeyCode.W or input.KeyCode==Enum.KeyCode.A or
        input.KeyCode==Enum.KeyCode.S or input.KeyCode==Enum.KeyCode.D) and vbSprint then
        pcall(function()
            sendKey(true, vbSprintKey)
            task.wait(0.1)
            sendKey(true, vbSprintKey)
            task.wait(0.1)
            sendKey(true, vbSprintKey)
        end)
    end
end)

local enablejoin = false
local joinRF     = nil

local function getJoinRF()
    if joinRF then return joinRF end
    local ok, rf = pcall(function()
        return ReplicatedStorage
            :WaitForChild("Packages", 5)
            :WaitForChild("_Index", 5)
            :WaitForChild("sleitnick_knit@1.7.0", 5)
            :WaitForChild("knit", 5)
            :WaitForChild("Services", 5)
            :WaitForChild("GameService", 5)
            :WaitForChild("RF", 5)
            :WaitForChild("RequestJoin", 5)
    end)
    if ok and rf then joinRF = rf end
    return joinRF
end

local function teamSelection()
    task.spawn(function()
        local rf = getJoinRF()
        if not rf then Notify("Auto Join","[X] RF not found!"); enablejoin=false; return end
        Notify("Auto Join","[?] Scanning teams...")
        while enablejoin do
            for slot = 1, 6 do
                if not enablejoin then return end
                local ok, res = pcall(function() return rf:InvokeServer(1, slot) end)
                if ok and res then Notify("Auto Join","[OK] Team 1 | Slot "..slot); enablejoin=false; return end
                task.wait(0.2)
            end
            if not enablejoin then return end
            for slot = 1, 6 do
                if not enablejoin then return end
                local ok, res = pcall(function() return rf:InvokeServer(2, slot) end)
                if ok and res then Notify("Auto Join","[OK] Team 2 | Slot "..slot); enablejoin=false; return end
                task.wait(0.2)
            end
            task.wait(0.5)
        end
    end)
end

startRoundOverChecker()

local TVolleyball  = Window:CreateTab({ Name="Game Modes",  Icon="sports_volleyball", ImageSource="Material", ShowTitle=true })
local TMovement    = Window:CreateTab({ Name="Movement",    Icon="directions_run",    ImageSource="Material", ShowTitle=true })
local TAutoFarm    = Window:CreateTab({ Name="Auto Farm",   Icon="agriculture",       ImageSource="Material", ShowTitle=true })
local TAutoSpin    = Window:CreateTab({ Name="Auto Spin",   Icon="sync",              ImageSource="Material", ShowTitle=true })
local TPower       = Window:CreateTab({ Name="Powers",      Icon="bolt",              ImageSource="Material", ShowTitle=true })
local THitboxes    = Window:CreateTab({ Name="Hitboxes",    Icon="open_with",         ImageSource="Material", ShowTitle=true })
local TVisuals     = Window:CreateTab({ Name="Visuals",     Icon="visibility",        ImageSource="Material", ShowTitle=true })
local TProtection  = Window:CreateTab({ Name="Protection",  Icon="security",          ImageSource="Material", ShowTitle=true })
local TCodes       = Window:CreateTab({ Name="Codes",       Icon="redeem",            ImageSource="Material", ShowTitle=true })
local TAbout       = Window:CreateTab({ Name="About",       Icon="info",              ImageSource="Material", ShowTitle=true })
local TPerf        = Window:CreateTab({ Name="Performance",  Icon="speed",             ImageSource="Material", ShowTitle=true })

TVolleyball:CreateSection("Game Modes")

TVolleyball:CreateToggle({
    Name="Setting Mode (F=Forward / R=Back)", CurrentValue=false,
    Callback=function(v)
        vbSetting = v
        if v then placeAntennas(); Notify("Setting","ON - F=forward R=back")
        else removeAntennas(); Notify("Setting","OFF") end
    end
})

TVolleyball:CreateToggle({
    Name="Serving Mode (auto aim corners)", CurrentValue=false,
    Callback=function(v)
        vbServing = v
        if v then placeServeCorners(); Notify("Serving","ON")
        else removeServeCorners(); Notify("Serving","OFF") end
    end
})

TVolleyball:CreateToggle({
    Name="Spiking Mode", CurrentValue=false,
    Callback=function(v)
        vbSpiking = v
        if v then placeSpikeZones(); Notify("Spiking","ON")
        else removeSpikeZones(); Notify("Spiking","OFF") end
    end
})

TVolleyball:CreateDropdown({
    Name="Spike Mode", Options={"random","point"}, CurrentOption={"random"}, MultipleOptions=false,
    Callback=function(option)
        vbSpikeMode = type(option)=="table" and option[1] or option
        Notify("Spike Mode", vbSpikeMode)
    end
})

TVolleyball:CreateDivider()

TVolleyball:CreateToggle({
    Name="Power Mode (auto max power on jump)", CurrentValue=false,
    Callback=function(v) vbPower=v; Notify("Power Mode",v and "ON" or "OFF") end
})

TVolleyball:CreateToggle({
    Name="Sprint Mode (auto sprint on WASD)", CurrentValue=false,
    Callback=function(v) vbSprint=v; Notify("Sprint Mode",v and "ON" or "OFF") end
})

TVolleyball:CreateDivider()
TVolleyball:CreateSection("Keybind Settings")

TVolleyball:CreateDropdown({
    Name="Set Forward Key", Options={"F","R","E","Q","G","H","X","Z"}, CurrentOption={"F"}, MultipleOptions=false,
    Callback=function(opt)
        local k=type(opt)=="table" and opt[1] or opt
        vbSetForward=Enum.KeyCode[k] or Enum.KeyCode.F; Notify("Set Forward",k)
    end
})

TVolleyball:CreateDropdown({
    Name="Set Backward Key", Options={"R","F","E","Q","G","H","X","Z"}, CurrentOption={"R"}, MultipleOptions=false,
    Callback=function(opt)
        local k=type(opt)=="table" and opt[1] or opt
        vbSetBack=Enum.KeyCode[k] or Enum.KeyCode.R; Notify("Set Backward",k)
    end
})

TVolleyball:CreateDropdown({
    Name="Max Power Key", Options={"C","V","B","X","Z","G","H"}, CurrentOption={"C"}, MultipleOptions=false,
    Callback=function(opt)
        local k=type(opt)=="table" and opt[1] or opt
        vbMaxPower=Enum.KeyCode[k] or Enum.KeyCode.C; Notify("Max Power Key",k)
    end
})

TVolleyball:CreateDropdown({
    Name="Sprint Key", Options={"T","Y","U","G","H","B"}, CurrentOption={"T"}, MultipleOptions=false,
    Callback=function(opt)
        local k=type(opt)=="table" and opt[1] or opt
        vbSprintKey=Enum.KeyCode[k] or Enum.KeyCode.T; Notify("Sprint Key",k)
    end
})

TVolleyball:CreateDivider()
TVolleyball:CreateSection("Ball Prediction")

-- ═══════════════════════════════════════════════════════════
--   TRAJECTORY SYSTEM v3  —  smooth static line
-- ═══════════════════════════════════════════════════════════
local SEG_POOL_SIZE   = 80

local _trajActive     = false
local _trajConn       = nil
local _trajShowLand   = true
local _trajShowOpt    = true
local _trajAutoPos    = false
local _trajMaxT       = 4
local _trajBounces    = 1

local _tBall          = nil
local _tBallLast      = 0
local _tSegPool       = {}
local _tLandPart      = nil
local _tLandLbl       = nil
local _tOptPart       = nil
local _tOptLbl        = nil

local _tPosBuffer     = {}
local _tTimeBuffer    = {}
local _tBufLen        = 0
local _tBufSize       = 10
local _tPrevVel       = Vector3.zero
local _tHitThresh     = 8

local _tLineFolder    = nil

-- ── Ball finder ─────────────────────────────────────────────
local function _tFindBall()
    local now = tick()
    if _tBall and _tBall.Parent and _tBall:IsDescendantOf(Workspace) and (now - _tBallLast) < 2 then
        return _tBall
    end
    _tBallLast = now
    _tBall     = nil
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:match("^CLIENT_BALL_%d+$") then
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("BasePart") then _tBall = child; return _tBall end
            end
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if (n:find("ball") or n:find("volley") or n:find("sphere"))
               and not n:find("rack") and not n:find("nocollide") and not n:find("collideonly") then
                if obj.Size.Magnitude > 0.3 and obj.Size.Magnitude < 14 then
                    _tBall = obj; return _tBall
                end
            end
        end
    end
    return nil
end

-- ── Weighted velocity from buffer ───────────────────────────
local function _tPushPos(pos, t)
    _tBufLen += 1
    local idx          = ((_tBufLen - 1) % _tBufSize) + 1
    _tPosBuffer[idx]   = pos
    _tTimeBuffer[idx]  = t
end

local function _tGetVel()
    if _tBufLen < 3 then return Vector3.zero end
    local count  = math.min(_tBufLen, _tBufSize)
    local velSum = Vector3.zero
    local wSum   = 0
    for i = 1, count - 1 do
        local ia = ((_tBufLen - i - 1) % _tBufSize) + 1
        local ib = ((_tBufLen - i    ) % _tBufSize) + 1
        local dt = _tTimeBuffer[ib] - _tTimeBuffer[ia]
        if dt > 0.001 then
            local w  = math.exp(-(i - 1) * 0.5)
            velSum  += (_tPosBuffer[ib] - _tPosBuffer[ia]) / dt * w
            wSum    += w
        end
    end
    return wSum > 0 and velSum / wSum or Vector3.zero
end

-- ── RK4 physics ─────────────────────────────────────────────
local function _tRK4(p, v, dt, g)
    local gv = Vector3.new(0, -g, 0)
    local nv = v + gv * dt
    local np = p + v * dt + gv * (0.5 * dt * dt)
    return np, nv
end

-- ── High-density simulation ──────────────────────────────────
local function _tSim(p0, v0, g, maxT, gy, maxB)
    local pts = {}
    local p, v = p0, v0
    local t    = 0
    local bc   = 0
    local lp, lt = nil, nil
    local dt   = 0.04

    while t <= maxT and #pts < SEG_POOL_SIZE + 2 do
        pts[#pts+1] = Vector3.new(p.X, p.Y, p.Z)
        local np, nv = _tRK4(p, v, dt, g)

        if np.Y <= gy and v.Y < 0 then
            local frac = math.clamp((p.Y - gy) / math.max(p.Y - np.Y, 0.001), 0, 1)
            if not lp then
                lp = p:Lerp(np, frac)
                lt = t + dt * frac
            end
            bc += 1
            if bc >= maxB then break end
            nv = Vector3.new(nv.X * 0.55, math.abs(nv.Y) * 0.4, nv.Z * 0.55)
            np = Vector3.new(np.X, gy + 0.01, np.Z)
        end
        p = np; v = nv; t = t + dt
    end
    return pts, lp, lt
end

-- ── Segment part pool ────────────────────────────────────────
local function _tInitPool()
    _tLineFolder = Instance.new("Folder")
    _tLineFolder.Name   = "RixTrajLine"
    _tLineFolder.Parent = Workspace

    for i = 1, SEG_POOL_SIZE do
        local s           = Instance.new("Part")
        s.Name            = "TS"..i
        s.Anchored        = true
        s.CanCollide      = false
        s.CastShadow      = false
        s.Material        = Enum.Material.Neon
        s.Transparency    = 1
        s.Size            = Vector3.new(0.12, 0.12, 1)
        s.Parent          = _tLineFolder
        _tSegPool[i]      = s
    end
end

local function _tMakeMarker(col, sz)
    local p           = Instance.new("Part")
    p.Shape           = Enum.PartType.Ball
    p.Size            = Vector3.new(sz, sz, sz)
    p.Anchored        = true
    p.CanCollide      = false
    p.CastShadow      = false
    p.Material        = Enum.Material.Neon
    p.Color           = col
    p.Transparency    = 1
    p.Parent          = _tLineFolder

    local bb          = Instance.new("BillboardGui")
    bb.Size           = UDim2.new(0, 120, 0, 28)
    bb.MaxDistance    = 500
    bb.AlwaysOnTop    = true
    bb.Adornee        = p
    bb.Parent         = p

    local lbl         = Instance.new("TextLabel", bb)
    lbl.Size          = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3    = Color3.new(1,1,1)
    lbl.Font          = Enum.Font.GothamBold
    lbl.TextSize      = 12
    lbl.TextStrokeTransparency = 0.3
    lbl.Text          = ""
    return p, lbl
end

local function _tHideAll()
    for i = 1, SEG_POOL_SIZE do
        if _tSegPool[i] then _tSegPool[i].Transparency = 1 end
    end
    if _tLandPart then _tLandPart.Transparency = 1 end
    if _tOptPart  then _tOptPart.Transparency  = 1 end
end

-- ── Draw full static line ────────────────────────────────────
local function _tDrawLine(pts, lPos, lT, vel, ball)
    if not pts or #pts < 2 then _tHideAll(); return end

    local count    = math.min(#pts - 1, SEG_POOL_SIZE)
    local stride   = math.max(1, math.floor((#pts - 1) / count))
    local segIdx   = 0

    for i = 1, #pts - 1, stride do
        segIdx += 1
        if segIdx > SEG_POOL_SIZE then break end
        local va  = pts[i]
        local vb  = pts[math.min(i + stride, #pts)]
        local len = (va - vb).Magnitude
        if len < 0.02 then
            _tSegPool[segIdx].Transparency = 1
        else
            local frac   = (i - 1) / math.max(#pts - 1, 1)
            local seg    = _tSegPool[segIdx]
            seg.Size         = Vector3.new(0.12, 0.12, len)
            seg.Transparency = math.clamp(0.05 + frac * 0.6, 0, 0.9)
            seg.Color        = Color3.fromRGB(
                math.floor(frac * 255),
                math.floor((1 - frac) * 180 + frac * 80),
                math.floor((1 - frac) * 255)
            )
            seg.CFrame = CFrame.lookAt((va + vb) * 0.5, vb)
        end
    end

    for i = segIdx + 1, SEG_POOL_SIZE do
        _tSegPool[i].Transparency = 1
    end

    if _trajShowLand and lPos then
        _tLandPart.CFrame      = CFrame.new(lPos)
        _tLandPart.Transparency = 0.15
        if _tLandLbl then
            _tLandLbl.Text = "LAND " .. (lT and string.format("%.1fs", lT) or "?")
        end
    else
        if _tLandPart then _tLandPart.Transparency = 1 end
    end

    if _trajShowOpt then
        local hrp = getHRP()
        if hrp then
            local grav   = Workspace.Gravity
            local bestP, bestT, bestS = nil, nil, math.huge
            local t2     = 0.05
            while t2 <= _trajMaxT do
                local np2, _ = _tRK4(ball.Position, vel, t2, grav)
                if np2.Y < 0.2 then break end
                local pd = (hrp.Position - np2).Magnitude
                local hs = math.abs(np2.Y - hrp.Position.Y - 2.8)
                local sc = pd * 0.3 + hs
                if sc < bestS then
                    bestS = sc
                    bestP = Vector3.new(np2.X, np2.Y - 0.8, np2.Z)
                    bestT = t2
                end
                t2 += 0.05
            end
            if bestP then
                _tOptPart.CFrame      = CFrame.new(bestP)
                _tOptPart.Transparency = 0.15
                if _tOptLbl then
                    _tOptLbl.Text = "HIT " .. (bestT and string.format("%.1fs", bestT) or "?")
                end
                if _trajAutoPos then
                    local dist = (hrp.Position - bestP).Magnitude
                    if dist > 2.5 then
                        local hum = getHum()
                        if hum then hum:MoveTo(bestP) end
                    end
                end
            else
                _tOptPart.Transparency = 1
            end
        else
            _tOptPart.Transparency = 1
        end
    else
        if _tOptPart then _tOptPart.Transparency = 1 end
    end
end

-- ── Destroy ──────────────────────────────────────────────────
local function _tDestroyAll()
    if _tLineFolder and _tLineFolder.Parent then _tLineFolder:Destroy() end
    _tLineFolder  = nil
    _tSegPool     = {}
    _tLandPart    = nil
    _tLandLbl     = nil
    _tOptPart     = nil
    _tOptLbl      = nil
    _tBufLen      = 0
    _tPrevVel     = Vector3.zero
end

local function _trajStop()
    _trajActive = false
    if _trajConn then _trajConn:Disconnect(); _trajConn = nil end
    _tDestroyAll()
end

local function _trajStart()
    _trajStop()
    _trajActive  = true
    _tInitPool()

    _tLandPart, _tLandLbl = _tMakeMarker(Color3.fromRGB(255, 60, 60),  1.6)
    _tOptPart,  _tOptLbl  = _tMakeMarker(Color3.fromRGB(60, 255, 140), 1.2)

    local _frameSkip = 0
    _trajConn = RunService.Heartbeat:Connect(function()
        _frameSkip += 1
        if _frameSkip % 2 ~= 0 then return end

        local ball = _tFindBall()
        if not ball then
            _tHideAll(); _tBufLen = 0; return
        end

        _tPushPos(ball.Position, tick())
        local vel = _tGetVel()
        local spd = vel.Magnitude

        if spd < 0.5 then
            _tHideAll(); return
        end

        local velDiff = (vel - _tPrevVel).Magnitude
        if velDiff < 1.5 and _tBufLen > 4 then return end
        _tPrevVel = vel

        local grav        = Workspace.Gravity
        local pts, lp, lt = _tSim(ball.Position, vel, grav, _trajMaxT, 0.4, _trajBounces + 1)
        _tDrawLine(pts, lp, lt, vel, ball)
    end)
end

TVolleyball:CreateToggle({
    Name="Ball Trajectory + Prediction", CurrentValue=false,
    Callback=function(v)
        if v then _trajStart(); Notify("Trajectory","ON")
        else      _trajStop();  Notify("Trajectory","OFF") end
    end
})

TVolleyball:CreateToggle({
    Name="Show Landing Marker", CurrentValue=true,
    Callback=function(v) _trajShowLand = v end
})

TVolleyball:CreateToggle({
    Name="Show Optimal Hit Marker", CurrentValue=true,
    Callback=function(v) _trajShowOpt = v end
})

TVolleyball:CreateToggle({
    Name="Auto Move to Hit Point", CurrentValue=false,
    Callback=function(v) _trajAutoPos = v end
})

TVolleyball:CreateSlider({
    Name="Prediction Time (s)", Range={1,8}, Increment=0.5, CurrentValue=4,
    Callback=function(v) _trajMaxT = v end
})

TVolleyball:CreateSlider({
    Name="Max Bounces", Range={0,3}, Increment=1, CurrentValue=1,
    Callback=function(v) _trajBounces = v end
})

TVolleyball:CreateSlider({
    Name="Hit Sensitivity", Range={1,20}, Increment=1, CurrentValue=8,
    Callback=function(v) _tHitThresh = v end
})


TMovement:CreateSection("Speed")

TMovement:CreateToggle({
    Name="Speed Boost", CurrentValue=false,
    Callback=function(v)
        disconnect("Speed")
        if v then
            local _speedTick = 0
            Connections.Speed = RunService.Heartbeat:Connect(function()
                _speedTick += 1; if _speedTick % PERF.hbInterval ~= 0 then return end
                local hum = getHum()
                if hum then hum.WalkSpeed = OriginalWalkSpeed * SpeedMult end
            end)
            Notify("Speed","x"..string.format("%.1f",SpeedMult))
        else
            local hum = getHum()
            if hum then hum.WalkSpeed = OriginalWalkSpeed end
            Notify("Speed","OFF")
        end
    end
})

TMovement:CreateSlider({ Name="Speed Multiplier", Range={1,5}, Increment=0.1, CurrentValue=1.2, Callback=function(v) SpeedMult=v end })
TMovement:CreateDivider()

TMovement:CreateToggle({
    Name="Jump Boost", CurrentValue=false,
    Callback=function(v)
        disconnect("Jump")
        if v then
            local _jumpTick = 0
            Connections.Jump = RunService.Heartbeat:Connect(function()
                _jumpTick += 1; if _jumpTick % PERF.hbInterval ~= 0 then return end
                local hum = getHum(); if hum then hum.JumpHeight = OriginalJumpHeight * JumpMult end
            end)
            Notify("Jump","x"..string.format("%.1f",JumpMult))
        else
            local hum = getHum(); if hum then hum.JumpHeight = OriginalJumpHeight end
            Notify("Jump","OFF")
        end
    end
})

TMovement:CreateSlider({ Name="Jump Multiplier", Range={1,5}, Increment=0.1, CurrentValue=1.3, Callback=function(v) JumpMult=v end })
TMovement:CreateDivider()

TMovement:CreateToggle({
    Name="Infinite Jump", CurrentValue=false,
    Callback=function(v)
        disconnect("InfiniteJump"); disconnect("InfiniteJumpEnd"); IsJumping=false
        if v then
            Connections.InfiniteJump = UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.KeyCode == Enum.KeyCode.Space and not IsJumping then
                    IsJumping = true
                    local hrp = getHRP(); local hum = getHum()
                    if hrp and hum then
                        if hum.FloorMaterial == Enum.Material.Air then
                            local bv = Instance.new("BodyVelocity")
                            bv.MaxForce = Vector3.new(0,math.huge,0); bv.Velocity = Vector3.new(0,30,0); bv.Parent = hrp
                            Debris:AddItem(bv, 0.1)
                        end
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
            Connections.InfiniteJumpEnd = UserInputService.InputEnded:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Space then IsJumping = false end
            end)
            Notify("Infinite Jump","ON")
        else
            IsJumping = false; Notify("Infinite Jump","OFF")
        end
    end
})

TMovement:CreateDivider()
TMovement:CreateSection("Character Mods")

TMovement:CreateToggle({
    Name="Auto Shift Lock", CurrentValue=false,
    Callback=function(v) autoShiftLock=v; Notify("Shift Lock",v and "ON" or "OFF") end
})

TMovement:CreateToggle({
    Name="Air Movement (Freeflight)", CurrentValue=false,
    Callback=function(v)
        airMovement = v
        if not v and airBodyVelocity then airBodyVelocity:Destroy(); airBodyVelocity=nil end
        Notify("Air Movement",v and "ON" or "OFF")
    end
})

TMovement:CreateSlider({ Name="Air Movement Speed", Range={0,100}, Increment=1, CurrentValue=16, Callback=function(v) airMovementSpeed=v end })
TMovement:CreateDivider()

TMovement:CreateToggle({
    Name="Gravity Mod", CurrentValue=false,
    Callback=function(v)
        disconnect("Gravity")
        if v then
            local _gravTick = 0
            Connections.Gravity = RunService.Heartbeat:Connect(function()
                _gravTick += 1; if _gravTick % PERF.hbInterval ~= 0 then return end
                local hrp = getHRP()
                if hrp then
                    local vel = hrp.Velocity
                    if vel.Y < -5 then hrp.Velocity = Vector3.new(vel.X, vel.Y*GravityMult, vel.Z) end
                end
            end)
            Notify("Gravity","x"..GravityMult)
        else
            Notify("Gravity","OFF")
        end
    end
})

TMovement:CreateSlider({ Name="Gravity Multiplier", Range={0.1,1}, Increment=0.1, CurrentValue=0.5, Callback=function(v) GravityMult=v end })
TMovement:CreateDivider()

TMovement:CreateToggle({
    Name="Anti Stun", CurrentValue=false,
    Callback=function(v)
        disconnect("AntiStun")
        if v then
            local _stunTick = 0
            Connections.AntiStun = RunService.Heartbeat:Connect(function()
                _stunTick += 1; if _stunTick % PERF.hbInterval ~= 0 then return end
                local hum = getHum()
                if hum then
                    if hum.PlatformStand then hum.PlatformStand = false end
                    local state = hum:GetState()
                    if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end
            end)
            Notify("Anti Stun","ON")
        else
            Notify("Anti Stun","OFF")
        end
    end
})

TMovement:CreateToggle({
    Name="Anti Ragdoll", CurrentValue=false,
    Callback=function(v)
        disconnect("AntiRagdoll")
        if v then
            local _ragTick = 0
            Connections.AntiRagdoll = RunService.Heartbeat:Connect(function()
                _ragTick += 1; if _ragTick % PERF.hbInterval ~= 0 then return end
                local char = getChar(); if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BallSocketConstraint") or part:IsA("HingeConstraint") then SafeDestroy(part) end
                end
                local hum = getHum()
                if hum then
                    if hum.PlatformStand then hum.PlatformStand = false end
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
            Notify("Anti Ragdoll","ON")
        else
            Notify("Anti Ragdoll","OFF")
        end
    end
})

TMovement:CreateDivider()

TMovement:CreateToggle({
    Name="Enable Rotate In Air", CurrentValue=false,
    Callback=function(v)
        disconnect("RotateAir")
        if v then
            local _rotateTick = 0
            Connections.RotateAir = RunService.Heartbeat:Connect(function()
                _rotateTick += 1; if _rotateTick % PERF.hbInterval ~= 0 then return end
                local hum = getHum(); if hum and not hum.AutoRotate then hum.AutoRotate = true end
            end)
            Notify("Rotate Air","ON")
        else
            Notify("Rotate Air","OFF")
        end
    end
})

TMovement:CreateDivider()

TMovement:CreateToggle({
    Name="Spin Mod", CurrentValue=false,
    Callback=function(v)
        disconnect("Spin")
        if v then
            local _spinTick = 0
            Connections.Spin = RunService.Heartbeat:Connect(function()
                _spinTick += 1; if _spinTick % PERF.hbInterval ~= 0 then return end
                local hrp = getHRP()
                if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SpinSpd), 0) end
            end)
            Notify("Spin","Speed "..SpinSpd)
        else
            Notify("Spin","OFF")
        end
    end
})

TMovement:CreateSlider({ Name="Spin Speed", Range={1,150}, Increment=1, CurrentValue=15, Callback=function(v) SpinSpd=v end })
TMovement:CreateDivider()

TMovement:CreateToggle({
    Name="Fly Mode (WASD+Space/Ctrl)", CurrentValue=false,
    Callback=function(v)
        disconnect("Fly")
        if v then
            local hrp = getHRP()
            if hrp then
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Parent   = hrp
                bodyVelocity.MaxForce = Vector3.new(999999,999999,999999)
                bodyVelocity.Velocity = Vector3.new(0,0,0)
            end
            Connections.Fly = RunService.Heartbeat:Connect(function()
                local hrp2 = getHRP(); if not hrp2 or not bodyVelocity then return end
                local move = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W)            then move = move + hrp2.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A)            then move = move - hrp2.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S)            then move = move - hrp2.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D)            then move = move + hrp2.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space)        then move = move + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)  then move = move - Vector3.new(0,1,0) end
                bodyVelocity.Velocity = move.Magnitude > 0 and move.Unit * FlySpd or Vector3.new(0,0,0)
            end)
            Notify("Fly","WASD+Space/Ctrl")
        else
            SafeDestroy(bodyVelocity); bodyVelocity = nil; Notify("Fly","OFF")
        end
    end
})

TMovement:CreateSlider({ Name="Fly Speed", Range={10,100}, Increment=1, CurrentValue=40, Callback=function(v) FlySpd=v end })
TMovement:CreateDivider()

TMovement:CreateToggle({
    Name="Smart Platform", CurrentValue=false,
    Callback=function(v)
        disconnect("Platform")
        if v then
            if not PlatformPart then
                PlatformPart = Instance.new("Part"); PlatformPart.Name = "RixPlatform"
                PlatformPart.Size = Vector3.new(8,1,8); PlatformPart.CanCollide = true
                PlatformPart.Material = Enum.Material.Neon; PlatformPart.BrickColor = BrickColor.new("Cyan")
                PlatformPart.Anchored = true; PlatformPart.Transparency = 0.3; PlatformPart.Parent = Workspace
            end
            local _platTick = 0
            Connections.Platform = RunService.Heartbeat:Connect(function()
                _platTick += 1; if _platTick % PERF.hbInterval ~= 0 then return end
                local hrp = getHRP()
                if hrp and PlatformPart then
                    PlatformPart.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - PlatHeight, hrp.Position.Z)
                end
            end)
            Notify("Platform","ON")
        else
            SafeDestroy(PlatformPart); PlatformPart = nil; Notify("Platform","OFF")
        end
    end
})

TMovement:CreateSlider({ Name="Platform Height", Range={3,20}, Increment=1, CurrentValue=8, Callback=function(v) PlatHeight=v end })

local farmFlySpeed   = 60
local farmHitDist    = 12
local farmPredictMul = 0.35
local farmAutoJump   = true
local farmAutoClick  = true
local farmFlyBV      = nil
local farmHitMode    = "auto"
local farmKeySpike   = Enum.KeyCode.Q
local farmKeyBump    = Enum.KeyCode.E
local farmKeyDive    = Enum.KeyCode.R
local farmKeySet     = Enum.KeyCode.F

local function predictBallPos(ball, seconds)
    local vel  = ball.Velocity
    local grav = Workspace.Gravity
    return ball.Position + vel * seconds + Vector3.new(0, -0.5 * grav * seconds * seconds, 0)
end

local function farmFlyCreate()
    local hrp = getHRP(); if not hrp then return end
    if farmFlyBV then pcall(function() farmFlyBV:Destroy() end) end
    farmFlyBV          = Instance.new("BodyVelocity")
    farmFlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    farmFlyBV.Velocity = Vector3.new(0, 0, 0)
    farmFlyBV.P        = 5000
    farmFlyBV.Name     = "FarmFlyBV"
    farmFlyBV.Parent   = hrp
end

local function farmFlyDestroy()
    if farmFlyBV then pcall(function() farmFlyBV:Destroy() end); farmFlyBV = nil end
end

local function farmFlyTo(targetPos)
    local hrp = getHRP(); if not hrp or not farmFlyBV then return end
    local dir  = targetPos - hrp.Position
    local dist = dir.Magnitude
    if dist < 0.5 then farmFlyBV.Velocity = Vector3.new(0,0,0); return end
    local speed = math.min(farmFlySpeed, dist * 6)
    farmFlyBV.Velocity = dir.Unit * speed
    local lookDir = Vector3.new(dir.X, 0, dir.Z)
    if lookDir.Magnitude > 0.1 then
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + lookDir.Unit)
    end
end

local function pressHitKey(mode)
    local key
    if mode=="spike" then key=farmKeySpike
    elseif mode=="bump" then key=farmKeyBump
    elseif mode=="dive" then key=farmKeyDive
    elseif mode=="set"  then key=farmKeySet end
    if key then
        pcall(function()
            sendKey(true, key)
            task.wait(0.05)
            sendKey(false, key)
        end)
    end
end

local function getBestHitMode(ball, hrp)
    if not ball or not hrp then return "bump" end
    local ballY = ball.Position.Y
    local myY   = hrp.Position.Y
    local diff  = ballY - myY
    local speed = ball.Velocity.Magnitude
    if diff > 6 and speed > 10 then return "spike"
    elseif diff < -1 then return "dive"
    elseif diff > 2 and speed < 10 then return "set"
    else return "bump" end
end

local function getTargetOffset(mode)
    if mode=="spike" then return Vector3.new(0,4,0)
    elseif mode=="bump" then return Vector3.new(0,-2,0)
    elseif mode=="dive" then return Vector3.new(0,0,0)
    elseif mode=="set"  then return Vector3.new(0,1,0) end
    return Vector3.new(0,2,0)
end

local farmAimEnemy = true

local function findNearestEnemy(hrp)
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local isEnemy = (LP.Team == nil) or (player.Team ~= nil and player.Team ~= LP.Team)
            if isEnemy then
                local char = player.Character
                if char then
                    local eHRP = char:FindFirstChild("HumanoidRootPart")
                    local eHum = char:FindFirstChildOfClass("Humanoid")
                    if eHRP and eHum and eHum.Health > 0 then
                        local d = (eHRP.Position - hrp.Position).Magnitude
                        if d < bestDist then bestDist = d; best = eHRP end
                    end
                end
            end
        end
    end
    return best
end

local function getEnemyZoneDir(hrp)
    if not hrp then return Vector3.new(0,0,1) end
    return hrp.Position.Z < 0 and Vector3.new(0,0,1) or Vector3.new(0,0,-1)
end

local function getSpikeApproachPos(ball, hrp)
    if not ball then return hrp.Position end
    local enemyDir = getEnemyZoneDir(hrp)
    return ball.Position - enemyDir * 3 + Vector3.new(0, 4, 0)
end

local hitStats = {
    spike = { attempts=0, weight=1.0 },
    bump  = { attempts=0, weight=1.0 },
    dive  = { attempts=0, weight=1.0 },
    set   = { attempts=0, weight=1.0 },
}

local hitHistory    = {}
local maxHistory    = 40
local adaptEnabled  = true

local function recordHit(mode, ball, hrp)
    if not ball or not hrp then return end
    table.insert(hitHistory, {
        mode    = mode,
        ballVelY= ball.Velocity.Y,
        ballSpd = ball.Velocity.Magnitude,
        dist    = (ball.Position - hrp.Position).Magnitude,
        diffY   = ball.Position.Y - hrp.Position.Y,
        time    = tick(),
    })
    if #hitHistory > maxHistory then table.remove(hitHistory, 1) end
    hitStats[mode].attempts += 1
end

local function analyseHistory()
    if #hitHistory < 4 then return end
    for m,_ in pairs(hitStats) do hitStats[m].weight = 0.5 end
    local recent = {}
    for i = math.max(1, #hitHistory - 20), #hitHistory do
        local e = hitHistory[i]; recent[e.mode] = (recent[e.mode] or 0) + 1
    end
    local minCount, minMode = math.huge, "bump"
    for m,_ in pairs(hitStats) do
        local c = recent[m] or 0
        if c < minCount then minCount=c; minMode=m end
    end
    hitStats[minMode].weight = 1.5
    local last = hitHistory[#hitHistory]
    if last then
        if last.ballVelY > 2 and last.diffY > 4 then hitStats.spike.weight += 0.8
        elseif last.ballVelY < -1 and last.diffY < 0 then hitStats.dive.weight += 0.8
        elseif last.ballSpd < 8 and last.diffY > 1 then hitStats.set.weight += 0.8
        else hitStats.bump.weight += 0.6 end
    end
end

local function selectBestMode(ball, hrp)
    local base = getBestHitMode(ball, hrp)
    if not adaptEnabled then return base end
    local total = 0
    for _, s in pairs(hitStats) do total += s.attempts end
    if total > 0 and total % 8 == 0 then analyseHistory() end
    if farmHitMode == "auto" then
        local r = math.random() * (hitStats[base].weight + 0.5)
        if r < hitStats[base].weight then return base end
        local best2, bestW = base, 0
        for m, s in pairs(hitStats) do if s.weight > bestW then bestW=s.weight; best2=m end end
        return best2
    end
    return farmHitMode
end

TAutoFarm:CreateSection("Auto Farm Settings")

TAutoFarm:CreateDropdown({
    Name="Hit Mode", Options={"auto","spike","bump","dive","set"}, CurrentOption={"auto"}, MultipleOptions=false,
    Callback=function(opt) farmHitMode=type(opt)=="table" and opt[1] or opt; Notify("Farm Mode",farmHitMode) end
})

TAutoFarm:CreateToggle({
    Name="Aim at Enemy on Spike", CurrentValue=true,
    Callback=function(v) farmAimEnemy=v; Notify("Aim Enemy",v and "ON" or "OFF") end
})

TAutoFarm:CreateToggle({
    Name="Adaptive Hit System", CurrentValue=true,
    Callback=function(v)
        adaptEnabled=v
        if not v then for m,_ in pairs(hitStats) do hitStats[m].weight=1.0 end end
        Notify("Adaptive System",v and "ON" or "OFF - weights reset")
    end
})

TAutoFarm:CreateSlider({ Name="Farm Fly Speed", Range={10,200}, Increment=5, CurrentValue=60, Callback=function(v) farmFlySpeed=v end })
TAutoFarm:CreateSlider({ Name="Hit Distance",   Range={5,30},   Increment=1, CurrentValue=12, Callback=function(v) farmHitDist=v end })
TAutoFarm:CreateSlider({ Name="Ball Prediction (seconds)", Range={0,1}, Increment=0.05, CurrentValue=0.35, Callback=function(v) farmPredictMul=v end })

TAutoFarm:CreateDivider()
TAutoFarm:CreateSection("Hit Keys")

TAutoFarm:CreateDropdown({ Name="Spike Key", Options={"Q","E","R","F","G","H","X","Z","V"}, CurrentOption={"Q"}, MultipleOptions=false,
    Callback=function(opt) local k=type(opt)=="table" and opt[1] or opt; farmKeySpike=Enum.KeyCode[k] or Enum.KeyCode.Q end })
TAutoFarm:CreateDropdown({ Name="Bump Key",  Options={"E","Q","R","F","G","H","X","Z","V"}, CurrentOption={"E"}, MultipleOptions=false,
    Callback=function(opt) local k=type(opt)=="table" and opt[1] or opt; farmKeyBump=Enum.KeyCode[k]  or Enum.KeyCode.E end })
TAutoFarm:CreateDropdown({ Name="Dive Key",  Options={"R","Q","E","F","G","H","X","Z","V"}, CurrentOption={"R"}, MultipleOptions=false,
    Callback=function(opt) local k=type(opt)=="table" and opt[1] or opt; farmKeyDive=Enum.KeyCode[k]  or Enum.KeyCode.R end })
TAutoFarm:CreateDropdown({ Name="Set Key",   Options={"F","Q","E","R","G","H","X","Z","V"}, CurrentOption={"F"}, MultipleOptions=false,
    Callback=function(opt) local k=type(opt)=="table" and opt[1] or opt; farmKeySet=Enum.KeyCode[k]   or Enum.KeyCode.F end })

TAutoFarm:CreateDivider()
TAutoFarm:CreateSection("Auto Farm")

TAutoFarm:CreateToggle({ Name="Auto Jump on hit",   CurrentValue=true, Callback=function(v) farmAutoJump=v  end })
TAutoFarm:CreateToggle({ Name="Auto Click on hit",  CurrentValue=true, Callback=function(v) farmAutoClick=v end })

TAutoFarm:CreateToggle({
    Name="Auto Farm", CurrentValue=false,
    Callback=function(v)
        autoFarm = v
        if v then
            farmFlyCreate()
            task.spawn(function()
                local lastHitTime = 0
                local hitCooldown = 0.55
                local stuckTimer  = 0
                local lastFarmPos = Vector3.new(0,0,0)
                while autoFarm do
                    task.wait(IS_MOBILE and 0.08 or 0.05)
                    pcall(function()
                        local hrp  = getHRP(); local hum = getHum()
                        if not hrp or not hum then return end
                        local ball = getBallModel() or FindBall()
                        if not ball then
                            if farmFlyBV then farmFlyBV.Velocity = Vector3.new(0,0,0) end; return
                        end
                        local mode      = selectBestMode(ball, hrp)
                        local targetPos
                        if mode == "spike" then
                            targetPos = getSpikeApproachPos(ball, hrp)
                        else
                            targetPos = predictBallPos(ball, farmPredictMul) + getTargetOffset(mode)
                        end
                        local dist = (ball.Position - hrp.Position).Magnitude
                        if (hrp.Position - lastFarmPos).Magnitude < 0.3 and dist > farmHitDist + 3 then
                            stuckTimer += 0.05
                        else
                            stuckTimer = 0
                        end
                        lastFarmPos = hrp.Position
                        if stuckTimer > 1.0 then
                            stuckTimer = 0; hrp.CFrame = CFrame.new(targetPos + Vector3.new(0,2,0))
                        else
                            farmFlyTo(targetPos)
                        end
                        local now = tick()
                        if dist <= farmHitDist and (now - lastHitTime) >= hitCooldown then
                            lastHitTime = now
                            if mode == "spike" and farmAimEnemy then
                                local enemyHRP = findNearestEnemy(hrp)
                                if enemyHRP then
                                    local dir = Vector3.new(enemyHRP.Position.X-hrp.Position.X,0,enemyHRP.Position.Z-hrp.Position.Z)
                                    if dir.Magnitude > 0.1 then hrp.CFrame = CFrame.new(hrp.Position, hrp.Position+dir.Unit) end
                                else
                                    local dir = getEnemyZoneDir(hrp)
                                    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position+dir)
                                end
                            else
                                local lookDir = Vector3.new(ball.Position.X-hrp.Position.X,0,ball.Position.Z-hrp.Position.Z)
                                if lookDir.Magnitude > 0.1 then hrp.CFrame = CFrame.new(hrp.Position,hrp.Position+lookDir.Unit) end
                            end
                            local needJump = (mode=="spike" or mode=="set")
                            if farmAutoJump and needJump then
                                sendKey(true, Enum.KeyCode.Space)
                                task.wait(0.08)
                                sendKey(false, Enum.KeyCode.Space)
                                task.wait(0.05)
                            end
                            pressHitKey(mode)
                            if farmAutoClick then
                                task.wait(0.04)
                                sendClick(true)
                                task.wait(0.04)
                                sendClick(false)
                            end
                            recordHit(mode, ball, hrp)
                        end
                    end)
                end
                farmFlyDestroy()
            end)
            Notify("Auto Farm","ON | mode: "..farmHitMode)
        else
            autoFarm = false; farmFlyDestroy(); Notify("Auto Farm","OFF")
        end
    end
})

TAutoFarm:CreateDivider()
TAutoFarm:CreateSection("Auto Join Match")
TAutoFarm:CreateLabel({ Text="Tries Team 1 (slots 1-6) -> Team 2 (slots 1-6)" })

TAutoFarm:CreateToggle({
    Name="Auto Join Match", CurrentValue=false,
    Callback=function(v)
        enablejoin=v; autoJoin=v
        if v then teamSelection(); Notify("Auto Join","ON - scanning both teams...")
        else enablejoin=false; Notify("Auto Join","OFF") end
    end
})

TAutoFarm:CreateButton({
    Name="Join Now (one attempt)",
    Callback=function()
        local rf = getJoinRF()
        if not rf then Notify("Join","[X] RF not found - open lobby first"); return end
        for team = 1, 2 do
            for slot = 1, 6 do
                local ok, res = pcall(function() return rf:InvokeServer(team, slot) end)
                if ok and res then Notify("Join","[OK] Team "..team.." Slot "..slot); return end
                task.wait(0.15)
            end
        end
        Notify("Join","No free slots found")
    end
})

TAutoFarm:CreateDivider()
TAutoFarm:CreateSection("Match Controls")

TAutoFarm:CreateToggle({
    Name="Powerful Serve (press Z)", CurrentValue=false,
    Callback=function(v) powerfulServe=v; Notify("Powerful Serve",v and "ON - press Z" or "OFF") end
})

TAutoFarm:CreateButton({
    Name="Break The Match (must be serving)",
    Callback=function()
        pcall(function()
            ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.GameService.RF.Serve:InvokeServer(nil, 0.95)
        end)
        Notify("Break Match","Sent")
    end
})

TAutoFarm:CreateDivider()
TAutoFarm:CreateButton({ Name="Rejoin Server", Callback=function() pcall(function() TeleportService:Teleport(game.PlaceId, LP) end) end })

TAutoSpin:CreateSection("Style Spinner")

local spinToggleRef     = nil
local spinChangedConn   = nil
local autoLuckySpin     = false
local spinMode          = "normal"

local function trimStyle(s)
    if not s then return nil end; return s:match("^%s*(.-)%s*$")
end

local function getStyleLabel()
    local paths = {
        function() return LP.PlayerGui.Interface.Lobby.Styles.TopPanel.DisplayName end,
        function() return LP.PlayerGui.Interface.Lobby.Styles.TopPanel.StyleName end,
        function() return LP.PlayerGui.Interface.Lobby.StylesFrame.TopPanel.DisplayName end,
    }
    for _, fn in ipairs(paths) do
        local ok, lbl = pcall(fn)
        if ok and lbl and lbl:IsA("TextLabel") then return lbl end
    end
    return nil
end

local function getCurrentStyle()
    local lbl = getStyleLabel(); return lbl and trimStyle(lbl.Text) or nil
end

local function styleMatches(styleName)
    if not styleName then return false end
    local normalized = trimStyle(styleName):lower()
    for _, desired in ipairs(desiredStyles) do
        if desired:lower() == normalized then return true end
    end
    return false
end

local function getStyleRF()
    local ok, rf = pcall(function()
        return ReplicatedStorage
            :WaitForChild("Packages",5):WaitForChild("_Index",5)
            :WaitForChild("sleitnick_knit@1.7.0",5):WaitForChild("knit",5)
            :WaitForChild("Services",5):WaitForChild("StyleService",5)
            :WaitForChild("RF",5):WaitForChild("Roll",5)
    end)
    return (ok and rf) and rf or nil
end

local function onStyleChanged(newText)
    if not autoSpin then return end
    local name = trimStyle(newText)
    if not name or name=="" then return end
    if styleMatches(name) then
        autoSpin = false
        if spinChangedConn then spinChangedConn:Disconnect(); spinChangedConn=nil end
        _freeSpinStop()
        if spinToggleRef then task.defer(function() spinToggleRef:Set(false) end) end
        Luna:Notification({ Title="Style Obtained!", Icon="check_circle", ImageSource="Material", Content="Got: "..name })
    end
end

TAutoSpin:CreateLabel({ Text="[!] Only pick styles that exist in your game version.", Style=2 })
TAutoSpin:CreateLabel({ Text="Setting a style that is not in the game will waste rolls.", Style=2 })
TAutoSpin:CreateDivider()
TAutoSpin:CreateSection("Common & Rare")
TAutoSpin:CreateDropdown({
    Name="Common & Rare Styles",
    Options={"Hinto","Tonkura","Hakochi","Kishoti","Sagumi","Yachikusai","Ninyoku","Tsuchiro","Oyatsu","Imaezi"},
    CurrentOption={"Hinto"}, MultipleOptions=true,
    Callback=function(opt)
        local sel=type(opt)=="table" and opt or {opt}
        for _, s in ipairs(sel) do if not table.find(desiredStyles,s) then table.insert(desiredStyles,s) end end
    end
})
TAutoSpin:CreateSection("Legendary & Godly")
TAutoSpin:CreateDropdown({
    Name="Legendary & Godly Styles",
    Options={"Uchikai","Kyoshin","Sazuroku","Azmei","Yokai","Kozei","Yomosuke","Kyamo","Bakuri","Okazu","Hirakumi"},
    CurrentOption={"Kyamo"}, MultipleOptions=true,
    Callback=function(opt)
        local sel=type(opt)=="table" and opt or {opt}
        for _, s in ipairs(sel) do if not table.find(desiredStyles,s) then table.insert(desiredStyles,s) end end
    end
})
TAutoSpin:CreateSection("Secret Rarity")
TAutoSpin:CreateDropdown({
    Name="Secret Styles",
    Options={"Sanju","Kiuuki","Timeskip Hinto","Timeskip Kyamo","Timeskip Okazu","The Twins","Taichou","Kazana","Mikage","Jinko","Yogan","Hidari","Reiko","Kijo","Ibara"},
    CurrentOption={"Sanju"}, MultipleOptions=true,
    Callback=function(opt)
        local sel=type(opt)=="table" and opt or {opt}
        for _, s in ipairs(sel) do if not table.find(desiredStyles,s) then table.insert(desiredStyles,s) end end
    end
})
TAutoSpin:CreateSection("Ultra & Evo")
TAutoSpin:CreateDropdown({
    Name="Ultra & Evo Styles", Options={"Hakka","Akari","Ronin","Encho"},
    CurrentOption={"Hakka"}, MultipleOptions=true,
    Callback=function(opt)
        local sel=type(opt)=="table" and opt or {opt}
        for _, s in ipairs(sel) do if not table.find(desiredStyles,s) then table.insert(desiredStyles,s) end end
    end
})
TAutoSpin:CreateDivider()
TAutoSpin:CreateButton({ Name="Clear Selected Styles", Callback=function() desiredStyles={}; Notify("Auto Spin","Selection cleared") end })
TAutoSpin:CreateDivider()
TAutoSpin:CreateSection("Free Lucky Spin")

local _freeSpinActive  = false
local _freeSpinCount   = 0
local _freeSpinDelay   = 2
local _freeSpinToggle  = nil
local _freeSpinID      = 1

local function _getFreeSpinRF()
    local ok, rf = pcall(function()
        return ReplicatedStorage
            :WaitForChild("Packages",5)
            :WaitForChild("_Index",5)
            :WaitForChild("sleitnick_knit@1.7.0",5)
            :WaitForChild("knit",5)
            :WaitForChild("Services",5)
            :WaitForChild("SeasonService",5)
            :WaitForChild("RF",5)
            :WaitForChild("RequestRankedReward",5)
    end)
    return ok and rf or nil
end

local function _freeSpinStop()
    _freeSpinActive = false
end

local function _freeSpinStart()
    local rf = _getFreeSpinRF()
    if not rf then
        Notify("Free Lucky Spin","SeasonService not found!")
        if _freeSpinToggle then task.defer(function() _freeSpinToggle:Set(false) end) end
        return
    end
    _freeSpinActive = true
    _freeSpinCount  = 0
    task.spawn(function()
        while _freeSpinActive do
            local ok, _ = pcall(function() rf:InvokeServer(_freeSpinID) end)
            if ok then _freeSpinCount += 1 end
            task.wait(_freeSpinDelay)
        end
    end)
end

TAutoSpin:CreateLabel({ Text="Uses SeasonService remote (from trade).", Style=2 })
TAutoSpin:CreateLabel({ Text="Open Season/Ranked menu in Lobby first.", Style=2 })
TAutoSpin:CreateDivider()

_freeSpinToggle = TAutoSpin:CreateToggle({
    Name="Free Lucky Spin", CurrentValue=false,
    Callback=function(v)
        if v then
            _freeSpinStart()
            Notify("Free Lucky Spin","ON")
        else
            _freeSpinStop()
            Notify("Free Lucky Spin","OFF | Spins: ".._freeSpinCount)
        end
    end
})

TAutoSpin:CreateSlider({
    Name="Free Spin ID", Range={1,10}, Increment=1, CurrentValue=1,
    Callback=function(v) _freeSpinID = v end
})

TAutoSpin:CreateSlider({
    Name="Free Spin Delay (s)", Range={1,10}, Increment=1, CurrentValue=2,
    Callback=function(v) _freeSpinDelay = v end
})

TAutoSpin:CreateButton({
    Name="Free Spin Count",
    Callback=function()
        Notify("Free Lucky Spin","Total: ".._freeSpinCount.." spins")
    end
})

TAutoSpin:CreateDivider()
TAutoSpin:CreateSection("Spin")

TAutoSpin:CreateDropdown({
    Name="Spin Type", Options={"Normal Spin","Lucky Spin"}, CurrentOption={"Normal Spin"}, MultipleOptions=false,
    Callback=function(opt)
        local v=type(opt)=="table" and opt[1] or opt
        spinMode = v:find("Lucky") and "lucky" or "normal"
        Notify("Spin Type", spinMode=="lucky" and "Lucky Spin (2x rates)" or "Normal Spin")
    end
})

spinToggleRef = TAutoSpin:CreateToggle({
    Name="Auto Spin", CurrentValue=false,
    Callback=function(v)
        autoSpin=v
        if spinChangedConn then spinChangedConn:Disconnect(); spinChangedConn=nil end
        if not v then Notify("Auto Spin","Stopped"); return end
        if #desiredStyles==0 then
            Notify("Auto Spin","Select at least one style first!"); autoSpin=false
            task.defer(function() spinToggleRef:Set(false) end); return
        end
        local rf = getStyleRF()
        if not rf then
            Notify("Auto Spin","StyleService not found - open Lobby first!"); autoSpin=false
            task.defer(function() spinToggleRef:Set(false) end); return
        end
        local current = getCurrentStyle()
        if current and styleMatches(current) then
            autoSpin=false; task.defer(function() spinToggleRef:Set(false) end)
            Luna:Notification({ Title="Already have it!", Icon="check_circle", ImageSource="Material", Content="Current style: "..current })
            return
        end
        local lbl = getStyleLabel()
        if lbl then
            spinChangedConn = lbl:GetPropertyChangedSignal("Text"):Connect(function() onStyleChanged(lbl.Text) end)
        end
        Notify("Auto Spin",(spinMode=="lucky" and "Lucky" or "Normal").." | "..#desiredStyles.." target(s)")
        task.spawn(function()
            while autoSpin do
                local pre = getCurrentStyle()
                if pre and styleMatches(pre) then onStyleChanged(pre); break end
                if not spinChangedConn then
                    local newLbl = getStyleLabel()
                    if newLbl then
                        spinChangedConn = newLbl:GetPropertyChangedSignal("Text"):Connect(function() onStyleChanged(newLbl.Text) end)
                    end
                end
                local isLucky = (spinMode=="lucky")
                local ok2, _ = pcall(function() rf:InvokeServer(isLucky) end)
                if not ok2 then task.wait(1) end
                task.wait(0.25)
            end
            if spinChangedConn then spinChangedConn:Disconnect(); spinChangedConn=nil end
        end)
    end
})

TPower:CreateSection("Stat Multipliers (SetAttribute)")

local powerList = {
    { name="Dive Speed",    attr="GameDiveSpeedMultiplier",  range={0,5},   default=1 },
    { name="Spike Power",   attr="GameSpikePowerMultiplier", range={0,500}, default=1 },
    { name="Tilt Power",    attr="GameTiltPowerMultiplier",  range={0,500}, default=1 },
    { name="Set Power",     attr="GameSetPowerMultiplier",   range={0,500}, default=1 },
    { name="Serve Power",   attr="GameServePowerMultiplier", range={0,500}, default=1 },
    { name="Jump Power",    attr="GameJumpPowerMultiplier",  range={0,5},   default=1 },
    { name="Speed",         attr="GameSpeedMultiplier",      range={0,5},   default=1 },
    { name="Bump Power",    attr="GameBumpPowerMultiplier",  range={0,500}, default=1 },
    { name="Block Power",   attr="GameBlockPowerMultiplier", range={0,500}, default=1 },
}

for _, ps in ipairs(powerList) do
    local pName=ps.name; local pAttr=ps.attr
    TPower:CreateSlider({ Name=pName, Range=ps.range, Increment=0.1, CurrentValue=ps.default,
        Callback=function(v) pcall(function() LP:SetAttribute(pAttr,v) end) end })
    TPower:CreateDivider()
end

THitboxes:CreateSection("Ball Hitbox (Unified - Model + Part)")

THitboxes:CreateToggle({
    Name="Ball Hitbox", CurrentValue=false,
    Callback=function(v)
        ballHitboxEnabled=v
        if v then enableBallHitbox(); Notify("Ball Hitbox","ON - size x"..BallHitboxMult)
        else disableBallHitbox(); Notify("Ball Hitbox","OFF - restored") end
    end
})

THitboxes:CreateSlider({
    Name="Ball Hitbox Size", Range={1,30}, Increment=0.5, CurrentValue=5,
    Callback=function(v)
        BallHitboxMult=v
        if ballHitboxEnabled then disableBallHitbox(); enableBallHitbox() end
    end
})

THitboxes:CreateSection("Skill Hitboxes (ReplicatedStorage.Assets.Hitboxes)")

local hitboxList = { "Spike","Block","Bump","Serve","Dive","Set","JumpSet" }
for _, hName in ipairs(hitboxList) do
    local hn=hName
    THitboxes:CreateSlider({ Name=hn.." Hitbox Size", Range={1,100}, Increment=0.1, CurrentValue=10,
        Callback=function(v) setHitboxSize(hn,v) end })
    THitboxes:CreateDivider()
end

TVisuals:CreateSection("Player ESP")

TVisuals:CreateToggle({
    Name="Player ESP", CurrentValue=false,
    Callback=function(v)
        for _, bb in pairs(ESPObjects) do SafeDestroy(bb) end
        ESPObjects={}; disconnect("ESPUpdate")
        if v then
            local function createESP(player)
                if player==LP or not player.Character then return end
                local hrp    = player.Character:FindFirstChild("HumanoidRootPart")
                local myHRP  = getHRP()
                if not hrp or not myHRP then return end
                local bb     = Instance.new("BillboardGui")
                bb.Size      = UDim2.new(8,0,4,0); bb.MaxDistance=ESPRange; bb.Adornee=hrp; bb.AlwaysOnTop=true
                local frame  = Instance.new("Frame")
                frame.Size   = UDim2.new(1,0,1,0); frame.BackgroundTransparency=0.1; frame.BorderSizePixel=0; frame.Parent=bb
                CreateGradientFrame(frame,Color3.fromRGB(0,255,200),Color3.fromRGB(0,100,255))
                local label  = Instance.new("TextLabel"); label.Parent=frame
                label.Size   = UDim2.new(1,0,0.5,0); label.BackgroundTransparency=1
                label.TextColor3=Color3.fromRGB(255,255,255); label.Font=Enum.Font.GothamBold
                label.TextSize=16; label.Text=player.Name; label.TextStrokeTransparency=0
                local distLabel = Instance.new("TextLabel"); distLabel.Parent=frame
                distLabel.Size=UDim2.new(1,0,0.5,0); distLabel.Position=UDim2.new(0,0,0.5,0)
                distLabel.BackgroundTransparency=1; distLabel.TextColor3=Color3.fromRGB(200,255,255)
                distLabel.Font=Enum.Font.GothamBold; distLabel.TextSize=14
                distLabel.Text=math.floor((hrp.Position-myHRP.Position).Magnitude).."m"; distLabel.TextStrokeTransparency=0
                Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
                bb.Parent=Workspace; ESPObjects[player]=bb
            end
            for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
            Connections.ESPUpdate = RunService.Heartbeat:Connect(function()
                FrameCounter+=1; if FrameCounter % math.max(UpdateInterval, PERF.hbInterval) ~= 0 then return end
                local now=tick(); if now-LastESPUpdate < math.max(ESPUpdateInterval, PERF.espInterval*0.5) then return end
                LastESPUpdate=now
                local myHRP=getHRP(); if not myHRP then return end
                for player, bb in pairs(ESPObjects) do
                    if player.Character and bb then
                        local hrp2=player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp2 then
                            local fr=bb:FindFirstChildOfClass("Frame")
                            if fr then
                                for _, lbl in ipairs(fr:GetChildren()) do
                                    if lbl:IsA("TextLabel") and lbl.Text:find("m") then
                                        lbl.Text=math.floor((hrp2.Position-myHRP.Position).Magnitude).."m"
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            Notify("Player ESP","ON")
        else
            Notify("Player ESP","OFF")
        end
    end
})

TVisuals:CreateSlider({ Name="ESP Range", Range={100,10000}, Increment=100, CurrentValue=5000, Callback=function(v) ESPRange=v end })
TVisuals:CreateDivider()

TVisuals:CreateToggle({
    Name="Jump ESP Highlight (enemies jumping)", CurrentValue=false,
    Callback=function(v)
        espJumpEnabled=v
        if not v then for p,_ in pairs(espHighlights) do removeJumpESP(p) end end
        Notify("Jump ESP",v and "ON (yellow)" or "OFF")
    end
})

TVisuals:CreateDivider()

TVisuals:CreateToggle({
    Name="Enemy Lines (beams)", CurrentValue=false,
    Callback=function(v)
        linesEnabled=v
        if not v then for p,_ in pairs(lines) do removeLine(p) end end
        Notify("Enemy Lines",v and "ON" or "OFF")
    end
})

TVisuals:CreateSlider({ Name="Line Distance", Range={0,100}, Increment=10, CurrentValue=50, Callback=function(v) lineDistance=v end })
TVisuals:CreateDivider()
TVisuals:CreateSection("Ball Visuals")

TVisuals:CreateToggle({
    Name="Ball ESP", CurrentValue=false,
    Callback=function(v)
        for _, bb in pairs(BallESPObjects) do SafeDestroy(bb) end
        BallESPObjects={}; disconnect("BallESPUpdate")
        if v then
            local function createBallESP(ball)
                if not ball or not ball:IsA("BasePart") then return end
                local bb    = Instance.new("BillboardGui")
                bb.Size     = UDim2.new(10,0,5,0); bb.MaxDistance=BallESPRange; bb.Adornee=ball; bb.AlwaysOnTop=true
                local frame = Instance.new("Frame")
                frame.Size  = UDim2.new(1,0,1,0); frame.BackgroundTransparency=0.05; frame.BorderSizePixel=0; frame.Parent=bb
                CreateGradientFrame(frame,Color3.fromRGB(255,50,50),Color3.fromRGB(255,150,0))
                local label = Instance.new("TextLabel"); label.Parent=frame
                label.Size  = UDim2.new(1,0,0.5,0); label.BackgroundTransparency=1
                label.TextColor3=Color3.fromRGB(255,255,255); label.Font=Enum.Font.GothamBold
                label.TextSize=18; label.Text=" BALL"; label.TextStrokeTransparency=0
                local velLabel = Instance.new("TextLabel"); velLabel.Parent=frame
                velLabel.Size=UDim2.new(1,0,0.5,0); velLabel.Position=UDim2.new(0,0,0.5,0)
                velLabel.BackgroundTransparency=1; velLabel.TextColor3=Color3.fromRGB(255,255,200)
                velLabel.Font=Enum.Font.GothamBold; velLabel.TextSize=14
                velLabel.Text="Speed: "..math.floor(ball.Velocity.Magnitude); velLabel.TextStrokeTransparency=0
                Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
                bb.Parent=Workspace; BallESPObjects[ball]=bb
            end
            local ball=FindBall(); if ball then createBallESP(ball) end
            Connections.BallESPUpdate = RunService.Heartbeat:Connect(function()
                FrameCounter+=1; if FrameCounter % math.max(UpdateInterval, PERF.hbInterval) ~= 0 then return end
                local ball2=FindBall()
                if ball2 and not BallESPObjects[ball2] then createBallESP(ball2) end
            end)
            Notify("Ball ESP","ON")
        else
            Notify("Ball ESP","OFF")
        end
    end
})

TVisuals:CreateSlider({ Name="Ball ESP Range", Range={100,10000}, Increment=100, CurrentValue=5000, Callback=function(v) BallESPRange=v end })
TVisuals:CreateDivider()

TVisuals:CreateToggle({
    Name="Reach Circle (shows reach radius)", CurrentValue=false,
    Callback=function(v)
        if v then CreateReachCircle(); Notify("Reach Circle",ReachDistance.." studs")
        else DestroyReachCircle(); Notify("Reach Circle","OFF") end
    end
})

TVisuals:CreateSlider({ Name="Reach Distance", Range={5,50}, Increment=1, CurrentValue=10, Callback=function(v) ReachDistance=v; UpdateReachCircle() end })
TVisuals:CreateDivider()
TVisuals:CreateSection("Lighting")

TVisuals:CreateToggle({
    Name="Fullbright", CurrentValue=false,
    Callback=function(v)
        if v then
            Lighting.Brightness=3; Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1)
            Notify("Fullbright","ON")
        else
            Lighting.Brightness=defaultBrightness; Lighting.Ambient=defaultAmbient; Lighting.OutdoorAmbient=defaultOutdoorAmbient
            Notify("Fullbright","OFF")
        end
    end
})

TVisuals:CreateToggle({
    Name="Night Mode", CurrentValue=false,
    Callback=function(v)
        if v then Lighting.Ambient=Color3.fromRGB(20,20,20); Lighting.Brightness=1; Notify("Night Mode","ON")
        else Lighting.Ambient=defaultAmbient; Lighting.Brightness=defaultBrightness; Notify("Night Mode","OFF") end
    end
})

TVisuals:CreateToggle({
    Name="Xray Vision", CurrentValue=false,
    Callback=function(v)
        if v then
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and not part:IsDescendantOf(LP.Character) and part.Name~="RixPlatform" then
                    OriginalParts[part]=part.Transparency; part.Transparency=0.7
                end
            end
            Notify("Xray","ON")
        else
            for part, trans in pairs(OriginalParts) do if part and part.Parent then part.Transparency=trans end end
            OriginalParts={}; Notify("Xray","OFF")
        end
    end
})

TVisuals:CreateSlider({ Name="Fog End Distance",  Range={0,10000}, Increment=50,  CurrentValue=defaultFogEnd, Callback=function(v) Lighting.FogEnd=v end })
TVisuals:CreateSlider({ Name="Bloom Intensity",   Range={0,5},     Increment=0.1, CurrentValue=0,             Callback=function(v) bloomEffect.Intensity=v end })

TVisuals:CreateButton({ Name="Reset Lighting",
    Callback=function()
        Lighting.Brightness=defaultBrightness; Lighting.Ambient=defaultAmbient
        Lighting.OutdoorAmbient=defaultOutdoorAmbient; Lighting.FogEnd=defaultFogEnd
        bloomEffect.Intensity=0; Notify("Lighting","Reset")
    end
})

TVisuals:CreateDivider()
TVisuals:CreateSection("FPS Boost")

local fpsBoostEnabled  = false
local savedFPS         = {}
local savedMaterials   = {}
local savedReflectance = {}
local savedDecals      = {}
local savedParticles   = {}
local savedShadows     = Lighting.GlobalShadows
local savedFogEnd      = Lighting.FogEnd
local savedBrightness  = Lighting.Brightness
local savedClockTime   = Lighting.ClockTime
local savedAmbient     = Lighting.Ambient
local savedOutdoor     = Lighting.OutdoorAmbient
local savedExposure    = Lighting.ExposureCompensation
local savedEnvDiff     = Lighting.EnvironmentDiffuseScale
local savedEnvSpec     = Lighting.EnvironmentSpecularScale
local savedFOV         = 80
local savedVolume      = 0.5

local _fpsServices = setmetatable({}, {
    __index = function(self, key)
        local ok, svc = pcall(function() return game:GetService(key) end)
        if ok then rawset(self, key, svc); return svc end
        return nil
    end
})

local function enableFPSBoost()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    local L = _fpsServices.Lighting
    L.GlobalShadows=false; L.FogEnd=9e9; L.FogStart=0; L.Brightness=1; L.ClockTime=14
    L.ExposureCompensation=0.5; L.Ambient=Color3.new(0.5,0.5,0.5); L.OutdoorAmbient=Color3.new(0.6,0.6,0.6)
    L.EnvironmentDiffuseScale=0.3; L.EnvironmentSpecularScale=0.1; bloomEffect.Intensity=0
    for _, fx in ipairs(L:GetChildren()) do
        if fx:IsA("PostEffect") or fx:IsA("Sky") or fx:IsA("Atmosphere") then fx.Enabled=false end
    end
    pcall(function() local cam=Workspace.CurrentCamera; if cam then savedFOV=cam.FieldOfView; cam.FieldOfView=80 end end)
    pcall(function() local ugs=_fpsServices.UserGameSettings; if ugs then savedVolume=ugs.MasterVolume; ugs.MasterVolume=0.1 end end)
    task.spawn(function()
        local batch=0; local desc=Workspace:GetDescendants()
        for _, v in ipairs(desc) do
            if not fpsBoostEnabled then return end
            batch+=1
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") or v:IsA("Beam") then
                savedParticles[v]=v.Enabled; pcall(function() v.Enabled=false end)
            elseif v:IsA("Decal") or v:IsA("Texture") then
                savedDecals[v]=v.Transparency; pcall(function() v.Transparency=1 end)
            elseif v:IsA("BasePart") and not v:IsDescendantOf(LP.Character) then
                savedMaterials[v]=v.Material; savedReflectance[v]=v.Reflectance
                pcall(function() v.Material=Enum.Material.SmoothPlastic; v.Reflectance=0 end)
            elseif v:IsA("SpecialMesh") or v:IsA("SurfaceAppearance") then
                savedParticles[v]=true; pcall(function() v.Parent=nil end)
            end
            if batch>=50 then batch=0; task.wait() end
        end
    end)
    Notify("FPS Boost","ON - Quality minimized")
end

local function disableFPSBoost()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    local L = _fpsServices.Lighting
    L.GlobalShadows=savedShadows; L.FogEnd=savedFogEnd; L.FogStart=0; L.Brightness=savedBrightness
    L.ClockTime=savedClockTime; L.Ambient=savedAmbient; L.OutdoorAmbient=savedOutdoor
    L.ExposureCompensation=savedExposure; L.EnvironmentDiffuseScale=savedEnvDiff; L.EnvironmentSpecularScale=savedEnvSpec
    for _, fx in ipairs(L:GetChildren()) do
        if fx:IsA("PostEffect") or fx:IsA("Sky") or fx:IsA("Atmosphere") then fx.Enabled=true end
    end
    pcall(function() local cam=Workspace.CurrentCamera; if cam then cam.FieldOfView=savedFOV end end)
    pcall(function() local ugs=_fpsServices.UserGameSettings; if ugs then ugs.MasterVolume=savedVolume end end)
    for obj, state in pairs(savedParticles) do if obj and obj.Parent then pcall(function() obj.Enabled=state end) end end
    savedParticles={}
    for obj, trans in pairs(savedDecals)    do if obj and obj.Parent then pcall(function() obj.Transparency=trans end) end end
    savedDecals={}
    for obj, mat in pairs(savedMaterials)   do if obj and obj.Parent then pcall(function() obj.Material=mat end) end end
    savedMaterials={}
    for obj, ref in pairs(savedReflectance) do if obj and obj.Parent then pcall(function() obj.Reflectance=ref end) end end
    savedReflectance={}
    Notify("FPS Boost","OFF - Restored")
end

TVisuals:CreateToggle({
    Name="FPS Boost", CurrentValue=false,
    Callback=function(v)
        fpsBoostEnabled=v
        if v then
            savedShadows=Lighting.GlobalShadows; savedFogEnd=Lighting.FogEnd; savedBrightness=Lighting.Brightness
            savedClockTime=Lighting.ClockTime; savedAmbient=Lighting.Ambient; savedOutdoor=Lighting.OutdoorAmbient
            savedExposure=Lighting.ExposureCompensation; savedEnvDiff=Lighting.EnvironmentDiffuseScale; savedEnvSpec=Lighting.EnvironmentSpecularScale
            enableFPSBoost()
        else
            disableFPSBoost()
        end
    end
})

TVisuals:CreateToggle({
    Name="Fullscreen Mode", CurrentValue=false,
    Callback=function(v)
        pcall(function()
            UserInputService.OverrideMouseIconBehavior = v and Enum.OverrideMouseIconBehavior.ForceHide or Enum.OverrideMouseIconBehavior.None
        end)
        Notify("Fullscreen",v and "ON" or "OFF")
    end
})

TVisuals:CreateSlider({
    Name="Render Quality (1=min 10=max)", Range={1,10}, Increment=1, CurrentValue=10,
    Callback=function(v)
        pcall(function()
            local lvl="Level0"..(v<10 and tostring(v) or "10")
            settings().Rendering.QualityLevel=Enum.QualityLevel[lvl]
        end)
    end
})

TVisuals:CreateSlider({
    Name="Volume", Range={0,100}, Increment=5, CurrentValue=50,
    Callback=function(v) pcall(function() _fpsServices.UserGameSettings.MasterVolume=v/100 end) end
})

TProtection:CreateSection("Anti Cheat")

TProtection:CreateToggle({
    Name="Anti Cheat Bypass (multi-stage)", CurrentValue=false,
    Callback=function(v)
        AntiCheatEnabled=v
        if v then
            if IS_FULL_EXECUTOR then
                SetupAntiCheatBypass(); Notify("AC Bypass","Active")
            else
                AntiCheatEnabled=false
                Notify("AC Bypass","Not supported - needs full executor")
            end
        else
            Notify("AC Bypass","OFF")
        end
    end
})

TProtection:CreateDivider()

TProtection:CreateToggle({
    Name="Anti Kick", CurrentValue=false,
    Callback=function(v)
        if v then
            if not IS_FULL_EXECUTOR then
                Notify("Anti Kick","Needs full executor (Delta not supported)")
                return
            end
            pcall(function()
                local mt=getrawmetatable(game); local old=mt.__namecall
                setreadonly(mt,false)
                mt.__namecall=newcclosure(function(self,...)
                    if getnamecallmethod()=="Kick" and self==LP then Notify("Anti Kick","Blocked"); return nil end
                    return old(self,...)
                end)
                setreadonly(mt,true)
            end)
            Notify("Anti Kick","ON")
        else
            Notify("Anti Kick","OFF")
        end
    end
})

TProtection:CreateDivider()

TProtection:CreateToggle({
    Name="Anti Teleport", CurrentValue=false,
    Callback=function(v)
        disconnect("AntiTP")
        if v then
            LastPos=getHRP() and getHRP().Position or Vector3.new(0,0,0)
            local _tpTick = 0
            Connections.AntiTP=RunService.Heartbeat:Connect(function()
                _tpTick += 1; if _tpTick % PERF.hbInterval ~= 0 then return end
                local hrp=getHRP(); if not hrp then return end
                local dist=(hrp.Position-LastPos).Magnitude
                if dist>150 then hrp.CFrame=CFrame.new(LastPos) else LastPos=hrp.Position end
            end)
            Notify("Anti TP","ON")
        else
            Notify("Anti TP","OFF")
        end
    end
})

TProtection:CreateDivider()

TProtection:CreateToggle({
    Name="Anti AFK", CurrentValue=false,
    Callback=function(v)
        disconnect("AntiAFK")
        if v then
            local _afkTick = 0
            Connections.AntiAFK=RunService.Heartbeat:Connect(function()
                _afkTick += 1; if _afkTick % 180 ~= 0 then return end
                pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
            end)
            Notify("Anti AFK","ON")
        else
            Notify("Anti AFK","OFF")
        end
    end
})

TProtection:CreateDivider()

TProtection:CreateButton({
    Name="Protect All Players from Kick",
    Callback=function()
        for _, p in ipairs(Players:GetPlayers()) do if p~=LP then ProtectedPlayers[p.Name]=true end end
        Notify("Player Protect","All protected")
    end
})

local function getCodeRF()
    local ok, rf = pcall(function()
        return game:GetService("ReplicatedStorage")
            :WaitForChild("Packages",5):WaitForChild("_Index",5)
            :WaitForChild("sleitnick_knit@1.7.0",5):WaitForChild("knit",5)
            :WaitForChild("Services",5):WaitForChild("CodeService",5)
            :WaitForChild("RF",5):WaitForChild("Redeem",5)
    end)
    return ok and rf or nil
end

local function redeemCode(rf, code)
    local ok, result = pcall(function() return rf:InvokeServer(code) end)
    return ok and result
end

local function fetchCodesFromWeb()
    local codes = {}
    local ok, html = pcall(function() return game:HttpGet("https://beebom.com/haikyuu-legends-codes/", true) end)
    if not ok or not html then return codes end
    for code in html:gmatch("<code[^>]*>([^<]+)</code>") do
        local c=code:match("^%s*(.-)%s*$")
        if #c>2 and #c<32 and not c:find("[<>]") then table.insert(codes,c) end
    end
    for code in html:gmatch("<strong>([A-Za-z0-9%-%_]+)</strong>") do
        local c=code:match("^%s*(.-)%s*$")
        if #c>2 and #c<32 and not table.find(codes,c) then table.insert(codes,c) end
    end
    for code in html:gmatch("<li><strong>([^<]+)</strong>") do
        local c=code:match("^%s*(.-)%s*$")
        if #c>2 and #c<32 and not table.find(codes,c) then table.insert(codes,c) end
    end
    return codes
end

local _manualCode    = ""
local _redeemedCodes = {}

TCodes:CreateSection("Auto Redeem from Web")
TCodes:CreateLabel({ Text="Fetches codes from beebom.com automatically", Style=2 })
TCodes:CreateLabel({ Text="Only redeems each code once per session", Style=2 })
TCodes:CreateDivider()

TCodes:CreateButton({
    Name="Fetch + Redeem All Codes",
    Callback=function()
        Notify("Codes","Fetching codes from web...")
        task.spawn(function()
            local rf=getCodeRF()
            if not rf then Notify("Codes","CodeService not found - be in lobby!"); return end
            local codes=fetchCodesFromWeb()
            if #codes==0 then Notify("Codes","No codes found on page"); return end
            Notify("Codes","Found "..#codes.." codes - redeeming...")
            local success,failed,skipped=0,0,0
            for _, code in ipairs(codes) do
                if _redeemedCodes[code] then skipped+=1
                else
                    _redeemedCodes[code]=true
                    local ok2=redeemCode(rf,code)
                    if ok2 then success+=1 else failed+=1 end
                    task.wait(0.4)
                end
            end
            Notify("Codes","Done! OK:"..success.." Fail:"..failed.." Skip:"..skipped)
        end)
    end
})

TCodes:CreateDivider()
TCodes:CreateSection("Manual Code")
TCodes:CreateInput({ Name="Enter Code", PlaceholderText="Code here...", Callback=function(val) _manualCode=val:match("^%s*(.-)%s*$") end })

TCodes:CreateButton({
    Name="Redeem Manual Code",
    Callback=function()
        if _manualCode=="" then Notify("Codes","Enter a code first!"); return end
        local rf=getCodeRF()
        if not rf then Notify("Codes","CodeService not found!"); return end
        local ok2=redeemCode(rf,_manualCode)
        if ok2 then _redeemedCodes[_manualCode]=true; Notify("Codes","Redeemed: ".._manualCode)
        else Notify("Codes","Failed: ".._manualCode) end
    end
})

TCodes:CreateDivider()
TCodes:CreateButton({ Name="Reset Redeemed History", Callback=function() _redeemedCodes={}; Notify("Codes","History cleared") end })

TPerf:CreateSection("Performance Info")

TPerf:CreateLabel({ Text="FPS and quality level update every second.", Style=2 })
TPerf:CreateDivider()

TPerf:CreateButton({
    Name="Check FPS & Quality",
    Callback=function()
        Notify("Performance",
            string.format("FPS: %d | Quality: %s | Platform: %s", PERF.fps, PERF.quality, PLATFORM))
    end
})

TPerf:CreateDivider()
TPerf:CreateSection("Manual Quality Override")

TPerf:CreateDropdown({
    Name="Force Quality Level",
    Options={"Auto","High (60fps)","Medium (30fps)","Low (<30fps)"},
    CurrentOption={"Auto"},
    MultipleOptions=false,
    Callback=function(opt)
        local v = type(opt)=="table" and opt[1] or opt
        if v == "High (60fps)" then
            PERF.hbInterval=1; PERF.espInterval=4; PERF.trajInterval=2
            Notify("Performance","Forced HIGH")
        elseif v == "Medium (30fps)" then
            PERF.hbInterval=2; PERF.espInterval=8; PERF.trajInterval=3
            Notify("Performance","Forced MEDIUM")
        elseif v == "Low (<30fps)" then
            PERF.hbInterval=3; PERF.espInterval=12; PERF.trajInterval=5
            Notify("Performance","Forced LOW")
        else
            PERF.hbInterval = IS_MOBILE and 2 or 1
            PERF.espInterval = IS_MOBILE and 8 or 4
            PERF.trajInterval = IS_MOBILE and 3 or 2
            Notify("Performance","Auto mode restored")
        end
    end
})

TPerf:CreateDivider()
TPerf:CreateSection("Mobile Optimization")

TPerf:CreateToggle({
    Name="Mobile Mode (less updates)",
    CurrentValue=IS_MOBILE,
    Callback=function(v)
        if v then
            PERF.hbInterval=3; PERF.espInterval=12; PERF.trajInterval=5
            Notify("Mobile Mode","ON - reduced updates")
        else
            PERF.hbInterval=1; PERF.espInterval=4; PERF.trajInterval=2
            Notify("Mobile Mode","OFF - full updates")
        end
    end
})

TPerf:CreateDivider()

TAbout:CreateLabel({ Text="Rix Hub v1.0.0 beta", Style=1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text="Volleyball Legends", Style=2 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text="Player: "..LP.Name, Style=1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text="Discord: discord.gg/sPCKm8juf", Style=1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text="Features:", Style=1 })
TAbout:CreateLabel({ Text="- Smart Auto Farm + Enemy Targeting", Style=2 })
TAbout:CreateLabel({ Text="- Normal + Lucky Auto Spin (40 styles)", Style=2 })
TAbout:CreateLabel({ Text="- Ball + Skill Hitboxes (no freeze)", Style=2 })
TAbout:CreateLabel({ Text="- ESP + Visuals + FPS Boost", Style=2 })
TAbout:CreateLabel({ Text="- Game Modes (Setting/Serving/Spiking)", Style=2 })
TAbout:CreateLabel({ Text="- Anti AC (starts automatically)", Style=2 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text="50+ Features", Style=1 })
TAbout:CreateDivider()

TAbout:CreateButton({
    Name="Disable ALL Features",
    Callback=function()
        for key,_ in pairs(Connections) do disconnect(key) end
        for _,bb in pairs(ESPObjects)     do SafeDestroy(bb) end; ESPObjects={}
        for _,bb in pairs(BallESPObjects) do SafeDestroy(bb) end; BallESPObjects={}
        _trajStop()
        for p,_ in pairs(lines) do removeLine(p) end
        for p,_ in pairs(espHighlights) do removeJumpESP(p) end
        for part,trans in pairs(OriginalParts) do if part and part.Parent then part.Transparency=trans end end; OriginalParts={}
        disableBallHitbox()
        removeAntennas(); removeServeCorners(); removeSpikeZones()
        SafeDestroy(PlatformPart); PlatformPart=nil
        SafeDestroy(bodyVelocity); bodyVelocity=nil
        DestroyReachCircle()
        local hum=getHum()
        if hum then hum.WalkSpeed=OriginalWalkSpeed; hum.JumpHeight=OriginalJumpHeight end
        Lighting.Brightness=defaultBrightness; Lighting.Ambient=defaultAmbient
        Lighting.OutdoorAmbient=defaultOutdoorAmbient; Lighting.FogEnd=defaultFogEnd
        bloomEffect.Intensity=0
        if fpsBoostEnabled then disableFPSBoost(); fpsBoostEnabled=false end
        autoFarm=false; autoJoin=false; enablejoin=false; autoSpin=false
        farmFlyDestroy()
        if spinChangedConn then spinChangedConn:Disconnect(); spinChangedConn=nil end
        linesEnabled=false; espJumpEnabled=false; powerfulServe=false
        vbSetting=false; vbServing=false; vbSpiking=false; vbPower=false; vbSprint=false
        IsJumping=false; AntiCheatEnabled=false; ProtectedPlayers={}; BlockedRemotes={}
        Notify("All OFF","Every feature disabled")
    end
})

LP.CharacterAdded:Connect(function()
    task.wait(1)
    local hum=getHum()
    if hum then hum.WalkSpeed=OriginalWalkSpeed; hum.JumpHeight=OriginalJumpHeight end
    if LastPos then LastPos=getHRP() and getHRP().Position or Vector3.new(0,0,0) end
    _acActive=false
    if enablejoin then task.spawn(teamSelection) end
end)

Players.PlayerAdded:Connect(function(p)
    setupJumpESP(p)
    if AntiCheatEnabled then ProtectedPlayers[p.Name]=true end
end)

if IS_FULL_EXECUTOR then
    Notify("Rix Hub","v1.0.0 beta | Full Executor")
else
    Notify("Rix Hub","v1.0.0 beta | Limited Mode (no full executor)")
end

-- ─── PLATFORM STARTUP ─────────────────────────────────────────
task.wait(1)

Notify("Rix Hub v1.0.0 beta",
    "Platform: " .. PLATFORM .. " | Executor: " .. EXECUTOR_TYPE)

if not IS_FULL_EXECUTOR then
    task.wait(1.5)
    Notify("Limited Executor",
        "Anti Kick & AC Bypass disabled. All other features work normally.")
end

if IS_MOBILE then
    local sg          = Instance.new("ScreenGui")
    sg.Name           = "RixMobileBtn"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent         = LP.PlayerGui

    local btn            = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 58, 0, 58)
    btn.Position         = UDim2.new(1, -70, 0.5, -29)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    btn.Text             = "RIX"
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 13
    btn.ZIndex           = 15
    btn.Parent           = sg

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    local st       = Instance.new("UIStroke", btn)
    st.Color       = Color3.fromRGB(80, 100, 220)
    st.Thickness   = 2

    local dragging, dragInput, startState = false, nil, nil

    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            dragInput  = inp
            startState = {btn.Position, inp.Position}
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(inp)
        if dragging and inp == dragInput then
            local d = inp.Position - startState[2]
            btn.Position = UDim2.new(
                startState[1].X.Scale, startState[1].X.Offset + d.X,
                startState[1].Y.Scale, startState[1].Y.Offset + d.Y
            )
        end
    end)

    game:GetService("UserInputService").InputEnded:Connect(function(inp)
        if inp == dragInput then dragging = false end
    end)

    btn.MouseButton1Click:Connect(function()
        pcall(function() Luna:ToggleUI() end)
    end)
end

print("Rix Hub v1.0.0 beta | " .. PLATFORM .. " | " .. EXECUTOR_TYPE .. " executor")
