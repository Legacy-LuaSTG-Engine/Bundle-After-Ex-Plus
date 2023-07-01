local test = require("test.tester")
local try = require("std.try").try

test.set_module_name("std.try")

test.case("basic call", function()
    try(function()
    end).catch("1", function(_)
    end).catch("2", function(_)
    end).catch(function(_)
    end).finally(function()
    end).execute()
end)

test.case("catch", function()
    local flag = false
    try(function()
        error()
    end).catch(function(e)
        flag = true
    end).execute()
    assert(flag)
end)

test.case("catch case", function()
    -- 1
    try(function()
        error("1")
    end).catch("1", function(e)
        assert(true)
    end).catch("2", function(e)
        assert(false)
    end).execute()
    -- 2
    try(function()
        error("2")
    end).catch("1", function(e)
        assert(false)
    end).catch("2", function(e)
        assert(true)
    end).execute()
end)

test.case("catch fallback", function()
    try(function()
        error("3")
    end).catch("1", function(e)
        assert(false)
    end).catch("2", function(e)
        assert(false)
    end).catch(function(e)
        assert(true)
    end).execute()
end)

test.case("finally", function()
    local flag = false
    try(function()
    end).finally(function()
        flag = true
    end).execute()
    assert(flag)
end)

test.case("catch finally flow", function()
    ---@type number[]
    local list = {}
    try(function()
        table.insert(list, 1)
        error()
    end).catch(function(e)
        table.insert(list, 2)
    end).finally(function()
        table.insert(list, 3)
    end).execute()
    for i, v in ipairs(list) do
        assert(i == v)
    end
end)
