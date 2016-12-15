--[[
    StateMachine is a table
    the key "STATE" stores the STATE of Lina 
    other key value pairs: key is the string of state value is the function of the State. 

    each frame DOTA2 will call Think()
    Then Think() will call the function of current state.
]]

ValveAbilityUse = require(GetScriptDirectory().."/dev/ability_item_usage_lina");

STATE_IDLE = "STATE_IDLE";
STATE_ATTACKING_CREEP = "STATE_ATTACKING_CREEP";
STATE_KILL = "STATE_KILL";
STATE_RETREAT = "STATE_RETREAT";
STATE_FARMING = "STATE_FARMING";
STATE_GOTO_COMFORT_POINT = "STATE_GOTO_COMFORT_POINT";

LinaRetreatThreshold = 0.5

STATE = STATE_IDLE;





function StateIdle(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(800,true);
    local pt = GetComfortPoint(creeps);

    if(npcBot:GetHealth()/npcBot:GetMaxHealth() < LinaRetreatThreshold) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        local mypos = npcBot:GetLocation();
        
        local d = GetUnitToLocationDistance(npcBot,pt);
        print("distance: " .. d);
        if(d > 200) then
            StateMachine.State = STATE_GOTO_COMFORT_POINT;
        else
            StateMachine.State = STATE_ATTACKING_CREEP;
        end
        return;
    end

    middle_point = Vector(0,0);
    npcBot:Action_AttackMove(middle_point);

end

function StateAttackingCreep(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(800,true);
    local pt = GetComfortPoint(creeps);

    if(npcBot:GetHealth()/npcBot:GetMaxHealth() < LinaRetreatThreshold) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        local mypos = npcBot:GetLocation();
        
        local d = GetUnitToLocationDistance(npcBot,pt);
        print("distance: " .. d);
        if(d > 200) then
            StateMachine.State = STATE_GOTO_COMFORT_POINT;
        else
            ConsiderAttackCreeps(creeps);
        end
        return;
    else
        StateMachine.State = STATE_IDLE;
        return;
    end
end

function StateRetreat(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    --[[
            I don't know how to Create a object of Location so I borrow one from GetLocation()

            Got Vector from marko.polo at http://dev.dota2.com/showthread.php?t=274301
    ]]
    home_pos = Vector(-7000,-7000);
    npcBot:Action_MoveToLocation(home_pos);

    if(npcBot:GetHealth() == npcBot:GetMaxHealth()) then
        StateMachine.State = STATE_IDLE;
        return;
    end
end

function StateGotoComfortPoint(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(800,true);
    local pt = GetComfortPoint(creeps);

    if(npcBot:GetHealth()/npcBot:GetMaxHealth() < LinaRetreatThreshold) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        local mypos = npcBot:GetLocation();
        
        local d = GetUnitToLocationDistance(npcBot,pt);
        print("distance: " .. d);
        if(d > 200) then
            print("mypos "..mypos[1]..mypos[2]);
            print("comfort_pt "..pt[1]..pt[2]);
            npcBot:Action_MoveToLocation(pt);
        else
            StateMachine.State = STATE_ATTACKING_CREEP;
        end
        return;
    else
        StateMachine.State = STATE_IDLE;
        return;
    end

end

-- useless now ignore it
function StateFarming(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end
end

StateMachine = {};
StateMachine["State"] = STATE_IDLE;
StateMachine[STATE_IDLE] = StateIdle;
StateMachine[STATE_ATTACKING_CREEP] = StateAttackingCreep;
StateMachine[STATE_RETREAT] = StateRetreat;
StateMachine[STATE_GOTO_COMFORT_POINT] = StateGotoComfortPoint;

LinaAbilityPriority = {"lina_laguna_blade",
"lina_dragon_slave","lina_light_strike_array","lina_fiery_soul"};

function ThinkLvlupAbility()
    -- Is there a bug? http://dev.dota2.com/showthread.php?t=274436
    local npcBot = GetBot();
    --[[
        npcBot:Action_LevelAbility("lina_laguna_blade");
    npcBot:Action_LevelAbility("lina_dragon_slave");
    npcBot:Action_LevelAbility("lina_light_strike_array");
    npcBot:Action_LevelAbility("lina_fiery_soul");
    ]]

    for _,AbilityName in pairs(LinaAbilityPriority)
    do
        -- USELESS BREAK : because valve does not check ability points
        if TryToUpgradeAbility(AbilityName) then
            break;
        end
    end
    
    
end

function Think(  )
    -- Think this item( ... )
    --update
    local npcBot = GetBot();
    --print("dragon_slave damage:" .. npcBot:GetAbilityByName( "lina_dragon_slave" ):GetAbilityDamage());
    print("BotTarget:"..type(npcBot:GetTarget()));
    ThinkLvlupAbility();
    StateMachine[StateMachine.State](StateMachine);
    print("STATE: "..StateMachine.State);
	
end

function ConsiderAttackCreeps(creeps)
    -- there are creeps try to attack them --
    print("ConsiderAttackCreeps");
    local npcBot = GetBot();

    -- Check if we're already using an ability
	if ( npcBot:IsUsingAbility() ) then return end;

    local abilityLSA = npcBot:GetAbilityByName( "lina_light_strike_array" );
	local abilityDS = npcBot:GetAbilityByName( "lina_dragon_slave" );
	local abilityLB = npcBot:GetAbilityByName( "lina_laguna_blade" );

    -- Consider using each ability
    
	local castLBDesire, castLBTarget = ConsiderLagunaBlade(abilityLSA);
	local castLSADesire, castLSALocation = ConsiderLightStrikeArray(abilityLB);
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

    print("desires: " .. castLBDesire .. " " .. castLSADesire .. " " .. castDSDesire);

    --If we dont cast ability, just try to last hit.

    local lowest_hp = 100000;
    for creep_k,creep in pairs(creeps)
    do 
        --npcBot:GetEstimatedDamageToTarget
        local creep_name = creep:GetUnitName();
        -- "bad" means "dire" and "good" means "radian"
        local badpos = string.find( creep_name,"bad");
        if(creep:IsAlive() == false) then
            print("dead creep");
        end
        if(badpos ~= nil and creep:IsAlive()) then
             local creep_hp = creep:GetHealth();
             if(lowest_hp > creep_hp) then
                 lowest_hp = creep_hp;
                 weakest_creep = creep;
             end
         end
    end

    if(weakest_creep ~= nil) then
        -- if creep's hp is lower than 70(because I don't Know how much is my damadge!!), try to last hit it.
        if(Attacking_creep ~= weakest_creep and lowest_hp < 70) then
            Attacking_creep = weakest_creep;
            npcBot:Action_AttackUnit(Attacking_creep,true);
            StateMachine.State = STATE_ATTACKING_CREEP;
        end
    end

    weakest_creep = nil;
end

function GetComfortPoint(creeps)
    local npcBot = GetBot();
    local mypos = npcBot:GetLocation();
    local x_pos_sum = 0;
    local y_pos_sum = 0;
    local count = 0;
    for creep_k,creep in pairs(creeps)
    do
        local creep_name = creep:GetUnitName();
        local meleepos = string.find( creep_name,"melee");
        --if(meleepos ~= nil) then
        if(true) then
            creep_pos = creep:GetLocation();
            x_pos_sum = x_pos_sum + creep_pos[1];
            y_pos_sum = y_pos_sum + creep_pos[2];
            count = count + 1;
        end
    end

    local avg_pos_x = x_pos_sum / count;
    local avg_pos_y = y_pos_sum / count;

    if(count > 0) then
        -- I assume ComfortPoint is 600 from the avg point 
        print("avg_pos : " .. avg_pos_x .. " , " .. avg_pos_y);
        return Vector(avg_pos_x - 600 / 1.414,avg_pos_y - 600 / 1.414);
    else
        return nil;
    end;
end


function TryToUpgradeAbility(AbilityName)
    local npcBot = GetBot();
    local ability = npcBot:GetAbilityByName(AbilityName);
    if ability:CanAbilityBeUpgraded() then
        ability:UpgradeAbility();
        return true;
    end
    return false;
end

-- How to get iTree handles?
function IsItemAvailable(item_name)
    local npcBot = GetBot();
    -- query item code by Hewdraw
    for i = 0, 5, 1 do
        local item = hero:GetItemInSlot(i);
        if(item and item:IsFullyCastable() and item:GetName() == item_name) then
            return item;
        end
    end
    return nil;
end