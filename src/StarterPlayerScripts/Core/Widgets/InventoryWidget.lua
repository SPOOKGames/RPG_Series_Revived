local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local LocalAssets = LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('Assets')
local LocalModules = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Modules"))

local UserInterfaceUtil = LocalModules.Utility.UserInterface
local ViewportUtility = LocalModules.Utility.Viewport

local Interface = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('Interface')
local LHUDFrame = Interface.LHUD
local InventoryFrame = Interface.Inventory

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedAssets = ReplicatedStorage:WaitForChild('Assets')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))
local ReplicatedCore = require(ReplicatedStorage:WaitForChild('Core'))

local MaidClassModule = ReplicatedModules.Classes.Maid
local ItemsConfigModule = ReplicatedModules.Data.Items
local AssetService = ReplicatedModules.Services.AssetService

local ReplicatedData = ReplicatedCore.ReplicatedData

local SystemsContainer = {}
local WidgetControllerModule = {}

local function SetProperties( Parent, Properties )
	for propName, propValue in pairs( Properties ) do
		Parent[propName] = propValue
	end
	return Parent
end

-- // Module // --
local Module = {}

Module.WidgetMaid = MaidClassModule.New()
Module.Open = false

function Module:GetInventoryFrame( itemId, itemUUID, itemData )
	local Frame = InventoryFrame.Scroll:FindFirstChild(itemUUID)
	if not Frame then
		local itemConfig = ItemsConfigModule:GetConfigFromId(itemId)

		Frame = LocalAssets.UI.TemplateInventory:Clone()
		Frame.Name = itemUUID
		--Frame.LayoutOrder =
		SetProperties( Frame.Title, itemConfig.Display.Title )

		local iconValue = itemConfig.Display.Icon
		local iconType = typeof(iconValue)
		if iconType == "table" then -- setup viewport model
			Frame.Icon.Visible = false
			Frame.Viewport.Visible = true
			local ViewportModel = AssetService:GetEquipmentByName( itemConfig.Model )
			if ViewportModel then
				ViewportUtility:SetupModelViewport(Frame.Viewport, ViewportModel, iconValue.CameraCFrame, iconValue.ModelCFrame)
			end
		elseif iconType == "number" or iconType == "string" then -- setup icon label
			Frame.Icon.Image = iconType == "number" and ("rbxassetid://"..iconType) or iconType
			Frame.Icon.Visible = true
			Frame.Viewport.Visible = false
			ViewportUtility:ClearViewport(Frame.Viewport)
		else -- invalid display
			Frame.Icon.Visible = false
			Frame.Viewport.Visible = false
			warn("Unsupported icon type; "..iconType)
		end

		UserInterfaceUtil:CreateActionButton({Parent = Frame}).Activated:Connect(function()
			print( itemUUID, itemId, itemData )
		end)

		Frame.Parent = InventoryFrame.Scroll
	end
	return Frame
end

function Module:UpdateWidget()
	local PlayerData = ReplicatedData:GetData('PlayerData')
	if not PlayerData then
		return
	end

	local uuidCache = { }

	-- create any additional frames for new items that appear in the inventory
	-- and update current items
	for itemId, cache in pairs( PlayerData.Inventory ) do
		for itemUUID, itemData in pairs(cache) do
			local itemConfig = ItemsConfigModule:GetConfigFromId(itemId)
			if not itemConfig then
				warn("Could not find item config for id: " .. itemId)
				continue
			end

			local Frame = Module:GetInventoryFrame( itemId, itemUUID, itemData )
			if not Frame then
				continue
			end

			Frame.Quantity.Visible = (itemData.Quantity and itemData.Quantity > 1)
			if Frame.Quantity.Visible then
				local newText = tostring(itemData.Quantity)
				if itemConfig.MaxQuantity then
					newText = newText..' / '..itemConfig.MaxQuantity
				end
				Frame.Quantity.Text = newText
			end

			table.insert(uuidCache, itemUUID)
		end
	end

	-- cleanup any old item frames which are no longer in the inventory
	for _, Frame in ipairs( InventoryFrame.Scroll:GetChildren() ) do
		if not Frame:IsA("Frame") then
			continue
		end
		if not table.find(uuidCache, Frame.Name) then
			Frame:Destroy()
		end
	end
end

function Module:OpenWidget()
	if Module.Open then
		return
	end
	Module.Open = true
	-- when widget opens
	Module:UpdateWidget()
	InventoryFrame.Visible = true
end

function Module:CloseWidget()
	if not Module.Open then
		return
	end
	Module.Open = false
	InventoryFrame.Visible = false
	Module.WidgetMaid:Cleanup()
end

function Module:Start()
	task.defer(function()
		InventoryFrame.Visible = false
		Module:CloseWidget()
	end)

	UserInterfaceUtil:CreateActionButton({Parent = LHUDFrame.MButtons.Inventory}).Activated:Connect(function()
		if Module.Open then
			Module:CloseWidget()
		else
			Module:OpenWidget()
		end
	end)

	InventoryFrame.CloseButton.Button.Activated:Connect(function()
		Module:CloseWidget()
	end)

	ReplicatedData.OnUpdate:Connect(function(Category, _)
		if Category == 'PlayerData' and Module.Open then
			Module:UpdateWidget()
		end
	end)
end

function Module:Init(ParentController, otherSystems)
	WidgetControllerModule = ParentController
	SystemsContainer = otherSystems
end

return Module
