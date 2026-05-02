--// Astra Hub | 99 Nights in the Forest //--

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Window = Rayfield:CreateWindow({
    Name = "Astra Hub",
    LoadingTitle = "Astra Hub",
    LoadingSubtitle = "99 Nights in the Forest",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "99NightsSettings"
    },
    Discord = { Enabled = false, Invite = "", RememberJoins = true },
    KeySystem = false,
})

-- Teleport targets (merged from both versions)
local teleportTargets = {
    "Alien", "Alien Chest", "Alien Shelf",
    "Alpha Wolf", "Alpha Wolf Pelt", "Anvil Base", "Apple",
    "Bandage", "Bear", "Berry", "Bolt",
    "Broken Fan", "Broken Microwave",
    "Bunny", "Bunny Foot", "Cake", "Carrot",
    "Chair Set", "Chest", "Chilli", "Coal", "Coin Stack",
    "Crossbow Cultist", "Cultist", "Cultist Gem",
    "Deer", "Fuel Canister",
    "Giant Sack", "Good Axe", "Good Sack",
    "Iron Body",
    "Item Chest", "Item Chest2", "Item Chest3", "Item Chest4", "Item Chest6",
    "Laser Fence Blueprint", "Laser Sword",
    "Leather Body", "Log",
    "Lost Child", "Lost Child2", "Lost Child3", "Lost Child4",
    "Medkit", "Meat? Sandwich", "Morsel",
    "Old Car Engine", "Old Flashlight", "Old Radio", "Oil Barrel",
    "Raygun", "Revolver", "Revolver Ammo",
    "Rifle", "Rifle Ammo", "Riot Shield",
    "Sapling", "Seed Box", "Sheet Metal", "Spear",
    "Steak", "Stronghold Diamond Chest",
    "Tyre", "UFO Component", "UFO Junk",
    "Washing Machine", "Wolf", "Wolf Corpse", "Wolf Pelt",
}

local AimbotTargets = {"Alien", "Alpha Wolf", "Wolf", "Crossbow Cultist", "Cultist", "Bunny", "Bear", "Polar Bear"}

local espEnabled = false
local npcESPEnabled = false
local ignoreDistanceFrom = Vector3.new(0, 0, 0)
local minDistance = 50

local AutoTreeFarmEnabled = false
local AutoLogFarmEnabled = false
local LogBagType = "Auto"

local AimbotEnabled = false
local FOVRadius = 100
local smoothness = 0.2
local lastAimbotCheck = 0

local AntiDeathEnabled = false
local AntiDeathRadius = 50
local AntiDeathTargets = {
    Alien = true, ["Alpha Wolf"] = true, Wolf = true,
    ["Crossbow Cultist"] = true, Cultist = true, Bear = true,
}

local flying, flyConnection = false, nil
local flySpeed = 60
local currentSpeed = 16

-- Utilities
local function pressKey(key)
    key = typeof(key) == "EnumItem" and key or Enum.KeyCode[key]
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.07)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function mouse1click()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

-- Aimbot FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(128, 255, 0)
FOVCircle.Thickness = 1
FOVCircle.Radius = FOVRadius
FOVCircle.Transparency = 0.5
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Item ESP
local function createESP(item)
    local adorneePart
    if item:IsA("Model") then
        if item:FindFirstChildWhichIsA("Humanoid") then return end
        adorneePart = item:FindFirstChildWhichIsA("BasePart")
    elseif item:IsA("BasePart") then
        adorneePart = item
    else return end
    if not adorneePart then return end

    local distance = (adorneePart.Position - ignoreDistanceFrom).Magnitude
    if distance < minDistance then return end

    if not item:FindFirstChild("ESP_Billboard") then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Adornee = adorneePart
        billboard.Size = UDim2.new(0, 50, 0, 20)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = item.Name
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0
        label.TextScaled = true
        billboard.Parent = item
    end

    if not item:FindFirstChild("ESP_Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = Color3.fromRGB(255, 85, 0)
        highlight.OutlineColor = Color3.fromRGB(0, 100, 0)
        highlight.FillTransparency = 0.25
        highlight.OutlineTransparency = 0
        highlight.Adornee = item:IsA("Model") and item or adorneePart
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = item
    end
end

local function toggleESP(state)
    espEnabled = state
    for _, item in pairs(workspace:GetDescendants()) do
        if table.find(teleportTargets, item.Name) then
            if espEnabled then
                createESP(item)
            else
                if item:FindFirstChild("ESP_Billboard") then item.ESP_Billboard:Destroy() end
                if item:FindFirstChild("ESP_Highlight") then item.ESP_Highlight:Destroy() end
            end
        end
    end
end

workspace.DescendantAdded:Connect(function(desc)
    if espEnabled and table.find(teleportTargets, desc.Name) then
        task.wait(0.1)
        createESP(desc)
    end
end)

-- NPC ESP
local npcBoxes = {}

local function createNPCESP(npc)
    if not npc:IsA("Model") or not npc:FindFirstChild("HumanoidRootPart") then return end
    if npcBoxes[npc] then return end

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Transparency = 1
    box.Color = Color3.fromRGB(255, 85, 0)
    box.Filled = false
    box.Visible = true

    local nameText = Drawing.new("Text")
    nameText.Text = npc.Name
    nameText.Color = Color3.fromRGB(255, 255, 255)
    nameText.Size = 16
    nameText.Center = true
    nameText.Outline = true
    nameText.Visible = true

    npcBoxes[npc] = {box = box, name = nameText}

    npc.AncestryChanged:Connect(function(_, parent)
        if not parent and npcBoxes[npc] then
            npcBoxes[npc].box:Remove()
            npcBoxes[npc].name:Remove()
            npcBoxes[npc] = nil
        end
    end)
end

local function toggleNPCESP(state)
    npcESPEnabled = state
    if not state then
        for _, visuals in pairs(npcBoxes) do
            if visuals.box then visuals.box:Remove() end
            if visuals.name then visuals.name:Remove() end
        end
        npcBoxes = {}
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if table.find(AimbotTargets, obj.Name) and obj:IsA("Model") then
                createNPCESP(obj)
            end
        end
    end
end

workspace.DescendantAdded:Connect(function(desc)
    if npcESPEnabled and table.find(AimbotTargets, desc.Name) and desc:IsA("Model") then
        task.wait(0.1)
        createNPCESP(desc)
    end
end)

RunService.RenderStepped:Connect(function()
    for npc, visuals in pairs(npcBoxes) do
        if npc and npc:FindFirstChild("HumanoidRootPart") then
            local hrp = npc.HumanoidRootPart
            local size = Vector2.new(60, 80)
            local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                visuals.box.Position = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)
                visuals.box.Size = size
                visuals.box.Visible = true
                visuals.name.Position = Vector2.new(screenPos.X, screenPos.Y - size.Y / 2 - 15)
                visuals.name.Visible = true
            else
                visuals.box.Visible = false
                visuals.name.Visible = false
            end
        else
            visuals.box:Remove()
            visuals.name:Remove()
            npcBoxes[npc] = nil
        end
    end
end)

-- Aimbot
RunService.RenderStepped:Connect(function()
    if not AimbotEnabled or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        FOVCircle.Visible = false
        return
    end

    local currentTime = tick()
    if currentTime - lastAimbotCheck < 0.02 then return end
    lastAimbotCheck = currentTime

    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
    FOVCircle.Visible = true

    local closestTarget, shortestDistance = nil, math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if table.find(AimbotTargets, obj.Name) and obj:IsA("Model") then
            local head = obj:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDistance and dist <= FOVRadius then
                        shortestDistance = dist
                        closestTarget = head
                    end
                end
            end
        end
    end

    if closestTarget then
        local currentCF = camera.CFrame
        local targetCF = CFrame.new(currentCF.Position, closestTarget.Position)
        camera.CFrame = currentCF:Lerp(targetCF, smoothness)
    end
end)

-- Auto Tree Farm
local badTrees = {}

task.spawn(function()
    while true do
        if AutoTreeFarmEnabled then
            local trees = {}
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name == "Trunk" and obj.Parent and obj.Parent.Name == "Small Tree" then
                    local distance = (obj.Position - ignoreDistanceFrom).Magnitude
                    if distance > minDistance and not badTrees[obj:GetFullName()] then
                        table.insert(trees, obj)
                    end
                end
            end

            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                table.sort(trees, function(a, b)
                    return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
                end)
            end

            for _, trunk in ipairs(trees) do
                if not AutoTreeFarmEnabled then break end
                LocalPlayer.Character:PivotTo(trunk.CFrame + Vector3.new(0, 3, 0))
                task.wait(0.2)
                local startTime = tick()
                while AutoTreeFarmEnabled and trunk and trunk.Parent and trunk.Parent.Name == "Small Tree" do
                    mouse1click()
                    task.wait(0.2)
                    if tick() - startTime > 12 then
                        badTrees[trunk:GetFullName()] = true
                        break
                    end
                end
                task.wait(0.3)
            end
        end
        task.wait(1.5)
    end
end)

-- Auto Log Farm
local function getClosestLog()
    local minDist = math.huge
    local closest = nil
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Log" then
            local pos = nil
            if obj:IsA("BasePart") then
                pos = obj.Position
            elseif obj:IsA("Model") then
                if obj.PrimaryPart then
                    pos = obj.PrimaryPart.Position
                else
                    for _, part in ipairs(obj:GetChildren()) do
                        if part:IsA("BasePart") then pos = part.Position break end
                    end
                end
            end
            if pos then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - pos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = obj
                    end
                end
            end
        end
    end
    return closest
end

local function getBagPickupCount()
    if LogBagType == "Old Sack" then return 5
    elseif LogBagType == "Good Sack" then return 15
    elseif LogBagType == "Giant Sack" then return 30
    elseif LogBagType == "Auto" then
        for _, obj in pairs(LocalPlayer.Character:GetDescendants()) do
            if obj.Name == "Giant Sack" then return 30 end
            if obj.Name == "Good Sack" then return 15 end
            if obj.Name == "Old Sack" then return 5 end
        end
    end
    return 5
end

local LogDropType = "Campfire"

task.spawn(function()
    while true do
        if AutoLogFarmEnabled then
            local pickupCount = getBagPickupCount()
            local log = getClosestLog()
            if log then
                local pos = log:IsA("BasePart") and log.Position
                    or (log.PrimaryPart and log.PrimaryPart.Position)
                    or nil
                if not pos then
                    for _, p in ipairs(log:GetChildren()) do
                        if p:IsA("BasePart") then pos = p.Position break end
                    end
                end
                if pos then
                    LocalPlayer.Character:PivotTo(CFrame.new(pos + Vector3.new(0, 2, 0)))
                    task.wait(0.5)
                    for i = 1, pickupCount do
                        pressKey("F")
                        pressKey("E")
                        task.wait(0.13)
                    end
                    if LogDropType == "Campfire" then
                        LocalPlayer.Character:PivotTo(CFrame.new(0, 10, 0))
                    else
                        LocalPlayer.Character:PivotTo(CFrame.new(16.1, 4, -4.6))
                    end
                    task.wait(2)
                end
            else
                task.wait(3)
            end
        end
        task.wait(1)
    end
end)

-- Fly
local function startFlying()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bodyGyro = Instance.new("BodyGyro", hrp)
    local bodyVelocity = Instance.new("BodyVelocity", hrp)
    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = hrp.CFrame
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyConnection = RunService.RenderStepped:Connect(function()
        local moveVec = Vector3.zero
        local camCF = camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec += camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec -= camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec -= camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec += camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec += camCF.UpVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec -= camCF.UpVector end
        bodyVelocity.Velocity = moveVec.Magnitude > 0 and moveVec.Unit * flySpeed or Vector3.zero
        bodyGyro.CFrame = camCF
    end)
end

local function stopFlying()
    if flyConnection then flyConnection:Disconnect() end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, v in pairs(hrp:GetChildren()) do
            if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then v:Destroy() end
        end
    end
end

local function toggleFly(state)
    flying = state
    if flying then startFlying() else stopFlying() end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Q then toggleFly(not flying) end
end)

-- Speed
local function setWalkSpeed(speed)
    currentSpeed = speed
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = speed
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(function()
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then hum.WalkSpeed = currentSpeed end
    end)
end)

-- Anti Death
local detectionCircle = Instance.new("Part")
detectionCircle.Name = "AntiDeathCircle"
detectionCircle.Anchored = true
detectionCircle.CanCollide = false
detectionCircle.Transparency = 1
detectionCircle.Material = Enum.Material.Neon
detectionCircle.Color = Color3.fromRGB(255, 0, 0)
detectionCircle.Parent = workspace

local circMesh = Instance.new("SpecialMesh", detectionCircle)
circMesh.MeshType = Enum.MeshType.Cylinder
circMesh.Scale = Vector3.new(AntiDeathRadius * 2, 0.2, AntiDeathRadius * 2)

local function updateDetectionCircle()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        detectionCircle.Position = Vector3.new(hrp.Position.X, hrp.Position.Y - 3, hrp.Position.Z)
        circMesh.Scale = Vector3.new(AntiDeathRadius * 2, 0.2, AntiDeathRadius * 2)
        detectionCircle.Transparency = AntiDeathEnabled and 0.5 or 1
    else
        detectionCircle.Transparency = 1
    end
end

RunService.RenderStepped:Connect(updateDetectionCircle)

task.spawn(function()
    while true do
        if AntiDeathEnabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, npc in ipairs(workspace:GetDescendants()) do
                    if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") and AntiDeathTargets[npc.Name] then
                        if (npc.HumanoidRootPart.Position - hrp.Position).Magnitude <= AntiDeathRadius then
                            LocalPlayer.Character:PivotTo(CFrame.new(0, 10, 0))
                            break
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- Fog
local defaultFogStart = game.Lighting.FogStart
local defaultFogEnd = game.Lighting.FogEnd

-- ===== GUI TABS =====

-- Home Tab
local HomeTab = Window:CreateTab("🏠Home🏠", 4483362458)

HomeTab:CreateButton({
    Name = "Teleport to Campfire",
    Callback = function()
        LocalPlayer.Character:PivotTo(CFrame.new(0, 10, 0))
    end
})

HomeTab:CreateButton({
    Name = "Teleport to Grinder",
    Callback = function()
        LocalPlayer.Character:PivotTo(CFrame.new(16.1, 4, -4.6))
    end
})

HomeTab:CreateSlider({
    Name = "Speedhack",
    Range = {16, 150},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Callback = setWalkSpeed
})

HomeTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    Suffix = "Speed",
    CurrentValue = 60,
    Callback = function(v) flySpeed = v end
})

HomeTab:CreateToggle({
    Name = "Item ESP",
    CurrentValue = false,
    Callback = toggleESP
})

HomeTab:CreateToggle({
    Name = "NPC ESP",
    CurrentValue = false,
    Callback = function(value)
        toggleNPCESP(value)
        Rayfield:Notify({Title="NPC ESP", Content=value and "Enabled" or "Disabled", Duration=3, Image=4483362458})
    end
})

HomeTab:CreateToggle({
    Name = "Auto Tree Farm (Small Tree)",
    CurrentValue = false,
    Callback = function(value)
        AutoTreeFarmEnabled = value
        Rayfield:Notify({Title="Auto Tree Farm", Content=value and "Enabled" or "Disabled", Duration=3, Image=4483362458})
    end
})

HomeTab:CreateToggle({
    Name = "Auto Log Farm",
    CurrentValue = false,
    Callback = function(value)
        AutoLogFarmEnabled = value
        Rayfield:Notify({Title="Auto Log Farm", Content=value and "Enabled" or "Disabled", Duration=3, Image=4483362458})
    end
})

HomeTab:CreateToggle({
    Name = "Aimbot (Hold Right Click)",
    CurrentValue = false,
    Callback = function(value)
        AimbotEnabled = value
        Rayfield:Notify({Title="Aimbot", Content=value and "Enabled" or "Disabled", Duration=3, Image=4483362458})
    end
})

HomeTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {20, 400},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 100,
    Callback = function(v)
        FOVRadius = v
        FOVCircle.Radius = v
    end
})

HomeTab:CreateToggle({
    Name = "Fly (WASD + Space + Shift)",
    CurrentValue = false,
    Callback = function(value)
        toggleFly(value)
        Rayfield:Notify({Title="Fly", Content=value and "Enabled" or "Disabled", Duration=3, Image=4483362458})
    end
})

HomeTab:CreateToggle({
    Name = "Anti Death Teleport",
    CurrentValue = false,
    Callback = function(value)
        AntiDeathEnabled = value
        Rayfield:Notify({Title="Anti Death", Content=value and "Enabled" or "Disabled", Duration=3, Image=4483362458})
    end
})

HomeTab:CreateToggle({
    Name = "No Fog",
    CurrentValue = false,
    Callback = function(value)
        if value then
            game.Lighting.FogStart = 999999
            game.Lighting.FogEnd = 1000000
        else
            game.Lighting.FogStart = defaultFogStart
            game.Lighting.FogEnd = defaultFogEnd
        end
        Rayfield:Notify({Title="Fog", Content=value and "Removed" or "Restored", Duration=3, Image=4483362458})
    end
})

-- Teleport Tab
local TeleTab = Window:CreateTab("🧲Teleport🧲", 4483362458)

for _, itemName in ipairs(teleportTargets) do
    TeleTab:CreateButton({
        Name = "TP: " .. itemName,
        Callback = function()
            local closest, shortest = nil, math.huge
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name == itemName then
                    local cf = nil
                    pcall(function() cf = obj:IsA("Model") and obj:GetPivot() or obj.CFrame end)
                    if not cf then
                        local part = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or (obj:IsA("BasePart") and obj)
                        if part then cf = part.CFrame end
                    end
                    if cf then
                        local dist = (cf.Position - ignoreDistanceFrom).Magnitude
                        if dist >= minDistance and dist < shortest then
                            closest = obj
                            shortest = dist
                        end
                    end
                end
            end
            if closest then
                local cf = nil
                pcall(function() cf = closest:IsA("Model") and closest:GetPivot() or closest.CFrame end)
                if not cf then
                    local part = closest:IsA("Model") and closest:FindFirstChildWhichIsA("BasePart") or closest
                    if part then cf = part.CFrame end
                end
                if cf then
                    LocalPlayer.Character:PivotTo(cf + Vector3.new(0, 5, 0))
                end
            else
                Rayfield:Notify({Title="Not Found", Content=itemName.." not found.", Duration=4, Image=4483362458})
            end
        end
    })
end

-- Log Farm Tab
local LogTab = Window:CreateTab("🌳Log Farm🌳", 4483362458)

local OldSackToggle, GoodSackToggle, GiantSackToggle

OldSackToggle = LogTab:CreateToggle({
    Name = "Old Sack (5 logs)",
    CurrentValue = false,
    Callback = function(value)
        if value then
            LogBagType = "Old Sack"
            if GoodSackToggle then GoodSackToggle:Set(false) end
            if GiantSackToggle then GiantSackToggle:Set(false) end
        else
            if LogBagType == "Old Sack" then LogBagType = "Auto" end
        end
    end
})

GoodSackToggle = LogTab:CreateToggle({
    Name = "Good Sack (15 logs)",
    CurrentValue = false,
    Callback = function(value)
        if value then
            LogBagType = "Good Sack"
            if OldSackToggle then OldSackToggle:Set(false) end
            if GiantSackToggle then GiantSackToggle:Set(false) end
        else
            if LogBagType == "Good Sack" then LogBagType = "Auto" end
        end
    end
})

GiantSackToggle = LogTab:CreateToggle({
    Name = "Giant Sack (30 logs)",
    CurrentValue = false,
    Callback = function(value)
        if value then
            LogBagType = "Giant Sack"
            if OldSackToggle then OldSackToggle:Set(false) end
            if GoodSackToggle then GoodSackToggle:Set(false) end
        else
            if LogBagType == "Giant Sack" then LogBagType = "Auto" end
        end
    end
})

LogTab:CreateToggle({
    Name = "Drop at Campfire",
    CurrentValue = true,
    Callback = function(value)
        LogDropType = value and "Campfire" or "Grinder"
    end
})

-- Anti Death Tab
local AntiDeathTab = Window:CreateTab("🛡️Anti Death🛡️", 4483362458)

AntiDeathTab:CreateSlider({
    Name = "Detection Radius",
    Range = {10, 150},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 50,
    Callback = function(value)
        AntiDeathRadius = value
        updateDetectionCircle()
    end
})

for npcName, _ in pairs(AntiDeathTargets) do
    AntiDeathTab:CreateToggle({
        Name = "Avoid " .. npcName,
        CurrentValue = true,
        Callback = function(value)
            AntiDeathTargets[npcName] = value
        end
    })
end

Rayfield:Notify({
    Title = "Astra Hub Loaded",
    Content = "All features ready. Press Q to toggle Fly.",
    Duration = 5,
    Image = 4483362458,
})
