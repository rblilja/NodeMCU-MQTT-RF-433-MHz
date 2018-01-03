-- file: sntpd.lua

local module = {}

local server = nil
local period = nil
local timeout = nil

function module.start(sntp_cfg)

	server = sntp_cfg.server
	period = sntp_cfg.period
	timeout = sntp_cfg.timeout

	module.sync()
end
	
function module.sync()

	sntp.sync(server,
	function(sec, usec, server, info)
		print("\n\tSNTP - SYNCHRONIZED".."\n\tSeconds: "..sec.."\n\tMicroseconds: "..usec.."\n\tServer: "..server)
		tmr.create():alarm(period * 1000, tmr.ALARM_SINGLE, module.sync)
  	end,
  	function(reason, info)
   		print("\n\tSNTP - FAILED".."\n\tReason: "..reason.."\n\tInfo (if any): "..info)
   		tmr.create():alarm(timeout * 1000, tmr.ALARM_SINGLE, module.sync)
  	end,
  	nil)
end

return module