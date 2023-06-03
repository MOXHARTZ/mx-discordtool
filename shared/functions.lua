local function unpackStr(...)
    local str = ''
    for _, v in ipairs({ ... }) do
        str = str .. v .. ' '
    end
    return str
end

function Debug(...)
    if not config.debug then return end
    local message = '^5DEBUG^0 '
    local str = unpackStr(...)
    print(message .. '^4' .. str .. '^0')
end

function Warn(...)
    if not config.warning then return end
    local message = '^8WARNING^0 '
    local str = unpackStr(...)
    print(message .. '^4' .. str .. '^0')
end
