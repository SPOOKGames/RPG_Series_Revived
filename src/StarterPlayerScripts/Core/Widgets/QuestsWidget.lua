local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local LocalAssets = LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('Assets')
local LocalModules = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Modules"))

local UserInterfaceUtility = LocalModules.Utility.UserInterface

local Interface = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('Interface')
local LHUDFrame = Interface:WaitForChild('LHUD')
local QuestMainFrame = Interface:WaitForChild('Quests')
local QuestsInfoFrame = QuestMainFrame.Info
local QuestsScrollFrame = QuestMainFrame.Scroll.Scroll
local QuestsOnScreenFrame = Interface:WaitForChild('OnscreenQuest')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedCore = require(ReplicatedStorage:WaitForChild('Core'))
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local ReplicatedData = ReplicatedCore.ReplicatedData

local MaidClassModule = ReplicatedModules.Classes.Maid
local QuestsConfigModule = ReplicatedModules.Data.Quests

local SystemsContainer = {}
local WidgetControllerModule = {}

local HIGHLIGHTED_QUEST_COLOR = Color3.fromRGB(207, 207, 16)
local CONTRIBUTION_COMPLETE_COLOR = Color3.fromRGB(50, 255, 50)
local WHITE_COLOR = Color3.new(1,1,1)

local LAST_CLICK_TIME = time()

local function SetProperties( Parent, Properties )
	for propName, propValue in pairs( Properties ) do
		Parent[propName] = propValue
	end
end

local function TweenSize( Frame, endSize, duration )
	Frame:TweenSize( endSize, Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, duration or 0.3 )
end

-- // Module // --
local Module = {}

Module.WidgetMaid = MaidClassModule.New()
Module.Open = false

Module.HighlightedQuestID = false
Module.HighlightedQuestUUID = false

Module.OnScreenQuestID = false
Module.OnScreenQuestUUID = false

function Module:UpdateContributionFrames( ParentFrame, questId, questUUID )
	local playerData = ReplicatedData:GetData("PlayerData")
	local questData = playerData.Quests[ questId ][ questUUID ]

	local questConfig = QuestsConfigModule:GetConfigFromId( questId )
	local questIndexConfig = questConfig.SubQuests[ questData.SubQuestIndex ]

	local contribUUIDs = { }
	for contribType, contribReqs in pairs( questIndexConfig.Contributions ) do
		local contribStringFormatFunc = QuestsConfigModule.ContributionStringFormating[ contribType ] or QuestsConfigModule.ContributionStringFormating.Default
		for id, value in pairs( contribReqs ) do
			local uuid = contribType.."_".. (typeof(value) == "number" and id or value)

			local Frame = ParentFrame:FindFirstChild( uuid )
			if not Frame then
				Frame = LocalAssets.UI.TemplateQuestContrib:Clone()
				Frame.Name = uuid
				Frame.TitleLabel.Text = contribStringFormatFunc(id, value)
				if typeof(value) ~= "number" then
					Frame.CountLabel:Destroy()
					Frame.TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
					Frame.TitleLabel.Position = UDim2.fromScale(0.187, 0.5)
				end
				Frame.Parent = ParentFrame
			end

			contribType = tostring(contribType)
			id = tostring(id)
			if typeof(value) == "number" then
				local amount = questData.Contributions[contribType] and questData.Contributions[contribType][id] or 0
				Frame.CountLabel.Text = amount.." / "..value
				Frame.TitleLabel.TextColor3 = (amount >= value) and CONTRIBUTION_COMPLETE_COLOR or WHITE_COLOR
				Frame.CountLabel.TextColor3 = Frame.TitleLabel.TextColor3
			else
				local contribArray = questData.Contributions[contribType]
				Frame.TitleLabel.TextColor3 = (contribArray and table.find(contribArray, value)) and CONTRIBUTION_COMPLETE_COLOR or WHITE_COLOR
			end

			table.insert(contribUUIDs, uuid)
		end
	end

	for _, Frame in ipairs( ParentFrame:GetChildren() ) do
		if Frame:IsA("Frame") and not table.find(contribUUIDs, Frame.Name) then
			Frame:Destroy()
		end
	end
end

function Module:UpdateOnScreenQuestData()
	QuestsOnScreenFrame.Visible = (Module.OnScreenQuestUUID ~= nil)
	if not Module.OnScreenQuestUUID then
		return
	end

	local playerData = ReplicatedData:GetData("PlayerData")
	if not playerData.Quests[ Module.OnScreenQuestID ] then
		Module:SetOnScreenQuestData(nil, nil)
		return
	end

	local questData = playerData.Quests[ Module.OnScreenQuestID ][ Module.OnScreenQuestUUID ]
	local questConfig = QuestsConfigModule:GetConfigFromId( Module.OnScreenQuestID )

	local totalContributionsNeeded = Module:GetTotalRequirementCount( Module.OnScreenQuestID, questData )
	local currentContributions = Module:GetQuestProgressCount( Module.OnScreenQuestID, questData )
	local decimal = currentContributions / math.max(totalContributionsNeeded, 1)

	SetProperties( QuestsOnScreenFrame.TitleFrame.Title, questConfig.Display.Title )
	QuestsOnScreenFrame.TitleFrame.Title.Text ..= string.format(" [%s / %s]", questData.SubQuestIndex, #questConfig.SubQuests)
	QuestsOnScreenFrame.TitleFrame.ContribCountLabel.Text = currentContributions.." / "..totalContributionsNeeded
	QuestsOnScreenFrame.TitleFrame.ProgressLabel.Text = 'PROGRESS : ' ..math.floor(decimal * 100).."%"
	TweenSize(QuestsOnScreenFrame.TitleFrame.BarBack.Bar, UDim2.fromScale(decimal, 1), nil)

	Module:UpdateContributionFrames(QuestsOnScreenFrame.Contributions.Scroll, Module.OnScreenQuestID,  Module.OnScreenQuestUUID)
end

function Module:SetOnScreenQuestData( questId, questUUID )
	if Module.OnScreenQuestUUID then
		local Frame = Module:GetQuestFrame( Module.OnScreenQuestID, Module.OnScreenQuestUUID )
		Frame.Title.TextColor3 = WHITE_COLOR
	end

	Module.OnScreenQuestID = questId
	Module.OnScreenQuestUUID = questUUID

	if questUUID then
		local Frame = Module:GetQuestFrame( questId, questUUID )
		Frame.Title.TextColor3 = HIGHLIGHTED_QUEST_COLOR
	end
	Module:UpdateOnScreenQuestData()
end

function Module:UpdateHighlightedQuestData()
	for _, Object in ipairs( QuestsInfoFrame:GetChildren() ) do
		if Object:IsA("GuiObject") then
			Object.Visible = (Module.HighlightedQuestUUID ~= nil)
		end
	end

	if not Module.HighlightedQuestUUID then
		return
	end

	local questConfig = QuestsConfigModule:GetConfigFromId( Module.HighlightedQuestID )
	SetProperties( QuestsInfoFrame.Title, questConfig.Display.Title )
	SetProperties( QuestsInfoFrame.Description.Label, questConfig.Display.Description )
	Module:UpdateContributionFrames(QuestsInfoFrame.Contributions.Scroll, Module.HighlightedQuestID, Module.HighlightedQuestUUID)
end

function Module:SetHighlightedQuestData( questId, questUUID )
	Module.HighlightedQuestID = questId
	Module.HighlightedQuestUUID = questUUID
	Module:UpdateHighlightedQuestData()
end

function Module:GetQuestFrame( questId, questUUID )
	local Frame = QuestsScrollFrame:FindFirstChild(questUUID)
	if not Frame then
		Frame = LocalAssets.UI.TemplateQuest:Clone()
		Frame.Name = questUUID

		local HighlightButton = UserInterfaceUtility:CreateActionButton({Parent = Frame})
		Module.WidgetMaid:Give(HighlightButton.Activated:Connect(function()
			if time() - LAST_CLICK_TIME < 0.2 then
				Module:SetOnScreenQuestData( questId, questUUID )
			else
				Module:SetHighlightedQuestData( questId, questUUID )
			end
			LAST_CLICK_TIME = time()
		end))

		Frame.Parent = QuestsScrollFrame
		Module.WidgetMaid:Give(Frame)
	end
	return Frame
end

function Module:GetTotalRequirementCount( questId, questData )
	local questConfig = QuestsConfigModule:GetConfigFromId( questId )
	local contribDict = questConfig.SubQuests[ questData.SubQuestIndex ].Contributions
	local totalCount = 0
	for _, contributions in pairs( contribDict ) do
		for _, value in pairs( contributions ) do
			totalCount += typeof(value) == "number" and value or 1
		end
	end
	return totalCount
end

function Module:GetQuestProgressCount( _, questData )
	local totalCount = 0
	for _, contributions in pairs( questData.Contributions ) do
		for _, value in pairs( contributions ) do
			totalCount += typeof(value) == "number" and value or 1
		end
	end
	return totalCount
end

function Module:UpdateWidget()
	local playerData = ReplicatedData:GetData("PlayerData")
	if not playerData then
		return
	end

	local uuidCache = { }
	local lastQuestId = false
	for questId, uuids in pairs( playerData.Quests ) do
		for questUUID, questData in pairs( uuids ) do
			if Module.Open then
				local questConfig = QuestsConfigModule:GetConfigFromId( questId )

				local totalContributionsNeeded = Module:GetTotalRequirementCount( questId, questData )
				local currentContributions = Module:GetQuestProgressCount( questId, questData )

				local decimal = currentContributions / math.max(totalContributionsNeeded, 1)

				local Frame = Module:GetQuestFrame( questId, questUUID )
				SetProperties( Frame.Title, questConfig.Display.Title )
				Frame.Title.Text ..= string.format(" [%s / %s]", questData.SubQuestIndex, #questConfig.SubQuests)
				Frame.Title.TextColor3 = Module.OnScreenQuestUUID==questUUID and HIGHLIGHTED_QUEST_COLOR or WHITE_COLOR
				Frame.ContribCountLabel.Text = currentContributions.." / "..totalContributionsNeeded
				Frame.ProgressLabel.Text = 'PROGRESS : ' ..math.floor(decimal * 100).."%"
				TweenSize(Frame.BarBack.Bar, UDim2.fromScale(decimal, 1), nil)
			end
			table.insert(uuidCache, questUUID)
		end
		lastQuestId = questId
	end

	for _, Frame in ipairs( QuestsScrollFrame:GetChildren() ) do
		if Frame:IsA("Frame") and not table.find( uuidCache, Frame.Name ) then
			Frame:Destroy()
		end
	end

	if not table.find( uuidCache, Module.HighlightedQuestUUID ) then
		if #uuidCache > 0 then
			Module:SetHighlightedQuestData( lastQuestId, uuidCache[#uuidCache] )
		else
			Module:SetHighlightedQuestData( nil, nil )
		end
	else
		Module:UpdateHighlightedQuestData()
	end

	if not table.find( uuidCache, Module.OnScreenQuestUUID ) then
		if #uuidCache > 0 then
			Module:SetOnScreenQuestData( lastQuestId, uuidCache[#uuidCache] )
		else
			Module:SetOnScreenQuestData( nil, nil )
		end
	else
		Module:UpdateOnScreenQuestData()
	end
end

function Module:OpenWidget()
	if Module.Open then
		return
	end
	Module.Open = true
	-- when widget opens

	QuestMainFrame.Visible = true
	task.defer(function()
		Module:UpdateWidget()
	end)
end

function Module:CloseWidget()
	if not Module.Open then
		return
	end
	Module.Open = false
	QuestMainFrame.Visible = false
	Module.WidgetMaid:Cleanup()
end

function Module:Start()
	task.defer(function()
		QuestMainFrame.Visible = false
		QuestsOnScreenFrame.Visible = false
		Module:CloseWidget()
	end)

	UserInterfaceUtility:CreateActionButton({Parent = LHUDFrame.RButtons.Quests}).Activated:Connect(function()
		if Module.Open then
			Module:CloseWidget()
		else
			Module:OpenWidget()
		end
	end)

	QuestMainFrame.Close.Button.Activated:Connect(function()
		Module:CloseWidget()
	end)

	ReplicatedData.OnUpdate:Connect(function(category, _)
		if category == 'PlayerData' then
			Module:UpdateWidget()
		end
	end)
end

function Module:Init(ParentController, otherSystems)
	WidgetControllerModule = ParentController
	SystemsContainer = otherSystems
end

return Module
