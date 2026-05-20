--[[
  ██████╗ ███████╗██╗  ██╗    ██╗  ██╗██╗   ██╗██████╗
  ██╔══██╗██╔════╝╚██╗██╔╝    ██║  ██║██║   ██║██╔══██╗
  ██████╔╝█████╗   ╚███╔╝     ███████║██║   ██║██████╔╝
  ██╔══██╗██╔══╝   ██╔██╗     ██╔══██║██║   ██║██╔══██╗
  ██║  ██║███████╗██╔╝ ██╗    ██║  ██║╚██████╔╝██████╔╝
  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
  Rex Hub | Slime RNG Edition
  UI: WindUI by Footagesus
--]]

repeat task.wait() until game:IsLoaded()

-- ─────────────────────────────────────
--  SERVICES
-- ─────────────────────────────────────
local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local lp          = Players.LocalPlayer

-- Anti-AFK
lp.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ─────────────────────────────────────
--  HRP HELPER (auto-refresh on respawn)
-- ─────────────────────────────────────
local function getHRP()
    local char = workspace:FindFirstChild(lp.Name)
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ─────────────────────────────────────
--  REMOTE HELPER
-- ─────────────────────────────────────
local NET = RS
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("leifstout_networker@0.3.1")
    :WaitForChild("networker")
    :WaitForChild("_remotes")

local function invoke(serviceName, ...)
    local args = { ... }
    local ok, err = pcall(function()
        NET:WaitForChild(serviceName)
            :WaitForChild("RemoteFunction")
            :InvokeServer(unpack(args))
    end)
    if not ok then
        warn("[Rex Hub] " .. serviceName .. ": " .. tostring(err))
    end
end

-- ─────────────────────────────────────
--  GAME FUNCTIONS  (оригинальная логика)
-- ─────────────────────────────────────

-- Roll — читает текущую скорость ролла прямо из UI игры
local function getRollSpeed()
    local ok, val = pcall(function()
        return tonumber(string.match(
            lp.PlayerGui.Root.BottomBarStats
                .StatsList.RollSpeedStat.Content.Value.TextLabel.Text,
            "[%d%.]+"
        ))
    end)
    return (ok and val) and val or 1
end

local function Roll()
    invoke("RollService", "requestRoll")
end

-- Index — клеймит все тиры
local function ClaimIndex()
    for _, tier in ipairs({ "basic", "big", "huge", "shiny", "inverted" }) do
        invoke("IndexService", "requestClaimReward", tier)
        task.wait(0.1)
    end
end

-- Potions — использует все бусты
local function ConsumePotions()
    for _, boost in ipairs({ "luck", "ultraLuck", "currency", "rollSpeed" }) do
        invoke("BoostService", "requestUseBoost", boost)
    end
end

-- Teleport по номеру зоны
local function Teleport(worldNum)
    invoke("ZonesService", "requestTeleportZone", worldNum)
end

-- Teleport в лучшую разблокированную зону (оригинальный алгоритм)
local function TeleportBestZone()
    local zonesFolder = workspace:FindFirstChild("Zones")
    if not zonesFolder then return end

    local gateList = {}
    for _, zone in pairs(zonesFolder:GetChildren()) do
        local gate = zone:FindFirstChild("Gate")
        if gate then
            local blocker = gate:FindFirstChild("ClientGateBlocker_" .. zone.Name)
            if blocker then
                table.insert(gateList, blocker)
            end
        end
    end

    local best = 0
    for _, blocker in pairs(gateList) do
        if not blocker.CanCollide then
            local num = tonumber(blocker.Parent.Parent.Name)
            if num and num > best then best = num end
        end
    end

    Teleport(best + 1)
end

-- Collect drops — телепортирует дропы к игроку и собирает
local function CollectDrops()
    local hrp  = getHRP()
    local loot = workspace:FindFirstChild("Loot")
    if not hrp or not loot then return end

    for _, drop in pairs(loot:GetChildren()) do
        if drop and drop:FindFirstChild("Root") then
            drop.Root.CFrame = CFrame.new(
                hrp.CFrame.X, hrp.CFrame.Y, hrp.CFrame.Z
            )
            local att = drop.Root:FindFirstChild("Attachment")
            if att then
                local prox = att:FindFirstChild("ProximityPrompt")
                if prox then fireproximityprompt(prox) end
            end
            task.wait(0.3)
        end
    end
end

-- Upgrade — парсит тайлы апгрейдов и покупает доступные
local function getUpgradeTiles()
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local root    = pg:FindFirstChild("Root")
    local screen  = root and root:FindFirstChild("UpgradeScreen")
    local content = screen and screen:FindFirstChild("UpgradeContent")
    local frame   = content and content:FindFirstChild("Frame")
    return frame and frame:GetChildren()
end

local function Upgrade()
    local tiles = getUpgradeTiles()
    if not tiles then return end

    for _, tile in pairs(tiles) do
        if tile.Name == "UIAspectRatioConstraint"
        or tile.Name == "UpgradeHoverInfo" then continue end

        local img = tile:FindFirstChild("ImageLabel")
        if not img then continue end
        if img.Image ~= "rbxassetid://127271823919078" then continue end

        for _, label in pairs(img:GetChildren()) do
            if label.Name ~= "TextLabelFrame" then continue end
            local prefix = label:FindFirstChild("Prefix")
            local tl     = label:FindFirstChild("TextLabel")
            if prefix and tl and tl.TextColor3:ToHex() ~= "ff2d49" then
                local upgradeName = tile.Name:match("^(%S+)Tile")
                if upgradeName then
                    invoke("UpgradeService", "requestUnlock", upgradeName)
                end
            end
        end
    end
end

-- Slime Gun — стреляет по всем врагам
local function FindGameplayFolder()
    for _, v in workspace:GetChildren() do
        if v.Name:match("Gameplay%d*") then return v end
    end
end

local function FindEnemies()
    local gp = FindGameplayFolder()
    if not gp or not gp:FindFirstChild("Enemies") then return {} end
    return gp.Enemies:GetChildren()
end

local function FireSlimeGun(id)
    invoke("SlimeGunService", "tryFireSlimeGun", id)
end

-- ─────────────────────────────────────
--  WEBHOOK
-- ─────────────────────────────────────
local webhookUrl      = ""
local webhookInterval = 30

local function buildEmbed(data)
    return HttpService:JSONEncode({
        embeds = {{
            title       = data.title or "Rex Hub",
            description = data.description or "",
            color       = 0x7B68EE,   -- фиолетовый
            footer      = { text = "Rex Hub • Slime RNG" },
            timestamp   = DateTime.now():ToIsoDate(),
        }},
        attachments = {},
    })
end

local function sendWebhook(data)
    if webhookUrl == "" then return end
    pcall(function()
        request({
            Url     = webhookUrl,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = buildEmbed(data),
        })
    end)
end

-- ─────────────────────────────────────
--  WIND UI
-- ─────────────────────────────────────
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title  = "Rex Hub",
    Icon   = "shield",
    Theme  = "Dark",
    Folder = "RexHub",
})

local function Notify(title, content)
    WindUI:Notify({
        Title    = title,
        Content  = content or "",
        Icon     = "solar:bell-bold",
        Duration = 4,
    })
end

-- Табы
local TMain     = Window:Tab({ Title = "Main",     Icon = "play"        })
local TUpgrades = Window:Tab({ Title = "Upgrades", Icon = "trending-up" })
local TWebhook  = Window:Tab({ Title = "Webhook",  Icon = "link"        })

-- ─────────────────────────────────────
--  STATE
-- ─────────────────────────────────────
local S = {
    AutoRoll         = false,
    AutoIndex        = false,
    AutoDrops        = false,
    AutoPotions      = false,
    AutoSlimeGun     = false,
    AutoBestZone     = false,
    AutoUpgrade      = false,
    AutoBuyZone      = false,
    AutoRebirth      = false,
    AutoEquipBest    = false,
    Webhook          = false,
    BestZoneInterval = 30,
    UpgradeInterval  = 30,
}

-- ─────────────────────────────────────
--  MAIN TAB
-- ─────────────────────────────────────

-- ── Роллинг ──────────────────────────
TMain:Toggle({
    Title    = "Auto Roll",
    Icon     = "refresh-cw",
    Value    = false,
    Flag     = "AutoRoll",
    Callback = function(v)
        S.AutoRoll = v
        Notify("Auto Roll", v and "✅ Включён" or "⛔ Выключен")
        if not v then return end
        task.spawn(function()
            while S.AutoRoll do
                task.wait(getRollSpeed())
                Roll()
            end
        end)
    end,
})

TMain:Space()

-- ── Индекс ───────────────────────────
TMain:Toggle({
    Title    = "Auto Index Claim",
    Icon     = "archive",
    Value    = false,
    Flag     = "AutoIndex",
    Callback = function(v)
        S.AutoIndex = v
        Notify("Auto Index", v and "✅ Включён" or "⛔ Выключен")
        if not v then return end
        task.spawn(function()
            while S.AutoIndex do
                ClaimIndex()
                task.wait(30)
            end
        end)
    end,
})

TMain:Space()

-- ── Дропы ────────────────────────────
TMain:Toggle({
    Title    = "Auto Collect Drops",
    Icon     = "package",
    Value    = false,
    Flag     = "AutoDrops",
    Callback = function(v)
        S.AutoDrops = v
        Notify("Auto Drops", v and "✅ Включён" or "⛔ Выключен")
        if not v then return end
        task.spawn(function()
            while S.AutoDrops do
                pcall(CollectDrops)
                task.wait()
            end
        end)
    end,
})

TMain:Space()

-- ── Зелья ────────────────────────────
TMain:Toggle({
    Title    = "Auto Potions",
    Icon     = "flask-conical",
    Value    = false,
    Flag     = "AutoPotions",
    Callback = function(v)
        S.AutoPotions = v
        Notify("Auto Potions", v and "✅ Включён" or "⛔ Выключен")
        if not v then return end
        task.spawn(function()
            while S.AutoPotions do
                ConsumePotions()
                task.wait(3)
            end
        end)
    end,
})

TMain:Space()

-- ── Slime Gun ─────────────────────────
TMain:Toggle({
    Title    = "Auto Slime Gun",
    Icon     = "zap",
    Value    = false,
    Flag     = "AutoSlimeGun",
    Callback = function(v)
        S.AutoSlimeGun = v
        Notify("Auto Slime Gun", v and "✅ Включён" or "⛔ Выключен")
        if not v then return end
        task.spawn(function()
            while S.AutoSlimeGun do
                local ok, err = pcall(function()
                    for _, enemy in pairs(FindEnemies()) do
                        if enemy and enemy.Parent then
                            repeat
                                FireSlimeGun(tonumber(enemy.Name))
                                task.wait(0.05)
                            until not enemy.Parent or not S.AutoSlimeGun
                        end
                    end
                end)
                if not ok then warn("[Rex Hub] SlimeGun: " .. tostring(err)) end
                task.wait()
            end
        end)
    end,
})

TMain:Space()

-- ── Лучшая зона ──────────────────────
TMain:Toggle({
    Title    = "Auto Best Zone",
    Icon     = "map-pin",
    Value    = false,
    Flag     = "AutoBestZone",
    Callback = function(v)
        S.AutoBestZone = v
        Notify("Auto Best Zone", v and "✅ Включён" or "⛔ Выключен")
        if not v then return end
        task.spawn(function()
            while S.AutoBestZone do
                pcall(TeleportBestZone)
                task.wait(S.BestZoneInterval)
            end
        end)
    end,
})

TMain:Input({
    Title       = "Best Zone Interval (sec)",
    Icon        = "timer",
    Value       = "30",
    Placeholder = "Секунды (по умолч. 30)",
    Numeric     = true,
    Flag        = "BestZoneInterval",
    Callback    = function(v)
        S.BestZoneInterval = tonumber(v) or 30
    end,
})

-- ─────────────────────────────────────
--  UPGRADES TAB
-- ─────────────────────────────────────

-- ── Авто-апгрейд ─────────────────────
TUpgrades:Toggle({
    Title    = "Auto Upgrade",
    Icon     = "trending-up",
    Value    = false,
    Flag     = "AutoUpgrade",
    Callback = function(v)
        S.AutoUpgrade = v
        Notify("Auto Upgrade", v and "✅ Включён" or "⛔ Выключен")
        if not v then return end
        task.spawn(function()
            while S.AutoUpgrade do
                pcall(Upgrade)
                task.wait(S.UpgradeInterval)
            end
        end)
    end,
})

TUpgrades:Input({
    Title       = "Upgrade Interval (sec)",
    Icon        = "timer",
    Value       = "30",
    Placeholder = "Секунды (по умолч. 30)",
    Numeric     = true,
    Flag        = "UpgradeInterval",
    Callback    = function(v)
        S.UpgradeInterval = tonumber(v) or 30
    end,
})

TUpgrades:Space()

-- ── Покупка зон ──────────────────────
TUpgrades:Toggle({
    Title    = "Auto Buy Zone",
    Icon     = "map",
    Value    = false,
    Flag     = "AutoBuyZone",
    Callback = function(v)
        S.AutoBuyZone = v
        Notify("Auto Buy Zone", v and "✅ Включён" or "⛔ Выключен")
        if not v then return end
        task.spawn(function()
            while S.AutoBuyZone do
                invoke("ZonesService", "requestPurchaseZone")
                task.wait(5)
            end
        end)
    end,
})

TUpgrades:Space()

-- ── Ребёрс ───────────────────────────
TUpgrades:Toggle({
    Title    = "Auto Rebirth",
    Icon     = "rotate-ccw",
    Value    = false,
    Flag     = "AutoRebirth",
    Callback = function(v)
        S.AutoRebirth = v
        Notify("Auto Rebirth", v and "✅ Включён" or "⛔ Выключен")
        if not v then return end
        task.spawn(function()
            while S.AutoRebirth do
                Notify("Rebirth", "Выполняю ребёрс...")
                invoke("RebirthService", "requestRebirth")
                task.wait(5)
            end
        end)
    end,
})

TUpgrades:Space()

-- ── Авто-экип лучшего ────────────────
TUpgrades:Toggle({
    Title    = "Auto Equip Best",
    Icon     = "star",
    Value    = false,
    Flag     = "AutoEquipBest",
    Callback = function(v)
        S.AutoEquipBest = v
        Notify("Auto Equip Best", v and "✅ Включён" or "⛔ Выключен")
        if not v then return end
        task.spawn(function()
            while S.AutoEquipBest do
                invoke("InventoryService", "requestEquipBest")
                task.wait(10)
                Notify("Equip Best", "Лучшие питомцы экипированы!")
            end
        end)
    end,
})

-- ─────────────────────────────────────
--  WEBHOOK TAB
-- ─────────────────────────────────────

TWebhook:Input({
    Title       = "Discord Webhook URL",
    Icon        = "link",
    Value       = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric     = false,
    Flag        = "WebhookUrl",
    Callback    = function(v)
        webhookUrl = v
    end,
})

TWebhook:Space()

TWebhook:Input({
    Title       = "Интервал отправки (sec)",
    Icon        = "timer",
    Value       = "30",
    Placeholder = "Секунды",
    Numeric     = true,
    Flag        = "WebhookInterval",
    Callback    = function(v)
        webhookInterval = tonumber(v) or 30
    end,
})

TWebhook:Space()

TWebhook:Toggle({
    Title    = "Включить Webhook",
    Icon     = "send",
    Value    = false,
    Flag     = "Webhook",
    Callback = function(v)
        S.Webhook = v
        Notify("Webhook", v and "✅ Запущен" or "⛔ Остановлен")
        if not v then return end
        task.spawn(function()
            while S.Webhook do
                local rolls = "?"
                pcall(function()
                    rolls = workspace:FindFirstChild(lp.Name)
                        .HumanoidRootPart.TitleGui.NumRolls.Text
                end)
                sendWebhook({
                    title       = "📊 " .. lp.Name,
                    description = "Роллов накручено: **" .. rolls .. "**",
                })
                task.wait(webhookInterval)
            end
        end)
    end,
})

TWebhook:Space()

TWebhook:Button({
    Title    = "Тест Webhook",
    Icon     = "check-circle",
    Callback = function()
        if webhookUrl == "" then
            Notify("Webhook", "⚠️ Сначала введи URL!")
            return
        end
        sendWebhook({
            title       = "🛡️ Rex Hub — Test",
            description = "Webhook работает корректно! ✅",
        })
        Notify("Webhook", "Тест отправлен!")
    end,
})

-- ─────────────────────────────────────
--  ЗАГРУЗКА ЗАВЕРШЕНА
-- ─────────────────────────────────────
WindUI:Notify({
    Title    = "Rex Hub",
    Content  = "Slime RNG готов к работе!",
    Icon     = "shield",
    Duration = 6,
})
