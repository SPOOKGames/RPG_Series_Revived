local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local LocalAssets = LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('Assets')

local Interface = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('Interface')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService('TweenService')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RemoteService = ReplicatedModules.Services.RemoteService
local NotificationEvent = RemoteService:GetRemote("NotificiationEvent", "RemoteEvent", false)

local SystemsContainer = {}

local NotificationQueue = {}
local ActiveNotifications = 0

local MAX_ACTIVE_NOTIFICATIONS = 4

local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

local function SetProperties( Parent, Properties )
	for propName, propValue in pairs(Properties) do
		Parent[propName] = propValue
	end
end

-- // Module // --
local Module = {}

function Module:Notify(titleText, titleColor, descriptionText, descriptionColor, duration)
	table.insert(NotificationQueue, {titleText, titleColor, descriptionText, descriptionColor, duration})
end

function Module:Update()

	while ActiveNotifications < MAX_ACTIVE_NOTIFICATIONS and #NotificationQueue > 0 do
		ActiveNotifications += 1

		local Data = table.remove(NotificationQueue, 1)
		local titleText, titleColor, descriptionText, descriptionColor, duration = unpack(Data)

		local NotificationFrame = LocalAssets.UI.TemplateNotification:Clone()
		NotificationFrame.Name = ActiveNotifications
		NotificationFrame.LayoutOrder = ActiveNotifications

		NotificationFrame.Title.TextTransparency = 0
		NotificationFrame.Description.TextTransparency = 0
		NotificationFrame.Divider.BackgroundTransparency = 0

		SetProperties(NotificationFrame.Title, {Text = titleText, TextColor3 = titleColor})
		SetProperties(NotificationFrame.Description, {Text = descriptionText, TextColor3 = descriptionColor})

		NotificationFrame.Parent = Interface.Notifications

		task.delay(duration, function()
			ActiveNotifications -= 1
			TweenService:Create(NotificationFrame.Title, tweenInfo, {TextTransparency = 1}):Play()
			TweenService:Create(NotificationFrame.Description, tweenInfo, {TextTransparency = 1}):Play()
			local Tween = TweenService:Create(NotificationFrame.Divider, tweenInfo, {BackgroundTransparency = 1})
			Tween:Play()
			if Tween.PlaybackState ~= Enum.PlaybackState.Completed then
				Tween.Completed:Wait()
			end
			NotificationFrame:Destroy()
		end)
	end

end

function Module:Start()

	NotificationEvent.OnClientEvent:Connect(function(...)
		Module:Notify(...)
	end)
	NotificationEvent:FireServer()

	task.spawn(function()
		while true do
			task.wait(0.25)
			Module:Update()
		end
	end)

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
