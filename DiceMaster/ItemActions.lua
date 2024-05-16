-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

-- Item Actions

local Me = DiceMaster4 
local Profile = Me.Profile

local ITEM_QUALITIES = {
	"Poor",
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Artifact",
	"Heirloom",
}

local ITEM_STACK_SIZES = {
	1,
	5,
	10,
	20,
	100,
	200,
}

local ITEM_COOLDOWNS = {
	{name = "1 sec", time = 1},
	{name = "10 sec", time = 10},
	{name = "15 sec", time = 15},
	{name = "20 sec", time = 20},
	{name = "30 sec", time = 30},
	{name = "45 sec", time = 45},
	{name = "1 min", time = 60},
	{name = "2 min", time = 120},
	{name = "5 min", time = 300},
	{name = "10 min", time = 600},
	{name = "15 min", time = 900},
	{name = "20 min", time = 1200},
	{name = "30 min", time = 1800},
	{name = "45 min", time = 2700},
	{name = "1 hour", time = 3600},
	{name = "2 hours", time = 7200},
	{name = "3 hours", time = 10800},
	{name = "4 hours", time = 10800},
	{name = "5 hours", time = 18000},
	{name = "6 hours", time = 21600},
	{name = "12 hours", time = 43200},
	{name = "1 day", time = 86400},
}

local ITEM_BIND_TYPES = {
	"Binds when picked up",
	"Binds when equipped",
	"Binds when used",
}

local BUFF_DURATION_AMOUNTS = {
	{name = "15 sec", time = 15},
	{name = "30 sec", time = 30},
	{name = "45 sec", time = 45},
	{name = "1 min", time = 60},
	{name = "2 min", time = 120},
	{name = "5 min", time = 300},
	{name = "10 min", time = 600},
	{name = "15 min", time = 900},
	{name = "30 min", time = 1800},
	{name = "45 min", time = 2700},
	{name = "1 hour", time = 3600},
	{name = "2 hours", time = 7200},
	{name = "3 hours", time = 10800},
	{name = "1 turn", turns = 1},
	{name = "2 turns", turns = 2},
	{name = "3 turns", turns = 3},
	{name = "4 turns", turns = 4},
	{name = "5 turns", turns = 5},
	{name = "6 turns", turns = 6},
	{name = "7 turns", turns = 7},
	{name = "8 turns", turns = 8},
	{name = "9 turns", turns = 9},
	{name = "10 turns", turns = 10},
}

---------------------------------------------------------------------------
-- Get the GUID identifier for a given unit.
--

local function GetUnitGUID( unit )
	local guid = UnitGUID( unit )
	if not( guid ) then
		return;
	end
	if not( string.find( guid, "-" ) ) then
		return guid;
	end
	
	local guidType, realmID, unitID = strsplit( "-", guid );
	return unitID;
end;

---------------------------------------------------------------------------
-- Generate a unique GUID identifier for an item.
--

local function GenerateGUID()
	local lastTime;
	local guid;
	
	if not (guid) then
		guid = string.gsub(string.gsub(GetUnitGUID("player"), "0x..", ""), "00[0]*", "")
	end

	local t = time();
	if t == 0 and not(lastTime) then
		t = random(100000);
	else
		t = t - 1315000000;
	end

	if lastTime and t <= lastTime then
		t = lastTime + 1;
	end
	lastTime = t;

	local hashTime = string.format("%X", t)
	
	return guid .. "_" .. hashTime;
end

---------------------------------------------------------------------------
-- Builds a table of all item stack data for items with the given GUID.
--
-- @param guid			string		The unique guid of the item
-- @returns stacks		table 		A table containing the item data for each stack

function Me.FindAllStacks( guid )
	local t = {}
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == guid then
			t[i] = Me.Profile.inventory[i];
		end
	end
	return t;
end

---------------------------------------------------------------------------
-- Builds a table of all item slots with the given GUID.
--
-- @param guid			string		The unique guid of the item
-- @returns stacks		table 		A table containing the item data for each stack

function Me.FindAllStackSlots( guid )
	local t = {}
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == guid then
			t[i] = Me.Profile.inventory[i];
		end
	end
	return t;
end

---------------------------------------------------------------------------
-- Find the amount of stacks of an item in the inventory.
--
-- Note: This differs from Me.FindTotalAmount() which returns the total amount
-- of an item.
--
-- @param guid			string		The unique guid of the item
-- @returns amount		number 		Amount of stacks of the item

function Me.FindTotalStacks( guid )
	local c = 0
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == guid then
			c = c + 1
		end
	end
	return c;
end

---------------------------------------------------------------------------
-- Find the total amount of an item in the inventory.
--
-- Note: This differs from Me.FindTotalStacks() which only returns the number
-- of stacks of an item.
--
-- @param guid			string		The unique guid of the item
-- @returns amount		number 		Total amount of the item

function Me.FindTotalAmount( guid )
	local c = 0
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == guid then
			c = c + Me.Profile.inventory[i].stackCount
		end
	end
	return c;
end

---------------------------------------------------------------------------
-- Find the item data of the first stack of an item in the inventory.
--
-- @param guid			string		The unique guid of the item
-- @returns itemData		table 		Item data table

function Me.FindFirstStack( guid )
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == guid then
			return Me.Profile.inventory[i];
		end
	end
	return false;
end

---------------------------------------------------------------------------
-- Find the index of the first stack of an item in the inventory.
--
-- @param guid			string		The unique guid of the item
-- @param player		string		The name of the player who has the item
-- @returns slotID		number 		Index of first stack 

function Me.FindFirstStackSlot( guid, player )
	if not player then
		player = UnitName("player")
	end
	for i = 1, 42 do
		if Me.inspectData[player].inventory[i] and Me.inspectData[player].inventory[i].guid == guid then
			return i;
		end
	end
	return false;
end

---------------------------------------------------------------------------
-- Find the first empty inventory slot.
--
-- @returns slotID		number 		Index of first unoccupied inventory slot

function Me.FindEmptySlot()
	for i = 1, 42 do
		if Me.Profile.inventory[i] == nil then
			return i;
		end
	end
	return false;
end

---------------------------------------------------------------------------
-- Get total number of empty inventory slots.
--
-- @returns slots	number 		Number of unoccupied inventory slots

function Me.FindTotalEmptySlots()
	local c = 42
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid then
			c = c - 1
		end
	end
	return c;
end

---------------------------------------------------------------------------
-- Get total number of empty bank slots.
--
-- @returns slots	number 		Number of unoccupied bank slots

function Me.FindTotalEmptyBankSlots()
	local c = 42
	for i = 1, 42 do
		if Me.db.global.bank[i] and Me.db.global.bank[i].guid then
			c = c - 1
		end
	end
	return c;
end

---------------------------------------------------------------------------
-- Get item data.
--
-- @param guid			string		The unique guid of the item
-- @returns itemData	table 		Item data table

function Me.GetItemInfo( guid )
	local item = Me.FindFirstStack( guid )
	
	if not( item )then
		return
	end

	local data = {}
	for k, v in pairs( item ) do
		data[k] = v;
	end
	
	return data;
end

---------------------------------------------------------------------------
-- Insert an item into the inventory.
--
-- @param item		table		Item data table
-- @param amount	number		Amount to insert

function Me.InsertItem( item, amount )
	if not item then
		return
	end
	
	local stacks = Me.FindAllStacks( item.guid );
	if ( stacks ) then
		for slot, stack in pairs( stacks ) do
			local maxAmount = stack.stackSize - stack.stackCount
			local deltaAmount = math.min( amount, maxAmount )
			
			if stack.stackCount + deltaAmount <= stack.stackSize then
				Me.Profile.inventory[slot].stackCount = Me.Profile.inventory[slot].stackCount + deltaAmount
				amount = amount - deltaAmount;
			end
		end
	end
	
	if amount > 0 and amount <= item.stackSize then
		local slot = Me.FindEmptySlot()
		
		if not( slot ) then
			UIErrorsFrame:AddMessage( "Inventory is full.", 1.0, 0.0, 0.0 ); 
			return
		end
		
		local data = {}
		for k, v in pairs( item ) do
			data[k] = v;
		end
		data.stackCount = amount
		Me.Profile.inventory[slot] = data
	end
	
	Me.TraitEditor_UpdateInventory()
end

---------------------------------------------------------------------------
-- Delete an item.
--
-- @param guid		string		The unique guid of the item
-- @param amount	number		Amount to delete

function Me.DeleteItem( guid, amount )
	local stacks = Me.FindAllStacks( guid )
	for slot, stack in pairs( stacks ) do
		if stack.stackCount >= amount then
			Me.Profile.inventory[slot].stackCount = stack.stackCount - amount;
			break;
		else
			amount = amount - stack.stackCount;
			Me.Profile.inventory[slot].stackCount = 0;
		end
	end
	Me.MaintainItemAmounts( guid );
end

---------------------------------------------------------------------------
-- Delete any empty item stacks.
--

function Me.MaintainItemAmounts( guid )
	local stacks = Me.FindAllStacks( guid )
	for slot, stack in pairs(stacks) do
		if stack.stackCount == 0 then
			Me.Profile.inventory[ slot ] = nil;
		end
	end
	Me.TraitEditor_UpdateInventory()
end

---------------------------------------------------------------------------
-- Update all item stacks when the data has been changed.
--

local UpdateAllItemStacks = function( item )
	if not item then
		return
	end
	
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == item.guid then
			for k, v in pairs( item ) do
				if Me.Profile.inventory[i][k] ~= item[k] and k~="stackCount" then
					Me.Profile.inventory[i][k] = item[k]
				end
			end
			if Me.Profile.inventory[i].stackCount > item.stackSize then
				Me.Profile.inventory[i].stackCount = item.stackSize
			end
		end
	end
	
	Me.TraitEditor_UpdateInventory()
end

---------------------------------------------------------------------------
-- Convert and sanitise item actions.
--

local GetSimpleActionFromArgs = function( actionType, ... )
	local args = {...};
	local info = {
		type = "script",
		code = "print('Unknown Action Type:" .. actionType .."')";
		delay = 0;
	}
	actionType = actionType:lower();
	
	if actionType == "script" then
		local code, delay = unpack( args );
		if not code or code == "" or type(code)~="string" then
			code = "";
		end
		if not delay or type(dela )~="number" or delay <= 0 then
			delay = 0;
		end
		info.type = "script";
		info.code = code;
		info.delay = delay;
	elseif actionType == "message" then
		local message, channel, delay = unpack( args );
		if not message or message == "" or type(message)~="string" then
			return
		end
		if not channel or type(channel) ~= "string" then
			channel = "SAY"
		end
		if not delay or type(delay)~="number" or delay <= 0 then
			delay = 0;
		end
		info.type = "message";
		info.message = message;
		info.channel = channel;
		info.delay = delay;
	elseif actionType == "produce" then
		local guid, amount, delay = unpack( args )
		if not guid or type(guid)~="string" then
			return
		end
		if not amount or type(amount)~="number" or amount <= 0 then
			amount = 1
		end
		local item = Me.FindFirstStack( guid )
		if not item then
			return
		end
		info.type = "produce";
		info.item = item;
		info.guid = guid;
		info.amount = amount;
		info.delay = delay;
	elseif actionType == "consume" then
		local guid, amount, delay = unpack( args )
		if not guid or type(guid)~="string" then
			return
		end
		if not amount or type(amount)~="number" or amount <= 0 then
			amount = 1
		end
		local item = Me.FindFirstStack( guid )
		if not item then
			return
		end
		info.type = "consume";
		info.item = item;
		info.guid = guid;
		info.amount = amount;
		info.delay = delay;
	elseif actionType == "currency" then
		local guid, amount = unpack( args )
		if not guid or type(guid)~="string" then
			return
		end
		if not amount or type(amount)~="number" or amount <= 0 then
			amount = 1
		end
		local currencies = Me.Profile.currency
		local currency = false; 
		for i = 1, #currencies do
			if currencies[i] and currencies[i].guid == guid and ( not currencies[i].author or currencies[i].author == UnitName("player") ) then
				currency = currencies[i];
				break
			end
		end
		if not currency then
			return
		end
		info.type = "currency";
		info.name = currency.name;
		info.icon = currency.icon;
		info.author = currency.author;
		info.guid = currency.guid;
		info.count = amount;
	elseif actionType == "buff" then
		local name, icon, desc, cancelable, duration, target, aoe, range, stackable, skill, skillRank = unpack( args );
		if not name or name == "" or type(name)~="string" then
			return
		end
		info.type = "buff";
		info.name = name;
		info.icon = icon or "Interface/Icons/inv_misc_questionmark";
		info.desc = desc or "";
		info.cancelable = cancelable or true;
		if cancelable then
			info.duration = duration;
		else
			info.duration = 1;
		end
		info.target = target;
		if aoe then
			info.range = range;
		else
			info.range = 0;
		end
		info.stackable = stackable or false;
		info.skill = skill or "";
		info.skillRank = skillRank or 0;
	elseif actionType == "removebuff" then
		local name, count = unpack( args );
		if not name or name == "" or type(name)~="string" then
			return
		end
		info.type = "removebuff";
		info.name = name;
		info.count = count or 1;
	elseif actionType == "setdice" then
		local value, skill = unpack( args )
		if not value then
			value = "D20"
		end
		info.type = "setdice";
		info.value = value;
		info.skill = skill;
		info.blank = false;
	elseif actionType == "effect" then
		local effectID, target, delay = unpack( args )
		if not effectID or type(effectID)~="number" then
			return
		end
		if not delay or type(delay)~="number" or delay <= 0 then
			delay = 0;
		end
		info.type = "effect";
		info.effectID = effectID;
		info.effectName = "";
		info.target = target;
		info.delay = delay;
	elseif actionType == "screeneffect" then
		local texture, target, delay = unpack( args )
		if not texture or type(texture)~="string" then
			texture = Me.textureList["Mage"][1].file;
		end
		if not delay or type(delay)~="number" or delay <= 0 then
			delay = 0;
		end
		info.type = "screeneffect";
		info.target = target;
		info.texture = texture;
		info.delay = delay;
	elseif actionType == "sound" then
		local soundID, range, delay = unpack( args )
		if not soundID or type(soundID)~="number" then
			return
		end
		if not range or type(range)~="number" or range <= 0 then
			range = 0;
		end
		if not delay or type(delay)~="number" or delay <= 0 then
			delay = 0;
		end
		info.type = "sound";
		info.soundID = soundID;
		info.range = range;
		info.delay = delay;
	elseif actionType == "health" then
		local health, armour, delay = unpack( args )
		if not health or type(health)~="number" then
			health = 0;
		end
		if not armour or type(armour)~="number" then
			armour = 0;
		end
		if not delay or type(delay)~="number" or delay <= 0 then
			delay = 0;
		end
		info.type = "health";
		info.health = health;
		info.armour = armour;
		info.delay = delay;
	end
	return info
end

---------------------------------------------------------------------------
-- Generate the item API.
--

local GetItemAPI = function( item )
	local api = {};
	
	-- Access api
	api.SetRequiresDMApproval = function( requiresDMapproval )
		if type(requiresDMApproval)~="boolean" then
			return
		end

		item.requiresDMApproval = requiresDMApproval;
	end
	api.GetRequiresDMApproval = function()
		return item.requiresDMApproval
	end
	api.IsCopyable = function()
		return item.copyable
	end
	api.SetCopyable = function( copy )
		if type(copy)~="boolean" then
			return
		end
		
		item.copyable = copy;
	end
	api.IsConsumed = function()
		return item.consumeable
	end
	api.SetConsumed = function( consume )
		if type(consume)~="boolean" then
			return
		end
		
		item.consumeable = consume;
	end
	api.GetAuthor = function()
		return item.author
	end
	api.SetAuthor = function( author )
		if type(author)~="string" then
			return
		end
		
		item.author = author;
	end
	
	-- Basic
	api.GetTooltipText = function()
		return item.whiteText1, item.whiteText2, item.useText, item.flavorText
	end
	api.GetGUID = function()
		return item.guid
	end
	api.GetItemInfo = function()
		return item.name, item.icon, item.quality, item.itemBind, item.stackSize;
	end
	api.SetGUID = function( guid )
		if type(guid)~="string" then
			return
		end
		
		item.guid = guid;
	end
	api.SetIcon = function( icon )
		item.icon = icon or "Interface/Icons/inv_misc_questionmark";
	end
	api.SetName = function( name )
		item.name = name or "New Item";
	end
	api.SetQuality = function( quality )
		if type(quality)~="number" then	
			return
		end
		
		if not ITEM_QUALITIES[ quality ] then
			return
		end
		
		item.quality = quality
	end
	api.SetBinding = function( binding )
		if type(binding)~="number" then
			return
		end
		
		if not ITEM_BIND_TYPES[ binding ] then
			return
		end
		
		item.itemBind = binding;
	end
	api.SetUseText = function( useText )
		item.useText = useText or "";
	end
	api.SetStackCount = function( stackCount )
		if type(stackCount)~="number" then
			return
		end
		
		stackCount = Me.Clamp( stackCount, 1, item.stackSize )
		
		item.stackCount = stackCount;
	end
	api.SetStackSize = function( stackSize )
		if type(stackSize)~="number" then
			return
		end
		
		stackSize = Me.Clamp( stackSize, 1, 200 )
		
		for i = 1, #ITEM_STACK_SIZES do
			if stackSize == ITEM_STACK_SIZES[i] then
				item.stackSize = stackSize;
				if ( item.stackCount > item.stackSize ) then
					item.stackCount = item.stackSize
				end
				break
			end
		end
	end
	
	api.SetWhiteText1 = function( whiteText1 )
		item.whiteText1 = whiteText1 or ""
	end
	api.SetWhiteText2 = function( whiteText2 )
		item.whiteText2 = whiteText2 or ""
	end
	api.SetFlavorText = function( flavorText )
		item.flavorText = flavorText or nil;
	end
	api.SetFlavourText = function( flavorText )
		item.flavorText = flavorText or nil;
	end
	
	-- Cooldown
	api.GetCooldown = function()
		if time() - item.lastCastTime < item.cooldown then
			return item.cooldown, time() - item.lastCastTime
		end
		return item.cooldown
	end
	api.GetLastCastTime = function()
		return item.lastCastTime
	end
	api.IsOnCooldown = function()
		if time() - item.lastCastTime < item.cooldown then
			return true;
		end
		return false;
	end
	api.SetCooldown = function( cd )
		if type(cd)~="number" then
			return
		end
		
		cd = Me.Clamp( cd, 0, 86400 )
		
		if item.cooldown ~= cd then
			item.lastCastTime = 0
		end
		
		for i = 1, #ITEM_COOLDOWNS do
			if cd == ITEM_COOLDOWNS[i].time then
				item.cooldown = cd;
				break
			end
		end
	end
	api.SetLastCastTime = function( lastCastTime )
		if type(lastCastTime)~="number" then
			return
		end
		
		lastCastTime = math.max( 0, lastCastTime )
		
		item.lastCastTime = lastCastTime
	end
	
	-- Actions
	api.AddAction = function( actionInfo,... )
		if (type(actionInfo)=="table") then
			table.insert( item.effects, actionInfo )
		elseif (type(actionInfo)=="string") then
			table.insert( item.effects, GetSimpleActionFromArgs(actionInfo,...))
		end
	end
	api.GetAction = function( index )
		if item.effects[index] then
			return item.effects[index]
		end
	end
	api.GetActionCount = function()
		return #item.effects or 0;
	end
	api.RemoveAction = function( index )
		if item.effects[index] then
			table.remove( item.effects, index )
		end
	end

	-- Properties
	api.SetProperty = function( property, value )
		if (type(value)=="boolean") then
			item.properties[property] = value;
		end
	end
	api.GetProperty = function( property )
		return item.properties[property];
	end
	
	-- Disenchanting
	api.SetDisenchantable = function( canDisenchant )
		if type(canDisenchant)~="boolean" or not ( Me.PermittedUse() ) then
			return
		end
		
		item.canDisenchant = canDisenchant
	end
	
	return api;
end

---------------------------------------------------------------------------
-- Edit an existing item.
--
-- Note: You have to use the item.Save() function to save your edits.
--
-- @param guid		string		The unique guid of the item	

function Me.EditItem( guid )
	if not guid or type(guid) ~= "string" then
		return
	end
	
	local item = Me.GetItemInfo( guid )
	if not(item) then
		return
	end
	
	local api = GetItemAPI(item);
	api.Save = function()
		UpdateAllItemStacks( item )
	end
	for k, v in pairs( api ) do
		item[k] = v
	end
	
	local author = item.GetAuthor();
	if not( UnitName("player") == author ) then
		return
	end
	
	return item
end

---------------------------------------------------------------------------
-- Create data table for a new item.
--
-- Note: You have to use the item.Save() function to "create" the item.
-- This function just creates the data for a new item.
--
-- @returns itemData	table	Item data table

function Me.NewItem()

	if Me.FindTotalEmptySlots() < 1 then
		UIErrorsFrame:AddMessage( "Inventory is full.", 1.0, 0.0, 0.0 );
		return
	end

	local item = {
		name = "Item";
		icon = "Interface/Icons/inv_misc_questionmark";
		quality = 1;
		itemBind = 0;
		soulbound = false;
		whiteText1 = "";
		whiteText2 = "";
		useText = "";
		flavorText = nil;
		stackSize = 1;
		stackCount = 1;
		cooldown = 1;
		lastCastTime = 0;
		consumeable = false;
		copyable = false;
		requiresDMApproval = false;
		canDisenchant = false;
		guid = GenerateGUID();
		author = "DiceMaster Script";
		effects = {}
	}
	
	local api = GetItemAPI(item);
	api.Save = function()
		if not item or type(item)~="table" then
			return
		end
		Me.CreateItem( item, item.stackCount or 1 )
		-- remove api from item
		local data = Me.GetItemInfo( item.guid );
		for k,v in pairs(data) do
			if api[k] then
				data[k] = nil;
			end
		end
		data.amount = item.stackCount or 1;
		data = Me:Serialize( "ITEM", data );
		Me:SendCommMessage( "DCM4", data, "WHISPER", UnitName("player"), "NORMAL" )
	end
	for k, v in pairs( api ) do
		item[k] = v
	end
	
	return item
end

---------------------------------------------------------------------------
-- Create an item and insert it into the inventory.
--
-- Note: This function requires the item data. Use Me.NewItem() to create
-- an item from scratch. 
--
-- @param item		table		Item data table
-- @param amount	number		Amount to create

function Me.CreateItem( item, amount )
	if not( item ) or amount == 0 then
		return
	end

	while amount > item.stackSize do
		Me.InsertItem( item, item.stackSize );
		amount = amount - item.stackSize;
	end
	
	if amount > 0 and amount <= item.stackSize then
		Me.InsertItem( item, amount );
	end
	
	Me.TraitEditor_UpdateInventory()
end

---------------------------------------------------------------------------
-- Produce an item.
--
-- Note: This function won't work if the player has never encountered
-- the item before!
--
-- @param guid		string		The unique guid of the item
-- @param amount	number		Amount to produce

function Me.ProduceItem( guid, amount )
	local item = Me.GetItemInfo( guid );

	if not( item ) or amount == 0 then
		return
	end
	
	local stacks = Me.FindAllStacks( guid );
	
	for slot, stack in pairs( stacks ) do
		local maxAmount = stack.stackSize - stack.stackCount
		local deltaAmount = math.min( amount, maxAmount )
		
		if stack.stackCount + deltaAmount <= stack.stackSize then
			Me.Profile.inventory[slot].stackCount = Me.Profile.inventory[slot].stackCount + deltaAmount
			amount = amount - deltaAmount;
		end
	end

	while amount > item.stackSize do
		Me.InsertItem( item, item.stackSize ) ;
		amount = amount - item.stackSize;
	end
	
	if amount > 0 and amount <= item.stackSize then
		Me.InsertItem( item, amount );
	end

	Me.TraitEditor_UpdateInventory()
end

---------------------------------------------------------------------------
-- Consume an item.
--
-- @param guid		string		The unique guid of the item
-- @param amount	number		Amount to consume

function Me.ConsumeItem( guid, amount )
	local stacks = Me.FindAllStacks( guid );
	
	for slot, stack in pairs( stacks ) do
		local stackAmount = stack.stackCount
		local deltaAmount = math.min( amount, stackAmount )
		
		Me.DeleteItem( guid, deltaAmount )
		amount = amount - deltaAmount;
		if amount <= 0 then
			Me.TraitEditor_UpdateInventory()
			return;
		end
	end
	Me.TraitEditor_UpdateInventory()
end

---------------------------------------------------------------------------
-- Apply a buff.
--
-- @param name				string		Buff name
-- @param icon				string		Buff icon path
-- @param desc				string		Buff description
-- @param duration			number		Buff duration index* (not the actual duration)
-- @param stackable			boolean		Buff name
-- @param alwaysCastOnSelf	boolean		True if only applies to the player, nil or false otherwise
-- @param range				number		Buff range (0 if not an area buff)
-- @param skill				string		Skill name
-- @param skillRank			number		Skill rank

function Me.ApplyBuff( name, icon, desc, duration, stackable, alwaysCastOnSelf, range, skill, skillRank )
	if not name or type(name)~="string" or name == "" then
		return
	end
	if not duration or type(duration)~="number" or duration < 1 or duration > #BUFF_DURATION_AMOUNTS then
		duration = 1;
	end
	duration = math.floor( duration );
	if not stackable or type(stackable)~="boolean" then
		stackable = false;
	end
	if not range or type(range)~="number" or range < 0 or range > 99 then
		range = 0;
	end
	range = math.floor( range );
	if not skillRank or type(skillRank)~="number" or skillRank < -9999 or skillRank > 9999 then
		skillRank = 0;
	end
	
	local buff = {
		type = "buff";
		name = name;
		icon = icon or "Interface/Icons/inv_misc_questionmark";
		desc = desc or "";
		cancelable = true;
		duration = duration or 1;
		stackable = stackable or false;
		target = alwaysCastOnSelf or true;
		aoe = false;
		range = range or 0;
		skill = skill or "";
		skillRank = skillRank or 0;
	}
	
	if duration > 1 then
		buff.cancelable = false;
	end
	if range > 0 then
		buff.aoe = true;
	end
	Me.BuffFrame_CastBuff( buff )
end

---------------------------------------------------------------------------
-- Remove a buff.
--
-- @param name		string		Buff name
-- @param amount	number		Amount to remove

function Me.RemoveBuff( name, amount )
	if not name or type(name)~="string" or name == "" then
		return
	end
	if not amount or type(amount)~="number" or amount <= 0 then
		amount = 1;
	end
	amount = math.floor( amount );
	
	local buff = {
		type = "removebuff";
		name = name;
		count = amount;
	}

	Me.BuffFrame_RemoveBuff( buff )
end

---------------------------------------------------------------------------
-- Play a sound.
--
-- @param soundPath		string/number		The soundKitID or file path of a sound
-- @param range			number				Sound range (0 if not an area sound)

function Me.PlaySound( soundPath, range )
	if not soundPath or soundPath == "" then
		return
	end
	
	local soundID
	if type(soundPath) == "string" then
		for i = 1, #Me.soundList do
			if Me.soundList[i].name:lower() == soundPath:lower() then
				soundID = Me.soundList[i].id;
				break
			end
		end
	elseif type(soundPath) == "number" then
		soundID = soundPath
	else
		return
	end
	
	if not soundID then return end
	
	if not range or type(range)~="number" or range < 0 or range > 99 then
		range = 0;
	end
	range = math.floor( range );
	
	local sound = {
		type = "sound";
		soundID = soundID;
		range = 0;
	}

	Me.SoundPicker_PlaySound( sound )
end

---------------------------------------------------------------------------
-- Roll the dice.
--
-- @param dice		string		The dice string, in D20 notation (XDY+Z)
-- @param skill	string		The name of a skill to check

function Me.RollDice( dice, skill )
	local setdice = {
		type = "setdice";
		value = dice or "D20";
		skill = skill or "";
	}

	Me.BuffFrame_RollDice( setdice )
end

---------------------------------------------------------------------------
-- Send a message.
--
-- @param message		string		The message to send
-- @param channel		string		The chat channel

function Me.SendChatMessage( message, channel )
	if not channel or type( channel ) ~= "string" then
		channel = "SAY"
	end
	
	if not message or message == "" or type( message ) ~= "string" then
		return
	end
	
	local data = {
		type = "message";
		message = message;
		channel = channel;
	}
	
	Me.MessageEditor_SendMessage( data )
end

---------------------------------------------------------------------------
-- Execute a script.
--
-- @param code		string		The code to execute

function Me.RunScript( code )
	if not code or type(code)~="string" then
		code = ""
	end
	
	local data = {
		type = "script";
		code = code;
	}
	
	Me.ScriptEditor_RunScript( data )
end

---------------------------------------------------------------------------
-- Display a visual effect.
--
-- @param effectID			string/number		The name of an effect from Me.effectList or a spellVisualKitID
-- @param alwaysCastOnSelf	boolean				True if only applies to the player, nil or false otherwise

function Me.VisualEffect( effectID, alwaysCastOnSelf )
	if not effectID then
		return
	end
	
	local spellVisualKitID
	if type(effectID) == "string" then
		for i = 1, #Me.effectList do
			if Me.effectList[i].name:lower() == effectID:lower() then
				spellVisualKitID = Me.effectList[i].id;
				break
			end
		end
	elseif type(effectID) == "number" then
		spellVisualKitID = effectID
	else
		return
	end
	
	if not spellVisualKitID then return end
	
	local effect = {
		type = "effect";
		effectID = spellVisualKitID;
		target = alwaysCastOnSelf or true;
	}
	
	Me.EffectPicker_PlayEffect( effect )
end

---------------------------------------------------------------------------
-- Display a textured screen effect.
--
-- @param texture			string		The file path of the texture
-- @param alwaysCastOnSelf	boolean		True if only applies to the player, nil or false otherwise

function Me.ScreenEffect( texture, alwaysCastOnSelf )
	if not texture or type( texture ) ~= "string" then
		texture = Me.textureList["Mage"][1].file
	end
	
	local effect = {
		type = "screeneffect";
		texture = texture;
		target = alwaysCastOnSelf or true;
	}
	
	Me.ScreenEffectEditor_PlayEffect( effect )
end

---------------------------------------------------------------------------
-- Get the player's health, armour, and maximum health.
--
-- @returns health		number		The player's health
-- @returns maxHealth	number		The player's maximum health
-- @returns armour		number		The player's armour

function Me.GetHealth()
	return Profile.health, Profile.healthMax, Profile.armor
end

---------------------------------------------------------------------------
-- Get information about the player's charges.
--
-- @returns charges		number		The player's charges value
-- @returns maxCharges	number		The player's maximum charges value
-- @returns name		number		The custom name of the player's charges

function Me.GetChargesInfo()
	if not Profile.charges.enable then
		return false
	end
	return Profile.charges.count, Profile.charges.max, Profile.charges.name
end

---------------------------------------------------------------------------
-- Get the player's level.
--
-- @returns level		number		The player's level

function Me.GetDiceMasterLevel()
	return Profile.level or 1
end

---------------------------------------------------------------------------
-- Get the player's experience.
--
-- @returns experience		number		The player's experience

function Me.GetDiceMasterExperience()
	return Profile.experience or 0
end

---------------------------------------------------------------------------
-- Set the player's health and/or armour.
--
-- @param health	number		The amount of health to add/remove
-- @param armour	number		The amount of armour to add/remove

function Me.SetHealth( health, armour )
	if not health or type( health ) ~= "number" then
		health = 0;
	end
	
	if not armour or type( armour ) ~= "number" then
		armour = 0;
	end
	
	health = math.floor( health )
	armour = math.floor( armour )
	
	local effect = {
		type = "health";
		health = health;
		armour = armour;
	}
	
	Me.AdjustHealthEditor_AdjustHealth( effect )
end

---------------------------------------------------------------------------
-- Set the player's maximum health.
--
-- @param maxHealth		number		The new maximum health value

function Me.SetMaxHealth( maxHealth )
	if not maxHealth or type( maxHealth ) ~= "number" then
		maxHealth = 0;
	end
	
	maxHealth = math.floor( maxHealth )
	
	Profile.healthMax = Me.Clamp( maxHealth, 1, 1000 )

	Me.RefreshHealthbarFrame( DiceMasterChargesFrame.healthbar, Profile.health, Profile.healthMax, Profile.armor )
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty()
	Me.DiceMasterRollDetailFrame_Update()
	Me.DMRosterFrame_Update()
end

---------------------------------------------------------------------------
-- Set the player's mana.
--
-- @param mana	number		The amount of mana to add/remove

function Me.SetMana( mana )
	if not mana or type( mana ) ~= "number" then
		mana = 0;
	end
	
	mana = math.floor( mana )
	
	local effect = {
		type = "mana";
		health = health;
		armour = armour;
	}
	
	Me.AdjustHealthEditor_AdjustMana( effect )
end

---------------------------------------------------------------------------
-- Set the player's charges.
--
-- @param charges		number		The amount of charges to add/remove

function Me.SetCharges( count )
	if not Profile.charges.enable then
		return
	end
	
	if not count or type( count ) ~= "number" then
		count = 0;
	end
	
	count = math.floor( count )
	
	Profile.charges.count = Me.Clamp( Profile.charges.count + count, 0, Profile.charges.max )
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	
	Me.RefreshChargesFrame()
	Me.Inspect_ShareStatusWithParty() 
end

---------------------------------------------------------------------------
-- Get the player's health, armour, and maximum health.
--
-- @returns name		string		The pet's name
-- @returns icon		string		The pet's icon
-- @returns type		string		The pet's type
-- @returns health		number		The pet's health
-- @returns maxHealth	number		The pet's maximum health
-- @returns armour		number		The pet's armour
-- @returns displayID		number		The displayID of the pet

function Me.GetPetInfo()
	if not Profile.pet.enable then
		return
	end
	return Profile.pet.name, Profile.pet.icon, Profile.pet.type, Profile.pet.health, Profile.pet.healthMax, Profile.pet.armor, Profile.pet.model
end

---------------------------------------------------------------------------
-- Get information about a currently active buff.
--
-- @param index				number		The numeric ID of the buff
-- @returns name			string		The name of the buff
-- @returns icon			string		The buff's icon
-- @returns description		string		The description of the buff
-- @returns count			number		The number of stacks
-- @returns duration		number		The time-based duration of the buff
-- @returns turns			number		The turn-based duration of the buff
-- @returns expirationTime	number		The time when the buff expires
-- @returns sender			string		The name of the character who applied the buff
-- @returns skill			string		The name of the skill modified by the buff
-- @returns skillRank		number		The value of the skill modified by the buff

function Me.GetBuffInfo( index )
	if not index or type(index)~="number" or index < 0 then
		return
	end
	if Profile.buffsActive[index] then
		return Profile.buffsActive[index].name, Profile.buffsActive[index].icon, Profile.buffsActive[index].description, Profile.buffsActive[index].count, Profile.buffsActive[index].duration, Profile.buffsActive[index].turns, Profile.buffsActive[index].expirationTime, Profile.buffsActive[index].sender, Profile.buffsActive[index].skill, Profile.buffsActive[index].skillRank
	end
end

---------------------------------------------------------------------------
-- Get the value of a player's skill.
--
-- @param skill		string		The name of the skill
-- @returns value	number		The value of the skill

function Me.GetSkill( skill )
	local value = 0;
	for i = 1, #Profile.skills do
		if Profile.skills[i].name == skill then
			value = Profile.skills[i].rank;
		end
	end
	for i = 1, #Profile.buffsActive do
		if Profile.buffsActive[i].skill == skill then
			value = value + Profile.buffsActive[i].skillRank * Profile.buffsActive[i].count;
		end
	end
	return value;
end

---------------------------------------------------------------------------
-- Get information about a currency.
--
-- @param guid		string		The guid of the currency
-- @return name		string		The name of the currency
-- @return icon		string		The currency's icon
-- @return author	string		The name of the character who created the currency
-- @return amount	number		The amount of currency

function Me.GetCurrency( guid )
	if not guid or type(guid)~="string" then
		return
	end
	
	local currency
	for i = 1, #Me.Profile.currency do
		if Me.Profile.currency[i].guid == guid then
			currency = Me.Profile.currency[i]
			break
		end
	end
	
	if not currency then
		return
	end
	
	return currency.name, currency.icon, currency.author, currency.count
end

---------------------------------------------------------------------------
-- Increase currency by a certain amount.
--
-- @param guid		string		The guid of the currency
-- @param amount	number		The amount of currency to produce

function Me.ProduceCurrency( guid, amount )
	if not guid or type(guid)~="string" then
		return
	end
	
	local found_currency
	for i = 1, #Me.Profile.currency do
		if Me.Profile.currency[i].guid == guid then
			found_currency = Me.Profile.currency[i]
			break
		end
	end
	
	if not found_currency then return end
	
	if not amount or type(amount)~="number" or amount <= 0 then
		amount = 1;
	end
	amount = math.floor( amount );
	
	local currency = {
		type = "currency";
		name = found_currency.name;
		icon = found_currency.icon;
		author = found_currency.author;
		guid = guid;
		count = amount;
	}
	
	Me.ProduceCurrencyEditor_ProduceCurrency( currency )
end

---------------------------------------------------------------------------
-- Decrease currency by a certain amount.
--
-- @param guid		string		The guid of the currency
-- @param amount	number		The amount of currency to consume

function Me.ConsumeCurrency( guid, amount )
	if not guid or type(guid)~="string" then
		return
	end
	
	local found_currency
	for i = 1, #Me.Profile.currency do
		if Me.Profile.currency[i].guid == guid then
			found_currency = Me.Profile.currency[i]
			break
		end
	end
	
	if not found_currency then return end
	
	if not amount or type(amount)~="number" or amount <= 0 then
		amount = 1;
	end
	amount = -1 * math.floor( amount );
	
	local currency = {
		type = "currency";
		name = found_currency.name;
		icon = found_currency.icon;
		author = found_currency.author;
		guid = guid;
		count = amount;
	}
	
	Me.ProduceCurrencyEditor_ProduceCurrency( currency )
end

---------------------------------------------------------------------------
-- Open a custom book.
--
-- @param title		string		Title of the book
-- @param material	string		Background image
-- @param pages		table		Metatable containing the page data
-- @param font		string		File path for the book font
-- @param p			number		Size of the text enclosed in <p> tags
-- @param h1		number		Size of the text enclosed in <h1> tags
-- @param h2		number		Size of the text enclosed in <h2> tags

function Me.Book( title, material, pages, font, p, h1, h2 )
	if not title or type(title)~="string" or title == "" then
		title = "Custom Book";
	end
	if not material or type(material)~="string" or material == "" then
		title = "Book";
	end
	if not pages or type(pages)~="table" then
		pages = { "" };
	end
	if not font or type(font)~="string" then
		font = "Frizqt";
	end
	if not p or type(p)~="number" or p < 1 or p > 100 then
		p = 13;
	end
	if not h1 or type(h1)~="number" or h1 < 1 or h1 > 100 then
		h1 = 18;
	end
	if not h2 or type(h2)~="number" or h2 < 1 or h2 > 100 then
		h2 = 16;
	end
	local book = {
		type = "book";
		title = title;
		material = material;
		pages = pages;
		font = font;
		fontSize = {
			p = p;
			h1 = h1;
			h2 = h2;
		},
		author = "DiceMaster Script";
	}
	
	Me.BookFrame_Show( book )
end

---------------------------------------------------------------------------
-- Display a cast bar.
--
-- @param barType			string		The type of cast bar ("cast" or "channel")
-- @param text				string		The text to display on the bar
-- @param texture			string		Texture path for the cast bar icon
-- @param duration			number		The duration (in seconds) of the cast/channel
-- @param nonInterruptible	boolean		Whether the cast/channel is interruptible or not
-- @return handle			table		A reference to the cast bar

function Me.CastBar( barType, text, texture, duration, nonInterruptible, sound )
	if not barType or ( barType~="cast" and barType~="channel" ) then
		barType = "cast"
	end
	if not text or type( text )~="string" then
		text = ""
	end
	if not texture or type( texture )~="string" then
		texture = "Interface/Icons/inv_misc_questionmark";
	end
	if not duration or type( duration )~="number" or duration < 0 or duration > 300 then
		duration = Me.Clamp( duration or 1, 0, 300 )
	end
	
	if sound and type(sound) == "string" then
		for i = 1, #Me.soundList do
			if Me.soundList[i].name:lower() == sound:lower() then
				sound = Me.soundList[i].id;
				break
			end
		end
	elseif sound and type(sound) == "number" then
		sound = sound
	else
		sound = nil
	end
	
	Me.CastingBar_Show(barType, text, texture, duration, notInterruptible, sound)
	return DiceMasterCastingBarFrame;
end

---------------------------------------------------------------------------
-- Display the 'Extra Button' frame.
--
-- @param texture		string		Texture path for the extra button frame
-- @param title			string		Tooltip title
-- @param icon			string		Icon for the extra button
-- @param description	string		Tooltip description
-- @param callback		function	Callback function for when the button is clicked
-- @return handle		table		A reference to the extra button

function Me.ExtraButton( texture, icon, title, description, callback )
	if not texture or type( texture )~="string" then
		texture = "Default";
	end
	if not icon or type( icon )~="string" then
		texture = "Interface/Icons/inv_misc_questionmark"
	end
	if not title or type( title )~="string" then
		title = nil
	end
	if not description or type( description )~="string" then
		description = nil
	end
	
	Me.ExtraButton_Show(texture, icon, title, description, callback)
	return DiceMasterExtraButtonFrame;
end

---------------------------------------------------------------------------
-- Hides the 'Extra Button' frame.
--

function Me.HideExtraButton()
	-- for those against underscores?
	Me.ExtraButton_Hide()
end

---------------------------------------------------------------------------
-- Get a hyperlink for an item.
--
-- @param player	string		Name of the player who has the item (not the author!)
-- @param guid		string		The unique guid of the item

function Me.GetItemLink( player, guid )
	local found_item = false;
	local store = Me.inspectData[player].inventory;
	
	for i = 1, 42 do
		if store[i] and store[i].guid == guid then
			found_item = i;
			break
		end
	end
	
	if ( player == UnitName("player") and not found_item ) then
		for i = 1, 42 do
			if Me.db.global.bank[i] and Me.db.global.bank[i].guid == guid then
				found_item = i;
				store = Me.db.global.bank;
				break
			end
		end
	end
	
	if not found_item then
		return "|TInterface/Icons/inv_misc_questionmark:16|t |cffffffff[Unknown Item]|r";
	end
	
	local icon = store[tonumber(found_item)].icon
	local name = store[tonumber(found_item)].name
	local colorHex = ITEM_QUALITY_COLORS[ store[tonumber(found_item)].quality ].hex or "|cffffffff";
	return string.format("|T"..icon..":16|t "..colorHex.."|HDiceMaster4Item:".. player ..":"..guid.."|h[%s]|h|r", name);
end