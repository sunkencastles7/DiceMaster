-------------------------------------------------------------------------------
-- Dice Master (C) 2024 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------
--

	DiceMaster4.EquipmentSlotItems = {
	{
		name = "High Commander's Favor",
		icon = "Interface/Icons/spell_misc_hellifrepvphonorholdfavor",
		equip = "Whenever you have less than 5 Health, your successful attacks inflict 2 additional damage. Does not stack with critical successes.", 
		flavour = "Let your chaos explode.",
		requirements = function()
			for i = 1, #DiceMaster4.Profile.skills do 
				if DiceMaster4.Profile.skills[i].name == "Constitution" then
					if DiceMaster4.Profile.skills[i].rank < 3 then
						return true
					else
						return false, "Your Constitution is too high to use that item."
					end
				end
			end
			return true
		end,
	},
	{
		name = "Silver Hand Badge",
		icon = "Interface/Icons/inv_shield_1h_silverhand_b_01",
		equip = "Your critical success threshold is expanded to 18-20.", 
		requirements = function()
			for i = 1, #DiceMaster4.Profile.skills do 
				if DiceMaster4.Profile.skills[i].name == "Charisma" or DiceMaster4.Profile.skills[i].name == "Dexterity" or DiceMaster4.Profile.skills[i].name == "Intelligence" or DiceMaster4.Profile.skills[i].name == "Strength" or DiceMaster4.Profile.skills[i].name == "Constitution" or DiceMaster4.Profile.skills[i].name == "Wisdom" then
					if DiceMaster4.Profile.skills[i].rank > 0 then
						return false, "Your " .. DiceMaster4.Profile.skills[i].name .. " is too high to use that item."
					end
				end
			end
			return true
		end,
	},
	{
		name = "Arathi War Banner",
		icon = "Interface/Icons/inv_brd_banner",
		equip = "Whenever you critically strike an opponent, choose one of the following:|n|n|n", 
		requirements = function()
			for i = 1, #DiceMaster4.Profile.skills do 
				if DiceMaster4.Profile.skills[i].name == "Charisma" or DiceMaster4.Profile.skills[i].name == "Dexterity" or DiceMaster4.Profile.skills[i].name == "Intelligence" or DiceMaster4.Profile.skills[i].name == "Strength" or DiceMaster4.Profile.skills[i].name == "Constitution" or DiceMaster4.Profile.skills[i].name == "Wisdom" then
					if DiceMaster4.Profile.skills[i].rank > 0 then
						return false, "Your " .. DiceMaster4.Profile.skills[i].name .. " is too high to use that item."
					end
				end
			end
			return true
		end,
	},
	{
		name = "Grenade Belt of the Battlerager",
		icon = "Interface/Icons/inv_eng_bombfire",
		equip = "Upon reaching 0 Health, you may land a critically successful attack against one enemy within melee range before you go unconscious. This effect can only occur once per event.", 
		requirements = function()
			return true
		end,
	},
	{
		name = "Captain's Scabbard",
		icon = "Interface/Icons/ability_paladin_sheathoflight",
		use = "Consecrate the ground beneath your feet in a 10 yd radius, preventing any creature with an Evil alignment from entering for 3 rounds. If an Evil creature is already standing in the hallowed zone, they suffer 1 damage per turn until they leave it.", 
		requirements = function()
			return true
		end,
	},
	{
		name = "Captain's Scabbard",
		icon = "Interface/Icons/inv_shield_1h_silverhand_b_01",
		equip = "Humanoids and Beasts are more likely to trust you. You also gain an additional 1 Health for every two turns of combat spent in a favored biome of your choosing.",
		use = "Attune with a natural biome of your choosing.",
		requirements = function()
			return true
		end,
	},
	{
		name = "Scarlet Monk's Bandana",
		icon = "Interface/Icons/inv_misc_bandana_03",
		equip = {
			{
				requirements = function()
					if DiceMaster4.Profile.alignment:find("Good") then return true end
				end,
				equip = "Your Insight checks against a race of your choosing have Advantage.",
			},
			{
				requirements = function()
					if DiceMaster4.Profile.alignment:find("Neutral") then return true end
				end,
				equip = "You are immune to non-magical poison.",
			},
			{
				requirements = function()
					if DiceMaster4.Profile.alignment:find("Evil") then return true end
				end,
				use = "All damage you receive this turn is duplicated upon an enemy of your choosing within 60 yd.",
			},

		},
		requirements = function()
			return true
		end,
	},
	{
		name = "Standard Issue Medical Kit",
		icon = "Interface/Icons/inv_shield_1h_silverhand_b_01",
		use = "Heal an ally for 2 Health, or spend a turn <Reviving> them after they have fallen unconscious. (10 Charges)",
		usage = "USE10",
		requirements = function()
			return true
		end,
	},
	{
		name = "Unlucky Loaded Dice",
		icon = "Interface/Icons/inv_misc_dice_01",
		equip = "Whenever you fail three rolls in a row, your next roll is made with <Advantage> at the maximum modifier allowed, and you gain a free re-roll to use before the end of the event.",
		requirements = function()
			return true
		end,
	},
	{
		name = "Potion Belt",
		icon = "Interface/AddOns/DiceMaster/Icons/PotionBelt",
		equip = "At the beginning of every campaign, you receive three of the following:|n|n",
		use = "Craft three potions of your choosing.",
		requirements = function()
			return true
		end,
	},
	{
		name = "Courtland Down Militia Shield",
		icon = "Interface/Icons/inv_shield_76",
		use = "When a nearby ally critically fails a Defence roll, reduce the critical failure to a normal failure, or consume both uses of this ability to negate the damage.",
		usage = "USE2",
		requirements = function()
			return true
		end,
	},
	{
		name = "Deck Full of Jokers",
		icon = "Interface/Icons/inv_shield_1h_silverhand_b_01",
		equip = "You have Advantage on Skill checks when the associated attribute is -3 or lower.",
		requirements = function()
			return true
		end,
	},
	{
		name = "Sack of Mercenary Coins",
		icon = "Interface/Icons/inv_shield_1h_silverhand_b_01",
		equip = "You may use gold from the sack to attempt to bribe or barter with certain other creatures.",
		requirements = function()
			return true
		end,
	},
	{
		name = "Gilnean Infantry Plate Gauntlet",
		icon = "Interface/Icons/inv_shield_1h_silverhand_b_01",
		equip = "You can no longer cast spells or use your mana, but your critically successful attacks bash your enemy for additional damage equal to your Armour.",
		requirements = function()
			return true
		end,
	},
	{
		name = "Fragment of the Huntsman's Crown",
		icon = "Interface/Icons/inv_shield_1h_silverhand_b_01",
		equip = "You can no longer cast spells or use your mana, but your critically successful attacks bash your enemy for additional damage equal to your Armour.",
		use = "Declare a creature as your prey.",
		usage = "USE3",
		requirements = function()
			return true
		end,
	},
	{
		name = "Enchanted Kirin Tor Boots",
		icon = "Interface/Icons/inv_shield_1h_silverhand_b_01",
		equip = "You cannot take fall damage and your footsteps produce no sound. You have Advantage on sound-based Stealth checks.",
		requirements = function()
			return true
		end,
	},
	{
		name = "Bag of Anything",
		icon = "Interface/Icons/inv_shield_1h_silverhand_b_01",
		equip = "You have a magical bag that seemingly always has the correct mundane thing you need in that situation. Examples include grappling hooks, warmer clothing, rations, shovels, etc.",
		use = "Grab whatever you need!",
		requirements = function()
			return true
		end,
	},
	{
		name = "Skeleton Key",
		icon = "Interface/Icons/inv_shield_1h_silverhand_b_01",
		use = "Open any door.",
		requirements = function()
			return true
		end,
	},
}