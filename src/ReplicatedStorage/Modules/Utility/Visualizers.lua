local Debris = game:GetService('Debris')

local function SetProperties(BaseInstance, Properties)
	if typeof(Properties) == 'table' then
		for propName : string, propValue : any in pairs(Properties) do
			BaseInstance[propName] = propValue
		end
	end
end

local function SetDuration(BaseInstance, Duration)
	if typeof(Duration) == 'number' then
		Debris:AddItem(BaseInstance, Duration)
	end
end

-- //Module // --
local Module = {}

-- Set an Instance's properties through passing a table
function Module:SetProperties(BaseInstance, Properties)
	SetProperties(BaseInstance, Properties)
end

-- Create an Attachment at the position.
function Module:Attachment(Position, Duration)
	local Attachment = Instance.new('Attachment')
	Attachment.Name = 'VisualNode'
	Attachment.Visible = true
	Attachment.WorldPosition = Position
	Attachment.Parent = workspace.Terrain
	SetDuration(Attachment, Duration)
	return Attachment
end

-- Create a Beam at the position to the target position
local baseBeam = Instance.new('Beam')
baseBeam.Enabled = true
baseBeam.Width0 = 0.1
baseBeam.Width1 = 0.1
baseBeam.FaceCamera = true
baseBeam.LightInfluence = 0
baseBeam.Color = ColorSequence.new(Color3.new(1, 1, 1))
baseBeam.Brightness = 0 
baseBeam.LightInfluence = 0
baseBeam.LightEmission = 0
baseBeam.Segments = 2
function Module:Beam(StartPosition, EndPosition, Duration, Properties)
	local NodeA = Module:Attachment(StartPosition, Duration)
	NodeA.Visible = false
	local NodeB = Module:Attachment(EndPosition, Duration)
	NodeB.Visible = false
	local newBeam = baseBeam:Clone()
	newBeam.Attachment0 = NodeA
	newBeam.Attachment1 = NodeB
	newBeam.Parent = NodeA
	SetProperties(newBeam, Properties)
	return newBeam
end

-- Create a Part at the position
local basePart = Instance.new('Part')
basePart.Transparency = 0.7
basePart.Anchored = true
basePart.CanCollide = false
basePart.CanQuery = false
basePart.CanTouch = false
basePart.CastShadow = false
basePart.Color = Color3.new(1,1,1)
basePart.Massless = true
function Module:BasePart(CF, Duration, Properties)
	local newPart = basePart:Clone()
	newPart.CFrame = CF
	newPart.Parent = workspace.Terrain
	SetProperties(newPart, Properties)
	SetDuration(newPart, Duration)
	return newPart
end

-- Create a SphereHandleAdornment at the position.
function Module:CircleNode(CF, Properties, Duration)
	local Node = Module:BasePart(CF, Duration)
	Node.Transparency = 1
	local Adornment : SphereHandleAdornment = Instance.new('SphereHandleAdornment')
	Adornment.Visible = true
	Adornment.Radius = 0.1
	Adornment.AlwaysOnTop = true
	Adornment.Transparency = 0.7
	Adornment.Adornee = Node
	Adornment.Parent = Node
	SetProperties(Adornment, Properties)
	return Adornment, Node
end

function Module:VisualizeUDim2( Position, Properties, Duration )

	local LocalPlayer : Player = game:GetService('Players').LocalPlayer
	local ScreenGui : ScreenGui = LocalPlayer.PlayerGui:FindFirstChild('Visuals')
	if not ScreenGui then
		ScreenGui = Instance.new('ScreenGui')
		ScreenGui.Name = 'Visuals'
		ScreenGui.ResetOnSpawn = false
		ScreenGui.IgnoreGuiInset = true
		ScreenGui.Parent = LocalPlayer.PlayerGui
	end

	local Frame : Frame = Instance.new('Frame')
	Frame.Name = 'Visualize'
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.Size = UDim2.fromScale(0.05, 0.05)
	Frame.BorderSizePixel = 0
	Frame.Position = Position
	Instance.new('UIAspectRatioConstraint', Frame).AspectType = Enum.AspectType.ScaleWithParentSize

	SetProperties(Frame, Properties)
	SetDuration(Frame, Duration)
	Frame.Parent = ScreenGui

end

return Module
