
local MainScene = class("MainScene", cc.load("mvc").ViewBase)
local ByteArray = cc.utils.ByteArray
local ByteArrayVarint = cc.utils.ByteArrayVarint
local PacketBuffer = cc.utils.PacketBuffer

function MainScene:onCreate()
    -- add background image
    -- display.newSprite("HelloWorld.png")
        -- :move(display.center)
        -- :addTo(self)

    -- add HelloWorld label
    -- cc.Label:createWithSystemFont("Hello World", "Arial", 40)
    --     :move(display.cx, display.cy + 200)
    --     :addTo(self)
    -- local str = string.pack(">P", "我是中国人")
    -- print(">>>>>>>>>>>>>>>", str, #str)

    -- print('>>>>>>>>>>>>>>>', string.unpack(str, ">P"))

    -- local netMgr = require("app.net.NetManager"):getInstance()
    -- netMgr:connect("172.22.2.22", 9320)

    -- self:testByteArray()

    -- local netMgr = require("net.NetManagerWS"):getInstance()
    -- netMgr:connect("172.22.2.22", 9320)
    TimerManager.addTimeOut(function()
        self:fortest()
    end, 2)
    
    -- PacketBuffer.fortest()
end

function MainScene:fortest()
    -- local msg, encode = Proto.m_role_login_tos()
    -- msg.name = "linhui"
    -- local b = encode(msg)
    -- NetManager:fortest(b)
end

function MainScene:testByteArray()
    local __pack = self:getDataByLpack()
    print(">>>>>>>>>>>>", __pack)
    local __ba1 = ByteArray.new()
        :writeBuf(__pack)
        :setPos(1)
    print("ba1.len:", __ba1:getLen())
    print("ba1.readByte:", __ba1:readByte())
    print("ba1.readInt:", __ba1:readInt())
    print("ba1.readShort:", __ba1:readShort())
    print("ba1.readString:", __ba1:readStringUShort())
    print("ba1.readString:", __ba1:readStringUShort())
    print("ba1.available:", __ba1:getAvailable())
    print("ba1.toString(16):", __ba1:toString(16))
    print("ba1.toString(10):", __ba1:toString(10))

    local __ba2 = self:getByteArray()
    print("ba2.toString(10):", __ba2:toString(10))


    local __ba3 = ByteArray.new()
    local __str = ""
    for i=1,20 do
        __str = __str.."ABCDEFGHIJ"
    end
    __ba3:writeStringSizeT(__str)
    __ba3:setPos(1)
    print("__ba3:readUInt:", __ba3:readUInt())
    --print("__ba3.readStringSizeT:", __ba3:readStringUInt())
end

function MainScene:getDataByLpack()
    local __pack = string.pack("<bihP2", 0x59, 11, 1101, "", "中文")
    return __pack
end

function MainScene:getByteArray()
    return ByteArray.new()
        :writeByte(0x59)
        :writeInt(11)
        :writeShort(1101)
        :writeStringUShort("")
        :writeStringUShort("中文")
end

return MainScene
