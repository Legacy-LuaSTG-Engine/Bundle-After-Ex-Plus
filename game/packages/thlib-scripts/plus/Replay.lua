local KEY_BIT = { 128, 64, 32, 16, 8, 4, 2, 1 }
local KEY_NAME = { "up", "down", "left", "right", "slow", "shoot", "spell", "special" }

--! @brief 将按键状态转换为二进制数值
--! @return 返回二进制按键数值
local function KeyState2Byte(state)
    local ret = 0
    for i, k in ipairs(KEY_NAME) do
        if state[k] then
            ret = ret + KEY_BIT[i]
        end
    end
    return ret
end

--! @brief 将二进制数值转换为按键状态
local function Byte2KeyState(state, b)
    for i, k in ipairs(KEY_NAME) do
        if b >= KEY_BIT[i] then
            state[k] = true
            b = b - KEY_BIT[i]
        else
            state[k] = false
        end
    end
end

-------------------------------------------------- ReplayFrameReader

---@class plus.ReplayFrameReader
local ReplayFrameReader = plus.Class()
plus.ReplayFrameReader = ReplayFrameReader

--! @brief 构造ReplayFrameReader
--! @param path 文件路径
--! @param offset 录像数据偏移
--! @param count 录像帧数量
---@param path string
---@param offset number
---@param count number
function ReplayFrameReader:init(path, offset, count)
    self._fs = plus.FileStream(path, "rb")

    -- 定位到录像数据开始位置
    self._fs:Seek(offset)
    self._offset = offset
    self._read = 0  -- 已读取数量
    self._count = count  -- 帧数量
end

--! @brief 下一帧
--! @return 若达到结尾则返回False，否则返回True
function ReplayFrameReader:Next(state)
    if self._read >= self._count then
        return false
    else
        local ret = self._fs:ReadByte()
        self._read = self._read + 1
        Byte2KeyState(state, ret)
        return true
    end
end

---@param byte_array number[]
---@param count number
---@return boolean
function ReplayFrameReader:Read(byte_array, count)
    if self._read >= self._count then
        return false
    else
        for i = 1, count do
            byte_array[i] = self._fs:ReadByte()
        end
        self._read = self._read + count
        return true
    end
end

--! @brief 重置
function ReplayFrameReader:Reset()
    self._read = 0
    self._fs:Seek(self._offset)
end

--! @brief 关闭文件流
function ReplayFrameReader:Close()
    self._fs:Close()
end

-------------------------------------------------- ReplayFrameWriter

---@class plus.ReplayFrameWriter
local ReplayFrameWriter = plus.Class()
plus.ReplayFrameWriter = ReplayFrameWriter

function ReplayFrameWriter:init()
    self._data = {}
    self._count = 0
end

function ReplayFrameWriter:Record(state)
    local b = KeyState2Byte(state)
    self._count = self._count + 1
    self._data[self._count] = b
end

---@param byte_array number[]
function ReplayFrameWriter:Write(byte_array)
    if type(byte_array) == "string" then
        -- 兼容性处理
        -- aex+0.8.21 将 Write 重命名为 CopyToFileStream
        -- 然后添加了功能完全不一样的 Write 函数，但更匹配函数名称
        ---@diagnostic disable-next-line: param-type-mismatch
        return self:CopyToFileStream(byte_array)
    end
    for _, b in ipairs(byte_array) do
        self._count = self._count + 1
        self._data[self._count] = b
    end
end

---@param fs plus.FileStream
function ReplayFrameWriter:CopyToFileStream(fs)
    for i = 1, self._count do
        fs:WriteByte(self._data[i])
    end
end

function ReplayFrameWriter:GetCount()
    return self._count
end

-------------------------------------------------- ReplayManager

---@class plus.ReplayManager.ReadData.StageData
local _ = {
    stageName = "",
    stageExtendInfo = "",
    score = 0,
    randomSeed = 0,
    stageTime = 0,
    stageDate = 0,
    stagePlayer = "",
    frameCount = 0,
    frameDataPosition = 0,
}

---@class plus.ReplayManager.ReadData
local _ = {
    path = "",
    fileVersion = 0,
    gameName = "",
    gameVersion = 1,
    gameExtendInfo = "",
    userName = "",
    userExtendInfo = "",
    group_finish = 0,
    ---@type plus.ReplayManager.ReadData.StageData[]
    stages = {},
}

---@class plus.ReplayManager.SaveData.StageData
local _ = {
    stageName = "",
    stageExtendInfo = "",
    score = 0,
    randomSeed = 0,
    stageTime = 0,
    stageDate = 0,
    stagePlayer = "",
    ---@type plus.ReplayFrameWriter
    frameData = {},
}

---@class plus.ReplayManager.SaveData
local _ = {
    gameName = "",
    gameVersion = 1,
    gameExtendInfo = "",
    userName = "",
    userExtendInfo = "",
    group_finish = 0,
    ---@type plus.ReplayManager.SaveData.StageData[]
    stages = {},
}

---@class plus.ReplayManager
local ReplayManager = plus.Class()
plus.ReplayManager = ReplayManager

--! @brief 构造ReplayManager
--! @param replayDirectory 录像文件夹
---@param replayDirectory string
function ReplayManager:init(replayDirectory)
    self._repdir = replayDirectory
    self._filefmt = "slot(%d+).rep"
    self._filefmt2 = "slot%d.rep"
    self._slots = nil
    self._slotmax = 16

    -- 确保录像目录存在
    lstg.FileManager.CreateDirectory(replayDirectory)
    
    -- 刷新录像数据
    self:Refresh()
end

--! @brief [静态函数]读取录像数据
--!
--! 返回的录像数据信息以下述格式表述：
--!  {
--!    path = "文件路径",
--!    fileVersion = 1, gameName = "游戏名称", gameVersion = 1, gameExtendInfo = "",
--!    userName = "用户名", userExtendInfo = "用户额外信息",
--!    stages = {
--!      {
--!        stageName = "关卡名称", stageExtendInfo = "", score = 0, randomSeed = 0,
--!        stageTime = 0, stageDate = 0, stagePlayer=lstg.var.rep_player，
--！       frameCount = 300, frameDataPosition = 12345
--!      }
--!    }
--!  }
---@return plus.ReplayManager.ReadData
function ReplayManager.ReadReplayInfo(path)
    ---@type plus.ReplayManager.ReadData
    local ret = { path = path }
    local f = plus.FileStream(path, "rb")
    local r = plus.BinaryReader(f)

    plus.TryCatch {
        try = function()
            -- 读取文件头
            assert(r:ReadString(4) == "STGR", "invalid file format.")

            -- 版本号1
            ret.fileVersion = r:ReadUShort()  -- 文件版本
            assert(ret.fileVersion == 1, "unsupported file version.")

            -- 游戏数据
            local gameNameLength = r:ReadUShort()  -- 游戏名称
            ret.gameName = r:ReadString(gameNameLength)
            ret.gameVersion = r:ReadUShort()  -- 游戏版本
            ret.group_finish = r:ReadUShort() --是否完成关卡
            local gameExtendInfoLength = r:ReadUInt()  -- 额外信息
            ret.gameExtendInfo = r:ReadString(gameExtendInfoLength)

            -- 玩家信息
            local userNameLength = r:ReadUShort()  -- 机签
            ret.userName = r:ReadString(userNameLength)
            local userExtendInfoLength = r:ReadUInt()  -- 额外信息
            ret.userExtendInfo = r:ReadString(userExtendInfoLength)

            -- 关卡数据
            ret.stages = {}
            local recordStageCount = r:ReadUShort()  -- 关卡数量
            for i = 1, recordStageCount do
                local stage = {}

                local stageNameLength = r:ReadUShort()  -- 关卡名称
                stage.stageName = r:ReadString(stageNameLength)
                local stageExtendInfoLength = r:ReadUInt()  -- 额外信息
                stage.stageExtendInfo = r:ReadString(stageExtendInfoLength)
                local scoreHigh = r:ReadUInt()  -- 分数的高32位
                local scoreLow = r:ReadUInt()  -- 分数的低32位
                stage.score = scoreLow + scoreHigh * 0x100000000
                stage.randomSeed = r:ReadUInt()  -- 随机数种子
                stage.stageTime = r:ReadFloat()  -- 通关时间
                stage.stageDate = r:ReadUInt()  -- 游戏日期(UNIX时间戳)
                local stagePlayerLength = r:ReadUShort()  -- 使用自机
                stage.stagePlayer = r:ReadString(stagePlayerLength)
                --                   local stage_num = r:ReadUShort()  --关卡所在位置
                --                   stage.cur_stage_num = stage_num
                --                   stage.group_num= r:ReadUShort() --关卡组长度
                -- 录像数据
                stage.frameCount = r:ReadUInt()  -- 帧数
                stage.frameDataPosition = f:GetPosition()  -- 数据起始位置
                f:Seek(stage.frameCount)  -- 跳过帧数据

                table.insert(ret.stages, stage)
            end
        end,
        finally = function()
            f:Close()
        end
    }

    return ret
end

--! @brief [静态函数]写入录像数据
--!
--! 输入的录像信息需要满足下述表述：
--!  {
--!    gameName = "游戏名称", gameVersion = 1, gameExtendInfo = "额外信息",
--!    userName = "用户名", userExtendInfo = "用户额外信息",
--!    stages = {
--!      {
--!        stageName = "关卡名称", stageExtendInfo = "", score = 0, randomSeed = 0,
--!        stageTime = 0, stageDate = 0, stagePlayer=lstg.var.rep_player，
--！       frameData = ReplayFrameWriter()
--!      }
--!    }
--!  }
---@param path string
---@param data plus.ReplayManager.SaveData
function ReplayManager.SaveReplayInfo(path, data)
    local f = plus.FileStream(path, "wb")
    local w = plus.BinaryWriter(f)
    --用于记录当前replay文件是否已经完整保存
    --如果保存中途出错，那么该文件会在finally函数中删除，防止下次进入游戏时读取到损坏的录像文件导致再次炸游戏
    local _save_finish = false

    plus.TryCatch {
        try = function()
            -- 写入文件头
            w:WriteString("STGR", false)

            -- 版本号1
            w:WriteUShort(1)

            -- 游戏数据
            w:WriteUShort(string.len(data.gameName))  -- 游戏名称
            w:WriteString(data.gameName, false)
            w:WriteUShort(data.gameVersion)  -- 游戏版本
            w:WriteUShort(data.group_finish) --是否完成关卡
            if data.gameExtendInfo then
                w:WriteUInt(string.len(data.gameExtendInfo))  -- 额外信息
                w:WriteString(data.gameExtendInfo, false)
            else
                w:WriteUInt(0)
            end

            -- 玩家信息
            w:WriteUShort(string.len(data.userName))  -- 机签
            w:WriteString(data.userName, false)
            if data.userExtendInfo then
                w:WriteUInt(string.len(data.userExtendInfo))  -- 额外信息
                w:WriteString(data.userExtendInfo, false)
            else
                w:WriteUInt(0)
            end

            -- 关卡数据
            local stageCount = #data.stages
            w:WriteUShort(stageCount)  -- 关卡数量
            for i = 1, stageCount do
                local stage = data.stages[i]

                w:WriteUShort(string.len(stage.stageName))  -- 关卡名称
                w:WriteString(stage.stageName, false)
                if stage.stageExtendInfo then
                    w:WriteUInt(string.len(stage.stageExtendInfo))  -- 额外信息
                    w:WriteString(stage.stageExtendInfo, false)
                else
                    w:WriteUInt(0)
                end
                w:WriteUInt(math.floor(stage.score / 0x100000000))  -- 分数的高32位
                w:WriteUInt(math.floor(stage.score % 0x100000000))  -- 分数的低32位
                w:WriteUInt(stage.randomSeed)  -- 随机数种子
                w:WriteFloat(stage.stageTime or 0)  -- 通关时间
                w:WriteUInt(stage.stageDate or 0)  -- 游戏日期(UNIX时间戳)
                w:WriteUShort(string.len(stage.stagePlayer))  -- 使用自机
                w:WriteString(stage.stagePlayer, false)
                --                   w:WriteUShort(stage.cur_stage_num)--关卡所在位置
                --                   w:WriteUShort(stage.group_num)  --关卡组长度
                -- 录像数据
                w:WriteUInt(stage.frameData:GetCount())  -- 帧数
                stage.frameData:CopyToFileStream(f)  -- 数据
            end

            _save_finish = true
        end,
        finally = function()
            f:Close()
            if not (_save_finish) then
                f:Delete()--by ETC
            end
        end
    }
end

--! @brief 获取录像目录
function ReplayManager:GetReplayDirectory()
    return self._repdir
end

--! @brief 构造录像文件名称
function ReplayManager:MakeReplayFilename(slot)
    return self._repdir .. "\\" .. string.format(self._filefmt2, slot)
end

--! @brief 刷新
function ReplayManager:Refresh()
    self._slots = {}
    local files = lstg.FileManager.EnumFiles(self._repdir)
    for _, v in ipairs(files) do
        local filename, isdir = v[1], v[2]
        if not isdir then
            local _, name = plus.SplitPath(filename)
            local _, _, id = string.find(name, self._filefmt)
            if id then
                id = tonumber(id)
                assert(self._slots[id] == nil, "duplicate slot id: " .. id)
                if not (id <= 0 or id > self._slotmax) then
                    plus.TryCatch {
                        try = function()
                            self._slots[id] = ReplayManager.ReadReplayInfo(filename)
                        end,
                        catch = function(err)
                            self._slots[id] = nil
                            lstg.Log(4, "加载录像文件'" .. filename .. "'失败: " .. err)
                        end
                    }
                end
            end
        end
    end
end

--! @brief 获取录像数量
function ReplayManager:GetSlotCount()
    return self._slotmax
end

--! @brief 获取录像信息
--! @param slot 录像槽
function ReplayManager:GetRecord(slot)
    assert(slot >= 0 and slot <= self._slotmax, "invalid argument.")
    return self._slots[slot]
end

-------------------------------------------------- api (IDEA emmylua | vscode sumneko lua)

if false then
    --- 用于代码提示，可以删，但是没必要

    ---@param path string
    ---@param offset number
    ---@param count number
    ---@return plus.ReplayFrameReader
    function plus.ReplayFrameReader(path, offset, count)
        return ReplayFrameReader(path, offset, count)
    end

    ---@return plus.ReplayFrameReader
    function plus.ReplayFrameWriter()
        return ReplayFrameWriter()
    end

    ---@param replayDirectory string
    ---@return plus.ReplayManager
    function plus.ReplayManager(replayDirectory)
        return ReplayManager(replayDirectory)
    end
end
