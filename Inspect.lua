-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
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
	officers = {};
}

-------------------------------------------------------------------------------
local function PrimeInspectData( name )
	
	Me.inspectData[name] = {
		traits = {};
		buffsActive = {};
		stats = {};
		statusSerial  = 0;
		charges = {
			enable    = false;
			name      = "Charges";
			color     = {1, 1, 1};
			count     = 0;
			max       = 0;
			tooltip   = "Represents the amount of Charges you have accumulated for certain traits.";
			symbol    = "charge-orb";
			flash     = true;
		};
		health        = 5;
		healthMax     = 5;
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
		inventoryIcon = "Interface/Icons/inv_misc_bag_08";
		shop		  = {};
		shopIcon = "Interface/Icons/garrison_building_tradingpost";
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
		
		PrimeInspectData( key )
		return table[key]
	end;
})

-------------------------------------------------------------------------------
-- Popup Dialogs for setting Inspect target health.
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
		self:SetAlpha(BuffFrame.BuffAlphaValue);
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
				else
					DiceMasterInspectFrame.health:SetPoint( "CENTER", 0, 50 )
				end
			else
				DiceMasterInspectFrame.charges:Show()
				DiceMasterInspectFrame.charges2:Hide()
				if Me.db.char.healthPos then
					DiceMasterInspectFrame.health:SetPoint( "CENTER", 0, -40 )
				else
					DiceMasterInspectFrame.health:SetPoint( "CENTER", 0, 30 )
				end
			end
				
			Me.SetupTooltip( DiceMasterInspectFrame.charges, nil, 
				chargesPlural, nil, nil, nil, nil, 
				store.charges.tooltip )
		else
			DiceMasterInspectFrame.charges:Hide()
			DiceMasterInspectFrame.charges2:Hide()
			if Me.db.char.healthPos then
				DiceMasterInspectFrame.health:SetPoint( "CENTER", 0, -40 )
			else
				DiceMasterInspectFrame.health:SetPoint( "CENTER", 0, 18 )
			end
		end
		Me.RefreshHealthbarFrame( DiceMasterInspectFrame.health, store.health, store.healthMax, store.armor )
		
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
	Me.StatInspector_UpdatePet()
	Me.StatInspector_UpdateInventory()							   
	
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
			
			Me:SendCommMessage( "DCM4", msg, "WHISPER", name, "ALERT" )
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

	if not IsInGroup( LE_PARTY_CATEGORY_HOME ) or not Me.IsLeader( true ) or not Me.inspectName then return end

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
		t = trait.icon;
	})
	
	if (channel and (not type(channel) == "number")) then channel = tostring(channel) end
    Me:SendCommMessage( "DCM4", msg, dist, channel, "ALERT" )
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
			ar = Profile.armor;
			c  = Profile.charges.count;
			cm = Profile.charges.max;
			cn = Profile.charges.name;
			cs = Profile.charges.symbol;
			fl = Profile.charges.flash;
			cc = ToHex(Profile.charges.color);
			ct = Profile.charges.tooltip;
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
		
		if #Profile.inventory > 0 then
			msg.inv = Profile.inventory
			msg.invIcon = Profile.inventoryIcon
		else
			msg.inv = {}
			msg.invIcon = "Interface/Icons/inv_misc_bag_08"
		end
		
		msg.cur = Profile.currency
		msg.cura = Profile.currencyActive
		
		if #Profile.shop > 0 then
			msg.shop = Profile.shop
			msg.shopIcon = Profile.shopIcon
		else
			msg.shop = {}
			msg.shopIcon = "Interface/Icons/garrison_building_tradingpost"
		end
		
		local msg = Me:Serialize( "STATUS", msg )
		
		Me:SendCommMessage( "DCM4", msg, dist, channel, "ALERT" )
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

-------------------------------------------------------------------------------
-- Send data for your stats.
--
-- @param dist    Addon message distribution.
-- @param channel Whisper target or channel name.
--
function Me.Inspect_SendStats( dist, channel )

	local stats = {}

	if Profile.stats and #Profile.stats > 0 then		
		
		for i = 1, #Profile.stats do
			local buffValue = Me.TraitEditor_AddStatisticsToValue( Profile.stats[i].name )
			
			local value = nil
			
			if Profile.stats[i].value then
				value = Profile.stats[i].value + buffValue
			end
			
			local data = {
				name = Profile.stats[i].name;
				desc = Profile.stats[i].desc or nil;
				value = value or nil;
				attribute = Profile.stats[i].attribute or nil;
			}
			
			tinsert( stats, data )
		end
		
	end
	
	local msg = Me:Serialize( "STATS", {
		stats = stats;
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
	
	Me.Inspect_SendStatus( "RAID" )
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
		-- they're requesting base stats.
		if not Profile.stats then
			return
		end
		Me.Inspect_SendStats( "WHISPER", sender )
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
		icon    = data.t;
	}
	
	-- we flag them as having dicemaster once we receive their first message
	-- if they don't have this set, then the inspect panel isn't shown
	Me.inspectData[sender].hasDM4 = true
	
	Me.Inspect_OnTraitUpdated( sender, data.i )
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
	store.armor          = data.ar
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
	if data.inv then
		store.inventory = data.inv
		store.inventoryIcon = store.invIcon
	else
		store.inventory = {};
		store.inventoryIcon = "Interface/Icons/inv_misc_bag_08";
	end
	if data.cur then
		store.currency = data.cur
		store.currencyActive = data.cura
	else
		store.currency = Me.Profile.currency[1]
		store.currencyActive = 1;
	end
	if data.shop then
		store.shop = data.shop
		store.shopIcon = data.shopIcon
	else
		store.shop = {};
		store.shopIcon = "Interface/Icons/garrison_building_tradingpost"
	end
	store.hasDM4         = true
	
	Me.Inspect_OnStatusUpdated( sender )
	Me.StatInspector_UpdatePet()
	Me.DiceMasterRollDetailFrame_Update()
	Me.DMRosterFrame_Update()
end

---------------------------------------------------------------------------
-- Received STATS data.
--
function Me.Inspect_OnStatsMessage( data, dist, sender )
	
	-- Ignore our own data.
	if sender == UnitName( "player" ) then return end
	
	-- sanitize message
	if not data.stats or not type(data.stats) == "table" then
		-- we require index in message
		return
	end
	
	-- store in database
	Me.inspectData[sender].stats = data.stats
	
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
			Profile.experience = Profile.experience - 100
			Profile.level = Profile.level + 1;
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
	Me.TraitEditor_StatsList_Update()
	Me.DiceMasterRollDetailFrame_Update()
	Me.DMRosterFrame_Update()
end

---------------------------------------------------------------------------
-- Received SETHP data.
--
local healthAnimationPlaying = false;
local healAmount = {};
local damageAmount = 0;

function Me.Inspect_OnSetHPMessage( data, dist, sender )
	
	-- Only the party leader can grant experience.
	if not UnitIsGroupLeader( sender , 1 ) and not UnitIsGroupAssistant( sender, 1 ) then return end
	
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
		end
	end
	
	C_Timer.After( 3, function() 
		if type(next(healAmount)) ~= "nil"  then
			for k, v in pairs( healAmount ) do
				Me.PrintMessage( k .. " has healed you for |cFFFFFFFF" .. v .. "|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t!", "RAID" )
			end
		end
		if damageAmount > 0 then
			Me.PrintMessage( "You have lost |cFFFFFFFF" .. damageAmount .. "|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t!", "RAID" )
		end
		healthAnimationPlaying = false
		healAmount = {};
		damageAmount = 0;
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

-------------------------------------------------------------------------------
-- ADDON_LOADED handler
--
function Me.Inspect_Init()
	-- listen for messages
	
end


