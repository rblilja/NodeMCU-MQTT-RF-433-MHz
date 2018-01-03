-- file: rf.lua

local module = {}

-- ON/OFF states
module.ON = 0
module.OFF = 1

-- unit/switch addressing
module.SWITCH_1 = 1
module.SWITCH_2 = 2
module.SWITCH_3 = 3
module.SWITCH_4 = 4
module.SWITCH_GROUP = 0

-- timing definitions in microseconds (Telldus self-learning protocol)
local PULSE_HIGH_T = 250	-- 1T
local ONE_LOW_T = 250  		-- 1T
local ZERO_LOW_T = 1250  	-- 5T
local SYNC_LOW_T = 2500  	-- 10T
local PAUSE_LOW_T = 10000  	-- 40T

-- pulse definitions
local SYNC = {PULSE_HIGH_T, SYNC_LOW_T}
local PAUSE = {PULSE_HIGH_T, PAUSE_LOW_T}
local ZERO = {PULSE_HIGH_T, ZERO_LOW_T, PULSE_HIGH_T, ONE_LOW_T}
local ONE = {PULSE_HIGH_T, ONE_LOW_T, PULSE_HIGH_T, ZERO_LOW_T}

local unit_addr = {}

-- definition of Telldus units (Nexa is inverted e.g. {1, 1} for unit one)
unit_addr[1] = {0, 0}	-- one
unit_addr[2] = {0, 1}	-- two
unit_addr[3] = {1, 0}	-- three
unit_addr[4] = {1, 1}	-- four (not official, works for self-learing Telldus and Nexa)
unit_addr[0] = {0, 0}	-- unit address when group bit set to zero

local tx_pin = nil
local repeats = nil

local queue = nil

local tx_is_ready = true

function module.start(rf_cfg)

	tx_pin = rf_cfg.tx_pin
	repeats = rf_cfg.repeats

	queue = {}

	gpio.mode(tx_pin, gpio.OUTPUT)
	gpio.write(tx_pin, gpio.LOW)

	tx_is_ready = true
end

function module.is_ready()

	return tx_is_ready
end

function module.switch_on(addr, unit)

	module.switch(addr, unit, module.ON)
end

function module.switch_off(addr, unit)

	module.switch(addr, unit, module.OFF)
end

function module.switch(addr, unit, onoff)

	-- push switch command on the queue
	table.insert(queue, {addr, unit, onoff})

	-- trigger transmission
	dequeue()
end

function dequeue()

	-- if transmission already in progress
	if tx_is_ready == false then return end

	-- if queue contains elements awaiting transmission
	if table.getn(queue) > 0 then send(unpack(table.remove(queue))) end
end

function merge(a, b)

	for n=1, table.getn(b) do table.insert(a, b[n]) end
end

function send(addr, unit, onoff)

	-- clear ready flag
	tx_is_ready = false

	-- assert tx pin is low
	gpio.write(tx_pin, gpio.LOW)

	bit_buffer = {}
	raw_buffer = {}

	-- channel bits for Telldus (Nexa is inverted i.e. {1, 1})
	channel = {0, 0}

	if unit == module.SWITCH_GROUP then group = module.ON else group = module.OFF end

	-- build bit sequence
	--
	-- HHHH HHHH HHHH HHHH HHHH HHHH HHGO CCEE
	--
	-- H = The first 26 bits are transmitter unique codes, and it is this code that the reciever "learns" to recognize.
	-- G = Group code. Set to 0 for ON, 1 for OFF.
	-- O = ON/OFF bit. Set to 0 for ON, 1 for OFF.
	-- C = Channel bits.
	-- E = Unit bits. Device to be turned ON or OFF.
	--
	merge(bit_buffer, addr)
	merge(bit_buffer, {group})
	merge(bit_buffer, {onoff})
	merge(bit_buffer, channel)
	merge(bit_buffer, unit_addr[unit])

	-- build raw pulse buffer
	--
	-- start with SYNC pulse
	merge(raw_buffer, SYNC)
	--
	-- add pulses in accordance with the bit sequence i.e. the message
	for n=1, table.getn(bit_buffer) do

		if bit_buffer[n] == 0 then merge(raw_buffer, ZERO) else merge(raw_buffer, ONE) end
	end
	--
	-- stop with PAUSE pulse
	merge(raw_buffer, PAUSE)

	--for n=1, table.getn(raw_buffer) do print(raw_buffer[n]) end

	-- push raw pulse buffer to the tx
	gpio.serout(tx_pin, gpio.HIGH, raw_buffer, repeats,
	function()
		-- set ready flag
		tx_is_ready = true
		-- continue to dequeue commands awaiting transmission
		dequeue()
	end)
end

return module
