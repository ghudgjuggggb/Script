
repeat task.wait() until game:IsLoaded()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- Window
local Window = Rayfield:CreateWindow({
    Name = "RixHub Open Source",
    LoadingTitle = "RixHub OS",
    LoadingSubtitle = "Volleyball Legends",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "RixHubOS",
        FileName = "Config"
    },
    Discord = {
        Enabled = true,
        Invite = "sPCKm8juf",
        RememberJoins = true
    },
    KeySystem = false
})

-- Tabs
local TMovement = Window:CreateTab("Movement", "activity")
local TVisuals = Window:CreateTab("Visuals", "eye")
local TFeatures = Window:CreateTab("Features", "zap")
local TAbout = Window:CreateTab("About", "info")

-- Variables
local Connections = {}
local ESPObjects = {}
local BallESPObjects = {}
local OriginalParts = {}
local espHighlights = {}
local espConnections = {}

local SpeedMult = 1.5
local JumpMult = 1.5
local FlySpd = 50
local airMovementSpeed = 16

local ESPRange = 5000
local BallESPRange = 5000

local IsJumping = false
local autoShiftLock = false
local airMovement = false
local espJumpEnabled = false
local linesEnabled = false
local fullbrightEnabled = false
local antiAfkEnabled = false
local speedEnabled = false
local jumpEnabled = false
local infJumpEnabled = false
local flyEnabled = false
local espEnabled = false
local ballEspEnabled = false
local ballHitboxEnabled = false
local antiRagdollEnabled = false

local PlatformPart = nil
local bodyVelocity = nil
local airBodyVelocity = nil

local defaultAmbient = Lighting.Ambient
local defaultBrightness = Lighting.Brightness
local defaultOutdoorAmbient = Lighting.OutdoorAmbient
local defaultFogEnd = Lighting.FogEnd

local OriginalWalkSpeed = 16
local OriginalJumpHeight = 7.2

-- Helpers
local function getChar() return LP.Character end
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
        pcall(function() Connections[key]:Disconnect() end)
        Connections[key] = nil
    end
end

local function SafeDestroy(obj)
    pcall(function() if obj and obj.Parent then obj:Destroy() end end)
end

local function FindBall()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("ball") or n:find("volleyball") or n:find("sphere") then
                return obj
            end
        end
    end
    return nil
end

local function getBallModel()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:match("^CLIENT_BALL_%d+$") then
            return obj:FindFirstChild("Sphere.001") or obj:FindFirstChild("Cube.001")
        end
    end
    return nil
end

-- BALL HITBOX (Fixed Size - Big)
local ballHitboxLoopAlive = false
local managedModelBalls = {}
local originalBallSizes = {}
local ballChildAddedConn = nil

local function applyBallHitboxToModel(model)
    if not (model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then return end
    if model:FindFirstChild("RixBallOS") then return end
    local base = nil
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then base = d; break end
    end
    if not base then return end
    local hb = Instance.new("Part")
    hb.Name = "RixBallOS"
    hb.Shape = Enum.PartType.Ball
    hb.Size = Vector3.new(1, 1, 1) * 8  -- FIXED SIZE: 8x (big)
    hb.CFrame = base.CFrame
    hb.Anchored = false
    hb.CanCollide = false
    hb.Transparency = 0.6
    hb.Material = Enum.Material.ForceField
    hb.Color = Color3.fromRGB(0, 255, 150)
    hb.Massless = true
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = base
    weld.Part1 = hb
    weld.Parent = hb
    hb.Parent = model
    table.insert(managedModelBalls, hb)
end

local function applyBallHitboxToPart(ball)
    if not ball or not ball:IsA("BasePart") then return end
    if originalBallSizes[ball] then return end
    originalBallSizes[ball] = {
        size = ball.Size,
        transparency = ball.Transparency,
        material = ball.Material,
        color = ball.Color,
    }
    ball.Size = ball.Size * 8  -- FIXED SIZE: 8x
    ball.Transparency = 0.5
    ball.Material = Enum.Material.Neon
    ball.Color = Color3.fromRGB(255, 80, 80)
end

local function restoreAllBalls()
    for _, hb in ipairs(managedModelBalls) do
        if hb and hb.Parent then hb:Destroy() end
    end
    managedModelBalls = {}
    for ball, props in pairs(originalBallSizes) do
        if ball and ball.Parent then
            ball.Size = props.size
            ball.Transparency = props.transparency
            ball.Material = props.material
            ball.Color = props.color
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
    if ballChildAddedConn then
        ballChildAddedConn:Disconnect()
        ballChildAddedConn = nil
    end
    restoreAllBalls()
end

-- Setup Character
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
                airBodyVelocity.Name = "AirControlVelocityOS"
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
end)

-- Jump ESP
local function applyJumpESP(player)
    if not player.Character or espHighlights[player] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "JumpESPOS"
    hl.Adornee = player.Character
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
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
            for _, c in pairs(espConnections[player]) do 
                pcall(function() c:Disconnect() end) 
            end
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

for _, p in ipairs(Players:GetPlayers()) do setupJumpESP(p) end
Players.PlayerAdded:Connect(setupJumpESP)

-- CoreGui Error handler
CoreGui.ChildAdded:Connect(function(child)
    if child:IsA("ScreenGui") and child.Name == "ErrorPrompt" then
        task.wait(2)
        pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
    end
end)

if LP.Character then Mouse.TargetFilter = LP.Character end
LP.CharacterAdded:Connect(function(char) Mouse.TargetFilter = char end)

-- ================= MOVEMENT TAB =================
TMovement:CreateSection("Speed & Jump")

TMovement:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Flag = "SpeedBoostOS",
    Callback = function(v)
        speedEnabled = v
        disconnect("Speed")
        if v then
            Connections.Speed = RunService.Heartbeat:Connect(function()
                local hum = getHum()
                if hum then hum.WalkSpeed = 16 * SpeedMult end
            end)
            Rayfield:Notify({
                Title = "Speed",
                Content = "x" .. string.format("%.1f", SpeedMult),
                Duration = 2
            })
        else
            local hum = getHum()
            if hum then hum.WalkSpeed = OriginalWalkSpeed end
        end
    end
})

TMovement:CreateSlider({
    Name = "Speed Multiplier",
    Range = {1, 3},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1.5,
    Flag = "SpeedMultOS",
    Callback = function(v) SpeedMult = v end
})

TMovement:CreateToggle({
    Name = "Jump Boost",
    CurrentValue = false,
    Flag = "JumpBoostOS",
    Callback = function(v)
        jumpEnabled = v
        disconnect("Jump")
        if v then
            Connections.Jump = RunService.Heartbeat:Connect(function()
                local hum = getHum()
                if hum then hum.JumpHeight = OriginalJumpHeight * JumpMult end
            end)
        else
            local hum = getHum()
            if hum then hum.JumpHeight = OriginalJumpHeight end
        end
    end
})

TMovement:CreateSlider({
    Name = "Jump Multiplier",
    Range = {1, 3},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1.5,
    Flag = "JumpMultOS",
    Callback = function(v) JumpMult = v end
})

TMovement:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJumpOS",
    Callback = function(v)
        infJumpEnabled = v
        disconnect("InfiniteJump")
        disconnect("InfiniteJumpEnd")
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
                            game:GetService("Debris"):AddItem(bv, 0.1)
                        end
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
            Connections.InfiniteJumpEnd = UserInputService.InputEnded:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Space then IsJumping = false end
            end)
        else
            IsJumping = false
        end
    end
})

TMovement:CreateSection("Flight & Air")

TMovement:CreateToggle({
    Name = "Air Movement",
    CurrentValue = false,
    Flag = "AirMoveOS",
    Callback = function(v)
        airMovement = v
        if not v and airBodyVelocity then
            airBodyVelocity:Destroy()
            airBodyVelocity = nil
        end
    end
})

TMovement:CreateSlider({
    Name = "Air Speed",
    Range = {0, 50},
    Increment = 1,
    Suffix = "",
    CurrentValue = 16,
    Flag = "AirSpeedOS",
    Callback = function(v) airMovementSpeed = v end
})

TMovement:CreateToggle({
    Name = "Fly Mode (WASD + Space/Ctrl)",
    CurrentValue = false,
    Flag = "FlyOS",
    Callback = function(v)
        flyEnabled = v
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
                local hrp = getHRP()
                if not hrp or not bodyVelocity then return end
                local move = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + hrp.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - hrp.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - hrp.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + hrp.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
                bodyVelocity.Velocity = move.Magnitude > 0 and move.Unit * FlySpd or Vector3.new(0, 0, 0)
            end)
        else
            SafeDestroy(bodyVelocity)
            bodyVelocity = nil
        end
    end
})

TMovement:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 50,
    Flag = "FlySpeedOS",
    Callback = function(v) FlySpd = v end
})

TMovement:CreateToggle({
    Name = "Anti Ragdoll",
    CurrentValue = false,
    Flag = "AntiRagdollOS",
    Callback = function(v)
        antiRagdollEnabled = v
        disconnect("AntiRagdoll")
        if v then
            Connections.AntiRagdoll = RunService.Heartbeat:Connect(function()
                local char = getChar()
                if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BallSocketConstraint") or part:IsA("HingeConstraint") then
                        SafeDestroy(part)
                    end
                end
                local hum = getHum()
                if hum then
                    if hum.PlatformStand then hum.PlatformStand = false end
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
        end
    end
})

-- ================= VISUALS TAB =================
TVisuals:CreateSection("Player ESP")

TVisuals:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "PlayerESPOS",
    Callback = function(v)
        espEnabled = v
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
                frame.Size = UDim2.new(1, 0, 1, 0)
                frame.BackgroundTransparency = 0.1
                frame.BorderSizePixel = 0
                frame.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
                frame.Parent = bb
                local label = Instance.new("TextLabel")
                label.Parent = frame
                label.Size = UDim2.new(1, 0, 0.5, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                label.Font = Enum.Font.GothamBold
                label.TextSize = 16
                label.Text = player.Name
                label.TextStrokeTransparency = 0
                local distLabel = Instance.new("TextLabel")
                distLabel.Parent = frame
                distLabel.Size = UDim2.new(1, 0, 0.5, 0)
                distLabel.Position = UDim2.new(0, 0, 0.5, 0)
                distLabel.BackgroundTransparency = 1
                distLabel.TextColor3 = Color3.fromRGB(200, 255, 255)
                distLabel.Font = Enum.Font.GothamBold
                distLabel.TextSize = 14
                distLabel.Text = math.floor((hrp.Position - myHRP.Position).Magnitude) .. "m"
                distLabel.TextStrokeTransparency = 0
                Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
                bb.Parent = Workspace
                ESPObjects[player] = bb
            end
            for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
            Connections.ESPUpdate = RunService.Heartbeat:Connect(function()
                local myHRP = getHRP()
                if not myHRP then return end
                for player, bb in pairs(ESPObjects) do
                    if player.Character and bb then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local fr = bb:FindFirstChildOfClass("Frame")
                            if fr then
                                for _, lbl in ipairs(fr:GetChildren()) do
                                    if lbl:IsA("TextLabel") and lbl.Text:find("m") then
                                        lbl.Text = math.floor((hrp.Position - myHRP.Position).Magnitude) .. "m"
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
})

TVisuals:CreateSlider({
    Name = "ESP Range",
    Range = {100, 10000},
    Increment = 100,
    Suffix = "",
    CurrentValue = 5000,
    Flag = "ESPRangeOS",
    Callback = function(v) ESPRange = v end
})

TVisuals:CreateToggle({
    Name = "Jump ESP (Enemies)",
    CurrentValue = false,
    Flag = "JumpESPOS",
    Callback = function(v)
        espJumpEnabled = v
        if not v then
            for p, _ in pairs(espHighlights) do removeJumpESP(p) end
        end
    end
})

TVisuals:CreateSection("Ball Visuals")

TVisuals:CreateToggle({
    Name = "Ball ESP",
    CurrentValue = false,
    Flag = "BallESPOS",
    Callback = function(v)
        ballEspEnabled = v
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
                frame.Size = UDim2.new(1, 0, 1, 0)
                frame.BackgroundTransparency = 0.05
                frame.BorderSizePixel = 0
                frame.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                frame.Parent = bb
                local label = Instance.new("TextLabel")
                label.Parent = frame
                label.Size = UDim2.new(1, 0, 0.5, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                label.Font = Enum.Font.GothamBold
                label.TextSize = 18
                label.Text = "BALL"
                label.TextStrokeTransparency = 0
                local velLabel = Instance.new("TextLabel")
                velLabel.Parent = frame
                velLabel.Size = UDim2.new(1, 0, 0.5, 0)
                velLabel.Position = UDim2.new(0, 0, 0.5, 0)
                velLabel.BackgroundTransparency = 1
                velLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
                velLabel.Font = Enum.Font.GothamBold
                velLabel.TextSize = 14
                velLabel.Text = "Speed: " .. math.floor(ball.Velocity.Magnitude)
                velLabel.TextStrokeTransparency = 0
                Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
                bb.Parent = Workspace
                BallESPObjects[ball] = bb
            end
            local ball = FindBall()
            if ball then createBallESP(ball) end
            Connections.BallESPUpdate = RunService.Heartbeat:Connect(function()
                local ball = FindBall()
                if ball and not BallESPObjects[ball] then createBallESP(ball) end
            end)
        end
    end
})

TVisuals:CreateSlider({
    Name = "Ball ESP Range",
    Range = {100, 10000},
    Increment = 100,
    Suffix = "",
    CurrentValue = 5000,
    Flag = "BallESPRangeOS",
    Callback = function(v) BallESPRange = v end
})

TVisuals:CreateSection("Lighting")

TVisuals:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "FullbrightOS",
    Callback = function(v)
        fullbrightEnabled = v
        if v then
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        else
            Lighting.Brightness = defaultBrightness
            Lighting.Ambient = defaultAmbient
            Lighting.OutdoorAmbient = defaultOutdoorAmbient
        end
    end
})

TVisuals:CreateToggle({
    Name = "Night Mode",
    CurrentValue = false,
    Flag = "NightModeOS",
    Callback = function(v)
        if v then
            Lighting.Ambient = Color3.fromRGB(20, 20, 20)
            Lighting.Brightness = 1
        else
            Lighting.Ambient = defaultAmbient
            Lighting.Brightness = defaultBrightness
        end
    end
})

TVisuals:CreateButton({
    Name = "Reset Lighting",
    Callback = function()
        Lighting.Brightness = defaultBrightness
        Lighting.Ambient = defaultAmbient
        Lighting.OutdoorAmbient = defaultOutdoorAmbient
        Lighting.FogEnd = defaultFogEnd
        Rayfield:Notify({ Title = "Lighting", Content = "Reset", Duration = 2 })
    end
})

-- ================= FEATURES TAB =================
TFeatures:CreateSection("Ball Hitbox")

TFeatures:CreateToggle({
    Name = "Big Ball Hitbox (Fixed 8x)",
    CurrentValue = false,
    Flag = "BallHitboxOS",
    Callback = function(v)
        ballHitboxEnabled = v
        if v then
            enableBallHitbox()
            Rayfield:Notify({
                Title = "Ball Hitbox",
                Content = "ON - Fixed size 8x (cannot be edited)",
                Duration = 3
            })
        else
            disableBallHitbox()
            Rayfield:Notify({
                Title = "Ball Hitbox",
                Content = "OFF - Restored",
                Duration = 2
            })
        end
    end
})

TFeatures:CreateParagraph({
    Title = "Hitbox Info",
    Content = "This hitbox has a FIXED size of 8x. The size slider is removed in the open-source version to prevent easy copying of premium features."
})

TFeatures:CreateSection("Utility")

TFeatures:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAfkOS",
    Callback = function(v)
        antiAfkEnabled = v
        disconnect("AntiAFK")
        if v then
            Connections.AntiAFK = RunService.Heartbeat:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end)
        end
    end
})

TFeatures:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
    end
})

-- ================= ABOUT TAB =================
TAbout:CreateSection("Info")

TAbout:CreateParagraph({
    Title = "RixHub Open Source v1.0",
    Content = "A free, open-source version of RixHub for Volleyball Legends. Built with Rayfield UI. This version includes basic movement, visuals, and utility features. Premium features like Auto Farm, Auto Spin, and advanced hitboxes are exclusive to the full version."
})

TAbout:CreateParagraph({
    Title = "Discord",
    Content = "discord.gg/sPCKm8juf - Join for updates, support, and the full version!"
})

TAbout:CreateParagraph({
    Title = "Player",
    Content = "Current player: " .. LP.Name
})

TAbout:CreateSection("Features List")

TAbout:CreateParagraph({
    Title = "Movement",
    Content = "- Speed Boost (1x-3x)\n- Jump Boost (1x-3x)\n- Infinite Jump\n- Air Movement\n- Fly Mode\n- Anti Ragdoll"
})

TAbout:CreateParagraph({
    Title = "Visuals",
    Content = "- Player ESP with distance\n- Jump ESP for enemies\n- Ball ESP with velocity\n- Fullbright\n- Night Mode"
})

TAbout:CreateParagraph({
    Title = "Features",
    Content = "- Big Ball Hitbox (Fixed 8x)\n- Anti AFK\n- Rejoin Server"
})

TAbout:CreateButton({
    Name = "Disable ALL Features",
    Callback = function()
        for key, _ in pairs(Connections) do disconnect(key) end
        for _, bb in pairs(ESPObjects) do SafeDestroy(bb) end
        ESPObjects = {}
        for _, bb in pairs(BallESPObjects) do SafeDestroy(bb) end
        BallESPObjects = {}
        for p, _ in pairs(espHighlights) do removeJumpESP(p) end
        disableBallHitbox()
        SafeDestroy(PlatformPart)
        PlatformPart = nil
        SafeDestroy(bodyVelocity)
        bodyVelocity = nil
        local hum = getHum()
        if hum then
            hum.WalkSpeed = OriginalWalkSpeed
            hum.JumpHeight = OriginalJumpHeight
        end
        Lighting.Brightness = defaultBrightness
        Lighting.Ambient = defaultAmbient
        Lighting.OutdoorAmbient = defaultOutdoorAmbient
        Lighting.FogEnd = defaultFogEnd
        speedEnabled = false
        jumpEnabled = false
        infJumpEnabled = false
        flyEnabled = false
        espEnabled = false
        ballEspEnabled = false
        ballHitboxEnabled = false
        antiRagdollEnabled = false
        antiAfkEnabled = false
        fullbrightEnabled = false
        airMovement = false
        espJumpEnabled = false
        Rayfield:Notify({
            Title = "All OFF",
            Content = "Every feature disabled",
            Duration = 3
        })
    end
})

-- Character respawn handler
LP.CharacterAdded:Connect(function()
    task.wait(1)
    local hum = getHum()
    if hum then
        hum.WalkSpeed = OriginalWalkSpeed
        hum.JumpHeight = OriginalJumpHeight
    end
end)

Rayfield:Notify({
    Title = "RixHub OS",
    Content = "v1.0 loaded! Open-source edition.",
    Duration = 4
})

print("[RixHub OS] v1.0 loaded for Volleyball Legends")
