-- Yvetzal: Funky Friday Autoplay (Optimized DAS v4 & Adaptive DMBOD + Watcher Telemetry Engine)

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
    -- Human Pro Defaults
    sickPct = 92,
    goodPct = 6,
    okPct = 2,
    badPct = 0,
    missPct = 0,
    missCooldown = 4.0,
    sickMaxOffsetMs = 18,
    -- Dynamic Accuracy Scaling (DAS v4)
    dynamicAccuracy = true,
    denseThresholdMs = 45,
    sparseThresholdMs = 240,
    comfortNps = 7,
    hardNps = 14,
    strainPenaltyPct = 40,
    -- Dynamic Missing Based on Difficulty (DMBOD v4)
    dmbod = true,
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
local ok, err = pcall(function()
    rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
end)
if not ok or not rayfield then
    warn("[Yvetzal] Rayfield Gen2 failed to load:", err)
    return
end

local window = rayfield:CreateWindow({
    name = "Yvetzal",
    subtitle = "FUNKY FRIDAY AUTOPLAY & WATCHER",
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

-- ------------------------------------------------------------ UNIVERSAL TEXT/LABEL ADAPTER

local function createTextItem(targetTab, title, initialText)
    local item = nil
    local combinedText = (title and (title .. "\n") or "") .. (initialText or "")

    -- 1. Try CreateParagraph (legacy Rayfield)
    if type(targetTab.CreateParagraph) == "function" then
        local ok, res = pcall(function()
            return targetTab:CreateParagraph({ Title = title or "Info", Content = initialText or "--" })
        end)
        if ok and res then item = res end
    end

    -- 2. Try CreateLabel (works across both Gen1 and Gen2)
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

    -- 3. Try CreateText (Gen2 specialized text element)
    if not item and type(targetTab.CreateText) == "function" then
        local ok, res = pcall(function()
            return targetTab:CreateText({ name = title or "Info", text = initialText or "--" })
        end)
        if not ok or not res then
            ok, res = pcall(function()
                return targetTab:CreateText(combinedText)
            end)
        end
        if ok and res then item = res end
    end

    -- 4. Fallback: CreateButton as visual read-only card
    if not item and type(targetTab.CreateButton) == "function" then
        local ok, res = pcall(function()
            return targetTab:CreateButton({
                name = (title or "Card") .. ": " .. (initialText or "--"),
                callback = function() end,
            })
        end)
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
                self.raw:Set({ Title = self.title, Content = self.content, title = self.title, content = self.content })
            end)
            pcall(function()
                self.raw:Set(fullText)
            end)
        elseif type(self.raw.set) == "function" then
            pcall(function()
                self.raw:set(fullText)
            end)
        end
    end

    return handle
end

-- ------------------------------------------------------------ RUN STATE & TOKENS

local Tune = {
    sideRefresh   = 1.5,
    stepInterval  = 0.10,
    maxStepErrors = 30,
    actorRetries  = 20,
}

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

local Side = {}

function Side.detect()
    local map = workspace:FindFirstChild("Map")
    local stages = map and map:FindFirstChild("Stages")
    if not stages then return nil end

    local marker = stages:FindFirstChild(localPlayer.Name, true)
    if not marker and localPlayer.DisplayName ~= localPlayer.Name then
        marker = stages:FindFirstChild(localPlayer.DisplayName, true)
    end

    local cur = marker and marker.Parent
    while cur and cur ~= stages do
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
    GameUI.nextTry = now + 0.25

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
        -- Timing & Accuracy
        localPlayer:SetAttribute("GCCSickPct", State.sickPct)
        localPlayer:SetAttribute("GCCGoodPct", State.goodPct)
        localPlayer:SetAttribute("GCCOkPct", State.okPct)
        localPlayer:SetAttribute("GCCBadPct", State.badPct)
        localPlayer:SetAttribute("GCCMissPct", State.missPct)
        localPlayer:SetAttribute("GCCMissCooldown", State.missCooldown)
        localPlayer:SetAttribute("GCCSickMaxOffset", State.sickMaxOffsetMs)
        -- Dynamic Accuracy Scaling (DAS)
        localPlayer:SetAttribute("GCCDynAcc", State.dynamicAccuracy)
        localPlayer:SetAttribute("GCDenseMs", State.denseThresholdMs)
        localPlayer:SetAttribute("GCSparseMs", State.sparseThresholdMs)
        localPlayer:SetAttribute("GCComfortNps", State.comfortNps)
        localPlayer:SetAttribute("GCHardNps", State.hardNps)
        localPlayer:SetAttribute("GCPenaltyPct", State.strainPenaltyPct)
        -- Dynamic Missing Based on Difficulty (DMBOD)
        localPlayer:SetAttribute("GCCDmbod", State.dmbod)
        localPlayer:SetAttribute("GCDmbodMaxMiss", State.dmbodMaxMissPct)
        -- Watcher
        localPlayer:SetAttribute("GCCWatcherActive", State.watcherEnabled)
    end)
end

local function releaseAll()
    pcall(function()
        localPlayer:SetAttribute("GCCReleaseAll",
            (tonumber(localPlayer:GetAttribute("GCCReleaseAll")) or 0) + 1)
    end)
end

-- ------------------------------------------------------------ ACTOR INJECTION

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
        local table_sort = table.sort

        local fwV
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
        local lastMechanicDispatch = 0
        local mechanicCentered = false
        local nextSearchAt = 0
        local cachedPlayerGui
        local cachedPendulumPivot
        local nextPendulumRefresh = 0

        -- Accuracy Distribution Weights Cache
        local cumSick = 92
        local cumGood = 98
        local cumOk = 100
        local cumBad = 100
        local totalWeight = 100
        local nextMissAllowedAt = 0

        -- ------------------------------------------------------------
        -- ZERO-ALLOCATION CONTINUOUS DIFFICULTY & NPS ENGINE
        -- ------------------------------------------------------------
        local lastGlobalNoteTime = 0
        local lastDistinctNoteTime = 0
        local lastLaneNoteTime = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }

        -- Monotonic NPS Ring Buffer (Song-Time window: 1.25s)
        local NPS_WINDOW = 1.25
        local RING_SIZE = 128
        local npsRing = table.create(RING_SIZE, 0)
        local ringHead = 1
        local ringCount = 0

        -- Smooth Strain & Fatigue State
        local accumulatedStrain = 0
        local lastStrainUpdateTime = 0

        -- Watcher Runtime Telemetry State
        local currentPeakNPS = 0
        local lastComputedRollingNPS = 0
        local currentSpam = false
        local currentComfort = "COMFORTABLE"
        local dasActivationCount = 0
        local dmbodTriggerCount = 0
        local currentDynamicMissRate = 0
        local chartAnalyzedCache = nil
        local nextTelemetrySyncAt = 0

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
            dmbod = LP:GetAttribute("GCCDmbod") ~= false,
            dmbodMaxMiss = tonumber(LP:GetAttribute("GCDmbodMaxMiss")) or 5,
            watcherActive = LP:GetAttribute("GCCWatcherActive") ~= false,
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

        local function resetWatcherCounters()
            currentPeakNPS = 0
            lastComputedRollingNPS = 0
            currentSpam = false
            currentComfort = "COMFORTABLE"
            dasActivationCount = 0
            dmbodTriggerCount = 0
            currentDynamicMissRate = 0
            chartAnalyzedCache = nil
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
        trackAttr("GCCDmbod", function(v) attr.dmbod = v ~= false end)
        trackAttr("GCDmbodMaxMiss", function(v) attr.dmbodMaxMiss = tonumber(v) or 5 end)
        trackAttr("GCCWatcherActive", function(v) attr.watcherActive = v ~= false end)
        trackAttr("GCCWatcherReset", function() resetWatcherCounters() end)

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
                or v.Direction ~= nil or v.Hit ~= nil or v.Length ~= nil
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
            local z = (math_random() + math_random() + math_random() - 1.5) * 1.4142
            local offset = z * (maxWindowSec * 0.33)
            return math_clamp(offset, -maxWindowSec, maxWindowSec)
        end

        local function shouldHit(arrow, diff, dt, targetOffset)
            local adjDiff = diff - (targetOffset or 0)
            local prev = arrow._bybyPrev
            arrow._bybyPrev = adjDiff
            local step = dt or 0.016
            local lateWindow = math_min(0.06, math_max(0.02, step * 1.75))
            if adjDiff <= (step * 0.3) and adjDiff >= -lateWindow then return true end
            if prev ~= nil and prev > 0 and adjDiff < -lateWindow and adjDiff >= -0.12 then return true end
            return false
        end

        local function sideMatches(arrow, field, sideName)
            local af = arrow.Field
            if af == nil then return true end
            local fs = field.Side
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

        local nestedGroups = {}
        local function forEachNote(nc, cb)
            local groups = 0
            for k, v in next, nc do
                if type(v) == "table" then
                    if isArrowLike(v) then
                        cb(v, nil)
                    else
                        groups = groups + 1
                        local slot = nestedGroups[groups]
                        if not slot then
                            slot = {}
                            nestedGroups[groups] = slot
                        end
                        slot[1] = k
                        slot[2] = v
                    end
                end
            end

            if groups > 0 then
                local useHint = groups <= 10
                for i = 1, groups do
                    local slot = nestedGroups[i]
                    local hint = useHint and tonumber(slot[1]) or nil
                    for _, v2 in next, slot[2] do
                        if type(v2) == "table" and isArrowLike(v2) then
                            cb(v2, hint)
                        end
                    end
                    slot[1], slot[2] = nil, nil
                end
            end
        end

        -- Static Chart Difficulty & Gap Analyzer
        local function analyzeChart(field, sideName)
            if not field or type(field.NoteCache) ~= "table" then return nil end

            local noteTimes = {}
            local seenIds = {}

            forEachNote(field.NoteCache, function(arrow)
                if not sideMatches(arrow, field, sideName) then return end
                if arrow.NoteData and (arrow.NoteData.Type == "Death" or arrow.NoteData.Type == "Poison") then return end

                local t = extractTime(arrow)
                if t then
                    if t > 1000 then t = t * 0.001 end
                    local id = arrow.Index or (arrow.NoteData and arrow.NoteData.Index) or arrow
                    if not seenIds[id] then
                        seenIds[id] = true
                        noteTimes[#noteTimes + 1] = t
                    end
                end
            end)

            local totalNotes = #noteTimes
            if totalNotes < 2 then
                return {
                    totalNotes = totalNotes,
                    duration = 0,
                    meanNps = 0,
                    meanDeltaMs = 0,
                    primaryTier = "NORMAL",
                    pctNormal = 100,
                    pctHard = 0,
                    pctInsane = 0,
                    pctMania = 0,
                    pctLunatic = 0,
                    pctImpossible = 0,
                }
            end

            table_sort(noteTimes)

            local minT = noteTimes[1]
            local maxT = noteTimes[totalNotes]
            local duration = math_max(1, maxT - minT)
            local meanNps = totalNotes / duration

            local deltaSum = 0
            local deltaCount = 0

            local counts = {
                Normal = 0,
                Hard = 0,
                Insane = 0,
                Mania = 0,
                Lunatic = 0,
                Impossible = 0,
            }

            for i = 2, totalNotes do
                local dtSec = noteTimes[i] - noteTimes[i - 1]
                if dtSec > 0.002 then
                    local dtMs = dtSec * 1000
                    deltaSum = deltaSum + dtMs
                    deltaCount = deltaCount + 1

                    local localNps = 1000.0 / dtMs

                    if localNps < 4 or dtMs > 250 then
                        counts.Normal = counts.Normal + 1
                    elseif localNps <= 7 or dtMs > 142 then
                        counts.Hard = counts.Hard + 1
                    elseif localNps <= 11 or dtMs > 90 then
                        counts.Insane = counts.Insane + 1
                    elseif localNps <= 16 or dtMs > 62.5 then
                        counts.Mania = counts.Mania + 1
                    elseif localNps <= 22 or dtMs > 45 then
                        counts.Lunatic = counts.Lunatic + 1
                    else
                        counts.Impossible = counts.Impossible + 1
                    end
                end
            end

            local validIntervals = math_max(1, deltaCount)
            local meanDeltaMs = deltaSum / validIntervals

            local pctNormal = (counts.Normal / validIntervals) * 100
            local pctHard = (counts.Hard / validIntervals) * 100
            local pctInsane = (counts.Insane / validIntervals) * 100
            local pctMania = (counts.Mania / validIntervals) * 100
            local pctLunatic = (counts.Lunatic / validIntervals) * 100
            local pctImpossible = (counts.Impossible / validIntervals) * 100

            local primary = "NORMAL"
            local maxP = pctNormal
            if pctHard > maxP then maxP = pctHard; primary = "HARD" end
            if pctInsane > maxP then maxP = pctInsane; primary = "INSANE" end
            if pctMania > maxP then maxP = pctMania; primary = "MANIA" end
            if pctLunatic > maxP then maxP = pctLunatic; primary = "LUNATIC" end
            if pctImpossible > maxP then maxP = pctImpossible; primary = "IMPOSSIBLE" end

            return {
                totalNotes = totalNotes,
                duration = duration,
                meanNps = meanNps,
                meanDeltaMs = meanDeltaMs,
                primaryTier = primary,
                pctNormal = pctNormal,
                pctHard = pctHard,
                pctInsane = pctInsane,
                pctMania = pctMania,
                pctLunatic = pctLunatic,
                pctImpossible = pctImpossible,
            }
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
            pressLane(lane, false)
            pressLane(lane, true)
            heldLanes[lane] = true
            releaseAt[lane] = nowS + math_max(0.03, (length and length > 0.04) and length or holdWindow)
        end

        local scan = {
            field = nil, timepos = 0, playback = 1, dt = 0.016, dodge = true,
            pending = 0, sideSkips = 0, sidePasses = 0,
            maxLane = 0, zeroBased = false,
            holdWindow = 0.15, sideName = "Left",
            nowS = 0,
            n = 0, pool = {},
        }

        local function poolPush(s, arrow, lane, length)
            local i = s.n + 1
            s.n = i
            local c = s.pool[i]
            if not c then
                c = { arrow = arrow, lane = lane, length = length }
                s.pool[i] = c
            else
                c.arrow = arrow
                c.lane = lane
                c.length = length
            end
        end

        local function sortPool(s)
            local pool, n = s.pool, s.n
            for i = 2, n do
                local c = pool[i]
                local ci = tonumber(c.arrow.Index) or math.huge
                local j = i - 1
                while j >= 1 do
                    local p = pool[j]
                    local pi = tonumber(p.arrow.Index) or math.huge
                    if pi > ci then
                        pool[j + 1] = p
                        j = j - 1
                    else
                        break
                    end
                end
                pool[j + 1] = c
            end
        end

        local death = { Death = true, Poison = true }

        local function processArrow(arrow, laneHint)
            if not arrow or arrow._bybyHit then return end

            if not sideBroken and not sideMatches(arrow, scan.field, scan.sideName) then
                scan.sideSkips = scan.sideSkips + 1
                return
            end
            scan.sidePasses = scan.sidePasses + 1

            if scan.dodge and type(arrow.NoteData) == "table" and arrow.NoteData.Type and death[arrow.NoteData.Type] then
                return
            end

            local rawLane = laneHint or extractLane(arrow)
            if not rawLane then return end
            if rawLane == 0 then scan.zeroBased = true end
            if rawLane > scan.maxLane then scan.maxLane = rawLane end

            local rawTime = extractTime(arrow)
            if not rawTime then return end
            local nTime = (rawTime > 1000 and scan.timepos < 500) and (rawTime * 0.001) or rawTime

            local diff = normDiff(nTime, scan.timepos)
            if not diff then return end
            diff = diff / scan.playback

            if diff < -0.25 then
                arrow._bybyHit = true
                return
            end

            if diff > -0.5 then
                scan.pending = scan.pending + 1
            end

            -- ------------------------------------------------------------
            -- DAS v4 & DMBOD & WATCHER TELEMETRY
            -- ------------------------------------------------------------
            if arrow._bybyTargetOffset == nil and not arrow._bybyMiss and diff <= 0.22 then
                local targetLaneIdx = laneFromValue(rawLane, 10)
                local lastLaneT = (targetLaneIdx and lastLaneNoteTime[targetLaneIdx]) or 0
                local dtLane = (lastLaneT > 0) and (nTime - lastLaneT) or 1.0

                local isChord = (lastGlobalNoteTime > 0) and (math_abs(nTime - lastGlobalNoteTime) <= 0.014)

                -- 1. Rolling Density & Burst NPS
                npsRing[ringHead] = nTime
                ringHead = (ringHead % RING_SIZE) + 1
                if ringCount < RING_SIZE then
                    ringCount = ringCount + 1
                end

                local activeDensityCount = 0
                for rIdx = 1, ringCount do
                    local t = npsRing[rIdx]
                    local deltaWindow = nTime - t
                    if deltaWindow >= 0 and deltaWindow <= NPS_WINDOW then
                        activeDensityCount = activeDensityCount + 1
                    end
                end
                local rollingNPS = activeDensityCount / NPS_WINDOW
                lastComputedRollingNPS = rollingNPS

                local dtInter = (lastDistinctNoteTime > 0) and math_max(0.015, nTime - lastDistinctNoteTime) or 0.20
                local burstNPS = math_clamp(1.0 / dtInter, 0.0, 35.0)
                local effectiveNPS = math_max(rollingNPS, (rollingNPS * 0.5) + (burstNPS * 0.5))

                if effectiveNPS > currentPeakNPS then
                    currentPeakNPS = effectiveNPS
                end

                -- Spam Detection (< denseThresholdMs)
                currentSpam = (dtInter * 1000) < attr.denseMs

                -- 2. Exponential Strain & Fatigue Accumulator
                if lastStrainUpdateTime > 0 then
                    local dtIdle = math_max(0, nTime - lastStrainUpdateTime)
                    if dtIdle > 0 then
                        accumulatedStrain = accumulatedStrain * math_exp(-2.0 * dtIdle)
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

                -- 3. Lane Jack Fatigue
                local jackStrain = 0.0
                if lastLaneT > 0 and dtLane < 0.22 and dtLane > 0.012 then
                    jackStrain = math_clamp(1.0 - (dtLane / 0.22), 0.0, 1.0)
                end

                local baseDiffFactor = math_clamp((effectiveNPS - comfortNps) / (hardNps - comfortNps), 0.0, 1.0)
                local diffIndex = math_clamp((baseDiffFactor * 0.45) + (accumulatedStrain * 0.35) + (jackStrain * 0.20), 0.0, 1.0)

                lastGlobalNoteTime = nTime
                if not isChord then
                    lastDistinctNoteTime = nTime
                end
                if targetLaneIdx and targetLaneIdx >= 1 and targetLaneIdx <= 10 then
                    lastLaneNoteTime[targetLaneIdx] = nTime
                end

                -- 4. Dynamic Missing (DMBOD v4)
                local currentMissPct = 0
                if attr.dmbod then
                    local lowDiffBaseline = math_min(0.4, attr.dmbodMaxMiss * 0.08)
                    currentMissPct = lowDiffBaseline + ((attr.dmbodMaxMiss - lowDiffBaseline) * (diffIndex ^ 1.25))
                    currentMissPct = math_clamp(currentMissPct, 0.0, attr.dmbodMaxMiss)
                else
                    currentMissPct = attr.missPct
                end
                currentDynamicMissRate = currentMissPct

                -- 5. Dynamic Accuracy Scaling (DAS v4)
                local curSick = attr.sickPct
                local curGood = attr.goodPct
                local curOk = attr.okPct
                local curBad = attr.badPct

                if attr.dynAcc and diffIndex > 0.05 then
                    local penaltyMultiplier = diffIndex * (attr.penaltyPct * 0.01)
                    local shaved = curSick * penaltyMultiplier
                    if shaved > 1 then
                        dasActivationCount = dasActivationCount + 1
                    end
                    curSick = math_max(5, curSick - shaved)

                    local highShift = diffIndex
                    curGood = curGood + (shaved * math_clamp(0.65 - (highShift * 0.25), 0.35, 0.65))
                    curOk = curOk + (shaved * math_clamp(0.25 + (highShift * 0.10), 0.25, 0.38))
                    curBad = curBad + (shaved * math_clamp(0.10 + (highShift * 0.15), 0.10, 0.28))
                end

                local cSick = curSick
                local cGood = cSick + curGood
                local cOk = cGood + curOk
                local cBad = cOk + curBad
                local cTotal = cBad

                local canMiss = (scan.nowS >= nextMissAllowedAt) and (currentMissPct > 0)
                if canMiss then
                    cTotal = cBad + currentMissPct
                end
                if cTotal <= 0 then cTotal = 100 end

                local roll = math_random() * cTotal
                if roll < cSick then
                    arrow._bybyTargetOffset = gaussianOffset(attr.sickMaxOffset)
                elseif roll < cGood then
                    local ms = math_random(48, 76)
                    arrow._bybyTargetOffset = (math_random() > 0.5 and ms or -ms) * 0.001
                elseif roll < cOk then
                    local ms = math_random(82, 118)
                    arrow._bybyTargetOffset = (math_random() > 0.5 and ms or -ms) * 0.001
                elseif roll < cBad then
                    local ms = math_random(125, 150)
                    arrow._bybyTargetOffset = (math_random() > 0.5 and ms or -ms) * 0.001
                else
                    arrow._bybyMiss = true
                    dmbodTriggerCount = dmbodTriggerCount + 1
                    nextMissAllowedAt = scan.nowS + attr.missCooldown
                end
            end

            if arrow._bybyMiss then
                if diff < -0.25 then
                    arrow._bybyHit = true
                end
                return
            end

            if shouldHit(arrow, diff, scan.dt, arrow._bybyTargetOffset) then
                poolPush(scan, arrow, rawLane, (extractLength(arrow) or 0.03) / scan.playback)
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

            -- Mechanics Check
            if attr.mechanics and attr.ap then
                local mechanics = fwV.VSRG and fwV.VSRG.Mechanics
                local actionController = mechanics and mechanics.Action
                local activeAction = actionController and actionController.ActiveAction

                if activeAction and activeAction.Enabled then
                    if activeAction ~= lastMechanicAction then
                        lastMechanicAction = activeAction
                        lastMechanicDispatch = 0
                        mechanicCentered = false
                    end

                    local dispatchedByPendulum = false
                    if tostring(activeAction.Label):upper() == "RESIST" then
                        local pivot = getPendulumPivot(nowS)
                        if pivot and pivot:IsA("GuiObject") and pivot.Visible then
                            dispatchedByPendulum = true
                            local centered = math_abs(pivot.Rotation) <= 3
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

                    if not dispatchedByPendulum and (nowS - lastMechanicDispatch >= attr.mechanicInterval) then
                        lastMechanicDispatch = nowS
                        if type(actionController.Dispatch) == "function" then
                            pcall(actionController.Dispatch, actionController, activeAction)
                        elseif type(activeAction.Callback) == "function" then
                            pcall(activeAction.Callback)
                        end
                    end
                else
                    lastMechanicAction = nil
                    lastMechanicDispatch = 0
                    mechanicCentered = false
                end
            end

            -- Rhythm Notes Engine
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

                -- Reset on chart change or seek
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
                    chartAnalyzedCache = nil
                elseif lastNoteCache ~= field.NoteCache then
                    lastNoteCache = field.NoteCache
                    chartAnalyzedCache = nil
                end

                if timepos ~= tpV then tpV, tpVAt = timepos, nowS end

                -- One-time chart breakdown computation for Watcher
                if attr.watcherActive and not chartAnalyzedCache then
                    chartAnalyzedCache = analyzeChart(field, attr.sideName)
                    if chartAnalyzedCache then
                        pcall(function()
                            LP:SetAttribute("GCC_W_TotalNotes", chartAnalyzedCache.totalNotes)
                            LP:SetAttribute("GCC_W_Duration", chartAnalyzedCache.duration)
                            LP:SetAttribute("GCC_W_MeanNPS", chartAnalyzedCache.meanNps)
                            LP:SetAttribute("GCC_W_MeanDeltaMs", chartAnalyzedCache.meanDeltaMs)
                            LP:SetAttribute("GCC_W_PrimaryTier", chartAnalyzedCache.primaryTier)
                            LP:SetAttribute("GCC_W_PctNormal", chartAnalyzedCache.pctNormal)
                            LP:SetAttribute("GCC_W_PctHard", chartAnalyzedCache.pctHard)
                            LP:SetAttribute("GCC_W_PctInsane", chartAnalyzedCache.pctInsane)
                            LP:SetAttribute("GCC_W_PctMania", chartAnalyzedCache.pctMania)
                            LP:SetAttribute("GCC_W_PctLunatic", chartAnalyzedCache.pctLunatic)
                            LP:SetAttribute("GCC_W_PctImpossible", chartAnalyzedCache.pctImpossible)
                        end)
                    end
                end

                scan.field = field
                scan.timepos = timepos
                scan.playback = playback
                scan.dt = dt or 0.016
                scan.dodge = attr.dodge
                scan.holdWindow = attr.holdWindow
                scan.sideName = attr.sideName
                scan.nowS = nowS
                scan.pending = 0
                scan.sideSkips = 0
                scan.sidePasses = 0
                scan.maxLane = maxLane
                scan.zeroBased = zeroBased
                scan.n = 0

                pcall(forEachNote, field.NoteCache, processArrow)

                maxLane = scan.maxLane
                zeroBased = scan.zeroBased

                if not sideBroken then
                    if scan.sideSkips > 0 and scan.sidePasses == 0 then
                        if not sideBrokenSince then sideBrokenSince = nowS end
                        if nowS - sideBrokenSince > 3 then sideBroken = true end
                    else
                        sideBrokenSince = nil
                    end
                end

                if scan.pending > 0 and (nowS - tpVAt) < 3 then
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

                if attr.ap and lastV and (nowS - lastV) <= 2 then
                    if scan.n > 1 then
                        sortPool(scan)
                    end
                    for i = 1, scan.n do
                        local c = scan.pool[i]
                        local laneIdx = laneFromValue(c.lane, laneCount)
                        hitLane(laneIdx, c.length, scan.holdWindow, nowS)
                        c.arrow._bybyHit = true
                    end
                end

                -- Telemetry sync at 10 Hz
                if attr.watcherActive and nowS >= nextTelemetrySyncAt then
                    nextTelemetrySyncAt = nowS + 0.10
                    pcall(function()
                        LP:SetAttribute("GCC_W_RollingNPS", lastComputedRollingNPS)
                        LP:SetAttribute("GCC_W_PeakNPS", currentPeakNPS)
                        LP:SetAttribute("GCC_W_Spam", currentSpam)
                        LP:SetAttribute("GCC_W_Comfort", currentComfort)
                        LP:SetAttribute("GCC_W_DasCount", dasActivationCount)
                        LP:SetAttribute("GCC_W_DmbodCount", dmbodTriggerCount)
                        LP:SetAttribute("GCC_W_MissRate", currentDynamicMissRate)
                    end)
                end
            else
                activeField = nil
            end
        end)
    ]=])

    return true
end

-- ------------------------------------------------------------ MAIN LOOP

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
        nextStepAt = now + Tune.stepInterval

        local ok = pcall(Main.step)
        if ok then
            Main.stepErrors = 0
        else
            Main.stepErrors = Main.stepErrors + 1
            if Main.stepErrors >= Tune.maxStepErrors then
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
            task.wait(Tune.sideRefresh)
            if State.inMatch then Side.update() end
        end
    end)

    task.spawn(function()
        for _ = 1, Tune.actorRetries do
            if not isAlive() then return end
            if State.actorInjected then return end
            pcall(injectActor)
            task.wait(1)
        end
    end)
end

-- ------------------------------------------------------------ UI CREATION

local uiElements = {}

-- 1. AUTOPLAY TAB
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
    name = "Comfort NPS Threshold (Low Difficulty / Floor)",
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
    name = "Hard NPS Threshold (High Difficulty / Ceiling)",
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

uiElements.denseThresholdMs = mainTab:CreateSlider({
    name = "Dense Threshold (Peak Burst/Spam)",
    flag = "Yvetzal_FF_DenseMs",
    range = { 10, 200 },
    value = State.denseThresholdMs,
    increment = 5,
    suffix = " ms",
    callback = function(v)
        State.denseThresholdMs = v
        syncFlags()
    end,
})

uiElements.sparseThresholdMs = mainTab:CreateSlider({
    name = "Sparse Threshold (Easy/Neutral Zone)",
    flag = "Yvetzal_FF_SparseMs",
    range = { 100, 500 },
    value = State.sparseThresholdMs,
    increment = 10,
    suffix = " ms",
    callback = function(v)
        State.sparseThresholdMs = v
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

uiElements.strainPenaltyPct = mainTab:CreateSlider({
    name = "Strain Accuracy Penalty",
    flag = "Yvetzal_FF_StrainPenalty",
    range = { 0, 80 },
    value = State.strainPenaltyPct,
    increment = 5,
    suffix = " %",
    callback = function(v)
        State.strainPenaltyPct = v
        syncFlags()
    end,
})

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

uiElements.badPct = mainTab:CreateSlider({
    name = "Bad Base Chance",
    flag = "Yvetzal_FF_BadPct",
    range = { 0, 100 },
    value = State.badPct,
    increment = 1,
    suffix = " %",
    callback = function(v)
        State.badPct = v
        syncFlags()
    end,
})

uiElements.missPct = mainTab:CreateSlider({
    name = "Static Miss Chance (Non-DMBOD)",
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

uiElements.missCooldown = mainTab:CreateSlider({
    name = "Miss Cooldown",
    flag = "Yvetzal_FF_MissCooldown",
    range = { 0.5, 15 },
    value = State.missCooldown,
    increment = 0.5,
    suffix = " s",
    callback = function(v)
        State.missCooldown = v
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

uiElements.mechanicInterval = mainTab:CreateSlider({
    name = "Mechanic Interval",
    flag = "Yvetzal_FF_MechInterval",
    range = { 0.01, 0.2 },
    value = State.mechanicInterval,
    increment = 0.01,
    suffix = " s",
    callback = function(v)
        State.mechanicInterval = v
        syncFlags()
    end,
})

-- 2. WATCHER TAB (ADAPTIVE TEXT / LABEL CARDS)
watcherTab:CreateSection({ name = "WATCHER CONTROLS", icon = "eye" })

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

local function resetWatcherUI()
    pcall(function()
        if watcherLabels.chartOverview then
            watcherLabels.chartOverview:Set({
                Title = "Chart Overview",
                Content = "Total Notes: --\nChart Duration: -- s\nMean Average NPS: --\nMean Inter-Note Gap: -- ms\nPeak Burst NPS: --\nRolling Dynamic NPS: --",
            })
        end
        if watcherLabels.difficultyBreakdown then
            watcherLabels.difficultyBreakdown:Set({
                Title = "Difficulty Profile",
                Content = "Primary Tier: --\n\n• Normal: --%\n• Hard: --%\n• Insane: --%\n• Mania: --%\n• Lunatic: --%\n• Impossible: --%",
            })
        end
        if watcherLabels.diagnostics then
            watcherLabels.diagnostics:Set({
                Title = "Real-Time Engine Diagnostics",
                Content = "Density Status: --\nFatigue / Comfort: --\nDynamic Miss Rate: --%\nDAS Activations: --\nDMBOD Triggers: --",
            })
        end
    end)
end

watcherTab:CreateButton({
    name = "Clear / Reset Data",
    callback = function()
        pcall(function()
            localPlayer:SetAttribute("GCCWatcherReset", os.clock())
            localPlayer:SetAttribute("GCC_W_TotalNotes", nil)
            localPlayer:SetAttribute("GCC_W_Duration", nil)
            localPlayer:SetAttribute("GCC_W_MeanNPS", nil)
            localPlayer:SetAttribute("GCC_W_MeanDeltaMs", nil)
            localPlayer:SetAttribute("GCC_W_PrimaryTier", nil)
            localPlayer:SetAttribute("GCC_W_PctNormal", nil)
            localPlayer:SetAttribute("GCC_W_PctHard", nil)
            localPlayer:SetAttribute("GCC_W_PctInsane", nil)
            localPlayer:SetAttribute("GCC_W_PctMania", nil)
            localPlayer:SetAttribute("GCC_W_PctLunatic", nil)
            localPlayer:SetAttribute("GCC_W_PctImpossible", nil)
            localPlayer:SetAttribute("GCC_W_RollingNPS", nil)
            localPlayer:SetAttribute("GCC_W_PeakNPS", nil)
            localPlayer:SetAttribute("GCC_W_Spam", nil)
            localPlayer:SetAttribute("GCC_W_Comfort", nil)
            localPlayer:SetAttribute("GCC_W_DasCount", nil)
            localPlayer:SetAttribute("GCC_W_DmbodCount", nil)
            localPlayer:SetAttribute("GCC_W_MissRate", nil)
        end)
        resetWatcherUI()
        window:Notify({
            title = "Watcher",
            content = "Telemetry data cleared successfully",
            icon = iconAsset("crosshair"),
            duration = 2.5,
        })
    end,
})

watcherTab:CreateSection({ name = "CHART METRICS & AVERAGES", icon = "crosshair" })

watcherLabels.chartOverview = createTextItem(
    watcherTab,
    "Chart Overview",
    "Total Notes: --\nChart Duration: -- s\nMean Average NPS: --\nMean Inter-Note Gap: -- ms\nPeak Burst NPS: --\nRolling Dynamic NPS: --"
)

watcherTab:CreateSection({ name = "DIFFICULTY BREAKDOWN", icon = "palette" })

watcherLabels.difficultyBreakdown = createTextItem(
    watcherTab,
    "Difficulty Profile",
    "Primary Tier: --\n\n• Normal: --%\n• Hard: --%\n• Insane: --%\n• Mania: --%\n• Lunatic: --%\n• Impossible: --%"
)

watcherTab:CreateSection({ name = "ENGINE DIAGNOSTICS (DAS & DMBOD)", icon = "settings" })

watcherLabels.diagnostics = createTextItem(
    watcherTab,
    "Real-Time Engine Diagnostics",
    "Density Status: --\nFatigue / Comfort: --\nDynamic Miss Rate: --%\nDAS Activations: --\nDMBOD Triggers: --"
)

-- UI Telemetry Sync Loop
task.spawn(function()
    while isAlive() do
        task.wait(0.20)
        if State.watcherEnabled and State.inMatch then
            pcall(function()
                local totalNotes = localPlayer:GetAttribute("GCC_W_TotalNotes")
                local duration = localPlayer:GetAttribute("GCC_W_Duration")
                local meanNps = localPlayer:GetAttribute("GCC_W_MeanNPS")
                local meanDelta = localPlayer:GetAttribute("GCC_W_MeanDeltaMs")
                local rollingNps = localPlayer:GetAttribute("GCC_W_RollingNPS") or 0
                local peakNps = localPlayer:GetAttribute("GCC_W_PeakNPS") or 0

                local primaryTier = localPlayer:GetAttribute("GCC_W_PrimaryTier") or "--"
                local pNormal = localPlayer:GetAttribute("GCC_W_PctNormal") or 0
                local pHard = localPlayer:GetAttribute("GCC_W_PctHard") or 0
                local pInsane = localPlayer:GetAttribute("GCC_W_PctInsane") or 0
                local pMania = localPlayer:GetAttribute("GCC_W_PctMania") or 0
                local pLunatic = localPlayer:GetAttribute("GCC_W_PctLunatic") or 0
                local pImpossible = localPlayer:GetAttribute("GCC_W_PctImpossible") or 0

                local isSpam = localPlayer:GetAttribute("GCC_W_Spam") == true
                local comfort = localPlayer:GetAttribute("GCC_W_Comfort") or "COMFORTABLE"
                local dasCount = localPlayer:GetAttribute("GCC_W_DasCount") or 0
                local dmbodCount = localPlayer:GetAttribute("GCC_W_DmbodCount") or 0
                local missRate = localPlayer:GetAttribute("GCC_W_MissRate") or 0

                if watcherLabels.chartOverview then
                    watcherLabels.chartOverview:Set({
                        Title = "Chart Overview",
                        Content = string.format(
                            "Total Notes: %s\nChart Duration: %s s\nMean Average NPS: %s\nMean Inter-Note Gap: %s ms\nPeak Burst NPS: %.2f\nRolling Dynamic NPS: %.2f",
                            totalNotes and tostring(totalNotes) or "--",
                            duration and string.format("%.1f", duration) or "--",
                            meanNps and string.format("%.2f", meanNps) or "--",
                            meanDelta and string.format("%.1f", meanDelta) or "--",
                            peakNps,
                            rollingNps
                        ),
                    })
                end

                if watcherLabels.difficultyBreakdown then
                    watcherLabels.difficultyBreakdown:Set({
                        Title = "Difficulty Profile",
                        Content = string.format(
                            "Primary Tier: %s\n\n• Normal (<4 NPS): %.1f%%\n• Hard (4-7 NPS): %.1f%%\n• Insane (7-11 NPS): %.1f%%\n• Mania (11-16 NPS): %.1f%%\n• Lunatic (16-22 NPS): %.1f%%\n• Impossible (>22 NPS): %.1f%%",
                            primaryTier,
                            pNormal,
                            pHard,
                            pInsane,
                            pMania,
                            pLunatic,
                            pImpossible
                        ),
                    })
                end

                if watcherLabels.diagnostics then
                    local spamColor = isSpam and "SPAM: TRUE" or "SPAM: FALSE"
                    watcherLabels.diagnostics:Set({
                        Title = "Real-Time Engine Diagnostics",
                        Content = string.format(
                            "Density Status: %s\nFatigue State: %s\nDynamic Miss Rate: %.2f%%\nDAS Activations (Shaved Sick): %d\nDMBOD Triggers (Dynamic Misses): %d",
                            spamColor,
                            tostring(comfort),
                            missRate,
                            dasCount,
                            dmbodCount
                        ),
                    })
                end
            end)
        end
    end
end)

-- 3. SETTINGS TAB
settingsTab:CreateSection({ name = "CONFIG MANAGEMENT", icon = "settings" })

local function syncUIWithState()
    pcall(function()
        if uiElements.autoplay then uiElements.autoplay:Set(State.autoplay) end
        if uiElements.dodge then uiElements.dodge:Set(State.dodge) end
        if uiElements.mechanics then uiElements.mechanics:Set(State.mechanics) end
        if uiElements.sideMode then uiElements.sideMode:Set(State.sideMode) end
        if uiElements.dynamicAccuracy then uiElements.dynamicAccuracy:Set(State.dynamicAccuracy) end
        if uiElements.dmbod then uiElements.dmbod:Set(State.dmbod) end
        if uiElements.comfortNps then uiElements.comfortNps:Set(State.comfortNps) end
        if uiElements.hardNps then uiElements.hardNps:Set(State.hardNps) end
        if uiElements.denseThresholdMs then uiElements.denseThresholdMs:Set(State.denseThresholdMs) end
        if uiElements.sparseThresholdMs then uiElements.sparseThresholdMs:Set(State.sparseThresholdMs) end
        if uiElements.dmbodMaxMissPct then uiElements.dmbodMaxMissPct:Set(State.dmbodMaxMissPct) end
        if uiElements.strainPenaltyPct then uiElements.strainPenaltyPct:Set(State.strainPenaltyPct) end
        if uiElements.sickMaxOffsetMs then uiElements.sickMaxOffsetMs:Set(State.sickMaxOffsetMs) end
        if uiElements.sickPct then uiElements.sickPct:Set(State.sickPct) end
        if uiElements.goodPct then uiElements.goodPct:Set(State.goodPct) end
        if uiElements.okPct then uiElements.okPct:Set(State.okPct) end
        if uiElements.badPct then uiElements.badPct:Set(State.badPct) end
        if uiElements.missPct then uiElements.missPct:Set(State.missPct) end
        if uiElements.missCooldown then uiElements.missCooldown:Set(State.missCooldown) end
        if uiElements.holdTime then uiElements.holdTime:Set(math.floor(State.holdTime * 1000)) end
        if uiElements.mechanicInterval then uiElements.mechanicInterval:Set(State.mechanicInterval) end
        if uiElements.watcherToggle then uiElements.watcherToggle:Set(State.watcherEnabled) end
    end)
end

settingsTab:CreateButton({
    name = "Save Configuration",
    callback = function()
        saveConfig()
        window:Notify({
            title = "Configuration",
            content = "Config saved to " .. CONFIG_FILE,
            icon = iconAsset("settings"),
            duration = 3,
        })
    end,
})

settingsTab:CreateButton({
    name = "Reload Configuration",
    callback = function()
        if loadConfig() then
            syncUIWithState()
            syncFlags()
            window:Notify({
                title = "Configuration",
                content = "Config successfully loaded",
                icon = iconAsset("settings"),
                duration = 3,
            })
        else
            window:Notify({
                title = "Configuration",
                content = "No saved configuration file found",
                icon = iconAsset("settings"),
                duration = 3,
            })
        end
    end,
})

settingsTab:CreateButton({
    name = "Reset to Defaults (Pro 4K Preset)",
    callback = function()
        for k, v in pairs(DefaultConfig) do
            State[k] = v
        end
        saveConfig()
        syncUIWithState()
        syncFlags()
        window:Notify({
            title = "Configuration",
            content = "Reset to Pro 4K Player defaults",
            icon = iconAsset("settings"),
            duration = 3,
        })
    end,
})

settingsTab:CreateSection({ name = "SCRIPT CONTROLS", icon = "settings" })

settingsTab:CreateButton({
    name = "Re-inject Actor",
    callback = function()
        State.actorInjected = false
        pcall(function() localPlayer:SetAttribute("GCCFW", false) end)
        pcall(injectActor)
    end,
})

settingsTab:CreateButton({
    name = "Unload Funky Friday",
    callback = function()
        if state.stop then
            state.stop()
        end
    end,
})

-- ------------------------------------------------------------ CLEANUP & INIT

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
        localPlayer:SetAttribute("GCCMechanicInterval", nil)
        localPlayer:SetAttribute("GCCAlive", false)
        localPlayer:SetAttribute("GCCFW", false)
        localPlayer:SetAttribute("GCCFWKind", nil)
        localPlayer:SetAttribute("GCCHitLane", nil)
        localPlayer:SetAttribute("GCCSide", nil)
        localPlayer:SetAttribute("GCCRunId", nil)
        localPlayer:SetAttribute("GCCHoldMs", nil)
        localPlayer:SetAttribute("GCCDodge", nil)
        localPlayer:SetAttribute("GCCSickPct", nil)
        localPlayer:SetAttribute("GCCGoodPct", nil)
        localPlayer:SetAttribute("GCCOkPct", nil)
        localPlayer:SetAttribute("GCCBadPct", nil)
        localPlayer:SetAttribute("GCCMissPct", nil)
        localPlayer:SetAttribute("GCCMissCooldown", nil)
        localPlayer:SetAttribute("GCCSickMaxOffset", nil)
        localPlayer:SetAttribute("GCCDynAcc", nil)
        localPlayer:SetAttribute("GCDenseMs", nil)
        localPlayer:SetAttribute("GCSparseMs", nil)
        localPlayer:SetAttribute("GCComfortNps", nil)
        localPlayer:SetAttribute("GCHardNps", nil)
        localPlayer:SetAttribute("GCPenaltyPct", nil)
        localPlayer:SetAttribute("GCCDmbod", nil)
        localPlayer:SetAttribute("GCDmbodMaxMiss", nil)
        localPlayer:SetAttribute("GCCWatcherActive", nil)
        localPlayer:SetAttribute("GCCWatcherReset", nil)
        localPlayer:SetAttribute("GCC_W_TotalNotes", nil)
        localPlayer:SetAttribute("GCC_W_Duration", nil)
        localPlayer:SetAttribute("GCC_W_MeanNPS", nil)
        localPlayer:SetAttribute("GCC_W_MeanDeltaMs", nil)
        localPlayer:SetAttribute("GCC_W_PrimaryTier", nil)
        localPlayer:SetAttribute("GCC_W_PctNormal", nil)
        localPlayer:SetAttribute("GCC_W_PctHard", nil)
        localPlayer:SetAttribute("GCC_W_PctInsane", nil)
        localPlayer:SetAttribute("GCC_W_PctMania", nil)
        localPlayer:SetAttribute("GCC_W_PctLunatic", nil)
        localPlayer:SetAttribute("GCC_W_PctImpossible", nil)
        localPlayer:SetAttribute("GCC_W_RollingNPS", nil)
        localPlayer:SetAttribute("GCC_W_PeakNPS", nil)
        localPlayer:SetAttribute("GCC_W_Spam", nil)
        localPlayer:SetAttribute("GCC_W_Comfort", nil)
        localPlayer:SetAttribute("GCC_W_DasCount", nil)
        localPlayer:SetAttribute("GCC_W_DmbodCount", nil)
        localPlayer:SetAttribute("GCC_W_MissRate", nil)
    end)

    if shared.YvetzalFunkyFriday == state then
        shared.YvetzalFunkyFriday = nil
    end
    shared.YvetzalFunkyFridayCleanup = nil
end

shared.YvetzalFunkyFridayCleanup = cleanup
state.stop = function()
    cleanup()
end

local originalUnload = window.Unload
window.Unload = function(self)
    cleanup()
    if type(originalUnload) == "function" then
        return originalUnload(self)
    end
    return nil
end

Main.start()
syncFlags()

window:Notify({
    title = "Yvetzal",
    content = "Loaded with Watcher Telemetry, DAS v4 & DMBOD",
    icon = iconAsset("crosshair"),
    duration = 4,
})
