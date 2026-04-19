local RexUi = {}
RexUi.__index = RexUi

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

local function getVP()  return workspace.CurrentCamera.ViewportSize end
local function getScale()
    local w = getVP().X
    if w < 480 then return 0.68
    elseif w < 680 then return 0.82
    elseif w < 960 then return 1.00
    elseif w < 1400 then return 1.12
    else return 1.22 end
end
local function sc(n) return math.round(n * getScale()) end
local function sf(n) return math.round(n * getScale()) end

local T = {
    BG           = Color3.fromRGB(13,  13,  22),
    Sidebar      = Color3.fromRGB(18,  18,  32),
    Card         = Color3.fromRGB(24,  24,  42),
    CardHover    = Color3.fromRGB(32,  32,  58),
    CardActive   = Color3.fromRGB(20,  20,  38),
    Section      = Color3.fromRGB(28,  28,  50),
    TabActive    = Color3.fromRGB(98,  58, 230),
    TabHover     = Color3.fromRGB(35,  35,  62),
    Accent       = Color3.fromRGB(120, 80, 255),
    AccentSoft   = Color3.fromRGB(160,120, 255),
    AccentDim    = Color3.fromRGB( 60, 40, 140),
    SliderFill   = Color3.fromRGB(100, 65, 240),
    ToggleOn     = Color3.fromRGB( 90, 55, 220),
    Border       = Color3.fromRGB( 55, 55,  95),
    BorderAccent = Color3.fromRGB( 90, 60, 200),
    Text         = Color3.fromRGB(230,230, 255),
    SubText      = Color3.fromRGB(140,140, 190),
    Muted        = Color3.fromRGB( 80, 80, 120),
    White        = Color3.fromRGB(255,255, 255),
    Red          = Color3.fromRGB(200, 55,  55),
    Green        = Color3.fromRGB( 60, 200, 100),
    Yellow       = Color3.fromRGB(220, 180,  50),
    Blue         = Color3.fromRGB( 60, 130, 220),
}

local ICON = {
    default   = 10734950309,
    check     = 4483362458,
    star      = 10734950309,
    settings  = 10734959143,
    close     = 10734953654,
    arrow     = 10734950086,
    info      = 10734950309,
    player    = 4483362458,
    sword     = 6031071057,
    shield    = 6031068421,
    eye       = 6026568198,
    zap       = 6026568198,
    lock      = 10734959143,
    globe     = 4483362458,
    bell      = 10734950309,
    heart     = 10734953654,
    target    = 10734950086,
    key       = 10734959143,
    camera    = 6026568198,
    speed     = 10734950086,
    fly       = 6031071057,
    esp       = 6031068421,
    aimbot    = 10734953654,
    misc      = 10734959143,
    bug       = 10734950309,
    trophy    = 10734950309,
    tools     = 10734959143,
    users     = 4483362458,
    money     = 10734950309,
    map       = 10734950309,
    color     = 10734953654,
    edit      = 10734959143,
    trash     = 10734950086,
    refresh   = 4483362458,
    download  = 10734950309,
    upload    = 10734950309,
    home      = 4483362458,
    fire      = 6031071057,
    skull     = 6031068421,
    magic     = 6026568198,
    crosshair = 10734953654,
    radar     = 10734950086,
    input     = 10734959143,
    dropdown  = 10734950086,
    toggle    = 4483362458,
    slider    = 10734950309,
    keybind   = 10734959143,
}

local function tw(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props):Play()
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local function stroke(p, col, thick)
    local s = Instance.new("UIStroke")
    s.Color = col or T.Border
    s.Thickness = thick or 1
    s.Parent = p
    return s
end

local function pad(p, t, b, l, r)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or 6)
    u.PaddingBottom = UDim.new(0, b or 6)
    u.PaddingLeft   = UDim.new(0, l or 8)
    u.PaddingRight  = UDim.new(0, r or 8)
    u.Parent = p
end

local function listLayout(p, spacing, dir)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, spacing or 5)
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.Parent = p
    return l
end

local function imgLabel(parent, id, sz, pos, col)
    local i = Instance.new("ImageLabel")
    i.Size = sz or UDim2.new(0, 18, 0, 18)
    i.Position = pos or UDim2.new(0, 10, 0.5, -9)
    i.BackgroundTransparency = 1
    i.Image = id and ("rbxassetid://" .. tostring(id)) or ""
    i.ImageColor3 = col or T.Accent
    i.ScaleType = Enum.ScaleType.Fit
    i.Parent = parent
    return i
end

local notifParent = nil
local notifCount  = 0

local function getNotifParent()
    if notifParent and notifParent.Parent then return notifParent end
    local sg = Instance.new("ScreenGui")
    sg.Name = "RexUi_Notifs"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 1000
    sg.Parent = (typeof(gethui) == "function" and gethui()) or PlayerGui
    notifParent = sg
    return sg
end

local function Notify(opts)
    opts = opts or {}
    local sg = getNotifParent()
    notifCount = notifCount + 1
    local idx = notifCount
    local S = getScale()
    local nW = sc(290)
    local nH = sc(72)
    local gap = sc(82)
    local accentCol = opts.Color or T.Accent

    local nf = Instance.new("Frame")
    nf.Name = "Notif_" .. idx
    nf.Size = UDim2.new(0, nW, 0, nH)
    nf.Position = UDim2.new(1, 12, 1, -(idx * gap + 10))
    nf.BackgroundColor3 = T.Card
    nf.Parent = sg
    corner(nf, sc(10))
    stroke(nf, accentCol, 1.5)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, -sc(16))
    bar.Position = UDim2.new(0, sc(8), 0, sc(8))
    bar.BackgroundColor3 = accentCol
    bar.BorderSizePixel = 0
    bar.Parent = nf
    corner(bar, 3)

    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(0, sc(18), 1, -sc(16))
    glow.Position = UDim2.new(0, sc(5), 0, sc(8))
    glow.BackgroundColor3 = accentCol
    glow.BackgroundTransparency = 0.85
    glow.BorderSizePixel = 0
    glow.Parent = nf
    corner(glow, sc(8))

    imgLabel(nf, opts.Image or ICON.bell,
        UDim2.new(0, sc(22), 0, sc(22)),
        UDim2.new(0, sc(18), 0.5, -sc(11)),
        T.AccentSoft)

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -sc(52), 0, sc(22))
    tl.Position = UDim2.new(0, sc(48), 0, sc(10))
    tl.BackgroundTransparency = 1
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = sf(13)
    tl.TextColor3 = T.Text
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.Text = opts.Title or "RexUi"
    tl.Parent = nf

    local cl = Instance.new("TextLabel")
    cl.Size = UDim2.new(1, -sc(52), 0, sc(30))
    cl.Position = UDim2.new(0, sc(48), 0, sc(32))
    cl.BackgroundTransparency = 1
    cl.Font = Enum.Font.Gotham
    cl.TextSize = sf(11)
    cl.TextColor3 = T.SubText
    cl.TextXAlignment = Enum.TextXAlignment.Left
    cl.TextWrapped = true
    cl.Text = opts.Content or ""
    cl.Parent = nf

    local prog = Instance.new("Frame")
    prog.Size = UDim2.new(1, -sc(20), 0, 2)
    prog.Position = UDim2.new(0, sc(10), 1, -6)
    prog.BackgroundColor3 = accentCol
    prog.BorderSizePixel = 0
    prog.Parent = nf
    corner(prog, 1)

    local xBtn = Instance.new("TextButton")
    xBtn.Size = UDim2.new(0, sc(20), 0, sc(20))
    xBtn.Position = UDim2.new(1, -sc(26), 0, sc(6))
    xBtn.BackgroundTransparency = 1
    xBtn.Font = Enum.Font.GothamBold
    xBtn.TextSize = sf(11)
    xBtn.TextColor3 = T.Muted
    xBtn.Text = "✕"
    xBtn.Parent = nf

    local function dismissNotif()
        tw(nf, {Position = UDim2.new(1, 12, 1, -(idx * gap + 10))}, 0.3)
        task.wait(0.35)
        pcall(function() nf:Destroy() end)
        notifCount = math.max(0, notifCount - 1)
    end

    xBtn.MouseButton1Click:Connect(dismissNotif)
    xBtn.TouchTap:Connect(dismissNotif)

    tw(nf, {Position = UDim2.new(1, -(nW + 10), 1, -(idx * gap + 10))}, 0.4, Enum.EasingStyle.Back)
    tw(prog, {Size = UDim2.new(0, 0, 0, 2)}, (opts.Duration or 4) - 0.4)

    task.delay(opts.Duration or 4, function()
        tw(nf, {Position = UDim2.new(1, 12, 1, -(idx * gap + 10))}, 0.3)
        task.wait(0.35)
        pcall(function() nf:Destroy() end)
        notifCount = math.max(0, notifCount - 1)
    end)
end

function RexUi:CreateWindow(config)
    config = config or {}
    local win = setmetatable({}, RexUi)
    win.Tabs      = {}
    win.ActiveTab = nil
    win.Flags     = {}
    win._notify   = Notify

    local S      = getScale()
    local winW   = sc(590)
    local winH   = sc(390)
    local sideW  = sc(150)
    local titleH = sc(48)
    local btnSz  = sc(28)

    local sg = Instance.new("ScreenGui")
    sg.Name = "RexUi_" .. (config.Name or "Window")
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 100
    sg.Parent = (typeof(gethui) == "function" and gethui()) or PlayerGui

    local shadowImg = Instance.new("ImageLabel")
    shadowImg.AnchorPoint = Vector2.new(0.5, 0.5)
    shadowImg.Size = UDim2.new(0, winW + sc(50), 0, winH + sc(40))
    shadowImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadowImg.BackgroundTransparency = 1
    shadowImg.Image = "rbxassetid://6014261993"
    shadowImg.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadowImg.ImageTransparency = 0.55
    shadowImg.ScaleType = Enum.ScaleType.Slice
    shadowImg.SliceCenter = Rect.new(49, 49, 450, 450)
    shadowImg.ZIndex = 0
    shadowImg.Parent = sg

    local main = Instance.new("Frame")
    main.Name = "RexMain"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Size = UDim2.new(0, winW, 0, winH)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.BackgroundColor3 = T.BG
    main.ClipsDescendants = true
    main.ZIndex = 1
    main.Parent = sg
    corner(main, sc(14))
    stroke(main, T.Border, 1.5)

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, titleH)
    titleBar.BackgroundColor3 = T.Sidebar
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 2
    titleBar.Parent = main

    local tg = Instance.new("UIGradient")
    tg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(100, 60, 220)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(55,  35, 145)),
        ColorSequenceKeypoint.new(1.00, T.Sidebar),
    })
    tg.Parent = titleBar

    local logoSz = sc(26)
    imgLabel(titleBar, config.Icon or ICON.star,
        UDim2.new(0, logoSz, 0, logoSz),
        UDim2.new(0, sc(12), 0.5, -math.round(logoSz / 2)),
        Color3.fromRGB(200, 170, 255))

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0, sc(200), 0, sc(22))
    nameLbl.Position = UDim2.new(0, sc(46), 0, sc(6))
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = sf(15)
    nameLbl.TextColor3 = T.Text
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Text = config.Name or "RexUi"
    nameLbl.Parent = titleBar

    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(0, sc(260), 0, sc(16))
    subLbl.Position = UDim2.new(0, sc(46), 0, sc(27))
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.Gotham
    subLbl.TextSize = sf(10)
    subLbl.TextColor3 = T.SubText
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.Text = config.LoadingSubtitle or ""
    subLbl.Parent = titleBar

    if config.Version then
        local ver = Instance.new("TextLabel")
        ver.Size = UDim2.new(0, sc(50), 0, sc(16))
        ver.Position = UDim2.new(0, sc(46 + 95), 0, sc(10))
        ver.BackgroundColor3 = T.AccentDim
        ver.Font = Enum.Font.GothamBold
        ver.TextSize = sf(9)
        ver.TextColor3 = T.AccentSoft
        ver.Text = config.Version
        ver.Parent = titleBar
        corner(ver, 4)
    end

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, btnSz, 0, btnSz)
    closeBtn.Position = UDim2.new(1, -sc(36), 0.5, -math.round(btnSz / 2))
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = sf(13)
    closeBtn.TextColor3 = T.White
    closeBtn.Text = "✕"
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = titleBar
    corner(closeBtn, 6)

    local function doClose()
        tw(main, {Size = UDim2.new(0, winW, 0, 0), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quad)
        task.wait(0.35)
        sg:Destroy()
    end
    closeBtn.MouseEnter:Connect(function() tw(closeBtn, {BackgroundColor3 = Color3.fromRGB(220, 70, 70)}, 0.1) end)
    closeBtn.MouseLeave:Connect(function() tw(closeBtn, {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}, 0.1) end)
    closeBtn.MouseButton1Click:Connect(doClose)
    closeBtn.TouchTap:Connect(doClose)

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, btnSz, 0, btnSz)
    minBtn.Position = UDim2.new(1, -sc(70), 0.5, -math.round(btnSz / 2))
    minBtn.BackgroundColor3 = T.Section
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = sf(16)
    minBtn.TextColor3 = T.SubText
    minBtn.Text = "─"
    minBtn.AutoButtonColor = false
    minBtn.Parent = titleBar
    corner(minBtn, 6)
    stroke(minBtn, T.Border, 1)

    local isMin = false
    local function doMin()
        isMin = not isMin
        if isMin then
            tw(main, {Size = UDim2.new(0, winW, 0, titleH)}, 0.3, Enum.EasingStyle.Quad)
            minBtn.Text = "□"
        else
            tw(main, {Size = UDim2.new(0, winW, 0, winH)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            minBtn.Text = "─"
        end
    end
    minBtn.MouseButton1Click:Connect(doMin)
    minBtn.TouchTap:Connect(doMin)

    local drag, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true
            dragStart = inp.Position
            startPos  = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
            shadowImg.Position = main.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -titleH)
    content.Position = UDim2.new(0, 0, 0, titleH)
    content.BackgroundTransparency = 1
    content.Parent = main

    local sidebar = Instance.new("ScrollingFrame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, sideW, 1, 0)
    sidebar.BackgroundColor3 = T.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.ScrollBarThickness = 0
    sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sidebar.Parent = content
    stroke(sidebar, T.Border, 1)

    local sbHeader = Instance.new("TextLabel")
    sbHeader.Size = UDim2.new(1, 0, 0, sc(28))
    sbHeader.BackgroundTransparency = 1
    sbHeader.Font = Enum.Font.GothamBold
    sbHeader.TextSize = sf(9)
    sbHeader.TextColor3 = T.Muted
    sbHeader.Text = "NAVIGATION"
    sbHeader.LetterSpacing = 2
    sbHeader.Parent = sidebar

    local sbList = Instance.new("UIListLayout")
    sbList.Padding = UDim.new(0, 3)
    sbList.SortOrder = Enum.SortOrder.LayoutOrder
    sbList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sbList.Parent = sidebar

    local sbPad = Instance.new("UIPadding")
    sbPad.PaddingTop   = UDim.new(0, 6)
    sbPad.PaddingLeft  = UDim.new(0, 7)
    sbPad.PaddingRight = UDim.new(0, 7)
    sbPad.Parent = sidebar

    local sbInfo = Instance.new("TextLabel")
    sbInfo.Size = UDim2.new(1, 0, 0, sc(20))
    sbInfo.Position = UDim2.new(0, 0, 1, -sc(24))
    sbInfo.BackgroundTransparency = 1
    sbInfo.Font = Enum.Font.Gotham
    sbInfo.TextSize = sf(9)
    sbInfo.TextColor3 = T.Muted
    sbInfo.Text = "RexUi v2.0"
    sbInfo.Parent = content

    local pageArea = Instance.new("Frame")
    pageArea.Name = "PageArea"
    pageArea.Size = UDim2.new(1, -sideW, 1, 0)
    pageArea.Position = UDim2.new(0, sideW, 0, 0)
    pageArea.BackgroundTransparency = 1
    pageArea.ClipsDescendants = true
    pageArea.Parent = content

    win._sg       = sg
    win._main     = main
    win._sidebar  = sidebar
    win._sbList   = sbList
    win._pageArea = pageArea
    win._winW     = winW
    win._winH     = winH
    win._titleH   = titleH
    win._sideW    = sideW

    main.Size = UDim2.new(0, winW, 0, 0)
    tw(main, {Size = UDim2.new(0, winW, 0, winH)}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    function win:GetFlag(f) return self.Flags[f] end
    function win:Notify(o) Notify(o) end

    return win
end

function RexUi:_activate(tab)
    if self.ActiveTab and self.ActiveTab ~= tab then
        local p = self.ActiveTab
        tw(p._btn,       {BackgroundColor3 = T.Card},    0.18)
        tw(p._btnLabel,  {TextColor3 = T.SubText},       0.18)
        tw(p._btnIcon,   {ImageColor3 = T.SubText},      0.18)
        tw(p._indicator, {BackgroundTransparency = 1, Size = UDim2.new(0, 3, 0, 0)}, 0.18)
        p._page.Visible = false
    end
    self.ActiveTab = tab
    tw(tab._btn,       {BackgroundColor3 = T.TabActive}, 0.18)
    tw(tab._btnLabel,  {TextColor3 = T.White},           0.18)
    tw(tab._btnIcon,   {ImageColor3 = T.White},          0.18)
    tw(tab._indicator, {BackgroundTransparency = 0, Size = UDim2.new(0, 3, 0.65, 0)}, 0.22, Enum.EasingStyle.Back)
    tab._page.Visible = true
end

function RexUi:CreateTab(name, iconId)
    local tab    = {}
    tab._window  = self

    local btnH   = sc(38)
    local icoSz  = sc(16)

    local btn = Instance.new("TextButton")
    btn.Name = "Tab_" .. name
    btn.Size = UDim2.new(1, 0, 0, btnH)
    btn.BackgroundColor3 = T.Card
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = self._sidebar
    corner(btn, 8)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0, 0)
    indicator.Position = UDim2.new(0, 0, 0.175, 0)
    indicator.BackgroundColor3 = T.AccentSoft
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel = 0
    indicator.Parent = btn
    corner(indicator, 3)

    local bIcon = imgLabel(btn, iconId or ICON.default,
        UDim2.new(0, icoSz, 0, icoSz),
        UDim2.new(0, sc(10), 0.5, -math.round(icoSz / 2)),
        T.SubText)

    local bLabel = Instance.new("TextLabel")
    bLabel.Size = UDim2.new(1, -sc(32), 1, 0)
    bLabel.Position = UDim2.new(0, sc(30), 0, 0)
    bLabel.BackgroundTransparency = 1
    bLabel.Font = Enum.Font.GothamSemibold
    bLabel.TextSize = sf(12)
    bLabel.TextColor3 = T.SubText
    bLabel.TextXAlignment = Enum.TextXAlignment.Left
    bLabel.TextTruncate = Enum.TextTruncate.AtEnd
    bLabel.Text = name
    bLabel.Parent = btn

    tab._btn       = btn
    tab._btnIcon   = bIcon
    tab._btnLabel  = bLabel
    tab._indicator = indicator

    btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tw(btn,   {BackgroundColor3 = T.TabHover},  0.12)
            tw(bIcon, {ImageColor3 = T.AccentSoft},     0.12)
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tw(btn,   {BackgroundColor3 = T.Card},    0.12)
            tw(bIcon, {ImageColor3 = T.SubText},      0.12)
        end
    end)
    btn.MouseButton1Click:Connect(function() self:_activate(tab) end)
    btn.TouchTap:Connect(function() self:_activate(tab) end)

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "_Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = T.Accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = self._pageArea
    listLayout(page, 5)
    pad(page, 8, 10, 8, 8)

    tab._page = page

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then self:_activate(tab) end

    function tab:CreateSection(title)
        local sec = Instance.new("Frame")
        sec.Size = UDim2.new(1, -6, 0, sc(24))
        sec.BackgroundColor3 = T.Section
        sec.Parent = self._page
        corner(sec, 6)

        local l1 = Instance.new("Frame")
        l1.Size = UDim2.new(0.28, 0, 0, 1)
        l1.Position = UDim2.new(0, 8, 0.5, 0)
        l1.BackgroundColor3 = T.Border
        l1.BorderSizePixel = 0
        l1.Parent = sec

        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(0.44, 0, 1, 0)
        tl.Position = UDim2.new(0.28, 0, 0, 0)
        tl.BackgroundTransparency = 1
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = sf(9)
        tl.TextColor3 = T.SubText
        tl.Text = title:upper()
        tl.LetterSpacing = 1
        tl.Parent = sec

        local l2 = Instance.new("Frame")
        l2.Size = UDim2.new(0.28, -8, 0, 1)
        l2.Position = UDim2.new(0.72, 0, 0.5, 0)
        l2.BackgroundColor3 = T.Border
        l2.BorderSizePixel = 0
        l2.Parent = sec
    end

    function tab:CreateLabel(text)
        local lf = Instance.new("Frame")
        lf.Size = UDim2.new(1, -6, 0, sc(20))
        lf.BackgroundTransparency = 1
        lf.Parent = self._page

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = sf(11)
        lbl.TextColor3 = T.SubText
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextWrapped = true
        lbl.Text = text or ""
        lbl.Parent = lf
        pad(lbl, 0, 0, 4, 4)

        local obj = {}
        function obj:Set(t)
            lbl.Text = t
            lf.Size = UDim2.new(1, -6, 0, math.max(sc(20), lbl.TextBounds.Y + 4))
        end
        return obj
    end

    function tab:CreateButton(opts)
        opts = opts or {}
        local hasDesc = opts.Description and opts.Description ~= ""
        local cardH   = hasDesc and sc(52) or sc(40)

        local card = Instance.new("TextButton")
        card.Size = UDim2.new(1, -6, 0, cardH)
        card.BackgroundColor3 = T.Card
        card.Text = ""
        card.AutoButtonColor = false
        card.Parent = self._page
        corner(card, 9)
        stroke(card, T.Border, 1)

        local strip = Instance.new("Frame")
        strip.Size = UDim2.new(0, 3, 0.6, 0)
        strip.Position = UDim2.new(0, 0, 0.2, 0)
        strip.BackgroundColor3 = T.Accent
        strip.BackgroundTransparency = 0.6
        strip.BorderSizePixel = 0
        strip.Parent = card
        corner(strip, 3)

        local icoSz2 = sc(18)
        local ic = imgLabel(card, opts.Icon or ICON.arrow,
            UDim2.new(0, icoSz2, 0, icoSz2),
            UDim2.new(0, sc(12), 0.5, -math.round(icoSz2 / 2)),
            T.Accent)

        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(1, -sc(52), 0, sc(22))
        nl.Position = UDim2.new(0, sc(36), 0, sc(hasDesc and 6 or 0))
        nl.AnchorPoint = hasDesc and Vector2.new(0, 0) or Vector2.new(0, 0)
        if not hasDesc then
            nl.Size = UDim2.new(1, -sc(52), 1, 0)
            nl.Position = UDim2.new(0, sc(36), 0, 0)
        end
        nl.BackgroundTransparency = 1
        nl.Font = Enum.Font.GothamSemibold
        nl.TextSize = sf(13)
        nl.TextColor3 = T.Text
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Text = opts.Name or "Button"
        nl.Parent = card

        if hasDesc then
            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(1, -sc(52), 0, sc(16))
            desc.Position = UDim2.new(0, sc(36), 0, sc(28))
            desc.BackgroundTransparency = 1
            desc.Font = Enum.Font.Gotham
            desc.TextSize = sf(10)
            desc.TextColor3 = T.Muted
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Text = opts.Description
            desc.Parent = card
        end

        local chev = Instance.new("TextLabel")
        chev.Size = UDim2.new(0, sc(20), 1, 0)
        chev.Position = UDim2.new(1, -sc(24), 0, 0)
        chev.BackgroundTransparency = 1
        chev.Font = Enum.Font.GothamBold
        chev.TextSize = sf(16)
        chev.TextColor3 = T.Muted
        chev.Text = "›"
        chev.Parent = card

        local function doClick()
            if opts.Callback then pcall(opts.Callback) end
        end
        card.MouseEnter:Connect(function()
            tw(card,  {BackgroundColor3 = T.CardHover},    0.12)
            tw(strip, {BackgroundTransparency = 0.2},      0.12)
            tw(ic,    {ImageColor3 = T.AccentSoft},        0.12)
            tw(chev,  {TextColor3 = T.AccentSoft},         0.12)
        end)
        card.MouseLeave:Connect(function()
            tw(card,  {BackgroundColor3 = T.Card},         0.12)
            tw(strip, {BackgroundTransparency = 0.6},      0.12)
            tw(ic,    {ImageColor3 = T.Accent},            0.12)
            tw(chev,  {TextColor3 = T.Muted},              0.12)
        end)
        card.MouseButton1Down:Connect(function() tw(card, {BackgroundColor3 = T.CardActive}, 0.08) end)
        card.MouseButton1Up:Connect(function()   tw(card, {BackgroundColor3 = T.CardHover},  0.08) end)
        card.MouseButton1Click:Connect(doClick)
        card.TouchTap:Connect(doClick)
    end

    function tab:CreateToggle(opts)
        opts = opts or {}
        local val = opts.CurrentValue == true

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -6, 0, sc(40))
        card.BackgroundColor3 = val and T.CardHover or T.Card
        card.Parent = self._page
        corner(card, 9)
        stroke(card, T.Border, 1)

        local icoSz2 = sc(18)
        local ic = imgLabel(card, opts.Icon or ICON.check,
            UDim2.new(0, icoSz2, 0, icoSz2),
            UDim2.new(0, sc(12), 0.5, -math.round(icoSz2 / 2)),
            val and T.Accent or T.SubText)

        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(1, -sc(90), 1, 0)
        nl.Position = UDim2.new(0, sc(36), 0, 0)
        nl.BackgroundTransparency = 1
        nl.Font = Enum.Font.GothamSemibold
        nl.TextSize = sf(13)
        nl.TextColor3 = T.Text
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Text = opts.Name or "Toggle"
        nl.Parent = card

        local pillW  = sc(44)
        local pillH  = sc(24)
        local knobSz = sc(18)
        local pill = Instance.new("Frame")
        pill.Size = UDim2.new(0, pillW, 0, pillH)
        pill.Position = UDim2.new(1, -sc(52), 0.5, -math.round(pillH / 2))
        pill.BackgroundColor3 = val and T.ToggleOn or T.Section
        pill.Parent = card
        corner(pill, math.round(pillH / 2))
        stroke(pill, T.Border, 1)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, knobSz, 0, knobSz)
        knob.Position = val
            and UDim2.new(1, -sc(21), 0.5, -math.round(knobSz / 2))
            or  UDim2.new(0,  3,      0.5, -math.round(knobSz / 2))
        knob.BackgroundColor3 = T.White
        knob.Parent = pill
        corner(knob, math.round(knobSz / 2))

        local knobGlow = Instance.new("UIStroke")
        knobGlow.Color = T.AccentSoft
        knobGlow.Thickness = val and 1.5 or 0
        knobGlow.Parent = knob

        local function setToggle(newVal)
            val = newVal
            tw(pill, {BackgroundColor3 = val and T.ToggleOn or T.Section}, 0.2)
            tw(knob, {Position = val
                and UDim2.new(1, -sc(21), 0.5, -math.round(knobSz / 2))
                or  UDim2.new(0,  3,      0.5, -math.round(knobSz / 2))}, 0.22, Enum.EasingStyle.Back)
            tw(ic,   {ImageColor3 = val and T.Accent or T.SubText}, 0.2)
            tw(card, {BackgroundColor3 = val and T.CardHover or T.Card}, 0.2)
            knobGlow.Thickness = val and 1.5 or 0
            if opts.Flag then tab._window.Flags[opts.Flag] = val end
            if opts.Callback then pcall(opts.Callback, val) end
        end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = card
        btn.MouseButton1Click:Connect(function() setToggle(not val) end)
        btn.TouchTap:Connect(function() setToggle(not val) end)

        if opts.Flag then tab._window.Flags[opts.Flag] = val end
        if val and opts.Callback then pcall(opts.Callback, val) end
    end

    function tab:CreateSlider(opts)
        opts = opts or {}
        local minV   = (opts.Range and opts.Range[1]) or 0
        local maxV   = (opts.Range and opts.Range[2]) or 100
        local inc    = opts.Increment or 1
        local val    = opts.CurrentValue or minV
        local suffix = opts.Suffix or ""

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -6, 0, sc(54))
        card.BackgroundColor3 = T.Card
        card.Parent = self._page
        corner(card, 9)
        stroke(card, T.Border, 1)

        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(0.6, 0, 0, sc(24))
        nl.Position = UDim2.new(0, sc(12), 0, sc(5))
        nl.BackgroundTransparency = 1
        nl.Font = Enum.Font.GothamSemibold
        nl.TextSize = sf(13)
        nl.TextColor3 = T.Text
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Text = opts.Name or "Slider"
        nl.Parent = card

        local vl = Instance.new("TextLabel")
        vl.Size = UDim2.new(0.4, -12, 0, sc(24))
        vl.Position = UDim2.new(0.6, 0, 0, sc(5))
        vl.BackgroundTransparency = 1
        vl.Font = Enum.Font.GothamBold
        vl.TextSize = sf(13)
        vl.TextColor3 = T.Accent
        vl.TextXAlignment = Enum.TextXAlignment.Right
        vl.Text = tostring(val) .. suffix
        vl.Parent = card

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -sc(24), 0, sc(6))
        track.Position = UDim2.new(0, sc(12), 0, sc(36))
        track.BackgroundColor3 = T.Section
        track.Parent = card
        corner(track, 3)

        local pct0 = (val - minV) / (maxV - minV)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(pct0, 0, 1, 0)
        fill.BackgroundColor3 = T.SliderFill
        fill.Parent = track
        corner(fill, 3)

        local fg = Instance.new("UIGradient")
        fg.Color = ColorSequence.new(T.Accent, Color3.fromRGB(170, 120, 255))
        fg.Parent = fill

        local thumbSz = sc(16)
        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.new(0, thumbSz, 0, thumbSz)
        thumb.Position = UDim2.new(pct0, -math.round(thumbSz / 2), 0.5, -math.round(thumbSz / 2))
        thumb.BackgroundColor3 = T.White
        thumb.ZIndex = 2
        thumb.Parent = track
        corner(thumb, math.round(thumbSz / 2))
        stroke(thumb, T.Accent, 2)

        local function applyVal(v)
            v = math.clamp(math.round(v / inc) * inc, minV, maxV)
            val = v
            local p = (v - minV) / (maxV - minV)
            tw(fill,  {Size     = UDim2.new(p, 0, 1, 0)},                                     0.08)
            tw(thumb, {Position = UDim2.new(p, -math.round(thumbSz / 2), 0.5, -math.round(thumbSz / 2))}, 0.08)
            vl.Text = tostring(v) .. suffix
            if opts.Flag then tab._window.Flags[opts.Flag] = v end
            if opts.Callback then pcall(opts.Callback, v) end
        end

        local sliding = false
        local function startSlide(inp)
            sliding = true
            local p = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            applyVal(minV + (maxV - minV) * p)
        end
        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                startSlide(i)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
                local p = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                applyVal(minV + (maxV - minV) * p)
            end
        end)

        if opts.Flag then tab._window.Flags[opts.Flag] = val end
        if opts.Callback then pcall(opts.Callback, val) end
    end

    function tab:CreateKeybind(opts)
        opts = opts or {}
        local key      = opts.CurrentKeybind and Enum.KeyCode[opts.CurrentKeybind] or Enum.KeyCode.RightShift
        local listening = false

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -6, 0, sc(40))
        card.BackgroundColor3 = T.Card
        card.Parent = self._page
        corner(card, 9)
        stroke(card, T.Border, 1)

        local icoSz2 = sc(18)
        imgLabel(card, opts.Icon or ICON.keybind,
            UDim2.new(0, icoSz2, 0, icoSz2),
            UDim2.new(0, sc(12), 0.5, -math.round(icoSz2 / 2)),
            T.SubText)

        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(0.6, 0, 1, 0)
        nl.Position = UDim2.new(0, sc(36), 0, 0)
        nl.BackgroundTransparency = 1
        nl.Font = Enum.Font.GothamSemibold
        nl.TextSize = sf(13)
        nl.TextColor3 = T.Text
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Text = opts.Name or "Keybind"
        nl.Parent = card

        local keyBtnW = sc(70)
        local keyBtnH = sc(26)
        local keyBtn  = Instance.new("TextButton")
        keyBtn.Size = UDim2.new(0, keyBtnW, 0, keyBtnH)
        keyBtn.Position = UDim2.new(1, -sc(78), 0.5, -math.round(keyBtnH / 2))
        keyBtn.BackgroundColor3 = T.Section
        keyBtn.Font = Enum.Font.GothamBold
        keyBtn.TextSize = sf(11)
        keyBtn.TextColor3 = T.Accent
        keyBtn.Text = key.Name
        keyBtn.AutoButtonColor = false
        keyBtn.Parent = card
        corner(keyBtn, 6)
        stroke(keyBtn, T.BorderAccent, 1)

        local function toggleListen()
            listening = not listening
            if listening then
                keyBtn.Text = "..."
                keyBtn.TextColor3 = T.AccentSoft
                tw(keyBtn, {BackgroundColor3 = T.TabActive}, 0.1)
            else
                keyBtn.Text = key.Name
                keyBtn.TextColor3 = T.Accent
                tw(keyBtn, {BackgroundColor3 = T.Section}, 0.1)
            end
        end
        keyBtn.MouseButton1Click:Connect(toggleListen)
        keyBtn.TouchTap:Connect(toggleListen)

        UserInputService.InputBegan:Connect(function(inp)
            if listening and inp.UserInputType == Enum.UserInputType.Keyboard then
                key = inp.KeyCode
                listening = false
                keyBtn.Text = key.Name
                keyBtn.TextColor3 = T.Accent
                tw(keyBtn, {BackgroundColor3 = T.Section}, 0.1)
                if opts.Flag then tab._window.Flags[opts.Flag] = key.Name end
            end
        end)

        UserInputService.InputBegan:Connect(function(inp, gpe)
            if not gpe and inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == key then
                if opts.Callback then pcall(opts.Callback) end
            end
        end)

        if opts.Flag then tab._window.Flags[opts.Flag] = key.Name end
    end

    function tab:CreateDropdown(opts)
        opts = opts or {}
        local options  = opts.Options or {}
        local selected = opts.CurrentOption or (options[1] or "")
        local isOpen   = false
        local baseH    = sc(40)
        local optH     = sc(28)
        local dropH    = #options * optH + sc(8)

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -6, 0, baseH)
        card.BackgroundColor3 = T.Card
        card.ClipsDescendants = false
        card.Parent = self._page
        corner(card, 9)
        stroke(card, T.Border, 1)

        local icoSz2 = sc(18)
        imgLabel(card, opts.Icon or ICON.dropdown,
            UDim2.new(0, icoSz2, 0, icoSz2),
            UDim2.new(0, sc(12), 0.5, -math.round(icoSz2 / 2)),
            T.Accent)

        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(0.55, 0, 1, 0)
        nl.Position = UDim2.new(0, sc(36), 0, 0)
        nl.BackgroundTransparency = 1
        nl.Font = Enum.Font.GothamSemibold
        nl.TextSize = sf(13)
        nl.TextColor3 = T.Text
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Text = opts.Name or "Dropdown"
        nl.Parent = card

        local selLbl = Instance.new("TextLabel")
        selLbl.Size = UDim2.new(0.4, -32, 1, 0)
        selLbl.Position = UDim2.new(0.55, 0, 0, 0)
        selLbl.BackgroundTransparency = 1
        selLbl.Font = Enum.Font.GothamBold
        selLbl.TextSize = sf(12)
        selLbl.TextColor3 = T.Accent
        selLbl.TextXAlignment = Enum.TextXAlignment.Right
        selLbl.Text = selected
        selLbl.Parent = card

        local arrLbl = Instance.new("TextLabel")
        arrLbl.Size = UDim2.new(0, sc(20), 1, 0)
        arrLbl.Position = UDim2.new(1, -sc(24), 0, 0)
        arrLbl.BackgroundTransparency = 1
        arrLbl.Font = Enum.Font.GothamBold
        arrLbl.TextSize = sf(14)
        arrLbl.TextColor3 = T.SubText
        arrLbl.Text = "▾"
        arrLbl.Parent = card

        local dropFrame = Instance.new("Frame")
        dropFrame.Size = UDim2.new(1, 0, 0, dropH)
        dropFrame.Position = UDim2.new(0, 0, 1, 4)
        dropFrame.BackgroundColor3 = T.CardHover
        dropFrame.Visible = false
        dropFrame.ZIndex = 10
        dropFrame.Parent = card
        corner(dropFrame, 8)
        stroke(dropFrame, T.BorderAccent, 1)
        listLayout(dropFrame, 2)
        pad(dropFrame, 4, 4, 4, 4)

        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, sc(24))
            optBtn.BackgroundColor3 = T.Section
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextSize = sf(12)
            optBtn.TextColor3 = (opt == selected) and T.Accent or T.Text
            optBtn.Text = opt
            optBtn.AutoButtonColor = false
            optBtn.ZIndex = 11
            optBtn.Parent = dropFrame
            corner(optBtn, 6)
            optBtn.MouseEnter:Connect(function() tw(optBtn, {BackgroundColor3 = T.TabActive}, 0.1) end)
            optBtn.MouseLeave:Connect(function() tw(optBtn, {BackgroundColor3 = T.Section},   0.1) end)
            local function selectOpt()
                selected = opt
                selLbl.Text = opt
                isOpen = false
                dropFrame.Visible = false
                tw(arrLbl, {Rotation = 0}, 0.15)
                card.Size = UDim2.new(1, -6, 0, baseH)
                if opts.Flag then tab._window.Flags[opts.Flag] = opt end
                if opts.Callback then pcall(opts.Callback, opt) end
            end
            optBtn.MouseButton1Click:Connect(selectOpt)
            optBtn.TouchTap:Connect(selectOpt)
        end

        local function toggleDrop()
            isOpen = not isOpen
            dropFrame.Visible = isOpen
            tw(arrLbl, {Rotation = isOpen and 180 or 0}, 0.18)
            card.Size = UDim2.new(1, -6, 0, isOpen and (baseH + dropH + sc(12)) or baseH)
        end
        local topBtn = Instance.new("TextButton")
        topBtn.Size = UDim2.new(1, 0, 1, 0)
        topBtn.BackgroundTransparency = 1
        topBtn.Text = ""
        topBtn.ZIndex = 5
        topBtn.Parent = card
        topBtn.MouseButton1Click:Connect(toggleDrop)
        topBtn.TouchTap:Connect(toggleDrop)

        if opts.Flag then tab._window.Flags[opts.Flag] = selected end

        local obj = {}
        function obj:Set(v)
            selected = v
            selLbl.Text = v
        end
        function obj:Get() return selected end
        return obj
    end

    function tab:CreateInput(opts)
        opts = opts or {}

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -6, 0, sc(50))
        card.BackgroundColor3 = T.Card
        card.Parent = self._page
        corner(card, 9)
        stroke(card, T.Border, 1)

        local icoSz2 = sc(18)
        imgLabel(card, opts.Icon or ICON.input,
            UDim2.new(0, icoSz2, 0, icoSz2),
            UDim2.new(0, sc(12), 0, sc(8)),
            T.SubText)

        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(1, -sc(40), 0, sc(18))
        nl.Position = UDim2.new(0, sc(36), 0, sc(6))
        nl.BackgroundTransparency = 1
        nl.Font = Enum.Font.GothamSemibold
        nl.TextSize = sf(12)
        nl.TextColor3 = T.Text
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Text = opts.Name or "Input"
        nl.Parent = card

        local inputBox = Instance.new("TextBox")
        inputBox.Size = UDim2.new(1, -sc(44), 0, sc(24))
        inputBox.Position = UDim2.new(0, sc(36), 1, -sc(30))
        inputBox.BackgroundColor3 = T.Section
        inputBox.Font = Enum.Font.Gotham
        inputBox.TextSize = sf(12)
        inputBox.TextColor3 = T.Text
        inputBox.PlaceholderText = opts.Placeholder or "Type here..."
        inputBox.PlaceholderColor3 = T.Muted
        inputBox.TextXAlignment = Enum.TextXAlignment.Left
        inputBox.Text = opts.Default or ""
        inputBox.ClearTextOnFocus = opts.ClearOnFocus ~= false
        inputBox.Parent = card
        corner(inputBox, 6)
        local inputStr = stroke(inputBox, T.Border, 1)
        pad(inputBox, 0, 0, sc(8), sc(8))

        inputBox.Focused:Connect(function()
            tw(inputBox, {BackgroundColor3 = T.CardHover}, 0.12)
            inputStr.Color = T.BorderAccent
            inputStr.Thickness = 1.5
        end)
        inputBox.FocusLost:Connect(function(enter)
            tw(inputBox, {BackgroundColor3 = T.Section}, 0.12)
            inputStr.Color = T.Border
            inputStr.Thickness = 1
            if opts.Flag then tab._window.Flags[opts.Flag] = inputBox.Text end
            if opts.Callback then pcall(opts.Callback, inputBox.Text, enter) end
        end)

        if opts.Flag then tab._window.Flags[opts.Flag] = inputBox.Text end

        local obj = {}
        function obj:Set(v) inputBox.Text = tostring(v) end
        function obj:Get() return inputBox.Text end
        return obj
    end

    function tab:CreateColorPicker(opts)
        opts = opts or {}
        local vals = {255, 100, 100}
        if opts.Color then
            vals[1] = math.round(opts.Color.R * 255)
            vals[2] = math.round(opts.Color.G * 255)
            vals[3] = math.round(opts.Color.B * 255)
        end

        local rowH   = sc(22)
        local cardH  = sc(34) + 3 * rowH + sc(6)

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -6, 0, cardH)
        card.BackgroundColor3 = T.Card
        card.Parent = self._page
        corner(card, 9)
        stroke(card, T.Border, 1)

        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(0.7, 0, 0, sc(22))
        nl.Position = UDim2.new(0, sc(12), 0, sc(5))
        nl.BackgroundTransparency = 1
        nl.Font = Enum.Font.GothamSemibold
        nl.TextSize = sf(13)
        nl.TextColor3 = T.Text
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Text = opts.Name or "Color"
        nl.Parent = card

        local preview = Instance.new("Frame")
        preview.Size = UDim2.new(0, sc(26), 0, sc(26))
        preview.Position = UDim2.new(1, -sc(34), 0, sc(7))
        preview.BackgroundColor3 = Color3.fromRGB(vals[1], vals[2], vals[3])
        preview.Parent = card
        corner(preview, 6)
        stroke(preview, T.Border, 1)

        local function updateColor()
            preview.BackgroundColor3 = Color3.fromRGB(vals[1], vals[2], vals[3])
            local col = Color3.fromRGB(vals[1], vals[2], vals[3])
            if opts.Flag then tab._window.Flags[opts.Flag] = col end
            if opts.Callback then pcall(opts.Callback, col) end
        end

        local chColors = {
            Color3.fromRGB(220, 70,  70),
            Color3.fromRGB(70,  200, 100),
            Color3.fromRGB(70,  120, 220),
        }
        local chNames = {"R", "G", "B"}

        for i = 1, 3 do
            local yOff = sc(28) + (i - 1) * rowH

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0, sc(12), 0, sc(16))
            lbl.Position = UDim2.new(0, sc(12), 0, yOff + sc(3))
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = sf(10)
            lbl.TextColor3 = chColors[i]
            lbl.Text = chNames[i]
            lbl.Parent = card

            local trk = Instance.new("Frame")
            trk.Size = UDim2.new(1, -sc(68), 0, sc(6))
            trk.Position = UDim2.new(0, sc(26), 0, yOff + sc(8))
            trk.BackgroundColor3 = T.Section
            trk.Parent = card
            corner(trk, 3)

            local pct = vals[i] / 255
            local fl  = Instance.new("Frame")
            fl.Size = UDim2.new(pct, 0, 1, 0)
            fl.BackgroundColor3 = chColors[i]
            fl.Parent = trk
            corner(fl, 3)

            local vLbl = Instance.new("TextLabel")
            vLbl.Size = UDim2.new(0, sc(30), 0, sc(16))
            vLbl.Position = UDim2.new(1, -sc(34), 0, yOff + sc(3))
            vLbl.BackgroundTransparency = 1
            vLbl.Font = Enum.Font.GothamBold
            vLbl.TextSize = sf(10)
            vLbl.TextColor3 = T.SubText
            vLbl.TextXAlignment = Enum.TextXAlignment.Right
            vLbl.Text = tostring(vals[i])
            vLbl.Parent = card

            local idx = i
            local sl2 = false
            local function applyColor(inp)
                local p = math.clamp((inp.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X, 0, 1)
                vals[idx] = math.round(p * 255)
                tw(fl, {Size = UDim2.new(p, 0, 1, 0)}, 0.05)
                vLbl.Text = tostring(vals[idx])
                updateColor()
            end
            trk.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    sl2 = true; applyColor(inp)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    sl2 = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if sl2 and (inp.UserInputType == Enum.UserInputType.MouseMovement
                or inp.UserInputType == Enum.UserInputType.Touch) then
                    applyColor(inp)
                end
            end)
        end

        if opts.Flag then tab._window.Flags[opts.Flag] = Color3.fromRGB(vals[1], vals[2], vals[3]) end
        if opts.Callback then pcall(opts.Callback, Color3.fromRGB(vals[1], vals[2], vals[3])) end
    end

    return tab
end

RexUi.Notify = Notify
RexUi.Icons  = ICON
RexUi.Theme  = T

return RexUi
