-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Loot Toast interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local groupLootItems = {}
local groupLootItemsRecipient = {}

local ITEM_BIND_TYPES = {
	"Binds when picked up",
	"Binds when equipped",
	"Binds when used",
}

local DICEMASTER_LOOT_BORDERS = {
	[1] = nil,
	[2] = "loottoast-itemborder-green",
	[3] = "loottoast-itemborder-blue",
	[4] = "loottoast-itemborder-purple",
	[5] = "loottoast-itemborder-orange",
	[6] = "loottoast-itemborder-artifact",
	[7] = "loottoast-itemborder-heirloom",
}

function Me.ItemIsBeingLooted( guid )
	-- check if it's being rolled for
	if groupLootItems[ guid ] then 
		return true 
	end
	return false
end

function Me.LootToastFrame_OnEnter( self )
	GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )
	local color = ITEM_QUALITY_COLORS[ self.itemData.quality ];
	GameTooltip:AddLine( self.itemData.name, color.r, color.g, color.b, true )
	
	if self.itemData.soulbound then
		GameTooltip:AddLine( "Binds when picked up", 1, 1, 1, true)
	elseif self.itemData.itemBind and self.itemData.itemBind > 0 then
		GameTooltip:AddLine( ITEM_BIND_TYPES[ self.itemData.itemBind ], 1, 1, 1, true )
	end
	
	if self.itemData.whiteText1 or self.itemData.whiteText2 then
		GameTooltip:AddDoubleLine(self.itemData.whiteText1, self.itemData.whiteText2, 1, 1, 1, 1, 1, 1, true)
	end
	
	if self.itemData.useText then
		GameTooltip:AddLine(Me.FormatItemTooltip(self.itemData.useText), 0, 1, 0, true)
	end
	
	if self.itemData.requirement then
		GameTooltip:AddLine(self.itemData.requirement, 1, 1, 1, true)
	end
	
	if self.itemData.flavorText then
		GameTooltip:AddLine( "\"" .. Me.FormatItemTooltip(self.itemData.flavorText) .. "\"", 1, 0.81, 0, true)
	end
	
	if self.itemData.author then
		GameTooltip:AddLine( "<Made by " .. self.itemData.author .. ">", 0, 1, 0, true)
	end
	
	GameTooltip:Show();
	
	self.MouseIsOver = true;
	
	if self.waitAndAnimOut:IsPlaying() then
		self.waitAndAnimOut:Stop()
	end
end

function Me.LootToastFrame_OnLeave( self )
	
	GameTooltip:Hide()
	
	self.MouseIsOver = false;
	
	if self:IsShown() and not ( self.animIn:IsPlaying() or self.waitAndAnimOut:IsPlaying() ) then
		self.waitAndAnimOut:Play()
	end
end

function Me.LootToastFrame_SetUp( self, itemData )
	
	if not itemData.name or not itemData.icon or not itemData.quality then
		return
	end
	
	-- A Loot Toast is playing, so add this one to the queue.
	-- We'll try again after this one finishes up.
	if self:IsShown() then
		if not self.Queue then
			self.Queue = {}
		end
		
		local queuedFrame = itemData
		tinsert( self.Queue, queuedFrame )
		return;
	end

	local windowInfo = LOOTWONALERTFRAME_VALUES.Default;
	
	if itemData.value and LOOTWONALERTFRAME_VALUES[ itemData.value ] then
		windowInfo = LOOTWONALERTFRAME_VALUES[ itemData.value ]
	end
	
	-- other options include...
	-- WonRoll, Default, Upgraded, LessAwesome, GarrisonCache, Horde, Alliance, RatedHorde, RatedAlliance, Azerite, Corrupted
	
	if ( windowInfo.bgAtlas ) then
		self.Background:Hide();
		self.BGAtlas:Show();
		self.BGAtlas:SetAtlas(windowInfo.bgAtlas);
		self.BGAtlas:SetPoint("CENTER", windowInfo.bgOffsetX, windowInfo.bgOffsetY);
	else
		self.Background:SetPoint("CENTER", windowInfo.bgOffsetX, windowInfo.bgOffsetY);
		self.Background:Show();
		self.BGAtlas:Hide();
	end
	if windowInfo.glowAtlas then
		self.glow:SetAtlas(windowInfo.glowAtlas);
		self.glow.suppressGlow = nil;
	else
		self.glow.suppressGlow = true;
	end

	self.Label:SetText(YOU_RECEIVED_LABEL or windowInfo.labelText);
	if itemData.labelText then
		self.Label:SetText( itemData.labelText );
	end
	self.Label:SetPoint("TOPLEFT", self.lootItem.Icon, "TOPRIGHT", windowInfo.labelOffsetX, windowInfo.labelOffsetY);

	self.ItemName:SetText( itemData.name );
	local color = ITEM_QUALITY_COLORS[ itemData.quality ];
	self.ItemName:SetVertexColor(color.r, color.g, color.b);
	
	if DICEMASTER_LOOT_BORDERS[ itemData.quality ] then
		self.lootItem.IconBorder:SetAtlas( DICEMASTER_LOOT_BORDERS[ itemData.quality ] );
		self.lootItem.IconBorder:Show()
	else
		self.lootItem.IconBorder:Hide()
	end
	self.lootItem.Icon:SetTexture( itemData.icon );
	
	if itemData.amount > 1 then
		self.lootItem.Count:SetText( itemData.amount );
		self.lootItem.Count:Show();
	else
		self.lootItem.Count:SetText( "" );
		self.lootItem.Count:Hide();
	end
	
	--TODO: Set up the item tooltip.
	self.itemData = itemData
	
	PlaySound(SOUNDKIT.UI_EPICLOOT_TOAST);
	Me.LootToastFrame_Play( self )
end

function Me.LootToastFrame_CloseImmediately( self )
	self:Hide();
	if (self.closeTimer) then
		self.closeTimer:Cancel()
		self.closeTimer = nil;
	end
end

function Me.LootToastFrame_Play( self )
	self:Show()
	self.animIn:Play()
	self.glow:Show()
	self.glow.animIn:Play()
	self.shine:Show()
	self.shine.animIn:Play()
	C_Timer.After( 3, function() 
		self.waitAndAnimOut:Play()
	end)
end

function Me.LootToastFrame_OnLoad( self )
	self:SetClampedToScreen( true )
	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag( "LeftButton" )
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )
	self:SetUserPlaced( true )
end

-- New Recipe Learned Frame

function Me.NewRecipeLearnedAlertFrame_SetUp(recipeID)
	local self = DiceMasterNewRecipeLearnedAlertFrame
	if not Me.Profile.recipes or not Me.Profile.recipes[recipeID] then
		return
	end 
	
	local recipeName = Me.Profile.recipes[recipeID].item.name;
	if recipeName then
		PlaySound(SOUNDKIT.UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST);

		self.Icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask");
		self.Icon:SetTexture(Me.Profile.recipes[recipeID].item.icon);

		self.Title:SetText("New Recipe Learned!");
		self.Name:SetText(recipeName);

		self.recipeID = recipeID;
	end
	
	self:Show()
	self.animIn:Play()
	self.glow:Show()
	self.glow.animIn:Play()
	self.shine:Show()
	self.shine.animIn:Play()
	C_Timer.After( 3, function() 
		self.waitAndAnimOut:Play()
	end)
end

function Me.NewRecipeLearnedAlertFrame_OnClick(self, button)
	if button == "RightButton" then
		self:Hide()
	elseif button == "LeftButton" then
		if (self.recipeID) then
			DiceMasterTradeSkillFrame:Show()
			Me.TradeSkillFrame_SetSelection(self.recipeID);
			Me.TradeSkillFrame_Update();
		end
	end
end

-- Group Loot Frame

local function CanRollNeedOnLoot( itemData )

	if #Profile.inventory >= 42 then
		return false, "Inventory is full."
	end
	
	return true
end

local function CanRollGreedOnLoot( itemData )

	if #Profile.inventory >= 42 then
		return false, "Inventory is full."
	end
	
	return true
end

local function CanRollDisenchantOnLoot( itemData )

	if Me.PermittedUse() and itemData.canDisenchant then
		return true;
	end
	
	return false, "Item cannot be disenchanted";
end

function Me.GroupLootContainer_OnLoad(self)
	self.rollFrames = {};
	self.reservedSize = 100;
	Me.GroupLootContainer_CalcMaxIndex(self);

	local alertSystem = AlertFrame:AddExternallyAnchoredSubSystem(self);
	AlertFrame:SetSubSystemAnchorPriority(alertSystem, 30);
end

function Me.GroupLootContainer_CalcMaxIndex(self)
	local maxIdx = 0;
	for k, v in pairs(self.rollFrames) do
		maxIdx = max(maxIdx, k);
	end
	self.maxIndex = maxIdx;
end

function Me.GroupLootContainer_AddFrame(self, frame)
	local idx = self.maxIndex + 1;
	for i=1, self.maxIndex do
		if ( not self.rollFrames[i] ) then
			idx = i;
			break;
		end
	end
	self.rollFrames[idx] = frame;

	if ( idx > self.maxIndex ) then
		self.maxIndex = idx;
	end

	Me.GroupLootContainer_Update(self);
	frame:Show();
end

function Me.GroupLootContainer_RemoveFrame(self, frame)
	local idx = nil;
	for k, v in pairs(self.rollFrames) do
		if ( v == frame ) then
			idx = k;
			break;
		end
	end

	if ( idx ) then
		self.rollFrames[idx] = nil;
		if ( idx == self.maxIndex ) then
			GroupLootContainer_CalcMaxIndex(self);
		end
	end
	frame:Hide();
	Me.GroupLootContainer_Update(self);
end

function Me.GroupLootContainer_ReplaceFrame(self, oldFrame, newFrame)
	for k, v in pairs(self.rollFrames) do
		if ( v == oldFrame ) then
			v:Hide();
			self.rollFrames[k] = newFrame;
			Me.GroupLootContainer_Update(self);
			newFrame:Show();
			return true;
		end
	end
	return false;	--Didn't find a frame to replace.
end

function Me.GroupLootContainer_Update(self)
	local lastIdx = nil;

	for i=1, self.maxIndex do
		local frame = self.rollFrames[i];
		if ( frame ) then
			frame:ClearAllPoints();
			frame:SetPoint("CENTER", self, "BOTTOM", 0, self.reservedSize * (i-1 + 0.5));
			lastIdx = i;
		end
	end

	if ( lastIdx ) then
		self:SetHeight(self.reservedSize * lastIdx);
		self:Show();
	else
		self:Hide();
	end
end

function Me.GroupLootFrame_OpenNewFrame( itemData, rollTime, sender )
	local frame;
	for i=1, 4 do
		frame = _G["DiceMasterGroupLootFrame"..i];
		if ( not frame:IsShown() ) then
			frame.itemData = itemData;
			frame.rollTime = rollTime;
			frame.sender = sender;
			frame.Timer:SetMinMaxValues(0, 60);
			groupLootItemsRecipient[ itemData.guid ] = {};
			
			for k, v in pairs( itemData ) do
				groupLootItemsRecipient[ itemData.guid ][k] = v;
			end
			
			Me.GroupLootContainer_AddFrame(DiceMasterGroupLootContainer, frame);
			return;
		end
	end
end

function Me.GroupLootFrame_EnableLootButton(button)
	button:Enable();
	button:SetAlpha(1.0);
	SetDesaturation(button:GetNormalTexture(), false);
end

function Me.GroupLootFrame_DisableLootButton(button)
	button:Disable();
	button:SetAlpha(0.35);
	SetDesaturation(button:GetNormalTexture(), true);
end

local function GetNumActiveGroupLootFrames()
	local f = 0
	for i = 1, 4 do
		frame = _G["DiceMasterGroupLootFrame"..i];
		if ( frame:IsShown() ) then
			f = f + 1
		end
	end
	return f
end

local function PickGroupLootWinner( guid, dist, channel )
	if not groupLootItems[ guid ] then
		return
	end
	
	local playerName = "";
	local roll = 0;
	local rollType = "Greed";
	local rolls = groupLootItems[guid].rolls;
	
	for i = 1, #rolls do
		if ( rolls[i].rollType == "Greed" or rolls[i].rollType == "Disenchant" ) and rollType == "Need" then
			-- ignore
		elseif rolls[i].roll > roll or ( rolls[i].rollType == "Need" and ( rollType == "Greed" or rollType == "Disenchant" ) ) then
			playerName = rolls[ i ].name;
			roll = rolls[ i ].roll
			rollType = rolls[ i ].rollType
		end
	end
	
	if playerName == "" and roll == 0 then
		-- everyone passed
		local msg = Me:Serialize( "ITEMMSG", {
			ro = "Pass";
			guid = guid;
			amount = groupLootItems[ guid ].amount;
		});
		Me:SendCommMessage( "DCM4", msg, dist, channel, "ALERT" )
	else
		local msg = Me:Serialize( "ITEMMSG", {
			pn = playerName;
			ro = roll;
			rt = rollType;
			wi = true;
			guid = guid;
			amount = groupLootItems[ guid ].amount;
		});
		Me:SendCommMessage( "DCM4", msg, dist, channel, "ALERT" )
	end
	
	Me.TraitEditor_UpdateInventory()
end

function Me.GroupLootFrame_GroupLoot( item, button )
	
	if not Me.IsLeader( true ) then
		UIErrorsFrame:AddMessage( "You must be the group leader or a raid assistant to distribute items.", 1.0, 0.0, 0.0 );
		return
	end
	
	if groupLootItems[ item.guid ] then
		UIErrorsFrame:AddMessage( "You are already dispensing that item.", 1.0, 0.0, 0.0 );
		return
	end
	
	if GetNumActiveGroupLootFrames() >= 4 then
		UIErrorsFrame:AddMessage( "You can only distribute four items at a time.", 1.0, 0.0, 0.0 );
		return
	end
	
	SetItemButtonDesaturated( button, true )
	
	local dist = "WHISPER"
	local channel = UnitName( "player" )
	if IsInRaid( LE_PARTY_CATEGORY_HOME ) then
		dist = "RAID"
		channel = nil
	elseif IsInGroup( LE_PARTY_CATEGORY_HOME ) then
		dist = "RAID"
		channel = nil
	end
	
	Me.Inspect_SendItemSlot( button.itemIndex, false, dist, channel )
	
	groupLootItems[ item.guid ] = {
		rolls = {};
		amount = item.stackCount;
	}
	
	C_Timer.After( 60, function() 
		PickGroupLootWinner( item.guid, dist, channel )
	end)
	
	local msg = Me:Serialize( "ITEMLOOT", item );
	Me:SendCommMessage( "DCM4", msg, dist, channel, "ALERT" )
end

function Me.GroupLootFrame_Roll( self, rollType )
	if not self:GetParent().itemData or not rollType then
		return
	end
	
	local itemLink = Me.GetItemLink( self:GetParent().sender, self:GetParent().itemData.guid ) or "[Unknown Item]"
	if self:GetParent().itemData.stackCount > 1 then
		itemLink = itemLink .. "x" .. self:GetParent().itemData.stackCount
	end	
	
	if rollType == "Pass" then
		Me.PrintMessage( "|cFF00aa00[Loot]: You passed on: " .. itemLink, "SYSTEM" )
	else
		Me.PrintMessage( "|cFF00aa00[Loot]: You have selected " .. rollType .. " for: " .. itemLink, "SYSTEM" )
	end
	
	local msg = Me:Serialize( "ITEMROLL", {
		id = self:GetParent().itemData.guid;
		rt = rollType;
	});
	Me:SendCommMessage( "DCM4", msg, "WHISPER", self:GetParent().sender, "ALERT" )
end

function Me.GroupLootFrame_OnShow(self)
	local item = self.itemData
	if not(item) or not(item.name) then
		Me.GroupLootContainer_RemoveFrame(DiceMasterGroupLootContainer, self);
		return;
	end
	
	self.IconFrame.Icon:SetTexture( item.icon );
	self.IconFrame.Border:SetAtlas(LOOT_BORDER_BY_QUALITY[ item.quality ] or nil);
	self.Name:SetText( item.name );
	local color = ITEM_QUALITY_COLORS[ item.quality ];
	self.Name:SetVertexColor(color.r, color.g, color.b);
	self.Border:SetVertexColor(color.r, color.g, color.b);
	if ( item.stackCount > 1 ) then
		self.IconFrame.Count:SetText( item.stackCount );
		self.IconFrame.Count:Show();
	else
		self.IconFrame.Count:Hide();
	end
	
	local canNeed, reasonNeed = CanRollNeedOnLoot( item )
	local canGreed, reasonGreed = CanRollGreedOnLoot( item )
	local canDisenchant, reasonDisenchant = CanRollDisenchantOnLoot( item )

	if ( canNeed ) then
		Me.GroupLootFrame_EnableLootButton(self.NeedButton);
		self.NeedButton.reason = nil;
	else
		Me.GroupLootFrame_DisableLootButton(self.NeedButton);
		self.NeedButton.reason = reasonNeed;
	end
	if ( canGreed) then
		Me.GroupLootFrame_EnableLootButton(self.GreedButton);
		self.GreedButton.reason = nil;
	else
		Me.GroupLootFrame_DisableLootButton(self.GreedButton);
		self.GreedButton.reason = reasonGreed;
	end
	if Me.PermittedUse() then
		self.DisenchantButton:Show()
		if ( canDisenchant ) then
			Me.GroupLootFrame_EnableLootButton(self.DisenchantButton);
			self.GreedButton.reason = nil;
		else
			Me.GroupLootFrame_DisableLootButton(self.DisenchantButton);
			self.DisenchantButton.reason = reasonDisenchant;
		end
	else
		self.DisenchantButton:Hide()
	end
	self.Timer:SetFrameLevel(self:GetFrameLevel() - 1);
	
	C_Timer.After( 60, function() 
		Me.GroupLootContainer_RemoveFrame(DiceMasterGroupLootContainer, self);
	end)
end

local function GetTimeLeft( rollTime )
	if time() - rollTime < 60 then
		return 60 - ( time() - rollTime );
	end
	return 0;
end

function Me.GroupLootFrame_OnUpdate(self, elapsed)
	local left = GetTimeLeft(self:GetParent().rollTime);
	local min, max = self:GetMinMaxValues();
	if ( (left < min) or (left > max) ) then
		left = min;
	end
	self:SetValue(left);
end

---------------------------------------------------------------------------
--  Receive a Loot Toast.
--  na = name							string
-- 	ic = icon							string
--  qu = quality						number
--  bi = binds							string
--  sl = slot							string
--  ar = armour type 					string
--  us = use							string
--  re = requirement					string
--  fl = flavour						string
--  ii = item index						number

function Me.LootToast_OnToast( data, dist, sender )	 
	-- sanitize message
	
	if not data.name or not data.icon or not data.guid then
	   
		return
	end
	
	local itemLink = Me.GetItemLink( UnitName("player"), data.guid ) or "[Unknown Item]"
	
	local toastText
	if not( data.labelText ) then
		toastText = "You receive item:"
	else
		toastText = data.labelText .. ":"
	end
	
	if data.amount == 1 then
		Me.PrintMessage( "|cFF00aa00"..toastText.." " .. itemLink .. ".|r", "SYSTEM" )
	else
		Me.PrintMessage( "|cFF00aa00"..toastText.." " .. itemLink .. "x" .. data.amount .. ".|r", "SYSTEM" )
	end
	
	DiceMasterItemAnim.animIcon:SetTexture( data.icon );
	DiceMasterItemAnim:SetPoint( "CENTER", DiceMasterTraitEditorInventoryTab, 0, 0 )
	DiceMasterItemAnim:Show()
	
	Me.LootToastFrame_SetUp( DiceMasterItemToastAlertFrame, data )
end

---------------------------------------------------------------------------
--  Received a Group Loot Option.

function Me.LootToast_OnGroupLoot( data, dist, sender )	 
	-- sanitize message
	
	if not data.name or not data.icon or not data.guid then
	   
		return
	end
	
	local itemLink = Me.GetItemLink( sender, data.guid ) or "[Unknown Item]"
	if data.stackCount > 1 then
		itemLink = itemLink .. "x" .. data.stackCount
	end
	
	Me.PrintMessage( "|cFF00aa00[Loot]: " .. itemLink, "SYSTEM" )
	
	Me.GroupLootFrame_OpenNewFrame( data, time(), sender )
end

---------------------------------------------------------------------------
--  Received a Group Loot Option.

function Me.LootToast_OnGroupLootMessage( data, dist, sender )	 
	-- sanitize message
	
	if not data.guid then
		return
	end
	
	local playerName = tostring( data.pn )
	local roll = tonumber( data.ro )
	local rollType = tostring( data.rt )
	
	local itemLink = Me.GetItemLink( sender, data.guid )
	if data.amount and data.amount > 1 then
		itemLink = itemLink .. "x" .. data.amount
	end
	
	if data.ro == "Pass" then
		Me.PrintMessage( "|cFF00aa00[Loot]: Everyone passed on: " .. itemLink, "SYSTEM" )
		groupLootItems[ data.guid ] = nil
		Me.TraitEditor_UpdateInventory()
	elseif data.wi and playerName == UnitName("player") then
		Me.PrintMessage( "|cFF00aa00[Loot]: You (" .. rollType .. " - " .. roll .. ") Won: " .. itemLink, "SYSTEM" )
		
		if groupLootItemsRecipient[ data.guid ] then
			
			if rollType == "Disenchant" then
				Me.Disenchant_ProduceDust( groupLootItemsRecipient[ data.guid ].quality )
			else
				local item = {}
				for k, v in pairs( groupLootItemsRecipient[ data.guid ] ) do
					item[k] = v;
				end
				
				local stacks = Me.FindAllStacks( data.guid );
				
				if Me.FindTotalStacks( data.guid ) > 0 then
					Me.ProduceItem( data.guid, data.amount )
				else
					if item then
						Me.CreateItem( item, data.amount )
					else
						UIErrorsFrame:AddMessage( "Error producing item.", 1.0, 0.0, 0.0 );
						return
					end
				end
				
				item.amount = data.amount
				local msg = Me:Serialize( "ITEM", item );
				Me:SendCommMessage( "DCM4", msg, "WHISPER", UnitName("player"), "ALERT" )
			end
			
			groupLootItemsRecipient[ data.guid ] = nil;
		end
	elseif data.wi then
		Me.PrintMessage( "|cFF00aa00[Loot]: " .. playerName .. " (" .. rollType .. " - " .. roll .. ") Won: " .. itemLink, "SYSTEM" )
		Me.PrintMessage( "|cFF00aa00[Loot]: " .. playerName .. " receives loot: " .. itemLink, "SYSTEM" )
	elseif playerName == UnitName("player") then
		if rollType ~= "Pass" then
			Me.PrintMessage( "|cFF00aa00[Loot]: You have rolled " .. rollType .. " - " .. roll .. " for: " .. itemLink, "SYSTEM" )
		end
	else
		if rollType == "Pass" then
			Me.PrintMessage( "|cFF00aa00[Loot]: " .. playerName .. " passed on: " .. itemLink, "SYSTEM" )
		else
			Me.PrintMessage( "|cFF00aa00[Loot]: " .. playerName .. " rolled " .. rollType .. " - " .. roll .. " for: " .. itemLink, "SYSTEM" )
		end
	end
	
	if data.wi and sender == UnitName("player") and groupLootItems[ data.guid ] then
		Me.ConsumeItem( data.guid, groupLootItems[ data.guid ].amount )
		groupLootItems[ data.guid ] = nil
		Me.TraitEditor_UpdateInventory()
	end
end

---------------------------------------------------------------------------
--  Received a Group Loot Roll.

function Me.LootToast_OnGroupLootRoll( data, dist, sender )	 
	-- sanitize message
	if not data or not data.id or not data.rt then
		return
	end
	
	local dist = "WHISPER"
	local channel = sender
	if UnitInRaid( sender ) then
		dist = "RAID";
		channel = nil
	elseif UnitInParty( sender ) then
		dist = "PARTY"
		channel = nil
	end
	
	local guid = tostring( data.id )
	local rollType = tostring( data.rt )
	
	if groupLootItems[ guid ] then
		-- group loot rolls are done internally to prevent cheating :)
		local roll = random( 100 )
		
		if rollType == "Pass" then
			roll = 0;
		end
		
		if groupLootItems[ guid ].rolls then
			local rollData = {
				name = sender;
				roll = roll;
				rollType = rollType;
			}
			tinsert( groupLootItems[ guid ].rolls, rollData );
		end
		
		local msg = Me:Serialize( "ITEMMSG", {
			pn = sender;
			ro = roll;
			rt = rollType;
			guid = guid;
			amount = groupLootItems[guid].amount;
		});
		Me:SendCommMessage( "DCM4", msg, dist, channel, "ALERT" )
		
		local groupMembers = GetNumGroupMembers( LE_PARTY_CATEGORY_HOME )
		for i = 1, GetNumGroupMembers( LE_PARTY_CATEGORY_HOME ) do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
			if not online then
				groupMembers = groupMembers - 1
			end
		end
		
		if #groupLootItems[ guid ].rolls >= groupMembers then
			-- everyone has rolled so pick a winner
			PickGroupLootWinner( guid, dist, channel )
		end
	end
end

---------------------------------------------------------------------------
--  Received a Master Loot Option.

function Me.LootToast_OnMasterLootMessage( data, dist, sender )	 
	-- sanitize message
	
	if not data.item or not data.pn then
		return
	end
	
	local playerName = tostring( data.pn )
	
	local itemLink = Me.GetItemLink( sender, data.item.guid )
	if data.amount and data.amount > 1 then
		itemLink = itemLink .. "x" .. data.amount
	end
	
	if data.wi and playerName == UnitName("player") then
		local item = {}
		for k, v in pairs( data.item ) do
			item[k] = v;
		end
		
		local stacks = Me.FindAllStacks( data.item.guid );
		
		if Me.FindTotalStacks( data.item.guid ) > 0 then
			Me.ProduceItem( data.item.guid, data.amount )
		else
			if item then
				Me.CreateItem( item, data.amount )
			else
				UIErrorsFrame:AddMessage( "Error producing item.", 1.0, 0.0, 0.0 );
				return
			end
		end
		
		item.amount = data.amount
		local msg = Me:Serialize( "ITEM", item );
		Me:SendCommMessage( "DCM4", msg, "WHISPER", UnitName("player"), "ALERT" )
	elseif data.wi then
		Me.PrintMessage( "|cFF00aa00" .. playerName .. " receives loot: " .. itemLink, "SYSTEM" )
	end
end