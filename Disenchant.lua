-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Disenchant integration.
--

local Me = DiceMaster4
local Profile = Me.Profile

function Me.Disenchant_ProduceDust( itemQuality, itemData )

	if not ( itemQuality ) then
		return
	end
	
	local currencies = Me.Profile.currency
	local currency = false; 
	for i = 1, #currencies do
		if currencies[i] and currencies[i].guid == "ARCANE_DUST" then
			currency = currencies[i];
			break
		end
	end
	if not currency then
		local currency = {
			name = "Arcane Dust";
			icon = "Interface/AddOns/DiceMaster/Texture/arcane-dust-icon";
			description = "A raw, magical resource extracted from disenchanting an item. Can be used to craft or enchant items, or exchanged for goods provided by the Arcane Sanctum.";
			value = 0;
			guid = "ARCANE_DUST";
			author = "ARCANE_DUST";
		};
		tinsert( Me.Profile.currency, currency )
	end
	PlaySound(1204)
	local item = Me.NewItem()
	item.SetName("Arcane Dust")
	item.SetIcon("Interface/AddOns/DiceMaster/Icons/ArcaneDust")
	item.SetQuality( 1 )
	item.SetStackSize( 20 )
	item.SetStackCount( itemQuality - 1 )
	item.SetUseText("Use: Deposit |cFFFFFFFF1|r |TInterface/AddOns/DiceMaster/Texture/arcane-dust-icon:12|t into your inventory.")
	item.SetFlavourText("A raw, magical resource extracted from disenchanting an item. Can be used to craft or enchant items, or exchanged for goods provided by the Arcane Sanctum.")
	item.SetConsumed( true )
	local currency = {
		type = "currency";
		name = "Arcane Dust";
		icon = "Interface/AddOns/DiceMaster/Texture/arcane-dust-icon";
		description = "A raw, magical resource extracted from disenchanting an item. Can be used to craft or enchant items, or exchanged for goods provided by the Arcane Sanctum.";
		count = 1;
		guid = "ARCANE_DUST";
		author = "ARCANE_DUST";
	};
	tinsert( item.effects, currency )
	item.SetGUID( "ARCANE_DUST" )
	item.Save()
	
	if ( itemData ) then
		Me.DeleteItem( itemData.guid, itemData.stackCount )
	end
end

function Me.Disenchant_DisenchantItem( item )
	if not item or not item.canDisenchant or not Me.PermittedUse() then
		return
	end
	
	if not ( item.quality > 1 ) or not ( item.quality < 6 ) then
		return
	end
	
	Dismount()
	Me.CastBar( "cast", "Disenchant", nil, 1.5, false, 27 )
	DiceMasterCastingBarFrame["OnFinished"] = function() 		
		Me.Disenchant_ProduceDust( item.quality, item )
	end
end