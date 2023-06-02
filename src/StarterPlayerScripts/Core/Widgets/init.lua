
local WidgetsCache = {}

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:ToggleWidget(widgetName, enabled)
	local cachedModule = WidgetsCache[widgetName]
	if not cachedModule then
		return
	end
	if enabled then
		cachedModule:OpenWidget()
	else
		cachedModule:CloseWidget()
	end
end

function Module:ToggleAllWidgets(enabled)
	for _, WidgetModule in pairs( WidgetsCache ) do
		if enabled then
			if not WidgetModule.Open then
				WidgetModule:OpenWidget()
			end
		else
			WidgetModule:CloseWidget()
		end
	end
end

function Module:UpdateWidget(widgetName)
	local cachedModule = WidgetsCache[widgetName]
	if not cachedModule then
		return
	end
	cachedModule:UpdateWidget()
end

function Module:Start()

	-- enable main menu on spawn
	for WidgetName, WidgetModule in pairs( WidgetsCache ) do
		print(WidgetName)
		if WidgetName == "MainMenuWidget" then
			WidgetModule:OpenWidget()
		else
			WidgetModule:CloseWidget()
		end
	end

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems

	-- Cache and initialize widget modules
	for _, WidgetModule in ipairs( script:GetChildren() ) do
		local Cached = require(WidgetModule)
		Cached:Init(Module, otherSystems)
		WidgetsCache[WidgetModule.Name] = Cached
	end

	-- start all modules
	for _, CachedModule in pairs(WidgetsCache) do
		CachedModule:Start()
	end
end

return Module
