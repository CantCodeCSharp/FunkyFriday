-- [[ Rscripts Risk Notice ]]
-- This script is not verified by rscripts.net. Deal with caution.
--
-- Stay safe:
--   • Never log in on unofficial Roblox sites or lookalike domains.
--   • Real Roblox links use roblox.com (check the .com ending).
--   • Treat fake Roblox login / "claim reward" pages as phishing.
-- [[ End Rscripts Risk Notice ]]

-- YOU'RE USING A GOOD GAMING CHAIR Script

-- 1. BOOTSTRAP

if getgenv().BybyHubCleanup then
    pcall(getgenv().BybyHubCleanup)
end
if getgenv().GoodGammingChairCleanup then
    pcall(getgenv().GoodGammingChairCleanup)
end

local runToken = {}
getgenv().GoodGammingChairToken = runToken
local runId = tostring(runToken)

local function IsAlive()
    return getgenv().GoodGammingChairToken == runToken
end

local connections = {}
local function Track(conn)
    connections[#connections + 1] = conn
    return conn
end

-- 2. SERVICES/CONFIGS

local RunService = game:GetService("RunService")
local LP = game:GetService("Players").LocalPlayer

local HOLD_TIME = 0.150
local MECHANIC_INTERVAL = 0.05

local Const = {
    SideRefresh = 1.5,
    MainStepInterval = 0.10,
    MaxStepErrors = 30,
    ActorRetries = 20,
}

local State = {
    AutoSide = "Left",
    InMatch = false,
}

local Framework = { ActorInjected = false }

-- 3. SIDE

local Side = {}

function Side.Detect()
    local map = workspace:FindFirstChild("Map")
    local stages = map and map:FindFirstChild("Stages")
    if not stages then return nil end

    local marker = stages:FindFirstChild(LP.Name, true)
    if not marker and LP.DisplayName ~= LP.Name then
        marker = stages:FindFirstChild(LP.DisplayName, true)
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

function Side.Update()
    local side = Side.Detect()
    if side and side ~= State.AutoSide then
        State.AutoSide = side
        pcall(function() LP:SetAttribute("GCCSide", side) end)
    end
    return side
end

-- 4. GAME UI

local GameUI = { Game = nil, Fields = nil, NextTry = 0 }

function GameUI.Get(now)
    local gameUI, fields = GameUI.Game, GameUI.Fields
    if gameUI and fields and gameUI.Parent and fields.Parent then
        return gameUI, fields
    end
    if now < GameUI.NextTry then return nil, nil end
    GameUI.NextTry = now + 0.25

    local pgui = LP:FindFirstChild("PlayerGui")
    local window = pgui and pgui:FindFirstChild("Window")
    gameUI = window and window:FindFirstChild("Game")
    fields = gameUI and gameUI:FindFirstChild("Fields")
    GameUI.Game, GameUI.Fields = gameUI, fields
    return gameUI, fields
end

-- 5. ACTOR COMMN

local function SyncActorFlagsImpl()
    LP:SetAttribute("GCCAP", true)
    LP:SetAttribute("GCCMechanics", true)
    LP:SetAttribute("GCCMechanicInterval", MECHANIC_INTERVAL)
    LP:SetAttribute("GCCHoldMs", math.floor(HOLD_TIME * 1000))
    LP:SetAttribute("GCCDodge", true)
    LP:SetAttribute("GCCSide", State.AutoSide)
    LP:SetAttribute("GCCAlive", IsAlive())
    LP:SetAttribute("GCCRunId", runId)
end

local function SyncActorFlags()
    pcall(SyncActorFlagsImpl)
end

local function ReleaseSignal()
    pcall(function()
        LP:SetAttribute("GCCReleaseAll", (tonumber(LP:GetAttribute("GCCReleaseAll")) or 0) + 1)
    end)
end

-- 6. CLIENTACTOR

function Framework.TryActor()
    if Framework.ActorInjected then
        return LP:GetAttribute("GCCFW") == true
    end
    if type(run_on_actor) ~= "function" then return false end
    local ps = LP:FindFirstChild("PlayerScripts")
    local actor = ps and (ps:FindFirstChild("ClientActor") or ps:FindFirstChildWhichIsA("Actor"))
    if not actor then return false end

    Framework.ActorInjected = true
    SyncActorFlags()

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

        trackAttr("GCCReleaseAll", function()
            attr.releaseDirty = true
        end)
        trackAttr("GCCRunId", function(v)
            attr.runId = v
        end)
        trackAttr("GCCAlive", function(v)
            attr.alive = v
        end)
        trackAttr("GCCAP", function(v)
            attr.ap = v
        end)
        trackAttr("GCCDodge", function(v)
            attr.dodge = v ~= false
        end)
        trackAttr("GCCMechanics", function(v)
            attr.mechanics = v == true
        end)
        trackAttr("GCCMechanicInterval", function(v)
            attr.mechanicInterval = tonumber(v) or 0.05
        end)
        trackAttr("GCCHoldMs", function(v)
            attr.holdWindow = (tonumber(v) or 150) / 1000
        end)
        trackAttr("GCCSide", function(v)
            attr.sideName = v or "Left"
        end)

        local function getPlayerGui()
            local pg = cachedPlayerGui
            if pg and pg.Parent then
                return pg
            end
            pg = LP:FindFirstChild("PlayerGui")
            cachedPlayerGui = pg
            return pg
        end

        local function getFieldsUi()
            local fieldsUi = cachedFieldsUi
            if fieldsUi and fieldsUi.Parent then
                return fieldsUi
            end
            local pg = getPlayerGui()
            local window = pg and pg:FindFirstChild("Window")
            local gameUi = window and window:FindFirstChild("Game")
            fieldsUi = gameUi and gameUi:FindFirstChild("Fields")
            cachedFieldsUi = fieldsUi
            return fieldsUi
        end

        local function getPendulumPivot(nowS)
            local pivot = cachedPendulumPivot
            if pivot and pivot.Parent then
                return pivot
            end
            if nowS < nextPendulumRefresh then
                return nil
            end
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

            -- AUTO MECHANICS
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

            -- VSRG
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

function Framework.Init()
    task.spawn(function()
        for _ = 1, Const.ActorRetries do
            if not IsAlive() then return end
            if Framework.ActorInjected then return end
            pcall(Framework.TryActor)
            task.wait(1)
        end
    end)
end

-- 7. MAIN

local Main = { StepErrors = 0 }

function Main.Step()
    local now = os.clock()
    local gameUI, fields = GameUI.Get(now)
    local isPlaying = (gameUI and gameUI.Visible and fields and fields.Visible) == true

    if isPlaying and not State.InMatch then
        State.InMatch = true
        Side.Update()
        SyncActorFlags()
        if not Framework.ActorInjected then
            pcall(Framework.TryActor)
        end
    elseif not isPlaying and State.InMatch then
        State.InMatch = false
        ReleaseSignal()
    end
end

function Main.Start()
    local nextStepAt = 0

    Track(RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now < nextStepAt then return end
        nextStepAt = now + Const.MainStepInterval

        local ok, err = pcall(Main.Step)
        if ok then
            Main.StepErrors = 0
        else
            Main.StepErrors = Main.StepErrors + 1
            if Main.StepErrors >= Const.MaxStepErrors then
                Main.StepErrors = 0
                pcall(function()
                    LP:SetAttribute("GCCAP", false)
                    LP:SetAttribute("GCCAlive", false)
                end)
                ReleaseSignal()
            end
        end
    end))

    task.spawn(function()
        while IsAlive() do
            task.wait(Const.SideRefresh)
            if State.InMatch then
                Side.Update()
            end
        end
    end)

    Framework.Init()
end

-- 8. STATUS GUI

local StatusGui

local function GetExecutorName()
    if type(identifyexecutor) == "function" then
        local ok, name = pcall(identifyexecutor)
        if ok and type(name) == "string" and #name > 0 then
            return name
        end
    end
    return "UNKNOWN"
end

local function BuildStatusGui(execName, hasRunOnActor, hasFiltergc)
    local gui = Instance.new("ScreenGui")
    gui.Name = "GoodGammingChair"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 9999

    local parented = pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    if not parented or not gui.Parent then
        local pg = LP:FindFirstChild("PlayerGui")
        if not pg then
            gui:Destroy()
            return nil, nil
        end
        gui.Parent = pg
    end

    local GREEN = Color3.fromRGB(96, 205, 120)
    local RED = Color3.fromRGB(235, 90, 90)
    local ORANGE = Color3.fromRGB(240, 175, 80)
    local GRAY = Color3.fromRGB(165, 165, 180)
    local WHITE = Color3.fromRGB(240, 240, 250)
    local DIM = Color3.fromRGB(120, 120, 140)

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 360, 0, 195)
    main.Position = UDim2.new(0, 24, 0, 160)
    main.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui

    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 10)
    mc.Parent = main

    local ms = Instance.new("UIStroke")
    ms.Color = Color3.fromRGB(65, 65, 80)
    ms.Thickness = 1
    ms.Parent = main

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 14, 0, 6)
    title.Size = UDim2.new(1, -70, 0, 24)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = WHITE
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Good Gamming Chair"
    title.Parent = main

    local close = Instance.new("TextButton")
    close.Position = UDim2.new(1, -40, 0, 4)
    close.Size = UDim2.new(0, 28, 0, 26)
    close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Text = "X"
    close.Parent = main

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = close

    Track(close.MouseButton1Click:Connect(function()
        gui:Destroy()
    end))

    local sep = Instance.new("Frame")
    sep.Position = UDim2.new(0, 14, 0, 36)
    sep.Size = UDim2.new(1, -28, 0, 1)
    sep.BackgroundColor3 = Color3.fromRGB(65, 65, 80)
    sep.BorderSizePixel = 0
    sep.Parent = main

    local rows = {}

    local function addLabel(y, text, color, size)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Position = UDim2.new(0, 14, 0, y)
        l.Size = UDim2.new(1, -28, 0, 16)
        l.Font = Enum.Font.Gotham
        l.TextSize = size or 13
        l.TextColor3 = color or GRAY
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = text
        l.Parent = main
        return l
    end

    local function addRow(y, name, valueText, valueColor)
        local l = addLabel(y, name, GRAY, 13)
        l.Size = UDim2.new(0, 188, 0, 16)

        local v = Instance.new("TextLabel")
        v.BackgroundTransparency = 1
        v.Position = UDim2.new(0, 202, 0, y)
        v.Size = UDim2.new(1, -216, 0, 16)
        v.Font = Enum.Font.GothamMedium
        v.TextSize = 12
        v.TextColor3 = valueColor or WHITE
        v.TextXAlignment = Enum.TextXAlignment.Right
        v.TextTruncate = Enum.TextTruncate.AtEnd
        v.Text = valueText
        v.Parent = main
        return v
    end

    rows.exec = addRow(46, "Executor", execName, execName == "UNKNOWN" and ORANGE or GREEN)

    addLabel(72, "AP SUPPORT", DIM, 11)

    rows.actor = addRow(94, "run_on_actor (ClientActor)",
        hasRunOnActor and "OK" or "MISSING", hasRunOnActor and GREEN or RED)
    rows.filtergc = addRow(116, "filtergc (game clock)",
        hasFiltergc and "OK" or "MISSING", hasFiltergc and GREEN or RED)
    rows.hitlane = addRow(138, "HitLane (lane input)", "waiting", GRAY)
    rows.status = addRow(162, "Status", "starting...", ORANGE)

    local function updateGuiStatus()
        if rows.hitlane and rows.hitlane.Parent then
            local hl = LP:GetAttribute("GCCHitLane") == true
            rows.hitlane.Text = hl and "OK" or "waiting"
            rows.hitlane.TextColor3 = hl and GREEN or GRAY
        end
        if rows.status and rows.status.Parent then
            if not hasRunOnActor then
                rows.status.Text = "not supported"
                rows.status.TextColor3 = RED
            elseif LP:GetAttribute("GCCFW") == true then
                rows.status.Text = "connected (vsrg)"
                rows.status.TextColor3 = GREEN
            else
                rows.status.Text = "searching game..."
                rows.status.TextColor3 = ORANGE
            end
        end
    end

    updateGuiStatus()
    Track(LP:GetAttributeChangedSignal("GCCHitLane"):Connect(updateGuiStatus))
    Track(LP:GetAttributeChangedSignal("GCCFW"):Connect(updateGuiStatus))

    return gui, rows
end

-- 9. CLEANUP

local function Cleanup()
    getgenv().GoodGammingChairToken = nil
    ReleaseSignal()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
    pcall(function()
        LP:SetAttribute("GCCAP", false)
        LP:SetAttribute("GCCMechanics", false)
        LP:SetAttribute("GCCMechanicInterval", nil)
        LP:SetAttribute("GCCAlive", false)
        LP:SetAttribute("GCCFW", false)
        LP:SetAttribute("GCCFWKind", nil)
        LP:SetAttribute("GCCHitLane", nil)
        LP:SetAttribute("GCCSide", nil)
        LP:SetAttribute("GCCRunId", nil)
        LP:SetAttribute("GCCHoldMs", nil)
        LP:SetAttribute("GCCDodge", nil)
        LP:SetAttribute("BybyAP", false)
        LP:SetAttribute("BybyAlive", false)
        LP:SetAttribute("BybyRunId", nil)
        LP:SetAttribute("BybyFW", false)
        LP:SetAttribute("BybyFWKind", nil)
    end)
    if StatusGui then
        pcall(function() StatusGui:Destroy() end)
        StatusGui = nil
    end
    getgenv().GoodGammingChairCleanup = nil
end

-- 10. INICIALIZATION

getgenv().GoodGammingChairCleanup = Cleanup

local execName = GetExecutorName()
local hasRunOnActor = type(run_on_actor) == "function"
local hasFiltergc = false
if type(filtergc) == "function" then
    local ok, res = pcall(filtergc, "table", { Keys = { "VSRG", "Songs" } })
    hasFiltergc = ok and type(res) == "table"
end

Main.Start()
SyncActorFlags()

local gui, rows = BuildStatusGui(execName, hasRunOnActor, hasFiltergc)
if gui then
    StatusGui = gui
end

print(" GAMING CHAIR INICIALIZATED ")
