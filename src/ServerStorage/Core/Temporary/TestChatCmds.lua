local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RemoteService = ReplicatedModules.Services.RemoteService
local ChatMessageEvent = RemoteService:GetRemote('MakeChatMessage', 'RemoteEvent', false)
local ConsoleMessageEvent = RemoteService:GetRemote('MakeConsoleMessage', 'RemoteEvent', false)

local SystemsContainer = {}

local PREFIX = ";;"

-- // Module // --
local Module = {}

-- parse the command message
function Module:ParseChatCmd( LocalPlayer, commandName, ... )
	local Args = {...}
	--warn(LocalPlayer.Name, commandName, Args)

	-- DEBUG
	if commandName == "clear_data" then
		return SystemsContainer.DataEditService:WipeUserId( LocalPlayer.UserId )
	elseif commandName == "output_data" then
		return SystemsContainer.DataService:GetProfileFromPlayer( LocalPlayer ).Data
	end

	-- QUESTS
	-- ;;quest_start_id TrainerMockBattle
	if commandName == "quest_start_id" then
		return SystemsContainer.QuestService:GiveQuestOfId( LocalPlayer, unpack(Args) )
	elseif commandName == "quest_remove_uuid" then
		return SystemsContainer.QuestService:RemoveQuestOfUUID( LocalPlayer, unpack(Args) )
	elseif commandName == "quest_reward_id" then
		return SystemsContainer.QuestService:RewardQuestOfId( LocalPlayer, unpack(Args) )
	elseif commandName == "quest_append_contrib" then
		return SystemsContainer.QuestService:AppendQuestContributions( LocalPlayer, unpack(Args) )
	elseif commandName == "quest_increment_subquest" then
		return SystemsContainer.QuestService:IncrementSubQuestFromQuestUUID( LocalPlayer, unpack(Args) )
	end

	-- ITEMS
	if commandName == "item_give_id" then
		return SystemsContainer.InventoryService:GiveQuantityOfItemIdToPlayer( LocalPlayer, Args[1], tonumber(Args[2]) )
	elseif commandName == "item_remove_uuid" then
		return SystemsContainer.InventoryService:RemoveItemOfUUID(LocalPlayer, unpack(Args))
	end

	-- CURRENCY
	if commandName == "currency_copper" then
		return SystemsContainer.DataEditService:GiveCurrencyToPlayer( LocalPlayer, tonumber(Args[1]) )
	end

	-- LEVEL & EXPERIENCE
	if commandName == "exp_give" then
		return SystemsContainer.DataEditService:GiveExperienceToPlayer( LocalPlayer, tonumber(Args[1]) )
	--[[elseif commandName == "exp_remove" then
		-- TODO:
	elseif commandName == "level_give" then
		-- TODO:
	elseif commandName == "level_remove" then
		-- TODO:]]
	end

	-- LOOT TABLES
	if commandName == "loot_table_enemy_reward" then
		return SystemsContainer.LootTableService:RewardEnemyLootToPlayer( LocalPlayer, unpack(Args) )
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
		Module:OnChatted( LocalPlayer, chatMessage )
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