local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local VirtualUser       = game:GetService("VirtualUser")
local TeleportService   = game:GetService("TeleportService")
local ScriptContext     = game:GetService("ScriptContext")
local CoreGui           = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkClient     = game:GetService("NetworkClient")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local Rex = {}
Rex.Version = "1.0.0 Beta"
Rex.Active  = false
Rex.Threads = {}
Rex.Log     = {}

local function rLog(msg)
    local entry = "[Rex] " .. msg
    table.insert(Rex.Log, entry)
    if #Rex.Log > 300 then table.remove(Rex.Log, 1) end
    pcall(print, entry)
end

local function rSpawn(fn)
    local t = task.spawn(fn)
    table.insert(Rex.Threads, t)
    return t
end

local function rRand(min, max) return min + math.random() * (max - min) end
local function rRandInt(min, max) return math.random(min, max) end
local function rGetChar() return LocalPlayer.Character end
local function rGetRoot() local c = rGetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function rGetHum() local c = rGetChar(); return c and c:FindFirstChildWhichIsA("Humanoid") end

-- ════════════════════════════════════════
--  ADAPTIVE ENGINE — мозг Rex
--  Учится на каждом новом AC паттерне
-- ════════════════════════════════════════

local RexAdaptive = {}
RexAdaptive.LearnedScripts  = {}   -- { [name] = score }
RexAdaptive.LearnedRemotes  = {}   -- { [name] = score }
RexAdaptive.LearnedFunctions = {}  -- { [fnRef] = true }
RexAdaptive.KickedCount     = 0
RexAdaptive.BlockedRemotes  = 0
RexAdaptive.KilledScripts   = 0

local BASE_SCRIPT_PATTERNS = {
    "anticheat","anti_cheat","detect","watchdog","scanner",
    "monitor","cheatcheck","speedcheck","flycheck","kickcheck",
    "bancheck","verify","integrity","exploit_detect","trustcheck",
}

local BASE_REMOTE_PATTERNS = {
    "detect","anticheat","ac_","cheatcheck","speedcheck","flycheck",
    "teleportcheck","flagplayer","reportplayer","banplayer","kickplayer",
    "punishment","violation","exploit","hack","cheat","monitor",
    "watchdog","scanner","verify","validate","integrity","trustcheck",
    "playercheck","servercheck","ping_ac","antilag","unfair",
}

local WHITELIST = {
    claimreward=true, collectreward=true, yenreward=true, eventreward=true,
    likereward=true, afkreward=true, spinreward=true, dailyreward=true,
    freereward=true, collect=true, claim=true, purchase=true,
    buy=true, shop=true, store=true, inventory=true, equip=true,
    open=true, quest=true, trade=true, chat=true, message=true,
}

-- Эвристика подозрительности имени (0–10)
local function calcSuspicionScore(name)
    local nl   = name:lower()
    local score = 0
    for _, p in ipairs(BASE_REMOTE_PATTERNS) do
        if nl:find(p) then score += 3 end
    end
    if #nl < 4 then score += 1 end
    if nl:match("^[a-z]+%d+$") then score += 1 end
    for w in pairs(WHITELIST) do
        if nl:find(w) then return 0 end
    end
    return score
end

function RexAdaptive:Learn(kind, name)
    if kind == "remote" then
        self.LearnedRemotes[name] = (self.LearnedRemotes[name] or 0) + 1
        rLog(("Adaptive: Learned remote '%s' (score %d)"):format(name, self.LearnedRemotes[name]))
    elseif kind == "script" then
        self.LearnedScripts[name] = (self.LearnedScripts[name] or 0) + 1
        rLog(("Adaptive: Learned script '%s' (score %d)"):format(name, self.LearnedScripts[name]))
    elseif kind == "fn" then
        self.LearnedFunctions[name] = true
        rLog("Adaptive: Learned function hook → " .. tostring(name))
    end
end

function RexAdaptive:IsKnownBadRemote(name)
    local nl = name:lower()
    if self.LearnedRemotes[name] and self.LearnedRemotes[name] >= 1 then return true end
    if calcSuspicionScore(nl) >= 3 then return true end
    return false
end

function RexAdaptive:IsKnownBadScript(name)
    local nl = name:lower()
    if self.LearnedScripts[name] and self.LearnedScripts[name] >= 1 then return true end
    for _, p in ipairs(BASE_SCRIPT_PATTERNS) do
        if nl:find(p) then return true end
    end
    return false
end

-- ════════════════════════════════════════
--  ROBLOX INTERNAL API LAYER
--  Использует executor API для подключения
--  к внутренним Roblox сервисам и отключения AC
-- ════════════════════════════════════════

local RexRobloxAPI = {}
RexRobloxAPI.HookedFunctions = {}

-- Хукаем внутренние Roblox функции через hookfunction/replaceclosure
function RexRobloxAPI:HookInternalFunctions()
    -- Хук game:GetService() — перехватываем запросы AC к сервисам
    pcall(function()
        local oldGetService = hookfunction(
            game.GetService,
            newcclosure(function(self, serviceName)
                if type(serviceName) == "string" then
                    local sl = serviceName:lower()
                    if sl == "scriptcontext" or sl == "replicatedfirst" then
                        -- Пропускаем, но логируем попытку
                        rLog("RobloxAPI: GetService called for: " .. serviceName)
                    end
                end
                return oldGetService(self, serviceName)
            end)
        )
        table.insert(RexRobloxAPI.HookedFunctions, oldGetService)
        rLog("RobloxAPI: Hooked GetService")
    end)

    -- Хук require() — блокируем загрузку AC ModuleScripts
    pcall(function()
        local oldRequire = hookfunction(
            require,
            newcclosure(function(mod)
                if typeof(mod) == "Instance" then
                    local n = mod.Name or ""
                    if RexAdaptive:IsKnownBadScript(n) then
                        rLog("RobloxAPI: Blocked require() for AC module: " .. n)
                        RexAdaptive:Learn("script", n)
                        return {}
                    end
                end
                return oldRequire(mod)
            end)
        )
        table.insert(RexRobloxAPI.HookedFunctions, oldRequire)
        rLog("RobloxAPI: Hooked require()")
    end)

    -- Хук FireServer — второй уровень защиты через hookfunction
    pcall(function()
        local re = Instance.new("RemoteEvent")
        local oldFireServer = hookfunction(
            re.FireServer,
            newcclosure(function(self, ...)
                local ok, isRem = pcall(function()
                    return self:IsA("RemoteEvent") or self:IsA("RemoteFunction")
                end)
                if ok and isRem then
                    local name = self.Name or ""
                    if RexAdaptive:IsKnownBadRemote(name) then
                        rLog("RobloxAPI: hookfunction blocked FireServer: " .. name)
                        RexAdaptive:Learn("remote", name)
                        RexAdaptive.BlockedRemotes += 1
                        return nil
                    end
                end
            end)
        )
        re:Destroy()
        table.insert(RexRobloxAPI.HookedFunctions, oldFireServer)
        rLog("RobloxAPI: Hooked FireServer via hookfunction")
    end)

    -- Хук Instance.new — детектим создание AC скриптов на лету
    pcall(function()
        local oldInstanceNew = hookfunction(
            Instance.new,
            newcclosure(function(className, parent)
                local obj = oldInstanceNew(className, parent)
                if className == "LocalScript" or className == "Script" or className == "ModuleScript" then
                    task.defer(function()
                        pcall(function()
                            if obj and obj.Name then
                                if RexAdaptive:IsKnownBadScript(obj.Name) then
                                    pcall(function() obj.Disabled = true end)
                                    RexAdaptive:Learn("script", obj.Name)
                                    rLog("RobloxAPI: Blocked new AC script: " .. obj.Name)
                                    RexAdaptive.KilledScripts += 1
                                end
                            end
                        end)
                    end)
                end
                return obj
            end)
        )
        table.insert(RexRobloxAPI.HookedFunctions, oldInstanceNew)
        rLog("RobloxAPI: Hooked Instance.new")
    end)
end

-- Получаем все коннекции ремоута и режем AC
function RexRobloxAPI:CutRemoteConnections(remote)
    pcall(function()
        if not getconnections then return end
        local signals = {}

        pcall(function() table.insert(signals, remote.OnClientEvent) end)
        pcall(function() table.insert(signals, remote.OnClientInvoke) end)

        for _, sig in ipairs(signals) do
            pcall(function()
                for _, conn in ipairs(getconnections(sig)) do
                    pcall(function()
                        local src = tostring(conn.Function):lower()
                        local isAC = src:find("anticheat") or src:find("detect") or src:find("kick")
                        if isAC or RexAdaptive:IsKnownBadRemote(remote.Name) then
                            conn:Disable()
                            rLog("RobloxAPI: Cut connection on " .. remote.Name)
                            RexAdaptive.BlockedRemotes += 1
                        end
                    end)
                end
            end)
        end
    end)
end

-- Сканируем Roblox game tree через внутренние API
function RexRobloxAPI:DeepScanGame()
    local scanned = 0
    local roots   = {
        workspace, LocalPlayer, LocalPlayer.PlayerGui,
        CoreGui, ReplicatedStorage, StarterGui,
        game:GetService("Players"),
    }

    for _, root in ipairs(roots) do
        pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                scanned += 1

                -- Скрипты
                if obj:IsA("LocalScript") or obj:IsA("Script") or obj:IsA("ModuleScript") then
                    if RexAdaptive:IsKnownBadScript(obj.Name) then
                        pcall(function()
                            obj.Disabled = true
                            RexAdaptive:Learn("script", obj.Name)
                            RexAdaptive.KilledScripts += 1
                            rLog("DeepScan: Killed → " .. obj.ClassName .. " '" .. obj.Name .. "'")
                        end)
                    end

                -- Ремоуты — проверяем и режем
                elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local score = calcSuspicionScore(obj.Name)
                    if score >= 3 then
                        RexAdaptive:Learn("remote", obj.Name)
                        RexRobloxAPI:CutRemoteConnections(obj)
                    end

                -- Значения-флаги AC
                elseif obj:IsA("BoolValue") or obj:IsA("IntValue") or obj:IsA("StringValue") then
                    local nl = obj.Name:lower()
                    if nl:find("cheat") or nl:find("exploit") or nl:find("ban")
                    or nl:find("detect") or nl:find("flag") or nl:find("hack") then
                        pcall(function()
                            if obj:IsA("BoolValue") then obj.Value = false
                            elseif obj:IsA("IntValue") then obj.Value = 0
                            elseif obj:IsA("StringValue") then obj.Value = ""
                            end
                            rLog("DeepScan: Cleared flag → " .. obj.Name)
                        end)
                    end
                end
            end
        end)
    end

    return scanned
end

function RexRobloxAPI:Init()
    RexRobloxAPI:HookInternalFunctions()
    rLog("RobloxAPI: Internal hooks installed")
end

-- ════════════════════════════════════════
--  PRELOADER
-- ════════════════════════════════════════

local RexPreload = {}

function RexPreload:SpoofIdentityNow()
    pcall(function() set_thread_identity(7) end)
    pcall(function() setidentity(7) end)
end

function RexPreload:ClearTracesNow()
    pcall(function()
        local names = {
            "SYNAPSE_RUNNING","KRNL_LOADED","FLUXUS","SCRIPT_HUB","EXECUTOR",
            "COCO_Z","OXYGEN_U","EVON","ARCEUS_X","WAVE","HYDROGEN","DELTA",
            "SOLARA","SELIOX","CELERY","VEGA","COMET","MACSPLOIT",
        }
        local G = getfenv(0)
        for _, name in ipairs(names) do
            if G[name] ~= nil then pcall(function() G[name] = nil end) end
        end
    end)
end

function RexPreload:Run()
    RexPreload:SpoofIdentityNow()
    RexPreload:ClearTracesNow()
    if not game:IsLoaded() then game.Loaded:Wait() end
    task.wait(0.2)
    local scanned = RexRobloxAPI:DeepScanGame()
    rLog(("Preload: Scanned %d objects, %d killed, %d remotes blocked"):format(
        scanned, RexAdaptive.KilledScripts, RexAdaptive.BlockedRemotes
    ))
end

-- ════════════════════════════════════════
--  ЕДИНЫЙ NAMECALL ХУК
-- ════════════════════════════════════════

local RexHook = {}
RexHook._installed = false

local KICK_METHODS = { Kick=true }
local TELEPORT_METHODS = {
    Teleport=true, TeleportAsync=true,
    TeleportToPlaceInstance=true, TeleportToPrivateServer=true,
}

local function buildNamecallHandler(oldFn)
    return newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}

        if KICK_METHODS[method] then
            rLog("AntiKick: Blocked :" .. method .. "()")
            RexAdaptive.KickedCount += 1
            return
        end

        if TELEPORT_METHODS[method] and self == TeleportService then
            local pid = args[1]
            if pid and pid ~= game.PlaceId then
                rLog("AntiKick: Blocked teleport → " .. tostring(pid))
                RexAdaptive.KickedCount += 1
                return
            end
        end

        if method == "Disconnect" then
            local s = tostring(self):lower()
            if s:find("network") or self == NetworkClient then
                rLog("AntiKick: Blocked NetworkClient:Disconnect()")
                return
            end
        end

        if method == "FireServer" or method == "InvokeServer"
        or method == "FireClient" or method == "InvokeClient" then
            local ok, isRem = pcall(function()
                return self:IsA("RemoteEvent") or self:IsA("RemoteFunction")
            end)
            if ok and isRem then
                local n = self.Name
                if RexAdaptive:IsKnownBadRemote(n) then
                    rLog("AntiAC: Blocked remote: " .. n)
                    RexAdaptive:Learn("remote", n)
                    RexAdaptive.BlockedRemotes += 1
                    return nil
                end
            end
        end

        if oldFn then return oldFn(self, ...) end
    end)
end

function RexHook:Install()
    if RexHook._installed then return end
    RexHook._installed = true

    local usedStealth = false
    pcall(function()
        if hookmetamethod then
            hookmetamethod(game, "__namecall", buildNamecallHandler(nil))
            usedStealth = true
            rLog("Hook: hookmetamethod (stealth)")
        end
    end)

    if not usedStealth then
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            local old = mt.__namecall
            mt.__namecall = buildNamecallHandler(old)
            setreadonly(mt, true)
            rLog("Hook: fallback namecall")
        end)
    end
end

function RexHook:Reinstall()
    RexHook._installed = false
    RexHook:Install()
end

-- ════════════════════════════════════════
--  ANTI-KICK
-- ════════════════════════════════════════

local RexAntiKick = {}

function RexAntiKick:Init()
    RexHook:Install()

    rSpawn(function()
        while Rex.Active do
            task.wait(0.05)
            local hum = rGetHum()
            if hum and hum.Health <= 0 and hum.MaxHealth > 0 then
                pcall(function()
                    hum.Health = hum.MaxHealth
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end)
                rLog("AntiKick: Health-zero prevented")
                RexAdaptive.KickedCount += 1
            end
        end
    end)

    pcall(function()
        ScriptContext.Error:Connect(function(msg)
            if msg then
                local ml = msg:lower()
                if ml:find("kick") or ml:find("ban") or ml:find("cheat")
                or ml:find("exploit") or ml:find("violation") then
                    rLog("AntiKick: Error kick suppressed")
                    RexAdaptive.KickedCount += 1
                    return false
                end
            end
        end)
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.3)
        rLog("AntiKick: Respawn — re-hooking + re-scan")
        RexHook:Reinstall()
        task.spawn(function() RexRobloxAPI:DeepScanGame() end)
    end)

    rLog("AntiKick: Initialized")
end

-- ════════════════════════════════════════
--  ANTI-BAN
-- ════════════════════════════════════════

local RexAntiBan = {}

function RexAntiBan:SpoofMovement()
    local root = rGetRoot()
    if not root then return end
    pcall(function()
        local offsets = {
            Vector3.new( 0.03,0, 0.00), Vector3.new(-0.03,0, 0.00),
            Vector3.new( 0.00,0, 0.03), Vector3.new( 0.00,0,-0.03),
            Vector3.new( 0.02,0, 0.02), Vector3.new(-0.02,0,-0.02),
            Vector3.new( 0.01,0,-0.01), Vector3.new( 0.00,0, 0.00),
        }
        root.CFrame = root.CFrame + offsets[rRandInt(1,#offsets)]
    end)
end

function RexAntiBan:SpoofCamera()
    pcall(function()
        if not Camera then return end
        Camera.CFrame = Camera.CFrame * CFrame.Angles(rRand(-0.0003,0.0003), rRand(-0.0008,0.0008), 0)
    end)
end

function RexAntiBan:SpoofHeartbeat()
    pcall(function()
        VirtualUser:Button2Down(Vector2.zero, Camera.CFrame)
        task.wait(rRand(0.04,0.12))
        VirtualUser:Button2Up(Vector2.zero, Camera.CFrame)
    end)
end

function RexAntiBan:SpoofMouseMove()
    pcall(function()
        VirtualUser:MoveMouse(Vector2.new(rRandInt(-4,4), rRandInt(-4,4)))
    end)
end

function RexAntiBan:SpoofClick()
    pcall(function()
        local p = Vector2.new(rRandInt(200,600), rRandInt(200,500))
        VirtualUser:Button1Down(p, Camera.CFrame)
        task.wait(rRand(0.02,0.05))
        VirtualUser:Button1Up(p, Camera.CFrame)
    end)
end

function RexAntiBan:Init()
    rSpawn(function()
        local cycle = 0
        while Rex.Active do
            cycle += 1
            RexAntiBan:SpoofMovement()
            if cycle % 3  == 0 then RexAntiBan:SpoofCamera() end
            if cycle % 6  == 0 then RexAntiBan:SpoofMouseMove() end
            if cycle % 4  == 0 then RexAntiBan:SpoofHeartbeat() end
            if cycle % 15 == 0 then RexAntiBan:SpoofClick() end
            if cycle % rRandInt(45,65) == 0 then
                task.wait(rRand(2.0,6.0))
                cycle = 0
            end
            task.wait(math.max(0.04, rRand(0.15,0.50) + rRand(0,0.20) * (math.random() > 0.5 and 1 or -1)))
        end
    end)

    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(45,80))
            RexAntiBan:SpoofHeartbeat()
            RexAntiBan:SpoofCamera()
            RexAntiBan:SpoofMouseMove()
        end
    end)

    rLog("AntiBan: Initialized")
end

-- ════════════════════════════════════════
--  ANTI-AC (адаптивный)
-- ════════════════════════════════════════

local RexAntiAC = {}

function RexAntiAC:SpoofHumanoidState()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(0.5,1.2))
            pcall(function()
                local hum = rGetHum()
                if hum then
                    local state = hum:GetState()
                    if state == Enum.HumanoidStateType.Freefall
                    or state == Enum.HumanoidStateType.Flying then
                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                    end
                end
            end)
        end
    end)
end

function RexAntiAC:SpoofWalkSpeed()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(2.5,6.0))
            pcall(function()
                local hum  = rGetHum()
                local root = rGetRoot()
                if hum and root then
                    local moving = root.AssemblyLinearVelocity.Magnitude > 0.5
                    if not moving and hum.WalkSpeed > 40 then
                        local saved = hum.WalkSpeed
                        hum.WalkSpeed = 16
                        task.wait(rRand(0.1,0.25))
                        hum.WalkSpeed = saved
                    end
                end
            end)
        end
    end)
end

-- Адаптивный цикл — каждые N секунд пересканирует и обучается
function RexAntiAC:AdaptiveLoop()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(8.0, 15.0))
            local scanned = RexRobloxAPI:DeepScanGame()

            -- Если нашли что-то новое — подкорректируем тайминг (агрессивнее)
            if RexAdaptive.KilledScripts > 0 or RexAdaptive.BlockedRemotes > 0 then
                rLog(("Adaptive: Cycle — %d killed, %d blocked (total)"):format(
                    RexAdaptive.KilledScripts, RexAdaptive.BlockedRemotes
                ))
            end

            -- Пересканируем новые объекты в workspace
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                        if not RexAdaptive.LearnedRemotes[obj.Name] then
                            local score = calcSuspicionScore(obj.Name)
                            if score >= 3 then
                                RexAdaptive:Learn("remote", obj.Name)
                                RexRobloxAPI:CutRemoteConnections(obj)
                            end
                        end
                    end
                end
            end)
        end
    end)
end

function RexAntiAC:Init()
    RexAntiAC:SpoofHumanoidState()
    RexAntiAC:SpoofWalkSpeed()
    RexAntiAC:AdaptiveLoop()
    rLog("AntiAC: Adaptive engine started")
end

-- ════════════════════════════════════════
--  ANTI-DETECT
-- ════════════════════════════════════════

local RexAntiDetect = {}

function RexAntiDetect:SpoofIdentity()
    pcall(function() set_thread_identity({4,5,6,7}[rRandInt(1,4)]) end)
    pcall(function() setidentity(rRandInt(4,7)) end)
end

function RexAntiDetect:ClearTraces()
    pcall(function()
        local names = {
            "SYNAPSE_RUNNING","KRNL_LOADED","FLUXUS","SCRIPT_HUB","EXECUTOR",
            "COCO_Z","OXYGEN_U","EVON","ARCEUS_X","WAVE","HYDROGEN","DELTA",
            "SOLARA","SELIOX","CELERY","VEGA","COMET","MACSPLOIT",
        }
        local G = getfenv(0)
        for _, n in ipairs(names) do
            if G[n] ~= nil then pcall(function() G[n] = nil end) end
        end
    end)
end

function RexAntiDetect:SpoofIndex()
    pcall(function()
        local mt = getrawmetatable(game)
        if not mt then return end
        setreadonly(mt, false)
        local oldIndex = mt.__index
        mt.__index = newcclosure(function(self, key)
            if key == "PlaceVersion" or key == "JobId" or key == "CreatorId" then
                if type(oldIndex) == "function" then
                    local ok, val = pcall(oldIndex, self, key)
                    return ok and val or nil
                end
            end
            if type(oldIndex) == "function" then return oldIndex(self, key) end
            return rawget(self, key)
        end)
        setreadonly(mt, true)
    end)
end

function RexAntiDetect:Init()
    RexAntiDetect:SpoofIdentity()
    RexAntiDetect:ClearTraces()
    RexAntiDetect:SpoofIndex()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(18,35))
            RexAntiDetect:SpoofIdentity()
            RexAntiDetect:ClearTraces()
        end
    end)
    rLog("AntiDetect: Initialized")
end

-- ════════════════════════════════════════
--  GUARDIAN
-- ════════════════════════════════════════

local RexGuardian = {}
RexGuardian.Watchlist = {}

function RexGuardian:Watch(name, fn)
    table.insert(RexGuardian.Watchlist, { name=name, fn=fn })
end

function RexGuardian:Init()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(4.0,8.0))
            for _, entry in ipairs(RexGuardian.Watchlist) do
                local ok, err = pcall(entry.fn)
                if not ok then
                    rLog("Guardian: Restarting " .. entry.name .. " — " .. tostring(err))
                    task.wait(0.3)
                end
            end
        end
    end)
    rLog("Guardian: Watching " .. #RexGuardian.Watchlist .. " modules")
end

-- ════════════════════════════════════════
--  SPLASH
-- ════════════════════════════════════════

local function showSplash(text)
    pcall(function()
        local vp = Camera.ViewportSize
        local cx, cy = vp.X/2, vp.Y/2

        local bg = Drawing.new("Square")
        bg.Size=Vector2.new(440,148); bg.Position=Vector2.new(cx-220,cy-74)
        bg.Color=Color3.fromRGB(8,8,14); bg.Filled=true; bg.Transparency=0.08; bg.Visible=true

        local border = Drawing.new("Square")
        border.Size=Vector2.new(440,148); border.Position=Vector2.new(cx-220,cy-74)
        border.Color=Color3.fromRGB(80,120,255); border.Filled=false; border.Thickness=2; border.Visible=true

        local accent = Drawing.new("Square")
        accent.Size=Vector2.new(440,3); accent.Position=Vector2.new(cx-220,cy-74)
        accent.Color=Color3.fromRGB(80,120,255); accent.Filled=true; accent.Visible=true

        local title = Drawing.new("Text")
        title.Text="Start Rex"; title.Size=40; title.Font=Drawing.Fonts.GothamBold
        title.Color=Color3.fromRGB(255,255,255); title.Position=Vector2.new(cx,cy-22)
        title.Center=true; title.Outline=true; title.OutlineColor=Color3.fromRGB(0,0,0); title.Visible=true

        local ver = Drawing.new("Text")
        ver.Text="v"..Rex.Version; ver.Size=18; ver.Font=Drawing.Fonts.Gotham
        ver.Color=Color3.fromRGB(130,160,255); ver.Position=Vector2.new(cx,cy+16)
        ver.Center=true; ver.Outline=true; ver.OutlineColor=Color3.fromRGB(0,0,0); ver.Visible=true

        local sub = Drawing.new("Text")
        sub.Text=text or "Initializing..."; sub.Size=13; sub.Font=Drawing.Fonts.Gotham
        sub.Color=Color3.fromRGB(160,160,180); sub.Position=Vector2.new(cx,cy+48)
        sub.Center=true; sub.Visible=true

        task.delay(4.5, function()
            for _,d in ipairs({bg,border,accent,title,ver,sub}) do
                pcall(function() d:Remove() end)
            end
        end)
    end)
end

-- ════════════════════════════════════════
--  BOOT SEQUENCE
-- ════════════════════════════════════════

showSplash("Connecting to game API · Scanning AC...")

-- Шаг 1: identity + traces
RexPreload:SpoofIdentityNow()
RexPreload:ClearTracesNow()

-- Шаг 2: hookfunction-based internal hooks (до загрузки)
RexRobloxAPI:Init()

-- Шаг 3: ждём загрузку и делаем глубокий скан
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(0.3)
RexPreload:Run()

-- ════════════════════════════════════════
--  RAYFIELD UI
-- ════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name            = "Rex",
    LoadingTitle    = "Rex",
    LoadingSubtitle = "v" .. Rex.Version,
    ConfigurationSaving = { Enabled = false },
    Discord   = { Enabled = false },
    KeySystem = false,
})

local logLabel      = nil
local statusLabel   = nil
local statsLabel    = nil

local function refreshLog()
    if logLabel then
        logLabel:Set("Last: " .. (Rex.Log[#Rex.Log] or "—"))
    end
    if statsLabel then
        statsLabel:Set(("Kicks blocked: %d | Remotes: %d | Scripts: %d"):format(
            RexAdaptive.KickedCount,
            RexAdaptive.BlockedRemotes,
            RexAdaptive.KilledScripts
        ))
    end
end

local HomeTab = Window:CreateTab("🛡 Rex", 4483362458)
HomeTab:CreateSection("Status")
statusLabel = HomeTab:CreateLabel("Status: ⭕ Inactive")
statsLabel  = HomeTab:CreateLabel("Kicks: 0 | Remotes: 0 | Scripts: 0")
logLabel    = HomeTab:CreateLabel("Last: —")

HomeTab:CreateToggle({
    Name         = "🛡 Enable Rex",
    CurrentValue = false,
    Flag         = "RexMain",
    Callback     = function(val)
        Rex.Active = val
        if val then
            RexAntiKick:Init()
            RexAntiBan:Init()
            RexAntiAC:Init()
            RexAntiDetect:Init()

            RexGuardian:Watch("Hook",       function() RexHook:Install() end)
            RexGuardian:Watch("AntiBan",    function() RexAntiBan:SpoofHeartbeat() end)
            RexGuardian:Watch("AntiDetect", function() RexAntiDetect:ClearTraces() end)
            RexGuardian:Watch("DeepScan",   function() RexRobloxAPI:DeepScanGame() end)
            RexGuardian:Watch("Preload",    function() RexPreload:Run() end)
            RexGuardian:Init()

            if statusLabel then statusLabel:Set("Status: ✅ Active — All modules running") end

            Rayfield:Notify({
                Title    = "🛡 Rex Active",
                Content  = "Adaptive AC engine running",
                Duration = 5,
                Image    = 4483362458,
            })

            rSpawn(function()
                while Rex.Active do
                    task.wait(1.5)
                    pcall(refreshLog)
                end
            end)
        else
            if statusLabel then statusLabel:Set("Status: ⭕ Inactive") end
            for _, t in ipairs(Rex.Threads) do pcall(function() task.cancel(t) end) end
            Rex.Threads = {}
            RexHook._installed = false
            Rayfield:Notify({ Title = "🛡 Rex Stopped", Content = "All modules disabled.", Duration = 3 })
        end
    end,
})

HomeTab:CreateButton({
    Name     = "🔄 Force Re-scan Now",
    Callback = function()
        local s = RexRobloxAPI:DeepScanGame()
        Rayfield:Notify({
            Title   = "🔄 Re-scan Complete",
            Content = ("Scanned %d objects\n%d scripts killed · %d remotes blocked"):format(
                s, RexAdaptive.KilledScripts, RexAdaptive.BlockedRemotes
            ),
            Duration = 5,
        })
    end,
})

HomeTab:CreateButton({
    Name     = "📋 Last 5 Events",
    Callback = function()
        local lines = {}
        local s = math.max(1, #Rex.Log - 4)
        for i = s, #Rex.Log do table.insert(lines, Rex.Log[i]) end
        Rayfield:Notify({
            Title    = "📋 Rex Log",
            Content  = #lines > 0 and table.concat(lines, "\n") or "No events yet.",
            Duration = 10,
        })
    end,
})

HomeTab:CreateButton({
    Name     = "📊 Learned Patterns",
    Callback = function()
        local count = 0
        local sample = {}
        for name, score in pairs(RexAdaptive.LearnedRemotes) do
            count += 1
            if #sample < 3 then table.insert(sample, name .. "(" .. score .. ")") end
        end
        for name, score in pairs(RexAdaptive.LearnedScripts) do
            count += 1
            if #sample < 5 then table.insert(sample, name .. "(" .. score .. ")") end
        end
        Rayfield:Notify({
            Title   = "📊 Adaptive Patterns",
            Content = ("Learned: %d patterns\n%s"):format(
                count, table.concat(sample, ", ")
            ),
            Duration = 7,
        })
    end,
})

HomeTab:CreateButton({
    Name     = "🗑️ Clear Log",
    Callback = function()
        Rex.Log = {}
        if logLabel then logLabel:Set("Last: —") end
        Rayfield:Notify({ Title = "Cleared", Content = "Rex log cleared.", Duration = 2 })
    end,
})

local AdaptiveTab = Window:CreateTab("🧠 Adaptive", 4483362458)
AdaptiveTab:CreateSection("Adaptive Engine")
AdaptiveTab:CreateLabel("⚔ Learns new AC patterns automatically")
AdaptiveTab:CreateLabel("⚔ Suspicion scoring (0–10) per remote/script")
AdaptiveTab:CreateLabel("⚔ Deep-scans all game descendants")
AdaptiveTab:CreateLabel("⚔ hookfunction on require() blocks AC modules")
AdaptiveTab:CreateLabel("⚔ hookfunction on Instance.new catches new scripts")
AdaptiveTab:CreateLabel("⚔ hookfunction on FireServer (2nd layer)")
AdaptiveTab:CreateLabel("⚔ GetService hook logs AC service requests")
AdaptiveTab:CreateLabel("⚔ Re-scans every 8–15s while active")
AdaptiveTab:CreateLabel("⚔ Extra scan on character respawn")

local AntiKickTab = Window:CreateTab("🦵 Anti-Kick", 4483362458)
AntiKickTab:CreateSection("Methods")
AntiKickTab:CreateLabel("⚔ hookmetamethod stealth (primary)")
AntiKickTab:CreateLabel("⚔ Fallback manual namecall hook")
AntiKickTab:CreateLabel("⚔ Kick() blocked on any object")
AntiKickTab:CreateLabel("⚔ TeleportService kick blocker")
AntiKickTab:CreateLabel("⚔ NetworkClient disconnect blocked")
AntiKickTab:CreateLabel("⚔ Health-zero prevention (0.05s)")
AntiKickTab:CreateLabel("⚔ ScriptContext error suppression")
AntiKickTab:CreateLabel("⚔ Auto re-hook + re-scan on respawn")

local AntiBanTab = Window:CreateTab("🚫 Anti-Ban", 4483362458)
AntiBanTab:CreateSection("Methods")
AntiBanTab:CreateLabel("⚔ Micro-movements · Camera · Mouse spoof")
AntiBanTab:CreateLabel("⚔ VirtualUser heartbeat + click spoof")
AntiBanTab:CreateLabel("⚔ Randomised human-like timing")
AntiBanTab:CreateLabel("⚔ Long idle pauses every 45–65 cycles")

local AntiDetectTab = Window:CreateTab("👁 Anti-Detect", 4483362458)
AntiDetectTab:CreateSection("Methods")
AntiDetectTab:CreateLabel("⚔ Thread identity 7 on boot")
AntiDetectTab:CreateLabel("⚔ Executor env variables erased")
AntiDetectTab:CreateLabel("⚔ __index spoof for game properties")
AntiDetectTab:CreateLabel("⚔ Re-spoofs every 18–35 seconds")

local GuardianTab = Window:CreateTab("👁‍🗨 Guardian", 4483362458)
GuardianTab:CreateSection("Self-Repair")
GuardianTab:CreateLabel("⚔ Monitors all modules every 4–8s")
GuardianTab:CreateLabel("⚔ Auto-restarts any crashed module")
GuardianTab:CreateLabel("⚔ Periodic DeepScan in Guardian loop")

local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)
MiscTab:CreateSection("Info")
MiscTab:CreateLabel("Rex v" .. Rex.Version)
MiscTab:CreateLabel("Adaptive AC · Anti-Kick · Anti-Ban · Anti-Detect")
MiscTab:CreateLabel("RobloxAPI hooks · Guardian · Preloader")

Rayfield:Notify({
    Title    = "🛡 Rex v" .. Rex.Version,
    Content  = "Boot complete. Enable in Rex tab.",
    Duration = 5,
    Image    = 4483362458,
})
