-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application main file forms the frontend and handles the GUI
-- Author:      Milind Gupta
-- Created:     1/13/2012
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

GUI = {["__index"]=_G}
setmetatable(GUI,GUI)
setfenv(1,GUI)
initFrameH = 400
initFrameW = 450
setfenv(1,_G)

-- To fill the GUI with Dummy data in the treeList and ganttList
function fillDummyData()

	treeGrid:SetCellValue(0,0,"Test Item 0")
	treeGrid:SetCellBackgroundColour(0,0,wx.wxColour(255,255,255))
    for i = 1,100 do
    	treeGrid:InsertRows(i)
		treeGrid:SetCellValue(i,0,"Test Item " .. i)
		treeGrid:SetCellBackgroundColour(i,0,wx.wxColour(255,255,255))
	end
	scrollWin1:SetScrollbars(3,3,treeGrid:GetSize():GetWidth(),treeGrid:GetSize():GetHeight())
	
	-- Fill the gantt chart list
	date = 17
	for i = 0,100 do	-- row count
		if i > 0 then 
			-- insert a row
			ganttGrid:InsertRows(i)
		end
		for j = 0,29 do
			if i == 0 then
				if j > 0 then
					-- insert a column
					ganttGrid:InsertCols(j)
				end
				-- set the column labels
				ganttGrid:SetColLabelValue(j,tostring(date+j))
				ganttGrid:SetColSize(j,25)
			end
			if (i+j)%2 == 0 then
				ganttGrid:SetCellBackgroundColour(i,j,wx.wxColour(128,34,170))
			end
		end
	end

	scrollWin2:SetScrollbars(3,3,ganttGrid:GetSize():GetWidth(),ganttGrid:GetSize():GetHeight())
end

function onScrollWin1(event)
	scrollWin2:Scroll(scrollWin1:GetScrollPos(wx.wxHORIZONTAL), scrollWin1:GetScrollPos(wx.wxVERTICAL))
	event:Skip()
end

function onScrollWin2(event)
	scrollWin1:Scroll(scrollWin2:GetScrollPos(wx.wxHORIZONTAL), scrollWin2:GetScrollPos(wx.wxVERTICAL))
	event:Skip()
end

function main()
    frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "Karm",
                        wx.wxDefaultPosition, wx.wxSize(GUI.initFrameW, GUI.initFrameH),
                        wx.wxDEFAULT_FRAME_STYLE )

	-- Create status Bar in the window
    frame:CreateStatusBar(1)
    frame:SetStatusText("Welcome to Karm", 0)

    -- create the menubar and attach it
    local fileMenu = wx.wxMenu()
    fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")
    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT, "&About", "About Karm")

    local menuBar = wx.wxMenuBar()
    menuBar:Append(fileMenu, "&File")
    menuBar:Append(helpMenu, "&Help")

    frame:SetMenuBar(menuBar)

    -- connect the selection event of the exit menu item to an
    -- event handler that closes the window
    frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            frame:Close(true)
        end )

    -- connect the selection event of the about menu item
    frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            wx.wxMessageBox('Karm is the Task and Project management application for everybody.\n'..
                            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                            "About Karm",
                            wx.wxOK + wx.wxICON_INFORMATION,
                            frame)
        end )

	local SplitterSizer = wx.wxSplitterWindow(frame, wx.wxID_ANY, wx.wxDefaultPosition, 
							wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxSP_3D, "Karm_SplitterWindow")
	SplitterSizer:SetMinimumPaneSize(10)
	-- Create the 2 list controls with 2 wxScrolledwindows
	scrollWin1 = wx.wxScrolledWindow(SplitterSizer, wx.wxID_ANY)
	local boxSizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)
    -- treeList = wx.wxListCtrl(scrollWin1, wx.wxID_ANY, wx.wxDefaultPosition,
    --                              wx.wxDefaultSize, wx.wxLC_REPORT, wx.wxDefaultValidator, "Karm Task Tree")
    treeGrid = wx.wxGrid(scrollWin1,wx.wxID_ANY)
    treeGrid:CreateGrid(1,1)
    treeGrid:SetRowLabelSize(0)
    treeGrid:SetColLabelValue(0,"Tasks")
    boxSizer1:Add(treeGrid, 1, bit.bor(wx.wxALL, wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL),1)
    scrollWin1:SetSizer(boxSizer1)
    boxSizer1:Fit(scrollWin1)
    boxSizer1:SetSizeHints(scrollWin1)

    scrollWin2 = wx.wxScrolledWindow(SplitterSizer, wx.wxID_ANY)
	local boxSizer2 = wx.wxBoxSizer(wx.wxVERTICAL)
    -- ganttList = wx.wxListCtrl(scrollWin2, wx.wxID_ANY, wx.wxDefaultPosition,
    --                            wx.wxDefaultSize, wx.wxLC_REPORT, wx.wxDefaultValidator, "Karm Task Tree")
    ganttGrid = wx.wxGrid(scrollWin2,wx.wxID_ANY)
    ganttGrid:CreateGrid(1,1)
    ganttGrid:SetRowLabelSize(0)
    boxSizer2:Add(ganttGrid, 1, bit.bor(wx.wxALL, wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL),1)
    scrollWin2:SetSizer(boxSizer2)
    boxSizer2:Fit(scrollWin2)
    boxSizer2:SetSizeHints(scrollWin2)
    -- Place them in the Splitter sizer
	SplitterSizer:SplitVertically(scrollWin1, scrollWin2)
	
	--	scrollWin1:SetBackgroundColour(wx.wxColour(0,0,0))
	
	-- Create the scroll event to sync the 2 scroll bars in the wxScrolledWindow
	scrollWin1:Connect(wx.wxEVT_SCROLLWIN_THUMBTRACK, onScrollWin1)
	scrollWin1:Connect(wx.wxEVT_SCROLLWIN_THUMBRELEASE, onScrollWin1)
	scrollWin1:Connect(wx.wxEVT_SCROLLWIN_LINEUP, onScrollWin1)
	scrollWin1:Connect(wx.wxEVT_SCROLLWIN_LINEDOWN, onScrollWin1)

    frame:Layout() -- help sizing the windows before being shown

    treeGrid:SetColSize(0,boxSizer1:GetSize():GetWidth())

	-- Main table to store the GUI data
	guiTable = {}
	
	fillDummyData()
	
    wx.wxGetApp():SetTopWindow(frame)
    
    frame:Show(true)
end

main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
