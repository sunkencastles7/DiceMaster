-------------------------------------------------------------------------------
-- Dice Master (C) 2022 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Splash Frame interface.
--

local Me = DiceMaster4

local changes = {
	{ "Added a new Skills tab to the Trait Editor, allowing players to create custom skills that represent their proficiency in certain actions.", "5.1.7" },
	{ "Added a new Bank tab to the Trait Editor, allowing players to store custom items from their inventory. Custom items in the Bank tab are accessible across all character profiles as well!", "5.1.7" },
	{ "Added a new Inspect button to the Inventory tab, allowing players to mouse over a custom item and view its actions in the tooltip.", "5.1.7" },
	{ "Added a new Add to Bank button to the Inventory tab, allowing players to deposit custom items into their bank.", "5.1.7" },
	{ "Updated the Inventory tab's button bar and moved it to the top of the frame.", "5.1.7" },
	{ "Added a new Craft button to the Inventory tab, allowing players to craft custom items from the new Crafting Frame using recipes they have learned.", "5.1.7" },
	{ "Added a new 'Learn Recipe' item action, allowing players to create custom recipes. When a player uses an item with this action, the recipe is added to the list on the Crafting Frame.", "5.1.7" },
	{ "Fixed an issue with the DiceMaster4.SendMessage function conflicting with AceEvent integration.", "5.1.7" },
}

DiceMasterChangeLogEntryMixin = {};

function DiceMasterChangeLogEntryMixin:Init(elementData)
	local index = elementData.index;
	local change = changes[index];

	self.change:SetText(change[1]);
	self.version:SetText(change[2]);
	self:SetID(index);
end

function Me.ChangeLog_OnShow()
	local scrollBox = DiceMasterChangeLog.ScrollBox;
	local dataProvider = CreateDataProviderByIndexCount(#changes);
	scrollBox:SetDataProvider(dataProvider);
end

function Me.SplashFrame_OnShow()
	DiceMasterSplashFrame.RightFeature.Title:SetText("Ready for Dragonflight!")
	DiceMasterSplashFrame.RightFeature.Description:SetText("The UI has undergone an art refresh. Customize it while in Edit Mode!")
	
	DiceMasterSplashFrame.TopLeftFeature.Title:SetText("Revamped Skills")
	DiceMasterSplashFrame.TopLeftFeature.Description:SetText("Statistics are now called Skills and come with brand new features!")
	
	DiceMasterSplashFrame.BottomLeftFeature.Title:SetText("Updated Pet Features")
	DiceMasterSplashFrame.BottomLeftFeature.Description:SetText("Pets can take part in new opt-in features using the new 'Learn Pet' item action!")
	SetClampedTextureRotation( DiceMasterSplashFrame.BottomTexture, 270 );
end

function Me.SplashFrame_Close()
	HideUIPanel(DiceMasterSplashFrame);
	PlaySound(SOUNDKIT.IG_MAINMENU_QUIT);
end