local M = {}

function M.HomePosition()
    if ( GetTeam() == TEAM_RADIANT ) then
        return Vector(-7000,-7000);
    elseif ( GetTeam() == TEAM_DIRE ) then
        return Vector(7200,6500);
    end
end

return M;