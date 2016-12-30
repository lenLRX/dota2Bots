--[[
    StateMachine is a table
    the key "STATE" stores the STATE of Lina 
    other key value pairs: key is the string of state value is the function of the State. 

    each frame DOTA2 will call Think()
    Then Think() will call the function of current state.
]]

local Constant = require(GetScriptDirectory().."/dev/constant_each_side");
local DotaBotUtility = require(GetScriptDirectory().."/utility");

local STATE_IDLE = "STATE_IDLE";
local STATE_ATTACKING_CREEP = "STATE_ATTACKING_CREEP";
local STATE_KILL = "STATE_KILL";
local STATE_RETREAT = "STATE_RETREAT";
local STATE_FARMING = "STATE_FARMING";
local STATE_GOTO_COMFORT_POINT = "STATE_GOTO_COMFORT_POINT";
local STATE_FIGHTING = "STATE_FIGHTING";
local STATE_RUN_AWAY = "STATE_RUN_AWAY";
local STATE_TEAM_FIGHTING = "STATE_TEAM_FIGHTING";

local TimberSawRetreatHPThreshold = 0.3;
local TimberSawRetreatMPThreshold = 0.2;

local STATE = STATE_IDLE;

LANE = LANE_TOP;

local function TimberSawIsBusy()
    local npcBot = GetBot();

    local busy = npcBot:IsUsingAbility() or npcBot:IsChanneling() or npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_USE_ABILITY;

    return busy;
end

local function CanCastOnTarget( npcTarget )
	return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable();
end

local function IsInTeamFight()
    return false;
end

local function GetTRange()
    local npcBot = GetBot();
    local abilityT = npcBot:GetAbilityByName( "shredder_timber_chain" );

    local lvl = abilityT:GetLevel();
    return 600 + lvl * 200;
end

----------------- local utility functions reordered for lua local visibility--------
--Perry's code from http://dev.dota2.com/showthread.php?t=274837
local function PerryGetHeroLevel()
    local npcBot = GetBot();
    local respawnTable = {8, 10, 12, 14, 16, 26, 28, 30, 32, 34, 36, 46, 48, 50, 52, 54, 56, 66, 70, 74, 78,  82, 86, 90, 100};
    local nRespawnTime = npcBot:GetRespawnTime() +1 -- It gives 1 second lower values.
    for k,v in pairs (respawnTable) do
        if v == nRespawnTime then
        return k
        end
    end
end

local function ConsiderFighting(StateMachine)
    local ShouldFight = false;
    local npcBot = GetBot();

    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        for _,npcEnemy in pairs( NearbyEnemyHeroes )
        do
            if(npcBot:WasRecentlyDamagedByHero(npcEnemy,1)) then
                -- got the enemy who attacks me, kill him!--
                StateMachine["EnemyToKill"] = npcEnemy;
                ShouldFight = true;
                break;
            elseif(GetUnitToUnitDistance(npcBot,npcEnemy) < 400) then
                StateMachine["EnemyToKill"] = npcEnemy;
                ShouldFight = true;
                break;
            end
        end
    end
    --return ShouldFight;
    return false;
end


local function ConsiderAttackCreeps(StateMachine)
    local npcBot = GetBot();

    local EnemyCreeps = npcBot:GetNearbyCreeps(1000,true);
    local AllyCreeps = npcBot:GetNearbyCreeps(1000,false);

    -- Check if we're already using an ability
	if ( TimberSawIsBusy()) then return end;

    local abilityD = npcBot:GetAbilityByName( "shredder_whirling_death" );
	local abilityT = npcBot:GetAbilityByName( "shredder_timber_chain" );
    local abilityC = npcBot:GetAbilityByName( "shredder_chakram" );
    local abilityC2 = npcBot:GetAbilityByName( "shredder_return_chakram" );
    local abilityF = npcBot:GetAbilityByName( "shredder_chakram_2" );
    local abilityF2 = npcBot:GetAbilityByName( "shredder_return_chakram_2" );

    local DDamage = abilityD:GetAbilityDamage();
    local DRange = 300;

    local TDamage = abilityT:GetAbilityDamage();
    local TCastRange = GetTRange();

    local CDamage = abilityC:GetAbilityDamage();

    --If we dont cast ability, just try to last hit.

    local lowest_hp = 100000;
    local weakest_creep = nil;
    for creep_k,creep in pairs(EnemyCreeps)
    do 
        --npcBot:GetEstimatedDamageToTarget
        local creep_name = creep:GetUnitName();
        DotaBotUtility:UpdateCreepHealth(creep);
        --print(creep_name);
        if(creep:IsAlive()) then
            local creep_hp = creep:GetHealth();
            if(lowest_hp > creep_hp) then
                 lowest_hp = creep_hp;
                 weakest_creep = creep;
            end
        end
    end

    if(weakest_creep ~= nil and weakest_creep:GetHealth() / weakest_creep:GetMaxHealth() < 0.5) then
        --if(DotaBotUtility.NilOrDead(npcBot:GetAttackTarget()) and 
        local DmgPerSec =  DotaBotUtility:GetCreepHealthDeltaPerSec(weakest_creep);
        if DmgPerSec < 0 then
            DmgPerSec = 0;
        end
        local ActualDmg = weakest_creep:GetActualDamage(npcBot:GetBaseDamage() + 24,
        DAMAGE_TYPE_PHYSICAL);
        if(lowest_hp < ActualDmg
        + DmgPerSec
        * npcBot:GetAttackPoint() / npcBot:GetAttackSpeed()) then
            if(npcBot:GetAttackTarget() == nil) then --StateMachine["attcking creep"]
                npcBot:Action_AttackUnit(weakest_creep,true);
                return;
            elseif(weakest_creep ~= StateMachine["attcking creep"]) then
                StateMachine["attcking creep"] = weakest_creep;
                npcBot:Action_AttackUnit(weakest_creep,true);
                return;
            end
            return;
        elseif(lowest_hp < ActualDmg
        + DmgPerSec
        * (npcBot:GetAttackPoint() / npcBot:GetAttackSpeed()
        + GetUnitToUnitDistance(npcBot,weakest_creep) / npcBot:GetCurrentMovementSpeed())) then
            npcBot:Action_MoveToLocation(weakest_creep:GetLocation());
            return;
        end
        weakest_creep = nil;
        
    end

    --[[
    for creep_k,creep in pairs(AllyCreeps)
    do 
        --npcBot:GetEstimatedDamageToTarget
        local creep_name = creep:GetUnitName();
        DotaBotUtility:UpdateCreepHealth(creep);
        --print(creep_name);
        if(creep:IsAlive()) then
             local creep_hp = creep:GetHealth();
             if(lowest_hp > creep_hp) then
                 lowest_hp = creep_hp;
                 weakest_creep = creep;
             end
         end
    end

    if(weakest_creep ~= nil) then
        -- if creep's hp is lower than 70(because I don't Know how much is my damadge!!), try to last hit it.
        if(DotaBotUtility.NilOrDead(npcBot:GetAttackTarget()) and 
        lowest_hp < weakest_creep:GetActualDamage(
        npcBot:GetBaseDamage(),DAMAGE_TYPE_PHYSICAL) + DotaBotUtility:GetCreepHealthDeltaPerSec(weakest_creep) 
        * npcBot:GetAttackPoint() / npcBot:GetAttackSpeed()
         and 
        weakest_creep:GetHealth() / weakest_creep:GetMaxHealth() < 0.5) then
            Attacking_creep = weakest_creep;
            npcBot:Action_AttackUnit(Attacking_creep,true);
            return;
        end
        weakest_creep = nil;
        
    end

    ]]

    

    local pt = GetLaneFrontLocation(DotaBotUtility:GetEnemyTeam(),LANE,-700);
    npcBot:Action_MoveToLocation(pt);
    return;
    
end

local function ShouldRetreat()
    local npcBot = GetBot();
    if(DotaTime() > 360) then
        return npcBot:GetHealth()/npcBot:GetMaxHealth() 
        < TimberSawRetreatHPThreshold or npcBot:GetMana()/npcBot:GetMaxMana() 
        < TimberSawRetreatMPThreshold;
    else
        return npcBot:GetHealth()/npcBot:GetMaxHealth() 
        < TimberSawRetreatHPThreshold;
    end
end

local function IsTowerAttackingMe()
    local npcBot = GetBot();
    local NearbyTowers = npcBot:GetNearbyTowers(1000,true);
    local AllyCreeps = npcBot:GetNearbyCreeps(650,false);
    if(#NearbyTowers > 0) then
        for _,tower in pairs( NearbyTowers)
        do
            if(GetUnitToUnitDistance(tower,npcBot) < 900 and tower:IsAlive() and #AllyCreeps <= 2) then
                print("TimberSaw Attacked by tower");
                return true;
            end
        end
    end
    return false;
end

-------------------local states-----------------------------------------------------

local function StateIdle(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(1000,true);
    local pt = DotaBotUtility:GetComfortPoint(creeps,LANE);

    if (TimberSawIsBusy()) then return end;

    if(ShouldRetreat()) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif(IsTowerAttackingMe() or DotaBotUtility:ConsiderRunAway()) then
        StateMachine.State = STATE_RUN_AWAY;
        return;
    elseif(IsInTeamFight()) then
        StateMachine.State = STATE_TEAM_FIGHTING;
        return;
    elseif(npcBot:GetAttackTarget() ~= nil) then
        if(npcBot:GetAttackTarget():IsHero()) then
            StateMachine["EnemyToKill"] = npcBot:GetAttackTarget();
            print("auto attacking: "..npcBot:GetAttackTarget():GetUnitName());
            StateMachine.State = STATE_FIGHTING;
            return;
        end
    elseif(ConsiderFighting(StateMachine)) then
        StateMachine.State = STATE_FIGHTING;
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        StateMachine.State = STATE_ATTACKING_CREEP;
        return;
    end

    -- buy a tp and get out
    if(npcBot:DistanceFromFountain() < 100 and DotaTime() > 0) then
        local tpscroll = DotaBotUtility.IsItemAvailable("item_tpscroll");
        if(tpscroll == nil and DotaBotUtility:HasEmptySlot() and npcBot:GetGold() >= GetItemCost("item_tpscroll")) then
            print("TimberSaw buying tp");
            npcBot:Action_PurchaseItem("item_tpscroll");
            return;
        elseif(tpscroll ~= nil and tpscroll:IsFullyCastable()) then
            local tower = DotaBotUtility:GetFrontTowerAt(LANE);
            if(tower ~= nil) then
                npcBot:Action_UseAbilityOnEntity(tpscroll,tower);
                return;
            end
        end
    end

    local NearbyTowers = npcBot:GetNearbyTowers(1000,true);
    local AllyCreeps = npcBot:GetNearbyCreeps(800,false);

    for _,tower in pairs(NearbyTowers)
    do
        local myDistanceToTower = GetUnitToUnitDistance(npcBot,tower);
        if(tower:IsAlive() and #AllyCreeps >= 1 and #creeps == 0) then
            for _,creep in pairs(AllyCreeps)
            do
                if(myDistanceToTower > GetUnitToUnitDistance(creep,tower) + 300) then
                    print("Timber attack tower!!!");
                    npcBot:Action_AttackUnit(tower,false);
                    return;
                end
            end
        end
    end

    if(DotaTime() < 20) then
        local tower = DotaBotUtility:GetFrontTowerAt(LANE);
        npcBot:Action_MoveToLocation(tower:GetLocation());
        return;
    else
        target = DotaBotUtility:GetNearBySuccessorPointOnLane(LANE);
        npcBot:Action_AttackMove(target);
        return;
    end
    

end

local function StateAttackingCreep(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(1000,true);
    local pt = DotaBotUtility:GetComfortPoint(creeps,LANE);

    if (TimberSawIsBusy()) then return end;

    if(npcBot:GetHealth()/npcBot:GetMaxHealth() 
    < TimberSawRetreatHPThreshold) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif(IsTowerAttackingMe() or DotaBotUtility:ConsiderRunAway()) then
        StateMachine.State = STATE_RUN_AWAY;
    elseif(IsInTeamFight()) then
        StateMachine.State = STATE_TEAM_FIGHTING;
        return;
    elseif(ConsiderFighting(StateMachine)) then
        StateMachine.State = STATE_FIGHTING;
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        ConsiderAttackCreeps(StateMachine);
        return;
    else
        StateMachine.State = STATE_IDLE;
        return;
    end
end

local function StateRetreat(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    if (TimberSawIsBusy()) then return end;

    npcBot:Action_MoveToLocation(Constant.HomePosition());

    if(npcBot:GetHealth() == npcBot:GetMaxHealth() and npcBot:GetMana() == npcBot:GetMaxMana()) then
        StateMachine.State = STATE_IDLE;
        return;
    end
end

local function StateGotoComfortPoint(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(1000,true);
    --local pt = DotaBotUtility:GetComfortPoint(creeps,LANE);
    local pt = GetLaneFrontLocation(DotaBotUtility:GetEnemyTeam(),LANE,-500);

    if (TimberSawIsBusy()) then return end;

    if(npcBot:GetHealth()/npcBot:GetMaxHealth() 
    < TimberSawRetreatHPThreshold) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif(IsTowerAttackingMe() or DotaBotUtility:ConsiderRunAway()) then
        StateMachine.State = STATE_RUN_AWAY;
        return;
    elseif(IsInTeamFight()) then
        StateMachine.State = STATE_TEAM_FIGHTING;
        return;
    elseif(ConsiderFighting(StateMachine)) then
        StateMachine.State = STATE_FIGHTING;
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        local mypos = npcBot:GetLocation();
        --pt[3] = npcBot:GetLocation()[3];
        
        --local d = GetUnitToLocationDistance(npcBot,pt);
        local d = (npcBot:GetLocation() - pt):Length2D();
 
        if (d < 100) then
            npcBot:Action_ClearActions(true);
            StateMachine.State = STATE_ATTACKING_CREEP;
        else
            npcBot:Action_MoveToLocation(pt);
        end
        return;
    else
        StateMachine.State = STATE_IDLE;
        return;
    end

end

local function StateFighting(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    if (TimberSawIsBusy()) then return end;

    if(IsTowerAttackingMe() or DotaBotUtility:ConsiderRunAway()) then
        StateMachine.State = STATE_RUN_AWAY;
        return;
    elseif(IsInTeamFight()) then
        StateMachine.State = STATE_TEAM_FIGHTING;
        return;
    elseif(not StateMachine["EnemyToKill"]:CanBeSeen() or not StateMachine["EnemyToKill"]:IsAlive()) then
        -- lost enemy 
        print("TimberSaw lost enemy");
        StateMachine.State = STATE_IDLE;
        return;
    else

        if(StateMachine["EnemyToKill"]:GetHealth() > npcBot:GetHealth()) then
            StateMachine.State = STATE_RUN_AWAY;
            return;
        end


        if(npcBot:GetAttackTarget() ~= StateMachine["EnemyToKill"]) then
            npcBot:Action_AttackUnit(StateMachine["EnemyToKill"],false);
            return;
        end

    end
end

local function StateRunAway(StateMachine)
    local npcBot = GetBot();

    if (TimberSawIsBusy()) then return end;

    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        StateMachine["RunAwayFromLocation"] = nil;
        return;
    end

    if(npcBot:GetHealth()/npcBot:GetMaxHealth() 
    < TimberSawRetreatHPThreshold) then
        StateMachine.State = STATE_RETREAT;
        StateMachine["RunAwayFromLocation"] = nil;
        return;
    end

    local mypos = npcBot:GetLocation();

    if(StateMachine["RunAwayFromLocation"] == nil) then
        --set the target to go back
        StateMachine["RunAwayFromLocation"] = npcBot:GetLocation();
        --npcBot:Action_MoveToLocation(Constant.HomePosition());
        npcBot:Action_MoveToLocation(DotaBotUtility:GetNearByPrecursorPointOnLane(LANE));
        return;
    else
        if(GetUnitToLocationDistance(npcBot,StateMachine["RunAwayFromLocation"]) > 400) then
            -- we are far enough from tower,return to normal state.
            StateMachine["RunAwayFromLocation"] = nil;
            StateMachine.State = STATE_IDLE;
            return;
        else
            npcBot:Action_MoveToLocation(DotaBotUtility:GetNearByPrecursorPointOnLane(LANE));
            return;
        end
    end
end 

local function StateTeamFighting(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    if (TimberSawIsBusy()) then return end;

    if(IsTowerAttackingMe() or DotaBotUtility:ConsiderRunAway()) then
        StateMachine.State = STATE_RUN_AWAY;
    elseif(not StateMachine["EnemyToKill"]:CanBeSeen() or not StateMachine["EnemyToKill"]:IsAlive()) then
        -- lost enemy 
        print("lost enemy");
        StateMachine.State = STATE_IDLE;
        return;
    else
        
        StateMachine.State = STATE_IDLE;
        return;

    end
end

local StateMachine = {};
StateMachine["State"] = STATE_IDLE;
StateMachine[STATE_IDLE] = StateIdle;
StateMachine[STATE_ATTACKING_CREEP] = StateAttackingCreep;
StateMachine[STATE_RETREAT] = StateRetreat;
StateMachine[STATE_GOTO_COMFORT_POINT] = StateGotoComfortPoint;
StateMachine[STATE_FIGHTING] = StateFighting;
StateMachine[STATE_RUN_AWAY] = StateRunAway;
StateMachine[STATE_TEAM_FIGHTING] = StateTeamFighting;
StateMachine["totalLevelOfAbilities"] = 0;

local TimberSawAbilityMap = {
    [1] = "shredder_reactive_armor",
    [2] = "shredder_whirling_death",
    [3] = "shredder_reactive_armor",
    [4] = "shredder_timber_chain",
    [5] = "shredder_reactive_armor",
    [6] = "shredder_chakram",
    [7] = "shredder_reactive_armor",
    [8] = "shredder_whirling_death",
    [9] = "shredder_whirling_death",
    [10] = "special_bonus_hp_150",
    [11] = "shredder_whirling_death",
    [12] = "shredder_chakram",
    [13] = "shredder_timber_chain",
    [14] = "shredder_timber_chain",
    [15] = "special_bonus_hp_regen_14",
    [16] = "shredder_timber_chain",
    [18] = "shredder_chakram",
    [20] = "special_bonus_spell_amplify_5",
    [25] = "special_bonus_strength_20"
};

local TimberSawDoneLvlupAbility = {};

for lvl,_ in pairs(TimberSawAbilityMap)
do
    TimberSawDoneLvlupAbility[lvl] = false;
end

local function ThinkLvlupAbility(StateMachine)
    -- Is there a bug? http://dev.dota2.com/showthread.php?t=274436
    local npcBot = GetBot();


    local HeroLevel = PerryGetHeroLevel();
    if(TimberSawDoneLvlupAbility[HeroLevel] == false) then
        npcBot:Action_LevelAbility(TimberSawAbilityMap[HeroLevel]);
        --TimberSawDoneLvlupAbility[HeroLevel] = true;
    end
end

local PrevState = "none";

function Think(  )
    -- Think this item( ... )
    --update
    
    local npcBot = GetBot();
    DotaBotUtility:CourierThink();
    ThinkLvlupAbility(StateMachine);

    StateMachine[StateMachine.State](StateMachine);

    if(PrevState ~= StateMachine.State) then
        print("TimberSaw bot STATE: "..StateMachine.State);
        PrevState = StateMachine.State;
    end

end
