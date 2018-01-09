-- file: init.lua

local config = require("config")
local wireless = require("wireless")
local sntpd = require("sntpd")
local mqttd = require("mqttd")
local rf = require("rf")

--local onoff = {["ON"]=rf.ON, ["OFF"]=rf.OFF}

local switches = {}
--[[
switches["home/lamps/switch1/set"] = {["ack"]="home/lamps/switch1", ["qos"]=0, ["addr"]=1, ["unit"]=rf.SWITCH_1}
switches["home/lamps/switch2/set"] = {["ack"]="home/lamps/switch2", ["qos"]=0, ["addr"]=1, ["unit"]=rf.SWITCH_2}
switches["home/lamps/switch3/set"] = {["ack"]="home/lamps/switch3", ["qos"]=0, ["addr"]=1, ["unit"]=rf.SWITCH_3}
switches["home/lamps/switch4/set"] = {["ack"]="home/lamps/switch4", ["qos"]=0, ["addr"]=1, ["unit"]=rf.SWITCH_4}
switches["home/lamps/switch5/set"] = {["ack"]="home/lamps/switch5", ["qos"]=0, ["addr"]=2, ["unit"]=rf.SWITCH_1}
switches["home/lamps/switch6/set"] = {["ack"]="home/lamps/switch6", ["qos"]=0, ["addr"]=2, ["unit"]=rf.SWITCH_2}
switches["home/lamps/switch7/set"] = {["ack"]="home/lamps/switch7", ["qos"]=0, ["addr"]=2, ["unit"]=rf.SWITCH_3}
switches["home/lamps/switch8/set"] = {["ack"]="home/lamps/switch8", ["qos"]=0, ["addr"]=2, ["unit"]=rf.SWITCH_4}
--]]
switches["home/lamps/switch1/set"] = {["ack"]="home/lamps/switch1", ["qos"]=0}
switches["home/lamps/switch2/set"] = {["ack"]="home/lamps/switch2", ["qos"]=0}
switches["home/lamps/switch3/set"] = {["ack"]="home/lamps/switch3", ["qos"]=0}
switches["home/lamps/switch4/set"] = {["ack"]="home/lamps/switch4", ["qos"]=0}
switches["home/lamps/switch5/set"] = {["ack"]="home/lamps/switch5", ["qos"]=0}
switches["home/lamps/switch6/set"] = {["ack"]="home/lamps/switch6", ["qos"]=0}
switches["home/lamps/switch7/set"] = {["ack"]="home/lamps/switch7", ["qos"]=0}
switches["home/lamps/switch8/set"] = {["ack"]="home/lamps/switch8", ["qos"]=0}

-- MQTT message handler
function handler(client, topic, payload)

	--[[
	local switch = switches[topic]

	mqttd.publish(switch["ack"], payload, nil)

	rf.switch(switch["addr"], switch["unit"], onoff[payload])
	--]]

	print("\n\tMQTT Topic: "..topic.." Payload: "..payload.." Heap: "..node.heap())

	local decoded = sjson.decode(payload)

	rf.switch(decoded.addr, decoded.unit, decoded.onoff)

	mqttd.publish(switches[topic]["ack"], payload, function() print("\n\tMQTT - PUBACK") end)

end

-- sampling of AM2320 and node statistics
function sample()

	if wireless.is_ready() == true and mqttd.is_ready() == true then

		local rh, t = am2320.read()

		local sec, _, _ = rtctime.get()

		local payload = "{ \"temp\":"..(t)..", \"RH\":"..(rh)..", \"epoch\":"..sec.." }"

		mqttd.publish("home/environment/am2320", payload, function() print("\n\tMQTT - PUBACK") end)

		print("\n\tMQTT Publish: "..payload.." Heap: "..node.heap())

		payload = "{ \"dice\":"..node.random(6)..", \"rssi\":"..wifi.sta.getrssi()..", \"epoch\":"..sec.." }"

		mqttd.publish("nodemcu/system", payload, function() print("\n\tMQTT - PUBACK") end)

		print("\n\tMQTT Payload: "..payload.." Heap: "..node.heap())

	else
		--
	end
end

function wait_on_ip()

	if wireless.is_ready() == true then

		system_tmr:stop()
		system_tmr:unregister()

		sntpd.start(config.SNTP)

		local subscriptions = {}

		-- build subscriptions table
		for key,value in pairs(switches) do subscriptions[key] = value["qos"] end

		mqttd.start(config.MQTT, subscriptions, handler)

		-- clean up heap from unused configuration table
		config.free()

		sample_tmr:start()

	end
end

function report_boot()

	if wireless.is_ready() == true and mqttd.is_ready() == true and sntpd.is_ready() == true then

		report_tmr:stop()
		report_tmr:unregister()

		local sec, _, _ = rtctime.get()

		local _, boot = node.bootreason()

		local payload = "{ \"reason\":"..boot..", \"epoch\":"..sec.." }"

		mqttd.publish("nodemcu/boot", payload, function() print("\n\tMQTT - PUBACK") end)

		print("\n\tMQTT Payload: "..payload.." Heap: "..node.heap())

	end
end

--node.egc.setmode(node.egc.ALWAYS, 4096)

wireless.start(config.WIFI)

i2c.setup(0, config.I2C.sda, config.I2C.scl, config.I2C.speed)
am2320.setup()

rf.start(config.RF)

system_tmr = tmr.create()
system_tmr:register(1000, tmr.ALARM_AUTO, function (t) wait_on_ip() end)
system_tmr:start()

report_tmr = tmr.create()
report_tmr:register(1000, tmr.ALARM_AUTO, function (t) report_boot() end)
report_tmr:start()

sample_tmr = tmr.create()
sample_tmr:register(60 * 1000, tmr.ALARM_AUTO, function (t) sample() end)
