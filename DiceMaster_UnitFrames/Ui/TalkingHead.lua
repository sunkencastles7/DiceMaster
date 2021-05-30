-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Talking head frame for dynamic dialogue.
--

local Me = DiceMaster4

Me.talkingHeadTextureKit = "Normal"
Me.soundKitID = nil

local talkingHeadFontColor = {
	["Horde"] = {Name = CreateColor(0.28, 0.02, 0.02), Text = CreateColor(0.0, 0.0, 0.0), Shadow = CreateColor(0.0, 0.0, 0.0, 0.0)},
	["Alliance"] = {Name = CreateColor(0.02, 0.17, 0.33), Text = CreateColor(0.0, 0.0, 0.0), Shadow = CreateColor(0.0, 0.0, 0.0, 0.0)},
	["Neutral"] = {Name = CreateColor(0.33, 0.16, 0.02), Text = CreateColor(0.0, 0.0, 0.0), Shadow = CreateColor(0.0, 0.0, 0.0, 0.0)},
	["Normal"] = {Name = CreateColor(1, 0.82, 0.02), Text = CreateColor(1, 1, 1), Shadow = CreateColor(0.0, 0.0, 0.0, 1.0)},
}

function DiceMasterTalkingHeadFrame_OnLoad(self)
	self:SetClampedToScreen( true )
	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag( "LeftButton" )
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )
	--self:SetScale(0.8)
	self:SetUserPlaced( true )
	self:RegisterForClicks("RightButtonUp");

	self.NameFrame.Name:SetPoint("TOPLEFT", self.PortraitFrame.Portrait, "TOPRIGHT", 2, -19);
	self.TextFrame.Text:SetFontObjectsToTry(SystemFont_Shadow_Large, SystemFont_Shadow_Med2, SystemFont_Shadow_Med1);
	
	self.TextFrame.Text:SetShadowColor( 0, 0, 0, 0 )
	
	local alertSystem = AlertFrame:AddExternallyAnchoredSubSystem(self);
	AlertFrame:SetSubSystemAnchorPriority(alertSystem, 0);
end

function DiceMasterTalkingHeadFrame_OnShow(self)
	UIParent_ManageFramePositions();
end

function DiceMasterTalkingHeadFrame_OnHide(self)
	UIParent_ManageFramePositions();
end

function DiceMasterTalkingHeadFrame_CloseImmediately()
	local frame = DiceMasterTalkingHeadFrame;
	if (frame.finishTimer) then
		frame.finishTimer:Cancel()
		frame.finishTimer = nil;
	end
	if (frame.closeTimer) then
		frame.closeTimer:Cancel()
		frame.closeTimer = nil;
	end
	frame.NameFrame.Fadein:Finish()
	frame.NameFrame.Fadeout:Finish()
	frame.NameFrame.Close:Finish()
	frame.TextFrame.Fadein:Finish()
	frame.TextFrame.Fadeout:Finish()
	frame.TextFrame.Close:Finish()
	frame.BackgroundFrame.Fadein:Finish()
	frame.BackgroundFrame.Close:Finish()
	frame.PortraitFrame.Fadein:Finish()
	frame.PortraitFrame.Close:Finish()
	frame.MainFrame.TalkingHeadsInAnim:Finish()
	frame.MainFrame.Close:Finish();
	frame:Hide();
end

function DiceMasterTalkingHeadFrame_OnClick(self, button)
	if ( button == "RightButton" ) then
		DiceMasterTalkingHeadFrame_CloseImmediately();
		return true;
	end

	return false;
end

function DiceMasterTalkingHeadFrame_FadeinFrames()
	local frame = DiceMasterTalkingHeadFrame
	frame.MainFrame.TalkingHeadsInAnim:Play();
	C_Timer.After(0.5, function()
		frame.NameFrame.Fadein:Play();
	end);
	C_Timer.After(0.75, function()
		frame.TextFrame.Fadein:Play();
	end);
	frame.BackgroundFrame.Fadein:Play();
	frame.PortraitFrame.Fadein:Play();
end

function DiceMasterTalkingHeadFrame_FadeoutFrames()
	local frame = DiceMasterTalkingHeadFrame
	frame.MainFrame.Close:Play();
	frame.NameFrame.Close:Play();
	frame.TextFrame.Close:Play();
	frame.BackgroundFrame.Close:Play();
	frame.PortraitFrame.Close:Play();
end

function DiceMasterTalkingHeadFrame_Reset(frame, text, name)
	-- set alpha for all animating textures
	frame:StopAnimating();
	frame.BackgroundFrame.TextBackground:SetAlpha(0.01);
	frame.NameFrame.Name:SetAlpha(0.01);
	frame.TextFrame.Text:SetAlpha(0.01);
	frame.MainFrame.Sheen:SetAlpha(0.01);
	frame.MainFrame.TextSheen:SetAlpha(0.01);

	frame.MainFrame.Model:SetAlpha(0.01);
	frame.MainFrame.Model.PortraitBg:SetAlpha(0.01);
	frame.PortraitFrame.Portrait:SetAlpha(0.01);
	frame.MainFrame.Overlay.Glow_LeftBar:SetAlpha(0.01);
	frame.MainFrame.Overlay.Glow_RightBar:SetAlpha(0.01);
	frame.MainFrame.CloseButton:SetAlpha(0.01);

	frame.MainFrame:SetAlpha(1);
	frame.NameFrame.Name:SetText(name);
	frame.TextFrame.Text:SetText(text);
end

function DiceMasterTalkingHeadFrame_SetUnit(modelID, name, textureKit, message, sound, isWhisper)
	
	-- Not using Talking Heads.
	if not Me.db.global.talkingHeads then
		if not isWhisper then
			Me.PrintMessage("|cFFE6E68E"..(name or "Unknown").." says: "..message, "RAID")
		else
			Me.PrintMessage("|cFFFF7EFF"..(name or "Unknown").." whispers: "..message, "RAID")
		end
		return;
	end
	
	if not Me.db.global.talkingHeads then
		return;
	end

	local frame = DiceMasterTalkingHeadFrame;
	
	-- A Talking Head is playing, so add this one to the queue.
	-- We'll try again after this one finishes up.
	if frame:IsShown() then
		if not frame.Queue then
			frame.Queue = {}
		end
		
		local queuedFrame = {
			modelID = modelID;
			name = name;
			textureKit = textureKit;
			message = message;
			sound = sound;
			isWhisper = isWhisper;
		}
		tinsert( frame.Queue, queuedFrame )
		return;
	end

	local model = frame.MainFrame.Model;
	model.PortraitImage:Hide()
	
	if type(modelID) == "number" then 
		model:SetDisplayInfo(modelID)
		model:SetPortraitZoom(1)
	elseif type(modelID) == "string" then
		model:SetDisplayInfo(1)
		model.PortraitImage:Show()
		model.PortraitImage:SetTexture(modelID)
	end
	frame.soundKitID = sound or nil;
	frame.NameFrame.Name:SetText(name or "Unknown")
	
	if textureKit == "Normal" then
		frame.BackgroundFrame.TextBackground:SetAtlas("TalkingHeads-TextBackground")
		frame.PortraitFrame.Portrait:SetAtlas("TalkingHeads-PortraitFrame")
	else
		frame.BackgroundFrame.TextBackground:SetAtlas("TalkingHeads-"..textureKit.."-TextBackground")
		frame.PortraitFrame.Portrait:SetAtlas("TalkingHeads-"..textureKit.."-PortraitFrame")
	end
	
	local nameColor = talkingHeadFontColor[textureKit].Name;
	local textColor = talkingHeadFontColor[textureKit].Text;
	local shadowColor = talkingHeadFontColor[textureKit].Shadow;
	frame.NameFrame.Name:SetTextColor(nameColor:GetRGB());
	frame.NameFrame.Name:SetShadowColor(shadowColor:GetRGBA());
	frame.TextFrame.Text:SetTextColor(textColor:GetRGB());
	frame.TextFrame.Text:SetShadowColor(shadowColor:GetRGBA());
	
	DiceMasterTalkingHeadFrame_PlayCurrent( message, isWhisper )
end

function DiceMasterTalkingHeadFrame_PlayCurrent( message, isWhisper )

	local frame = DiceMasterTalkingHeadFrame;
	
	local unitframes = DiceMasterUnitsPanel.unitframes; 
	local model = frame.MainFrame.Model;
	model.sequence = nil;
	DiceMasterTalkingHeadFrame.animations = {}
	local animIndex = {["."]=60,["!"]=64,["?"]=65}
	
	message:gsub("%p",function(c) table.insert(DiceMasterTalkingHeadFrame.animations,animIndex[c]) end)
	
	if not isWhisper then
		Me.PrintMessage("|cFFE6E68E"..( frame.NameFrame.Name:GetText() or "Unknown").." says: "..message, "RAID" )
	else
		Me.PrintMessage("|cFFFF7EFF"..( frame.NameFrame.Name:GetText() or "Unknown").." whispers: "..message, "RAID" )
	end

	frame:Show();
	
	if not DiceMasterTalkingHeadFrame.animations[1] or model:HasAnimation(DiceMasterTalkingHeadFrame.animations[1])==false then DiceMasterTalkingHeadFrame.animations[1] = 60 end;
	model:SetAnimation(DiceMasterTalkingHeadFrame.animations[1])
	frame.TextFrame.Text:SetText(message)
	local stringHeight = frame.TextFrame.Text:GetStringHeight()/16
	
	if DiceMasterTalkingHeadFrame.soundKitID and Me.db.global.soundEffects then
		PlaySound(DiceMasterTalkingHeadFrame.soundKitID, "Dialog")
	end
	
	DiceMasterTalkingHeadFrame_FadeinFrames()
	frame.finishTimer = C_Timer.After(5+(2*stringHeight), function()
			model:SetAnimation(0)
			DiceMasterTalkingHeadFrame_FadeoutFrames()
			frame.finishTimer = nil;
		end
	);
	frame.closeTimer = C_Timer.After(6+(2*stringHeight), function()
			DiceMasterTalkingHeadFrame:Hide();
			frame.closeTimer = nil;
			
			if frame.Queue and #frame.Queue >= 1 then
				-- We still have more Talking Heads to show.
				local modelID = frame.Queue[1].modelID;
				local name = frame.Queue[1].name;
				local textureKit = frame.Queue[1].textureKit;
				local message = frame.Queue[1].message;
				local sound = frame.Queue[1].sound;
				local isWhisper = frame.Queue[1].isWhisper
				
				DiceMasterTalkingHeadFrame_SetUnit(modelID, name, textureKit, message, sound, isWhisper)
				tremove( frame.Queue, 1 )
			end
		end
	);
end

function DiceMasterTalkingHeadFrame_Init( message, textureKit, unit )
	
	if not unit then
		return
	end
	
	local model = unit:GetDisplayInfo()
	local name = unit.name:GetText()
	if name == "" then name = "Unknown" end
	local sound;
	if unit.sounds and unit.sounds["PreAggro"] then
		sound = unit.sounds["PreAggro"].id
	end
	DiceMasterTalkingHeadFrame_SetUnit(model, name, textureKit, message, sound, isWhisper);
	--DiceMasterTalkingHeadFrame_PlayCurrent(message)
	
	local msg = Me:Serialize( "DMSAY", {
		na = tostring( name );
		md = tonumber( model );
		ms = tostring( message );
		tk = tostring( textureKit );
		so = tonumber( sound );
	})
	
	Me:SendCommMessage( "DCM4", msg, "RAID", nil, "ALERT" )
end
