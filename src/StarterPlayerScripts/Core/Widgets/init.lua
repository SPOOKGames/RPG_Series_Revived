
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local LocalModules = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Modules"))

local Interface = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('Interface')
local LeftButtonsFrame = Interface.LeftButtons
local InventoryFrame = Interface.InventoryFrame

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:Start()

	-- inventory button
	LeftButtonsFrame.Scroll.Template.Button.Activated:Connect(function()
		InventoryFrame.Visible = not InventoryFrame.Visible
	end)
	InventoryFrame.Visible = false

	-- inventory thingie

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
