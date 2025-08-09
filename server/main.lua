local QBCore = exports['qb-core']:GetCoreObject()

local discordWebhook = "#WEBHOOK"

local bansFile = "bans.json"

local function loadBans()
    local file = io.open(bansFile, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local success, bans = pcall(json.decode, content)
        return success and bans or {}
    end
    return {}
end

local function saveBans(bans)
    local file = io.open(bansFile, "w")
    if file then
        file:write(json.encode(bans, {indent = true}))
        file:close()
        return true
    end
    return false
end

function enumerateIdentifiers(source)
    local identifiers = {
        steam = "",
        ip = "",
        discord = "",
        fivem = "",
        license = "",
        xbl = "",
        live = ""
    }

    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        
        for key, value in pairs(identifiers) do
            if string.match(id, key) then
                identifiers[key] = id
                break
            end
        end
    end

    return identifiers
end

local function sendDiscordLog(playerName, reason, identifiers)
    local embed = {
        {
            ["title"] = "🔨 Spelare kickad för DevTools",
            ["description"] = string.format("**Spelare:** %s\n**Anledning:** %s\n**Bannad av:** Moderator", playerName, reason),
            ["color"] = 16711680, -- Röd färg
            ["fields"] = {
                {
                    ["name"] = "Identifierare",
                    ["value"] = string.format("**License:** %s\n**Discord:** %s\n**Steam:** %s\n**IP:** %s", 
                        identifiers.license or "N/A",
                        identifiers.discord or "N/A", 
                        identifiers.steam or "N/A",
                        identifiers.ip or "N/A"),
                    ["inline"] = false
                }
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(discordWebhook, function(err, text, headers) end, 'POST', json.encode({embeds = embed}), {['Content-Type'] = 'application/json'})
end

local function exploitBan(id, reason)
    local playerName = GetPlayerName(id)
    local identifiers = enumerateIdentifiers(id)
    local banReason = reason or 'NuiDevTool Abuse'
    
    -- Läs nuvarande bans
    local bans = loadBans()
    
    -- Lägg till ny ban
    local newBan = {
        name = playerName,
        license = identifiers.license,
        discord = identifiers.discord,
        steam = identifiers.steam,
        ip = identifiers.ip,
        reason = banReason,
        expire = 2147483647, -- Permanent ban
        bannedby = 'NewLife AntiDT',
        timestamp = os.time(),
        date = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    table.insert(bans, newBan)
    
    if saveBans(bans) then
        print("Ban sparad till JSON: " .. playerName)
    else
        print("Fel vid sparning av ban till JSON")
    end
    
    sendDiscordLog(playerName, banReason, identifiers)
    
    TriggerEvent('qb-log:server:CreateLog', 'snd', 'Spelare kickad', 'red',
        string.format('%s blev kickad av %s för %s', playerName, 'Moderator', banReason), true)
    
    -- Kicka spelaren
    DropPlayer(id, 'Moget beteende, skapa en ticket för att överklaga! DevTools ')
end

RegisterServerEvent(GetCurrentResourceName())
AddEventHandler(GetCurrentResourceName(), function()
    local src = source
    local identifier = enumerateIdentifiers(source)
    local identifierLicense = identifier.license
    local identifierDiscord = identifier.discord
    if permType == 'license' then
        local isInPermissions = false
        
        for _, v in pairs(permissions) do
            if v == identifierLicense then
             isInPermissions = true
                break
            end
        end
        
        if not isInPermissions then
            exploitBan(src)
        end
    elseif permType == 'discord' then
        local isInPermissions = false
    
        for _, v in pairs(permissions) do
            if v == identifierDiscord then
             isInPermissions = true
                break
            end
        end
    
        if not isInPermissions then
            exploitBan(src)
        end
    --[[ elseif checkmethod == 'Add New Method' then
        local isInPermissions = false
    
        for _, v in pairs(allowlist) do
            if v == identifierNewMethod then
             isInPermissions = true
                break
            end
        end
    
        if not isInPermissions then
            exploitBan(src)
        end ]]
    else
        -- Handle other check methods or provide an error message
        print("Invalid check method specified.")
    end
end)

