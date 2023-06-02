local Debris = game:GetService('Debris')
local TweenService = game:GetService('TweenService')

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:ApplyTemporaryMassless( Model, Duration )
	local MasslessInstances = { }
	for _, BasePart in ipairs( Model:GetDescendants() ) do
		if BasePart:IsA('BasePart') and not BasePart.Massless then
			BasePart.Massless = true
			table.insert(MasslessInstances, BasePart)
		end
	end
	task.delay(Duration, function()
		for _, BasePart in ipairs( MasslessInstances ) do
			BasePart.Massless = false
		end
	end)
end

local ANTI_GRAVITY_FORCE = Vector3.new(0, 650, 0)

function Module:Knockback( PrimaryPart, AttackOrigin )
	-- TODO: disable player movement during knockback
	Module:ApplyTemporaryMassless( PrimaryPart.Parent, 0.45 )

	local EnemyPosition = PrimaryPart.Position
	local DirectionCFrame = CFrame.lookAt(EnemyPosition, Vector3.new(AttackOrigin.X, EnemyPosition.Y, AttackOrigin.Z))
	PrimaryPart.Parent:SetPrimaryPartCFrame( DirectionCFrame )

	local forceAttachment = Instance.new('Attachment')
	forceAttachment.Name = 'ForceAttachment'
	forceAttachment.Parent = PrimaryPart
	Debris:AddItem(forceAttachment, 0.45)

	local upVelocityForce = Instance.new('VectorForce')
	upVelocityForce.Name = 'antiGravity'
	upVelocityForce.Attachment0 = forceAttachment
	upVelocityForce.ApplyAtCenterOfMass = true
	upVelocityForce.RelativeTo = Enum.ActuatorRelativeTo.World
	upVelocityForce.Force = ANTI_GRAVITY_FORCE
	upVelocityForce.Parent = forceAttachment

	local bodyGyro = Instance.new('BodyGyro')
	bodyGyro.Name = 'orientatorGyro'
	bodyGyro.CFrame = DirectionCFrame
	bodyGyro.D = 100
	bodyGyro.P = 500
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.Parent = PrimaryPart
	Debris:AddItem(bodyGyro, 0.45)

	local bodyVelocity = Instance.new('BodyVelocity')
	bodyVelocity.Velocity = PrimaryPart.CFrame.LookVector * -47
	bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
	bodyVelocity.P = 1500
	bodyVelocity.Parent = PrimaryPart
	Debris:AddItem(bodyVelocity, 0.45)

	TweenService:Create( bodyVelocity, TweenInfo.new(0.7), {Velocity = Vector3.zero} ):Play()
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
