-- file: mqttd.lua

local module = {}

module.MQTT_DISCONNECTED = 0
module.MQTT_CONNECTED = 1
module.MQTT_FAILED = 2

local m = nil

local host = nil
local port = nil
local timeout = nil
local subscriptions = nil

local state = module.MQTT_DISCONNECTED

function module.is_ready()

	return state == module.MQTT_CONNECTED
end

function module.start(__config, __subscriptions, handler)

	host = __config.host
	port = __config.port
	timeout = __config.timeout

	subscriptions = __subscriptions

	-- init mqtt client with logins and keepalive timer
	m = mqtt.Client(__config.client_id, __config.keepalive, __config.user, __config.pwd)

	module.connect()

	m:on("offline",
	function(client)
		print("\n\tMQTT - OFFLINE")
		state = module.MQTT_DISCONNECTED
		tmr.create():alarm(timeout * 1000, tmr.ALARM_SINGLE, module.connect)
	end)

	m:on("message", handler)
end

function module.connect()

	if m == nil then return end

	m:connect(host, port,
	function(client)
		print("\n\tMQTT - CONNECTED")
		state = module.MQTT_CONNECTED
		module.subscribe(subscriptions)
	end,
	function(client, reason)
		print("\n\tMQTT - FAILED\n\tReason: "..reason)
		state = module.MQTT_FAILED
		tmr.create():alarm(timeout * 1000, tmr.ALARM_SINGLE, module.connect)
	end)
end

function module.disconnect()

	if m:close() == true then

		state = module.MQTT_DISCONNECTED
	else
		state = module.MQTT_FAILED
	end

	return state
end

function module.publish(topic, data, handler)

	if m == nil then return end

	-- publish a message, QoS = 0 and retain = 1 i.e. MQTT server will push current data for new subscribers
	m:publish(topic, data, 0, 1, handler)
end

function module.subscribe(topic)

	m:subscribe(topic,
	function()
		print("\n\tMQTT - SUBSCRIBED")
	end)
end

return module
