local lunaUrl = "https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua"
local lunaLoaded, lunaResult = pcall(function()
    return loadstring(game:HttpGet(lunaUrl, true))()
end)
if not lunaLoaded or not lunaResult then
    error("[RixHub] Luna failed to load. Check your executor or internet connection.")
end
local Luna = lunaResult

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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Debris = game:GetService("Debris")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

if not LP then return end

local Connections = {}
local SpeedMult = 1.2
local JumpMult = 1.3
local SpinSpd = 15
local BallHitboxMult = 3
local FlySpd = 40
local PlatHeight = 8
local GravityMult = 0.5
local ReachDistance = 10
local ESPRange = 5000
local BallESPRange = 5000
local lineDistance = 50
local airMovementSpeed = 16
local bloomIntensity = 0

local PlatformPart = nil
local ESPObjects = {}
local BallESPObjects = {}
local TrajectoryLines = {}
local OriginalParts = {}
local OriginalBallSizes = {}
local LastPos = nil
local IsJumping = false
local bodyVelocity = nil
local airBodyVelocity = nil
local ReachCircle = nil
local ReachGui = nil
local AntiCheatEnabled = false
local autoShiftLock = false
local airMovement = false
local linesEnabled = false
local powerfulServe = false
local autoFarm = false
local autoJoin = false
local autoSpin = false
local espJumpEnabled = false
local OriginalGravity = Workspace.Gravity
local OriginalWalkSpeed = 16
local OriginalJumpHeight = 7.2
local BlockedRemotes = {}
local ProtectedPlayers = {}
local CurrentBall = nil
local LastBallCheck = 0
local FrameCounter = 0
local UpdateInterval = 3
local LastESPUpdate = 0
local ESPUpdateInterval = 5
local CachedDescendants = {}
local LastDescendantsUpdate = 0
local lines = {}
local espHighlights = {}
local espConnections = {}
local desiredStyles = {}

local defaultAmbient = Lighting.Ambient
local defaultBrightness = Lighting.Brightness
local defaultOutdoorAmbient = Lighting.OutdoorAmbient
local defaultFogEnd = Lighting.FogEnd

local bloomEffect = Instance.new("BloomEffect", Lighting)
bloomEffect.Intensity = 0
bloomEffect.Size = 56
bloomEffect.Threshold = 1

local function getChar() return LP.Character end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") or nil end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") or nil end

local function disconnect(key)
    if Connections[key] then
        pcall(function() Connections[key]:Disconnect() end)
        Connections[key] = nil
    end
end

local function Notify(title, content)
    pcall(function()
        Luna:Notification({ Title = title, Icon = "info", ImageSource = "Material", Content = content or "" })
    end)
end

local function SafeDestroy(obj)
    pcall(function() if obj and obj.Parent then obj:Destroy() end end)
end

local function CreateGradientFrame(parent, color1, color2)
    pcall(function()
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2) })
        g.Rotation = 45
        g.Parent = parent
    end)
end

local function FindBall()
    local now = tick()
    if now - LastBallCheck < 0.5 and CurrentBall and CurrentBall.Parent then return CurrentBall end
    LastBallCheck = now
    CurrentBall = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("ball") or n:find("volleyball") or n:find("sphere") then
                CurrentBall = obj
                break
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

local function CreateReachCircle()
    pcall(function()
        if ReachGui then SafeDestroy(ReachGui) end
        ReachGui = Instance.new("ScreenGui")
        ReachGui.Name = "RixReachGui"
        ReachGui.ResetOnSpawn = false
        ReachGui.IgnoreGuiInset = true
        ReachGui.Parent = LP.PlayerGui
        ReachCircle = Instance.new("Frame")
        ReachCircle.AnchorPoint = Vector2.new(0.5, 0.5)
        ReachCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
        ReachCircle.Size = UDim2.new(0, ReachDistance * 8, 0, ReachDistance * 8)
        ReachCircle.BackgroundTransparency = 0.85
        ReachCircle.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
        ReachCircle.BorderSizePixel = 0
        ReachCircle.Parent = ReachGui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ReachCircle
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(0, 255, 200)
        stroke.Thickness = 2
        stroke.Parent = ReachCircle
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 1, 5)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(0, 255, 200)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.Text = tostring(ReachDistance) .. " studs"
        label.Parent = ReachCircle
    end)
end

local function UpdateReachCircle()
    pcall(function()
        if ReachCircle then
            ReachCircle.Size = UDim2.new(0, ReachDistance * 8, 0, ReachDistance * 8)
            local label = ReachCircle:FindFirstChild("TextLabel")
            if label then label.Text = tostring(ReachDistance) .. " studs" end
        end
    end)
end

local function DestroyReachCircle()
    SafeDestroy(ReachGui)
    ReachCircle = nil
    ReachGui = nil
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
            local args = {...}
            if method == "FireServer" or method == "InvokeServer" then
                local name = tostring(self):lower()
                if name:find("kick") or name:find("ban") or name:find("ac") or name:find("anti") or
                   name:find("cheat") or name:find("detect") or name:find("hack") or name:find("exploit") or
                   name:find("flag") or name:find("punish") or name:find("security") or name:find("stun") or
                   name:find("ragdoll") or name:find("verify") or name:find("validate") then
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
            hookfunction(LP.Kick, function(self, ...)
                if self == LP then return nil end
            end)
        end
    end)
end

local function removeLine(player)
    local data = lines[player]
    if data then
        if data.beam then data.beam:Destroy() end
        if data.target and data.target.Parent then data.target:Destroy() end
        if data.attachment and data.attachment.Parent then data.attachment:Destroy() end
        lines[player] = nil
    end
end

local function updateLine(player, index)
    local lineColors = {
        Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255),
        Color3.fromRGB(255,165,0), Color3.fromRGB(128,0,128), Color3.fromRGB(255,255,0)
    }
    if not linesEnabled then removeLine(player) return end
    local char = player.Character
    if not char or not char:FindFirstChild("Head") or not char:FindFirstChild("HumanoidRootPart") then
        removeLine(player) return
    end
    local head = char.Head
    local rootPart = char.HumanoidRootPart
    if not lines[player] then
        local attachment = Instance.new("Attachment", head)
        local target = Instance.new("Part")
        target.Anchored = true; target.CanCollide = false; target.Transparency = 1
        target.Size = Vector3.new(0.1,0.1,0.1); target.Parent = Workspace
        local targetAttachment = Instance.new("Attachment", target)
        local beam = Instance.new("Beam")
        beam.Attachment0 = attachment; beam.Attachment1 = targetAttachment
        beam.Width0 = 0.25; beam.Width1 = 0.25; beam.FaceCamera = true
        beam.LightEmission = 1; beam.Transparency = NumberSequence.new(0.3)
        beam.Color = ColorSequence.new(lineColors[((index-1) % #lineColors) + 1])
        beam.Parent = head
        lines[player] = { beam=beam, target=target, attachment=attachment }
    end
    lines[player].target.Position = head.Position + rootPart.CFrame.LookVector * lineDistance
end

local function applyJumpESP(player)
    if not player.Character or espHighlights[player] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "JumpESP"
    hl.Adornee = player.Character
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0
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
                if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
                    applyJumpESP(player)
                elseif newState == Enum.HumanoidStateType.Landed then
                    removeJumpESP(player)
                end
            else
                removeJumpESP(player)
            end
        end)
        espConnections[player] = { c1 }
    end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

local function pressSpace()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

local function pressClick()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

local function getHitbox(name)
    return pcall(function()
        return ReplicatedStorage.Assets.Hitboxes:FindFirstChild(name)
    end)
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

local function setupCharacterAir(character)
    local hum = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
    airMovementSpeed = hum.WalkSpeed

    hum:GetPropertyChangedSignal("Jump"):Connect(function()
        if hum.Jump and autoShiftLock then
            task.defer(function()
                task.wait(0.03)
                local cam = Workspace:FindFirstChildOfClass("Camera") or Workspace.CurrentCamera
                local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
                if look.Magnitude > 0 then
                    hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + look.Unit)
                    hum.AutoRotate = false
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
                local sameTeam = LP.Team and player.Team and player.Team == LP.Team
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

local TMovement   = Window:CreateTab({ Name = "Movement",   Icon = "directions_run", ImageSource = "Material", ShowTitle = true })
local TAutoFarm   = Window:CreateTab({ Name = "Auto Farm",  Icon = "agriculture",    ImageSource = "Material", ShowTitle = true })
local TAutoSpin   = Window:CreateTab({ Name = "Auto Spin",  Icon = "sync",           ImageSource = "Material", ShowTitle = true })
local TPower      = Window:CreateTab({ Name = "Powers",     Icon = "bolt",           ImageSource = "Material", ShowTitle = true })
local THitboxes   = Window:CreateTab({ Name = "Hitboxes",   Icon = "open_with",      ImageSource = "Material", ShowTitle = true })
local TVisuals    = Window:CreateTab({ Name = "Visuals",    Icon = "visibility",     ImageSource = "Material", ShowTitle = true })
local TProtection = Window:CreateTab({ Name = "Protection", Icon = "security",       ImageSource = "Material", ShowTitle = true })
local TAbout      = Window:CreateTab({ Name = "About",      Icon = "info",           ImageSource = "Material", ShowTitle = true })

TMovement:CreateSection("Speed & Jump")
TMovement:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Callback = function(v)
        disconnect("Speed")
        if v then
            Connections.Speed = RunService.Heartbeat:Connect(function()
                local hum = getHum()
                if hum then hum.WalkSpeed = 16 * SpeedMult end
            end)
            Notify("Speed Boost", "x" .. string.format("%.1f", SpeedMult))
        else
            local hum = getHum()
            if hum then hum.WalkSpeed = OriginalWalkSpeed end
            Notify("Speed Boost", "Off")
        end
    end
})
TMovement:CreateSlider({ Name = "Speed Multiplier", Range = {1, 3}, Increment = 0.1, CurrentValue = 1.2, Callback = function(v) SpeedMult = v end })
TMovement:CreateDivider()
TMovement:CreateToggle({
    Name = "Jump Boost",
    CurrentValue = false,
    Callback = function(v)
        disconnect("Jump")
        if v then
            Connections.Jump = RunService.Heartbeat:Connect(function()
                local hum = getHum()
                if hum then hum.JumpHeight = OriginalJumpHeight * JumpMult end
            end)
            Notify("Jump Boost", "x" .. string.format("%.1f", JumpMult))
        else
            local hum = getHum()
            if hum then hum.JumpHeight = OriginalJumpHeight end
            Notify("Jump Boost", "Off")
        end
    end
})
TMovement:CreateSlider({ Name = "Jump Multiplier", Range = {1, 3}, Increment = 0.1, CurrentValue = 1.3, Callback = function(v) JumpMult = v end })
TMovement:CreateDivider()
TMovement:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        disconnect("InfiniteJump")
        disconnect("InfiniteJumpEnded")
        IsJumping = false
        if v then
            Connections.InfiniteJump = UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.KeyCode == Enum.KeyCode.Space and not IsJumping then
                    IsJumping = true
                    local hrp = getHRP()
                    local hum = getHum()
                    if hrp and hum then
                        if hum.FloorMaterial == Enum.Material.Air then
                            local bv = Instance.new("BodyVelocity")
                            bv.MaxForce = Vector3.new(0, math.huge, 0)
                            bv.Velocity = Vector3.new(0, 30, 0)
                            bv.Parent = hrp
                            Debris:AddItem(bv, 0.1)
                        end
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
            Connections.InfiniteJumpEnded = UserInputService.InputEnded:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Space then IsJumping = false end
            end)
            Notify("Infinite Jump", "On")
        else
            IsJumping = false
            Notify("Infinite Jump", "Off")
        end
    end
})
TMovement:CreateDivider()
TMovement:CreateSection("Character Control")
TMovement:CreateToggle({
    Name = "Auto Shift Lock",
    CurrentValue = false,
    Callback = function(v) autoShiftLock = v Notify("Auto Shift Lock", v and "On" or "Off") end
})
TMovement:CreateToggle({
    Name = "Air Movement",
    CurrentValue = false,
    Callback = function(v)
        airMovement = v
        if not v and airBodyVelocity then
        airBodyVelocity:Destroy()
        airBodyVelocity = nil
    end
        Notify("Air Movement", v and "On" or "Off")
    end
})
TMovement:CreateSlider({ Name = "Air Movement Speed", Range = {0, 100}, Increment = 1, CurrentValue = 16, Callback = function(v) airMovementSpeed = v end })
TMovement:CreateDivider()
TMovement:CreateSection("Mods")
TMovement:CreateToggle({
    Name = "Gravity Mod",
    CurrentValue = false,
    Callback = function(v)
        disconnect("Gravity")
        if v then
            Connections.Gravity = RunService.Heartbeat:Connect(function()
                local hrp = getHRP()
                if hrp then
                    local vel = hrp.Velocity
                    if vel.Y < -5 then hrp.Velocity = Vector3.new(vel.X, vel.Y * GravityMult, vel.Z) end
                end
            end)
            Notify("Gravity Mod", "x" .. GravityMult)
        else
            Notify("Gravity Mod", "Off")
        end
    end
})
TMovement:CreateSlider({ Name = "Gravity Multiplier", Range = {0.1, 1}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) GravityMult = v end })
TMovement:CreateDivider()
TMovement:CreateToggle({
    Name = "Anti Stun",
    CurrentValue = false,
    Callback = function(v)
        disconnect("AntiStun")
        if v then
            Connections.AntiStun = RunService.Heartbeat:Connect(function()
                local hum = getHum()
                if hum then
                    if hum.PlatformStand then hum.PlatformStand = false end
                    local state = hum:GetState()
                    if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll then
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end
            end)
            Notify("Anti Stun", "On")
        else
            Notify("Anti Stun", "Off")
        end
    end
})
TMovement:CreateDivider()
TMovement:CreateToggle({
    Name = "Anti Ragdoll",
    CurrentValue = false,
    Callback = function(v)
        disconnect("AntiRagdoll")
        if v then
            Connections.AntiRagdoll = RunService.Heartbeat:Connect(function()
                local char = getChar()
                if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BallSocketConstraint") or part:IsA("HingeConstraint") then SafeDestroy(part) end
                end
                local hum = getHum()
                if hum then
                    if hum.PlatformStand then hum.PlatformStand = false end
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
            Notify("Anti Ragdoll", "On")
        else
            Notify("Anti Ragdoll", "Off")
        end
    end
})
TMovement:CreateDivider()
TMovement:CreateToggle({
    Name = "Enable Rotate In Air",
    CurrentValue = false,
    Callback = function(v)
        disconnect("RotateAir")
        if v then
            Connections.RotateAir = RunService.Heartbeat:Connect(function()
                local hum = getHum()
                if hum and not hum.AutoRotate then hum.AutoRotate = true end
            end)
            Notify("Rotate In Air", "On")
        else
            Notify("Rotate In Air", "Off")
        end
    end
})
TMovement:CreateDivider()
TMovement:CreateToggle({
    Name = "Spin Mod",
    CurrentValue = false,
    Callback = function(v)
        disconnect("Spin")
        if v then
            Connections.Spin = RunService.Heartbeat:Connect(function()
                local hrp = getHRP()
                if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SpinSpd), 0) end
            end)
            Notify("Spin Mod", "Speed " .. SpinSpd)
        else
            Notify("Spin Mod", "Off")
        end
    end
})
TMovement:CreateSlider({ Name = "Spin Speed", Range = {1, 150}, Increment = 1, CurrentValue = 15, Callback = function(v) SpinSpd = v end })
TMovement:CreateDivider()
TMovement:CreateToggle({
    Name = "Fly Mode",
    CurrentValue = false,
    Callback = function(v)
        disconnect("Fly")
        if v then
            local hrp = getHRP()
            if hrp then
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Parent = hrp
                bodyVelocity.MaxForce = Vector3.new(999999, 999999, 999999)
                bodyVelocity.Velocity = Vector3.new(0,0,0)
            end
            Connections.Fly = RunService.Heartbeat:Connect(function()
                local hrp = getHRP()
                if not hrp or not bodyVelocity then return end
                local move = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + hrp.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - hrp.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - hrp.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + hrp.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
                bodyVelocity.Velocity = move.Magnitude > 0 and move.Unit * FlySpd or Vector3.new(0,0,0)
            end)
            Notify("Fly Mode", "WASD + Space/Ctrl")
        else
            SafeDestroy(bodyVelocity)
            bodyVelocity = nil
            Notify("Fly Mode", "Off")
        end
    end
})
TMovement:CreateSlider({ Name = "Fly Speed", Range = {10, 80}, Increment = 1, CurrentValue = 40, Callback = function(v) FlySpd = v end })
TMovement:CreateDivider()
TMovement:CreateToggle({
    Name = "Smart Platform",
    CurrentValue = false,
    Callback = function(v)
        disconnect("Platform")
        if v then
            if not PlatformPart then
                PlatformPart = Instance.new("Part")
                PlatformPart.Name = "RixPlatform"
                PlatformPart.Size = Vector3.new(8, 1, 8)
                PlatformPart.CanCollide = true
                PlatformPart.Material = Enum.Material.Neon
                PlatformPart.BrickColor = BrickColor.new("Cyan")
                PlatformPart.Anchored = true
                PlatformPart.Transparency = 0.3
                PlatformPart.Parent = Workspace
            end
            Connections.Platform = RunService.Heartbeat:Connect(function()
                local hrp = getHRP()
                if hrp and PlatformPart then
                    PlatformPart.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - PlatHeight, hrp.Position.Z)
                end
            end)
            Notify("Smart Platform", "On")
        else
            SafeDestroy(PlatformPart)
            PlatformPart = nil
            Notify("Smart Platform", "Off")
        end
    end
})
TMovement:CreateSlider({ Name = "Platform Height", Range = {3, 20}, Increment = 1, CurrentValue = 8, Callback = function(v) PlatHeight = v end })

TAutoFarm:CreateSection("Auto Features")
TAutoFarm:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Callback = function(v)
        autoFarm = v
        if v then
            task.spawn(function()
                while autoFarm do
                    task.wait(0.3)
                    pcall(function()
                        local hrp = getHRP()
                        local hum = getHum()
                        if not hrp or not hum then return end
                        local ball = getBallModel()
                        if ball then
                            hum:MoveTo(ball.Position)
                            local dist = (ball.Position - hrp.Position).Magnitude
                            if dist <= 15 then
                                local ok, posFolder = pcall(function()
                                    return Workspace.Map.BallNoCollide.Positions["2"]
                                end)
                                if ok and posFolder then
                                    local parts = {}
                                    for _, p in ipairs(posFolder:GetChildren()) do
                                        if p:IsA("BasePart") then table.insert(parts, p) end
                                    end
                                    if #parts > 0 then
                                        local target = parts[math.random(1, #parts)]
                                        local look = (target.Position - hrp.Position).Unit
                                        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + look)
                                    end
                                end
                                if ball.Position.Y > hrp.Position.Y + 5 then
                                    pressSpace()
                                    pressClick()
                                end
                            end
                        end
                    end)
                end
            end)
            Notify("Auto Farm", "On")
        else
            autoFarm = false
            Notify("Auto Farm", "Off")
        end
    end
})
TAutoFarm:CreateDivider()
TAutoFarm:CreateToggle({
    Name = "Auto Join Match",
    CurrentValue = false,
    Callback = function(v)
        autoJoin = v
        if v then
            task.spawn(function()
                task.wait(10)
                while autoJoin do
                    pcall(function()
                        local gui = LP.PlayerGui.Interface.TeamSelection
                        local gameGui = LP.PlayerGui.Interface.Game
                        if not gameGui.Visible then
                            local randomNum = math.random(1, 6)
                            local btn = gui["2"][tostring(randomNum)]
                            if btn and btn:IsA("ImageButton") then
                                local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
                                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                            end
                        end
                    end)
                    task.wait(math.random(5,15)/10)
                end
            end)
            Notify("Auto Join Match", "On")
        else
            Notify("Auto Join Match", "Off")
        end
    end
})
TAutoFarm:CreateDivider()
TAutoFarm:CreateSection("Match Controls")
TAutoFarm:CreateToggle({
    Name = "Powerful Serve (Z key)",
    CurrentValue = false,
    Callback = function(v)
        powerfulServe = v
        Notify("Powerful Serve", v and "Press Z" or "Off")
    end
})
TAutoFarm:CreateButton({
    Name = "Break The Match",
    Callback = function()
        pcall(function()
            ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.GameService.RF.Serve:InvokeServer(nil, 0.95)
        end)
        Notify("Break Match", "Sent")
    end
})
TAutoFarm:CreateDivider()
TAutoFarm:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
    end
})

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Z and powerfulServe then
        pcall(function()
            local hrp = getHRP()
            if not hrp then return end
            local direction = hrp.CFrame.LookVector
            local distance = 50
            local targetPos = hrp.Position + direction * distance
            ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.GameService.RF.Serve:InvokeServer(
                CFrame.new(targetPos), 0.95
            )
        end)
    end
end)

TAutoSpin:CreateSection("Style Spinner")
TAutoSpin:CreateDropdown({
    Name = "Desired Styles",
    Options = {"Oikawa","Bokuto","Kageyama","Sawamura","Ushijima","Kozume","Kuroo","Yamamoto","Azumane","Yaku","Hinata"},
    CurrentOption = {"Hinata"},
    MultipleOptions = true,
    Callback = function(option) desiredStyles = option end
})
TAutoSpin:CreateToggle({
    Name = "Auto Spin",
    CurrentValue = false,
    Callback = function(v)
        autoSpin = v
        if v then
            coroutine.wrap(function()
                while autoSpin do
                    pcall(function()
                        local current = LP.PlayerGui.Interface.Lobby.Styles.TopPanel.DisplayName.Text
                        if table.find(desiredStyles, current) then
                            autoSpin = false
                            Luna:Notification({
                                Title = "Style Obtained!",
                                Icon = "check_circle",
                                ImageSource = "Material",
                                Content = "Got: " .. current
                            })
                        else
                            ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.StylesService.RF.Roll:InvokeServer(false)
                        end
                    end)
                    task.wait(0.5)
                end
            end)()
            Notify("Auto Spin", "Running...")
        else
            Notify("Auto Spin", "Stopped")
        end
    end
})

TPower:CreateSection("Skills Power (SetAttribute)")
local powerSliders = {
    { name = "Spike Power",  attr = "GameSpikePowerMultiplier" },
    { name = "Block Power",  attr = "GameBlockPowerMultiplier" },
    { name = "Bump Power",   attr = "GameBumpPowerMultiplier"  },
    { name = "Serve Power",  attr = "GameServePowerMultiplier" },
    { name = "Dive Speed",   attr = "GameDiveSpeedMultiplier"  },
    { name = "Jump Power",   attr = "GameJumpPowerMultiplier"  },
    { name = "Speed",        attr = "GameSpeedMultiplier"      },
}
for _, ps in ipairs(powerSliders) do
    local pName = ps.name
    local pAttr = ps.attr
    TPower:CreateSlider({
        Name = pName,
        Range = {0, 500},
        Increment = 0.1,
        CurrentValue = 1,
        Callback = function(v)
            pcall(function() LP:SetAttribute(pAttr, v) end)
        end
    })
    TPower:CreateDivider()
end

THitboxes:CreateSection("Hitbox Extender (ReplicatedStorage)")
local hitboxSliders = {
    { name = "Spike Hitbox",    path = "Spike"   },
    { name = "Block Hitbox",    path = "Block"   },
    { name = "Bump Hitbox",     path = "Bump"    },
    { name = "Serve Hitbox",    path = "Serve"   },
    { name = "Dive Hitbox",     path = "Dive"    },
    { name = "Set Hitbox",      path = "Set"     },
    { name = "JumpSet Hitbox",  path = "JumpSet" },
}
for _, hs in ipairs(hitboxSliders) do
    local hName = hs.name
    local hPath = hs.path
    THitboxes:CreateSlider({
        Name = hName,
        Range = {1, 100},
        Increment = 0.1,
        CurrentValue = 10,
        Callback = function(v)
            setHitboxSize(hPath, v)
        end
    })
    THitboxes:CreateDivider()
end
THitboxes:CreateSection("Ball Hitbox (CLIENT_BALL Model)")
THitboxes:CreateToggle({
    Name = "Ball Model Hitbox",
    CurrentValue = false,
    Callback = function(v)
        disconnect("BallHitbox")
        if v then
            local function applyBallHitbox(model)
                if not model:IsA("Model") or not model.Name:match("^CLIENT_BALL_%d+$") then return end
                local ball = model:FindFirstChild("Ball.001")
                if not ball then
                    local base = nil
                    for _, d in ipairs(model:GetDescendants()) do
                        if d:IsA("BasePart") then base = d break end
                    end
                    if base then
                        ball = Instance.new("Part")
                        ball.Name = "Ball.001"
                        ball.Shape = Enum.PartType.Ball
                        ball.Size = Vector3.new(2,2,2) * BallHitboxMult
                        ball.CFrame = base.CFrame
                        ball.Anchored = true
                        ball.CanCollide = false
                        ball.Transparency = 0.7
                        ball.Material = Enum.Material.ForceField
                        ball.Color = Color3.fromRGB(0, 255, 0)
                        ball.Parent = model
                    end
                else
                    ball.Size = Vector3.new(2,2,2) * BallHitboxMult
                end
            end
            for _, child in ipairs(Workspace:GetChildren()) do applyBallHitbox(child) end
            Workspace.ChildAdded:Connect(function(child) task.wait(0.1) applyBallHitbox(child) end)
            Notify("Ball Model Hitbox", "x" .. BallHitboxMult)
        else
            for _, model in ipairs(Workspace:GetChildren()) do
                if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
                    local ball = model:FindFirstChild("Ball.001")
                    if ball then ball:Destroy() end
                end
            end
            Notify("Ball Model Hitbox", "Off")
        end
    end
})
THitboxes:CreateSlider({ Name = "Ball Model Size", Range = {0, 20}, Increment = 0.5, CurrentValue = 5, Callback = function(v) BallHitboxMult = v end })
THitboxes:CreateDivider()
THitboxes:CreateSection("Ball Part Hitbox")
THitboxes:CreateToggle({
    Name = "Ball Part Hitbox",
    CurrentValue = false,
    Callback = function(v)
        disconnect("BallHitbox2")
        OriginalBallSizes = {}
        if v then
            Connections.BallHitbox2 = RunService.Heartbeat:Connect(function()
                local ball = FindBall()
                if ball then
                    if not OriginalBallSizes[ball] then
                        OriginalBallSizes[ball] = ball.Size
                        ball.Size = ball.Size * BallHitboxMult
                        ball.Transparency = 0.3
                        ball.Material = Enum.Material.Neon
                        ball.Color = Color3.fromRGB(255, 0, 100)
                    end
                end
            end)
            Notify("Ball Part Hitbox", "x" .. BallHitboxMult)
        else
            for ball, size in pairs(OriginalBallSizes) do
                if ball and ball.Parent then
                    ball.Size = size
                    ball.Transparency = 0
                    ball.Material = Enum.Material.Plastic
                    ball.Color = Color3.fromRGB(255,255,255)
                end
            end
            OriginalBallSizes = {}
            Notify("Ball Part Hitbox", "Off")
        end
    end
})
THitboxes:CreateSlider({ Name = "Ball Part Size", Range = {1, 10}, Increment = 0.5, CurrentValue = 3, Callback = function(v) BallHitboxMult = v end })

TVisuals:CreateSection("Player ESP")
TVisuals:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(v)
        for _, bb in pairs(ESPObjects) do SafeDestroy(bb) end
        ESPObjects = {}
        disconnect("ESPUpdate")
        if v then
            local function createESP(player)
                if player == LP or not player.Character then return end
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = getHRP()
                if not hrp or not myHRP then return end
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(8, 0, 4, 0)
                bb.MaxDistance = ESPRange
                bb.Adornee = hrp
                bb.AlwaysOnTop = true
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1,0,1,0)
                frame.BackgroundTransparency = 0.1
                frame.BorderSizePixel = 0
                frame.Parent = bb
                CreateGradientFrame(frame, Color3.fromRGB(0,255,200), Color3.fromRGB(0,100,255))
                local label = Instance.new("TextLabel")
                label.Parent = frame
                label.Size = UDim2.new(1,0,0.5,0)
                label.BackgroundTransparency = 1
                label.TextColor3 = Color3.fromRGB(255,255,255)
                label.Font = Enum.Font.GothamBold
                label.TextSize = 16
                label.Text = player.Name
                label.TextStrokeTransparency = 0
                local distLabel = Instance.new("TextLabel")
                distLabel.Parent = frame
                distLabel.Size = UDim2.new(1,0,0.5,0)
                distLabel.Position = UDim2.new(0,0,0.5,0)
                distLabel.BackgroundTransparency = 1
                distLabel.TextColor3 = Color3.fromRGB(200,255,255)
                distLabel.Font = Enum.Font.GothamBold
                distLabel.TextSize = 14
                distLabel.Text = math.floor((hrp.Position - myHRP.Position).Magnitude) .. "m"
                distLabel.TextStrokeTransparency = 0
                local corner = Instance.new("UICorner")
                corner.Parent = frame
                corner.CornerRadius = UDim.new(0, 8)
                bb.Parent = Workspace
                ESPObjects[player] = bb
            end
            for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
            Connections.ESPUpdate = RunService.Heartbeat:Connect(function()
                FrameCounter = FrameCounter + 1
                if FrameCounter % UpdateInterval ~= 0 then return end
                local now = tick()
                if now - LastESPUpdate < ESPUpdateInterval then return end
                LastESPUpdate = now
                local myHRP = getHRP()
                if not myHRP then return end
                for player, bb in pairs(ESPObjects) do
                    if player.Character and bb then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local frame = bb:FindFirstChild("Frame")
                            if frame then
                                local labels = frame:GetChildren()
                                for _, lbl in ipairs(labels) do
                                    if lbl:IsA("TextLabel") and lbl.Text:find("m") then
                                        lbl.Text = math.floor((hrp.Position - myHRP.Position).Magnitude) .. "m"
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            Notify("Player ESP", "On")
        else
            Notify("Player ESP", "Off")
        end
    end
})
TVisuals:CreateSlider({ Name = "ESP Range", Range = {100, 10000}, Increment = 100, CurrentValue = 5000, Callback = function(v) ESPRange = v end })
TVisuals:CreateDivider()
TVisuals:CreateToggle({
    Name = "ESP Jump Highlight",
    CurrentValue = false,
    Callback = function(v)
        espJumpEnabled = v
        if not v then
            for p, _ in pairs(espHighlights) do removeJumpESP(p) end
        end
        Notify("ESP Jump", v and "On (Yellow)" or "Off")
    end
})
TVisuals:CreateDivider()
TVisuals:CreateToggle({
    Name = "Enemy Lines",
    CurrentValue = false,
    Callback = function(v)
        linesEnabled = v
        if not v then
            for p, _ in pairs(lines) do removeLine(p) end
        end
        Notify("Enemy Lines", v and "On" or "Off")
    end
})
TVisuals:CreateSlider({ Name = "Line Distance", Range = {0, 100}, Increment = 10, CurrentValue = 50, Callback = function(v) lineDistance = v end })
TVisuals:CreateDivider()
TVisuals:CreateToggle({
    Name = "Ball ESP",
    CurrentValue = false,
    Callback = function(v)
        for _, bb in pairs(BallESPObjects) do SafeDestroy(bb) end
        BallESPObjects = {}
        disconnect("BallESPUpdate")
        if v then
            local function createBallESP(ball)
                if not ball or not ball:IsA("BasePart") then return end
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(10, 0, 5, 0)
                bb.MaxDistance = BallESPRange
                bb.Adornee = ball
                bb.AlwaysOnTop = true
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1,0,1,0)
                frame.BackgroundTransparency = 0.05
                frame.BorderSizePixel = 0
                frame.Parent = bb
                CreateGradientFrame(frame, Color3.fromRGB(255,50,50), Color3.fromRGB(255,150,0))
                local label = Instance.new("TextLabel")
                label.Parent = frame
                label.Size = UDim2.new(1,0,0.5,0)
                label.BackgroundTransparency = 1
                label.TextColor3 = Color3.fromRGB(255,255,255)
                label.Font = Enum.Font.GothamBold
                label.TextSize = 18
                label.Text = "🏐 BALL"
                label.TextStrokeTransparency = 0
                local velLabel = Instance.new("TextLabel")
                velLabel.Parent = frame
                velLabel.Size = UDim2.new(1,0,0.5,0)
                velLabel.Position = UDim2.new(0,0,0.5,0)
                velLabel.BackgroundTransparency = 1
                velLabel.TextColor3 = Color3.fromRGB(255,255,200)
                velLabel.Font = Enum.Font.GothamBold
                velLabel.TextSize = 14
                velLabel.Text = "Speed: " .. math.floor(ball.Velocity.Magnitude)
                velLabel.TextStrokeTransparency = 0
                local corner = Instance.new("UICorner")
                corner.Parent = frame
                corner.CornerRadius = UDim.new(0, 10)
                bb.Parent = Workspace
                BallESPObjects[ball] = bb
            end
            local ball = FindBall()
            if ball then createBallESP(ball) end
            Connections.BallESPUpdate = RunService.Heartbeat:Connect(function()
                FrameCounter = FrameCounter + 1
                if FrameCounter % UpdateInterval ~= 0 then return end
                local ball = FindBall()
                if ball and not BallESPObjects[ball] then createBallESP(ball) end
            end)
            Notify("Ball ESP", "On")
        else
            Notify("Ball ESP", "Off")
        end
    end
})
TVisuals:CreateSlider({ Name = "Ball ESP Range", Range = {100, 10000}, Increment = 100, CurrentValue = 5000, Callback = function(v) BallESPRange = v end })
TVisuals:CreateDivider()
TVisuals:CreateToggle({
    Name = "Ball Trajectory",
    CurrentValue = false,
    Callback = function(v)
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
                    table.insert(points, startPos + velocity * t + Vector3.new(0, -0.5 * gravity * t * t, 0))
                end
                for i = 1, #points - 1 do
                    local line = Instance.new("Part")
                    line.Anchored = true; line.CanCollide = false
                    line.Size = Vector3.new(0.3, 0.3, (points[i] - points[i+1]).Magnitude)
                    line.CFrame = CFrame.lookAt(points[i], points[i+1]) * CFrame.new(0, 0, -line.Size.Z / 2)
                    line.Color = Color3.fromRGB(255, 100, 100)
                    line.Material = Enum.Material.Neon
                    line.Transparency = 0.3
                    line.Parent = Workspace
                    table.insert(TrajectoryLines, line)
                end
            end)
            Notify("Ball Trajectory", "On")
        else
            for _, line in ipairs(TrajectoryLines) do SafeDestroy(line) end
            TrajectoryLines = {}
            Notify("Ball Trajectory", "Off")
        end
    end
})
TVisuals:CreateDivider()
TVisuals:CreateToggle({
    Name = "Reach Circle",
    CurrentValue = false,
    Callback = function(v)
        if v then CreateReachCircle() Notify("Reach Circle", ReachDistance .. " studs")
        else DestroyReachCircle() Notify("Reach Circle", "Off") end
    end
})
TVisuals:CreateSlider({ Name = "Reach Distance", Range = {5, 50}, Increment = 1, CurrentValue = 10, Callback = function(v) ReachDistance = v UpdateReachCircle() end })
TVisuals:CreateDivider()
TVisuals:CreateSection("Lighting")
TVisuals:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(v)
        if v then
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.new(1,1,1)
            Lighting.OutdoorAmbient = Color3.new(1,1,1)
            Notify("Fullbright", "On")
        else
            Lighting.Brightness = defaultBrightness
            Lighting.Ambient = defaultAmbient
            Lighting.OutdoorAmbient = defaultOutdoorAmbient
            Notify("Fullbright", "Off")
        end
    end
})
TVisuals:CreateToggle({
    Name = "Night Mode",
    CurrentValue = false,
    Callback = function(v)
        if v then
            Lighting.Ambient = Color3.fromRGB(20,20,20)
            Lighting.Brightness = 1
            Notify("Night Mode", "On")
        else
            Lighting.Ambient = defaultAmbient
            Lighting.Brightness = defaultBrightness
            Notify("Night Mode", "Off")
        end
    end
})
TVisuals:CreateToggle({
    Name = "Xray Vision",
    CurrentValue = false,
    Callback = function(v)
        if v then
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and not part:IsDescendantOf(LP.Character) and part.Name ~= "RixPlatform" then
                    OriginalParts[part] = part.Transparency
                    part.Transparency = 0.7
                end
            end
            Notify("Xray", "On")
        else
            for part, trans in pairs(OriginalParts) do
                if part and part.Parent then part.Transparency = trans end
            end
            OriginalParts = {}
            Notify("Xray", "Off")
        end
    end
})
TVisuals:CreateSlider({ Name = "Fog End Distance", Range = {0, 10000}, Increment = 50, CurrentValue = defaultFogEnd, Callback = function(v) Lighting.FogEnd = v end })
TVisuals:CreateSlider({ Name = "Bloom Intensity", Range = {0, 5}, Increment = 0.1, CurrentValue = 0, Callback = function(v) bloomEffect.Intensity = v end })
TVisuals:CreateButton({
    Name = "Reset Lighting",
    Callback = function()
        Lighting.Brightness = defaultBrightness
        Lighting.Ambient = defaultAmbient
        Lighting.OutdoorAmbient = defaultOutdoorAmbient
        Lighting.FogEnd = defaultFogEnd
        bloomEffect.Intensity = 0
        Notify("Lighting", "Reset")
    end
})

TProtection:CreateSection("Anti Cheat")
TProtection:CreateToggle({
    Name = "Anti Cheat Bypass",
    CurrentValue = false,
    Callback = function(v)
        AntiCheatEnabled = v
        if v then
            SetupAntiCheatBypass()
            Notify("AC Bypass", "Multi-Stage Active")
        else
            Notify("AC Bypass", "Off")
        end
    end
})
TProtection:CreateDivider()
TProtection:CreateToggle({
    Name = "Anti Kick",
    CurrentValue = false,
    Callback = function(v)
        if v then
            pcall(function()
                local mt = getrawmetatable(game)
                local old = mt.__namecall
                setreadonly(mt, false)
                mt.__namecall = newcclosure(function(self, ...)
                    if getnamecallmethod() == "Kick" and self == LP then
                        Notify("Anti Kick", "Blocked")
                        return nil
                    end
                    return old(self, ...)
                end)
                setreadonly(mt, true)
            end)
            Notify("Anti Kick", "On")
        else
            Notify("Anti Kick", "Off")
        end
    end
})
TProtection:CreateDivider()
TProtection:CreateToggle({
    Name = "Anti Teleport",
    CurrentValue = false,
    Callback = function(v)
        disconnect("AntiTP")
        if v then
            LastPos = getHRP() and getHRP().Position or Vector3.new(0,0,0)
            Connections.AntiTP = RunService.Heartbeat:Connect(function()
                local hrp = getHRP()
                if not hrp then return end
                local dist = (hrp.Position - LastPos).Magnitude
                if dist > 150 then hrp.CFrame = CFrame.new(LastPos)
                else LastPos = hrp.Position end
            end)
            Notify("Anti TP", "On")
        else
            Notify("Anti TP", "Off")
        end
    end
})
TProtection:CreateDivider()
TProtection:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Callback = function(v)
        disconnect("AntiAFK")
        if v then
            Connections.AntiAFK = RunService.Heartbeat:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end)
            Notify("Anti AFK", "On")
        else
            Notify("Anti AFK", "Off")
        end
    end
})
TProtection:CreateDivider()
TProtection:CreateButton({
    Name = "Protect All Players",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then ProtectedPlayers[p.Name] = true end
        end
        Notify("Player Protect", "All players protected")
    end
})

TAbout:CreateLabel({ Text = "Rix Hub", Style = 1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "Volleyball Legends", Style = 2 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "Version: 2.0 Full Merge", Style = 1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "Player: " .. LP.Name, Style = 1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "Merged: RixHub + ZeckHub + Sterling", Style = 1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "60+ Features", Style = 1 })
TAbout:CreateDivider()
TAbout:CreateButton({
    Name = "Disable All",
    Callback = function()
        for key, _ in pairs(Connections) do disconnect(key) end
        for _, bb in pairs(ESPObjects) do SafeDestroy(bb) end
        ESPObjects = {}
        for _, bb in pairs(BallESPObjects) do SafeDestroy(bb) end
        BallESPObjects = {}
        for _, line in ipairs(TrajectoryLines) do SafeDestroy(line) end
        TrajectoryLines = {}
        for p, _ in pairs(lines) do removeLine(p) end
        for p, _ in pairs(espHighlights) do removeJumpESP(p) end
        for part, trans in pairs(OriginalParts) do
            if part and part.Parent then part.Transparency = trans end
        end
        OriginalParts = {}
        for ball, size in pairs(OriginalBallSizes) do
            if ball and ball.Parent then
                ball.Size = size
                ball.Transparency = 0
                ball.Material = Enum.Material.Plastic
                ball.Color = Color3.fromRGB(255,255,255)
            end
        end
        OriginalBallSizes = {}
        SafeDestroy(PlatformPart)
        PlatformPart = nil
        SafeDestroy(bodyVelocity)
        bodyVelocity = nil
        DestroyReachCircle()
        local hum = getHum()
        if hum then
            hum.WalkSpeed = OriginalWalkSpeed
            hum.JumpHeight = OriginalJumpHeight
        end
        Lighting.Brightness = defaultBrightness
        Lighting.Ambient = defaultAmbient
        Lighting.OutdoorAmbient = defaultOutdoorAmbient
        Lighting.FogEnd = defaultFogEnd
        bloomEffect.Intensity = 0
        autoFarm = false
        autoJoin = false
        autoSpin = false
        linesEnabled = false
        espJumpEnabled = false
        powerfulServe = false
        IsJumping = false
        AntiCheatEnabled = false
        ProtectedPlayers = {}
        BlockedRemotes = {}
        Notify("All Off", "Disabled")
    end
})

LP.CharacterAdded:Connect(function()
    task.wait(1)
    local hum = getHum()
    if hum then
        hum.WalkSpeed = OriginalWalkSpeed
        hum.JumpHeight = OriginalJumpHeight
    end
    if LastPos then LastPos = getHRP() and getHRP().Position or Vector3.new(0,0,0) end
    if AntiCheatEnabled then task.delay(2, SetupAntiCheatBypass) end
end)

Notify("Rix Hub", "v2.0 Full Merge Loaded!")
print("✅ RixHub v2.0 - Full Merge (RixHub + ZeckHub + Sterling) - Ready!")
