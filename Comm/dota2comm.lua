--[[
	from https://github.com/Keithenneu/dota2comm
]]
module("comm", package.seeall)

local input = {};
local output = {};
	
local blank = string.rep(" ", 2^10);

setfenv(1, comm);

function init()
	print("comm init");
	
	input[0] = "is000"; -- buffer start
	input[1] = "ie000"; -- buffer end
	for i = 1,10 do
		input[2-1+i] = "i"..string.format("%03d", i-1)..blank -- buffer...
	end
	
	output[0] = "os000" -- buffer start
	output[1] = "oe000" -- buffer end
	for i = 1,10 do
		output[2-1+i] = ""
	end
	
	local tbl = {};
	
	local marker = "commtable"
	
	tbl[0] = marker;
	tbl[1] = input;
	tbl[2] = output;
	
	comm[marker..marker] = tbl;
end

function comm.send(text)
	local b_start = tonumber(string.sub(output[0], 3))
    local b_end = tonumber(string.sub(output[1], 3))
	if (b_end+1)%10 == b_start then return end
	output[2+b_end] = text
	b_end = (b_end+1)%10
	--if b_end == b_start then error("send buffer is full") end
	output[1] = "oe"..string.format("%03d", b_end)
end

function comm.receive()
	local b_start = tonumber(string.sub(input[0], 3))
    local b_end = tonumber(string.sub(input[1], 3))
	if b_start == b_end then return nil end
	local msg = input[2+b_start]
	input[0] = "is"..string.format("%03d", (b_start+1)%10)
	input[2+b_start] = "i"..string.format("%03d", b_start)..blank
	local length = tonumber(string.sub(msg, 2, 4))
	msg = string.sub(msg, 5, 5-1+length)
	return msg
end

init();