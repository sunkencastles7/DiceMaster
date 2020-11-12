-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
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

-------------------------------------------------------------------------------
-- Remove Buff Editor
--

function Me.RemoveBuffEditor_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText(Me.removebuffeditor.buffName, "")
	if self:GetText() ~= "" then
		UIDropDownMenu_SetText(Me.removebuffeditor.buffName, self:GetText())
	end
	Me.RemoveBuffEditor_Save()
end

function Me.RemoveBuffEditor_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	local found = false;

	  for i=1,5 do
		if Me.db.global.traitsList[i].buffs and not Me.db.global.traitsList[i].buffs.blank then		
		   info.text = Me.db.global.traitsList[i].buffs.name
		   info.icon = Me.db.global.traitsList[i].buffs.icon
		   info.arg1 = Me.db.global.traitsList[i].buffs
		   info.checked = Me.db.global.traitsList[Me.trait_editing].removebuffs.name == Me.db.global.traitsList[i].buffs.name;
		   info.notCheckable = false;
		   info.func = Me.RemoveBuffEditor_OnClick;
		   UIDropDownMenu_AddButton(info, level)
		end
		if Me.db.global.traitsList[i].buffs and Me.db.global.traitsList[i].buffs.name == Me.db.global.traitsList[Me.trait_editing].removebuffs.name then
			found = true;
		end
	  end
	UIDropDownMenu_SetText(frame, "")
	if not found then
		Me.db.global.traitsList[Me.trait_editing].removebuffs = nil
	end
	if Me.db.global.traitsList[Me.trait_editing].removebuffs and Me.db.global.traitsList[Me.trait_editing].removebuffs.name then
		UIDropDownMenu_SetText(frame, Me.db.global.traitsList[Me.trait_editing].removebuffs.name)
	end
end

function Me.RemoveBuffEditor_Refresh()
	local removebuff = Me.db.global.traitsList[Me.trait_editing].removebuffs or nil
	if not removebuff then
		removebuff = {
			name = "",
			count = 1,
			blank = true,
		}
		Me.db.global.traitsList[Me.trait_editing].removebuffs = removebuff
	end
	Me.removebuffeditor.buffName:SetText( removebuff.name )
	Me.removebuffeditor.buffCount:SetText( removebuff.count )
end

function Me.RemoveBuffEditor_Save()
	if not UIDropDownMenu_GetText(Me.removebuffeditor.buffName) then
		UIErrorsFrame:AddMessage( "You must select a buff from the dropdown.", 1.0, 0.0, 0.0, 53, 5 );
		return
	end
	local removebuff = {
		name = UIDropDownMenu_GetText(Me.removebuffeditor.buffName);
		count = Me.removebuffeditor.buffCount:GetText();
		blank = false;
	}
	Me.db.global.traitsList[Me.trait_editing].removebuffs = removebuff
end

function Me.RemoveBuffEditor_DeleteBuff()
	Me.db.global.traitsList[Me.trait_editing].removebuffs = nil
	
	PlaySound(840); 
	Me.removebuffeditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.RemoveBuffEditor_OnCloseClicked()
	Me.RemoveBuffEditor_Save()
	PlaySound(840); 
	Me.removebuffeditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.RemoveBuffEditor_Open()
	Me.SoundPicker_Close()
	Me.EffectPicker_Close()
	if Me.buffeditor:IsShown() or Me.setdiceeditor:IsShown() then
		Me.buffeditor:Hide()
		Me.setdiceeditor:Hide()
	end
   
	Me.RemoveBuffEditor_Refresh()
	Me.removebuffeditor:Show()
end

-------------------------------------------------------------------------------
-- Set Dice Editor
--

function Me.SetDiceEditor_Refresh()
	local setdice = Me.db.global.traitsList[Me.editing_trait].setdice or nil
	if not setdice then
		setdice = {
			value = "D20";
			stat = "";
			blank = true,
		}
		Me.db.global.traitsList[Me.editing_trait].setdice = dice
	end
	Me.setdiceeditor.diceValue:SetText( setdice.value )
	Me.setdiceeditor.statName:SetText( setdice.stat )
end

function Me.SetDiceEditor_Save()
	if not Me.FormatDiceString( Me.setdiceeditor.diceValue:GetText() ) then
		Me.setdiceeditor.diceValue:SetText("D20")
	end
	local setdice = {
		value = Me.setdiceeditor.diceValue:GetText();
		stat = Me.setdiceeditor.statName:GetText();
		blank = false,
	}
	Me.db.global.traitsList[Me.editing_trait].setdice = setdice
end

function Me.SetDiceEditor_Delete()
	Me.db.global.traitsList[Me.editing_trait].setdice = nil
	
	PlaySound(840); 
	Me.setdiceeditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.SetDiceEditor_OnCloseClicked()
	Me.SetDiceEditor_Save()
	PlaySound(840); 
	Me.setdiceeditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.SetDiceEditor_Open()
	Me.SoundPicker_Close()
	Me.EffectPicker_Close()
	if Me.buffeditor:IsShown() or Me.removebuffeditor:IsShown() then
		Me.buffeditor:Hide()
		Me.removebuffeditor:Hide()
	end
   
	Me.RemoveBuffEditor_Refresh()
	Me.setdiceeditor:Show()
end

-------------------------------------------------------------------------------
-- Apply Buff Editor
--

function Me.BuffButton_FormatTime( seconds )
	local timeRemaining = math.floor( seconds ) .. " seconds"
	if seconds > 86400 then
		seconds = math.ceil( seconds / 86400 )
		timeRemaining = seconds .. " days"
	elseif seconds > 3600 then
		seconds = math.ceil( seconds / 3600 )
		timeRemaining = seconds .. " hours"
	elseif seconds > 60 then
		seconds = math.ceil( seconds / 60 )
		timeRemaining = seconds .. " minutes"
	end
	return timeRemaining
end

function Me.BuffEditor_Refresh()
	local buff = Me.db.global.traitsList[Me.editing_trait].buffs or nil
	if not buff then
		buff = {
			icon = "Interface/Icons/inv_misc_questionmark",
			name = "",
			desc = "",
			stat = "",
			statAmount = 0,
			cancelable = true,
			duration = 1,
			target = true,
			aoe = false,
			range = 0,
			stackable = false,
			blank = true,
		}
		Me.db.global.traitsList[Me.editing_trait].buffs = buff
	end
	Me.buffeditor.buffIcon:SetTexture( buff.icon )
	Me.buffeditor.buffName:SetText( buff.name )
	Me.buffeditor.buffDesc.EditBox:SetText( buff.desc )
	Me.buffeditor.buffStatName:SetText( buff.stat or "" )
	Me.buffeditor.buffStatAmount:SetText( buff.statAmount or 0 )
	Me.buffeditor.buffCancelable:SetChecked( buff.cancelable )
	if buff.cancelable then
		DiceMasterBuffEditorBuffDuration:Disable()
		DiceMasterBuffEditorBuffDurationText:SetTextColor( 0.4, 0.4, 0.4 )
	else
		DiceMasterBuffEditorBuffDuration:Enable()
		DiceMasterBuffEditorBuffDurationText:SetTextColor( 1, 0.82, 0 )
	end
	Me.buffeditor.buffDuration:SetValue( buff.duration or 1 )
	Me.buffeditor.buffTarget:SetChecked( buff.target )
	Me.buffeditor.buffAOE:SetChecked( buff.aoe )
	Me.buffeditor.buffRange:SetText( buff.range or 0 )
	Me.buffeditor.buffStackable:SetChecked( buff.stackable )
end

function Me.BuffEditor_DeleteBuff()
	Me.db.global.traitsList[Me.editing_trait].buffs = nil
	
	PlaySound(840); 
	Me.IconPicker_Close()
	Me.buffeditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.BuffEditor_Save()
	if Me.buffeditor.buffName:GetText() == "" then
		UIErrorsFrame:AddMessage( "Invalid name: too short.", 1.0, 0.0, 0.0, 53, 5 );
		return
	end
	local buff = Me.db.global.traitsList[Me.editing_trait].buffs
	buff.name = Me.buffeditor.buffName:GetText()
	buff.desc = Me.buffeditor.buffDesc.EditBox:GetText()
	buff.stat = Me.buffeditor.buffStatName:GetText()
	buff.statAmount = Me.buffeditor.buffStatAmount:GetText()
	buff.cancelable = Me.buffeditor.buffCancelable:GetChecked()	
	if not buff.cancelable then
		buff.duration = Me.buffeditor.buffDuration:GetValue()
	else
		buff.duration = 1
	end
	buff.target = Me.buffeditor.buffTarget:GetChecked()
	buff.aoe = Me.buffeditor.buffAOE:GetChecked()
	if buff.aoe then 
		buff.range = Me.buffeditor.buffRange:GetText()
	else
		buff.range = 0
	end
	buff.stackable = Me.buffeditor.buffStackable:GetChecked()
	buff.blank = false
	Me.db.global.traitsList[Me.editing_trait].buffs = buff
end

function Me.BuffEditor_SelectIcon( texture )
	local buff = Me.db.global.traitsList[Me.editing_trait].buffs
	buff.icon = texture
	DiceMasterBuffEditor.buffIcon:SetTexture( texture )
end

function Me.BuffDuration_OnLoad( self )
	self:SetMinMaxValues(1, #BUFF_DURATION_AMOUNTS)
	self:SetObeyStepOnDrag( true )
	self:SetValueStep( 1 )
	self:SetValue(1)
	_G[self:GetName().."Low"]:Hide()
	_G[self:GetName().."High"]:Hide()
	_G[self:GetName().."Text"]:SetText("Buff Duration: "..BUFF_DURATION_AMOUNTS[self:GetValue()].name)
	self.tooltipText = "Set the duration for this buff."
end

function Me.BuffDuration_OnValueChanged( self, value, userInput )
	_G[self:GetName().."Text"]:SetText("Buff Duration: "..BUFF_DURATION_AMOUNTS[ value ].name)
end

function Me.BuffEditor_OnCloseClicked()
	Me.BuffEditor_Save()
	PlaySound(840); 
	Me.IconPicker_Close()
	Me.buffeditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.BuffEditor_Open()
	Me.SoundPicker_Close()
	Me.EffectPicker_Close()
	if Me.removebuffeditor:IsShown() or Me.setdiceeditor:IsShown() then
		Me.removebuffeditor:Hide()
		Me.setdiceeditor:Hide()
	end
   
	Me.BuffEditor_Refresh()
	Me.buffeditor:Show()
end

------------------------------------------------------------

function Me.BuffFrame_OnLoad(self)
	self:RegisterUnitEvent("UNIT_AURA", "player", "vehicle");
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
end

function Me.BuffFrame_OnEvent(self, event, ...)
	local unit = ...;
	if ( event == "UNIT_AURA" ) then
		if ( unit == PlayerFrame.unit ) then
			Me.BuffFrame_Update();
		end
	elseif ( event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" ) then
		Me.BuffFrame_Update();
	end
end

function Me.BuffFrame_Update()
	-- Handle Buffs
	DiceMasterBuffFrame.Display = 0;
	for i=1, ( 5 ) do
		if ( Me.BuffButton_Update("DiceMasterBuffButton", i) ) then
			DiceMasterBuffFrame.Display = DiceMasterBuffFrame.Display + 1;
		end
	end
	
	Me.BuffFrame_UpdateAllBuffAnchors();
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty()
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
		self:SetAlpha(BuffFrame.BuffAlphaValue);
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
		Me.TraitEditor_StatsFrame_UpdateStats()
		Me.BuffFrame_Update()
		Me.BumpSerial( Me.db.char, "statusSerial" )
		Me.Inspect_ShareStatusWithParty()
		Me.Inspect_SendStats( "RAID" )
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
		Me.Inspect_SendStats( "RAID" )
	else
		Profile.buffsActive[self:GetID()].count = Profile.buffsActive[self:GetID()].count - 1
	end
	Me.TraitEditor_StatsFrame_UpdateStats()
	Me.BuffFrame_Update()
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty()
end

local function FramesOverlap(frameA, frameB)
  local sA, sB = frameA:GetEffectiveScale(), frameB:GetEffectiveScale();
  return ((frameA:GetLeft()*sA) < (frameB:GetRight()*sB))
     and ((frameB:GetLeft()*sB) < (frameA:GetRight()*sA))
     and ((frameA:GetBottom()*sA) < (frameB:GetTop()*sB))
     and ((frameB:GetBottom()*sB) < (frameA:GetTop()*sA));
end

function Me.BuffFrame_UpdateAllBuffAnchors()
	local buff, previousBuff, aboveBuff, index;
	local numBuffs = 0;
	local numAuraRows = 0;
	
	for i = 1, DiceMasterBuffFrame.Display do
		buff = _G["DiceMasterBuffButton"..i];
		numBuffs = numBuffs + 1;
		if ( buff.parent ~= DiceMasterBuffFrame ) then
			buff.count:SetFontObject(NumberFontNormal);
			buff:SetParent(DiceMasterBuffFrame);
			buff.parent = DiceMasterBuffFrame;
		end
		buff:ClearAllPoints();
		if FramesOverlap(DiceMasterBuffFrame, BuffFrame) then
			if ( (numBuffs > 1) and (mod(BUFF_ACTUAL_DISPLAY + numBuffs, BUFFS_PER_ROW) == 1) ) then
				-- New row
				numAuraRows = numAuraRows + 1;
				buff:SetPoint("TOPRIGHT", aboveBuff, "BOTTOMRIGHT", 0, -BUFF_ROW_SPACING);
				aboveBuff = buff;
			elseif ( numBuffs == 1 ) then
				numAuraRows = 1;
				if _G["BuffButton1"] then
					buff:SetPoint("TOPRIGHT", _G["BuffButton" .. BUFF_ACTUAL_DISPLAY], "TOPLEFT", BUFF_HORIZ_SPACING, 0);
					if numBuffs < BUFF_ACTUAL_DISPLAY then
						aboveBuff = _G["BuffButton" .. numBuffs];
					else
						aboveBuff = buff
					end
				else
					buff:SetPoint("TOPRIGHT", DiceMasterBuffFrame, "TOPRIGHT", 0, 0);
					aboveBuff = buff
				end
			else
				buff:SetPoint("RIGHT", previousBuff, "LEFT", BUFF_HORIZ_SPACING, 0);
			end
		else
			if ( (numBuffs > 1) and (mod(numBuffs, BUFFS_PER_ROW) == 1) ) then
				-- New row
				numAuraRows = numAuraRows + 1;
				buff:SetPoint("TOPRIGHT", aboveBuff, "BOTTOMRIGHT", 0, -BUFF_ROW_SPACING);
				aboveBuff = buff;
			elseif ( numBuffs == 1 ) then
				numAuraRows = 1;
				buff:SetPoint("TOPRIGHT", DiceMasterBuffFrame, "TOPRIGHT", 0, 0);
				aboveBuff = buff
			else
				buff:SetPoint("RIGHT", previousBuff, "LEFT", BUFF_HORIZ_SPACING, 0);
			end
		end
		previousBuff = buff;
	end
end

function Me.BuffFrame_CastBuff( traitIndex )
	local buff = Me.db.global.traitsList[ traitIndex ].buffs
	if buff and not buff.blank then
		local name = tostring( buff.name )
		local icon = tostring( buff.icon )
		local desc = tostring( buff.desc )
		local stat = tostring( buff.stat )
		local statAmount = tonumber( buff.statAmount )
		local duration = 0;
		local turns = 0;
		if BUFF_DURATION_AMOUNTS[buff.duration].time then
			duration = BUFF_DURATION_AMOUNTS[buff.duration].time
		elseif BUFF_DURATION_AMOUNTS[buff.duration].turns then
			turns = BUFF_DURATION_AMOUNTS[buff.duration].turns
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
		if buff.cancelable then
			duration = 0;
			turns = 0;
		end
		local stackable = buff.stackable
		
		if name == "" or icon == "" or desc == "" then return end
		
		if Me.UnitFrameTargeted and not Me.db.char.unitframes.enable and not buff.target then
			-- We're targeting a Unit Frame.
			target = tonumber( Me.UnitFrameTargeted )
			
			local msg = Me:Serialize( "UFBUFF", {
				un = target;
				na = name;
				ic = icon;
				de = desc;
				st = stackable;
				co = 1;
				du = duration;
				tu = turns;
			})

			for i=1, MAX_RAID_MEMBERS do
				local name, rank = GetRaidRosterInfo(i)
				if name and UnitIsGroupLeader( name ) then
					Me:SendCommMessage( "DCM4", msg, "WHISPER", name, "NORMAL" )
					break
				end
			end
			return
		end
		
		local msg = Me:Serialize( "BUFF", {
			na = name;
			ic = icon;
			de = desc;
			at = stat;
			am = statAmount;
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

function Me.BuffFrame_RemoveBuff( traitIndex )
	local removebuff = Me.db.global.traitsList[ traitIndex ].removebuffs
	if removebuff and not removebuff.blank then
		local name = tostring( removebuff.name )
		local count = tostring( removebuff.count )
		local target = UnitName("target") or UnitName("player")
		
		if name == "" then return end
		
		if Me.UnitFrameTargeted and not Me.db.char.unitframes.enable then
			-- We're targeting a Unit Frame.
			target = tonumber( Me.UnitFrameTargeted )
			
			local msg = Me:Serialize( "UFREMOVE", {
				un = target;
				na = name;
				co = count;
			})

			for i=1, MAX_RAID_MEMBERS do
				local name, rank = GetRaidRosterInfo(i)
				if name and UnitIsGroupLeader( name ) then
					Me:SendCommMessage( "DCM4", msg, "WHISPER", name, "NORMAL" )
					break
				end
			end
			return
		end
		
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

function Me.BuffFrame_RollDice( traitIndex )
	local setdice = Me.db.global.traitsList[ traitIndex ].setdice or nil
	
	if not setdice then return end
	
	local modifier = 0
	
	if setdice.stat then
		for i = 1,#Profile.stats do
			if Profile.stats[i].name == setdice.stat then
				modifier = Profile.stats[i].value
				break
			end
		end
		
		for i = 1,#Profile.buffsActive do
			if Profile.buffsActive[i].statistic and Profile.buffsActive[i].statistic == setdice.stat then
				modifier = modifier + ( Profile.buffsActive[i].statAmount * Profile.buffsActive[i].count );
			end
		end
	end
	
	if setdice and not setdice.blank then
		local dice = Me.FormatDiceString( setdice.value, modifier )
		Me.Roll( dice )
	end
end

---------------------------------------------------------------------------
-- Received a buff request.
--  na = name							string
--	ic = icon							string
-- 	de = description					string
--  at = statistic						string
--  am = statistic amount				number
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
	
	-- if buff doesn't exist and we have less than 5, apply it
	if not found and #Profile.buffsActive < 5 then
		local buff = {
			name = tostring(data.na),
			icon = tostring(data.ic),
			description = tostring(data.de),
			count = tonumber(data.co),
			duration = 0,
			turns = 0,
			sender = sender,
		}
		if data.du then
			buff.duration = tonumber(data.du)
			buff.expirationTime = (GetTime() + tonumber( data.du ))
		end
		if data.tu then
			buff.turns = tonumber(data.tu)
		end
		if data.at and data.am then
			buff.statistic = tostring(data.at)
			buff.statAmount = tonumber(data.am)
		end
		tinsert( Profile.buffsActive, buff )
	end
	Me.TraitEditor_StatsFrame_UpdateStats()
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.BuffFrame_Update()
	Me.Inspect_ShareStatusWithParty()
	Me.Inspect_SendStats( "RAID" )
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
		if buff.name == data.na and buff.sender == sender then
			-- check if buff stacks
			if buff.count == 1 then
				tremove( Profile.buffsActive, i )
			else
				buff.count = buff.count - 1
			end
		end		
	end
	Me.TraitEditor_StatsFrame_UpdateStats()
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.BuffFrame_Update()
	Me.Inspect_ShareStatusWithParty()
end
