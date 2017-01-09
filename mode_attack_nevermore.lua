if (false and GetTeam() == TEAM_RADIANT ) then

math.randomseed(RealTime())

_G.AttackDesire = math.random()

function GetDesire()
    print("_G.AttackDesire",_G.AttackDesire)
    return _G.AttackDesire
end

end

if (GetTeam() == TEAM_RADIANT ) then

function OnStart()
    _G.state = "attack"
end

end