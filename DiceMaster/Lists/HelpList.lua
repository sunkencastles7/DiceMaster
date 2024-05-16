-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------
--

-- Assistant Tips List

-- tip				string 		Tip tooltip text.
-- keywords			table 		Keywords grabbed by search.
-- button1Text		string		Left button text (optional).
-- button1OnClick	function	Left button on-click handler (optional).
-- button2Text		string		Right button text (optional).
-- button2OnClick	function	Right button on-click handler (optional).

DiceMaster4.HelpList = {
	-- DICE
	{ title = "What is dice notation?", tip = "Dice rolls follow standard dice notation in the form XDY+Z|n|n- X is the number of dice to be rolled (or omitted if 1).|n- Y is the number of faces of each dice.|n- Z is an additive modifier added to (or subtracted from) the total.|n|nFor example,|n1D20+5 means 'roll one twenty-sided die, and then add five.'|n3D6+2 means 'roll three six-sided dice, add them together, and then add two.'", keywords = { "dice", "roll", "notation", "format", "d20" } },
	{ title = "How do I make a dice roll?", tip = "To make a roll, click the dice button on the Dice Panel.|n|nYou can click the arrow on the left of the button to edit the value of your dice.|n|nWhen you mouse over the dice button, a radial menu of your Skills will expand, allowing you to roll using that Skill as a modifier.", keywords = { "dice", "roll", "button" } },
	
	-- TRAITS
	{ title = "What are traits?", tip = "Traits are a set of five unique spells, abilities, or skills possessed by your character that are typically designed to reflect their strengths, weaknesses, and capabilities.|n|nTo edit your traits, click the Traits button on the Dice Panel.", keywords = { "trait", "spell" } },
	{ title = "How do I edit my traits?", tip = "Traits can be edited from the Traits Frame.|n|nTo edit your traits, click the Traits button on the Dice Panel.", keywords = { "trait", "spell", "edit" } },
	{ title = "How do I change a trait's usage?", tip = "Traits can either be Passive, Channeled (meaning that their effects continue each turn until cancelled or interrupted), or have a certain number of Uses (up to 3) per roleplaying event.|n|nThey can also use optional Resources (such as Mana, Energy, or Rage) which can be customised in the configuration menu.", keywords = { "trait", "spell", "use", "usage", "resource", "mana", "energy", "rage", "runic power", "focus", "charge" } },
	{ title = "How do I set the range of a trait?", tip = "Traits can be given optional distance-based requirements (up to 100 yd range).|n|nYou can check your distance from other players with the command '|cFFFFFFFF/dicemaster range (distance)|r' where |cFFFFFFFFdistance|r is measured in yards.", keywords = { "trait", "spell", "range", "distance", "yards", "radar" } },
	{ title = "How do I give a trait a cooldown?", tip = "Traits can be given an optional cooldown time, preventing the player from using a trait until the end of the duration.|n|nTrait cooldowns can use time or turn-based measurements when the Dungeon Master manually progresses the turn.", keywords = { "trait", "spell", "cooldown", "cd", "turn" } },
	{ title = "How do I use DiceMaster terms?", tip = "You can format your trait descriptions with official terms that are highlighted with supplemental definitions.|n|nUse the format buttons on the Traits Frame to insert a key term, or wrap a term in angle brackets (<>) to format your description.", keywords = { "trait", "spell", "format", "term", "keyword", "word", "bracket", "description" } },
	
	-- SKILLS
	{ title = "What are skills?", tip = "You can create custom character skills in the Skill tab of the Traits Frame.|n|nYou can start with the preset skills, or from scratch, and add or remove as many as you want.|n|nSkills will appear as roll options on your dice menu unless hidden from the Skills tab.|n|nSkills can also be shared with other players by using the ", keywords = { "skill", "stat", "statistic", "attribute", "sheet", "dice", "menu", } },
	
	-- PETS
	{ title = "How do I create a pet?", tip = "You can create a customisable pet, companion, or follower in the Pet tab of the Traits Frame.|n|nEnabling this feature will toggle the Pet Frame on your UI, allowing you to control your pet’s health, and allows others to view your pet on the Inspect Frame.", keywords = { "pet", "companion", "follower" } },
	{ title = "How do I use advanced pet features?", tip = "DiceMaster items with the 'Learn Pet' action can be used to add a custom pet to the user's Pet tab, and comes with a variety of optional features such as hunger, hygiene, and evolution!|n|n", keywords = { "pet", "companion", "follower", "advanced", "feature" } },
	
	-- ITEMS
	{ title = "How do I create a DiceMaster item?", tip = "You can create DiceMaster items with custom actions from the Inventory tab of the Traits Frame.|n|nDiceMaster items can be traded using the default trade frame, distributed to other players by the Dungeon Master, or sold for custom currencies in your shop.|n|nYou can also store your DiceMaster items in your Bank tab for safe-keeping.", keywords = { "item", "trade", "buy", "sell", "shop", "currency", } },
	
	-- SHOP 
	{ title = "How do I sell my DiceMaster items?", tip = "You can create a customisable shop, allowing you to sell your DiceMaster items to other players in the Shop tab of the Traits Frame.|n|nPlayers can view your shop from the Inspect Frame, allowing them to purchase the custom items you have listed in exchange for a custom currency.|n|nTo add an item to your shop, click the |cFFFFFFFFSell|r button on the Inventory tab of the Traits Frame, then select the item from your inventory.", keywords = { "shop", "buy", "sell", "item", "vendor", "merchant", "store", "currency" } },
	{ title = "How do I set up my shop?", tip = "To edit your shop, click the Traits button on the Dice Panel, then select the Shop tab on the right.|n|nClick the gear icon in the top left corner to change your shop's name and portrait.|n|nRemember to check the 'Enable Shop' button so other players can browse your shop!", keywords = { "shop", "buy", "sell", "item", "vendor", "merchant", "store", "currency", "enable", "set", "setup", } },
}

if DiceMaster4.PermittedUse() then
	-- TODO
	-- tinsert League specific tips into Me.HelpList.
end