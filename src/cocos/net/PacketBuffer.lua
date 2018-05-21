--[[
PacketBuffer receive the byte stream and analyze them, then pack them into a message packet.
The method name, message metedata and message body will be splited, and return to invoker.
@see https://github.com/zrong/as3/blob/master/src/org/zengrong/net/PacketBuffer.as
@author zrong(zengrong.net)
Creation: 2013-11-14
]]

local Protocol = import(".Protocol")
local ByteArrayVarint = require("cocos.utils.ByteArrayVarint")
loadfile("cocos.utils.bit")
local PacketBuffer = {}

PacketBuffer.ENDIAN = ByteArrayVarint.ENDIAN_BIG
--PacketBuffer.ENDIAN = ByteArrayVarint.ENDIAN_LITTLE

PacketBuffer.MASK1 = 0x86
PacketBuffer.MASK2 = 0x7b
PacketBuffer.RANDOM_MAX = 10000
PacketBuffer.PACKET_MAX_LEN = 2100000000

--[[
packet bit structure
FLAG byte|FLAG byte|TYPE byte|BODY_LEN int|METHOD short|VER byte|META_NUM byte|META bytes|BODY bytes|
]]
PacketBuffer.FLAG_LEN = 2	-- package flag at start, 1byte per flag
PacketBuffer.TYPE_LEN = 1	-- type of message, 1byte
PacketBuffer.BODY_LEN = 4	-- length of message body, int
PacketBuffer.METHOD_LEN = 2	-- length of message method code, short
PacketBuffer.VER_LEN = 1	-- version of message, byte
PacketBuffer.META_NUM_LEN = 1	-- how much item in a message, 1byte

function PacketBuffer._createBody(pcontent, body, buf)
	if not buf then
		buf = PacketBuffer.getBaseBA()
	end
	if type(body) ~= "table" then
		return nil, "Error PacketBuffer._createBody:argument [body] need table got" .. type(body) .. tostring(body)
	end
	if pcontent.KEY then
		local len = #body
		buf:writeUVInt(len)
		for i = 1, len do
			local bSucc, sMsg =  PacketBuffer._createBody2(pcontent, body[i], buf)
			if not bSucc then
				return nil, sMsg
			end
		end
	else
		local bSucc, sMsg = PacketBuffer._createBody2(pcontent, body, buf)
		if not bSucc then
			return nil, sMsg
		end
	end
	return buf, ""
end

function PacketBuffer._createBody2(pcontent, body, buf)
	for _, proto in ipairs(pcontent) do
		if proto.KEY then
			PacketBuffer._createBody(proto, body[proto.KEY], buf)
		else
			local data = body[proto[1]]
			local fmt = proto[2]
			if fmt == "R" then
				buf:writeUVInt(data or 0)
			elseif fmt == "S" then
				buf:writeStringUVInt(data or "")
			elseif fmt == "r" then
				buf:writeVInt(data or 0)
			else
				return false, string.format("Error PacketBuffer._createBody: got an unavalable type %s", tostring(fmt))
			end
		end
	end
	return true, ""
end

function PacketBuffer._parseBody(buf, pcontent)
	local body, sMsg
	if pcontent.KEY then
		local len = buf:readUVInt() or 0
		body = {}
		for i = 1, len do
			local b, s = PacketBuffer._parseBody2(buf, pcontent)
			if not b then
				return nil, s
			end
			table.insert(body, b)
		end
	else
		body, sMsg = PacketBuffer._parseBody2(buf, pcontent)
	end
	return body, ""
end

function PacketBuffer._parseBody2(buf, pcontent)
	local body = {}
	for _, proto in ipairs(pcontent) do
		if proto.KEY then
			body[proto.KEY] = PacketBuffer._parseBody(buf, proto)
		else
			local name = proto[1]
			local fmt = proto[2]
			if fmt == "R" then
				body[name] = buf:readUVInt() or 0
			elseif fmt == "S" then
				body[name] = intl.Unpack(buf:readStringUVInt() or "")
			elseif fmt == "r" then
				body[name] = buf:readVInt() or 0
			else
				return nil, string.format("Error PacketBuffer._parseBody: got an unavalable type %s", fmt)
			end
		end
	end
	return body, ""
end

function PacketBuffer.getBaseBA()
	return ByteArrayVarint.new(PacketBuffer.ENDIAN)
end

--- Create a formated packet that to send server
-- @param __msgDef the define of message, a table
-- @param __msgBodyTable the message body with key&value, a table
function PacketBuffer.createPacket(__msgDef, method, ver, __msgBodyTable)
	local __buf = PacketBuffer.getBaseBA()
	local __bodyBA, sErr = PacketBuffer._createBody(__msgDef, __msgBodyTable)
	if __bodyBA == nil then
		printError(sErr)
		return
	end
	local __bodyLen = PacketBuffer.METHOD_LEN + PacketBuffer.VER_LEN + __bodyBA:getLen()
	local __packetLen = PacketBuffer.FLAG_LEN +PacketBuffer.TYPE_LEN + PacketBuffer.BODY_LEN +__bodyLen
	-- write 2 flags and message type, for client, is always 0
	__buf:rawPack(
		__buf:_getLC("hb3ihb"),
		__packetLen,
		PacketBuffer.MASK1, 
		PacketBuffer.MASK2, 
		0,
		__bodyLen,
		method,
		ver
		)
	__buf:writeBuf(__bodyBA:getPack())
	--__buf:writeBytes(__bodyBA)
	return __buf
end

function PacketBuffer.new()
	local obj = setmetatable({}, {__index = PacketBuffer})
	obj:init()
	return obj
end

function PacketBuffer:init()
	self._buf = PacketBuffer.getBaseBA()
end

--- Get a byte stream and analyze it, return a splited table
-- Generally, the table include a message, but if it receive 2 packets meanwhile, then it includs 2 messages.
function PacketBuffer:parsePackets(__byteString)
	local __msgs = {}
	local __pos = 0
	self._buf:setPos(self._buf:getLen()+1)
	self._buf:writeBuf(__byteString)
	self._buf:setPos(1)
	local __flag1 = nil
	local __flag2 = nil
	local __preLen = PacketBuffer.FLAG_LEN + PacketBuffer.TYPE_LEN + PacketBuffer.BODY_LEN
	--printf("start analyzing... buffer len: %u, available: %u", self._buf:getLen(), self._buf:getAvailable())
	while self._buf:getAvailable() >= __preLen do
		__flag1 = self._buf:readByte()
		--if bit.band(__flag1 ,PacketBuffer.MASK1) == __flag1 then
		if __flag1 == PacketBuffer.MASK1 then
			__flag2 = self._buf:readByte()
			--if bit.band(__flag2, PacketBuffer.MASK2) == __flag2 then
			if __flag2 ==  PacketBuffer.MASK2 then
				-- skip type value, client isn't needs it
				self._buf:setPos(self._buf:getPos()+1)
				local __bodyLen = self._buf:readInt()
				local __pos = self._buf:getPos()
				-- buffer is not enougth, waiting...
				--print("buffuer:", self._buf:toString())
				if self._buf:getAvailable() < __bodyLen then 
					-- restore the position to the head of data, behind while loop, 
					-- we will save this incomplete buffer in a new buffer,
					-- and wait next parsePackets performation.
					--printf("received data is not enough, waiting... need %u, get %u", __bodyLen, self._buf:getAvailable())
					self._buf:setPos(self._buf:getPos() - __preLen)
					break 
				end
				if __bodyLen <= PacketBuffer.PACKET_MAX_LEN then
					local __method = self._buf:readShort()
					local __ver = self._buf:readByte()
					local bodyLen = __bodyLen - PacketBuffer.METHOD_LEN - PacketBuffer.VER_LEN
					local buf = self._buf:createSubBuf(self._buf:getPos(), bodyLen)
					self._buf:setPos(self._buf:getPos() + bodyLen)
					local content = Protocol.getReceive(__method, __ver)
					if content then
						local __msg = {}
						__msg.method = __method
						__msg.ver = __ver
						local bSucc, __body, sErr = pcall(PacketBuffer._parseBody,buf, content)
						if not bSucc then
							print("__body",__body)
						end
						if __body then
							__msg.body = __body
							__msgs[#__msgs+1] = __msg
						else
							print("parsePackets",sErr)
						end
					else
						print(string.format("there is not such protocol %x", __method))
					end
                end
            end
        end
	end
	-- clear buffer on exhausted
	if self._buf:getAvailable() <= 0 then
		self:init()
	else
		-- some datas in buffer yet, write them to a new blank buffer.
		local __tmp = PacketBuffer.getBaseBA()
		self._buf:readBytes(__tmp, 1, self._buf:getAvailable())
		self._buf = __tmp
	end
	return __msgs
end

return PacketBuffer
