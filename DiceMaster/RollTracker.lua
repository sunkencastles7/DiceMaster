-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Dungeon Manager interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

-------------------------------------------------------------------------------
local MAJOR, MINOR = "HereBeDragons-Pins-2.0", 16 
local HBD = LibStub("HereBeDragons-2.0")
local HBDPins = LibStub("HereBeDragons-Pins-2.0")

---------------------------------------------------------

if not Me.SavedRolls then
	Me.SavedRolls = {}
end
Me.HistoryRolls = {}

local WORLD_MARKER_NAMES = {
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:14:14|t |cffffff00Gold|r World Marker"; -- [1]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:14:14|t |cffff7f3fOrange|r World Marker"; -- [2]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:14:14|t |cffa335eePurple|r World Marker"; -- [3]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:14:14|t |cff1eff00Green|r World Marker"; -- [4]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:14:14|t |cffaaaaddSilver|r World Marker"; -- [5]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:14:14|t |cff0070ddBlue|r World Marker"; -- [6]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:14:14|t |cffff2020Red|r World Marker"; -- [7]
	"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14:14|t |cffffffffWhite|r World Marker"; -- [8]
}

local MAP_NODE_ICONS = {
	["Eye of the Storm"] = {
		"eots_capPts-leftIcon1-state1",
		"eots_capPts-leftIcon2-state1",
		"eots_capPts-leftIcon2-state2",
		"eots_capPts-leftIcon3-state1",
		"eots_capPts-leftIcon3-state2",
		"eots_capPts-leftIcon4-state1",
		"eots_capPts-leftIcon4-state2",
		"eots_capPts-rightIcon1-state1",
		"eots_capPts-rightIcon2-state1",
		"eots_capPts-rightIcon2-state2",
		"eots_capPts-rightIcon3-state1",
		"eots_capPts-rightIcon3-state2",
		"eots_capPts-rightIcon4-state1",
		"eots_capPts-rightIcon4-state2",
		"eots_capPts-leftIcon5-state1",
		"eots_capPts-leftIcon5-state2",
		"eots_capPts-rightIcon5-state1",
		"eots_capPts-rightIcon5-state2",
		"eots_capPts-neutralIcon1-state1",
		"eots_capPts-neutralIcon2-state1",
		"eots_capPts-neutralIcon3-state1",
		"eots_capPts-neutralIcon4-state1",
	},
	["Arathi Basin"] = {
		"ab_capPts-leftIcon1-state1",
		"ab_capPts-leftIcon1-state2",
		"ab_capPts-leftIcon2-state1",
		"ab_capPts-leftIcon2-state2",
		"ab_capPts-leftIcon3-state1",
		"ab_capPts-leftIcon3-state2",
		"ab_capPts-leftIcon4-state1",
		"ab_capPts-leftIcon4-state2",
		"ab_capPts-leftIcon5-state1",
		"ab_capPts-leftIcon5-state2",
		"ab_capPts-rightIcon1-state1",
		"ab_capPts-rightIcon1-state2",
		"ab_capPts-rightIcon2-state1",
		"ab_capPts-rightIcon2-state2",
		"ab_capPts-rightIcon3-state1",
		"ab_capPts-rightIcon3-state2",
		"ab_capPts-rightIcon4-state1",
		"ab_capPts-rightIcon4-state2",
		"ab_capPts-rightIcon5-state1",
		"ab_capPts-rightIcon5-state2",
	},
	["Battle for Gilneas"] = {
		"bfg_capPts-leftIcon1-state1",
		"bfg_capPts-leftIcon1-state2",
		"bfg_capPts-leftIcon2-state1",
		"bfg_capPts-leftIcon2-state2",
		"bfg_capPts-leftIcon3-state1",
		"bfg_capPts-leftIcon3-state2",
		"bfg_capPts-rightIcon1-state1",
		"bfg_capPts-rightIcon1-state2",
		"bfg_capPts-rightIcon2-state1",
		"bfg_capPts-rightIcon2-state2",
		"bfg_capPts-rightIcon3-state1",
		"bfg_capPts-rightIcon3-state2",
	},
	["Silvershard Mines"] = {
		"sm_carts-leftIcon1-state1",
		"sm_carts-leftIcon2-state1",
		"sm_carts-leftIcon3-state1",
		"sm_carts-rightIcon1-state1",
		"sm_carts-rightIcon2-state1",
		"sm_carts-rightIcon3-state1",
	},
	["Deepwind Gorge"] = {
		"dg_capPts-leftIcon1-state1",
		"dg_capPts-leftIcon2-state1",
		"dg_capPts-leftIcon2-state2",
		"dg_capPts-leftIcon3-state1",
		"dg_capPts-leftIcon3-state2",
		"dg_capPts-leftIcon4-state1",
		"dg_capPts-rightIcon1-state1",
		"dg_capPts-rightIcon2-state1",
		"dg_capPts-rightIcon2-state2",
		"dg_capPts-rightIcon3-state1",
		"dg_capPts-rightIcon3-state2",
		"dg_capPts-rightIcon4-state1",
		"dg_capPts-leftIcon4-state2",
		"dg_capPts-rightIcon4-state2",
		"dg_capPts-neutralIcon1-state1",
		"dg_capPts-neutralIcon2-state1",
		"dg_capPts-neutralIcon3-state1",
		"dg_capPts-leftIcon1-state2",
		"dg_capPts-leftIcon5-state1",
		"dg_capPts-leftIcon5-state2",
		"dg_capPts-rightIcon1-state2",
		"dg_capPts-rightIcon5-state1",
		"dg_capPts-rightIcon5-state2",
	},
	["Temple of Kotmogu"] = {
		"orbs-leftIcon1-state1",
		"orbs-leftIcon2-state1",
		"orbs-leftIcon3-state1",
		"orbs-leftIcon4-state1",
		"orbs-rightIcon1-state1",
		"orbs-rightIcon2-state1",
		"orbs-rightIcon3-state1",
		"orbs-rightIcon4-state1",
	},
	["Tracking"] = {
		"WildBattlePet",
		"StableMaster",
		"ArchBlob",
		"Banker",
		"Focus",
		"BattleMaster",
		"Ammunition",
		"Class",
		"Profession",
		"Target",
		"Food",
		"Reagents",
		"Innkeeper",
		"Auctioneer",
		"Repair",
		"Mailbox",
		"FlightMaster",
		"None",
		"TrivialQuests",
		"Poisons",
		"Barbershop-32x32",
		"ChromieTime-32x32",
		"poi-transmogrifier",
		"WildBattlePet-Tracker",
		"WildBattlePetCapturable",
		"SmallQuestBang",
		"GreenCross",
		"CrossedFlags",
		"CrossedFlagsWithTimer",
		"XMarksTheSpot",
		"Object",
	},
	["Instance"] = {
		"DungeonSkull",
		"Dungeon",
		"Raid",
	},
	["Vignettes"] = {
		"VignetteLoot",
		"VignetteLootElite",
		"VignetteEvent",
		"VignetteEventElite",
		"VignetteKill",
		"VignetteKillElite",
		"vignetteloot-locked",
		"vignettelootelite-locked",
	},
	["Vehicles"] = {
		"Vehicle-Air-Alliance",
		"Vehicle-Air-Horde",
		"Vehicle-Air-Occupied",
		"Vehicle-Air-Unoccupied",
		"Vehicle-AllianceCart",
		"Vehicle-Carriage",
		"Vehicle-Ground-Occupied",
		"Vehicle-Ground-Unoccupied",
		"Vehicle-GrummleConvoy",
		"Vehicle-HammerGold-1",
		"Vehicle-HammerGold-2",
		"Vehicle-HammerGold-3",
		"Vehicle-HammerGold",
		"Vehicle-HordeCart",
		"Vehicle-Mogu",
		"Vehicle-SilvershardMines-Arrow",
		"Vehicle-SilvershardMines-MineCart",
		"Vehicle-SilvershardMines-MineCartBlue",
		"Vehicle-SilvershardMines-MineCartRed",
		"Vehicle-TempleofKotmogu-CyanBall",
		"Vehicle-TempleofKotmogu-GreenBall",
		"Vehicle-TempleofKotmogu-OrangeBall",
		"Vehicle-TempleofKotmogu-PurpleBall",
		"Vehicle-Trap-Gold",
		"Vehicle-Trap-Grey",
		"Vehicle-Trap-Red",
		"map-icon-deathknightclasshall",
	},
	["Warfront Alliance"] = {
		"AllianceWarfrontMapBanner",
		"Warfront-AllianceDot",
		"Warfront-Alliance-SiegeEngine",
		"Warfront-AllianceHero",
		"Warfront-AllianceHero-Gold",
		"Warfront-AllianceHero-Silver",
		"Warfront-AllianceCommander-Muradin",
		"Warfront-AllianceCommander-Trollbane",
		"Warfront-AllianceCommander-Turalyon",
		"Warfront-AllianceWave1",
		"Warfront-AllianceWave2",
		"Warfront-AllianceWave3",
		"Warfronts-BaseMapIcons-Alliance-Armory-Minimap",
		"Warfronts-BaseMapIcons-Alliance-Barracks-Minimap",
		"Warfronts-BaseMapIcons-Alliance-Heroes-Minimap",
		"Warfronts-BaseMapIcons-Alliance-MainHall-Minimap",
		"Warfronts-BaseMapIcons-Alliance-Workshop-Minimap",
		"Warfronts-FieldMapIcons-Alliance-Banner-Minimap",
		"Warfronts-FieldMapIcons-Alliance-LumberMill-Minimap",
		"Warfronts-FieldMapIcons-Alliance-Mine-Minimap",
		"Warfronts-BaseMapIcons-Alliance-ConstructionArmory-Minimap",
		"Warfronts-BaseMapIcons-Alliance-ConstructionBarracks-Minimap",
		"Warfronts-BaseMapIcons-Alliance-ConstructionHeroes-Minimap",
		"Warfronts-BaseMapIcons-Alliance-ConstructionMainHall-Minimap",
		"Warfronts-BaseMapIcons-Alliance-ConstructionWorkshop-Minimap",
	},
	["Warfront Horde"] = {
		"HordeWarfrontMapBanner",
		"Warfront-HordeDot",
		"Warfront-Horde-Demolisher",
		"Warfront-HordeHero",
		"Warfront-HordeHero-Gold",
		"Warfront-HordeHero-Silver",
		"Warfront-HordeCommander-Eitrigg",
		"Warfront-HordeCommander-LadyLiadrin",
		"Warfront-HordeCommander-Rokhan",
		"Warfront-HordeWave1",
		"Warfront-HordeWave2",
		"Warfront-HordeWave3",
		"Warfronts-BaseMapIcons-Horde-Armory-Minimap",
		"Warfronts-BaseMapIcons-Horde-Barracks-Minimap",
		"Warfronts-BaseMapIcons-Horde-Heroes-Minimap",
		"Warfronts-BaseMapIcons-Horde-MainHall-Minimap",
		"Warfronts-BaseMapIcons-Horde-Workshop-Minimap",
		"Warfronts-FieldMapIcons-Horde-Banner-Minimap",
		"Warfronts-FieldMapIcons-Horde-LumberMill-Minimap",
		"Warfronts-FieldMapIcons-Horde-Mine-Minimap",
		"Warfronts-BaseMapIcons-Horde-ConstructionArmory-Minimap",
		"Warfronts-BaseMapIcons-Horde-ConstructionBarracks-Minimap",
		"Warfronts-BaseMapIcons-Horde-ConstructionHeroes-Minimap",
		"Warfronts-BaseMapIcons-Horde-ConstructionMainHall-Minimap",
		"Warfronts-BaseMapIcons-Horde-ConstructionWorkshop-Minimap",
	},
	["Warfront Neutral"] = {
		"Map-MarkedDefeated",
		"Warfront-NeutralHero",
		"Warfront-NeutralHero-Gold",
		"Warfront-NeutralHero-Silver",
		"Warfronts-BaseMapIcons-Empty-Armory-Minimap",
		"Warfronts-BaseMapIcons-Empty-Barracks-Minimap",
		"Warfronts-BaseMapIcons-Empty-Heroes-Minimap",
		"Warfronts-BaseMapIcons-Empty-MainHall-Minimap",
		"Warfronts-BaseMapIcons-Empty-Workshop-Minimap",
		"Warfronts-FieldMapIcons-Empty-Banner-Minimap",
		"Warfronts-FieldMapIcons-Empty-LumberMill-Minimap",
		"Warfronts-FieldMapIcons-Empty-Mine-Minimap",
		"Warfronts-FieldMapIcons-Neutral-Banner-Minimap",
		"Warfronts-FieldMapIcons-Neutral-Mine-Minimap",
		"Warfronts-BaseMapIcons-Alliance-Tower-Minimap",
		"Warfronts-BaseMapIcons-Empty-Tower-Minimap",
		"Warfronts-BaseMapIcons-Horde-Tower-Minimap",
	},
	["Alliance Garrison (Tier 1)"] = {
		"Alliance_Tier1_Barracks",
		"Alliance_Tier1_Professions",
		"Alliance_Tier1_TownHall",
		"Alliance_Tier1_Mine",
		"Alliance_Tier1_Trading1",
		"Alliance_Tier1_Armory1",
		"Alliance_Tier1_Mage1",
		"Alliance_Tier1_Mage2",
		"Alliance_Tier1_Armory2",
		"Alliance_Tier1_Stables1",
		"Alliance_Tier1_Barracks1",
		"Alliance_Tier1_Stables2",
		"Alliance_Tier1_Lumber1",
		"Alliance_Tier1_Barn2",
		"Alliance_Tier1_Professions2",
		"Alliance_Tier1_Inn1",
		"Alliance_Tier1_Farm",
		"Menagery1",
		"Alliance_Tier1_Arena2",
		"Alliance_Tier1_Lumber2",
		"Alliance_Tier1_Trading2",
		"Alliance_Tier1_Fishing",
		"Alliance_Tier1_Barn1",
		"Alliance_Tier1_Inn2",
		"Alliance_Tier1_Arena1",
		"Alliance_Tier1_Barracks2",
		"Alliance_Tier1_Workshop1",
		"Alliance_Tier1_Workshop2",
	},
	["Alliance Garrison (Tier 2)"] = {
		"Alliance_Tier2_Arena1",
		"Alliance_Tier2_Arena2",
		"Alliance_Tier2_Armory1",
		"Alliance_Tier2_Armory2",
		"Alliance_Tier2_Barn1",
		"Alliance_Tier2_Barn2",
		"Alliance_Tier2_Barracks1",
		"Alliance_Tier2_Inn1",
		"Alliance_Tier2_Inn2",
		"Alliance_Tier2_Lumber1",
		"Alliance_Tier2_Lumber2",
		"Alliance_Tier2_Mage1",
		"Alliance_Tier2_Mage2",
		"Alliance_Tier2_Stables1",
		"Alliance_Tier2_Stables2",
		"Alliance_Tier2_Trading1",
		"Alliance_Tier2_Trading2",
		"Alliance_Tier2_Barracks2",
		"Alliance_Tier2_Workshop1",
		"Alliance_Tier2_Workshop2",
	},
	["Alliance Garrison (Tier 3)"] = {
		"Alliance_Tier3_Barn1",
		"Alliance_Tier3_Lumber1",
		"Alliance_Tier3_Mage2",
		"Alliance_Tier3_Inn1",
		"Alliance_Tier3_Barracks1",
		"Alliance_Tier3_Armory2",
		"Alliance_Tier3_Mage1",
		"Alliance_Tier3_Lumber2",
		"Alliance_Tier3_Inn2",
		"Alliance_Tier3_Stables1",
		"Alliance_Tier3_Trading2",
		"Alliance_Tier3_Arena1",
		"Alliance_Tier3_Trading1",
		"Alliance_Tier3_Stables2",
		"Alliance_Tier3_Barn2",
		"Alliance_Tier3_Armory1",
		"Alliance_Tier3_Arena2",
		"Alliance_Tier3_Barracks2",
		"Alliance_Tier3_Workshop1",
		"Alliance_Tier3_Workshop2",
	},
	["Horde Garrison (Tier 1)"] = {
		"Horde_Tier1_Arena1",
		"Horde_Tier1_Arena2",
		"Horde_Tier1_Armory1",
		"Horde_Tier1_Armory2",
		"Horde_Tier1_Barn1",
		"Horde_Tier1_Barn2",
		"Horde_Tier1_Barracks1",
		"Horde_Tier1_Barracks2",
		"Horde_Tier1_Farm1",
		"Horde_Tier1_Fishing1",
		"Horde_Tier1_Inn1",
		"Horde_Tier1_Inn2",
		"Horde_Tier1_Lumber1",
		"Horde_Tier1_Lumber2",
		"Horde_Tier1_Mage1",
		"Horde_Tier1_Mage2",
		"Horde_Tier1_Mine1",
		"Horde_Tier1_Profession1",
		"Horde_Tier1_Profession2",
		"Horde_Tier1_Profession3",
		"Horde_Tier1_Stables1",
		"Horde_Tier1_Stables2",
		"Horde_Tier1_Trading1",
		"Horde_Tier1_Trading2",
		"Horde_Tier1_Workshop1",
		"Horde_Tier1_Workshop2",
	},
	["Horde Garrison (Tier 2)"] = {
		"Horde_Tier2_Arena1",
		"Horde_Tier2_Arena2",
		"Horde_Tier2_Armory1",
		"Horde_Tier2_Armory2",
		"Horde_Tier2_Barn1",
		"Horde_Tier2_Barn2",
		"Horde_Tier2_Barracks1",
		"Horde_Tier2_Barracks2",
		"Horde_Tier2_Inn1",
		"Horde_Tier2_Inn2",
		"Horde_Tier2_Lumber1",
		"Horde_Tier2_Lumber2",
		"Horde_Tier2_Mage1",
		"Horde_Tier2_Mage2",
		"Horde_Tier2_Stables1",
		"Horde_Tier2_Stables2",
		"Horde_Tier2_Trading1",
		"Horde_Tier2_Trading2",
		"Horde_Tier2_Workshop1",
		"Horde_Tier2_Workshop2",
	},
	["Horde Garrison (Tier 3)"] = {
		"Horde_Tier3_Arena1",
		"Horde_Tier3_Arena2",
		"Horde_Tier3_Armory1",
		"Horde_Tier3_Armory2",
		"Horde_Tier3_Barn1",
		"Horde_Tier3_Barn2",
		"Horde_Tier3_Barracks1",
		"Horde_Tier3_Barracks2",
		"Horde_Tier3_Inn1",
		"Horde_Tier3_Inn2",
		"Horde_Tier3_Lumber1",
		"Horde_Tier3_Lumber2",
		"Horde_Tier3_Mage1",
		"Horde_Tier3_Mage2",
		"Horde_Tier3_Stables1",
		"Horde_Tier3_Stables2",
		"Horde_Tier3_Trading1",
		"Horde_Tier3_Trading2",
		"Horde_Tier3_Workshop1",
		"Horde_Tier3_Workshop2",
	},
	["Island Expeditions"] = {
		"Islands-AllianceBoat",
		"Islands-AzeriteBoss",
		"Islands-AzeriteChest",
		"Islands-HordeBoat",
		"Islands-MarkedArea",
		"Islands-QuestBang",
		"Islands-QuestBangDisable",
		"Islands-QuestDisable",
		"Islands-QuestTurnin",
	},
	["Doors"] = {
		"poi-door",
		"poi-door-up",
		"poi-door-down",
		"poi-door-left",
		"poi-door-right",
	},
	["Quests"] = {
		"QuestObjective",
		"QuestNormal",
		"QuestBlob",
		"QuestBonusObjective",
		"QuestDaily",
		"QuestRepeatableTurnin",
		"QuestArtifact",
		"QuestArtifactTurnin",
		"QuestLegendary",
		"QuestLegendaryTurnin",
		"QuestSkull",
		"QuestTurnin",
		"Quest-Campaign-Available",
		"Quest-Campaign-Available-Trivial",
		"Quest-Campaign-TurnIn",
		"Quest-DailyCampaign-Available",
		"Quest-DailyCampaign-TurnIn",
	},
	["Flight Paths"] = {
		"FlightPath",
		"TaxiNode_Alliance",
		"TaxiNode_Horde",
		"TaxiNode_Neutral",
		"TaxiNode_Continent_Alliance",
		"TaxiNode_Continent_Horde",
		"TaxiNode_Continent_Neutral",
		"FlightMasterFerry",
		"FlightMaster_Ferry-TaxiNode_Alliance",
		"FlightMaster_Argus-TaxiNode_Neutral",
		"FlightMasterArgus",
		"flightmaster_ancientwaygate-taxinode_neutral",
	},
	["Portals"] = {
		"PortalRed",
		"PortalBlue",
		"PortalPurple",
		"MagePortalAlliance",
		"MagePortalHorde",
		"WarlockPortalAlliance",
		"WarlockPortalHorde",
	},
	["Legion"] = {
		"AncientMana",
		"LegionfallMapBanner",
		"DemonInvasion1",
		"DemonInvasion2",
		"DemonInvasion3",
		"DemonInvasion4",
		"DemonInvasion5",
		"DemonShip",
		"DemonShip_East",
		"poi-rift1",
		"poi-rift2",
	},
	["Battle for Azeroth"] = {
		"AzeriteReady",
		"AzeriteSpawning",
		"poi-scrapper",
		"poi-islands-table",
		"AllianceAssaultsMapBanner",
		"HordeAssaultsMapBanner",
		"mechagon-projects",
		"MinimapTrident",
		"nazjatar-nagaevent",
		"poi-nzothpylon",
		"poi-nzothvision",
		"Warboard",
		"AllianceSymbol",
		"HordeSymbol",
		"poi-bountyplayer-alliance",
		"poi-bountyplayer-horde",
	},
	["Shadowlands"] = {
		"TorghastDoor-32x32",
		"TorghastDoor-ArrowDown-32x32",
		"TorghastDoor-ArrowLeft-32x32",
		"TorghastDoor-ArrowRight-32x32",
		"TorghastDoor-ArrowUp-32x32",
		"animachannel-icon-kyrian-map",
		"animachannel-icon-necrolord-map",
		"animachannel-icon-nightfae-map",
		"animachannel-icon-venthyr-map",
		"flightmaster_bastion-taxinode_neutral",
		"TeleportationNetwork-32x32",
		"TeleportationNetwork-Ardenweald-32x32",
		"TeleportationNetwork-Maldraxxus-32x32",
		"TeleportationNetwork-Revendreth-32x32",
		"TeleportationNetwork-FlightPathMinimap",
		"SanctumUpgrades-Kyrian-32x32",
		"SanctumUpgrades-Necrolord-32x32",
		"SanctumUpgrades-NightFae-32x32",
		"SanctumUpgrades-Venthyr-32x32",
		"BuildanAbomination-32x32",
		"embercourt-32x32-zhcn",
		"EmberCourt-32x32",
		"PathofAscension-32x32",
		"QueensConservatory-32x32",
		"Soulbind-32x32",
		"animadiversion-icon",
		"Adventures-32x32",
		"GreatVault-32x32",
		"TimewalkingVendor-32x32",
		"UpgradeItem-32x32",
		"KyrianAssaults-64x64",
		"KyrianAssaultsQuest-32x32",
		"NecrolordAssaults-64x64",
		"NecrolordAssaultsQuest-32x32",
		"NightFaeAssaults-64x64",
		"NightFaeAssaultsQuest-32x32",
		"VenthyrAssaults-64x64",
		"VenthyrAssaultsQuest-32x32",
		"Tormentors-Boss",
		"Tormentors-Event",
		"FlightMaster_Progenitor-TaxiNode_Neutral",
		"ProgenitorFlightMaster-32x32",
		"WarlockPortal-Yellow-32x32",
		"CreationCatalyst-32x32",
		"FlightMaster_ProgenitorObelisk-TaxiNode_Neutral",
		"poi-soulspiritghost",
		"poi-torghast",
		"WarMode-Broker-32x32",
	},
	["Dragonflight"] = {
		"MajorFactions_MapIcons_Centaur64",
		"MajorFactions_MapIcons_Expedition64",
		"MajorFactions_MapIcons_Tuskarr64",
		"MajorFactions_MapIcons_Valdrakken64",
		"Professions-Crafting-Orders-Icon",
		"racing",
		"dragonriding-winds",
		"ElementalStorm-Boss-Air",
		"ElementalStorm-Boss-Earth",
		"ElementalStorm-Boss-Fire",
		"ElementalStorm-Boss-Water",
		"ElementalStorm-Lesser-Air",
		"ElementalStorm-Lesser-Earth",
		"ElementalStorm-Lesser-Fire",
		"ElementalStorm-Lesser-Water",
		"greatvault-dragonflight-32x32",
		"dragon-rostrum",
		"minimap-genericevent-hornicon",
		"Fishing-Hole",
	},
	["Ember Court"] = {
		"Embercourt-Guest-AlexandrosMograine",
		"Embercourt-Guest-BaronessVashj",
		"Embercourt-Guest-Choofa",
		"Embercourt-Guest-Countess",
		"Embercourt-Guest-CryptkeeperKassir",
		"Embercourt-Guest-Cudgelface",
		"Embercourt-Guest-DromanAliothe",
		"Embercourt-Guest-GrandmasterVole",
		"Embercourt-Guest-HuntCaptainKorayn",
		"Embercourt-Guest-Kleia",
		"Embercourt-Guest-LadyMoonberry",
		"Embercourt-Guest-Mikanikos",
		"Embercourt-Guest-Pelagos",
		"Embercourt-Guest-PlagueDeviserMarileth",
		"Embercourt-Guest-PolemarchAdrestes",
		"Embercourt-Guest-PrinceRenathal",
		"Embercourt-Guest-Rendle",
		"Embercourt-Guest-Sika",
		"Embercourt-Guest-Stonehead",
	},
}

StaticPopupDialogs["DICEMASTER4_CLEARNOTES"] = {
  text = "Do you want to clear the notes field?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function (self, data)
	if Me.IsLeader() then
		DiceMasterDMNotesDMNotes.EditBox:SetText("")
		DiceMasterDMNotesDMNotes.EditBox:ClearFocus()
	end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_GRANTEXPERIENCE"] = {
  text = "Experience Amount:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText("10")
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText()) or 0
	if text == "" or ( tonumber(text) > 100 ) or text == 0 then
		UIErrorsFrame:AddMessage( "Invalid amount.", 1.0, 0.0, 0.0 );
	else
		local msg = Me:Serialize( "EXP", {
			v = tonumber( text );
		})
		if data and UnitExists( data ) and UnitIsPlayer( data ) and UnitIsConnected( data ) then
			-- Grant a specific player experience.
			Me:SendCommMessage( "DCM4", msg, "WHISPER", data, "ALERT" )
		elseif not data and IsInGroup( LE_PARTY_CATEGORY_HOME ) then
			-- Grant all players experience.
			Me:SendCommMessage( "DCM4", msg, "RAID", nil, "ALERT" )
		else
			UIErrorsFrame:AddMessage( "Player not found.", 1.0, 0.0, 0.0 );
		end
	end
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_GRANTLEVEL"] = {
  text = "Level Amount:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText("1")
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText()) or 0
	if text == "" or ( tonumber(text) > 100 ) or text == 0 then
		UIErrorsFrame:AddMessage( "Invalid amount.", 1.0, 0.0, 0.0 );
	else
		local msg = Me:Serialize( "EXP", {
			l = tonumber( text );
		})
		if data and UnitExists( data ) and UnitIsPlayer( data ) and UnitIsConnected( data ) then
			-- Grant a specific player level(s).
			Me:SendCommMessage( "DCM4", msg, "WHISPER", data, "ALERT" )
		elseif not data and IsInGroup( LE_PARTY_CATEGORY_HOME ) then
			-- Grant all players level(s).
			Me:SendCommMessage( "DCM4", msg, "RAID", nil, "ALERT" )
		else
			UIErrorsFrame:AddMessage( "Player not found.", 1.0, 0.0, 0.0 );
		end
	end
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_LEVELRESETATTEMPT"] = {
  text = "Do you want to reset levels to 1? Players will lose all experience gained so far.|n|nType \"RESET\" into the field to confirm.",
  button1 = "Yes",
  button2 = "No",
  OnShow = function (self, data)
	self.button1:Disable()
	self.button1:SetScript("OnUpdate", function(self)
		if self:GetParent().editBox:GetText() == "RESET" then
			self:Enable()
		else
			self:Disable()
		end
	end)
  end,
  OnAccept = function (self, data)
	self.button1:SetScript("OnUpdate", nil)
    local msg = Me:Serialize( "EXP", {
			r = true;
		})
	if data and UnitExists( data ) and UnitIsPlayer( data ) and UnitIsConnected( data ) then
		-- Reset a specific player's level.
		Me:SendCommMessage( "DCM4", msg, "WHISPER", data, "ALERT" )
	elseif not data and IsInGroup( LE_PARTY_CATEGORY_HOME ) then
		-- Reset all players' level.
		Me:SendCommMessage( "DCM4", msg, "RAID", nil, "ALERT" )
	else
		UIErrorsFrame:AddMessage( "Player not found.", 1.0, 0.0, 0.0 );
	end
  end,
  hasEditBox = true,
  showAlert = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- TUTORIAL STRINGS

local ROLL_TRACKER_TUTORIAL = {
	"Select a World Marker from the dropdown to designate which World Marker you are currently at or focused on.|n|nDungeon Masters may use World Markers to represent NPCs or important locations.",
	"Use the ‘Difficulty Class’ text box to compare each of the rolls listed below against a Difficulty Class (or DC).|n|nAny numeric value entered in the text box will change the colour of each roll to either green (indicating a “success”, or a value greater than the Difficulty Class) or red (indicating a “failure”, or a value lesser than the Difficulty Class).",
	"Player rolls are logged here along with a timestamp and the type of roll attempted (if applicable).|n|nYou can expand a detailed menu complete with a list of all past rolls by left clicking any entry from the list.",
	"Click the 'Clear' button to erase all player rolls from the above list.|n|nDungeon Masters can click the 'Send Banner...' button to send custom banners to their group members in order to make announcements and signal the transition between turns or combat phases.",
}

local NOTES_TUTORIAL = {
	"Dungeon Masters can toggle whether or not raid assistants are allowed to edit the Notes field below.",
	"Dungeon Masters can record public notes here that the rest of their group can see.",
	"The format bar allows the Dungeon Master to insert icons, colours, and more into the Notes field above.",
}

local ROSTER_TUTORIAL = {
	"While in a party or raid, you can view the health, level, and experience of all group members here.|n|nYou can target a group member by clicking on their portrait, or click on their nameplate for more information.",
	"Click the 'Refresh' button to manually update the roster.|n|nYou can use the 'Apply Buff...' button to manually apply custom buffs to yourself or a targeted group member.",
}

local MAP_NODES_TUTORIAL = {
	"Your custom map nodes are logged here, including their icon, title, zone, and a 'View' button that opens the World Map to their location.|n|nSelect any map node from this list to edit or delete it.",
	"Create custom map nodes that are visible on the World Map and Minimap by you and the members of your party or raid.|n|nYou can edit the title, description, and icon of your map nodes here.|n|nYou can also toggle whether or not the map node is visible to the rest of your party or raid.|n|nClick the 'Save' button to save any changes made to the selected map node.",
}

function Me.DiceMasterRollFrame_OnLoad(self)
	self:SetClampedToScreen( true )
	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag( "LeftButton" )
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )
	self:SetScale(0.8)
	self:SetUserPlaced( true )
	
	self.PortraitContainer.portrait:SetTexture( "Interface/AddOns/DiceMaster/Texture/DungeonManagerIcon" )
	self.TitleContainer.TitleText:SetText("Dungeon Manager")
	--self.Inset:SetPoint("TOPLEFT", 4, -80);
	
	for i = 2, 17 do
		local button = CreateFrame("Button", "DiceMasterRollTrackerButton"..i, DiceMasterRollTracker, "DiceMasterRollTrackerButtonTemplate");
		button:SetID(i)
		button:SetPoint("TOP", _G["DiceMasterRollTrackerButton"..(i-1)], "BOTTOM");
	end
	
	for i = 3, 9, 2 do
		local button = CreateFrame("Button", "DiceMasterDMRosterButton"..i, DiceMasterDMRoster, "DiceMasterDMRosterButtonTemplate");
		button:SetID(i)
		button:SetPoint("TOP", _G["DiceMasterDMRosterButton"..(i-2)], "BOTTOM", 0, -2);
	end
	
	for i = 4, 10, 2 do
		local button = CreateFrame("Button", "DiceMasterDMRosterButton"..i, DiceMasterDMRoster, "DiceMasterDMRosterButtonTemplate");
		button:SetID(i)
		button:SetPoint("TOP", _G["DiceMasterDMRosterButton"..(i-2)], "BOTTOM", 0, -2);
	end
	
	for i = 2, 7 do
		local button = CreateFrame("Button", "DiceMasterMapNodesButton"..i, DiceMasterMapNodes, "DiceMasterMapNodesButtonTemplate");
		button:SetID(i)
		button:SetPoint("TOP", _G["DiceMasterMapNodesButton"..(i-1)], "BOTTOM");
	end
	
	Me.DiceMasterRollFrame_Update()
	--Me.UpdateAllMapNodes()
	
	local chat_events = { 
		"WHISPER";
		"PARTY";
		"PARTY_LEADER";
		"RAID";
		"RAID_LEADER";
	}
	
	local f = CreateFrame("Frame")
	for i, event in ipairs(chat_events) do
		f:RegisterEvent( "CHAT_MSG_" .. event )
		f:RegisterEvent( "GROUP_ROSTER_UPDATE" )
		f:RegisterEvent( "UNIT_CONNECTION" )
		f:RegisterEvent( "PARTY_LEADER_CHANGED" )
	end
	f:SetScript( "OnEvent", function( self, event, msg, sender )
		if event:match("CHAT_MSG_") then
			Me.OnChatMessage( msg, sender )
		elseif event == "GROUP_ROSTER_UPDATE" then
			if IsInGroup( LE_PARTY_CATEGORY_HOME ) and not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
				DiceMasterDMNotesAllowAssistants:Hide()
				DiceMasterDMNotesDMNotes.EditBox:Disable()
				if Me.IsLeader() then
					DiceMasterDMNotesAllowAssistants:Show()
					if not DiceMasterDMNotesDMNotes.EditBox.previewShown then
						DiceMasterDMNotesDMNotes.EditBox:Enable()
					end
					Me.RollTracker_ShareNoteWithParty( true )
				end
				for i = 1, GetNumGroupMembers(1) do
					-- Get level and experience data from players.
					local name, rank = GetRaidRosterInfo(i)
					if name then
						Me.Inspect_UpdatePlayer( name )
					end
				end
				Me.DiceMasterRollDetailFrame_Update()
				Me.DMRosterFrame_Update()
			end
			Me.UpdateAllMapNodes();
		elseif event == "UNIT_CONNECTION" or event == "PARTY_LEADER_CHANGED" then
			Me.DiceMasterRollDetailFrame_Update()
			Me.DMRosterFrame_Update()
			Me.RollTracker_ShareMapNodesWithParty()
		end
	end)
	
	if Me.IsLeader() then
		DiceMasterDMNotesAllowAssistants:Show()
		if not DiceMasterDMNotesDMNotes.EditBox.previewShown then
			DiceMasterDMNotesDMNotes.EditBox:Enable()
		end
		Me.RollTracker_ShareNoteWithParty()
	elseif IsInGroup( LE_PARTY_CATEGORY_HOME ) and not Me.IsLeader( false ) and not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		for i = 1, GetNumGroupMembers(1) do
			local name, rank = GetRaidRosterInfo(i)
			if rank == 2 then
				local msg = Me:Serialize( "NOTREQ", {
					me = true;
				})
				Me:SendCommMessage( "DCM4", msg, "WHISPER", name, "NORMAL" )
				local msg = Me:Serialize( "MAPREQ", {
					me = true;
				})
				Me:SendCommMessage( "DCM4", msg, "WHISPER", name, "NORMAL" )
				break
			end
		end
	end
end

function Me.RollTargetDropDown_OnClick(self, arg1)
	if arg1 > 0 then
		UIDropDownMenu_SetText(DiceMasterRollTracker.selectTarget, "|TInterface/TARGETINGFRAME/UI-RaidTargetingIcon_"..arg1..":16|t")
	else
		UIDropDownMenu_SetText(DiceMasterRollTracker.selectTarget, "") 
	end
	
	if IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		return
	end
	
	local msg = Me:Serialize( "TARGET", {
		ta = tonumber( arg1 );
	})
	Me:SendCommMessage( "DCM4", msg, "RAID", nil, "ALERT" )
	
	if not IsInGroup( LE_PARTY_CATEGORY_HOME ) then
		if arg1 > 0 then 
			Me.OnChatMessage( "{rt"..arg1.."}", UnitName("player") ) 
		else
			for i=1,#Me.SavedRolls do
				if Me.SavedRolls[i].name == UnitName("player") then
					Me.SavedRolls[i].target = 0
					Me.DiceMasterRollFrame_Update()
					break
				end
			end
		end
	end
end

function Me.RollTargetDropDown_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	
	info.text = "|cFFffd100Select a Target:"
	info.notClickable = true;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info, level)
	info.notClickable = false;
	info.disabled = false;
	
	for i = 1, 8 do
	   info.text = WORLD_MARKER_NAMES[i];
	   info.arg1 = i;
	   info.notCheckable = true;
	   info.func = Me.RollTargetDropDown_OnClick;
	   UIDropDownMenu_AddButton(info, level)
	end
	
	info.text = "No World Marker";
	info.arg1 = 0;
	info.notCheckable = true;
	info.func = Me.RollTargetDropDown_OnClick;
	UIDropDownMenu_AddButton(info, level)
end

function DiceMasterRollTrackerButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		DiceMasterRollTracker.selected = self.rollIndex
		Me.DiceMasterRollFrame_Update()
		Me.DiceMasterRollFrameDisplayDetail( self.rollIndex )
	end
end

function Me.SortRolls( self, reversed, sortKey, sortType )
	local sort_func = function( a,b )
		if not a then
			a = 0
		end 
		if not b then
			b = 0 
		end
		if sortType == "number" then
			return tonumber( a[sortKey] ) or 0 < tonumber( b[sortKey] ) or 0
		else
			return tostring( a[sortKey] ) < tostring( b[sortKey] )
		end
	end
	if not reversed then
		self.reversed = true
	else
		sort_func = function( a,b ) 
		if not a then
			a = 0 
		end 
		if not b then 
			b = 0 
		end 
		if sortType == "number" then
			return tonumber( a[sortKey] ) > tonumber( b[sortKey] )
		else
			return tostring( a[sortKey] ) > tostring( b[sortKey] )
		end		
	end
		self.reversed = false
	end
	table.sort( Me.SavedRolls, sort_func)
	DiceMasterRollTracker.selected = nil
	
	Me.DiceMasterRollFrame_Update()
end

function Me.SortNodes( self, reversed, sortKey, sortType )
	local sort_func = function( a,b )
		if not a then
			a = 0
		end 
		if not b then
			b = 0 
		end
		if sortType == "number" then
			return tonumber( a[sortKey] ) < tonumber( b[sortKey] )
		else
			return tostring( a[sortKey] ) < tostring( b[sortKey] )
		end
	end
	if not reversed then
		self.reversed = true
	else
		sort_func = function( a,b ) 
		if not a then
			a = 0 
		end 
		if not b then 
			b = 0 
		end 
		if sortType == "number" then
			return tonumber( a[sortKey] ) > tonumber( b[sortKey] )
		else
			return tostring( a[sortKey] ) > tostring( b[sortKey] )
		end		
	end
		self.reversed = false
	end
	table.sort( Me.Profile.mapNodes, sort_func)
	DiceMasterMapNodes.selected = nil
	
	Me.UpdateAllMapNodes();
	Me.DiceMasterMapNodes_Update();
	Me.RollTracker_ShareMapNodesWithParty()
end

function Me.ColourRolls( roll )
	local r, g, b = 1, 1, 1
	local dc = tonumber(DiceMasterRollTrackerDCThreshold:GetText()) or nil
	if not roll or not dc then return r, g, b end
	
	if roll > dc then
		r, g, b = 0, 1, 0
	elseif roll < dc then
		r, g, b = 1, 0, 0
	elseif roll == dc then
		r, g, b = 1, 1, 0
	end
	return r, g, b
end

function Me.Format_TimeStamp( timestamp )
	if not timestamp then return end
	
	local hour = tonumber(timestamp:match("(%d+)%:%d+%:%d+"))
	if hour > 12 then
		timestamp = string.gsub(timestamp, hour, hour-12)
	elseif hour < 1 then
		timestamp = string.gsub(timestamp, "00", 12)
	end
	
	return timestamp
end

function Me.ColourHistoryRolls( roll )
	local r, g, b = 1, 1, 1
	local dc = tonumber(DiceMasterRollTrackerDCThreshold:GetText()) or nil
	if not tonumber(roll) or not dc then return r, g, b end
	
	g = ( roll / dc )
	r = ( dc / roll )
	b = 0
	
	return r, g, b
end

function Me.DiceMasterRollFrame_Update()
	local name, roll, rollType, time, timestamp, target;
	local rollIndex;
	if #Me.SavedRolls > 0 then
		DiceMasterRollTrackerTotals:Hide()
	else
		DiceMasterRollTrackerTotals:Show()
		DiceMasterRollTrackerTotals:SetText("No Recent Rolls")
	end
	
	if DiceMasterRollTracker.selected then
		DiceMasterRollTracker.selectedName = Me.SavedRolls[DiceMasterRollTracker.selected].name;
	end
	
	local rollOffset = FauxScrollFrame_GetOffset(DiceMasterRollTrackerScrollFrame);
	
	for i=1,17,1 do
		rollIndex = rollOffset + i;
		local button = _G["DiceMasterRollTrackerButton"..i];
		button.rollIndex = rollIndex
		local info = Me.SavedRolls[rollIndex];
		if ( info ) then
			name = info.name;
			roll = info.roll;
			rollType = info.rollType;
			time = info.time;
			timestamp = info.timestamp;
			target = info.target;			
		end
		local buttonText = _G["DiceMasterRollTrackerButton"..i.."Name"];
		buttonText:SetText(name)
		if name and UnitClass(name) then
			className, classFile, classID = UnitClass(name)
			buttonText:SetText("|TInterface/Icons/ClassIcon_"..classFile..":16|t "..name)
			buttonText:SetTextColor(RAID_CLASS_COLORS[classFile].r, RAID_CLASS_COLORS[classFile].g, RAID_CLASS_COLORS[classFile].b)
		elseif name and UnitIsPlayer(name) and not UnitIsConnected(name) then
			buttonText:SetTextColor(0.5, 0.5, 0.5)
		else
			-- It's probably a Unit Frame.
			buttonText:SetTextColor( 1, 1, 1 )
		end
		local buttonText = _G["DiceMasterRollTrackerButton"..i.."Roll"];
		buttonText:SetText(roll or "--")
		buttonText:SetTextColor(Me.ColourRolls( roll ))
		local buttonText = _G["DiceMasterRollTrackerButton"..i.."RollType"];
		if rollType == 0 or not rollType then
			buttonText:SetText("--")
		else
			buttonText:SetText(rollType)
		end
		local buttonText = _G["DiceMasterRollTrackerButton"..i.."Timestamp"];
		buttonText:SetText(Me.Format_TimeStamp( timestamp ))
		local buttonText = _G["DiceMasterRollTrackerButton"..i.."Target"];
		if target == 0 or not target then
			buttonText:SetText("")
		else
			buttonText:SetText("|TInterface/TARGETINGFRAME/UI-RaidTargetingIcon_"..target..":16|t")
		end
		
		-- Highlight the correct who
		if ( DiceMasterRollTracker.selected == rollIndex ) then
			button:LockHighlight();
		elseif DiceMasterRollFrame.DetailFrame:IsShown() and DiceMasterRollTracker.selectedName == name then
			button:LockHighlight();
		else
			button:UnlockHighlight();
		end
		
		if ( rollIndex > #Me.SavedRolls ) then
			button:Hide();
		else
			button:Show();
		end
		
	end
	
	FauxScrollFrame_Update(DiceMasterRollTrackerScrollFrame, #Me.SavedRolls, 17, 16, nil, nil, nil, nil, nil, nil, true );
end

function Me.RollTrackerColumn_SetWidth(index, width)
	_G["DiceMasterRollTrackerButton"..index.."Highlight"]:SetWidth(width);
end

function Me.DiceMasterRollDetailFrame_Update()
	local roll, rollType, time, timestamp, dice;
	local rollIndex;
	local frame = DiceMasterRollFrame.DetailFrame
	
	if Me.db.global.trackerAnchor == "RIGHT" then
		frame:ClearAllPoints()
		frame:SetPoint( "TOPLEFT", DiceMasterRollFrame, "TOPRIGHT", -8, -26 )
	else
		frame:ClearAllPoints()
		frame:SetPoint( "TOPRIGHT", DiceMasterRollFrame, "TOPLEFT", 8, -46 )
	end
	
	if ( not frame:IsShown() ) then
		return;
	end
	
	local name = DiceMasterRollTracker.selectedName or nil
	
	local numGroupMembers = GetNumGroupMembers(1)
	local found = false;
	
	local playerName, rank, subgroup, level, class, fileName, zone, online;
	if numGroupMembers > 1 then
		for i = 1, numGroupMembers do
			playerName, rank, subgroup, level, class, fileName, zone, online = GetRaidRosterInfo( i )
			if name == playerName then
				frame.PortraitFrame:SetAttribute( "unit", name )
				frame.PortraitFrame:SetAttribute( "type1", "target" )
				if UnitIsUnit( name, "player" ) then
					SetPortraitTexture( frame.PortraitFrame.Portrait, "player" )
				elseif UnitInRaid( name ) or UnitInParty( name ) then
					SetPortraitTexture( frame.PortraitFrame.Portrait, name )
				end
				found = true;
				break;
			end
		end
	elseif UnitIsUnit( name, "player" ) then
		frame.PortraitFrame:SetAttribute( "unit", name )
		frame.PortraitFrame:SetAttribute( "type1", "target" )
		SetPortraitTexture( frame.PortraitFrame.Portrait, "player" )
		found = true;
	end
	
	if name and UnitIsPlayer( name ) then
		if rank == 2 then
			-- Group Leader Icon
			frame.PortraitFrame.Rank:SetTexture( "Interface/GROUPFRAME/UI-Group-LeaderIcon" )
		elseif rank == 1 then
			-- Group Assist Icon
			frame.PortraitFrame.Rank:SetTexture( "Interface/GROUPFRAME/UI-GROUP-ASSISTANTICON" )
		else
			frame.PortraitFrame.Rank:SetTexture( nil )
		end
		if Me.inspectData[name] then
			local store = Me.inspectData[name]
		
			if not store.experience or not store.level then
				frame.PortraitFrame.Level:SetText( 1 )
				frame.xpBar.rankText:SetText( "XP: 0/100" )
				frame.xpBar:SetValue( 0 )
				return
			end
			
			frame.PortraitFrame.Level:SetText( store.level )
			frame.PortraitFrame.Level:Show()
			frame.PortraitFrame.LevelBG:Show()
			frame.xpBar.rankText:SetText( "XP: " .. store.experience .. "/100" )
			frame.xpBar:SetValue( store.experience )
			
			if not store.health or not store.healthMax then
				frame.healthFrame.healthValue:SetText( "10/10" );
				return
			end
			
			local healthValue, healthMax, armorValue = store.health, store.healthMax, store.armor
			frame.healthFrame.healthValue:SetText( healthValue .. "/" .. healthMax );
			
			if armorValue and armorValue > 0 then
				frame.healthFrame.healthValue:SetText( healthValue.." (+"..armorValue..")/"..healthMax )
			end
		else
			frame.healthFrame.healthValue:SetText( "10/10" );
			frame.PortraitFrame.Level:SetText( 1 )
			frame.xpBar.rankText:SetText( "XP: 0/100" )
			frame.xpBar:SetValue( 0 )
		end
	end
	
	if not online and numGroupMembers > 1 then
		SetDesaturation( frame.PortraitFrame.Portrait, true )
		frame.PortraitFrame.Disconnect:Show()
		frame.Name:SetTextColor(0.5, 0.5, 0.5)
	else
		SetDesaturation( frame.PortraitFrame.Portrait, false )
		frame.PortraitFrame.Disconnect:Hide()
	end
	
	if Me.HistoryRolls[name] and #Me.HistoryRolls[name] > 0 then
		frame.ListInset.Totals:Hide()
	else
		frame.ListInset.Totals:Show()
		frame.ListInset.Totals:SetText("No Recent Rolls")
		for i=1,9,1 do
			local button = _G["DiceMasterRollTrackerHistoryButton"..i];
			button:Hide()
		end
		frame.AverageText:SetText( "--" );
		frame.AverageText:SetTextColor( 1, 1, 1 )
		FauxScrollFrame_Update(DiceMasterRollFrameDetailScrollFrame, 0, 9, 16 );
		return
	end
	
	local rollOffset = FauxScrollFrame_GetOffset(DiceMasterRollFrameDetailScrollFrame);
	
	local showScrollBar = nil;
	if ( #Me.HistoryRolls[name] > 9 ) then
		showScrollBar = 1;
	end
	
	local divider = 0
	local sum = 0
	for i=1,#Me.HistoryRolls[name] do
		divider = divider + 1
		sum = sum + Me.HistoryRolls[name][i].roll
	end
	if sum == 0 then 
		sum = "--"
	else
		sum = math.floor( sum / divider )
	end
	frame.AverageText:SetText(sum);
	frame.AverageText:SetTextColor(Me.ColourHistoryRolls( sum ))
	
	for i=1,9,1 do
		rollIndex = rollOffset + i;
		local button = _G["DiceMasterRollTrackerHistoryButton"..i];
		button.rollIndex = rollIndex
		local info = Me.HistoryRolls[name][rollIndex];
		if ( info ) then
			roll = info.roll;
			rollType = info.rollType;
			time = info.time;
			timestamp = info.timestamp;
			dice = info.dice;			
		end
		local buttonText = _G["DiceMasterRollTrackerHistoryButton"..i.."Roll"];
		buttonText:SetText(roll.." ("..dice..")")
		buttonText:SetTextColor(Me.ColourHistoryRolls( roll ))
		local buttonText = _G["DiceMasterRollTrackerHistoryButton"..i.."Timestamp"];
		buttonText:SetText(Me.Format_TimeStamp( timestamp ))
		local buttonText = _G["DiceMasterRollTrackerHistoryButton"..i.."Type"];
		if rollType == 0 or not rollType then
			buttonText:SetText("--")
		else
			buttonText:SetText(rollType)
		end
		
		-- If need scrollbar resize columns
		if ( showScrollBar ) then
			buttonText:SetWidth(65);
		else
			buttonText:SetWidth(90);
		end
		
		if ( rollIndex > #Me.HistoryRolls[name] ) then
			button:Hide();
		else
			button:Show();
		end
	end
	
	FauxScrollFrame_Update(DiceMasterRollFrameDetailScrollFrame, #Me.HistoryRolls[name], 9, 16 );
end

function Me.DMRosterFrame_OnShow()		
	Me.DMRosterFrame_Update()	
end

function Me.DMRosterButton_OnClick(self, button)
	if ( button == "LeftButton" ) then		
		local name, rank, subgroup, level, class, fileName, zone, online = GetRaidRosterInfo( self.entryIndex )
		
		DiceMasterRollTracker.selected = nil
		for i = 1, #Me.SavedRolls do
			if Me.SavedRolls[i].name == name then
				DiceMasterRollTracker.selected = i;
				break;
			end
		end
		
		DiceMasterRollTracker.selectedName = name;
		Me.DiceMasterRollFrameDisplayDetail( nil, name )
		Me.DMRosterFrame_Update()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	end
end

function Me.DMRosterFrame_Update()
	if ( not DiceMasterDMRoster:IsShown() ) then
		return;
	end
	
	DiceMasterDMRosterInset.Text:Hide()
	
	local name;
	local numGroupMembers = GetNumGroupMembers(1)
	if numGroupMembers < 1 then
		DiceMasterDMRosterInset.Text:Show()
		for i = 1, 10 do
			local button = _G["DiceMasterDMRosterButton"..i];
			button:Hide()
		end
		FauxScrollFrame_Update(DiceMasterDMRosterScrollFrame, numGroupMembers, 10, 16 );
		return
	end
	local entryIndex;
	
	local entryOffset = FauxScrollFrame_GetOffset(DiceMasterDMRosterScrollFrame);
	
	for i=1,10,1 do
		entryIndex = entryOffset + i;
		local button = _G["DiceMasterDMRosterButton"..i];
		button.entryIndex = entryIndex
		local name, rank, subgroup, level, class, fileName, zone, online = GetRaidRosterInfo(entryIndex)
		
		local buttonText = _G["DiceMasterDMRosterButton"..i.."Name"];
		buttonText:SetText(name)
		if name and UnitClass(name) then
			className, classFile, classID = UnitClass(name)
			buttonText:SetTextColor(RAID_CLASS_COLORS[classFile].r, RAID_CLASS_COLORS[classFile].g, RAID_CLASS_COLORS[classFile].b)
			button.Class:SetAtlas( "GarrMission_ClassIcon-" .. classFile )
			button.PortraitFrame:SetAttribute( "unit", name )
			button.PortraitFrame:SetAttribute( "type1", "target" )
			if UnitIsUnit( name, "player" ) then
				SetPortraitTexture( button.PortraitFrame.Portrait, "player" )
			elseif UnitInRaid( name ) or UnitInParty( name ) then
				SetPortraitTexture( button.PortraitFrame.Portrait, name )
			end
			if rank == 2 then
				-- Group Leader Icon
				button.PortraitFrame.Rank:SetTexture( "Interface/GROUPFRAME/UI-Group-LeaderIcon" )
			elseif rank == 1 then
				-- Group Assist Icon
				button.PortraitFrame.Rank:SetTexture( "Interface/GROUPFRAME/UI-GROUP-ASSISTANTICON" )
			else
				button.PortraitFrame.Rank:SetTexture( nil )
			end
		end
		
		if not online then
			SetDesaturation( button.PortraitFrame.Portrait, true )
			button.PortraitFrame.Disconnect:Show()
			buttonText:SetTextColor(0.5, 0.5, 0.5)
		else
			SetDesaturation( button.PortraitFrame.Portrait, false )
			button.PortraitFrame.Disconnect:Hide()
		end
		
		if name and Me.inspectData[name] and online then
			local store = Me.inspectData[name]
			
			if not store.experience or not store.level then
				button.PortraitFrame.Level:SetText( 1 )
				button.XPBar:SetWidth( 0 )
				return
			end
			
			button.PortraitFrame.Level:SetText( store.level )
			button.XPBar:SetWidth( 103 * ( store.experience / 100 ) )
			
			if not store.health or not store.healthMax then
				button.healthFrame.healthValue:SetText( "10/10" );
				button.healthFrame.healthBar:SetMinMaxValues( 0, 10 );
				button.healthFrame.healthBar:SetValue( 10 );
				button.healthFrame.armourBar:SetMinMaxValues( 0, 10 );
				button.healthFrame.armourBar:SetValue( 0 )
				return
			end
			
			local healthValue, healthMax, armorValue = store.health, store.healthMax, store.armor
			button.healthFrame.healthValue:SetText( healthValue .. "/" .. healthMax );
			button.healthFrame.healthBar:SetMinMaxValues( 0, healthMax );
			button.healthFrame.healthBar:SetValue( healthValue );
			
			if armorValue then
				button.healthFrame.armourBar:SetMinMaxValues( 0, healthMax );
				button.healthFrame.armourBar:SetValue( healthValue + armorValue )
			end
		elseif name and not Me.inspectData[name] and online then
			-- Request player data.
			local request_data = {
				ts = {};
				ss = {};
				bs = {};
			}
			
			local msg = Me:Serialize( "INSP", request_data )
			
			Me:SendCommMessage( "DCM4", msg, "WHISPER", name, "ALERT" )
		else
			button.PortraitFrame.Level:SetText( 1 )
			button.XPBar:SetWidth( 0 )
			button.healthFrame.healthValue:SetText( "10/10" );
			button.healthFrame.healthBar:SetMinMaxValues( 0, 10 );
			button.healthFrame.healthBar:SetValue( 10 );
			button.healthFrame.armourBar:SetMinMaxValues( 0, 10 );
			button.healthFrame.armourBar:SetValue( 0 )
		end
		
		if DiceMasterRollTracker.selectedName == name and DiceMasterRollFrame.DetailFrame:IsShown() then
			button.Selected:Show();
		else
			button.Selected:Hide();
		end
		
		if ( entryIndex > numGroupMembers ) then
			button:Hide();
		else
			button:Show();
		end
	end
	
	FauxScrollFrame_Update(DiceMasterDMRosterScrollFrame, numGroupMembers, 10, 16, nil, nil, nil, nil, nil, nil, true);
end

function Me.DiceMasterRollFrameDisplayDetail( rollIndex, name )
	local frame = DiceMasterRollFrame.DetailFrame
	
	if ( rollIndex == nil or Me.SavedRolls[rollIndex] == nil ) and not name then
		frame:Hide()
		return;
	end
	
	if not name then
		name = Me.SavedRolls[rollIndex].name
	end
	
	frame.name = name
	
	frame.Name:SetText(name);
	if name and UnitClass(name) then
		className, classFile, classID = UnitClass(name)
		frame.Name:SetText( name )
		frame.Name:SetTextColor(RAID_CLASS_COLORS[classFile].r, RAID_CLASS_COLORS[classFile].g, RAID_CLASS_COLORS[classFile].b)
		frame.Class:SetAtlas( "GarrMission_ClassIcon-" .. classFile )
		frame.Class:Show()
	elseif name and UnitIsPlayer( name ) and not UnitIsConnected(name) then
		frame.Name:SetTextColor(0.5, 0.5, 0.5)
		frame.Class:Hide()
	else
		-- It's probably a Unit Frame.
		frame.Name:SetTextColor( 1, 1, 1 )
		frame.Class:Hide()
	end
	
	Me.DiceMasterRollDetailFrame_Update()
	frame:Show()
end

local function FormatNoteField( sanitize )
	local TEXT_SUBS = {
		{"{star}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12|t"},
		{"{circle}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:12|t"},
		{"{diamond}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:12|t"},
		{"{triangle}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:12|t"},
		{"{moon}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:12|t"},
		{"{square}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:12|t"},
		{"{x}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:12|t"},
		{"{skull}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12|t"},
		{"<rule>", " |TInterface/Buttons/WHITE8X8:1:335|t"},
		{"<HP>", "|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t"},
		{"<AR>", "|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t"},
		{"%<food%>", "|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:0:24:0:24|t" },
		{"%<wood%>",      "|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:24:48:0:24|t" },
		{"%<iron%>",      "|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:48:72:0:24|t" },
		{"%<leather%>",      "|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:72:96:0:24|t" },
		{ "%<%*%>", "|TInterface/Transmogrify/transmog-tooltip-arrow:8|t" },
	}
	
	local text = DiceMasterDMNotesDMNotes.EditBox:GetText()
	
	if not sanitize then
		for i = 1, #TEXT_SUBS do
			text = gsub( text, TEXT_SUBS[i][1], TEXT_SUBS[i][2] )
		end
		
		-- <img> </img>
		text = gsub( text, "<img>","|T" )
		text = gsub( text, "</img>",":12|t" )
		
		-- <color=rrggbb> </color>
		text = gsub( text, "<color=(.-)>","|cFF%1" )
		text = gsub( text, "</color>","|r" )
	else
		for i = 1, #TEXT_SUBS do
			text = gsub( text, TEXT_SUBS[i][2], TEXT_SUBS[i][1] )
		end
		
		-- <img> </img>
		text = gsub( text, "|T","<img>" )
		text = gsub( text, ":12|t","</img>" )
		
		-- <color=rrggbb> </color>
		text = gsub( text, "|cFF(%w%w%w%w%w%w)","<color=%1>" )
		text = gsub( text, "|r","</color>" )
	end
	
	DiceMasterDMNotesDMNotes.EditBox:SetText( text )
end

function DiceMasterNotesEditBox_OnEditFocusGained(self)
	self.Instructions:Hide()
end

function DiceMasterNotesEditBox_OnEditFocusLost(self)	
	if self:GetText() == "" then
		self.Instructions:Show()
	else
		self.Instructions:Hide()
	end
	
	if Me.IsLeader( true ) then
		Me.RollTracker_ShareNoteWithParty()
	end
end

function DiceMasterNotesEditBox_OnTextChanged(self, userInput)
	local parent = self:GetParent()
	ScrollingEdit_OnTextChanged(self, parent)
	local text = self:GetText()
	if text == "" then
		text = nil
	end
	if not userInput and not self:HasFocus() then
		DiceMasterNotesEditBox_OnEditFocusLost(self)
	end
end

function DiceMasterNotesEditBox_UpdatePreview( sanitize )
	FormatNoteField( sanitize )
	if not sanitize then
		DiceMasterDMNotesDMNotes.EditBox.previewShown = true;
		DiceMasterDMNotesDMNotes.EditBox:Disable()
	else
		DiceMasterDMNotesDMNotes.EditBox.previewShown = false;
		DiceMasterDMNotesDMNotes.EditBox:Enable()
	end
end

function DiceMasterMapNodesButton_OnClick( self, button )
	if ( button == "LeftButton" ) then
		DiceMasterMapNodes.selected = self.nodeIndex
		Me.DiceMasterMapNodes_Update()
	end
end

function Me.DiceMasterMapNodes_Update()
	local name, roll, rollType, time, timestamp, target;
	local nodeIndex;
	if #Me.Profile.mapNodes > 0 then
		DiceMasterMapNodesTotals:Hide()
	else
		DiceMasterMapNodesTotals:Show()
		DiceMasterMapNodesTotals:SetText("No Map Nodes")
		DiceMasterMapNodes.selected = nil
	end
	
	local nodeOffset = FauxScrollFrame_GetOffset(DiceMasterMapNodesScrollFrame);
	
	for i=1,7,1 do
		local title, icon, description, coordX, coordY, mapID, zone, hidden;
		nodeIndex = nodeOffset + i;
		local button = _G["DiceMasterMapNodesButton"..i];
		button.nodeIndex = nodeIndex
		local info = Me.Profile.mapNodes[nodeIndex];
		if ( info ) then
			title 		= info.title;
			icon 		= info.icon;
			description = info.description;
			coordX 		= info.coordX;
			coordY 		= info.coordY;
			mapID 		= info.mapID;
			zone		= info.zone;
			hidden		= info.hidden;
		end
		local buttonText = _G["DiceMasterMapNodesButton"..i.."Icon"];
		if icon and C_Texture.GetAtlasInfo( icon ) then
			buttonText:SetAtlas(icon)
		else
			buttonText:SetTexCoord(0, 1, 0, 1);
			buttonText:SetTexture("Interface/Icons/inv_misc_questionmark");
		end
		local buttonText = _G["DiceMasterMapNodesButton"..i.."Title"];
		buttonText:SetText( title )
		local buttonText = _G["DiceMasterMapNodesButton"..i.."Zone"];
		buttonText:SetText( zone )
		
		-- Highlight the correct who
		if ( DiceMasterMapNodes.selected == nodeIndex ) then
			button:LockHighlight();
		else
			button:UnlockHighlight();
		end
		
		if ( nodeIndex > #Me.Profile.mapNodes ) then
			button:Hide();
		else
			button:Show();
		end		
	end
	
	local frame = DiceMasterMapNodesInset2;
		
	if DiceMasterMapNodes.selected then
		local selectedIcon = Me.Profile.mapNodes[ DiceMasterMapNodes.selected ].icon
		
		UIDropDownMenu_SetSelectedValue( frame.nodeIcon, selectedIcon )
		frame.nodeName:SetText( Me.Profile.mapNodes[ DiceMasterMapNodes.selected ].title );
		frame.nodeDesc.EditBox:SetText( Me.Profile.mapNodes[ DiceMasterMapNodes.selected ].description );
		frame.nodeHidden:SetChecked( Me.Profile.mapNodes[ DiceMasterMapNodes.selected ].hidden );
	else
		UIDropDownMenu_SetSelectedValue( frame.nodeIcon, nil )
		frame.nodeName:SetText( "" );
		frame.nodeDesc.EditBox:SetText( "" );
		frame.nodeHidden:SetChecked(false)
	end
	
	FauxScrollFrame_Update(DiceMasterMapNodesScrollFrame, #Me.Profile.mapNodes, 7, 16, nil, nil, nil, nil, nil, nil, true );
end

function Me.DiceMasterMapNodesDropDown_OnClick( self )
	UIDropDownMenu_SetSelectedValue( DiceMasterMapNodesInset2.nodeIcon, self.value )
end

local function CreateIconMenu( dropdown, level, title )
	local info = UIDropDownMenu_CreateInfo();
	info.text = title;
	info.value = title;
	info.notCheckable = true;
	info.hasArrow = true;
	info.keepShownOnClick = true;
	info.menuList = title;
	UIDropDownMenu_AddButton(info, level);
end

function Me.DiceMasterMapNodesDropDown_OnLoad( frame, level, menuList )
	local info = UIDropDownMenu_CreateInfo()
	
	if level == 1 then
		local tkeys = {}
		for k in pairs( MAP_NODE_ICONS ) do
			table.insert( tkeys, k )
		end
		table.sort( tkeys )
		for _, k in ipairs( tkeys ) do
			CreateIconMenu( frame, level, k );
		end
	elseif level == 2 then
		for i = 1, #MAP_NODE_ICONS[menuList] do
			local info = UIDropDownMenu_CreateInfo()
			local iconName = MAP_NODE_ICONS[menuList][i];
			local iconString = CreateAtlasMarkup( iconName )
			info.value = iconName;
			info.text = iconString .. " " .. MAP_NODE_ICONS[menuList][i];
			info.func = Me.DiceMasterMapNodesDropDown_OnClick;
			info.checked = UIDropDownMenu_GetSelectedValue(DiceMasterMapNodesInset2.nodeIcon) == iconName;
			UIDropDownMenu_AddButton( info, level )
		end
	end
end

-- Delete the map node selected from the list.

function Me.DiceMasterMapNodes_Delete()	
	if not DiceMasterMapNodes.selected then
		return
	end
	
	local icon = Me.Profile.mapNodes[ DiceMasterMapNodes.selected ].icon;
	local title = Me.Profile.mapNodes[ DiceMasterMapNodes.selected ].title;
	if icon and C_Texture.GetAtlasInfo(icon) then
		Me.PrintMessage( CreateAtlasMarkup( icon ) .. " ".. title .." has been deleted.", "SYSTEM");
	else
		Me.PrintMessage( "|TInterface/Icons/inv_misc_questionmark:16|t ".. title .." has been deleted.", "SYSTEM");
	end
	tremove( Me.Profile.mapNodes, DiceMasterMapNodes.selected );
	
	DiceMasterMapNodes.selected = nil
	
	Me.UpdateAllMapNodes();
	Me.DiceMasterMapNodes_Update()
	Me.RollTracker_ShareMapNodesWithParty()
end

-- Create a new map node and add it to the list.

function Me.DiceMasterMapNodes_New()
	local x, y, map = HBD:GetPlayerZonePosition( true );
	local zone = GetZoneText();
	
	local newMapNode = {
		icon = "Object";
		title = "New Map Node";
		description = "";
		coordX = x;
		coordY = y;
		mapID = map;
		zone = zone;
		hidden = false;
	}

	tinsert( Me.Profile.mapNodes, newMapNode );
	
	Me.PrintMessage("|TInterface/MINIMAP/TRACKING/Target:16|t New Map Node has been added to your map.", "SYSTEM");
	
	DiceMasterMapNodes.selected = #Me.Profile.mapNodes
	
	Me.UpdateAllMapNodes();
	Me.DiceMasterMapNodes_Update();
	Me.RollTracker_ShareMapNodesWithParty()
end

-- Save changes made to an existing map node.

function Me.DiceMasterMapNodes_Save()
	if not DiceMasterMapNodes.selected then
		return
	end
	
	local node = Me.Profile.mapNodes[ DiceMasterMapNodes.selected ]
	local frame = DiceMasterMapNodesInset2;
	
	local icon = UIDropDownMenu_GetSelectedValue( DiceMasterMapNodesInset2.nodeIcon )
	
	local title = frame.nodeName:GetText();
	local description = frame.nodeDesc.EditBox:GetText();
	
	local hidden = frame.nodeHidden:GetChecked()
	
	node.icon = icon;
	node.title = title;
	node.description = description;
	node.hidden = hidden;
	
	Me.PrintMessage( CreateAtlasMarkup( icon ) .. " ".. title .." has been saved.", "SYSTEM");
	
	Me.UpdateAllMapNodes();
	Me.DiceMasterMapNodes_Update()
	Me.RollTracker_ShareMapNodesWithParty()
end

function Me.DiceMasterMapNodes_View( self )
	local nodeIndex = self:GetParent().nodeIndex;
	local info = Me.Profile.mapNodes[nodeIndex];
	
	local mapID = info.mapID;
	
	OpenWorldMap( mapID )
end

-------------------------------------------------------------------------------
-- Send a NOTES message to the party.
--
function Me.RollTracker_ShareNoteWithParty()
	if not Me.IsLeader( true ) or not IsInGroup( LE_PARTY_CATEGORY_HOME ) or IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		return
	end
	
	FormatNoteField()
	
	local msg = Me:Serialize( "NOTES", {
		no = DiceMasterDMNotesDMNotes.EditBox:GetText() or "";
		al = DiceMasterDMNotesDMNotes.EditBox:GetJustifyH() or "LEFT";
		ra = DiceMasterDMNotesAllowAssistants:GetChecked();
	})
	
	Me:SendCommMessage( "DCM4", msg, "RAID", nil, "NORMAL" )
end

DiceMasterRollFrameTutorialMixin = {}

function DiceMasterRollFrameTutorialMixin:OnLoad()
	self.helpInfo = {
		FramePos = { x = 0,	y = -20 },
		FrameSize = { width = 338, height = 364	},
	};
end

function DiceMasterRollFrameTutorialMixin:OnHide()
	self:CheckAndHideHelpInfo();
end

function DiceMasterRollFrameTutorialMixin:CheckAndShowTooltip()
	if not HelpPlate:IsShown() then
		HelpPlate_ShowTutorialPrompt(self.helpInfo, self);
	end
end

function DiceMasterRollFrameTutorialMixin:CheckAndHideHelpInfo()
	if HelpPlate:IsShown() then
		HelpPlate_Hide();
		HelpPlate_TooltipHide();
	end
end

function DiceMasterRollFrameTutorialMixin:ToggleHelpInfo()
	local rollFrame = DiceMasterRollFrame;
	for i = 1, #self.helpInfo do
		self.helpInfo[i] = nil;
	end
	if ( DiceMasterRollTracker:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 108,	y = 2 }, HighLightBox = { x = 50, y = -2, width = 98, height = 39 },	ToolTipDir = "DOWN", ToolTipText = ROLL_TRACKER_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 150,	y = 2 }, HighLightBox = { x = 155, y = -2, width = 174, height = 39 },	ToolTipDir = "DOWN", ToolTipText = ROLL_TRACKER_TUTORIAL[2] };
		self.helpInfo[3] = { ButtonPos = { x = 146,	y = -170 }, HighLightBox = { x = 10, y = -66, width = 320, height = 270 },	ToolTipDir = "DOWN", ToolTipText = ROLL_TRACKER_TUTORIAL[3] };
		self.helpInfo[4] = { ButtonPos = { x = 146,	y = -329 }, HighLightBox = { x = 10, y = -340, width = 320, height = 24 },	ToolTipDir = "UP", ToolTipText = ROLL_TRACKER_TUTORIAL[4] };
	elseif ( DiceMasterDMNotes:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 290,	y = 2 }, HighLightBox = { x = 60, y = -2, width = 270, height = 39 },	ToolTipDir = "DOWN", ToolTipText = NOTES_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 146,	y = -150 }, HighLightBox = { x = 10, y = -47, width = 320, height = 276 },	ToolTipDir = "DOWN", ToolTipText = NOTES_TUTORIAL[2] };
		self.helpInfo[3] = { ButtonPos = { x = 146,	y = -324 }, HighLightBox = { x = 10, y = -328, width = 320, height = 39 },	ToolTipDir = "UP", ToolTipText = NOTES_TUTORIAL[3] };
	elseif ( DiceMasterDMRoster:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 146,	y = -150 }, HighLightBox = { x = 10, y = -47, width = 320, height = 289 },	ToolTipDir = "DOWN", ToolTipText = ROSTER_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 146,	y = -329 }, HighLightBox = { x = 10, y = -340, width = 320, height = 24 },	ToolTipDir = "UP", ToolTipText = ROSTER_TUTORIAL[2] };
	elseif ( DiceMasterMapNodes:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 146,	y = -100 }, HighLightBox = { x = 10, y = -66, width = 320, height = 111 },	ToolTipDir = "DOWN", ToolTipText = MAP_NODES_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 146,	y = -230 }, HighLightBox = { x = 10, y = -185, width = 320, height = 152 },	ToolTipDir = "UP", ToolTipText = MAP_NODES_TUTORIAL[2] };
	end

	if ( not HelpPlate:IsShown() and rollFrame:IsShown()) then
		HelpPlate_Show(self.helpInfo, rollFrame, self, true);
	else
		HelpPlate_Hide(true);
	end
end

-------------------------------------------------------------------------------
-- Record a DiceMaster roll.

function Me.OnRollMessage( name, you, count, sides, mod, roll, rollType ) 
	
	if not count or not sides or not mod or not roll then
		return
	end
	
	if you then
		name = UnitName("player")
	end
	
	if not rollType then
		rollType = "--"
	end
	
	local dice = Me.FormatDiceType( count, sides, mod )
	
	if roll and UnitIsPlayer( name ) then
		roll = roll + mod
		if not Me.HistoryRolls[name] then
			Me.HistoryRolls[name] = {}
		end
		local exists = false;
		for i=1,#Me.SavedRolls do
			if Me.SavedRolls[i].name == name then
				Me.SavedRolls[i].roll = tonumber(roll)
				Me.SavedRolls[i].rollType = rollType
				Me.SavedRolls[i].time = date("%H%M%S")
				Me.SavedRolls[i].timestamp = date("%H:%M:%S")
				exists = true;
			end
		end
		
		if not exists then
			local data = {}
			data.roll = tonumber(roll)
			data.rollType = rollType
			data.time = date("%H%M%S")
			data.timestamp = date("%H:%M:%S")
			data.target = 0
			data.name = name
			tinsert(Me.SavedRolls, data)
		end
		
		local data = {}
		data.roll = tonumber(roll)
		data.rollType = rollType
		data.time = date("%H%M%S")
		data.timestamp = date("%H:%M:%S")
		data.dice = dice
		tinsert(Me.HistoryRolls[name], 1, data)
		
		Me.DiceMasterRollFrame_Update()
		
		if DiceMasterRollTracker.selectedName then
			Me.DiceMasterRollDetailFrame_Update()
		end
	end
end

-------------------------------------------------------------------------------
-- Record a vanilla roll.

function Me.OnVanillaRollMessage( name, roll, min, max ) 
	
	if not name or not roll or not min or not max then
		return
	end
	
	local dice = ( min .. "-" .. max )
	
	if roll and UnitIsPlayer( name ) then
		if not Me.HistoryRolls[name] then
			Me.HistoryRolls[name] = {}
		end
		local exists = false;
		for i=1,#Me.SavedRolls do
			if Me.SavedRolls[i].name == name then
				Me.SavedRolls[i].roll = tonumber(roll)
				Me.SavedRolls[i].rollType = "--"
				Me.SavedRolls[i].time = date("%H%M%S")
				Me.SavedRolls[i].timestamp = date("%H:%M:%S")
				exists = true;
			end
		end
		
		if not exists then
			local data = {}
			data.roll = tonumber(roll)
			data.rollType = "--"
			data.time = date("%H%M%S")
			data.timestamp = date("%H:%M:%S")
			data.target = 0
			data.name = name
			tinsert(Me.SavedRolls, data)
		end
		
		local data = {}
		data.roll = tonumber(roll)
		data.rollType = "--"
		data.time = date("%H%M%S")
		data.timestamp = date("%H:%M:%S")
		data.dice = dice
		tinsert(Me.HistoryRolls[name], 1, data)
		
		Me.DiceMasterRollFrame_Update()
		
		if DiceMasterRollTracker.selectedName then
			Me.DiceMasterRollDetailFrame_Update()
		end
	end
end

function Me.OnChatMessage( message, sender ) 
	local icons = {
		{"gold", "star", "rt1"},
		{"orange", "circle", "coin", "rt2"},
		{"purple", "diamond", "rt3"},
		{"green", "triangle", "rt4"},
		{"silver", "moon", "rt5"},
		{"blue", "square", "rt6"},
		{"red", "cross", "x", "rt7"},
		{"white", "skull", "rt8"}
	}
	
	if sender:find("-") then
		-- this is the best xrealm support ur gonna get :)
		sender = sender:match( "(.+)%-")
	end
	
	local found = false
	local icon = message:match("%{(%w+)%}") or 0
	for x=1,#icons do
		for y=1,#icons[x] do
			if icons[x][y] == icon then
				icon = x
				found = true
				break
			end
		end
	end
	
	if icon and found then
		local exists = false;
		for i=1,#Me.SavedRolls do
			if Me.SavedRolls[i].name == sender then
				--Me.SavedRolls[i].time = date("%H%M%S")
				--Me.SavedRolls[i].timestamp = date("%H:%M:%S")
				Me.SavedRolls[i].roll = Me.SavedRolls[i].roll or "--"
				Me.SavedRolls[i].rollType = Me.SavedRolls[i].rollType or "--"
				Me.SavedRolls[i].target = icon
				exists = true;
			end
		end
		
		if not exists then
			local data = {}
			data.name = sender
			data.roll = "--"
			data.rollType = "--"
			data.time = date("%H%M%S")
			data.timestamp = date("%H:%M:%S")
			data.target = icon
			tinsert(Me.SavedRolls, data)
		end
		
		if sender == UnitName("player") then
			UIDropDownMenu_SetText(DiceMasterRollTracker.selectTarget, "|TInterface/TARGETINGFRAME/UI-RaidTargetingIcon_"..icon..":16|t")
		end
	
		Me.DiceMasterRollFrame_Update()
	elseif sender == UnitName("player") then
		UIDropDownMenu_SetText(DiceMasterRollTracker.selectTarget, "") 
	end
end

---------------------------------------------------------------------------
-- Received a NOTES message.
--	no = note							string
--  al = text alignment					string
--  ra = raid assistants allowed		boolean

function Me.RollTracker_OnNoteMessage( data, dist, sender )	

	if sender == UnitName("player") then
		return
	end
 
	-- Only the party leader and raid assistants can send us these.
	if not UnitIsGroupLeader(sender, 1) and not UnitIsGroupAssistant(sender, 1) then 
		return 
	end
	
	-- sanitize message
	if not data.no then
	   
		return
	end
	
	data.no = tostring(data.no)	
	DiceMasterDMNotesDMNotes.EditBox:SetText( data.no )
	
	if data.al then
		data.al = tostring( data.al )
		DiceMasterDMNotesDMNotes.EditBox:SetJustifyH( data.al )
	end
	
	if Me.IsLeader( true ) and data.ra then
		if not DiceMasterDMNotesDMNotes.EditBox.previewShown then
			DiceMasterDMNotesDMNotes.EditBox:Enable()
		end
	else
		DiceMasterDMNotesDMNotes.EditBox:Disable()
	end
	
end


---------------------------------------------------------------------------
-- Received NOTREQ data.
-- 

function Me.RollTracker_OnStatusRequest( data, dist, sender )

	-- Ignore our own data.
	if sender == UnitName( "player" ) or IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then 
		return
	end
 
	if Me.IsLeader( false ) then
		local msg = Me:Serialize( "NOTES", {
			no = DiceMasterDMNotesDMNotes.EditBox:GetText() or "";
			ra = DiceMasterDMNotesAllowAssistants:GetChecked();
		})
		
		Me:SendCommMessage( "DCM4", msg, "RAID", nil, "NORMAL" )
		
		-- Update roll options as well.
		msg = Me:Serialize( "RTYPE", {
			rt = Me.db.char.rollOptions;
		})
		
		Me:SendCommMessage( "DCM4", msg, "RAID", nil, "ALERT" )
	end
end

---------------------------------------------------------------------------
-- Received a target update.
--	ta = target							number

function Me.RollTracker_OnTargetMessage( data, dist, sender )	
 
	-- sanitize message
	if not data.ta then
	   
		return
	end
	
	local icon = tonumber( data.ta )
	
	local exists = false;
	for i=1,#Me.SavedRolls do
		if Me.SavedRolls[i].name == sender then
			--Me.SavedRolls[i].time = date("%H%M%S")
			--Me.SavedRolls[i].timestamp = date("%H:%M:%S")
			Me.SavedRolls[i].roll = Me.SavedRolls[i].roll or "--"
			Me.SavedRolls[i].rollType = Me.SavedRolls[i].rollType or "--"
			Me.SavedRolls[i].target = icon
			exists = true;
		end
	end
	
	if not exists then
		local msg = {}
		msg.name = sender
		msg.roll = "--"
		msg.time = date("%H%M%S")
		msg.timestamp = date("%H:%M:%S")
		msg.rollType = "--"
		msg.target = icon
		tinsert(Me.SavedRolls, msg)
	end
	Me.DiceMasterRollFrame_Update()
end

-------------------------------------------------------------------------------
-- Send a MAPNODES message to the party.
--
function Me.RollTracker_ShareMapNodesWithParty()
	if not Me.IsLeader( false ) or not IsInGroup( LE_PARTY_CATEGORY_HOME ) or IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		return
	end
	
	local mapNodes = {}
	
	if Profile.mapNodes and #Profile.mapNodes > 0 then
	
		for i = 1, #Profile.mapNodes do
			
			if not Profile.mapNodes[i].hidden then
				local data = {
					icon = Profile.mapNodes[i].icon;
					title = Profile.mapNodes[i].title;
					description = Profile.mapNodes[i].description;
					coordX = Profile.mapNodes[i].coordX;
					coordY = Profile.mapNodes[i].coordY;
					mapID = Profile.mapNodes[i].mapID;
					zone = Profile.mapNodes[i].zone;
				}
				
				tinsert( mapNodes, data )
			end
		end
		
	end
	
	local msg = Me:Serialize( "MAPNODES", {
		nodes = mapNodes;
	})
	
	Me:SendCommMessage( "DCM4", msg, "RAID", nil, "NORMAL" )
end

---------------------------------------------------------------------------
-- Received MAPNODES data.
-- 

function Me.RollTracker_OnMapNodesMessage( data, dist, sender )

	-- Ignore our own data.
	if sender == UnitName( "player" ) then return end
	
	-- Only the party leader can send us these.
	if not UnitIsGroupLeader(sender, 1) then 
		return 
	end
	
	-- sanitize message
	if not data.nodes or not type( data.nodes ) == "table" then
	   
		-- cover all those bases . . .
		return 
	end
	
	-- store in database
	Me.inspectData[sender].mapNodes = data.nodes or {}
	
	Me.UpdateAllMapNodes();
end

---------------------------------------------------------------------------
-- Received MAPREQ data.
-- 

function Me.RollTracker_OnMapNodesRequest( data, dist, sender )

	-- Ignore our own data.
	if sender == UnitName( "player" ) or IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then 
		return
	end
 
	if Me.IsLeader( false ) then
		local mapNodes = {}
		
		if Profile.mapNodes and #Profile.mapNodes > 0 then
		
			for i = 1, #Profile.mapNodes do
				
				if not Profile.mapNodes[i].hidden then
					local data = {
						icon = Profile.mapNodes[i].icon;
						title = Profile.mapNodes[i].title;
						description = Profile.mapNodes[i].description;
						coordX = Profile.mapNodes[i].coordX;
						coordY = Profile.mapNodes[i].coordY;
						mapID = Profile.mapNodes[i].mapID;
						zone = Profile.mapNodes[i].zone;
					}
					
					tinsert( mapNodes, data )
				end
			end
			
		end
		
		local msg = Me:Serialize( "MAPNODES", {
			nodes = mapNodes;
		})
		
		Me:SendCommMessage( "DCM4", msg, "WHISPER", sender, "NORMAL" )
	end
end