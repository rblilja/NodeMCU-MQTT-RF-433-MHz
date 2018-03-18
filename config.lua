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
module.MQTT.host = "XXX"
module.MQTT.port = 1883
module.MQTT.client_id = node.chipid()
module.MQTT.keepalive = 120
module.MQTT.user = "XXX"
module.MQTT.pwd = "XXX"
module.MQTT.timeout = 5

-- SDA and SCL can be assigned freely to available GPIOs
module.I2C = {}
module.I2C.sda = 5 -- GPIO14
module.I2C.scl = 6 -- GPIO12
module.I2C.speed = i2c.SLOW -- 100 kHz

-- RF (Telldus and Nexa 433.92 MHz)
module.RF = {}
module.RF.tx_pin = 7 	-- GPIO13
module.RF.repeats = 5	-- Number of times to repeat TX message
module.RF.addr = {}		-- Remote addresses are stored in a table of arrays (one element per bit)
module.RF.addr[1] = {1,1,0,0,0,0,0,1,0,1,1,1,0,0,1,1,0,0,1,0,1,1,0,1,0,1}
module.RF.addr[2] = {1,1,0,0,0,0,0,1,0,1,1,1,0,0,1,1,0,0,1,0,1,1,0,1,1,0}
module.RF.addr[3] = {1,1,0,0,0,0,0,1,0,1,1,1,0,0,1,1,0,0,1,0,1,1,0,1,1,1}

--[[
configuration subtables shall be copied (the parts needed) locally in modules
once modules are loaded the free() function shall be called
--]]
function module.free()

  package.loaded["config"] = nil
  module = nil
end

return module
