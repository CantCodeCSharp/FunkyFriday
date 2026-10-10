-- Yvetzal: Funky Friday Autoplay (Cleaned & Fixed)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local players = game:GetService("Players")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer
local shared = type(getgenv) == "function" and getgenv() or _G

-- Kill any prior instance (GCC or Yvetzal)
if shared.GoodGammingChairCleanup then
    pcall(shared.GoodGammingChairCleanup)
end
if shared.YvetzalFunkyFriday and shared.YvetzalFunkyFriday.stop then
    pcall(shared.YvetzalFunkyFriday.stop)
end

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
    subtitle = "FUNKY FRIDAY AUTOPLAY",
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
local settingsTab = makeTab("Settings", "settings")

-- ------------------------------------------------------------ CORE STATE

local Tune = {
    sideRefresh   = 1.5,
    stepInterval  = 0.10,
    maxStepErrors = 30,
    actorRetries  = 20,
}

local State = {
    autoSide = "Left",
    inMatch = false,
    sideMode = "Auto",
    autoplay = true,
    dodge = true,
    mechanics = true,
    holdTime = 0.150,
    mechanicInterval = 0.05,
    actorInjected = false,
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

-- Forward declaration to prevent nil-index errors in GUI callbacks
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
        local cachedFieldsUi
        local cachedPendulumPivot
        local nextPendulumRefresh = 0
        local lastLaneProbeField
        local attr = {
            runId = actorRunId,
            alive = LP:GetAttribute("GCCAlive"),
            ap = LP:GetAttribute("GCCAP"),
            dodge = LP:GetAttribute("GCCDodge") ~= false,
            mechanics = LP:GetAttribute("GCCMechanics") == true,
            mechanicInterval = tonumber(LP:GetAttribute("GCCMechanicInterval")) or 0.05,
            holdWindow = (tonumber(LP:GetAttribute("GCCHoldMs")) or 150) / 1000,
            sideName = LP:GetAttribute("GCCSide") or "Left",
            releaseDirty = false,
        }
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
        trackAttr("GCCHoldMs", function(v) attr.holdWindow = (tonumber(v) or 150) / 1000 end)
        trackAttr("GCCSide", function(v) attr.sideName = v or "Left" end)

        local function getPlayerGui()
            local pg = cachedPlayerGui
            if pg and pg.Parent then return pg end
            pg = LP:FindFirstChild("PlayerGui")
            cachedPlayerGui = pg
            return pg
        end

        local function getFieldsUi()
            local fieldsUi = cachedFieldsUi
            if fieldsUi and fieldsUi.Parent then return fieldsUi end
            local pg = getPlayerGui()
            local window = pg and pg:FindFirstChild("Window")
            local gameUi = window and window:FindFirstChild("Game")
            fieldsUi = gameUi and gameUi:FindFirstChild("Fields")
            cachedFieldsUi = fieldsUi
            return fieldsUi
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
            return (math.floor(p) % count) + 1
        end

        local function normDiff(noteTime, songTime)
            if type(noteTime) ~= "number" or type(songTime) ~= "number" then return nil end
            if noteTime > 1000 and songTime < 500 then noteTime = noteTime / 1000 end
            if songTime > 1000 and noteTime < 500 then songTime = songTime / 1000 end
            return noteTime - songTime
        end

        local function shouldHit(arrow, diff, dt)
            local prev = arrow._bybyPrev
            arrow._bybyPrev = diff
            local lateWindow = math.min(0.08, math.max(0.025, (dt or 0.016) * 2.5))
            if diff <= 0 and diff >= -lateWindow then return true end
            if prev ~= nil and prev > 0 and diff < -lateWindow and diff >= -0.15 then return true end
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

        local function pressLane(lane, down)
            if lane == nil then return end
            local field = activeField or (fwV and fwV.VSRG and fwV.VSRG.GameHandler and fwV.VSRG.GameHandler.Field)
            if field and type(field.HitLane) == "function" then
                pcall(field.HitLane, field, lane, down, nil)
            end
        end

        local held = {}
        local releaseAt = {}

        local function releaseHeld()
            if next(held) ~= nil then
                for lane in pairs(held) do
                    pressLane(lane, false)
                end
                table.clear(held)
            end
            table.clear(releaseAt)
        end

        local function flushReleases(nowS)
            for lane, releaseTime in pairs(releaseAt) do
                if nowS >= releaseTime then
                    pressLane(lane, false)
                    held[lane] = nil
                    releaseAt[lane] = nil
                end
            end
        end

        local function hitLane(lane, length, holdWindow, nowS)
            if lane == nil then return end
            pressLane(lane, false)
            pressLane(lane, true)
            held[lane] = true
            releaseAt[lane] = nowS + math.max(0.03, (length and length > 0.04) and length or holdWindow)
        end

        local scan = {
            field = nil, timepos = 0, playback = 1, dt = 0.016, dodge = true,
            pending = 0, sideSkips = 0, sidePasses = 0,
            maxLane = 0, zeroBased = false,
            holdWindow = 0.15, sideName = "Left",
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
                local ci = tonumber(c.arrow.Index)
                if ci == nil then ci = math.huge end
                local j = i - 1
                while j >= 1 do
                    local p = pool[j]
                    local pi = tonumber(p.arrow.Index)
                    if pi == nil or pi > ci then
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

            local diff = normDiff(extractTime(arrow), scan.timepos)
            if not diff then return end
            diff = diff / scan.playback
            if diff > -0.5 then scan.pending = scan.pending + 1 end

            if shouldHit(arrow, diff, scan.dt) then
                poolPush(scan, arrow, rawLane, (extractLength(arrow) or 0.03) / scan.playback)
            elseif diff < -0.25 then
                arrow._bybyHit = true
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
            if attr.ap ~= true then
                releaseHeld()
                return
            end

            local nowS = clockS()
            if not fwV then
                search(nowS)
                if not fwV then return end
            end

            flushReleases(nowS)

            local dodge = attr.dodge
            local mechanicsEnabled = attr.mechanics
            local mechanicInterval = attr.mechanicInterval
            local holdWindow = attr.holdWindow
            local sideName = attr.sideName

            -- Mechanics Handler
            if mechanicsEnabled then
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
                            local centered = math.abs(pivot.Rotation) <= 3
                            if centered and not mechanicCentered then
                                mechanicCentered = true
                                if type(actionController.Dispatch) == "function" then
                                    pcall(actionController.Dispatch, actionController, activeAction)
                                elseif type(activeAction.Callback) == "function" then
                                    pcall(activeAction.Callback)
                                end
                            elseif math.abs(pivot.Rotation) >= 8 then
                                mechanicCentered = false
                            end
                        end
                    end

                    if not dispatchedByPendulum then
                        if nowS - lastMechanicDispatch >= mechanicInterval then
                            lastMechanicDispatch = nowS
                            if type(actionController.Dispatch) == "function" then
                                pcall(actionController.Dispatch, actionController, activeAction)
                            elseif type(activeAction.Callback) == "function" then
                                pcall(activeAction.Callback)
                            end
                        end
                    end
                else
                    lastMechanicAction = nil
                    lastMechanicDispatch = 0
                    mechanicCentered = false
                end
            else
                lastMechanicAction = nil
                lastMechanicDispatch = 0
                mechanicCentered = false
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

                if lastField ~= field or lastGame ~= gameObj then
                    lastField, lastGame, lastNoteCache = field, gameObj, field.NoteCache
                    laneCount, maxLane, zeroBased = 4, 0, false
                    nextCountCheck = 0
                    lastLaneProbeField = nil
                    sideBroken, sideBrokenSince = false, nil
                elseif lastNoteCache ~= field.NoteCache then
                    lastNoteCache = field.NoteCache
                end

                local timepos = gameObj.TimePosition
                local playback = gameObj.AdjustedPlayback or 1
                if playback == 0 then playback = 1 end
                if timepos ~= tpV then tpV, tpVAt = timepos, nowS end

                scan.field = field
                scan.timepos = timepos
                scan.playback = playback
                scan.dt = dt or 0.016
                scan.dodge = dodge
                scan.holdWindow = holdWindow
                scan.sideName = sideName
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
                        if nowS - sideBrokenSince > 3 then
                            sideBroken = true
                        end
                    else
                        sideBrokenSince = nil
                    end
                end

                if scan.pending > 0 and (nowS - tpVAt) < 3 then
                    lastV = nowS
                end

                if nowS >= nextCountCheck then
                    nextCountCheck = nowS + 10
                    local probed
                    pcall(function()
                        local gh = fwV.VSRG.GameHandler
                        local list = {
                            field.KeyCount, field.Keys, field.LaneCount,
                            gh and gh.KeyCount, gh and gh.Keys, gh and gh.LaneCount,
                        }
                        for _, v in ipairs(list) do
                            local n = tonumber(v)
                            if n and n >= 3 and n <= 9 then
                                probed = math.floor(n)
                                return
                            end
                        end
                    end)

                    if not probed and laneCount <= 4 and lastLaneProbeField ~= field then
                        lastLaneProbeField = field
                        pcall(function()
                            local f = getFieldsUi()
                            if not f then return end
                            local byParent = {}
                            for _, d in ipairs(f:GetDescendants()) do
                                if d.Name:match("^Lane%d+$") then
                                    byParent[d.Parent] = (byParent[d.Parent] or 0) + 1
                                end
                            end
                            local best = 0
                            for _, c in pairs(byParent) do
                                if c > best then best = c end
                            end
                            if best >= 3 and best <= 9 then probed = best end
                        end)
                    end

                    if probed and probed > laneCount and probed <= 9 then laneCount = probed end
                end

                if maxLane > 0 then
                    local observed = zeroBased and (maxLane + 1) or maxLane
                    if observed > laneCount and observed <= 9 then laneCount = observed end
                end

                if lastV and (nowS - lastV) <= 2 then
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

-- ------------------------------------------------------------ UI SETUP

mainTab:CreateSection({ name = "AUTOPLAY", icon = "eye" })

mainTab:CreateToggle({
    name = "Enable Autoplay",
    flag = "Yvetzal_FunkyFriday_Enabled",
    value = true,
    callback = function(v)
        State.autoplay = v
        syncFlags()
        if not v then releaseAll() end
    end,
})

mainTab:CreateToggle({
    name = "Dodge Death / Poison",
    flag = "Yvetzal_FunkyFriday_Dodge",
    value = true,
    callback = function(v)
        State.dodge = v
        syncFlags()
    end,
})

mainTab:CreateToggle({
    name = "Auto Mechanics (RESIST)",
    flag = "Yvetzal_FunkyFriday_Mechanics",
    value = true,
    callback = function(v)
        State.mechanics = v
        syncFlags()
    end,
})

mainTab:CreateDropdown({
    name = "Side",
    flag = "Yvetzal_FunkyFriday_Side",
    options = { "Auto", "Left", "Right" },
    value = "Auto",
    callback = function(v)
        State.sideMode = v
        Side.update()
        syncFlags()
    end,
})

mainTab:CreateSection({ name = "TIMING", icon = "crosshair" })

mainTab:CreateSlider({
    name = "Hold Window",
    flag = "Yvetzal_FunkyFriday_HoldMs",
    range = { 30, 300 },
    value = 150,
    increment = 5,
    suffix = " ms",
    callback = function(v)
        State.holdTime = v / 1000
        syncFlags()
    end,
})

mainTab:CreateSlider({
    name = "Mechanic Interval",
    flag = "Yvetzal_FunkyFriday_MechInterval",
    range = { 0.01, 0.2 },
    value = 0.05,
    increment = 0.01,
    suffix = " s",
    callback = function(v)
        State.mechanicInterval = v
        syncFlags()
    end,
})

settingsTab:CreateSection({ name = "SCRIPT", icon = "settings" })

settingsTab:CreateText({
    name = "Requirements",
    text = "Requires run_on_actor (ClientActor) and filtergc support.",
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
    content = "Autoplay loaded successfully",
    icon = iconAsset("eye"),
    duration = 4,
})
