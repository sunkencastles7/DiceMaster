-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------
--
-- The spell list data structure:
-------------------------------------------------------------------------------
-- name					string			Name of the spell.
-- icon					string			File path of the spell icon.
-- description			string			Spell description.
-- level				string			Spell level.
-- school				string			School classification.
-- castTime				number			
-- range				string/number	Maximum spell range (in yards), or "Melee" (optional).
-- duration				string/number	Duration of the spell, in seconds or "turns."
-- damage				number*			Damage (*or range of damage) dealt.
-- damageType			string			Damage type (see below).
-- dice					string			Dice used to cast the spell (in d20 format).
-- savingThrow			string			
-- requiresConc			boolean			Requires concentration to cast.
-- attackRoll			boolean			Is an attack roll (?)

DiceMaster4.DamageTypes = {
	["Acid"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/acid";
		hex = "FF80b000";
	},
	["Bludgeoning"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/bludgeoning";
		hex = "FF8c8c8c";
	},
	["Cold"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/cold";
		hex = "FF3399cc";
	},
	["Fire"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/fire";
		hex = "FFee5500";
	},
	["Force"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/force";
		hex = "FFcc3333";
	},
	["Lightning"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/lightning";
		hex = "FF3366cc";
	},
	["Necrotic"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/necrotic";
		hex = "FF40b050";
	},
	["Piercing"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/piercing";
		hex = "FF8c8c8c";
	},
	["Poison"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/poison";
		hex = "FF44bb00";
	},
	["Psychic"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/psychic";
		hex = "FFcc77aa";
	},
	["Radiant"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/radiant";
		hex = "FFccaa00";
	},
	["Slashing"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/slashing";
		hex = "FF8c8c8c";
	},
	["Thunder"] = {
		icon = "Interface/AddOns/DiceMaster/Texture/Damage/thunder";
		hex = "FF8844bb";
	}
}

DiceMaster4.SpellList = {
	["Player's Handbook"] = {
		{
			name = "Acid Splash";
			icon = "Interface/Icons/ability_creature_poison_06";
			description = "Throw a bubble of acid that damages each creature it hits.";
			level = "Cantrip";
			school = "Conjuration";
			castTime = "Action";
			range = 20;
			damage = "1-6";
			damageType = "Acid";
			dice = "1d6";
			savingThrow = "Dexterity";
		},
		{
			name = "Blade Ward";
			icon = "Interface/Icons/ability_creature_poison_06";
			description = "Take only half of the damage from Bludgeoning, Piercing, and Slashing attacks.";
			level = "Cantrip";
			school = "Abjuration";
			castTime = "Action";
			duration = "2 turns";
		},
		{
			name = "Bone Chill";
			icon = "Interface/Icons/spell_necro_deathsdoor";
			description = "Prevent the target from healing until your next turn. An undead target receives Disadvantage on Attack Rolls.";
			level = "Cantrip";
			school = "Necromancy";
			castTime = "Action";
			range = 20;
			damage = "1-8";
			damageType = "Necrotic";
			dice = "1d8";
		},
		{
			name = "Dancing Lights";
			icon = "Interface/Icons/spell_arcane_arcane01";
			description = "Illuminate a 10 yard radius.";
			level = "Cantrip";
			school = "Evocation";
			castTime = "Action";
			range = 20;
			requiresConc = true;
		},
		{
			name = "Eldritch Blast";
			icon = "Interface/Icons/inv_demonbolt";
			description = "Conjure a beam of crackling energy.";
			level = "Cantrip";
			school = "Evocation";
			castTime = "Action";
			range = 20;
			damage = "1-10";
			damageType = "Force";
			dice = "1d10";
		},
		{
			name = "Fire Bolt";
			icon = "Interface/Icons/spell_fire_firebolt02";
			description = "Hurl a mote of fire.";
			level = "Cantrip";
			school = "Evocation";
			castTime = "Action";
			range = 20;
			damage = "1-10";
			damageType = "Fire";
			dice = "1d10";
		},
		{
			name = "Friends";
			icon = "Interface/Icons/achievement_reputation_01";
			description = "Gain Advantage on Charisma Checks against a non-hostile creature.|n|nThis spell can be cast while you are Silenced.";
			level = "Cantrip";
			school = "Enchantment";
			castTime = "Action";
			range = 10;
			duration = "10 turns";
			requiresConc = true;
		},
		{
			name = "Guidance";
			icon = "Interface/Icons/spell_holy_holyguidance";
			description = "The target gains a +1d4 bonus to Ability Checks.";
			level = "Cantrip";
			school = "Divination";
			castTime = "Action";
			range = "Melee";
			duration = "10 turns";
			requiresConc = true;
		},
		{
			name = "Light";
			icon = "Interface/Icons/spell_nature_enchantarmor";
			description = "Infuse an object with an aura of light.";
			level = "Cantrip";
			school = "Evocation";
			castTime = "Action";
			range = "Melee";
			duration = "10 turns";
			savingThrow = "Dexterity";
		},
		{
			name = "Mage Hand";
			icon = "Interface/Icons/ability_mage_incantersabsorbtion";
			description = "Create a spectral hand that can manipulate and interact with objects.";
			level = "Cantrip";
			school = "Conjuration";
			castTime = "Action";
			range = 20;
			duration = "Permanent";
			requiresConc = true;
		},
		{
			name = "Minor Illusion";
			icon = "Interface/Icons/spell_mage_presenceofmind";
			description = "Create an illusion that compels nearby creatures to investigate.|n|nYou can remain hidden while casting this spell.|n|nThis spell can be cast while you are Silenced.";
			level = "Cantrip";
			school = "Illusion";
			castTime = "Action";
			range = 20;
			requiresConc = true;
		},
		{
			name = "Poison Spray";
			icon = "Interface/Icons/spell_shadow_plaguecloud";
			description = "Project a puff of noxious gas.";
			level = "Cantrip";
			school = "Conjuration";
			castTime = "Action";
			range = 3;
			damage = "1-8";
			damageType = "Poison";
			dice = "1d8";
			savingThrow = "Constitution";
		},
		{
			name = "Produce Flame";
			icon = "Interface/Icons/spell_fire_playingwithfire";
			description = "A flame in your hand sheds a light in a 9m radius and deals 1-8 Fire damage damage when thrown.|n|nThrowing the flame immediately after you conjure it does not cost an action.|n|nExtinguishing or throwing it on subsequent turns costs an action.";
			level = "Cantrip";
			school = "Conjuration";
			castTime = "Action";
			duration = "Until Long Rest";
		},
		{
			name = "Ray of Frost";
			icon = "Interface/Icons/ability_mage_rayoffrost";
			description = "Reduce the target's movement speed by 3m.";
			level = "Cantrip";
			school = "Evocation";
			castTime = "Action";
			range = 20;
			damage = "1-8";
			damageType = "Cold";
			dice = "1d8";
		},
		{
			name = "Resistance";
			icon = "Interface/Icons/spell_holy_rebuke";
			description = "Make a target more resistant to spell effects and conditions: it receives a +1d4 bonus to Saving Throws.";
			level = "Cantrip";
			school = "Abjuration";
			castTime = "Action";
			range = "Melee";
			duration = "10 turns";
			requiresConc = true;
		},
		{
			name = "Sacred Flame";
			icon = "Interface/Icons/spell_holy_searinglightpriest";
			description = "Engulf a target in a flame-like radiance.";
			level = "Cantrip";
			school = "Evocation";
			castTime = "Action";
			range = 20;
			damage = "1-8";
			damageType = "Radiant";
			dice = "1d8";
			savingThrow = "Dexterity";
		},
		{
			name = "Shillelagh";
			icon = "Interface/Icons/inv_staff_17";
			description = "Imbue your staff or club with nature's power. It becomes magical, deals 1d8+WIS Bludgeoning damage, and uses your Spellcasting Ability for Attack Rolls.";
			level = "Cantrip";
			school = "Transmutation";
			castTime = "Bonus Action";
			duration = "10 turns";
		},
		{
			name = "Shocking Grasp";
			icon = "Interface/Icons/spell_shaman_crashlightning";
			description = "The target cannot use reactions. This spell has Advantage on creatures wearing metal armour.";
			level = "Cantrip";
			school = "Evocation";
			castTime = "Action";
			range = "Melee";
			damage = "1-8";
			damageType = "Lightning";
			dice = "1d8";
			duration = "10 turns";
		},
		{
			name = "Spare the Dying";
			icon = "Interface/Icons/spell_shaman_crashlightning";
			description = "Touch a living creature that has 0 hit points. The creature becomes stable. This spell has no effect on undead or constructs.";
			level = "Cantrip";
			school = "Necromancy";
			castTime = "Action";
			range = "Melee";
		},
		{
			name = "Thaumaturgy";
			icon = "Interface/Icons/spell_holy_powerinfusion";
			description = "Gain Advantage on Intimidation and Performance Checks.";
			level = "Cantrip";
			school = "Transmutation";
			castTime = "Action";
			range = "Melee";
			duration = "10 turns";
		},
		{
			name = "Thorn Whip";
			icon = "Interface/Icons/spell_nature_thorns";
			description = "Pulls the creature 3 yards closer to you.|n|n{WARNING} The target can't be pulled if it is Huge in size.";
			level = "Cantrip";
			school = "Transmutation";
			castTime = "Action";
			range = 10;
		},
		{
			name = "True Strike";
			icon = "Interface/Icons/ability_hunter_snipershot";
			description = "Gain Advantage on your next Attack Roll.";
			level = "Cantrip";
			school = "Divination";
			castTime = "Action";
			range = 20;
			duration = "2 turns";
		},
		{
			name = "Vicious Mockery";
			icon = "Interface/Icons/spell_shadow_skull";
			description = "Insult a creature: it has Disadvantage on its next Attack Roll.";
			level = "Cantrip";
			school = "Enchantment";
			castTime = "Action";
			range = 20;
			duration = "1 turn";
			savingThrow = "Wisdom";
		},
		{
			name = "Animal Friendship";
			icon = "Interface/Icons/ability_hunter_invigeration";
			description = "Convince a beast not to attack you.|nThe creature must have an Intelligence of 3 or less.|nCondition ends early if you or an ally hurts the target.|nWhen the spell ends, the target might become hostile.";
			level = 1;
			school = "Enchantment";
			castTime = "Action";
			range = 20;
			duration = "10 turns";
			savingThrow = "Wisdom";
		},
		{
			name = "Armor of Agathys";
			icon = "Interface/Icons/spell_frost_chillingarmor";
			description = "Gain 5 temporary hit points and deal 5 Cold Damage to any creature that hits you with a melee attack.|nCan only have temporary hit points from one source.";
			level = 1;
			school = "Abjuration";
			castTime = "Action";
			range = "Melee";
			duration = "10 turns";
		},
		{
			name = "Arms of Hadar";
			icon = "Interface/Icons/spell_priest_voidtendrils";
			description = "Prevent targets from taking reactions.|nOn Save: Targets still take half damage.";
			level = 1;
			school = "Abjuration";
			castTime = "Action";
			range = "Melee";
			duration = "10 turns";
		},
	},
}