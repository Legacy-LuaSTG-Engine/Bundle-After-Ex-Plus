---=====================================
---pause menu
---=====================================

----------------------------------------
---暂停菜单

---@class ext.pausemenu @暂停菜单对象
ext.pausemenu = plus.Class()

function ext.pausemenu:init()
    self.kill = true

    self.pos = 1
    self.pos2 = 2
    self.ok = false
    self.choose = false
    self.lock = true

    self.timer = 0
    self.t = 30

    self.eff = 0
    self.mask_color = Color(0, 255, 255, 255)
    self.mask_alph = { 0, 0, 0 }
    self.mask_x = { 0, 0, 0 }

    self.text = {
        { 'Return to Game', 'Return to Title', 'Give up and Retry' },
        { 'Return to Game', 'Return to Title', 'Replay Again' },
    }

    self.bgmlist = {}--用来储存正在播放的bgm
end

function ext.pausemenu:frame()
    if self.kill then
        return "killed"
    end

    --如果有可用的暂停菜单文字，则优先使用已有的
    local pause_menu_text
    if lstg.tmpvar.pause_menu_text then
        pause_menu_text = lstg.tmpvar.pause_menu_text
    else
        --根据是否是replay状态选择暂停菜单文字
        if ext.replay.IsReplay() then
            pause_menu_text = self.text[2]
        else
            pause_menu_text = self.text[1]
        end
    end
    --执行自身task
    task.Do(self)
    --执行选项操作
    if (not self.lock) and self.t < 1 then
        local lastkey = GetLastKey()
        --关闭暂停菜单
        if lastkey == setting.keysys.menu and (not lstg.tmpvar.death) then
            if not ext.rep_over then
                self.t = 60
                PlaySound('cancel00', 0.3)
                self.choose = false
                self:FlyOut()
            end
        end
        --直接重开
        if lastkey == setting.keysys.retry and (not lstg.tmpvar.death) then
            self.t = 60
            PlaySound('ok00', 0.3)
            self.choose = false
            if ext.replay.IsReplay() then
                ext.pause_menu_order = 'Replay Again'
            else
                ext.pause_menu_order = 'Give up and Retry'
            end
            self:FlyOut()
        end
        --槽位切换
        do
            if lastkey == setting.keys.up then
                self.t = 4
                PlaySound('select00', 0.3)
                if not self.choose then
                    self.pos = self.pos - 1
                else
                    self.pos2 = self.pos2 - 1
                end
            elseif lastkey == setting.keys.down then
                self.t = 4
                PlaySound('select00', 0.3)
                if not self.choose then
                    self.pos = self.pos + 1
                else
                    self.pos2 = self.pos2 + 1
                end
            end
            self.pos = (self.pos - 1) % (#pause_menu_text) + 1
            self.pos2 = (self.pos2 - 1) % (2) + 1
        end
        --取消操作
        if lastkey == setting.keys.spell then
            if self.choose then
                self.t = 15
                PlaySound('cancel00', 0.3)
                self.choose = false
            else
                if not ext.rep_over and (not lstg.tmpvar.death) then
                    self.t = 60
                    PlaySound('cancel00', 0.3)
                    self:FlyOut()
                end
            end
        end
        --按键操作
        if lastkey == setting.keys.shoot then
            if self.choose then
                if self.pos2 == 1 then
                    --确认选项，推送命令，暂停菜单关闭
                    self.t = 60
                    PlaySound('ok00', 0.3)
                    ext.PushPauseMenuOrder(pause_menu_text[self.pos])
                    self.choose = false
                    self:FlyOut()
                else
                    --取消选项
                    self.t = 15
                    PlaySound('cancel00', 0.3)
                    self.choose = false
                end
            else
                --未选中状态，进入二级菜单
                self.t = 15
                PlaySound('ok00', 0.3)
                if self.pos == 1 then
                    --对第一个选项特化处理
                    ext.PushPauseMenuOrder(pause_menu_text[self.pos])
                    self:FlyOut()
                else
                    self.choose = true
                end
            end
        end
    end
    --last op
    self.timer = self.timer + 1
    if self.t > 0 then
        self.t = self.t - 1
    end
    if self.choose then
        self.eff = min(self.eff + 1, 15)
    else
        self.eff = max(self.eff - 1, 0)
    end
end

function ext.pausemenu:render()
    if self.kill then
        return "killed"
    end

    --准备一些变量
    local pm = self--ext.pausemenu
    local dx = 208
    local dy = 240
    local m
    if ext.replay.IsReplay() then
        m = 2
    else
        m = 1
    end
    --绘制黑色遮罩
    SetViewMode 'ui'
    SetImageState('white', '', pm.mask_color)
    RenderRect('white', 0, screen.width, 0, screen.height)
    --渲染底图
    SetImageState('pause_eff', '', Color(pm.mask_alph[1] / 3, 200 * self.eff / 15 + 55, 200 * (1 - self.eff / 15) + 55, 200 * (1 - self.eff / 15) + 55))
    Render('pause_eff', -150 + 180 * self.eff / 15 + dx, -90 + dy, 4 + 4 * sin(self.timer * 3), 0.4, 0.6)
    --准备选项
    local pause_menu_text
    local pause_menu_choose = { 'yes', 'no' }
    if lstg.tmpvar.pause_menu_text then
        pause_menu_text = lstg.tmpvar.pause_menu_text
    else
        pause_menu_text = pm.text[m]
    end
    local textnumber = 0
    if pause_menu_text[3] then
        textnumber = 3
    else
        textnumber = 2
    end
    if pause_menu_text then
        if lstg.tmpvar.pause_menu_text then
            --有现有的文字时高亮处理
            if ext.rep_over then
                if self.choose then
                    SetImageState('pause_replyover', '', Color(pm.mask_alph[1] + 15, 100, 100, 100))
                else
                    SetImageState('pause_replyover', '', Color(pm.mask_alph[1] + 15, 255, 255, 255))
                end
                Render('pause_replyover', pm.mask_x[1] + dx, -30 + dy, 0, 0.7, 0.7)
            elseif not ext.sc_pr then
                if self.choose then
                    SetImageState('pause_gameover', '', Color(pm.mask_alph[1] + 15, 100, 100, 100))
                else
                    SetImageState('pause_gameover', '', Color(pm.mask_alph[1] + 15, 255, 255, 255))
                end
                Render('pause_gameover', pm.mask_x[1] + dx, -30 + dy, 0, 0.7, 0.7)
            end
        else
            --没有现有的文字时高亮处理
            if m == 1 then
                if self.choose then
                    SetImageState('pause_pausemenu', '', Color(pm.mask_alph[1] + 15, 100, 100, 100))
                else
                    SetImageState('pause_pausemenu', '', Color(pm.mask_alph[1] + 15, 255, 255, 255))
                end
                Render('pause_pausemenu', pm.mask_x[1] + dx, -30 + dy, 0, 0.7, 0.7)
            else
                if self.choose then
                    SetImageState('pause_replyover', '', Color(pm.mask_alph[1] + 15, 100, 100, 100))
                else
                    SetImageState('pause_replyover', '', Color(pm.mask_alph[1] + 15, 255, 255, 255))
                end
                Render('pause_replyover', pm.mask_x[1] + dx, -30 + dy, 0, 0.7, 0.7)
            end
        end
        --渲染选项列表
        for i = 1, textnumber do
            if not (self.choose) then
                if i == self.pos and pm.mask_alph[i] + 15 >= 245 then
                    SetImageState('pause_' .. pause_menu_text[i], '', Color(pm.mask_alph[i] + 15, 155 + 100 * sin(self.timer * 4.5), 255, 222))
                else
                    SetImageState('pause_' .. pause_menu_text[i], '', Color(pm.mask_alph[i] + 15, 100, 100, 100))
                end
            else
                if i == self.pos and pm.mask_alph[i] + 15 >= 245 then
                    SetImageState('pause_' .. pause_menu_text[i], '', Color(55, 255, 255, 255))
                else
                    SetImageState('pause_' .. pause_menu_text[i], '', Color(55, 100, 100, 100))
                end
            end
            Render('pause_' .. pause_menu_text[i], pm.mask_x[i] + (1 + i) * 10 + dx, -30 - i * 40 + dy, 0, 0.62, 0.62)
        end
    end
    --渲染确定选项
    if self.choose then
        Render('pause_really', 0 + dx, -50 + dy, 0, 0.62, 0.62)
        for i = 1, 2 do
            if i == self.pos2 then
                SetImageState('pause_' .. pause_menu_choose[i], '', Color(pm.mask_alph[i] + 15, 155 + 100 * sin(self.timer * 4.5), 255, 255))
            else
                SetImageState('pause_' .. pause_menu_choose[i], '', Color(pm.mask_alph[i] + 15, 100, 100, 100))
            end
            Render('pause_' .. pause_menu_choose[i], 15 + i * 10 + dx, -50 - i * 40 + dy, 0, 0.62, 0.62)
        end
    end
    SetViewMode 'world'
end

function ext.pausemenu:FlyIn()
    --清除一些flag
    ext.pop_pause_menu = nil

    self.kill = false--标记为开启状态

    self.pos = 1
    self.pos2 = 2
    self.ok = false
    self.choose = false
    self.lock = true

    self.timer = 0
    self.t = 30

    self.eff = 0
    self.mask_color = Color(0, 255, 255, 255)
    self.mask_alph = { 0, 0, 0 }
    self.mask_x = { 0, 0, 0 }

    task.New(self, function()
        self:PauseSound()
        PlaySound('pause', 0.5)

        for i = 1, 50 do
            self.mask_color = Color(i * 4.1, 0, 0, 0)
            self.mask_alph = {
                min(i * 8, 239),
                max(min((i - 10) * 8, 239), 0),
                max(min((i - 20) * 8, 239), 0),
            }
            self.mask_x = {
                min(-210 + i, -180),
                min(-220 + i, -180),
                min(-230 + i, -180),
            }
            task.Wait(1)
        end
        self.lock = false
    end)
end

function ext.pausemenu:FlyOut()
    self.lock = true

    --应该是针对疮痍曲的淡出……
    if not (ext.sc_pr) then
        task.New(self, function()
            local _, bgm = EnumRes('bgm')
            for i = 1, 30 do
                for _, v in pairs(bgm) do
                    if GetMusicState(v) == 'playing' then
                        SetBGMVolume(v, 1 - i / 30)
                    end
                end
                task.Wait(1)
            end
        end)
    end
    task.New(self, function()
        for i = 30, 1, -1 do
            self.mask_color = Color(i * 7, 0, 0, 0)
            for j = 1, 3 do
                self.mask_alph[j] = i * 8
            end
            task.Wait(1)
        end
        task.New(stage.current_stage, function()
            task.Wait(1)
            self:ResumeSound()
        end)

        self.kill = true--标记为关闭状态

        --清除一些flag
        lstg.tmpvar.death = false
        ext.rep_over = false
    end)
end

function ext.pausemenu:PauseSound()
    self.bgmlist = {}--先清空列表
    if not (ext.sc_pr) then
        local _, bgm = EnumRes('bgm')
        for _, v in pairs(bgm) do
            --[[
            if GetMusicState(v) ~= 'stopped' and v ~= 'deathmusic' then
                PauseMusic(v)
            end
            --]]
            --新的处理方法（实验性），只处理正在播放的bgm，不处理暂停的bgm
            if GetMusicState(v) == "playing" and v ~= "deathmusic" then
                PauseMusic(v)
                self.bgmlist[v] = true--标记
            end
        end
    end
    --[=[
    local sound, _ = EnumRes('snd')
    for _,v in pairs(sound) do
        if GetSoundState(v)~='stopped' and v ~= 'pause' then
            PauseSound(v)
        end
    end
    ]=]
end

function ext.pausemenu:ResumeSound()
    local _, bgm = EnumRes('bgm')
    for _, v in pairs(bgm) do
        --只对标记过为播放状态的bgm进行恢复
        if GetMusicState(v) ~= 'stopped' and self.bgmlist[v] then
            ResumeMusic(v)
        end
    end
    --[=[
    local sound,_=EnumRes('snd')
    for _,v in pairs(sound) do
        if GetSoundState(v)=='paused' then
            ResumeSound(v)
        end
    end
    ]=]
    --StopMusic(deathmusic)
end

function ext.pausemenu:IsKilled()
    local flag = self.kill
    return flag
end

----------------------------------------
---暂停菜单资源

local deathmusic = 'deathmusic'--疮痍曲

LoadMusic(deathmusic, 'THlib/music/player_score.ogg', 34.834, 27.54)
LoadTexture('pause', 'THlib/UI/pause.png')
LoadImage('pause_pausemenu', 'pause', 2, 0, 168, 70)
SetImageCenter('pause_pausemenu', 0, 35)
LoadImage('pause_gameover', 'pause', 172, 0, 170, 70)
SetImageCenter('pause_gameover', 0, 35)
LoadImage('pause_replyover', 'pause', 352, 0, 162, 70)
SetImageCenter('pause_replyover', 0, 35)
LoadImage('pause_Return to Game', 'pause', 0, 80, 245, 60)
SetImageCenter('pause_Return to Game', 0, 30)
LoadImage('pause_Return to Title', 'pause', 0, 140, 260, 56)
SetImageCenter('pause_Return to Title', 0, 28)
LoadImage('pause_Give up and Retry', 'pause', 0, 197, 200, 58)
SetImageCenter('pause_Give up and Retry', 0, 29)
LoadImage('pause_Restart', 'pause', 0, 197, 200, 58)
SetImageCenter('pause_Restart', 0, 29)
LoadImage('pause_yes', 'pause', 200, 196, 112, 60)
SetImageCenter('pause_yes', 0, 30)
LoadImage('pause_no', 'pause', 340, 196, 112, 60)
SetImageCenter('pause_no', 0, 30)
LoadImage('pause_Quit and Save Replay', 'pause', 0, 256, 360, 58)
SetImageCenter('pause_Quit and Save Replay', 0, 29)
LoadImage('pause_really', 'pause', 0, 316, 240, 60)
SetImageCenter('pause_really', 0, 30)
LoadImage('pause_savereply', 'pause', 0, 368, 188, 60)
SetImageCenter('pause_savereply', 0, 30)
LoadImage('pause_Replay Again', 'pause', 0, 432, 224, 56)
SetImageCenter('pause_Replay Again', 0, 28)
LoadImage('pause_Continue', 'pause', 232, 432, 120, 58)
SetImageCenter('pause_Continue', 0, 29)
LoadImage('pause_eff', 'pause', 408, 320, 104, 384)
