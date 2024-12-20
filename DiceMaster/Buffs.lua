-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Buff frame interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

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

------------------------------------------------------------

function Me.BuffFrame_OnLoad(self)
	self:RegisterUnitEvent("UNIT_AURA", "player", "vehicle");
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");

	for i = 1, #BuffFrame.auraFrames do
		BuffFrame.auraFrames[i].Dummy = CreateFrame("FRAME", nil, BuffFrame.auraFrames[i], "DiceMasterAuraDummyTemplate");
		BuffFrame.auraFrames[i].Dummy:SetAllPoints();
		BuffFrame.auraFrames[i].Dummy:SetScript("OnUpdate", function(self)
			if GameTooltip:IsOwned(self) then
				self:GetParent():GetScript("OnEnter")(self:GetParent())
			end
		end);
	end

	hooksecurefunc( BuffFrame, "UpdateAuras", function()
		for i = 1, #Profile.buffsActive do
			local timeLeft = Profile.buffsActive[i].expirationTime - GetTime();
			if ( timeLeft > 0 ) or ( Profile.buffsActive[i].duration and Profile.buffsActive[i].duration == 0 ) or ( Profile.buffsActive[i].turns and Profile.buffsActive[i].turns > 0 ) then
				local buffTable = BuffFrame.auraInfo
				local data = {
					isDMBuff = true;
					auraType = "Buff";
					debuffType = Profile.buffsActive[i].debuffType or nil;
					index = 0;
					ID = i;
					name = Profile.buffsActive[i].name;
					texture = Profile.buffsActive[i].icon;
					description = Profile.buffsActive[i].description;
					count = Profile.buffsActive[i].count;
					duration = Profile.buffsActive[i].duration;
					turns = Profile.buffsActive[i].turns or 0;
					expirationTime = Profile.buffsActive[i].expirationTime or 0;
					sender = Profile.buffsActive[i].sender;
				}
				tinsert( buffTable, data )
			end
		end
	end)

	for i = 1, #BuffFrame.auraFrames do
		BuffFrame.auraFrames[i]:HookScript("OnEnter", function( self )
			if self.buttonInfo.isDMBuff then
				local data = self.buttonInfo;
				local timeLeft;
				if ( data.duration and data.duration > 0 and data.expirationTime and data.expirationTime > 0 ) then
					timeLeft = (data.expirationTime - GetTime());
				end
				GameTooltip:SetOwner( self.Dummy, "ANCHOR_BOTTOMLEFT" )
				if data.debuffType then
					GameTooltip:AddDoubleLine( data.name, data.debuffType, 1, 0.81, 0, 1, 0.81, 0, true, true )
				else
					GameTooltip:AddLine( data.name, 1, 0.81, 0, true )
				end
				GameTooltip:AddLine( Me.FormatDescTooltip( data.description ), 1, 1, 1, true )
				if timeLeft then
					GameTooltip:AddLine( Me.BuffButton_FormatTime(timeLeft).." remaining", 1, 0.81, 0, true )
				elseif data.turns and data.turns > 0 then
					if data.turns > 1 then
						GameTooltip:AddLine( data.turns .. " turns remaining", 1, 0.81, 0, true )
					else
						GameTooltip:AddLine( data.turns .. " turn remaining", 1, 0.81, 0, true )
					end
				end
				GameTooltip:AddLine( "Given by ".. data.sender, 0.5, 0.5, 0.5, true )
				GameTooltip:Show()
			end
		end)
		BuffFrame.auraFrames[i]:HookScript("OnClick", function( self, button )
			if self.buttonInfo.isDMBuff then
				local data = self.buttonInfo;
				if Profile.buffsActive[self:GetID()].count == 1 then
					tremove( Profile.buffsActive, self:GetID() )
				else
					Profile.buffsActive[self:GetID()].count = Profile.buffsActive[self:GetID()].count - 1
				end
				BuffFrame:Update();
				Me.SkillFrame_UpdateSkills()
			end
		end)
		hooksecurefunc(BuffFrame.auraFrames[i], "Update", function( self, buttonInfo )
			if buttonInfo.isDMBuff then
				local data = buttonInfo;
				local timeLeft = (data.expirationTime - GetTime());
				if ( data.duration and data.duration > 0 and data.expirationTime and data.expirationTime > 0 ) or ( data.turns and data.turns > 0 ) then
					self.Duration:Show()
					if data.turns and data.turns > 0 then
						self.Duration:SetText( data.turns .. " t" )
						self.Duration:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
					else
						self.Duration:SetFormattedText(SecondsToTimeAbbrev(timeLeft));
						if timeLeft < BUFF_DURATION_WARNING_TIME then
							self.Duration:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
						else
							self.Duration:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
						end
					end
				else
					self.Duration:Hide()
				end
			end
		end)
		hooksecurefunc(BuffFrame.auraFrames[i], "UpdateDuration", function( self, timeLeft )
			if self.buttonInfo.isDMBuff then
				if timeLeft <= 0 then
					BuffFrame:UpdateAuras();
					BuffFrame:UpdateAuraButtons();
					tremove( Profile.buffsActive, self:GetID() )
					Me.SkillFrame_UpdateSkills()
				end
			end
		end)
	end
end

function Me.BuffButton_Update(buttonName, index)
	local data = Profile.buffsActive[index] or nil
	local name, icon, description, count, duration, turns, expirationTime, sender
	if data then 
		name = data.name
		icon = data.icon
		description = data.description
		count = data.count
		duration = data.duration
		turns = data.turns or 0
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
		-- If button doesn't exist make it
		if ( not buff ) then
			buff = CreateFrame("Button", buffName, DiceMasterBuffFrame, "DiceMasterBuffButtonTemplate");
			buff.parent = DiceMasterBuffFrame;
			Me.SetupTooltip( buff, nil, "|cFFffd100"..name, nil, nil, Me.FormatDescTooltip( description ), nil, "|cFF707070Given by "..sender )
		end
		-- Setup Buff
		buff:SetID(index);
		buff:SetAlpha(1.0);
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
				buff:SetScript("OnUpdate", Me.BuffButton_OnUpdate);
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
		
		if ( turns and turns > 0 ) then
			if ( SHOW_BUFF_DURATIONS == "1" ) then
				buff.turns:Show();
				buff.turns:SetText( turns .. " turn" )
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
		elseif ( turns and turns > 0 ) then
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

function Me.BuffButton_OnUpdate(self)
	local index = self:GetID();
	if ( self.timeLeft < BUFF_WARNING_TIME ) then
		self:SetAlpha(1.0);
	else
		self:SetAlpha(1.0);
	end

	-- Update duration
	Me.BuffButton_UpdateDuration( self, self.timeLeft )
	
	-- Update our timeLeft
	local timeLeft = self.expirationTime - GetTime();
	self.timeLeft = max( timeLeft, 0 );
	
	if timeLeft < 0 then
		tremove( Profile.buffsActive, self:GetID() )
		Me.SkillFrame_UpdateSkills()
		Me.BuffFrame_Update()
		Me.BumpSerial( Me.db.char, "statusSerial" )
		Me.Inspect_ShareStatusWithParty()
		Me.Inspect_SendSkills( "RAID" )
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
		Me.SetupTooltip( self, nil, "|cFFffd100"..Profile.buffsActive[index].name, nil, nil, Me.FormatDescTooltip( Profile.buffsActive[index].description ), nil, Me.BuffButton_FormatTime(timeLeft).." remaining|n|cFF707070Given by "..Profile.buffsActive[index].sender )
		self:GetScript("OnEnter")( self )
	end
end

function Me.BuffButton_UpdateDuration( button, timeLeft )
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

function Me.BuffButton_OnLoad(self)
	self:RegisterForClicks("RightButtonUp");
end

function Me.BuffButton_OnClick(self)
	if Profile.buffsActive[self:GetID()].count == 1 then
		tremove( Profile.buffsActive, self:GetID() )
		Me.Inspect_SendSkills( "RAID" )
	else
		Profile.buffsActive[self:GetID()].count = Profile.buffsActive[self:GetID()].count - 1
	end
	Me.SkillFrame_UpdateSkills()
	Me.BuffFrame_Update()
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty()
end

function Me.BuffFrame_CastBuff( data )
	local buff
	if type( data ) == "table" and data.type and data.type == "buff" then
		buff = data
	elseif type( data ) == "number" then
		buff = Profile.traits[ data ]["effects"]["buff"]
	end
	if buff then
		local name = tostring( buff.name )
		local icon = tostring( buff.icon )
		local desc = tostring( buff.desc )
		local debuffType
		if buff.debuffType then
			debuffType = tostring( buff.debuffType );
		end
		local skill = tostring( buff.skill )
		local skillRank = tonumber( buff.skillRank )
		local duration = 0;
		local turns = 0;
		if buff.duration and buff.duration > 0 then
			if BUFF_DURATION_AMOUNTS[buff.duration].time then
				duration = BUFF_DURATION_AMOUNTS[buff.duration].time
			elseif BUFF_DURATION_AMOUNTS[buff.duration].turns then
				turns = BUFF_DURATION_AMOUNTS[buff.duration].turns
			end
		end
		local aoe = buff.aoe or false
		local range = tonumber( buff.range )
		if not aoe then
			range = nil
		end
		local target = UnitName("player")
		if buff.target == false then
			target = UnitName("target") or UnitName("player")
		end
		local stackable = buff.stackable
		
		if name == "" or icon == "" or desc == "" then return end
		
		local msg = Me:Serialize( "BUFF", {
			na = name;
			ic = icon;
			de = desc;
			dt = debuffType;
			at = skill;
			am = skillRank;
			st = stackable;
			co = 1;
			du = duration;
			tu = turns;
		})
		
		if range then
			Me.BuffFrame_CastAOEBuff( target, range, msg )
		end
		
		Me:SendCommMessage( "DCM4", msg, "WHISPER", target, "NORMAL" )
		
		C_Timer.After( 0.5, function() Me.Inspect_Open( UnitName( "target" )) end)
	end
end

function Me.BuffFrame_RemoveBuff( data )
	local removebuff
	if type( data ) == "table" and data.type and data.type == "removebuff" then
		removebuff = data
	elseif type( data ) == "number" then
		removebuff = Profile.traits[ data ]["effects"]["removebuff"]
	end
	if removebuff then
		local name = tostring( removebuff.name )
		local count = tostring( removebuff.count )
		local target = UnitName("target") or UnitName("player")
		
		if name == "" then return end
		
		local msg = Me:Serialize( "REMOVE", {
			na = name;
			co = count;
		})
		
		Me:SendCommMessage( "DCM4", msg, "WHISPER", target, "NORMAL" )
		
		C_Timer.After( 0.5, function() Me.Inspect_Open( UnitName( "target" )) end)
	end
end

function Me.BuffFrame_CastAOEBuff( target, range, buff )
	if not IsInGroup( LE_PARTY_CATEGORY_HOME ) or not target or not range or not buff then return end
	
	local y1, x1, _, instance1 = UnitPosition( target )
	for i = 1, GetNumGroupMembers(1) do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
		local y2, x2, _, instance2 = UnitPosition( "raid" .. i )
		local distance = instance1 == instance2 and ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
		if type(distance)=="number" and tonumber(distance) <= range and online and name~=target then
			Me:SendCommMessage( "DCM4", buff, "WHISPER", UnitName( "raid"..i ), "NORMAL" )
		end
	end
end

function Me.BuffFrame_RollDice( data )
	local setdice
	if type( data ) == "table" and data.type and data.type == "setdice" then
		setdice = data
	elseif type( data ) == "number" then
		setdice = Profile.traits[ data ]["effects"]["setdice"] or nil
	end
	
	if not setdice then return end
	
	local modifier = 0
	
	if setdice.skill then
		for i = 1,#Profile.skills do
			if Profile.skills[i].name == setdice.skill then
				modifier = Profile.skills[i].rank
				break
			end
		end
		
		for i = 1,#Profile.buffsActive do
			if Profile.buffsActive[i].skill and Profile.buffsActive[i].skill == setdice.skill then
				modifier = modifier + ( Profile.buffsActive[i].skillRank * Profile.buffsActive[i].count );
			end
		end
	end
	
	if setdice then
		local dice = Me.FormatDiceString( setdice.value, modifier )
		Me.Roll( dice )
	end
end

---------------------------------------------------------------------------
-- Received a buff request.
--  na = name							string
--	ic = icon							string
-- 	de = description					string
--  at = skill							string
--  am = skill rank						number
--  st = stackable						boolean
--  co = count							number
--  du = duration						number
--  tu = turns							number

function Me.BuffFrame_OnBuffMessage( data, dist, sender )
	-- Only accept buffs if we're in a party.
	if not IsInGroup( LE_PARTY_CATEGORY_HOME ) and sender ~= UnitName("player") then return end
 
	-- sanitize message
	if not data.na or not data.ic or not data.de or not data.co then
	   
		return
	end
	
	-- search for duplicates
	local found = false
	for i = 1, #Profile.buffsActive do
		local buff = Profile.buffsActive[i]
		if buff.name == data.na and buff.sender == sender then
			-- check if buff is stackable
			if not data.st then
				tremove( Profile.buffsActive, i )
			else
				found = true
				buff.count = buff.count + 1
				buff.expirationTime = (GetTime() + tonumber( data.du or 0 ))
			end
			break
		end		
	end
	
	-- if buff doesn't exist and we have less than 32, apply it
	if not found and #Profile.buffsActive < 32 then
		local buff = {
			name = tostring(data.na),
			icon = tostring(data.ic),
			description = tostring(data.de),
			count = tonumber(data.co),
			duration = 0,
			expirationTime = 0,
			turns = 0,
			sender = sender,
		}
		if data.dt and DebuffTypeColor[tostring(data.dt)] then
			buff.debuffType = tostring(data.dt)
		end
		if data.du and tonumber(data.du) > 0 then
			buff.duration = tonumber(data.du)
			buff.expirationTime = (GetTime() + tonumber( data.du ))
		end
		if data.tu then
			buff.turns = tonumber(data.tu)
		end
		if data.at and data.am then
			buff.skill = tostring(data.at)
			buff.skillRank = tonumber(data.am)
		end
		tinsert( Profile.buffsActive, buff )
	end
	Me.SkillFrame_UpdateSkills()
	Me.BumpSerial( Me.db.char, "statusSerial" )
	BuffFrame:Update();
	Me.Inspect_ShareStatusWithParty()
	Me.Inspect_SendSkills( "RAID" )
end

---------------------------------------------------------------------------
-- Received a buff removal request.
--  na = name							string
--  co = count							number

function Me.BuffFrame_OnRemoveBuffMessage( data, dist, sender )
	-- Only accept buffs if we're in a party.
	if not IsInGroup( LE_PARTY_CATEGORY_HOME ) and sender ~= UnitName("player") then return end
 
	-- sanitize message
	if not data.na or not data.co then
	   
		return
	end
	
	-- search for buff
	for i = 1, #Profile.buffsActive do
		local buff = Profile.buffsActive[i]
		if buff.name == data.na then
			-- check if buff stacks
			if buff.count == 1 then
				tremove( Profile.buffsActive, i )
			else
				buff.count = buff.count - 1
			end
		end		
	end
	Me.SkillFrame_UpdateSkills()
	Me.BumpSerial( Me.db.char, "statusSerial" )
	BuffFrame:Update();
	Me.Inspect_ShareStatusWithParty()
end
