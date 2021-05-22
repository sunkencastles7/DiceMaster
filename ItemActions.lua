-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

-- Item Actions

local Me = DiceMaster4 
local Profile = Me.Profile

function Me.FindAllStacks( guid )
	local t = {}
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == guid then
			t[i] = Me.Profile.inventory[i];
		end
	end
	return t;
end

function Me.FindTotalStacks( guid )
	local c = 0
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == guid then
			c = c + 1
		end
	end
	return c;
end

function Me.FindFirstStack( guid )
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == guid then
			return Me.Profile.inventory[i];
		end
	end
	return false;
end

function Me.FindFirstStackSlot( guid )
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == guid then
			return i;
		end
	end
	return false;
end

function Me.FindEmptySlot()
	for i = 1, 42 do
		if Me.Profile.inventory[i] == nil then
			return i;
		end
	end
	return false;
end

function Me.FindTotalEmptySlots()
	local c = 42
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid then
			c = c - 1
		end
	end
	return c;
end

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

function Me.InsertItem( item, amount )
	local slot = Me.FindEmptySlot()
	
	if not( slot ) then
		UIErrorsFrame:AddMessage( "Inventory is full.", 1.0, 0.0, 0.0, 53, 5 ); 
		return
	end
	
	local data = {}
	for k, v in pairs( item ) do
		data[k] = v;
	end
	data.stackCount = amount
	Me.Profile.inventory[slot] = data
	Me.TraitEditor_UpdateInventory()
end

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

function Me.MaintainItemAmounts( guid )
	local stacks = Me.FindAllStacks( guid )
	for slot, stack in pairs(stacks) do
		if stack.stackCount == 0 then
			Me.Profile.inventory[ slot ] = nil;
		end
	end
	Me.TraitEditor_UpdateInventory()
end

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