local EventClass = require(script.Parent.Event)
local MaidClass = require(script.Parent.Maid)

-- // Class // --
local Class = {}
Class.__index = Class

function Class.New( TargetInstance )
	local StartedEvent = EventClass.New()
	local CanceledEvent = EventClass.New()
	local CompletedEvent = EventClass.New()
	return setmetatable({
		Enabled = true,
		TargetInstance = TargetInstance,
		Destroyed = nil,

		Keybinds = { Enum.KeyCode.F, Enum.KeyCode.ButtonB },
		HoldDuration = 1,
		MaxDistance = 14,

		CanUseInteraction = false,

		_Maid = MaidClass.New(StartedEvent, CanceledEvent, CompletedEvent),
		Events = {
			Started = StartedEvent,
			Canceled = CanceledEvent,
			Completed = CompletedEvent,
		},
	}, Class)
end

function Class:AddConditionFunction(...)
	if not self.CanUseInteraction then
		self.CanUseInteraction = { }
	end
	for _, func in ipairs( { ... } ) do
		if not table.find(self.CanUseInteraction, func) then
			table.insert(self.CanUseInteraction, func)
		end
	end
end

function Class:SetEnabled( enabled )
	self.Enabled = enabled
end

function Class:SetKeybinds( ... )
	self.Keybinds = { ... }
end

function Class:SetCanUseFunction( Callback )
	self.CanUseInteraction = Callback
end

function Class:OnInteractStarted( callback )
	local connection = self.Events.Started:Connect(callback)
	self._Maid:Give(connection)
	return connection
end

function Class:OnInteractCanceled( callback )
	local connection = self.Events.Canceled:Connect(callback)
	self._Maid:Give(connection)
	return connection
end

function Class:OnInteractCompleted( callback )
	local connection = self.Events.Completed:Connect(callback)
	self._Maid:Give(connection)
	return connection
end

function Class:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true

	self._Maid:Cleanup()
	self.Events.Started:Disconnect()
	self.Events.Canceled:Disconnect()
	self.Events.Completed:Disconnect()
end

return Class
