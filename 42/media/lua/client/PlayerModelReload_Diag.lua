--[[
    Visibility Diagnostics (opt-in, off by default)
    -----------------------------------------------
    Investigative tool for the wall-cutaway invisible-player bug. While enabled,
    it logs the local player's render-visibility state to the console so we can
    see WHY the engine keeps you hidden in some spots:

      * targetAlpha stuck near 0  -> the cutaway/occlusion system is deciding you
                                     should stay hidden (root cause = occlusion).
      * targetAlpha ~1 but alpha stuck 0 -> the fade-toward-target loop isn't
                                     running for the player (root cause = update).

    It also records what is on the square and the square directly above (the
    likely occluder), plus z-level, so we can correlate the stuck state with the
    basement-stairwell geometry.

    Toggle via right-click -> Utilities -> Visibility Diagnostics. Read results in
    Zomboid/console.txt (or the DebugLog), filtering for "PMRU-DIAG".
    Purely read-only: it observes, it does not change anything.
]]

PMRU_Diag = PMRU_Diag or {}
PMRU_Diag.enabled = false
PMRU_Diag.lastLine = nil
PMRU_Diag.lastBeat = 0

local function sqTag(sq)
    if not sq then return "none" end
    local room = sq:getRoom()
    local bld = sq:getBuilding()
    return string.format("room=%s bld=%s",
        room and (room:getName() or "y") or "n",
        bld and "y" or "n")
end

-- logged every frame while faded; identical consecutive lines are de-duped, so
-- we capture transitions and re-fades without 60 spam lines per second
PMRU_Diag.tick = function(player)
    if not PMRU_Diag.enabled then return end
    if not player or player:getPlayerNum() ~= 0 then return end

    local pn = player:getPlayerNum() or 0
    local a  = player:getAlpha(pn)
    local ta = player:getTargetAlpha(pn)
    local hidden = (player.isHidden and tostring(player:isHidden())) or "n/a"

    local sq = player:getCurrentSquare()
    local z = sq and sq:getZ() or -99
    local above = nil
    if sq and getCell() then
        above = getCell():getGridSquare(sq:getX(), sq:getY(), sq:getZ() + 1)
    end

    local now = getTimestampMs()
    local faded = (a < 0.95) or (ta < 0.95)

    local line = string.format(
        "[PMRU-DIAG] alpha=%.2f targetAlpha=%.2f hidden=%s z=%d here[%s] above[%s]",
        a, ta, hidden, z, sqTag(sq), sqTag(above))

    if faded then
        if line ~= PMRU_Diag.lastLine then
            print(line)
            PMRU_Diag.lastLine = line
        end
    elseif (now - PMRU_Diag.lastBeat) > 2000 then
        -- occasional heartbeat when fully visible, to confirm it's running
        print(line .. " (visible)")
        PMRU_Diag.lastBeat = now
        PMRU_Diag.lastLine = nil
    end
end

PMRU_Diag.toggle = function()
    PMRU_Diag.enabled = not PMRU_Diag.enabled
    PMRU_Diag.lastLine = nil
    local player = getSpecificPlayer(0)
    if player and HaloTextHelper and HaloTextHelper.addGoodText then
        HaloTextHelper.addGoodText(player,
            PMRU_Diag.enabled and "Visibility diag: ON" or "Visibility diag: OFF")
    end
    print("[PMRU-DIAG] enabled=" .. tostring(PMRU_Diag.enabled))
end

-- add the toggle to the shared "Utilities" submenu (reuse it if already present)
local function onFillContextMenu(playerIndex, context)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    local utilOption = context:getOptionFromName("Utilities")
    local utilSubMenu
    if utilOption and utilOption.subOption then
        utilSubMenu = context:getSubMenu(utilOption.subOption)
    end
    if not utilSubMenu then
        utilOption = context:addOption("Utilities")
        utilSubMenu = context:getNew(context)
        context:addSubMenu(utilOption, utilSubMenu)
    end

    local label = PMRU_Diag.enabled and "Visibility Diagnostics: ON" or "Visibility Diagnostics: OFF"
    utilSubMenu:addOption(label, nil, PMRU_Diag.toggle)
end

Events.OnPlayerUpdate.Add(PMRU_Diag.tick)
Events.OnFillWorldObjectContextMenu.Add(onFillContextMenu)
