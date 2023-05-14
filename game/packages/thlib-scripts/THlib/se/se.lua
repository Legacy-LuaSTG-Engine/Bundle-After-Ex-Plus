--======================================
--THlib se
--======================================

----------------------------------------
--自带的音效

local sounds = {
    'alert', 'astralup', 'bonus', 'bonus2', 'boon00', 'boon01', 'cancel00', 'cardget', 'cat00', 'cat01', 'ch00', 'ch01', 'ch02', 'don00',
    'damage00', 'damage01', 'enep00', 'enep01', 'enep02', 'extend', 'fault', 'graze', 'gun00',
    'hint00', 'invalid', 'item00', 'kira00', 'kira01', 'kira02', 'lazer00', 'lazer01', 'lazer02',
    'msl', 'msl2', 'nep00', 'ok00', 'option', 'pause', 'pldead00', 'plst00', 'power0', 'power1',
    'powerup', 'select00', 'slash', 'tan00', 'tan01', 'tan02', 'timeout', 'timeout2',
    'warpl', 'warpr', 'water', 'explode', 'nice', 'nodamage', 'power02',
    'lgods1', 'lgods2', 'lgods3', 'lgods4', 'lgodsget', 'big', 'wolf', 'noise', 'pin00',
    'powerup1',
    'old_cat00', 'old_enep00', 'old_extend', 'old_gun00', 'old_kira00', 'old_kira01',
    'old_lazer01', 'old_nep00', 'old_pldead00', 'old_power0', 'old_power1', 'old_powerup',
    'hyz_charge00', 'hyz_charge01b', 'hyz_chargeup', 'hyz_eterase', 'hyz_exattack',
    'hyz_gosp', 'hyz_life1', 'hyz_playerdead', 'hyz_timestop0', 'hyz_warning',
    'bonus3', 'border', 'changeitem', 'down', 'extend2', 'focusfix', 'focusfix2', 'focusin',
    'heal', 'ice', 'ice2', 'item01', 'ophide', 'opshow',
}

for _, v in pairs(sounds) do
    LoadSound(v, 'THlib/se/se_' .. v .. '.wav')
end

----------------------------------------
--修正的音量系统
--！警告：该修正方法有问题

local soundVolume = {
    bonus = 0.6, bonus2 = 0.6, boon00 = 0.9, boon01 = 0.7,
    cancel00 = 0.4, cardget = 0.8, cat00 = 0.55,
    ch00 = 0.9, ch02 = 1,
    don00 = 0.85, damage00 = 0.35, damage01 = 0.5,
    enep00 = 0.35, enep02 = 0.45, enep01 = 0.6, explode = 0.4, extend = 0.6,
    graze = 0.4, gun00 = 0.6, invalid = 0.8, item00 = 0.32,
    kira00 = 0.33, kira01 = 0.4, kira02 = 0.6,
    lazer00 = 0.35, lazer01 = 0.35, lazer02 = 0.18,
    lgods1 = 0.6, lgods2 = 0.6, lgods3 = 0.6, lgods4 = 0.6, lgodsget = 0.6,
    msl = 0.37, msl2 = 0.37, nep00 = 0.5, nodamage = 0.5,
    ok00 = 0.4, option = 0.7, pause = 0.5, pldead00 = 0.7, plst00 = 0.27,
    power0 = 0.7, power02 = 0.7, power1 = 0.6,
    powerup = 0.6, powerup1 = 0.55,
    select00 = 0.4, slash = 0.75,
    tan00 = 0.28, tan01 = 0.35, tan02 = 0.5,
    timeout = 0.6, timeout2 = 0.7, water = 0.6,
}

function PlaySound(name, vol, pan, sndflag)
    local v
    if not (sndflag) then
        v = soundVolume[name]
        if v == nil then
            v = vol
        end
    else
        v = vol
    end
    lstg.PlaySound(name, v, (pan or 0) / 1024)
end
