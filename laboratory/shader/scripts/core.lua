local SceneManager = require("laboratory.shader.SceneManager")
local HelloScene = require("laboratory.shader.HelloScene")
local MaskScene = require("laboratory.shader.MaskScene")
local ThresholdMaskScene = require("laboratory.shader.ThresholdMaskScene")
local ThresholdEdgeScene = require("laboratory.shader.ThresholdEdgeScene")
local BoxBlur3x3Scene = require("laboratory.shader.BoxBlur3x3Scene")
local BoxBlur5x5Scene = require("laboratory.shader.BoxBlur5x5Scene")
local BoxBlur7x7Scene = require("laboratory.shader.BoxBlur7x7Scene")
local HSLShift = require("laboratory.shader.HSLShift")

function GameInit()
    SceneManager.initialize()
    SceneManager.add(HelloScene)
    SceneManager.add(MaskScene)
    SceneManager.add(ThresholdMaskScene)
    SceneManager.add(ThresholdEdgeScene)
    SceneManager.add(BoxBlur3x3Scene)
    SceneManager.add(BoxBlur5x5Scene)
    SceneManager.add(BoxBlur7x7Scene)
    SceneManager.add(HSLShift)
end

function GameExit()
    SceneManager.destroy()
end

function FrameFunc()
    SceneManager.update()
	return false
end

function RenderFunc()
    SceneManager.draw()
end
