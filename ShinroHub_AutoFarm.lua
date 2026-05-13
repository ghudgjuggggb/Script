local ShinroHub = {
    Version = "4.0.0",
    StartTime = tick(),
    AutoFarm = true,
    AutoQuest = true,
    AutoCombat = true,
    AutoSkills = true,
    AutoLevelUp = true,
    AutoStats = true,
    AutoMissions = true,
    AutoRepeatQuest = true,
    AutoDungeon = true,
    AutoInteract = true,
    AutoCollect = true,
    FastAttack = true,
    NoCooldown = true,
    AntiAFK = true,
    AntiDie = true,
    AutoRespawn = true,
    Speed = 200,
    AttackDelay = 0.01,
    QuestDelay = 0.5,
    CurrentQuest = nil,
    CurrentEnemy = nil,
    CurrentLevel = 1,
    TargetLevel = 9999,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

local Remotes = {
    Quests = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Quests"),
    Combat = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Combat"),
    Skills = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Skills"),
    LevelUp = ReplicatedStorage:WaitForChild("Events"):WaitForChild("LevelUp"),
    Stats = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Stats"),
    Missions = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Missions"),
    RepeatQuest = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RepeatQuest"),
    Interact = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Interact"),
    Die = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Die"),
    SpawnCharacter = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SpawnCharacter"),
    DungeonJoin = ReplicatedStorage:WaitForChild("Events"):WaitForChild("DungeonJoin"),
    SatchelHandler = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SatchelHandler"),
    MotionHandler = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MotionHandler"),
    MousePosition = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MousePosition"),
    StateReset = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("StateReset"),
    BeforeAttack = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Fight"):WaitForChild("BeforeAttack"),
    Stun = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Fight"):WaitForChild("Stun"),
    Burn = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Burn"),
    Ragdoll = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Ragdoll"),
    DoubleJump = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DoubleJump"),
    Dash = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Dash"),
    FireArm = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FireArm"),
    MagicSense = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MagicSense"),
    Notification = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notification"),
    Cooldown = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Cooldown"),
    Orb = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Orb"),
    DropDisplay = ReplicatedStorage:WaitForChild("Events"):WaitForChild("DropDisplay"),
    Codes = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Codes"),
    Spins = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Spins"),
    Craft = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Craft"),
    ItemShop = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemShop"),
    Inventory = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Inventory"),
    InventoryValidateTool = ReplicatedStorage:WaitForChild("Events"):WaitForChild("InventoryValidateTool"),
    Battlepass = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Battlepass"),
    PlayTime = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayTime"),
    Gift = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Gift"),
    Titles = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Titles"),
    Teams = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Teams"),
    Pvp = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Pvp"),
    Party = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Party"),
    Squad = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Squad"),
    Invite = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Invite"),
    Tutorial = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Tutorial"),
    FirstJoin = ReplicatedStorage:WaitForChild("Events"):WaitForChild("FirstJoin"),
    PlayScreen = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayScreen"),
    MobileButtons = ReplicatedStorage:WaitForChild("Events"):WaitForChild("MobileButtons"),
    Configs = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Configs"),
    ChatNotify = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ChatNotify"),
    NpcWarn = ReplicatedStorage:WaitForChild("Events"):WaitForChild("NpcWarn"),
    Indicator = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Indicator"),
    ManaSenseQuest = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ManaSenseQuest"),
    MagicKnightExam = ReplicatedStorage:WaitForChild("Events"):WaitForChild("MagicKnightExam"),
    SecondaryQuestTools = ReplicatedStorage:WaitForChild("Events"):WaitForChild("SecondaryQuestTools"),
    BlackMarket = ReplicatedStorage:WaitForChild("Events"):WaitForChild("BlackMarket"),
    BlackMarketOpen = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BlackMarketOpen"),
    BossSpawned = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BossSpawned"),
    Broom = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Broom"),
    BuyRobux = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuyRobux"),
    DieCharacter = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DieCharacter"),
    DisableChest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DisableChest"),
    Error = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Error"),
    ForceLock = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ForceLock"),
    GetButtonsData = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetButtonsData"),
    OpenActionButtonsConfigure = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("OpenActionButtonsConfigure"),
    PlayerStatsReset = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerStatsReset"),
    replicate = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("emitAll"):WaitForChild("replicate"),
}

local function GetCharacter()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function GetHRP()
    local char = GetCharacter()
    return char:WaitForChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char:FindFirstChildOfClass("Humanoid")
end

local function GetLevel()
    local leaderstats = LP:FindFirstChild("leaderstats")
    if leaderstats then
        local lvl = leaderstats:FindFirstChild("Level")
        if lvl then return lvl.Value end
    end

    local data = LP:FindFirstChild("Data")
    if data then
        local lvl = data:FindFirstChild("Level") or data:FindFirstChild("level") or data:FindFirstChild("Lvl")
        if lvl then return lvl.Value end
    end

    return 1
end

local function GetExp()
    local data = LP:FindFirstChild("Data")
    if data then
        local exp = data:FindFirstChild("Exp") or data:FindFirstChild("EXP") or data:FindFirstChild("Experience")
        if exp then return exp.Value end
    end
    return 0
end

local function GetMoney()
    local leaderstats = LP:FindFirstChild("leaderstats")
    if leaderstats then
        local money = leaderstats:FindFirstChild("Money") or leaderstats:FindFirstChild("Gold") or leaderstats:FindFirstChild("Coins") or leaderstats:FindFirstChild("Beli")
        if money then return money.Value end
    end

    local data = LP:FindFirstChild("Data")
    if data then
        local money = data:FindFirstChild("Money") or data:FindFirstChild("Gold") or data:FindFirstChild("Coins") or data:FindFirstChild("Beli")
        if money then return money.Value end
    end

    return 0
end

local function FormatNumber(num)
    if num >= 1000000000 then
        return string.format("%.2fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.2fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.2fK", num / 1000)
    end
    return tostring(num)
end

local function FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

local function TweenTo(pos, speed)
    local hrp = GetHRP()
    local distance = (pos - hrp.Position).Magnitude
    local time = distance / (speed or ShinroHub.Speed)
    local tween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(pos)
    })
    tween:Play()
    tween.Completed:Wait()
end

local function InstantTP(pos)
    local hrp = GetHRP()
    hrp.CFrame = CFrame.new(pos)
end

local function FireRemote(remote, args)
    args = args or {}
    if not remote then return false end
    local success, result = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(unpack(args))
        elseif remote:IsA("RemoteFunction") then
            return remote:InvokeServer(unpack(args))
        end
    end)
    return success, result
end

local function GetEnemies()
    local enemies = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v ~= LP.Character and v.Humanoid.Health > 0 then
                if v.Name:lower():find("mob") or v.Name:lower():find("enemy") or v.Name:lower():find("npc") or v.Name:lower():find("boss") or v.Name:lower():find("monster") then
                    table.insert(enemies, v)
                end
            end
        end
    end
    return enemies
end

local function GetNearestEnemy()
    local hrp = GetHRP()
    local nearest = nil
    local minDist = math.huge

    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v ~= LP.Character and v.Humanoid.Health > 0 then
                local dist = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = v
                end
            end
        end
    end

    return nearest, minDist
end

local function GetQuestNPCs()
    local npcs = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Name:lower():find("quest") or v.Name:lower():find("npc") or v.Name:lower():find("mission") then
                table.insert(npcs, v)
            end
        end
    end
    return npcs
end

local function GetDrops()
    local drops = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:FindFirstChild("TouchInterest") or v.Name:lower():find("drop") or v.Name:lower():find("orb") or v.Name:lower():find("coin") or v.Name:lower():find("exp") then
            table.insert(drops, v)
        end
    end
    return drops
end

local function GetNearestDrop()
    local hrp = GetHRP()
    local nearest = nil
    local minDist = math.huge

    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:FindFirstChild("TouchInterest") or v.Name:lower():find("drop") or v.Name:lower():find("orb") then
            if v:IsA("BasePart") or v:IsA("MeshPart") then
                local dist = (v.Position - hrp.Position).Magnitude
                if dist < minDist and dist < 100 then
                    minDist = dist
                    nearest = v
                end
            end
        end
    end

    return nearest, minDist
end

local function Attack()
    local char = GetCharacter()
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    end

    VirtualUser:CaptureController()
    VirtualUser:Button1Down(Vector2.new(0, 0))
    task.wait(0.01)
    VirtualUser:Button1Up(Vector2.new(0, 0))
end

local function FastAttackLoop()
    while ShinroHub.FastAttack do
        local char = GetCharacter()
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            for i = 1, 5 do
                tool:Activate()
                VirtualUser:CaptureController()
                VirtualUser:Button1Down(Vector2.new(0, 0))
                VirtualUser:Button1Up(Vector2.new(0, 0))
            end
        end

        FireRemote(Remotes.Combat, {"Attack", Mouse.Hit.Position})
        FireRemote(Remotes.BeforeAttack, {})

        task.wait(ShinroHub.AttackDelay)
    end
end

local function AutoQuestLoop()
    while ShinroHub.AutoQuest do
        local level = GetLevel()

        FireRemote(Remotes.Quests, {"AcceptQuest", level})
        FireRemote(Remotes.Quests, {"CompleteQuest", level})
        FireRemote(Remotes.RepeatQuest, {"Repeat", level})
        FireRemote(Remotes.Missions, {"Accept", level})
        FireRemote(Remotes.Missions, {"Complete", level})
        FireRemote(Remotes.ManaSenseQuest, {"Accept"})
        FireRemote(Remotes.SecondaryQuestTools, {"Accept"})
        FireRemote(Remotes.MagicKnightExam, {"Accept"})

        task.wait(ShinroHub.QuestDelay)
    end
end

local function AutoCombatLoop()
    while ShinroHub.AutoCombat do
        local enemy, dist = GetNearestEnemy()

        if enemy and dist < 200 then
            ShinroHub.CurrentEnemy = enemy
            local hrp = GetHRP()
            local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")

            if enemyHRP then
                hrp.CFrame = enemyHRP.CFrame * CFrame.new(0, 15, 0)

                repeat
                    if not ShinroHub.AutoCombat then break end

                    local char = GetCharacter()
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    end

                    FireRemote(Remotes.Combat, {
                        "Attack",
                        enemyHRP.Position,
                        enemy.Name,
                        enemy.Humanoid.Health
                    })

                    FireRemote(Remotes.Skills, {"UseSkill", 1})
                    FireRemote(Remotes.Skills, {"UseSkill", 2})
                    FireRemote(Remotes.Skills, {"UseSkill", 3})
                    FireRemote(Remotes.Skills, {"UseSkill", 4})

                    FireRemote(Remotes.BeforeAttack, {})
                    FireRemote(Remotes.StateReset, {})

                    VirtualUser:CaptureController()
                    VirtualUser:Button1Down(Vector2.new(0, 0))
                    VirtualUser:Button1Up(Vector2.new(0, 0))

                    task.wait(ShinroHub.AttackDelay)
                until not enemy:FindFirstChild("Humanoid") or enemy.Humanoid.Health <= 0 or not ShinroHub.AutoCombat
            end
        end

        task.wait(0.1)
    end
end

local function AutoCollectLoop()
    while ShinroHub.AutoCollect do
        local drop, dist = GetNearestDrop()

        if drop and dist < 50 then
            local hrp = GetHRP()
            hrp.CFrame = drop.CFrame
            task.wait(0.2)
        end

        FireRemote(Remotes.Orb, {"CollectAll"})
        FireRemote(Remotes.DropDisplay, {"Collect"})
        FireRemote(Remotes.Inventory, {"CollectDrops"})

        task.wait(0.5)
    end
end

local function AutoLevelUpLoop()
    while ShinroHub.AutoLevelUp do
        FireRemote(Remotes.LevelUp, {"LevelUp"})
        FireRemote(Remotes.Stats, {"AddPoint", "Melee", 1})
        FireRemote(Remotes.Stats, {"AddPoint", "Defense", 1})
        FireRemote(Remotes.Stats, {"AddPoint", "Sword", 1})
        FireRemote(Remotes.Stats, {"AddPoint", "Magic", 1})

        task.wait(1)
    end
end

local function AutoDungeonLoop()
    while ShinroHub.AutoDungeon do
        FireRemote(Remotes.DungeonJoin, {"Join", 1})
        FireRemote(Remotes.DungeonJoin, {"Start"})

        task.wait(5)
    end
end

local function AutoInteractLoop()
    while ShinroHub.AutoInteract do
        local npcs = GetQuestNPCs()
        for _, npc in ipairs(npcs) do
            if npc:FindFirstChild("HumanoidRootPart") then
                local hrp = GetHRP()
                local dist = (npc.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist < 30 then
                    FireRemote(Remotes.Interact, {"Interact", npc.Name})
                    FireRemote(Remotes.Interact, {"Talk", npc.Name})
                    FireRemote(Remotes.Interact, {"AcceptQuest", npc.Name})
                end
            end
        end

        task.wait(1)
    end
end

local function NoCooldownLoop()
    while ShinroHub.NoCooldown do
        FireRemote(Remotes.Cooldown, {"ResetAll"})

        local char = GetCharacter()
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("Tool") then
                local cd = v:FindFirstChild("Cooldown")
                if cd then
                    cd.Value = 0
                end
            end
        end

        task.wait(0.5)
    end
end

local function AntiAFKLoop()
    while ShinroHub.AntiAFK do
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0))
        task.wait(300)
    end
end

local function AntiDieLoop()
    while ShinroHub.AntiDie do
        local humanoid = GetHumanoid()
        if humanoid then
            if humanoid.Health <= 0 or humanoid.Health < humanoid.MaxHealth * 0.3 then
                humanoid.Health = humanoid.MaxHealth
                FireRemote(Remotes.StateReset, {})
                FireRemote(Remotes.Ragdoll, {"Disable"})
                FireRemote(Remotes.Stun, {"Disable"})
                FireRemote(Remotes.Burn, {"Disable"})
                FireRemote(Remotes.Die, {"Cancel"})
                FireRemote(Remotes.DieCharacter, {"Cancel"})
            end
        end

        task.wait(0.1)
    end
end

local function AutoRespawnLoop()
    while ShinroHub.AutoRespawn do
        local char = GetCharacter()
        local humanoid = char:FindFirstChildOfClass("Humanoid")

        if humanoid and humanoid.Health <= 0 then
            task.wait(2)
            FireRemote(Remotes.SpawnCharacter, {"Respawn"})
            FireRemote(Remotes.SpawnCharacter, {})
        end

        task.wait(1)
    end
end

local function AutoCodesLoop()
    while true do
        local codes = {
            "RELEASE", "UPDATE1", "UPDATE2", "UPDATE3", "UPDATE4", "UPDATE5",
            "FREEGEMS", "FREELEVEL", "BOOST", "2XEXP", "2XGEMS", "2XCOINS",
            "WELCOME", "THANKS", "SORRY", "FIXED", "BUGFIX", "PATCH",
            "HOLIDAY", "WEEKEND", "MONDAY", "FRIDAY", "WEEKLY", "DAILY",
            "NEWYEAR", "CHRISTMAS", "HALLOWEEN", "EASTER", "SUMMER", "WINTER",
            "10K", "50K", "100K", "500K", "1M", "2M", "5M", "10M",
            "LIKE100", "LIKE500", "LIKE1K", "LIKE10K", "LIKE50K", "LIKE100K",
            "FOLLOW100", "FOLLOW1K", "FOLLOW10K", "FOLLOW50K", "FOLLOW100K",
            "DISCORD", "TWITTER", "YOUTUBE", "Twitch", "ROBLOX", "GROUP",
            "SUBSCRIBE", "JOIN", "MEMBER", "VIP", "ELITE", "LEGEND",
            "ADMIN", "MOD", "TESTER", "BETA", "ALPHA", "DEV",
            "SECRET", "HIDDEN", "SPECIAL", "RARE", "EPIC", "LEGENDARY",
            "GOD", "DEMON", "ANGEL", "DRAGON", "PHOENIX", "UNICORN",
        }

        for _, code in ipairs(codes) do
            FireRemote(Remotes.Codes, {"Redeem", code})
            task.wait(0.5)
        end

        task.wait(300)
    end
end

local function AutoSpinsLoop()
    while true do
        FireRemote(Remotes.Spins, {"Spin", 1})
        FireRemote(Remotes.Spins, {"Spin", 10})
        FireRemote(Remotes.Spins, {"SpinAll"})

        task.wait(1)
    end
end

local function AutoCraftLoop()
    while true do
        FireRemote(Remotes.Craft, {"CraftAll"})
        FireRemote(Remotes.Craft, {"AutoCraft"})

        task.wait(5)
    end
end

local function AutoShopLoop()
    while true do
        FireRemote(Remotes.ItemShop, {"BuyAll"})
        FireRemote(Remotes.BlackMarket, {"Open"})
        FireRemote(Remotes.BlackMarketOpen, {})
        FireRemote(Remotes.Battlepass, {"ClaimAll"})
        FireRemote(Remotes.Gift, {"ClaimAll"})
        FireRemote(Remotes.Titles, {"ClaimAll"})
        FireRemote(Remotes.PlayTime, {"ClaimAll"})

        task.wait(10)
    end
end

local function AutoInventoryLoop()
    while true do
        FireRemote(Remotes.Inventory, {"Sort"})
        FireRemote(Remotes.Inventory, {"EquipBest"})
        FireRemote(Remotes.InventoryValidateTool, {})
        FireRemote(Remotes.SatchelHandler, {"Organize"})

        task.wait(5)
    end
end

local function AutoBuffsLoop()
    while true do
        FireRemote(Remotes.MagicSense, {"Activate"})
        FireRemote(Remotes.ForceLock, {"Activate"})
        FireRemote(Remotes.DoubleJump, {"Enable"})
        FireRemote(Remotes.Dash, {"Enable"})
        FireRemote(Remotes.FireArm, {"Activate"})
        FireRemote(Remotes.Broom, {"Equip"})

        task.wait(3)
    end
end

local function AutoNotificationsLoop()
    while true do
        FireRemote(Remotes.Notification, {"ClearAll"})
        FireRemote(Remotes.NpcWarn, {"Disable"})
        FireRemote(Remotes.Indicator, {"HideAll"})
        FireRemote(Remotes.ChatNotify, {"Disable"})

        task.wait(5)
    end
end

local function AutoSocialLoop()
    while true do
        FireRemote(Remotes.Party, {"AutoJoin"})
        FireRemote(Remotes.Squad, {"AutoJoin"})
        FireRemote(Remotes.Teams, {"AutoJoin"})
        FireRemote(Remotes.Invite, {"AcceptAll"})
        FireRemote(Remotes.Pvp, {"Disable"})

        task.wait(10)
    end
end

local function AutoTutorialSkipLoop()
    while true do
        FireRemote(Remotes.Tutorial, {"Skip"})
        FireRemote(Remotes.Tutorial, {"Complete"})
        FireRemote(Remotes.FirstJoin, {"Skip"})
        FireRemote(Remotes.PlayScreen, {"Skip"})
        FireRemote(Remotes.MobileButtons, {"Hide"})
        FireRemote(Remotes.Configs, {"SkipIntro"})

        task.wait(2)
    end
end

local function AutoMotionLoop()
    while true do
        local hrp = GetHRP()
        FireRemote(Remotes.MotionHandler, {"UpdatePosition", hrp.Position})
        FireRemote(Remotes.MousePosition, {Mouse.Hit.Position})
        FireRemote(Remotes.replicate, {"Update"})

        task.wait(0.1)
    end
end

local function AutoBossLoop()
    while true do
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v.Name:lower():find("boss") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                if v.Humanoid.Health > 0 then
                    local hrp = GetHRP()
                    hrp.CFrame = v.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0)

                    repeat
                        FireRemote(Remotes.Combat, {"Attack", v.HumanoidRootPart.Position, v.Name, v.Humanoid.Health})
                        FireRemote(Remotes.Skills, {"UseSkill", 1})
                        FireRemote(Remotes.Skills, {"UseSkill", 2})
                        FireRemote(Remotes.BeforeAttack, {})

                        VirtualUser:CaptureController()
                        VirtualUser:Button1Down(Vector2.new(0, 0))
                        VirtualUser:Button1Up(Vector2.new(0, 0))

                        task.wait(0.05)
                    until not v:FindFirstChild("Humanoid") or v.Humanoid.Health <= 0
                end
            end
        end

        task.wait(1)
    end
end

local function AutoChestsLoop()
    while true do
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v.Name:lower():find("chest") and v:FindFirstChild("TouchInterest") then
                local hrp = GetHRP()
                hrp.CFrame = v.CFrame
                task.wait(0.3)
                FireRemote(Remotes.DisableChest, {"Open", v.Name})
            end
        end

        task.wait(2)
    end
end

local function CreateMiniUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ShinroHubAutoFarm"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
    MainFrame.Size = UDim2.new(0, 260, 0, 180)
    MainFrame.Active = true
    MainFrame.Draggable = true

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(0, 170, 255)
    Stroke.Thickness = 2
    Stroke.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 28)
    Title.Position = UDim2.new(0, 0, 0, 5)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "Shinro Hub v" .. ShinroHub.Version
    Title.TextColor3 = Color3.fromRGB(0, 170, 255)
    Title.TextSize = 14

    local Status = Instance.new("TextLabel")
    Status.Name = "Status"
    Status.Parent = MainFrame
    Status.BackgroundTransparency = 1
    Status.Size = UDim2.new(1, 0, 0, 18)
    Status.Position = UDim2.new(0, 0, 0, 32)
    Status.Font = Enum.Font.GothamBold
    Status.Text = "AUTO FARM: ACTIVE"
    Status.TextColor3 = Color3.fromRGB(0, 255, 100)
    Status.TextSize = 11

    local LevelLabel = Instance.new("TextLabel")
    LevelLabel.Name = "Level"
    LevelLabel.Parent = MainFrame
    LevelLabel.BackgroundTransparency = 1
    LevelLabel.Size = UDim2.new(1, -20, 0, 18)
    LevelLabel.Position = UDim2.new(0, 10, 0, 52)
    LevelLabel.Font = Enum.Font.Gotham
    LevelLabel.Text = "Level: Loading..."
    LevelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    LevelLabel.TextSize = 12
    LevelLabel.TextXAlignment = Enum.TextXAlignment.Left

    local ExpLabel = Instance.new("TextLabel")
    ExpLabel.Name = "Exp"
    ExpLabel.Parent = MainFrame
    ExpLabel.BackgroundTransparency = 1
    ExpLabel.Size = UDim2.new(1, -20, 0, 18)
    ExpLabel.Position = UDim2.new(0, 10, 0, 70)
    ExpLabel.Font = Enum.Font.Gotham
    ExpLabel.Text = "EXP: Loading..."
    ExpLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    ExpLabel.TextSize = 12
    ExpLabel.TextXAlignment = Enum.TextXAlignment.Left

    local MoneyLabel = Instance.new("TextLabel")
    MoneyLabel.Name = "Money"
    MoneyLabel.Parent = MainFrame
    MoneyLabel.BackgroundTransparency = 1
    MoneyLabel.Size = UDim2.new(1, -20, 0, 18)
    MoneyLabel.Position = UDim2.new(0, 10, 0, 88)
    MoneyLabel.Font = Enum.Font.Gotham
    MoneyLabel.Text = "Money: Loading..."
    MoneyLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    MoneyLabel.TextSize = 12
    MoneyLabel.TextXAlignment = Enum.TextXAlignment.Left

    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Name = "Time"
    TimeLabel.Parent = MainFrame
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.Size = UDim2.new(1, -20, 0, 18)
    TimeLabel.Position = UDim2.new(0, 10, 0, 106)
    TimeLabel.Font = Enum.Font.Gotham
    TimeLabel.Text = "Farm Time: 00:00:00"
    TimeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    TimeLabel.TextSize = 11
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Left

    local EnemyLabel = Instance.new("TextLabel")
    EnemyLabel.Name = "Enemy"
    EnemyLabel.Parent = MainFrame
    EnemyLabel.BackgroundTransparency = 1
    EnemyLabel.Size = UDim2.new(1, -20, 0, 18)
    EnemyLabel.Position = UDim2.new(0, 10, 0, 124)
    EnemyLabel.Font = Enum.Font.Gotham
    EnemyLabel.Text = "Target: None"
    EnemyLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    EnemyLabel.TextSize = 11
    EnemyLabel.TextXAlignment = Enum.TextXAlignment.Left

    local QuestLabel = Instance.new("TextLabel")
    QuestLabel.Name = "Quest"
    QuestLabel.Parent = MainFrame
    QuestLabel.BackgroundTransparency = 1
    QuestLabel.Size = UDim2.new(1, -20, 0, 18)
    QuestLabel.Position = UDim2.new(0, 10, 0, 142)
    QuestLabel.Font = Enum.Font.Gotham
    QuestLabel.Text = "Quest: None"
    QuestLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    QuestLabel.TextSize = 11
    QuestLabel.TextXAlignment = Enum.TextXAlignment.Left

    local FPSLabel = Instance.new("TextLabel")
    FPSLabel.Name = "FPS"
    FPSLabel.Parent = MainFrame
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.Size = UDim2.new(1, -20, 0, 15)
    FPSLabel.Position = UDim2.new(0, 10, 0, 160)
    FPSLabel.Font = Enum.Font.Gotham
    FPSLabel.Text = "FPS: 60"
    FPSLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    FPSLabel.TextSize = 10
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Left

    return {
        Level = LevelLabel,
        Exp = ExpLabel,
        Money = MoneyLabel,
        Time = TimeLabel,
        Enemy = EnemyLabel,
        Quest = QuestLabel,
        FPS = FPSLabel,
        Status = Status,
    }
end

local Labels = CreateMiniUI()

local fpsCount = 0
local fpsTime = tick()

RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    local now = tick()
    if now - fpsTime >= 1 then
        Labels.FPS.Text = "FPS: " .. fpsCount
        fpsCount = 0
        fpsTime = now
    end

    local level = GetLevel()
    local exp = GetExp()
    local money = GetMoney()
    local elapsed = tick() - ShinroHub.StartTime

    Labels.Level.Text = "Level: " .. FormatNumber(level) .. " / " .. FormatNumber(ShinroHub.TargetLevel)
    Labels.Exp.Text = "EXP: " .. FormatNumber(exp)
    Labels.Money.Text = "Money: " .. FormatNumber(money)
    Labels.Time.Text = "Farm Time: " .. FormatTime(elapsed)

    if ShinroHub.CurrentEnemy then
        local enemyName = ShinroHub.CurrentEnemy.Name or "Unknown"
        local enemyHealth = ShinroHub.CurrentEnemy:FindFirstChild("Humanoid") and ShinroHub.CurrentEnemy.Humanoid.Health or 0
        Labels.Enemy.Text = "Target: " .. enemyName .. " | HP: " .. math.floor(enemyHealth)
    end

    if ShinroHub.CurrentQuest then
        Labels.Quest.Text = "Quest: Active | Lvl " .. level
    end

    local progress = math.min(level / ShinroHub.TargetLevel, 1)
    Labels.Status.Text = string.format("AUTO FARM: ON | %.1f%%", progress * 100)
end)

task.spawn(FastAttackLoop)
task.spawn(AutoQuestLoop)
task.spawn(AutoCombatLoop)
task.spawn(AutoCollectLoop)
task.spawn(AutoLevelUpLoop)
task.spawn(AutoDungeonLoop)
task.spawn(AutoInteractLoop)
task.spawn(NoCooldownLoop)
task.spawn(AntiAFKLoop)
task.spawn(AntiDieLoop)
task.spawn(AutoRespawnLoop)
task.spawn(AutoCodesLoop)
task.spawn(AutoSpinsLoop)
task.spawn(AutoCraftLoop)
task.spawn(AutoShopLoop)
task.spawn(AutoInventoryLoop)
task.spawn(AutoBuffsLoop)
task.spawn(AutoNotificationsLoop)
task.spawn(AutoSocialLoop)
task.spawn(AutoTutorialSkipLoop)
task.spawn(AutoMotionLoop)
task.spawn(AutoBossLoop)
task.spawn(AutoChestsLoop)

game.StarterGui:SetCore("SendNotification", {
    Title = "Shinro Hub v" .. ShinroHub.Version,
    Text = "Auto Farm Level Activated! | 22 Features Running",
    Duration = 5,
})
