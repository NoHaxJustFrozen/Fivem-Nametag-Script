local QBCore = exports['qb-core']:GetCoreObject()
local pendingIstekler = {}

local function getIdentifier(src)
    for _,v in ipairs(GetPlayerIdentifiers(src)) do
        if v:find("license:") then return v end
    end
    return false
end

local function sendTanidikUpdate(src)
    local identifier = getIdentifier(src)
    exports.oxmysql:execute('SELECT * FROM tanidiklar WHERE license1 = ? OR license2 = ?', {identifier, identifier}, function(rows)
        local tanidiklarList, adlar, idMap = {}, {}, {}
        for _, row in ipairs(rows) do
            local other, otherName
            if row.license1 == identifier then
                other = row.license2
                otherName = row.isim2
            else
                other = row.license1
                otherName = row.isim1
            end
            for _, pid in ipairs(GetPlayers()) do
                local pident = getIdentifier(tonumber(pid))
                if pident == other then
                    local serverid = tonumber(pid)
                    tanidiklarList[serverid] = true
                    adlar[serverid] = otherName or "Tanıdık"
                    idMap[serverid] = other
                end
            end
        end
        TriggerClientEvent('xavi-tag:taniupdate', src, tanidiklarList, adlar, idMap)
    end)
end

AddEventHandler("playerDropped", function()
    local src = source
    pendingIstekler[src] = nil
end)

RegisterNetEvent("xavi-tag:playerLoaded", function()
    local src = source
    sendTanidikUpdate(src)
end)

RegisterNetEvent("xavi-tag:tanistek", function(target, ad)
    local src = source
    if not pendingIstekler[target] then
        pendingIstekler[target] = {src = src, ad = ad}
        TriggerClientEvent("xavi-tag:istekalindi", target, {src=src, ad=ad})
    end
end)

RegisterNetEvent("xavi-tag:tanikabul", function(myAd)
    local src = source
    local istek = pendingIstekler[src]
    if not istek then return end
    local other = istek.src
    local otherAd = istek.ad

    local myIdent = getIdentifier(src)
    local otherIdent = getIdentifier(other)
    if not myIdent or not otherIdent then return end

    -- TANIDIK KAYIT!
    exports.oxmysql:execute("INSERT INTO tanidiklar (license1, isim1, license2, isim2) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE isim1 = VALUES(isim1), isim2 = VALUES(isim2)", {
        myIdent, myAd, otherIdent, otherAd
    }, function()
        sendTanidikUpdate(src)
        sendTanidikUpdate(other)
        -- TANITANINCA ANİMASYON YOLLA
        TriggerClientEvent("xavi-tag:broemote", src, other)
        TriggerClientEvent("xavi-tag:broemote", other, src)
    end)
    pendingIstekler[src] = nil
end)

RegisterNetEvent("xavi-tag:tanireddet", function(src2)
    local src = source
    pendingIstekler[src] = nil
end)

RegisterNetEvent("xavi-tag:unut", function(otherId)
    local src = source
    local myIdent = getIdentifier(src)
    local otherIdent = nil

    for _,v in ipairs(GetPlayerIdentifiers(tonumber(otherId))) do
        if v:find("license:") then
            otherIdent = v
            break
        end
    end
    if not otherIdent then
        -- oyuncu online değilse SQL'den çek
        exports.oxmysql:execute('SELECT license1, license2 FROM tanidiklar WHERE (license1 = ? AND license2 = ?) OR (license1 = ? AND license2 = ?)', {myIdent, otherIdent, otherIdent, myIdent}, function(rows)
            if rows[1] then
                exports.oxmysql:execute('DELETE FROM tanidiklar WHERE (license1 = ? AND license2 = ?) OR (license1 = ? AND license2 = ?)', {myIdent, otherIdent, otherIdent, myIdent})
            end
        end)
        return
    end
    exports.oxmysql:execute('DELETE FROM tanidiklar WHERE (license1 = ? AND license2 = ?) OR (license1 = ? AND license2 = ?)', {myIdent, otherIdent, otherIdent, myIdent}, function()
        sendTanidikUpdate(src)
        sendTanidikUpdate(tonumber(otherId))
    end)
end)
