-- Rex Hub | Slime RNG
-- UI: WindUI by Footagesus

repeat task.wait() until game:IsLoaded()

-- ══════════════════════════════════════
--              SERVICES
-- ══════════════════════════════════════

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local HttpService  = game:GetService("HttpService")
local VirtualUser  = game:GetService("VirtualUser")

local lp           = Players.LocalPlayer
local char         = workspace:FindFirstChild(lp.Name)
local hrp          = char and char:FindFirstChild("HumanoidRootPart")

-- Anti-AFK
lp.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ══════════════════════════════════════
--              WIND UI
-- ══════════════════════════════════════

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title  = "Rex Hub",
    Icon   = "shield",
    Theme  = "Dark",
    Folder = "RexHub",
})

-- Tabs
local TabMain     = Window:Tab({ Title = "Main",     Icon = "play"         })
local TabUpgrades = Window:Tab({ Title = "Upgrades", Icon = "arrow-up"     })
local TabWebhook  = Window:Tab({ Title = "Webhook",  Icon = "webhook"      })
local TabSettings = Window:Tab({ Title = "Settings", Icon = "settings"     })

-- ══════════════════════════════════════
--              REMOTES HELPER
-- ══════════════════════════════════════

local NET = RS
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("leifstout_networker@0.3.1")
    :WaitForChild("networker")
    :WaitForChild("_remotes")

local function invokeService(serviceName, ...)
    local args = { ... }
    local ok, err = pcall(function()
        NET:WaitForChild(serviceName):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
    end)
    if not ok then warn("[Rex Hub] " .. serviceName .. " error: " .. tostring(err)) end
end

-- ══════════════════════════════════════
--           GAME FUNCTIONS
-- ══════════════════════════════════════

local function Notify(title, content)
    WindUI:Notify({
        Title   = title,
        Content = content or "",
        Icon    = "solar:bell-bold",
        Duration = 4,
    })
end

local function Roll()
    invokeService("RollService", "requestRoll")
end

local function ClaimIndex()
    for _, tier in ipairs({ "basic", "big", "huge", "shiny", "inverted" }) do
        invokeService("IndexService", "requestClaimReward", tier)
        task.wait(0.1)
    end
end

local function ConsumePotions()
    for _, boostType in ipairs({ "luck", "ultraLuck", "currency", "rollSpeed" }) do
        invokeService("BoostService", "requestUseBoost", boostType)
    end
end

local function Teleport(worldNum)
    invokeService("ZonesService", "requestTeleportZone", worldNum)
end

local function TeleportBestZone()
    local zones = workspace:FindFirstChild("Zones")
    if not zones then return end
    local best = 0
    for _, zone in pairs(zones:GetChildren()) do
        local blockerName = "ClientGateBlocker_" .. zone.Name
        local gate = zone:FindFirstChild("Gate") and zone.Gate:FindFirstChild(blockerName)
        if gate and gate.CanCollide ~= true then
            local num = tonumber(zone.Name)
            if num and num > best then best = num end
        end
    end
    Teleport(best + 1)
end

local function CollectDrops()
    local loot = workspace:FindFirstChild("Loot")
    if not loot then return end
    -- refresh char ref each call
    char = workspace:FindFirstChild(lp.Name)
    hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, drop in pairs(loot:GetChildren()) do
        if drop and drop:FindFirstChild("Root") then
            drop.Root.CFrame = hrp.CFrame
            local prox = drop.Root:FindFirstChild("Attachment")
                and drop.Root.Attachment:FindFirstChild("ProximityPrompt")
            if prox then
                fireproximityprompt(prox)
            end
            task.wait(0.3)
        end
    end
end

local function getUpgradeTiles()
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local path = pg:FindFirstChild("Root")
        and pg.Root:FindFirstChild("UpgradeScreen")
        and pg.Root.UpgradeScreen:FindFirstChild("UpgradeContent")
        and pg.Root.UpgradeScreen.UpgradeContent:FindFirstChild("Frame")
    return path and path:GetChildren()
end

local function Upgrade()
    local tiles = getUpgradeTiles()
    if not tiles then return end
    for _, tile in pairs(tiles) do
        if tile.Name == "UIAspectRatioConstraint" or tile.Name == "UpgradeHoverInfo" then continue end
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
                    invokeService("UpgradeService", "requestUnlock", upgradeName)
                end
            end
        end
    end
end

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
    invokeService("SlimeGunService", "tryFireSlimeGun", id)
end

-- ══════════════════════════════════════
--         WEBHOOK HELPERS
-- ══════════════════════════════════════

local webhookUrl      = ""
local webhookInterval = 30

local function buildWebhookBody(data)
    return HttpService:JSONEncode({
        embeds = {{
            title       = data.title or "Rex Hub",
            description = data.description or "",
            color       = 5592575,
            footer      = { text = "Rex Hub | Slime RNG" },
            timestamp   = DateTime.now():ToIsoDate(),
        }},
        attachments = {},
    })
end

local function sendWebhook(url, data)
    if not url or url == "" then
        Notify("Webhook", "No URL set!")
        return
    end
    pcall(function()
        request({
            Url    = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body   = buildWebhookBody(data),
        })
    end)
end

-- ══════════════════════════════════════
--       TOGGLE STATE TABLE
-- ══════════════════════════════════════

local State = {
    AutoRoll          = false,
    AutoIndex         = false,
    AutoDrops         = false,
    AutoPotions       = false,
    AutoSlimeGun      = false,
    AutoUpgrade       = false,
    AutoBestZone      = false,
    AutoBuyZone       = false,
    AutoRebirth       = false,
    AutoEquipBest     = false,
    Webhook           = false,
    UpgradeInterval   = 30,
    BestZoneInterval  = 30,
}

-- ══════════════════════════════════════
--           MAIN TAB
-- ══════════════════════════════════════

TabMain:Toggle({
    Title    = "Auto Roll",
    Icon     = "refresh-cw",
    Value    = false,
    Flag     = "AutoRoll",
    Callback = function(v)
        State.AutoRoll = v
        Notify("Auto Roll", v and "Enabled" or "Disabled")
        if v then
            task.spawn(function()
                while State.AutoRoll do
                    local ok, speed = pcall(function()
                        return tonumber(string.match(
                            lp.PlayerGui.Root.BottomBarStats.StatsList
                                .RollSpeedStat.Content.Value.TextLabel.Text,
                            "[%d%.]+"
                        ))
                    end)
                    task.wait((ok and speed) and speed or 1)
                    Roll()
                end
            end)
        end
    end,
})

TabMain:Space()

TabMain:Toggle({
    Title    = "Auto Index Claim",
    Icon     = "archive",
    Value    = false,
    Flag     = "AutoIndex",
    Callback = function(v)
        State.AutoIndex = v
        Notify("Auto Index", v and "Enabled" or "Disabled")
        if v then
            task.spawn(function()
                while State.AutoIndex do
                    ClaimIndex()
                    task.wait(30)
                end
            end)
        end
    end,
})

TabMain:Space()

TabMain:Toggle({
    Title    = "Auto Collect Drops",
    Icon     = "package",
    Value    = false,
    Flag     = "AutoDrops",
    Callback = function(v)
        State.AutoDrops = v
        Notify("Auto Drops", v and "Enabled" or "Disabled")
        if v then
            task.spawn(function()
                while State.AutoDrops do
                    pcall(CollectDrops)
                    task.wait()
                end
            end)
        end
    end,
})

TabMain:Space()

TabMain:Toggle({
    Title    = "Auto Potions",
    Icon     = "flask-conical",
    Value    = false,
    Flag     = "AutoPotions",
    Callback = function(v)
        State.AutoPotions = v
        Notify("Auto Potions", v and "Enabled" or "Disabled")
        if v then
            task.spawn(function()
                while State.AutoPotions do
                    ConsumePotions()
                    task.wait(3)
                end
            end)
        end
    end,
})

TabMain:Space()

TabMain:Toggle({
    Title    = "Auto Slime Gun",
    Icon     = "zap",
    Value    = false,
    Flag     = "AutoSlimeGun",
    Callback = function(v)
        State.AutoSlimeGun = v
        Notify("Auto Slime Gun", v and "Enabled" or "Disabled")
        if v then
            task.spawn(function()
                while State.AutoSlimeGun do
                    pcall(function()
                        for _, enemy in pairs(FindEnemies()) do
                            if enemy and enemy.Parent then
                                repeat
                                    FireSlimeGun(tonumber(enemy.Name))
                                    task.wait(0.05)
                                until not enemy.Parent or not State.AutoSlimeGun
                            end
                        end
                    end)
                    task.wait()
                end
            end)
        end
    end,
})

TabMain:Space()

TabMain:Toggle({
    Title    = "Auto Best Zone",
    Icon     = "map-pin",
    Value    = false,
    Flag     = "AutoBestZone",
    Callback = function(v)
        State.AutoBestZone = v
        Notify("Auto Best Zone", v and "Enabled" or "Disabled")
        if v then
            task.spawn(function()
                while State.AutoBestZone do
                    TeleportBestZone()
                    task.wait(State.BestZoneInterval)
                end
            end)
        end
    end,
})

TabMain:Input({
    Title       = "Best Zone Interval (sec)",
    Icon        = "timer",
    Value       = "30",
    Placeholder = "Seconds",
    Numeric     = true,
    Flag        = "BestZoneInterval",
    Callback    = function(v)
        State.BestZoneInterval = tonumber(v) or 30
    end,
})

-- ══════════════════════════════════════
--         UPGRADES TAB
-- ══════════════════════════════════════

TabUpgrades:Toggle({
    Title    = "Auto Upgrade",
    Icon     = "trending-up",
    Value    = false,
    Flag     = "AutoUpgrade",
    Callback = function(v)
        State.AutoUpgrade = v
        Notify("Auto Upgrade", v and "Enabled" or "Disabled")
        if v then
            task.spawn(function()
                while State.AutoUpgrade do
                    Upgrade()
                    task.wait(State.UpgradeInterval)
                end
            end)
        end
    end,
})

TabUpgrades:Input({
    Title       = "Upgrade Interval (sec)",
    Icon        = "timer",
    Value       = "30",
    Placeholder = "Seconds",
    Numeric     = true,
    Flag        = "UpgradeInterval",
    Callback    = function(v)
        State.UpgradeInterval = tonumber(v) or 30
    end,
})

TabUpgrades:Space()

TabUpgrades:Toggle({
    Title    = "Auto Buy Zone",
    Icon     = "map",
    Value    = false,
    Flag     = "AutoBuyZone",
    Callback = function(v)
        State.AutoBuyZone = v
        Notify("Auto Buy Zone", v and "Enabled" or "Disabled")
        if v then
            task.spawn(function()
                while State.AutoBuyZone do
                    invokeService("ZonesService", "requestPurchaseZone")
                    task.wait(5)
                end
            end)
        end
    end,
})

TabUpgrades:Space()

TabUpgrades:Toggle({
    Title    = "Auto Rebirth",
    Icon     = "rotate-ccw",
    Value    = false,
    Flag     = "AutoRebirth",
    Callback = function(v)
        State.AutoRebirth = v
        Notify("Auto Rebirth", v and "Enabled" or "Disabled")
        if v then
            task.spawn(function()
                while State.AutoRebirth do
                    invokeService("RebirthService", "requestRebirth")
                    task.wait(5)
                end
            end)
        end
    end,
})

TabUpgrades:Space()

TabUpgrades:Toggle({
    Title    = "Auto Equip Best",
    Icon     = "star",
    Value    = false,
    Flag     = "AutoEquipBest",
    Callback = function(v)
        State.AutoEquipBest = v
        Notify("Auto Equip Best", v and "Enabled" or "Disabled")
        if v then
            task.spawn(function()
                while State.AutoEquipBest do
                    invokeService("InventoryService", "requestEquipBest")
                    task.wait(10)
                end
            end)
        end
    end,
})

-- ══════════════════════════════════════
--          WEBHOOK TAB
-- ══════════════════════════════════════

TabWebhook:Input({
    Title       = "Webhook URL",
    Icon        = "link",
    Value       = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric     = false,
    Flag        = "WebhookUrl",
    Callback    = function(v)
        webhookUrl = v
    end,
})

TabWebhook:Space()

TabWebhook:Input({
    Title       = "Send Interval (sec)",
    Icon        = "timer",
    Value       = "30",
    Placeholder = "Seconds",
    Numeric     = true,
    Flag        = "WebhookInterval",
    Callback    = function(v)
        webhookInterval = tonumber(v) or 30
    end,
})

TabWebhook:Space()

TabWebhook:Toggle({
    Title    = "Enable Webhook",
    Icon     = "webhook",
    Value    = false,
    Flag     = "Webhook",
    Callback = function(v)
        State.Webhook = v
        Notify("Webhook", v and "Started" or "Stopped")
        if v then
            task.spawn(function()
                while State.Webhook do
                    local rolls = ""
                    pcall(function()
                        rolls = workspace:FindFirstChild(lp.Name)
                            .HumanoidRootPart.TitleGui.NumRolls.Text
                    end)
                    sendWebhook(webhookUrl, {
                        title       = lp.Name,
                        description = "Rolls: " .. rolls,
                    })
                    task.wait(webhookInterval)
                end
            end)
        end
    end,
})

TabWebhook:Space()

TabWebhook:Button({
    Title    = "Test Webhook",
    Icon     = "send",
    Callback = function()
        sendWebhook(webhookUrl, {
            title       = "Rex Hub Test",
            description = "Webhook is working! ✅",
        })
        Notify("Webhook", "Test sent!")
    end,
})

-- ══════════════════════════════════════
--         READY NOTIFICATION
-- ══════════════════════════════════════

WindUI:Notify({
    Title    = "Rex Hub",
    Content  = "Slime RNG loaded successfully!",
    Icon     = "shield",
    Duration = 5,
})
