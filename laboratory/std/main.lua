lstg.FileManager.AddSearchPath("../../game/packages/thlib-experiment/")

function FrameFunc()
	return true
end

local assert = require("std.assert")
local algorithm = require("std.algorithm")

local values = { 5, 75, 614, 45, 485362, 1, 6, 4, 3, 7, 9, 4 }

algorithm.quick_sort(values)

for i, v in ipairs(values) do
    print(i, v)
end

local function func1(name, value)
    assert.is_false(value, "false excepted")
end

func1("k", 0 == 0)
