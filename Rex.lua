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
    pcall(function() print(entry) end)
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

local function showSplash()
    local vp = Camera.ViewportSize
    local cx = vp.X / 2
    local cy = vp.Y / 2

    local bg = Drawing.new("Square")
    bg.Size         = Vector2.new(400, 130)
    bg.Position     = Vector2.new(cx - 200, cy - 65)
    bg.Color        = Color3.fromRGB(8, 8, 14)
    bg.Filled       = true
    bg.Thickness    = 1
    bg.Visible      = true
    bg.Transparency = 0.1

    local border = Drawing.new("Square")
    border.Size      = Vector2.new(400, 130)
    border.Position  = Vector2.new(cx - 200, cy - 65)
    border.Color     = Color3.fromRGB(80, 120, 255)
    border.Filled    = false
    border.Thickness = 2
    border.Visible   = true

    local accent = Drawing.new("Square")
    accent.Size     = Vector2.new(400, 3)
    accent.Position = Vector2.new(cx - 200, cy - 65)
    accent.Color    = Color3.fromRGB(80, 120, 255)
    accent.Filled   = true
    accent.Thickness = 1
    accent.Visible  = true

    local title = Drawing.new("Text")
    title.Text         = "Start Rex"
    title.Size         = 38
    title.Font         = Drawing.Fonts.GothamBold
    title.Color        = Color3.fromRGB(255, 255, 255)
    title.Position     = Vector2.new(cx, cy - 18)
    title.Center       = true
    title.Outline      = true
    title.OutlineColor = Color3.fromRGB(0, 0, 0)
    title.Visible      = true

    local ver = Drawing.new("Text")
    ver.Text         = "v" .. Rex.Version
    ver.Size         = 18
    ver.Font         = Drawing.Fonts.Gotham
    ver.Color        = Color3.fromRGB(130, 160, 255)
    ver.Position     = Vector2.new(cx, cy + 18)
    ver.Center       = true
    ver.Outline      = true
    ver.OutlineColor = Color3.fromRGB(0, 0, 0)
    ver.Visible      = true

    local sub = Drawing.new("Text")
    sub.Text     = "Protection System · Loading..."
    sub.Size     = 13
    sub.Font     = Drawing.Fonts.Gotham
    sub.Color    = Color3.fromRGB(160, 160, 180)
    sub.Position = Vector2.new(cx, cy + 44)
    sub.Center   = true
    sub.Outline  = false
    sub.Visible  = true

    task.delay(3.5, function()
        for _, d in ipairs({ bg, border, accent, title, ver, sub }) do
            pcall(function() d:Remove() end)
        end
    end)
end

pcall(showSplash)

local RexAntiKick = {}
RexAntiKick._hooked = false

function RexAntiKick:HookNamecall()
    if RexAntiKick._hooked then return end
    RexAntiKick._hooked = true
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args   = {...}

            if method == "Kick" then
                rLog("AntiKick: Blocked :Kick() on " .. tostring(self))
                return
            end

            if (method == "TeleportToPlaceInstance" or method == "Teleport"
                or method == "TeleportAsync" or method == "TeleportToPrivateServer") then
                if self == TeleportService then
                    local pid = args[1]
                    if pid and pid ~= game.PlaceId then
                        rLog("AntiKick: Blocked teleport kick → " .. tostring(pid))
                        return
                    end
                end
            end

            if method == "Disconnect" then
                if self == NetworkClient or tostring(self):lower():find("network") then
                    rLog("AntiKick: Blocked network disconnect")
                    return
                end
            end

            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

function RexAntiKick:HookHealthZero()
    rSpawn(function()
        while Rex.Active do
            task.wait(0.05)
            local hum = rGetHum()
            if hum then
                if hum.Health <= 0 and hum.MaxHealth > 0 then
                    pcall(function()
                        hum.Health = hum.MaxHealth
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end)
                    rLog("AntiKick: Prevented health-zero kick")
                end
            end
        end
    end)
end

function RexAntiKick:HookErrors()
    pcall(function()
        ScriptContext.Error:Connect(function(msg, trace, script)
            if msg then
                local ml = msg:lower()
                if ml:find("kick") or ml:find("ban") or ml:find("cheat")
                or ml:find("exploit") or ml:find("violation") then
                    rLog("AntiKick: Suppressed crash kick: " .. tostring(msg):sub(1, 60))
                    return false
                end
            end
        end)
    end)
end

function RexAntiKick:HookCharacterRespawn()
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        rLog("AntiKick: Character respawned — re-applying hooks")
        RexAntiKick._hooked = false
        task.wait(0.1)
        RexAntiKick:HookNamecall()
    end)
end

function RexAntiKick:Init()
    RexAntiKick:HookNamecall()
    RexAntiKick:HookHealthZero()
    RexAntiKick:HookErrors()
    RexAntiKick:HookCharacterRespawn()
    rLog("AntiKick: Initialized")
end

local RexAntiBan = {}

function RexAntiBan:SpoofMovement()
    local root = rGetRoot()
    if not root then return end
    pcall(function()
        local offsets = {
            Vector3.new( 0.03, 0,  0.00),
            Vector3.new(-0.03, 0,  0.00),
            Vector3.new( 0.00, 0,  0.03),
            Vector3.new( 0.00, 0, -0.03),
            Vector3.new( 0.02, 0,  0.02),
            Vector3.new(-0.02, 0, -0.02),
            Vector3.new( 0.01, 0, -0.01),
            Vector3.new( 0.00, 0,  0.00),
        }
        local pick = offsets[rRandInt(1, #offsets)]
        root.CFrame = root.CFrame + pick
    end)
end

function RexAntiBan:SpoofCamera()
    pcall(function()
        if not Camera then return end
        local yaw   = rRand(-0.0008, 0.0008)
        local pitch = rRand(-0.0003, 0.0003)
        Camera.CFrame = Camera.CFrame * CFrame.Angles(pitch, yaw, 0)
    end)
end

function RexAntiBan:SpoofHeartbeat()
    pcall(function()
        VirtualUser:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
        task.wait(rRand(0.04, 0.12))
        VirtualUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
    end)
end

function RexAntiBan:SpoofMouseMove()
    pcall(function()
        VirtualUser:MoveMouse(Vector2.new(rRandInt(-4, 4), rRandInt(-4, 4)))
    end)
end

function RexAntiBan:SpoofClickActivity()
    pcall(function()
        VirtualUser:Button1Down(Vector2.new(rRandInt(100, 400), rRandInt(100, 400)), workspace.CurrentCamera.CFrame)
        task.wait(rRand(0.02, 0.06))
        VirtualUser:Button1Up(Vector2.new(rRandInt(100, 400), rRandInt(100, 400)), workspace.CurrentCamera.CFrame)
    end)
end

function RexAntiBan:RandomTiming()
    local base   = rRand(0.15, 0.50)
    local jitter = rRand(0, 0.20) * (math.random() > 0.5 and 1 or -1)
    return math.max(0.04, base + jitter)
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
            if cycle % 15 == 0 then RexAntiBan:SpoofClickActivity() end
            if cycle % rRandInt(45, 65) == 0 then
                task.wait(rRand(2.0, 6.0))
                cycle = 0
            end
            task.wait(RexAntiBan:RandomTiming())
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

local RexAntiAC = {}

RexAntiAC.Whitelist = {
    "claimreward","collectreward","yenreward","eventreward","likereward",
    "afkreward","spinreward","dailyreward","freereward","collect","claim",
    "purchase","buy","shop","store","inventory","equip","open","quest",
}

RexAntiAC.Suspicious = {
    "detect","anticheat","anti_cheat","ac_","cheatcheck","speedcheck",
    "flycheck","teleportcheck","flagplayer","reportplayer","banplayer",
    "kickplayer","punishment","violation","exploit","hack","cheat",
    "monitor","watchdog","scanner","verify","validate","integrity",
}

function RexAntiAC:IsSuspicious(name)
    local nl = name:lower()
    for _, pat in ipairs(RexAntiAC.Suspicious) do
        if nl:find(pat) then return true end
    end
    return false
end

function RexAntiAC:IsWhitelisted(name)
    local nl = name:lower()
    for _, w in ipairs(RexAntiAC.Whitelist) do
        if nl:find(w) then return true end
    end
    return false
end

function RexAntiAC:BlockRemotes()
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer"
            or method == "FireClient" or method == "InvokeClient" then
                if pcall(function() return self:IsA("RemoteEvent") or self:IsA("RemoteFunction") end) then
                    local name = self.Name
                    if RexAntiAC:IsSuspicious(name) and not RexAntiAC:IsWhitelisted(name) then
                        rLog("AntiAC: Blocked remote: " .. name)
                        return nil
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

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
                        local nl = obj.Name:lower()
                        if nl:find("anticheat") or nl:find("detect") or nl:find("check")
                        or nl:find("monitor") or nl:find("watchdog") then
                            pcall(function() obj.Disabled = true end)
                            rLog("AntiAC: Disabled AC script: " .. obj.Name)
                        end
                    end
                end
            end)
        end
    end)
end

function RexAntiAC:Init()
    RexAntiAC:BlockRemotes()
    RexAntiAC:CleanPlayerFlags()
    RexAntiAC:SpoofHumanoidState()
    RexAntiAC:SpoofWalkSpeed()
    RexAntiAC:MonitorACScripts()
    rLog("AntiAC: Initialized")
end

local RexAntiDetect = {}

function RexAntiDetect:SpoofIdentity()
    pcall(function()
        local ids = {4, 5, 6, 7}
        set_thread_identity(ids[rRandInt(1, #ids)])
    end)
    pcall(function()
        setidentity(rRandInt(4, 7))
    end)
end

function RexAntiDetect:ClearTraces()
    pcall(function()
        local names = {
            "SYNAPSE_RUNNING","KRNL_LOADED","FLUXUS","SCRIPT_HUB",
            "EXECUTOR","COCO_Z","OXYGEN_U","EVON","ARCEUS_X",
        }
        local G = getfenv(0)
        for _, name in ipairs(names) do
            if G[name] ~= nil then
                pcall(function() G[name] = nil end)
            end
        end
    end)
end

function RexAntiDetect:SpoofIndex()
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local oldIndex = mt.__index
        mt.__index = newcclosure(function(self, key)
            if key == "PlaceVersion" or key == "JobId" or key == "CreatorId" then
                if type(oldIndex) == "function" then
                    local ok, val = pcall(oldIndex, self, key)
                    return ok and val or nil
                end
            end
            if type(oldIndex) == "function" then
                return oldIndex(self, key)
            end
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
            task.wait(rRand(20, 40))
            RexAntiDetect:SpoofIdentity()
            RexAntiDetect:ClearTraces()
        end
    end)
    rLog("AntiDetect: Initialized")
end

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
        local last = Rex.Log[#Rex.Log] or "No events yet."
        logLabel:Set("Last: " .. last)
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

            RexGuardian:Watch("AntiKick",   function() RexAntiKick:HookNamecall() end)
            RexGuardian:Watch("AntiBan",    function() RexAntiBan:SpoofHeartbeat() end)
            RexGuardian:Watch("AntiDetect", function() RexAntiDetect:ClearTraces() end)
            RexGuardian:Watch("AntiAC",     function() RexAntiAC:CleanPlayerFlags() end)
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
            RexAntiKick._hooked = false
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
        local start = math.max(1, #Rex.Log - 4)
        for i = start, #Rex.Log do table.insert(lines, Rex.Log[i]) end
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

local AntiKickTab = Window:CreateTab("🦵 Anti-Kick", 4483362458)
AntiKickTab:CreateSection("Methods")
AntiKickTab:CreateLabel("⚔ Player:Kick() namecall hook (all callers)")
AntiKickTab:CreateLabel("⚔ TeleportService kick blocker")
AntiKickTab:CreateLabel("⚔ Network disconnect hook")
AntiKickTab:CreateLabel("⚔ Health-zero kick prevention (0.05s loop)")
AntiKickTab:CreateLabel("⚔ ScriptContext error kick suppression")
AntiKickTab:CreateLabel("⚔ Auto re-hook on character respawn")

local AntiBanTab = Window:CreateTab("🚫 Anti-Ban", 4483362458)
AntiBanTab:CreateSection("Methods")
AntiBanTab:CreateLabel("⚔ Micro-movements every cycle")
AntiBanTab:CreateLabel("⚔ Camera angle spoof every 3 cycles")
AntiBanTab:CreateLabel("⚔ Mouse spoof every 6 cycles")
AntiBanTab:CreateLabel("⚔ VirtualUser heartbeat every 4 cycles")
AntiBanTab:CreateLabel("⚔ Click activity spoof every 15 cycles")
AntiBanTab:CreateLabel("⚔ Long human pause every 45–65 cycles")
AntiBanTab:CreateLabel("⚔ Independent idle heartbeat every ~60s")

local AntiACTab = Window:CreateTab("🔒 Anti-AC", 4483362458)
AntiACTab:CreateSection("Methods")
AntiACTab:CreateLabel("⚔ Suspicious RemoteEvent/Function blocker")
AntiACTab:CreateLabel("⚔ Player flag cleaner (BoolValue/IntValue)")
AntiACTab:CreateLabel("⚔ Humanoid state spoofing")
AntiACTab:CreateLabel("⚔ WalkSpeed masking when idle")
AntiACTab:CreateLabel("⚔ AC LocalScript disabler")

local AntiDetectTab = Window:CreateTab("👁 Anti-Detect", 4483362458)
AntiDetectTab:CreateSection("Methods")
AntiDetectTab:CreateLabel("⚔ Thread identity spoofing")
AntiDetectTab:CreateLabel("⚔ Executor env variable cleaner")
AntiDetectTab:CreateLabel("⚔ __index spoof for game properties")
AntiDetectTab:CreateLabel("⚔ Re-spoofs every 20–40 seconds")

local GuardianTab = Window:CreateTab("👁‍🗨 Guardian", 4483362458)
GuardianTab:CreateSection("Self-Repair")
GuardianTab:CreateLabel("⚔ Monitors all modules every 4–8s")
GuardianTab:CreateLabel("⚔ Auto-restarts any crashed module")
GuardianTab:CreateLabel("⚔ Logs every restart to Rex Log")

local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)
MiscTab:CreateSection("Info")
MiscTab:CreateLabel("Rex v" .. Rex.Version)
MiscTab:CreateLabel("Anti-Kick · Anti-Ban · Anti-AC · Anti-Detect")
MiscTab:CreateLabel("Guardian — Self-Repair Engine")

Rayfield:Notify({
    Title    = "🛡 Rex v" .. Rex.Version,
    Content  = "Ready. Enable protection in the Rex tab.",
    Duration = 5,
    Image    = 4483362458,
})
