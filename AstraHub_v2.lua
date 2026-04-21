--[[
 ╔═══════════════════════════════════════════════════════════╗
 ║              ASTRAHUB  —  CUSTOM UI v2.0                  ║
 ║  Key System + Main Menu  |  Pure Instance-based GUI       ║
 ╚═══════════════════════════════════════════════════════════╝
--]]

-- ══════════════════════════════════════════════════════════
--  CONFIG
-- ══════════════════════════════════════════════════════════
local CFG = {
    Name      = "ASTRAHUB",
    Version   = "2.0",
    KeyLink   = "https://your-site.com/astrahub-key",  -- ← your site
    SaveFile  = "astrahub_key.dat",
    KeyPrefix = "ASTRA-",

    -- Accent colors (B&W theme)
    White     = Color3.fromRGB(255, 255, 255),
    Black     = Color3.fromRGB(0,   0,   0  ),
    Gray1     = Color3.fromRGB(12,  12,  12 ),
    Gray2     = Color3.fromRGB(22,  22,  22 ),
    Gray3     = Color3.fromRGB(40,  40,  40 ),
    Gray4     = Color3.fromRGB(90,  90,  90 ),
    Gray5     = Color3.fromRGB(160, 160, 160),
}

-- ══════════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════════
local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local UserInput     = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local LocalPlayer   = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════
local function tween(obj, info, props)
    TweenService:Create(obj, info, props):Play()
end

local function make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function shadow(parent, offset, opacity)
    return make("ImageLabel", {
        Size            = UDim2.new(1,10,1,10),
        Position        = UDim2.new(0,-5,0,offset or 4),
        BackgroundTransparency = 1,
        Image           = "rbxassetid://6015897843",
        ImageColor3     = CFG.Black,
        ImageTransparency = opacity or 0.6,
        ScaleType       = Enum.ScaleType.Slice,
        SliceCenter     = Rect.new(49,49,450,450),
        ZIndex          = 0,
    }, parent)
end

local function stroke(parent, color, thickness)
    return make("UIStroke", {
        Color     = color or CFG.Gray3,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

-- Smooth tween info presets
local TI = {
    fast  = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    med   = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    slow  = TweenInfo.new(0.4,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    enter = TweenInfo.new(0.5,  Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
}

-- Key file I/O
local function saveKey(k)
    if writefile then pcall(writefile, CFG.SaveFile, k) end
end
local function loadKey()
    if readfile and isfile and isfile(CFG.SaveFile) then
        local ok, v = pcall(readfile, CFG.SaveFile)
        if ok then return v:match("^%s*(.-)%s*$") end
    end
    return nil
end

-- ══════════════════════════════════════════════════════════
--  UI ROOT
-- ══════════════════════════════════════════════════════════
local Gui = make("ScreenGui", {
    Name            = "AstraHub",
    ResetOnSpawn    = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    DisplayOrder    = 999,
}, (syn and syn.protect_gui and syn.protect_gui(Instance.new("ScreenGui")) or
   (gethui and gethui()) or LocalPlayer.PlayerGui))

-- ══════════════════════════════════════════════════════════
--  ██  KEY SYSTEM UI
-- ══════════════════════════════════════════════════════════
local function buildKeyUI(onSuccess)
    -- Backdrop
    local backdrop = make("Frame", {
        Size               = UDim2.fromScale(1,1),
        BackgroundColor3   = CFG.Black,
        BackgroundTransparency = 0.25,
        BorderSizePixel    = 0,
        ZIndex             = 10,
    }, Gui)

    -- Panel
    local panel = make("Frame", {
        Size               = UDim2.fromOffset(480, 340),
        Position           = UDim2.fromScale(0.5, 0.5),
        AnchorPoint        = Vector2.new(0.5, 0.5),
        BackgroundColor3   = CFG.Gray1,
        BorderSizePixel    = 0,
        ZIndex             = 11,
    }, backdrop)
    stroke(panel, CFG.Gray3, 1)
    shadow(panel, 6, 0.5)

    -- Animate in
    panel.Position = UDim2.fromScale(0.5, 0.6)
    panel.BackgroundTransparency = 1
    tween(panel, TI.enter, {
        Position            = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 0,
    })

    -- Top accent bar
    make("Frame", {
        Size             = UDim2.new(1,0,0,2),
        BackgroundColor3 = CFG.White,
        BorderSizePixel  = 0,
        ZIndex           = 12,
    }, panel)

    -- Header row
    local header = make("Frame", {
        Size             = UDim2.new(1,0,0,52),
        Position         = UDim2.fromOffset(0,2),
        BackgroundColor3 = CFG.Gray2,
        BorderSizePixel  = 0,
        ZIndex           = 12,
    }, panel)

    make("TextLabel", {
        Size             = UDim2.new(1,-80,1,0),
        Position         = UDim2.fromOffset(20,0),
        BackgroundTransparency = 1,
        Text             = CFG.Name .. "  //  KEY SYSTEM",
        TextColor3       = CFG.White,
        Font             = Enum.Font.GothamBold,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
        LetterSpacing    = 3,
        ZIndex           = 13,
    }, header)

    make("TextLabel", {
        Size             = UDim2.new(0,60,1,0),
        Position         = UDim2.new(1,-70,0,0),
        BackgroundTransparency = 1,
        Text             = "v" .. CFG.Version,
        TextColor3       = CFG.Gray4,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Right,
        ZIndex           = 13,
    }, header)

    -- Divider
    make("Frame", {
        Size             = UDim2.new(1,0,0,1),
        Position         = UDim2.fromOffset(0,54),
        BackgroundColor3 = CFG.Gray3,
        BorderSizePixel  = 0,
        ZIndex           = 12,
    }, panel)

    -- Body container
    local body = make("Frame", {
        Size             = UDim2.new(1,-48,0,230),
        Position         = UDim2.fromOffset(24, 76),
        BackgroundTransparency = 1,
        ZIndex           = 12,
    }, panel)

    -- Instruction label
    make("TextLabel", {
        Size             = UDim2.new(1,0,0,18),
        BackgroundTransparency = 1,
        Text             = "ENTER YOUR ACCESS KEY BELOW",
        TextColor3       = CFG.Gray4,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        LetterSpacing    = 4,
        ZIndex           = 13,
    }, body)

    -- Key input box
    local inputBox = make("Frame", {
        Size             = UDim2.new(1,0,0,44),
        Position         = UDim2.fromOffset(0, 28),
        BackgroundColor3 = CFG.Gray2,
        BorderSizePixel  = 0,
        ZIndex           = 13,
    }, body)
    stroke(inputBox, CFG.Gray3, 1)

    local input = make("TextBox", {
        Size             = UDim2.new(1,-16,1,0),
        Position         = UDim2.fromOffset(12,0),
        BackgroundTransparency = 1,
        Text             = "",
        PlaceholderText  = "ASTRA-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
        PlaceholderColor3 = CFG.Gray4,
        TextColor3       = CFG.White,
        Font             = Enum.Font.Code,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex           = 14,
    }, inputBox)

    -- Focus highlight
    input.Focused:Connect(function()
        tween(inputBox, TI.fast, {BackgroundColor3 = CFG.Gray3})
        stroke(inputBox, CFG.White, 1)
    end)
    input.FocusLost:Connect(function()
        tween(inputBox, TI.fast, {BackgroundColor3 = CFG.Gray2})
        stroke(inputBox, CFG.Gray3, 1)
    end)

    -- Status label
    local statusLabel = make("TextLabel", {
        Size             = UDim2.new(1,0,0,16),
        Position         = UDim2.fromOffset(0, 82),
        BackgroundTransparency = 1,
        Text             = "",
        TextColor3       = CFG.Gray4,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        LetterSpacing    = 2,
        ZIndex           = 13,
    }, body)

    -- Link row
    local linkRow = make("Frame", {
        Size             = UDim2.new(1,0,0,32),
        Position         = UDim2.fromOffset(0, 108),
        BackgroundColor3 = CFG.Gray2,
        BorderSizePixel  = 0,
        ZIndex           = 13,
    }, body)
    stroke(linkRow, CFG.Gray3, 1)

    make("TextLabel", {
        Size             = UDim2.new(0,100,1,0),
        Position         = UDim2.fromOffset(12,0),
        BackgroundTransparency = 1,
        Text             = "GET KEY →",
        TextColor3       = CFG.Gray5,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        LetterSpacing    = 3,
        ZIndex           = 14,
    }, linkRow)

    local linkText = make("TextLabel", {
        Size             = UDim2.new(1,-120,1,0),
        Position         = UDim2.fromOffset(108,0),
        BackgroundTransparency = 1,
        Text             = CFG.KeyLink,
        TextColor3       = CFG.Gray4,
        Font             = Enum.Font.Code,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 14,
    }, linkRow)

    -- Copy link button
    local copyLinkBtn = make("TextButton", {
        Size             = UDim2.fromOffset(60, 24),
        Position         = UDim2.new(1,-68, 0.5, -12),
        BackgroundColor3 = CFG.Gray3,
        BorderSizePixel  = 0,
        Text             = "COPY",
        TextColor3       = CFG.Gray5,
        Font             = Enum.Font.GothamBold,
        TextSize         = 9,
        ZIndex           = 14,
    }, linkRow)
    make("UICorner", {CornerRadius = UDim.new(0,2)}, copyLinkBtn)

    copyLinkBtn.MouseButton1Click:Connect(function()
        setclipboard(CFG.KeyLink)
        copyLinkBtn.Text = "✓"
        tween(copyLinkBtn, TI.fast, {BackgroundColor3 = CFG.White, TextColor3 = CFG.Black})
        task.delay(1.5, function()
            copyLinkBtn.Text = "COPY"
            tween(copyLinkBtn, TI.fast, {BackgroundColor3 = CFG.Gray3, TextColor3 = CFG.Gray5})
        end)
    end)

    -- Bottom buttons row
    local btnRow = make("Frame", {
        Size             = UDim2.new(1,0,0,44),
        Position         = UDim2.fromOffset(0, 152),
        BackgroundTransparency = 1,
        ZIndex           = 13,
    }, body)

    -- Confirm button
    local confirmBtn = make("TextButton", {
        Size             = UDim2.new(1,-54,1,0),
        BackgroundColor3 = CFG.White,
        BorderSizePixel  = 0,
        Text             = "CONFIRM KEY",
        TextColor3       = CFG.Black,
        Font             = Enum.Font.GothamBold,
        TextSize         = 12,
        LetterSpacing    = 4,
        ZIndex           = 14,
    }, btnRow)

    -- Confirm hover
    confirmBtn.MouseEnter:Connect(function()
        tween(confirmBtn, TI.fast, {BackgroundColor3 = CFG.Gray5})
    end)
    confirmBtn.MouseLeave:Connect(function()
        tween(confirmBtn, TI.fast, {BackgroundColor3 = CFG.White})
    end)

    -- Close / exit button
    local closeBtn = make("TextButton", {
        Size             = UDim2.fromOffset(44,44),
        Position         = UDim2.new(1,-44,0,0),
        BackgroundColor3 = CFG.Gray2,
        BorderSizePixel  = 0,
        Text             = "✕",
        TextColor3       = CFG.Gray4,
        Font             = Enum.Font.GothamBold,
        TextSize         = 14,
        ZIndex           = 14,
    }, btnRow)
    stroke(closeBtn, CFG.Gray3, 1)
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, TI.fast, {BackgroundColor3 = CFG.Gray3, TextColor3 = CFG.White})
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, TI.fast, {BackgroundColor3 = CFG.Gray2, TextColor3 = CFG.Gray4})
    end)
    closeBtn.MouseButton1Click:Connect(function()
        backdrop:Destroy()
    end)

    -- ── Validation logic ──
    local function setStatus(msg, color)
        statusLabel.Text       = msg
        statusLabel.TextColor3 = color or CFG.Gray4
    end

    local function validateKey(k)
        k = k:match("^%s*(.-)%s*$")
        if k:sub(1, #CFG.KeyPrefix) ~= CFG.KeyPrefix then return false end
        if #k < 30 then return false end
        -- Check character pattern  ASTRA-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
        if not k:match("^ASTRA%-%w+%-%w+%-%w+%-%w+%-%w+$") then return false end
        return true
    end

    confirmBtn.MouseButton1Click:Connect(function()
        local key = input.Text:match("^%s*(.-)%s*$")
        if key == "" then
            setStatus("⚠  KEY FIELD IS EMPTY", CFG.Gray5)
            tween(inputBox, TI.fast, {BackgroundColor3 = Color3.fromRGB(35,15,15)})
            task.delay(0.6, function()
                tween(inputBox, TI.fast, {BackgroundColor3 = CFG.Gray2})
            end)
            return
        end

        confirmBtn.Text = "VERIFYING..."
        confirmBtn.Active = false
        task.wait(0.6)

        if validateKey(key) then
            saveKey(key)
            setStatus("✓  KEY ACCEPTED  —  ACCESS GRANTED", CFG.White)
            tween(confirmBtn, TI.fast, {BackgroundColor3 = CFG.White})
            confirmBtn.Text = "✓  GRANTED"
            task.wait(1.0)
            -- Fade out
            tween(backdrop, TI.med, {BackgroundTransparency = 1})
            tween(panel, TI.med, {
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.44),
            })
            task.wait(0.35)
            backdrop:Destroy()
            onSuccess()
        else
            setStatus("✕  INVALID KEY  —  CHECK FORMAT", Color3.fromRGB(220,80,80))
            confirmBtn.Text = "CONFIRM KEY"
            confirmBtn.Active = true
            tween(inputBox, TI.fast, {BackgroundColor3 = Color3.fromRGB(35,15,15)})
            task.delay(0.8, function()
                tween(inputBox, TI.fast, {BackgroundColor3 = CFG.Gray2})
            end)
        end
    end)
end

-- ══════════════════════════════════════════════════════════
--  ██  MAIN MENU UI
-- ══════════════════════════════════════════════════════════
local function buildMainMenu()
    -- ── Window ──
    local MENU_W, MENU_H = 620, 420

    local win = make("Frame", {
        Size             = UDim2.fromOffset(MENU_W, MENU_H),
        Position         = UDim2.fromScale(0.5, 0.5),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = CFG.Gray1,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, Gui)
    stroke(win, CFG.Gray3, 1)
    shadow(win, 8, 0.45)

    -- Entrance animation
    win.BackgroundTransparency = 1
    win.Position = UDim2.fromScale(0.5, 0.56)
    tween(win, TI.enter, {
        BackgroundTransparency = 0,
        Position = UDim2.fromScale(0.5, 0.5),
    })

    -- Top accent line
    make("Frame", {
        Size             = UDim2.new(1,0,0,2),
        BackgroundColor3 = CFG.White,
        BorderSizePixel  = 0,
        ZIndex           = 6,
    }, win)

    -- ── Title bar ──
    local titleBar = make("Frame", {
        Size             = UDim2.new(1,0,0,46),
        Position         = UDim2.fromOffset(0,2),
        BackgroundColor3 = CFG.Gray2,
        BorderSizePixel  = 0,
        ZIndex           = 6,
    }, win)

    make("TextLabel", {
        Size             = UDim2.new(1,-120,1,0),
        Position         = UDim2.fromOffset(18,0),
        BackgroundTransparency = 1,
        Text             = "▶  " .. CFG.Name,
        TextColor3       = CFG.White,
        Font             = Enum.Font.GothamBold,
        TextSize         = 14,
        TextXAlignment   = Enum.TextXAlignment.Left,
        LetterSpacing    = 5,
        ZIndex           = 7,
    }, titleBar)

    make("TextLabel", {
        Size             = UDim2.new(0,80,1,0),
        Position         = UDim2.new(1,-90,0,0),
        BackgroundTransparency = 1,
        Text             = "v" .. CFG.Version,
        TextColor3       = CFG.Gray4,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Right,
        ZIndex           = 7,
    }, titleBar)

    -- Minimize / Close buttons
    local function headerBtn(xOffset, icon, action)
        local b = make("TextButton", {
            Size             = UDim2.fromOffset(30,30),
            Position         = UDim2.new(1, xOffset, 0.5, -15),
            BackgroundColor3 = CFG.Gray3,
            BorderSizePixel  = 0,
            Text             = icon,
            TextColor3       = CFG.Gray5,
            Font             = Enum.Font.GothamBold,
            TextSize         = 13,
            ZIndex           = 8,
        }, titleBar)
        make("UICorner", {CornerRadius = UDim.new(0,3)}, b)
        b.MouseEnter:Connect(function()
            tween(b, TI.fast, {BackgroundColor3 = CFG.White, TextColor3 = CFG.Black})
        end)
        b.MouseLeave:Connect(function()
            tween(b, TI.fast, {BackgroundColor3 = CFG.Gray3, TextColor3 = CFG.Gray5})
        end)
        b.MouseButton1Click:Connect(action)
        return b
    end

    local minimized = false
    local mainBody -- defined below
    headerBtn(-38, "—", function()
        minimized = not minimized
        if mainBody then
            tween(win, TI.med, {Size = UDim2.fromOffset(MENU_W, minimized and 48 or MENU_H)})
        end
    end)
    headerBtn(-8, "✕", function()
        tween(win, TI.med, {BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.56)})
        task.delay(0.3, function() win:Destroy() end)
    end)

    -- Draggable
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = win.Position
        end
    end)
    UserInput.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            win.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInput.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Divider below titlebar
    make("Frame", {
        Size             = UDim2.new(1,0,0,1),
        Position         = UDim2.fromOffset(0,48),
        BackgroundColor3 = CFG.Gray3,
        BorderSizePixel  = 0,
        ZIndex           = 6,
    }, win)

    -- ── Sidebar ──
    local sidebar = make("Frame", {
        Size             = UDim2.new(0,140,1,-50),
        Position         = UDim2.fromOffset(0,50),
        BackgroundColor3 = CFG.Gray2,
        BorderSizePixel  = 0,
        ZIndex           = 6,
    }, win)

    make("Frame", {
        Size             = UDim2.new(0,1,1,0),
        Position         = UDim2.new(1,-1,0,0),
        BackgroundColor3 = CFG.Gray3,
        BorderSizePixel  = 0,
        ZIndex           = 7,
    }, sidebar)

    -- ── Content area ──
    mainBody = make("Frame", {
        Size             = UDim2.new(1,-142,1,-50),
        Position         = UDim2.fromOffset(141,50),
        BackgroundTransparency = 1,
        ZIndex           = 6,
    }, win)

    -- ── Tab system ──
    local tabs = {}
    local activeTab = nil

    local tabList = make("Frame", {
        Size             = UDim2.new(1,0,1,-8),
        Position         = UDim2.fromOffset(0,8),
        BackgroundTransparency = 1,
        ZIndex           = 7,
    }, sidebar)
    make("UIListLayout", {
        SortOrder    = Enum.SortOrder.LayoutOrder,
        Padding      = UDim.new(0,2),
    }, tabList)
    make("UIPadding", {
        PaddingLeft  = UDim.new(0,6),
        PaddingRight = UDim.new(0,6),
    }, tabList)

    local function addTab(name, icon, buildFn)
        local btn = make("TextButton", {
            Size             = UDim2.new(1,0,0,36),
            BackgroundColor3 = CFG.Gray1,
            BorderSizePixel  = 0,
            Text             = "",
            ZIndex           = 8,
            LayoutOrder      = #tabs + 1,
        }, tabList)
        make("UICorner", {CornerRadius = UDim.new(0,4)}, btn)

        make("TextLabel", {
            Size             = UDim2.new(1,-30,1,0),
            Position         = UDim2.fromOffset(28,0),
            BackgroundTransparency = 1,
            Text             = name,
            TextColor3       = CFG.Gray4,
            Font             = Enum.Font.GothamBold,
            TextSize         = 11,
            TextXAlignment   = Enum.TextXAlignment.Left,
            LetterSpacing    = 2,
            ZIndex           = 9,
        }, btn)

        make("TextLabel", {
            Size             = UDim2.fromOffset(18,36),
            Position         = UDim2.fromOffset(8,0),
            BackgroundTransparency = 1,
            Text             = icon,
            TextColor3       = CFG.Gray4,
            Font             = Enum.Font.GothamBold,
            TextSize         = 13,
            ZIndex           = 9,
        }, btn)

        -- Active indicator bar
        local indicator = make("Frame", {
            Size             = UDim2.fromOffset(2,20),
            Position         = UDim2.new(0,-6, 0.5, -10),
            BackgroundColor3 = CFG.White,
            BorderSizePixel  = 0,
            BackgroundTransparency = 1,
            ZIndex           = 9,
        }, btn)

        -- Content frame
        local content = make("Frame", {
            Size             = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            Visible          = false,
            ZIndex           = 7,
        }, mainBody)

        local tab = {btn=btn, content=content, indicator=indicator}
        table.insert(tabs, tab)

        btn.MouseEnter:Connect(function()
            if activeTab ~= tab then
                tween(btn, TI.fast, {BackgroundColor3 = CFG.Gray3})
            end
        end)
        btn.MouseLeave:Connect(function()
            if activeTab ~= tab then
                tween(btn, TI.fast, {BackgroundColor3 = CFG.Gray1})
            end
        end)

        btn.MouseButton1Click:Connect(function()
            if activeTab == tab then return end
            if activeTab then
                activeTab.content.Visible = false
                tween(activeTab.btn, TI.fast, {BackgroundColor3 = CFG.Gray1})
                tween(activeTab.indicator, TI.fast, {BackgroundTransparency = 1})
                local oldLabels = activeTab.btn:GetDescendants()
                for _, l in ipairs(oldLabels) do
                    if l:IsA("TextLabel") then
                        tween(l, TI.fast, {TextColor3 = CFG.Gray4})
                    end
                end
            end
            activeTab = tab
            activeTab.content.Visible = true
            tween(btn, TI.fast, {BackgroundColor3 = CFG.Gray3})
            tween(indicator, TI.fast, {BackgroundTransparency = 0})
            for _, l in ipairs(btn:GetDescendants()) do
                if l:IsA("TextLabel") then
                    tween(l, TI.fast, {TextColor3 = CFG.White})
                end
            end
        end)

        buildFn(content)
        return tab
    end

    -- ── Toggle helper (used inside tabs) ──
    local function addToggle(parent, yPos, label, desc, default, callback)
        local row = make("Frame", {
            Size             = UDim2.new(1,-24,0,50),
            Position         = UDim2.fromOffset(12, yPos),
            BackgroundColor3 = CFG.Gray2,
            BorderSizePixel  = 0,
            ZIndex           = 8,
        }, parent)
        stroke(row, CFG.Gray3, 1)
        make("UICorner", {CornerRadius = UDim.new(0,4)}, row)

        make("TextLabel", {
            Size             = UDim2.new(1,-70,0,20),
            Position         = UDim2.fromOffset(14,8),
            BackgroundTransparency = 1,
            Text             = label,
            TextColor3       = CFG.White,
            Font             = Enum.Font.GothamBold,
            TextSize         = 11,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 9,
        }, row)

        make("TextLabel", {
            Size             = UDim2.new(1,-70,0,16),
            Position         = UDim2.fromOffset(14,26),
            BackgroundTransparency = 1,
            Text             = desc,
            TextColor3       = CFG.Gray4,
            Font             = Enum.Font.GothamMedium,
            TextSize         = 9,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 9,
        }, row)

        -- Toggle pill
        local pill = make("Frame", {
            Size             = UDim2.fromOffset(40,20),
            Position         = UDim2.new(1,-52, 0.5, -10),
            BackgroundColor3 = default and CFG.White or CFG.Gray3,
            BorderSizePixel  = 0,
            ZIndex           = 9,
        }, row)
        make("UICorner", {CornerRadius = UDim.new(1,0)}, pill)

        local knob = make("Frame", {
            Size             = UDim2.fromOffset(14,14),
            Position         = default
                and UDim2.fromOffset(23,3)
                or  UDim2.fromOffset(3,3),
            BackgroundColor3 = default and CFG.Black or CFG.Gray5,
            BorderSizePixel  = 0,
            ZIndex           = 10,
        }, pill)
        make("UICorner", {CornerRadius = UDim.new(1,0)}, knob)

        local state = default
        local togBtn = make("TextButton", {
            Size             = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            Text             = "",
            ZIndex           = 11,
        }, row)
        togBtn.MouseButton1Click:Connect(function()
            state = not state
            tween(pill, TI.fast, {BackgroundColor3 = state and CFG.White or CFG.Gray3})
            tween(knob, TI.fast, {
                Position     = state and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3),
                BackgroundColor3 = state and CFG.Black or CFG.Gray5,
            })
            if callback then callback(state) end
        end)

        return row
    end

    -- ── Slider helper ──
    local function addSlider(parent, yPos, label, min, max, default, callback)
        local row = make("Frame", {
            Size             = UDim2.new(1,-24,0,56),
            Position         = UDim2.fromOffset(12, yPos),
            BackgroundColor3 = CFG.Gray2,
            BorderSizePixel  = 0,
            ZIndex           = 8,
        }, parent)
        stroke(row, CFG.Gray3, 1)
        make("UICorner", {CornerRadius = UDim.new(0,4)}, row)

        local valLabel = make("TextLabel", {
            Size             = UDim2.new(0,40,0,18),
            Position         = UDim2.new(1,-52,0,8),
            BackgroundTransparency = 1,
            Text             = tostring(default),
            TextColor3       = CFG.White,
            Font             = Enum.Font.Code,
            TextSize         = 11,
            TextXAlignment   = Enum.TextXAlignment.Right,
            ZIndex           = 9,
        }, row)

        make("TextLabel", {
            Size             = UDim2.new(1,-60,0,18),
            Position         = UDim2.fromOffset(14,8),
            BackgroundTransparency = 1,
            Text             = label,
            TextColor3       = CFG.White,
            Font             = Enum.Font.GothamBold,
            TextSize         = 11,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 9,
        }, row)

        local track = make("Frame", {
            Size             = UDim2.new(1,-28,0,2),
            Position         = UDim2.fromOffset(14,38),
            BackgroundColor3 = CFG.Gray3,
            BorderSizePixel  = 0,
            ZIndex           = 9,
        }, row)

        local fill = make("Frame", {
            Size             = UDim2.fromScale((default-min)/(max-min), 1),
            BackgroundColor3 = CFG.White,
            BorderSizePixel  = 0,
            ZIndex           = 10,
        }, track)

        local thumb = make("Frame", {
            Size             = UDim2.fromOffset(10,10),
            Position         = UDim2.new((default-min)/(max-min),0-5, 0.5,-5),
            BackgroundColor3 = CFG.White,
            BorderSizePixel  = 0,
            ZIndex           = 11,
        }, track)
        make("UICorner", {CornerRadius = UDim.new(1,0)}, thumb)

        local sliding = false
        local sliderBtn = make("TextButton", {
            Size             = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            Text             = "",
            ZIndex           = 12,
        }, track)

        local function setVal(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + rel*(max-min))
            valLabel.Text = tostring(val)
            fill.Size = UDim2.fromScale(rel, 1)
            thumb.Position = UDim2.new(rel,0-5, 0.5,-5)
            if callback then callback(val) end
        end

        sliderBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = true
                setVal(inp.Position.X)
            end
        end)
        UserInput.InputChanged:Connect(function(inp)
            if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
                setVal(inp.Position.X)
            end
        end)
        UserInput.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = false
            end
        end)

        return row
    end

    -- ══════════════════════
    --  TAB: COMBAT
    -- ══════════════════════
    addTab("COMBAT", "⚔", function(c)
        make("TextLabel", {
            Size             = UDim2.new(1,-24,0,28),
            Position         = UDim2.fromOffset(12,12),
            BackgroundTransparency = 1,
            Text             = "COMBAT SETTINGS",
            TextColor3       = CFG.Gray4,
            Font             = Enum.Font.GothamBold,
            TextSize         = 9,
            TextXAlignment   = Enum.TextXAlignment.Left,
            LetterSpacing    = 4,
            ZIndex           = 8,
        }, c)

        addToggle(c, 44, "AUTO ATTACK", "Automatically attack nearest target", false, function(v)
            print("[AstraHub] AutoAttack:", v)
        end)
        addToggle(c, 100, "INFINITE RANGE", "No distance limit on attacks", false, function(v)
            print("[AstraHub] InfiniteRange:", v)
        end)
        addSlider(c, 156, "ATTACK SPEED", 1, 10, 5, function(v)
            print("[AstraHub] AttackSpeed:", v)
        end)
        addSlider(c, 218, "HIT RADIUS", 5, 50, 15, function(v)
            print("[AstraHub] HitRadius:", v)
        end)
    end)

    -- ══════════════════════
    --  TAB: PLAYER
    -- ══════════════════════
    addTab("PLAYER", "👤", function(c)
        make("TextLabel", {
            Size             = UDim2.new(1,-24,0,28),
            Position         = UDim2.fromOffset(12,12),
            BackgroundTransparency = 1,
            Text             = "PLAYER SETTINGS",
            TextColor3       = CFG.Gray4,
            Font             = Enum.Font.GothamBold,
            TextSize         = 9,
            TextXAlignment   = Enum.TextXAlignment.Left,
            LetterSpacing    = 4,
            ZIndex           = 8,
        }, c)

        addSlider(c, 44, "WALK SPEED", 16, 150, 16, function(v)
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = v end
            end
        end)
        addSlider(c, 106, "JUMP POWER", 50, 300, 50, function(v)
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpPower = v end
            end
        end)
        addToggle(c, 168, "INFINITE JUMP", "Jump repeatedly in mid-air", false, function(v)
            getgenv().InfJump = v
            if v then
                UserInput.JumpRequest:Connect(function()
                    if getgenv().InfJump and LocalPlayer.Character then
                        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                    end
                end)
            end
        end)
        addToggle(c, 224, "NO CLIP", "Walk through solid objects", false, function(v)
            getgenv().NoClip = v
            if v then
                RunService.Stepped:Connect(function()
                    if getgenv().NoClip and LocalPlayer.Character then
                        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                            if p:IsA("BasePart") then
                                p.CanCollide = false
                            end
                        end
                    end
                end)
            end
        end)
    end)

    -- ══════════════════════
    --  TAB: VISUAL
    -- ══════════════════════
    addTab("VISUAL", "👁", function(c)
        make("TextLabel", {
            Size             = UDim2.new(1,-24,0,28),
            Position         = UDim2.fromOffset(12,12),
            BackgroundTransparency = 1,
            Text             = "VISUAL SETTINGS",
            TextColor3       = CFG.Gray4,
            Font             = Enum.Font.GothamBold,
            TextSize         = 9,
            TextXAlignment   = Enum.TextXAlignment.Left,
            LetterSpacing    = 4,
            ZIndex           = 8,
        }, c)

        addToggle(c, 44, "FULLBRIGHT", "Maximum game brightness", false, function(v)
            game:GetService("Lighting").Brightness = v and 10 or 1
            game:GetService("Lighting").ClockTime  = v and 14 or 12
        end)
        addSlider(c, 100, "FIELD OF VIEW", 60, 120, 70, function(v)
            workspace.CurrentCamera.FieldOfView = v
        end)
        addToggle(c, 162, "HIDE GUI", "Toggle all UI visibility", false, function(v)
            for _, g in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if g:IsA("ScreenGui") and g.Name ~= "AstraHub" then
                    g.Enabled = not v
                end
            end
        end)
    end)

    -- ══════════════════════
    --  TAB: SETTINGS
    -- ══════════════════════
    addTab("SETTINGS", "⚙", function(c)
        make("TextLabel", {
            Size             = UDim2.new(1,-24,0,28),
            Position         = UDim2.fromOffset(12,12),
            BackgroundTransparency = 1,
            Text             = "SCRIPT SETTINGS",
            TextColor3       = CFG.Gray4,
            Font             = Enum.Font.GothamBold,
            TextSize         = 9,
            TextXAlignment   = Enum.TextXAlignment.Left,
            LetterSpacing    = 4,
            ZIndex           = 8,
        }, c)

        -- Clear saved key button
        local clearBtn = make("TextButton", {
            Size             = UDim2.new(1,-24,0,40),
            Position         = UDim2.fromOffset(12,44),
            BackgroundColor3 = CFG.Gray2,
            BorderSizePixel  = 0,
            Text             = "CLEAR SAVED KEY",
            TextColor3       = CFG.Gray5,
            Font             = Enum.Font.GothamBold,
            TextSize         = 11,
            LetterSpacing    = 3,
            ZIndex           = 8,
        }, c)
        stroke(clearBtn, CFG.Gray3, 1)
        make("UICorner", {CornerRadius = UDim.new(0,4)}, clearBtn)
        clearBtn.MouseEnter:Connect(function()
            tween(clearBtn, TI.fast, {BackgroundColor3 = CFG.Gray3})
        end)
        clearBtn.MouseLeave:Connect(function()
            tween(clearBtn, TI.fast, {BackgroundColor3 = CFG.Gray2})
        end)
        clearBtn.MouseButton1Click:Connect(function()
            if delfile then pcall(delfile, CFG.SaveFile) end
            clearBtn.Text = "✓  KEY CLEARED"
            task.delay(2, function() clearBtn.Text = "CLEAR SAVED KEY" end)
        end)

        -- Info block
        local info = make("Frame", {
            Size             = UDim2.new(1,-24,0,80),
            Position         = UDim2.fromOffset(12,96),
            BackgroundColor3 = CFG.Gray2,
            BorderSizePixel  = 0,
            ZIndex           = 8,
        }, c)
        stroke(info, CFG.Gray3, 1)
        make("UICorner", {CornerRadius = UDim.new(0,4)}, info)

        local infoLines = {
            "SCRIPT  →  " .. CFG.Name .. " v" .. CFG.Version,
            "GAME    →  " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
            "PLAYER  →  " .. LocalPlayer.Name,
        }
        for i, line in ipairs(infoLines) do
            make("TextLabel", {
                Size             = UDim2.new(1,-24,0,18),
                Position         = UDim2.fromOffset(14, 6 + (i-1)*22),
                BackgroundTransparency = 1,
                Text             = line,
                TextColor3       = CFG.Gray4,
                Font             = Enum.Font.Code,
                TextSize         = 10,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 9,
            }, info)
        end
    end)

    -- Activate first tab
    task.defer(function()
        tabs[1].btn.MouseButton1Click:Fire()
    end)

    -- ── Keybind: RightShift to toggle ──
    UserInput.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == Enum.KeyCode.RightShift then
            win.Visible = not win.Visible
        end
    end)

    return win
end

-- ══════════════════════════════════════════════════════════
--  ██  NOTIFICATION TOAST (global)
-- ══════════════════════════════════════════════════════════
local function notify(title, body, duration)
    duration = duration or 3
    local notif = make("Frame", {
        Size             = UDim2.fromOffset(280, 60),
        Position         = UDim2.new(1,-296, 1,-80),
        BackgroundColor3 = CFG.Gray1,
        BorderSizePixel  = 0,
        ZIndex           = 50,
        AnchorPoint      = Vector2.new(0,1),
    }, Gui)
    stroke(notif, CFG.Gray3, 1)

    make("Frame", {
        Size             = UDim2.fromOffset(2,40),
        Position         = UDim2.fromOffset(0,10),
        BackgroundColor3 = CFG.White,
        BorderSizePixel  = 0,
        ZIndex           = 51,
    }, notif)

    make("TextLabel", {
        Size             = UDim2.new(1,-18,0,20),
        Position         = UDim2.fromOffset(14,8),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = CFG.White,
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Left,
        LetterSpacing    = 2,
        ZIndex           = 51,
    }, notif)

    make("TextLabel", {
        Size             = UDim2.new(1,-18,0,16),
        Position         = UDim2.fromOffset(14,28),
        BackgroundTransparency = 1,
        Text             = body,
        TextColor3       = CFG.Gray4,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 51,
    }, notif)

    notif.Position = UDim2.new(1,-296, 1, 20)
    tween(notif, TI.med, {Position = UDim2.new(1,-296, 1,-80)})
    task.delay(duration, function()
        tween(notif, TI.med, {Position = UDim2.new(1,-296, 1, 20)})
        task.delay(0.3, function() notif:Destroy() end)
    end)
end

-- ══════════════════════════════════════════════════════════
--  ██  ENTRY POINT
-- ══════════════════════════════════════════════════════════
local function main()
    buildMainMenu()
    task.delay(0.5, function()
        notify(CFG.Name, "Script loaded — RShift to toggle", 4)
    end)
    -- ← PUT YOUR GAME LOGIC HERE
end

local saved = loadKey()
if saved and saved:sub(1, #CFG.KeyPrefix) == CFG.KeyPrefix and #saved > 30 then
    notify(CFG.Name, "Saved key found, bypassing prompt...", 3)
    task.wait(0.4)
    main()
else
    buildKeyUI(main)
end
