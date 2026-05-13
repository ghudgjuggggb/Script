if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(0.3)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RS               = game:GetService("ReplicatedStorage")
local VIM              = game:GetService("VirtualInputManager")

local Camera = workspace.CurrentCamera
local LP     = Players.LocalPlayer

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local VP        = Camera.ViewportSize
local SCALE     = math.clamp(math.min(VP.X, VP.Y) / 600, 0.55, 1.5)
local UI_W      = IS_MOBILE and math.floor(VP.X * 0.94) or math.floor(math.min(480, VP.X * 0.44))
local UI_H      = IS_MOBILE and math.floor(VP.Y * 0.88) or math.floor(math.min(580, VP.Y * 0.84))
local FONT_SM   = math.floor(11 * SCALE)
local FONT_MD   = math.floor(13 * SCALE)
local FONT_LG   = math.floor(15 * SCALE)
local PAD       = math.floor(10 * SCALE)
local ROW_H     = math.floor(38 * SCALE)
local HDR_H     = math.floor(46 * SCALE)
local TAB_H     = IS_MOBILE and math.floor(40 * SCALE) or math.floor(32 * SCALE)
local BTN_RAD   = UDim.new(0, math.floor(7 * SCALE))

local C = {
    BG      = Color3.fromRGB(12,  12,  20),
    Panel   = Color3.fromRGB(22,  22,  35),
    Card    = Color3.fromRGB(30,  30,  48),
    Accent  = Color3.fromRGB(220, 0,   110),
    Accent2 = Color3.fromRGB(140, 0,   200),
    Green   = Color3.fromRGB(60,  220, 100),
    Yellow  = Color3.fromRGB(255, 200, 60),
    Blue    = Color3.fromRGB(60,  160, 255),
    Red     = Color3.fromRGB(255, 70,  70),
    TextW   = Color3.fromRGB(240, 240, 240),
    TextG   = Color3.fromRGB(140, 140, 160),
    Border  = Color3.fromRGB(55,  55,  80),
}

local EV  = RS:WaitForChild("Events",  10)
local REM = RS:WaitForChild("Remotes", 10)

local function getRemote(parent, name)
    if not parent then return nil end
    local ok, r = pcall(function() return parent:WaitForChild(name, 6) end)
    return ok and r or nil
end

local R = {
    Codes           = getRemote(EV,  "Codes"),
    Quests          = getRemote(EV,  "Quests"),
    RepeatQuest     = getRemote(EV,  "RepeatQuest"),
    Interact        = getRemote(EV,  "Interact"),
    Inventory       = getRemote(EV,  "Inventory"),
    Combat          = getRemote(EV,  "Combat"),
    MotionHandler   = getRemote(REM, "MotionHandler"),
    InvValidateTool = getRemote(EV,  "InventoryValidateTool"),
    Missions        = getRemote(EV,  "Missions"),
}

local S = {
    AutoFarm       = false,
    AutoCodes      = false,
    AutoChest      = false,
    AutoSkill      = false,
    FarmTime       = 0,
    KillCount      = 0,
    ChestCount     = 0,
    CodesRedeemed  = 0,
    ActiveTab      = "Farm",
    MobOffset      = "Above",
    MobOffsetY     = 4,
    MobOffsetZ     = 0,
    AttackDist     = 8,
    SkillInterval  = 1.2,
    QuestGot       = false,
    CurrentMob     = nil,
    FarmStatus     = "Idle",
    FarmPhase      = "idle",
}

local ALL_CODES = {
    {code="SHUTDOWNSORRY7!", reward="2x EXP + 2x Luck 1hr"},
    {code="85KLIKES!",       reward="10k Yens + Spins"},
    {code="80KLIKES!",       reward="10k Yens + Spins"},
    {code="UPDATE4!",        reward="10k Yens + Spins"},
    {code="THANKS2!",        reward="50 Race + 25 Grimoire Spins"},
    {code="70KLIKES!",       reward="10k Yens + Spins"},
    {code="75KLIKES!",       reward="10k Yens + Spins"},
    {code="65KLIKES!",       reward="10k Yens + Spins"},
    {code="60KLIKES!",       reward="10k Yens + Spins"},
    {code="UPDATEFIXES2!",   reward="2hr 2x EXP + 2x Luck"},
    {code="55KLIKES!",       reward="10k Yens + Spins"},
    {code="50KLIKES!",       reward="10k Yens + Spins"},
    {code="UPDATESFIXES!",   reward="2hr 2x EXP + 2x Luck"},
    {code="45KLIKES!",       reward="10k Yens + Spins"},
    {code="40KLIKES!",       reward="10k Yens + Spins"},
    {code="THANKS!",         reward="50 Race + 25 Grimoire Spins"},
    {code="35KLIKES!",       reward="10k Yens + Spins"},
    {code="SHUTDOWNSORRY5!", reward="10k Yens + Spins"},
    {code="30KLIKES!",       reward="10k Yens + Spins"},
    {code="29KLIKES!",       reward="10k Yens + Spins"},
    {code="28KLIKES!",       reward="10k Yens + Spins"},
    {code="BUGFIXES11!",     reward="10k Yens + Spins"},
    {code="SORRYSHUTDOWN!",  reward="1hr 2x EXP + 2x Luck"},
    {code="27KLIKES!",       reward="10k Yens + Spins"},
    {code="26KLIKES!",       reward="10k Yens + Spins"},
    {code="25KLIKES!",       reward="10k Yens + Spins"},
    {code="24KLIKES!",       reward="10k Yens + Spins"},
    {code="23KLIKES!",       reward="10k Yens + Spins"},
    {code="22KLIKES!",       reward="10k Yens + Spins"},
    {code="21KLIKES!",       reward="10k Yens + Spins"},
    {code="20KLIKES!",       reward="10k Yens + Spins"},
    {code="19KLIKES!",       reward="10k Yens + Spins"},
    {code="BUGFIXES10!",     reward="10k Yens + Spins"},
    {code="18KLIKES!",       reward="10k Yens + Spins"},
    {code="17KLIKES!",       reward="10k Yens + Spins"},
    {code="16KLIKES!",       reward="10k Yens + Spins"},
    {code="15KLIKES!",       reward="10k Yens + Spins"},
    {code="14KLIKES!",       reward="10k Yens + Spins"},
    {code="13KLIKES!",       reward="10k Yens + Spins"},
    {code="12KLIKES!",       reward="10k Yens + Spins"},
}

local LEVEL_RANGES = {
    {min=1,   max=49,  enemy="Bandit",            quest="Bandit Boss Quest Lvl 50",          questPos=Vector3.new(155.27, 5.18, -330.74),  mobPos=Vector3.new(155.27, 5.18, -330.74)},
    {min=50,  max=149, enemy="Boar",              quest="Boar Quest Lvl 150",                questPos=Vector3.new(-121.18,15.71,-844.86),  mobPos=Vector3.new(-121.18,15.71,-844.86)},
    {min=150, max=249, enemy="Boar Boss",         quest="Boar Boss Quest Lvl 250",           questPos=Vector3.new(-576.53,10.98,-946.72),  mobPos=Vector3.new(-576.53,10.98,-946.72)},
    {min=250, max=449, enemy="Corrupted Wiz",     quest="Corrupted Wizards Quest Lvl 450",   questPos=Vector3.new(-310.15,33.00,-2063.69), mobPos=Vector3.new(-310.15,33.00,-2063.69)},
    {min=450, max=999, enemy="Earth Wizard",      quest="Quest Giver Earth Wizard 2000+",    questPos=Vector3.new(536.77, 14.15,-416.55),  mobPos=Vector3.new(536.77, 14.15,-416.55)},
    {min=1000,max=2549,enemy="Corrupted Nobleman",quest="Quest Giver Corrupted Nobleman 2550+",questPos=Vector3.new(-449.13,11.14,-724.49),mobPos=Vector3.new(-449.13,11.14,-724.49)},
}

local QUEST_NPCS = {
    {name="Bandit Quest Lvl 1",                   pos=Vector3.new(289.63,  5.68,  -720.66)},
    {name="Bandit Boss Quest Lvl 50",             pos=Vector3.new(155.27,  5.18,  -330.74)},
    {name="Boar Quest Lvl 150",                   pos=Vector3.new(-121.18, 15.71, -844.86)},
    {name="Boar Boss Quest Lvl 250",              pos=Vector3.new(-576.53, 10.98, -946.72)},
    {name="Corrupted Wizards Quest Lvl 450",      pos=Vector3.new(-310.15, 33.00, -2063.69)},
    {name="Quest Giver Water Wizard",             pos=Vector3.new(-325.87, 11.14, -571.94)},
    {name="Quest Giver Earth Wizard 2000+",       pos=Vector3.new(536.77,  14.15, -416.55)},
    {name="Quest Giver Corrupted Nobleman 2550+", pos=Vector3.new(-449.13, 11.14, -724.49)},
    {name="Secondary Quest Giver Wheat",          pos=Vector3.new(-3.40,   5.18,  -623.19)},
    {name="BroomQuest",                           pos=Vector3.new(328.52,  17.29, -534.90)},
}

local function safeFireServer(remote, ...)
    if not remote then return false end
    local args = {...}
    local ok, err = pcall(function() remote:FireServer(table.unpack(args)) end)
    if not ok then warn("[NexHub] " .. tostring(err)) end
    return ok
end

local function safeInvokeServer(remote, ...)
    if not remote then return false end
    local args = {...}
    local ok, err = pcall(function() remote:InvokeServer(table.unpack(args)) end)
    if not ok then warn("[NexHub] " .. tostring(err)) end
    return ok
end

local function getLevel()
    if LP.Character then
        local lv = LP.Character:FindFirstChild("Level")
        if lv then return lv.Value end
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local lv2 = hum:FindFirstChild("Level") or hum.Parent:FindFirstChild("Level")
            if lv2 then return lv2.Value end
        end
    end
    return 1
end

local function getLevelRange()
    local lv = getLevel()
    for _, r in ipairs(LEVEL_RANGES) do
        if lv >= r.min and lv <= r.max then return r end
    end
    return LEVEL_RANGES[#LEVEL_RANGES]
end

local function getHum()
    return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function isAlive()
    local hum = getHum()
    return hum ~= nil and hum.Health > 0
end

local function formatTime(s)
    return string.format("%02d:%02d:%02d",
        math.floor(s/3600), math.floor(s%3600/60), math.floor(s%60))
end

local function teleportTo(pos)
    local root = getRoot()
    if root then root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)) end
end

local function giveQuest(questName)
    return safeFireServer(R.Quests, "giveQuest", questName)
end

local function redeemCode(code)
    return safeFireServer(R.Codes, code)
end

local function enableRegen()
    if LP.Character and LP.Character:FindFirstChild("Regen") then
        safeFireServer(R.MotionHandler, LP.Character:FindFirstChild("Regen"), true)
    end
end

local function enableCombat()
    if LP.Character and LP.Character:FindFirstChild("Combat") then
        safeFireServer(R.MotionHandler, LP.Character:FindFirstChild("Combat"), true)
    end
end

local function equipCombat()
    safeInvokeServer(R.InvValidateTool, "Combat")
end

local function getMobOffset(mobPos)
    local offY = S.MobOffsetY
    local offZ = S.MobOffsetZ
    if S.MobOffset == "Above" then
        return mobPos + Vector3.new(0, offY, 0)
    elseif S.MobOffset == "Behind" then
        return mobPos + Vector3.new(0, offY, offZ + 4)
    elseif S.MobOffset == "Below" then
        return mobPos + Vector3.new(0, -math.abs(offY), 0)
    elseif S.MobOffset == "Front" then
        return mobPos + Vector3.new(0, offY, -(offZ + 4))
    end
    return mobPos + Vector3.new(0, offY, 0)
end

local function findMobOnMap(mobName)
    local root = getRoot()
    if not root then return nil end
    local best, bestDist = nil, math.huge
    local folders = {"Enemies", "Mobs", "NPCs", "Workspace"}
    for _, fname in ipairs(folders) do
        local folder = fname == "Workspace" and workspace or workspace:FindFirstChild(fname)
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Model") then
                    local matchName = obj.Name:lower():find(mobName:lower(), 1, true)
                    if matchName then
                        local hum = obj:FindFirstChildOfClass("Humanoid")
                        local hrp = obj:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health > 0 then
                            local d = (root.Position - hrp.Position).Magnitude
                            if d < bestDist then
                                best     = obj
                                bestDist = d
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function attackMob(mob)
    if not mob then return end
    local root = getRoot()
    local mobHRP = mob:FindFirstChild("HumanoidRootPart")
    if not root or not mobHRP then return end

    local targetPos = getMobOffset(mobHRP.Position)
    root.CFrame = CFrame.new(targetPos)

    task.wait(0.05)

    pcall(function()
        safeFireServer(R.Combat, mob)
    end)

    pcall(function()
        local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
        if tool then
            local re = tool:FindFirstChildOfClass("RemoteEvent")
            if re then re:FireServer(mob) end
        end
    end)

    pcall(function()
        VIM:SendKeyEvent(true,  Enum.KeyCode.Q, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
    end)
end

local function useSkills()
    local skillKeys = {
        Enum.KeyCode.Q,
        Enum.KeyCode.E,
        Enum.KeyCode.R,
        Enum.KeyCode.F,
        Enum.KeyCode.T,
        Enum.KeyCode.G,
        Enum.KeyCode.Z,
        Enum.KeyCode.X,
        Enum.KeyCode.C,
    }
    for _, key in ipairs(skillKeys) do
        pcall(function()
            VIM:SendKeyEvent(true,  key, false, game)
            task.wait(0.04)
            VIM:SendKeyEvent(false, key, false, game)
        end)
        task.wait(0.05)
    end
end

local function findNearestChest()
    local root = getRoot()
    if not root then return nil end
    local containers = {"Chests", "Items", "Chest", "WorldItems"}
    for _, cname in ipairs(containers) do
        local folder = workspace:FindFirstChild(cname)
        if folder then
            local best, bestDist = nil, 999999
            for _, obj in ipairs(folder:GetChildren()) do
                local pos
                if obj:IsA("Model") then
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                        or obj:FindFirstChild("PrimaryPart")
                        or obj:FindFirstChildWhichIsA("BasePart")
                    if hrp then pos = hrp.Position end
                elseif obj:IsA("BasePart") then
                    pos = obj.Position
                end
                if pos then
                    local d = (pos - root.Position).Magnitude
                    if d < bestDist then bestDist = d; best = obj end
                end
            end
            if best then return best end
        end
    end
    return nil
end

local function collectChest(chest)
    local root = getRoot()
    if not root or not chest then return end
    pcall(function()
        local target = chest:IsA("Model")
            and (chest:FindFirstChild("HumanoidRootPart") or chest:FindFirstChildWhichIsA("BasePart"))
            or chest
        if target then
            root.CFrame = CFrame.new(target.Position + Vector3.new(0, 4, 0))
            task.wait(0.25)
            safeFireServer(R.Interact, chest)
            S.ChestCount = S.ChestCount + 1
        end
    end)
end

local lastSkillTime = 0

task.spawn(function()
    while true do
        task.wait(0.25)

        if not S.AutoFarm then
            S.FarmPhase  = "idle"
            S.FarmStatus = "Idle"
            S.QuestGot   = false
            S.CurrentMob = nil
            task.wait(0.5)
        else
            S.FarmTime = S.FarmTime + 0.25

            if not isAlive() then
                S.FarmPhase  = "dead"
                S.FarmStatus = "Мёртв — ждём воскрешения..."
                task.wait(4)
            else
                local range = getLevelRange()

                if S.FarmPhase == "idle" then
                    S.QuestGot   = false
                    S.CurrentMob = nil
                    S.FarmPhase  = "goto_quest"
                    S.FarmStatus = "Иду к квест NPC..."

                elseif S.FarmPhase == "goto_quest" then
                    enableRegen()
                    task.wait(0.05)
                    enableCombat()
                    task.wait(0.05)
                    equipCombat()
                    task.wait(0.05)
                    teleportTo(range.questPos)
                    task.wait(0.4)
                    S.FarmPhase  = "take_quest"
                    S.FarmStatus = "Беру квест: " .. range.quest

                elseif S.FarmPhase == "take_quest" then
                    local ok = giveQuest(range.quest)
                    task.wait(0.3)
                    if ok then
                        S.QuestGot  = true
                        S.FarmPhase = "find_mob"
                        S.FarmStatus = "Ищу моба: " .. range.enemy
                    else
                        S.FarmPhase = "goto_quest"
                    end

                elseif S.FarmPhase == "find_mob" then
                    local mob = findMobOnMap(range.enemy)
                    if mob then
                        S.CurrentMob = mob
                        S.FarmPhase  = "goto_mob"
                        local hrp = mob:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            S.FarmStatus = "Найден: " .. mob.Name ..
                                string.format(" (%.0fm)", (getRoot() and (getRoot().Position - hrp.Position).Magnitude or 0))
                        end
                    else
                        teleportTo(range.mobPos)
                        task.wait(0.5)
                        S.FarmStatus = "Моб не найден — иду к зоне"
                    end

                elseif S.FarmPhase == "goto_mob" then
                    local mob = S.CurrentMob
                    if not mob or not mob.Parent then
                        S.CurrentMob = nil
                        S.FarmPhase  = "find_mob"
                        S.FarmStatus = "Моб исчез — ищу снова"
                    else
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health <= 0 then
                            S.KillCount  = S.KillCount + 1
                            S.CurrentMob = nil
                            S.FarmPhase  = "check_quest"
                            S.FarmStatus = "Моб убит! Всего: " .. S.KillCount
                        else
                            local hrp  = mob:FindFirstChild("HumanoidRootPart")
                            local root = getRoot()
                            if hrp and root then
                                local d = (root.Position - hrp.Position).Magnitude
                                if d > S.AttackDist then
                                    local targetPos = getMobOffset(hrp.Position)
                                    root.CFrame = CFrame.new(targetPos)
                                    S.FarmStatus = "ТП к мобу: " .. mob.Name
                                else
                                    S.FarmPhase  = "attack"
                                    S.FarmStatus = "Атакую: " .. mob.Name
                                end
                            else
                                S.FarmPhase = "find_mob"
                            end
                        end
                    end

                elseif S.FarmPhase == "attack" then
                    local mob = S.CurrentMob
                    if not mob or not mob.Parent then
                        S.CurrentMob = nil
                        S.FarmPhase  = "find_mob"
                    else
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health <= 0 then
                            S.KillCount  = S.KillCount + 1
                            S.CurrentMob = nil
                            S.FarmPhase  = "check_quest"
                            S.FarmStatus = "Убит! Всего: " .. S.KillCount
                        else
                            local hrp  = mob:FindFirstChild("HumanoidRootPart")
                            local root = getRoot()
                            if hrp and root then
                                local d = (root.Position - hrp.Position).Magnitude
                                if d > S.AttackDist + 4 then
                                    S.FarmPhase = "goto_mob"
                                else
                                    attackMob(mob)
                                    if S.AutoSkill then
                                        local now = tick()
                                        if now - lastSkillTime >= S.SkillInterval then
                                            lastSkillTime = now
                                            task.spawn(useSkills)
                                        end
                                    end
                                    S.FarmStatus = string.format(
                                        "Атака: %s  HP: %.0f  Dist: %.1f",
                                        mob.Name,
                                        hum and hum.Health or 0,
                                        d
                                    )
                                end
                            else
                                S.FarmPhase = "find_mob"
                            end
                        end
                    end

                elseif S.FarmPhase == "check_quest" then
                    local qDone = false
                    pcall(function()
                        local data = LP:FindFirstChild("PlayerData") or LP:FindFirstChild("Data")
                        if data then
                            local qv = data:FindFirstChild("QuestCompleted")
                                or data:FindFirstChild("QuestDone")
                                or data:FindFirstChild("QuestFinished")
                            if qv and qv.Value then qDone = true end
                        end
                    end)
                    if qDone then
                        S.FarmPhase  = "idle"
                        S.QuestGot   = false
                        S.FarmStatus = "Квест завершён! Берём новый..."
                        task.wait(0.5)
                    else
                        S.FarmPhase  = "find_mob"
                        S.FarmStatus = "Продолжаю фармить..."
                    end
                end
            end
        end

        if S.AutoChest then
            local chest = findNearestChest()
            if chest then
                collectChest(chest)
                task.wait(1.5)
            end
        end
    end
end)

pcall(function()
    local old = LP.PlayerGui:FindFirstChild("NexHubUI")
    if old then old:Destroy() end
end)

local GUI = Instance.new("ScreenGui")
GUI.Name           = "NexHubUI"
GUI.ResetOnSpawn   = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.IgnoreGuiInset = true
GUI.Parent         = LP.PlayerGui

local startX = IS_MOBILE and math.floor((VP.X - UI_W) / 2) or PAD * 2
local startY = IS_MOBILE and math.floor((VP.Y - UI_H) / 2) or math.floor(VP.Y * 0.1)

local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, UI_W, 0, UI_H)
Main.Position         = UDim2.new(0, startX, 0, startY)
Main.BackgroundColor3 = C.BG
Main.BorderSizePixel  = 0
Main.Parent           = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, math.floor(12*SCALE))
local ms = Instance.new("UIStroke", Main)
ms.Thickness = math.max(1, math.floor(2*SCALE))
local mg = Instance.new("UIGradient", ms)
mg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   C.Accent),
    ColorSequenceKeypoint.new(0.5, C.Accent2),
    ColorSequenceKeypoint.new(1,   C.Accent),
})
mg.Rotation = 45

local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1, 0, 0, HDR_H)
Header.BackgroundColor3 = C.Panel
Header.BorderSizePixel  = 0
Header.ZIndex           = 2
Header.Parent           = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, math.floor(12*SCALE))
local hg = Instance.new("UIGradient", Header)
hg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.Accent),
    ColorSequenceKeypoint.new(1, C.Accent2),
})
hg.Rotation = 90

local Title = Instance.new("TextLabel")
Title.Size              = UDim2.new(1, -HDR_H - PAD, 1, 0)
Title.Position          = UDim2.new(0, PAD, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3        = C.TextW
Title.Font              = Enum.Font.GothamBold
Title.TextSize          = FONT_LG
Title.TextXAlignment    = Enum.TextXAlignment.Left
Title.Text              = "⚡ NEX HUB  Beta 1.0  |  Clover Origins"
Title.ZIndex            = 3
Title.Parent            = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, HDR_H-10, 0, HDR_H-10)
CloseBtn.Position         = UDim2.new(1, -(HDR_H-5), 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseBtn.BorderSizePixel  = 0
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = C.TextW
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = FONT_MD
CloseBtn.ZIndex           = 4
CloseBtn.Parent           = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local isOpen = true
local function toggleOpen()
    isOpen = not isOpen
    Main.Size = isOpen
        and UDim2.new(0, UI_W, 0, UI_H)
        or  UDim2.new(0, UI_W, 0, HDR_H)
end
CloseBtn.MouseButton1Click:Connect(toggleOpen)
CloseBtn.TouchTap:Connect(toggleOpen)

local dragging, dragStart, frameStart = false, nil, nil
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging   = true
        dragStart  = inp.Position
        frameStart = Main.AbsolutePosition
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        local delta = inp.Position - dragStart
        Main.Position = UDim2.new(0,
            math.clamp(frameStart.X + delta.X, 0, VP.X - UI_W),
            0,
            math.clamp(frameStart.Y + delta.Y, 0, VP.Y - HDR_H))
    end
end)

local Sep = Instance.new("Frame")
Sep.Size             = UDim2.new(1, 0, 0, 1)
Sep.Position         = UDim2.new(0, 0, 0, HDR_H)
Sep.BackgroundColor3 = C.Border
Sep.BorderSizePixel  = 0
Sep.Parent           = Main

local TAB_NAMES = {"Farm", "Settings", "Codes", "Chest", "Quests", "Stats"}

local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, 0, 0, TAB_H + PAD)
TabBar.Position         = UDim2.new(0, 0, 0, HDR_H + 1)
TabBar.BackgroundColor3 = C.Panel
TabBar.BorderSizePixel  = 0
TabBar.ZIndex           = 2
TabBar.Parent           = Main

local TabList = Instance.new("UIListLayout", TabBar)
TabList.FillDirection       = Enum.FillDirection.Horizontal
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabList.VerticalAlignment   = Enum.VerticalAlignment.Center
TabList.Padding             = UDim.new(0, 4)
TabList.SortOrder           = Enum.SortOrder.LayoutOrder

local TabPad = Instance.new("UIPadding", TabBar)
TabPad.PaddingLeft   = UDim.new(0, PAD)
TabPad.PaddingRight  = UDim.new(0, PAD)
TabPad.PaddingTop    = UDim.new(0, math.floor(PAD/2))
TabPad.PaddingBottom = UDim.new(0, math.floor(PAD/2))

local tabBtns = {}
local tabW    = math.floor((UI_W - PAD*2 - 4*(#TAB_NAMES-1)) / #TAB_NAMES)

for i, tname in ipairs(TAB_NAMES) do
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, tabW, 0, TAB_H)
    btn.BackgroundColor3 = C.Card
    btn.BorderSizePixel  = 0
    btn.Text             = tname
    btn.TextColor3       = C.TextG
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = FONT_SM
    btn.LayoutOrder      = i
    btn.ZIndex           = 3
    btn.Parent           = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    tabBtns[tname] = btn
end

local CONTENT_Y = HDR_H + 1 + TAB_H + PAD + 1
local CONTENT_H = UI_H - CONTENT_Y - PAD

local Content = Instance.new("ScrollingFrame")
Content.Size                 = UDim2.new(1, -PAD*2, 0, CONTENT_H)
Content.Position             = UDim2.new(0, PAD, 0, CONTENT_Y)
Content.BackgroundTransparency = 1
Content.BorderSizePixel      = 0
Content.ScrollBarThickness   = IS_MOBILE and 4 or 3
Content.ScrollBarImageColor3 = C.Accent
Content.CanvasSize           = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize  = Enum.AutomaticSize.Y
Content.Parent               = Main

local ContentList = Instance.new("UIListLayout", Content)
ContentList.Padding       = UDim.new(0, math.floor(6*SCALE))
ContentList.SortOrder     = Enum.SortOrder.LayoutOrder
ContentList.FillDirection = Enum.FillDirection.Vertical

local function makeCard(parent, order)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.BackgroundColor3 = C.Card
    card.BorderSizePixel  = 0
    card.LayoutOrder      = order or 99
    card.Parent           = parent
    Instance.new("UICorner", card).CornerRadius = BTN_RAD
    local pad = Instance.new("UIPadding", card)
    pad.PaddingLeft   = UDim.new(0, PAD)
    pad.PaddingRight  = UDim.new(0, PAD)
    pad.PaddingTop    = UDim.new(0, math.floor(PAD*0.7))
    pad.PaddingBottom = UDim.new(0, math.floor(PAD*0.7))
    local list = Instance.new("UIListLayout", card)
    list.Padding       = UDim.new(0, math.floor(5*SCALE))
    list.SortOrder     = Enum.SortOrder.LayoutOrder
    list.FillDirection = Enum.FillDirection.Vertical
    return card
end

local function makeLabel(parent, text, textColor, fontSize, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1, 0, 0, 0)
    lbl.AutomaticSize     = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.TextColor3        = textColor or C.TextW
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = fontSize or FONT_MD
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.TextWrapped       = true
    lbl.Text              = text
    lbl.LayoutOrder       = order or 99
    lbl.Parent            = parent
    return lbl
end

local function makeToggle(parent, label, stateKey, order, onToggle)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, ROW_H)
    row.BackgroundTransparency = 1
    row.LayoutOrder      = order or 99
    row.Parent           = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -(ROW_H*1.8 + PAD), 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3       = C.TextW
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = FONT_MD
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text             = label
    lbl.TextWrapped      = true
    lbl.Parent           = row

    local pill = Instance.new("TextButton")
    pill.Size            = UDim2.new(0, ROW_H*1.7, 0, ROW_H*0.6)
    pill.Position        = UDim2.new(1, -(ROW_H*1.7), 0.5, -ROW_H*0.3)
    pill.BackgroundColor3= S[stateKey] and C.Green or C.Card
    pill.BorderSizePixel = 0
    pill.Text            = S[stateKey] and "ON" or "OFF"
    pill.TextColor3      = C.TextW
    pill.Font            = Enum.Font.GothamBold
    pill.TextSize        = FONT_SM
    pill.Parent          = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke",  pill).Color = C.Border

    local function refresh()
        local on = S[stateKey]
        pill.Text = on and "ON" or "OFF"
        TweenService:Create(pill, TweenInfo.new(0.15), {
            BackgroundColor3 = on and C.Green or C.Card
        }):Play()
    end

    local function activate()
        S[stateKey] = not S[stateKey]
        refresh()
        if onToggle then onToggle(S[stateKey]) end
    end

    pill.MouseButton1Click:Connect(activate)
    pill.TouchTap:Connect(activate)

    return row, pill, refresh
end

local function makeButton(parent, label, col, order, onClick)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, ROW_H)
    btn.BackgroundColor3 = col or C.Accent
    btn.BorderSizePixel  = 0
    btn.Text             = label
    btn.TextColor3       = C.TextW
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = FONT_SM
    btn.LayoutOrder      = order or 99
    btn.Parent           = parent
    Instance.new("UICorner", btn).CornerRadius = BTN_RAD

    local function activate()
        TweenService:Create(btn, TweenInfo.new(0.08), {
            BackgroundColor3 = (col or C.Accent):Lerp(Color3.new(1,1,1), 0.2)
        }):Play()
        task.delay(0.12, function()
            TweenService:Create(btn, TweenInfo.new(0.08), {
                BackgroundColor3 = col or C.Accent
            }):Play()
        end)
        if onClick then pcall(onClick) end
    end

    btn.MouseButton1Click:Connect(activate)
    btn.TouchTap:Connect(activate)
    return btn
end

local function makeDivider(parent, order)
    local d = Instance.new("Frame")
    d.Size             = UDim2.new(1, 0, 0, 1)
    d.BackgroundColor3 = C.Border
    d.BorderSizePixel  = 0
    d.LayoutOrder      = order or 99
    d.Parent           = parent
    return d
end

local function makeSlider(parent, label, stateKey, minV, maxV, step, suffix, order)
    suffix = suffix or ""
    step   = step or 1
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1, 0, 0, math.floor(54*SCALE))
    frame.BackgroundTransparency = 1
    frame.LayoutOrder      = order or 99
    frame.Parent           = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1, 0, 0, math.floor(20*SCALE))
    lbl.BackgroundTransparency = 1
    lbl.TextColor3        = C.TextW
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = FONT_SM
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Text              = label .. ": " .. tostring(S[stateKey]) .. suffix
    lbl.Parent            = frame

    local trackH = math.floor(8 * SCALE)
    local knobS  = math.floor(16 * SCALE)

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, 0, 0, trackH)
    track.Position         = UDim2.new(0, 0, 0, math.floor(26*SCALE))
    track.BackgroundColor3 = C.Border
    track.BorderSizePixel  = 0
    track.Parent           = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local pct0 = math.clamp((S[stateKey] - minV) / (maxV - minV), 0, 1)

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new(pct0, 0, 1, 0)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel  = 0
    fill.Parent           = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Size             = UDim2.new(0, knobS, 0, knobS)
    knob.Position         = UDim2.new(pct0, -knobS/2, 0.5, -knobS/2)
    knob.BackgroundColor3 = C.TextW
    knob.Text             = ""
    knob.BorderSizePixel  = 0
    knob.AutoButtonColor  = false
    knob.Parent           = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local sliding = false

    local function applyX(absX)
        local tPos  = track.AbsolutePosition
        local tSize = track.AbsoluteSize
        local rel   = math.clamp((absX - tPos.X) / tSize.X, 0, 1)
        local raw   = minV + rel * (maxV - minV)
        local snap  = math.floor(raw / step + 0.5) * step
        snap        = math.clamp(math.floor(snap * 100 + 0.5) / 100, minV, maxV)
        S[stateKey] = snap
        local p     = (snap - minV) / (maxV - minV)
        fill.Size     = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, -knobS/2, 0.5, -knobS/2)
        lbl.Text      = label .. ": " .. tostring(snap) .. suffix
    end

    knob.MouseButton1Down:Connect(function() sliding = true end)
    knob.TouchLongPress:Connect(function() sliding = true end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not sliding then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            applyX(inp.Position.X)
        end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            applyX(inp.Position.X)
        end
    end)
    track.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    return frame
end

local function makeDropdown(parent, label, options, stateKey, order, onChange)
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize    = Enum.AutomaticSize.Y
    frame.BackgroundTransparency = 1
    frame.LayoutOrder      = order or 99
    frame.Parent           = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1, 0, 0, math.floor(20*SCALE))
    lbl.BackgroundTransparency = 1
    lbl.TextColor3        = C.TextG
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = FONT_SM
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Text              = label
    lbl.Parent            = frame

    local btnW = math.floor(UI_W / #options) - PAD

    local btnRow = Instance.new("Frame")
    btnRow.Size             = UDim2.new(1, 0, 0, ROW_H)
    btnRow.BackgroundTransparency = 1
    btnRow.Parent           = frame

    local blist = Instance.new("UIListLayout", btnRow)
    blist.FillDirection = Enum.FillDirection.Horizontal
    blist.Padding       = UDim.new(0, 4)

    local btns = {}
    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size             = UDim2.new(0, btnW, 1, 0)
        ob.BackgroundColor3 = S[stateKey] == opt and C.Accent or C.Card
        ob.BorderSizePixel  = 0
        ob.Text             = opt
        ob.TextColor3       = C.TextW
        ob.Font             = Enum.Font.GothamBold
        ob.TextSize         = FONT_SM
        ob.Parent           = btnRow
        Instance.new("UICorner", ob).CornerRadius = BTN_RAD
        btns[opt] = ob
    end

    local function selectOpt(opt)
        S[stateKey] = opt
        for o, b in pairs(btns) do
            TweenService:Create(b, TweenInfo.new(0.1), {
                BackgroundColor3 = o == opt and C.Accent or C.Card
            }):Play()
        end
        if onChange then onChange(opt) end
    end

    for opt, ob in pairs(btns) do
        local o = opt
        ob.MouseButton1Click:Connect(function() selectOpt(o) end)
        ob.TouchTap:Connect(function() selectOpt(o) end)
    end

    return frame
end

local ToastFrame = Instance.new("Frame")
ToastFrame.Size             = UDim2.new(0, math.floor(UI_W*0.7), 0, math.floor(36*SCALE))
ToastFrame.AnchorPoint      = Vector2.new(0.5, 0)
ToastFrame.Position         = UDim2.new(0.5, 0, 0, -50)
ToastFrame.BackgroundColor3 = C.Green
ToastFrame.BorderSizePixel  = 0
ToastFrame.ZIndex           = 10
ToastFrame.Parent           = GUI
Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 8)

local ToastLbl = Instance.new("TextLabel")
ToastLbl.Size       = UDim2.new(1, -10, 1, 0)
ToastLbl.Position   = UDim2.new(0, 5, 0, 0)
ToastLbl.BackgroundTransparency = 1
ToastLbl.TextColor3 = C.BG
ToastLbl.Font       = Enum.Font.GothamBold
ToastLbl.TextSize   = FONT_SM
ToastLbl.Text       = ""
ToastLbl.ZIndex     = 11
ToastLbl.Parent     = ToastFrame

local function showToast(msg, col, duration)
    ToastFrame.BackgroundColor3 = col or C.Green
    ToastLbl.Text               = msg
    TweenService:Create(ToastFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart),
        {Position = UDim2.new(0.5, 0, 0, 8)}):Play()
    task.delay(duration or 2.5, function()
        TweenService:Create(ToastFrame, TweenInfo.new(0.2),
            {Position = UDim2.new(0.5, 0, 0, -50)}):Play()
    end)
end

local function clearContent()
    for _, c in ipairs(Content:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local statsLbls = {}

local function buildFarm()
    clearContent()

    local c1 = makeCard(Content, 1)
    makeLabel(c1, "AUTO FARM", C.Accent, FONT_LG, 1)
    makeLabel(c1, "Сам читает уровень → берёт квест → ТП к NPC → ТП к мобу → атакует → повтор.", C.TextG, FONT_SM, 2)
    makeDivider(c1, 3)
    makeToggle(c1, "Включить Auto Farm", "AutoFarm", 4, function(on)
        showToast(on and "Auto Farm ВКЛЮЧЁН" or "Auto Farm выключен", on and C.Green or C.Red)
        if not on then
            S.FarmPhase  = "idle"
            S.FarmStatus = "Idle"
            S.QuestGot   = false
        end
    end)
    makeToggle(c1, "Auto Skill (скиллы во время боя)", "AutoSkill", 5, function(on)
        showToast(on and "Auto Skill ON" or "Auto Skill OFF", on and C.Green or C.Red)
    end)

    local c2 = makeCard(Content, 2)
    makeLabel(c2, "СТАТУС ФАРМА", C.Yellow, FONT_MD, 1)
    statsLbls.farmStatus = makeLabel(c2, "Idle", C.Green, FONT_SM, 2)
    statsLbls.farmPhase  = makeLabel(c2, "Фаза: idle", C.TextG, FONT_SM, 3)
    statsLbls.farm       = makeLabel(c2, "Загрузка...", C.TextG, FONT_SM, 4)
    makeDivider(c2, 5)
    makeButton(c2, "⚡ ТП в мою зону", C.Blue, 6, function()
        local range = getLevelRange()
        teleportTo(range.mobPos)
        showToast("ТП → " .. range.enemy, C.Blue)
    end)
    makeButton(c2, "◼ Стоп всё", C.Red, 7, function()
        S.AutoFarm  = false
        S.AutoCodes = false
        S.AutoChest = false
        S.AutoSkill = false
        S.FarmPhase  = "idle"
        S.FarmStatus = "Idle"
        showToast("Всё остановлено", C.Red)
    end)

    local c3 = makeCard(Content, 3)
    makeLabel(c3, "ЗОНЫ ПО УРОВНЮ", C.Yellow, FONT_MD, 1)
    local rangeStr = ""
    for _, r in ipairs(LEVEL_RANGES) do
        rangeStr = rangeStr .. string.format("Lv %d–%d  →  %s\n", r.min, r.max, r.enemy)
    end
    makeLabel(c3, rangeStr:sub(1,-2), C.TextG, FONT_SM, 2)
end

local function buildSettings()
    clearContent()

    local c1 = makeCard(Content, 1)
    makeLabel(c1, "НАСТРОЙКИ ФАРМА", C.Accent, FONT_LG, 1)
    makeDivider(c1, 2)

    makeLabel(c1, "Позиция над мобом:", C.TextG, FONT_SM, 3)
    makeDropdown(c1, "Место ТП к мобу", {"Above","Behind","Below","Front"}, "MobOffset", 4, function(v)
        showToast("Позиция: " .. v, C.Blue)
    end)

    makeSlider(c1, "Смещение Y",    "MobOffsetY", -10, 20, 0.5, "",  5)
    makeSlider(c1, "Смещение Z",    "MobOffsetZ", -10, 20, 0.5, "",  6)
    makeSlider(c1, "Дистанция атаки", "AttackDist",  2,  30, 0.5, " st", 7)
    makeSlider(c1, "Интервал скиллов","SkillInterval",0.3, 5, 0.1, "s",  8)

    local c2 = makeCard(Content, 2)
    makeLabel(c2, "ТЕСТ ПОЗИЦИИ", C.Yellow, FONT_MD, 1)
    makeButton(c2, "🎯 ТП к ближайшему мобу (тест)", C.Accent, 2, function()
        local range = getLevelRange()
        local mob   = findMobOnMap(range.enemy)
        if mob then
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            if hrp then
                local root = getRoot()
                if root then
                    root.CFrame = CFrame.new(getMobOffset(hrp.Position))
                    showToast("ТП к " .. mob.Name, C.Green)
                end
            end
        else
            showToast("Моб не найден на карте", C.Red)
        end
    end)
    makeButton(c2, "⚔ Атаковать моба (тест)", C.Red, 3, function()
        local range = getLevelRange()
        local mob   = findMobOnMap(range.enemy)
        if mob then
            attackMob(mob)
            showToast("Атака: " .. mob.Name, C.Green)
        else
            showToast("Моб не найден", C.Red)
        end
    end)
    makeButton(c2, "🎵 Использовать скиллы (тест)", C.Yellow, 4, function()
        task.spawn(useSkills)
        showToast("Скиллы нажаты", C.Yellow)
    end)
end

local function buildCodes()
    clearContent()
    local c1 = makeCard(Content, 1)
    makeLabel(c1, "AUTO CODES", C.Accent, FONT_LG, 1)
    makeLabel(c1, string.format("Всего %d кодов.", #ALL_CODES), C.TextG, FONT_SM, 2)
    makeDivider(c1, 3)
    makeToggle(c1, "Auto Redeem при загрузке", "AutoCodes", 4, function(on)
        showToast(on and "Auto Codes ON" or "Auto Codes OFF", on and C.Green or C.Red)
    end)
    makeButton(c1, "▶ Активировать ВСЕ коды", C.Green, 5, function()
        showToast("Активируем " .. #ALL_CODES .. " кодов...", C.Blue, 4)
        task.spawn(function()
            local ok = 0
            for _, entry in ipairs(ALL_CODES) do
                if redeemCode(entry.code) then ok = ok + 1 end
                task.wait(0.6)
            end
            S.CodesRedeemed = ok
            showToast(string.format("Готово! %d/%d", ok, #ALL_CODES), C.Green, 3)
        end)
    end)
    local c2 = makeCard(Content, 2)
    makeLabel(c2, "СПИСОК КОДОВ (" .. #ALL_CODES .. ")", C.Yellow, FONT_MD, 1)
    for i, entry in ipairs(ALL_CODES) do
        local row = Instance.new("Frame")
        row.Size           = UDim2.new(1, 0, 0, 0)
        row.AutomaticSize  = Enum.AutomaticSize.Y
        row.BackgroundTransparency = 1
        row.LayoutOrder    = i + 1
        row.Parent         = c2
        local rl = Instance.new("UIListLayout", row)
        rl.FillDirection = Enum.FillDirection.Vertical
        rl.Padding       = UDim.new(0, 2)
        makeLabel(row, string.format("%d. %s", i, entry.code), C.TextW, FONT_SM, 1)
        makeLabel(row, "  → " .. entry.reward, C.TextG, FONT_SM-1, 2)
        local btn = Instance.new("TextButton", row)
        btn.Size = UDim2.new(1, 0, 0, ROW_H)
        btn.AutomaticSize = Enum.AutomaticSize.Y
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 5
        btn.MouseButton1Click:Connect(function()
            if redeemCode(entry.code) then
                showToast("✓ " .. entry.code, C.Green)
            else
                showToast("✗ " .. entry.code, C.Red)
            end
        end)
        btn.TouchTap:Connect(function()
            if redeemCode(entry.code) then
                showToast("✓ " .. entry.code, C.Green)
            else
                showToast("✗ " .. entry.code, C.Red)
            end
        end)
    end
end

local function buildChest()
    clearContent()
    local c1 = makeCard(Content, 1)
    makeLabel(c1, "AUTO CHEST", C.Accent, FONT_LG, 1)
    makeLabel(c1, "ТП к ближайшему сундуку и открывает его.", C.TextG, FONT_SM, 2)
    makeDivider(c1, 3)
    makeToggle(c1, "Включить Auto Chest", "AutoChest", 4, function(on)
        showToast(on and "Auto Chest ON" or "Auto Chest OFF", on and C.Green or C.Red)
    end)
    local c2 = makeCard(Content, 2)
    makeLabel(c2, "ВРУЧНУЮ", C.Yellow, FONT_MD, 1)
    makeButton(c2, "📦 Открыть ближайший сундук", C.Blue, 2, function()
        local chest = findNearestChest()
        if chest then
            collectChest(chest)
            showToast("Сундук открыт! Всего: " .. S.ChestCount, C.Green)
        else
            showToast("Сундук не найден", C.Red)
        end
    end)
    local c3 = makeCard(Content, 3)
    makeLabel(c3, "СТАТИСТИКА", C.Yellow, FONT_MD, 1)
    statsLbls.chest = makeLabel(c3, "Открыто: " .. S.ChestCount, C.TextG, FONT_SM, 2)
end

local function buildQuests()
    clearContent()
    local c1 = makeCard(Content, 1)
    makeLabel(c1, "КВЕСТ NPC", C.Accent, FONT_LG, 1)
    makeLabel(c1, "ТП к NPC + взять квест одной кнопкой.", C.TextG, FONT_SM, 2)
    for i, npc in ipairs(QUEST_NPCS) do
        local qCard = makeCard(Content, i + 1)
        makeLabel(qCard, npc.name, C.TextW, FONT_SM, 1)
        makeLabel(qCard, string.format("%.0f, %.0f, %.0f", npc.pos.X, npc.pos.Y, npc.pos.Z), C.TextG, FONT_SM-1, 2)
        local btnRow = Instance.new("Frame")
        btnRow.Size            = UDim2.new(1, 0, 0, ROW_H)
        btnRow.BackgroundTransparency = 1
        btnRow.LayoutOrder     = 3
        btnRow.Parent          = qCard
        local blist = Instance.new("UIListLayout", btnRow)
        blist.FillDirection = Enum.FillDirection.Horizontal
        blist.Padding       = UDim.new(0, 6)

        local tpBtn = Instance.new("TextButton")
        tpBtn.Size             = UDim2.new(0.47, 0, 1, 0)
        tpBtn.BackgroundColor3 = C.Blue
        tpBtn.BorderSizePixel  = 0
        tpBtn.Text             = "⚡ ТП"
        tpBtn.TextColor3       = C.TextW
        tpBtn.Font             = Enum.Font.GothamBold
        tpBtn.TextSize         = FONT_SM
        tpBtn.Parent           = btnRow
        Instance.new("UICorner", tpBtn).CornerRadius = BTN_RAD
        local pos = npc.pos
        tpBtn.MouseButton1Click:Connect(function() teleportTo(pos) showToast("ТП → " .. npc.name:sub(1,20), C.Blue) end)
        tpBtn.TouchTap:Connect(function() teleportTo(pos) showToast("ТП → " .. npc.name:sub(1,20), C.Blue) end)

        local qBtn = Instance.new("TextButton")
        qBtn.Size             = UDim2.new(0.47, 0, 1, 0)
        qBtn.BackgroundColor3 = C.Accent
        qBtn.BorderSizePixel  = 0
        qBtn.Text             = "✓ Взять квест"
        qBtn.TextColor3       = C.TextW
        qBtn.Font             = Enum.Font.GothamBold
        qBtn.TextSize         = FONT_SM
        qBtn.Parent           = btnRow
        Instance.new("UICorner", qBtn).CornerRadius = BTN_RAD
        local qname = npc.name
        qBtn.MouseButton1Click:Connect(function()
            giveQuest(qname)
            teleportTo(pos)
            showToast("Квест: " .. qname:sub(1,20), C.Green)
        end)
        qBtn.TouchTap:Connect(function()
            giveQuest(qname)
            teleportTo(pos)
            showToast("Квест: " .. qname:sub(1,20), C.Green)
        end)
    end
end

local function buildStats()
    clearContent()
    local c1 = makeCard(Content, 1)
    makeLabel(c1, "СТАТИСТИКА ИГРОКА", C.Accent, FONT_LG, 1)
    statsLbls.statsMain = makeLabel(c1, "Загрузка...", C.TextG, FONT_SM, 2)
    local c2 = makeCard(Content, 2)
    makeLabel(c2, "СЕССИЯ", C.Yellow, FONT_MD, 1)
    statsLbls.statsSession = makeLabel(c2, "Загрузка...", C.TextG, FONT_SM, 2)
    local c3 = makeCard(Content, 3)
    makeLabel(c3, "ИНФОРМАЦИЯ", C.Blue, FONT_MD, 1)
    makeLabel(c3, string.format(
        "NEX HUB Beta 1.0  |  Clover Origins\nУстройство: %s\nЭкран: %dx%d  |  Scale: %.2f",
        IS_MOBILE and "Mobile" or "PC",
        math.floor(VP.X), math.floor(VP.Y), SCALE
    ), C.TextG, FONT_SM, 2)
end

local TAB_BUILDERS = {
    Farm     = buildFarm,
    Settings = buildSettings,
    Codes    = buildCodes,
    Chest    = buildChest,
    Quests   = buildQuests,
    Stats    = buildStats,
}

local function switchTab(name)
    S.ActiveTab = name
    for tname, btn in pairs(tabBtns) do
        if tname == name then
            btn.BackgroundColor3 = C.Accent
            btn.TextColor3       = C.TextW
        else
            btn.BackgroundColor3 = C.Card
            btn.TextColor3       = C.TextG
        end
    end
    if TAB_BUILDERS[name] then TAB_BUILDERS[name]() end
end

for tname, btn in pairs(tabBtns) do
    local n = tname
    btn.MouseButton1Click:Connect(function() switchTab(n) end)
    btn.TouchTap:Connect(function() switchTab(n) end)
end

RunService.Heartbeat:Connect(function()
    local hum   = getHum()
    local lv    = getLevel()
    local range = getLevelRange()

    if statsLbls.farmStatus and statsLbls.farmStatus.Parent then
        statsLbls.farmStatus.Text = S.FarmStatus
        statsLbls.farmStatus.TextColor3 = S.AutoFarm and C.Green or C.TextG
    end
    if statsLbls.farmPhase and statsLbls.farmPhase.Parent then
        statsLbls.farmPhase.Text = "Фаза: " .. S.FarmPhase
    end
    if statsLbls.farm and statsLbls.farm.Parent then
        statsLbls.farm.Text = string.format(
            "Уровень: %d  |  Зона: %s\nВремя: %s  |  Убийств: %d\nКвест: %s\nАвто Скилл: %s",
            lv, range.enemy,
            formatTime(S.FarmTime), S.KillCount,
            range.quest:sub(1, 30),
            S.AutoSkill and "ON" or "OFF"
        )
    end
    if statsLbls.chest and statsLbls.chest.Parent then
        statsLbls.chest.Text = "Открыто: " .. S.ChestCount
    end
    if statsLbls.statsMain and statsLbls.statsMain.Parent then
        local hp    = hum and math.floor(hum.Health) or 0
        local maxhp = hum and math.floor(hum.MaxHealth) or 0
        statsLbls.statsMain.Text = string.format(
            "Уровень: %d\nHP: %d / %d\nЗона: %s (Lv %d–%d)\nКвест: %s",
            lv, hp, maxhp,
            range.enemy, range.min, range.max,
            range.quest:sub(1,30)
        )
    end
    if statsLbls.statsSession and statsLbls.statsSession.Parent then
        statsLbls.statsSession.Text = string.format(
            "Время фарма: %s\nАвто Фарм: %s\nАвто Скилл: %s\nАвто Коды: %s\nАвто Сундук: %s\nУбийств: %d\nСундуков: %d\nКодов: %d",
            formatTime(S.FarmTime),
            S.AutoFarm  and "ON" or "OFF",
            S.AutoSkill and "ON" or "OFF",
            S.AutoCodes and "ON" or "OFF",
            S.AutoChest and "ON" or "OFF",
            S.KillCount,
            S.ChestCount,
            S.CodesRedeemed
        )
    end
end)

switchTab("Farm")

if IS_MOBILE then
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size             = UDim2.new(0, math.floor(52*SCALE), 0, math.floor(52*SCALE))
    ToggleBtn.Position         = UDim2.new(0, 6, 0.5, -math.floor(26*SCALE))
    ToggleBtn.BackgroundColor3 = C.Accent
    ToggleBtn.BorderSizePixel  = 0
    ToggleBtn.Text             = "⚡"
    ToggleBtn.TextColor3       = C.TextW
    ToggleBtn.Font             = Enum.Font.GothamBold
    ToggleBtn.TextSize         = math.floor(22*SCALE)
    ToggleBtn.ZIndex           = 5
    ToggleBtn.Parent           = GUI
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
    ToggleBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)
    ToggleBtn.TouchTap:Connect(function() Main.Visible = not Main.Visible end)
end

if not IS_MOBILE then
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.Insert then toggleOpen() end
    end)
end

task.spawn(function()
    task.wait(1)
    if S.AutoCodes then
        for _, entry in ipairs(ALL_CODES) do
            if redeemCode(entry.code) then S.CodesRedeemed += 1 end
            task.wait(0.7)
        end
    end
end)

showToast("NEX HUB Beta 1.0 загружен!", C.Green, 3)
print("✅ NEX HUB Beta 1.0 | " .. (IS_MOBILE and "Mobile" or "PC") .. " | Scale: " .. string.format("%.2f", SCALE))
