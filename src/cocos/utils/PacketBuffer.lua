--
-- Author: chenlinhui
-- Date: 2018-05-19 11:17:49
--

local PacketBuffer = {}
local ByteArrayVarint = import(".ByteArrayVarint")

local PACKAGE_LENGTH = 2 -- 包头长度占位
local PACKAGE_PROTOID = 4 -- 协议id长度占位

local parseBuffer_forkey
local parseBuffer_forvalue
-- R:number
-- S:string
-- T:table

local function getBaseBuffer()
	local byte = ByteArrayVarint.new(ByteArrayVarint.ENDIAN_BIG)
	byte:writeUShort(0)
	byte:writeUInt(1001)
	return byte
end

local function getBaseBuffer2()
	local byte = ByteArrayVarint.new(ByteArrayVarint.ENDIAN_BIG)
	return byte
end

local function writeBuffer(buffer, value)
	local type_v = type(value)
	if type_v == "number" then 
		buffer:writeStringUVInt("R")
		buffer:writeUVInt(value)
	elseif type_v == "string" then 
		buffer:writeStringUVInt("S")
		buffer:writeStringUVInt(value)
	else
		error("Error Type key in _createBody", type_v)
	end
end

function PacketBuffer._createBody(body, buffer)
	if not buffer then 
		buffer = getBaseBuffer()
	end

	if type(body) ~= "table" then 
		print("Error argument body in function PacketBuffer._createBody")
		return nil
	end

	for key, value in pairs(body) do
		writeBuffer(buffer, key)
		if type(value) == "table" then 
			buffer:writeStringUVInt("T")
			buffer:writeUVInt(table.nums(value))
			PacketBuffer._createBody(value, buffer)
		else
		 	writeBuffer(buffer, value)
		end
	end
	return buffer
end

function parseBuffer_forkey(buffer, data)
	if not data then 
		data = {}
	end
	local tp = buffer:readStringUVInt()
	if tp == "R" then -- number
		local n = buffer:readUVInt()
		data = parseBuffer_forvalue(buffer, data, n)
	elseif tp == "S" then -- string
		local s = buffer:readStringUVInt()
		data = parseBuffer_forvalue(buffer, data, s)
	else
		error("error type in function parseBuffer_forkey")
	end
	return data
end

function parseBuffer_forvalue(buffer, data, key)
	local tp = buffer:readStringUVInt()
	if tp == "R" then -- number
		data[key] = buffer:readUVInt()
	elseif tp == "S" then -- string
		data[key] = buffer:readStringUVInt()
	elseif tp == "T" then  -- table
		local d = {}
		local len = buffer:readUVInt()
		for i=1, len do
			d = parseBuffer_forkey(buffer, d)
		end
		data[key] = d
	end
	return data
end

function PacketBuffer._parseBody(buffer)
	local byte = getBaseBuffer2()
	byte:writeBuf(buffer)
	byte:setPos(1)
	byte:readUShort() -- 长度
	byte:readUInt() -- 协议id

	local proto, succ
	while byte:getAvailable() > 0 do
		succ, proto = pcall(parseBuffer_forkey, byte, proto)
		if not succ then 
			print(">>>>>>>>>>>>>Parse error!!")
			break
		end
	end
	return proto
end

function PacketBuffer.createPackage(body, protoid)
	local buffer = PacketBuffer._createBody(body)
	local len = buffer:getLen()
	buffer:setPos(1)
	buffer:writeUShort(len)
	buffer:writeUInt(protoid)
	return buffer:getBytes()
end

function PacketBuffer.parsePackage(buffer)
	return PacketBuffer._parseBody(buffer)
end

-- eg:
-- local data = {
-- 	id = 10001,
-- 	name = "linhui",
-- 	item = {
-- 		[1] = 120001,
-- 		[2] = 203002,
-- 	},
-- }
-- ==>>
-- "S"-"id"-"R"-10001-"S"-"name"-"S"-"linhui"-"S"-"item"-"T"-2-"R"-1-"R"-120001-"R"-2-"R"-203002

function PacketBuffer.fortest()
	local data = {
		[1] = 1001,
		name = "linhui", 
		id = 11,
		item = {
			[1] = "lpack",
			color = "purple",
			num = 10,
			co = {
				[1] = 22,
				[3] = 255,
				[2] = 89,
				["sddd"] = "9",
				lin = "..",
				hui = {},
			},
		},
	}

	-- local buffer = PacketBuffer._createBody(data)
	-- print(">>>>>>>", buffer:toString())

	-- local proto = PacketBuffer._parseBody(buffer)
	-- print(">>>>>>>>>>>>>>>>>")
	-- print(dump(proto))
end

return PacketBuffer