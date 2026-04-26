local Rayfield         = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local VirtualUser      = game:GetService("VirtualUser")
local TeleportService  = game:GetService("TeleportService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera
local Mouse            = LocalPlayer:GetMouse()
local IsMobile         = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Cfg = {
    -- Shoot Murder / Gun Aimbot
    ShootMurder      = false,
    GunAimbot        = false,

    ESP              = false,
    ESPBoxes         = true,
    ESPNames         = true,
    ESPHealth        = true,
    ESPDistance      = true,
    ESPRoles         = true,
    ESPMaxDist       = 500,

    Chams            = false,
    ChamTransparency = 0.5,

    Tracers          = false,
    TracerOrigin     = "Bottom",

    RoleChams        = false,

    CoinFarm         = false,
    CoinESP          = false,
    CoinFarmDelay    = 0.1,

    GunESP           = false,

    TpToMurderer     = false,
    TpToSheriff      = false,

    KillAura         = false,
    KillAuraRange    = 8,

    FlingTimeout     = 2.5,

    InfiniteStamina  = false,
    AlwaysSprint     = false,
    AutoPickupGun    = false,

    SpeedHack        = false,
    SpeedValue       = 32,
    JumpHack         = false,
    JumpValue        = 100,
    InfiniteJump     = false,
    Noclip           = false,
    Fly              = false,
    FlySpeed         = 60,
    FlyBoostSpeed    = 150,

    FullBright       = false,
    FullBrightValue  = 2,

    SecondsLife      = false,
    TouchFling       = false,
    NoclipPlayers    = false,

    AntiAFK          = false,
    FPSBoost         = false,
}

local RoleColors = {
    Murderer = Color3.fromRGB(255, 50,  50),
    Sheriff  = Color3.fromRGB(255, 215, 0),
    Innocent = Color3.fromRGB(80,  255, 80),
}

local KnifeNames = {"Knife", "Godly", "knife", "MM2Knife"}
local GunNames   = {"Sheriff", "Gun", "Revolver", "sheriff", "MM2Gun"}

local function GetRole(plr)
    if not plr or not plr.Character then return "Innocent" end
    for _, tool in ipairs(plr.Character:GetChildren()) do
        if tool:IsA("Tool") then
            local n = tool.Name:lower()
            for _, kn in ipairs(KnifeNames) do
                if n:find(kn:lower()) then return "Murderer" end
            end
            for _, gn in ipairs(GunNames) do
                if n:find(gn:lower()) then return "Sheriff" end
            end
        end
    end
    local bp = plr:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                for _, kn in ipairs(KnifeNames) do
                    if n:find(kn:lower()) then return "Murderer" end
                end
                for _, gn in ipairs(GunNames) do
                    if n:find(gn:lower()) then return "Sheriff" end
                end
            end
        end
    end
    local rv = plr:FindFirstChild("Role")
    if rv and rv:IsA("StringValue") then return rv.Value end
    return "Innocent"
end

local function GetMyRole()
    return GetRole(LocalPlayer)
end

local BodyPartAliases = {
    ["Head"]       = {"Head"},
    ["UpperTorso"] = {"UpperTorso", "Torso"},
    ["LowerTorso"] = {"LowerTorso"},
    ["Left Arm"]   = {"LeftUpperArm", "LeftLowerArm", "Left Arm"},
    ["Right Arm"]  = {"RightUpperArm", "RightLowerArm", "Right Arm"},
    ["Left Leg"]   = {"LeftUpperLeg",  "LeftLowerLeg",  "Left Leg"},
    ["Right Leg"]  = {"RightUpperLeg", "RightLowerLeg", "Right Leg"},
    ["Root"]       = {"HumanoidRootPart"},
}

local Character, Humanoid, RootPart
local Connections   = {}
local ESPData       = {}
local ChamData      = {}
local RoleChamData  = {}
local FlyBG, FlyBV  = nil, nil
local CoinESPData   = {}
local GunESPData    = { highlight = nil, billboard = nil }
local GunBotConn    = nil

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
    if IsMobile then return Camera.ViewportSize.X / 1280 end
    return 1
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

local function GetMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 and GetRole(plr) == "Murderer" then
                return plr
            end
        end
    end
    return nil
end

-- GetMurdererTarget — через RemoteFunction (как в оригинальном открытом скрипте)
local function GetMurdererTarget()
    local ok, data = pcall(function()
        return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    end)
    if not ok or type(data) ~= "table" then return nil, false end
    for plrName, plrData in pairs(data) do
        if plrData.Role == "Murderer" then
            local player = Players:FindFirstChild(plrName)
            if player then
                if player == LocalPlayer then return nil, true end
                local char = player.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then return hrp.Position, false end
                    local head = char:FindFirstChild("Head")
                    if head then return head.Position, false end
                end
            end
        end
    end
    return nil, false
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
    -- Обновить GodMode при respawn
    Disconnect("GodCon")
    if Cfg.SecondsLife then
        Connections["GodCon"] = Humanoid.HealthChanged:Connect(function()
            if Cfg.SecondsLife and Humanoid.Health < Humanoid.MaxHealth then
                Humanoid.Health = Humanoid.MaxHealth
            end
        end)
    end
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
    FlyBG.Name = "NokoFlyBG"; FlyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
    FlyBG.P = 9e4; FlyBG.D = 1e3; FlyBG.CFrame = Camera.CFrame; FlyBG.Parent = RootPart
    FlyBV = Instance.new("BodyVelocity")
    FlyBV.Name = "NokoFlyBV"; FlyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
    FlyBV.Velocity = Vector3.zero; FlyBV.Parent = RootPart
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

local function GetFlyDir()
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or
       UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
       UserInputService:IsKeyDown(Enum.KeyCode.C) then dir = dir - Vector3.new(0,1,0) end
    if Humanoid then
        local mob = Humanoid.MoveDirection
        if mob.Magnitude > 0.05 then
            local cf  = Camera.CFrame
            local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
            dir = dir + fwd * (-mob.Z) + cf.RightVector * mob.X
        end
    end
    return dir
end

-- ─── DoFling (адаптировано из SHubFling) ────────────────────────────────────
local function DoFling(targetPlayer)
    if not GetChar() then return end
    local TCharacter = targetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead     = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle    = Accessory and Accessory:FindFirstChild("Handle")
    local OldPos    = RootPart.CFrame

    repeat task.wait()
        Camera.CameraSubject = THead or Handle or THumanoid
    until Camera.CameraSubject == THead or Handle or THumanoid

    local function FPos(BasePart, Pos, Ang)
        local targetCF = CFrame.new(BasePart.Position) * Pos * Ang
        RootPart.CFrame = targetCF
        Character:SetPrimaryPartCFrame(targetCF)
        RootPart.Velocity    = Vector3.new(9e7, 9e8, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local function SFBasePart(BasePart)
        local start = tick()
        local angle = 0
        repeat
            if RootPart and THumanoid then
                angle = angle + 100
                for _, offset in ipairs{
                    CFrame.new(0,1.5,0),
                    CFrame.new(0,-1.5,0),
                    CFrame.new(2.25,1.5,-2.25),
                    CFrame.new(-2.25,-1.5,2.25),
                } do
                    FPos(BasePart, offset + THumanoid.MoveDirection, CFrame.Angles(math.rad(angle), 0, 0))
                    task.wait()
                end
            end
        until BasePart.Velocity.Magnitude > 500 or tick() - start > Cfg.FlingTimeout
    end

    local BV = Instance.new("BodyVelocity")
    BV.Name     = "NokoFlingVel"
    BV.Velocity  = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    BV.Parent   = RootPart

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    local target = TRootPart or THead or Handle
    if target then SFBasePart(target) end
    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)

    repeat task.wait()
        Camera.CameraSubject = Humanoid
    until Camera.CameraSubject == Humanoid

    repeat
        local cf = OldPos * CFrame.new(0, 0.5, 0)
        RootPart.CFrame = cf
        Character:SetPrimaryPartCFrame(cf)
        Humanoid:ChangeState("GettingUp")
        for _, part in ipairs(Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Velocity    = Vector3.zero
                part.RotVelocity = Vector3.zero
            end
        end
        task.wait()
    until (RootPart.Position - OldPos.p).Magnitude < 25
end

-- ─── ESP Utils ───────────────────────────────────────────────────────────────
local ESPColor = {
    Box  = Color3.fromRGB(255, 60, 60),
    Name = Color3.fromRGB(255, 255, 255),
    Dist = Color3.fromRGB(180, 180, 180),
    Trc  = Color3.fromRGB(255, 60, 60),
    Role = Color3.fromRGB(255, 215, 0),
}

local function NewText(size)
    local t = Drawing.new("Text")
    t.Visible = false; t.Size = size or 13; t.Center = true
    t.Outline = true; t.OutlineColor = Color3.fromRGB(0,0,0)
    t.Font = Drawing.Fonts.Plex; t.Transparency = 1
    return t
end

local function NewQuad(filled)
    local q = Drawing.new("Quad")
    q.Visible = false; q.Filled = filled or false
    q.Color = ESPColor.Box; q.Thickness = 1.4; q.Transparency = 1
    return q
end

local function NewLine()
    local l = Drawing.new("Line")
    l.Visible = false; l.Color = ESPColor.Trc; l.Thickness = 1.2; l.Transparency = 1
    return l
end

local function CreateESP(plr)
    if ESPData[plr] then return end
    local hpBG   = NewQuad(true); hpBG.Color = Color3.fromRGB(0,0,0); hpBG.Transparency = 0.55
    local hpFill = NewQuad(true); hpFill.Color = Color3.fromRGB(60,255,60)
    ESPData[plr] = {
        Box     = NewQuad(false),
        NameTxt = NewText(13),
        HpTxt   = NewText(11),
        DistTxt = NewText(11),
        RoleTxt = NewText(12),
        HpBG    = hpBG,
        HpFill  = hpFill,
        Tracer  = NewLine(),
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
    hl.Name = "NokoChams"; hl.FillColor = Color3.fromRGB(255,60,60)
    hl.OutlineColor = Color3.fromRGB(255,255,255)
    hl.FillTransparency = Cfg.ChamTransparency; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = plr.Character; hl.Parent = Camera
    ChamData[plr] = hl
end

local function RemoveChams(plr)
    if ChamData[plr] then pcall(function() ChamData[plr]:Destroy() end); ChamData[plr] = nil end
end

local function CreateRoleChams(plr)
    if RoleChamData[plr] or not plr.Character then return end
    local role = GetRole(plr)
    local col  = RoleColors[role] or RoleColors.Innocent
    local hl   = Instance.new("Highlight")
    hl.Name    = "NokoRoleChams"
    hl.FillColor = col; hl.OutlineColor = col
    hl.FillTransparency = 0.4; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = plr.Character; hl.Parent = Camera
    RoleChamData[plr] = hl
end

local function RemoveRoleChams(plr)
    if RoleChamData[plr] then pcall(function() RoleChamData[plr]:Destroy() end); RoleChamData[plr] = nil end
end

local function UpdateRoleChams()
    if not Cfg.RoleChams then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if not RoleChamData[plr] and plr.Character then
                CreateRoleChams(plr)
            end
            if RoleChamData[plr] then
                local role = GetRole(plr)
                local col  = RoleColors[role] or RoleColors.Innocent
                RoleChamData[plr].FillColor    = col
                RoleChamData[plr].OutlineColor = col
                if plr.Character then
                    RoleChamData[plr].Adornee = plr.Character
                end
            end
        end
    end
end

-- ─── Gun Drop ESP ────────────────────────────────────────────────────────────
local function UpdateGunESP()
    local gun = workspace:FindFirstChild("GunDrop", true)
    if not Cfg.GunESP then
        if GunESPData.highlight then pcall(function() GunESPData.highlight:Destroy() end); GunESPData.highlight = nil end
        if GunESPData.billboard then pcall(function() GunESPData.billboard:Destroy() end); GunESPData.billboard = nil end
        return
    end
    if gun then
        if not GunESPData.highlight or not GunESPData.highlight.Parent then
            local hl = Instance.new("Highlight", gun)
            hl.Name = "NokoGunHL"
            hl.FillColor = Color3.new(1, 1, 0)
            hl.OutlineColor = Color3.new(1, 1, 1)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillTransparency = 0.4
            hl.OutlineTransparency = 0.5
            GunESPData.highlight = hl
        end
        if not GunESPData.billboard or not GunESPData.billboard.Parent then
            local esp = Instance.new("BillboardGui", gun)
            esp.Name = "NokoGunBB"
            esp.Size = UDim2.new(5, 0, 5, 0)
            esp.AlwaysOnTop = true
            local lbl = Instance.new("TextLabel", esp)
            lbl.Name = "GunLabel"
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextStrokeTransparency = 0
            lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
            lbl.Font = Enum.Font.FredokaOne
            lbl.TextSize = 16
            lbl.Text = "🔫 Gun Drop"
            GunESPData.billboard = esp
        end
    else
        if GunESPData.highlight then pcall(function() GunESPData.highlight:Destroy() end); GunESPData.highlight = nil end
        if GunESPData.billboard then pcall(function() GunESPData.billboard:Destroy() end); GunESPData.billboard = nil end
    end
end

local function FindCoins()
    local coins = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "Coin" or obj.Name:lower():find("coin")) then
            table.insert(coins, obj)
        end
    end
    return coins
end

local function UpdateCoinESP()
    for coin, label in pairs(CoinESPData) do
        if not coin or not coin.Parent then
            pcall(function() label:Remove() end)
            CoinESPData[coin] = nil
        end
    end
    if not Cfg.CoinESP then
        for _, label in pairs(CoinESPData) do
            pcall(function() label.Visible = false end)
        end
        return
    end
    local coins = FindCoins()
    for _, coin in ipairs(coins) do
        local sp, vis, z = W2S(coin.Position)
        if vis and z > 0 then
            if not CoinESPData[coin] then
                local t = Drawing.new("Text")
                t.Text = "🪙"; t.Size = 16; t.Center = true
                t.Color = Color3.fromRGB(255, 215, 0)
                t.Outline = true; t.OutlineColor = Color3.fromRGB(0,0,0)
                t.Transparency = 1; t.Visible = true
                CoinESPData[coin] = t
            end
            CoinESPData[coin].Position = sp
            CoinESPData[coin].Visible  = true
        else
            if CoinESPData[coin] then
                CoinESPData[coin].Visible = false
            end
        end
    end
end

local lastCoinFarm = 0
local function DoCoinFarm()
    if not Cfg.CoinFarm then return end
    if not GetChar() then return end
    local now = tick()
    if now - lastCoinFarm < Cfg.CoinFarmDelay then return end
    lastCoinFarm = now
    local coins = FindCoins()
    local nearest, nearDist = nil, math.huge
    for _, coin in ipairs(coins) do
        local d = (RootPart.Position - coin.Position).Magnitude
        if d < nearDist then nearest = coin; nearDist = d end
    end
    if nearest then
        pcall(function()
            RootPart.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 3, 0))
        end)
    end
end

local function DoKillAura()
    if not Cfg.KillAura then return end
    if GetMyRole() ~= "Murderer" then return end
    if not GetChar() then return end
    local knife = nil
    for _, tool in ipairs(Character:GetChildren()) do
        if tool:IsA("Tool") then
            local n = tool.Name:lower()
            for _, kn in ipairs(KnifeNames) do
                if n:find(kn:lower()) then knife = tool; break end
            end
        end
    end
    if not knife then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                if PartDist(RootPart, root) <= Cfg.KillAuraRange then
                    local savedCF = RootPart.CFrame
                    pcall(function()
                        RootPart.CFrame = root.CFrame * CFrame.new(0, 0, -2)
                    end)
                    pcall(function()
                        local activate = knife:FindFirstChild("Activate")
                            or knife:FindFirstChild("RemoteEvent")
                        if activate and activate:IsA("RemoteEvent") then
                            activate:FireServer()
                        end
                    end)
                    pcall(function()
                        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                            or ReplicatedStorage:FindFirstChild("Events")
                        if remotes then
                            for _, rem in ipairs(remotes:GetChildren()) do
                                if rem:IsA("RemoteEvent") then
                                    local n = rem.Name:lower()
                                    if n:find("kill") or n:find("stab") or n:find("attack") then
                                        rem:FireServer(plr)
                                    end
                                end
                            end
                        end
                    end)
                    pcall(function() RootPart.CFrame = savedCF end)
                end
            end
        end
    end
end

local function DoAutoPickupGun()
    if not Cfg.AutoPickupGun then return end
    if not GetChar() then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") then
            local n = obj.Name:lower()
            for _, gn in ipairs(GunNames) do
                if n:find(gn:lower()) and not obj.Parent:IsA("Model") then
                    local pos = obj:FindFirstChild("Handle")
                    if pos then
                        local d = (RootPart.Position - pos.Position).Magnitude
                        if d < 15 then
                            pcall(function()
                                RootPart.CFrame = CFrame.new(pos.Position + Vector3.new(0,3,0))
                            end)
                        end
                    end
                end
            end
        end
    end
end

local function GetPlayerByRole(role)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and GetRole(plr) == role then
            return plr
        end
    end
    return nil
end

local function UpdateESP()
    local vp = Camera.ViewportSize
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end

        if Cfg.ESP and not ESPData[plr] then
            CreateESP(plr)
        end

        local d = ESPData[plr]
        if not d then continue end

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
        local headSP                  = W2S(head.Position)
        local alive   = hum.Health > 0
        local dist3D  = GetChar() and RootPart and math.floor(PartDist(RootPart, root)) or 9999
        local show    = Cfg.ESP and rootVis and rootZ > 0 and alive and dist3D <= Cfg.ESPMaxDist

        local role    = GetRole(plr)
        local roleCol = RoleColors[role] or RoleColors.Innocent

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
            d.Box.Color  = roleCol
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
                d.HpBG.Visible = false; d.HpFill.Visible = false
            end
        else
            d.Box.Visible = false; d.HpBG.Visible = false; d.HpFill.Visible = false
        end

        if show and Cfg.ESPNames then
            d.NameTxt.Text     = plr.DisplayName
            d.NameTxt.Color    = Color3.fromRGB(255, 255, 255)
            d.NameTxt.Position = Vector2.new(rootSP.X, headSP.Y - 18)
            d.NameTxt.Visible  = true
        else d.NameTxt.Visible = false end

        if show and Cfg.ESPHealth then
            d.HpTxt.Text     = math.floor(hum.Health) .. " HP"
            d.HpTxt.Color    = Color3.fromHSV(math.clamp(hum.Health/hum.MaxHealth,0,1)*0.33,1,1)
            d.HpTxt.Position = Vector2.new(rootSP.X, headSP.Y - 7)
            d.HpTxt.Visible  = true
        else d.HpTxt.Visible = false end

        if show and Cfg.ESPDistance then
            d.DistTxt.Text     = dist3D .. "m"
            d.DistTxt.Color    = Color3.fromRGB(180,180,180)
            d.DistTxt.Position = Vector2.new(rootSP.X, (d.Box.PointC and d.Box.PointC.Y or rootSP.Y) + 3)
            d.DistTxt.Visible  = true
        else d.DistTxt.Visible = false end

        if show and Cfg.ESPRoles then
            local roleLabel = role == "Murderer" and "🔪 MURDERER"
                           or role == "Sheriff"  and "🔫 SHERIFF"
                           or                       "😇 Innocent"
            d.RoleTxt.Text     = roleLabel
            d.RoleTxt.Color    = roleCol
            d.RoleTxt.Position = Vector2.new(rootSP.X, headSP.Y - 30)
            d.RoleTxt.Visible  = true
        else d.RoleTxt.Visible = false end

        if show and Cfg.Tracers then
            local origin = Cfg.TracerOrigin == "Bottom" and Vector2.new(vp.X/2, vp.Y)
                        or Cfg.TracerOrigin == "Center"  and Vector2.new(vp.X/2, vp.Y/2)
                        or                                   Vector2.new(vp.X/2, 0)
            d.Tracer.From = origin; d.Tracer.To = rootSP
            d.Tracer.Color = roleCol
            d.Tracer.Visible = true
        else d.Tracer.Visible = false end
    end
end

local function OnPlayerAdded(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.3)
        if Cfg.ESP       then CreateESP(plr)       end
        if Cfg.Chams     then CreateChams(plr)     end
        if Cfg.RoleChams then CreateRoleChams(plr) end
    end)
    if plr.Character then
        if Cfg.ESP       then CreateESP(plr)       end
        if Cfg.Chams     then CreateChams(plr)     end
        if Cfg.RoleChams then CreateRoleChams(plr) end
    end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(function(plr)
    RemoveESP(plr); RemoveChams(plr); RemoveRoleChams(plr)
end)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then OnPlayerAdded(plr) end
end

-- ─── RunService Loops ────────────────────────────────────────────────────────
Connections["RenderStepped"] = RunService.RenderStepped:Connect(function(dt)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if Cfg.ESP and not ESPData[plr] then CreateESP(plr) end
            if Cfg.Chams and not ChamData[plr] and plr.Character then CreateChams(plr) end
            if ChamData[plr] and plr.Character then ChamData[plr].Adornee = plr.Character end
        end
    end
    UpdateESP()
    UpdateRoleChams()
    UpdateCoinESP()
    UpdateGunESP()
end)

Connections["Heartbeat"] = RunService.Heartbeat:Connect(function(dt)
    if not GetChar() then return end
    if Cfg.SpeedHack then Humanoid.WalkSpeed = Cfg.SpeedValue end
    if Cfg.JumpHack  then Humanoid.JumpPower = Cfg.JumpValue  end
    if Cfg.InfiniteStamina then
        local stamina = Character:FindFirstChild("Stamina")
            or LocalPlayer:FindFirstChild("Stamina")
        if stamina then
            pcall(function() stamina.Value = stamina.MaxValue or 100 end)
        end
    end
    if Cfg.AlwaysSprint then
        local sprint = Character:FindFirstChildWhichIsA("BoolValue")
        if sprint and sprint.Name:lower():find("sprint") then
            pcall(function() sprint.Value = true end)
        end
    end
    if Cfg.Noclip then
        for _, p in ipairs(Character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
    -- Noclip Players (Anti-Fling)
    if Cfg.NoclipPlayers then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                for _, v in ipairs(plr.Character:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide = false
                    end
                end
            end
        end
    end
    -- Touch Fling
    if Cfg.TouchFling then
        local vel = RootPart.Velocity
        RootPart.Velocity = vel * 9e8 + Vector3.new(0, 9e8, 0)
        task.wait()
        if RootPart and RootPart.Parent then
            RootPart.Velocity = vel
        end
    end
    if Cfg.Fly then
        if not FlyBG or not FlyBV then SetupFly() end
        Humanoid.PlatformStand = true
        local dir   = GetFlyDir()
        local boost = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        local spd   = boost and Cfg.FlyBoostSpeed or Cfg.FlySpeed
        if FlyBG then FlyBG.CFrame = Camera.CFrame end
        if FlyBV then
            FlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * spd
                          or FlyBV.Velocity * math.max(0, 1 - dt * 10)
        end
    end
    DoKillAura()
    DoCoinFarm()
    DoAutoPickupGun()
    if Cfg.TpToMurderer then
        local m = GetPlayerByRole("Murderer")
        if m and m.Character then
            local r = m.Character:FindFirstChild("HumanoidRootPart")
            if r then pcall(function() RootPart.CFrame = r.CFrame * CFrame.new(0, 0, 4) end) end
        end
    end
    if Cfg.TpToSheriff then
        local s = GetPlayerByRole("Sheriff")
        if s and s.Character then
            local r = s.Character:FindFirstChild("HumanoidRootPart")
            if r then pcall(function() RootPart.CFrame = r.CFrame * CFrame.new(0, 0, 4) end) end
        end
    end
end)

-- ─── UI ──────────────────────────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name            = "Noko Hub  |  Murder Mystery 2",
    Icon            = 0,
    LoadingTitle    = "Noko Hub",
    LoadingSubtitle = "Murder Mystery 2  |  v2.1.0  |  " .. (IsMobile and "📱 Mobile" or "🖥️ PC"),
    Theme           = "Default",
    DisableRayfieldPrompts   = false,
    DisableBuildWarnings     = false,
    ConfigurationSaving      = { Enabled = false },
    Discord                  = { Enabled = false },
    KeySystem                = false,
})

local MM2Tab    = Window:CreateTab("🔪 MM2",      4483362458)
local CombatTab = Window:CreateTab("⚔️ Combat",   4483362458)
local MoveTab   = Window:CreateTab("🏃 Movement", 4483362458)
local VisualTab = Window:CreateTab("👁️ Visuals",  4483362458)
local MiscTab   = Window:CreateTab("⚙️ Misc",     4483362458)

-- ═══════════════════════════════════════════════════════════
-- MM2 TAB
-- ═══════════════════════════════════════════════════════════
MM2Tab:CreateSection("🎭 Roles")
MM2Tab:CreateToggle({
    Name = "Role ESP (🔪/🔫/😇)",
    CurrentValue = true, Flag = "ESPRoles",
    Callback = function(v) Cfg.ESPRoles = v end,
})
MM2Tab:CreateToggle({
    Name = "Role Chams (color by role)",
    CurrentValue = false, Flag = "RoleChams",
    Callback = function(v)
        Cfg.RoleChams = v
        if not v then
            for _, plr in ipairs(Players:GetPlayers()) do RemoveRoleChams(plr) end
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then CreateRoleChams(plr) end
            end
        end
        Rayfield:Notify({ Title = "Role Chams", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})

MM2Tab:CreateSection("💰 Coins")
MM2Tab:CreateToggle({
    Name = "Coin ESP",
    CurrentValue = false, Flag = "CoinESP",
    Callback = function(v)
        Cfg.CoinESP = v
        if not v then
            for _, label in pairs(CoinESPData) do pcall(function() label.Visible = false end) end
        end
        Rayfield:Notify({ Title = "Coin ESP", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MM2Tab:CreateToggle({
    Name = "Coin Farm (auto collect)",
    CurrentValue = false, Flag = "CoinFarm",
    Callback = function(v)
        Cfg.CoinFarm = v
        Rayfield:Notify({ Title = "Coin Farm", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MM2Tab:CreateSlider({
    Name = "Coin Farm Delay",
    Range = {0, 1}, Increment = 0.05, Suffix = "s",
    CurrentValue = 0.1, Flag = "CoinFarmDelay",
    Callback = function(v) Cfg.CoinFarmDelay = v end,
})

MM2Tab:CreateSection("🗡️ Murderer")
MM2Tab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false, Flag = "KillAura",
    Callback = function(v)
        Cfg.KillAura = v
        Rayfield:Notify({ Title = "Kill Aura", Content = v and "ON (Murderer only)" or "OFF", Duration = 2 })
    end,
})
MM2Tab:CreateSlider({
    Name = "Kill Aura Range",
    Range = {3, 30}, Increment = 1, Suffix = " studs",
    CurrentValue = 8, Flag = "KillAuraRange",
    Callback = function(v) Cfg.KillAuraRange = v end,
})

MM2Tab:CreateSection("💥 Fling")
MM2Tab:CreateSlider({
    Name = "Fling Timeout",
    Range = {0.5, 10}, Increment = 0.1, Suffix = "s",
    CurrentValue = 2.5, Flag = "FlingTimeout",
    Callback = function(v) Cfg.FlingTimeout = v end,
})
MM2Tab:CreateButton({
    Name = "💥 Fling Murderer",
    Callback = function()
        if not GetChar() then return end
        local m = GetPlayerByRole("Murderer")
        if m then
            task.spawn(function() DoFling(m) end)
            Rayfield:Notify({ Title = "Fling", Content = "Flinging: " .. m.DisplayName, Duration = 2 })
        else
            Rayfield:Notify({ Title = "Fling", Content = "Murderer not found", Duration = 2 })
        end
    end,
})
MM2Tab:CreateButton({
    Name = "💥 Fling Sheriff",
    Callback = function()
        if not GetChar() then return end
        local s = GetPlayerByRole("Sheriff")
        if s then
            task.spawn(function() DoFling(s) end)
            Rayfield:Notify({ Title = "Fling", Content = "Flinging: " .. s.DisplayName, Duration = 2 })
        else
            Rayfield:Notify({ Title = "Fling", Content = "Sheriff not found", Duration = 2 })
        end
    end,
})
local FlingTarget = nil
local FlingPlayerList = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then table.insert(FlingPlayerList, p.Name) end
end
MM2Tab:CreateDropdown({
    Name = "Select Fling Target",
    Options = FlingPlayerList,
    CurrentOption = {}, MultipleOptions = false, Flag = "FlingTargetDrop",
    Callback = function(v) FlingTarget = v[1] end,
})
MM2Tab:CreateButton({
    Name = "💥 Fling Selected Player",
    Callback = function()
        if not GetChar() or not FlingTarget then
            Rayfield:Notify({ Title = "Fling", Content = "No player selected", Duration = 2 })
            return
        end
        local p = Players:FindFirstChild(FlingTarget)
        if p and p ~= LocalPlayer then
            task.spawn(function() DoFling(p) end)
            Rayfield:Notify({ Title = "Fling", Content = "Flinging: " .. p.DisplayName, Duration = 2 })
        end
    end,
})

MM2Tab:CreateSection("🚀 Teleport")
MM2Tab:CreateToggle({
    Name = "TP to Murderer (continuous)",
    CurrentValue = false, Flag = "TpMurderer",
    Callback = function(v)
        Cfg.TpToMurderer = v
        if v then Cfg.TpToSheriff = false end
        Rayfield:Notify({ Title = "TP Murderer", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MM2Tab:CreateToggle({
    Name = "TP to Sheriff (continuous)",
    CurrentValue = false, Flag = "TpSheriff",
    Callback = function(v)
        Cfg.TpToSheriff = v
        if v then Cfg.TpToMurderer = false end
        Rayfield:Notify({ Title = "TP Sheriff", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MM2Tab:CreateButton({
    Name = "📍  TP to Murderer (once)",
    Callback = function()
        if not GetChar() then return end
        local m = GetPlayerByRole("Murderer")
        if m and m.Character then
            local r = m.Character:FindFirstChild("HumanoidRootPart")
            if r then
                pcall(function() RootPart.CFrame = r.CFrame * CFrame.new(0,0,5) end)
                Rayfield:Notify({ Title = "TP", Content = "Teleported to: " .. m.DisplayName, Duration = 2 })
            end
        else
            Rayfield:Notify({ Title = "TP", Content = "Murderer not found", Duration = 2 })
        end
    end,
})
MM2Tab:CreateButton({
    Name = "📍  TP to Sheriff (once)",
    Callback = function()
        if not GetChar() then return end
        local s = GetPlayerByRole("Sheriff")
        if s and s.Character then
            local r = s.Character:FindFirstChild("HumanoidRootPart")
            if r then
                pcall(function() RootPart.CFrame = r.CFrame * CFrame.new(0,0,5) end)
                Rayfield:Notify({ Title = "TP", Content = "Teleported to: " .. s.DisplayName, Duration = 2 })
            end
        else
            Rayfield:Notify({ Title = "TP", Content = "Sheriff not found", Duration = 2 })
        end
    end,
})
MM2Tab:CreateButton({
    Name = "📍  TP to Map",
    Callback = function()
        if not GetChar() then return end
        local map = workspace:FindFirstChild("CoinContainer", true)
        if map and map.Parent then
            local part = map:FindFirstChildWhichIsA("BasePart", true)
                      or map.Parent:FindFirstChildWhichIsA("BasePart", true)
            if part then
                pcall(function() RootPart.CFrame = part.CFrame * CFrame.new(0, 2, 0) end)
                Rayfield:Notify({ Title = "TP Map", Content = "Teleported to map", Duration = 2 })
                return
            end
        end
        Rayfield:Notify({ Title = "TP Map", Content = "Map not found", Duration = 2 })
    end,
})
MM2Tab:CreateButton({
    Name = "📍  TP to Lobby",
    Callback = function()
        if not GetChar() then return end
        local lobby = workspace:FindFirstChild("Lobby", true)
        if lobby and lobby.Parent then
            local part = lobby:FindFirstChildWhichIsA("BasePart", true)
                      or lobby.Parent:FindFirstChildWhichIsA("BasePart", true)
            if part then
                pcall(function() RootPart.CFrame = part.CFrame * CFrame.new(0, 2, 0) end)
                Rayfield:Notify({ Title = "TP Lobby", Content = "Teleported to lobby", Duration = 2 })
                return
            end
        end
        Rayfield:Notify({ Title = "TP Lobby", Content = "Lobby not found", Duration = 2 })
    end,
})

MM2Tab:CreateSection("🔫 Sheriff")
MM2Tab:CreateToggle({
    Name = "Auto Pickup Gun",
    CurrentValue = false, Flag = "AutoGun",
    Callback = function(v)
        Cfg.AutoPickupGun = v
        Rayfield:Notify({ Title = "Auto Pickup Gun", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MM2Tab:CreateButton({
    Name = "🔫  Grab Gun (GunDrop)",
    Callback = function()
        if not GetChar() then return end
        local gun = workspace:FindFirstChild("GunDrop", true)
        if gun then
            if firetouchinterest then
                firetouchinterest(RootPart, gun, 0)
                firetouchinterest(RootPart, gun, 1)
            else
                gun.CFrame = RootPart.CFrame
            end
            Rayfield:Notify({ Title = "Grab Gun", Content = "Подобрал GunDrop!", Duration = 2 })
        else
            Rayfield:Notify({ Title = "Grab Gun", Content = "GunDrop не найден", Duration = 2 })
        end
    end,
})
MM2Tab:CreateButton({
    Name = "🔫  Steal Gun (from Sheriff)",
    Callback = function()
        if not GetChar() then return end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not bp then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if p.Character and p.Character:FindFirstChild("Gun") then
                    p.Character:FindFirstChild("Gun").Parent = Character
                    Humanoid:EquipTool(Character:FindFirstChild("Gun"))
                    Humanoid:UnequipTools()
                    Rayfield:Notify({ Title = "Steal Gun", Content = "Украл у " .. p.Name, Duration = 2 })
                    return
                elseif p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Gun") then
                    p.Backpack:FindFirstChild("Gun").Parent = bp
                    Humanoid:EquipTool(bp:FindFirstChild("Gun"))
                    Humanoid:UnequipTools()
                    Rayfield:Notify({ Title = "Steal Gun", Content = "Украл у " .. p.Name, Duration = 2 })
                    return
                end
            end
        end
        Rayfield:Notify({ Title = "Steal Gun", Content = "Пистолет не найден", Duration = 2 })
    end,
})

MM2Tab:CreateSection("⚡ Stamina")
MM2Tab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false, Flag = "InfStamina",
    Callback = function(v)
        Cfg.InfiniteStamina = v
        Rayfield:Notify({ Title = "Infinite Stamina", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MM2Tab:CreateToggle({
    Name = "Always Sprint",
    CurrentValue = false, Flag = "AlwaysSprint",
    Callback = function(v)
        Cfg.AlwaysSprint = v
        Rayfield:Notify({ Title = "Always Sprint", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})

-- ═══════════════════════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════════════════════
CombatTab:CreateSection("🔫 Shoot Murder")
CombatTab:CreateToggle({
    Name = "Shoot Murder Button",
    CurrentValue = false, Flag = "ShootMurder",
    Callback = function(v)
        Cfg.ShootMurder = v
        local guip = (gethui and gethui())
            or (game:FindService("CoreGui") and game:FindService("CoreGui"):FindFirstChild("RobloxGui"))
            or game:FindService("CoreGui")
            or LocalPlayer:FindFirstChild("PlayerGui")
        if v then
            if guip and not guip:FindFirstChild("NokoGunW") then
                local GunGui = Instance.new("ScreenGui", guip)
                GunGui.Name = "NokoGunW"
                GunGui.ResetOnSpawn = false
                local btn = Instance.new("TextButton", GunGui)
                btn.Name = "ShootBtn"
                btn.Draggable = true
                btn.Position = UDim2.new(0.5, 187, 0.5, -176)
                btn.Size = UDim2.new(0, 70, 0, 50)
                btn.BackgroundTransparency = 0.15
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                btn.Text = "🔫\nShoot\nMurder"
                btn.TextColor3 = Color3.new(1, 1, 1)
                btn.TextSize = 11
                btn.TextWrapped = true
                btn.Active = true
                btn.AnchorPoint = Vector2.new(0.5, 0.5)
                local corner = Instance.new("UICorner", btn)
                corner.CornerRadius = UDim.new(0, 8)
                local stroke = Instance.new("UIStroke", btn)
                stroke.Color = Color3.fromRGB(255, 80, 80)
                stroke.Thickness = 2
                stroke.Transparency = 0.3
                btn.MouseButton1Click:Connect(function()
                    if not Character then return end
                    if Character:FindFirstChild("Gun") then
                        -- Точно как в оригинале: (GetMurdererTarget()) — скобки берут только первое значение (позицию)
                        pcall(function()
                            Character.Gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, (GetMurdererTarget()), "AH2")
                        end)
                    else
                        Rayfield:Notify({ Title = "Shoot Murder", Content = "Нет пистолета в руках!", Duration = 2 })
                    end
                end)
            end
        else
            if guip and guip:FindFirstChild("NokoGunW") then
                guip:FindFirstChild("NokoGunW"):Destroy()
            end
        end
        Rayfield:Notify({ Title = "Shoot Murder", Content = v and "ON — кнопка появилась" or "OFF", Duration = 2 })
    end,
})

CombatTab:CreateSection("🎯 Gun Aimbot")
CombatTab:CreateToggle({
    Name = "Gun Aimbot (Sheriff)",
    CurrentValue = false, Flag = "GunAimbot",
    Callback = function(v)
        Cfg.GunAimbot = v
        if GunBotConn then GunBotConn:Disconnect(); GunBotConn = nil end
        if v then
            task.spawn(function()
                local function SetupBot()
                    if not GetChar() then return end
                    local gun = Character:FindFirstChild("Gun")
                    if not gun then return end
                    local knifeLocal = gun:FindFirstChild("KnifeLocal")
                    local cb     = knifeLocal and knifeLocal:FindFirstChild("CreateBeam")
                    local remote = cb and cb:FindFirstChild("RemoteFunction")
                    if not remote then return end
                    if GunBotConn then GunBotConn:Disconnect(); GunBotConn = nil end
                    GunBotConn = gun.Activated:Connect(function()
                        local targetPos, isSelf = GetMurdererTarget()
                        if targetPos and not isSelf then
                            pcall(function() remote:InvokeServer(1, targetPos, "AH2") end)
                        end
                    end)
                end
                while Cfg.GunAimbot do
                    SetupBot()
                    task.wait(0.25)
                end
                if GunBotConn then GunBotConn:Disconnect(); GunBotConn = nil end
            end)
        end
        Rayfield:Notify({ Title = "Gun Aimbot", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})

-- ═══════════════════════════════════════════════════════════
-- MOVEMENT TAB
-- ═══════════════════════════════════════════════════════════
MoveTab:CreateSection("Speed")
MoveTab:CreateToggle({
    Name = "Speed Hack", CurrentValue = false, Flag = "SpeedHack",
    Callback = function(v)
        Cfg.SpeedHack = v
        if not v and GetChar() then Humanoid.WalkSpeed = 16 end
        Rayfield:Notify({ Title = "Speed Hack", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MoveTab:CreateSlider({
    Name = "Walk Speed", Range = {16,500}, Increment = 2, Suffix = " WS",
    CurrentValue = 32, Flag = "SpeedValue",
    Callback = function(v) Cfg.SpeedValue = v end,
})

MoveTab:CreateSection("Jump")
MoveTab:CreateToggle({
    Name = "Jump Hack", CurrentValue = false, Flag = "JumpHack",
    Callback = function(v)
        Cfg.JumpHack = v
        if not v and GetChar() then Humanoid.JumpPower = 50 end
        Rayfield:Notify({ Title = "Jump Hack", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MoveTab:CreateSlider({
    Name = "Jump Power", Range = {50,1000}, Increment = 10, Suffix = " JP",
    CurrentValue = 100, Flag = "JumpPower",
    Callback = function(v) Cfg.JumpValue = v end,
})
MoveTab:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump",
    Callback = function(v)
        Cfg.InfiniteJump = v
        Rayfield:Notify({ Title = "Infinite Jump", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})

MoveTab:CreateSection("Advanced")
MoveTab:CreateToggle({
    Name = "Noclip", CurrentValue = false, Flag = "Noclip",
    Callback = function(v)
        Cfg.Noclip = v
        Rayfield:Notify({ Title = "Noclip", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MoveTab:CreateToggle({
    Name = "Fly  [Shift = Boost]", CurrentValue = false, Flag = "Fly",
    Callback = function(v)
        Cfg.Fly = v
        if v then SetupFly() else DestroyFly() end
        Rayfield:Notify({ Title = "Fly", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MoveTab:CreateSlider({
    Name = "Fly Speed", Range = {10,500}, Increment = 5, Suffix = " FS",
    CurrentValue = 60, Flag = "FlySpeed",
    Callback = function(v) Cfg.FlySpeed = v end,
})
MoveTab:CreateSlider({
    Name = "Fly Boost Speed", Range = {50,1000}, Increment = 10, Suffix = " FS",
    CurrentValue = 150, Flag = "FlyBoost",
    Callback = function(v) Cfg.FlyBoostSpeed = v end,
})

-- ═══════════════════════════════════════════════════════════
-- VISUALS TAB
-- ═══════════════════════════════════════════════════════════
VisualTab:CreateSection("ESP")
VisualTab:CreateToggle({
    Name = "Player ESP", CurrentValue = false, Flag = "ESP",
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
    Name = "ESP Max Distance", Range = {50,2000}, Increment = 50, Suffix = "m",
    CurrentValue = 500, Flag = "ESPMaxDist",
    Callback = function(v) Cfg.ESPMaxDist = v end,
})

VisualTab:CreateSection("Chams")
VisualTab:CreateToggle({
    Name = "Chams", CurrentValue = false, Flag = "Chams",
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
    Name = "Chams Transparency", Range = {0,100}, Increment = 5, Suffix = "%",
    CurrentValue = 50, Flag = "ChamTransp",
    Callback = function(v)
        Cfg.ChamTransparency = v / 100
        for _, hl in pairs(ChamData) do hl.FillTransparency = Cfg.ChamTransparency end
    end,
})

VisualTab:CreateSection("Tracers")
VisualTab:CreateToggle({
    Name = "Tracers", CurrentValue = false, Flag = "Tracers",
    Callback = function(v)
        Cfg.Tracers = v
        Rayfield:Notify({ Title = "Tracers", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
VisualTab:CreateDropdown({
    Name = "Tracer Origin", Options = {"Bottom","Center","Top"},
    CurrentOption = {"Bottom"}, MultipleOptions = false, Flag = "TracerOrigin",
    Callback = function(v) Cfg.TracerOrigin = v[1] end,
})

VisualTab:CreateSection("Gun")
VisualTab:CreateToggle({
    Name = "Gun Drop ESP",
    CurrentValue = false, Flag = "GunESP",
    Callback = function(v)
        Cfg.GunESP = v
        if not v then
            if GunESPData.highlight then pcall(function() GunESPData.highlight:Destroy() end); GunESPData.highlight = nil end
            if GunESPData.billboard then pcall(function() GunESPData.billboard:Destroy() end); GunESPData.billboard = nil end
        end
        Rayfield:Notify({ Title = "Gun Drop ESP", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})

VisualTab:CreateSection("Environment")
VisualTab:CreateToggle({
    Name = "FullBright", CurrentValue = false, Flag = "FullBright",
    Callback = function(v)
        Cfg.FullBright = v
        if v then
            Lighting.Ambient = Color3.fromRGB(255,255,255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
            Lighting.Brightness = Cfg.FullBrightValue
            Lighting.ClockTime  = 14; Lighting.FogEnd = 100000
            for _, ef in ipairs(Lighting:GetChildren()) do
                if ef:IsA("PostEffect") then ef.Enabled = false end
            end
        else
            Lighting.Ambient = Color3.fromRGB(127,127,127)
            Lighting.OutdoorAmbient = Color3.fromRGB(127,127,127)
            Lighting.Brightness = 1
            for _, ef in ipairs(Lighting:GetChildren()) do
                if ef:IsA("PostEffect") then ef.Enabled = true end
            end
        end
        Rayfield:Notify({ Title = "FullBright", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})

-- ═══════════════════════════════════════════════════════════
-- MISC TAB
-- ═══════════════════════════════════════════════════════════
MiscTab:CreateSection("Utility")
MiscTab:CreateToggle({
    Name = "Anti AFK", CurrentValue = false, Flag = "AntiAFK",
    Callback = function(v)
        Cfg.AntiAFK = v; Disconnect("AntiAFK")
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
    Name = "FPS Boost", CurrentValue = false, Flag = "FPSBoost",
    Callback = function(v)
        Cfg.FPSBoost = v
        settings().Rendering.QualityLevel = v
            and Enum.QualityLevel.Level01
            or  Enum.QualityLevel.Automatic
        Rayfield:Notify({ Title = "FPS Boost", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})

MiscTab:CreateSection("⚡ Extra")
MiscTab:CreateToggle({
    Name = "Seconds Life (Godmode)",
    CurrentValue = false, Flag = "SecondsLife",
    Callback = function(v)
        Cfg.SecondsLife = v
        Disconnect("GodCon")
        if v and Humanoid then
            Connections["GodCon"] = Humanoid.HealthChanged:Connect(function()
                if Cfg.SecondsLife and Humanoid.Health < Humanoid.MaxHealth then
                    Humanoid.Health = Humanoid.MaxHealth
                end
            end)
        end
        Rayfield:Notify({ Title = "Seconds Life", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MiscTab:CreateToggle({
    Name = "Touch Fling",
    CurrentValue = false, Flag = "TouchFling",
    Callback = function(v)
        Cfg.TouchFling = v
        Rayfield:Notify({ Title = "Touch Fling", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})
MiscTab:CreateToggle({
    Name = "Noclip Players (Anti-Fling)",
    CurrentValue = false, Flag = "NoclipPlrs",
    Callback = function(v)
        Cfg.NoclipPlayers = v
        if not v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    for _, part in ipairs(plr.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
            end
        end
        Rayfield:Notify({ Title = "Noclip Players", Content = v and "ON" or "OFF", Duration = 2 })
    end,
})

MiscTab:CreateSection("Server")
MiscTab:CreateButton({
    Name = "🔄  Rejoin Server",
    Callback = function()
        Rayfield:Notify({ Title = "Rejoin", Content = "Reconnecting in 2s...", Duration = 2 })
        task.wait(2)
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end,
})
MiscTab:CreateButton({
    Name = "📋  Copy PlaceId",
    Callback = function()
        setclipboard(tostring(game.PlaceId))
        Rayfield:Notify({ Title = "Copied", Content = "PlaceId: " .. game.PlaceId, Duration = 3 })
    end,
})

-- ─── Cleanup ─────────────────────────────────────────────────────────────────
game:BindToClose(function()
    pcall(function() Camera.CameraType = Enum.CameraType.Custom end)
    for _, plr in ipairs(Players:GetPlayers()) do
        RemoveESP(plr); RemoveChams(plr); RemoveRoleChams(plr)
    end
    for _, conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end
    for _, label in pairs(CoinESPData) do pcall(function() label:Remove() end) end
    if GunBotConn then pcall(function() GunBotConn:Disconnect() end) end
    if GunESPData.highlight then pcall(function() GunESPData.highlight:Destroy() end) end
    if GunESPData.billboard then pcall(function() GunESPData.billboard:Destroy() end) end
    -- Remove Shoot Murder GUI
    local guip = (gethui and gethui()) or game:FindService("CoreGui") or LocalPlayer:FindFirstChild("PlayerGui")
    if guip and guip:FindFirstChild("NokoGunW") then
        guip:FindFirstChild("NokoGunW"):Destroy()
    end
    DestroyFly()
end)

Rayfield:Notify({
    Title   = "Noko Hub  MM2",
    Content = "Loaded v2.1.0 | Murder Mystery 2 | " .. (IsMobile and "📱 Mobile" or "🖥️ PC"),
    Duration = 5,
    Image   = 4483362458,
})

print("[Noko Hub MM2] Loaded v2.1.0 | " .. (IsMobile and "Mobile" or "PC") .. " | " .. os.date("%H:%M:%S"))
