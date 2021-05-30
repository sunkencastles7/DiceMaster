-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Animation picker interface.
--

local Me = DiceMaster4

function Me.AnimationPicker_OnLoad(self)
	self.Inset:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -28)
	self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -6, 26)
	
	if self.NineSlice then
		self.NineSlice:SetFrameLevel(1)
	end
end

-------------------------------------------------------------------------------
-- UIDropDownMenu for Animations
--

function Me.AnimationPickerDropDown_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText(arg1, self:GetText())
	local data = {
		id = arg2;
		anim = self:GetText();
	}
	Me.UnitEditing.animations[ arg1:GetParent().name:GetText() ] = data
	Me.AffixEditor_UpdateModel()
end

local function CreateAnimationMenu(dropdown, level, range)
	local startLetter = string.byte(range, 1);
	local endLetter = string.byte(range, 3) or string.byte(range, 1);
	for i, animation in ipairs(Me.animationList) do
		local letter = string.byte(animation.name, 1)
		
		if (letter >= startLetter and letter <= endLetter and DiceMasterAffixEditor.Model:HasAnimation( animation.id )) then
			local info = UIDropDownMenu_CreateInfo();
			info.text = animation.name;
			info.func = Me.AnimationPickerDropDown_OnClick;
			info.checked = Me.unitAnim == animation.id;
			info.arg1 = dropdown
			info.arg2 = animation.id;
			UIDropDownMenu_AddButton(info, level);
		end
	end
end

local function CreateAnimationRangeMenu(dropdown, level, range)
	local info = UIDropDownMenu_CreateInfo();
	info.text = range;
	info.value = range;
	info.notCheckable = true;
	info.hasArrow = true;
	info.keepShownOnClick = true;
	info.menuList = range;
	UIDropDownMenu_AddButton(info, level);
end

function Me.AnimationPickerDropDown_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()

	if level == 1 then
		CreateAnimationRangeMenu(frame, level, "A-B");
		CreateAnimationRangeMenu(frame, level, "C-D");
		CreateAnimationRangeMenu(frame, level, "E");
		CreateAnimationRangeMenu(frame, level, "F-L");
		CreateAnimationRangeMenu(frame, level, "M-O");
		CreateAnimationRangeMenu(frame, level, "P-R");
		CreateAnimationRangeMenu(frame, level, "S");
		CreateAnimationRangeMenu(frame, level, "T-Z");
	elseif menuList then
		CreateAnimationMenu(frame, level, menuList);
	end
end

function Me.AnimationPicker_TestAnimation( self )
	local list = Me.animationList;
	
	if Me.UnitEditing.animations[self.name:GetText()] then
		DiceMasterAffixEditor.Model:SetAnimation( Me.UnitEditing.animations[self.name:GetText()].id )
	end
end

function Me.AnimationPicker_UnbindAllAnimations()
	if Me.UnitEditing then
		--DiceMasterAffixEditor.animations = {}
		Me.UnitEditing.animations = {
			["PreAggro"] = { id = 0, anim = "Stand" },
			["Aggro"] = { id = 127, anim = "Birth" },
			["Melee Attack"] = { id = 16, anim = "AttackUnarmed" },
			["Ranged Attack"] = { id = 29, anim = "ReadyBow" },
			["Spell Attack"] = { id = 53, anim = "SpellCastDirected" },
			["Wound"] = { id = 8, anim = "StandWound" },
			["Death"] = { id = 1, anim = "Death" },
			["Dead"] = { id = 6, anim = "Dead" },
		}
		UIDropDownMenu_SetText( DiceMasterAnimationPicker.preaggro, "Stand" ) 
		UIDropDownMenu_SetText( DiceMasterAnimationPicker.aggro, "Birth" )
		UIDropDownMenu_SetText( DiceMasterAnimationPicker.meleeAttack, "Attack1H" )
		UIDropDownMenu_SetText( DiceMasterAnimationPicker.rangedAttack, "AttackBow" )
		UIDropDownMenu_SetText( DiceMasterAnimationPicker.spellAttack, "SpellCastDirected" )
		UIDropDownMenu_SetText( DiceMasterAnimationPicker.wound, "StandWound" )
		UIDropDownMenu_SetText( DiceMasterAnimationPicker.death, "Death" )
		UIDropDownMenu_SetText( DiceMasterAnimationPicker.dead, "Dead" )
		
		Me.AffixEditor_UpdateModel()
	end
end

function Me.AnimationPicker_UpdateBindings()
	if Me.UnitEditing and Me.UnitEditing.animations then
		for k, v in pairs( Me.UnitEditing.animations ) do
			if _G["DiceMasterAnimationPicker"..k.."Animation"] then
				local dropdown = _G["DiceMasterAnimationPicker"..k.."Animation"].animation
				UIDropDownMenu_SetSelectedName( dropdown, v.anim )
				UIDropDownMenu_SetText( dropdown, v.anim )
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Close the animation picker window. Use this instead of a direct Hide()
--
function Me.AnimationPicker_Close()
	Me.AnimationEditing = nil;
	DiceMasterAnimationPicker:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the animation picker window.
--
function Me.AnimationPicker_Open( frame )
	Me.ModelPicker_Close()
	DiceMasterAnimationPicker:ClearAllPoints()
	DiceMasterAnimationPicker:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterAnimationPicker:Show()
	
	Me.AnimationPicker_UpdateBindings()
end