--
-- Author: chenlinhui
-- Date: 2018-05-18 15:01:26
--

module("LoginController", package.seeall)

function init()
	ProtoManager.addEventListener(ProtoName.role_login, m_role_login_toc)
end

function m_role_login_toc(proto)
	print(">>>>>>>>>>>>>>>>>>>>>>>")
	print(dump(proto))
end
