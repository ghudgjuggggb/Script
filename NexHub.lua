if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(0.3)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RS               = game:GetService("ReplicatedStorage")
local VIM              = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer

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
    AutoFarm             = false,
    AutoCodes            = false,
    AutoChest            = false,
    AutoSkill            = false,
    FarmTime             = 0,
    KillCount            = 0,
    ChestCount           = 0,
    CodesRedeemed        = 0,
    MobOffset            = "Above",
    MobOffsetY           = 4,
    MobOffsetZ           = 0,
    AttackDist           = 8,
    SkillInterval        = 1.2,
    QuestGot             = false,
    CurrentMob           = nil,
    FarmStatus           = "Idle",
    FarmPhase            = "idle",
}

local ALL_CODES = {
    {code="SHUTDOWNSORRY7!", reward="2x EXP + 2x Luck 1hr"},
    {code="85KLIKES!",       reward="10k Yens + Spins"},
    {code="80KLIKES!",       reward="10k Yens + Spins"},
    {code="UPDATE4!",        reward="10k Yens + Spins"},
    {code="THANKS2!",        reward="50 Race + 25 Grimoire Spins"},
    {code="75KLIKES!",       reward="10k Yens + Spins"},
    {code="70KLIKES!",       reward="10k Yens + Spins"},
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
    {min=1,    max=49,   enemy="Bandit",             quest="Bandit Boss Quest Lvl 50",             questPos=Vector3.new(155.27,   5.18,  -330.74),  mobPos=Vector3.new(155.27,   5.18,  -330.74)},
    {min=50,   max=149,  enemy="Boar",               quest="Boar Quest Lvl 150",                   questPos=Vector3.new(-121.18,  15.71, -844.86),  mobPos=Vector3.new(-121.18,  15.71, -844.86)},
    {min=150,  max=249,  enemy="Boar Boss",          quest="Boar Boss Quest Lvl 250",              questPos=Vector3.new(-576.53,  10.98, -946.72),  mobPos=Vector3.new(-576.53,  10.98, -946.72)},
    {min=250,  max=449,  enemy="Corrupted Wiz",      quest="Corrupted Wizards Quest Lvl 450",      questPos=Vector3.new(-310.15,  33.00,-2063.69),  mobPos=Vector3.new(-310.15,  33.00,-2063.69)},
    {min=450,  max=999,  enemy="Earth Wizard",       quest="Quest Giver Earth Wizard 2000+",       questPos=Vector3.new(536.77,   14.15, -416.55),  mobPos=Vector3.new(536.77,   14.15, -416.55)},
    {min=1000, max=2549, enemy="Corrupted Nobleman", quest="Quest Giver Corrupted Nobleman 2550+", questPos=Vector3.new(-449.13,  11.14, -724.49),  mobPos=Vector3.new(-449.13,  11.14, -724.49)},
}

local QUEST_NPCS = {
    {name="Bandit Quest Lvl 1",                   pos=Vector3.new(289.63,   5.68,  -720.66)},
    {name="Bandit Boss Quest Lvl 50",             pos=Vector3.new(155.27,   5.18,  -330.74)},
    {name="Boar Quest Lvl 150",                   pos=Vector3.new(-121.18,  15.71, -844.86)},
    {name="Boar Boss Quest Lvl 250",              pos=Vector3.new(-576.53,  10.98, -946.72)},
    {name="Corrupted Wizards Quest Lvl 450",      pos=Vector3.new(-310.15,  33.00,-2063.69)},
    {name="Quest Giver Water Wizard",             pos=Vector3.new(-325.87,  11.14, -571.94)},
    {name="Quest Giver Earth Wizard 2000+",       pos=Vector3.new(536.77,   14.15, -416.55)},
    {name="Quest Giver Corrupted Nobleman 2550+", pos=Vector3.new(-449.13,  11.14, -724.49)},
    {name="Secondary Quest Giver Wheat",          pos=Vector3.new(-3.40,    5.18,  -623.19)},
    {name="BroomQuest",                           pos=Vector3.new(328.52,   17.29, -534.90)},
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

local function getBeli()
    local data = LP:FindFirstChild("PlayerData") or LP:FindFirstChild("Data")
    if data then
        local beli = data:FindFirstChild("Beli") or data:FindFirstChild("Gold") or data:FindFirstChild("Money")
        if beli then return beli.Value end
    end
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        local b = ls:FindFirstChild("Beli") or ls:FindFirstChild("Gold") or ls:FindFirstChild("Money")
        if b then return b.Value end
    end
    return 0
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
                    if obj.Name:lower():find(mobName:lower(), 1, true) then
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
    local root   = getRoot()
    local mobHRP = mob:FindFirstChild("HumanoidRootPart")
    if not root or not mobHRP then return end
    root.CFrame = CFrame.new(getMobOffset(mobHRP.Position))
    task.wait(0.05)
    pcall(function() safeFireServer(R.Combat, mob) end)
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
    for _, key in ipairs({
        Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.R,
        Enum.KeyCode.F, Enum.KeyCode.T, Enum.KeyCode.G,
        Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C,
    }) do
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
    for _, cname in ipairs({"Chests","Items","Chest","WorldItems"}) do
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
                        S.QuestGot   = true
                        S.FarmPhase  = "find_mob"
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
                                    root.CFrame = CFrame.new(getMobOffset(hrp.Position))
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
                                        mob.Name, hum and hum.Health or 0, d
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

local RayfieldOk, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not RayfieldOk or not Rayfield then
    warn("[NexHub] Rayfield не загрузился: " .. tostring(Rayfield))
    return
end

local Window = Rayfield:CreateWindow({
    Name                  = "Nex Hub  |  Clover Origins  v1.0",
    LoadingTitle          = "Nex Hub",
    LoadingSubtitle       = "Clover Origins  •  Beta 1.0",
    Theme                 = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings  = false,
})

local FarmTab = Window:CreateTab("⚔ Auto Farm", 4483345998)

FarmTab:CreateSection("Управление")

FarmTab:CreateToggle({
    Name         = "Auto Farm",
    CurrentValue = false,
    Flag         = "AutoFarm",
    Callback     = function(v)
        S.AutoFarm = v
        if not v then
            S.FarmPhase  = "idle"
            S.FarmStatus = "Idle"
            S.QuestGot   = false
            S.CurrentMob = nil
        end
    end,
})

FarmTab:CreateToggle({
    Name         = "Auto Skill",
    CurrentValue = false,
    Flag         = "AutoSkill",
    Callback     = function(v) S.AutoSkill = v end,
})

FarmTab:CreateSection("Статус фарма")

local farmStatusLbl = FarmTab:CreateLabel("Статус: Idle")
local farmInfoLbl   = FarmTab:CreateLabel("Уровень: —  |  Зона: —")
local farmTimeLbl   = FarmTab:CreateLabel("Время: 00:00:00  |  Убийств: 0")
local farmQuestLbl  = FarmTab:CreateLabel("Квест: —")

FarmTab:CreateSection("Быстрые действия")

FarmTab:CreateButton({
    Name     = "ТП в мою зону",
    Callback = function()
        local range = getLevelRange()
        teleportTo(range.mobPos)
        Rayfield:Notify({Title="Nex Hub", Content="ТП → " .. range.enemy, Duration=2})
    end,
})

FarmTab:CreateButton({
    Name     = "Стоп всё",
    Callback = function()
        S.AutoFarm  = false
        S.AutoSkill = false
        S.AutoChest = false
        S.AutoCodes = false
        S.FarmPhase  = "idle"
        S.FarmStatus = "Idle"
        Rayfield:Notify({Title="Nex Hub", Content="Всё остановлено", Duration=2})
    end,
})

FarmTab:CreateSection("Зоны по уровню")

local zoneStr = ""
for _, r in ipairs(LEVEL_RANGES) do
    zoneStr = zoneStr .. string.format("Lv %d–%d  →  %s\n", r.min, r.max, r.enemy)
end
FarmTab:CreateLabel(zoneStr:sub(1, -2))

local SettTab = Window:CreateTab("⚙ Настройки", 4483345998)

SettTab:CreateSection("Позиция к мобу")

SettTab:CreateDropdown({
    Name         = "Место ТП к мобу",
    Options      = {"Above", "Behind", "Below", "Front"},
    CurrentOption = {"Above"},
    Flag         = "MobOffset",
    Callback     = function(v) S.MobOffset = v end,
})

SettTab:CreateSlider({
    Name         = "Смещение по Y",
    Range        = {-10, 20},
    Increment    = 0.5,
    CurrentValue = 4,
    Flag         = "MobOffsetY",
    Callback     = function(v) S.MobOffsetY = v end,
})

SettTab:CreateSlider({
    Name         = "Смещение по Z",
    Range        = {-10, 20},
    Increment    = 0.5,
    CurrentValue = 0,
    Flag         = "MobOffsetZ",
    Callback     = function(v) S.MobOffsetZ = v end,
})

SettTab:CreateSection("Атака")

SettTab:CreateSlider({
    Name         = "Дистанция атаки (studs)",
    Range        = {2, 30},
    Increment    = 0.5,
    CurrentValue = 8,
    Flag         = "AttackDist",
    Callback     = function(v) S.AttackDist = v end,
})

SettTab:CreateSlider({
    Name         = "Интервал скиллов (сек)",
    Range        = {0.3, 5},
    Increment    = 0.1,
    CurrentValue = 1.2,
    Flag         = "SkillInterval",
    Callback     = function(v) S.SkillInterval = v end,
})

SettTab:CreateSection("Тест позиции")

SettTab:CreateButton({
    Name     = "ТП к ближайшему мобу (тест)",
    Callback = function()
        local range = getLevelRange()
        local mob   = findMobOnMap(range.enemy)
        if mob then
            local hrp  = mob:FindFirstChild("HumanoidRootPart")
            local root = getRoot()
            if hrp and root then
                root.CFrame = CFrame.new(getMobOffset(hrp.Position))
                Rayfield:Notify({Title="Nex Hub", Content="ТП к " .. mob.Name, Duration=2})
            end
        else
            Rayfield:Notify({Title="Nex Hub", Content="Моб не найден на карте", Duration=2})
        end
    end,
})

SettTab:CreateButton({
    Name     = "Атаковать моба (тест)",
    Callback = function()
        local range = getLevelRange()
        local mob   = findMobOnMap(range.enemy)
        if mob then
            attackMob(mob)
            Rayfield:Notify({Title="Nex Hub", Content="Атака: " .. mob.Name, Duration=2})
        else
            Rayfield:Notify({Title="Nex Hub", Content="Моб не найден", Duration=2})
        end
    end,
})

SettTab:CreateButton({
    Name     = "Нажать скиллы (тест)",
    Callback = function()
        task.spawn(useSkills)
        Rayfield:Notify({Title="Nex Hub", Content="Скиллы нажаты", Duration=2})
    end,
})

local QuestTab = Window:CreateTab("📜 Квесты", 4483345998)

QuestTab:CreateSection("Квест NPC — ТП + взять")

for _, npc in ipairs(QUEST_NPCS) do
    local npcName = npc.name
    local npcPos  = npc.pos
    QuestTab:CreateButton({
        Name     = npcName,
        Callback = function()
            teleportTo(npcPos)
            task.wait(0.4)
            giveQuest(npcName)
            Rayfield:Notify({
                Title   = "Nex Hub",
                Content = "ТП + квест: " .. npcName,
                Duration = 3,
            })
        end,
    })
end

QuestTab:CreateSection("Только ТП")

for _, npc in ipairs(QUEST_NPCS) do
    local npcName = npc.name
    local npcPos  = npc.pos
    QuestTab:CreateButton({
        Name     = "ТП → " .. npcName:sub(1, 28),
        Callback = function()
            teleportTo(npcPos)
            Rayfield:Notify({Title="Nex Hub", Content="ТП → " .. npcName, Duration=2})
        end,
    })
end

local ChestTab = Window:CreateTab("📦 Сундуки", 4483345998)

ChestTab:CreateSection("Auto Chest")

ChestTab:CreateToggle({
    Name         = "Auto Chest (авто сбор)",
    CurrentValue = false,
    Flag         = "AutoChest",
    Callback     = function(v) S.AutoChest = v end,
})

ChestTab:CreateSection("Вручную")

local chestCountLbl = ChestTab:CreateLabel("Открыто: 0")

ChestTab:CreateButton({
    Name     = "Открыть ближайший сундук",
    Callback = function()
        local chest = findNearestChest()
        if chest then
            collectChest(chest)
            chestCountLbl:Set("Открыто: " .. S.ChestCount)
            Rayfield:Notify({Title="Nex Hub", Content="Сундук открыт! Всего: " .. S.ChestCount, Duration=2})
        else
            Rayfield:Notify({Title="Nex Hub", Content="Сундук не найден рядом", Duration=2})
        end
    end,
})

local CodesTab = Window:CreateTab("🎁 Коды", 4483345998)

CodesTab:CreateSection("Auto Codes")

CodesTab:CreateToggle({
    Name         = "Auto Redeem при загрузке",
    CurrentValue = false,
    Flag         = "AutoCodes",
    Callback     = function(v) S.AutoCodes = v end,
})

local codesResultLbl = CodesTab:CreateLabel("Активировано: 0 / " .. #ALL_CODES)

CodesTab:CreateButton({
    Name     = "▶  Активировать ВСЕ коды",
    Callback = function()
        Rayfield:Notify({Title="Nex Hub", Content="Активируем " .. #ALL_CODES .. " кодов...", Duration=4})
        task.spawn(function()
            local ok = 0
            for _, entry in ipairs(ALL_CODES) do
                if redeemCode(entry.code) then ok = ok + 1 end
                task.wait(0.6)
            end
            S.CodesRedeemed = ok
            codesResultLbl:Set("Активировано: " .. ok .. " / " .. #ALL_CODES)
            Rayfield:Notify({
                Title   = "Nex Hub",
                Content = string.format("Готово! %d / %d кодов", ok, #ALL_CODES),
                Duration = 4,
            })
        end)
    end,
})

CodesTab:CreateSection("Все коды (" .. #ALL_CODES .. ")")

for i, entry in ipairs(ALL_CODES) do
    local code   = entry.code
    local reward = entry.reward
    CodesTab:CreateButton({
        Name     = string.format("%d. %s  —  %s", i, code, reward),
        Callback = function()
            if redeemCode(code) then
                Rayfield:Notify({Title="✓ " .. code, Content=reward, Duration=3})
            else
                Rayfield:Notify({Title="✗ " .. code, Content="Не удалось", Duration=2})
            end
        end,
    })
end

local StatsTab = Window:CreateTab("📊 Статистика", 4483345998)

StatsTab:CreateSection("Игрок")

local statsPlayerLbl  = StatsTab:CreateLabel("Загрузка...")
local statsSessionLbl = StatsTab:CreateLabel("Загрузка...")

StatsTab:CreateSection("Информация")
StatsTab:CreateLabel("Nex Hub  •  Beta 1.0  •  Clover Origins")

RunService.Heartbeat:Connect(function()
    local lv    = getLevel()
    local beli  = getBeli()
    local range = getLevelRange()
    local hum   = getHum()

    local hp    = hum and math.floor(hum.Health)    or 0
    local maxhp = hum and math.floor(hum.MaxHealth) or 0

    farmStatusLbl:Set("Статус: " .. S.FarmStatus)
    farmInfoLbl:Set(string.format(
        "Уровень: %d  |  Зона: %s  |  Beli: %d",
        lv, range.enemy, beli
    ))
    farmTimeLbl:Set(string.format(
        "Время: %s  |  Убийств: %d",
        formatTime(S.FarmTime), S.KillCount
    ))
    farmQuestLbl:Set("Квест: " .. range.quest:sub(1, 40))

    chestCountLbl:Set("Открыто: " .. S.ChestCount)

    statsPlayerLbl:Set(string.format(
        "Уровень: %d\nHP: %d / %d\nBeli: %d\nЗона: %s  (Lv %d – %d)",
        lv, hp, maxhp, beli,
        range.enemy, range.min, range.max
    ))

    statsSessionLbl:Set(string.format(
        "Время фарма: %s\nАвто Фарм:  %s  |  Авто Скилл: %s\nАвто Коды:  %s  |  Авто Сундук: %s\nУбийств: %d  |  Сундуков: %d  |  Кодов: %d\nФаза: %s",
        formatTime(S.FarmTime),
        S.AutoFarm  and "ON" or "OFF",
        S.AutoSkill and "ON" or "OFF",
        S.AutoCodes and "ON" or "OFF",
        S.AutoChest and "ON" or "OFF",
        S.KillCount, S.ChestCount, S.CodesRedeemed,
        S.FarmPhase
    ))
end)

task.spawn(function()
    task.wait(1)
    if S.AutoCodes then
        for _, entry in ipairs(ALL_CODES) do
            if redeemCode(entry.code) then S.CodesRedeemed = S.CodesRedeemed + 1 end
            task.wait(0.7)
        end
    end
end)

Rayfield:Notify({
    Title    = "Nex Hub",
    Content  = "Beta 1.0 загружен!  Lv " .. getLevel() .. "  |  " .. getLevelRange().enemy,
    Duration = 5,
})

print("✅ Nex Hub Beta 1.0  |  Clover Origins  |  Lv " .. getLevel())
