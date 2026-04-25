local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local VirtualUser      = game:GetService("VirtualUser")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()
local Cfg = {
    SilentAim        = false,
    SilentAimFOV     = 120,
    SilentAimPart    = "Head",
    SilentAimSmooth  = 0,
    Aimbot           = false,
    AimbotSmooth     = 0.15,
    AimbotFOV        = 150,
    AimbotPart       = "Head",
    ShowFOVCircle    = true,
    AutoParry        = false,
    AutoParryRange   = 8,
    SpeedHack        = false,
    SpeedValue       = 32,
    JumpHack         = false,
    JumpValue        = 100,
    Noclip           = false,
    Fly              = false,
    FlySpeed         = 60,
    FlyBoostSpeed    = 150,
    InfiniteJump     = false,
    ESP              = false,
    ESPBoxes         = true,
    ESPNames         = true,
    ESPHealth        = true,
    ESPDistance      = true,
    ESPMaxDist       = 500,
    Chams            = false,
    ChamColor        = Color3.fromRGB(255, 60, 60),
    ChamTransparency = 0.5,
    Tracers          = false,
    TracerOrigin     = "Bottom",
    FullBright       = false,
    FullBrightValue  = 2,
    AntiAFK          = false,
    AutoRejoin       = false,
    FPSBoost         = false,
    FPSLevel         = 1,
}
local Character, Humanoid, RootPart
local Connections  = {}
local ESPData      = {}
local ChamData     = {}
local TracerData   = {}
local FlyActive    = false
local FlyBG, FlyBV = nil, nil
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible    = false
FOVCircle.Filled     = false
FOVCircle.Color      = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness  = 1.2
FOVCircle.Transparency = 0.8
FOVCircle.NumSides   = 64
local function GetChar()
    Character = LocalPlayer.Character
    if not Character then return false end
    Humanoid  = Character:FindFirstChildOfClass("Humanoid")
    RootPart  = Character:FindFirstChild("HumanoidRootPart")
    return Humanoid and RootPart
end
local function ViewportCenter()
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end
local function WorldToScreen(pos)
    local sp, vis = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), vis, sp.Z
end
local function ScreenDist(pos3D)
    local sp, vis = Camera:WorldToViewportPoint(pos3D)
    if not vis then return math.huge end
    return (Vector2.new(sp.X, sp.Y) - ViewportCenter()).Magnitude
end
local function GetClosest(fov)
    local best, bestDist = nil, fov
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
            local part = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and part and hum.Health > 0 then
                local d = ScreenDist(part.Position)
                if d < bestDist then
                    best     = plr
                    bestDist = d
                end
            end
        end
    end
    return best
end
local function GetPart(plr, name)
    if not plr or not plr.Character then return nil end
    return plr.Character:FindFirstChild(name)
        or plr.Character:FindFirstChild("UpperTorso")
        or plr.Character:FindFirstChild("HumanoidRootPart")
end
local function LerpCFrame(a, b, t)
    return a:Lerp(b, t)
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
local function OnCharacterAdded(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid")
    RootPart  = char:WaitForChild("HumanoidRootPart")
    FlyActive = false
    FlyBG, FlyBV = nil, nil
    Connections["InfJumpChar"] = Humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
        if Cfg.InfiniteJump and Humanoid.Jump then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
if LocalPlayer.Character then OnCharacterAdded(LocalPlayer.Character) end
local function SetupFlyObjects()
    if not RootPart then return end
    local oldBG = RootPart:FindFirstChild("NokoFlyBG")
    local oldBV = RootPart:FindFirstChild("NokoFlyBV")
    if oldBG then oldBG:Destroy() end
    if oldBV then oldBV:Destroy() end
    FlyBG = Instance.new("BodyGyro")
    FlyBG.Name        = "NokoFlyBG"
    FlyBG.MaxTorque   = Vector3.new(9e9, 9e9, 9e9)
    FlyBG.P           = 9e4
    FlyBG.D           = 1e3
    FlyBG.CFrame      = Camera.CFrame
    FlyBG.Parent      = RootPart
    FlyBV = Instance.new("BodyVelocity")
    FlyBV.Name        = "NokoFlyBV"
    FlyBV.MaxForce    = Vector3.new(9e9, 9e9, 9e9)
    FlyBV.Velocity    = Vector3.zero
    FlyBV.Parent      = RootPart
end
local function DestroyFlyObjects()
    if RootPart then
        local bg = RootPart:FindFirstChild("NokoFlyBG")
        local bv = RootPart:FindFirstChild("NokoFlyBV")
        if bg then bg:Destroy() end
        if bv then bv:Destroy() end
    end
    FlyBG, FlyBV = nil, nil
    if Humanoid then Humanoid.PlatformStand = false end
end
local function GetMoveVector()
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        dir = dir + Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        dir = dir - Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        dir = dir - Camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        dir = dir + Camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        dir = dir + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
       UserInputService:IsKeyDown(Enum.KeyCode.C) then
        dir = dir - Vector3.new(0, 1, 0)
    end
    if Humanoid then
        local mobDir = Humanoid.MoveDirection
        if mobDir.Magnitude > 0.05 then
            local camRight   = Camera.CFrame.RightVector
            local camForward = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z).Unit
            dir = dir + camForward * mobDir.Z + camRight * mobDir.X
        end
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then
        dir = dir + Vector3.new(0, 1, 0)
    end
    return dir
end
local ESPColors = {
    Box      = Color3.fromRGB(255, 60, 60),
    Name     = Color3.fromRGB(255, 255, 255),
    Health   = Color3.fromRGB(60, 255, 60),
    Distance = Color3.fromRGB(200, 200, 200),
    Tracer   = Color3.fromRGB(255, 60, 60),
}
local function CreateESPForPlayer(plr)
    if ESPData[plr] then return end
    local function NewLine()
        local l = Drawing.new("Line")
        l.Visible     = false
        l.Color       = ESPColors.Box
        l.Thickness   = 1.2
        l.Transparency = 1
        return l
    end
    local function NewText()
        local t = Drawing.new("Text")
        t.Visible     = false
        t.Size        = 13
        t.Center      = true
        t.Outline     = true
        t.OutlineColor = Color3.fromRGB(0, 0, 0)
        t.Font        = Drawing.Fonts.Plex
        t.Transparency = 1
        return t
    end
    local function NewQuad()
        local q = Drawing.new("Quad")
        q.Visible     = false
        q.Color       = ESPColors.Box
        q.Thickness   = 1.2
        q.Filled      = false
        q.Transparency = 1
        return q
    end
    local hpBG   = Drawing.new("Quad")
    hpBG.Visible  = false
    hpBG.Filled   = true
    hpBG.Color    = Color3.fromRGB(0, 0, 0)
    hpBG.Transparency = 0.6
    local hpFill = Drawing.new("Quad")
    hpFill.Visible  = false
    hpFill.Filled   = true
    hpFill.Color    = ESPColors.Health
    hpFill.Transparency = 1
    ESPData[plr] = {
        Box      = NewQuad(),
        NameTxt  = NewText(),
        HealthTxt= NewText(),
        DistTxt  = NewText(),
        HpBG     = hpBG,
        HpFill   = hpFill,
        Tracer   = NewLine(),
    }
end
local function RemoveESPForPlayer(plr)
    local d = ESPData[plr]
    if not d then return end
    for _, obj in pairs(d) do
        pcall(function() obj:Remove() end)
    end
    ESPData[plr] = nil
end
local function CreateChamsForPlayer(plr)
    if ChamData[plr] or not plr.Character then return end
    local hl = Instance.new("Highlight")
    hl.Name                  = "NokoChams"
    hl.FillColor             = Cfg.ChamColor
    hl.OutlineColor          = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency      = Cfg.ChamTransparency
    hl.OutlineTransparency   = 0
    hl.DepthMode             = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee               = plr.Character
    hl.Parent                = Camera
    ChamData[plr]            = hl
end
local function RemoveChamsForPlayer(plr)
    if ChamData[plr] then
        pcall(function() ChamData[plr]:Destroy() end)
        ChamData[plr] = nil
    end
end
local function UpdateESP()
    local vp = Camera.ViewportSize
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local d = ESPData[plr]
        if not d then continue end
        local char = plr.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local rootSP, rootVis, rootZ = WorldToScreen(root and root.Position or Vector3.zero)
        local headSP, headVis        = WorldToScreen(head and head.Position or Vector3.zero)
        local alive   = hum and hum.Health > 0
        local visible = alive and root and rootVis and rootZ > 0
        local dist = 9999
        if GetChar() and root then
            dist = math.floor(PartDist(RootPart, root))
        end
        local inRange = dist <= Cfg.ESPMaxDist
        local show = Cfg.ESP and visible and inRange
        if show and Cfg.ESPBoxes then
            local topPos    = root.Position + Vector3.new(0, 3.2, 0)
            local botPos    = root.Position - Vector3.new(0, 3.2, 0)
            local topSP, _  = WorldToScreen(topPos)
            local botSP, _  = WorldToScreen(botPos)
            local height = math.abs(topSP.Y - botSP.Y)
            local width  = height * 0.55
            local tl = Vector2.new(rootSP.X - width/2, topSP.Y)
            local tr = Vector2.new(rootSP.X + width/2, topSP.Y)
            local br = Vector2.new(rootSP.X + width/2, botSP.Y)
            local bl = Vector2.new(rootSP.X - width/2, botSP.Y)
            d.Box.PointA    = tl
            d.Box.PointB    = tr
            d.Box.PointC    = br
            d.Box.PointD    = bl
            d.Box.Visible   = true
            local hpRatio   = hum.Health / hum.MaxHealth
            local barW      = 4
            local barLeft   = tl.X - barW - 2
            d.HpBG.PointA   = Vector2.new(barLeft, tl.Y)
            d.HpBG.PointB   = Vector2.new(barLeft + barW, tl.Y)
            d.HpBG.PointC   = Vector2.new(barLeft + barW, bl.Y)
            d.HpBG.PointD   = Vector2.new(barLeft, bl.Y)
            d.HpBG.Visible  = Cfg.ESPHealth
            local fillTop   = tl.Y + height * (1 - hpRatio)
            d.HpFill.PointA = Vector2.new(barLeft, fillTop)
            d.HpFill.PointB = Vector2.new(barLeft + barW, fillTop)
            d.HpFill.PointC = Vector2.new(barLeft + barW, bl.Y)
            d.HpFill.PointD = Vector2.new(barLeft, bl.Y)
            d.HpFill.Color  = Color3.fromHSV(hpRatio * 0.33, 1, 1)
            d.HpFill.Visible = Cfg.ESPHealth
        else
            d.Box.Visible    = false
            d.HpBG.Visible   = false
            d.HpFill.Visible = false
        end
        if show and Cfg.ESPNames then
            d.NameTxt.Text     = plr.DisplayName
            d.NameTxt.Color    = ESPColors.Name
            d.NameTxt.Position = Vector2.new(rootSP.X, headSP.Y - 16)
            d.NameTxt.Visible  = true
        else
            d.NameTxt.Visible = false
        end
        if show and Cfg.ESPDistance then
            d.DistTxt.Text     = dist .. "m"
            d.DistTxt.Color    = ESPColors.Distance
            d.DistTxt.Position = Vector2.new(rootSP.X, headSP.Y - 4)
            d.DistTxt.Visible  = true
        else
            d.DistTxt.Visible = false
        end
        if show and Cfg.ESPHealth then
            d.HealthTxt.Text     = math.floor(hum.Health) .. " HP"
            d.HealthTxt.Color    = ESPColors.Health
            d.HealthTxt.Position = Vector2.new(rootSP.X, (d.Box.PointC and d.Box.PointC.Y or rootSP.Y) + 2)
            d.HealthTxt.Visible  = true
        else
            d.HealthTxt.Visible = false
        end
        if show and Cfg.Tracers then
            local origin
            if Cfg.TracerOrigin == "Bottom" then
                origin = Vector2.new(vp.X / 2, vp.Y)
            elseif Cfg.TracerOrigin == "Center" then
                origin = Vector2.new(vp.X / 2, vp.Y / 2)
            else
                origin = Vector2.new(vp.X / 2, 0)
            end
            d.Tracer.From    = origin
            d.Tracer.To      = rootSP
            d.Tracer.Color   = ESPColors.Tracer
            d.Tracer.Visible = true
        else
            d.Tracer.Visible = false
        end
    end
end
local function OnPlayerAdded(plr)
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        if Cfg.ESP   then CreateESPForPlayer(plr)   end
        if Cfg.Chams then CreateChamsForPlayer(plr) end
    end)
    if plr.Character then
        task.wait(0.3)
        if Cfg.ESP   then CreateESPForPlayer(plr)   end
        if Cfg.Chams then CreateChamsForPlayer(plr) end
    end
end
local function OnPlayerRemoving(plr)
    RemoveESPForPlayer(plr)
    RemoveChamsForPlayer(plr)
end
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then OnPlayerAdded(plr) end
end
Connections["MainLoop"] = RunService.Heartbeat:Connect(function(dt)
    if not GetChar() then return end
    if Cfg.SpeedHack then
        Humanoid.WalkSpeed = Cfg.SpeedValue
    end
    if Cfg.JumpHack then
        Humanoid.JumpPower = Cfg.JumpValue
    end
    if Cfg.Noclip then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    if Cfg.Fly then
        if not FlyBG or not FlyBV then SetupFlyObjects() end
        Humanoid.PlatformStand = true
        local dir   = GetMoveVector()
        local boost = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            or UserInputService:IsKeyDown(Enum.KeyCode.ButtonR2)
        local spd   = boost and Cfg.FlyBoostSpeed or Cfg.FlySpeed
        if FlyBG then FlyBG.CFrame = Camera.CFrame end
        if FlyBV then
            if dir.Magnitude > 0 then
                FlyBV.Velocity = dir.Unit * spd
            else
                FlyBV.Velocity = FlyBV.Velocity * (1 - math.min(dt * 8, 1))
            end
        end
    end
    if Cfg.Aimbot then
        local target = GetClosest(Cfg.AimbotFOV)
        if target then
            local part = GetPart(target, Cfg.AimbotPart)
            if part then
                local targetCF = CFrame.new(Camera.CFrame.Position, part.Position)
                Camera.CFrame  = LerpCFrame(Camera.CFrame, targetCF, Cfg.AimbotSmooth)
            end
        end
    end
    FOVCircle.Visible = (Cfg.Aimbot or Cfg.SilentAim) and Cfg.ShowFOVCircle
    if FOVCircle.Visible then
        local r = Cfg.Aimbot and Cfg.AimbotFOV or Cfg.SilentAimFOV
        FOVCircle.Position = ViewportCenter()
        FOVCircle.Radius   = r
    end
    if Cfg.AutoParry then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local eRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                if eRoot and PartDist(RootPart, eRoot) <= Cfg.AutoParryRange then
                    local remotes = workspace:FindFirstChild("Remotes")
                        or game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                    if remotes then
                        local parryRE = remotes:FindFirstChild("Parry")
                            or remotes:FindFirstChild("Block")
                        if parryRE and parryRE:IsA("RemoteEvent") then
                            pcall(function() parryRE:FireServer() end)
                        end
                    end
                end
            end
        end
    end
end)
Connections["SilentAim"] = RunService.RenderStepped:Connect(function()
    if not Cfg.SilentAim then return end
    local target = GetClosest(Cfg.SilentAimFOV)
    if not target then return end
    local part = GetPart(target, Cfg.SilentAimPart)
    if not part then return end
    local sp, vis = Camera:WorldToViewportPoint(part.Position)
    if vis then
        if Cfg.SilentAimSmooth > 0 then
        end
        Mouse.TargetFilter = Character
    end
end)
Connections["ESPRender"] = RunService.RenderStepped:Connect(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if Cfg.ESP and not ESPData[plr] then
                CreateESPForPlayer(plr)
            end
            if Cfg.Chams and not ChamData[plr] and plr.Character then
                CreateChamsForPlayer(plr)
            end
            if ChamData[plr] and plr.Character then
                ChamData[plr].Adornee = plr.Character
            end
        end
    end
    UpdateESP()
end)
local Window = Rayfield:CreateWindow({
    Name             = "Noko Hub  v2.0",
    Icon             = 0,
    LoadingTitle     = "Noko Hub",
    LoadingSubtitle  = "Rivals | PC & Mobile",
    Theme            = "Default",
    DisableRayfieldPrompts  = false,
    DisableBuildWarnings    = false,
    ConfigurationSaving     = { Enabled = false },
    Discord                 = { Enabled = false },
    KeySystem               = false,
})
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)
CombatTab:CreateSection("Silent Aim")
CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "SilentAim",
    Callback = function(v)
        Cfg.SilentAim = v
        Rayfield:Notify({
            Title   = "Silent Aim",
            Content = v and "Включён" or "Выключен",
            Duration = 2,
        })
    end,
})
CombatTab:CreateSlider({
    Name         = "Silent Aim FOV",
    Range        = {30, 400},
    Increment    = 5,
    Suffix       = "px",
    CurrentValue = 120,
    Flag         = "SilentAimFOV",
    Callback     = function(v) Cfg.SilentAimFOV = v end,
})
CombatTab:CreateDropdown({
    Name          = "Silent Aim Part",
    Options       = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Left Arm", "Right Arm"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Flag          = "SilentAimPart",
    Callback      = function(v) Cfg.SilentAimPart = v[1] end,
})
CombatTab:CreateSection("Aimbot")
CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "Aimbot",
    Callback = function(v)
        Cfg.Aimbot = v
        Rayfield:Notify({
            Title   = "Aimbot",
            Content = v and "Включён" or "Выключен",
            Duration = 2,
        })
    end,
})
CombatTab:CreateSlider({
    Name         = "Aimbot Smooth",
    Range        = {1, 100},
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = 15,
    Flag         = "AimbotSmooth",
    Callback     = function(v)
        Cfg.AimbotSmooth = v / 100
    end,
})
CombatTab:CreateSlider({
    Name         = "Aimbot FOV",
    Range        = {30, 500},
    Increment    = 10,
    Suffix       = "px",
    CurrentValue = 150,
    Flag         = "AimbotFOV",
    Callback     = function(v) Cfg.AimbotFOV = v end,
})
CombatTab:CreateDropdown({
    Name          = "Aimbot Part",
    Options       = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Flag          = "AimbotPart",
    Callback      = function(v) Cfg.AimbotPart = v[1] end,
})
CombatTab:CreateToggle({
    Name         = "Show FOV Circle",
    CurrentValue = true,
    Flag         = "ShowFOV",
    Callback     = function(v) Cfg.ShowFOVCircle = v end,
})
CombatTab:CreateSection("Defense")
CombatTab:CreateToggle({
    Name = "Auto Parry",
    CurrentValue = false,
    Flag = "AutoParry",
    Callback = function(v)
        Cfg.AutoParry = v
        Rayfield:Notify({
            Title   = "Auto Parry",
            Content = v and "Включён" or "Выключен",
            Duration = 2,
        })
    end,
})
CombatTab:CreateSlider({
    Name         = "Parry Range",
    Range        = {3, 25},
    Increment    = 1,
    Suffix       = " studs",
    CurrentValue = 8,
    Flag         = "AutoParryRange",
    Callback     = function(v) Cfg.AutoParryRange = v end,
})
local MoveTab = Window:CreateTab("🏃 Movement", 4483362458)
MoveTab:CreateSection("Speed")
MoveTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedHack",
    Callback = function(v)
        Cfg.SpeedHack = v
        if not v and GetChar() then Humanoid.WalkSpeed = 16 end
        Rayfield:Notify({
            Title   = "Speed Hack",
            Content = v and ("Включён | " .. Cfg.SpeedValue .. " WS") or "Выключен",
            Duration = 2,
        })
    end,
})
MoveTab:CreateSlider({
    Name         = "Walk Speed",
    Range        = {16, 500},
    Increment    = 2,
    Suffix       = " WS",
    CurrentValue = 32,
    Flag         = "SpeedValue",
    Callback     = function(v) Cfg.SpeedValue = v end,
})
MoveTab:CreateSection("Jump")
MoveTab:CreateToggle({
    Name = "Jump Hack",
    CurrentValue = false,
    Flag = "JumpHack",
    Callback = function(v)
        Cfg.JumpHack = v
        if not v and GetChar() then Humanoid.JumpPower = 50 end
        Rayfield:Notify({
            Title   = "Jump Hack",
            Content = v and ("Включён | " .. Cfg.JumpValue .. " JP") or "Выключен",
            Duration = 2,
        })
    end,
})
MoveTab:CreateSlider({
    Name         = "Jump Power",
    Range        = {50, 1000},
    Increment    = 10,
    Suffix       = " JP",
    CurrentValue = 100,
    Flag         = "JumpValue",
    Callback     = function(v) Cfg.JumpValue = v end,
})
MoveTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(v)
        Cfg.InfiniteJump = v
        Rayfield:Notify({
            Title   = "Infinite Jump",
            Content = v and "Включён" or "Выключен",
            Duration = 2,
        })
    end,
})
MoveTab:CreateSection("Advanced")
MoveTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v)
        Cfg.Noclip = v
        Rayfield:Notify({
            Title   = "Noclip",
            Content = v and "Включён" or "Выключен",
            Duration = 2,
        })
    end,
})
MoveTab:CreateToggle({
    Name = "Fly  [Shift = Boost / Mobile: джойстик]",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v)
        Cfg.Fly = v
        if v then
            SetupFlyObjects()
        else
            DestroyFlyObjects()
        end
        Rayfield:Notify({
            Title   = "Fly",
            Content = v and "Включён" or "Выключен",
            Duration = 2,
        })
    end,
})
MoveTab:CreateSlider({
    Name         = "Fly Speed",
    Range        = {10, 500},
    Increment    = 5,
    Suffix       = " FS",
    CurrentValue = 60,
    Flag         = "FlySpeed",
    Callback     = function(v) Cfg.FlySpeed = v end,
})
MoveTab:CreateSlider({
    Name         = "Fly Boost Speed (Shift)",
    Range        = {50, 1000},
    Increment    = 10,
    Suffix       = " FS",
    CurrentValue = 150,
    Flag         = "FlyBoostSpeed",
    Callback     = function(v) Cfg.FlyBoostSpeed = v end,
})
local VisualTab = Window:CreateTab("👁️ Visuals", 4483362458)
VisualTab:CreateSection("ESP")
VisualTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v)
        Cfg.ESP = v
        if not v then
            for _, plr in ipairs(Players:GetPlayers()) do
                RemoveESPForPlayer(plr)
            end
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then CreateESPForPlayer(plr) end
            end
        end
        Rayfield:Notify({
            Title   = "ESP",
            Content = v and "Включён" or "Выключен",
            Duration = 2,
        })
    end,
})
VisualTab:CreateToggle({
    Name = "ESP Boxes",
    CurrentValue = true,
    Flag = "ESPBoxes",
    Callback = function(v) Cfg.ESPBoxes = v end,
})
VisualTab:CreateToggle({
    Name = "ESP Names",
    CurrentValue = true,
    Flag = "ESPNames",
    Callback = function(v) Cfg.ESPNames = v end,
})
VisualTab:CreateToggle({
    Name = "ESP Health Bar",
    CurrentValue = true,
    Flag = "ESPHealth",
    Callback = function(v) Cfg.ESPHealth = v end,
})
VisualTab:CreateToggle({
    Name = "ESP Distance",
    CurrentValue = true,
    Flag = "ESPDistance",
    Callback = function(v) Cfg.ESPDistance = v end,
})
VisualTab:CreateSlider({
    Name         = "ESP Max Distance",
    Range        = {50, 2000},
    Increment    = 50,
    Suffix       = "m",
    CurrentValue = 500,
    Flag         = "ESPMaxDist",
    Callback     = function(v) Cfg.ESPMaxDist = v end,
})
VisualTab:CreateSection("Chams")
VisualTab:CreateToggle({
    Name = "Chams (Highlight)",
    CurrentValue = false,
    Flag = "Chams",
    Callback = function(v)
        Cfg.Chams = v
        if not v then
            for _, plr in ipairs(Players:GetPlayers()) do
                RemoveChamsForPlayer(plr)
            end
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then CreateChamsForPlayer(plr) end
            end
        end
        Rayfield:Notify({
            Title   = "Chams",
            Content = v and "Включён" or "Выключен",
            Duration = 2,
        })
    end,
})
VisualTab:CreateSlider({
    Name         = "Chams Transparency",
    Range        = {0, 100},
    Increment    = 5,
    Suffix       = "%",
    CurrentValue = 50,
    Flag         = "ChamTransp",
    Callback     = function(v)
        Cfg.ChamTransparency = v / 100
        for _, hl in pairs(ChamData) do
            hl.FillTransparency = Cfg.ChamTransparency
        end
    end,
})
VisualTab:CreateSection("Tracers")
VisualTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = false,
    Flag = "Tracers",
    Callback = function(v)
        Cfg.Tracers = v
        Rayfield:Notify({
            Title   = "Tracers",
            Content = v and "Включён" or "Выключен",
            Duration = 2,
        })
    end,
})
VisualTab:CreateDropdown({
    Name          = "Tracer Origin",
    Options       = {"Bottom", "Center", "Top"},
    CurrentOption = {"Bottom"},
    MultipleOptions = false,
    Flag          = "TracerOrigin",
    Callback      = function(v) Cfg.TracerOrigin = v[1] end,
})
VisualTab:CreateSection("Environment")
VisualTab:CreateToggle({
    Name = "FullBright",
    CurrentValue = false,
    Flag = "FullBright",
    Callback = function(v)
        Cfg.FullBright = v
        if v then
            Lighting.Ambient        = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness     = Cfg.FullBrightValue
            Lighting.ClockTime      = 14
            Lighting.FogEnd         = 100000
            for _, ef in ipairs(Lighting:GetChildren()) do
                if ef:IsA("BlurEffect") or ef:IsA("ColorCorrectionEffect")
                or ef:IsA("SunRaysEffect") or ef:IsA("DepthOfFieldEffect") then
                    ef.Enabled = false
                end
            end
        else
            Lighting.Ambient        = Color3.fromRGB(127, 127, 127)
            Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
            Lighting.Brightness     = 1
            for _, ef in ipairs(Lighting:GetChildren()) do
                if ef:IsA("PostEffect") then ef.Enabled = true end
            end
        end
        Rayfield:Notify({
            Title   = "FullBright",
            Content = v and "Включён" or "Выключен",
            Duration = 2,
        })
    end,
})
VisualTab:CreateSlider({
    Name         = "Brightness Level",
    Range        = {1, 10},
    Increment    = 1,
    Suffix       = "x",
    CurrentValue = 2,
    Flag         = "BrightnessLevel",
    Callback     = function(v)
        Cfg.FullBrightValue = v
        if Cfg.FullBright then Lighting.Brightness = v end
    end,
})
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)
MiscTab:CreateSection("Utility")
MiscTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
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
        Rayfield:Notify({
            Title   = "Anti AFK",
            Content = v and "Включён" or "Выключен",
            Duration = 2,
        })
    end,
})
MiscTab:CreateToggle({
    Name = "Auto Rejoin",
    CurrentValue = false,
    Flag = "AutoRejoin",
    Callback = function(v)
        Cfg.AutoRejoin = v
        Disconnect("AutoRejoin")
        if v then
            Connections["AutoRejoin"] = LocalPlayer.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.Failed then
                    task.wait(2)
                    pcall(function()
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    end)
                end
            end)
        end
        Rayfield:Notify({
            Title   = "Auto Rejoin",
            Content = v and "Включён" or "Выключен",
            Duration = 2,
        })
    end,
})
MiscTab:CreateSection("Performance")
MiscTab:CreateToggle({
    Name = "FPS Boost",
    CurrentValue = false,
    Flag = "FPSBoost",
    Callback = function(v)
        Cfg.FPSBoost = v
        if v then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            workspace.StreamingEnabled = pcall(function()
                Camera.FieldOfView = 70
            end)
        else
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        end
        Rayfield:Notify({
            Title   = "FPS Boost",
            Content = v and "Включён | Качество: Мин" or "Выключен | Качество: Авто",
            Duration = 2,
        })
    end,
})
MiscTab:CreateSection("Server")
MiscTab:CreateButton({
    Name = "🔄  Rejoin Server",
    Callback = function()
        Rayfield:Notify({
            Title   = "Rejoin",
            Content = "Переподключение через 2 сек...",
            Duration = 2,
        })
        task.wait(2)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end,
})
MiscTab:CreateButton({
    Name = "📋  Копировать PlaceId",
    Callback = function()
        setclipboard(tostring(game.PlaceId))
        Rayfield:Notify({
            Title   = "Скопировано",
            Content = "PlaceId: " .. game.PlaceId,
            Duration = 3,
        })
    end,
})
game:BindToClose(function()
    FOVCircle:Remove()
    for _, plr in ipairs(Players:GetPlayers()) do
        RemoveESPForPlayer(plr)
        RemoveChamsForPlayer(plr)
    end
    for _, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    DestroyFlyObjects()
end)
Rayfield:Notify({
    Title   = "Noko Hub  v2.0",
    Content = "Загружен успешно! | Rivals",
    Duration = 5,
    Image   = 4483362458,
})
print("[Noko Hub v2.0] Loaded | Rivals | " .. os.date("%H:%M:%S"))
