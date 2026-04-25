local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local VirtualUser      = game:GetService("VirtualUser")
local TeleportService  = game:GetService("TeleportService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera
local Mouse            = LocalPlayer:GetMouse()
local IsMobile         = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local BodyParts = {
    "Head",
    "UpperTorso",
    "LowerTorso",
    "LeftUpperArm",
    "RightUpperArm",
    "LeftLowerArm",
    "RightLowerArm",
    "LeftUpperLeg",
    "RightUpperLeg",
    "LeftLowerLeg",
    "RightLowerLeg",
    "HumanoidRootPart",
}

local BodyPartAliases = {
    ["Head"]         = {"Head"},
    ["UpperTorso"]   = {"UpperTorso", "Torso"},
    ["LowerTorso"]   = {"LowerTorso"},
    ["Left Arm"]     = {"LeftUpperArm", "LeftLowerArm", "Left Arm"},
    ["Right Arm"]    = {"RightUpperArm", "RightLowerArm", "Right Arm"},
    ["Left Leg"]     = {"LeftUpperLeg",  "LeftLowerLeg",  "Left Leg"},
    ["Right Leg"]    = {"RightUpperLeg", "RightLowerLeg", "Right Leg"},
    ["Root"]         = {"HumanoidRootPart"},
}

local Cfg = {
    SilentAim          = false,
    SilentAimFOV       = 120,
    SilentAimPart      = "Head",
    SilentAimSmooth    = 6,

    Aimbot             = false,
    AimbotSmooth       = 8,
    AimbotFOV          = 150,
    AimbotPart         = "Head",
    AimSpeedMode       = "Human",   -- "Human" | "Fast" | "Instant"
    ShowFOVCircle      = true,
    FOVCircleColor     = Color3.fromRGB(255, 255, 255),

    AutoParry          = false,
    AutoParryRange     = 8,

    SpeedHack          = false,
    SpeedValue         = 32,
    JumpHack           = false,
    JumpValue          = 100,
    InfiniteJump       = false,
    Noclip             = false,
    Fly                = false,
    FlySpeed           = 60,
    FlyBoostSpeed      = 150,

    ESP                = false,
    ESPBoxes           = true,
    ESPNames           = true,
    ESPHealth          = true,
    ESPDistance        = true,
    ESPMaxDist         = 500,

    Chams              = false,
    ChamTransparency   = 0.5,

    Tracers            = false,
    TracerOrigin       = "Bottom",

    FullBright         = false,
    FullBrightValue    = 2,

    AntiAFK            = false,
    AutoRejoin         = false,
    FPSBoost           = false,
}

local Character, Humanoid, RootPart
local Connections = {}
local ESPData     = {}
local ChamData    = {}
local FlyBG, FlyBV = nil, nil
local AimTarget = nil

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible       = false
FOVCircle.Filled        = false
FOVCircle.Color         = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness     = 1.4
FOVCircle.Transparency  = 1
FOVCircle.NumSides      = 80

local function GetChar()
    Character = LocalPlayer.Character
    if not Character then return false end
    Humanoid  = Character:FindFirstChildOfClass("Humanoid")
    RootPart  = Character:FindFirstChild("HumanoidRootPart")
    return Humanoid ~= nil and RootPart ~= nil
end

local function VPCenter()
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function W2S(pos)
    local sp, vis = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), vis, sp.Z
end

local function FOVScale()
    if IsMobile then
        local baseW = 1280
        return Camera.ViewportSize.X / baseW
    end
    return 1
end

local function ScreenDist(pos3D)
    local sp, vis = Camera:WorldToViewportPoint(pos3D)
    if not vis then return math.huge end
    local dist = (Vector2.new(sp.X, sp.Y) - VPCenter()).Magnitude
    return dist / FOVScale()
end

local function ResolvePart(plr, alias)
    if not plr or not plr.Character then return nil end
    local list = BodyPartAliases[alias]
    if list then
        for _, name in ipairs(list) do
            local p = plr.Character:FindFirstChild(name)
            if p then return p end
        end
    end
    return plr.Character:FindFirstChild(alias)
        or plr.Character:FindFirstChild("UpperTorso")
        or plr.Character:FindFirstChild("HumanoidRootPart")
end

local function GetClosest(fov)
    local best, bestDist = nil, fov
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            -- Rivals team check: не целимся в союзников
            if LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then
                continue
            end
            local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
                      or plr.Character:FindFirstChild("Humanoid")
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local d = ScreenDist(root.Position)
                if d < bestDist then
                    best     = plr
                    bestDist = d
                end
            end
        end
    end
    return best
end

local function PartDist(a, b)
    if not a or not b then return math.huge end
    return (a.Position - b.Position).Magnitude
end

local function Disconnect(key)
    if Connections[key] then
        pcall(function() Connections[key]:Disconnect() end)
        Connections[key] = nil
    end
end

local function SmoothFactor(speed, dt)
    return 1 - math.exp(-speed * dt)
end

local function OnCharacterAdded(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid")
    RootPart  = char:WaitForChild("HumanoidRootPart")
    FlyBG, FlyBV = nil, nil
    Connections["InfJump"] = Humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
        if Cfg.InfiniteJump and Humanoid.Jump then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
if LocalPlayer.Character then OnCharacterAdded(LocalPlayer.Character) end

local function SetupFly()
    if not RootPart then return end
    local oldBG = RootPart:FindFirstChild("NokoFlyBG")
    local oldBV = RootPart:FindFirstChild("NokoFlyBV")
    if oldBG then oldBG:Destroy() end
    if oldBV then oldBV:Destroy() end
    FlyBG = Instance.new("BodyGyro")
    FlyBG.Name      = "NokoFlyBG"
    FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    FlyBG.P         = 9e4
    FlyBG.D         = 1e3
    FlyBG.CFrame    = Camera.CFrame
    FlyBG.Parent    = RootPart
    FlyBV = Instance.new("BodyVelocity")
    FlyBV.Name      = "NokoFlyBV"
    FlyBV.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
    FlyBV.Velocity  = Vector3.zero
    FlyBV.Parent    = RootPart
end

local function DestroyFly()
    if RootPart then
        local bg = RootPart:FindFirstChild("NokoFlyBG")
        local bv = RootPart:FindFirstChild("NokoFlyBV")
        if bg then bg:Destroy() end
        if bv then bv:Destroy() end
    end
    FlyBG, FlyBV = nil, nil
    if Humanoid then Humanoid.PlatformStand = false end
end

local function GetFlyDir(dt)
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or
       UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then
        dir = dir + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
       UserInputService:IsKeyDown(Enum.KeyCode.C) or
       UserInputService:IsKeyDown(Enum.KeyCode.ButtonB) then
        dir = dir - Vector3.new(0, 1, 0)
    end
    if Humanoid then
        local mob = Humanoid.MoveDirection
        if mob.Magnitude > 0.05 then
            local cf  = Camera.CFrame
            local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
            local rgt = cf.RightVector
            dir = dir + fwd * (-mob.Z) + rgt * mob.X
        end
    end
    return dir
end

local ESPColor = {
    Box  = Color3.fromRGB(255, 60, 60),
    Name = Color3.fromRGB(255, 255, 255),
    Dist = Color3.fromRGB(180, 180, 180),
    Trc  = Color3.fromRGB(255, 60, 60),
}

local function NewText(size)
    local t = Drawing.new("Text")
    t.Visible      = false
    t.Size         = size or 13
    t.Center       = true
    t.Outline      = true
    t.OutlineColor = Color3.fromRGB(0, 0, 0)
    t.Font         = Drawing.Fonts.Plex
    t.Transparency = 1
    return t
end

local function NewQuad(filled)
    local q = Drawing.new("Quad")
    q.Visible      = false
    q.Filled       = filled or false
    q.Color        = ESPColor.Box
    q.Thickness    = 1.4
    q.Transparency = 1
    return q
end

local function NewLine()
    local l = Drawing.new("Line")
    l.Visible      = false
    l.Color        = ESPColor.Trc
    l.Thickness    = 1.2
    l.Transparency = 1
    return l
end

local function CreateESP(plr)
    if ESPData[plr] then return end
    local hpBG   = NewQuad(true)
    hpBG.Color   = Color3.fromRGB(0, 0, 0)
    hpBG.Transparency = 0.55
    local hpFill = NewQuad(true)
    hpFill.Color = Color3.fromRGB(60, 255, 60)
    ESPData[plr] = {
        Box      = NewQuad(false),
        NameTxt  = NewText(13),
        HpTxt    = NewText(11),
        DistTxt  = NewText(11),
        HpBG     = hpBG,
        HpFill   = hpFill,
        Tracer   = NewLine(),
    }
end

local function RemoveESP(plr)
    local d = ESPData[plr]
    if not d then return end
    for _, obj in pairs(d) do pcall(function() obj:Remove() end) end
    ESPData[plr] = nil
end

local function CreateChams(plr)
    if ChamData[plr] or not plr.Character then return end
    local hl = Instance.new("Highlight")
    hl.Name              = "NokoChams"
    hl.FillColor         = Color3.fromRGB(255, 60, 60)
    hl.OutlineColor      = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency  = Cfg.ChamTransparency
    hl.OutlineTransparency = 0
    hl.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee           = plr.Character
    hl.Parent            = Camera
    ChamData[plr]        = hl
end

local function RemoveChams(plr)
    if ChamData[plr] then
        pcall(function() ChamData[plr]:Destroy() end)
        ChamData[plr] = nil
    end
end

local function UpdateESP()
    local vp = Camera.ViewportSize
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local d    = ESPData[plr]
        if not d   then continue end
        local char = plr.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        if not (char and hum and root and head) then
            for _, obj in pairs(d) do
                if obj and type(obj.Visible) == "boolean" then obj.Visible = false end
            end
            continue
        end
        local rootSP, rootVis, rootZ = W2S(root.Position)
        local headSP                 = W2S(head.Position)
        local alive   = hum.Health > 0
        local dist3D  = GetChar() and RootPart and math.floor(PartDist(RootPart, root)) or 9999
        local show    = Cfg.ESP and rootVis and rootZ > 0 and alive and dist3D <= Cfg.ESPMaxDist

        if show and Cfg.ESPBoxes then
            local topSP = W2S(root.Position + Vector3.new(0, 3.2, 0))
            local botSP = W2S(root.Position - Vector3.new(0, 3.2, 0))
            local h     = math.abs(topSP.Y - botSP.Y)
            local w     = h * 0.56
            local tl    = Vector2.new(rootSP.X - w/2, topSP.Y)
            local tr    = Vector2.new(rootSP.X + w/2, topSP.Y)
            local br    = Vector2.new(rootSP.X + w/2, botSP.Y)
            local bl    = Vector2.new(rootSP.X - w/2, botSP.Y)
            d.Box.PointA = tl; d.Box.PointB = tr
            d.Box.PointC = br; d.Box.PointD = bl
            d.Box.Visible = true
            if Cfg.ESPHealth then
                local ratio   = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local barW    = 4
                local barLeft = tl.X - barW - 2
                d.HpBG.PointA = Vector2.new(barLeft, tl.Y)
                d.HpBG.PointB = Vector2.new(barLeft + barW, tl.Y)
                d.HpBG.PointC = Vector2.new(barLeft + barW, bl.Y)
                d.HpBG.PointD = Vector2.new(barLeft, bl.Y)
                d.HpBG.Visible = true
                local fillTop = tl.Y + h * (1 - ratio)
                d.HpFill.PointA = Vector2.new(barLeft, fillTop)
                d.HpFill.PointB = Vector2.new(barLeft + barW, fillTop)
                d.HpFill.PointC = Vector2.new(barLeft + barW, bl.Y)
                d.HpFill.PointD = Vector2.new(barLeft, bl.Y)
                d.HpFill.Color  = Color3.fromHSV(ratio * 0.33, 1, 1)
                d.HpFill.Visible = true
            else
                d.HpBG.Visible  = false
                d.HpFill.Visible = false
            end
        else
            d.Box.Visible    = false
            d.HpBG.Visible   = false
            d.HpFill.Visible = false
        end

        if show and Cfg.ESPNames then
            d.NameTxt.Text     = plr.DisplayName
            d.NameTxt.Color    = ESPColor.Name
            d.NameTxt.Position = Vector2.new(rootSP.X, headSP.Y - 18)
            d.NameTxt.Visible  = true
        else
            d.NameTxt.Visible = false
        end

        if show and Cfg.ESPHealth then
            d.HpTxt.Text     = math.floor(hum.Health) .. " HP"
            d.HpTxt.Color    = Color3.fromHSV(math.clamp(hum.Health/hum.MaxHealth, 0,1)*0.33, 1, 1)
            d.HpTxt.Position = Vector2.new(rootSP.X, headSP.Y - 7)
            d.HpTxt.Visible  = true
        else
            d.HpTxt.Visible = false
        end

        if show and Cfg.ESPDistance then
            d.DistTxt.Text     = dist3D .. "m"
            d.DistTxt.Color    = ESPColor.Dist
            d.DistTxt.Position = Vector2.new(rootSP.X, (d.Box.PointC and d.Box.PointC.Y or rootSP.Y) + 3)
            d.DistTxt.Visible  = true
        else
            d.DistTxt.Visible = false
        end

        if show and Cfg.Tracers then
            local origin
            if Cfg.TracerOrigin == "Bottom" then
                origin = Vector2.new(vp.X/2, vp.Y)
            elseif Cfg.TracerOrigin == "Center" then
                origin = Vector2.new(vp.X/2, vp.Y/2)
            else
                origin = Vector2.new(vp.X/2, 0)
            end
            d.Tracer.From    = origin
            d.Tracer.To      = rootSP
            d.Tracer.Visible = true
        else
            d.Tracer.Visible = false
        end
    end
end

local function OnPlayerAdded(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.3)
        if Cfg.ESP   then CreateESP(plr)   end
        if Cfg.Chams then CreateChams(plr) end
    end)
    if plr.Character then
        if Cfg.ESP   then CreateESP(plr)   end
        if Cfg.Chams then CreateChams(plr) end
    end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(function(plr)
    RemoveESP(plr)
    RemoveChams(plr)
end)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then OnPlayerAdded(plr) end
end

-- Пресеты скорости аима
local AimSpeedPresets = {
    ["Human"]   = 3,   -- плавно как человек
    ["Fast"]    = 12,  -- немного ускоренное
    ["Instant"] = 0,   -- моментальный снап (0 = спец. режим)
}

local function GetAimAlpha(dt)
    if Cfg.AimSpeedMode == "Instant" then
        return 1
    end
    local spd = AimSpeedPresets[Cfg.AimSpeedMode] or Cfg.AimbotSmooth
    return SmoothFactor(spd, dt)
end

local function DoAimbot(dt)
    local target = GetClosest(Cfg.AimbotFOV)
    AimTarget = target
    if not target then return end
    local part = ResolvePart(target, Cfg.AimbotPart)
    if not part then return end
    local targetCF = CFrame.new(Camera.CFrame.Position, part.Position)
    local alpha    = GetAimAlpha(dt)
    Camera.CFrame  = Camera.CFrame:Lerp(targetCF, alpha)
end

local function DoSilentAim()
    local target = GetClosest(Cfg.SilentAimFOV)
    if not target then return end
    local part = ResolvePart(target, Cfg.SilentAimPart)
    if not part then return end
    local sp, vis = W2S(part.Position)
    if not vis then return end
    if IsMobile then
        local targetCF  = CFrame.new(Camera.CFrame.Position, part.Position)
        local alpha     = GetAimAlpha(1/60)
        Camera.CFrame   = Camera.CFrame:Lerp(targetCF, alpha)
    else
        Mouse.TargetFilter = Character
    end
end

Connections["RenderStepped"] = RunService.RenderStepped:Connect(function(dt)
    if Cfg.SilentAim then DoSilentAim() end

    FOVCircle.Visible = (Cfg.Aimbot or Cfg.SilentAim) and Cfg.ShowFOVCircle
    if FOVCircle.Visible then
        local r = Cfg.Aimbot and Cfg.AimbotFOV or Cfg.SilentAimFOV
        FOVCircle.Position = VPCenter()
        FOVCircle.Radius   = r * FOVScale()
        FOVCircle.Color    = Cfg.FOVCircleColor
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if Cfg.ESP   and not ESPData[plr]  then CreateESP(plr)   end
            if Cfg.Chams and not ChamData[plr] and plr.Character then CreateChams(plr) end
            if ChamData[plr] and plr.Character then
                ChamData[plr].Adornee = plr.Character
            end
        end
    end
    UpdateESP()
end)

-- Rivals fix: запускаем aimbot ПОСЛЕ обновления камеры игры (приоритет Camera+1)
-- Это не даёт игре перезаписать наш поворот камеры
RunService:BindToRenderStep("NokoAimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if Cfg.Aimbot then DoAimbot(dt) end
end)

Connections["Heartbeat"] = RunService.Heartbeat:Connect(function(dt)
    if not GetChar() then return end

    if Cfg.SpeedHack  then Humanoid.WalkSpeed = Cfg.SpeedValue  end
    if Cfg.JumpHack   then Humanoid.JumpPower = Cfg.JumpValue   end

    if Cfg.Noclip then
        for _, p in ipairs(Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end
    end

    if Cfg.Fly then
        if not FlyBG or not FlyBV then SetupFly() end
        Humanoid.PlatformStand = true
        local dir   = GetFlyDir(dt)
        local boost = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or
                      UserInputService:IsKeyDown(Enum.KeyCode.ButtonR2)
        local spd   = boost and Cfg.FlyBoostSpeed or Cfg.FlySpeed
        if FlyBG then FlyBG.CFrame = Camera.CFrame end
        if FlyBV then
            if dir.Magnitude > 0 then
                FlyBV.Velocity = dir.Unit * spd
            else
                FlyBV.Velocity = FlyBV.Velocity * math.max(0, 1 - dt * 10)
            end
        end
    end

    if Cfg.AutoParry then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local er = plr.Character:FindFirstChild("HumanoidRootPart")
                if er and PartDist(RootPart, er) <= Cfg.AutoParryRange then
                    local RS = game:GetService("ReplicatedStorage")
                    for _, rem in ipairs({
                        workspace:FindFirstChild("Remotes"),
                        RS:FindFirstChild("Remotes"),
                        RS:FindFirstChild("Events"),
                    }) do
                        if rem then
                            for _, re in ipairs(rem:GetChildren()) do
                                if re:IsA("RemoteEvent") and
                                   (re.Name:lower():find("parry") or re.Name:lower():find("block")) then
                                    pcall(function() re:FireServer() end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

local Window = Rayfield:CreateWindow({
    Name             = "Noko Hub  1.0.0",
    Icon             = 0,
    LoadingTitle     = "Noko Hub",
    LoadingSubtitle  = "Rivals  |  v1.0.0  |  " .. (IsMobile and "Mobile" or "PC"),
    Theme            = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving    = { Enabled = false },
    Discord                = { Enabled = false },
    KeySystem              = false,
})

local CombatTab  = Window:CreateTab("⚔️ Combat",   4483362458)
local MoveTab    = Window:CreateTab("🏃 Movement", 4483362458)
local VisualTab  = Window:CreateTab("👁️ Visuals",  4483362458)
local MiscTab    = Window:CreateTab("⚙️ Misc",     4483362458)

CombatTab:CreateSection("Silent Aim")
CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "SilentAim",
    Callback = function(v)
        Cfg.SilentAim = v
        Rayfield:Notify({ Title = "Silent Aim", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
CombatTab:CreateSlider({
    Name = "Silent Aim FOV",
    Range = {20, 500}, Increment = 5, Suffix = "px",
    CurrentValue = 120, Flag = "SilentFOV",
    Callback = function(v) Cfg.SilentAimFOV = v end,
})
CombatTab:CreateSlider({
    Name = "Silent Aim Smooth",
    Range = {1, 30}, Increment = 1, Suffix = "x",
    CurrentValue = 6, Flag = "SilentSmooth",
    Callback = function(v) Cfg.SilentAimSmooth = v end,
})
CombatTab:CreateDropdown({
    Name = "Silent Aim Part",
    Options = {"Head","UpperTorso","LowerTorso","Left Arm","Right Arm","Left Leg","Right Leg","Root"},
    CurrentOption = {"Head"}, MultipleOptions = false, Flag = "SilentPart",
    Callback = function(v) Cfg.SilentAimPart = v[1] end,
})

CombatTab:CreateSection("Aimbot")
CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false, Flag = "Aimbot",
    Callback = function(v)
        Cfg.Aimbot = v
        Rayfield:Notify({ Title = "Aimbot", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
CombatTab:CreateSlider({
    Name = "Aimbot Smooth",
    Range = {1, 30}, Increment = 1, Suffix = "x",
    CurrentValue = 8, Flag = "AimbotSmooth",
    Callback = function(v) Cfg.AimbotSmooth = v end,
})
CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {20, 600}, Increment = 10, Suffix = "px",
    CurrentValue = 150, Flag = "AimbotFOV",
    Callback = function(v) Cfg.AimbotFOV = v end,
})
CombatTab:CreateDropdown({
    Name = "Aimbot Target Part",
    Options = {"Head","UpperTorso","LowerTorso","Left Arm","Right Arm","Left Leg","Right Leg","Root"},
    CurrentOption = {"Head"}, MultipleOptions = false, Flag = "AimbotPart",
    Callback = function(v) Cfg.AimbotPart = v[1] end,
})
CombatTab:CreateDropdown({
    Name = "🎯 Aim Speed",
    Options = {"Human", "Fast", "Instant"},
    CurrentOption = {"Human"}, MultipleOptions = false, Flag = "AimSpeedMode",
    Callback = function(v)
        Cfg.AimSpeedMode = v[1]
        local labels = {
            ["Human"]   = "🐢 Как человек — плавно",
            ["Fast"]    = "⚡ Ускоренное — быстро",
            ["Instant"] = "💥 Моментальный снап",
        }
        Rayfield:Notify({ Title = "Aim Speed", Content = labels[v[1]] or v[1], Duration = 2 })
    end,
})
CombatTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true, Flag = "ShowFOV",
    Callback = function(v) Cfg.ShowFOVCircle = v end,
})

CombatTab:CreateSection("Defense")
CombatTab:CreateToggle({
    Name = "Auto Parry",
    CurrentValue = false, Flag = "AutoParry",
    Callback = function(v)
        Cfg.AutoParry = v
        Rayfield:Notify({ Title = "Auto Parry", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
CombatTab:CreateSlider({
    Name = "Parry Range",
    Range = {2, 30}, Increment = 1, Suffix = " studs",
    CurrentValue = 8, Flag = "ParryRange",
    Callback = function(v) Cfg.AutoParryRange = v end,
})

MoveTab:CreateSection("Speed")
MoveTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false, Flag = "SpeedHack",
    Callback = function(v)
        Cfg.SpeedHack = v
        if not v and GetChar() then Humanoid.WalkSpeed = 16 end
        Rayfield:Notify({ Title = "Speed Hack", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MoveTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 500}, Increment = 2, Suffix = " WS",
    CurrentValue = 32, Flag = "SpeedValue",
    Callback = function(v) Cfg.SpeedValue = v end,
})

MoveTab:CreateSection("Jump")
MoveTab:CreateToggle({
    Name = "Jump Hack",
    CurrentValue = false, Flag = "JumpHack",
    Callback = function(v)
        Cfg.JumpHack = v
        if not v and GetChar() then Humanoid.JumpPower = 50 end
        Rayfield:Notify({ Title = "Jump Hack", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MoveTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 1000}, Increment = 10, Suffix = " JP",
    CurrentValue = 100, Flag = "JumpPower",
    Callback = function(v) Cfg.JumpValue = v end,
})
MoveTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false, Flag = "InfJump",
    Callback = function(v)
        Cfg.InfiniteJump = v
        Rayfield:Notify({ Title = "Infinite Jump", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})

MoveTab:CreateSection("Advanced")
MoveTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false, Flag = "Noclip",
    Callback = function(v)
        Cfg.Noclip = v
        Rayfield:Notify({ Title = "Noclip", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MoveTab:CreateToggle({
    Name = "Fly  [Shift = Boost]",
    CurrentValue = false, Flag = "Fly",
    Callback = function(v)
        Cfg.Fly = v
        if v then SetupFly() else DestroyFly() end
        Rayfield:Notify({ Title = "Fly", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MoveTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 500}, Increment = 5, Suffix = " FS",
    CurrentValue = 60, Flag = "FlySpeed",
    Callback = function(v) Cfg.FlySpeed = v end,
})
MoveTab:CreateSlider({
    Name = "Fly Boost Speed",
    Range = {50, 1000}, Increment = 10, Suffix = " FS",
    CurrentValue = 150, Flag = "FlyBoost",
    Callback = function(v) Cfg.FlyBoostSpeed = v end,
})

VisualTab:CreateSection("ESP")
VisualTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false, Flag = "ESP",
    Callback = function(v)
        Cfg.ESP = v
        if not v then
            for _, plr in ipairs(Players:GetPlayers()) do RemoveESP(plr) end
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then CreateESP(plr) end
            end
        end
        Rayfield:Notify({ Title = "ESP", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
VisualTab:CreateToggle({ Name = "ESP Boxes",    CurrentValue = true,  Flag = "ESPBoxes",  Callback = function(v) Cfg.ESPBoxes    = v end })
VisualTab:CreateToggle({ Name = "ESP Names",    CurrentValue = true,  Flag = "ESPNames",  Callback = function(v) Cfg.ESPNames    = v end })
VisualTab:CreateToggle({ Name = "ESP Health",   CurrentValue = true,  Flag = "ESPHealth", Callback = function(v) Cfg.ESPHealth   = v end })
VisualTab:CreateToggle({ Name = "ESP Distance", CurrentValue = true,  Flag = "ESPDist",   Callback = function(v) Cfg.ESPDistance = v end })
VisualTab:CreateSlider({
    Name = "ESP Max Distance",
    Range = {50, 2000}, Increment = 50, Suffix = "m",
    CurrentValue = 500, Flag = "ESPMaxDist",
    Callback = function(v) Cfg.ESPMaxDist = v end,
})

VisualTab:CreateSection("Chams")
VisualTab:CreateToggle({
    Name = "Chams",
    CurrentValue = false, Flag = "Chams",
    Callback = function(v)
        Cfg.Chams = v
        if not v then
            for _, plr in ipairs(Players:GetPlayers()) do RemoveChams(plr) end
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then CreateChams(plr) end
            end
        end
        Rayfield:Notify({ Title = "Chams", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
VisualTab:CreateSlider({
    Name = "Chams Transparency",
    Range = {0, 100}, Increment = 5, Suffix = "%",
    CurrentValue = 50, Flag = "ChamTransp",
    Callback = function(v)
        Cfg.ChamTransparency = v / 100
        for _, hl in pairs(ChamData) do hl.FillTransparency = Cfg.ChamTransparency end
    end,
})

VisualTab:CreateSection("Tracers")
VisualTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = false, Flag = "Tracers",
    Callback = function(v)
        Cfg.Tracers = v
        Rayfield:Notify({ Title = "Tracers", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
VisualTab:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Center", "Top"},
    CurrentOption = {"Bottom"}, MultipleOptions = false, Flag = "TracerOrigin",
    Callback = function(v) Cfg.TracerOrigin = v[1] end,
})

VisualTab:CreateSection("Environment")
VisualTab:CreateToggle({
    Name = "FullBright",
    CurrentValue = false, Flag = "FullBright",
    Callback = function(v)
        Cfg.FullBright = v
        if v then
            Lighting.Ambient        = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness     = Cfg.FullBrightValue
            Lighting.ClockTime      = 14
            Lighting.FogEnd         = 100000
            for _, ef in ipairs(Lighting:GetChildren()) do
                if ef:IsA("PostEffect") then ef.Enabled = false end
            end
        else
            Lighting.Ambient        = Color3.fromRGB(127, 127, 127)
            Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
            Lighting.Brightness     = 1
            for _, ef in ipairs(Lighting:GetChildren()) do
                if ef:IsA("PostEffect") then ef.Enabled = true end
            end
        end
        Rayfield:Notify({ Title = "FullBright", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
VisualTab:CreateSlider({
    Name = "Brightness Level",
    Range = {1, 10}, Increment = 1, Suffix = "x",
    CurrentValue = 2, Flag = "Brightness",
    Callback = function(v)
        Cfg.FullBrightValue = v
        if Cfg.FullBright then Lighting.Brightness = v end
    end,
})

MiscTab:CreateSection("Utility")
MiscTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false, Flag = "AntiAFK",
    Callback = function(v)
        Cfg.AntiAFK = v
        Disconnect("AntiAFK")
        if v then
            Connections["AntiAFK"] = LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
                VirtualUser:CaptureController()
            end)
        end
        Rayfield:Notify({ Title = "Anti AFK", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MiscTab:CreateToggle({
    Name = "Auto Rejoin",
    CurrentValue = false, Flag = "AutoRejoin",
    Callback = function(v)
        Cfg.AutoRejoin = v
        Disconnect("AutoRejoin")
        if v then
            Connections["AutoRejoin"] = LocalPlayer.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.Failed then
                    task.wait(2)
                    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
                end
            end)
        end
        Rayfield:Notify({ Title = "Auto Rejoin", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})

MiscTab:CreateSection("Performance")
MiscTab:CreateToggle({
    Name = "FPS Boost",
    CurrentValue = false, Flag = "FPSBoost",
    Callback = function(v)
        Cfg.FPSBoost = v
        settings().Rendering.QualityLevel = v
            and Enum.QualityLevel.Level01
            or  Enum.QualityLevel.Automatic
        Rayfield:Notify({ Title = "FPS Boost", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})

MiscTab:CreateSection("Server")
MiscTab:CreateButton({
    Name = "🔄  Rejoin Server",
    Callback = function()
        Rayfield:Notify({ Title = "Rejoin", Content = "Переподключение через 2с...", Duration = 2 })
        task.wait(2)
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end,
})
MiscTab:CreateButton({
    Name = "📋  Копировать PlaceId",
    Callback = function()
        setclipboard(tostring(game.PlaceId))
        Rayfield:Notify({ Title = "Скопировано", Content = "PlaceId: " .. game.PlaceId, Duration = 3 })
    end,
})

game:BindToClose(function()
    FOVCircle:Remove()
    pcall(function() RunService:UnbindFromRenderStep("NokoAimbot") end)
    for _, plr in ipairs(Players:GetPlayers()) do
        RemoveESP(plr)
        RemoveChams(plr)
    end
    for _, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    DestroyFly()
end)

Rayfield:Notify({
    Title   = "Noko Hub  1.0.0",
    Content = "Загружен | Rivals | " .. (IsMobile and "📱 Mobile" or "🖥️ PC"),
    Duration = 5,
    Image   = 4483362458,
})

print("[Noko Hub 1.0.0] Loaded | " .. (IsMobile and "Mobile" or "PC") .. " | " .. os.date("%H:%M:%S"))
