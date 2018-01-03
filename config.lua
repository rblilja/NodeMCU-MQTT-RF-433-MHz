-- file : config.lua

local module = {}

-- WIFI
module.WIFI = {}
module.WIFI.ssid = "XXX"
module.WIFI.pwd = "XXX"

-- SNTP
module.SNTP = {}
module.SNTP.server = "ntp1.sp.se"
module.SNTP.period = 3600
module.SNTP.timeout = 5

-- MQTT
module.MQTT = {}
module.MQTT.host = "X.X.X.X"
module.MQTT.port = 1883
module.MQTT.client_id = node.chipid()
module.MQTT.keepalive = 120
module.MQTT.user = "XXX"
module.MQTT.pwd = "XXX"
module.MQTT.timeout = 5

module.MQTT.subscriptions = {}
module.MQTT.subscriptions["home/lamps/switch1/set"] = {["ack"]="home/lamps/switch1", ["qos"]=0}
module.MQTT.subscriptions["home/lamps/switch2/set"] = {["ack"]="home/lamps/switch2", ["qos"]=0}
module.MQTT.subscriptions["home/lamps/switch3/set"] = {["ack"]="home/lamps/switch3", ["qos"]=0}
module.MQTT.subscriptions["home/lamps/switch4/set"] = {["ack"]="home/lamps/switch4", ["qos"]=0}
module.MQTT.subscriptions["home/lamps/switch5/set"] = {["ack"]="home/lamps/switch5", ["qos"]=0}
module.MQTT.subscriptions["home/lamps/switch6/set"] = {["ack"]="home/lamps/switch6", ["qos"]=0}
module.MQTT.subscriptions["home/lamps/switch7/set"] = {["ack"]="home/lamps/switch7", ["qos"]=0}
module.MQTT.subscriptions["home/lamps/switch8/set"] = {["ack"]="home/lamps/switch8", ["qos"]=0}

-- SDA and SCL can be assigned freely to available GPIOs
module.I2C = {}
module.I2C.sda = 5 -- GPIO14
module.I2C.scl = 6 -- GPIO12
module.I2C.speed = i2c.SLOW -- 100 kHz

-- RF (Telldus and Nexa 433.92 MHz)
module.RF = {}
module.RF.tx_pin = 8 	-- GPIO8
module.RF.repeats = 6	-- Number of times to repeat TX message
module.RF.addr = {}		-- Remote addresses are stored in a table of arrays (one element per bit)
module.RF.addr[1] = {1,1,0,0,0,0,0,1,0,1,1,1,0,0,1,1,0,0,1,0,1,1,0,1,0,1}
module.RF.addr[2] = {1,1,0,0,0,0,0,1,0,1,1,1,0,0,1,1,0,0,1,0,1,1,0,1,1,0}
module.RF.addr[3] = {1,1,0,0,0,0,0,1,0,1,1,1,0,0,1,1,0,0,1,0,1,1,0,1,1,1}

return module
