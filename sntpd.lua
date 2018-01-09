-- file: sntpd.lua

local module = {}

module.SNTP_UNKNOWN = 0
module.SNTP_SYNCHRONIZED = 1
module.SNTP_FAILED = 2

local server = nil
local period = nil
local timeout = nil

local state = module.SNTP_UNKNOWN

function module.is_ready()

	return state == module.SNTP_SYNCHRONIZED
end

function module.start(__config)

	server = __config.server
	period = __config.period
	timeout = __config.timeout

	module.sync()
end

function module.sync()

	sntp.sync(server,
	function(sec, usec, server, info)
		print("\n\tSNTP - SYNCHRONIZED".."\n\tSeconds: "..sec.."\n\tMicroseconds: "..usec.."\n\tServer: "..server)
		state = module.SNTP_SYNCHRONIZED
		tmr.create():alarm(period * 1000, tmr.ALARM_SINGLE, module.sync)
  	end,
  	function(reason, info)
   		print("\n\tSNTP - FAILED".."\n\tReason: "..reason.."\n\tInfo (if any): "..info)
			state = module.SNTP_FAILED
			tmr.create():alarm(timeout * 1000, tmr.ALARM_SINGLE, module.sync)
  	end,
  	nil)
end

return module
