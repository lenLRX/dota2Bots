if (false) then
math.randomseed(RealTime())

_G.FarmDesire = math.random()

function GetDesire()
    return 0
end

function OnStart()
    _G.state = "farm"
end

end