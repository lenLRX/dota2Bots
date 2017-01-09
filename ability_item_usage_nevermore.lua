_G.state = "laning"

local Constant = require(GetScriptDirectory().."/dev/constant_each_side")
local DotaBotUtility = require(GetScriptDirectory().."/utility")
local para = require(GetScriptDirectory().."/SFDQN")
local DQN = require(GetScriptDirectory().."/DQN")

DQN:LoadFromTable(para)
DQN:PrintValidationQ()

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
        GoldReward = (npcBot:GetGold() - MyLastGold)
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

    local DistanceToLane = GetUnitToLocationDistance(npcBot,AllyLaneFront) * 2

    if LastDistanceToLane == nil then
        LastDistanceToLane = DistanceToLane
    end

    local Reward = (npcBot:GetHealth() - MyLastHP) * 10 
    - (EnemyHP - LastEnemyHP) * 10
    + (AllyTower:GetHealth() - AllyTowerLastHP) * 10
    - (EnemyTowerHP - LastEnemyTowerHP) * 10
    + (LastDistanceToLane - DistanceToLane)
    + GoldReward

    print(GoldReward)

    local input = {
        npcBot:GetHealth() / npcBot:GetMaxHealth(),
        EnemyHP / EnemyMaxHP,
        DistanceToLane,
        AllyTower:GetHealth()/1300,
        EnemyTowerHP/1300,
        #npcBot:GetNearbyTowers(800,false) / 10,
        #npcBot:GetNearbyCreeps(800,true) / 10
    }

    local Q_value = DQN:ForwardProp(input)

    print("LenLRX log: ",
        npcBot:GetHealth() / npcBot:GetMaxHealth(),
        EnemyHP / EnemyMaxHP,
        DistanceToLane,
        AllyTower:GetHealth()/1300,
        EnemyTowerHP/1300,
        #npcBot:GetNearbyTowers(800,false) / 10,
        #npcBot:GetNearbyCreeps(800,true) / 10,
        Reward,
        _G.state
    )

    
    local max_val = -100000
    local max_idx = -1

    for i = 0 , 2 , 1 do
        if Q_value[i] > max_val then
            max_val = Q_value[i]
            max_idx = i
        end
    end

    _G.LaningDesire = 0.0
    _G.AttackDesire = 0.0
    _G.RetreatDesire = 0.0

    if max_idx == 0 then
        _G.LaningDesire = 1.0
    elseif max_idx == 1 then
        _G.AttackDesire = 1.0
    elseif max_idx == 2 then
        _G.RetreatDesire = 1.0
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



    if enemyTower:GetHealth() > 0 then
        LastEnemyTowerHP = enemyTower:GetHealth()
    end

    MyLastHP = npcBot:GetHealth()
    AllyTowerLastHP = AllyTower:GetHealth()
    LastEnemyHP = EnemyHP
    LastEnemyMaxHP = EnemyMaxHP
    MyLastGold = npcBot:GetGold()
    LastDistanceToLane = DistanceToLane
end

if ( GetTeam() == TEAM_RADIANT ) then
    LastTime = DotaTime()
end


function BuybackUsageThink()
    if ( GetTeam() == TEAM_RADIANT ) then
        if true or DotaTime() - LastTime > 1 then
            OutputToConsole()
            LastTime = DotaTime()
        end
    end
end