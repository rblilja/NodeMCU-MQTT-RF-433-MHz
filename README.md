MQTT client controlling remote 433 MHz power switches using NodeMCU for ESP8266. Tested with Telldus and Nexa devices 
using the self-learning protocol. The RF module was written as the built-in library of NodeMCU doesn't work with the 
aforementioned devices. Any 433.92 MHz ASK transmitter module shall work.

For controlling the remote switch using Home Assistant, enter the following in your configuration:

- platform: mqtt
  name: "Displayed name of switch 1"
  state_topic: "home/lamps/switch1"
  command_topic: "home/lamps/switch1/set"
  payload_on: "{ \"addr\":1, \"unit\":1, \"onoff\":0 }"
  payload_off: "{ \"addr\":1, \"unit\":1, \"onoff\":1 }"
  optimistic: false
  qos: 0
  retain: true

Note: The onoff field is inverted, which could be seen in the rf.lua file.
