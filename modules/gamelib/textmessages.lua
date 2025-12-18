local messageModeCallbacks = {}
local trackedMessages = {
    ["Sorry, not possible."] = true,
    ["Sorry, not possible"] = true,
    ["There is no way."] = true,
    ["There is no way"] = true
}

local logFilePath

local function isTrackedMessage(message)
    return trackedMessages[message] or false
end

local function resolveLogPath()
    if logFilePath then
        return logFilePath
    end

    local binaryPath = g_resources and g_resources.getBinaryPath and g_resources.getBinaryPath() or ''
    local dir = binaryPath:match("^(.*)[/\\]")
    if not dir or dir == '' then
        dir = '.'
    end

    logFilePath = dir .. '/sorry.log'
    return logFilePath
end

local function appendSorryLog(source, message, context)
    local file = io.open(resolveLogPath(), 'a')
    if not file then
        return
    end

    if context and context ~= '' then
        file:write(string.format('[%s] %s | %s\n', source, context, message))
    else
        file:write(string.format('[%s] %s\n', source, message))
    end
    file:close()
end

local function describeCallbacks(callbacks)
    if not callbacks or #callbacks == 0 then
        return 'callbacks=none'
    end

    local entries = {}
    for _, callback in pairs(callbacks) do
        local info = debug.getinfo(callback, 'S')
        if info then
            local src = info.short_src or info.source or 'unknown'
            local line = info.linedefined or -1
            table.insert(entries, string.format('%s:%d', src, line))
        else
            table.insert(entries, tostring(callback))
        end
    end

    return 'callbacks={' .. table.concat(entries, ', ') .. '}'
end

local function logTrackedMessage(source, message, context)
    if not isTrackedMessage(message) then
        return
    end

    appendSorryLog(source, message, context)
end

function g_game.onTextMessage(messageMode, message)
    local callbacks = messageModeCallbacks[messageMode]
    local callbackInfo = describeCallbacks(callbacks)
    local context = string.format('mode=%s %s', tostring(messageMode), callbackInfo)
    logTrackedMessage('Lua g_game.onTextMessage', message, context)

    if not callbacks or #callbacks == 0 then
        perror(string.format('Unhandled onTextMessage message mode %i: %s', messageMode, message))
        return
    end

    for _, callback in pairs(callbacks) do
        callback(messageMode, message)
    end
end

function registerMessageMode(messageMode, callback)
    if not messageModeCallbacks[messageMode] then
        messageModeCallbacks[messageMode] = {}
    end

    table.insert(messageModeCallbacks[messageMode], callback)
    return true
end

function unregisterMessageMode(messageMode, callback)
    if not messageModeCallbacks[messageMode] then
        return false
    end

    return table.removevalue(messageModeCallbacks[messageMode], callback)
end

modules = modules or {}
modules.gamelib = modules.gamelib or {}
modules.gamelib.textmessages = modules.gamelib.textmessages or {}
modules.gamelib.textmessages.logTrackedMessage = logTrackedMessage
