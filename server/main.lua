local QBCore = exports['qbx-core']:GetCoreObject()

-- Helpers

local function hasValue(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

-- Functions

local function getClosestHall(pedCoords)
    local distance = #(pedCoords - Config.Cityhalls[1].coords)
    local closest = 1
    for i = 1, #Config.Cityhalls do
        local hall = Config.Cityhalls[i]
        local dist = #(pedCoords - hall.coords)
        if dist < distance then
            distance = dist
            closest = i
        end
    end
    return closest
end

local function getClosestSchool(pedCoords)
    local distance = #(pedCoords - Config.DrivingSchools[1].coords)
    local closest = 1
    for i = 1, #Config.DrivingSchools do
        local school = Config.DrivingSchools[i]
        local dist = #(pedCoords - school.coords)
        if dist < distance then
            distance = dist
            closest = i
        end
    end
    return closest
end

-- Events

RegisterNetEvent('qb-cityhall:server:requestId', function(item, hall)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local itemInfo = Config.Cityhalls[hall].licenses[item]
    if not Player.Functions.RemoveMoney("cash", itemInfo.cost) then
        return TriggerClientEvent('ox_lib:notify', source,
            { description = ('You don\'t have enough money on you, you need %s cash'):format(itemInfo.cost),
                type = 'error' })
    end

    TriggerEvent('qb-cityhall:server:RequestDocument', source, item, 1)
    TriggerClientEvent('ox_lib:notify', source,
        { description = ('You have received your %s for $%s'):format(QBCore.Shared.Items[item].label, itemInfo.cost),
            type = 'success' })
end)

RegisterNetEvent('qb-cityhall:server:sendDriverTest', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local ped = GetPlayerPed(source)
    local pedCoords = GetEntityCoords(ped)
    local closestDrivingSchool = getClosestSchool(pedCoords)
    local instructors = Config.DrivingSchools[closestDrivingSchool].instructors
    for i = 1, #instructors do
        local citizenid = instructors[i]
        local SchoolPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
        if SchoolPlayer then
            TriggerClientEvent("qb-cityhall:client:sendDriverEmail", SchoolPlayer.PlayerData.source, Player.PlayerData.charinfo)
        else
            local mailData = {
                sender = "Township",
                subject = "Driving lessons request",
                message = "Hello,<br><br>We have just received a message that someone wants to take driving lessons.<br>If you are willing to teach, please contact them:<br>Name: <strong>".. Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. "<br />Phone Number: <strong>"..Player.PlayerData.charinfo.phone.."</strong><br><br>Kind regards,<br>Township Los Santos",
                button = {}
            }
            TriggerEvent("qb-phone:server:sendNewMailToOffline", citizenid, mailData)
        end
    end
    TriggerClientEvent('ox_lib:notify', source,
        { description = "An email has been sent to driving schools, and you will be contacted automatically",
            type = 'success' })
end)

RegisterNetEvent('qb-cityhall:server:ApplyJob', function(job)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local ped = GetPlayerPed(source)
    local pedCoords = GetEntityCoords(ped)
    local closestCityhall = getClosestHall(pedCoords)
    local closestCityhallInfo = Config.Cityhalls[closestCityhall]
    local cityhallCoords = closestCityhallInfo.coords
    local JobInfo = QBCore.Shared.Jobs[job]
    if #(pedCoords - cityhallCoords) >= 20.0 or not closestCityhallInfo.availableJobs[job] then
        return DropPlayer(source, "Attempted exploit abuse")
    end
    Player.Functions.SetJob(job, 0)
    TriggerClientEvent('ox_lib:notify', source, { description = Lang:t('info.new_job', {job = JobInfo.label}), type = 'success' })
end)

RegisterNetEvent('qb-cityhall:server:RequestDocument', function(source, type, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    local metadata = {
        CID = Player.PlayerData.citizenid,
        FN = Player.PlayerData.charinfo.firstname,
        LN = Player.PlayerData.charinfo.lastname,
        DOB = Player.PlayerData.charinfo.birthdate,
        SEX = Player.PlayerData.charinfo.gender == 0 and 'M' or 'F'
    }

    if type == 'driver_license' then
        local licences = ""
        for _, value in pairs(Player.PlayerData.metadata['licences']['driver']) do
            licences = licences .. value .. " "
        end
        metadata['type'] = licences
    else
        metadata['type'] = string.format('%s %s', Player.PlayerData.charinfo.firstname,
            Player.PlayerData.charinfo.lastname)
    end

    if metadata['type'] then
        exports.ox_inventory:AddItem(source, type, amount, metadata)
        return true
    else
        return false
    end
end)

-- Commands

lib.addCommand('check-driver-licences', {
    help = 'Check someone licenses',
    params = {
        { name = 'target', help = "ID of a person", type = 'playerId' },
    }
}, function (source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    local SearchedPlayer = QBCore.Functions.GetPlayer(args.target)

    for i = 1, #Config.DrivingSchools do
        for id = 1, #Config.DrivingSchools[i].instructors do
            if Config.DrivingSchools[i].instructors[id] == Player.PlayerData.citizenid then
                local licences = ""
                for _, value in pairs(SearchedPlayer.PlayerData.metadata['licences']['driver']) do
                    licences = licences .. value .. " "
                end
            end
        end
    end
end)

lib.addCommand('give-driver-licence', {
    help = 'Give a drivers license to someone',
    params = {
        { name = 'target', help = "ID of a person", type = 'playerId' },
        { name = 'cat', help = "Category of license A/B/C/D", type = 'string'}
    }
}, function(source, args)
    if not args.target then
        return TriggerClientEvent('ox_lib:notify', source,
            { description = "Player Not Online", type = 'error' }) end

    if not args.cat or not hasValue({'A', 'B', 'C', 'D'}, args.cat) then
        return TriggerClientEvent('ox_lib:notify', source, { description = "Invalid Category", type = 'error' })
    end

    local Player = QBCore.Functions.GetPlayer(source)
    local SearchedPlayer = QBCore.Functions.GetPlayer(args.target)

    if SearchedPlayer then
        if not SearchedPlayer.PlayerData.metadata["licences"]["driver"] then
            SearchedPlayer.PlayerData.metadata["licences"]["driver"] = {}
        end

        for i = 1, #Config.DrivingSchools do
            for id = 1, #Config.DrivingSchools[i].instructors do
                if Config.DrivingSchools[i].instructors[id] == Player.PlayerData.citizenid then
                    if not hasValue(SearchedPlayer.PlayerData.metadata["licences"]["driver"], args.cat) then
                        SearchedPlayer.PlayerData.metadata["licences"]["driver"]
                        [#SearchedPlayer.PlayerData.metadata["licences"]["driver"] + 1] = args.cat
                        SearchedPlayer.Functions.SetMetaData("licences", SearchedPlayer.PlayerData.metadata["licences"])
                        TriggerClientEvent('ox_lib:notify', SearchedPlayer.PlayerData.source, { description = "You have passed! Pick up your drivers license at the town hall", type = 'success' })
                        TriggerClientEvent('ox_lib:notify', source, { description = ("Player with ID %s has been granted access to a driving license"):format(SearchedPlayer.PlayerData.source), type = 'success' })
                    else
                        TriggerClientEvent('ox_lib:notify', source, { description = "Can't give permission for a drivers license, this person already has permission", type = 'error' })
                    end

                    break
                end
            end
        end
    else
        TriggerClientEvent('ox_lib:notify', source, { description = "Player Not Online", type = 'error' })
    end
end)
