-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Merchant Editing Panel
--

local Me      = DiceMaster4
local Profile = Me.Profile


function Me.MerchantEditor_SaveName()
	local name = DiceMasterMerchantEditor.merchantName:GetText()
	if name == nil or name == "" then
		UIErrorsFrame:AddMessage( "Invalid name: too short.", 1.0, 0.0, 0.0 );
		return
	end
	
	Me.Profile.shopName = name;
	Me.ShopFrame_Update()
	Me.TraitEditor_OnTabChanged()
end

function Me.MerchantEditor_SaveModel( displayID )
	if not( displayID ) then
		return
	end
	
	if type( displayID ) == "number" then
		Me.Profile.shopModel = displayID;
	else
		Me.Profile.shopModel = nil;
	end
	Me.ShopFrame_Update()
	Me.TraitEditor_OnTabChanged()
end

function Me.MerchantEditor_UseIcon()
	Me.Profile.shopModel = nil;
	Me.ShopFrame_Update()
	Me.TraitEditor_OnTabChanged()
end

function Me.MerchantEditor_Refresh()
	local editor = DiceMasterMerchantEditor
	
	if Me.Profile.shopModel then
		SetPortraitTextureFromCreatureDisplayID( editor.merchantPreview, Me.Profile.shopModel )
	else
		SetPortraitToTexture( editor.merchantPreview, Me.Profile.shopIcon )
	end
	
	editor.merchantName:SetText( Me.Profile.shopName or "Shop" )
end

-------------------------------------------------------------------------------
-- Close the Merchant editor window. Use this instead of a direct Hide()
--
function Me.MerchantEditor_Close()
	Me.MerchantEditor_Refresh()
	DiceMasterMerchantEditor:Hide()
	ResetCursor();
	Me.TraitEditor_OnTabChanged()
end
    
-------------------------------------------------------------------------------
-- Open the Merchant editor window.
--
function Me.MerchantEditor_Open( frame )
	Me.CloseAllEditors()
	DiceMasterMerchantEditor:ClearAllPoints()
	DiceMasterMerchantEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	Me.MerchantEditor_Refresh()
	
	DiceMasterMerchantEditor:Show()
end