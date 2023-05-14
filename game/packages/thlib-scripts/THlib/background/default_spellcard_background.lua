
default_spellcard_background = Class(_spellcard_background)

function default_spellcard_background:init()
    _spellcard_background.init(self)
    _spellcard_background.AddLayer(self,
        "white",
        false,
        0, 0,
        0,
        0, 0,
        0,
        "",
        640 / 16, 640 / 16,
        function(layer)
            layer.r = 16
            layer.g = 16
            layer.b = 16
        end,
        function(layer)
        end,
        function(layer)
        end
    )
end
