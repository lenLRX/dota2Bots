math.randomseed(RealTime())

_G.RoamDesire = math.random()

function GetDesire()
    return 0
end

function OnStart()
    _G.state = "roam"
end
