-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Script editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

function Me.ScriptEditor_Refresh()
	DiceMasterScriptEditor.script.EditBox:SetText("")
	DiceMasterScriptEditor.delay:SetText("")
	
	Me.EffectEditingIndex = nil;
end

function Me.ScriptEditor_RunScript( data )
	if not data or not data.type or not data.code or data.type ~= "script" then
		return
	end
	
	local codeFunc, err = loadstring( data.code );
	if not ( codeFunc ) then
		Me.PrintMessage( "|cFFFF0000Syntax error in DiceMaster item.|r", "SYSTEM" )
		Me.PrintMessage( "|cFFFF0000" .. err .. "|r" )
		return
	end
	pcall( codeFunc )
end

function Me.ScriptEditor_Load( effectIndex )
	
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
	
	DiceMasterScriptEditor.script.EditBox:SetText( effect.code )
	DiceMasterScriptEditor.delay:SetText( effect.delay )
	
	DiceMasterScriptEditorSaveButton:SetScript( "OnClick", function()
		Me.ScriptEditor_SaveEdits()
	end)	
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
		UIErrorsFrame:AddMessage( "Invalid code.", 1.0, 0.0, 0.0, 53, 5 );
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
		UIErrorsFrame:AddMessage( "Invalid code.", 1.0, 0.0, 0.0, 53, 5 );
		return
	end
	
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
	
	Me.ScriptEditor_Close()
	Me.ItemEditorEffectsList_Update()
end
    
-------------------------------------------------------------------------------
-- Close the script editor window. Use this instead of a direct Hide()
--
function Me.ScriptEditor_Close()
	Me.ScriptEditor_Refresh()
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
		frame = DiceMasterItemEditor;
	end
	DiceMasterScriptEditor:ClearAllPoints()
	DiceMasterScriptEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterScriptEditorSaveButton:SetScript( "OnClick", function()
		Me.ScriptEditor_Save()
	end)	
	
	Me.ScriptEditor_Refresh()
	DiceMasterScriptEditor:Show()
end
