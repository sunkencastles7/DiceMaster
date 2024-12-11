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

function Me.MyCollectionDropDown_OnClick(self, arg1, arg2, checked)
	local displayID = arg2:GetDisplayInfo()
	local filePath = arg2.filePath;
	if arg1 == "new" then
		StaticPopup_Show("DICEMASTER4_CREATECOLLECTION", nil, nil, Me.db.global.collections.models)
	else
		for i=1,#Me.db.global.collections.models[arg1] do
			if Me.db.global.collections.models[arg1][i]==displayID then
				return
			end
		end
		local entry = {
			displayID = displayID;
			model = filePath;
		};
		tinsert(Me.db.global.collections.models[arg1], entry)
		Me.ModelPicker_RefreshGrid()
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
	
	if Me.db.global.collections.models then
	  for k,v in pairs(Me.db.global.collections.models) do
	   info.text = k;
	   info.arg1 = k;
	   info.arg2 = frame;
	   info.disabled = false;
	   info.notCheckable = true;
	   	for i=1,#v do
			if frame:GetDisplayInfo()==v[i].displayID then
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
	if Me.db.global.collections.models then
		for k,v in pairs(Me.db.global.collections.models) do
			for i=1,#v do
				if frame:GetDisplayInfo()==v[i].displayID then
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
			elseif DiceMasterUnitManagerUnitEditor and Me.ModelEditing:GetParent() == DiceMasterUnitManagerUnitEditor.RightInset.portrait then
				SetPortraitTextureFromCreatureDisplayID( Me.ModelEditing, value )
			elseif Me.ModelEditing == DiceMasterPetModel then
				Me.ModelEditing:SetSpellVisualKit(0);
				Me.ModelEditing:SetModelByCreatureDisplayID( value );
				Me.Profile.pet.model = value;
			elseif Me.ModelEditing:GetParent() == DiceMasterLearnPetEditor then
				Me.ModelEditing.ModelScene:GetActorAtIndex(1):SetSpellVisualKit(0);
				Me.ModelEditing.ModelScene:GetActorAtIndex(1):SetModelByCreatureDisplayID( value );
			elseif Me.IsLeader( true ) then
				Me.ModelEditing:ClearModel()
				Me.ModelEditing:SetPosition(0,0,0)
				Me.ModelEditing:SetDisplayInfo(value)
			end
			PlaySound(83)
			Me.ModelEditing.checked = value;
			self.check:Show()
			Me.ModelEditing.scrollposition = DiceMasterModelPicker.selectorFrame.scroller:GetValue()
			Me.ModelPicker_RefreshGrid()
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
		value = Me.modelList[filteredList[value]];
	else
		value = Me.modelList[value]
	end
	if type(value) == "table" then
		GameTooltip:AddLine( "|cFFFFD100DisplayID:|r " .. value.displayID, 1, 1, 1, true )
		GameTooltip:AddLine( "|cFFFFD100File Path:|r " .. value.model, 1, 1, 1, true )
		GameTooltip:AddLine( "<Right Click for More Options>", 0.5, 0.5, 0.5, true )
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
		local displayID

		if list[startOffset + k] then
			displayID = list[startOffset + k].displayID;
			filePath = list[startOffset + k].model;
		end
		if displayID~= nil then
		
			UIDropDownMenu_Initialize( v, DiceMaster4.MyCollectionDropDown_OnLoad )
			
			v:SetHeight(104)
			v:Show()
			v:ClearModel()
			v:SetDisplayInfo(displayID)
			v.filePath = filePath;
			
			if Me.ModelEditing.checked == displayID then
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
		filteredList = list;
		DiceMasterModelPicker.search:SetText("");
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

	-- Load the DiceMaster_Resources module needed to access the model list.
	local loaded, reason = C_AddOns.LoadAddOn("DiceMaster_Resources")
	if not loaded then
		if reason == "DISABLED" then
			C_AddOns.EnableAddOn("DiceMaster_Resources", true) -- enable for all characters on the realm
			C_AddOns.LoadAddOn("DiceMaster_Resources")
		else
			local failed_msg = format("%s - %s", reason, _G["ADDON_"..reason])
			error(ADDON_LOAD_FAILED:format("DiceMaster_Resources", failed_msg))
		end
	end
	-- Failsafe
	if not( C_AddOns.IsAddOnLoaded("DiceMaster_Resources")) then return end

	Me.CloseAllEditors( nil, true, nil )
	DiceMasterModelPicker:ClearAllPoints()
	DiceMasterModelPicker:SetPoint( "LEFT", frame, "RIGHT" )
	Me.ModelEditing = model
	filteredList = nil
	
	DiceMasterModelPicker.ActiveCollection = "default";
	
	local checkFunc = function( value )
		return DiceMasterModelPicker.LoadDropdown:GetText() == value;
	end;
	local returnFunc = function( returnValue )
		local collectionName = returnValue;
		local selectedModelCollection;
		if returnValue == "default" then
			DiceMasterModelPicker.LoadDropdown:OverrideText( "Default" );
			selectedModelCollection = returnValue;
		else
			DiceMasterModelPicker.LoadDropdown:OverrideText( returnValue );
			selectedModelCollection = Me.db.global.collections.models[collectionName];

			if not( selectedModelCollection and type(selectedModelCollection)=="table" ) then
				return
			end
		end

		Me.ModelPicker_FilterChanged( selectedModelCollection );
	end

	DiceMasterModelPicker.LoadDropdown:SetCollection("Default", "Models", nil, checkFunc, returnFunc);
	
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
