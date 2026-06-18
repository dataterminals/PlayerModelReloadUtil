--[[
    Player Model Reload Utility
    ---------------------------
    Rebuilds the local player's 3D model on demand, via either:
      * a rebindable keybind (default INSERT), or
      * right-click in-game -> Utilities -> Reload Player Model

    Recovers from the B42 invisible-character bug without reloading the save:
    when an animation/ragdoll transition (e.g. tripping while mantling a
    railing) forces a model rebuild, the engine can resolve a model's mesh to
    null -> "ERROR: ProcessedAiScene.processAiScene > No such mesh null" -> the
    character renders as nothing. resetModelNextFrame() reassembles the model
    on the next frame; it is the same call vanilla uses when toggling
    blood/dirt on the character (see ISDebugBlood.lua).

    Standalone, no dependencies, load order irrelevant. Safe to remove.
]]

local BIND_NAME = "Reload Player Model"

-- shared action used by both the keybind and the context menu
local function doReloadModel(player)
    if not player then return end

    -- 1) rebuild the model DATA (skin, clothing, attachments). On its own this
    --    does NOT recover the B42 z-transition invisible-model state - those
    --    resets are meant for appearance changes - but it's cheap and correct.
    player:resetModel()
    if player.resetEquippedHandsModels then
        player:resetEquippedHandsModels()
    end

    -- 2) re-register the character with the world/cell so the renderer
    --    re-attaches its model on the current floor. The player object stays
    --    valid (you can still move while invisible); it's the model that got
    --    detached from the render scene. removeFromWorld()+addToWorld() is the
    --    in-game equivalent of the full re-init a save reload does.
    --    pcall-guarded: if it ever errors, the model-data reset above still ran.
    local ok = pcall(function()
        local sq = player:getCurrentSquare()
        if sq then
            player:removeFromWorld()
            player:addToWorld()
        end
    end)

    -- 3) one more rebuild next frame now that it's re-attached
    player:resetModelNextFrame()

    -- on-screen confirmation (addGoodText = green; B42 dropped the colored addText overload)
    if HaloTextHelper and HaloTextHelper.addGoodText then
        HaloTextHelper.addGoodText(player, ok and "Reloading model..." or "Reloading model (partial)...")
    end
end

-- keybind -> reload the main local player
local function onKeyPressed(key)
    if not getCore():isKey(BIND_NAME, key) then return end
    doReloadModel(getSpecificPlayer(0))
end

-- right-click world menu -> Utilities submenu -> Reload Player Model
local function onFillContextMenu(playerIndex, context, worldobjects)
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
