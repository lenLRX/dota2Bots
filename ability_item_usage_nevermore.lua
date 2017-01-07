_G.state = "laning"

local Constant = require(GetScriptDirectory().."/dev/constant_each_side")
local DotaBotUtility = require(GetScriptDirectory().."/utility")
local DQN = require(GetScriptDirectory().."/DQN")

LastEnemyHP = 1000

LastEnemyTowerHP = 1300

function OutputToConsole()
    local npcBot = GetBot()
    local EnemyBots = DotaBotUtility:GetEnemyBots();
    local enemyBot = GetTeamMember(TEAM_DIRE,1);

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
        GoldReward = (npcBot:GetGold() - MyLastGold) / 100
    end

    if MyLastHP == nil then
        MyLastHP = npcBot:GetHealth()
    end

    

    if LastEnemyHP == nil then
        LastEnemyHP = 600
    end

    if LastEnemyMaxHP == nil then
        LastEnemyMaxHP = 600
    end
    
    if(enemyBot ~= nil) then 
        EnemyHP = enemyBot:GetHealth()
        EnemyMaxHP = enemyBot:GetMaxHealth()
    else
        EnemyHP = 600
        EnemyMaxHP = 600
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

    local DistanceToLane = GetUnitToLocationDistance(npcBot,AllyLaneFront + EnemyLaneFront) / 2 / (7000 * 1.414)

    local Reward = (npcBot:GetHealth() - MyLastHP) 
    - (EnemyHP - LastEnemyHP)
    + (AllyTower:GetHealth() - AllyTowerLastHP)
    - (EnemyTowerHP - LastEnemyTowerHP)
    - DistanceToLane
    + GoldReward

    local input = {
        npcBot:GetHealth() / npcBot:GetMaxHealth(),
        EnemyHP / EnemyMaxHP,
        DistanceToLane,
        AllyTower:GetHealth()/1300,
        enemyTower:GetHealth()/1300,
        #npcBot:GetNearbyTowers(800,false) / 10,
        #npcBot:GetNearbyCreeps(800,true) / 10
    }

    local Q_value = DQN:ForwardProp(input)

    print("LenLRX log: ",
        npcBot:GetHealth() / npcBot:GetMaxHealth(),
        EnemyHP / EnemyMaxHP,
        DistanceToLane,
        AllyTower:GetHealth()/1300,
        enemyTower:GetHealth()/1300,
        #npcBot:GetNearbyTowers(800,false) / 10,
        #npcBot:GetNearbyCreeps(800,true) / 10,
        Reward,
        _G.state
    )

    --[[
    print("Q_Values",
    Q_value[0],
    Q_value[1],
    Q_value[2]
    )
    ]]
    

    local sum = Q_value[0] + Q_value[1] + Q_value[2]

    _G.LaningDesire = Q_value[0] / sum
    _G.AttackDesire = Q_value[1] / sum
    _G.RetreatDesire = Q_value[2] / sum


    if enemyTower:GetHealth() > 0 then
        LastEnemyTowerHP = enemyTower:GetHealth()
    end

    MyLastHP = npcBot:GetHealth()
    AllyTowerLastHP = AllyTower:GetHealth()
    LastEnemyHP = EnemyHP
    LastEnemyMaxHP = EnemyMaxHP
    MyLastGold = npcBot:GetGold()
end


function BuybackUsageThink()
    if ( GetTeam() == TEAM_RADIANT ) then
        OutputToConsole()
    end
end