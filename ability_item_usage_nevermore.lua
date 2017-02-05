_G.state = "laning"

local Constant = require(GetScriptDirectory().."/dev/constant_each_side")
local DotaBotUtility = require(GetScriptDirectory().."/utility")
local para = require(GetScriptDirectory().."/SFDQN")
local DQN = require(GetScriptDirectory().."/DQN")
local ActorDQN = require(GetScriptDirectory().."/ActorDQN")
local comm_module = require(GetScriptDirectory().."/Comm/dota2comm")
ActorDQN:SetUpNetWork()

if(GetTeam() == TEAM_RADIANT) then
    comm = comm_module:new("SFradiant")
else
    comm = comm_module:new("SFdire")
end

DQN:LoadFromTable(para)
DQN:PrintValidationQ()

LastEnemyHP = 1000

EnemyTowerPosition = Vector(1024,320)
AllyTowerPosition = Vector(-1656,-1512)

LastEnemyTowerHP = 1300

LastDecesion = -1000

DeltaTime = 300 / 2

GotOrder = false

local function ClipTime(t)
    local ub = 3
    if t > ub then
        return ub
    else
        return t
    end
end

function OutputToConsole()
    local npcBot = GetBot()
    local enemyBot = GetUnitList(UNIT_LIST_ENEMY_HEROES)[1]

    if(enemyBot ~= nil) then 
        npcBot:SetTarget(enemyBot)
    end
    local enemyTower = GetTower(TEAM_DIRE,TOWER_MID_1);
    local AllyTower = GetTower(TEAM_RADIANT,TOWER_MID_1);

    if MyLastGold == nil then
        MyLastGold = npcBot:GetGold()
    end

    local GoldReward = 0

    if npcBot:GetGold() - MyLastGold > 5 then
        GoldReward = (npcBot:GetGold() - MyLastGold)
    end

    if MyLastHP == nil then
        MyLastHP = npcBot:GetHealth()
    end

    if LastEnemyHP == nil then
        LastEnemyHP = 600
    end

    if LastDistanceToEnemy == nil then
        LastDistanceToEnemy = 2000
    end

    if LastEnemyMaxHP == nil then
        LastEnemyMaxHP = 1000
    end
    
    if(enemyBot ~= nil) then 
        EnemyHP = enemyBot:GetHealth()
        EnemyMaxHP = enemyBot:GetMaxHealth()
    else
        
        EnemyHP = 600
        EnemyMaxHP = 1000
    end

    if(enemyBot ~= nil and enemyBot:CanBeSeen()) then
        DistanceToEnemy = GetUnitToUnitDistance(npcBot,enemyBot)
        if(DistanceToEnemy > 2000) then
            DistanceToEnemy = 2000
        end
    else
        DistanceToEnemy = LastDistanceToEnemy
    end

    if EnemyHP < 0 then
        EnemyHP = LastEnemyHP
        EnemyMaxHP = LastEnemyMaxHP
    end

    if AllyTowerLastHP == nil then
        AllyTowerLastHP = AllyTower:GetHealth()
    end

    if enemyTower:GetHealth() > 0 then
        EnemyTowerHP = enemyTower:GetHealth()
    else
        EnemyTowerHP = LastEnemyTowerHP
    end
    local AllyLaneFront = GetLaneFrontLocation(DotaBotUtility:GetEnemyTeam(),LANE_MID,0)
    local EnemyLaneFront = GetLaneFrontLocation(TEAM_RADIANT,LANE_MID,0)

    local DistanceToEnemyLane = GetUnitToLocationDistance(npcBot,EnemyLaneFront)
    local DistanceToAllyLane = GetUnitToLocationDistance(npcBot,AllyLaneFront)

    local DistanceToEnemyTower = GetUnitToLocationDistance(npcBot,EnemyTowerPosition)
    local DistanceToAllyTower = GetUnitToLocationDistance(npcBot,AllyTowerPosition)

    local DistanceToLane = (DistanceToEnemyLane + DistanceToAllyLane) / 2

    if LastDistanceToLane == nil then
        LastDistanceToLane = DistanceToLane
    end

    if(LastEnemyLocation == nil) then
        if(GetTeam() == TEAM_RADIANT) then
            LastEnemyLocation = Vector(6900,6650)
        else
            LastEnemyLocation = Vector(-7000,-7000)
        end
    end

    local EnemyLocation = Vector(0,0)
    if(enemyBot~=nil) then
        EnemyLocation = enemyBot:GetLocation()
    else
        EnemyLocation = LastEnemyLocation
    end
    
    local MyLocation = npcBot:GetLocation()

    local BotTeam = 0
    if(GetTeam() == TEAM_RADIANT) then
        BotTeam = 1
    else
        BotTeam = -1
    end

    local Reward = (npcBot:GetHealth() - MyLastHP)
    - (EnemyHP - LastEnemyHP)
    + (AllyTower:GetHealth() - AllyTowerLastHP)
    - (EnemyTowerHP - LastEnemyTowerHP)
    + GoldReward

    local input = {
        npcBot:GetHealth() / npcBot:GetMaxHealth(),
        npcBot:GetMana(),
        MyLocation[1],
        MyLocation[2],
        EnemyHP / EnemyMaxHP,
        EnemyLocation[1],
        EnemyLocation[2],
        EnemyLaneFront[1],
        EnemyLaneFront[2],
        AllyLaneFront[1],
        AllyLaneFront[2],
        EnemyTowerPosition[1],
        EnemyTowerPosition[2],
        AllyTowerPosition[1],
        AllyTowerPosition[2],
        ClipTime(npcBot:TimeSinceDamagedByAnyHero()),
        ClipTime(npcBot:TimeSinceDamagedByTower()),
        ClipTime(npcBot:TimeSinceDamagedByCreep()),
        AllyTower:GetHealth()/1300,
        EnemyTowerHP/1300,
        #npcBot:GetNearbyCreeps(800,false) / 10,
        #npcBot:GetNearbyCreeps(800,true) / 10,
        BotTeam
    }

    --local Q_value = DQN:ForwardProp(input)
    local zero_based = {}
    for k,v in pairs(input) do
        zero_based[k - 1] = v
    end
    --local Q_value = ActorDQN:Predict(zero_based)

    local output_str = string.format("LenLRX_log: %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %s",
        npcBot:GetHealth() / npcBot:GetMaxHealth(),
        npcBot:GetMana(),
        MyLocation[1],
        MyLocation[2],
        EnemyHP / EnemyMaxHP,
        EnemyLocation[1],
        EnemyLocation[2],
        EnemyLaneFront[1],
        EnemyLaneFront[2],
        AllyLaneFront[1],
        AllyLaneFront[2],
        EnemyTowerPosition[1],
        EnemyTowerPosition[2],
        AllyTowerPosition[1],
        AllyTowerPosition[2],
        ClipTime(npcBot:TimeSinceDamagedByAnyHero()),
        ClipTime(npcBot:TimeSinceDamagedByTower()),
        ClipTime(npcBot:TimeSinceDamagedByCreep()),
        AllyTower:GetHealth()/1300,
        EnemyTowerHP/1300,
        #npcBot:GetNearbyCreeps(800,false) / 10,
        #npcBot:GetNearbyCreeps(800,true) / 10,
        BotTeam,
        Reward,
        _G.state
    )

    print(output_str)

    comm:send(output_str)

    --[[
    local max_val = -100000
    local max_idx = -1

    for i = 0 , 2 , 1 do
        if Q_value[i] > max_val then
            max_val = Q_value[i]
            max_idx = i
        end
    end

    if true or DotaTime() - LastDecesion > DeltaTime then

        _G.LaningDesire = 0.0
        _G.AttackDesire = 0.0
        _G.RetreatDesire = 0.0

        local e = 0.0

        --  e-greedy policy
        if(math.random() < e) then
            _G.LaningDesire = math.random()
            _G.AttackDesire = math.random()
            _G.AttackDesire = math.random()
        else
            if max_idx == 0 then
                _G.LaningDesire = 1.0
            elseif max_idx == 1 then
                _G.AttackDesire = 1.0
            elseif max_idx == 2 then
                _G.RetreatDesire = 1.0
            end
        end

        LastDecesion = DotaTime()
    end
    

    if true then
    print("Q_Values",
    Q_value[0],
    Q_value[1],
    Q_value[2],
    "max_idx:",
    max_idx
    )
    end
    ]]


    if enemyTower:GetHealth() > 0 then
        LastEnemyTowerHP = enemyTower:GetHealth()
    end

    MyLastHP = npcBot:GetHealth()
    AllyTowerLastHP = AllyTower:GetHealth()
    LastEnemyHP = EnemyHP
    LastEnemyMaxHP = EnemyMaxHP
    MyLastGold = npcBot:GetGold()
    LastDistanceToLane = DistanceToLane
    LastDistanceToEnemy = DistanceToEnemy
    LastEnemyLocation = EnemyLocation
end

LastTimeOutput = DotaTime()

function ApplyOrder(s)
    local action = tonumber(s)
    _G.LaningDesire = 0.0
    _G.AttackDesire = 0.0
    _G.RetreatDesire = 0.0
    if action == 0 then
        _G.LaningDesire = 1.0
    elseif action == 1 then
        _G.AttackDesire = 1.0
    elseif action == 2 then
        _G.RetreatDesire = 1.0
    end
    print("Apply Order",s)
end


function BuybackUsageThink()
    if (GetGameState() == GAME_STATE_GAME_IN_PROGRESS or GetGameState() == GAME_STATE_PRE_GAME) then
        --print(math.abs(DotaTime() - LastTimeOutput))
        if math.abs(DotaTime() - LastTimeOutput) > 1 then
            OutputToConsole()
            LastTimeOutput = DotaTime()
        end
    end

    local msg = comm:receive()
    if msg then
        ApplyOrder(msg)
    end
end

print("init done")