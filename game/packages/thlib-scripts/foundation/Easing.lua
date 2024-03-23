--- SPDX-License-Identifier: MIT
--- Author: OLC

local pi = math.pi
local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin

local c1 = 1.70158;
local c2 = c1 * 1.525;
local c3 = c1 + 1;
local c4 = (2 * pi) / 3;
local c5 = (2 * pi) / 4.5;
local n1 = 7.5625;
local d1 = 2.75;

---@class foundation.Easing
local lib = {}

---插值计算
---@param from number
---@param to number
---@param i number
---@param func function
---@return number
local function interpolation(from, to, i, func)
    return from + (to - from) * func(i)
end
lib.interpolation = interpolation

---构造迭代器
---@param from number
---@param to number
---@param part number
---@param head boolean
---@param tail boolean
---@param func function
---@return function
local function iterator(from, to, part, head, tail, func)
    local n = 0
    if head and tail then
        local p = part - 1
        return function()
            if n < part then
                local result = interpolation(from, to, n / p, func)
                n = n + 1
                return result
            end
        end
    elseif head then
        return function()
            if n < part then
                local result = interpolation(from, to, n / part, func)
                n = n + 1
                return result
            end
        end
    elseif tail then
        return function()
            if n < part then
                n = n + 1
                return interpolation(from, to, n / part, func)
            end
        end
    else
        local p = part + 1
        return function()
            if n < part then
                n = n + 1
                return interpolation(from, to, n / p, func)
            end
        end
    end
end
lib.iterator = iterator

---线性
---@param x number
---@return number
local function linear(x)
    return x
end
lib.linear = linear

---https://easings.net/#easeInQuad
---@param x number
---@return number
local function easeInQuad(x)
    return x * x
end
lib.easeInQuad = easeInQuad

---https://easings.net/#easeOutQuad
---@param x number
---@return number
local function easeOutQuad(x)
    return x * 2 - x * x
end
lib.easeOutQuad = easeOutQuad

---easeInOutQuad
---@param x number
---@return number
local function easeInOutQuad(x)
    return x < 0.5 and x * x * 2 or -2 * x * x + 4 * x - 1
end
lib.easeInOutQuad = easeInOutQuad

---https://easings.net/#easeInSine
---@param x number
---@return number
local function easeInSine(x)
    return 1 - cos((x * pi) / 2)
end
lib.easeInSine = easeInSine

---https://easings.net/#easeOutSine
---@param x number
---@return number
local function easeOutSine(x)
    return sin((x * pi) / 2);
end
lib.easeOutSine = easeOutSine

---https://easings.net/#easeInOutSine
---@param x number
---@return number
local function easeInOutSine(x)
    return -(cos(x * pi) - 1) / 2;
end
lib.easeInOutSine = easeInOutSine

---https://easings.net/#easeInCubic
---@param x number
---@return number
local function easeInCubic(x)
    return x ^ 3
end
lib.easeInCubic = easeInCubic

---https://easings.net/#easeOutCubic
---@param x number
---@return number
local function easeOutCubic(x)
    return 1 - (1 - x) ^ 3
end
lib.easeOutCubic = easeOutCubic

---https://easings.net/#easeInOutCubic
---@param x number
---@return number
local function easeInOutCubic(x)
    return x < 0.5 and x ^ 3 * 4 or 1 - ((-2 * x + 2) ^ 3) / 2
end
lib.easeInOutCubic = easeInOutCubic

---https://easings.net/#easeInQuart
---@param x number
---@return number
local function easeInQuart(x)
    return x ^ 4
end
lib.easeInQuart = easeInQuart

---https://easings.net/#easeOutQuart
---@param x number
---@return number
local function easeOutQuart(x)
    return 1 - (1 - x) ^ 4
end
lib.easeOutQuart = easeOutQuart

---https://easings.net/#easeInOutQuart
---@param x number
---@return number
local function easeInOutQuart(x)
    return x < 0.5 and x ^ 4 * 8 or 1 - ((-2 * x + 2) ^ 4) / 2
end
lib.easeInOutQuart = easeInOutQuart

---https://easings.net/#easeInQuint
---@param x number
---@return number
local function easeInQuint(x)
    return x ^ 5
end
lib.easeInQuint = easeInQuint

---https://easings.net/#easeOutQuint
---@param x number
---@return number
local function easeOutQuint(x)
    return 1 - (1 - x) ^ 5
end
lib.easeOutQuint = easeOutQuint

---https://easings.net/#easeInOutQuint
---@param x number
---@return number
local function easeInOutQuint(x)
    return x < 0.5 and x ^ 5 * 16 or 1 - ((-2 * x + 2) ^ 5) / 2
end
lib.easeInOutQuint = easeInOutQuint

---https://easings.net/#easeInExpo
---@param x number
---@return number
local function easeInExpo(x)
    return x == 0 and 0 or 2 ^ (10 * x - 10)
end
lib.easeInExpo = easeInExpo

---https://easings.net/#easeOutExpo
---@param x number
---@return number
local function easeOutExpo(x)
    return x == 1 and 1 or 1 - 2 ^ (-10 * x)
end
lib.easeOutExpo = easeOutExpo

---https://easings.net/#easeInOutExpo
---@param x number
---@return number
local function easeInOutExpo(x)
    return x == 0 and 0 or x == 1 and 1
            or x < 0.5 and 2 ^ (20 * x - 10) / 2 or (2 - 2 ^ (-20 * x + 10)) / 2
end
lib.easeInOutExpo = easeInOutExpo

---https://easings.net/#easeInCirc
---@param x number
---@return number
local function easeInCirc(x)
    return 1 - sqrt(1 - x ^ 2)
end
lib.easeInCirc = easeInCirc

---https://easings.net/#easeOutCirc
---@param x number
---@return number
local function easeOutCirc(x)
    return sqrt(1 - (x - 1) ^ 2)
end
lib.easeOutCirc = easeOutCirc

---https://easings.net/#easeInOutCirc
---@param x number
---@return number
local function easeInOutCirc(x)
    return x < 0.5 and (1 - sqrt(1 - (2 * x) ^ 2)) / 2 or (sqrt(1 - (-2 * x + 2) ^ 2) + 1) / 2
end
lib.easeInOutCirc = easeInOutCirc

---https://easings.net/#easeInBack
---@param x number
---@return number
local function easeInBack(x)
    return c3 * x * x * x - c1 * x * x
end
lib.easeInBack = easeInBack

---https://easings.net/#easeOutBack
---@param x number
---@return number
local function easeOutBack(x)
    return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end
lib.easeOutBack = easeOutBack

---https://easings.net/#easeInOutBack
---@param x number
---@return number
local function easeInOutBack(x)
    return x < 0.5 and ((2 * x) ^ 2 * ((c2 + 1) * 2 * x - c2)) / 2
            or ((2 * x - 2) ^ 2 * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2
end
lib.easeInOutBack = easeInOutBack

---https://easings.net/#easeInElastic
---@param x number
---@return number
local function easeInElastic(x)
    return x == 0 and 0 or x == 1 and 1 or -2 ^ (10 * x - 10) * sin((x * 10 - 10.75) * c4)
end
lib.easeInElastic = easeInElastic

---https://easings.net/#easeOutElastic
---@param x number
---@return number
local function easeOutElastic(x)
    return x == 0 and 0 or x == 1 and 1 or 2 ^ (-10 * x) * sin((x * 10 - 0.75) * c4) + 1
end
lib.easeOutElastic = easeOutElastic

---https://easings.net/#easeInOutElastic
---@param x number
---@return number
local function easeInOutElastic(x)
    return x == 0 and 0 or x == 1 and 1 or x < 0.5
            and -(2 ^ (20 * x - 10) * sin((20 * x - 11.125) * c5)) / 2
            or (2 ^ (-20 * x + 10) * sin((20 * x - 11.125) * c5)) / 2 + 1
end
lib.easeInOutElastic = easeInOutElastic

---@param x number
---@return number
local function bounce(x)
    if (x < 1 / d1) then
        return n1 * x * x;
    elseif (x < 2 / d1) then
        x = x - 1.5 / d1
        return n1 * x * x + 0.75;
    elseif (x < 2.5 / d1) then
        x = x - 2.25  / d1
        return n1 * x * x + 0.9375;
    else
        x = x - 2.625 / d1
        return n1 * x * x + 0.984375;
    end
end

---https://easings.net/#easeInBounce
---@param x number
---@return number
local function easeInBounce(x)
    return 1 - bounce(1 - x)
end
lib.easeInBounce = easeInBounce

---https://easings.net/#easeOutBounce
---@param x number
---@return number
local function easeOutBounce(x)
    return bounce(x)
end
lib.easeOutBounce = easeOutBounce

---https://easings.net/#easeInOutBounce
---@param x number
---@return number
local function easeInOutBounce(x)
    return x < 0.5 and (1 - bounce(1 - 2 * x)) / 2 or (1 + bounce(2 * x - 1)) / 2
end
lib.easeInOutBounce = easeInOutBounce

return lib
