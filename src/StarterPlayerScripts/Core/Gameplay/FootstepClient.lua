local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ReplicatedAssets = ReplicatedStorage:WaitForChild('Assets')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local MaidClassModule = ReplicatedModules.Classes.Maid

local FootstepSoundsInstance = ReplicatedAssets.Sounds.FootstepSounds

local SystemsContainer = {}

local ActiveCharacterData = { }
local CharacterToPlayerCache = { }

-- // Module // --
local Module = {}

function Module:CleanupPlayerInstance( PlayerInstance )
	-- cleanup old character for this player
	if CharacterToPlayerCache[ PlayerInstance ] then
		Module:CleanupCharacter( CharacterToPlayerCache[ PlayerInstance ] )
	end
	CharacterToPlayerCache[ PlayerInstance ] = nil
end

function Module:CleanupCharacter( CharacterInstance )
	if ActiveCharacterData[ CharacterInstance ] then
		ActiveCharacterData[ CharacterInstance ].Maid:Cleanup()
	end
	ActiveCharacterData[ CharacterInstance ] = nil
end

function Module:StopSoundInstances( SoundInstances )
	for _, soundInstance in ipairs( SoundInstances ) do
		soundInstance:Stop(0.15)
	end
end

function Module:UpdateCharacterMaterialSounds( CharacterData )
	-- if they are not walking, stop all sounds
	if not CharacterData.Walking then
		Module:StopSoundInstances( CharacterData.Sounds:GetChildren() )
		return
	end

	-- stop playing old material sound
	local CurrentMaterial = CharacterData.CurrentMaterial
	local LastMaterial = CharacterData.LastMaterial
	if LastMaterial and CurrentMaterial ~= LastMaterial then
		local LastMaterialSound = CharacterData.Sounds:FindFirstChild( LastMaterial )
		if LastMaterialSound then
			LastMaterialSound:Stop( 0.15 )
		end
	end
	CharacterData.LastMaterial = CurrentMaterial

	local CurrentMaterialSound = CharacterData.Sounds:FindFirstChild( CurrentMaterial )
	if not CurrentMaterialSound then
		return
	end

	-- edit playback speed
	local PlaybackSpeed = CharacterData.CurrentSpeed / (CharacterData.Humanoid.WalkSpeed * 0.75)
	CurrentMaterialSound.PlaybackSpeed = PlaybackSpeed

	-- play new material sound if not already playing
	if not CurrentMaterialSound.IsPlaying then
		CurrentMaterialSound:Play( 0.15 )
	end
end

function Module:OnCharacterAdded( PlayerInstance, CharacterInstance )
	local Humanoid = CharacterInstance and CharacterInstance:WaitForChild('Humanoid', 5)
	if not Humanoid then
		return
	end

	-- set the new character into the cache
	Module:CleanupPlayerInstance( PlayerInstance )
	CharacterToPlayerCache[ PlayerInstance ] = CharacterInstance

	-- character maid stuff
	local CharacterMaid = MaidClassModule.New()

	CharacterMaid:Give(Humanoid.Died:Connect(function()
		Module:CleanupCharacter( CharacterInstance )
	end))

	CharacterMaid:Give(Humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		ActiveCharacterData[ CharacterInstance ].CurrentMaterial = Humanoid.FloorMaterial.Name
	end))

	CharacterMaid:Give(Humanoid.Running:Connect(function(speed)
		-- must be a minumum speed to be walking
		ActiveCharacterData[ CharacterInstance ].CurrentSpeed = speed
		ActiveCharacterData[ CharacterInstance ].Walking = speed > (Humanoid.WalkSpeed / 2)
	end))

	local FootstepSoundClone = FootstepSoundsInstance:Clone()
	FootstepSoundClone.Parent = CharacterInstance

	ActiveCharacterData[ CharacterInstance ] = {
		Humanoid = Humanoid,
		Sounds = FootstepSoundClone,
		Walking = false,
		CurrentSpeed = 0,
		CurrentMaterial = false,
		LastMaterial = false,
		Maid = CharacterMaid,
	}

	-- disable normal character sounds
	for _, SoundInstance in ipairs( CharacterInstance.HumanoidRootPart:GetChildren() ) do
		if SoundInstance:IsA("Sound") then
			SoundInstance.Volume = 0
		end
	end
end

function Module:OnPlayerAdded( PlayerInstance )
	task.defer(function()
		Module:OnCharacterAdded( PlayerInstance, PlayerInstance.Character )
	end)
	PlayerInstance.CharacterAdded:Connect(function( CharacterInstance )
		Module:OnCharacterAdded( PlayerInstance, CharacterInstance )
	end)
end

function Module:Start()
	Module:OnPlayerAdded( LocalPlayer )
	for _, PlayerInstance in ipairs( Players:GetPlayers() ) do
		if PlayerInstance == LocalPlayer then
			continue
		end
		Module:OnPlayerAdded( PlayerInstance )
	end

	Players.PlayerAdded:Connect(function( PlayerInstance )
		Module:OnPlayerAdded( PlayerInstance )
	end)

	Players.PlayerRemoving:Connect(function( PlayerInstance )
		Module:CleanupPlayerInstance( PlayerInstance )
	end)

	RunService.Heartbeat:Connect(function(_)
		for CharacterInstance, CharacterData in pairs( ActiveCharacterData ) do
			if CharacterInstance.Humanoid.Health <= 0 then
				continue
			end
			Module:UpdateCharacterMaterialSounds( CharacterData )
		end
	end)
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
