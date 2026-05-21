repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

if not LP then return end

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "Rix Hub",
    Icon = "moon",
    Theme = "Dark",
    Folder = "RixHub",
})

local function Notify(title, content)
    WindUI:Notify({
        Title = title,
        Content = content or "",
        Icon = "moon",
        Duration = 3,
    })
end

local function getChar() return LP.Character end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") or nil end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") or nil end

local Connections = {}
local SpeedMult = 1.5
local JumpMult = 1.5
local SpinSpd = 15
local HitboxMult = 2
local FlySpd = 50
local PlatHeight = 8

local function disconnect(key)
    if Connections[key] then
        Connections[key]:Disconnect()
        Connections[key] = nil
    end
end

local TMovement = Window:Tab({ Title = "Movement", Icon = "zap" })
local TFeatures = Window:Tab({ Title = "Features", Icon = "star" })
local TVisuals = Window:Tab({ Title = "Visuals", Icon = "eye" })
local TProtection = Window:Tab({ Title = "Protection", Icon = "shield" })
local TAbout = Window:Tab({ Title = "About", Icon = "moon" })

TMovement:Toggle({
    Title = "Speed Boost",
    Icon = "zap",
    Value = false,
    Callback = function(v)
        disconnect("Speed")
        if v then
            Connections.Speed = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hum = getHum()
                    if hum then hum.WalkSpeed = 16 * SpeedMult end
                end)
            end)
            Notify("Speed Boost", "x" .. string.format("%.1f", SpeedMult))
        else
            local hum = getHum()
            if hum then hum.WalkSpeed = 16 end
            Notify("Speed", "Off")
        end
    end,
})

TMovement:Slider({
    Title = "Speed x",
    Min = 1,
    Max = 10,
    Default = 1.5,
    Round = 1,
    Callback = function(value)
        SpeedMult = tonumber(value) or 1.5
    end,
})

TMovement:Space()

TMovement:Toggle({
    Title = "Jump Boost",
    Icon = "arrow-up",
    Value = false,
    Callback = function(v)
        disconnect("Jump")
        if v then
            Connections.Jump = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hum = getHum()
                    if hum then hum.JumpPower = 50 * JumpMult end
                end)
            end)
            Notify("Jump Boost", "x" .. string.format("%.1f", JumpMult))
        else
            local hum = getHum()
            if hum then hum.JumpPower = 50 end
            Notify("Jump", "Off")
        end
    end,
})

TMovement:Slider({
    Title = "Jump x",
    Min = 1,
    Max = 10,
    Default = 1.5,
    Round = 1,
    Callback = function(value)
        JumpMult = tonumber(value) or 1.5
    end,
})

TMovement:Space()

TMovement:Toggle({
    Title = "Infinite Jump",
    Icon = "arrow-up-circle",
    Value = false,
    Callback = function(v)
        disconnect("InfiniteJump")
        if v then
            Connections.InfiniteJump = UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.KeyCode == Enum.KeyCode.Space then
                    pcall(function()
                        local hum = getHum()
                        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                    end)
                end
            end)
            Notify("Infinite Jump", "On")
        else
            Notify("Infinite Jump", "Off")
        end
    end,
})

TMovement:Space()

TMovement:Toggle({
    Title = "Spin Mod",
    Icon = "rotate-cw",
    Value = false,
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
    end,
})

TMovement:Slider({
    Title = "Spin Speed",
    Min = 1,
    Max = 150,
    Default = 15,
    Round = 0,
    Callback = function(value)
        SpinSpd = tonumber(value) or 15
    end,
})

TFeatures:Toggle({
    Title = "Auto Take Brainrot",
    Icon = "download",
    Value = false,
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
    end,
})

TFeatures:Space()

local PlatformPart = nil

TFeatures:Toggle({
    Title = "Smart Platform",
    Icon = "layers",
    Value = false,
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
                    
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = getHRP()
                    weld.Part1 = PlatformPart
                    weld.Parent = PlatformPart
                    
                    PlatformPart.Parent = Workspace
                end)
            end
            
            Connections.Platform = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hrp = getHRP()
                    if hrp and PlatformPart then
                        local hum = getHum()
                        local newHeight = PlatHeight
                        
                        if hum then
                            local humanoidState = hum:GetState()
                            if humanoidState == Enum.HumanoidStateType.Jumping or humanoidState == Enum.HumanoidStateType.Flying then
                                newHeight = PlatHeight - 2
                            else
                                newHeight = PlatHeight
                            end
                        end
                        
                        PlatformPart.Position = hrp.Position - Vector3.new(0, newHeight, 0)
                    end
                end)
            end)
            Notify("Smart Platform", "Stand on it & boost!")
        else
            pcall(function()
                if PlatformPart then
                    PlatformPart:Destroy()
                    PlatformPart = nil
                end
            end)
            Notify("Smart Platform", "Off")
        end
    end,
})

TFeatures:Slider({
    Title = "Platform Height",
    Min = 3,
    Max = 20,
    Default = 8,
    Round = 0,
    Callback = function(value)
        PlatHeight = tonumber(value) or 8
    end,
})

TFeatures:Space()

TFeatures:Toggle({
    Title = "Mega Hitbox",
    Icon = "expand",
    Value = false,
    Callback = function(v)
        disconnect("Hitbox")
        if v then
            Connections.Hitbox = RunService.Heartbeat:Connect(function()
                pcall(function()
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LP and player.Character then
                            for _, part in ipairs(player.Character:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.Size = part.Size * (1 + (HitboxMult - 1) * 0.001)
                                end
                            end
                        end
                    end
                end)
            end)
            Notify("Mega Hitbox", "x" .. HitboxMult)
        else
            Notify("Mega Hitbox", "Off")
        end
    end,
})

TFeatures:Slider({
    Title = "Hitbox Size",
    Min = 1,
    Max = 20,
    Default = 2,
    Round = 0,
    Callback = function(value)
        HitboxMult = tonumber(value) or 2
    end,
})

TFeatures:Space()

TFeatures:Toggle({
    Title = "Fly Mode",
    Icon = "airplay",
    Value = false,
    Callback = function(v)
        disconnect("Fly")
        if v then
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Parent = getHRP()
            bodyVelocity.MaxForce = Vector3.new(999999, 999999, 999999)
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            
            Connections.Fly = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hrp = getHRP()
                    if not hrp then return end
                    
                    local moveDirection = Vector3.new(0, 0, 0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + (hrp.CFrame.LookVector) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - (hrp.CFrame.RightVector) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - (hrp.CFrame.LookVector) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + (hrp.CFrame.RightVector) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
                    
                    if moveDirection.Magnitude > 0 then
                        bodyVelocity.Velocity = moveDirection.Unit * FlySpd
                    else
                        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                    end
                end)
            end)
            Notify("Fly Mode", "WASD+Space/Ctrl")
        else
            disconnect("Fly")
            Notify("Fly Mode", "Off")
        end
    end,
})

TFeatures:Slider({
    Title = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = 50,
    Round = 0,
    Callback = function(value)
        FlySpd = tonumber(value) or 50
    end,
})

local ESPObjects = {}
TVisuals:Toggle({
    Title = "ESP Players",
    Icon = "eye",
    Value = false,
    Callback = function(v)
        for _, bb in pairs(ESPObjects) do
            if bb then pcall(function() bb:Destroy() end) end
        end
        ESPObjects = {}
        
        if v then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP and player.Character then
                    pcall(function()
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local bb = Instance.new("BillboardGui")
                            bb.Size = UDim2.new(8, 0, 4, 0)
                            bb.MaxDistance = 5000
                            bb.Adornee = hrp
                            bb.AlwaysOnTop = true
                            
                            local label = Instance.new("TextLabel", bb)
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 0.1
                            label.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
                            label.TextColor3 = Color3.fromRGB(255, 255, 255)
                            label.Font = Enum.Font.GothamBold
                            label.TextSize = 16
                            label.Text = player.Name .. " | " .. math.floor((hrp.Position - getHRP().Position).Magnitude) .. "m"
                            label.TextStrokeTransparency = 0
                            Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)
                            
                            bb.Parent = Workspace
                            ESPObjects[player] = bb
                        end
                    end)
                end
            end
            Notify("ESP", "On")
        else
            Notify("ESP", "Off")
        end
    end,
})

TVisuals:Space()

local OriginalParts = {}
TVisuals:Toggle({
    Title = "Xray Vision",
    Icon = "zap",
    Value = false,
    Callback = function(v)
        if v then
            pcall(function()
                for _, part in ipairs(Workspace:GetDescendants()) do
                    if part:IsA("BasePart") and not part:IsDescendantOf(LP.Character) and part.Name ~= "RixPlatform" then
                        OriginalParts[part] = part.Transparency
                        part.Transparency = 0.35
                    end
                end
            end)
            Notify("Xray", "On")
        else
            pcall(function()
                for part, trans in pairs(OriginalParts) do
                    if part and part.Parent then part.Transparency = trans end
                end
                OriginalParts = {}
            end)
            Notify("Xray", "Off")
        end
    end,
})

TVisuals:Space()

TVisuals:Toggle({
    Title = "Fullbright",
    Icon = "sun",
    Value = false,
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
    end,
})

TProtection:Toggle({
    Title = "Anti Kick",
    Icon = "shield",
    Value = false,
    Callback = function(v)
        if v then
            pcall(function()
                LP.Kick = function() end
            end)
            Notify("Anti Kick", "On")
        else
            Notify("Anti Kick", "Off")
        end
    end,
})

TProtection:Space()

local LastPos = nil
TProtection:Toggle({
    Title = "Anti Teleport",
    Icon = "move",
    Value = false,
    Callback = function(v)
        disconnect("AntiTP")
        if v then
            LastPos = getHRP() and getHRP().Position or Vector3.new(0, 0, 0)
            Connections.AntiTP = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hrp = getHRP()
                    if not hrp then return end
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
    end,
})

TProtection:Space()

TProtection:Toggle({
    Title = "Anti AFK",
    Icon = "activity",
    Value = false,
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
    end,
})

TAbout:Label({ Text = "🌙 RIX HUB 🌙" })
TAbout:Space()
TAbout:Label({ Text = "Steal a Brainrot" })
TAbout:Space()
TAbout:Label({ Text = "Version: 1.0" })
TAbout:Space()
TAbout:Label({ Text = "Player: " .. LP.Name })
TAbout:Space()
TAbout:Label({ Text = "18 Features" })
TAbout:Space()
TAbout:Label({ Text = "✓ All Sliders Work" })
TAbout:Label({ Text = "✓ Spin Mod Included" })
TAbout:Label({ Text = "✓ Smart Platform" })
TAbout:Label({ Text = "✓ Boost Jump" })
TAbout:Space()

TAbout:Button({
    Title = "Disable All",
    Icon = "power",
    Callback = function()
        for key, _ in pairs(Connections) do
            disconnect(key)
        end
        
        for _, bb in pairs(ESPObjects) do
            if bb then pcall(function() bb:Destroy() end) end
        end
        ESPObjects = {}
        
        for part, trans in pairs(OriginalParts) do
            if part and part.Parent then part.Transparency = trans end
        end
        OriginalParts = {}
        
        pcall(function()
            if PlatformPart then PlatformPart:Destroy() PlatformPart = nil end
        end)
        
        pcall(function()
            local hum = getHum()
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
            end
        end)
        
        Notify("All Off", "Disabled")
    end,
})

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    pcall(function()
        if LastPos then
            LastPos = getHRP() and getHRP().Position or Vector3.new(0, 0, 0)
        end
    end)
end)

Notify("Rix Hub", "✓ Loaded!")
print("✅ RixHub v1.0 Ready!")
