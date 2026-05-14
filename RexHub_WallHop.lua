if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(0.3)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local VIM              = game:GetService("VirtualInputManager")
local CoreGui          = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local S = {
    AutoWallHop      = false,
    AutoFlick        = false,
    AutoAlign        = false,
    SpeedBoost       = false,
    WalkSpeed        = 16,
    JumpPower        = 50,
    FlickAngle       = 90,
    FlickSpeed       = 0.03,
    WallHopDelay     = 0.08,
    AlignDistance    = 3.5,
    InfJump          = false,
    AntiSlip         = false,
    ShowWallESP      = false,
    AutoCheckpoint   = false,
}

local flickCooldown  = false
local lastFlickTime  = 0
local wallHopActive  = false
local lastJumpState  = false

local function safe(fn) pcall(fn) end

local function getChar()  return LP.Character end
local function getRoot()  local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local function isOnGround()
    local hum = getHum()
    return hum and hum.FloorMaterial ~= Enum.Material.Air
end

local function findNearestWall(maxDist)
    maxDist = maxDist or 6
    local root = getRoot()
    if not root then return nil, nil end

    local dirs = {
        Vector3.new( 1, 0,  0),
        Vector3.new(-1, 0,  0),
        Vector3.new( 0, 0,  1),
        Vector3.new( 0, 0, -1),
    }

    local bestHit, bestNormal, bestDist = nil, nil, maxDist

    for _, dir in ipairs(dirs) do
        local origin = root.Position
        local ray    = RaycastParams.new()
        ray.FilterDescendantsInstances = {getChar()}
        ray.FilterType = Enum.RaycastFilterType.Exclude

        local result = workspace:Raycast(origin, dir * maxDist, ray)
        if result and result.Instance then
            local d = (result.Position - origin).Magnitude
            if d < bestDist then
                bestHit    = result.Instance
                bestNormal = result.Normal
                bestDist   = d
            end
        end
    end

    return bestHit, bestNormal, bestDist
end

local function alignToWall()
    local root = getRoot()
    if not root then return false end

    local wall, normal, dist = findNearestWall(S.AlignDistance + 2)
    if not wall or not normal then return false end

    safe(function()
        local wallCF   = CFrame.new(root.Position, root.Position - normal)
        root.CFrame    = CFrame.new(root.Position) * CFrame.Angles(0, wallCF:ToEulerAnglesYXZ(), 0)
    end)

    return true
end

local function flickCamera(angle)
    if flickCooldown then return end
    local now = tick()
    if now - lastFlickTime < 0.05 then return end

    flickCooldown = true
    lastFlickTime = now

    safe(function()
        local root   = getRoot()
        if not root then flickCooldown = false; return end

        local camCF  = Camera.CFrame
        local pivot  = camCF.Position

        local deg    = math.rad(angle or S.FlickAngle)

        local t1 = TweenService:Create(
            Camera,
            TweenInfo.new(S.FlickSpeed, Enum.EasingStyle.Linear),
            {CFrame = CFrame.new(pivot) * CFrame.Angles(0, deg, 0) * CFrame.new(0, 0, (pivot - camCF.Position).Magnitude)}
        )
        t1:Play()
        t1.Completed:Wait()

        task.wait(0.02)

        local t2 = TweenService:Create(
            Camera,
            TweenInfo.new(S.FlickSpeed, Enum.EasingStyle.Linear),
            {CFrame = camCF}
        )
        t2:Play()
        t2.Completed:Wait()
    end)

    task.delay(0.05, function() flickCooldown = false end)
end

local function wallHopJump()
    local hum  = getHum()
    local root = getRoot()
    if not hum or not root then return end

    safe(function()
        local wall, normal, dist = findNearestWall(S.AlignDistance + 1)
        if not wall or not normal then return end

        if S.AutoAlign then
            local wallDir = -normal
            local newCF   = CFrame.new(root.Position, root.Position + wallDir)
            root.CFrame   = CFrame.new(root.Position) * CFrame.Angles(0, select(2, newCF:ToEulerAnglesYXZ()), 0)
            task.wait(0.02)
        end

        hum.Jump = true

        task.delay(S.WallHopDelay, function()
            safe(function() flickCamera(S.FlickAngle) end)
        end)
    end)
end

local function doCheckpoint()
    safe(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = obj.Name:lower()
                if n:find("checkpoint") or n:find("spawn") or n:find("stage") then
                    local root = getRoot()
                    if root and (root.Position - obj.Position).Magnitude < 15 then
                        local touch = workspace:FindFirstChild("TouchTransmitter", true)
                        if touch then
                            game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent", true)
                        end
                        root.CFrame = obj.CFrame * CFrame.new(0, 3, 0)
                        return
                    end
                end
            end
        end
    end)
end

RunService.Heartbeat:Connect(function()
    safe(function()
        local hum  = getHum()
        local root = getRoot()
        if not hum or not root then return end

        if S.SpeedBoost then
            hum.WalkSpeed = S.WalkSpeed
            hum.JumpPower = S.JumpPower
        else
            if hum.WalkSpeed == S.WalkSpeed and S.WalkSpeed ~= 16 then
                hum.WalkSpeed = 16
            end
        end

        if S.InfJump then
            hum:GetPropertyChangedSignal("Jump"):Connect(function()
                if hum.Jump then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end

        if S.AntiSlip then
            local floor = hum.FloorMaterial
            if floor ~= Enum.Material.Air then
                root.AssemblyLinearVelocity = Vector3.new(
                    root.AssemblyLinearVelocity.X * 0.92,
                    root.AssemblyLinearVelocity.Y,
                    root.AssemblyLinearVelocity.Z * 0.92
                )
            end
        end
    end)
end)

local autoHopConn
RunService.Stepped:Connect(function()
    if not S.AutoWallHop then
        if autoHopConn then autoHopConn = nil end
        return
    end

    safe(function()
        local hum  = getHum()
        if not hum then return end

        local wall, normal, dist = findNearestWall(S.AlignDistance)
        if not wall then return end

        local onGround = hum.FloorMaterial ~= Enum.Material.Air
        if onGround and dist <= S.AlignDistance then
            wallHopJump()
            task.wait(S.WallHopDelay + 0.05)
        end
    end)
end)

local espObjs = {}

RunService.RenderStepped:Connect(function()
    if not S.ShowWallESP then
        for _, v in pairs(espObjs) do pcall(function() v:Destroy() end) end
        espObjs = {}
        return
    end

    safe(function()
        for _, v in pairs(espObjs) do pcall(function() v:Destroy() end) end
        espObjs = {}

        local root = getRoot()
        if not root then return end

        local wall, normal, dist = findNearestWall(8)
        if not wall or not wall.Parent then return end

        local bb = Instance.new("SelectionBox")
        bb.Adornee      = wall
        bb.Color3       = dist <= S.AlignDistance
            and Color3.fromRGB(60, 255, 100)
            or  Color3.fromRGB(255, 180, 40)
        bb.LineThickness = 0.06
        bb.SurfaceTransparency = 0.85
        bb.SurfaceColor3 = bb.Color3
        bb.Parent        = CoreGui
        table.insert(espObjs, bb)
    end)
end)

local RayfieldOk, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not RayfieldOk or not Rayfield then
    warn("[Rex Hub] Rayfield не загрузился: " .. tostring(Rayfield))
    return
end

local Window = Rayfield:CreateWindow({
    Name                   = "Rex Hub  |  Wall Flick & Wall Hop",
    LoadingTitle           = "Rex Hub",
    LoadingSubtitle        = "Wall Flick & Wall Hop Practice",
    Theme                  = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
})

local MainTab = Window:CreateTab("🏃 Wall Hop", 4483345998)

MainTab:CreateSection("Авто движение")

MainTab:CreateToggle({
    Name         = "Auto WallHop",
    CurrentValue = false,
    Flag         = "AutoWallHop",
    Callback     = function(v) S.AutoWallHop = v end,
})

MainTab:CreateToggle({
    Name         = "Auto Flick (камера)",
    CurrentValue = false,
    Flag         = "AutoFlick",
    Callback     = function(v) S.AutoFlick = v end,
})

MainTab:CreateToggle({
    Name         = "Auto Align (выравнивание к стене)",
    CurrentValue = false,
    Flag         = "AutoAlign",
    Callback     = function(v) S.AutoAlign = v end,
})

MainTab:CreateSection("Настройки WallHop")

MainTab:CreateSlider({
    Name         = "Flick Угол (градусы)",
    Range        = {30, 180},
    Increment    = 5,
    CurrentValue = 90,
    Flag         = "FlickAngle",
    Callback     = function(v) S.FlickAngle = v end,
})

MainTab:CreateSlider({
    Name         = "Flick Скорость",
    Range        = {1, 20},
    Increment    = 1,
    CurrentValue = 3,
    Flag         = "FlickSpeedSlider",
    Callback     = function(v) S.FlickSpeed = v / 100 end,
})

MainTab:CreateSlider({
    Name         = "WallHop Задержка (мс)",
    Range        = {20, 200},
    Increment    = 5,
    CurrentValue = 80,
    Flag         = "WallHopDelay",
    Callback     = function(v) S.WallHopDelay = v / 1000 end,
})

MainTab:CreateSlider({
    Name         = "Дистанция к стене (studs)",
    Range        = {1, 10},
    Increment    = 0.5,
    CurrentValue = 3,
    Flag         = "AlignDist",
    Callback     = function(v) S.AlignDistance = v end,
})

MainTab:CreateSection("Вручную")

MainTab:CreateButton({
    Name     = "⚡ Flick Влево (-90°)",
    Callback = function() task.spawn(function() flickCamera(-S.FlickAngle) end) end,
})

MainTab:CreateButton({
    Name     = "⚡ Flick Вправо (+90°)",
    Callback = function() task.spawn(function() flickCamera(S.FlickAngle) end) end,
})

MainTab:CreateButton({
    Name     = "🎯 Выровнять к стене",
    Callback = function()
        local ok = alignToWall()
        Rayfield:Notify({
            Title   = "Rex Hub",
            Content = ok and "Выровнено к стене!" or "Стена не найдена",
            Duration = 2,
        })
    end,
})

MainTab:CreateButton({
    Name     = "🦘 WallHop Прыжок",
    Callback = function() task.spawn(wallHopJump) end,
})

local MoveTab = Window:CreateTab("⚡ Движение", 4483345998)

MoveTab:CreateSection("Персонаж")

MoveTab:CreateToggle({
    Name         = "Speed / Jump Boost",
    CurrentValue = false,
    Flag         = "SpeedBoost",
    Callback     = function(v)
        S.SpeedBoost = v
        if not v then
            safe(function()
                local hum = getHum()
                if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
            end)
        end
    end,
})

MoveTab:CreateSlider({
    Name         = "Walk Speed",
    Range        = {16, 120},
    Increment    = 2,
    CurrentValue = 16,
    Flag         = "WalkSpeed",
    Callback     = function(v) S.WalkSpeed = v end,
})

MoveTab:CreateSlider({
    Name         = "Jump Power",
    Range        = {50, 200},
    Increment    = 5,
    CurrentValue = 50,
    Flag         = "JumpPower",
    Callback     = function(v) S.JumpPower = v end,
})

MoveTab:CreateToggle({
    Name         = "Infinite Jump",
    CurrentValue = false,
    Flag         = "InfJump",
    Callback     = function(v) S.InfJump = v end,
})

MoveTab:CreateToggle({
    Name         = "Anti Slip (меньше скольжения)",
    CurrentValue = false,
    Flag         = "AntiSlip",
    Callback     = function(v) S.AntiSlip = v end,
})

MoveTab:CreateSection("Телепорт")

MoveTab:CreateButton({
    Name     = "🔄 Телепорт на старт",
    Callback = function()
        safe(function()
            local spawns = workspace:FindFirstChild("Spawns")
                or workspace:FindFirstChild("SpawnLocations")
                or workspace:FindFirstChild("Checkpoints")
            if spawns then
                local first = spawns:GetChildren()[1]
                if first and first:IsA("BasePart") then
                    local root = getRoot()
                    if root then
                        root.CFrame = first.CFrame * CFrame.new(0, 4, 0)
                        Rayfield:Notify({Title="Rex Hub", Content="ТП на старт!", Duration=2})
                        return
                    end
                end
            end
            local spawn = workspace:FindFirstChild("SpawnLocation")
            if spawn then
                local root = getRoot()
                if root then
                    root.CFrame = spawn.CFrame * CFrame.new(0, 4, 0)
                    Rayfield:Notify({Title="Rex Hub", Content="ТП на SpawnLocation!", Duration=2})
                end
            end
        end)
    end,
})

MoveTab:CreateButton({
    Name     = "📍 ТП вверх (+30 studs)",
    Callback = function()
        safe(function()
            local root = getRoot()
            if root then root.CFrame = root.CFrame + Vector3.new(0, 30, 0) end
        end)
    end,
})

local VisualTab = Window:CreateTab("👁 Визуал", 4483345998)

VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({
    Name         = "Wall ESP (подсветка стены)",
    CurrentValue = false,
    Flag         = "ShowWallESP",
    Callback     = function(v) S.ShowWallESP = v end,
})

VisualTab:CreateSection("Информация о стене")

local wallInfoLbl = VisualTab:CreateLabel("Стена: не найдена")
local wallDistLbl = VisualTab:CreateLabel("Дистанция: —")
local wallNameLbl = VisualTab:CreateLabel("Объект: —")

VisualTab:CreateSection("FPS")

VisualTab:CreateToggle({
    Name         = "FPS Boost",
    CurrentValue = false,
    Flag         = "FPSBoost",
    Callback     = function(v)
        safe(function()
            local Lighting = game:GetService("Lighting")
            if v then
                settings().Rendering.QualityLevel = 1
                Lighting.GlobalShadows  = false
                Lighting.FogEnd         = 9e9
                for _, o in ipairs(workspace:GetDescendants()) do
                    if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") then
                        pcall(function() o.Enabled = false end)
                    end
                end
                Rayfield:Notify({Title="Rex Hub", Content="FPS Boost включён", Duration=2})
            else
                settings().Rendering.QualityLevel = 10
                Lighting.GlobalShadows  = true
                Rayfield:Notify({Title="Rex Hub", Content="FPS Boost выключен", Duration=2})
            end
        end)
    end,
})

if IsMobile then
    local MobileTab = Window:CreateTab("📱 Мобайл", 4483345998)

    MobileTab:CreateSection("Кнопки на экране")

    MobileTab:CreateLabel("Кнопки Flick добавляются поверх экрана")

    local mobileGuiEnabled = false

    MobileTab:CreateToggle({
        Name         = "Показать кнопки Flick",
        CurrentValue = false,
        Flag         = "ShowMobileBtns",
        Callback     = function(v)
            mobileGuiEnabled = v
            pcall(function()
                local old = game:GetService("CoreGui"):FindFirstChild("RexMobileButtons")
                if old then old:Destroy() end
            end)
            if not v then return end

            local sg = Instance.new("ScreenGui")
            sg.Name           = "RexMobileButtons"
            sg.ResetOnSpawn   = false
            sg.IgnoreGuiInset = true
            sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            sg.Parent         = game:GetService("CoreGui")

            local btnSz = 64

            local function mkBtn(label, x, y, col, cb)
                local btn = Instance.new("TextButton")
                btn.Size             = UDim2.new(0, btnSz, 0, btnSz)
                btn.Position         = UDim2.new(x, -btnSz/2, y, -btnSz/2)
                btn.BackgroundColor3 = col
                btn.BorderSizePixel  = 0
                btn.Text             = label
                btn.TextColor3       = Color3.new(1,1,1)
                btn.Font             = Enum.Font.GothamBold
                btn.TextSize         = 13
                btn.ZIndex           = 10
                btn.Parent           = sg
                Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
                btn.MouseButton1Click:Connect(cb)
                btn.TouchTap:Connect(cb)
                return btn
            end

            mkBtn("◀ FLICK", 0.12, 0.78, Color3.fromRGB(60, 80, 220), function()
                task.spawn(function() flickCamera(-S.FlickAngle) end)
            end)

            mkBtn("FLICK ▶", 0.88, 0.78, Color3.fromRGB(60, 80, 220), function()
                task.spawn(function() flickCamera(S.FlickAngle) end)
            end)

            mkBtn("🎯\nALIGN", 0.5, 0.88, Color3.fromRGB(40, 160, 80), function()
                alignToWall()
            end)

            mkBtn("🦘\nHOP", 0.5, 0.72, Color3.fromRGB(180, 60, 220), function()
                task.spawn(wallHopJump)
            end)
        end,
    })

    MobileTab:CreateSection("Советы")
    MobileTab:CreateLabel("◀ FLICK — флик влево")
    MobileTab:CreateLabel("FLICK ▶ — флик вправо")
    MobileTab:CreateLabel("ALIGN — выровнять к стене")
    MobileTab:CreateLabel("HOP — прыжок от стены")
end

local InfoTab = Window:CreateTab("ℹ️ Инфо", 4483345998)

InfoTab:CreateSection("Rex Hub")
InfoTab:CreateLabel("Wall Flick & Wall Hop Practice")
InfoTab:CreateLabel("Версия: 1.0.0  |  Rex Hub")

InfoTab:CreateSection("Как пользоваться")
InfoTab:CreateLabel("1. Подойди к стене вплотную")
InfoTab:CreateLabel("2. Нажми ALIGN для выравнивания")
InfoTab:CreateLabel("3. Нажми HOP или включи Auto WallHop")
InfoTab:CreateLabel("4. Flick вращает камеру для прыжка")

InfoTab:CreateSection("Клавиши (ПК)")
InfoTab:CreateLabel("Insert — скрыть / показать GUI")

local wallStatusLbl = InfoTab:CreateLabel("Стена рядом: нет")
local playerPosLbl  = InfoTab:CreateLabel("Позиция: —")

RunService.Heartbeat:Connect(function()
    safe(function()
        local root = getRoot()
        if not root then return end

        local wall, normal, dist = findNearestWall(8)

        if wallInfoLbl then
            wallInfoLbl:Set(wall
                and ("Стена: ✅  " .. (normal and string.format("Normal: %.1f %.1f %.1f", normal.X, normal.Y, normal.Z) or ""))
                or "Стена: ❌ не найдена")
        end
        if wallDistLbl then
            wallDistLbl:Set(wall
                and string.format("Дистанция: %.2f studs", dist or 0)
                or "Дистанция: —")
        end
        if wallNameLbl then
            wallNameLbl:Set(wall
                and ("Объект: " .. wall.Name)
                or "Объект: —")
        end
        if wallStatusLbl then
            wallStatusLbl:Set(wall and dist and dist <= S.AlignDistance
                and "Стена рядом: ✅ ГОТОВ К HOP"
                or (wall and "Стена рядом: 🟡 далеко"
                or "Стена рядом: ❌ нет"))
        end
        if playerPosLbl then
            playerPosLbl:Set(string.format(
                "Позиция: %.0f, %.0f, %.0f",
                root.Position.X, root.Position.Y, root.Position.Z
            ))
        end
    end)
end)

if not IsMobile then
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.Insert then
            Rayfield:Notify({Title="Rex Hub", Content="Toggle GUI", Duration=1})
        end
        if inp.KeyCode == Enum.KeyCode.Q and S.AutoFlick then
            task.spawn(function() flickCamera(-S.FlickAngle) end)
        end
        if inp.KeyCode == Enum.KeyCode.E and S.AutoFlick then
            task.spawn(function() flickCamera(S.FlickAngle) end)
        end
    end)
end

Rayfield:Notify({
    Title    = "Rex Hub",
    Content  = "Wall Flick & Wall Hop загружен! " .. (IsMobile and "📱 Mobile" or "💻 PC"),
    Duration = 4,
})

print("✅ Rex Hub | Wall Flick & Wall Hop | " .. (IsMobile and "Mobile" or "PC"))
