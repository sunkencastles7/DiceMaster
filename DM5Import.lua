-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Import methods for DiceMaster data
--

local Me = DiceMaster4
local Profile = Me.Profile

function Me.ImportDM5Saved()
	if Me.Profile.dm5Imported or Me.Profile.skills ~= {} then 
		return
	end
	
	Me.Profile.skills = {}

	if not( Me.Profile.stats ) then
		return
	end
	
	for i = 1, #Me.Profile.stats do
		if Me.Profile.stats[i] then
			if Me.Profile.stats[i].value then
				local skill = {
					name = Me.Profile.stats[i].name,
					icon = "Interface/Icons/inv_misc_questionmark",
					desc = Me.Profile.stats[i].desc or nil,
					rank = Me.Profile.stats[i].value or 0,
					maxRank = 0,
					author = UnitName("player"),
					skillModifiers = {},
					expanded = true,
					showOnMenu = true,
					canEdit = true,
					guid = Me.GenerateGUID() .. i,
				}
				if Me.AttributeList[ skill.name ] then
					skill.maxRank = 10;
				end
				tinsert( Me.Profile.skills, skill )
			elseif Me.Profile.stats[i].name then
				local skill = {
					name = Me.Profile.stats[i].name,
					type = "header",
					author = UnitName("player"),
				}
				tinsert( Me.Profile.skills, skill )
			end
		end
	end

	-- If a statistic had an attribute attached, find its GUID and insert 
	-- it into the skillModifiers table.
	for i = 1, #Me.Profile.
	s do
		if Me.Profile.stats[i] and Me.Profile.stats[i].attribute then
			for skillIndex = 1, #Me.Profile.skills do
				if Me.Profile.skills[skillIndex].name == Me.Profile.stats[i].attribute then
					tinsert( Me.Profile.skills[i].skillModifiers, Me.Profile.skills[skillIndex].guid )
				end
			end
		end
	end
	
	Me.Profile.dm5Imported = true;
end