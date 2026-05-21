local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua", true))()

local Window = Luna:CreateWindow({
    Name = "Rix Hub",
    Subtitle = "Steal a Brainrot",
    LogoID = "130188918639066",
    LoadingEnabled = true,
    LoadingTitle = "Rix Hub",
    LoadingSubtitle = "Загрузка...",
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

if not LP then return end

local Connections = {}
local SpeedMult = 1.5
local JumpMult = 1.5
local SpinSpd = 15
local HitboxMult = 2
local FlySpd = 50
local PlatHeight = 8
local PlatformPart = nil
local ESPObjects = {}
local OriginalParts = {}
local OriginalSizes = {}
local LastPos = nil
local IsJumping = false
local bodyVelocity = nil

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
        Connections[key]:Disconnect()
        Connections[key] = nil
    end
end

local function Notify(title, content)
    Luna:Notification({
        Title = title,
        Icon = "info",
        ImageSource = "Material",
        Content = content or ""
    })
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
                        hum.WalkSpeed = 16 * SpeedMult
                    end
                end)
            end)
            Notify("Speed Boost", "x" .. string.format("%.1f", SpeedMult))
        else
            local hum = getHum()
            if hum then
                hum.WalkSpeed = 16
            end
            Notify("Speed", "Off")
        end
    end
})

TMovement:CreateSlider({
    Name = "Speed x",
    Range = {1, 10},
    Increment = 0.1,
    CurrentValue = 1.5,
    Callback = function(value)
        SpeedMult = tonumber(value) or 1.5
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
                        hum.JumpHeight = 7.2 * JumpMult
                    end
                end)
            end)
            Notify("Jump Boost", "x" .. string.format("%.1f", JumpMult))
        else
            local hum = getHum()
            if hum then
                hum.JumpHeight = 7.2
                end
            Notify("Jump", "Off")
        end
    end
})

TMovement:CreateSlider({
    Name = "Jump x",
    Range = {1, 10},
    Increment = 0.1,
    CurrentValue = 1.5,
    Callback = function(value)
        JumpMult = tonumber(value) or 1.5
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
                                hrp.Velocity = Vector3.new(hrp.Velocity.X, 50, hrp.Velocity.Z)
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
                                if dist < 150 then
                                    item.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                                end
                            end
                        end
                    end
                end)
            end)
            Notify("Auto Take", "Collecting...")
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
                    PlatformPart.Size = Vector3.new(16, 2, 16)
                    PlatformPart.CanCollide = true
                    PlatformPart.Material = Enum.Material.Neon
                    PlatformPart.BrickColor = BrickColor.new("Cyan")
                    PlatformPart.TopSurface = Enum.SurfaceType.Smooth
                    PlatformPart.BottomSurface = Enum.SurfaceType.Smooth
                    PlatformPart.Anchored = true
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
            pcall(function()
                if PlatformPart then
                    PlatformPart:Destroy()
                    PlatformPart = nil
                end
            end)
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
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 2,
    Callback = function(value)
        HitboxMult = tonumber(value) or 2
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
            if bodyVelocity then
                bodyVelocity:Destroy()
                bodyVelocity = nil
            end
            Notify("Fly Mode", "Off")
        end
    end
})

TFeatures:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(value)
        FlySpd = tonumber(value) or 50
    end
})

TVisuals:CreateToggle({
    Name = "ESP Players",
    CurrentValue = false,
    Callback = function(v)
        for _, bb in pairs(ESPObjects) do
            if bb then
                pcall(function()
                    bb:Destroy()
                end)
            end
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
                        bb.Size = UDim2.new(8, 0, 4, 0)
                        bb.MaxDistance = 5000
                        bb.Adornee = hrp
                        bb.AlwaysOnTop = true
                        bb.Name = "RixESP_" .. player.Name
                        local label = Instance.new("TextLabel")
                        label.Parent = bb
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 0.1
                        label.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
                        label.TextColor3 = Color3.fromRGB(255, 255, 255)
                        label.Font = Enum.Font.GothamBold
                        label.TextSize = 16
                        label.Text = player.Name .. " | " .. math.floor((hrp.Position - myHRP.Position).Magnitude) .. "m"
                        label.TextStrokeTransparency = 0
                        local corner = Instance.new("UICorner")
                        corner.Parent = label
                        corner.CornerRadius = UDim.new(0, 6)
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
                        part.Transparency = 0.35
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
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
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
                            Notify("Anti Kick", "Blocked!")
                            return nil
                        end
                        return oldNamecall(self, ...)
                    end)
                    setreadonly(mt, true)
                else
                    LP.Kick = function()
                        Notify("Anti Kick", "Blocked!")
                    end
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
                    if dist > 350 then
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
                    game:GetService("VirtualUser"):CaptureController()
                    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
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
TAbout:CreateLabel({ Text = "20 Features", Style = 1 })
TAbout:CreateDivider()
TAbout:CreateLabel({ Text = "Jump Boost Fixed", Style = 1 })
TAbout:CreateLabel({ Text = "Infinite Jump Fixed", Style = 1 })
TAbout:CreateLabel({ Text = "Mega Hitbox Fixed", Style = 1 })
TAbout:CreateLabel({ Text = "Anti Kick Improved", Style = 1 })
TAbout:CreateLabel({ Text = "ESP Live Update", Style = 1 })
TAbout:CreateDivider()

TAbout:CreateButton({
    Name = "Disable All",
    Callback = function()
        for key, _ in pairs(Connections) do
            disconnect(key)
        end
        for _, bb in pairs(ESPObjects) do
            if bb then
                pcall(function()
                    bb:Destroy()
                end)
            end
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
        pcall(function()
            if PlatformPart then
                PlatformPart:Destroy()
                PlatformPart = nil
            end
        end)
        pcall(function()
            local hum = getHum()
            if hum then
                hum.WalkSpeed = 16
                hum.JumpHeight = 7.2
                end
        end)
        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
        IsJumping = false
        Notify("All Off", "Disabled")
    end
})

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    pcall(function()
        if LastPos then
            LastPos = getHRP() and getHRP().Position or Vector3.new(0, 0, 0)
        end
        local hum = getHum()
        if hum then
            end
    end)
end)

Notify("Rix Hub", "v1.1 Loaded")
print("RixHub v1.1 Ready")
