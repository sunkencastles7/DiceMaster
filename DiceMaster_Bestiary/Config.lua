-------------------------------------------------------------------------------
-- Dice Master (C) 2024 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4_Bestiary

local AceConfig       = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local SharedMedia     = LibStub("LibSharedMedia-3.0")

local VERSION = 1

-------------------------------------------------------------------------------
local DB_DEFAULTS = {
	
	global = {
		version     = nil;
	};
	
	profile = {
		units = {
			{
				modelID = 82702;
				name = "Witch";
				description = "The Witches who flock to Horned God’s patronage are often the victims of persecution, and the Witch Hunts which have historically run rampant throughout Drustvar. Some are naturally born with their dark gifts, while others are initiated to Maleficium (or “dark magic”) by voluntarily selling their souls to the Dark Lord himself. Their reasons are not always motivated by self-interest - indeed, some feel desperately compelled to join the Horned God’s cult out of fear of persecution for their inborn powers. Many more submit themselves willingly to their dark practice, greedy for power, influence, and life everlasting. Whatever their reasons, a Witch’s soul is known to become darker, more ruthless, and cunning over time.|n|nCast out by society, they form tightly-knit sisterhoods known as Hives (or Covens) - both because a Witch knows she depends upon her sisters to ensure her own survival, and also to share their power collectively. Despite how they may choose to appear to their prey, a Witch is never truly alone, and they are known to seclude themselves in vast, underground strongholds in the subsoil of the dark woods of Drustvar.";
				raidMarker = 3;
				isVisible = true;
				health = 4;
				maxHealth = 10;
				armour = 3;
				quantity = 1;
				statistics = {
					{ name = "Alignment", value = "Neutral Evil", tooltip = "A general measure of the creature's moral and personal attitudes." };
					{ name = "Classification", value = "Monstrous Humanoid", tooltip = "The category of monster that the creature belongs to for abilities that affect a certain monster type." };
					{ name = "Health", value = "7<HP>", tooltip = "The amount of base health points the creature has in combat." };
					{ name = "Armour", value = "0<AR>", tooltip = "The amount of base armour the creature has in combat." };
					{ name = "Attack Type", value = "Spell", tooltip = "The type of attack used for the creature’s basic attacks." };
					{ name = "Attack Damage", value = "3", tooltip = "The amount of damage caused by the creature’s basic attacks." };
					{ name = "Maximum Damage", value = "4", tooltip = "The maximum amount of damage the creature is able to inflict using any of its abilities. This is also the amount of damage dealt by its critically successful attacks." };
					{ name = "Armour Type", value = "Unarmoured", tooltip = "The type of armour worn by the creature." };
					{ name = "Difficulty Class", value = "12", tooltip = "The number you must score on your roll against the creature in order to succeed." };
					{ name = "Speed", value = "Moderate", tooltip = "The approximate movement speed of the creature." };
					{ name = "Size", value = "Medium", tooltip = "The approximate scale of the creature in comparison to the average human." };
					{ name = "Difficulty", value = "Moderate", tooltip = "A rough estimate of how challenging or deadly the creature is when faced in combat." };
				};
				traits = {
					{
						name = "Bewitch";
						icon = "Interface/AddOns/DiceMaster/Icons/diablo3_smokescreen";
						uses = "1 Use";
						description = "The Witch enthralls a chosen target, forcing them to fight for her for three turns, or until they roll a successful Will Save.|n|n|cFFFF0000If the Witch perishes, this effect is broken instantly.|r";
					};
					{
						name = "Witchflight";
						icon = "Interface/AddOns/DiceMaster/Icons/diablo3_companion";
						uses = "1 Use";
						description = "The Witch disperses into a flock of ravens, attempting to flee. Only a successful Grapple roll can prevent her from escaping, Stunning her for one turn.";
					};
					{
						name = "Crone's Mark";
						icon = "Interface/AddOns/DiceMaster/Icons/diablo3_markedfordeath";
						uses = "1 Use";
						description = "The Witch marks a chosen target with an omen of doom. Their very next Defence, Spell Defence, or Fortitude Save roll must be made with Disadvantage.|n|nThis effect persists until it has been triggered.";
					};
				};
			},
		};
	} 
}

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
Me.configOptions = {
	type  = "group";
	order = 1;
	args = { 
		-----------------------------------------------------------------------
		header = {
			order = 0;
			name  = "Configure the core settings for DiceMaster Bestiary.";
			type  = "description";
		};
 
		uiScale = {
			order     = 4;
			name      = "UI Scale";
			desc      = "Change the size of the Dice Panel, Health and Resource bars, Target, and Progress Bar frames.";
			type      = "range";
			min       = 0.25;
			max       = 10;
			softMax   = 4;
			isPercent = true;
			set = function( info, val ) 
				Me.db.char.uiScale = val;
			end;
			width = "double";
			get = function( info ) return Me.db.char.uiScale end;
		};
		
		showUses = {
			order = 5;
			name  = "Show Remaining Uses on Dice Panel";
			desc  = "Show the number of remaining uses for traits on the Dice Panel.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.showUses = val
				Me.configOptions.args.resetUses.hidden = not val
			end;
			get = function( info ) return Me.db.global.showUses end;
		};
	};
}

-------------------------------------------------------------------------------
function Me.SetupDB()
	
	local acedb = LibStub( "AceDB-3.0" )
  
	Me.db = acedb:New( "DiceMaster4_Bestiary", DB_DEFAULTS )
	
	Me.db.RegisterCallback( Me, "OnProfileChanged", "ApplyConfig" )
	Me.db.RegisterCallback( Me, "OnProfileCopied",  "ApplyConfig" )
	Me.db.RegisterCallback( Me, "OnProfileReset",   "ApplyConfig" )
	 
	local options = Me.configOptions
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable( Me.db )
	profiles.order = 500
	 
	AceConfig:RegisterOptionsTable( "DiceMaster Bestiary", options )	
	AceConfig:RegisterOptionsTable( "DiceMaster Bestiary Profiles", profiles )
	
	Me.config = AceConfigDialog:AddToBlizOptions( "DiceMaster Bestiary", "DiceMaster Bestiary" )
	Me.configProfiles = AceConfigDialog:AddToBlizOptions( "DiceMaster Bestiary Profiles", "Profiles", "DiceMaster Bestiary" )
	
	local function CreateLogo( frame )
		local logo = CreateFrame('Frame', nil, frame, BackdropTemplateMixin and "BackdropTemplate")
		logo:SetFrameLevel(4)
		logo:SetSize(64, 64)
		logo:SetPoint('TOPRIGHT', 8, 24)
		logo:SetBackdrop({bgFile = "Interface/AddOns/DiceMaster/Texture/logo"})
		frame.logo = logo
	end
	
	CreateLogo( Me.config )
	CreateLogo( Me.configProfiles )
end

local interfaceOptionsNeedsInit = true
-------------------------------------------------------------------------------
-- Open the configuration panel.
--
function Me.OpenConfig() 
	-- the first time we open the options frame, it wont go to the right page
	if interfaceOptionsNeedsInit then
		Settings.OpenToCategory( "DiceMaster Bestiary" )
		interfaceOptionsNeedsInit = nil
	end
	Settings.OpenToCategory( "DiceMaster Bestiary" )
	LibStub("AceConfigRegistry-3.0"):NotifyChange( "DiceMaster Bestiary" )
end

-------------------------------------------------------------------------------
function Me.ApplyConfig( onload )
	--
end
