--[[
    StateMachine is a table
    the key "STATE" stores the STATE of Lina 
    other key value pairs: key is the string of state value is the function of the State. 

    each frame DOTA2 will call Think()
    Then Think() will call the function of current state.
]]


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
        --[[
            I don't know how to Create a object of Location so I borrow one from GetLocation()
        ]]
        home_pos = npcBot:GetLocation();
        home_pos[1] = -7000.0;
        home_pos[2] = -7000.0;
        npcBot:Action_MoveToLocation(home_pos);
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        local mypos = npcBot:GetLocation();
        local pt = GetComfortPoint(creeps);
        local d = dist2d({mypos[1],mypos[2]},pt);
        print("distance: " .. d);
        if(d > 200) then
            StateMachine.State = STATE_GOTO_COMFORT_POINT;
        else
            StateMachine.State = STATE_ATTACKING_CREEP;
        end
    else
        middle_point = npcBot:GetLocation();
        middle_point[1] = 1.0;
        middle_point[2] = 1.0;
        npcBot:Action_AttackMove(middle_point);
    end

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
        home_pos = npcBot:GetLocation();
        home_pos[1] = -7000.0;
        home_pos[2] = -7000.0;
        npcBot:Action_MoveToLocation(home_pos);
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        local mypos = npcBot:GetLocation();
        local pt = GetComfortPoint(creeps);
        local d = dist2d({mypos[1],mypos[2]},pt);
        print("distance: " .. d);
        if(d > 200) then
            StateMachine.State = STATE_GOTO_COMFORT_POINT;
        else
            ConsiderAttackCreeps(creeps);
        end
    else
        middle_point = npcBot:GetLocation();
        middle_point[1] = 1.0;
        middle_point[2] = 1.0;
        npcBot:Action_AttackMove(middle_point);
        StateMachine.State = STATE_IDLE;
    end
end

function StateRetreat(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

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
        home_pos = npcBot:GetLocation();
        home_pos[1] = -7000.0;
        home_pos[2] = -7000.0;
        npcBot:Action_MoveToLocation(home_pos);
        return;
    elseif(#creeps > 0 and pt ~= nil) then
        local mypos = npcBot:GetLocation();
            
        local d = dist2d({mypos[1],mypos[2]},pt);
        print("distance: " .. d);
        if(d > 200) then
            local comfort_pt = mypos;
            comfort_pt[1] = pt[1];
            comfort_pt[2] = pt[2];
            print("mypos "..mypos[1]..mypos[2]);
            print("comfort_pt "..comfort_pt[1]..comfort_pt[2]);
            npcBot:Action_MoveToLocation(comfort_pt);
        else
            StateMachine.State = STATE_ATTACKING_CREEP;
        end
    else
        middle_point = npcBot:GetLocation();
        middle_point[1] = 1.0;
        middle_point[2] = 1.0;
        npcBot:Action_AttackMove(middle_point);
        StateMachine.State = STATE_IDLE;
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

function ThinkLvlupAbility()
    -- Is there a bug? http://dev.dota2.com/showthread.php?t=274436
    local npcBot = GetBot();
    npcBot:Action_LevelAbility("lina_laguna_blade");
    npcBot:Action_LevelAbility("lina_dragon_slave");
    npcBot:Action_LevelAbility("lina_light_strike_array");
    npcBot:Action_LevelAbility("lina_fiery_soul");
end

function Think(  )
    -- Think this item( ... )
    --update
    ThinkLvlupAbility();
    StateMachine[StateMachine.State](StateMachine);
    print("STATE: "..StateMachine.State);
	
end

function ConsiderAttackCreeps(creeps)
    -- there are creeps try to attack them --
    print("ConsiderAttackCreeps");
    local npcBot = GetBot();
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

    if(Attacking_creep ~= nil and Attacking_creep:IsAlive() == false)then
        Attacking_creep = nil;
    end

    weakest_creep = nil;
end

function CanLastHitTarget(target)
    local npcBot = GetBot();
    local damage = npcBot:GetEstimatedDamageToTarget(target);
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
        return {avg_pos_x - 600 / 1.414,avg_pos_y - 600 / 1.414};
    else
        return nil;
    end;
end

function dist2d(pt1,pt2)
    return math.sqrt((pt1[1] - pt2[1]) * (pt1[1] - pt2[1]) + (pt1[2] - pt2[2]) * (pt1[2] - pt2[2]));
end