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
    Icon = "shield",
    Theme = "Dark",
    Folder = "RixHub",
})

-- Custom Logo
pcall(function()
    task.delay(0.5, function()
        local mainFrame = game.CoreGui:FindFirstChild("WindUI") 
            or game.Players.LocalPlayer.PlayerGui:FindFirstChild("WindUI")
        if mainFrame then
            local topBar = mainFrame:FindFirstChild("TopBar", true) 
                or mainFrame:FindFirstChild("TitleBar", true)
            if topBar then
                local logo = Instance.new("ImageLabel")
                logo.Name = "RixHubLogo"
                logo.Image = "rbxassetid://130188918639066"
                logo.Size = UDim2.new(0, 32, 0, 32)
                logo.Position = UDim2.new(0, 8, 0, 8)
                logo.BackgroundTransparency = 1
                logo.BorderSizePixel = 0
                logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
                logo.Parent = topBar
            end
        end
    end)
end)


local function Notify(title, content)
    WindUI:Notify({
        Title = title,
        Content = content or "",
        Icon = "solar:bell-bold",
        Duration = 4,
    })
end

local function getChar() return LP.Character end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") or nil end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") or nil end

local Connections = {}
local State = {
    SpeedValue = 1.5,
    JumpValue = 1.5,
    SpinValue = 15,
    HitboxValue = 2,
}

local function disconnect(key)
    if Connections[key] then
        Connections[key]:Disconnect()
        Connections[key] = nil
    end
end

-- ============================================
-- TABS
-- ============================================
local TMovement = Window:Tab({ Title = "Movement", Icon = "zap" })
local TFeatures = Window:Tab({ Title = "Features", Icon = "star" })
local TVisuals = Window:Tab({ Title = "Visuals", Icon = "eye" })
local TProtection = Window:Tab({ Title = "Protection", Icon = "shield" })
local TSettings = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ============================================
-- MOVEMENT TAB
-- ============================================

-- Speed Boost
TMovement:Toggle({
    Title = "Speed Boost",
    Icon = "zap",
    Value = false,
    Flag = "SpeedBoost",
    Callback = function(v)
        disconnect("Speed")
        if v then
            Connections.Speed = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hum = getHum()
                    if hum then hum.WalkSpeed = 16 * State.SpeedValue end
                end)
            end)
            Notify("Speed Boost", "Enabled | x" .. State.SpeedValue)
        else
            local hum = getHum()
            if hum then hum.WalkSpeed = 16 end
            Notify("Speed Boost", "Disabled")
        end
    end,
})

TMovement:Slider({
    Title = "Speed Multiplier",
    Description = "Adjust speed multiplier",
    Min = 1,
    Max = 5,
    Default = 1.5,
    Rounding = 1,
    Flag = "SpeedSlider",
    Callback = function(value)
        State.SpeedValue = value
        Notify("Speed", "Multiplier set to x" .. value)
    end,
})

TMovement:Space()

-- Jump Boost
TMovement:Toggle({
    Title = "Jump Boost",
    Icon = "arrow-up",
    Value = false,
    Flag = "JumpBoost",
    Callback = function(v)
        disconnect("Jump")
        if v then
            Connections.Jump = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hum = getHum()
                    if hum then hum.JumpPower = 50 * State.JumpValue end
                end)
            end)
            Notify("Jump Boost", "Enabled | x" .. State.JumpValue)
        else
            local hum = getHum()
            if hum then hum.JumpPower = 50 end
            Notify("Jump Boost", "Disabled")
        end
    end,
})

TMovement:Slider({
    Title = "Jump Multiplier",
    Description = "Adjust jump multiplier",
    Min = 1,
    Max = 5,
    Default = 1.5,
    Rounding = 1,
    Flag = "JumpSlider",
    Callback = function(value)
        State.JumpValue = value
        Notify("Jump", "Multiplier set to x" .. value)
    end,
})

TMovement:Space()

-- Spin Mode (Improved)
TMovement:Toggle({
    Title = "Spin Mode",
    Icon = "rotate-cw",
    Value = false,
    Flag = "SpinMode",
    Callback = function(v)
        disconnect("Spin")
        if v then
            Connections.Spin = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hrp = getHRP()
                    if hrp then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(State.SpinValue), 0)
                    end
                end)
            end)
            Notify("Spin Mode", "Enabled | Speed " .. State.SpinValue)
        else
            Notify("Spin Mode", "Disabled")
        end
    end,
})

TMovement:Slider({
    Title = "Spin Speed",
    Description = "Adjust spin rotation speed",
    Min = 1,
    Max = 100,
    Default = 15,
    Rounding = 0,
    Flag = "SpinSlider",
    Callback = function(value)
        State.SpinValue = value
        Notify("Spin", "Speed set to " .. value)
    end,
})

TMovement:Space()

-- Fly Mode (NEW)
local FlyEnabled = false
local FlyConnection = nil
TMovement:Toggle({
    Title = "Fly Mode",
    Icon = "plane",
    Value = false,
    Flag = "FlyMode",
    Callback = function(v)
        FlyEnabled = v
        if FlyConnection then
            FlyConnection:Disconnect()
            FlyConnection = nil
        end
        if v then
            local hrp = getHRP()
            local hum = getHum()
            if hrp and hum then
                hum.PlatformStand = true
                local bv = Instance.new("BodyVelocity")
                bv.Name = "RixFlyVelocity"
                bv.Velocity = Vector3.new(0, 0, 0)
                bv.MaxForce = Vector3.new(400000, 400000, 400000)
                bv.Parent = hrp

                FlyConnection = RunService.Heartbeat:Connect(function()
                    pcall(function()
                        if not FlyEnabled then return end
                        local hrp2 = getHRP()
                        local cam = Workspace.CurrentCamera
                        if hrp2 and cam then
                            local bv2 = hrp2:FindFirstChild("RixFlyVelocity")
                            if bv2 then
                                local moveDir = Vector3.new(0, 0, 0)
                                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                                    moveDir = moveDir + cam.CFrame.LookVector
                                end
                                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                                    moveDir = moveDir - cam.CFrame.LookVector
                                end
                                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                                    moveDir = moveDir - cam.CFrame.RightVector
                                end
                                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                                    moveDir = moveDir + cam.CFrame.RightVector
                                end
                                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                                    moveDir = moveDir + Vector3.new(0, 1, 0)
                                end
                                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                                    moveDir = moveDir - Vector3.new(0, 1, 0)
                                end
                                bv2.Velocity = moveDir * 50
                            end
                        end
                    end)
                end)
            end
            Notify("Fly Mode", "Enabled | WASD to move, Space/Shift up/down")
        else
            local hrp = getHRP()
            if hrp then
                local bv = hrp:FindFirstChild("RixFlyVelocity")
                if bv then bv:Destroy() end
            end
            local hum = getHum()
            if hum then hum.PlatformStand = false end
            Notify("Fly Mode", "Disabled")
        end
    end,
})

-- ============================================
-- FEATURES TAB
-- ============================================

-- Auto Take Brainrot
TFeatures:Toggle({
    Title = "Auto Take Brainrot",
    Icon = "download",
    Value = false,
    Flag = "AutoTake",
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
                                if dist < 100 then
                                    item.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                                end
                            end
                        end
                    end
                end)
            end)
            Notify("Auto Take", "Collecting Brainrot")
        else
            Notify("Auto Take", "Disabled")
        end
    end,
})

TFeatures:Space()

-- Platform Under You (Fixed - pushes player up when jumping)
local PlatformPart = nil
TFeatures:Toggle({
    Title = "Platform Under You",
    Icon = "layers",
    Value = false,
    Flag = "Platform",
    Callback = function(v)
        disconnect("Platform")
        if v then
            if not PlatformPart then
                pcall(function()
                    PlatformPart = Instance.new("Part")
                    PlatformPart.Name = "RixPlatform"
                    PlatformPart.Size = Vector3.new(12, 1.5, 12)
                    PlatformPart.CanCollide = true
                    PlatformPart.Anchored = true
                    PlatformPart.Material = Enum.Material.Neon
                    PlatformPart.Color = Color3.fromRGB(255, 0, 255)
                    PlatformPart.Transparency = 0.3
                    PlatformPart.TopSurface = Enum.SurfaceType.Smooth
                    PlatformPart.BottomSurface = Enum.SurfaceType.Smooth
                    PlatformPart.Parent = Workspace
                end)
            end
            Connections.Platform = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hrp = getHRP()
                    local hum = getHum()
                    if hrp and hum and PlatformPart then
                        local hrpPos = hrp.Position
                        -- Position platform at feet level
                        PlatformPart.CFrame = CFrame.new(hrpPos.X, hrpPos.Y - 3.5, hrpPos.Z)

                        -- If player is jumping/falling, push them up
                        if hum.FloorMaterial == Enum.Material.Air then
                            local vel = hrp.Velocity
                            if vel.Y < 0 then
                                -- Player is falling, push up
                                hrp.Velocity = Vector3.new(vel.X, 10, vel.Z)
                            end
                        end
                    end
                end)
            end)
            Notify("Platform", "Enabled | Jump to go higher!")
        else
            pcall(function()
                if PlatformPart then PlatformPart:Destroy() PlatformPart = nil end
            end)
            Notify("Platform", "Disabled")
        end
    end,
})

TFeatures:Space()

-- Mega Hitbox
local OriginalSizes = {}
TFeatures:Toggle({
    Title = "Mega Hitbox",
    Icon = "expand",
    Value = false,
    Flag = "Hitbox",
    Callback = function(v)
        disconnect("Hitbox")
        if v then
            -- Save original sizes
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP and player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") and not OriginalSizes[part] then
                            OriginalSizes[part] = part.Size
                        end
                    end
                end
            end

            Connections.Hitbox = RunService.Heartbeat:Connect(function()
                pcall(function()
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LP and player.Character then
                            for _, part in ipairs(player.Character:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    local orig = OriginalSizes[part] or part.Size
                                    if not OriginalSizes[part] then
                                        OriginalSizes[part] = orig
                                    end
                                    part.Size = orig * State.HitboxValue
                                end
                            end
                        end
                    end
                end)
            end)
            Notify("Hitbox", "Enabled | x" .. State.HitboxValue)
        else
            -- Reset sizes
            for part, size in pairs(OriginalSizes) do
                if part and part.Parent then
                    pcall(function() part.Size = size end)
                end
            end
            OriginalSizes = {}
            Notify("Hitbox", "Disabled")
        end
    end,
})

TFeatures:Slider({
    Title = "Hitbox Size",
    Description = "Adjust hitbox multiplier",
    Min = 1,
    Max = 10,
    Default = 2,
    Rounding = 1,
    Flag = "HitboxSlider",
    Callback = function(value)
        State.HitboxValue = value
        Notify("Hitbox", "Size set to x" .. value)
    end,
})

TFeatures:Space()

-- Auto Click (NEW)
TFeatures:Toggle({
    Title = "Auto Click",
    Icon = "mouse-pointer-click",
    Value = false,
    Flag = "AutoClick",
    Callback = function(v)
        disconnect("AutoClick")
        if v then
            Connections.AutoClick = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    end
                end)
            end)
            Notify("Auto Click", "Enabled")
        else
            Notify("Auto Click", "Disabled")
        end
    end,
})

-- ============================================
-- VISUALS TAB
-- ============================================

-- ESP Players
local ESPObjects = {}
TVisuals:Toggle({
    Title = "ESP Players",
    Icon = "eye",
    Value = false,
    Flag = "ESP",
    Callback = function(v)
        -- Clean up existing ESP
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
                            bb.Size = UDim2.new(7, 0, 3.5, 0)
                            bb.MaxDistance = 5000
                            bb.Adornee = hrp
                            bb.AlwaysOnTop = true

                            local label = Instance.new("TextLabel", bb)
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 0.1
                            label.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
                            label.TextColor3 = Color3.fromRGB(255, 255, 255)
                            label.Font = Enum.Font.GothamBold
                            label.TextSize = 16
                            label.Text = player.Name
                            label.TextStrokeTransparency = 0
                            Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)

                            bb.Parent = Workspace
                            ESPObjects[player] = bb
                        end
                    end)
                end
            end

            -- Update ESP on player added
            Connections.ESPPlayerAdded = Players.PlayerAdded:Connect(function(player)
                if not CrystalHub or not State then return end
                task.wait(1)
                pcall(function()
                    if player ~= LP and player.Character then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local bb = Instance.new("BillboardGui")
                            bb.Size = UDim2.new(7, 0, 3.5, 0)
                            bb.MaxDistance = 5000
                            bb.Adornee = hrp
                            bb.AlwaysOnTop = true

                            local label = Instance.new("TextLabel", bb)
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 0.1
                            label.BackgroundColor3 = Color3.fromRGB(255, 0, 150)
                            label.TextColor3 = Color3.fromRGB(255, 255, 255)
                            label.Font = Enum.Font.GothamBold
                            label.TextSize = 16
                            label.Text = player.Name
                            label.TextStrokeTransparency = 0
                            Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)

                            bb.Parent = Workspace
                            ESPObjects[player] = bb
                        end
                    end
                end)
            end)

            Notify("ESP", "Enabled")
        else
            if Connections.ESPPlayerAdded then
                Connections.ESPPlayerAdded:Disconnect()
                Connections.ESPPlayerAdded = nil
            end
            Notify("ESP", "Disabled")
        end
    end,
})

TVisuals:Space()

-- Xray Vision
local OriginalParts = {}
TVisuals:Toggle({
    Title = "Xray Vision",
    Icon = "zap",
    Value = false,
    Flag = "Xray",
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
            Notify("Xray", "Enabled")
        else
            pcall(function()
                for part, trans in pairs(OriginalParts) do
                    if part and part.Parent then part.Transparency = trans end
                end
                OriginalParts = {}
            end)
            Notify("Xray", "Disabled")
        end
    end,
})

TVisuals:Space()

-- Fullbright Mode
TVisuals:Toggle({
    Title = "Fullbright Mode",
    Icon = "sun",
    Value = false,
    Flag = "Fullbright",
    Callback = function(v)
        pcall(function()
            if v then
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                Lighting.GlobalShadows = false
                Notify("Fullbright", "Enabled")
            else
                Lighting.Ambient = Color3.fromRGB(128, 128, 128)
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                Lighting.GlobalShadows = true
                Notify("Fullbright", "Disabled")
            end
        end)
    end,
})

TVisuals:Space()

-- Tracers (NEW)
local TracerLines = {}
TVisuals:Toggle({
    Title = "Player Tracers",
    Icon = "navigation",
    Value = false,
    Flag = "Tracers",
    Callback = function(v)
        disconnect("Tracers")
        for _, line in pairs(TracerLines) do
            if line then pcall(function() line:Destroy() end) end
        end
        TracerLines = {}

        if v then
            Connections.Tracers = RunService.Heartbeat:Connect(function()
                pcall(function()
                    -- Clean up old lines
                    for player, line in pairs(TracerLines) do
                        if not player or not player.Parent or not player.Character then
                            pcall(function() line:Destroy() end)
                            TracerLines[player] = nil
                        end
                    end

                    local myHRP = getHRP()
                    if not myHRP then return end

                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LP and player.Character then
                            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local line = TracerLines[player]
                                if not line then
                                    line = Instance.new("Beam")
                                    local a0 = Instance.new("Attachment", myHRP)
                                    local a1 = Instance.new("Attachment", hrp)
                                    line.Attachment0 = a0
                                    line.Attachment1 = a1
                                    line.Color = ColorSequence.new(Color3.fromRGB(255, 0, 150))
                                    line.Width0 = 0.1
                                    line.Width1 = 0.1
                                    line.FaceCamera = true
                                    line.Parent = Workspace
                                    TracerLines[player] = line
                                end
                            end
                        end
                    end
                end)
            end)
            Notify("Tracers", "Enabled")
        else
            Notify("Tracers", "Disabled")
        end
    end,
})

-- ============================================
-- PROTECTION TAB
-- ============================================

-- Anti Kick
TProtection:Toggle({
    Title = "Anti Kick",
    Icon = "shield",
    Value = false,
    Flag = "AntiKick",
    Callback = function(v)
        if v then
            pcall(function()
                local oldKick = LP.Kick
                LP.Kick = function(self, ...)
                    Notify("Anti Kick", "Blocked kick attempt!")
                    return nil
                end
            end)
            Notify("Anti Kick", "Enabled")
        else
            Notify("Anti Kick", "Disabled")
        end
    end,
})

TProtection:Space()

-- Anti Teleport
local LastPos = nil
TProtection:Toggle({
    Title = "Anti Teleport",
    Icon = "move",
    Value = false,
    Flag = "AntiTP",
    Callback = function(v)
        disconnect("AntiTP")
        if v then
            LastPos = getHRP() and getHRP().Position or Vector3.new(0, 0, 0)
            Connections.AntiTP = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hrp = getHRP()
                    if not hrp then return end
                    local dist = (hrp.Position - LastPos).Magnitude
                    if dist > 300 then
                        hrp.CFrame = CFrame.new(LastPos)
                        Notify("Anti TP", "Teleported back!")
                    else
                        LastPos = hrp.Position
                    end
                end)
            end)
            Notify("Anti TP", "Enabled")
        else
            Notify("Anti TP", "Disabled")
        end
    end,
})

TProtection:Space()

-- Anti Ragdoll (NEW)
TProtection:Toggle({
    Title = "Anti Ragdoll",
    Icon = "lock",
    Value = false,
    Flag = "AntiRagdoll",
    Callback = function(v)
        disconnect("AntiRagdoll")
        if v then
            Connections.AntiRagdoll = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local char = LP.Character
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") and part.Anchored then
                                part.Anchored = false
                            end
                            local n = part.Name:lower()
                            if n:find("ragdoll") or n:find("stun") or n:find("knock") then
                                if not part:IsA("Humanoid") then
                                    pcall(function() part:Destroy() end)
                                end
                            end
                        end
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum.PlatformStand = false
                            hum.AutoRotate = true
                            hum.Sit = false
                        end
                    end
                end)
            end)
            Notify("Anti Ragdoll", "Enabled")
        else
            Notify("Anti Ragdoll", "Disabled")
        end
    end,
})

TProtection:Space()

-- Anti Detect (Fake)
TProtection:Toggle({
    Title = "Anti Detect",
    Icon = "lock",
    Value = false,
    Flag = "AntiDetect",
    Callback = function(v)
        if v then
            Notify("Anti Detect", "Enabled (Basic protection)")
        else
            Notify("Anti Detect", "Disabled")
        end
    end,
})

-- ============================================
-- SETTINGS TAB
-- ============================================
TSettings:Label({ Text = "Rix Hub for Steal a Brainrot" })
TSettings:Space()
TSettings:Label({ Text = "All Systems Active" })
TSettings:Space()
TSettings:Label({ Text = "Player: " .. LP.Name })
TSettings:Space()

TSettings:Button({
    Title = "Disable All Features",
    Icon = "power",
    Callback = function()
        for key, _ in pairs(Connections) do
            disconnect(key)
        end

        for _, bb in pairs(ESPObjects) do
            if bb then pcall(function() bb:Destroy() end) end
        end
        ESPObjects = {}

        for _, line in pairs(TracerLines) do
            if line then pcall(function() line:Destroy() end) end
        end
        TracerLines = {}

        for part, trans in pairs(OriginalParts) do
            if part and part.Parent then part.Transparency = trans end
        end
        OriginalParts = {}

        pcall(function()
            if PlatformPart then PlatformPart:Destroy() PlatformPart = nil end
        end)

        local hum = getHum()
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
        end

        Notify("All Features", "Disabled")
    end,
})

-- Character respawn handler
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    pcall(function()
        if LastPos then
            LastPos = getHRP() and getHRP().Position or Vector3.new(0, 0, 0)
        end
    end)
end)

Notify("Rix Hub", "Loaded Successfully!")
print("Rix Hub for Steal a Brainrot - Ready to use!")
