if (false) then

math.randomseed(RealTime())

_G.RetreatDesire = math.random()

function GetDesire()
    return _G.RetreatDesire
end


function OnStart()
    _G.state = "retreat"
end

end