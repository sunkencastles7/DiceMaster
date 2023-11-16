-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Skill Check Interface
--

local Me = DiceMaster4
local Profile = Me.Profile

function Me.DiceRoller_Dice_OnEnter( self )
	self.Bounce:Play();
	self.SheenSlide:Play();
end

function Me.DiceRoller_Dice_OnClick( self, button )
	self:Disable();
	self.Flash:SetModel(629717);
	self.Flash:Show();
	self.RollDice:Play();
	PlaySoundFile("Interface/AddOns/DiceMaster/Sounds/DiceRoll.ogg");	-- custom roll sound
	self:GetParent().ExplodeAnim:Play();
end

function Me.DiceRoller_Dice_OnShow( self )
	self.RollFinish:Play();
	self.Dice:SetTexture("Interface/AddOns/DiceMaster/Texture/Dice/d20_20");
end


function Me.DiceRoller_OnShow( self )
	local skill, attribute, totalBonus;

	skill = "Persuasion";
	attribute = "Charisma";

	-- Find the checked skill in our skills, and add its value to total bonus
	for i = 1, #Profile.skills do
		if Profile.skills[i].guid == skill then
			totalBonus = totalBonus + Profile.skills[i].value;
		end
	end

	self.BonusFrame.Pool = CreateFramePool("Button", self.BonusFrame, "DiceMasterDiceRollerBonusCard")

	-- Check our active buffs for any that modify the checked skill, add it to total bonus
	local totalBonusCount = 0;
	for i = 1,#Profile.buffsActive do
		if Profile.buffsActive[i].skill and Profile.buffsActive[i].skill == skill then
			-- Multiply the bonus (skillRank) by the number of stacks (count)
			local bonus = Profile.buffsActive[i].skillRank * Profile.buffsActive[i].count;
			local button = self.BonusFrame.Pool:Acquire()
			button:SetPoint( "LEFT", self.BonusFrame, "LEFT", 32*i-32, 6 );
			button.Title:SetText( Profile.buffsActive[i].name );
			if bonus > 0 then
				button.Bonus:SetText( "+" .. bonus );
			else
				button.Bonus:SetText( bonus );
			end
			SetPortraitToTexture( button.Icon, Profile.buffsActive[i].icon );
			totalBonus = totalBonus + bonus;
			totalBonusCount = totalBonusCount + 1;
		end
	end
	self.BonusFrame:SetWidth( 100 * totalBonusCount );
	if (totalBonus) then
		self.BonusFrame:Show();
		self.AddBonusFrame:ClearAllPoints();
		self.AddBonusFrame:SetPoint("TOP", self.BonusFrame, "BOTTOM", 0, -16);
		if totalBonus > 0 then
			self.BonusFrame.BonusTitle:SetText( "Total Bonus +" .. totalBonus );
		else
			self.BonusFrame.BonusTitle:SetText( "Total Bonus " .. totalBonus );
		end
	else
		self.BonusFrame:Hide();
		self.AddBonusFrame:ClearAllPoints();
		self.AddBonusFrame:SetPoint("TOP", self, "BOTTOM", 0, -16);
	end
end