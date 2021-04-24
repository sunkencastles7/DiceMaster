-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Loot Toast interface.
--

local Me = DiceMaster4

local DICEMASTER_LOOT_BORDERS = {
	[1] = nil,
	[2] = "loottoast-itemborder-green",
	[3] = "loottoast-itemborder-blue",
	[4] = "loottoast-itemborder-purple",
	[5] = "loottoast-itemborder-orange",
	[6] = "loottoast-itemborder-artifact",
	[7] = "loottoast-itemborder-heirloom",
}

function Me.LootToastFrame_OnEnter( self )
	GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )
	-- TODO: Set item tooltip
	local color = ITEM_QUALITY_COLORS[ self.itemData.quality ];
	GameTooltip:AddLine( self.itemData.name, color.r, color.g, color.b, true )
	
	if self.itemData.soulbound then
		GameTooltip:AddLine( "Binds when picked up", 1, 1, 1, true)
	end
	
	if self.itemData.whiteText1 or self.itemData.whiteText2 then
		GameTooltip:AddDoubleLine(self.itemData.whiteText1, self.itemData.whiteText2, 1, 1, 1, 1, 1, 1, true)
	end
	
	if self.itemData.useText then
		GameTooltip:AddLine(self.itemData.useText, 0, 1, 0, true)
	end
	
	if self.itemData.requirement then
		GameTooltip:AddLine(self.itemData.requirement, 1, 1, 1, true)
	end
	
	if self.itemData.flavorText then
		GameTooltip:AddLine(self.itemData.flavorText, 1, 0.81, 0, true)
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
	--if itemData.labelText then
		--self.Label:SetText( itemData.labelText );
	--end
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

---------------------------------------------------------------------------
--  Receive a Loot Toast request.
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
	
	local found_item = false;
	
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == data.guid then
			found_item = i;
			break
		end
	end
	
	local icon = Me.inspectData[UnitName("player")].inventory[tonumber(found_item)].icon
	local colorHex = ITEM_QUALITY_COLORS[ Me.inspectData[UnitName("player")].inventory[tonumber(found_item)].quality ].hex or "|cffffffff";
	local itemLink = string.format("|T"..icon..":16|t "..colorHex.."|HDiceMaster4Item:"..UnitName("player")..":"..found_item.."|h[%s]|h|r", data.name);
	
	if data.amount == 1 then
		Me.PrintMessage( "|cFF00aa00You receive item: " .. itemLink .. ".|r", "SYSTEM" )
	else
		Me.PrintMessage( "|cFF00aa00You receive item: " .. itemLink .. "x" .. data.amount .. ".|r", "SYSTEM" )
	end
	
	DiceMasterItemAnim.animIcon:SetTexture( icon );
	DiceMasterItemAnim:SetPoint( "CENTER", DiceMasterTraitEditorInventoryTab, 0, 0 )
	DiceMasterItemAnim:Show()
	
	Me.LootToastFrame_SetUp( DiceMasterItemToastAlertFrame, data )
end
