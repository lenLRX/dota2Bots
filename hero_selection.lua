

----------------------------------------------------------------------------------------------------
offset = 2;
function Think()


	if ( GetTeam() == TEAM_RADIANT )
	then
		print( "selecting radiant" );
		SelectHero( 0 + offset, "npc_dota_hero_nevermore" );
		SelectHero( 1 + offset, "npc_dota_hero_sven" );
		SelectHero( 2 + offset, "npc_dota_hero_sven" );
		SelectHero( 3 + offset, "npc_dota_hero_sven" );
		SelectHero( 4 + offset, "npc_dota_hero_sven" );
	elseif ( GetTeam() == TEAM_DIRE )
	then
		print( "selecting dire" );
		SelectHero( 5 + offset, "npc_dota_hero_nevermore" );
		SelectHero( 6 + offset, "npc_dota_hero_sven" );
		SelectHero( 7 + offset, "npc_dota_hero_sven" );
		SelectHero( 8 + offset, "npc_dota_hero_sven" );
		SelectHero( 9 + offset, "npc_dota_hero_sven" );
	end

end

if ( GetTeam() == TEAM_DIRE ) then
    function UpdateLaneAssignments()
	    return {
			[5 + offset] = LANE_MID,
			[6 + offset] = LANE_MID,
			[7 + offset] = LANE_MID,
			[8 + offset] = LANE_MID,
			[9 + offset] = LANE_MID
		}
	end
end

----------------------------------------------------------------------------------------------------
