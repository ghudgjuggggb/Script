local CrystalHub = {
    Version = "1.0.0",
    Name = "Crystal Hub",
    Game = "Neo Tennis",
    Enabled = true,
    Features = {
        ESPPlayers = false,
        ESPBall = false,
        BallTrajectory = false,
        SpeedBoost = false,
        DoubleJump = false,
        AntiRagdoll = false,
        SpinBot = false,
        HitboxMultiplier = 1,
    },
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "CrystalESP"
ESPFolder.Parent = Workspace

local TrajectoryFolder = Instance.new("Folder")
TrajectoryFolder.Name = "CrystalTrajectory"
TrajectoryFolder.Parent = Workspace

local function GetCharacter()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function GetHRP()
    local char = GetCharacter()
    return char:WaitForChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char:FindFirstChildOfClass("Humanoid")
end

local function CreateESP(player)
    if player == LP then return end

    local espFrame = Instance.new("BillboardGui")
    espFrame.Name = player.Name .. "_ESP"
    espFrame.Parent = ESPFolder
    espFrame.Size = UDim2.new(0, 200, 0, 60)
    espFrame.StudsOffset = Vector3.new(0, 3, 0)
    espFrame.AlwaysOnTop = true
    espFrame.MaxDistance = 500

    local bg = Instance.new("Frame", espFrame)
    bg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    bg.Size = UDim2.new(1, 0, 1, 0)
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

    local nameLabel = Instance.new("TextLabel", bg)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
    nameLabel.TextSize = 14

    local distLabel = Instance.new("TextLabel", bg)
    distLabel.BackgroundTransparency = 1
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Font = Enum.Font.Gotham
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextSize = 12

    local box = Instance.new("BoxHandleAdornment", ESPFolder)
    box.Name = player.Name .. "_Box"
    box.Color3 = Color3.fromRGB(0, 255, 200)
    box.Transparency = 0.7
    box.ZIndex = 10
    box.AlwaysOnTop = true
    box.Size = Vector3.new(4, 6, 4)

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not CrystalHub.Features.ESPPlayers then
            espFrame.Enabled = false
            box.Visible = false
            return
        end

        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local hrp = char.HumanoidRootPart
            local myHRP = GetHRP()
            local dist = (hrp.Position - myHRP.Position).Magnitude

            espFrame.Adornee = hrp
            espFrame.Enabled = true
            distLabel.Text = string.format("%.1fm", dist)

            box.Adornee = hrp
            box.Visible = true
            box.Size = Vector3.new(4, 6, 4)

            if dist < 20 then
                nameLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                box.Color3 = Color3.fromRGB(255, 50, 50)
            else
                nameLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
                box.Color3 = Color3.fromRGB(0, 255, 200)
            end
        else
            espFrame.Enabled = false
            box.Visible = false
        end
    end)

    player.CharacterRemoving:Connect(function()
        espFrame.Enabled = false
        box.Visible = false
    end)
end

local function CreateBallESP()
    local ballESP = Instance.new("BillboardGui")
    ballESP.Name = "BallESP"
    ballESP.Parent = ESPFolder
    ballESP.Size = UDim2.new(0, 150, 0, 50)
    ballESP.StudsOffset = Vector3.new(0, 2, 0)
    ballESP.AlwaysOnTop = true

    local bg = Instance.new("Frame", ballESP)
    bg.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    bg.Size = UDim2.new(1, 0, 1, 0)
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", bg)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.Text = "BALL"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16

    local ballBox = Instance.new("BoxHandleAdornment", ESPFolder)
    ballBox.Name = "BallBox"
    ballBox.Color3 = Color3.fromRGB(255, 150, 50)
    ballBox.Transparency = 0.5
    ballBox.ZIndex = 10
    ballBox.AlwaysOnTop = true

    RunService.RenderStepped:Connect(function()
        if not CrystalHub.Features.ESPBall then
            ballESP.Enabled = false
            ballBox.Visible = false
            return
        end

        local ball = nil
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v.Name:lower():find("ball") and (v:IsA("BasePart") or v:IsA("MeshPart")) then
                ball = v
                break
            end
        end

        if ball then
            ballESP.Adornee = ball
            ballESP.Enabled = true
            ballBox.Adornee = ball
            ballBox.Visible = true
            ballBox.Size = ball.Size * CrystalHub.Features.HitboxMultiplier
        else
            ballESP.Enabled = false
            ballBox.Visible = false
        end
    end)
end

local function CreateTrajectory()
    local trajectoryPart = Instance.new("Part")
    trajectoryPart.Name = "TrajectoryLine"
    trajectoryPart.Parent = TrajectoryFolder
    trajectoryPart.Anchored = true
    trajectoryPart.CanCollide = false
    trajectoryPart.Transparency = 0.3
    trajectoryPart.Color = Color3.fromRGB(0, 200, 255)
    trajectoryPart.Material = Enum.Material.Neon
    trajectoryPart.Size = Vector3.new(0.2, 0.2, 1)

    RunService.RenderStepped:Connect(function()
        if not CrystalHub.Features.BallTrajectory then
            trajectoryPart.Transparency = 1
            return
        end

        local ball = nil
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v.Name:lower():find("ball") and (v:IsA("BasePart") or v:IsA("MeshPart")) then
                ball = v
                break
            end
        end

        if ball and ball.Velocity.Magnitude > 1 then
            trajectoryPart.Transparency = 0.3
            local velocity = ball.Velocity
            local position = ball.Position
            local direction = velocity.Unit
            local distance = math.min(velocity.Magnitude * 2, 100)

            trajectoryPart.CFrame = CFrame.lookAt(position, position + direction)
            trajectoryPart.Size = Vector3.new(0.2, 0.2, distance)
            trajectoryPart.Position = position + direction * (distance / 2)
        else
            trajectoryPart.Transparency = 1
        end
    end)
end

local function SpeedBoostLoop()
    while true do
        if CrystalHub.Features.SpeedBoost then
            local humanoid = GetHumanoid()
            if humanoid then
                humanoid.WalkSpeed = 32
            end
        end
        task.wait(0.1)
    end
end

local function DoubleJumpLoop()
    local canDoubleJump = false
    local hasDoubleJumped = false

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not CrystalHub.Features.DoubleJump then return end
        if input.KeyCode ~= Enum.KeyCode.Space then return end

        local humanoid = GetHumanoid()
        if not humanoid then return end

        if humanoid.FloorMaterial ~= Enum.Material.Air then
            canDoubleJump = true
            hasDoubleJumped = false
        elseif canDoubleJump and not hasDoubleJumped then
            hasDoubleJumped = true
            local hrp = GetHRP()
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 50, hrp.Velocity.Z)
        end
    end)
end

local function AntiRagdollLoop()
    while true do
        if CrystalHub.Features.AntiRagdoll then
            local char = GetCharacter()
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("Humanoid") then
                    v.PlatformStand = false
                    v.AutoRotate = true
                end
                if v.Name:lower():find("ragdoll") or v.Name:lower():find("stun") or v.Name:lower():find("knock") then
                    v:Destroy()
                end
            end
        end
        task.wait(0.1)
    end
end

local function SpinBotLoop()
    while true do
        if CrystalHub.Features.SpinBot then
            local hrp = GetHRP()
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(20), 0)
        end
        task.wait(0.05)
    end
end

local function HitboxLoop()
    while true do
        if CrystalHub.Features.HitboxMultiplier > 1 then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v.Name:lower():find("ball") and (v:IsA("BasePart") or v:IsA("MeshPart")) then
                    v.Size = Vector3.new(2, 2, 2) * CrystalHub.Features.HitboxMultiplier
                end
            end
        end
        task.wait(1)
    end
end

local function CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CrystalHubNeoTennis"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    local Main = Instance.new("Frame", ScreenGui)
    Main.Name = "Main"
    Main.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -250, 0.5, -200)
    Main.Size = UDim2.new(0, 500, 0, 380)
    Main.Active = true
    Main.Draggable = true
    Main.ClipsDescendants = true

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = Color3.fromRGB(40, 40, 55)
    Stroke.Thickness = 1

    local TopBar = Instance.new("Frame", Main)
    TopBar.Name = "TopBar"
    TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 48)

    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 14)

    local TopFix = Instance.new("Frame", TopBar)
    TopFix.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    TopFix.BorderSizePixel = 0
    TopFix.Position = UDim2.new(0, 0, 0.5, 0)
    TopFix.Size = UDim2.new(1, 0, 0.5, 0)

    local Logo = Instance.new("Frame", TopBar)
    Logo.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
    Logo.BorderSizePixel = 0
    Logo.Position = UDim2.new(0, 16, 0, 12)
    Logo.Size = UDim2.new(0, 20, 0, 20)
    Logo.Rotation = 45
    Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 4)

    local Title = Instance.new("TextLabel", TopBar)
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 48, 0, 10)
    Title.Size = UDim2.new(0, 200, 0, 18)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "CRYSTAL"
    Title.TextColor3 = Color3.fromRGB(200, 200, 210)
    Title.TextSize = 15
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local SubTitle = Instance.new("TextLabel", TopBar)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Position = UDim2.new(0, 48, 0, 26)
    SubTitle.Size = UDim2.new(0, 200, 0, 14)
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.Text = "HUB"
    SubTitle.TextColor3 = Color3.fromRGB(120, 120, 130)
    SubTitle.TextSize = 10
    SubTitle.TextXAlignment = Enum.TextXAlignment.Left

    local Line = Instance.new("Frame", TopBar)
    Line.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    Line.BorderSizePixel = 0
    Line.Position = UDim2.new(0, 48, 0, 24)
    Line.Size = UDim2.new(0, 25, 0, 1)

    local Ver = Instance.new("TextLabel", TopBar)
    Ver.BackgroundTransparency = 1
    Ver.Position = UDim2.new(1, -70, 0, 10)
    Ver.Size = UDim2.new(0, 60, 0, 14)
    Ver.Font = Enum.Font.Gotham
    Ver.Text = CrystalHub.Version
    Ver.TextColor3 = Color3.fromRGB(100, 100, 110)
    Ver.TextSize = 10
    Ver.TextXAlignment = Enum.TextXAlignment.Right

    local CloseBtn = Instance.new("TextButton", TopBar)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Position = UDim2.new(1, -32, 0, 10)
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(120, 120, 130)
    CloseBtn.TextSize = 20

    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 80, 80)}):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(120, 120, 130)}):Play()
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        ESPFolder:Destroy()
        TrajectoryFolder:Destroy()
    end)

    local MinBtn = Instance.new("TextButton", TopBar)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Position = UDim2.new(1, -60, 0, 10)
    MinBtn.Size = UDim2.new(0, 24, 0, 24)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.Text = "−"
    MinBtn.TextColor3 = Color3.fromRGB(120, 120, 130)
    MinBtn.TextSize = 18

    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(Main, TweenInfo.new(0.3), {Size = UDim2.new(0, 500, 0, 48)}):Play()
        else
            TweenService:Create(Main, TweenInfo.new(0.3), {Size = UDim2.new(0, 500, 0, 380)}):Play()
        end
    end)

    local TabPanel = Instance.new("Frame", Main)
    TabPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    TabPanel.BorderSizePixel = 0
    TabPanel.Position = UDim2.new(0, 0, 0, 48)
    TabPanel.Size = UDim2.new(0, 130, 1, -48)

    local TabDiv = Instance.new("Frame", TabPanel)
    TabDiv.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    TabDiv.BorderSizePixel = 0
    TabDiv.Position = UDim2.new(1, -1, 0, 0)
    TabDiv.Size = UDim2.new(0, 1, 1, 0)

    local Content = Instance.new("Frame", Main)
    Content.Name = "Content"
    Content.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    Content.BorderSizePixel = 0
    Content.Position = UDim2.new(0, 130, 0, 48)
    Content.Size = UDim2.new(1, -130, 1, -48)

    local tabs = {}
    local currentTab = nil

    local function CreateTab(name)
        local btn = Instance.new("TextButton", TabPanel)
        btn.Name = name
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Position = UDim2.new(0, 8, 0, 12 + (#tabs * 40))
        btn.Size = UDim2.new(1, -16, 0, 34)
        btn.Font = Enum.Font.Gotham
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(140, 140, 150)
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left

        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local ind = Instance.new("Frame", btn)
        ind.Name = "Indicator"
        ind.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
        ind.BorderSizePixel = 0
        ind.Size = UDim2.new(0, 3, 1, 0)
        ind.BackgroundTransparency = 1

        local page = Instance.new("ScrollingFrame", Content)
        page.Name = name .. "Page"
        page.BackgroundTransparency = 1
        page.Size = UDim2.new(1, -16, 1, -16)
        page.Position = UDim2.new(0, 8, 0, 8)
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Color3.fromRGB(40, 40, 50)
        page.Visible = false
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y

        local layout = Instance.new("UIListLayout", page)
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        table.insert(tabs, {Button = btn, Page = page, Name = name})

        btn.MouseEnter:Connect(function()
            if currentTab ~= name then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if currentTab ~= name then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            end
        end)
        btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(tabs) do
                t.Page.Visible = false
                TweenService:Create(t.Button, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                TweenService:Create(t.Button, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(140, 140, 150)}):Play()
                TweenService:Create(t.Button.Indicator, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            end
            page.Visible = true
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
            TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(200, 200, 210)}):Play()
            TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            currentTab = name
        end)

        if #tabs == 1 then btn.MouseButton1Click:Fire() end
        return page
    end

    local function CreateToggle(parent, text, flag)
        local frame = Instance.new("Frame", parent)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        frame.BorderSizePixel = 0
        frame.Size = UDim2.new(1, 0, 0, 40)
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        Instance.new("UIStroke", frame).Color = Color3.fromRGB(35, 35, 45)

        local label = Instance.new("TextLabel", frame)
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 12, 0, 0)
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.Font = Enum.Font.Gotham
        label.Text = text
        label.TextColor3 = Color3.fromRGB(220, 220, 230)
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left

        local switch = Instance.new("Frame", frame)
        switch.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        switch.BorderSizePixel = 0
        switch.Position = UDim2.new(1, -48, 0.5, -10)
        switch.Size = UDim2.new(0, 36, 0, 18)
        Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame", switch)
        knob.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
        knob.BorderSizePixel = 0
        knob.Position = UDim2.new(0, 2, 0.5, -7)
        knob.Size = UDim2.new(0, 14, 0, 14)
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local enabled = false
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                enabled = not enabled
                CrystalHub.Features[flag] = enabled
                if enabled then
                    TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180, 190, 200)}):Play()
                    TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -16, 0.5, -7)}):Play()
                    TweenService:Create(knob, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(240, 240, 250)}):Play()
                else
                    TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
                    TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -7)}):Play()
                    TweenService:Create(knob, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 120, 130)}):Play()
                end
            end
        end)
        return frame
    end

    local function CreateSlider(parent, text, min, max, default, flag)
        local frame = Instance.new("Frame", parent)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        frame.BorderSizePixel = 0
        frame.Size = UDim2.new(1, 0, 0, 54)
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        Instance.new("UIStroke", frame).Color = Color3.fromRGB(35, 35, 45)

        local label = Instance.new("TextLabel", frame)
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 12, 0, 6)
        label.Size = UDim2.new(0.7, 0, 0, 16)
        label.Font = Enum.Font.Gotham
        label.Text = text
        label.TextColor3 = Color3.fromRGB(220, 220, 230)
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left

        local valLabel = Instance.new("TextLabel", frame)
        valLabel.BackgroundTransparency = 1
        valLabel.Position = UDim2.new(1, -44, 0, 6)
        valLabel.Size = UDim2.new(0, 36, 0, 16)
        valLabel.Font = Enum.Font.GothamBold
        valLabel.Text = tostring(default) .. "x"
        valLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
        valLabel.TextSize = 11
        valLabel.TextXAlignment = Enum.TextXAlignment.Right

        local track = Instance.new("Frame", frame)
        track.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        track.BorderSizePixel = 0
        track.Position = UDim2.new(0, 12, 0, 32)
        track.Size = UDim2.new(1, -24, 0, 4)
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", track)
        fill.BackgroundColor3 = Color3.fromRGB(180, 190, 200)
        fill.BorderSizePixel = 0
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame", track)
        knob.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
        knob.BorderSizePixel = 0
        knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -5)
        knob.Size = UDim2.new(0, 10, 0, 10)
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local dragging = false
        local uis = game:GetService("UserInputService")

        local function update(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = min + (pos * (max - min))
            CrystalHub.Features[flag] = value
            valLabel.Text = string.format("%.1fx", value)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -6, 0.5, -5)
        end

        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        uis.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        uis.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end
        end)
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then update(input) end
        end)

        return frame
    end

    local function CreateLabel(parent, text)
        local frame = Instance.new("Frame", parent)
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, 0, 0, 20)

        local label = Instance.new("TextLabel", frame)
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -16, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.Font = Enum.Font.GothamBold
        label.Text = text
        label.TextColor3 = Color3.fromRGB(180, 190, 200)
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left

        local line = Instance.new("Frame", frame)
        line.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        line.BorderSizePixel = 0
        line.Position = UDim2.new(0, 8, 1, -2)
        line.Size = UDim2.new(0.2, 0, 0, 1)

        return frame
    end

    local VisualTab = CreateTab("Visual")
    local CombatTab = CreateTab("Combat")
    local MiscTab = CreateTab("Misc")

    CreateLabel(VisualTab, "VISUAL FEATURES")
    CreateToggle(VisualTab, "ESP Players", "ESPPlayers")
    CreateToggle(VisualTab, "ESP Ball", "ESPBall")
    CreateToggle(VisualTab, "Ball Trajectory", "BallTrajectory")

    CreateLabel(CombatTab, "COMBAT FEATURES")
    CreateToggle(CombatTab, "Spin Bot", "SpinBot")
    CreateSlider(CombatTab, "Hitbox Multiplier", 1, 3, 1, "HitboxMultiplier")

    CreateLabel(MiscTab, "MOVEMENT FEATURES")
    CreateToggle(MiscTab, "Speed Boost", "SpeedBoost")
    CreateToggle(MiscTab, "Double Jump", "DoubleJump")
    CreateToggle(MiscTab, "Anti Ragdoll", "AntiRagdoll")

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.Insert then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    return ScreenGui
end

for _, p in ipairs(Players:GetPlayers()) do
    CreateESP(p)
end
Players.PlayerAdded:Connect(CreateESP)

CreateBallESP()
CreateTrajectory()

CreateUI()

task.spawn(SpeedBoostLoop)
task.spawn(DoubleJumpLoop)
task.spawn(AntiRagdollLoop)
task.spawn(SpinBotLoop)
task.spawn(HitboxLoop)

game.StarterGui:SetCore("SendNotification", {
    Title = "Crystal Hub",
    Text = CrystalHub.Game .. " | v" .. CrystalHub.Version .. " | Press Insert to toggle",
    Duration = 5,
})
