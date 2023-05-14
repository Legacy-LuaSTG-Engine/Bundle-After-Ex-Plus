--======================================
--luastg text
--======================================

----------------------------------------
--文字渲染

ENUM_TTF_FMT = {
    left = 0x00000000,
    center = 0x00000001,
    right = 0x00000002,

    top = 0x00000000,
    vcenter = 0x00000004,
    bottom = 0x00000008,

    wordbreak = 0x00000010,
    --singleline=0x00000020,
    --expantextabs=0x00000040,
    noclip = 0x00000100,
    --calcrect=0x00000400,
    --rtlreading=0x00020000,
    paragraph = 0x00000010,
    centerpoint = 0x00000105,
}
setmetatable(ENUM_TTF_FMT, { __index = function(t, k)
    return 0
end })

function RenderTTF(ttfname, text, left, right, bottom, top, color, ...)
    local fmt = 0
    local arg = { ... }
    for i = 1, #arg do
        fmt = fmt + ENUM_TTF_FMT[arg[i]]
    end
    lstg.RenderTTF(ttfname, text, left, right, bottom, top, fmt, color)
end

function RenderTTF2(ttfname, text, left, right, bottom, top, scale, color, ...)
    local fmt = 0
    local arg = { ... }
    for i = 1, #arg do
        fmt = fmt + ENUM_TTF_FMT[arg[i]]
    end
    lstg.RenderTTF(ttfname, text, left, right, bottom, top, fmt, color, scale)
end

function RenderText(fontname, text, x, y, size, ...)
    local fmt = 0
    local arg = { ... }
    for i = 1, #arg do
        fmt = fmt + ENUM_TTF_FMT[arg[i]]
    end
    lstg.RenderText(fontname, text, x, y, size, fmt)
end
