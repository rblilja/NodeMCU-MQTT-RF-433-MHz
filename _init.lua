-- file: init.lua

local config = require("config")
local initd = require("initd")
local wireless = require("wireless")
local sntpd = require("sntpd")
local mqttd = require("mqttd")
local rf = require("rf")

local switches = {}
switches["home/lamps/switch1/set"] = {["ack"]="home/lamps/switch1", ["qos"]=0}
switches["home/lamps/switch2/set"] = {["ack"]="home/lamps/switch2", ["qos"]=0}
switches["home/lamps/switch3/set"] = {["ack"]="home/lamps/switch3", ["qos"]=0}
switches["home/lamps/switch4/set"] = {["ack"]="home/lamps/switch4", ["qos"]=0}
switches["home/lamps/switch5/set"] = {["ack"]="home/lamps/switch5", ["qos"]=0}
switches["home/lamps/switch6/set"] = {["ack"]="home/lamps/switch6", ["qos"]=0}
switches["home/lamps/switch7/set"] = {["ack"]="home/lamps/switch7", ["qos"]=0}
switches["home/lamps/switch8/set"] = {["ack"]="home/lamps/switch8", ["qos"]=0}

subscriptions = {}

-- build subscriptions table
for key,value in pairs(switches) do subscriptions[key] = value["qos"] end

-- MQTT message handler
function mqtt_handler(client, topic, payload)

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

function report_boot()

	if wireless.is_ready() == true and mqttd.is_ready() == true and sntpd.is_ready() == true then

		local sec, _, _ = rtctime.get()

		local _, boot = node.bootreason()

		local payload = "{ \"reason\":"..boot..", \"epoch\":"..sec.." }"

		mqttd.publish("nodemcu/boot", payload, function() print("\n\tMQTT - PUBACK") end)

		print("\n\tMQTT Payload: "..payload.." Heap: "..node.heap())

	else
		--
	end
end

function done()

	-- clean up the heap
	fsm = nil
	subscriptions = nil
	config.free()
	collectgarbage()

	--for k,v in pairs(package.loaded) do print(k,v) end

	report_boot()
	sample_tmr:start()
end

i2c.setup(0, config.I2C.sda, config.I2C.scl, config.I2C.speed)
am2320.setup()

rf.start(config.RF)

fsm = {}
fsm[3] = { fnc=wireless.start, arg={ config.WIFI }, assert=wireless.is_ready, run=1}
fsm[2] = { fnc=sntpd.start, arg={ config.SNTP }, assert=sntpd.is_ready, run=1}
fsm[1] = { fnc=mqttd.start, arg={ config.MQTT, subscriptions, mqtt_handler }, assert=mqttd.is_ready, run=1}

initd.start(fsm, done)

sample_tmr = tmr.create()
sample_tmr:register(60 * 1000, tmr.ALARM_AUTO, function (t) sample() end)
