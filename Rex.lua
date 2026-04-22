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
Rex.Hooks   = {}
Rex.Log     = {}

local function rLog(msg)
    local entry = "[Rex] " .. msg
    table.insert(Rex.Log, entry)
    if #Rex.Log > 200 then table.remove(Rex.Log, 1) end
    pcall(print, entry)
end

local function rSpawn(fn)
    local t = task.spawn(fn)
    table.insert(Rex.Threads, t)
    return t
end

local function rRand(min, max)
    return min + math.random() * (max - min)
end

local function rRandInt(min, max)
    return math.random(min, max)
end

local function rGetChar()
    return LocalPlayer.Character
end

local function rGetRoot()
    local c = rGetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function rGetHum()
    local c = rGetChar()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function showSplash(statusText)
    pcall(function()
        local vp = Camera.ViewportSize
        local cx = vp.X / 2
        local cy = vp.Y / 2

        local bg = Drawing.new("Square")
        bg.Size         = Vector2.new(420, 140)
        bg.Position     = Vector2.new(cx - 210, cy - 70)
        bg.Color        = Color3.fromRGB(8, 8, 14)
        bg.Filled       = true
        bg.Thickness    = 1
        bg.Visible      = true
        bg.Transparency = 0.08

        local border = Drawing.new("Square")
        border.Size      = Vector2.new(420, 140)
        border.Position  = Vector2.new(cx - 210, cy - 70)
        border.Color     = Color3.fromRGB(80, 120, 255)
        border.Filled    = false
        border.Thickness = 2
        border.Visible   = true

        local accent = Drawing.new("Square")
        accent.Size      = Vector2.new(420, 3)
        accent.Position  = Vector2.new(cx - 210, cy - 70)
        accent.Color     = Color3.fromRGB(80, 120, 255)
        accent.Filled    = true
        accent.Thickness = 1
        accent.Visible   = true

        local title = Drawing.new("Text")
        title.Text         = "Start Rex"
        title.Size         = 38
        title.Font         = Drawing.Fonts.GothamBold
        title.Color        = Color3.fromRGB(255, 255, 255)
        title.Position     = Vector2.new(cx, cy - 22)
        title.Center       = true
        title.Outline      = true
        title.OutlineColor = Color3.fromRGB(0, 0, 0)
        title.Visible      = true

        local ver = Drawing.new("Text")
        ver.Text         = "v" .. Rex.Version
        ver.Size         = 18
        ver.Font         = Drawing.Fonts.Gotham
        ver.Color        = Color3.fromRGB(130, 160, 255)
        ver.Position     = Vector2.new(cx, cy + 16)
        ver.Center       = true
        ver.Outline      = true
        ver.OutlineColor = Color3.fromRGB(0, 0, 0)
        ver.Visible      = true

        local sub = Drawing.new("Text")
        sub.Text     = statusText or "Initializing..."
        sub.Size     = 13
        sub.Font     = Drawing.Fonts.Gotham
        sub.Color    = Color3.fromRGB(160, 160, 180)
        sub.Position = Vector2.new(cx, cy + 46)
        sub.Center   = true
        sub.Visible  = true

        task.delay(4.0, function()
            for _, d in ipairs({ bg, border, accent, title, ver, sub }) do
                pcall(function() d:Remove() end)
            end
        end)
    end)
end

showSplash("Scanning for anti-cheat...")

local AC_SCRIPT_PATTERNS = {
    "anticheat","anti_cheat","detect","watchdog","scanner",
    "monitor","cheatcheck","speedcheck","flycheck","kickcheck",
    "bancheck","verify","integrity","exploit_detect",
}

local AC_REMOTE_PATTERNS = {
    "detect","anticheat","ac_","cheatcheck","speedcheck","flycheck",
    "teleportcheck","flagplayer","reportplayer","banplayer","kickplayer",
    "punishment","violation","exploit","hack","cheat","monitor",
    "watchdog","scanner","verify","validate","integrity",
}

local WHITELIST_REMOTES = {
    claimreward=true, collectreward=true, yenreward=true, eventreward=true,
    likereward=true, afkreward=true, spinreward=true, dailyreward=true,
    freereward=true, collect=true, claim=true, purchase=true,
    buy=true, shop=true, store=true, inventory=true, equip=true,
    open=true, quest=true,
}

local function matchesAC(name, patterns)
    local nl = name:lower()
    for _, p in ipairs(patterns) do
        if nl:find(p) then return true end
    end
    return false
end

local function isSuspiciousRemote(name)
    return matchesAC(name, AC_REMOTE_PATTERNS)
end

local function isWhitelisted(name)
    local nl = name:lower()
    for w in pairs(WHITELIST_REMOTES) do
        if nl:find(w) then return true end
    end
    return false
end

-- ════════════════════════════════════════
--  PRELOADER — убивает AC ДО хуков
-- ════════════════════════════════════════

local RexPreload = {}

function RexPreload:KillACScripts()
    local killed = 0
    local targets = {
        workspace, LocalPlayer, LocalPlayer.PlayerGui,
        CoreGui, ReplicatedStorage, StarterGui,
    }
    for _, root in ipairs(targets) do
        pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("LocalScript") or obj:IsA("Script") or obj:IsA("ModuleScript") then
                    if matchesAC(obj.Name, AC_SCRIPT_PATTERNS) then
                        pcall(function()
                            obj.Disabled = true
                            killed += 1
                            rLog("Preload: Killed → " .. obj.Name)
                        end)
                    end
                end
            end
        end)
    end
    return killed
end

function RexPreload:DisconnectACRemotes()
    local cut = 0
    local roots = { ReplicatedStorage, workspace, LocalPlayer, LocalPlayer.PlayerGui }
    for _, root in ipairs(roots) do
        pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    if isSuspiciousRemote(obj.Name) then
                        pcall(function()
                            if getconnections then
                                local sig = pcall(function() return obj.OnClientEvent end) and obj.OnClientEvent
                                    or pcall(function() return obj.OnClientInvoke end) and obj.OnClientInvoke
                                if sig then
                                    for _, conn in ipairs(getconnections(sig)) do
                                        pcall(function() conn:Disable() end)
                                        cut += 1
                                    end
                                end
                            end
                            rLog("Preload: Cut remote → " .. obj.Name)
                        end)
                    end
                end
            end
        end)
    end
    return cut
end

function RexPreload:SpoofIdentityNow()
    pcall(function() set_thread_identity(7) end)
    pcall(function() setidentity(7) end)
end

function RexPreload:ClearTracesNow()
    pcall(function()
        local names = {
            "SYNAPSE_RUNNING","KRNL_LOADED","FLUXUS","SCRIPT_HUB","EXECUTOR",
            "COCO_Z","OXYGEN_U","EVON","ARCEUS_X","WAVE","HYDROGEN","DELTA","SOLARA","SELIOX",
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
    task.wait(0.3)
    local killed = RexPreload:KillACScripts()
    local cut    = RexPreload:DisconnectACRemotes()
    rLog(("Preload: %d scripts killed, %d remotes cut"):format(killed, cut))
    task.wait(0.2)
end

RexPreload:Run()

-- ════════════════════════════════════════
--  ЕДИНЫЙ ХУКЕР NAMECALL
--  hookmetamethod (stealth) + fallback
-- ════════════════════════════════════════

local RexHook = {}
RexHook._installed = false

local KICK_METHODS = { Kick=true }
local TELEPORT_METHODS = {
    Teleport=true, TeleportAsync=true,
    TeleportToPlaceInstance=true, TeleportToPrivateServer=true,
}

local function buildHandler(oldFn)
    return newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}

        if KICK_METHODS[method] then
            rLog("AntiKick: Blocked :" .. method .. "()")
            return
        end

        if TELEPORT_METHODS[method] and self == TeleportService then
            local pid = args[1]
            if pid and pid ~= game.PlaceId then
                rLog("AntiKick: Blocked teleport → " .. tostring(pid))
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
                if isSuspiciousRemote(n) and not isWhitelisted(n) then
                    rLog("AntiAC: Blocked remote: " .. n)
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
            hookmetamethod(game, "__namecall", buildHandler(nil))
            usedStealth = true
            rLog("Hook: hookmetamethod (stealth) installed")
        end
    end)

    if not usedStealth then
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            local old = mt.__namecall
            mt.__namecall = buildHandler(old)
            setreadonly(mt, true)
            rLog("Hook: fallback namecall installed")
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
                rLog("AntiKick: Restored health-zero kick")
            end
        end
    end)

    pcall(function()
        ScriptContext.Error:Connect(function(msg)
            if msg then
                local ml = msg:lower()
                if ml:find("kick") or ml:find("ban") or ml:find("cheat")
                or ml:find("exploit") or ml:find("violation") then
                    rLog("AntiKick: Suppressed error kick")
                    return false
                end
            end
        end)
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.3)
        rLog("AntiKick: Respawn — re-hooking")
        RexHook:Reinstall()
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
            Vector3.new( 0.03, 0,  0.00), Vector3.new(-0.03, 0,  0.00),
            Vector3.new( 0.00, 0,  0.03), Vector3.new( 0.00, 0, -0.03),
            Vector3.new( 0.02, 0,  0.02), Vector3.new(-0.02, 0, -0.02),
            Vector3.new( 0.01, 0, -0.01), Vector3.new( 0.00, 0,  0.00),
        }
        root.CFrame = root.CFrame + offsets[rRandInt(1, #offsets)]
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
        task.wait(rRand(0.04, 0.12))
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
        task.wait(rRand(0.02, 0.05))
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
                task.wait(rRand(2.0, 6.0))
                cycle = 0
            end
            task.wait(math.max(0.04, rRand(0.15,0.50) + rRand(0,0.20) * (math.random() > 0.5 and 1 or -1)))
        end
    end)

    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(45, 80))
            RexAntiBan:SpoofHeartbeat()
            RexAntiBan:SpoofCamera()
            RexAntiBan:SpoofMouseMove()
        end
    end)

    rLog("AntiBan: Initialized")
end

-- ════════════════════════════════════════
--  ANTI-AC
-- ════════════════════════════════════════

local RexAntiAC = {}

function RexAntiAC:CleanPlayerFlags()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(1.0, 2.5))
            pcall(function()
                for _, v in ipairs(LocalPlayer:GetDescendants()) do
                    local nl = v.Name:lower()
                    local bad = nl:find("cheat") or nl:find("exploit") or nl:find("flag")
                        or nl:find("ban") or nl:find("detect") or nl:find("hack")
                        or nl:find("violation") or nl:find("punish")
                    if bad and (v:IsA("BoolValue") or v:IsA("StringValue") or v:IsA("IntValue")) then
                        pcall(function()
                            if v:IsA("BoolValue") then v.Value = false
                            elseif v:IsA("IntValue") then v.Value = 0
                            elseif v:IsA("StringValue") then v.Value = ""
                            end
                        end)
                        rLog("AntiAC: Cleared flag: " .. v.Name)
                    end
                end
            end)
        end
    end)
end

function RexAntiAC:SpoofHumanoidState()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(0.5, 1.2))
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
            task.wait(rRand(2.5, 6.0))
            pcall(function()
                local hum  = rGetHum()
                local root = rGetRoot()
                if hum and root then
                    local moving = root.AssemblyLinearVelocity.Magnitude > 0.5
                    if not moving and hum.WalkSpeed > 40 then
                        local saved = hum.WalkSpeed
                        hum.WalkSpeed = 16
                        task.wait(rRand(0.1, 0.25))
                        hum.WalkSpeed = saved
                    end
                end
            end)
        end
    end)
end

function RexAntiAC:MonitorACScripts()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(1.5, 3.5))
            pcall(function()
                for _, obj in ipairs(LocalPlayer:GetDescendants()) do
                    if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                        if matchesAC(obj.Name, AC_SCRIPT_PATTERNS) then
                            pcall(function() obj.Disabled = true end)
                            rLog("AntiAC: Disabled: " .. obj.Name)
                        end
                    end
                end
            end)
        end
    end)
end

function RexAntiAC:Init()
    RexAntiAC:CleanPlayerFlags()
    RexAntiAC:SpoofHumanoidState()
    RexAntiAC:SpoofWalkSpeed()
    RexAntiAC:MonitorACScripts()
    rLog("AntiAC: Initialized")
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
            "COCO_Z","OXYGEN_U","EVON","ARCEUS_X","WAVE","HYDROGEN","DELTA","SOLARA","SELIOX",
        }
        local G = getfenv(0)
        for _, name in ipairs(names) do
            if G[name] ~= nil then pcall(function() G[name] = nil end) end
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
            task.wait(rRand(18, 35))
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
    table.insert(RexGuardian.Watchlist, { name = name, fn = fn })
end

function RexGuardian:Init()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(4.0, 8.0))
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

local logLabel    = nil
local statusLabel = nil

local function refreshLog()
    if logLabel then
        logLabel:Set("Last: " .. (Rex.Log[#Rex.Log] or "No events yet."))
    end
end

local HomeTab = Window:CreateTab("🛡 Rex", 4483362458)
HomeTab:CreateSection("Status")
statusLabel = HomeTab:CreateLabel("Status: ⭕ Inactive")
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
            RexGuardian:Watch("AntiAC",     function() RexAntiAC:CleanPlayerFlags() end)
            RexGuardian:Watch("Preload",    function() RexPreload:KillACScripts() end)
            RexGuardian:Init()

            if statusLabel then statusLabel:Set("Status: ✅ Active — All modules running") end

            Rayfield:Notify({
                Title    = "🛡 Rex Active",
                Content  = "Anti-Kick · Anti-Ban · Anti-AC · Anti-Detect",
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
            Rayfield:Notify({
                Title    = "🛡 Rex Stopped",
                Content  = "All modules disabled.",
                Duration = 3,
            })
        end
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
    Name     = "🗑️ Clear Log",
    Callback = function()
        Rex.Log = {}
        if logLabel then logLabel:Set("Last: —") end
        Rayfield:Notify({ Title = "Cleared", Content = "Rex log cleared.", Duration = 2 })
    end,
})

HomeTab:CreateButton({
    Name     = "🔄 Re-scan AC Scripts",
    Callback = function()
        local k = RexPreload:KillACScripts()
        local c = RexPreload:DisconnectACRemotes()
        Rayfield:Notify({
            Title   = "🔄 Re-scan Done",
            Content = k .. " scripts killed, " .. c .. " remotes cut",
            Duration = 4,
        })
    end,
})

local AntiKickTab = Window:CreateTab("🦵 Anti-Kick", 4483362458)
AntiKickTab:CreateSection("Methods")
AntiKickTab:CreateLabel("⚔ hookmetamethod stealth (Error 267 fix)")
AntiKickTab:CreateLabel("⚔ Player:Kick() blocked on any object")
AntiKickTab:CreateLabel("⚔ TeleportService kick blocker")
AntiKickTab:CreateLabel("⚔ NetworkClient disconnect blocked")
AntiKickTab:CreateLabel("⚔ Health-zero prevention (0.05s loop)")
AntiKickTab:CreateLabel("⚔ ScriptContext error suppression")
AntiKickTab:CreateLabel("⚔ Auto re-hook on respawn")

local AntiBanTab = Window:CreateTab("🚫 Anti-Ban", 4483362458)
AntiBanTab:CreateSection("Methods")
AntiBanTab:CreateLabel("⚔ Micro-movements every cycle")
AntiBanTab:CreateLabel("⚔ Camera spoof every 3 cycles")
AntiBanTab:CreateLabel("⚔ Mouse spoof every 6 cycles")
AntiBanTab:CreateLabel("⚔ Heartbeat every 4 cycles")
AntiBanTab:CreateLabel("⚔ Click spoof every 15 cycles")
AntiBanTab:CreateLabel("⚔ Long human pause every 45–65 cycles")
AntiBanTab:CreateLabel("⚔ Independent idle loop every ~60s")

local AntiACTab = Window:CreateTab("🔒 Anti-AC", 4483362458)
AntiACTab:CreateSection("Methods")
AntiACTab:CreateLabel("⚔ Preload: kills AC scripts before hooks")
AntiACTab:CreateLabel("⚔ Preload: cuts AC remote connections")
AntiACTab:CreateLabel("⚔ Player flag cleaner loop")
AntiACTab:CreateLabel("⚔ Humanoid state spoofing")
AntiACTab:CreateLabel("⚔ WalkSpeed masking when idle")
AntiACTab:CreateLabel("⚔ AC LocalScript disabler loop")

local AntiDetectTab = Window:CreateTab("👁 Anti-Detect", 4483362458)
AntiDetectTab:CreateSection("Methods")
AntiDetectTab:CreateLabel("⚔ Thread identity spoof (ID 7 on load)")
AntiDetectTab:CreateLabel("⚔ Executor env variable cleaner")
AntiDetectTab:CreateLabel("⚔ __index spoof for game properties")
AntiDetectTab:CreateLabel("⚔ Re-spoofs every 18–35 seconds")

local GuardianTab = Window:CreateTab("👁‍🗨 Guardian", 4483362458)
GuardianTab:CreateSection("Self-Repair")
GuardianTab:CreateLabel("⚔ Monitors all modules every 4–8s")
GuardianTab:CreateLabel("⚔ Restarts any crashed module auto")
GuardianTab:CreateLabel("⚔ Runs Preload scan every cycle")
GuardianTab:CreateLabel("⚔ All events logged to Rex Log")

local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)
MiscTab:CreateSection("Info")
MiscTab:CreateLabel("Rex v" .. Rex.Version)
MiscTab:CreateLabel("Anti-Kick · Anti-Ban · Anti-AC · Anti-Detect")
MiscTab:CreateLabel("Guardian — Self-Repair Engine")
MiscTab:CreateLabel("Preloader — AC Killer on connect")

Rayfield:Notify({
    Title    = "🛡 Rex v" .. Rex.Version,
    Content  = "Preload done. Enable protection in the Rex tab.",
    Duration = 5,
    Image    = 4483362458,
})
