-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Item Trading
--

local Me      = DiceMaster4
local Profile = Me.Profile

local tradeItemsPlayer = {};
local tradeItemsRecipient = {};
local playerAcceptState, recipientAcceptState;
local tradePlayer;
local orig = {};

local function ClearAll()
	tradeItemsPlayer = {}
	tradeItemsRecipient = {}
	playerAcceptState = nil
	recipientAcceptState = nil
	tradePlayer = nil
end

local ClickTradeButton = function( slot )
	if slot > 6 then return orig.ClickTradeButton(slot); end;

	local cursorIcon = DiceMasterCursorItemIcon
	local cursorGotDMItem = cursorIcon.item and cursorIcon.itemID;
	local slotGotDMItem = tradeItemsPlayer[slot] and true;
	local slotGotNormalItem = GetTradePlayerItemInfo(slot) and true;
	local slotGotNoItem = not (slotGotDMItem or slotGotNormalItem);

	if cursorGotDMItem and not ( Me.inspectData[TradeFrameRecipientNameText:GetText()].hasDM4 ) then
		return Me.NoTradeResponseError();
	end

	if cursorGotDMItem then
		local item = Me.Profile.inventory[cursorIcon.itemID];
		if item.soulbound then
			UIErrorsFrame:AddMessage( ERR_TRADE_BOUND_ITEM , 1, 0, 0 );
			return
		end
	end

	if cursorGotDMItem and slotGotNormalItem then
		Me.PickupWowItemPlaceDMItem(slot);
	elseif cursorGotDMItem and slotGotDMItem then
		Me.PickupDMItemPlaceDMItem(slot);
	elseif cursorGotDMItem and slotGotNoItem then
		Me.PickupNonePlaceDMItem(slot);
	elseif not (cursorGotDMItem) and slotGotNormalItem then
		orig.ClickTradeButton(slot)
	elseif not (cursorGotDMItem) and slotGotDMItem then
		Me.PickupDMItemPlaceWowItem(slot) -- placing nothing instead of wow item
	elseif not (cursorGotDMItem) and slotGotNoItem then
		orig.ClickTradeButton(slot)
		return
	end

	Me.CancelAcceptTrade();
end
orig["ClickTradeButton"] = _G["ClickTradeButton"];
_G["ClickTradeButton"] = ClickTradeButton;

function Me.NoTradeResponseError()
	local tradePlayer = TradeFrameRecipientNameText:GetText() or "The trade recipient";
	if tradePlayer and ( Me.inspectData[tradePlayer].hasDM4 ) then
		Me.PrintMessage( tradePlayer .. " is busy right now.","SYSTEM" );
		return
	end
	Me.PrintMessage( tradePlayer .. " does not have DiceMaster installed or is using an out of date version.","SYSTEM" );
end;

function Me.PickupNonePlaceDMItem(slot)
	Me.SetDMItemInSlot(slot, Me.GetDMItemFromCursor());
	Me.ClearCursorActions( true, true, true )
end

function Me.PickupWowItemPlaceDMItem(slot)
	local item = { Me.GetDMItemFromCursor() };
	Me.ClearCursorActions( true, true, true )
	orig.ClickTradeButton(slot)
	Me.SetDMItemInSlot(slot, unpack(item));
end

function Me.PickupDMItemPlaceWowItem(slot)
	local item = { Me.GetDMItemFromSlot(slot) };
	Me.ClearTradeButton(slot);
	orig.ClickTradeButton(slot);
	Me.PickUpDMItem(slot, unpack(item));
end

function Me.PickupDMItemPlaceDMItem(slot)
	local item = { Me.GetDMItemFromCursor() };
	local item2 = { Me.GetDMItemFromSlot(slot) };
	Me.PickUpDMItem(slot, unpack(item2));
	Me.SetDMItemInSlot(slot, unpack(item));
end

function Me.GetDMItemFromCursor()
	local cursorIcon = DiceMasterCursorItemIcon
	local item = Me.Profile.inventory[cursorIcon.itemID]
	local containerSlotID = cursorIcon.itemID
	local stack = DiceMasterTraitEditorInventoryFrame["Item"..cursorIcon.itemID]
	
	if cursorIcon.splitItem then
		amount = cursorIcon.splitAmount
	elseif cursorIcon.copyItem then
		amount = cursorIcon.copyAmount
	else
		amount = Me.Profile.inventory[cursorIcon.itemID].stackCount
	end
	
	return amount, containerSlotID, stack;
end

function Me.SetDMItemInSlot(slot, amount, containerSlotID, stack)
	tradeItemsPlayer[slot] = {
		amount = amount,
		containerSlotID = containerSlotID,
		stack = stack,
	};
	Me.UpdateTradeButton(slot);
end

function Me.UpdateTradeButton(slot)
	local amount, containerSlotID, stack = Me.GetDMItemFromSlot(slot);

	local item;
	if stack then
		item = stack:GetItem()
	else
		return;
	end
	Me.SetTradeItem(slot, amount, item.name, item.icon, item.quality)
	Me.SendTradeInfo(tradePlayer, slot, item, amount or stack)
end

function Me.GetDMItemFromSlot(slot)
	local t = tradeItemsPlayer[slot];
	if not (type(t) == "table") then
		return
	end
	return t.amount, t.containerSlotID, t.stack;
end

function Me.SetTradeItem(slot, amount, name, texture, quality )
	local itemButton = _G["TradePlayerItem" .. slot .. "ItemButton"];
	SetItemButtonTexture(itemButton, texture);
	SetItemButtonCount(itemButton, amount);

	local colorHex = ""
	if quality then
		colorHex = ITEM_QUALITY_COLORS[ quality ].hex
	end

	_G["TradePlayerItem" .. slot .. "Name"]:SetText(colorHex .. name);
end

function Me.SendTradeInfo(player, slot, item, amount, stackToSend)
	local data = {
		item = item;
		slot = slot;
		guid = item.guid;
		amount = amount;
		stack = stackToSend;
	};
	local msg = Me:Serialize( "TRDITEM", data )
	Me:SendCommMessage( "DCM4", msg, "WHISPER", player, "ALERT" )
end

function Me.CancelAcceptTrade()
	local n = GetPlayerTradeMoney();
	SetTradeMoney(1);
	SetTradeMoney(n);
end

function Me.UpdateRecipientTradeItem( slot, name, texture, amount, item )
	if (GetTradeTargetItemInfo(slot)) then
		-- Wait with updating until the item is gone
		C_Timer.After( 1, function() Me.UpdateRecipientTradeItem(slot, name, texture, amount, item ) end);
	end

	local itemButton = _G["TradeRecipientItem" .. slot .. "ItemButton"];

	SetItemButtonTexture(itemButton, texture);
	SetItemButtonCount(itemButton, amount);
	
	local colorHex = ""
	if item and item.quality then
		colorHex = ITEM_QUALITY_COLORS[ item.quality ].hex
	end

	_G["TradeRecipientItem" .. slot .. "Name"]:SetText(colorHex .. name);
end

function Me.UpdateTradeInfo( slot, guid, amount )
	local item = DiceMasterTraitEditorInventoryFrame["Item"..guid];

	if not ( item ) and TradeFrame:IsShown() then
		C_Timer.After(1, function() Me.UpdateTradeInfo(slot, guid, amount ) end);
	else
		local data = item:GetItem()
		local name, icon = data.name, data.icon;
		Me.UpdateRecipientTradeItem(slot, name, icon, amount, item );
	end
end

function Me.ClearTradeButton( slot )
	tradeItemsPlayer[slot] = nil;
	local itemButton = _G["TradePlayerItem" .. slot .. "ItemButton"];
	SetItemButtonTexture(itemButton, "");
	SetItemButtonCount(itemButton, 1);
	_G["TradePlayerItem" .. slot .. "Name"]:SetText("");
	local data = {
		slot = slot;
	};
	local msg = Me:Serialize( "TRDREM", data )
	Me:SendCommMessage( "DCM4", msg, "WHISPER", tradePlayer, "ALERT" )
end

function Me.PickUpDMItem( slot, splitAmount, containerSlotID, stack )
	stack = stack:GetItem()
	local name, icon = stack.name, stack.icon
	DiceMasterCursorOverlay:Show()
	local cursorIcon = DiceMasterCursorItemIcon
	cursorIcon.item:SetTexture( icon )
	cursorIcon.itemID = containerSlotID
	cursorIcon.prevButton = _G["TradeRecipientItem" .. slot .. "ItemButton"]
	cursorIcon:Show()
	SetItemButtonDesaturated( _G["TradeRecipientItem" .. slot .. "ItemButton"], true );
	ClearCursor()
	SetCursor( "ITEM_CURSOR" )
	PlaySound( 1186 )
end

function Me.ClearRecipientButton( slot )
	tradeItemsRecipient[slot] = {};
	local itemButton = _G["TradeRecipientItem" .. slot .. "ItemButton"];

	SetItemButtonTexture(itemButton, "");
	SetItemButtonCount(itemButton, 1);

	_G["TradeRecipientItem" .. slot .. "Name"]:SetText("");
	Me.CancelAcceptTrade();
end

function Me.AcceptTrade( name, ... )
	if name == tradePlayer then
		-- insert
		for i = 1, 6 do
			local guid, amount, playerName, _, _, item = Me.GetRecipientTradeItem(i);
			if guid and item then
				tinsert( Me.Profile.inventory, item )
				local data = Me:Serialize( "ITEM", item );
				Me:SendCommMessage( "DCM4", data, "WHISPER", UnitName("player"), "ALERT" )
				Me.TraitEditor_UpdateInventory()
			end
		end
		ClearAll();
	end
end

function Me.CancelTrade()
	for slot = 1, 6 do
		local amount, containerSlotID, stack = Me.GetDMItemFromSlot(slot);
		if stack then
			stack:Update();
			SetItemButtonDesaturated( stack, false );
		end
	end
	ClearAll();
end

function Me.GetRecipientTradeItem( slot )
	local t = tradeItemsRecipient[slot];
	if type(t) == "table" then
		return t.guid, t.amount, t.name, t.texture, t.stack, t.item;
	end
end

function Me.TradeItemButtonOnEnter( self, slot )
	local ID = Me.GetDMItemFromSlot(slot);
	if ID then
		local amount, containerSlotID, stack = Me.GetDMItemFromSlot(slot);
		-- TODO
		-- Show item tooltip
		Me.OpenItemTooltip( self, UnitName("player"), containerSlotID, false )
	end
end

function Me.TradeItemButtonOnUpdate(self, elapsed)
	if (self.updateTooltip) then
		self.updateTooltip = self.updateTooltip - elapsed;
		if (self.updateTooltip > 0) then
			return;
		end
	end

	if (self:IsMouseMotionFocus()) then
		Me.TradeItemButtonOnEnter(self, self:GetParent():GetID());
	end
end

function Me.RecipientTradeItemButtonOnEnter(self, slot)
	local ID = Me.GetRecipientTradeItem(slot);
	if ID then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

		local guid, amount, name, texture, stack = Me.GetRecipientTradeItem(slot);
		Me.OpenItemTooltip( self, tradePlayer, slot, false )
	end
end
	
function Me.RecipientTradeItemButtonOnUpdate(self, elapsed)
	if (self.updateTooltip) then
		self.updateTooltip = self.updateTooltip - elapsed;
		if (self.updateTooltip > 0) then
			return;
		end
	end

	if (self:IsMouseMotionFocus()) then
		Me.RecipientTradeItemButtonOnEnter(self, self:GetParent():GetID());
	end
end

local function OnEvent( self, event, arg1, arg2, ... )
	if (event == "TRADE_CLOSED") then
		if (playerAcceptState == 1 and recipientAcceptState == 1) then
			local data = {
				accepted = true;
			};
			local msg = Me:Serialize( "TRDACC", data )
			Me:SendCommMessage( "DCM4", msg, "WHISPER", tradePlayer, "ALERT" )
			Me.AcceptTrade(tradePlayer);
		end
	elseif (event == "TRADE_ACCEPT_UPDATE") then
		playerAcceptState = arg1;
		recipientAcceptState = arg2;
	elseif (event == "TRADE_SHOW") then
		ClearAll();
		tradePlayer = TradeFrameRecipientNameText:GetText();
		--ping.SendPing(tradePlayer, true);
	elseif (event == "TRADE_REQUEST_CANCEL") then
		Me.CancelTrade();
	end
end

function Me.ItemTrade_Init()
	local frame = CreateFrame( "Frame" )
	frame:SetScript( "OnEvent", OnEvent );
	frame:RegisterEvent("TRADE_CLOSED");
	frame:RegisterEvent("TRADE_ACCEPT_UPDATE");
	frame:RegisterEvent("TRADE_SHOW");
	frame:RegisterEvent("TRADE_REQUEST_CANCEL");

	for i = 1, 6 do
		_G["TradePlayerItem" .. i .. "ItemButton"]:HookScript( "OnEnter", function( self )
			Me.TradeItemButtonOnEnter(self, self:GetParent():GetID())
		end)
		_G["TradePlayerItem" .. i .. "ItemButton"]:HookScript( "OnUpdate", function( self, arg1 )
			Me.TradeItemButtonOnUpdate(self, arg1);
		end)
		_G["TradeRecipientItem" .. i .. "ItemButton"]:HookScript( "OnEnter", function( self )
			Me.RecipientTradeItemButtonOnEnter(self, self:GetParent():GetID()); 
		end);
		_G["TradeRecipientItem" .. i .. "ItemButton"]:HookScript( "OnUpdate", function( self, arg1 )
			Me.RecipientTradeItemButtonOnUpdate(self, arg1); 
		end);
	end
	
	if TradeFrame:IsShown() then
		OnEvent(nil, "TRADE_SHOW");
	end
end

function Me.ItemTrade_RemoveTradeItem( data, dist, sender )

	if not data.slot then
		return
	end
	
	local slot = tostring( data.slot );

	Me.CancelAcceptTrade();
	Me.ClearRecipientButton(slot);
end

function Me.ItemTrade_TradeAccepted( data, dist, sender )

	if not data.accepted then
		return
	end
	
	-- delete
	for slot = 1, 6 do
		local amount, containerSlotID, stack = Me.GetDMItemFromSlot(slot);
		if stack then
			Me.Profile.inventory[containerSlotID] = nil
			Me.TraitEditor_UpdateInventory()
		end
	end
end

function Me.ItemTrade_RecieveTradeItem( data, dist, sender )

	if not data or not data.item or not data.guid then
		return
	end
	
	local player = sender
	local slot = data.slot
	local guid = data.guid
	local amount = data.amount
	local item = data.item
	local name = data.item.name
	local texture = data.item.icon
	local stack = data.stack

	if player == tradePlayer then
		Me.CancelAcceptTrade();
		tradeItemsRecipient[slot] = {
			item = item,
			guid = guid,
			amount = amount,
			name = name,
			texture = texture,
			stack = stack,
		};
		if not (name) then
			Me.UpdateRecipientTradeItem(slot, "Waiting for item data.", texture, amount, item );
			Me.UpdateTradeInfo(slot, guid, amount );
		else
			Me.UpdateRecipientTradeItem(slot, name, texture, amount, item );
		end
	end
end
	
	