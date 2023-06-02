
-- // Module // --
local Module = {}

function Module:SetupModelForViewport( ClonedModel )
	local Humanoid = ClonedModel:FindFirstChildOfClass("Humanoid")
	if Humanoid then
		Humanoid.HealthDisplayDistance = Enum.HumanoidHealthDisplayType.AlwaysOff
		Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	if ClonedModel:IsA("Model") and ClonedModel.PrimaryPart then
		ClonedModel.PrimaryPart.Anchored = true
	end
	return ClonedModel
end

function Module:SetupModelViewport(Viewport, Model, CameraCFrame, ModelCFrame)
	assert( typeof(Model) == "Instance", "Passed Model must be an Instance." )

	local Camera = Module:ViewportCamera(Viewport)
	if Viewport:GetAttribute("Current") == Model.Name then
		return Viewport:FindFirstChild(Model.Name), Camera
	end

	Viewport:SetAttribute("Current", Model.Name)
	Model = Module:SetupModelForViewport( Model:Clone() )
	Model:SetPrimaryPartCFrame( ModelCFrame )
	Model.Parent = Viewport
	Camera.CFrame = CameraCFrame
	return Model, Camera
end

function Module:ViewportCamera(ViewportFrame)
	local Camera = ViewportFrame:FindFirstChildOfClass('Camera')
	if not Camera then
		Camera = Instance.new('Camera')
		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame = CFrame.new()
		Camera.Parent = ViewportFrame
		ViewportFrame.CurrentCamera = Camera
	end
	return Camera
end

function Module:ClearViewport(ViewportFrame)
	for _, item in ipairs(ViewportFrame:GetChildren()) do
		if not item:IsA('Camera') then
			item:Destroy()
		end
	end
end

return Module
