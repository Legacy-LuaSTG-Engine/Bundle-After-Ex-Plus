-- THlib

lstg.plugin.LoadPlugins()
lstg.plugin.DispatchEvent("beforeTHlib")
Include("THlib/THlib.lua")
lstg.plugin.DispatchEvent("afterTHlib")
