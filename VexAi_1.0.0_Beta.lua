local VexAi = {}

VexAi.Version = "1.0.0 Beta"
VexAi.ApiKey = "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"
VexAi.Model = "llama3-70b-8192"
VexAi.Running = true
VexAi.CurrentTab = "dashboard"
VexAi.AiDecisionInterval = 6
VexAi.LastDecision = ""
VexAi.LastReason = ""
VexAi.ActionQueue = {}
VexAi.ScriptSlots = {}
VexAi.Errors = {}

VexAi.Brain = {
    gameType = "Unknown",
    mapScan = {},
    nearbyEnemies = {},
    nearbyPlayers = {},
    nearbyItems = {},
    nearbyNPCs = {},
    playerStats = {},
    learnedPatterns = {},
    actionHistory = {},
    sessionStats = {
        kills = 0, deaths = 0, farmed = 0,
        quests = 0, collected = 0, errors = 0,
        aiCalls = 0, start = os.time()
    },
    tipQueue = {},
    knowledgeBase = {}
}

VexAi.Config = {
    AutoFarm = true,
    AutoQuest = true,
    AutoCollect = true,
    AutoDodge = true,
    AutoUpgrade = false,
    AntiAFK = true,
    SpeedHack = false,
    FlyMode = false,
    NoClip = false,
    InfJump = false,
    AutoHeal = true,
    GodMode = false,
    ShowESP = true,
    ShowTracers = false,
    TeleportToTarget = true,
    AiFarmInterval = 6,
    FarmRadius = 200,
    DodgeHPThreshold = 40,
    HealHPThreshold = 60,
}

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local HttpService    = game:GetService("HttpService")
local Workspace      = game:GetService("Workspace")
local CoreGui        = game:GetService("CoreGui")
local StarterGui     = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

local function safeGet(fn)
    local ok, v = pcall(fn)
    return ok and v or nil
end

local function getChar()
    return LP.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function dist(a, b)
    local ok, d = pcall(function()
        return (a.Position - b.Position).Magnitude
    end)
    return ok and d or 9999
end

local function logError(e)
    table.insert(VexAi.Errors, {t = os.time(), msg = tostring(e)})
    VexAi.Brain.sessionStats.errors = VexAi.Brain.sessionStats.errors + 1
    if #VexAi.Errors > 30 then table.remove(VexAi.Errors, 1) end
end

local function addHistory(action, result)
    table.insert(VexAi.Brain.actionHistory, {
        action = action, result = result, t = os.time()
    })
    if #VexAi.Brain.actionHistory > 60 then
        table.remove(VexAi.Brain.actionHistory, 1)
    end
end

local function scanWorld()
    local hrp = getHRP()
    if not hrp then return end

    VexAi.Brain.nearbyEnemies = {}
    VexAi.Brain.nearbyItems = {}
    VexAi.Brain.nearbyNPCs = {}
    VexAi.Brain.nearbyPlayers = {}
    VexAi.Brain.mapScan = {}

    local playerChars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then playerChars[p.Character] = p end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        local ok, _ = pcall(function()
            if obj:IsA("Model") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    local d = dist(hrp, root)
                    if d < VexAi.Config.FarmRadius then
                        if playerChars[obj] then
                            table.insert(VexAi.Brain.nearbyPlayers, {
                                model = obj, root = root,
                                dist = d, name = playerChars[obj].Name,
                                hp = hum.Health, maxhp = hum.MaxHealth
                            })
                        else
                            table.insert(VexAi.Brain.nearbyEnemies, {
                                model = obj, root = root,
                                dist = d, name = obj.Name,
                                hp = hum.Health, maxhp = hum.MaxHealth
                            })
                        end
                    end
                end
            elseif obj:IsA("BasePart") then
                local n = obj.Name:lower()
                local d = dist(hrp, obj)
                if d < 120 then
                    if n:find("drop") or n:find("coin") or n:find("gem") or
                       n:find("fruit") or n:find("chest") or n:find("reward") or
                       n:find("item") or n:find("loot") or n:find("money") or
                       n:find("cash") or n:find("orb") or n:find("shard") then
                        table.insert(VexAi.Brain.nearbyItems, {part = obj, dist = d, name = obj.Name})
                    end
                end
            end
        end)
    end

    table.sort(VexAi.Brain.nearbyEnemies, function(a, b) return a.dist < b.dist end)
    table.sort(VexAi.Brain.nearbyItems, function(a, b) return a.dist < b.dist end)

    local leaderstats = safeGet(function() return LP:FindFirstChild("leaderstats") end)
    VexAi.Brain.playerStats = {}
    if leaderstats then
        for _, v in ipairs(leaderstats:GetChildren()) do
            VexAi.Brain.playerStats[v.Name] = tostring(v.Value)
        end
    end

    local hum = getHum()
    if hum then
        VexAi.Brain.playerStats["HP"] = string.format("%.0f/%.0f", hum.Health, hum.MaxHealth)
        VexAi.Brain.playerStats["HPpct"] = string.format("%.0f", (hum.Health/hum.MaxHealth)*100)
    end
end

local function buildContext()
    local hrp = getHRP()
    local pos = hrp and hrp.Position or Vector3.new(0,0,0)
    local hum = getHum()
    local hp = hum and hum.Health or 0
    local maxhp = hum and hum.MaxHealth or 100
    local elapsed = os.time() - VexAi.Brain.sessionStats.start
    local statsStr = ""
    for k, v in pairs(VexAi.Brain.playerStats) do
        statsStr = statsStr .. k .. "=" .. v .. " "
    end
    local enemyStr = ""
    for i, e in ipairs(VexAi.Brain.nearbyEnemies) do
        if i > 3 then break end
        enemyStr = enemyStr .. string.format("[%s hp=%.0f dist=%.0f] ", e.name, e.hp, e.dist)
    end
    local itemStr = ""
    for i, it in ipairs(VexAi.Brain.nearbyItems) do
        if i > 3 then break end
        itemStr = itemStr .. string.format("[%s dist=%.0f] ", it.name, it.dist)
    end
    local patternSummary = ""
    for i = math.max(1, #VexAi.Brain.actionHistory - 5), #VexAi.Brain.actionHistory do
        local h = VexAi.Brain.actionHistory[i]
        if h then patternSummary = patternSummary .. h.action .. "=" .. h.result .. " " end
    end
    local s = VexAi.Brain.sessionStats
    return string.format(
        "Game=%s HP=%.0f/%.0f(%.0f%%) Pos=%.0f,%.0f,%.0f Enemies=%d[%s] Items=%d[%s] Stats=[%s] Session=kills:%d farm:%d quests:%d collect:%d errors:%d time:%ds RecentActions=[%s]",
        VexAi.Brain.gameType, hp, maxhp, (hp/maxhp)*100,
        pos.X, pos.Y, pos.Z,
        #VexAi.Brain.nearbyEnemies, enemyStr,
        #VexAi.Brain.nearbyItems, itemStr,
        statsStr,
        s.kills, s.farmed, s.quests, s.collected, s.errors, elapsed,
        patternSummary
    )
end

local function callGroq(userMsg, sysMsg)
    local ok, result = pcall(function()
        return request({
            Url = "https://api.groq.com/openai/v1/chat/completions",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer " .. VexAi.ApiKey,
            },
            Body = HttpService:JSONEncode({
                model = VexAi.Model,
                max_tokens = 512,
                temperature = 0.3,
                messages = {
                    { role = "system", content = sysMsg },
                    { role = "user", content = userMsg }
                }
            })
        })
    end)
    if not ok then logError("HTTP: " .. tostring(result)); return nil end
    if result and result.StatusCode == 200 then
        local d = safeGet(function() return HttpService:JSONDecode(result.Body) end)
        return d and d.choices and d.choices[1] and d.choices[1].message.content or nil
    end
    logError("API status: " .. tostring(result and result.StatusCode))
    return nil
end

local function askDecision()
    VexAi.Brain.sessionStats.aiCalls = VexAi.Brain.sessionStats.aiCalls + 1
    local ctx = buildContext()
    local sys = "You are VexAi, a Roblox game AI. Analyze the game state and respond ONLY with valid JSON. Format: {\"action\":\"farm|quest|collect|dodge|upgrade|explore|heal|wait\",\"target\":\"string or null\",\"reason\":\"short russian text\",\"priority\":1-10,\"next\":\"brief plan\"}"
    local raw = callGroq("Game state:\n" .. ctx .. "\n\nDecide the best single action now.", sys)
    if not raw then return nil end
    local cleanOk, parsed = pcall(function()
        local s = raw:match("{.+}")
        return s and HttpService:JSONDecode(s) or nil
    end)
    if cleanOk and parsed then return parsed end
    return { action = "wait", reason = raw:sub(1, 80), priority = 1 }
end

local function askChat(question)
    local sys = "Ты VexAi — умный игровой ИИ-ассистент для Roblox. Отвечай по-русски кратко и конкретно. Давай полезные игровые советы."
    return callGroq(question, sys) or "Ошибка соединения с ИИ."
end

local Actions = {}

Actions.farm = function(target)
    local hrp = getHRP()
    if not hrp then return "no_char" end
    local enemy = VexAi.Brain.nearbyEnemies[1]
    if not enemy then return "no_target" end
    if VexAi.Config.TeleportToTarget then
        local ok, _ = pcall(function()
            hrp.CFrame = CFrame.new(enemy.root.Position + Vector3.new(0, 3, 0))
        end)
        if not ok then return "tp_fail" end
    end
    pcall(function()
        local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
        if tool then
            local act = tool:FindFirstChildOfClass("RemoteEvent") or
                        tool:FindFirstChildOfClass("RemoteFunction")
            if act then act:FireServer() end
        end
    end)
    VexAi.Brain.sessionStats.farmed = VexAi.Brain.sessionStats.farmed + 1
    return "ok"
end

Actions.collect = function()
    local hrp = getHRP()
    if not hrp then return "no_char" end
    local collected = 0
    for _, item in ipairs(VexAi.Brain.nearbyItems) do
        if item.dist < 100 then
            pcall(function()
                hrp.CFrame = CFrame.new(item.part.Position + Vector3.new(0, 2, 0))
            end)
            collected = collected + 1
            wait(0.05)
        end
    end
    VexAi.Brain.sessionStats.collected = VexAi.Brain.sessionStats.collected + collected
    return collected > 0 and "ok" or "nothing"
end

Actions.quest = function()
    local hrp = getHRP()
    if not hrp then return "no_char" end
    local questNames = {"QuestGiver","NPC","Sensei","Master","Quest","Trainer","Elder","Villager","Captain","Commander"}
    for _, name in ipairs(questNames) do
        local found = nil
        local best = 500
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == name and obj:IsA("BasePart") then
                local d = dist(hrp, obj)
                if d < best then best = d; found = obj end
            end
        end
        if found then
            pcall(function()
                hrp.CFrame = CFrame.new(found.Position + Vector3.new(0, 3, 4))
                local model = found.Parent
                local rem = model:FindFirstChildOfClass("RemoteEvent", true)
                if rem then rem:FireServer("accept") end
            end)
            VexAi.Brain.sessionStats.quests = VexAi.Brain.sessionStats.quests + 1
            return "ok"
        end
    end
    return "no_npc"
end

Actions.dodge = function()
    local hrp = getHRP()
    if not hrp then return "no_char" end
    pcall(function()
        local back = hrp.CFrame.LookVector * -1
        hrp.CFrame = hrp.CFrame + back * 40 + Vector3.new(0, 5, 0)
    end)
    return "ok"
end

Actions.heal = function()
    pcall(function()
        local hum = getHum()
        if hum then hum.Health = hum.MaxHealth end
    end)
    return "ok"
end

Actions.explore = function()
    local hrp = getHRP()
    if not hrp then return "no_char" end
    pcall(function()
        local rng = Random.new()
        local x = rng:NextNumber(-100, 100)
        local z = rng:NextNumber(-100, 100)
        hrp.CFrame = hrp.CFrame + Vector3.new(x, 0, z)
    end)
    return "ok"
end

Actions.upgrade = function()
    local hrp = getHRP()
    if not hrp then return "no_char" end
    local shopNames = {"Shop","Upgrade","Store","Merchant","Blacksmith","Dealer"}
    for _, name in ipairs(shopNames) do
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == name and obj:IsA("BasePart") then
                local d = dist(hrp, obj)
                if d < 300 then
                    pcall(function()
                        hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 3))
                    end)
                    return "ok"
                end
            end
        end
    end
    return "no_shop"
end

Actions.wait = function() wait(1); return "ok" end

local function executeAction(decision)
    if not decision then return end
    local fn = Actions[decision.action] or Actions.wait
    local ok, res = pcall(fn, decision.target)
    local result = ok and (res or "ok") or ("err:" .. tostring(res))
    addHistory(decision.action, result)
    VexAi.LastDecision = decision.action
    VexAi.LastReason = decision.reason or ""
    if decision.action == "farm" and result == "ok" then
        VexAi.Brain.sessionStats.kills = VexAi.Brain.sessionStats.kills + 1
    end
    return result
end

local function detectGame()
    local known = {
        [2753915549] = "Blox Fruits",
        [1537690962] = "Arsenal",
        [6284583030] = "Pet Simulator X",
        [606849621]  = "Jailbreak",
        [292439477]  = "Adopt Me",
        [189707]     = "Natural Disaster",
        [3233893879] = "Brookhaven",
        [4924922222] = "Anime Fighting Sim",
        [2788229376] = "Shindo Life",
        [301549746]  = "Murder Mystery 2",
    }
    VexAi.Brain.gameType = known[game.PlaceId] or (game.Name ~= "" and game.Name or "Generic")
end

local function antiAFK()
    spawn(function()
        while true do
            wait(55 + math.random(0, 20))
            pcall(function()
                local cam = Workspace.CurrentCamera
                if cam then cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(0.5), 0) end
            end)
        end
    end)
end

local function speedHackLoop()
    spawn(function()
        while true do
            wait(0.1)
            if VexAi.Config.SpeedHack then
                pcall(function()
                    local hum = getHum()
                    if hum then hum.WalkSpeed = 80 end
                end)
            end
        end
    end)
end

local function flyLoop()
    spawn(function()
        local bodyVel, bodyGyro
        while true do
            wait(0.05)
            if VexAi.Config.FlyMode then
                pcall(function()
                    local hrp = getHRP()
                    if not hrp then return end
                    if not bodyVel or not bodyVel.Parent then
                        bodyVel = Instance.new("BodyVelocity")
                        bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
                        bodyVel.Parent = hrp
                    end
                    if not bodyGyro or not bodyGyro.Parent then
                        bodyGyro = Instance.new("BodyGyro")
                        bodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
                        bodyGyro.Parent = hrp
                    end
                    local camDir = Cam.CFrame.LookVector
                    bodyVel.Velocity = camDir * 50
                    bodyGyro.CFrame = Cam.CFrame
                end)
            else
                if bodyVel and bodyVel.Parent then bodyVel:Destroy() end
                if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy() end
                bodyVel = nil; bodyGyro = nil
            end
        end
    end)
end

local function infJumpLoop()
    spawn(function()
        while true do
            wait(0.1)
            if VexAi.Config.InfJump then
                pcall(function()
                    local hum = getHum()
                    if hum then hum:GetPropertyChangedSignal("Jump"):Connect(function()
                        if hum.Jump then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                    end) end
                end)
            end
        end
    end)
end

local function autoHealLoop()
    spawn(function()
        while true do
            wait(1)
            if VexAi.Config.AutoHeal and VexAi.Config.GodMode then
                pcall(function()
                    local hum = getHum()
                    if hum and (hum.Health / hum.MaxHealth) * 100 < VexAi.Config.HealHPThreshold then
                        hum.Health = hum.MaxHealth
                    end
                end)
            end
        end
    end)
end

local function espLoop()
    spawn(function()
        local espFolder = Instance.new("Folder")
        espFolder.Name = "VexAiESP"
        espFolder.Parent = Workspace
        while true do
            wait(0.5)
            pcall(function()
                for _, v in ipairs(espFolder:GetChildren()) do v:Destroy() end
                if not VexAi.Config.ShowESP then return end
                local hrp = getHRP()
                if not hrp then return end
                for _, e in ipairs(VexAi.Brain.nearbyEnemies) do
                    if e.root and e.root.Parent then
                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(0, 80, 0, 24)
                        bb.StudsOffset = Vector3.new(0, 3, 0)
                        bb.Adornee = e.root
                        bb.AlwaysOnTop = true
                        bb.Parent = espFolder
                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(1,0,1,0)
                        lbl.BackgroundTransparency = 1
                        lbl.Text = string.format("⚔ %s [%.0f%%]", e.name:sub(1,10), (e.hp/e.maxhp)*100)
                        lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
                        lbl.TextScaled = true
                        lbl.Font = Enum.Font.GothamBold
                        lbl.Parent = bb
                    end
                end
                for _, it in ipairs(VexAi.Brain.nearbyItems) do
                    if it.part and it.part.Parent then
                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(0, 70, 0, 20)
                        bb.StudsOffset = Vector3.new(0, 2, 0)
                        bb.Adornee = it.part
                        bb.AlwaysOnTop = true
                        bb.Parent = espFolder
                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(1,0,1,0)
                        lbl.BackgroundTransparency = 1
                        lbl.Text = "💎 " .. it.name:sub(1, 10)
                        lbl.TextColor3 = Color3.fromRGB(0, 255, 180)
                        lbl.TextScaled = true
                        lbl.Font = Enum.Font.GothamBold
                        lbl.Parent = bb
                    end
                end
            end)
        end
    end)
end

local function aiMainLoop()
    spawn(function()
        local lastAi = 0
        local lastCollect = 0
        local lastScan = 0
        while true do
            wait(0.5)
            if not VexAi.Running then wait(1); goto continue end
            local now = os.time()
            if now - lastScan >= 1 then
                pcall(scanWorld)
                lastScan = now
            end
            if VexAi.Config.AutoDodge then
                pcall(function()
                    local hum = getHum()
                    if hum and (hum.Health/hum.MaxHealth)*100 < VexAi.Config.DodgeHPThreshold then
                        executeAction({action="dodge", reason="HP низкий"})
                    end
                end)
            end
            if VexAi.Config.AutoCollect and (now - lastCollect >= 2) then
                pcall(function() executeAction({action="collect"}) end)
                lastCollect = now
            end
            if now - lastAi >= VexAi.Config.AiFarmInterval then
                local decision = pcall(function()
                    local d = askDecision()
                    if d then
                        table.insert(VexAi.Brain.tipQueue, d)
                        if #VexAi.Brain.tipQueue > 20 then table.remove(VexAi.Brain.tipQueue, 1) end
                        pcall(executeAction, d)
                    end
                end)
                lastAi = now
            end
            if VexAi.Config.AutoFarm and #VexAi.Brain.nearbyEnemies > 0 then
                pcall(function() executeAction({action="farm"}) end)
            end
            if VexAi.Config.AutoQuest and (now % 30 == 0) then
                pcall(function() executeAction({action="quest"}) end)
            end
            ::continue::
        end
    end)
end

local function createGUI()
    pcall(function()
        local old = CoreGui:FindFirstChild("VexAiMain")
        if old then old:Destroy() end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name = "VexAiMain"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    sg.Parent = CoreGui

    local COLORS = {
        bg       = Color3.fromRGB(8, 8, 16),
        panel    = Color3.fromRGB(13, 13, 26),
        panelB   = Color3.fromRGB(18, 18, 35),
        border   = Color3.fromRGB(50, 30, 120),
        accent   = Color3.fromRGB(110, 50, 255),
        accent2  = Color3.fromRGB(0, 220, 180),
        red      = Color3.fromRGB(255, 50, 80),
        green    = Color3.fromRGB(0, 255, 130),
        yellow   = Color3.fromRGB(255, 210, 50),
        text     = Color3.fromRGB(210, 210, 255),
        dim      = Color3.fromRGB(100, 100, 160),
        white    = Color3.fromRGB(255, 255, 255),
    }

    local W, H = 560, 420
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, W, 0, H)
    Main.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    Main.BackgroundColor3 = COLORS.bg
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = sg

    local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 12); mc.Parent = Main
    local ms = Instance.new("UIStroke"); ms.Color = COLORS.accent; ms.Thickness = 1.5; ms.Parent = Main

    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, 0, 0, 2)
    glow.Position = UDim2.new(0, 0, 0, 0)
    glow.BackgroundColor3 = COLORS.accent
    glow.BorderSizePixel = 0
    glow.Parent = Main
    local glowGrad = Instance.new("UIGradient")
    glowGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.accent),
        ColorSequenceKeypoint.new(0.5, COLORS.accent2),
        ColorSequenceKeypoint.new(1, COLORS.accent),
    })
    glowGrad.Parent = glow

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 36)
    TitleBar.BackgroundTransparency = 1
    TitleBar.Parent = Main

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0, 200, 1, 0)
    TitleLabel.Position = UDim2.new(0, 14, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "⚡ VexAi  " .. VexAi.Version
    TitleLabel.TextColor3 = COLORS.white
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    local StatusDot = Instance.new("Frame")
    StatusDot.Size = UDim2.new(0, 9, 0, 9)
    StatusDot.Position = UDim2.new(0, 200, 0.5, -4)
    StatusDot.BackgroundColor3 = COLORS.green
    StatusDot.BorderSizePixel = 0
    StatusDot.Parent = TitleBar
    Instance.new("UICorner").Parent = StatusDot

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -36, 0, 3)
    CloseBtn.BackgroundColor3 = COLORS.red
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = COLORS.white
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TitleBar
    Instance.new("UICorner").Parent = CloseBtn
    CloseBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -70, 0, 3)
    MinBtn.BackgroundColor3 = COLORS.yellow
    MinBtn.Text = "—"
    MinBtn.TextColor3 = Color3.fromRGB(20,20,20)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 14
    MinBtn.BorderSizePixel = 0
    MinBtn.Parent = TitleBar
    Instance.new("UICorner").Parent = MinBtn

    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Main.Size = minimized and UDim2.new(0, W, 0, 36) or UDim2.new(0, W, 0, H)
    end)

    local dragging, ds, sp = false, nil, nil
    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; ds = inp.Position; sp = Main.Position
        end
    end)
    TitleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - ds
            Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)

    local TABS = {"dashboard","tools","config","scripts","ai_chat","logs"}
    local TAB_ICONS = {dashboard="📊", tools="🔧", config="⚙️", scripts="📜", ai_chat="🤖", logs="📋"}
    local TAB_LABELS = {dashboard="Дашборд", tools="Инструменты", config="Настройки", scripts="Скрипты", ai_chat="ИИ Чат", logs="Логи"}

    local SideBar = Instance.new("Frame")
    SideBar.Size = UDim2.new(0, 90, 1, -36)
    SideBar.Position = UDim2.new(0, 0, 0, 36)
    SideBar.BackgroundColor3 = COLORS.panel
    SideBar.BorderSizePixel = 0
    SideBar.Parent = Main

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -90, 1, -36)
    Content.Position = UDim2.new(0, 90, 0, 36)
    Content.BackgroundColor3 = COLORS.panelB
    Content.BorderSizePixel = 0
    Content.Parent = Main

    local tabBtns = {}
    local tabPanels = {}

    for i, tabId in ipairs(TABS) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 56)
        btn.Position = UDim2.new(0, 0, 0, (i-1)*56 + 4)
        btn.BackgroundTransparency = 1
        btn.Text = TAB_ICONS[tabId] .. "\n" .. TAB_LABELS[tabId]
        btn.TextColor3 = COLORS.dim
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 10
        btn.BorderSizePixel = 0
        btn.Parent = SideBar
        tabBtns[tabId] = btn

        local panel = Instance.new("ScrollingFrame")
        panel.Name = tabId
        panel.Size = UDim2.new(1, 0, 1, 0)
        panel.BackgroundTransparency = 1
        panel.BorderSizePixel = 0
        panel.ScrollBarThickness = 3
        panel.ScrollBarImageColor3 = COLORS.accent
        panel.CanvasSize = UDim2.new(0, 0, 0, 0)
        panel.Visible = false
        panel.Parent = Content
        tabPanels[tabId] = panel
    end

    local function switchTab(id)
        VexAi.CurrentTab = id
        for tid, p in pairs(tabPanels) do p.Visible = (tid == id) end
        for tid, b in pairs(tabBtns) do
            b.TextColor3 = (tid == id) and COLORS.accent2 or COLORS.dim
            b.BackgroundTransparency = (tid == id) and 0.85 or 1
            if tid == id then b.BackgroundColor3 = COLORS.accent end
        end
    end

    for _, tabId in ipairs(TABS) do
        local id = tabId
        tabBtns[id].MouseButton1Click:Connect(function() switchTab(id) end)
    end

    local function mkLabel(parent, text, y, color, size, bold)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -16, 0, 20)
        l.Position = UDim2.new(0, 8, 0, y)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = color or COLORS.text
        l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextSize = size or 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = parent
        return l
    end

    local function mkCard(parent, y, h)
        local c = Instance.new("Frame")
        c.Size = UDim2.new(1, -16, 0, h or 60)
        c.Position = UDim2.new(0, 8, 0, y)
        c.BackgroundColor3 = COLORS.panel
        c.BorderSizePixel = 0
        c.Parent = parent
        Instance.new("UICorner").Parent = c
        local st = Instance.new("UIStroke"); st.Color = COLORS.border; st.Thickness = 1; st.Parent = c
        return c
    end

    local function mkToggle(parent, label, y, configKey)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -16, 0, 34)
        row.Position = UDim2.new(0, 8, 0, y)
        row.BackgroundColor3 = COLORS.panel
        row.BorderSizePixel = 0
        row.Parent = parent
        Instance.new("UICorner").Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = COLORS.text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local tog = Instance.new("TextButton")
        tog.Size = UDim2.new(0, 44, 0, 22)
        tog.Position = UDim2.new(1, -54, 0.5, -11)
        tog.BackgroundColor3 = VexAi.Config[configKey] and COLORS.green or COLORS.red
        tog.Text = VexAi.Config[configKey] and "ON" or "OFF"
        tog.TextColor3 = Color3.fromRGB(10,10,10)
        tog.Font = Enum.Font.GothamBold
        tog.TextSize = 11
        tog.BorderSizePixel = 0
        tog.Parent = row
        Instance.new("UICorner").Parent = tog

        tog.MouseButton1Click:Connect(function()
            VexAi.Config[configKey] = not VexAi.Config[configKey]
            tog.BackgroundColor3 = VexAi.Config[configKey] and COLORS.green or COLORS.red
            tog.Text = VexAi.Config[configKey] and "ON" or "OFF"
        end)
        return row
    end

    local function mkBtn(parent, text, y, color, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -16, 0, 32)
        b.Position = UDim2.new(0, 8, 0, y)
        b.BackgroundColor3 = color or COLORS.accent
        b.Text = text
        b.TextColor3 = COLORS.white
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.BorderSizePixel = 0
        b.Parent = parent
        Instance.new("UICorner").Parent = b
        b.MouseButton1Click:Connect(callback)
        return b
    end

    local function setCanvasY(panel, y)
        panel.CanvasSize = UDim2.new(0, 0, 0, y + 16)
    end

    do
        local p = tabPanels["dashboard"]
        mkLabel(p, "📊 ДАШБОРД — СТАТУС В РЕАЛЬНОМ ВРЕМЕНИ", 8, COLORS.accent2, 13, true)

        local statCard = mkCard(p, 32, 90)
        local killsL  = mkLabel(statCard, "⚔ Убийств: 0", 4,  COLORS.red, 12, true)
        local farmL   = mkLabel(statCard, "🌾 Фарм: 0", 22,  COLORS.yellow, 12, true)
        local questL  = mkLabel(statCard, "📜 Квесты: 0", 40, COLORS.accent2, 12, true)
        local collectL= mkLabel(statCard, "💎 Собрано: 0", 58, COLORS.green, 12, true)
        local callL   = mkLabel(statCard, "🤖 ИИ вызовов: 0", 76, COLORS.text, 12)

        local aiCard = mkCard(p, 132, 60)
        local aiActL = mkLabel(aiCard, "Действие: —", 4, COLORS.green, 12, true)
        local aiResL = mkLabel(aiCard, "Причина: ожидание...", 24, COLORS.dim, 11)
        local aiResL2= mkLabel(aiCard, "Следующее: —", 44, COLORS.dim, 11)

        local scanCard = mkCard(p, 202, 70)
        local enemL  = mkLabel(scanCard, "👾 Враги рядом: 0", 4, COLORS.red, 12, true)
        local itemL  = mkLabel(scanCard, "💎 Предметы: 0", 24, COLORS.green, 12, true)
        local gameL  = mkLabel(scanCard, "🎮 Игра: определение...", 44, COLORS.text, 12)

        local hpCard = mkCard(p, 282, 44)
        local hpL    = mkLabel(hpCard, "❤ HP: —", 4, COLORS.red, 13, true)
        local hpBar  = Instance.new("Frame")
        hpBar.Size = UDim2.new(0.8, 0, 0, 6)
        hpBar.Position = UDim2.new(0, 10, 0, 30)
        hpBar.BackgroundColor3 = COLORS.dim
        hpBar.BorderSizePixel = 0
        hpBar.Parent = hpCard
        Instance.new("UICorner").Parent = hpBar
        local hpFill = Instance.new("Frame")
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = COLORS.green
        hpFill.BorderSizePixel = 0
        hpFill.Parent = hpBar
        Instance.new("UICorner").Parent = hpFill

        local errCard = mkCard(p, 336, 36)
        local errL = mkLabel(errCard, "🛡 Ошибок: 0 | Uptime: 0s", 8, COLORS.dim, 11)

        setCanvasY(p, 380)

        spawn(function()
            while true do
                wait(0.5)
                pcall(function()
                    local s = VexAi.Brain.sessionStats
                    killsL.Text  = "⚔ Убийств: " .. s.kills
                    farmL.Text   = "🌾 Фарм: " .. s.farmed
                    questL.Text  = "📜 Квесты: " .. s.quests
                    collectL.Text= "💎 Собрано: " .. s.collected
                    callL.Text   = "🤖 ИИ вызовов: " .. s.aiCalls
                    aiActL.Text  = "Действие: " .. (VexAi.LastDecision ~= "" and VexAi.LastDecision or "ожидание")
                    aiResL.Text  = "Причина: " .. (VexAi.LastReason ~= "" and VexAi.LastReason:sub(1,50) or "—")
                    enemL.Text   = "👾 Враги рядом: " .. #VexAi.Brain.nearbyEnemies
                    itemL.Text   = "💎 Предметы: " .. #VexAi.Brain.nearbyItems
                    gameL.Text   = "🎮 Игра: " .. VexAi.Brain.gameType
                    local hum = getHum()
                    if hum then
                        local pct = hum.Health / hum.MaxHealth
                        hpL.Text = string.format("❤ HP: %.0f / %.0f", hum.Health, hum.MaxHealth)
                        hpFill.Size = UDim2.new(pct, 0, 1, 0)
                        hpFill.BackgroundColor3 = pct > 0.6 and COLORS.green or (pct > 0.3 and COLORS.yellow or COLORS.red)
                    end
                    local uptime = os.time() - s.start
                    errL.Text = string.format("🛡 Ошибок: %d | Uptime: %ds | Паттернов: %d", s.errors, uptime, #VexAi.Brain.actionHistory)
                    StatusDot.BackgroundColor3 = VexAi.Running and COLORS.green or COLORS.red
                end)
            end
        end)
    end

    do
        local p = tabPanels["tools"]
        mkLabel(p, "🔧 ИГРОВЫЕ ИНСТРУМЕНТЫ", 8, COLORS.accent2, 13, true)
        mkBtn(p, "⚡ Телепорт к ближайшему врагу", 32, COLORS.accent, function()
            pcall(function()
                local hrp = getHRP()
                local e = VexAi.Brain.nearbyEnemies[1]
                if hrp and e then hrp.CFrame = CFrame.new(e.root.Position + Vector3.new(0,4,0)) end
            end)
        end)
        mkBtn(p, "💎 Собрать весь дроп рядом", 72, COLORS.accent, function()
            pcall(function() executeAction({action="collect"}) end)
        end)
        mkBtn(p, "📜 Взять квест", 112, COLORS.accent, function()
            pcall(function() executeAction({action="quest"}) end)
        end)
        mkBtn(p, "⬆ Найти магазин / апгрейд", 152, COLORS.accent, function()
            pcall(function() executeAction({action="upgrade"}) end)
        end)
        mkBtn(p, "🏃 Уклониться (рывок назад)", 192, COLORS.yellow, function()
            pcall(function() executeAction({action="dodge"}) end)
        end)
        mkBtn(p, "❤ Хил (God Mode требуется)", 232, COLORS.green, function()
            pcall(function() executeAction({action="heal"}) end)
        end)
        mkBtn(p, "🔍 Исследовать карту (рандом)", 272, Color3.fromRGB(60,80,200), function()
            pcall(function() executeAction({action="explore"}) end)
        end)
        mkBtn(p, "🤖 Принудительный ИИ запрос", 312, Color3.fromRGB(120,40,200), function()
            spawn(function()
                pcall(function()
                    local d = askDecision()
                    if d then executeAction(d) end
                end)
            end)
        end)
        mkBtn(p, "🔄 Сброс персонажа", 352, COLORS.red, function()
            pcall(function() LP.Character:BreakJoints() end)
        end)
        setCanvasY(p, 395)
    end

    do
        local p = tabPanels["config"]
        mkLabel(p, "⚙️ НАСТРОЙКИ БОТА", 8, COLORS.accent2, 13, true)
        local y = 34
        local toggles = {
            {"🌾 Авто-Фарм",       "AutoFarm"},
            {"📜 Авто-Квесты",     "AutoQuest"},
            {"💎 Авто-Сбор",       "AutoCollect"},
            {"🏃 Авто-Уклонение",  "AutoDodge"},
            {"⬆ Авто-Апгрейд",    "AutoUpgrade"},
            {"🔄 Anti-AFK",        "AntiAFK"},
            {"⚡ SpeedHack (80)",   "SpeedHack"},
            {"✈ Fly Mode",         "FlyMode"},
            {"🔫 NoClip",          "NoClip"},
            {"🦘 Inf Jump",        "InfJump"},
            {"❤ Авто-Хил",        "AutoHeal"},
            {"🛡 God Mode",        "GodMode"},
            {"👁 ESP Враги/Дроп",  "ShowESP"},
            {"📍 Телепорт к цели", "TeleportToTarget"},
        }
        for _, t in ipairs(toggles) do
            mkToggle(p, t[1], y, t[2])
            y = y + 38
        end
        setCanvasY(p, y + 10)
    end

    do
        local p = tabPanels["scripts"]
        mkLabel(p, "📜 БЫСТРЫЙ ЗАПУСК СКРИПТОВ", 8, COLORS.accent2, 13, true)
        mkLabel(p, "Нажми кнопку — скрипт выполнится напрямую в игре", 28, COLORS.dim, 11)

        local scripts = {
            {"🍎 [BloxFruits] Авто-фарм боссов", [[
                while task.wait(0.1) do
                    local lp = game.Players.LocalPlayer
                    local char = lp.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            for _, v in ipairs(game.Workspace:GetDescendants()) do
                                if v:IsA("Model") and v:FindFirstChild("Humanoid") and not game.Players:GetPlayerFromCharacter(v) then
                                    hrp.CFrame = CFrame.new(v:FindFirstChild("HumanoidRootPart").Position + Vector3.new(0,3,0))
                                end
                            end
                        end
                    end
                end
            ]]},
            {"⚔ [Arsenal] Авто-прицел", [[
                local lp = game.Players.LocalPlayer
                game:GetService("RunService").RenderStepped:Connect(function()
                    local char = lp.Character
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    for _, p in ipairs(game.Players:GetPlayers()) do
                        if p ~= lp and p.Character then
                            local enemy_hrp = p.Character:FindFirstChild("HumanoidRootPart")
                            if enemy_hrp then
                                game.Workspace.CurrentCamera.CFrame = CFrame.new(game.Workspace.CurrentCamera.CFrame.Position, enemy_hrp.Position)
                            end
                        end
                    end
                end)
            ]]},
            {"💎 [Universal] Авто-сбор монет", [[
                while task.wait(0.05) do
                    local lp = game.Players.LocalPlayer
                    local char = lp.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            for _, v in ipairs(game.Workspace:GetDescendants()) do
                                if v:IsA("BasePart") then
                                    local n = v.Name:lower()
                                    if n:find("coin") or n:find("gem") or n:find("drop") or n:find("money") then
                                        hrp.CFrame = CFrame.new(v.Position)
                                    end
                                end
                            end
                        end
                    end
                end
            ]]},
            {"⚡ [Universal] Спидхак x5", [[
                game:GetService("RunService").Heartbeat:Connect(function()
                    local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = 100 end
                end)
            ]]},
            {"🛡 [Universal] God Mode (локальный)", [[
                game:GetService("RunService").Heartbeat:Connect(function()
                    local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = hum.MaxHealth end
                end)
            ]]},
            {"✈ [Universal] Fly Script", [[
                local lp = game.Players.LocalPlayer
                local uis = game:GetService("UserInputService")
                local flying = false
                local bv, bg
                uis.InputBegan:Connect(function(inp)
                    if inp.KeyCode == Enum.KeyCode.F then
                        flying = not flying
                        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        if flying and hrp then
                            bv = Instance.new("BodyVelocity",hrp)
                            bv.MaxForce = Vector3.new(1e5,1e5,1e5)
                            bg = Instance.new("BodyGyro",hrp)
                            bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
                        else
                            if bv then bv:Destroy() end
                            if bg then bg:Destroy() end
                        end
                    end
                end)
                game:GetService("RunService").Heartbeat:Connect(function()
                    if flying then
                        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and bv and bg then
                            local cam = game.Workspace.CurrentCamera
                            bv.Velocity = cam.CFrame.LookVector * 60
                            bg.CFrame = cam.CFrame
                        end
                    end
                end)
            ]]},
            {"🔫 [Universal] NoClip", [[
                game:GetService("RunService").Stepped:Connect(function()
                    local char = game.Players.LocalPlayer.Character
                    if char then
                        for _, v in ipairs(char:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v.CanCollide = false
                            end
                        end
                    end
                end)
            ]]},
            {"🗺 [Universal] ESP Всех игроков", [[
                for _, p in ipairs(game.Players:GetPlayers()) do
                    if p ~= game.Players.LocalPlayer then
                        p.CharacterAdded:Connect(function(char)
                            local bb = Instance.new("BillboardGui", char:WaitForChild("HumanoidRootPart"))
                            bb.Size = UDim2.new(0,80,0,24)
                            bb.StudsOffset = Vector3.new(0,3,0)
                            bb.AlwaysOnTop = true
                            local tl = Instance.new("TextLabel",bb)
                            tl.Size = UDim2.new(1,0,1,0)
                            tl.BackgroundTransparency = 1
                            tl.Text = p.Name
                            tl.TextColor3 = Color3.fromRGB(255,80,80)
                            tl.Font = Enum.Font.GothamBold
                            tl.TextScaled = true
                        end)
                        if p.Character then
                            local root = p.Character:FindFirstChild("HumanoidRootPart")
                            if root then
                                local bb = Instance.new("BillboardGui",root)
                                bb.Size = UDim2.new(0,80,0,24)
                                bb.StudsOffset = Vector3.new(0,3,0)
                                bb.AlwaysOnTop = true
                                local tl = Instance.new("TextLabel",bb)
                                tl.Size = UDim2.new(1,0,1,0)
                                tl.BackgroundTransparency = 1
                                tl.Text = p.Name
                                tl.TextColor3 = Color3.fromRGB(255,80,80)
                                tl.Font = Enum.Font.GothamBold
                                tl.TextScaled = true
                            end
                        end
                    end
                end
            ]]},
        }

        local y = 48
        for _, s in ipairs(scripts) do
            local name, code = s[1], s[2]
            local card = mkCard(p, y, 50)
            local lbl = mkLabel(card, name, 4, COLORS.text, 12, true)
            local runBtn = Instance.new("TextButton")
            runBtn.Size = UDim2.new(0, 70, 0, 24)
            runBtn.Position = UDim2.new(1, -80, 0.5, -12)
            runBtn.BackgroundColor3 = COLORS.green
            runBtn.Text = "▶ RUN"
            runBtn.TextColor3 = Color3.fromRGB(0, 30, 10)
            runBtn.Font = Enum.Font.GothamBold
            runBtn.TextSize = 12
            runBtn.BorderSizePixel = 0
            runBtn.Parent = card
            Instance.new("UICorner").Parent = runBtn
            local capturedCode = code
            local capturedBtn = runBtn
            runBtn.MouseButton1Click:Connect(function()
                local ok, err = pcall(loadstring(capturedCode))
                if ok then
                    capturedBtn.BackgroundColor3 = COLORS.green
                    capturedBtn.Text = "✓ OK"
                else
                    capturedBtn.BackgroundColor3 = COLORS.red
                    capturedBtn.Text = "✕ ERR"
                    logError(tostring(err))
                end
                wait(2)
                capturedBtn.Text = "▶ RUN"
                capturedBtn.BackgroundColor3 = COLORS.green
            end)
            y = y + 58
        end

        local customCard = mkCard(p, y, 90)
        mkLabel(customCard, "💻 Свой скрипт (вставь и запусти)", 4, COLORS.accent2, 11, true)
        local customInput = Instance.new("TextBox")
        customInput.Size = UDim2.new(1, -80, 0, 60)
        customInput.Position = UDim2.new(0, 6, 0, 24)
        customInput.BackgroundColor3 = COLORS.bg
        customInput.TextColor3 = COLORS.text
        customInput.Font = Enum.Font.Code
        customInput.TextSize = 10
        customInput.MultiLine = true
        customInput.PlaceholderText = "print('hello VexAi')"
        customInput.ClearTextOnFocus = false
        customInput.BorderSizePixel = 0
        customInput.TextXAlignment = Enum.TextXAlignment.Left
        customInput.TextYAlignment = Enum.TextYAlignment.Top
        customInput.Parent = customCard
        Instance.new("UICorner").Parent = customInput
        local customRun = Instance.new("TextButton")
        customRun.Size = UDim2.new(0, 60, 0, 60)
        customRun.Position = UDim2.new(1, -66, 0, 24)
        customRun.BackgroundColor3 = COLORS.accent
        customRun.Text = "▶\nRUN"
        customRun.TextColor3 = COLORS.white
        customRun.Font = Enum.Font.GothamBold
        customRun.TextSize = 12
        customRun.BorderSizePixel = 0
        customRun.Parent = customCard
        Instance.new("UICorner").Parent = customRun
        customRun.MouseButton1Click:Connect(function()
            local code = customInput.Text
            if code == "" then return end
            local ok, err = pcall(loadstring(code))
            if not ok then logError("Custom: " .. tostring(err)) end
        end)

        setCanvasY(p, y + 110)
    end

    do
        local p = tabPanels["ai_chat"]
        mkLabel(p, "🤖 ЧАТ С VexAi (Groq LLaMA)", 8, COLORS.accent2, 13, true)

        local chatHistory = Instance.new("ScrollingFrame")
        chatHistory.Size = UDim2.new(1, -8, 0, 280)
        chatHistory.Position = UDim2.new(0, 4, 0, 30)
        chatHistory.BackgroundColor3 = COLORS.panel
        chatHistory.BorderSizePixel = 0
        chatHistory.ScrollBarThickness = 3
        chatHistory.ScrollBarImageColor3 = COLORS.accent
        chatHistory.CanvasSize = UDim2.new(0, 0, 0, 0)
        chatHistory.Parent = p
        Instance.new("UICorner").Parent = chatHistory
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 4)
        layout.Parent = chatHistory
        Instance.new("UIPadding", chatHistory).PaddingLeft = UDim.new(0,6)

        local function addChatMsg(speaker, msg, color)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -8, 0, 0)
            frame.BackgroundTransparency = 1
            frame.Parent = chatHistory
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = "[" .. speaker .. "] " .. msg
            lbl.TextColor3 = color or COLORS.text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextWrapped = true
            lbl.AutomaticSize = Enum.AutomaticSize.Y
            lbl.Parent = frame
            frame.AutomaticSize = Enum.AutomaticSize.Y
            chatHistory.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
            chatHistory.CanvasPosition = Vector2.new(0, 9999)
        end

        addChatMsg("VexAi", "Привет! Я готов отвечать на вопросы об игре. Спроси меня что-нибудь!", COLORS.accent2)

        local chatInput = Instance.new("TextBox")
        chatInput.Size = UDim2.new(1, -80, 0, 36)
        chatInput.Position = UDim2.new(0, 4, 0, 318)
        chatInput.BackgroundColor3 = COLORS.panel
        chatInput.TextColor3 = COLORS.text
        chatInput.Font = Enum.Font.Gotham
        chatInput.TextSize = 12
        chatInput.PlaceholderText = "Спроси у ИИ..."
        chatInput.ClearTextOnFocus = false
        chatInput.BorderSizePixel = 0
        chatInput.Parent = p
        Instance.new("UICorner").Parent = chatInput

        local sendBtn = Instance.new("TextButton")
        sendBtn.Size = UDim2.new(0, 68, 0, 36)
        sendBtn.Position = UDim2.new(1, -74, 0, 318)
        sendBtn.BackgroundColor3 = COLORS.accent
        sendBtn.Text = "Отправить"
        sendBtn.TextColor3 = COLORS.white
        sendBtn.Font = Enum.Font.GothamBold
        sendBtn.TextSize = 11
        sendBtn.BorderSizePixel = 0
        sendBtn.Parent = p
        Instance.new("UICorner").Parent = sendBtn

        local function sendMessage()
            local q = chatInput.Text
            if q == "" or q == "Спроси у ИИ..." then return end
            chatInput.Text = ""
            addChatMsg("Ты", q, COLORS.text)
            sendBtn.Text = "..."
            spawn(function()
                local reply = askChat(q)
                addChatMsg("VexAi", reply, COLORS.accent2)
                sendBtn.Text = "Отправить"
            end)
        end

        sendBtn.MouseButton1Click:Connect(sendMessage)
        chatInput.FocusLost:Connect(function(enter) if enter then sendMessage() end end)

        setCanvasY(p, 362)
    end

    do
        local p = tabPanels["logs"]
        mkLabel(p, "📋 ЛОГИ ОШИБОК И ДЕЙСТВИЙ", 8, COLORS.accent2, 13, true)

        local logFrame = Instance.new("ScrollingFrame")
        logFrame.Size = UDim2.new(1, -8, 0, 260)
        logFrame.Position = UDim2.new(0, 4, 0, 30)
        logFrame.BackgroundColor3 = COLORS.panel
        logFrame.BorderSizePixel = 0
        logFrame.ScrollBarThickness = 3
        logFrame.ScrollBarImageColor3 = COLORS.accent
        logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        logFrame.Parent = p
        Instance.new("UICorner").Parent = logFrame
        local logLayout = Instance.new("UIListLayout")
        logLayout.SortOrder = Enum.SortOrder.LayoutOrder
        logLayout.Parent = logFrame
        Instance.new("UIPadding", logFrame).PaddingLeft = UDim.new(0,6)

        local function refreshLogs()
            for _, c in ipairs(logFrame:GetChildren()) do
                if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
            end
            for i = #VexAi.Brain.actionHistory, math.max(1, #VexAi.Brain.actionHistory - 20), -1 do
                local h = VexAi.Brain.actionHistory[i]
                if h then
                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, -8, 0, 18)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = string.format("[%s] %s → %s", os.date("%H:%M:%S", h.t), h.action, h.result)
                    lbl.TextColor3 = h.result == "ok" and COLORS.green or (h.result:find("err") and COLORS.red or COLORS.yellow)
                    lbl.Font = Enum.Font.Code
                    lbl.TextSize = 10
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = logFrame
                end
            end
            for _, e in ipairs(VexAi.Errors) do
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -8, 0, 18)
                lbl.BackgroundTransparency = 1
                lbl.Text = string.format("[ERR %s] %s", os.date("%H:%M:%S", e.t), e.msg:sub(1,60))
                lbl.TextColor3 = COLORS.red
                lbl.Font = Enum.Font.Code
                lbl.TextSize = 10
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = logFrame
            end
            logFrame.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 8)
        end

        mkBtn(p, "🔄 Обновить логи", 300, COLORS.accent, refreshLogs)
        mkBtn(p, "🗑 Очистить ошибки", 340, COLORS.red, function()
            VexAi.Errors = {}
            refreshLogs()
        end)

        refreshLogs()
        spawn(function() while true do wait(3); pcall(refreshLogs) end end)

        setCanvasY(p, 385)
    end

    switchTab("dashboard")
end

detectGame()

if VexAi.Config.AntiAFK then antiAFK() end
speedHackLoop()
flyLoop()
infJumpLoop()
autoHealLoop()
espLoop()
aiMainLoop()
createGUI()
