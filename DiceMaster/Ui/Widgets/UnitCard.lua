-------------------------------------------------------------------------------
-- Dice Master (C) 2024 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4

-------------------------------------------------------------------------------
-- Handler for unit cards.
--

local function OnMouseDown( self )
	
	-- TODO
	 
end

local function OnEnter( self )
	if DiceMasterUnitCardDragDummy:IsShown() then
		self.Highlight:Show();
		self:SetAlpha(0.5);
	end
end

local function OnLeave( self )
	self.Highlight:Hide();
	self:SetAlpha(1);
end

-------------------------------------------------------------------------------

local methods = {
	
	---------------------------------------------------------------------------
	-- Allow this button to be dragged.
	--

	SetDraggable = function( self )
		self:RegisterForDrag("LeftButton");
		self:SetScript("OnDragStart", function(self, button)
			self:SetAlpha( 0.5 );
			DiceMasterUnitCardDragDummy:Show();
			DiceMasterUnitCardDragDummy:SetUnit("player");
			DiceMasterUnitCardDragDummy:SetPortraitZoom(1);
			DiceMasterUnitCardDragDummy.Highlight:Hide();
			DiceMasterUnitCardDragDummy.Name:SetText( self.Name:GetText() );
			DiceMasterUnitCardDragDummy:SetID( self:GetID() );
			DiceMasterUnitCardDragDummy:EnableMouse(false);
		end);

		for card in DiceMasterInitiativeBar.Cards:EnumerateActive() do
			card.MiddleFrame:Show();
		end
	end;

	-------------------------------------------------------------------------------
	-- When the healthbar frame is clicked.
	--

	OnHealthClicked = function( self, button )
		local delta = 0
		if button == "LeftButton" then
			delta = 1
		elseif button == "RightButton" then
			delta = -1
		else
			return
		end
	  	
		if IsShiftKeyDown() and button == "LeftButton" then
			-- Open dialog for custom value.
			StaticPopup_Show("DICEMASTER4_SETUNITHEALTHMAX", nil, nil, self)
		elseif IsControlKeyDown() and button == "LeftButton" then
			-- Open dialog for custom value.
			StaticPopup_Show("DICEMASTER4_SETUNITHEALTHVALUE", nil, nil, self)
		elseif IsAltKeyDown() then
			if Me.OutOfRange( self.armour+delta, 0, 1000 ) then
				return
			end
			self.armour = self.armour + delta;
		else
			if Me.OutOfRange( self.health+delta, 0, self.maxHealth ) then
				return
			end
			self.health = Me.Clamp( self.health + delta, 0, self.maxHealth )
		end
	
		self.HealthFrame.text:SetText( self.health );
		if self.health < self.maxHealth then
			self.HealthFrame.text:SetTextColor(1,0,0);
		else
			self.HealthFrame.text:SetTextColor(1,1,1);
		end
		if self.armour > 0 then
			self.HealthFrame.armourText:SetText( self.armour );
			self.HealthFrame.armour:Show();
		else
			self.HealthFrame.armourText:SetText( "" );
			self.HealthFrame.armour:Hide();
		end
	end
}

-------------------------------------------------------------------------------
-- Initialize.
--
function Me.UnitCard_Init( self )

	for k, v in pairs( methods ) do
		self[k] = v;
	end
	
	self:EnableMouse(true);
	self:SetScript( "OnMouseDown", OnMouseDown );
	self:SetScript( "OnEnter", OnEnter );
	self:SetScript( "OnLeave", OnLeave );
		
	self.health		= 10;
	self.maxHealth	= 10;
	self.armour		= 0;

	self.HealthFrame.text:SetText( self.health );
end
