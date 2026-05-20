--[[
  ██████╗ ███████╗██╗  ██╗    ██╗  ██╗██╗   ██╗██████╗
  ██╔══██╗██╔════╝╚██╗██╔╝    ██║  ██║██║   ██║██╔══██╗
  ██████╔╝█████╗   ╚███╔╝     ███████║██║   ██║██████╔╝
  ██╔══██╗██╔══╝   ██╔██╗     ██╔══██║██║   ██║██╔══██╗
  ██║  ██║███████╗██╔╝ ██╗    ██║  ██║╚██████╔╝██████╔╝
  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
  Rex Hub | Build-A-Ring-Farm Edition
  UI: WindUI by Footagesus
--]]

repeat task.wait() until game:IsLoaded()

-- ─────────────────────────────────────
--  SERVICES
-- ─────────────────────────────────────
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")

-- Anti-AFK
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ─────────────────────────────────────
--  WIND UI — load
-- ─────────────────────────────────────
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title  = "Rex Hub",
    Icon   = "leaf",
    Theme  = "Dark",
    Folder = "RexHub",
})

local function Notify(title, content, icon)
    WindUI:Notify({
        Title    = title,
        Content  = content or "",
        Icon     = icon or "solar:bell-bold",
        Duration = 4,
    })
end

-- ─────────────────────────────────────
--  PLOT DETECTION
-- ─────────────────────────────────────
local Plots  = workspace.Map.Plots
local myPlot = nil

for i = 1, 6 do
    local plot = Plots:FindFirstChild("Plot" .. i)
    if plot then
        local att = plot:FindFirstChild("HomeLabelAttachment")
        if att and #att:GetChildren() > 0 then
            myPlot = plot
            break
        end
    end
end

if not myPlot then
    Notify("Rex Hub", "❌ Твой плот не найден! Перезайди.", "alert-triangle")
    return
end

-- Stands на SeedRoller
local seedRoller = myPlot:FindFirstChild("SeedRoller")
local stands     = {}
if seedRoller then
    for i = 1, 6 do
        local stand = seedRoller:FindFirstChild("Stand" .. i)
        if stand then
            stands[i] = { index = i, position = stand:GetPivot().Position }
        end
    end
end

-- ─────────────────────────────────────
--  GAME FUNCTIONS
-- ─────────────────────────────────────

-- Возвращает { [seedName] = standIndex } для семян в мире
local function getWorldSeeds()
    local seeds = {}
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChild("BuySeed", true) then
            local seedPos = model:GetPivot().Position
            local bestStand, bestDist = nil, math.huge
            for _, st in pairs(stands) do
                local d = (
                    Vector3.new(seedPos.X, 0, seedPos.Z) -
                    Vector3.new(st.position.X, 0, st.position.Z)
                ).Magnitude
                if d < bestDist then
                    bestDist  = d
                    bestStand = st
                end
            end
            if bestStand and bestDist < 15 then
                seeds[model.Name] = bestStand.index
            end
        end
    end
    return seeds
end

-- FarmPlot-ы всех этажей
local function getFarmPlots()
    local out = {}
    for _, name in ipairs({ "FarmPlot", "SecondFloor", "ThirdFloor" }) do
        local node = myPlot:FindFirstChild(name)
        if node then
            local fp = (name == "FarmPlot") and node
                or node:FindFirstChild("FarmPlot")
            if fp then table.insert(out, fp) end
        end
    end
    return out
end

-- Удобрение из рюкзака
local FERTILIZER_NAMES = { "Normal Fertilizer", "Strong Fertilizer", "Super Fertilizer" }
local function getFertilizerFromBackpack()
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        for _, name in ipairs(FERTILIZER_NAMES) do
            if tool.Name:find(name, 1, true) then return tool end
        end
    end
    return nil
end

-- Первый незаудобренный dirt
local function getUnfertilizedDirt()
    for _, fp in ipairs(getFarmPlots()) do
        for _, plant in ipairs(fp:GetChildren()) do
            local dirt = plant:FindFirstChild("Dirt")
            if dirt and dirt:GetAttribute("PlantLevel") ~= nil then
                if not dirt:GetAttribute("Fertilized") then
                    return dirt
                end
            end
        end
    end
    return nil
end

-- Семена из UI игры (по редкости)
local rarityOrder = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary",
    "Divine", "Prismatic", "Secret", "Exotic", "Transcended",
}

local allSeedsByRarity = {}
for _, r in ipairs(rarityOrder) do allSeedsByRarity[r] = {} end

local seedScrollOk, seedScrollFrame = pcall(function()
    return player.PlayerGui.MainUI.Menus.IndexFrame.Main.ScrollingFrame
end)

if seedScrollOk and seedScrollFrame then
    for _, child in ipairs(seedScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            local sname  = child:FindFirstChild("SeedName")
            local rarity = child:FindFirstChild("RarityName")
            local name   = (sname and sname.Text ~= "???" and sname.Text) or child.Name
            local rar    = (rarity and rarity.Text) or "Common"
            local bucket = allSeedsByRarity[rar] or allSeedsByRarity["Common"]
            table.insert(bucket, name)
        end
    end
end

-- Плоский список всех семян (для Dropdown)
local allSeedNames = {}
for _, r in ipairs(rarityOrder) do
    for _, name in ipairs(allSeedsByRarity[r]) do
        table.insert(allSeedNames, name)
    end
end
if #allSeedNames == 0 then
    -- Заполним хотя бы что-то на случай если UI ещё не загрузился
    allSeedNames = { "Загрузи меню семян и перезапусти" }
end

-- Shop items
local shopScrollOk, shopScrollFrame = pcall(function()
    return player.PlayerGui.MainUI.Menus.GearShopFrame.ScrollingFrame
end)

local shopItems        = {}
local stockLabelByName = {}

if shopScrollOk and shopScrollFrame then
    for _, child in ipairs(shopScrollFrame:GetChildren()) do
        if child:IsA("ImageLabel") then
            local gearName  = child:FindFirstChild("GearName")
            local gearImage = child:FindFirstChild("GearImage")
            local rarLabel  = gearImage and gearImage:FindFirstChild("Rarity")
            if gearName then
                table.insert(shopItems, gearName.Text)
                stockLabelByName[gearName.Text] = rarLabel
            end
        end
    end
end
if #shopItems == 0 then
    shopItems = { "Открой магазин и перезапусти" }
end

local function parseStock(stockLabel)
    if not stockLabel then return 0 end
    return tonumber(stockLabel.Text:match("%d+")) or 0
end

-- ─────────────────────────────────────
--  STATE
-- ─────────────────────────────────────
local selectedSeeds = {}   -- set: { [seedName] = true }
local selectedGear  = {}   -- set: { [itemName] = true }

local buying        = false
local stopBuying    = false
local buyingShop    = false
local stopBuyingShop = false
local collecting    = false
local stopCollect   = false
local fertilizing   = false
local stopFertilize = false

local shopInterval  = 120
local targetLevel   = 10

-- ─────────────────────────────────────
--  TABS
-- ─────────────────────────────────────
local TSeeds  = Window:Tab({ Title = "Seeds",  Icon = "sprout"       })
local TShop   = Window:Tab({ Title = "Shop",   Icon = "shopping-bag" })
local TAuto   = Window:Tab({ Title = "Auto",   Icon = "play"         })
local TInfo   = Window:Tab({ Title = "Info",   Icon = "info"         })

-- ══════════════════════════════════════
--  SEEDS TAB
-- ══════════════════════════════════════

TSeeds:Dropdown({
    Title    = "Выбери семена (мульти-выбор)",
    Icon     = "list",
    Values   = allSeedNames,
    Value    = {},
    Flag     = "SeedSelection",
    Callback = function(vals)
        selectedSeeds = {}
        if type(vals) == "table" then
            for _, v in ipairs(vals) do
                selectedSeeds[v] = true
            end
        end
        local count = 0
        for _ in pairs(selectedSeeds) do count += 1 end
        Notify("Seeds", "✅ Выбрано семян: " .. count, "sprout")
    end,
})

TSeeds:Space()

TSeeds:Button({
    Title    = "Показать текущие семена в мире",
    Icon     = "search",
    Callback = function()
        local found = getWorldSeeds()
        local msg   = ""
        for name, idx in pairs(found) do
            msg = msg .. name .. " → Stand " .. idx .. "\n"
        end
        Notify("Семена в мире", msg == "" and "Ничего не найдено" or msg, "sprout")
    end,
})

-- ══════════════════════════════════════
--  SHOP TAB
-- ══════════════════════════════════════

TShop:Dropdown({
    Title    = "Выбери шмот для авто-покупки",
    Icon     = "package",
    Values   = shopItems,
    Value    = {},
    Flag     = "GearSelection",
    Callback = function(vals)
        selectedGear = {}
        if type(vals) == "table" then
            for _, v in ipairs(vals) do
                selectedGear[v] = true
            end
        end
        local count = 0
        for _ in pairs(selectedGear) do count += 1 end
        Notify("Shop", "✅ Выбрано предметов: " .. count, "shopping-bag")
    end,
})

TShop:Space()

TShop:Button({
    Title    = "Купить выбранный шмот сейчас",
    Icon     = "shopping-cart",
    Callback = function()
        if next(selectedGear) == nil then
            Notify("Shop", "⚠️ Ничего не выбрано!", "alert-triangle")
            return
        end
        task.spawn(function()
            for itemName in pairs(selectedGear) do
                local stock = parseStock(stockLabelByName[itemName])
                if stock > 0 then
                    for i = 1, stock do
                        local ok = pcall(function()
                            ReplicatedStorage.Remotes.Gear.Transaction:InvokeServer(itemName)
                        end)
                        if ok then
                            Notify("Куплено!", itemName .. " (" .. i .. "/" .. stock .. ")", "check-circle")
                        end
                        task.wait(0.1)
                    end
                else
                    Notify("Shop", "📦 " .. itemName .. " — нет в наличии", "info")
                end
            end
        end)
    end,
})

-- ══════════════════════════════════════
--  AUTO TAB
-- ══════════════════════════════════════

-- ── Auto-Buy Seeds ───────────────────
TAuto:Toggle({
    Title    = "Auto-Buy Seeds",
    Icon     = "refresh-cw",
    Value    = false,
    Flag     = "AutoBuySeeds",
    Callback = function(v)
        if v then
            if buying then return end
            buying = true; stopBuying = false
            Notify("Auto Seeds", "✅ Запущен", "sprout")
            task.spawn(function()
                while not stopBuying do
                    if next(selectedSeeds) == nil then
                        task.wait(1); continue
                    end
                    -- Роллим машину
                    pcall(function()
                        ReplicatedStorage.Remotes.RollSeeds:FireServer()
                    end)
                    task.wait(3)
                    -- Покупаем совпадающие семена
                    local worldSeeds = getWorldSeeds()
                    for seedName, standIdx in pairs(worldSeeds) do
                        if stopBuying then break end
                        if selectedSeeds[seedName] then
                            pcall(function()
                                ReplicatedStorage.Remotes.BuySeed:FireServer(standIdx)
                            end)
                            Notify("Куплено! 🌱", seedName .. " → Stand " .. standIdx, "check-circle")
                            task.wait(0.5)
                        end
                    end
                end
                buying = false
            end)
        else
            stopBuying = true
            Notify("Auto Seeds", "⛔ Остановлен", "x-circle")
        end
    end,
})

TAuto:Space()

-- ── Auto-Buy Shop ────────────────────
TAuto:Slider({
    Title = "Shop Scan Interval (sec)",
    Icon  = "timer",
    Step  = 5,
    Value = { Min = 10, Max = 300, Default = 120 },
    Flag  = "ShopInterval",
    Callback = function(v)
        shopInterval = v
    end,
})

TAuto:Toggle({
    Title    = "Auto-Buy Shop",
    Icon     = "shopping-bag",
    Value    = false,
    Flag     = "AutoBuyShop",
    Callback = function(v)
        if v then
            if buyingShop then return end
            buyingShop = true; stopBuyingShop = false
            Notify("Auto Shop", "✅ Запущен", "shopping-bag")
            task.spawn(function()
                while not stopBuyingShop do
                    if next(selectedGear) ~= nil then
                        for itemName in pairs(selectedGear) do
                            if stopBuyingShop then break end
                            local stock = parseStock(stockLabelByName[itemName])
                            if stock > 0 then
                                for i = 1, stock do
                                    if stopBuyingShop then break end
                                    local ok = pcall(function()
                                        ReplicatedStorage.Remotes.Gear.Transaction:InvokeServer(itemName)
                                    end)
                                    if ok then
                                        Notify("Куплено!", itemName .. " (" .. i .. "/" .. stock .. ")", "check-circle")
                                    end
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                    -- Ждём до следующего скана
                    local elapsed = 0
                    while elapsed < shopInterval and not stopBuyingShop do
                        task.wait(1); elapsed += 1
                    end
                end
                buyingShop = false
            end)
        else
            stopBuyingShop = true
            Notify("Auto Shop", "⛔ Остановлен", "x-circle")
        end
    end,
})

TAuto:Space()

-- ── Auto-Collect (Sell Crates) ───────
TAuto:Toggle({
    Title    = "Auto-Collect (Sell Crates)",
    Icon     = "package",
    Value    = false,
    Flag     = "AutoCollect",
    Callback = function(v)
        if v then
            if collecting then return end
            collecting = true; stopCollect = false
            Notify("Auto Collect", "✅ Запущен", "package")
            task.spawn(function()
                while not stopCollect do
                    pcall(function()
                        ReplicatedStorage.Remotes.SellCrates:FireServer()
                    end)
                    Notify("Собрано!", "💰 Ящики проданы", "check-circle")
                    task.wait(120)
                end
                collecting = false
            end)
        else
            stopCollect = true
            Notify("Auto Collect", "⛔ Остановлен", "x-circle")
        end
    end,
})

TAuto:Space()

-- ── Auto-Upgrade Plants ──────────────
TAuto:Slider({
    Title = "Target Plant Level",
    Icon  = "trending-up",
    Step  = 1,
    Value = { Min = 1, Max = 75, Default = 10 },
    Flag  = "TargetLevel",
    Callback = function(v)
        targetLevel = v
    end,
})

TAuto:Button({
    Title    = "▶ Upgrade All Plants",
    Icon     = "arrow-up-circle",
    Callback = function()
        local farmPlots = getFarmPlots()
        if #farmPlots == 0 then
            Notify("Upgrade", "❌ FarmPlot не найден!", "alert-triangle")
            return
        end
        task.spawn(function()
            local upgraded = 0
            for _, fp in ipairs(farmPlots) do
                for _, plant in ipairs(fp:GetChildren()) do
                    local dirt = plant:FindFirstChild("Dirt")
                    if dirt and dirt:GetAttribute("PlantLevel") ~= nil then
                        local lvl = dirt:GetAttribute("PlantLevel") or 0
                        while lvl < targetLevel do
                            pcall(function()
                                ReplicatedStorage.Remotes.UpgradePlant:InvokeServer(dirt)
                            end)
                            task.wait(0.1)
                            lvl = dirt:GetAttribute("PlantLevel") or 0
                        end
                        upgraded += 1
                    end
                end
            end
            Notify("Upgrade Done!", upgraded .. " растений → уровень " .. targetLevel, "check-circle")
        end)
    end,
})

TAuto:Space()

-- ── Auto-Fertilizer ──────────────────
TAuto:Toggle({
    Title    = "Auto-Fertilizer",
    Icon     = "droplets",
    Value    = false,
    Flag     = "AutoFertilizer",
    Callback = function(v)
        if v then
            if fertilizing then return end
            fertilizing = true; stopFertilize = false
            Notify("Auto Fertilizer", "✅ Запущен", "droplets")
            task.spawn(function()
                while not stopFertilize do
                    local tool = getFertilizerFromBackpack()
                    if tool then
                        local dirt = getUnfertilizedDirt()
                        if dirt then
                            pcall(function()
                                humanoid:EquipTool(tool)
                                task.wait(0.5)
                                ReplicatedStorage.Remotes.UseFertilizer:FireServer(dirt)
                                task.wait(0.5)
                                humanoid:UnequipTools()
                                task.wait(0.1)
                            end)
                        else
                            task.wait(5) -- все растения удобрены
                        end
                    else
                        task.wait(5) -- нет удобрений в рюкзаке
                    end
                end
                fertilizing = false
            end)
        else
            stopFertilize = true
            Notify("Auto Fertilizer", "⛔ Остановлен", "x-circle")
        end
    end,
})

-- ══════════════════════════════════════
--  INFO TAB
-- ══════════════════════════════════════

TInfo:Button({
    Title    = "📍 Твой плот: " .. myPlot.Name,
    Icon     = "map-pin",
    Callback = function()
        Notify("Плот", "Текущий плот: " .. myPlot.Name, "map-pin")
    end,
})

TInfo:Space()

TInfo:Button({
    Title    = "Семян в выбранных: проверить",
    Icon     = "list",
    Callback = function()
        local count = 0
        for _ in pairs(selectedSeeds) do count += 1 end
        Notify("Seeds", "Выбрано семян: " .. count, "sprout")
    end,
})

TInfo:Button({
    Title    = "Шмота в выбранных: проверить",
    Icon     = "list",
    Callback = function()
        local count = 0
        for _ in pairs(selectedGear) do count += 1 end
        Notify("Shop", "Выбрано предметов: " .. count, "shopping-bag")
    end,
})

TInfo:Space()

TInfo:Button({
    Title    = "FarmPlots на плоте: проверить",
    Icon     = "layers",
    Callback = function()
        local fps = getFarmPlots()
        Notify("FarmPlots", "Найдено этажей: " .. #fps, "layers")
    end,
})

-- ─────────────────────────────────────
--  READY
-- ─────────────────────────────────────
WindUI:Notify({
    Title    = "Rex Hub",
    Content  = "Build-A-Ring-Farm загружен! Плот: " .. myPlot.Name,
    Icon     = "leaf",
    Duration = 6,
})
