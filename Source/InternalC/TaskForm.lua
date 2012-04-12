-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application Task Entry form UI creation and handling file
-- Author:      Milind Gupta
-- Created:     4/11/2012
-----------------------------------------------------------------------------

local modname = ...
local wx = wx
local setfenv = setfenv
local GUI = GUI

module(modname)

local taskData	-- To store the task data locally

function taskFormActivate(parent, task, callBack)

	frame = wx.wxFrame(parent, wx.wxID_ANY, "Task Form", wx.wxDefaultPosition,
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)

	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)

	frame:SetSizer(MainSizer)

	frame:Connect(wx.wxEVT_CLOSE_WINDOW,
		function (event)
			setfenv(1,package.loaded[modname])		
			event:Skip()
			callBack(nil)
		end
	)


    frame:Layout() -- help sizing the windows before being shown
    frame:Show(true)

end	-- function taskFormActivate(parent, callBack)