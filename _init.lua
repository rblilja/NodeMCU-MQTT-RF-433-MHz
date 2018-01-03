-- file: init.lua

local config = require("config")
local wireless = require("wireless")
local sntpd = require("sntpd")
local mqttd = require("mqttd")
local rf = require("rf")

-- MQTT message handler
function handler(client, topic, payload)

	print("\n\tMQTT Topic: "..topic.." Payload: "..payload)

	-- check that the topic is present
	if topic == nil then return end

	-- check that payload is present
	if payload == nil then return end

	subscription = config.MQTT.subscriptions[topic]

	-- check that topic gave a hit in the subscription table
	if subscription == nil then return end

	-- decode payload with the assumption it is JSON encoded
	decoded = sjson.decode(payload)

	rf.switch(config.RF.addr[decoded.addr], decoded.unit, decoded.onoff)

	mqttd.publish(subscription["ack"], payload)
end

-- AM2320 sampling
function sample()

	if wireless.is_ready() == true and mqttd.is_ready() == true then

		rh, t = am2320.read()

		sec, usec, rate = rtctime.get()

		rh = rh / 10
		t = t / 10

		payload = "{ \"temp\":"..(t)..", \"RH\":"..(rh)..", \"epoch\":"..sec.." }"

		print("\n\tMQTT Payload: "..payload)

		mqttd.publish("nodemcu/am2320", payload)
	else

		print("\n\tMQTT - Not Ready")
	end
end

function wait_on_ip()

	if wireless.is_ready() == true then

		system_tmr:stop()
		system_tmr:unregister()

		sntpd.start(config.SNTP)
		mqttd.start(config.MQTT, handler)

		sample_tmr:start()
	else
		--
	end
end

wireless.start(config.WIFI)

i2c.setup(0, config.I2C.sda, config.I2C.scl, config.I2C.speed)
am2320.setup()

rf.start(config.RF)

system_tmr = tmr.create()
system_tmr:register(500, tmr.ALARM_AUTO, function (t) wait_on_ip() end)
system_tmr:start()

sample_tmr = tmr.create()
sample_tmr:register(30 * 1000, tmr.ALARM_AUTO, function (t) sample() end)
