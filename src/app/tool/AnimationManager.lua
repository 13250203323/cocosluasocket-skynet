--
-- Author: chenlinhui
-- Date: 2017-12-25 14:46:26
-- 
--                   _ooOoo_
--                  o8888888o
--                  88" . "88
--                  (| -_- |)
--                  O\  =  /O
--               ____/`---'\____
--             .'  \\|     |//  `.
--            /  \\|||  :  |||//  \
--           /  _||||| -:- |||||-  \
--           |   | \\\  -  /// |   |
--           | \_|  ''\---/''  |   |
--           \  .-\__  `-`  ___/-. /
--         ___`. .'  /--.--\  `. . __
--      ."" '<  `.___\_<|>_/___.'  >'"".
--     | | :  `- \`.;`\ _ /`;.`/ - ` : | |
--     \  \ `-.   \_ __\ /__ _/   .-` /  /
--======`-.____`-.___\_____/___.-`____.-'======
--                   `=---='
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--             佛祖保佑       永无BUG       

-- module("AnimationManager", package.seeall)
local AnimationManager = {}

local fc = cc.SpriteFrameCache:getInstance()
-- local tc = cc.Director:getInstance():getTextureCache()


--@file：资源名
--@endIndex：最大帧数
--@perTime：每帧间隔时间
--@loop：是否循环
--@resetFrame：是否重置第一帧
function AnimationManager.showEffect(file, endIndex, perTime, loop, resetFrame)
	assert(file, "file error")
	endIndex = endIndex or 1
	loop = (loop == nil and true) or false
	perTime = perTime or 0.1
	local sprite = display.newSprite(string.format("#%s1.png", file))
	local animation = cc.Animation:create() 
	for i=1, endIndex do  
	    local frameName = string.format("%s%d.png", file, i) 
	    local spriteFrame = fc:getSpriteFrame(frameName)
	   animation:addSpriteFrame(spriteFrame) 
	end  

	animation:setDelayPerUnit(perTime)
	if resetFrame then 
		animation:setRestoreOriginalFrame(resetFrame)
	end

	local action = cc.Animate:create(animation)  
	if loop then 
		sprite:runAction(cc.RepeatForever:create(action))
	else
		sprite:runAction(action)
	end

	return sprite
end

return AnimationManager