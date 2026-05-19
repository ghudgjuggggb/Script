-- ╔══════════════════════════════════════════════════════╗
-- ║           NEKO HUB  |  Sailor Piece                 ║
-- ║  All functions from NixHub · Rayfield UI            ║
-- ╚══════════════════════════════════════════════════════╝

if getgenv().NekoHub_Running then
    warn("[NekoHub] Already running!")
    return
end

repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.GameId ~= 0

-- ─── Compat helpers ───────────────────────────────────
local function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end

cloneref      = missing("function", cloneref,      function(...) return ... end)
getgc         = missing("function", getgc or get_gc_objects)
getconnections= missing("function", getconnections or get_signal_cons)

-- ─── Services ─────────────────────────────────────────
local Services = setmetatable({}, {
    __index = function(self, name)
        local ok, cache = pcall(function() return cloneref(game:GetService(name)) end)
        if ok then rawset(self, name, cache); return cache end
        error("Invalid Service: " .. tostring(name))
    end,
})

local Players        = Services.Players
local RunService     = Services.RunService
local HttpService    = Services.HttpService
local TweenService   = Services.TweenService
local GuiService     = Services.GuiService
local TeleportService= Services.TeleportService
local UIS            = Services.UserInputService
local Marketplace    = Services.MarketplaceService
local Lighting       = game:GetService("Lighting")

local Plr  = Players.LocalPlayer
local Char = Plr.Character or Plr.CharacterAdded:Wait()
local PGui = Plr:WaitForChild("PlayerGui")
local RS   = Services.ReplicatedStorage

getgenv().NekoHub_Running = true

-- ─── Executor support flags ───────────────────────────
local Support = {
    Webhook   = (typeof(request)            == "function" or typeof(http_request) == "function"),
    Clipboard = (typeof(setclipboard)       == "function"),
    FileIO    = (typeof(writefile)          == "function" and typeof(isfile) == "function"),
    QueueOnTP = (typeof(queue_on_teleport)  == "function"),
    Proximity = (typeof(fireproximityprompt)== "function"),
}
local executorName   = (identifyexecutor and identifyexecutor() or "Unknown"):lower()
local isXeno         = executorName:find("xeno") ~= nil

-- ─── Rayfield ─────────────────────────────────────────
local ok_rf, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok_rf then warn("[NekoHub] Rayfield failed: " .. tostring(Rayfield)); getgenv().NekoHub_Running = false; return end

-- ─── Toggles / Options tables (mirrors Obsidian API) ──
-- All game logic uses Toggles.X.Value and Options.X.Value
-- We populate these when Rayfield callbacks fire.
local Toggles = {}
local Options  = {}

local function MakeToggle(id, default)
    Toggles[id] = { Value = default or false }
    return Toggles[id]
end
local function MakeOption(id, default)
    Options[id] = { Value = default }
    return Options[id]
end

-- ─── Shared state ─────────────────────────────────────
local Shared = {
    GlobalPrio="FARM", Farm=true, Recovering=false,
    MovingIsland=false, Island="", Target=nil,
    KillTick=0, TargetValid=false, QuestNPC="",
    MobIdx=1, AllMobIdx=1, WeapRotationIdx=1,
    ComboIdx=1, ParsedCombo={}, ActiveWeap="",
    ArmHaki=false, BossTIMap={},
    InventorySynced=false, Stats={}, Settings={},
    GemStats={}, SkillTree={Nodes={},Points=0},
    Passives={}, SpecStatsSlider={},
    ArtifactSession={Inventory={},Dust=0,InvCount=0},
    UpBlacklist={},
    MerchantBusy=false, LocalMerchantTime=0,
    LastTimerTick=tick(), MerchantExecute=false,
    FirstMerchantSync=false, CurrentStock={},
    LastM1=0, LastWRSwitch=0,
    LastSwitch={Title="",Rune="",Build=""},
    LastBuildSwitch=0, LastDungeon=0,
    AltDamage={}, AltActive=false, TradeState={},
    Cached={Inv={},Accessories={},RawWeapCache={Sword={},Melee={}}},
}

local Script_Start_Time = os.time()
local StartStats = {
    Level  = Plr.Data.Level.Value,
    Money  = Plr.Data.Money.Value,
    Gems   = Plr.Data.Gems.Value,
    Bounty = (Plr:FindFirstChild("leaderstats") and Plr.leaderstats:FindFirstChild("Bounty") and Plr.leaderstats.Bounty.Value) or 0,
}

local function GetSessionTime()
    local s = os.time() - Script_Start_Time
    return string.format("%dh %02dm", math.floor(s/3600), math.floor((s%3600)/60))
end

-- ─── Module / Remote helpers ──────────────────────────
local function GetSafeModule(parent, name)
    local obj = parent:FindFirstChild(name)
    if obj and obj:IsA("ModuleScript") then
        local ok, r = pcall(require, obj); if ok then return r end
    end
    return nil
end

local function GetRemote(parent, pathStr)
    local cur = parent
    for _, name in ipairs(pathStr:split(".")) do
        if not cur then return nil end
        cur = cur:FindFirstChild(name)
    end
    return cur
end

local function SafeInvoke(remote, ...)
    local args = {...}; local result = nil
    task.spawn(function()
        local ok, res = pcall(function() return remote:InvokeServer(unpack(args)) end)
        result = res
    end)
    local start = tick()
    repeat task.wait() until result ~= nil or (tick()-start) > 2
    return result
end

local function fire_event(signal, ...)
    if firesignal then return firesignal(signal, ...) end
    if getconnections then
        for _, c in ipairs(getconnections(signal)) do
            if c.Function then task.spawn(c.Function, ...) end
        end
    end
end

-- ─── Remotes ──────────────────────────────────────────
local _DR = GetRemote(RS, "RemoteEvents.DashRemote")
local _FS = (_DR and _DR.FireServer)

local Remotes = {
    SettingsToggle  = GetRemote(RS,"RemoteEvents.SettingsToggle"),
    SettingsSync    = GetRemote(RS,"RemoteEvents.SettingsSync"),
    UseCode         = GetRemote(RS,"RemoteEvents.CodeRedeem"),
    M1              = GetRemote(RS,"CombatSystem.Remotes.RequestHit"),
    EquipWeapon     = GetRemote(RS,"Remotes.EquipWeapon"),
    UseSkill        = GetRemote(RS,"AbilitySystem.Remotes.RequestAbility"),
    UseFruit        = GetRemote(RS,"RemoteEvents.FruitPowerRemote"),
    QuestAccept     = GetRemote(RS,"RemoteEvents.QuestAccept"),
    QuestAbandon    = GetRemote(RS,"RemoteEvents.QuestAbandon"),
    UseItem         = GetRemote(RS,"Remotes.UseItem"),
    SlimeCraft      = GetRemote(RS,"Remotes.RequestSlimeCraft"),
    GrailCraft      = GetRemote(RS,"Remotes.RequestGrailCraft"),
    RerollSingleStat= GetRemote(RS,"Remotes.RerollSingleStat"),
    SkillTreeUpgrade= GetRemote(RS,"RemoteEvents.SkillTreeUpgrade"),
    Enchant         = GetRemote(RS,"Remotes.EnchantAccessory"),
    Blessing        = GetRemote(RS,"Remotes.BlessWeapon"),
    ArtifactSync    = GetRemote(RS,"RemoteEvents.ArtifactDataSync"),
    ArtifactClaim   = GetRemote(RS,"RemoteEvents.ArtifactMilestoneClaimReward"),
    MassDelete      = GetRemote(RS,"RemoteEvents.ArtifactMassDeleteByUUIDs"),
    MassUpgrade     = GetRemote(RS,"RemoteEvents.ArtifactMassUpgrade"),
    ArtifactLock    = GetRemote(RS,"RemoteEvents.ArtifactLock"),
    ArtifactUnequip = GetRemote(RS,"RemoteEvents.ArtifactUnequip"),
    ArtifactEquip   = GetRemote(RS,"RemoteEvents.ArtifactEquip"),
    Roll_Trait      = GetRemote(RS,"RemoteEvents.TraitReroll"),
    TraitAutoSkip   = GetRemote(RS,"RemoteEvents.TraitUpdateAutoSkip"),
    TraitConfirm    = GetRemote(RS,"RemoteEvents.TraitConfirm"),
    SpecPassiveReroll=GetRemote(RS,"RemoteEvents.SpecPassiveReroll"),
    ArmHaki         = GetRemote(RS,"RemoteEvents.HakiRemote"),
    ObserHaki       = GetRemote(RS,"RemoteEvents.ObservationHakiRemote"),
    ConquerorHaki   = GetRemote(RS,"Remotes.ConquerorHakiRemote"),
    TP_Portal       = GetRemote(RS,"Remotes.TeleportToPortal"),
    OpenDungeon     = GetRemote(RS,"Remotes.RequestDungeonPortal"),
    DungeonWaveVote = GetRemote(RS,"Remotes.DungeonWaveVote"),
    EquipTitle      = GetRemote(RS,"RemoteEvents.TitleEquip"),
    TitleUnequip    = GetRemote(RS,"RemoteEvents.TitleUnequip"),
    EquipRune       = GetRemote(RS,"Remotes.EquipRune"),
    LoadoutLoad     = GetRemote(RS,"RemoteEvents.LoadoutLoad"),
    AddStat         = GetRemote(RS,"RemoteEvents.AllocateStat"),
    OpenMerchant    = GetRemote(RS,"Remotes.MerchantRemotes.OpenMerchantUI"),
    MerchantBuy     = GetRemote(RS,"Remotes.MerchantRemotes.PurchaseMerchantItem"),
    StockUpdate     = GetRemote(RS,"Remotes.MerchantRemotes.MerchantStockUpdate"),
    SummonBoss      = GetRemote(RS,"Remotes.RequestSummonBoss"),
    JJKSummonBoss   = GetRemote(RS,"Remotes.RequestSpawnStrongestBoss"),
    RimuruBoss      = GetRemote(RS,"RemoteEvents.RequestSpawnRimuru"),
    AnosBoss        = GetRemote(RS,"Remotes.RequestSpawnAnosBoss"),
    TrueAizenBoss   = GetRemote(RS,"RemoteEvents.RequestSpawnTrueAizen"),
    AtomicBoss      = GetRemote(RS,"RemoteEvents.RequestSpawnAtomic"),
    ReqInventory    = GetRemote(RS,"Remotes.RequestInventory"),
    Ascend          = GetRemote(RS,"RemoteEvents.RequestAscend"),
    ReqAscend       = GetRemote(RS,"RemoteEvents.GetAscendData"),
    CloseAscend     = GetRemote(RS,"RemoteEvents.CloseAscendUI"),
    TradeRespond    = GetRemote(RS,"Remotes.TradeRemotes.RespondToRequest"),
    TradeSend       = GetRemote(RS,"Remotes.TradeRemotes.SendTradeRequest"),
    TradeAddItem    = GetRemote(RS,"Remotes.TradeRemotes.AddItemToTrade"),
    TradeReady      = GetRemote(RS,"Remotes.TradeRemotes.SetReady"),
    TradeConfirm    = GetRemote(RS,"Remotes.TradeRemotes.ConfirmTrade"),
    TradeUpdated    = GetRemote(RS,"Remotes.TradeRemotes.TradeUpdated"),
    HakiStateUpdate = GetRemote(RS,"RemoteEvents.HakiStateUpdate"),
    UpInventory     = GetRemote(RS,"Remotes.UpdateInventory"),
    UpPlayerStats   = GetRemote(RS,"RemoteEvents.UpdatePlayerStats"),
    UpSkillTree     = GetRemote(RS,"RemoteEvents.SkillTreeUpdate"),
    BossUIUpdate    = GetRemote(RS,"Remotes.BossUIUpdate"),
    TitleSync       = GetRemote(RS,"RemoteEvents.TitleDataSync"),
    SpecPassiveSkip = GetRemote(RS,"RemoteEvents.SpecPassiveUpdateAutoSkip"),
    SpecPassiveUpdate=GetRemote(RS,"RemoteEvents.SpecPassiveDataUpdate"),
    NotifyItemDrop  = GetRemote(RS,"Remotes.NotifyItemDrop"),
}

-- ─── Modules ──────────────────────────────────────────
local Modules = {
    BossConfig    = GetSafeModule(RS.Modules,"BossConfig")           or {Bosses={}},
    TimedConfig   = GetSafeModule(RS.Modules,"TimedBossConfig"),
    SummonConfig  = GetSafeModule(RS.Modules,"SummonableBossConfig"),
    Merchant      = GetSafeModule(RS.Modules,"MerchantConfig")       or {ITEMS={}},
    Title         = GetSafeModule(RS.Modules,"TitlesConfig")         or {},
    Quests        = GetSafeModule(RS.Modules,"QuestConfig")          or {RepeatableQuests={},Questlines={}},
    WeaponClass   = GetSafeModule(RS.Modules,"WeaponClassification") or {Tools={}},
    ArtifactConfig= GetSafeModule(RS.Modules,"ArtifactConfig"),
    Stats         = GetSafeModule(RS.Modules,"StatRerollConfig"),
    Codes         = GetSafeModule(RS,"CodesConfig")                  or {Codes={}},
    ItemRarity    = GetSafeModule(RS.Modules,"ItemRarityConfig"),
    Trait         = GetSafeModule(RS.Modules,"TraitConfig")          or {Traits={}},
    Race          = GetSafeModule(RS.Modules,"RaceConfig")           or {Races={}},
    Clan          = GetSafeModule(RS.Modules,"ClanConfig")           or {Clans={}},
    SpecPassive   = GetSafeModule(RS.Modules,"SpecPassiveConfig"),
    SkillTree     = GetSafeModule(RS.Modules,"SkillTreeConfig"),
    InfiniteTower = GetSafeModule(RS.Modules,"InfiniteTowerConfig"),
    DungeonMerch  = GetSafeModule(RS.Modules,"DungeonMerchantConfig"),
    InfTowerMerch = GetSafeModule(RS.Modules,"InfiniteTowerMerchantConfig"),
    BossRushMerch = GetSafeModule(RS.Modules,"BossRushMerchantConfig"),
    Fruits        = GetSafeModule(RS:FindFirstChild("FruitPowerSystem") or RS,"FruitPowerConfig") or {Powers={}},
}

-- ─── Tables / Lists ───────────────────────────────────
local Tables = {
    MobList={}, BossList={}, AllBossList={}, AllNPCList={},
    AllEntitiesList={}, SummonList={}, OtherSummonList={"StrongestHistory","StrongestToday","Rimuru","Anos","TrueAizen","Atomic","AbyssalEmpress"},
    Weapon={"Melee","Sword","Power"},
    ManualWeaponClass={["Invisible"]="Power",["Bomb"]="Power",["Quake"]="Power"},
    MerchantList={}, DungeonMerchantList={}, InfiniteTowerMerchantList={}, BossRushMerchantList={},
    Rarities={"Common","Rare","Epic","Legendary","Mythical","Secret","Aura Crate","Cosmetic Crate"},
    CraftItemList={"SlimeKey","DivineGrail"},
    UnlockedTitle={}, TitleCategory={"None","Best EXP","Best Money & Gem","Best Luck","Best DMG"}, TitleList={},
    BuildList={"1","2","3","4","5","None"}, TraitList={},
    RarityWeight={Secret=1,Mythical=2,Legendary=3,Epic=4,Rare=5,Uncommon=6,Common=7},
    RaceList={}, ClanList={}, RuneList={"None"}, SpecPassive={},
    GemStat=Modules.Stats and Modules.Stats.StatKeys or {},
    GemRank=Modules.Stats and Modules.Stats.RankOrder or {},
    OwnedWeapon={}, AllOwnedWeapons={}, OwnedAccessory={}, QuestlineList={},
    OwnedItem={}, MobToIsland={},
    IslandList={"Starter","Jungle","Desert","Snow","Sailor","Shibuya","HuecoMundo","Boss","Dungeon","Shinjuku","Valentine","Slime","Academy","Judgement","SoulSociety","Tower"},
    NPC_QuestList={"DungeonUnlock","SlimeKeyUnlock"},
    NPC_MiscList={"Artifacts","Blessing","Enchant","SkillTree","Cupid","ArmHaki","Observation","Conqueror"},
    DungeonList={"CidDungeon","RuneDungeon","DoubleDungeon","BossRush","InfiniteTower"},
    NPC_MovesetList={}, NPC_MasteryList={},
    MiniBossList={"ThiefBoss","MonkeyBoss","DesertBoss","SnowBoss","PandaMiniBoss"},
    DiffList={"Normal","Medium","Hard","Extreme"},
}

local SummonMap = {}
local NewItemsBuffer = {}
local Connections = {Player_General=nil,Idled=nil,Merchant=nil,Dash=nil,Knockback={},Reconnect=nil}
local Flags = {}

-- Island teleport crystals
local IslandCrystals = {
    ["Starter"]     = workspace:FindFirstChild("StarterIsland")    and workspace.StarterIsland:FindFirstChild("SpawnPointCrystal_Starter"),
    ["Jungle"]      = workspace:FindFirstChild("JungleIsland")     and workspace.JungleIsland:FindFirstChild("SpawnPointCrystal_Jungle"),
    ["Desert"]      = workspace:FindFirstChild("DesertIsland")     and workspace.DesertIsland:FindFirstChild("SpawnPointCrystal_Desert"),
    ["Snow"]        = workspace:FindFirstChild("SnowIsland")       and workspace.SnowIsland:FindFirstChild("SpawnPointCrystal_Snow"),
    ["Sailor"]      = workspace:FindFirstChild("SailorIsland")     and workspace.SailorIsland:FindFirstChild("SpawnPointCrystal_Sailor"),
    ["Shibuya"]     = workspace:FindFirstChild("ShibuyaStation")   and workspace.ShibuyaStation:FindFirstChild("SpawnPointCrystal_Shibuya"),
    ["HuecoMundo"]  = workspace:FindFirstChild("HuecoMundo")       and workspace.HuecoMundo:FindFirstChild("SpawnPointCrystal_HuecoMundo"),
    ["Boss"]        = workspace:FindFirstChild("BossIsland")       and workspace.BossIsland:FindFirstChild("SpawnPointCrystal_Boss"),
    ["Dungeon"]     = workspace:FindFirstChild("Main Temple")      and workspace["Main Temple"]:FindFirstChild("SpawnPointCrystal_Dungeon"),
    ["Shinjuku"]    = workspace:FindFirstChild("ShinjukuIsland")   and workspace.ShinjukuIsland:FindFirstChild("SpawnPointCrystal_Shinjuku"),
    ["Valentine"]   = workspace:FindFirstChild("ValentineIsland")  and workspace.ValentineIsland:FindFirstChild("SpawnPointCrystal_Valentine"),
    ["Slime"]       = workspace:FindFirstChild("SlimeIsland")      and workspace.SlimeIsland:FindFirstChild("SpawnPointCrystal_Slime"),
    ["Academy"]     = workspace:FindFirstChild("AcademyIsland")    and workspace.AcademyIsland:FindFirstChild("SpawnPointCrystal_Academy"),
    ["Judgement"]   = workspace:FindFirstChild("JudgementIsland")  and workspace.JudgementIsland:FindFirstChild("SpawnPointCrystal_Judgement"),
    ["SoulDominion"]= workspace:FindFirstChild("SoulDominionIsland") and workspace.SoulDominionIsland:FindFirstChild("SpawnPointCrystal_SoulDominion"),
    ["NinjaIsland"] = workspace:FindFirstChild("NinjaIsland")      and workspace.NinjaIsland:FindFirstChild("SpawnPointCrystal_Ninja"),
    ["LawlessIsland"]= workspace:FindFirstChild("LawlessIsland")   and workspace.LawlessIsland:FindFirstChild("SpawnPointCrystal_Lawless"),
    ["TowerIsland"] = workspace:FindFirstChild("TowerIsland")      and workspace.TowerIsland:FindFirstChild("SpawnPointCrystal_Tower"),
}

local PATH = {
    Mobs         = workspace:WaitForChild("NPCs"),
    InteractNPCs = workspace:WaitForChild("ServiceNPCs"),
}

-- ─── Populate lists from modules ──────────────────────
if Modules.TimedConfig and Modules.TimedConfig.Bosses then
    for _, data in pairs(Modules.TimedConfig.Bosses) do
        table.insert(Tables.BossList, data.displayName)
        local tpName = data.spawnLocation:gsub(" Island",""):gsub(" Station","")
        if data.spawnLocation == "Hueco Mundo Island" then tpName = "HuecoMundo" end
        if data.spawnLocation == "Judgement Island"   then tpName = "Judgement"  end
        Shared.BossTIMap[data.displayName] = tpName
    end
    table.sort(Tables.BossList)
end

if Modules.SummonConfig and Modules.SummonConfig.Bosses then
    for _, data in pairs(Modules.SummonConfig.Bosses) do
        table.insert(Tables.SummonList, data.displayName)
        SummonMap[data.displayName] = data.bossId
    end
    table.sort(Tables.SummonList)
end

for bossName, _ in pairs(Modules.BossConfig.Bosses) do
    table.insert(Tables.AllBossList, bossName:gsub("Boss$",""))
end
table.sort(Tables.AllBossList)

for item in pairs(Modules.Merchant.ITEMS) do table.insert(Tables.MerchantList, item) end

for name, _ in pairs(Modules.Trait.Traits) do table.insert(Tables.TraitList, name) end
table.sort(Tables.TraitList, function(a,b)
    local wa = Tables.RarityWeight[Modules.Trait.Traits[a].Rarity] or 99
    local wb = Tables.RarityWeight[Modules.Trait.Traits[b].Rarity] or 99
    return wa ~= wb and wa < wb or a < b
end)

for name in pairs(Modules.Race.Races) do table.insert(Tables.RaceList, name) end
table.sort(Tables.RaceList, function(a,b)
    local wa = Tables.RarityWeight[Modules.Race.Races[a].rarity] or 99
    local wb = Tables.RarityWeight[Modules.Race.Races[b].rarity] or 99
    return wa ~= wb and wa < wb or a < b
end)

for name in pairs(Modules.Clan.Clans) do table.insert(Tables.ClanList, name) end
table.sort(Tables.ClanList, function(a,b)
    local wa = Tables.RarityWeight[Modules.Clan.Clans[a].rarity] or 99
    local wb = Tables.RarityWeight[Modules.Clan.Clans[b].rarity] or 99
    return wa ~= wb and wa < wb or a < b
end)

if Modules.SpecPassive and Modules.SpecPassive.Passives then
    for name in pairs(Modules.SpecPassive.Passives) do table.insert(Tables.SpecPassive, name) end
    table.sort(Tables.SpecPassive)
end

for k in pairs(Modules.Quests.Questlines) do table.insert(Tables.QuestlineList, k) end
table.sort(Tables.QuestlineList)

if Modules.Title and Modules.Title.GetSortedTitleIds then
    for _, v in ipairs(Modules.Title:GetSortedTitleIds()) do table.insert(Tables.TitleList, v) end
end

local CombinedTitleList = {}
for _, cat in ipairs(Tables.TitleCategory) do table.insert(CombinedTitleList, cat) end
for _, t   in ipairs(Tables.TitleList)    do table.insert(CombinedTitleList, t)   end

-- ─── Utility functions ────────────────────────────────
local function CommaFormat(n)
    return tostring(n):reverse():gsub("%d%d%d","%1,"):reverse():gsub("^,","")
end
local function Abbreviate(n)
    local ab = {{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}
    for _, v in ipairs(ab) do
        if n >= v[1] then return string.format("%.1f%s", n/v[1], v[2]) end
    end
    return tostring(n)
end

local function GetCharacter()
    local c = Plr.Character
    return (c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid")) and c or nil
end

local function Clean(str) return str:gsub("%s+",""):lower() end

-- ─── Thread manager ───────────────────────────────────
local function Thread(featurePath, featureFunc, isEnabled, ...)
    local parts = featurePath:split(".")
    local cur = Flags
    for i = 1, #parts-1 do
        local p = parts[i]
        if not cur[p] then cur[p] = {} end
        cur = cur[p]
    end
    local key = parts[#parts]
    local active = cur[key]
    if isEnabled then
        if not active or coroutine.status(active) == "dead" then
            cur[key] = task.spawn(featureFunc, ...)
        end
    else
        if active and typeof(active) == "thread" then
            task.cancel(active); cur[key] = nil
        end
    end
end

-- ─── Notify wrapper ───────────────────────────────────
local function Notify(msg, dur)
    Rayfield:Notify({Title="Neko Hub", Content=tostring(msg), Duration=dur or 4})
end

-- ─── Island / NPC helpers ─────────────────────────────
local function GetNearestIsland(targetPos, npcName)
    if npcName and Shared.BossTIMap[npcName] then return Shared.BossTIMap[npcName] end
    local best, minD = "Starter", math.huge
    for name, crystal in pairs(IslandCrystals) do
        if crystal then
            local d = (targetPos - crystal:GetPivot().Position).Magnitude
            if d < minD then minD = d; best = name end
        end
    end
    return best
end

local function HybridMove(targetCF)
    local char = GetCharacter()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local dist = (root.Position - targetCF.Position).Magnitude
    local speed = (Options.TweenSpeed and Options.TweenSpeed.Value) or 180
    local tpThresh = (Options.TargetDistTP and Options.TargetDistTP.Value) or 200

    if dist > tpThresh then
        local oldNC = Toggles.Noclip and Toggles.Noclip.Value or false
        if Toggles.Noclip then Toggles.Noclip.Value = true end
        local tweenTarget = targetCF * CFrame.new(0,0,150)
        local dur = (root.Position - tweenTarget.Position).Magnitude / speed
        local tw = TweenService:Create(root, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame=tweenTarget})
        tw:Play(); tw.Completed:Wait()
        if Toggles.Noclip then Toggles.Noclip.Value = oldNC end
        task.wait(0.1)
    end
    root.CFrame = targetCF
    root.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0)
    task.wait(0.2)
end

local function SafeTeleportToNPC(targetName)
    local char = GetCharacter()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local target = workspace:FindFirstChild(targetName) or PATH.InteractNPCs:FindFirstChild(targetName)
    if not target then
        for _, v in pairs(PATH.InteractNPCs:GetChildren()) do
            if v.Name:find(targetName) then target = v; break end
        end
    end
    if target then
        root.CFrame = target:GetPivot() * CFrame.new(0,3,0)
        root.AssemblyLinearVelocity = Vector3.new(0,0.01,0)
        root.AssemblyAngularVelocity = Vector3.zero
    else
        Notify("NPC not found: " .. targetName, 3)
    end
end

-- ─── Weapon helpers ───────────────────────────────────
local function GetToolTypeFromModule(name)
    local cl = Clean(name)
    for mn, t in pairs(Tables.ManualWeaponClass) do if Clean(mn)==cl then return t end end
    if Modules.WeaponClass and Modules.WeaponClass.Tools then
        for mn, t in pairs(Modules.WeaponClass.Tools) do if Clean(mn)==cl then return t end end
    end
    if name:lower():find("fruit") then return "Power" end
    return "Melee"
end

local function GetWeaponsByType()
    local avail = {}
    local enabled = (Options.SelectedWeaponType and Options.SelectedWeaponType.Value) or {}
    local char = GetCharacter()
    local containers = {Plr.Backpack}
    if char then table.insert(containers, char) end
    for _, cont in ipairs(containers) do
        for _, tool in ipairs(cont:GetChildren()) do
            if tool:IsA("Tool") and enabled[GetToolTypeFromModule(tool.Name)] and not table.find(avail, tool.Name) then
                table.insert(avail, tool.Name)
            end
        end
    end
    return avail
end

local function UpdateWeaponRotation()
    local list = GetWeaponsByType()
    if #list == 0 then Shared.ActiveWeap = ""; return end
    local delay = (Options.SwitchWeaponCD and Options.SwitchWeaponCD.Value) or 4
    if tick() - Shared.LastWRSwitch >= delay then
        Shared.WeapRotationIdx = (Shared.WeapRotationIdx % #list) + 1
        Shared.ActiveWeap = list[Shared.WeapRotationIdx]
        Shared.LastWRSwitch = tick()
    end
    local exists = false
    for _, n in ipairs(list) do if n == Shared.ActiveWeap then exists=true; break end end
    if not exists then Shared.ActiveWeap = list[1] end
end

local function EquipWeapon()
    UpdateWeaponRotation()
    if Shared.ActiveWeap == "" then return end
    local char = GetCharacter()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if char:FindFirstChild(Shared.ActiveWeap) then return end
    local tool = Plr.Backpack:FindFirstChild(Shared.ActiveWeap) or char:FindFirstChild(Shared.ActiveWeap)
    if tool then hum:EquipTool(tool) end
end

-- ─── Haki helpers ─────────────────────────────────────
local function CheckArmHaki()
    if Shared.ArmHaki then return true end
    local char = GetCharacter()
    if char then
        for _, arm in ipairs({"Left Arm","Right Arm","LeftUpperArm","RightUpperArm"}) do
            local p = char:FindFirstChild(arm)
            if p and p:FindFirstChild("Lightning Strike") then Shared.ArmHaki = true; return true end
        end
    end
    return false
end

local function CheckObsHaki()
    local dui = PGui:FindFirstChild("DodgeCounterUI")
    return dui and dui:FindFirstChild("MainFrame") and dui.MainFrame.Visible or false
end

-- ─── Skill ready check ────────────────────────────────
local function IsSkillReady(key)
    local char = GetCharacter()
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return true end
    local mainFrame = PGui:FindFirstChild("CooldownUI") and PGui.CooldownUI:FindFirstChild("MainFrame")
    if not mainFrame then return true end
    local cleanTool = Clean(tool.Name)
    for _, frame in pairs(mainFrame:GetChildren()) do
        if not frame:IsA("Frame") then continue end
        local fn = frame.Name:lower()
        if fn:find("cooldown") then
            local mapped = "none"
            if fn:find("skill 1") or fn:find("_z") then mapped = "Z"
            elseif fn:find("skill 2") or fn:find("_x") then mapped = "X"
            elseif fn:find("skill 3") or fn:find("_c") then mapped = "C"
            elseif fn:find("skill 4") or fn:find("_v") then mapped = "V"
            elseif fn:find("skill 5") or fn:find("_f") then mapped = "F" end
            if mapped == key then
                local lbl = frame:FindFirstChild("WeaponNameAndCooldown", true)
                return lbl and lbl.Text:find("Ready")
            end
        end
    end
    return true
end

-- ─── Quest UI reader ──────────────────────────────────
local function GetCurrentQuestUI()
    local ok, result = pcall(function()
        local holder = PGui.QuestUI.Quest.Quest.Holder.Content
        local info = holder.QuestInfo
        return {
            Title       = info.QuestTitle.QuestTitle.Text,
            Description = info.QuestDescription.Text,
            SwitchVisible = holder.QuestSwitchButton.Visible,
            SwitchBtn   = holder.QuestSwitchButton,
            IsVisible   = PGui.QuestUI.Quest.Visible,
        }
    end)
    return ok and result or {Title="",Description="",SwitchVisible=false,IsVisible=false}
end

-- ─── Boss remotes ─────────────────────────────────────
local function GetRemoteBossArg(name)
    local m = {["strongestinhistory"]="StrongestHistory",["strongestoftoday"]="StrongestToday",
               ["strongesthistory"]="StrongestHistory",["strongesttoday"]="StrongestToday"}
    return m[name:lower()] or name
end

local function FireBossRemote(bossName, diff)
    local lower = bossName:lower():gsub("%s+","")
    table.clear(Shared.AltDamage)
    pcall(function()
        if lower:find("rimuru") then Remotes.RimuruBoss:FireServer(diff)
        elseif lower:find("anos") then Remotes.AnosBoss:FireServer("Anos", diff)
        elseif lower:find("trueaizen") then if Remotes.TrueAizenBoss then Remotes.TrueAizenBoss:FireServer(diff) end
        elseif lower:find("strongest") then Remotes.JJKSummonBoss:FireServer(GetRemoteBossArg(bossName), diff)
        elseif lower:find("atomic") then Remotes.AtomicBoss:FireServer(diff)
        else
            local id = SummonMap[bossName] or (bossName:gsub("%s+","") .. "Boss")
            for displayName, internalId in pairs(SummonMap) do
                if displayName:lower():gsub("%s+","") == lower then id = internalId; break end
            end
            Remotes.SummonBoss:FireServer(id, diff)
        end
    end)
end

local function IsStrictBossMatch(npcName, targetDisplay)
    local n = npcName:lower():gsub("%s+","")
    local t = targetDisplay:lower():gsub("%s+","")
    if n:find("true") and not t:find("true") then return false end
    if t:find("strongest") then
        local era = t:find("history") and "history" or "today"
        return n:find("strongest") and n:find(era)
    end
    return n:find(t)
end

-- ─── Remote event listeners ───────────────────────────
if Remotes.UpInventory then
    Remotes.UpInventory.OnClientEvent:Connect(function(category, data)
        Shared.InventorySynced = true
        if category == "Items" then
            Shared.Cached.Inv = data or {}
            table.clear(Tables.OwnedItem)
            for _, item in pairs(data) do
                if not table.find(Tables.OwnedItem, item.name) then table.insert(Tables.OwnedItem, item.name) end
            end
            table.sort(Tables.OwnedItem)
        elseif category == "Runes" then
            table.clear(Tables.RuneList); table.insert(Tables.RuneList, "None")
            for name in pairs(data) do table.insert(Tables.RuneList, name) end
            table.sort(Tables.RuneList)
        elseif category == "Accessories" then
            table.clear(Shared.Cached.Accessories)
            if type(data) == "table" then
                for _, acc in ipairs(data) do
                    if acc.name then Shared.Cached.Accessories[acc.name] = acc.quantity end
                end
            end
            table.clear(Tables.OwnedAccessory)
            local proc = {}
            for _, item in ipairs(data) do
                if (item.enchantLevel or 0) < 10 and not proc[item.name] then
                    table.insert(Tables.OwnedAccessory, item.name); proc[item.name] = true
                end
            end
            table.sort(Tables.OwnedAccessory)
        elseif category == "Sword" or category == "Melee" then
            Shared.Cached.RawWeapCache[category] = data or {}
            table.clear(Tables.OwnedWeapon); table.clear(Tables.AllOwnedWeapons)
            local proc = {}; local allProc = {}
            for _, cat in pairs({"Sword","Melee"}) do
                for _, item in ipairs(Shared.Cached.RawWeapCache[cat]) do
                    if (item.blessingLevel or 0) < 10 and not proc[item.name] then
                        table.insert(Tables.OwnedWeapon, item.name); proc[item.name] = true
                    end
                    if not allProc[item.name] then
                        table.insert(Tables.AllOwnedWeapons, item.name); allProc[item.name] = true
                    end
                end
            end
            table.sort(Tables.OwnedWeapon); table.sort(Tables.AllOwnedWeapons)
        end
    end)
end

if Remotes.NotifyItemDrop then
    Remotes.NotifyItemDrop.OnClientEvent:Connect(function(data)
        if not data or type(data) ~= "table" or not data.name then return end
        NewItemsBuffer[data.name] = (NewItemsBuffer[data.name] or 0) + (data.quantity or 1)
    end)
end

if Remotes.StockUpdate then
    Remotes.StockUpdate.OnClientEvent:Connect(function(itemName, stockLeft)
        Shared.CurrentStock[itemName] = tonumber(stockLeft)
        if stockLeft == 0 then Notify("[MERCHANT] Bought: " .. tostring(itemName), 2) end
    end)
end

if Remotes.UpSkillTree then
    Remotes.UpSkillTree.OnClientEvent:Connect(function(data)
        if data then Shared.SkillTree.Nodes = data.Nodes or {}; Shared.SkillTree.SkillPoints = data.SkillPoints or 0 end
    end)
end

if Remotes.HakiStateUpdate then
    Remotes.HakiStateUpdate.OnClientEvent:Connect(function(a1, a2)
        if a1 == false then Shared.ArmHaki = false; return end
        if a1 == Plr then Shared.ArmHaki = a2 end
    end)
end

if Remotes.BossUIUpdate then
    Remotes.BossUIUpdate.OnClientEvent:Connect(function(mode, data)
        if mode == "DamageStats" and data and data.stats then
            for _, info in pairs(data.stats) do
                if info.player and info.player:IsA("Player") then
                    Shared.AltDamage[info.player.Name] = tonumber(info.percent) or 0
                end
            end
        end
    end)
end

if Remotes.TitleSync then
    Remotes.TitleSync.OnClientEvent:Connect(function(data)
        if data and data.unlocked then Tables.UnlockedTitle = data.unlocked end
    end)
end

if Remotes.TradeUpdated then
    Remotes.TradeUpdated.OnClientEvent:Connect(function(data) Shared.TradeState = data end)
end

PATH.Mobs.ChildRemoved:Connect(function(child)
    if child:IsA("Model") and child.Name:lower():find("boss") then
        table.clear(Shared.AltDamage); Shared.AltActive = false
    end
end)

-- ─── Pity counter ─────────────────────────────────────
local function GetCurrentPity()
    local pityLabel = PGui.BossUI and PGui.BossUI:FindFirstChild("MainFrame",true)
    if pityLabel then
        local pl = pityLabel:FindFirstChild("Pity",true)
        if pl then
            local cur, max = pl.Text:match("Pity: (%d+)/(%d+)")
            return tonumber(cur) or 0, tonumber(max) or 25
        end
    end
    return 0, 25
end

-- ─── Misc toggleable features ─────────────────────────
local function FuncTPW()
    while Toggles.TPW and Toggles.TPW.Value do
        local dt = RunService.Heartbeat:Wait()
        local char = GetCharacter()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if char and hum and hum.Health > 0 and hum.MoveDirection.Magnitude > 0 then
            local speed = (Options.TPWValue and Options.TPWValue.Value) or 20
            char:TranslateBy(hum.MoveDirection * speed * dt * 10)
        end
    end
end

local function FuncNoclip()
    while Toggles.Noclip and Toggles.Noclip.Value do
        RunService.Stepped:Wait()
        local char = GetCharacter()
        if char then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end
end

local function Func_AntiKnockback()
    if type(Connections.Knockback) == "table" then
        for _, c in pairs(Connections.Knockback) do if c then c:Disconnect() end end
        table.clear(Connections.Knockback)
    else Connections.Knockback = {} end

    local function ApplyAKB(character)
        if not character then return end
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if root then
            local conn = root.ChildAdded:Connect(function(child)
                if not (Toggles.AntiKnockback and Toggles.AntiKnockback.Value) then return end
                if child:IsA("BodyVelocity") and child.MaxForce == Vector3.new(40000,40000,40000) then child:Destroy() end
            end)
            table.insert(Connections.Knockback, conn)
        end
    end

    if Plr.Character then ApplyAKB(Plr.Character) end
    local charConn = Plr.CharacterAdded:Connect(ApplyAKB)
    table.insert(Connections.Knockback, charConn)
    repeat task.wait(1) until not (Toggles.AntiKnockback and Toggles.AntiKnockback.Value)
    for _, c in pairs(Connections.Knockback) do if c then c:Disconnect() end end
    table.clear(Connections.Knockback)
end

local function DisableIdled()
    pcall(function()
        local cons = getconnections or get_signal_cons
        if cons then
            for _, v in pairs(cons(Plr.Idled)) do
                if v.Disable then v:Disable() elseif v.Disconnect then v:Disconnect() end
            end
        end
    end)
end

local function Func_AutoReconnect()
    if Connections.Reconnect then Connections.Reconnect:Disconnect() end
    Connections.Reconnect = GuiService.ErrorMessageChanged:Connect(function()
        if not (Toggles.AutoReconnect and Toggles.AutoReconnect.Value) then return end
        task.delay(2, function()
            pcall(function()
                local promptGui = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui")
                if promptGui then
                    local errPr = promptGui.promptOverlay:FindFirstChild("ErrorPrompt")
                    if errPr and errPr.Visible then
                        task.wait(5)
                        TeleportService:Teleport(game.PlaceId, Plr)
                    end
                end
            end)
        end)
    end)
end

local function ApplyFPSBoost()
    pcall(function()
        Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; Lighting.Brightness = 1
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("PostProcessEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") then
                v.Enabled = false
            end
        end
        task.spawn(function()
            for i, v in pairs(workspace:GetDescendants()) do
                if Toggles.FPSBoost and not Toggles.FPSBoost.Value then break end
                pcall(function()
                    if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic; v.CastShadow = false
                    elseif v:IsA("Decal") or v:IsA("Texture") then v:Destroy()
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled = false end
                end)
                if i % 500 == 0 then task.wait() end
            end
        end)
    end)
end

local function PanicStop()
    Shared.Farm = false; Shared.AltActive = false; Shared.GlobalPrio = "FARM"
    Shared.Target = nil; Shared.MovingIsland = false
    for _, t in pairs(Toggles) do if t.SetValue then t:SetValue(false) end end
    local char = GetCharacter(); local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
    task.delay(0.5, function() Shared.Farm = true end)
    Notify("Stopped.", 5)
end

-- ─── Switch state (Title/Rune/Build) ──────────────────
local function GetBestOwnedTitle(category)
    local statMap = {["Best EXP"]="XPPercent",["Best Money & Gem"]="MoneyPercent",["Best Luck"]="LuckPercent",["Best DMG"]="DamagePercent"}
    local targetStat = statMap[category]; if not targetStat then return nil end
    local bestId, highest = nil, -1
    for _, titleId in ipairs(Tables.UnlockedTitle) do
        local data = Modules.Title.Titles and Modules.Title.Titles[titleId]
        if data and data.statBonuses and data.statBonuses[targetStat] then
            local val = data.statBonuses[targetStat]
            if val > highest then highest = val; bestId = titleId end
        end
    end
    return bestId
end

local function UpdateSwitchState(target, farmType)
    if Shared.GlobalPrio == "COMBO" then return end
    local types = {
        {id="Title",  remote=Remotes.EquipTitle,   method=function(v) return {v} end},
        {id="Rune",   remote=Remotes.EquipRune,    method=function(v) return {"Equip",v} end},
        {id="Build",  remote=Remotes.LoadoutLoad,  method=function(v) return {tonumber(v)} end},
    }
    for _, sw in ipairs(types) do
        local tog = Toggles["Auto"..sw.id]
        if not (tog and tog.Value) then continue end
        if sw.id == "Build" and tick() - Shared.LastBuildSwitch < 3.1 then continue end
        local threshold = (Options[sw.id.."_BossHPAmt"] and Options[sw.id.."_BossHPAmt"].Value) or 15
        local isLow = false
        if farmType == "Boss" and target then
            local hum = target:FindFirstChildOfClass("Humanoid")
            if hum then isLow = (hum.Health/hum.MaxHealth)*100 <= threshold end
        end
        local toEquip = ""
        if farmType == "None"  then toEquip = (Options["Default"..sw.id] and Options["Default"..sw.id].Value) or ""
        elseif farmType == "Mob" then toEquip = (Options[sw.id.."_Mob"] and Options[sw.id.."_Mob"].Value) or ""
        elseif farmType == "Boss" then
            toEquip = isLow
                and ((Options[sw.id.."_BossHP"] and Options[sw.id.."_BossHP"].Value) or "")
                or  ((Options[sw.id.."_Boss"]   and Options[sw.id.."_Boss"].Value)   or "")
        end
        if not toEquip or toEquip == "" or toEquip == "None" then continue end
        local finalVal = toEquip
        if sw.id == "Title" and toEquip:find("Best ") then
            local best = GetBestOwnedTitle(toEquip); if best then finalVal = best else continue end
        end
        if finalVal ~= Shared.LastSwitch[sw.id] then
            local args = sw.method(finalVal)
            pcall(function() sw.remote:FireServer(table.unpack(args)) end)
            Shared.LastSwitch[sw.id] = finalVal
            if sw.id == "Build" then Shared.LastBuildSwitch = tick() end
        end
    end
end

-- ─── Merchant logic ───────────────────────────────────
local function OpenMerchantInterface()
    if isXeno then
        local npc = PATH.InteractNPCs:FindFirstChild("MerchantNPC")
        local prompt = npc and npc:FindFirstChild("HumanoidRootPart") and npc.HumanoidRootPart:FindFirstChild("MerchantPrompt")
        if prompt then
            local char = GetCharacter(); local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0,0,3); task.wait(0.2)
                if Support.Proximity then fireproximityprompt(prompt)
                else prompt:InputHoldBegin(); task.wait(prompt.HoldDuration+0.1); prompt:InputHoldEnd() end
                task.wait(0.5)
            end
        end
    else
        fire_event(Remotes.OpenMerchant and Remotes.OpenMerchant.OnClientEvent)
    end
end

-- ─── Race / Clan / Trait sync ─────────────────────────
local function SyncTraitAutoSkip()
    if not (Toggles.AutoTrait and Toggles.AutoTrait.Value) then return end
    pcall(function()
        local sel = (Options.SelectedTrait and Options.SelectedTrait.Value) or {}
        local rarH = {["Epic"]=1,["Legendary"]=2,["Mythical"]=3,["Secret"]=4}
        local lowest = 99
        for name, en in pairs(sel) do
            if en then
                local d = Modules.Trait.Traits[name]; if d then
                    local v = rarH[d.Rarity] or 0
                    if v > 0 and v < lowest then lowest = v end
                end
            end
        end
        if lowest == 99 then return end
        Remotes.TraitAutoSkip:FireServer({["Epic"]=1<lowest,["Legendary"]=2<lowest,["Mythical"]=3<lowest,["Secret"]=4<lowest})
    end)
end

local function SyncRaceSettings()
    if not (Toggles.AutoRace and Toggles.AutoRace.Value) then return end
    pcall(function()
        local sel = (Options.SelectedRace and Options.SelectedRace.Value) or {}
        for name, data in pairs(Modules.Race.Races) do
            local rarity = data.rarity or data.Rarity
            if rarity == "Mythical" then
                local shouldSkip = not sel[name]
                if Shared.Settings["SkipRace_"..name] ~= shouldSkip then
                    Remotes.SettingsToggle:FireServer("SkipRace_"..name, shouldSkip)
                end
            end
        end
    end)
end

local function SyncClanSettings()
    if not (Toggles.AutoClan and Toggles.AutoClan.Value) then return end
    pcall(function()
        local sel = (Options.SelectedClan and Options.SelectedClan.Value) or {}
        for name, data in pairs(Modules.Clan.Clans) do
            local rarity = data.rarity or data.Rarity
            if rarity == "Legendary" then
                local shouldSkip = not sel[name]
                if Shared.Settings["SkipClan_"..name] ~= shouldSkip then
                    Remotes.SettingsToggle:FireServer("SkipClan_"..name, shouldSkip)
                end
            end
        end
    end)
end

-- ─── Upgrade loop (Enchant / Blessing) ────────────────
local function AutoUpgradeLoop(mode)
    local toggle    = Toggles["Auto"..mode]
    local allToggle = Toggles["Auto"..mode.."All"]
    local remote    = (mode == "Enchant") and Remotes.Enchant or Remotes.Blessing
    local sourceT   = (mode == "Enchant") and Tables.OwnedAccessory or Tables.OwnedWeapon
    while (toggle and toggle.Value) or (allToggle and allToggle.Value) do
        local sel = (Options["Selected"..mode] and Options["Selected"..mode].Value) or {}
        local workDone = false
        for _, name in ipairs(sourceT) do
            if Shared.UpBlacklist[name] then continue end
            local isSel = (allToggle and allToggle.Value) or sel[name] or table.find(sel, name)
            if isSel then
                workDone = true
                pcall(function() remote:FireServer(name) end)
                task.wait(1.5); break
            end
        end
        if not workDone then
            Notify("Stopping upgrade..", 5)
            if toggle    then toggle.Value    = false end
            if allToggle then allToggle.Value = false end
            break
        end
        task.wait(0.1)
    end
end

-- ─── Summon handler ───────────────────────────────────
local function HandleSummons()
    if Shared.MerchantBusy then return end
    local function MatchName(a,b)
        if not a or not b then return false end
        return a:lower():gsub("%s+","") == b:lower():gsub("%s+","")
    end
    local function IsSummonable(name)
        local cn = name:lower():gsub("%s+","")
        for _, b in ipairs(Tables.SummonList) do if MatchName(b, cn) then return true end end
        for _, b in ipairs(Tables.OtherSummonList) do if MatchName(b, cn) then return true end end
        return false
    end

    if Toggles.PityBossFarm and Toggles.PityBossFarm.Value then
        local cur, max = GetCurrentPity()
        local buildOpts = (Options.SelectedBuildPity and Options.SelectedBuildPity.Value) or {}
        local useName   = Options.SelectedUsePity and Options.SelectedUsePity.Value
        if useName and next(buildOpts) then
            local isUseTurn = cur >= (max-1)
            if isUseTurn then
                local found = false
                for _, v in pairs(PATH.Mobs:GetChildren()) do
                    if MatchName(v.Name, useName) then found = true; break end
                end
                if not found and IsSummonable(useName) then
                    FireBossRemote(useName, (Options.SelectedPityDiff and Options.SelectedPityDiff.Value) or "Normal"); task.wait(0.5); return
                end
            else
                local anySpawned = false
                for bossName, en in pairs(buildOpts) do
                    if en then
                        for _, v in pairs(PATH.Mobs:GetChildren()) do
                            if MatchName(v.Name, bossName) then anySpawned = true; break end
                        end
                    end
                    if anySpawned then break end
                end
                if not anySpawned then
                    for bossName, en in pairs(buildOpts) do
                        if en and IsSummonable(bossName) then FireBossRemote(bossName, "Normal"); task.wait(0.5); return end
                    end
                end
            end
        end
    end

    if Toggles.AutoOtherSummon and Toggles.AutoOtherSummon.Value then
        local sel  = Options.SelectedOtherSummon and Options.SelectedOtherSummon.Value
        local diff = (Options.SelectedOtherSummonDiff and Options.SelectedOtherSummonDiff.Value) or "Normal"
        if sel then
            local found = false
            for _, v in pairs(PATH.Mobs:GetChildren()) do
                if v.Name:lower():find(sel:lower():gsub("%s+","")) then found = true; break end
            end
            if not found then FireBossRemote(sel, diff); task.wait(0.5) end
        end
    end

    if Toggles.AutoSummon and Toggles.AutoSummon.Value then
        local sel = Options.SelectedSummon and Options.SelectedSummon.Value
        if sel then
            local found = false
            for _, v in pairs(PATH.Mobs:GetChildren()) do
                if IsStrictBossMatch(v.Name, sel) then found = true; break end
            end
            if not found then FireBossRemote(sel, (Options.SelectedSummonDiff and Options.SelectedSummonDiff.Value) or "Normal"); task.wait(0.5) end
        end
    end
end

-- ─── Auto kick / safety ───────────────────────────────
local TargetGroupId = 1002185259
local BannedRanks   = {255, 254, 175, 150}

local function SendSafetyWebhook(target, reason)
    local url = Options.WebhookURL and Options.WebhookURL.Value or ""
    if url == "" or not url:find("discord.com/api/webhooks/") then return end
    task.spawn(function()
        pcall(function()
            request({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},
                Body=HttpService:JSONEncode({embeds={{
                    title="⚠️ Auto Kick",
                    description="Player detected.",
                    color=16711680,
                    fields={{name="Username",value="`"..target.Name.."`",inline=true},{name="Type",value=reason,inline=true}},
                    footer={text="NekoHub · "..os.date("%x %X")}
                }}}})
            })
        end)
    end)
end

local function CheckPlayerForSafety(target)
    if not (Toggles.AutoKick and Toggles.AutoKick.Value) then return end
    if target == Plr then return end
    local kickTypes = (Options.SelectedKickType and Options.SelectedKickType.Value) or {}
    if kickTypes["Player Join"] then
        SendSafetyWebhook(target, "Player Join"); task.wait(0.5)
        Plr:Kick("\n[NekoHub]\nReason: Player joined (" .. target.Name .. ")")
        return
    end
    if kickTypes["Mod"] then
        local ok, rank = pcall(function() return target:GetRankInGroup(TargetGroupId) end)
        if ok and table.find(BannedRanks, rank) then
            SendSafetyWebhook(target, "Moderator (Rank:"..tostring(rank)..")"); task.wait(0.5)
            Plr:Kick("\n[NekoHub]\nReason: Moderator detected (" .. target.Name .. ")")
        end
    end
end

-- ─── NPC list population ──────────────────────────────
local function PopulateNPCLists()
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name:match("^QuestNPC%d+$") and not table.find(Tables.NPC_QuestList, child.Name) then
            table.insert(Tables.NPC_QuestList, child.Name)
        end
    end
    for _, child in ipairs(PATH.InteractNPCs:GetChildren()) do
        if child.Name:match("^QuestNPC%d+$") and not table.find(Tables.NPC_QuestList, child.Name) then
            table.insert(Tables.NPC_QuestList, child.Name)
        end
    end
    table.sort(Tables.NPC_QuestList, function(a,b)
        local na = tonumber(a:match("%d+$")) or 0
        local nb = tonumber(b:match("%d+$")) or 0
        return na ~= nb and na < nb or a < b
    end)
    for _, v in pairs(PATH.InteractNPCs:GetChildren()) do
        local name = v.Name
        if (name:find("Moveset") or name:find("Buyer")) and not name:find("Observation") then
            table.insert(Tables.NPC_MovesetList, name)
        end
        if (name:find("Mastery") or name:find("Questline") or name:find("Craft"))
            and not (name:find("Grail") or name:find("Slime")) then
            table.insert(Tables.NPC_MasteryList, name)
        end
    end
    table.sort(Tables.NPC_MovesetList); table.sort(Tables.NPC_MasteryList)
end
PopulateNPCLists()

local function UpdateNPCLists()
    local special = {"ThiefBoss","MonkeyBoss","DesertBoss","SnowBoss","PandaMiniBoss"}
    local cur = {}; for _, n in pairs(Tables.MobList) do cur[n] = true end
    for _, v in pairs(PATH.Mobs:GetChildren()) do
        local clean = v.Name:gsub("%d+$","")
        local isSp = table.find(special, clean)
        if (isSp or not clean:find("Boss")) and not cur[clean] then
            table.insert(Tables.MobList, clean); cur[clean] = true
            local minD, closestI = math.huge, "Unknown"
            for iName, crystal in pairs(IslandCrystals) do
                if crystal then
                    local d = (v:GetPivot().Position - crystal:GetPivot().Position).Magnitude
                    if d < minD then minD=d; closestI=iName end
                end
            end
            Tables.MobToIsland[clean] = closestI
        end
    end
    if Options.SelectedMob then Options.SelectedMob:SetValues(Tables.MobList) end
end

-- ─── MAIN FARM LOOP ───────────────────────────────────
local PriorityTasks = {"Boss","Pity Boss","Summon [Other]","Summon","Level Farm","All Mob Farm","Mob","Merchant","Alt Help"}

local function FuncMainFarm()
    while Toggles.AutoFarm and Toggles.AutoFarm.Value do
        UpdateNPCLists()
        task.wait(0.1)

        local char = GetCharacter()
        if not char or not Shared.Farm then task.wait(1); continue end

        local hum  = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then task.wait(1); continue end

        -- Anti-idle
        DisableIdled()

        -- Auto Haki
        if Toggles.AutoArmHaki and Toggles.AutoArmHaki.Value and not CheckArmHaki() then
            pcall(function() Remotes.ArmHaki:FireServer() end)
            task.wait(0.3)
        end
        if Toggles.AutoObsHaki and Toggles.AutoObsHaki.Value and not CheckObsHaki() then
            pcall(function() Remotes.ObserHaki:FireServer() end)
            task.wait(0.3)
        end

        -- Equip weapon
        if Toggles.WeaponRotation and Toggles.WeaponRotation.Value then EquipWeapon() end

        -- Skills
        local skillKeys = {"Z","X","C","V","F"}
        if Toggles.AutoSkill and Toggles.AutoSkill.Value then
            for _, k in ipairs(skillKeys) do
                if IsSkillReady(k) then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        pcall(function() Remotes.UseSkill:FireServer(k) end)
                        task.wait(0.15)
                    end
                end
            end
        end

        -- Find target
        local priority = Options.TaskPriority and Options.TaskPriority.Value or "Mob"
        local target = nil

        if (priority == "Boss" or priority == "Pity Boss") and (Toggles.AutoBossFarm and Toggles.AutoBossFarm.Value or Toggles.PityBossFarm and Toggles.PityBossFarm.Value) then
            HandleSummons()
            for _, v in pairs(PATH.Mobs:GetChildren()) do
                if v.Name:lower():find("boss") then
                    local bossHum = v:FindFirstChildOfClass("Humanoid")
                    if bossHum and bossHum.Health > 0 then target = v; break end
                end
            end
        end

        if not target and (Toggles.AutoMobFarm and Toggles.AutoMobFarm.Value) then
            local selMob = Options.SelectedMob and Options.SelectedMob.Value
            if selMob and selMob ~= "" then
                for _, v in pairs(PATH.Mobs:GetChildren()) do
                    local cleanName = v.Name:gsub("%d+$","")
                    if cleanName == selMob then
                        local mobHum = v:FindFirstChildOfClass("Humanoid")
                        if mobHum and mobHum.Health > 0 then target = v; break end
                    end
                end
            else
                for _, v in pairs(PATH.Mobs:GetChildren()) do
                    local mobHum = v:FindFirstChildOfClass("Humanoid")
                    if mobHum and mobHum.Health > 0 then target = v; break end
                end
            end
        end

        if not target then
            -- TP to island if no mob found
            if Toggles.AutoMobFarm and Toggles.AutoMobFarm.Value then
                local selMob = Options.SelectedMob and Options.SelectedMob.Value
                if selMob and Tables.MobToIsland[selMob] then
                    pcall(function() Remotes.TP_Portal:FireServer(Tables.MobToIsland[selMob]) end)
                    task.wait(2)
                end
            end
            task.wait(0.5); continue
        end

        Shared.Target = target
        local targetHum  = target:FindFirstChildOfClass("Humanoid")
        local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart

        if not targetRoot or not targetHum or targetHum.Health <= 0 then
            Shared.Target = nil; task.wait(0.1); continue
        end

        -- Teleport to target
        local attackRange = (Options.AttackRange and Options.AttackRange.Value) or 15
        local distToTarget = (root.Position - targetRoot.Position).Magnitude

        if distToTarget > attackRange then
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 2, -(attackRange * 0.5))
            task.wait(0.15)
        end

        -- Face target
        root.CFrame = CFrame.new(root.Position, Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))

        -- M1
        if Toggles.AutoM1 and Toggles.AutoM1.Value then
            if tick() - Shared.LastM1 >= 0.35 then
                pcall(function() Remotes.M1:FireServer(target, targetRoot.CFrame) end)
                Shared.LastM1 = tick()
            end
        end

        -- Switch title/rune/build
        local isBoss = target.Name:lower():find("boss")
        UpdateSwitchState(target, isBoss and "Boss" or "Mob")

        -- Auto Quest
        if Toggles.AutoQuest and Toggles.AutoQuest.Value then
            local qUI = GetCurrentQuestUI()
            if not qUI.IsVisible then
                local questNPC = Options.SelectedQuestNPC and Options.SelectedQuestNPC.Value
                if questNPC and questNPC ~= "" then
                    SafeTeleportToNPC(questNPC); task.wait(0.5)
                    pcall(function() Remotes.QuestAccept:FireServer(questNPC) end)
                    task.wait(0.3)
                end
            end
        end

        task.wait(0.05)
    end
    Shared.Target = nil
end

-- ─── Merchant farm ────────────────────────────────────
local function FuncMerchantFarm()
    while Toggles.AutoMerchant and Toggles.AutoMerchant.Value do
        local selectedItems = (Options.SelectedMerchantItems and Options.SelectedMerchantItems.Value) or {}
        local hasItems = next(selectedItems) ~= nil

        if hasItems then
            OpenMerchantInterface(); task.wait(0.8)
            for itemName, enabled in pairs(selectedItems) do
                if enabled then
                    local stock = Shared.CurrentStock[itemName]
                    if stock == nil or stock > 0 then
                        pcall(function() Remotes.MerchantBuy:FireServer(itemName) end)
                        task.wait(0.4)
                    end
                end
            end
        end
        task.wait(5)
    end
end

-- ─── Auto codes ───────────────────────────────────────
local function FuncAutoCode(code)
    pcall(function() Remotes.UseCode:FireServer(code) end)
end

-- ─── Artifact management ──────────────────────────────
local function EvaluateArtifact(uuid, data)
    local function GetFilterStatus(filter, value)
        if not filter or next(filter) == nil then return nil end
        return filter[value] == true
    end
    local function GetMatches(d, ssFilter)
        local c = 0
        for _, sub in pairs(d.Substats or {}) do if ssFilter[sub.Stat] then c = c + 1 end end
        return c
    end

    local actions = {lock=false, delete=false, upgrade=false}

    if Toggles.ArtifactUpgrade and Toggles.ArtifactUpgrade.Value then
        local limit = (Options.UpgradeLimit and Options.UpgradeLimit.Value) or 20
        local upMS  = (Options.Up_MS and Options.Up_MS.Value) or {}
        if data.Level < limit then
            if not next(upMS) or upMS[data.MainStat.Stat] then actions.upgrade = true end
        end
    end

    local lockMinSS = (Options.Lock_MinSS and Options.Lock_MinSS.Value) or 2
    if Toggles.ArtifactLock and Toggles.ArtifactLock.Value and not data.Locked and data.Level >= lockMinSS * 3 then
        local lkMS  = (Options.Lock_MS   and Options.Lock_MS.Value)   or {}
        local lkType= (Options.Lock_Type and Options.Lock_Type.Value) or {}
        local lkSet = (Options.Lock_Set  and Options.Lock_Set.Value)  or {}
        local lkSS  = (Options.Lock_SS   and Options.Lock_SS.Value)   or {}
        local msOk  = not next(lkMS)   or lkMS[data.MainStat.Stat]
        local tyOk  = not next(lkType) or lkType[data.Category]
        local setOk = not next(lkSet)  or lkSet[data.Set]
        if msOk and tyOk and setOk and GetMatches(data, lkSS) >= lockMinSS then
            actions.lock = true
        end
    end

    if not data.Locked and not actions.lock then
        if Toggles.ArtifactDelete and Toggles.ArtifactDelete.Value then
            local delType = (Options.Del_Type and Options.Del_Type.Value) or {}
            local delSet  = (Options.Del_Set  and Options.Del_Set.Value)  or {}
            local delSS   = (Options.Del_SS   and Options.Del_SS.Value)   or {}
            local minDel  = (Options.Del_MinSS and Options.Del_MinSS.Value) or 0
            local isTarget = (not next(delType) or delType[data.Category]) and (not next(delSet) or delSet[data.Set])
            if isTarget and GetMatches(data, delSS) >= minDel then actions.delete = true end
        elseif Toggles.DeleteUnlock and Toggles.DeleteUnlock.Value then
            actions.delete = true
        end
    end
    return actions
end

local function RunArtifactManager()
    local toDelete = {}; local toUpgrade = {}; local toLock = {}
    for uuid, data in pairs(Shared.ArtifactSession.Inventory) do
        local actions = EvaluateArtifact(uuid, data)
        if actions.delete then table.insert(toDelete, uuid)
        elseif actions.lock then table.insert(toLock, uuid)
        elseif actions.upgrade then table.insert(toUpgrade, uuid) end
    end
    if #toLock > 0 then
        for _, uuid in ipairs(toLock) do pcall(function() Remotes.ArtifactLock:FireServer(uuid) end); task.wait(0.1) end
    end
    if #toUpgrade > 0 then
        pcall(function() Remotes.MassUpgrade:FireServer(toUpgrade) end); task.wait(0.5)
    end
    if #toDelete > 0 then
        pcall(function() Remotes.MassDelete:FireServer(toDelete) end); task.wait(0.5)
    end
end

-- ─── Webhook ──────────────────────────────────────────
local function PostToWebhook()
    if not Support.Webhook then return end
    local url = Options.WebhookURL and Options.WebhookURL.Value or ""
    if url == "" or not url:find("discord.com/api/webhooks/") then return end
    local data = Plr.Data
    local ls = Plr:FindFirstChild("leaderstats")
    local bounty = ls and ls:FindFirstChild("Bounty") and ls.Bounty.Value or 0
    local gainLv = data.Level.Value - StartStats.Level
    local desc = string.format(
        "**Neko Hub** · Sailor Piece\n**Player:** ||%s||\n**Level:** %s (+%d)\n**Money:** %s | **Gems:** %s\n**Session:** %s",
        Plr.Name,
        CommaFormat(data.Level.Value), gainLv,
        Abbreviate(data.Money.Value), Abbreviate(data.Gems.Value),
        GetSessionTime()
    )
    task.spawn(function()
        pcall(function()
            request({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},
                Body=HttpService:JSONEncode({embeds={{description=desc,color=0xff69b4,
                    footer={text="NekoHub · "..os.date("%x %X")}}}})
            })
        end)
    end)
end

-- ═══════════════════════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name            = "Neko Hub",
    Icon            = 0,
    LoadingTitle    = "Neko Hub",
    LoadingSubtitle = "Sailor Piece · All Functions",
    Theme           = "Default",
    ConfigurationSaving = {Enabled=true, FileName="NekoHub_SailorPiece"},
    KeySystem       = false,
})

-- ── Helper to register toggle ─────────────────────────
local function RT(tab, id, label, default, callback)
    MakeToggle(id, default)
    tab:CreateToggle({Name=label, CurrentValue=default, Flag=id,
        Callback=function(v)
            Toggles[id].Value = v
            if callback then callback(v) end
        end})
    return Toggles[id]
end

-- Helper to register option (slider/dropdown/input)
local function RS_Opt(id, default) MakeOption(id, default); return Options[id] end

-- ════ TAB: FARM ═══════════════════════════════════════
local FarmTab = Window:CreateTab("Farm", 4483362458)

FarmTab:CreateSection("Auto Farm")
RT(FarmTab, "AutoFarm", "Auto Farm (All Modes)", false, function(v)
    Thread("Farm.Main", FuncMainFarm, v)
end)
RT(FarmTab, "AutoMobFarm",  "Auto Mob Farm",  false)
RT(FarmTab, "AutoBossFarm", "Auto Boss Farm", false)
RT(FarmTab, "AutoM1",       "Auto M1 Attack", true)
RT(FarmTab, "AutoSkill",    "Auto Skill (Z/X/C/V/F)", true)
RT(FarmTab, "WeaponRotation","Weapon Rotation", false)

FarmTab:CreateSection("Targets")
RS_Opt("SelectedMob", "")
FarmTab:CreateDropdown({Name="Selected Mob", Options=Tables.MobList, CurrentOption={}, Flag="SelectedMob",
    Callback=function(v) Options.SelectedMob.Value = v[1] or "" end})

RS_Opt("AttackRange", 15)
FarmTab:CreateSlider({Name="Attack Range", Range={5,60}, Increment=1, CurrentValue=15, Flag="AttackRange",
    Callback=function(v) Options.AttackRange.Value = v end})

FarmTab:CreateSection("Quest")
RT(FarmTab, "AutoQuest", "Auto Quest", false)
RS_Opt("SelectedQuestNPC", "")
FarmTab:CreateDropdown({Name="Quest NPC", Options=Tables.NPC_QuestList, CurrentOption={}, Flag="SelectedQuestNPC",
    Callback=function(v) Options.SelectedQuestNPC.Value = v[1] or "" end})

FarmTab:CreateSection("Movement")
RT(FarmTab, "TPW", "TP Walk (Speed Boost)", false, function(v) Thread("Farm.TPW", FuncTPW, v) end)
RS_Opt("TPWValue", 20)
FarmTab:CreateSlider({Name="TP Walk Speed", Range={5,100}, Increment=1, CurrentValue=20, Flag="TPWValue",
    Callback=function(v) Options.TPWValue.Value = v end})

RT(FarmTab, "Noclip", "Noclip", false, function(v) Thread("Farm.Noclip", FuncNoclip, v) end)

RS_Opt("TweenSpeed", 180)
FarmTab:CreateSlider({Name="Tween Speed", Range={50,600}, Increment=10, CurrentValue=180, Flag="TweenSpeed",
    Callback=function(v) Options.TweenSpeed.Value = v end})
RS_Opt("TargetDistTP", 200)
FarmTab:CreateSlider({Name="TP Distance Threshold", Range={50,500}, Increment=10, CurrentValue=200, Flag="TargetDistTP",
    Callback=function(v) Options.TargetDistTP.Value = v end})

FarmTab:CreateSection("Teleport")
for _, island in ipairs(Tables.IslandList) do
    local islandName = island
    FarmTab:CreateButton({Name="TP → "..island, Callback=function()
        pcall(function() Remotes.TP_Portal:FireServer(islandName) end)
        Notify("Teleporting to "..islandName, 2)
    end})
end

-- ════ TAB: BOSS ════════════════════════════════════════
local BossTab = Window:CreateTab("Boss", 4483362458)

BossTab:CreateSection("Summon")
RT(BossTab, "AutoSummon", "Auto Summon Boss", false)
RS_Opt("SelectedSummon", "")
BossTab:CreateDropdown({Name="Summon Boss", Options=Tables.SummonList, CurrentOption={}, Flag="SelectedSummon",
    Callback=function(v) Options.SelectedSummon.Value = v[1] or "" end})
RS_Opt("SelectedSummonDiff", "Normal")
BossTab:CreateDropdown({Name="Summon Difficulty", Options=Tables.DiffList, CurrentOption={"Normal"}, Flag="SelectedSummonDiff",
    Callback=function(v) Options.SelectedSummonDiff.Value = v[1] or "Normal" end})

BossTab:CreateSection("Other Summon")
RT(BossTab, "AutoOtherSummon", "Auto Other Summon", false)
RS_Opt("SelectedOtherSummon", "")
BossTab:CreateDropdown({Name="Other Summon", Options=Tables.OtherSummonList, CurrentOption={}, Flag="SelectedOtherSummon",
    Callback=function(v) Options.SelectedOtherSummon.Value = v[1] or "" end})
RS_Opt("SelectedOtherSummonDiff", "Normal")
BossTab:CreateDropdown({Name="Other Summon Difficulty", Options=Tables.DiffList, CurrentOption={"Normal"}, Flag="SelectedOtherSummonDiff",
    Callback=function(v) Options.SelectedOtherSummonDiff.Value = v[1] or "Normal" end})

BossTab:CreateSection("Pity Boss")
RT(BossTab, "PityBossFarm", "Pity Boss Farm", false)
RS_Opt("SelectedUsePity", "")
BossTab:CreateDropdown({Name="Use Pity Boss", Options=Tables.SummonList, CurrentOption={}, Flag="SelectedUsePity",
    Callback=function(v) Options.SelectedUsePity.Value = v[1] or "" end})
RS_Opt("SelectedPityDiff", "Normal")
BossTab:CreateDropdown({Name="Pity Difficulty", Options=Tables.DiffList, CurrentOption={"Normal"}, Flag="SelectedPityDiff",
    Callback=function(v) Options.SelectedPityDiff.Value = v[1] or "Normal" end})

BossTab:CreateSection("Manual Summon")
for _, bossName in ipairs(Tables.AllBossList) do
    local bn = bossName
    BossTab:CreateButton({Name="Summon "..bn, Callback=function()
        local diff = (Options.SelectedSummonDiff and Options.SelectedSummonDiff.Value) or "Normal"
        FireBossRemote(bn, diff)
        Notify("Summoning "..bn.." ["..diff.."]", 2)
    end})
end

-- ════ TAB: HAKI ════════════════════════════════════════
local HakiTab = Window:CreateTab("Haki", 4483362458)

HakiTab:CreateSection("Auto Haki")
RT(HakiTab, "AutoArmHaki",       "Auto Arm Haki",        true)
RT(HakiTab, "AutoObsHaki",       "Auto Observation Haki",true)
RT(HakiTab, "AutoConquerorHaki", "Auto Conqueror Haki",  false)

HakiTab:CreateSection("Manual")
HakiTab:CreateButton({Name="Enable Arm Haki",        Callback=function() pcall(function() Remotes.ArmHaki:FireServer() end) end})
HakiTab:CreateButton({Name="Enable Observation Haki",Callback=function() pcall(function() Remotes.ObserHaki:FireServer() end) end})
HakiTab:CreateButton({Name="Enable Conqueror Haki",  Callback=function() pcall(function() Remotes.ConquerorHaki:FireServer() end) end})

-- ════ TAB: MERCHANT ════════════════════════════════════
local MerchTab = Window:CreateTab("Merchant", 4483362458)

MerchTab:CreateSection("Auto Merchant")
RT(MerchTab, "AutoMerchant", "Auto Buy Merchant Items", false, function(v)
    Thread("Farm.Merchant", FuncMerchantFarm, v)
end)
RS_Opt("SelectedMerchantItems", {})
MerchTab:CreateDropdown({Name="Merchant Items", Options=Tables.MerchantList, CurrentOption={}, Flag="SelectedMerchantItems",
    Callback=function(v)
        local tbl = {}
        for _, item in ipairs(v) do tbl[item] = true end
        Options.SelectedMerchantItems.Value = tbl
    end})

MerchTab:CreateSection("Open Merchant")
MerchTab:CreateButton({Name="Open Merchant UI", Callback=function() OpenMerchantInterface() end})
MerchTab:CreateButton({Name="Claim Merchant (firesignal)", Callback=function()
    fire_event(Remotes.OpenMerchant and Remotes.OpenMerchant.OnClientEvent)
end})

-- ════ TAB: ENCHANT / BLESSING ══════════════════════════
local UpgTab = Window:CreateTab("Upgrade", 4483362458)

UpgTab:CreateSection("Enchant")
RT(UpgTab, "AutoEnchant",    "Auto Enchant",        false, function(v) if v then task.spawn(AutoUpgradeLoop, "Enchant") end end)
RT(UpgTab, "AutoEnchantAll", "Auto Enchant All",    false, function(v) if v then task.spawn(AutoUpgradeLoop, "Enchant") end end)
RS_Opt("SelectedEnchant", {})
UpgTab:CreateDropdown({Name="Enchant Target", Options=Tables.OwnedAccessory, CurrentOption={}, Flag="SelectedEnchant",
    Callback=function(v)
        local t = {}; for _, i in ipairs(v) do t[i] = true end
        Options.SelectedEnchant.Value = t
    end})

UpgTab:CreateSection("Blessing")
RT(UpgTab, "AutoBlessing",    "Auto Blessing",       false, function(v) if v then task.spawn(AutoUpgradeLoop, "Blessing") end end)
RT(UpgTab, "AutoBlessingAll", "Auto Blessing All",   false, function(v) if v then task.spawn(AutoUpgradeLoop, "Blessing") end end)
RS_Opt("SelectedBlessing", {})
UpgTab:CreateDropdown({Name="Blessing Target", Options=Tables.OwnedWeapon, CurrentOption={}, Flag="SelectedBlessing",
    Callback=function(v)
        local t = {}; for _, i in ipairs(v) do t[i] = true end
        Options.SelectedBlessing.Value = t
    end})

-- ════ TAB: ARTIFACT ════════════════════════════════════
local ArtTab = Window:CreateTab("Artifact", 4483362458)

ArtTab:CreateSection("Auto Manage")
RT(ArtTab, "ArtifactUpgrade", "Auto Upgrade Artifacts", false)
RT(ArtTab, "ArtifactLock",    "Auto Lock Artifacts",    false)
RT(ArtTab, "ArtifactDelete",  "Auto Delete Artifacts",  false)
RT(ArtTab, "ArtifactEquip",   "Auto Equip Best Artifact",false)
RT(ArtTab, "DeleteUnlock",    "Delete Unlocked (no lock filter)",false)

RS_Opt("UpgradeLimit", 20)
ArtTab:CreateSlider({Name="Upgrade Level Limit", Range={0,20}, Increment=1, CurrentValue=20, Flag="UpgradeLimit",
    Callback=function(v) Options.UpgradeLimit.Value = v end})
RS_Opt("Lock_MinSS", 2)
ArtTab:CreateSlider({Name="Lock Min Sub-Stats Match", Range={1,4}, Increment=1, CurrentValue=2, Flag="Lock_MinSS",
    Callback=function(v) Options.Lock_MinSS.Value = v end})
RS_Opt("Del_MinSS", 0)
ArtTab:CreateSlider({Name="Delete Min Sub-Stats", Range={0,4}, Increment=1, CurrentValue=0, Flag="Del_MinSS",
    Callback=function(v) Options.Del_MinSS.Value = v end})

ArtTab:CreateSection("Actions")
ArtTab:CreateButton({Name="Run Artifact Manager Now", Callback=function()
    task.spawn(RunArtifactManager)
    Notify("Running artifact management...", 3)
end})
ArtTab:CreateButton({Name="Claim Artifact Milestones", Callback=function()
    pcall(function() Remotes.ArtifactClaim:FireServer() end)
    Notify("Claimed artifact milestones", 2)
end})
ArtTab:CreateButton({Name="Sync Artifact Data", Callback=function()
    fire_event(Remotes.ArtifactSync and Remotes.ArtifactSync.OnClientEvent)
    Notify("Syncing artifact data...", 2)
end})

-- ════ TAB: TRAIT / RACE / CLAN ═════════════════════════
local RollTab = Window:CreateTab("Rolls", 4483362458)

RollTab:CreateSection("Trait")
RT(RollTab, "AutoTrait", "Auto Trait Reroll", false)
RS_Opt("SelectedTrait", {})
RollTab:CreateDropdown({Name="Target Traits (multi)", Options=Tables.TraitList, CurrentOption={}, Flag="SelectedTrait",
    Callback=function(v)
        local t = {}; for _, i in ipairs(v) do t[i] = true end
        Options.SelectedTrait.Value = t; SyncTraitAutoSkip()
    end})
RollTab:CreateButton({Name="Sync Trait Auto-Skip", Callback=function() SyncTraitAutoSkip(); Notify("Trait skip synced",2) end})
RollTab:CreateButton({Name="Confirm Current Trait",  Callback=function() pcall(function() Remotes.TraitConfirm:FireServer() end) end})

RollTab:CreateSection("Race")
RT(RollTab, "AutoRace", "Auto Race Reroll", false, function() SyncRaceSettings() end)
RS_Opt("SelectedRace", {})
RollTab:CreateDropdown({Name="Target Races (multi)", Options=Tables.RaceList, CurrentOption={}, Flag="SelectedRace",
    Callback=function(v)
        local t = {}; for _, i in ipairs(v) do t[i] = true end
        Options.SelectedRace.Value = t; SyncRaceSettings()
    end})

RollTab:CreateSection("Clan")
RT(RollTab, "AutoClan", "Auto Clan Reroll", false, function() SyncClanSettings() end)
RS_Opt("SelectedClan", {})
RollTab:CreateDropdown({Name="Target Clans (multi)", Options=Tables.ClanList, CurrentOption={}, Flag="SelectedClan",
    Callback=function(v)
        local t = {}; for _, i in ipairs(v) do t[i] = true end
        Options.SelectedClan.Value = t; SyncClanSettings()
    end})

-- ════ TAB: SKILLS / TITLES / RUNES ════════════════════
local EquipTab = Window:CreateTab("Equip", 4483362458)

EquipTab:CreateSection("Auto Switch")
RT(EquipTab, "AutoTitle", "Auto Switch Title", false)
RS_Opt("DefaultTitle", "")
EquipTab:CreateDropdown({Name="Default Title", Options=CombinedTitleList, CurrentOption={}, Flag="DefaultTitle",
    Callback=function(v) Options.DefaultTitle.Value = v[1] or "" end})
RS_Opt("Title_Mob", "")
EquipTab:CreateDropdown({Name="Title [Mob]", Options=CombinedTitleList, CurrentOption={}, Flag="Title_Mob",
    Callback=function(v) Options.Title_Mob.Value = v[1] or "" end})
RS_Opt("Title_Boss", "")
EquipTab:CreateDropdown({Name="Title [Boss]", Options=CombinedTitleList, CurrentOption={}, Flag="Title_Boss",
    Callback=function(v) Options.Title_Boss.Value = v[1] or "" end})
RS_Opt("Title_BossHP", "")
EquipTab:CreateDropdown({Name="Title [Boss Low HP]", Options=CombinedTitleList, CurrentOption={}, Flag="Title_BossHP",
    Callback=function(v) Options.Title_BossHP.Value = v[1] or "" end})
RS_Opt("Title_BossHPAmt", 15)
EquipTab:CreateSlider({Name="Boss HP% Threshold", Range={0,100}, Increment=1, CurrentValue=15, Flag="Title_BossHPAmt",
    Callback=function(v) Options.Title_BossHPAmt.Value = v end})

EquipTab:CreateSection("Auto Rune")
RT(EquipTab, "AutoRune", "Auto Switch Rune", false)
RS_Opt("DefaultRune", "None")
EquipTab:CreateDropdown({Name="Default Rune", Options=Tables.RuneList, CurrentOption={"None"}, Flag="DefaultRune",
    Callback=function(v) Options.DefaultRune.Value = v[1] or "None" end})
RS_Opt("Rune_Mob", "None")
EquipTab:CreateDropdown({Name="Rune [Mob]", Options=Tables.RuneList, CurrentOption={"None"}, Flag="Rune_Mob",
    Callback=function(v) Options.Rune_Mob.Value = v[1] or "None" end})
RS_Opt("Rune_Boss", "None")
EquipTab:CreateDropdown({Name="Rune [Boss]", Options=Tables.RuneList, CurrentOption={"None"}, Flag="Rune_Boss",
    Callback=function(v) Options.Rune_Boss.Value = v[1] or "None" end})

EquipTab:CreateSection("Auto Build")
RT(EquipTab, "AutoBuild", "Auto Switch Build", false)
RS_Opt("DefaultBuild", "None")
EquipTab:CreateDropdown({Name="Default Build", Options=Tables.BuildList, CurrentOption={"None"}, Flag="DefaultBuild",
    Callback=function(v) Options.DefaultBuild.Value = v[1] or "None" end})
RS_Opt("Build_Mob", "None")
EquipTab:CreateDropdown({Name="Build [Mob]", Options=Tables.BuildList, CurrentOption={"None"}, Flag="Build_Mob",
    Callback=function(v) Options.Build_Mob.Value = v[1] or "None" end})
RS_Opt("Build_Boss", "None")
EquipTab:CreateDropdown({Name="Build [Boss]", Options=Tables.BuildList, CurrentOption={"None"}, Flag="Build_Boss",
    Callback=function(v) Options.Build_Boss.Value = v[1] or "None" end})

EquipTab:CreateSection("Weapon Type Filter")
RS_Opt("SelectedWeaponType", {Melee=true, Sword=true, Power=false})
EquipTab:CreateDropdown({Name="Weapon Types", Options=Tables.Weapon, CurrentOption={"Melee","Sword"}, Flag="SelectedWeaponType",
    Callback=function(v)
        local t = {}; for _, i in ipairs(v) do t[i] = true end
        Options.SelectedWeaponType.Value = t
    end})
RS_Opt("SwitchWeaponCD", 4)
EquipTab:CreateSlider({Name="Weapon Switch Cooldown (s)", Range={1,30}, Increment=1, CurrentValue=4, Flag="SwitchWeaponCD",
    Callback=function(v) Options.SwitchWeaponCD.Value = v end})

-- ════ TAB: CRAFTING / NPC ══════════════════════════════
local CraftTab = Window:CreateTab("NPC / Craft", 4483362458)

CraftTab:CreateSection("NPC Teleport")
for _, npc in ipairs(Tables.NPC_MiscList) do
    local n = npc
    CraftTab:CreateButton({Name="TP → "..n, Callback=function() SafeTeleportToNPC(n) end})
end

CraftTab:CreateSection("Crafting")
for _, item in ipairs(Tables.CraftItemList) do
    local it = item
    CraftTab:CreateButton({Name="Craft "..it, Callback=function()
        if it == "SlimeKey" then pcall(function() Remotes.SlimeCraft:FireServer() end)
        elseif it == "DivineGrail" then pcall(function() Remotes.GrailCraft:FireServer() end) end
        Notify("Crafting "..it, 2)
    end})
end

CraftTab:CreateSection("Dungeon")
for _, dung in ipairs(Tables.DungeonList) do
    local d = dung
    CraftTab:CreateButton({Name="Open Dungeon: "..d, Callback=function()
        pcall(function() Remotes.OpenDungeon:FireServer(d) end)
        Notify("Opening dungeon: "..d, 2)
    end})
end

CraftTab:CreateSection("Ascend")
CraftTab:CreateButton({Name="Request Ascend Data", Callback=function()
    pcall(function() Remotes.ReqAscend:FireServer() end); Notify("Ascend data requested",2)
end})
CraftTab:CreateButton({Name="Request Ascend", Callback=function()
    pcall(function() Remotes.Ascend:FireServer() end); Notify("Ascend sent",2)
end})

-- ════ TAB: MISC / PLAYER ══════════════════════════════
local MiscTab = Window:CreateTab("Misc", 4483362458)

MiscTab:CreateSection("Player")
RT(MiscTab, "AntiKnockback",   "Anti Knockback",        false, function(v) Thread("Misc.AntiKB", Func_AntiKnockback, v) end)
RT(MiscTab, "AutoReconnect",   "Auto Reconnect",        false, function() Func_AutoReconnect() end)
RT(MiscTab, "FPSBoost",        "FPS Boost (Client)",    false, function(v) if v then ApplyFPSBoost() end end)
RT(MiscTab, "FPSBoost_AF",     "FPS Boost Island Wipe", false)
RT(MiscTab, "AutoDeleteNotif", "Hide Junk Notifications",false)

if Support.FPS then
    RS_Opt("FPSCap", 60)
    MiscTab:CreateSlider({Name="FPS Cap", Range={15,240}, Increment=5, CurrentValue=60, Flag="FPSCap",
        Callback=function(v) Options.FPSCap.Value = v; pcall(function() setfpscap(v) end) end})
end

MiscTab:CreateSection("Safety")
RT(MiscTab, "AutoKick", "Auto Kick (Anti-Join)", false, function(v) if v then
    pcall(function() for _, p in ipairs(Players:GetPlayers()) do CheckPlayerForSafety(p) end end)
    Players.PlayerAdded:Connect(CheckPlayerForSafety)
end end)
RS_Opt("SelectedKickType", {})
MiscTab:CreateDropdown({Name="Kick Type", Options={"Player Join","Mod","Public Server"}, CurrentOption={}, Flag="SelectedKickType",
    Callback=function(v)
        local t = {}; for _, i in ipairs(v) do t[i] = true end
        Options.SelectedKickType.Value = t
    end})

MiscTab:CreateSection("Actions")
MiscTab:CreateButton({Name="⚠ PANIC STOP",  Callback=function() PanicStop() end})
MiscTab:CreateButton({Name="Request Inventory Sync", Callback=function()
    pcall(function() Remotes.ReqInventory:FireServer() end)
    Notify("Inventory sync requested",2)
end})

-- ════ TAB: CODES ══════════════════════════════════════
local CodesTab = Window:CreateTab("Codes", 4483362458)

CodesTab:CreateSection("Redeem Codes")
CodesTab:CreateButton({Name="Redeem ALL Codes", Callback=function()
    if not (Modules.Codes and Modules.Codes.Codes) then Notify("Codes module not found",3); return end
    local count = 0
    task.spawn(function()
        for code, _ in pairs(Modules.Codes.Codes) do
            FuncAutoCode(code); count = count + 1; task.wait(0.6)
        end
        Notify("Redeemed "..count.." codes!", 4)
    end)
end})

RS_Opt("ManualCode", "")
CodesTab:CreateInput({Name="Manual Code", PlaceholderText="Enter code here", RemoveTextAfterFocusLost=false, Flag="ManualCode",
    Callback=function(v) Options.ManualCode.Value = v end})
CodesTab:CreateButton({Name="Redeem Manual Code", Callback=function()
    local code = Options.ManualCode and Options.ManualCode.Value or ""
    if code == "" then Notify("Enter a code first",2); return end
    FuncAutoCode(code); Notify("Redeemed: "..code, 3)
end})

-- ════ TAB: WEBHOOK ════════════════════════════════════
local WebhookTab = Window:CreateTab("Webhook", 4483362458)

WebhookTab:CreateSection("Discord Webhook")
RS_Opt("WebhookURL", "")
WebhookTab:CreateInput({Name="Webhook URL", PlaceholderText="https://discord.com/api/webhooks/...", RemoveTextAfterFocusLost=false, Flag="WebhookURL",
    Callback=function(v) Options.WebhookURL.Value = v end})
RS_Opt("UID", "")
WebhookTab:CreateInput({Name="Discord UID (ping)", PlaceholderText="Your Discord User ID", RemoveTextAfterFocusLost=false, Flag="UID",
    Callback=function(v) Options.UID.Value = v end})
RT(WebhookTab, "PingUser", "Ping User on Post", false)

WebhookTab:CreateSection("Data to Send")
RT(WebhookTab, "WH_SendName",   "Send Player Name",   true)
RT(WebhookTab, "WH_SendStats",  "Send Stats",          true)
RT(WebhookTab, "WH_SendItems",  "Send New Items",      true)
RT(WebhookTab, "WH_SendAll",    "Send All Inventory",  false)

WebhookTab:CreateButton({Name="Post to Webhook Now", Callback=function()
    PostToWebhook(); Notify("Webhook sent!", 2)
end})

-- ════ LOADED ══════════════════════════════════════════
Rayfield:Notify({
    Title   = "Neko Hub",
    Content = "Loaded! Sailor Piece · All functions ready.",
    Duration= 6,
})

warn("[NekoHub] Loaded | Sailor Piece | All functions active")

-- ════ TAB: SPEC PASSIVE ═══════════════════════════════
local SpecTab = Window:CreateTab("Spec Passive", 4483362458)

SpecTab:CreateSection("Auto Spec Passive")
RT(SpecTab, "AutoSpecPassive", "Auto Reroll Spec Passive", false)
RS_Opt("SelectedPassive", {})
SpecTab:CreateDropdown({Name="Weapons (multi)", Options=Tables.AllOwnedWeapons, CurrentOption={}, Flag="SelectedPassive",
    Callback=function(v)
        local t = {}; for _, i in ipairs(v) do t[i] = true end
        Options.SelectedPassive.Value = t
    end})

SpecTab:CreateSection("Target Passives")
RS_Opt("SelectedSpecPassive", {})
SpecTab:CreateDropdown({Name="Target Spec Passives", Options=Tables.SpecPassive, CurrentOption={}, Flag="SelectedSpecPassive",
    Callback=function(v)
        local t = {}; for _, i in ipairs(v) do t[i] = true end
        Options.SelectedSpecPassive.Value = t
    end})

SpecTab:CreateSection("Actions")
SpecTab:CreateButton({Name="Sync Spec Passive Auto-Skip", Callback=function()
    pcall(function()
        local skipData = {["Epic"]=true,["Legendary"]=true,["Mythical"]=true}
        if Remotes.SpecPassiveSkip then Remotes.SpecPassiveSkip:FireServer(skipData) end
    end)
    Notify("Spec passive skip synced",2)
end})
SpecTab:CreateButton({Name="Reroll Spec Passive", Callback=function()
    local sel = Options.SelectedPassive and Options.SelectedPassive.Value or {}
    local count = 0
    task.spawn(function()
        for weapName, enabled in pairs(sel) do
            if enabled then
                pcall(function() Remotes.SpecPassiveReroll:FireServer(weapName) end)
                count = count + 1; task.wait(0.5)
            end
        end
        Notify("Rerolled "..count.." weapons",3)
    end)
end})

-- ════ TAB: SKILL TREE ═════════════════════════════════
local SkillTab = Window:CreateTab("Skill Tree", 4483362458)

SkillTab:CreateSection("Auto Skill Tree")
RT(SkillTab, "AutoSkillTree", "Auto Upgrade Skill Tree", false)

local function FuncSkillTree()
    while Toggles.AutoSkillTree and Toggles.AutoSkillTree.Value do
        if Shared.SkillTree.SkillPoints and Shared.SkillTree.SkillPoints > 0 then
            for nodeId, nodeData in pairs(Shared.SkillTree.Nodes or {}) do
                if not nodeData.Purchased then
                    pcall(function() Remotes.SkillTreeUpgrade:FireServer(nodeId) end)
                    task.wait(0.4)
                end
            end
        end
        task.wait(2)
    end
end

Toggles.AutoSkillTree = Toggles.AutoSkillTree or {Value=false}
local _oldSkillCB = SkillTab
RT(SkillTab, "AutoSkillTree", "Auto Upgrade Skill Tree Nodes", false, function(v)
    Thread("SkillTree.Main", FuncSkillTree, v)
end)

SkillTab:CreateSection("NPC Teleport")
SkillTab:CreateButton({Name="TP → Skill Tree NPC", Callback=function()
    SafeTeleportToNPC("SkillTree"); Notify("Teleporting to Skill Tree NPC",2)
end})

SkillTab:CreateSection("Stats Info")
SkillTab:CreateParagraph({Title="Skill Points", Content="Skill points and node data sync automatically when you open the Skill Tree in-game. Enable Auto Upgrade to spend them automatically."})

-- ════ TAB: STAT REROLL ════════════════════════════════
local StatTab = Window:CreateTab("Stat Reroll", 4483362458)

StatTab:CreateSection("Gem / Stat Reroll")
RT(StatTab, "AutoStatReroll", "Auto Stat Reroll", false)

local function FuncStatReroll()
    while Toggles.AutoStatReroll and Toggles.AutoStatReroll.Value do
        local targetStats = Options.SelectedGemStats and Options.SelectedGemStats.Value or {}
        local hasTarget = next(targetStats) ~= nil
        local allGood = true

        if hasTarget then
            for _, statName in ipairs(Tables.GemStat) do
                if targetStats[statName] then
                    local data = Shared.GemStats[statName]
                    local targetRank = Options.SelectedGemRank and Options.SelectedGemRank.Value or "S"
                    local rankOrder = Tables.GemRank
                    if not data or (rankOrder and rankOrder[data.Rank] or 0) < (rankOrder and rankOrder[targetRank] or 0) then
                        allGood = false
                        pcall(function() Remotes.RerollSingleStat:FireServer(statName) end)
                        task.wait(0.4)
                        break
                    end
                end
            end
        end

        if allGood and hasTarget then
            Notify("All target stats at desired rank!", 5)
            Toggles.AutoStatReroll.Value = false; break
        end
        task.wait(0.1)
    end
end

RT(StatTab, "AutoStatReroll", "Auto Reroll Stats", false, function(v)
    Thread("StatReroll.Main", FuncStatReroll, v)
end)

RS_Opt("SelectedGemStats", {})
StatTab:CreateDropdown({Name="Target Stats (multi)", Options=Tables.GemStat, CurrentOption={}, Flag="SelectedGemStats",
    Callback=function(v)
        local t = {}; for _, i in ipairs(v) do t[i] = true end
        Options.SelectedGemStats.Value = t
    end})

RS_Opt("SelectedGemRank", "S")
StatTab:CreateDropdown({Name="Target Rank", Options=Tables.GemRank or {"D","C","B","A","S","SS","SSS"}, CurrentOption={"S"}, Flag="SelectedGemRank",
    Callback=function(v) Options.SelectedGemRank.Value = v[1] or "S" end})

StatTab:CreateSection("Manual")
StatTab:CreateButton({Name="Reroll Once", Callback=function()
    local sel = Options.SelectedGemStats and Options.SelectedGemStats.Value or {}
    local count = 0
    for statName, enabled in pairs(sel) do
        if enabled then
            pcall(function() Remotes.RerollSingleStat:FireServer(statName) end)
            count = count + 1; task.wait(0.3)
        end
    end
    Notify("Rerolled "..count.." stats",2)
end})
StatTab:CreateButton({Name="Allocate Stat Point", Callback=function()
    local stat = Options.SelectedAllocStat and Options.SelectedAllocStat.Value or ""
    if stat == "" then Notify("Select a stat first",2); return end
    pcall(function() Remotes.AddStat:FireServer(stat) end)
    Notify("Allocated: "..stat,2)
end})
RS_Opt("SelectedAllocStat", "")
StatTab:CreateDropdown({Name="Allocate Stat", Options={"Strength","Defense","Speed","Vitality","Intelligence","Spirit"}, CurrentOption={}, Flag="SelectedAllocStat",
    Callback=function(v) Options.SelectedAllocStat.Value = v[1] or "" end})

-- ════ TAB: WEAPON ROTATION ════════════════════════════
local WRTab = Window:CreateTab("Weap Rotation", 4483362458)

WRTab:CreateSection("Weapon Rotation")
RT(WRTab, "WeaponRotation", "Enable Weapon Rotation", false)
WRTab:CreateDropdown({Name="Weapon Types to Include", Options={"Melee","Sword","Power"}, CurrentOption={"Melee","Sword"}, Flag="SelectedWeaponTypeWR",
    Callback=function(v)
        local t = {}; for _, i in ipairs(v) do t[i] = true end
        Options.SelectedWeaponType = Options.SelectedWeaponType or {Value={}}
        Options.SelectedWeaponType.Value = t
    end})
WRTab:CreateSlider({Name="Switch Cooldown (s)", Range={1,30}, Increment=1, CurrentValue=4, Flag="SwitchWeaponCDWR",
    Callback=function(v) Options.SwitchWeaponCD = Options.SwitchWeaponCD or {Value=4}; Options.SwitchWeaponCD.Value = v end})

WRTab:CreateSection("Combo System")
RT(WRTab, "AutoCombo", "Auto Combo (Custom F-Move)", false)
RS_Opt("ComboString", "")
WRTab:CreateInput({Name="Combo String (e.g. M1,Z,X,C)", PlaceholderText="M1,Z,X,M1,F", RemoveTextAfterFocusLost=false, Flag="ComboString",
    Callback=function(v)
        Options.ComboString.Value = v
        Shared.ParsedCombo = {}
        for part in v:gmatch("[^,]+") do
            table.insert(Shared.ParsedCombo, part:upper():gsub("%s",""))
        end
    end})

local function FuncComboLoop()
    while Toggles.AutoCombo and Toggles.AutoCombo.Value do
        if #Shared.ParsedCombo == 0 then task.wait(0.5); continue end
        local char = GetCharacter()
        if not char then task.wait(0.5); continue end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then task.wait(0.5); continue end

        local step = Shared.ParsedCombo[Shared.ComboIdx]
        if step == "M1" then
            local root = char:FindFirstChild("HumanoidRootPart")
            local target = Shared.Target
            local targetRoot = target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)
            if root and targetRoot then
                pcall(function() Remotes.M1:FireServer(target, targetRoot.CFrame) end)
            end
        else
            pcall(function() Remotes.UseSkill:FireServer(step) end)
        end

        Shared.ComboIdx = Shared.ComboIdx % #Shared.ParsedCombo + 1
        task.wait(0.3)
    end
end

RT(WRTab, "AutoCombo", "Enable Auto Combo", false, function(v)
    Thread("Combo.Main", FuncComboLoop, v)
    if v then Shared.GlobalPrio = "COMBO" else Shared.GlobalPrio = "FARM" end
end)

-- ════ TAB: QUESTLINE ══════════════════════════════════
local QuestlineTab = Window:CreateTab("Questline", 4483362458)

QuestlineTab:CreateSection("Questline NPC")
RT(QuestlineTab, "AutoQuestline", "Auto Questline", false)
RS_Opt("SelectedQuestline", "")
QuestlineTab:CreateDropdown({Name="Questline", Options=Tables.QuestlineList, CurrentOption={}, Flag="SelectedQuestline",
    Callback=function(v) Options.SelectedQuestline.Value = v[1] or "" end})

local function FuncQuestline()
    while Toggles.AutoQuestline and Toggles.AutoQuestline.Value do
        local sel = Options.SelectedQuestline and Options.SelectedQuestline.Value or ""
        if sel == "" then task.wait(1); continue end

        local questlineData = Modules.Quests and Modules.Quests.Questlines and Modules.Quests.Questlines[sel]
        if not questlineData then task.wait(1); continue end

        local qUI = GetCurrentQuestUI()
        if qUI.IsVisible and qUI.SwitchVisible then
            pcall(function() gsc(qUI.SwitchBtn) end)
            task.wait(0.5)
        elseif not qUI.IsVisible then
            for _, npc in ipairs(Tables.NPC_MasteryList) do
                if npc:lower():find(sel:lower()) then
                    SafeTeleportToNPC(npc); task.wait(0.3); break
                end
            end
        end
        task.wait(1)
    end
end

RT(QuestlineTab, "AutoQuestline", "Auto Questline Progress", false, function(v)
    Thread("Questline.Main", FuncQuestline, v)
end)

QuestlineTab:CreateSection("Manual NPC TP")
for _, npc in ipairs(Tables.NPC_MasteryList) do
    local n = npc
    QuestlineTab:CreateButton({Name="TP → "..n, Callback=function()
        SafeTeleportToNPC(n); Notify("Teleporting to "..n,2)
    end})
end

-- ════ TAB: PUZZLE SOLVER ══════════════════════════════
local PuzzleTab = Window:CreateTab("Puzzles", 4483362458)

PuzzleTab:CreateSection("Puzzle Solvers")
PuzzleTab:CreateParagraph({Title="Auto Puzzle", Content="Automatically collects all puzzle pieces for the selected puzzle. Requires fireproximityprompt support."})

for _, pType in ipairs({"Dungeon","Slime","Demonite","Hogyoku"}) do
    local pt = pType
    PuzzleTab:CreateButton({Name="Solve: "..pt.." Puzzle", Callback=function()
        if not Support.Proximity then
            Notify("Your executor does not support fireproximityprompt",4); return
        end
        task.spawn(function()
            local ok, err = pcall(function()
                local moduleMap = {
                    ["Dungeon"]  = RS.Modules:FindFirstChild("DungeonConfig"),
                    ["Slime"]    = RS.Modules:FindFirstChild("SlimePuzzleConfig"),
                    ["Demonite"] = RS.Modules:FindFirstChild("DemoniteCoreQuestConfig"),
                    ["Hogyoku"]  = RS.Modules:FindFirstChild("HogyokuQuestConfig"),
                }
                local hogyokuIslands = {"Snow","Shibuya","HuecoMundo","Shinjuku","Slime","Judgement"}
                local targetModule = moduleMap[pt]
                if not targetModule then Notify("Module not found for: "..pt,3); return end

                local data = require(targetModule)
                local settings = data.PuzzleSettings or data.PieceSettings
                local pieces = data.Pieces or (settings and settings.IslandOrder) or {}
                local pieceName = (settings and settings.PieceModelName) or "DungeonPuzzlePiece"

                Notify("Starting "..pt.." Puzzle...",5)

                for i, islandOrPiece in ipairs(pieces) do
                    local tpTarget = nil
                    if pt == "Demonite" then tpTarget = "Academy"
                    elseif pt == "Hogyoku" then tpTarget = hogyokuIslands[i]
                    else
                        tpTarget = islandOrPiece:gsub("Island",""):gsub("Station","")
                        if islandOrPiece == "HuecoMundo" then tpTarget = "HuecoMundo" end
                    end

                    if tpTarget then
                        pcall(function() Remotes.TP_Portal:FireServer(tpTarget) end)
                        task.wait(2.5)
                    end

                    local piece = nil
                    if pt == "Demonite" or pt == "Hogyoku" then
                        piece = workspace:FindFirstChild(islandOrPiece, true)
                    else
                        local islandFolder = workspace:FindFirstChild(islandOrPiece)
                        piece = (islandFolder and islandFolder:FindFirstChild(pieceName, true))
                             or workspace:FindFirstChild(pieceName, true)
                    end

                    if piece then
                        HybridMove(piece:GetPivot() * CFrame.new(0,3,0))
                        task.wait(0.5)
                        local prompt = piece:FindFirstChildOfClass("ProximityPrompt")
                                    or piece:FindFirstChild("ProximityPrompt", true)
                        if prompt then
                            fireproximityprompt(prompt)
                            Notify(string.format("Collected piece %d/%d", i, #pieces), 2)
                            task.wait(1.5)
                        else
                            Notify("No prompt on piece "..i, 3)
                        end
                    else
                        Notify("Piece "..i.." not found on "..tostring(tpTarget), 3)
                    end
                end
                Notify(pt.." Puzzle Complete!", 5)
            end)
            if not ok then Notify("Puzzle error: "..tostring(err), 5) end
        end)
    end})
end

-- ════ TAB: TRADE ══════════════════════════════════════
local TradeTab = Window:CreateTab("Trade", 4483362458)

TradeTab:CreateSection("Trade Requests")
RT(TradeTab, "AutoAcceptTrade",  "Auto Accept Trade Requests",  false)
RT(TradeTab, "AutoDeclineTrade", "Auto Decline Trade Requests", false)

if Remotes.TradeUpdated then
    Remotes.TradeUpdated.OnClientEvent:Connect(function(data)
        Shared.TradeState = data
        if data and data.incomingRequest then
            local requester = data.incomingRequest.Player
            if requester and requester ~= Plr then
                if Toggles.AutoAcceptTrade and Toggles.AutoAcceptTrade.Value then
                    pcall(function() Remotes.TradeRespond:FireServer(true, requester) end)
                    Notify("Auto-accepted trade from "..requester.Name, 3)
                elseif Toggles.AutoDeclineTrade and Toggles.AutoDeclineTrade.Value then
                    pcall(function() Remotes.TradeRespond:FireServer(false, requester) end)
                end
            end
        end
    end)
end

TradeTab:CreateSection("Send Trade")
RS_Opt("TradeTargetPlayer", "")
local playerNames = {}
for _, p in ipairs(Players:GetPlayers()) do if p ~= Plr then table.insert(playerNames, p.Name) end end
TradeTab:CreateDropdown({Name="Target Player", Options=playerNames, CurrentOption={}, Flag="TradeTargetPlayer",
    Callback=function(v) Options.TradeTargetPlayer.Value = v[1] or "" end})
TradeTab:CreateButton({Name="Send Trade Request", Callback=function()
    local targetName = Options.TradeTargetPlayer and Options.TradeTargetPlayer.Value or ""
    if targetName == "" then Notify("Select a player first",2); return end
    local target = Players:FindFirstChild(targetName)
    if not target then Notify("Player not found: "..targetName,2); return end
    pcall(function() Remotes.TradeSend:FireServer(target) end)
    Notify("Trade request sent to "..targetName,2)
end})

TradeTab:CreateSection("Trade Items")
RS_Opt("SelectedTradeItems", {})
TradeTab:CreateDropdown({Name="Items to Add", Options=Tables.OwnedItem, CurrentOption={}, Flag="SelectedTradeItems",
    Callback=function(v)
        local t = {}; for _, i in ipairs(v) do t[i] = true end
        Options.SelectedTradeItems.Value = t
    end})
TradeTab:CreateButton({Name="Add Items to Trade", Callback=function()
    local sel = Options.SelectedTradeItems and Options.SelectedTradeItems.Value or {}
    for itemName, enabled in pairs(sel) do
        if enabled then
            pcall(function() Remotes.TradeAddItem:FireServer(itemName, 1) end)
            task.wait(0.3)
        end
    end
    Notify("Items added to trade",2)
end})
TradeTab:CreateButton({Name="Set Ready",    Callback=function() pcall(function() Remotes.TradeReady:FireServer(true) end); Notify("Trade ready!",2) end})
TradeTab:CreateButton({Name="Confirm Trade",Callback=function() pcall(function() Remotes.TradeConfirm:FireServer() end); Notify("Trade confirmed!",2) end})

-- ════ TAB: ALT HELP ═══════════════════════════════════
local AltTab = Window:CreateTab("Alt Help", 4483362458)

AltTab:CreateSection("Alt Help Mode")
AltTab:CreateParagraph({Title="Alt Help", Content="Use your alt account to assist with boss fights. The main account activates boss; the alt deals damage and collects rewards."})

RT(AltTab, "AltHelp", "Enable Alt Help Mode", false)
RT(AltTab, "AltAutoAttack", "Alt Auto M1 Attack", false)

local function FuncAltHelp()
    while Toggles.AltHelp and Toggles.AltHelp.Value do
        local char = GetCharacter()
        if not char then task.wait(1); continue end

        local target = nil
        for _, v in pairs(PATH.Mobs:GetChildren()) do
            if v.Name:lower():find("boss") then
                local h = v:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then target = v; break end
            end
        end

        if target then
            Shared.AltActive = true
            local root = char:FindFirstChild("HumanoidRootPart")
            local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
            if root and targetRoot then
                local dist = (root.Position - targetRoot.Position).Magnitude
                if dist > 20 then root.CFrame = targetRoot.CFrame * CFrame.new(0, 3, -15) end
                if Toggles.AltAutoAttack and Toggles.AltAutoAttack.Value then
                    pcall(function() Remotes.M1:FireServer(target, targetRoot.CFrame) end)
                    task.wait(0.35)
                end
            end
        else
            Shared.AltActive = false
        end
        task.wait(0.1)
    end
end

RT(AltTab, "AltHelp", "Enable Alt Help Mode", false, function(v)
    Thread("AltHelp.Main", FuncAltHelp, v)
end)

AltTab:CreateSection("Damage Stats")
AltTab:CreateButton({Name="Show Damage Stats", Callback=function()
    if not next(Shared.AltDamage) then Notify("No boss damage data yet",3); return end
    local msg = "Boss Damage:\n"
    for player, pct in pairs(Shared.AltDamage) do
        msg = msg .. string.format("  %s: %.1f%%\n", player, pct)
    end
    Notify(msg, 6)
end})

-- ════ TAB: MOVESET / MASTERY ══════════════════════════
local MoveTab = Window:CreateTab("Moveset", 4483362458)

MoveTab:CreateSection("Moveset NPC")
for _, npc in ipairs(Tables.NPC_MovesetList) do
    local n = npc
    MoveTab:CreateButton({Name="Buy Moveset: "..n, Callback=function()
        SafeTeleportToNPC(n); Notify("Teleporting to "..n,2)
    end})
end

MoveTab:CreateSection("Mastery NPC")
for _, npc in ipairs(Tables.NPC_MasteryList) do
    local n = npc
    MoveTab:CreateButton({Name="Mastery: "..n, Callback=function()
        SafeTeleportToNPC(n); Notify("Teleporting to "..n,2)
    end})
end

-- ════ TAB: AUTO COMPLETE ══════════════════════════════
-- Wrapper loop: handles quest ping, auto-accept from game's own prompt system
local function FuncAutoComplete()
    while true do
        task.wait(0.5)
        if not Toggles.AutoFarm or not Toggles.AutoFarm.Value then continue end

        -- Auto-complete if quest complete popup visible
        local ok = pcall(function()
            local pingUI = PGui:FindFirstChild("QuestPingUI")
            if pingUI and pingUI.Visible then
                for _, btn in pairs(pingUI:GetDescendants()) do
                    if btn:IsA("TextButton") and (btn.Text:lower():find("claim") or btn.Text:lower():find("complete")) then
                        pcall(function() btn:Activate() end)
                        break
                    end
                end
            end
        end)

        -- Auto-dismiss notification frames
        if Toggles.AutoDeleteNotif and Toggles.AutoDeleteNotif.Value then
            pcall(function()
                local notifHolder = PGui:FindFirstChild("NotificationUI") or PGui:FindFirstChild("NotifUI")
                if notifHolder then
                    local notifBL = {"You don't have this item!", "Not enough "}
                    for _, frame in pairs(notifHolder:GetDescendants()) do
                        if frame:IsA("TextLabel") then
                            local txt = frame.Text:lower()
                            for _, bl in ipairs(notifBL) do
                                if txt:find(bl:lower()) then
                                    if frame.Parent and frame.Parent:IsA("Frame") then
                                        frame.Parent.Visible = false
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- Stat allocation auto-loop
        if Toggles.AutoStatAlloc and Toggles.AutoStatAlloc.Value then
            local stat = Options.SelectedAllocStat and Options.SelectedAllocStat.Value or ""
            if stat ~= "" then
                pcall(function() Remotes.AddStat:FireServer(stat) end)
                task.wait(0.3)
            end
        end
    end
end

task.spawn(FuncAutoComplete)

-- ════ MISC CONTINUOUS LOOPS ═══════════════════════════

-- Auto Reconnect init
Func_AutoReconnect()

-- Weapon rotation background heartbeat
RunService.Heartbeat:Connect(function()
    if Toggles.AutoArmHaki and Toggles.AutoArmHaki.Value then
        if tick() % 5 < 0.05 then
            pcall(function() Remotes.ArmHaki:FireServer() end)
        end
    end
    if Toggles.AutoConquerorHaki and Toggles.AutoConquerorHaki.Value then
        if tick() % 8 < 0.05 then
            pcall(function() Remotes.ConquerorHaki:FireServer() end)
        end
    end
    if Toggles.AutoSkillTree and Toggles.AutoSkillTree.Value then
        if tick() % 3 < 0.05 then
            for nodeId, nodeData in pairs(Shared.SkillTree.Nodes or {}) do
                if not nodeData.Purchased then
                    pcall(function() Remotes.SkillTreeUpgrade:FireServer(nodeId) end)
                end
            end
        end
    end
end)

-- Artifact manager loop
task.spawn(function()
    while true do
        task.wait(8)
        if (Toggles.ArtifactUpgrade and Toggles.ArtifactUpgrade.Value)
            or (Toggles.ArtifactLock and Toggles.ArtifactLock.Value)
            or (Toggles.ArtifactDelete and Toggles.ArtifactDelete.Value) then
            pcall(RunArtifactManager)
        end
        if Toggles.ArtifactEquip and Toggles.ArtifactEquip.Value then
            -- equip best artifacts
            pcall(function()
                local bestItems = {}; local bestScores = {}
                local cats = {"Helmet","Gloves","Body","Boots"}
                for _, cat in ipairs(cats) do bestItems[cat]=nil; bestScores[cat]=-1 end
                for uuid, data in pairs(Shared.ArtifactSession.Inventory) do
                    local score = data.Level or 0
                    if score > (bestScores[data.Category] or -1) then
                        bestScores[data.Category] = score
                        bestItems[data.Category]  = {UUID=uuid,Equipped=data.Equipped}
                    end
                end
                for _, item in pairs(bestItems) do
                    if item and not item.Equipped then
                        Remotes.ArtifactEquip:FireServer(item.UUID); task.wait(0.2)
                    end
                end
            end)
        end
    end
end)

-- Request initial inventory sync
task.delay(3, function()
    pcall(function() Remotes.ReqInventory:FireServer() end)
end)

warn("[NekoHub] All tabs loaded successfully | Sailor Piece")
