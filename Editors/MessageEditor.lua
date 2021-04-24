-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Message editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local chat_channels = { 
	"Say";
	"Yell";
	"Emote";
	"Guild";
	"Party";
	"Raid";
	--"Whisper";
}

local function RGBToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

function Me.MessageEditorChannel_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText( DiceMasterMessageEditor.channel, self:GetText() )
end

function Me.MessageEditorChannel_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	for i=1, #chat_channels do
		local r, g, b = Chat_GetChannelColor( ChatTypeInfo[ string.upper( chat_channels[i] ) ] )
		local hex = RGBToHex( r, g, b )
		info.text = "|cFF" .. hex .. chat_channels[i] .. "|r"
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

function Me.MessageEditor_SendMessage( data )
	if not data or not data.type or not data.message or not data.channel or data.type ~= "message" then
		return
	end
	
	SendChatMessage( data.message, data.channel )
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
	
	DiceMasterMessageEditor.message.EditBox:SetText( effect.code )
	DiceMasterMessageEditor.delay:SetText( effect.delay )
	UIDropDownMenu_SetText( DiceMasterMessageEditor.channel, effect.channel )
	
	DiceMasterMessageEditorSaveButton:SetScript( "OnClick", function()
		Me.MessageEditor_SaveEdits()
	end)	
end

function Me.MessageEditor_SaveEdits()
	if not Me.ItemEditingIndex or not Me.EffectEditingIndex then
		return
	end
	
	local message = DiceMasterMessageEditor.message.EditBox:GetText()
	local channel = UIDropDownMenu_GetText( DiceMasterMessageEditor.channel )
	local delay = tonumber( DiceMasterMessageEditor.delay:GetText() )
	
	if not channel or type( channel ) ~= "string" then
		channel = "Say"
	end
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	if not message or message == "" or type( message ) ~= "string" then
		UIErrorsFrame:AddMessage( "Invalid message.", 1.0, 0.0, 0.0, 53, 5 );
		return
	end
	
	local messageData = {
		type = "message";
		message = message;
		channel = string.upper( channel );
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
	if not Me.ItemEditingIndex then
		return
	end
	
	local message = DiceMasterMessageEditor.message.EditBox:GetText()
	local channel = UIDropDownMenu_GetText( DiceMasterMessageEditor.channel )
	local delay = tonumber( DiceMasterMessageEditor.delay:GetText() )
	
	if not channel or type( channel ) ~= "string" then
		channel = "Say"
	end
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	if not message or message == "" or type( message ) ~= "string" then
		UIErrorsFrame:AddMessage( "Invalid message.", 1.0, 0.0, 0.0, 53, 5 );
		return
	end
	
	local messageData = {
		type = "message";
		message = message;
		channel = string.upper( channel );
		delay = delay;
	}
	
	if Me.ItemEditing then
		tinsert( Me.ItemEditing.effects, messageData )
	elseif Me.newItem then
		tinsert( Me.newItem.effects, messageData )
	end
	
	--tinsert( Me.Profile.inventory[Me.ItemEditingIndex].effects, scriptData )
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
	Me.EffectPicker_Close()
	Me.SoundPicker_Close()
	Me.AnimationPicker_Close()
	Me.ShopEditor_Close()
	Me.ScriptEditor_Close()
	--Me.ItemEditor_Close()
	Me.ModelPicker_Close()
	Me.CurrencyEditor_Close()
	Me.buffeditor:Hide()
	Me.removebuffeditor:Hide()
	Me.setdiceeditor:Hide()
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
