default_stage_background = Class(background)

function default_stage_background:init()
    background.init(self)
end

function default_stage_background:render()
    local w = lstg.world
    lstg.SetImageState("white", "", lstg.Color(255, 16, 16, 16))
    lstg.RenderRect("white", w.l, w.r, w.b, w.t)
end
