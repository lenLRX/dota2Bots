
--"item_flask" == heal flask

local tableItemsToBuy = { 
				"item_mantle",
				"item_circlet",
				"item_recipe_null_talisman",
				"item_bottle",
				"item_boots",
				"item_sobi_mask",
				"item_ring_of_regen",
                "item_recipe_soul_ring",
				"item_recipe_travel_boots",
				"item_staff_of_wizardry",
				"item_recipe_dagon",
				"item_staff_of_wizardry",
				"item_wind_lace",
				"item_void_stone",
				"item_recipe_cyclone"
			};


----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
    local npcBot = GetBot();
	if ( #tableItemsToBuy == 0 )
	then
		npcBot:SetNextItemPurchaseValue( 0 );
		return;
	end

	local sNextItem = tableItemsToBuy[1];
	

	npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

	if ( npcBot:GetGold() >= GetItemCost( sNextItem ) )
	then
		npcBot:Action_PurchaseItem( sNextItem );
		table.remove( tableItemsToBuy, 1 );
	end

end

----------------------------------------------------------------------------------------------------
