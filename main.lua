-- Yvetzal: Funky Friday Autoplay (Optimized DAS v4.5 & High-Performance Low-GC Engine)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local players = game:GetService("Players")
local runService = game:GetService("RunService")
local httpService = game:GetService("HttpService")
local localPlayer = players.LocalPlayer
local shared = type(getgenv) == "function" and getgenv() or _G

-- Kill prior instances
if shared.GoodGammingChairCleanup then
    pcall(shared.GoodGammingChairCleanup)
end
if shared.YvetzalFunkyFriday and shared.YvetzalFunkyFriday.stop then
    pcall(shared.YvetzalFunkyFriday.stop)
end

-- ------------------------------------------------------------ CONFIGURATION SYSTEM

local CONFIG_FILE = "Yvetzal_FunkyFriday.json"

local DefaultConfig = {
    autoplay = true,
    dodge = true,
    mechanics = true,
    sideMode = "Auto",
    holdTime = 0.150,
    mechanicInterval = 0.05,
    -- Timing Weights
    sickPct = 92,
    goodPct = 6,
    okPct = 2,
    badPct = 0,
    missPct = 0,
    missCooldown = 4.0,
    sickMaxOffsetMs = 18,
    -- Dynamic Accuracy Scaling (DAS v4.5)
    dynamicAccuracy = true,
    denseThresholdMs = 45,
    sparseThresholdMs = 240,
    comfortNps = 7,
    hardNps = 14,
    strainPenaltyPct = 40,
    spamMinNps = 9,
    strainDecayRate = 2.0,
    jackStrainWeight = 0.20,
    -- Dynamic Missing Based on Difficulty (DMBOD v4.5)
    dmbod = false,
    dmbodMaxMissPct = 5,
    -- Watcher Engine
    watcherEnabled = true,
}

local State = {}
for k, v in pairs(DefaultConfig) do
    State[k] = v
end
State.autoSide = "Left"
State.inMatch = false
State.actorInjected = false
State.sessionActive = false
State.sessionStartTime = 0

local function loadConfig()
    if type(readfile) == "function" and type(isfile) == "function" and isfile(CONFIG_FILE) then
        local ok, data = pcall(function()
            return httpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do
                if State[k] ~= nil then
                    State[k] = v
                end
            end
            return true
        end
    end
    return false
end

local function saveConfig()
    if type(writefile) == "function" then
        local toSave = {}
        for k in pairs(DefaultConfig) do
            toSave[k] = State[k]
        end
        pcall(writefile, CONFIG_FILE, httpService:JSONEncode(toSave))
    end
end

loadConfig()

-- ------------------------------------------------------------ THEME & ASSETS

local theme = {
    WindowColor = ColorSequence.new(Color3.fromRGB(8, 8, 8), Color3.fromRGB(0, 0, 0)),
    ShadowColor = Color3.fromRGB(0, 0, 0),
    SurfaceStroke = Color3.fromRGB(120, 15, 15),
    CornerRoundness = UDim.new(0, 8),
    ElementCornerRadius = UDim.new(0, 6),
    ContentColor = Color3.fromRGB(230, 230, 230),
    TitlingColor = Color3.fromRGB(255, 255, 255),
    ActionColor = Color3.fromRGB(255, 255, 255),
    ElementTextHoverColor = Color3.fromRGB(255, 255, 255),
    TabColor = Color3.fromRGB(255, 255, 255),
    TabBackground = ColorSequence.new(Color3.fromRGB(22, 22, 22), Color3.fromRGB(8, 8, 8)),
    TabStroke = ColorSequence.new(Color3.fromRGB(230, 30, 30), Color3.fromRGB(110, 10, 10)),
    ElementGradient = ColorSequence.new(Color3.fromRGB(18, 18, 18), Color3.fromRGB(10, 10, 10)),
    ElementStroke = Color3.fromRGB(60, 60, 60),
    ElementStrokeHover = Color3.fromRGB(230, 40, 40),
    StatBackground = Color3.fromRGB(30, 6, 6),
    AccentColor = Color3.fromRGB(220, 25, 25),
    AccentStroke = Color3.fromRGB(255, 70, 70),
    SliderBackground = Color3.fromRGB(35, 35, 35),
    SliderProgress = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(210, 210, 210)),
    SliderHandle = Color3.fromRGB(255, 255, 255),
    SliderStroke = Color3.fromRGB(60, 60, 60),
    ToggleTrack = Color3.fromRGB(30, 30, 30),
    ToggleKnobOff = Color3.fromRGB(220, 220, 220),
    DropdownHighlight = Color3.fromRGB(180, 25, 25),
    FieldBackground = Color3.fromRGB(14, 14, 14),
    FieldGlow = Color3.fromRGB(120, 20, 20),
    PlaceholderColor = Color3.fromRGB(150, 150, 150),
    NeutralButton = Color3.fromRGB(26, 26, 26),
    NeutralButtonHover = Color3.fromRGB(45, 45, 45),
    NeutralButtonStroke = Color3.fromRGB(80, 15, 15),
    ErrorColor = Color3.fromRGB(230, 40, 40),
    ErrorStrokeColor = Color3.fromRGB(255, 90, 90),
}

local icons = {
    ["box-select"] = { 16898612819, 820, 147 },
    crosshair = { 16898613044, 453, 869 },
    eye = { 16898613353, 771, 563 },
    flame = { 16898613353, 967, 306 },
    palette = { 16898613613, 453, 918 },
    settings = { 16898613777, 771, 257 },
}

local function iconAsset(name)
    local i = icons[name]
    return i and ("rbxassetid://" .. i[1])
end

local function cropIcon(img, name)
    local i = icons[name]
    if img and i then
        img.ImageRectSize = Vector2.new(48, 48)
        img.ImageRectOffset = Vector2.new(i[2], i[3])
    end
end

local rayfield
for _, url in ipairs({
    "https://sirius.menu/gen2",
    "https://sirius.menu/rayfield",
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
}) do
    local ok, res = pcall(function()
        local src = game:HttpGet(url)
        local fn = loadstring(src)
        if type(fn) == "function" then
            return fn()
        end
        return nil
    end)
    if ok and type(res) == "table" and (res.CreateWindow or res.createWindow) then
        rayfield = res
        break
    end
end

if not rayfield then
    warn("[Yvetzal] Failed to load Rayfield UI engine.")
    return
end

local window = rayfield:CreateWindow({
    name = "Yvetzal",
    subtitle = "FUNKY FRIDAY HIGH-PERFORMANCE v4.5",
    icon = iconAsset("flame"),
    showName = "Yvetzal",
    showIcon = iconAsset("flame"),
    sidebarLayout = true,
    profile = "Infernum",
    theme = theme,
})
cropIcon(window.topbarIcon, "flame")
cropIcon(window.collapsedIcon, "flame")

local function makeTab(name, icon)
    local tab = window:CreateTab({ name = name, icon = iconAsset(icon) })
    cropIcon(tab.topbarItemIcon, icon)
    local createSection = tab.CreateSection
    tab.CreateSection = function(self, props)
        local sIcon = props.icon
        props.icon = iconAsset(sIcon)
        local section = createSection(self, props)
        cropIcon(section.iconLabel, sIcon)
        return section
    end
    return tab
end

local mainTab = makeTab("Autoplay", "eye")
local watcherTab = makeTab("Watcher", "crosshair")
local settingsTab = makeTab("Settings", "settings")

-- ------------------------------------------------------------ UI ADAPTER

local function createTextItem(targetTab, title, initialText)
    local item = nil
    local combinedText = (title and (title .. "\n") or "") .. (initialText or "")

    if type(targetTab.CreateParagraph) == "function" then
        local ok, res = pcall(function()
            return targetTab:CreateParagraph({ Title = title or "Info", Content = initialText or "--" })
        end)
        if ok and res then item = res end
    end

    if not item and type(targetTab.CreateLabel) == "function" then
        local ok, res = pcall(function()
            return targetTab:CreateLabel({ name = title or "Info", text = initialText or "--" })
        end)
        if not ok or not res then
            ok, res = pcall(function()
                return targetTab:CreateLabel(combinedText)
            end)
        end
        if ok and res then item = res end
    end

    local handle = {
        raw = item,
        title = title or "",
        content = initialText or "--",
    }

    function handle:Set(props)
        local newTitle = (type(props) == "table" and (props.Title or props.title)) or self.title
        local newContent = (type(props) == "table" and (props.Content or props.content)) or (type(props) == "string" and props) or self.content

        self.title = newTitle
        self.content = newContent

        if not self.raw then return end
        local fullText = (self.title ~= "" and (self.title .. "\n") or "") .. self.content

        if type(self.raw.Set) == "function" then
            pcall(function()
                self.raw:Set({ Title = self.title, Content = self.content })
            end)
        elseif type(self.raw.set) == "function" then
            pcall(function()
                self.raw:set(fullText)
            end)
        end
    end

    return handle
end

-- ------------------------------------------------------------ STATE MANAGEMENT

local runToken = {}
shared.YvetzalFunkyFridayToken = runToken
local runId = tostring(runToken)

local function isAlive()
    return shared.YvetzalFunkyFridayToken == runToken
end

local connections = {}
local function track(conn)
    connections[#connections + 1] = conn
    return conn
end

local state = { alive = true, stop = nil }

-- ------------------------------------------------------------ SIDE DETECTION

local cachedStagesFolder = nil
local lastStageSearch = 0

local Side = {}

function Side.detect()
    local now = os.clock()
    if not cachedStagesFolder or (now - lastStageSearch > 5.0) then
        lastStageSearch = now
        local map = workspace:FindFirstChild("Map")
        cachedStagesFolder = map and map:FindFirstChild("Stages")
    end

    if not cachedStagesFolder then return nil end

    local marker = cachedStagesFolder:FindFirstChild(localPlayer.Name, true)
    if not marker and localPlayer.DisplayName ~= localPlayer.Name then
        marker = cachedStagesFolder:FindFirstChild(localPlayer.DisplayName, true)
    end

    local cur = marker and marker.Parent
    while cur and cur ~= cachedStagesFolder do
        local n = cur.Name
        if n:find("Left", 1, true) then return "Left" end
        if n:find("Right", 1, true) then return "Right" end
        cur = cur.Parent
    end
    return nil
end

function Side.update()
    if State.sideMode ~= "Auto" then
        if State.sideMode ~= State.autoSide then
            State.autoSide = State.sideMode
            pcall(function() localPlayer:SetAttribute("GCCSide", State.autoSide) end)
        end
        return State.autoSide
    end

    local side = Side.detect()
    if side and side ~= State.autoSide then
        State.autoSide = side
        pcall(function() localPlayer:SetAttribute("GCCSide", side) end)
    end
    return side
end

-- ------------------------------------------------------------ GAME UI HOOK

local GameUI = { game = nil, fields = nil, nextTry = 0 }

function GameUI.get(now)
    local g, f = GameUI.game, GameUI.fields
    if g and f and g.Parent and f.Parent then
        return g, f
    end
    if now < GameUI.nextTry then return nil, nil end
    GameUI.nextTry = now + 0.5

    local pgui = localPlayer:FindFirstChild("PlayerGui")
    local win = pgui and pgui:FindFirstChild("Window")
    g = win and win:FindFirstChild("Game")
    f = g and g:FindFirstChild("Fields")
    GameUI.game, GameUI.fields = g, f
    return g, f
end

-- ------------------------------------------------------------ ACTOR FLAGS

local function syncFlags()
    pcall(function()
        localPlayer:SetAttribute("GCCAP", State.autoplay)
        localPlayer:SetAttribute("GCCMechanics", State.mechanics)
        localPlayer:SetAttribute("GCCMechanicInterval", State.mechanicInterval)
        localPlayer:SetAttribute("GCCHoldMs", math.floor(State.holdTime * 1000))
        localPlayer:SetAttribute("GCCDodge", State.dodge)
        localPlayer:SetAttribute("GCCSide", State.autoSide)
        localPlayer:SetAttribute("GCCAlive", isAlive())
        localPlayer:SetAttribute("GCCRunId", runId)
        localPlayer:SetAttribute("GCCSickPct", State.sickPct)
        localPlayer:SetAttribute("GCCGoodPct", State.goodPct)
        localPlayer:SetAttribute("GCCOkPct", State.okPct)
        localPlayer:SetAttribute("GCCBadPct", State.badPct)
        localPlayer:SetAttribute("GCCMissPct", State.missPct)
        localPlayer:SetAttribute("GCCMissCooldown", State.missCooldown)
        localPlayer:SetAttribute("GCCSickMaxOffset", State.sickMaxOffsetMs)
        localPlayer:SetAttribute("GCCDynAcc", State.dynamicAccuracy)
        localPlayer:SetAttribute("GCDenseMs", State.denseThresholdMs)
        localPlayer:SetAttribute("GCSparseMs", State.sparseThresholdMs)
        localPlayer:SetAttribute("GCComfortNps", State.comfortNps)
        localPlayer:SetAttribute("GCHardNps", State.hardNps)
        localPlayer:SetAttribute("GCPenaltyPct", State.strainPenaltyPct)
        localPlayer:SetAttribute("GCSpamMinNps", State.spamMinNps)
        localPlayer:SetAttribute("GCStrainDecay", State.strainDecayRate)
        localPlayer:SetAttribute("GCJackWeight", State.jackStrainWeight)
        localPlayer:SetAttribute("GCCDmbod", State.dmbod)
        localPlayer:SetAttribute("GCDmbodMaxMiss", State.dmbodMaxMissPct)
        localPlayer:SetAttribute("GCCWatcherActive", State.watcherEnabled)
        localPlayer:SetAttribute("GCC_W_SessionActive", State.sessionActive)
    end)
end

local function releaseAll()
    pcall(function()
        localPlayer:SetAttribute("GCCReleaseAll", (tonumber(localPlayer:GetAttribute("GCCReleaseAll")) or 0) + 1)
    end)
end

-- ------------------------------------------------------------ HIGH SPEED ACTOR WORKER

local function injectActor()
    if State.actorInjected then
        return localPlayer:GetAttribute("GCCFW") == true
    end
    if type(run_on_actor) ~= "function" then return false end

    local ps = localPlayer:FindFirstChild("PlayerScripts")
    local actor = ps and (ps:FindFirstChild("ClientActor") or ps:FindFirstChildWhichIsA("Actor"))
    if not actor then return false end

    State.actorInjected = true
    syncFlags()

    run_on_actor(actor, [=[
        local Players = game:GetService("Players")
        local LP = Players.LocalPlayer
        local RS = game:GetService("RunService")
        local actorRunId = LP:GetAttribute("GCCRunId")

        local clockS = (type(tick) == "function") and tick or time
        local math_random = math.random
        local math_abs = math.abs
        local math_min = math.min
        local math_max = math.max
        local math_clamp = math.clamp
        local math_floor = math.floor
        local math_exp = math.exp

        local fwV = nil
        local laneCount = 4
        local maxLane, zeroBased = 0, false
        local lastField, lastGame, lastNoteCache
        local nextCountCheck = 0
        local lastV = nil
        local tpV, tpVAt = nil, 0
        local sideBroken, sideBrokenSince = false, nil
        local hitLaneSeen = false
        local activeField

        local lastMechanicAction
        local nextMechanicDispatchTime = 0
        local mechanicCentered = false
        local nextSearchAt = 0
        local cachedPlayerGui
        local cachedPendulumPivot
        local nextPendulumRefresh = 0

        -- Accuracy Weights
        local cumSick = 92
        local cumGood = 98
        local cumOk = 100
        local cumBad = 100
        local totalWeight = 100
        local nextMissAllowedAt = 0

        -- Metrics & Rhythm Buffer
        local lastGlobalNoteTime = 0
        local lastDistinctNoteTime = 0
        local lastLaneNoteTime = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }

        local NPS_WINDOW = 1.25
        local RING_SIZE = 64
        local npsRing = table.create(RING_SIZE, 0)
        local ringHead = 1
        local ringCount = 0

        local accumulatedStrain = 0
        local lastStrainUpdateTime = 0
        local currentJackStrain = 0
        local currentDiffIndex = 0

        local currentPeakNPS = 0
        local lastComputedRollingNPS = 0
        local currentSpam = false
        local currentComfort = "COMFORTABLE"
        local dasActivationCount = 0
        local dmbodTriggerCount = 0
        local totalActualMissCount = 0
        local currentDynamicMissRate = 0
        local nextTelemetrySyncAt = 0

        local sessionTotalNotes = 0
        local sessionDistinctNotes = 0
        local sessionSeenArrows = {}
        local sessionFirstNoteT = nil
        local sessionLastNoteT = nil
        local sumDeltaMs = 0
        local validDeltaCount = 0
        local timingOffsetSum = 0
        local timingOffsetCount = 0

        local tierCounts = {
            Normal = 0,
            Hard = 0,
            Insane = 0,
            Mania = 0,
            Lunatic = 0,
            Impossible = 0,
        }

        local attr = {
            runId = actorRunId,
            alive = LP:GetAttribute("GCCAlive"),
            ap = LP:GetAttribute("GCCAP"),
            dodge = LP:GetAttribute("GCCDodge") ~= false,
            mechanics = LP:GetAttribute("GCCMechanics") == true,
            mechanicInterval = tonumber(LP:GetAttribute("GCCMechanicInterval")) or 0.05,
            holdWindow = (tonumber(LP:GetAttribute("GCCHoldMs")) or 150) * 0.001,
            sideName = LP:GetAttribute("GCCSide") or "Left",
            sickPct = tonumber(LP:GetAttribute("GCCSickPct")) or 92,
            goodPct = tonumber(LP:GetAttribute("GCCGoodPct")) or 6,
            okPct = tonumber(LP:GetAttribute("GCCOkPct")) or 2,
            badPct = tonumber(LP:GetAttribute("GCCBadPct")) or 0,
            missPct = tonumber(LP:GetAttribute("GCCMissPct")) or 0,
            missCooldown = tonumber(LP:GetAttribute("GCCMissCooldown")) or 4.0,
            sickMaxOffset = (tonumber(LP:GetAttribute("GCCSickMaxOffset")) or 18) * 0.001,
            dynAcc = LP:GetAttribute("GCCDynAcc") ~= false,
            denseMs = tonumber(LP:GetAttribute("GCDenseMs")) or 45,
            sparseMs = tonumber(LP:GetAttribute("GCSparseMs")) or 240,
            comfortNps = tonumber(LP:GetAttribute("GCComfortNps")) or 7,
            hardNps = tonumber(LP:GetAttribute("GCHardNps")) or 14,
            penaltyPct = tonumber(LP:GetAttribute("GCPenaltyPct")) or 40,
            spamMinNps = tonumber(LP:GetAttribute("GCSpamMinNps")) or 9,
            strainDecay = tonumber(LP:GetAttribute("GCStrainDecay")) or 2.0,
            jackWeight = tonumber(LP:GetAttribute("GCJackWeight")) or 0.20,
            dmbod = LP:GetAttribute("GCCDmbod") == true,
            dmbodMaxMiss = tonumber(LP:GetAttribute("GCDmbodMaxMiss")) or 5,
            watcherActive = LP:GetAttribute("GCCWatcherActive") ~= false,
            sessionActive = LP:GetAttribute("GCC_W_SessionActive") == true,
            releaseDirty = false,
        }

        local function recalculateWeights()
            local s = math_max(0, attr.sickPct)
            local g = math_max(0, attr.goodPct)
            local o = math_max(0, attr.okPct)
            local b = math_max(0, attr.badPct)
            local m = math_max(0, attr.missPct)
            cumSick = s
            cumGood = cumSick + g
            cumOk = cumGood + o
            cumBad = cumOk + b
            totalWeight = cumBad + m
            if totalWeight <= 0 then
                totalWeight = 100
                cumSick = 100
                cumGood = 100
                cumOk = 100
                cumBad = 100
            end
        end
        recalculateWeights()

        local function resetSessionTelemetry()
            currentPeakNPS = 0
            lastComputedRollingNPS = 0
            currentSpam = false
            currentComfort = "COMFORTABLE"
            dasActivationCount = 0
            dmbodTriggerCount = 0
            totalActualMissCount = 0
            currentDynamicMissRate = 0
            accumulatedStrain = 0
            currentJackStrain = 0
            currentDiffIndex = 0
            timingOffsetSum = 0
            timingOffsetCount = 0

            sessionTotalNotes = 0
            sessionDistinctNotes = 0
            table.clear(sessionSeenArrows)
            sessionFirstNoteT = nil
            sessionLastNoteT = nil
            sumDeltaMs = 0
            validDeltaCount = 0

            tierCounts.Normal = 0
            tierCounts.Hard = 0
            tierCounts.Insane = 0
            tierCounts.Mania = 0
            tierCounts.Lunatic = 0
            tierCounts.Impossible = 0
        end

        local attrSignals = {}
        local function disconnectAttrSignals()
            for i = 1, #attrSignals do
                pcall(function() attrSignals[i]:Disconnect() end)
            end
            table.clear(attrSignals)
        end

        local function trackAttr(name, setter)
            attrSignals[#attrSignals + 1] = LP:GetAttributeChangedSignal(name):Connect(function()
                setter(LP:GetAttribute(name))
            end)
        end

        trackAttr("GCCReleaseAll", function() attr.releaseDirty = true end)
        trackAttr("GCCRunId", function(v) attr.runId = v end)
        trackAttr("GCCAlive", function(v) attr.alive = v end)
        trackAttr("GCCAP", function(v) attr.ap = v end)
        trackAttr("GCCDodge", function(v) attr.dodge = v ~= false end)
        trackAttr("GCCMechanics", function(v) attr.mechanics = v == true end)
        trackAttr("GCCMechanicInterval", function(v) attr.mechanicInterval = tonumber(v) or 0.05 end)
        trackAttr("GCCHoldMs", function(v) attr.holdWindow = (tonumber(v) or 150) * 0.001 end)
        trackAttr("GCCSide", function(v) attr.sideName = v or "Left" end)
        trackAttr("GCCSickPct", function(v) attr.sickPct = tonumber(v) or 92; recalculateWeights() end)
        trackAttr("GCCGoodPct", function(v) attr.goodPct = tonumber(v) or 6; recalculateWeights() end)
        trackAttr("GCCOkPct", function(v) attr.okPct = tonumber(v) or 2; recalculateWeights() end)
        trackAttr("GCCBadPct", function(v) attr.badPct = tonumber(v) or 0; recalculateWeights() end)
        trackAttr("GCCMissPct", function(v) attr.missPct = tonumber(v) or 0; recalculateWeights() end)
        trackAttr("GCCMissCooldown", function(v) attr.missCooldown = tonumber(v) or 4.0 end)
        trackAttr("GCCSickMaxOffset", function(v) attr.sickMaxOffset = (tonumber(v) or 18) * 0.001 end)
        trackAttr("GCCDynAcc", function(v) attr.dynAcc = v ~= false end)
        trackAttr("GCDenseMs", function(v) attr.denseMs = tonumber(v) or 45 end)
        trackAttr("GCSparseMs", function(v) attr.sparseMs = tonumber(v) or 240 end)
        trackAttr("GCComfortNps", function(v) attr.comfortNps = tonumber(v) or 7 end)
        trackAttr("GCHardNps", function(v) attr.hardNps = tonumber(v) or 14 end)
        trackAttr("GCPenaltyPct", function(v) attr.penaltyPct = tonumber(v) or 40 end)
        trackAttr("GCSpamMinNps", function(v) attr.spamMinNps = tonumber(v) or 9 end)
        trackAttr("GCStrainDecay", function(v) attr.strainDecay = tonumber(v) or 2.0 end)
        trackAttr("GCJackWeight", function(v) attr.jackWeight = tonumber(v) or 0.20 end)
        trackAttr("GCCDmbod", function(v) attr.dmbod = v == true end)
        trackAttr("GCDmbodMaxMiss", function(v) attr.dmbodMaxMiss = tonumber(v) or 5 end)
        trackAttr("GCCWatcherActive", function(v) attr.watcherActive = v ~= false end)
        trackAttr("GCC_W_SessionActive", function(v)
            attr.sessionActive = v == true
            if v == true then resetSessionTelemetry() end
        end)
        trackAttr("GCCWatcherReset", function() resetSessionTelemetry() end)

        local function getPlayerGui()
            local pg = cachedPlayerGui
            if pg and pg.Parent then return pg end
            pg = LP:FindFirstChild("PlayerGui")
            cachedPlayerGui = pg
            return pg
        end

        local function getPendulumPivot(nowS)
            local pivot = cachedPendulumPivot
            if pivot and pivot.Parent then return pivot end
            if nowS < nextPendulumRefresh then return nil end
            nextPendulumRefresh = nowS + 0.5

            local playerGui = getPlayerGui()
            local pendulumGui = playerGui and playerGui:FindFirstChild("LullabyPendulum")
            local pendulumRoot = pendulumGui and pendulumGui:FindFirstChild("LullabyPendulum")
            pivot = pendulumRoot and pendulumRoot:FindFirstChild("PendulumPivot")
            cachedPendulumPivot = pivot
            return pivot
        end

        local function search(nowS)
            if fwV then return end
            if type(filtergc) ~= "function" then return end
            if nowS and nowS < nextSearchAt then return end
            nextSearchAt = (nowS or 0) + 0.5

            local list = filtergc("table", { Keys = { "VSRG", "Songs" } })
            for _, obj in ipairs(list or {}) do
                local root = type(obj) == "table" and rawget(obj, "VSRG")
                if type(root) == "table" and type(rawget(root, "GameHandler")) == "table" then
                    fwV = obj
                    nextSearchAt = 0
                    pcall(function()
                        LP:SetAttribute("GCCFW", true)
                        LP:SetAttribute("GCCFWKind", "vsrg")
                    end)
                    return
                end
            end
        end
        search()

        local function isArrowLike(v)
            if type(v) ~= "table" then return false end
            return v.Time ~= nil or v.NoteData ~= nil or v.Data ~= nil
                or v.LaneIndex ~= nil or v.Lane ~= nil or v.Column ~= nil
                or v.Direction ~= nil
        end

        local function extractLane(a)
            if type(a) ~= "table" then return nil end
            local nd = a.NoteData
            if type(nd) == "table" then
                local p = tonumber(nd.Position) or tonumber(nd.Lane) or tonumber(nd.Column) or tonumber(nd.LaneIndex)
                if p then return p end
            end
            local d = a.Data
            if type(d) == "table" then
                local p = tonumber(d.Position) or tonumber(d.Lane) or tonumber(d.Column) or tonumber(d.LaneIndex)
                if p then return p end
            end
            local p = tonumber(a.LaneIndex) or tonumber(a.Lane) or tonumber(a.Column)
            if p then return p end
            return tonumber(a.Direction)
        end

        local function extractTime(a)
            if type(a) ~= "table" then return nil end
            local t = a.Time
            if type(t) ~= "number" and type(a.NoteData) == "table" then t = a.NoteData.Time end
            if type(t) ~= "number" and type(a.Data) == "table" then t = a.Data.Time end
            if type(t) ~= "number" then t = a._Time end
            return (type(t) == "number") and t or nil
        end

        local function extractLength(a)
            if type(a) ~= "table" then return nil end
            local t = a.Length
            if type(t) ~= "number" and type(a.NoteData) == "table" then t = a.NoteData.Length end
            if type(t) ~= "number" and type(a.Data) == "table" then t = a.Data.Length end
            return (type(t) == "number") and t or nil
        end

        local function laneFromValue(p, count)
            count = count or 4
            p = tonumber(p)
            if not p then return nil end
            if p >= 1 and p <= count then return p end
            if p >= 0 and p < count then return p + 1 end
            return (math_floor(p) % count) + 1
        end

        local function normDiff(noteTime, songTime)
            if type(noteTime) ~= "number" or type(songTime) ~= "number" then return nil end
            if noteTime > 1000 and songTime < 500 then noteTime = noteTime * 0.001 end
            if songTime > 1000 and noteTime < 500 then songTime = songTime * 0.001 end
            return noteTime - songTime
        end

        local function gaussianOffset(maxWindowSec)
            local effectiveCap = math_min(maxWindowSec, 0.040)
            local z = (math_random() + math_random() + math_random() - 1.5) * 1.4142
            return math_clamp(z * (effectiveCap * 0.33), -effectiveCap, effectiveCap)
        end

        -- FIXED: Symmetric hit detection that does not lock out early or late offsets
        local function shouldHit(arrow, diff, dt, targetOffset)
            local target = targetOffset or 0
            local step = dt or 0.016
            local hitWindow = math_max(0.024, step * 1.5)

            -- If note has crossed or is within the target threshold
            if diff <= target + (step * 0.5) then
                -- Allowed hit window: up to 90ms late past target before dropping
                if (target - diff) <= 0.090 then
                    return true
                end
            end
            return false
        end

        local function sideMatches(arrow, field, sideName)
            local af = arrow.Field
            if af == nil then return true end
            local fs = field and field.Side
            if af == fs then return true end

            if type(af) == "table" then
                if af == field then return true end
                local afSide = rawget(af, "Side")
                if type(afSide) == "string" then
                    local a = afSide:lower()
                    if a == "all" or a == "both" then return true end
                    if type(fs) == "string" then return a == fs:lower() end
                    return afSide:find(sideName or "Left", 1, true) ~= nil
                end
                return true
            end

            if type(af) == "string" then
                local a = af:lower()
                if a == "all" or a == "both" then return true end
                if type(fs) == "string" then return a == fs:lower() end
                return af:find(sideName or "Left", 1, true) ~= nil
            end
            return true
        end

        -- Telemetry Registration
        local function registerNoteTelemetry(arrow, nTime)
            if not attr.sessionActive or not attr.watcherActive then return end
            local noteKey = arrow.Index or (arrow.NoteData and arrow.NoteData.Index) or arrow
            if sessionSeenArrows[noteKey] then return end
            sessionSeenArrows[noteKey] = true

            sessionTotalNotes = sessionTotalNotes + 1
            if not sessionFirstNoteT or nTime < sessionFirstNoteT then sessionFirstNoteT = nTime end
            if not sessionLastNoteT or nTime > sessionLastNoteT then sessionLastNoteT = nTime end

            local isChordStep = (lastDistinctNoteTime > 0) and (math_abs(nTime - lastDistinctNoteTime) <= 0.015)
            if not isChordStep then
                sessionDistinctNotes = sessionDistinctNotes + 1
                if lastDistinctNoteTime > 0 then
                    local dtSec = nTime - lastDistinctNoteTime
                    if dtSec > 0.015 then
                        local dtMs = dtSec * 1000
                        sumDeltaMs = sumDeltaMs + dtMs
                        validDeltaCount = validDeltaCount + 1

                        local stepNps = 1000.0 / dtMs
                        if stepNps < 4 or dtMs > 250 then
                            tierCounts.Normal = tierCounts.Normal + 1
                        elseif stepNps <= 7 or dtMs > 142 then
                            tierCounts.Hard = tierCounts.Hard + 1
                        elseif stepNps <= 11 or dtMs > 90 then
                            tierCounts.Insane = tierCounts.Insane + 1
                        elseif stepNps <= 16 or dtMs > 62.5 then
                            tierCounts.Mania = tierCounts.Mania + 1
                        elseif stepNps <= 22 or dtMs > 45 then
                            tierCounts.Lunatic = tierCounts.Lunatic + 1
                        else
                            tierCounts.Impossible = tierCounts.Impossible + 1
                        end
                    end
                end
            end
        end

        local function pressLane(lane, down)
            if lane == nil then return end
            local field = activeField or (fwV and fwV.VSRG and fwV.VSRG.GameHandler and fwV.VSRG.GameHandler.Field)
            if field and type(field.HitLane) == "function" then
                pcall(field.HitLane, field, lane, down, nil)
            end
        end

        local heldLanes = { false, false, false, false, false, false, false, false, false, false }
        local releaseAt = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }

        local function releaseHeld()
            for lane = 1, 10 do
                if heldLanes[lane] then
                    pressLane(lane, false)
                    heldLanes[lane] = false
                end
                releaseAt[lane] = 0
            end
        end

        local function flushReleases(nowS)
            for lane = 1, 10 do
                local rTime = releaseAt[lane]
                if rTime > 0 and nowS >= rTime then
                    pressLane(lane, false)
                    heldLanes[lane] = false
                    releaseAt[lane] = 0
                end
            end
        end

        local function hitLane(lane, length, holdWindow, nowS)
            if lane == nil or lane > 10 then return end
            if heldLanes[lane] then
                pressLane(lane, false)
            end
            pressLane(lane, true)
            heldLanes[lane] = true
            releaseAt[lane] = nowS + math_max(0.035, (length and length > 0.04) and length or holdWindow)
        end

        -- STATIC REUSABLE HIT QUEUE
        local MAX_POOL = 32
        local hitPool = table.create(MAX_POOL)
        for i = 1, MAX_POOL do
            hitPool[i] = { arrow = nil, lane = 1, length = 0, time = 0 }
        end
        local hitPoolCount = 0

        local deathTypes = { Death = true, Poison = true }

        local function processSingleArrow(arrow, laneHint, timepos, playback, dt, nowS, sideName, dodge, holdWindow)
            if not arrow or arrow._bybyHit then return end

            if not sideBroken and not sideMatches(arrow, activeField, sideName) then
                return
            end

            if dodge and type(arrow.NoteData) == "table" and arrow.NoteData.Type and deathTypes[arrow.NoteData.Type] then
                return
            end

            local rawLane = laneHint or extractLane(arrow)
            if not rawLane then return end
            if rawLane == 0 then zeroBased = true end
            if rawLane > maxLane then maxLane = rawLane end

            local rawTime = extractTime(arrow)
            if not rawTime then return end
            local nTime = (rawTime > 1000 and timepos < 500) and (rawTime * 0.001) or rawTime

            local diff = normDiff(nTime, timepos)
            if not diff then return end
            diff = diff / playback

            -- Out of range optimizations: ignore notes far in future or ancient
            if diff > 1.2 then return end
            if diff < -0.25 then
                arrow._bybyHit = true
                if not arrow._bybyHitSuccessfully and not arrow._bybyMiss then
                    totalActualMissCount = totalActualMissCount + 1
                end
                return
            end

            registerNoteTelemetry(arrow, nTime)

            -- ACCURACY & DAS EVALUATION (Computed once when within 180ms)
            if arrow._bybyTargetOffset == nil and not arrow._bybyMiss and diff <= 0.18 then
                local targetLaneIdx = laneFromValue(rawLane, 10)
                local lastLaneT = (targetLaneIdx and lastLaneNoteTime[targetLaneIdx]) or 0
                local dtLane = (lastLaneT > 0) and (nTime - lastLaneT) or 1.0

                local isChord = (lastDistinctNoteTime > 0) and (math_abs(nTime - lastDistinctNoteTime) <= 0.015)

                if not isChord then
                    npsRing[ringHead] = nTime
                    ringHead = (ringHead % RING_SIZE) + 1
                    if ringCount < RING_SIZE then ringCount = ringCount + 1 end
                end

                local activeCount = 0
                for r = 1, ringCount do
                    local dw = nTime - npsRing[r]
                    if dw >= 0 and dw <= NPS_WINDOW then
                        activeCount = activeCount + 1
                    end
                end
                local rollingNPS = activeCount / NPS_WINDOW
                lastComputedRollingNPS = rollingNPS

                local dtInter = (lastDistinctNoteTime > 0) and math_max(0.015, nTime - lastDistinctNoteTime) or 0.20
                local burstNPS = math_clamp(1.0 / dtInter, 0.0, 35.0)
                local effectiveNPS = math_max(rollingNPS, (rollingNPS * 0.5) + (burstNPS * 0.5))

                if effectiveNPS > currentPeakNPS then currentPeakNPS = effectiveNPS end
                currentSpam = ((dtInter * 1000) < attr.denseMs) and (rollingNPS >= attr.spamMinNps)

                if lastStrainUpdateTime > 0 then
                    local dtIdle = math_max(0, nTime - lastStrainUpdateTime)
                    if dtIdle > 0 then
                        accumulatedStrain = accumulatedStrain * math_exp(-attr.strainDecay * dtIdle)
                    end
                end
                lastStrainUpdateTime = nTime

                local comfortNps = attr.comfortNps
                local hardNps = math_max(comfortNps + 2, attr.hardNps)

                if effectiveNPS > comfortNps and not isChord then
                    local densityOverhead = (effectiveNPS - comfortNps) / (hardNps - comfortNps)
                    accumulatedStrain = math_clamp(accumulatedStrain + (densityOverhead * 0.12), 0.0, 1.0)
                end

                if accumulatedStrain >= 0.85 then
                    currentComfort = "OVERLOAD"
                elseif effectiveNPS > comfortNps then
                    currentComfort = "STRAINED"
                else
                    currentComfort = "COMFORTABLE"
                end

                local jackStrain = 0.0
                if lastLaneT > 0 and dtLane < 0.22 and dtLane > 0.012 then
                    jackStrain = math_clamp(1.0 - (dtLane / 0.22), 0.0, 1.0)
                end
                currentJackStrain = jackStrain

                local baseDiffFactor = math_clamp((effectiveNPS - comfortNps) / (hardNps - comfortNps), 0.0, 1.0)
                local diffIndex = math_clamp(
                    (baseDiffFactor * 0.45) + (accumulatedStrain * 0.35) + (jackStrain * attr.jackWeight),
                    0.0, 1.0
                )
                currentDiffIndex = diffIndex

                lastGlobalNoteTime = nTime
                if not isChord then lastDistinctNoteTime = nTime end
                if targetLaneIdx and targetLaneIdx >= 1 and targetLaneIdx <= 10 then
                    lastLaneNoteTime[targetLaneIdx] = nTime
                end

                local currentMissPct = 0
                if attr.dmbod then
                    local lowDiffBaseline = math_min(0.4, attr.dmbodMaxMiss * 0.08)
                    currentMissPct = lowDiffBaseline + ((attr.dmbodMaxMiss - lowDiffBaseline) * (diffIndex ^ 1.25))
                    currentMissPct = math_clamp(currentMissPct, 0.0, attr.dmbodMaxMiss)
                else
                    currentMissPct = attr.missPct
                end
                currentDynamicMissRate = currentMissPct

                local curSick = attr.sickPct
                local curGood = attr.goodPct
                local curOk = attr.okPct
                local curBad = attr.badPct

                if attr.dynAcc and diffIndex > 0.05 then
                    local shaved = curSick * (diffIndex * (attr.penaltyPct * 0.01))
                    if shaved > 1 then dasActivationCount = dasActivationCount + 1 end
                    curSick = math_max(5, curSick - shaved)
                    curGood = curGood + (shaved * 0.50)
                    curOk = curOk + (shaved * 0.35)
                    curBad = curBad + (shaved * 0.15)
                end

                local cSick = curSick
                local cGood = cSick + curGood
                local cOk = cGood + curOk
                local cBad = cOk + curBad
                local cTotal = cBad

                local canMiss = (nowS >= nextMissAllowedAt) and (currentMissPct > 0)
                if canMiss then
                    cTotal = cBad + currentMissPct
                end
                if cTotal <= 0 then cTotal = 100 end

                local roll = math_random() * cTotal
                if roll < cSick then
                    arrow._bybyTargetOffset = gaussianOffset(attr.sickMaxOffset)
                elseif roll < cGood then
                    local ms = math_random(18, 45)
                    local sign = (math_random() < 0.5) and -1 or 1
                    arrow._bybyTargetOffset = (sign * ms) * 0.001
                elseif roll < cOk then
                    local ms = math_random(46, 75)
                    local sign = (math_random() < 0.5) and -1 or 1
                    arrow._bybyTargetOffset = (sign * ms) * 0.001
                elseif roll < cBad then
                    local ms = math_random(76, 110)
                    local sign = (math_random() < 0.5) and -1 or 1
                    arrow._bybyTargetOffset = (sign * ms) * 0.001
                else
                    arrow._bybyMiss = true
                    dmbodTriggerCount = dmbodTriggerCount + 1
                    totalActualMissCount = totalActualMissCount + 1
                    nextMissAllowedAt = nowS + attr.missCooldown
                end

                if arrow._bybyTargetOffset then
                    timingOffsetSum = timingOffsetSum + math_abs(arrow._bybyTargetOffset * 1000)
                    timingOffsetCount = timingOffsetCount + 1
                end
            end

            if arrow._bybyMiss then
                if diff < -0.20 then arrow._bybyHit = true end
                return
            end

            if shouldHit(arrow, diff, dt, arrow._bybyTargetOffset) then
                arrow._bybyHitSuccessfully = true
                if hitPoolCount < MAX_POOL then
                    hitPoolCount = hitPoolCount + 1
                    local item = hitPool[hitPoolCount]
                    item.arrow = arrow
                    item.lane = rawLane
                    item.length = (extractLength(arrow) or 0.03) / playback
                    item.time = nTime
                end
            end
        end

        local signal = RS.PreRender or RS.RenderStepped
        local connection
        connection = signal:Connect(function(dt)
            if attr.releaseDirty then
                attr.releaseDirty = false
                releaseHeld()
            end
            if attr.runId ~= actorRunId then
                releaseHeld()
                disconnectAttrSignals()
                connection:Disconnect()
                return
            end
            if attr.alive == false then
                releaseHeld()
                return
            end

            local nowS = clockS()
            if not fwV then
                search(nowS)
                if not fwV then return end
            end

            flushReleases(nowS)

            -- AUTO MECHANICS
            if attr.mechanics and attr.ap then
                local mechanics = fwV.VSRG and fwV.VSRG.Mechanics
                local actionController = mechanics and mechanics.Action
                local activeAction = actionController and actionController.ActiveAction

                if activeAction and activeAction.Enabled then
                    if activeAction ~= lastMechanicAction then
                        lastMechanicAction = activeAction
                        nextMechanicDispatchTime = 0
                        mechanicCentered = false
                    end

                    local dispatchedByPendulum = false
                    if tostring(activeAction.Label):upper() == "RESIST" then
                        local pivot = getPendulumPivot(nowS)
                        if pivot and pivot:IsA("GuiObject") and pivot.Visible then
                            dispatchedByPendulum = true
                            local centerThreshold = 3.0 + ((math_random() * 2 - 1) * 0.8)
                            local centered = math_abs(pivot.Rotation) <= centerThreshold
                            if centered and not mechanicCentered then
                                mechanicCentered = true
                                if type(actionController.Dispatch) == "function" then
                                    pcall(actionController.Dispatch, actionController, activeAction)
                                elseif type(activeAction.Callback) == "function" then
                                    pcall(activeAction.Callback)
                                end
                            elseif math_abs(pivot.Rotation) >= 8 then
                                mechanicCentered = false
                            end
                        end
                    end

                    if not dispatchedByPendulum and (nowS >= nextMechanicDispatchTime) then
                        local jitterDelta = (math_random() * 2 - 1) * (attr.mechanicInterval * 0.25)
                        nextMechanicDispatchTime = nowS + math_max(0.015, attr.mechanicInterval + jitterDelta)

                        if type(actionController.Dispatch) == "function" then
                            pcall(actionController.Dispatch, actionController, activeAction)
                        elseif type(activeAction.Callback) == "function" then
                            pcall(activeAction.Callback)
                        end
                    end
                else
                    lastMechanicAction = nil
                    nextMechanicDispatchTime = 0
                    mechanicCentered = false
                end
            end

            -- NOTE ENGINE
            local field = fwV.VSRG and fwV.VSRG.GameHandler and fwV.VSRG.GameHandler.Field
            local gameObj = field and field.Game

            if gameObj and type(field.NoteCache) == "table" then
                activeField = field
                if type(field.HitLane) == "function" and not hitLaneSeen then
                    hitLaneSeen = true
                    pcall(function() LP:SetAttribute("GCCHitLane", true) end)
                end

                local timepos = gameObj.TimePosition
                local playback = gameObj.AdjustedPlayback or 1
                if playback == 0 then playback = 1 end

                if lastField ~= field or lastGame ~= gameObj or (tpV and (timepos < tpV - 1.0 or timepos > tpV + 5.0)) then
                    lastField, lastGame, lastNoteCache = field, gameObj, field.NoteCache
                    laneCount, maxLane, zeroBased = 4, 0, false
                    nextCountCheck = 0
                    sideBroken, sideBrokenSince = false, nil
                    lastGlobalNoteTime = 0
                    lastDistinctNoteTime = 0
                    for l = 1, 10 do lastLaneNoteTime[l] = 0 end
                    for r = 1, RING_SIZE do npsRing[r] = 0 end
                    ringHead, ringCount = 1, 0
                    accumulatedStrain = 0
                    lastStrainUpdateTime = 0
                elseif lastNoteCache ~= field.NoteCache then
                    lastNoteCache = field.NoteCache
                end

                if timepos ~= tpV then tpV, tpVAt = timepos, nowS end

                hitPoolCount = 0

                -- FAST ITERATION: Direct traversal without closure generation
                local nc = field.NoteCache
                for k, v in next, nc do
                    if type(v) == "table" then
                        if isArrowLike(v) then
                            processSingleArrow(v, nil, timepos, playback, dt, nowS, attr.sideName, attr.dodge, attr.holdWindow)
                        else
                            local laneHint = tonumber(k)
                            for _, v2 in next, v do
                                if type(v2) == "table" and isArrowLike(v2) then
                                    processSingleArrow(v2, laneHint, timepos, playback, dt, nowS, attr.sideName, attr.dodge, attr.holdWindow)
                                end
                            end
                        end
                    end
                end

                if (nowS - tpVAt) < 3 then
                    lastV = nowS
                end

                if nowS >= nextCountCheck then
                    nextCountCheck = nowS + 10
                    pcall(function()
                        local gh = fwV.VSRG.GameHandler
                        local list = {
                            field.KeyCount, field.Keys, field.LaneCount,
                            gh and gh.KeyCount, gh and gh.Keys, gh and gh.LaneCount,
                        }
                        for _, v in ipairs(list) do
                            local n = tonumber(v)
                            if n and n >= 3 and n <= 9 then
                                laneCount = math_floor(n)
                                break
                            end
                        end
                    end)
                end

                if maxLane > 0 then
                    local observed = zeroBased and (maxLane + 1) or maxLane
                    if observed > laneCount and observed <= 9 then laneCount = observed end
                end

                -- PROCESS DISPATCH POOL
                if attr.ap and lastV and (nowS - lastV) <= 2 and hitPoolCount > 0 then
                    for i = 1, hitPoolCount do
                        local item = hitPool[i]
                        local laneIdx = laneFromValue(item.lane, laneCount)
                        hitLane(laneIdx, item.length, attr.holdWindow, nowS)
                        item.arrow._bybyHit = true
                    end
                end

                -- TELEMETRY DISPATCH (10 Hz)
                if attr.watcherActive and nowS >= nextTelemetrySyncAt then
                    nextTelemetrySyncAt = nowS + 0.10

                    local duration = 0
                    local meanNps = 0
                    local meanDelta = 0

                    if sessionFirstNoteT and sessionLastNoteT and sessionLastNoteT > sessionFirstNoteT then
                        duration = sessionLastNoteT - sessionFirstNoteT
                        if duration > 0 then
                            meanNps = sessionTotalNotes / duration
                        end
                    end

                    if validDeltaCount > 0 then
                        meanDelta = sumDeltaMs / validDeltaCount
                    end

                    local primaryTier = "NORMAL"
                    local pNormal, pHard, pInsane, pMania, pLunatic, pImpossible = 100, 0, 0, 0, 0, 0

                    if validDeltaCount > 0 then
                        pNormal = (tierCounts.Normal / validDeltaCount) * 100
                        pHard = (tierCounts.Hard / validDeltaCount) * 100
                        pInsane = (tierCounts.Insane / validDeltaCount) * 100
                        pMania = (tierCounts.Mania / validDeltaCount) * 100
                        pLunatic = (tierCounts.Lunatic / validDeltaCount) * 100
                        pImpossible = (tierCounts.Impossible / validDeltaCount) * 100

                        local maxP = pNormal
                        if pHard > maxP then maxP = pHard; primaryTier = "HARD" end
                        if pInsane > maxP then maxP = pInsane; primaryTier = "INSANE" end
                        if pMania > maxP then maxP = pMania; primaryTier = "MANIA" end
                        if pLunatic > maxP then maxP = pLunatic; primaryTier = "LUNATIC" end
                        if pImpossible > maxP then maxP = pImpossible; primaryTier = "IMPOSSIBLE" end
                    end

                    local avgOffsetMs = (timingOffsetCount > 0) and (timingOffsetSum / timingOffsetCount) or 0

                    pcall(function()
                        LP:SetAttribute("GCC_W_TotalNotes", sessionTotalNotes)
                        LP:SetAttribute("GCC_W_DistinctNotes", sessionDistinctNotes)
                        LP:SetAttribute("GCC_W_Duration", duration)
                        LP:SetAttribute("GCC_W_MeanNPS", meanNps)
                        LP:SetAttribute("GCC_W_MeanDeltaMs", meanDelta)
                        LP:SetAttribute("GCC_W_PrimaryTier", primaryTier)
                        LP:SetAttribute("GCC_W_PctNormal", pNormal)
                        LP:SetAttribute("GCC_W_PctHard", pHard)
                        LP:SetAttribute("GCC_W_PctInsane", pInsane)
                        LP:SetAttribute("GCC_W_PctMania", pMania)
                        LP:SetAttribute("GCC_W_PctLunatic", pLunatic)
                        LP:SetAttribute("GCC_W_PctImpossible", pImpossible)

                        LP:SetAttribute("GCC_W_RollingNPS", lastComputedRollingNPS)
                        LP:SetAttribute("GCC_W_PeakNPS", currentPeakNPS)
                        LP:SetAttribute("GCC_W_Spam", currentSpam)
                        LP:SetAttribute("GCC_W_Comfort", currentComfort)
                        LP:SetAttribute("GCC_W_DasCount", dasActivationCount)
                        LP:SetAttribute("GCC_W_DmbodCount", dmbodTriggerCount)
                        LP:SetAttribute("GCC_W_TotalMissCount", totalActualMissCount)
                        LP:SetAttribute("GCC_W_MissRate", math_floor(currentDynamicMissRate + 0.5))
                        LP:SetAttribute("GCC_W_StrainPct", math_floor((accumulatedStrain * 100) + 0.5))
                        LP:SetAttribute("GCC_W_JackStrainPct", math_floor((currentJackStrain * 100) + 0.5))
                        LP:SetAttribute("GCC_W_DiffIndex", currentDiffIndex)
                        LP:SetAttribute("GCC_W_AvgOffsetMs", avgOffsetMs)
                    end)
                end
            else
                activeField = nil
            end
        end)
    ]=])

    return true
end

-- ------------------------------------------------------------ MAIN PROCESS MONITOR

local Main = { stepErrors = 0 }

function Main.step()
    local now = os.clock()
    local gameUI, fields = GameUI.get(now)
    local inGame = (gameUI and gameUI.Visible and fields and fields.Visible) == true

    if inGame and not State.inMatch then
        State.inMatch = true
        Side.update()
        syncFlags()
        if not State.actorInjected then
            pcall(injectActor)
        end
    elseif not inGame and State.inMatch then
        State.inMatch = false
        releaseAll()
    end
end

function Main.start()
    local nextStepAt = 0

    track(runService.Heartbeat:Connect(function()
        local now = os.clock()
        if now < nextStepAt then return end
        nextStepAt = now + 0.15

        local ok = pcall(Main.step)
        if ok then
            Main.stepErrors = 0
        else
            Main.stepErrors = Main.stepErrors + 1
            if Main.stepErrors >= 30 then
                Main.stepErrors = 0
                pcall(function()
                    localPlayer:SetAttribute("GCCAP", false)
                    localPlayer:SetAttribute("GCCAlive", false)
                end)
                releaseAll()
            end
        end
    end))

    task.spawn(function()
        while isAlive() do
            task.wait(2.0)
            if State.inMatch then Side.update() end
        end
    end)

    task.spawn(function()
        for _ = 1, 20 do
            if not isAlive() then return end
            if State.actorInjected then return end
            pcall(injectActor)
            task.wait(1.0)
        end
    end)
end

-- ------------------------------------------------------------ UI CONSTRUCTION

local uiElements = {}

-- AUTOPLAY
mainTab:CreateSection({ name = "AUTOPLAY", icon = "eye" })

uiElements.autoplay = mainTab:CreateToggle({
    name = "Enable Autoplay",
    flag = "Yvetzal_FF_Enabled",
    value = State.autoplay,
    callback = function(v)
        State.autoplay = v
        syncFlags()
        if not v then releaseAll() end
    end,
})

uiElements.dodge = mainTab:CreateToggle({
    name = "Dodge Death / Poison",
    flag = "Yvetzal_FF_Dodge",
    value = State.dodge,
    callback = function(v)
        State.dodge = v
        syncFlags()
    end,
})

uiElements.mechanics = mainTab:CreateToggle({
    name = "Auto Mechanics (RESIST)",
    flag = "Yvetzal_FF_Mechanics",
    value = State.mechanics,
    callback = function(v)
        State.mechanics = v
        syncFlags()
    end,
})

uiElements.sideMode = mainTab:CreateDropdown({
    name = "Side",
    flag = "Yvetzal_FF_Side",
    options = { "Auto", "Left", "Right" },
    value = State.sideMode,
    callback = function(v)
        State.sideMode = v
        Side.update()
        syncFlags()
    end,
})

-- DYNAMICS
mainTab:CreateSection({ name = "DYNAMIC ACCURACY & DMBOD", icon = "crosshair" })

uiElements.dynamicAccuracy = mainTab:CreateToggle({
    name = "Dynamic Accuracy Scaling (DAS)",
    flag = "Yvetzal_FF_DynAcc",
    value = State.dynamicAccuracy,
    callback = function(v)
        State.dynamicAccuracy = v
        syncFlags()
    end,
})

uiElements.dmbod = mainTab:CreateToggle({
    name = "Dynamic Missing (DMBOD)",
    flag = "Yvetzal_FF_Dmbod",
    value = State.dmbod,
    callback = function(v)
        State.dmbod = v
        syncFlags()
    end,
})

uiElements.comfortNps = mainTab:CreateSlider({
    name = "Comfort NPS Threshold",
    flag = "Yvetzal_FF_ComfortNps",
    range = { 2, 20 },
    value = State.comfortNps,
    increment = 1,
    suffix = " NPS",
    callback = function(v)
        State.comfortNps = v
        syncFlags()
    end,
})

uiElements.hardNps = mainTab:CreateSlider({
    name = "Hard NPS Threshold",
    flag = "Yvetzal_FF_HardNps",
    range = { 8, 35 },
    value = State.hardNps,
    increment = 1,
    suffix = " NPS",
    callback = function(v)
        State.hardNps = v
        syncFlags()
    end,
})

uiElements.dmbodMaxMissPct = mainTab:CreateSlider({
    name = "DMBOD Max Miss Chance",
    flag = "Yvetzal_FF_DmbodMaxMiss",
    range = { 1, 25 },
    value = State.dmbodMaxMissPct,
    increment = 1,
    suffix = " %",
    callback = function(v)
        State.dmbodMaxMissPct = v
        syncFlags()
    end,
})

-- BASE ACCURACY
mainTab:CreateSection({ name = "BASE ACCURACY & TIMING", icon = "palette" })

uiElements.sickMaxOffsetMs = mainTab:CreateSlider({
    name = "Sick Max Spread (±ms)",
    flag = "Yvetzal_FF_SickMaxSpread",
    range = { 5, 30 },
    value = State.sickMaxOffsetMs,
    increment = 1,
    suffix = " ms",
    callback = function(v)
        State.sickMaxOffsetMs = v
        syncFlags()
    end,
})

uiElements.sickPct = mainTab:CreateSlider({
    name = "Sick Base Chance",
    flag = "Yvetzal_FF_SickPct",
    range = { 0, 100 },
    value = State.sickPct,
    increment = 1,
    suffix = " %",
    callback = function(v)
        State.sickPct = v
        syncFlags()
    end,
})

uiElements.goodPct = mainTab:CreateSlider({
    name = "Good Base Chance",
    flag = "Yvetzal_FF_GoodPct",
    range = { 0, 100 },
    value = State.goodPct,
    increment = 1,
    suffix = " %",
    callback = function(v)
        State.goodPct = v
        syncFlags()
    end,
})

uiElements.okPct = mainTab:CreateSlider({
    name = "Ok Base Chance",
    flag = "Yvetzal_FF_OkPct",
    range = { 0, 100 },
    value = State.okPct,
    increment = 1,
    suffix = " %",
    callback = function(v)
        State.okPct = v
        syncFlags()
    end,
})

uiElements.missPct = mainTab:CreateSlider({
    name = "Static Miss Chance",
    flag = "Yvetzal_FF_MissPct",
    range = { 0, 100 },
    value = State.missPct,
    increment = 1,
    suffix = " %",
    callback = function(v)
        State.missPct = v
        syncFlags()
    end,
})

uiElements.holdTime = mainTab:CreateSlider({
    name = "Hold Window",
    flag = "Yvetzal_FF_HoldMs",
    range = { 30, 300 },
    value = math.floor(State.holdTime * 1000),
    increment = 5,
    suffix = " ms",
    callback = function(v)
        State.holdTime = v * 0.001
        syncFlags()
    end,
})

-- WATCHER TAB
watcherTab:CreateSection({ name = "WATCHER TELEMETRY", icon = "eye" })

local watcherLabels = {}

uiElements.watcherToggle = watcherTab:CreateToggle({
    name = "Enable Watcher Monitoring",
    flag = "Yvetzal_FF_WatcherEnabled",
    value = State.watcherEnabled,
    callback = function(v)
        State.watcherEnabled = v
        syncFlags()
    end,
})

watcherTab:CreateButton({
    name = "Toggle Telemetry Recording",
    callback = function()
        State.sessionActive = not State.sessionActive
        if State.sessionActive then
            State.sessionStartTime = os.clock()
            localPlayer:SetAttribute("GCC_W_SessionActive", true)
        else
            localPlayer:SetAttribute("GCC_W_SessionActive", false)
        end
        syncFlags()
    end,
})

watcherTab:CreateButton({
    name = "Clear Telemetry Data",
    callback = function()
        State.sessionActive = false
        State.sessionStartTime = 0
        syncFlags()
        pcall(function()
            localPlayer:SetAttribute("GCC_W_SessionActive", false)
            localPlayer:SetAttribute("GCCWatcherReset", os.clock())
        end)
    end,
})

watcherLabels.sessionStatus = createTextItem(watcherTab, "Session Status", "Standby")
watcherLabels.chartOverview = createTextItem(watcherTab, "Chart Overview", "No data")
watcherLabels.difficultyBreakdown = createTextItem(watcherTab, "Difficulty Profile", "No data")
watcherLabels.diagnostics = createTextItem(watcherTab, "Real-Time Engine Diagnostics", "Idle")

-- Telemetry Render Loop (200ms throttle to prevent UI thread lag)
task.spawn(function()
    while isAlive() do
        task.wait(0.20)
        if State.watcherEnabled then
            pcall(function()
                local totalNotes = tonumber(localPlayer:GetAttribute("GCC_W_TotalNotes")) or 0
                local distinctNotes = tonumber(localPlayer:GetAttribute("GCC_W_DistinctNotes")) or 0
                local duration = tonumber(localPlayer:GetAttribute("GCC_W_Duration")) or 0
                local meanNps = tonumber(localPlayer:GetAttribute("GCC_W_MeanNPS")) or 0
                local meanDelta = tonumber(localPlayer:GetAttribute("GCC_W_MeanDeltaMs")) or 0
                local rollingNps = tonumber(localPlayer:GetAttribute("GCC_W_RollingNPS")) or 0
                local peakNps = tonumber(localPlayer:GetAttribute("GCC_W_PeakNPS")) or 0
                local primaryTier = localPlayer:GetAttribute("GCC_W_PrimaryTier") or "NORMAL"

                local isSpam = localPlayer:GetAttribute("GCC_W_Spam") == true
                local comfort = localPlayer:GetAttribute("GCC_W_Comfort") or "COMFORTABLE"
                local dasCount = tonumber(localPlayer:GetAttribute("GCC_W_DasCount")) or 0
                local dmbodCount = tonumber(localPlayer:GetAttribute("GCC_W_DmbodCount")) or 0
                local totalMisses = tonumber(localPlayer:GetAttribute("GCC_W_TotalMissCount")) or 0
                local missRate = math.floor((tonumber(localPlayer:GetAttribute("GCC_W_MissRate")) or 0) + 0.5)

                local strainPct = tonumber(localPlayer:GetAttribute("GCC_W_StrainPct")) or 0
                local jackStrainPct = tonumber(localPlayer:GetAttribute("GCC_W_JackStrainPct")) or 0
                local diffIndex = tonumber(localPlayer:GetAttribute("GCC_W_DiffIndex")) or 0
                local avgOffsetMs = tonumber(localPlayer:GetAttribute("GCC_W_AvgOffsetMs")) or 0

                if watcherLabels.sessionStatus then
                    local elapsed = (State.sessionActive and State.sessionStartTime > 0)
                        and (os.clock() - State.sessionStartTime)
                        or duration
                    watcherLabels.sessionStatus:Set({
                        Title = "Session Timer & Status",
                        Content = string.format("Status: %s\nElapsed: %.1f s\nTotal Notes: %d (Steps: %d)",
                            State.sessionActive and "RECORDING" or "IDLE", elapsed, totalNotes, distinctNotes
                        ),
                    })
                end

                if watcherLabels.chartOverview then
                    watcherLabels.chartOverview:Set({
                        Title = "Chart Overview",
                        Content = string.format("Duration: %.1f s\nMean NPS: %.2f\nMean Gap: %.1f ms\nPeak NPS: %.2f\nRolling NPS: %.2f",
                            duration, meanNps, meanDelta, peakNps, rollingNps
                        ),
                    })
                end

                if watcherLabels.difficultyBreakdown then
                    watcherLabels.difficultyBreakdown:Set({
                        Title = "Difficulty Profile",
                        Content = string.format("Primary Tier: %s", primaryTier),
                    })
                end

                if watcherLabels.diagnostics then
                    watcherLabels.diagnostics:Set({
                        Title = "Real-Time Engine Diagnostics",
                        Content = string.format(
                            "NPS: %.1f | Comfort: %s | Strain: %d%%\nJack Strain: %d%% | Diff Index: %.2f\nMiss Rate: %d%% | Offset: ±%.1f ms\nDAS Hits: %d | DMBOD: %d | Total Misses: %d",
                            rollingNps, tostring(comfort), strainPct,
                            jackStrainPct, diffIndex, missRate, avgOffsetMs,
                            dasCount, dmbodCount, totalMisses
                        ),
                    })
                end
            end)
        end
    end
end)

-- SETTINGS
settingsTab:CreateSection({ name = "CONFIG", icon = "settings" })

settingsTab:CreateButton({
    name = "Save Configuration",
    callback = function()
        saveConfig()
        window:Notify({ title = "Config", content = "Saved successfully", duration = 2 })
    end,
})

settingsTab:CreateButton({
    name = "Re-inject Actor",
    callback = function()
        State.actorInjected = false
        pcall(function() localPlayer:SetAttribute("GCCFW", false) end)
        pcall(injectActor)
    end,
})

settingsTab:CreateButton({
    name = "Unload Script",
    callback = function()
        if state.stop then state.stop() end
    end,
})

-- ------------------------------------------------------------ TEARDOWN

shared.YvetzalFunkyFriday = state

local function cleanup()
    if not state.alive then return end
    state.alive = false

    saveConfig()
    shared.YvetzalFunkyFridayToken = nil
    releaseAll()

    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)

    pcall(function()
        localPlayer:SetAttribute("GCCAP", false)
        localPlayer:SetAttribute("GCCMechanics", false)
        localPlayer:SetAttribute("GCCAlive", false)
        localPlayer:SetAttribute("GCCFW", false)
    end)

    if shared.YvetzalFunkyFriday == state then
        shared.YvetzalFunkyFriday = nil
    end
    shared.YvetzalFunkyFridayCleanup = nil
end

shared.YvetzalFunkyFridayCleanup = cleanup
state.stop = cleanup

local originalUnload = window.Unload
window.Unload = function(self)
    cleanup()
    if type(originalUnload) == "function" then
        return originalUnload(self)
    end
end

Main.start()
syncFlags()

window:Notify({
    title = "Yvetzal",
    content = "Zero-Allocation High-Performance Engine Loaded",
    icon = iconAsset("flame"),
    duration = 3,
})
