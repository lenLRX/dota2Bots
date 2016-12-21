--[[
    StateMachine is a table
    the key "STATE" stores the STATE of Lina 
    other key value pairs: key is the string of state value is the function of the State. 

    each frame DOTA2 will call Think()
    Then Think() will call the function of current state.
]]

local ValveAbilityUse = require(GetScriptDirectory().."/dev/ability_item_usage_lina");
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

local LinaRetreatHPThreshold = 0.3;
local LinaRetreatMPThreshold = 0.2;

local STATE = STATE_IDLE;

LANE = LANE_BOT

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


local function TryToUpgradeAbility(AbilityName)
    local npcBot = GetBot();
    local ability = npcBot:GetAbilityByName(AbilityName);
    if ability:CanAbilityBeUpgraded() then
        ability:UpgradeAbility();
        return true;
    end
    return false;
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
            elseif(GetUnitToUnitDistance(npcBot,npcEnemy) < 500) then
                StateMachine["EnemyToKill"] = npcEnemy;
                ShouldFight = true;
                break;
            end
        end
    end
    return ShouldFight;
end


local function ConsiderAttackCreeps()
    -- there are creeps try to attack them --
    --print("ConsiderAttackCreeps");
    local npcBot = GetBot();

    local EnemyCreeps = npcBot:GetNearbyCreeps(1000,true);
    local AllyCreeps = npcBot:GetNearbyCreeps(1000,false);

    -- Check if we're already using an ability
	if ( npcBot:IsUsingAbility() ) then return end;

    local abilityLSA = npcBot:GetAbilityByName( "lina_light_strike_array" );
	local abilityDS = npcBot:GetAbilityByName( "lina_dragon_slave" );
	local abilityLB = npcBot:GetAbilityByName( "lina_laguna_blade" );

    -- Consider using each ability
    
	local castLBDesire, castLBTarget = ConsiderLagunaBlade(abilityLB);
	local castLSADesire, castLSALocation = ConsiderLightStrikeArray(abilityLSA);
	local castDSDesire, castDSLocation = ConsiderDragonSlave(abilityDS);

    if ( castLBDesire > castLSADesire and castLBDesire > castDSDesire ) 
	then
		npcBot:Action_UseAbilityOnEntity( abilityLB, castLBTarget );
		return;
	end

	if ( castLSADesire > 0 ) 
	then
		npcBot:Action_UseAbilityOnLocation( abilityLSA, castLSALocation );
		return;
	end

	if ( castDSDesire > 0 ) 
	then
		npcBot:Action_UseAbilityOnLocation( abilityDS, castDSLocation );
		return;
	end

    --print("desires: " .. castLBDesire .. " " .. castLSADesire .. " " .. castDSDesire);

    --If we dont cast ability, just try to last hit.

    local lowest_hp = 100000;
    local weakest_creep = nil;
    for creep_k,creep in pairs(EnemyCreeps)
    do 
        --npcBot:GetEstimatedDamageToTarget
        local creep_name = creep:GetUnitName();
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
        if(DotaBotUtility.NilOrDead(npcBot:GetAttackTarget()) and lowest_hp < 100) then
            npcBot:Action_AttackUnit(weakest_creep,true);
            return;
        end
        weakest_creep = nil;
        
    end

    for creep_k,creep in pairs(AllyCreeps)
    do 
        --npcBot:GetEstimatedDamageToTarget
        local creep_name = creep:GetUnitName();
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
        lowest_hp < 100 and 
        weakest_creep:GetHealth() / weakest_creep:GetMaxHealth() < 0.5) then
            Attacking_creep = weakest_creep;
            npcBot:Action_AttackUnit(Attacking_creep,true);
            return;
        end
        weakest_creep = nil;
        
    end

    -- nothing to do , try to attack heros

    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 700, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        for _,npcEnemy in pairs( NearbyEnemyHeroes )
        do
            if(DotaBotUtility.NilOrDead(npcBot:GetAttackTarget())) then
                npcBot:Action_AttackUnit(npcEnemy,false);
                return;
            end
        end
    end
    
end

local function ShouldRetreat()
    local npcBot = GetBot();
    return npcBot:GetHealth()/npcBot:GetMaxHealth() 
    < LinaRetreatHPThreshold or npcBot:GetMana()/npcBot:GetMaxMana() 
    < LinaRetreatMPThreshold;
end

local function IsTowerAttackingMe()
    local npcBot = GetBot();
    local NearbyTowers = npcBot:GetNearbyTowers(1000,true);
    if(#NearbyTowers > 0) then
        for _,tower in pairs( NearbyTowers)
        do
            if(GetUnitToUnitDistance(tower,npcBot) < 900 and tower:IsAlive()) then
                print("Attacked by tower");
                return true;
            end
        end
    else
        return false;
    end
end

-------------------local states-----------------------------------------------------

local function StateIdle(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(1000,true);
    local pt = DotaBotUtility:GetComfortPoint(creeps,LANE);

    

    if(ShouldRetreat()) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif(IsTowerAttackingMe()) then
        StateMachine.State = STATE_RUN_AWAY;
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

    --target = GetLocationAlongLane(LANE,0.95);
    target = DotaBotUtility:GetNearBySuccessorPointOnLane(LANE);
    npcBot:Action_AttackMove(target);
    

end

local function StateAttackingCreep(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(1000,true);
    local pt = DotaBotUtility:GetComfortPoint(creeps,LANE);

    if(ShouldRetreat()) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif(IsTowerAttackingMe()) then
        StateMachine.State = STATE_RUN_AWAY;
    elseif(ConsiderFighting(StateMachine)) then
        StateMachine.State = STATE_FIGHTING;
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        local mypos = npcBot:GetLocation();
        local d = GetUnitToLocationDistance(npcBot,pt);
        if(d > 250) then
            StateMachine.State = STATE_GOTO_COMFORT_POINT;
        else
            ConsiderAttackCreeps();
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
    local pt = DotaBotUtility:GetComfortPoint(creeps,LANE);
    

    if(ShouldRetreat()) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif(IsTowerAttackingMe()) then
        StateMachine.State = STATE_RUN_AWAY;
    elseif(ConsiderFighting(StateMachine)) then
        StateMachine.State = STATE_FIGHTING;
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        local mypos = npcBot:GetLocation();
        --pt[3] = npcBot:GetLocation()[3];
        
        --local d = GetUnitToLocationDistance(npcBot,pt);
        local d = (npcBot:GetLocation() - pt):Length2D();
 
        if (d < 200) then
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
        StateMachine["cyclone dota time"] = nil;
        StateMachine.State = STATE_IDLE;
        return;
    end

    if(IsTowerAttackingMe()) then
        StateMachine["cyclone dota time"] = nil;
        StateMachine.State = STATE_RUN_AWAY;
    elseif(not StateMachine["EnemyToKill"]:CanBeSeen() or not StateMachine["EnemyToKill"]:IsAlive()) then
        -- lost enemy 
        print("lost enemy");
        StateMachine["cyclone dota time"] = nil;
        StateMachine.State = STATE_IDLE;
        return;
    else
        if ( npcBot:IsUsingAbility() ) then return end;

        local cyclone = DotaBotUtility.IsItemAvailable("item_cyclone");

        if(cyclone ~= nil) then
            if(ConsiderCyclone(cyclone,StateMachine["EnemyToKill"])) then
                npcBot:Action_UseAbilityOnEntity(cyclone,StateMachine["EnemyToKill"]);
                StateMachine["cyclone dota time"] = GameTime();
                return;
            elseif(cyclone:IsFullyCastable()) then
                -- move closer to cast cyclone
                npcBot:Action_MoveToLocation(StateMachine["EnemyToKill"]:GetLocation());
                return;
            end
        end

        local abilityLSA = npcBot:GetAbilityByName( "lina_light_strike_array" );
        local abilityDS = npcBot:GetAbilityByName( "lina_dragon_slave" );
        local abilityLB = npcBot:GetAbilityByName( "lina_laguna_blade" );

        local Lina_Cyclone_LSA_Combo_Delay = 1.5;

        if(StateMachine["cyclone dota time"] ~= nil) then
            -- Consider LSA after cyclone
            -- Cast LSA 0.5s before cyclone ends
            if(abilityLSA:IsFullyCastable() and GameTime() - StateMachine["cyclone dota time"] > Lina_Cyclone_LSA_Combo_Delay) then
                if(DotaBotUtility.AbilityOutOfRange4Unit(abilityLSA,StateMachine["EnemyToKill"])) then
                    -- move closer to cast LSA
                    npcBot:Action_MoveToLocation(StateMachine["EnemyToKill"]:GetLocation());
                    return;
                else
                    npcBot:Action_UseAbilityOnLocation( abilityLSA, StateMachine["EnemyToKill"]:GetLocation());
                    StateMachine["cyclone dota time"] = nil;
                    return;
                end
            elseif(abilityLSA:IsFullyCastable() and GameTime() - StateMachine["cyclone dota time"] < Lina_Cyclone_LSA_Combo_Delay) then
                if(DotaBotUtility.AbilityOutOfRange4Unit(abilityLSA,StateMachine["EnemyToKill"])) then
                    -- move closer to cast LSA
                    npcBot:Action_MoveToLocation(StateMachine["EnemyToKill"]:GetLocation());
                    return;
                end
            end
        end
        

        -- Consider using each ability
        
        local castLBDesire, castLBTarget = ConsiderLagunaBlade(abilityLB);
        local castLSADesire, castLSALocation = ConsiderLightStrikeArrayFighting(abilityLSA,StateMachine["EnemyToKill"]);
        local castDSDesire, castDSLocation = ConsiderDragonSlaveFighting(abilityDS,StateMachine["EnemyToKill"]);

        if ( castLBDesire > 0 ) 
        then
            npcBot:Action_UseAbilityOnEntity( abilityLB, castLBTarget );
            return;
        end

        if ( castLSADesire > 0 ) 
        then
            npcBot:Action_UseAbilityOnLocation( abilityLSA, castLSALocation );
            return;
        end

        if ( castDSDesire > 0 ) 
        then
            npcBot:Action_UseAbilityOnLocation( abilityDS, castDSLocation );
            return;
        end

        -- LSA is castable but out of range, get closer!--
        if(abilityLSA:IsFullyCastable() and CanCastLightStrikeArrayOnTarget(StateMachine["EnemyToKill"])) then
            npcBot:Action_MoveToLocation(StateMachine["EnemyToKill"]:GetLocation());
            return;
        end

        if(not abilityLSA:IsFullyCastable() and 
        not abilityDS:IsFullyCastable() or StateMachine["EnemyToKill"]:IsMagicImmune()) then
            local extraHP = 0;
            if(abilityLB:IsFullyCastable()) then
                local LBnDamage = abilityLB:GetSpecialValueInt( "damage" );
                local LBeDamageType = npcBot:HasScepter() and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL;
                extraHP = StateMachine["EnemyToKill"]:GetActualDamage(LBnDamage,LBeDamageType);
            end

            if(StateMachine["EnemyToKill"]:GetHealth() - extraHP > npcBot:GetHealth()) then
                StateMachine.State = STATE_RUN_AWAY;
                return;
            end
        end


        if(npcBot:GetAttackTarget() ~= StateMachine["EnemyToKill"]) then
            npcBot:Action_AttackUnit(StateMachine["EnemyToKill"],false);
        end

    end
end

local function StateRunAway(StateMachine)
    local npcBot = GetBot();

    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        StateMachine["RunAwayFromLocation"] = nil;
        return;
    end

    if(ShouldRetreat()) then
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

-- useless now ignore it
local function StateFarming(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
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
StateMachine["totalLevelOfAbilities"] = 0;


local LinaAbilityPriority = {"lina_laguna_blade",
"lina_dragon_slave","lina_light_strike_array","lina_fiery_soul"};

local LinaTalents = {
    [10] = "special_bonus_mp_250",
    [15] = "bonus_cast_range_125",
    [20] = "bonus_attack_range_150",
    [25] = "special_bonus_unique_lina_1"
};

local function ThinkLvlupAbility(StateMachine)
    -- Is there a bug? http://dev.dota2.com/showthread.php?t=274436
    local npcBot = GetBot();
    --[[
        npcBot:Action_LevelAbility("lina_laguna_blade");
    npcBot:Action_LevelAbility("lina_dragon_slave");
    npcBot:Action_LevelAbility("lina_light_strike_array");
    npcBot:Action_LevelAbility("lina_fiery_soul");
    ]]

    --[[
        for _,AbilityName in pairs(LinaAbilityPriority)
    do
        -- USELESS BREAK : because valve does not check ability points
        if TryToUpgradeAbility(AbilityName) then
            break;
        end
    end
    ]]   

    --npcBot:Action_LevelAbility("special_bonus_mp_250");

    local HeroLevel = PerryGetHeroLevel();

    if(LinaTalents[HeroLevel] ~= nil and StateMachine["totalLevelOfAbilities"] < HeroLevel) then
        npcBot:Action_LevelAbility(LinaTalents[HeroLevel]);
        StateMachine["totalLevelOfAbilities"] = StateMachine["totalLevelOfAbilities"] + 1;
    else
        for k, ability_name in pairs(LinaAbilityPriority) do
            local ability = npcBot:GetAbilityByName(ability_name);
            if (ability:CanAbilityBeUpgraded() and ability:GetLevel()<ability:GetMaxLevel() and StateMachine["totalLevelOfAbilities"] < HeroLevel) then
                ability:UpgradeAbility();
                StateMachine["totalLevelOfAbilities"] = StateMachine["totalLevelOfAbilities"] + 1;
                break;
            end
        end
    end
end

local PrevState = "none";

function Think(  )
    -- Think this item( ... )
    --update
    
    local npcBot = GetBot();
    ThinkLvlupAbility(StateMachine);
    StateMachine[StateMachine.State](StateMachine);

    if(PrevState ~= StateMachine.State) then
        print("STATE: "..StateMachine.State);
        PrevState = StateMachine.State;
    end
	
end
