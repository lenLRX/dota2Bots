
--"item_flask" == heal flask

local tableItemsToBuy = { 
				"item_mantle",
				"item_circlet",
				"item_recipe_null_talisman",
				"item_boots",
				"item_recipe_travel_boots",
                "item_ring_of_regen",
                "item_sobi_mask",
                "item_recipe_soul_ring"
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
