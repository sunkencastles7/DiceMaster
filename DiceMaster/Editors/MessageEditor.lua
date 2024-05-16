-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Message editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local chat_channels = { 
	"SAY";
	"YELL";
	"EMOTE";
	"GUILD";
	"PARTY";
	"RAID";
}

function Me.MessageEditorChannel_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText( DiceMasterMessageEditor.channel, self:GetText() )
end

function Me.MessageEditorChannel_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	for i=1, #chat_channels do
		info.text = chat_channels[i]
		info.checked = UIDropDownMenu_GetText(DiceMasterMessageEditor.channel) == info.text;
		info.notCheckable = false;
		info.func = Me.MessageEditorChannel_OnClick;
		UIDropDownMenu_AddButton(info, level)
	end
end

function Me.MessageEditor_Refresh()
	DiceMasterMessageEditor.message.EditBox:SetText("")
	DiceMasterMessageEditor.delay:SetText("")
	UIDropDownMenu_SetText( DiceMasterMessageEditor.channel, chat_channels[1] )
	
	Me.EffectEditingIndex = nil;
end

function Me.MessageEditor_SendMessage( data, item )
	if not data or not data.type or not data.message or not data.channel or data.type ~= "message" then
		return
	end
	
	local message = data.message
	
	-- Insert item link, if present
	if item and item.guid then
		local link = "[DiceMaster4Item:"..(UnitName("player"))..":"..(item.guid).."]";
		message = gsub(message,"%%[Ll]",link);
	end
	
	SendChatMessage( message, data.channel )
end

function Me.MessageEditor_Load( effectIndex )
	
	local effect = nil
	if Me.ItemEditing then
		effect = Me.ItemEditing.effects[ effectIndex ]
	elseif Me.newItem then
		effect = Me.newItem.effects[ effectIndex ]
	end
	
	if not effect then
		return
	end
	
	Me.EffectEditingIndex = effectIndex
	
	DiceMasterMessageEditor.message.EditBox:SetText( effect.message )
	DiceMasterMessageEditor.delay:SetText( effect.delay )
	UIDropDownMenu_SetText( DiceMasterMessageEditor.channel, effect.channel )
	
	DiceMasterMessageEditorSaveButton:SetScript( "OnClick", function()
		Me.MessageEditor_SaveEdits()
	end)	
end

function Me.MessageEditor_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	local message = DiceMasterMessageEditor.message.EditBox:GetText()
	local channel = UIDropDownMenu_GetText( DiceMasterMessageEditor.channel )
	local delay = tonumber( DiceMasterMessageEditor.delay:GetText() )
	
	if not channel or type( channel ) ~= "string" then
		channel = "SAY"
	end
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	if not message or message == "" or type( message ) ~= "string" then
		UIErrorsFrame:AddMessage( "Invalid message.", 1.0, 0.0, 0.0 );
		return
	end
	
	local messageData = {
		type = "message";
		message = message;
		channel = channel;
		delay = delay;
	}
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = messageData
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = messageData
	end
	
	Me.MessageEditor_Close()
	Me.ItemEditorEffectsList_Update()
end

function Me.MessageEditor_Save()
	local message = DiceMasterMessageEditor.message.EditBox:GetText()
	local channel = UIDropDownMenu_GetText( DiceMasterMessageEditor.channel )
	local delay = tonumber( DiceMasterMessageEditor.delay:GetText() )
	
	if not channel or type( channel ) ~= "string" then
		channel = "SAY"
	end
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	if not message or message == "" or type( message ) ~= "string" then
		UIErrorsFrame:AddMessage( "Invalid message.", 1.0, 0.0, 0.0 );
		return
	end
	
	local messageData = {
		type = "message";
		message = message;
		channel = channel;
		delay = delay;
	}
	
	if Me.ItemEditing then
		tinsert( Me.ItemEditing.effects, messageData )
	elseif Me.newItem then
		tinsert( Me.newItem.effects, messageData )
	end
	
	Me.MessageEditor_Close()
	Me.ItemEditorEffectsList_Update()
end
    
-------------------------------------------------------------------------------
-- Close the message editor window. Use this instead of a direct Hide()
--
function Me.MessageEditor_Close()
	Me.MessageEditor_Refresh()
	DiceMasterMessageEditorSaveButton:SetScript( "OnClick", function()
		Me.MessageEditor_Save()
	end)	
	DiceMasterMessageEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the message editor window.
--
function Me.MessageEditor_Open( frame )
	Me.CloseAllEditors( nil, nil, true )
	if not frame then
		frame = DiceMasterItemEditor;
	end
	DiceMasterMessageEditor:ClearAllPoints()
	DiceMasterMessageEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterMessageEditorSaveButton:SetScript( "OnClick", function()
		Me.MessageEditor_Save()
	end)	
	
	Me.MessageEditor_Refresh()
	DiceMasterMessageEditor:Show()
end
