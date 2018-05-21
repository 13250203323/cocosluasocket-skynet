--
-- Author: chenlinhui
-- Date: 2018-05-17 17:15:20
--

module("ProtoManager", package.seeall)
local eventListener = {}

function addEventListener(protoName, listener)
	assert(type(listener) == "function", "listener is not a func")
	if eventListener[protoName] then 
		error("重复监听协议...", protoName)
		return
	end
	eventListener[protoName] = listener
end

function removeEventListener(protoName)
	eventListener[protoName] = nil
end

function dispatchEvent(protoName, buffer)
	local listener = eventListener[protoName]
	if not listener then 
		print("收到未监听协议...", protoName)
		return
	end
	local func = Proto["p_"..protoName]
	if not func then 
		error("未找到协议...p_", protoName)
		return 
	end
	listener(func(buffer))
end