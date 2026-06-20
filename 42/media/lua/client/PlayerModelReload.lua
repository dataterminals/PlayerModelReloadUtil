--[[
    Player Model Reload Utility
    ---------------------------
    Keeps your character visible through the B42 wall-cutaway "invisible player"
    bug without reloading the save.

    The bug: when you pass behind a wall the engine can't make transparent - most
    reliably the wall around a basement stairwell - the cutaway system fades your
    character's per-player render alpha toward 0 to hide you. In these spots the
    un-hide never fires, and the engine keeps re-driving alpha back to 0 every
    frame, so you stay invisible (but fully functional). A one-shot reload only
    makes you reappear for a moment before it re-hides you.

    Two tools (both right-click -> Utilities, plus a keybind for the reload):
      * Auto-Visibility (default ON): every frame, re-assert full alpha so the
        cutaway can never hold you invisible. This is the hands-free fix.
      * Reload Player Model (keybind default INSERT): one-shot force-visible +
        model-data rebuild, also useful for the rarer null-mesh model glitch.

    Only ever changes rendering (alpha + model data). It never touches the
    world/grid, so it cannot affect your position or movement. Standalone, no
    dependencies, load order irrelevant. Safe to remove.
]]

local BIND_NAME = "Reload Player Model"

PMRU = PMRU or {}
if PMRU.autoVisible == nil then PMRU.autoVisible = true end

-- core: force the local player's render alpha back to fully visible
local function forceVisible(player)
    if not player then return end
    pcall(function()
        local pn = player:getPlayerNum() or 0
        player:setAlpha(pn, 1.0)
        if player.setTargetAlpha then player:setTargetAlpha(pn, 1.0) end
    end)
end

-- manual one-shot: force visible + rebuild model data (covers the rarer
-- "No such mesh null" model glitch as well as the cutaway hide)
local function doReloadModel(player)
    if not player then return end
    forceVisible(player)
    player:resetModelNextFrame()
    if player.resetEquippedHandsModels then
        player:resetEquippedHandsModels()
    end
    if HaloTextHelper and HaloTextHelper.addGoodText then
        HaloTextHelper.addGoodText(player, "Reloading model...")
    end
end

-- auto watchdog: every frame, undo the cutaway hide so you never go invisible.
-- (Leaves vehicles alone - the player model is handled differently while driving.)
local function autoEnforce(player)
    if not PMRU.autoVisible then return end
    if not player or player:getPlayerNum() ~= 0 then return end
    if player:getVehicle() then return end
    forceVisible(player)
end

local function toggleAuto(player)
    PMRU.autoVisible = not PMRU.autoVisible
    if player and HaloTextHelper and HaloTextHelper.addGoodText then
        HaloTextHelper.addGoodText(player,
            PMRU.autoVisible and "Auto-Visibility: ON" or "Auto-Visibility: OFF")
    end
end

-- keybind -> one-shot reload of the main local player
local function onKeyPressed(key)
    if not getCore():isKey(BIND_NAME, key) then return end
    doReloadModel(getSpecificPlayer(0))
end

-- right-click world menu -> Utilities submenu
local function onFillContextMenu(playerIndex, context)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    -- reuse an existing "Utilities" submenu if another util already made one
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

    utilSubMenu:addOption("Reload Player Model", player, doReloadModel)
    utilSubMenu:addOption(
        PMRU.autoVisible and "Auto-Visibility: ON" or "Auto-Visibility: OFF",
        player, toggleAuto)
end

-- register the rebindable key once (it appears in Options > Key Bindings)
local function registerKeyBind()
    for _, kb in ipairs(keyBinding) do
        if kb.value == BIND_NAME then return end
    end
    table.insert(keyBinding, { value = "[Player Model Reload]" })
    table.insert(keyBinding, { value = BIND_NAME, key = Keyboard.KEY_INSERT })
end

registerKeyBind()
Events.OnKeyPressed.Add(onKeyPressed)
Events.OnFillWorldObjectContextMenu.Add(onFillContextMenu)
Events.OnPlayerUpdate.Add(autoEnforce)
