----------------------------------------
--- extra stage data

---@type table<string|number,string|number|boolean>|nil
local extraData

---@type table<string|number,string|number|boolean>|nil
local nextData

ext.stage_data = {}

---检查 key 的类型是否合法
---@param key any
---@return boolean
local function checkKeyType(key)
    local keyType = type(key)
    if keyType == "string" or keyType == "number" then
        return true
    else
        lstg.Log(2, string.format("Invalid key type: %s", keyType))
        return false, string.format("Key must be a string or number, got %s", keyType)
    end
end

---检查 value 的类型是否合法
---@param value any
---@return boolean
local function checkValueType(value)
    local valueType = type(value)
    if valueType == "string" or valueType == "number" or valueType == "boolean" then
        return true
    else
        lstg.Log(2, string.format("Invalid value type: %s", valueType))
        return false, string.format("Value must be a string, number, or boolean, got %s", valueType)
    end
end

---设置关卡数据
---@param key string|number
---@param value string|number|boolean
function ext.stage_data.SetStageData(key, value)
    if ext.replay.IsReplay() then
        error("Cannot set stage data in replay mode")
        return
    end

    assert(extraData, "extraData is not initialized")
    assert(checkKeyType(key))
    assert(checkValueType(value))
    extraData[key] = value
end

---获取关卡数据
---@param key string|number
---@return string|number|boolean|nil
function ext.stage_data.GetStageData(key)
    assert(extraData, "extraData is not initialized")
    assert(checkKeyType(key))
    return extraData[key]
end

---装载关卡数据
function ext.stage_data.InitStageData()
    if nextData then
        -- 如果 nextData 已经存在，直接使用它
        extraData = nextData
        nextData = nil
    else
        -- 否则初始化一个新的空表
        extraData = {}
    end
end

---序列化关卡数据
---@return string
function ext.stage_data.SerializeStageData()
    assert(extraData, "extraData is not initialized")
    return Serialize(extraData)
end

---准备关卡数据
---@param data string
function ext.stage_data.PrepareStageData(data)
    assert(type(data) == "string", "Data must be a serialized string")
    nextData = DeSerialize(data)
    assert(type(nextData) == "table", "Deserialized data must be a table")
end