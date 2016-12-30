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

local TinkerRetreatHPThreshold = 0.3;
local TinkerRetreatMPThreshold = 0.2;

local STATE = STATE_IDLE;

MoMradius = 900;

LANE = LANE_MID;

local function TinkerIsBusy()
    local npcBot = GetBot();
    local abilityRearm = npcBot:GetAbilityByName( "tinker_rearm" );

    if(LastRearmTime ~= nil) then
        if(GameTime() - LastRearmTime < abilityRearm:GetChannelTime() + 0.2) then
            return true;
        end
    end

    local busy = npcBot:IsUsingAbility() or npcBot:IsChanneling() or npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_USE_ABILITY;

    return busy;
end

local function CanCastOnTarget( npcTarget )
	return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable();
end

local function TinkerConsiderRearm()
    local npcBot = GetBot();
    local abilityLaser = npcBot:GetAbilityByName( "tinker_laser" );
	local abilityMissile = npcBot:GetAbilityByName( "tinker_heat_seeking_missile" );
	local abilityMoM = npcBot:GetAbilityByName( "tinker_march_of_the_machines" );
    local abilityRearm = npcBot:GetAbilityByName( "tinker_rearm" );
    if(abilityRearm == nil) then
        return false;
    end

    if(LastRearmTime ~= nil) then
        if(GameTime() - LastRearmTime < abilityRearm:GetChannelTime() + 0.2) then
            return false;
        end
    end

    local boot_ready = true;

    local travel_boots = DotaBotUtility.IsItemAvailable("item_travel_boots");

    if(travel_boots ~= nil) then
        boot_ready = travel_boots:IsCooldownReady();
    end

    return not abilityMoM:IsCooldownReady() 
    or not abilityMissile:IsCooldownReady() 
    or not abilityLaser:IsCooldownReady() 
    or not boot_ready;
end

local function SoulRingReArm()
    local npcBot = GetBot();
    local abilityRearm = npcBot:GetAbilityByName( "tinker_rearm" );
    if(TinkerConsiderRearm() and abilityRearm:IsFullyCastable()) then
        local soul_ring = DotaBotUtility.IsItemAvailable("item_soul_ring");
        if(soul_ring ~= nil and soul_ring:IsFullyCastable()
        and npcBot:GetHealth() / npcBot:GetMaxHealth() > 0.5) then
            npcBot:Action_UseAbility(soul_ring);
            return;
        else
            npcBot:Action_UseAbility(abilityRearm);
            LastRearmTime = GameTime();
            return;
        end
    end
end

local function IsInTeamFight()
    local npcBot = GetBot();
    local EnemyCount = 0;

    local EnemyBots = DotaBotUtility:GetEnemyBots();
    local EnemyTeam = DotaBotUtility:GetEnemyTeam();

    for _,idx in pairs(EnemyBots)
    do
        local BotHandle = GetTeamMember(EnemyTeam,idx);
        if(BotHandle ~= nil and BotHandle:IsAlive() and BotHandle:CanBeSeen() 
        and GetUnitToUnitDistance(BotHandle,npcBot) < 1000) then
            EnemyCount = EnemyCount + 1;
        end
    end

    if(EnemyCount >= 2)then
        return true;
    else
        return false;
    end
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
    return ShouldFight;
end


local function ConsiderAttackCreeps(StateMachine)
    -- there are creeps try to attack them --
    --print("ConsiderAttackCreeps");
    local npcBot = GetBot();

    local EnemyCreeps = npcBot:GetNearbyCreeps(MoMradius,true);
    local AllyCreeps = npcBot:GetNearbyCreeps(1000,false);

    -- Check if we're already using an ability
	if ( TinkerIsBusy()) then return end;

    local abilityLaser = npcBot:GetAbilityByName( "tinker_laser" );
	local abilityMissile = npcBot:GetAbilityByName( "tinker_heat_seeking_missile" );
	local abilityMoM = npcBot:GetAbilityByName( "tinker_march_of_the_machines" );
    local abilityRearm = npcBot:GetAbilityByName( "tinker_rearm" );

    local LaserDamage = abilityLaser:GetAbilityDamage();
    local LaserCastRange = abilityLaser:GetCastRange();

    local MissileDamage = abilityMissile:GetAbilityDamage();
    local MissileCastRange = abilityMissile:GetCastRange();

    local MoMDamage = abilityMoM:GetAbilityDamage();

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
        -- if creep's hp is lower than 70(because I don't Know how much is my damadge!!), try to last hit it.
        --if(DotaBotUtility.NilOrDead(npcBot:GetAttackTarget()) and 
        if(lowest_hp < weakest_creep:GetActualDamage(
        npcBot:GetBaseDamage(),DAMAGE_TYPE_PHYSICAL)
        + DotaBotUtility:GetCreepHealthDeltaPerSec(weakest_creep) 
        * (npcBot:GetAttackPoint() / npcBot:GetAttackSpeed() + GetUnitToUnitDistance(npcBot,weakest_creep) / 900)) then
            if(npcBot:GetAttackTarget() == nil) then --StateMachine["attcking creep"]
                npcBot:Action_AttackUnit(weakest_creep,false);
                return;
            elseif(weakest_creep ~= StateMachine["attcking creep"]) then
                StateMachine["attcking creep"] = weakest_creep;
                npcBot:Action_AttackUnit(weakest_creep,true);
                return;
            end
        else
            -- simulation of human attack and stop
            if(npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_ATTACK) then
                npcBot:Action_ClearActions(true);
                return;
            else
                npcBot:Action_AttackUnit(weakest_creep,false);
                return;
            end
        end
        weakest_creep = nil;
        
    end

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
        * (npcBot:GetAttackPoint() / npcBot:GetAttackSpeed() + GetUnitToUnitDistance(npcBot,weakest_creep) / 900)
         and 
        weakest_creep:GetHealth() / weakest_creep:GetMaxHealth() < 0.5) then
            Attacking_creep = weakest_creep;
            npcBot:Action_AttackUnit(Attacking_creep,true);
            return;
        end
        weakest_creep = nil;
        
    end

    -- nothing to do , try to attack heros

    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        if(#NearbyEnemyHeroes > 0 and abilityMissile:IsFullyCastable() and MissileDamage > 300) then
            npcBot:Action_UseAbility(abilityMissile);
            return;
        end


        for _,npcEnemy in pairs( NearbyEnemyHeroes )
        do
            if(CanCastOnTarget(npcEnemy)) then
                if(npcEnemy:GetActualDamage(MissileDamage,DAMAGE_TYPE_MAGICAL) >= npcEnemy:GetHealth()) then
                    npcBot:Action_UseAbility(abilityMissile);
                    return;
                end

                if(npcEnemy:GetActualDamage(LaserDamage,DAMAGE_TYPE_PURE) >= npcEnemy:GetHealth()) then
                    npcBot:Action_UseAbilityOnEntity(abilityLaser,npcEnemy);
                    return;
                end

                if(LaserDamage > 300 and GetUnitToUnitDistance(npcBot,npcEnemy) <= LaserCastRange) then
                    npcBot:Action_UseAbilityOnEntity(abilityLaser,npcEnemy);
                    return;
                end
            end

            if(DotaBotUtility.NilOrDead(npcBot:GetAttackTarget()) and GetUnitToUnitDistance(npcBot,npcEnemy) <= 600) then
                npcBot:Action_AttackUnit(npcEnemy,false);
                return;
            end
        end
    end

    -- CastMoM
    if(EnemyCreeps ~= nil) then
        if(AllyCreeps ~= nil and #AllyCreeps > 0) then
            if(#EnemyCreeps >=3 and abilityMoM:IsFullyCastable() and MoMDamage >= 24) then
                npcBot:Action_UseAbilityOnLocation(abilityMoM,npcBot:GetLocation() + Vector(50,-50));
                return;
            end
        else
            if(#EnemyCreeps >=0 and abilityMoM:IsFullyCastable() and MoMDamage >= 24) then
                npcBot:Action_UseAbilityOnLocation(abilityMoM,npcBot:GetLocation() + Vector(50,-50));
                return;
            end
        end
    end

    SoulRingReArm();

    -- hit creeps to push
    local TimeNow = DotaTime();
    for creep_k,creep in pairs(EnemyCreeps)
    do 
        local creep_name = creep:GetUnitName();
        --print(creep_name);
        if(creep:IsAlive()) then
            if(TimeNow > 600) then
                npcBot:Action_AttackUnit(creep,false);
                return;
            end
            local creep_hp = creep:GetHealth();
            if(lowest_hp > creep_hp) then
                 lowest_hp = creep_hp;
                 weakest_creep = creep;
            end
        end
    end
    
end

local function ShouldRetreat()
    local npcBot = GetBot();
    if(DotaTime() > 360) then
        return npcBot:GetHealth()/npcBot:GetMaxHealth() 
        < TinkerRetreatHPThreshold or npcBot:GetMana()/npcBot:GetMaxMana() 
        < TinkerRetreatMPThreshold;
    else
        return npcBot:GetHealth()/npcBot:GetMaxHealth() 
        < TinkerRetreatHPThreshold;
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
                print("Tinker Attacked by tower");
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

    if (TinkerIsBusy()) then return end;

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
        local mypos = npcBot:GetLocation();
        
        local d = GetUnitToLocationDistance(npcBot,pt);
        if(d > 250) then
            StateMachine.State = STATE_GOTO_COMFORT_POINT;
        else
            StateMachine.State = STATE_ATTACKING_CREEP;
        end
        return;
    end

    -- cast missile
	local abilityMissile = npcBot:GetAbilityByName( "tinker_heat_seeking_missile" );

    local MissileDamage = abilityMissile:GetAbilityDamage();
    local MissileCastRange = abilityMissile:GetCastRange();

    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        if(#NearbyEnemyHeroes > 0 and abilityMissile:IsFullyCastable() and MissileDamage > 300) then
            npcBot:Action_UseAbility(abilityMissile);
            return;
        end
    end

    local travel_boots = DotaBotUtility.IsItemAvailable("item_travel_boots");

    -- buy a tp and get out
    if(travel_boots == nil and npcBot:DistanceFromFountain() < 100 and DotaTime() > 0) then
        local tpscroll = DotaBotUtility.IsItemAvailable("item_tpscroll");
        if(tpscroll == nil and DotaBotUtility:HasEmptySlot() and npcBot:GetGold() >= GetItemCost("item_tpscroll")) then
            print("buying tp");
            npcBot:Action_PurchaseItem("item_tpscroll");
            return;
        elseif(tpscroll ~= nil and tpscroll:IsFullyCastable()) then
            local tower = DotaBotUtility:GetFrontTowerAt(LANE);
            if(tower ~= nil) then
                npcBot:Action_UseAbilityOnEntity(tpscroll,tower);
                return;
            end
        elseif(tpscroll ~= nil and not tpscroll:IsCooldownReady()) then
            print("refresh tpscroll");
            local abilityRearm = npcBot:GetAbilityByName( "tinker_rearm" );
            if(abilityRearm:IsFullyCastable()) then
                npcBot:Action_UseAbility(abilityRearm);
                LastRearmTime = GameTime();
                return;
            end
        end
    end
    
    if(travel_boots ~= nil and travel_boots:IsFullyCastable() and npcBot:DistanceFromFountain() == 0) then
        local tower = DotaBotUtility:GetFrontTowerAt(LANE);
        if(tower ~= nil) then
            npcBot:Action_UseAbilityOnEntity(travel_boots,tower);
            return;
        else
            target = DotaBotUtility:GetNearBySuccessorPointOnLane(LANE);
            npcBot:Action_AttackMove(target);
            return;
        end
    elseif(travel_boots ~= nil and not travel_boots:IsCooldownReady()) then
        --refresh boots
        print("refresh boots");
        local abilityRearm = npcBot:GetAbilityByName( "tinker_rearm" );
        if(abilityRearm:IsFullyCastable()) then
            npcBot:Action_UseAbility(abilityRearm);
            LastRearmTime = GameTime();
            return;
        end
    else
        local NearbyTowers = npcBot:GetNearbyTowers(1000,true);
        local AllyCreeps = npcBot:GetNearbyCreeps(800,false);

        for _,tower in pairs(NearbyTowers)
        do
            local myDistanceToTower = GetUnitToUnitDistance(npcBot,tower);
            if(tower:IsAlive() and #AllyCreeps >= 1 and #creeps == 0) then
                for _,creep in pairs(AllyCreeps)
                do
                    if(myDistanceToTower > GetUnitToUnitDistance(creep,tower) + 300) then
                        print("Lina attack tower!!!");
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
    

end

local function StateAttackingCreep(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(1000,true);
    local pt = DotaBotUtility:GetComfortPoint(creeps,LANE);

    if (TinkerIsBusy()) then return end;

    if(npcBot:GetHealth()/npcBot:GetMaxHealth() 
    < TinkerRetreatHPThreshold) then
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
        local mypos = npcBot:GetLocation();
        local d = GetUnitToLocationDistance(npcBot,pt);
        if(d > 200) then
            if(StateMachine["GotoComfortPointTime"] == nil) then
                StateMachine["GotoComfortPointTime"] = GameTime();
                return;
            else
                if(GameTime() - StateMachine["GotoComfortPointTime"] < 1) then
                    return;
                else
                    StateMachine.State = STATE_GOTO_COMFORT_POINT;
                    StateMachine["GotoComfortPointTime"] = nil;
                    return;
                end
            end
            
        else
            ConsiderAttackCreeps(StateMachine);
        end
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

    --[[
            I don't know how to Create a object of Location so I borrow one from GetLocation()

            Got Vector from marko.polo at http://dev.dota2.com/showthread.php?t=274301
    ]]

    if (TinkerIsBusy()) then return end;

    if(npcBot:DistanceFromFountain() > 0) then
        local travel_boots = DotaBotUtility.IsItemAvailable("item_travel_boots");
        
        if(travel_boots ~= nil and travel_boots:IsFullyCastable()) then
            npcBot:Action_UseAbilityOnLocation(travel_boots,Constant.HomePosition());
            return;
        else
            npcBot:Action_MoveToLocation(Constant.HomePosition());
            return;
        end
    end

    -- cast missile
	local abilityMissile = npcBot:GetAbilityByName( "tinker_heat_seeking_missile" );

    local MissileDamage = abilityMissile:GetAbilityDamage();
    local MissileCastRange = abilityMissile:GetCastRange();

    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        if(#NearbyEnemyHeroes > 0 and abilityMissile:IsFullyCastable() and MissileDamage > 300) then
            npcBot:Action_UseAbility(abilityMissile);
            return;
        end
    end

    

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
    local pt = DotaBotUtility:GetComfortPoint(creeps,LANE);
    
    if (TinkerIsBusy()) then return end;

    if(npcBot:GetHealth()/npcBot:GetMaxHealth() 
    < TinkerRetreatHPThreshold) then
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
            StateMachine.State = STATE_ATTACKING_CREEP;
        else
            npcBot:Action_MoveToLocation(pt);
        end
        return;
    else
        StateMachine.State = STATE_IDLE;
        return;
    end

    -- cast missile
	local abilityMissile = npcBot:GetAbilityByName( "tinker_heat_seeking_missile" );

    local MissileDamage = abilityMissile:GetAbilityDamage();
    local MissileCastRange = abilityMissile:GetCastRange();

    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        if(#NearbyEnemyHeroes > 0 and abilityMissile:IsFullyCastable() and MissileDamage > 300) then
            npcBot:Action_UseAbility(abilityMissile);
            return;
        end
    end

end

local function StateFighting(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine["cyclone dota time"] = nil;
        StateMachine.State = STATE_IDLE;
        return;
    end

    if (TinkerIsBusy()) then return end;

    if(IsTowerAttackingMe() or DotaBotUtility:ConsiderRunAway()) then
        StateMachine["cyclone dota time"] = nil;
        StateMachine.State = STATE_RUN_AWAY;
        return;
    elseif(IsInTeamFight()) then
        StateMachine.State = STATE_TEAM_FIGHTING;
        return;
    elseif(not StateMachine["EnemyToKill"]:CanBeSeen() or not StateMachine["EnemyToKill"]:IsAlive()) then
        -- lost enemy 
        print("lost enemy");
        StateMachine["cyclone dota time"] = nil;
        StateMachine.State = STATE_IDLE;
        return;
    else
        local abilityLaser = npcBot:GetAbilityByName( "tinker_laser" );
        local abilityMissile = npcBot:GetAbilityByName( "tinker_heat_seeking_missile" );
        local abilityMoM = npcBot:GetAbilityByName( "tinker_march_of_the_machines" );
        local abilityRearm = npcBot:GetAbilityByName( "tinker_rearm" );

        local LaserDamage = abilityLaser:GetAbilityDamage();
        local LaserCastRange = abilityLaser:GetCastRange();

        local MissileDamage = abilityMissile:GetAbilityDamage();
        local MissileCastRange = abilityMissile:GetCastRange();

        local MoMDamage = abilityMoM:GetAbilityDamage();

        -- Laser is castable but out of range, get closer!--
        if(CanCastOnTarget(StateMachine["EnemyToKill"])) then
            if(abilityLaser:IsFullyCastable()) then
                if(GetUnitToUnitDistance(npcBot,StateMachine["EnemyToKill"]) < LaserCastRange) then
                    npcBot:Action_UseAbilityOnEntity(abilityLaser,StateMachine["EnemyToKill"]);
                else
                    npcBot:Action_MoveToLocation(StateMachine["EnemyToKill"]:GetLocation());
                    return;
                end
            end

            if(abilityMissile:IsFullyCastable()) then
                npcBot:Action_UseAbility(abilityMissile);
                return;
            end

            if(abilityMoM:IsFullyCastable()) then
                npcBot:Action_UseAbilityOnLocation(abilityMoM,npcBot:GetLocation() + Vector(50,-50));
                return;
            end
        end

        if(StateMachine["EnemyToKill"]:GetHealth() > npcBot:GetHealth()) then
            StateMachine.State = STATE_RUN_AWAY;
            return;
        end


        if(npcBot:GetAttackTarget() ~= StateMachine["EnemyToKill"]) then
            npcBot:Action_AttackUnit(StateMachine["EnemyToKill"],false);
            return;
        end

        SoulRingReArm();    

    end
end

local function StateRunAway(StateMachine)
    local npcBot = GetBot();

    if (TinkerIsBusy()) then return end;

    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        StateMachine["RunAwayFromLocation"] = nil;
        return;
    end

    if(npcBot:GetHealth()/npcBot:GetMaxHealth() 
    < TinkerRetreatHPThreshold) then
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

    if (TinkerIsBusy()) then return end;

    if(IsTowerAttackingMe() or DotaBotUtility:ConsiderRunAway()) then
        StateMachine.State = STATE_RUN_AWAY;
    else
        local abilityLaser = npcBot:GetAbilityByName( "tinker_laser" );
        local abilityMissile = npcBot:GetAbilityByName( "tinker_heat_seeking_missile" );
        local abilityMoM = npcBot:GetAbilityByName( "tinker_march_of_the_machines" );
        local abilityRearm = npcBot:GetAbilityByName( "tinker_rearm" );

        local LaserDamage = abilityLaser:GetAbilityDamage();
        local LaserCastRange = abilityLaser:GetCastRange();

        local MissileDamage = abilityMissile:GetAbilityDamage();
        local MissileCastRange = abilityMissile:GetCastRange();

        local MoMDamage = abilityMoM:GetAbilityDamage();

        local EnemyBots = DotaBotUtility:GetEnemyBots();
        local EnemyTeam = DotaBotUtility:GetEnemyTeam();

        for _,idx in pairs(EnemyBots)
        do
            local BotHandle = GetTeamMember(EnemyTeam,idx);
            if(BotHandle ~= nil and BotHandle:IsAlive() and BotHandle:CanBeSeen()) then
                local d = GetUnitToUnitDistance(BotHandle,npcBot);
                if(d < LaserCastRange and abilityLaser:IsFullyCastable()) then
                    npcBot:Action_UseAbilityOnEntity(abilityLaser,BotHandle);
                    return;
                elseif(d < 1000 and abilityMoM:IsFullyCastable()) then
                    npcBot:Action_UseAbilityOnLocation(abilityMoM,npcBot:GetLocation());
                    return;
                elseif(d < 2500) then
                    npcBot:Action_UseAbility(abilityMissile);
                    return;
                end
            end
        end

        SoulRingReArm();
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

--[[
local TinkerAbilityMap = {
    [1] = "tinker_laser",
    [2] = "tinker_march_of_the_machines",
    [3] = "tinker_march_of_the_machines",
    [4] = "tinker_heat_seeking_missile",
    [5] = "tinker_march_of_the_machines",
    [6] = "tinker_rearm",
    [7] = "tinker_march_of_the_machines",
    [8] = "tinker_heat_seeking_missile",
    [9] = "tinker_heat_seeking_missile",
    [10] = "special_bonus_intelligence_8",
    [11] = "tinker_heat_seeking_missile",
    [12] = "tinker_rearm",
    [13] = "tinker_laser",
    [14] = "tinker_laser",
    [15] = "special_bonus_spell_amplify_4",
    [16] = "tinker_laser",
    [18] = "tinker_rearm",
    [20] = "special_bonus_cast_range_75",
    [25] = "special_bonus_unique_tinker"
};   
]]
local TinkerAbilityMap = {
    [1] = "tinker_laser",
    [2] = "tinker_heat_seeking_missile",
    [3] = "tinker_laser",
    [4] = "tinker_heat_seeking_missile",
    [5] = "tinker_laser",
    [6] = "tinker_rearm",
    [7] = "tinker_laser",
    [8] = "tinker_heat_seeking_missile",
    [9] = "tinker_heat_seeking_missile",
    [10] = "special_bonus_intelligence_8",
    [11] = "tinker_march_of_the_machines",
    [12] = "tinker_rearm",
    [13] = "tinker_march_of_the_machines",
    [14] = "tinker_march_of_the_machines",
    [15] = "special_bonus_spell_amplify_4",
    [16] = "tinker_march_of_the_machines",
    [18] = "tinker_rearm",
    [20] = "special_bonus_cast_range_75",
    [25] = "special_bonus_unique_tinker"
};

local TinkerDoneLvlupAbility = {};

for lvl,_ in pairs(TinkerAbilityMap)
do
    TinkerDoneLvlupAbility[lvl] = false;
end

local function ThinkLvlupAbility(StateMachine)
    -- Is there a bug? http://dev.dota2.com/showthread.php?t=274436
    local npcBot = GetBot();


    local HeroLevel = PerryGetHeroLevel();
    if(TinkerDoneLvlupAbility[HeroLevel] == false) then
        npcBot:Action_LevelAbility(TinkerAbilityMap[HeroLevel]);
        --TinkerDoneLvlupAbility[HeroLevel] = true;
    end
end

local PrevState = "none";

function Think(  )
    -- Think this item( ... )
    --update
    
    local npcBot = GetBot();
    DotaBotUtility:CourierThink();
    ThinkLvlupAbility(StateMachine);

    --drinking bottle is a higher level
    if(npcBot:GetMaxHealth() - npcBot:GetHealth() > 100
    or npcBot:GetMaxMana() - npcBot:GetMana() > 100) then
        local bottle = DotaBotUtility.IsItemAvailable("item_bottle");

        if(bottle ~= nil and 
        not npcBot:HasModifier("modifier_bottle_regeneration") 
        and bottle:IsFullyCastable() and bottle:GetCurrentCharges() > 0
        and not (npcBot:IsUsingAbility() or npcBot:IsChanneling())) then
            npcBot:Action_UseAbility(bottle);
            return;
        end
    end

    StateMachine[StateMachine.State](StateMachine);

    if(PrevState ~= StateMachine.State) then
        print("Tink bot STATE: "..StateMachine.State);
        PrevState = StateMachine.State;
    end

    -- not working!
    --local cp = DotaBotUtility:GetFrontTowerAt(LANE):GetNearbyCreeps(1000,false);

end
