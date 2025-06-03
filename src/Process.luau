--!strict
--!native
--!optimize 2

local RunService = game:GetService("RunService")

local types = require("./types")

local bound: {types.Component3D} = {}

local function process(component: types.Component3D, dt: number)
	local surfaceGui = component.surfaceGui :: SurfaceGui
	local surfacePart = surfaceGui and surfaceGui.Adornee :: BasePart
	if not surfacePart then
		local index = table.find(bound, component)
		if index then
			table.remove(bound, index)
		end
		return
	end

	local viewportSize = component:GetViewportSize()

	component.viewportSize = viewportSize

	surfaceGui.CanvasSize = viewportSize
	surfacePart.Size = component:GetStudsScreenSize(viewportSize)
	surfacePart.CFrame = component:ReadWorldCFrame()

	if component.stepped then
		component.stepped(component, dt)
	end
end

RunService:BindToRenderStep("ScreenThriDi:Process", Enum.RenderPriority.Last.Value, function(dt)
	for i, v in ipairs(bound) do
		process(v, dt)
	end
end)

--removes or adds the component to the process
return function(component: types.Component3D)
	local index = table.find(bound, component)
	if index then
		table.remove(bound, index)
	else
		table.insert(bound, component)
	end
end