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
--             佛祖保佑       永无BUG             --

module("TimerManager", package.seeall)
-- local TimerManager = {}

local bInit = false
local timerList = {}
local timeOutList = {}
local timeOutKey = 0
local scheduleId = 0
local update 

local function init()
    if bInit then 
        return 
    end
    bInit = true
    cc.Director:getInstance():getScheduler():scheduleScriptFunc(update, 0, false)
end

function update(dt)
    for k, v in pairs(timeOutList) do
        if (v) then
            local newdt = v.dt + dt
            if (newdt >= v.timeout) then
                TimerManager.clearTimeOut(k)
--                ccprint(k,v.timeout,v.arg)
                if v.arg then
                   v.handler(v.arg)
                else
                    v.handler(newdt)
                end

            else
                v.dt = newdt
            end
        end
    end

    for k, v in pairs(timerList) do
        if (v) then
            local newdt = v.dt + dt
            if (newdt >= v.interval) then
                if v.arg then
                    v.handler(v.arg,newdt)
                else
                    v.handler(newdt)
                end
                v.dt = 0
            else
                v.dt = newdt
            end
        end
    end
end

function TimerManager.addTimeOut(handler, timeout, arg)
    timeOutKey = timeOutKey + 1
    timeOutList[timeOutKey] = { handler = handler, timeout = timeout, arg = arg, dt = 0, key = timeOutKey }
    return timeOutKey
end

function TimerManager.clearTimeOut(tid)
    if tid then
    timeOutList[tid] = nil
    end
end

function TimerManager.addTimer(key,handler, interval, arg,dt)
    local tt = nil
    local dt = dt or 0
    if(not timerList[key]) then
       tt = { handler = handler, interval = interval, arg = arg, dt = dt}
       timerList[key] = tt
    else
       tt = timerList[key]
      ccprint(key .. "重复添加定时器")
    end
    return tt
end

function TimerManager.clearTimer(key)
    if key then
    timerList[key] = nil
    end
end

function TimerManager.scheduleGlobal(handler, interval, arg)
    scheduleId = scheduleId+1
    local key = "sUG" .. scheduleId
    if interval then
        TimerManager.addTimer(key,handler, interval, arg)
    else
        TimerManager.addTimer(key,handler, 0, arg)
    end
    return key
end

function TimerManager.unscheduleGlobal(key)
    TimerManager.clearTimer(key)
end

function TimerManager.printTimerInformation()
    local result = ""
    for id,ele in pairs(timerList) do
--        if ele then
--            ccprint(id)
--        end
result = result .. id ..","
    end
end

function TimerManager.getTimerInformation()
    local  result = ""
    local count = 0
    for id,ele in pairs(timerList) do
--        if ele then
            count = count+1
--            ccprint(id)
--        end
    end
    result=result.." timer:"..count
    
    count = 0
    for id,ele in pairs(timeOutList) do
--        if ele then
            count = count+1
--        end
    end
    result=result.." timerout:"..count

    return result
end

init()
-- return TimerManager