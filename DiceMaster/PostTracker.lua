-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Post tracker interface.
--

local Me = DiceMaster4
Me.WhoIsTyping = {}

local trackTypes = {
	["Say: "] = true,
	["Party: "] = true,
	["Raid: "] = true,
	[UnitName("player").." "] = true,
}

function Me.PostTracker_SendUpdate( typing )
	local data = {}
	data.na = UnitName("player")
	data.tp = typing
	local msg = Me:Serialize( "TYPE", data )
	C_ChatInfo.SendAddonMessage( "DCM4", msg, "RAID" )
end

function Me.PostTracker_Typing( self )
	if IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then return end

	local chatType = _G[self:GetName() .. "Header"]:GetText()
	local msg = self:GetText()
	if string.len(msg) > 0 and not msg:match("^%/%.*") then 
		msg = true
	else 
		msg = false 
	end
	
	if DiceMasterPostTrackerButton.isTyping then
		self.Typing = true;
		Me.PostTracker_SendUpdate( self.Typing )
		return
	end
	
	if msg and trackTypes[chatType] and self:HasFocus() then
		if not self.Typing then
			self.Typing = true;
			Me.PostTracker_SendUpdate( self.Typing )
		end
	else
		self.Typing = false;
		Me.PostTracker_SendUpdate( self.Typing )
	end
end

function Me.PostTracker_Init()
	if not ( Me.db.global.hideTypeTracker ) then
		DiceMasterPostTrackerButton.isTyping = false;
		
		if ( DiceMasterPostTrackerButton.Timer ) then
			DiceMasterPostTrackerButton.Timer:Cancel()
		end
	
		DiceMasterPostTrackerButton.icon:SetTexture("Interface/Buttons/UI-GuildButton-PublicNote-Disabled")
		DiceMasterPostTrackerButton.alert:Hide()
		DiceMasterPostTrackerButton.alert.flash:Stop()
		DiceMasterPostTrackerButton:Hide()
		
		Me.PostTracker_SendUpdate( false )
	else
		DiceMasterPostTrackerButton:Show()
	end
end

function Me.PostTracker_OnClick( self, button )
	self.isTyping = not self.isTyping
	
	if ( self.Timer ) then
		self.Timer:Cancel()
	end
	
	if ( self.isTyping ) then
		self.icon:SetTexture("Interface/Buttons/UI-GuildButton-PublicNote-Up")
		self.Timer = C_Timer.NewTicker(300, function()
			if ( self:IsShown() ) then
				self.alert:Show()
				self.alert.flash:Play()
			end
		end, 0)
	else
		self.icon:SetTexture("Interface/Buttons/UI-GuildButton-PublicNote-Disabled")
		self.alert:Hide()
		self.alert.flash:Stop()
	end
	
	if GameTooltip:IsOwned(self) then
		self:GetScript("OnEnter")(self)
	end
	
	Me.PostTracker_SendUpdate( self.isTyping )	
	PlaySound(SOUNDKIT.IG_CHAT_EMOTE_BUTTON);
end

function Me.PostTracker_OnLoad( self )
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. i .. "EditBox"]
		frame:HookScript("OnChar", Me.PostTracker_Typing)
		frame:HookScript("OnEditFocusLost", Me.PostTracker_Typing)
	end
	
	local f = CreateFrame("Frame")
	f:RegisterEvent( "GROUP_ROSTER_UPDATE" )
	f:SetScript( "OnEvent", function( self, event )
		if IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
			return
		end
		
		if event and #Me.WhoIsTyping > 0 then
			for i=1,#Me.WhoIsTyping do
				if not UnitInParty(Me.WhoIsTyping[i]) and not UnitInRaid(Me.WhoIsTyping[i])  then
					tremove(Me.WhoIsTyping, i)
				end
				C_Timer.After( 1.0, function()
					if Me.WhoIsTyping[i] and not UnitIsConnected(Me.WhoIsTyping[i]) then
						tremove(Me.WhoIsTyping, i)
						if #Me.WhoIsTyping == 0 and not Me.FramesUnlocked then
							DiceMasterPostTrackerFrame.FadeOutAnim:Play()
						end
					end
				end)
			end
			if #Me.WhoIsTyping == 0 and not Me.FramesUnlocked then
				DiceMasterPostTrackerFrame.FadeOutAnim:Play()
			end
		end
	end)
end

---------------------------------------------------------------------------
-- Someone is typing...
--  na = name							string
--	tp = typing | not typing			boolean

function Me.PostTracker_OnTyping( data, dist, sender )	
	-- Ignore our own data.
	if sender == UnitName( "player" )  then return end
 
	-- sanitize message
	if not data.na or not Me.db.global.hideTypeTracker then
	   
		return
	end
	
	if data.tp then
		local found = false;
		for i = 1, #Me.WhoIsTyping do
			if Me.WhoIsTyping[i] == data.na then
				found = true;
				break
			end
		end
		if not( found ) then
			tinsert(Me.WhoIsTyping, data.na)
		end
	else
		for i=1,#Me.WhoIsTyping do
			if Me.WhoIsTyping[i] == data.na then
				tremove(Me.WhoIsTyping, i)
				break
			end
		end
	end
	
	if #Me.WhoIsTyping > 0 then
		local text = Me.WhoIsTyping[1]
		local plural = " is"
		
		if #Me.WhoIsTyping > 3 then
			text = "Several people"
			plural = " are"
		elseif #Me.WhoIsTyping > 1 then 
			plural = " are"
			for i = 2, #Me.WhoIsTyping do
				if i == #Me.WhoIsTyping then
					if #Me.WhoIsTyping > 2 then
						text = text .. ", and " .. Me.WhoIsTyping[i]
					else
						text = text .. " and " .. Me.WhoIsTyping[i]
					end
				else
					text = text .. ", " .. Me.WhoIsTyping[i]
				end
			end
		end
		
		if text then 
			text = "|TInterface/GossipFrame/ChatBubbleGossipIcon:16|t "..text..plural.." typing..."
			DiceMasterPostTrackerFrame.Message:SetText( text )
		end
		
		local tooltip = "|cFFffd100" .. Me.WhoIsTyping[1]
		for i=2,#Me.WhoIsTyping do
			tooltip = tooltip .. "|n" .. Me.WhoIsTyping[i]
		end
		Me.SetupTooltip( DiceMasterPostTrackerFrame, nil, tooltip )
		if GameTooltip:IsOwned(DiceMasterPostTrackerFrame) then
			DiceMasterPostTrackerFrame:GetScript("OnEnter")(DiceMasterPostTrackerFrame)
		end
		
		if DiceMasterPostTrackerFrame.FadeOutAnim:IsPlaying() then
			DiceMasterPostTrackerFrame.FadeOutAnim:Stop()
		end
		
		if not DiceMasterPostTrackerFrame.FadeInAnim:IsPlaying() or not DiceMasterPostTrackerFrame:IsShown() then
			DiceMasterPostTrackerFrame:Show()
			if DiceMasterPostTrackerFrame.Background:GetAlpha() < 1 then
				DiceMasterPostTrackerFrame.FadeInAnim:Play()
			end
		end
	elseif not Me.FramesUnlocked then
		if GameTooltip:IsOwned(DiceMasterPostTrackerFrame) then
			GameTooltip:Hide()
		end
		DiceMasterPostTrackerFrame:SetScript( "OnEnter", nil )
		if DiceMasterPostTrackerFrame:IsShown() and not DiceMasterPostTrackerFrame.FadeOutAnim:IsPlaying() then
			DiceMasterPostTrackerFrame.FadeOutAnim:Play()
		end
	end
end
