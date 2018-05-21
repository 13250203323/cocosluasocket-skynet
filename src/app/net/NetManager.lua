--
-- Author: chenlinhui
-- Date: 2018-05-15 11:34:01
-- Desc: luasocket

local NetManager = class("NetManager")
local socketCore = require("socket.core")
local ByteArrayVarint = cc.utils.ByteArrayVarint

local timerKey = "netmanager"
local PACKAGE_LENGTH = 2 -- 包头长度占位

local connect_is_success
local socketIO
local socket_input
local socket_output
local dealRecvBuffer

function NetManager:ctor()
	self.isConnected = false
	self.send_list = {}
	self.receiveBufffer = ""
	self.byteArray = ByteArrayVarint.new(ByteArrayVarint.ENDIAN_BIG)

	self.socket = socketCore.tcp()
	self.socket:settimeout(0) -- 非阻塞
	self.socket:setoption("tcp-nodelay", true) -- 去掉优化
end

function connect_is_success(self)
	local for_write = {}
	table.insert(for_write, self.socket)
	local _, ready_forwrite, _ = socketCore.select(nil, for_write, 0)
	if #ready_forwrite > 0 then 
		return true
	else
		return false
	end
end

function socketIO(self)
	if not self.isConnected then
		return
	end
	socket_input(self)
	socket_output(self)
end

-- 检查socket是否有内容可读
function socket_input(self)
	-- 检查是否有可读的socket
	local recvt, sendt, status = socketCore.select(nil, {self.socket}, 1)
	if not recvt or #recvt <= 0 then 
		return 
	end

	local recvData, recvError, recvParticialData = self.socket:receive(999999)
	if recvError == "closed" then 
		-- socket已经断开
		if recvParticialData then 
			self.receiveBufffer = recvParticialData
			self.byteArray:writeBuf(recvParticialData)
			dealRecvBuffer(self)
		end
		return 
	end

	if #recvData < PACKAGE_LENGTH then -- 包头长度不够
		self.receiveBufffer = recvData
		self.byteArray:writeBuf(recvData)
		return 
	end

	if recvData then 
		self.receiveBufffer = self.receiveBufffer..recvData
		self.byteArray:writeBuf(recvData)
	elseif recvParticialData then 
		self.receiveBufffer = self.receiveBufffer..recvParticialData
		self.byteArray:writeBuf(recvParticialData)
	end

	self.byteArray:setPos(1)
	local packageLen = self.byteArray:readUShort()
	if packageLen > #self.receiveBufffer then -- 还未接收完
		self.byteArray:setPos(self.byteArray:getAvailable())
		return 
	end

	dealRecvBuffer(self)
end

function dealRecvBuffer(self)
	if #self.receiveBufffer < PACKAGE_LENGTH then -- 不完整信息
		print(">>>>>>>>>>>>>包头长度不够", #self.receiveBufffer, PACKAGE_LENGTH)
		return
	end
	self.byteArray:setPos(1)
	local packageLen = self.byteArray:readUShort()
	if packageLen > #self.receiveBufffer then -- 不完整信息
		print(">>>>>>>>>>>>>不完整信息", packageLen, #self.receiveBufffer)
		return 
	end
	
	-- 派发协议
	local protoid = self.byteArray:readUInt() -- 协议id
	local buffer = string.sub(self.receiveBufffer, 1, packageLen)
	ProtoManager.dispatchEvent(protoid, buffer)

	-- 下一条协议
	local nextBuffer = string.sub(self.receiveBufffer, packageLen+1)
	self.receiveBufffer = nextBuffer
	self.byteArray = ByteArrayVarint.new(ByteArrayVarint.ENDIAN_BIG)
	self.byteArray:writeBuf(nextBuffer)
end

-- 检查socket是否有内容可写
function socket_output(self)
	if self.send_list and #self.send_list > 0 then 
		local data = self.send_list[1]
		if data then 
			self.socket:send(data)
			table.remove(self.send_list, 1)
		end
	end
end

function NetManager:connect(ip, port)
	assert(ip and port, "ip or port error!")
	if self.isConnected then return end

	local result = self.socket:connect(ip, port)
	if not result then 
		error("socket connect error!")
		return 
	end

	TimerManager.clearTimer(timerKey)
	self.socketTimer = TimerManager.scheduleGlobal(function()
		if connect_is_success(self) then 
			self.isConnected = true
			TimerManager.unscheduleGlobal(self.socketTimer)
			self.socketTimer = nil

			self.csTimer = TimerManager.addTimer(timerKey, function()
				socketIO(self)
			end, 0.05)
		end
	end, 1)
end

function NetManager:send(tos)
	if not tos then 
		error("tos is nil")
		return 
	end
    local buffer = tos.encode()
	table.insert(self.send_list, buffer)
end

function NetManager:fortest(buffer)
	self.receiveBufffer = buffer
	self.byteArray:writeBuf(buffer)
	dealRecvBuffer(self)
end

local instance
function NetManager:getInstance()
	if not instance then 
		instance = NetManager.new()
	end
	return instance
end 

return NetManager