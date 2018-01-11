-- file: initd.lua

local module = {}

local state = nil
local fsm = nil

local handler = nil

local timer = nil

function module.start(__fsm, __handler)

	fsm = __fsm

	handler = __handler

	timer = tmr.create()
	timer:register(500, tmr.ALARM_AUTO, function (t) module.step() end)

	timer:start()

	print("\n\tINIT - START")

end

function module.step()

	-- if initialization complete
	if table.getn(fsm) == 0 then module.done() return end

  -- load new state if no current state
	if state == nil then state = table.remove(fsm) end

	if state.run > 0 then

		-- decrement run counter and call function
		state.run = state.run - 1;
		state.fnc(unpack(state.arg))

	end

	-- set current state to nil
	if state.assert() == true then state = nil end

end

function module.done()

	timer:stop()
	timer:unregister()

	-- user handler function
	handler()

	-- free itself
	module.free()

	print("\n\tINIT - DONE")

end

function module.free()

  package.loaded["initd"] = nil
  module = nil
end

return module
