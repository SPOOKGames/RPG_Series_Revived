local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RemoteService = ReplicatedModules.Services.RemoteService
local ChatMessageEvent = RemoteService:GetRemote('MakeChatMessage', 'RemoteEvent', false)
local ConsoleMessageEvent = RemoteService:GetRemote('MakeConsoleMessage', 'RemoteEvent', false)

local SystemsContainer = {}

local PREFIX = ";;"
local Whitelist = false -- { 00000, 00000, }

-- // Module // --
local Module = {}

-- parse the command message
function Module:ParseChatCmd( LocalPlayer, commandName, ... )
	local Args = {...}
	--warn(LocalPlayer.Name, commandName, Args)

	-- DEBUG
	if commandName == "clear_data" then
		return SystemsContainer.DataEditServer:WipeUserId( LocalPlayer.UserId )
	elseif commandName == "output_data" then
		return SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer ).Data
	end

	-- QUESTS
	-- ;;quest_start_id TrainerMockBattle
	if commandName == "quest_start_id" then
		return SystemsContainer.QuestServer:GiveQuestOfId( LocalPlayer, unpack(Args) )
	elseif commandName == "quest_remove_uuid" then
		return SystemsContainer.QuestServer:RemoveQuestOfUUID( LocalPlayer, unpack(Args) )
	elseif commandName == "quest_reward_id" then
		return SystemsContainer.QuestServer:RewardQuestOfId( LocalPlayer, unpack(Args) )
	elseif commandName == "quest_append_contrib" then
		return SystemsContainer.QuestServer:AppendQuestContributions( LocalPlayer, unpack(Args) )
	elseif commandName == "quest_increment_subquest" then
		return SystemsContainer.QuestServer:IncrementSubQuestFromQuestUUID( LocalPlayer, unpack(Args) )
	end

	-- ITEMS
	if commandName == "item_give_id" then
		for i, value in ipairs(Args) do
			if tonumber( value ) then
				continue
			end
			SystemsContainer.InventoryServer:GiveQuantityOfItemIdToPlayer(
				LocalPlayer, value, tonumber(Args[i+1])
			)
		end
		return "Success"
	elseif commandName == "item_remove_uuid" then
		return SystemsContainer.InventoryServer:RemoveItemOfUUID(LocalPlayer, unpack(Args))
	end

	-- CURRENCY
	if commandName == "currency_copper" then
		return SystemsContainer.DataEditServer:GiveCurrencyToPlayer( LocalPlayer, tonumber(Args[1]) )
	end

	-- LEVEL & EXPERIENCE
	if commandName == "exp_give" then
		return SystemsContainer.DataEditServer:GiveExperienceToPlayer( LocalPlayer, tonumber(Args[1]) )
	--[[elseif commandName == "exp_remove" then
		-- TODO:
	elseif commandName == "level_give" then
		-- TODO:
	elseif commandName == "level_remove" then
		-- TODO:]]
	end

	-- LOOT TABLES
	if commandName == "loot_table_enemy_reward" then
		return SystemsContainer.LootTableServer:RewardEnemyLootToPlayer( LocalPlayer, unpack(Args) )
	end

	-- DIALOGUE
	-- ;;start_dialogue TestDialogue1
	if commandName == "start_dialogue" then
		return SystemsContainer.DialogueServer:StartDialogue( LocalPlayer, unpack(Args) )
	elseif commandName == "close_dialogue" then
		return SystemsContainer.DialogueServer:CloseDialogue( LocalPlayer )
	end

	return false, "NO SUCH COMMAND"
end

-- when a player chats, check if its a command message
function Module:OnChatted( LocalPlayer, chatMessage )
	if string.sub(chatMessage, 1, #PREFIX) ~= PREFIX then
		return
	end
	chatMessage = string.sub(chatMessage, #PREFIX + 1) -- remove the prefix

	-- parse the chat command and group return values to a table
	local splits = string.split(chatMessage, " ")
	local Returned = { splits, Module:ParseChatCmd(LocalPlayer, unpack(splits)) }
	ConsoleMessageEvent:FireClient(LocalPlayer, HttpService:JSONEncode(Returned))
end

function Module:OnPlayerAdded( LocalPlayer )
	LocalPlayer.Chatted:Connect(function(chatMessage)
		if (not Whitelist) or table.find(Whitelist, LocalPlayer.UserId) then
			Module:OnChatted( LocalPlayer, chatMessage )
		end
	end)
end

function Module:Start()
	for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
		Module:OnPlayerAdded(LocalPlayer)
	end

	Players.PlayerAdded:Connect(function(LocalPlayer)
		Module:OnPlayerAdded(LocalPlayer)
	end)
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems.ParentSystems
end

return Module