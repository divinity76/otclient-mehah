MessageSettings = {
    none = {},
    consoleRed = {
        color = TextColors.red,
        consoleTab = 'Local Chat'
    },
    consoleOrange = {
        color = TextColors.orange,
        consoleTab = 'Local Chat'
    },
    consoleBlue = {
        color = TextColors.blue,
        consoleTab = 'Local Chat'
    },
    centerRed = {
        color = TextColors.red,
        consoleTab = 'Server Log',
        screenTarget = 'lowCenterLabel'
    },
    centerGreen = {
        color = TextColors.green,
        consoleTab = 'Server Log',
        screenTarget = 'highCenterLabel',
        consoleOption = 'showInfoMessagesInConsole'
    },
    centerWhite = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        screenTarget = 'middleCenterLabel',
        consoleOption = 'showEventMessagesInConsole'
    },
    bottomWhite = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        screenTarget = 'statusLabel',
        consoleOption = 'showEventMessagesInConsole'
    },
    status = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        screenTarget = 'statusLabel',
        consoleOption = 'showStatusMessagesInConsole'
    },
    othersStatus = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        consoleOption = 'showOthersStatusMessagesInConsole'
    },
    statusSmall = {
        color = TextColors.white,
        screenTarget = 'statusLabel'
    },
    private = {
        color = TextColors.lightblue,
        screenTarget = 'privateLabel'
    },
    loot = {
        color = TextColors.white,
        consoleTab = 'Loot',
        screenTarget = 'highCenterLabel',
        consoleOption = 'showInfoMessagesInConsole',
        colored = true
    },
    valuableLoot = {
        color = TextColors.white,
        consoleTab = 'Loot',
        screenTarget = 'statusLabel',
        consoleOption = 'showInfoMessagesInConsole',
        colored = true
    }
}

MessageTypes = {
    [MessageModes.MonsterSay] = MessageSettings.consoleOrange,
    [MessageModes.MonsterYell] = MessageSettings.consoleOrange,
    [MessageModes.BarkLow] = MessageSettings.consoleOrange,
    [MessageModes.BarkLoud] = MessageSettings.consoleOrange,
    [MessageModes.Failure] = MessageSettings.statusSmall,
    [MessageModes.Login] = MessageSettings.bottomWhite,
    [MessageModes.Game] = MessageSettings.centerWhite,
    [MessageModes.Status] = MessageSettings.status,
    [MessageModes.Warning] = MessageSettings.centerRed,
    [MessageModes.Look] = MessageSettings.centerGreen,
    [MessageModes.Loot] = MessageSettings.loot,
    [MessageModes.Red] = MessageSettings.consoleRed,
    [MessageModes.Blue] = MessageSettings.consoleBlue,
    [MessageModes.PrivateFrom] = MessageSettings.consoleBlue,

    [MessageModes.GamemasterBroadcast] = MessageSettings.consoleRed,

    [MessageModes.DamageDealed] = MessageSettings.status,
    [MessageModes.DamageReceived] = MessageSettings.status,
    [MessageModes.Heal] = MessageSettings.status,
    [MessageModes.Exp] = MessageSettings.status,

    [MessageModes.DamageOthers] = MessageSettings.othersStatus,
    [MessageModes.HealOthers] = MessageSettings.othersStatus,
    [MessageModes.ExpOthers] = MessageSettings.othersStatus,
    [MessageModes.Potion] = MessageSettings.othersStatus,

    [MessageModes.TradeNpc] = MessageSettings.centerWhite,
    [MessageModes.Guild] = MessageSettings.centerWhite,
    [MessageModes.Party] = MessageSettings.centerGreen,
    [MessageModes.PartyManagement] = MessageSettings.centerWhite,
    [MessageModes.TutorialHint] = MessageSettings.centerWhite,
    [MessageModes.BeyondLast] = MessageSettings.centerWhite,
    [MessageModes.Report] = MessageSettings.consoleRed,
    [MessageModes.GameHighlight] = MessageSettings.centerRed,
    [MessageModes.HotkeyUse] = MessageSettings.centerGreen,
    [MessageModes.Attention] = MessageSettings.bottomWhite,
    [MessageModes.BoostedCreature] = MessageSettings.centerWhite,
    [MessageModes.OfflineTrainning] = MessageSettings.centerWhite,
    [MessageModes.Transaction] = MessageSettings.centerWhite,
    [MessageModes.ValuableLoot] = MessageSettings.valuableLoot,

    [254] = MessageSettings.private
}

messagesPanel = nil

local function formatPosition(pos)
    if not pos or not pos.x then
        return 'nil'
    end

    return string.format('%d,%d,%d', pos.x, pos.y, pos.z)
end

local PathFindResultNames = {}
if PathFindResults then
    PathFindResultNames[PathFindResults.Ok] = 'ok'
    PathFindResultNames[PathFindResults.Position] = 'same-position'
    PathFindResultNames[PathFindResults.Impossible] = 'impossible'
    PathFindResultNames[PathFindResults.TooFar] = 'too-far'
    PathFindResultNames[PathFindResults.NoWay] = 'no-way'
end

local function boolToStr(value)
    return value and 'true' or 'false'
end

local function listToString(list)
    if not list or #list == 0 then
        return 'none'
    end
    return table.concat(list, ',')
end

local function describeTileState(label, pos, fallback)
    label = label or 'tile'
    if not pos or not pos.x then
        if fallback and fallback ~= '' then
            return string.format('%s[%s]', label, fallback)
        end
        return string.format('%s[pos=invalid]', label)
    end

    local formattedPos = formatPosition(pos)
    local tile = g_map.getTile(pos)
    if not tile then
        if fallback and fallback ~= '' then
            return string.format('%s[%s]', label, fallback)
        end

        return string.format('%s[pos=%s missing=true]', label, formattedPos)
    end

    local seenItems = {}
    local blockingItems, nonPathableItems, floorChangeItems = {}, {}, {}

    local function itemLabel(itemType, itemId)
        if itemType and itemType.getName then
            local name = itemType:getName()
            if name and name ~= '' then
                return string.format('%d(%s)', itemId, name)
            end
        end
        return tostring(itemId)
    end

    local function inspectItem(item)
        if not item or seenItems[item] then
            return
        end
        seenItems[item] = true

        local itemId = item:getId()
        local itemType = g_things and g_things.getItemType and g_things.getItemType(itemId)
        if not itemType then
            return
        end

        local labelValue = itemLabel(itemType, itemId)

        if ThingAttrFloorChange and itemType.hasAttribute and itemType:hasAttribute(ThingAttrFloorChange) then
            table.insert(floorChangeItems, labelValue)
        end

        if itemType:isNotWalkable() or itemType:isFullGround() then
            table.insert(blockingItems, labelValue)
        end

        if itemType:isNotPathable() then
            table.insert(nonPathableItems, labelValue)
        end
    end

    inspectItem(tile:getGround())
    local items = tile:getItems()
    if items then
        for _, item in ipairs(items) do
            inspectItem(item)
        end
    end

    local creaturesList = {}
    if tile:hasCreatures() then
        local creatures = tile:getCreatures() or {}
        for _, creature in ipairs(creatures) do
            if creature then
                table.insert(creaturesList, creature:getName() or 'unknown')
            end
        end
    end

    local elevation = 0
    for level = 10, 1, -1 do
        if tile:hasElevation(level) then
            elevation = level
            break
        end
    end

    return string.format('%s[pos=%s walkable=%s walkableIgnoreCreatures=%s pathable=%s fullGround=%s elevation=%d floorChange=%s floorChangeItems=%s creatures=%s blockingItems=%s nonPathableItems=%s]',
        label,
        formattedPos,
        boolToStr(tile:isWalkable()),
        boolToStr(tile:isWalkable(true)),
        boolToStr(tile:isPathable()),
        boolToStr(tile:isFullGround()),
        elevation,
        boolToStr(#floorChangeItems > 0),
        listToString(floorChangeItems),
        listToString(creaturesList),
        listToString(blockingItems),
        listToString(nonPathableItems)
    )
end

function init()
    for messageMode, _ in pairs(MessageTypes) do
        registerMessageMode(messageMode, displayMessage)
    end

    connect(g_game, 'onGameEnd', clearMessages)
    messagesPanel = g_ui.loadUI('textmessage', modules.game_interface.getRootPanel())
end

function terminate()
    for messageMode, _ in pairs(MessageTypes) do
        unregisterMessageMode(messageMode, displayMessage)
    end

    disconnect(g_game, 'onGameEnd', clearMessages)
    clearMessages()
    messagesPanel:destroy()
    messagesPanel = nil
end

function calculateVisibleTime(text)
    return math.max(#text * 50, 4000)
end

function displayMessage(mode, text)

    if not g_game.isOnline() then
        return
    end

    local msgtype = MessageTypes[mode]
    if not msgtype then
        return
    end

    if msgtype == MessageSettings.none then
        return
    end

    if msgtype.consoleTab ~= nil and
        (msgtype.consoleOption == nil or modules.client_options.getOption(msgtype.consoleOption)) then
        if msgtype == MessageSettings.loot or msgtype == MessageSettings.valuableLoot then
            local lootColoredText = ItemsDatabase.setColorLootMessage(text)
            modules.game_console.addText(lootColoredText, msgtype, tr("Server Log"))
            modules.game_console.addText(lootColoredText, msgtype, tr(msgtype.consoleTab))
        else
            modules.game_console.addText(text, msgtype, tr(msgtype.consoleTab))
        end
    end

    if msgtype.screenTarget then
        local label = messagesPanel:recursiveGetChildById(msgtype.screenTarget)
        if msgtype == MessageSettings.loot and not modules.client_options.getOption('showLootMessagesOnScreen') then
            return
        elseif msgtype == MessageSettings.loot or msgtype == MessageSettings.valuableLoot then
            local coloredText = ItemsDatabase.setColorLootMessage(text)
            label:setColoredText(coloredText)
        else
            label:setText(text)
            label:setColor(msgtype.color)
        end

        label:setVisible(true)
        removeEvent(label.hideEvent)
        label.hideEvent = scheduleEvent(function()
            label:setVisible(false)
        end, calculateVisibleTime(text))
    end
end

function displayPrivateMessage(text)
    displayMessage(254, text)
end

function displayStatusMessage(text)
    displayMessage(MessageModes.Status, text)
end

function displayFailureMessage(text)
    displayMessage(MessageModes.Failure, text)
end

function displayGameMessage(text)
    displayMessage(MessageModes.Game, text)
end

function displayBroadcastMessage(text)
    displayMessage(MessageModes.Warning, text)
end

function clearMessages()
    for _i, child in pairs(messagesPanel:recursiveGetChildren()) do
        if child:getId():match('Label') then
            child:hide()
            removeEvent(child.hideEvent)
        end
    end
end

function LocalPlayer:onAutoWalkFail(status, startPos, destinationPos, pathLength, complexity, playerPos, pendingDestination, retries, failureReason, destinationTileDebug, playerTileDebug, pendingTileDebug, belowTileDebug, aboveTileDebug)
    local text = tr('There is no way.')
    local statusName = PathFindResultNames[status] or 'unknown'

    if modules and modules.gamelib and modules.gamelib.textmessages and modules.gamelib.textmessages.logTrackedMessage then
        local function positionsEqual(a, b)
            return a and b and a.x == b.x and a.y == b.y and a.z == b.z
        end

        local contextParts = {
            string.format('mode=%s', tostring(MessageModes.Failure)),
            'reason=AutoWalkFail',
            string.format('status=%s(%s)', tostring(status or 'nil'), statusName),
            string.format('start=%s', formatPosition(startPos)),
            string.format('destination=%s', formatPosition(destinationPos)),
            string.format('pendingDestination=%s', formatPosition(pendingDestination)),
            string.format('playerPos=%s', formatPosition(playerPos)),
            string.format('pathLength=%s', pathLength and tostring(pathLength) or 'nil'),
            string.format('complexity=%s', complexity and tostring(complexity) or 'nil'),
            string.format('retries=%s', retries and tostring(retries) or 'nil'),
            string.format('failureReason=%s', failureReason or 'unspecified')
        }

        local tileContexts = { describeTileState('destTile', destinationPos, destinationTileDebug) }
        if not positionsEqual(playerPos, destinationPos) then
            table.insert(tileContexts, describeTileState('playerTile', playerPos, playerTileDebug))
        end
        if pendingDestination and not positionsEqual(pendingDestination, destinationPos) then
            table.insert(tileContexts, describeTileState('pendingTile', pendingDestination, pendingTileDebug))
        end

        local belowPos
        if destinationPos and destinationPos.x and destinationPos.z then
            belowPos = { x = destinationPos.x, y = destinationPos.y, z = destinationPos.z + 1 }
        end
        table.insert(tileContexts, describeTileState('belowTile', belowPos, belowTileDebug))

        local abovePos
        if destinationPos and destinationPos.x and destinationPos.z and destinationPos.z > 0 then
            abovePos = { x = destinationPos.x, y = destinationPos.y, z = destinationPos.z - 1 }
        end
        table.insert(tileContexts, describeTileState('aboveTile', abovePos, aboveTileDebug))

        local context = table.concat(contextParts, ' ') .. ' ' .. table.concat(tileContexts, ' ')

        modules.gamelib.textmessages.logTrackedMessage('Lua LocalPlayer:onAutoWalkFail', text, context)
    end

    modules.game_textmessage.displayFailureMessage(text)
end
