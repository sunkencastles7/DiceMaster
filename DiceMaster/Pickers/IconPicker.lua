-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Icon picker interface.
--

local Me = DiceMaster4

local startOffset = 0
local filteredList = nil

local function GetIconPath( button )
	if not button or not button.pickerIndex then
		return ""
	end
	
	local list = filteredList or Me.iconList
	local texture = list[ button.pickerIndex + startOffset ]
	
	if texture:find("DiceMaster") then
		texture = "Interface/" .. texture
	else
		texture = "Interface/Icons/" .. texture
	end
	return texture
end

-------------------------------------------------------------------------------
-- When one of the icon buttons are clicked.
--
function Me.IconPickerButton_OnClick( self )
	-- Apply the icon to the edited trait and close the picker. 
	if DiceMasterIconPicker.parent == DiceMasterBuffEditor then
		Me.BuffEditor_SelectIcon( GetIconPath(self) )
	elseif DiceMasterIconPicker.parent == DiceMasterDMBuffEditor then
		Me.DMBuffEditor_SelectIcon( GetIconPath(self) )
	elseif DiceMasterIconPicker.parent == Me.editor then
		Me.TraitEditor_SelectIcon( GetIconPath(self) )
	elseif DiceMasterIconPicker.parent == DiceMasterSkillDetailSkillIconButton then
		Me.SkillFrame_SelectIcon( GetIconPath(self) )
	elseif DiceMasterIconPicker.parent == DiceMasterPetFrame then
		Me.PetEditor_SelectIcon( GetIconPath(self) ) 
	elseif DiceMasterIconPicker.parent == DiceMasterItemEditor then
		Me.ItemEditor_SelectIcon( GetIconPath(self) )
	elseif DiceMasterIconPicker.parent == DiceMasterCurrencyEditor then
		Me.CurrencyEditor_SelectIcon( GetIconPath(self) )
	elseif DiceMasterIconPicker.parent == DiceMasterDMNotesDMNotes.EditBox then
		Me.TraitEditor_Insert( "<img>"..GetIconPath(self).."</img>", DiceMasterIconPicker.parent )
		DiceMasterNotesEditBox_OnTextChanged(DiceMasterIconPicker.parent)
	elseif DiceMasterIconPicker.parent == DiceMasterBookFrame then
		Me.BookEditor_Insert( "{icon:"..GetIconPath(self)..":32}" )
	elseif DiceMasterIconPicker.parent == DiceMasterTraitEditorInventoryTab then
		Me.TraitEditor_SelectInventoryIcon( GetIconPath(self) )
	elseif DiceMasterIconPicker.parent == DiceMasterTraitEditorShopTab then
		Me.ShopFrame_SelectIcon( GetIconPath(self) )
	elseif DiceMasterIconPicker.parent == DiceMasterSkillEditor then
		Me.SkillEditor_SelectIcon( GetIconPath(self) )
	elseif DiceMasterIconPicker.parent:GetName():find("DiceMasterLearnPetEditor") then
		DiceMasterIconPicker.parent:SetTexture( GetIconPath(self) );
	else
		Me.TraitEditor_Insert( "<img>"..GetIconPath(self).."</img>" )
		Me.TraitEditor_SaveDescription()
	end
	PlaySound(54129)
	Me.IconPicker_Close()
end

-------------------------------------------------------------------------------
-- OnEnter handler, to magnify the icon and show the texture path.
--
function Me.IconPickerButton_ShowTooltip( self )
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	local texture = GetIconPath(self)
	
    GameTooltip:AddLine( "|T"..texture..":64|t", 1, 1, 1, true )
    GameTooltip:AddLine( texture, 1, 0.81, 0, true )
    GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- When the mousewheel is used on the icon map.
--
function Me.IconPicker_MouseScroll( delta )

	local a = DiceMasterIconPicker.selectorFrame.scroller:GetValue() - delta
	-- todo: do we need to clamp?
	DiceMasterIconPicker.selectorFrame.scroller:SetValue( a )
end
   
-------------------------------------------------------------------------------
-- When the scrollbar's value is changed.
--
function Me.IconPicker_ScrollChanged( value )
	
	-- Our "step" is 6 icons, which is one line.
	startOffset = math.floor(value) * 7
	Me.IconPicker_RefreshGrid()
end

-------------------------------------------------------------------------------
-- Set the textures of the icon grid from the icons in the list at the
-- current offset.
--
function Me.IconPicker_RefreshGrid()
	local list = filteredList or Me.iconList
	for k,v in ipairs( DiceMasterIconPicker.icons ) do
		local tex = list[startOffset + k]
		if tex then
			v:Show()
			if tex:find( "AddOns/" ) then
				tex = "Interface/" .. tex
			else
				tex = "Interface/Icons/" .. tex
			end
			
			v:SetNormalTexture( tex )
				
		else
			v:Hide()
		end
	end
end

-------------------------------------------------------------------------------
-- Called when the user types into the search box.
--
function Me.IconPicker_FilterChanged()
	local filter = DiceMasterIconPicker.search:GetText():lower()
	if #filter < 3 then
		-- Ignore filters less than three characters
		if filteredList then
			filteredList = nil
			Me.IconPicker_RefreshScroll()
			Me.IconPicker_RefreshGrid()
		end
	else
		-- build new list
		filteredList = {}
		for k,v in ipairs( Me.iconList ) do
			if v:lower():find( filter ) then
				table.insert( filteredList, v )
			end	
		end
		Me.IconPicker_RefreshScroll()
	end
end

-------------------------------------------------------------------------------
-- When we change the size of the list, update the scroll bar range.
--
-- @param reset Reset the scroll bar to the beginning.
--
function Me.IconPicker_RefreshScroll( reset )
	local list = filteredList or Me.iconList 
	local max = math.floor((#list - 42) / 7)
	if max < 0 then max = 0 end
	DiceMasterIconPicker.selectorFrame.scroller:SetMinMaxValues( 0, max )
	
	if reset then
		DiceMasterIconPicker.selectorFrame.scroller:SetValue( 0 )
	end
	-- todo: does scroller auto clamp value?
	
	Me.IconPicker_ScrollChanged( DiceMasterIconPicker.selectorFrame.scroller:GetValue() )
end
    
-------------------------------------------------------------------------------
-- Close the icon picker window. Use this instead of a direct Hide()
--
function Me.IconPicker_Close()

	-- unhighlight the traitIcon button.
	Me.editor.scrollFrame.Container.traitIcon:Select( false )
	DiceMasterBuffEditor.buffIcon:Select( false )
	DiceMasterIconPicker:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the icon picker window.
--
function Me.IconPicker_Open( parent, noSelect )
	if parent then
		Me.CloseAllEditors( nil, true, true )
		DiceMasterIconPicker.parent = parent
		
		if not noSelect then
			if DiceMasterIconPicker.parent == Me.editor then
				DiceMasterIconPicker.parent.scrollFrame.Container.traitIcon:Select( true )
			elseif DiceMasterIconPicker.parent.buffIcon then
				DiceMasterIconPicker.parent.buffIcon:Select( true )
			end
		end
	else
		Me.CloseAllEditors( nil, true )
		DiceMasterIconPicker.parent = nil
	end
	filteredList = nil
	
	DiceMasterIconPicker.CloseButton:SetScript("OnClick",Me.IconPicker_Close)
	
	Me.IconPicker_RefreshScroll( true )
	DiceMasterIconPicker.search:SetText("")
	DiceMasterIconPicker:Show()
end
