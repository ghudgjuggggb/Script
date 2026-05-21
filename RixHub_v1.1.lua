local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua", true))()

local Window = Luna:CreateWindow({
    Name = "Rix Hub",
    Subtitle = "Steal a Brainrot",
    LogoID = "130188918639066",
    LoadingEnabled = true,
    LoadingTitle = "Rix Hub",
    LoadingSubtitle = "Loading...",
    ConfigSettings = {
        RootFolder = nil,
        ConfigFolder = "RixHub"
    },
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
local Debris = game:GetService("Debris")

if not LP then return end

local Connections = {}
local SpeedMult = 1.2
local JumpMult = 1.3
local SpinSpd = 15
local HitboxMult = 1.5
local FlySpd = 40
local PlatHeight = 8
local GravityMult = 0.5
local ReachDistance = 10
local PlatformPart = nil
local ESPObjects = {}
local OriginalParts = {}
local OriginalSizes = {}
local LastPos = nil
local IsJumping = false
local bodyVelocity = nil
local ReachCircle = nil
local ReachGui = nil
local AntiCheatEnabled = false
local OriginalGravity = Workspace.Gravity
local OriginalWalkSpeed = 16
local OriginalJumpHeight = 7.2
local BlockedRemotes = {}

local function getChar()
    return LP.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart") or nil
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid") or nil
end

local function disconnect(key)
    if Connections[key] then
        pcall(function()
            Connections[key]:Disconnect()
        end)
        Connections[key] = nil
    end
end

local function Notify(title, content)
    pcall(function()
        Luna:Notification({
            Title = title,
            Icon = "info",
            ImageSource = "Material",
            Content = content or ""
        })
    end)
end

local function SafeDestroy(obj)
    pcall(function()
        if obj and obj.Parent then
            obj:Destroy()
        end
    end)
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
        ReachCircle.Name = "ReachCircle"
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
        label.Name = "DistanceLabel"
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
            local label = ReachCircle:FindFirstChild("DistanceLabel")
            if label then
                label.Text = tostring(ReachDistance) .. " studs"
            end
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
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if method == "FireServer" or method == "InvokeServer" then
                local remoteName = tostring(self)
                local lowerName = remoteName:lower()
                if lowerName:find("kick") or lowerName:find("ban") or lowerName:find("report") or lowerName:find("ac") or lowerName:find("anti") or lowerName:find("cheat") or lowerName:find("detect") or lowerName:find("bac") or lowerName:find("hack") or lowerName:find("exploit") or lowerName:find("flag") or lowerName:find("log") or lowerName:find("punish") or lowerName:find("moderate") or lowerName:find("security") then
                    if not BlockedRemotes[remoteName] then
                        BlockedRemotes[remoteName] = true
                        Notify("AC Bypass", "Blocked: " .. remoteName)
                    end
                    return nil
                end
                if #args > 0 then
                    for i = 1, #args do
                        local argStr = tostring(args[i]):lower()
                        if argStr:find("cheat") or argStr:find("hack") or argStr:find("exploit") or argStr:find("bac") or argStr:find("speed") or argStr:find("fly") or argStr:find("teleport") or argStr:find("noclip") then
                            return nil
                        end
                    end
                end
            end
            if method == "Kick" and (self == LP or self == LP.Character) then
                Notify("AC Bypass", "Kick blocked")
                return nil
            end
            if method == "Destroy" and self == LP then
                Notify("AC Bypass", "Destroy blocked")
                return nil
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
    pcall(function()
        if hookfunction then
            local oldKick = hookfunction(LP.Kick, function(self, ...)
                if self == LP then
                    Notify("AC Bypass", "Kick function blocked")
                    return nil
                end
                return oldKick(self, ...)
            end)
        end
    end)
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local name = obj.Name:lower()
                if name:find("kick") or name:find("ban") or name:find("report") or name:find("ac") or name:find("anti") or name:find("cheat") or name:find("detect") or name:find("bac") or name:find("hack") or name:find("exploit") or name:find("flag") or name:find("log") or name:find("punish") or name:find("moderate") or name:find("security") then
                    pcall(function()
                        obj.OnClientEvent:Connect(function(...)
                            Notify("AC Bypass", "Event blocked: " .. obj.Name)
                            return nil
                        end)
                    end)
                end
            end
        end
    end)
    pcall(function()
        LP.CharacterRemoving:Connect(function()
            if AntiCheatEnabled then
                task.wait(0.5)
                SetupAntiCheatBypass()
            end
        end)
    end)
end

local TMovement = Window:CreateTab({ Name = "Movement", Icon = "directions_run", ImageSource = "Material", ShowTitle = true })
local TFeatures = Window:CreateTab({ Name = "Features", Icon = "star", ImageSource = "Material", ShowTitle = true })
local TVisuals = Window:CreateTab({ Name = "Visuals", Icon = "visibility", ImageSource = "Material", ShowTitle = true })
local TProtection = Window:CreateTab({ Name = "Protection", Icon = "security", ImageSource = "Material", ShowTitle = true })
local TAbout = Window:CreateTab({ Name = "About", Icon = "info", ImageSource = "Material", ShowTitle = true })

TMovement:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Callback = function(v)
        disconnect("Speed")
        if v then
            Connections.Speed = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hum = getHum()
                    if hum then
                        local target = 16 * SpeedMult
                        if math.abs(hum.WalkSpeed - target) > 0.1 then
                            hum.WalkSpeed = target
                        end
                    end
                end)
            end)
            Notify("Speed Boost", "x" .. string.format("%.1f", SpeedMult))
        else
            local hum = getHum()
            if hum then
                hum.WalkSpeed = OriginalWalkSpeed
            end
            Notify("Speed", "Off")
        end
    end
})

TMovement:CreateSlider({
    Name = "Speed Multiplier",
    Range = {1, 2.5},
    Increment = 0.1,
    CurrentValue = 1.2,
    Callback = function(value)
        SpeedMult = tonumber(value) or 1.2
    end
})

TMovement:CreateDivider()

TMovement:CreateToggle({
    Name = "Jump Boost",
    CurrentValue = false,
    Callback = function(v)
        disconnect("Jump")
        if v then
            Connections.Jump = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hum = getHum()
                    if hum then
                        local target = OriginalJumpHeight * JumpMult
                        if math.abs(hum.JumpHeight - target) > 0.1 then
                            hum.JumpHeight = target
                        end
                    end
                end)
            end)
            Notify("Jump Boost", "x" .. string.format("%.1f", JumpMult))
        else
            local hum = getHum()
            if hum then
                hum.JumpHeight = OriginalJumpHeight
            end
            Notify("Jump", "Off")
        end
    end
})

TMovement:CreateSlider({
    Name = "Jump Multiplier",
    Range = {1, 2.5},
    Increment = 0.1,
    CurrentValue = 1.3,
    Callback = function(value)
        JumpMult = tonumber(value) or 1.3
    end
})

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
                    pcall(function()
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
                    end)
                end
            end)
            Connections.InfiniteJumpEnded = UserInputService.InputEnded:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Space then
                    IsJumping = false
                end
            end)
            Notify("Infinite Jump", "On")
        else
            IsJumping = false
            Notify("Infinite Jump", "Off")
        end
    end
})

TMovement:CreateDivider()

TMovement:CreateToggle({
    Name = "Gravity Mod",
    CurrentValue = false,
    Callback = function(v)
        disconnect("Gravity")
        if v then
            Connections.Gravity = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hrp = getHRP()
                    if hrp then
                        local vel = hrp.Velocity
                        if vel.Y < -5 then
                            hrp.Velocity = Vector3.new(vel.X, vel.Y * GravityMult, vel.Z)
                        end
                    end
                end)
            end)
            Notify("Gravity Mod", "x" .. string.format("%.1f", GravityMult))
        else
            Notify("Gravity Mod", "Off")
        end
    end
})

TMovement:CreateSlider({
    Name = "Gravity Multiplier",
    Range = {0.1, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(value)
        GravityMult = tonumber(value) or 0.5
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
                pcall(function()
                    local hrp = getHRP()
                    if hrp then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SpinSpd), 0)
                    end
                end)
            end)
            Notify("Spin Mod", "Speed " .. SpinSpd)
        else
            Notify("Spin Mod", "Off")
        end
    end
})

TMovement:CreateSlider({
    Name = "Spin Speed",
    Range = {1, 150},
    Increment = 1,
    CurrentValue = 15,
    Callback = function(value)
        SpinSpd = tonumber(value) or 15
    end
})

TFeatures:CreateToggle({
    Name = "Auto Take Brainrot",
    CurrentValue = false,
    Callback = function(v)
        disconnect("AutoTake")
        if v then
            Connections.AutoTake = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hrp = getHRP()
                    if not hrp then return end
                    for _, item in ipairs(Workspace:GetDescendants()) do
                        if item:IsA("BasePart") then
                            local name = item.Name:lower()
                            local pname = item.Parent.Name:lower()
                            if name:find("brainrot") or name:find("brain") or pname:find("brainrot") then
                                local dist = (item.Position - hrp.Position).Magnitude
                                if dist < 30 then
                                    item.CFrame = hrp.CFrame + Vector3.new(0, 2, 0)
                                end
                            end
                        end
                    end
                end)
            end)
            Notify("Auto Take", "Collecting")
        else
            Notify("Auto Take", "Off")
        end
    end
})

TFeatures:CreateDivider()

TFeatures:CreateToggle({
    Name = "Smart Platform",
    CurrentValue = false,
    Callback = function(v)
        disconnect("Platform")
        if v then
            if not PlatformPart then
                pcall(function()
                    PlatformPart = Instance.new("Part")
                    PlatformPart.Name = "RixPlatform"
                    PlatformPart.Shape = Enum.PartType.Block
                    PlatformPart.Size = Vector3.new(8, 1, 8)
                    PlatformPart.CanCollide = true
                    PlatformPart.Material = Enum.Material.Neon
                    PlatformPart.BrickColor = BrickColor.new("Cyan")
                    PlatformPart.TopSurface = Enum.SurfaceType.Smooth
                    PlatformPart.BottomSurface = Enum.SurfaceType.Smooth
                    PlatformPart.Anchored = true
                    PlatformPart.Transparency = 0.3
                    PlatformPart.Parent = Workspace
                end)
            end
            Connections.Platform = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hrp = getHRP()
                    if hrp and PlatformPart then
                        PlatformPart.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - PlatHeight, hrp.Position.Z)
                    end
                end)
            end)
            Notify("Smart Platform", "On")
        else
            SafeDestroy(PlatformPart)
            PlatformPart = nil
            Notify("Smart Platform", "Off")
        end
    end
})

TFeatures:CreateSlider({
    Name = "Platform Height",
    Range = {3, 20},
    Increment = 1,
    CurrentValue = 8,
    Callback = function(value)
        PlatHeight = tonumber(value) or 8
    end
})

TFeatures:CreateDivider()

TFeatures:CreateToggle({
    Name = "Mega Hitbox",
    CurrentValue = false,
    Callback = function(v)
        disconnect("Hitbox")
        if v then
            pcall(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LP and player.Character then
                        for _, part in ipairs(player.Character:GetDescendants()) do
                            if part:IsA("BasePart") and not OriginalSizes[part] then
                                OriginalSizes[part] = part.Size
                                part.Size = part.Size * HitboxMult
                            end
                        end
                    end
                end
            end)
            Connections.Hitbox = RunService.Heartbeat:Connect(function()
                pcall(function()
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LP and player.Character then
                            for _, part in ipairs(player.Character:GetDescendants()) do
                                if part:IsA("BasePart") and not OriginalSizes[part] then
                                    OriginalSizes[part] = part.Size
                                    part.Size = part.Size * HitboxMult
                                end
                            end
                        end
                    end
                end)
            end)
            Notify("Mega Hitbox", "x" .. HitboxMult)
        else
            disconnect("Hitbox")
            pcall(function()
                for part, size in pairs(OriginalSizes) do
                    if part and part.Parent then
                        part.Size = size
                    end
                end
                OriginalSizes = {}
            end)
            Notify("Mega Hitbox", "Off")
        end
    end
})

TFeatures:CreateSlider({
    Name = "Hitbox Size",
    Range = {1, 3},
    Increment = 0.5,
    CurrentValue = 1.5,
    Callback = function(value)
        HitboxMult = tonumber(value) or 1.5
    end
})

TFeatures:CreateDivider()

TFeatures:CreateToggle({
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
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
            Connections.Fly = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hrp = getHRP()
                    if not hrp or not bodyVelocity then return end
                    local moveDirection = Vector3.new(0, 0, 0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        moveDirection = moveDirection + hrp.CFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        moveDirection = moveDirection - hrp.CFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        moveDirection = moveDirection - hrp.CFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        moveDirection = moveDirection + hrp.CFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        moveDirection = moveDirection + Vector3.new(0, 1, 0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        moveDirection = moveDirection - Vector3.new(0, 1, 0)
                    end
                    if moveDirection.Magnitude > 0 then
                        bodyVelocity.Velocity = moveDirection.Unit * FlySpd
                    else
                        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                    end
                end)
            end)
            Notify("Fly Mode", "WASD+Space/Ctrl")
        else
            SafeDestroy(bodyVelocity)
            bodyVelocity = nil
            Notify("Fly Mode", "Off")
        end
    end
})

TFeatures:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 80},
    Increment = 1,
    CurrentValue = 40,
    Callback = function(value)
        FlySpd = tonumber(value) or 40
    end
})

TVisuals:CreateToggle({
    Name = "ESP Players",
    CurrentValue = false,
    Callback = function(v)
        for _, bb in pairs(ESPObjects) do
            SafeDestroy(bb)
        end
        ESPObjects = {}
        disconnect("ESPUpdate")
        if v then
            local function createESP(player)
                if player == LP or not player.Character then
                    return
                end
                pcall(function()
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    local myHRP = getHRP()
                    if hrp and myHRP then
                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(6, 0, 3, 0)
                        bb.MaxDistance = 2000
                        bb.Adornee = hrp
                        bb.AlwaysOnTop = true
                        bb.Name = "RixESP_" .. player.Name
                        local label = Instance.new("TextLabel")
                        label.Parent = bb
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 0.2
                        label.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
                        label.TextColor3 = Color3.fromRGB(255, 255, 255)
                        label.Font = Enum.Font.GothamBold
                        label.TextSize = 14
                        label.Text = player.Name .. " | " .. math.floor((hrp.Position - myHRP.Position).Magnitude) .. "m"
                        label.TextStrokeTransparency = 0
                        local corner = Instance.new("UICorner")
                        corner.Parent = label
                        corner.CornerRadius = UDim.new(0, 4)
                        bb.Parent = Workspace
                        ESPObjects[player] = bb
                    end
                end)
            end
            for _, player in ipairs(Players:GetPlayers()) do
                createESP(player)
            end
            Connections.ESPUpdate = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local myHRP = getHRP()
                    if not myHRP then
                        return
                    end
                    for player, bb in pairs(ESPObjects) do
                        if player.Character and bb then
                            local label = bb:FindFirstChild("TextLabel")
                            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                            if label and hrp then
                                label.Text = player.Name .. " | " .. math.floor((hrp.Position - myHRP.Position).Magnitude) .. "m"
                            end
                        end
                    end
                end)
            end)
            Notify("ESP", "On")
        else
            Notify("ESP", "Off")
        end
    end
})

TVisuals:CreateDivider()

TVisuals:CreateToggle({
    Name = "Reach Circle",
    CurrentValue = false,
    Callback = function(v)
        if v then
            CreateReachCircle()
            Notify("Reach Circle", "On - " .. ReachDistance .. " studs")
        else
            DestroyReachCircle()
            Notify("Reach Circle", "Off")
        end
    end
})

TVisuals:CreateSlider({
    Name = "Reach Distance",
    Range = {5, 50},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(value)
        ReachDistance = tonumber(value) or 10
        UpdateReachCircle()
    end
})

TVisuals:CreateDivider()

TVisuals:CreateToggle({
    Name = "Xray Vision",
    CurrentValue = false,
    Callback = function(v)
        if v then
            pcall(function()
                for _, part in ipairs(Workspace:GetDescendants()) do
                    if part:IsA("BasePart") and not part:IsDescendantOf(LP.Character) and part.Name ~= "RixPlatform" then
                        if OriginalParts[part] == nil then
                            OriginalParts[part] = part.Transparency
                        end
                        part.Transparency = 0.4
                    end
                end
            end)
            Notify("Xray", "On")
        else
            pcall(function()
                for part, trans in pairs(OriginalParts) do
                    if part and part.Parent then
                        part.Transparency = trans
                    end
                end
                OriginalParts = {}
            end)
            Notify("Xray", "Off")
        end
    end
})

TVisuals:CreateDivider()

TVisuals:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(v)
        pcall(function()
            if v then
                Lighting.Ambient = Color3.fromRGB(200, 200, 200)
                Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
                Lighting.GlobalShadows = false
                Notify("Fullbright", "On")
            else
                Lighting.Ambient = Color3.fromRGB(128, 128, 128)
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                Lighting.GlobalShadows = true
                Notify("Fullbright", "Off")
            end
        end)
    end
})

TProtection:CreateToggle({
    Name = "Anti Cheat Bypass",
    CurrentValue = false,
    Callback = function(v)
        if v then
            AntiCheatEnabled = true
            SetupAntiCheatBypass()
            Notify("Anti Cheat", "Multi-Stage Bypass Active")
        else
            AntiCheatEnabled = false
            Notify("Anti Cheat", "Off")
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
                if getrawmetatable and hookfunction then
                    local mt = getrawmetatable(game)
                    local oldNamecall = mt.__namecall
                    setreadonly(mt, false)
                    mt.__namecall = newcclosure(function(self, ...)
                        local method = getnamecallmethod()
                        if method == "Kick" and self == LP then
                            Notify("Anti Kick", "Blocked")
                            return nil
                        end
                        return oldNamecall(self, ...)
                    end)
                    setreadonly(mt, true)
                end
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
            LastPos = getHRP() and getHRP().Position or Vector3.new(0, 0, 0)
            Connections.AntiTP = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hrp = getHRP()
                    if not hrp then
                        return
                    end
                    local dist = (hrp.Position - LastPos).Magnitude
                    if dist > 150 then
                        hrp.CFrame = CFrame.new(LastPos)
                    else
                        LastPos = hrp.Position
                    end
                end)
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

TAbout:CreateLabel({ Text = "Rix Hub", Style = 1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "Steal a Brainrot", Style = 2 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "Version: 1.1", Style = 1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "Player: " .. LP.Name, Style = 1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "24 Features", Style = 1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "Multi-Stage AC Bypass", Style = 1 })
TAbout:CreateLabel({ Text = "Reach Circle Visual", Style = 1 })
TAbout:CreateLabel({ Text = "Gravity Mod", Style = 1 })
TAbout:CreateLabel({ Text = "PC and Mobile Support", Style = 1 })
TAbout:CreateDivider()

TAbout:CreateButton({
    Name = "Disable All",
    Callback = function()
        for key, _ in pairs(Connections) do
            disconnect(key)
        end
        for _, bb in pairs(ESPObjects) do
            SafeDestroy(bb)
        end
        ESPObjects = {}
        for part, trans in pairs(OriginalParts) do
            if part and part.Parent then
                part.Transparency = trans
            end
        end
        OriginalParts = {}
        for part, size in pairs(OriginalSizes) do
            if part and part.Parent then
                part.Size = size
            end
        end
        OriginalSizes = {}
        SafeDestroy(PlatformPart)
        PlatformPart = nil
        DestroyReachCircle()
        pcall(function()
            local hum = getHum()
            if hum then
                hum.WalkSpeed = OriginalWalkSpeed
                hum.JumpHeight = OriginalJumpHeight
            end
        end)
        SafeDestroy(bodyVelocity)
        bodyVelocity = nil
        IsJumping = false
        AntiCheatEnabled = false
        Notify("All Off", "Disabled")
    end
})

LP.CharacterAdded:Connect(function()
    task.wait(1)
    pcall(function()
        if LastPos then
            LastPos = getHRP() and getHRP().Position or Vector3.new(0, 0, 0)
        end
        local hum = getHum()
        if hum then
            hum.WalkSpeed = OriginalWalkSpeed
            hum.JumpHeight = OriginalJumpHeight
        end
        if AntiCheatEnabled then
            task.delay(2, SetupAntiCheatBypass)
        end
    end)
end)

Notify("Rix Hub", "v1.1 Loaded")
print("RixHub v1.1 Ready")
