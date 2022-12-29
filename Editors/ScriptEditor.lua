-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Script editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile
local IndentationLib = select( 2, ... ).IndentationLib

local DEFAULT_SYNTAX_COLORS = {
	keyword = { 0.6, 0.6, 1.0 },
	comment = { 1.0, 0.6, 0.6 },
	string = { 0.6, 1.0, 0.6 },
	boolean = { 0.5, 0.9, 1.0 },
	number = { 0.8, 0.2, 0.8 },
};

local RGBAPercToHex = function(r, g, b, a)
	if not(a) then a = 1 end
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	a = a <= 1 and a >= 0 and a or 1
	
	return string.format("%02x%02x%02x%02x",a*255 ,r*255, g*255, b*255)
end

local GetSyntaxColor = function(cat, default)
	local t
	if cat then
		t = DEFAULT_SYNTAX_COLORS[cat];
	end	
	if t then
		return t[1] or 1, t[2] or 1, t[3] or 1;
	end	
	return 1, 1, 1;
end

local GetSyntaxColorList = function()
	local syntaxColorTable = {};
	local booleans = { "true", "false", "nil" }
	local keywordColor = strconcat("|c"..RGBAPercToHex(GetSyntaxColor("keyword")))
	local commentColor = strconcat("|c"..RGBAPercToHex(GetSyntaxColor("comment")))
	local stringColor = strconcat("|c"..RGBAPercToHex(GetSyntaxColor("string")))
	local numberColor = strconcat("|c"..RGBAPercToHex(GetSyntaxColor("number")))
	local booleanColor = strconcat("|c"..RGBAPercToHex(GetSyntaxColor("boolean")))
	local T = IndentationLib.Tokens;

	local function colorCodeTokens(colorCode, ... )
		for Index = 1, select( '#', ... ) do
			syntaxColorTable[ select( Index, ... ) ] = colorCode;
		end
	end

	colorCodeTokens(keywordColor, T.KEYWORD)
	colorCodeTokens(keywordColor, T.CONCAT, T.VARARG, T.ASSIGNMENT, T.SIZE);
	colorCodeTokens(numberColor, T.NUMBER);
	colorCodeTokens(stringColor, T.STRING, T.STRING_LONG);
	colorCodeTokens(commentColor, T.COMMENT_SHORT, T.COMMENT_LONG);
	colorCodeTokens(keywordColor, T.ADD, T.SUBTRACT, T.MULTIPLY, T.DIVIDE, T.POWER, T.MODULUS);
	colorCodeTokens(keywordColor, T.EQUALITY, T.NOTEQUAL, T.LT, T.LTE, T.GT, T.GTE);
	colorCodeTokens(booleanColor, booleans)

	return syntaxColorTable
end

function Me.ScriptEditor_Refresh( effectIndex )
	local effect
	if DiceMasterScriptEditor.parent == DiceMasterItemEditor then
		if Me.ItemEditing then
			effect = Me.ItemEditing.effects[ effectIndex ]
		elseif Me.newItem then
			effect = Me.newItem.effects[ effectIndex ]
		end
		
		if effect then
			DiceMasterScriptEditorSaveButton:SetScript( "OnClick", function()
				Me.ScriptEditor_SaveEdits()
			end)	
		end
		
		Me.EffectEditingIndex = effectIndex
	else
		effect = Profile.traits[Me.editing_trait]["effects"]["script"] or nil
	end
	if not effect then 
		DiceMasterScriptEditor.script.EditBox:SetText( "" )
		DiceMasterScriptEditor.delay:SetText( "" )
		return
	end
	DiceMasterScriptEditor.script.EditBox:SetText( effect.code )
	DiceMasterScriptEditor.delay:SetText( effect.delay )
end

function Me.ScriptEditor_TestScript()
	local code = DiceMasterScriptEditor.script.EditBox:GetText()
	if not code or type(code) ~= "string" or code == "" then
		return
	end
	
	-- Insert item link, if present
	local item
	if Me.ItemEditing then
		item = Me.ItemEditing
	elseif Me.newItem then
		item = Me.newItem
	end
	
	if item and item.guid then
		local link = "[DiceMaster4Item:"..(UnitName("player"))..":"..(item.guid).."]";
		code = gsub(code,"%%[Ll]",link);
		print(code)
	end
	
	local codeFunc, err = loadstring( code );
	if not ( codeFunc ) then
		Me.PrintMessage( "|cFFFF0000Syntax error in DiceMaster item.|r", "SYSTEM" )
		Me.PrintMessage( "|cFFFF0000" .. err .. "|r" )
		return
	end
	pcall( codeFunc )
end

function Me.ScriptEditor_RunScript( data, item )
	if not data then
		return
	end

	if type( data ) == "table" and data.type and data.type == "script" and data.code then
		data = data
	else
		data = Profile.traits[ data ]["effects"]["script"]
	end
	
	local code = data.code
	
	-- Insert item link, if present
	if item and item.guid then
		local link = "[DiceMaster4Item:"..(UnitName("player"))..":"..(item.guid).."]";
		code = gsub(code,"%%[Ll]",link);
	end
	
	local codeFunc, err = loadstring( code );
	if not ( codeFunc ) then
		Me.PrintMessage( "|cFFFF0000Syntax error in DiceMaster item.|r", "SYSTEM" )
		Me.PrintMessage( "|cFFFF0000" .. err .. "|r" )
		return
	end
	pcall( codeFunc )
end

function Me.ScriptEditor_Delete()
	if DiceMasterScriptEditor.parent == DiceMasterTraitEditor then
		Profile.traits[Me.editing_trait]["effects"]["script"] = nil
	end
	
	PlaySound(840); 
	Me.ScriptEditor_Close()
end

function Me.ScriptEditor_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	local code = DiceMasterScriptEditor.script.EditBox:GetText()
	local delay = tonumber( DiceMasterScriptEditor.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	if not code or code == "" or type( code ) ~= "string" then
		UIErrorsFrame:AddMessage( "Invalid code.", 1.0, 0.0, 0.0 );
		return
	end
	
	local scriptData = {
		type = "script";
		code = code;
		delay = delay;
	}
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = scriptData
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = scriptData
	end
	
	Me.ScriptEditor_Close()
	Me.ItemEditorEffectsList_Update()
end

function Me.ScriptEditor_Save()	
	local code = DiceMasterScriptEditor.script.EditBox:GetText()
	local delay = tonumber( DiceMasterScriptEditor.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	if not code or code == "" or type( code ) ~= "string" then
		UIErrorsFrame:AddMessage( "Invalid code.", 1.0, 0.0, 0.0 );
		return
	end
	
	if DiceMasterScriptEditor.parent == DiceMasterItemEditor then
		local scriptData = {
			type = "script";
			code = code;
			delay = delay;
		}
		if Me.ItemEditing then
			tinsert( Me.ItemEditing.effects, scriptData )
		elseif Me.newItem then
			tinsert( Me.newItem.effects, scriptData )
		end
		Me.ItemEditorEffectsList_Update()
	else
		Profile.traits[Me.editing_trait]["effects"]["script"] = {
			code = code;
			delay = delay;
		}
	end
	
	Me.ScriptEditor_Close()
end
    
-------------------------------------------------------------------------------
-- Close the script editor window. Use this instead of a direct Hide()
--
function Me.ScriptEditor_Close()
	DiceMasterScriptEditor.script.EditBox:SetText( "" )
	DiceMasterScriptEditor.delay:SetText( "" )
	DiceMasterScriptEditorSaveButton:SetScript( "OnClick", function()
		Me.ScriptEditor_Save()
	end)
	DiceMasterScriptEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the script editor window.
--
function Me.ScriptEditor_Open( frame )
	Me.CloseAllEditors( nil, nil, true )
	if not frame then
		frame = DiceMasterTraitEditor;
		DiceMasterScriptEditorSaveButton:ClearAllPoints()
		DiceMasterScriptEditorSaveButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterScriptEditorCancelButton:ClearAllPoints()
		DiceMasterScriptEditorCancelButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterScriptEditorCancelButton:SetText( "Delete" )
	else
		DiceMasterScriptEditorSaveButton:ClearAllPoints()
		DiceMasterScriptEditorSaveButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterScriptEditorCancelButton:ClearAllPoints()
		DiceMasterScriptEditorCancelButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterScriptEditorCancelButton:SetText( "Cancel" )
	end
	DiceMasterScriptEditor.parent = frame
	DiceMasterScriptEditor:ClearAllPoints()
	DiceMasterScriptEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterScriptEditorSaveButton:SetScript( "OnClick", function()
		Me.ScriptEditor_Save()
	end)
	
	local syntaxColors = GetSyntaxColorList()
	IndentationLib.Enable( DiceMasterScriptEditor.script.EditBox, 4, syntaxColors or {} )
	
	Me.ScriptEditor_Refresh()
	DiceMasterScriptEditor:Show()
end
