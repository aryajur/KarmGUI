-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application main file forms the frontend and handles the GUI
-- Author:      Milind Gupta
-- Created:     1/13/2012
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

-- Include the XML handling module
require("LuaXml")

-- Creating GUI the main table containing all the GUI objects and data
GUI = {["__index"]=_G}
setmetatable(GUI,GUI)
setfenv(1,GUI)
initFrameH = 400
initFrameW = 450
setfenv(1,_G)

-- Table to store all the Spores data 
SporeData = {}

-- Function to convert XML data to internal data structure
function XML2Data(SporeXML)
	local dataStruct = {tasks = 0, [0] = "Task_Spore"}	-- to create the data structure
	if SporeXML[0]~="Task_Spore" then
		return nil
	end
	-- Find the Task_Spore element
	local currNode = SporeXML
	local hierInfo = {}
	local level = 1
	hierInfo[level] = {count = 1}
	while(currNode[hierInfo[level].count] or level > 1) do
		if not(currNode[hierInfo[level].count]) then
			currNode = hierInfo[level].parent
			level = level - 1
			dataStruct = dataStruct.parent
		else
			if currNode[hierInfo[level].count][0] == "Task" then
				dataStruct.tasks = dataStruct.tasks + 1
				dataStruct[dataStruct.tasks] = {[0] = "Task"}
				-- Extract all task information here
				local task = currNode[hierInfo[level].count]
				hierInfo[level].count = hierInfo[level].count + 1
				local count = 1
				while(task[count]) do
					if task[count][0] == "Title" then
						dataStruct[dataStruct.tasks].Title = task[count][1]
						-- print(task[count][1])
					elseif task[count][0] == "SubTasks" then
						level = level + 1
						hierInfo[level] = {count = 1, parent = currNode}
						currNode = task[count]
						dataStruct[dataStruct.tasks].SubTasks = {parent = dataStruct, tasks = 0, [0]="SubTasks"}
						dataStruct = dataStruct[dataStruct.tasks].SubTasks
					end
					count = count + 1
				end
			else
				if currNode[hierInfo[level].parent] then
					currNode = hierInfo[level].parent
					level = level - 1
					dataStruct = dataStruct.parent
				end		-- if currNode[hierInfo[level].parent ends here
			end		-- if currNode[hierInfo[level].count][0] == "Task"  ends here
		end
	end		-- while(currNode[hierInfo[level].count]) ends here
	while dataStruct.parent do
		dataStruct = dataStruct.parent
	end
	return dataStruct
end		-- function XML2Data(SporeXML) ends here

function Initialize()
	configFile = "KarmConfig.lua"
	
	-- load the configuration file
	dofile(configFile)
	-- Load all the XML spores
	local count = 1
	-- print(Spores[count])
	if Spores then
		while Spores[count] do
			local xmlFile = xml.load(Spores[count])
			SporeData[count] = XML2Data(xmlFile)
			setmetatable({},getmetatable(xmlFile))
			count = count + 1
		end
	end
    SporeData[1] = xml.new(SporeData[1])
	print(SporeData[1])
end

-- To fill the GUI with Dummy data in the treeList and ganttList
function fillDummyData()

	GUI.treeGrid:SetCellValue(0,0,"Test Item 0")
	GUI.treeGrid:SetCellBackgroundColour(0,0,wx.wxColour(255,255,255))
    for i = 1,100 do
    	GUI.treeGrid:InsertRows(i)
		GUI.treeGrid:SetCellValue(i,0,"Test Item " .. i)
		GUI.treeGrid:SetCellBackgroundColour(i,0,wx.wxColour(255,255,255))
	end
	-- GUI.treeGrid:SetScrollbars(3,3,treeGrid:GetSize():GetWidth(),treeGrid:GetSize():GetHeight())
	
	-- Fill the gantt chart list
	date = 17
	for i = 0,100 do	-- row count
		if i > 0 then 
			-- insert a row
			GUI.ganttGrid:InsertRows(i)
		end
		for j = 0,29 do
			if i == 0 then
				if j > 0 then
					-- insert a column
					GUI.ganttGrid:InsertCols(j)
				end
				-- set the column labels
				GUI.ganttGrid:SetColLabelValue(j,tostring(date+j))
				GUI.ganttGrid:SetColSize(j,25)
			end
			if (i+j)%2 == 0 then
				GUI.ganttGrid:SetCellBackgroundColour(i,j,wx.wxColour(128,34,170))
			end
		end
	end

	-- GUI.ganttGrid:SetScrollbars(3,3,ganttGrid:GetSize():GetWidth(),ganttGrid:GetSize():GetHeight())
end

function onScrollTree(event)
	GUI.ganttGrid:Scroll(GUI.ganttGrid:GetScrollPos(wx.wxHORIZONTAL), GUI.treeGrid:GetScrollPos(wx.wxVERTICAL))
	event:Skip()
end

function onScrollGantt(event)
	GUI.treeGrid:Scroll(GUI.treeGrid:GetScrollPos(wx.wxHORIZONTAL), GUI.ganttGrid:GetScrollPos(wx.wxVERTICAL))
	event:Skip()
end

function horSashAdjust(event)
	GUI.treeGrid:SetColSize(0,GUI.horSplitWin:GetSashPosition())
	GUI.treeGrid:ForceRefresh()
	event:Skip()
end

function main()
    GUI.frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "Karm",
                        wx.wxDefaultPosition, wx.wxSize(GUI.initFrameW, GUI.initFrameH),
                        wx.wxDEFAULT_FRAME_STYLE )

	GUI.ID_LOAD = wx.wxID_ANY
	GUI.ID_UNLOAD = wx.wxID_ANY
	GUI.ID_SAVEALL = wx.wxID_ANY
	GUI.ID_SAVECURR = wx.wxID_ANY
	GUI.ID_SET_FILTER = wx.wxID_ANY
	GUI.ID_NEW_SUB_TASK = wx.wxID_ANY
	GUI.ID_EDIT_TASK = wx.wxID_ANY
	GUI.ID_DEL_TASK = wx.wxID_ANY
	GUI.ID_MOVE_UNDER = wx.wxID_ANY
	GUI.ID_MOVE_ABOVE = wx.wxID_ANY
	GUI.ID_MOVE_BELOW = wx.wxID_ANY
	GUI.ID_REPORT = wx.wxID_ANY
	
	local toolBar = GUI.frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)
	local toolBmpSize = toolBar:GetToolBitmapSize()
	toolBar:AddTool(GUI.ID_LOAD, "Load", wx.wxArtProvider.GetBitmap(wx.wxART_GO_DIR_UP, wx.wxART_MENU, toolBmpSize), "Load Spore from Disk")
	toolBar:AddTool(GUI.ID_UNLOAD, "Unload", wx.wxArtProvider.GetBitmap(wx.wxART_FOLDER, wx.wxART_MENU, toolBmpSize), "Unload current spore")
	toolBar:AddTool(GUI.ID_SAVEALL, "Save All", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize), "Save All Spores to Disk")
	toolBar:AddTool(GUI.ID_SAVECURR, "Save Current", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE_AS, wx.wxART_MENU, toolBmpSize), "Save current spore to disk")
	toolBar:AddSeparator()
	toolBar:AddTool(GUI.ID_SET_FILTER, "Set Filter", wx.wxArtProvider.GetBitmap(wx.wxART_HELP_SIDE_PANEL, wx.wxART_MENU, toolBmpSize),   "Set Filter Criteria")
	toolBar:AddTool(GUI.ID_NEW_SUB_TASK, "Create Subtask", wx.wxArtProvider.GetBitmap(wx.wxART_ADD_BOOKMARK, wx.wxART_MENU, toolBmpSize),   "Creat Sub-task")
	toolBar:AddTool(GUI.ID_EDIT_TASK, "Edit Task", wx.wxArtProvider.GetBitmap(wx.wxART_REPORT_VIEW, wx.wxART_MENU, toolBmpSize),   "Edit Task")
	toolBar:AddTool(GUI.ID_DEL_TASK, "Delete Task", wx.wxArtProvider.GetBitmap(wx.wxART_CROSS_MARK, wx.wxART_MENU, toolBmpSize),   "Delete Task")
	toolBar:AddTool(GUI.ID_MOVE_UNDER, "Move Under", wx.wxArtProvider.GetBitmap(wx.wxART_GO_FORWARD, wx.wxART_MENU, toolBmpSize),   "Move Task Under...")
	toolBar:AddTool(GUI.ID_MOVE_ABOVE, "Move Above", wx.wxArtProvider.GetBitmap(wx.wxART_GO_UP, wx.wxART_MENU, toolBmpSize),   "Move task above...")
	toolBar:AddTool(GUI.ID_MOVE_BELOW, "Move Below", wx.wxArtProvider.GetBitmap(wx.wxART_GO_DOWN, wx.wxART_MENU, toolBmpSize),   "Move task below...")
	toolBar:AddSeparator()
	toolBar:AddTool(GUI.ID_REPORT, "Report", wx.wxArtProvider.GetBitmap(wx.wxART_LIST_VIEW, wx.wxART_MENU, toolBmpSize),   "Generate Reports")
	toolBar:Realize()

	-- Create status Bar in the window
    GUI.frame:CreateStatusBar(2)
    -- Text for the 1st field in the status bar
    GUI.frame:SetStatusText("Welcome to Karm", 0)
    -- text for the second field in the status bar
    GUI.frame:SetStatusText("Test", 1)
    -- Set the width of the second field to 25% of the whole window
    local widths = {}
    widths[1]=-3
    widths[2] = -1
    GUI.frame:SetStatusWidths(widths)
    

    -- create the menubar and attach it
    local fileMenu = wx.wxMenu()
    fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")
    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT, "&About", "About Karm")

    GUI.menuBar = wx.wxMenuBar()
    GUI.menuBar:Append(fileMenu, "&File")
    GUI.menuBar:Append(helpMenu, "&Help")

    GUI.frame:SetMenuBar(GUI.menuBar)

    -- connect the selection event of the exit menu item to an
    -- event handler that closes the window
    GUI.frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            frame:Close(true)
        end )

    -- connect the selection event of the about menu item
    GUI.frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            wx.wxMessageBox('Karm is the Task and Project management application for everybody.\n'..
                            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                            "About Karm",
                            wx.wxOK + wx.wxICON_INFORMATION,
                            frame)
        end )


	GUI.vertSplitWin = wx.wxSplitterWindow(GUI.frame, wx.wxID_ANY, wx.wxDefaultPosition, 
						wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxSP_3D, "Main Vertical Splitter")
	GUI.vertSplitWin:SetMinimumPaneSize(10)
	GUI.horSplitWin = wx.wxSplitterWindow(GUI.vertSplitWin, wx.wxID_ANY, wx.wxDefaultPosition, 
						wx.wxSize(GUI.initFrameW, 0.7*GUI.initFrameH), wx.wxSP_3D, "Task Splitter")
	GUI.horSplitWin:SetMinimumPaneSize(10)
	
	GUI.treeGrid = wx.wxGrid(GUI.horSplitWin, wx.wxID_ANY, wx.wxDefaultPosition, 
					wx.wxDefaultSize, 0, "Task Tree Grid")
    GUI.treeGrid:CreateGrid(1,1)
    GUI.treeGrid:SetRowLabelSize(0)
    GUI.treeGrid:SetColLabelValue(0,"Tasks")

	GUI.ganttGrid = wx.wxGrid(GUI.horSplitWin, wx.wxID_ANY, wx.wxDefaultPosition, 
						wx.wxDefaultSize, 0, "Gantt Chart Grid")
    GUI.ganttGrid:CreateGrid(1,1)
    GUI.ganttGrid:SetRowLabelSize(0)

	GUI.horSplitWin:SplitVertically(GUI.treeGrid, GUI.ganttGrid)
	GUI.horSplitWin:SetSashPosition(0.3*GUI.initFrameW)
	
	local detailsPanel = wx.wxPanel(GUI.vertSplitWin, wx.wxID_ANY, wx.wxDefaultPosition, 
							wx.wxDefaultSize, wx.wxTAB_TRAVERSAL, "Task Details Parent Panel")
	local boxSizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)
	local staticBoxSizer1 = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, detailsPanel, "Task Details")
	
	GUI.taskDetails = wx.wxTextCtrl(detailsPanel, wx.wxID_ANY, "No Task Selected", 
						wx.wxDefaultPosition, wx.wxDefaultSize, bit.bor(wx.wxTE_AUTO_SCROLL, 
						wx.wxTE_MULTILINE, wx.wxTE_READONLY), wx.wxDefaultValidator,"Task Details Box")
	staticBoxSizer1:Add(GUI.taskDetails, 1, bit.bor(wx.wxALL,wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,
						wx.wxALIGN_CENTER_VERTICAL), 2)
	boxSizer1:Add(staticBoxSizer1, 1, bit.bor(wx.wxALL,wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	local staticBoxSizer2 = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, detailsPanel, "Filter Criteria")
	GUI.taskFilter = wx.wxTextCtrl(detailsPanel, wx.wxID_ANY, "No Filter", 
						wx.wxDefaultPosition, wx.wxDefaultSize, bit.bor(wx.wxTE_AUTO_SCROLL, 
						wx.wxTE_MULTILINE, wx.wxTE_READONLY), wx.wxDefaultValidator,"Task Filter Criteria")
	staticBoxSizer2:Add(GUI.taskFilter, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 2)
	boxSizer1:Add(staticBoxSizer2, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	detailsPanel:SetSizer(boxSizer1)
	boxSizer1:Fit(detailsPanel)
	boxSizer1:SetSizeHints(detailsPanel)
	GUI.vertSplitWin:SplitHorizontally(GUI.horSplitWin, detailsPanel)
	GUI.vertSplitWin:SetSashPosition(0.7*GUI.initFrameH)


	-- SYNC THE SCROLLING OF THE TWO GRIDS	
	-- Create the scroll event to sync the 2 scroll bars in the wxScrolledWindow
	GUI.treeGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBTRACK, onScrollTree)
	GUI.treeGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBRELEASE, onScrollTree)
	GUI.treeGrid:Connect(wx.wxEVT_SCROLLWIN_LINEUP, onScrollTree)
	GUI.treeGrid:Connect(wx.wxEVT_SCROLLWIN_LINEDOWN, onScrollTree)

	GUI.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBTRACK, onScrollGantt)
	GUI.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBRELEASE, onScrollGantt)
	GUI.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_LINEUP, onScrollGantt)
	GUI.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_LINEDOWN, onScrollGantt)
	
	-- Sash position changing event
	GUI.horSplitWin:Connect(wx.wxEVT_COMMAND_SPLITTER_SASH_POS_CHANGED, horSashAdjust)

    GUI.frame:Layout() -- help sizing the windows before being shown

    GUI.treeGrid:SetColSize(0,GUI.horSplitWin:GetSashPosition())

	-- Main table to store the task tree that is on display
	GUI.taskTree = {}
	
	fillDummyData()
	
    wx.wxGetApp():SetTopWindow(GUI.frame)
    
    GUI.frame:Show(true)
end

-- Do all the initial Configuration and Initialization
Initialize()

main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
