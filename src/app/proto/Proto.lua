--
-- Author: chenlinhui
-- Date: 2018-05-18 14:35:16
--
module("Proto", package.seeall)
local PacketBuffer = cc.utils.PacketBuffer

local function encode(protoid, tbl)
	return PacketBuffer.createPackage(tbl, protoid)
end

function Proto.m_role_login_tos()
	local tbl = {name = ""}
	return tbl, handler(1001, encode)
end

function Proto.p_1001(buffer)
	return PacketBuffer.parsePackage(buffer)
end

function Proto.m_role_chat_tos()
	local tbl = {name = "", content = ""}
	return tbl, handler(encode, protoid)
end

function Proto.p_1002(buffer)
	return PacketBuffer.parsePackage(buffer)
end
