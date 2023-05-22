-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Disenchant integration.
--

local Me = DiceMaster4
local Profile = Me.Profile

local yields = {
	{1,3}, {2,4}, {3,5}
};

function Me.Disenchant_ProduceDust( itemQuality )
	if not( itemQuality ) then
		return
	end
	local yield = random(yields[itemQuality - 1][1], yields[itemQuality - 1][2]);
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
	item.SetStackSize( 100 )
	item.SetStackCount( yield )
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
end

local function Disenchant( slot, button )
	local item = Me.Profile.inventory[slot];
	if not item or not item.canDisenchant or not Me.PermittedUse() then
		return
	end

	item.stackCount = item.stackCount - 1;

	Me.UIInteractFX( button );
	Me.Disenchant_ProduceDust( item.quality );
	Me.MaintainItemAmounts( item.guid );
end

function Me.Disenchant_DisenchantItem( slot, button )
	local item = Me.Profile.inventory[slot];
	if not item or not item.canDisenchant or not Me.PermittedUse() then
		return
	end
	
	if not ( item.quality > 1 ) or not ( item.quality < 6 ) then
		return
	end
	
	Dismount()
	Me.CastBar( "cast", "Disenchant", nil, 1.5, false, 27 )
	DiceMasterCastingBarFrame["OnFinished"] = function() 		
		Disenchant( slot, button )
	end
end