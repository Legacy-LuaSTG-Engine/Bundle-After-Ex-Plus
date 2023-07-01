-- 哇，真是个糟糕的解决方法！
-- WOW what a bad workaround!

local function _redirect_font(filename)
    -- 重定向 THlib/ui/font/default_ttf
    if filename == "THlib/ui/font/default_ttf"
    or filename == "THlib\\ui\\font\\default_ttf"
    or filename == "THlib/UI/font\\default_ttf"
    or filename == "THlib\\UI\\font\\default_ttf"
    then
        filename = "assets/font/SourceHanSansCN-Bold.otf"
    end
    -- 重定向 THlib/ui/font/syst_heavy.otf
    if filename == "THlib/ui/font/syst_heavy.otf"
    or filename == "THlib\\ui\\font\\syst_heavy.otf"
    or filename == "THlib/UI/font/syst_heavy.otf"
    or filename == "THlib\\UI\\font\\syst_heavy.otf"
    then
        filename = "assets/font/SourceHanSerifCN-Heavy.otf"
    end
    -- 重定向 THlib/enemy/balloon_font.ttf -> assets/font/wqy-microhei-mono.ttf
    if filename == "THlib/enemy/balloon_font.ttf"
    or filename == "THlib\\enemy\\balloon_font.ttf"
    then
        filename = "assets/font/wqy-microhei-mono.ttf"
    end
    return filename
end

local _LoadTTF = LoadTTF

function LoadTTF(ttfname, filename, size)
    _LoadTTF(ttfname, _redirect_font(filename), size)
end

local _lstg_LoadTTF = lstg.LoadTTF

function lstg.LoadTTF(ttfname, filename, width, height)
    _lstg_LoadTTF(ttfname, _redirect_font(filename), width, height)
end
