-- file: wireless.lua

local module = {}

function module.is_ready()

	return wifi.sta.status() == wifi.STA_GOTIP
end

function module.start(station_cfg)

	-- register event monitors

	-- connected
	wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, 
	function(T)
 		print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..T.BSSID.."\n\tChannel: "..T.channel.."\n\tRSSI: "..wifi.sta.getrssi())
 	end)
 	
 	-- disconnected
 	wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, 
	function(T)
 		print("\n\tSTA - DISCONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..T.BSSID.."\n\tReason: "..T.reason)
 	end)
 	
 	-- got IP
 	wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, 
	function(T)
 		print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..T.netmask.."\n\tGateway IP: "..T.gateway)
 	end)
 	
 	-- set mode and config
 	wifi.setmode(wifi.STATION)
 	wifi.sta.config(station_cfg)
end

return module
