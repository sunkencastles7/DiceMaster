-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Texture picker interface.
--

local Me = DiceMaster4

local startOffset = 0
local filteredList = nil

-------------------------------------------------------------------------------
-- When one of the icon buttons are clicked.
--
function Me.TexturePickerButton_OnClick( self )
	-- Apply the icon to the edited trait and close the picker. 
	if DiceMasterIconPicker.parent == DiceMasterBuffEditor then
		Me.BuffEditor_SelectIcon( self:GetNormalTexture():GetTexture() )
	elseif DiceMasterIconPicker.parent == Me.editor then
		Me.TraitEditor_SelectIcon( self:GetNormalTexture():GetTexture() )
	elseif DiceMasterIconPicker.parent == DiceMasterPetFrame then
		Me.PetEditor_SelectIcon( self:GetNormalTexture():GetTexture() ) 
	elseif DiceMasterIconPicker.parent == DiceMasterItemEditor then
		Me.ItemEditor_SelectIcon( self:GetNormalTexture():GetTexture() )
	elseif DiceMasterIconPicker.parent == DiceMasterCurrencyEditor then
		Me.CurrencyEditor_SelectIcon( self:GetNormalTexture():GetTexture() )
	elseif DiceMasterIconPicker.parent == DiceMasterDMNotesDMNotes.EditBox then
		Me.TraitEditor_Insert( "<img>"..self:GetNormalTexture():GetTexture().."</img>", DiceMasterIconPicker.parent )
		DiceMasterNotesEditBox_OnTextChanged(DiceMasterIconPicker.parent)
	elseif DiceMasterIconPicker.parent == DiceMasterBookFrame then
		Me.BookEditor_Insert( "<img src=\""..self:GetNormalTexture():GetTexture().."\" width=\"32\" height=\"32\" align=\"right\"/>" )
	elseif DiceMasterIconPicker.parent == DiceMasterTraitEditorInventoryTab then
		Me.TraitEditor_SelectInventoryIcon( self:GetNormalTexture():GetTexture() )
	elseif DiceMasterIconPicker.parent == DiceMasterTraitEditorShopTab then
		Me.ShopFrame_SelectIcon( self:GetNormalTexture():GetTexture() )
	else
		Me.TraitEditor_Insert( "<img>"..self:GetNormalTexture():GetTexture().."</img>" )
		Me.TraitEditor_SaveDescription()
	end
	PlaySound(54129)
	Me.TexturePicker_Close()
end

-------------------------------------------------------------------------------
-- OnEnter handler, to magnify the icon and show the texture path.
--
function Me.TexturePickerButton_ShowTooltip( self )
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	
	local texture = self:GetNormalTexture():GetTexture()
    GameTooltip:AddLine( "|T"..texture..":64|t", 1, 1, 1, true )
    GameTooltip:AddLine( texture, 1, 0.81, 0, true )
    GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- When the mousewheel is used on the icon map.
--
function Me.TexturePicker_MouseScroll( delta )

	local a = DiceMasterTexturePicker.selectorFrame.scroller:GetValue() - delta
	-- todo: do we need to clamp?
	DiceMasterTexturePicker.selectorFrame.scroller:SetValue( a )
end
   
-------------------------------------------------------------------------------
-- When the scrollbar's value is changed.
--
function Me.TexturePicker_ScrollChanged( value )
	
	-- Our "step" is 6 icons, which is one line.
	startOffset = math.floor(value) * 7
	Me.TexturePicker_RefreshGrid()
end

-------------------------------------------------------------------------------
-- Set the textures of the grid from the textures in the list at the
-- current offset.
--
function Me.TexturePicker_RefreshGrid()
	local list = filteredList or Me.textureList
	for k,v in ipairs( DiceMasterTexturePicker.icons ) do
		 
		local tex = list[startOffset + k].id
		if tex then
			v:Show()
			v:SetNormalTexture( tex )
		else
			v:Hide()
		end
	end
end

-------------------------------------------------------------------------------
-- Called when the user types into the search box.
--
function Me.TexturePicker_FilterChanged()
	local filter = DiceMasterTexturePicker.search:GetText():lower()
	if #filter < 3 then
		-- Ignore filters less than three characters
		if filteredList then
			filteredList = nil
			Me.TexturePicker_RefreshScroll()
			Me.TexturePicker_RefreshGrid()
		end
	else
		-- build new list
		filteredList = {}
		for k,v in ipairs( Me.textureList ) do
			local file = v.file
			if file:lower():find( filter ) then
				table.insert( filteredList, v )
			end	
		end
		Me.TexturePicker_RefreshScroll()
	end
end

-------------------------------------------------------------------------------
-- When we change the size of the list, update the scroll bar range.
--
-- @param reset Reset the scroll bar to the beginning.
--
function Me.TexturePicker_RefreshScroll( reset )
	local list = filteredList or Me.textureList 
	local max = math.floor((#list - 42) / 7)
	if max < 0 then max = 0 end
	DiceMasterTexturePicker.selectorFrame.scroller:SetMinMaxValues( 0, max )
	
	if reset then
		DiceMasterTexturePicker.selectorFrame.scroller:SetValue( 0 )
	end
	-- todo: does scroller auto clamp value?
	
	Me.TexturePicker_ScrollChanged( DiceMasterTexturePicker.selectorFrame.scroller:GetValue() )
end
    
-------------------------------------------------------------------------------
-- Close the icon picker window. Use this instead of a direct Hide()
--
function Me.TexturePicker_Close()
	DiceMasterTexturePicker:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the icon picker window.
--
function Me.TexturePicker_Open( parent, noSelect )
	if parent then
		Me.CloseAllEditors( nil, true, true )
		DiceMasterTexturePicker.parent = parent
	else
		Me.CloseAllEditors( nil, true )
		DiceMasterTexturePicker.parent = nil
	end
	filteredList = nil
	
	DiceMasterTexturePicker.CloseButton:SetScript("OnClick",Me.TexturePicker_Close)
	
	Me.TexturePicker_RefreshScroll( true )
	DiceMasterTexturePicker.search:SetText("")
	DiceMasterTexturePicker:Show()
end
