
--"item_flask" == heal flask

local tableItemsToBuy = { 
				"item_mantle",
				"item_circlet",
				"item_recipe_null_talisman",
				"item_blight_stone",
				"item_boots",
				"item_staff_of_wizardry",
				"item_wind_lace",
				"item_void_stone",
				"item_recipe_cyclone",
				"item_robe",
				"item_gloves",
				"item_gloves",
				"item_branches",
				"item_ring_of_regen",
				"item_recipe_headdress",
				"item_recipe_helm_of_the_dominator",
				"item_gloves",
				"item_mithril_hammer",
				"item_recipe_maelstrom",
				"item_mithril_hammer",
				"item_mithril_hammer"
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
