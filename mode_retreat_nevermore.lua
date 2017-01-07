if (false and  GetTeam() == TEAM_RADIANT ) then

math.randomseed(RealTime())

_G.RetreatDesire = math.random()

function GetDesire()
    return _G.RetreatDesire
end

end

if (GetTeam() == TEAM_RADIANT ) then

function OnStart()
    _G.state = "retreat"
end

end