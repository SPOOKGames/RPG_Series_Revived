local TweenService = game:GetService('TweenService')

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Interface = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('Interface')

local SystemsContainer = {}

local CinematicsQueue = {}

local function SetProperties(Parent, Properties)
	for propName, propValue in pairs(Properties) do
		Parent[propName] = propValue
	end
end

local tweenInfo = TweenInfo.new(1)

-- // Module // --
local Module = {}

function Module:RunCinematicLabel( targetFrame, titleProperties, descriptionProperties, holdDuration )
	targetFrame.Visible = true
	SetProperties(targetFrame.Title, titleProperties)
	SetProperties(targetFrame.Description, descriptionProperties)

	TweenService:Create(targetFrame.Description, tweenInfo, {TextTransparency = 0}):Play()
	TweenService:Create(targetFrame.Divider, tweenInfo, {BackgroundTransparency = 0}):Play()
	local Tween = TweenService:Create(targetFrame.Title, tweenInfo, {TextTransparency = 0})
	Tween:Play()
	if Tween.PlaybackState ~= Enum.PlaybackState.Completed then
		Tween.Completed:Wait()
	end

	task.wait(holdDuration)

	TweenService:Create(targetFrame.Description, tweenInfo, {TextTransparency = 1}):Play()
	TweenService:Create(targetFrame.Divider, tweenInfo, {BackgroundTransparency = 1}):Play()
	Tween = TweenService:Create(targetFrame.Title, tweenInfo, {TextTransparency = 1})
	Tween:Play()
	if Tween.PlaybackState ~= Enum.PlaybackState.Completed then
		Tween.Completed:Wait()
	end

	targetFrame.Visible = false
end

function Module:AppendCinematic( frame, titleText, titleColor, descriptionText, descriptionColor, textDuration, priority )
	table.insert(CinematicsQueue, {
		Frame = frame,
		Title = { Text = titleText, TextColor3 = titleColor },
		Description = { Text = descriptionText, TextColor3 = descriptionColor },
		Duration = textDuration,
		Priority = priority,
	})
end

function Module:CinematicTopWhite( titleText, descriptionText, priority )
	Module:AppendCinematic( Interface.CinematicTop, titleText, Color3.new(1,1,1), descriptionText, Color3.new(1,1,1), 2, priority )
end

function Module:CinematicBottomWhite( titleText, descriptionText, priority )
	Module:AppendCinematic( Interface.CinematicBottom, titleText, Color3.new(1,1,1), descriptionText, Color3.new(1,1,1), 2, priority )
end

function Module:OnUpdate()
	table.sort(CinematicsQueue, function(a, b)
		return a.Priority < b.Priority
	end)

	while #CinematicsQueue > 0 do
		task.wait()
		local data = table.remove(CinematicsQueue, 1)
		Module:RunCinematicLabel(data.Frame, data.Title, data.Description, data.Duration)
	end
end

function Module:Start()

	task.defer(function()
		while true do
			Module:OnUpdate()
			task.wait(0.25)
		end
	end)

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module