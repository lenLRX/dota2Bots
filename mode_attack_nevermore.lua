if (false) then

math.randomseed(RealTime())

_G.AttackDesire = math.random()

function GetDesire()
    return _G.AttackDesire
end

end


function OnStart()
    _G.state = "attack"
end