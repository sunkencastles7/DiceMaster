-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4
local Profile = Me.Profile

local versionCheck = true;

local DEFAULT_ICON = "Interface/Icons/inv_misc_questionmark"

--
-- Requesting and reading trait data for other players.
-- Also can be used seamlessly for the player's own traits.
--

-------------------------------------------------------------------------------
Me.inspectData = {}
Me.inspectName = nil

Me.inspectQueue   = {}    -- Map of players that we want to inspect
Me.inspectStarted = false -- We are going to inspect players soon

-------------------------------------------------------------------------------
-- A special case for the player, where we just mirror their saved data.
--
local self_inspect = {
	hasDM4 = true;
}
setmetatable( self_inspect, {
	__index = function( table, key )
		if key == "statusSerial" then
			return Me.db.char.statusSerial
		else
			return Profile[key]
		end
	end;
})

Me.inspectData[UnitName("player")] = self_inspect

-------------------------------------------------------------------------------
-- Placeholder trait for data transfers.
--
local WAITING_FOR_TRAIT = {
	icon    = DEFAULT_ICON;
	name    = "";
	serial  = 0; 
	desc    = "Waiting for data from player.";
	approved = 0;
	secret1Active = false;
	secret1Enabled = false;
	secret2Active = false;
	secret2Enabled = false;
	secret3Active = false;
	secret3Enabled = false;
	officers = {};
}

-------------------------------------------------------------------------------
local function PrimeInspectData( name )
	
	Me.inspectData[name] = {
		traits = {};
		buffsActive = {};
		skills = {};
		alignment = "(None)";
		statusSerial  = 0;
		charges = {
			enable    = false;
			name      = "Resource";
			color     = {1, 1, 1};
			count     = 0;
			max       = 0;
			tooltip   = "Represents this character's custom resource.";
			symbol    = "charge-orb";
			flash     = true;
		};
		health        = 10;
		healthMax     = 10;
		mana 		  = 0;
		manaMax		  = 20;
		manaType	  = "None";
		armor         = 0;
		level         = 1;
		experience    = 0;
		pet	= {
			enable  = false;
			name 	= "Pet Name";
			type    = "Pet";
			icon 	= "Interface/Icons/inv_misc_questionmark";
			model 	= 31;
			health       = 5;
			healthMax    = 5;
			armor        = 0;
		};
		inventory	  = {};
		shop		  = {};
		shopIcon = "Interface/Icons/garrison_building_tradingpost";
		shopName = false;
		shopModel = false;
		hideShop = false;
		currency 	  = {};
		currencyActive = 1;
		mapNodes 	  = {};
		hasDM4        = false;
	}
	
	for i = 1, Me.traitCount do
		Me.inspectData[name].traits[i] = WAITING_FOR_TRAIT;
	end
end

-------------------------------------------------------------------------------
-- This little metatable adds some magic so that if you reference a name
-- without data yet, it primes it first with default values.
--
setmetatable( Me.inspectData, {
	__index = function( table, key )
		
		if key == nil then return end
		
		PrimeInspectData( key )
		return table[key]
	end;
})

-------------------------------------------------------------------------------
-- Popup Dialogs for setting Inspect target health and mana.
--

StaticPopupDialogs["DICEMASTER4_SETTARGETHEALTHVALUE"] = {
  text = "Set Health value:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText(Me.inspectData[Me.inspectName].health)
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText()) or Me.inspectData[Me.inspectName].health
	if Me.OutOfRange( text, 0, Me.inspectData[Me.inspectName].healthMax ) then
		return
	end
	-- Send update to target.
	local msg = Me:Serialize( "SETHP", {
		h = text;
		hm = Me.inspectData[Me.inspectName].healthMax;
		ar = Me.inspectData[Me.inspectName].armor;
	})
		
	Me:SendCommMessage( "DCM4", msg, "WHISPER", Me.inspectName, "ALERT" )
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_SETTARGETHEALTHMAX"] = {
  text = "Set maximum Health value:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText(Me.inspectData[Me.inspectName].healthMax)
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText()) or Me.inspectData[Me.inspectName].healthMax
	local health = Me.inspectData[Me.inspectName].health
	if Me.OutOfRange( text, 1, 1000 ) then
		return
	end
	if health > text then 
		health = text
	end
	-- Send update to target.
	local msg = Me:Serialize( "SETHP", {
		h = health;
		hm = text;
		ar = Me.inspectData[Me.inspectName].armor;
	})
		
	Me:SendCommMessage( "DCM4", msg, "WHISPER", Me.inspectName, "ALERT" )
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_SETTARGETMANAVALUE"] = {
  text = "Set Health value:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText(Me.inspectData[Me.inspectName].mana)
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText()) or Me.inspectData[Me.inspectName].mana
	if Me.OutOfRange( text, 0, Me.inspectData[Me.inspectName].manaMax ) then
		return
	end
	-- Send update to target.
	local msg = Me:Serialize( "SETMANA", {
		m = text;
		mm = Me.inspectData[Me.inspectName].manaMax;
	})
		
	Me:SendCommMessage( "DCM4", msg, "WHISPER", Me.inspectName, "ALERT" )
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_SETTARGETMANAMAX"] = {
  text = "Set maximum Mana value:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText(Me.inspectData[Me.inspectName].manaMax)
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText()) or Me.inspectData[Me.inspectName].manaMax
	local mana = Me.inspectData[Me.inspectName].mana
	if Me.OutOfRange( text, 1, 1000 ) then
		return
	end
	if mana > text then 
		mana = text
	end
	-- Send update to target.
	local msg = Me:Serialize( "SETMANA", {
		m = mana;
		mm = text;
	})
		
	Me:SendCommMessage( "DCM4", msg, "WHISPER", Me.inspectName, "ALERT" )
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-------------------------------------------------------------------------------
-- Update the buff frame.
--

function Me.Inspect_UpdateBuffButton(buttonName, playerName, index)
	local data = Me.inspectData[playerName].buffsActive[index] or nil
	local name, icon, description, count, duration, turns, expirationTime, sender
	if data then 
		name = data.name
		icon = data.icon
		description = data.description
		count = data.count or 1
		duration = data.duration
		turns = data.turns
		expirationTime = data.expirationTime
		sender = data.sender
	end
	
	local buffName = buttonName..index;
	local buff = _G[buffName];
	
	if ( not name ) then
		-- No buff so hide it if it exists
		if ( buff ) then
			buff:Hide();
			buff.duration:Hide();
		end
		return nil;
	else
		-- Setup Buff
		buff.owner = playerName;
		buff:SetID(index);
		buff:SetAlpha(1.0);
		--buff:SetScript("OnUpdate", Me.Inspect_BuffButton_OnUpdate);
		--Me.SetupTooltip( buff, nil, "|cFFffd100"..name, nil, nil, Me.FormatDescTooltip( description ), "|cFF707070Given by "..sender )
		buff:Show();

		if ( duration > 0 and expirationTime ) then
			buff.turns:Hide();
			if ( SHOW_BUFF_DURATIONS == "1" ) then
				buff.duration:Show();
			else
				buff.duration:Hide();
			end
			
			local timeLeft = (expirationTime - GetTime());

			if ( not buff.timeLeft ) then
				buff.timeLeft = timeLeft;
				buff:SetScript("OnUpdate", Me.Inspect_BuffButton_OnUpdate);
			else
				buff.timeLeft = timeLeft;
			end

			buff.expirationTime = expirationTime;		
		else
			buff.turns:Hide()
			buff.duration:Hide();
			if ( buff.timeLeft ) then
				buff:SetScript("OnUpdate", nil);
			end
			buff.timeLeft = nil;
		end
		
		if ( turns > 0 ) then
			if ( SHOW_BUFF_DURATIONS == "1" ) then
				buff.turns:Show();
				buff.turns:SetText( turns .. " trn" )
			else
				buff.turns:Hide();
				buff.turns:SetText( "" )
			end
		end

		-- Set Icon
		local texture = _G[buffName.."Icon"];
		texture:SetTexture(icon);

		-- Set the number of applications of an aura
		if ( count > 1 ) then
			buff.count:SetText(count);
			buff.count:Show();
		else
			buff.count:Hide();
		end

		-- Refresh tooltip
		if timeLeft then
			Me.SetupTooltip( buff, nil, "|cFFffd100"..name, nil, nil, Me.FormatDescTooltip( description ), nil,  Me.BuffButton_FormatTime(timeLeft).." remaining|n|cFF707070Given by "..sender )
		elseif turns > 0 then
			if turns > 1 then
				Me.SetupTooltip( buff, nil, "|cFFffd100"..name, nil, nil, Me.FormatDescTooltip( description ), nil,  turns .. " turns remaining|n|cFF707070Given by "..sender )
			else
				Me.SetupTooltip( buff, nil, "|cFFffd100"..name, nil, nil, Me.FormatDescTooltip( description ), nil,  turns .. " turn remaining|n|cFF707070Given by "..sender )
			end
		else
			Me.SetupTooltip( buff, nil, "|cFFffd100"..name, nil, nil, Me.FormatDescTooltip( description ), nil, "|cFF707070Given by "..sender )
		end
	end
	return 1;
end

function Me.Inspect_BuffButton_OnUpdate(self)
	local data = Me.inspectData[self.owner].buffsActive[self:GetID()] or nil
	local index = self:GetID();
	if ( self.timeLeft < BUFF_WARNING_TIME ) then
		self:SetAlpha(1.0);
	else
		self:SetAlpha(1.0);
	end

	-- Update duration
	Me.Inspect_BuffButton_UpdateDuration( self, self.timeLeft )
	
	-- Update our timeLeft
	local timeLeft = self.expirationTime - GetTime();
	self.timeLeft = max( timeLeft, 0 );
	
	if timeLeft == 0 then
		tremove(Me.inspectData[self.owner].buffsActive, self:GetID())
		for i = 1, 5 do
			Me.Inspect_UpdateBuffButton("DiceMasterInspectBuffButton", self.owner, i)
		end
	end
	
	if ( SMALLER_AURA_DURATION_FONT_MIN_THRESHOLD ) then
		local aboveMinThreshold = self.timeLeft > SMALLER_AURA_DURATION_FONT_MIN_THRESHOLD;
		local belowMaxThreshold = not SMALLER_AURA_DURATION_FONT_MAX_THRESHOLD or self.timeLeft < SMALLER_AURA_DURATION_FONT_MAX_THRESHOLD;
		if ( aboveMinThreshold and belowMaxThreshold ) then
			self.duration:SetFontObject(SMALLER_AURA_DURATION_FONT);
			self.duration:SetPoint("TOP", self, "BOTTOM", 0, SMALLER_AURA_DURATION_OFFSET_Y);
		else
			self.duration:SetFontObject(DEFAULT_AURA_DURATION_FONT);
			self.duration:SetPoint("TOP", self, "BOTTOM");
		end
	end

	if ( GameTooltip:IsOwned(self) ) and timeLeft > 0 then
		Me.SetupTooltip( self, nil, "|cFFffd100"..data.name, nil, nil, Me.FormatDescTooltip( data.description ), nil, Me.BuffButton_FormatTime(timeLeft).." remaining|n|cFF707070Given by "..data.sender )
		self:GetScript("OnEnter")( self )
	end
end


function Me.Inspect_BuffButton_UpdateDuration( button, timeLeft )
	local duration = button.duration;
	if ( SHOW_BUFF_DURATIONS == "1" and timeLeft ) then
		duration:SetFormattedText(SecondsToTimeAbbrev(timeLeft));
		if ( timeLeft < BUFF_DURATION_WARNING_TIME ) then
			duration:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		else
			duration:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		end
		duration:Show();
	else
		duration:Hide();
	end
end

-------------------------------------------------------------------------------
-- Refresh the inspect panel.
--
-- @param status Refresh the status bars.
-- @param trait  Refresh the trait displays, may be "all" to refresh all or
--               a trait index to refresh one.
--
function Me.Inspect_Refresh( status, trait )
	local store = Me.inspectData[Me.inspectName]
	if status then
		local ourChargesHack = Me.inspectName == UnitName("player") and not Profile.charges.enable
		
		if store.charges.max > 0 and not ourChargesHack then
			DiceMasterInspectFrame.charges:SetMax( store.charges.max )
			DiceMasterInspectFrame.charges:SetFilled( store.charges.count )
			
			local symbol = store.charges.symbol or "charge-orb"
			
			DiceMasterInspectFrame.charges:SetTexture( 
				"Interface/AddOns/DiceMaster/Texture/"..symbol, 
				store.charges.color[1], store.charges.color[2], store.charges.color[3] )
			
			local chargesPlural = store.charges.name:gsub( "/.*", "" )
				
			-- Check for an Interface path.
			if not symbol:find("charge") then
				DiceMasterInspectFrame.charges2:SetMinMaxPower( 0, store.charges.max )
				DiceMasterInspectFrame.charges2:ApplyTextures( store.charges.symbol, store.charges.name, store.charges.tooltip, store.charges.count, store.charges.color, store.charges.flash )
				DiceMasterInspectFrame.charges2.text:SetText( store.charges.count .. "/" .. store.charges.max )
				DiceMasterInspectFrame.charges:Hide()
				DiceMasterInspectFrame.charges2:Show()
				DiceMasterInspectFrame.charges2:UpdateFill()
				if Me.db.char.healthPos then
					DiceMasterInspectFrame.health:SetPoint( "CENTER", 0, -40 )
					DiceMasterInspectFrame.mana:SetPoint( "CENTER", 0, -60 )
				else
					DiceMasterInspectFrame.health:SetPoint( "CENTER", 0, 70 )
					DiceMasterInspectFrame.mana:SetPoint( "CENTER", 0, 50 )
				end
				-- Check charges position setting:
				if Profile.charges.pos then
					DiceMasterInspectFrame:SetHeight( 120 );
					DiceMasterInspectFrame.charges:SetPoint("BOTTOM", 0, -50)
					DiceMasterInspectFrame.charges2:SetPoint("BOTTOM", 0, -50)
				else
					DiceMasterInspectFrame:SetHeight( 120 );
					DiceMasterInspectFrame.charges:SetPoint("BOTTOM", 0, 170)
					DiceMasterInspectFrame.charges2:SetPoint("BOTTOM", 0, 80)
				end
			else
				DiceMasterInspectFrame.charges:Show()
				DiceMasterInspectFrame.charges2:Hide()
			end
				
			Me.SetupTooltip( DiceMasterInspectFrame.charges, nil, 
				chargesPlural, nil, nil, nil, nil, 
				store.charges.tooltip )
		else
			DiceMasterInspectFrame.charges:Hide()
			DiceMasterInspectFrame.charges2:Hide()
			if Me.db.char.healthPos then
				DiceMasterInspectFrame.health:SetPoint( "CENTER", 0, -40 )
				DiceMasterInspectFrame.mana:SetPoint( "CENTER", 0, -60 )
			else
				DiceMasterInspectFrame.health:SetPoint( "CENTER", 0, 38 )
				DiceMasterInspectFrame.mana:SetPoint( "CENTER", 0, 18 )
			end
		end
		Me.RefreshHealthbarFrame( DiceMasterInspectFrame.health, store.health, store.healthMax, store.armor )
		Me.RefreshManabarFrame( DiceMasterInspectFrame.mana, store.mana, store.manaMax )
		
		if store.manaType then
			local statusBarTexture = DiceMasterInspectFrame.mana:GetStatusBarTexture()
			if store.manaType == "None" then
				DiceMasterInspectFrame.mana:Hide();
			else
				local manaType = store.manaType;
				if manaType == "RunicPower" then manaType = "Runic Power" end
				statusBarTexture:SetAtlas( "UI-HUD-UnitFrame-Player-PortraitOff-Bar-" .. store.manaType );
				DiceMasterInspectFrame.mana:Show();
				if Me.IsLeader( true ) then
					DiceMaster4.SetupTooltip( DiceMasterInspectFrame.mana, nil, manaType, nil, nil, nil, nil, "Represents this character's " .. manaType .. ".|n|cFF707070<Left/Right Click to Add/Remove>|n<Shift+Left Click to Set Max>|n<Ctrl+Left Click to Set Value>|r" )
				else
					DiceMaster4.SetupTooltip( DiceMasterInspectFrame.mana, nil, manaType, nil, nil, nil, nil, "Represents this character's " .. manaType .. "." )
				end
			end
		end
		
		if Me.IsLeader( true ) then
			DiceMaster4.SetupTooltip( DiceMasterInspectFrame.health, nil, "Health", nil, nil, nil, nil, 
              "Represents this character's health.|n|cFF707070<Left/Right Click to Add/Remove>|n<Shift+Left Click to Set Max>|n<Ctrl+Left Click to Set Value>|n<Alt+Left/Right Click to Add/Remove Armour>" )
        else
			DiceMaster4.SetupTooltip( DiceMasterInspectFrame.health, nil, "Health", nil, nil, nil, nil, "Represents this character's health." )
		end
		
	end
	
	if trait == "all" then
		for i = 1, Me.traitCount do
			DiceMasterInspectFrame.traits[i]:SetPlayerTrait( Me.inspectName, i )
			DiceMasterInspectFrame.traits[i]:SetPoint( "CENTER", -56 + 28*(i-1), -14 )
		end
	elseif trait then
		DiceMasterInspectFrame.traits[trait]:SetPlayerTrait( Me.inspectName, trait )
	end 
	
	if store.buffsActive then
		for i = 1, 5 do
			Me.Inspect_UpdateBuffButton("DiceMasterInspectBuffButton", Me.inspectName, i)
		end
		DiceMasterInspectBuffFrame:Show()
	else
		DiceMasterInspectBuffFrame:Hide()
	end
	
	if store.pet.enable and not Me.db.global.hidePet then
		--DiceMasterInspectPetFrame.Texture:SetTexture( store.pet.icon )
		SetPortraitTextureFromCreatureDisplayID( DiceMasterInspectPetFrame.Texture, store.pet.model )
		Me.SetupTooltip( DiceMasterInspectPetFrame, store.pet.icon, store.pet.name, store.pet.type, store.pet.health.."/"..store.pet.healthMax.." |TInterface/AddOns/DiceMaster/Texture/health-heart:12|t" )
		DiceMasterInspectPetFrame:Show()
	else
		DiceMasterInspectPetFrame:Hide()
	end
	
	if not Me.db.char.hidepanel or not Me.db.global.hideInspect then
		if store.hasDM4 then
			DiceMasterInspectFrame:Show()
			if not Me.db.global.hideStats then
				DiceMasterStatInspectButton:Show()
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Show the inspect panel and update a player's data.
--
-- @param name Name of player that we want to inspect.
--             If nil, the inspect panel will be closed instead.
--
function Me.Inspect_Open( name )
	Me.inspectName = name
	DiceMasterInspectFrame:Hide()
	DiceMasterStatInspectButton:Hide()
	if Me.FramesUnlocked then 
		DiceMasterInspectFrame:Show()
		DiceMasterStatInspectButton:Show()
	end
	if name == nil then return end
	
	Me.StatInspector_Update()				   
	
	Me.Inspect_UpdatePlayer( name )
	Me.Inspect_Refresh( true, "all" ) 
end

-------------------------------------------------------------------------------
-- This is essentially meant to stop multiple requests per frame.
--
-- A simple queue to bundle up requests and discard duplicates, and then run
-- them a little later.
--
local function StartQueue()
	if Me.inspectStarted then return end
	Me.inspectStarted = true
	
	C_Timer.After( 0.025, function()
		Me.inspectStarted = false
		
		for name, _ in pairs( Me.inspectQueue ) do
			
			local store = Me.inspectData[name]
			
			-- build request
			-- see PROTOCOL.TXT
			local request_data = {
				ts = {};
				ss = store.statusSerial;
				bs = {};
			}
			
			for i = 1, Me.traitCount do
				request_data.ts[i] = store.traits[i].serial
			end
			
			local msg = Me:Serialize( "INSP", request_data )
			
			Me:SendCommMessage( "DCM4", msg, "WHISPER", name, "NORMAL" )
		end
		
		Me.inspectQueue = {}
	end)
end

-------------------------------------------------------------------------------
-- Update a player's data in the background.
--
-- @param name Name of player. Must be home-realm.
--
function Me.Inspect_UpdatePlayer( name )
	  
	if name ~= UnitName( "player" ) then
	
		Me.inspectQueue[ name ] = true
		StartQueue() 
	end
end

-------------------------------------------------------------------------------
-- Called when a player's trait is updated.
-- 
-- @param name  Name of player who was updated.
-- @param index Index of trait that was updated.
--
function Me.Inspect_OnTraitUpdated( name, index )
	if name == Me.inspectName then
		Me.Inspect_Refresh( nil, index )
	end
	
	-- If the user is viewing this trait, update their item ref tooltip.
	Me.UpdateTraitItemRef( name, index )
	
	-- If the user is mousing over this trait, via this inspect panel,
	-- then we update it IN FRONT OF THEIR VERY EYES.
	Me.UpdateTraitTooltip( name, index )
end

-------------------------------------------------------------------------------
-- When the healthbar frame is clicked.
--
function Me.Inspect_OnHealthClicked( button )

	if not IsInGroup( LE_PARTY_CATEGORY_HOME ) or not Me.inspectName then return end

	local delta = 0
	local health = Me.inspectData[Me.inspectName].health
	local armor =  Me.inspectData[Me.inspectName].armor
	if button == "LeftButton" then
		delta = 1
	elseif button == "RightButton" then
		delta = -1
	else
		return
	end
	  	
	if IsShiftKeyDown() and button == "LeftButton" then
		-- Open dialog for custom value.
		StaticPopup_Show("DICEMASTER4_SETTARGETHEALTHMAX")
		return
	elseif IsControlKeyDown() and button == "LeftButton" then
		-- Open dialog for custom value.
		StaticPopup_Show("DICEMASTER4_SETTARGETHEALTHVALUE")
		return
	elseif IsAltKeyDown() then
		if Me.OutOfRange( armor+delta, 0, 1000 ) then
			return
		end
		armor = armor + delta;
	else
		if Me.OutOfRange( Me.inspectData[Me.inspectName].health+delta, 0, Me.inspectData[Me.inspectName].healthMax ) then
			return
		end
		health = Me.Clamp( health + delta, 0, Me.inspectData[Me.inspectName].healthMax )
	end
	
	-- Send update to target.
	local msg = Me:Serialize( "SETHP", {
		h = health;
		hm = Me.inspectData[Me.inspectName].healthMax;
		ar = armor;
	})
		
	Me:SendCommMessage( "DCM4", msg, "WHISPER", Me.inspectName, "ALERT" )
end

-------------------------------------------------------------------------------
-- When the manabar frame is clicked.
--
function Me.Inspect_OnManaClicked( button )

	if not IsInGroup( LE_PARTY_CATEGORY_HOME ) or not Me.inspectName then return end

	local delta = 0
	local mana = Me.inspectData[Me.inspectName].mana
	if button == "LeftButton" then
		delta = 1
	elseif button == "RightButton" then
		delta = -1
	else
		return
	end
	  	
	if IsShiftKeyDown() and button == "LeftButton" then
		-- Open dialog for custom value.
		StaticPopup_Show("DICEMASTER4_SETTARGETMANAMAX")
		return
	elseif IsControlKeyDown() and button == "LeftButton" then
		-- Open dialog for custom value.
		StaticPopup_Show("DICEMASTER4_SETTARGETMANAVALUE")
		return
	else
		if Me.OutOfRange( Me.inspectData[Me.inspectName].mana+delta, 0, Me.inspectData[Me.inspectName].manaMax ) then
			return
		end
		mana = Me.Clamp( mana + delta, 0, Me.inspectData[Me.inspectName].manaMax )
	end
	
	-- Send update to target.
	local msg = Me:Serialize( "SETMANA", {
		m = mana;
		mm = Me.inspectData[Me.inspectName].manaMax;
	})
		
	Me:SendCommMessage( "DCM4", msg, "WHISPER", Me.inspectName, "ALERT" )
end

-------------------------------------------------------------------------------
-- When a trait button is clicked.
--
function Me.Inspect_OnTraitClicked( self, button )
	if not self.traitIndex then return end -- this handler is only for the target's traits
	
	if button == "LeftButton" and ACTIVE_CHAT_EDIT_BOX then
		if IsShiftKeyDown() then
			-- Create chat link.
			
			-- We convert ability names' spaces to U+00A0 No-Break Space
			-- so that chat addons that split up messages see the link as 
			-- a whole word and have a lesser chance to screw up
			--
			-- We could use something another symbol that would be more secure
			-- but then people without the addon would see that ugly symbol
			--
			local trait = DiceMaster4.inspectData[UnitName("target")].traits[self.traitIndex]
			
			-- find the name of the channel we mean to link to.
			local dist = tostring(ACTIVE_CHAT_EDIT_BOX:GetAttribute("chatType"))
			local channel = nil
			if dist == "WHISPER" then
				channel = ACTIVE_CHAT_EDIT_BOX:GetAttribute("tellTarget")
			end
			
			if UnitName("target") == UnitName("player") then
				Me.Inspect_SendTrait( self.traitIndex, dist, channel )
			else
				local msg = Me:Serialize( "TRAIT", {
					i = self.traitIndex;
					s = trait.serial;
					n = trait.name;
					u = trait.usage;
					r = trait.range;
					c = trait.castTime;
					cd = trait.cooldown;
					d = trait.desc;
					a = trait.approved;
					o = trait.officers;
					s1 = trait.secret1Enabled or false;
					s2 = trait.secret2Enabled or false;
					s3 = trait.secret3Enabled or false;
					t = trait.icon;
					l = UnitName("target");
				})
			
				Me:SendCommMessage( "DCM4", msg, dist, channel, "ALERT" )
			end
			
			local name = trait.name:gsub( " ", " " )
			--                                                       |    |
			--                                                space -'    |
			--                                            no-break-space -'
			
			ChatEdit_InsertLink(
				string.format( "[DiceMaster4:%s:%d:%s]", UnitName("target"), self.traitIndex, name ) ) 
		end
	elseif button == "RightButton" and Me.IsOfficer() then
		local trait = DiceMaster4.inspectData[UnitName("target")].traits[self.traitIndex]
		
		local msg = Me:Serialize( "APPROVE", {
			i = self.traitIndex;
		})
			
		Me:SendCommMessage( "DCM4", msg, "WHISPER", UnitName("target"), "ALERT" )
		
		C_Timer.After( 1.0, function() Me.Inspect_Open( UnitName( "target" )) end)
	end
end

-------------------------------------------------------------------------------
-- Called when a player's Status is updated.
--
-- @param name Name of player that was updated.
--
function Me.Inspect_OnStatusUpdated( name )
	if name == Me.inspectName then
		Me.Inspect_Refresh( true )
	end
end

-------------------------------------------------------------------------------
-- Simple tonumber wrapper for 0 as failure.
--
local function ToNumber2( expr )
	return tonumber( expr ) or 0
end

-------------------------------------------------------------------------------
-- Convert 6-digit hex color to {r,g,b} decimal values.
--
local function FromHex( hex ) 
	return {
		ToNumber2("0x"..hex:sub(1,2))/255, 
		ToNumber2("0x"..hex:sub(3,4))/255, 
		ToNumber2("0x"..hex:sub(5,6))/255
	}
end

-------------------------------------------------------------------------------
-- Convert {r,g,b} decimal values to 6-digit hex code.
--
local function ToHex( col )
	return string.format( "%2x%2x%2x", 
		Me.Clamp( math.floor(col[1] * 255+0.5), 0, 255 ), 
		Me.Clamp( math.floor(col[2] * 255+0.5), 0, 255 ), 
		Me.Clamp( math.floor(col[3] * 255+0.5), 0, 255 ))
end

-------------------------------------------------------------------------------
-- Send data for one of your traits.
--
-- @param index   Index of Me.traits
-- @param dist    Addon message distribution.
-- @param channel Whisper target or channel name.
--
function Me.Inspect_SendTrait( index, dist, channel )
	local trait = Profile.traits[index]
	
	local msg = Me:Serialize( "TRAIT", {
		i = index;
		s = Me.db.char.traitSerials[index];
		n = trait.name;
		u = trait.usage;
		r = trait.range;
		c = trait.castTime;
		cd = trait.cooldown;
		d = trait.desc;
		a = trait.approved;
		o = trait.officers;
		s1 = trait.secret1Enabled or false;
		s2 = trait.secret2Enabled or false;
		s3 = trait.secret3Enabled or false;
		t = trait.icon;
	})
	
	if (channel and (not type(channel) == "number")) then channel = tostring(channel) end
    Me:SendCommMessage( "DCM4", msg, dist, channel, "NORMAL" )
end

function Me.Inspect_SendTraits( dist, channel )
	for i = 1, #Profile.traits do
		Me.Inspect_SendTrait( i, dist, channel )
	end
end

local function DoSendShop( dist, channel )

	if Me.Profile.hideShop then
		return
	end

	for i = 1, #Me.Profile.shop do
		if Me.Profile.shop[i] and Me.Profile.shop[i].guid then
			Me.Inspect_SendItemSlot( i, true, dist, channel )
		end
	end
end

-------------------------------------------------------------------------------
-- Send data for one of your inventory slots.
--
-- @param index   Index of Me.Profile.inventory
-- @param dist    Addon message distribution.
-- @param channel Whisper target or channel name.
--
function Me.Inspect_SendItemSlot( index, isShop, dist, channel )
	local item, itemType
	if isShop then
		item = Profile.shop[ index ]
		itemType = "shop"
	else
		item = Profile.inventory[ index ]
		itemType = "inv"
	end
	
	if not item then
		return
	end
	
	local msg = {
		i = index;
		it = itemType;
		n = tostring( item.name ) or "Item";
		t = tostring( item.icon ) or "Interface/Icons/inv_misc_questionmark";
		q = tonumber( item.quality ) or 1;
		b = item.itemBind or false;
		s = item.soulbound or false;
		w1 = item.whiteText1 or "";
		w2 = item.whiteText2 or "";
		u = item.useText or "";
		f = item.flavorText or "";
		rc = item.requiredClass or {};
		rr = item.requiredRank or {};
		rl = item.requiredLevel or false;
		ss = tonumber( item.stackSize ) or 1;
		sc = tonumber( item.stackCount ) or 1;
		c = tonumber( item.cooldown ) or 1;
		l = tonumber( item.lastCastTime ) or 0;
		cn = item.consumeable or false;
		co = item.copyable or false;
		a = tostring( item.author );
		g = item.guid or 0;
		e = item.effects or {};
	}
	
	if isShop then
		msg.na = item.numAvailable;
		msg.cu = {
			name = tostring( item.currency.name ) or Me.Profile.currency[1].name;
			icon = tostring( item.currency.icon ) or Me.Profile.currency[1].icon;
			guid = item.currency.guid or Me.Profile.currency[1].guid;
		}
		msg.p = tonumber( item.price ) or 0;
	end
	
	msg = Me:Serialize( "INV", msg )
	
	if (channel and (not type(channel) == "number")) then channel = tostring(channel) end
    Me:SendCommMessage( "DCM4", msg, dist, channel, "NORMAL" )
end

local sendStatusQueue   = {}
local sendStatusStarted = false

local function DoSendStatus()
	
	sendStatusStarted = false
	
	for k, v in pairs( sendStatusQueue ) do
	
		-- parse message parameters and send
		local dist, channel = k:match( "(.*)%.(.*)" )
		if channel == "" then channel = nil end
		 
		local msg = {
			s  = Me.db.char.statusSerial;
			h  = Profile.health;
			hm = Profile.healthMax;
			m  = Profile.mana;
			mm = Profile.manaMax;
			mt = Profile.manaType;
			ar = Profile.armor;
			c  = Profile.charges.count;
			cm = Profile.charges.max;
			cn = Profile.charges.name;
			cs = Profile.charges.symbol;
			fl = Profile.charges.flash;
			cc = ToHex(Profile.charges.color);
			ct = Profile.charges.tooltip;
			al = Profile.alignment;
			le = Profile.level;
			ex = Profile.experience;
			pe = Profile.pet.enable;
			pn = Profile.pet.name;
			pt = Profile.pet.type;
			pi = Profile.pet.icon;
			pm = Profile.pet.model;
			ph = Profile.pet.health;
			phm = Profile.pet.healthMax;
			pa = Profile.pet.armor;
			vs = Me.version;
		}
		if not Profile.charges.enable then
			msg.c  = 0
			msg.cm = 0
		end
		
		if #Profile.buffsActive > 0 then
			msg.buffs = Profile.buffsActive
		else
			msg.buffs = {}
		end
		
		msg.shopHide = Profile.hideShop or false
		msg.shopName = Profile.shopName or false
		msg.shopModel = Profile.shopModel or false
		
		msg.cur = Profile.currency
		msg.cura = Profile.currencyActive
		
		if #Profile.shop > 0 then
			DoSendShop( dist, channel )
		end
		
		if Profile.shopIcon then
			msg.shopIcon = Profile.shopIcon
		else
			msg.shopIcon = "Interface/Icons/garrison_building_tradingpost"
		end
		
		local msg = Me:Serialize( "STATUS", msg )
		
		Me:SendCommMessage( "DCM4", msg, dist, channel, "NORMAL" )
	end
	
	sendStatusQueue = {}
end

-------------------------------------------------------------------------------
-- Send data of your status.
--
-- @param dist    Addon message distribution.
-- @param channel Whisper target or channel name.
--
function Me.Inspect_SendStatus( dist, channel )

	-- we want to buffer up these calls too
	-- for example, if you're in the config panel and scrolling the color
	-- wheel for charges, you're going to generate a lot of sendstatus messages
	-- we'll wait a second and ignore any duplicate requests during that timeframe
	--
	sendStatusQueue[ dist .. "." .. (channel or "") ] = true
	if not sendStatusStarted then
		sendStatusStarted = true
		C_Timer.After( 1.0, DoSendStatus )
	end

end

local function GetSkillValue( skill )
	
	local value = 0
	
	for i = 1,#Profile.buffsActive do
		if Profile.buffsActive[i].skill and Profile.buffsActive[i].skill == skill then
			value = value + ( Profile.buffsActive[i].skillRank * Profile.buffsActive[i].count );
		end
	end
	
	return value;
end

-------------------------------------------------------------------------------
-- Send data for your skills.
--
-- @param dist    Addon message distribution.
-- @param channel Whisper target or channel name.
--
function Me.Inspect_SendSkills( dist, channel )

	local skills = {}

	if Profile.skills and #Profile.skills > 0 then		
		
		for i = 1, #Profile.skills do
			local buffValue = GetSkillValue( Profile.skills[i].name )
			local value
			
			if Profile.skills[i].rank then
				-- calculate the total value before sending
				-- for safety reasons :) 
				value = Profile.skills[i].rank + buffValue
			end
			
			local data = {
				name = Profile.skills[i].name;
				icon = Profile.skills[i].icon or "Interface/Icons/inv_misc_questionmark";
				desc = Profile.skills[i].desc or nil;
				type = Profile.skills[i].type;
				rank = value or Profile.skills[i].rank;
				maxRank = Profile.skills[i].maxRank;
				guid = Profile.skills[i].guid;
				attribute = Profile.skills[i].attribute or nil;
				skillModifiers = Profile.skills[i].skillModifiers or {};
				author = Profile.skills[i].author;
				expanded = true;
			}
			
			tinsert( skills, data )
		end
		
	end
	
	local msg = Me:Serialize( "SKILLS", {
		skills = skills;
	})
	
	if (channel and (not type(channel) == "number")) then channel = tostring(channel) end
    Me:SendCommMessage( "DCM4", msg, dist, channel, "NORMAL" )
end

-------------------------------------------------------------------------------
-- Send a STATUS message to the party.
--
function Me.Inspect_ShareStatusWithParty()
	if not IsInGroup( LE_PARTY_CATEGORY_HOME ) or IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		return
	end
	
	if IsInRaid() then
		Me.Inspect_SendStatus( "RAID" )
	else
		Me.Inspect_SendStatus( "PARTY" )
	end
	Me.Inspect_OnStatusUpdated( UnitName( "player" ) )
end

---------------------------------------------------------------------------
-- Received an INSPECT request.
--
function Me.Inspect_OnInspectMessage( data, dist, sender )
	
	if data.ts then
		-- they're requesting traits, see which ones.
		for i = 1, Me.traitCount do
			if data.ts[i] and Me.db.char.traitSerials[i] ~= data.ts[i] then
				-- their serial doesn't match, so we send them this trait
				Me.Inspect_SendTrait( i, "WHISPER", sender )
			end
		end
	end
	
	if data.ss and data.ss ~= Me.db.char.statusSerial then
		-- their status serial mismatches, so we send them our status
		Me.Inspect_SendStatus( "WHISPER", sender )
	end
	
	if data.bs then
		-- they're requesting base skills.
		if not Profile.skills then
			return
		end
		Me.Inspect_SendSkills( "WHISPER", sender )
	end
end

---------------------------------------------------------------------------
-- Received APPROVE data.
--
function Me.Inspect_OnTraitApprove( data, dist, sender )
	
	-- you can't approve your own traits...
	if sender == UnitName( "player" ) then return end
	
	-- sanitize message
	if not data.i or not Me.PermittedUse() then
		-- we require index in message
		return
	end
	
	local trait = Profile.traits[data.i]
	
	if not trait.icon or not trait.name then
		-- another pass after sanitization
		return
	end
	
	if trait.officers and #trait.officers > 0 then
		for i=1,#trait.officers do
			if trait.officers[i] == sender then
				trait.approved = trait.approved - 1
				tremove(trait.officers, i)
				Me.PrintMessage(sender.." has revoked their approval of |T"..trait.icon..":16|t |cff71d5ff|HDiceMaster4:"..UnitName("player")..":"..data.i.."|h["..trait.name.."]|h|r.")
				Me.Inspect_SendTrait( data.i, "WHISPER", sender )
				return
			end
		end
	end
	
	if not trait.approved or trait.approved == 0 then 
		trait.approved = 1
		trait.officers = {}
		trait.officers[1] = sender
		Me.PrintMessage(sender.." has approved |T"..trait.icon..":16|t |cff71d5ff|HDiceMaster4:"..UnitName("player")..":"..data.i.."|h["..trait.name.."]|h|r! You need the approval of one more officer to use this trait during guild events.")
	elseif trait.approved == 1 then
		trait.approved = 2
		tinsert( trait.officers, sender )
		Me.PrintMessage(sender.." has approved |T"..trait.icon..":16|t |cff71d5ff|HDiceMaster4:"..UnitName("player")..":"..data.i.."|h["..trait.name.."]|h|r! You may now use this trait during guild events.")
	end
	Me.Inspect_SendTrait( data.i, "WHISPER", sender )
end
	
---------------------------------------------------------------------------
-- Received TRAIT data.
--
function Me.Inspect_OnTraitMessage( data, dist, sender )
	
	-- Ignore our own data.
	if sender == UnitName( "player" ) then return end
	
	-- sanitize message
	if not data.i or not data.s then
		-- we require index and serial in message
		return
	end
	
	data.i = tonumber( data.i )
	data.s = tonumber( data.s )
	data.u = tostring( data.u or "UNKNOWN" ) 
	data.r = tostring( data.r or "UNKNOWN" )
	data.c = tostring( data.c or "UNKNOWN" ) 
	data.cd = tostring( data.cd or "UNKNOWN" ) 
	data.n = tostring( data.n or "<Unknown name.>" )
	data.d = tostring( data.d or "" )
	data.a = tonumber( data.a or 0 )
	data.o = data.o or nil
	data.s1 = data.s1 or nil
	data.s2 = data.s2 or nil
	data.s3 = data.s3 or nil
	data.t = tostring( data.t or DEFAULT_ICON )
	
	-- we're receiving someone else's traits, not the sender
	if data.l then sender = tostring( data.l ) end
	
	if not data.i or not data.s or data.i < 1 or data.i > Me.traitCount then 
		-- another pass after number sanitization
		return 
	end
	
	-- store in database
	Me.inspectData[sender].traits[data.i] = {
		serial  = data.s;
		name    = data.n;
		usage   = data.u;
		range   = data.r;
		castTime = data.c;
		cooldown = data.cd;
		desc    = data.d;
		approved = data.a;
		officers = data.o;
		secret1Enabled = data.s1;
		secret2Enabled = data.s2;
		secret3Enabled = data.s3;
		icon    = data.t;
	}
	
	-- we flag them as having dicemaster once we receive their first message
	-- if they don't have this set, then the inspect panel isn't shown
	Me.inspectData[sender].hasDM4 = true
	
	Me.Inspect_OnTraitUpdated( sender, data.i )
end

---------------------------------------------------------------------------
-- Received item slot data.
--
function Me.Inspect_OnItemSlotMessage( data, dist, sender )
	
	-- Ignore our own data.
	if sender == UnitName( "player" ) then return end
	
	-- sanitize message
	if not data.i or not data.it or not data.g then
		-- we require index, itemType, and guid in message
		return
	end
	
	data.i = tonumber( data.i )
	data.it = tostring( data.it )
	data.n = tostring( data.n )
	data.t = tostring( data.t )
	data.q = tonumber( data.q )
	data.b = data.b or false
	data.s = data.s or false
	data.w1 = tostring( data.w1 )
	data.w2 = tostring( data.w2 )
	data.u = tostring( data.u )
	data.f = tostring( data.f )
	data.rc = data.rc or {}
	data.rr = data.rr or {}
	data.rl = data.rl or nil
	data.ss = tonumber( data.ss )
	data.sc = tonumber( data.sc )
	data.c = tonumber( data.c )
	data.l = tonumber( data.l )
	data.cn = data.cn or false
	data.co = data.co or false
	data.a = tostring( data.a )
	data.g = data.g
	data.e = data.e or {}
	
	if not data.i or not data.it or not data.g then 
		-- another pass after number sanitization
		return 
	end
	
	local item = {
		name = data.n;
		icon = data.t;
		quality = data.q;
		itemBind = data.b;
		soulbound = data.s;
		whiteText1 = data.w1;
		whiteText2 = data.w2;
		useText = data.u;
		flavorText = data.f;
		requiredClass = data.rc;
		requiredRank = data.rr;
		requiredLevel = data.rl;
		stackSize = data.ss;
		stackCount = data.sc;
		cooldown = data.c;
		lastCastTime = data.l;
		consumeable = data.cn;
		copyable = data.co;
		author = data.a;
		guid = data.g;
		effects = data.e;
	}
	
	-- store in database
	if data.it == "shop" then
		item.numAvailable = data.na;
		item.currency = data.cu;
		item.price = data.p;
		Me.inspectData[sender].shop[data.i] = item
	else
		Me.inspectData[sender].inventory[data.i] = item
	end
	
	Me.StatInspector_Update()
end

---------------------------------------------------------------------------
-- Received STATUS data.
--
function Me.Inspect_OnStatusMessage( data, dist, sender )

	-- Ignore our own data.
	if sender == UnitName( "player" )  then return end
 
	-- sanitize message
	if not data.s or not data.h or not data.hm or not data.c or not data.cm
	   or not data.cn or not data.cc then
	   
		return
	end
	
	data.s  = tonumber(data.s)
	data.h  = tonumber(data.h)
	data.hm = tonumber(data.hm)
	data.m  = tonumber(data.m)
	data.mm = tonumber(data.mm)
	data.ar = tonumber(data.ar)
	data.c  = tonumber(data.c)
	data.cm = tonumber(data.cm)
	data.cn = tostring(data.cn)
	if data.le then data.le = tonumber(data.le) end
	if data.ex then data.ex = tonumber(data.ex) end
	if data.ct then data.ct = tostring(data.ct) end
	if data.cs then data.cs = tostring(data.cs) end
	if #data.cc ~= 6 then data.cc = "FFFFFF" end
	if data.pe then
		data.pn = tostring(data.pn)
		data.pt = tostring(data.pt)
		data.pi = tostring(data.pi)
		data.pm = tonumber(data.pm)
		data.ph = tonumber(data.ph)
		data.phm = tonumber(data.phm)
		data.pa = tonumber(data.pa)
	end
	
	-- Version check
	if data.vs and versionCheck and data.vs > Me.version then
		versionCheck = false;
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t Your DiceMaster is out of date and may be incompatible with other users. Please update at your earliest convenience.", "SYSTEM")
	end
	
	if not data.s or not data.h or not data.hm or not data.c 
	   or not data.cm or not data.cn or data.cm < 0
	   or data.cm > 100
	   or data.h < 0 or data.h > data.hm or data.c < 0 
	   or data.c > data.cm then
	   
		-- cover all those bases . . .
		return 
	end
	
	if data.buffs then
		Me.inspectData[sender].buffsActive = data.buffs
	else
		Me.inspectData[sender].buffsActive = {}
	end

	local store = Me.inspectData[sender]
	store.statusSerial   = data.s
	store.charges.enable = data.cm > 0
	store.charges.count  = data.c
	store.charges.max    = data.cm
	store.charges.name   = data.cn
	store.charges.color  = FromHex( data.cc )
	if data.ct then store.charges.tooltip = data.ct end
	if data.cs then store.charges.symbol = data.cs end
	store.charges.flash = data.fl or false;
	store.health         = data.h
	store.healthMax      = data.hm
	store.mana         	 = data.m or 0
	store.manaMax      = data.mm or 10
	store.manaType      = data.mt or "None"
	store.armor          = data.ar
	if data.al then store.alignment = data.al end
	if data.le then store.level = data.le end
	if data.ex then store.experience = data.ex end
	if data.pe then
		store.pet.enable 		= data.pe
		store.pet.name	 		= data.pn
		store.pet.type			= data.pt
		store.pet.icon	 		= data.pi
		store.pet.model	 		= data.pm
		store.pet.health		= data.ph
		store.pet.healthMax    	= data.phm
		store.pet.armor        	= data.pa
	end
	if data.cur then
		store.currency = data.cur
		store.currencyActive = data.cura
	else
		store.currency = Me.Profile.currency[1]
		store.currencyActive = 1;
	end
	if data.shopIcon then
		store.shopIcon = data.shopIcon
		store.shopName = data.shopName or false
		store.shopModel = data.shopModel or false
	else
		store.shopIcon = "Interface/Icons/garrison_building_tradingpost"
		store.shopName = false
		store.shopModel = false
	end
	store.hideShop = data.shopHide or false
	store.hasDM4         = true
	
	Me.Inspect_OnStatusUpdated( sender )
	Me.StatInspector_UpdatePet()
	Me.DiceMasterRollDetailFrame_Update()
	Me.DMRosterFrame_Update()
end

---------------------------------------------------------------------------
-- Received SKILLS data.
--
function Me.Inspect_OnSkillsMessage( data, dist, sender )
	
	-- Ignore our own data.
	if sender == UnitName( "player" ) then return end
	
	-- sanitize message
	if not data.skills or not type(data.skills) == "table" then
		-- we require index in message
		return
	end
	
	-- store in database
	Me.inspectData[sender].skills = data.skills
	
	Me.StatInspector_Update()
end

---------------------------------------------------------------------------
-- Received EXP data.
--
function Me.Inspect_OnExperience( data, dist, sender )
	
	-- Only the party leader can grant experience.
	if sender == UnitName( "player" ) or not UnitIsGroupLeader( sender , 1) then return end
	
	-- sanitize message
	if not data.v and not data.l and not data.r then
		return
	end
	
	if data.v then data.v = tonumber( data.v ) end
	if data.l then data.l = tonumber( data.l ) end
	
	if data.v then
		Profile.experience = Profile.experience + data.v
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t Experience gained: " .. ( data.v ) .. ".", "RAID")
		
		if Profile.experience >= 100 then
			local levelsGained = math.floor( Profile.experience / 100 );
			local remainder = Profile.experience - ( levelsGained * 100 );
			Profile.experience = remainder;
			Profile.level = Profile.level + levelsGained;
			PlaySound(124)
			Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t Congratulations, you have reached level " .. ( Profile.level ) .. "!", "RAID")
		end
	elseif data.l then
		Profile.level = Profile.level + 1;
		PlaySound(124)
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t Congratulations, you have reached level " .. ( Profile.level ) .. "!", "RAID")
	elseif data.r then	
		Profile.level = 1;
		Profile.experience = 0;
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t Your level has been reset to 1.", "RAID")
	end
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty()
	Me.SkillFrame_UpdateSkills()
	Me.DiceMasterRollDetailFrame_Update()
	Me.DMRosterFrame_Update()
end

---------------------------------------------------------------------------
-- Received SETHP data.
--
local healthAnimationPlaying = false;
local healAmount = {};
local damageAmount = 0;
local armourGained = {};
local armourLost = 0;

function Me.Inspect_OnSetHPMessage( data, dist, sender )
	
	-- sanitize message
	if not data.h or not data.hm or not data.ar then
		return
	end

	data.h  = tonumber(data.h)
	data.hm = tonumber(data.hm)
	data.ar = tonumber(data.ar) or 0
	
	if not data.h or not data.hm or data.h < 0 or data.h > data.hm or data.h > 1000 or data.hm < 0 or data.hm > 1000 or not data.ar or data.ar > data.hm then
	   
		-- cover all those bases . . .
		return 
	end
	
	if data.h > Profile.health then
		if not healAmount[ sender ] then
			healAmount[ sender ] = data.h - Profile.health;
		else
			healAmount[ sender ] = healAmount[ sender ] + ( data.h - Profile.health )
		end
	elseif data.h < Profile.health then
		damageAmount = damageAmount + ( Profile.health - data.h )
	end
	
	if data.ar > Profile.armor then
		if not armourGained[ sender ] then
			armourGained[ sender ] = data.ar - Profile.armor;
		else
			armourGained[ sender ] = armourGained[ sender ] + ( data.ar - Profile.armor )
		end
	elseif data.ar < Profile.armor then
		armourLost = armourLost + ( Profile.armor - data.ar )
	end
	
	if not healthAnimationPlaying and Me.db.global.allowEffects then
		healthAnimationPlaying = true
		Me.ResetFullscreenEffect()
		local model = DiceMasterFullscreenEffectFrame.Model
		-- check if we're gaining or losing health
		if data.h > Profile.health then
			model:ApplySpellVisualKit( 29077, true )
			PlaySound( 32877 )
		elseif data.h < Profile.health then
			model:ApplySpellVisualKit( 29078, true )
			PlaySound( 32878 )
		elseif data.ar > Profile.armor then
			model:ApplySpellVisualKit( 30834, true )
			PlaySound( 32882 )
		elseif data.ar < Profile.armor then
			model:ApplySpellVisualKit( 29938, true )
			PlaySound( 32881 )
		end
	end
	
	C_Timer.After( 3, function() 
		if type(next(healAmount)) ~= "nil"  then
			for k, v in pairs( healAmount ) do
				Me.PrintMessage( k .. " has healed you for |cFFFFFFFF" .. v .. "|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t!", "RAID" )
			end
			Me.SecretEditor_OnEvent( "PLAYER_HEALED" )
		end
		if damageAmount > 0 then
			Me.PrintMessage( "You have lost |cFFFFFFFF" .. damageAmount .. "|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t!", "RAID" )
		end
		if type(next(armourGained)) ~= "nil"  then
			for k, v in pairs( armourGained ) do
				Me.PrintMessage( k .. " has granted you |cFFFFFFFF" .. v .. "|r|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t!", "RAID" )
			end
		end
		if armourLost > 0 then
			Me.PrintMessage( "You have lost |cFFFFFFFF" .. armourLost .. "|r|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t!", "RAID" )
		end
		healthAnimationPlaying = false
		healAmount = {};
		damageAmount = 0;
		armourGained = {};
		armourLost = 0;
	end )
	
	Profile.health = data.h
	Profile.healthMax = data.hm
	Profile.armor = data.ar
	
	Me.RefreshHealthbarFrame( DiceMasterChargesFrame.healthbar, Profile.health, Profile.healthMax, Profile.armor )
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty()
	Me.DiceMasterRollDetailFrame_Update()
	Me.DMRosterFrame_Update()
end

---------------------------------------------------------------------------
-- Received SETMANA data.

function Me.Inspect_OnSetManaMessage( data, dist, sender )
	
	-- Only the party leader can change players' mana.
	if not UnitIsGroupLeader( sender , 1) then return end
	
	-- sanitize message
	if not data.h or not data.hm or not data.ar then
		return
	end

	data.m  = tonumber(data.m)
	data.mm = tonumber(data.mm)
	
	if not data.m or not data.mm or data.m < 0 or data.m > data.mm or data.m > 1000 or data.mm < 0 or data.mm > 1000 then
	   
		-- cover all those bases . . .
		return 
	end
	
	Profile.mana = data.m
	Profile.manaMax = data.mm
	
	Me.RefreshManabarFrame( DiceMasterChargesFrame.mana, Profile.mana, Profile.manaMax )
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty()
	Me.DiceMasterRollDetailFrame_Update()
	Me.DMRosterFrame_Update()
end

-------------------------------------------------------------------------------
-- ADDON_LOADED handler
--
function Me.Inspect_Init()
	-- listen for messages
	
end


