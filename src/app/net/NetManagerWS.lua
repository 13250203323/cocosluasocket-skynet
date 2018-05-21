--
-- Author: chenlinhui
-- Date: 2018-05-15 15:05:30
-- Desc: websocket

local NetManagerWS = class("NetManagerWS")

function NetManagerWS:ctor()
	self.isConnect = false
	self.send_list = {}

	self.socket = nil
end

function NetManagerWS:open(data)
	print(">>>>>>>>>>>>>>>>>>>>>open", data)
end

function NetManagerWS:message(data)
	print(">>>>>>>>>>>>>>>>>>>>>message", data)
end

function NetManagerWS:close(data)
	print(">>>>>>>>>>>>>>>>>>>>>close", data)
end

function NetManagerWS:error(data)
	print(">>>>>>>>>>>>>>>>>>>>>error", data)
end

function NetManagerWS:connect(ip, port)
	if self.socket then 
		return 
	end
	self.socket = cc.WebSocket:create(string.format("ws://%s:%d", ip, port))

	self.socket:registerScriptHandler(handler(self, self.open), cc.WEBSOCKET_OPEN)
	self.socket:registerScriptHandler(handler(self, self.message), cc.WEBSOCKET_MESSAGE)
	self.socket:registerScriptHandler(handler(self, self.close), cc.WEBSOCKET_CLOSE)
	self.socket:registerScriptHandler(handler(self, self.error), cc.WEBSOCKET_ERROR)
end

function NetManagerWS:send(tos)
	if not tos then return end
	tos:encode()
	local str = tos.byte:toString()
	print(">>>>>>>>>>>>>>>>>", str)
	self.socket:sendString(str)
end

local instance
function NetManagerWS:getInstance()
	if not instance then 
		instance = NetManagerWS.new()
	end
	return instance
end 

return NetManagerWS
