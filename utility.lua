local M = {}

M["PointsOnLane"] = {}

local function InitPointsOnLane(PointsOnLane)
    for i = 1, 3, 1 do
        PointsOnLane[i] = {};
        for j = 0, 100, 1 do
            PointsOnLane[i][j] = GetLocationAlongLane(i,j / 100.0);
        end
    end
end

InitPointsOnLane(M["PointsOnLane"]);


function M.NilOrDead(Unit)
    return Unit == nil or not Unit:IsAlive();
end

function M.AbilityOutOfRange4Unit(Ability,Unit)
    return GetUnitToUnitDistance(GetBot(),Unit) > Ability:GetCastRange();
end

function M.AbilityOutOfRange4Location(Ability,Location)
    return GetUnitToLocationDistance(GetBot(),Location) > Ability:GetCastRange();
end

function M:GetNearByPrecursorPointOnLane(Lane,Location)
    local npcBot = GetBot();
    local Pos = npcBot:GetLocation();
    if Location ~= nil then
        Pos = Location;
    end
    
    local PointsOnLane =  self["PointsOnLane"][Lane];
    local prevDist = (Pos - PointsOnLane[0]):Length2D();
    for i = 1,100,1 do
        local d = (Pos - PointsOnLane[i]):Length2D();
        if(d > prevDist) then
            if i >= 4 then
                return PointsOnLane[i - 4] + RandomVector(50);
            else
                return PointsOnLane[i - 1];
            end
        else
            prevDist = d;
        end
    end

    return PointsOnLane[100];
end

function M:GetNearBySuccessorPointOnLane(Lane,Location)
    local npcBot = GetBot();
    local Pos = npcBot:GetLocation();
    if Location ~= nil then
        Pos = Location;
    end
    
    local PointsOnLane =  self["PointsOnLane"][Lane];
    local prevDist = (Pos - PointsOnLane[100]):Length2D();
    for i = 100,0,-1 do
        local d = (Pos - PointsOnLane[i]):Length2D();
        if(d > prevDist) then
            if i <= 96 then
                return PointsOnLane[i + 4] + RandomVector(100);
            else
                return PointsOnLane[i + 1];
            end
        else
            prevDist = d;
        end
    end

    return PointsOnLane[0];
end

function M.IsItemAvailable(item_name)
    local npcBot = GetBot();
    -- query item code by Hewdraw
    for i = 0, 5, 1 do
        local item = npcBot:GetItemInSlot(i);
        if(item and item:GetName() == item_name) then
            return item;
        end
    end
    return nil;
end

function M:GetComfortPoint(creeps,LANE)
    local npcBot = GetBot();
    local mypos = npcBot:GetLocation();
    local x_pos_sum = 0;
    local y_pos_sum = 0;
    local count = 0;
    local meele_coefficient = 5;-- Consider meele creeps first
    local coefficient = 1;
    for creep_k,creep in pairs(creeps)
    do
        local creep_name = creep:GetUnitName();
        local meleepos = string.find( creep_name,"melee");
        if(meleepos ~= nil) then
            coefficient = meele_coefficient;
        else
            coefficient = 1;
        end

        creep_pos = creep:GetLocation();
        x_pos_sum = x_pos_sum + coefficient * creep_pos[1];
        y_pos_sum = y_pos_sum + coefficient * creep_pos[2];
        count = count + coefficient;
    end

    local avg_pos_x = x_pos_sum / count;
    local avg_pos_y = y_pos_sum / count;

    if(count > 0) then      
        return self:GetNearByPrecursorPointOnLane(LANE,Vector(avg_pos_x,avg_pos_y)) + RandomVector(20);
    else
        return nil;
    end;
end

function M:HasEmptySlot()
    local npcBot = GetBot();
    -- query item code by Hewdraw
    for i = 0, 5, 1 do
        local item = npcBot:GetItemInSlot(i);
        if(item == nil) then
            return true;
        end
    end
    return false;
end

function M:CourierThink()
    local npcBot = GetBot();
    for i = 9, 15, 1 do
        local item = npcBot:GetItemInSlot(i);
        if((item ~= nil or npcBot:GetCourierValue() > 0) and IsCourierAvailable()) then
            --print("got item");
            npcBot:Action_CourierDeliver();
            return;
        end
    end
end

function M:GetFrontTowerAtMid()
    local tower = GetTower(GetTeam(),TOWER_MID_1);
    if(tower ~= nil and tower:IsAlive())then
        return tower;
    end

    tower = GetTower(GetTeam(),TOWER_MID_2);
    if(tower ~= nil and tower:IsAlive())then
        return tower;
    end

    tower = GetTower(GetTeam(),TOWER_MID_3);
    if(tower ~= nil and tower:IsAlive())then
        return tower;
    end
    return nil;
end

function M:CreepGC()
    print("CreepGC");
    local swp_table = {}
    for handle,time_health in pairs(self["creeps"])
    do
        local rm = false;
        for t,_ in pairs(time_health)
        do
            if(GameTime() - t > 60) then
                rm = true;
            end
            break;
        end
        if not rm then
            swp_table[handle] = time_health;
        end
    end

    self["creeps"] = swp_table;
end

function M:UpdateCreepHealth(creep)
    if self["creeps"] == nil then
        self["creeps"] = {};
    end

    if(self["creeps"][creep] == nil) then
        self["creeps"][creep] = {};
    end
    if(creep:GetHealth() < creep:GetMaxHealth()) then
        self["creeps"][creep][GameTime()] = creep:GetHealth();
    end

    if(#self["creeps"] > 1000) then
        self:CreepGC();
    end
end

function pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0                 -- iterator variable
    local iter = function ()    -- iterator function
       i = i + 1
       if a[i] == nil then return nil
       else return a[i], t[a[i]]
       end
    end
    return iter
end

function sortFunc(a , b)
    if a < b then 
        return true
    end
end

function M:GetCreepHealthDeltaPerSec(creep)
    if self["creeps"] == nil then
        self["creeps"] = {};
    end

    if(self["creeps"][creep] == nil) then
        return 10000000;
    else
        for _time,_health in pairsByKeys(self["creeps"][creep],sortFunc)
        do
            -- only Consider very recent datas
            if(GameTime() - _time < 3) then
                local e = (_health - creep:GetHealth()) / (GameTime() - _time);
                print("esstimation: " .. e);
                return e;
            end
        end
        return 10000000;
    end

end

function M:ConsiderRunAway()
    local npcBot = GetBot();
    local enemy = npcBot:GetNearbyHeroes( 600, true, BOT_MODE_NONE );
    if(#enemy > 1 and DotaTime() > 360) then
        return true;
    end
    return false;
end

return M;