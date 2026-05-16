local CrystalHub = {
    Version = "1.0.0",
    Name = "Crystal Hub",
    Theme = {
        Background = Color3.fromRGB(5, 5, 8),
        Surface = Color3.fromRGB(12, 12, 18),
        SurfaceLight = Color3.fromRGB(20, 20, 30),
        Primary = Color3.fromRGB(180, 180, 190),
        Crystal = Color3.fromRGB(200, 210, 220),
        CrystalGlow = Color3.fromRGB(220, 230, 240),
        Accent = Color3.fromRGB(160, 170, 180),
        Text = Color3.fromRGB(220, 220, 230),
        TextDim = Color3.fromRGB(140, 140, 150),
        TextDark = Color3.fromRGB(100, 100, 110),
        Border = Color3.fromRGB(40, 40, 50),
        BorderLight = Color3.fromRGB(60, 60, 75),
        Success = Color3.fromRGB(140, 200, 160),
        Error = Color3.fromRGB(200, 100, 100),
        Warning = Color3.fromRGB(200, 180, 120),
        Black = Color3.fromRGB(0, 0, 0),
    },
    Tabs = {},
    CurrentTab = nil,
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local function CreateCrystalUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CrystalHub"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = CrystalHub.Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.Size = UDim2.new(0, 600, 0, 420)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ClipsDescendants = true

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = CrystalHub.Theme.Border
    MainStroke.Thickness = 1.5
    MainStroke.Parent = MainFrame

    local GlowFrame = Instance.new("Frame")
    GlowFrame.Name = "Glow"
    GlowFrame.Parent = MainFrame
    GlowFrame.BackgroundColor3 = CrystalHub.Theme.CrystalGlow
    GlowFrame.BackgroundTransparency = 0.95
    GlowFrame.BorderSizePixel = 0
    GlowFrame.Position = UDim2.new(0, -50, 0, -50)
    GlowFrame.Size = UDim2.new(1, 100, 0, 200)
    GlowFrame.ZIndex = 0

    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(1, 0)
    GlowCorner.Parent = GlowFrame

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = MainFrame
    TopBar.BackgroundColor3 = CrystalHub.Theme.Surface
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 55)
    TopBar.ZIndex = 2

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 16)
    TopBarCorner.Parent = TopBar

    local TopBarBottom = Instance.new("Frame")
    TopBarBottom.Parent = TopBar
    TopBarBottom.BackgroundColor3 = CrystalHub.Theme.Surface
    TopBarBottom.BorderSizePixel = 0
    TopBarBottom.Position = UDim2.new(0, 0, 0.5, 0)
    TopBarBottom.Size = UDim2.new(1, 0, 0.5, 0)
    TopBarBottom.ZIndex = 2

    local LogoFrame = Instance.new("Frame")
    LogoFrame.Name = "Logo"
    LogoFrame.Parent = TopBar
    LogoFrame.BackgroundTransparency = 1
    LogoFrame.Size = UDim2.new(0, 40, 0, 40)
    LogoFrame.Position = UDim2.new(0, 15, 0, 7)
    LogoFrame.ZIndex = 3

    local CrystalIcon = Instance.new("Frame")
    CrystalIcon.Name = "Crystal"
    CrystalIcon.Parent = LogoFrame
    CrystalIcon.BackgroundColor3 = CrystalHub.Theme.Crystal
    CrystalIcon.BorderSizePixel = 0
    CrystalIcon.Position = UDim2.new(0.5, -8, 0.2, 0)
    CrystalIcon.Size = UDim2.new(0, 16, 0, 16)
    CrystalIcon.Rotation = 45
    CrystalIcon.ZIndex = 4

    local CrystalGlow = Instance.new("Frame")
    CrystalGlow.Name = "Glow"
    CrystalGlow.Parent = CrystalIcon
    CrystalGlow.BackgroundColor3 = CrystalHub.Theme.CrystalGlow
    CrystalGlow.BackgroundTransparency = 0.7
    CrystalGlow.BorderSizePixel = 0
    CrystalGlow.Position = UDim2.new(0, -4, 0, -4)
    CrystalGlow.Size = UDim2.new(1, 8, 1, 8)
    CrystalGlow.ZIndex = 3

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Parent = TopBar
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 65, 0, 8)
    TitleLabel.Size = UDim2.new(0, 200, 0, 22)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "CRYSTAL"
    TitleLabel.TextColor3 = CrystalHub.Theme.Crystal
    TitleLabel.TextSize = 18
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 3

    local SubTitleLabel = Instance.new("TextLabel")
    SubTitleLabel.Name = "SubTitle"
    SubTitleLabel.Parent = TopBar
    SubTitleLabel.BackgroundTransparency = 1
    SubTitleLabel.Position = UDim2.new(0, 65, 0, 28)
    SubTitleLabel.Size = UDim2.new(0, 200, 0, 16)
    SubTitleLabel.Font = Enum.Font.Gotham
    SubTitleLabel.Text = "H U B"
    SubTitleLabel.TextColor3 = CrystalHub.Theme.TextDim
    SubTitleLabel.TextSize = 11
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.ZIndex = 3

    local Line = Instance.new("Frame")
    Line.Name = "Line"
    Line.Parent = TopBar
    Line.BackgroundColor3 = CrystalHub.Theme.BorderLight
    Line.BorderSizePixel = 0
    Line.Position = UDim2.new(0, 65, 0, 26)
    Line.Size = UDim2.new(0, 40, 0, 1)
    Line.ZIndex = 3

    local VersionLabel = Instance.new("TextLabel")
    VersionLabel.Name = "Version"
    VersionLabel.Parent = TopBar
    VersionLabel.BackgroundTransparency = 1
    VersionLabel.Position = UDim2.new(1, -80, 0, 10)
    VersionLabel.Size = UDim2.new(0, 70, 0, 16)
    VersionLabel.Font = Enum.Font.Gotham
    VersionLabel.Text = "v" .. CrystalHub.Version
    VersionLabel.TextColor3 = CrystalHub.Theme.TextDark
    VersionLabel.TextSize = 10
    VersionLabel.TextXAlignment = Enum.TextXAlignment.Right
    VersionLabel.ZIndex = 3

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "Close"
    CloseBtn.Parent = TopBar
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Position = UDim2.new(1, -35, 0, 12)
    CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = CrystalHub.Theme.TextDim
    CloseBtn.TextSize = 22
    CloseBtn.ZIndex = 4

    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = CrystalHub.Theme.Error}):Play()
    end)

    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = CrystalHub.Theme.TextDim}):Play()
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        task.wait(0.3)
        ScreenGui:Destroy()
    end)

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "Minimize"
    MinimizeBtn.Parent = TopBar
    MinimizeBtn.BackgroundTransparency = 1
    MinimizeBtn.Position = UDim2.new(1, -65, 0, 12)
    MinimizeBtn.Size = UDim2.new(0, 25, 0, 25)
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.Text = "−"
    MinimizeBtn.TextColor3 = CrystalHub.Theme.TextDim
    MinimizeBtn.TextSize = 20
    MinimizeBtn.ZIndex = 4

    MinimizeBtn.MouseEnter:Connect(function()
        TweenService:Create(MinimizeBtn, TweenInfo.new(0.2), {TextColor3 = CrystalHub.Theme.Crystal}):Play()
    end)

    MinimizeBtn.MouseLeave:Connect(function()
        TweenService:Create(MinimizeBtn, TweenInfo.new(0.2), {TextColor3 = CrystalHub.Theme.TextDim}):Play()
    end)

    local minimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 600, 0, 55)}):Play()
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 600, 0, 420)}):Play()
        end
    end)

    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Parent = MainFrame
    TabContainer.BackgroundColor3 = CrystalHub.Theme.Surface
    TabContainer.BorderSizePixel = 0
    TabContainer.Position = UDim2.new(0, 0, 0, 55)
    TabContainer.Size = UDim2.new(0, 140, 1, -55)
    TabContainer.ZIndex = 2

    local TabContainerTop = Instance.new("Frame")
    TabContainerTop.Parent = TabContainer
    TabContainerTop.BackgroundColor3 = CrystalHub.Theme.Surface
    TabContainerTop.BorderSizePixel = 0
    TabContainerTop.Size = UDim2.new(1, 0, 0, 10)
    TabContainerTop.ZIndex = 2

    local TabDivider = Instance.new("Frame")
    TabDivider.Parent = TabContainer
    TabDivider.BackgroundColor3 = CrystalHub.Theme.Border
    TabDivider.BorderSizePixel = 0
    TabDivider.Position = UDim2.new(1, -1, 0, 0)
    TabDivider.Size = UDim2.new(0, 1, 1, 0)
    TabDivider.ZIndex = 3

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "Content"
    ContentFrame.Parent = MainFrame
    ContentFrame.BackgroundColor3 = CrystalHub.Theme.Background
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Position = UDim2.new(0, 140, 0, 55)
    ContentFrame.Size = UDim2.new(1, -140, 1, -55)
    ContentFrame.ZIndex = 1

    local ContentTopFade = Instance.new("Frame")
    ContentTopFade.Parent = ContentFrame
    ContentTopFade.BackgroundColor3 = CrystalHub.Theme.Background
    ContentTopFade.BorderSizePixel = 0
    ContentTopFade.Size = UDim2.new(1, 0, 0, 10)
    ContentTopFade.ZIndex = 2

    local function CreateTab(name, icon)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name
        TabBtn.Parent = TabContainer
        TabBtn.BackgroundColor3 = CrystalHub.Theme.Surface
        TabBtn.BackgroundTransparency = 1
        TabBtn.BorderSizePixel = 0
        TabBtn.Size = UDim2.new(1, -10, 0, 38)
        TabBtn.Position = UDim2.new(0, 5, 0, 10 + (#CrystalHub.Tabs * 42))
        TabBtn.Font = Enum.Font.Gotham
        TabBtn.Text = "    " .. name
        TabBtn.TextColor3 = CrystalHub.Theme.TextDim
        TabBtn.TextSize = 12
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.ZIndex = 3

        local TabIndicator = Instance.new("Frame")
        TabIndicator.Name = "Indicator"
        TabIndicator.Parent = TabBtn
        TabIndicator.BackgroundColor3 = CrystalHub.Theme.Crystal
        TabIndicator.BorderSizePixel = 0
        TabIndicator.Position = UDim2.new(0, 0, 0, 0)
        TabIndicator.Size = UDim2.new(0, 3, 1, 0)
        TabIndicator.BackgroundTransparency = 1
        TabIndicator.ZIndex = 4

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 8)
        TabCorner.Parent = TabBtn

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = name .. "Page"
        TabPage.Parent = ContentFrame
        TabPage.BackgroundTransparency = 1
        TabPage.Size = UDim2.new(1, -20, 1, -20)
        TabPage.Position = UDim2.new(0, 10, 0, 10)
        TabPage.ScrollBarThickness = 3
        TabPage.ScrollBarImageColor3 = CrystalHub.Theme.BorderLight
        TabPage.Visible = false
        TabPage.ZIndex = 2

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = TabPage
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder

        table.insert(CrystalHub.Tabs, {
            Button = TabBtn,
            Page = TabPage,
            Name = name,
        })

        TabBtn.MouseEnter:Connect(function()
            if CrystalHub.CurrentTab ~= name then
                TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = CrystalHub.Theme.SurfaceLight}):Play()
                TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
            end
        end)

        TabBtn.MouseLeave:Connect(function()
            if CrystalHub.CurrentTab ~= name then
                TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            end
        end)

        TabBtn.MouseButton1Click:Connect(function()
            for _, tab in ipairs(CrystalHub.Tabs) do
                tab.Page.Visible = false
                TweenService:Create(tab.Button, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                TweenService:Create(tab.Button, TweenInfo.new(0.2), {TextColor3 = CrystalHub.Theme.TextDim}):Play()
                TweenService:Create(tab.Button.Indicator, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            end

            TabPage.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = CrystalHub.Theme.SurfaceLight}):Play()
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {TextColor3 = CrystalHub.Theme.Crystal}):Play()
            TweenService:Create(TabIndicator, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()

            CrystalHub.CurrentTab = name
        end)

        return TabPage
    end

    local function CreateToggle(parent, text, callback)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Parent = parent
        ToggleFrame.BackgroundColor3 = CrystalHub.Theme.Surface
        ToggleFrame.BorderSizePixel = 0
        ToggleFrame.Size = UDim2.new(1, 0, 0, 45)

        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 10)
        ToggleCorner.Parent = ToggleFrame

        local ToggleStroke = Instance.new("UIStroke")
        ToggleStroke.Color = CrystalHub.Theme.Border
        ToggleStroke.Thickness = 1
        ToggleStroke.Parent = ToggleFrame

        local Label = Instance.new("TextLabel")
        Label.Parent = ToggleFrame
        Label.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 15, 0, 0)
        Label.Size = UDim2.new(0.6, 0, 1, 0)
        Label.Font = Enum.Font.Gotham
        Label.Text = text
        Label.TextColor3 = CrystalHub.Theme.Text
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left

        local SwitchFrame = Instance.new("Frame")
        SwitchFrame.Parent = ToggleFrame
        SwitchFrame.BackgroundColor3 = CrystalHub.Theme.Border
        SwitchFrame.BorderSizePixel = 0
        SwitchFrame.Position = UDim2.new(1, -55, 0.5, -10)
        SwitchFrame.Size = UDim2.new(0, 40, 0, 20)

        local SwitchCorner = Instance.new("UICorner")
        SwitchCorner.CornerRadius = UDim.new(1, 0)
        SwitchCorner.Parent = SwitchFrame

        local SwitchKnob = Instance.new("Frame")
        SwitchKnob.Parent = SwitchFrame
        SwitchKnob.BackgroundColor3 = CrystalHub.Theme.TextDim
        SwitchKnob.BorderSizePixel = 0
        SwitchKnob.Position = UDim2.new(0, 2, 0.5, -8)
        SwitchKnob.Size = UDim2.new(0, 16, 0, 16)

        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = SwitchKnob

        local enabled = false

        local function Toggle()
            enabled = not enabled
            if enabled then
                TweenService:Create(SwitchFrame, TweenInfo.new(0.2), {BackgroundColor3 = CrystalHub.Theme.Crystal}):Play()
                TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
                TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {BackgroundColor3 = CrystalHub.Theme.CrystalGlow}):Play()
                TweenService:Create(ToggleStroke, TweenInfo.new(0.2), {Color = CrystalHub.Theme.BorderLight}):Play()
            else
                TweenService:Create(SwitchFrame, TweenInfo.new(0.2), {BackgroundColor3 = CrystalHub.Theme.Border}):Play()
                TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
                TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {BackgroundColor3 = CrystalHub.Theme.TextDim}):Play()
                TweenService:Create(ToggleStroke, TweenInfo.new(0.2), {Color = CrystalHub.Theme.Border}):Play()
            end
            if callback then callback(enabled) end
        end

        ToggleFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Toggle()
            end
        end)

        return ToggleFrame, Toggle
    end

    local function CreateSlider(parent, text, min, max, default, callback)
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Parent = parent
        SliderFrame.BackgroundColor3 = CrystalHub.Theme.Surface
        SliderFrame.BorderSizePixel = 0
        SliderFrame.Size = UDim2.new(1, 0, 0, 60)

        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(0, 10)
        SliderCorner.Parent = SliderFrame

        local SliderStroke = Instance.new("UIStroke")
        SliderStroke.Color = CrystalHub.Theme.Border
        SliderStroke.Thickness = 1
        SliderStroke.Parent = SliderFrame

        local Label = Instance.new("TextLabel")
        Label.Parent = SliderFrame
        Label.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 15, 0, 8)
        Label.Size = UDim2.new(0.7, 0, 0, 18)
        Label.Font = Enum.Font.Gotham
        Label.Text = text
        Label.TextColor3 = CrystalHub.Theme.Text
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left

        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Parent = SliderFrame
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Position = UDim2.new(1, -60, 0, 8)
        ValueLabel.Size = UDim2.new(0, 50, 0, 18)
        ValueLabel.Font = Enum.Font.GothamBold
        ValueLabel.Text = tostring(default)
        ValueLabel.TextColor3 = CrystalHub.Theme.Crystal
        ValueLabel.TextSize = 12
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Right

        local Track = Instance.new("Frame")
        Track.Parent = SliderFrame
        Track.BackgroundColor3 = CrystalHub.Theme.Border
        Track.BorderSizePixel = 0
        Track.Position = UDim2.new(0, 15, 0, 38)
        Track.Size = UDim2.new(1, -30, 0, 4)

        local TrackCorner = Instance.new("UICorner")
        TrackCorner.CornerRadius = UDim.new(1, 0)
        TrackCorner.Parent = Track

        local Fill = Instance.new("Frame")
        Fill.Parent = Track
        Fill.BackgroundColor3 = CrystalHub.Theme.Crystal
        Fill.BorderSizePixel = 0
        Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)

        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(1, 0)
        FillCorner.Parent = Fill

        local Knob = Instance.new("Frame")
        Knob.Parent = Track
        Knob.BackgroundColor3 = CrystalHub.Theme.CrystalGlow
        Knob.BorderSizePixel = 0
        Knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
        Knob.Size = UDim2.new(0, 12, 0, 12)

        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob

        local dragging = false
        local value = default

        local function Update(input)
            local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
            value = math.floor(min + (pos * (max - min)))
            ValueLabel.Text = tostring(value)
            Fill.Size = UDim2.new(pos, 0, 1, 0)
            Knob.Position = UDim2.new(pos, -6, 0.5, -6)
            if callback then callback(value) end
        end

        Knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                Update(input)
            end
        end)

        Track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Update(input)
            end
        end)

        return SliderFrame
    end

    local function CreateButton(parent, text, callback)
        local BtnFrame = Instance.new("Frame")
        BtnFrame.Parent = parent
        BtnFrame.BackgroundColor3 = CrystalHub.Theme.Surface
        BtnFrame.BorderSizePixel = 0
        BtnFrame.Size = UDim2.new(1, 0, 0, 45)

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 10)
        BtnCorner.Parent = BtnFrame

        local BtnStroke = Instance.new("UIStroke")
        BtnStroke.Color = CrystalHub.Theme.BorderLight
        BtnStroke.Thickness = 1
        BtnStroke.Parent = BtnFrame

        local Button = Instance.new("TextButton")
        Button.Parent = BtnFrame
        Button.BackgroundColor3 = CrystalHub.Theme.Crystal
        Button.BackgroundTransparency = 0.9
        Button.BorderSizePixel = 0
        Button.Position = UDim2.new(0, 5, 0, 5)
        Button.Size = UDim2.new(1, -10, 1, -10)
        Button.Font = Enum.Font.GothamBold
        Button.Text = text
        Button.TextColor3 = CrystalHub.Theme.Crystal
        Button.TextSize = 13

        local InnerCorner = Instance.new("UICorner")
        InnerCorner.CornerRadius = UDim.new(0, 8)
        InnerCorner.Parent = Button

        Button.MouseEnter:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundTransparency = 0.7}):Play()
            TweenService:Create(BtnStroke, TweenInfo.new(0.2), {Color = CrystalHub.Theme.Crystal}):Play()
        end)

        Button.MouseLeave:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundTransparency = 0.9}):Play()
            TweenService:Create(BtnStroke, TweenInfo.new(0.2), {Color = CrystalHub.Theme.BorderLight}):Play()
        end)

        Button.MouseButton1Click:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundTransparency = 0.5}):Play()
            task.wait(0.1)
            TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundTransparency = 0.7}):Play()
            if callback then callback() end
        end)

        return BtnFrame
    end

    local function CreateDropdown(parent, text, options, callback)
        local DropFrame = Instance.new("Frame")
        DropFrame.Parent = parent
        DropFrame.BackgroundColor3 = CrystalHub.Theme.Surface
        DropFrame.BorderSizePixel = 0
        DropFrame.Size = UDim2.new(1, 0, 0, 45)

        local DropCorner = Instance.new("UICorner")
        DropCorner.CornerRadius = UDim.new(0, 10)
        DropCorner.Parent = DropFrame

        local DropStroke = Instance.new("UIStroke")
        DropStroke.Color = CrystalHub.Theme.Border
        DropStroke.Thickness = 1
        DropStroke.Parent = DropFrame

        local Label = Instance.new("TextLabel")
        Label.Parent = DropFrame
        Label.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 15, 0, 0)
        Label.Size = UDim2.new(0.5, 0, 1, 0)
        Label.Font = Enum.Font.Gotham
        Label.Text = text
        Label.TextColor3 = CrystalHub.Theme.Text
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left

        local Selected = Instance.new("TextButton")
        Selected.Parent = DropFrame
        Selected.BackgroundColor3 = CrystalHub.Theme.SurfaceLight
        Selected.BorderSizePixel = 0
        Selected.Position = UDim2.new(0.55, 0, 0.2, 0)
        Selected.Size = UDim2.new(0.4, -10, 0, 28)
        Selected.Font = Enum.Font.Gotham
        Selected.Text = options[1] or "Select"
        Selected.TextColor3 = CrystalHub.Theme.Crystal
        Selected.TextSize = 12

        local SelCorner = Instance.new("UICorner")
        SelCorner.CornerRadius = UDim.new(0, 6)
        SelCorner.Parent = Selected

        local Arrow = Instance.new("TextLabel")
        Arrow.Parent = Selected
        Arrow.BackgroundTransparency = 1
        Arrow.Position = UDim2.new(1, -20, 0, 0)
        Arrow.Size = UDim2.new(0, 20, 1, 0)
        Arrow.Font = Enum.Font.GothamBold
        Arrow.Text = "▼"
        Arrow.TextColor3 = CrystalHub.Theme.TextDim
        Arrow.TextSize = 10

        local OptionsFrame = Instance.new("Frame")
        OptionsFrame.Parent = DropFrame
        OptionsFrame.BackgroundColor3 = CrystalHub.Theme.SurfaceLight
        OptionsFrame.BorderSizePixel = 0
        OptionsFrame.Position = UDim2.new(0.55, 0, 0, 45)
        OptionsFrame.Size = UDim2.new(0.4, -10, 0, 0)
        OptionsFrame.Visible = false
        OptionsFrame.ZIndex = 10

        local OptCorner = Instance.new("UICorner")
        OptCorner.CornerRadius = UDim.new(0, 8)
        OptCorner.Parent = OptionsFrame

        local OptLayout = Instance.new("UIListLayout")
        OptLayout.Parent = OptionsFrame
        OptLayout.Padding = UDim.new(0, 2)

        for _, opt in ipairs(options) do
            local OptBtn = Instance.new("TextButton")
            OptBtn.Parent = OptionsFrame
            OptBtn.BackgroundColor3 = CrystalHub.Theme.SurfaceLight
            OptBtn.BorderSizePixel = 0
            OptBtn.Size = UDim2.new(1, 0, 0, 26)
            OptBtn.Font = Enum.Font.Gotham
            OptBtn.Text = opt
            OptBtn.TextColor3 = CrystalHub.Theme.TextDim
            OptBtn.TextSize = 11
            OptBtn.ZIndex = 11

            OptBtn.MouseEnter:Connect(function()
                TweenService:Create(OptBtn, TweenInfo.new(0.15), {BackgroundColor3 = CrystalHub.Theme.Surface}):Play()
                TweenService:Create(OptBtn, TweenInfo.new(0.15), {TextColor3 = CrystalHub.Theme.Crystal}):Play()
            end)

            OptBtn.MouseLeave:Connect(function()
                TweenService:Create(OptBtn, TweenInfo.new(0.15), {BackgroundColor3 = CrystalHub.Theme.SurfaceLight}):Play()
                TweenService:Create(OptBtn, TweenInfo.new(0.15), {TextColor3 = CrystalHub.Theme.TextDim}):Play()
            end)

            OptBtn.MouseButton1Click:Connect(function()
                Selected.Text = opt
                OptionsFrame.Visible = false
                OptionsFrame.Size = UDim2.new(0.4, -10, 0, 0)
                if callback then callback(opt) end
            end)
        end

        Selected.MouseButton1Click:Connect(function()
            OptionsFrame.Visible = not OptionsFrame.Visible
            if OptionsFrame.Visible then
                OptionsFrame.Size = UDim2.new(0.4, -10, 0, math.min(#options * 28, 150))
            else
                OptionsFrame.Size = UDim2.new(0.4, -10, 0, 0)
            end
        end)

        return DropFrame
    end

    local function CreateLabel(parent, text)
        local LabelFrame = Instance.new("Frame")
        LabelFrame.Parent = parent
        LabelFrame.BackgroundTransparency = 1
        LabelFrame.Size = UDim2.new(1, 0, 0, 25)

        local Label = Instance.new("TextLabel")
        Label.Parent = LabelFrame
        Label.BackgroundTransparency = 1
        Label.Size = UDim2.new(1, -20, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.Font = Enum.Font.GothamBold
        Label.Text = text
        Label.TextColor3 = CrystalHub.Theme.Crystal
        Label.TextSize = 12
        Label.TextXAlignment = Enum.TextXAlignment.Left

        local Underline = Instance.new("Frame")
        Underline.Parent = LabelFrame
        Underline.BackgroundColor3 = CrystalHub.Theme.BorderLight
        Underline.BorderSizePixel = 0
        Underline.Position = UDim2.new(0, 10, 1, -2)
        Underline.Size = UDim2.new(0.3, 0, 0, 1)

        return LabelFrame
    end

    local MainPage = CreateTab("Main", "")
    local FarmPage = CreateTab("Auto Farm", "")
    local CombatPage = CreateTab("Combat", "")
    local QuestPage = CreateTab("Quests", "")
    local MiscPage = CreateTab("Misc", "")
    local SettingsPage = CreateTab("Settings", "")

    CreateLabel(MainPage, "WELCOME TO CRYSTAL HUB")

    local InfoFrame = Instance.new("Frame")
    InfoFrame.Parent = MainPage
    InfoFrame.BackgroundColor3 = CrystalHub.Theme.Surface
    InfoFrame.BorderSizePixel = 0
    InfoFrame.Size = UDim2.new(1, 0, 0, 80)

    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 10)
    InfoCorner.Parent = InfoFrame

    local InfoStroke = Instance.new("UIStroke")
    InfoStroke.Color = CrystalHub.Theme.Border
    InfoStroke.Thickness = 1
    InfoStroke.Parent = InfoFrame

    local InfoText = Instance.new("TextLabel")
    InfoText.Parent = InfoFrame
    InfoText.BackgroundTransparency = 1
    InfoText.Position = UDim2.new(0, 15, 0, 10)
    InfoText.Size = UDim2.new(1, -30, 1, -20)
    InfoText.Font = Enum.Font.Gotham
    InfoText.Text = "Crystal Hub v" .. CrystalHub.Version .. "\nPremium Roblox Script Hub\nElegant. Powerful. Crystal Clear."
    InfoText.TextColor3 = CrystalHub.Theme.TextDim
    InfoText.TextSize = 12
    InfoText.TextWrapped = true
    InfoText.TextXAlignment = Enum.TextXAlignment.Left
    InfoText.TextYAlignment = Enum.TextYAlignment.Top

    CreateButton(MainPage, "Load Configuration", function()
        print("Crystal Hub: Load Config")
    end)

    CreateButton(MainPage, "Save Configuration", function()
        print("Crystal Hub: Save Config")
    end)

    CreateLabel(FarmPage, "AUTO FARM SETTINGS")

    CreateToggle(FarmPage, "Auto Farm Level", function(v)
        print("Auto Farm:", v)
    end)

    CreateToggle(FarmPage, "Auto Collect Drops", function(v)
        print("Auto Collect:", v)
    end)

    CreateToggle(FarmPage, "Auto Quest Accept", function(v)
        print("Auto Quest:", v)
    end)

    CreateSlider(FarmPage, "Farm Speed", 1, 500, 200, function(v)
        print("Farm Speed:", v)
    end)

    CreateSlider(FarmPage, "Farm Range", 10, 500, 100, function(v)
        print("Farm Range:", v)
    end)

    CreateDropdown(FarmPage, "Farm Mode", {"Nearest", "Lowest HP", "Highest Level", "Boss Only"}, function(v)
        print("Farm Mode:", v)
    end)

    CreateLabel(CombatPage, "COMBAT SETTINGS")

    CreateToggle(CombatPage, "Auto Attack", function(v)
        print("Auto Attack:", v)
    end)

    CreateToggle(CombatPage, "Fast Attack", function(v)
        print("Fast Attack:", v)
    end)

    CreateToggle(CombatPage, "Auto Skills", function(v)
        print("Auto Skills:", v)
    end)

    CreateToggle(CombatPage, "No Cooldown", function(v)
        print("No Cooldown:", v)
    end)

    CreateSlider(CombatPage, "Attack Speed", 1, 100, 50, function(v)
        print("Attack Speed:", v)
    end)

    CreateSlider(CombatPage, "Skill Delay", 0, 5, 1, function(v)
        print("Skill Delay:", v)
    end)

    CreateLabel(QuestPage, "QUEST SETTINGS")

    CreateToggle(QuestPage, "Auto Accept Quests", function(v)
        print("Auto Accept:", v)
    end)

    CreateToggle(QuestPage, "Auto Complete Quests", function(v)
        print("Auto Complete:", v)
    end)

    CreateToggle(QuestPage, "Auto Repeat Quests", function(v)
        print("Auto Repeat:", v)
    end)

    CreateDropdown(QuestPage, "Quest Type", {"All", "Main", "Side", "Daily", "Event"}, function(v)
        print("Quest Type:", v)
    end)

    CreateLabel(MiscPage, "MISCELLANEOUS")

    CreateToggle(MiscPage, "Anti AFK", function(v)
        print("Anti AFK:", v)
    end)

    CreateToggle(MiscPage, "Anti Die", function(v)
        print("Anti Die:", v)
    end)

    CreateToggle(MiscPage, "Auto Respawn", function(v)
        print("Auto Respawn:", v)
    end)

    CreateToggle(MiscPage, "Auto Codes", function(v)
        print("Auto Codes:", v)
    end)

    CreateToggle(MiscPage, "Auto Spins", function(v)
        print("Auto Spins:", v)
    end)

    CreateButton(MiscPage, "Redeem All Codes", function()
        print("Redeeming codes...")
    end)

    CreateLabel(SettingsPage, "UI SETTINGS")

    CreateToggle(SettingsPage, "Show UI Keybind", function(v)
        print("Keybind:", v)
    end)

    CreateSlider(SettingsPage, "UI Transparency", 0, 100, 0, function(v)
        MainFrame.BackgroundTransparency = v / 100
    end)

    CreateButton(SettingsPage, "Reset UI Position", function()
        MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    end)

    CreateButton(SettingsPage, "Destroy UI", function()
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        task.wait(0.3)
        ScreenGui:Destroy()
    end)

    CrystalHub.Tabs[1].Button.MouseButton1Click:Fire()

    local ToggleKey = Enum.KeyCode.Insert
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == ToggleKey then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    local pulse = true
    task.spawn(function()
        while pulse do
            TweenService:Create(GlowFrame, TweenInfo.new(2), {BackgroundTransparency = 0.92}):Play()
            task.wait(2)
            TweenService:Create(GlowFrame, TweenInfo.new(2), {BackgroundTransparency = 0.97}):Play()
            task.wait(2)
        end
    end)

    game.StarterGui:SetCore("SendNotification", {
        Title = "Crystal Hub",
        Text = "v" .. CrystalHub.Version .. " loaded! Press Insert to toggle.",
        Duration = 5,
    })

    return CrystalHub
end

CreateCrystalUI()
