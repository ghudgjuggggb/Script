local CrystalUI = {}

CrystalUI.Theme = {
    Background = Color3.fromRGB(12, 12, 16),
    Surface = Color3.fromRGB(18, 18, 24),
    SurfaceHover = Color3.fromRGB(28, 28, 36),
    Primary = Color3.fromRGB(200, 200, 210),
    Text = Color3.fromRGB(220, 220, 230),
    TextDim = Color3.fromRGB(140, 140, 150),
    Accent = Color3.fromRGB(160, 170, 180),
    Border = Color3.fromRGB(35, 35, 45),
    BorderActive = Color3.fromRGB(80, 80, 100),
    ToggleOn = Color3.fromRGB(180, 190, 200),
    ToggleOff = Color3.fromRGB(50, 50, 60),
    Success = Color3.fromRGB(140, 200, 160),
    Error = Color3.fromRGB(200, 100, 100),
}

function CrystalUI:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Crystal UI"
    local subtitle = config.SubTitle or "HUB"
    local version = config.Version or "v1.0.0"

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CrystalUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = self.Theme.Background
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -280, 0.5, -200)
    Main.Size = UDim2.new(0, 560, 0, 400)
    Main.Active = true
    Main.Draggable = true
    Main.ClipsDescendants = true

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = self.Theme.Border
    Stroke.Thickness = 1

    local TopBar = Instance.new("Frame", Main)
    TopBar.Name = "TopBar"
    TopBar.BackgroundColor3 = self.Theme.Surface
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 50)

    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 14)

    local TopBarFix = Instance.new("Frame", TopBar)
    TopBarFix.BackgroundColor3 = self.Theme.Surface
    TopBarFix.BorderSizePixel = 0
    TopBarFix.Position = UDim2.new(0, 0, 0.5, 0)
    TopBarFix.Size = UDim2.new(1, 0, 0.5, 0)

    local Logo = Instance.new("Frame", TopBar)
    Logo.Name = "Logo"
    Logo.BackgroundColor3 = self.Theme.Primary
    Logo.BorderSizePixel = 0
    Logo.Position = UDim2.new(0, 18, 0, 13)
    Logo.Size = UDim2.new(0, 22, 0, 22)
    Logo.Rotation = 45

    Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 4)

    local TitleText = Instance.new("TextLabel", TopBar)
    TitleText.Name = "Title"
    TitleText.BackgroundTransparency = 1
    TitleText.Position = UDim2.new(0, 52, 0, 10)
    TitleText.Size = UDim2.new(0, 200, 0, 20)
    TitleText.Font = Enum.Font.GothamBold
    TitleText.Text = string.upper(title)
    TitleText.TextColor3 = self.Theme.Primary
    TitleText.TextSize = 16
    TitleText.TextXAlignment = Enum.TextXAlignment.Left

    local SubText = Instance.new("TextLabel", TopBar)
    SubText.Name = "SubTitle"
    SubText.BackgroundTransparency = 1
    SubText.Position = UDim2.new(0, 52, 0, 28)
    SubText.Size = UDim2.new(0, 200, 0, 14)
    SubText.Font = Enum.Font.Gotham
    SubText.Text = subtitle
    SubText.TextColor3 = self.Theme.TextDim
    SubText.TextSize = 10
    SubText.TextXAlignment = Enum.TextXAlignment.Left

    local Line = Instance.new("Frame", TopBar)
    Line.BackgroundColor3 = self.Theme.Border
    Line.BorderSizePixel = 0
    Line.Position = UDim2.new(0, 52, 0, 26)
    Line.Size = UDim2.new(0, 30, 0, 1)

    local VerText = Instance.new("TextLabel", TopBar)
    VerText.BackgroundTransparency = 1
    VerText.Position = UDim2.new(1, -80, 0, 10)
    VerText.Size = UDim2.new(0, 70, 0, 14)
    VerText.Font = Enum.Font.Gotham
    VerText.Text = version
    VerText.TextColor3 = self.Theme.TextDim
    VerText.TextSize = 10
    VerText.TextXAlignment = Enum.TextXAlignment.Right

    local CloseBtn = Instance.new("TextButton", TopBar)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Position = UDim2.new(1, -35, 0, 12)
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = self.Theme.TextDim
    CloseBtn.TextSize = 20

    CloseBtn.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = self.Theme.Error}):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = self.Theme.TextDim}):Play()
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local MinBtn = Instance.new("TextButton", TopBar)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Position = UDim2.new(1, -65, 0, 12)
    MinBtn.Size = UDim2.new(0, 24, 0, 24)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.Text = "−"
    MinBtn.TextColor3 = self.Theme.TextDim
    MinBtn.TextSize = 18

    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            game:GetService("TweenService"):Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 560, 0, 50)}):Play()
        else
            game:GetService("TweenService"):Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 560, 0, 400)}):Play()
        end
    end)

    local TabPanel = Instance.new("Frame", Main)
    TabPanel.Name = "TabPanel"
    TabPanel.BackgroundColor3 = self.Theme.Surface
    TabPanel.BorderSizePixel = 0
    TabPanel.Position = UDim2.new(0, 0, 0, 50)
    TabPanel.Size = UDim2.new(0, 130, 1, -50)

    local TabDivider = Instance.new("Frame", TabPanel)
    TabDivider.BackgroundColor3 = self.Theme.Border
    TabDivider.BorderSizePixel = 0
    TabDivider.Position = UDim2.new(1, -1, 0, 0)
    TabDivider.Size = UDim2.new(0, 1, 1, 0)

    local ContentPanel = Instance.new("Frame", Main)
    ContentPanel.Name = "Content"
    ContentPanel.BackgroundColor3 = self.Theme.Background
    ContentPanel.BorderSizePixel = 0
    ContentPanel.Position = UDim2.new(0, 130, 0, 50)
    ContentPanel.Size = UDim2.new(1, -130, 1, -50)

    local window = {
        ScreenGui = ScreenGui,
        Main = Main,
        TabPanel = TabPanel,
        ContentPanel = ContentPanel,
        Tabs = {},
        CurrentTab = nil,
    }

    game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.Insert then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    return window
end

function CrystalUI:CreateTab(window, name)
    local tabBtn = Instance.new("TextButton", window.TabPanel)
    tabBtn.Name = name
    tabBtn.BackgroundColor3 = self.Theme.Surface
    tabBtn.BackgroundTransparency = 1
    tabBtn.BorderSizePixel = 0
    tabBtn.Position = UDim2.new(0, 8, 0, 12 + (#window.Tabs * 42))
    tabBtn.Size = UDim2.new(1, -16, 0, 36)
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.Text = name
    tabBtn.TextColor3 = self.Theme.TextDim
    tabBtn.TextSize = 12
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left

    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

    local indicator = Instance.new("Frame", tabBtn)
    indicator.Name = "Indicator"
    indicator.BackgroundColor3 = self.Theme.Primary
    indicator.BorderSizePixel = 0
    indicator.Position = UDim2.new(0, 0, 0, 0)
    indicator.Size = UDim2.new(0, 3, 1, 0)
    indicator.BackgroundTransparency = 1

    local page = Instance.new("ScrollingFrame", window.ContentPanel)
    page.Name = name .. "Page"
    page.BackgroundTransparency = 1
    page.Size = UDim2.new(1, -20, 1, -20)
    page.Position = UDim2.new(0, 10, 0, 10)
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = self.Theme.Border
    page.Visible = false
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    table.insert(window.Tabs, {Button = tabBtn, Page = page, Name = name})

    tabBtn.MouseEnter:Connect(function()
        if window.CurrentTab ~= name then
            game:GetService("TweenService"):Create(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if window.CurrentTab ~= name then
            game:GetService("TweenService"):Create(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end
    end)
    tabBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(window.Tabs) do
            t.Page.Visible = false
            game:GetService("TweenService"):Create(t.Button, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            game:GetService("TweenService"):Create(t.Button, TweenInfo.new(0.2), {TextColor3 = self.Theme.TextDim}):Play()
            game:GetService("TweenService"):Create(t.Button.Indicator, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end
        page.Visible = true
        game:GetService("TweenService"):Create(tabBtn, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.SurfaceHover}):Play()
        game:GetService("TweenService"):Create(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
        game:GetService("TweenService"):Create(tabBtn, TweenInfo.new(0.2), {TextColor3 = self.Theme.Primary}):Play()
        game:GetService("TweenService"):Create(indicator, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        window.CurrentTab = name
    end)

    if #window.Tabs == 1 then
        tabBtn.MouseButton1Click:Fire()
    end

    return page
end

function CrystalUI:CreateToggle(parent, text, callback)
    local frame = Instance.new("Frame", parent)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 42)

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", frame).Color = self.Theme.Border

    local label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 14, 0, 0)
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = self.Theme.Text
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local switch = Instance.new("Frame", frame)
    switch.BackgroundColor3 = self.Theme.ToggleOff
    switch.BorderSizePixel = 0
    switch.Position = UDim2.new(1, -52, 0.5, -10)
    switch.Size = UDim2.new(0, 38, 0, 20)

    Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", switch)
    knob.BackgroundColor3 = self.Theme.TextDim
    knob.BorderSizePixel = 0
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.Size = UDim2.new(0, 16, 0, 16)

    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local enabled = false

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            enabled = not enabled
            local ts = game:GetService("TweenService")
            if enabled then
                ts:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.ToggleOn}):Play()
                ts:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
                ts:Create(knob, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.Primary}):Play()
            else
                ts:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.ToggleOff}):Play()
                ts:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
                ts:Create(knob, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.TextDim}):Play()
            end
            if callback then callback(enabled) end
        end
    end)

    return frame
end

function CrystalUI:CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 58)

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", frame).Color = self.Theme.Border

    local label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 14, 0, 8)
    label.Size = UDim2.new(0.7, 0, 0, 16)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = self.Theme.Text
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valueLabel = Instance.new("TextLabel", frame)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -50, 0, 8)
    valueLabel.Size = UDim2.new(0, 40, 0, 16)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = self.Theme.Primary
    valueLabel.TextSize = 11
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame", frame)
    track.BackgroundColor3 = self.Theme.Border
    track.BorderSizePixel = 0
    track.Position = UDim2.new(0, 14, 0, 36)
    track.Size = UDim2.new(1, -28, 0, 4)

    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = self.Theme.Primary
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)

    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", track)
    knob.BackgroundColor3 = self.Theme.Primary
    knob.BorderSizePixel = 0
    knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
    knob.Size = UDim2.new(0, 12, 0, 12)

    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local value = default
    local uis = game:GetService("UserInputService")

    local function update(input)
        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (pos * (max - min)))
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        knob.Position = UDim2.new(pos, -6, 0.5, -6)
        if callback then callback(value) end
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            update(input)
        end
    end)

    return frame
end

function CrystalUI:CreateButton(parent, text, callback)
    local frame = Instance.new("Frame", parent)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 42)

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = self.Theme.BorderActive
    stroke.Thickness = 1

    local btn = Instance.new("TextButton", frame)
    btn.BackgroundColor3 = self.Theme.Primary
    btn.BackgroundTransparency = 0.9
    btn.BorderSizePixel = 0
    btn.Position = UDim2.new(0, 4, 0, 4)
    btn.Size = UDim2.new(1, -8, 1, -8)
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = self.Theme.Primary
    btn.TextSize = 12

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local ts = game:GetService("TweenService")

    btn.MouseEnter:Connect(function()
        ts:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.7}):Play()
        ts:Create(stroke, TweenInfo.new(0.2), {Color = self.Theme.Primary}):Play()
    end)
    btn.MouseLeave:Connect(function()
        ts:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.9}):Play()
        ts:Create(stroke, TweenInfo.new(0.2), {Color = self.Theme.BorderActive}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        ts:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.5}):Play()
        task.wait(0.1)
        ts:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.7}):Play()
        if callback then callback() end
    end)

    return frame
end

function CrystalUI:CreateDropdown(parent, text, options, callback)
    local frame = Instance.new("Frame", parent)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 42)

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", frame).Color = self.Theme.Border

    local label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 14, 0, 0)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = self.Theme.Text
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local selected = Instance.new("TextButton", frame)
    selected.BackgroundColor3 = self.Theme.SurfaceHover
    selected.BorderSizePixel = 0
    selected.Position = UDim2.new(0.55, 0, 0.2, 0)
    selected.Size = UDim2.new(0.4, -10, 0, 26)
    selected.Font = Enum.Font.Gotham
    selected.Text = options[1] or "Select"
    selected.TextColor3 = self.Theme.Primary
    selected.TextSize = 11

    Instance.new("UICorner", selected).CornerRadius = UDim.new(0, 6)

    local arrow = Instance.new("TextLabel", selected)
    arrow.BackgroundTransparency = 1
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Font = Enum.Font.GothamBold
    arrow.Text = "▼"
    arrow.TextColor3 = self.Theme.TextDim
    arrow.TextSize = 10

    local optsFrame = Instance.new("Frame", frame)
    optsFrame.BackgroundColor3 = self.Theme.SurfaceHover
    optsFrame.BorderSizePixel = 0
    optsFrame.Position = UDim2.new(0.55, 0, 0, 42)
    optsFrame.Size = UDim2.new(0.4, -10, 0, 0)
    optsFrame.Visible = false
    optsFrame.ZIndex = 10

    Instance.new("UICorner", optsFrame).CornerRadius = UDim.new(0, 8)

    local optsLayout = Instance.new("UIListLayout", optsFrame)
    optsLayout.Padding = UDim.new(0, 2)

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton", optsFrame)
        optBtn.BackgroundColor3 = self.Theme.SurfaceHover
        optBtn.BorderSizePixel = 0
        optBtn.Size = UDim2.new(1, 0, 0, 24)
        optBtn.Font = Enum.Font.Gotham
        optBtn.Text = opt
        optBtn.TextColor3 = self.Theme.TextDim
        optBtn.TextSize = 11
        optBtn.ZIndex = 11

        optBtn.MouseEnter:Connect(function()
            game:GetService("TweenService"):Create(optBtn, TweenInfo.new(0.15), {BackgroundColor3 = self.Theme.Surface}):Play()
            game:GetService("TweenService"):Create(optBtn, TweenInfo.new(0.15), {TextColor3 = self.Theme.Primary}):Play()
        end)
        optBtn.MouseLeave:Connect(function()
            game:GetService("TweenService"):Create(optBtn, TweenInfo.new(0.15), {BackgroundColor3 = self.Theme.SurfaceHover}):Play()
            game:GetService("TweenService"):Create(optBtn, TweenInfo.new(0.15), {TextColor3 = self.Theme.TextDim}):Play()
        end)
        optBtn.MouseButton1Click:Connect(function()
            selected.Text = opt
            optsFrame.Visible = false
            optsFrame.Size = UDim2.new(0.4, -10, 0, 0)
            if callback then callback(opt) end
        end)
    end

    selected.MouseButton1Click:Connect(function()
        optsFrame.Visible = not optsFrame.Visible
        if optsFrame.Visible then
            optsFrame.Size = UDim2.new(0.4, -10, 0, math.min(#options * 26, 130))
        else
            optsFrame.Size = UDim2.new(0.4, -10, 0, 0)
        end
    end)

    return frame
end

function CrystalUI:CreateLabel(parent, text)
    local frame = Instance.new("Frame", parent)
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 22)

    local label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = self.Theme.Primary
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local line = Instance.new("Frame", frame)
    line.BackgroundColor3 = self.Theme.BorderActive
    line.BorderSizePixel = 0
    line.Position = UDim2.new(0, 10, 1, -2)
    line.Size = UDim2.new(0.25, 0, 0, 1)

    return frame
end

return CrystalUI
