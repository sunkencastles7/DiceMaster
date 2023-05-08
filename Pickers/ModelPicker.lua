-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Model picker interface.
--

local Me = DiceMaster4

local startOffset = 0
local filteredList = nil

Me.unitList = 95525

-------------------------------------------------------------------------------
-- StaticPopupDialogs for Collections.
--

StaticPopupDialogs["DICEMASTER4_CREATECOLLECTION"] = {
  text = "Enter a name for this model collection:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText("Collection 1")
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data, data2)
    local text = self.editBox:GetText()
	if DiceMaster4UF_Saved.MyCollection[text] then
		UIErrorsFrame:AddMessage( text.." already exists.", 1.0, 0.0, 0.0 );
	elseif text~= "" then
		DiceMaster4UF_Saved.MyCollection[text] = {}
		tinsert(DiceMaster4UF_Saved.MyCollection[text], data)
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t \""..text.."\" created.", "SYSTEM");
		Me.ModelPicker_RefreshGrid()
	else
		UIErrorsFrame:AddMessage( "Invalid name.", 1.0, 0.0, 0.0 );
	end
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_RENAMECOLLECTION"] = {
  text = "Enter a new name for this model collection:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText(data)
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data, data2)
    local text = self.editBox:GetText()
	if DiceMaster4UF_Saved.MyCollection[text] then
		UIErrorsFrame:AddMessage( text.." already exists.", 1.0, 0.0, 0.0 );
	elseif text~= "" then
		DiceMaster4UF_Saved.MyCollection[text] = DiceMaster4UF_Saved.MyCollection[data]
		DiceMaster4UF_Saved.MyCollection[data] = nil
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t \""..data.."\" renamed to \""..text..".\"", "SYSTEM");
		UIDropDownMenu_SetText(DiceMasterModelPickerFilter, text)
		Me.ModelPicker_RefreshGrid()
	else
		UIErrorsFrame:AddMessage( "Invalid name.", 1.0, 0.0, 0.0 );
	end
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_DELETECOLLECTION"] = {
  text = "Are you sure you want to delete this model collection?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function (self, data, data2)
	DiceMaster4UF_Saved.MyCollection[data] = nil
	Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t \""..data.."\" deleted.", "SYSTEM");
	UIDropDownMenu_SetText(DiceMasterModelPickerFilter, "Default")
	Me.ModelPicker_FilterChanged( "default" )
	Me.ModelPicker_RefreshGrid()
	DiceMasterModelPickerRenameButton:Disable()
	DiceMasterModelPickerDeleteButton:Disable()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_ADDTOCOLLECTION"] = {
  text = "Enter the displayID for the model:",
  button1 = "Accept",
  button2 = "Cancel",
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText())
	if text~= nil and (text <= Me.unitList) then
		tinsert(DiceMaster4UF_Saved.MyCollection[data], text)
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t "..text.." added to \""..data..".\"", "SYSTEM");
		Me.ModelPicker_RefreshGrid()
	else
		UIErrorsFrame:AddMessage( "Invalid model.", 1.0, 0.0, 0.0 );
	end
  end,
  hasEditBox = true,
  timeout = 0,
  preferredIndex = 3,
}

function Me.ModelPickerDropDown_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText(DiceMasterModelPickerFilter, self:GetText())
	Me.ModelPicker_FilterChanged( arg1 )
	DiceMasterModelPicker.search:SetText("")
	DiceMasterModelPicker.search:ClearFocus()
	if arg2 == "collection" then
		DiceMasterModelPickerRenameButton:Enable()
		DiceMasterModelPickerDeleteButton:Enable()
	else
		DiceMasterModelPickerRenameButton:Disable()
		DiceMasterModelPickerDeleteButton:Disable()
	end
end

function Me.MyCollectionDropDown_OnClick(self, arg1, arg2, checked)
	local model = arg2:GetDisplayInfo()
	if arg1 == "new" then
		StaticPopup_Show("DICEMASTER4_CREATECOLLECTION", nil, nil, model)
	else
		for i=1,#DiceMaster4UF_Saved.MyCollection[arg1] do
			if DiceMaster4UF_Saved.MyCollection[arg1][i]==model then
				return
			end
		end
		tinsert(DiceMaster4UF_Saved.MyCollection[arg1], model)
		Me.ModelPicker_RefreshGrid()
	end
end

function Me.MyCollectionDropDown_Remove(self, arg1, arg2)
	tremove(DiceMaster4UF_Saved.MyCollection[arg1], arg2)
	Me.ModelPicker_RefreshGrid()
end

function Me.ModelPickerDropDown_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()

	 if level == 1 then
	  -- Outermost menu level
	  info.text = "Default"
	  info.arg1 = "default"
	  info.hasArrow = nil
	  info.checked = UIDropDownMenu_GetText(frame) == "Default";
	  info.notCheckable = false;
	  info.func = Me.ModelPickerDropDown_OnClick;
	  UIDropDownMenu_AddButton(info)
	  info.func = nil;
	  info.keepShownOnClick = true;
	  info.notCheckable = true;
	  info.text = "My Models"
	  info.hasArrow = true;
	  info.notCheckable = true;
	  info.menuList = "My Collections"
	  UIDropDownMenu_AddButton(info)
	  
	  info.keepShownOnClick = false;
	  info.notCheckable = false;

	  elseif menuList == "My Collections" then
	  -- Show the "My Collections" sub-menu
		if DiceMaster4UF_Saved and DiceMaster4UF_Saved.MyCollection then
			for k,v in pairs(DiceMaster4UF_Saved.MyCollection) do
			   info.text = k
			   info.arg1 = v
			   info.arg2 = "collection";
			   info.hasArrow = true;
			   info.menuList = k
			   info.checked = UIDropDownMenu_GetText(frame) == k;
			   info.func = Me.ModelPickerDropDown_OnClick;
			   UIDropDownMenu_AddButton(info, level)
			end
		end
	 else
		if DiceMaster4UF_Saved and DiceMaster4UF_Saved.MyCollection then
			for k,v in pairs(DiceMaster4UF_Saved.MyCollection) do
			   if menuList == k then
				   info.text = "|cFF00FF00Add Model..."
				   info.notCheckable = true;
				   info.func = function() StaticPopup_Show("DICEMASTER4_ADDTOCOLLECTION", nil, nil, k) end;
				   UIDropDownMenu_AddButton(info, level)
				end
			end
		end
	end
end

function Me.MyCollectionDropDown_OnLoad(frame, level, menuList)
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
    info.func = Me.MyCollectionDropDown_OnClick;
    UIDropDownMenu_AddButton(info, level)
	
	if DiceMaster4UF_Saved and DiceMaster4UF_Saved.MyCollection then
	  for k,v in pairs(DiceMaster4UF_Saved.MyCollection) do
	   info.text = k;
	   info.arg1 = k;
	   info.arg2 = frame;
	   info.disabled = false;
	   info.notCheckable = true;
	   	for i=1,#v do
			if frame:GetDisplayInfo()==v[i] then
				info.disabled = true;
			end
		end
	   info.func = Me.MyCollectionDropDown_OnClick;
	   UIDropDownMenu_AddButton(info, level)
	  end
	
	info.text = "|cFFffd100Remove From..."
	info.notClickable = true;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info, level)
	if DiceMaster4UF_Saved and DiceMaster4UF_Saved.MyCollection then
		for k,v in pairs(DiceMaster4UF_Saved.MyCollection) do
			for i=1,#v do
				if frame:GetDisplayInfo()==v[i] then
				   info.text = k;
				   info.arg1 = k;
				   info.arg2 = i;
				   info.notClickable = false;
				   info.disabled = false;
				   info.notCheckable = true;
				   info.func = Me.MyCollectionDropDown_Remove;
				   UIDropDownMenu_AddButton(info, level)
				end
			end
		  end
		end
	end
end

-------------------------------------------------------------------------------
-- When one of the model buttons are clicked.
--
function Me.ModelPickerButton_OnClick( self, button )
	-- Apply the model and close the picker. 
	local value = math.floor(self:GetParent().scroller:GetValue())*4 + self.pickerIndex
	if filteredList then
		value = self:GetDisplayInfo()
	else
		value = Me.modelList[value].displayID
	end
	
	if button == "LeftButton" then
		if Me.ModelEditing then
			if Me.ModelEditing == DiceMasterMerchantEditor.merchantPreview then
				SetPortraitTextureFromCreatureDisplayID( Me.ModelEditing, value )
				Me.MerchantEditor_SaveModel( value )
				PlaySound(83)
				
				Me.ModelEditing.checked = value;
				self.check:Show()
				
				Me.ModelEditing.scrollposition = DiceMasterModelPicker.selectorFrame.scroller:GetValue()
				Me.ModelPicker_RefreshGrid()
			elseif Me.ModelEditing == DiceMasterPetModel then
				Me.ModelEditing:SetSpellVisualKit(0);
				Me.ModelEditing:SetModelByCreatureDisplayID( value );
				Me.Profile.pet.model = value;
				Me.RefreshPetFrame()
				PlaySound(83)
				
				Me.ModelEditing.checked = value;
				self.check:Show()
				Me.ModelEditing.scrollposition = DiceMasterModelPicker.selectorFrame.scroller:GetValue()
				Me.ModelPicker_RefreshGrid()
			elseif Me.ModelEditing:GetParent() == DiceMasterLearnPetEditor then
				Me.ModelEditing.ModelScene:GetActorAtIndex(1):SetSpellVisualKit(0);
				Me.ModelEditing.ModelScene:GetActorAtIndex(1):SetModelByCreatureDisplayID( value );
				PlaySound(83)
				
				Me.ModelEditing.checked = value;
				self.check:Show()
				Me.ModelEditing.scrollposition = DiceMasterModelPicker.selectorFrame.scroller:GetValue()
				Me.ModelPicker_RefreshGrid()
			elseif Me.IsLeader( true ) then
				Me.ModelEditing:ClearModel()
				Me.ModelEditing:SetPosition(0,0,0)
				Me.ModelEditing:SetDisplayInfo(value)
				PlaySound(83)
				
				Me.ModelEditing.checked = value;
				self.check:Show()
				
				Me.ModelEditing.scrollposition = DiceMasterModelPicker.selectorFrame.scroller:GetValue()
				Me.ModelPicker_RefreshGrid()
			end
		end
	elseif button == "RightButton" then
		local height = self:GetHeight()
		ToggleDropDownMenu(1, nil, self, "cursor", 0, 0)
		self:SetHeight(height)
	end
end

-------------------------------------------------------------------------------
-- OnEnter handler, to magnify the model and show the texture path.
--
function Me.ModelPickerButton_ShowTooltip( self )
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	
	local value = math.floor(self:GetParent().scroller:GetValue())*4 + self.pickerIndex
	if filteredList then
		value = filteredList[value]
	else
		value = Me.modelList[value]
	end
	if type(value) == "table" then
		GameTooltip:AddLine( "ID: " .. value.displayID, 1, 1, 1, true )
		GameTooltip:AddLine( "Name: " .. value.model, 1, 1, 1, true )
	elseif type(value) == "number" then
		GameTooltip:AddLine( "ID: " .. self:GetDisplayInfo(), 1, 1, 1, true )
	end
    GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- When the mousewheel is used on the model map.
--
function Me.ModelPicker_MouseScroll( delta )

	local a = DiceMasterModelPicker.selectorFrame.scroller:GetValue() - delta
	-- todo: do we need to clamp?
	DiceMasterModelPicker.selectorFrame.scroller:SetValue( a )
end
   
-------------------------------------------------------------------------------
-- When the scrollbar's value is changed.
--
function Me.ModelPicker_ScrollChanged( value )
	
	-- Our "step" is 4 models, which is one line.
	startOffset = math.floor(value) * 4
	Me.ModelPicker_RefreshGrid()
end

-------------------------------------------------------------------------------
-- Set the displayID of the model grid from the models in the list at the
-- current offset.
--
function Me.ModelPicker_RefreshGrid()
	local list = filteredList or Me.modelList
	for k,v in ipairs( DiceMasterModelPicker.icons ) do		
		local tex
		if filteredList and type(list[startOffset + k]) == "number" then 
			tex = list[startOffset + k]
		elseif list[startOffset + k] then
			tex = list[startOffset + k].displayID
		end
		if tex~= nil then
		
			UIDropDownMenu_Initialize( v, DiceMaster4.MyCollectionDropDown_OnLoad )
			
			v:SetHeight(65)
			v:Show()
			v:ClearModel()
			v:SetDisplayInfo(tex)
			
			if Me.ModelEditing.checked == tex then
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
function Me.ModelPicker_FilterChanged( list )
	local filter = DiceMasterModelPicker.search:GetText():lower()
	if list and list~="default" then
		filteredList = list
		Me.ModelPicker_RefreshScroll( true )
		Me.ModelPicker_RefreshGrid()
		return
	end
	if #filter < 3 then
		-- Ignore filters less than three characters
		if filteredList then
			filteredList = nil
			Me.ModelPicker_RefreshScroll( true )
			Me.ModelPicker_RefreshGrid()
		end
	else
		-- build new list
		filteredList = {}
		for i=1,#Me.modelList do
			if strfind( Me.modelList[i].model, filter) or strfind( Me.modelList[i].displayID, filter) then 
				tinsert( filteredList, Me.modelList[i] )
			end
		end
		Me.ModelPicker_RefreshScroll( true )
	end
end

-------------------------------------------------------------------------------
-- When we change the size of the list, update the scroll bar range.
--
-- @param reset Reset the scroll bar to the beginning.
--
function Me.ModelPicker_RefreshScroll( reset, value )
	local list = filteredList or Me.modelList 
	local max = math.floor((#list - 12) / 4)
	if max < 0 then max = 0 end
	DiceMasterModelPicker.selectorFrame.scroller:SetMinMaxValues( 0, max )
	
	if reset then
		DiceMasterModelPicker.selectorFrame.scroller:SetValue( 0 )
	elseif value then
		DiceMasterModelPicker.selectorFrame.scroller:SetValue( math.floor(value) )
	end
	
	Me.ModelPicker_ScrollChanged( DiceMasterModelPicker.selectorFrame.scroller:GetValue() )
end
    
-------------------------------------------------------------------------------
-- Close the model picker window. Use this instead of a direct Hide()
--
function Me.ModelPicker_Close()
	Me.ModelEditing = nil;
	DiceMasterModelPicker:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the model picker window.
--
function Me.ModelPicker_Open( frame, model )
	Me.CloseAllEditors( nil, true, nil )
	DiceMasterModelPicker:ClearAllPoints()
	DiceMasterModelPicker:SetPoint( "LEFT", frame, "RIGHT" )
	Me.ModelEditing = model
	filteredList = nil
	
	if DiceMaster4UF_Saved then
		DiceMaster4UF_Saved.MyCollection = DiceMaster4UF_Saved.MyCollection
	end
	
	UIDropDownMenu_Initialize( DiceMasterModelPickerFilter, DiceMaster4.ModelPickerDropDown_OnLoad )
	UIDropDownMenu_SetText(DiceMasterModelPickerFilter, "Default")
	Me.ModelPicker_FilterChanged( "default" )
	DiceMasterModelPickerRenameButton:Disable()
	DiceMasterModelPickerDeleteButton:Disable()
	UIDropDownMenu_SetWidth(DiceMasterModelPickerFilter, 150, 5)
	
	if Me.ModelEditing.scrollposition then
		Me.ModelPicker_RefreshScroll( nil, Me.ModelEditing.scrollposition )
	elseif DiceMasterModelPicker.scrollposition then
		Me.ModelPicker_RefreshScroll( nil, DiceMasterModelPicker.scrollposition )
	else
		Me.ModelPicker_RefreshScroll( true )
	end
	
	Me.ModelPicker_RefreshScroll( true )
	DiceMasterModelPicker.search:SetText("")
	DiceMasterModelPicker:Show()
end
