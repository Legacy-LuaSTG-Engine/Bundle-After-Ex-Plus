lstg.FileManager.AddSearchPath("../../game/packages/thlib-experiment/")

function FrameFunc()
	return true
end

local algorithm = require("std.algorithm")

local values = { 5, 75, 614, 45, 485362, 1, 6, 4, 3, 7, 9, 4 }

algorithm.quick_sort(values)

for i, v in ipairs(values) do
    print(i, v)
end
