--[[

All of the supported data types are following:

	R : Unsigned Varint Int		1~4bit
	r : Varint Int				1~4bit
    I : Unsigned Int			4bit
    i : Int						4bit
    H : Unsigned Short			2bit
    h : Short					2bit
	S : String					dynamic
    b : byte (unsigned char) 	1bit 0~255
    c : char (signed byte)		1bit -127~128
    f : float					4bit
    d : double					8bit

Certainly, a user of this api can only use RSr.
]]

--local _p = import(".protocols")
local _p = net.protocols

local Protocol = {}

local function _getProtocol(__name, __methodCode, __ver)
	if type(__name) ~= "string" then
		print(string.format("_getProtocol argument __name type error, want string got %s", type(__name)))
	end
	if type(__methodCode) ~= "number" then
		print(string.format("_getProtocol argument __methodCode type error, want number got %s", type(__methodCode)))
	end
	if type(__ver) ~= "number" then
		print(string.format("_getProtocol argument __ver type error, want string got %s", type(__ver)))
	end
	local protoSet = _p[__methodCode]
	if not protoSet then
		print(_p[__methodCode], __methodCode, type(__methodCode))
		print(string.format("not such protocol [%x]",__methodCode))
		return
	end
	local oneSideProto = protoSet[__name]
	if not oneSideProto then
		print(string.format("there is not type [%s] in protocol [%x] ", tostring(__name), __methodCode))
		return
	end
	local content = oneSideProto[__ver]
	if not content then
		print(string.format("there is not ver [%s] in protocol [%x] [%s]", tostring(__ver), __methodCode, __name))
		return
	end
	return content
end

function Protocol.getSend(__methodCode, __ver)
	return _getProtocol("c2s", __methodCode, __ver), __methodCode, __ver
end

function Protocol.getReceive(__methodCode, __ver)
	return _getProtocol("s2c", __methodCode, __ver)
end

return Protocol

