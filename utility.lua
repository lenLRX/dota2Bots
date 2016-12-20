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
                return PointsOnLane[i - 4];
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
                return PointsOnLane[i + 4];
            else
                return PointsOnLane[i + 1];
            end
        else
            prevDist = d;
        end
    end

    return PointsOnLane[0];
end



return M;