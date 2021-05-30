-------------------------------------------------------------------------------
-- DiceMaster (C) 2019 <The League of Lordaeron> - Moon Guard
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
-- StaticPopupDialogs
--

StaticPopupDialogs["DICEMASTER4_OVERWRITEBUFF"] = {
  text = "A buff with this name already exists. Are you sure you want to overwrite it?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function (self)
	Me.UnitFramesBuffEditor_SaveBuff()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_DELETEBUFF"] = {
  text = "Are you sure you want to delete this buff?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function (self, data)
	Me.UnitFramesBuffEditor_DeleteBuff( data )
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-------------------------------------------------------------------------------
-- Apply Buff Editor
--

function Me.UnitFramesBuffEditor_SaveBuff()
	local editor = DiceMasterUnitFramesBuffEditor
	if not editor.buffIcon.icon:GetTexture() then return end

	local icon = editor.buffIcon.icon:GetTexture()
	local name = editor.buffName:GetText()
	local desc = editor.buffDesc.EditBox:GetText()
	local duration = 0
	if not editor.buffCancelable:GetChecked() then
		duration = editor.buffDuration:GetValue()
	end
	local stackable = editor.buffStackable:GetChecked()
	
	if name~="" then
		DiceMaster4UF_Saved.FavouriteAffixes[name] = {}
		DiceMaster4UF_Saved.FavouriteAffixes[name].icon = icon
		DiceMaster4UF_Saved.FavouriteAffixes[name].name = name
		DiceMaster4UF_Saved.FavouriteAffixes[name].desc = desc
		DiceMaster4UF_Saved.FavouriteAffixes[name].duration = duration
		DiceMaster4UF_Saved.FavouriteAffixes[name].stackable = stackable
		Me.PrintMessage("|T"..icon..":16|t "..name.." saved.", "SYSTEM");
	end
end

function Me.UnitFramesBuffEditor_DeleteBuff( affix )
	local editor = DiceMasterUnitFramesBuffEditor
	editor.buffIcon:SetTexture("Interface/Icons/inv_misc_questionmark")
	editor.buffName:SetText("")
	editor.buffDesc.EditBox:SetText("")
	editor.buffCancelable:SetChecked( false )
	editor.buffDuration:SetValue( 1 )
	editor.buffDuration:Show()
	editor.buffStackable:SetChecked( false )
	if DiceMaster4UF_Saved.FavouriteAffixes[affix] then
		Me.PrintMessage("|T"..DiceMaster4UF_Saved.FavouriteAffixes[affix].icon..":16|t "..affix.." deleted.", "SYSTEM");
		DiceMaster4UF_Saved.FavouriteAffixes[affix] = nil;
	end
end

function Me.UnitFramesBuffEditor_ApplyBuff( self )
	local editor = DiceMasterUnitFramesBuffEditor
	local unitframe = Me.UnitEditing

	if not editor.buffIcon.icon:GetTexture() then return end
	
	local icon = editor.buffIcon.icon:GetTexture()
	local name = editor.buffName:GetText() or nil
	local desc = editor.buffDesc.EditBox:GetText() or nil
	local duration = 0
	local turns = 0
	if not editor.buffCancelable:GetChecked() then
		if BUFF_DURATION_AMOUNTS[editor.buffDuration:GetValue()].time then
			duration = BUFF_DURATION_AMOUNTS[editor.buffDuration:GetValue()].time
		elseif BUFF_DURATION_AMOUNTS[editor.buffDuration:GetValue()].turns then
			turns = BUFF_DURATION_AMOUNTS[editor.buffDuration:GetValue()].turns
		end
	end
	local stackable = editor.buffStackable:GetChecked()
	
	if name == "" or not icon or desc == "" or not duration then
		return
	end	
	
	-- search for duplicates
	local found = false
	for i = 1, #unitframe.buffsActive do
		local buff = unitframe.buffsActive[i]
		if buff.name == name and buff.sender == UnitName("player") then
			if not stackable then
				tremove( unitframe.buffsActive, i )
			else
				found = true
				buff.count = buff.count + 1
				buff.expirationTime = (GetTime() + tonumber( duration ))
			end
			break
		end		
	end
	
	-- if buff doesn't exist and we have less than 15, apply it
	if not found and #unitframe.buffsActive < 15 then
		local buff = {
			name = tostring(name),
			icon = tostring(icon),
			description = tostring(desc),
			count = 1,
			duration = 0,
			turns = 0,
			sender = UnitName("player"),
		}
		if duration then
			buff.duration = tonumber(duration)
			buff.expirationTime = (GetTime() + tonumber( duration ))
		end
		if turns then
			buff.turns = tonumber( turns )
		end
		tinsert( unitframe.buffsActive, buff )
	end
	for i = 1, #unitframe.buffs do
		Me.UnitFrames_UpdateBuffButton( unitframe, i)
	end
	unitframe.buffFrame:Show()
	Me.UpdateUnitFrames()
end

function Me.UnitFramesBuffEditor_SelectIcon( texture )
	DiceMasterUnitFramesBuffEditor.buffIcon:SetTexture( texture )
	DiceMasterUnitFramesBuffEditor.buffIcon:Select( false )
end

function Me.UnitFramesBuffEditor_OnCloseClicked()
	PlaySound(840); 
	Me.IconPicker_Close()
	DiceMasterUnitFramesBuffEditor:Hide()
end

function Me.UnitFramesBuffEditor_Open()
	
	SetPortraitToTexture( DiceMasterUnitFramesBuffEditor.portrait, "Interface/Icons/Spell_Holy_WordFortitude" )
	DiceMasterUnitFramesBuffEditor.CloseButton:SetScript("OnClick",Me.UnitFramesBuffEditor_OnCloseClicked)
	
	DiceMaster4UF_Saved.FavouriteAffixes = DiceMaster4UF_Saved.FavouriteAffixes or {}
   
	DiceMasterUnitFramesBuffEditor:Show()
end

-------------------------------------------------------------------------------
-- Dropdown handlers for the load buffs menu.
--
function Me.UnitFramesBuffEditorDropDown_OnClick(self, arg1, arg2, checked)
	local duration = arg1.duration or 0
	local stackable = arg1.stackable or false
	local editor = DiceMasterUnitFramesBuffEditor
	
	editor.buffIcon:SetTexture( arg1.icon )
	editor.buffName:SetText( arg1.name )
	editor.buffDesc.EditBox:SetText( arg1.desc )
	if duration > 0 then
		editor.buffCancelable:SetChecked( false )
		editor.buffDuration:SetValue( duration )
		editor.buffDuration:Show()
	else
		editor.buffCancelable:SetChecked( true )
		editor.buffDuration:Hide()
	end
	editor.buffStackable:SetChecked( stackable )
end

function Me.UnitFramesBuffEditorDropDown_OnLoad( frame, level, menuList )
	local info      = UIDropDownMenu_CreateInfo();
	
	if level == 1 then
		info.notCheckable = true;
		info.text = "Conditions";
		info.disabled = false;
		info.notClickable = false;
		info.hasArrow = true;
		info.menuList = "Conditions";
		UIDropDownMenu_AddButton(info);
		info.hasArrow = false;
		info.menuList = nil;
		for k,v in pairs(DiceMaster4UF_Saved.FavouriteAffixes) do 
		   info.icon	   = v.icon or "Interface/Icons/inv_misc_questionmark";
		   info.tooltipTitle = k;
		   info.tooltipText = v.desc;
		   info.tooltipOnButton = true;
		   info.text       = k;
		   info.value      = 1;
		   info.notCheckable = true;
		   info.arg1	   = v;
		   info.func       = Me.UnitFramesBuffEditorDropDown_OnClick;
		   UIDropDownMenu_AddButton(info); 
		end
	elseif menuList then
		for i = 1,#Me.TermsList["Conditions"] do
			local conditionData = {
				name = Me.TermsList["Conditions"][i].altName,
				icon = Me.TermsList["Conditions"][i].icon,
				desc = Me.TermsList["Conditions"][i].desc,
				duration = 0,
				stackable = false,
			}
			info.icon = Me.TermsList["Conditions"][i].icon;
			info.tooltipTitle = Me.TermsList["Conditions"][i].altName;
			info.tooltipText = Me.TermsList["Conditions"][i].desc;
			info.tooltipOnButton = true;
			info.text = Me.TermsList["Conditions"][i].altName;
			info.value = 1;
			info.notCheckable = true;
			info.arg1 = conditionData;
			info.func = Me.UnitFramesBuffEditorDropDown_OnClick;
			UIDropDownMenu_AddButton(info, level); 
		end
	end
end

------------------------------------------------------------

function Me.UnitFrames_UpdateBuffButton(button, index)

	local data = button.buffsActive[index] or nil
	local name, icon, description, count, duration, turns, expirationTime, sender
	if data then 
		name = data.name
		icon = data.icon
		description = data.description
		count = data.count or 1
		duration = data.duration
		turns = data.turns or 0
		expirationTime = data.expirationTime
		sender = data.sender
	end
	
	local buffName = button.buffs[index];
	local buff = buffName;
	
	if ( not name ) then
		-- No buff so hide it if it exists
		if ( buff ) then
			buff:Hide();
			buff.duration:Hide();
		end
		return nil;
	else
		-- Setup Buff
		buff.owner = button;
		buff:SetID(index);
		buff:SetAlpha(1.0);
		--buff:SetScript("OnUpdate", Me.Inspect_BuffButton_OnUpdate);
		--Me.SetupTooltip( buff, nil, "|cFFffd100"..name, nil, nil, Me.FormatDescTooltip( description ), "|cFF707070Given by "..sender )
		buff:Show();

		if ( duration > 0 and expirationTime ) then
			buff.turns:Hide()
			if ( SHOW_BUFF_DURATIONS == "1" ) then
				buff.duration:Show();
			else
				buff.duration:Hide();
			end
			
			local timeLeft = (expirationTime - GetTime());

			if ( not buff.timeLeft ) then
				buff.timeLeft = timeLeft;
				buff:SetScript("OnUpdate", Me.UnitFrames_BuffButton_OnUpdate);
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
				buff.turns:SetText( turns .. " trn" )
			else
				buff.turns:Hide();
				buff.turns:SetText( "" )
			end
		end

		-- Set Icon
		local texture = buffName.Icon;
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

function Me.UnitFrames_BuffButton_OnUpdate(self)
	local data = self.owner.buffsActive[self:GetID()] or nil
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
	
	if self.timeLeft == 0 then
		tremove(self.owner.buffsActive, self:GetID())
		for i = 1, #self.owner.buffs do
			Me.UnitFrames_UpdateBuffButton(self.owner, i)
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

function Me.UnitFrames_BuffButton_OnLoad(self)
	self:RegisterForClicks("RightButtonUp");
end

function Me.UnitFrames_BuffButton_OnClick(self)
	if not Me.IsLeader( false ) then return end
	
	if self.owner.buffsActive[self:GetID()].count == 1 then
		tremove( self.owner.buffsActive, self:GetID() )
	else
		self.owner.buffsActive[self:GetID()].count = self.owner.buffsActive[self:GetID()].count - 1
	end
	for i = 1, #self.owner.buffs do
		Me.UnitFrames_UpdateBuffButton(self.owner, i)
	end
	Me.UpdateUnitFrames()
end