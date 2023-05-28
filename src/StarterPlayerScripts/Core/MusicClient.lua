local TweenService = game:GetService('TweenService')

local MusicData = require(script.Parent.Parent.Modules.Data.MusicData)

local SystemsContainer = {}

local MUSIC_FADE_TWEEN = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

local MusicSoundInstance = Instance.new('Sound')
MusicSoundInstance.Name = 'MusicBackground'
MusicSoundInstance.Looped = true
MusicSoundInstance.Parent = workspace

local CurrentSoundId = false
local CurrentSoundData = false

local function SetProperties( Parent, Properties )
	for propName, propValue in pairs(Properties) do
		Parent[propName] = propValue
	end
end

-- // Module // --
local Module = {}

-- Play a random sound with volume fade
function Module:PlayRandomSong()
	local RandomId = MusicData.SongIds[ Random.new():NextInteger(1, #MusicData.SongIds) ]
	while CurrentSoundId == RandomId do
		RandomId = MusicData.SongIds[ Random.new():NextInteger(1, #MusicData.SongIds) ]
	end
	CurrentSoundData = MusicData.SongData[ RandomId ]

	local Tween = TweenService:Create(MusicSoundInstance, MUSIC_FADE_TWEEN, {Volume = 0})
	Tween:Play()
	Tween.Completed:Wait()
	MusicSoundInstance:Stop()

	SetProperties( MusicSoundInstance, CurrentSoundData.Properties )
	MusicSoundInstance.Volume = 0
	MusicSoundInstance:Play()

	TweenService:Create(MusicSoundInstance, MUSIC_FADE_TWEEN, {Volume = CurrentSoundData.Properties.Volume}):Play()
end

-- Yield until the correct timing before crossfading songs
function Module:AwaitSongCrossfadeTime()
	if not MusicSoundInstance.IsLoaded then
		MusicSoundInstance.Loaded:Wait()
	end
	task.wait( MusicSoundInstance.TimeLength - MUSIC_FADE_TWEEN.Time )
end

function Module:Start()

	task.defer(function()
		while true do
			Module:PlayRandomSong()
			Module:AwaitSongCrossfadeTime()
		end
	end)

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
