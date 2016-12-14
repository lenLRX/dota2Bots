STATE_IDLE = "STATE_IDLE";
STATE_ATTACKING_CREEP = "STATE_ATTACKING_CREEP";
STATE_KILL = "STATE_KILL";
STATE_RETREAT = "STATE_RETREAT";

LinaRetreatThreshold = 0.5

STATE = STATE_IDLE;



function StateIdle(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(800,true);

    if(npcBot:GetHealth()/npcBot:GetMaxHealth() < LinaRetreatThreshold) then
        StateMachine.State = STATE_RETREAT;
        local LocationMetaTable = getmetatable(npcBot:GetLocation());
        home_pos = npcBot:GetLocation();
        home_pos[1] = -7000.0;
        home_pos[2] = -7000.0;
        npcBot:Action_MoveToLocation(home_pos);
        return;
    elseif(#creeps > 0) then
        ConsiderAttackCreeps(creeps);
    else
        local LocationMetaTable = getmetatable(npcBot:GetLocation());
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

    if(npcBot:GetHealth()/npcBot:GetMaxHealth() < LinaRetreatThreshold) then
        StateMachine.State = STATE_RETREAT;
        local LocationMetaTable = getmetatable(npcBot:GetLocation());
        home_pos = npcBot:GetLocation();
        home_pos[1] = -7000.0;
        home_pos[2] = -7000.0;
        npcBot:Action_MoveToLocation(home_pos);
        return;
    elseif(#creeps > 0) then
        ConsiderAttackCreeps(creeps);
    else
        local LocationMetaTable = getmetatable(npcBot:GetLocation());
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

StateMachine = {};
StateMachine["State"] = STATE_IDLE;
StateMachine[STATE_IDLE] = StateIdle;
StateMachine[STATE_ATTACKING_CREEP] = StateAttackingCreep;
StateMachine[STATE_RETREAT] = StateRetreat;

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
    local npcBot = GetBot();
    local lowest_hp = 100000;
    for creep_k,creep in pairs(creeps)
    do 
        --npcBot:GetEstimatedDamageToTarget
        local creep_name = creep:GetUnitName();
        local badpos = string.find( creep_name,"bad");
        if(badpos ~= nil) then
             local creep_hp = creep:GetHealth();
             if(lowest_hp > creep_hp) then
                 lowest_hp = creep_hp;
                 weakest_creep = creep;
             end
         end
    end

    if(weakest_creep ~= nil) then
        if(Attacking_creep ~= weakest_creep) then
            Attacking_creep = weakest_creep;
            npcBot:Action_AttackUnit(Attacking_creep,true);
            StateMachine.State = STATE_ATTACKING_CREEP;
        end
    end

    weakest_creep = nil;
end

function CanLastHitTarget(target)
    local npcBot = GetBot();
    local damage = npcBot:GetEstimatedDamageToTarget(target);
end