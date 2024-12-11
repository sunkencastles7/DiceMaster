-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Unit Manager Frame.
--

local Me = DiceMaster4
local Profile = DiceMaster4_Bestiary.Profile

local NUM_DISPLAYED_UNITS = 500;
local UNIT_BUTTON_HEIGHT = 46;
local UNIT_EDITOR_UNITS = {
	{
		modelID = 82702;
		name = "Witch";
		description = "The Witches who flock to Horned God’s patronage are often the victims of persecution, and the Witch Hunts which have historically run rampant throughout Drustvar. Some are naturally born with their dark gifts, while others are initiated to Maleficium (or “dark magic”) by voluntarily selling their souls to the Dark Lord himself. Their reasons are not always motivated by self-interest - indeed, some feel desperately compelled to join the Horned God’s cult out of fear of persecution for their inborn powers. Many more submit themselves willingly to their dark practice, greedy for power, influence, and life everlasting. Whatever their reasons, a Witch’s soul is known to become darker, more ruthless, and cunning over time.|n|nCast out by society, they form tightly-knit sisterhoods known as Hives (or Covens) - both because a Witch knows she depends upon her sisters to ensure her own survival, and also to share their power collectively. Despite how they may choose to appear to their prey, a Witch is never truly alone, and they are known to seclude themselves in vast, underground strongholds in the subsoil of the dark woods of Drustvar.";
		raidMarker = 3;
		isVisible = true;
		health = 4;
		maxHealth = 10;
		armour = 3;
		quantity = 1;
		statistics = {
			{ name = "Alignment", value = "Neutral Evil", tooltip = "A general measure of the creature’s moral and personal attitudes." };
			{ name = "Classification", value = "Monstrous Humanoid", tooltip = "The category of monster that the creature belongs to for abilities that affect a certain monster type." };
			{ name = "Health", value = "7<HP>", tooltip = "The amount of base health points the creature has in combat." };
			{ name = "Armour", value = "0<AR>", tooltip = "The amount of base armour the creature has in combat." };
			{ name = "Attack Type", value = "Spell", tooltip = "The type of attack used for the creature’s basic attacks." };
			{ name = "Attack Damage", value = "3", tooltip = "The amount of damage caused by the creature’s basic attacks." };
			{ name = "Maximum Damage", value = "4", tooltip = "The maximum amount of damage the creature is able to inflict using any of its abilities. This is also the amount of damage dealt by its critically successful attacks." };
			{ name = "Armour Type", value = "Unarmoured", tooltip = "The type of armour worn by the creature." };
			{ name = "Difficulty Class", value = "12", tooltip = "The number you must score on your roll against the creature in order to succeed." };
			{ name = "Speed", value = "Moderate", tooltip = "The approximate movement speed of the creature." };
			{ name = "Size", value = "Medium", tooltip = "The approximate scale of the creature in comparison to the average human." };
			{ name = "Difficulty", value = "Moderate", tooltip = "A rough estimate of how challenging or deadly the creature is when faced in combat." };
		};
		traits = {
			{
				name = "Bewitch";
				icon = "Interface/AddOns/DiceMaster/Icons/diablo3_smokescreen";
				uses = "1 Use";
				description = "The Witch enthralls a chosen target, forcing them to fight for her for three turns, or until they roll a successful Will Save.|n|n|cFFFF0000If the Witch perishes, this effect is broken instantly.|r";
			};
			{
				name = "Witchflight";
				icon = "Interface/AddOns/DiceMaster/Icons/diablo3_companion";
				uses = "1 Use";
				description = "The Witch disperses into a flock of ravens, attempting to flee. Only a successful Grapple roll can prevent her from escaping, Stunning her for one turn.";
			};
			{
				name = "Crone's Mark";
				icon = "Interface/AddOns/DiceMaster/Icons/diablo3_markedfordeath";
				uses = "1 Use";
				description = "The Witch marks a chosen target with an omen of doom. Their very next Defence, Spell Defence, or Fortitude Save roll must be made with Disadvantage.|n|nThis effect persists until it has been triggered.";
			};
		};
	},
}

StaticPopupDialogs["DICEMASTER4_SETUNITHEALTHVALUE"] = {
  text = "Set Health value:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText(data.health)
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText()) or data.health
	text = math.floor( text )
	if Me.OutOfRange( text, 0, data.maxHealth ) then
		return
	end
	data.health = text
	
	local unitEditor = DiceMasterUnitManagerUnitEditor
	local barFrame = unitEditor.UnitInfoFrame.ScrollFrame.Child.HealthBar
	
    barFrame:SetValue( data.health );
    barFrame:SetMax( data.maxHealth );
    barFrame:SetArmour( data.armour );

	Profile.units[ unitEditor.selectedUnitID ].health = data.health;
	Profile.units[ unitEditor.selectedUnitID ].maxHealth = data.maxHealth;
	Profile.units[ unitEditor.selectedUnitID ].armour = data.armour;
	Me.UnitManagerUnitEditor_UpdateUnitList()
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_SETUNITHEALTHMAX"] = {
  text = "Set maximum Health value:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText(data.maxHealth)
	self.editBox:SetNumeric()
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText()) or data.maxHealth
	text = math.floor( text )
	if Me.OutOfRange( text, 1, 1000 ) then
		return
	end
	data.maxHealth = text
	
	local unitEditor = DiceMasterUnitManagerUnitEditor
	local barFrame = unitEditor.UnitInfoFrame.ScrollFrame.Child.HealthBar
	
    barFrame:SetValue( data.health );
    barFrame:SetMax( data.maxHealth );
    barFrame:SetArmour( data.armour );

	Profile.units[ unitEditor.selectedUnitID ].health = data.health;
	Profile.units[ unitEditor.selectedUnitID ].maxHealth = data.maxHealth;
	Profile.units[ unitEditor.selectedUnitID ].armour = data.armour;
	Me.UnitManagerUnitEditor_UpdateUnitList()
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- local function SetModelSize( self, size )
	-- if size == "small" then
		-- self:SetViewInsets( 80, 80, 80, 60 )
		-- self.Nameplate:SetPoint( "CENTER", self, 0, 10 )
	-- elseif size == "medium" then
		-- self:SetViewInsets( 40, 40, 40, 30 )
		-- self.Nameplate:SetPoint( "CENTER", self, 0, 30 )
	-- elseif size == "large" then
		-- self:SetViewInsets( 0, 0, 0, 0 )
		-- self.Nameplate:SetPoint( "CENTER", self, 0, 50 )
	-- end
-- end

function Me.UnitManagerUnitGrid_OnLoad(self)

	-- Create Grid
	local alpha = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }
	
	self.squares = {}
	for y = 0, 9 do
		for x = 0, 12 do
			local button = CreateFrame( "Button", nil, self.Inset, "DiceMasterUnitGridButtonTemplate" )
			button:SetPoint( "TOPLEFT", self.Inset, 50*x+10, -50*y-10 )
			button.Text:SetText( alpha[ y + 1 ] .. ( x + 1 ) )
			
			if x == 3 and y == 3 then
				button.Model.Actor:SetModelByFileID( 1835134 )
				button.Model.Actor:SetScale( 0.15 )
				button.occupied = true;
			end
			
			if x == 4 and y == 3 then
				button.Model.Actor:SetModelByCreatureDisplayID( 1061 )
				button.Model.Nameplate:SetText("Abomination")
				button.displayID = 1061;
				button.occupied = true;
			end
			
			if x == 5 and y == 3 then
				button.Model.Actor:SetModelByFileID( 2061082 )
				button.Model.Actor:SetScale( 0.1 )
				button.occupied = true;
			end
			
			table.insert( self.squares, button )
			button.x = x
			button.y = y
			button.index = #self.squares
		end
	end
end

local function isAdjacentCell( x, y, posx, posy )
	if x == posx and y == posy + 1 then
		return "up"
	elseif x == posx and y == posy - 1 then
		return "down"
	elseif y == posy and x == posx + 1 then
		return "right"
	elseif y == posy and x == posx - 1 then
		return "left"
	end
	return false
end

local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function TurnModel( model, direction )
	local radians
	if direction == "right" then
		radians = 0
	elseif direction == "left" then
		radians = math.pi*-1
	elseif direction == "up" then
		radians = math.pi/2*-1
	elseif direction == "down" then
		radians = math.pi/2
	end
	
	--model:SetAnimation( 11 )
	model:SetScript("OnUpdate", function(self)
		if round( self.Actor:GetYaw(), 1 ) == round( radians, 1 ) then
			self:SetScript("OnUpdate", nil)
			self.Actor:SetAnimation( 0 )
		elseif self.Actor:GetYaw() > radians then
			self.Actor:SetYaw( self.Actor:GetYaw() - 0.1 )
		elseif self.Actor:GetYaw() < radians then
			self.Actor:SetYaw( self.Actor:GetYaw() + 0.1 )
		end
	end)
end

local function HighlightAvailableCells( self )
	local availableCells = { self.index - 13, self.index + 13, self.index - 1, self.index + 1 }
	for i = 1, #DiceMasterUnitManagerUnitGrid.squares do
		if tContains( availableCells, i ) and not DiceMasterUnitManagerUnitGrid.squares[i].occupied then
			UIFrameFadeIn( DiceMasterUnitManagerUnitGrid.squares[i].Available, 1, 0, 0.25 )
		elseif DiceMasterUnitManagerUnitGrid.squares[i].Available:IsShown() then
			UIFrameFadeOut( DiceMasterUnitManagerUnitGrid.squares[i].Available, 1, 0.25, 0 )
			C_Timer.After( 1, function() DiceMasterUnitManagerUnitGrid.squares[i].Available:Hide() end )
		else
			DiceMasterUnitManagerUnitGrid.squares[i].Available:Hide()
		end
	end
end

local function SelectCell( self )
	if DiceMasterUnitManagerUnitGrid.selected then
		DiceMasterUnitManagerUnitGrid.squares[DiceMasterUnitManagerUnitGrid.selected]:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square", "ADD")
		DiceMasterUnitManagerUnitGrid.squares[DiceMasterUnitManagerUnitGrid.selected]:UnlockHighlight()
	end
	DiceMasterUnitManagerUnitGrid.selected = self.index
	self:SetHighlightTexture("Interface/Buttons/CheckButtonHilight", "ADD")
	self:LockHighlight()
	self.Model.Nameplate:Show();
	HighlightAvailableCells( self )
end

local function TransferCell( cell, target )
	target.Model.Actor:SetModelByCreatureDisplayID( cell.displayID )
	target.Model.Actor:SetYaw( cell.Model.Actor:GetYaw() )
	target.Model.Nameplate:SetText( cell.Model.Nameplate:GetText() )
	--SetModelSize( target.Model, cell.size )
	target.size = cell.size
	target.occupied = true
	target.displayID = cell.displayID
	
	cell.Model.Actor:SetModelByCreatureDisplayID(6908)
	cell.Model.Actor:SetYaw( 0 )
	cell.Model.Nameplate:SetText( nil )
	--SetModelSize( cell.Model, "medium" )
	cell.size = "medium"
	cell.occupied = false	
	cell.displayID = nil
	
	SelectCell( target )
end

-- model = the model to move
-- direction = left, right, up, or down
-- distance = number of grid squares to move

local function Move( model, target, direction, distance )
	local mod = 50 * distance
	local elapsed = 0
	if direction == "right" then
		x = 1
		y = 0
	elseif direction == "left" then
		x = -1
		y = 0
	elseif direction == "up" then
		x = 0
		y = -1
	elseif direction == "down" then
		x = 0
		y = 1
	end
	
	local speed = 1
	if model:GetParent().size == "small" then
		speed = 2
	elseif model:GetParent().size == "medium" then
		speed = 1
	elseif model:GetParent().size == "large" then
		speed = 0.5
	end
	
	model.Actor:SetAnimation( 4, nil, speed )
	local _, _, _, xOrig, yOrig = model:GetPoint(1)
	local timer = C_Timer.NewTicker( 0.01, function( self )
		elapsed = elapsed + speed
		local point, relativeTo, relativePoint, xOfs, yOfs = model:GetPoint(1)
		if round( xOfs, 1 ) == round( xOrig + (x*mod), 1 ) and round( yOfs, 1 ) == round( yOrig + (y*mod), 1 ) then
			self:Cancel()
			model:SetPoint( point, relativeTo, relativePoint, xOrig, yOrig )
			TransferCell( model:GetParent(), target:GetParent() )
			model.Actor:SetAnimation( 0 )
		else
			model:ClearAllPoints()
			model:SetPoint( point, relativeTo, relativePoint, xOrig + x*elapsed, yOrig + y*elapsed )
		end
	end)
end

local function Attack( attacker, victim )
	attacker.Actor:SetAnimation( 16 )
	victim.Actor:SetAnimation( 9 )
	victim.Actor:SetSpellVisualKit( 70253, true )
	victim.AnimIn:Play()
	victim.DamageText:SetText( "-1" )
	UIFrameFadeOut( victim.DamageText, 2, 1, 0 )
end

function Me.UnitManagerUnitGrid_OnClick( self, button )
	local grid = DiceMasterUnitManagerUnitGrid
	local target = grid.squares[grid.selected]
	if button == "LeftButton" then
		SelectCell( self )
	elseif button == "RightButton" then
		if target and target.occupied then
			if isAdjacentCell( self.x, self.y, target.x, target.y ) then
				local model = target.Model
				local victim = self.Model
				local direction = isAdjacentCell( self.x, self.y, target.x, target.y )
				TurnModel( model, direction )
				if not self.occupied then
					grid.X:SetPoint( "CENTER", self )
					UIFrameFadeOut( grid.X, 1, 1, 0 )
					C_Timer.After( 1, function(self) Move( model, victim, direction, 1 ) end)
				else
					C_Timer.After( 1, function(self) Attack( model, victim ) end)
				end
			end
		else
			self.Model.Actor:SetModelByFileID( 1545660 )
			self.Model.Actor:SetScale( 0.5 )
			self.occupied = true;
		end
	end
end

function Me.UnitManagerUnitEditor_OnLoad(self)
	self.ListScrollFrame.update = Me.UnitManagerUnitEditor_UpdateUnitList;
	self.ListScrollFrame.scrollBar.doNotHide = true;
	HybridScrollFrame_CreateButtons(self.ListScrollFrame, "DiceMasterUnitListButtonTemplate", 22, 0);
	
	self.UnitInfoFrame.ScrollFrame.Child.StatisticsFrame.bulletPool = CreateFramePool("DiceMasterUnitInfoStatisticsTemplate", self.UnitInfoFrame.ScrollFrame.Child );
	self.UnitInfoFrame.ScrollFrame.Child.TraitsFrame.bulletPool = CreateFramePool("DiceMasterUnitInfoTraitTemplate", self.UnitInfoFrame.ScrollFrame.Child );
	
	self.UnitInfoFrame.ScrollFrame.Child.usedHeaders = { self.UnitInfoFrame.ScrollFrame.Child.TraitsFrame, self.UnitInfoFrame.ScrollFrame.Child.StatisticsFrame, self.UnitInfoFrame.ScrollFrame.Child.DescriptionFrame }
end

function Me.UnitManagerUnitEditor_UpdateUnitList()
	local unitEditor = DiceMasterUnitManagerUnitEditor
	local scrollFrame = unitEditor.ListScrollFrame;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;

	unitEditor.numUnits = #Profile.units
	local showUnits = true;
	if  ( unitEditor.numUnits < 1 ) then
		-- display the no units message on the right hand side
		unitEditor.RightInset.NoUnits:Show();
		showUnits = false;
	else
		unitEditor.RightInset.NoUnits:Hide();
	end

	for i=1, #buttons do
		local button = buttons[i];
		local displayIndex = i + offset;
		if ( displayIndex <= unitEditor.numUnits and showUnits ) then
			local index = displayIndex;
			local unitData = Profile.units[index];

			button.name:SetText(unitData.name);
			SetPortraitTextureFromCreatureDisplayID(button.portrait.Portrait, unitData.modelID);
			button.portrait.Portrait:SetDesaturated( false );
			button.portrait.PortraitRing:SetDesaturated( false );

			button.index = index;
			button.portrait.unitData = unitData;
			button:Show();

			if ( unitEditor.selectedUnitID == index ) then
				button.selected = true;
				button.selectedTexture:Show();
				button.portrait.PortraitHighlight:Show();
			else
				button.selected = false;
				button.selectedTexture:Hide();
				button.portrait.PortraitHighlight:Hide();
			end
			button:SetEnabled(true);
			
			if unitData.health then
				local ratio = unitData.health / unitData.maxHealth;
				button.HealthBar:SetWidth(max(button.HealthBG:GetWidth() * ratio, 1));
				button.HealthBar:Show()
				button.HealthBG:Show()
			else
				button.HealthBar:Hide()
				button.HealthBG:Hide()
			end
			
			if unitData.armour and unitData.health then
				local ratio = min( ( unitData.armour + unitData.health ) / unitData.maxHealth, 1 );
				button.ArmourBar:SetWidth(max(button.HealthBG:GetWidth() * ratio, 1));
				button.ArmourBar:Show()
			else
				button.ArmourBar:Hide()
			end

			if ( unitData.raidMarker and unitData.raidMarker > 0 and unitData.raidMarker < 10 ) then
				button.raidMarker:SetTexture( "Interface/TargetingFrame/UI-RaidTargetingIcon_" .. unitData.raidMarker );
				button.raidMarker:Show();
			else
				button.raidMarker:Hide();
			end

			if ( unitData.isVisible ) then
				button.visibleButton.NormalTexture:SetAtlas("gm-icon-visible");
				button.visibleButton.isVisible = true;
			else
				button.visibleButton.NormalTexture:SetAtlas("gm-icon-visibledis");
				button.visibleButton.isVisible = false;
			end

			if ( button.showingTooltip ) then
				MountJournalMountButton_UpdateTooltip(button);
			end
		else
			button.name:SetText("");
			SetPortraitToTexture( button.portrait.Portrait, "Interface/Icons/INV_Misc_GroupLooking" );
			button.portrait.Portrait:SetDesaturated(true);
			button.portrait.PortraitRing:SetDesaturated(true);
			button.index = nil;
			button.portrait.unitData = nil;
			button.selected = false;
			button.selectedTexture:Hide();
			button:SetEnabled(false);
			button.HealthBar:Hide()
			button.HealthBG:Hide()
			button.ArmourBar:Hide()
			button.raidMarker:Hide();
		end
	end

	local totalHeight = unitEditor.numUnits * UNIT_BUTTON_HEIGHT;
	if totalHeight < 9 then
		totalHeight = 9;
	end
	HybridScrollFrame_Update(scrollFrame, totalHeight, scrollFrame:GetHeight());
	unitEditor.UnitCount.Count:SetText(unitEditor.numUnits);
	if ( not showUnits ) then
		unitEditor.selectedUnitID = nil;
		unitEditor.selectedUnitData = nil;
		unitEditor.UnitCount.Count:SetText(0);
	end
end

function Me.UnitManagerUnitEditor_CreateNewUnit()
	local newUnit = {
		modelID = 856;
		name = "New Unit";
		description = "Click here to type a description for this unit.";
		raidMarker = 0;
		isVisible = false;
		health = 10;
		maxHealth = 10;
		armour = 0;
		quantity = 1;
		statistics = {};
		traits = {};
	}
	
	tinsert( Profile.units, newUnit )
	print("New unit created.")
	PlaySound(72547)
	Me.UnitManagerUnitEditor_UpdateUnitList()
end

function Me.UnitManagerUnitEditor_DeleteUnit()
	local unitEditor = DiceMasterUnitManagerUnitEditor
	if not ( unitEditor.selectedUnitID ) then
		return
	end
	
	print( Profile.units[ unitEditor.selectedUnitID ].name .. " deleted." )
	tremove( Profile.units, unitEditor.selectedUnitID )
	PlaySound(51871)
	unitEditor.selectedUnitID = nil;
	unitEditor.selectedUnitData = nil;
	Me.UnitManagerUnitEditor_UpdateUnitList()
end

function Me.UnitManagerUnitEditor_DuplicateUnit()
	local unitEditor = DiceMasterUnitManagerUnitEditor
	if not ( unitEditor.selectedUnitID and unitEditor.selectedUnitData ) then
		return
	end
	
	local newUnit = unitEditor.selectedUnitData
	
	print( Profile.units[ unitEditor.selectedUnitID ].name .. " duplicated." )
	tinsert( Profile.units, unitEditor.selectedUnitID + 1, newUnit )
	PlaySound(51871)
	Me.UnitManagerUnitEditor_UpdateUnitList()
end

function Me.UnitManagerUnitEditor_UnitListVisibleButtonOnClick( self, button )
	local unitEditor = DiceMasterUnitManagerUnitEditor
	if not ( self:GetParent().index ) then
		return
	end

	if not( button=="LeftButton" ) then
		return
	end

	local index = self:GetParent().index;
	local isVisible = not( Profile.units[ index ].isVisible );
	self.isVisible = isVisible;
	
	self:GetScript("OnEnter")(self, button);

	Profile.units[ index ].isVisible = isVisible;
	Me.UnitManagerUnitEditor_UpdateUnitList();
end

-- Unit Editor Save Functions

function Me.UnitManagerUnitEditor_SaveName()
	local unitEditor = DiceMasterUnitManagerUnitEditor
	if not ( unitEditor.selectedUnitID and unitEditor.selectedUnitData ) then
		return
	end
	
	Profile.units[ unitEditor.selectedUnitID ].name = unitEditor.RightInset.name:GetText()
	Me.UnitManagerUnitEditor_UpdateUnitList()
end

function Me.UnitManagerUnitEditor_RaidMarkerButtonOnClick( self, button )
	local unitEditor = DiceMasterUnitManagerUnitEditor
	if not ( unitEditor.selectedUnitID and unitEditor.selectedUnitData ) then
		return
	end

	if button=="LeftButton" then
		delta = -1
	else
		delta = 1
	end

	local marker = unitEditor.selectedUnitData.raidMarker or 1;
	marker = marker + delta;
	if marker > 8 then
		marker = 1;
	elseif marker < 1 then
		marker = 8;
	end
	self:SetNormalTexture("Interface/TargetingFrame/UI-RaidTargetingIcon_"..marker);
	
	Profile.units[ unitEditor.selectedUnitID ].raidMarker = marker;
	Me.UnitManagerUnitEditor_UpdateUnitList();
end

function Me.UnitManagerUnitEditor_VisibilityButtonOnClick( self, button )
	local unitEditor = DiceMasterUnitManagerUnitEditor
	if not ( unitEditor.selectedUnitID and unitEditor.selectedUnitData ) then
		return
	end

	if not( button=="LeftButton" ) then
		return
	end

	local isVisible = not(unitEditor.selectedUnitData.isVisible);

	unitEditor.RightInset.visible:SetText( isVisible and "Visible" or "Hidden" );
	unitEditor.RightInset.visible:SetScript( "OnEnter", function( self)
		GameTooltip:SetOwner( self, "ANCHOR_RIGHT")
		GameTooltip:SetText( isVisible and "Visible" or "Hidden", 1, 1, 1)
		GameTooltip:AddLine("Players in your group "..(isVisible and "|cFF00FF00can|r" or "|cFFFF0000cannot|r").." see this unit on their map.", 1, 0.81, 0, 1);
		GameTooltip:AddLine( "<Left Click to Toggle>", 0.44, 0.44, 0.44, true);
		GameTooltip:Show()
	end);
	
	self:GetScript("OnEnter")(self, button);

	Profile.units[ unitEditor.selectedUnitID ].isVisible = isVisible;
	Me.UnitManagerUnitEditor_UpdateUnitList();
end

function Me.UnitManagerUnitEditor_HealthBarOnClick( self, button )
	local unitEditor = DiceMasterUnitManagerUnitEditor
	if not ( unitEditor.selectedUnitID and unitEditor.selectedUnitData ) then
		return
	end

	local health	= unitEditor.selectedUnitData.health;
	local maxHealth = unitEditor.selectedUnitData.maxHealth;
	local armour	= unitEditor.selectedUnitData.armour;
	
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
		StaticPopup_Show("DICEMASTER4_SETUNITHEALTHMAX", nil, nil, unitEditor.selectedUnitData)
	elseif IsControlKeyDown() and button == "LeftButton" then
		-- Open dialog for custom value.
		StaticPopup_Show("DICEMASTER4_SETUNITHEALTHVALUE", nil, nil, unitEditor.selectedUnitData)
	elseif IsAltKeyDown() then
		if Me.OutOfRange( armour+delta, 0, 1000 ) then
			return
		end
		armour = armour + delta;
	else
		if Me.OutOfRange( health+delta, 0, maxHealth ) then
			return
		end
		health = Me.Clamp( health + delta, 0, maxHealth )
	end

	local barFrame = self:GetParent();
	
    barFrame:SetValue( health );
    barFrame:SetMax( maxHealth );
    barFrame:SetArmour( armour );
	
	self:GetScript("OnEnter")(self, button);

	Profile.units[ unitEditor.selectedUnitID ].health = health;
	Profile.units[ unitEditor.selectedUnitID ].maxHealth = maxHealth;
	Profile.units[ unitEditor.selectedUnitID ].armour = armour;
	Me.UnitManagerUnitEditor_UpdateUnitList()
end

function Me.UnitManagerUnitEditor_UpdateDisplay()	
	local unitEditor = DiceMasterUnitManagerUnitEditor
	
	if not ( unitEditor.selectedUnitData ) then
		return
	end
	
	local rightInset = unitEditor.RightInset
	local scrollFrame = unitEditor.UnitInfoFrame.ScrollFrame.Child
	local unitData = unitEditor.selectedUnitData
	
	SetPortraitTextureFromCreatureDisplayID( rightInset.portrait.Portrait, unitData.modelID )
	rightInset.name:SetText( unitData.name )
	if ( unitData.raidMarker and unitData.raidMarker > 0 and unitData.raidMarker < 10 ) then
		rightInset.portrait.raidMarker:SetNormalTexture( "Interface/TargetingFrame/UI-RaidTargetingIcon_"..unitData.raidMarker )
		rightInset.portrait.raidMarker:Show()
	else
		rightInset.portrait.raidMarker:Hide()
	end
	
	if unitData.health then
		scrollFrame.HealthBar:SetMax( unitData.maxHealth )
		scrollFrame.HealthBar:SetValue( unitData.health )
		scrollFrame.HealthBar:SetArmour( unitData.armour )
		scrollFrame.HealthBar:SetAlpha( 1 )
	end

	Me.UnitInfo_UpdateStatisticsFrame( unitData.statistics, scrollFrame.StatisticsFrame, true )
	Me.UnitInfo_UpdateTraitsFrame( unitData.traits, scrollFrame.TraitsFrame, true )
	Me.UnitInfo_UpdateDescriptionFrame( unitData.description, scrollFrame.DescriptionFrame, true )
end

function Me.UnitManagerUnitEditor_SetSelected(unitID)
	DiceMasterUnitManagerUnitEditor.selectedUnitID = unitID;
	DiceMasterUnitManagerUnitEditor.selectedUnitData = Profile.units[ unitID ];
	Me.UnitManagerOptionsMenu_HideDropdown();
	Me.UnitManagerUnitEditor_UpdateUnitList();
	Me.UnitManagerUnitEditor_UpdateDisplay();
end

function Me.UnitManagerUnitEditor_OnDragStartListButton(frame)
	if ( not frame.unitData ) then
		return;
	end
	DiceMasterUnitManagerCursorIcon.unitData = frame.unitData;
	DiceMasterUnitManagerCursorIcon:Show();
	SetPortraitTextureFromCreatureDisplayID( DiceMasterUnitManagerCursorIcon.Portrait, frame.unitData.modelID )
	PlaySound(832)
end

function Me.UnitManagerUnitEditor_OnDragStopListButton(frame)
	if ( not frame.unitData ) then
		return;
	end
	if ( WorldMapFrame:IsShown() and MouseIsOver(WorldMapFrame.ScrollContainer) ) then
		-- Place icon on the map.
		local coordX, coordY, mapID = Me.CalculateMapCoordsFromCursorPosition()
		if ( coordX and coordY and mapID ) then
			Me.AddWorldMapIconMap( 1, frame.unitData, coordX, coordY, mapID )
		end
	end
	DiceMasterUnitManagerCursorIcon.Portrait:SetTexture(nil)
	DiceMasterUnitManagerCursorIcon.unitData = nil
	DiceMasterUnitManagerCursorIcon:Hide()
	PlaySound(833)
end

function Me.UnitManagerOptionsMenu_Init(self, level)

	local info = UIDropDownMenu_CreateInfo();
	info.notCheckable = true;
	if DiceMasterUnitManager.dropDownFrame then
		info.isTitle = true;
		info.text = DiceMasterUnitManager.dropDownFrame.unitData.name;
		UIDropDownMenu_AddButton(info, level);
	end
	info.isClickable = true;
	info.disabled = nil;
	info.isTitle = false;
	info.text = "Drop at My Location";
	info.func = function()
		-- TODO
		if DiceMasterUnitManager.dropDownFrame then
			Me.AddWorldMapIconMap( 1, DiceMasterUnitManager.dropDownFrame.unitData )
			PlaySound(833)
		end
	end;
	UIDropDownMenu_AddButton(info, level);
	
	info.text = "Duplicate";
	info.func = function()
		-- TODO
	end;
	UIDropDownMenu_AddButton(info, level);
	
	info.text = "Delete";
	info.func = function()
		-- TODO
	end;
	UIDropDownMenu_AddButton(info, level);
	info.text = "Cancel";
	info.func = nil;
	UIDropDownMenu_AddButton(info, level);
end

function Me.UnitManagerOptionsMenu_HideDropdown()
	if (UIDropDownMenu_GetCurrentDropDown() == DiceMasterUnitManager.unitOptionsMenu) then
		DiceMasterUnitManager.dropDownFrame = nil;
		HideDropDownMenu(1);
	end
end

function Me.UnitManagerFieldEditor_Reset()
	local editor = DiceMasterUnitManagerFieldEditor;

	editor.LoadDropdown:SetDefaultText("Load...");

	editor.Icon:SetTexture( "Interface/Icons/inv_misc_questionmark" );
	editor.HeaderTitle:SetText("");
	editor.Title:SetText("");
	editor.Description.EditBox:SetText("");
	editor.Value:SetText("");

end

function Me.UnitManagerFieldEditor_Save()
	local unitEditor = DiceMasterUnitManagerUnitEditor;
	local editor = DiceMasterUnitManagerFieldEditor;

	if not( unitEditor.selectedUnitData and unitEditor.selectedUnitID and editor.statisticID ) then
		return
	end

	local statistic = {
		icon	=	editor.Icon.icon:GetTexture();
		name	=	editor.Title:GetText();
		tooltip =	editor.Description.EditBox:GetText();
		value	=	editor.Value:GetText();
	};

	Profile.units[ unitEditor.selectedUnitID ].statistics[ editor.statisticID ] = statistic;
	
	Me.UnitManagerUnitEditor_UpdateUnitList();
	Me.UnitManagerUnitEditor_UpdateDisplay();
end

function Me.UnitManagerFieldEditor_Edit( fieldType, index )
	local unitEditor = DiceMasterUnitManagerUnitEditor;
	local editor = DiceMasterUnitManagerFieldEditor;

	if not( fieldType and index and unitEditor.selectedUnitData ) then
		return
	end

	local unitData = unitEditor.selectedUnitData;

	if ( fieldType == "statistic" ) then
		local collectFunc = function()
			local editor = DiceMasterUnitManagerFieldEditor;
			local data = {
				icon = editor.Icon.icon:GetTexture();
				name = editor.Title:GetText();
				tooltip = editor.Description.EditBox:GetText();
				value = editor.Value:GetText();
			};
			return data;
		end;
		editor.LoadDropdown:SetCollection(nil, "Statistics", collectFunc);

		local statistic = unitData.statistics[index];
		editor.Icon:SetTexture( statistic.icon or "Interface/Icons/inv_misc_questionmark" );
		editor.HeaderTitle:SetText( "Edit Statistic" );
		editor.Title:SetText( statistic.name );
		editor.Description.EditBox:SetText( statistic.tooltip );
		editor.Value:SetText( statistic.value );
		editor.statisticID = index;
	end
	editor:Show();
end

function Me.UnitManagerFieldEditor_OnCloseClicked()
	local editor = DiceMasterUnitManagerFieldEditor;
	editor:Hide();
end

function Me.UnitManagerFieldEditor_Open()
	local editor = DiceMasterUnitManagerFieldEditor;
	Me.UnitManagerFieldEditor_Reset();
	editor.Inset:SetPoint("TOPLEFT", editor, "TOPLEFT", 3, -76);
	editor:Show();
end