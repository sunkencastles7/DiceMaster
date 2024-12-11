-------------------------------------------------------------------------------
-- Dice Master (C) 2024 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Examine Frame
--

local Me = DiceMaster4
local Profile = Me.Profile

local models = {
	{ name="cratestack", fileID=1349572, x=-2, y=-2.5, z=-0.6, yaw=(math.pi/2), scale=0.5 },
	{ name="cratestack2", fileID=1349035, x=-2, y=2.5, z=-0.6, scale=0.5 },
	{ name="table", fileID=1305544, x=0, y=0, z=-0.8, scale=0.5 },
	{ name="chair", fileID=1305333, x=1.5, y=0, z=-0.8, yaw=math.pi, scale=0.5 },
	{ name="rug", fileID=942909, x=0, y=0, z=-0.9, scale=0.5 },
	{ name="Fingerprint Dust", fileID=1305534, x=-0.5, y=-1, z=0, scale=0.5, yaw=0.3, button="DustButton", width=48, height=48, isTool=true },
	{ name="Magnifying Glass", fileID=4391087, x=0.3, y=-1, z=0, yaw=0.3, scale=0.5, button="MagnifyingGlass", width=48, height=48, isTool=true },
	{ name="Lockpicking Tools", fileID=1305334, x=0.7, y=1, z=0, scale=0.4, yaw=0.3, button="LockpickButton", width=48, height=48, isTool=true, toolModel=1305338 },
	{ name="chest", fileID=219372, x=0, y=0, z=0, scale=0.3 },
	{ name="Interact", fileID=166027, x=0.35, y=0, z=0.3, scale=0.5, animation=158, button="InteractButton", width=16, height=16 },
};


local function CreateActor(name, fileID, x, y, z, scale, pitch, yaw, roll, button, buttonWidth, buttonHeight, isTool, toolModel)
	local actor = DiceMasterExamineFrame.ModelScene:CreateActor("DiceMasterExamine" .. name .. "Model", "DiceMasterPetFrameActorTemplate"); 
	actor:SetScale( scale or 1 );
	actor:SetPosition( x or 0, y or 0, z or 0 );
	actor:SetAnimationBlendOperation(0);
	actor:SetAlpha(1);
	actor:SetModelByFileID( fileID );
	actor:SetPitch( pitch or 0 );
	actor:SetYaw( yaw or 0 );
	actor:SetRoll( roll or 0 );

	if button then
		local interactButton = CreateFrame("Button", "DiceMasterExamineFrame" .. name.. "Button", DiceMasterExamineFrame);
		interactButton:RegisterForClicks("RightButtonDown");
		interactButton:SetSize( buttonWidth or 16, buttonHeight or 16 );
		interactButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:AddLine( name );
			GameTooltip:AddLine( "<Right Click to Pick Up>", 0.5, 0.5, 0.5 );
			GameTooltip:Show();
			SetCursor( cursor or "INTERACT_CURSOR" );
		end);
		interactButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide();
			ResetCursor();
		end);
		if isTool then
			interactButton:SetScript("OnClick", function(self)
				actor:Hide();
				interactButton:Hide()
				DiceMasterExamineFrame.ActiveTool:SetModel( toolModel or fileID )
				DiceMasterExamineFrame.ActiveTool:SetPitch( 0.5 )
				DiceMasterExamineFrame.ActiveTool:Show()
				DiceMasterExamineFrame.ModelScene:HookScript("OnMouseUp", function(self, button)
					if button=="RightButton" then
						DiceMasterExamineFrame.ActiveTool:ClearModel();
						DiceMasterExamineFrame.ActiveTool:Hide();
						actor:Show();
						interactButton:Show();
					end
				end)
			end);
		end
		actor.interactButton = interactButton;

		DiceMasterExamineFrame.ModelScene:HookScript("OnUpdate", function(self)
			local positionVector = CreateVector3D(actor:GetPosition());
			positionVector:ScaleBy(actor:GetScale());
			local x, y, depthScale = self:Transform3DPointTo2D(positionVector:GetXYZ());

			if (not x or not y or not depthScale) then
				return;
			end

			local interactButton = actor.interactButton;
			interactButton:ClearAllPoints();
			interactButton:SetParent(self);
			depthScale = Lerp(.05, 1, ClampedPercentageBetween(depthScale, 0.8, 1))
			interactButton:SetScale(depthScale);
			local inverseScale = self:GetEffectiveScale() * depthScale;
			interactButton:SetPoint("CENTER", self, "BOTTOMLEFT", (x / inverseScale) + 2, (y / inverseScale) - 4);
		end)
	end
end

function Me.ExamineFrame_OnLoad( self )
	local modelScene = self.ModelScene

	modelScene.cameras = {};
	modelScene.actorTemplate = "DiceMasterPetFrameActorTemplate";
	modelScene.tagToActor = {};
	modelScene.tagToCamera = {};

	modelScene:SetLightPosition(0, 0, 3);
	modelScene:SetLightDirection(0, 0, -3);
	modelScene:SetLightDiffuseColor(0.3, 0.3, 0.3);
	
	local camera = CameraRegistry:CreateCameraByType("OrbitCamera");
	camera.panningXOffset = 0;
	camera.panningYOffset = 0;
	camera.modelSceneCameraInfo = {
		flags = 0,
		}
	modelScene:AddCamera(camera);
	camera:SetTarget(0, 0, -0.3);
	camera:SnapToTargetInterpolationTarget();
	camera:SetPitch(0.7);
	camera:SetMinZoomDistance(1);
	camera:SetMaxZoomDistance(2.7);
	camera:SetZoomDistance(2);

	for i = 1, #models do
		local model = models[i];
		CreateActor( model.name, model.fileID, model.x, model.y, model.z, model.scale, model.pitch, model.yaw, model.roll, model.button, model.width, model.height, model.isTool, model.toolModel );
	end

	modelScene.ControlFrame:SetModelScene(modelScene);
end