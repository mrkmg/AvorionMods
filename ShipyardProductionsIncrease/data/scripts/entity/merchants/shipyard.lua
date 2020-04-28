function Shipyard.startServerJob(singleBlock, founder, captain, styleName, seed, volume, scale, material, name)

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources, AlliancePrivilege.FoundShips)
    if not buyer then return end

    local stationFaction = Faction()
    local station = Entity()

    -- shipyard may only have x jobs
    if tablelength(runningJobs) >= 20 then
        player:sendChatMessage(station, 1, "The shipyard is already at maximum capacity."%_t)
        return 1
    end

    local settings = GameSettings()
    if settings.maximumPlayerShips > 0 and buyer.numShips >= settings.maximumPlayerShips then
        player:sendChatMessage("", 1, "Maximum ship limit per faction (%s) of this server reached!"%_t, settings.maximumPlayerShips)
        return
    end

    -- check if the player can afford the ship
    -- first create the plan
    local plan = BlockPlan()

    if singleBlock then
        if anynils(material) then
            return
        end

        plan:addBlock(vec3(0, 0, 0), vec3(2, 2, 2), -1, -1, ColorRGB(1, 1, 1), Material(material), Matrix(), BlockType.Hull)
    else
        if anynils(styleName, seed, volume) then return end

        local style = stationFaction:getPlanStyle(styleName)
        if not style then return end

        plan = GeneratePlanFromStyle(style, Seed(seed), volume, 2000, 1, Material(material))
    end

    if anynils(scale, name) then return end

    plan:scale(vec3(scale, scale, scale))

    -- get the money required for the plan
    local requiredMoney, fee = Shipyard.getRequiredMoney(plan, buyer)
    local requiredResources = Shipyard.getRequiredResources(plan, buyer)

    if captain > 0 then
        if captain == 2 then
            if stationFaction:getRelations(buyer.index) < 30000 then
                local name = "Good"%_t
                player:sendChatMessage(station.title, ChatMessageType.Error, "You need relations of at least '%s' with this faction to include a captain with the ship."%_t, name)
                return
            end
        end

        requiredMoney = requiredMoney + Shipyard.getCrewMoney(plan, captain == 2)
    end

    -- check if the player has enough money & resources
    local canPay, msg, args = buyer:canPay(requiredMoney, unpack(requiredResources))
    if not canPay then -- if there was an error, print it
        player:sendChatMessage(station, 1, msg, unpack(args))
        return;
    end

    receiveTransactionTax(station, fee)

    -- let the player pay
    buyer:pay(requiredMoney, unpack(requiredResources))

    -- relations of the player to the faction owning the shipyard get better
    local relationsChange = GetRelationChangeFromMoney(requiredMoney)
    for i, v in pairs(requiredResources) do
        relationsChange = relationsChange + v / 4
    end

    changeRelations(buyer, stationFaction, relationsChange, RelationChangeType.ServiceUsage)

    -- register the ship in the player's database
    -- The ship might get renamed in order to keep consistency in the database
    local cx, cy = Sector():getCoordinates()

    -- start the job
    local requiredTime = (math.floor(20.0) + plan.durability / 100.0)

    if captain > 0 then
        requiredTime = requiredTime + 300
    end

    if buyer.infiniteResources then
        requiredTime = 1.0
    end

    local job = {}
    job.executed = 0
    job.duration = requiredTime
    job.shipOwner = buyer.index
    job.styleName = styleName
    job.seed = seed
    job.scale = scale
    job.volume = volume
    job.material = material
    job.shipName = name
    job.singleBlock = singleBlock
    job.founder = founder
    job.captain = captain

    table.insert(runningJobs, job)

    local args = createReadableTimeTable(requiredTime)
    if args.hours > 0 then
        if args.hours == 1 then
            player:sendChatMessage(station, 0, "Thank you for your purchase. Your ship will be ready in about an hour and %2% minutes."%_T, args.hours, args.minutes)
        else
            player:sendChatMessage(station, 0, "Thank you for your purchase. Your ship will be ready in about %1% hours and %2% minutes."%_T, args.hours, args.minutes)
        end
    elseif args.minutes > 0 then
        if args.minutes > 2 then
            player:sendChatMessage(station, 0, "Thank you for your purchase. Your ship will be ready in about %1% minutes."%_T, args.minutes, args.seconds)
        else
            player:sendChatMessage(station, 0, "Thank you for your purchase. Your ship will be ready in about two minutes."%_T, args.minutes, args.seconds)
        end
    end

    -- tell all clients in the sector that production begins
    broadcastInvokeClientFunction("startClientJob", 0, requiredTime)

    -- this sends an ack to the client and makes it close the window
    invokeClientFunction(player, "transactionComplete")
end
callable(Shipyard, "startServerJob")