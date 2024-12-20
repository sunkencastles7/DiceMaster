-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Splash Frame interface.
--

local Me = DiceMaster4

local changelog = {
	{ "Patch 11.0.2 support.", "5.2.0" },
	{ "Fixed an issue with some outdated backdrops.", "5.2.0" },
	{ "Added a new 'Edit' button that appears on the bottom corner of the Skills frame when an editable skill is selected.", "5.2.0" },
	{ "Added a new \"My Collections\" system for saving buffs, models, banners, and more!", "5.2.0" },
	{ "Saved buffs using the old system have been automatically migrated.", "5.2.0" },
	{ "Added a new Druid Seed skin for Custom Resource and Progress Bars.", "5.2.0" },
	{ "Re-added the minimap button (oops).", "5.2.0" },
	{ "Revamped the Send Banner feature to allow users to customise up to 10 optional submenu options with a custom title, icon, and description.", "5.2.0" },
	{ "Expanded the Model Picker to included larger model frames.", "5.2.0" },
	{ "Updated Ace libraries.", "5.2.0" },
	{ "The War Within pre-patch support.", "5.1.9" },
	{ "Updated to 11.0.", "5.1.9" }, 
	{ "Added The War Within icons.", "5.1.9" },
	{ "Added an optional 'target' arguement to DiceMaster4.SetHealth(health, target) to affect targeted player instead of player.", "5.1.9" },
	{ "Moved the minimap icon to the new Addon Compartment Frame (just below the calendar icon).", "5.1.9" },
	{ "Dragonflight support.", "5.1.8" },
	{ "Updated to 10.0.", "5.1.8" },
	{ "Added Dragonflight icons.", "5.1.8" },
	{ "Added Dragonflight models to the Model Picker.", "5.1.8" },
	{ "Added a new Splash Frame that displays once upon updating to a new version of the addon to showcase latest features.", "5.1.8" }, 
	{ "Added a /dicemaster changelog command to view a full list of changes in the most recent update.", "5.1.8" },
	{ "Added '/dm' as a valid alias for console commands.", "5.1.8" }, 
	{ "UI frames will now lock/unlock seamlessly with Edit Mode.", "5.1.8" },
	{ "Fixed an issue where re-enabling the addon resets frame positions on the UI.", "5.1.8" }, 
	{ "Upgraded the Dice Panel with a new look for 10.0. The Panel is now condensed into a single button with an expanded radial menu of rolling options pulled from your list of custom skills.", "5.1.8" },
	{ "Updated the config menu with new options and restructured to improve readability.", "5.1.8" },
	{ "Renamed 'DM Manager' to 'Dungeon Manager.'", "5.1.8" }, 
	{ "Revamped Statistics tab. Statistics are now called Skills and have been expanded to support a custom icon and description. Skills can also now inherit the values of several other skills (up for one).", "5.1.8" },
	{ "Revamped Pet tab. Pets can now be further customised with new options including diet, a hunger system that relies on DiceMaster items for food, hygiene, and other interactive features.", "5.1.8" },
	{ "Renamed 'Charges' to 'Resource'.", "5.1.8" },
	{ "Changed the Trait Editor title text to 'Traits' instead of the player's MSP roleplay name.", "5.1.8" },
	{ "Deleted extraneous libraries.", "5.1.8" },
	{ "Updated the Inventory tab with sleeker new buttons.", "5.1.8" },
	{ "Fixed an issue where edited items had their quality reset to Common upon commit.", "5.1.8" },
	{ "Added a new custom item action: Learn Skill. Custom items with this action can be used to learn a new custom-made skill, or further increase your rank in an existing skill.", "5.1.8" },
	{ "Added a new custom item action: Casting Bar. Custom items with this action can be used to display a custom casting bar with additional features.", "5.1.8" },
	{ "Added a new custom item action: Extra Button. Custom items with this action can be used to enable a custom extra button on your UI with additional features.", "5.1.8" },
	{ "Emojis are now available with auto-complete integrated into the native chat frame. You can disable the auto-complete feature in the config menu.", "5.1.8" },
	{ "Added a new button on the chat frame for the Typing Tracker, allowing players to manually toggle on/off their typing status.", "5.1.8" },
	{ "Added an optional mana bar to the Player Frame, allowing players to track their personal mana pool. Other players can view your mana bar from the Inspect Frame, and group leaders can manually manipulate their party members' mana bars. You can also choose from several skin options in the config menu, including Focus, Rage, Energy, and Runic Power.", "5.1.8" },
	{ "Resolved an issue where Icon Picker was returning fileID (numeric) instead of file path (string), resulting in untextured green squares for trait icons.", "5.1.8" },
	{ "Fixed an issue with Book fonts due to new API changes.", "5.1.8" },
	{ "Fixed an issue where editing an officer-approved trait would sometimes reset the description field (League of Lordaeron only).", "5.1.8" },
	{ "Added a new Skills tab to the Trait Editor, allowing players to create custom skills that represent their proficiency in certain actions.", "5.1.7" },
	{ "Added a new Bank tab to the Trait Editor, allowing players to store custom items from their inventory. Custom items in the Bank tab are accessible across all character profiles as well!", "5.1.7" },
	{ "Added a new Inspect button to the Inventory tab, allowing players to mouse over a custom item and view its actions in the tooltip.", "5.1.7" },
	{ "Added a new Add to Bank button to the Inventory tab, allowing players to deposit custom items into their bank.", "5.1.7" },
	{ "Updated the Inventory tab's button bar and moved it to the top of the frame.", "5.1.7" },
	{ "Added a new Craft button to the Inventory tab, allowing players to craft custom items from the new Crafting Frame using recipes they have learned.", "5.1.7" },
	{ "Added a new 'Learn Recipe' item action, allowing players to create custom recipes. When a player uses an item with this action, the recipe is added to the list on the Crafting Frame.", "5.1.7" },
	{ "Fixed an issue with the DiceMaster4.SendMessage function conflicting with AceEvent integration.", "5.1.7" },
};

DiceMasterChangeLogEntryMixin = {};

function DiceMasterChangeLogEntryMixin:Init(elementData)
	local index = elementData.index;
	local change = changelog[index];

	self.change:SetText(change[1]);
	self.version:SetText(change[2]);
	self:SetID(index);
end

function Me.ChangeLog_OnShow()
	local scrollBox = DiceMasterChangeLog.ScrollBox;
	local dataProvider = CreateDataProviderByIndexCount(#changelog);
	scrollBox:SetDataProvider(dataProvider);
end

function Me.SplashFrame_OnShow()
	DiceMasterSplashFrame.RightFeature.Title:SetText("Crafting Items")
	DiceMasterSplashFrame.RightFeature.Description:SetText("You can now design your own Crafting recipes with custom items!")
	
	DiceMasterSplashFrame.TopLeftFeature.Title:SetText("Collections")
	DiceMasterSplashFrame.TopLeftFeature.Description:SetText("You can now save models, buffs, banners, and more in custom loadouts called Collections!")
	
	DiceMasterSplashFrame.BottomLeftFeature.Title:SetText("New Banner Options")
	DiceMasterSplashFrame.BottomLeftFeature.Description:SetText("The Send Banner feature can now be customised with up to 10 submenu options.")
	SetClampedTextureRotation( DiceMasterSplashFrame.BottomTexture, 270 );
end

function Me.SplashFrame_Close()
	HideUIPanel(DiceMasterSplashFrame);
	PlaySound(SOUNDKIT.IG_MAINMENU_QUIT);
end