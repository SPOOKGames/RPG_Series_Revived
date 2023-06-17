local StarterGui = game:GetService('StarterGui')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RemoteService = ReplicatedModules.Services.RemoteService
local ChatMessageEvent = RemoteService:GetRemote('MakeChatMessage', 'RemoteEvent', false)
local ConsoleMessageEvent = RemoteService:GetRemote('MakeConsoleMessage', 'RemoteEvent', false)

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:CreateChatMessage(Text, R,G,B)
	StarterGui:SetCore("ChatMakeSystemMessage", {
		Text = "[SERVER] - " .. tostring(Text),
		Font = Enum.Font.SourceSansBold,
		Colour = R and Color3.fromRGB(R,G,B) or Color3.new(1,1,1),
		FontSize = Enum.FontSize.Size18,
	})
end

function Module:CreateDevConsoleMessage(Text)
	print("[SERVER] - " .. tostring(Text))
end

function Module:Start()
	ChatMessageEvent.OnClientEvent:Connect(function(...)
		Module:CreateChatMessage(...)
	end)

	ConsoleMessageEvent.OnClientEvent:Connect(function(...)
		Module:CreateDevConsoleMessage(...)
	end)
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module