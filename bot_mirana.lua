local DotaBotUtility = require(GetScriptDirectory().."/utility");

function Think(  )
    --dummy function
    local courier = DotaBotUtility.IsItemAvailable("item_courier");
    if(courier ~= nil) then
        GetBot():Action_UseAbility(courier);
    end
end