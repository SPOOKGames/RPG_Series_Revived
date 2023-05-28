
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local LocalModules = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Modules"))

local UserInterfaceUtil = LocalModules.Utility.UserInterface

local Interface = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('Interface')
local LHUDFrame = Interface.LHUD
local InventoryFrame = Interface.Inventory

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:Start()

	-- inventory button
	UserInterfaceUtil:CreateActionButton({Parent = LHUDFrame.MButtons.Inventory}).Activated:Connect(function()
		InventoryFrame.Visible = not InventoryFrame.Visible
	end)
	InventoryFrame.CloseButton.Button.Activated:Connect(function()
		InventoryFrame.Visible = false
	end)
	InventoryFrame.Visible = false

	-- inventory thingie

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
