local array = require("std.array")
local try = require("std.try").try
local tester = require("test.tester")

tester.set_module_name("std.array")

tester.case("create", function()
    array.create(1)
    array.create(1, 0)
    array.create(1, 0.0)
    array.create(1, true)
    array.create(1, false)
    array.create(1, "")
    array.create(1, "string")
    array.create(10)
    array.create(10, 0)
    array.create(10, 0.0)
    array.create(10, true)
    array.create(10, false)
    array.create(10, "")
    array.create(10, "string")
end)

tester.case("length", function()
    for i = 1, 10 do
        local t = array.create(i, 0)
        assert(#t == i)
    end
end)

tester.case("value", function()
    local t = array.create(10, 123)
    for i = 1, 10 do
        assert(t[i] == 123)
        t[i] = 456
        assert(t[i] == 456)
    end
end)

tester.case("out of bound", function()
    local t = array.create(10, 0)
    local flag = false

    try(function()
        t[11] = 0
    end).catch("out of array bound", function(e)
        flag = true
    end).execute()
    assert(flag)

    flag = false
    try(function()
        t[0] = 0
    end).catch("out of array bound", function(e)
        flag = true
    end).execute()
    assert(flag)

    flag = false
    try(function()
        print(t[11])
    end).catch("out of array bound", function(e)
        flag = true
    end).execute()
    assert(flag)

    flag = false
    try(function()
        print(t[0])
    end).catch("out of array bound", function(e)
        flag = true
    end).execute()
    assert(flag)
end)
