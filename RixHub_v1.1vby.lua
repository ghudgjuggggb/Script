
repeat task.wait() until game:IsLoaded()

local lunaUrl = "https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua"
local lunaLoaded, lunaResult = pcall(function()
    return loadstring(game:HttpGet(lunaUrl, true))()
end)
if not lunaLoaded or type(lunaResult) ~= "table" then
    error("[RixHub] Luna failed to load: " .. tostring(lunaResult))
end
local Luna = lunaResult

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local Workspace       = game:GetService("Workspace")
local Lighting        = game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local VirtualUser     = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local Debris          = game:GetService("Debris")
local CoreGui         = game:GetService("CoreGui")

local LP   = Players.LocalPlayer
local Mouse = LP:GetMouse()
if not LP then return end

local Window = Luna:CreateWindow({
    Name = "Rix Hub",
    Subtitle = "Volleyball Legends",
    LogoID = "130188918639066",
    LoadingEnabled = true,
    LoadingTitle = "Rix Hub",
    LoadingSubtitle = "Loading...",
    ConfigSettings = { RootFolder = nil, ConfigFolder = "RixHub" },
    KeySystem = false
})

local Connections = {}

local SpeedMult      = 1.2
local JumpMult       = 1.3
local SpinSpd        = 15
local FlySpd         = 40
local PlatHeight     = 8
local GravityMult    = 0.5
local airMovementSpeed = 16

local ESPRange       = 5000
local BallESPRange   = 5000
local ReachDistance  = 10
local lineDistance   = 50

local BallHitboxMult = 5

local IsJumping      = false
local autoShiftLock  = false
local airMovement    = false
local linesEnabled   = false
local powerfulServe  = false
local autoFarm       = false
local autoJoin       = false
local autoSpin       = false
local espJumpEnabled = false
local AntiCheatEnabled = false
local escPressed     = false

local vbSetting   = false
local vbServing   = false
local vbSpiking   = false
local vbPower     = false
local vbSprint    = false
local vbBlockMode = false
local vbSpikeMode = "random"
local vbSetForward  = Enum.KeyCode.F
local vbSetBack     = Enum.KeyCode.R
local vbMaxPower    = Enum.KeyCode.C
local vbSprintKey   = Enum.KeyCode.T
local vbChangeMode  = Enum.KeyCode.One
local vbLeft, vbRight
local vbRedRCorner, vbRedLCorner, vbBluRCorner, vbBluLCorner
local vbRedSpike, vbBluSpike

local PlatformPart    = nil
local bodyVelocity    = nil
local airBodyVelocity = nil
local ReachCircle     = nil
local ReachGui        = nil

local ESPObjects     = {}
local BallESPObjects = {}
local TrajectoryLines= {}
local OriginalParts  = {}
local lines          = {}
local espHighlights  = {}
local espConnections = {}
local desiredStyles  = {}

local BlockedRemotes = {}
local ProtectedPlayers = {}
local LastPos        = nil

local FrameCounter   = 0
local UpdateInterval = 3
local LastESPUpdate  = 0
local ESPUpdateInterval = 5

local CurrentBall    = nil
local LastBallCheck  = 0

local defaultAmbient        = Lighting.Ambient
local defaultBrightness     = Lighting.Brightness
local defaultOutdoorAmbient = Lighting.OutdoorAmbient
local defaultFogEnd         = Lighting.FogEnd

local bloomEffect = Instance.new("BloomEffect", Lighting)
bloomEffect.Intensity = 0; bloomEffect.Size = 56; bloomEffect.Threshold = 1

local OriginalWalkSpeed  = 16
local OriginalJumpHeight = 7.2

local function getChar() return LP.Character end
local function getHRP()  local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") or nil end
local function getHum()  local c=getChar() return c and c:FindFirstChildOfClass("Humanoid") or nil end

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
        g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(1,c2)})
        g.Rotation = 45; g.Parent = parent
    end)
end

local function FindBall()
    local now = tick()
    if now - LastBallCheck < 0.5 and CurrentBall and CurrentBall.Parent then return CurrentBall end
    LastBallCheck = now; CurrentBall = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("ball") or n:find("volleyball") or n:find("sphere") then
                CurrentBall = obj; break
            end
        end
    end
    return CurrentBall
end

local function getBallModel()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:match("^CLIENT_BALL_%d+$") then
            return obj:FindFirstChild("Sphere.001") or obj:FindFirstChild("Cube.001")
        end
    end
    return nil
end

local function findFirstPart(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
end

-- ============================================================
-- UNIFIED BALL HITBOX  (CLIENT_BALL model + BasePart + Heartbeat)
-- ============================================================
local ballHitboxEnabled   = false
local ballHitboxLoopAlive = false
local originalBallSizes   = {}
local managedModelBalls   = {}
local ballChildAddedConn  = nil

local function applyBallHitboxToModel(model)
    if not (model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$")) then return end
    if model:FindFirstChild("RixBall") then return end  -- уже есть
    local base = nil
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then base = d; break end
    end
    if not base then return end
    local hb          = Instance.new("Part")
    hb.Name           = "RixBall"
    hb.Shape          = Enum.PartType.Ball
    hb.Size           = Vector3.new(1, 1, 1) * BallHitboxMult
    hb.CFrame         = base.CFrame
    hb.Anchored       = false
    hb.CanCollide     = false
    hb.Transparency   = 0.5
    hb.Material       = Enum.Material.ForceField
    hb.Color          = Color3.fromRGB(0, 255, 100)
    hb.Massless       = true
    local weld        = Instance.new("WeldConstraint")
    weld.Part0        = base
    weld.Part1        = hb
    weld.Parent       = hb
    hb.Parent         = model
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
    ball.Size        = ball.Size * BallHitboxMult
    ball.Transparency = 0.45
    ball.Material    = Enum.Material.Neon
    ball.Color       = Color3.fromRGB(255, 50, 50)
end

local function restoreAllBalls()
    for _, hb in ipairs(managedModelBalls) do
        if hb and hb.Parent then hb:Destroy() end
    end
    managedModelBalls = {}
    for ball, props in pairs(originalBallSizes) do
        if ball and ball.Parent then
            ball.Size        = props.size
            ball.Transparency = props.transparency
            ball.Material    = props.material
            ball.Color       = props.color
        end
    end
    originalBallSizes = {}
end

local function enableBallHitbox()
    if ballHitboxLoopAlive then return end
    ballHitboxLoopAlive = true

    -- Применяем сразу к существующим
    for _, child in ipairs(Workspace:GetChildren()) do
        applyBallHitboxToModel(child)
    end
    local part = FindBall()
    if part then applyBallHitboxToPart(part) end

    -- ChildAdded: ловим новый мяч без polling
    if ballChildAddedConn then ballChildAddedConn:Disconnect() end
    ballChildAddedConn = Workspace.ChildAdded:Connect(function(child)
        if not ballHitboxEnabled then return end
        task.wait(0.15)
        applyBallHitboxToModel(child)
    end)

    -- Редкий фоновый цикл (каждые 2 сек) для BasePart мячей
    -- НЕ Heartbeat — не нагружает каждый кадр
    task.spawn(function()
        while ballHitboxLoopAlive do
            task.wait(2)
            if not ballHitboxEnabled then break end
            pcall(function()
                local ball = FindBall()
                if ball and not originalBallSizes[ball] then
                    applyBallHitboxToPart(ball)
                end
                -- Чистим мёртвые записи
                for b, _ in pairs(originalBallSizes) do
                    if not (b and b.Parent) then
                        originalBallSizes[b] = nil
                    end
                end
                for i = #managedModelBalls, 1, -1 do
                    local hb = managedModelBalls[i]
                    if not (hb and hb.Parent) then
                        table.remove(managedModelBalls, i)
                    end
                end
            end)
        end
    end)
end

local function disableBallHitbox()
    ballHitboxLoopAlive = false
    if ballChildAddedConn then
        ballChildAddedConn:Disconnect()
        ballChildAddedConn = nil
    end
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
        local frame = CFrame.new(chr.PrimaryPart.Position, target.Position)
        chr:SetPrimaryPartCFrame(frame)
    end
end

local function lookAway(chr, target)
    if chr and chr.PrimaryPart and target then
        local frame = CFrame.new(chr.PrimaryPart.Position, target.Position)
        chr:SetPrimaryPartCFrame(frame)
        chr.HumanoidRootPart.CFrame = chr.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(180), 0)
    end
end

local function placeAntennas()
    pcall(function()
        vbLeft = Instance.new("Part")
        vbRight = Instance.new("Part")
        vbLeft.Name = "RixLeft"; vbRight.Name = "RixRight"
        vbLeft.Transparency = 1; vbRight.Transparency = 1
        vbLeft.Position = Vector3.new(-23.789, 8, 0.007)
        vbRight.Position = Vector3.new(23.783, 8, -0.006)
        vbLeft.Size = Vector3.new(1.607, 1, 2)
        vbRight.Size = Vector3.new(1.607, 1, 2)
        vbLeft.CanCollide = false; vbRight.CanCollide = false
        vbLeft.Anchored = true; vbRight.Anchored = true
        vbLeft.Parent = Workspace; vbRight.Parent = Workspace
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
        vbRedRCorner.Position = Vector3.new(23.479, 0.638, -47.059)
        vbRedLCorner.Position = Vector3.new(-23.577, 0.633, -47.059)
        vbBluRCorner.Position = Vector3.new(-23.577, 0.633, 46.936)
        vbBluLCorner.Position = Vector3.new(23.483, 0.628, 46.936)
        for _, p in ipairs({vbRedRCorner, vbRedLCorner, vbBluRCorner, vbBluLCorner}) do
            p.Size = Vector3.new(1.048, 0.076, 1.07)
            p.Anchored = true; p.CanCollide = false; p.Transparency = 1
            p.Parent = Workspace
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
        vbRedSpike = Instance.new("Part")
        vbRedSpike.Name = "RixRedSpike"
        vbRedSpike.Anchored = true; vbRedSpike.CanCollide = false
        vbRedSpike.Position = Vector3.new(-0.009, 0.501, -23.927)
        vbRedSpike.Size = Vector3.new(47.936, 0.001, 46.988)
        vbRedSpike.Transparency = 1; vbRedSpike.Parent = Workspace
        vbBluSpike = Instance.new("Part")
        vbBluSpike.Name = "RixBluSpike"
        vbBluSpike.Anchored = true; vbBluSpike.CanCollide = false
        vbBluSpike.Position = Vector3.new(-0.009, 0.501, 23.984)
        vbBluSpike.Size = Vector3.new(47.936, 0.001, 46.988)
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
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
                        task.wait(0.3)
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
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
    Color3.fromRGB(255,165,0), Color3.fromRGB(128,0,128), Color3.fromRGB(255,255,0)
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
    local head = char.Head
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then removeLine(player); return end
    if not lines[player] then
        local attachment = Instance.new("Attachment", head)
        local target = Instance.new("Part")
        target.Anchored=true; target.CanCollide=false; target.Transparency=1
        target.Size=Vector3.new(0.1,0.1,0.1); target.Parent=Workspace
        local targetAttachment = Instance.new("Attachment", target)
        local beam = Instance.new("Beam")
        beam.Attachment0=attachment; beam.Attachment1=targetAttachment
        beam.Width0=0.25; beam.Width1=0.25; beam.FaceCamera=true
        beam.LightEmission=1; beam.Transparency=NumberSequence.new(0.3)
        beam.Color=ColorSequence.new(lineColors[((index-1)%#lineColors)+1])
        beam.Parent=head
        lines[player] = {beam=beam, target=target, attachment=attachment}
    end
    lines[player].target.Position = head.Position + rootPart.CFrame.LookVector * lineDistance
end

local function applyJumpESP(player)
    if not player.Character or espHighlights[player] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "JumpESP"; hl.Adornee = player.Character
    hl.FillTransparency = 1; hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.fromRGB(255,255,0)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = player.Character
    espHighlights[player] = hl
end

local function removeJumpESP(player)
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
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
                if newState==Enum.HumanoidStateType.Jumping or newState==Enum.HumanoidStateType.Freefall then
                    applyJumpESP(player)
                elseif newState==Enum.HumanoidStateType.Landed then
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

local function SetupAntiCheatBypass()
    pcall(function()
        if not getrawmetatable then return end
        local mt = getrawmetatable(game)
        if not mt then return end
        local oldNC = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local name = tostring(self):lower()
                if name:find("kick") or name:find("ban") or name:find("anti") or
                   name:find("cheat") or name:find("detect") or name:find("hack") or
                   name:find("exploit") or name:find("flag") or name:find("punish") or
                   name:find("security") or name:find("stun") or name:find("ragdoll") or
                   name:find("verify") or name:find("validate") then
                    if not BlockedRemotes[name] then
                        BlockedRemotes[name] = true
                        Notify("AC Bypass", "Blocked: " .. tostring(self))
                    end
                    return nil
                end
            end
            if method == "Kick" and (self == LP or self == LP.Character) then
                Notify("AC Bypass", "Kick blocked")
                return nil
            end
            return oldNC(self, ...)
        end)
        setreadonly(mt, true)
    end)
    pcall(function()
        if hookfunction then
            hookfunction(LP.Kick, function(self) if self == LP then return nil end end)
        end
    end)
end

local function CreateReachCircle()
    pcall(function()
        if ReachGui then SafeDestroy(ReachGui) end
        ReachGui = Instance.new("ScreenGui")
        ReachGui.Name = "RixReachGui"; ReachGui.ResetOnSpawn = false
        ReachGui.IgnoreGuiInset = true; ReachGui.Parent = LP.PlayerGui
        ReachCircle = Instance.new("Frame")
        ReachCircle.AnchorPoint = Vector2.new(0.5, 0.5)
        ReachCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
        ReachCircle.Size = UDim2.new(0, ReachDistance*8, 0, ReachDistance*8)
        ReachCircle.BackgroundTransparency = 0.85
        ReachCircle.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
        ReachCircle.BorderSizePixel = 0; ReachCircle.Parent = ReachGui
        local corner = Instance.new("UICorner"); corner.CornerRadius=UDim.new(1,0); corner.Parent=ReachCircle
        local stroke = Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(0,255,200); stroke.Thickness=2; stroke.Parent=ReachCircle
        local label = Instance.new("TextLabel")
        label.Size=UDim2.new(1,0,0,20); label.Position=UDim2.new(0,0,1,5)
        label.BackgroundTransparency=1; label.TextColor3=Color3.fromRGB(0,255,200)
        label.TextSize=14; label.Font=Enum.Font.GothamBold
        label.Text=tostring(ReachDistance).." studs"; label.Parent=ReachCircle
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
                airBodyVelocity = Instance.new("BodyVelocity")
                airBodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5)
                airBodyVelocity.Velocity = Vector3.zero
                airBodyVelocity.P = 2500
                airBodyVelocity.Name = "AirControlVelocity"
                airBodyVelocity.Parent = hrp
            end
        elseif newState == Enum.HumanoidStateType.Landed then
            if airBodyVelocity then
                airBodyVelocity:Destroy()
                airBodyVelocity = nil
            end
            hum.AutoRotate = true
        end
    end)
end

if LP.Character then setupCharacterAir(LP.Character) end
LP.CharacterAdded:Connect(setupCharacterAir)

RunService.RenderStepped:Connect(function()
    if airMovement and airBodyVelocity and LP.Character then
        local hum = LP.Character:FindFirstChild("Humanoid")
        if hum then airBodyVelocity.Velocity = hum.MoveDirection * airMovementSpeed end
    end
    if linesEnabled then
        local idx = 0
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then
                local sameTeam = LP.Team ~= nil and player.Team ~= nil and player.Team == LP.Team
                if not sameTeam then
                    idx = idx + 1
                    updateLine(player, idx)
                else
                    removeLine(player)
                end
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
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, vbMaxPower, false, game)
        end)
    end

    if input.KeyCode == vbSetForward and vbSetting then
        local char = LP.Character
        if char then
            if LP.TeamColor == BrickColor.new("Really blue") then
                lookAt(char, vbLeft)
            else
                lookAt(char, vbRight)
            end
        end
    end

    if input.KeyCode == vbSetBack and vbSetting then
        local char = LP.Character
        if char then
            if LP.TeamColor == BrickColor.new("Really red") then
                lookAway(char, vbLeft)
            else
                lookAway(char, vbRight)
            end
        end
    end

    if input.KeyCode == Enum.KeyCode.Space and vbServing then
        local char = LP.Character
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
        local char = LP.Character
        local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
        if torso then
            if vbSpikeMode == "random" then
                if LP.TeamColor == BrickColor.new("Really blue") and torso.Position.Z < 40 and vbRedSpike then
                    local rP = Instance.new("Part")
                    rP.Anchored=true; rP.Transparency=1; rP.CanCollide=false
                    local range=20
                    rP.Position = vbRedSpike.Position + Vector3.new(math.random(-range,range),10,math.random(-range,range))
                    rP.Parent = Workspace
                    lookAt(char, rP)
                    rP:Destroy()
                elseif LP.TeamColor == BrickColor.new("Really red") and torso.Position.Z > -40 and vbBluSpike then
                    local rP = Instance.new("Part")
                    rP.Anchored=true; rP.Transparency=1; rP.CanCollide=false
                    local range=20
                    rP.Position = vbBluSpike.Position + Vector3.new(math.random(-range,range),10,math.random(-range,range))
                    rP.Parent = Workspace
                    lookAt(char, rP)
                    rP:Destroy()
                end
            elseif vbSpikeMode == "point" then
                if (LP.TeamColor==BrickColor.new("Really blue") and torso.Position.Z < 40) or
                   (LP.TeamColor==BrickColor.new("Really red") and torso.Position.Z > -40) then
                    local p = Instance.new("Part")
                    p.Anchored=true; p.CanCollide=false
                    p.CFrame=CFrame.new(Mouse.Hit.X, 10, Mouse.Hit.Z)
                    p.Transparency=1; p.Parent=Workspace
                    lookAt(char, p)
                    p:Destroy()
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
            VirtualInputManager:SendKeyEvent(true, vbSprintKey, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(true, vbSprintKey, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(true, vbSprintKey, false, game)
        end)
    end
end)

local enablejoin = false

-- Кэшируем RF один раз
local joinRF = nil
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

-- Основной Auto Join цикл
local function teamSelection()
    task.spawn(function()
        local rf = getJoinRF()
        if not rf then
            Notify("Auto Join", "❌ RF not found! Try later.")
            enablejoin = false
            return
        end

        Notify("Auto Join", "🔍 Scanning teams...")

        while enablejoin do
            -- Команда 1: слоты 1 → 6
            for slot = 1, 6 do
                if not enablejoin then return end
                local ok, res = pcall(function()
                    return rf:InvokeServer(1, slot)
                end)
                if ok and res then
                    Notify("Auto Join", "✅ Team 1 | Slot " .. slot)
                    enablejoin = false
                    return
                end
                task.wait(0.2)
            end

            if not enablejoin then return end

            -- Команда 2: слоты 1 → 6
            for slot = 1, 6 do
                if not enablejoin then return end
                local ok, res = pcall(function()
                    return rf:InvokeServer(2, slot)
                end)
                if ok and res then
                    Notify("Auto Join", "✅ Team 2 | Slot " .. slot)
                    enablejoin = false
                    return
                end
                task.wait(0.2)
            end

            -- Пауза перед следующим полным циклом
            task.wait(0.5)
        end
    end)
end

startRoundOverChecker()

local TVolleyball  = Window:CreateTab({ Name="Volleyball 4.2", Icon="sports_volleyball", ImageSource="Material", ShowTitle=true })
local TMovement    = Window:CreateTab({ Name="Movement",       Icon="directions_run",    ImageSource="Material", ShowTitle=true })
local TAutoFarm    = Window:CreateTab({ Name="Auto Farm",      Icon="agriculture",       ImageSource="Material", ShowTitle=true })
local TAutoSpin    = Window:CreateTab({ Name="Auto Spin",      Icon="sync",              ImageSource="Material", ShowTitle=true })
local TPower       = Window:CreateTab({ Name="Powers",         Icon="bolt",              ImageSource="Material", ShowTitle=true })
local THitboxes    = Window:CreateTab({ Name="Hitboxes",       Icon="open_with",         ImageSource="Material", ShowTitle=true })
local TVisuals     = Window:CreateTab({ Name="Visuals",        Icon="visibility",        ImageSource="Material", ShowTitle=true })
local TProtection  = Window:CreateTab({ Name="Protection",     Icon="security",          ImageSource="Material", ShowTitle=true })
local TAbout       = Window:CreateTab({ Name="About",          Icon="info",              ImageSource="Material", ShowTitle=true })

TVolleyball:CreateSection("Game Modes")

TVolleyball:CreateToggle({
    Name="Setting Mode (F=Forward / R=Back)",
    CurrentValue=false,
    Callback=function(v)
        vbSetting = v
        if v then placeAntennas() Notify("Setting","ON — F=forward R=back")
        else removeAntennas() Notify("Setting","OFF") end
    end
})

TVolleyball:CreateToggle({
    Name="Serving Mode (auto aim corners)",
    CurrentValue=false,
    Callback=function(v)
        vbServing = v
        if v then placeServeCorners() Notify("Serving","ON — aims at corners on jump")
        else removeServeCorners() Notify("Serving","OFF") end
    end
})

TVolleyball:CreateToggle({
    Name="Spiking Mode",
    CurrentValue=false,
    Callback=function(v)
        vbSpiking = v
        if v then placeSpikeZones() Notify("Spiking","ON — jumps aim spike zone")
        else removeSpikeZones() Notify("Spiking","OFF") end
    end
})

TVolleyball:CreateDropdown({
    Name="Spike Mode",
    Options={"random","point"},
    CurrentOption={"random"},
    MultipleOptions=false,
    Callback=function(option)
        vbSpikeMode = type(option)=="table" and option[1] or option
        Notify("Spike Mode", vbSpikeMode)
    end
})

TVolleyball:CreateDivider()

TVolleyball:CreateToggle({
    Name="Power Mode (auto max power on jump)",
    CurrentValue=false,
    Callback=function(v)
        vbPower = v
        Notify("Power Mode", v and "ON" or "OFF")
    end
})

TVolleyball:CreateToggle({
    Name="Sprint Mode (auto sprint on WASD)",
    CurrentValue=false,
    Callback=function(v)
        vbSprint = v
        Notify("Sprint Mode", v and "ON" or "OFF")
    end
})

TVolleyball:CreateDivider()
TVolleyball:CreateSection("Keybind Settings")

TVolleyball:CreateDropdown({
    Name="Set Forward Key",
    Options={"F","R","E","Q","G","H","X","Z"},
    CurrentOption={"F"},
    MultipleOptions=false,
    Callback=function(opt)
        local k = type(opt)=="table" and opt[1] or opt
        vbSetForward = Enum.KeyCode[k] or Enum.KeyCode.F
        Notify("Set Forward", k)
    end
})

TVolleyball:CreateDropdown({
    Name="Set Backward Key",
    Options={"R","F","E","Q","G","H","X","Z"},
    CurrentOption={"R"},
    MultipleOptions=false,
    Callback=function(opt)
        local k = type(opt)=="table" and opt[1] or opt
        vbSetBack = Enum.KeyCode[k] or Enum.KeyCode.R
        Notify("Set Backward", k)
    end
})

TVolleyball:CreateDropdown({
    Name="Max Power Key",
    Options={"C","V","B","X","Z","G","H"},
    CurrentOption={"C"},
    MultipleOptions=false,
    Callback=function(opt)
        local k = type(opt)=="table" and opt[1] or opt
        vbMaxPower = Enum.KeyCode[k] or Enum.KeyCode.C
        Notify("Max Power Key", k)
    end
})

TVolleyball:CreateDropdown({
    Name="Sprint Key",
    Options={"T","Y","U","G","H","B"},
    CurrentOption={"T"},
    MultipleOptions=false,
    Callback=function(opt)
        local k = type(opt)=="table" and opt[1] or opt
        vbSprintKey = Enum.KeyCode[k] or Enum.KeyCode.T
        Notify("Sprint Key", k)
    end
})

TVolleyball:CreateDivider()
TVolleyball:CreateSection("Ball Prediction")

TVolleyball:CreateToggle({
    Name="Ball Trajectory Prediction",
    CurrentValue=false,
    Callback=function(v)
        disconnect("Trajectory")
        if v then
            Connections.Trajectory = RunService.Heartbeat:Connect(function()
                FrameCounter = FrameCounter + 1
                if FrameCounter % 2 ~= 0 then return end
                for _, line in ipairs(TrajectoryLines) do SafeDestroy(line) end
                TrajectoryLines = {}
                local ball = FindBall()
                if not ball then return end
                local startPos = ball.Position
                local velocity = ball.Velocity
                local gravity = Workspace.Gravity
                local points = {}
                for t = 0, 3, 0.15 do
                    table.insert(points, startPos + velocity*t + Vector3.new(0, -0.5*gravity*t*t, 0))
                end
                for i = 1, #points-1 do
                    local line = Instance.new("Part")
                    line.Anchored=true; line.CanCollide=false
                    line.Size=Vector3.new(0.3, 0.3, (points[i]-points[i+1]).Magnitude)
                    line.CFrame=CFrame.lookAt(points[i], points[i+1])*CFrame.new(0,0,-line.Size.Z/2)
                    line.Color=Color3.fromRGB(255,100,100)
                    line.Material=Enum.Material.Neon
                    line.Transparency=0.3; line.Parent=Workspace
                    table.insert(TrajectoryLines, line)
                end
            end)
            Notify("Ball Trajectory","ON")
        else
            for _, line in ipairs(TrajectoryLines) do SafeDestroy(line) end
            TrajectoryLines = {}
            Notify("Ball Trajectory","OFF")
        end
    end
})

TMovement:CreateSection("Speed & Jump")
TMovement:CreateToggle({
    Name="Speed Boost", CurrentValue=false,
    Callback=function(v)
        disconnect("Speed")
        if v then
            Connections.Speed=RunService.Heartbeat:Connect(function()
                local hum=getHum(); if hum then hum.WalkSpeed=16*SpeedMult end
            end)
            Notify("Speed","x"..string.format("%.1f",SpeedMult))
        else
            local hum=getHum(); if hum then hum.WalkSpeed=OriginalWalkSpeed end
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
            Connections.Jump=RunService.Heartbeat:Connect(function()
                local hum=getHum(); if hum then hum.JumpHeight=OriginalJumpHeight*JumpMult end
            end)
            Notify("Jump","x"..string.format("%.1f",JumpMult))
        else
            local hum=getHum(); if hum then hum.JumpHeight=OriginalJumpHeight end
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
            Connections.InfiniteJump=UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.KeyCode==Enum.KeyCode.Space and not IsJumping then
                    IsJumping=true
                    local hrp=getHRP(); local hum=getHum()
                    if hrp and hum then
                        if hum.FloorMaterial==Enum.Material.Air then
                            local bv=Instance.new("BodyVelocity")
                            bv.MaxForce=Vector3.new(0,math.huge,0); bv.Velocity=Vector3.new(0,30,0); bv.Parent=hrp
                            Debris:AddItem(bv,0.1)
                        end
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
            Connections.InfiniteJumpEnd=UserInputService.InputEnded:Connect(function(input)
                if input.KeyCode==Enum.KeyCode.Space then IsJumping=false end
            end)
            Notify("Infinite Jump","ON")
        else IsJumping=false; Notify("Infinite Jump","OFF") end
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
        airMovement=v
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
            Connections.Gravity=RunService.Heartbeat:Connect(function()
                local hrp=getHRP()
                if hrp then
                    local vel=hrp.Velocity
                    if vel.Y<-5 then hrp.Velocity=Vector3.new(vel.X,vel.Y*GravityMult,vel.Z) end
                end
            end)
            Notify("Gravity","x"..GravityMult)
        else Notify("Gravity","OFF") end
    end
})
TMovement:CreateSlider({ Name="Gravity Multiplier", Range={0.1,1}, Increment=0.1, CurrentValue=0.5, Callback=function(v) GravityMult=v end })
TMovement:CreateDivider()

TMovement:CreateToggle({
    Name="Anti Stun", CurrentValue=false,
    Callback=function(v)
        disconnect("AntiStun")
        if v then
            Connections.AntiStun=RunService.Heartbeat:Connect(function()
                local hum=getHum()
                if hum then
                    if hum.PlatformStand then hum.PlatformStand=false end
                    local state=hum:GetState()
                    if state==Enum.HumanoidStateType.Physics or state==Enum.HumanoidStateType.Ragdoll then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end
            end)
            Notify("Anti Stun","ON")
        else Notify("Anti Stun","OFF") end
    end
})

TMovement:CreateToggle({
    Name="Anti Ragdoll", CurrentValue=false,
    Callback=function(v)
        disconnect("AntiRagdoll")
        if v then
            Connections.AntiRagdoll=RunService.Heartbeat:Connect(function()
                local char=getChar(); if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BallSocketConstraint") or part:IsA("HingeConstraint") then SafeDestroy(part) end
                end
                local hum=getHum()
                if hum then
                    if hum.PlatformStand then hum.PlatformStand=false end
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
            Notify("Anti Ragdoll","ON")
        else Notify("Anti Ragdoll","OFF") end
    end
})
TMovement:CreateDivider()

TMovement:CreateToggle({
    Name="Enable Rotate In Air", CurrentValue=false,
    Callback=function(v)
        disconnect("RotateAir")
        if v then
            Connections.RotateAir=RunService.Heartbeat:Connect(function()
                local hum=getHum(); if hum and not hum.AutoRotate then hum.AutoRotate=true end
            end)
            Notify("Rotate Air","ON")
        else Notify("Rotate Air","OFF") end
    end
})
TMovement:CreateDivider()

TMovement:CreateToggle({
    Name="Spin Mod", CurrentValue=false,
    Callback=function(v)
        disconnect("Spin")
        if v then
            Connections.Spin=RunService.Heartbeat:Connect(function()
                local hrp=getHRP()
                if hrp then hrp.CFrame=hrp.CFrame*CFrame.Angles(0,math.rad(SpinSpd),0) end
            end)
            Notify("Spin","Speed "..SpinSpd)
        else Notify("Spin","OFF") end
    end
})
TMovement:CreateSlider({ Name="Spin Speed", Range={1,150}, Increment=1, CurrentValue=15, Callback=function(v) SpinSpd=v end })
TMovement:CreateDivider()

TMovement:CreateToggle({
    Name="Fly Mode (WASD+Space/Ctrl)", CurrentValue=false,
    Callback=function(v)
        disconnect("Fly")
        if v then
            local hrp=getHRP()
            if hrp then
                bodyVelocity=Instance.new("BodyVelocity")
                bodyVelocity.Parent=hrp; bodyVelocity.MaxForce=Vector3.new(999999,999999,999999)
                bodyVelocity.Velocity=Vector3.new(0,0,0)
            end
            Connections.Fly=RunService.Heartbeat:Connect(function()
                local hrp=getHRP(); if not hrp or not bodyVelocity then return end
                local move=Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move=move+hrp.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move=move-hrp.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move=move-hrp.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move=move+hrp.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move=move+Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move=move-Vector3.new(0,1,0) end
                bodyVelocity.Velocity=move.Magnitude>0 and move.Unit*FlySpd or Vector3.new(0,0,0)
            end)
            Notify("Fly","WASD+Space/Ctrl")
        else SafeDestroy(bodyVelocity); bodyVelocity=nil; Notify("Fly","OFF") end
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
                PlatformPart=Instance.new("Part"); PlatformPart.Name="RixPlatform"
                PlatformPart.Size=Vector3.new(8,1,8); PlatformPart.CanCollide=true
                PlatformPart.Material=Enum.Material.Neon; PlatformPart.BrickColor=BrickColor.new("Cyan")
                PlatformPart.Anchored=true; PlatformPart.Transparency=0.3; PlatformPart.Parent=Workspace
            end
            Connections.Platform=RunService.Heartbeat:Connect(function()
                local hrp=getHRP()
                if hrp and PlatformPart then
                    PlatformPart.CFrame=CFrame.new(hrp.Position.X, hrp.Position.Y-PlatHeight, hrp.Position.Z)
                end
            end)
            Notify("Platform","ON")
        else SafeDestroy(PlatformPart); PlatformPart=nil; Notify("Platform","OFF") end
    end
})
TMovement:CreateSlider({ Name="Platform Height", Range={3,20}, Increment=1, CurrentValue=8, Callback=function(v) PlatHeight=v end })

-- AUTO FARM CONFIG
-- ============================================================
-- AUTO FARM CONFIG
-- ============================================================
local farmFlySpeed   = 60
local farmHitDist    = 12
local farmPredictMul = 0.35
local farmAutoJump   = true
local farmAutoClick  = true
local farmFlyBV      = nil

-- Тип удара: "spike" | "bump" | "dive" | "set" | "auto"
local farmHitMode    = "auto"

-- Клавиши для каждого удара (настраивается)
local farmKeySpike   = Enum.KeyCode.Q
local farmKeyBump    = Enum.KeyCode.E
local farmKeyDive    = Enum.KeyCode.R
local farmKeySet     = Enum.KeyCode.F

local function predictBallPos(ball, seconds)
    local vel  = ball.Velocity
    local grav = Workspace.Gravity
    return ball.Position
        + vel * seconds
        + Vector3.new(0, -0.5 * grav * seconds * seconds, 0)
end

local function farmFlyCreate()
    local hrp = getHRP()
    if not hrp then return end
    if farmFlyBV then pcall(function() farmFlyBV:Destroy() end) end
    farmFlyBV          = Instance.new("BodyVelocity")
    farmFlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    farmFlyBV.Velocity = Vector3.new(0, 0, 0)
    farmFlyBV.P        = 5000
    farmFlyBV.Name     = "FarmFlyBV"
    farmFlyBV.Parent   = hrp
end

local function farmFlyDestroy()
    if farmFlyBV then
        pcall(function() farmFlyBV:Destroy() end)
        farmFlyBV = nil
    end
end

local function farmFlyTo(targetPos)
    local hrp = getHRP()
    if not hrp or not farmFlyBV then return end
    local dir  = (targetPos - hrp.Position)
    local dist = dir.Magnitude
    if dist < 0.5 then
        farmFlyBV.Velocity = Vector3.new(0, 0, 0)
        return
    end
    local speed = math.min(farmFlySpeed, dist * 6)
    farmFlyBV.Velocity = dir.Unit * speed
    local lookDir = Vector3.new(dir.X, 0, dir.Z)
    if lookDir.Magnitude > 0.1 then
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + lookDir.Unit)
    end
end

-- Отправить нажатие клавиши удара
local function pressHitKey(mode)
    local key
    if mode == "spike" then key = farmKeySpike
    elseif mode == "bump" then key = farmKeyBump
    elseif mode == "dive" then key = farmKeyDive
    elseif mode == "set"  then key = farmKeySet
    end
    if key then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true,  key, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end)
    end
end

-- Определить лучший удар автоматически по позиции мяча
local function getBestHitMode(ball, hrp)
    if not ball or not hrp then return "bump" end
    local ballY  = ball.Position.Y
    local myY    = hrp.Position.Y
    local diff   = ballY - myY
    local speed  = ball.Velocity.Magnitude

    if diff > 6 and speed > 10 then
        return "spike"   -- мяч высоко и летит — спайк
    elseif diff < -1 then
        return "dive"    -- мяч ниже нас — дайв
    elseif diff > 2 and speed < 10 then
        return "set"     -- мяч немного выше и медленно — сет
    else
        return "bump"    -- всё остальное — бамп
    end
end

-- Позиция для каждого типа удара
local function getTargetOffset(mode)
    if mode == "spike" then
        return Vector3.new(0,  4, 0)   -- лететь выше мяча
    elseif mode == "bump" then
        return Vector3.new(0, -2, 0)   -- лететь ниже мяча
    elseif mode == "dive" then
        return Vector3.new(0,  0, 0)   -- прямо к мячу
    elseif mode == "set" then
        return Vector3.new(0,  1, 0)   -- чуть ниже мяча
    end
    return Vector3.new(0, 2, 0)
end

-- ============================================================
-- ENEMY TARGETING FOR SPIKE
-- ============================================================
local farmAimEnemy = true   -- включать/выключать прицел на врага

-- Найти ближайшего живого врага противоположной команды
local function findNearestEnemy(hrp)
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        -- Разные команды
        local isEnemy = (LP.Team == nil) or
                        (player.Team ~= nil and player.Team ~= LP.Team)
        if not isEnemy then continue end
        local char = player.Character
        if not char then continue end
        local eHRP = char:FindFirstChild("HumanoidRootPart")
        local eHum = char:FindFirstChildOfClass("Humanoid")
        if not eHRP or not eHum or eHum.Health <= 0 then continue end
        local d = (eHRP.Position - hrp.Position).Magnitude
        if d < bestDist then
            bestDist = d
            best     = eHRP
        end
    end
    return best
end

-- Направление в сторону вражеской зоны (по Z-оси корта)
-- В Volleyball Legends корт делится по оси Z: ~ < 0 и > 0
local function getEnemyZoneDir(hrp)
    if not hrp then return Vector3.new(0, 0, 1) end
    -- Определяем на какой половине стоим
    local myZ = hrp.Position.Z
    -- Противник на другой стороне
    return myZ < 0
        and Vector3.new(0, 0,  1)   -- мы на отрицательной → враг на положительной
        or  Vector3.new(0, 0, -1)   -- мы на положительной → враг на отрицательной
end

-- Рассчитать оффсет подлёта к мячу для Spike:
-- летим СЗАДИ мяча относительно врагов, чтобы спайк летел вперёд
local function getSpikeApproachPos(ball, hrp)
    if not ball then return hrp.Position end
    local enemyDir = getEnemyZoneDir(hrp)
    -- Встаём позади мяча (со своей стороны) и выше
    return ball.Position - enemyDir * 3 + Vector3.new(0, 4, 0)
end

-- ============================================================
-- AUTO FARM UI
-- ============================================================
TAutoFarm:CreateSection("Auto Farm Settings")

TAutoFarm:CreateDropdown({
    Name = "Hit Mode",
    Options = {"auto","spike","bump","dive","set"},
    CurrentOption = {"auto"},
    MultipleOptions = false,
    Callback = function(opt)
        farmHitMode = type(opt)=="table" and opt[1] or opt
        Notify("Farm Mode", farmHitMode)
    end
})

TAutoFarm:CreateToggle({
    Name = "Aim at Enemy on Spike",
    CurrentValue = true,
    Callback = function(v)
        farmAimEnemy = v
        Notify("Aim Enemy", v and "ON — spike aims at nearest enemy" or "OFF")
    end
})

TAutoFarm:CreateSlider({
    Name = "Farm Fly Speed",
    Range = {10, 200}, Increment = 5, CurrentValue = 60,
    Callback = function(v) farmFlySpeed = v end
})

TAutoFarm:CreateSlider({
    Name = "Hit Distance",
    Range = {5, 30}, Increment = 1, CurrentValue = 12,
    Callback = function(v) farmHitDist = v end
})

TAutoFarm:CreateSlider({
    Name = "Ball Prediction (seconds)",
    Range = {0, 1}, Increment = 0.05, CurrentValue = 0.35,
    Callback = function(v) farmPredictMul = v end
})

TAutoFarm:CreateDivider()
TAutoFarm:CreateSection("Hit Keys")

TAutoFarm:CreateDropdown({
    Name = "Spike Key",
    Options = {"Q","E","R","F","G","H","X","Z","V"},
    CurrentOption = {"Q"},
    MultipleOptions = false,
    Callback = function(opt)
        local k = type(opt)=="table" and opt[1] or opt
        farmKeySpike = Enum.KeyCode[k] or Enum.KeyCode.Q
    end
})

TAutoFarm:CreateDropdown({
    Name = "Bump Key",
    Options = {"E","Q","R","F","G","H","X","Z","V"},
    CurrentOption = {"E"},
    MultipleOptions = false,
    Callback = function(opt)
        local k = type(opt)=="table" and opt[1] or opt
        farmKeyBump = Enum.KeyCode[k] or Enum.KeyCode.E
    end
})

TAutoFarm:CreateDropdown({
    Name = "Dive Key",
    Options = {"R","Q","E","F","G","H","X","Z","V"},
    CurrentOption = {"R"},
    MultipleOptions = false,
    Callback = function(opt)
        local k = type(opt)=="table" and opt[1] or opt
        farmKeyDive = Enum.KeyCode[k] or Enum.KeyCode.R
    end
})

TAutoFarm:CreateDropdown({
    Name = "Set Key",
    Options = {"F","Q","E","R","G","H","X","Z","V"},
    CurrentOption = {"F"},
    MultipleOptions = false,
    Callback = function(opt)
        local k = type(opt)=="table" and opt[1] or opt
        farmKeySet = Enum.KeyCode[k] or Enum.KeyCode.F
    end
})

TAutoFarm:CreateDivider()
TAutoFarm:CreateSection("Auto Farm")

TAutoFarm:CreateToggle({
    Name = "Auto Jump on hit",
    CurrentValue = true,
    Callback = function(v) farmAutoJump = v end
})

TAutoFarm:CreateToggle({
    Name = "Auto Click on hit",
    CurrentValue = true,
    Callback = function(v) farmAutoClick = v end
})

TAutoFarm:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Callback = function(v)
        autoFarm = v

        if v then
            farmFlyCreate()

            task.spawn(function()
                local lastHitTime = 0
                local hitCooldown = 0.55
                local stuckTimer  = 0
                local lastPos     = Vector3.new(0,0,0)

                while autoFarm do
                    task.wait(0.05)
                    pcall(function()
                        local hrp = getHRP()
                        local hum = getHum()
                        if not hrp or not hum then return end

                        -- Ищем мяч: сначала модель CLIENT_BALL, потом любой BasePart
                        local ball = getBallModel() or FindBall()
                        if not ball then
                            if farmFlyBV then farmFlyBV.Velocity = Vector3.new(0,0,0) end
                            return
                        end

                        -- Определяем режим
                        local mode = farmHitMode == "auto"
                            and getBestHitMode(ball, hrp)
                            or  farmHitMode

                        -- Выбор позиции подлёта
                        local targetPos
                        if mode == "spike" then
                            -- Для спайка — подлетаем со своей стороны позади мяча
                            targetPos = getSpikeApproachPos(ball, hrp)
                        else
                            local predicted = predictBallPos(ball, farmPredictMul)
                            targetPos = predicted + getTargetOffset(mode)
                        end

                        local dist = (ball.Position - hrp.Position).Magnitude

                        -- Застрял?
                        if (hrp.Position - lastPos).Magnitude < 0.3 and dist > farmHitDist + 3 then
                            stuckTimer = stuckTimer + 0.05
                        else
                            stuckTimer = 0
                        end
                        lastPos = hrp.Position

                        if stuckTimer > 1.0 then
                            stuckTimer = 0
                            hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
                        else
                            farmFlyTo(targetPos)
                        end

                        -- Удар
                        local now = tick()
                        if dist <= farmHitDist and (now - lastHitTime) >= hitCooldown then
                            lastHitTime = now

                            if mode == "spike" and farmAimEnemy then
                                -- Spike: смотрим на ближайшего врага
                                local enemyHRP = findNearestEnemy(hrp)
                                if enemyHRP then
                                    -- Смотрим точно на врага (Y = 0 чтобы не задирать голову)
                                    local dir = Vector3.new(
                                        enemyHRP.Position.X - hrp.Position.X,
                                        0,
                                        enemyHRP.Position.Z - hrp.Position.Z
                                    )
                                    if dir.Magnitude > 0.1 then
                                        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir.Unit)
                                    end
                                else
                                    -- Врагов нет — смотрим в сторону их зоны
                                    local dir = getEnemyZoneDir(hrp)
                                    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir)
                                end
                            else
                                -- Остальные удары: смотрим на мяч
                                local lookDir = Vector3.new(
                                    ball.Position.X - hrp.Position.X,
                                    0,
                                    ball.Position.Z - hrp.Position.Z
                                )
                                if lookDir.Magnitude > 0.1 then
                                    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + lookDir.Unit)
                                end
                            end

                            -- Прыжок для spike/set
                            local needJump = (mode == "spike" or mode == "set")
                            if farmAutoJump and needJump then
                                VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
                                task.wait(0.08)
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                                task.wait(0.05)
                            end

                            -- Клавиша удара
                            pressHitKey(mode)

                            -- Клик мышью
                            if farmAutoClick then
                                task.wait(0.04)
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
                                task.wait(0.04)
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                            end
                        end
                    end)
                end

                farmFlyDestroy()
            end)

            Notify("Auto Farm", "ON | mode: " .. farmHitMode)
        else
            autoFarm = false
            farmFlyDestroy()
            Notify("Auto Farm", "OFF")
        end
    end
})

TAutoFarm:CreateDivider()
TAutoFarm:CreateSection("Auto Join Match")

TAutoFarm:CreateLabel({ Text = "Tries Team 1 (slots 1-6) → Team 2 (slots 1-6)" })

TAutoFarm:CreateToggle({
    Name = "Auto Join Match",
    CurrentValue = false,
    Callback = function(v)
        enablejoin = v
        autoJoin   = v
        if v then
            teamSelection()
            Notify("Auto Join", "ON — scanning both teams...")
        else
            enablejoin = false
            Notify("Auto Join", "OFF")
        end
    end
})

TAutoFarm:CreateButton({
    Name = "Join Now (one attempt)",
    Callback = function()
        local rf = getJoinRF()
        if not rf then
            Notify("Join", "❌ RF not found — open lobby first")
            return
        end
        for team = 1, 2 do
            for slot = 1, 6 do
                local ok, res = pcall(function() return rf:InvokeServer(team, slot) end)
                if ok and res then
                    Notify("Join", "✅ Team " .. team .. " Slot " .. slot)
                    return
                end
                task.wait(0.15)
            end
        end
        Notify("Join", "No free slots found")
    end
})

TAutoFarm:CreateDivider()
TAutoFarm:CreateSection("Match Controls")

TAutoFarm:CreateToggle({
    Name="Powerful Serve (press Z)", CurrentValue=false,
    Callback=function(v) powerfulServe=v; Notify("Powerful Serve",v and "ON — press Z" or "OFF") end
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

TAutoFarm:CreateButton({
    Name="Rejoin Server",
    Callback=function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
    end
})

TAutoSpin:CreateSection("Style Spinner")

local spinToggleRef    = nil
local spinChangedConn  = nil

-- Получить текстовый лейбл стиля
local function getStyleLabel()
    local ok, lbl = pcall(function()
        return LP.PlayerGui.Interface.Lobby.Styles.TopPanel.DisplayName
    end)
    return (ok and lbl and lbl:IsA("TextLabel")) and lbl or nil
end

local function getCurrentStyle()
    local lbl = getStyleLabel()
    return lbl and lbl.Text or nil
end

local function getStyleRF()
    local ok, rf = pcall(function()
        return ReplicatedStorage
            :WaitForChild("Packages",    10)
            :WaitForChild("_Index",      10)
            :WaitForChild("sleitnick_knit@1.7.0", 10)
            :WaitForChild("knit",        10)
            :WaitForChild("Services",    10)
            :WaitForChild("StyleService",10)
            :WaitForChild("RF",          10)
            :WaitForChild("Roll",        10)
    end)
    return (ok and rf) and rf or nil
end

-- Вызывается при каждом изменении стиля (мгновенно)
local function onStyleChanged(newText)
    if not autoSpin then return end
    if not newText or newText == "" then return end
    if table.find(desiredStyles, newText) then
        -- МГНОВЕННАЯ остановка
        autoSpin = false
        if spinChangedConn then
            spinChangedConn:Disconnect()
            spinChangedConn = nil
        end
        if spinToggleRef then
            task.defer(function() spinToggleRef:Set(false) end)
        end
        Luna:Notification({
            Title   = "🎉 Style Obtained!",
            Icon    = "check_circle",
            ImageSource = "Material",
            Content = "Got: " .. newText .. " — Spin stopped instantly!"
        })
    end
end

TAutoSpin:CreateDropdown({
    Name = "Desired Styles",
    Options = {"Oikawa","Bokuto","Kageyama","Sawamura","Ushijima",
               "Kozume","Kuroo","Yamamoto","Azumane","Yaku","Hinata"},
    CurrentOption = {"Hinata"},
    MultipleOptions = true,
    Callback = function(option)
        desiredStyles = type(option) == "table" and option or {option}
    end
})

spinToggleRef = TAutoSpin:CreateToggle({
    Name = "Auto Spin",
    CurrentValue = false,
    Callback = function(v)
        autoSpin = v

        -- Всегда отключаем старый listener
        if spinChangedConn then
            spinChangedConn:Disconnect()
            spinChangedConn = nil
        end

        if not v then
            Notify("Auto Spin", "Stopped")
            return
        end

        -- Проверяем что мы в лобби и StyleService доступен
        local rf = getStyleRF()
        if not rf then
            Notify("Auto Spin", "❌ StyleService not found! Open Lobby first.")
            autoSpin = false
            task.defer(function() spinToggleRef:Set(false) end)
            return
        end

        -- Проверяем сразу — вдруг нужный стиль уже есть
        local current = getCurrentStyle()
        if current and table.find(desiredStyles, current) then
            autoSpin = false
            task.defer(function() spinToggleRef:Set(false) end)
            Luna:Notification({
                Title   = "🎉 Already have it!",
                Icon    = "check_circle",
                ImageSource = "Material",
                Content = "Current style: " .. current
            })
            return
        end

        -- Подписываемся на Changed — ловим смену стиля МГНОВЕННО
        local lbl = getStyleLabel()
        if lbl then
            spinChangedConn = lbl:GetPropertyChangedSignal("Text"):Connect(function()
                onStyleChanged(lbl.Text)
            end)
        end

        Notify("Auto Spin", "Running → " .. table.concat(desiredStyles, ", "))

        -- Основной цикл роллов
        task.spawn(function()
            while autoSpin do
                -- Двойная защита: проверяем ДО ролла
                local pre = getCurrentStyle()
                if pre and table.find(desiredStyles, pre) then
                    onStyleChanged(pre)
                    break
                end

                local ok, err = pcall(function()
                    rf:InvokeServer(false)
                end)

                if not ok then
                    Notify("Auto Spin", "❌ Roll error: " .. tostring(err))
                    task.wait(1)
                end

                -- Минимальная задержка чтобы сервер успел ответить
                -- Changed listener поймает результат быстрее
                task.wait(0.25)
            end

            -- Чистим listener при выходе
            if spinChangedConn then
                spinChangedConn:Disconnect()
                spinChangedConn = nil
            end
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
    TPower:CreateSlider({
        Name=pName,
        Range=ps.range,
        Increment=0.1,
        CurrentValue=ps.default,
        Callback=function(v)
            pcall(function() LP:SetAttribute(pAttr, v) end)
        end
    })
    TPower:CreateDivider()
end

THitboxes:CreateSection("Ball Hitbox (Unified — Model + Part)")

THitboxes:CreateToggle({
    Name = "Ball Hitbox",
    CurrentValue = false,
    Callback = function(v)
        ballHitboxEnabled = v
        if v then
            enableBallHitbox()
            Notify("Ball Hitbox", "ON — size x" .. BallHitboxMult)
        else
            disableBallHitbox()
            Notify("Ball Hitbox", "OFF — restored")
        end
    end
})

THitboxes:CreateSlider({
    Name = "Ball Hitbox Size",
    Range = {1, 30}, Increment = 0.5, CurrentValue = 5,
    Callback = function(v)
        BallHitboxMult = v
        if ballHitboxEnabled then
            disableBallHitbox()
            enableBallHitbox()
        end
    end
})

THitboxes:CreateSection("Skill Hitboxes (ReplicatedStorage.Assets.Hitboxes)")

local hitboxList = {
    "Spike", "Block", "Bump", "Serve", "Dive", "Set", "JumpSet"
}
for _, hName in ipairs(hitboxList) do
    local hn=hName
    THitboxes:CreateSlider({
        Name=hn.." Hitbox Size",
        Range={1,100}, Increment=0.1, CurrentValue=10,
        Callback=function(v) setHitboxSize(hn, v) end
    })
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
                local hrp=player.Character:FindFirstChild("HumanoidRootPart")
                local myHRP=getHRP()
                if not hrp or not myHRP then return end
                local bb=Instance.new("BillboardGui")
                bb.Size=UDim2.new(8,0,4,0); bb.MaxDistance=ESPRange
                bb.Adornee=hrp; bb.AlwaysOnTop=true
                local frame=Instance.new("Frame")
                frame.Size=UDim2.new(1,0,1,0); frame.BackgroundTransparency=0.1; frame.BorderSizePixel=0; frame.Parent=bb
                CreateGradientFrame(frame, Color3.fromRGB(0,255,200), Color3.fromRGB(0,100,255))
                local label=Instance.new("TextLabel"); label.Parent=frame
                label.Size=UDim2.new(1,0,0.5,0); label.BackgroundTransparency=1
                label.TextColor3=Color3.fromRGB(255,255,255); label.Font=Enum.Font.GothamBold
                label.TextSize=16; label.Text=player.Name; label.TextStrokeTransparency=0
                local distLabel=Instance.new("TextLabel"); distLabel.Parent=frame
                distLabel.Size=UDim2.new(1,0,0.5,0); distLabel.Position=UDim2.new(0,0,0.5,0)
                distLabel.BackgroundTransparency=1; distLabel.TextColor3=Color3.fromRGB(200,255,255)
                distLabel.Font=Enum.Font.GothamBold; distLabel.TextSize=14
                distLabel.Text=math.floor((hrp.Position-myHRP.Position).Magnitude).."m"
                distLabel.TextStrokeTransparency=0
                Instance.new("UICorner", frame).CornerRadius=UDim.new(0,8)
                bb.Parent=Workspace; ESPObjects[player]=bb
            end
            for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
            Connections.ESPUpdate=RunService.Heartbeat:Connect(function()
                FrameCounter=FrameCounter+1
                if FrameCounter%UpdateInterval~=0 then return end
                local now=tick()
                if now-LastESPUpdate<ESPUpdateInterval then return end
                LastESPUpdate=now
                local myHRP=getHRP(); if not myHRP then return end
                for player, bb in pairs(ESPObjects) do
                    if player.Character and bb then
                        local hrp=player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local fr=bb:FindFirstChildOfClass("Frame")
                            if fr then
                                for _, lbl in ipairs(fr:GetChildren()) do
                                    if lbl:IsA("TextLabel") and lbl.Text:find("m") then
                                        lbl.Text=math.floor((hrp.Position-myHRP.Position).Magnitude).."m"
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            Notify("Player ESP","ON")
        else Notify("Player ESP","OFF") end
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
                local bb=Instance.new("BillboardGui")
                bb.Size=UDim2.new(10,0,5,0); bb.MaxDistance=BallESPRange
                bb.Adornee=ball; bb.AlwaysOnTop=true
                local frame=Instance.new("Frame")
                frame.Size=UDim2.new(1,0,1,0); frame.BackgroundTransparency=0.05; frame.BorderSizePixel=0; frame.Parent=bb
                CreateGradientFrame(frame, Color3.fromRGB(255,50,50), Color3.fromRGB(255,150,0))
                local label=Instance.new("TextLabel"); label.Parent=frame
                label.Size=UDim2.new(1,0,0.5,0); label.BackgroundTransparency=1
                label.TextColor3=Color3.fromRGB(255,255,255); label.Font=Enum.Font.GothamBold
                label.TextSize=18; label.Text="🏐 BALL"; label.TextStrokeTransparency=0
                local velLabel=Instance.new("TextLabel"); velLabel.Parent=frame
                velLabel.Size=UDim2.new(1,0,0.5,0); velLabel.Position=UDim2.new(0,0,0.5,0)
                velLabel.BackgroundTransparency=1; velLabel.TextColor3=Color3.fromRGB(255,255,200)
                velLabel.Font=Enum.Font.GothamBold; velLabel.TextSize=14
                velLabel.Text="Speed: "..math.floor(ball.Velocity.Magnitude); velLabel.TextStrokeTransparency=0
                Instance.new("UICorner", frame).CornerRadius=UDim.new(0,10)
                bb.Parent=Workspace; BallESPObjects[ball]=bb
            end
            local ball=FindBall(); if ball then createBallESP(ball) end
            Connections.BallESPUpdate=RunService.Heartbeat:Connect(function()
                FrameCounter=FrameCounter+1
                if FrameCounter%UpdateInterval~=0 then return end
                local ball=FindBall()
                if ball and not BallESPObjects[ball] then createBallESP(ball) end
            end)
            Notify("Ball ESP","ON")
        else Notify("Ball ESP","OFF") end
    end
})
TVisuals:CreateSlider({ Name="Ball ESP Range", Range={100,10000}, Increment=100, CurrentValue=5000, Callback=function(v) BallESPRange=v end })
TVisuals:CreateDivider()

TVisuals:CreateToggle({
    Name="Reach Circle (shows reach radius)", CurrentValue=false,
    Callback=function(v)
        if v then CreateReachCircle() Notify("Reach Circle",ReachDistance.." studs")
        else DestroyReachCircle() Notify("Reach Circle","OFF") end
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

TVisuals:CreateSlider({ Name="Fog End Distance", Range={0,10000}, Increment=50, CurrentValue=defaultFogEnd, Callback=function(v) Lighting.FogEnd=v end })
TVisuals:CreateSlider({ Name="Bloom Intensity", Range={0,5}, Increment=0.1, CurrentValue=0, Callback=function(v) bloomEffect.Intensity=v end })

TVisuals:CreateButton({
    Name="Reset Lighting",
    Callback=function()
        Lighting.Brightness=defaultBrightness; Lighting.Ambient=defaultAmbient
        Lighting.OutdoorAmbient=defaultOutdoorAmbient; Lighting.FogEnd=defaultFogEnd
        bloomEffect.Intensity=0; Notify("Lighting","Reset")
    end
})

-- ============================================================
-- FPS BOOST
-- ============================================================
TVisuals:CreateDivider()
TVisuals:CreateSection("FPS Boost")

local fpsBoostEnabled  = false
local savedDecals      = {}
local savedParticles   = {}
local savedTextures    = {}
local savedShadows     = Lighting.GlobalShadows
local savedFogEnd      = Lighting.FogEnd
local savedBrightness  = Lighting.Brightness

local function enableFPSBoost()
    -- Рендер качество через executor API
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    -- Тени
    Lighting.GlobalShadows   = false
    -- Атмосфера
    Lighting.FogEnd          = 100000
    Lighting.FogStart        = 99000
    Lighting.Brightness      = 2
    bloomEffect.Intensity    = 0
    -- Эффекты Lighting — отключаем все
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("PostEffect") or fx:IsA("Sky") or fx:IsA("Atmosphere") then
            fx.Enabled = false
        end
    end
    -- Частицы и декали — постепенно по 30 штук за раз чтобы не лагать
    task.spawn(function()
        local batch = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if not fpsBoostEnabled then break end
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or
               obj:IsA("Smoke") or obj:IsA("Sparkles") then
                savedParticles[obj] = obj.Enabled
                obj.Enabled = false
                batch = batch + 1
                if batch >= 30 then batch = 0; task.wait() end
            elseif obj:IsA("Decal") then
                savedDecals[obj] = obj.Transparency
                obj.Transparency = 1
                batch = batch + 1
                if batch >= 30 then batch = 0; task.wait() end
            end
        end
    end)
    Notify("FPS Boost", "✅ ON")
end

local function disableFPSBoost()
    -- Рендер качество назад
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end)
    -- Освещение
    Lighting.GlobalShadows = savedShadows
    Lighting.FogEnd        = savedFogEnd
    Lighting.FogStart      = 0
    Lighting.Brightness    = savedBrightness
    -- Эффекты Lighting — включаем всё обратно
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("PostEffect") or fx:IsA("Sky") or fx:IsA("Atmosphere") then
            fx.Enabled = true
        end
    end
    -- Частицы
    for obj, state in pairs(savedParticles) do
        if obj and obj.Parent then obj.Enabled = state end
    end
    savedParticles = {}
    -- Декали
    for obj, trans in pairs(savedDecals) do
        if obj and obj.Parent then obj.Transparency = trans end
    end
    savedDecals = {}
    Notify("FPS Boost", "⛔ OFF")
end

TVisuals:CreateToggle({
    Name = "FPS Boost",
    CurrentValue = false,
    Callback = function(v)
        fpsBoostEnabled = v
        if v then
            savedShadows    = Lighting.GlobalShadows
            savedFogEnd     = Lighting.FogEnd
            savedBrightness = Lighting.Brightness
            enableFPSBoost()
        else
            disableFPSBoost()
        end
    end
})

TVisuals:CreateToggle({
    Name = "Fullscreen Mode",
    CurrentValue = false,
    Callback = function(v)
        pcall(function()
            UserInputService.OverrideMouseIconBehavior =
                v and Enum.OverrideMouseIconBehavior.ForceHide
                  or  Enum.OverrideMouseIconBehavior.None
        end)
        Notify("Fullscreen", v and "ON" or "OFF")
    end
})

TVisuals:CreateSlider({
    Name = "Render Quality (1=min 10=max)",
    Range = {1, 10}, Increment = 1, CurrentValue = 10,
    Callback = function(v)
        pcall(function()
            settings().Rendering.QualityLevel =
                Enum.QualityLevel["Level0" .. (v < 10 and tostring(v) or "10")]
        end)
    end
})

TProtection:CreateSection("Anti Cheat")

TProtection:CreateToggle({
    Name="Anti Cheat Bypass (multi-stage)", CurrentValue=false,
    Callback=function(v)
        AntiCheatEnabled=v
        if v then SetupAntiCheatBypass(); Notify("AC Bypass","Active") end
        if not v then Notify("AC Bypass","OFF") end
    end
})
TProtection:CreateDivider()

TProtection:CreateToggle({
    Name="Anti Kick", CurrentValue=false,
    Callback=function(v)
        if v then
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
        else Notify("Anti Kick","OFF") end
    end
})
TProtection:CreateDivider()

TProtection:CreateToggle({
    Name="Anti Teleport", CurrentValue=false,
    Callback=function(v)
        disconnect("AntiTP")
        if v then
            LastPos=getHRP() and getHRP().Position or Vector3.new(0,0,0)
            Connections.AntiTP=RunService.Heartbeat:Connect(function()
                local hrp=getHRP(); if not hrp then return end
                local dist=(hrp.Position-LastPos).Magnitude
                if dist>150 then hrp.CFrame=CFrame.new(LastPos) else LastPos=hrp.Position end
            end)
            Notify("Anti TP","ON")
        else Notify("Anti TP","OFF") end
    end
})
TProtection:CreateDivider()

TProtection:CreateToggle({
    Name="Anti AFK", CurrentValue=false,
    Callback=function(v)
        disconnect("AntiAFK")
        if v then
            Connections.AntiAFK=RunService.Heartbeat:Connect(function()
                pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
            end)
            Notify("Anti AFK","ON")
        else Notify("Anti AFK","OFF") end
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

TAbout:CreateLabel({ Text="Rix Hub v3.0 Full Merge", Style=1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text="Volleyball Legends", Style=2 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text="Player: "..LP.Name, Style=1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text="Sources Merged:", Style=1 })
TAbout:CreateLabel({ Text="✓ RixHub (base)", Style=2 })
TAbout:CreateLabel({ Text="✓ ZeckHub (ball hitbox, lines, jump esp)", Style=2 })
TAbout:CreateLabel({ Text="✓ Sterling Hub (powers, hitboxes, auto spin)", Style=2 })
TAbout:CreateLabel({ Text="✓ Volleyball 4.2 (setting, serving, spiking)", Style=2 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text="50+ Features | All RemoteEvents", Style=1 })
TAbout:CreateDivider()

TAbout:CreateButton({
    Name="Disable ALL Features",
    Callback=function()
        for key,_ in pairs(Connections) do disconnect(key) end
        for _,bb in pairs(ESPObjects) do SafeDestroy(bb) end; ESPObjects={}
        for _,bb in pairs(BallESPObjects) do SafeDestroy(bb) end; BallESPObjects={}
        for _,line in ipairs(TrajectoryLines) do SafeDestroy(line) end; TrajectoryLines={}
        for p,_ in pairs(lines) do removeLine(p) end
        for p,_ in pairs(espHighlights) do removeJumpESP(p) end
        for part,trans in pairs(OriginalParts) do if part and part.Parent then part.Transparency=trans end end; OriginalParts={}
        disableBallHitbox()
        removeAntennas(); removeServeCorners(); removeSpikeZones()
        SafeDestroy(PlatformPart)
        PlatformPart = nil
        SafeDestroy(bodyVelocity)
        bodyVelocity = nil
        DestroyReachCircle()
        local hum=getHum()
        if hum then hum.WalkSpeed=OriginalWalkSpeed; hum.JumpHeight=OriginalJumpHeight end
        Lighting.Brightness=defaultBrightness; Lighting.Ambient=defaultAmbient
        Lighting.OutdoorAmbient=defaultOutdoorAmbient; Lighting.FogEnd=defaultFogEnd
        bloomEffect.Intensity=0
        if fpsBoostEnabled then disableFPSBoost(); fpsBoostEnabled=false end
        autoFarm=false; autoJoin=false; enablejoin=false; autoSpin=false
        farmFlyDestroy()
        if spinChangedConn then
            spinChangedConn:Disconnect()
            spinChangedConn = nil
        end
        linesEnabled=false; espJumpEnabled=false; powerfulServe=false
        vbSetting=false; vbServing=false; vbSpiking=false; vbPower=false; vbSprint=false
        IsJumping=false; AntiCheatEnabled=false; ProtectedPlayers={}; BlockedRemotes={}
        Notify("All OFF","Every feature disabled")
    end
})

LP.CharacterAdded:Connect(function()
    task.wait(1)
    local hum = getHum()
    if hum then
        hum.WalkSpeed  = OriginalWalkSpeed
        hum.JumpHeight = OriginalJumpHeight
    end
    if LastPos then
        LastPos = getHRP() and getHRP().Position or Vector3.new(0, 0, 0)
    end
    if AntiCheatEnabled then task.delay(2, SetupAntiCheatBypass) end
    if enablejoin then task.spawn(teamSelection) end
end)

Players.PlayerAdded:Connect(function(p)
    setupJumpESP(p)
    if AntiCheatEnabled then ProtectedPlayers[p.Name] = true end
end)

Notify("Rix Hub", "v3.0 Full Merge Loaded!")
print("✅ RixHub v3.0 Full Merge Ready | 50+ Features")
