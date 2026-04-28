if getgenv().RexHubLoaded then warn("[Rex Hub] Already loaded!") return end
getgenv().RexHubLoaded = true

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(0.3 + math.random() * 0.4)

local placeId = game.PlaceId
local validPlaces = {2753915549, 4442272183, 7449423635}
local isBloxFruits = table.find(validPlaces, placeId) ~= nil
if not isBloxFruits then
    pcall(function()
        local n = game:GetService("MarketplaceService"):GetProductInfo(placeId).Name or ""
        isBloxFruits = n:lower():find("blox") and n:lower():find("fruit")
    end)
end
if not isBloxFruits then
    warn("[Rex Hub] Not Blox Fruits!")
    getgenv().RexHubLoaded = nil
    return
end

if getgenv().RexHubManager then
    pcall(function() getgenv().RexHubManager:Destroy() end)
end

local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local HttpService    = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Lighting       = game:GetService("Lighting")
local CoreGui        = game:GetService("CoreGui")
local StarterGui     = game:GetService("StarterGui")
local Workspace      = game:GetService("Workspace")

local LP  = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

local Manager = {}
Manager.Connections = {}
Manager.Instances   = {}
Manager.Loops       = {}

function Manager:Connect(name, conn)
    if self.Connections[name] then pcall(function() self.Connections[name]:Disconnect() end) end
    self.Connections[name] = conn
    return conn
end
function Manager:Disconnect(name)
    if self.Connections[name] then
        pcall(function() self.Connections[name]:Disconnect() end)
        self.Connections[name] = nil
    end
end
function Manager:SetLoop(name, v) self.Loops[name] = v end
function Manager:IsLoop(name) return self.Loops[name] == true end
function Manager:Destroy()
    for _, c in pairs(self.Connections) do pcall(function() c:Disconnect() end) end
    for _, i in pairs(self.Instances)   do pcall(function() i:Destroy()     end) end
    self.Connections = {}
    self.Instances   = {}
    self.Loops       = {}
end
getgenv().RexHubManager = Manager

local Config = getgenv().RexHubConfig or {
    AutoFarm         = false,
    AutoQuest        = true,
    SmartFarm        = true,
    AutoFarmBoss     = false,
    AutoCollectDrops = true,
    ServerHopNoMobs  = false,
    FarmWeaponType   = "Combat",
    AutoSwitchWeapon = false,
    MasteryWeapon    = "Melee",
    MasteryHealthSwitch = 30,
    SelectedBoss     = "Auto",
    AutoSkill        = true,
    FastAttack       = true,
    AutoBusoHaki     = true,
    AutoKenHaki      = false,
    KillAura         = false,
    BringMobs        = true,
    ExpandHitbox     = true,
    HitboxSize       = 50,
    BringDistance    = 100,
    FarmDistance     = 50,
    FruitSniper      = false,
    FruitESP         = false,
    AutoStoreFruit   = false,
    FruitNotification= true,
    TargetFruit      = "Any",
    AutoMirage       = false,
    ESPMirage        = true,
    ESPMirageDealer  = true,
    MirageNotification = true,
    AutoRaceV4       = false,
    AutoTrialV4      = false,
    AutoRaid         = false,
    AutoBuyChip      = false,
    AutoSeaEvents    = false,
    AutoSeaBeast     = false,
    AutoTerrorShark  = false,
    AutoLeviathan    = false,
    ESPBoss          = true,
    ESPQuestMobs     = true,
    ESPPlayer        = false,
    ESPChest         = false,
    ESPFlower        = false,
    ESPDistance      = true,
    ESPHealth        = true,
    WalkSpeed        = 16,
    JumpPower        = 50,
    Fly              = false,
    FlySpeed         = 150,
    NoClip           = false,
    InfiniteEnergy   = false,
    SafeMode         = true,
    SafeHealthPercent= 30,
    AntiAFK          = true,
    AutoDisableOnAdmin = true,
    FPSBooster       = false,
    AutoRejoin       = false,
    Notifications    = true,
    EnableLogs       = false,
    SelectedIsland   = "Starter Island",
}
getgenv().RexHubConfig = Config

local function safe(fn, ...) local ok,v = pcall(fn,...) return ok and v or nil end
local function safeDo(fn) pcall(fn) end

local function getChar() return LP.Character end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function isAlive() local h=getHum(); return h and h.Health > 0 end
local function getData() return LP:FindFirstChild("Data") end

local function getLevel()
    local d=getData()
    return d and d:FindFirstChild("Level") and d.Level.Value or 1
end
local function getBeli()
    local d=getData()
    return d and d:FindFirstChild("Beli") and d.Beli.Value or 0
end
local function getFragments()
    local d=getData()
    return d and d:FindFirstChild("Fragments") and d.Fragments.Value or 0
end
local function getRace()
    local d=getData()
    return d and d:FindFirstChild("Race") and d.Race.Value or "Human"
end
local function getSea()
    local lv=getLevel()
    if lv < 700 then return 1 elseif lv < 1500 then return 2 else return 3 end
end
local function dist(a,b)
    if typeof(a)=="CFrame" then a=a.Position end
    if typeof(b)=="CFrame" then b=b.Position end
    if typeof(a)=="Instance" then a=a.Position end
    if typeof(b)=="Instance" then b=b.Position end
    return (a-b).Magnitude
end

local function notify(title, text, dur)
    pcall(function()
        if not Config.Notifications then return end
        StarterGui:SetCore("SendNotification",{Title=title,Text=text,Duration=dur or 3})
    end)
end

local function log(msg, t)
    if Config.EnableLogs then
        print(string.format("[Rex Hub][%s] %s", t or "INFO", msg))
    end
end

local RemoteCache = {}
local LastCall    = {}

local function getRemote(name)
    if RemoteCache[name] then return RemoteCache[name] end
    local r = ReplicatedStorage:FindFirstChild(name)
    if not r then
        local rem = ReplicatedStorage:FindFirstChild("Remotes")
        if rem then r = rem:FindFirstChild(name) end
    end
    if r then RemoteCache[name] = r end
    return r
end

local function fireRemote(name, ...)
    local r = getRemote(name)
    if not r then return nil end
    local now = tick()
    local last = LastCall[name] or 0
    local delay = 0.04 + math.random() * 0.04
    if now - last < delay then task.wait(delay-(now-last)+math.random()*0.02) end
    LastCall[name] = tick()
    local ok, res = pcall(function()
        if r:IsA("RemoteFunction") then return r:InvokeServer(...)
        else r:FireServer(...); return true end
    end)
    return ok and res or nil
end

local function invokeCommF(...) return fireRemote("CommF_", ...) end

local QuestDB = {
    {Min=1,   Max=9,    QuestId="BanditQuest1",     MobName="Bandit",              QuestPos=CFrame.new(1060,17,1550),    MobPos=CFrame.new(1044,16,1525),     Island="Starter"},
    {Min=10,  Max=14,   QuestId="JungleQuest",       MobName="Monkey",              QuestPos=CFrame.new(-1604,37,152),   MobPos=CFrame.new(-1538,37,203),     Island="Jungle"},
    {Min=15,  Max=29,   QuestId="JungleQuest",       MobName="Gorilla",             QuestPos=CFrame.new(-1604,37,152),   MobPos=CFrame.new(-1230,6,-485),     Island="Jungle"},
    {Min=30,  Max=39,   QuestId="BuggyQuest1",       MobName="Pirate",              QuestPos=CFrame.new(-1140,5,3828),   MobPos=CFrame.new(-1190,5,3762),     Island="Buggy"},
    {Min=40,  Max=59,   QuestId="BuggyQuest1",       MobName="Brute",               QuestPos=CFrame.new(-1140,5,3828),   MobPos=CFrame.new(-1414,12,4162),    Island="Buggy"},
    {Min=60,  Max=74,   QuestId="DesertQuest",       MobName="Desert Bandit",       QuestPos=CFrame.new(897,7,4388),     MobPos=CFrame.new(960,7,4348),       Island="Desert"},
    {Min=75,  Max=89,   QuestId="DesertQuest",       MobName="Desert Officer",      QuestPos=CFrame.new(897,7,4388),     MobPos=CFrame.new(1537,7,4596),      Island="Desert"},
    {Min=90,  Max=99,   QuestId="SnowQuest",         MobName="Snow Bandit",         QuestPos=CFrame.new(1386,87,-1297),  MobPos=CFrame.new(1366,87,-1347),    Island="Frozen"},
    {Min=100, Max=119,  QuestId="SnowQuest",         MobName="Snowman",             QuestPos=CFrame.new(1386,87,-1297),  MobPos=CFrame.new(1120,115,-1411),   Island="Frozen"},
    {Min=120, Max=149,  QuestId="MarineQuest2",      MobName="Chief Petty Officer", QuestPos=CFrame.new(-4880,21,4273),  MobPos=CFrame.new(-4953,21,4232),    Island="Marine Ford"},
    {Min=150, Max=174,  QuestId="SkyQuest",          MobName="Sky Bandit",          QuestPos=CFrame.new(-4892,312,4211), MobPos=CFrame.new(-4946,312,4175),   Island="Sky Island"},
    {Min=175, Max=189,  QuestId="PrisonerQuest",     MobName="Prisoner",            QuestPos=CFrame.new(5308,2,474),     MobPos=CFrame.new(5379,2,413),       Island="Prison"},
    {Min=190, Max=209,  QuestId="PrisonerQuest",     MobName="Dangerous Prisoner",  QuestPos=CFrame.new(5308,2,474),     MobPos=CFrame.new(5098,2,466),       Island="Prison"},
    {Min=210, Max=249,  QuestId="ColosseumQuest",    MobName="Toga Warrior",        QuestPos=CFrame.new(-1576,8,-2985),  MobPos=CFrame.new(-1475,8,-2918),    Island="Colosseum"},
    {Min=250, Max=274,  QuestId="ColosseumQuest",    MobName="Gladiator",           QuestPos=CFrame.new(-1576,8,-2985),  MobPos=CFrame.new(-1415,8,-3150),    Island="Colosseum"},
    {Min=275, Max=299,  QuestId="MagmaQuest",        MobName="Military Soldier",    QuestPos=CFrame.new(-5313,12,8515),  MobPos=CFrame.new(-5451,12,8466),    Island="Magma"},
    {Min=300, Max=324,  QuestId="MagmaQuest",        MobName="Military Spy",        QuestPos=CFrame.new(-5313,12,8515),  MobPos=CFrame.new(-5138,12,8519),    Island="Magma"},
    {Min=325, Max=374,  QuestId="FishmanQuest",      MobName="Fishman Warrior",     QuestPos=CFrame.new(61123,19,1569),  MobPos=CFrame.new(61072,19,1519),    Island="Fishman"},
    {Min=375, Max=399,  QuestId="FishmanQuest",      MobName="Fishman Commando",    QuestPos=CFrame.new(61123,19,1569),  MobPos=CFrame.new(61497,19,1526),    Island="Fishman"},
    {Min=400, Max=449,  QuestId="SkyExp1Quest",      MobName="God's Guard",         QuestPos=CFrame.new(-4721,845,-1912),MobPos=CFrame.new(-4766,845,-1978),  Island="Upper Sky"},
    {Min=450, Max=474,  QuestId="SkyExp1Quest",      MobName="Shanda",              QuestPos=CFrame.new(-4721,845,-1912),MobPos=CFrame.new(-7863,5545,-380),  Island="Upper Sky"},
    {Min=475, Max=524,  QuestId="SkyExp2Quest",      MobName="Royal Squad",         QuestPos=CFrame.new(-7906,5634,-1411),MobPos=CFrame.new(-7903,5634,-1467),Island="Upper Sky 2"},
    {Min=525, Max=549,  QuestId="SkyExp2Quest",      MobName="Royal Soldier",       QuestPos=CFrame.new(-7906,5634,-1411),MobPos=CFrame.new(-7679,5584,-1406),Island="Upper Sky 2"},
    {Min=550, Max=624,  QuestId="FountainQuest",     MobName="Galley Pirate",       QuestPos=CFrame.new(5255,39,4050),   MobPos=CFrame.new(5267,42,3996),     Island="Fountain"},
    {Min=625, Max=699,  QuestId="FountainQuest",     MobName="Galley Captain",      QuestPos=CFrame.new(5255,39,4050),   MobPos=CFrame.new(5573,39,4107),     Island="Fountain"},
    {Min=700, Max=724,  QuestId="Area1Quest",        MobName="Raider",              QuestPos=CFrame.new(-428,73,1836),   MobPos=CFrame.new(-472,73,1824),     Island="Rose"},
    {Min=725, Max=774,  QuestId="Area1Quest",        MobName="Mercenary",           QuestPos=CFrame.new(-428,73,1836),   MobPos=CFrame.new(-413,73,1563),     Island="Rose"},
    {Min=775, Max=799,  QuestId="Area2Quest",        MobName="Swan Pirate",         QuestPos=CFrame.new(638,73,1478),    MobPos=CFrame.new(638,73,1527),      Island="Rose"},
    {Min=800, Max=874,  QuestId="Area2Quest",        MobName="Factory Staff",       QuestPos=CFrame.new(638,73,1478),    MobPos=CFrame.new(281,73,410),       Island="Rose"},
    {Min=875, Max=899,  QuestId="MarineQuest3",      MobName="Marine Lieutenant",   QuestPos=CFrame.new(-2440,73,-3217), MobPos=CFrame.new(-2496,73,-3280),   Island="Green Zone"},
    {Min=900, Max=949,  QuestId="MarineQuest3",      MobName="Marine Captain",      QuestPos=CFrame.new(-2440,73,-3217), MobPos=CFrame.new(-2273,73,-3125),   Island="Green Zone"},
    {Min=950, Max=974,  QuestId="ZombieQuest",       MobName="Zombie",              QuestPos=CFrame.new(-5497,49,-795),  MobPos=CFrame.new(-5454,49,-729),    Island="Graveyard"},
    {Min=975, Max=999,  QuestId="ZombieQuest",       MobName="Vampire",             QuestPos=CFrame.new(-5497,49,-795),  MobPos=CFrame.new(-5635,112,-780),   Island="Graveyard"},
    {Min=1000,Max=1049, QuestId="SnowMountainQuest", MobName="Snow Trooper",        QuestPos=CFrame.new(607,401,-5371),  MobPos=CFrame.new(600,401,-5304),    Island="Snow Mountain"},
    {Min=1050,Max=1099, QuestId="SnowMountainQuest", MobName="Winter Warrior",      QuestPos=CFrame.new(607,401,-5371),  MobPos=CFrame.new(596,440,-5806),    Island="Snow Mountain"},
    {Min=1100,Max=1124, QuestId="IceSideQuest",      MobName="Lab Subordinate",     QuestPos=CFrame.new(-6061,16,-4905), MobPos=CFrame.new(-6095,16,-4832),   Island="Hot Cold"},
    {Min=1125,Max=1174, QuestId="IceSideQuest",      MobName="Horned Warrior",      QuestPos=CFrame.new(-6061,16,-4905), MobPos=CFrame.new(-5988,16,-5280),   Island="Hot Cold"},
    {Min=1175,Max=1199, QuestId="FireSideQuest",     MobName="Magma Ninja",         QuestPos=CFrame.new(-5431,16,-5296), MobPos=CFrame.new(-5376,16,-5247),   Island="Hot Cold"},
    {Min=1200,Max=1249, QuestId="FireSideQuest",     MobName="Lava Pirate",         QuestPos=CFrame.new(-5431,16,-5296), MobPos=CFrame.new(-5102,16,-5427),   Island="Hot Cold"},
    {Min=1250,Max=1274, QuestId="ShipQuest1",        MobName="Ship Deckhand",       QuestPos=CFrame.new(1037,125,32911), MobPos=CFrame.new(958,125,32849),    Island="Cursed Ship"},
    {Min=1275,Max=1299, QuestId="ShipQuest1",        MobName="Ship Engineer",       QuestPos=CFrame.new(1037,125,32911), MobPos=CFrame.new(1235,125,32895),   Island="Cursed Ship"},
    {Min=1300,Max=1324, QuestId="ShipQuest2",        MobName="Ship Steward",        QuestPos=CFrame.new(971,125,33245),  MobPos=CFrame.new(924,141,33184),    Island="Cursed Ship"},
    {Min=1325,Max=1349, QuestId="ShipQuest2",        MobName="Ship Officer",        QuestPos=CFrame.new(971,125,33245),  MobPos=CFrame.new(920,177,33385),    Island="Cursed Ship"},
    {Min=1350,Max=1374, QuestId="FrostQuest",        MobName="Arctic Warrior",      QuestPos=CFrame.new(5669,29,-6482),  MobPos=CFrame.new(5596,29,-6420),    Island="Ice Castle"},
    {Min=1375,Max=1424, QuestId="FrostQuest",        MobName="Snow Lurker",         QuestPos=CFrame.new(5669,29,-6482),  MobPos=CFrame.new(5874,29,-6585),    Island="Ice Castle"},
    {Min=1425,Max=1449, QuestId="ForgottenQuest",    MobName="Sea Soldier",         QuestPos=CFrame.new(-3054,236,-10145),MobPos=CFrame.new(-3004,236,-10089),Island="Forgotten"},
    {Min=1450,Max=1499, QuestId="ForgottenQuest",    MobName="Water Fighter",       QuestPos=CFrame.new(-3054,236,-10145),MobPos=CFrame.new(-2864,236,-10186),Island="Forgotten"},
    {Min=1500,Max=1524, QuestId="PiratePortQuest",   MobName="Pirate Millionaire",  QuestPos=CFrame.new(-290,44,5580),   MobPos=CFrame.new(-241,44,5632),     Island="Port Town"},
    {Min=1525,Max=1574, QuestId="PiratePortQuest",   MobName="Pistol Billionaire",  QuestPos=CFrame.new(-290,44,5580),   MobPos=CFrame.new(-444,44,5595),     Island="Port Town"},
    {Min=1575,Max=1599, QuestId="AmazonQuest",       MobName="Dragon Crew Warrior", QuestPos=CFrame.new(5832,52,-1100),  MobPos=CFrame.new(5766,52,-1159),    Island="Hydra"},
    {Min=1600,Max=1624, QuestId="AmazonQuest",       MobName="Dragon Crew Archer",  QuestPos=CFrame.new(5832,52,-1100),  MobPos=CFrame.new(6076,52,-1035),    Island="Hydra"},
    {Min=1625,Max=1649, QuestId="AmazonQuest2",      MobName="Female Islander",     QuestPos=CFrame.new(5448,602,751),   MobPos=CFrame.new(5401,602,706),     Island="Amazon"},
    {Min=1650,Max=1699, QuestId="AmazonQuest2",      MobName="Giant Islander",      QuestPos=CFrame.new(5448,602,751),   MobPos=CFrame.new(5691,602,785),     Island="Amazon"},
    {Min=1700,Max=1724, QuestId="MarineTreeIsland",  MobName="Marine Commodore",    QuestPos=CFrame.new(2180,29,-6737),  MobPos=CFrame.new(2119,29,-6784),    Island="Marine Tree"},
    {Min=1725,Max=1774, QuestId="MarineTreeIsland",  MobName="Marine Rear Admiral", QuestPos=CFrame.new(2180,29,-6737),  MobPos=CFrame.new(2365,29,-6663),    Island="Marine Tree"},
    {Min=1775,Max=1799, QuestId="DeepForestIsland",  MobName="Mythological Pirate", QuestPos=CFrame.new(-13234,332,-7625),MobPos=CFrame.new(-13303,332,-7570),Island="Turtle"},
    {Min=1800,Max=1824, QuestId="DeepForestIsland2", MobName="Jungle Pirate",       QuestPos=CFrame.new(-12680,390,-9902),MobPos=CFrame.new(-12620,390,-9840),Island="Turtle"},
    {Min=1825,Max=1849, QuestId="DeepForestIsland3", MobName="Musketeer Pirate",    QuestPos=CFrame.new(-13234,332,-7625),MobPos=CFrame.new(-13450,332,-7580),Island="Turtle"},
    {Min=1850,Max=1899, QuestId="HauntedQuest1",     MobName="Reborn Skeleton",     QuestPos=CFrame.new(-9479,142,5566), MobPos=CFrame.new(-9426,142,5510),   Island="Haunted"},
    {Min=1900,Max=1924, QuestId="HauntedQuest1",     MobName="Living Zombie",       QuestPos=CFrame.new(-9479,142,5566), MobPos=CFrame.new(-9606,142,5584),   Island="Haunted"},
    {Min=1925,Max=1974, QuestId="HauntedQuest2",     MobName="Demonic Soul",        QuestPos=CFrame.new(-9513,172,6078), MobPos=CFrame.new(-9457,172,6020),   Island="Haunted"},
    {Min=1975,Max=1999, QuestId="HauntedQuest2",     MobName="Posessed Mummy",      QuestPos=CFrame.new(-9513,172,6078), MobPos=CFrame.new(-9613,172,6136),   Island="Haunted"},
    {Min=2000,Max=2024, QuestId="IceCreamLandQuest", MobName="Peanut Scout",        QuestPos=CFrame.new(-716,38,-12469), MobPos=CFrame.new(-659,38,-12412),   Island="Ice Cream"},
    {Min=2025,Max=2049, QuestId="IceCreamLandQuest", MobName="Peanut President",    QuestPos=CFrame.new(-716,38,-12469), MobPos=CFrame.new(-865,38,-12532),   Island="Ice Cream"},
    {Min=2050,Max=2074, QuestId="IceCreamLandQuest2",MobName="Ice Cream Chef",      QuestPos=CFrame.new(-821,66,-10965), MobPos=CFrame.new(-762,66,-10906),   Island="Ice Cream 2"},
    {Min=2075,Max=2099, QuestId="IceCreamLandQuest2",MobName="Ice Cream Commander", QuestPos=CFrame.new(-821,66,-10965), MobPos=CFrame.new(-978,66,-11028),   Island="Ice Cream 2"},
    {Min=2100,Max=2124, QuestId="CakeQuest1",        MobName="Cookie Crafter",      QuestPos=CFrame.new(-2021,38,-12028),MobPos=CFrame.new(-1968,38,-11975),  Island="Cake"},
    {Min=2125,Max=2149, QuestId="CakeQuest1",        MobName="Cake Guard",          QuestPos=CFrame.new(-2021,38,-12028),MobPos=CFrame.new(-2132,38,-12089),  Island="Cake"},
    {Min=2150,Max=2199, QuestId="CakeQuest2",        MobName="Baking Staff",        QuestPos=CFrame.new(-1927,38,-12842),MobPos=CFrame.new(-1871,38,-12785),  Island="Cake 2"},
    {Min=2200,Max=2224, QuestId="CakeQuest2",        MobName="Head Baker",          QuestPos=CFrame.new(-1927,38,-12842),MobPos=CFrame.new(-2038,38,-12905),  Island="Cake 2"},
    {Min=2225,Max=2249, QuestId="ChocQuest1",        MobName="Cocoa Warrior",       QuestPos=CFrame.new(231,23,-12197),  MobPos=CFrame.new(286,23,-12141),    Island="Chocolate"},
    {Min=2250,Max=2274, QuestId="ChocQuest1",        MobName="Chocolate Bar Battler",QuestPos=CFrame.new(231,23,-12197), MobPos=CFrame.new(120,23,-12258),    Island="Chocolate"},
    {Min=2275,Max=2299, QuestId="ChocQuest2",        MobName="Sweet Thief",         QuestPos=CFrame.new(151,23,-12774),  MobPos=CFrame.new(205,23,-12718),    Island="Chocolate 2"},
    {Min=2300,Max=2324, QuestId="ChocQuest2",        MobName="Candy Rebel",         QuestPos=CFrame.new(151,23,-12774),  MobPos=CFrame.new(40,23,-12837),     Island="Chocolate 2"},
    {Min=2325,Max=2349, QuestId="CandyQuest1",       MobName="Candy Pirate",        QuestPos=CFrame.new(-1149,14,-14445),MobPos=CFrame.new(-1093,14,-14389),  Island="Candy"},
    {Min=2350,Max=2374, QuestId="CandyQuest1",       MobName="Snow Demon",          QuestPos=CFrame.new(-1149,14,-14445),MobPos=CFrame.new(-1260,14,-14508),  Island="Candy"},
    {Min=2375,Max=2399, QuestId="TikiQuest1",        MobName="Isle Outlaw",         QuestPos=CFrame.new(-16545,56,1051), MobPos=CFrame.new(-16490,56,995),    Island="Tiki"},
    {Min=2400,Max=2424, QuestId="TikiQuest1",        MobName="Island Boy",          QuestPos=CFrame.new(-16545,56,1051), MobPos=CFrame.new(-16655,56,1114),   Island="Tiki"},
    {Min=2425,Max=2449, QuestId="TikiQuest2",        MobName="Sun-kissed Warrior",  QuestPos=CFrame.new(-16539,56,-173), MobPos=CFrame.new(-16483,56,-117),   Island="Tiki 2"},
    {Min=2450,Max=9999, QuestId="TikiQuest2",        MobName="Isle Champion",       QuestPos=CFrame.new(-16539,56,-173), MobPos=CFrame.new(-16650,56,-236),   Island="Tiki 2"},
}

local function getQuest(level)
    level = level or getLevel()
    for _, q in ipairs(QuestDB) do
        if level >= q.Min and level <= q.Max then return q end
    end
    return QuestDB[#QuestDB]
end

local BossDB = {
    {Name="Gorilla King",          Level=25,   Pos=CFrame.new(-1221,6,-427),     Sea=1},
    {Name="Bobby",                 Level=55,   Pos=CFrame.new(-1259,5,4282),     Sea=1},
    {Name="Yeti",                  Level=110,  Pos=CFrame.new(1187,138,-1483),   Sea=1},
    {Name="Vice Admiral",          Level=130,  Pos=CFrame.new(-5072,22,4280),    Sea=1},
    {Name="Warden",                Level=200,  Pos=CFrame.new(5231,2,443),       Sea=1},
    {Name="Chief Warden",          Level=220,  Pos=CFrame.new(4926,-72,608),     Sea=1},
    {Name="Saber Expert",          Level=200,  Pos=CFrame.new(-1458,29,-48),     Sea=1},
    {Name="Magma Admiral",         Level=350,  Pos=CFrame.new(-5364,40,8442),    Sea=1},
    {Name="Fishman Lord",          Level=425,  Pos=CFrame.new(61366,18,1476),    Sea=1},
    {Name="Wysper",                Level=500,  Pos=CFrame.new(-7862,5544,-371),  Sea=1},
    {Name="Thunder God",           Level=575,  Pos=CFrame.new(-7648,5586,-1414), Sea=1},
    {Name="Cyborg",                Level=675,  Pos=CFrame.new(5331,54,4038),     Sea=1},
    {Name="Greybeard",             Level=750,  Pos=CFrame.new(-5076,25,4270),    Sea=1},
    {Name="Diamond",               Level=750,  Pos=CFrame.new(-429,73,1218),     Sea=2},
    {Name="Jeremy",                Level=850,  Pos=CFrame.new(-797,73,1064),     Sea=2},
    {Name="Fajita",                Level=925,  Pos=CFrame.new(-2148,73,-3106),   Sea=2},
    {Name="Don Swan",              Level=1000, Pos=CFrame.new(-375,124,428),     Sea=2},
    {Name="Smoke Admiral",         Level=1150, Pos=CFrame.new(-5099,16,-5335),   Sea=2},
    {Name="Awakened Ice Admiral",  Level=1400, Pos=CFrame.new(5669,29,-6482),    Sea=2},
    {Name="Tide Keeper",           Level=1475, Pos=CFrame.new(-2871,236,-10179), Sea=2},
    {Name="Stone",                 Level=1550, Pos=CFrame.new(-293,44,5472),     Sea=3},
    {Name="Island Empress",        Level=1675, Pos=CFrame.new(5698,602,779),     Sea=3},
    {Name="Kilo Admiral",          Level=1750, Pos=CFrame.new(2366,28,-6708),    Sea=3},
    {Name="Captain Elephant",      Level=1875, Pos=CFrame.new(-12757,332,-7734), Sea=3},
    {Name="Beautiful Pirate",      Level=1950, Pos=CFrame.new(-9565,142,5570),   Sea=3},
    {Name="Cake Queen",            Level=2175, Pos=CFrame.new(-2021,38,-12028),  Sea=3},
    {Name="Dough King",            Level=2200, Pos=CFrame.new(231,23,-12197),    Sea=3},
    {Name="rip_indra",             Level=5000, Pos=CFrame.new(-5352,424,-2893),  Sea=3},
}

local function getBossForLevel(lv)
    lv = lv or getLevel()
    local res = nil
    for _, b in ipairs(BossDB) do
        if lv >= b.Level then res = b end
    end
    return res or BossDB[1]
end

local function findBoss(name)
    for _, b in ipairs(BossDB) do
        if b.Name:lower():find(name:lower()) then return b end
    end
    return nil
end

local IslandDB = {
    ["Starter Island"]   = {Pos=CFrame.new(1044,16,1525),      Sea=1},
    ["Jungle"]           = {Pos=CFrame.new(-1604,37,152),      Sea=1},
    ["Buggy Island"]     = {Pos=CFrame.new(-1140,5,3828),      Sea=1},
    ["Desert"]           = {Pos=CFrame.new(897,7,4388),        Sea=1},
    ["Frozen Village"]   = {Pos=CFrame.new(1386,87,-1297),     Sea=1},
    ["Marine Ford"]      = {Pos=CFrame.new(-4880,21,4273),     Sea=1},
    ["Sky Island"]       = {Pos=CFrame.new(-4892,312,4211),    Sea=1},
    ["Prison"]           = {Pos=CFrame.new(5308,2,474),        Sea=1},
    ["Colosseum"]        = {Pos=CFrame.new(-1576,8,-2985),     Sea=1},
    ["Magma Village"]    = {Pos=CFrame.new(-5313,12,8515),     Sea=1},
    ["Fishman Island"]   = {Pos=CFrame.new(61123,19,1569),     Sea=1},
    ["Upper Skylands"]   = {Pos=CFrame.new(-4721,845,-1912),   Sea=1},
    ["Upper Skylands 2"] = {Pos=CFrame.new(-7906,5634,-1411),  Sea=1},
    ["Fountain City"]    = {Pos=CFrame.new(5255,39,4050),      Sea=1},
    ["Kingdom of Rose"]  = {Pos=CFrame.new(-428,73,1836),      Sea=2},
    ["Green Zone"]       = {Pos=CFrame.new(-2440,73,-3217),    Sea=2},
    ["Graveyard Island"] = {Pos=CFrame.new(-5497,49,-795),     Sea=2},
    ["Snow Mountain"]    = {Pos=CFrame.new(607,401,-5371),     Sea=2},
    ["Hot and Cold"]     = {Pos=CFrame.new(-6061,16,-4905),    Sea=2},
    ["Cursed Ship"]      = {Pos=CFrame.new(1037,125,32911),    Sea=2},
    ["Ice Castle"]       = {Pos=CFrame.new(5669,29,-6482),     Sea=2},
    ["Forgotten Island"] = {Pos=CFrame.new(-3054,236,-10145),  Sea=2},
    ["Dark Arena"]       = {Pos=CFrame.new(-375,124,428),      Sea=2},
    ["Port Town"]        = {Pos=CFrame.new(-290,44,5580),      Sea=3},
    ["Hydra Island"]     = {Pos=CFrame.new(5832,52,-1100),     Sea=3},
    ["Amazon Lily"]      = {Pos=CFrame.new(5448,602,751),      Sea=3},
    ["Marine Tree"]      = {Pos=CFrame.new(2180,29,-6737),     Sea=3},
    ["Floating Turtle"]  = {Pos=CFrame.new(-13234,332,-7625),  Sea=3},
    ["Haunted Castle"]   = {Pos=CFrame.new(-9479,142,5566),    Sea=3},
    ["Ice Cream Land"]   = {Pos=CFrame.new(-716,38,-12469),    Sea=3},
    ["Cake Land"]        = {Pos=CFrame.new(-2021,38,-12028),   Sea=3},
    ["Chocolate Land"]   = {Pos=CFrame.new(231,23,-12197),     Sea=3},
    ["Candy Land"]       = {Pos=CFrame.new(-1149,14,-14445),   Sea=3},
    ["Tiki Outpost"]     = {Pos=CFrame.new(-16545,56,1051),    Sea=3},
    ["Mirage Island"]    = {Pos=CFrame.new(925,81,34226),      Sea=3},
    ["Castle on the Sea"]= {Pos=CFrame.new(-5039,313,-2991),   Sea=3},
}

local FruitRarity = {
    Legendary = {"Dragon","Leopard","Spirit","Control","Venom","Shadow","Dough","Soul","Mammoth","T-Rex"},
    Mythical  = {"Buddha","Phoenix","Rumble","Magma","Quake","Ice","Light","Love","Gravity","Dark"},
    Rare      = {"Flame","Paw","String","Bird","Barrier","Sand","Rubber","Diamond"},
    Uncommon  = {"Smoke","Falcon","Revive","Spin","Spring","Bomb","Chop","Spike"},
}
local function fruitRarity(name)
    for r, list in pairs(FruitRarity) do
        if table.find(list, name) then return r end
    end
    return "Common"
end
local function isLegendary(n) return table.find(FruitRarity.Legendary,n) ~= nil end
local function isMythical(n)  return table.find(FruitRarity.Mythical,n)  ~= nil end

local currentTween = nil
local function stopTween()
    if currentTween then pcall(function() currentTween:Cancel() end) currentTween = nil end
end
local function tweenTo(cf)
    local hrp = getHRP()
    if not hrp then return end
    stopTween()
    local t = TweenService:Create(hrp, TweenInfo.new(0.12, Enum.EasingStyle.Linear), {CFrame = cf})
    currentTween = t
    t:Play()
end
local function teleportSafe(cf)
    local hrp = getHRP()
    if not hrp then return end
    stopTween()
    safeDo(function() hrp.CFrame = cf end)
end

local bvInst, bgInst
local function startFly()
    local hrp = getHRP()
    if not hrp then return end
    safeDo(function()
        bvInst = Instance.new("BodyVelocity")
        bvInst.MaxForce = Vector3.new(1e5,1e5,1e5)
        bvInst.Parent = hrp
        bgInst = Instance.new("BodyGyro")
        bgInst.MaxTorque = Vector3.new(1e5,1e5,1e5)
        bgInst.Parent = hrp
    end)
    Manager:Connect("FlyUpdate", RunService.Heartbeat:Connect(function()
        if not Config.Fly then return end
        local h2 = getHRP()
        if not h2 or not bvInst or not bgInst then return end
        safeDo(function()
            bvInst.Velocity = Cam.CFrame.LookVector * (Config.FlySpeed or 150)
            bgInst.CFrame   = Cam.CFrame
        end)
    end))
end
local function stopFly()
    Manager:Disconnect("FlyUpdate")
    if bvInst and bvInst.Parent then bvInst:Destroy() end
    if bgInst and bgInst.Parent then bgInst:Destroy() end
    bvInst, bgInst = nil, nil
end

Manager:Connect("NoClipLoop", RunService.Stepped:Connect(function()
    if not Config.NoClip then return end
    local c = getChar()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then safeDo(function() p.CanCollide = false end) end
    end
end))

Manager:Connect("SpeedJumpLoop", RunService.Heartbeat:Connect(function()
    local h = getHum()
    if not h then return end
    if Config.WalkSpeed  and Config.WalkSpeed  > 16  then safeDo(function() h.WalkSpeed  = Config.WalkSpeed  end) end
    if Config.JumpPower  and Config.JumpPower  > 50  then safeDo(function() h.JumpPower  = Config.JumpPower  end) end
end))

Manager:Connect("InfEnergyLoop", RunService.Heartbeat:Connect(function()
    if not Config.InfiniteEnergy then return end
    local c = getChar()
    if not c then return end
    local e = c:FindFirstChild("Energy")
    if e then safeDo(function() e.Value = e.MaxValue or 1000 end) end
end))

local function equipWeapon(wtype)
    safeDo(function()
        local c = getChar()
        if not c then return end
        for _, tool in ipairs(LP.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local tname = tool.Name:lower()
                local match = (wtype == "Combat" and (tname:find("combat") or tname:find("melee"))) or
                              (wtype == "Sword"   and (tname:find("sword") or tname:find("sabre"))) or
                              (wtype == "Gun"     and (tname:find("gun") or tname:find("rifle") or tname:find("pistol"))) or
                              (wtype == "Blox Fruit" and tname:find("fruit"))
                if match then
                    LP.Character.Humanoid:EquipTool(tool)
                    return
                end
            end
        end
    end)
end

local function attack(target)
    safeDo(function()
        local c = getChar()
        if not c then return end
        local tool = c:FindFirstChildOfClass("Tool")
        if tool then
            for _, ch in ipairs(tool:GetChildren()) do
                if ch:IsA("RemoteEvent") or ch:IsA("RemoteFunction") then
                    pcall(function()
                        if ch:IsA("RemoteEvent") then ch:FireServer(target)
                        else ch:InvokeServer(target) end
                    end)
                end
            end
        end
    end)
end

local function spamSkills()
    safeDo(function()
        local keys = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V, Enum.KeyCode.F}
        for _, k in ipairs(keys) do
            if Config.AutoSkill then
                game:GetService("VirtualInputManager"):SendKeyEvent(true, k, false, game)
                task.wait(0.05)
                game:GetService("VirtualInputManager"):SendKeyEvent(false, k, false, game)
            end
        end
    end)
end

local function bringMob(target)
    if not Config.BringMobs then return end
    safeDo(function()
        local hrp = getHRP()
        local mobHRP = target:FindFirstChild("HumanoidRootPart")
        if hrp and mobHRP then
            mobHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, -Config.BringDistance)
        end
    end)
end

local function expandHitbox(target)
    if not Config.ExpandHitbox then return end
    safeDo(function()
        for _, p in ipairs(target:GetDescendants()) do
            if p:IsA("BasePart") then p.Size = Vector3.new(Config.HitboxSize,Config.HitboxSize,Config.HitboxSize) end
        end
    end)
end

local function getClosestEnemy(maxDist)
    local hrp = getHRP()
    if not hrp then return nil end
    local closest, closestD = nil, maxDist or 500
    local enemies = Workspace:FindFirstChild("Enemies")
    local search  = enemies and enemies:GetChildren() or Workspace:GetChildren()
    for _, m in ipairs(search) do
        local mhum = m:FindFirstChild("Humanoid")
        local mhrp = m:FindFirstChild("HumanoidRootPart")
        if mhum and mhrp and mhum.Health > 0 then
            local isPlayer = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character == m then isPlayer = true; break end
            end
            if not isPlayer then
                local d = dist(hrp.Position, mhrp.Position)
                if d < closestD then closest = m; closestD = d end
            end
        end
    end
    return closest
end

local function acceptQuest(questData)
    if not questData then return end
    safeDo(function() invokeCommF("QuestAction", "Accept", questData.QuestId, 1) end)
    safeDo(function() invokeCommF("QuestAction", "Accept", questData.QuestId, 2) end)
    safeDo(function() invokeCommF("QuestAction", "StartQuest", questData.QuestId) end)
end

local function hasActiveQuest()
    local d = getData()
    if d then
        local q = d:FindFirstChild("Quest") or d:FindFirstChild("ActiveQuest")
        if q and q.Value ~= "" then return true end
    end
    return false
end

local AutoFarm = {}
AutoFarm.Running = false

function AutoFarm.Start()
    AutoFarm.Running = true
    Manager:SetLoop("AutoFarm", true)
    notify("Rex Hub","Auto Farm Started ⚔️", 3)
    Manager:Connect("AutoFarmLoop", RunService.Heartbeat:Connect(function()
        if not Manager:IsLoop("AutoFarm") then return end
        safeDo(function()
            if not isAlive() then
                task.wait(2)
                return
            end
            local hum = getHum()
            if Config.SafeMode and hum and (hum.Health/hum.MaxHealth)*100 < Config.SafeHealthPercent then
                teleportSafe(getQuest().MobPos * CFrame.new(0,30,0))
                task.wait(1)
                return
            end
            if Config.AutoQuest and not hasActiveQuest() then
                local qd = getQuest()
                teleportSafe(qd.QuestPos)
                task.wait(0.3)
                acceptQuest(qd)
                task.wait(0.3)
                teleportSafe(qd.MobPos)
                return
            end
            local qd = getQuest()
            local mob = getClosestEnemy(Config.FarmDistance + 200)
            if not mob then
                teleportSafe(qd.MobPos)
                task.wait(0.5)
                return
            end
            local hrp = getHRP()
            local mobHRP = mob:FindFirstChild("HumanoidRootPart")
            if hrp and mobHRP then
                local d = dist(hrp.Position, mobHRP.Position)
                if d > Config.FarmDistance then
                    if Config.TeleportToTarget or d > 200 then
                        hrp.CFrame = mobHRP.CFrame * CFrame.new(0, 3, 0)
                    else
                        tweenTo(mobHRP.CFrame * CFrame.new(0, 3, 0))
                    end
                else
                    stopTween()
                    bringMob(mob)
                    expandHitbox(mob)
                    equipWeapon(Config.FarmWeaponType)
                    attack(mob)
                    spamSkills()
                end
            end
        end)
    end))
end

function AutoFarm.Stop()
    AutoFarm.Running = false
    Manager:SetLoop("AutoFarm", false)
    Manager:Disconnect("AutoFarmLoop")
    stopTween()
    notify("Rex Hub","Auto Farm Stopped", 2)
end

local BossFarm = {}
BossFarm.Running = false

function BossFarm.Start()
    BossFarm.Running = true
    Manager:SetLoop("BossFarm", true)
    notify("Rex Hub","Boss Farm Started 👹", 3)
    Manager:Connect("BossFarmLoop", RunService.Heartbeat:Connect(function()
        if not Manager:IsLoop("BossFarm") then return end
        safeDo(function()
            if not isAlive() then task.wait(2); return end
            local bossName = Config.SelectedBoss
            local bossInfo = (bossName == "Auto") and getBossForLevel() or findBoss(bossName)
            if not bossInfo then return end
            local bossModel = nil
            for _, m in ipairs(Workspace:GetDescendants()) do
                if m.Name == bossInfo.Name then
                    local h = m:FindFirstChild("Humanoid")
                    if h and h.Health > 0 then bossModel = m; break end
                end
            end
            local hrp = getHRP()
            if not hrp then return end
            if bossModel then
                local bhrp = bossModel:FindFirstChild("HumanoidRootPart")
                if bhrp then
                    local d = dist(hrp.Position, bhrp.Position)
                    if d > 80 then
                        hrp.CFrame = bhrp.CFrame * CFrame.new(0, 15, 0)
                    else
                        expandHitbox(bossModel)
                        equipWeapon(Config.FarmWeaponType)
                        attack(bossModel)
                        spamSkills()
                    end
                end
            else
                if bossInfo.Pos then
                    hrp.CFrame = bossInfo.Pos * CFrame.new(0, 5, 0)
                end
            end
        end)
    end))
end

function BossFarm.Stop()
    BossFarm.Running = false
    Manager:SetLoop("BossFarm", false)
    Manager:Disconnect("BossFarmLoop")
    notify("Rex Hub","Boss Farm Stopped", 2)
end

local FruitSys = {}

local function getAllFruits()
    local fruits = {}
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("Tool") and o.ToolTip == "Blox Fruit" then table.insert(fruits, o) end
    end
    local gi = Workspace:FindFirstChild("GroundItems")
    if gi then
        for _, item in ipairs(gi:GetChildren()) do
            local t = item:FindFirstChildOfClass("Tool")
            if t and t.ToolTip == "Blox Fruit" then table.insert(fruits, item) end
        end
    end
    return fruits
end

function FruitSys.StartSniper()
    Manager:Connect("FruitSniper", RunService.Heartbeat:Connect(function()
        if not Config.FruitSniper then return end
        safeDo(function()
            local hrp = getHRP()
            if not hrp then return end
            for _, fruit in ipairs(getAllFruits()) do
                local handle = fruit:FindFirstChild("Handle")
                local pos    = handle and handle.Position or (fruit:IsA("BasePart") and fruit.Position) or (fruit.PrimaryPart and fruit.PrimaryPart.Position)
                if pos then
                    local fruitName = fruit:IsA("Tool") and fruit.Name or "Fruit"
                    local target  = Config.TargetFruit or "Any"
                    local valid   = target=="Any" or
                                    (target=="Legendary" and isLegendary(fruitName)) or
                                    (target=="Mythical"  and isMythical(fruitName))  or
                                    fruitName:find(target)
                    if valid then
                        if Config.FruitNotification then
                            notify("🍎 Rex Hub","Fruit: "..fruitName.." ("..fruitRarity(fruitName)..")", 4)
                        end
                        hrp.CFrame = CFrame.new(pos) * CFrame.new(0,3,0)
                        task.wait(0.2)
                        if handle and firetouchinterest then
                            firetouchinterest(hrp, handle, 0)
                            task.wait(0.1)
                            firetouchinterest(hrp, handle, 1)
                        end
                        if Config.AutoStoreFruit then
                            task.wait(0.5)
                            safeDo(function() fireRemote("StoreFruit") end)
                        end
                    end
                end
            end
        end)
    end))
end
function FruitSys.StopSniper() Manager:Disconnect("FruitSniper") end

local MirageSys = {}
MirageSys.Found = false

local function findMirageIsland()
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o.Name:find("Mirage") and (o:IsA("Model") or o:IsA("BasePart")) then return o end
    end
    return nil
end
local function findFruitDealer()
    for _, o in ipairs(Workspace:GetDescendants()) do
        if (o.Name == "Fruit Dealer" or o.Name:find("Advanced Fruit")) and o:FindFirstChild("HumanoidRootPart") then
            return o
        end
    end
    return nil
end

function MirageSys.StartAuto()
    local lastChk = 0
    Manager:Connect("MirageLoop", RunService.Heartbeat:Connect(function()
        if not Config.AutoMirage then return end
        local now = tick()
        if now - lastChk < 1 then return end
        lastChk = now
        safeDo(function()
            local m = findMirageIsland()
            if m and not MirageSys.Found then
                MirageSys.Found = true
                if Config.MirageNotification then notify("🏝️ REX HUB","MIRAGE ISLAND FOUND!", 6) end
                local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                if pp then teleportSafe(pp.CFrame * CFrame.new(0,50,0)) end
                task.wait(2)
                local dealer = findFruitDealer()
                if dealer then
                    local dhrp = dealer:FindFirstChild("HumanoidRootPart")
                    if dhrp then teleportSafe(dhrp.CFrame * CFrame.new(0,0,3)) end
                end
            elseif not m then
                MirageSys.Found = false
            end
        end)
    end))
end
function MirageSys.StopAuto()
    Manager:Disconnect("MirageLoop")
    MirageSys.Found = false
end

local RaceV4Sys = {}
local function findMinotaur()
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, e in ipairs(enemies:GetChildren()) do
            if e.Name:find("Minotaur") then
                local h = e:FindFirstChild("Humanoid")
                if h and h.Health > 0 then return e end
            end
        end
    end
    return nil
end
function RaceV4Sys.StartAuto()
    Manager:Connect("RaceV4Loop", RunService.Heartbeat:Connect(function()
        if not Config.AutoRaceV4 then return end
        safeDo(function()
            if not isAlive() then return end
            local hrp = getHRP()
            if not hrp then return end
            local mino = findMinotaur()
            if mino then
                local mhrp = mino:FindFirstChild("HumanoidRootPart")
                if mhrp then
                    local d = dist(hrp.Position, mhrp.Position)
                    if d > 100 then
                        hrp.CFrame = mhrp.CFrame * CFrame.new(0,20,0)
                    else
                        equipWeapon(Config.FarmWeaponType)
                        attack(mino)
                        spamSkills()
                    end
                end
            else
                teleportSafe(CFrame.new(-12489,332,-7558))
            end
        end)
    end))
end
function RaceV4Sys.StopAuto() Manager:Disconnect("RaceV4Loop") end

local RaidSys = {}
local function isInRaid() return Workspace:FindFirstChild("_raid") ~= nil end
local function getClosestRaidMob()
    local raid = Workspace:FindFirstChild("_raid")
    if not raid then return nil end
    local hrp = getHRP()
    if not hrp then return nil end
    local closest, closestD = nil, math.huge
    for _, m in ipairs(raid:GetDescendants()) do
        local h = m:FindFirstChild("Humanoid")
        local r = m:FindFirstChild("HumanoidRootPart")
        if h and r and h.Health > 0 then
            local d = dist(hrp.Position, r.Position)
            if d < closestD then closest = m; closestD = d end
        end
    end
    return closest
end
function RaidSys.StartAuto()
    Manager:Connect("RaidLoop", RunService.Heartbeat:Connect(function()
        if not Config.AutoRaid then return end
        safeDo(function()
            if not isAlive() then return end
            if isInRaid() then
                local mob = getClosestRaidMob()
                local hrp = getHRP()
                if mob and hrp then
                    local mhrp = mob:FindFirstChild("HumanoidRootPart")
                    if mhrp then
                        local d = dist(hrp.Position, mhrp.Position)
                        if d > 100 then
                            hrp.CFrame = mhrp.CFrame * CFrame.new(0,12,0)
                        else
                            equipWeapon(Config.FarmWeaponType)
                            attack(mob)
                            spamSkills()
                        end
                    end
                end
            end
        end)
    end))
end
function RaidSys.StopAuto() Manager:Disconnect("RaidLoop") end

local SeaSys = {}
local function findSeaTarget()
    local names = {
        "SeaBeast","Sea Beast","SeaBeast1",
        "Terror Shark","TerrorShark",
        "Leviathan"
    }
    for _, o in ipairs(Workspace:GetDescendants()) do
        for _, n in ipairs(names) do
            if o.Name == n or o.Name:find(n:gsub(" ","")) then
                local h = o:FindFirstChild("Humanoid")
                if h and h.Health > 0 then return o end
            end
        end
    end
    return nil
end
function SeaSys.StartAuto()
    Manager:Connect("SeaLoop", RunService.Heartbeat:Connect(function()
        if not Config.AutoSeaEvents then return end
        safeDo(function()
            if not isAlive() then return end
            local target = findSeaTarget()
            if not target then return end
            local hrp = getHRP()
            local tpart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
            if hrp and tpart then
                local d = dist(hrp.Position, tpart.Position)
                if d > 100 then
                    hrp.CFrame = tpart.CFrame * CFrame.new(0,50,0)
                else
                    equipWeapon(Config.FarmWeaponType)
                    attack(target)
                    spamSkills()
                end
            end
        end)
    end))
end
function SeaSys.StopAuto() Manager:Disconnect("SeaLoop") end

local ESPObjs = {}
local function createESP(obj, color, text)
    if ESPObjs[obj] then return end
    safeDo(function()
        local bb = Instance.new("BillboardGui")
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0,200,0,55)
        bb.StudsOffset = Vector3.new(0,3,0)
        local lbl = Instance.new("TextLabel",bb)
        lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color
        lbl.TextStrokeTransparency = 0
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.Text = text
        local adornee = obj:IsA("BasePart") and obj or
                        obj:FindFirstChild("HumanoidRootPart") or
                        obj:FindFirstChild("Handle") or
                        obj:FindFirstChildWhichIsA("BasePart")
        if adornee then
            bb.Adornee = adornee
            bb.Parent = CoreGui
            local conn = RunService.RenderStepped:Connect(function()
                if not obj or not obj.Parent then
                    pcall(function() bb:Destroy() end)
                    ESPObjs[obj] = nil
                    return
                end
                local hrp = getHRP()
                if hrp and adornee and adornee.Parent then
                    local d = math.floor(dist(hrp.Position, adornee.Position))
                    local t = text
                    if Config.ESPDistance then t = t .. " [" .. d .. "m]" end
                    if Config.ESPHealth then
                        local h = obj:FindFirstChild("Humanoid")
                        if h then t = t .. "\n❤ " .. math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth) end
                    end
                    lbl.Text = t
                end
            end)
            ESPObjs[obj] = {bb=bb, conn=conn}
        else
            bb:Destroy()
        end
    end)
end
local function clearESP()
    for _, v in pairs(ESPObjs) do
        pcall(function() v.bb:Destroy() end)
        pcall(function() v.conn:Disconnect() end)
    end
    ESPObjs = {}
end
Manager:Connect("ESPLoop", RunService.RenderStepped:Connect(function()
    safeDo(function()
        if Config.ESPBoss then
            local enemies = Workspace:FindFirstChild("Enemies")
            if enemies then
                for _, e in ipairs(enemies:GetChildren()) do
                    for _, b in ipairs(BossDB) do
                        if e.Name == b.Name and not ESPObjs[e] then
                            createESP(e, Color3.fromRGB(255,60,60), "👹 "..b.Name)
                        end
                    end
                end
            end
        end
        if Config.ESPQuestMobs then
            local qd = getQuest()
            if qd then
                local enemies = Workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, e in ipairs(enemies:GetChildren()) do
                        if e.Name == qd.MobName and not ESPObjs[e] then
                            createESP(e, Color3.fromRGB(200,100,255), "⚔ "..e.Name)
                        end
                    end
                end
            end
        end
        if Config.ESPMirage then
            local m = findMirageIsland()
            if m and not ESPObjs[m] then
                createESP(m, Color3.fromRGB(0,255,220), "🏝 MIRAGE ISLAND")
            end
        end
        if Config.ESPMirageDealer then
            local d = findFruitDealer()
            if d and not ESPObjs[d] then
                createESP(d, Color3.fromRGB(255,215,0), "🍎 FRUIT DEALER")
            end
        end
        if Config.FruitESP then
            for _, fruit in ipairs(getAllFruits()) do
                if not ESPObjs[fruit] then
                    local fn = fruit:IsA("Tool") and fruit.Name or "Fruit"
                    createESP(fruit, isLegendary(fn) and Color3.fromRGB(255,215,0) or Color3.fromRGB(255,140,0), "🍎 "..fn)
                end
            end
        end
        if Config.ESPPlayer then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and not ESPObjs[p.Character] then
                    createESP(p.Character, Color3.fromRGB(0,255,100), "👤 "..p.Name)
                end
            end
        end
    end)
end))

local AdminList = {"Rip_indra","rip_indra","mygame43","Dumped","Xpolsion"}
local adminInServer = false
local function checkAdmins()
    if not Config.AutoDisableOnAdmin then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if table.find(AdminList, p.Name) then return true end
    end
    return false
end
local function disableAll()
    Config.AutoFarm = false
    Config.AutoFarmBoss = false
    Config.AutoRaid = false
    Config.AutoMirage = false
    Config.AutoRaceV4 = false
    Config.FruitSniper = false
    Config.AutoSeaEvents = false
    Config.Fly = false
    Config.NoClip = false
    AutoFarm.Stop()
    BossFarm.Stop()
    RaidSys.StopAuto()
    MirageSys.StopAuto()
    RaceV4Sys.StopAuto()
    FruitSys.StopSniper()
    SeaSys.StopAuto()
    stopTween()
    stopFly()
    clearESP()
    notify("⚠️ REX HUB","ADMIN DETECTED — All disabled!", 10)
end
Players.PlayerAdded:Connect(function(p)
    if table.find(AdminList, p.Name) then disableAll() end
end)
local adminCheckLast = 0
Manager:Connect("AdminCheck", RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - adminCheckLast < 5 then return end
    adminCheckLast = now
    if checkAdmins() and not adminInServer then
        adminInServer = true
        disableAll()
    elseif not checkAdmins() then
        adminInServer = false
    end
end))

if Config.AntiAFK then
    safeDo(function()
        local vu = game:GetService("VirtualUser")
        Manager:Connect("AntiAFK", LP.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end))
    end)
end

local function panicAll()
    Config.AutoFarm=false; Config.AutoFarmBoss=false; Config.AutoRaid=false
    Config.AutoMirage=false; Config.AutoRaceV4=false; Config.FruitSniper=false
    Config.AutoSeaEvents=false; Config.Fly=false; Config.NoClip=false; Config.KillAura=false
    AutoFarm.Stop(); BossFarm.Stop(); RaidSys.StopAuto()
    MirageSys.StopAuto(); RaceV4Sys.StopAuto(); FruitSys.StopSniper()
    SeaSys.StopAuto(); stopTween(); stopFly(); clearESP()
    local h = getHum()
    if h then safeDo(function() h.WalkSpeed=16; h.JumpPower=50 end) end
    notify("🛑 REX HUB","PANIC — ALL STOPPED", 5)
end

local function serverHop()
    notify("Rex Hub","Finding server...",3)
    safeDo(function()
        local data = HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        ))
        if data and data.data then
            for _, sv in ipairs(data.data) do
                if sv.id ~= game.JobId and sv.playing < sv.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, LP)
                    return
                end
            end
        end
        TeleportService:Teleport(game.PlaceId, LP)
    end)
end

local RayfieldLoaded = false
local Rayfield = nil

local rayfieldOk, rayfieldErr = pcall(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    RayfieldLoaded = true
end)

if not RayfieldLoaded then
    warn("[Rex Hub] Rayfield failed: " .. tostring(rayfieldErr))
    notify("Rex Hub","UI load failed — check executor",5)
    return
end

local Window = Rayfield:CreateWindow({
    Name             = "⚡ Rex Hub  |  Blox Fruits",
    Icon             = 0,
    LoadingTitle     = "Rex Hub Loading...",
    LoadingSubtitle  = "Blox Fruits Ultimate Edition",
    Theme            = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
})

local FarmTab = Window:CreateTab("⚔️ Auto Farm", 4483345998)

FarmTab:CreateSection("Main Farm")
FarmTab:CreateToggle({
    Name    = "Auto Farm (Level)",
    CurrentValue = false,
    Flag    = "AutoFarm",
    Callback = function(v)
        Config.AutoFarm  = v
        Config.AutoQuest = v
        if v then AutoFarm.Start() else AutoFarm.Stop() end
    end
})
FarmTab:CreateToggle({
    Name    = "Auto Farm Boss",
    CurrentValue = false,
    Flag    = "AutoFarmBoss",
    Callback = function(v)
        Config.AutoFarmBoss = v
        if v then BossFarm.Start() else BossFarm.Stop() end
    end
})
FarmTab:CreateToggle({
    Name    = "Smart Farm",
    CurrentValue = true,
    Flag    = "SmartFarm",
    Callback = function(v) Config.SmartFarm = v end
})
FarmTab:CreateToggle({
    Name    = "Auto Collect Drops",
    CurrentValue = true,
    Flag    = "AutoCollectDrops",
    Callback = function(v) Config.AutoCollectDrops = v end
})
FarmTab:CreateToggle({
    Name    = "Server Hop (No Mobs)",
    CurrentValue = false,
    Flag    = "ServerHopNoMobs",
    Callback = function(v) Config.ServerHopNoMobs = v end
})

FarmTab:CreateSection("Weapon Settings")
FarmTab:CreateDropdown({
    Name    = "Main Weapon Type",
    Options = {"Combat","Melee","Sword","Blox Fruit","Gun"},
    CurrentOption = {"Combat"},
    Flag    = "FarmWeapon",
    Callback = function(v) Config.FarmWeaponType = v end
})
FarmTab:CreateToggle({
    Name    = "Auto Switch Weapon",
    CurrentValue = false,
    Flag    = "AutoSwitchWeapon",
    Callback = function(v) Config.AutoSwitchWeapon = v end
})
FarmTab:CreateSlider({
    Name    = "Mastery HP Switch %",
    Range   = {10, 60},
    Increment = 5,
    CurrentValue = 30,
    Flag    = "MasteryHP",
    Callback = function(v) Config.MasteryHealthSwitch = v end
})

FarmTab:CreateSection("Safety")
FarmTab:CreateToggle({
    Name    = "Safe Mode",
    CurrentValue = true,
    Flag    = "SafeMode",
    Callback = function(v) Config.SafeMode = v end
})
FarmTab:CreateSlider({
    Name    = "Safe Health %",
    Range   = {10, 50},
    Increment = 5,
    CurrentValue = 30,
    Flag    = "SafeHP",
    Callback = function(v) Config.SafeHealthPercent = v end
})

local BossTab = Window:CreateTab("👹 Boss Farm", 4483345998)
BossTab:CreateSection("Boss Selection")

local bossNames = {"Auto"}
for _, b in ipairs(BossDB) do table.insert(bossNames, b.Name) end

BossTab:CreateDropdown({
    Name    = "Select Boss",
    Options = bossNames,
    CurrentOption = {"Auto"},
    Flag    = "SelectedBoss",
    Callback = function(v) Config.SelectedBoss = v end
})
BossTab:CreateToggle({
    Name    = "Auto Farm Boss",
    CurrentValue = false,
    Flag    = "BossFarmToggle",
    Callback = function(v)
        Config.AutoFarmBoss = v
        if v then BossFarm.Start() else BossFarm.Stop() end
    end
})
BossTab:CreateButton({
    Name    = "📍 TP to Selected Boss",
    Callback = function()
        local b = Config.SelectedBoss == "Auto" and getBossForLevel() or findBoss(Config.SelectedBoss)
        if b then
            teleportSafe(b.Pos * CFrame.new(0,5,0))
            notify("Rex Hub","Teleported to "..b.Name, 2)
        end
    end
})

local MirageTab = Window:CreateTab("🏝️ Mirage Island", 4483345998)
MirageTab:CreateSection("Mirage System")
MirageTab:CreateToggle({
    Name    = "Auto Mirage Island",
    CurrentValue = false,
    Flag    = "AutoMirage",
    Callback = function(v)
        Config.AutoMirage = v
        if v then MirageSys.StartAuto() else MirageSys.StopAuto() end
    end
})
MirageTab:CreateToggle({
    Name    = "ESP Mirage Island",
    CurrentValue = true,
    Flag    = "ESPMirage",
    Callback = function(v) Config.ESPMirage = v end
})
MirageTab:CreateToggle({
    Name    = "ESP Fruit Dealer",
    CurrentValue = true,
    Flag    = "ESPDealer",
    Callback = function(v) Config.ESPMirageDealer = v end
})
MirageTab:CreateToggle({
    Name    = "Mirage Notification",
    CurrentValue = true,
    Flag    = "MirageNotif",
    Callback = function(v) Config.MirageNotification = v end
})
MirageTab:CreateButton({
    Name    = "📍 TP to Mirage Coords",
    Callback = function()
        teleportSafe(CFrame.new(925,81,34226))
        notify("Rex Hub","Teleported to Mirage coords", 2)
    end
})

local RaceTab = Window:CreateTab("🧬 Race V4", 4483345998)
RaceTab:CreateSection("Race V4 System")
RaceTab:CreateToggle({
    Name    = "Auto Race V4 (Farm Minotaur)",
    CurrentValue = false,
    Flag    = "AutoRaceV4",
    Callback = function(v)
        Config.AutoRaceV4 = v
        if v then RaceV4Sys.StartAuto() else RaceV4Sys.StopAuto() end
    end
})
RaceTab:CreateButton({
    Name    = "📍 TP to Minotaur Spawn",
    Callback = function()
        teleportSafe(CFrame.new(-12489,332,-7558))
        notify("Rex Hub","Teleported to Minotaur", 2)
    end
})
RaceTab:CreateButton({
    Name    = "📍 TP to Ancient Altar",
    Callback = function()
        teleportSafe(CFrame.new(-5039,313,-2991))
        notify("Rex Hub","Teleported to Ancient Altar", 2)
    end
})
RaceTab:CreateButton({
    Name    = "📍 TP to Castle on the Sea",
    Callback = function()
        teleportSafe(CFrame.new(-5039,313,-2991))
        notify("Rex Hub","Teleported to Castle", 2)
    end
})
RaceTab:CreateLabel("Your Race: " .. getRace() .. " | Level: " .. getLevel())

local FruitTab = Window:CreateTab("🍎 Fruits", 4483345998)
FruitTab:CreateSection("Fruit Sniper")
FruitTab:CreateToggle({
    Name    = "Fruit Sniper",
    CurrentValue = false,
    Flag    = "FruitSniper",
    Callback = function(v)
        Config.FruitSniper = v
        if v then FruitSys.StartSniper() else FruitSys.StopSniper() end
    end
})
FruitTab:CreateToggle({
    Name    = "Fruit ESP",
    CurrentValue = false,
    Flag    = "FruitESP",
    Callback = function(v) Config.FruitESP = v end
})
FruitTab:CreateToggle({
    Name    = "Auto Store Fruit",
    CurrentValue = false,
    Flag    = "AutoStoreFruit",
    Callback = function(v) Config.AutoStoreFruit = v end
})
FruitTab:CreateToggle({
    Name    = "Fruit Notification",
    CurrentValue = true,
    Flag    = "FruitNotif",
    Callback = function(v) Config.FruitNotification = v end
})
FruitTab:CreateDropdown({
    Name    = "Target Fruit",
    Options = {"Any","Legendary","Mythical","Dragon","Leopard","Spirit","Dough","Buddha","Control","Venom","Shadow"},
    CurrentOption = {"Any"},
    Flag    = "TargetFruit",
    Callback = function(v) Config.TargetFruit = v end
})

local RaidTab = Window:CreateTab("🏴‍☠️ Raids & Sea", 4483345998)
RaidTab:CreateSection("Raids")
RaidTab:CreateToggle({
    Name    = "Auto Raid",
    CurrentValue = false,
    Flag    = "AutoRaid",
    Callback = function(v)
        Config.AutoRaid = v
        if v then RaidSys.StartAuto() else RaidSys.StopAuto() end
    end
})
RaidTab:CreateToggle({
    Name    = "Auto Buy Chip",
    CurrentValue = false,
    Flag    = "AutoBuyChip",
    Callback = function(v) Config.AutoBuyChip = v end
})
RaidTab:CreateSection("Sea Events")
RaidTab:CreateToggle({
    Name    = "Auto Sea Events",
    CurrentValue = false,
    Flag    = "AutoSeaEvents",
    Callback = function(v)
        Config.AutoSeaEvents = v
        if v then SeaSys.StartAuto() else SeaSys.StopAuto() end
    end
})
RaidTab:CreateToggle({
    Name    = "Auto Sea Beast",
    CurrentValue = false,
    Flag    = "AutoSeaBeast",
    Callback = function(v) Config.AutoSeaBeast = v end
})
RaidTab:CreateToggle({
    Name    = "Auto Terror Shark",
    CurrentValue = false,
    Flag    = "AutoTerrorShark",
    Callback = function(v) Config.AutoTerrorShark = v end
})
RaidTab:CreateToggle({
    Name    = "Auto Leviathan",
    CurrentValue = false,
    Flag    = "AutoLeviathan",
    Callback = function(v) Config.AutoLeviathan = v end
})

local CombatTab = Window:CreateTab("⚡ Combat", 4483345998)
CombatTab:CreateSection("Combat Settings")
CombatTab:CreateToggle({Name="Auto Skill",      CurrentValue=true,  Flag="AutoSkill",   Callback=function(v) Config.AutoSkill=v end})
CombatTab:CreateToggle({Name="Fast Attack",     CurrentValue=true,  Flag="FastAttack",  Callback=function(v) Config.FastAttack=v end})
CombatTab:CreateToggle({Name="Auto Buso Haki",  CurrentValue=true,  Flag="AutoBuso",    Callback=function(v) Config.AutoBusoHaki=v end})
CombatTab:CreateToggle({Name="Auto Ken Haki",   CurrentValue=false, Flag="AutoKen",     Callback=function(v) Config.AutoKenHaki=v end})
CombatTab:CreateToggle({Name="Kill Aura",       CurrentValue=false, Flag="KillAura",    Callback=function(v) Config.KillAura=v end})
CombatTab:CreateToggle({Name="Bring Mobs",      CurrentValue=true,  Flag="BringMobs",   Callback=function(v) Config.BringMobs=v end})
CombatTab:CreateToggle({Name="Expand Hitbox",   CurrentValue=true,  Flag="ExpandHitbox",Callback=function(v) Config.ExpandHitbox=v end})
CombatTab:CreateSlider({Name="Hitbox Size",     Range={10,100},Increment=5,CurrentValue=50,  Flag="HitboxSize",  Callback=function(v) Config.HitboxSize=v end})
CombatTab:CreateSlider({Name="Bring Distance",  Range={20,200},Increment=10,CurrentValue=100,Flag="BringDist",   Callback=function(v) Config.BringDistance=v end})
CombatTab:CreateSlider({Name="Farm Distance",   Range={20,150},Increment=10,CurrentValue=50, Flag="FarmDist",    Callback=function(v) Config.FarmDistance=v end})

local ESPTab = Window:CreateTab("👁️ ESP", 4483345998)
ESPTab:CreateSection("ESP Options")
ESPTab:CreateToggle({Name="Boss ESP",        CurrentValue=true,  Flag="ESPBoss",    Callback=function(v) Config.ESPBoss=v end})
ESPTab:CreateToggle({Name="Quest Mob ESP",   CurrentValue=true,  Flag="ESPQuest",   Callback=function(v) Config.ESPQuestMobs=v end})
ESPTab:CreateToggle({Name="Mirage ESP",      CurrentValue=true,  Flag="ESPMirage2", Callback=function(v) Config.ESPMirage=v end})
ESPTab:CreateToggle({Name="Fruit Dealer ESP",CurrentValue=true,  Flag="ESPDealer2", Callback=function(v) Config.ESPMirageDealer=v end})
ESPTab:CreateToggle({Name="Fruit ESP",       CurrentValue=false, Flag="ESPFruit",   Callback=function(v) Config.FruitESP=v end})
ESPTab:CreateToggle({Name="Player ESP",      CurrentValue=false, Flag="ESPPlayer",  Callback=function(v) Config.ESPPlayer=v end})
ESPTab:CreateToggle({Name="Chest ESP",       CurrentValue=false, Flag="ESPChest",   Callback=function(v) Config.ESPChest=v end})
ESPTab:CreateToggle({Name="Flower ESP",      CurrentValue=false, Flag="ESPFlower",  Callback=function(v) Config.ESPFlower=v end})
ESPTab:CreateToggle({Name="Show Distance",   CurrentValue=true,  Flag="ESPDist",    Callback=function(v) Config.ESPDistance=v end})
ESPTab:CreateToggle({Name="Show Health",     CurrentValue=true,  Flag="ESPHealth",  Callback=function(v) Config.ESPHealth=v end})
ESPTab:CreateButton({Name="🗑 Clear All ESP", Callback=function() clearESP() end})

local TPTab = Window:CreateTab("🗺️ Teleport", 4483345998)
TPTab:CreateSection("Island Teleport")

local islandNames = {}
for n, _ in pairs(IslandDB) do table.insert(islandNames, n) end
table.sort(islandNames)

TPTab:CreateDropdown({
    Name    = "Select Island",
    Options = islandNames,
    CurrentOption = {"Starter Island"},
    Flag    = "SelectedIsland",
    Callback = function(v) Config.SelectedIsland = v end
})
TPTab:CreateButton({
    Name    = "📍 Teleport to Island",
    Callback = function()
        local d = IslandDB[Config.SelectedIsland]
        if d then
            teleportSafe(d.Pos * CFrame.new(0,5,0))
            notify("Rex Hub","Teleported to "..Config.SelectedIsland, 2)
        end
    end
})
TPTab:CreateSection("Quick Teleport")
TPTab:CreateButton({Name="📍 TP to Quest Giver", Callback=function()
    local q = getQuest(); if q then teleportSafe(q.QuestPos); notify("Rex Hub","Teleported to Quest Giver",2) end
end})
TPTab:CreateButton({Name="📍 TP to Quest Mobs", Callback=function()
    local q = getQuest(); if q then teleportSafe(q.MobPos); notify("Rex Hub","Teleported to Mobs",2) end
end})
TPTab:CreateButton({Name="📍 TP to Closest Enemy", Callback=function()
    local e = getClosestEnemy(500)
    local hrp = getHRP()
    if e and hrp then
        local mhrp = e:FindFirstChild("HumanoidRootPart")
        if mhrp then hrp.CFrame = mhrp.CFrame * CFrame.new(0,4,0) end
    end
end})

local UtilTab = Window:CreateTab("⚙️ Utility", 4483345998)
UtilTab:CreateSection("Movement")
UtilTab:CreateSlider({Name="Walk Speed",Range={16,500},Increment=10,CurrentValue=16,Flag="WalkSpeed",Callback=function(v) Config.WalkSpeed=v end})
UtilTab:CreateSlider({Name="Jump Power", Range={50,500},Increment=10,CurrentValue=50,Flag="JumpPower",Callback=function(v) Config.JumpPower=v end})
UtilTab:CreateToggle({Name="Fly",CurrentValue=false,Flag="Fly",Callback=function(v)
    Config.Fly=v
    if v then startFly() else stopFly() end
end})
UtilTab:CreateSlider({Name="Fly Speed",Range={50,500},Increment=25,CurrentValue=150,Flag="FlySpeed",Callback=function(v) Config.FlySpeed=v end})
UtilTab:CreateToggle({Name="NoClip",CurrentValue=false,Flag="NoClip",Callback=function(v) Config.NoClip=v end})
UtilTab:CreateToggle({Name="Infinite Energy",CurrentValue=false,Flag="InfEnergy",Callback=function(v) Config.InfiniteEnergy=v end})
UtilTab:CreateSection("Performance & Safety")
UtilTab:CreateToggle({Name="Anti AFK",CurrentValue=true,Flag="AntiAFK",Callback=function(v) Config.AntiAFK=v end})
UtilTab:CreateToggle({Name="Auto Disable on Admin",CurrentValue=true,Flag="AutoDisableAdmin",Callback=function(v) Config.AutoDisableOnAdmin=v end})
UtilTab:CreateToggle({Name="FPS Booster",CurrentValue=false,Flag="FPSBooster",Callback=function(v)
    Config.FPSBooster=v
    if v then
        safeDo(function()
            settings().Rendering.QualityLevel = 1
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9999999
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") then
                    safeDo(function() obj.Enabled=false end)
                end
            end
        end)
    else
        safeDo(function()
            settings().Rendering.QualityLevel = 10
            Lighting.GlobalShadows = true
        end)
    end
end})
UtilTab:CreateButton({Name="🔄 Server Hop",   Callback=function() serverHop() end})
UtilTab:CreateButton({Name="🛑 PANIC BUTTON", Callback=function() panicAll() end})

local InfoTab = Window:CreateTab("📊 Info", 4483345998)
InfoTab:CreateSection("Player Info")
InfoTab:CreateLabel("⚡ Rex Hub — Blox Fruits Ultimate")
InfoTab:CreateLabel("👤 Player: "  .. LP.Name)
InfoTab:CreateLabel("📊 Level: "   .. getLevel())
InfoTab:CreateLabel("🌊 Sea: "     .. getSea())
InfoTab:CreateLabel("🧬 Race: "    .. getRace())
InfoTab:CreateLabel("💰 Beli: $"   .. getBeli())
InfoTab:CreateLabel("💎 Fragments: " .. getFragments())
InfoTab:CreateSection("Current Quest")
local qd = getQuest()
if qd then
    InfoTab:CreateLabel("🎯 Mob: " .. qd.MobName)
    InfoTab:CreateLabel("🏝 Island: " .. qd.Island)
    InfoTab:CreateLabel("📏 Level Range: " .. qd.Min .. " – " .. qd.Max)
end
InfoTab:CreateSection("Controls")
InfoTab:CreateLabel("Insert / RightAlt — Toggle UI")
InfoTab:CreateLabel("PANIC: Use button in Utility tab")

Rayfield:Notify({
    Title    = "⚡ Rex Hub",
    Content  = "Blox Fruits loaded! Level " .. getLevel() .. " | Sea " .. getSea(),
    Duration = 6,
})

print("╔═══════════════════════════════════════╗")
print("║  ⚡ REX HUB — Blox Fruits Ultimate    ║")
print("║  Level: "..getLevel().." | Sea: "..getSea().." | Race: "..getRace())
print("╚═══════════════════════════════════════╝")
