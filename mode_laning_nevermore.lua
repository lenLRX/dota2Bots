if (false and GetTeam() == TEAM_RADIANT ) then
math.randomseed(RealTime())

_G.LaningDesire = math.random()

function GetDesire()
    return _G.LaningDesire
end

function OnStart()
    _G.state = "laning"
end

end