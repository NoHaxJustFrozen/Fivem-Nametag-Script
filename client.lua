local QBCore = exports['qb-core']:GetCoreObject()
local playerName = "Unknown"
local tanistiklarim = {}
local karakterler = {}
local idMap = {}
local pendingIstek = nil
local MESAFE_LIMITI = 8.0
local hudAcik = true

local maskCache = {}

function UpdateAllMaskStates()
    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        maskCache[player] = false
        local appearance = exports['illenium-appearance']:getPedAppearance(ped)
        if appearance and appearance.components then
            for _, comp in ipairs(appearance.components) do
                if comp.component_id == 1 and comp.drawable ~= 0 then
                    maskCache[player] = true
                    break
                end
            end
        end
    end
end

Citizen.CreateThread(function()
    while true do
        UpdateAllMaskStates()
        Citizen.Wait(800) -- 0.8sn'de bir maskeyi güncelle, daha bile arttırabilirsin
    end
end)

function IsPlayerMaskedCached(player)
    return maskCache[player] or false
end

TriggerEvent('chat:addSuggestion', '/tanış', 'Bir oyuncuya tanışma isteği gönder. Kullanım: /tanış [id]', {
    { name = "id", help = "Tanışma isteği atacağın kişinin sunucu idsi" }
})
TriggerEvent('chat:addSuggestion', '/tanış-kabul', 'Gelen tanışma isteğini kabul et.')
TriggerEvent('chat:addSuggestion', '/tanış-reddet', 'Gelen tanışma isteğini reddet.')
TriggerEvent('chat:addSuggestion', '/tanıdıklar', 'Tanışık olduğun kişileri menüden görüntüle ve unut.')
TriggerEvent('chat:addSuggestion', '/unut', 'Bir tanışıklığı sil. Kullanım: /unut [id]', {
    { name = "id", help = "Tanışıklığı silmek istediğin kişinin sunucu idsi" }
})

RegisterCommand("nametag", function()
    hudAcik = not hudAcik
    local durum = hudAcik and "^2açık^7" or "^1kapalı^7"
    TriggerEvent("chat:addMessage", {args = {"", "Nametag artık "..durum.."!"}})
end)

function UpdatePlayerName()
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.charinfo and playerData.charinfo.firstname then
        playerName = (playerData.charinfo.firstname or "") .. " " .. (playerData.charinfo.lastname or "")
    end
end

Citizen.CreateThread(function()
    while QBCore.Functions.GetPlayerData().charinfo == nil do Citizen.Wait(200) end
    UpdatePlayerName()
    TriggerServerEvent('xavi-tag:playerLoaded')
end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    UpdatePlayerName()
    TriggerServerEvent('xavi-tag:playerLoaded')
end)

RegisterNetEvent('xavi-tag:taniupdate', function(yeni, adlar, map)
    tanistiklarim = yeni or {}
    karakterler = adlar or {}
    idMap = map or {}
end)

RegisterNetEvent('xavi-tag:istekalindi', function(src, ad)
    pendingIstek = {src=src, ad=ad}
    exports.ox_lib:showContext("xavi-tag_tanistek")
end)

RegisterCommand("tanış", function(_, args)
    local id = tonumber(args[1])
    if not id then
        exports.ox_lib:registerContext({
            id = 'xavi-tag_tanışinfo',
            title = "Tanışma İsteği",
            description = "Bir oyuncuya tanışma isteği göndermek için: /tanış [id]\n\nDiğer komutlar:\n/tanış-kabul → Gelen isteği kabul et\n/tanış-reddet → Reddet\n/tanıdıklar → Menüyü aç\n/unut [id] → Tanışıklığı sil",
            options = { { title = "Kapat", onSelect = function() end } }
        })
        exports.ox_lib:showContext("xavi-tag_tanışinfo")
        return
    end
    if id ~= GetPlayerServerId(PlayerId()) then
        TriggerServerEvent('xavi-tag:tanistek', id, playerName)
        TriggerEvent("chat:addMessage", {args = {"Nametag", "Tanışma isteği yollandı."}})
    end
end)

RegisterCommand("tanıdıklar", function()
    local options = {}
    for id, _ in pairs(tanistiklarim) do
        if karakterler[id] then
            table.insert(options, {
                title = ("%s (%s)"):format(karakterler[id], id),
                description = "Unutmak için tıkla",
                onSelect = function()
                    TriggerServerEvent('xavi-tag:unut', id)
                end
            })
        end
    end
    if #options == 0 then
        table.insert(options, { title = "Tanışıklık yok.", description = "" })
    end
    exports.ox_lib:registerContext({
        id = 'xavi-tag_tanışıklar',
        title = "Tanıdıklarım",
        options = options
    })
    exports.ox_lib:showContext("xavi-tag_tanışıklar")
end)

RegisterCommand("tanış-reddet", function()
    if pendingIstek then
        TriggerServerEvent('xavi-tag:tanireddet', pendingIstek.src)
        pendingIstek = nil
        TriggerEvent("chat:addMessage", {args = {"Nametag", "Tanışma isteğini reddettin."}})
    end
end)
RegisterCommand("tanış-kabul", function()
    if pendingIstek then
        TriggerServerEvent('xavi-tag:tanikabul', playerName)
        pendingIstek = nil
        TriggerEvent("chat:addMessage", {args = {"Nametag", "Tanışma isteğini kabul ettin."}})
    end
end)
RegisterCommand("unut", function(_, args)
    local id = tonumber(args[1])
    if id then
        TriggerServerEvent('xavi-tag:unut', id)
        TriggerEvent("chat:addMessage", {args = {"Nametag", "Artık bu kişiyi unuttun."}})
    end
end)

exports.ox_lib:registerContext({
    id = "xavi-tag_tanistek",
    title = "Tanışma İsteği Geldi",
    options = {
        { title = "Kabul Et", onSelect = function()
            if pendingIstek then
                TriggerServerEvent('xavi-tag:tanikabul', playerName)
                pendingIstek = nil
                TriggerEvent("chat:addMessage", {args = {"Nametag", "Tanışma isteğini kabul ettin."}})
            end
        end },
        { title = "Reddet", onSelect = function()
            if pendingIstek then
                TriggerServerEvent('xavi-tag:tanireddet', pendingIstek.src)
                pendingIstek = nil
                TriggerEvent("chat:addMessage", {args = {"Nametag", "Tanışma isteğini reddettin."}})
            end
        end }
    }
})

RegisterNetEvent("xavi-tag:broemote", function(otherSrc)
    local ped = PlayerPedId()
    RequestAnimDict("mp_ped_interaction")
    while not HasAnimDictLoaded("mp_ped_interaction") do
        Wait(10)
    end
    TaskPlayAnim(ped, "mp_ped_interaction", "hugs_guy_a", 8.0, -8.0, 2500, 48, 0, false, false, false)
end)

function DrawCustomText(text, x, y, z, renk, scale, font)
    SetTextFont(font or 4)
    SetTextProportional(1)
    SetTextScale(0.0, scale)
    SetTextColour(renk[1], renk[2], renk[3], renk[4])
    SetTextDropshadow(2, 0, 0, 0, 220)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextCentre(true)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if not hudAcik then goto devam end

        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)

        for _, player in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(player)
            local id = GetPlayerServerId(player)
            local dist = #(GetEntityCoords(ped) - myCoords)
            if not IsPedDeadOrDying(ped, true) and dist < MESAFE_LIMITI then
                local tag, renk

                if player == PlayerId() then
                    tag = ("%s (%s)"):format(playerName, id)
                    renk = {255,255,255,255}
                elseif tanistiklarim[id] and karakterler[id] then
                    tag = ("%s (%s)"):format(karakterler[id], id)
                    renk = {255,255,255,255}
                else
                    tag = "Bilinmeyen Kişi ("..id..")"
                    renk = {255,255,255,200}
                end

                if IsPlayerMaskedCached(player) then
                    tag = ("Maskeli (%s)"):format(id)
                    renk = {255,0,0,255}
                end

                local coords = GetPedBoneCoords(ped, 0x796e)
                DrawCustomText(tag, coords.x, coords.y, coords.z + 0.27, renk, 0.42, 4)
                if IsPedInAnyVehicle(ped, false) then
                    DrawCustomText("Araçta", coords.x, coords.y, coords.z + 0.22, {255, 221, 51, 230}, 0.33, 4)
                end
            end
        end
        ::devam::
    end
end)
