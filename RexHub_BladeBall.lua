if getgenv().RexHubBBLoaded then
    warn("[Rex Hub] Already loaded!")
    return
end
getgenv().RexHubBBLoaded = true

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(0.3)

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService        = game:GetService("TweenService")
local Stats               = game:GetService("Stats")
local CoreGui             = game:GetService("CoreGui")
local Lighting            = game:GetService("Lighting")

local LP  = Players.LocalPlayer
local Cam = workspace.CurrentCamera

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Cfg = {
    AutoParry            = true,
    PingBased            = false,
    PingOffset           = 0,
    ParryRange           = 0.5,
    BallSpeedCheck       = true,
    AutoSpam             = false,
    SpamRange            = 12,
    AutoAbility          = false,
    AbilityTimerInterval = 8,
    HitSound             = false,
    NightMode            = false,
    GuiOpen              = true,
}

local parryRemote   = nil
local closestEntity = nil
local hitSound      = nil
local isSpamming    = false
local hitCount      = 0

local function safe(fn)
    local ok, err = pcall(fn)
    if not ok then warn("[Rex Hub] " .. tostring(err)) end
end

local function getChar()
    return LP.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getPing()
    local ok, val = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return ok and val or 0
end

local function findParryRemote()
    for _, svc in ipairs({
        game:GetService("AdService"),
        game:GetService("SocialService")
    }) do
        for _, obj in ipairs(svc:GetDescendants()) do
            if obj:IsA("RemoteEvent") and obj.Name:find("\n") then
                parryRemote = obj
                return obj
            end
        end
    end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") and (
            obj.Name:lower():find("parry") or
            obj.Name:lower():find("attack") or
            obj.Name:lower():find("swing")
        ) then
            parryRemote = obj
            return obj
        end
    end
    return nil
end

local function findBall()
    local ballsFolder = workspace:FindFirstChild("Balls")
    if not ballsFolder then return nil end
    for _, v in ipairs(ballsFolder:GetChildren()) do
        if v:GetAttribute("realBall") == true then
            return v
        end
    end
    for _, v in ipairs(ballsFolder:GetChildren()) do
        if v:IsA("BasePart") or v:IsA("MeshPart") then
            return v
        end
    end
    return nil
end

local function isTarget()
    local c = getChar()
    return c and (
        c:FindFirstChild("Highlight") ~= nil or
        c:FindFirstChildOfClass("SelectionBox") ~= nil
    )
end

local function updateClosestEntity()
    local hrp = getHRP()
    if not hrp then return end
    local alive = workspace:FindFirstChild("Alive")
    if not alive then return end
    local best, bestDist = nil, math.huge
    for _, entity in ipairs(alive:GetChildren()) do
        if entity.Name ~= LP.Name then
            local eHRP = entity:FindFirstChild("HumanoidRootPart")
            if eHRP then
                local d = (hrp.Position - eHRP.Position).Magnitude
                if d < bestDist then
                    best     = entity
                    bestDist = d
                end
            end
        end
    end
    closestEntity = best
end

local abilityRemotes = {}

local function scanAbilityRemotes()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:find("abilit") or n:find("skill") or n:find("spell") or n:find("power") then
                if not table.find(abilityRemotes, obj) then
                    table.insert(abilityRemotes, obj)
                end
            end
        end
    end
end

local abilityCooldowns = {}
local lastAbilityFire  = {}

local function fireAbility(remote)
    local now  = tick()
    local last = lastAbilityFire[remote] or 0
    if now - last < 0.3 then return end
    lastAbilityFire[remote] = now
    safe(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer()
        elseif remote:IsA("RemoteFunction") then
            remote:InvokeServer()
        end
    end)
end

local function watchCooldowns()
    local function scanObj(obj)
        for _, v in ipairs(obj:GetDescendants()) do
            if (v:IsA("IntValue") or v:IsA("NumberValue")) then
                local n = v.Name:lower()
                if n:find("cool") or n:find("cd") then
                    if not abilityCooldowns[v] then
                        abilityCooldowns[v] = true
                        v.Changed:Connect(function(val)
                            if not Cfg.AutoAbility then return end
                            if val <= 0 then
                                for _, rem in ipairs(abilityRemotes) do
                                    fireAbility(rem)
                                end
                            end
                        end)
                    end
                end
            end
        end
    end

    local function onCharacter(char)
        task.wait(1)
        scanObj(char)
        scanObj(LP)
    end

    if LP.Character then onCharacter(LP.Character) end
    LP.CharacterAdded:Connect(onCharacter)
end

local abilityTimerLast = 0

local function setupHitSound()
    if hitSound then return end
    safe(function()
        local folder = CoreGui:FindFirstChild("RexHub_BB")
        if not folder then
            folder = Instance.new("Folder")
            folder.Name   = "RexHub_BB"
            folder.Parent = CoreGui
        end
        hitSound          = Instance.new("Sound")
        hitSound.SoundId  = "rbxassetid://936447863"
        hitSound.Volume   = 5
        hitSound.Parent   = folder
    end)
end

safe(function()
    ReplicatedStorage:WaitForChild("Remotes", 10)
end)

safe(function()
    local rem = ReplicatedStorage.Remotes:FindFirstChild("ParrySuccess")
    if rem then
        rem.OnClientEvent:Connect(function()
            if Cfg.HitSound and hitSound then
                hitSound:Play()
            end
        end)
    end
end)

safe(function()
    local rem = ReplicatedStorage.Remotes:FindFirstChild("ParrySuccessAll")
    if rem then
        rem.OnClientEvent:Connect(function()
            hitCount += 1
            task.delay(0.15, function()
                hitCount -= 1
            end)
        end)
    end
end)

safe(function()
    local balls = workspace:WaitForChild("Balls", 10)
    if balls then
        balls.ChildRemoved:Connect(function()
            hitCount   = 0
            isSpamming = false
        end)
    end
end)

task.spawn(function()
    while task.wait(1) do
        safe(function()
            local target = Cfg.NightMode and 3.9 or 13.5
            TweenService:Create(Lighting, TweenInfo.new(3), {ClockTime = target}):Play()
        end)
    end
end)

task.spawn(function()
    RunService.PreRender:Connect(function()

        if Cfg.AutoParry then
            safe(function()
                local ball = findBall()
                if not ball then return end

                local ballPos  = ball.Position
                local ballVel  = ball.AssemblyLinearVelocity.Magnitude
                local distance = LP:DistanceFromCharacter(ballPos)

                if Cfg.BallSpeedCheck and ballVel == 0 then return end

                if Cfg.PingBased then
                    local ping = getPing()
                    distance = distance - (ballVel * (ping / 1000)) - Cfg.PingOffset
                end

                local ratio = distance / ballVel
                if ratio <= Cfg.ParryRange and isTarget() then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end
            end)
        end

        if Cfg.AutoSpam and parryRemote then
            safe(function()
                updateClosestEntity()
                local entity = closestEntity
                if not entity then return end

                local alive = workspace:FindFirstChild("Alive")
                if not alive then return end

                local eInAlive = alive:FindFirstChild(entity.Name)
                if not eInAlive then return end

                local eHum = eInAlive:FindFirstChild("Humanoid")
                if not eHum or eHum.Health <= 0 then return end

                local eHRP = eInAlive:FindFirstChild("HumanoidRootPart")
                if not eHRP then return end

                local hrp = getHRP()
                if not hrp then return end

                local dist = (hrp.Position - eHRP.Position).Magnitude
                if dist <= Cfg.SpamRange then
                    parryRemote:FireServer(
                        0.5,
                        CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + Cam.CFrame.LookVector * 100),
                        {[entity.Name] = eHRP.Position},
                        {eHRP.Position.X, eHRP.Position.Y},
                        false
                    )
                end
            end)
        end

        if Cfg.AutoAbility and #abilityRemotes > 0 then
            local now = tick()
            if now - abilityTimerLast >= Cfg.AbilityTimerInterval then
                abilityTimerLast = now
                for _, rem in ipairs(abilityRemotes) do
                    fireAbility(rem)
                end
            end
        end
    end)
end)

local function buildGui()
    pcall(function()
        local old = CoreGui:FindFirstChild("RexHub_BladeBall")
        if old then old:Destroy() end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name            = "RexHub_BladeBall"
    sg.ResetOnSpawn    = false
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset  = true
    sg.Parent          = CoreGui

    local C = {
        bg      = Color3.fromRGB(10,  10,  20),
        panel   = Color3.fromRGB(16,  16,  32),
        accent  = Color3.fromRGB(80,  40,  220),
        accent2 = Color3.fromRGB(140, 80,  255),
        green   = Color3.fromRGB(40,  220, 100),
        red     = Color3.fromRGB(220, 50,  70),
        yellow  = Color3.fromRGB(255, 200, 40),
        text    = Color3.fromRGB(220, 220, 255),
        dim     = Color3.fromRGB(100, 100, 150),
        white   = Color3.fromRGB(255, 255, 255),
        border  = Color3.fromRGB(50,  30,  120),
    }

    local W = IsMobile and 300 or 340
    local H = IsMobile and 440 or 480

    local Main = Instance.new("Frame")
    Main.Name              = "Main"
    Main.Size              = UDim2.new(0, W, 0, H)
    Main.Position          = UDim2.new(0, 20, 0.5, -(H/2))
    Main.BackgroundColor3  = C.bg
    Main.BorderSizePixel   = 0
    Main.ClipsDescendants  = true
    Main.Parent            = sg
    Instance.new("UICorner").Parent = Main

    local stroke = Instance.new("UIStroke")
    stroke.Color     = C.accent
    stroke.Thickness = 1.5
    stroke.Parent    = Main

    local topBar = Instance.new("Frame")
    topBar.Size             = UDim2.new(1, 0, 0, 3)
    topBar.BackgroundColor3 = C.accent2
    topBar.BorderSizePixel  = 0
    topBar.Parent           = Main
    local tg = Instance.new("UIGradient")
    tg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   C.accent),
        ColorSequenceKeypoint.new(0.5, C.accent2),
        ColorSequenceKeypoint.new(1,   C.accent),
    })
    tg.Parent = topBar

    local titleBar = Instance.new("Frame")
    titleBar.Size                 = UDim2.new(1, 0, 0, 38)
    titleBar.Position             = UDim2.new(0, 0, 0, 3)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent               = Main

    local title = Instance.new("TextLabel")
    title.Size              = UDim2.new(1, -80, 1, 0)
    title.Position          = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text              = "⚡ Rex Hub  |  Blade Ball"
    title.TextColor3        = C.white
    title.Font              = Enum.Font.GothamBold
    title.TextSize          = IsMobile and 12 or 14
    title.TextXAlignment    = Enum.TextXAlignment.Left
    title.Parent            = titleBar

    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size              = UDim2.new(1, -12, 0, 14)
    versionLabel.Position          = UDim2.new(0, 12, 1, -16)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text              = "v1.0.0 beta"
    versionLabel.TextColor3        = C.dim
    versionLabel.Font              = Enum.Font.Gotham
    versionLabel.TextSize          = 10
    versionLabel.TextXAlignment    = Enum.TextXAlignment.Left
    versionLabel.Parent            = titleBar

    local minimized = false

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.new(0, IsMobile and 34 or 28, 0, IsMobile and 34 or 28)
    closeBtn.Position         = UDim2.new(1, IsMobile and -40 or -34, 0, 5)
    closeBtn.BackgroundColor3 = C.red
    closeBtn.Text             = "✕"
    closeBtn.TextColor3       = C.white
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.TextSize         = 13
    closeBtn.BorderSizePixel  = 0
    closeBtn.Parent           = titleBar
    Instance.new("UICorner").Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Main.Size = minimized
            and UDim2.new(0, W, 0, 41)
            or  UDim2.new(0, W, 0, H)
        closeBtn.Text = minimized and "▶" or "✕"
    end)

    local dragging   = false
    local dragStart  = nil
    local startPos   = nil
    local touchId    = nil

    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = Main.Position
        elseif inp.UserInputType == Enum.UserInputType.Touch then
            if not dragging then
                dragging  = true
                touchId   = inp
                dragStart = inp.Position
                startPos  = Main.Position
            end
        end
    end)

    titleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        elseif inp.UserInputType == Enum.UserInputType.Touch then
            if inp == touchId then
                dragging = false
                touchId  = nil
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or
           inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)

    local Content = Instance.new("ScrollingFrame")
    Content.Size                  = UDim2.new(1, 0, 1, -44)
    Content.Position              = UDim2.new(0, 0, 0, 44)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel       = 0
    Content.ScrollBarThickness    = IsMobile and 5 or 3
    Content.ScrollBarImageColor3  = C.accent
    Content.CanvasSize            = UDim2.new(0, 0, 0, 0)
    Content.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    Content.Parent                = Main

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 6)
    layout.Parent    = Content

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft   = UDim.new(0, 10)
    padding.PaddingRight  = UDim.new(0, 10)
    padding.PaddingTop    = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent        = Content

    local order = 0
    local function nextOrder() order = order + 1; return order end

    local function mkSection(text)
        local f = Instance.new("Frame")
        f.Size                 = UDim2.new(1, 0, 0, 22)
        f.BackgroundTransparency = 1
        f.LayoutOrder          = nextOrder()
        f.Parent               = Content

        local line = Instance.new("Frame")
        line.Size             = UDim2.new(1, 0, 0, 1)
        line.Position         = UDim2.new(0, 0, 0.5, 0)
        line.BackgroundColor3 = C.border
        line.BorderSizePixel  = 0
        line.Parent           = f

        local lbl = Instance.new("TextLabel")
        lbl.Size             = UDim2.new(0, 0, 1, 0)
        lbl.AutomaticSize    = Enum.AutomaticSize.X
        lbl.Position         = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundColor3 = C.bg
        lbl.Text             = "  " .. text .. "  "
        lbl.TextColor3       = C.accent2
        lbl.Font             = Enum.Font.GothamBold
        lbl.TextSize         = 11
        lbl.Parent           = f
    end

    local function mkToggle(label, configKey, callback)
        local rowH = IsMobile and 44 or 36
        local row  = Instance.new("Frame")
        row.Size             = UDim2.new(1, 0, 0, rowH)
        row.BackgroundColor3 = C.panel
        row.BorderSizePixel  = 0
        row.LayoutOrder      = nextOrder()
        row.Parent           = Content
        Instance.new("UICorner").Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(1, -60, 1, 0)
        lbl.Position          = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text              = label
        lbl.TextColor3        = C.text
        lbl.Font              = Enum.Font.Gotham
        lbl.TextSize          = IsMobile and 12 or 13
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.Parent            = row

        local togW = IsMobile and 52 or 44
        local togH = IsMobile and 28 or 22
        local tog  = Instance.new("TextButton")
        tog.Size             = UDim2.new(0, togW, 0, togH)
        tog.Position         = UDim2.new(1, -(togW + 8), 0.5, -(togH / 2))
        tog.BackgroundColor3 = Cfg[configKey] and C.green or C.dim
        tog.Text             = Cfg[configKey] and "ON" or "OFF"
        tog.TextColor3       = Color3.fromRGB(10, 10, 10)
        tog.Font             = Enum.Font.GothamBold
        tog.TextSize         = 11
        tog.BorderSizePixel  = 0
        tog.Parent           = row
        Instance.new("UICorner").Parent = tog

        local tweenOn  = TweenService:Create(tog, TweenInfo.new(0.15), {BackgroundColor3 = C.green})
        local tweenOff = TweenService:Create(tog, TweenInfo.new(0.15), {BackgroundColor3 = C.dim})

        tog.MouseButton1Click:Connect(function()
            Cfg[configKey] = not Cfg[configKey]
            local v = Cfg[configKey]
            tog.Text = v and "ON" or "OFF"
            if v then tweenOn:Play() else tweenOff:Play() end
            if callback then callback(v) end
        end)
        return tog
    end

    local function mkSlider(label, configKey, minVal, maxVal, step, suffix)
        suffix = suffix or ""
        step   = step   or 0.1

        local frame = Instance.new("Frame")
        frame.Size             = UDim2.new(1, 0, 0, IsMobile and 62 or 52)
        frame.BackgroundColor3 = C.panel
        frame.BorderSizePixel  = 0
        frame.LayoutOrder      = nextOrder()
        frame.Parent           = Content
        Instance.new("UICorner").Parent = frame

        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(1, -10, 0, 20)
        lbl.Position          = UDim2.new(0, 10, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text              = label .. ": " .. tostring(Cfg[configKey]) .. suffix
        lbl.TextColor3        = C.text
        lbl.Font              = Enum.Font.Gotham
        lbl.TextSize          = IsMobile and 11 or 12
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.Parent            = frame

        local trackY = IsMobile and 38 or 32
        local track  = Instance.new("Frame")
        track.Size             = UDim2.new(1, -20, 0, IsMobile and 10 or 8)
        track.Position         = UDim2.new(0, 10, 0, trackY)
        track.BackgroundColor3 = C.border
        track.BorderSizePixel  = 0
        track.Parent           = frame
        Instance.new("UICorner").Parent = track

        local fill = Instance.new("Frame")
        fill.Size             = UDim2.new(
            (Cfg[configKey] - minVal) / (maxVal - minVal), 0, 1, 0)
        fill.BackgroundColor3 = C.accent2
        fill.BorderSizePixel  = 0
        fill.Parent           = track
        Instance.new("UICorner").Parent = fill

        local knobSize = IsMobile and 22 or 16
        local knob     = Instance.new("TextButton")
        knob.Size             = UDim2.new(0, knobSize, 0, knobSize)
        knob.Position         = UDim2.new(
            (Cfg[configKey] - minVal) / (maxVal - minVal),
            -(knobSize / 2), 0.5, -(knobSize / 2))
        knob.BackgroundColor3 = C.white
        knob.Text             = ""
        knob.BorderSizePixel  = 0
        knob.Parent           = track
        Instance.new("UICorner").Parent = knob

        local sliding   = false
        local slideTouchId = nil

        local function updateSlider(posX)
            local trackPos  = track.AbsolutePosition
            local trackSize = track.AbsoluteSize
            local rel       = math.clamp((posX - trackPos.X) / trackSize.X, 0, 1)
            local raw       = minVal + rel * (maxVal - minVal)
            local snapped   = math.round(raw / step) * step
            snapped         = math.clamp(snapped, minVal, maxVal)
            snapped         = math.floor(snapped * 100 + 0.5) / 100
            Cfg[configKey]  = snapped
            local pct       = (snapped - minVal) / (maxVal - minVal)
            fill.Size       = UDim2.new(pct, 0, 1, 0)
            knob.Position   = UDim2.new(pct, -(knobSize / 2), 0.5, -(knobSize / 2))
            lbl.Text        = label .. ": " .. tostring(snapped) .. suffix
        end

        knob.MouseButton1Down:Connect(function()
            sliding = true
        end)

        knob.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch and not sliding then
                sliding      = true
                slideTouchId = inp
            end
        end)

        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = false
            elseif inp.UserInputType == Enum.UserInputType.Touch then
                if inp == slideTouchId then
                    sliding      = false
                    slideTouchId = nil
                end
            end
        end)

        UserInputService.InputChanged:Connect(function(inp)
            if not sliding then return end
            if inp.UserInputType == Enum.UserInputType.MouseMovement or
               inp.UserInputType == Enum.UserInputType.Touch then
                updateSlider(inp.Position.X)
            end
        end)
    end

    local function mkButton(label, color, callback)
        local btnH = IsMobile and 42 or 34
        local btn  = Instance.new("TextButton")
        btn.Size             = UDim2.new(1, 0, 0, btnH)
        btn.BackgroundColor3 = color or C.accent
        btn.Text             = label
        btn.TextColor3       = C.white
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = IsMobile and 12 or 13
        btn.BorderSizePixel  = 0
        btn.LayoutOrder      = nextOrder()
        btn.Parent           = Content
        Instance.new("UICorner").Parent = btn
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local function mkLabel(text, color)
        local lbl = Instance.new("TextLabel")
        lbl.Size              = UDim2.new(1, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Text              = text
        lbl.TextColor3        = color or C.dim
        lbl.Font              = Enum.Font.Gotham
        lbl.TextSize          = 11
        lbl.TextXAlignment    = Enum.TextXAlignment.Left
        lbl.LayoutOrder       = nextOrder()
        lbl.Parent            = Content
        return lbl
    end

    mkSection("⚡ AUTO PARRY")
    mkToggle("Auto Parry",        "AutoParry",      nil)
    mkToggle("Ping Based (Asia)", "PingBased",      nil)
    mkSlider("Ping Offset",       "PingOffset",     -50, 50,  1,    " ms")
    mkSlider("Parry Range",       "ParryRange",     0.1, 5.0, 0.05, "")
    mkLabel("  Range: меньше = точнее | больше = раньше", C.dim)
    mkToggle("Ball Speed Check",  "BallSpeedCheck", nil)

    mkSection("🏏 AUTO SPAM")
    mkToggle("Auto Spam",         "AutoSpam",  nil)
    mkSlider("Spam Range (studs)","SpamRange", 5, 30, 1, " st")
    mkLabel("  Рекомендуется: 12 studs", C.dim)

    mkSection("🔮 AUTO ABILITY")
    mkToggle("Auto Ability",           "AutoAbility",          nil)
    mkSlider("Ability Interval (sec)", "AbilityTimerInterval", 1, 30, 0.5, "s")
    mkLabel("  Подбери под кулдаун своей способности", C.dim)

    mkSection("🎨 ВИЗУАЛ")
    mkToggle("Hit Sound",  "HitSound",  nil)
    mkToggle("Night Mode", "NightMode", nil)

    mkSection("🔧 ИНФО")
    local pingLabel   = mkLabel("Ping: —",               C.accent2)
    local ballLabel   = mkLabel("Мяч: не найден",        C.dim)
    local targetLabel = mkLabel("Цель: нет",             C.yellow)
    local remoteLabel = mkLabel("Parry Remote: поиск...",C.dim)

    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                pingLabel.Text = "Ping: " .. math.floor(getPing()) .. " ms"
                local ball = findBall()
                ballLabel.Text = ball
                    and ("Мяч: найден | Скорость: " .. math.floor(ball.AssemblyLinearVelocity.Magnitude))
                    or  "Мяч: не найден"
                targetLabel.Text = isTarget()
                    and "Цель: ТЫ 🎯"
                    or  "Цель: другой игрок"
                remoteLabel.Text = parryRemote
                    and "Parry Remote: ✅ найден"
                    or  "Parry Remote: ❌ не найден"
            end)
        end
    end)

    mkSection("⚙️ ДЕЙСТВИЯ")

    mkButton("🔍 Найти Parry Remote", C.accent, function()
        local r = findParryRemote()
        if r then
            remoteLabel.Text = "Parry Remote: ✅ " .. r.Name
        else
            remoteLabel.Text = "Parry Remote: ❌ не найден"
        end
    end)

    mkButton("🔍 Сканировать Ability Remotes", C.accent, function()
        scanAbilityRemotes()
        mkLabel("Найдено: " .. #abilityRemotes .. " ability remotes", C.green)
    end)

    mkButton("🛑 Стоп Всё", C.red, function()
        Cfg.AutoParry   = false
        Cfg.AutoSpam    = false
        Cfg.AutoAbility = false
    end)

    mkButton("▶ Включить Всё", C.green, function()
        Cfg.AutoParry   = true
        Cfg.AutoSpam    = true
        Cfg.AutoAbility = true
    end)

    if IsMobile then
        local mobileToggle = Instance.new("TextButton")
        mobileToggle.Size             = UDim2.new(0, 50, 0, 50)
        mobileToggle.Position         = UDim2.new(1, -60, 1, -60)
        mobileToggle.BackgroundColor3 = C.accent
        mobileToggle.Text             = "⚡"
        mobileToggle.TextColor3       = C.white
        mobileToggle.Font             = Enum.Font.GothamBold
        mobileToggle.TextSize         = 22
        mobileToggle.BorderSizePixel  = 0
        mobileToggle.ZIndex           = 10
        mobileToggle.Parent           = sg
        Instance.new("UICorner").Parent = mobileToggle

        mobileToggle.MouseButton1Click:Connect(function()
            Main.Visible = not Main.Visible
        end)
    else
        UserInputService.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if inp.KeyCode == Enum.KeyCode.Insert or
               inp.KeyCode == Enum.KeyCode.RightAlt then
                sg.Enabled = not sg.Enabled
            end
        end)
    end

    return sg
end

setupHitSound()

task.spawn(function()
    findParryRemote()
    if not parryRemote then
        task.wait(3)
        findParryRemote()
    end
end)

task.spawn(function()
    task.wait(1)
    scanAbilityRemotes()
    watchCooldowns()
end)

task.spawn(function()
    while task.wait(0.2) do
        pcall(updateClosestEntity)
    end
end)

buildGui()

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title    = "⚡ Rex Hub",
        Text     = IsMobile and "Blade Ball v1.0.0 beta! Кнопка ⚡ = меню" or "Blade Ball v1.0.0 beta! Insert = скрыть GUI",
        Duration = 5,
    })
end)

print("╔═══════════════════════════════════╗")
print("║  ⚡ REX HUB | Blade Ball v1.0.0  ║")
print("║  beta | AutoParry | Spam | Ability║")
print("║  PC: Insert/RightAlt = toggle GUI ║")
print("║  Mobile: кнопка ⚡ = toggle GUI   ║")
print("╚═══════════════════════════════════╝")
