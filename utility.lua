local M = {}

function M.NilOrDead(unit)
    return unit == nil or not unit:IsAlive();
end

return M;