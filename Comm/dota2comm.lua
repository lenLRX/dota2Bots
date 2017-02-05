local comm = {}

local function add_marker(s,marker)
    return s..marker
	--return s
end

function comm:new(marker)
	print("comm init " .. marker)

	local o = {}

	setmetatable(o, self)
	self.__index = self
	
	local input = {}
    local output = {}
	
    local blank = string.rep(" ", 2^10)

	local r_marker = string.reverse(marker)
	
	input[0] = add_marker("is000",r_marker); -- buffer start
	input[1] = add_marker("ie000",r_marker); -- buffer end
	for i = 1,10 do
		input[2-1+i] = add_marker("i"..string.format("%03d", i-1)..blank,r_marker) -- buffer...
	end
	
	output[0] = add_marker("os000",r_marker) -- buffer start
	output[1] = add_marker("oe000",r_marker) -- buffer end
	for i = 1,10 do
		output[2-1+i] = add_marker("",r_marker)
	end
	
	local tbl = {};
	
	tbl[0] = marker;
	tbl[1] = input;
	tbl[2] = output;
	
	o[marker..marker] = tbl;
	o.r_marker = r_marker
	return o
end

function comm:send(text)
    local marker = string.reverse( self.r_marker )
	local markermarker = marker..marker
	local b_start = tonumber(string.sub(self[markermarker][2][0], 3, 5))
    local b_end = tonumber(string.sub(self[markermarker][2][1], 3, 5))
	self[markermarker][2][2+b_end] = add_marker(text,self.r_marker)
	b_end = (b_end+1)%10
	if b_end == b_start then error("send buffer is full") end
	self[markermarker][2][1] = add_marker("oe"..string.format("%03d", b_end),self.r_marker)
end

function comm:receive()
	local marker = string.reverse( self.r_marker )
	local markermarker = marker..marker
    local blank = string.rep(" ", 2^10)
	local b_start = tonumber(string.sub(self[markermarker][1][0], 3, 5))
    local b_end = tonumber(string.sub(self[markermarker][1][1], 3, 5))
	if b_start == b_end then return nil end
	local msg = self[markermarker][1][2+b_start]
	self[markermarker][1][0] = add_marker("is"..string.format("%03d", (b_start+1)%10), self.r_marker)
	self[markermarker][1][2+b_start] = add_marker("i"..string.format("%03d", b_start)..blank, self.r_marker)
	local length = tonumber(string.sub(msg, 2, 4))
	msg = string.sub(msg, 5, 5-1+length)
	return msg
end

return comm