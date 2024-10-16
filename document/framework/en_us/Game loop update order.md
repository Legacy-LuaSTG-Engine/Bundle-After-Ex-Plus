# Game loop update order  

LuaSTG Sub 0.21.12 and LuaSTG After Ex Plus 0.9.0 have made significant changes to the game loop update order, which may affect existing code that depends on certain features or bugs. However, in the long run, these changes will make the game loop update order more rational.  

## Highlights of changes  

* 调整“根据 navi 更新 rot 属性”的位置到每个游戏对象的粒子系统更新之前  
* 调整“更新 dx、dy 属性”的位置到每个逻辑帧的开始  
* 调整“更新 timer、ani 属性”的位置到每个逻辑帧的开始  
* 将出界检测调整到每个逻辑帧的末尾  
* 先执行所有游戏对象的 frame 回调函数，再更新所有游戏对象的运动参数、位置、粒子系统  
* 先执行所有相交检测，再根据检测结果触发 colli 回调函数  
* 先执行所有出界检测，再根据检测结果标记删除游戏对象  

## Old order  

1. Read player inputs  
2. call `ex.Frame`, _`current_stage_instance`_`.frame`  
3. Update GameObjects (1) `lstg.ObjFrame` (pseudo-code):  
    ```lua
    for object in lstg.ObjList() do
        -- Call frame callback function
        object:frame()
        -- Update vx, vy according to ax, ay, ag
        object.vx = object.vx + object.ax
        object.vy = object.vy + object.ay - object.ag
        -- Limit vx, vy according to maxv
        local speed = sqrt(object.vx * object.vx + object.vy * object.vy)
        if speed > maxv then
            local scale = maxv / speed
            object.vx = object.vx * scale
            object.vy = object.vy * scale
        end
        -- Limit vx, vy according to maxvx, maxvy
        object.vx = clamp(object.vx, -object.maxvx, object.maxvx)
        object.vy = clamp(object.vy, -object.maxvy, object.maxvy)
        -- Update x, y according to vx, vy
        object.x = object.x + object.vx
        object.y = object.y + object.vy
        -- Update rot according to omega (omiga)
        object.rot = object.rot + object.omega
        -- Updating particle system (if exists)
        updateParticleSystem(object)
    end
    ```
4. Check world boundary `lstg.BoundCheck` (pseudo-code):  
    ```lua
    for object in lstg.ObjList() do
        if not isInWorldBoundary(object) then
            -- mark as deleted
            lstg.Del(object)
        end
    end
    ```
5. Check intersection `lstg.CollisionCheck` (pseudo-code):  
    ```lua
    for object1 in lstg.ObjList(group1) do
        for object2 in lstg.ObjList(group2) do
            if hasIntersection(object1, object2) then
                -- Call the colli callback function for the GameObject that belongs to the first group.
                object1:colli(object2)
            end
        end
    end
    ```
6. Update GameObject to next frame (1) & Update GameObjects (2) `lstg.UpdateXY` (pseudo-code):  
    ```lua
    for object in lstg.ObjList() do
        -- Update dx, dy (Note that lastx, lasty are not accessible to lua scripts)
        object.dx = object.x - object.lastx
        object.dy = object.y - object.lasty
        object.lastx = object.x
        object.lasty = object.y
        -- Update rot if navi enabled
        if object.navi then
            object.rot = atan2(object.dy, object.dx)
        end
    end
    ```
7. Update GameObject to next frame (2) `lstg.AfterFrame` (pseudo-code):  
    ```lua
    for object in lstg.ObjList() do
        -- Update timers
        object.timer = object.timer + 1
        object.ani = object.ani + 1
        -- Check GameObject status
        if object.status ~= "normal" then
            -- Marked as deleted, free it
            freeGameObject(object)
        end
    end
    ```

## New order  

1. Update GameObject to next frame (pseudo-code):  
    ```lua
    for object in lstg.ObjList() do
        -- Check GameObject status
        if object.status == "normal" then
            -- Update dx, dy (Note that lastx, lasty are not accessible to lua scripts)
            object.dx = object.x - object.lastx
            object.dy = object.y - object.lasty
            object.lastx = object.x
            object.lasty = object.y
            -- Update timers
            object.timer = object.timer + 1
            object.ani = object.ani + 1
        else
            -- Marked as deleted, free it
            freeGameObject(object)
        end
    end
    ```
2. Read player inputs    
3. Call ex.Frame, _current_stage_instance_.frame  
4. Update GameObject (pseudo-code):  
    ```lua
    for object in lstg.ObjList() do
        -- Call frame callback function
        object:frame()
    end
    for object in lstg.ObjList() do
        -- Update vx, vy according to ax, ay, ag
        object.vx = object.vx + object.ax
        object.vy = object.vy + object.ay - object.ag
        -- Limit vx, vy according to maxv
        local speed = sqrt(object.vx * object.vx + object.vy * object.vy)
        if speed > maxv then
            local scale = maxv / speed
            object.vx = object.vx * scale
            object.vy = object.vy * scale
        end
        -- Limit vx, vy according to maxvx, maxvy
        object.vx = clamp(object.vx, -object.maxvx, object.maxvx)
        object.vy = clamp(object.vy, -object.maxvy, object.maxvy)
        -- Update x, y according to vx, vy
        object.x = object.x + object.vx
        object.y = object.y + object.vy
        -- Update rot according to omega (omiga)
        object.rot = object.rot + object.omega
        -- Update rot if navi enabled
        if object.navi then
            object.rot = atan2(object.dy, object.dx)
        end
        -- Updating particle system (if exists)
        updateParticleSystem(object)
    end
    ```
5. Check intersection (pseudo-code):  
    ```lua
    local results = {}
    for object1 in lstg.ObjList(group1) do
        for object2 in lstg.ObjList(group2) do
            if hasIntersection(object1, object2) then
                table.insert(results, { object1, object2 })
            end
        end
    end
    for _, result in ipairs(results) do
        -- Call the colli callback function for the GameObject that belongs to the first group.
        result[1]:colli(result[2])
    end
    ```
6. Check world boundary (pseudo-code):  
    ```lua
    -- Step 1
    local results = {}
    for object in lstg.ObjList() do
        if not isInWorldBoundary(object) then
            table.insert(results, object)
        end
    end
    -- Step 2
    for _ object in ipairs(results) do
        -- mark as deleted
        lstg.Del(object)
    end
    ```
