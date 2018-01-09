-- file: compile.lua

node.stripdebug(2)
node.compile("config.lua")
node.compile("mqttd.lua")
node.compile("sntpd.lua")
node.compile("wireless.lua")
node.compile("rf.lua")
