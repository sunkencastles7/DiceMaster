-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Icon picker interface.
--

local Me = DiceMaster4

local startOffset = 0
local filteredList = nil
local refreshCounter = 0;

C_Timer.NewTicker( 7, function() refreshCounter = 0 end )

Me.effectCount = #Me.effectList

function Me.UnitPickerDropDown_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText(DiceMasterUnitPicker.filter, self:GetText()) 
	Me.UnitPicker_FilterChanged( arg1 )
	if arg2 == "effects" then
		DiceMasterUnitPickerRenameButton:Enable()
		DiceMasterUnitPickerDeleteButton:Enable()
	else
		DiceMasterUnitPickerRenameButton:Disable()
		DiceMasterUnitPickerDeleteButton:Disable()
	end
end

function Me.MyEffectsDropDown_OnClick(self, arg1, arg2, checked)
	local svk = arg2.spellvisualkit
	if arg1 == "new" then
		StaticPopup_Show("DICEMASTER4_MYCOLLECTIONEFFECTS", nil, nil, svk)
	else
		for i=1,#DiceMaster4UF_Saved.MyEffects[arg1] do
			if DiceMaster4UF_Saved.MyEffects[arg1][i]==svk then
				return
			end
		end
		tinsert(DiceMaster4UF_Saved.MyEffects[arg1], svk)
		Me.UnitPicker_RefreshGrid()
	end
end

function Me.MyEffectsDropDown_Remove(self, arg1, arg2)
	tremove(DiceMaster4UF_Saved.MyEffects[arg1], arg2)
	Me.UnitPicker_RefreshGrid()
end

function Me.UnitPickerDropDown_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()

	 if level == 1 then
	  -- Outermost menu level
	  info.text = "Default"
	  info.arg1 = "default"
	  info.hasArrow = nil
	  info.checked = filteredList == nil;
	  info.notCheckable = false;
	  info.func = Me.UnitPickerDropDown_OnClick;
	  UIDropDownMenu_AddButton(info)
	  info.text = "My Effects"
	  info.hasArrow = true;
	  info.notCheckable = true;
	  info.func = nil;
	  info.menuList = "My Effects"
	  UIDropDownMenu_AddButton(info)
	  
	elseif menuList == "My Effects" then
	  -- Show the "My Effects" sub-menu
		if DiceMaster4UF_Saved.MyEffects then
			for k,v in pairs(DiceMaster4UF_Saved.MyEffects) do
			   info.text = k
			   info.arg1 = v
			   info.arg2 = "effects";
			   info.checked = filteredList == v;
			   info.notCheckable = false;
			   info.func = Me.UnitPickerDropDown_OnClick;
			   UIDropDownMenu_AddButton(info, level)
			end
		end
	end
end

function Me.MyEffectsDropDown_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.text = "|cFFffd100Add To..."
	info.notClickable = true;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info, level)
	info.text = "|cFF00FF00New..."
	info.arg1 = "new";
	info.arg2 = frame;
	info.disabled = false;
	info.notClickable = false;
    info.notCheckable = true;
    info.func = Me.MyEffectsDropDown_OnClick;
    UIDropDownMenu_AddButton(info, level)
	
	if DiceMaster4UF_Saved.MyEffects then
	  for k,v in pairs(DiceMaster4UF_Saved.MyEffects) do
	   info.text = k;
	   info.arg1 = k;
	   info.arg2 = frame;
	   info.disabled = false;
	   info.notCheckable = true;
	   	for i=1,#v do
			if frame.spellvisualkit==v[i] then
				info.disabled = true;
			end
		end
	   info.func = Me.MyEffectsDropDown_OnClick;
	   UIDropDownMenu_AddButton(info, level)
	  end
	
	info.text = "|cFFffd100Remove From..."
	info.notClickable = true;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info, level)
	for k,v in pairs(DiceMaster4UF_Saved.MyEffects) do
	   	for i=1,#v do
			if frame.spellvisualkit==v[i] then
			   info.text = k;
			   info.arg1 = k;
			   info.arg2 = i;
			   info.notClickable = false;
			   info.disabled = false;
			   info.notCheckable = true;
			   info.func = Me.MyEffectsDropDown_Remove;
			   UIDropDownMenu_AddButton(info, level)
			end
		end
	  end
	end
end

StaticPopupDialogs["DICEMASTER4_MYCOLLECTIONEFFECTS"] = {
  text = "Enter a name for this effects collection:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText("Effects Collection 1")
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data, data2)
    local text = self.editBox:GetText()
	if DiceMaster4UF_Saved.MyEffects[text] then
		UIErrorsFrame:AddMessage( text.." already exists.", 1.0, 0.0, 0.0, 53, 5 );
	elseif text~= "" then
		DiceMaster4UF_Saved.MyEffects[text] = {}
		tinsert(DiceMaster4UF_Saved.MyEffects[text], data)
		Me.PrintMessage("\""..text.."\" created.", "SYSTEM");
		Me.UnitPicker_RefreshGrid()
	else
		UIErrorsFrame:AddMessage( "Invalid name.", 1.0, 0.0, 0.0, 53, 5 );
	end
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_RENAMECOLLECTIONEFFECTS"] = {
  text = "Enter a new name for this effects collection:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText(data)
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data, data2)
    local text = self.editBox:GetText()
	if DiceMaster4UF_Saved.MyEffects[text] then
		UIErrorsFrame:AddMessage( text.." already exists.", 1.0, 0.0, 0.0, 53, 5 );
	elseif text~= "" then
		DiceMaster4UF_Saved.MyEffects[text] = DiceMaster4UF_Saved.MyEffects[data]
		DiceMaster4UF_Saved.MyEffects[data] = nil
		Me.PrintMessage("\""..data.."\" renamed to \""..text..".\"", "SYSTEM");
		UIDropDownMenu_SetText(DiceMasterUnitPickerFilter, text)
		Me.UnitPicker_RefreshGrid()
	else
		UIErrorsFrame:AddMessage( "Invalid name.", 1.0, 0.0, 0.0, 53, 5 );
	end
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_DELETECOLLECTIONEFFECTS"] = {
  text = "Are you sure you want to delete this effects collection?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function (self, data, data2)
	DiceMaster4UF_Saved.MyEffects[data] = nil
	Me.PrintMessage("\""..data.."\" deleted.", "SYSTEM");
	UIDropDownMenu_SetText(DiceMasterUnitPickerFilter, "Default")
	Me.UnitPicker_FilterChanged( "default" )
	Me.UnitPicker_RefreshGrid()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-------------------------------------------------------------------------------
-- When one of the icon buttons are clicked.
--
function Me.UnitPickerButton_OnClick( self, button )

	local value = math.floor(self:GetParent().scroller:GetValue())*4 + self.pickerIndex
	if filteredList then
		value = filteredList[value]
	else
		value = Me.effectList[value]
	end
	
	-- Apply the model to the edited frame and close the picker. ) 
		
	if button=="LeftButton" and Me.IsLeader( true ) then
		if Me.ModelEditing then
			local displayInfo = Me.ModelEditing:GetDisplayInfo()
			Me.ModelEditing:ClearModel()
			Me.ModelEditing:SetDisplayInfo( displayInfo )
			Me.ModelEditing.spellvisualkit = value
			Me.ModelEditing:SetSpellVisualKit(value)
			PlaySound(83)
			
			DiceMasterUnitPicker.checked = value;
			self.check:Show()
			
			Me.UpdateUnitFrames()
			Me.UnitPicker_RefreshGrid()
		end
	-- Right click to add/remove from our list of favourites.
	
	elseif button=="RightButton" then
		local height = self:GetHeight()
		ToggleDropDownMenu(1, nil, self, "cursor", 0, 0)
		self:SetHeight(height)
	end
end


-------------------------------------------------------------------------------
-- Handler for resetting effects that taint the model.
--
function Me.UnitPicker_ResetEffect()
	if Me.ModelEditing then
		local displayInfo = Me.ModelEditing:GetDisplayInfo()
		Me.ModelEditing:ClearModel()
		Me.ModelEditing.spellvisualkit = 0
		Me.ModelEditing:SetDisplayInfo( displayInfo )
		Me.ModelEditing:SetSpellVisualKit(0)
		
		DiceMasterAffixEditor.Model.Ticker:Cancel()
		
		DiceMasterUnitPicker.checked = nil
		Me.UnitPicker_RefreshGrid()
	end
	Me.UpdateUnitFrames()
end

-------------------------------------------------------------------------------
-- OnEnter handler, to magnify the icon and show the texture path.
--
function Me.UnitPickerButton_ShowTooltip( self )
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	
	local value = math.floor(self:GetParent().scroller:GetValue())*4 + self.pickerIndex
	if filteredList then
		value = filteredList[value]
	else
		value = Me.effectList[value]
	end
    GameTooltip:AddLine( "ID: " .. value, 1, 1, 1, true )
    GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- When the mousewheel is used on the icon map.
--
function Me.UnitPicker_MouseScroll( delta )

	local a = DiceMasterUnitPicker.selectorFrame.scroller:GetValue() - delta
	-- todo: do we need to clamp?
	DiceMasterUnitPicker.selectorFrame.scroller:SetValue( a )
end
   
-------------------------------------------------------------------------------
-- When the scrollbar's value is changed.
--
function Me.UnitPicker_ScrollChanged( value )
	-- Our "step" is 5 icons, which is one line.
	startOffset = math.floor(value) * 4
	Me.UnitPicker_RefreshGrid()
end

-------------------------------------------------------------------------------
-- Set the textures of the icon grid from the icons in the list at the
-- current offset.
--
function Me.UnitPicker_RefreshGrid()
	local list = filteredList or Me.effectList
	for k,v in ipairs( DiceMasterUnitPicker.icons ) do
		UIDropDownMenu_Initialize( DiceMasterUnitPickerFilter, DiceMaster4.UnitPickerDropDown_OnLoad )
		UIDropDownMenu_Initialize( v, DiceMaster4.MyEffectsDropDown_OnLoad )
		
		local tex
		if list[startOffset + k] then
			tex = list[startOffset + k]
		end
		if tex then
		
			v:Show()
			v:ClearModel()
			v:SetDisplayInfo(31)
			v.spellvisualkit = tex
			v:SetSpellVisualKit(tex)
			
			v:SetPortraitZoom(0.7)
			v:SetPortraitZoom(0)

			if DiceMasterUnitPicker.checked == tex then
				v.check:Show()
			else
				v.check:Hide()
			end	
			
		else
			v:Hide()
		end
	end
end

-------------------------------------------------------------------------------
-- Called when the user types into the search box.
--
function Me.UnitPicker_FilterChanged( list )
	if list and list~="default" then
		filteredList = list
	else
		filteredList = nil
	end
	Me.UnitPicker_RefreshScroll()
end

-------------------------------------------------------------------------------
-- When we change the size of the list, update the scroll bar range.
--
-- @param reset Reset the scroll bar to the beginning.
--
function Me.UnitPicker_RefreshScroll( reset, value )
	local list = filteredList or Me.effectList
	local max = math.floor((#list - 8) / 4)
	if max < 0 then max = 0 end
	DiceMasterUnitPicker.selectorFrame.scroller:SetMinMaxValues( 0, max )
	
	if reset then
		DiceMasterUnitPicker.selectorFrame.scroller:SetValue( 0 )
	elseif value then
		DiceMasterUnitPicker.selectorFrame.scroller:SetValue( math.floor(value) )
	end
	-- todo: does scroller auto clamp value?
	
	Me.UnitPicker_ScrollChanged( DiceMasterUnitPicker.selectorFrame.scroller:GetValue() )
end
    
-------------------------------------------------------------------------------
-- Close the icon picker window. Use this instead of a direct Hide()
--
function Me.UnitPicker_Close()
	Me.ModelEditing = nil;
	DiceMasterUnitPicker:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the icon picker window.
--
function Me.UnitPicker_Open( frame, model )
	DiceMasterUnitPicker:SetPoint( "LEFT", frame, "RIGHT" )
	Me.ModelEditing = model
	filteredList = nil

	DiceMaster4UF_Saved.MyEffects = DiceMaster4UF_Saved.MyEffects or {}

	if frame.effectscrollposition then
		Me.UnitPicker_RefreshScroll( nil, frame.effectscrollposition )
	elseif DiceMasterUnitPicker.scrollposition then
		Me.UnitPicker_RefreshScroll( nil, DiceMasterUnitPicker.scrollposition )
	else
		Me.UnitPicker_RefreshScroll( true )
	end 
	DiceMasterUnitPicker:Show()
end
