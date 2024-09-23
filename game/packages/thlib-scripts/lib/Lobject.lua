--------------------------------------------------------------------------------
--- LuaSTG 游戏对象类模板创建和注册
--- by 璀境石
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- 预定义的碰撞组

GROUP_GHOST = 0
GROUP_ENEMY_BULLET = 1
GROUP_ENEMY = 2
GROUP_PLAYER_BULLET = 3
GROUP_PLAYER = 4
GROUP_INDES = 5
GROUP_ITEM = 6
GROUP_NONTJT = 7
GROUP_SPELL = 8--由OLC添加，可用于自机bomb
GROUP_CPLAYER = 9

GROUP_ALL = 16
GROUP_NUM_OF_GROUP = 16

--------------------------------------------------------------------------------
--- 预定义的图层

LAYER_BG = -700
LAYER_ENEMY = -600
LAYER_PLAYER_BULLET = -500
LAYER_PLAYER = -400
LAYER_ITEM = -300
LAYER_ENEMY_BULLET = -200
LAYER_ENEMY_BULLET_EF = -100
LAYER_TOP = 0

--------------------------------------------------------------------------------
--- 推荐的代码风格

---@diagnostic disable-next-line: empty-block
if false then
    ------------------------------------------------------------
    --- 1. 尽可能地在局部声明游戏对象类，
    ---    如果要导出给其他 lua 脚本，应该使用 require 机制（见 EX 1 部分）
    ---    即使要导出为全局，也应该分类归纳在 table 中

    my_lib = {}

    local my_bullet_class = lstg.CreateGameObjectClass() -- 或者 Class(object)
    function my_bullet_class:init()
        -- 做点什么
    end
    function my_bullet_class:frame()
        -- 做点什么
    end

    my_lib.bullet_class = my_bullet_class

    ------------------------------------------------------------
    --- 2. 避免使用“继承”概念，
    ---    应当显式调用其他游戏对象类的方法，
    ---    这是 Lua 语言，而不是 C++ C# Java 等面向对象语言，
    ---    除非你愿意通过 metatable 完整模拟带有继承的面向对象，
    ---    且接受可能带来的性能损失

    local my_super_bullet_class = lstg.CreateGameObjectClass() -- 或者 Class(object)
    function my_super_bullet_class:init()
        -- 做点什么
        my_bullet_class.init(self)
        -- 做点什么
    end
    function my_super_bullet_class:frame()
        -- 做点什么
        my_bullet_class.frame(self)
        -- 做点什么
    end

    ------------------------------------------------------------
    --- 3. 不要定义空方法，避免破坏优化
    ---    具体原因请见 lstg.RegisterGameObjectClass 的实现，
    ---    如果使用传统的 Class 函数来初步模拟继承，
    ---    空方法是可接受的，此时会覆盖“父类”的行为

    local my_little_class = lstg.CreateGameObjectClass() -- 或者 Class(object)
    function my_little_class:init()
        -- 做点什么
    end
    -- 不要像这样定义空方法
    --function my_little_class:frame() end

    ------------------------------------------------------------
    --- 4. 使用“工厂模式（定义一个 create 函数生成对象）”，
    ---    而不是使用 init 回调函数，
    ---    这么做的理由是，我们能受益于开发工具的代码提示

    local my_class_1 = lstg.CreateGameObjectClass() -- 或者 Class(object)
    -- 我们不这么做
    --function my_class_1:init(x, y)
    --    self.x = x
    --    self.y = y
    --end
    --- 应该这么做
    ---@param x number
    ---@param y number
    function my_class_1.create(x, y)
        local self = lstg.New(my_class_1)
        self.x = x
        self.y = y
        return self
    end

    do -- 在某个要创建对象的地方
        local x, y = 0, 0
        -- 我们不这么做
        --local obj_1 = lstg.New(my_class_1, x, y)
        -- 应该这么做
        local obj_1 = my_class_1.create(x, y)
    end

    ------------------------------------------------------------
    --- EX 1. 使用 require 机制来导出和导入
    ---       下面的例子中，有两个文件
    ---       一个是 deep/dir/foo.lua
    ---       一个是 bar.lua
    ---       我们在第一个文件中导出一个值和一个函数，
    ---       然后在第二个文件中使用

    do
        -- 这里是 deep/dir/foo.lua
        local foo = {}
        foo.value = 1024
        local local_string = "Hello!"
        function foo.hello()
            return local_string
        end
        return foo
    end

    do
        -- 这里是 bar.lua
        local foo = require("deep.dir.foo")
        print(foo.value)
        print(foo.hello())
    end
end

--------------------------------------------------------------------------------
--- 游戏对象注册

local all_class = {}
setmetatable(all_class, {
    __mode = "k", -- 将类存为表键，并设为弱引用
})

local function empty_callback()
end

local DEFAULT_MASK_INIT = 2
local DEFAULT_MASK_DEL = 4
local DEFAULT_MASK_FRAME = 8
local DEFAULT_MASK_RENDER = 16
local DEFAULT_MASK_COLLI = 32
local DEFAULT_MASK_KILL = 64

--- 这个游戏对象类是否存在默认回调函数  
---@generic T
---@param c T
local function isDefaultCallbackExist(c)
    ---@diagnostic disable-next-line: undefined-field
    if c.init == empty_callback or c.del == empty_callback or c.frame == empty_callback or c.render == lstg.DefaultRenderFunc or c.colli == empty_callback or c.kill == empty_callback then
        return true
    else
        return false
    end
end

--- 创建一个空白的默认的游戏对象类  
--- 等效于调用传统的 Class(object)  
---@generic T
---@return T
function lstg.CreateGameObjectClass()
    local c = {
        empty_callback, -- init
        empty_callback, -- del
        empty_callback, -- frame
        lstg.DefaultRenderFunc, -- render
        empty_callback, -- colli
        empty_callback; -- kill
        is_class = true,
    }
    c.init = empty_callback
    c.del = empty_callback
    c.frame = empty_callback
    c.render = lstg.DefaultRenderFunc
    c.colli = empty_callback
    c.kill = empty_callback
    all_class[c] = true
    return c
end

--- 注册一个游戏对象类的回调函数  
---@generic T
---@param c T
function lstg.RegisterGameObjectClass(c)
    -- 校验类型
    assert(type(c) == "table", "bad argument #1 to 'RegisterGameObjectClass' (table expected)")
    assert(c.is_class, "bad argument #1 to 'RegisterGameObjectClass' (not a class)")
    local init_t = type(c.init)
    local del_t = type(c.del)
    local frame_t = type(c.frame)
    local render_t = type(c.render)
    local colli_t = type(c.colli)
    local kill_t = type(c.kill)
    assert(init_t == "function" or init_t == "nil", "bad argument #1 to 'RegisterGameObjectClass' (invalid init function)")
    assert(del_t == "function" or del_t == "nil", "bad argument #1 to 'RegisterGameObjectClass' (invalid del function)")
    assert(frame_t == "function" or frame_t == "nil", "bad argument #1 to 'RegisterGameObjectClass' (invalid frame function)")
    assert(render_t == "function" or render_t == "nil", "bad argument #1 to 'RegisterGameObjectClass' (invalid render function)")
    assert(colli_t == "function" or colli_t == "nil", "bad argument #1 to 'RegisterGameObjectClass' (invalid colli function)")
    assert(kill_t == "function" or kill_t == "nil", "bad argument #1 to 'RegisterGameObjectClass' (invalid kill function)")
    -- 注册回调函数
    c[1] = c.init
    c[2] = c.del
    c[3] = c.frame
    c[4] = c.render
    c[5] = c.colli
    c[6] = c.kill
    -- 性能优化，如果它没有重载函数，则不再调用这些回调函数
    if isDefaultCallbackExist(c) then
        c.default_function = 0
        if c.init == empty_callback then
            c.default_function = c.default_function + DEFAULT_MASK_INIT
        end
        if c.del == empty_callback then
            c.default_function = c.default_function + DEFAULT_MASK_DEL
        end
        if c.frame == empty_callback then
            c.default_function = c.default_function + DEFAULT_MASK_FRAME
        end
        if c.render == lstg.DefaultRenderFunc then
            c.default_function = c.default_function + DEFAULT_MASK_RENDER
        end
        if c.colli == empty_callback then
            c.default_function = c.default_function + DEFAULT_MASK_COLLI
        end
        if c.kill == empty_callback then
            c.default_function = c.default_function + DEFAULT_MASK_KILL
        end
    end
    -- 这是一个游戏对象类，保存引用以便后续统一重新注册
    if not all_class[c] then
        all_class[c] = true
    end
end

--- 注册所有游戏对象类的回调函数  
function lstg.RegisterAllGameObjectClass()
    for k, _ in pairs(all_class) do
        lstg.RegisterGameObjectClass(k)
    end
end

--------------------------------------------------------------------------------
--- 兼容性 API

object = lstg.CreateGameObjectClass()

--- 该 API 在不同参数数量的情况下调用时会有不一样的行为  
--- 1、Class()             基类为 object  
--- 2、Class(base)         基类为传进去的 base 且会严格验证 base 的类型  
--- 3、Class(base, define) 同 2 并将 define 表中的内容复制到返回的超类中  
---@overload fun(base)
---@overload fun(base, define)
function Class(...)
    local args = {...}
    local argc = select("#", ...)
    local super = lstg.CreateGameObjectClass()
    if argc < 1 then
        -- 不带参数调用，此时基类为 object
        super.base = object
    else
        -- 带一个或更多参数调用，模拟继承，并验证基类类型
        local base = args[1]
        assert(type(base) == "table", "bad argument #1 to 'Class' (table expected)")
        assert(base.is_class, "bad argument #1 to 'Class' (not a class)")
        super.init = base.init
        super.del = base.del
        super.frame = base.frame
        super.render = base.render
        super.colli = base.colli
        super.kill = base.kill
        super.base = base
        -- 复制其他成员
        if argc >= 2 then
            local define = args[2]
            assert(type(define) == "table", "bad argument #2 to 'Class' (table expected)")
            for k, v in pairs(define) do
                super[k] = v
            end
        end
    end
    return super
end

InitAllClass = lstg.RegisterAllGameObjectClass
