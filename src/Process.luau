--!strict
--!native
--!optimize 2

--::thread pooling
local freeThreads = {} :: {thread}

local function runCallback(callback: (self: any, dt: number) -> (), thread: thread, arg1: any, arg2: any)
    callback(arg1, arg2)
    table.insert(freeThreads, thread)
end

local function yielder()
    while true do
        runCallback(coroutine.yield())
    end
end

--Runs given function asynchronously with given arguments
local function addThread(fn: (self: any, dt: number) -> (), arg1: any, arg2: any)
    local thread: thread
    if #freeThreads == 0 then
        thread = coroutine.create(yielder)
        coroutine.resume(thread)
    else
		thread = freeThreads[#freeThreads]
        freeThreads[#freeThreads] = nil
    end

    task.spawn(thread, fn, thread, arg1, arg2)
end
--::

local RunService = game:GetService("RunService")

local types = require("./types")

local bound: {types.Component3D} = {}

--i know varargs exist yall dw
local function runStepped(stepped: types.fn_SteppedCallback, arg1: types.Component3D, arg2: number)
	local fn = stepped[1] :: (self: types.Component3D, dt: number) -> ()
	if stepped[2] then
		addThread(fn, arg1, arg2)
	else
		fn(arg1, arg2)
	end
end

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

	local stepped = component.stepped
	if stepped then
		local rate = stepped[3] :: number

		if rate then
			local newTime = os.clock()
			if newTime - (stepped[4] :: number) >= 1 / rate then
				runStepped(stepped, component, dt)
				stepped[4] = newTime
			end
		else
			runStepped(stepped, component, dt)
		end
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