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

local publish_ack = nil

local state = module.MQTT_DISCONNECTED

function module.is_ready()

	return state == module.MQTT_CONNECTED
end

function module.start(mqtt_cfg, handler)

	host = mqtt_cfg.host
	port = mqtt_cfg.port
	timeout = mqtt_cfg.timeout

	subscriptions = {}

	-- build subscriptions table
	for key,value in pairs(mqtt_cfg.subscriptions) do

		subscriptions[key] = value["qos"]
	end

	publish_ack = 0

	-- init mqtt client with logins and keepalive timer
	m = mqtt.Client(mqtt_cfg.client_id, mqtt_cfg.keepalive, mqtt_cfg.user, mqtt_cfg.pwd)

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

function module.publish(topic, data)

	if m == nil then return end

	-- publish a message, QoS = 0 and retain = 1 i.e. MQTT server will push current data for new subscribers
	m:publish(topic, data, 0, 1,
	function(client)
		-- increment ACK counter
		publish_ack = publish_ack + 1
		print("\n\tMQTT - PUBACK")
	end)
end

function module.subscribe(topic)

	m:subscribe(topic,
	function()
		print("\n\tMQTT - SUBSCRIBED")
	end)
end

return module
